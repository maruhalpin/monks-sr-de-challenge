select *
from {{ ref('int_ga4_sessions') }}
where
       page_views < 0
    or add_to_cart < 0
    or begin_checkout < 0
    or add_payment_info < 0
    or conversions < 0
    or purchase_count < 0
    or revenue < 0