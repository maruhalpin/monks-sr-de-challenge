with daily as (

    select
        platform,
        campaign_id,
        campaign_name,
        account_id,
        account_name,
        country,
        placement,
        date,

        sum(clicks) as clicks,
        sum(impressions) as impressions,
        sum(spend) as spend,

        sum(sessions) as sessions,
        sum(conversions) as conversions,
        sum(purchases) as purchases,
        sum(revenue) as revenue

    from {{ ref('fct_campaign_performance') }}

    group by
        platform,
        campaign_id,
        campaign_name,
        account_id,
        account_name,
        country,
        placement,
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

from daily