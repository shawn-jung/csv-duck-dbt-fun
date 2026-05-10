"""
Display current inventory balance from f_inventory_balance.

Usage:
    uv run python show_balance.py           # dev (default)
    uv run python show_balance.py --env prod
"""

import argparse
import os

import duckdb

DB_PATHS = {
    "dev": "duckdb-files/dev.duckdb",
    "prod": "duckdb-files/prod.duckdb",
}

parser = argparse.ArgumentParser()
parser.add_argument("--env", choices=["dev", "prod"], default="dev")
args = parser.parse_args()

db_path = os.path.join(os.path.dirname(__file__), DB_PATHS[args.env])

with duckdb.connect(db_path, read_only=True) as conn:
    df = conn.execute("SELECT * FROM f_inventory_balance ORDER BY category, size").df()

print(f"[{args.env}] f_inventory_balance — {len(df)} rows\n")
print(df.to_string(index=False))
