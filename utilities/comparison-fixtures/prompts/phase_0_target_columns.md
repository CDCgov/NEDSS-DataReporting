# Phase 0 — RTR target-column map

You are a sub-agent on a multi-agent project. Your single deliverable is
`catalog/rtr_target_columns.md`.

## Context

Read `NEDSS-DataReporting/utilities/comparison-fixtures/STRATEGY.md` first. It
defines the larger project: producing synthetic NBS_ODSE INSERTs that exercise
every RDB_MODERN table/column RTR can populate, for use in a future
RDB-vs-RDB_MODERN comparison test against MasterETL.

Your job is the *static analysis* that defines RTR's coverage scope. Every
later agent measures itself against your output.

## Inputs

- All RTR routines in
  `NEDSS-DataReporting/liquibase-service/src/main/resources/db/005-rdb_modern/routines/`
  (~130 SPs). The SP body is the spec — every `INSERT`, `UPDATE`, `MERGE`
  target tells you a (table, column) RTR can write.
- All RDB_MODERN table DDL in
  `NEDSS-DataReporting/liquibase-service/src/main/resources/db/005-rdb_modern/tables/`.
- All RTR view DDL in `.../db/005-rdb_modern/views/` (some "tables" are views;
  ignore those for fixture targeting but note them).
- Optional: live baseline DB for cross-checking, started per
  STRATEGY.md → "Connection details". You may use `sqlcmd` to query
  `INFORMATION_SCHEMA.COLUMNS` and friends.

## Method

For each routine file:

1. Identify the SP name and whether it is an `_event` SP, an
   `_nrt_*_postprocessing` SP, a datamart SP, a `dyn_dm_*` SP, or a utility
   SP. Datamart SPs and event SPs have different positions in the chain — note
   it.
2. Extract every `INSERT INTO <table>` statement's target table and column
   list. Be liberal with dynamic SQL — if the SP builds an `INSERT` via
   `@sql + ...`, capture the table name and note `dynamic_columns: true`.
3. Extract every `UPDATE <table> SET col = ...` and the columns set.
4. Extract every `MERGE INTO <table>` and the columns the WHEN MATCHED /
   WHEN NOT MATCHED branches set.
5. For each (table, column) record:
   - Which SP(s) write it.
   - Whether the write is unconditional or guarded (CASE / WHERE / IF). Don't
     parse the predicate — just flag `guarded: true|false`.
   - Whether the write is dynamic-SQL'd (datamart-style) — flag
     `dynamic: true|false`.

For temp tables (`#temp`, `@table_var`, `tmp_*`, `nrt_*` staging populated by
event SPs as a side-effect): these are intermediate, not a coverage target.
List them separately under "Intermediate / staging targets" so we can refer
back later, but they're not part of the comparison scope.

For tables defined as views in `views/`: list under "Views (excluded from
fixture scope)".

## Output: `catalog/rtr_target_columns.md`

```markdown
# RTR Target Columns

Generated: <YYYY-MM-DD>
Source: NEDSS-DataReporting/liquibase-service/.../005-rdb_modern/routines/

## Summary
- SPs analyzed: N
- Distinct target tables: N
- Distinct (table, column) pairs: N
- Guarded writes: N
- Dynamic-SQL writes: N

## Per-table breakdown

### dbo.D_PATIENT
Writers:
- sp_nrt_patient_postprocessing (postprocessing) — primary
- sp_patient_event (event) — n/a (writes nrt staging only)

| Column | Writer SP(s) | Guarded | Dynamic | Notes |
| ---    | ---          | ---     | ---     | ---   |
| patient_uid | sp_nrt_patient_postprocessing | no | no | PK |
| patient_first_name | sp_nrt_patient_postprocessing | no | no | |
| patient_deceased_indicator | sp_nrt_patient_postprocessing | yes | no | CASE on deceased_ind_cd |
| ... | | | | |

### dbo.D_INVESTIGATION
...

## Intermediate / staging targets (not in scope)
- dbo.nrt_patient — written by sp_patient_event, read by sp_nrt_patient_postprocessing
- dbo.nrt_provider
- ...

## Views (excluded from fixture scope)
- dbo.v_<view> (defined in views/<file>)

## SP catalog

| SP | File | Type | Reads from | Writes to (top-level) |
| -- | --   | ---  | ---        | ---                   |
| sp_provider_event | 052-sp_provider_event-001.sql | event | dbo.person, dbo.entity, ... | nrt_provider |
| sp_nrt_provider_postprocessing | 003-sp_nrt_provider_postprocessing-001.sql | postprocessing | nrt_provider | D_PROVIDER, ... |
| ... |
```

## Constraints

- Do **not** write fixtures, INSERT statements, or strategy notes — those are
  later phases. This deliverable is reference data only.
- Do **not** speculate about coverability ("this column requires condition_cd
  = X"). That belongs in Tier 1 coverage reports. You are extracting *what*
  RTR writes, not *how* to make it write.
- Distinguish event SPs from postprocessing SPs from datamart SPs from
  utility SPs explicitly. The Tier 1 verification recipe depends on it.
- If a routine file is a `DROP PROCEDURE` only, skip it.
- For `MERGE` statements, both INSERT and UPDATE column sets count.

## Sanity checks before declaring done

- Spot-check `sp_nrt_patient_postprocessing` — its target should include
  `dbo.D_PATIENT` and likely `dbo.nrt_patient_key`. If your output disagrees,
  re-read.
- Spot-check `sp_hepatitis_datamart_postprocessing` — target tables are
  dynamic; flag them as such.
- Total distinct target tables should be in the dozens, not single digits and
  not hundreds. If far off, re-think.

Write the file, run the sanity checks, and stop. Do not proceed to Phase B.
