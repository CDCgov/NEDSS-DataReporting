# RTR bugs surfaced by the comparison-fixtures project

This directory contains 8 bug investigations produced by the
comparison-fixtures project's end-to-end merged-fixture run. Each
subdirectory has:

- `repro.sql` — self-contained SQL script demonstrating the bug
- `findings.md` — investigation report with hypotheses tested,
  root cause (where determined), and suggested fix

All bugs were observed in baseline `ghcr.io/cdcent/nedssdb:latest`
with `DATABASE_VERSION=6.0.18.1`.

## Index

| # | Bug | Severity | Files affected |
| --- | --- | --- | --- |
| [01](./01_sp_get_date_dim/) | `sp_get_date_dim` references nonexistent `dbo.rdb_date_temp`; also has an inverted-IF logic bug | High (SP unrunnable; documented setup path is broken) | `014-sp_get_date_dim-001.sql` |
| [02](./02_sp_contact_record_event/) | `sp_contact_record_event` references `nbs_odse.dbo.fn_get_value_by_cd_codeset` (function lives in `RDB_MODERN.dbo`) | High (SP unrunnable on every input) | `069-sp_contact_record_event-001.sql:69` |
| [03](./03_morb_rpt_user_comment/) | `sp_d_morbidity_report_postprocessing` self-defeating join+filter at lines 802-816 | Medium (silent — table never populates) | `016-sp_nrt_morbidity_report_postprocessing-001.sql:802-816` |
| [04](./04_provider_postprocessing_typo/) | `sp_nrt_provider_postprocessing` line 564 typo: `#PATIENT_UPDATE_LIST` should be `#PROVIDER_UPDATE_LIST` | Low/latent (UPDATE-with-diff path only) | `003-sp_nrt_provider_postprocessing-001.sql:564` |
| [05](./05_tmp_f_page_case_family/) | **TWO bugs**: (5a) `sp_hepatitis_datamart_postprocessing` logs incorrect row_count for #TMP_F_PAGE_CASE due to `IF @debug` resetting `@@ROWCOUNT` (logging-only); (5b) `nrt_investigation.patient_id NULL` cascades through PATIENT sentinel into a `DELETE WHERE PATIENT_UID IS NULL` (fixture-side; actual blocker for HEPATITIS_DATAMART) | High (5b blocks HEPATITIS_DATAMART population) | `013-sp_hepatitis_datamart_postprocessing-001.sql:108-111, 2149` + fixture `nrt_investigation` |
| [06](./06_ldf_data_truncation/) | `sp_nrt_ldf_postprocessing` maps `metadata_record_status_cd` ('LDF_PROCESSED', 13 chars) into `LDF_DATA.RECORD_STATUS_CD` (varchar(8) with CHECK constraint for 'ACTIVE'/'INACTIVE'). **Wrong source column**, not a width oversight. | High (latent in baseline; manifests on first LDF data flow) | `015-sp_nrt_ldf_postprocessing-001.sql:863, 1006, 1132` |
| [07](./07_ldf_dimensional_data_zero/) | `sp_nrt_ldf_dimensional_data_postprocessing` early-RETURN guard misclassifies intentionally-filtered ldf_uids as "missing NRT records" + a latent INNER/LEFT JOIN inconsistency | High (LDF_DIMENSIONAL_DATA never populates; cascades to all per-condition LDF tables) | `265-sp_nrt_ldf_dimensional_data_postprocessing-001.sql:136-158, 648` |
| [08](./08_ldf_tetanus_substring/) | **6-instance family**: unguarded `SUBSTRING(s, 1, LEN(s)-1)` idiom across 6 per-condition LDF datamart SPs fails when no dynamic columns added yet | Medium (each fires on first invocation against empty per-condition LDF table) | `285:603, 290:893, 295:627, 300:833, 305:1105, 320:594` (the `*-sp_ldf_*_datamart_postprocessing-001.sql` files) |

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

## Suggested triage order

After investigation, the corrected priority is:

1. **#5b (fixture-side)** — fastest unlock for HEPATITIS_DATAMART. Add
   `UPDATE nrt_investigation SET patient_id = <real-patient-uid> WHERE
   public_health_case_uid = 20000100` to the orchestrator. Once this
   is fixed, the actual reason the other 9 condition datamarts are
   empty becomes investigable (each likely has its own variant of
   this fixture-side issue).

2. **#7 (RTR fix, two-line)** — unblocks all per-condition LDF tables
   (LDF_TETANUS, LDF_HEPATITIS, etc.) for fixtures with valid LDF
   answers.

3. **#8 (RTR fix, 6 sites mechanical)** — even after #7 is fixed, the
   6 unguarded SUBSTRING sites will fire on first invocation against
   empty per-condition LDF tables. Apply the existing guard pattern
   (already used at 3 other sites) to the 6 vulnerable sites.

4. **#1, #2** (RTR fix, one-line each) — both are "SP cannot run"
   blockers; one-line fixes.

5. **#6** (RTR fix, two-line) — change the SP's source column from
   `metadata_record_status_cd` to `record_status_cd` at lines 863 + 1006.

6. **#3** (RTR fix, query rewrite) — self-defeating join in
   `sp_d_morbidity_report_postprocessing`; replace with two-hop
   act_relationship traversal.

7. **#5a** (RTR fix, line swap) — logging-only; no behavior impact
   beyond fixing the row_count log entry.

8. **#4** (RTR fix, one-line) — latent on UPDATE-with-diff path; low
   priority.

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

- **8 bug categories** investigated
- **At least 11 distinct SP-level defects** identified across them
  (bug #1 has 2 issues; bug #5 has 2 issues; bug #7 has 2 issues;
  bug #8 has 6 instances). Several "single bug" entries in the index
  expand to multiple fixes.
- **3 isolation-blocked tables** (HEPATITIS_DATAMART, LDF_DIMENSIONAL_DATA,
  LDF_TETANUS) traced to specific root causes; the 9 other condition
  datamarts (TB, COVID, STD/HIV, BMIRD, Pertussis, Measles, Rubella,
  Var, CRS) need follow-on investigation.

## Context

These bugs were surfaced incrementally over the project's tier-by-tier
build. See `STRATEGY.md` for the project's overall approach and
`coverage_tier_3.md` for detailed prior investigation notes that
informed each bug's repro.
