"""Verify a generated investigation renders in the classic NBS6 UI.

Follows the OKF ui-visibility recipe: log in as superuser, search the patient by
last name, open the patient file, and confirm the investigation shows in the list.
Shells out to curl so the cookie-jar / form-post / redirect handling matches the
proven recipe exactly.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path


def _curl(args: list[str]) -> tuple[int, str]:
    proc = subprocess.run(["curl", "-s", *args], capture_output=True, text=True)
    return proc.returncode, proc.stdout


def verify(base_url: str, last_name: str, mpr_uid: int, phc_uid: int) -> bool:
    """Return True if the patient file loads and lists the investigation."""
    with tempfile.TemporaryDirectory() as td:
        cj = str(Path(td) / "cj.txt")

        # 1. login page seeds the cookie jar
        _curl(["-c", cj, f"{base_url}/login", "-o", "/dev/null"])
        # 2. authenticate (empty password for superuser; POST to /nbslogin, not the form action)
        _curl(["-b", cj, "-c", cj, "-L",
               "--data-urlencode", "UserName=superuser",
               "--data-urlencode", "Password=",
               f"{base_url}/nbslogin", "-o", str(Path(td) / "home.html")])
        # 3. patient search by last name
        _curl(["-b", cj, "-c", cj, "-L",
               "--data-urlencode", f"patientSearchVO.lastName={last_name}",
               f"{base_url}/HomePage.do?method=patientSearchSubmit",
               "-o", str(Path(td) / "results.html")])
        # 4. open the patient file (uid = MPR/master uid)
        _, file_html = _curl(["-b", cj, "-c", cj, "-L",
                              f"{base_url}/PatientSearchResults1.do?ContextAction=ViewFile&uid={mpr_uid}",
                              "-o", "-"])

        if "Error Page" in file_html or "NullPointerException" in file_html:
            print(f"  FAIL: patient file errored for MPR {mpr_uid}")
            return False
        listed = f"publicHealthCaseUID={phc_uid}" in file_html
        has_inv_section = "Investigation" in file_html
        print(f"  patient file {len(file_html)}b, investigation section={has_inv_section}, "
              f"phc {phc_uid} listed={listed}")
        return listed


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-url", default="http://localhost:7003/nbs")
    ap.add_argument("--last-name", required=True)
    ap.add_argument("--mpr-uid", type=int, required=True)
    ap.add_argument("--phc-uid", type=int, required=True)
    args = ap.parse_args()
    ok = verify(args.base_url, args.last_name, args.mpr_uid, args.phc_uid)
    print("VISIBLE" if ok else "NOT VISIBLE")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
