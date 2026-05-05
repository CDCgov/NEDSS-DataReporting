# Coverage: foundation

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 20000000 - 20009999
- Foundation dependencies: none
- Other-agent dependencies: baseline SRTE only

## SPs verified
- (none — Tier 0 does not run RTR SPs; SP-driven coverage is verified in Tier 1+.)

## Apply / FK check
- `sqlcmd -i 00_foundation.sql` exit code: 0 (clean apply on first attempt; no iterations needed).
- `DBCC CHECKCONSTRAINTS` run on every table written: `entity`, `act`, `person`, `person_name`, `organization`, `organization_name`, `place`, `public_health_case`, `notification`, `observation`, `intervention`, `treatment`, `interview`, `ct_contact`, `postal_locator`, `tele_locator`, `entity_locator_participation`. All checks completed with no constraint-violation rows reported.

## Columns populated
Foundation rows written, with the parent identity columns and key shape columns each row carries:

| Table | Column | Sample value |
| --- | --- | --- |
| entity | entity_uid, class_cd | 20000000 / `PSN` (Patient); 20000010 / `PSN` (Provider); 20000020 / `ORG`; 20000030 / `PLC` |
| person | person_uid, cd, local_id, first_nm, last_nm | 20000000 / `PAT` / `PSN20000000GA01` / `Foundation Patient`; 20000010 / `PRV` / `PSN20000010GA01` / `Foundation Provider` |
| person_name | person_uid, person_name_seq, nm_use_cd | 20000000/1/`L`; 20000010/1/`L` |
| organization | organization_uid, display_nm, local_id | 20000020 / `Foundation Organization` / `ORG20000020GA01` |
| organization_name | organization_uid, organization_name_seq, nm_txt, nm_use_cd | 20000020 / 1 / `Foundation Organization` / `L` |
| place | place_uid, nm, local_id | 20000030 / `Foundation Place` / `PLC20000030GA01` |
| postal_locator | postal_locator_uid, street_addr1, city_desc_txt, state_cd, zip_cd | 20000001 / `100 Foundation Way` / `Atlanta` / `13` / `30303` (+3 more for Provider/Org/Place) |
| tele_locator | tele_locator_uid, phone_nbr_txt | 20000002 / `404-555-0100` (+2 more for Provider/Org) |
| entity_locator_participation | entity_uid, locator_uid, class_cd, use_cd, cd | 7 rows: Patient (PST/H/H, TELE/H/PH), Provider (PST/WP/O, TELE/WP/PH), Org (PST/WP/O, TELE/WP/PH), Place (PST/H/H) |
| act | act_uid, class_cd, mood_cd | 20000100 `CASE`/`EVN`; 20000110 `NOTF`/`EVN`; 20000120 `OBS`/`EVN` (lab); 20000130 `OBS`/`EVN` (morb); 20000140 `ENC`/`EVN` (interview); 20000150 `TRMT`/`EVN`; 20000160 `INTV`/`EVN`; 20000170 `ENC`/`EVN` (contact) |
| public_health_case | public_health_case_uid, case_type_cd, cd, local_id, investigation_status_cd, prog_area_cd, jurisdiction_cd | 20000100 / `I` / `10110` / `CAS20000100GA01` / `O` / `STD` / `1` |
| notification | notification_uid, cd, local_id, prog_area_cd, jurisdiction_cd | 20000110 / `NOT100` / `NOT20000110GA01` / `STD` / `1` |
| observation (lab) | observation_uid, cd, local_id, obs_domain_cd_st_1, subject_person_uid | 20000120 / `LAB100` / `OBS20000120GA01` / `Order` / 20000000 |
| observation (morbidity) | observation_uid, cd, local_id, obs_domain_cd_st_1, subject_person_uid | 20000130 / `MOR100` / `OBS20000130GA01` / `Order` / 20000000 |
| interview | interview_uid, local_id, interview_status_cd, interview_type_cd, interview_loc_cd | 20000140 / `INT20000140GA01` / `C` / `INITIAL` / `HOSP` |
| treatment | treatment_uid, cd, local_id, class_cd, prog_area_cd | 20000150 / `TRMT100` / `TRT20000150GA01` / `TRMT` / `STD` |
| intervention (vaccination) | intervention_uid, cd, local_id, class_cd, material_cd, vacc_dose_nbr | 20000160 / `VAC100` / `VAC20000160GA01` / `INTV` / `207` / 1 |
| ct_contact | ct_contact_uid, local_id, subject_entity_uid, contact_entity_uid, subject_entity_phc_uid | 20000170 / `CON20000170GA01` / 20000000 / 20000000 / 20000100 |

Row count by table (within 20000000 - 20009999):

| Table | Rows |
| --- | --- |
| entity | 4 |
| person | 2 |
| person_name | 2 |
| organization | 1 |
| organization_name | 1 |
| place | 1 |
| postal_locator | 4 |
| tele_locator | 3 |
| entity_locator_participation | 7 |
| act | 8 |
| public_health_case | 1 |
| notification | 1 |
| observation | 2 |
| intervention | 1 |
| treatment | 1 |
| interview | 1 |
| ct_contact | 1 |

## SRTE codes referenced
Every `_cd` value chosen for foundation, with its baseline SRTE code set. All values verified present in `NBS_SRTE.dbo.code_value_general` at baseline 6.0.18.1.

| Table.column | Value | code_set_nm | Notes |
| --- | --- | --- | --- |
| entity.class_cd | `PSN` | `ENTITY_CLS` | Patient + Provider |
| entity.class_cd | `ORG` | `ENTITY_CLS` | Organization |
| entity.class_cd | `PLC` | `ENTITY_CLS` | Place |
| person.cd | `PAT` | `P_TYPE` | Patient |
| person.cd | `PRV` | `P_TYPE` | Provider |
| act.class_cd | `CASE` | `ACT_CLS` | Investigation |
| act.class_cd | `NOTF` | `ACT_CLS` | Notification |
| act.class_cd | `OBS` | `ACT_CLS` | Lab + Morbidity |
| act.class_cd | `TRMT` | `ACT_CLS` | Treatment |
| act.class_cd | `INTV` | `ACT_CLS` | Vaccination (Intervention) |
| act.class_cd | `ENC` | `ACT_CLS` | Interview + Contact (no SRTE-listed `act.class_cd` directly for either; `ENC` is the encounter shape used by upstream NBS) |
| act.mood_cd | `EVN` | `ACT_MOOD` | All foundation acts (event mood) |
| entity_locator_participation.class_cd | `PST` | `EL_CLS` | Postal locator |
| entity_locator_participation.class_cd | `TELE` | `EL_CLS` | Tele locator |
| entity_locator_participation.use_cd | `H` | `EL_USE` | Home (Patient address+phone, Place address) |
| entity_locator_participation.use_cd | `WP` | `EL_USE` | Work (Provider, Organization) |
| entity_locator_participation.cd | `H` | `EL_TYPE` | Home address |
| entity_locator_participation.cd | `O` | `EL_TYPE` | Office address |
| entity_locator_participation.cd | `PH` | `EL_TYPE` | Phone |
| person_name.nm_use_cd | `L` | (legal name; reference-only — `RL_TYPE` etc. exist but RTR reads through) | matches existing fixture dialect |
| organization_name.nm_use_cd | `L` | (legal) | same |
| public_health_case.case_type_cd | `I` | (inferred Investigation marker; column is char(1), no SRTE FK) | conventional NBS value |
| public_health_case.investigation_status_cd | `O` | (Open status; PHC enum) | conventional NBS value |
| public_health_case.prog_area_cd | `STD` | program-area code (NBS-specific, not in EL_CLS family) | reasonable seed value |
| public_health_case.jurisdiction_cd | `1` | jurisdiction (NBS-specific) | reasonable seed value |
| public_health_case.shared_ind | `F` | char(1) flag, not coded | conventional |
| notification.shared_ind | `F` | char(1) flag | conventional |
| observation.shared_ind | `F` | char(1) flag | conventional |
| observation.obs_domain_cd_st_1 | `Order` | conventional Lab/Morb root marker (RTR filters at `055-sp_observation_event-001.sql`) | matches edge_types.md note |
| treatment.class_cd | `TRMT` | `ACT_CLS` | column is on treatment, not act; same code set |
| treatment.shared_ind | `F` | char(1) flag | conventional |
| intervention.class_cd | `INTV` | `ACT_CLS` | same code set |
| intervention.shared_ind | `F` | char(1) flag | conventional |
| intervention.material_cd | `207` | CVX vaccine code (HL7 CVX, not a baseline SRTE code set RTR filters on; placeholder for Tier 1 to refine) | conventional CVX value |
| interview.interview_status_cd | `C` | conventional (closed/complete) | not enforced by SRTE FK |
| interview.interview_type_cd | `INITIAL` | conventional NBS interview type | not enforced by SRTE FK |
| interview.interview_loc_cd | `HOSP` | from `RL_TYPE` family — verified present in SRTE | reasonable seed |
| person.administrative_gender_cd / birth_gender_cd / curr_sex_cd | `M` | NBS gender codes | conventional |
| person.deceased_ind_cd | `N` | conventional | |
| person.ethnic_group_ind | `2186-5` | HL7 race/ethnicity code | conventional, matches patientEvent setup.sql |

## Columns deliberately skipped

**For Tier 1 readers:** "Tier 1 <subject> agent" or "Tier 1 will populate"
in the Reason column means *the Tier 1 v2 variant inside the subject
agent's UID block populates the column*, exhibiting the populated path.
The foundation row exhibits the null/blank path. Tier 1 agents must
**not** UPDATE foundation rows to populate these columns — see the Tier
1 template's "Forbidden in Tier 1" section. The two-variant pattern
(foundation NULL + v2 populated) is how both branches of the SP's
transform get exercised.

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| public_health_case | case_class_cd, cd_system_cd, cd_system_desc_txt, condition-driven `*_cnty_*` columns | Tier 1 will populate per-condition variants. RTR datamart SPs branch on `case_class_cd` and `cd_system_cd`. Foundation deliberately leaves these NULL so a Tier 1 investigation agent can refine without colliding. | STRATEGY.md "Tier 1 — Subjects" |
| public_health_case | rpt_cnty_cd, rpt_to_state_time, rpt_form_cmplt_time, mmwr_week, mmwr_year, outbreak_*, outcome_* | Tier 1 / Tier 3 will populate based on which datamart branch they target. | rtr_target_columns.md |
| observation | cd_system_cd, value_cd, ynu_cd, alt_cd, lab_condition_cd, ctrl_cd_*, repeat_nbr | Per-test result columns; Tier 1 lab/morb agents own them. obs_domain_cd_st_1='Order' is sufficient for the Lab/Morb root identity. | edge_types.md "LabReport / MorbReport" |
| notification | case_class_cd, case_condition_cd, confirmation_method_cd, mmwr_*, rpt_sent_time, rpt_source_cd | Tier 1 notification agent populates. | rtr_target_columns.md |
| treatment | activity_from_time, activity_to_time, cd_system_cd, txt | Tier 1 treatment agent. | rtr_target_columns.md |
| intervention | activity_from_time, activity_to_time, target_site_cd, method_cd, vacc_mfgr_cd, age_at_vacc, material_lot_nm, material_expiration_time, vacc_info_source_cd | Tier 1 vaccination agent populates dose-level and clinical detail. | rtr_target_columns.md |
| interview | (all optional clinical / participant fields) | Tier 1 interview agent owns. | rtr_target_columns.md |
| ct_contact | health_status_cd, contact_priority_cd, contact_relationship_cd, exposure_*, named_on_date | Tier 1 contact agent populates contact-investigation columns. | rtr_target_columns.md |
| person | race_cd, race_category_cd, ethnicity_group_cd, occupation_cd, marital_status_cd, education_level_cd, mothers_maiden_nm, ssn, medicaid_num, dl_num, dl_state_cd, age_calc / age_reported family, hm_/wk_ address columns, etc. | Most demographic columns are read-through by RTR; Tier 1 patient/provider agents will populate the columns specific to each subject's RTR branch. Foundation only needs the parent identity row. | rtr_target_columns.md |
| organization | standard_industry_class_cd, electronic_ind/edx_ind variants, street_addr / phone_nbr (denorm) | Tier 1 organization agent. | rtr_target_columns.md |
| place | (address denormalized columns are populated; cd, cd_desc_txt left NULL) | Tier 1 place agent picks place type. | rtr_target_columns.md |

## NULL columns RTR SPs read (justified)
- `person.race_cd`, `person.ethnicity_group_cd` — read by `sp_patient_event` for patient demographics. Tier 1 patient agent will populate.
- `public_health_case.case_class_cd`, `public_health_case.cd_system_cd` — read by `sp_investigation_event` and `sp_public_health_case_fact_datamart_event`. Tier 1 investigation agent populates per-condition variants.
- `observation.cd_system_cd`, `observation.value_cd`, `observation.ynu_cd` — read by `sp_observation_event`. Tier 1 lab/morb agent populates.
- `notification.case_condition_cd`, `notification.case_class_cd` — read by `sp_notification_event`. Tier 1 notification agent populates.
- `treatment.activity_from_time`, `treatment.cd_system_cd` — read by `sp_treatment_event`. Tier 1 treatment agent populates.
- `intervention.activity_from_time`, `intervention.target_site_cd`, `intervention.vacc_mfgr_cd` — read by `sp_vaccination_event`. Tier 1 vaccination agent populates.
- `interview.interview_date` IS populated; status_cd / type_cd / loc_cd populated. Other interview optional columns left NULL for Tier 1.

## Decisions made under ambiguity
- **Contact table name:** `ct_contact` (Pascal `CT_contact` in DDL — no `contact_record` table exists). Confirmed via `INFORMATION_SCHEMA`.
- **CT_contact NOT-NULL FKs:** `subject_entity_uid`, `contact_entity_uid`, `subject_entity_phc_uid` are hard NOT NULL FKs. Foundation has only one Person-class entity (Patient) and one PHC (Investigation), so the contact's subject and contact endpoints both point at Patient and the PHC points at the foundation Investigation. This is internal foundation linkage — not a cross-subject act_relationship / participation row, which the prompt forbids. Tier 1 contact agent can extend with additional contacts in its own UID block.
- **Interview act class:** `ENC` (encounter) chosen for the interview's parent Act row — there is no `INT` value in `ACT_CLS`. RTR reads `interview` rows by `interview_uid` joined to `act.act_uid`; the act class is read-through. `ENC` matches NBS shape.
- **Contact act class:** `ENC` for the same reason. RTR reads `ct_contact` via its own UID; act class is read-through.
- **Locator class allocation:** Patient → home (PST,H,H) + (TELE,H,PH); Provider → work (PST,WP,O) + (TELE,WP,PH); Organization → work (PST,WP,O) + (TELE,WP,PH); Place → physical address as PST/H/H. RTR pivot rules (per edge_types.md) match: sp_patient_event filters on `(PST,H|BIR,*)`, sp_provider_event on `(PST,WP,*)`, sp_organization_event on `(PST,WP,*)` and `(TELE,WP,*)`, sp_place_event on `(TELE,*,*)` and pivots PST locators.
- **Organization name table:** `organization_name` used (matches `organizationEvent/setup.sql` example). `organization_name_seq` started at 1 (the example uses 0; both are valid since the column is `smallint NOT NULL`. 1 chosen for consistency with `person_name_seq`).
- **Sentinel `@superuser_id`:** 10009282 is a soft reference (NBS_ODSE.dbo.auth_user.user_id is `varchar`, contains login names like `superuser`). The bigint 10009282 is the conventional value used in existing fixtures (`patientEvent/setup.sql`, etc.) for `add_user_id`/`last_chg_user_id` columns and is preserved here.
- **No `entity_id` rows on Patient/Provider:** Foundation does not seed `entity_id` rows. The Tier 0 prompt does not list them as required parent rows; Tier 1 patient/provider agents will populate per RTR's `EI_TYPE_PAT` / `EI_TYPE_PRV` branches.
- **No `role` rows:** Same rationale; Tier 1 agents populate per `RL_TYPE` requirements.
- **Date literal format:** `'2026-04-01T00:00:00'` (ISO-style without zone) used per prompt. SQL Server accepts and parses to `datetime`.

## Gaps reported
- (none — no FOUNDATION_GAP, SRTE_GAP, LINK_REQUIRED, or OUT_OF_SCOPE findings during foundation authoring.)
