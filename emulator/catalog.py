"""Load the canonical CSVs and split historical (May) vs live (June)."""
import csv
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

from emulator import config


@dataclass(frozen=True)
class Ga4Event:
    user_id: str
    session_id: str
    event_timestamp: datetime
    event_timestamp_ms: int
    event_name: str
    event_params: str
    campaign_id: str
    stream_name: str
    page_url: str
    country: str
    is_conversion: bool
    is_duplicate: bool = False


@dataclass(frozen=True)
class AdsSlice:
    platform: str
    date: date
    campaign_name: str
    campaign_id: str
    placement_id: str | None
    ad_location: str | None
    account_id: str
    account_name: str
    country: str
    clicks: int
    impressions: int
    spend: Decimal
    batch_window_start: datetime
    batch_window_end: datetime


@dataclass(frozen=True)
class Catalog:
    historical_ga4: tuple[Ga4Event, ...]
    live_ga4: tuple[Ga4Event, ...]
    historical_ads: tuple[AdsSlice, ...]
    live_ads: tuple[AdsSlice, ...]


def load(data_dir: Path | None = None) -> Catalog:
    data_dir = data_dir or config.DATA_DIR
    ga4 = tuple(_load_ga4(data_dir / "ga4.csv"))
    ads = tuple(
        [
            *_load_ads(data_dir / "google_ads.csv", platform="google_ads"),
            *_load_ads(data_dir / "meta.csv", platform="meta_ads"),
        ]
    )
    cutoff = datetime.combine(
        config.HISTORICAL_CUTOFF_DATE + timedelta(days=1),
        time.min,
        tzinfo=timezone.utc,
    )
    return Catalog(
        historical_ga4=tuple(e for e in ga4 if e.event_timestamp < cutoff),
        live_ga4=tuple(e for e in ga4 if e.event_timestamp >= cutoff),
        historical_ads=tuple(s for s in ads if s.date <= config.HISTORICAL_CUTOFF_DATE),
        live_ads=tuple(s for s in ads if s.date > config.HISTORICAL_CUTOFF_DATE),
    )


def _load_ga4(path: Path) -> list[Ga4Event]:
    events: list[Ga4Event] = []
    with path.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            ts_ms = int(row["Timestamp"])
            events.append(
                Ga4Event(
                    user_id=row["User ID"],
                    session_id=row["session_id"],
                    event_timestamp=datetime.fromtimestamp(
                        ts_ms / 1000, tz=timezone.utc
                    ),
                    event_timestamp_ms=ts_ms,
                    event_name=row["Event Name"],
                    event_params=row["Event Parameters"],
                    campaign_id=row["Campaign ID"],
                    stream_name=row["Stream Name"],
                    page_url=row["Page URL"],
                    country=row["Country"],
                    is_conversion=row["Is Conversion"] == "True",
                )
            )
    return events


def _load_ads(path: Path, platform: str) -> list[AdsSlice]:
    slices: list[AdsSlice] = []
    with path.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            slices.extend(_explode_day(row, platform=platform))
    return slices


def _explode_day(row: dict[str, str], platform: str) -> list[AdsSlice]:
    report_date = date.fromisoformat(row["Date"])
    clicks = _split_int(int(row["Clicks"]), config.ADS_BATCHES_PER_DAY)
    impressions = _split_int(int(row["Impressions"]), config.ADS_BATCHES_PER_DAY)
    spend = _split_money(Decimal(row["Spend"]), config.ADS_BATCHES_PER_DAY)
    placement_id = row.get("Placement ID")
    ad_location = row.get("Ad Location")

    out: list[AdsSlice] = []
    for index in range(config.ADS_BATCHES_PER_DAY):
        start = datetime.combine(report_date, time.min, tzinfo=timezone.utc) + timedelta(
            hours=index * config.ADS_WINDOW_HOURS
        )
        end = start + timedelta(hours=config.ADS_WINDOW_HOURS)
        out.append(
            AdsSlice(
                platform=platform,
                date=report_date,
                campaign_name=row["Campaign Name"],
                campaign_id=row["Campaign ID"],
                placement_id=placement_id,
                ad_location=ad_location,
                account_id=row["Account ID"],
                account_name=row["Account Name"],
                country=row["Country"],
                clicks=clicks[index],
                impressions=impressions[index],
                spend=spend[index],
                batch_window_start=start,
                batch_window_end=end,
            )
        )
    return out


def _split_int(total: int, parts: int) -> list[int]:
    base, remainder = divmod(total, parts)
    return [base] * (parts - remainder) + [base + 1] * remainder


def _split_money(total: Decimal, parts: int) -> list[Decimal]:
    total = total.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    share = (total / parts).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    values = [share] * (parts - 1)
    values.append(total - sum(values))
    return values
