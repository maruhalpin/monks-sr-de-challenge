select *
from {{ ref('fct_campaign_daily') }}
where
       spend < 0
    or clicks < 0
    or impressions < 0
    or conversions < 0
    or purchases < 0
    or revenue < 0
    or clicks > impressions
    or windows_received < 1
    or windows_received > 4