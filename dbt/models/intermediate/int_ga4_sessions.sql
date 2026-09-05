with sessions as (

    select
        user_id,
        session_id,

        min(event_timestamp) as session_start,
        max(event_timestamp) as session_end,

        max(campaign_id) as campaign_id,
        max(country) as country,

        count(*) filter (
            where event_name = 'page_view'
        ) as page_views,

        count(*) filter (
            where event_name = 'add_to_cart'
        ) as add_to_cart,

        count(*) filter (
            where event_name = 'begin_checkout'
        ) as begin_checkout,

        count(*) filter (
            where event_name = 'add_payment_info'
        ) as add_payment_info,

        count(*) filter (
            where is_conversion = true
        ) as conversions,

        count(*) filter (
            where event_name = 'purchase'
        ) as purchase_count,

        coalesce(
            sum(
                case
                    when event_name = 'purchase'
                    then (event_params ->> 'value')::numeric
                    else 0
                end
            ),
            0
        ) as revenue

    from {{ ref('stg_ga4_events') }}

    group by
        user_id,
        session_id

)

select *
from sessions