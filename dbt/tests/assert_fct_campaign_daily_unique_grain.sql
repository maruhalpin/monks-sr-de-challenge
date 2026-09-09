select
    platform,
    campaign_id,
    country,
    placement,
    date,
    count(*) as row_count
from {{ ref('fct_campaign_daily') }}
group by
    platform,
    campaign_id,
    country,
    placement,
    date
having count(*) > 1