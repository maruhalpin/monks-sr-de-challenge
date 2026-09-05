with affected_sessions as (

    select distinct
        user_id,
        session_id
    from {{ ref('stg_ga4_events') }}

    {% if is_incremental() %}
        where ingested_at >= (
            select coalesce(
                max(ingested_at) - interval '5 minutes',
                '1900-01-01'::timestamptz
            )
            from {{ ref('stg_ga4_events') }}
        )
    {% endif %}

),

sessions as (

    select
        e.user_id,
        e.session_id,
        min(e.event_timestamp) as session_start,
        max(e.event_timestamp) as session_end,
        max(e.campaign_id) as campaign_id,
        max(e.country) as country,

        count(*) filter (where e.event_name = 'page_view') as page_views,
        count(*) filter (where e.event_name = 'add_to_cart') as add_to_cart,
        count(*) filter (where e.event_name = 'begin_checkout') as begin_checkout,
        count(*) filter (where e.event_name = 'add_payment_info') as add_payment_info,
        count(*) filter (where e.is_conversion = true) as conversions,
        count(*) filter (where e.event_name = 'purchase') as purchase_count,

        max(e.ingested_at) as last_event_ingested_at,

        coalesce(
            sum(
                case
                    when e.event_name = 'purchase'
                    then (e.event_params ->> 'value')::numeric
                    else 0
                end
            ),
            0
        ) as revenue

    from {{ ref('stg_ga4_events') }} e

    inner join affected_sessions a
        on e.user_id = a.user_id
        and e.session_id = a.session_id

    group by
        e.user_id,
        e.session_id

)

select *
from sessions