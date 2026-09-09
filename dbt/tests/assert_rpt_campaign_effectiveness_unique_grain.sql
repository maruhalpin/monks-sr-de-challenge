select
    campaign_id,
    month,
    count(*) as row_count
from {{ ref('rpt_campaign_effectiveness') }}
group by campaign_id, month
having count(*) > 1
