# Tier 1 — Contact Record

You are a Tier 1 sub-agent. Your subject is **Contact Record**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

Contact has the **largest dimension** of any Tier 1 subject:
**D_CONTACT_RECORD has 66 live columns** (vs catalog's 45 — large
drift; many LDF/dynamic columns added since Phase 0 was generated).
F_CONTACT_RECORD_CASE has 11 cols. No FK constraints on either; all
KEY columns NULLABLE. Should run cleanly in isolation.

This is the **last Tier 1 subject** — once it's complete, the project
moves to Tier 2 (cross-subject links).

## Subject identity

- **Subject name:** contact (a.k.a. contact_record, ct_contact)
- **Foundation row:** `@dbo_Act_contact_uid = 20000170`
  (`act.act_uid`, `ct_contact.ct_contact_uid`); class `ENC`,
  mood `EVN`. Foundation has internal-linkage rows pointing all
  three NOT-NULL FKs at the foundation Patient + Investigation
  (per Tier 0's documented decision — `subject_entity_uid`,
  `contact_entity_uid`, `subject_entity_phc_uid`).
- **Foundation Patient/Investigation:** referenced by foundation
  ct_contact's NOT-NULL columns.
- **No internal locators.** Contact is an Act, not an Entity.
- **Your UID block:** `20120000–20129999` per `catalog/uid_ranges.md`.

## SP chain

- Event SP: `dbo.sp_contact_record_event @cc_uids nvarchar(max), @debug = 0`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/069-sp_contact_record_event-001.sql`
  - **Param `@cc_uids`** (cc = contact records).
- Postprocessing SPs (2 — both use `@contact_uids`):
  1. `dbo.sp_d_contact_record_postprocessing @contact_uids, @debug = 0`
     - File: `routines/036-sp_d_contact_record_postprocessing-001.sql`
     - Writes `D_CONTACT_RECORD` (66 cols).
  2. `dbo.sp_f_contact_record_case_postprocessing @contact_uids, @debug = 0`
     - File: `routines/038-sp_f_contact_record_case_postprocessing-001.sql`
     - Writes `F_CONTACT_RECORD_CASE` (11 cols).
- **NOT in scope:**
  - `sp_covid_contact_datamart_postprocessing` (315) — datamart,
    Tier 2/3.
  - `sp_public_health_case_fact_datamart_event` (072) and `_update`
    (073) — datamart-side fact assembly that uses Contact data after
    Tier 2 wires participation rows.

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md` and live schema:

- `dbo.D_CONTACT_RECORD` — primary write target. **Live: 66 / catalog: 45**
  (large drift — verify which 21+ extra columns exist live and whether
  they're LDF/dynamic-pivot or static). Read the catalog's per-table
  breakdown for the 45 documented columns; for the live-only columns,
  check whether the postprocessing SP populates them or if they're
  out-of-scope LDF columns gated by `nrt_metadata_columns` (like
  Interview's 6 LDF columns).
- `dbo.F_CONTACT_RECORD_CASE` — fact table. **Live: 11 / catalog: 12.**
  All 11 KEY columns NULLABLE — no INSERT failures on missing FKs.
- `dbo.nrt_contact` — synthetic staging. 56 cols (large).
- `dbo.nrt_contact_answer` — answer staging. 5 cols.
- `dbo.nrt_contact_key` — surrogate-key store; **do not hand-write**.

## Foundation's NOT-NULL FKs (from Tier 0 decision)

The foundation ct_contact row has three hard NOT-NULL FKs already
satisfied per Tier 0's "Decisions made" note:
- `subject_entity_uid` → foundation Patient (20000000)
- `contact_entity_uid` → foundation Patient (20000000)
- `subject_entity_phc_uid` → foundation Investigation (20000100)

Tier 1 inherits this — your fixture doesn't need to author additional
ct_contact rows just to satisfy those FKs. Your v2 contact can point
its FKs at the same foundation Patient + Investigation, OR you can
author additional rows in your block to vary contact endpoints.

## Variant strategy (apply the template's two-variant pattern)

- **Foundation Contact enrichment**: hang additive child rows off
  `@dbo_Act_contact_uid = 20000170`. The ct_contact row exists; you'll
  need:
  - The matching `nrt_contact` staging row (driver of the chain)
  - Optionally `nrt_contact_answer` rows for additional fields
  - Leave most ct_contact-detail columns NULL on foundation
- **v2 Contact**: a separate fully-attributed Contact in your block
  (e.g., UID 20120010 for the Act + ct_contact). The 66-col
  D_CONTACT_RECORD has many domain-specific fields (contact health
  status, exposure indicators, treatment indicators, etc.) — populate
  generously.

If specific CASE branches in the SP warrant a v3, add it. Otherwise
2 variants is sufficient.

## Forbidden (inherited from template, repeated for clarity)

- **No cross-subject `act_relationship`, `participation`, or
  `nbs_act_entity` rows.**
- No SRTE writes.
- **No UPDATE/DELETE against any foundation row.**
- **No INSERTs into other subjects' RDB_MODERN output tables.**
- Do not write `nrt_contact_key`.
- Do not invoke COVID datamart or PHC fact datamart SPs.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/contact.sql

# event SP — @cc_uids
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_contact_record_event @cc_uids = N'20000170,20120010', @debug = 0"

# d_ postprocessing — @contact_uids
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_d_contact_record_postprocessing @contact_uids = N'20000170,20120010', @debug = 0"

# f_ postprocessing — @contact_uids
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_f_contact_record_case_postprocessing @contact_uids = N'20000170,20120010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT COUNT(*) FROM dbo.D_CONTACT_RECORD WHERE CT_CONTACT_UID IN (20000170, 20120010)" -y 0 -Y 0
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT COUNT(*) FROM dbo.F_CONTACT_RECORD_CASE" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape. Report
`<populated>/<live_count>` for D_CONTACT_RECORD (target 66) and
F_CONTACT_RECORD_CASE (target 11). For the 21+ live-only columns
not in the catalog, distinguish populated vs OUT_OF_SCOPE.
