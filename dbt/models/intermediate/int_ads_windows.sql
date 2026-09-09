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
),

unioned as (
    select * from google
    union all
    select * from meta
),
new_windows as (
    select *
    from unioned

    {% if is_incremental() %}
        where (
            ingested_at >= (select coalesce(max(ingested_at) - interval '5 minutes', '1900-01-01'::timestamptz)
                from {{ this }}
            )
            {% if var('backfill_start_date', none) %}
            or date >= '{{ var("backfill_start_date") }}'::date and date < '{{ var("backfill_end_date") }}'::date
            {% endif %}
        )
    {% endif %}

)
select
    *,
    lower(split_part(campaign_id, '_', 3)) as channel,
    lower(split_part(campaign_id, '_', 4)) as objective
from new_windows