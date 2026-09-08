select
    platform,
    date_trunc('month', date)::date as month,
    sum(clicks) as clicks,
    sum(impressions) as impressions,
    sum(spend) as spend,
    sum(sessions) as sessions,
    sum(conversions) as conversions,
    sum(purchases) as purchases,
    sum(revenue) as revenue,
    sum(page_views) as page_views,
    sum(add_to_cart) as add_to_cart,
    sum(begin_checkout) as begin_checkout,
    sum(add_payment_info) as add_payment_info,
    case when sum(clicks) > 0 then sum(spend) / sum(clicks) end as cpc,
    case when sum(conversions) > 0 then sum(spend) / sum(conversions) end as cpa,
    case when sum(impressions) > 0 then sum(clicks)::numeric / sum(impressions) end as ctr,
    case when sum(sessions) > 0 then sum(converting_sessions)::numeric / sum(sessions) end as conversion_rate,
    case when sum(spend) > 0 then (sum(revenue) - sum(spend)) / sum(spend) end as roi
from {{ ref('fct_campaign_daily') }}
group by platform, date_trunc('month', date)::date
order by month desc, roi desc nulls last
