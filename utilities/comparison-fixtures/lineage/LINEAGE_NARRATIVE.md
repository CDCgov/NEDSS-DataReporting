# RTR Data Lineage — ODSE → staging → RDB_MODERN

> **What this is.** An end-to-end column-lineage map for the RTR (Real-Time
> Reporting) pipeline: for every populated RDB_MODERN target column, the chain
> back through `nrt_*` staging to its `nbs_odse` source(s), with the stored
> procedure and comparison-fixture that *prove* each path. It exists in two
> parts — this human-readable narrative, and the machine-readable column
> appendix `LINEAGE_COLUMNS.tsv` that the future schema-diff tool consumes.
>
> **It is synthesized, not freshly derived.** The SQL contains each *hop* but
> never the *end-to-end chain*. This document is the synthesis of ~38
> comparison fixtures and their coverage reports, each of which already
> reverse-engineered "these ODSE inputs light up these RDB_MODERN columns
> through this SP." See `LINEAGE.md` for how the work was fanned out.

## The pipeline in four layers

RTR moves case-surveillance data from the operational NBS database
(`nbs_odse`) into the reporting warehouse (`RDB_MODERN`) through a staging
layer. Reading left to right:

```
nbs_odse.dbo.*                         operational source (ODSE)
   │   sp_<entity>_event               projects ODSE rows → JSON
   ▼
[ CDC → Debezium → Kafka → JDBC sink ] production transport (bypassed in fixtures)
   ▼
dbo.nrt_*  (+ #tmp_* derivations)      RDB_MODERN-side staging
   │   sp_nrt_*_postprocessing
   │   sp_d_*_postprocessing
   │   sp_*_datamart_postprocessing
   ▼
RDB_MODERN dimensions / facts / datamarts   reporting targets
```

1. **ODSE → JSON (event layer).** `sp_<entity>_event` SPs read
   `nbs_odse.dbo.*` directly and project rows into a JSON shape for downstream
   consumption. These are the **only** SPs that touch ODSE. They do *not*
   write `nrt_*` — that is the CDC pipeline's job.

2. **JSON → staging (transport).** In production, SQL Server CDC → Debezium →
   Kafka → a kafka-connect JDBC sink lands the projected rows into `dbo.nrt_*`
   staging tables in RDB_MODERN. The comparison fixtures **deliberately bypass
   this** and hand-author synthetic `nrt_*` rows alongside the ODSE INSERTs,
   because the project diffs the *postprocessing transform*, not CDC fidelity.

3. **staging → RDB_MODERN (postprocessing layer).** `sp_nrt_*_postprocessing`,
   `sp_d_*_postprocessing`, and `sp_*_datamart_postprocessing` SPs read
   `nrt_*` staging (and `#tmp_*` tables derived from it) and write the
   warehouse dimensions, facts, and datamarts.

4. **datamarts (no event partner).** Datamart SPs (Hepatitis_Datamart,
   Std_Hiv_Datamart, the `dyn_dm_*` family, etc.) have no `_event` partner at
   all — they read already-populated RDB_MODERN dimensions and run after
   Tier 1/Tier 2 are merged.

## The load-bearing convention: postprocessing reads staging only

This invariant, verified against the entire
`liquibase-service/.../005-rdb_modern/routines/` tree, is what makes the
lineage tractable:

- **`sp_*_event` SPs read `nbs_odse.dbo.*` directly** — that is their whole
  job (the ODSE→staging edge).
- **`sp_nrt_*_postprocessing` / `sp_d_*` / `sp_*_datamart_*` SPs read
  RDB_MODERN-side staging only** — `nrt_*` tables and `#tmp_*` temps. There
  are **zero** references to `nbs_odse.dbo.*` in the postprocessing layer
  (the staging→RDB_MODERN edge).

The CSV columns on NRT staging rows (e.g.
`nrt_observation.associated_phc_uids`,
`nrt_morbidity_observation.followup_observation_uid`) are the upstream
Debezium projection of the act_relationship / participation graph — how
postprocessing walks edges *without* re-traversing ODSE. The synthesis hop in
this document — mapping an `nrt_*` staging column back to its ODSE source — is
recovered by reading the matching `sp_*_event` SP's JSON projection, and is
the one place this document goes beyond any single SP body.

## How to read the column appendix

`LINEAGE_COLUMNS.tsv` has one row per RDB_MODERN column, tab-separated:

| field | meaning |
| --- | --- |
| `rdb_modern_table` | target table |
| `rdb_modern_col` | target column |
| `writing_sp` | the postprocessing/datamart SP that writes it |
| `nrt_staging_source` | the `nrt_*` column (or `#tmp` derivation) the SP reads |
| `odse_source_col(s)` | the `nbs_odse.dbo.*` column(s) feeding that staging col |
| `transform_note` | CASE/COALESCE/substring/pivot/code-lookup applied |
| `status` | provenance confidence (below) |
| `fixture_proof` | the fixture (+ coverage report) establishing the mapping |

**Status flags** (the discipline rule: every column gets a row and an honest
status — a confabulated ODSE→target mapping is worse than an `INFERRED` flag):

- **`VERIFIED`** — a fixture populates the column and a coverage report
  confirms it. `fixture_proof` cites the fixture.
- **`INFERRED`** — the SP clearly maps it but no fixture proves it (or it sits
  in a partially-covered table and the specific column couldn't be confirmed).
  The ODSE source is the SP's apparent intent, never invented.
- **`DYNAMIC`** — written via dynamic SQL (`<dynamic:@var>` in the catalog);
  source not statically derivable. The `dyn_dm_*` family and much of the LDF
  cluster are dynamic, keyed on `nbs_page_answer` / page-builder metadata —
  the appendix documents the driving mechanism, not a forced column map.
- **`MASTERETL_ONLY`** — per `catalog/odse_unknown_tables.md`, no RTR ODSE
  path; the column is pre-populated by the legacy MasterETL pipeline.
- **`BLOCKED:#NN`** — reachable in principle but capped by a known RTR bug
  (`bugs/NN_*/findings.md`).

### Scope and counts (sanity check for the appendix)

- The static catalog `rtr_target_columns.md` parses **130** routines and finds
  **3,593** statically-derivable (table, column) pairs across **118** in-scope
  tables, plus **15** dynamic-SQL target placeholders whose columns are *not*
  statically derivable.
- Live coverage (`coverage_merged.md`, full from-scratch run 2026-05-25)
  reports **4,633** total columns across those 118 tables, of which **4,150**
  are populated — **89.6%** overall column coverage.
- **This appendix has 3,101 rows across 66 tables.** It is *not* a 1:1 with
  the 4,150 live-populated columns, and deliberately so: tables whose physical
  schema is generated at runtime — `covid_case_datamart`, `covid_lab*`,
  `d_investigation_repeat`, the `dyn_dm_*` family — are built by dynamic SQL
  (`ALTER TABLE … ADD` + PIVOT keyed on `nbs_page_answer` / page-builder
  metadata) and are represented by a **single `DYNAMIC` mechanism row each**
  rather than by enumerating their hundreds of runtime columns. That collapses
  ~1,000+ live-populated-but-runtime columns into a handful of rows. The
  statically-traceable spine of every table *is* fully enumerated (verified
  1:1 against `rtr_target_columns.md` per cluster). Status split across the
  3,101 rows: **1,499 VERIFIED · 1,318 INFERRED · 174 MASTERETL_ONLY ·
  86 BLOCKED · 25 DYNAMIC**.

### Known caveats reflected in the data

- **`zz_hepatitis_datamart_round2.sql` is quarantined** (tempdb blowup on cold
  rebuild — see `BLOCKED.md` / `bugs/`). Its ~+61 `hepatitis_datamart` columns
  are therefore **not** currently populated and are flagged `BLOCKED` /
  `INFERRED` in the Hepatitis section, not `VERIFIED`.
- **Bugs #11–#13 cap specific columns**: #11 `aggregate_report_datamart`
  schema mismatch; #12 `bmird_case_datamart` ROW_NUMBER partition; #13
  `sld_investigation_repeat` TEXT-pivot NULL propagation. Affected columns are
  flagged `BLOCKED:#NN`.

---

## Cluster sections

### Table of contents

- [L1 — Labs lineage](#l1--labs-lineage)
- [L2 — Hepatitis cluster](#l2--hepatitis-cluster)
- [L3 — TB / STD-HIV / BMIRD / Varicella datamarts](#l3--tb--std-hiv--bmird--varicella-datamarts)
- [L4 — COVID family lineage](#l4--covid-family-lineage)
- [L5 — People, Links & Dimensions](#l5--people-links--dimensions)
- [L6 — Investigation-repeat, LDF, dyn_dm, page-builder](#l6--investigation-repeat-ldf-dyn_dm-page-builder)

---

## L1 — Labs lineage

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

### LAB_TEST / LAB_TEST_RESULT / LAB_RESULT_VAL / comments / groupings

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

#### The Lab→Investigation Tier-2 edge (LAB_TEST_RESULT.INVESTIGATION_KEY)

`fixtures/20_links/lab_inv.sql` authors the `type_cd='LabReport'`
act_relationship (Lab Order → Investigation PHC) and mirrors the CDC effect by
UPDATE-ing `nrt_observation.associated_phc_uids` to the investigation
`case_uid`. The result-postprocessing SP `STRING_SPLIT`s that CSV and joins
`investigation.case_uid` → `INVESTIGATION_KEY` flips from sentinel 1 to a real
key for all three LAB_TEST_RESULT rows (`coverage_lab_inv.md`: 1 → 3 / 4). This
edge is also what un-gates `CASE_LAB_DATAMART` (its keying filter is
`INVESTIGATION_KEY <> 1`). The other FK keys (PATIENT/PROVIDER/ORG/DATE) resolve
through the corresponding Tier-1 subject chains, not this edge.

### LAB100

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

### LAB101 — isolate tracking (entirely INFERRED, 0/46 live)

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

### CASE_LAB_DATAMART

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

### COVID_LAB_DATAMART / COVID_LAB_CELR_DATAMART (DYNAMIC)

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

### Summary

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

---

## L2 — Hepatitis cluster

Tables: `HEPATITIS_DATAMART`, `HEP100`, `HEP_MULTI_VALUE_FIELD_GROUP`
(the "hepatitis_case" subject), `LDF_HEPATITIS`.

Writing SPs:
`sp_hepatitis_datamart_postprocessing` (013),
`sp_hep100_datamart_postprocessing` (042),
`sp_hepatitis_case_datamart_postprocessing` (039),
`sp_ldf_hepatitis_datamart_postprocessing` (320).

Column appendix slice: `lineage/columns/L2_hepatitis.tsv` (398 rows).
Status mix: **330 VERIFIED · 65 BLOCKED:tempdb · 2 INFERRED · 1 DYNAMIC.**
This reconciles exactly with `coverage/coverage_merged.md`:
HEP100 185/187, HEP_MULTI 1/1, HEPATITIS_DATAMART 144/209, LDF 0/7.

All four SPs are datamart-postprocessing SPs with **no `_event`
partner**: per STRATEGY.md's convention, they read already-populated
RDB_MODERN dimensions/staging (`nrt_*`, the `D_INV_*` page-builder
dims, `F_PAGE_CASE`), never `nbs_odse.dbo.*` directly. The ODSE edge is
therefore one hop further upstream — ODSE `public_health_case` /
`nbs_case_answer` / `observation` rows flow into `nrt_investigation` /
`nrt_page_case_answer` (production: CDC→Debezium→Kafka; fixtures:
hand-authored), get pivoted into the `D_INV_<cat>` dimensions by the
page-builder chain (`sp_s_pagebuilder_*` → `sp_d_pagebuilder_*`), and
only then are read by the Hepatitis datamart SP. The `odse_source_col(s)`
column in the appendix names that upstream origin; the
`transform_note` names the dimension hop.

### HEPATITIS_DATAMART (144/209 VERIFIED, 65 BLOCKED:tempdb)

Row flow (SP 013): the SP builds `#TMP_HEPATITIS_CASE_BASE` by a wide
`SELECT DISTINCT … INTO` (lines 1853–2097) that FULL-OUTER-JOINs the
`INVESTIGATION` dim (`I.`) to twelve page-builder dimensions keyed on
`INVESTIGATION_KEY`: `D_INV_LAB_FINDING` (`L.`),
`D_INV_RISK_FACTOR` (`R.`), `D_INV_EPIDEMIOLOGY` (`E.`),
`D_Patient` (`P.`), `D_INV_VACCINATION` (`V.`), `D_INV_TRAVEL` (`T.`),
`D_INV_MOTHER` (`M.`), `D_INV_MEDICAL_HISTORY` (`MH.`),
`D_INV_ADMINISTRATIVE` (`A.`), `D_INV_PATIENT_OBS` (`PO.`),
`D_INV_CLINICAL` (`C.`), a provider/org/reporting-source bundle
`#TMP_HEP_PAT_PROV` (`HP.`, joined off `F_PAGE_CASE` keys to
`D_PROVIDER`/`D_ORGANIZATION`), and a vaccination-repeat pivot
`#TMP_VAC_REPEAT_OUT_FINAL` (`VAC.`). Each datamart column's source
prefix in the appendix is taken straight from this SELECT, so the
ODSE origin is the corresponding `nbs_case_answer` answer (LAB_*,
RSK_*, EPI_*, etc.) for the page-builder dims, `public_health_case`
for the `I.` columns, and provider/organization participations for the
`HP.` columns.

Gating predicates: the SP filters on Hepatitis condition codes
(`condition_cd IN ('10110','10104','10100','10106','10101','10102',
'10103','10105','10481','50248','999999')`; the fixture uses 10110
Hep A acute). The load-bearing gate is the
`DELETE FROM #TMP_HEPATITIS_CASE_BASE WHERE PATIENT_UID IS NULL`
(line ~2148): if `nrt_investigation.patient_id` is NULL,
`sp_f_page_case_postprocessing`'s `COALESCE(PATIENT.PATIENT_KEY, 1)`
falls back to the sentinel patient (UID NULL) and the row is deleted,
yielding 0 datamart rows. This is the bug-5b cascade documented in
`coverage/coverage_hep_datamart_investigation.md` and
`bugs/05_tmp_f_page_case_family/`. Notable transforms: numeric-string
guarding (`NOT LIKE N'%[^0-9.,-]%' AND ISNUMERIC = 1`) on
`LAST6PLUSMO_INCAR_*` / sex-partner / STD-year columns; control-char
stripping on `INV_COMMENTS`; `SUBSTRING` truncation on
`BINATIONAL_RPTNG_CRIT` (300) and `TEST_REASON_OTH` (150);
`HEP_D_TEST_IND` Yes/No→Y/N/U recode; `VACC_GT_4_IND` empty→'False';
`EVENT_DATE` / `EVENT_DATE_TYPE` are SP literals (`CAST(NULL …)`).

The **144 VERIFIED** columns are populated by
`fixtures/30_sp_coverage/zz_hepatitis_datamart_enrich.sql` (Round 1),
which direct-INSERTs the `D_INV_*` dimensions plus their `L_INV_*` link
rows for PHC 22008500 (the page-builder answer→S_INV→D_INV pivot does
not propagate in this DB, so the dims are seeded directly), then
tail-EXECs `sp_f_page_case_postprocessing` and
`sp_hepatitis_datamart_postprocessing`. `INIT_NND_NOT_DT` is also
populated via the notification chain (`sp_nrt_notification_postprocessing`
UPDATE) at merge step 9.

The **65 BLOCKED:tempdb** columns are exactly the ones Agent Q's Round 2
fixture was meant to light up:
`fixtures/30_sp_coverage/_quarantine/zz_hepatitis_datamart_round2.sql.tempdb-blowup`.
They are: the full `D_INV_RISK_FACTOR` (`R.`) set (~39 cols — RSK_* was
explicitly skipped in Round 1 over numeric-cast concerns); the
provider/org/reporting-source (`HP.`) bundle (PHYS_*, INVESTIGATOR_*,
RPT_SRC_*, *_UID — 13 cols); the three `INVESTIGATION`-UPDATE cols
(INV_COMMENTS, INV_START_DT, PAT_PREGNANT_IND); and the
vaccination-repeat pivot outputs (VACC_DOSE_NBR_1..4, VACC_RECVD_DT_1..4,
IMM_GLOB_RECVD_IND, GLOB_LAST_RECVD_YR — 10 cols). **These are NOT in
the live 89.6% coverage.** Round 2 verified them on a *warm*
incremental DB (140→201), but on the deterministic cold single-batch
rebuild its tail-EXEC chain (`sp_f_page_case_postprocessing` →
`sp_hepatitis_datamart_postprocessing`, PHC 22008500) spilled ~70 GB
into tempdb and crashed MSSQL twice (ENOSPC). Per LOOP's
fixture-error rule the file was renamed to a non-`.sql` suffix and
parked under `_quarantine/` (see `BLOCKED.md` and the `_quarantine/`
README). Restoring it needs an upstream fix to the runaway
join/spill in those two SPs (or a tempdb MAX_SIZE cap that fails loudly
on just this fixture). Marked `BLOCKED:tempdb` rather than VERIFIED
accordingly. (Note: the briefing's "bug #14" label does not have a
`bugs/14_*` dir — bug dirs run 01–13 — so the quarantine is tracked
via `BLOCKED.md`/`_quarantine/README.md`, not a numbered bug.)

### HEP100 (185/187 VERIFIED, 2 INFERRED)

Row flow (SP 042): HEP100 does **not** read `HEPATITIS_DATAMART`. It
builds `#HEP100_INIT` by selecting `FROM dbo.HEPATITIS_CASE hc`
(line 349) and joining the patient/provider/investigation dimensions,
then INSERTs into `HEP100` (line 601). So the chain is
`HEPATITIS_CASE → HEP100`, with `HEPATITIS_CASE` itself being the
observation-pivot output (see next section). The clinical/risk/epi
columns are carried straight from `HEPATITIS_CASE`; patient
demographics come from the `nrt_patient`-fed `D_PATIENT` join;
physician/investigator/reporting-source columns from
`D_PROVIDER`/`D_ORGANIZATION`; investigation attributes via the
`INVESTIGATION` dim. The notable derived column is `EVENT_DATE`,
computed from a date-coalesce precedence lifted from the classic SAS
ETL (Illness_onset → Diagnosis → earliest of report/admit/discharge
dates; SP comment lines 61–82).

The unblock fixture
(`fixtures/30_sp_coverage/zz_hepatitis_zz_hep100_unblock.sql`)
direct-INSERTs one richly-populated `HEPATITIS_CASE` row keyed to the
Hep A investigation (CASE_UID 22008500), because `HEPATITIS_CASE` has 0
rows in the baseline and no routine-layer SP writes it from ODSE — it
is normally a Kafka/Debezium-streamed table. The fixture resolves
`INVESTIGATION_KEY` dynamically (an earlier hardcoded `=26` broke the
FK on clean rebuilds) and self-heals if the dim row is missing. With
that one row, the SP's `INNER JOIN (HC.investigation_key =
I.investigation_key)` is satisfied and HEP100 populates 185/187 live.
The 2 INFERRED gaps are `ADDR_CD_DESC` / `ADDR_USE_CD_DESC`
(address-type code descriptors) — guarded patient-dim columns
(also written by `sp_patient_dim_columns_update_to_datamart`) that
stay NULL because the seeded patient locator carries no address-use /
address-type code. Not blocked, just unseeded.

### HEP_MULTI_VALUE_FIELD_GROUP (1/1 VERIFIED) — the "hepatitis_case" subject

`sp_hepatitis_case_datamart_postprocessing` (039) is a **dynamic-pivot**
SP (`@tgt_table_nm='Hepatitis_Case'`, `@multival_tgt_table_nm =
'HEP_Multi_Value_Field'`). It reads observation values through
`dbo.v_rdb_obs_mapping` — splitting coded / text / date / numeric
answer values into `#OBS_*_Hepatitis_Case` temp tables filtered by
`RDB_TABLE = @tgt_table_nm` — and writes `HEPATITIS_CASE` plus the
multi-value group table `HEP_MULTI_VALUE_FIELD_GROUP`. The single
cataloged column `HEP_MULTI_VAL_GRP_KEY` is a surrogate group key
assigned per multi-value answer group; its ODSE origin is the
`observation` rows mapped to `HEP_Multi_Value_Field`. Live coverage
shows 1/1 (the group-key row is present), so it is VERIFIED via the
hep100 unblock fixture's seeded `HEPATITIS_CASE`/group context.

Note the coverage-report nuance: the 2026-05-19 investigation
(`coverage_hep_datamart_investigation.md`, line 138) found that
`sp_hepatitis_case_datamart_postprocessing` itself produces **0** rows
of `HEPATITIS_CASE` end-to-end, because it needs `NBS_case_answer`-style
observation data that the fixtures don't seed through the pivot path.
That is why the HEP100 unblock fixture takes the direct-INSERT
shortcut on `HEPATITIS_CASE` rather than relying on SP 039.

### LDF_HEPATITIS (0/7 — DYNAMIC, LDF chain blocked)

`sp_ldf_hepatitis_datamart_postprocessing` (320) is an LDF
(locally-defined-field) datamart SP: its columns are **dynamic** —
the SP `ALTER TABLE`s `LDF_HEPATITIS` per the LDF-template metadata for
the condition, then dynamically INSERTs answer values keyed on
`nrt_ldf` / `nrt_page_case_answer`. There is no static ODSE→column map;
the catalog represents the whole table as one `dynamiccolumnList`
entry. Live coverage is **0/7**: the LDF chain is blocked upstream —
`sp_nrt_ldf_dimensional_data_postprocessing` early-returns producing 0
rows of `LDF_DIMENSIONAL_DATA` (`bugs/07_ldf_dimensional_data_zero/`),
and the related LDF truncation issue (`bugs/06_ldf_data_truncation/`,
fixed on main) sits on the same path. The fixture does tail-EXEC
`sp_ldf_hepatitis_datamart_postprocessing` (@phc_uids='22008500') but
no LDF columns populate. Flagged `DYNAMIC` with the LDF-chain block
noted (`BLOCKED:#07`).

### Summary of what's blocked vs. covered

- **Covered live (the 89.6% run):** HEPATITIS_DATAMART 144/209
  (Round 1 enrich), HEP100 185/187, HEP_MULTI 1/1.
- **Blocked / not in the headline:** HEPATITIS_DATAMART's Round 2 +65
  (RSK_*, provider/org, vaccination-repeat, 3 investigation cols) —
  quarantined for the tempdb blowup; LDF_HEPATITIS 0/7 — LDF
  dimensional-data chain (bug #07); HEP100 2 address-descriptor cols —
  unseeded (INFERRED).

---

## L3 — TB / STD-HIV / BMIRD / Varicella datamarts

Cluster tables: `D_TB_PAM`, `TB_DATAMART`, `TB_HIV_DATAMART`,
`STD_HIV_DATAMART`, `BMIRD_STREP_PNEUMO_DATAMART`, `VAR_DATAMART`
(1,427 RDB_MODERN columns total). Column-level lineage is in
`lineage/columns/L3_tb_stdhiv_bmird_var.tsv`.

This cluster spans the **two composition patterns** the project's
datamart SPs use, and all six tables are downstream consumers — none
read `nbs_odse` directly (per the STRATEGY.md convention: only
`sp_*_event` SPs read ODSE; the postprocessing/datamart layer reads
`nrt_*` staging and RDB_MODERN dimensions). The ODSE source columns
below are therefore the *synthesis hop*: the `sp_investigation_event` /
`sp_observation_event` JSON projection that feeds the staging tables
these SPs read.

The two patterns:

- **PAM page-answer pivot** (TB, Varicella, and the TB-HIV sub-mart).
  A per-investigation set of `nbs_case_answer` rows is projected by
  `sp_investigation_event` into `nrt_page_case_answer` (carrying
  `answer_txt`, `datamart_column_nm`, `question_identifier`,
  `code_set_group_id`). The `sp_nrt_d_*_pam_postprocessing` SP `PIVOT`s
  `MAX(answer_txt) FOR datamart_column_nm IN (...)` — so **each
  D_*_PAM column is exactly one PAM question's answer**, code-translated
  via `nrt_srte_code_value_general` for coded answers. The datamart SP
  then projects D_*_PAM through the fact table (`F_TB_PAM` /
  `F_VAR_PAM`) and folds in patient/provider/org dimensions.
- **D_INV_\* / observation dimensional composition** (STD-HIV, BMIRD).
  The datamart SP `LEFT JOIN`s a family of dimension tables
  (`D_INV_ADMINISTRATIVE`, `D_INV_CLINICAL`, `D_INV_COMPLICATION`,
  `D_INV_EPIDEMIOLOGY`, … for STD-HIV; `BMIRD_Case` /
  `BMIRD_MULTI_VALUE_FIELD` / `ANTIMICROBIAL` for BMIRD) keyed off the
  fact row, and projects/CASEs their columns. Most of those `D_INV_*`
  dimensions are **MasterETL-only** (no RTR ODSE path — see
  `catalog/odse_unknown_tables.md` and the STD coverage report's "Key
  takeaway"); the Tier-3 fixtures hand-author the dimension rows
  directly so the datamart join lights up.

Cross-subject person/provider/org columns on every table (PATIENT_NAME,
CURRENT_SEX, PHYSICIAN_*, REPORTER_*, HOSPITAL_*, ORGANIZATION_*, …)
resolve through `D_PATIENT` / `D_PROVIDER` / `D_ORGANIZATION`, which are
populated by their own entity-dim pipelines (MasterETL-side for the
persistent dims). They are flagged `MASTERETL_ONLY` in the appendix
because there is no static TB/STD/BMIRD/Var ODSE→column chain for them —
their lineage belongs to L5 (people/links/dims).

**Status accounting** (1,427 rows): VERIFIED 84, INFERRED 1,156,
MASTERETL_ONLY 174, BLOCKED:#12 13. The high INFERRED count is expected
and honest: the PAM pivots and dimensional joins *map* every column, but
the full-chain fixtures author a deliberately minimum-viable set of
questions/dimension columns to prove each SP runs end-to-end. The
remaining columns are reachable in principle by authoring more PAM
questions / `D_INV_*` columns (a fixture-completeness exercise, not an
infrastructure block) — so they are INFERRED (SP clearly maps them, no
fixture proves the specific column), never confabulated.

---

### D_TB_PAM (166 cols) — `sp_nrt_d_tb_pam_postprocessing`

`D_TB_PAM` is the TB RVCT PAM dimension. The SP filters
`nrt_page_case_answer` to the investigation's `INV_FORM_RVCT` answers
(`data_location = 'NBS_Case_Answer.answer_txt'`, `ldf_status_cd IS NULL`,
`datamart_column_nm` present, minus a 13-question exclusion list), joins
`nrt_srte_codeset_group_metadata` + `nrt_srte_code_value_general` to
translate coded answers, then `PIVOT`s `MAX(ANSWER_TXT) FOR
DATAMART_COLUMN_NM` over the explicit ~158-column IN-list (SP lines
305-359). Every pivot column maps to one TUB question's `answer_txt`;
the ODSE source is `nbs_odse.dbo.nbs_case_answer.answer_txt` tagged by
`nbs_question.datamart_column_nm` / `question_identifier`.

Surrogate/business keys: `D_TB_PAM_KEY` is allocated from the
`nrt_d_tb_pam_key` keystore; `TB_PAM_UID` is the page-case `act_uid`
(= `public_health_case_uid`); `LAST_CHG_TIME` is `MAX(last_chg_time)`
over the answers. Three columns are **computed**, not raw pivots:
`CALC_DISEASE_SITE` (CASE over the multi-value DISEASE_SITE answers →
Pulmonary/Extrapulmonary/Both, SP lines 807-873), `INIT_DRUG_REG_CALC`
(count of `INIT_REGIMEN_*` answers = 'Yes'), and `TB_VERCRIT_CALC_IND`.

Coverage (`coverage_tb_full_chain.md` + the later `zz_tb_datamart_enrich`
expansion → 161/166 in `coverage_merged.md`): the fixture proves the
key/UID/time columns, `CALC_DISEASE_SITE`, `HOMELESS_IND`,
`INIT_REGIMEN_*`, `CASE_VERIFICATION`, `INIT_DRUG_REG_CALC`, and the
three HIV_* columns (TUB154/155/156, via `sp_nrt_d_tb_hiv_postprocessing`).
The remaining pivot columns are INFERRED — fed by TUB questions the
minimum-viable fixture did not author.

### TB_DATAMART (318 cols) — `sp_tb_datamart_postprocessing`

`TB_DATAMART` is the flattened TB case mart. It joins `F_TB_PAM` to
`D_TB_PAM` (the pivot above), the 11 TB topic-group dimensions
(`D_DISEASE_SITE`, `D_ADDL_RISK`, `D_MOVE_*`, `D_GT_12_REAS`,
`D_HC_PROV_TY_3`, `D_SMR_EXAM_TY`, `D_OUT_OF_CNTRY`, `D_MOVED_WHERE`),
`D_PATIENT` / `D_PROVIDER` / `D_ORGANIZATION`, `INVESTIGATION`,
`confirmation_method_group`, and `notification_event`/`notification`.
Clinical TB columns therefore inherit the PAM page-answer lineage
through `D_TB_PAM`; multi-value topic columns inherit from the topic
dimensions' `VALUE` (also page-answer fed); person/provider/org columns
are MASTERETL_ONLY.

Notable gating/transform: confirmation columns come from a `LEFT JOIN`
on `confirmation_method_group` keyed by `INVESTIGATION_KEY`. The TB
coverage report flags an **RTR bug**: `sp_tb_datamart_postprocessing`
has an INSERT-only path with no DELETE/MERGE guard, so re-running for
the same PHC produces duplicate rows (row-count integrity issue for the
diff tool, not a populated-state block). Verified columns are the
INVESTIGATION/disease/case-status anchors plus the D_TB_PAM-derived
clinical columns the enrich fixture lit up.

### TB_HIV_DATAMART (322 cols) — `sp_tb_hiv_datamart_postprocessing`

`TB_HIV_DATAMART` is essentially a re-projection of `TB_DATAMART` for
the TB-HIV co-infection view: its only source tables are `TB_DATAMART`,
`D_TB_PAM`, `D_TB_HIV`, and `INVESTIGATION`. Most columns mirror
`TB_DATAMART` one-for-one (same lineage; INFERRED unless TB_DATAMART
proved them), and the `HIV_*` columns come from `D_TB_HIV`
(`HIV_STATUS`, `HIV_STATE_PATIENT_NUM`, `HIV_CITY_CNTY_PATIENT_NUM`),
which `sp_nrt_d_tb_hiv_postprocessing` pivots from `nrt_page_case_answer`
questions TUB154/155/156 — a verified PAM path. Person/provider/org
columns inherited from TB_DATAMART are MASTERETL_ONLY. Same
duplicate-INSERT bug as TB_DATAMART.

### VAR_DATAMART (233 cols) — `sp_var_datamart_postprocessing`

Varicella mart, structurally the TB twin. It joins `F_VAR_PAM` to
`D_VAR_PAM` (the Varicella PAM pivot, SP 215, `INV_FORM_VAR` answers,
IN-list at SP lines 263-301), the two Varicella topic dimensions
`D_RASH_LOC_GEN` and `D_PCR_SOURCE` (fed by VAR105 / VAR176), plus
`D_PATIENT` / `D_PROVIDER` / `D_ORGANIZATION`, `INVESTIGATION`,
`confirmation_method_group`, `notification`. Clinical Varicella columns
trace to `nbs_case_answer.answer_txt` via the D_VAR_PAM pivot.

Key gating predicate: `VAR_DATAMART` is gated by
`INNER JOIN EVENT_METRIC e ON e.EVENT_UID = d.VAR_PAM_UID` (SP line 692).
`EVENT_METRIC` is empty in a Tier-1-isolation run, so VAR_DATAMART only
populates after the orchestrator's Step 9 runs
`sp_event_metric_datamart_postprocessing` first
(`coverage_varicella_full_chain.md`). Unlike TB, VAR_DATAMART's INSERT
has a `WHERE D.INVESTIGATION_KEY IS NULL` idempotency guard. Verified
columns are the ~25 the full-chain + enrich fixtures authored
(VARICELLA_VACCINE, RASH_LOCATION, lab-test flags, etc.); the rest of
the ~110 VAR questions are INFERRED.

### STD_HIV_DATAMART (248 cols) — `sp_std_hiv_datamart_postprocessing`

The STD/HIV mart uses the **dimensional** pattern, not a PAM pivot. The
SP runs a wide guarded UPDATE/INSERT (every column is `Guarded=yes` in
the catalog) that `LEFT JOIN`s `F_STD_PAGE_CASE` to the `D_INV_*` family
(`D_INV_ADMINISTRATIVE` → `ADM_*`/`ADI_*`, `D_INV_CLINICAL` → `CLN_*`,
`D_INV_COMPLICATION` → `CMP_*`, `D_INV_EPIDEMIOLOGY` → `EPI_*`),
`INV_HIV` → `HIV_*` (which `sp_f_std_page_case`/this SP populate from
the hand-authored `D_INV_HIV` via `L_INV_HIV`), `D_PATIENT`,
`D_PROVIDER`, `D_CASE_MANAGEMENT`, `INVESTIGATION`, and
`CONFIRMATION_METHOD_GROUP`. Column→source is by prefix (HIV_/ADM_/CLN_/
CMP_/EPI_/CA_).

The `D_INV_*` and `L_INV_*` tables are **MasterETL-only** persistent
dimensions: no RTR SP populates them from ODSE, so the STD fixture
authors them by hand and the datamart join reads them. Consequently the
~190 columns sourced purely from a `D_INV_*` dimension are flagged
`MASTERETL_ONLY` (their value lands via a hand-authored fixture row, not
an ODSE→staging→column chain). The VERIFIED set is the ~30 columns the
fixture's five authored dimensions lit up
(`coverage_std_hiv_full_chain.md`): the HIV_* block, a handful of
CLN_/ADM_/CMP_/EPI_ columns, and the INVESTIGATION/condition/MMWR/
confirmation anchors. Transforms of note: `CALC_5_YEAR_AGE_GROUP`
(CASE ladder over `D_PATIENT.PATIENT_AGE_REPORTED`) and `PATIENT_NAME`
concatenation. Two RTR bugs surfaced here — sentinel
`CONFIRMATION_METHOD_GROUP` rows doubling the join cardinality, and an
orchestrator `@phc_ids` vs `@phc_id_list` parameter-name mismatch
(both documented in the coverage report).

### BMIRD_STREP_PNEUMO_DATAMART (140 cols) — `sp_bmird_strep_pneumo_datamart_postprocessing`

The invasive Strep pneumoniae mart is **observation-derived**. Upstream,
`sp_bmird_case_datamart_postprocessing` (SP 040) builds `BMIRD_Case` /
`BMIRD_MULTI_VALUE_FIELD` / `ANTIMICROBIAL` via **dynamic SQL** keyed on
`nrt_srte_IMRDBMapping` (`RDB_TABLE='BMIRD_Case'`), reading the
`nrt_observation*` staging tables (coded/text/numeric/date) that
`sp_observation_event` projects from `nbs_odse.dbo.observation`. SP 140
then `LEFT JOIN`s `BMIRD_Case` (via `v_nrt_inv_keys_attrs_mapping`),
`BMIRD_MULTI_VALUE_FIELD`, `ANTIMICROBIAL`, `D_PATIENT`,
`D_ORGANIZATION`, `INVESTIGATION`, `CONDITION`, `EVENT_METRIC`, and
CASE/pivots the BMD answers into the wide datamart row (e.g.
`TYPE_INFECTION_BACTEREMIA` = CASE WHEN `BM_INFEC_TYPE` …, SP ~line 797;
`EVENT_DATE` = CASE over illness-onset/diagnosis dates).

Three column groups stand out:

- **BLOCKED:#12 (13 cols)** — `UNDERLYING_CONDITION_2..8`,
  `NON_STERILE_SITE_2..3`, `ADD_CULTURE_1_SITE_2..3`,
  `ADD_CULTURE_2_SITE_2..3`. These are the `_2`+ slots of the
  multi-value pivot. Bug #12
  (`bugs/12_bmird_case_datamart_row_number_partition/findings.md`): SP
  040's `ROW_NUMBER() OVER (PARTITION BY public_health_case_uid,
  branch_id ...)` includes `branch_id` in the partition, so every branch
  is alone → `row_num` always 1 → `BMIRD_MULTI_VALUE_FIELD` collapses to
  one row per investigation and only the `_1` slot fills, no matter how
  many answers are authored. Reachable in principle; capped by the bug.
- **ANTIMICROBIAL pivot (~40 cols)** — `ANTIMICROBIAL_AGENT_TESTED_1..8`,
  `SUSCEPTABILITY_METHOD_*`, `MIC_*`, etc. Require root/branch
  Antimicrobial observations (`ANTIMICRO_GAP` in the coverage report);
  out of scope for the current fixture → INFERRED.
- **Verified (~25 cols)** — the single-slot BMD answers and
  INVESTIGATION/condition anchors the full-chain + enrich fixtures
  proved (BACTERIAL_SPECIES_ISOLATED, OXACILLIN_*, CULTURE_SEROTYPE,
  VACCINE_*, HOSPITALIZED_*, EVENT_DATE, MMWR_*, etc.).

Person (`D_PATIENT`) and hospital/reporter (`D_ORGANIZATION`) columns
are MASTERETL_ONLY. SP 140 also has the same INSERT-without-DELETE
re-runnability bug noted for TB/Var (a `WHERE tgt IS NULL` anti-join
that prevents re-INSERT but never updates stale columns).

---

#### Cross-cutting notes

- **No PAM/datamart SP reads `nbs_odse` directly.** ODSE columns in the
  appendix are the `sp_investigation_event` / `sp_observation_event`
  projection that feeds `nrt_page_case_answer` / `nrt_observation*`.
- **`MASTERETL_ONLY` here means "no RTR ODSE chain for this column"** —
  it is sourced from a persistent dimension (`D_PATIENT`, `D_PROVIDER`,
  `D_ORGANIZATION`, `D_INV_*`, `L_INV_*`) that RTR joins but does not
  populate from ODSE. For STD/HIV the Tier-3 fixture hand-authors the
  `D_INV_*`/`L_INV_*` rows so the join resolves.
- **INFERRED is the honest default** for the many PAM/BMD questions and
  `D_INV_*` columns that each SP maps but the minimum-viable fixtures did
  not author a feeder for. None were confabulated to VERIFIED.
- **Re-runnability bug** (TB_DATAMART, TB_HIV_DATAMART,
  BMIRD_STREP_PNEUMO_DATAMART): INSERT-only / anti-join INSERT with no
  DELETE-first or MERGE — duplicate or stale rows on replay.
  VAR_DATAMART and the DELETE-then-INSERT marts are safe.

---

## L4 — COVID family lineage

Cluster: `COVID_CASE_DATAMART`, `COVID_CONTACT_DATAMART`,
`COVID_VACCINATION_DATAMART`, `INV_SUMM_DATAMART`.

Writing SPs (all `datamart_postprocessing`, no `_event` partner — they read
RDB_MODERN-side staging / dimensions only, per STRATEGY.md "postprocessing SPs
read NRT staging only"):

| SP | File | Target |
| --- | --- | --- |
| `sp_covid_case_datamart_postprocessing` | `routines/310-...` | `COVID_CASE_DATAMART` |
| `sp_covid_contact_datamart_postprocessing` | `routines/315-...` | `COVID_CONTACT_DATAMART` |
| `sp_covid_vaccination_datamart_postprocessing` | `routines/320-...` | `COVID_VACCINATION_DATAMART` |
| `sp_inv_summary_datamart_postprocessing` | `routines/045-...` | `INV_SUMM_DATAMART` |

The three COVID SPs all gate on COVID condition code `'11065'`. The
`INV_SUMM_DATAMART` SP is condition-agnostic (it summarises every active
investigation). The ODSE→staging hop for the COVID case/contact SPs is the
debezium projection of `sp_investigation_event` (056), `sp_patient_event`
(054), `sp_contact_record_event` (069) and `sp_vaccination_event` (071); the
postprocessing SPs themselves never touch `nbs_odse.dbo.*`. `INV_SUMM_DATAMART`
sits one tier further downstream — it reads only RDB_MODERN dimensions/facts
(`INVESTIGATION`, `D_PATIENT`, `D_PROVIDER`, `NOTIFICATION`, the per-condition
`*_CASE` fact tables, `CASE_LAB_DATAMART`, `lab100`), each of which is itself
built by an upstream `sp_nrt_*`/`sp_d_*`/`sp_f_*` SP — so its ODSE roots are
recorded transitively (INVESTIGATION → `nrt_investigation` → ODSE
`public_health_case`).

Live coverage (coverage_merged.md, 2026-05-25 clean run):
`covid_case_datamart` 379/383, `covid_contact_datamart` 89/94,
`covid_vaccination_datamart` 60/60, `inv_summ_datamart` 58/58.

---

### COVID_CASE_DATAMART

Row flow: `sp_covid_case_datamart_postprocessing @phc_uids` builds `#PHC_LIST`
by joining `NRT_INVESTIGATION` to the CSV of PHC UIDs filtered on
`nrtInv.cd = '11065'` (Step 1). It is idempotent: DELETE-then-INSERT per PHC,
and drops `LOG_DEL` rows before insert. It then assembles three static temp
tables and up to five dynamic ones, and finally builds the INSERT itself as
dynamic SQL.

The **statically traceable** columns come from three temp tables:

- `#COVID_CASE_CORE_DATA` (Step 4) — `NRT_INVESTIGATION phc` columns mapped
  near-1:1 to datamart columns (`phc.CD→CONDITION_CD`,
  `phc.JURISDICTION_CD→JURISDICTION_CD`, `phc.ACTIVITY_FROM_TIME→INV_START_DT`,
  `phc.CASE_CLASS_CD→INV_CASE_STATUS`, `phc.MMWR_WEEK/YEAR`, the
  `HOSPITALIZED_*`, `EFFECTIVE_*`, `OUTCOME_CD→DIE_FROM_ILLNESS_IND`, etc.).
  `NRT_INVESTIGATION` is the debezium projection of `sp_investigation_event`,
  whose primary FROM is `nbs_odse.dbo.public_health_case phc` (event SP
  line 335), so the ODSE source for every core column is the same-named
  `public_health_case` column. `NOTIFICATION_SUBMIT_DT / SENT_DT /
  LOCAL_ID` come from `NRT_INVESTIGATION_NOTIFICATION`; `CONFIRMATION_METHOD /
  _DT` from a `STRING_AGG` over `NRT_INVESTIGATION_CONFIRMATION` joined to
  `NRT_SRTE_CODE_VALUE_GENERAL` (codeset `PHC_CONF_M`); `JURISDICTION_NM` from
  `NRT_SRTE_JURISDICTION_CODE`.
- `#COVID_PATIENT_DATA` (Step 5) — joins `D_PATIENT pat` (built by
  `sp_d_patient`/`sp_patient_event` from ODSE `person`) on
  `inv.patient_id`, plus `NRT_PATIENT nrtPat` (status `'A'`, name-use `'L'`)
  for the codeset-unit fields (`AGE_REPORTED_UNIT_CD`, `DECEASED_IND_CD`,
  `MARITAL_STATUS_CD`, `STATE_CODE`, `COUNTY_CODE`, `COUNTRY_CODE`,
  `ETHNIC_GROUP_IND`).
- `#COVID_ENTITIES_DATA` (Step 6) — resolves the soft-ref FKs on
  `NRT_INVESTIGATION` (`investigator_id`, `physician_id`,
  `person_as_reporter_uid`, `organization_id`, `hospital_uid`) against
  `D_PROVIDER` / `D_ORGANIZATION` to produce `PHC_INV_*`, `PHYS_*`,
  `RPT_PRV_*`, `RPT_ORG_*`, `HOSPITAL_NAME`. These were the columns the
  round-1 fixture left NULL; `zz_covid_case_datamart_round2.sql` adds the
  provider/org rows and re-points the FKs to light them up.

The **form-driven** columns (the overwhelming majority — ~440 of them) are
not in any DDL. Steps 7/10/13 run `ALTER TABLE COVID_CASE_DATAMART ADD <col>
varchar(2000|8000)` for every `user_defined_column_nm` discovered in
`NRT_ODSE_NBS_RDB_METADATA ⋈ NRT_ODSE_NBS_UI_METADATA` for
`investigation_form_cd = 'PG_COVID-19_v1.1'`; Steps 8/11/14 PIVOT
`NRT_PAGE_CASE_ANSWER` (answer value =
`replace(ISNULL(code_short_desc_txt, answer_txt), …)`) keyed on
`nbs_question_uid + act_uid`. Discrete answers (component NOT IN 1013,1025,
`question_group_seq_nbr IS NULL`), multi-string answers (component IN
1013,1025), and three repeating-block slices (`_1/_2/_3`,
`answer_group_seq_nbr`) feed `@tmp_COVID_CASE_DISCRETE/MULTI/RPT_DATA_*`. The
**final INSERT is itself dynamic SQL** — the entire column list is read from
`tempdb.INFORMATION_SCHEMA.COLUMNS` of those temp tables and executed via
`EXEC sp_executesql @insert_query` (lines 1119–1245). These columns are
`DYNAMIC`: their ODSE source is `nbs_odse.dbo.nbs_case_answer.answer_txt` (via
`nrt_page_case_answer`), keyed dynamically by form metadata, not statically
derivable per target column.

> **Surprise / catalog caveat.** `rtr_target_columns.md` lists exactly one
> column for this table — `PATH`, guarded. That is a **parser false-positive**:
> it matched the `FOR XML PATH('')` literal inside the dynamic INSERT-string
> assembly (310-...:551,1128,…), not a real column. COVID_CASE_DATAMART has
> **no static column list at all** — every column is added/inserted via
> dynamic SQL. `PATH` is flagged `DYNAMIC`/parser-artifact in the appendix.

Blocked/skipped: coverage_merged shows 379/383 populated; the round-1
coverage_covid_full_chain.md "deliberately skipped" list (CONFIRMATION_*,
PHC_INV_*/PHYS_*/RPT_*/HOSPITAL_NAME, NOTIFICATION_*) was subsequently
unblocked by round2. The residual ~4 columns are form questions for which no
answer row is authored — reachable by mechanical fixture expansion, not a bug.

### COVID_CONTACT_DATAMART

Row flow (Step 1 single big SELECT … INTO `#COVID_CONTACT_DATAMART`):
`NRT_CONTACT con` INNER JOIN `NRT_INVESTIGATION inv` on
`con.SUBJECT_ENTITY_PHC_UID = inv.public_health_case_uid` (and
`con.RECORD_STATUS_CD <> 'LOG_DEL'`), filtered `inv.cd = '11065'` and
`inv.public_health_case_uid IN STRING_SPLIT(@phcid_list)`. So a contact only
materialises if its **subject** investigation is COVID. This is the gating
predicate that kept the table at 0 rows until `zz_covid_contact.sql` authored
an `nrt_contact` row pointing at COVID PHC 22003000.

The 89-column row is assembled in three families:

- `SRC_*` (index-investigation/patient) — `inv.*` columns
  (`activity_from_time`, `investigation_status_cd`, `case_class_cd`,
  `hospitalized_ind_cd`, `outcome_cd`, `infectious_from/to_date`,
  `contact_inv_*`) and `D_PATIENT pat`/`NRT_PATIENT nrt_pat` for the index
  patient. Four `SRC_INV_*` answer columns come from `NRT_PAGE_CASE_ANSWER`
  by `question_identifier` (`NBS547` CDC-assigned ID, `NOT113` reporting
  county, `INV576` symptomatic, `NBS555` symptom status), batch-id matched.
- `CR_*` (contact record) — `NRT_CONTACT con` columns
  (`CTT_JURISDICTION_NM`, `CTT_STATUS_CODE`, `CTT_PRIORITY`,
  `CTT_INV_ASSIGNED_DT`, `CTT_DISPOSITION`, `CTT_NAMED_ON_DT`,
  `CTT_RELATIONSHIP`, `CTT_HEALTH_STATUS`, dates/notes) plus four
  `NRT_CONTACT_ANSWER` joins by `rdb_column_nm`
  (`CTT_EXPOSURE_TYPE/SITE_TYPE`, `CTT_FIRST/LAST_EXPOSURE_DT`). Investigator
  name comes from `D_PATIENT ctt_pat_con`. Many `CR_*` codes resolve through
  `NRT_SRTE_CODE_VALUE_GENERAL` by codeset (`NBS_PRIORITY`, `NBS_DISPO`,
  `NBS_RELATIONSHIP`, `NBS_HEALTH_STATUS`, `YNU`).
- `CTT_*` (contact-as-subject) — a CASE switch: if
  `con.CONTACT_ENTITY_PHC_UID IS NOT NULL` use the contact's own
  investigation/patient (`con_inv` / `ctt_pat_inv`), else fall back to the
  contact-record patient (`ctt_pat_con`). Sex/deceased/country are resolved
  through `v_code_value_general` (DEM113/DEM127/DEM126) fed by an OUTER APPLY
  that picks the same branch.

`NRT_CONTACT` / `NRT_CONTACT_ANSWER` are the debezium projection of
`sp_contact_record_event` (069), whose ODSE source is `nbs_odse.dbo.contact`
(+ `contact`-scoped answers). `NRT_INVESTIGATION` traces to ODSE
`public_health_case` as above; `D_PATIENT`/`NRT_PATIENT` to ODSE `person`.

Blocked/skipped: 89/94 live. Five columns require a fully-attributed contact
investigation (`CONTACT_ENTITY_PHC_UID` branch) not authored in the fixture —
INFERRED, reachable via a second COVID investigation linked as the contact's
own subject. No bug caps this table.

### COVID_VACCINATION_DATAMART

Row flow: `sp_covid_vaccination_datamart_postprocessing @vac_uids,@patient_uids`
builds `#VAC_LIST` from `NRT_VACCINATION` filtered on
`material_cd IN ('207','208','213')` (the COVID vaccine product codes) — that
is the gating predicate, not a condition code. Idempotent DELETE-then-INSERT
keyed on `local_id`; `LOG_DEL` dropped. The INSERT is `INSERT INTO
COVID_VACCINATION_DATAMART SELECT DISTINCT …` with **no column list** (hence
the catalog's `<all>`), so the 60 targets are positional from the SELECT.

`NRT_VACCINATION` supplies the keys + `INVESTIGATION_DT`
(`COALESCE(nrtinv.activity_from_time, nrtinv.add_time)` via the LEFT JOIN to
`NRT_INVESTIGATION` on `phc_uid`) and `INVESTIGATION_LOCAL_ID`
(`nrtinv.local_id`). Everything else comes from RDB_MODERN dimensions joined
on the CTE soft-refs:

- `D_VACCINATION dvac` (on `vaccination_uid`) — `VACCINATION_ADMINISTERED_NM`,
  `VACCINE_ADMINISTERED_DATE`, `VACCINATION_ANATOMICAL_SITE`,
  `AGE_AT_VACCINATION(_UNIT)`, `VACCINE_MANUFACTURER_NM`,
  `VACCINE_LOT_NUMBER_TXT`, `VACCINE_EXPIRATION_DT`, `VACCINE_DOSE_NBR`,
  `VACCINE_INFO_SOURCE`, `ELECTRONIC_IND`, `RECORD_STATUS_CD`, `LOCAL_ID`,
  add/chg audit columns.
- `D_PATIENT patient` (on `patient_uid`) — all `PATIENT_*`; `PATIENT_BIRTH_SEX`
  via a correlated subselect on `PATIENT_MPR_UID`; `PATIENT_RACE_CALC_DETAILS`
  with `REPLACE(' |',';')`; `PATIENT_COUNTRY` upper-cased.
- `D_PROVIDER provider` / `D_ORGANIZATION org` (on `provider_uid` /
  `organization_uid`) — `PROVIDER_*` / `ORGANIZATION_*`, country upper-cased,
  addr-2 `ISNULL('')`.
- `COVID_VACCINATION_DATAMART_KEY` =
  `CONCAT(vaccination_uid, phc_uid) + RIGHT(YEAR(add_time),2)`.

ODSE roots: `NRT_VACCINATION` ⟶ `sp_vaccination_event` (071) ⟶
`nbs_odse.dbo.intervention` (`vaccination_uid = intervention_uid`,
`material_cd`); `D_VACCINATION` is built from the same intervention chain;
`D_PATIENT`/`D_PROVIDER`/`D_ORGANIZATION` from ODSE `person`/`organization`.

Status: 60/60 live (full). `zz_covid_vaccination_datamart_enrich.sql` authored
a fully-attributed COVID vaccination (patient+provider+org) on top of the
foundation vaccination, which alone left dim-sourced columns NULL. All 60 are
VERIFIED.

### INV_SUMM_DATAMART

This SP is structurally different: **no COVID filter, no `nrt_*` reads** — it
summarises every active investigation (`INVESTIGATION.CASE_TYPE='I'`,
`RECORD_STATUS_CD='ACTIVE'`) whose `CASE_UID` is in `@phc_uids` (or whose
notification was just updated, via `#TMP_UPDATED_INV_WITH_NOTIF`). It runs an
INSERT-new + UPDATE-existing pair, then DELETEs inactive rows, then two
follow-on UPDATEs (EVENT_DATE/specimen, INIT_NND_NOT_DT).

Column families and their RDB_MODERN sources:

- Investigation columns (`INVESTIGATION_KEY/STATUS/LOCAL_ID`, MMWR, dates,
  `CASE_STATUS`, `PROGRAM_AREA`, `PROGRAM_JURISDICTION_OID`,
  `CURR_PROCESS_STATE`, `JURISDICTION_NM`, create/update audit) — the
  `INVESTIGATION` dimension, `SUBSTRING`-truncated to fit. `INVESTIGATION` is
  built by `sp_nrt_investigation_postprocessing` from `nrt_investigation`,
  i.e. ODSE `public_health_case`.
- `PATIENT_KEY`/`PHYSICIAN_KEY` — resolved by a `CASE`/`COALESCE` priority
  ladder across eleven per-condition fact tables (`GENERIC_CASE`, `CRS_CASE`,
  `MEASLES_CASE`, `RUBELLA_CASE`, `HEPATITIS_CASE`, `BMIRD_CASE`,
  `PERTUSSIS_CASE`, `F_TB_PAM`, `F_VAR_PAM`, `F_PAGE_CASE`, `F_STD_PAGE_CASE`)
  — first key > 1 wins. STD vs non-STD branch chosen by
  `count(*) nrt_investigation_case_management`.
- Patient demographics (`PATIENT_FIRST/LAST_NAME`, DOB, sex, age,
  address, county, ethnicity, race, local id) — `D_PATIENT` on `PATIENT_KEY`.
- `PHYSICIAN_FIRST/LAST_NAME` — `D_PROVIDER` on `PHYSICIAN_KEY`.
- `DISEASE`/`DISEASE_CD` — `CASE_COUNT ⋈ condition` (dim) on
  `CONDITION_KEY`.
- `CONFIRMATION_METHOD`/`CONFIRMATION_DT` — `STRING_AGG('|')` over
  `CONFIRMATION_METHOD ⋈ CONFIRMATION_METHOD_GROUP`.
- Notification columns (`NOTIFICATION_STATUS/LOCAL_ID/CREATE_DATE/SENT_DATE/
  SUBMITTER/LAST_UPDATED_*`) — `NOTIFICATION ⋈ NOTIFICATION_EVENT ⋈ RDB_DATE`,
  `ROW_NUMBER() … rn=1` to take the earliest. `INIT_NND_NOT_DT` from a later
  `nrt_investigation_notification` aggregate (`FIRSTNOTIFICATIONSENDDATE`).
- Lab columns (`LABORATORY_INFORMATION`, `EVENT_DATE(_TYPE)`,
  `FIRST_POSITIVE_CULTURE_DT`, `Earliest_specimen_collect_date`) —
  `CASE_LAB_DATAMART` + a `LAB_TEST_RESULT ⋈ LAB_TEST ⋈ lab100` chain;
  `FIRST_POSITIVE_CULTURE_DT` from `BMIRD_CASE`.

Because none of these are `nrt_*` reads, the appendix records the RDB_MODERN
dim/fact column as the proximate source and the transitive ODSE root where it
is unambiguous (investigation/patient/provider → public_health_case/person).
`EVENT_DATE`/`EVENT_DATE_TYPE` originate entirely inside the lab datamart
(L1's CASE_LAB_DATAMART) and are copied here — INFERRED on the COVID side.

Status: 58/58 live (full). `zz_inv_summ_datamart_unblock.sql` corrected the
earlier "chicken-and-egg" misreading (the `@INV_SUMMARY_DATAMART_COUNT > 0`
predicate gates only the optional notif-update temp table, not the main insert)
and supplied the joined dims; all 58 are VERIFIED.

---

## L5 — People, Links & Dimensions

Cluster owned by Agent L5: the core RDB_MODERN dimension and fact tables
for the "people" subjects (`d_patient`, `d_provider`, `d_organization`,
`D_PLACE`), the act-based subjects (`D_INTERVIEW`/`D_INTERVIEW_NOTE`,
`D_VACCINATION`, `D_CONTACT_RECORD`, `NOTIFICATION`, `TREATMENT`,
`MORBIDITY_REPORT` + its datamart), their fact bridges
(`F_VACCINATION`, `F_CONTACT_RECORD_CASE`, `F_INTERVIEW_CASE`,
`NOTIFICATION_EVENT`, `TREATMENT_EVENT`, `MORBIDITY_REPORT_EVENT`,
`morb_Rpt_User_Comment`), **and all Tier-2 link edges** that flip the
cross-subject sentinel keys on those fact tables to real FKs.

Column appendix: `lineage/columns/L5_people_links_dims.tsv` — 532 rows,
one per (table, column) the catalog records for these tables. 526
VERIFIED, 6 DYNAMIC, 0 INFERRED, 0 MASTERETL_ONLY, 0 currently
BLOCKED (bug #03 was the only blocker and is fixed on `aw/odse-test-seed`).

### How to read the chain for this cluster

Every column in this cluster follows the STRATEGY.md convention:

- The `sp_<subject>_event` SP reads `nbs_odse.dbo.*` and projects a JSON
  view. It does **not** write `nrt_*`; in production CDC/Debezium does.
  This is the **ODSE → staging** edge, and it is the column in the
  appendix's `odse_source_col(s)` field.
- The `sp_nrt_<subject>_postprocessing` / `sp_d_<subject>_postprocessing`
  SP reads only RDB_MODERN-side `nrt_*` staging (never ODSE) and writes
  the dimension/fact. This is the **staging → RDB_MODERN** edge and is
  the `nrt_staging_source` + `transform_note` fields.

Because this cluster is the canonical home of the Tier-1 subject
fixtures, the ODSE→staging hop is unusually well documented: each
fixture header and `coverage_<subject>.md` SRTE table names the exact
`person.*` / `postal_locator.*` / `observation.*` column that feeds each
staging field. The appendix's ODSE attributions are synthesised from
those artifacts, not re-derived from SP source.

### The dimension tables (Tier 1)

**`d_patient` (81/81 VERIFIED).** `sp_nrt_patient_postprocessing` reads
`nrt_patient` and writes `D_PATIENT`. The event SP `sp_patient_event`
projects `nbs_odse.dbo.Person` plus its locator children
(`Entity_locator_participation` → `Postal_locator` / `Tele_locator`),
`person_name`, `person_race` (via the nested `sp_patient_race_event`),
and `entity_id`. Notable transforms: nearly every demographic `*_cd`
resolves to a description through `fn_get_value_by_cd_ques` against a
named code set (e.g. `birth_gender_cd`→SEX via DEM114,
`deceased_ind_cd`→YNU via DEM127); addresses pivot on
`entity_locator_participation.use_cd`/`cd` (`H`/`BIR`/`NET`/`CP`); the
postprocessing SP applies a uniform `blank → NULL` guard
(`004-...:41-170`). The 25-column race breakdown (`PATIENT_RACE_*_1/2/3/
GT3_IND/ALL` across five categories) is rolled up from `person_race.race_cd`
rows keyed by `parent_is_cd='ROOT'` + detail rows. The fixture exercises
all paths across three variants (foundation = null/blank path, v2 =
fully attributed multi-race, v3 = deceased branch).

**`d_provider` (34/34 VERIFIED)** and **`d_organization` (30/30
VERIFIED)** follow the same Person/Organization → locators → name →
entity_id shape via `sp_provider_event` / `sp_organization_event` into
`nrt_provider` / `nrt_organization`. Provider keys off `person.cd='PRV'`;
Organization sources its name from `organization_name` and its
`FACILITY_ID`/`STAND_IND_CLASS` from `entity_id` (CLIA) and the NAICS
code set. **Bug #04** (`#PATIENT_UPDATE_LIST` typo in
`sp_nrt_provider_postprocessing` line 564) is flagged on
`PROVIDER_LAST_UPDATED_BY` but is *not* a coverage blocker — it only
fires on the UPDATE-with-diff re-run path, the INSERT path used by the
fixture is clean, and the fix is already merged on main (PR #826).

**`D_PLACE` (37/37 VERIFIED).** `sp_nrt_place_postprocessing` reads
`nrt_place` (sourced from `nbs_odse.dbo.Place` + `Entity_id` + locators
via `sp_place_event`) and emits **four UNION-ALL variants** per
`place_uid` — Base / Postal-only / Tele-only / Postal+Tele — so a single
place can produce up to four `D_PLACE` rows. `PLACE_LOCATOR_UID` is a
composite `<place_uid>^<postal_uid>^<tele_uid>` key; `PLACE_ADDED_BY` /
`PLACE_LAST_UPDATED_BY` both join `USER_PROFILE` on `place_add_user_id`
(the SP uses `add_user_id` for both, never `last_chg_user_id`).

**`D_VACCINATION` (21 clinical VERIFIED + 2 DYNAMIC).**
`sp_d_vaccination_postprocessing` reads `nrt_vaccination` (projected from
`nbs_odse.dbo.INTERVENTION` by `sp_vaccination_event`). Clinical columns
use a `NULLIF(x,'')` blank-to-NULL idiom; `VACCINATION_ADMINISTERED_NM`
resolves `material_cd` through the VAC_NM code set. `RDB_COLUMN_NM` and
`THEN` are dynamic-PIVOT helper columns for LDF answers
(`V_RDB_UI_METADATA_ANSWERS_VACCINATION`), gated by
`nrt_metadata_columns(D_VACCINATION)` being non-empty — empty at baseline,
so flagged **DYNAMIC**.

**`D_INTERVIEW` (18 VERIFIED + 2 DYNAMIC) / `D_INTERVIEW_NOTE` (7/7
VERIFIED).** `sp_d_interview_postprocessing` reads `nrt_interview` /
`nrt_interview_note` (from `nbs_odse.dbo.INTERVIEW` via
`sp_interview_event`). The four `IX_*_CD`→`IX_*` description pairs resolve
through SRTE. The note table sources `USER_COMMENT` / author name / date
from the interview-note answer observations. Six live LDF columns
(IX_CONTACTS_NAMED_IND etc.) are dynamic-PIVOT and not in the catalog
write-set, hence not in this appendix; the two catalog dynamic helpers
(`RDB_COLUMN_NM`, `THEN`) are flagged DYNAMIC.

### The act-based dimensions with transform logic

**`NOTIFICATION` (6/6) / `NOTIFICATION_EVENT` (8/8) VERIFIED.**
`sp_nrt_notification_postprocessing` reads `nrt_investigation_notification`
(projected from `nbs_odse.dbo.notification` joined through
`act_relationship` → `public_health_case` by `sp_notification_event`).
At Tier-1 isolation the chain rolls back because `NOTIFICATION_EVENT`'s
`INVESTIGATION_KEY` has no resolvable PHC; the `inv_notification`
Tier-2 edge resolves it (see Tier-2 below). The three `*_DT_KEY` columns
join `RDB_DATE`; `CONDITION_KEY` joins `dbo.condition` (populated by the
infrastructure SP `sp_nrt_srte_condition_code_postprocessing`).

**`TREATMENT` (16/16) / `TREATMENT_EVENT` (11/11) VERIFIED.**
`sp_nrt_treatment_postprocessing` reads `nrt_treatment` (from
`nbs_odse.dbo.treatment` + `Treatment_administered` via
`sp_treatment_event`). Drug attributes resolve through TREAT_* code sets;
`CUSTOM_TREATMENT` is a `CASE WHEN cd='OTH'` branch (exercised by the v3
fixture variant); `RECORD_STATUS_CD` is pass-through (unlike Morbidity,
which transforms `PROCESSED→ACTIVE`). All eight cross-subject FK columns
on `TREATMENT_EVENT` `COALESCE(...,1)` to sentinel 1 at isolation; with
no FK constraints the INSERT succeeds at sentinel, then `treatment_inv`
flips them.

**`MORBIDITY_REPORT` (30/30), `MORBIDITY_REPORT_EVENT` (17/17),
`morb_Rpt_User_Comment` (8/8) VERIFIED.**
`sp_d_morbidity_report_postprocessing` (defined in the misleadingly-named
`016-sp_nrt_morbidity_report_postprocessing` file) reads `nrt_observation`
+ `nrt_morbidity_observation` + `nrt_observation_txt` (from
`nbs_odse.dbo.observation` + `obs_value_coded/txt/date` via
`sp_observation_event`). The "Order" observation is the morb root; ~16
INV*/MRB* follow-up observations are reached via the
`followup_observation_uid` CSV and pivoted into the dimension's clinical
columns (e.g. INV128→`HOSPITALIZED_IND`, MRB165→`DIAGNOSIS_DT`).
`MORBIDITY_REPORT_EVENT.PATIENT_KEY` is NOT-NULL with **no** COALESCE, so
at Tier-1 isolation the EVENT INSERT fails until the Patient chain has
populated `D_PATIENT` — a `LINK_REQUIRED` resolved by running the Patient
chain + the `morb_inv` edge.

`morb_Rpt_User_Comment` was **BLOCKED:#03** in pristine baseline: the SP's
user-comment temp-table query (lines 802-816) had a self-defeating join
(`root.morb_rpt_uid = obs.observation_uid` binds the Order to itself,
then filters `obs_domain_cd_st_1 IN ('C_Order','C_Result')` which the
Order can never satisfy), so 0 rows ever inserted. The fix (rewrite to
walk Order→C_Order→C_Result via the staging `followup_observation_uid`
CSV, staying inside RDB_MODERN per the postprocessing-reads-NRT
convention) is **squashed onto `aw/odse-test-seed`** (`[SQUASH bug-3]`,
upstream PR #837). On this branch the 8 columns populate end-to-end, so
they are recorded **VERIFIED** with a `bugs/03` cross-reference in the
transform note; revert the fix and they return to BLOCKED:#03.

**`MORBIDITY_REPORT_DATAMART` (133/133 VERIFIED).** The only datamart in
this cluster. `sp_morbidity_report_datamart_postprocessing` has **no
event-SP partner** — it reads exclusively from already-populated
RDB_MODERN tables: `MORBIDITY_REPORT`/`_EVENT` as the spine, dimension
joins to `D_PATIENT` / `D_PROVIDER` (physician + reporter) /
`D_ORGANIZATION` (report-facility + hospital) / `INVESTIGATION` /
`CONDITION` / `RDB_DATE`, plus `ROW_NUMBER()` `_1/_2/_3` pivots over
`LAB_TEST`/`LAB_TEST_RESULT`/`LAB_RESULT_VAL`/`LAB_RESULT_COMMENT` (lab
columns) and `TREATMENT_EVENT`/`TREATMENT` (treatment columns). Patient
and provider demographic columns are also overlaid by the two
`sp_*_dim_columns_update_to_datamart` SPs. Their *ultimate* ODSE origin
is therefore the same `person`/`observation`/`treatment` columns
documented on the dimension rows above (the appendix points back to
those rows rather than restating the chain). Verified at 133/133 by the
Tier-3 `zz_morbidity_report_datamart_enrich.sql` fixture, which authors a
third fully-attributed morbidity report with 3 labs + 3 treatments to
land every `_1/_2/_3` suffix.

### The fact bridges and the sentinel → FK flip (Tier 2)

The fact tables (`F_VACCINATION`, `F_CONTACT_RECORD_CASE`,
`F_INTERVIEW_CASE`, `NOTIFICATION_EVENT`, `TREATMENT_EVENT`,
`MORBIDITY_REPORT_EVENT`) all carry cross-subject surrogate-key columns
(`PATIENT_KEY`, `*_PROVIDER_KEY`, `*_ORGANIZATION_KEY`,
`INVESTIGATION_KEY`, etc.). At Tier-1 isolation the dimension tables hold
no matching row, so the postprocessing SP resolves each via
`COALESCE(<dim>.<KEY>, 1)` to **sentinel 1** (or, where there is no
COALESCE, NULL — which either is allowed or blocks the INSERT, as with
Morbidity's PATIENT_KEY). The fact INSERT succeeds at sentinel; the value
is wrong but the shape is right.

**Tier-2 edges flip the sentinel to a real FK.** There are two mechanisms,
and the distinction is load-bearing for this cluster:

1. **`act_relationship` edges mirrored via a staging soft-ref UPDATE.**
   For Notification, Lab, Morbidity and Treatment, the postprocessing SP
   resolves `INVESTIGATION_KEY` (and CONDITION/MORB keys) by joining
   `dbo.INVESTIGATION` on a PHC UID it reads from a *staging* column —
   `nrt_observation.associated_phc_uids` or
   `nrt_investigation_notification.public_health_case_uid`. The Tier-2
   fixture authors the `act_relationship` row (e.g.
   `MorbReport`/`LabReport`/`Notification`/`TreatmentToPHC`,
   `source_class_cd`/`target_class_cd` matching the event-SP filter)
   **and** issues an UPDATE on that `nrt_*.associated_phc_uids` column to
   mirror what CDC would have projected, then re-EXECs the postprocessing
   SP. On the re-run the join resolves and the key flips from 1 to the
   real `INVESTIGATION_KEY`. This is genuine RDB_MODERN coverage-unlock:
   `inv_notification` flips NOTIFICATION_EVENT.INVESTIGATION_KEY,
   `morb_inv` flips MORBIDITY_REPORT_EVENT (and unblocks the whole EVENT
   INSERT), `treatment_inv` flips TREATMENT_EVENT.INVESTIGATION_KEY +
   CONDITION_KEY for foundation/v3, `lab_inv` (L1's table) the analogous
   lab keys.

2. **`participation` / `nbs_act_entity` edges — JSON-projection-only at
   the postprocessing layer.** `patient_phc` (SubjOfPHC),
   `reporter_phc` (Per/OrgAsReporterOfPHC), `physician_phc`
   (Physician/InvestgrOfPHC), `phc_roles_nae` (NAE role edges),
   `interview_links` (Intrvwer/Intrvwee/OrgAsSiteOfIntv NAE),
   `contact_links` (SiteOfExposure/InvestgrOfContact/DispoInvestgr NAE),
   `vaccination_links` (SubOfVacc/PerformerOfVacc NAE) all author the
   connective rows correctly and flip the **event-SP JSON projection**
   (verified pre/post), but they do **not** flip any RDB_MODERN dim/fact
   column at the postprocessing layer — because the postprocessing SPs
   read the cross-subject UID from a `nrt_*` soft-ref column (hand-authored
   by Tier 1), never from the graph table. So `F_VACCINATION`,
   `F_CONTACT_RECORD_CASE`, `F_INTERVIEW_CASE` keys resolve through their
   own dimension joins in the merged sequence (after Patient/Provider/Org/
   Investigation/Interview chains run), and these NAE/participation edges
   are documented as *shape-consistency* (they keep the ODSE graph
   honest and unlock the Datamart-layer F_PAGE_CASE INNER JOINs at Merge
   step 9, which is L6/datamart territory). Several of the edge `type_cd`
   values (`IXS`, `SiteOfExposure`, `TreatmentToMorb`, etc.) are
   `MISSING_FROM_SRTE` but the RTR event SPs filter on the literal anyway,
   so the fixtures author them with the literal value per the Phase-B
   "MISSING_FROM_SRTE used anyway" policy.

In the appendix, fact-table FK columns are attributed to the staging
soft-ref the SP actually reads, with the transform note recording the
`sentinel-1 -> FK` flip and which Tier-2 fixture (or merged-sequence
chain) performs it.

### Blocked / skipped / dynamic columns

- **DYNAMIC (6):** `D_VACCINATION.RDB_COLUMN_NM`, `D_VACCINATION.THEN`,
  `D_INTERVIEW.RDB_COLUMN_NM`, `D_INTERVIEW.THEN`,
  `D_CONTACT_RECORD.RDB_COLUMN_NM`, `D_CONTACT_RECORD.THEN`. These are
  dynamic-PIVOT helper columns driven by `nrt_metadata_columns` /
  `v_rdb_ui_metadata_answers` page-builder metadata, empty at baseline.
  The associated live LDF columns (23 on D_CONTACT_RECORD, 6 on
  D_INTERVIEW) are NOT in the catalog write-set and are deferred to a
  Tier-3 LDF fixture; they are out of scope for this appendix per the
  catalog-driven row set.
- **BLOCKED:#03 (resolved):** the 8 `morb_Rpt_User_Comment` columns —
  blocked in pristine baseline, VERIFIED on `aw/odse-test-seed` where the
  bug-3 fix is squashed in. Recorded VERIFIED with the bug cross-reference.
- **Bug #02** (`sp_contact_record_event` 3-part-name error) and **bug #04**
  (provider UPDATE-path typo) touch this cluster but block **no** columns:
  #02 is bypassed because `sp_d_contact_record_postprocessing` reads
  `nrt_contact` directly (and the bug is fixed on main, PR #769); #04 only
  fires on the UPDATE-diff re-run, not the INSERT path (fixed on main,
  PR #826). Both are noted in the relevant transform notes, not flagged
  BLOCKED.
- **No MASTERETL_ONLY columns** in this cluster — every column has a real
  RTR SP write path and a fixture/coverage proof.

---

## L6 — Investigation-repeat, LDF, dyn_dm, page-builder

**Cluster**: `d_investigation_repeat`, `d_inv_place_repeat`, `f_page_case`,
the `ldf_*` family (`ldf_data`, `ldf_group`, `ldf_dimensional_data`,
`d_ldf_meta_data`, `ldf_datamart_column_ref`, the per-condition
`ldf_foodborne/tetanus/mumps/vaccine_prevent_diseases/bmird/hepatitis`,
and the `*_ldf_group` link tables), `summary_report_case` /
`summary_case_group`, `lookup_table_n_rept`, and `aggregate_report_datamart`.
Plus the `dyn_dm_*` SP family, which writes **dynamically-named** datamart
tables and so contributes no statically-enumerable RDB_MODERN columns of
its own.

**Governing characteristic of this cluster**: it is the *page-builder /
dynamic-SQL* corner of RTR. The bulk of the columns here are not produced
by a static `ODSE col → staging col → target col` projection. They are
materialized at runtime by dynamic `ALTER TABLE … ADD` loops and dynamic
`PIVOT` / `UNPIVOT` statements keyed on **page-builder metadata** —
`nrt_page_case_answer` rows (the staging projection of `nbs_page_answer` /
`nbs_ui_metadata`) for the repeating-block dims, and
`nrt_odse_state_defined_field_metadata` (the projection of ODSE
`state_defined_field*`) for the LDF chain. The guardrail in `LINEAGE.md`
applies in full: for these columns the appendix records the **driving
mechanism** and a `DYNAMIC` status rather than forcing a per-column ODSE
map. Per STRATEGY.md, none of these postprocessing/datamart SPs read
`nbs_odse.dbo.*` directly — they read RDB_MODERN-side staging (`nrt_*`)
and already-built dimensions.

This cluster is heavily bug-capped. Bugs #06–#11 and #13 each cap a
specific column set; affected rows carry `BLOCKED:#NN`.

---

### d_investigation_repeat (+ lookup_table_n_rept, l_investigation_repeat*)

`sp_sld_investigation_repeat_postprocessing` is the repeating-block pivot
SP. It reads **only** `nrt_page_case_answer` (joined to `nrt_investigation`
on `act_uid = public_health_case_uid`) and writes the repeating-block dim
plus its lookup/link tables — no participation or act_relationship walk.
For each Investigation whose `investigation_form_cd` is **not** in the SP's
15-value exclusion list (every BMIRD/Hepatitis form plus GEN/MEA/PER/RUB/
RVCT/VAR), it pivots answers into one staged `S_INVESTIGATION_REPEAT` row
per `(PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR)` across four data-type
branches (TEXT / CODED / DATE / NUMERIC).

The catalog statically extracts only **two** columns
(`D_INVESTIGATION_REPEAT_KEY`, `S_INVESTIGATION_REPEAT`) because the
remaining ~251 columns are **added at runtime** by a dynamic ALTER TABLE
loop keyed on `nrt_page_case_answer.rdb_column_nm`
(`010-…-001.sql:1241-1284`) and then filled by the 4-branch dynamic pivot.
In the merged state this dim is **250/253 columns populated over 32 rows** —
i.e. essentially the whole table is `DYNAMIC`, fed by page-builder
metadata, not by any fixed ODSE map. The appendix represents these with a
single `<dynamic:…>` row.

Two bugs shaped this table's history:

- **Bug #10** (`sld_investigation_repeat_key_alloc`, *fixed* 2026-05-22):
  `LOOKUP_TABLE_N_REPT.D_REPT_KEY` had no IDENTITY/DEFAULT, so every new
  row defaulted to the sentinel key `1`; the final
  `WHERE D_INVESTIGATION_REPEAT_KEY != 1` filter then dropped all new rows
  (dim stuck at 2 baseline rows). The 2026-05-21 coverage report captures
  the pre-fix state (1 populated value); the 2026-05-25 merged run reflects
  the post-fix surge to 250/253.
- **Bug #13** (`sld_investigation_repeat_text_pivot_null_propagation`,
  *open*): the TEXT pivot builds its column list with `@cols += …`, which
  NULL-propagates if any `#text_data_REPT` row has `rdb_column_nm = NULL`.
  The `zz_d_inv_place_repeat_enrich.sql` fixture authors exactly such rows
  on PHC 22006000 (they target a *different* SP via `part_type_cd`), so at
  `merge_and_verify` time the TEXT pivot silently no-ops for that PHC —
  ~56 TEXT columns regress to NULL. In isolation (`@phc_id_list=N'22007000'`)
  the pivot reaches 250/256. These TEXT columns carry `BLOCKED:#13`.

`lookup_table_n_rept` is RTR-written (catalog/odse_unknown_tables.md
corrects the earlier "MasterETL-only" claim), but is **0/2** in the merged
state: the orchestrator does not invoke the `sp_page_builder_postprocessing`
path that persists it during the merge run, so its row only appears under
the fixture's direct tail-EXEC — marked `BLOCKED:#10`.

### d_inv_place_repeat

`sp_repeated_place_postprocessing` is the place-flavoured sibling of the
repeat SP. It pivots `nrt_page_case_answer` rows whose
`PART_TYPE_CD IN ('PlaceAsHangoutOfPHC','PlaceAsSexOfPHC')` (the page-builder
answer metadata) into `PlaceAsHangoutOfPHC` / `PlaceAsSexOfPHC` columns
holding a `PLACE_LOCATOR_UID` string (`place_uid^postal_uid^tele_uid`,
with caret normalization at SP line 48). It then **INNER JOINs `D_PLACE`**
on `PLACE_LOCATOR_UID` and copies the entire `PLACE_*` block (39 columns)
from the matched place row (`035-…-001.sql:515-567`). So the four
pivot-derived columns + the surrogate key are page-builder driven, while
the `PLACE_*` columns trace through the **L5 place dimension** to ODSE via
`sp_place_event`.

Because those `PLACE_*` values originate in another agent's dimension and
this table is only **1/44** in the merged state (the
`zz_d_inv_place_repeat_enrich.sql` fixture's needle-moving depends on an
unshipped orchestrator wire-up of `sp_repeated_place_postprocessing` — the
SP isn't called by `merge_and_verify.sh`), the `PLACE_*` rows are recorded
`INFERRED` (mechanism clear from the SP body, not yet fixture-confirmed
end-to-end), while the pivot columns and surrogate key — which the fixture
demonstrably exercises and `coverage_tier_3.md` documents — are `VERIFIED`.

### f_page_case

`sp_f_page_case_postprocessing` builds the page-case fact (`INSERT_NOCOL`,
`SELECT *` shape) from `nrt_investigation` joined to the dimension key
tables. Its gating filter excludes legacy hepatitis form codes and rows
with non-NULL `CASE_MANAGEMENT_UID` (`012-…-001.sql:85-101`). Foundation's
Investigation was filtered out (NULL form_cd fails `NOT IN`); the
`f_page_case_unblock.sql` fixture UPDATEs `nrt_investigation.investigation_form_cd`
to a modern code so the row passes. Result: **33/35 columns over 7 rows**.
Recorded as a single `<all>` `VERIFIED` row (the SP is `INSERT_NOCOL`, so
the catalog does not enumerate individual columns). Note `f_std_page_case`
is the STD-HIV variant owned by Agent L3 and is **out of L6 scope**.

### LDF chain (ldf_data, ldf_group, ldf_dimensional_data, d_ldf_meta_data,
### ldf_datamart_column_ref, *_ldf_group, per-condition ldf_*)

The LDF chain is the second dynamic spine:

```
nrt_ldf_data (answers in staging; projection of ODSE state_defined_field_data)
  → sp_nrt_ldf_postprocessing            → LDF_DATA + LDF_GROUP + *_ldf_group
nrt_odse_state_defined_field_metadata    → sp_nrt_ldf_dimensional_data_postprocessing
  → LDF_DIMENSIONAL_DATA + D_LDF_META_DATA + LDF_DATAMART_COLUMN_REF
  → per-condition sp_ldf_<cond>_datamart_postprocessing → LDF_<COND>
```

`LDF_DATA`, `LDF_GROUP`, `D_LDF_META_DATA`, `LDF_DATAMART_COLUMN_REF`,
`LDF_DIMENSIONAL_DATA` and the three `*_LDF_GROUP` link tables have a
**static, statically-mappable column set** sourced from
`nrt_odse_state_defined_field_metadata` (the ODSE
`state_defined_field*`/LDF metadata projection) and `nrt_ldf_data`. Those
columns are mapped per-column in the appendix. The metadata/ref tables are
baseline-seeded (2620 / 2662 rows) and largely `VERIFIED`; per-fixture
answer columns are `VERIFIED` where `ldf_answers_tetanus.sql` /
`ldf_answers_mumps_foodborne.sql` / `zz_ldf_flagged_answers.sql` exercise
them, `INFERRED` for the handful of metadata columns no fixture lights up.

The **per-condition `LDF_<COND>` datamart tables are the dynamic tier**:
each is widened by a dynamic ALTER TABLE + pivot keyed on
`LDF_DATAMART_COLUMN_REF` for that condition, so the catalog shows only the
`dynamiccolumnList` placeholder (plus SQL-parser artifacts `END` / `THEN`
from a CASE expression). These are `DYNAMIC`. Several are bug-capped:

- **Bug #06** (`ldf_data_truncation`, *merged*): `LDF_DATA.RECORD_STATUS_CD`
  is `varchar(8)` but the SP maps the 13-char `'LDF_PROCESSED'` into it →
  Msg 2628 truncation. That single column is `BLOCKED:#06` (fixtures author
  `'ACTIVE'` to dodge it).
- **Bug #07** (`ldf_dimensional_data_zero`, *open*): an early-RETURN guard
  treats data-type-filtered LDF UIDs as "missing NRT" and aborts the batch,
  and an INNER (vs LEFT) JOIN on a NULL `ldf_page_id` drops rows. This
  capped `LDF_DIMENSIONAL_DATA` historically (now 14/16 after fixture work);
  the chain's downstream emptiness cascades from here.
- **Bug #08** (`ldf_tetanus_substring`, *open*, **6-SP family**): when a
  per-condition LDF table has only its baseline key columns (no dynamic
  answer columns yet), `SUBSTRING(@dynamiccolumnUpdate, 1, LEN('')-1)`
  computes `SUBSTRING('',1,-1)` → Msg 537. `LDF_TETANUS` carries
  `BLOCKED:#08`; `LDF_BMIRD` and `LDF_HEPATITIS` (both **0/7**) are
  additionally blocked at the source — no `condition_cd` 11717 / 10110 rows
  exist in `nrt_odse_state_defined_field_metadata`, so no dynamic columns
  are ever added and the SUBSTRING fires; populating them needs LDF
  metadata seeding, out of fixture scope. `LDF_FOODBORNE`,
  `LDF_MUMPS`, `LDF_VACCINE_PREVENT_DISEASES` populate (`DYNAMIC`).

### summary_report_case + summary_case_group

`sp_summary_report_case_postprocessing` is a conventional (non-dynamic)
postprocessing SP. It reads `nrt_investigation` filtered to
`case_type_cd='S'`, joined to `nrt_investigation_observation` and the
`nrt_observation_numeric` / `_txt` / `_coded` value tables, plus
`nrt_investigation_notification` and `nrt_srte_state_county_code_value`.
The counts/comments/status are projections of the observation values
(`SUM_RPT_CASE_COUNT = ROUND(ovn_numeric_value_1,0)`,
`SUM_RPT_CASE_COMMENTS = REPLACE(... CR/LF)`, `SUM_RPT_CASE_STATUS = notif_status`);
keys are dimension FKs (`CONDITION_KEY`, `INVESTIGATION_KEY`, date-dim
keys, `SUMMARY_CASE_SRC_KEY` to the sibling `summary_case_group`). The
observation values trace to ODSE via `sp_observation_event` /
`sp_investigation_event`. The `summary_report_case.sql` fixture authors a
`case_type_cd='S'` Investigation with the SUM103/104/105 observations; both
tables are `VERIFIED` (11/12 and 2/2). `NOTIFICATION_SEND_DT_KEY` and
`LDF_GROUP_KEY` are the unfilled cols → `INFERRED`.

### aggregate_report_datamart

`sp_aggregate_report_datamart_postprocessing` builds the aggregate count
grid (24 cells = 8 age groups × HOSPITALIZED/DIED/TOTAL) plus an event
block from a `case_type_cd='A'` Investigation joined to
`nrt_investigation_aggregate`, writing via a dynamic UPDATE keyed on
`@tgt_table_nm='AGGREGATE_REPORT_DATAMART'`. A second SP,
`sp_provider_dim_columns_update_to_datamart`, overlays the 28
`INVESTIGATOR_*` / `PHYSICIAN_*` / `REPORTER_*` provider columns (the only
columns the catalog statically extracts for this table).

The entire table is **0/42** — **Bug #11** (`aggregate_report_datamart_schema_mismatch`,
*open*): the dynamic UPDATE references `NOTIFICATION_UPD_DT_KEY`, a column
the target table does not have (Msg 207, "Invalid column name"); the SP's
try/catch swallows the error and never populates a row, so the provider
overlay has nothing to update either. The `aggregate_report.sql` fixture
authors a correct `case_type_cd='A'` Investigation + aggregate count grid
(and documents the `batch_id` IIF-match gotcha) but cannot land rows until
the schema mismatch is fixed. All 42 columns carry `BLOCKED:#11`.

### dyn_dm_* family (no own RDB_MODERN columns)

The 12 `sp_dyn_dm_*` SPs (`createdm`, `main`, `case_management`,
`invest_form`, `invest_clear`, `org_data`, `provider_data`,
`page_builder_d_inv`, `repeatdate`, `repeatnumeric`, `repeatvarch`,
`dimension_update`) generate and populate **dynamically-named** datamart
tables (`DM_INV_<datamart_nm>`, etc.) whose names and column lists are
assembled at runtime from `nrt_dyn_dm_column_metadata` / page-builder
metadata and `@tgt_table_nm`. The catalog therefore lists them only under
"Dynamic-SQL targets (table name resolved at runtime)" — they contribute
**no static `(table, col)` rows** to this appendix. Their inputs are the
already-built `D_INVESTIGATION_REPEAT` (read by `repeatvarch/repeatdate/
repeatnumeric`) and the page-case dims. They are wholly `DYNAMIC` by
construction and are documented here as a mechanism rather than per-column.

- **Bug #09** (`dyn_dm_unpivot_type`, *fixed* 2026-05-21):
  `sp_dyn_dm_repeatvarch_postprocessing` built a dynamic UNPIVOT over a
  column list whose member columns carried mismatched types (Msg 8167),
  rolling back the outer transaction (Msg 266). The fix unblocked the
  orchestrator Step-9 `sp_dyn_dm_*` chain.

---

### Status summary for this cluster

- **VERIFIED**: static-mapped columns proven by a fixture + coverage report
  — the LDF metadata/data/group/ref tables, `*_ldf_group` links,
  `summary_report_case` / `summary_case_group`, `f_page_case`, and the
  pivot-derived + surrogate-key columns of the repeat dims.
- **DYNAMIC** (expected to dominate): `d_investigation_repeat`'s ~251
  pivot columns, `d_inv_place_repeat`'s pivot columns, and the populating
  per-condition LDF tables (`ldf_foodborne/mumps/vaccine_prevent_diseases`).
  Driven by `nrt_page_case_answer` / `nrt_odse_state_defined_field_metadata`,
  no static ODSE→col map. The `dyn_dm_*` family is dynamic in its entirety.
- **INFERRED**: `d_inv_place_repeat`'s `PLACE_*` block (sourced from
  `D_PLACE`, not yet fixture-confirmed here), plus a small set of LDF
  metadata columns and two `summary_report_case` keys no fixture lights up.
  Never confabulated an ODSE source for these.
- **BLOCKED**: `ldf_data.record_status_cd` (#06); `ldf_tetanus`,
  `ldf_bmird`, `ldf_hepatitis` (#08, the latter two also source-starved);
  `lookup_table_n_rept` (#10, orchestrator wire-up); all of
  `aggregate_report_datamart` (#11); `d_investigation_repeat`'s TEXT pivot
  columns at merge time (#13). Bugs #07 (open) and #09 (fixed) shape the LDF
  and dyn_dm chains respectively.

Note: there is **no bug #14** — the `LINEAGE.md` reference is incorrect;
`aggregate_report` is #11 and the `sld_investigation_repeat` TEXT pivot is
#13. `bugs/` holds dirs 01–13.
