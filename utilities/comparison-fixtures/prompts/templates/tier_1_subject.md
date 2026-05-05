# Tier 1 — Subject fixture (template)

You are a sub-agent on a multi-agent project that generates synthetic
NBS_ODSE INSERTs for RDB-vs-RDB_MODERN comparison testing. This template
covers Tier 1 subject fixtures. You will receive a per-subject prompt that
fills in the `<<SUBJECT>>` slots below; this file is the shared contract.

Your subject is `<<SUBJECT>>` — one of: organization, patient, place,
investigation, notification, lab_report, morbidity_report, interview,
treatment, vaccination, contact_record. (Provider is already authored.)

## Deliverables

1. `fixtures/10_subjects/<<subject>>.sql` — your additive ODSE INSERTs plus
   synthetic `nrt_<<subject>>` staging row(s).
2. `coverage/coverage_<<subject>>.md` — coverage report per the schema in
   STRATEGY.md.
3. Append your UID allocations to `catalog/uid_ranges.md` under the Tier 1
   section. Do not overwrite existing entries.

## Required reading (in order)

1. `STRATEGY.md` — strategy, baseline, build order, idempotency, failure-mode
   policy, coverage report schema. Pay special attention to the **RTR
   transformation chain** section: the event SP does NOT write `nrt_*`
   staging. You will write `nrt_<<subject>>` rows directly.
2. `catalog/rtr_target_columns.md` — Phase 0. Search for your subject's
   postprocessing SP (`sp_nrt_<<subject>>_postprocessing` or analog) and read
   the per-table breakdown for each table the catalog says it writes.
3. `catalog/edge_types.md` — Phase B. Use only for any
   `entity_locator_participation` rows you author internal to your subject.
   Do **not** author cross-subject edges (act_relationship, participation,
   nbs_act_entity). Those are Tier 2.
4. `catalog/uid_ranges.md` — registry. Take the block listed for your
   subject. If your per-subject prompt assigns a different block than the
   registry suggests, the per-subject prompt wins; update the registry as
   part of your deliverable.
5. `fixtures/00_foundation/00_foundation.sql` — read-only. Your subject
   already has one canonical instance there with a sentinel UID
   (e.g., `@dbo_Entity_provider_uid = 20000010`). Reference it by UID, never
   modify it. Read the DECLAREs at the top to learn the actual sentinel
   names — they may not match prose descriptions in older prompts.
6. `coverage/coverage_foundation.md` — the SRTE codes Tier 0 already chose;
   reuse the same codes when applicable so foundation and your subject
   refer to consistent values.
7. `coverage/coverage_provider.md` — the canary. Reading the "Notes for Tier
   1 template" section there will save you a lot of time. Most surprises
   are absorbed into this template, but the canary's lived examples are
   useful.
8. The two SP files for your subject:
   - `liquibase-service/src/main/resources/db/005-rdb_modern/routines/<event_sp>.sql`
   - `liquibase-service/src/main/resources/db/005-rdb_modern/routines/<postprocessing_sp>.sql`
   File numbers vary by subject — find them via the Phase 0 catalog's SP
   table at the bottom of `rtr_target_columns.md`.

## Connection / sqlcmd usage

Baseline DB runs on `localhost,3433`. The `!` in the password causes zsh
history expansion failures when passed via `-P "..."`. Use `SQLCMDPASSWORD`
inline on every Bash call — DO NOT pass `-P`:

```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_ODSE -Q "..."
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -i /absolute/path/to/file.sql
```

## Method

### Step 1 — Static-extract before running anything

For each table in your subject's postprocessing-SP write set per
`rtr_target_columns.md`:

- **Verify the table exists in the live RDB_MODERN schema** before treating
  it as a coverage target:
  ```sh
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
    -Q "SET NOCOUNT ON; SELECT name FROM sys.tables WHERE name='<TABLE_NAME>'" -h -1
  ```
  If a catalog-named table doesn't exist in the live schema, record it as
  `OUT_OF_SCOPE: <table> does not exist in baseline 6.0.18.1` and skip.
  (The Provider canary found `D_PROVIDER_HIST` like this — phantom in the
  catalog/prompt, missing in the schema.)

- Read the postprocessing SP file end-to-end. Extract the column list it
  writes, the source `nrt_<<subject>>` columns, and any CASE/blank-handling
  transforms that surface different output for different inputs.

- Read the event SP file end-to-end **as a contract test, not as a staging
  populator**. The event SP's role is to emit a JSON projection of ODSE
  rows. You'll run it after authoring your fixture to confirm your ODSE
  rows produce the JSON shape downstream consumers expect — but the event
  SP does not populate `nrt_<<subject>>`. You will.

- Spot-grep the SP body for obvious typos (e.g., the Provider canary found
  `#PATIENT_UPDATE_LIST` referenced inside `sp_nrt_provider_postprocessing`
  where `#PROVIDER_UPDATE_LIST` was meant). Note these but do not "fix"
  the SP — you don't own RTR. Document in coverage.

- Also note any **column-name typos preserved in the schema** (Provider has
  `PROVIDER_REGISRATION_NUM_AUTH` — missing `T`). Match them exactly. Don't
  silently correct.

### Step 2 — Inspect DDL for every table you'll INSERT into

```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_ODSE \
  -Q "SET NOCOUNT ON;
      SELECT column_name, data_type, is_nullable, character_maximum_length
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE table_name='<table>'
      ORDER BY ordinal_position" -h -1
```

For `nrt_<<subject>>` (in RDB_MODERN), additionally identify temporal-table
system-period columns — they are `GENERATED ALWAYS` and explicit INSERTs
into them fail:

```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SET NOCOUNT ON;
      SELECT name, generated_always_type
      FROM sys.columns
      WHERE object_id=OBJECT_ID('dbo.nrt_<<subject>>')
        AND generated_always_type<>0" -h -1
```

OMIT any columns where `generated_always_type IN (1,2)` from your INSERT
column list. (The canary found `nrt_provider.refresh_datetime` and
`max_datetime` are both AS_ROW_START/AS_ROW_END.)

For columns that look split between Person and Person_Name (or analogous
parent / child split tables), ALWAYS verify which table actually has the
column before authoring. The canary tried to set `person.nm_degree` —
that column lives only on `person_name`.

### Step 3 — Verify SRTE codes

For every `*_cd` column you populate, verify the chosen value exists in
baseline SRTE:

```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_SRTE \
  -Q "SET NOCOUNT ON;
      SELECT code, code_set_nm
      FROM dbo.code_value_general
      WHERE code IN ('<code1>','<code2>',...)
      ORDER BY code, code_set_nm" -h -1
```

`code_value_general` is the main code table but **not the only one**. Some
codes (`EL_CLS`, `EL_USE`) are visible there; others may live in
sub-tables. If `code_value_general` returns nothing for a code you expect,
check `nbs_srte.dbo.<code_set_nm>` directly (the table is sometimes named
after the code set) before declaring an SRTE_GAP.

For locator codes specifically, follow the values established by `Phase B`
edge_types.md and the foundation. A common gotcha: foundation locators may
use a `cd` value (e.g., `'PH'`) that the event SP's filter does not match
(`cd='O'`). Read the per-subject prompt's locator-cd citation if provided,
or grep your event SP for its locator filter (`WHERE el.class_cd = ... AND
el.use_cd = ... AND ... cd = ...`). If foundation's locator uses the wrong
`cd`, add an additional `entity_locator_participation` row in your block
that uses the correct one — do not modify foundation.

Cite each SRTE code with a SQL comment above the row, e.g.
`-- code_set_nm=PAR_TYPE, code=SubjOfPHC`.

### Step 4 — Author the fixture file

`fixtures/10_subjects/<<subject>>.sql`:

- `USE [NBS_ODSE]` at the top.
- DECLARE every UID at the top with `DECLARE @<symbolic_name> bigint = <value>;`
  and a comment naming the entity. Use the foundation's naming pattern
  (e.g., `@dbo_Entity_<<subject>>_v2_uid`, `@dbo_Postal_locator_<<subject>>_v2`).
  Allocate contiguously from your block.
- `N'...'` strings, `'2026-04-01T00:00:00'` default datetime.
- Common columns on every ODSE row: `add_time`, `add_user_id=@superuser_id`,
  `last_chg_time`, `last_chg_user_id=@superuser_id`,
  `record_status_cd='ACTIVE'`, `record_status_time`, `status_cd='A'`,
  `status_time`, `version_ctrl_nbr=1`. The `@superuser_id` symbolic name is
  declared in foundation; reuse the same name.
- Author **two variants** of your subject (the Provider canary established
  this pattern):
  - **Foundation row enrichment**: add new child rows
    (`entity_locator_participation`, `entity_id`, `role`, `person_name` etc.)
    that hang off the foundation's existing parent UID. Do not modify the
    foundation row itself.
  - **A v2 variant**: a fully-populated alternative, allocated entirely
    within your UID block. Use this to exercise every column in the
    postprocessing SP's write set.
  - Together, the two variants exercise both the populated path and the
    "blank → NULL" or CASE-branch path for the SP. Document explicitly in
    your coverage report which variant exhibits which path.

#### Authoring `nrt_<<subject>>` rows

After your ODSE rows, INSERT directly into `dbo.nrt_<<subject>>` in
`[RDB_MODERN]`. Switch databases inline:

```sql
USE [RDB_MODERN];

INSERT INTO dbo.nrt_<<subject>> (col1, col2, ...)
VALUES (...), (...);
```

Or use three-part names (`[RDB_MODERN].dbo.nrt_<<subject>>`) and stay in
NBS_ODSE for the file. Either works; pick one.

The `nrt_<<subject>>` row(s) **must** mirror what the upstream
person-service / lab-service / etc. would have produced and the
kafka-connect JDBC sink would have written. To discover the column shape:
- Read the postprocessing SP — every column it reads must be set
  (or deliberately NULL to exercise transforms).
- Read the event SP — every column in its `SELECT` projection has a
  semantic role. The event SP's projection may not perfectly match
  `nrt_<<subject>>` columns (the kafka-connect sink does some renaming);
  treat the postprocessing SP as ground truth when they conflict.
- Inspect `INFORMATION_SCHEMA.COLUMNS` for NOT-NULL columns; satisfy them.
- Skip GENERATED ALWAYS columns (Step 2).

The synthetic-staging approach **deliberately bypasses production CDC**
(Debezium → Kafka → kafka-connect). This is documented in STRATEGY.md and
is intentional: production CDC fidelity is a separate concern, not what
the comparison test verifies. Be aware that if RTR maintainers rename
`nrt_<<subject>>` columns, every Tier 1 fixture breaks at apply time.
Don't add abstraction layers to soften that.

#### Do NOT write `nrt_<<subject>>_key`

The postprocessing SP allocates surrogate keys via IDENTITY in
`nrt_<<subject>>_key`. These are non-deterministic — they shift based on
prior runs and on which subjects ran first. The diff tool consuming this
fixture is responsible for ignoring or remapping surrogate keys. Don't
hand-author them.

#### Forbidden in Tier 1

- Cross-subject `act_relationship`, `participation`, `nbs_act_entity` rows.
  These are Tier 2.
- SRTE writes. If your SP requires a code that's not in baseline SRTE,
  record `SRTE_GAP: <code> needed by <SP> at line <N>` and stop on that
  branch — Tier 2 / Tier 3 / a Tier 0 amendment will revisit.
- Foundation modifications. **No `UPDATE` / `DELETE` against any row in
  `00_foundation.sql`'s output, period** — including columns that
  `coverage_foundation.md` lists under "Columns deliberately skipped" with
  a "Tier 1 will populate" note. That note describes which *variant*
  exercises the populated path (your v2 variant), not which agent gets to
  UPDATE the foundation row. The correct pattern: leave the foundation
  row's column NULL (which exhibits the SP's null/blank path in
  D_<TARGET>) and populate the column on your v2 variant inside your UID
  block (which exhibits the populated path). Together the two variants
  exercise both branches without anyone touching foundation rows.
  *Additive child rows* tied to a foundation UID (e.g., a new
  `entity_locator_participation`, `entity_id`, or `role` row referencing
  `@dbo_Entity_<<subject>>_uid`) are allowed and encouraged — they
  enrich what hangs off the foundation parent without modifying the
  parent itself. If foundation is inadequate at the parent-row level,
  record `FOUNDATION_GAP: <description>` in coverage and stop.
- `IF NOT EXISTS` guards. Fresh baseline, no idempotency.
- **Writing to other subjects' RDB_MODERN output tables.** Do not
  `INSERT INTO dbo.D_PATIENT`, `dbo.INVESTIGATION`, `dbo.D_ORGANIZATION`,
  `dbo.D_PROVIDER`, `dbo.D_PLACE`, `dbo.NOTIFICATION`, `dbo.CONDITION`,
  `dbo.RDB_DATE`, etc. from your fixture. Each of those tables is the
  output of *some* RTR SP chain (its owning Tier 1 subject, or an
  infrastructure SP like `sp_get_date_dim` /
  `sp_nrt_srte_condition_code_postprocessing`). If your subject's
  postprocessing SP joins one of those tables and the join produces
  NULL on a NOT-NULL FK column (a real risk — Notification's SP at
  lines 79–80 does this on INVESTIGATION_KEY and CONDITION_KEY without
  COALESCE), the right responses are:
  1. Document as `LINK_REQUIRED: <table> needed by <SP> at line <N> for
     non-NULL <COLUMN>; resolved in merged-fixture sequence after
     <upstream subject's chain>`.
  2. Accept that Tier 1 isolation will fail or produce reduced coverage.
  3. Do NOT author placeholder rows in the foreign table to "make it
     work" — that creates phantom keys that collide with the canonical
     rows the upstream chain will produce, breaking the merge contract.
  Your fixture's job is to be a clean, self-contained ODSE +
  `nrt_<<subject>>` payload. The merged-fixture sequence (foundation +
  infrastructure SPs + all Tier 1 subjects' fixtures + chains in
  dependency order) is what produces full coverage; isolation is a
  diagnostic mode, not the production target.

### Step 5 — Apply against fresh baseline

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
# Wait for liquibase. Poll, do not sleep:
docker logs nedss-datareporting-liquibase-1 --tail 20
# Look for "Migrations complete" or container Exited (0) with successful tail.
# Liquibase takes ~3-5 minutes.
```

Then:
```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/<<subject>>.sql
```

If apply fails, fix the SQL and reset:
```sh
docker compose down -v && docker compose up -d nbs-mssql liquibase
```
Don't fix-forward with `DELETE` — start clean. Iterate until apply is
clean.

After clean apply, run FK checks for every NBS_ODSE table you wrote to:
```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_ODSE -Q "
  DBCC CHECKCONSTRAINTS ('dbo.<table1>');
  DBCC CHECKCONSTRAINTS ('dbo.<table2>');
  ...
"
```
FK violations are blocking. Fix and reset+re-apply.

### Step 6 — Run the SP chain

```sh
# event SP — pass every subject UID, comma-separated. Treat as a contract
# test: the SP returns a SELECT result set; inspect it visually for shape.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_<<subject>>_event @<<param_name>> = N'20000_,20010_,...'"

# postprocessing SP
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_<<subject>>_postprocessing @id_list = N'20000_,20010_,...', @debug = 0"

# verify COMPLETE in job_flow_log. Order by batch_id and step_number — there
# is NO `job_flow_id` column.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SET NOCOUNT ON;
      SELECT batch_id, step_number, status_type, step_name, row_count
      FROM dbo.job_flow_log
      WHERE dataflow_name LIKE '%<<subject>>%'
      ORDER BY batch_id DESC, step_number"
```

The postprocessing SP's last step should be `step_name='SP_COMPLETE'`,
`status_type='COMPLETE'`. Anything `ERROR` is blocking. If the SP raises
("Missing NRT Record:..." is the canonical signal that your synthetic
`nrt_<<subject>>` is missing or doesn't match the SP's lookup), inspect
the staging row vs the SP's SELECT and fix.

### Step 7 — Coverage check

```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.<<TARGET_TABLE>> WHERE <<UID_COLUMN>> IN (...)" -y 0 -Y 0
```

For each catalog-listed write target, identify which columns are NULL.
Cross-reference against `rtr_target_columns.md`'s entry for that table:

- A NULL column the SP DOES write → likely a coverage gap; trace the SP
  body to find what additional ODSE / staging input would populate it,
  then iterate.
- A NULL column the SP does NOT write per the catalog → not your problem
  for this subject; could be a Datamart / Tier 2 / Tier 3 column.

Stop when every column the postprocessing SP writes is either populated
for at least one variant OR has a documented skip reason.

### Step 8 — Write the coverage report

Use the schema in STRATEGY.md → "Coverage report schema". Make sure to
include:

- The full UID allocation table for your subject (also goes in
  `uid_ranges.md`).
- Every SRTE code referenced, with `code_set_nm` and value chosen.
- Every column the SP writes with its source and which variant exhibits
  the populated value vs the deliberate-NULL.
- Any `OUT_OF_SCOPE` finding (catalog tables that don't exist in the
  baseline; columns the SP doesn't actually populate; columns belonging
  to Datamart / Tier 2 / Tier 3 work).
- Any `SRTE_GAP`, `LINK_REQUIRED`, or `FOUNDATION_GAP` findings.

### Step 9 — Update `uid_ranges.md`

Append a section under "Tier 1 — Subjects" for your subject. Format
matches existing entries. Do not overwrite Tier 0 or other Tier 1
subjects' allocations.

## Stop conditions

Done when ALL of:

- Every column written by your subject's postprocessing SP per
  `rtr_target_columns.md` is populated for at least one variant in your
  fixture OR has a documented skip reason
  (`SRTE_GAP` / `LINK_REQUIRED` / `OUT_OF_SCOPE`).
- The full apply-and-run sequence is clean from a fresh baseline:
  `docker compose down -v && up -d` → foundation.sql → `<<subject>>.sql` →
  `sp_<<subject>>_event` → `sp_nrt_<<subject>>_postprocessing` — all without
  errors and with `job_flow_log` `SP_COMPLETE / COMPLETE`.
- Coverage report exists with the standard schema, including the
  populated-columns table and any gap findings.
- `uid_ranges.md` extended with your subject's allocation.
- You have not modified foundation, SRTE, or any other agent's outputs.

Stop and hand back. Do not start other Tier 1 subjects.

## Final report

When you reply back, include:

- Apply result: clean / iterations needed.
- Final SP exec result: both clean? `job_flow_log` shows COMPLETE?
- Coverage: `<populated>/<total>` columns the postprocessing SP writes,
  per RDB_MODERN target table.
- Iteration count (full baseline-reset cycles).
- Any `OUT_OF_SCOPE`, `SRTE_GAP`, `LINK_REQUIRED`, `FOUNDATION_GAP`
  findings with citations.
- Decisions made under prompt ambiguity (locator-cd choice, variant
  strategy, NULL-vs-populated patterns, anything not obvious from the
  template).
- Confirmation that all three deliverables exist.
