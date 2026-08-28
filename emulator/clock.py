"""Compress live June into ``TARGET_DURATION_SECONDS`` of wall-clock time."""
import hashlib
import math
from collections.abc import Iterator
from dataclasses import dataclass, replace
from datetime import datetime

from emulator import config
from emulator.catalog import AdsSlice, Catalog, Ga4Event


@dataclass(frozen=True)
class Tick:
    wall_second: int
    sim_start: datetime
    sim_end: datetime
    ga4: tuple[Ga4Event, ...]
    ads: tuple[AdsSlice, ...]


class ReplayClock:
    """One shared sim clock so GA4 events and ads windows stay aligned."""

    def __init__(self, catalog: Catalog) -> None:
        n_ticks = config.TARGET_DURATION_SECONDS // config.TICK_SECONDS
        ga4_by_tick: list[list[Ga4Event]] = [[] for _ in range(n_ticks)]
        ads_by_tick: list[list[AdsSlice]] = [[] for _ in range(n_ticks)]

        for event in catalog.live_ga4:
            tick = _tick_for_instant(event.event_timestamp, closed_end=False)
            ga4_by_tick[tick].append(event)
            if _should_duplicate(event):
                dupe_tick = min(tick + config.DUPLICATE_DELAY_SECONDS, n_ticks - 1)
                ga4_by_tick[dupe_tick].append(replace(event, is_duplicate=True))

        for slice_ in catalog.live_ads:
            tick = _tick_for_instant(slice_.batch_window_end, closed_end=True)
            ads_by_tick[tick].append(slice_)

        self._ga4_by_tick = ga4_by_tick
        self._ads_by_tick = ads_by_tick

    def ticks(self) -> Iterator[Tick]:
        for wall_second, (ga4, ads) in enumerate(
            zip(self._ga4_by_tick, self._ads_by_tick)
        ):
            yield Tick(
                wall_second=wall_second,
                sim_start=config.sim_at(wall_second),
                sim_end=config.sim_at(wall_second + 1),
                ga4=tuple(ga4),
                ads=tuple(ads),
            )


def _tick_for_instant(instant, closed_end: bool) -> int:
    offset = (instant - config.LIVE_START).total_seconds()
    step = config.sim_seconds() / config.TARGET_DURATION_SECONDS
    if closed_end:
        tick = math.ceil(offset / step) - 1
    else:
        tick = math.floor(offset / step)
    return max(0, min(tick, config.TARGET_DURATION_SECONDS - 1))


def _should_duplicate(event: Ga4Event) -> bool:
    key = (
        f"{config.DUPLICATE_SEED}:{event.user_id}:{event.session_id}:"
        f"{event.event_timestamp_ms}:{event.event_name}"
    )
    digest = hashlib.md5(key.encode("utf-8"), usedforsecurity=False).digest()
    unit = int.from_bytes(digest[:8], "big") / 2**64
    return unit < config.DUPLICATE_RATE
