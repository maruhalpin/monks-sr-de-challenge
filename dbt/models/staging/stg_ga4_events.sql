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
    is_conversion
from {{ source('raw', 'google_analytics_events') }}