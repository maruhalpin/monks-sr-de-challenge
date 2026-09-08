with ads as (
    select *
    from {{ ref('int_ads_windows') }}
),

sessions as (
    select *
    from {{ ref('int_ga4_sessions') }}
),

affected_ad_windows as (
    select distinct campaign_id, date, batch_window_start
    from ads

    {% if is_incremental() %}
        where (
            ingested_at >= (
                select coalesce(max(_ad_ingested_at), '1900-01-01'::timestamptz) - interval '5 minutes'
                from {{ this }}
            )
            {% if var('backfill_start_date', none) %}
            or date >= '{{ var("backfill_start_date") }}'::date and date < '{{ var("backfill_end_date") }}'::date
            {% endif %}
        )
    {% endif %}
),

affected_sessions as (
    select distinct campaign_id, country, session_start
    from sessions

    {% if is_incremental() %}
        where (
            last_event_ingested_at >= (
                select coalesce(max(_max_session_ingested_at), '1900-01-01'::timestamptz) - interval '5 minutes'
                from {{ this }}
            )
            {% if var('backfill_start_date', none) %}
            or session_start >= '{{ var("backfill_start_date") }}'::date and session_start < '{{ var("backfill_end_date") }}'::date
            {% endif %}
        )
    {% endif %}
),

affected_windows_from_sessions as (
    select distinct
        ads.campaign_id,
        ads.date,
        ads.batch_window_start
    from ads
    inner join affected_sessions
        on affected_sessions.campaign_id = ads.campaign_id
        and affected_sessions.country = ads.country
        and affected_sessions.session_start >= ads.batch_window_start
        and affected_sessions.session_start < ads.batch_window_end
),

affected_keys as (
    select campaign_id, date, batch_window_start from affected_ad_windows
    union
    select campaign_id, date, batch_window_start from affected_windows_from_sessions
),

campaign_performance as (
    select
        ads.platform,
        ads.campaign_id,
        ads.campaign_name,
        ads.account_id,
        ads.account_name,
        ads.country,
        ads.placement,
        ads.channel,
        ads.objective,
        ads.date,
        ads.batch_id,
        ads.batch_window_start,
        ads.batch_window_end,
        ads.ingested_at as _ad_ingested_at,
        ads.clicks,
        ads.impressions,
        ads.spend,
        count(*) filter (where sessions.session_id is not null) as sessions,
        count(*) filter (where sessions.conversions > 0) as converting_sessions,
        coalesce(sum(sessions.conversions), 0) as conversions,
        coalesce(sum(sessions.purchase_count), 0) as purchases,
        coalesce(sum(sessions.revenue), 0) as revenue,
        coalesce(sum(sessions.page_views), 0) as page_views,
        coalesce(sum(sessions.add_to_cart), 0) as add_to_cart,
        coalesce(sum(sessions.begin_checkout), 0) as begin_checkout,
        coalesce(sum(sessions.add_payment_info), 0) as add_payment_info,
        max(sessions.last_event_ingested_at) as _max_session_ingested_at
    from ads
    inner join affected_keys
        on affected_keys.campaign_id = ads.campaign_id
        and affected_keys.date = ads.date
        and affected_keys.batch_window_start = ads.batch_window_start
    left join sessions
        on sessions.campaign_id = ads.campaign_id
        and sessions.country = ads.country
        and sessions.session_start >= ads.batch_window_start
        and sessions.session_start < ads.batch_window_end
    group by
        ads.platform,
        ads.campaign_id,
        ads.campaign_name,
        ads.account_id,
        ads.account_name,
        ads.country,
        ads.placement,
        ads.channel,
        ads.objective,
        ads.date,
        ads.batch_id,
        ads.batch_window_start,
        ads.batch_window_end,
        ads.ingested_at,
        ads.clicks,
        ads.impressions,
        ads.spend
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
from campaign_performance