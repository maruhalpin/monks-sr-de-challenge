select
    date,
    batch_window_start,
    batch_window_end,
    batch_id,
    ingested_at,
    campaign_name,
    campaign_id,
    placement_id as placement,
    account_id,
    account_name,
    country,
    clicks,
    impressions,
    spend
from {{ source('raw', 'google_ads') }}