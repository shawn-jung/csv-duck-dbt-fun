{{ config(materialized='table') }}

select 
    type as category,
    {{ cleanse_size('size') }} as size,
    coalesce(quantity::INTEGER,0) as qty
from '{{ var("gsheet_url", "https://docs.google.com/spreadsheets/d/1Xrm3Luj-ccG2X7OT3kfl2QE6aIX0Z5vd6DGM3ahgoqs/edit?gid=1437600504#gid=1437600504&range=A1:C1000") }}'
