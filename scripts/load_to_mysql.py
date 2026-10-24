"""
Load the Olist CSVs into MySQL from Python - same statements as
sql/02_load_data.sql, but the file paths are resolved automatically and
local_infile is enabled on the connection, so it works from any folder
and from MySQL Workbench-only setups.

Usage (from anywhere):
    python scripts/load_to_mysql.py --user root --password YOURPASSWORD

Steps performed:
    1. runs sql/01_create_schema.sql   (creates database + tables)
    2. runs sql/02_load_data.sql       (LOAD DATA LOCAL INFILE x 9)
    3. runs sql/04_create_views_and_fact_table.sql
    4. prints row counts

Requires: pip install pymysql
"""
import argparse
import os
import re
import time

import pymysql

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQL_DIR = os.path.join(ROOT, "sql")
RAW_DIR = os.path.join(ROOT, "data", "raw").replace("\\", "/")


def statements(path: str):
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    # make relative CSV paths absolute (MySQL accepts forward slashes on Windows)
    text = text.replace("'data/raw/", f"'{RAW_DIR}/")
    lines = []
    for ln in text.splitlines():
        if ln.strip().startswith("--"):
            continue
        lines.append(re.sub(r"\s+--.*$", "", ln))      # drop trailing -- comments
    body = "\n".join(lines)
    return [s.strip() for s in re.split(r";\s*\n", body + "\n") if s.strip()]


def run_script(cur, path: str, label: str):
    t0 = time.time()
    for stmt in statements(path):
        cur.execute(stmt)
        if cur.description:          # statement returned rows -> print them
            rows = cur.fetchall()
            cols = [d[0] for d in cur.description]
            print("   " + " | ".join(cols))
            for r in rows:
                print("   " + " | ".join(str(v) for v in r))
    print(f"{label}: done in {time.time() - t0:.1f}s")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--port", type=int, default=3306)
    ap.add_argument("--user", default="root")
    ap.add_argument("--password", default="")
    args = ap.parse_args()

    conn = pymysql.connect(host=args.host, port=args.port, user=args.user,
                           password=args.password, charset="utf8mb4",
                           local_infile=True, autocommit=True)
    cur = conn.cursor()
    try:
        cur.execute("SET GLOBAL local_infile = 1")
    except pymysql.err.OperationalError:
        print("Could not SET GLOBAL local_infile (needs SUPER/SYSTEM_VARIABLES_ADMIN); "
              "continuing - ask an admin to enable it if the load fails.")

    run_script(cur, os.path.join(SQL_DIR, "01_create_schema.sql"), "schema")
    run_script(cur, os.path.join(SQL_DIR, "02_load_data.sql"), "load")
    run_script(cur, os.path.join(SQL_DIR, "04_create_views_and_fact_table.sql"), "views + fact table")
    conn.close()


if __name__ == "__main__":
    main()
