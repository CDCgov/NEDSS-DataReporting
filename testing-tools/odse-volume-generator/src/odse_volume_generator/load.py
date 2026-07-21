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
STAGE_ROOT = "/tmp/odse_volume"


def _sqlcmd(sql: str, timeout: int = 7200) -> tuple[int, str]:
    proc = subprocess.run(
        ["docker", "exec", "-i", CONTAINER, "/opt/mssql-tools18/bin/sqlcmd",
         "-C", "-b", "-t", "0", "-S", "localhost", "-U", "sa", "-P", "PizzaIsGood33!",
         "-Q", sql],
        capture_output=True, text=True, timeout=timeout)
    return proc.returncode, (proc.stdout + proc.stderr)


# Disabling the non-unique nonclustered indexes drops per-row index maintenance
# during the load; we rebuild them after. PK/clustered and unique indexes are left
# alone (FK enforcement uses them), so referential integrity holds throughout.
_IDX_WHERE = "i.type_desc='NONCLUSTERED' AND i.is_unique=0 AND i.is_primary_key=0"


def _index_batch(tables: list[str], action: str) -> str:
    tl = ",".join(f"'{t}'" for t in tables)
    return (
        "DECLARE @sql nvarchar(max)=N''; "
        f"SELECT @sql += N'ALTER INDEX '+QUOTENAME(i.name)+N' ON NBS_ODSE.dbo.'"
        f"+QUOTENAME(t.name)+N' {action};'+CHAR(10) "
        "FROM NBS_ODSE.sys.indexes i JOIN NBS_ODSE.sys.tables t ON t.object_id=i.object_id "
        f"WHERE t.name IN ({tl}) AND {_IDX_WHERE}; EXEC sp_executesql @sql;")


def disable_indexes(tables: list[str]) -> tuple[int, str]:
    return _sqlcmd(_index_batch(tables, "DISABLE"))


def rebuild_indexes(tables: list[str]) -> tuple[int, str]:
    return _sqlcmd(_index_batch(tables, "REBUILD"))


def load(manifest_path: Path, stage_suffix: str = "", verbose: bool = True) -> dict:
    m = json.loads(Path(manifest_path).read_text())
    stage = f"{STAGE_ROOT}{('_' + stage_suffix) if stage_suffix else ''}"
    subprocess.run(["docker", "exec", CONTAINER, "mkdir", "-p", stage], check=True)

    results = {}
    # FK-safe order comes from the manifest (parents before children).
    order = m.get("load_order") or list(m["tables"].keys())
    for t in order:
        info = m["tables"][t]
        local = Path(info["path"])
        staged = f"{stage}/{t}.parquet"
        subprocess.run(["docker", "cp", str(local), f"{CONTAINER}:{staged}"], check=True)
        collist = ", ".join(f"[{c}]" for c in info["columns"])
        sql = (f"SET NOCOUNT ON; "
               f"INSERT INTO NBS_ODSE.dbo.[{t}] ({collist}) "
               f"SELECT {collist} FROM OPENROWSET(BULK N'{staged}', FORMAT='PARQUET') AS r;")
        rc, out = _sqlcmd(sql)
        results[t] = {"rc": rc, "out": out.strip()}
        if verbose:
            print(f"  [{'OK' if rc == 0 else 'FAIL'}] {t}: {out.strip() or rc}")
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
