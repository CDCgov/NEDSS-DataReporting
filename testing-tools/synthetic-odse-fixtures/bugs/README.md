# RTR bugs surfaced by the comparison-fixtures project

This directory contains 14 bug investigations produced by the
comparison-fixtures project's end-to-end merged-fixture run, numbered
`#1`–`#13` and `#15` (there is no `#14` directory; see "Total scope").
Each subdirectory has:

- `repro.sql`: self-contained SQL script demonstrating the bug (where
  applicable; some bugs are documented from in-orchestrator triggers)
- `findings.md`: investigation report with hypotheses tested,
  root cause (where determined), and suggested fix

All bugs were observed in baseline `ghcr.io/cdcent/nedssdb:latest`
with `DATABASE_VERSION=6.0.18.1`.

## Index

| # | Bug | Severity | Files affected |
| --- | --- | --- | --- |
| [01](./01_sp_get_date_dim/) | `sp_get_date_dim` references nonexistent `dbo.rdb_date_temp`; also has an inverted-IF logic bug | **Resolved, non-issue.** RDB_DATE is correctly populated by seeds in normal environments; SP is not on the live path. Separate seed-correction PR in-flight. | `014-sp_get_date_dim-001.sql` |
| [02](./02_sp_contact_record_event/) | `sp_contact_record_event` references `nbs_odse.dbo.fn_get_value_by_cd_codeset` (function lives in `RDB_MODERN.dbo`) | **Already fixed on main** via PR #769 (commit `a0dbf3be`). | `069-sp_contact_record_event-001.sql:69` |
| [03](./03_morb_rpt_user_comment/) | `sp_d_morbidity_report_postprocessing` self-defeating join+filter at lines 802-816 | **PR #837 open** on branch `aw/app-471/bug-3`. | `016-sp_nrt_morbidity_report_postprocessing-001.sql:802-816` |
| [04](./04_provider_postprocessing_typo/) | `sp_nrt_provider_postprocessing` line 564 typo: `#PATIENT_UPDATE_LIST` should be `#PROVIDER_UPDATE_LIST` | **Merged on main** (PR #826, commit `92a56d42`). | `003-sp_nrt_provider_postprocessing-001.sql:564` |
| [05](./05_tmp_f_page_case_family/) | **TWO bugs**: (5a) `sp_hepatitis_datamart_postprocessing` logs incorrect row_count for #TMP_F_PAGE_CASE due to `IF @debug` resetting `@@ROWCOUNT` (logging-only); (5b) `nrt_investigation.patient_id NULL` cascades through PATIENT sentinel into a `DELETE WHERE PATIENT_UID IS NULL` (fixture-side; actual blocker for HEPATITIS_DATAMART) | 5b **resolved** on `aw/odse-test-seed` (fixture-side; no PR; orchestrator plus Tier 3 variants now set `patient_id`). 5a still open. | `013-sp_hepatitis_datamart_postprocessing-001.sql:108-111, 2149` + fixture `nrt_investigation` |
| [06](./06_ldf_data_truncation/) | `sp_nrt_ldf_postprocessing` maps `metadata_record_status_cd` ('LDF_PROCESSED', 13 chars) into `LDF_DATA.RECORD_STATUS_CD` (varchar(8) with CHECK constraint for 'ACTIVE'/'INACTIVE'). Wrong source column, not a width oversight. | **Merged on main** (PR #827, commit `bb882115`). | `015-sp_nrt_ldf_postprocessing-001.sql:863, 1006, 1132` |
| [07](./07_ldf_dimensional_data_zero/) | `sp_nrt_ldf_dimensional_data_postprocessing` early-RETURN guard misclassifies intentionally-filtered ldf_uids as "missing NRT records", plus a latent INNER/LEFT JOIN inconsistency | High (LDF_DIMENSIONAL_DATA never populates; cascades to all per-condition LDF tables) | `265-sp_nrt_ldf_dimensional_data_postprocessing-001.sql:136-158, 648` |
| [08](./08_ldf_tetanus_substring/) | **6-instance family**: unguarded `SUBSTRING(s, 1, LEN(s)-1)` idiom across 6 per-condition LDF datamart SPs fails when no dynamic columns added yet | Medium (each fires on first invocation against empty per-condition LDF table) | `285:603, 290:893, 295:627, 300:833, 305:1105, 320:594` (the `*-sp_ldf_*_datamart_postprocessing-001.sql` files) |
| [09](./09_dyn_dm_unpivot_type/) | `sp_dyn_dm_repeatvarch_postprocessing` step 16 dynamic UNPIVOT raises Msg 8167 ("type of column EPI_CNTRY_OF_EXP conflicts with other columns in the UNPIVOT list") because repeat-block column types in `nrt_metadata_columns` are heterogeneous and the SP doesn't CAST before unpivoting | Medium (blocks every `DM_INV_<DATAMART>` wide table; surfaces when the reporting-pipeline-service invokes `sp_dyn_dm_main_postprocessing` for HEPATITIS_A_ACUTE during the CDC drain) | `205-sp_dyn_dm_repeatvarch_postprocessing-001.sql:531-557` |
| [10](./10_sld_investigation_repeat_key_alloc/) | `sp_sld_investigation_repeat_postprocessing` surrogate-key allocation: `LOOKUP_TABLE_N_REPT.D_REPT_KEY` is INT NOT NULL with no DEFAULT/IDENTITY, the INSERT supplies only `PAGE_CASE_UID`, the column ends up as `1`, and that 1 is then filtered out by `WHERE D_INVESTIGATION_REPEAT_KEY != 1` at line 1349. New dim rows stage correctly but never reach `D_INVESTIGATION_REPEAT`. | High (blocks every new row in `D_INVESTIGATION_REPEAT`, which is the dim for repeating-block dynamic columns). Suggested fix: IDENTITY column on LOOKUP_TABLE_N_REPT, or ROW_NUMBER()-derived key inside the SP. | `010-sp_sld_investigation_repeat_postprocessing-001.sql:1146, 1349` |
| [11](./11_aggregate_report_datamart_schema_mismatch/) | `sp_aggregate_report_datamart_postprocessing` dynamic UPDATE references column `NOTIFICATION_UPD_DT_KEY` which `AGGREGATE_REPORT_DATAMART` does not have (table has only `NOTIFICATION_STATUS` and `NOTIFICATION_LOCAL_ID`). Msg 207 inside the SP's try/catch is silently swallowed; AGGREGATE_REPORT_DATAMART never populates. | Medium (blocks AGGREGATE_REPORT_DATAMART entirely; affects any aggregate report; likely never exercised in normal individual-case production flows). Suggested fix: add `NOTIFICATION_UPD_DT_KEY` column to AGGREGATE_REPORT_DATAMART (mirrors summary_report_case structure), OR remove that column reference from the SP's UPDATE/INSERT statements. | `050-sp_aggregate_report_datamart_postprocessing-001.sql:187, 268, 286` |
| [12](./12_bmird_case_datamart_row_number_partition/) | `sp_bmird_case_datamart_postprocessing` `ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id)` collapses multi-value answer rows so only the `_1` pivot slot fills | Medium (blocks 13 multi-value cols, `UNDERLYING_CONDITION_2..8`, `NON_STERILE_SITE_2..3`, `ADD_CULTURE_*_SITE_2..3`, on `BMIRD_STREP_PNEUMO_DATAMART`). Open, not fixed. | `040-sp_bmird_case_datamart_postprocessing-001.sql:555-558` |
| [13](./13_sld_investigation_repeat_text_pivot_null_propagation/) | `sp_sld_investigation_repeat_postprocessing` dynamic TEXT pivot column-list builder NULL-propagates, silently leaving TEXT columns of `D_INVESTIGATION_REPEAT` NULL (tail-EXEC returns 0 rows, no error) | High (blocks ~50 TEXT cols on `D_INVESTIGATION_REPEAT` for any PHC sharing the polluted state). Open, not fixed. | `010-sp_sld_investigation_repeat_postprocessing-001.sql:~212` |
| [15](./15_event_metric_add_user_name_null/) | `sp_event_metric_datamart_postprocessing` leaves `ADD_USER_NAME` NULL on some branches; downstream `sp_sr100_datamart_postprocessing` swallows the resulting NOT NULL violation, blocking `SR100` | Medium (blocks `dbo.SR100` entirely, 0/20; likely under-populates `EVENT_METRIC.ADD_USER_NAME` / `LAST_CHG_USER_NAME` in production too). Documented, not fixed. | `155-sp_sr100_datamart_postprocessing-001.sql` + `sp_event_metric_datamart_postprocessing` |
| [18](./18_bmird_strep_pneumo_site_cross_join/) | `sp_bmird_strep_pneumo_datamart_postprocessing` merges the three additional-site datasets (`#DM_BMD125/142/144`) on `INVESTIGATION_KEY` only, a Cartesian product, so a single value repeats across `NON_STERILE_SITE_1..3` / `ADD_CULTURE_1_SITE_1..3` / `ADD_CULTURE_2_SITE_1..3` instead of the distinct selections. The next bug in the BMIRD multi-value chain after #12: invisible while each field had only one value, exposed once `zz_bmird_fill.sql` authors one-observation-with-N-coded-values. | Medium (corrupts the 9 additional-site columns on `BMIRD_STREP_PNEUMO_DATAMART` for any multi-value investigation). **Fixed on `aw/odse-test-seed`** (rank-aligned join; no PR yet). | `140-sp_bmird_strep_pneumo_datamart_postprocessing-001.sql` (`#DM_BR7` step) |

## Surprises during investigation

Three hypotheses in the original brief did not survive investigation.
They reshape the picture, so they are worth recording.

1. **Bug #5 is not a 10-SP shared bug.** The original brief listed 10
   condition-datamart SPs as sharing the same TMP_F_PAGE_CASE pattern.
   In fact, only `sp_hepatitis_datamart_postprocessing` references
   `#TMP_F_PAGE_CASE` (20 occurrences). The other 9 SPs have 0
   references; they use entirely different temp-table structures
   (`#S_PHC_LIST`, `#S_INVESTIGATION_LIST`, `#PATIENT`). Their 0-row
   symptoms are unrelated to bug #5 and need separate investigation.

2. **Bug #5 is not a transaction-isolation bug.** All 5 isolation
   hypotheses (RCSI, BEGIN TRANSACTION scoping, WITH(NOLOCK),
   STRING_SPLIT type conversion, parameter sniffing) were ruled out
   empirically. The actual logged-0 symptom is caused by
   `IF @debug='true' SELECT *` resetting `@@ROWCOUNT` between the
   `SELECT INTO` and the `SELECT @ROWCOUNT_NO = @@ROWCOUNT` capture.
   The temp table itself is correctly populated.

3. **Bug #5 is distinct from bug #7.** They were initially hypothesized
   as the same root cause. They are independent: #5 is the @@ROWCOUNT
   logging defect; #7 is two SP logic bugs (early-RETURN guard
   misclassification plus an INNER/LEFT JOIN inconsistency).

4. **Bug #8 is a 6-instance family.** It was originally framed as a
   single SUBSTRING issue in `sp_ldf_tetanus_datamart_postprocessing`.
   An audit found the same unguarded idiom at 6 sites across the 6
   per-condition LDF datamart SPs, plus 3 already-guarded sites. The
   pattern is known but inconsistently applied.

## Current status (2026-05-27)

| # | Status | Notes |
| --- | --- | --- |
| #1 | Resolved, non-issue | RDB_DATE is correctly populated by seeds in normal environments; the SP is not on the live path. Separate seed-correction PR in-flight. |
| #2 | Fixed on main | PR #769 (commit `a0dbf3be`), pre-dates this investigation. |
| #3 | PR #837 open on `aw/app-471/bug-3`. | RTR fix, query rewrite: replaced self-defeating join with staging-side walk via `nrt_morbidity_observation.followup_observation_uid` CSV filtered to `obs_domain_cd_st_1 = 'C_Result'`. Stays inside RDB_MODERN (no cross-DB ODSE read; see STRATEGY.md convention). |
| #4 | Merged on main | PR #826 (commit `92a56d42`). |
| #5a | **Squashed on `aw/odse-test-seed`** (no separate PR). | RTR fix, line swap: capture `@@ROWCOUNT` before debug SELECT. Logging-only; no behavioral impact. |
| #5b | Resolved on `aw/odse-test-seed`; fixture-side; no PR. | patient_id authored inline (literal `20000000`) on every Tier 1 and Tier 3 `nrt_investigation` row that drives the Datamart chain. Orchestrator UPDATE workaround removed. End-to-end uplift: HEPATITIS_DATAMART 0 to 1, F_PAGE_CASE 1 to 6. |
| #6 | Merged on main | PR #827 (commit `bb882115`). |
| #7 | **Squashed on `aw/odse-test-seed`** as `[SQUASH bug-7]` commit. Was PR #839 (approved). | RTR fix, two-line: early-RETURN guard misclassification plus INNER-to-LEFT JOIN harmonization. Unblocks LDF_DIMENSIONAL_DATA. |
| #8 | **Squashed on `aw/odse-test-seed`** as `[SQUASH bug-8]` commit. Was PR #840 (approved). | RTR fix, mechanical: apply existing guard pattern at 6 unguarded `SUBSTRING(s, 1, LEN(s)-1)` sites. |
| #9 | **Fixed on `aw/odse-test-seed`** (commit a88e40e5). | Dynamic UNPIVOT type-conflict in dyn_dm chain. Fix: CAST/TRY_CAST list wrapped around each column in the inner SELECT of UNPIVOT, applied to 3 SPs (repeatvarch nvarchar(max), repeatnumeric nvarchar(max), repeatdate DATE). Also pinned QUOTED_IDENTIFIER ON in all 3 files so re-applies via sqlcmd don't break the dynamic SELECT INTO. Chain runs to SP_COMPLETE. Headline coverage unchanged because DM_INV_* tables aren't in-scope and dim-table downstream needs richer fixture data. |
| #10 | **Fixed on `aw/odse-test-seed`** (commit 99ef3517). | sp_sld_investigation_repeat_postprocessing surrogate-key collision. Fix: DBCC CHECKIDENT RESEED on LOOKUP_TABLE_N_REPT to max(2, MAX(D_INV_REPEAT_KEY)+1) right after the DELETE, so the next IDENTITY-assigned D_REPT_KEY is always >= 2 and passes the `!= 1` filter at line 1349. Also pinned QUOTED_IDENTIFIER ON. The dim populates via the CDC drain (service `processInvestigation` -> `sp_page_builder_postprocessing` -> `sp_sld_investigation_repeat_postprocessing`, gated on `rdb_table_name_list` containing `'D_INVESTIGATION_REPEAT'`); no script step. D_INVESTIGATION_REPEAT 2 to 8 rows (+6 new), 1/252 to 12/256 cols. |
| #11 | **Open**, documented; no fix attempted. | sp_aggregate_report_datamart references column NOTIFICATION_UPD_DT_KEY that target table doesn't have. SP/schema mismatch. Surfaced 2026-05-21; fixture is correct but blocked by this SP defect. |
| #12 | **Open**, documented; no fix attempted. | Surfaced 2026-05-24. `sp_bmird_case_datamart_postprocessing` ROW_NUMBER PARTITION BY branch_id collapses multi-value rows; 13 cols on BMIRD_STREP_PNEUMO_DATAMART stuck at the `_1` slot. |
| #13 | **Open**, documented; no fix attempted. | Surfaced 2026-05-24. `sp_sld_investigation_repeat_postprocessing` dynamic TEXT pivot column-list builder NULL-propagates; ~50 TEXT cols on D_INVESTIGATION_REPEAT stay NULL with no error raised. |
| #15 | **Documented**, not fixed (RTR routine, left to upstream). | `sp_event_metric_datamart_postprocessing` leaves ADD_USER_NAME NULL on some branches; `sp_sr100_datamart_postprocessing` swallows the NOT NULL violation, blocking SR100 entirely (0/20). Repro fully reduced in findings.md. |

### Remaining work

**Branch hygiene.** Fixes already landed on `aw/odse-test-seed`;
re-rebase if and when they merge upstream:

- **#3**: PR #837 still open upstream; squashed as `[SQUASH bug-3]` so
  the branch is self-contained. Re-rebase onto main once #837 merges.
- **#5a**: squashed; no separate PR pursued.
- **#7 and #8**: squashed; PRs #839/#840 were approved but never merged;
  re-rebase if they land upstream.
- **#9 and #10**: fixed on-branch (commits `a88e40e5`, `99ef3517`). The
  reporting-pipeline-service fires
  `sp_sld_investigation_repeat_postprocessing` during the CDC drain via
  `sp_page_builder_postprocessing` (gated on `rdb_table_name_list`
  containing `'D_INVESTIGATION_REPEAT'`), so `D_INVESTIGATION_REPEAT`
  populates end-to-end once the fixtures carry that table name in the
  investigation's `rdb_table_name_list`.

**Open bugs needing a fix.** Documented with repros; no fix attempted:

- **#11**: `sp_aggregate_report_datamart_postprocessing` references
  `NOTIFICATION_UPD_DT_KEY`, which AGGREGATE_REPORT_DATAMART lacks. Add
  the column to the table (mirrors summary_report_case) or drop the
  reference from the SP. See `11_aggregate_report_datamart_schema_mismatch/`.
- **#12**: `sp_bmird_case_datamart_postprocessing` ROW_NUMBER PARTITION
  collapses multi-value rows (13 BMIRD cols). See
  `12_bmird_case_datamart_row_number_partition/`.
- **#13**: `sp_sld_investigation_repeat_postprocessing` TEXT-pivot
  column-list builder NULL-propagates (~50 D_INVESTIGATION_REPEAT cols).
  See `13_sld_investigation_repeat_text_pivot_null_propagation/`.
- **#15**: `sp_event_metric_datamart_postprocessing` leaves
  ADD_USER_NAME NULL, blocking SR100 (0/20). See
  `15_event_metric_add_user_name_null/`.

### Additional issues surfaced but not yet promoted to bugs/

These were noted during fixture authoring. They are not serious enough
to file as their own bugs but are worth tracking:

- **BMIRD INSERT-without-dedup-guard** in
  `140-sp_bmird_strep_pneumo_datamart_postprocessing-001.sql`:
  re-runs against the same PHC append rather than DELETE-then-INSERT.
  Same shape as the pre-existing `notification_event` over-broad join
  in `sp_tb_datamart_postprocessing` line 1525. Medium severity.
- **CMG sentinel duplication** in `005-sp_nrt_investigation_postprocessing-001.sql`
  lines 714-732, 849-858: every Investigation gets a sentinel
  (KEY=1, NULL) confirmation-method-group row even without an
  `nrt_investigation_confirmation` staging row. Doubles
  `STD_HIV_DATAMART` rows on a `SELECT DISTINCT INVESTIGATION_KEY,
  CONFIRMATION_DT` join. Worked around in STD/HIV fixture by
  authoring a real `nrt_investigation_confirmation` row.
- **COVID_CASE_DATAMART varchar(2000) row-size warning**: the SP
  emits ~440 `ALTER TABLE ... ADD <col> varchar(2000)` statements,
  exceeding SQL Server's 8060-byte row limit. INSERTs currently
  succeed because few columns populate; would hard-fail under denser
  data. Low/medium severity. Recommended fix: `varchar(MAX)` or
  pivot wide answers into a child table.

### Headline reframing from the HEPATITIS_DATAMART investigation

An earlier triage framed this as a transaction-isolation bug that
blocked the entire 10-SP condition-datamart family. That framing did
not survive investigation:

- There is no isolation bug. The two symptoms cited were (a) bug 5a
  (logging-only `@@ROWCOUNT` reset) and (b) bug 5b (fixture-side NULL
  cascade through `COALESCE(PATIENT.PATIENT_KEY, 1)` to sentinel
  PATIENT_UID NULL to the SP's `DELETE WHERE PATIENT_UID IS NULL`).
- Only `sp_hepatitis_datamart_postprocessing` references
  `#TMP_F_PAGE_CASE`. The 9 other condition datamarts (TB, COVID,
  STD/HIV, BMIRD, Pertussis, Measles, Rubella, Var, CRS) do not
  share a single blocker. Each has its own coverage gap (PAM fact
  data missing, observation answers missing, F_PAGE_CASE form_cd
  exclusions, and so on). Documented per-datamart in
  `coverage/coverage_hep_datamart_investigation.md`.

## How to run a repro

Each `repro.sql` is self-contained and assumes a fresh baseline 6.0.18.1
DB plus the merged-fixture state from
`scripts/merge_and_verify.sh`. To set up:

```sh
cd <repo-root>/NEDSS-DataReporting
docker compose down -v && docker compose up -d nbs-mssql liquibase
# Wait for liquibase exit 0 (~3-5 min)

cd testing-tools/synthetic-odse-fixtures
./scripts/merge_and_verify.sh    # Run end-to-end merge

# Run the specific bug's repro
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i bugs/05_tmp_f_page_case_family/repro.sql
```

## Total scope

- **14 bug investigations** in their own `bugs/` directories, numbered
  #1–#13 and #15. There is no `#14` directory: `#14` was assigned in
  the STRATEGY.md progress log to a `sp_d_contact_record_postprocessing`
  STRING_AGG / VARCHAR(8000) dynamic-SQL truncation issue that was never
  promoted to its own directory here.
- **Dispositions:** 3 fixes merged upstream (#2 PR #769, #4 PR #826,
  #6 PR #827); 6 fixed on `aw/odse-test-seed` (#3, #5, #7, #8, #9, #10);
  5 documented with repros (#1 resolved as a non-issue; #11, #12, #13,
  #15 open, no fix attempted).
- Plus **3-4 additional minor issues** flagged but not promoted to
  their own directories (BMIRD INSERT dedup; CMG sentinel duplication;
  COVID row-size warning; Pertussis SP @@ROWCOUNT-after-IF, same
  pattern as bug 5a).
- Several "single bug" entries expand to multiple distinct SP-level
  defects (bug #1 has 2 issues, bugs #5 and #7 have 2 each, and bug #8
  is a 6-instance family), so the count of distinct defects is
  meaningfully higher than 14.
- **Coverage state of the originally-blocked tables**:
  HEPATITIS_DATAMART unblocks at 0 to 1 row once #5b's orchestrator
  change is merged into `aw/odse-test-seed`; LDF_DIMENSIONAL_DATA and
  LDF_TETANUS unblock once #7 and #8 land. The 9 other condition
  datamarts (TB, COVID, STD/HIV, BMIRD, Pertussis, Measles, Rubella,
  Var, CRS) are blocked by separate per-condition coverage gaps
  (PAM data, observation answers, F_PAGE_CASE form_cd exclusions),
  not a shared bug. See
  `coverage/coverage_hep_datamart_investigation.md`.

## Context

These bugs were surfaced incrementally over the project's tier-by-tier
build. See `STRATEGY.md` for the project's overall approach. The Tier 3
coverage investigation notes that informed each bug's repro are captured
in the per-SP `coverage/` reports.
