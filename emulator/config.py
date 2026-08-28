"""Cadence knobs for the local lab emulator.

``TARGET_DURATION_SECONDS`` is the rate control: live June is compressed into
this wall-clock window. Ads still land as 4 batches per campaign-day (6h);
their wall interval is derived from the duration, not set independently.
"""

from datetime import date, datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / ".data"

TARGET_DURATION_SECONDS = 600
TICK_SECONDS = 1

HISTORICAL_CUTOFF_DATE = date(2026, 5, 31)
LIVE_START = datetime(2026, 6, 1, tzinfo=timezone.utc)
LIVE_END = datetime(2026, 7, 1, tzinfo=timezone.utc)

ADS_BATCHES_PER_DAY = 4
ADS_WINDOW_HOURS = 24 // ADS_BATCHES_PER_DAY

DUPLICATE_RATE = 0.01
DUPLICATE_DELAY_SECONDS = 3
DUPLICATE_SEED = 42


def sim_seconds() -> float:
    return (LIVE_END - LIVE_START).total_seconds()


def wall_seconds_per_sim_second() -> float:
    return TARGET_DURATION_SECONDS / sim_seconds()


def sim_at(wall_second: int) -> datetime:
    """Simulated instant at the start of a wall-clock tick."""
    return LIVE_START + (LIVE_END - LIVE_START) * (
        wall_second / TARGET_DURATION_SECONDS
    )
