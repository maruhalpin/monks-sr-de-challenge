with attributed_sessions as (
    select count(*) as n
    from {{ ref('int_ga4_sessions') }}
    where campaign_id is not null
),

reported_sessions as (
    select coalesce(sum(sessions), 0) as n
    from {{ ref('fct_campaign_performance') }}
)

select *
from reported_sessions
where n > (select n from attributed_sessions)
