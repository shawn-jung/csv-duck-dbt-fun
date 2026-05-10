{{ config(materialized='table') }}

select 
    Category as category,
    {{ cleanse_size('Size') }} as size,
    coalesce(qty::INTEGER,0) as qty
from '{{ var("gsheet_url", "https://docs.google.com/spreadsheets/d/1Xrm3Luj-ccG2X7OT3kfl2QE6aIX0Z5vd6DGM3ahgoqs/edit?gid=0#gid=0&range=A1:C1000") }}'
