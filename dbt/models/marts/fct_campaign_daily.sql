with campaign_performance as (
    select *
    from {{ ref('fct_campaign_performance') }}
),

affected_dates as (
    select distinct date
    from campaign_performance

    {% if is_incremental() %}
        where _ad_ingested_at >= (
            select coalesce(max(_ad_ingested_at), '1900-01-01'::timestamptz) - interval '5 minutes'
            from {{ this }}
        )
        or _max_session_ingested_at >= (
            select coalesce(max(_max_session_ingested_at), '1900-01-01'::timestamptz) - interval '5 minutes'
            from {{ this }}
        )
        {% if var('backfill_start_date', none) %}
        or date >= '{{ var("backfill_start_date") }}'::date and date < '{{ var("backfill_end_date") }}'::date
        {% endif %}
    {% endif %}
),

daily as (
    select
        platform,
        campaign_id,
        campaign_name,
        account_id,
        account_name,
        country,
        placement,
        channel,
        objective,
        date,
        sum(clicks) as clicks,
        sum(impressions) as impressions,
        sum(spend) as spend,
        sum(sessions) as sessions,
        sum(converting_sessions) as converting_sessions,
        sum(conversions) as conversions,
        sum(purchases) as purchases,
        sum(revenue) as revenue,
        sum(page_views) as page_views,
        sum(add_to_cart) as add_to_cart,
        sum(begin_checkout) as begin_checkout,
        sum(add_payment_info) as add_payment_info,
        count(distinct batch_id) as windows_received,
        count(distinct batch_id) = 4 as is_day_complete,
        max(_ad_ingested_at) as _ad_ingested_at,
        max(_max_session_ingested_at) as _max_session_ingested_at
    from campaign_performance
    inner join affected_dates using (date)
    group by
        platform,
        campaign_id,
        campaign_name,
        account_id,
        account_name,
        country,
        placement,
        channel,
        objective,
        date
)

select
    *,
    case
        when clicks > 0
        then spend / clicks
    end as cpc,
    case
        when conversions > 0
        then spend / conversions
    end as cpa,
    case
        when impressions > 0
        then clicks::numeric / impressions
    end as ctr,
    case
        when sessions > 0
        then converting_sessions::numeric / sessions
    end as conversion_rate,
    case
        when spend > 0
        then (revenue - spend) / spend
    end as roi
from daily