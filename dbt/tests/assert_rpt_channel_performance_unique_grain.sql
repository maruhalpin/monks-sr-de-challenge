select
    platform,
    channel,
    objective,
    month,
    count(*) as row_count
from {{ ref('rpt_channel_performance') }}
group by platform, channel, objective, month
having count(*) > 1
