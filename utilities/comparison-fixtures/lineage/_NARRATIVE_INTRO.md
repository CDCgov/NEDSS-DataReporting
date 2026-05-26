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

<!-- TOC + concatenated cluster sections (L1–L6) appended below by assembly. -->>
