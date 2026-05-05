# Coverage: lab_inv (Tier 2 — `LabReport` edge)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: `21001000 - 21001999` (Tier 2, second agent)
- Foundation dependencies (read-only):
  - `@dbo_Act_lab_uid = 20000120` (foundation Lab Report Order observation)
  - `@dbo_Act_investigation_uid = 20000100` (foundation Investigation)
- Tier 1 dependencies (read-only):
  - `@dbo_Act_lab_v2_order_uid = 20070010` (v2 Lab Order; Lab Tier 1)
  - `@dbo_Act_investigation_v2_uid = 20050010` (v2 Investigation; Investigation Tier 1)
- Pre-fixture infrastructure SPs (run by orchestrator per Merge contract step 2):
  - `RDB_DATE` populated via recursive CTE (sp_get_date_dim is buggy — see
    `coverage_inv_notification.md` INFRA_GAP for the well-documented
    workaround SQL).
  - `EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'`.

## Apply result

**Clean apply on first attempt** — no iterations.

- Foundation: applied clean.
- Patient / Provider / Organization / Investigation / Lab Tier 1: all applied clean.
- Patient chain (`sp_patient_event` + `sp_nrt_patient_postprocessing`): COMPLETE; 3 D_PATIENT rows.
- Provider chain (`sp_provider_event` + `sp_nrt_provider_postprocessing`): COMPLETE; 2 d_provider rows.
- Organization chain (`sp_organization_event` + `sp_nrt_organization_postprocessing`): COMPLETE; 2 d_organization rows.
- Investigation chain (`sp_investigation_event` + `sp_nrt_investigation_postprocessing`): COMPLETE; INVESTIGATION_KEY 3 (foundation, CASE_UID=20000100), 4 (v2, CASE_UID=20050010).
- Lab chain (`sp_observation_event` + `sp_d_lab_test_postprocessing` + `sp_d_labtest_result_postprocessing`): COMPLETE pre-edge with INVESTIGATION_KEY = sentinel 1.
- Edge fixture (`fixtures/20_links/lab_inv.sql`): applied clean. 2 act_relationship rows + 2 nrt_observation UPDATEs + tail-EXEC re-runs of both Lab postprocessing SPs.
- Lab postprocessing re-runs (post-edge): COMPLETE — `SP_COMPLETE` row in `dbo.job_flow_log` for both `sp_d_lab_test_postprocessing` and `sp_d_labtest_result_postprocessing`. INVESTIGATION_KEY now resolves to real keys.

## Edges authored

| # | source_act_uid | target_act_uid | type_cd | source_class_cd | target_class_cd | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 20000120 (foundation Lab Order) | 20000100 (foundation Inv) | `LabReport` | `OBS` | `CASE` | foundation→foundation pair |
| 2 | 20070010 (v2 Lab Order) | 20050010 (v2 Inv) | `LabReport` | `OBS` | `CASE` | v2→v2 pair (Order parent only — Result/C_Order/C_Result children are tied via Lab-internal `type_cd='COMP'` rows authored in Lab Tier 1) |

Total: 2 rows in `nbs_odse.dbo.act_relationship`.

`type_cd='LabReport'` is verified present in baseline `NBS_SRTE.dbo.code_value_general` for `code_set_nm='AR_TYPE'` (Phase B catalog row in `catalog/edge_types.md`). RTR's filters at `055-sp_observation_event-001.sql:116-117` and `:430-431` filter on `type_cd IN ('MorbReport','LabReport') AND target_class_cd='CASE'` (and `source_class_cd='OBS'` for the second site) — both filters match these rows.

In addition, the fixture issues 2 staging UPDATEs against `RDB_MODERN.dbo.nrt_observation` to mirror the CDC pipeline's effect on `associated_phc_uids`:

| observation_uid | associated_phc_uids before | associated_phc_uids after |
| --- | --- | --- |
| 20000120 | NULL | `20000100` |
| 20070010 | NULL | `20050010` |
| 20070011 | NULL | `20050010` |

The 20070020 / 20070021 followup observations remain NULL — those C_Order/C_Result rows feed the `LAB_RPT_USER_COMMENT` path (driven by Order's `followup_observation_uid` CSV), not LAB_TEST_RESULT, so their `associated_phc_uids` is not consumed by the postprocessing SPs.

No new entity / Person / Act / Public_health_case / Observation rows authored (forbidden in Tier 2). No SRTE writes. No foundation/Tier 1 modifications. No INSERTs into RDB_MODERN dim/fact tables. The fixture's tail-EXEC re-runs the two Lab postprocessing SPs against the wired graph; those SPs write/update the dim rows.

## SPs verified

- `dbo.sp_d_lab_test_postprocessing @obs_ids = N'20000120,20070010,20070011', @debug = 0` — exit code: 0; `dbo.job_flow_log` shows `SP_COMPLETE`. Re-write of LAB_TEST + LAB_RPT_USER_COMMENT (no INVESTIGATION_KEY consumed by this SP, but it re-runs as part of the Lab chain for completeness).
- `dbo.sp_d_labtest_result_postprocessing @pLabResultList = N'20000120,20070010,20070011', @pDebug = 0` — exit code: 0; `dbo.job_flow_log` shows `SP_COMPLETE`. LAB_TEST_RESULT.INVESTIGATION_KEY now resolves to real keys 3 (foundation Inv) and 4 (v2 Inv) via the staging-mirrored `associated_phc_uids` -> `STRING_SPLIT` -> JOIN to `dbo.investigation.case_uid`. Also emits the Case_Lab_Datamart projection at the bottom of the SP body (lines 1856-1932), which now returns 2 rows (was 0 pre-edge — the `INVESTIGATION_KEY <> 1` filter at line 1876, 1895, 1914 excluded all sentinel-1 rows).

## Coverage unlocked

### LAB_TEST_RESULT — INVESTIGATION_KEY column

Tier 1 baseline (per `coverage_lab.md` LINK_REQUIRED for `INVESTIGATION_KEY`): **sentinel 1** for all 3 LAB_TEST_RESULT rows (foundation Lab + v2 Order + v2 Result).

Post-edge: **real keys** for all 3 rows.

| LAB_TEST_UID | LAB_TEST_KEY | Before edge | After edge | Notes |
| --- | --- | --- | --- | --- |
| 20000120 (foundation Lab) | 101 | INVESTIGATION_KEY=1 (sentinel) | INVESTIGATION_KEY=**3** (foundation Inv, CASE_UID=20000100) | Resolved via `nrt_observation.associated_phc_uids = '20000100'` -> JOIN `dbo.investigation` ON `case_uid=20000100`. |
| 20070010 (v2 Lab Order) | 102 | INVESTIGATION_KEY=1 (sentinel) | INVESTIGATION_KEY=**4** (v2 Inv, CASE_UID=20050010) | Resolved via `nrt_observation.associated_phc_uids = '20050010'` -> JOIN `dbo.investigation` ON `case_uid=20050010`. |
| 20070011 (v2 Lab Result child) | 103 | INVESTIGATION_KEY=1 (sentinel) | INVESTIGATION_KEY=**4** (v2 Inv) | Resolved through the same `nrt_observation.associated_phc_uids = '20050010'` (set on the Result row's nrt_observation entry). The postprocessing SP's path uses `tst.lab_test_uid` to look up `no2.associated_phc_uids` in `#TMP_lab_test_resultInit`. |

**One column flipped from sentinel 1 to real keys for all 3 LAB_TEST_RESULT rows.**

### Cross-FK summary on LAB_TEST_RESULT (full FK columns)

For reference, the full LAB_TEST_RESULT FK column status post-merged-fixture sequence:

| Column | foundation row (UID 20000120) | v2 Order (UID 20070010) | v2 Result (UID 20070011) | Resolution path |
| --- | --- | --- | --- | --- |
| PATIENT_KEY | 3 (real, foundation Patient) | 3 (real) | 3 (real) | Resolved at Tier 1 by Patient chain (D_PATIENT) — independent of this edge. |
| ORDERING_PROVIDER_KEY | 1 (sentinel) | **12** (real, v2 Provider) | 12 (real) | Resolved at Tier 1 by Provider chain — but only for v2 Lab. Foundation Lab's `nrt_observation.ordering_person_id` is NULL by Tier 1 design (foundation = sparse / null-propagation variant), so its sentinel 1 is by design, not LINK_REQUIRED. |
| REPORTING_LAB_KEY | 1 (sentinel; foundation null-path) | **7** (real, foundation Org) | 7 (real) | Resolved at Tier 1 by Organization chain. |
| ORDERING_ORG_KEY | 1 (sentinel; foundation null-path) | **7** (real) | 7 (real) | Same as REPORTING_LAB_KEY. |
| PERFORMING_LAB_KEY | 1 (sentinel; foundation null-path) | **7** (real) | 7 (real) | Same. |
| COPY_TO_PROVIDER_KEY | 1 (sentinel; foundation null-path) | **12** (real) | 12 (real) | Resolved at Tier 1 by Provider chain. |
| LAB_TEST_TECHNICIAN_KEY | 1 (sentinel; foundation null-path) | **12** (real) | 12 (real) | Same. |
| SPECIMEN_COLLECTOR_KEY | 1 (sentinel; foundation null-path) | **12** (real) | 12 (real) | Same. |
| CONDITION_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | **NOT resolved by this edge.** SP join is `nrt_observation.prog_area_cd = condition.program_area_cd AND condition.condition_cd IS NULL`. Lab Tier 1 sets `prog_area_cd='STD'`; CONDITION dim has rows for `program_area_cd='HEP'` only. This is an OUT_OF_SCOPE finding documented below — orthogonal to the Lab→Inv edge. |
| **INVESTIGATION_KEY** | 1 → **3** | 1 → **4** | 1 → **4** | **THIS EDGE.** |
| MORB_RPT_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | **NOT resolved by this edge.** Awaits `act_relationship_morb_inv` Tier 2 agent (Lab→Morb back-prop via `nrt_observation.report_observation_uid` -> Morbidity_Report).  See LINK_REQUIRED below. |
| LDF_GROUP_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | OUT_OF_SCOPE. `dbo.ldf_group` is empty in baseline; populated by LDF Tier 3 work. |
| LAB_RPT_DT_KEY | 5935 (real, 2026-04-01) | 5938 (real, 2026-04-04) | 5938 (real) | Resolved at Tier 1 by `RDB_DATE` infrastructure SP. |

### sp_observation_event JSON projection (`associated_phc_uids` branch, lines 105-119)

Before edge: empty (no act_relationship matched the filter).
After edge: contains the wired investigation UID for each Lab Order — visible by re-running `sp_observation_event @obs_id_list = N'20000120,20070010'` post-edge (not invoked in fixture verification since it's a no-op for staging — STRATEGY.md "verification recipe" notes the event SP is not invoked in fixture chains).

### Investigation event SP `investigation_observation_ids` branch (per `coverage_investigation.md` LINK_REQUIRED #14)

`coverage_investigation.md` line 197 names this edge as required for the `investigation_observation_ids` JSON branch (event SP lines 378-407). **Resolved by this edge.** A re-run of `sp_investigation_event @phc_id_list = N'20000100,20050010'` post-edge would surface the wired labs in that JSON branch. We do not re-run Investigation event SP in the fixture's tail-EXEC because the only persistent side-effect of the event SP is the JSON projection (no staging writes — STRATEGY.md "verification recipe"); the dimensional impact via `nrt_investigation` is already captured in Investigation Tier 1's chain.

## Coverage still LINK_REQUIRED on LAB_TEST_RESULT

These FK columns remain at sentinel 1 after this edge — they depend on other Tier 2 agents' edges or Tier 3 work:

| Column | Sentinel-1 reason | Waiting on |
| --- | --- | --- |
| `MORB_RPT_KEY` | SP at lines 117-122 reads `morb_event.PATIENT_KEY/Condition_Key/Investigation_Key/MORB_RPT_SRC_ORG_KEY` from `Morbidity_Report_Event` joined via `nrt_observation.report_observation_uid -> Morbidity_Report.morb_rpt_uid`. The `report_observation_uid` on Lab's nrt_observation rows in baseline is the lab's own `observation_uid` (not a morbidity report). This sentinel persists unless either (a) Lab Tier 1's `report_observation_uid` is re-pointed at a Morbidity Report (Tier 1 amendment), or (b) a separate `act_relationship_lab_morb` edge exists — but in NBS schema there is no such direct relationship; Lab→Morbidity backprop is via the `report_observation_uid` linkage on `nrt_observation`, not via act_relationship. **OUT_OF_SCOPE for this edge** — flagged here as a partial-resolution path requiring Lab Tier 1 amendment, not a Tier 2 edge. |
| `LDF_GROUP_KEY` | `dbo.ldf_group` is empty in baseline. Populated by LDF Tier 3 work (per `coverage_lab.md` BASELINE_QUIRK and Phase B's "Tier 3 LDF coverage" guidance). |
| `CONDITION_KEY` | SP join is `prog_area_cd = program_area_cd AND condition_cd IS NULL`. Lab's `prog_area_cd='STD'` does not match the seeded HEP condition rows. This would resolve only if (a) the Lab Tier 1 fixture used `prog_area_cd='HEP'`, or (b) `sp_nrt_srte_condition_code_postprocessing` is run with an STD condition_cd (none in baseline that matches `condition_cd IS NULL` filter). **OUT_OF_SCOPE** — Tier 1 design choice. |

Note: `coverage_lab.md` LINK_REQUIRED #2 lists 13 sentinel-1 keys; this edge resolves **1** of them (INVESTIGATION_KEY for all 3 rows). The other 12 are status:

| Tier 1 LINK_REQUIRED key | Status post this Tier 2 edge | Waiting on |
| --- | --- | --- |
| PATIENT_KEY | **resolved** (real key 3) | Patient Tier 1 chain (already run) |
| INVESTIGATION_KEY | **resolved** (real keys 3 / 4) | **THIS EDGE.** |
| CONDITION_KEY | unresolved | Out of scope (Tier 1 design — `prog_area_cd='STD'` doesn't match HEP condition rows). |
| REPORTING_LAB_KEY | **resolved** for v2 (real key 7) | Organization Tier 1 chain |
| ORDERING_PROVIDER_KEY | **resolved** for v2 (real key 12) | Provider Tier 1 chain |
| ORDERING_ORG_KEY | **resolved** for v2 (real key 7) | Organization Tier 1 chain |
| COPY_TO_PROVIDER_KEY | **resolved** for v2 (real key 12) | Provider Tier 1 chain |
| LAB_TEST_TECHNICIAN_KEY | **resolved** for v2 (real key 12) | Provider Tier 1 chain |
| SPECIMEN_COLLECTOR_KEY | **resolved** for v2 (real key 12) | Provider Tier 1 chain |
| PERFORMING_LAB_KEY | **resolved** for v2 (real key 7) | Organization Tier 1 chain |
| MORB_RPT_KEY | unresolved | Out of scope (no NBS schema path from Lab to a separate Morbidity Report at the act_relationship level — relies on Tier 1 `report_observation_uid` design). |
| LDF_GROUP_KEY | unresolved | Tier 3 (LDF group seed) |
| LAB_RPT_DT_KEY | **resolved** (real keys 5935 / 5938) | RDB_DATE infrastructure SP |

The foundation Lab variant (LAB_TEST_UID=20000120) intentionally exhibits the sentinel-1 / NULL-propagation path for ORDERING_PROVIDER_KEY, REPORTING_LAB_KEY, ORDERING_ORG_KEY, COPY_TO_PROVIDER_KEY, LAB_TEST_TECHNICIAN_KEY, SPECIMEN_COLLECTOR_KEY, PERFORMING_LAB_KEY by Lab Tier 1's deliberate "foundation = sparse" design. Those sentinel-1 values on the foundation row are NOT LINK_REQUIRED — they are the SP's COALESCE-to-1 path.

## Columns deliberately not exercised by this edge

These belong to other Tier 2 agents:

- LAB_TEST.RESULT_INTERPRETER_NAME (resolved by Provider Tier 1 chain — already resolved at the merge orchestrator level for v2; foundation null-path remains).
- D_PATIENT.* / d_organization.* / d_provider.* — Tier 1 chains.
- The various Lab datamart SPs (`sp_lab100_datamart_postprocessing`, `sp_lab101_datamart_postprocessing`, `sp_case_lab_datamart_postprocessing`, `sp_covid_lab_celr_datamart_postprocessing`, `sp_covid_lab_datamart_postprocessing`, `sp_hepatitis_datamart_postprocessing`) consume LAB_TEST_RESULT.INVESTIGATION_KEY (filter at line 1876 / 1895 / 1914 of `017-sp_d_labtest_result_postprocessing-001.sql` is `INVESTIGATION_KEY <> 1`). With this edge wired, the Case_Lab_Datamart projection at the bottom of the result-postprocessing SP now returns 2 rows (foundation Inv 20000100 + v2 Inv 20050010). Datamart SPs run at Merge contract step 9 (after all Tier 2 / Tier 3); they are out-of-scope here.

## Gaps reported

### INFRA_GAP

- Same `sp_get_date_dim` bug as `coverage_inv_notification.md` documents (RTR baseline 6.0.18.1 references non-existent `dbo.rdb_date_temp` and has a `#temp_date` scope bug). Verification used the recursive-CTE workaround documented in inv_notification's coverage. No new infra gap from this edge.

### SRTE_GAP

None for this edge. `type_cd='LabReport'` is verified present in baseline `NBS_SRTE.dbo.code_value_general` for `code_set_nm='AR_TYPE'` (Phase B catalog).

### FOUNDATION_GAP

None. Foundation provides `@dbo_Act_lab_uid (20000120)` (Class `OBS`, mood `EVN`) and `@dbo_Act_investigation_uid (20000100)` (Class `CASE`, mood `EVN`), satisfying the SP's class-cd filters. Tier 1 Lab provides v2 Lab Order (20070010); Tier 1 Investigation provides v2 Investigation (20050010).

### OUT_OF_SCOPE

- **`LAB_TEST_RESULT.CONDITION_KEY`** — sentinel 1 persists post-edge. The SP at line 333-334 joins `condition.program_area_cd = nrt_observation.prog_area_cd AND condition.condition_cd IS NULL`. Lab Tier 1 sets `prog_area_cd='STD'`; the CONDITION dim has rows for `program_area_cd='HEP'` only (seeded by `sp_nrt_srte_condition_code_postprocessing @condition_cd_list='10110'`). To resolve, either (a) Lab Tier 1 amendment to use `prog_area_cd='HEP'` (would conflict with the existing Tier 1 design — the lab is an STD-program-area observation with a Hepatitis-A LOINC code), or (b) seed an `STD` program-area row in CONDITION via additional `sp_nrt_srte_condition_code_postprocessing` invocations. Neither is a Tier 2 edge concern.

- **`LAB_TEST_RESULT.MORB_RPT_KEY`** — sentinel 1 persists. The SP path at lines 126-131 joins `nrt_observation.report_observation_uid -> Morbidity_Report.morb_rpt_uid`. Lab Tier 1 sets `report_observation_uid = lab_test_uid` (self-reference for the Order; child for Result), not a Morbidity Report UID. Resolving this would require either (a) Lab Tier 1 amendment to repurpose `report_observation_uid`, or (b) a new fixture variant where the Lab Order's `report_observation_uid` points at a Morbidity Report observation — neither is a Tier 2 edge. NBS schema does not have a direct Lab->Morb act_relationship; the linkage is via `report_observation_uid` on nrt_observation.

- **`LAB_TEST_RESULT.LDF_GROUP_KEY`** — sentinel 1 persists. `dbo.ldf_group` is empty in baseline; populated by Tier 3 LDF coverage work.

- **`LAB_RESULT_VAL_LARGE_TXT_KEY`** — column exists but no SP writes it (per `coverage_lab.md` OUT_OF_SCOPE).

- **`TEST_RESULT_GROUPING.RDB_LAST_REFRESH_TIME`** — SP explicitly NULLs this (per `coverage_lab.md` OUT_OF_SCOPE).

- **Datamart SPs** (`sp_case_lab_datamart_postprocessing`, `sp_lab100_datamart_postprocessing`, etc.) — out of scope per Merge contract step 9.

## Decisions made under prompt ambiguity

- **No UIDs allocated from block 21001000-21001999.** `dbo.act_relationship`'s primary key is the composite (source_act_uid, target_act_uid, type_cd). Both edges' source/target UIDs are foundation/Tier 1 references; no surrogate UID needed. The block is reserved (registry updated) in case a future amendment needs surrogate UIDs.

- **`type_cd='LabReport'`** chosen for both edges, matching NBS upstream convention and the catalog's Phase B finding. RTR's filter at `055-sp_observation_event-001.sql:116` is on `type_cd IN ('MorbReport','LabReport') AND target_class_cd='CASE'`. The catalog disambiguation note states: "the same underlying type_cd is used regardless of obs domain because RTR disambiguates lab vs. morbidity by joining the source observation's `cd` and `obs_domain_cd_st_1`, not by AR type." We use `'LabReport'` here for the foundation+v2 Lab Orders; the Morb Tier 2 agent will use `'MorbReport'` for foundation+v2 Morb Orders. The downstream postprocessing SP `017-sp_d_labtest_result_postprocessing-001.sql` reads `nrt_observation.associated_phc_uids` (a CSV produced by upstream `sp_observation_event`), not the act_relationship table directly — but the upstream JSON projection that drives `associated_phc_uids` does filter on `type_cd IN ('MorbReport','LabReport')`. So `'LabReport'` is correct.

- **UPDATE against `dbo.nrt_observation` permitted.** The fixture issues 2 `UPDATE` statements against `RDB_MODERN.dbo.nrt_observation.associated_phc_uids` to mirror what the CDC pipeline (sp_observation_event -> Debezium -> Kafka -> kafka-connect JDBC sink) would produce after the act_relationship is wired. STRATEGY.md "RTR transformation chain (verification recipe)" calls out that fixture authors hand-write `nrt_<entity>` rows; the Tier 2 contract forbids INSERTs into RDB_MODERN dim/fact tables (D_PATIENT, INVESTIGATION, NOTIFICATION_EVENT) but does not forbid touching staging tables (`nrt_*`). Without the staging mirror, the postprocessing SP at `017-...:117` would still read NULL `associated_phc_uids` and INVESTIGATION_KEY would persist at sentinel 1 — defeating the entire point of the edge. This is the Tier-2-equivalent of "wiring": the act_relationship in NBS_ODSE plus the staging mirror that CDC would have produced.

- **Updated `associated_phc_uids` on the v2 Result row (20070011) too**, not just the Order parent. The postprocessing SP at lines 117 + 343-346 reads from `no2.associated_phc_uids` keyed by `tst.lab_test_uid` — for a Result row, `tst.lab_test_uid` is the Result's own UID (20070011), so without setting `associated_phc_uids` on the Result's nrt_observation, INVESTIGATION_KEY on its LAB_TEST_RESULT row would still be 1. Verified empirically: the v2 Result LAB_TEST_RESULT row (LAB_TEST_KEY=103, LAB_TEST_UID=20070011) flipped 1 -> 4 with this update.

- **C_Order/C_Result not updated.** Their nrt_observation rows have `associated_phc_uids` NULL post-fixture. They're not in `@obs_ids` for the postprocessing SPs (per Lab Tier 1's deliberate exclusion — they fail the `obs_domain_cd_st_1 IN (...)` filter at SP line 218-219), so their `associated_phc_uids` is never read by LAB_TEST_RESULT computation. They feed the LAB_RPT_USER_COMMENT path via the Order's `followup_observation_uid` CSV.

- **No second `LabReport` edge from foundation Lab to v2 Inv (20000120 -> 20050010) or v2 Lab to foundation Inv.** The prompt specifies "Two pairs (foundation→foundation + v2→v2)" exactly; we do not author additional cross-pairings.

- **Did NOT author edges for the v2 Result observation (20070011) -> Investigation.** The per-edge prompt explicitly notes "The cross-subject edge wires the **Order parent** (20070010) to the Investigation. The Result/C_Order/C_Result children are tied to the Order via Lab-internal act_relationships of `type_cd='COMP'`; they don't need their own cross-subject edges." This matches NBS convention — the Lab Order is the act with the cross-subject relationship; results inherit by being COMP-children of the Order.

- **Did NOT re-run `sp_observation_event` in the tail-EXEC.** STRATEGY.md "RTR transformation chain" Note: "The event SP (`sp_<entity>_event`) is **not invoked** in fixture verification — it's a no-op for our purposes since its only side effect is the JSON-emit query." Re-running `sp_observation_event` would not affect the Lab postprocessing chain; the only effect would be re-emitting the JSON projection (which we already verified manually shows the wired investigation in the `associated_phc_uids` branch). The staging UPDATE we do in the fixture is the CDC-equivalent.

- **Did NOT re-run `sp_investigation_event` either.** Same rationale — no persistent side effect on dimensional output. `coverage_investigation.md` LINK_REQUIRED #14 names this edge as required for the `investigation_observation_ids` JSON branch, which is satisfied by the act_relationship existing — but the JSON projection itself is consumed by downstream Datamart SPs (Merge contract step 9) and is not measured by the LAB_TEST_RESULT-focused coverage of this Tier 2 agent.

## Verification recipe (reproducible)

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting
docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure (Merge contract step 2). RDB_DATE via recursive CTE
# (sp_get_date_dim has the documented INFRA_GAP).
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SET NOCOUNT ON;
      WITH dates AS (
        SELECT CAST('2020-01-01' AS DATE) AS dt
        UNION ALL
        SELECT DATEADD(day, 1, dt) FROM dates WHERE dt < '2030-12-31'
      )
      INSERT INTO dbo.RDB_DATE (DATE_KEY, DATE_MM_DD_YYYY)
      SELECT DATEDIFF(day, '2010-01-01', dt) + 1, dt FROM dates
      OPTION (MAXRECURSION 0);"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'"

# Foundation + relevant Tier 1
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i .../fixtures/00_foundation/00_foundation.sql
for f in patient provider organization investigation lab; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i .../fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains in dependency order
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_organization_event @org_id_list = N'20000020,20030010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_organization_postprocessing @id_list = N'20000020,20030010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010,20020020'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010,20020020', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_observation_event @obs_id_list = N'20000120,20070010,20070011'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_d_lab_test_postprocessing @obs_ids = N'20000120,20070010,20070011', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_d_labtest_result_postprocessing @pLabResultList = N'20000120,20070010,20070011', @pDebug = 0"

# Pre-edge state
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -d RDB_MODERN \
  -Q "SELECT LAB_TEST_UID, INVESTIGATION_KEY FROM dbo.LAB_TEST_RESULT ORDER BY LAB_TEST_UID;"
# Expected: all rows show INVESTIGATION_KEY=1 (sentinel)

# Apply edge fixture (its tail-EXEC re-runs the Lab postprocessing chain)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i .../fixtures/20_links/lab_inv.sql

# Post-edge state
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -d RDB_MODERN \
  -Q "SELECT LAB_TEST_UID, INVESTIGATION_KEY FROM dbo.LAB_TEST_RESULT ORDER BY LAB_TEST_UID;"
# Expected:
#   20000120 -> 3 (foundation Inv key)
#   20070010 -> 4 (v2 Inv key)
#   20070011 -> 4 (v2 Inv key)
```

## Confirmation

All three deliverables exist:

- ✓ `fixtures/20_links/lab_inv.sql` (2 act_relationship rows + 2 nrt_observation UPDATEs + 2 post-edge SP re-runs).
- ✓ `coverage/coverage_lab_inv.md` (this file).
- ✓ `catalog/uid_ranges.md` updated with Tier 2 — `LabReport` edge entry (block 21001000 - 21001999).
