with ads as (

    select *
    from {{ ref('int_ads_windows') }}

),

sessions as (

    select *
    from {{ ref('int_ga4_sessions') }}

),

affected_ad_windows as (

    select distinct campaign_id, country
    from ads

    {% if is_incremental() %}
        where ingested_at > (
            select coalesce(max(_ad_ingested_at), '1900-01-01'::timestamptz)
            from {{ this }}
        )
    {% endif %}

),

affected_sessions as (

    select distinct campaign_id, country
    from sessions

    {% if is_incremental() %}
        where last_event_ingested_at > (
            select coalesce(max(_max_session_ingested_at), '1900-01-01'::timestamptz)
            from {{ this }}
        )
    {% endif %}

),

affected_keys as (

    select campaign_id, country from affected_ad_windows
    union
    select campaign_id, country from affected_sessions

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
        ads.date,
        ads.batch_id,
        ads.batch_window_start,
        ads.batch_window_end,
        ads.ingested_at as _ad_ingested_at,

        ads.clicks,
        ads.impressions,
        ads.spend,

        count(distinct sessions.session_id) as sessions,

        coalesce(sum(sessions.conversions), 0) as conversions,

        coalesce(sum(sessions.purchase_count), 0) as purchases,

        coalesce(sum(sessions.revenue), 0) as revenue,

        max(sessions.last_event_ingested_at) as _max_session_ingested_at

    from ads

    inner join affected_keys
        on affected_keys.campaign_id = ads.campaign_id
        and affected_keys.country = ads.country

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
        then conversions::numeric / sessions
    end as conversion_rate,

    case
        when spend > 0
        then revenue / spend
    end as roas,

    case
        when spend > 0
        then (revenue - spend) / spend
    end as roi

from campaign_performance