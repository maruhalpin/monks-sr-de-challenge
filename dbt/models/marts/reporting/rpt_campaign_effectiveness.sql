-- preg 2
select
    platform,
    campaign_id,
    campaign_name,
    account_id,
    account_name,
    sum(clicks) as clicks,
    sum(impressions) as impressions,
    sum(spend) as spend,
    sum(sessions) as sessions,
    sum(conversions) as conversions,
    sum(purchases) as purchases,
    sum(revenue) as revenue,
    case when sum(clicks) > 0 then sum(spend) / sum(clicks) end as cpc,
    case when sum(conversions) > 0 then sum(spend) / sum(conversions) end as cpa,
    case when sum(spend) > 0 then sum(revenue) / sum(spend) end as roas,
    case when sum(spend) > 0 then (sum(revenue) - sum(spend)) / sum(spend) end as roi
from {{ ref('fct_campaign_daily') }}
group by platform, campaign_id, campaign_name, account_id, account_name
order by revenue desc nulls last
