# Tier 2 — TreatmentToPHC (+ TreatmentToMorb)

You are a Tier 2 sub-agent. Your edge type is **`TreatmentToPHC`**
(TRMT→CASE act_relationship). You'll also author the related
**`TreatmentToMorb`** edges (TRMT→OBS) since both are filtered by the
Treatment event SP and are typically authored together for a single
treatment.

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

This edge is **shape-consistency, not coverage-unlock**. Treatment
Tier 1 isolation already hit 11/11 TREATMENT_EVENT coverage cleanly
because every cross-subject FK in the postprocessing SP is COALESCE-to-1.
Wiring the act_relationships:

- Upgrades sentinel-1 keys to real keys (TREATMENT_EVENT.INVESTIGATION_KEY,
  MORB_RPT_KEY, etc.) once the postprocessing SP re-runs. This DOES happen
  via the `nrt_treatment.associated_phc_uids` soft-ref already written
  by Tier 1, so coverage at the dim/fact level may already be at real
  keys *without* the act_relationship — verify empirically.
- Makes the **ODSE graph correct** for the comparison test against
  MasterETL. MasterETL likely traverses the act_relationship; RTR reads
  the soft-ref; for the diff to make sense, both should reach the same
  endpoint.
- Surfaces the cross-subject context in the **event SP's JSON projection**
  — useful for downstream datamart SPs at Merge contract step 9.

## Edge identity

Two related edge types, both authored in this fixture:

1. **`TreatmentToPHC`** — `act_relationship` of `type_cd='TreatmentToPHC'`
   linking Treatment act_uid → Investigation act_uid.
   - source_class_cd='TRMT', target_class_cd='CASE'
   - SP filter: `070-sp_treatment_event-001.sql:127-129`
   - Catalog: `catalog/edge_types.md` row for `TreatmentToPHC`
2. **`TreatmentToMorb`** — `act_relationship` of `type_cd='TreatmentToMorb'`
   linking Treatment act_uid → Morbidity Order act_uid.
   - source_class_cd='TRMT', target_class_cd='OBS'
   - SP filter: `070-sp_treatment_event-001.sql:86`
   - Catalog: flagged `MISSING_FROM_SRTE` in Phase B but RTR SPs filter
     on the literal regardless. Author with the literal `'TreatmentToMorb'`
     value as documented in Phase B's findings.

## Endpoints to wire

For TreatmentToPHC (4 pairs):
1. Foundation Treatment (`@dbo_Act_treatment_uid = 20000150`) →
   Foundation Investigation (`@dbo_Act_investigation_uid = 20000100`)
2. v2 Treatment (UID 20100010, per Treatment Tier 1 block) →
   v2 Investigation (UID 20050010)
3. v3 Treatment (UID 20100020, per Treatment Tier 1 block — the cd='OTH'
   variant) → foundation Investigation (20000100)

For TreatmentToMorb (3 pairs — same Treatment UIDs, target Morbidity
Order):
1. Foundation Treatment (20000150) → Foundation Morbidity (20000130)
2. v2 Treatment (20100010) → v2 Morbidity Order (20080010)
3. v3 Treatment (20100020) → Foundation Morbidity (20000130)

(Pairing v3 with foundation Investigation/Morbidity is fine; it
exercises the multi-treatment-per-investigation case.)

## Your UID block

- **`21003000–21003999`** (fourth Tier 2 agent — incremented from
  `morb_inv`'s 21002000–21002999). Update `catalog/uid_ranges.md`.

## Required reading (in addition to template's list)

- `coverage/coverage_treatment.md` — note that Treatment hit 11/11
  TREATMENT_EVENT at Tier 1 isolation already (sentinel keys, COALESCE
  pattern). Your edge upgrades sentinels to real keys.
- `coverage/coverage_investigation.md` — find any LINK_REQUIRED entry
  for Treatment/`TreatmentToPHC` (Investigation's notification_history
  aggregation is similar).
- `liquibase-service/.../routines/070-sp_treatment_event-001.sql`
  — line 86 (TreatmentToMorb), lines 127-129 (TreatmentToPHC).
- `liquibase-service/.../routines/047-sp_nrt_treatment_postprocessing-001.sql`
  — line 129/134 reads `nrt_treatment.associated_phc_uids` directly
  (not the act_relationship). So your edge fixture may need a
  `nrt_treatment.associated_phc_uids` UPDATE if Tier 1 didn't already
  set it correctly. Verify.
- `fixtures/20_links/lab_inv.sql` and `morb_inv.sql` — sibling patterns.
  Same staging-table UPDATE approach.

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

# Tier 1 fixtures: patient + provider + organization + investigation + morbidity + treatment
for f in patient provider organization investigation morbidity treatment; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains in dependency order. Run Treatment's chain too — it works
# at Tier 1 isolation (no FK gap), unlike Notification/Morbidity.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event ..."
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing ..."
# (etc. for org, patient, investigation)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_treatment_event @treatment_uids = N'20000150,20100010,20100020'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_treatment_postprocessing @treatment_uids = N'20000150,20100010,20100020', @debug = 0"

# Spot-check pre-edge state: TREATMENT_EVENT keys (likely already real for
# columns Tier 1's nrt_treatment soft-refs hit, sentinel 1 for the rest)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "SELECT TREATMENT_KEY, INVESTIGATION_KEY, MORB_RPT_KEY, PATIENT_KEY FROM dbo.TREATMENT_EVENT"

# Apply your edge fixture (act_relationship rows + tail-EXEC)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/treatment_inv.sql

# Spot-check post-edge state: same query. Did INVESTIGATION_KEY / MORB_RPT_KEY
# change values?
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "SELECT TREATMENT_KEY, INVESTIGATION_KEY, MORB_RPT_KEY, PATIENT_KEY FROM dbo.TREATMENT_EVENT"
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result (clean / iterations).
- Edge rows authored: count + breakdown by type_cd (TreatmentToPHC vs TreatmentToMorb).
- **Did the act_relationship rows change TREATMENT_EVENT coverage?**
  Compare pre-edge vs post-edge values for INVESTIGATION_KEY,
  MORB_RPT_KEY, etc. If coverage is unchanged (i.e., Tier 1's
  `nrt_treatment.associated_phc_uids` already drove resolution), report
  this honestly — the edge is shape-consistency, not coverage-unlock.
- Coverage still LINK_REQUIRED.
- OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP findings (TreatmentToMorb is
  expected `MISSING_FROM_SRTE`).
- Confirmation deliverables exist.
