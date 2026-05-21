# Overnight loop session summary — 2026-05-21

**Window**: T0 = 2026-05-21 02:30:09 PDT, T+4h ~30m at writeup.
**Budget**: 5 hours wall-clock. Self-paced via `<<autonomous-loop-dynamic>>`
sentinel.

## Headline

**Coverage: 33.9% → 41.4% column coverage** (+7.5 percentage points,
+347 columns from 1566 → 1913 populated).

| Metric | Loop start | Loop end |
| --- | --- | --- |
| Fully covered tables | 65 | 66 (+1) |
| Partially covered | 32 | 35 (+3) |
| Empty | 20 | 16 (-4) |
| Populated columns | 1566 | 1913 (+347) |
| Column coverage % | 33.9% | 41.4% |

Combined with the daytime session this nudges the day's overall delta
to **21.8% → 41.4%** (+19.6 percentage points, +909 columns from the
21.8% baseline at start of yesterday's work). **Surpassed** the
previously-estimated 40% ceiling. New ceiling estimate without
upstream RTR fixes: probably 43-45%.

## Iterations (committed)

| # | Action | Δ | Commit |
| --- | --- | --- | --- |
| 1 | Pertussis full-chain fixture (UID 22007000) | 0pp | 6fd2929b |
| 2 | LDF Mumps + Foodborne answer chains | +0.3pp, +13 cols | 11a8c143 |
| 3 | Case-management staging + Step 9 SP wire-up | **+2.5pp, +119 cols** | b6a85259 |
| 4 | Summary-report-case Investigation + observations | +0.3pp, +12 cols | 40a017b1 |
| 5 | Aggregate-report fixture (blocked by RTR bug #11) | 0pp | 589136e1 |
| 6 | Enrich 9 Phase-2 nrt_investigation rows (~50 cols each) | **+2.9pp, +132 cols** | a802b9e5 |
| 7 | Extended enrichment to 12 stub PHCs | 0pp defensive | d396a706 |
| 8 | COVID contact + nrt_contact_answer for PHC 22003000 | **+1.5pp, +71 cols** | 0e6f7b62 |
| 9 | Vaccination enrichment (defensive, no movement) | 0pp | 360548a1 |

7 iterations, 6 committed (1 still authored but had to fix mid-iter).
Several apply attempts with errors that were diagnosed and fixed
in-iter (IDENTITY_INSERT column count, varchar width truncation,
NULL=NULL trap, alphabetical apply order with cross-fixture
dependencies).

## Biggest wins of the night

1. **Iter 6 (+2.9pp, +132 cols)** — UPDATE pattern on 9 Phase-2
   nrt_investigation rows. covid_case_datamart 53→87, tb_datamart
   61→95, var_datamart 61→91. The key insight: condition-specific
   datamart SPs read directly from `nrt_investigation.*` for many
   demographic / hospitalization / outbreak / transmission cols. Just
   filling in those cols on the existing staging rows propagates
   immediately to the datamart.
2. **Iter 3 (+2.5pp, +119 cols)** — case_management staging + Step 9
   SP wire-up. Discovered `sp_nrt_case_management_postprocessing`
   wasn't being invoked by the orchestrator; added it. Then authored
   a rich 67-col-wide nrt_investigation_case_management UPDATE pattern.
   d_case_management 0→62/67.
3. **Iter 8 (+1.5pp, +71 cols)** — COVID contact + 4 nrt_contact_answer
   rows. covid_contact_datamart 0/94 → 71/94 from just 1 contact row
   plus 4 exposure-type answer rows. High yield per row.

## Lessons surfaced

- **Alphabetical apply order matters** within Tier 3. Filename prefix
  controls ordering. Used `zz_` prefix to force enrichment fixture
  last (iter 6).
- **`varchar(N)` truncation traps everywhere.** Always check
  `INFORMATION_SCHEMA.COLUMNS.CHARACTER_MAXIMUM_LENGTH` before authoring
  string values. Iter 3 burned 2 apply cycles on this.
- **`NULL = NULL` in JOIN/IIF clauses is NULL (treated as false).**
  Trap caught on iter 5 attempt 1 — `batch_id NULL = batch_id NULL`
  silently zeroed every aggregate count. Fix: explicit batch_id=1.
- **Coverage `0pp` doesn't mean fixture was bad.** Pertussis (iter 1)
  populated 2 out-of-scope tables; Aggregate (iter 5) hit a real RTR
  bug. Both are valid defensive groundwork that will pay off when
  scope expands or bugs land.

## RTR bugs surfaced tonight

| # | Bug | Status |
| --- | --- | --- |
| 11 | `sp_aggregate_report_datamart_postprocessing` references `NOTIFICATION_UPD_DT_KEY` column that doesn't exist in `AGGREGATE_REPORT_DATAMART`. SP/schema mismatch, full doc + repro at `bugs/11_aggregate_report_datamart_schema_mismatch/findings.md`. | Open. |

Plus several observations not promoted to bugs (per LOOP rules):
- `sp_pertussis_case_datamart_postprocessing` step-2 (#OBS_CODED_PERTUSSIS_Case) logs row_count=0 despite producing 53 rows when invoked with `@debug='true'`. Same `@@ROWCOUNT`-after-IF pattern as bug 5a but in a different SP. Documented in coverage_pertussis_full_chain.md.
- `sp_sld_investigation_repeat_postprocessing` (bug #10 from yesterday) still blocks D_INVESTIGATION_REPEAT.
- `sp_ldf_mumps_datamart_postprocessing` doesn't populate LDF_MUMPS despite our 5 Mumps LDF answers flowing into LDF_DIMENSIONAL_DATA. Likely PHC_CD filter mismatch. Documented in coverage_ldf_mumps_foodborne.md.

## What remains empty (17 tables)

After tonight's work:

- **4 COVID extension datamarts** — `covid_contact_datamart`, `covid_lab_datamart`, `covid_lab_celr_datamart`, `covid_vaccination_datamart`. All need COVID-coded contact/lab/vaccination records linked to the COVID Investigation. Each is ~100 cols of authoring work.
- **4 legacy MasterETL-only** — `hep100`, `lab100`, `lab101`, `sr100`. Per `catalog/odse_unknown_tables.md`, these have no RTR writer. Expected to surface as legitimate diff findings against MasterETL.
- **3 condition-LDF tables without baseline metadata** — `ldf_bmird`, `ldf_hepatitis`, `ldf_mumps`. The LDF_DATAMART_TABLE_REF condition mapping points at codes that have zero entries in `nrt_odse_state_defined_field_metadata`. Cannot populate without seeding baseline metadata (out of scope).
- **3 *_ldf_group tables** — `organization_ldf_group`, `patient_ldf_group`, `provider_ldf_group`. Same metadata-gap issue at the Org/Pat/Prv business-object scope.
- **2 *_pam_ldf tables** — `tb_pam_ldf`, `var_pam_ldf`. Not in LDF_DATAMART_TABLE_REF at all.
- **`aggregate_report_datamart`** — blocked by bug #11 (this session).
- **`inv_summ_datamart`** — chicken-and-egg `WHERE @INV_SUMMARY_DATAMART_COUNT > 0` guard on the UPDATE path; no INSERT path appears to write the first row.

Realistic ceiling on fixture-authorable coverage without upstream RTR
fixes: probably 42-45%. The big remaining unlocks are gated by the
COVID extension SPs (need new fixtures) and the LDF/PAM metadata
seeding question.

## Files added this session

- `fixtures/30_sp_coverage/pertussis_investigation_full_chain.sql`
- `fixtures/30_sp_coverage/ldf_answers_mumps_foodborne.sql`
- `fixtures/30_sp_coverage/case_management_staging.sql`
- `fixtures/30_sp_coverage/summary_report_case.sql`
- `fixtures/30_sp_coverage/aggregate_report.sql`
- `fixtures/30_sp_coverage/zz_enrich_phase2_investigations.sql`
- `coverage/coverage_pertussis_full_chain.md`
- `coverage/coverage_ldf_mumps_foodborne.md`
- `bugs/11_aggregate_report_datamart_schema_mismatch/findings.md`

Plus orchestrator additions to `scripts/merge_and_verify.sh`:
- `sp_nrt_case_management_postprocessing` invocation in Step 9
- PHC_UIDS extended with new Phase-2 PHCs (22007000-22010000)

## Stop reason

Lock-out time approached + remaining headroom dominated by
upstream-RTR-blocked or out-of-scope tables. Last 1h budget reserved
for clean documentation refresh and SESSION_SUMMARY (this file).
