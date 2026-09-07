select
    platform,
    placement,
    country,
    sum(clicks) as clicks,
    sum(impressions) as impressions,
    sum(spend) as spend,
    sum(sessions) as sessions,
    sum(conversions) as conversions,
    sum(purchases) as purchases,
    sum(revenue) as revenue,
    case when sum(clicks) > 0 then sum(spend) / sum(clicks) end as cpc,
    case when sum(conversions) > 0 then sum(spend) / sum(conversions) end as cpa,
    case when sum(sessions) > 0 then sum(conversions)::numeric / sum(sessions) end as conversion_rate,
    case when sum(spend) > 0 then sum(revenue) / sum(spend) end as roas
from {{ ref('fct_campaign_daily') }}
group by platform, placement, country
order by roas desc nulls last
