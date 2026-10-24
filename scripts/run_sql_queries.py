"""
Run every analysis query in sql/ (files 10_*.sql .. 20_*.sql) against MySQL
and save each result set to sql/outputs/<query_name>[_<n>].csv.

Usage (from the project root):
    python scripts/run_sql_queries.py --user root --password YOURPASSWORD

Options:
    --host      default localhost
    --port      default 3306
    --database  default olist
    --only      run a single file, e.g. --only 12_review_score_vs_delay.sql

Requires: pip install pymysql pandas
"""
import argparse
import glob
import os
import re
import sys

import pandas as pd
import pymysql

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQL_DIR = os.path.join(ROOT, "sql")
OUT_DIR = os.path.join(SQL_DIR, "outputs")


def split_statements(sql_text: str):
    """Split a script on ';' at line ends, ignoring '--' comment lines."""
    lines = []
    for ln in sql_text.splitlines():
        if ln.strip().startswith("--"):
            continue
        lines.append(re.sub(r"\s+--.*$", "", ln))      # drop trailing -- comments
    body = "\n".join(lines)
    statements = [s.strip() for s in re.split(r";\s*\n", body + "\n") if s.strip()]
    return statements


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--port", type=int, default=3306)
    ap.add_argument("--user", default="root")
    ap.add_argument("--password", default="")
    ap.add_argument("--database", default="olist")
    ap.add_argument("--only", default=None)
    args = ap.parse_args()

    os.makedirs(OUT_DIR, exist_ok=True)
    conn = pymysql.connect(host=args.host, port=args.port, user=args.user,
                           password=args.password, database=args.database,
                           charset="utf8mb4")

    files = sorted(glob.glob(os.path.join(SQL_DIR, "[12][0-9]_*.sql")))
    if args.only:
        files = [f for f in files if os.path.basename(f) == args.only]
    if not files:
        sys.exit("No query files found.")

    for path in files:
        name = os.path.splitext(os.path.basename(path))[0]
        with open(path, encoding="utf-8") as fh:
            statements = split_statements(fh.read())
        result_no = 0
        for stmt in statements:
            if stmt.upper().startswith("USE "):
                continue
            df = pd.read_sql(stmt, conn)
            result_no += 1
            suffix = "" if result_no == 1 else f"_{result_no}"
            out = os.path.join(OUT_DIR, f"{name}{suffix}.csv")
            df.to_csv(out, index=False)
            print(f"{name}{suffix}: {len(df):>6} rows -> {os.path.relpath(out, ROOT)}")
    conn.close()


if __name__ == "__main__":
    main()
