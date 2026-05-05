# Tier 1 — Provider (canary run)

You are a sub-agent on a multi-agent project. Your single deliverable is
`fixtures/10_subjects/provider.sql` plus the coverage report
`coverage/coverage_provider.md`.

This is the **first Tier 1 agent run**. Treat it as a contract test: the
purpose is not just to produce the Provider fixture but to exercise the
end-to-end Tier 1 contract so the human can identify what the eventual
Tier 1 template should and shouldn't say. Be explicit in your coverage
report about anything that surprised you, was missing from the prompt, or
required guesswork — those are the gaps the template must close.

## Context

Read in this order:
1. `STRATEGY.md`
2. `catalog/rtr_target_columns.md` (Phase 0 output)
3. `catalog/edge_types.md` (Phase B output)
4. `fixtures/00_foundation/00_foundation.sql` (Tier 0 output) — this is your
   **read-only foundation**. The Provider it defines (`@dbo_Provider_entity_uid`
   = 20000010 per Tier 0 allocation) is your subject-under-test.
5. `coverage/coverage_foundation.md` — for SRTE codes already chosen.

## Your subject

The Provider canonical subject. Foundation already created one Provider
(Entity + Person with `cd='PRV'`, locators, role row). Your job is to:

1. **Identify the SP chain.** From `catalog/rtr_target_columns.md`, locate
   `sp_provider_event` (event SP) and `sp_nrt_provider_postprocessing`
   (postprocessing SP). Read both files end-to-end. Specifically:
   - `liquibase-service/.../routines/052-sp_provider_event-001.sql`
   - `liquibase-service/.../routines/003-sp_nrt_provider_postprocessing-001.sql`
2. **Run the chain against foundation alone.**
   ```sh
   docker compose down -v && docker compose up -d nbs-mssql liquibase
   # wait
   sqlcmd ... -i fixtures/00_foundation/00_foundation.sql
   sqlcmd ... -d RDB_MODERN -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010'"
   sqlcmd ... -d RDB_MODERN -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010', @debug = 0"
   ```
   Then SELECT every column of `dbo.D_PROVIDER WHERE provider_uid = 20000010`.
   Note which columns are NULL.
3. **Identify the gap.** For each NULL column that
   `catalog/rtr_target_columns.md` says `sp_nrt_provider_postprocessing`
   writes, trace the SP body to find what ODSE input would cause it to be
   non-null. The columns may need: a Person field set differently
   (race/ethnicity/qualification/etc.), additional locators (e.g., a TELE
   locator for `phone_work`), an `entity_id` row (for NPI-like identifiers),
   or a `role` row connecting Provider to Organization.
4. **Author additive ODSE INSERTs.** Anything new goes in
   `fixtures/10_subjects/provider.sql`, allocating UIDs from the Provider
   block (see UID range below). Never modify foundation rows. If your subject
   needs a *different* Provider (e.g., a deceased provider for a CASE branch),
   create it as a new entity in your block.
5. **Re-run the chain** against foundation + provider.sql. Iterate until you
   have hit every reachable column in `D_PROVIDER`, `D_PROVIDER_HIST`, and any
   other RTR-write target the catalog associates with the Provider SP chain.

## UID range

Provider Tier 1 owns: `20010000–20019999`.

Allocate sentinels at the top of `provider.sql` with comments. Examples:

```
DECLARE @dbo_Provider_v2_entity_uid    bigint = 20010000;  -- second provider variant
DECLARE @dbo_Provider_v2_postal_locator bigint = 20010001;
DECLARE @dbo_Provider_npi_entity_id_seq smallint = 1;       -- not a UID, scoped to entity
```

## Authoring constraints

(Inherit from STRATEGY.md and Tier 0; reproduced here for clarity.)

- `USE [NBS_ODSE]` at the top.
- `N'...'` strings, `'2026-04-01T00:00:00'` default datetime.
- Every code you write must exist in baseline SRTE — verify with `sqlcmd`,
  cite the `code_set_nm` and value in a comment.
- No `IF NOT EXISTS`. No idempotency.
- No SRTE writes. No foundation modifications.
- No cross-subject act_relationship / participation / nbs_act_entity rows —
  if you find columns that require them, record `LINK_REQUIRED` in coverage
  and skip.

## Verification recipe (run repeatedly while iterating)

```sh
docker compose down -v && docker compose up -d nbs-mssql liquibase
# wait for liquibase
sqlcmd -S localhost,3433 -U sa -P 'PizzaIsGood33!' -C -i fixtures/00_foundation/00_foundation.sql
sqlcmd -S localhost,3433 -U sa -P 'PizzaIsGood33!' -C -i fixtures/10_subjects/provider.sql

# event SP — provide every provider UID you've created, comma-separated
sqlcmd -S localhost,3433 -U sa -P 'PizzaIsGood33!' -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010000'"

# postprocessing SP
sqlcmd -S localhost,3433 -U sa -P 'PizzaIsGood33!' -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010000', @debug = 0"

# coverage check
sqlcmd -S localhost,3433 -U sa -P 'PizzaIsGood33!' -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.D_PROVIDER WHERE PROVIDER_UID IN (20000010, 20010000)"
```

Both `EXEC`s must return without error and `job_flow_log` must record
`Status_Type='COMPLETE'` for the postprocessing SP. Any column that is NULL
in `D_PROVIDER` *and* listed as written by the SP in
`catalog/rtr_target_columns.md` *and* not deliberately skipped is a gap.

## Output: `coverage/coverage_provider.md`

Use the schema in STRATEGY.md → "Coverage report schema". Additionally,
because this is the canary, include a final section:

```markdown
## Notes for Tier 1 template

Things that surprised me / required guesswork / aren't obvious from the
prompt and should be in the template:
- ...

Things the prompt got right and should keep:
- ...

Open questions for the human reviewer:
- ...
```

Be honest and specific here. The template will be derived from this section.

## Stop conditions

Done when:
- Every column written by `sp_nrt_provider_postprocessing` per
  `catalog/rtr_target_columns.md` is either populated for at least one
  Provider in your fixture or has a documented reason for being skipped
  (`SRTE_GAP`, `LINK_REQUIRED`, `OUT_OF_SCOPE`).
- Both SPs run cleanly against foundation + provider.sql on a fresh baseline.
- The coverage report is written, including the "Notes for Tier 1 template"
  section.
- You have not modified foundation, SRTE, or any other agent's outputs.

Stop and hand back. Do not proceed to other Tier 1 subjects.
