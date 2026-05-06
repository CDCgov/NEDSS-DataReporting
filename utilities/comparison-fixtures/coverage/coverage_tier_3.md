# Coverage: Tier 3 (gap-driven SP coverage)

Generated: 2026-05-06

## Inputs

- Source: `coverage/coverage_merged.md` "Partially covered (16)" list
  produced after the first end-to-end `scripts/merge_and_verify.sh` run.
- Goal per STRATEGY.md: "small, targeted ODSE rows or variants to hit
  the missing branches. They never modify foundation or existing
  subjects."

## Triage of partial-coverage tables

The 16 partially-covered tables from the merged-state report were
triaged to identify which warrant Tier 3 fixture work:

| Table | Cols | Rows | NULL cols | Tier 3 worthy? | Reason |
| --- | --- | --- | --- | --- | --- |
| condition | 15 | 2 | 1 | No | Only Hep A seeded by design; multi-condition is Phase 2 |
| d_contact_record | 66 | 3 | 24 | No | All NULL = LDF dynamic + 1 phantom (TREATMNT_END_DESCRIPTION); documented OUT_OF_SCOPE in coverage_contact.md |
| d_interview | 24 | 2 | 6 | No | LDF dynamic columns; Phase 2 LDF expansion |
| d_inv_place_repeat | 42 | 1 | 41 | No | Repeating-block dim; requires sp_repeated_place_postprocessing (Tier 2/3 explicitly out of scope per Place Tier 1 prompt) |
| d_investigation_repeat | 244 | 2 | most | No | Mostly dynamic-SQL columns; Tier 3 datamart territory (Phase 2) |
| d_ldf_meta_data | 14 | 2620 | some | No | LDF infrastructure; Phase 2 LDF |
| event_metric_inc | 28 | 1 | most | No | Logging table; out of scope per Phase 0 |
| inv_hiv | 19 | 1 | most | No | HIV-specific; Phase 2 multi-condition |
| job_flow_log | 15 | 21921 | some | No | Logging table; out of scope per Phase 0 |
| l_inv_place_repeat | 2 | 1 | 1 | No | Link table for repeated-place |
| l_investigation_repeat | 2 | 1 | 1 | No | Link table for investigation-repeat |
| **lab_test_result** | 20 | 3 | 1 | **No (resolved)** | Only `LAB_RESULT_VAL_LARGE_TXT_KEY` NULL — coverage_lab.md already documents this as OUT_OF_SCOPE (live DDL has col but no SP writes it) |
| ldf_datamart_column_ref | 8 | 2662 | some | No | LDF infrastructure |
| **rdb_date** | 11 | 4019 | 9 | **YES — fixed in orchestrator** | The recursive-CTE seed only set DATE_KEY + DATE_MM_DD_YYYY. The other 9 columns (DAY_OF_WEEK, CLNDR_*, etc.) are deterministically computable from the date. Trivially fixable. |
| summary_case_group | 2 | 1 | 1 | No | Sentinel row only |
| test_result_grouping | 3 | 2 | 1 | No | RDB_LAST_REFRESH_TIME is explicitly NULLed by the SP (sp_d_lab_test_postprocessing line 1297) |

## Tier 3 fixture work performed

Only one of the 16 partially-covered tables warranted Tier 3 work:

### RDB_DATE calendar enrichment

**Problem**: the recursive-CTE seed in `merge_and_verify.sh` step 2
populated only `DATE_KEY` and `DATE_MM_DD_YYYY` for the 4018 dates in
2020-2030. The other 9 columns
(`DAY_OF_WEEK`, `DAY_NBR_IN_CLNDR_MON`, `DAY_NBR_IN_CLNDR_YR`,
`WK_NBR_IN_CLNDR_MON`, `WK_NBR_IN_CLNDR_YR`, `CLNDR_MON_NAME`,
`CLNDR_MON_IN_YR`, `CLNDR_QRTR`, `CLNDR_YR`) were NULL.

**Fix**: extended the recursive CTE in
`scripts/merge_and_verify.sh:run_infrastructure_sps()` to compute all
11 columns from the date itself using `DATEPART` / `DATENAME`:

- `DAY_OF_WEEK` = `DATEPART(weekday, dt)`
- `DAY_NBR_IN_CLNDR_MON` = `DATEPART(day, dt)`
- `DAY_NBR_IN_CLNDR_YR` = `DATEPART(dayofyear, dt)`
- `WK_NBR_IN_CLNDR_MON` = `((DATEPART(day, dt) - 1) / 7) + 1`
- `WK_NBR_IN_CLNDR_YR` = `DATEPART(week, dt)`
- `CLNDR_MON_NAME` = `DATENAME(month, dt)`
- `CLNDR_MON_IN_YR` = `DATEPART(month, dt)`
- `CLNDR_QRTR` = `DATEPART(quarter, dt)`
- `CLNDR_YR` = `DATEPART(year, dt)`

The DATE_KEY=1 sentinel row remains all-NULL except for `DATE_KEY`
itself — that's correct (it represents an unknown date).

**Result**: rdb_date moves from "Partially covered (2/11)" to
"Fully covered (11/11)" in coverage_merged.md. Verified by re-running
the orchestrator + coverage_summary.sh.

## Tables NOT addressed by Tier 3 (and why)

The remaining 15 partially-covered tables are deferred:

- **9 are LDF / dynamic-pivot territory**: d_contact_record (24 LDF
  cols), d_interview (6 LDF cols), d_inv_place_repeat,
  d_investigation_repeat, d_ldf_meta_data, ldf_datamart_column_ref.
  Phase 2 LDF expansion will populate `nrt_metadata_columns` and
  re-run the affected SPs.
- **3 are condition-specific**: condition (only Hep A seeded), inv_hiv
  (HIV-specific), summary_case_group. Phase 2 multi-condition fan-out.
- **2 are logging tables out of Phase 0 scope**: job_flow_log,
  event_metric_inc.
- **1 already documented OUT_OF_SCOPE in Tier 1 coverage**:
  lab_test_result (LAB_RESULT_VAL_LARGE_TXT_KEY phantom),
  test_result_grouping (RDB_LAST_REFRESH_TIME explicit-NULL by SP).

## ODSE-unknown tables (note from teammate, 2026-05)

A teammate identified ~80 RDB tables that no one on the team currently
knows how to populate via ODSE inputs. See STRATEGY.md "Follow-on /
phase-2" section for the full TODO. These tables aren't Tier 3 fixture
candidates — they're either MasterETL-only writes (legitimate diff
findings against RTR), or datamart-SP-driven (Merge step 9, deferred),
or genuinely uninvestigated. Documented for follow-up; not addressed
in v1.
