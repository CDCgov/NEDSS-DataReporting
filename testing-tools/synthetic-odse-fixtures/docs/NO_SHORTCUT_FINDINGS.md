# The NRT shortcut: why coverage read 90.5%, and why it is now ~80% faithfully

This file records a detour the build took and then had to undo. The intent was
always ODSE-only fixtures: author `NBS_ODSE` rows and let the real RTR pipeline
(CDC → Debezium → Kafka → kafka-connect → `nrt_*` → reporting-pipeline-service SPs)
derive RDB_MODERN. This is the one place that documents how that intent briefly
slipped, what it cost, and how faithful coverage was rebuilt. Everywhere else,
ODSE-only is the design.

## What happened

Running the full pipeline end-to-end needs CDC, Kafka, kafka-connect, and the
service standing up and draining on every iteration, a ~15-30 min loop. To move
faster, the build took a shortcut: hand-author the `nrt_*` staging rows directly
and run the postprocessing SPs by hand (`EXEC sp_*`), bypassing CDC entirely. That
cut the loop to ~5 minutes, but it made RDB_MODERN coverage an artifact of the
hand-written staging rather than of the real ODSE→RTR transform. It inflated
apparent coverage and confounded the RDB-vs-RDB_MODERN comparison the fixtures
exist to support.

The shortcut was removed: every `nrt_*` INSERT (50 files) and every manual `EXEC sp_*` (45 files
/ 97 EXECs) deleted, `merge_and_verify.sh` rewired to bring up the full stack and drain the
pipeline (no manual SP EXEC), and 20 strip-damaged Tier-3 fixtures repaired (empty `IF`/`TRY`
wrappers) so all parse clean. The fixtures have been ODSE-only since, and the clean pipeline
run completes end-to-end with no apply errors.

## The coverage numbers

| | with shortcut | real pipeline (ODSE-only) |
| --- | --- | --- |
| Overall column coverage | **90.5%** (4165/4633) | **14.0%** |
| Fully / Partial / Empty | 76 / 36 / 5 | 33 / 24 / 60 |

~84 percentage points of the apparent coverage were the shortcut, not pipeline output. Faithful
coverage was then rebuilt from the 14.0% floor to the ~80% range (≈78-81%; regenerate with
`scripts/coverage_summary.sh`) by fixing fixture fidelity, without reintroducing a shortcut.
The arc:

`14% → 34%` datamart-routing metadata · `→ 42%` investigation↔patient links unlock condition
datamarts · `→ ~72%` dedicated entities + std/hiv case-mgmt + d_investigation_repeat forms ·
`→ ~78%` summary_report_case/SR100 + hepatitis + tb · `→ ~80%` LDF, covid_vaccination, contact,
interview, obs-heavy lab/bmird.

Two classes of remaining gap, both documented in `../../bugs/`:
- Real pipeline bugs the shortcut had masked, fixed via TDD: lab key-gen race (#17),
  `LAB_TEST` record-status CHECK (#19), notification key-gen race (#26), followup-obs NPE (#18).
- Structurally out of reach for ODSE-only fixtures: seed-gated (#16 covid_lab LOINC, #22 LDF
  metadata), routine defects (#24 bmird multi-value cap, #25 dyn-datamart date/float), and
  out-of-bounds datamarts (var_datamart, covid_lab*, aggregate_report, f_var_pam, MasterETL-only).
  These bound the realistic fixtures-only ceiling at ~85-89%.

> The coverage figure varies slightly run-to-run. The service's batch processing is an intentional
> fail-fast defer-and-retry (bug #20, investigated, "fixed", then reverted as not-a-bug), so a batch
> that hits a residual poison (#25 dyn-datamart, #21 summary-case race) defers its co-batched
> entities. That is the source of the historical "flakiness", not bad fixture data.

## Where the 76 points went (decomposition)
- **Entity/dimension path WORKS faithfully:** D_PATIENT, D_PROVIDER, INVESTIGATION,
  LAB_TEST, MORBIDITY_REPORT, F_PAGE_CASE all populate from ODSE via the service's
  postprocessing SPs. The conversion mechanism is sound.
- **Condition-specific datamarts DON'T fire (biggest loss).** `nrt_investigation.rdb_table_name_list`
  was NULL for every investigation, so the service couldn't route investigations to
  `covid_case_datamart`/`tb_datamart`/`var_datamart`/`bmird_*`/`std_hiv_*` (each 100–300 cols
  = most of the column universe). The synthetic investigations lacked the page/condition→datamart
  routing metadata real NBS investigations carry. The shortcut masked this by running all ~40
  datamart SPs manually with hardcoded UID lists. The service DID run the routing-agnostic
  datamarts (case_lab, hepatitis, inv_summary, morbidity_report, dyn for STD/HEP).
- **Pure-`nrt` enrich fixtures** (e.g. `zz_bmird_strep_pneumo_datamart_enrich`) had **no ODSE
  backing at all**. They only ever hand-authored `nrt_*` rows, so they became no-ops; their
  coverage cannot be reproduced from ODSE without authoring full ODSE chains.
- **Value / Tier-2-link fidelity gaps:** e.g. the morb user comment needs the Tier-2 patient
  link to resolve `PATIENT_KEY` before the comment row inserts.

The two root causes that unblocked the bulk of the recovery are below; both are durable facts
about how ODSE-only fixtures must be authored, independent of the shortcut.

## Root cause #1: datamart routing. Coverage 14.0% to 34.4%

`sp_investigation_event` (run by the service per investigation) builds the event payload's
datamart routing from the investigation's **`nbs_case_answer`** rows joined
`nbs_question_uid → nbs_ui_metadata (nuim) → nbs_rdb_metadata (nrdbm)` to yield `rdb_table_nm`
per answer (routine 056, lines ~467-567). The service routes to those page-builder tables
(PostProcessingService.java:345-356, `pbCache` from `rdb_table_name_list`).

Empirically (TB PHC 22001000, full pipeline run): it has 186 ODSE `nbs_case_answer` rows; 215
join to `nbs_ui_metadata`, but most map to `nbs_rdb_metadata_uid = NULL` → only **2** distinct
tables resolve. Baked metadata is rich and present (nbs_ui_metadata 386 rows for INV_FORM_RVCT;
nbs_rdb_metadata 8092 rows), so the gap is NOT missing metadata: it is that the synthetic answers
didn't use the `nbs_question_uid`s that map through that metadata to datamart columns. The shortcut
had hidden this by hand-authoring resolved `nrt_page_case_answer` rows and force-running datamart SPs.

The exact end-to-end chain:

1. **`sp_investigation_event`** (routine 056) gathers every `nbs_case_answer` for the PHC with
   its resolved `rdb_table_nm`, but the join is **gated by the investigation's condition**:
   `nbs_srte.condition_code cc ON cc.condition_cd = phc.cd` AND
   `nuim.investigation_form_cd = cc.investigation_form_cd` (lines ~516-521). Answers on any
   other form fall into the UNION's second arm and get `rdb_table_nm = NULL` (line 540).
2. **`ProcessInvestigationDataUtil.java:459-468`** (the service) streams that answer array, takes
   `distinct` non-null `rdb_table_nm`, comma-joins, and sets `rdb_table_name_list`. *(So the list
   is computed in Java from the answers; no SP emits it.)*
3. **`PostProcessingService.java:351-356`** splits `rdb_table_name_list` into `pbCache` →
   `executeStoredProcForPageBuilder(tbl, uids)` populates each `D_INV_*` page-builder dimension.
4. **Condition datamarts** (COVID_CASE_DATAMART, STD_HIV_DATAMART, …) are a *separate* path:
   `sp_nrt_investigation_postprocessing` returns a DatamartData signal per PHC **iff the
   condition is mapped in `nrt_datamart_metadata`** (11065→Covid_Case_Datamart,
   10311→Std_Hiv_Datamart, etc.; 161 rows). The service then runs the mapped datamart SP.

Two mistakes in the first attempt, both fixed: (a) authored answers against
`PG_TB_LTBI_Investigation` while the TB PHC's condition (10220) maps to legacy `INV_FORM_RVCT`,
which has ZERO page-builder rdb metadata in this seed (an unroutable dead end); in this seed
`condition_code` routes only **11065 → PG_COVID-19_v1.1** and **10311 → PG_STD_Investigation**.
(b) targeted an arbitrary rich form instead of the condition's form, so the condition-gated join
never matched.

**Fix (fixtures only, no product change):** `scripts/gen_page_answers.sql` derives the form from
the act's condition via `condition_code` and emits one type-correct `nbs_case_answer` per
datamart-mapped question. Applied to the COVID + STD PHCs: resolvable `rdb_table_nm` went 0 → 26/27
each; `rdb_table_name_list` populated; the `D_INV_*` dimensions populated;
`sp_covid_case_datamart_postprocessing` / `sp_std_hiv_datamart_postprocessing` fired. Overall column
coverage **14.0% → 34.4%** from just these two investigations.

**Takeaway for ODSE-only authoring:** faithful datamart coverage requires synthetic page answers
authored against the real page-builder metadata graph (question_uid → ui_metadata → rdb_metadata →
datamart column) for the condition's own form, not arbitrary/partial question_uids.

## Root cause #2: condition datamarts need the patient link. 37.7% to 42.1%

The empty condition datamarts were NOT a routing problem. `ProcessDatamartData.java:113-115`
**drops any DatamartData whose `patientUid` is NULL**, and the `*_investigation_full_chain.sql`
fixtures created the PHC but never a patient *subject* link. So `sp_investigation_event` left
`nrt_investigation.patient_id` NULL and every condition datamart was silently skipped.

Fix (`zz_investigation_patient_links.sql`): add a `SubjOfPHC` participation (act=PHC,
subject=foundation patient 20000000, class PSN/CASE) for all 8 investigation subjects. Result:
`patient_id` resolves, DatamartData `patient_uid` becomes non-null, and the service fires the condition
datamart SP that `nrt_datamart_metadata` maps for each condition. Newly populating:
**COVID_CASE_DATAMART, STD_HIV_DATAMART, D_TB_PAM, HEPATITIS_DATAMART**. This is the same link
fidelity the morb-comment `PATIENT_KEY` gap needed: the Tier-2 investigation-to-patient link.

### Remaining condition-datamart gaps (triaged, lower ROI)
- **VAR_DATAMART = 0**: `sp_var_datamart_postprocessing` (lines 129-132) inner-joins
  `NRT_SRTE_condition_code cc ON cc.condition_cd='10030' AND cc.PORT_REQ_IND_CD='T'`. Our seed's
  SRTE row for Varicella (10030) does not satisfy `PORT_REQ_IND_CD='T'`, an SRTE-reference-data
  flag, not an investigation-fixture gap. Fix = seed/patch that SRTE flag (verify against real NBS).
- **F_TB_PAM = 0 (while D_TB_PAM = 1)**: `sp_f_tb_pam_postprocessing` gates on
  `investigation_form_cd='INV_FORM_RVCT'` (our TB PHC matches), but the TB *fact* table needs
  prerequisite dimension keys / measures (treatment, dispositions) the generic fixture lacks.
  The TB *dimension* populates; the fact needs richer TB-specific source data.
