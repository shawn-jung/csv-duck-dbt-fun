{{ config(severity='warn') }}

-- Returns rows where inventory has gone negative (sold more than baseline).
-- Configured as warn-only: flags the issue without failing the dbt run.
select category, size, balance_qty
from {{ ref('f_inventory_balance') }}
where balance_qty < 0
