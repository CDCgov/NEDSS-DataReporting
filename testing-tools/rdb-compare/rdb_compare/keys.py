"""Per-table business/UID key resolution for the RDB vs RDB_MODERN comparison.

Rows are matched across the two databases on a table's *business* key -- the
stable identifier that originates in the source system (ODSE) and is therefore
identical in both RDB and RDB_MODERN. They are **never** matched on the
surrogate ``*_KEY`` columns, which carry documented per-table offsets (see the
reporting-differences page: PATIENT_KEY's offset cascades through every other
``*_KEY``).

The project convention (from the reporting work and the comparison SQL
templates) is that the stable cross-DB business key is usually a ``*_LOCAL_ID``
column (the ODSE local id), occasionally a ``*_UID``. A few tables hold several
rows per id and need a 2-column key (e.g. ``LAB100`` keys on both
``LAB_RPT_LOCAL_ID`` and ``LAB_RPT_UID``).

:data:`KEY_CONFIG` pins the keys for tables the page/templates name explicitly;
everything else falls through to :func:`resolve_keys`'s heuristic
(``*_LOCAL_ID`` -> ``*_UID`` -> none).
"""

from __future__ import annotations

# Explicit per-table keys, keyed by UPPERCASE table name. Each value is the
# tuple of key column(s). Basis cited per entry from /tmp/rtr-diffs.txt (the
# RTR reporting-differences page) and the in-repo datamart DDL.
KEY_CONFIG: dict[str, tuple[str, ...]] = {
    # --- Single-UID tables (PDF "Comparable Records Using a Single UID") -----
    # The single-UID SQL template ships with @TableName='LAB_TEST',
    # @UniqueIdColumn='LAB_TEST_UID'.
    "LAB_TEST": ("LAB_TEST_UID",),
    # --- Two-id tables (PDF "Comparable Results Using 2 IDs") ----------------
    # The 2-id SQL template ships with @TableName='LAB100',
    # @UniqueIdColumn='LAB_RPT_LOCAL_ID', @SecondaryUniqueIdColumn='LAB_RPT_UID'.
    # The page also notes "LAB_RPT_LOCAL_ID and LAB_RPT_UID were used" for LAB100.
    "LAB100": ("LAB_RPT_LOCAL_ID", "LAB_RPT_UID"),
    # --- Patient ------------------------------------------------------------
    # Probable-bugs section: records were matched on PATIENT_UID; the 2-id
    # discussion pairs PATIENT_LOCAL_ID with INVESTIGATION_LOCAL_ID. The local
    # id is the stable cross-DB key for the patient dimension.
    "D_PATIENT": ("PATIENT_LOCAL_ID",),
    # --- Investigation ------------------------------------------------------
    # Page repeatedly matches investigations on INVESTIGATION_LOCAL_ID
    # (e.g. "The local ID for the investigation is CAS10063001GA01");
    # INVESTIGATION_KEY (surrogate) is explicitly an offset column and must not
    # be used.
    "INVESTIGATION": ("INVESTIGATION_LOCAL_ID",),
    # --- Morbidity report ---------------------------------------------------
    # The morbidity_report_datamart DDL exposes MORBIDITY_REPORT_LOCAL_ID; the
    # page discusses MORBIDITY_REPORT differences keyed on the local id.
    "MORBIDITY_REPORT": ("MORBIDITY_REPORT_LOCAL_ID",),
    "MORBIDITY_REPORT_DATAMART": ("MORBIDITY_REPORT_LOCAL_ID",),
    # --- Notification -------------------------------------------------------
    # Page lists NOTIFICATION_LOCAL_ID among the compared identifiers; the
    # datamarts carry NOTIFICATION_LOCAL_ID.
    "NOTIFICATION": ("NOTIFICATION_LOCAL_ID",),
    # --- D_INV_* dimensional tables -----------------------------------------
    # Offset section: "the D_INV_* tables have a column called
    # NBS_CASE_ANSWER_UID which originates from the ODSE table NBS_CASE_ANSWER.
    # This value was used to find the NBS_CASE_ANSWER record to ensure the
    # compared D_INV_* records from both databases were valid." So the stable
    # cross-DB key for these is NBS_CASE_ANSWER_UID, not the D_INV_*_KEY
    # surrogate.
    "D_INV_ADMINISTRATIVE": ("NBS_CASE_ANSWER_UID",),
    "D_INV_CLINICAL": ("NBS_CASE_ANSWER_UID",),
    "D_INV_COMPLICATION": ("NBS_CASE_ANSWER_UID",),
    "D_INV_CONTACT": ("NBS_CASE_ANSWER_UID",),
    "D_INV_DEATH": ("NBS_CASE_ANSWER_UID",),
    "D_INV_EPIDEMIOLOGY": ("NBS_CASE_ANSWER_UID",),
    "D_INV_HIV": ("NBS_CASE_ANSWER_UID",),
    "D_INV_ISOLATE_TRACKING": ("NBS_CASE_ANSWER_UID",),
    "D_INV_LAB_FINDING": ("NBS_CASE_ANSWER_UID",),
    "D_INV_MEDICAL_HISTORY": ("NBS_CASE_ANSWER_UID",),
    "D_INV_MOTHER": ("NBS_CASE_ANSWER_UID",),
    "D_INV_OTHER": ("NBS_CASE_ANSWER_UID",),
    "D_INV_PATIENT_OBS": ("NBS_CASE_ANSWER_UID",),
    "D_INV_PREGNANCY_BIRTH": ("NBS_CASE_ANSWER_UID",),
    "D_INV_RESIDENCY": ("NBS_CASE_ANSWER_UID",),
    "D_INV_RISK_FACTOR": ("NBS_CASE_ANSWER_UID",),
    "D_INV_SOCIAL_HISTORY": ("NBS_CASE_ANSWER_UID",),
    "D_INV_SYMPTOM": ("NBS_CASE_ANSWER_UID",),
    "D_INV_TRAVEL": ("NBS_CASE_ANSWER_UID",),
    "D_INV_VACCINATION": ("NBS_CASE_ANSWER_UID",),
}


def _suffix_matches(column: str, suffix: str) -> bool:
    """True if ``column`` ends with ``suffix`` (case-insensitive)."""
    return column.upper().endswith(suffix.upper())


def resolve_keys(
    table: str, available_columns: tuple[str, ...] | list[str]
) -> tuple[str, ...] | None:
    """Resolve the business/UID key column(s) for ``table``.

    Precedence:

    1. If ``UPPER(table)`` is in :data:`KEY_CONFIG` *and* every configured
       column is present in ``available_columns`` (case-insensitive), return the
       configured columns, spelled as they actually appear in
       ``available_columns``.
    2. Else, if at least one ``*_LOCAL_ID`` column is present, return the single
       best one: prefer one whose prefix matches the table's entity name, else
       the first such column in ``available_columns`` order.
    3. Else, if a ``*_UID`` column exists (and is not a surrogate ``*_KEY``),
       return it (the first in column order).
    4. Else ``None`` -- no usable key; the caller compares counts/existence only.

    A surrogate ``*_KEY`` column is **never** returned as a key.

    :param table: table name (any case).
    :param available_columns: columns actually present on the table.
    :returns: a tuple of key column name(s) as they appear in
        ``available_columns``, or ``None``.
    """
    cols = list(available_columns)
    # Case-insensitive lookup: UPPER(col) -> actual spelling (first wins).
    by_upper: dict[str, str] = {}
    for c in cols:
        by_upper.setdefault(c.upper(), c)

    # (1) Configured keys -- require every configured column to be available.
    configured = KEY_CONFIG.get(table.upper())
    if configured and all(c.upper() in by_upper for c in configured):
        return tuple(by_upper[c.upper()] for c in configured)

    # (2) *_LOCAL_ID columns, preferring an entity-matching prefix.
    local_ids = [c for c in cols if _suffix_matches(c, "_LOCAL_ID")]
    if local_ids:
        entity = table.upper().lstrip("D_").lstrip("F_")  # strip dim/fact prefix
        for c in local_ids:
            prefix = c.upper()[: -len("_LOCAL_ID")]
            if prefix and (entity.startswith(prefix) or prefix.startswith(entity)):
                return (c,)
        return (local_ids[0],)

    # (3) *_UID fallback, never a surrogate *_KEY.
    uids = [
        c
        for c in cols
        if _suffix_matches(c, "_UID") and not _suffix_matches(c, "_KEY")
    ]
    if uids:
        return (uids[0],)

    # (4) Nothing usable.
    return None
