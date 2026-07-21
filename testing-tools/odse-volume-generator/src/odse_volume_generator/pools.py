"""SRTE code pools the generated data must draw from, so FKs resolve and the
program_jurisdiction_oid gate computes. Values verified live against NBS_SRTE by
the domain spec. `refresh_from_db` re-pulls them for schema-evolution safety.
"""

from __future__ import annotations

# (condition_cd, prog_area_cd, condition_short_nm). ACTIVE + routable.
CONDITIONS = [
    ("10110", "HEP", "Hepatitis A, acute"),
    ("10311", "STD", "Syphilis, primary"),
    ("10190", "VPD", "Pertussis"),
    ("10140", "VPD", "Measles (Rubeola)"),
    ("11065", "GCD", "2019 Novel Coronavirus (COVID-19)"),
    ("11066", "GCD", "MIS-C (COVID-19)"),
    ("10130", "GCD", "Malaria"),
    ("10250", "GCD", "Spotted Fever Rickettsiosis"),
    ("11090", "GCD", "Anaplasma phagocytophilum"),
    ("10049", "ARBO", "West Nile virus, non-neuroinvasive"),
    ("10220", "TB", "Tuberculosis"),
    ("10490", "GCD", "Legionellosis"),
]

# prog_area_cd -> nbs_uid
PROGRAM_AREAS = {
    "BMIRD": 8, "GCD": 9, "VPD": 10, "HEP": 11, "HEPC": 12,
    "ARBO": 13, "TB": 14, "STD": 15, "HIV": 16,
}

# (jurisdiction code, nbs_uid). Real counties only; skip 999999 "Out of system".
JURISDICTIONS = [
    ("130001", 13001), ("130002", 13003), ("130004", 13004),
    ("130005", 13005), ("130006", 13006),
]


def oid(jurisdiction_nbs_uid: int, prog_area_cd: str) -> int:
    """program_jurisdiction_oid = jurisdiction.nbs_uid*100000 + program_area.nbs_uid."""
    return jurisdiction_nbs_uid * 100000 + PROGRAM_AREAS[prog_area_cd]


def refresh_from_db(run_sql) -> None:
    """Re-pull pools from live NBS_SRTE. `run_sql(query)->rows` executes and returns
    rows as lists of strings. Call before a large run if the code sets may have drifted.
    """
    global CONDITIONS, PROGRAM_AREAS, JURISDICTIONS
    conds = run_sql(
        "SELECT condition_cd, prog_area_cd, condition_short_nm FROM NBS_SRTE.dbo.condition_code "
        "WHERE status_cd='A' AND prog_area_cd IN "
        "(SELECT prog_area_cd FROM NBS_SRTE.dbo.program_area_code)"
    )
    if conds:
        CONDITIONS = [(c[0], c[1], c[2]) for c in conds]
    pa = run_sql("SELECT prog_area_cd, nbs_uid FROM NBS_SRTE.dbo.program_area_code")
    if pa:
        PROGRAM_AREAS = {r[0]: int(r[1]) for r in pa}
    jc = run_sql("SELECT code, nbs_uid FROM NBS_SRTE.dbo.jurisdiction_code WHERE code <> '999999'")
    if jc:
        JURISDICTIONS = [(r[0], int(r[1])) for r in jc]
