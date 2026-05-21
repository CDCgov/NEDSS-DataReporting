# RTR bugs surfaced by the comparison-fixtures project

This directory contains 9 bug investigations produced by the
comparison-fixtures project's end-to-end merged-fixture run. Each
subdirectory has:

- `repro.sql` — self-contained SQL script demonstrating the bug (where
  applicable; some bugs are documented from in-orchestrator triggers)
- `findings.md` — investigation report with hypotheses tested,
  root cause (where determined), and suggested fix

All bugs were observed in baseline `ghcr.io/cdcent/nedssdb:latest`
with `DATABASE_VERSION=6.0.18.1`.

## Index

| # | Bug | Severity | Files affected |
| --- | --- | --- | --- |
| [01](./01_sp_get_date_dim/) | `sp_get_date_dim` references nonexistent `dbo.rdb_date_temp`; also has an inverted-IF logic bug | **Resolved — non-issue.** RDB_DATE is correctly populated by seeds in normal environments; SP is not on the live path. Separate seed-correction PR in-flight. | `014-sp_get_date_dim-001.sql` |
| [02](./02_sp_contact_record_event/) | `sp_contact_record_event` references `nbs_odse.dbo.fn_get_value_by_cd_codeset` (function lives in `RDB_MODERN.dbo`) | **Already fixed on main** via PR #769 (commit `a0dbf3be`). | `069-sp_contact_record_event-001.sql:69` |
| [03](./03_morb_rpt_user_comment/) | `sp_d_morbidity_report_postprocessing` self-defeating join+filter at lines 802-816 | **PR #837 open** on branch `aw/app-471/bug-3`. | `016-sp_nrt_morbidity_report_postprocessing-001.sql:802-816` |
| [04](./04_provider_postprocessing_typo/) | `sp_nrt_provider_postprocessing` line 564 typo: `#PATIENT_UPDATE_LIST` should be `#PROVIDER_UPDATE_LIST` | **Merged on main** (PR #826, commit `92a56d42`). | `003-sp_nrt_provider_postprocessing-001.sql:564` |
| [05](./05_tmp_f_page_case_family/) | **TWO bugs**: (5a) `sp_hepatitis_datamart_postprocessing` logs incorrect row_count for #TMP_F_PAGE_CASE due to `IF @debug` resetting `@@ROWCOUNT` (logging-only); (5b) `nrt_investigation.patient_id NULL` cascades through PATIENT sentinel into a `DELETE WHERE PATIENT_UID IS NULL` (fixture-side; actual blocker for HEPATITIS_DATAMART) | 5b **resolved** on `aw/odse-test-seed` (fixture-side; no PR — orchestrator + Tier 3 variants now set `patient_id`). 5a still open. | `013-sp_hepatitis_datamart_postprocessing-001.sql:108-111, 2149` + fixture `nrt_investigation` |
| [06](./06_ldf_data_truncation/) | `sp_nrt_ldf_postprocessing` maps `metadata_record_status_cd` ('LDF_PROCESSED', 13 chars) into `LDF_DATA.RECORD_STATUS_CD` (varchar(8) with CHECK constraint for 'ACTIVE'/'INACTIVE'). **Wrong source column**, not a width oversight. | **Merged on main** (PR #827, commit `bb882115`). | `015-sp_nrt_ldf_postprocessing-001.sql:863, 1006, 1132` |
| [07](./07_ldf_dimensional_data_zero/) | `sp_nrt_ldf_dimensional_data_postprocessing` early-RETURN guard misclassifies intentionally-filtered ldf_uids as "missing NRT records" + a latent INNER/LEFT JOIN inconsistency | High (LDF_DIMENSIONAL_DATA never populates; cascades to all per-condition LDF tables) | `265-sp_nrt_ldf_dimensional_data_postprocessing-001.sql:136-158, 648` |
| [08](./08_ldf_tetanus_substring/) | **6-instance family**: unguarded `SUBSTRING(s, 1, LEN(s)-1)` idiom across 6 per-condition LDF datamart SPs fails when no dynamic columns added yet | Medium (each fires on first invocation against empty per-condition LDF table) | `285:603, 290:893, 295:627, 300:833, 305:1105, 320:594` (the `*-sp_ldf_*_datamart_postprocessing-001.sql` files) |
| [09](./09_dyn_dm_unpivot_type/) | `sp_dyn_dm_repeatvarch_postprocessing` step 16 dynamic UNPIVOT raises Msg 8167 ("type of column EPI_CNTRY_OF_EXP conflicts with other columns in the UNPIVOT list") because repeat-block column types in `nrt_metadata_columns` are heterogeneous and the SP doesn't CAST before unpivoting | Medium (blocks every `DM_INV_<DATAMART>` wide table; surfaces when orchestrator's Step 9 invokes `sp_dyn_dm_main_postprocessing` for HEPATITIS_A_ACUTE) | `205-sp_dyn_dm_repeatvarch_postprocessing-001.sql:531-557` |

## Surprises during investigation

The original brief had three hypotheses that **did not survive
investigation**. Worth noting because they reshape the picture:

1. **Bug #5 is not a 10-SP shared bug.** Original brief listed 10
   condition-datamart SPs as sharing the same TMP_F_PAGE_CASE pattern.
   In fact, only `sp_hepatitis_datamart_postprocessing` references
   `#TMP_F_PAGE_CASE` (20 occurrences). The other 9 SPs have **0**
   references — they use entirely different temp-table structures
   (`#S_PHC_LIST`, `#S_INVESTIGATION_LIST`, `#PATIENT`). Their 0-row
   symptoms are unrelated to bug #5 and need separate investigation.

2. **Bug #5 is not a transaction-isolation bug.** All 5 isolation
   hypotheses (RCSI, BEGIN TRANSACTION scoping, WITH(NOLOCK),
   STRING_SPLIT type conversion, parameter sniffing) were ruled out
   empirically. The actual logged-0 symptom is caused by
   `IF @debug='true' SELECT *` resetting `@@ROWCOUNT` between the
   `SELECT INTO` and the `SELECT @ROWCOUNT_NO = @@ROWCOUNT` capture.
   The temp table itself is correctly populated.

3. **Bug #5 ≠ Bug #7.** Initially hypothesized as the same root cause.
   Confirmed independently they are distinct: #5 is the @@ROWCOUNT
   logging defect; #7 is two SP logic bugs (early-RETURN guard
   misclassification + INNER/LEFT JOIN inconsistency).

4. **Bug #8 is a 6-instance family.** Originally framed as a single
   SUBSTRING issue in `sp_ldf_tetanus_datamart_postprocessing`. Audit
   found the same unguarded idiom at 6 sites across the 6
   per-condition LDF datamart SPs (and 3 already-guarded sites — the
   pattern is known but inconsistently applied).

## Current status (2026-05-21)

| # | Status | Notes |
| --- | --- | --- |
| #1 | Resolved — non-issue | RDB_DATE is correctly populated by seeds in normal environments; the SP is not on the live path. Separate seed-correction PR in-flight. |
| #2 | Fixed on main | PR #769 (commit `a0dbf3be`), pre-dates this investigation. |
| #3 | PR #837 open on `aw/app-471/bug-3`. | RTR fix, query rewrite: replaced self-defeating join with staging-side walk via `nrt_morbidity_observation.followup_observation_uid` CSV filtered to `obs_domain_cd_st_1 = 'C_Result'`. Stays inside RDB_MODERN (no cross-DB ODSE read — see STRATEGY.md convention). |
| #4 | Merged on main | PR #826 (commit `92a56d42`). |
| #5a | **Squashed on `aw/odse-test-seed`** (no separate PR). | RTR fix, line swap — capture `@@ROWCOUNT` before debug SELECT. Logging-only; no behavioral impact. |
| #5b | Resolved on `aw/odse-test-seed` — fixture-side; no PR. | patient_id authored inline (literal `20000000`) on every Tier 1 and Tier 3 `nrt_investigation` row that drives the Datamart chain. Orchestrator UPDATE workaround removed. End-to-end uplift: HEPATITIS_DATAMART 0→1, F_PAGE_CASE 1→6. |
| #6 | Merged on main | PR #827 (commit `bb882115`). |
| #7 | **Squashed on `aw/odse-test-seed`** as `[SQUASH bug-7]` commit. Was PR #839 (approved). | RTR fix, two-line: early-RETURN guard misclassification + INNER→LEFT JOIN harmonization. Unblocks LDF_DIMENSIONAL_DATA. |
| #8 | **Squashed on `aw/odse-test-seed`** as `[SQUASH bug-8]` commit. Was PR #840 (approved). | RTR fix, mechanical: apply existing guard pattern at 6 unguarded `SUBSTRING(s, 1, LEN(s)-1)` sites. |
| #9 | **Open** — documented; no fix attempted. | Dynamic UNPIVOT type-conflict in dyn_dm chain. Suggested fix: wrap each column in `CAST(<col> AS nvarchar(max))` in the dynamic SELECT before UNPIVOT. Need to confirm whether heterogeneous repeat-block column types are a baseline-data defect or a latent SP defect that prod dodges via uniform metadata. |

### Remaining work

- **#3** — PR #837 still open upstream; squashed onto `aw/odse-test-seed`
  as `[SQUASH bug-3]` so the branch is self-contained. Re-rebase onto
  main once #837 merges.
- **#5a** — squashed onto `aw/odse-test-seed`. No separate PR pursued
  per user direction.
- **#7 + #8** — squashed onto `aw/odse-test-seed`. PRs #839/#840 were
  approved but never merged; re-rebase if they land upstream.
- **#9** — open. Investigate whether heterogeneous repeat-block column
  types in `nrt_metadata_columns` are a baseline-data defect (would
  not affect prod) or a latent SP defect (would). Suggested fix:
  wrap each column in `CAST(<col> AS nvarchar(max))` inside the
  dynamic SELECT before UNPIVOT. See `09_dyn_dm_unpivot_type/findings.md`.

### Headline reframing from the HEPATITIS_DATAMART investigation

The "transaction-isolation bug blocks the entire 10-SP
condition-datamart family" hypothesis in `coverage_tier_3.md` did
not survive investigation:

- There is no isolation bug. The two symptoms cited were (a) bug 5a
  (logging-only `@@ROWCOUNT` reset) and (b) bug 5b (fixture-side NULL
  cascade through `COALESCE(PATIENT.PATIENT_KEY, 1)` → sentinel
  PATIENT_UID NULL → SP's `DELETE WHERE PATIENT_UID IS NULL`).
- Only `sp_hepatitis_datamart_postprocessing` references
  `#TMP_F_PAGE_CASE`. The 9 other condition datamarts (TB, COVID,
  STD/HIV, BMIRD, Pertussis, Measles, Rubella, Var, CRS) do not
  share a single shared blocker — each has its own coverage gap
  (PAM fact data missing, observation answers missing, F_PAGE_CASE
  form_cd exclusions, etc.). Documented per-datamart in
  `coverage/coverage_hep_datamart_investigation.md`.

## How to run a repro

Each `repro.sql` is self-contained and assumes a fresh baseline 6.0.18.1
DB plus the merged-fixture state from
`scripts/merge_and_verify.sh`. To set up:

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting
docker compose down -v && docker compose up -d nbs-mssql liquibase
# Wait for liquibase exit 0 (~3-5 min)

cd utilities/comparison-fixtures
./scripts/merge_and_verify.sh    # Run end-to-end merge

# Run the specific bug's repro
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i bugs/05_tmp_f_page_case_family/repro.sql
```

## Total scope

- **9 bug categories** investigated
- **At least 12 distinct SP-level defects** identified across them
  (bug #1 has 2 issues; bug #5 has 2 issues; bug #7 has 2 issues;
  bug #8 has 6 instances; bug #9 is one SP defect with broad
  impact across the dyn_dm datamart family). Several "single bug"
  entries in the index expand to multiple fixes.
- **Coverage state of the originally-blocked tables**:
  HEPATITIS_DATAMART unblocks at 0 → 1 row once #5b's orchestrator
  change is merged into `aw/odse-test-seed`; LDF_DIMENSIONAL_DATA and
  LDF_TETANUS unblock once #7 + #8 land. The 9 other condition
  datamarts (TB, COVID, STD/HIV, BMIRD, Pertussis, Measles, Rubella,
  Var, CRS) are blocked by separate per-condition coverage gaps
  (PAM data, observation answers, F_PAGE_CASE form_cd exclusions),
  not a shared bug — see
  `coverage/coverage_hep_datamart_investigation.md`.

## Context

These bugs were surfaced incrementally over the project's tier-by-tier
build. See `STRATEGY.md` for the project's overall approach and
`coverage_tier_3.md` for detailed prior investigation notes that
informed each bug's repro.
