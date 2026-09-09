select
    user_id,
    session_id,
    count(*) as row_count
from {{ ref('int_ga4_sessions') }}
group by
    user_id,
    session_id
having count(*) > 1