# L1 — Labs lineage

Cluster tables: **LAB_TEST**, **LAB_TEST_RESULT**, **LAB_RESULT_VAL**,
**Lab_Result_Comment**, **LAB_RPT_USER_COMMENT**, **TEST_RESULT_GROUPING**,
**RESULT_COMMENT_GROUP** (the lab dimensions/facts), and the lab datamarts
**LAB100**, **LAB101**, **CASE_LAB_DATAMART**, **COVID_LAB_DATAMART**,
**COVID_LAB_CELR_DATAMART**.

The lab cluster has two clearly separated layers, and the layer a column
lives in determines its lineage shape:

1. **Lab dimensions** (`LAB_TEST` family) are written by the
   `sp_d_lab_test_postprocessing` and `sp_d_labtest_result_postprocessing`
   postprocessing SPs, which read **`nrt_observation` and its child staging
   tables only** (`nrt_observation_coded` / `_numeric` / `_txt` / `_material`
   / `_reason` / `_edx`), never ODSE. The `nrt_observation` row is the
   debezium/kafka-connect projection of the ODSE `observation` row, so each
   dimension column traces ODSE `observation.* → nrt_observation.* →
   LAB_TEST.*`. These are the columns with concrete VERIFIED mappings.

2. **Lab datamarts** (`LAB100`/`LAB101`/`CASE_LAB`/`COVID_LAB*`) read from the
   **already-populated RDB_MODERN dimensions** (`LAB_TEST`, `LAB_TEST_RESULT`,
   `LAB_RESULT_VAL`, `LAB_RESULT_COMMENT`, `D_PATIENT`, `D_PROVIDER`,
   `D_ORGANIZATION`, `INVESTIGATION`, `CONDITION`) — *except* `COVID_LAB_DATAMART`,
   which is the one datamart that re-reads `nrt_observation` directly. So most
   datamart columns chain back to ODSE *through* their dimension's own lineage
   (documented in layer 1); the appendix shows the dim column as the
   `nrt_staging_source` and the `-> ... -> observation` chain in
   `odse_source_col(s)`.

## LAB_TEST / LAB_TEST_RESULT / LAB_RESULT_VAL / comments / groupings

`sp_d_lab_test_postprocessing` builds `#observation_data` from `nrt_observation`
filtered to `obs_domain_cd_st_1 IN ('Order','Result','R_Order','R_Result',
'I_Order','I_Result','Order_rslt')` AND `ctrl_cd_display_form IN ('LabReport',
'LabReportMorb') OR NULL`. From that it projects the LAB_TEST columns almost
1:1 from observation columns (cd → LAB_TEST_CD, method_cd → TEST_METHOD_CD,
target_site_cd → SPECIMEN_SITE, local_id → LAB_RPT_LOCAL_ID, etc.). A handful
of columns come from child staging tables collapsed into temp tables:
`#material_data` (latest `nrt_observation_material` by `last_chg_time` →
SPECIMEN_*/DANGER_*), `#reason_data` (`STRING_AGG` over
`nrt_observation_reason` → REASON_FOR_TEST_CD/DESC, `|`-delimited),
`#hierarchical_data`/`#merge_order` (walks parent order via
`report_observation_uid` → ROOT_ORDERED_TEST_PNTR / PARENT_TEST_NM). Notable
transforms: `RECORD_STATUS_CD` collapses PROCESSED/UNPROCESSED/''/NULL → `ACTIVE`
and LOG_DEL → `INACTIVE`; `JURISDICTION_NM`, `LAB_TEST_STATUS`, and
`PROCESSING_DECISION_DESC` are SRTE code lookups against `nrt_srte_*`.

`sp_d_labtest_result_postprocessing` writes `LAB_TEST_RESULT` (the fact),
`LAB_RESULT_VAL`, `Lab_Result_Comment`, `TEST_RESULT_GROUPING`, and
`RESULT_COMMENT_GROUP`. The result-value columns come from the obs-value
staging children: `nrt_observation_coded` (ovc_* → TEST_RESULT_VAL_CD family +
ALT_RESULT_VAL_CD family), `nrt_observation_numeric` (ovn_* → NUMERIC_RESULT,
REF_RANGE_FRM/TO, RESULT_UNITS), `nrt_observation_txt` split by type
(`txt_type_cd='FT'` → LAB_RESULT_TXT_VAL; `='N'` → LAB_RESULT_COMMENTS in
`Lab_Result_Comment`). `LAB_TEST_RESULT` is essentially all foreign keys: each
`*_KEY` is a `COALESCE(<dim lookup>, 1)` — sentinel **1** when the upstream
dimension isn't populated yet. `LAB_RPT_USER_COMMENT` is written by
`sp_d_lab_test_postprocessing` from the C_Result follow-up observation's `'N'`
text, reached via the Order's `followup_observation_uid` CSV (the C_Order /
C_Result observations are *deliberately excluded* from `@obs_ids` because they
fail the `obs_domain_cd_st_1` filter — see `coverage_lab.md`).

All of these are **VERIFIED** by `fixtures/10_subjects/lab.sql` +
`coverage_lab.md` (live: LAB_TEST 66/66, LAB_RESULT_VAL 20/20,
LAB_RESULT_COMMENT 6/6, TEST_RESULT_GROUPING 3/3, RESULT_COMMENT_GROUP 3/3,
LAB_TEST_RESULT 19/20). Honest exceptions, all flagged INFERRED in the
appendix and cross-referenced in the coverage report's "deliberately skipped":

- **LAB_TEST.RESULT_INTERPRETER_NAME** — LEFT JOINs `nrt_provider` on
  `result_interpreter_id`; empty at Lab Tier-1 isolation → NULL. Resolves once
  the Provider chain has run (merged-fixture sequence).
- **LAB_TEST_RESULT.CONDITION_KEY** — join is `condition.program_area_cd =
  prog_area_cd AND condition.condition_cd IS NULL`; the lab fixture uses STD
  prog-area while CONDITION is seeded for HEP only → sentinel 1 persists
  (`coverage_lab_inv.md` OUT_OF_SCOPE).
- **LAB_TEST_RESULT.MORB_RPT_KEY** — no NBS act_relationship path Lab→Morb;
  linkage is via `report_observation_uid`, sentinel 1 persists.
- **LAB_TEST_RESULT.LDF_GROUP_KEY** — `ldf_group` empty in baseline (Tier-3
  LDF work); sentinel 1.
- **LAB_TEST_RESULT.LAB_RESULT_VAL_LARGE_TXT_KEY** — column in DDL but no SP
  writes it.
- **TEST_RESULT_GROUPING.RDB_LAST_REFRESH_TIME** — SP explicitly INSERTs
  `CAST(NULL AS datetime)` by design.

### The Lab→Investigation Tier-2 edge (LAB_TEST_RESULT.INVESTIGATION_KEY)

`fixtures/20_links/lab_inv.sql` authors the `type_cd='LabReport'`
act_relationship (Lab Order → Investigation PHC) and mirrors the CDC effect by
UPDATE-ing `nrt_observation.associated_phc_uids` to the investigation
`case_uid`. The result-postprocessing SP `STRING_SPLIT`s that CSV and joins
`investigation.case_uid` → `INVESTIGATION_KEY` flips from sentinel 1 to a real
key for all three LAB_TEST_RESULT rows (`coverage_lab_inv.md`: 1 → 3 / 4). This
edge is also what un-gates `CASE_LAB_DATAMART` (its keying filter is
`INVESTIGATION_KEY <> 1`). The other FK keys (PATIENT/PROVIDER/ORG/DATE) resolve
through the corresponding Tier-1 subject chains, not this edge.

## LAB100

`sp_lab100_datamart_postprocessing` assembles `#TMP_LABTESTS4` from
`LAB_TEST` (Order + Result, paired via `ROOT_ORDERED_TEST_PNTR`),
`LAB_TEST_RESULT`, `LAB_RESULT_VAL`, `LAB_RESULT_COMMENT`, and demographic
INNER/LEFT joins to `D_PATIENT` / `D_PROVIDER` / `D_ORGANIZATION`. It is a
result-centric flattening: one LAB100 row per resulted test, INSERT-filtered to
`LAB_RPT_LOCAL_ID IS NOT NULL`. EVENT_DATE is `COALESCE(SPECIMEN_COLLECTION_DT,
LAB_TEST_DT, LAB_RPT_RECEIVED_BY_PH_DT, LAB_RPT_CREATED_DT)`; ADDRESS_DATE is a
hardcoded NULL. VERIFIED by `fixtures/30_sp_coverage/zz_lab100_enrich.sql` (which
authors two fully-attributed Order+Result pairs reusing well-populated
Foundation Patient/Provider/Org rows) — live **62/69**. The ~7 unpopulated
columns are the address-use/cd description lookups (ADDR_USE_CD_DESC,
ADDR_CD_DESC, PRV_*), CONDITION_SHORT_NM / PROGRAM_AREA_DESC (sparse CONDITION
dim), and the sentinel/empty FK passthroughs (MORB_RPT_KEY, LDF_GROUP_KEY) —
flagged INFERRED.

## LAB101 — isolate tracking (entirely INFERRED, 0/46 live)

`sp_lab101_datamart_postprocessing` is the Emerging-Infections / NARMS / PFGE
PulseNet isolate-tracking datamart. Roughly a dozen columns
(RESULTED_LAB_TEST_KEY, SPECIMEN_*, RECORD_STATUS_CD, OID, dates) come from
`LAB_TEST`; the **bulk** — every `EIP_*`, `NARMS_*`, `PFGE_*`, `ISO_*`,
`PATIENT_STATUS`, `CASE_LAB_CONFIRMED_IND`, `PULSENET_ISO_IND` column — comes
from a special **`cd='LAB330'` follow-up observation** reached by walking the
Order's `followup_observation_uid` CSV, whose coded result values
(`TEST_RESULT_VAL_CD_DESC`) are pivoted **positionally** into aliases
`LAB.LAB3` … `LAB.LAB34` (e.g. `LAB10` → PFGE_PULSENET_SENT, `LAB21` →
NARMS_EXPECTED_SHIP_DATE via a `convert(datetime, replace('-',' '))`). No
fixture exercises the LAB330 isolate-tracking chain, so **the whole table is
empty (0/46)** and every column is flagged **INFERRED** — the source chain is
reconstructed from the SP body (`nrt_observation` LAB330 followups →
`obs_value_coded` → ODSE `observation`), never confabulated. This is the most
notable gap in the cluster: lighting up LAB101 would need a follow-on fixture
authoring a LAB330 follow-up observation with the positional answer set.

## CASE_LAB_DATAMART

`sp_case_lab_datamart_postprocessing` is investigation-centric: it keys on
`INVESTIGATION` rows that have an active linked `LAB_TEST_RESULT` (i.e. the
Tier-2 LabReport edge must exist), joins `D_PATIENT` for demographics (which are
*also* UPDATEd by the guarded `sp_patient_dim_columns_update_to_datamart`),
`condition` for DISEASE/DISEASE_CD, and an ORGANIZATION lookup for
REPORTING_SOURCE. `LABORATORY_INFORMATION` is a large concatenated HTML chunk
built from the investigation's `LAB_TEST` / `LAB_RESULT_VAL` rows (with HTML
entity decoding `&lt; → <` etc.). Live **11/35** — the investigation/patient
identity and OID columns (12 in the appendix) are flagged VERIFIED via
`fixtures/20_links/lab_inv.sql` — the Tier-2 LabReport edge demonstrably wires
the investigation+patient identity path; the remaining address, age, race,
physician, disease, comment, and laboratory-chunk columns are flagged INFERRED
(populated in principle once the upstream graph is fully wired, but not
confirmed for these specific columns in the merged run). Note the appendix
counts 12 VERIFIED identity columns while `coverage_merged.md` reports an
aggregate **11/35** populated in the live run — the one-column gap is a single
identity column that lands blank in that specific run, not a confabulated
mapping; both numbers are reported here rather than reconciled away.

## COVID_LAB_DATAMART / COVID_LAB_CELR_DATAMART (DYNAMIC)

These two are structurally different from the rest and are flagged **DYNAMIC**.
`sp_covid_lab_datamart_postprocessing` builds `#COVID_LAB_CORE_DATA` directly
from `nrt_observation` (Order `o` + Result `o1`) plus
`nrt_observation_coded/numeric` and `nrt_organization`/`D_Organization`, gated
on the result `cd` mapping to `condition_cd='11065'` (2019 Novel Coronavirus)
via `nrt_srte_Loinc_condition` (which the unblock fixture must seed first — by
default that table has zero `11065` rows). It then **dynamically `ALTER TABLE
dbo.COVID_LAB_DATAMART ADD`**s a column per `#COVID_LAB_CORE_DATA` column, and
separately builds `#COVID_LAB_AOE_DATA` — a dynamic PIVOT of "ask-on-order
entry" answer observations keyed by `nrt_odse_lookup_question` where
`from_form_cd='LAB_REPORT'` (FIRST_TEST, HOSPITALIZED, ICU, PREGNANT, …). The
catalog therefore lists only the placeholder `COVID_LAB_CORE_DATA`; the physical
129-column schema is generated at runtime. The appendix documents the
mechanism: the **core** columns have concrete `nrt_observation → observation`
sources (sample rows enumerated), and the **AOE** columns are a single DYNAMIC
row because the column set is not statically derivable.
`sp_covid_lab_celr_datamart_postprocessing` is a pure downstream projection — it
just `INNER JOIN STRING_SPLIT`s `dbo.covid_lab_datamart` on `Observation_Uid`
and re-derives the CELR schema (17 columns hardcoded NULL). Live:
COVID_LAB_DATAMART **127/129**, COVID_LAB_CELR_DATAMART **85/101**, both via
`zz_covid_lab_datamart_unblock.sql` + `zz_covid_lab_celr_datamart_unblock.sql`.

## Summary

| Table | Live coverage | Status in appendix |
| --- | --- | --- |
| LAB_TEST | 66/66 | VERIFIED (65) + INFERRED (1: RESULT_INTERPRETER_NAME) |
| LAB_TEST_RESULT | 19/20 | VERIFIED (16) + INFERRED (4 sentinels/unwritten) |
| LAB_RESULT_VAL | 20/20 | VERIFIED |
| Lab_Result_Comment | 6/6 | VERIFIED |
| LAB_RPT_USER_COMMENT | 8/8 | VERIFIED |
| TEST_RESULT_GROUPING | 3/3 (RDB ref NULL by design) | VERIFIED (2) + INFERRED (1) |
| RESULT_COMMENT_GROUP | 3/3 | VERIFIED |
| LAB100 | 62/69 | VERIFIED (60) + INFERRED (9) |
| LAB101 | 0/46 | INFERRED (all 46 — LAB330 isolate-tracking chain unexercised) |
| CASE_LAB_DATAMART | 11/35 | VERIFIED (12) + INFERRED (23) |
| COVID_LAB_DATAMART | 127/129 | DYNAMIC (runtime schema; core nrt_observation-sourced + AOE pivot) |
| COVID_LAB_CELR_DATAMART | 85/101 | DYNAMIC (projection of covid_lab_datamart) |

No lab columns are BLOCKED by a bug (bug dirs 01–13 contain no lab-cluster
findings; the LDF/dyn_dm bugs that mention "lab" are out of this cluster). No
lab columns are MASTERETL_ONLY.
