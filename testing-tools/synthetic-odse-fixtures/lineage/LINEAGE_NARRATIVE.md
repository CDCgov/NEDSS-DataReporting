# RTR Data Lineage: ODSE → staging → RDB_MODERN

> **What this is.** An end-to-end column-lineage map for the RTR (Real-Time
> Reporting) pipeline: for every populated RDB_MODERN target column, the chain
> back through `nrt_*` staging to its `nbs_odse` source(s), with the stored
> procedure and comparison-fixture that *prove* each path. It exists in two
> parts: this human-readable narrative, and the machine-readable column
> appendix `LINEAGE_COLUMNS.tsv` that the future schema-diff tool consumes.
>
> **It is synthesized rather than freshly derived.** The SQL contains each
> *hop* but never the *end-to-end chain*. This document is the synthesis of ~38
> comparison fixtures and their coverage reports, each of which already
> reverse-engineered "these ODSE inputs light up these RDB_MODERN columns
> through this SP." See `LINEAGE.md` for how the work was carried out.

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
   write `nrt_*`; that is the CDC pipeline's job.

2. **JSON → staging (transport).** In production, SQL Server CDC → Debezium →
   Kafka → a kafka-connect JDBC sink lands the projected rows into `dbo.nrt_*`
   staging tables in RDB_MODERN. The comparison fixtures **deliberately bypass
   this** and hand-author synthetic `nrt_*` rows alongside the ODSE INSERTs,
   because the project diffs the *postprocessing transform* rather than CDC
   fidelity.

3. **staging → RDB_MODERN (postprocessing layer).** `sp_nrt_*_postprocessing`,
   `sp_d_*_postprocessing`, and `sp_*_datamart_postprocessing` SPs read
   `nrt_*` staging (and `#tmp_*` tables derived from it) and write the
   warehouse dimensions, facts, and datamarts.

4. **datamarts (no event partner).** Datamart SPs (Hepatitis_Datamart,
   Std_Hiv_Datamart, the `dyn_dm_*` family, etc.) have no `_event` partner at
   all. They read already-populated RDB_MODERN dimensions and run after
   Tier 1/Tier 2 are merged.

## The load-bearing convention: postprocessing reads staging only

This invariant, verified against the entire
`liquibase-service/.../005-rdb_modern/routines/` tree, is what makes the
lineage tractable:

- **`sp_*_event` SPs read `nbs_odse.dbo.*` directly.** That is their whole
  job (the ODSE→staging edge).
- **`sp_nrt_*_postprocessing` / `sp_d_*` / `sp_*_datamart_*` SPs read
  RDB_MODERN-side staging only:** `nrt_*` tables and `#tmp_*` temps. There
  are **zero** references to `nbs_odse.dbo.*` in the postprocessing layer
  (the staging→RDB_MODERN edge).

The CSV columns on NRT staging rows (e.g.
`nrt_observation.associated_phc_uids`,
`nrt_morbidity_observation.followup_observation_uid`) are the upstream
Debezium projection of the act_relationship / participation graph, how
postprocessing walks edges *without* re-traversing ODSE. The synthesis hop in
this document (mapping an `nrt_*` staging column back to its ODSE source) is
recovered by reading the matching `sp_*_event` SP's JSON projection, and is
the one place this document goes beyond any single SP body.

## How to read the column appendix

The appendix ships in two equivalent renderings, both with one row per
RDB_MODERN column and both regenerated from the per-cluster slices in
`lineage/columns/` by `scripts/build_lineage_columns.py`:

- **`LINEAGE_COLUMNS.tsv`**: canonical, greppable. Tab-separated because the
  free-text fields are full of commas (CSV would force quoting on nearly every
  row); tabs never occur in the data.
- **`LINEAGE_COLUMNS.jsonl`**: one JSON object per line, for the schema-diff
  tool. Line-oriented so it streams and git-diffs cleanly. Same fields, except
  `odse_source_col(s)` is keyed `odse_source_cols`.

| field | meaning |
| --- | --- |
| `rdb_modern_table` | target table |
| `rdb_modern_col` | target column |
| `writing_sp` | the postprocessing/datamart SP that writes it |
| `nrt_staging_source` | the `nrt_*` column (or `#tmp` derivation) the SP reads |
| `odse_source_col(s)` | the `nbs_odse.dbo.*` column(s) feeding that staging col |
| `transform_note` | CASE/COALESCE/substring/pivot/code-lookup applied |
| `mapping_kind` | how the value gets from ODSE to the target (below); *derived* from `transform_note`, not hand-maintained |
| `status` | provenance confidence (below) |
| `fixture_proof` | the fixture (+ coverage report) establishing the mapping |

**Status flags** (the discipline rule: every column gets a row and an honest
status, and a confabulated ODSE→target mapping is worse than an `INFERRED`
flag):

- **`VERIFIED`**: a fixture populates the column and a coverage report
  confirms it. `fixture_proof` cites the fixture.
- **`INFERRED`**: the SP clearly maps it but no fixture proves it (or it sits
  in a partially-covered table and the specific column couldn't be confirmed).
  The ODSE source is the SP's apparent intent, never invented.
- **`DYNAMIC`**: written via dynamic SQL (`<dynamic:@var>` in the catalog);
  source not statically derivable. The `dyn_dm_*` family and much of the LDF
  cluster are dynamic, keyed on `nbs_page_answer` / page-builder metadata. The
  appendix documents the driving mechanism rather than a forced column map.
- **`MASTERETL_ONLY`**: per `catalog/odse_unknown_tables.md`, no RTR ODSE
  path; the column is pre-populated by the legacy MasterETL pipeline.
- **`BLOCKED:#NN`**: reachable in principle but capped by a known RTR bug
  (`bugs/NN_*/findings.md`).

**Mapping kind** (`mapping_kind`) classifies *how* the value reaches the
target, so the diff tool can decide how strictly to compare a column. It is
derived from `transform_note` by `scripts/build_lineage_columns.py`: a
heuristic hint, not a contract; refine at the source if a column matters.

- **`direct`** (700, ~19%): value relocated unchanged. Passthrough, direct
  projection, dim-join / copied-from-dim. No reshape, no edit.
- **`pivot`** (600, ~16%): EAV→columnar reshape (an `nbs_case_answer` /
  observation *row* pivoted into a column) with **no** value edit. Structurally
  moved, value preserved.
- **`code-translate`** (996, ~27%): a code is mapped to its description or
  another coded form (codeset lookup / decode), whether or not a pivot also
  moved it. The same datum, a different *representation*.
- **`derived`** (701, ~19%): the value is computed. Substring/concat,
  aggregate (`SUM`/`COUNT`/`ROW_NUMBER`/`MAX` outside a pivot), `CASE` rewrite,
  type convert, `COALESCE`/`ISNULL` key resolution, flags. Also the catch-all
  for INFERRED rows whose exact op could not be isolated.
- **`no-source`** (738, ~20%): the *stored* value is not a copy of any ODSE
  column. Surrogate / IDENTITY / resolved foreign keys (any ODSE col in
  `odse_source_col(s)` is the natural key that *drives* the lookup, not the
  stored value), runtime-`DYNAMIC` tables, MasterETL-fed dims, generated date
  dims, and operational log/metric state.

For a schema-diff tool: **`direct` + `pivot` (~35%)** should compare
byte-for-byte; **`code-translate` (~27%)** should compare after applying the
codeset; **`derived` and `no-source` (~39%)** are environment-dependent, so
don't expect literal equality. (Where you draw the "is this a 1:1 mapping?"
line is exactly the `pivot` vs `code-translate` question: ~35% if a pivot that
also decodes a coded answer counts as transformed, ~61% if it counts as
movement.)

### Scope and counts (sanity check for the appendix)

- The static catalog `rtr_target_columns.md` parses **130** routines and finds
  **3,593** statically-derivable (table, column) pairs across **118** in-scope
  tables, plus **15** dynamic-SQL target placeholders whose columns are *not*
  statically derivable.
- Live coverage (`coverage_merged.md`, full from-scratch run 2026-05-25)
  reports **4,633** total columns across those 118 tables, of which **4,161**
  are populated: **89.8%** overall column coverage.
- **This appendix has 3,735 rows covering all 118 in-scope tables.** Every
  in-scope table is now represented (none omitted), and the
  statically-traceable column spine of each is enumerated against
  `rtr_target_columns.md`. It is still *not* 1:1 with the 4,161 live-populated
  columns, and deliberately so: tables whose physical schema is generated at
  runtime (`covid_case_datamart`, `covid_lab*`, `d_investigation_repeat`, and
  the `dyn_dm_*` / per-condition `ldf_*` families) are built by dynamic SQL
  (`ALTER TABLE … ADD` + PIVOT keyed on `nbs_page_answer` / page-builder
  metadata) and are represented by a **single `DYNAMIC` (or `BLOCKED`)
  mechanism row each** rather than by enumerating their hundreds of runtime
  columns. That collapses ~1,000+ live-populated-but-runtime columns into a
  handful of rows. Status split across the 3,735 rows: **1,940 VERIFIED ·
  1,469 INFERRED · 193 MASTERETL_ONLY · 105 BLOCKED · 28 DYNAMIC**.

### Known caveats reflected in the data

- **`zz_hepatitis_datamart_round2.sql` is quarantined** (tempdb blowup on cold
  rebuild; see `BLOCKED.md` / `bugs/`). Its ~+61 `hepatitis_datamart` columns
  are therefore **not** currently populated and are flagged `BLOCKED` /
  `INFERRED` in the Hepatitis section, not `VERIFIED`.
- **Bugs cap specific columns** (flagged `BLOCKED:#NN`): #06/#10 LDF chain
  prerequisites; #08 the per-condition LDF `SUBSTRING(@dynamiccolumnUpdate, 1,
  LEN(...)-1)` family (fires on an empty dynamic-column list); #11 `aggregate_report_datamart` schema
  mismatch; #12 `bmird_case_datamart` ROW_NUMBER partition; #13
  `sld_investigation_repeat` TEXT-pivot NULL propagation; #15 `EVENT_METRIC`
  investigation-branch leaves `ADD_USER_NAME` NULL, which violates the
  `SR100.ADD_USER_NAME NOT NULL` constraint and blocks the entire `SR100`
  datamart (all 20 columns) because the TRY/CATCH swallows the Msg 515.
- **Operational / audit tables are out of the subject-data lineage.**
  `RDB_DATE` is a generated calendar dimension (no ODSE source); `ETL_DQ_LOG`,
  `JOB_FLOW_LOG`, `EVENT_METRIC(_INC)`, and `USER_PROFILE` are RTR run-time
  state (SP name, batch id, timestamps, DQ-fail records, staged user names),
  not `nbs_odse` columns. They are enumerated honestly in section G4 with that
  provenance rather than a fabricated ODSE→column chain.

---

## Cluster sections

### Table of contents

- [L1: Labs lineage](#l1-labs-lineage)
- [L2: Hepatitis cluster](#l2-hepatitis-cluster)
- [L3: TB / STD-HIV / BMIRD / Varicella datamarts](#l3-tb--std-hiv--bmird--varicella-datamarts)
- [L4: COVID family lineage](#l4-covid-family-lineage)
- [L5: People, Links & Dimensions](#l5-people-links--dimensions)
- [L6: Investigation-repeat, LDF, dyn_dm, page-builder](#l6-investigation-repeat-ldf-dyn_dm-page-builder)

Gap-fill sections (tables the L1–L6 cluster work narrated but did not enumerate):

- [G1: Core Investigation, HIV, Case-Management & Repeat-Link tables](#g1-core-investigation-hiv-case-management--repeat-link-tables)
- [G2: TB / Varicella PAM facts, LDFs, STD page-case fact & BMIRD/Pertussis groups](#g2-tb--varicella-pam-facts-ldfs-std-page-case-fact--bmirdpertussis-groups)
- [G3: PAM dimension code & group tables (TB / Varicella)](#g3-pam-dimension-code--group-tables-tb--varicella)
- [G4: Operational, audit & blocked tables](#g4-operational-audit--blocked-tables)

---

## L1: Labs lineage

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
   `D_ORGANIZATION`, `INVESTIGATION`, `CONDITION`), except `COVID_LAB_DATAMART`,
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
`Lab_Result_Comment`). `LAB_TEST_RESULT` is almost all foreign keys: each
`*_KEY` is a `COALESCE(<dim lookup>, 1)`: sentinel **1** when the upstream
dimension isn't populated yet. `LAB_RPT_USER_COMMENT` is written by
`sp_d_lab_test_postprocessing` from the C_Result follow-up observation's `'N'`
text, reached via the Order's `followup_observation_uid` CSV (the C_Order /
C_Result observations are *deliberately excluded* from `@obs_ids` because they
fail the `obs_domain_cd_st_1` filter; see `coverage_lab.md`).

All of these are **VERIFIED** by `fixtures/10_subjects/lab.sql` +
`coverage_lab.md` (live: LAB_TEST 66/66, LAB_RESULT_VAL 20/20,
LAB_RESULT_COMMENT 6/6, TEST_RESULT_GROUPING 3/3, RESULT_COMMENT_GROUP 3/3,
LAB_TEST_RESULT 19/20). Honest exceptions, all flagged INFERRED in the
appendix and cross-referenced in the coverage report's "deliberately skipped":

- **LAB_TEST.RESULT_INTERPRETER_NAME**: LEFT JOINs `nrt_provider` on
  `result_interpreter_id`; empty at Lab Tier-1 isolation → NULL. Resolves once
  the Provider chain has run (merged-fixture sequence).
- **LAB_TEST_RESULT.CONDITION_KEY**: join is `condition.program_area_cd =
  prog_area_cd AND condition.condition_cd IS NULL`; the lab fixture uses STD
  prog-area while CONDITION is seeded for HEP only → sentinel 1 persists
  (`coverage_lab_inv.md` OUT_OF_SCOPE).
- **LAB_TEST_RESULT.MORB_RPT_KEY**: no NBS act_relationship path Lab→Morb;
  linkage is via `report_observation_uid`, sentinel 1 persists.
- **LAB_TEST_RESULT.LDF_GROUP_KEY**: `ldf_group` empty in baseline (Tier-3
  LDF work); sentinel 1.
- **LAB_TEST_RESULT.LAB_RESULT_VAL_LARGE_TXT_KEY**: column in DDL but no SP
  writes it.
- **TEST_RESULT_GROUPING.RDB_LAST_REFRESH_TIME**: SP explicitly INSERTs
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
Foundation Patient/Provider/Org rows). Live **62/69**. The ~7 unpopulated
columns are the address-use/cd description lookups (ADDR_USE_CD_DESC,
ADDR_CD_DESC, PRV_*), CONDITION_SHORT_NM / PROGRAM_AREA_DESC (sparse CONDITION
dim), and the sentinel/empty FK passthroughs (MORB_RPT_KEY, LDF_GROUP_KEY),
flagged INFERRED.

### LAB101: isolate tracking (entirely INFERRED, 0/46 live)

`sp_lab101_datamart_postprocessing` is the Emerging-Infections / NARMS / PFGE
PulseNet isolate-tracking datamart. Roughly a dozen columns
(RESULTED_LAB_TEST_KEY, SPECIMEN_*, RECORD_STATUS_CD, OID, dates) come from
`LAB_TEST`; the **bulk** (every `EIP_*`, `NARMS_*`, `PFGE_*`, `ISO_*`,
`PATIENT_STATUS`, `CASE_LAB_CONFIRMED_IND`, `PULSENET_ISO_IND` column) comes
from a special **`cd='LAB330'` follow-up observation** reached by walking the
Order's `followup_observation_uid` CSV, whose coded result values
(`TEST_RESULT_VAL_CD_DESC`) are pivoted **positionally** into aliases
`LAB.LAB3` … `LAB.LAB34` (e.g. `LAB10` → PFGE_PULSENET_SENT, `LAB21` →
NARMS_EXPECTED_SHIP_DATE via a `convert(datetime, replace('-',' '))`). No
fixture exercises the LAB330 isolate-tracking chain, so **the whole table is
empty (0/46)** and every column is flagged **INFERRED**. The source chain is
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
entity decoding `&lt; → <` etc.). Live **11/35**: the investigation/patient
identity and OID columns (12 in the appendix) are flagged VERIFIED via
`fixtures/20_links/lab_inv.sql`. The Tier-2 LabReport edge demonstrably wires
the investigation+patient identity path; the remaining address, age, race,
physician, disease, comment, and laboratory-chunk columns are flagged INFERRED
(populated in principle once the upstream graph is fully wired, but not
confirmed for these specific columns in the merged run). Note the appendix
counts 12 VERIFIED identity columns while `coverage_merged.md` reports an
aggregate **11/35** populated in the live run. The one-column gap is a single
identity column that lands blank in that specific run, not a confabulated
mapping; both numbers are reported here rather than reconciled away.

### COVID_LAB_DATAMART / COVID_LAB_CELR_DATAMART (DYNAMIC)

These two are structurally different from the rest and are flagged **DYNAMIC**.
`sp_covid_lab_datamart_postprocessing` builds `#COVID_LAB_CORE_DATA` directly
from `nrt_observation` (Order `o` + Result `o1`) plus
`nrt_observation_coded/numeric` and `nrt_organization`/`D_Organization`, gated
on the result `cd` mapping to `condition_cd='11065'` (2019 Novel Coronavirus)
via `nrt_srte_Loinc_condition` (which the unblock fixture must seed first; by
default that table has zero `11065` rows). It then **dynamically `ALTER TABLE
dbo.COVID_LAB_DATAMART ADD`**s a column per `#COVID_LAB_CORE_DATA` column, and
separately builds `#COVID_LAB_AOE_DATA`, a dynamic PIVOT of "ask-on-order
entry" answer observations keyed by `nrt_odse_lookup_question` where
`from_form_cd='LAB_REPORT'` (FIRST_TEST, HOSPITALIZED, ICU, PREGNANT, …). The
catalog therefore lists only the placeholder `COVID_LAB_CORE_DATA`; the physical
129-column schema is generated at runtime. The appendix documents the
mechanism: the **core** columns have concrete `nrt_observation → observation`
sources (sample rows enumerated), and the **AOE** columns are a single DYNAMIC
row because the column set is not statically derivable.
`sp_covid_lab_celr_datamart_postprocessing` is a pure downstream projection: it
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
| LAB101 | 0/46 | INFERRED (all 46: LAB330 isolate-tracking chain unexercised) |
| CASE_LAB_DATAMART | 11/35 | VERIFIED (12) + INFERRED (23) |
| COVID_LAB_DATAMART | 127/129 | DYNAMIC (runtime schema; core nrt_observation-sourced + AOE pivot) |
| COVID_LAB_CELR_DATAMART | 85/101 | DYNAMIC (projection of covid_lab_datamart) |

No lab columns are BLOCKED by a bug (bug dirs 01–13 contain no lab-cluster
findings; the LDF/dyn_dm bugs that mention "lab" are out of this cluster). No
lab columns are MASTERETL_ONLY.

---

## L2: Hepatitis cluster

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
therefore one hop further upstream. ODSE `public_health_case` /
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
`coverage/coverage_hep_datamart_investigation.md`. Notable transforms: numeric-string
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
UPDATE) by the datamart SPs the reporting-pipeline-service fires during
the CDC drain.

The **65 BLOCKED:tempdb** columns are exactly the ones the Round 2
fixture was meant to light up:
`fixtures/30_sp_coverage/_quarantine/zz_hepatitis_datamart_round2.sql.tempdb-blowup`.
They are: the full `D_INV_RISK_FACTOR` (`R.`) set (~39 cols; RSK_* was
explicitly skipped in Round 1 over numeric-cast concerns); the
provider/org/reporting-source (`HP.`) bundle (PHYS_*, INVESTIGATOR_*,
RPT_SRC_*, *_UID, 13 cols); the three `INVESTIGATION`-UPDATE cols
(INV_COMMENTS, INV_START_DT, PAT_PREGNANT_IND); and the
vaccination-repeat pivot outputs (VACC_DOSE_NBR_1..4, VACC_RECVD_DT_1..4,
IMM_GLOB_RECVD_IND, GLOB_LAST_RECVD_YR, 10 cols). **These are NOT in
the live 89.6% coverage.** Round 2 verified them on a *warm*
incremental DB (140→201), but on the deterministic cold single-batch
rebuild its tail-EXEC chain (`sp_f_page_case_postprocessing` →
`sp_hepatitis_datamart_postprocessing`, PHC 22008500) spilled ~70 GB
into tempdb and crashed MSSQL twice (ENOSPC). Per the fixture-error
rule the file was renamed to a non-`.sql` suffix and
parked under `_quarantine/` (see `BLOCKED.md` and the `_quarantine/`
README). Restoring it needs an upstream fix to the runaway
join/spill in those two SPs (or a tempdb MAX_SIZE cap that fails loudly
on just this fixture). Marked `BLOCKED:tempdb` rather than VERIFIED
accordingly. (Note: the briefing's "bug #14" label was never a numbered
bug, so the quarantine is tracked via `BLOCKED.md`/`_quarantine/README.md`.)

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
rows in the baseline and no routine-layer SP writes it from ODSE; it
is normally a Kafka/Debezium-streamed table. The fixture resolves
`INVESTIGATION_KEY` dynamically (an earlier hardcoded `=26` broke the
FK on clean rebuilds) and self-heals if the dim row is missing. With
that one row, the SP's `INNER JOIN (HC.investigation_key =
I.investigation_key)` is satisfied and HEP100 populates 185/187 live.
The 2 INFERRED gaps are `ADDR_CD_DESC` / `ADDR_USE_CD_DESC`
(address-type code descriptors): guarded patient-dim columns
(also written by `sp_patient_dim_columns_update_to_datamart`) that
stay NULL because the seeded patient locator carries no address-use /
address-type code. Not blocked, just unseeded.

### HEP_MULTI_VALUE_FIELD_GROUP (1/1 VERIFIED): the "hepatitis_case" subject

`sp_hepatitis_case_datamart_postprocessing` (039) is a **dynamic-pivot**
SP (`@tgt_table_nm='Hepatitis_Case'`, `@multival_tgt_table_nm =
'HEP_Multi_Value_Field'`). It reads observation values through
`dbo.v_rdb_obs_mapping` (splitting coded / text / date / numeric
answer values into `#OBS_*_Hepatitis_Case` temp tables filtered by
`RDB_TABLE = @tgt_table_nm`) and writes `HEPATITIS_CASE` plus the
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

### LDF_HEPATITIS (0/7, DYNAMIC, LDF chain blocked)

`sp_ldf_hepatitis_datamart_postprocessing` (320) is an LDF
(locally-defined-field) datamart SP: its columns are **dynamic**.
the SP `ALTER TABLE`s `LDF_HEPATITIS` per the LDF-template metadata for
the condition, then dynamically INSERTs answer values keyed on
`nrt_ldf` / `nrt_page_case_answer`. There is no static ODSE→column map;
the catalog represents the whole table as one `dynamiccolumnList`
entry. Live coverage is **0/7**: the LDF chain is blocked upstream.
`sp_nrt_ldf_dimensional_data_postprocessing` early-returns producing 0
rows of `LDF_DIMENSIONAL_DATA`,
and the related LDF truncation issue (fixed on main) sits on the same path. The fixture does tail-EXEC
`sp_ldf_hepatitis_datamart_postprocessing` (@phc_uids='22008500') but
no LDF columns populate. Flagged `DYNAMIC` with the LDF-chain block
noted (`BLOCKED:#07`).

### Summary of what's blocked vs. covered

- **Covered live (the 89.6% run):** HEPATITIS_DATAMART 144/209
  (Round 1 enrich), HEP100 185/187, HEP_MULTI 1/1.
- **Blocked / not in the headline:** HEPATITIS_DATAMART's Round 2 +65
  (RSK_*, provider/org, vaccination-repeat, 3 investigation cols),
  quarantined for the tempdb blowup; LDF_HEPATITIS 0/7, the LDF
  dimensional-data chain (bug #07); HEP100 2 address-descriptor cols,
  unseeded (INFERRED).

---

## L3: TB / STD-HIV / BMIRD / Varicella datamarts

Cluster tables: `D_TB_PAM`, `TB_DATAMART`, `TB_HIV_DATAMART`,
`STD_HIV_DATAMART`, `BMIRD_STREP_PNEUMO_DATAMART`, `VAR_DATAMART`
(1,427 RDB_MODERN columns total). Column-level lineage is in
`lineage/columns/L3_tb_stdhiv_bmird_var.tsv`.

This cluster spans the **two composition patterns** the project's
datamart SPs use, and all six tables are downstream consumers; none
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
  `MAX(answer_txt) FOR datamart_column_nm IN (...)`, so **each
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
  dimensions are **MasterETL-only** (no RTR ODSE path; see
  `catalog/odse_unknown_tables.md` and the STD coverage report's "Key
  takeaway"); the Tier-3 fixtures hand-author the dimension rows
  directly so the datamart join lights up.

Cross-subject person/provider/org columns on every table (PATIENT_NAME,
CURRENT_SEX, PHYSICIAN_*, REPORTER_*, HOSPITAL_*, ORGANIZATION_*, …)
resolve through `D_PATIENT` / `D_PROVIDER` / `D_ORGANIZATION`, which are
populated by their own entity-dim pipelines (MasterETL-side for the
persistent dims). They are flagged `MASTERETL_ONLY` in the appendix
because there is no static TB/STD/BMIRD/Var ODSE→column chain for them.
their lineage belongs to L5 (people/links/dims).

**Status accounting** (1,427 rows): VERIFIED 84, INFERRED 1,156,
MASTERETL_ONLY 174, BLOCKED:#12 13. The high INFERRED count is expected
and honest: the PAM pivots and dimensional joins *map* every column, but
the full-chain fixtures author a deliberately minimum-viable set of
questions/dimension columns to prove each SP runs end-to-end. The
remaining columns are reachable in principle by authoring more PAM
questions / `D_INV_*` columns (a fixture-completeness exercise, not an
infrastructure block), so they are INFERRED (SP clearly maps them, no
fixture proves the specific column), never confabulated.

---

### D_TB_PAM (166 cols): `sp_nrt_d_tb_pam_postprocessing`

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
The remaining pivot columns are INFERRED, fed by TUB questions the
minimum-viable fixture did not author.

### TB_DATAMART (318 cols): `sp_tb_datamart_postprocessing`

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

### TB_HIV_DATAMART (322 cols): `sp_tb_hiv_datamart_postprocessing`

`TB_HIV_DATAMART` is largely a re-projection of `TB_DATAMART` for
the TB-HIV co-infection view: its only source tables are `TB_DATAMART`,
`D_TB_PAM`, `D_TB_HIV`, and `INVESTIGATION`. Most columns mirror
`TB_DATAMART` one-for-one (same lineage; INFERRED unless TB_DATAMART
proved them), and the `HIV_*` columns come from `D_TB_HIV`
(`HIV_STATUS`, `HIV_STATE_PATIENT_NUM`, `HIV_CITY_CNTY_PATIENT_NUM`),
which `sp_nrt_d_tb_hiv_postprocessing` pivots from `nrt_page_case_answer`
questions TUB154/155/156, a verified PAM path. Person/provider/org
columns inherited from TB_DATAMART are MASTERETL_ONLY. Same
duplicate-INSERT bug as TB_DATAMART.

### VAR_DATAMART (233 cols): `sp_var_datamart_postprocessing`

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
populates after `sp_event_metric_datamart_postprocessing` has run first
(in the merged flow that runs in `run_summary_datamarts`)
(`coverage_varicella_full_chain.md`). Unlike TB, VAR_DATAMART's INSERT
has a `WHERE D.INVESTIGATION_KEY IS NULL` idempotency guard. Verified
columns are the ~25 the full-chain + enrich fixtures authored
(VARICELLA_VACCINE, RASH_LOCATION, lab-test flags, etc.); the rest of
the ~110 VAR questions are INFERRED.

### STD_HIV_DATAMART (248 cols): `sp_std_hiv_datamart_postprocessing`

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
concatenation. Two RTR bugs surfaced here: sentinel
`CONFIRMATION_METHOD_GROUP` rows doubling the join cardinality, and an
orchestrator `@phc_ids` vs `@phc_id_list` parameter-name mismatch
(both documented in the coverage report).

### BMIRD_STREP_PNEUMO_DATAMART (140 cols): `sp_bmird_strep_pneumo_datamart_postprocessing`

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

- **BLOCKED:#12 (13 cols)**: `UNDERLYING_CONDITION_2..8`,
  `NON_STERILE_SITE_2..3`, `ADD_CULTURE_1_SITE_2..3`,
  `ADD_CULTURE_2_SITE_2..3`. These are the `_2`+ slots of the
  multi-value pivot. Bug #12: SP
  040's `ROW_NUMBER() OVER (PARTITION BY public_health_case_uid,
  branch_id ...)` includes `branch_id` in the partition, so every branch
  is alone → `row_num` always 1 → `BMIRD_MULTI_VALUE_FIELD` collapses to
  one row per investigation and only the `_1` slot fills, no matter how
  many answers are authored. Reachable in principle; capped by the bug.
- **ANTIMICROBIAL pivot (~40 cols)**: `ANTIMICROBIAL_AGENT_TESTED_1..8`,
  `SUSCEPTABILITY_METHOD_*`, `MIC_*`, etc. Require root/branch
  Antimicrobial observations (`ANTIMICRO_GAP` in the coverage report);
  out of scope for the current fixture → INFERRED.
- **Verified (~25 cols)**: the single-slot BMD answers and
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
- **`MASTERETL_ONLY` here means "no RTR ODSE chain for this column"**:
  it is sourced from a persistent dimension (`D_PATIENT`, `D_PROVIDER`,
  `D_ORGANIZATION`, `D_INV_*`, `L_INV_*`) that RTR joins but does not
  populate from ODSE. For STD/HIV the Tier-3 fixture hand-authors the
  `D_INV_*`/`L_INV_*` rows so the join resolves.
- **INFERRED is the honest default** for the many PAM/BMD questions and
  `D_INV_*` columns that each SP maps but the minimum-viable fixtures did
  not author a feeder for. None were confabulated to VERIFIED.
- **Re-runnability bug** (TB_DATAMART, TB_HIV_DATAMART,
  BMIRD_STREP_PNEUMO_DATAMART): INSERT-only / anti-join INSERT with no
  DELETE-first or MERGE, so duplicate or stale rows appear on replay.
  VAR_DATAMART and the DELETE-then-INSERT marts are safe.

---

## L4: COVID family lineage

Cluster: `COVID_CASE_DATAMART`, `COVID_CONTACT_DATAMART`,
`COVID_VACCINATION_DATAMART`, `INV_SUMM_DATAMART`.

Writing SPs (all `datamart_postprocessing`, no `_event` partner; they read
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
sits one tier further downstream: it reads only RDB_MODERN dimensions/facts
(`INVESTIGATION`, `D_PATIENT`, `D_PROVIDER`, `NOTIFICATION`, the per-condition
`*_CASE` fact tables, `CASE_LAB_DATAMART`, `lab100`), each of which is itself
built by an upstream `sp_nrt_*`/`sp_d_*`/`sp_f_*` SP, so its ODSE roots are
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

- `#COVID_CASE_CORE_DATA` (Step 4): `NRT_INVESTIGATION phc` columns mapped
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
- `#COVID_PATIENT_DATA` (Step 5): joins `D_PATIENT pat` (built by
  `sp_d_patient`/`sp_patient_event` from ODSE `person`) on
  `inv.patient_id`, plus `NRT_PATIENT nrtPat` (status `'A'`, name-use `'L'`)
  for the codeset-unit fields (`AGE_REPORTED_UNIT_CD`, `DECEASED_IND_CD`,
  `MARITAL_STATUS_CD`, `STATE_CODE`, `COUNTY_CODE`, `COUNTRY_CODE`,
  `ETHNIC_GROUP_IND`).
- `#COVID_ENTITIES_DATA` (Step 6): resolves the soft-ref FKs on
  `NRT_INVESTIGATION` (`investigator_id`, `physician_id`,
  `person_as_reporter_uid`, `organization_id`, `hospital_uid`) against
  `D_PROVIDER` / `D_ORGANIZATION` to produce `PHC_INV_*`, `PHYS_*`,
  `RPT_PRV_*`, `RPT_ORG_*`, `HOSPITAL_NAME`. These were the columns the
  round-1 fixture left NULL; `zz_covid_case_datamart_round2.sql` adds the
  provider/org rows and re-points the FKs to light them up.

The **form-driven** columns (the overwhelming majority, ~440 of them) are
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
**final INSERT is itself dynamic SQL**: the entire column list is read from
`tempdb.INFORMATION_SCHEMA.COLUMNS` of those temp tables and executed via
`EXEC sp_executesql @insert_query` (lines 1119–1245). These columns are
`DYNAMIC`: their ODSE source is `nbs_odse.dbo.nbs_case_answer.answer_txt` (via
`nrt_page_case_answer`), keyed dynamically by form metadata, not statically
derivable per target column.

> **Surprise / catalog caveat.** `rtr_target_columns.md` lists exactly one
> column for this table, `PATH`, guarded. That is a **parser false-positive**:
> it matched the `FOR XML PATH('')` literal inside the dynamic INSERT-string
> assembly (310-...:551,1128,…), not a real column. COVID_CASE_DATAMART has
> **no static column list at all**: every column is added/inserted via
> dynamic SQL. `PATH` is flagged `DYNAMIC`/parser-artifact in the appendix.

Blocked/skipped: coverage_merged shows 379/383 populated; the round-1
coverage_covid_full_chain.md "deliberately skipped" list (CONFIRMATION_*,
PHC_INV_*/PHYS_*/RPT_*/HOSPITAL_NAME, NOTIFICATION_*) was subsequently
unblocked by round2. The residual ~4 columns are form questions for which no
answer row is authored. Reachable by mechanical fixture expansion, not a bug.

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

- `SRC_*` (index-investigation/patient): `inv.*` columns
  (`activity_from_time`, `investigation_status_cd`, `case_class_cd`,
  `hospitalized_ind_cd`, `outcome_cd`, `infectious_from/to_date`,
  `contact_inv_*`) and `D_PATIENT pat`/`NRT_PATIENT nrt_pat` for the index
  patient. Four `SRC_INV_*` answer columns come from `NRT_PAGE_CASE_ANSWER`
  by `question_identifier` (`NBS547` CDC-assigned ID, `NOT113` reporting
  county, `INV576` symptomatic, `NBS555` symptom status), batch-id matched.
- `CR_*` (contact record): `NRT_CONTACT con` columns
  (`CTT_JURISDICTION_NM`, `CTT_STATUS_CODE`, `CTT_PRIORITY`,
  `CTT_INV_ASSIGNED_DT`, `CTT_DISPOSITION`, `CTT_NAMED_ON_DT`,
  `CTT_RELATIONSHIP`, `CTT_HEALTH_STATUS`, dates/notes) plus four
  `NRT_CONTACT_ANSWER` joins by `rdb_column_nm`
  (`CTT_EXPOSURE_TYPE/SITE_TYPE`, `CTT_FIRST/LAST_EXPOSURE_DT`). Investigator
  name comes from `D_PATIENT ctt_pat_con`. Many `CR_*` codes resolve through
  `NRT_SRTE_CODE_VALUE_GENERAL` by codeset (`NBS_PRIORITY`, `NBS_DISPO`,
  `NBS_RELATIONSHIP`, `NBS_HEALTH_STATUS`, `YNU`).
- `CTT_*` (contact-as-subject): a CASE switch. If
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
investigation (`CONTACT_ENTITY_PHC_UID` branch) not authored in the fixture:
INFERRED, reachable via a second COVID investigation linked as the contact's
own subject. No bug caps this table.

### COVID_VACCINATION_DATAMART

Row flow: `sp_covid_vaccination_datamart_postprocessing @vac_uids,@patient_uids`
builds `#VAC_LIST` from `NRT_VACCINATION` filtered on
`material_cd IN ('207','208','213')` (the COVID vaccine product codes); that
is the gating predicate, not a condition code. Idempotent DELETE-then-INSERT
keyed on `local_id`; `LOG_DEL` dropped. The INSERT is `INSERT INTO
COVID_VACCINATION_DATAMART SELECT DISTINCT …` with **no column list** (hence
the catalog's `<all>`), so the 60 targets are positional from the SELECT.

`NRT_VACCINATION` supplies the keys + `INVESTIGATION_DT`
(`COALESCE(nrtinv.activity_from_time, nrtinv.add_time)` via the LEFT JOIN to
`NRT_INVESTIGATION` on `phc_uid`) and `INVESTIGATION_LOCAL_ID`
(`nrtinv.local_id`). Everything else comes from RDB_MODERN dimensions joined
on the CTE soft-refs:

- `D_VACCINATION dvac` (on `vaccination_uid`): `VACCINATION_ADMINISTERED_NM`,
  `VACCINE_ADMINISTERED_DATE`, `VACCINATION_ANATOMICAL_SITE`,
  `AGE_AT_VACCINATION(_UNIT)`, `VACCINE_MANUFACTURER_NM`,
  `VACCINE_LOT_NUMBER_TXT`, `VACCINE_EXPIRATION_DT`, `VACCINE_DOSE_NBR`,
  `VACCINE_INFO_SOURCE`, `ELECTRONIC_IND`, `RECORD_STATUS_CD`, `LOCAL_ID`,
  add/chg audit columns.
- `D_PATIENT patient` (on `patient_uid`): all `PATIENT_*`; `PATIENT_BIRTH_SEX`
  via a correlated subselect on `PATIENT_MPR_UID`; `PATIENT_RACE_CALC_DETAILS`
  with `REPLACE(' |',';')`; `PATIENT_COUNTRY` upper-cased.
- `D_PROVIDER provider` / `D_ORGANIZATION org` (on `provider_uid` /
  `organization_uid`): `PROVIDER_*` / `ORGANIZATION_*`, country upper-cased,
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

This SP is structurally different: **no COVID filter, no `nrt_*` reads**. It
summarises every active investigation (`INVESTIGATION.CASE_TYPE='I'`,
`RECORD_STATUS_CD='ACTIVE'`) whose `CASE_UID` is in `@phc_uids` (or whose
notification was just updated, via `#TMP_UPDATED_INV_WITH_NOTIF`). It runs an
INSERT-new + UPDATE-existing pair, then DELETEs inactive rows, then two
follow-on UPDATEs (EVENT_DATE/specimen, INIT_NND_NOT_DT).

Column families and their RDB_MODERN sources:

- Investigation columns (`INVESTIGATION_KEY/STATUS/LOCAL_ID`, MMWR, dates,
  `CASE_STATUS`, `PROGRAM_AREA`, `PROGRAM_JURISDICTION_OID`,
  `CURR_PROCESS_STATE`, `JURISDICTION_NM`, create/update audit): the
  `INVESTIGATION` dimension, `SUBSTRING`-truncated to fit. `INVESTIGATION` is
  built by `sp_nrt_investigation_postprocessing` from `nrt_investigation`,
  i.e. ODSE `public_health_case`.
- `PATIENT_KEY`/`PHYSICIAN_KEY`: resolved by a `CASE`/`COALESCE` priority
  ladder across eleven per-condition fact tables (`GENERIC_CASE`, `CRS_CASE`,
  `MEASLES_CASE`, `RUBELLA_CASE`, `HEPATITIS_CASE`, `BMIRD_CASE`,
  `PERTUSSIS_CASE`, `F_TB_PAM`, `F_VAR_PAM`, `F_PAGE_CASE`, `F_STD_PAGE_CASE`)
  first key > 1 wins. STD vs non-STD branch chosen by
  `count(*) nrt_investigation_case_management`.
- Patient demographics (`PATIENT_FIRST/LAST_NAME`, DOB, sex, age,
  address, county, ethnicity, race, local id): `D_PATIENT` on `PATIENT_KEY`.
- `PHYSICIAN_FIRST/LAST_NAME`: `D_PROVIDER` on `PHYSICIAN_KEY`.
- `DISEASE`/`DISEASE_CD`: `CASE_COUNT ⋈ condition` (dim) on
  `CONDITION_KEY`.
- `CONFIRMATION_METHOD`/`CONFIRMATION_DT`: `STRING_AGG('|')` over
  `CONFIRMATION_METHOD ⋈ CONFIRMATION_METHOD_GROUP`.
- Notification columns (`NOTIFICATION_STATUS/LOCAL_ID/CREATE_DATE/SENT_DATE/
  SUBMITTER/LAST_UPDATED_*`): `NOTIFICATION ⋈ NOTIFICATION_EVENT ⋈ RDB_DATE`,
  `ROW_NUMBER() … rn=1` to take the earliest. `INIT_NND_NOT_DT` from a later
  `nrt_investigation_notification` aggregate (`FIRSTNOTIFICATIONSENDDATE`).
- Lab columns (`LABORATORY_INFORMATION`, `EVENT_DATE(_TYPE)`,
  `FIRST_POSITIVE_CULTURE_DT`, `Earliest_specimen_collect_date`):
  `CASE_LAB_DATAMART` + a `LAB_TEST_RESULT ⋈ LAB_TEST ⋈ lab100` chain;
  `FIRST_POSITIVE_CULTURE_DT` from `BMIRD_CASE`.

Because none of these are `nrt_*` reads, the appendix records the RDB_MODERN
dim/fact column as the proximate source and the transitive ODSE root where it
is unambiguous (investigation/patient/provider → public_health_case/person).
`EVENT_DATE`/`EVENT_DATE_TYPE` originate entirely inside the lab datamart
(L1's CASE_LAB_DATAMART) and are copied here; INFERRED on the COVID side.

Status: 58/58 live (full). `zz_inv_summ_datamart_unblock.sql` corrected the
earlier "chicken-and-egg" misreading (the `@INV_SUMMARY_DATAMART_COUNT > 0`
predicate gates only the optional notif-update temp table, not the main insert)
and supplied the joined dims; all 58 are VERIFIED.

---

## L5: People, Links & Dimensions

This cluster covers the core RDB_MODERN dimension and fact tables
for the "people" subjects (`d_patient`, `d_provider`, `d_organization`,
`D_PLACE`), the act-based subjects (`D_INTERVIEW`/`D_INTERVIEW_NOTE`,
`D_VACCINATION`, `D_CONTACT_RECORD`, `NOTIFICATION`, `TREATMENT`,
`MORBIDITY_REPORT` + its datamart), their fact bridges
(`F_VACCINATION`, `F_CONTACT_RECORD_CASE`, `F_INTERVIEW_CASE`,
`NOTIFICATION_EVENT`, `TREATMENT_EVENT`, `MORBIDITY_REPORT_EVENT`,
`morb_Rpt_User_Comment`), **and all Tier-2 link edges** that flip the
cross-subject sentinel keys on those fact tables to real FKs.

Column appendix: `lineage/columns/L5_people_links_dims.tsv`: 532 rows,
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
`PROVIDER_LAST_UPDATED_BY` but is *not* a coverage blocker. It only
fires on the UPDATE-with-diff re-run path, the INSERT path used by the
fixture is clean, and the fix is already merged on main (PR #826).

**`D_PLACE` (37/37 VERIFIED).** `sp_nrt_place_postprocessing` reads
`nrt_place` (sourced from `nbs_odse.dbo.Place` + `Entity_id` + locators
via `sp_place_event`) and emits **four UNION-ALL variants** per
`place_uid` (Base / Postal-only / Tele-only / Postal+Tele), so a single
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
`nrt_metadata_columns(D_VACCINATION)` being non-empty (empty at baseline,
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
populated `D_PATIENT`: a `LINK_REQUIRED` resolved by running the Patient
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
event-SP partner**. It reads exclusively from already-populated
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
COALESCE, NULL, which either is allowed or blocks the INSERT, as with
Morbidity's PATIENT_KEY). The fact INSERT succeeds at sentinel; the value
is wrong but the shape is right.

**Tier-2 edges flip the sentinel to a real FK.** There are two mechanisms,
and the distinction is load-bearing for this cluster:

1. **`act_relationship` edges mirrored via a staging soft-ref UPDATE.**
   For Notification, Lab, Morbidity and Treatment, the postprocessing SP
   resolves `INVESTIGATION_KEY` (and CONDITION/MORB keys) by joining
   `dbo.INVESTIGATION` on a PHC UID it reads from a *staging* column:
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

2. **`participation` / `nbs_act_entity` edges, JSON-projection-only at
   the postprocessing layer.** `patient_phc` (SubjOfPHC),
   `reporter_phc` (Per/OrgAsReporterOfPHC), `physician_phc`
   (Physician/InvestgrOfPHC), `phc_roles_nae` (NAE role edges),
   `interview_links` (Intrvwer/Intrvwee/OrgAsSiteOfIntv NAE),
   `contact_links` (SiteOfExposure/InvestgrOfContact/DispoInvestgr NAE),
   `vaccination_links` (SubOfVacc/PerformerOfVacc NAE) all author the
   connective rows correctly and flip the **event-SP JSON projection**
   (verified pre/post), but they do **not** flip any RDB_MODERN dim/fact
   column at the postprocessing layer, because the postprocessing SPs
   read the cross-subject UID from a `nrt_*` soft-ref column (hand-authored
   by Tier 1), never from the graph table. So `F_VACCINATION`,
   `F_CONTACT_RECORD_CASE`, `F_INTERVIEW_CASE` keys resolve through their
   own dimension joins in the merged sequence (after Patient/Provider/Org/
   Investigation/Interview chains run), and these NAE/participation edges
   are documented as *shape-consistency* (they keep the ODSE graph
   honest and unlock the Datamart-layer F_PAGE_CASE INNER JOINs driven by
   the datamart SPs the reporting-pipeline-service fires during the CDC
   drain, which is L6/datamart territory). Several of the edge `type_cd`
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
- **BLOCKED:#03 (resolved):** the 8 `morb_Rpt_User_Comment` columns,
  blocked in pristine baseline, VERIFIED on `aw/odse-test-seed` where the
  bug-3 fix is squashed in. Recorded VERIFIED with the bug cross-reference.
- **Bug #02** (`sp_contact_record_event` 3-part-name error) and **bug #04**
  (provider UPDATE-path typo) touch this cluster but block **no** columns:
  #02 is bypassed because `sp_d_contact_record_postprocessing` reads
  `nrt_contact` directly (and the bug is fixed on main, PR #769); #04 only
  fires on the UPDATE-diff re-run, not the INSERT path (fixed on main,
  PR #826). Both are noted in the relevant transform notes, not flagged
  BLOCKED.
- **No MASTERETL_ONLY columns** in this cluster. Every column has a real
  RTR SP write path and a fixture/coverage proof.

---

## L6: Investigation-repeat, LDF, dyn_dm, page-builder

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
`PIVOT` / `UNPIVOT` statements keyed on **page-builder metadata**:
`nrt_page_case_answer` rows (the staging projection of `nbs_page_answer` /
`nbs_ui_metadata`) for the repeating-block dims, and
`nrt_odse_state_defined_field_metadata` (the projection of ODSE
`state_defined_field*`) for the LDF chain. The guardrail in `LINEAGE.md`
applies in full: for these columns the appendix records the **driving
mechanism** and a `DYNAMIC` status rather than forcing a per-column ODSE
map. Per STRATEGY.md, none of these postprocessing/datamart SPs read
`nbs_odse.dbo.*` directly. They read RDB_MODERN-side staging (`nrt_*`)
and already-built dimensions.

This cluster is heavily bug-capped. Bugs #06–#11 and #13 each cap a
specific column set; affected rows carry `BLOCKED:#NN`.

---

### d_investigation_repeat (+ lookup_table_n_rept, l_investigation_repeat*)

`sp_sld_investigation_repeat_postprocessing` is the repeating-block pivot
SP. It reads **only** `nrt_page_case_answer` (joined to `nrt_investigation`
on `act_uid = public_health_case_uid`) and writes the repeating-block dim
plus its lookup/link tables. No participation or act_relationship walk.
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
In the merged state this dim is **250/253 columns populated over 32 rows**,
i.e. nearly the whole table is `DYNAMIC`, fed by page-builder
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
  `merge_and_verify` time the TEXT pivot silently no-ops for that PHC,
  ~56 TEXT columns regress to NULL. In isolation (`@phc_id_list=N'22007000'`)
  the pivot reaches 250/256. These TEXT columns carry `BLOCKED:#13`.

`lookup_table_n_rept` is RTR-written (catalog/odse_unknown_tables.md
corrects the earlier "MasterETL-only" claim), but is **0/2** in the merged
state: the orchestrator does not invoke the `sp_page_builder_postprocessing`
path that persists it during the merge run, so its row only appears under
the fixture's direct tail-EXEC, marked `BLOCKED:#10`.

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

Because those `PLACE_*` values originate in the L5 place dimension and
this table is only **1/44** in the merged state (the
`zz_d_inv_place_repeat_enrich.sql` fixture's needle-moving depends on
`sp_repeated_place_postprocessing`, which the reporting-pipeline-service
fires via `sp_page_builder_postprocessing` during the CDC drain, gated on
the investigation's `rdb_table_name_list` containing `'D_INV_PLACE_REPEAT'`
— so the fixture must carry that table name for the SP to run), the
`PLACE_*` rows are recorded
`INFERRED` (mechanism clear from the SP body, not yet fixture-confirmed
end-to-end), while the pivot columns and surrogate key, which the fixture
demonstrably exercises, are `VERIFIED`.

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
is the STD-HIV variant covered in the L3 cluster and is **out of scope for
this section**.

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
  additionally blocked at the source: no `condition_cd` 11717 / 10110 rows
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

The entire table is **0/42**. **Bug #11** (`aggregate_report_datamart_schema_mismatch`,
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
"Dynamic-SQL targets (table name resolved at runtime)": they contribute
**no static `(table, col)` rows** to this appendix. Their inputs are the
already-built `D_INVESTIGATION_REPEAT` (read by `repeatvarch/repeatdate/
repeatnumeric`) and the page-case dims. They are wholly `DYNAMIC` by
construction and are documented here as a mechanism rather than per-column.

- **Bug #09** (`dyn_dm_unpivot_type`, *fixed* 2026-05-21):
  `sp_dyn_dm_repeatvarch_postprocessing` built a dynamic UNPIVOT over a
  column list whose member columns carried mismatched types (Msg 8167),
  rolling back the outer transaction (Msg 266). The fix unblocked the
  `sp_dyn_dm_*` chain the reporting-pipeline-service fires during the
  CDC drain.

---

### Status summary for this cluster

- **VERIFIED**: static-mapped columns proven by a fixture + coverage report
  the LDF metadata/data/group/ref tables, `*_ldf_group` links,
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

Note: there is **no bug #14**. The `LINEAGE.md` reference is incorrect;
`aggregate_report` is #11 and the `sld_investigation_repeat` TEXT pivot is
#13. `bugs/` holds dirs 01–13 and #15 (`event_metric_add_user_name_null`,
the SR100 blocker, see section G4).

---

## G1: Core Investigation, HIV, Case-Management & Repeat-Link tables

Gap-fill cluster covering ten RDB_MODERN tables that the original appendix
missed: the core investigation fact (`INVESTIGATION`) and its two
confirmation children (`confirmation_method`, `CONFIRMATION_METHOD_GROUP`),
the SRTE-driven `CONDITION` dimension, the `CASE_COUNT` fact, the
`D_CASE_MANAGEMENT` dimension, the STD/HIV `INV_HIV` bridge, and the three
page-builder repeat-link tables (`L_INVESTIGATION_REPEAT`,
`L_INVESTIGATION_REPEAT_INC`, `L_INV_PLACE_REPEAT`).

Column appendix: `lineage/columns/G1_core_investigation.tsv`: 197 rows,
one per (table, column) the catalog records. 193 VERIFIED, 4 INFERRED, 0
DYNAMIC, 0 MASTERETL_ONLY, 0 BLOCKED.

### How to read the chain for this cluster

Every event-sourced table here follows the STRATEGY.md convention: the
`sp_investigation_event` SP reads `nbs_odse.dbo.*` and projects a JSON
view (it is the **ODSE → staging** edge, recorded in `odse_source_col(s)`);
the matching `sp_nrt_*_postprocessing` SP reads only RDB_MODERN-side
`nrt_*` staging (the **staging → RDB_MODERN** edge, recorded in
`nrt_staging_source` + `transform_note`). One subtlety: a single event SP
(`sp_investigation_event`) is the upstream projector for *three* of this
cluster's postprocessing SPs: investigation, case-management, and
case-count all read staging tables (`nrt_investigation`,
`nrt_investigation_case_management`, `nrt_investigation_confirmation`)
that are slices of that one event SP's nested-JSON output. The
case-management columns in particular trace to the
`investigation_case_management` nested projection of
`nbs_odse.dbo.case_management` at event-SP lines 603-691. `CONDITION` is
the exception: it has **no** event-SP partner and reads SRTE staging
mirrors (`nrt_srte_condition_code`, `nrt_srte_program_area_code`), so its
ultimate source is `nbs_srte.dbo.*` rather than ODSE.

### INVESTIGATION: the core investigation fact (71/71 VERIFIED)

`sp_nrt_investigation_postprocessing` is the heaviest SP in this cluster.
It selects `nrt_investigation` into `#temp_inv_table` (SP:46-132),
applying a uniform `NULLIF(x,'')`/`CASE WHEN '' OR 'null'` blank-to-NULL
discipline and two `isnumeric()`-guarded `CAST … AS int` conversions
(`PATIENT_AGE_AT_ONSET`, `ILLNESS_DURATION`). It then UPDATEs existing
rows (SP:428-503) and INSERTs new ones (SP:536-681), allocating
`INVESTIGATION_KEY` from the `nrt_investigation_key` IDENTITY surrogate.
The upstream `sp_investigation_event` resolves nearly every `*_cd` to a
description through `fn_get_value_by_cd_codeset` against a named INV* code
set (e.g. `case_class_cd`→INV163 for `INV_CASE_STATUS`,
`hospitalized_ind_cd`→INV128, `outcome_cd`→INV145 for
`DIE_FRM_THIS_ILLNESS_IND`), plus SRTE desc joins for jurisdiction, state,
county, program-area, and detection method. All 71 catalog columns map
back to `nbs_odse.dbo.public_health_case` (with locator/code-set joins),
and are VERIFIED across the two fixture variants (foundation = NULL-heavy
blank-path; v2 = fully attributed).

A notable **conditional branch** is the legacy coded-observation overlay
(SP:198-385): when `investigation_form_cd` is one of 14 legacy forms
(`INV_FORM_BMDGAS`/`INV_FORM_HEPGEN`/`INV_FORM_RUB`/…), the SP pulls
coded/text/numeric/date observations from `NRT_INVESTIGATION_OBSERVATION`
via the `v_getobs*` views and COALESCEs them over the direct PHC values
for ~12 columns (HSPTLIZD_IND, IMPORT_FRM_*, FOOD_HANDLR_IND, etc.). The
v2 fixture uses the modern `PG_Hepatitis_A_Acute_Investigation` form, so
the overlay does not fire; the direct-PHC path is what is exercised. The
overlay is documented in transform notes but not separately fixture-proven
(coverage_investigation.md "Legacy investigation form" skip).

### confirmation_method & CONFIRMATION_METHOD_GROUP (3/3 each, VERIFIED)

Both are written by the same SP in its second transaction (SP:705-880).
`#temp_cm_table` joins `dbo.investigation` LEFT JOIN
`nrt_investigation_confirmation` (the event SP's
`investigation_confirmation_method` projection of
`nbs_odse.dbo.Confirmation_method` + the `PHC_CONF_M` SRTE desc). New
confirmation codes allocate a `confirmation_method` key via
`nrt_confirmation_method_key` IDENTITY (SP:805-817).
`CONFIRMATION_METHOD_GROUP` is DELETE-then-INSERT per investigation and
COALESCEs `CONFIRMATION_METHOD_KEY` to sentinel 1 when no real CM row
exists (SP:856). **Caveat worth flagging for the diff tool:** the
`#temp_cm_table` query emits one row per Investigation regardless of
whether a confirmation method is present, so an Investigation with no
`nrt_investigation_confirmation` row still gets a sentinel-1
CONFIRMATION_METHOD_GROUP row, documented as a row-count-integrity bug in
`coverage_std_hiv_full_chain.md` (the "sentinel CMG row" finding). It does
not block any column population here.

### CONDITION: SRTE-sourced dimension (14/15 VERIFIED, 1 INFERRED)

`sp_nrt_srte_condition_code_postprocessing` is an infrastructure SP run
once per merge (`@condition_cd_list = '10110'` for Hep A acute). Unlike
the rest of the cluster it reads SRTE staging mirrors, not ODSE: 13
columns are pass-throughs of `nrt_srte_condition_code` (=
`nbs_srte.dbo.condition_code`); `program_area_desc` joins
`nrt_srte_program_area_code`; `condition_key` is the
`nrt_condition_key` IDENTITY surrogate; and `disease_grp_cd`/`_desc` are a
`CASE LEFT(investigation_form_cd,50)` map to `*_Case` group labels
(SP:70-93). One of the 15 catalog columns is NULL in the merged run
(14/15), most likely `assigning_authority_desc` for the Hep A code,
which lacks an SRTE value; that single column is flagged **INFERRED**.

### CASE_COUNT (13/15 VERIFIED, 2 INFERRED)

`sp_nrt_case_count_postprocessing` reads `NRT_INVESTIGATION` and resolves
13 dimension keys by joining the already-populated RDB_MODERN dimensions
(`INVESTIGATION`, `condition`, `D_PATIENT`, `D_PROVIDER`×3,
`D_ORGANIZATION`×2, `RDB_DATE`×4), each `COALESCE(...,1)`-guarded to
sentinel 1 (SP:52-88). `geocoding_location_key` is a hard-coded literal 1
(no RTR geocoding chain). The two derived count columns,
`investigation_count` and `case_count`, come from
`nrt_investigation.investigation_count`/`case_count`, which the event SP
derives only from the `Summary_Report_Form`→`SUM107` `act_relationship`
chain (event SP:846-867). The merged run leaves these 2 NULL (13/15);
they are flagged **INFERRED** because no fixture authors the summary-form
chain that feeds them.

### D_CASE_MANAGEMENT: needs a case-management ODSE input (62/67 VERIFIED)

`sp_nrt_case_management_postprocessing` reads
`nrt_investigation_case_management` INNER JOIN `INVESTIGATION` (on
CASE_UID) and writes the dimension (SP:52-432). 65 columns pass through
the staging row, `INVESTIGATION_KEY` comes from the INVESTIGATION join,
and `D_CASE_MANAGEMENT_KEY` is the `nrt_case_management_key` IDENTITY
surrogate. **The load-bearing ODSE input is `nbs_odse.dbo.case_management`**:
the entire staging row is the event SP's `investigation_case_management`
nested-JSON projection (event SP:603-691), where each
`case_management.*` column is either passed through or resolved through a
`fn_get_value_by_cvg` code-set lookup (e.g.
`pat_intv_status_cd`→PAT_INTVW_STATUS, `status_900`→STATUS_900,
`fld_foll_up_dispo`→FIELD_FOLLOWUP_DISPOSITION_STDHIV). A handful of
columns also apply `LEFT(x,N)` width truncation in the postprocessing SP
to fit narrow target widths (`init_foll_up_notifiable` LEFT 27,
`initiating_agncy`/`ooj_agency` LEFT 20). The TSV records all 67 columns
VERIFIED against `case_management_staging.sql`; the catalog's "62/67"
reflects 5 columns left NULL in the merged run because the fixture's
short-string UPDATEs do not populate every narrow `*_cd`/date field. The
mapping itself is sound, so each column is attributed to its
`case_management.*` source.

### INV_HIV: STD/HIV bridge over a MasterETL-only dimension (17/19 VERIFIED)

`sp_std_hiv_datamart_postprocessing` populates `INV_HIV` by joining
`F_STD_PAGE_CASE` (which carries `D_INV_HIV_KEY` and `INVESTIGATION_KEY`)
to the `D_INV_HIV` dimension and copying its 15 `HIV_*` columns
(SP:62-159). `INVESTIGATION_KEY` traces back to
`public_health_case.public_health_case_uid` through the INVESTIGATION dim;
`D_INV_HIV_KEY` and all `HIV_*` values originate in **`D_INV_HIV`, which
is a MasterETL-only dimension with no RTR ODSE writer**. The fixture
hand-authors the `D_INV_HIV` row directly (per the
coverage_std_hiv_full_chain.md convention that Tier-3 dimensional-cluster
fixtures may write these MasterETL-only tables when the RTR datamart chain
reads from them). Because the fixture proves all 17 catalog columns
populate end-to-end, they are recorded VERIFIED with the MasterETL-only
provenance noted in `odse_source_col(s)`. The catalog's "17/19" reflects 2
physical table columns RTR's SELECT list never writes (e.g.
HIV_HIV_STAT_INV_IN_EHARS), not in the catalog write-set, so not in this
slice.

### L_INVESTIGATION_REPEAT / _INC / L_INV_PLACE_REPEAT (repeat-link tables)

`sp_sld_investigation_repeat_postprocessing` builds the two
investigation-repeat link tables. `PAGE_CASE_UID` on both is the
`nrt_investigation.public_health_case_uid` (→
`public_health_case.public_health_case_uid`), filtered out of 15 legacy
`investigation_form_cd` values (SP:84-91); the answer payload itself comes
from `nrt_page_case_answer` (NRT_PAGE). `D_INVESTIGATION_REPEAT_KEY` is a
surrogate from `LOOKUP_TABLE_N_REPT` (SP:1165-1203). Both tables are 2/2
VERIFIED (merged coverage: `l_investigation_repeat` 1→2,
`l_investigation_repeat_inc` 0→1). Note the link tables are **not** capped
by the repeat-dim bugs: **bug #10** (`D_REPT_KEY` surrogate pins to
sentinel 1, dropping rows from the wide `D_INVESTIGATION_REPEAT` dim) and
**bug #13** (TEXT-pivot NULL propagation) both affect
`D_INVESTIGATION_REPEAT`'s value columns, not these two-column link
tables, which populate cleanly.

`L_INV_PLACE_REPEAT` is written by `sp_repeated_place_postprocessing`. Its
`D_INV_PLACE_REPEAT_KEY` is a `DENSE_RANK()`-allocated surrogate (SP:393-412)
and is populated (the sentinel row), but `PAGE_CASE_UID`,
sourced from `nrt_page_case_answer.act_uid` via the
`PlaceAsHangoutOfPHC`/`PlaceAsSexOfPHC` part-type pivot (SP:46-67), is
**NULL in the merged run (1/2)**. Two things keep it unpopulated:
`sp_repeated_place_postprocessing` only runs when the
reporting-pipeline-service fires it via `sp_page_builder_postprocessing`
during the CDC drain — gated on the investigation's `rdb_table_name_list`
containing `'D_INV_PLACE_REPEAT'`, which the fixture must carry (the
ORCH_TODO in `zz_d_inv_place_repeat_enrich.sql`) — and the place-repeat
answer rows + a matching `D_PLACE.PLACE_LOCATOR_UID` must both exist for
the SP's INNER JOIN to emit a non-sentinel row.
`PAGE_CASE_UID` is therefore flagged **INFERRED**: the mapping is read
from the SP body but no merged fixture proves it.

---

## G2: TB / Varicella PAM facts, LDFs, STD page-case fact & BMIRD/Pertussis groups

Gap-fill slice for the PAM facts/dims, page-case fact, LDF dynamic tables,
and the tiny BMIRD/pertussis group-bridge tables that L3 narrated but did
not enumerate. Column-level lineage is in
`lineage/columns/G2_tbvar_pam.tsv` (233 rows). All eleven tables are
downstream consumers; none read `nbs_odse` directly (STRATEGY.md
convention: only `sp_*_event` SPs read ODSE; the
postprocessing/datamart layer reads `nrt_*` staging + RDB_MODERN
dimensions). The ODSE columns in the appendix are therefore the
*synthesis hop*: the `sp_investigation_event` JSON projection that feeds
`nrt_investigation` / `nrt_page_case_answer`.

**Status accounting** (233 rows): VERIFIED 89, INFERRED 122, DYNAMIC 4,
MASTERETL_ONLY 18. As with L3, the high INFERRED count is honest, not a
gap: the PAM pivot and the F_STD_PAGE_CASE keystore *map* every column,
but the minimum-viable full-chain fixtures author a deliberately small
set of PAM questions / dimension rows / participation edges to prove each
SP runs end-to-end. Un-authored columns are INFERRED (SP clearly maps
them, no fixture proves the specific col), never confabulated.

---

### D_VAR_PAM (129 cols): `sp_nrt_d_var_pam_postprocessing` (215)

`D_VAR_PAM` is the Varicella PAM dimension and the structural twin of
L3's `D_TB_PAM`. The SP filters `nrt_page_case_answer` to the
investigation's `INV_FORM_VAR` answers (`data_location =
'NBS_Case_Answer.answer_txt'`, `ldf_status_cd IS NULL`, SP lines 86-92),
code-translates coded answers through `nrt_srte_code_value_general` (with
special handling for STATE/COUNTY/COUNTRY/jurisdiction/program code-sets,
SP lines 126-194 (e.g. `PATIENT_BIRTH_COUNTRY` resolves `PSL_CNTRY`
answers via `nrt_srte_country_code.code_desc_txt`), then `PIVOT`s
`MAX(ANSWER_TXT) FOR DATAMART_COLUMN_NM` over the explicit ~122-column
IN-list (SP lines 263-301). **Every pivot column is exactly one VAR
question's `answer_txt`**, tagged by `nbs_question.datamart_column_nm`;
the ODSE source is `nbs_odse.dbo.nbs_case_answer.answer_txt`.

Keys: `D_VAR_PAM_KEY` is allocated from the `nrt_var_pam_key` keystore
(SP line 510); `VAR_PAM_UID` is the page-case `public_health_case_uid`;
`LAST_CHG_TIME` is the answer-set last-change time. Coverage
(`coverage_varicella_full_chain.md` + `zz_var_datamart_enrich.sql` →
127/129 in `coverage_merged.md`): the fixture proves the key/UID/time
columns plus a ~25-question minimum-viable set (`VARICELLA_VACCINE`,
`RASH_LOCATION`, `VESICLES`, `FEVER`, `PCR_TEST`/`PCR_TEST_RESULT`,
`COMPLICATIONS*`, `EPI_LINKED`, `TRANSMISSION_SETTING`, etc.). The other
~100 pivot columns are INFERRED, fed by VAR questions the fixture did
not author (a fixture-completeness exercise, not an infrastructure
block).

### F_TB_PAM (20 cols): `sp_f_tb_pam_postprocessing` (206); F_VAR_PAM (12 cols): `sp_f_var_pam_postprocessing` (240)

These are the TB/Varicella PAM **fact** tables: all-key rows that hang
the PAM dimension off the patient/provider/org dimensions, the
topic-group dimensions, and the date dimension. Both read the
`INV_FORM_RVCT` / `INV_FORM_VAR` rows of `nrt_investigation` for the
driving UID set, then build per-UID keystores that resolve each
entity UID to a surrogate key: `nrt_investigation.patient_id` →
`D_PATIENT.PATIENT_KEY`, `investigator_id`/`physician_id`/
`person_as_reporter_uid` → `D_PROVIDER.PROVIDER_KEY`, and
`hospital_uid`/`org_as_reporter_uid` → `D_ORGANIZATION.ORGANIZATION_KEY`
(all `COALESCE(..., 1)`). `INVESTIGATION_KEY` joins `INVESTIGATION` on
`CASE_UID`; `ADD_DATE_KEY`/`LAST_CHG_DATE_KEY` resolve via `RDB_DATE` on
the staging add/last-change times; `D_*_PAM_KEY` is the FK to the PAM
pivot. F_TB_PAM additionally carries the 10 TB topic-group keys
(`D_DISEASE_SITE_GROUP_KEY`, `D_ADDL_RISK_GROUP_KEY`, `D_MOVE_*`,
`D_GT_12_REAS_GROUP_KEY`, `D_HC_PROV_TY_3_GROUP_KEY`,
`D_OUT_OF_CNTRY_GROUP_KEY`, `D_MOVED_WHERE_GROUP_KEY`,
`D_SMR_EXAM_TY_GROUP_KEY`), and F_VAR_PAM the two VAR topic-group keys
(`D_RASH_LOC_GEN_GROUP_KEY`, `D_PCR_SOURCE_GROUP_KEY`); these inherit
the multi-value page-answer lineage from their `D_*` topic dimensions
(group key set by the `sp_nrt_d_*_postprocessing` group-dim SPs, which
the catalog lists as co-writers via UPDATE).

The whole F_VAR_PAM body is gated by an `IF EXISTS` on condition
`10030` having `PORT_REQ_IND_CD = 'T'` (SP lines 47-51). Both facts are
VERIFIED (F_TB_PAM 20/20, F_VAR_PAM 12/12 in `coverage_merged.md`,
spot-checked in the coverage reports), but note that the
physician/reporter/hospital/provider keys resolve to **sentinel 1**:
the standalone TB/VAR Phase-2 investigations carry no `PhysicianOfPHC` /
`PerAsReporterOfPHC` / `OrgAsReporterOfPHC` / `HospOfADT` participation
edges (the `LINK_REQUIRED` gap in both coverage reports). The values are
populated and the mapping verified; only the *resolved* (non-sentinel)
value awaits a Tier-2 edge follow-on.

### D_TB_HIV (6 cols): `sp_nrt_d_tb_hiv_postprocessing` (160)

A narrow PAM sub-pivot: it filters `nrt_page_case_answer` for the RVCT
investigation to the three HIV questions `TUB154`/`TUB155`/`TUB156` (SP
line 104), code-translates, then `PIVOT`s into `HIV_STATE_PATIENT_NUM`,
`HIV_STATUS`, `HIV_CITY_CNTY_PATIENT_NUM` (SP lines 300-312). `TB_PAM_UID`
is `CAST(ACT_UID AS BIGINT)`, `D_TB_HIV_KEY` is from the `nrt_d_tb_hiv_key`
keystore, `LAST_CHG_TIME` is the `MAX` over the three answers. These three
HIV columns are the verified path L3 cited as feeding `TB_HIV_DATAMART`'s
`HIV_*` block. All 6/6 VERIFIED (`coverage_tb_full_chain.md`).

### TB_PAM_LDF (5 cols): `sp_nrt_tb_pam_ldf_postprocessing` (220); VAR_PAM_LDF (5 cols): `sp_nrt_var_pam_ldf_postprocessing` (235)

These are the LDF (locally-defined field) tables, the clearest example
in the cluster of the **page-builder/PAM-answer dynamic-pivot
mechanism**. Each SP filters `nrt_page_case_answer` to the RVCT/VAR
investigation's *LDF-flagged* answers (`LDF_STATUS_CD IN
('LDF_UPDATE','LDF_CREATE','LDF_PROCESSED')`, SP 220 lines 83-85), runs
the answer through the SRTE translation ladder (code_value_general →
clinical → state → country, with `STRING_AGG` concatenation for
multi-select), then discovers which `datamart_column_nm` values are
*not* yet columns of the target table, **`ALTER TABLE ... ADD`s those
columns at runtime**, and finally `PIVOT`s `MAX(ANSWER_TXT) FOR
DATAMART_COLUMN_NM IN (<dynamic list>)` into them via `sp_executesql`
(SP 220 lines 344-491). Because the column set is whatever LDF questions
exist in `nbs_page_answer` / `nbs_question` metadata, the data columns
are **not statically derivable**.

In the appendix the three base columns are static and VERIFIED:
`INVESTIGATION_KEY` (LEFT JOIN `investigation` on `*_PAM_UID = CASE_UID`),
`*_PAM_UID` (the page-case `ACT_UID`), and `ADD_TIME` (the answer's
`NCA_ADD_TIME`, present in the SP INSERT and the live 6/6 population but
missing from the static catalog extract). The two columns the catalog
*did* statically capture, `END` and `THEN`, are SQL-keyword
`datamart_column_nm` values from LDF questions and are flagged
**DYNAMIC** (driving table: `nbs_page_answer` / `nbs_question` LDF
metadata). The coverage reports note both tables show **0 rows** in the
TB/VAR full-chain runs (LDF_GAP: the full-chain fixtures author only
`ldf_status_cd IS NULL` answers); `coverage_merged.md` shows **6/6** for
both because `zz_ldf_flagged_answers.sql` later authors LDF-flagged
`nrt_page_case_answer` rows for the RVCT/VAR PHCs and tail-EXECs these
two SPs (the orchestrator does not call them in its main chain).

### F_STD_PAGE_CASE (52 cols): `sp_f_std_page_case_postprocessing` (025)

The STD/HIV page-case **fact**: an all-key row that L3's
`STD_HIV_DATAMART` joins to reach the `D_INV_*` dimensional cluster. It
reads `nrt_investigation` (+ `nrt_investigation_case_management`) for
non-PAM, case-managed investigations (the form-cd exclusion list at SP
lines 152-154, gated on `CASE_MANAGEMENT_UID IS NOT NULL`), then resolves
three families of keys:

1. **Entity keys** (`PATIENT_KEY`, `PHYSICIAN_KEY`, `INVESTIGATOR_KEY`,
   `HOSPITAL_KEY`, `ORG_AS_REPORTER_KEY`, plus the ~14 follow-up /
   delivery / OB-GYN provider+org keys): each `COALESCE(..., 1)` joins a
   UID column on the staging row to `D_PATIENT`/`D_PROVIDER`/
   `D_ORGANIZATION` (SP lines 176-239). `CONDITION_KEY` joins `CONDITION`
   on `CD`; `ADD_DATE_KEY`/`LAST_CHG_DATE_KEY` join `RDB_DATE`;
   `INVESTIGATION_KEY` joins `INVESTIGATION` on `CASE_UID`.
2. **`D_INV_*_KEY` dimensional keys** (24 of them): each
   `COALESCE(..., 1)` resolves through an `L_INV_*` link table to a
   `D_INV_*` dimension keyed on `PAGE_CASE_UID` (SP lines 265-289).
3. **`GEOCODING_LOCATION_KEY`**: joins `GEOCODING_LOCATION` on the
   patient entity UID.

The `D_INV_*`/`L_INV_*` dimensions and `GEOCODING_LOCATION` are
**MasterETL-only** persistent dimensions: no RTR SP populates them from
ODSE (see L3 and `catalog/odse_unknown_tables.md`). The STD full-chain
fixture hand-authors **five** D_INV/L_INV pairs (HIV, ADMINISTRATIVE,
CLINICAL, EPIDEMIOLOGY, COMPLICATION), so those 5 keys + the
entity/condition/date keys are VERIFIED; the other 17 `D_INV_*` keys and
`GEOCODING_LOCATION_KEY` are flagged `MASTERETL_ONLY` (they populate at
sentinel 1 because no `L_INV_*` row exists for them). `D_INVESTIGATION_REPEAT_KEY`
/ `D_INV_PLACE_REPEAT_KEY` are INFERRED (those dims *are* RTR-populated
in the L6 cluster, but no `L_*` row links this PHC). The 14 follow-up /
delivery cross-subject keys are INFERRED (sentinel 1, no Tier-2
participation edges, the coverage report's `LINK_REQUIRED` gap). Two RTR
issues surfaced here, both documented in `coverage_std_hiv_full_chain.md`:
the orchestrator `@phc_ids` vs `@phc_id_list` parameter-name mismatch
(Bug #M: F_STD_PAGE_CASE stays 0 rows in the orchestrated path until
fixed), and the sentinel-`CONFIRMATION_METHOD_GROUP` join-cardinality
issue on the downstream datamart.

### BMIRD & Pertussis group-bridge tables (1 col each)

`ANTIMICROBIAL_GROUP` and `BMIRD_MULTI_VALUE_FIELD_GROUP` (written by
`sp_bmird_case_datamart_postprocessing`, SP 040) and
`PERTUSSIS_SUSPECTED_SOURCE_GRP` and `PERTUSSIS_TREATMENT_GROUP` (written
by `sp_pertussis_case_datamart_postprocessing`, SP 043) are
single-column **group-bridge** tables. Each holds one surrogate
group-key column (`*_GRP_KEY`). The mechanism is identical across all
four: the datamart SP computes a multi-value group key per
investigation; for PHCs whose group key is **unresolved** (left at the
sentinel value 1 because no matching multi-value/antimicrobial group
exists), it loads `public_health_case_uid` into a `nrt_*_group_key`
keystore (which DELETEs then re-INSERTs every run), then `INSERT`s the
allocated `*_GRP_KEY` from that keystore into the group-bridge table
(SP 040 lines 398-425 and 588-612; SP 043 lines 605-632 and 816-838).
There is **no direct ODSE column**: the value is a generated surrogate
key, so the appendix records the keystore as the staging source and
`—` for the ODSE column. All four are VERIFIED at 1/1 in
`coverage_merged.md` (the full-chain fixtures for BMIRD/pertussis each
produce the single sentinel group row).

These tables relate to the L3 BMIRD note about **bug #12**: SP 040's
`ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ...)`
collapses `BMIRD_MULTI_VALUE_FIELD` to one row per investigation, capping
the `_2`+ pivot slots on `BMIRD_STREP_PNEUMO_DATAMART`. The group-bridge
tables themselves are not blocked (they only ever hold the sentinel
group key in the current fixtures), but the bug is why their downstream
multi-value fan-out stays single-slot.

---

### Cross-cutting notes

- **No PAM/fact/LDF SP reads `nbs_odse` directly.** ODSE columns are the
  `sp_investigation_event` projection that feeds `nrt_investigation` /
  `nrt_page_case_answer`.
- **The PAM-answer pivot** (D_VAR_PAM, D_TB_HIV) and the **dynamic LDF
  pivot** (TB_PAM_LDF, VAR_PAM_LDF) are the same idiom at two levels of
  staticness: D_VAR_PAM/D_TB_HIV pivot over a *fixed* IN-list (statically
  mappable → INFERRED/VERIFIED per column), whereas the LDF tables
  `ALTER TABLE` + pivot over a *runtime-discovered* `datamart_column_nm`
  list (DYNAMIC for the answer columns; only the base keys are static).
- **`MASTERETL_ONLY`** on F_STD_PAGE_CASE means the `D_INV_*` /
  `GEOCODING_LOCATION` dimension is a persistent dim RTR joins but does
  not populate from ODSE; the STD fixture hand-authors a subset so the
  join resolves.
- **Sentinel-1 keys are populated, not missing.** Several VERIFIED fact
  keys (provider/org/physician on F_TB_PAM/F_VAR_PAM/F_STD_PAGE_CASE)
  resolve to 1 only because the Phase-2 investigations lack Tier-2
  participation edges (`LINK_REQUIRED`): the mapping is proven, the
  resolved value awaits an edge fixture.

---

## G3: PAM dimension code & group tables (TB / Varicella)

**Cluster**: the 12 page-answer-driven PAM "code + group" dimension pairs that
hang off the TB and Varicella PAM fact tables (`F_TB_PAM` / `F_VAR_PAM`) and
their root dims (`D_TB_PAM` / `D_VAR_PAM`). Each pair is one *value* dimension
plus its one-column `_GROUP` partner:

| Dimension (6/6 cols) | Group (1/1 col) | Writer SP | Question | PAM family |
| --- | --- | --- | --- | --- |
| `D_ADDL_RISK` | `D_ADDL_RISK_GROUP` | `sp_nrt_d_addl_risk_postprocessing` (146) | TUB167 | TB |
| `D_DISEASE_SITE` | `D_DISEASE_SITE_GROUP` | `sp_nrt_d_disease_site_postprocessing` (145) | TUB119 | TB |
| `D_GT_12_REAS` | `D_GT_12_REAS_GROUP` | `sp_nrt_d_gt_12_reas_postprocessing` (170) | TUB235 | TB |
| `D_HC_PROV_TY_3` | `D_HC_PROV_TY_3_GROUP` | `sp_nrt_d_hc_prov_ty_3_postprocessing` (180) | TUB237 | TB |
| `D_MOVED_WHERE` | `D_MOVED_WHERE_GROUP` | `sp_nrt_d_moved_where_postprocessing` (195) | TUB225 | TB |
| `D_MOVE_CNTRY` | `D_MOVE_CNTRY_GROUP` | `sp_nrt_d_move_cntry_postprocessing` (156) | TUB230 | TB |
| `D_MOVE_CNTY` | `D_MOVE_CNTY_GROUP` | `sp_nrt_d_move_cnty_postprocessing` (175) | TUB228 | TB |
| `D_MOVE_STATE` | `D_MOVE_STATE_GROUP` | `sp_nrt_d_move_state_postprocessing` (185) | TUB229 | TB |
| `D_OUT_OF_CNTRY` | `D_OUT_OF_CNTRY_GROUP` | `sp_nrt_d_out_of_cntry_postprocessing` (190) | TUB114 | TB |
| `D_PCR_SOURCE` | `D_PCR_SOURCE_GROUP` | `sp_nrt_d_pcr_source_postprocessing` (230) | VAR176 | Varicella |
| `D_RASH_LOC_GEN` | `D_RASH_LOC_GEN_GROUP` | `sp_nrt_d_rash_loc_gen_postprocessing` (225) | VAR105 | Varicella |
| `D_SMR_EXAM_TY` | `D_SMR_EXAM_TY_GROUP` | `sp_nrt_d_smr_exam_ty_postprocessing` (200) | TUB129 | TB |

24 tables; 84 columns; **all VERIFIED** in the merged state (every dimension
6/6, every group 1/1, per `coverage_merged.md`).

---

### The shared SP template

These 12 SPs are near-identical clones; reading 145/146/185/225/230 establishes
the whole family. Each one materializes a *single multi-answer PAM question* (a
"repeating-block" page answer) into a value dimension + a group dimension that
collects the per-investigation answer set. Per STRATEGY.md, none of them read
`nbs_odse.dbo.*`; they read RDB_MODERN-side staging only. The pipeline is:

```
nbs_case_answer / PAM page answer  (ODSE-side; one row per answered question)
   → CDC → Debezium → kafka-connect → nrt_page_case_answer  (staging projection)
   → sp_nrt_d_<X>_postprocessing  → D_<X> + D_<X>_GROUP  (RDB_MODERN)
```

Step-by-step, the template is:

1. **`#S_PHC_LIST`**: split the proc argument into a PHC-UID temp table.
   Most SPs take `@phc_uids` and `STRING_SPLIT(@phc_uids, ',')`; a newer subset
   (170, 180, 190, 200, 230) take **`@phc_id_list`** and use
   `SELECT TRIM(value) FROM STRING_SPLIT(@phc_id_list, ',')` inline (no temp
   table), the only signature deviation in the family. The orchestrator
   passes the correct argument name per SP (see `coverage_tb_full_chain.md`).
2. **`#S_<X>_TRANSLATED`**: select from `NRT_PAGE_CASE_ANSWER` filtered to
   `QUESTION_IDENTIFIER = '<the SP's question>'` and `DATAMART_COLUMN_NM <> 'n/a'`,
   `LEFT JOIN NRT_INVESTIGATION` on `act_uid = public_health_case_uid`
   (with the `isnull(tb.batch_id,1)=isnull(inv.batch_id,1)` batch guard),
   `INNER JOIN #S_PHC_LIST` on `act_uid`. `CAST(act_uid AS BIGINT)` becomes the
   grain key: `TB_PAM_UID` for TB tables, `VAR_PAM_UID` for the two Varicella
   tables. The answer text is decoded against SRTE: join
   `nrt_srte_codeset_group_metadata` on `CODE_SET_GROUP_ID` to resolve
   `CODE_SET_NM`, then join the code-value table on `(CODE_SET_NM, CODE=ANSWER_TXT)`.
3. **`#S_<X>`**: derive `VALUE`. Two transform shapes (see deviations below).
4. **Delete-then-reload**: compute `#TEMP_D_<X>_DEL` (existing dim rows for
   these PHCs), delete the matching rows from the two `NRT_<X>_KEY` /
   `NRT_<X>_GROUP_KEY` surrogate-key staging tables and from `D_<X>`, then
   re-insert fresh surrogate keys (`NRT_<X>_GROUP_KEY` by `TB_PAM_UID`/`VAR_PAM_UID`,
   `NRT_<X>_KEY` by `(PAM_UID, NBS_CASE_ANSWER_UID)`). These IDENTITY-allocated
   keys are RTR-internal surrogates (**no ODSE source**).
5. **Build link temps**: `#D_<X>_PAM_TEMP` from `D_TB_PAM`/`D_VAR_PAM`,
   `#L_<X>_GROUP` and `#L_<X>` join the surrogate keys; missing keys collapse to
   the sentinel `1` via `CASE WHEN … IS NULL THEN 1`.
6. **Load**: INSERT new `D_<X>_GROUP` rows (DISTINCT group keys), then
   UPDATE-existing + INSERT-new into `D_<X>` writing the six columns
   (`<PAM>_PAM_UID`, `D_<X>_KEY`, `SEQ_NBR`, `D_<X>_GROUP_KEY`, `LAST_CHG_TIME`,
   `VALUE`). Finally **push `D_<X>_GROUP_KEY` onto the fact** via
   `UPDATE F_TB_PAM`/`F_VAR_PAM … SET D_<X>_GROUP_KEY = …` joined through
   `D_TB_PAM`/`D_VAR_PAM`, and garbage-collect orphaned group rows.

So for every dimension: `<PAM>_PAM_UID`, `SEQ_NBR`, `LAST_CHG_TIME` carry
through from the page answer; `VALUE` is the decoded answer; the two `_KEY`
columns are RTR surrogate keys; and `D_<X>_GROUP` holds just the surrogate
group key. The driving mechanism is a **fixed page-answer question pivot**:
the value is page-answer-sourced (`nbs_case_answer` → `nrt_page_case_answer`),
*not* a static ODSE column, but because each SP keys on a hard-coded
`QUESTION_IDENTIFIER` (not runtime page-builder metadata) the column set is
fully static, statically mappable, and fixture-proven. These are therefore
**VERIFIED**, not DYNAMIC: the `nbs_case_answer`/PAM-page → `nrt_page_case_answer`
edge is the honest ODSE-side source recorded in the appendix.

### Per-table deviations

The SPs are templated to the point of being clones; only three axes vary, all
captured in the appendix `transform_note`:

- **Argument name**: 170/180/190/200/230 use `@phc_id_list` (+ `TRIM`); the
  other seven use `@phc_uids`. No effect on the column map.
- **`VALUE` transform shape**: two forms.
  - **CASE form** (145, 146, 170, 180, 190, 200, 230):
    `CASE WHEN CODE_SET_GROUP_ID IS NULL OR ='' THEN ANSWER_TXT ELSE
    CODE_SHORT_DESC_TXT END`, falls back to the raw answer text when the
    answer is free-text (no code set).
  - **Direct form** (156, 175, 185, 195, 225): `CODE_SHORT_DESC_TXT AS VALUE`
    with no fallback (these questions are always coded).
- **Code-value source table**: most decode against
  `nrt_srte_code_value_general` (alias yields `CODE_SHORT_DESC_TXT`). Two
  geography questions decode against **`nrt_srte_state_county_code_value`**
  instead: `D_MOVE_CNTY` (175, county) keeps `CODE_SHORT_DESC_TXT`, while
  `D_MOVE_STATE` (185, state) aliases **`CODE_DESC_TXT`** (the only SP that
  reads `CODE_DESC_TXT` rather than `CODE_SHORT_DESC_TXT`).
- **PAM family / grain column**: `D_PCR_SOURCE` (230) and `D_RASH_LOC_GEN`
  (225) are the two **Varicella** tables: grain key `VAR_PAM_UID`, joined to
  `D_VAR_PAM`, fact pushed to `F_VAR_PAM`. The other ten are **TB**:
  `TB_PAM_UID`, `D_TB_PAM`, `F_TB_PAM`.

### Verification

Both PAM families are proven end-to-end. `tb_investigation_full_chain.sql`
authors one `nbs_case_answer` + `nrt_page_case_answer` pair per TUB question
(TUB114/119/129/167/225/228/229/230/235/237 all present) and runs the ten TB
cluster SPs; `coverage_tb_full_chain.md` records each TB dim at 6/6 with sample
`VALUE`s (`D_DISEASE_SITE='Pulmonary'`, `D_ADDL_RISK='Diabetes Mellitus'`,
`D_MOVE_CNTRY='UNITED STATES'`, `D_MOVE_STATE='Georgia'`,
`D_MOVED_WHERE='Out of the U.S.'`, `D_HC_PROV_TY_3='Private Outpatient'`,
`D_GT_12_REAS='Non-adherence'`, `D_SMR_EXAM_TY='Pathology/Cytology'`).
`varicella_investigation_full_chain.sql` authors VAR105 + VAR176 and runs the
two Varicella SPs; `coverage_varicella_full_chain.md` records
`D_RASH_LOC_GEN='Trunk'` and `D_PCR_SOURCE='Scab'`, each 6/6, plus the group
keys flowing onto `F_VAR_PAM`. `coverage_merged.md` confirms all 24 tables at
6/6 (dims) / 1/1 (groups) in the full merged run.

*Note*: `coverage_tb_full_chain.md` labels `D_DISEASE_SITE` as "7/7"; this is a
typo in that report. The catalog (the appendix spine) and the SP both define
six columns for the table, and `coverage_merged.md` lists it as 6/6.

### Status summary for this cluster

- **VERIFIED (84/84)**: every column of all 24 tables. The dim grain/answer
  columns trace to the PAM page answer (`nbs_case_answer` → `nrt_page_case_answer`)
  via a fixed `QUESTION_IDENTIFIER` pivot + SRTE code decode; the `_KEY` /
  `_GROUP_KEY` columns are RTR-internal surrogates (no ODSE source, correctly
  recorded as such). No INFERRED, DYNAMIC, MASTERETL_ONLY, or BLOCKED rows;
  the family is wholly fixture-proven and bug-free, and **as templated as
  expected**.

---

## G4: Operational, audit & blocked tables

This section covers eight RDB_MODERN tables that sit **outside** the
`ODSE source col → … → RDB_MODERN col` subject-data lineage the rest of
this document traces. Seven of them are RTR-internal **operational /
audit** tables: per-run job logs (`JOB_FLOW_LOG`, `JOB_BATCH_REBUILD_LOG`),
a data-quality side-channel (`ETL_DQ_LOG`), event-processing metric buffers
(`EVENT_METRIC`, `EVENT_METRIC_INC`), a generated calendar dimension
(`RDB_DATE`), and a user/provider profile lookup (`USER_PROFILE`). For
most of these the honest source is **RTR runtime state**: the emitting SP
name, batch ids, timestamps, `@@ROWCOUNT`, error text, or a hard-coded
literal, not an `nbs_odse.dbo.*` column. Where that is the case the
column appendix records the operational source in `transform_note` and
marks the row `INFERRED` rather than confabulating an ODSE chain. The
eighth table, `SR100`, *is* a real condition-summary datamart with a
genuine source chain, but it is **blocked at 0 rows by bug #15** and so is
documented as `BLOCKED:#15` for every column. Two of these tables do carry
honest staging-sourced lineage and are flagged `VERIFIED` accordingly:
`USER_PROFILE` (reads `nrt_auth_user`) and `EVENT_METRIC` /
`EVENT_METRIC_INC` (read the `nrt_investigation` / `nrt_observation` /
`nrt_contact` / `nrt_auth_user` event-staging tables, fully consistent
with the postprocessing-reads-NRT convention).

**ETL_DQ_LOG** (14/15 cols live, ~6200 rows) is a **data-quality
failure side-channel**. An earlier triage marked it MasterETL-only; it is
in fact RTR-written. Three RTR routines INSERT into it on a DQ-fail
branch: `sp_s_pagebuilder_postprocessing` (007), the SLD-repeat SP (010),
and `sp_f_std_page_case_postprocessing` (025). When a page-builder answer
fails validation, either a non-numeric value where numeric is expected
(`isNumeric(ANSWER_VALUE) != 1`, SP 007 line ~477) or a malformed date
(`ISDATE(ANSWER_TXT) != 1`, line ~817), the SP logs the offending row:
the investigation's `LOCAL_ID` / `PUBLIC_HEALTH_CASE_UID`, the literal
issue code/description, and the page-builder metadata for the failing
answer (`QUESTION_IDENTIFIER`, the bad `ANSWER_TXT` value itself,
`DATA_LOCATION`, target `rdb_table_nm` / `RDB_COLUMN_NM`, `QUESTION_LABEL`)
plus the run's `@Batch_id` and `GETDATE()`. The source is page-builder
runtime state and the offending value, so columns are `INFERRED`: it only
populates when a fixture deliberately exercises a DQ-fail branch.

**EVENT_METRIC** (28/28) and **EVENT_METRIC_INC** (28/28) are
**event-processing metrics**: one snapshot row per surveillance event
(notification / observation / investigation / contact) capturing its
class, condition, jurisdiction, status, prog-area and timing.
`sp_event_metric_datamart_postprocessing` (037) builds `#TMP_EVENT_METRIC`
from several branches over `nrt_investigation_notification`,
`nrt_observation`, `nrt_investigation`, and `nrt_contact`, resolving code
descriptions via SRTE and user names via `nrt_auth_user`. It INSERTs into
the incremental buffer `EVENT_METRIC_INC` (line 963); the cleanup SP
`sp_event_metric_cleanup_postprocessing` (345) later migrates rows into
the durable `EVENT_METRIC` after a configurable lookback window. These are
operational metrics, not ODSE subject-data, but the staging reads are
real, so most columns are `VERIFIED`. The exception is the
**`ADD_USER_NAME`** column on both tables: the investigation branch at
line ~634 (`FROM dbo.nrt_investigation phc`) selects `add_user_id` but
omits the `LEFT JOIN dbo.nrt_auth_user`, so its rows get
`ADD_USER_NAME = NULL`. This is the layer-2 root cause of **bug #15** and
is flagged `BLOCKED:#15`.

**JOB_FLOW_LOG** (14/15 cols live, ~25,825 rows) is the pipeline's
**operational run-log**, written by ~37 RTR routines as flow logging.
Every postprocessing / datamart SP opens with a `START` row, writes a row
after each step with the step number, step name and `@@ROWCOUNT`, and
closes with a `COMPLETE` row; on failure the `BEGIN CATCH` writes an
`ERROR` row carrying `@FullErrorMessage` (assembled from `ERROR_NUMBER` /
`SEVERITY` / `STATE` / `LINE` / `MESSAGE`) and the truncated id-list in
`MSG_DESCRIPTION1`. Every value is RTR runtime state: batch id,
timestamps, the SP's own `@dataflow_name` / `@package_name` literals,
status literals, step counters, so all columns are `INFERRED` with the
operational source noted. There is no ODSE input.

**JOB_BATCH_REBUILD_LOG** is **MISSING from the live RDB** and has **no
RTR writer**. The only routine that touches it,
`sp_sld_investigation_repeat_postprocessing` (010), merely *reads* /
conditionally `UPDATE`s it inside an `IF OBJECT_ID('job_batch_rebuild_log')
IS NOT NULL` guard (lines 41-69) to decide whether to rebuild the
page-builder repeating-question dimension. It never INSERTs. The table is
therefore a MasterETL-side artifact from RTR's perspective; it is
documented as a single `MASTERETL_ONLY` appendix row.

**RDB_DATE** (11/11) is a **generated calendar/date dimension with no ODSE
source**. `sp_get_date_dim` takes `@start`/`@end` year integers and walks a
date spine in a `WHILE` loop, deriving every column from the iterated date
(`DATENAME`, `DATEPART`, `DAY`, `MONTH`, `YEAR`, and a legacy
Saturday-counting week rule). `DATE_KEY = 1` is reserved for the
NULL/unknown date row; real dates start at `DATE_KEY = 2` for 1990-01-01.
Columns are `VERIFIED` against the live 4019-row dimension but the
appendix `odse_source_col(s)` honestly reads "(generated utility, no ODSE
source)". (Note: the STRATEGY baseline records an RTR bug in this SP under
6.0.18.1; `RDB_DATE` is populated by the liquibase onboarding seed
`onboarding-rdb-date-seed`, which EXECs `sp_get_date_dim @start=1990
@end=2030` on baseline `up` from a fixed copy. The column logic above is
the SP's intent.)

**USER_PROFILE** (8/8) is the one operational-adjacent table with
**genuine staging-sourced lineage**. `sp_user_profile_postprocessing` (027)
reads `dbo.nrt_auth_user` (the auth-user staging table, the ODSE
`auth_user` projection) for `FIRST_NM`, `LAST_NM`, `LAST_CHG_TIME`,
`NEDSS_ENTRY_ID` and `PROVIDER_UID`, derives `USER_NM` via a
last/first-name CASE, and joins `D_PROVIDER` on `PROVIDER_UID` to attach
`PROVIDER_KEY` (`COALESCE(...,1)` sentinel) and `PROVIDER_QUICK_CODE`. It
dedupes to one row per `NEDSS_ENTRY_ID`. All eight columns are `VERIFIED`.

**SR100** (0/20) is the **blocked condition-summary report datamart**.
`sp_sr100_datamart_postprocessing` (155) builds `#temp_sr100` (one row,
verified to build) by joining `SUMMARY_REPORT_CASE`, `INVESTIGATION`,
`SUMMARY_CASE_GROUP`, `dbo.condition`, `RDB_DATE`, `nrt_srte_state_county_code_value`,
`v_code_value_general`, `CASE_COUNT`, and `EVENT_METRIC` (INNER JOIN on
`em.local_id = I.inv_local_id`). The chain resolves, but the final INSERT
fails: **`SR100.ADD_USER_NAME` is NOT NULL while
`EVENT_METRIC.ADD_USER_NAME` is NULL** (the bug-#15 line-634 branch never
joined `nrt_auth_user`), raising **Msg 515** which the SP's outer
`TRY/CATCH` swallows, so the pipeline sees success while SR100 stays
empty at 0 rows. This is **not** a fixture-fixable gap (seeding `nrt_auth_user` and setting
`add_user_id` was verified to leave `EVENT_METRIC.ADD_USER_NAME` NULL); it
requires an RTR fix (uniformly apply the line-819 `nrt_auth_user` join to
every `#TMP_EVENT_METRIC` branch, relax the SR100 NOT NULL, or
`COALESCE(...,'')` the SR100 insert). Every SR100 column is therefore
flagged `BLOCKED:#15`, with `ADD_USER_NAME` itself called out as the
blocking column.
