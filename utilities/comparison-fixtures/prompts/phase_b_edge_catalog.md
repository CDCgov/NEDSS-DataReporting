# Phase B — Edge-type catalog

You are a sub-agent on a multi-agent project. Your single deliverable is
`catalog/edge_types.md`.

## Context

Read `STRATEGY.md` first. Background: ODSE is heavily relational, and most of
the bad fixtures we expect to see will fail not because of missing columns
but because of invalid or hallucinated edge `type_cd`s on the connective
tables. Your output is the catalog every Tier 2 (link) agent picks edge codes
from, so that every cross-subject relationship in the final fixture is a
shape RTR's SPs can actually read.

## Inputs

You have shell access. Bring up the baseline per STRATEGY.md → "Connection
details" if it isn't already running. Confirm with:

```sh
sqlcmd -S localhost,3433 -U sa -P 'PizzaIsGood33!' -C -Q "SELECT name FROM sys.databases ORDER BY name"
```

You should see at least `NBS_ODSE`, `NBS_SRTE`, `RDB_MODERN`. If liquibase
hasn't completed yet, wait — RDB_MODERN's RTR objects must exist for the
catalog to be useful.

Schema sources:

- ODSE table DDL: 6.0.18.1 migrations under
  `NEDSSDB/src/migrations/6.0.18.1/NBS_ODSE/`. Earlier versions also.
- Live SRTE: `NBS_SRTE.dbo.*` — code_set, code_value_general, condition_code,
  etc.
- Connective table column lists: query
  `INFORMATION_SCHEMA.COLUMNS` against NBS_ODSE for the tables below.
- ODSE views in `liquibase-service/src/main/resources/db/003-odse/views/` if
  you need to disambiguate shape.

## Connective tables in scope

Author one section per table. For each table, document the discriminator
columns (the `*_cd` columns whose values constrain valid endpoints) and the
catalog of legal values:

1. `dbo.act_relationship` — discriminators: `type_cd`, `source_class_cd`,
   `target_class_cd`. (Source and target are both Acts.)
2. `dbo.participation` — discriminators: `type_cd`, `act_class_cd`,
   `subject_class_cd`. Links Acts to Entities.
3. `dbo.nbs_act_entity` — discriminators: `type_cd`, source/target classes.
4. `dbo.entity_locator_participation` — discriminators: `class_cd`,
   `use_cd`, `type_cd`. Links Entities to Locators (Postal/Tele/Physical).
5. `dbo.role` — discriminators: `role_cd`, `subject_class_cd`,
   `scoping_class_cd`. (Person-as-Provider, Person-as-Patient,
   Organization-as-Hospital, etc.)
6. `dbo.act_id` — discriminators: `type_cd` and `assigning_authority_*`.
7. `dbo.entity_id` — discriminators: `type_cd`, `assigning_authority_*`,
   `class_cd`.

## Method per table

For each table:

1. **Find the legal codes.** Query SRTE — the conventional location is
   `NBS_SRTE.dbo.code_value_general` filtered by `code_set_nm`. Common code
   sets:
   - `ACT_REL_TYPE` for `act_relationship.type_cd`
   - `PART_TYPE` for `participation.type_cd`
   - `ROLE_CD` for `role.role_cd`
   - `ELP_TYPE`, `ELP_USE`, `ELP_CLASS` for entity_locator_participation
   - etc. — confirm the actual `code_set_nm` values present in this baseline:
     `SELECT DISTINCT code_set_nm FROM NBS_SRTE.dbo.code_value_general ORDER BY 1`
2. **Find which codes are actually used by RTR SPs.** Grep the RTR routines
   for the `type_cd`/`class_cd`/`role_cd` literal values. A code that exists
   in SRTE but no RTR SP filters on is uninteresting (we won't differentiate
   coverage by including it). A code that an RTR SP filters on is
   load-bearing — those are the priority.
3. **Map endpoint constraints.** For each load-bearing code, identify the
   legal source/target class_cds. Sometimes encoded in SRTE
   (`code_value_general.value_1` / `value_2` etc., implementation-specific —
   inspect to confirm), sometimes encoded only in SP `WHERE` clauses. Cite
   the source.

## Output: `catalog/edge_types.md`

```markdown
# Edge-type catalog

Generated: <YYYY-MM-DD>
Baseline: 6.0.18.1 (post-liquibase)

## How to use

When a Tier 2 (link) agent needs to author a row in one of these tables, it
**must** pick a `type_cd` (or analogous discriminator) listed here. The legal
endpoint shapes are stated alongside. Codes not in this catalog were not
found in baseline SRTE or are not used by any RTR SP — using them is a bug.

## dbo.act_relationship

Discriminators: `type_cd`, `source_class_cd`, `target_class_cd`.

| type_cd | Source class_cd | Target class_cd | Used by SP(s) | SRTE source |
| ---     | ---             | ---             | ---           | ---         |
| InvestigationHasNotification | NOT (Notification Act) | CASE (PHC Act) | sp_nrt_notification_postprocessing | code_value_general.code_set_nm='ACT_REL_TYPE' |
| LabReportToInvestigation | OBS (Lab Act) | CASE (PHC Act) | sp_observation_event, sp_d_lab_test_postprocessing | ... |
| ... |

(One row per load-bearing code. Add a paragraph beneath the table for any
codes whose endpoint constraints are non-obvious.)

## dbo.participation
...

## dbo.entity_locator_participation
...

## dbo.role
...

## dbo.act_id
...

## dbo.entity_id
...

## Codes seen in SRTE but not used by RTR SPs

(For completeness — Tier 2 agents skip these unless explicitly authorized.)

| Table | type_cd | code_set_nm | Reason for inclusion |
| ---   | ---     | ---         | ---                  |
```

## Constraints

- **Ground in live baseline SRTE.** Do not list a `type_cd` that does not
  exist in `code_value_general` (or its analog). If you find an RTR SP
  filtering on a code that is *not* in baseline SRTE, that's a finding —
  flag it as `MISSING_FROM_SRTE` at the bottom of the file. Don't omit it
  silently.
- **Ground endpoint constraints in the SP body.** Cite file:line for any
  endpoint constraint sourced from SP code rather than SRTE.
- **Don't enumerate every code in SRTE** — only the load-bearing ones plus
  the small "not used by RTR" appendix. If a discriminator has 200 values in
  SRTE and RTR uses 8, list the 8.
- **No fixtures, no INSERT statements, no agent prompts.** Reference data
  only.

## Sanity checks before declaring done

- `act_relationship` should have ≥ 6 load-bearing codes (Investigation has
  Notification, Lab to Investigation, Morbidity to Investigation, Treatment to
  Investigation, Vaccination to Investigation, Investigation to Contact).
  If your output has fewer, you're missing some — re-grep RTR routines for
  string literals.
- `participation.type_cd` should include `SubjOfPHC`, `PerAsRptOfPHC` (or
  similar reporter codes), `ProviderAsAuthor`, etc.
- `entity_locator_participation.class_cd` legal values should be exactly the
  three locator types: PST (postal), TELE (tele), PHYS (physical) — confirm.

Write the file, run sanity checks, stop.
