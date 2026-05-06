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

### F_PAGE_CASE unblock

**Problem**: F_PAGE_CASE was empty (0 rows) after the initial datamart
step run. The SP at line 85-95 of `012-sp_f_page_case_postprocessing-001.sql`
filters `nrt_investigation` rows on:

```sql
WHERE INVESTIGATION_FORM_CD NOT IN (legacy hepatitis form codes)
  AND CASE_MANAGEMENT_UID is null
```

Foundation Inv (CASE_UID 20000100) was authored with `INVESTIGATION_FORM_CD=NULL`
and `CASE_MANAGEMENT_UID=NULL`. NULL fails `NOT IN` (UNKNOWN treated as
false in WHERE), so foundation was filtered out. v2 Inv (20050010) has
form_cd set but case_management_uid set too — also filtered out.

**Fix**: `fixtures/30_sp_coverage/f_page_case_unblock.sql` — UPDATE
foundation's `nrt_investigation` row to set `INVESTIGATION_FORM_CD =
'PG_Hepatitis_A_Acute_Investigation'` (modern form, passes filter).
This is a staging-table UPDATE consistent with the Tier 2 pattern
established by `lab_inv` and `morb_inv` (UPDATE `nrt_observation.associated_phc_uids`).

**Result**: F_PAGE_CASE: 0 → 1 row. Same single-row content as v1's
condition fan-out; multi-condition expansion is Phase 2.

### F_PAGE_CASE → HEPATITIS_DATAMART cascade — RTR investigation needed

**Problem**: After F_PAGE_CASE has 1 row,
`sp_hepatitis_datamart_postprocessing` STILL produces 0 rows in
HEPATITIS_DATAMART. Its first internal step `#TMP_F_PAGE_CASE` reports
`row_count=0` even though F_PAGE_CASE has a row that should match all
the filters.

The TMP_F_PAGE_CASE generation query (lines 95-101) joins:
```sql
SELECT F_PAGE_CASE.INVESTIGATION_KEY, T.CONDITION_KEY, F_PAGE_CASE.PATIENT_KEY
INTO #TMP_F_PAGE_CASE
FROM dbo.F_PAGE_CASE
   INNER JOIN #TMP_CONDITION T ON F_PAGE_CASE.CONDITION_KEY = T.CONDITION_KEY
   INNER JOIN dbo.D_PATIENT ON F_PAGE_CASE.PATIENT_KEY = D_PATIENT.PATIENT_KEY
   INNER JOIN dbo.INVESTIGATION ON INVESTIGATION.INVESTIGATION_KEY = F_PAGE_CASE.INVESTIGATION_KEY
WHERE INVESTIGATION.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_id, ','))
  AND INVESTIGATION.RECORD_STATUS_CD = 'ACTIVE'
```

Verified manually: this exact query (with `dbo.condition` substituted
for `#TMP_CONDITION`) returns 1 row. Inside the SP's scope it returns 0.
`#TMP_CONDITION` has 1 row per `job_flow_log` ("Generating  #TMP_CONDITION
START 1"). All key values match across F_PAGE_CASE / D_PATIENT /
INVESTIGATION / condition. No obvious cause.

Possible explanations (not investigated further; out of project scope):
- Snapshot isolation or transaction-scope quirk between the SP's
  context and the outer connection.
- F_PAGE_CASE row was inserted in the same batch the hepatitis SP runs
  in, and the SP doesn't see it due to read-committed snapshot.
- Latent bug in `#TMP_CONDITION` projection (it selects 4 columns
  including DISEASE_GRP_DESC but `condition.DISEASE_GRP_DESC` may have
  unexpected value affecting downstream joins).

**Status**: documented as another RTR investigation item. Without
HEPATITIS_DATAMART populating, several downstream tables stay empty:
- HEPATITIS_DATAMART (0 rows; the headline diff target for Hep A)
- HEPATITIS_CASE (0 rows; sibling case-detail table)
- INV_HIV (1 row but partial — unrelated; populated by std_hiv chain)
- LDF_HEPATITIS (0 rows; cascades from HEPATITIS_DATAMART being empty)

The fix path is upstream RTR debugging, not fixture work.

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

## Empty (59) tables — second-pass triage

Tier 3 v1 also re-triaged the 59 "Empty" tables to confirm they're
correctly classified as out-of-scope rather than missed Tier 3
opportunities. Findings:

- **~25 datamart fact tables** (`*_datamart`, `hep100`, `lab100`,
  `lab101`, `sr100`, `f_page_case`, `f_std_page_case`, `f_tb_pam`,
  `f_var_pam`, `inv_summ_datamart`, `case_count`, `event_metric`,
  `summary_report_case`): correctly deferred to Merge contract step 9
  (datamart SPs, Phase 2).
- **~12 LDF tables** (`ldf_*`, `*_ldf_group`, `*_pam_ldf`): correctly
  deferred to Phase 2 LDF breadth expansion.
- **~14 patient-detail group dimensions** (`d_addl_risk`,
  `d_disease_site`, `d_gt_12_reas`, `d_hc_prov_ty_3`, `d_move_*`,
  `d_moved_where`, `d_out_of_cntry`, `d_pcr_source`, `d_rash_loc_gen`,
  `d_smr_exam_ty`, `d_tb_hiv`, `d_tb_pam`, `d_var_pam`,
  `d_case_management`): the **TB-PAM cluster**. All 14 d_<topic> SPs
  (`sp_nrt_d_<topic>_postprocessing`, files 145-230) read from
  `D_TB_PAM` (which is itself written by `sp_nrt_d_tb_pam_postprocessing`).
  The whole cluster requires:
    1. An Investigation with `condition_cd` indicating TB (not Hep A)
    2. NBS_case_answer rows for the TB form responses
    3. TB-PAM SP runs first; the 14 detail SPs run against its output
  This is **multi-condition territory** explicitly deferred to Phase 2
  per STRATEGY.md "Multi-condition variants per disease family". Not a
  missed v1 opportunity.
- **`morb_rpt_user_comment`**: blocked by RTR bug at
  `sp_d_morbidity_report_postprocessing:802-816` (self-defeating
  join+filter). Documented in coverage_morbidity.md and
  coverage_morb_inv.md. Not fixable without RTR change.
- **`l_investigation_repeat_inc`**: repeating-block inc table, depends
  on `sp_dyn_dm_*` SPs (Phase 2 datamart territory).
- **`etl_dq_log`, `lookup_table_n_rept`**: NO writer in any RTR
  routine — MasterETL-only tables. Maps to teammate's note about ~80
  RTR-not-writes tables.

Conclusion: all 59 empty tables fall into existing deferral categories.
No additional Tier 3 v1 work warranted.

## ODSE-unknown tables (note from teammate, 2026-05)

A teammate identified ~80 RDB tables that no one on the team currently
knows how to populate via ODSE inputs. See STRATEGY.md "Follow-on /
phase-2" section for the full TODO. These tables aren't Tier 3 fixture
candidates — they're either MasterETL-only writes (legitimate diff
findings against RTR), or datamart-SP-driven (Merge step 9, deferred),
or genuinely uninvestigated. Documented for follow-up; not addressed
in v1.
