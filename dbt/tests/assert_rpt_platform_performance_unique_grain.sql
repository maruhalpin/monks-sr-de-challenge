select
    platform,
    month,
    count(*) as row_count
from {{ ref('rpt_platform_performance') }}
group by platform, month
having count(*) > 1
