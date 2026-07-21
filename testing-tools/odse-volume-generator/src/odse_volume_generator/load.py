"""Bulk-load the generated Parquet into NBS_ODSE via native OPENROWSET.

SQL Server 2022 reads a local Parquet file directly with
OPENROWSET(BULK '<path>', FORMAT='PARQUET'). We copy each table's Parquet into the
mssql container and INSERT ... SELECT from it, one set-based statement per table. No
row-by-row INSERTs, no S3/external data source.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

CONTAINER = "nedss-datareporting-nbs-mssql-1"
STAGE = "/tmp/odse_volume"


def _sqlcmd(sql: str) -> tuple[int, str]:
    proc = subprocess.run(
        ["docker", "exec", "-i", CONTAINER, "/opt/mssql-tools18/bin/sqlcmd",
         "-C", "-b", "-S", "localhost", "-U", "sa", "-P", "PizzaIsGood33!",
         "-Q", sql],
        capture_output=True, text=True)
    return proc.returncode, (proc.stdout + proc.stderr)


def load(manifest_path: Path) -> dict:
    m = json.loads(Path(manifest_path).read_text())
    subprocess.run(["docker", "exec", CONTAINER, "mkdir", "-p", STAGE], check=True)

    results = {}
    # FK-safe order comes from the manifest (parents before children).
    order = m.get("load_order") or list(m["tables"].keys())
    for t in order:
        info = m["tables"][t]
        local = Path(info["path"])
        staged = f"{STAGE}/{t}.parquet"
        subprocess.run(["docker", "cp", str(local), f"{CONTAINER}:{staged}"], check=True)
        collist = ", ".join(f"[{c}]" for c in info["columns"])
        sql = (f"SET NOCOUNT ON; "
               f"INSERT INTO NBS_ODSE.dbo.[{t}] ({collist}) "
               f"SELECT {collist} FROM OPENROWSET(BULK N'{staged}', FORMAT='PARQUET') AS r; "
               f"SELECT '{t}', @@ROWCOUNT;")
        rc, out = _sqlcmd(sql)
        results[t] = {"rc": rc, "out": out.strip()}
        status = "OK" if rc == 0 else "FAIL"
        print(f"  [{status}] {t}: {out.strip().splitlines()[-1] if out.strip() else rc}")
        if rc != 0:
            break
    return results


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default="out/manifest.json")
    args = ap.parse_args()
    res = load(Path(args.manifest))
    ok = all(r["rc"] == 0 for r in res.values())
    print("LOAD OK" if ok else "LOAD FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
