-- preg 2
select
    platform,
    campaign_id,
    campaign_name,
    account_id,
    account_name,
    channel,
    objective,
    date_trunc('month', date)::date as month,
    sum(clicks) as clicks,
    sum(impressions) as impressions,
    sum(spend) as spend,
    sum(sessions) as sessions,
    sum(conversions) as conversions,
    sum(purchases) as purchases,
    sum(revenue) as revenue,
    case when sum(clicks) > 0 then sum(spend) / sum(clicks) end as cpc,
    case when sum(impressions) > 0 then sum(clicks)::numeric / sum(impressions) end as ctr,
    case when sum(conversions) > 0 then sum(spend) / sum(conversions) end as cpa,
    case when sum(sessions) > 0 then sum(converting_sessions)::numeric / sum(sessions) end as conversion_rate,
    case when sum(spend) > 0 then (sum(revenue) - sum(spend)) / sum(spend) end as roi
from {{ ref('fct_campaign_daily') }}
group by
    platform, campaign_id, campaign_name, account_id, account_name, channel, objective,
    date_trunc('month', date)::date
order by month desc, revenue desc nulls last
