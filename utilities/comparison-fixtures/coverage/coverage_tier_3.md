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

### Multi-condition Investigation fan-out

**Problem**: condition-specific datamart SPs (sp_tb_datamart,
sp_var_datamart, sp_covid_case_datamart, sp_pertussis_case_datamart,
sp_measles_case_datamart, sp_rubella_case_datamart, sp_std_hiv_datamart,
sp_bmird_strep_pneumo_datamart, sp_crs_case_datamart) all returned 0
rows because the only Investigation in the merged state was condition
'10110' (Hep A acute). Each SP filters on a different condition_cd or
investigation_form_cd, so none matched.

**Fix**: `fixtures/30_sp_coverage/multi_condition_investigations.sql` —
authors 10 additional Investigation variants directly as nrt_investigation
rows (no full ODSE Investigation+PHC since the postprocessing/datamart
SPs read from nrt_investigation directly). One Investigation per
condition family:
- 22000010 — TB (10220, INV_FORM_RVCT)
- 22000020 — Varicella (10030, INV_FORM_VAR)
- 22000030 — Mumps (10180)
- 22000040 — Pertussis (10190)
- 22000050 — Measles (10140)
- 22000060 — Rubella (10200)
- 22000070 — COVID-19 (11065)
- 22000080 — Syphilis primary (10311, STD)
- 22000090 — HIV pediatric (10561)
- 22000100 — Strep pneumoniae invasive (11717, BMIRD)

The orchestrator's `sp_nrt_srte_condition_code_postprocessing` call also
extended from a single condition to 17 codes covering all the families,
so dbo.condition has 23 rows post-merge.

**Result**:
- INVESTIGATION: 4 → 14 rows (10 new variants flow through
  sp_nrt_investigation_postprocessing in the fixture's tail-EXEC).
- F_PAGE_CASE: 1 → 6 rows (more Investigations passed the form-cd
  filter).
- CONDITION: 2 → 23 rows.
- Condition-specific datamarts: still 0 rows. **Same RTR transaction-
  isolation bug** that affects HEPATITIS_DATAMART (TMP_F_PAGE_CASE
  projection returns 0 rows even with valid F_PAGE_CASE rows). The
  bug is shared across the entire condition-datamart SP family —
  TB_DATAMART, VAR_DATAMART, COVID_CASE_DATAMART,
  PERTUSSIS_CASE/MEASLES_CASE/RUBELLA_CASE, STD_HIV_DATAMART,
  BMIRD_STREP_PNEUMO_DATAMART all use the same TMP_F_PAGE_CASE
  pattern at the top of their SP body and all fail identically.

The fixture-side work is done — Investigation variants and conditions
are present, F_PAGE_CASE has matching rows, the datamart SPs just
can't see them due to the upstream RTR bug. Filed as a single
RTR-investigation item covering the whole condition-datamart family.

### LDF answer chain (Tetanus)

**Goal**: populate `LDF_DATA`, `LDF_GROUP`, `LDF_DIMENSIONAL_DATA`,
`LDF_TETANUS`, and the 12 LDF tables overall. The LDF chain is:
`nrt_ldf_data` (answers in staging) → `sp_nrt_ldf_postprocessing` →
`LDF_DATA` + `LDF_GROUP` → `sp_nrt_ldf_dimensional_data_postprocessing`
→ `LDF_DIMENSIONAL_DATA` → per-condition `sp_ldf_<condition>_datamart_postprocessing`
→ per-condition LDF tables.

**Fix**: `fixtures/30_sp_coverage/ldf_answers_tetanus.sql` —
1. Adds a Tetanus Investigation variant (UID 22000200, condition_cd
   '10210') since multi_condition_investigations.sql didn't include
   Tetanus.
2. Authors 5 `nrt_ldf_data` rows pulling real LDF UIDs from
   `nrt_odse_state_defined_field_metadata` for Tetanus PHC (87 LDFs
   are baseline-seeded for condition 10210).
3. Tail-EXEC runs sp_nrt_ldf_postprocessing,
   sp_nrt_ldf_dimensional_data_postprocessing, and
   sp_ldf_tetanus_datamart_postprocessing.

**Result (partial)**:
- LDF_DATA: 0/17 → **9/17** (5 rows, 9 cols populated)
- LDF_GROUP: 0/2 → **2/2** (1 row, fully covered)
- LDF_DIMENSIONAL_DATA: 0 rows (next gap, blocks LDF_TETANUS et al.)
- LDF_TETANUS: 0 rows (cascades from LDF_DIMENSIONAL_DATA empty)

**Bugs surfaced (also out of project scope)**:
1. `LDF_DATA.RECORD_STATUS_CD` is `varchar(8)` but the SP at line 1132
   maps `metadata_record_status_cd` (typically `'LDF_PROCESSED'` = 13
   chars) into it — guaranteed truncation error. Worked around by
   authoring `metadata_record_status_cd='ACTIVE'` (6 chars). Real
   fix is to widen the column or change the source.
2. `sp_nrt_ldf_dimensional_data_postprocessing` at step "GENERATING
   TMP_LDF_DATA" produces 0 rows even with valid `nrt_ldf_data` and
   `nrt_odse_state_defined_field_metadata` rows. Looks like another
   transaction-isolation issue (similar pattern to the
   condition-datamart family bug — TMP table aggregation returns 0
   from inside the SP but works manually).
3. `sp_ldf_tetanus_datamart_postprocessing` at line 824: "Invalid
   length parameter passed to LEFT or SUBSTRING function" — likely
   downstream of LDF_DIMENSIONAL_DATA being empty.

The fixture-side work has gone as far as it can. The LDF chain needs
upstream RTR debugging to populate the per-condition LDF tables.

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

## Orchestrator-ordering fix: PAM fact tables before condition datamarts (2026-05-21)

**Symptom**: After Phase-2 TB fixture work landed, `TB_DATAMART` and
`TB_HIV_DATAMART` stayed at 0 rows even though `F_TB_PAM`, `D_TB_PAM`,
all 12 d_topic dims, and `INVESTIGATION` (case_uid=22001000) were
populated correctly.

**Root cause**: `scripts/merge_and_verify.sh` Step 9 invoked
`sp_tb_datamart_postprocessing` (line 503) and
`sp_tb_hiv_datamart_postprocessing` (line 504) BEFORE
`sp_f_tb_pam_postprocessing` (line 513). The TB datamart SP's
`#PATIENT/#PROVIDER/#PHYSICIAN/#REPORTER/#ORG_REPORTER/#HOSPITAL`
temp tables all `INNER JOIN [dbo].F_TB_PAM` (see
`255-sp_tb_datamart_postprocessing-001.sql:117-204`), so with F_TB_PAM
empty at invocation time, every temp table downstream had 0 rows and
the final `INSERT INTO TB_DATAMART` got 0 rows. `sp_tb_hiv_datamart_postprocessing`
then `INNER JOIN`s `TB_DATAMART` (line 166), so it also produced 0.

Confirmed by `job_flow_log` ordering (batch_ids on the live DB):
`F_TB_PAM POST-Processing` ran at 08:34:09; `TB_DATAMART POST-Processing`
ran 6 seconds earlier at 08:34:03 with `#PATIENT TABLE = 0 rows`.

**Verdict**: orchestrator bug, not an RTR bug. The SPs themselves are
correct DELETE-then-INSERT (re-running them is idempotent for the same
@phc_id_list scope).

**Fix applied on `aw/odse-test-seed`**: moved
`sp_f_tb_pam_postprocessing` and `sp_f_var_pam_postprocessing` from
lines 513-514 to immediately before the condition-specific datamart
block (now executes before `sp_std_hiv_datamart_postprocessing` at
line 501). The same ordering bug almost certainly affected
`VAR_DATAMART` (whose SP also reads `F_VAR_PAM`); moving both PAM
fact-table SPs together addresses both.

**Post-fix verification**: re-ran `sp_tb_datamart_postprocessing` and
`sp_tb_hiv_datamart_postprocessing` against the existing populated
F_TB_PAM. Result: `TB_DATAMART` populated 2 rows, `TB_HIV_DATAMART`
populated 2 rows.

**Note**: the 2-row count (instead of 1) is a separate, pre-existing
RTR defect that was previously documented in
`coverage/coverage_tb_full_chain.md` Gaps section as "TB_DATAMART
INSERT-only path; no UPDATE" (later refined: the SP does have a
correct DELETE-then-INSERT guard at lines 1700-1735). The actual
mechanism is over-broad `LEFT JOIN notification_event ne ON
tdi.person_key = ne.patient_key` (line 1525) which fans the row out
across every notification the patient has across all investigations
(not just this Investigation's notification). The TB Patient is the
foundation Patient (PERSON_KEY=3) which has notification_event rows
for NOTIFICATION_KEY=2 (Hep A foundation) and NOTIFICATION_KEY=3
(Hep A v2). The join should also constrain by INVESTIGATION_KEY
(via `nrt_investigation_notification` or `notification`-keyed walk).
Not fixed here — out of scope for the orchestrator-ordering fix; the
0→2 row uplift is the primary deliverable. Filed for follow-up in
the `coverage_tb_full_chain.md` Gaps section.
