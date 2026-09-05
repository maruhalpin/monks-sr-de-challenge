with google as (

    select
        'google' as platform,
        date,
        batch_window_start,
        batch_window_end,
        batch_id,
        ingested_at,
        campaign_name,
        campaign_id,
        placement,
        account_id,
        account_name,
        country,
        clicks,
        impressions,
        spend
    from {{ ref('stg_google_ads') }}

),

meta as (

    select
        'meta' as platform,
        date,
        batch_window_start,
        batch_window_end,
        batch_id,
        ingested_at,
        campaign_name,
        campaign_id,
        placement,
        account_id,
        account_name,
        country,
        clicks,
        impressions,
        spend
    from {{ ref('stg_meta_ads') }}

)

select * from google

union all

select * from meta