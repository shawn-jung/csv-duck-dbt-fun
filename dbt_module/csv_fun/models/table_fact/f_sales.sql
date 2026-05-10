{{ config(materialized='table') }}

with raw_in_person_sales as (
    select
        date_event,
        customer_name,
        category,
        size,
        qty,
        qty < 0 as is_return,
        'in_person' as sale_type
    from {{ ref('raw_in_person_orders') }}
    where qty != 0
    /* 0 or null means, they changed mind or we forgot, so no sale that day */
),
in_person_sales as (
    -- todo: i'd do dedupe first and transform, but this is just mere hundres table, so leave it as it is
    {{ dbt_utils.deduplicate(
        relation='raw_in_person_sales',
        partition_by='date_event, customer_name, category, size, qty',
        order_by='date_event',
    )}}
),
raw_cart_sales as (
    select
        date_event,
        customer_name,
        category,
        size,
        qty,
        qty < 0 as is_return,
        'cart_sale' as sale_type
    from {{ ref('raw_cart_sales_by_minh') }}
    where qty != 0
),
cart_sales as (
    {{ dbt_utils.deduplicate(
        relation='raw_cart_sales',
        partition_by='date_event, customer_name, category, size, qty',
        order_by='date_event',
    )}}
)
select * from in_person_sales
union all
select * from cart_sales
