select
    campaign_id,
    date,
    batch_window_start,
    count(*) as row_count
from {{ ref('fct_campaign_performance') }}
group by
    campaign_id,
    date,
    batch_window_start
having count(*) > 1
