{{
    config(
        materialized='table',
        post_hook="COPY {{ this }} TO '../../excel-files/export/f_inventory_balance_{{ modules.datetime.datetime.now().strftime(\"%Y%m%d\") }}.xlsx' WITH (FORMAT xlsx, HEADER true)"
    )
}}

-- calculate current balance of inventory based on f_sales and f_inventory_baseline

with baseline as (
    select 
        category, 
        size, 
        sum(qty) as qty
    from {{ ref('f_inventory_baseline') }}
    group by 1, 2
),

sold as (
    select 
        category, 
        size, 
        sum(qty) as qty
    from {{ ref('f_sales') }}
    group by 1, 2
)

select
    b.category,
    b.size,
    b.qty as baseline_qty,
    coalesce(s.qty, 0)  as sold_qty,
    b.qty - coalesce(s.qty, 0)  as balance_qty,
    current_date as last_update
from baseline b
left join sold s
    on b.category = s.category
    and b.size = s.size
