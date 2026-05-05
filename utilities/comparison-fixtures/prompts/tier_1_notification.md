# Tier 1 — Notification

You are a Tier 1 sub-agent. Your subject is **Notification**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

**Important architectural note**: Notification's event SP contains a
hard `INNER JOIN` on `act_relationship` (Notification → Investigation)
at line 49. Without that cross-subject edge, the event SP's SELECT
returns zero rows. **However**, the postprocessing SP reads directly
from the `nrt_investigation_notification` staging table (line 44) — it
does NOT require the event SP to have run. So you CAN populate
NOTIFICATION + NOTIFICATION_EVENT at Tier 1 by writing the staging row
yourself. The cross-subject dependency only affects whether the event
SP's SELECT projection emits rows for Kafka; it doesn't gate
postprocessing. Read the "Cross-subject dependencies" section carefully
— it shapes how you author the staging row.

## Subject identity

- **Subject name:** notification
- **Foundation row:** `@dbo_Act_notification_uid = 20000110`
  (`act.act_uid`, `notification.notification_uid`); class `NOTF`,
  mood `EVN`. Foundation has `case_class_cd=NULL`, `case_condition_cd=NULL`,
  `confirmation_method_cd=NULL`, etc. (Tier 1 deferred — see
  `coverage_foundation.md`).
- **No internal locators.** Notification is an Act, not an Entity.
- **Your UID block:** `20060000–20069999` per `catalog/uid_ranges.md`.
  Update the registry with your final allocation.

## SP chain

- Event SP: `dbo.sp_notification_event @notification_list nvarchar(max)`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/064-sp_notification_event-001.sql`
  - **Param name is `@notification_list`** (yet another variant).
- Postprocessing SP: `dbo.sp_nrt_notification_postprocessing @notification_uids, @debug = 0`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/006-sp_nrt_notification_postprocessing-001.sql`
  - **Param name is `@notification_uids`** (different from event SP's
    `@notification_list` AND from every other postprocessing SP's
    `@id_list`).

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md` and live schema:

- `dbo.NOTIFICATION` — primary write target. **Live: 6 cols only**
  (NOTIFICATION_KEY, NOTIFICATION_LOCAL_ID, NOTIFICATION_STATUS,
  NOTIFICATION_COMMENTS, NOTIFICATION_SUBMITTED_BY,
  NOTIFICATION_LAST_CHANGE_TIME). Smaller than expected — most
  notification context lives on the linked NOTIFICATION_EVENT row.
- `dbo.NOTIFICATION_EVENT` — fact table. **Live: 8 cols** —
  (PATIENT_KEY, NOTIFICATION_KEY, NOTIFICATION_SENT_DT_KEY,
  NOTIFICATION_SUBMIT_DT_KEY, NOTIFICATION_UPD_DT_KEY,
  INVESTIGATION_KEY, CONDITION_KEY, COUNT). Almost entirely surrogate
  keys to OTHER dimensions (Patient, Investigation, Condition, dates).
  At Tier 1 with no Tier 2 edges, every cross-subject FK will resolve
  to the unknown-key sentinel (typically 1).
- `dbo.HEPATITIS_DATAMART` — UPDATEd by the postprocessing SP per the
  Phase 0 catalog (line 2091). The UPDATE no-ops if HEPATITIS_DATAMART
  has no row for the notification's investigation/condition. At Tier 1
  this is expected to no-op (no datamart facts populated yet).
- `dbo.nrt_investigation_notification` — synthetic staging. Verify DDL.
- `dbo.nrt_notification_key` — surrogate-key store; **do not hand-write**.

## Cross-subject dependencies — read VERY carefully

The Notification event SP at **line 49** has:

```sql
INNER JOIN nbs_odse.dbo.act_relationship act
   ON act.source_act_uid = notif.notification_uid
INNER JOIN nbs_odse.dbo.public_health_case phc
   ON act.target_act_uid = phc.public_health_case_uid
```

This INNER JOIN means: **without an `act_relationship` row of
`type_cd='Notification'` (or similar — verify in
`catalog/edge_types.md`) linking the Notification's act_uid to an
Investigation's act_uid, the event SP returns ZERO rows.** No JSON
projection, no staging row populated, no postprocessing-SP downstream
write.

You MUST NOT author this `act_relationship` row in your fixture. It is
a cross-subject edge (Notification's act_uid → Investigation's act_uid)
and per the template's "Forbidden in Tier 1" section, cross-subject
`act_relationship`/`participation`/`nbs_act_entity` rows are Tier 2
territory.

The Tier 1 outcome for Notification:
- Event SP runs without error but emits **0 rows** in its SELECT
  projection (because of the INNER JOIN). This is FINE — the event SP
  is just a JSON-emit query for downstream Kafka; it does not populate
  `nrt_investigation_notification`.
- Postprocessing SP runs without error AND **CAN** write rows to
  `NOTIFICATION` and `NOTIFICATION_EVENT` because it reads from
  `nrt_investigation_notification` directly (line 44). Your hand-authored
  staging row drives the populated path.
- However, NOTIFICATION_EVENT joins (lines 86–91) include
  `LEFT JOIN INVESTIGATION` (foundation Investigation = OK), `LEFT
  JOIN D_PATIENT` (foundation Patient row will exist after foundation
  applies BUT only if D_PATIENT was populated by Patient's chain — at
  Tier 1 in *isolation* without running Patient's chain, D_PATIENT
  may be empty), `LEFT JOIN dbo.condition`, and `LEFT JOIN RDB_DATE`.
  The COALESCE-to-1 sentinel handles the missing-FK cases gracefully.
- Set `nrt_investigation_notification.public_health_case_uid =
  20000100` (foundation Investigation) and
  `nrt_investigation_notification.local_patient_uid = 20000000`
  (foundation Patient) so the FK joins resolve when those dimensions
  exist. At Tier 1 in isolation those joins return NULL → COALESCE to
  the sentinel key 1; coverage is preserved (the column is populated,
  just to the unknown sentinel).

The other connective-table reference at line 102 of the event SP is a
LEFT JOIN — produces NULL when missing, doesn't filter rows out.

## What to author at Tier 1

Even though the event SP filters everything out, your fixture has value:

1. **Foundation Notification enrichment**: hang additive child rows off
   `@dbo_Act_notification_uid = 20000110`. Candidates depend on what
   the SP actually reads from staging; minimal enrichment may be
   sufficient.
2. **v2 Notification**: a separate fully-attributed Notification row in
   your block (e.g., UID 20060010 for the Act + notification). Set
   every column the postprocessing SP would populate from
   `nrt_investigation_notification` directly: `notification_status_cd`,
   `notification_comments`, NND-related fields, etc.
3. **Synthetic staging row**: write the row to
   `dbo.nrt_investigation_notification` — but be careful, the
   postprocessing SP may filter this row to only-process-when-also-in-
   nrt_notification_key, and *that* is allocated by the SP itself. Read
   the postprocessing SP body before authoring.

Coverage target: aim for `<populated>/6` on NOTIFICATION and
`<populated>/8` on NOTIFICATION_EVENT. Plausibly 6/6 + 8/8 from the
synthetic staging row alone, with cross-subject FK keys resolving to
the sentinel key 1 (a populated value, just not a "real" link).

The actual cross-subject *content* (PATIENT_NAME etc., which Notification
doesn't store directly — those are on the joined dimensions) won't be
exercised until Tier 2 wires the act_relationship and re-runs Patient's
chain.

## Variant strategy

Two variants is still the pattern (foundation enrichment + v2). Even
if SP coverage is 0/6 + 0/8 at Tier 1, the ODSE rows you author are
needed by Tier 2 — Tier 2 will reference your v2 notification UID when
it writes the `act_relationship` row.

## Forbidden (inherited from template, repeated for clarity)

- **No cross-subject `act_relationship`, `participation`, or
  `nbs_act_entity` rows.** Especially load-bearing here — the inner-join
  on act_relationship is what the contract says Tier 2 will provide.
- No SRTE writes.
- **No UPDATE/DELETE against any foundation row.** Foundation
  Notification's `case_class_cd`, `case_condition_cd`, etc. that are
  flagged "Tier 1 will populate" in `coverage_foundation.md` —
  populate on v2 only.
- Do not write `nrt_notification_key`.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/notification.sql

# event SP — @notification_list
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_notification_event @notification_list = N'20000110,20060010'"
# Expected: 0 rows in the result set. This is correct — the inner join
# requires act_relationship which is Tier 2.

# postprocessing SP — @notification_uids
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_notification_postprocessing @notification_uids = N'20000110,20060010', @debug = 0"
# Expected: COMPLETE in job_flow_log, but 0 rows written to NOTIFICATION
# and NOTIFICATION_EVENT.

# coverage check (expect empty)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT COUNT(*) FROM dbo.NOTIFICATION WHERE NOTIFICATION_LOCAL_ID LIKE '%20000110%' OR NOTIFICATION_LOCAL_ID LIKE '%20060010%';
      SELECT COUNT(*) FROM dbo.NOTIFICATION_EVENT" -h -1
```

Apply the template's stop conditions and final-report shape. Report
`<populated>/6 + <populated>/8`. The postprocessing SP reads from
`nrt_investigation_notification` directly, so coverage of 6/6 + 8/8
is the *target* outcome at Tier 1. Cross-subject FK keys (PATIENT_KEY,
INVESTIGATION_KEY, CONDITION_KEY) will resolve to the sentinel key 1
unless Patient's chain has also run in the same fixture sequence —
either is acceptable; document which.
