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

## Headline result: coverage 90.5% → **14.0%**

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
resolved `nrt_page_case_answer` rows and force-running datamart SPs. This is a substantial
fixture-authoring effort (P2/P3 are similar fidelity work), not a one-line routing fix.

Tight-loop aid added: `docker-compose.override.yaml` (untracked) sets FIXED_DELAY_ID=2000 /
FIXED_DELAY_DM=3000 on the service so the CDC→nrt→SP drain completes in seconds for iteration.
