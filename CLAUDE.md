# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Inventory tracking pipeline for club apparel. Pulls data from Google Sheets and Excel files → DuckDB (via dbt) → exports a balance report to Excel. Two environments: `dev` (`duckdb-files/dev.duckdb`) and `prod` (`duckdb-files/prod.duckdb`).

## Commands

All commands are run from the repo root with `uv run`.

```bash
uv sync                    # install dependencies

uv run poe auth            # one-time Google Sheets OAuth (re-run on 401 errors)
uv run poe build           # full pipeline: seed + run + test
uv run poe seed            # load dim seeds only
uv run poe run             # build all dbt models
uv run poe test            # run dbt tests
uv run poe balance         # print inventory balance (dev)
uv run poe balance-prod    # print inventory balance (prod)
uv run poe lint            # ruff check + ruff format + mypy
uv run poe regular-build   # auth → build → show prod balance

# Single model
cd dbt_module/csv_fun && uv run dbt run --select f_inventory_balance
```

`poe` tasks automatically set `DBT_PROFILES_DIR`. When running raw `dbt` commands directly, first run `source env_set.sh`.

## Architecture

```
Google Sheets ──┐
Excel files  ──┤──▶ raw/ models ──▶ f_inventory_baseline ──┐
                │                                            ├──▶ f_inventory_balance ──▶ .xlsx export
                └──▶ raw/ models ──▶ f_sales  ─────────────┘
```

**dbt project** lives in `dbt_module/csv_fun/`. Profile (`csv_fun`) is in `.dbt/profiles.yml`. All models are materialized as tables.

**Two model layers:**
- `models/raw/gsheet/` — reads live Google Sheets URLs directly via the DuckDB `gsheets` community extension
- `models/raw/excel/` — reads from `excel-files/import/`
- `models/table_fact/` — `f_inventory_baseline` (union of all inventory sources), `f_sales` (union of all sales channels, deduplicated), `f_inventory_balance` (baseline minus sales)

**`f_inventory_balance` post-hook** auto-exports to `excel-files/export/f_inventory_balance_YYYYMMDD.xlsx` on every run.

**Seeds** (`seeds/d_size.csv`, `seeds/d_category.csv`) define canonical sizes and categories. The `cleanse_size()` macro (`macros/size_category_cleanse.sql`) normalises size variants (e.g. `Small` → `S`, `XXL` → `2XL`) before tests run.

**`on-run-start`** in `dbt_project.yml` loads the `gsheets` and `excel` DuckDB extensions at the start of every run — no need to install them manually after `setup_gsheets.py` has been run once.

## Data contracts

`f_sales` and `f_inventory_baseline` have enforced model contracts. Schema changes require updating `models/table_fact/schema.yml`.

Valid `category` values: `Youth`, `WomenVneck`, `AdultUnisex`, `Hoodie`, `YouthHoodie`
Valid `size` values: `XS`, `S`, `M`, `L`, `XL`, `2XL`

`f_inventory_balance` warns (does not fail) when `balance_qty < 0` — see `tests/warn_negative_balance_qty.sql`.

## DuckDB concurrency

DuckDB allows only one writer. When browsing data while dbt is running, open the CLI read-only:

```bash
duckdb -readonly duckdb-files/dev.duckdb
```

## Python tooling

- **Package manager:** `uv` (Python 3.13 pinned in `.python-version`)
- **Linter/formatter:** `ruff` (line length 100, checks: W, F, I, B, SIM)
- **Type checker:** `mypy` (strict=false; `dbt_module/` excluded)
- **Pre-commit hooks:** trailing whitespace, LF endings, YAML/TOML validation, ruff
