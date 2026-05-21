# Coverage: COVID-19 Investigation full ODSE + nrt + NBS_case_answer chain

Generated: 2026-05-21

## Inputs

- Baseline: 6.0.18.1 (post-liquibase) + foundation + all Tier 1 fixtures
  + all Tier 2 fixtures + existing Tier 3 fixtures (including
  `multi_condition_investigations.sql` stub at UID 22000070).
- Fixture file:
  `fixtures/30_sp_coverage/covid_investigation_full_chain.sql`.
- UID range allocated: **22003000 - 22003999** (Tier 3 COVID full-chain).
- Foundation dependencies (read-only):
  - `@superuser_id = 10009282`
  - `@dbo_Entity_patient_uid = 20000000` (foundation Patient; referenced
    by `nrt_investigation.patient_id` so the COVID SP's
    `LEFT OUTER JOIN dbo.D_PATIENT pat ON inv.patient_id = pat.patient_uid`
    and `LEFT OUTER JOIN dbo.NRT_PATIENT nrtPat
    ON nrtPat.patient_uid = pat.patient_uid AND
    nrtPat.status_name_cd = 'A' AND nrtPat.nm_use_cd = 'L'` both resolve
    to populated rows).
- Tier 3 dependencies (read-only):
  - The existing COVID stub at `public_health_case_uid = 22000070` in
    `fixtures/30_sp_coverage/multi_condition_investigations.sql` is
    **left untouched**. It continues to exercise the no-answers path
    (core + patient + entity columns only, ~30 of 383). Our
    full-chain UID 22003000 exercises the discrete-answers /
    multi-answers paths.

## UID allocations

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22003000 | covid_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (every answer row) | The single COVID Investigation full-chain anchor. condition_cd `11065` 2019 Novel Coronavirus, prog_area_cd `COV`, investigation_form_cd `PG_COVID-19_v1.1`. |
| 22003001 | covid_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22003100..22003121 | (22 nbs_case_answer + nrt_page_case_answer pairs) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per COVID question authored: 9 symptoms (FEVER, CHILLS_RIGORS, FATIGUE_MALAISE, HEADACHE, MYALGIA, ALT_MENTAL_STATUS, NAUSEA, DIARRHEA, ABDOMINAL_PAIN), 2 disposition (HOSPITAL_ICU_STAY, US_HC_WORKER_IND), 6 exposure (TRAVEL_DOMESTICALLY, TRAVEL_INTERNATIONAL, CRUISE_TRAVEL_EXP, AIR_TRAVEL_EXP, WORKPLACE_EXP, ANIMAL_EXPOSURE_IND), 3 labs (TEST_TYPE, TEST_RESULT, PERFORMING_LAB_TYPE — Type 3 repeating block with `answer_group_seq_nbr='1'`), 2 comorbidity/status (HYPERTENSION, Symptomatic). |

Unused UIDs in COVID full-chain Tier 3 block (22003002-22003099,
22003122-22003999) reserved for future expansion (more COVID questions
to broaden discrete column coverage, additional repeats `_2`/`_3` for
labs, or LDF-flagged answer rows).

## SPs verified

Tail-EXEC'd in dependency order from the fixture file. All ran without
errors against the live state.

| SP | File | Param | Outcome |
| --- | --- | --- | --- |
| `sp_nrt_investigation_postprocessing` | 005 | `@id_list` | INSERT into `INVESTIGATION` for case_uid=22003000 |

Datamart SPs **NOT run from this fixture** (Step 9 owns):

| SP | File | Why deferred to Step 9 |
| --- | --- | --- |
| `sp_covid_case_datamart_postprocessing` | 310 | Orchestrator runs against full PHC_UIDS. SP is idempotent (DELETE-then-INSERT per PHC). |
| `sp_covid_contact_datamart_postprocessing` | 315 | No ct_contact rows currently link to a COVID condition. |
| `sp_covid_vaccination_datamart_postprocessing` | 320 | No COVID vaccinations. |
| `sp_covid_lab_celr_datamart_postprocessing` | 325 | No COVID-coded LAB observations. |
| `sp_covid_lab_datamart_postprocessing` | 330 | Same — needs COVID lab observations. |

Verified manually that `sp_covid_case_datamart_postprocessing
@phc_uids='22003000'` populates 1 row in COVID_CASE_DATAMART with 53
of 383 columns non-NULL (25 more than the stub alone).

## Columns populated — row counts per cluster table

| Table | Rows (this fixture's contribution) | Notes |
| --- | --- | --- |
| `COVID_CASE_DATAMART` | 1 | 53 / 383 cols populated. Core (`public_health_case_uid`, `INV_LOCAL_ID`, `CONDITION_CD='11065'`, `JURISDICTION_CD='130001'`, `PROGRAM_AREA_CD='COV'`, `INV_CASE_STATUS='C'`, `CASE_RPT_MMWR_WK`, `CASE_RPT_MMWR_YR`), Patient (`PATIENT_FIRST_NAME='Foundation'`, `PATIENT_LAST_NAME='Patient'`, `PATIENT_DOB`, `PATIENT_BIRTH_COUNTRY`, demographics), Symptoms (`FEVER='Yes'`, `CHILLS_RIGORS='Yes'`, `FATIGUE_MALAISE='Yes'`, `HEADACHE='Yes'`, `MYALGIA='Yes'`, `ALT_MENTAL_STATUS='No'`, `NAUSEA='No'`, `DIARRHEA='No'`, `ABDOMINAL_PAIN='No'`), Disposition (`HOSPITAL_ICU_STAY='No'`, `US_HC_WORKER_IND='No'`), Exposure (`TRAVEL_DOMESTICALLY='No'`, `TRAVEL_INTERNATIONAL='No'`, `CRUISE_TRAVEL_EXP='No'`, `AIR_TRAVEL_EXP='No'`, `WORKPLACE_EXP='No'`, `ANIMAL_EXPOSURE_IND='No'`), Comorbidity / Status (`HYPERTENSION='No'`, `Symptomatic='Yes'`), Type-3 labs (`TEST_TYPE_1='SARS coronavirus 2 RNA [Presence] in Unspecified specimen by NAA with probe detection'`, `TEST_RESULT_1='Positive'`, `PERFORMING_LAB_TYPE_1='Hospital Laboratory'`). |
| `COVID_CONTACT_DATAMART` | 0 | No ct_contact rows linked to condition_cd='11065'. See Gaps. |
| `COVID_LAB_DATAMART` | 0 | No COVID-coded LAB observations. See Gaps. |
| `COVID_LAB_CELR_DATAMART` | 0 | Same. |
| `COVID_VACCINATION_DATAMART` | 0 | No COVID vaccinations. See Gaps. |
| `INVESTIGATION` | 1 | Newly inserted row for `case_uid=22003000`. |
| `nrt_investigation` | 1 | Newly inserted staging row. |
| `nrt_page_case_answer` | 22 | Newly inserted staging rows for the 22 authored COVID answers. |

### Summary

- **1 of 5** COVID datamart tables populated (`COVID_CASE_DATAMART`).
- **4 of 5** remain empty: contact / lab / lab_celr / vaccination —
  each requires additional Tier 3 inputs (see LINK_REQUIRED below).
- 53 / 383 COVID_CASE_DATAMART columns non-NULL — up from 28 with the
  bare stub. This is a +89% increase in covered columns for this
  Investigation. Adding more COVID questions (the form has 470 in
  `nbs_ui_metadata`) is mechanical fixture expansion.

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| `COVID_CASE_DATAMART` | ~330 / 383 columns | Each is fed by a distinct COVID question; this fixture authors a 22-question minimum-viable set covering 6 datamart-column categories. The remaining ~448 questions on the COVID form would be authored in fixture-completeness Phase 2. | `310-sp_covid_case_datamart_postprocessing-001.sql` Steps 4 / 7 / 10 / 13 (the SP `EXEC ('ALTER TABLE COVID_CASE_DATAMART ADD ' + col + ' varchar(2000)')` adds ~440 columns dynamically per the form's metadata). |
| `COVID_CASE_DATAMART` | `NOTIFICATION_SENT_DT`, `NOTIFICATION_SUBMIT_DT`, `NOTIFICATION_LOCAL_ID` | No `nrt_investigation_notification` row for `public_health_case_uid=22003000`. Adding one would require a Notification act + an `InvestigationHasNotification` act_relationship → that's a Tier 2 expansion not covered here. | `310-sp_covid_case_datamart_postprocessing-001.sql:227` (`LEFT OUTER JOIN dbo.NRT_INVESTIGATION_NOTIFICATION`) |
| `COVID_CASE_DATAMART` | `CONFIRMATION_METHOD`, `CONFIRMATION_DT` | No `nrt_investigation_confirmation` row. LEFT JOIN — NULL is the populated path. | `310-sp_covid_case_datamart_postprocessing-001.sql:215-223` |
| `COVID_CASE_DATAMART` | `PHC_INV_LAST_NAME`, `PHYS_LAST_NAME`, `RPT_PRV_LAST_NAME`, `RPT_ORG_NAME`, `HOSPITAL_NAME` | nrt_investigation columns `investigator_id`, `physician_id`, `person_as_reporter_uid`, `organization_id`, `hospital_uid` are NULL on the new row. Would require Tier 2 participation edges (`PhysicianOfPHC`, `PerAsReporterOfPHC`, etc.) targeting 22003000. | `310-sp_covid_case_datamart_postprocessing-001.sql:309-348` (UID_CTE + entity LEFT JOINs) |

## Gaps reported

### LINK_REQUIRED: 4 of 5 COVID datamarts need additional inputs

The COVID datamart cluster has 4 sibling datamarts that this fixture
does NOT unblock. Each requires separate Tier 3 work:

- **COVID_CONTACT_DATAMART** — needs `ct_contact` rows with subject
  Investigation 22003000 (or a sibling COVID Investigation),
  populated via `nrt_ct_contact` + the contact postprocessing chain.
  Foundation `ct_contact` (20000170) is bound to Hep A Inv 20000100.
- **COVID_LAB_DATAMART** / **COVID_LAB_CELR_DATAMART** — need
  COVID-coded LAB observations (cd in `94309-2`, `94500-6`, etc.
  per the LOINC COVID set) linked to the Investigation via a Tier 2
  `LabReportToInvestigation` act_relationship. Foundation/v2 Labs
  are bound to Hep A LOINC `13950-1`.
- **COVID_VACCINATION_DATAMART** — needs vaccination
  `nrt_vaccination` row with `vacc_nm` linked via `condition_cd=11065`
  through `nrt_srte_vacc_condition`. Foundation/v2 vaccination is Hep A.

These four would constitute a follow-on fixture
`covid_observations_full_chain.sql` (Tier 3 block 22003200-22003999 or
allocate a new sub-block). Out of scope for this Investigation-focused
fixture.

### SRTE_GAP / Code-set notes

- COVID condition_code `11065` carries `prog_area_cd='GCD'` in
  `NBS_SRTE.dbo.condition_code` (verified 2026-05-21). The
  multi_condition_investigations stub uses `prog_area_cd='COV'`, which
  is NOT in `NBS_SRTE.dbo.program_area_code` (verified). We follow the
  stub's convention here for consistency, because the COVID datamart SP
  filters on `cd='11065'` and `investigation_form_cd='PG_COVID-19_v1.1'`,
  not on `prog_area_cd`. The PROG_AREA_CD column on
  `COVID_CASE_DATAMART` will therefore show 'COV', not 'GCD' — that's
  what MasterETL produces too (it propagates whatever PHC sets). Mark
  this in coverage report only; no fixture change needed.
- All code-set group IDs (4150 YNU, 108020 TEST_TYPE_COVID, 108610
  PHVS_LABTESTINTERPRETATION_VPD_COVID19, 108620
  PHVS_PERFORMINGLABORATORYTYPE_VPD_COVID19) verified live in
  `NBS_SRTE.dbo.codeset_group_metadata`.

### OUT_OF_SCOPE: dyn_dm chain skip

`PG_COVID-19_v1.1` is NOT present as a `FORM_CD` in
`RDB_MODERN.dbo.v_nrt_nbs_page` — only `PG_MIS_C_Investigation_Page →
MIS_COVID_19` is. The orchestrator's dyn_dm Step 9 chain
(`merge_and_verify.sh:541-550`) auto-discovers via that view; therefore
no `DM_INV_COVID_19_v1_1` wide table will be populated by this fixture.
Bug #9 (sp_dyn_dm_repeatvarch UNPIVOT type conflict) is therefore NOT
triggered by this fixture. If desired, a future Tier 3 could author a
`PG_MIS_C_Investigation_Page` Investigation (UID 22000300 or similar)
to drive `DM_INV_MIS_COVID_19` and exercise the dyn_dm chain on COVID
metadata — that WOULD potentially trigger bug #9.

### RTR BUG / WARNING surfaced: COVID_CASE_DATAMART row-size warning

When `sp_covid_case_datamart_postprocessing` runs, SQL Server emits a
warning **per ALTER TABLE statement** (~440 columns added dynamically
from form metadata):

```
Warning: The table "COVID_CASE_DATAMART" has been created, but its
maximum row size exceeds the allowed maximum of 8060 bytes. INSERT or
UPDATE to this table will fail if the resulting row exceeds the size
limit.
```

This is a **latent risk**, not yet a hard failure. With 22 columns
populated, my row is well under 8060 bytes; but if a future fixture
authors enough text columns to push over, INSERTs would silently fail
(or fail per-row in production). The bug is in RTR's choice of
`varchar(2000)` per dynamically-added column, combined with
unconstrained question metadata growth. **Severity: low for now;
medium if the form grows.** Recommended Phase 2 RTR fix: use
`varchar(MAX)` for dynamically-added columns, or store wide data in a
separate child table keyed on `public_health_case_uid`.

Not a fixture bug.

## Orchestrator integration recommendation

`scripts/merge_and_verify.sh` line 446 currently has:

```bash
readonly PHC_UIDS='20000100,20050010,22000010,22000020,22000030,22000040,22000050,22000060,22000070,22000080,22000090,22000100,22000200,22001000'
```

**To pick up this fixture, the orchestrator's `PHC_UIDS` list must be
extended to include 22003000.** Otherwise Step 9's
`sp_covid_case_datamart_postprocessing @phc_uids = "$PHC_UIDS"` will
not include our Investigation in `#PHC_LIST` and the row will not be
inserted into `COVID_CASE_DATAMART` during the full merged run. The
parent agent should add `22003000` to `PHC_UIDS` and also to all the
related per-condition fixture lists (the same pattern applies to TB
22001000, etc., which are already in the list).

Recommended one-line patch:
```bash
readonly PHC_UIDS='20000100,20050010,22000010,...,22001000,22003000'
```

This fixture's tail-EXEC is intentionally short (just
`sp_nrt_investigation_postprocessing`) — Step 9 owns the COVID
datamart SP per the TB-fixture convention. Tail-EXEC + Step 9 = 2
invocations of the COVID case datamart SP, which IS idempotent
because the SP runs DELETE-then-INSERT per @phc_uids (verified
live: re-run on the same UID produces 1 row, not 2 — unlike
TB_DATAMART which has the duplicate-INSERT bug).

## Reproduction recipe

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
# Apply against existing populated state
sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/30_sp_coverage/covid_investigation_full_chain.sql

# Run COVID case datamart for our PHC
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "
  EXEC dbo.sp_covid_case_datamart_postprocessing
    @phc_uids = N'22003000', @debug = 0"

# Verify
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -h -1 -W -Q "
  SELECT 'covid_case_datamart' AS t, COUNT(*) FROM dbo.covid_case_datamart
  UNION ALL SELECT 'covid_contact_datamart', COUNT(*) FROM dbo.covid_contact_datamart
  UNION ALL SELECT 'covid_vaccination_datamart', COUNT(*) FROM dbo.covid_vaccination_datamart"

# Inspect populated columns
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "
  SELECT public_health_case_uid, FEVER, HEADACHE, MYALGIA, HYPERTENSION,
         Symptomatic, TEST_TYPE_1, TEST_RESULT_1, PERFORMING_LAB_TYPE_1
  FROM dbo.covid_case_datamart WHERE public_health_case_uid = 22003000"
```

For a full-baseline replay, `scripts/merge_and_verify.sh` picks up
this fixture at Step 8 automatically (the script iterates
`30_sp_coverage/*.sql` alphabetically — `covid_investigation_full_chain.sql`
sorts after `bmird_*` and before `f_page_case_*`). **Pending action:**
add `22003000` to `PHC_UIDS` so Step 9 picks it up.
