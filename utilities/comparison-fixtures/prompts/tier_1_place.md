# Tier 1 — Place

You are a Tier 1 sub-agent. Your subject is **Place**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

## Subject identity

- **Subject name:** place
- **Foundation row:** `@dbo_Entity_place_uid = 20000030`
  (`entity.entity_uid`, `place.place_uid`); class `PLC`
- **Foundation locators:**
  - `@dbo_Postal_locator_place = 20000031` — wired (PST, H, H)
  - **No tele locator on foundation Place.** Tier 1 needs to add one
    to exercise PLACE_TELEPHONE columns (see locator filters below).
- **Your UID block:** `20040000–20049999` per `catalog/uid_ranges.md`.
  Update the registry with your final allocation.

## SP chain

- Event SP: `dbo.sp_place_event @id_list nvarchar(max)`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/068-sp_place_event-001.sql`
  - Param name is `@id_list` (NOT `@user_id_list`, NOT `@org_id_list`,
    NOT `@phc_id_list`). Each event SP varies — match the literal.
- Postprocessing SP: `dbo.sp_nrt_place_postprocessing @id_list, @debug = 0`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/028-sp_nrt_place_postprocessing-001.sql`
- **NOT in scope:** `sp_repeated_place_postprocessing`
  (file 035) — that SP takes `@phc_id_list` (Public Health Case UIDs)
  and writes to `D_INV_PLACE_REPEAT` / `L_INV_PLACE_REPEAT`. It requires
  Investigation rows + cross-subject `act_relationship` /
  `participation` rows wiring PHC → places. **That is Tier 2 / Tier 3
  territory.** Do NOT invoke it. If your Place fixture includes places
  that *would* be linked to investigations, document the expected Tier
  2 wiring as a `LINK_REQUIRED` note in coverage.

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md` and live schema:

- `dbo.D_PLACE` — primary write target. Catalog says ~38 columns; live
  schema has 37. **Verify the live count first** and report
  `<populated>/<live_count>` — Patient revealed the catalog can drift
  from live schema by 1–8 columns.
- `dbo.nrt_place` — synthetic staging row(s) you write directly. Mirror
  what kafka-connect would produce.
- `dbo.nrt_place_tele` — **separate tele staging table** that the
  postprocessing SP LEFT JOINs at line 103. Tier 1 must populate this
  too if PLACE_TELEPHONE / PLACE_FAX columns are to be non-NULL on
  D_PLACE. The Org/Provider chains had a single `nrt_*` staging table;
  Place is the first subject to require a *second* staging table.
  Inspect its DDL and column shape before authoring.
- `dbo.nrt_place_key` — surrogate-key store; **do not hand-write** per
  the template.
- `dbo.job_flow_log` — logging only.

`dbo.D_INV_PLACE_REPEAT` / `L_INV_PLACE_REPEAT` are written by
`sp_repeated_place_postprocessing` (out of scope, see above).

## Locator-cd filters in the event SP

- **Address (postal)**: foundation already has `(PST, H, H)` on the
  Place. Read `068-sp_place_event-001.sql` to confirm whether it
  filters on `use_cd`/`cd` or just `class_cd='PST'`. Either way the
  foundation locator should match.
- **Tele**: `class_cd='TELE'` (line 121 of the event SP). Foundation
  has no tele locator on Place. Add at least one tele locator + ELP
  row in your block to exercise PLACE_TELEPHONE coverage.
  Optionally a fax (`cd='FAX'`) or email (`cd='NET'`) locator if the
  postprocessing SP exposes those columns separately.

## Variant strategy (apply the template's two-variant pattern)

- **Foundation Place enrichment**: hang additional rows off
  `@dbo_Entity_place_uid = 20000030`. At minimum add a tele locator +
  ELP row. Optionally add a fax or email tele locator. Leave deliberate
  NULLs on the foundation Place to exercise the SP's null/blank path.
- **v2 Place**: a separate fully-attributed Place in your block. Every
  D_PLACE column non-NULL. Allocate sequentially from 20040010.

The Place subject has fewer code-set / CASE branches than Patient, so
two variants should suffice. If you find a CASE branch that needs a
specific class_cd or place type to fire, consider a v3 — but only on
demonstrated need.

## Place-specific code: `place.cd`

The foundation Place has `place.cd` set to NULL per
`coverage_foundation.md` ("place: cd, cd_desc_txt left NULL — Tier 1
place agent picks place type"). Per the v2-variant pattern (corrected
contract), set `place.cd` ONLY on the v2 Place — don't UPDATE the
foundation row. Verify the SRTE codeset for place type:

```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_SRTE \
  -Q "SET NOCOUNT ON; SELECT TOP 20 code, code_short_desc_txt
      FROM dbo.code_value_general
      WHERE code_set_nm IN ('PLACE_TYPE', 'P_TYPE', 'PLC_TYPE')
      ORDER BY code_set_nm, code"
```

Pick a code that exists. Cite `code_set_nm` and value in a SQL comment.

## Forbidden (inherited from template, repeated for clarity)

- No cross-subject `act_relationship`, `participation`, or
  `nbs_act_entity` rows.
- No SRTE writes.
- **No UPDATE/DELETE against any foundation row** (including
  `place.cd`, even though `coverage_foundation.md` flags it as
  "Tier 1 will populate"). Use the v2 variant pattern: foundation
  exhibits the null path; v2 exhibits the populated path.
- Do not write `nrt_place_key`.
- Do NOT invoke `sp_repeated_place_postprocessing` (Tier 2/3 only).

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/place.sql

# event SP — @id_list (NOT @user_id_list / @org_id_list)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_place_event @id_list = N'20000030,20040010'"

# postprocessing SP
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_place_postprocessing @id_list = N'20000030,20040010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.D_PLACE WHERE PLACE_UID IN (20000030, 20040010)" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape. Report
`<populated>/<live_D_PLACE_count>` (live schema, not catalog).
