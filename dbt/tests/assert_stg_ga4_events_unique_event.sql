select
    user_id,
    session_id,
    event_timestamp,
    event_name,
    count(*) as row_count
from {{ ref('stg_ga4_events') }}
group by
    user_id,
    session_id,
    event_timestamp,
    event_name
having count(*) > 1