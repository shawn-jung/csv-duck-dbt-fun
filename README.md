# csv-duck-dbt-fun

Inventory tracking pipeline for club apparel using DuckDB + dbt. Ingests data from Google Sheets and Excel files, applies transformations, and exports a balance report to Excel. This could have been a pivot in Excel if I can copy-paste every week, but that's a heavy conginitive load for a person who dreams in dbt and SQL. So I go with duckdb. 

## Setup

### 1. Install dependencies

```bash
uv sync
```

### 2. Set the dbt profiles directory

Must be sourced (not executed) so the export persists in the shell:

```bash
source envset.sh
```

> Note: poe tasks set `DBT_PROFILES_DIR` automatically — `source envset.sh` is only needed when running dbt commands directly.

### 3. Authenticate with Google Sheets (one-time)

Opens a browser for OAuth login and saves a persistent secret to `~/.duckdb/stored_secrets/`:

```bash
uv run python setup_gsheets.py
# or
uv run poe auth
```

Re-run this if you get a `401 UNAUTHENTICATED` error from the gsheets extension — the token has expired.

## Running the pipeline

```bash
uv run poe build        # full pipeline: seed + run + test
```

Or step by step:

```bash
uv run poe seed         # load dim_size, dim_category
uv run poe run          # build all dbt models
uv run poe test         # run data quality tests
```

<details>
<summary>Equivalent raw dbt commands</summary>

```bash
cd dbt-module/csv_fun
uv run dbt seed
uv run dbt run
uv run dbt test
# or all at once
uv run dbt build
```

</details>

After `build`, the inventory balance is exported automatically to `excel-files/export/f_inventory_balance_YYYYMMDD.xlsx`.

To run a single model directly:

```bash
cd dbt-module/csv_fun && uv run dbt run --select f_inventory_balance
```

## Viewing the balance

```bash
uv run poe balance        # dev (default)
uv run poe balance-prod   # prod
```

<details>
<summary>Equivalent raw commands</summary>

```bash
uv run python show_balance.py
uv run python show_balance.py --env prod
```

</details>

## All poe tasks

| Command | Description |
|---|---|
| `uv run poe auth` | One-time Google Sheets OAuth setup |
| `uv run poe seed` | Load seed tables |
| `uv run poe run` | Build all dbt models |
| `uv run poe test` | Run all dbt tests |
| `uv run poe build` | Full pipeline: seed + run + test |
| `uv run poe balance` | Print inventory balance (dev) |
| `uv run poe balance-prod` | Print inventory balance (prod) |
| `uv run poe regular-build` | Auth → build → show prod balance |

## Project structure

```
.
├── envset.sh                        # sets DBT_PROFILES_DIR
├── setup_gsheets.py                 # one-time Google OAuth setup
├── show_balance.py                  # CLI viewer for f_inventory_balance
├── .dbt/
│   └── profiles.yml                 # dbt connection config (dev/prod DuckDB files)
├── duckdb-files/                    # local duckdb files where tables are materialized (gitignored excep prod)
│   ├── dev.duckdb                   
│   └── prod.duckdb
├── excel-files/
│   ├── import/                      # source Excel files
│   └── export/                      # generated balance reports (gitignored except sample)
└── dbt-module/csv_fun/
    ├── seeds/
    │   ├── dim_size.csv             # canonical shirt sizes with sort order
    │   └── dim_category.csv         # canonical shirt categories
    ├── macros/
    │   └── size_category_cleanse.sql  # cleanse_size() macro
    └── models/
        ├── raw/
        │   ├── gsheet/
        │   │   ├── raw_inventory_control_log_gsheet_20241104.sql
        │   │   ├── raw_new_merge_quang_garage.sql
        │   │   └── raw_in_person_orders.sql
        │   └── excel/
        │       └── raw_cart_sales_by_minh.sql
        └── table_fact/
            ├── f_inventory_baseline.sql   # union of all starting inventory
            ├── f_sales.sql                # union of all sales channels (deduped)
            ├── f_inventory_balance.sql    # baseline minus sales, exported to xlsx
            └── f_order.sql                # in-person orders with is_return flag
```

## Data sources

| Model | Source | Notes |
|---|---|---|
| `raw_inventory_control_log_gsheet_20241104` | Google Sheets | Snapshot inventory as of 2024-11-04 |
| `raw_new_merge_quang_garage` | Google Sheets | Merged inventory from Quang's garage |
| `raw_in_person_orders` | Google Sheets | In-person sales log |
| `raw_cart_sales_by_minh` | Excel (`cart-sales-by-minh.xlsx`) | Cart sales recorded by Minh |

## Data quality

- `category` is tested against `['Youth', 'WomenVneck', 'AdultUnisex', 'Hoodie', 'YouthHoodie']`
- `size` is tested against `['XS', 'S', 'M', 'L', 'XL', '2XL']` — the `cleanse_size()` macro normalises variants like `Small`, `Large`, `X-Large`, `XXL` before this test runs
- `f_inventory_balance` warns (but does not fail) when `balance_qty < 0`

## DuckDB concurrency note

DuckDB allows only one writer at a time. When browsing data with the CLI while running dbt, always open the CLI in read-only mode:

```bash
duckdb -readonly duckdb-files/dev.duckdb
```
