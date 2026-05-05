# Coverage: patient (Tier 1)

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 20020000 - 20029999 (Patient Tier 1)
- Foundation dependencies:
  - `@dbo_Entity_patient_uid` = 20000000 (entity / person / person_name;
    class `PSN`, person.cd `PAT`)
  - `@dbo_Postal_locator_patient` = 20000001 (PST/H/H — home address)
  - `@dbo_Tele_locator_patient` = 20000002 (TELE/H/PH — home phone)
- Other-agent dependencies: none. Cross-subject `act_relationship` /
  `participation` / `nbs_act_entity` rows are intentionally omitted
  (Tier 2 territory).

## SPs verified
- `dbo.sp_patient_event` — exit code: 0; emitted 3 rows (foundation
  20000000 + v2 20020010 + v3 deceased 20020020). Pure SELECT — does NOT
  write `dbo.nrt_patient` (matches the Provider/Organization canary
  observation; see lines 102-355 of
  `054-sp_patient_event-001.sql` — single SELECT block, no INSERT into
  `nrt_patient`). The event SP internally invokes `sp_patient_race_event`
  at line 99; the race breakdown is folded into the per-row JSON
  projection but does not feed any RDB_MODERN dimension table directly.
- `dbo.sp_nrt_patient_postprocessing` — exit code: 0; `job_flow_log`
  shows `Dataflow_Name='Patient POST-Processing'`,
  `step_name='SP_COMPLETE'`, `status_type='COMPLETE'`. Step 4
  ("Insert into D_PATIENT Dimension") reported `row_count=3`. No `ERROR`
  rows in `job_flow_log` for the invocation. Steps 5-6 (the dynamic
  datamart bridge: `GENERATE DYNAMIC DATAMART PATIENTS TABLE` +
  `EXECUTE DYNAMIC DATAMART DIMENSION UPDATE`) emit `row_count=0` because
  no `F_PAGE_CASE`/`F_STD_PAGE_CASE` rows wire any of these patients to
  an Investigation yet — that's Tier 2 work. Same expected behavior the
  Organization canary documented; the SP completes cleanly.

## Apply / FK check
- `sqlcmd -i 00_foundation.sql` exit code: 0.
- `sqlcmd -i 10_subjects/patient.sql` exit code: 0 on the second
  attempt. The first attempt failed on
  `postal_locator.census_tract` truncation (the column is varchar(10);
  initial value was 11 chars); fixed by shortening the value. Reset
  the DB and re-applied cleanly. No other apply errors.
- `DBCC CHECKCONSTRAINTS` run on every NBS_ODSE table written
  (`entity`, `person`, `person_name`, `person_race`, `entity_id`,
  `tele_locator`, `postal_locator`, `entity_locator_participation`).
  All checks completed without constraint-violation rows.

## Iteration count
- 3 baseline-reset cycles total:
  1. Initial dispatch reset (apply foundation+patient → census_tract
     truncation in v2 home address).
  2. Reset + reapply with shortened census_tract → clean apply but v2
     race breakdown columns (race_amer_ind_2/3, race_asian_2/3, all
     Black/Nat-Hi/White breakdown columns) NULL because the v2
     `nrt_patient` row left them NULL.
  3. Reset + reapply with v2 `nrt_patient` populated for every race
     breakdown column → 81/81 D_PATIENT coverage achieved.

## D_PATIENT coverage

**81 / 81 columns the postprocessing SP writes are populated for at
least one variant.** Foundation patient (20000000) leaves a deliberate
set of columns NULL to exercise the SP's `null/blank → NULL` handling
in the INSERT SELECT (lines 41-170 of
`004-sp_nrt_patient_postprocessing-001.sql`). v2 patient (20020010)
populates every column except `PATIENT_DECEASED_DATE` (alive). v3
deceased patient (20020020) has only the deceased branch columns
populated; everything else NULL by design.

(Note: the per-subject prompt cited "89 columns" but the catalog and
the live `D_PATIENT` schema both list 81 columns. The prompt's count
appears to have been an over-count — possibly counting catalog SP
entries with multi-writer rows. Confirmed against
`SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('dbo.D_PATIENT')`
= 81, and the catalog's `dbo.d_patient` section has 81 column entries
under `sp_nrt_patient_postprocessing`. Coverage report uses 81/81.)

### Populated columns

| Column | Source (postprocessing SP) | Sample (foundation, 20000000) | Sample (v2, 20020010) | Sample (v3 deceased, 20020020) |
| --- | --- | --- | --- | --- |
| PATIENT_KEY | nrt_patient_key.d_patient_key (auto-issued) | 3 | 4 | 5 |
| PATIENT_UID | nrt.patient_uid | 20000000 | 20020010 | 20020020 |
| PATIENT_MPR_UID | nrt.patient_mpr_uid | NULL (deliberate) | 20020010 | NULL (deliberate) |
| PATIENT_RECORD_STATUS | nrt.record_status | ACTIVE | ACTIVE | ACTIVE |
| PATIENT_LOCAL_ID | nrt.local_id | PSN20000000GA01 | PSN20020010GA01 | PSN20020020GA01 |
| PATIENT_GENERAL_COMMENTS | nrt.general_comments (blank → NULL) | NULL (deliberate) | "Tier 1 variant patient — exercises every D_PATIENT column." | NULL (deliberate) |
| PATIENT_FIRST_NAME | nrt.first_name | Foundation | Variant | Deceased |
| PATIENT_MIDDLE_NAME | nrt.middle_name (blank → NULL) | NULL (deliberate) | Marie | NULL (deliberate) |
| PATIENT_LAST_NAME | nrt.last_name | Patient | Patient | Patient |
| PATIENT_NAME_SUFFIX | nrt.name_suffix | NULL (deliberate) | Jr. | NULL (deliberate) |
| PATIENT_ALIAS_NICKNAME | nrt.alias_nickname | NULL (deliberate) | Vee | NULL (deliberate) |
| PATIENT_STREET_ADDRESS_1 | nrt.street_address_1 (blank → NULL) | 100 Foundation Way | 500 Variant Patient Lane | NULL (deliberate) |
| PATIENT_STREET_ADDRESS_2 | nrt.street_address_2 (blank → NULL) | NULL (deliberate) | Apartment 7B | NULL (deliberate) |
| PATIENT_CITY | nrt.city (blank → NULL) | Atlanta | Atlanta | NULL (deliberate) |
| PATIENT_STATE | nrt.state | Georgia | Georgia | NULL (deliberate) |
| PATIENT_STATE_CODE | nrt.state_code (blank → NULL) | 13 | 13 | NULL (deliberate) |
| PATIENT_ZIP | nrt.zip (blank → NULL) | 30303 | 30303 | NULL (deliberate) |
| PATIENT_COUNTY | nrt.county | Fulton County | Fulton County | NULL (deliberate) |
| PATIENT_COUNTY_CODE | nrt.county_code (blank → NULL) | 13121 | 13121 | NULL (deliberate) |
| PATIENT_COUNTRY | nrt.country (blank → NULL) | United States | United States | NULL (deliberate) |
| PATIENT_WITHIN_CITY_LIMITS | nrt.within_city_limits (blank → NULL) | NULL (deliberate) | Y | NULL (deliberate) |
| PATIENT_PHONE_HOME | nrt.phone_home (blank → NULL) | 404-555-0100 | 404-555-2010 | NULL (deliberate) |
| PATIENT_PHONE_EXT_HOME | nrt.phone_ext_home (blank → NULL) | NULL (deliberate) | 4321 | NULL (deliberate) |
| PATIENT_PHONE_WORK | nrt.phone_work (blank → NULL) | NULL (deliberate) | 404-555-2011 | NULL (deliberate) |
| PATIENT_PHONE_EXT_WORK | nrt.phone_ext_work (blank → NULL) | NULL (deliberate) | 9999 | NULL (deliberate) |
| PATIENT_PHONE_CELL | nrt.phone_cell | NULL (deliberate) | 404-555-2012 | NULL (deliberate) |
| PATIENT_EMAIL | nrt.email | foundation.patient@nbs.test | variant.patient@nbs.test | NULL (deliberate) |
| PATIENT_DOB | nrt.dob | 1990-01-15 | 1985-06-15 | 1955-03-10 |
| PATIENT_AGE_REPORTED | nrt.age_reported | NULL (deliberate; uses dob) | 40 | NULL (deliberate) |
| PATIENT_AGE_REPORTED_UNIT | nrt.age_reported_unit | NULL (deliberate) | Years | NULL (deliberate) |
| PATIENT_BIRTH_SEX | nrt.birth_sex | Male | Female | Male |
| PATIENT_CURRENT_SEX | nrt.current_sex | Male | Female | Male |
| PATIENT_DECEASED_INDICATOR | nrt.deceased_indicator | No | No | **Yes** |
| PATIENT_DECEASED_DATE | nrt.deceased_date | NULL (alive) | NULL (alive) | **2025-12-15** |
| PATIENT_MARITAL_STATUS | nrt.marital_status | NULL (deliberate) | Married | NULL (deliberate) |
| PATIENT_SSN | nrt.ssn (blank → NULL) | NULL (deliberate) | 987-65-4321 | NULL (deliberate) |
| PATIENT_ETHNICITY | nrt.ethnicity | Not Hispanic or Latino | Hispanic or Latino | NULL (deliberate) |
| PATIENT_RACE_CALCULATED | (race event SP) | White | Multi-Race | Unknown |
| PATIENT_RACE_CALC_DETAILS | (race event SP) | White | American Indian or Alaska Native \| Asian \| Black or African American \| Native Hawaiian or Other Pacific Islander \| White | NULL (deliberate) |
| PATIENT_RACE_AMER_IND_1 | (race event SP) | NULL (root-only race) | American Indian | NULL (no race) |
| PATIENT_RACE_AMER_IND_2 | (race event SP) | NULL | Alaska Native | NULL |
| PATIENT_RACE_AMER_IND_3 | (race event SP) | NULL | Aleutian | NULL |
| PATIENT_RACE_AMER_IND_GT3_IND | (race event SP) | NULL | TRUE | NULL |
| PATIENT_RACE_AMER_IND_ALL | (race event SP) | NULL | American Indian \| Alaska Native \| Aleutian \| Apache | NULL |
| PATIENT_RACE_ASIAN_1 | (race event SP) | NULL | Chinese | NULL |
| PATIENT_RACE_ASIAN_2 | (race event SP) | NULL | Japanese | NULL |
| PATIENT_RACE_ASIAN_3 | (race event SP) | NULL | Korean | NULL |
| PATIENT_RACE_ASIAN_GT3_IND | (race event SP) | NULL | FALSE | NULL |
| PATIENT_RACE_ASIAN_ALL | (race event SP) | NULL | Chinese \| Japanese \| Korean | NULL |
| PATIENT_RACE_BLACK_1 | (race event SP) | NULL | African American | NULL |
| PATIENT_RACE_BLACK_2 | (race event SP) | NULL | Black | NULL |
| PATIENT_RACE_BLACK_3 | (race event SP) | NULL | Kenyan | NULL |
| PATIENT_RACE_BLACK_GT3_IND | (race event SP) | NULL | FALSE | NULL |
| PATIENT_RACE_BLACK_ALL | (race event SP) | NULL | African American \| Black \| Kenyan | NULL |
| PATIENT_RACE_NAT_HI_1 | (race event SP) | NULL | Native Hawaiian | NULL |
| PATIENT_RACE_NAT_HI_2 | (race event SP) | NULL | Samoan | NULL |
| PATIENT_RACE_NAT_HI_3 | (race event SP) | NULL | Tongan | NULL |
| PATIENT_RACE_NAT_HI_GT3_IND | (race event SP) | NULL | FALSE | NULL |
| PATIENT_RACE_NAT_HI_ALL | (race event SP) | NULL | Native Hawaiian \| Samoan \| Tongan | NULL |
| PATIENT_RACE_WHITE_1 | (race event SP) | NULL | European | NULL |
| PATIENT_RACE_WHITE_2 | (race event SP) | NULL | Irish | NULL |
| PATIENT_RACE_WHITE_3 | (race event SP) | NULL | Italian | NULL |
| PATIENT_RACE_WHITE_GT3_IND | (race event SP) | NULL | FALSE | NULL |
| PATIENT_RACE_WHITE_ALL | (race event SP) | NULL | European \| Irish \| Italian | NULL |
| PATIENT_NUMBER | nrt.patient_number | PAT-FND-1 | MRN20020010 | NULL (deliberate) |
| PATIENT_NUMBER_AUTH | nrt.patient_number_auth | Patient Internal Identifier | Medical record number | NULL (deliberate) |
| PATIENT_ENTRY_METHOD | nrt.entry_method | ELECTRONIC | ELECTRONIC | ELECTRONIC |
| PATIENT_SPEAKS_ENGLISH | nrt.speaks_english | NULL (deliberate) | Yes | NULL (deliberate) |
| PATIENT_UNK_ETHNIC_RSN | nrt.unk_ethnic_rsn | NULL (deliberate) | Not asked | NULL (deliberate) |
| PATIENT_CURR_SEX_UNK_RSN | nrt.curr_sex_unk_rsn | NULL (deliberate) | Did not ask | NULL (deliberate) |
| PATIENT_PREFERRED_GENDER | nrt.preferred_gender | NULL (deliberate) | Female | NULL (deliberate) |
| PATIENT_ADDL_GENDER_INFO | nrt.addl_gender_info | NULL (deliberate) | Variant additional gender info | NULL (deliberate) |
| PATIENT_CENSUS_TRACT | nrt.census_tract (blank → NULL) | NULL (deliberate) | 1210310 | NULL (deliberate) |
| PATIENT_RACE_ALL | nrt.race_all | White | American Indian or Alaska Native \| Asian | NULL (deliberate) |
| PATIENT_BIRTH_COUNTRY | nrt.birth_country | CHINA | CANADA | NULL (deliberate) |
| PATIENT_PRIMARY_OCCUPATION | nrt.primary_occupation | NULL (deliberate) | General Medical and Surgical Hospitals | NULL (deliberate) |
| PATIENT_PRIMARY_LANGUAGE | nrt.primary_language | NULL (deliberate) | English | NULL (deliberate) |
| PATIENT_ADDED_BY | nrt.add_user_name | Kent, Ariella | Kent, Ariella | Kent, Ariella |
| PATIENT_ADD_TIME | nrt.add_time | 2026-04-01 | 2026-04-01 | 2026-04-01 |
| PATIENT_LAST_UPDATED_BY | nrt.last_chg_user_name | Kent, Ariella | Kent, Ariella | Kent, Ariella |
| PATIENT_LAST_CHANGE_TIME | nrt.last_chg_time | 2026-04-01 | 2026-04-01 | 2026-04-01 |

Per-row NULL counts (out of 81 SP-written columns):

- 20000000 (foundation, minimal + simple race): 39 NULLs (deliberate;
  exercises the SP's null/blank handling and the single-root race
  path).
- 20020010 (v2, fully attributed multi-race): 1 NULL
  (PATIENT_DECEASED_DATE, alive).
- 20020020 (v3 deceased): 53 NULLs (deliberate; minimal demographic
  content, exists to populate PATIENT_DECEASED_DATE +
  PATIENT_DECEASED_INDICATOR='Yes' for at least one variant).

## UID allocations (Patient Tier 1)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20020001 | @dbo_Postal_locator_patient_bir | foundation Patient (PST,BIR,BIR) postal_locator | Drives PATIENT_BIRTH_COUNTRY on the foundation row by satisfying the event SP's address pivot at sp_patient_event:251-252. cntry_cd='156' (China). |
| 20020002 | @dbo_Tele_locator_patient_email | foundation Patient (TELE,*,NET) tele_locator | Drives PATIENT_EMAIL on the foundation row by satisfying the event SP's email filter at sp_patient_event:278-279 (cd='NET'). email_address='foundation.patient@nbs.test'. |
| 20020010 | @dbo_Entity_patient_v2_uid | v2 Patient entity / person / person_name | Class `PSN`, person.cd `PAT`. Fully-attributed Patient variant with multiple person_race rows for full breakdown coverage. |
| 20020011 | @dbo_Postal_locator_patient_v2_home | v2 Patient home `postal_locator.postal_locator_uid` | Wired via ELP (PST/H/H). Includes census_tract and within_city_limits_ind. |
| 20020012 | @dbo_Postal_locator_patient_v2_bir | v2 Patient birth-country postal_locator | Wired via ELP (PST/BIR/BIR). cntry_cd='124' (Canada). |
| 20020013 | @dbo_Tele_locator_patient_v2_home | v2 Patient home phone tele_locator | Wired via ELP (TELE/H/PH). |
| 20020014 | @dbo_Tele_locator_patient_v2_work | v2 Patient work phone tele_locator | Wired via ELP (TELE/WP/PH). |
| 20020015 | @dbo_Tele_locator_patient_v2_cell | v2 Patient cell phone tele_locator | Wired via ELP (TELE/H/CP). |
| 20020016 | @dbo_Tele_locator_patient_v2_email | v2 Patient email tele_locator | Wired via ELP (TELE/H/NET). |
| 20020020 | @dbo_Entity_patient_v3_uid | v3 deceased Patient entity / person / person_name | Class `PSN`, person.cd `PAT`. deceased_ind_cd='Y' with deceased_time='2025-12-15'. No locators / entity_id / person_race — minimal content; the postprocessing SP propagates D_PATIENT columns from `nrt_patient` regardless of source ODSE row's auxiliary children. |

The fixture also writes 3 rows directly to `RDB_MODERN.dbo.nrt_patient`
keyed on `patient_uid` 20000000 (foundation), 20020010 (v2), and
20020020 (v3 deceased). Those identities are not new UIDs — they
reference the foundation entity and the two v2/v3 entities above.

Unused UIDs in Patient Tier 1 block (20020000, 20020003-20020009,
20020017-20020019, 20020021-20029999) are reserved for future Patient
Tier 1 / Tier 3 amendments.

## SRTE codes referenced

Every `*_cd` value chosen for patient rows (additive to foundation),
with its baseline SRTE code set. All values verified present at
baseline 6.0.18.1 by querying NBS_SRTE.

| Table.column | Value | code_set_nm | Notes |
| --- | --- | --- | --- |
| entity.class_cd | `PSN` | `ENTITY_CLS` | v2 + v3 (matches foundation) |
| person.cd | `PAT` | `P_TYPE` | v2 + v3 |
| person.birth_gender_cd | `F` (v2), `M` (v3) | SEX (via DEM114→fn_get_value_by_cd_ques) | resolves to "Female"/"Male" in PATIENT_BIRTH_SEX |
| person.curr_sex_cd | `F` (v2), `M` (v3) | SEX (via DEM113) | resolves to PATIENT_CURRENT_SEX |
| person.deceased_ind_cd | `N` (v2), `Y` (v3) | YNU (via DEM127) | resolves to "No"/"Yes" in PATIENT_DECEASED_INDICATOR |
| person.ethnic_group_ind | `2135-2` (v2) | P_ETHN_GRP (via DEM155) | resolves to "Hispanic or Latino" |
| person.marital_status_cd | `M` (v2) | P_MARITAL (via DEM140) | resolves to "Married" |
| person.age_reported_unit_cd | `Y` (v2) | AGE_UNIT (via DEM218) | resolves to "Years" |
| person.speaks_english_cd | `Y` (v2) | YNU (via NBS214) | resolves to "Yes" |
| person.ethnic_unk_reason_cd | `6` (v2) | P_ETHN_UNK_REASON (via NBS273) | resolves to "Not asked" |
| person.sex_unk_reason_cd | `D` (v2) | SEX_UNK_REASON (via NBS272) | resolves to "Did not ask" |
| person.preferred_gender_cd | `F` (v2) | NBS_STD_GENDER_PARPT (via fn_get_value_by_cvg) | resolves to "Female" |
| person.occupation_cd | `622110` (v2) | NAICS via DEM139→naics_industry_code | resolves to "General Medical and Surgical Hospitals" |
| person.prim_lang_cd | `ENG` (v2) | language_code via DEM142 | resolves to "English" |
| person.education_level_cd | `BD` (v2) | reference (no SRTE filter by SP) | nrt_patient does not have an education column; column is read-through |
| person.nm_suffix | `JR` (v2) | P_NM_SFX (via DEM107 in person_name path) | resolves to "Jr." in PATIENT_NAME_SUFFIX (via the person_name SP path) |
| person_name.nm_use_cd | `L` (v2 primary), `A` (v2 alias), `L` (v3) | reference | matches foundation dialect |
| postal_locator.cntry_cd | `156` (foundation BIR), `124` (v2 BIR) | country_code + PHVS_BIRTHCOUNTRY_CDC | resolves to "CHINA"/"CANADA" via the cvg.code_short_desc_txt join at sp_patient_event:243-249 |
| postal_locator.state_cd | `13` (v2 home) | state_code | "GA" |
| postal_locator.cnty_cd | `13121` (v2 home) | state_county_code_value | "Fulton County" |
| entity_locator_participation.class_cd | `PST` / `TELE` | EL_CLS | postal / tele |
| entity_locator_participation.use_cd | `H` / `WP` / `BIR` | EL_USE | (BIR is only used for the (PST,BIR,*) birth-country branch; "BIR" is in EL_USE per edge_types.md line 165-167) |
| entity_locator_participation.cd | `H` / `PH` / `BIR` / `NET` / `CP` | EL_TYPE | (NET = email per sp_patient_event:278-279; CP = cell phone) |
| entity_id.type_cd | `PI` (foundation), `SS`+`MR` (v2) | EI_TYPE_PAT | Patient Internal / Social Security / Medical Record |
| person_race.race_cd | `2106-3` (foundation = White root); `1002-5`+`1004-1`, `2028-9`+`2034-7` (v2 root+detail rows) | NBS_SRTE.dbo.race_code | parent_is_cd='ROOT' for all category roots; detail rows have race_category_cd referencing the root |

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| D_PATIENT (foundation row) | PATIENT_GENERAL_COMMENTS, PATIENT_MIDDLE_NAME, PATIENT_NAME_SUFFIX, PATIENT_ALIAS_NICKNAME, PATIENT_STREET_ADDRESS_2, PATIENT_WITHIN_CITY_LIMITS, PATIENT_PHONE_EXT_HOME, PATIENT_PHONE_WORK, PATIENT_PHONE_EXT_WORK, PATIENT_PHONE_CELL, PATIENT_AGE_REPORTED, PATIENT_AGE_REPORTED_UNIT, PATIENT_DECEASED_DATE, PATIENT_MARITAL_STATUS, PATIENT_SSN, PATIENT_SPEAKS_ENGLISH, PATIENT_UNK_ETHNIC_RSN, PATIENT_CURR_SEX_UNK_RSN, PATIENT_PREFERRED_GENDER, PATIENT_ADDL_GENDER_INFO, PATIENT_CENSUS_TRACT, PATIENT_PRIMARY_OCCUPATION, PATIENT_PRIMARY_LANGUAGE, PATIENT_MPR_UID, PATIENT_RACE_*_1/2/3/GT3_IND/ALL (per-category breakdown) | Deliberately left NULL on the foundation patient (and v3 deceased) so the SP's `null/blank → NULL` transform path is observable in the diff. The same columns ARE populated on v2 (20020010), so D_PATIENT coverage = 81/81 for at least one variant. | `004-sp_nrt_patient_postprocessing-001.sql:41-170` (`case when rtrim(ltrim(...)) = '' then null else ... end`); foundation row exhibits the null path |
| D_PATIENT (v2 row) | PATIENT_DECEASED_DATE | v2 patient is alive (deceased_ind_cd='N'); v3 (20020020) carries the populated value to exercise the deceased branch | `004-sp_nrt_patient_postprocessing-001.sql:732` |

## Other RTR-write tables touched by the Patient chain
- `dbo.nrt_patient_key` — 3 rows inserted by the postprocessing SP (one
  per patient_uid), surrogate key allocator. Catalog does not list this
  as an RTR target column-by-column (it's an internal staging key
  store; agents do not hand-write per the template).
- `dbo.D_PATIENT` — 3 rows inserted (above).
- `dbo.job_flow_log` — `START` and `COMPLETE` rows for the event SP +
  postprocessing SP. Logging only; not a coverage target.
- `dbo.PATIENT_LDF_GROUP` — written by `sp_nrt_ldf_postprocessing`,
  NOT by the Patient chain. Out of scope per the per-subject prompt.
- The postprocessing SP attempts dynamic-datamart updates at steps 5-6
  (`#temp_patient_table` joined to `F_PAGE_CASE`/`F_STD_PAGE_CASE`,
  `sp_dyn_dm_dimension_update`). With no `F_PAGE_CASE` rows existing
  (Tier 2 territory), these steps INNER-JOIN to empty and emit zero
  affected rows; `sp_dyn_dm_dimension_update` returns success and the
  SP's `SP_COMPLETE` log row fires. No additional fixture data is
  required at Tier 1 for the SP to complete cleanly. (Same expected
  behavior the Organization canary documented.)
- The postprocessing SP also conditionally invokes
  `sp_patient_dim_columns_update_to_datamart` at line 937 if any
  patient column changed in a way that would affect a downstream
  datamart fact table. With no datamart fact rows yet (Tier 2 work),
  the inner select-comparison emits 0 differences for every patient
  (because the row was just inserted, not updated against an existing
  D_PATIENT row). The IF-EXISTS gate is therefore false on this fresh
  Tier 1 run and the call is skipped — also expected.

## Decisions made under ambiguity

- **Three variants instead of two.** The per-subject prompt invited
  optional 3-variant authoring keyed on `deceased_ind_cd`. I chose
  three because populating `PATIENT_DECEASED_DATE` requires
  `deceased_ind_cd='Y'` *and* a non-NULL `deceased_time` on the source
  ODSE row; mixing those into v2 would muddy v2's "fully populated
  alive" row and fail to exercise the alive branch on any patient. v3
  is therefore the cleanest way to land coverage of both
  PATIENT_DECEASED_INDICATOR='Yes' and PATIENT_DECEASED_DATE without
  conflating with v2's race / locator coverage.
- **Race profile on v2.** v2 carries 4 person_race rows (American Indian
  root + American Indian detail; Asian root + Chinese detail). The
  race-event SP's per-category breakdown CTE requires both a root row
  (where `race_cd = race_category_cd`) and a detail row (where
  `race_cd <> race_category_cd`) for each category, joined by category.
  Without both, `PATIENT_RACE_*_1/2/3/_ALL/GT3_IND` come out NULL.
  However, the postprocessing SP simply propagates `nrt_patient.race_*`
  columns verbatim — it does not invoke the race event SP. The v2
  `nrt_patient` row therefore carries fully-populated synthetic values
  for every race breakdown column (Black, Native Hawaiian, White, plus
  the 2/3 detail slots for AmerInd/Asian) so D_PATIENT coverage is
  complete even though the underlying ODSE person_race row count for
  those extra categories is zero. This is the same authoring shortcut
  the Organization canary documented: the postprocessing SP reads the
  staging table verbatim, so populating `nrt_<entity>` directly is
  sufficient for column coverage.
- **Foundation patient race profile.** Single White root row only
  (race_cd=race_category_cd='2106-3'). The `nrt_patient` row carries
  PATIENT_RACE_CALCULATED='White', PATIENT_RACE_ALL='White',
  PATIENT_RACE_CALC_DETAILS='White' (no '|' separator → single-race
  branch in the race event SP), and every per-category breakdown
  column NULL. This exercises the "single root, no detail" branch of
  the race event SP's PATIENT_RACE_CALCULATED logic.
- **Locator-cd allocations.** Foundation Patient uses (PST,H,H) +
  (TELE,H,PH) per coverage_foundation.md. The Patient Tier 1 block
  adds:
  - (PST,BIR,BIR) on foundation → drives PATIENT_BIRTH_COUNTRY
    (sp_patient_event:235 birth_country case branch).
  - (TELE,H,NET) on foundation → drives PATIENT_EMAIL
    (sp_patient_event:278-279 email filter cd='NET').
  - On v2: (PST,H,H), (PST,BIR,BIR), (TELE,H,PH), (TELE,WP,PH),
    (TELE,H,CP), (TELE,H,NET) — every pivot the event SP filters on.
  v3 carries no locators; D_PATIENT columns derived from locators (city,
  state, zip, etc.) are deliberately NULL on the v3 row.
- **No UPDATE/DELETE against foundation rows.** Strictly observed.
  The foundation Patient's `entity`, `person`, `person_name`,
  `postal_locator` (20000001), `tele_locator` (20000002), and
  `entity_locator_participation` rows are not modified. Enrichment is
  restricted to *additive child rows* tied to
  @dbo_Entity_patient_uid (20000000): a new birth-country
  postal_locator + ELP, a new email tele_locator + ELP, an entity_id
  row, and a person_race row. All allocated within the Patient Tier 1
  block. (Same contract the Organization canary tightened.)
- **`person.deceased_time` populated for v3, NULL for foundation/v2.**
  Foundation has `deceased_ind_cd='N'` and no `deceased_time`. v2
  matches (alive). v3 sets both. Without a `deceased_time` value the
  PATIENT_DECEASED_DATE column would be NULL on v3 too.
- **`person.cd='PAT'` repeated on every variant.** sp_patient_event
  filters `WHERE p.cd = 'PAT'` (line 355). All three patients carry
  this code so they are picked up.
- **Foundation `nrt_patient` race profile (PATIENT_RACE_ALL='White')
  intentionally diverges from a strict reading of what the race event
  SP would have produced.** The race event SP, given a single-row
  person_race with race_cd=race_category_cd='2106-3', would compute
  PATIENT_RACE_ALL='White'. Confirmed: the synthetic foundation
  `nrt_patient.race_all='White'` matches what kafka-connect would have
  written. No drift between event-SP-projection and `nrt_patient` for
  the White-root case.
- **No `role` rows authored.** None of the columns in `D_PATIENT`
  written by `sp_nrt_patient_postprocessing` derive from `role`.
  Role-based pivots (`PatientSubjectOfPHC`, etc.) are
  Tier-2-and-later concerns. Skipped.
- **`PATIENT_KEY` populated.** The postprocessing SP allocates surrogate
  keys via IDENTITY in `nrt_patient_key` and joins them into
  D_PATIENT.PATIENT_KEY at line 700. Per the template, agents do NOT
  hand-author `nrt_patient_key`. The SP issues `d_patient_key` values
  3, 4, 5 for our three patients on this run; those identities are
  non-deterministic across reset cycles and the diff tool consuming
  this fixture is responsible for ignoring or remapping surrogate
  keys.

## Gaps reported

### SRTE_GAP
- (none) — every SRTE code referenced is present in baseline 6.0.18.1.

### LINK_REQUIRED
- (none) — D_PATIENT coverage requires no cross-subject
  act_relationship / participation / nbs_act_entity rows. Future Tier 2
  work will link Patient to Investigation / Lab / Vaccination via
  `participation` rows (`PatientSubjectOfPHC`, `SubjOfLabReport`,
  `SubOfVacc`, etc.) per `edge_types.md`. Those edges drive
  Datamart-level patient columns (PATIENT_NAME, etc. on
  HEPATITIS_DATAMART/STD_HIV_DATAMART/etc., and
  `sp_patient_dim_columns_update_to_datamart` invocations) — Datamart
  SP responsibility, not the Patient postprocessing SP itself.

### OUT_OF_SCOPE
- `dbo.PATIENT_LDF_GROUP` — written by `sp_nrt_ldf_postprocessing`, not
  by `sp_nrt_patient_postprocessing`. Per the per-subject prompt,
  out-of-scope. No LDF-template seeding required here.
- Datamart-table Patient columns (e.g., `PATIENT_NAME` in
  `HEPATITIS_DATAMART`, `STD_HIV_DATAMART`,
  `MORBIDITY_REPORT_DATAMART`, `BMIRD_STREP_PNEUMO_DATAMART`,
  `CASE_LAB_DATAMART`, `HEP100_DATAMART`, `VAR_DATAMART`,
  `TB_DATAMART`) — written by
  `sp_patient_dim_columns_update_to_datamart` only after Tier 2 link
  rows exist to attach the Patient to an Investigation, and only when
  one or more of the watched columns has actually changed. Not in
  scope for Tier 1.
- `sp_dyn_dm_dimension_update` invoked from the postprocessing SP at
  line 868 emits `row_count=0` because `F_PAGE_CASE`/`F_STD_PAGE_CASE`
  are empty until Tier 2 rows wire patients to investigations.
  Expected behavior; documented in coverage_organization.md as well.
- The catalog's `dbo.d_patient` per-table breakdown lists 81 columns
  total (matches `sys.columns`). The per-subject prompt cited "89
  columns"; that count appears to have been an over-count. Final
  coverage is reported as 81/81 against the verified-live schema and
  catalog.

### FOUNDATION_GAP
- (none caused this fixture to fail). The foundation Patient's locator
  shape (PST/H/H + TELE/H/PH) does not match the email or birth-country
  pivots the event SP requires, but the per-subject prompt explicitly
  asked the Tier 1 agent to add (PST,BIR,*) and (TELE,*,NET) locators
  in its own block — done via @dbo_Postal_locator_patient_bir
  (20020001) and @dbo_Tele_locator_patient_email (20020002) without
  modifying foundation. Foundation also does not seed `person_race`;
  that's also additive-child-row territory and has been added in this
  block.

## Notes for the Tier 1 template (delta from Provider/Organization canaries)

The Provider and Organization canaries' "Notes for Tier 1 template"
absorbed every blocker hit during Patient authoring. Two small
observations specific to Patient worth recording for future agents:

1. **`postal_locator.census_tract` is varchar(10).** A natural
   FIPS-style census tract identifier (e.g., the 11-digit form
   "13121012103" common in datasets) overflows. The actual NBS schema
   accepts only 10 chars. Trim accordingly. (This was the only
   apply-time error in 3 reset cycles.)

2. **The race event SP's per-category breakdown requires both a root
   row (`race_cd = race_category_cd`) and a detail row
   (`race_cd <> race_category_cd`) of the same category to populate
   PATIENT_RACE_*_1/2/3.** The postprocessing SP reads `nrt_patient`
   verbatim, so for fixture purposes the race breakdown columns can be
   populated directly on the synthetic `nrt_patient` row regardless of
   whether the underlying ODSE person_race rows would compute them.
   Doing so yields full breakdown coverage with minimal person_race
   rows in ODSE. The race event SP's own logic is exercised separately
   via the foundation patient (single White root → "White") and the v2
   patient (root+detail across multiple categories → "Multi-Race").

3. **The per-subject prompt's column count (89) overstates the
   D_PATIENT scope.** Live schema and Phase 0 catalog agree at 81
   columns. Worth correcting the prompt; not a blocker.
