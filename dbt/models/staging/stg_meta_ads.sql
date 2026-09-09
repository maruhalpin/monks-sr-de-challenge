select
    date,
    batch_window_start,
    batch_window_end,
    batch_id,
    ingested_at,
    campaign_name,
    campaign_id,
    ad_location as placement,
    account_id,
    account_name,
    country,
    clicks,
    impressions,
    spend
from {{ source('raw', 'meta_ads') }}