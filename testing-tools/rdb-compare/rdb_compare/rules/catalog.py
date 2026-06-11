"""The default known-differences catalog, transcribed from the RTR page.

This module is the single, human-curated source of truth that turns the
"RTR reporting differences" page into executable :class:`~rdb_compare.rules.types.Rule`
objects. :func:`build_default_registry` assembles every rule into a populated
:class:`~rdb_compare.rules.RuleRegistry` for the classifier.

The rules are grouped to mirror the page's own sections:

* **SKIP_TABLES** -- "RDB Tables Not Considered for Comparison": whole tables /
  table families excluded from the comparison.
* **IGNORE_COLUMNS** -- "Identified Offset for ``_KEY`` Columns" (surrogate-key
  offsets, ``category="key_offset"``) and the environment/timestamp columns the
  page repeatedly calls out as non-issues (``category="env_timestamp"``).
* **EXPECTED** -- "Expected Differences": documented, by-design divergences.
* **KNOWN_BUGS** -- "Unexpected Differences (Probable Bugs)": documented probable
  defects, each with a short ``RTR-diffs:bug-<n>`` reference.

Where the page names exact ``table.column`` pairs, the rule is column-specific;
where it only names a table (e.g. "D_PLACE is not populated") the rule uses a
``"*"`` column pattern and the reason explains the scope. Predicates are attached
where the page describes the *shape* of the difference (NULL-in-RDB vs populated,
NULL vs empty-string, etc.) so a column only gets the documented verdict when its
mismatches actually fit that shape.
"""

from __future__ import annotations

from rdb_compare.rules import (
    ExpectedDiffRule,
    IgnoreColumnRule,
    KnownBugRule,
    RuleRegistry,
    SkipTableRule,
)
from rdb_compare.rules.predicates import (
    modern_null_rdb_set,
    null_vs_empty,
    rdb_null_modern_set,
)


# =====================================================================
# RDB Tables Not Considered for Comparison  -> SkipTableRule
# =====================================================================
# The page lists explicit ETL/event-metric tables plus several table
# *families* identified by prefix, and RDB_MODERN-only staging tables.
SKIP_TABLES = [
    # --- explicitly named skip-list tables ---
    SkipTableRule("ETL_DQ_LOG", "Skip-list: ETL data-quality log, not compared.", id="SKIP-ETL_DQ_LOG"),
    SkipTableRule(
        "ETL_HEALTH_CHECK_PAT_DATA",
        "Skip-list: ETL health-check table, not compared.",
        id="SKIP-ETL_HEALTH_CHECK_PAT_DATA",
    ),
    SkipTableRule("ETL_MISSING_PATIENT", "Skip-list: ETL bookkeeping table, not compared.", id="SKIP-ETL_MISSING_PATIENT"),
    SkipTableRule("ETL_MISSING_RECORD", "Skip-list: ETL bookkeeping table, not compared.", id="SKIP-ETL_MISSING_RECORD"),
    SkipTableRule("ETL_PROCESS", "Skip-list: ETL process bookkeeping, not compared.", id="SKIP-ETL_PROCESS"),
    SkipTableRule(
        "EVENT_METRIC",
        "Skip-list: time-bound metric table (RDB holds only ~last 30 days; RTR "
        "does not age records out), so it is excluded from comparison.",
        id="SKIP-EVENT_METRIC",
    ),
    SkipTableRule(
        "EVENT_METRIC_INC",
        "Skip-list: time-bound incremental metric table, excluded from comparison.",
        id="SKIP-EVENT_METRIC_INC",
    ),
    # --- table families named by prefix ---
    SkipTableRule("ETL_*", "Skip-list: all ETL_* bookkeeping/process tables.", id="SKIP-ETL_PREFIX"),
    SkipTableRule("L_*", "Skip-list: lookup tables (prefixed L_).", id="SKIP-LOOKUP_L_PREFIX"),
    SkipTableRule("LOOKUP_*", "Skip-list: lookup tables (prefixed LOOKUP_).", id="SKIP-LOOKUP_PREFIX"),
    SkipTableRule("S_*", "Skip-list: staging tables (prefixed S_).", id="SKIP-STAGING_S_PREFIX"),
    SkipTableRule("SAS_*", "Skip-list: SAS tables (prefixed SAS_).", id="SKIP-SAS_PREFIX"),
    SkipTableRule(
        "TEMP_*",
        "Skip-list: temporary tables (prefixed TEMP_, case-insensitive).",
        id="SKIP-TEMP_PREFIX",
    ),
    SkipTableRule(
        "nrt_*",
        "Skip-list: RDB_MODERN-only staging tables (e.g. nrt_investigation, "
        "nrt_patient); no RDB counterpart to compare.",
        id="SKIP-NRT_PREFIX",
    ),
    # --- APP-720: transient SELECT INTO scratch / working tables ---
    # These are intermediate tables the SAS MasterETL and RTR pipelines build
    # with SELECT INTO mid-run (UID worklists, staging/keystores, *_REPT report
    # intermediates, temp/incremental scratch). They are not reporting output:
    # in the captured runs they were `presence=both` with no column verdict, and
    # whether they exist at scan time depends on run timing/cleanup -- so counting
    # them in discovered/compared makes the totals non-comparable run-to-run
    # (the spurious "7.12=202 vs 7.13=180" table-count delta). The existing
    # ETL_*/L_*/S_*/SAS_*/TEMP_* families miss them only because those globs are
    # prefix-anchored. Patterns below are scoped to match ONLY these scratch
    # tables in the APP-720 7.12/7.13 universe (verified -- no real comparand hit).
    SkipTableRule("PHC_*", "Skip-list: transient PHC UID worklists/keys built via SELECT INTO; not reporting output.", id="SKIP-PHC_PREFIX"),
    SkipTableRule("*_REPT", "Skip-list: SAS report-build intermediate tables (suffix _REPT); not compared.", id="SKIP-REPT_SUFFIX"),
    SkipTableRule("*_REPT_*", "Skip-list: SAS report-build intermediate/temp tables (e.g. *_REPT_TEMP, *_REPT_FINAL).", id="SKIP-REPT_INFIX"),
    SkipTableRule("STAGING_*", "Skip-list: staging tables (prefixed STAGING_).", id="SKIP-STAGING_PREFIX"),
    SkipTableRule("*_KEYS", "Skip-list: key-mapping scratch tables (suffix _KEYS, e.g. DIMENSIONAL_KEYS, PHC_KEYS).", id="SKIP-KEYS_SUFFIX"),
    SkipTableRule("*KEYSTORE*", "Skip-list: entity keystore scratch tables (e.g. ENTITY_KEYSTORE_STD/INC).", id="SKIP-KEYSTORE"),
    SkipTableRule("TMP_*", "Skip-list: temporary tables (prefixed TMP_; complements TEMP_*).", id="SKIP-TMP_PREFIX"),
    SkipTableRule("*TEMP_INC", "Skip-list: incremental temp scratch (e.g. F_PAGE_CASE_TEMP_INC); TEMP_* glob is prefix-only.", id="SKIP-TEMP_INC_SUFFIX"),
    SkipTableRule("UPDATED_*_LIST", "Skip-list: ETL delta worklists (e.g. UPDATED_OBSERVATION_LIST); not reporting output.", id="SKIP-UPDATED_LIST"),
    SkipTableRule("DIMENSION_KEYS_PAGECASEID", "Skip-list: page-case-id key-mapping scratch table.", id="SKIP-DIMENSION_KEYS_PAGECASEID"),
    SkipTableRule("ACTIVITY_LOG_MASTER_LAST_SAS", "Skip-list: SAS MasterETL run-bookkeeping table; not compared.", id="SKIP-ACTIVITY_LOG_MASTER_LAST_SAS"),
    SkipTableRule("INIT", "Skip-list: ETL init/bootstrap scratch table; not reporting output.", id="SKIP-INIT"),
    # F_S_* are staging fact intermediates (the _S_ infix mirrors the existing
    # S_* staging family). Only these two were verified transient (they dropped
    # out of the 7.13 scan); F_S_TB_PAM / F_S_VAR_PAM persist in both runs and
    # are left in scope pending confirmation -- revisit whether F_S_* should be a
    # family skip once those two are characterized.
    SkipTableRule("F_S_INV_CASE", "Skip-list: staging fact intermediate (SELECT INTO); not reporting output.", id="SKIP-F_S_INV_CASE"),
    SkipTableRule("F_S_STD_HIV_CASE", "Skip-list: staging fact intermediate (SELECT INTO); not reporting output.", id="SKIP-F_S_STD_HIV_CASE"),
]


# =====================================================================
# Identified Offset for _KEY Columns + environment/timestamp columns
#   -> IgnoreColumnRule
# =====================================================================
IGNORE_COLUMNS = [
    # --- surrogate-key offsets (category="key_offset") ---
    # The PATIENT_KEY offset in D_PATIENT cascades into every *_KEY column.
    # MasterETL not capturing the very first patient record shifts the
    # surrogate keys, so all *_KEY columns carry a documented offset.
    IgnoreColumnRule(
        "*_KEY",
        "Identified Offset for _KEY Columns: surrogate *_KEY values carry a "
        "documented offset (the D_PATIENT PATIENT_KEY offset cascades through "
        "all *_KEY columns). Rows are matched on business/UID keys, not *_KEY. "
        "A value of 1 typically flags missing/unfetched data and is worth a "
        "double-check.",
        category="key_offset",
        id="IGN-key_offset-ALL",
    ),
    IgnoreColumnRule(
        "RESULTED_LAB_TEST_KEY",
        "Identified Offset for _KEY Columns: RESULTED_LAB_TEST_KEY shares the "
        "LAB_TEST_KEY offset behaviour.",
        category="key_offset",
        id="IGN-key_offset-RESULTED_LAB_TEST_KEY",
    ),
    IgnoreColumnRule(
        "INVESTIGATION_KEYS",
        "Identified Offset for _KEY Columns: plural INVESTIGATION_KEYS column "
        "(e.g. in LAB100) carries the same surrogate-key offset.",
        category="key_offset",
        id="IGN-key_offset-INVESTIGATION_KEYS",
    ),
    # --- environment / refresh timestamp columns (category="env_timestamp") ---
    # RTR and the SAS/MasterETL environments stamp refresh/update times at
    # different moments, so these never match and are non-issues.
    IgnoreColumnRule(
        "RDB_LAST_REFRESH_TIME",
        "Environment timestamp: RDB_LAST_REFRESH_TIME reflects when each "
        "pipeline refreshed the table (SAS/MasterETL vs RTR services); values "
        "differ by environment date/time configuration and are a non-issue.",
        category="env_timestamp",
        id="IGN-env_timestamp-RDB_LAST_REFRESH_TIME",
    ),
    IgnoreColumnRule(
        "*_LAST_REFRESH_TIME",
        "Environment timestamp: any *_LAST_REFRESH_TIME column reflects the "
        "differing refresh process between MasterETL and RTR; non-issue.",
        category="env_timestamp",
        id="IGN-env_timestamp-LAST_REFRESH_TIME",
    ),
    IgnoreColumnRule(
        "*_LAST_UPDATE_DT",
        "Environment timestamp: *_LAST_UPDATE_DT values diverge because of "
        "date/time configuration differences between the SAS and RTR "
        "environments (e.g. LAB_RPT_LAST_UPDATE_DT on LAB_TEST/LAB100).",
        category="env_timestamp",
        id="IGN-env_timestamp-LAST_UPDATE_DT",
    ),
    IgnoreColumnRule(
        "*_LAST_CHANGE_TIME",
        "Environment timestamp: *_LAST_CHANGE_TIME values can differ by a few "
        "days where NBS6 defects were corrected in NBS7 / RTR (e.g. "
        "PATIENT_LAST_CHANGE_TIME on D_PATIENT); treated as env/timestamp.",
        category="env_timestamp",
        id="IGN-env_timestamp-LAST_CHANGE_TIME",
    ),
    IgnoreColumnRule(
        "PHC_LAST_CHG_TIME",
        "Environment timestamp: PHC_LAST_CHG_TIME can hold an outdated stamp in "
        "legacy RDB (e.g. CASE_LAB_DATAMART); RTR populates correctly.",
        category="env_timestamp",
        id="IGN-env_timestamp-PHC_LAST_CHG_TIME",
    ),
]


# =====================================================================
# Expected Differences  -> ExpectedDiffRule
# =====================================================================
# Documented, by-design divergences. Many follow the "NULL in legacy RDB,
# correctly populated in RDB_MODERN" shape (NBS6 defects fixed in NBS7),
# so they carry the rdb_null_modern_set predicate.
EXPECTED = [
    # LDF_DIMENSIONAL_DATA vs staging existence note (APP-607).
    ExpectedDiffRule(
        "LDF_DIMENSIONAL_DATA",
        "*",
        "Expected: LDF_DIMENSIONAL_DATA does not exist in RDB but is populated "
        "in RDB_MODERN; the S_LDF_DIMENSIONAL_DATA staging side is the inverse "
        "(APP-607).",
        id="EXP-LDF_DIMENSIONAL_DATA",
    ),
    # 3. EVENT_METRIC(_INC) ADD_USER_NAME / LAST_CHG_USER_NAME populated in modern.
    ExpectedDiffRule(
        "EVENT_METRIC*",
        "ADD_USER_NAME",
        "Expected: RDB EVENT_METRIC/EVENT_METRIC_INC is missing ADD_USER_NAME, "
        "while RDB_Modern populates it correctly.",
        predicate=rdb_null_modern_set,
        id="EXP-EVENT_METRIC-ADD_USER_NAME",
    ),
    ExpectedDiffRule(
        "EVENT_METRIC*",
        "LAST_CHG_USER_NAME",
        "Expected: RDB EVENT_METRIC/EVENT_METRIC_INC is missing "
        "LAST_CHG_USER_NAME, while RDB_Modern populates it correctly.",
        predicate=rdb_null_modern_set,
        id="EXP-EVENT_METRIC-LAST_CHG_USER_NAME",
    ),
    # 8. CASE_LAB_DATAMART.EVENT_DATE_TYPE NULL in RDB, populated in modern.
    ExpectedDiffRule(
        "CASE_LAB_DATAMART",
        "EVENT_DATE_TYPE",
        "Expected: EVENT_DATE_TYPE is NULL in legacy RDB but populated (e.g. "
        "'Illness Onset Date') in RDB_MODERN; RTR correctly derives it.",
        predicate=rdb_null_modern_set,
        id="EXP-CASE_LAB_DATAMART-EVENT_DATE_TYPE",
    ),
    # 9. D_INV_MEDICAL_HISTORY: three fields NULL in RDB, populated in modern.
    ExpectedDiffRule(
        "D_INV_MEDICAL_HISTORY",
        "MDH_PREEXISTING_COND_IND",
        "Expected: NULL in legacy RDB, correctly populated in RDB_MODERN "
        "(RTR consolidates question/answer combos to a single "
        "nbs_case_answer_uid).",
        predicate=rdb_null_modern_set,
        id="EXP-D_INV_MEDICAL_HISTORY-MDH_PREEXISTING_COND_IND",
    ),
    ExpectedDiffRule(
        "D_INV_MEDICAL_HISTORY",
        "MDH_REASON_FOR_TEST",
        "Expected: NULL in legacy RDB, correctly populated in RDB_MODERN "
        "(e.g. 'Screening').",
        predicate=rdb_null_modern_set,
        id="EXP-D_INV_MEDICAL_HISTORY-MDH_REASON_FOR_TEST",
    ),
    ExpectedDiffRule(
        "D_INV_MEDICAL_HISTORY",
        "MDH_SYMPTOMATIC",
        "Expected: NULL in legacy RDB, correctly populated in RDB_MODERN "
        "(e.g. 'Yes').",
        predicate=rdb_null_modern_set,
        id="EXP-D_INV_MEDICAL_HISTORY-MDH_SYMPTOMATIC",
    ),
    # 11. D_INV_SOCIAL_HISTORY: pipe-doubled values cleaned up in NBS7.
    ExpectedDiffRule(
        "D_INV_SOCIAL_HISTORY",
        "SOC_PLACES_TO_HAVE_SEX",
        "Expected: legacy RDB stored doubled values (e.g. 'Yes|Yes'); NBS7/RTR "
        "stores the de-duplicated value (e.g. 'Yes') -- a data-quality "
        "improvement.",
        id="EXP-D_INV_SOCIAL_HISTORY-SOC_PLACES_TO_HAVE_SEX",
    ),
    ExpectedDiffRule(
        "D_INV_SOCIAL_HISTORY",
        "PLACES_TO_MEET_PARTNER",
        "Expected: legacy RDB stored 'Yes|Yes'; NBS7/RTR stores 'Yes' -- "
        "data-quality improvement.",
        id="EXP-D_INV_SOCIAL_HISTORY-PLACES_TO_MEET_PARTNER",
    ),
    ExpectedDiffRule(
        "D_INV_SOCIAL_HISTORY",
        "SOC_PRTNRS_PRD_MALE_IND",
        "Expected: legacy RDB stored 'No|No'; NBS7/RTR stores 'No' -- "
        "data-quality improvement.",
        id="EXP-D_INV_SOCIAL_HISTORY-SOC_PRTNRS_PRD_MALE_IND",
    ),
    ExpectedDiffRule(
        "D_INV_SOCIAL_HISTORY",
        "SOC_PRTNRS_PRD_TRNSGNDR_IND",
        "Expected: legacy RDB stored 'No|No'; NBS7/RTR stores 'No' -- "
        "data-quality improvement.",
        id="EXP-D_INV_SOCIAL_HISTORY-SOC_PRTNRS_PRD_TRNSGNDR_IND",
    ),
    # 12. D_INV_SUMM_DATAMART: NULL in RDB, populated in modern.
    ExpectedDiffRule(
        "D_INV_SUMM_DATAMART",
        "EVENT_DATE_TYPE",
        "Expected: NULL in legacy RDB, populated as 'Investigation Start Date' "
        "in RDB_MODERN (RTR correct).",
        predicate=rdb_null_modern_set,
        id="EXP-D_INV_SUMM_DATAMART-EVENT_DATE_TYPE",
    ),
    ExpectedDiffRule(
        "D_INV_SUMM_DATAMART",
        "CONFIRMATION_METHOD",
        "Expected: NULL in legacy RDB, populated as 'Active Surveillance' in "
        "RDB_MODERN (RTR correct).",
        predicate=rdb_null_modern_set,
        id="EXP-D_INV_SUMM_DATAMART-CONFIRMATION_METHOD",
    ),
    # 13. DM_INV_GENERIC_V2: confirmation fields NULL in RDB, populated in modern.
    ExpectedDiffRule(
        "DM_INV_GENERIC_V2",
        "CONFIRMATION_DT",
        "Expected: NULL in legacy RDB, correctly populated in RDB_MODERN.",
        predicate=rdb_null_modern_set,
        id="EXP-DM_INV_GENERIC_V2-CONFIRMATION_DT",
    ),
    ExpectedDiffRule(
        "DM_INV_GENERIC_V2",
        "CONFIRMATION_METHOD",
        "Expected: NULL in legacy RDB, correctly populated in RDB_MODERN.",
        predicate=rdb_null_modern_set,
        id="EXP-DM_INV_GENERIC_V2-CONFIRMATION_METHOD",
    ),
    ExpectedDiffRule(
        "DM_INV_GENERIC_V2",
        "EVENT_DATE_TYPE",
        "Expected: NULL in legacy RDB, correctly populated in RDB_MODERN.",
        predicate=rdb_null_modern_set,
        id="EXP-DM_INV_GENERIC_V2-EVENT_DATE_TYPE",
    ),
    # 22. DM_INV_GENERIC_V2.BINATIONAL_RPTNG_CRIT: MasterETL not updating it.
    ExpectedDiffRule(
        "DM_INV_GENERIC_V2",
        "BINATIONAL_RPTNG_CRIT",
        "Expected: MasterETL does not update BINATIONAL_RPTNG_CRIT on "
        "investigation changes; RTR updates it correctly.",
        id="EXP-DM_INV_GENERIC_V2-BINATIONAL_RPTNG_CRIT",
    ),
    # 16. COVID_LAB_CELR_DATAMART.File_created_date uses GetDate() at insert.
    ExpectedDiffRule(
        "COVID_LAB_CELR_DATAMART",
        "FILE_CREATED_DATE",
        "Expected: File_created_date is set to insertion time via GetDate(), so "
        "it never matches between Covid19ETL and RTR.",
        id="EXP-COVID_LAB_CELR_DATAMART-FILE_CREATED_DATE",
    ),
    # 17. TB_HIV_DATAMART / TB_DATAMART: RDB values incorrect, modern correct.
    ExpectedDiffRule(
        "TB_HIV_DATAMART",
        "PHYSICIAN_FIRST_NAME",
        "Expected: RDB value is incorrect (e.g. 'Chung_FAKE'); RDB_MODERN "
        "derives the correct value from Ordering Provider.",
        id="EXP-TB_HIV_DATAMART-PHYSICIAN_FIRST_NAME",
    ),
    ExpectedDiffRule(
        "TB_HIV_DATAMART",
        "REPORTING_SOURCE_NAME",
        "Expected: RDB value is incorrect (NULL); RDB_MODERN derives the "
        "correct value from Reporting Facility.",
        id="EXP-TB_HIV_DATAMART-REPORTING_SOURCE_NAME",
    ),
    ExpectedDiffRule(
        "TB_DATAMART",
        "PHYSICIAN_FIRST_NAME",
        "Expected: same as TB_HIV_DATAMART -- RDB value incorrect, RDB_MODERN "
        "correct (derived from Ordering Provider).",
        id="EXP-TB_DATAMART-PHYSICIAN_FIRST_NAME",
    ),
    ExpectedDiffRule(
        "TB_DATAMART",
        "REPORTING_SOURCE_NAME",
        "Expected: same as TB_HIV_DATAMART -- RDB value incorrect, RDB_MODERN "
        "correct (derived from Reporting Facility).",
        id="EXP-TB_DATAMART-REPORTING_SOURCE_NAME",
    ),
    # 18. LDF_DATAMART_COLUMN_REF.BUSINESS_OBJECT_NM null in RDB, populated modern.
    ExpectedDiffRule(
        "LDF_DATAMART_COLUMN_REF",
        "BUSINESS_OBJECT_NM",
        "Expected: BUSINESS_OBJECT_NM is NULL in RDB but populated (e.g. 'PHC') "
        "in RDB_Modern.",
        predicate=rdb_null_modern_set,
        id="EXP-LDF_DATAMART_COLUMN_REF-BUSINESS_OBJECT_NM",
    ),
    # 19. INV_SUMM_DATAMART notification columns null in RDB, populated in modern.
    ExpectedDiffRule(
        "INV_SUMM_DATAMART",
        "NOTIFICATION_LAST_UPDATED_DATE",
        "Expected: NULL in RDB, correctly populated in RDB_Modern.",
        predicate=rdb_null_modern_set,
        id="EXP-INV_SUMM_DATAMART-NOTIFICATION_LAST_UPDATED_DATE",
    ),
    ExpectedDiffRule(
        "INV_SUMM_DATAMART",
        "NOTIFICATION_LAST_UPDATED_USER",
        "Expected: NULL in RDB, correctly populated in RDB_Modern.",
        predicate=rdb_null_modern_set,
        id="EXP-INV_SUMM_DATAMART-NOTIFICATION_LAST_UPDATED_USER",
    ),
    ExpectedDiffRule(
        "INV_SUMM_DATAMART",
        "NOTIFICATION_LOCAL_ID",
        "Expected: NULL in RDB, correctly populated in RDB_Modern.",
        predicate=rdb_null_modern_set,
        id="EXP-INV_SUMM_DATAMART-NOTIFICATION_LOCAL_ID",
    ),
    ExpectedDiffRule(
        "INV_SUMM_DATAMART",
        "NOTIFICATION_STATUS",
        "Expected: NULL in RDB, correctly populated in RDB_Modern.",
        predicate=rdb_null_modern_set,
        id="EXP-INV_SUMM_DATAMART-NOTIFICATION_STATUS",
    ),
    ExpectedDiffRule(
        "INV_SUMM_DATAMART",
        "NOTIFICATION_SUBMITTER",
        "Expected: NULL in RDB, correctly populated in RDB_Modern.",
        predicate=rdb_null_modern_set,
        id="EXP-INV_SUMM_DATAMART-NOTIFICATION_SUBMITTER",
    ),
    # 20. D_PROVIDER.PROVIDER_PHONE_CELL: MasterETL keeps inactive phone, RTR fixed.
    ExpectedDiffRule(
        "D_PROVIDER",
        "PROVIDER_PHONE_CELL",
        "Expected: MasterETL does not filter out inactive phone records (keeps "
        "most-recent cell even if inactive); RTR was fixed (APP-595).",
        id="EXP-D_PROVIDER-PROVIDER_PHONE_CELL",
    ),
    # 21. D_ORGANIZATION audit columns: MasterETL not updating on typo edits.
    ExpectedDiffRule(
        "D_ORGANIZATION",
        "ORGANIZATION_LAST_CHANGE_TIME",
        "Expected: MasterETL does not update this on typographical org edits; "
        "RTR updates it accurately.",
        id="EXP-D_ORGANIZATION-ORGANIZATION_LAST_CHANGE_TIME",
    ),
    ExpectedDiffRule(
        "D_ORGANIZATION",
        "ORGANIZATION_LAST_UPDATED_BY",
        "Expected: MasterETL does not update this on typographical org edits; "
        "RTR updates it accurately.",
        id="EXP-D_ORGANIZATION-ORGANIZATION_LAST_UPDATED_BY",
    ),
    # Consultant-reported corrections (not yet independently verified).
    ExpectedDiffRule(
        "D_PLACE",
        "PLACE_ADDRESS_COMMENTS",
        "Expected (consultant-reported): RDB sometimes swaps PLACE_PHONE_COMMENTS "
        "into PLACE_ADDRESS_COMMENTS; RDB_MODERN reportedly does not have this "
        "bug. NB: superseded by the D_PLACE not-populated KNOWN_BUG.",
        id="EXP-D_PLACE-PLACE_ADDRESS_COMMENTS",
    ),
    ExpectedDiffRule(
        "D_PLACE",
        "PLACE_PHONE_COMMENTS",
        "Expected (consultant-reported): RDB sometimes swaps "
        "PLACE_ADDRESS_COMMENTS into PLACE_PHONE_COMMENTS; RDB_MODERN reportedly "
        "correct.",
        id="EXP-D_PLACE-PLACE_PHONE_COMMENTS",
    ),
    ExpectedDiffRule(
        "D_PROVIDER",
        "PROVIDER_ADDED_BY",
        "Expected (consultant-reported): in RDB, PROVIDER_ADDED_BY and "
        "PROVIDER_LAST_UPDATED_BY always match (incorrect); RDB_MODERN "
        "reportedly has the correct distinct values.",
        id="EXP-D_PROVIDER-PROVIDER_ADDED_BY",
    ),
    ExpectedDiffRule(
        "D_PROVIDER",
        "PROVIDER_LAST_UPDATED_BY",
        "Expected (consultant-reported): in RDB always equals PROVIDER_ADDED_BY "
        "(incorrect); RDB_MODERN reportedly correct.",
        id="EXP-D_PROVIDER-PROVIDER_LAST_UPDATED_BY",
    ),
    ExpectedDiffRule(
        "CONDITION",
        "CONDITION_DESC",
        "Expected (consultant-reported): for condition 11638, RDB has a "
        "mis-encoded CONDITION_DESC ('JunAn...'); RDB_MODERN has the correct "
        "UTF-8 'Junin hemorrhagic fever'.",
        id="EXP-CONDITION-CONDITION_DESC",
    ),
    ExpectedDiffRule(
        "HEP_MULTI_VALUE_FIELD",
        "*",
        "Expected (consultant-reported): RDB sometimes lacks expected values; "
        "RDB_MODERN reportedly has the correct values.",
        id="EXP-HEP_MULTI_VALUE_FIELD",
    ),
    ExpectedDiffRule(
        "MORBIDITY_REPORT_EVENT",
        "*",
        "Expected (consultant-reported): RDB sometimes carries the wrong "
        "treatment key for MORBIDITY_REPORT; RDB_MODERN reportedly correct.",
        id="EXP-MORBIDITY_REPORT_EVENT-treatment_key",
    ),
]


# =====================================================================
# Unexpected Differences (Probable Bugs)  -> KnownBugRule
# =====================================================================
# Each item maps to the numbered list on the page; tickets reference
# "RTR-diffs:bug-<n>" (plus real Jira IDs where the page gives them).
KNOWN_BUGS = [
    # 1. ORGANIZATION.ORGANIZATION_FACILITY_ID_AUTH not set.
    KnownBugRule(
        "ORGANIZATION",
        "ORGANIZATION_FACILITY_ID_AUTH",
        "RDB_MODERN..ORGANIZATION is not setting a value in "
        "ORGANIZATION_FACILITY_ID_AUTH.",
        ticket="RTR-diffs:bug-1",
        predicate=modern_null_rdb_set,
        id="BUG-ORGANIZATION-FACILITY_ID_AUTH",
    ),
    # 2. LAB_RPT_USER_COMMENT not including user comments (also item 26).
    KnownBugRule(
        "LAB_RPT_USER_COMMENT",
        "*",
        "RDB_MODERN..LAB_RPT_USER_COMMENT is not including user-added comments "
        "and is not populated; there should be data here. DataCompareAPI does "
        "not detect this.",
        ticket="RTR-diffs:bug-2,26",
        id="BUG-LAB_RPT_USER_COMMENT",
    ),
    # 3. LAB_TEST audit columns differ (APP-238) -- see also item 28.
    KnownBugRule(
        "LAB_TEST",
        "LAB_RPT_LAST_UPDATE_BY",
        "RDB_MODERN..LAB_TEST differs from RDB for LAB_RPT_LAST_UPDATE_BY; RTR "
        "extracts LAST_CHG_USER_ID from NRT_OBSERVATION rather than "
        "NEDSS_ENTRY_ID, yielding a different user id (APP-238).",
        ticket="RTR-diffs:bug-3,28 / APP-238",
        id="BUG-LAB_TEST-LAB_RPT_LAST_UPDATE_BY",
    ),
    # 28. LAB_TEST.SPECIMEN_SRC NULL in modern.
    KnownBugRule(
        "LAB_TEST",
        "SPECIMEN_SRC",
        "RDB_MODERN..LAB_TEST has SPECIMEN_SRC NULL where legacy RDB has a value "
        "(e.g. 'Sputum').",
        ticket="RTR-diffs:bug-28",
        predicate=modern_null_rdb_set,
        id="BUG-LAB_TEST-SPECIMEN_SRC",
    ),
    # 27. LAB_TEST_KEY offset significant (360+).
    KnownBugRule(
        "LAB_TEST",
        "LAB_TEST_KEY",
        "LAB_TEST_KEY has an expected offset, but the offsets discovered "
        "(360+) are significant -- likely due to a lack of ELR data captured "
        "in NBS7/RTR.",
        ticket="RTR-diffs:bug-27",
        id="BUG-LAB_TEST-LAB_TEST_KEY_OFFSET",
    ),
    # 8 / 33. D_CASE_MANAGEMENT.INIT_FUP_INITIAL_FOLL_UP: DEC in RDB, NULL in modern.
    KnownBugRule(
        "D_CASE_MANAGEMENT",
        "INIT_FUP_INITIAL_FOLL_UP",
        "Legacy RDB has 'DEC' for INIT_FUP_INITIAL_FOLL_UP while RDB_MODERN has "
        "NULL (same discrepancy also seen in STD_HIV_DATAMART).",
        ticket="RTR-diffs:bug-8,33",
        id="BUG-D_CASE_MANAGEMENT-INIT_FUP_INITIAL_FOLL_UP",
    ),
    # 8. D_CASE_MANAGEMENT.INIT_FUP_CLOSED_DT: full ISO datetime vs date-only.
    KnownBugRule(
        "D_CASE_MANAGEMENT",
        "INIT_FUP_CLOSED_DT",
        "Legacy RDB has the full ISO 8601 date/time while RDB_MODERN only has "
        "the formatted date (e.g. '2025-01-15 00:00:00' vs '2025-01-15').",
        ticket="RTR-diffs:bug-8",
        id="BUG-D_CASE_MANAGEMENT-INIT_FUP_CLOSED_DT",
    ),
    # 33. STD_HIV_DATAMART same INIT_FUP_INITIAL_FOLL_UP discrepancy.
    KnownBugRule(
        "STD_HIV_DATAMART",
        "INIT_FUP_INITIAL_FOLL_UP",
        "Same as D_CASE_MANAGEMENT: 'DEC' in legacy RDB, NULL in RDB_MODERN.",
        ticket="RTR-diffs:bug-33",
        id="BUG-STD_HIV_DATAMART-INIT_FUP_INITIAL_FOLL_UP",
    ),
    # 9. D_CONTACT_RECORD NULL-vs-empty note columns + CTT_EXPOSURE_TYPE.
    KnownBugRule(
        "D_CONTACT_RECORD",
        "CTT_EVAL_NOTES",
        "NULL on legacy RDB vs empty string on RDB_MODERN; populates correctly "
        "in both once note data is added via the UI (suspected RTR logic bug on "
        "contact-record creation).",
        ticket="RTR-diffs:bug-9",
        predicate=null_vs_empty,
        id="BUG-D_CONTACT_RECORD-CTT_EVAL_NOTES",
    ),
    KnownBugRule(
        "D_CONTACT_RECORD",
        "CTT_RISK_NOTES",
        "NULL on legacy RDB vs empty string on RDB_MODERN (see bug-9).",
        ticket="RTR-diffs:bug-9",
        predicate=null_vs_empty,
        id="BUG-D_CONTACT_RECORD-CTT_RISK_NOTES",
    ),
    KnownBugRule(
        "D_CONTACT_RECORD",
        "CTT_STMP_NOTES",
        "NULL on legacy RDB vs empty string on RDB_MODERN (see bug-9).",
        ticket="RTR-diffs:bug-9",
        predicate=null_vs_empty,
        id="BUG-D_CONTACT_RECORD-CTT_STMP_NOTES",
    ),
    KnownBugRule(
        "D_CONTACT_RECORD",
        "CTT_TRT_NOTES",
        "NULL on legacy RDB vs empty string on RDB_MODERN (see bug-9).",
        ticket="RTR-diffs:bug-9",
        predicate=null_vs_empty,
        id="BUG-D_CONTACT_RECORD-CTT_TRT_NOTES",
    ),
    KnownBugRule(
        "D_CONTACT_RECORD",
        "CTT_NOTES",
        "NULL on legacy RDB vs empty string on RDB_MODERN (see bug-9).",
        ticket="RTR-diffs:bug-9",
        predicate=null_vs_empty,
        id="BUG-D_CONTACT_RECORD-CTT_NOTES",
    ),
    KnownBugRule(
        "D_CONTACT_RECORD",
        "CTT_EXPOSURE_TYPE",
        "CTT_EXPOSURE_TYPE was 'Social/Recreational' in legacy RDB but NULL on "
        "RDB_MODERN (corrected once the note was added via the UI -- suspected "
        "RTR stored-procedure logic bug on contact-record creation).",
        ticket="RTR-diffs:bug-9",
        id="BUG-D_CONTACT_RECORD-CTT_EXPOSURE_TYPE",
    ),
    # 10. D_INV_SYMPTOM fever fields NULL in modern.
    KnownBugRule(
        "D_INV_SYMPTOM",
        "SYM_FEVER_HIGHEST_TEMP",
        "RDB_MODERN had NULL while legacy RDB populated SYM_FEVER_HIGHEST_TEMP "
        "(e.g. 102).",
        ticket="RTR-diffs:bug-10",
        predicate=modern_null_rdb_set,
        id="BUG-D_INV_SYMPTOM-SYM_FEVER_HIGHEST_TEMP",
    ),
    KnownBugRule(
        "D_INV_SYMPTOM",
        "SYM_FEVER_HIGHEST_TEMP_UNIT",
        "RDB_MODERN had NULL while legacy RDB populated SYM_FEVER_HIGHEST_TEMP_UNIT "
        "(e.g. 'Fahrenheit').",
        ticket="RTR-diffs:bug-10",
        predicate=modern_null_rdb_set,
        id="BUG-D_INV_SYMPTOM-SYM_FEVER_HIGHEST_TEMP_UNIT",
    ),
    # 11. D_INTERVIEW fields NULL in modern.
    KnownBugRule(
        "D_INTERVIEW",
        "IX_CONTACTS_NAMED_IND",
        "RDB_MODERN had NULL while legacy RDB populated it (e.g. 'Yes').",
        ticket="RTR-diffs:bug-11",
        predicate=modern_null_rdb_set,
        id="BUG-D_INTERVIEW-IX_CONTACTS_NAMED_IND",
    ),
    KnownBugRule(
        "D_INTERVIEW",
        "IX_INTERVENTION",
        "RDB_MODERN had NULL while legacy RDB populated it (e.g. 'HIV "
        "Intervention Value c').",
        ticket="RTR-diffs:bug-11",
        predicate=modern_null_rdb_set,
        id="BUG-D_INTERVIEW-IX_INTERVENTION",
    ),
    KnownBugRule(
        "D_INTERVIEW",
        "CLN_CARE_STATUS_IXS",
        "RDB_MODERN had NULL while legacy RDB populated it (e.g. '1-In Care').",
        ticket="RTR-diffs:bug-11",
        predicate=modern_null_rdb_set,
        id="BUG-D_INTERVIEW-CLN_CARE_STATUS_IXS",
    ),
    # 12. D_INTERVIEW_NOTE not appearing though D_INTERVIEW has data.
    KnownBugRule(
        "D_INTERVIEW_NOTE",
        "*",
        "D_INTERVIEW exists in RDB_MODERN but the corresponding D_INTERVIEW_NOTE "
        "rows are not appearing -- likely an RTR defect. DataCompareAPI does "
        "not detect this.",
        ticket="RTR-diffs:bug-12",
        id="BUG-D_INTERVIEW_NOTE-not_populated",
    ),
    # 13. D_ORGANIZATION.ORGANIZATION_FACILITY_AUTH NULL in modern.
    KnownBugRule(
        "D_ORGANIZATION",
        "ORGANIZATION_FACILITY_AUTH",
        "ORGANIZATION_FACILITY_AUTH was 'NPI' in legacy RDB but NULL on "
        "RDB_MODERN.",
        ticket="RTR-diffs:bug-13",
        predicate=modern_null_rdb_set,
        id="BUG-D_ORGANIZATION-ORGANIZATION_FACILITY_AUTH",
    ),
    # 14. D_PLACE not populated in modern.
    KnownBugRule(
        "D_PLACE",
        "*",
        "D_PLACE is not populated in RDB_MODERN though it should be. "
        "DataCompareAPI does not detect this.",
        ticket="RTR-diffs:bug-14",
        id="BUG-D_PLACE-not_populated",
    ),
    # 15. DM_INV_ARBO_HUMAN.EVENT_DATE_TYPE NULL in RDB vs populated in modern.
    KnownBugRule(
        "DM_INV_ARBO_HUMAN",
        "EVENT_DATE_TYPE",
        "A case where EVENT_DATE_TYPE was NULL in legacy RDB but 'Investigation "
        "Start Date' in RDB_MODERN.",
        ticket="RTR-diffs:bug-15",
        predicate=rdb_null_modern_set,
        id="BUG-DM_INV_ARBO_HUMAN-EVENT_DATE_TYPE",
    ),
    # 16. DM_INV_GENERIC_V2 not populated in modern.
    KnownBugRule(
        "DM_INV_GENERIC_V2",
        "*",
        "DM_INV_GENERIC_V2 is not populated in RDB_MODERN though it should be. "
        "DataCompareAPI does not detect this.",
        ticket="RTR-diffs:bug-16",
        id="BUG-DM_INV_GENERIC_V2-not_populated",
    ),
    # 17. DM_INV_HIV.EVENT_DATE_TYPE NULL in RDB vs populated in modern.
    KnownBugRule(
        "DM_INV_HIV",
        "EVENT_DATE_TYPE",
        "A case where EVENT_DATE_TYPE was NULL in legacy RDB but 'Investigation "
        "Start Date' in RDB_MODERN.",
        ticket="RTR-diffs:bug-17",
        predicate=rdb_null_modern_set,
        id="BUG-DM_INV_HIV-EVENT_DATE_TYPE",
    ),
    # 18. D_INV_SUMM_DATAMART.INVESTIGATION_LAST_UPDTD_DATE incorrect in RDB.
    KnownBugRule(
        "D_INV_SUMM_DATAMART",
        "INVESTIGATION_LAST_UPDTD_DATE",
        "RDB has an incorrect INVESTIGATION_LAST_UPDTD_DATE (e.g. 2026-01-08 "
        "21:23:58.027); RDB_MODERN has the correct value.",
        ticket="RTR-diffs:bug-18",
        id="BUG-D_INV_SUMM_DATAMART-INVESTIGATION_LAST_UPDTD_DATE",
    ),
    # 19. INVESTIGATION hospitalization fields NULL in modern.
    KnownBugRule(
        "INVESTIGATION",
        "HSPTL_ADMISSION_DT",
        "RDB_MODERN had NULL while legacy RDB populated HSPTL_ADMISSION_DT "
        "(e.g. 2025-12-08).",
        ticket="RTR-diffs:bug-19",
        predicate=modern_null_rdb_set,
        id="BUG-INVESTIGATION-HSPTL_ADMISSION_DT",
    ),
    KnownBugRule(
        "INVESTIGATION",
        "HSPTL_DISCHARGE_DT",
        "RDB_MODERN had NULL while legacy RDB populated HSPTL_DISCHARGE_DT "
        "(e.g. 2025-12-09).",
        ticket="RTR-diffs:bug-19",
        predicate=modern_null_rdb_set,
        id="BUG-INVESTIGATION-HSPTL_DISCHARGE_DT",
    ),
    KnownBugRule(
        "INVESTIGATION",
        "HSPTL_DURATION_DAYS",
        "RDB_MODERN had NULL while legacy RDB populated HSPTL_DURATION_DAYS "
        "(e.g. 1).",
        ticket="RTR-diffs:bug-19",
        predicate=modern_null_rdb_set,
        id="BUG-INVESTIGATION-HSPTL_DURATION_DAYS",
    ),
    # 20. L_CASE_MANAGEMENT populated in RDB, does not exist in modern.
    KnownBugRule(
        "L_CASE_MANAGEMENT",
        "*",
        "L_CASE_MANAGEMENT is populated in legacy RDB but does not exist in "
        "RDB_MODERN.",
        ticket="RTR-diffs:bug-20",
        id="BUG-L_CASE_MANAGEMENT-missing",
    ),
    # 21. L_CONTACT_RECORD not populated in modern.
    KnownBugRule(
        "L_CONTACT_RECORD",
        "*",
        "L_CONTACT_RECORD is populated in legacy RDB but not in RDB_MODERN; "
        "there should be data here.",
        ticket="RTR-diffs:bug-21",
        id="BUG-L_CONTACT_RECORD-not_populated",
    ),
    # 22. L_INTERVIEW not populated in modern.
    KnownBugRule(
        "L_INTERVIEW",
        "*",
        "L_INTERVIEW is populated in legacy RDB but not in RDB_MODERN; there "
        "should be data here.",
        ticket="RTR-diffs:bug-22",
        id="BUG-L_INTERVIEW-not_populated",
    ),
    # 23. L_INTERVIEW_NOTE not populated in modern.
    KnownBugRule(
        "L_INTERVIEW_NOTE",
        "*",
        "L_INTERVIEW_NOTE is populated in legacy RDB but not in RDB_MODERN; "
        "there should be data here.",
        ticket="RTR-diffs:bug-23",
        id="BUG-L_INTERVIEW_NOTE-not_populated",
    ),
    # 24. LAB_RESULT_COMMENT populated in modern, not in RDB.
    KnownBugRule(
        "LAB_RESULT_COMMENT",
        "*",
        "LAB_RESULT_COMMENT is populated in RDB_MODERN but not in legacy RDB.",
        ticket="RTR-diffs:bug-24",
        id="BUG-LAB_RESULT_COMMENT-modern_only",
    ),
    # 25. LAB_RESULT_VAL value-code fields NULL in modern.
    KnownBugRule(
        "LAB_RESULT_VAL",
        "TEST_RESULT_VAL_CD",
        "RDB_MODERN had NULL while legacy RDB populated TEST_RESULT_VAL_CD "
        "(e.g. 260415000). DataCompareAPI does not detect this.",
        ticket="RTR-diffs:bug-25",
        predicate=modern_null_rdb_set,
        id="BUG-LAB_RESULT_VAL-TEST_RESULT_VAL_CD",
    ),
    KnownBugRule(
        "LAB_RESULT_VAL",
        "TEST_RESULT_VAL_CD_DESC",
        "RDB_MODERN had NULL while legacy RDB populated TEST_RESULT_VAL_CD_DESC "
        "(e.g. 'Not Detected').",
        ticket="RTR-diffs:bug-25",
        predicate=modern_null_rdb_set,
        id="BUG-LAB_RESULT_VAL-TEST_RESULT_VAL_CD_DESC",
    ),
    KnownBugRule(
        "LAB_RESULT_VAL",
        "TEST_RESULT_VAL_CD_SYS_CD",
        "RDB_MODERN had NULL while legacy RDB populated TEST_RESULT_VAL_CD_SYS_CD "
        "(e.g. 'SCT').",
        ticket="RTR-diffs:bug-25",
        predicate=modern_null_rdb_set,
        id="BUG-LAB_RESULT_VAL-TEST_RESULT_VAL_CD_SYS_CD",
    ),
    # 30. LDF_DATAMART_COLUMN_REF unfinished-work marker rows.
    KnownBugRule(
        "LDF_DATAMART_COLUMN_REF",
        "DATAMART_COLUMN_NM",
        "Apparent unfinished work: rows where DATAMART_COLUMN_NM is "
        "'L_10000007LDF_to_Fix_RDB' on both databases -- needs investigation.",
        ticket="RTR-diffs:bug-30",
        id="BUG-LDF_DATAMART_COLUMN_REF-DATAMART_COLUMN_NM",
    ),
    # 32. PHC_UIDS.CASE_MANAGEMENT_UID NULL in modern.
    # RETIRED (APP-720): PHC_UIDS is now skip-listed (SKIP-PHC_PREFIX) as a
    # transient SELECT INTO UID worklist, so this column-level known-bug rule can
    # never fire (skip rules outrank known-bug in sort order). The underlying
    # CASE_MANAGEMENT_UID NULL + non-STD/STD record-set observation (ticket
    # RTR-diffs:bug-32) is preserved here for traceability; re-open it against a
    # real comparand if PHC case-management linkage needs verification.
    # 34. TREATMENT.TREATMENT_COMMENTS NULL vs empty.
    KnownBugRule(
        "TREATMENT",
        "TREATMENT_COMMENTS",
        "TREATMENT_COMMENTS is NULL on legacy RDB but empty string on "
        "RDB_MODERN (representation-only difference).",
        ticket="RTR-diffs:bug-34",
        predicate=null_vs_empty,
        id="BUG-TREATMENT-TREATMENT_COMMENTS",
    ),
    # 37. INV_SUMM_DATAMART.NOTIFICATION_CREATE_DATE NULL in modern.
    KnownBugRule(
        "INV_SUMM_DATAMART",
        "NOTIFICATION_CREATE_DATE",
        "NOTIFICATION_CREATE_DATE has the correct value in RDB but is NULL in "
        "RDB_Modern.",
        ticket="RTR-diffs:bug-37",
        predicate=modern_null_rdb_set,
        id="BUG-INV_SUMM_DATAMART-NOTIFICATION_CREATE_DATE",
    ),
]


def build_default_registry() -> RuleRegistry:
    """Build and return the fully populated default :class:`RuleRegistry`.

    Assembles every rule transcribed from the "RTR reporting differences" page:
    the skip-list tables/families, the surrogate-key and environment-timestamp
    ignore rules, the documented expected differences, and the probable-bug
    rules. The registry orders them by ``sort_key`` (skip < known-bug < expected
    < ignore; exact before glob), so the first matching rule wins.
    """
    registry = RuleRegistry()
    registry.extend(SKIP_TABLES)
    registry.extend(IGNORE_COLUMNS)
    registry.extend(EXPECTED)
    registry.extend(KNOWN_BUGS)
    return registry
