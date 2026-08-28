"""Print catalog split and derived live-stream rates. No I/O to a warehouse."""

from emulator import config
from emulator.catalog import load
from emulator.clock import ReplayClock


def main() -> None:
    catalog = load()
    clock = ReplayClock(catalog)

    live_ga4 = 0
    dupes = 0
    ads_ticks = 0
    live_ads = 0
    for tick in clock.ticks():
        live_ga4 += sum(1 for event in tick.ga4 if not event.is_duplicate)
        dupes += sum(1 for event in tick.ga4 if event.is_duplicate)
        if tick.ads:
            ads_ticks += 1
            live_ads += len(tick.ads)

    print(f"historical GA4 events: {len(catalog.historical_ga4)}")
    print(f"historical ads slices: {len(catalog.historical_ads)}")
    print(f"live GA4 events:       {live_ga4}")
    print(f"live ads slices:       {live_ads}")
    print(f"scheduled duplicates:  {dupes}")
    print(f"target duration (s):   {config.TARGET_DURATION_SECONDS}")
    print(f"GA4 events / second:   {live_ga4 / config.TARGET_DURATION_SECONDS:.2f}")
    print(f"ads batches (ticks):   {ads_ticks}")
    print(
        "ads interval (s):      "
        f"{config.TARGET_DURATION_SECONDS / ads_ticks:.2f}"
        if ads_ticks
        else "ads interval (s):      n/a"
    )


if __name__ == "__main__":
    main()
