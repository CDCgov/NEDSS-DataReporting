# Tier 1 — Lab Report

You are a Tier 1 sub-agent. Your subject is **Lab Report** (a.k.a. Order
observation, lab test).

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

**Note**: Lab is the largest-footprint Tier 1 subject so far (~100
catalog columns across 4–5 RDB_MODERN target tables). Budget time
accordingly.

## Subject identity

- **Subject name:** lab (or lab_report)
- **Foundation row:** `@dbo_Act_lab_uid = 20000120`
  (`act.act_uid`, `observation.observation_uid`); class `OBS`,
  mood `EVN`, `obs_domain_cd_st_1='Order'`. Foundation has many
  observation/cd/value columns NULL (Tier 1 deferred — see
  `coverage_foundation.md`).
- **Foundation Patient:** `@dbo_Entity_patient_uid = 20000000`
  (referenced by lab as the subject — observation.subject_person_uid).
- **No internal locators.** Lab is an Act, not an Entity.
- **Your UID block:** `20070000–20079999` per `catalog/uid_ranges.md`.
  Update the registry with your final allocation.

## SP chain

- Event SP: `dbo.sp_observation_event @obs_id_list nvarchar(max)`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/055-sp_observation_event-001.sql`
  - **Note**: This is the SAME event SP that Morbidity Tier 1 will use
    (different `obs_domain_cd` values, but the SP serves both Lab and
    Morbidity observations). The SP has 27 connective-table references
    — most are LEFT JOINs (survivable). Line 421 has a non-LEFT JOIN
    on Act_relationship inside the `associated_investigations` JSON
    sub-projection — that produces NULL for that JSON field when the
    cross-subject edge is missing, but doesn't filter rows.
- Postprocessing SPs:
  1. `dbo.sp_d_lab_test_postprocessing @obs_ids, @debug = 0`
     - File: `routines/018-sp_d_lab_test_postprocessing-001.sql`
     - **Param name is `@obs_ids` (NOT `@id_list`).** Different naming
       convention again.
  2. `dbo.sp_d_labtest_result_postprocessing @obs_ids, @debug = 0`
     - File: `routines/017-sp_d_labtest_result_postprocessing-001.sql`
     - Companion postprocessing for lab results / interpretations /
       comment groups.
- **NOT in scope:**
  - `sp_lab100_datamart_postprocessing` (019), `sp_lab101_datamart_postprocessing` (020),
    `sp_case_lab_datamart_postprocessing` (034) — datamart SPs that read
    from already-populated Lab dimensions and need Tier 2 act_relationship
    rows wiring Lab → Investigation.
  - `sp_covid_lab_celr_datamart_postprocessing` (325),
    `sp_covid_lab_datamart_postprocessing` (330) — COVID-specific
    datamart SPs.

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md` and live schema:

- `dbo.LAB_TEST` — primary write target. **Live: 66 cols / catalog: 67**
  (close drift). Read the catalog's per-table breakdown.
- `dbo.LAB_TEST_RESULT` — secondary write target. Live: 20 cols /
  catalog: 19.
- `dbo.LAB_RPT_USER_COMMENT` — comment dimension. Verify live cols.
- `dbo.TEST_RESULT_GROUPING` — link table.
- `dbo.LAB_RESULT_VAL` — fact table. Verify live cols.
- `dbo.RESULT_COMMENT_GROUP` — comment-grouping link.
- `dbo.L_LAB_TEST` — link from LAB_TEST_KEY to PAGE_CASE_UID (likely
  Tier 2 territory; check the SP).
- `dbo.nrt_observation` — synthetic staging row(s) you write directly
  (driver of the chain).
- Several `nrt_lab_*_key` surrogate-key stores; **do not hand-write**.

The chain expects:
- `nrt_observation` populated for each Lab observation (writes drive
  LAB_TEST + LAB_TEST_RESULT).
- `nrt_observation` joined to baseline-populated `nrt_srte_Lab_test`
  (13,877 rows in baseline) and `nrt_srte_Labtest_loinc` (8,758 rows)
  for LOINC code lookups. **These are pre-populated by Liquibase, not
  by an RTR SP — Lab can rely on them at Tier 1 isolation.**

## Cross-subject dependencies

- The event SP at line 421 has `JOIN Act_relationship` (non-LEFT) but
  it's INSIDE a SELECT subquery for the `associated_investigations`
  JSON field. Without the act_relationship row, the JSON field is
  NULL — but the outer query still emits the lab observation row.
- Lab's postprocessing SPs are mostly self-contained (LAB_TEST has 66
  cols including denormalized patient/provider info packed by the event
  SP). Most cross-subject FKs end up in `L_LAB_TEST` (link to
  PAGE_CASE_UID) which is Tier 2 territory.
- **`PATIENT_KEY` references in LAB_TEST**: spot-check the
  postprocessing SP. If it uses LEFT JOIN to D_PATIENT and COALESCEs to
  1, Tier 1 isolation works (sentinel key 1). If it requires a real
  D_PATIENT row, you need Patient Tier 1's chain to have run first
  (LINK_REQUIRED), or accept that join will return NULL.

If you hit a **Notification-style isolation failure** (FK violation on
NOT-NULL column with no COALESCE), document as
`LINK_REQUIRED: <upstream subject's chain> needed for non-NULL
<COLUMN>` and **do NOT author placeholder rows in the upstream
subject's output table** (that was the Notification contract violation;
template's "Forbidden in Tier 1" section now forbids it explicitly).

## Variant strategy (apply the template's two-variant pattern)

- **Foundation Lab enrichment**: hang additive child rows off
  `@dbo_Act_lab_uid = 20000120`. The foundation Lab already has the
  observation row — leave most observation columns NULL on it
  (per `coverage_foundation.md`'s deferred-columns list). Add child
  rows only where the SP genuinely needs them (e.g., `act_id` for
  the Lab's accession ID, additional `observation` rows for
  result/interp children if the SP chain expects them, observation
  participations to clinical entities — wait, those are Tier 2).
- **v2 Lab**: a separate fully-attributed Lab Report in your block
  (e.g., UID 20070010 for the Act + observation root, plus child
  observation rows for results — Lab tests typically have a parent
  "Order" observation and child "Result" observations). Set every
  observation column the postprocessing SPs read.

Lab observations are typically a **2-level hierarchy** (Order parent +
Result children, related by `act_relationship` of `type_cd='COMP'` or
similar). At Tier 1 you may need:
- One Order observation parent (foundation 20000120 + v2 20070010)
- Multiple Result observation children inside your block
- `act_relationship` rows linking Order → Result. **These act_relationships
  are INTERNAL to the Lab subject** (both endpoints are Lab observations),
  not cross-subject (Lab → Investigation, etc.). Internal-to-subject
  act_relationships are **allowed** at Tier 1 — they're part of the
  Lab's own structure. Cross-subject act_relationships (Lab →
  Investigation) are Tier 2 only.

Verify this Lab-internal-vs-Lab-cross interpretation against
`catalog/edge_types.md` and the SP body. If the SP joins Lab → Result
via a participation type rather than act_relationship, follow the SP.

## Forbidden (inherited from template, repeated for clarity)

- **No cross-subject `act_relationship` (Lab → Investigation), 
  `participation` (Patient as Subject of Lab is Tier 2), or
  `nbs_act_entity` rows.** Lab-internal Order→Result act_relationships
  ARE allowed (see above).
- No SRTE writes. Note: `nrt_srte_Lab_test` and friends are PRE-
  POPULATED in baseline, so SRTE-grounding for LOINC lookups should
  work without writes.
- **No UPDATE/DELETE against any foundation row.** Use v2 variant.
- **No INSERTs into other subjects' RDB_MODERN output tables**
  (D_PATIENT, INVESTIGATION, CONDITION, RDB_DATE, etc.). If a Lab SP's
  join requires them, document as LINK_REQUIRED.
- Do not write `nrt_lab_*_key` surrogate-key stores.
- Do not invoke any of the four datamart SPs listed under "NOT in scope".

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/lab.sql

# event SP — @obs_id_list (yet another param name variation)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_observation_event @obs_id_list = N'20000120,20070010'"

# postprocessing SPs — run BOTH (lab_test then labtest_result), with @obs_ids (different param name)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_d_lab_test_postprocessing @obs_ids = N'20000120,20070010', @debug = 0"

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_d_labtest_result_postprocessing @obs_ids = N'20000120,20070010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.LAB_TEST WHERE LAB_TEST_UID IN (20000120, 20070010)" -y 0 -Y 0
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.LAB_TEST_RESULT WHERE LAB_TEST_UID IN (20000120, 20070010)" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape. Report
`<populated>/<live_count>` for each of LAB_TEST, LAB_TEST_RESULT, and
any other tables your fixture populates. **If you hit Notification-
style isolation failures (FK violation, NOT NULL violation on a
cross-subject FK column), accept the partial coverage and document as
LINK_REQUIRED — do not paper over with placeholder rows.**
