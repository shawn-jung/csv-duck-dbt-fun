{{ config(materialized='table') }}

select
    category,
    size,
    qty
from {{ ref('raw_inventory_control_log_gsheet_20241104') }}

union all

select
    category,
    size,
    qty
from {{ ref('raw_new_merge_quang_garage') }}
