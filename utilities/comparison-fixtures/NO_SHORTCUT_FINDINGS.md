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
