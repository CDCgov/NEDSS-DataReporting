# No-NRT-shortcut conversion — findings (branch `aw/remove-nrt-shortcut`)

## What was done
Removed all CDC-bypass shortcuts from the comparison fixtures and ran the **real**
pipeline (ODSE → SQL Server CDC → Debezium → Kafka → kafka-connect sink → `nrt_*` →
reporting-pipeline-service runs `sp_*_event` + postprocessing + datamart SPs):
- Removed every `nrt_*` INSERT (50 files) and every manual `EXEC sp_*` (45 files / 97 EXECs).
- Rewired `merge_and_verify.sh` to bring up the full stack, apply ODSE fixtures tier-by-tier,
  and drain the pipeline (no manual SP EXEC); hardened `sql_i`.
- Repaired 20 strip-damaged Tier-3 fixtures (empty `IF`/`TRY` wrappers) — all parse-clean.
- The clean pipeline run completes end-to-end with **no apply errors**.

## STATUS UPDATE (recovery in progress): 14.0% → **42.1%** faithfully, no shortcut

Faithful coverage has been recovered from the 14.0% no-shortcut floor to **42.1%** via two
fixture-only fixes (see the two "RESOLVED" sections at the bottom). Progression:
`14.0% → 34.4%` (datamart routing) `→ 37.7%` (all routable subjects) `→ 42.1%` (patient link
unlocks condition datamarts). No product/liquibase-routine changes. Remaining gaps documented
inline (VAR_DATAMART / F_TB_PAM still empty; pure-`nrt` enrich fixtures = P2).

## Original headline result: coverage 90.5% → **14.0%**

| | shortcut (committed baseline) | real pipeline (no shortcut) |
| --- | --- | --- |
| Overall column coverage | **90.5%** (4165/4633) | **14.0%** |
| Fully / Partial / Empty | 76 / 36 / 5 | 33 / 24 / 60 |

**~84 percentage points of the prior coverage were an artifact of the hand-authored
`nrt_*`/`EXEC` shortcut, not produced by the real ODSE→CDC→RTR pipeline from the same
ODSE fixtures.** This quantifies the quality risk raised earlier (the shortcut both
inflated RTR coverage and confounded the RDB-vs-RDB_MODERN comparison).

## Where the coverage went (decomposition)
- **Entity/dimension path WORKS faithfully:** D_PATIENT, D_PROVIDER, INVESTIGATION,
  LAB_TEST, MORBIDITY_REPORT, F_PAGE_CASE all populate from ODSE via the service's
  postprocessing SPs. The conversion mechanism is sound.
- **Condition-specific datamarts DON'T fire (biggest loss).** `nrt_investigation.rdb_table_name_list`
  is NULL for every investigation, so the service can't route investigations to
  `covid_case_datamart`/`tb_datamart`/`var_datamart`/`bmird_*`/`std_hiv_*` (each 100–300 cols
  = most of the column universe). The synthetic investigations lack the page/condition→datamart
  routing metadata real NBS investigations carry. The old merge masked this by running all ~40
  datamart SPs manually with hardcoded UID lists. The service DID run the routing-agnostic
  datamarts (case_lab, hepatitis, inv_summary, morbidity_report, dyn for STD/HEP).
- **Pure-`nrt` enrich fixtures** (e.g. `zz_bmird_strep_pneumo_datamart_enrich`) had **no ODSE
  backing at all** — they only ever hand-authored `nrt_*` rows. They are now no-ops; their
  coverage cannot be reproduced from ODSE without authoring full ODSE chains.
- **Value / Tier-2-link fidelity gaps:** e.g. the morb user comment needs the Tier-2 patient
  link to resolve `PATIENT_KEY` before the comment row inserts.

## What faithful coverage recovery requires (NOT done — scoping for decision)
1. **Datamart routing:** make synthetic investigations carry the page/condition metadata so the
   service derives `rdb_table_name_list` and routes to condition datamarts (investigate the
   `NBS_page`/`Page_cond_mapping`/page-builder path), OR accept datamarts need explicit invocation.
2. **Author real ODSE chains** for the pure-`nrt` enrich fixtures (biggest manual effort).
3. **Resolve Tier-2 link timing/fidelity** (patient↔morb, etc.).
4. Remaining 2nd-class shortcuts: ~several fixtures still seed `RDB_MODERN` dims directly +
   retained `nrt_*` UPDATE statements.

## Bottom line
The faithful, pipeline-produced coverage of the current ODSE fixtures is ~14%. The 90.5%
figure was overwhelmingly shortcut-driven. Recovering faithful coverage is a substantial
fixture-fidelity project (chiefly: datamart routing metadata + real ODSE chains), distinct
from the mechanical shortcut removal (which is complete on this branch).

## P1 datamart-routing — root cause (deeper than expected)

Traced the routing: `sp_investigation_event` (run by the service per investigation) builds
the event payload's datamart routing from the investigation's **`nbs_case_answer`** rows
joined `nbs_question_uid → nbs_ui_metadata (nuim) → nbs_rdb_metadata (nrdbm)` to yield
`rdb_table_nm` per answer (routine 056, lines ~467-567). The service routes to those
page-builder tables (PostProcessingService.java:345-356, `pbCache` from `rdb_table_name_list`).

Empirical (TB PHC 22001000, full pipeline run):
- It HAS 186 ODSE `nbs_case_answer` rows; 215 join to `nbs_ui_metadata`.
- BUT most map to `nbs_rdb_metadata_uid = NULL` → `rdb_table_nm = NULL`. Only **2** distinct
  tables resolve (`D_INV_CLINICAL`, `D_INV_LAB_FINDING`).
- The **TB case datamart is never reached** — `nrt_investigation.rdb_table_name_list` is NULL,
  and the service ran only the routing-agnostic / HEP/STD datamarts (whose forms are in
  `v_nrt_nbs_page`), not TB/COVID/VAR/BMIRD.
- Baked metadata is rich and present (nbs_ui_metadata 386 rows for INV_FORM_RVCT;
  nbs_rdb_metadata 8092 rows) — so the gap is NOT missing metadata, it's that the synthetic
  answers don't use the `nbs_question_uid`s that map through that metadata to datamart columns.

**Conclusion:** faithful datamart coverage requires the synthetic page answers to be authored
against the real page-builder metadata graph (question_uid → ui_metadata → rdb_metadata →
datamart column), not arbitrary/partial question_uids. The shortcut hid this by hand-authoring
resolved `nrt_page_case_answer` rows and force-running datamart SPs.

Tight-loop aid added: `docker-compose.override.yaml` (untracked) sets FIXED_DELAY_ID=2000 /
FIXED_DELAY_DM=3000 on the service so the CDC→nrt→SP drain completes in seconds for iteration.

## P1 — RESOLVED. Coverage 14.0% → 34.4% (faithful, no shortcut)

The routing mechanism is fully faithful; the gap was purely the synthetic answers. The exact
end-to-end chain:

1. **`sp_investigation_event`** (routine 056) gathers every `nbs_case_answer` for the PHC with
   its resolved `rdb_table_nm`, but the join is **gated by the investigation's condition**:
   `nbs_srte.condition_code cc ON cc.condition_cd = phc.cd` AND
   `nuim.investigation_form_cd = cc.investigation_form_cd` (lines ~516-521). Answers on any
   other form fall into the UNION's second arm and get `rdb_table_nm = NULL` (line 540).
2. **`ProcessInvestigationDataUtil.java:459-468`** (the service) streams that answer array, takes
   `distinct` `non-null` `rdb_table_nm`, comma-joins, and sets `rdb_table_name_list`. *(So the
   list is computed in Java from the answers — no SP emits it; it is only ever hand-authored in
   unit-test setup.sql, which is why it looked unpopulated.)*
3. **`PostProcessingService.java:351-356`** splits `rdb_table_name_list` into `pbCache` →
   `executeStoredProcForPageBuilder(tbl, uids)` populates each `D_INV_*` page-builder dimension.
4. **Condition datamarts** (COVID_CASE_DATAMART, STD_HIV_DATAMART, …) are a *separate* path:
   `sp_nrt_investigation_postprocessing` returns a DatamartData signal per PHC **iff the
   condition is mapped in `nrt_datamart_metadata`** (it is: 11065→Covid_Case_Datamart,
   10311→Std_Hiv_Datamart, etc. — 161 rows). The service then runs the mapped datamart SP.

**Two mistakes in the first attempt**, both now fixed:
- Authored answers against `PG_TB_LTBI_Investigation` while the TB PHC's condition (10220)
  maps to **legacy `INV_FORM_RVCT`, which has ZERO page-builder rdb metadata** in this seed —
  an unroutable dead end. `condition_code` for our fixtures routes only: **11065 →
  PG_COVID-19_v1.1 (350 mapped q)** and **10311 → PG_STD_Investigation (364 q)**.
- Targeted an arbitrary rich form instead of the condition's form, so the SP's condition-gated
  join never matched.

**Fix (fixtures only, no product change):** `scripts/gen_page_answers.sql` now derives the form
from the act's condition via `condition_code` and emits one type-correct `nbs_case_answer` per
remaining datamart-mapped question. Applied to the COVID + STD PHCs (`zz_page_answers_datamart_
routing.sql`): resolvable `rdb_table_nm` went **0 → 26/27** each; `rdb_table_name_list` populated
(was NULL); the `D_INV_*` dimensions populated; `sp_covid_case_datamart_postprocessing` /
`sp_std_hiv_datamart_postprocessing` fire and populate. Overall column coverage **14.0% → 34.4%**
(empty tables 60→33, fully-covered 33→58) from just these two investigations.

Remaining headroom (next, not blocking): apply the generator to every routable investigation;
COVID condition datamart column *values* are generic (coverage, not fidelity); TB/VAR need a
condition that maps to a metadata-bearing form (or accept they don't route in this seed).

## P3 / condition datamarts — RESOLVED via patient link. 37.7% → 42.1%

The empty condition datamarts were NOT a routing problem — `ProcessDatamartData.java:113-115`
**drops any DatamartData whose `patientUid` is NULL**, and the `*_investigation_full_chain.sql`
fixtures created the PHC but never a patient *subject* link. So `sp_investigation_event` left
`nrt_investigation.patient_id` NULL and every condition datamart was silently skipped.

Fix (`zz_investigation_patient_links.sql`): add a `SubjOfPHC` participation (act=PHC,
subject=foundation patient 20000000, class PSN/CASE) for all 8 investigation subjects. Result:
`patient_id` resolves → DatamartData `patient_uid` non-null → the service fires the
condition datamart SP that `nrt_datamart_metadata` maps for each condition. Newly populating:
**COVID_CASE_DATAMART, STD_HIV_DATAMART, D_TB_PAM, HEPATITIS_DATAMART**. This is the same link
fidelity the morb-comment `PATIENT_KEY` gap needed — the Tier-2 investigation↔patient link.

### Remaining condition-datamart gaps (triaged, lower ROI)
- **VAR_DATAMART = 0**: `sp_var_datamart_postprocessing` (lines 129-132) inner-joins
  `NRT_SRTE_condition_code cc ON cc.condition_cd='10030' AND cc.PORT_REQ_IND_CD='T'`. Our seed's
  SRTE row for Varicella (10030) does not satisfy `PORT_REQ_IND_CD='T'` — an SRTE-reference-data
  flag, not an investigation-fixture gap. Fix = seed/patch that SRTE flag (verify against real NBS).
- **F_TB_PAM = 0 (while D_TB_PAM = 1)**: `sp_f_tb_pam_postprocessing` gates on
  `investigation_form_cd='INV_FORM_RVCT'` (our TB PHC matches), but the TB *fact* table needs
  prerequisite dimension keys / measures (treatment, dispositions) the generic fixture lacks.
  The TB *dimension* populates; the fact needs richer TB-specific source data.
