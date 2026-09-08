select
    campaign_id,
    date,
    batch_window_start,
    count(*) as row_count
from {{ ref('int_ads_windows') }}
group by
    campaign_id,
    date,
    batch_window_start
having count(*) > 1
