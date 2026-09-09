with paid as (
    select
        platform,
        channel,
        objective,
        date_trunc('month', date)::date as month,
        sum(clicks) as clicks,
        sum(impressions) as impressions,
        sum(spend) as spend,
        sum(sessions) as sessions,
        sum(converting_sessions) as converting_sessions,
        sum(conversions) as conversions,
        sum(purchases) as purchases,
        sum(revenue) as revenue
    from {{ ref('fct_campaign_daily') }}
    group by platform, channel, objective, date_trunc('month', date)::date
),

-- Trafico organico (que no pertenece a ninguna capaña de ads)
organic as (
    select
        'organic' as platform,
        'direct' as channel,
        cast(null as text) as objective,
        date_trunc('month', session_start)::date as month,
        0 as clicks,
        0 as impressions,
        0::numeric as spend,
        count(*) as sessions,
        count(*) filter (where conversions > 0) as converting_sessions,
        coalesce(sum(conversions), 0) as conversions,
        coalesce(sum(purchase_count), 0) as purchases,
        coalesce(sum(revenue), 0) as revenue
    from {{ ref('int_ga4_sessions') }}
    where campaign_id is null
    group by date_trunc('month', session_start)::date

),

combined as (
    select * from paid
    union all
    select * from organic
)

select
    *,
    case when clicks > 0 then spend / clicks end as cpc,
    case when conversions > 0 then spend / conversions end as cpa,
    case when sessions > 0 then converting_sessions::numeric / sessions end as conversion_rate,
    case when spend > 0 then (revenue - spend) / spend end as roi
from combined
order by month desc, revenue desc nulls last
