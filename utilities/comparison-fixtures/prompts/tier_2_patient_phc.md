# Tier 2 — Patient as SubjectOfPHC

You are a Tier 2 sub-agent. Your edge type is **`SubjOfPHC`**
(participation linking Patient → Investigation, where Investigation
is the act and Patient is the subject entity).

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

This edge is fundamental — it establishes who the Investigation is
ABOUT. Datamart-side fact assembly (`sp_public_health_case_fact_datamart_event`,
`sp_public_health_case_fact_datamart_update`) heavily depends on it.
At Tier 1 isolation, every patient-context column in datamart facts is
NULL because no SubjOfPHC participation row exists.

## Edge identity

- **Edge type:** `SubjOfPHC`
- **Table:** `dbo.participation`
- **Discriminators:**
  - `type_cd = 'SubjOfPHC'`
  - `act_class_cd = 'CASE'` (the Investigation)
  - `subject_class_cd = 'PSN'` (the Person/Patient)
- **Direction:** `participation.act_uid = <Investigation's act_uid>`,
  `participation.subject_entity_uid = <Patient's entity_uid>`.
- **Catalog citation:** `catalog/edge_types.md` row for `SubjOfPHC`
  (under `dbo.participation`).
- **SP filter sites:**
  - `056-sp_investigation_event-001.sql:741` (LEFT JOIN; surfaces patient
    UID in Investigation's JSON projection)
  - `064-sp_notification_event-001.sql:102` (LEFT JOIN; gets local_patient_id
    in Notification JSON)
  - `072-sp_public_health_case_fact_datamart_event-001.sql:147` (capitalized
    `SUBJOFPHC`; populates F_PAGE_CASE.PATIENT_KEY etc.)
  - `073-sp_public_health_case_fact_datamart_update-001.sql:54`

## Endpoints to wire

Each Investigation needs ONE SubjOfPHC participation row pointing at
its patient. Two pairs:

1. Foundation Patient (`@dbo_Entity_patient_uid = 20000000`) ↔
   Foundation Investigation (`@dbo_Act_investigation_uid = 20000100`)
2. v2 Patient (UID 20020010) ↔ v2 Investigation (UID 20050010)

(Could also pair foundation Patient ↔ v2 Investigation if the project
wants multiple investigations per patient, but the conventional 1:1
pairing of foundation→foundation + v2→v2 mirrors the existing edge
fixtures.)

## Your UID block

- **`21004000–21004999`** (fifth Tier 2 agent — incremented from
  `treatment_inv`'s 21003000–21003999). Update `catalog/uid_ranges.md`.

## Required reading (in addition to template's list)

- `coverage/coverage_investigation.md` — find LINK_REQUIRED entries
  for SubjOfPHC. These mention F_PAGE_CASE patient columns and the
  notification_history aggregation.
- `coverage/coverage_notification.md` — line 12 mentions the
  participation SubjOfPHC requirement for local_patient_id JSON.
- `liquibase-service/.../routines/056-sp_investigation_event-001.sql` —
  line 741 (the LEFT JOIN context).
- `liquibase-service/.../routines/064-sp_notification_event-001.sql` —
  line 102.
- `liquibase-service/.../routines/072-sp_public_health_case_fact_datamart_event-001.sql` —
  line 147 (the all-caps `SUBJOFPHC` filter — note SQL is case-
  insensitive on string comparisons depending on collation; cite the
  case used).
- `fixtures/20_links/inv_notification.sql` — sibling pattern for
  understanding the file structure.

## participation row shape

```sql
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd],
     [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time],
     [type_desc_txt])
VALUES
    (@foundation_inv_uid, @foundation_patient_uid, N'SubjOfPHC',
     N'CASE', N'PSN',
     '2026-04-01T00:00:00', @superuser_id, '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00',
     N'A', '2026-04-01T00:00:00',
     N'Subject of Public Health Case');
```

Verify the `participation` schema first — earlier Tier 2 agents may
have learned about additional NOT-NULL columns. Inspect with
`INFORMATION_SCHEMA.COLUMNS WHERE table_name='participation'`.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SET NOCOUNT ON;
      WITH dates AS (
        SELECT CAST('2020-01-01' AS DATE) AS dt
        UNION ALL
        SELECT DATEADD(day, 1, dt) FROM dates WHERE dt < '2030-12-31'
      )
      INSERT INTO dbo.RDB_DATE (DATE_KEY, DATE_MM_DD_YYYY)
      SELECT DATEDIFF(day, '2010-01-01', dt) + 1, dt FROM dates
      OPTION (MAXRECURSION 0);"

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_srte_condition_code_postprocessing"

# Foundation
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

# Tier 1 fixtures: patient + investigation (minimum) for this edge.
# Optionally include notification + lab + morbidity if you want to verify
# downstream JSON projections.
for f in patient investigation; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Patient + Investigation chains
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/patient_phc.sql

# Verification: re-run the Investigation event SP and inspect its JSON
# projection. The SubjOfPHC participation row should now surface in the
# investigation_subject branch.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
```

## What coverage does this edge unlock?

Honest assessment: **probably very little at Tier 1 isolation.** Because:
- The Investigation postprocessing SP doesn't read participation rows
  directly — it reads from `nrt_investigation` staging that Tier 1
  hand-authored.
- The Notification SP's LEFT JOIN at line 102 only contributes to the
  JSON projection (consumed by Kafka, not by `sp_nrt_notification_postprocessing`).
- The fact-table-side benefits show up at Merge contract step 9 (Datamart SPs).

The primary value of this edge:
1. **ODSE graph correctness** for the comparison test against MasterETL.
2. **F_PAGE_CASE coverage** when Datamart SPs run later (PATIENT_KEY,
   patient name, etc. in F_PAGE_CASE depend on SubjOfPHC).
3. **Future Tier 3 fact-datamart agents** can rely on this edge being
   present.

Report this honestly in the coverage report — don't claim coverage
unlock if there isn't one at Tier 1 isolation.

## Apply the template's stop conditions and final-report shape

Report:
- Apply result.
- Edge rows authored: count + endpoints (2 expected).
- Coverage assessment: which RDB_MODERN columns flipped from NULL/sentinel-1
  to populated values? If none, report honestly — this edge primarily
  benefits Datamart SPs at Merge step 9.
- Any new LINK_REQUIRED found.
- OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP.
- Confirmation deliverables exist.
