"""
One-time setup: installs the gsheets community extension and authenticates
via browser OAuth. The resulting persistent secret is stored in DuckDB's
secret store (~/.duckdb/stored_secrets/) and reused by all future connections,
including dbt runs, without re-prompting.

Run once from the repo root:
    uv run python setup_gsheets.py
"""

import duckdb
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "dbt-module/csv_fun/dev.duckdb")

conn = duckdb.connect(DB_PATH)

print("Installing gsheets extension from community ...")
conn.execute("INSTALL gsheets FROM community")
conn.execute("LOAD gsheets")
print("Extension loaded.")

print("\nOpening browser for Google authentication ...")
print("(Paste the token shown in the browser back into the terminal if prompted.)\n")
conn.execute("CREATE OR REPLACE PERSISTENT SECRET gsheets_secret (TYPE gsheet)")
print("\nPersistent secret saved.")

# Quick sanity check — reads the first row of the target sheet
SHEET_URL = "https://docs.google.com/spreadsheets/d/1Xrm3Luj-ccG2X7OT3kfl2QE6aIX0Z5vd6DGM3ahgoqs/edit?gid=0#gid=0"
print("\nVerifying access — reading first 3 rows ...")
result = conn.execute(f"SELECT * FROM '{SHEET_URL}' LIMIT 3").fetchdf()
print(result)
print("\nSetup complete. You can now run `dbt run` from dbt-module/csv_fun/.")

conn.close()
