CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE raw.google_analytics_events (
    user_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    event_timestamp TIMESTAMPTZ NOT NULL,
    event_name TEXT NOT NULL,
    event_params JSONB NOT NULL,
    campaign_id TEXT NOT NULL DEFAULT '',
    stream_name TEXT,
    page_url TEXT,
    country TEXT,
    is_conversion BOOLEAN,
    ingested_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX ga4_event_timestamp_idx
    ON raw.google_analytics_events (event_timestamp);
CREATE INDEX ga4_ingested_at_idx
    ON raw.google_analytics_events (ingested_at);

CREATE TABLE raw.google_ads (
    date DATE NOT NULL,
    campaign_name TEXT,
    campaign_id TEXT NOT NULL,
    placement_id TEXT,
    account_id TEXT,
    account_name TEXT,
    country TEXT,
    clicks INTEGER NOT NULL,
    impressions INTEGER NOT NULL,
    spend NUMERIC(12, 2) NOT NULL,
    batch_window_start TIMESTAMPTZ NOT NULL,
    batch_window_end TIMESTAMPTZ NOT NULL,
    batch_id TEXT NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    UNIQUE (campaign_id, date, batch_window_start)
);

CREATE INDEX google_ads_date_idx ON raw.google_ads (date);
CREATE INDEX google_ads_ingested_at_idx ON raw.google_ads (ingested_at);

CREATE TABLE raw.meta_ads (
    date DATE NOT NULL,
    campaign_name TEXT,
    campaign_id TEXT NOT NULL,
    ad_location TEXT,
    account_id TEXT,
    account_name TEXT,
    country TEXT,
    clicks INTEGER NOT NULL,
    impressions INTEGER NOT NULL,
    spend NUMERIC(12, 2) NOT NULL,
    batch_window_start TIMESTAMPTZ NOT NULL,
    batch_window_end TIMESTAMPTZ NOT NULL,
    batch_id TEXT NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL,
    UNIQUE (campaign_id, date, batch_window_start)
);

CREATE INDEX meta_ads_date_idx ON raw.meta_ads (date);
CREATE INDEX meta_ads_ingested_at_idx ON raw.meta_ads (ingested_at);
