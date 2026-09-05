with source_data as (
    select
        user_id,
        session_id,
        event_timestamp,
        event_name,
        event_params,
        nullif(trim(campaign_id), '') as campaign_id,
        stream_name,
        page_url,
        case
            when upper(trim(country)) = 'US' then 'United States'
            else country
        end as country,
        is_conversion,
        ingested_at
    from {{ source('raw', 'google_analytics_events') }}

    {% if is_incremental() %}
        where ingested_at >= (
            select coalesce(
                max(ingested_at) - interval '5 minutes',
                '1900-01-01'::timestamptz
            )
            from {{ this }}
        )
    {% endif %}
),

deduplicated as (
    select *
    from (
        select
            *,
            row_number() over (
                partition by
                    user_id,
                    session_id,
                    event_timestamp,
                    event_name
                order by ingested_at desc
            ) as rn
        from source_data
    ) t
    where rn = 1
)

select
    user_id,
    session_id,
    event_timestamp,
    event_name,
    event_params,
    campaign_id,
    stream_name,
    page_url,
    country,
    is_conversion,
    ingested_at
from deduplicated