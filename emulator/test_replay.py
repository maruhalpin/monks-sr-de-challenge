import unittest
from datetime import date, datetime, timezone
from decimal import Decimal

from emulator import config
from emulator.catalog import load
from emulator.clock import ReplayClock


class CatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = load()

    def test_ga4_split_matches_cutoff(self) -> None:
        self.assertEqual(len(self.catalog.historical_ga4), 6458)
        self.assertEqual(len(self.catalog.live_ga4), 5742)
        self.assertTrue(
            all(
                event.event_timestamp.date() <= config.HISTORICAL_CUTOFF_DATE
                for event in self.catalog.historical_ga4
            )
        )
        self.assertTrue(
            all(
                event.event_timestamp.date() > config.HISTORICAL_CUTOFF_DATE
                for event in self.catalog.live_ga4
            )
        )

    def test_ads_exploded_into_four_windows_per_campaign_day(self) -> None:
        google_live = [s for s in self.catalog.live_ads if s.platform == "google_ads"]
        meta_live = [s for s in self.catalog.live_ads if s.platform == "meta_ads"]
        self.assertEqual(len(google_live), 8 * 30 * 4)
        self.assertEqual(len(meta_live), 8 * 30 * 4)
        self.assertEqual(len(self.catalog.historical_ads), 8 * 31 * 4 * 2)

        sample_day = [
            s
            for s in google_live
            if s.date == date(2026, 6, 1)
            and s.campaign_id == "GADS_H&M_DISPLAY_AWARENESS_US_CALIFORNIA_SUMMER"
        ]
        self.assertEqual(len(sample_day), 4)
        self.assertEqual(sum(s.clicks for s in sample_day), 752)
        self.assertEqual(sum(s.impressions for s in sample_day), 213835)
        self.assertEqual(sum(s.spend for s in sample_day), Decimal("621.04"))

    def test_ads_windows_are_six_hours(self) -> None:
        first = next(
            s
            for s in self.catalog.live_ads
            if s.date == date(2026, 6, 1) and s.platform == "google_ads"
        )
        self.assertEqual(
            first.batch_window_start,
            datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc),
        )
        self.assertEqual(
            (first.batch_window_end - first.batch_window_start).total_seconds(),
            6 * 3600,
        )


class ClockTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = load()
        cls.ticks = list(ReplayClock(cls.catalog).ticks())

    def test_live_stream_fits_target_duration(self) -> None:
        self.assertEqual(len(self.ticks), config.TARGET_DURATION_SECONDS)

    def test_every_live_ga4_event_is_emitted_once(self) -> None:
        originals = [
            event
            for tick in self.ticks
            for event in tick.ga4
            if not event.is_duplicate
        ]
        self.assertEqual(len(originals), len(self.catalog.live_ga4))

    def test_every_live_ads_slice_lands_when_its_window_closes(self) -> None:
        emitted = [slice_ for tick in self.ticks for slice_ in tick.ads]
        self.assertEqual(len(emitted), len(self.catalog.live_ads))
        first_ads_tick = next(t.wall_second for t in self.ticks if t.ads)
        last_ads_tick = next(t.wall_second for t in reversed(self.ticks) if t.ads)
        self.assertLess(first_ads_tick, 10)
        self.assertGreater(last_ads_tick, config.TARGET_DURATION_SECONDS - 10)

    def test_duplicates_are_deterministic_and_delayed(self) -> None:
        dupes = [
            event for tick in self.ticks for event in tick.ga4 if event.is_duplicate
        ]
        self.assertGreater(len(dupes), 40)
        self.assertLess(len(dupes), 90)
        again = [
            event
            for tick in ReplayClock(self.catalog).ticks()
            for event in tick.ga4
            if event.is_duplicate
        ]
        self.assertEqual(
            [(e.user_id, e.event_timestamp_ms, e.event_name) for e in dupes],
            [(e.user_id, e.event_timestamp_ms, e.event_name) for e in again],
        )


if __name__ == "__main__":
    unittest.main()
