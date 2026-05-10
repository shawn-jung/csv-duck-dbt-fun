{{ config(materialized='table') }}

select
    Date::DATE  as date_event,
    Customer as customer_name,
    Category as category,
    {{ cleanse_size('Size') }} as size,
    coalesce(Qty::INTEGER, 0) as qty
from read_xlsx('{{ var("cart_sales_minh_path", "../../excel-files/import/cart-sales-by-minh.xlsx") }}')
