# Tier 1 — Organization

You are a Tier 1 sub-agent. Your subject is **Organization**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

## Subject identity

- **Subject name:** organization
- **Foundation row:** `@dbo_Entity_organization_uid = 20000020`
  (`entity.entity_uid`, `organization.organization_uid`,
  `organization_name.organization_uid`); class `ORG`
- **Foundation locators:**
  - `@dbo_Postal_locator_org = 20000021` — wired (PST, WP, O)
  - `@dbo_Tele_locator_org = 20000022` — wired (TELE, WP, PH)
- **Your UID block:** `20030000–20039999` per `catalog/uid_ranges.md`.
  Update the registry with your final allocation.

## SP chain

- Event SP: `dbo.sp_organization_event @org_id_list nvarchar(max)`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/051-sp_organization_event-001.sql`
  - **Note the parameter name is `@org_id_list`, NOT `@user_id_list` /
    `@id_list`.** Each event SP has its own convention.
- Postprocessing SP: `dbo.sp_nrt_organization_postprocessing @id_list, @debug = 0`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/002-sp_nrt_organization_postprocessing-001.sql`

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md`:

- `dbo.d_organization` — primary write target. ~30+ columns. Verify
  exact column count by reading the catalog and the SP body.
- `dbo.nrt_organization_key` — surrogate-key store; **do not hand-write**
  per the template.
- `dbo.job_flow_log` — logging only.

`dbo.ORGANIZATION_LDF_GROUP` shows up in the catalog but is written by
`sp_nrt_ldf_postprocessing`, not by the organization chain. Out of scope
for this subject.

## Locator-cd filters in the event SP

Foundation's locators line up cleanly for Organization (unlike Provider).
For reference, the event SP filters (cite line numbers in your fixture
comments if you add new locators):

- **Address**: `entity_locator_participation.class_cd='PST' AND use_cd='WP' AND cd='O'`
  (line 98). Foundation's postal locator matches — no extra row needed.
- **Phone**: `class_cd='TELE' AND use_cd='WP' AND cd='PH'` (line 120).
  Foundation's tele locator matches — no extra row needed.
- **Fax**: `class_cd='TELE' AND use_cd='WP' AND cd='FAX'` (line 133).
  Foundation has no fax locator. To exercise `D_ORGANIZATION.ORGANIZATION_FAX`,
  add a fax `tele_locator` + `entity_locator_participation` row in your
  block, attached to either the foundation Org or your v2 Org.

## Variant strategy (apply the template's two-variant pattern)

- **Foundation Org enrichment**: hang additional rows off
  `@dbo_Entity_organization_uid = 20000020`. Candidates:
  - A fax tele_locator + ELP row.
  - An `entity_id` row (e.g., FI / facility identifier — Phase B notes
    that `entity_id` for Org has 1 hard-filtered code, `FI`; check the
    SP body for what NPI-style identifier columns it expects).
  - Additional `organization_name` rows if the SP exercises name-priority
    logic.
  - A `role` row if the SP expects Org-as-Hospital / Org-as-Clinic role
    relationships internal to the Org itself.
  Leave some columns deliberately NULL on the foundation Org to exercise
  the SP's `blank → NULL` transform path (the postprocessing SP for
  Organization has `guarded=yes` on essentially every column per the
  catalog — that's CASE-when-empty handling).
- **v2 Org**: a separate fully-attributed Organization in your block,
  every D_ORGANIZATION column non-NULL. Allocate sequentially from
  20030000.

## Forbidden (inherited from template, repeated for clarity)

- No cross-subject `act_relationship`, `participation`, or `nbs_act_entity`
  rows — those are Tier 2 (Org-as-ReportingSource-of-Investigation, etc.).
- No SRTE writes.
- No foundation modifications.
- Do not write `nrt_organization_key`.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
# poll for liquibase: docker logs nedss-datareporting-liquibase-1 --tail 20

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/organization.sql

# event SP — note the @org_id_list param name (not @user_id_list)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_organization_event @org_id_list = N'20000020,20030010'"

# postprocessing SP
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_organization_postprocessing @id_list = N'20000020,20030010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.D_ORGANIZATION WHERE ORGANIZATION_UID IN (20000020, 20030010)" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape.
