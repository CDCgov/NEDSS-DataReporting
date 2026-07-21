"""Smoke-test generated patients in the classic NBS6 UI.

Logs in once, then for each sampled patient does search -> ViewFile (the search must
precede ViewFile in a session to seat the patient context) and reports what actually
renders: the patient file, the investigation list, and any lab/observation sections.
Read-only against the UI.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

BASE = "http://localhost:7003/nbs"
CONTAINER = "nedss-datareporting-nbs-mssql-1"


def _curl(args: list[str]) -> str:
    p = subprocess.run(["curl", "-s", *args], capture_output=True, text=True)
    return p.stdout


def _sql(q: str) -> list[list[str]]:
    p = subprocess.run(
        ["docker", "exec", CONTAINER, "/opt/mssql-tools18/bin/sqlcmd", "-C", "-h", "-1",
         "-W", "-s", "|", "-S", "localhost", "-U", "sa", "-P", "PizzaIsGood33!",
         "-Q", f"SET NOCOUNT ON; {q}"],
        capture_output=True, text=True)
    rows = []
    for line in p.stdout.splitlines():
        line = line.strip()
        if not line or line.startswith("-") or "rows affected" in line:
            continue
        rows.append([c.strip() for c in line.split("|")])
    return rows


def sample_patients(n: int) -> list[dict]:
    """Prefer patients that have an investigation, so we exercise the full render."""
    q = (f"SELECT TOP {n} CAST(p.person_uid AS varchar), p.last_nm, "
         "CAST(ISNULL(phc.public_health_case_uid,0) AS varchar), "
         "CAST((SELECT COUNT(*) FROM NBS_ODSE.dbo.observation o "
         "      WHERE o.subject_person_uid=p.person_uid) AS varchar) "
         "FROM NBS_ODSE.dbo.person p "
         "LEFT JOIN NBS_ODSE.dbo.participation pt ON pt.subject_entity_uid=p.person_uid "
         "     AND pt.type_cd='SubjOfPHC' "
         "LEFT JOIN NBS_ODSE.dbo.public_health_case phc "
         "     ON phc.public_health_case_uid=pt.act_uid "
         "WHERE p.person_uid>=100000000 AND p.cd='PAT' AND p.person_parent_uid=p.person_uid "
         "  AND pt.act_uid IS NOT NULL "
         "ORDER BY p.person_uid;")
    out = []
    for r in _sql(q):
        if len(r) >= 4 and r[0].isdigit():
            out.append({"mpr": r[0], "last": r[1], "phc": r[2], "obs": int(r[3])})
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=25)
    args = ap.parse_args()

    pats = sample_patients(args.count)
    if not pats:
        print("no generated patients with investigations found")
        return 1

    with tempfile.TemporaryDirectory() as td:
        cj = str(Path(td) / "cj")
        _curl(["-c", cj, f"{BASE}/login", "-o", "/dev/null"])
        home = _curl(["-b", cj, "-c", cj, "-L", "--data-urlencode", "UserName=superuser",
                      "--data-urlencode", "Password=", f"{BASE}/nbslogin", "-o", "-"])
        if "Logout" not in home and "HomePage" not in home:
            print("LOGIN FAILED")
            return 1
        print(f"logged in. smoke-testing {len(pats)} patients\n")
        print(f"{'mpr':>11} {'last':<12} {'file_kb':>7} {'found':>5} {'inv':>4} "
              f"{'lab_sect':>8} {'obs_db':>6}  status")

        ok = fail = 0
        for p in pats:
            res = _curl(["-b", cj, "-c", cj, "-L", "--data-urlencode",
                         f"patientSearchVO.lastName={p['last']}",
                         f"{BASE}/HomePage.do?method=patientSearchSubmit", "-o", "-"])
            found = f"uid={p['mpr']}" in res
            html = _curl(["-b", cj, "-c", cj, "-L",
                          f"{BASE}/PatientSearchResults1.do?ContextAction=ViewFile&uid={p['mpr']}",
                          "-o", "-"])
            err = "Error Page" in html or "NullPointerException" in html
            inv = f"publicHealthCaseUID={p['phc']}" in html
            labs = len(re.findall(r"Lab Report", html))
            status = "FAIL" if (err or not inv) else "ok"
            if status == "ok":
                ok += 1
            else:
                fail += 1
            print(f"{p['mpr']:>11} {p['last'][:12]:<12} {len(html)//1024:>7} "
                  f"{str(found):>5} {str(inv):>4} {labs:>8} {p['obs']:>6}  {status}"
                  + ("  <ERROR PAGE>" if err else ""))

        print(f"\n{ok} ok, {fail} failed out of {len(pats)}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
