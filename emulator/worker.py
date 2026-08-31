"""Insert historical May, then stream June into Postgres on the replay clock."""

from __future__ import annotations

import json
import logging
import os
import time
from datetime import datetime, timezone

import psycopg
from psycopg.types.json import Jsonb

from emulator import config
from emulator.catalog import AdsSlice, Catalog, Ga4Event, load
from emulator.clock import ReplayClock

LOGGER = logging.getLogger("emulator.worker")

GA4_COLUMNS = (
    "user_id, session_id, event_timestamp, event_name, event_params, "
    "campaign_id, stream_name, page_url, country, is_conversion, ingested_at"
)
GOOGLE_ADS_COLUMNS = (
    "date, campaign_name, campaign_id, placement_id, account_id, account_name, "
    "country, clicks, impressions, spend, batch_window_start, batch_window_end, "
    "batch_id, ingested_at"
)
META_ADS_COLUMNS = (
    "date, campaign_name, campaign_id, ad_location, account_id, account_name, "
    "country, clicks, impressions, spend, batch_window_start, batch_window_end, "
    "batch_id, ingested_at"
)


def dsn() -> str:
    user = os.environ.get("POSTGRES_USER", "xyz")
    password = os.environ.get("POSTGRES_PASSWORD", "xyz")
    host = os.environ.get("POSTGRES_HOST", "localhost")
    port = os.environ.get("POSTGRES_PORT", "5432")
    db = os.environ.get("POSTGRES_DB", "xyz")
    return f"postgresql://{user}:{password}@{host}:{port}/{db}"


def connect(retries: int = 30) -> psycopg.Connection:
    last_error: Exception | None = None
    for attempt in range(1, retries + 1):
        try:
            return psycopg.connect(dsn())
        except psycopg.OperationalError as exc:
            last_error = exc
            LOGGER.warning("waiting for postgres (%s/%s): %s", attempt, retries, exc)
            time.sleep(1)
    raise RuntimeError("could not connect to postgres") from last_error


def reset(conn: psycopg.Connection) -> None:
    with conn.cursor() as cur:
        cur.execute(
            "TRUNCATE raw.google_analytics_events, raw.google_ads, raw.meta_ads"
        )
    conn.commit()


def batch_id_for(slice_: AdsSlice) -> str:
    return slice_.batch_window_end.strftime("%Y%m%dT%H%M%SZ")


def insert_ga4(
    conn: psycopg.Connection,
    events: tuple[Ga4Event, ...] | list[Ga4Event],
    ingested_at: datetime,
) -> None:
    if not events:
        return
    rows = [
        (
            event.user_id,
            event.session_id,
            event.event_timestamp,
            event.event_name,
            Jsonb(json.loads(event.event_params)),
            event.campaign_id,
            event.stream_name,
            event.page_url,
            event.country,
            event.is_conversion,
            ingested_at,
        )
        for event in events
    ]
    with conn.cursor() as cur:
        cur.executemany(
            f"INSERT INTO raw.google_analytics_events ({GA4_COLUMNS}) "
            f"VALUES ({', '.join(['%s'] * 11)})",
            rows,
        )


def insert_ads(
    conn: psycopg.Connection,
    slices: tuple[AdsSlice, ...] | list[AdsSlice],
    ingested_at: datetime,
) -> None:
    google = [s for s in slices if s.platform == "google_ads"]
    meta = [s for s in slices if s.platform == "meta_ads"]
    if google:
        with conn.cursor() as cur:
            cur.executemany(
                f"INSERT INTO raw.google_ads ({GOOGLE_ADS_COLUMNS}) "
                f"VALUES ({', '.join(['%s'] * 14)})",
                [_google_row(s, ingested_at) for s in google],
            )
    if meta:
        with conn.cursor() as cur:
            cur.executemany(
                f"INSERT INTO raw.meta_ads ({META_ADS_COLUMNS}) "
                f"VALUES ({', '.join(['%s'] * 14)})",
                [_meta_row(s, ingested_at) for s in meta],
            )


def _google_row(slice_: AdsSlice, ingested_at: datetime) -> tuple:
    return (
        slice_.date,
        slice_.campaign_name,
        slice_.campaign_id,
        slice_.placement_id,
        slice_.account_id,
        slice_.account_name,
        slice_.country,
        slice_.clicks,
        slice_.impressions,
        slice_.spend,
        slice_.batch_window_start,
        slice_.batch_window_end,
        batch_id_for(slice_),
        ingested_at,
    )


def _meta_row(slice_: AdsSlice, ingested_at: datetime) -> tuple:
    return (
        slice_.date,
        slice_.campaign_name,
        slice_.campaign_id,
        slice_.ad_location,
        slice_.account_id,
        slice_.account_name,
        slice_.country,
        slice_.clicks,
        slice_.impressions,
        slice_.spend,
        slice_.batch_window_start,
        slice_.batch_window_end,
        batch_id_for(slice_),
        ingested_at,
    )


def load_historical(conn: psycopg.Connection, catalog: Catalog) -> None:
    ingested_at = datetime.now(timezone.utc)
    insert_ga4(conn, catalog.historical_ga4, ingested_at)
    insert_ads(conn, catalog.historical_ads, ingested_at)
    conn.commit()
    LOGGER.info(
        "historical backfill complete: %s GA4 events, %s ads slices",
        len(catalog.historical_ga4),
        len(catalog.historical_ads),
    )


def stream_live(conn: psycopg.Connection, catalog: Catalog) -> None:
    clock = ReplayClock(catalog)
    started = time.monotonic()
    ga4_streamed = 0
    ads_streamed = 0
    ga4_total = len(catalog.live_ga4)
    ads_total = len(catalog.live_ads)
    for tick in clock.ticks():
        ingested_at = datetime.now(timezone.utc)
        insert_ga4(conn, tick.ga4, ingested_at)
        insert_ads(conn, tick.ads, ingested_at)
        conn.commit()
        ga4_streamed += sum(1 for event in tick.ga4 if not event.is_duplicate)
        ads_streamed += len(tick.ads)
        target = started + (tick.wall_second + 1) * config.TICK_SECONDS
        remaining = target - time.monotonic()
        if remaining > 0:
            time.sleep(remaining)
        if tick.wall_second == 0 or (tick.wall_second + 1) % 30 == 0:
            LOGGER.info(
                "live tick %s/%s: %s/%s GA4 streamed, %s/%s ads streamed",
                tick.wall_second + 1,
                config.TARGET_DURATION_SECONDS,
                ga4_streamed,
                ga4_total,
                ads_streamed,
                ads_total,
            )
    LOGGER.info("live stream complete")


def run() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    LOGGER.info(
        "starting emulator: duration=%ss cutoff=%s",
        config.TARGET_DURATION_SECONDS,
        config.HISTORICAL_CUTOFF_DATE,
    )
    catalog = load()
    with connect() as conn:
        reset(conn)
        load_historical(conn, catalog)
        stream_live(conn, catalog)
    LOGGER.info("idle; raw tables are ready")
    while True:
        time.sleep(3600)


def main() -> None:
    run()


if __name__ == "__main__":
    main()
