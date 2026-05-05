# Tier 0 — Foundation fixture

You are a sub-agent on a multi-agent project. Your single deliverable is
`fixtures/00_foundation/00_foundation.sql` plus the matching coverage report
`coverage/coverage_foundation.md`.

## Context

Read `STRATEGY.md` first. Read `catalog/rtr_target_columns.md` and
`catalog/edge_types.md` (Phases 0 and B must be complete). Briefly skim
`reporting-pipeline-service/src/test/resources/testData/unit/patientEvent/setup.sql`
and `.../organizationEvent/setup.sql` — they're the closest existing examples
of the dialect you'll be writing in.

## Your scope

Foundation is the floor every downstream agent builds on. It contains:

1. **Sentinel UID DECLAREs** at the top, named after the ODSE table they
   identify: `@dbo_Entity_patient_uid`, `@dbo_Act_investigation_uid`, etc.
   These names become the public contract Tier 1+ agents reference (by reading
   this file or the UID range registry).
2. **One canonical instance** of each parent entity. Concretely:
   - 1 Patient (Entity + Person, with `cd='PAT'`).
   - 1 Provider (Entity + Person, with `cd='PRV'`).
   - 1 Organization (Entity + Organization).
   - 1 Place (Entity + Place).
   - 1 Investigation (Act + Public_health_case, `class_cd='CASE'`,
     `mood_cd='EVN'`).
   - 1 Notification (Act + Notification).
   - 1 Lab Report (Act + Observation, `class_cd='OBS'`, `mood_cd='EVN'`).
   - 1 Morbidity Report (Act + Observation).
   - 1 Interview (Act + Interview).
   - 1 Treatment (Act + Treatment).
   - 1 Vaccination (Act + Intervention).
   - 1 Contact Record (Act + Contact_record or analog).
3. **Internal locators** for parent entities that need them (Patient address,
   Provider phone, Organization address, Place address). Use Postal_locator
   and Tele_locator as appropriate. Wire them via
   entity_locator_participation, picking class_cd / use_cd from
   `catalog/edge_types.md`.
4. **No cross-subject edges.** A Lab Report sits as a free-floating Act in
   foundation — Tier 2 will link it to the Investigation. Same for
   Notification, Morbidity Report, Treatment, Vaccination, Contact, Interview.
5. **No SRTE writes.** SRTE is provided by the baseline. If a Tier 1 agent
   later reports `SRTE_GAP`, we revisit Tier 0 — but never seed SRTE here as
   a workaround.

## UID range

Tier 0 owns `20000000–20009999`. Suggested allocation (keep contiguous, easy
to read):

```
20000000  Patient.entity_uid (also person_uid, person_parent_uid)
20000001  Patient postal_locator_uid
20000002  Patient tele_locator_uid
20000010  Provider.entity_uid
20000011  Provider postal_locator_uid
20000012  Provider tele_locator_uid
20000020  Organization.entity_uid
20000021  Organization postal_locator_uid
20000030  Place.entity_uid
20000031  Place postal_locator_uid
20000100  Investigation.act_uid
20000110  Notification.act_uid
20000120  Lab Report.act_uid
20000130  Morbidity Report.act_uid
20000140  Interview.act_uid
20000150  Treatment.act_uid
20000160  Vaccination.act_uid
20000170  Contact Record.act_uid
```

Sentinel reference (do not allocate): `@superuser_id bigint = 10009282`. (Verify
with `SELECT user_id FROM NBS_ODSE.dbo.auth_user WHERE user_id = 10009282`.)

## Authoring constraints

- Single `.sql` file. Begin with `USE [NBS_ODSE]`.
- Declare every UID at the top with a `DECLARE @<name> bigint = <value>;` line
  and a comment naming the entity it identifies.
- Use `N'...'` for string literals (matches existing fixture dialect).
- For NOT NULL columns: every row must satisfy them. If you can't satisfy a
  NOT NULL without inventing data, ask whether the table really belongs in
  foundation — it may belong in Tier 1.
- For columns with FK or soft-FK to SRTE codes (`*_cd` columns referencing
  code_value_general), pick a code that actually exists in baseline SRTE.
  Verify with `sqlcmd`. Cite the chosen code in a SQL comment above the row.
- Common columns to populate on every row: `add_time`, `add_user_id`,
  `last_chg_time`, `last_chg_user_id`, `record_status_cd='ACTIVE'`,
  `record_status_time`, `status_cd='A'`, `status_time`, `version_ctrl_nbr=1`.
  Use `'2026-04-01T00:00:00'` for date/time literals throughout the fixture
  unless a specific column needs a different value.
- Populate `local_id` columns where they exist on the parent (Person.local_id,
  Place.local_id, Public_health_case.local_id) using their conventional
  patterns (e.g., `N'PSN20000000GA01'`, `N'CAS20000100GA01'`).

## Verification

After authoring, run:

```sh
docker compose down -v
docker compose up -d nbs-mssql liquibase
# wait for liquibase
sqlcmd -S localhost,3433 -U sa -P 'PizzaIsGood33!' -C -i fixtures/00_foundation/00_foundation.sql
```

The fixture must apply without error against a fresh baseline. Then verify
referential integrity with:

```sh
sqlcmd -S localhost,3433 -U sa -P 'PizzaIsGood33!' -C -d NBS_ODSE -Q "
  DBCC CHECKCONSTRAINTS ('dbo.entity_locator_participation');
  DBCC CHECKCONSTRAINTS ('dbo.person');
  DBCC CHECKCONSTRAINTS ('dbo.public_health_case');
  -- etc. for every table you wrote to
"
```

Any FK violations are blocking. Fix and re-run.

## Output: `coverage/coverage_foundation.md`

Use the schema in STRATEGY.md → "Coverage report schema". The "Columns
populated" section at this tier just lists the rows you wrote, since
foundation isn't running any RTR SPs yet — that's Tier 1's job. The
"Foundation dependencies" line says `none`. The "Other-agent dependencies"
line says `baseline SRTE only`.

Record explicitly:

- The full UID allocation table (becomes the seed of `catalog/uid_ranges.md`).
- Every SRTE code referenced, with `code_set_nm` and the value chosen.
- Any column you set to NULL despite RTR SPs reading it — explain briefly
  ("Tier 1 will populate this", "downstream-only", etc.).

## Constraints

- **Do not invoke any RTR SP.** Foundation is data only; SP execution is
  Tier 1's job.
- **Do not author any cross-subject act_relationship, participation, or
  nbs_act_entity rows.** Those are Tier 2.
- **Do not seed SRTE.** Period.
- **Do not write IF NOT EXISTS.** Fresh baseline, no idempotency.

Write the SQL file, apply it against a fresh baseline, run the FK checks,
write the coverage report, and stop.
