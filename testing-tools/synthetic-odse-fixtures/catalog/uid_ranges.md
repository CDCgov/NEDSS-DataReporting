# UID range registry

Single source of truth for UID allocation across all tiers. Every fixture
reads this before writing. Adding a new tier or block requires appending to
this file in the same PR/turn that authors the corresponding fixture.

Reservation rules (from STRATEGY.md "UID range registry"):

- Tier 0 owns `20000000 - 20009999`.
- Each Tier 1 fixture gets a 10000-wide block in `200_____0 - 200_____9999`.
- Tier 2 fixtures allocate within `21000000 - 21099999`.
- Tier 3 fixtures allocate within `22000000 - 22099999`.
- Sentinel UIDs (e.g., `superuser_id = 10009282`) are referenced by symbolic
  name through `DECLARE`s and never reallocated.
- A fixture allocates only within its assigned block. Cross-references to
  other fixtures' UIDs are by reading this registry, not by guessing.
- Foreign key targets that live outside ODSE (e.g., SRTE codes) are by string
  value, never UID.

## Tier 0: Foundation (20000000 - 20009999)

Allocated by Tier 0. Source: `fixtures/00_foundation/00_foundation.sql`.
Coverage report: `coverage/coverage_foundation.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20000000 | @dbo_Entity_patient_uid | Patient `entity.entity_uid`, `person.person_uid`, `person.person_parent_uid`; also referenced as `observation.subject_person_uid` (Lab + Morb), `ct_contact.subject_entity_uid`, `ct_contact.contact_entity_uid` | Class `PSN`, person.cd `PAT` |
| 20000001 | @dbo_Postal_locator_patient | Patient home `postal_locator.postal_locator_uid` | wired via entity_locator_participation (PST/H/H) |
| 20000002 | @dbo_Tele_locator_patient | Patient home `tele_locator.tele_locator_uid` | wired via entity_locator_participation (TELE/H/PH) |
| 20000010 | @dbo_Entity_provider_uid | Provider `entity.entity_uid`, `person.person_uid`, `person.person_parent_uid` | Class `PSN`, person.cd `PRV` |
| 20000011 | @dbo_Postal_locator_provider | Provider work `postal_locator.postal_locator_uid` | wired via entity_locator_participation (PST/WP/O) |
| 20000012 | @dbo_Tele_locator_provider | Provider work `tele_locator.tele_locator_uid` | wired via entity_locator_participation (TELE/WP/PH) |
| 20000020 | @dbo_Entity_organization_uid | Organization `entity.entity_uid`, `organization.organization_uid`, `organization_name.organization_uid` | Class `ORG` |
| 20000021 | @dbo_Postal_locator_org | Organization work `postal_locator.postal_locator_uid` | wired via entity_locator_participation (PST/WP/O) |
| 20000022 | @dbo_Tele_locator_org | Organization work `tele_locator.tele_locator_uid` | wired via entity_locator_participation (TELE/WP/PH) |
| 20000030 | @dbo_Entity_place_uid | Place `entity.entity_uid`, `place.place_uid` | Class `PLC` |
| 20000031 | @dbo_Postal_locator_place | Place `postal_locator.postal_locator_uid` | wired via entity_locator_participation (PST/H/H) |
| 20000100 | @dbo_Act_investigation_uid | Investigation `act.act_uid`, `public_health_case.public_health_case_uid`; also `ct_contact.subject_entity_phc_uid` | Class `CASE`, mood `EVN` |
| 20000110 | @dbo_Act_notification_uid | Notification `act.act_uid`, `notification.notification_uid` | Class `NOTF`, mood `EVN` |
| 20000120 | @dbo_Act_lab_uid | Lab Report `act.act_uid`, `observation.observation_uid` (obs_domain_cd_st_1='Order') | Class `OBS`, mood `EVN` |
| 20000130 | @dbo_Act_morbidity_uid | Morbidity Report `act.act_uid`, `observation.observation_uid` (obs_domain_cd_st_1='Order') | Class `OBS`, mood `EVN` |
| 20000140 | @dbo_Act_interview_uid | Interview `act.act_uid`, `interview.interview_uid` | Class `ENC`, mood `EVN` |
| 20000150 | @dbo_Act_treatment_uid | Treatment `act.act_uid`, `treatment.treatment_uid` | Class `TRMT`, mood `EVN` |
| 20000160 | @dbo_Act_vaccination_uid | Vaccination `act.act_uid`, `intervention.intervention_uid` | Class `INTV`, mood `EVN` |
| 20000170 | @dbo_Act_contact_uid | Contact Record `act.act_uid`, `ct_contact.ct_contact_uid` | Class `ENC`, mood `EVN` |

Unused UIDs in Tier 0 block (20000003-20000009, 20000013-20000019,
20000023-20000029, 20000032-20000099, 20000101-20000109, 20000111-20000119,
20000121-20000129, 20000131-20000139, 20000141-20000149, 20000151-20000159,
20000161-20000169, 20000171-20009999) are reserved for any future Tier 0
amendments. Do not allocate from this range outside of Tier 0.

## Sentinels (do not allocate)

| UID | Symbolic name | Source | Notes |
| --- | --- | --- | --- |
| 10009282 | @superuser_id | conventional NBS superuser; used as `add_user_id` / `last_chg_user_id` (bigint) on rows. NBS_ODSE.dbo.auth_user.user_id is `varchar` (logins like `superuser`); 10009282 is referenced as a symbolic bigint by all fixtures and is not validated by an FK. |

## Tier 1: Subjects (200_____0 - 200_____9999)

*Allocations made by Tier 1 fixtures. Format: 10000-wide block per subject.
Suggested ranges (reserve a block by appending here):*

| Range | Subject | Status |
| --- | --- | --- |
| 20010000 - 20019999 | Provider (Tier 1) | **allocated** (canary; tier_1_provider_canary.md). See block detail below. |
| 20020000 - 20029999 | Patient (Tier 1) | **allocated** (tier_1_patient). See block detail below. |
| 20030000 - 20039999 | Organization (Tier 1) | **allocated** (tier_1_organization). See block detail below. |
| 20040000 - 20049999 | Place (Tier 1) | **allocated** (tier_1_place). See block detail below. |
| 20050000 - 20059999 | Investigation (Tier 1) | **allocated** (tier_1_investigation). See block detail below. |
| 20060000 - 20069999 | Notification (Tier 1) | **allocated** (tier_1_notification). See block detail below. |
| 20070000 - 20079999 | Lab (Tier 1) | **allocated** (tier_1_lab). See block detail below. |
| 20080000 - 20089999 | Morbidity (Tier 1) | **allocated** (tier_1_morbidity). See block detail below. |
| 20090000 - 20099999 | Interview (Tier 1) | **allocated** (tier_1_interview). See block detail below. |
| 20100000 - 20109999 | Treatment (Tier 1) | **allocated** (tier_1_treatment). See block detail below. |
| 20110000 - 20119999 | Vaccination (Tier 1) | **allocated** (tier_1_vaccination). See block detail below. |
| 20120000 - 20129999 | Contact (Tier 1) | **allocated** (tier_1_contact). See block detail below. |

### Tier 1: Provider (20010000 - 20019999)

Allocated by the Tier 1 Provider canary fixture. Source:
`fixtures/10_subjects/provider.sql`. Coverage report:
`coverage/coverage_provider.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20010001 | @dbo_Tele_locator_provider_work_o | `tele_locator.tele_locator_uid` for foundation Provider's (TELE, WP, `O`) work-phone/email locator | Adds the cd='O' tele locator the Provider event SP requires (lines 115-118), since foundation's tele_locator at 20000012 uses cd='PH'. Also referenced by an `entity_locator_participation` row pointing at @dbo_Entity_provider_uid (20000010). |
| 20010002 | @dbo_Postal_locator_provider_v1_alt | (reserved for foundation Provider variant address, not currently used) | Held for future Tier 3 expansion. |
| 20010010 | @dbo_Entity_provider_v2_uid | v2 Provider `entity.entity_uid`, `person.person_uid`, `person.person_parent_uid` | Class `PSN`, person.cd `PRV`. Fully-attributed Provider variant for column coverage. |
| 20010011 | @dbo_Postal_locator_provider_v2 | v2 Provider work `postal_locator.postal_locator_uid` | Wired via entity_locator_participation (PST/WP/O). |
| 20010012 | @dbo_Tele_locator_provider_v2_work | v2 Provider work phone `tele_locator.tele_locator_uid` | Wired via entity_locator_participation (TELE/WP/O). |
| 20010013 | @dbo_Tele_locator_provider_v2_email | v2 Provider email `tele_locator.tele_locator_uid` | Wired via entity_locator_participation (TELE/WP/O). email_address column. |
| 20010014 | @dbo_Tele_locator_provider_v2_cell | v2 Provider cell phone `tele_locator.tele_locator_uid` | Wired via entity_locator_participation (TELE/WP/`CP`); cd='CP' filter at sp_provider_event line 132. |

Unused UIDs in Provider Tier 1 block (20010000, 20010003-20010009,
20010015-20019999) are reserved for future Provider Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Provider Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_provider`
keyed on `provider_uid` 20000010 (foundation) and 20010010 (v2). Those
identities are not new UIDs. They reference the entities created in
foundation and the v2 entity above.

### Tier 1: Organization (20030000 - 20039999)

Allocated by the Tier 1 Organization fixture. Source:
`fixtures/10_subjects/organization.sql`. Coverage report:
`coverage/coverage_organization.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20030001 | @dbo_Tele_locator_org_fax | `tele_locator.tele_locator_uid` for foundation Org's (TELE, WP, `FAX`) work-fax locator | Adds the cd='FAX' tele locator the Organization event SP requires (lines 124-135), which foundation Org does not have. Also referenced by an `entity_locator_participation` row pointing at @dbo_Entity_organization_uid (20000020). Drives `D_ORGANIZATION.ORGANIZATION_FAX` on the foundation row. |
| 20030010 | @dbo_Entity_organization_v2_uid | v2 Organization `entity.entity_uid`, `organization.organization_uid`, `organization_name.organization_uid` | Class `ORG`. Fully-attributed Organization variant for column coverage (every D_ORGANIZATION column non-NULL). |
| 20030011 | @dbo_Postal_locator_org_v2 | v2 Org work `postal_locator.postal_locator_uid` | Wired via entity_locator_participation (PST/WP/O). |
| 20030012 | @dbo_Tele_locator_org_v2_phone | v2 Org work phone `tele_locator.tele_locator_uid` | Wired via ELP (TELE/WP/PH). Includes `extension_txt` and `email_address`. |
| 20030013 | @dbo_Tele_locator_org_v2_fax | v2 Org work fax `tele_locator.tele_locator_uid` | Wired via ELP (TELE/WP/FAX). |

Unused UIDs in Organization Tier 1 block (20030000, 20030002-20030009,
20030014-20039999) are reserved for future Organization Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Organization Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_organization`
keyed on `organization_uid` 20000020 (foundation) and 20030010 (v2). Those
identities are not new UIDs. They reference the entities created in
foundation and the v2 entity above.

### Tier 1: Patient (20020000 - 20029999)

Allocated by the Tier 1 Patient fixture. Source:
`fixtures/10_subjects/patient.sql`. Coverage report:
`coverage/coverage_patient.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20020001 | @dbo_Postal_locator_patient_bir | `postal_locator.postal_locator_uid` for foundation Patient's birth-country locator (PST/BIR/BIR) | Adds the (PST,BIR,*) postal locator the Patient event SP requires (lines 251-252) so PATIENT_BIRTH_COUNTRY is populated on the foundation row. cntry_cd='156' (China). |
| 20020002 | @dbo_Tele_locator_patient_email | `tele_locator.tele_locator_uid` for foundation Patient's email locator (TELE/H/NET) | Adds the (TELE,*,NET) email locator the Patient event SP requires (lines 278-279). email_address='foundation.patient@nbs.test'. |
| 20020010 | @dbo_Entity_patient_v2_uid | v2 Patient `entity.entity_uid`, `person.person_uid`, `person.person_parent_uid` | Class `PSN`, person.cd `PAT`. Fully-attributed Patient variant for column coverage (every D_PATIENT column non-NULL for v2). Carries 4 person_race rows (AmerInd root+detail, Asian root+detail) for the race-event SP's category breakdown. |
| 20020011 | @dbo_Postal_locator_patient_v2_home | v2 Patient home `postal_locator.postal_locator_uid` | Wired via entity_locator_participation (PST/H/H). Includes census_tract and within_city_limits_ind. |
| 20020012 | @dbo_Postal_locator_patient_v2_bir | v2 Patient birth-country `postal_locator.postal_locator_uid` | Wired via ELP (PST/BIR/BIR). cntry_cd='124' (Canada). |
| 20020013 | @dbo_Tele_locator_patient_v2_home | v2 Patient home phone `tele_locator.tele_locator_uid` | Wired via ELP (TELE/H/PH). |
| 20020014 | @dbo_Tele_locator_patient_v2_work | v2 Patient work phone `tele_locator.tele_locator_uid` | Wired via ELP (TELE/WP/PH). |
| 20020015 | @dbo_Tele_locator_patient_v2_cell | v2 Patient cell phone `tele_locator.tele_locator_uid` | Wired via ELP (TELE/H/CP). |
| 20020016 | @dbo_Tele_locator_patient_v2_email | v2 Patient email `tele_locator.tele_locator_uid` | Wired via ELP (TELE/H/NET). |
| 20020020 | @dbo_Entity_patient_v3_uid | v3 deceased Patient `entity.entity_uid`, `person.person_uid`, `person.person_parent_uid` | Class `PSN`, person.cd `PAT`. deceased_ind_cd='Y' with deceased_time='2025-12-15' so PATIENT_DECEASED_DATE and PATIENT_DECEASED_INDICATOR='Yes' are populated for at least one variant. No locators / entity_id / person_race, so minimal demographic content; the postprocessing SP propagates all D_PATIENT columns regardless of the source ODSE row's auxiliary children, since nrt_patient is hand-written. |

Unused UIDs in Patient Tier 1 block (20020000, 20020003-20020009,
20020017-20020019, 20020021-20029999) are reserved for future Patient
Tier 1 / Tier 3 amendments. Do not allocate from this range outside of
Patient Tier 1.

The fixture also writes 3 rows directly to `RDB_MODERN.dbo.nrt_patient`
keyed on `patient_uid` 20000000 (foundation), 20020010 (v2), and
20020020 (v3 deceased). Those identities are not new UIDs. They
reference the foundation entity created in 00_foundation.sql plus the
two v2/v3 entities above.

### Tier 1: Place (20040000 - 20049999)

Allocated by the Tier 1 Place fixture. Source:
`fixtures/10_subjects/place.sql`. Coverage report:
`coverage/coverage_place.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20040000 | @dbo_Postal_locator_place_wp | foundation Place work-place `postal_locator.postal_locator_uid` (PST/WP/PLC) | Wired to @dbo_Entity_place_uid (20000030) via a new (PST,WP,PLC) `entity_locator_participation` row in this block. Required because the event SP at lines 91-94 filters `(USE_CD='WP', CD='PLC', CLASS_CD='PST')` and foundation's existing ELP on postal_locator 20000031 is (PST,H,H). The ELP PK is (entity_uid, locator_uid), so a second ELP row for 20000031 with a different (use_cd, cd) collides, hence a new locator. |
| 20040001 | @dbo_Tele_locator_place_phone | foundation Place work-phone `tele_locator.tele_locator_uid` (TELE/WP/PH) | Foundation Place has no tele locator; this adds one. Drives PLACE_PHONE on the foundation Place's tele rows. nrt_place_tele row keyed on (place_uid=20000030, place_tele_locator_uid=20040001). |
| 20040010 | @dbo_Entity_place_v2_uid | v2 Place `entity.entity_uid` / `place.place_uid` | Class `PLC`, place.cd `M` (Motel/Hotel from PLACE_TYPE). Fully-attributed Place variant for D_PLACE column coverage. |
| 20040011 | @dbo_Postal_locator_place_v2 | v2 Place work-place `postal_locator.postal_locator_uid` (PST/WP/PLC) | Wired via (PST,WP,PLC) ELP. |
| 20040012 | @dbo_Tele_locator_place_v2_phone | v2 Place work-phone `tele_locator.tele_locator_uid` (TELE/WP/PH) | Wired via (TELE,WP,PH) ELP. Includes `extension_txt` and `email_address`. nrt_place_tele row keyed on (place_uid=20040010, place_tele_locator_uid=20040012). |
| 20040013 | @dbo_Tele_locator_place_v2_fax | v2 Place work-fax `tele_locator.tele_locator_uid` (TELE/WP/FAX) | Wired via (TELE,WP,FAX) ELP. Shape-only on the ODSE side; exercises the EL_TYPE_TELE_PLC `FAX` code in the event SP's JSON projection. The hand-authored nrt_place_tele row on v2 references the phone locator (20040012), not this fax locator. |

Unused UIDs in Place Tier 1 block (20040002-20040009,
20040014-20049999) are reserved for future Place Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Place Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_place`
keyed on `place_uid` 20000030 (foundation) and 20040010 (v2), and 2
rows to `RDB_MODERN.dbo.nrt_place_tele` keyed on the same two
place_uids. Those identities are not new UIDs. They reference the
foundation entity created in 00_foundation.sql plus the v2 entity
above.

### Tier 1: Investigation (20050000 - 20059999)

Allocated by the Tier 1 Investigation fixture. Source:
`fixtures/10_subjects/investigation.sql`. Coverage report:
`coverage/coverage_investigation.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20050010 | @dbo_Act_investigation_v2_uid | v2 Investigation `act.act_uid`, `public_health_case.public_health_case_uid` | Class `CASE`, mood `EVN`, case_class_cd `C` (Confirmed), cd `10110` (Hepatitis A, acute), prog_area_cd `HEP`, jurisdiction_cd `130001` (Fulton County), investigation_form_cd `PG_Hepatitis_A_Acute_Investigation`. Fully-attributed Investigation variant for INVESTIGATION column coverage. |
| 20050011 | @dbo_Case_management_v2_uid | v2 case_management `case_management.case_management_uid` (IDENTITY column, toggled IDENTITY_INSERT) | Wired to @dbo_Act_investigation_v2_uid via case_management.public_health_case_uid. Used by sp_investigation_event's case_management JSON branch (lines 603-691). INVESTIGATION dimension does not directly store case-management columns; this row is added for event SP projection completeness on v2. |

The fixture also adds **one new act_id row** keyed on
`act_uid = @dbo_Act_investigation_uid (20000100)` (foundation Investigation
enrichment, foundation has no act_id rows). That row's identity is the
foundation Act UID, not a new UID; act_id keys on (act_uid, act_id_seq).

The fixture writes **2 rows** directly to `RDB_MODERN.dbo.nrt_investigation`
keyed on `public_health_case_uid` 20000100 (foundation) and 20050010
(v2). Those identities reference the foundation PHC + the v2 PHC; not
new UIDs.

The fixture writes **1 row** directly to
`RDB_MODERN.dbo.nrt_investigation_confirmation` keyed on
`public_health_case_uid = 20050010` (v2 only). Foundation Investigation
has no confirmation method, so this exercises the no-CM branch.

Unused UIDs in Investigation Tier 1 block (20050000-20050009,
20050012-20059999) are reserved for future Investigation Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Investigation
Tier 1.

### Tier 1: Notification (20060000 - 20069999)

Allocated by the Tier 1 Notification fixture. Source:
`fixtures/10_subjects/notification.sql`. Coverage report:
`coverage/coverage_notification.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20060001 | (no symbolic: INVESTIGATION dim scaffolding) | `RDB_MODERN.dbo.INVESTIGATION.INVESTIGATION_KEY` | Fixture-environment scaffolding row that lets `sp_nrt_notification_postprocessing`'s `LEFT JOIN dbo.INVESTIGATION` resolve when Notification runs in isolation. CASE_UID=20000100 (foundation Investigation). The SP at lines 79-80 reads `inv.INVESTIGATION_KEY` directly (no COALESCE), and INVESTIGATION_KEY is NOT NULL on NOTIFICATION_EVENT, so the join MUST resolve to a row or the INSERT fails. NOT a coverage row for INVESTIGATION dimension; Investigation Tier 1's own postprocessing-SP-driven row is the canonical INVESTIGATION coverage. |
| 20060002 | (no symbolic: CONDITION dim scaffolding) | `RDB_MODERN.dbo.CONDITION.CONDITION_KEY` | Fixture-environment scaffolding row with CONDITION_CD='10110' (Hepatitis A, acute). Same rationale as INVESTIGATION_KEY=20060001: the SP reads `cnd.CONDITION_KEY` directly and CONDITION_KEY is NOT NULL on NOTIFICATION_EVENT. RDB_MODERN.dbo.CONDITION is empty in baseline 6.0.18.1 (production populates it via `sp_nrt_srte_condition_code_postprocessing`, out of scope for this fixture). |
| 20060010 | @dbo_Act_notification_v2_uid | v2 Notification `act.act_uid`, `notification.notification_uid` | Class `NOTF`, mood `EVN`. Fully-attributed Notification variant for column coverage, with every Tier-1 deferred column populated (case_class_cd 'C', case_condition_cd '10110', confirmation_method_cd 'LD', mmwr_week '14', mmwr_year '2026', rpt_sent_time, rpt_source_cd 'PP', record_status_cd 'COMPLETED'). |

Unused UIDs in Notification Tier 1 block (20060000, 20060003-20060009,
20060011-20069999) are reserved for future Notification Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Notification
Tier 1.

The fixture also writes 2 rows directly to
`RDB_MODERN.dbo.nrt_investigation_notification` keyed on
`notification_uid` 20000110 (foundation) and 20060010 (v2), and 1
sentinel row to `RDB_MODERN.dbo.RDB_DATE` at `DATE_KEY=1`. The
RDB_DATE sentinel is required because `sp_nrt_notification_postprocessing`
COALESCEs missing date keys to 1 (lines 75-76, 81), and
NOTIFICATION_EVENT has FKs from NOTIFICATION_SENT_DT_KEY,
NOTIFICATION_SUBMIT_DT_KEY, and NOTIFICATION_UPD_DT_KEY to
RDB_DATE.DATE_KEY which is empty in baseline 6.0.18.1.

### Tier 1: Lab (20070000 - 20079999)

Allocated by the Tier 1 Lab fixture. Source:
`fixtures/10_subjects/lab.sql`. Coverage report:
`coverage/coverage_lab.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20070010 | @dbo_Act_lab_v2_order_uid | v2 Order observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='Order'`, `ctrl_cd_display_form='LabReport'`. cd='13950-1' (LOINC Hepatitis A IgM Ab → condition '10110' via baseline `nrt_srte_Loinc_condition`). Fully-attributed Lab Order variant for column coverage. |
| 20070011 | @dbo_Act_lab_v2_result_uid | v2 Result observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='Result'`, `ctrl_cd_display_form='LabReport'`. Lab-internal child of 20070010 via `act_relationship` (type_cd='COMP') AND `nrt_observation.report_observation_uid=20070010`. Carries result values (coded POS, numeric >1.10, date, FT/N text). |
| 20070020 | @dbo_Act_lab_v2_corder_uid | v2 followup C_Order observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='C_Order'`. Drives `LAB_RPT_USER_COMMENT` path. NOT in @obs_ids; reached via v2 Order's `followup_observation_uid='20070020,20070021'` CSV. |
| 20070021 | @dbo_Act_lab_v2_cresult_uid | v2 followup C_Result observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='C_Result'`. Carries the user-comment text (`obs_value_txt` txt_type_cd='N'). |
| 20070030 | @dbo_Material_v2_uid | (reserved) v2 specimen material `material.material_uid` | Held for future use; ODSE row not authored due to material→entity FK. Referenced only in `nrt_observation_material.material_id`. |
| 20070031 | @dbo_EDX_Document_v2_uid | (reserved) v2 ELR document `EDX_Document.EDX_Document_uid` | Held for future use; ODSE row not authored due to IDENTITY column. Referenced only in `nrt_observation_edx.edx_document_uid`. |

Unused UIDs in Lab Tier 1 block (20070000-20070009, 20070012-20070019,
20070022-20070029, 20070032-20079999) are reserved for future Lab Tier
1 / Tier 3 amendments. Do not allocate from this range outside of Lab
Tier 1.

The fixture also writes 5 rows to `RDB_MODERN.dbo.nrt_observation`
keyed on `observation_uid` 20000120 (foundation), 20070010 (v2 Order),
20070011 (v2 Result), 20070020 (v2 C_Order), 20070021 (v2 C_Result),
plus 3 rows to `nrt_observation_txt`, 1 row each to
`nrt_observation_coded`, `nrt_observation_numeric`,
`nrt_observation_date`, `nrt_observation_material`,
`nrt_observation_reason`, `nrt_observation_edx`. Those identities are
not new UIDs. They reference observation UIDs declared above.

The fixture also enriches foundation Lab (`act_uid=20000120`) with one
new `act_id` row (act_id_seq=1) and adds 2 `act_id` rows to v2 Order
(act_id_seq 1 and 2). `act_id` keys on (act_uid, act_id_seq); identities
are not new UIDs.

The fixture runs an IDENTITY-advance routine
(`SET IDENTITY_INSERT ON; INSERT high-key; OFF; DELETE`) against
`dbo.nrt_lab_test_result_group_key` and `dbo.nrt_lab_test_key` in
RDB_MODERN to work around a baseline-data quirk in 6.0.18.1
(IDENTITY counter NULL while seeded sentinel row exists at KEY=1). This
is not allocation of UIDs; it is IDENTITY-counter maintenance. See
`coverage_lab.md` BASELINE_QUIRK section.

### Tier 1: Morbidity (20080000 - 20089999)

Allocated by the Tier 1 Morbidity fixture. Source:
`fixtures/10_subjects/morbidity.sql`. Coverage report:
`coverage/coverage_morbidity.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20080010 | @dbo_Act_morb_v2_order_uid | v2 Morb Order observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='Order'`, `ctrl_cd_display_form='MorbReport'`. cd='10110' (Hep A acute). Fully-attributed Morbidity Order variant for column coverage. Carries 18 followup observations via `nrt_observation.followup_observation_uid` CSV. |
| 20080020 | @dbo_Act_morb_v2_corder_uid | v2 followup C_Order observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='C_Order'`. Drives `MORB_RPT_USER_COMMENT` path. NOT in @pMorbidityIdList; reached via v2 Order's followup CSV. |
| 20080021 | @dbo_Act_morb_v2_cresult_uid | v2 followup C_Result observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='C_Result'`. Carries the user-comment txt (`obs_value_txt` / `nrt_observation_txt` txt_type_cd='N'). |
| 20080100 | @dbo_Act_morb_v2_INV128 | v2 followup observation cd=`INV128` (HOSPITALIZED_IND) | Result-domain. obs_value_coded='Y'. |
| 20080101 | @dbo_Act_morb_v2_INV145 | v2 followup observation cd=`INV145` (DIE_FROM_ILLNESS_IND) | Result-domain. obs_value_coded='N'. |
| 20080102 | @dbo_Act_morb_v2_INV148 | v2 followup observation cd=`INV148` (DAYCARE_IND) | Result-domain. obs_value_coded='N'. |
| 20080103 | @dbo_Act_morb_v2_INV149 | v2 followup observation cd=`INV149` (FOOD_HANDLER_IND) | Result-domain. obs_value_coded='N'. |
| 20080104 | @dbo_Act_morb_v2_INV178 | v2 followup observation cd=`INV178` (PREGNANT_IND) | Result-domain. obs_value_coded='N'. |
| 20080105 | @dbo_Act_morb_v2_MRB100 | v2 followup observation cd=`MRB100` (MORB_RPT_TYPE) | Result-domain. obs_value_coded='INIT'. |
| 20080106 | @dbo_Act_morb_v2_MRB102 | v2 followup observation cd=`MRB102` (MORB_RPT_COMMENTS) | Result-domain. obs_value_txt 'FT'. |
| 20080107 | @dbo_Act_morb_v2_MRB122 | v2 followup observation cd=`MRB122` (TEMP_ILLNESS_ONSET_DT_KEY) | Result-domain. obs_value_date 2026-03-25. |
| 20080108 | @dbo_Act_morb_v2_MRB129 | v2 followup observation cd=`MRB129` (NURSING_HOME_ASSOCIATE_IND) | Result-domain. obs_value_coded='N' (substring 1,1 in SP). |
| 20080109 | @dbo_Act_morb_v2_MRB130 | v2 followup observation cd=`MRB130` (HEALTHCARE_ORG_ASSOCIATE_IND) | Result-domain. obs_value_coded='N'. |
| 20080110 | @dbo_Act_morb_v2_MRB161 | v2 followup observation cd=`MRB161` (MORB_RPT_DELIVERY_METHOD) | Result-domain. obs_value_coded='Web'. |
| 20080111 | @dbo_Act_morb_v2_MRB165 | v2 followup observation cd=`MRB165` (TEMP_DIAGNOSIS_DT_KEY / DIAGNOSIS_DT) | Result-domain. obs_value_date 2026-03-30. |
| 20080112 | @dbo_Act_morb_v2_MRB166 | v2 followup observation cd=`MRB166` (HSPTL_ADMISSION_DT) | Result-domain. obs_value_date 2026-03-31. |
| 20080113 | @dbo_Act_morb_v2_MRB167 | v2 followup observation cd=`MRB167` (TEMP_HSPTL_DISCHARGE_DT_KEY) | Result-domain. obs_value_date 2026-04-02. |
| 20080114 | @dbo_Act_morb_v2_MRB168 | v2 followup observation cd=`MRB168` (SUSPECT_FOOD_WTRBORNE_ILLNESS) | Result-domain. obs_value_coded='N'. |
| 20080115 | @dbo_Act_morb_v2_MRB169 | v2 followup observation cd=`MRB169` (MORB_RPT_OTHER_SPECIFY) | Result-domain. obs_value_txt 'FT'. |

Unused UIDs in Morbidity Tier 1 block (20080000-20080009,
20080011-20080019, 20080022-20080099, 20080116-20089999) are reserved
for future Morbidity Tier 1 / Tier 3 amendments. Do not allocate from
this range outside of Morbidity Tier 1.

The fixture also writes 1 `act_id` row keyed on `act_uid=20000130`
(foundation Morbidity enrichment, foundation has none) and 1 `act_id`
row keyed on `act_uid=20080010` (v2 Morb Order). `act_id` keys on
(act_uid, act_id_seq); identities are not new UIDs.

The fixture writes **20 rows** directly to `RDB_MODERN.dbo.nrt_observation`
keyed on `observation_uid` 20000130 (foundation), 20080010 (v2 Order),
20080020/20080021 (v2 C_Order/C_Result), and 20080100..20080115 (16 INV/MRB
followups), plus 10 rows to `nrt_observation_coded`, 4 rows to
`nrt_observation_date`, 3 rows to `nrt_observation_txt`. Those
identities are not new UIDs. They reference observation UIDs declared
above.

No surrogate-key tables hand-authored. Morbidity uses inline
IDENTITY-temp-table allocation rather than IDENTITY-column nrt_*_key
tables, so no Lab-style IDENTITY-counter quirk applies.

### Tier 1: Treatment (20100000 - 20109999)

Allocated by the Tier 1 Treatment fixture. Source:
`fixtures/10_subjects/treatment.sql`. Coverage report:
`coverage/coverage_treatment.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20100010 | @dbo_Act_treatment_v2_uid | v2 Treatment `act.act_uid` / `treatment.treatment_uid` / `treatment_administered.treatment_uid` | Class `TRMT`, mood `EVN`. Fully-attributed variant, Acyclovir composite. cd='1' (TREAT_COMPOSITE), treatment_drug='500' (TREAT_DRUG Acyclovir), route_cd='C0205531' (TREAT_ROUTE PO), dose_qty_unit_cd='mg' (TREAT_DOSE_UNIT), interval_cd='TID' (TREAT_FREQ_UNIT), effective_duration_unit_cd='D' (TREAT_DUR_UNIT). Drives populated path on every TREATMENT-dim column. |
| 20100020 | @dbo_Act_treatment_v3_uid | v3 Treatment `act.act_uid` / `treatment.treatment_uid` / `treatment_administered.treatment_uid` | Class `TRMT`, mood `EVN`. cd='OTH' free-text variant that drives the CUSTOM_TREATMENT CASE THEN branch in `sp_nrt_treatment_postprocessing` line 88. Other clinical columns NULL since v2 already covers their populated path. |

Unused UIDs in Treatment Tier 1 block (20100000-20100009,
20100011-20100019, 20100021-20109999) are reserved for future Treatment
Tier 1 / Tier 3 amendments. Do not allocate from this range outside of
Treatment Tier 1.

The fixture also writes:
- 1 row to `NBS_ODSE.dbo.act_id` keyed on `act_uid=20000150` (foundation Treatment enrichment, foundation has no act_id rows on Treatment).
- 1 row to `NBS_ODSE.dbo.treatment_administered` keyed on `treatment_uid=20000150` (foundation enrichment, required for the event SP's INNER JOIN at line 65 to surface the foundation Treatment row).
- 3 rows to `RDB_MODERN.dbo.nrt_treatment` keyed on `treatment_uid` 20000150 (foundation), 20100010 (v2), 20100020 (v3). Those identities are not new UIDs. They reference the foundation Treatment + v2/v3 entities above.

No surrogate-key tables hand-authored. Treatment's `nrt_treatment_key` IDENTITY counter is in a sane state at baseline (IDENT_CURRENT=2 after the seed sentinel row at d_treatment_key=1), so no Lab-style IDENTITY-counter quirk applies.

### Tier 1: Vaccination (20110000 - 20119999)

Allocated by the Tier 1 Vaccination fixture. Source:
`fixtures/10_subjects/vaccination.sql`. Coverage report:
`coverage/coverage_vaccination.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20110010 | @dbo_Act_vaccination_v2_uid | v2 Vaccination `act.act_uid` / `intervention.intervention_uid` | Class `INTV`, mood `EVN`. Fully-attributed Vaccination variant, Hep A adult (VAC_NM cd='52'), aligned with foundation Investigation condition_cd='10110' (Hep A acute). Drives populated path on every D_VACCINATION column the postprocessing SP reads from nrt_vaccination. |

Unused UIDs in Vaccination Tier 1 block (20110000-20110009,
20110011-20119999) are reserved for future Vaccination Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Vaccination Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_vaccination`
keyed on `vaccination_uid` 20000160 (foundation) and 20110010 (v2). Those
identities are not new UIDs. They reference the foundation Vaccination
created in 00_foundation.sql plus the v2 entity above. No
`nrt_vaccination_answer` rows authored (NRT_METADATA_COLUMNS for
D_VACCINATION is empty in baseline; LDF-column dynamic PIVOT is a
no-op).

No surrogate-key tables hand-authored. Vaccination's
`nrt_vaccination_key` IDENTITY counter is in a sane state at baseline
(IDENT_CURRENT=2 after the seed sentinel row at d_vaccination_key=1),
so no Lab-style IDENTITY-counter quirk applies. The d_vaccination
postprocessing SP allocates surrogate keys via IDENTITY at lines
205-209.

### Tier 1: Interview (20090000 - 20099999)

Allocated by the Tier 1 Interview fixture. Source:
`fixtures/10_subjects/interview.sql`. Coverage report:
`coverage/coverage_interview.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20090010 | @dbo_Act_interview_v2_uid | v2 Interview `act.act_uid` / `interview.interview_uid` | Class `ENC`, mood `EVN`. Fully-attributed Interview variant: interviewee_role_cd='PHYS' (NBS_INTVWEE_ROLE) to exercise F_INTERVIEW_CASE.PHYSICIAN_KEY CASE branch (sp_f_interview_case_postprocessing line 98). interview_status_cd='COMPLETE' (NBS_INTVW_STATUS), interview_type_cd='REINTVW' (NBS_INTERVIEW_TYPE_STDHIV), interview_loc_cd='PHCLINIC' (NBS_INTVW_LOC). |
| 20090020 | (no symbolic: note 1 nbs_answer_uid) | `nrt_interview_note.nbs_answer_uid` for v2 note 1 | Standalone identity value inside Interview's UID block; not a real NBS_ANSWER row UID (the SP only reads it as a column on nrt_interview_note + nrt_interview_note_key, no FK enforced). |
| 20090021 | (no symbolic: note 2 nbs_answer_uid) | `nrt_interview_note.nbs_answer_uid` for v2 note 2 | Same as above. |

Unused UIDs in Interview Tier 1 block (20090000-20090009,
20090011-20090019, 20090022-20099999) are reserved for future Interview
Tier 1 / Tier 3 amendments (e.g., Tier 3 v3 with
`interviewee_role_cd='SUBJECT'` to exercise IX_INTERVIEWEE_KEY THEN
branch). Do not allocate from this range outside of Interview Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_interview`
keyed on `interview_uid` 20000140 (foundation) and 20090010 (v2), and 2
rows to `RDB_MODERN.dbo.nrt_interview_note` keyed on
`interview_uid=20090010` with `nbs_answer_uid` 20090020 and 20090021.
Those identities are not new UIDs. They reference the foundation
Interview created in 00_foundation.sql plus the v2 entity above.

No `nrt_interview_answer` rows authored. `dbo.nrt_metadata_columns` is
empty for `TABLE_NAME='D_INTERVIEW'` in baseline 6.0.18.1, so the
postprocessing SP's dynamic PIVOT collapses to a no-op (verified). LDF
column coverage on D_INTERVIEW (IX_CONTACTS_NAMED_IND, IX_900_SITE_TYPE,
IX_INTERVENTION, IX_900_SITE_ID, IX_900_SITE_ZIP, CLN_CARE_STATUS_IXS)
is a Tier 3 LDF-coverage concern.

No surrogate-key tables hand-authored. the d_interview postprocessing
SP allocates `nrt_interview_key` IDENTITY at lines 206-210 and
`nrt_interview_note_key` IDENTITY at lines 476-481. IDENT_CURRENT
verified at 2 for both at baseline (clean state, sane).

### Tier 1: Contact (20120000 - 20129999)

Allocated by the Tier 1 Contact fixture. Source:
`fixtures/10_subjects/contact.sql`. Coverage report:
`coverage/coverage_contact.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20120010 | @dbo_Act_contact_v2_uid | v2 Contact `act.act_uid` + `ct_contact.ct_contact_uid` | Class `ENC`, mood `EVN`. Fully-attributed Contact variant; every column the postprocessing SPs read from `nrt_contact` set non-NULL except CONTACT_STATUS (left NULL to side-step the event SP's `nbs_odse.dbo.fn_get_value_by_cd_codeset` 3-part-name bug; the function actually lives in RDB_MODERN.dbo). |
| 20120020 | @dbo_Entity_contact_party_uid | v2 contact-party `entity.entity_uid` + `person.person_uid` + `person.person_parent_uid` | Class `PSN`, person.cd `PAT`. Required because `ct_contact.contact_entity_uid` has a UNIQUE constraint (`UQ_CT_contact_3101`); foundation Patient (20000000) is consumed by foundation ct_contact's contact_entity_uid, so v2 needs a distinct entity. Subject_entity_uid + third_party_entity_uid have no UNIQUE constraint and remain pointed at foundation Patient. Minimal person row (no person_name). |

Unused UIDs in Contact Tier 1 block (20120000-20120009, 20120011-20120019,
20120021-20129999) are reserved for future Contact Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Contact Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_contact`
keyed on `contact_uid` 20000170 (foundation) and 20120010 (v2). Those
identities are not new UIDs. They reference the foundation Contact
created in 00_foundation.sql plus the v2 Act+ct_contact above.

No `nrt_contact_answer` rows authored. `dbo.nrt_metadata_columns` is
empty for `TABLE_NAME='D_CONTACT_RECORD'` in baseline 6.0.18.1, so the
postprocessing SP's dynamic PIVOT collapses to a no-op (verified). LDF
column coverage on D_CONTACT_RECORD (the 23 LDF/dynamic columns
including CTT_INITIATE_FOLLOWUP_DT, CTT_*_SEX_EXP_DT, CTT_HEIGHT,
CTT_HAIR, etc.) is a Tier 3 LDF-coverage concern.

No surrogate-key tables hand-authored. the d_contact_record
postprocessing SP allocates `nrt_contact_key` IDENTITY at lines 234-238.
IDENT_CURRENT verified at 2 at baseline (clean state, sane).

## Tier 2: Links (21000000 - 21099999)

*Allocations made by Tier 2 fixtures.*

| Range | Edge type | Status |
| --- | --- | --- |
| 21000000 - 21000999 | `Notification` (NOTF→CASE act_relationship) | **allocated** (tier_2_inv_notification). See block detail below. |
| 21001000 - 21001999 | `LabReport` (OBS→CASE act_relationship) | **allocated** (tier_2_lab_inv). See block detail below. |
| 21002000 - 21002999 | `MorbReport` (OBS→CASE act_relationship) | **allocated** (tier_2_morb_inv). See block detail below. |
| 21003000 - 21003999 | `TreatmentToPHC` + `TreatmentToMorb` (TRMT→CASE / TRMT→OBS act_relationship) | **allocated** (tier_2_treatment_inv). See block detail below. |
| 21004000 - 21004999 | `SubjOfPHC` (PSN→CASE participation) | **allocated** (tier_2_patient_phc). See block detail below. |
| 21005000 - 21005999 | `PerAsReporterOfPHC` + `OrgAsReporterOfPHC` (PSN/ORG→CASE participation) | **allocated** (tier_2_reporter_phc). See block detail below. |
| 21006000 - 21006999 | `PhysicianOfPHC` + `InvestgrOfPHC` (PSN→CASE participation) | **allocated** (tier_2_physician_phc). See block detail below. |
| 21007000 - 21007999 | `SubOfVacc` + `PerformerOfVacc` (INTV→PAT/PSN nbs_act_entity) | **allocated** (tier_2_vaccination_links). See block detail below. |
| 21008000 - 21008999 | `IntrvwerOfInterview` + `IntrvweeOfInterview` + `OrgAsSiteOfIntv` (Interview→PSN/PSN/ORG nbs_act_entity) | **allocated** (tier_2_interview_links). See block detail below. |
| 21009000 - 21009999 | `PerAsReporterOfPHC` + `OrgAsReporterOfPHC` + `HospOfADT` (CASE→PSN/ORG/ORG nbs_act_entity) | **allocated** (tier_2_phc_roles_nae). See block detail below. |

### Tier 2: `Notification` edge (21000000 - 21000999)

Allocated by the Tier 2 inv_notification fixture. Source:
`fixtures/20_links/inv_notification.sql`. Coverage report:
`coverage/coverage_inv_notification.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.act_relationship`
(`type_cd='Notification'`, source_class_cd='NOTF', target_class_cd='CASE'):

1. foundation Notification (20000110) → foundation Investigation (20000100)
2. v2 Notification          (20060010) → v2 Investigation         (20050010)

`act_relationship`'s composite PK is (source_act_uid, target_act_uid,
type_cd), so the rows do not require their own surrogate UID and no
UID is allocated from the 21000000-21000999 block. The block is reserved
for any future amendment (e.g., a Tier 3 v3 Notification variant whose
own act_uid would live in this Tier 2 block, or future surrogate-UID
needs).

Unused UIDs: 21000000-21000999 (entire block reserved). Do not allocate
from this range outside of the inv_notification edge fixture.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables.
Coverage of `NOTIFICATION` and `NOTIFICATION_EVENT` is unlocked indirectly
by the post-edge re-run of `sp_nrt_notification_postprocessing` (in the
fixture's tail-EXEC), which now succeeds because (a) the edge wires the
ODSE act_relationship the SPs need, and (b) the merge orchestrator has
already populated `INVESTIGATION` (via Investigation Tier 1's chain),
`CONDITION` (via `sp_nrt_srte_condition_code_postprocessing`), and
`RDB_DATE` (via `sp_get_date_dim`, see INFRA_GAP in the coverage
report).

### Tier 2: `LabReport` edge (21001000 - 21001999)

Allocated by the Tier 2 lab_inv fixture. Source:
`fixtures/20_links/lab_inv.sql`. Coverage report:
`coverage/coverage_lab_inv.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.act_relationship`
(`type_cd='LabReport'`, source_class_cd='OBS', target_class_cd='CASE'):

1. foundation Lab Order (20000120) → foundation Investigation (20000100)
2. v2 Lab Order         (20070010) → v2 Investigation         (20050010)

`act_relationship`'s composite PK is (source_act_uid, target_act_uid,
type_cd), so the rows do not require their own surrogate UID and no
UID is allocated from the 21001000-21001999 block. The block is reserved
for any future amendment (e.g., a Tier 3 v3 Lab variant whose own
act_uid would live in this Tier 2 block, or future surrogate-UID needs).

In addition, the fixture issues **2 UPDATE statements** against
`RDB_MODERN.dbo.nrt_observation` (a STAGING table, not a dim/fact)
to mirror what the CDC pipeline would have written to
`associated_phc_uids` after `sp_observation_event` re-emits the
JSON projection containing the new act_relationship. The lab
postprocessing SP at `017-sp_d_labtest_result_postprocessing-001.sql:117`
reads `nrt_observation.associated_phc_uids` and at lines 343-346 joins
`dbo.investigation` via `STRING_SPLIT` against `case_uid`. Without the
staging mirror, INVESTIGATION_KEY would remain at sentinel 1.

Unused UIDs: 21001000-21001999 (entire block reserved). Do not allocate
from this range outside of the lab_inv edge fixture.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables.
Coverage of `LAB_TEST_RESULT.INVESTIGATION_KEY` is unlocked indirectly
by the post-edge re-runs of `sp_d_lab_test_postprocessing` and
`sp_d_labtest_result_postprocessing` (in the fixture's tail-EXEC).

### Tier 2: `MorbReport` edge (21002000 - 21002999)

Allocated by the Tier 2 morb_inv fixture. Source:
`fixtures/20_links/morb_inv.sql`. Coverage report:
`coverage/coverage_morb_inv.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.act_relationship`
(`type_cd='MorbReport'`, source_class_cd='OBS', target_class_cd='CASE'):

1. foundation Morb Order (20000130) → foundation Investigation (20000100)
2. v2 Morb Order         (20080010) → v2 Investigation         (20050010)

`act_relationship`'s composite PK is (source_act_uid, target_act_uid,
type_cd), so the rows do not require their own surrogate UID and no
UID is allocated from the 21002000-21002999 block. The block is reserved
for any future amendment (e.g., a Tier 3 v3 Morb variant whose own
act_uid would live in this Tier 2 block, or future surrogate-UID needs).

In addition, the fixture issues **2 UPDATE statements** against
`RDB_MODERN.dbo.nrt_observation` (a STAGING table, not a dim/fact)
to mirror what the CDC pipeline would have written to
`associated_phc_uids` after `sp_observation_event` re-emits the JSON
projection containing the new act_relationship. The Morb postprocessing
SP at `016-sp_nrt_morbidity_report_postprocessing-001.sql:984` joins
`dbo.investigation` via `rpt.associated_phc_uids = inv.case_uid`
(equality, not STRING_SPLIT, per the SP comment block at lines 204-210,
"For MorbReport observations, there can only be one associated
investigation"). Without the staging mirror, INVESTIGATION_KEY would
remain at sentinel 1.

Unused UIDs: 21002000-21002999 (entire block reserved). Do not allocate
from this range outside of the morb_inv edge fixture.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables.
Coverage of `MORBIDITY_REPORT_EVENT` and `MORB_RPT_USER_COMMENT` is
unlocked indirectly by the post-edge re-run of
`sp_d_morbidity_report_postprocessing` (in the fixture's tail-EXEC).

### Tier 2: `TreatmentToPHC` + `TreatmentToMorb` edges (21003000 - 21003999)

Allocated by the Tier 2 treatment_inv fixture. Source:
`fixtures/20_links/treatment_inv.sql`. Coverage report:
`coverage/coverage_treatment_inv.md`.

The fixture authors **6 rows** in `nbs_odse.dbo.act_relationship`:

TreatmentToPHC (`type_cd='TreatmentToPHC'`, source_class_cd='TRMT',
target_class_cd='CASE'), 3 rows:

1. foundation Treatment (20000150) → foundation Investigation (20000100)
2. v2 Treatment         (20100010) → v2 Investigation         (20050010)
3. v3 Treatment         (20100020) → foundation Investigation (20000100)

TreatmentToMorb (`type_cd='TreatmentToMorb'`, source_class_cd='TRMT',
target_class_cd='OBS'), 3 rows:

1. foundation Treatment (20000150) → foundation Morb Order (20000130)
2. v2 Treatment         (20100010) → v2 Morb Order         (20080010)
3. v3 Treatment         (20100020) → foundation Morb Order (20000130)

`act_relationship`'s composite PK is (source_act_uid, target_act_uid,
type_cd), so the rows do not require their own surrogate UID and no
UID is allocated from the 21003000-21003999 block. The block is reserved
for any future amendment (e.g., a Tier 3 v4 Treatment variant whose
own act_uid would live in this Tier 2 block, or future surrogate-UID
needs).

In addition, the fixture issues **2 UPDATE statements** against
`RDB_MODERN.dbo.nrt_treatment` (a STAGING table, not a dim/fact)
to mirror what the CDC pipeline would have written to
`associated_phc_uids` after `sp_treatment_event` re-emits the
JSON projection containing the new TreatmentToPHC act_relationship rows.
The Treatment postprocessing SP at
`047-sp_nrt_treatment_postprocessing-001.sql:134` reads
`nrt_treatment.associated_phc_uids` directly via `OUTER APPLY
STRING_SPLIT` and at line 200-205 joins `dbo.INVESTIGATION` /
`dbo.condition` to resolve INVESTIGATION_KEY / CONDITION_KEY. Without
the staging mirror, those keys remain at sentinel 1 for foundation
(20000150) and v3 (20100020). v2 (20100010) was already correct from
Tier 1 (Treatment Tier 1 set associated_phc_uids='20000100' on v2 only).

Unused UIDs: 21003000-21003999 (entire block reserved). Do not allocate
from this range outside of the treatment_inv edge fixture.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables.
Coverage of `TREATMENT_EVENT.INVESTIGATION_KEY` / `CONDITION_KEY` for
foundation and v3 Treatment rows is unlocked indirectly by the post-edge
re-run of `sp_nrt_treatment_postprocessing` (in the fixture's tail-EXEC),
which now resolves those keys to non-sentinel values (foundation Inv key
3 / Hep A acute condition key 42).

The TreatmentToMorb rows are shape-consistency-only at this Tier 2
fixture's level: the postprocessing SP reads
`nrt_treatment.morbidity_uid` (set by Tier 1 on v2 only); the
TreatmentToMorb act_relationship row is what `sp_treatment_event`
projects into the JSON `morbidity_uid` field that CDC-Debezium would
mirror into staging. Authoring the rows makes the ODSE graph correct
for the comparison test against MasterETL. MORB_RPT_KEY on v2 will
resolve to a real key only after the `morb_inv` Tier 2 edge
is applied AND Morbidity's chain re-runs (a separate Tier 2 fixture's
deliverable; not this fixture's responsibility).

### Tier 2: `SubjOfPHC` edge (21004000 - 21004999)

Allocated by the Tier 2 patient_phc fixture. Source:
`fixtures/20_links/patient_phc.sql`. Coverage report:
`coverage/coverage_patient_phc.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.participation`
(`type_cd='SubjOfPHC'`, `act_class_cd='CASE'`, `subject_class_cd='PSN'`):

1. foundation Patient (entity_uid 20000000) AS subject of foundation Investigation (act_uid 20000100)
2. v2 Patient         (entity_uid 20020010) AS subject of v2 Investigation         (act_uid 20050010)

`participation`'s composite PK is (subject_entity_uid, act_uid,
type_cd), so the rows do not require their own surrogate UID and no
UID is allocated from the 21004000-21004999 block. The block is reserved
for any future amendment (e.g., a Tier 3 v3 Patient or v3 Investigation
variant whose own UIDs would need to live in this Tier 2 block, or
future surrogate-UID needs).

Unused UIDs: 21004000-21004999 (entire block reserved). Do not allocate
from this range outside of the patient_phc edge fixture.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_investigation_event` only (SP-callability check; the event SP's
JSON projection now contains the SubjOfPHC participation row in the
`person_participations` branch).

Honest coverage assessment: this edge is **shape-consistency-mostly at
Tier 1 isolation.** 0 RDB_MODERN dim/fact columns flip from
NULL/sentinel-1 to populated values. The participation row's value
lands in RDB_MODERN via the datamart SPs the reporting-pipeline-service fires during the CDC drain (
`sp_public_health_case_fact_datamart_event`,
`sp_public_health_case_fact_datamart_update`). The `participation`
table is read by event SPs (lines 339-360 + 741 of
`056-sp_investigation_event-001.sql`, line 102 of
`064-sp_notification_event-001.sql`) but those reads only affect JSON
projections consumed by Kafka, not by the postprocessing SPs that
populate RDB_MODERN dim/fact tables. The corresponding postprocessing
SPs read from `nrt_*` staging tables hand-authored by Tier 1, never
from `participation`. Detail: `coverage/coverage_patient_phc.md`.

The SQL Server default collation `SQL_Latin1_General_CP1_CI_AS` is
case-insensitive, so the literal value `'SubjOfPHC'` (mixed case,
matching event-SP filters) also matches the datamart SPs' uppercase
`'SUBJOFPHC'` filter. One row value satisfies all four filter sites.

### Tier 2: `PerAsReporterOfPHC` + `OrgAsReporterOfPHC` edges (21005000 - 21005999)

Allocated by the Tier 2 reporter_phc fixture. Source:
`fixtures/20_links/reporter_phc.sql`. Coverage report:
`coverage/coverage_reporter_phc.md`.

The fixture authors **4 rows** in `nbs_odse.dbo.participation`
(2 PerAsReporterOfPHC + 2 OrgAsReporterOfPHC):

PerAsReporterOfPHC (`type_cd='PerAsReporterOfPHC'`,
`act_class_cd='CASE'`, `subject_class_cd='PSN'`):

1. foundation Provider (entity_uid 20000010) AS reporter of foundation Investigation (act_uid 20000100)
2. v2 Provider         (entity_uid 20010010) AS reporter of v2 Investigation         (act_uid 20050010)

OrgAsReporterOfPHC (`type_cd='OrgAsReporterOfPHC'`,
`act_class_cd='CASE'`, `subject_class_cd='ORG'`):

3. foundation Organization (entity_uid 20000020) AS reporting source of foundation Investigation (act_uid 20000100)
4. v2 Organization         (entity_uid 20030010) AS reporting source of v2 Investigation         (act_uid 20050010)

`participation`'s composite PK is (subject_entity_uid, act_uid,
type_cd), so the rows do not require their own surrogate UID and no
UID is allocated from the 21005000-21005999 block. The block is reserved
for any future amendment (e.g., Tier 3 cross-pair variants whose UIDs
would need to live in this Tier 2 block, or future surrogate-UID needs).

Unused UIDs: 21005000-21005999 (entire block reserved). Do not allocate
from this range outside of the reporter_phc edge fixture.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_investigation_event` only (SP-callability check; the event SP's
JSON projection now contains all 4 reporter participation rows in the
`person_participations` / `organization_participations` branches,
verified for both foundation and v2 Investigations).

Honest coverage assessment: this edge is **shape-consistency-mostly at
Tier 1 isolation.** 0 RDB_MODERN dim/fact columns flip from
NULL/sentinel-1 to populated values. The participation rows' value
lands in RDB_MODERN via the datamart SPs the reporting-pipeline-service fires during the CDC drain (
`sp_public_health_case_fact_datamart_event` lines 1897-1903 / 1944-1948
/ 1964, `sp_public_health_case_fact_datamart_update` lines 105-110 /
155-156 / 160 / 213). Both SPs filter the participation INNER JOIN on
`TYPE_CD IN ('OrgAsReporterOfPHC','InvestgrOfPHC','PerAsReporterOfPHC',
'PhysicianOfPHC')` AND `RECORD_STATUS_CD='ACTIVE'`, populating
F_PAGE_CASE.REPORTER_NAME / REPORTER_PHONE / ORGANIZATION_NAME (and
related). Detail: `coverage/coverage_reporter_phc.md`.

Note: the related `nrt_investigation.person_as_reporter_uid` /
`org_as_reporter_uid` columns called out in `coverage_investigation.md`
LINK_REQUIRED #3-#4 read from the `sp_investigation_event` SP's pivot
on **`nbs_act_entity`** (lines 913 / 932), NOT from `participation`.
A separate Tier 2 `nbs_act_entity_reporter` fixture is required to
populate those columns. The two edge tables (participation vs
nbs_act_entity) are complementary: participation drives the datamart
SPs, while nbs_act_entity drives the event SP's reporter-uid
projection into nrt_investigation.

### Tier 2: `PhysicianOfPHC` + `InvestgrOfPHC` edges (21006000 - 21006999)

Allocated by the Tier 2 physician_phc fixture. Source:
`fixtures/20_links/physician_phc.sql`. Coverage report:
`coverage/coverage_physician_phc.md`.

The fixture authors **4 rows** in `nbs_odse.dbo.participation`
(2 PhysicianOfPHC + 2 InvestgrOfPHC):

PhysicianOfPHC (`type_cd='PhysicianOfPHC'`,
`act_class_cd='CASE'`, `subject_class_cd='PSN'`):

1. foundation Provider (entity_uid 20000010) AS physician of foundation Investigation (act_uid 20000100)
2. v2 Provider         (entity_uid 20010010) AS physician of v2 Investigation         (act_uid 20050010)

InvestgrOfPHC (`type_cd='InvestgrOfPHC'`,
`act_class_cd='CASE'`, `subject_class_cd='PSN'`):

3. foundation Provider (entity_uid 20000010) AS investigator of foundation Investigation (act_uid 20000100)
4. v2 Provider         (entity_uid 20010010) AS investigator of v2 Investigation         (act_uid 20050010)

`participation`'s composite PK is (subject_entity_uid, act_uid,
type_cd), so the rows do not require their own surrogate UID and no
UID is allocated from the 21006000-21006999 block. The block is reserved
for any future amendment (e.g., distinct-Provider variants where the
Physician and Investigator are different Providers, common in
production but skipped in v1 per STRATEGY.md simplification).

Unused UIDs: 21006000-21006999 (entire block reserved). Do not allocate
from this range outside of the physician_phc edge fixture.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_investigation_event` only (SP-callability check; the event SP's
JSON projection now contains the InvestgrOfPHC participation row's
`from_time` as `investigator_assigned_datetime` for both foundation
and v2 Investigations, verified by grep on the JSON output).

Honest coverage assessment: this edge is **shape-consistency-mostly at
Tier 1 isolation.** 0 RDB_MODERN dim/fact columns flip from
NULL/sentinel-1 to populated values. The participation rows' value
lands in RDB_MODERN via the datamart SPs the reporting-pipeline-service fires during the CDC drain (
`sp_public_health_case_fact_datamart_event` lines 1897-1903 / 1934-1962,
`sp_public_health_case_fact_datamart_update` lines 105-110 / 152-160).
Both SPs filter the participation INNER JOIN on
`TYPE_CD IN ('OrgAsReporterOfPHC','InvestgrOfPHC','PerAsReporterOfPHC',
'PhysicianOfPHC')` AND `RECORD_STATUS_CD='ACTIVE'`, populating
F_PAGE_CASE.PROVIDERNAME / PROVIDERPHONE (from PhysicianOfPHC) and
INVESTIGATORNAME / INVESTIGATORPHONE / INVESTIGATORASSIGNEDDATE (from
InvestgrOfPHC). Detail: `coverage/coverage_physician_phc.md`.

Note on `nrt_investigation.investigator_id` and `physician_id`:
spot-checked post-edge, both remain NULL. The investigation_event SP
at line 848 projects `par2.from_time` as `investigator_assigned_datetime`
ONLY (it does NOT project the subject_entity_uid as `investigator_id`).
The `investigator_id` and `physician_id` columns on `nrt_investigation`
are hand-authored staging columns; no SP derives them from the
InvestgrOfPHC / PhysicianOfPHC participation rows. PhysicianOfPHC is
not read by the investigation_event SP at all (verified by zero
matches for 'PhysicianOfPHC' in 056-sp_investigation_event-001.sql).
Documented as OUT_OF_SCOPE in the coverage report.

### Tier 2: `SubOfVacc` + `PerformerOfVacc` edges (21007000 - 21007999)

Allocated by the Tier 2 vaccination_links fixture. Source:
`fixtures/20_links/vaccination_links.sql`. Coverage report:
`coverage/coverage_vaccination_links.md`.

The fixture authors **4 rows** in `nbs_odse.dbo.nbs_act_entity`
(2 SubOfVacc + 2 PerformerOfVacc):

SubOfVacc (`type_cd='SubOfVacc'`, act endpoint=Intervention/INTV,
entity endpoint=Person/PAT, Patient):

1. (21007000) foundation Vaccination (act_uid 20000160) ← foundation Patient (entity_uid 20000000)
2. (21007001) v2 Vaccination         (act_uid 20110010) ← v2 Patient         (entity_uid 20020010)

PerformerOfVacc (`type_cd='PerformerOfVacc'`, act endpoint=Intervention/INTV,
entity endpoint=Person/PSN, Provider):

3. (21007002) foundation Vaccination (act_uid 20000160) ← foundation Provider (entity_uid 20000010)
4. (21007003) v2 Vaccination         (act_uid 20110010) ← v2 Provider         (entity_uid 20010010)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 21007000 | (SubOfVacc foundation) | `nbs_act_entity.nbs_act_entity_uid` | foundation Vacc → foundation Patient. |
| 21007001 | (SubOfVacc v2)         | `nbs_act_entity.nbs_act_entity_uid` | v2 Vacc → v2 Patient. |
| 21007002 | (PerformerOfVacc foundation) | `nbs_act_entity.nbs_act_entity_uid` | foundation Vacc → foundation Provider. |
| 21007003 | (PerformerOfVacc v2)         | `nbs_act_entity.nbs_act_entity_uid` | v2 Vacc → v2 Provider. |

`nbs_act_entity` has a surrogate UID column
(`nbs_act_entity_uid bigint NOT NULL IDENTITY`). Unlike all 7 prior
Tier 2 edge fixtures, which used composite-PK tables (participation,
act_relationship), this fixture allocates 4 surrogate UIDs from its
block. The fixture wraps the INSERT in
`SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` to insert
explicit UIDs (the IDENTITY column otherwise auto-allocates).

Unused UIDs: 21007004-21007999 (996 UIDs reserved). Do not allocate
from this range outside of the vaccination_links edge fixture. Reserved
for future amendments such as: PerformerOfVacc-to-Organization
edges (`type_cd='PerformerOfVacc'` with subject_class_cd='ORG' per
catalog row), or v3 Vaccination variants.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_vaccination_event` only.

Honest coverage assessment: **this is the FIRST Tier 2 edge that
genuinely unblocks an event SP at Tier 1 isolation**. The Vaccination
event SP (`071-sp_vaccination_event-001.sql:108`) filters
`NBS_ACT_ENTITY.TYPE_CD='SubOfVacc'` as an INNER predicate in its main
FROM clause: pre-edge it returns 0 rows; post-edge it returns 2 rows
(one per vaccination UID), with PATIENT_UID and PROVIDER_UID JSON
fields populated. **0 RDB_MODERN dim/fact column unlocks at Tier 1
isolation** (the postprocessing SPs read `nrt_vaccination` directly,
not `nbs_act_entity`); D_VACCINATION (3 rows, 21/21 columns) and
F_VACCINATION (2 rows, 6/6 columns) are byte-identical pre/post-edge.
Detail: `coverage/coverage_vaccination_links.md`.

The `PerformerOfVacc`-to-Organization variant (catalog row notes
"Person (provider) or Organization") is NOT authored here; it is
skipped for v1 unless SP coverage demonstrably needs it. Result:
post-edge ORGANIZATION_UID JSON field projects as
NULL on both vaccination rows. A future amendment within this block
can add a 5th row pointing to `entity_uid=20000020` (foundation
Organization) if Organization-performer event-SP-projection coverage
is needed.

The `act_relationship type_cd='1180'` VaccinationToPHC edge (used at
event SP line 1167 to project PHC_UID) is a separate Tier 2
deliverable, not covered by this fixture. Currently PHC_UID projects as
NULL post-edge for both vaccination rows.

### Tier 2: `IntrvwerOfInterview` + `IntrvweeOfInterview` + `OrgAsSiteOfIntv` edges (21008000 - 21008999)

Allocated by the Tier 2 interview_links fixture. Source:
`fixtures/20_links/interview_links.sql`. Coverage report:
`coverage/coverage_interview_links.md`.

The fixture authors **6 rows** in `nbs_odse.dbo.nbs_act_entity`
(2 IntrvwerOfInterview + 2 IntrvweeOfInterview + 2 OrgAsSiteOfIntv):

IntrvwerOfInterview (`type_cd='IntrvwerOfInterview'`, act endpoint=
Interview, entity endpoint=Person/PSN, Provider as interviewer):

1. (21008000) foundation Interview (act_uid 20000140) ← foundation Provider (entity_uid 20000010)
2. (21008001) v2 Interview         (act_uid 20090010) ← v2 Provider         (entity_uid 20010010)

IntrvweeOfInterview (`type_cd='IntrvweeOfInterview'`, act endpoint=
Interview, entity endpoint=Person/PSN, Patient as interviewee):

3. (21008002) foundation Interview (act_uid 20000140) ← foundation Patient (entity_uid 20000000)
4. (21008003) v2 Interview         (act_uid 20090010) ← v2 Patient         (entity_uid 20020010)

OrgAsSiteOfIntv (`type_cd='OrgAsSiteOfIntv'`, act endpoint=Interview,
entity endpoint=Organization/ORG, Org as interview site):

5. (21008004) foundation Interview (act_uid 20000140) ← foundation Organization (entity_uid 20000020)
6. (21008005) v2 Interview         (act_uid 20090010) ← v2 Organization         (entity_uid 20030010)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 21008000 | (IntrvwerOfInterview foundation) | `nbs_act_entity.nbs_act_entity_uid` | foundation Interview → foundation Provider. |
| 21008001 | (IntrvwerOfInterview v2)         | `nbs_act_entity.nbs_act_entity_uid` | v2 Interview → v2 Provider. |
| 21008002 | (IntrvweeOfInterview foundation) | `nbs_act_entity.nbs_act_entity_uid` | foundation Interview → foundation Patient. |
| 21008003 | (IntrvweeOfInterview v2)         | `nbs_act_entity.nbs_act_entity_uid` | v2 Interview → v2 Patient. |
| 21008004 | (OrgAsSiteOfIntv foundation)     | `nbs_act_entity.nbs_act_entity_uid` | foundation Interview → foundation Organization. |
| 21008005 | (OrgAsSiteOfIntv v2)             | `nbs_act_entity.nbs_act_entity_uid` | v2 Interview → v2 Organization. |

`nbs_act_entity` has a surrogate UID column
(`nbs_act_entity_uid bigint NOT NULL IDENTITY`), the same pattern as the
sibling `vaccination_links` fixture (the eighth Tier 2 fixture, also
`nbs_act_entity`). The fixture wraps the INSERT in
`SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` to insert
explicit UIDs.

Unused UIDs: 21008006-21008999 (994 UIDs reserved). Do not allocate
from this range outside of the interview_links edge fixture. Reserved
for future amendments such as a v3 Interview variant's edges or
alternative interviewer/interviewee endpoints.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_interview_event` only.

Honest coverage assessment: **this edge is shape-consistency, NOT a
Tier 1-isolation RDB_MODERN-coverage unlock.** Unlike
`vaccination_links` (whose `SubOfVacc` INNER JOIN at
`071-sp_vaccination_event-001.sql:108` gates the entire SP and
returns 0 rows pre-edge), all three Interview event-SP joins are
**LEFT JOIN** (lines 87-95 of `065-sp_interview_event-001.sql`):

- `nae` for `IntrvwerOfInterview` (projects `PROVIDER_UID`).
- `nae2` for `OrgAsSiteOfIntv` (projects `ORGANIZATION_UID`).
- `nae3` for `IntrvweeOfInterview` (projects `PATIENT_UID`).

Pre-edge, `#INTERVIEW_INIT` projects PROVIDER_UID / ORGANIZATION_UID /
PATIENT_UID as NULL on every row (the LEFT JOINs returned no matching
nbs_act_entity rows). Post-edge, those JSON-projection columns
surface the wired entity_uids, but the postprocessing SPs
(`sp_d_interview_postprocessing`,
`sp_f_interview_case_postprocessing`) read from
`nrt_interview` / `nrt_interview_note` / `nrt_interview_answer`
directly and do NOT traverse `nbs_act_entity`. So `D_INTERVIEW`
(2 rows, 18/24 + 6 LDF OUT_OF_SCOPE), `D_INTERVIEW_NOTE` (2 rows,
7/7), and `F_INTERVIEW_CASE` (2 rows, 8/10) column populations are
**byte-identical pre/post-edge**. **0 RDB_MODERN dim/fact column
unlocks at Tier 1 isolation** (LEFT JOINs in event SP); the value of
this edge is in the datamart SPs the reporting-pipeline-service fires
during the CDC drain and the post-Kafka JSON projection in production. Detail:
`coverage/coverage_interview_links.md`.

The `act_relationship type_cd='IXS'` Interview→Investigation edge
(used at event SP lines 85-86 to project INVESTIGATION_UID) is a
separate Tier 2 deliverable (`IXS` is `MISSING_FROM_SRTE` per
Phase B's catalog), not covered by this fixture. Currently
INVESTIGATION_UID projects as NULL post-edge for both Interview rows.

### Tier 2: `PerAsReporterOfPHC` + `OrgAsReporterOfPHC` + `HospOfADT` edges (21009000 - 21009999)

Allocated by the Tier 2 phc_roles_nae fixture (the tenth Tier 2 edge
fixture). Source: `fixtures/20_links/phc_roles_nae.sql`. Coverage report:
`coverage/coverage_phc_roles_nae.md`.

The fixture authors **6 rows** in `nbs_odse.dbo.nbs_act_entity`
(2 PerAsReporterOfPHC + 2 OrgAsReporterOfPHC + 2 HospOfADT). This is
the THIRD `nbs_act_entity` Tier 2 edge fixture (after `vaccination_links`
21007000-21007999 and `interview_links` 21008000-21008999), same
`SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` wrap pattern.

PerAsReporterOfPHC (`type_cd='PerAsReporterOfPHC'`, act endpoint=Public
Health Case/CASE, entity endpoint=Person/PSN, Provider as
person-reporter):

1. (21009000) foundation Investigation (act_uid 20000100) → foundation Provider (entity_uid 20000010)
2. (21009001) v2 Investigation         (act_uid 20050010) → v2 Provider         (entity_uid 20010010)

OrgAsReporterOfPHC (`type_cd='OrgAsReporterOfPHC'`, act endpoint=CASE,
entity endpoint=Organization/ORG, Org as reporting source):

3. (21009002) foundation Investigation (act_uid 20000100) → foundation Organization (entity_uid 20000020)
4. (21009003) v2 Investigation         (act_uid 20050010) → v2 Organization         (entity_uid 20030010)

HospOfADT (`type_cd='HospOfADT'`, act endpoint=CASE, entity endpoint=
Organization/ORG, Org as hospital of ADT):

5. (21009004) foundation Investigation (act_uid 20000100) → foundation Organization (entity_uid 20000020)
6. (21009005) v2 Investigation         (act_uid 20050010) → v2 Organization         (entity_uid 20030010)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 21009000 | (PerAsReporterOfPHC nae foundation) | `nbs_act_entity.nbs_act_entity_uid` | foundation Inv → foundation Provider. |
| 21009001 | (PerAsReporterOfPHC nae v2)         | `nbs_act_entity.nbs_act_entity_uid` | v2 Inv → v2 Provider. |
| 21009002 | (OrgAsReporterOfPHC nae foundation) | `nbs_act_entity.nbs_act_entity_uid` | foundation Inv → foundation Org. |
| 21009003 | (OrgAsReporterOfPHC nae v2)         | `nbs_act_entity.nbs_act_entity_uid` | v2 Inv → v2 Org. |
| 21009004 | (HospOfADT nae foundation)          | `nbs_act_entity.nbs_act_entity_uid` | foundation Inv → foundation Org. |
| 21009005 | (HospOfADT nae v2)                  | `nbs_act_entity.nbs_act_entity_uid` | v2 Inv → v2 Org. |

Same Org serves as both `OrgAsReporterOfPHC` and `HospOfADT` endpoints
for v1 simplification (one canonical Org variant per tier, common
in production data per the per-edge prompt).

Unused UIDs: 21009006-21009999 (994 UIDs reserved). Do not allocate
from this range outside of the phc_roles_nae edge fixture. Reserved
specifically for future Tier 3 expansion of the other 17 *OfPHC roles
in the same CASE-pivot subquery (lines 909-934 of
`056-sp_investigation_event-001.sql`): `OrgAsClinicOfPHC`,
`CASupervisorOfPHC`, `ClosureInvestgrOfPHC`,
`DispoFldFupInvestgrOfPHC`, `FldFupInvestgrOfPHC`, `FldFupProvOfPHC`,
`FldFupSupervisorOfPHC`, `InitFldFupInvestgrOfPHC`,
`InitFupInvestgrOfPHC`, `InitInterviewerOfPHC`, `InterviewerOfPHC`,
`SurvInvestgrOfPHC`, `FldFupFacilityOfPHC`, `OrgAsHospitalOfDelivery`,
`PerAsProviderOfDelivery`, `PerAsProviderOfOBGYN`,
`PerAsProvideroOfPediatrics` (all MISSING_FROM_SRTE per Phase B).
A single Tier 3 fixture can author all 17 deferred roles within this
block (e.g., 21009006-21009039 for 17 foundation rows + 21009040-
21009056 for 17 v2 rows = 34 rows).

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_investigation_event` only.

**Architectural distinction from `reporter_phc` (sixth Tier 2 fixture,
21005000-21005999):** The `reporter_phc` fixture authored 4
`participation` rows for `PerAsReporterOfPHC` + `OrgAsReporterOfPHC`
linking the same Provider/Organization/Investigation endpoints. THIS
fixture authors complementary `nbs_act_entity` rows for the same
endpoints (plus 2 additional `HospOfADT` rows that have no
participation cousin). Both are required for full coverage:

- `reporter_phc`'s participation rows feed:
  - `sp_investigation_event` `person_participations` /
    `organization_participations` JSON branches (event SP lines
    ~339-375).
  - `sp_public_health_case_fact_datamart_event/_update` filtered by
    `TYPE_CD IN ('OrgAsReporterOfPHC','InvestgrOfPHC',
    'PerAsReporterOfPHC','PhysicianOfPHC')` populating
    `F_PAGE_CASE.REPORTER_NAME / REPORTER_PHONE / ORGANIZATION_NAME`
    via the datamart SPs the service fires during the CDC drain.
- `phc_roles_nae`'s nbs_act_entity rows feed:
  - `sp_investigation_event` CASE-pivot subquery
    `investigation_act_entity` at lines 909-934, which projects
    `person_as_reporter_uid` (line 913), `hospital_uid` (line 914),
    `org_as_reporter_uid` (line 932) into the JSON output.
  - `F_PAGE_CASE` consumes `hospital_uid` downstream via the datamart
    SPs the service fires during the CDC drain (datamart-side; out of
    scope here).

The two tables (`participation` and `nbs_act_entity`) are different
connective tables in the ODSE schema; each row in one does NOT imply
a row in the other. Authoring in only one would leave half the
projection NULL. `coverage_reporter_phc.md`'s "Coverage still
LINK_REQUIRED" section explicitly defers the `nbs_act_entity` rows
to a separate Tier 2 fixture (this one).

Honest coverage assessment: **this edge is JSON-projection /
shape-consistency, NOT a Tier 1-isolation RDB_MODERN-coverage
unlock.** Like sibling `interview_links` (and unlike
`vaccination_links`'s INNER JOIN at vaccination event SP line 108),
the CASE-pivot subquery at `056-sp_investigation_event-001.sql:909`
joins `LEFT JOIN ... ON investigation_act_entity.nac_page_case_uid =
results.public_health_case_uid`, so `sp_investigation_event` returns
rows for both Investigations regardless of these edges. Pre-edge,
the projection columns `person_as_reporter_uid` / `hospital_uid` /
`org_as_reporter_uid` (and the 17 deferred Tier 3 `*_of_phc_uid`
columns) all project as NULL on every row. Post-edge, the 3 in-scope
columns surface the wired entity_uids:

- foundation Inv 20000100 → person_as_reporter=20000010,
  hospital=20000020, org_as_reporter=20000020.
- v2 Inv 20050010 → person_as_reporter=20010010,
  hospital=20030010, org_as_reporter=20030010.

**0 RDB_MODERN dim/fact column unlocks at Tier 1 isolation.** The
postprocessing SP (`sp_nrt_investigation_postprocessing`) reads
from `nrt_investigation` (hand-authored by Tier 1 Investigation) and
does NOT traverse `nbs_act_entity`. INVESTIGATION dimension column
populations are byte-identical pre/post-edge. Detail:
`coverage/coverage_phc_roles_nae.md`.

### Tier 2: `SiteOfExposure` + `InvestgrOfContact` + `DispoInvestgrOfConRec` edges (21010000 - 21010999)

Allocated by the Tier 2 contact_links fixture (the eleventh Tier 2 edge
fixture). Source: `fixtures/20_links/contact_links.sql`. Coverage report:
`coverage/coverage_contact_links.md`.

The fixture authors **6 rows** in `nbs_odse.dbo.nbs_act_entity`
(2 SiteOfExposure + 2 InvestgrOfContact + 2 DispoInvestgrOfConRec).
This is the FOURTH `nbs_act_entity` Tier 2 edge fixture (after
`vaccination_links` 21007000-21007999, `interview_links`
21008000-21008999, `phc_roles_nae` 21009000-21009999), same
`SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` wrap pattern.

All three `type_cd` values are MISSING_FROM_SRTE per Phase B
(`catalog/edge_types.md` rows 131-133 and 369-371). RTR's
`sp_contact_record_event` filters on the literal values directly at
lines 155-157 of `069-sp_contact_record_event-001.sql`.

SiteOfExposure (`type_cd='SiteOfExposure'`, act endpoint=Contact /
ct_contact (ENC), entity endpoint=Place, exposure site):

1. (21010000) foundation Contact (act_uid 20000170) → foundation Place (entity_uid 20000030)
2. (21010001) v2 Contact         (act_uid 20120010) → foundation Place (entity_uid 20000030) (no v2 Place; v1 simplification)

InvestgrOfContact (`type_cd='InvestgrOfContact'`, act endpoint=ENC,
entity endpoint=Person/PSN, Provider as investigator):

3. (21010002) foundation Contact (act_uid 20000170) → foundation Provider (entity_uid 20000010)
4. (21010003) v2 Contact         (act_uid 20120010) → v2 Provider         (entity_uid 20010010)

DispoInvestgrOfConRec (`type_cd='DispoInvestgrOfConRec'`, act endpoint=
ENC, entity endpoint=Person/PSN, Provider as disposition investigator;
same Provider as InvestgrOfContact for v1 simplification):

5. (21010004) foundation Contact (act_uid 20000170) → foundation Provider (entity_uid 20000010)
6. (21010005) v2 Contact         (act_uid 20120010) → v2 Provider         (entity_uid 20010010)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 21010000 | (SiteOfExposure nae foundation)        | `nbs_act_entity.nbs_act_entity_uid` | foundation Contact → foundation Place. |
| 21010001 | (SiteOfExposure nae v2)                | `nbs_act_entity.nbs_act_entity_uid` | v2 Contact → foundation Place (v1 simplification). |
| 21010002 | (InvestgrOfContact nae foundation)     | `nbs_act_entity.nbs_act_entity_uid` | foundation Contact → foundation Provider. |
| 21010003 | (InvestgrOfContact nae v2)             | `nbs_act_entity.nbs_act_entity_uid` | v2 Contact → v2 Provider. |
| 21010004 | (DispoInvestgrOfConRec nae foundation) | `nbs_act_entity.nbs_act_entity_uid` | foundation Contact → foundation Provider. |
| 21010005 | (DispoInvestgrOfConRec nae v2)         | `nbs_act_entity.nbs_act_entity_uid` | v2 Contact → v2 Provider. |

Unused UIDs: 21010006-21010999 (994 UIDs reserved). Do not allocate
from this range outside of the contact_links edge fixture.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The fixture has
**no tail-EXEC** because `sp_contact_record_event` is BROKEN
UPSTREAM in baseline 6.0.18.1; it references nonexistent
`nbs_odse.dbo.fn_get_value_by_cd_codeset` (the function actually lives
in `RDB_MODERN.dbo`). Verification is via direct `SELECT` against
`dbo.nbs_act_entity` (6 rows expected, 2 per `type_cd`).

Honest coverage assessment: **0 RDB_MODERN dim/fact column unlocks at
Tier 1 isolation OR in the merged sequence.** Both because the event
SP is broken upstream AND because the Contact postprocessing SPs
(`sp_d_contact_record_postprocessing`,
`sp_f_contact_record_case_postprocessing`) read soft-ref UIDs from
`nrt_contact` directly and do NOT traverse `nbs_act_entity`. Even when
the event SP bug is fixed upstream, the SP's only output is a JSON
projection (Kafka-consumed in production), not RDB_MODERN dim/fact
rows. The PRIMARY value of this edge is purely **shape-consistency**
for the eventual RDB-vs-RDB_MODERN comparison test against MasterETL
(which traverses `nbs_act_entity` to derive analogous Contact-
participant linkages on the RDB side). Detail:
`coverage/coverage_contact_links.md`.

### Tier 2: `IXS` Interview→Investigation edge (21011000 - 21011999)

Allocated by the Tier 2 interview_phc fixture (the twelfth Tier 2 edge
fixture). Source: `fixtures/20_links/interview_phc.sql`. Coverage report:
`coverage/coverage_interview_phc.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.act_relationship` with
`type_cd='IXS'`. This is the SECOND `act_relationship` Tier 2 edge
fixture (after `inv_notification` 21000000-21000999), same composite-PK
pattern (no surrogate UID needed; block reserved for future
amendments).

`type_cd='IXS'` is **MISSING from baseline `NBS_SRTE.dbo.code_value_general`
`code_set_nm='AR_TYPE'`** per Phase B (`catalog/edge_types.md` row 338):
found in `BUS_OBJ_TYPE` and `INFO_SOURCE_COVID` code sets but not in
`AR_TYPE`. RTR's `sp_interview_event` filters on the literal `IXS`
value at line 86 of `065-sp_interview_event-001.sql` regardless.

IXS (`type_cd='IXS'`, source_class_cd=`ENC` (Interview), target_class_cd=
`CASE` (Investigation)):

1. foundation Interview (act_uid 20000140) → foundation Investigation (act_uid 20000100)
2. v2 Interview         (act_uid 20090010) → v2 Investigation         (act_uid 20050010)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| n/a | (IXS act_rel foundation) | `act_relationship` composite PK | foundation Interview → foundation Investigation. No surrogate UID. |
| n/a | (IXS act_rel v2)         | `act_relationship` composite PK | v2 Interview → v2 Investigation. No surrogate UID. |

Unused UIDs: 21011000-21011999 (1000 UIDs reserved). Do not allocate
from this range outside of the interview_phc edge fixture.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_interview_event` only.

Honest coverage assessment: **0 RDB_MODERN dim/fact column unlocks at
Tier 1 isolation.** Like sibling `interview_links`, the join at lines
85-86 of `065-sp_interview_event-001.sql` is a `LEFT JOIN`, so
`sp_interview_event` returns rows regardless of this edge.
`D_INTERVIEW` (2 rows, 18/24 + 6 LDF OUT_OF_SCOPE), `D_INTERVIEW_NOTE`
(2 rows, 7/7), and `F_INTERVIEW_CASE` (2 rows, 8/10) populations are
byte-identical pre/post-edge. The postprocessing SPs read from
`nrt_interview*` (hand-authored by Tier 1) and do NOT traverse
`act_relationship`.

The PRIMARY value of this edge is **JSON-projection coverage**: the
event SP's `INVESTIGATION_UID` field flips from NULL (pre-edge) to the
wired `target_act_uid`s post-edge:

- foundation Interview row → `INVESTIGATION_UID = 20000100`
- v2 Interview row         → `INVESTIGATION_UID = 20050010`

Kafka consumers in production read this projection. Plus ODSE graph
correctness for the eventual RDB-vs-RDB_MODERN comparison test against
MasterETL. Detail: `coverage/coverage_interview_phc.md`.

This closes the JSON-projection gap that `coverage_interview_links.md`
flagged: post-`interview_links`, `INVESTIGATION_UID` was the only
remaining NULL field in the Interview event SP's JSON projection, now
populated by this edge.

## Tier 3: Gap-driven SP coverage (22000000 - 22099999)

*Allocations made by Tier 3 fixtures (only on reported gaps).*

| Range | Fixture | Status |
| --- | --- | --- |
| 22000000 - 22000999 | `multi_condition_investigations` (10 stubs, one per condition) | **allocated**. Stubs only, no investigations authored. TB / Varicella / Mumps / Pertussis / Measles / Rubella / COVID-19 / Syphilis / HIV / Strep pneumoniae each need a full ODSE condition chain (`act` + `public_health_case` + `nbs_case_answer`). |
| 22001000 - 22001999 | `tb_investigation_full_chain` (full ODSE + NBS_case_answer chain for TB) | **allocated**. See block detail below. |
| 22002000 - 22002999 | `varicella_investigation_full_chain` (full ODSE + NBS_case_answer chain for Varicella) | **allocated**. See block detail below. |
| 22003000 - 22003999 | `covid_investigation_full_chain` (full ODSE + NBS_case_answer chain for COVID-19) | **allocated**. See block detail below. |
| 22004000 - 22004999 | `std_hiv_investigation_full_chain` (full ODSE + Tier 2 + dimensional D_INV_* chain for STD Syphilis primary) | **allocated**. See block detail below. |
| 22005000 - 22005999 | `bmird_investigation_full_chain` (full ODSE + nrt_investigation_observation graph for BMIRD Strep pneumo invasive) | **allocated**. See block detail below. |
| 22006000 - 22006999 | `d_investigation_repeat` (full ODSE + nrt_page_case_answer repeating-block chain for Pertussis form) | **allocated**. See block detail below. |
| 22007000 - 22007999 | `zz_covid_case_datamart_enrich` (extra nrt_page_case_answer answers for existing COVID PHC 22003000 to lift COVID_CASE_DATAMART column coverage) | **reserved 2026-05-22**. |
| 22008000 - 22008999 | `zz_hepatitis_datamart_enrich` (full ODSE + answers chain for a Hep A Investigation to lift HEPATITIS_DATAMART column coverage) | **reserved 2026-05-22**. |
| 22009000 - 22009999 | `zz_var_datamart_enrich` (extra answers for existing Varicella PHC 22002000 to lift VAR_DATAMART column coverage beyond the curated 25-question set) | **reserved 2026-05-22**. |
| 22010000 - 22010999 | `zz_d_inv_place_repeat_enrich` (repeating-block place-of-exposure answers to populate D_INV_PLACE_REPEAT baseline columns) | **reserved 2026-05-22**. |
| 22011000 - 22011999 | `zz_tb_datamart_enrich` (extra TUB* answer rows for existing TB PHC 22001000 to lift TB_DATAMART / TB_HIV_DATAMART / D_TB_PAM column coverage) | **reserved 2026-05-24**. |
| 22012000 - 22012999 | `zz_std_hiv_datamart_enrich` (9 hand-authored D_INV_*/L_INV_* pairs + UPDATEs on existing D_INV_HIV / D_INV_EPI / D_CASE_MANAGEMENT / D_PATIENT / INV_HIV to lift STD_HIV_DATAMART column coverage on PHC 22004000) | **allocated 2026-05-24**. Used 22012100, 22012110, 22012120, 22012130, 22012140, 22012150, 22012160, 22012170, 22012180. |
| 22013000 - 22013999 | `zz_bmird_strep_pneumo_datamart_enrich` (extra answers / observation rows for existing BMIRD PHC 22005000 to lift BMIRD_STREP_PNEUMO_DATAMART column coverage) | **reserved 2026-05-24**. |
| 22014000 - 22014999 | `zz_d_investigation_repeat_more_blocks` (more repeating-block answer-row variants on PHC 22006000 across additional BLOCK_NM × seq combinations to lift D_INVESTIGATION_REPEAT row count and column coverage) | **reserved 2026-05-24**. |
| 22015000 - 22015999 | `zz_morbidity_report_datamart_enrich`: direct RDB_MODERN INSERTs of MORBIDITY_REPORT (22015000) + MORBIDITY_REPORT_EVENT + D_PATIENT (22015100, PATIENT_UID reuses Variant Marie 20020010 for orch pickup) + D_PROVIDER (22015110/111) + D_ORGANIZATION (22015120/121) + INVESTIGATION (22015200) + EVENT_METRIC + 3 LAB_TEST Result rows (22015300-22015302) with TEST_RESULT_GROUPING / RESULT_COMMENT_GROUP parents + LAB_TEST_RESULT + LAB_RESULT_VAL (22015500-22015502) + LAB_RESULT_COMMENT (22015700-22015702 / GRP 22015600-22015602) + 3 TREATMENT + TREATMENT_EVENT (22015400-22015402). Lifts MORBIDITY_REPORT_DATAMART from 86/133 → 133/133. | **allocated 2026-05-24**. Used: 22015000, 22015100, 22015110, 22015111, 22015120, 22015121, 22015200, 22015300-22015302, 22015400-22015402, 22015500-22015502, 22015600-22015602, 22015700-22015702, 22015800-22015802. |
| 22016000 - 22016999 | `zz_hep100_unblock` (direct INSERT into HEPATITIS_CASE for hep PHC 22008500 to unblock hep100 datamart, ~187 cols) | **allocated 2026-05-24**. |
| 22017000 - 22017999 | `zz_case_lab_datamart_enrich` (case-lab linkage rows so sp_case_lab_datamart_postprocessing populates more cols, ~26 cols) | **allocated 2026-05-24**. |
| 22018000 - 22018999 | `zz_covid_contact_datamart_enrich` (more nrt_page_case_answer rows for COVID contact PHC to lift COVID_CONTACT_DATAMART column coverage from 71/94) | **allocated 2026-05-24**. |
| 22019000 - 22019999 | `zz_ldf_flagged_answers` (LDF-flagged nrt_page_case_answer rows across TB/VAR/BMIRD/Hep/Mumps PHCs to unblock *_pam_ldf + ldf_bmird/mumps/hepatitis + *_ldf_group tables) | **allocated 2026-05-24**. |
| 22020000 - 22020999 | `zz_covid_vaccination_datamart_enrich` (new Patient with full demographics + COVID vaccination intervention linkage to lift covid_vaccination_datamart from 10/60) | **allocated 2026-05-24**. |
| 22021000 - 22021999 | `zz_lab100_enrich` (additional Result-type LAB_TEST rows + LAB_TEST_RESULT to extend lab100 col coverage beyond initial 22/69) | **allocated 2026-05-24**. |
| 22022000 - 22022999 | `zz_covid_lab_datamart_unblock` (COVID-coded lab observations linked to existing COVID PHC 22003000 to unblock covid_lab_datamart from 0/129) | **allocated 2026-05-24**. |
| 22023000 - 22023999 | `zz_hepatitis_datamart_round2` (fill the 69 remaining unpopulated cols on hepatitis_datamart via Tier-2-style participation rows + dim enrichment) | **allocated 2026-05-24**. |
| 22024000 - 22024999 | `zz_covid_case_datamart_round2` **superseded** by `sr100` (Round 3). | **re-allocated 2026-06-02** to `fixtures/30_sp_coverage/sr100.sql`, per the Round-3 reservation table below. The covid round-2 fixture wrote 0 ODSE rows in this block (verified empty in baseline-merged DB). Used by sr100: 22024000 (PHC), 22024100/101/102 (SUM103/104/105 obs). See block detail below. |
| 22025000 - 22025999 | `zz_inv_summ_datamart_unblock` (unblock inv_summ_datamart 0/58; investigate the WHERE-clause requiring pre-existing rows from round 1) | **allocated 2026-05-24**. |
| 22026000 - 22026999 | `zz_covid_lab_celr_datamart_unblock` (unblock covid_lab_celr_datamart 0/101; sibling of covid_lab_datamart with same SP pattern) | **allocated 2026-05-24**. |
| 22027000 - 22027999 | `zz_d_contact_record_enrich` (more answer rows / dim attrs on existing contact PHCs to lift d_contact_record from 42/66) | **allocated 2026-05-24**. NOTE: this file inserts NO 22027xxx rows; it only enriches existing contact PHCs (the block is referenced only in a header comment). Sub-range 22027000-22027099 carved out below. |
| 22027000 - 22027099 | `zz_tb_datamart_enrich_r3` (fill the 41 residual NULL TB_DATAMART columns sourced from dims/staging, not page-case answers: user_profile, confirmation_method[_group], nrt_investigation_notification, F_TB_PAM key repoint, D_PATIENT/INVESTIGATION/nrt_investigation attr fill, OUTBREAK_NM code) | **allocated 2026-06-02**. Carved from the unused 22027 block (nothing else inserts there). Used: confirmation_method 22027000-002, nrt_investigation_notification 22027010. |
| 22028000 - 22028999 | `zz_d_investigation_repeat_round3` (more block-NM coverage via a NEW PHC (not 22006000 to avoid bug #13 TEXT pivot pollution) to lift d_investigation_repeat from 106/256) | **allocated 2026-05-24**. |

### Tier 3: TB Investigation full chain (22001000 - 22001999)

Allocated by the Tier 3 tb_investigation_full_chain fixture. Source:
`fixtures/30_sp_coverage/tb_investigation_full_chain.sql`. Coverage
report: `coverage/coverage_tb_full_chain.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22001000 | tb_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (all 23 answer rows) | The single TB Investigation full-chain anchor. condition_cd `10220` Tuberculosis, prog_area_cd `TB`, investigation_form_cd `INV_FORM_RVCT`. Adds the populated-PAM-answers path alongside the existing 22000010 stub's no-answers path. |
| 22001001 | tb_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22001100..22001112 | (13 d_topic feeders) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per excluded-from-TB-PAM-pivot TUB question (TUB119, TUB129, TUB154, TUB155, TUB156, TUB167, TUB225, TUB228, TUB229, TUB230, TUB235, TUB237, TUB114). |
| 22001113..22001122 | (10 D_TB_PAM main-pivot feeders) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | A curated 10-question minimum-viable set proving the wide D_TB_PAM pivot path works end-to-end. The remaining ~150 TUB questions are deferred to fixture-completeness Phase 2. |

Unused UIDs: 22001002..22001099, 22001123..22001999 (978 UIDs reserved). Do not allocate
from this range outside of the tb_investigation_full_chain fixture.

This fixture writes:
- 1 row to `NBS_ODSE.dbo.act` (act_uid=22001000)
- 1 row to `NBS_ODSE.dbo.public_health_case` (public_health_case_uid=22001000)
- 1 row to `NBS_ODSE.dbo.act_id` (act_uid=22001000, act_id_seq=1)
- 1 row to `NBS_ODSE.dbo.case_management` (case_management_uid=22001001, IDENTITY_INSERT)
- 13 rows to `NBS_ODSE.dbo.nbs_case_answer` (act_uid=22001000)
- 1 row to `RDB_MODERN.dbo.nrt_investigation` (public_health_case_uid=22001000)
- 23 rows to `RDB_MODERN.dbo.nrt_page_case_answer` (act_uid=22001000)

It populates **24 of 26** TB-PAM cluster RDB_MODERN tables (every
d_topic dim + group + D_TB_PAM + F_TB_PAM + TB_DATAMART + TB_HIV_DATAMART).
The 2 remaining (`TB_PAM_LDF`, plus the per-topic-empty group sentinel)
require separate LDF-flagged answer rows (Phase 2 LDF work).

### Tier 3: Varicella Investigation full chain (22002000 - 22002999)

Allocated by the Tier 3 varicella_investigation_full_chain fixture. Source:
`fixtures/30_sp_coverage/varicella_investigation_full_chain.sql`.
Coverage report: `coverage/coverage_varicella_full_chain.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22002000 | var_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (all 25 answer rows) | The single Varicella Investigation full-chain anchor. condition_cd `10030` Varicella (Chickenpox), prog_area_cd `GCD`, investigation_form_cd `INV_FORM_VAR`. Adds the populated-PAM-answers path alongside the existing 22000020 stub's no-answers path. |
| 22002001 | var_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22002100..22002124 | (25 VAR answer rows: VAR101, VAR103, VAR105, VAR111, VAR113, VAR122, VAR123, VAR126, VAR128, VAR129, VAR135, VAR139, VAR143, VAR150, VAR154, VAR156, VAR158, VAR170, VAR171, VAR174, VAR176, VAR178, VAR180, VAR188, VAR195) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | A curated minimum-viable set proving the D_VAR_PAM wide-pivot + D_RASH_LOC_GEN (VAR105 → 'Trunk') + D_PCR_SOURCE (VAR176 → 'Scab') paths work end-to-end. |

Unused UIDs: 22002002..22002099, 22002125..22002999 (974 UIDs reserved).
Do not allocate from this range outside of the
varicella_investigation_full_chain fixture.

This fixture writes:
- 1 row to `NBS_ODSE.dbo.act` (act_uid=22002000)
- 1 row to `NBS_ODSE.dbo.public_health_case` (public_health_case_uid=22002000)
- 1 row to `NBS_ODSE.dbo.act_id` (act_uid=22002000, act_id_seq=1)
- 1 row to `NBS_ODSE.dbo.case_management` (case_management_uid=22002001, IDENTITY_INSERT)
- 25 rows to `NBS_ODSE.dbo.nbs_case_answer` (act_uid=22002000)
- 1 row to `RDB_MODERN.dbo.nrt_investigation` (public_health_case_uid=22002000)
- 25 rows to `RDB_MODERN.dbo.nrt_page_case_answer` (act_uid=22002000)

It populates **5 of 8** Varicella-PAM cluster RDB_MODERN tables at
Tier-1-isolation (D_VAR_PAM, D_RASH_LOC_GEN(+group), D_PCR_SOURCE(+group)).
F_VAR_PAM and VAR_DATAMART populate via the datamart SPs the
reporting-pipeline-service fires during the CDC drain plus the
deterministic `run_summary_datamarts` pass (gated on EVENT_METRIC for
var_datamart); the `PHC_UIDS` list in `run_summary_datamarts` must
include 22002000 (see
`coverage/coverage_varicella_full_chain.md` ORCH_TODO section).
VAR_PAM_LDF remains 0 (requires LDF-flagged answer rows, Phase 2 LDF
work).

### Tier 3: COVID-19 Investigation full chain (22003000 - 22003999)

Allocated by the Tier 3 covid_investigation_full_chain fixture. Source:
`fixtures/30_sp_coverage/covid_investigation_full_chain.sql`. Coverage
report: `coverage/coverage_covid_full_chain.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22003000 | covid_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (all 22 answer rows) | The single COVID Investigation full-chain anchor. condition_cd `11065` 2019 Novel Coronavirus, prog_area_cd `COV` (matching the stub convention; SRTE canonical is `GCD`, see coverage report SRTE_GAP), investigation_form_cd `PG_COVID-19_v1.1`. Adds the discrete + Type-3 repeating-block answers path alongside the existing 22000070 stub's no-answers path. |
| 22003001 | covid_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22003100..22003121 | (22 nbs_case_answer + nrt_page_case_answer pairs) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per COVID datamart-column-mapped question: 9 symptoms (FEVER, CHILLS_RIGORS, FATIGUE_MALAISE, HEADACHE, MYALGIA, ALT_MENTAL_STATUS, NAUSEA, DIARRHEA, ABDOMINAL_PAIN, all SNOMED-coded), 2 disposition (HOSPITAL_ICU_STAY, US_HC_WORKER_IND), 6 exposure (TRAVEL_DOMESTICALLY, TRAVEL_INTERNATIONAL, CRUISE_TRAVEL_EXP, AIR_TRAVEL_EXP, WORKPLACE_EXP, ANIMAL_EXPOSURE_IND), 3 Type-3 labs (TEST_TYPE, TEST_RESULT, PERFORMING_LAB_TYPE with `answer_group_seq_nbr='1'` → `_1` repeating-block columns), 2 comorbidity/status (HYPERTENSION, Symptomatic). |

Unused UIDs: 22003002..22003099, 22003122..22003999 (978 UIDs
reserved). Do not allocate from this range outside of the
covid_investigation_full_chain fixture.

This fixture writes:
- 1 row to `NBS_ODSE.dbo.act` (act_uid=22003000)
- 1 row to `NBS_ODSE.dbo.public_health_case` (public_health_case_uid=22003000)
- 1 row to `NBS_ODSE.dbo.act_id` (act_uid=22003000, act_id_seq=1)
- 1 row to `NBS_ODSE.dbo.case_management` (case_management_uid=22003001, IDENTITY_INSERT)
- 22 rows to `NBS_ODSE.dbo.nbs_case_answer` (act_uid=22003000)
- 1 row to `RDB_MODERN.dbo.nrt_investigation` (public_health_case_uid=22003000)
- 22 rows to `RDB_MODERN.dbo.nrt_page_case_answer` (act_uid=22003000)

It populates **1 of 5** COVID datamart tables (COVID_CASE_DATAMART
with 53/383 columns non-NULL, up from 28 with the stub alone). The 4
remaining (COVID_CONTACT_DATAMART, COVID_LAB_DATAMART,
COVID_LAB_CELR_DATAMART, COVID_VACCINATION_DATAMART) require
additional Tier 3 inputs (COVID-coded labs / vaccinations / contacts
linked to the Investigation) as Phase 2 follow-on.

**Orchestrator pending action**: add 22003000 to the `PHC_UIDS` list in
`run_summary_datamarts` (`scripts/merge_and_verify.sh`) so the
deterministic datamart pass picks up this Investigation for
`sp_covid_case_datamart_postprocessing`. (The reporting-pipeline-service
also fires the datamart SPs off CDC events during the drain; the
`PHC_UIDS` pass is the deterministic post-drain re-run over the full PHC
list.)

### Tier 3: STD Syphilis Investigation full chain (22004000 - 22004999)

Allocated by the Tier 3 std_hiv_investigation_full_chain fixture. Source:
`fixtures/30_sp_coverage/std_hiv_investigation_full_chain.sql`. Coverage
report: `coverage/coverage_std_hiv_full_chain.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22004000 | std_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation_case_management.public_health_case_uid`, `nrt_investigation_confirmation.public_health_case_uid`, `L_INV_*.PAGE_CASE_UID` (5 link rows) | The single STD Syphilis-primary full-chain anchor. condition_cd `10311` Syphilis, primary; prog_area_cd `STD`; investigation_form_cd `PG_STD_Investigation` (the FORM_CD that v_nrt_nbs_page maps to DATAMART_NM='STD' for the dyn_dm chain). Adds the populated-CASE_MANAGEMENT + populated-D_INV_* path alongside the existing 22000080 Syphilis stub's no-CASE_MANAGEMENT path. |
| 22004001 | std_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. Required so the f_std_page_case SP's INNER predicate at line 97 (`nicm.CASE_MANAGEMENT_UID is not null`) admits this PHC row. |
| 22004100 | D_INV_HIV_KEY | `D_INV_HIV.D_INV_HIV_KEY` | Hand-authored dimension row; populates 16/22 HIV_* columns. |
| 22004110 | D_INV_ADMINISTRATIVE_KEY | `D_INV_ADMINISTRATIVE.D_INV_ADMINISTRATIVE_KEY` | Populates 4/58 ADM_* columns. |
| 22004120 | D_INV_CLINICAL_KEY | `D_INV_CLINICAL.D_INV_CLINICAL_KEY` | Populates 7/93 CLN_* columns. |
| 22004130 | D_INV_EPIDEMIOLOGY_KEY | `D_INV_EPIDEMIOLOGY.D_INV_EPIDEMIOLOGY_KEY` | Populates 1/154 EPI_* columns (EPI_CNTRY_USUAL_RESID). |
| 22004140 | D_INV_COMPLICATION_KEY | `D_INV_COMPLICATION.D_INV_COMPLICATION_KEY` | Populates 2/33 CMP_* columns. |

Unused UIDs: 22004002..22004099, 22004101..22004109, 22004111..22004119,
22004121..22004129, 22004131..22004139, 22004141..22004999 (~960 UIDs
reserved). Do not allocate from this range outside of the
std_hiv_investigation_full_chain fixture. Reserved for future expansion:
broader D_INV_* column coverage; sibling HIV-pediatric full-chain
(condition 10561, currently stubbed at 22000090); congenital syphilis
(condition 10316, PG_Congenital_Syphilis_Investigation, a separate
form, not part of STD_HIV_GROUP coinfection_grp_cd).

This fixture writes:
- 1 row to `NBS_ODSE.dbo.act` (act_uid=22004000)
- 1 row to `NBS_ODSE.dbo.public_health_case` (public_health_case_uid=22004000)
- 1 row to `NBS_ODSE.dbo.act_id` (act_uid=22004000, act_id_seq=1)
- 1 row to `NBS_ODSE.dbo.case_management` (case_management_uid=22004001, IDENTITY_INSERT)
- 1 row to `RDB_MODERN.dbo.nrt_investigation` (public_health_case_uid=22004000)
- 1 row to `RDB_MODERN.dbo.nrt_investigation_case_management` (public_health_case_uid=22004000)
- 1 row to `RDB_MODERN.dbo.nrt_investigation_confirmation` (public_health_case_uid=22004000)
- 1 row each to `RDB_MODERN.dbo.D_INV_HIV / D_INV_ADMINISTRATIVE / D_INV_CLINICAL / D_INV_EPIDEMIOLOGY / D_INV_COMPLICATION`
- 1 row each to `RDB_MODERN.dbo.L_INV_HIV / L_INV_ADMINISTRATIVE / L_INV_CLINICAL / L_INV_EPIDEMIOLOGY / L_INV_COMPLICATION`

After this fixture applies, the chain unblocks (verified live 2026-05-21):
- `INVESTIGATION` +1 row
- `CONFIRMATION_METHOD_GROUP` +1 row (via sp_nrt_investigation_postprocessing's
  DELETE-then-INSERT cycle reading nrt_investigation_confirmation)
- `F_STD_PAGE_CASE` +1 row (after the service fires
  `sp_f_std_page_case_postprocessing` during the CDC drain)
- `INV_HIV` +1 row
- `STD_HIV_DATAMART` +1 row (after the service fires
  `sp_std_hiv_datamart_postprocessing` during the CDC drain)

**Orchestrator pending actions** (Phase 2 follow-on, NOT this fixture's
responsibility):
1. Add 22004000 to the `PHC_UIDS` list in `run_summary_datamarts`
   (`scripts/merge_and_verify.sh`) so the deterministic datamart pass
   picks up this Investigation for `sp_std_hiv_datamart_postprocessing`,
   `sp_f_std_page_case_postprocessing`, and the dyn_dm STD chain. (The
   service also fires these off CDC events during the drain.)
2. Fix orchestrator bug at line 475: `sp_f_std_page_case_postprocessing`
   is invoked with `@phc_ids = N'...'` while the SP's actual parameter is
   `@phc_id_list`. The 2>/dev/null masks the silent failure; the SP
   never runs in the orchestrated path. See report deliverable for
   detail.

### Tier 3: BMIRD (Strep pneumo) Investigation full chain (22005000 - 22005999)

Allocated by the Tier 3 bmird_investigation_full_chain fixture. Source:
`fixtures/30_sp_coverage/bmird_investigation_full_chain.sql`. Coverage
report: `coverage/coverage_bmird_full_chain.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22005000 | bmird_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_investigation_observation.public_health_case_uid` (all 24 observation rows) | The single BMIRD Strep pneumoniae invasive full-chain anchor. condition_cd `11717`, prog_area_cd `BMIRD`, investigation_form_cd `INV_FORM_BMDSP`. Adds the populated-BMD-answers path alongside the existing 22000100 stub's no-answers path. |
| 22005001 | bmird_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22005100..22005112 | (13 BMIRD_Case coded feeders) | `nrt_observation.observation_uid` + `nrt_investigation_observation.branch_id` + `nrt_observation_coded.observation_uid` | One per BMD coded question (BMD120 BACTERIAL_SPECIES_ISOLATED → '11717', BMD100 ABCCASE → 'Y', BMD137 OXACILLIN_INTERPRETATION → 'R', BMD138 PNEUVACC_RECEIVED_IND → 'Y', BMD131 CULTURE_SEROTYPE → '19A', etc.). |
| 22005120..22005123 | (4 BMIRD_Case text feeders) | `nrt_observation.observation_uid` + `nrt_observation_txt.observation_uid` | One per BMD text question (BMD119 TYPES_OF_OTHER_INFECTION, BMD123 STERILE_SITE_OTHER, BMD298 OTHNONSTER, BMD299 OTHSEROTYPE). |
| 22005130 | (1 BMIRD_Case numeric feeder) | `nrt_observation.observation_uid` + `nrt_observation_numeric.observation_uid` | BMD136 OXACILLIN_ZONE_SIZE → 22 mm. |
| 22005140..22005141 | (2 BMIRD_Case date feeders) | `nrt_observation.observation_uid` + `nrt_observation_date.observation_uid` | BMD141 FIRST_ADDITIONAL_SPECIMEN_DT, BMD143 SECOND_ADDITIONAL_SPECIMEN_DT. |
| 22005150..22005153 | (4 BMIRD_Multi_Value_field feeders) | `nrt_observation.observation_uid` + `nrt_observation_coded.observation_uid` | One per BMD multi-value question routed by `nrt_srte_IMRDBMapping.RDB_table='BMIRD_Multi_Value_field'` (BMD118 TYPES_OF_INFECTIONS → 'BACTEREM' → 'Bacteremia without focus', BMD127 UNDERLYING_CONDITION_NM → 'DM' → 'Diabetes Mellitus', BMD125 NON_STERILE_SITE → 'SINUS', BMD142 STREP_PNEUMO_1_CULTURE_SITES → 'BLOOD'). |

Unused UIDs: 22005002..22005099, 22005113..22005119, 22005124..22005129,
22005131..22005139, 22005142..22005149, 22005154..22005999 (961 UIDs
reserved). Do not allocate from this range outside of the
bmird_investigation_full_chain fixture. Reserved for: more BMD/INV
question rows to broaden BMIRD_Case column coverage; Antimicrobial
batch-entry observations to populate ANTIMICROBIAL columns +
ANTIMICROBIAL_AGENT_TESTED_1..8 pivot columns; LDF_BMIRD via
LDF_DIMENSIONAL_DATA seed rows.

This fixture writes:
- 1 row to `NBS_ODSE.dbo.act` (act_uid=22005000)
- 1 row to `NBS_ODSE.dbo.public_health_case` (public_health_case_uid=22005000)
- 1 row to `NBS_ODSE.dbo.act_id` (act_uid=22005000, act_id_seq=1)
- 1 row to `NBS_ODSE.dbo.case_management` (case_management_uid=22005001, IDENTITY_INSERT)
- 1 row to `RDB_MODERN.dbo.nrt_investigation` (public_health_case_uid=22005000)
- 24 rows to `RDB_MODERN.dbo.nrt_observation` (observation_uid 22005100-22005153)
- 24 rows to `RDB_MODERN.dbo.nrt_investigation_observation` (linking each to PHC)
- 17 rows to `RDB_MODERN.dbo.nrt_observation_coded`
- 4 rows to `RDB_MODERN.dbo.nrt_observation_txt`
- 1 row to `RDB_MODERN.dbo.nrt_observation_numeric`
- 2 rows to `RDB_MODERN.dbo.nrt_observation_date`
- 1 sentinel seed to `RDB_MODERN.dbo.LDF_GROUP` (KEY=1, idempotent IF NOT EXISTS),
  required by BMIRD_Case FK on LDF_GROUP_KEY.

It populates **3 of 5** BMIRD-cluster RDB_MODERN tables (BMIRD_Case +
BMIRD_STREP_PNEUMO_DATAMART + BMIRD_MULTI_VALUE_FIELD). The 2
remaining (`ANTIMICROBIAL`, `LDF_BMIRD`) require additional fixture
work: Antimicrobial needs root-observation + branch_id structure for
batch-entry observations (out of scope for v1; reserve 22005200-22005299
UID range); LDF_BMIRD needs LDF_DIMENSIONAL_DATA seed rows.

**Orchestrator integration** (applied alongside this fixture):
1. Add 22005000 to the `PHC_UIDS` list in `run_summary_datamarts`
   (`scripts/merge_and_verify.sh`) so the deterministic datamart pass
   picks up this Investigation for `sp_bmird_case_datamart_postprocessing`,
   `sp_bmird_strep_pneumo_datamart_postprocessing`, and
   `sp_ldf_bmird_datamart_postprocessing`. (The service also fires these
   off CDC events during the drain.) **Done in same commit.**

### Tier 3: d_investigation_repeat full chain (22006000 - 22006999)

Allocated by the Tier 3 d_investigation_repeat fixture. Source:
`fixtures/30_sp_coverage/d_investigation_repeat.sql`. Coverage
report: `coverage/coverage_d_investigation_repeat.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22006000 | inv_rept_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (all 24 answer rows) | The single Pertussis-form Investigation full-chain anchor for `sp_sld_investigation_repeat_postprocessing`. condition_cd `10190` Pertussis, prog_area_cd `VAC`, investigation_form_cd `PG_Pertussis_Investigation`, which is NOT in the SP's form_cd exclusion list at line 84. Adds the populated-repeating-block path alongside the existing 22000040 Pertussis stub's no-answers path. |
| 22006001 | inv_rept_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22006100..22006123 | (24 nbs_case_answer + nrt_page_case_answer pairs) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per repeating-block answer. Layout: 2 BLOCK_NMs (TRAVEL_BLOCK, EXPOSURE_BLOCK) × 3 answer_group_seq_nbr values × 4 data types (TEXT, CODED, DATE, NUMERIC) = 24 rows. Each row carries a unique RDB_COLUMN_NM so the SP's dynamic ALTER TABLE loop widens D_INVESTIGATION_REPEAT by 8 new columns. Fictional `nbs_question_uid` values (22006001..22006014); the SP does not FK-validate against `nbs_question`. |

Unused UIDs: 22006002..22006099, 22006015..22006099, 22006124..22006999
(~975 UIDs reserved). Do not allocate from this range outside of the
d_investigation_repeat fixture. Reserved for: more BLOCK_NMs, more
answer_group_seq_nbr values (e.g., N=10 to exercise off-by-one logic in
pivots), additional data-type variants like DATETIME or PART.

This fixture writes:
- 1 row to `NBS_ODSE.dbo.act` (act_uid=22006000)
- 1 row to `NBS_ODSE.dbo.public_health_case` (public_health_case_uid=22006000)
- 1 row to `NBS_ODSE.dbo.act_id` (act_uid=22006000, act_id_seq=1)
- 1 row to `NBS_ODSE.dbo.case_management` (case_management_uid=22006001, IDENTITY_INSERT)
- 24 rows to `NBS_ODSE.dbo.nbs_case_answer` (act_uid=22006000)
- 1 row to `RDB_MODERN.dbo.nrt_investigation` (public_health_case_uid=22006000)
- 24 rows to `RDB_MODERN.dbo.nrt_page_case_answer` (act_uid=22006000)

After this fixture applies and the CDC drain processes it, the chain unblocks:
- `d_investigation_repeat`: 2 → 8 rows (+6 new dim rows; 1 PHC × 2 blocks × 3 seq) AND +8 dynamically-added RDB_COLUMN_NM columns (was 1/244, now ~11/252)
- `lookup_table_n_rept`: 0 → 1 row (was 0/2)
- `l_investigation_repeat_inc`: 0 → 6 rows (was 0/2)
- `l_investigation_repeat`: 1 → 7 rows (sentinel + 6 new)

**Wiring note**: there is no script step for this. The dim populates
during the CDC drain: the reporting-pipeline-service's
`processInvestigation` path calls `sp_page_builder_postprocessing` once
per table name in the investigation's `rdb_table_name_list`, and that SP
internally EXECs `sp_sld_investigation_repeat_postprocessing` when the
list contains `'D_INVESTIGATION_REPEAT'` (page-builder SP line 108). The
real dependency is therefore on the fixtures: a fixture-authored
Investigation's `nrt_investigation.rdb_table_name_list` must carry
`'D_INVESTIGATION_REPEAT'` so the page-builder path fires the repeat SP;
otherwise its repeating-block answers are silently dropped.
| 22007000-22007999 | Pertussis full chain | 30 observations (20 coded + 1 txt + 1 num + 7 date) attached to PHC 22007000 via nrt_investigation_observation 'InvFrmQ' edges. Mirrors BMIRD template. Net headline coverage: 0pp (PERTUSSIS_CASE not in rtr_target_columns.md scope) but populates out-of-scope PERTUSSIS_SUSPECTED_SOURCE_FLD and PERTUSSIS_TREATMENT_FIELD. |
| 22008000-22008999 | LDF Foodborne | New Salmonellosis (10470) Investigation. 5 nrt_ldf_data rows on this PHC + 5 more on Mumps stub (22000030). Unlocked ldf_foodborne (0/12 -> 11/12) and grew ldf_dimensional_data + ldf_group. ldf_mumps stayed empty (cause TBD). |
| 22029000-22029999 | LAB101 unblock (zz_lab101_unblock.sql) | I_Order/I_Result/'Result' 4-level lab hierarchy (22029300-22029302 keys / 22029400-22029402 UIDs) + root-order nrt_observation 22029500 + 35 coded child obs 22029600-22029634 (LAB329a..LAB363) + 35 LAB_RESULT_VAL 22029700-22029734 + I_Result-level LRV 22029699 + grouping 22029800/comment-group 22029801. Unblocks LAB101 0 -> 11/46 core cols; 35 EIP/NARMS/PFGE cols pend an SP step-3 (#tmp_ISOLATE_TRACKING_INIT) nuance. ORCH: the lab obs 22029401 is processed by the reporting-pipeline-service during the CDC drain (it runs the lab chain incl. lab100/101 datamart SPs off CDC events). |

### Tier 3: SR100 datamart (22024000 - 22024999)

Allocated by the Tier 3 SR100 fixture. Source:
`fixtures/30_sp_coverage/sr100.sql`. RTR bug addendum:
`bugs/15_event_metric_add_user_name_null/findings.md`.

Populates the empty `dbo.SR100` summary-report datamart (was 0/20 → 17/20).

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 22024000 | @sr100_phc_uid | Summary-type `nrt_investigation.public_health_case_uid` (case_type_cd='S') → INVESTIGATION + SUMMARY_REPORT_CASE + EVENT_METRIC + SR100 | cd='10470' (Cholera), rpt_cnty_cd='13121' (Fulton County, state 13). Sets add_user_name, mmwr_week='14', mmwr_year='2026', rpt_to_state_time='2026-04-01' so SR100's four NOT NULL columns (ADD_USER_NAME, MMWRWK, MMWRYR, DATE_REPORTED) resolve. patient_id reuses foundation Patient 20000000 (read-only ref). |
| 22024100 | @sr100_obs_sum103 | SUM103 `nrt_observation.observation_uid` (coded, summary case source) | ovc_code='PHC_LOCAL'. Drives SUMMARY_CASE_SRC / RPT_SOURCE. |
| 22024101 | @sr100_obs_sum104 | SUM104 `nrt_observation.observation_uid` (numeric, summary case count) | ovn_numeric_value_1=17 → SR100.NBR_CASES. |
| 22024102 | @sr100_obs_sum105 | SUM105 `nrt_observation.observation_uid` (text, summary case comments) | ovt_value_txt → SR100.REPORT_COMMENTS. |

The fixture tail-EXECs (its own UID, in dependency order):
`sp_nrt_investigation_postprocessing` → `sp_summary_report_case_postprocessing`
→ `sp_event_metric_datamart_postprocessing` → `sp_sr100_datamart_postprocessing`.
No new RDB_MODERN surrogate UIDs are allocated (INVESTIGATION_KEY,
SUMMARY_REPORT_CASE, EVENT_METRIC keys are IDENTITY-assigned by the SPs).

Unused UIDs in this block (22024001-22024099, 22024103-22024999) are
reserved for future SR100 Tier 3 amendments.

**Ordering note** (resolved): SR100 INNER-JOINs EVENT_METRIC, so it must
run AFTER `sp_event_metric_datamart_postprocessing` (and after
summary_report_case) or it sees an empty EVENT_METRIC and inserts 0 rows.
The deterministic `run_summary_datamarts` step in
`scripts/merge_and_verify.sh` sequences these correctly:
`sp_event_metric_datamart_postprocessing` →
`sp_summary_report_case_postprocessing` →
`sp_sr100_datamart_postprocessing`. The fixture's own tail-EXEC sequences
them the same way for standalone verification.

## Round 3 reservations (coverage top-up)

| Block | Task | Target |
| --- | --- | --- |
| 22023000 - 22023999 | R3-A | aggregate_report_datamart (0/42) |
| 22024000 - 22024999 | R3-B | sr100 / SR100 datamart (0/20) |
| 22025000 - 22025999 | R3-C | ldf_bmird + ldf_hepatitis (LDF-flagged answers) |
| 22026000 - 22026999 | R3-D | var_datamart (close remaining ~21 cols) |
| 22027000 - 22027999 | R3-E | TB_DATAMART remainder (partial 95/318) |
| 22028000 - 22028999 | R3-F | var_datamart fill via NEW complete varicella chain (additive) |
| 22029000 - 22029999 | R3-G | tb_datamart fill via NEW complete TB chain (additive) |

> **R3-G sub-range carve-out (allocated 2026-06-02).** The 22029000 block was
> already in use by `zz_lab101_unblock.sql` (UIDs 22029000, 22029300-302,
> 22029400-402, 22029500, 22029600-634, 22029699-734, 22029800-801, 22029999).
> R3-G (`fixtures/30_sp_coverage/zz_tb_datamart_addl_chain.sql`) therefore lives
> in the clear sub-range **22029020-22029129** (verified unused across all
> fixtures). Used UIDs:
> - `22029020` user_profile.NEDSS_ENTRY_ID (new add/edit/notif user)
> - `22029021-22029026` surrogate dim keys (D_PROVIDER x3, D_ORGANIZATION x2, D_PATIENT)
> - `22029031-22029035` D_PROVIDER/D_ORGANIZATION ORGANIZATION/PROVIDER_UIDs
> - `22029040` D_PATIENT.PATIENT_UID + nrt_investigation.patient_id
> - `22029050` notification.NOTIFICATION_KEY; `22029060` nrt_investigation_notification source_act_uid/notification_uid
> - `22029100` NEW TB PHC (act_uid / public_health_case_uid / nrt_investigation); `22029101` case_management_uid
> - `22029110-22029122` nbs_case_answer + nrt_page_case_answer rows (RVCT TUB answers)
>
> **ORCH_TODO:** add `22029100` to the `PHC_UIDS` list in
> `run_summary_datamarts` (`scripts/merge_and_verify.sh`) so the new TB
> PHC is covered by the deterministic TB-PAM + TB datamart pass (the
> reporting-pipeline-service also fires the TB chain for 22029100 off CDC
> events during the drain, so the row exists either way; adding it to
> `PHC_UIDS` keeps it first-class under the deterministic datamart pass).

> **R3-F sub-range carve-out (allocated 2026-06-02).** The 22028000 block was
> already in use by `zz_d_investigation_repeat_round3` (22028000-22028381
> + sentinel 22028999). R3-F
> (`fixtures/30_sp_coverage/zz_var_datamart_addl_chain.sql`) therefore lives in
> the clear sub-range **22028400-22028524** (verified unused across all fixtures).
> Used UIDs:
> - `22028400` NEW Varicella PHC (act_uid / public_health_case_uid /
>   nrt_investigation / EVENT_METRIC.EVENT_UID / nrt_page_case_answer.act_uid /
>   nrt_investigation_confirmation.public_health_case_uid)
> - `22028401` case_management.case_management_uid
> - `22028410` D_PATIENT.PATIENT_UID + PATIENT_KEY; nrt_investigation.patient_id
> - `22028420-22028422` D_PROVIDER x3 (investigator / physician / reporter),
>   PROVIDER_KEY=PROVIDER_UID; referenced by nrt_investigation investigator_id /
>   physician_id / person_as_reporter_uid
> - `22028430-22028431` D_ORGANIZATION x2 (reporting source / hospital),
>   ORGANIZATION_KEY=ORGANIZATION_UID; referenced by org_as_reporter_uid /
>   hospital_uid
> - `22028440` USER_PROFILE.NEDSS_ENTRY_ID (creator/editor/notif submitter)
> - `22028450` NOTIFICATION.NOTIFICATION_KEY (+ NOTIFICATION_EVENT keyed by
>   patient_key 22028410)
> - `22028500-22028524` nbs_case_answer + nrt_page_case_answer rows (VAR answers)
>
> **ORCH_TODO:** add `22028400` to the `PHC_UIDS` list in
> `run_summary_datamarts` (`scripts/merge_and_verify.sh`) so the new
> Varicella PHC is covered by the deterministic VAR-PAM + var_datamart
> pass (the reporting-pipeline-service also fires the VAR chain for
> 22028400 off CDC events during the drain, so the row exists either way;
> adding it to `PHC_UIDS` keeps it first-class under the deterministic
> datamart pass).

<!-- Round 4 (coverage recovery) -->
| 22040000 - 22044999 | Round 4 fixtures (P2 ODSE chains) |
| 22040000 - 22040999 | R4 TB-fact, **allocated 2026-06-03**, `zz_tb_fact_chain.sql`. Target `tb_datamart` (0/318) + `tb_hiv_datamart` (0/322), both built FROM `F_TB_PAM` which was EMPTY. Root cause: `sp_f_tb_pam_postprocessing` (routine 206) derives `TB_PAM_UID = nrt_investigation.nac_page_case_uid`, which was NULL for TB PHC 22001000 because `sp_investigation_event` (routine 056, lines 910-935) only sets `nac_page_case_uid` when the PHC has `nbs_act_entity` rows, and our TB investigation had ZERO. Fix: author 3 `NBS_ODSE.dbo.nbs_act_entity` rows (`OrgAsReporterOfPHC`, `HospOfADT`, `PerAsReporterOfPHC`) for act_uid=22001000, mirroring the foundation investigations (20000100/20050010), + a `public_health_case.last_chg_time` bump to re-trigger CDC→`sp_investigation_event`. UIDs consumed: 22040000-22040002 (`nbs_act_entity_uid`, IDENTITY_INSERT). |
| 22041000 - 22041999 | R4 COVID-lab, **allocated 2026-06-03, no UIDs consumed**. Target `covid_lab_datamart` (0/120) + `covid_lab_celr_datamart` (0/101) found UNAUTHORABLE from ODSE-only fixtures: `sp_covid_lab_datamart_postprocessing` filters lab results on `nrt_srte_Loinc_condition WHERE condition_cd='11065'`, which has **zero rows** in the baseline seed (NBS_SRTE.dbo.Loinc_condition, 3449 rows, none for 11065). Populating it = an SRTE/seed edit → OUT OF BOUNDS. The complete ODSE lab chain already exists in the DB (UIDs 22022000/22022001 from `zz_covid_lab_datamart_unblock`) and is already processed by the reporting-pipeline-service during the CDC drain (which runs the lab chain off CDC events and feeds both datamart SPs), yet the datamarts stay at 0 rows solely due to this SRTE gap. Documented as SEED-gated gap (VAR_DATAMART precedent) in `bugs/16_covid_lab_loinc_condition_seed_gap/`. Block freed for reuse. |
| 22042000 - 22042999 | R4 Hepatitis-obs, **allocated 2026-06-03**, `zz_hepatitis_obs_chain.sql`. Target `hep100` (0/187) + `hepatitis_datamart` (39/209) via the REAL observation pipeline. `sp_hep100_datamart_postprocessing` (042) builds FROM `dbo.HEPATITIS_CASE`, which is itself built by `sp_hepatitis_case_datamart_postprocessing` (039) from `dbo.v_rdb_obs_mapping` (← `nrt_srte_IMRDBMapping WHERE RDB_table='Hepatitis_Case'` JOIN `v_getobs{code,num,txt,date}` keyed on `unique_cd`=obs.cd, filtered `branch_type_cd='InvFrmQ'`). The existing Hep A acute PHC 22008500 (cond 10110, in PHC_UIDS) had ZERO HEP observations in ODSE, so the whole chain was empty. Fix: author the ODSE observation graph for act 22008500: one `act`(OBS)+`Observation`(cd=HEPnnn)+`Obs_value_{coded,numeric,txt,date}` per IMRDBMapping unique_cd (103 coded, 12 numeric, 13 txt, 11 date), one L1 form observation (cd `INV_FORM_HepatitisInvestigation`), `Act_relationship` InvFrmQ (each Q → L1 form) + PHCInvForm (L1 form → PHC 22008500). CDC mirrors ODSE → `nrt_observation*`; service `sp_investigation_event` builds `nrt_investigation_observation`. UIDs consumed: `22042001` L1 form obs; `22042100-22042238` question observations (= HEP code numeric suffix offset by +22042000 mod, see fixture header). No new PHC (reuses 22008500). |
| 22043000 - 22043999 | R4-D hepatitis chain fix (HEPATITIS_CASE/hep100). **allocated 2026-06-03**, `zz_hepatitis_case_chain.sql`. ROOT CAUSE of the `zz_hepatitis_obs_chain.sql` (22042xxx) miss: it hung the 139 HEP obs off foundation PHC 22008500 (cond **10110**), whose `condition_code.investigation_form_cd='PG_Hepatitis_A_Acute_Investigation'` FAILS the `INV_FORM_HEP%` gate in `sp_hepatitis_case_datamart_postprocessing` (039, `#KEY_ATTR_INIT`), and 10110 maps in `nrt_datamart_metadata` ONLY to `Hepatitis_Datamart` (013), never `Hepatitis_Case` (039). Live proof: job_flow_log step `GENERATING #KEY_ATTR_INIT` row_count=0 despite v_rdb_obs_mapping=139. FIX: NEW PHC **22043000** under cond **10481** (Hepatitis Non-ABC, Acute → maps to Hepatitis_Case AND form `INV_FORM_HEPGEN`, matches gate) + SubjOfPHC patient link 20000000 + its own 139-obs InvFrmQ chain (L1 form `22043001`, questions `22043100-22043238`) + PHCInvForm. UIDs: 22043000 PHC/act, 22043001 L1 form obs, 22043100-22043238 questions. **ORCH: 22043000 added to PHC_UIDS in scripts/merge_and_verify.sh.** |
| 22044000 - 22044999 | R4-E std_hiv_datamart fill. **allocated 2026-06-03**, `zz_std_hiv_fill.sql`. ODSE-ONLY. Target the ~190 NULL D_INV_*-sourced columns on STD PHC 22004000 (cond 10311, form PG_STD_Investigation). Root cause: all 364 generic page answers (`zz_page_answers_datamart_routing.sql`) carry `answer_group_seq_nbr=0`, but the page-builder dim staging SP (routine 007 `sp_s_pagebuilder_postprocessing`, text path line 103 + coded path lines 191/193) builds the SINGLE D_INV_* dim rows ONLY from answers with `ANSWER_GROUP_SEQ_NBR IS NULL` (group_seq=0 feeds D_INVESTIGATION_REPEAT instead). So every D_INV_* dim is EMPTY for the STD investigation → all CLN/CMP/CTT/EPI/HIV/LAB/MDH/IPO/PBI/RSK/SOC/SYM/TRT/ADM columns NULL. Verified live: 0 STD answers with NULL group seq; 0 D_INV_* dim rows; COVID 22003000 populates its dims precisely because its curated answers (e.g. 22003109) have group_seq=NULL. FIX: author 112 NULL-group `NBS_ODSE.dbo.nbs_case_answer` complement rows (IDENTITY_INSERT) for the STD-form question_uids mapped to 14 single D_INV_* dims (codes reuse generator-proven valid values; STD-realistic where clear), + a `public_health_case.last_chg_time` bump to re-trigger CDC→`sp_investigation_event`→the page-builder rebuild the service runs during the CDC drain. No new act/PHC (reuses 22004000, already in PHC_UIDS). UIDs consumed: 22044000-22044360 (`nbs_case_answer_uid`, sparse). |
| 22045000 - 22045999 | R4-F covid_case_datamart fill. **allocated 2026-06-03**, `zz_covid_case_fill.sql`. ODSE-ONLY. Target the 105 NULL repeating-group columns (`<COL>_1/_2/_3`) on COVID PHC 22003000 (cond 11065, form PG_COVID-19_v1.1). Root cause: every repeating-block question already has an NRT page answer but with `answer_group_seq_nbr=0`, while `sp_covid_case_datamart_postprocessing` (routine 310) RPT_DATA_1/2/3 steps pivot only `answer_group_seq_nbr IN (1,2,3)` for ui_metadata rows with `question_group_seq_nbr IS NOT NULL`. Fix: author 35 repeating COVID questions × 3 answer groups = 105 `NBS_ODSE.dbo.nbs_case_answer` rows (IDENTITY_INSERT), real coded values from NRT_SRTE_CODE_VALUE_GENERAL (LAB/specimen, travel, exposure-location, occupation/industry blocks). CDC mirrors ODSE → nrt_page_case_answer; the covid datamart SP the service fires during the CDC drain pivots. No new act/PHC (reuses 22003000). UIDs consumed: 22045000-22045104 (`nbs_case_answer_uid`). |
| 22046000 - 22046999 | R4-G hepatitis_datamart fill. **allocated 2026-06-03**, `zz_hepatitis_datamart_fill.sql`. ODSE-ONLY. Target the 167 NULL columns on `hepatitis_datamart`. ROOT CAUSE: the committed `zz_hepatitis_case_chain.sql` PHC 22043000 (cond **10481** → form `INV_FORM_HEPGEN`) populates `HEPATITIS_CASE` (149/152) via the **InvFrmQ observation** route, but `sp_hepatitis_datamart_postprocessing` (routine 013) sources its 167 NULL cols from the **page-builder D_INV_\* dims** (D_INV_LAB_FINDING/RISK_FACTOR/MEDICAL_HISTORY/EPIDEMIOLOGY, aliases L/R/MH/E), which are built by `sp_s_pagebuilder_postprocessing` (routine 007) + `sp_f_page_case_postprocessing` from `nrt_page_case_answer` (← ODSE `nbs_case_answer`). PHC 22043000 had ZERO page answers and `INV_FORM_HEPGEN` carries ZERO datamart-mapped `nbs_ui_metadata`/`nbs_rdb_metadata`, so `nrt_investigation.rdb_table_name_list` is NULL → F_PAGE_CASE empty → all dim joins return nothing. FIX: NEW PHC **22046000** under cond **10100** (Hepatitis B, acute → form `PG_Hepatitis_B_and_C_Acute_Investigation`, which DOES carry the page-builder dim metadata: 36 LAB_FINDING + 30 RISK_FACTOR + 9 MEDICAL_HISTORY + 10 EPIDEMIOLOGY = 85 datamart-mapped questions; and 10100 maps in `nrt_datamart_metadata` to `Hepatitis_Datamart` → `sp_hepatitis_datamart_postprocessing`) + SubjOfPHC patient link 20000000 + 85 `nbs_case_answer` rows on that form's datamart-mapped question_uids (type-correct values; `answer_group_seq_nbr=NULL` per LESSON 9 so they route to the SINGLE D_INV dims, not D_INVESTIGATION_REPEAT). `nbs_case_answer_uid` is IDENTITY → omitted. UIDs consumed: 22046000 PHC/act + act_id; participation uses subject 20000000 (no new uid). **ORCH: add 22046000 to PHC_UIDS in scripts/merge_and_verify.sh** so routine 007/036/013 process it. |
| 22047000 - 22047999 | R4-H d_investigation_repeat fill. **allocated 2026-06-03**, `zz_d_inv_repeat_fill.sql`. ODSE-ONLY. Target the 162 NULL cols of `D_INVESTIGATION_REPEAT` (82/244 baseline). The 4 contract-named forms reach only ~2 NULL cols (live-proven): COVID/STD/Pertussis repeat columns are already populated by prior fixtures, their lone remaining NULL repeat cols (TRV_DURATION_OUTSIDE_US / EPI_SUSPECTED_SOURCE_AGE) are NUMERIC+`unit_type_cd='CODED'` which routine 010's pivot cannot land (numeric branch needs unit NULL/LITERAL; coded-numeric branch needs form IS NULL), and Hep 22043000 (INV_FORM_HEPGEN) is EXCLUDED by the routine-010 form filter (line 91). The real 162-col gap belongs to page-builder forms with NO investigation. This fixture authors 2 NEW page-builder PHCs (forms NOT in the exclusion list, conditions present in the seed): **TB_LTBI** PHC `22047000` (cond 502582 → `PG_TB_LTBI_Investigation`, 25 repeating questions) and **Trichinellosis** PHC `22047500` (cond 10270 → `PG_Trichinellosis_Investigation`, 15 questions) = **40 DISTINCT NULL columns** expected to fill (39 after subtracting the 1 SP-gated TRV_DURATION_OUTSIDE_US). Each PHC: act + public_health_case + act_id + SubjOfPHC participation (patient 20000000) + case_management + `nbs_case_answer` rows at `answer_group_seq_nbr` 1/2/3 (repeating). CDC mirrors PHC→nrt_investigation; service builds nrt_page_case_answer (resolving rdb_column_nm by nbs_question_uid + form via seed ui/rdb metadata); during the CDC drain the service's page-builder path (sp_page_builder_postprocessing → sp_sld_investigation_repeat_postprocessing, gated on rdb_table_name_list containing 'D_INVESTIGATION_REPEAT') pivots into D_INVESTIGATION_REPEAT. UIDs: `22047000` TB_LTBI PHC/act, `22047001` TB_LTBI case_mgmt, `22047100-22047174` TB_LTBI 75 answers; `22047500` Trich PHC/act, `22047501` Trich case_mgmt, `22047600-22047644` Trich 45 answers. **SEED-GATED (skipped, documented):** PG_Malaria_Investigation (+26 NULL cols) has NO Condition_code row in the seed → routing key absent → OUT OF BOUNDS. **ORCH_TODO: ensure the TB_LTBI/Trich `nrt_investigation` rows carry `'D_INVESTIGATION_REPEAT'` in `rdb_table_name_list`** so the CDC page-builder path fires the repeat SP for them. |
| 22048000 - 22048999 | R4-I bmird_strep_pneumo fill. **allocated 2026-06-03**, `zz_bmird_fill.sql`. ODSE-ONLY. Target the 91 NULL columns on `bmird_strep_pneumo_datamart` for BMIRD Strep pneumo PHC **22005000** (cond 11717, form INV_FORM_BMDSP). Root cause: the legacy BMIRD form populates `BMIRD_CASE` (and thence the strep datamart) entirely from **InvFrmQ observations** pivoted through `v_rdb_obs_mapping` (← `nrt_srte_IMRDBMapping` JOIN `v_getobs{code,num,txt,date}` keyed `unique_cd`=obs.cd, `branch_type_cd='InvFrmQ'`), per `sp_bmird_case_datamart_postprocessing` (040). The original `bmird_investigation_full_chain.sql` only authored the ODSE act/PHC/case_management (investigation-level → 49 cols), and `zz_bmird_strep_pneumo_datamart_enrich.sql` was a pure-nrt no-op with no ODSE backing, so ZERO obs ever landed for 22005000. Fix: author the real ODSE observation graph for act 22005000: one `act`(OBS)+`Observation`(cd=BMDnnn)+`Obs_value_{coded,numeric,txt,date}` per IMRDBMapping unique_cd for RDB_table IN ('BMIRD_Case','BMIRD_Multi_Value_field'); L1 form observation (cd `INV_FORM_BMDSP`); `Act_relationship` InvFrmQ (each Q → L1 form) + PHCInvForm (L1 form → PHC). CDC mirrors ODSE → `nrt_observation*`; service `sp_investigation_event` builds `nrt_investigation_observation`; the `sp_bmird_case_datamart_postprocessing` + `sp_bmird_strep_pneumo_datamart_postprocessing` SPs the service fires during the CDC drain pivot. No new PHC (reuses 22005000, already in PHC_UIDS). UIDs consumed: 22048001 L1 form obs; 22048100-22048124 direct BMIRD_Case question obs; 22048200-22048214 multi-value-field obs (BMD127/125/142/144/118, multiple selections each). |
| 22049000 - 22049999 | R4-J d_investigation_repeat fill #2. **allocated 2026-06-03**, `zz_d_inv_repeat_fill2.sql`. ODSE-ONLY. Target the remaining NULL columns of `D_INVESTIGATION_REPEAT` (121/245 populated at authoring; 124 NULL). R4-H filled TB_LTBI + Trichinellosis; this fixture adds FOUR more mapped, NON-excluded page-builder forms with NO investigation in the corpus: **STEC** PHC `22049000` (cond 115631 → `PG_STEC_Investigation_(PB)`, 38 repeating Qs, +39 marginal NULL cols), **Cyclosporiasis** PHC `22049200` (cond 115751 → `PG_Cyclosporiasis_Investigation`, 33 Qs, +33), **Salmonellosis** PHC `22049400` (cond 502651 → `PG_Salmonellosis_(PB)`, 15 Qs, +14), **Malaria** PHC `22049500` (cond 10130 → `PG_Malaria_Investigation`, 24 Qs, +24). Distinct union of their NULL cols = **81**; minus the 2 SP-gated NUMERIC+`unit_type_cd='CODED'` Qs that routine 010's pivot cannot land (TRV_DURATION_OUTSIDE_US q 10006160 shared by all four; CLN_ADVERSE_EVNT_ONSET q 10008164 on Malaria) → **~79 columns expected to fill**. **R4-H "PG_Malaria_Investigation is SEED-GATED" CLAIM CORRECTED (live-verified 2026-06-03):** condition_cd 10130 → form IS present in both `NBS_SRTE.dbo.Condition_code` AND the pipeline routing copy `RDB_MODERN.dbo.nrt_srte_Condition_code`, and the form's ui/rdb metadata is seeded (24 repeat cols resolve) → Malaria is IN BOUNDS. Each PHC: act + public_health_case + act_id + SubjOfPHC participation (patient 20000000) + case_management + `nbs_case_answer` rows at `answer_group_seq_nbr` 1/2/3 (330 answers total). CDC mirrors PHC→nrt_investigation; service builds nrt_page_case_answer; during the CDC drain the service's page-builder path (sp_page_builder_postprocessing → `sp_sld_investigation_repeat_postprocessing`, gated on rdb_table_name_list containing 'D_INVESTIGATION_REPEAT') pivots into D_INVESTIGATION_REPEAT. UIDs: `22049000`/`22049001` STEC PHC/case_mgmt + `22049010-22049126` answers; `22049200`/`22049201` Cyclo + `22049210-22049308`; `22049400`/`22049401` Salm + `22049410-22049451`; `22049500`/`22049501` Malaria + `22049510-22049581`. **ORCH_TODO: ensure the STEC/Cyclo/Salm/Malaria `nrt_investigation` rows carry `'D_INVESTIGATION_REPEAT'` in `rdb_table_name_list`** so the CDC page-builder path fires the repeat SP for them. |
| 22050000 - 22050999 | R4-K tb_datamart/tb_hiv dimensional tail. **allocated 2026-06-03**, `zz_tb_datamart_fill.sql`. ODSE-ONLY. Target the ~90 NULL columns shared by `tb_datamart` (228/318) and `tb_hiv_datamart` (232/322), both built FROM `dbo.F_TB_PAM` (routines 255/260). The single existing TB row (PHC 22001000) leaves them NULL for ROW-level reasons, not structural: (a) it links the SPARSE foundation patient 20000000 (no SSN/middle-name/suffix/within-city/Asian-race-breakdown), and UPDATE of the shared D_PATIENT is forbidden; (b) no InvestgrOfPHC/PhysicianOfPHC participation → investigator_id/physician_id NULL → INVESTIGATOR_*/PHYSICIAN_* NULL; (c) thin public_health_case (no hospitalized/diagnosis/onset/day-care/transmission/detection/deceased/mmwr/imported-*); (d) no Confirmation_method rows; (e) d_topic answers carry a single distinct decoded VALUE per group so the 255 ROW_NUMBER-over-DISTINCT-VALUE pivot fills only _1 (the _2/_3 cols of OUT_OF_CNTRY/MOVE_CNTRY/MOVE_STATE/MOVE_CNTY/MOVED_WHERE/GT_12_REAS/HC_PROV_TY/DISEASE_SITE/SMR_EXAM_TY/ADDL_RISK stay NULL); (f) 3 single D_TB_PAM measure cols unanswered (PATIENT_BIRTH_COUNTRY, INIT_REGIMEN_PA_SALICYLIC_ACID, FINAL_SUSCEPT_RIFAMPIN). Since coverage = any-non-NULL-across-rows, this fixture authors a SECOND richly-attributed TB RVCT investigation (PHC **22050000**, cond 10220 → INV_FORM_RVCT) whose own row populates those columns: act + public_health_case (rich INV fields, proven-good codes from Tier-1 v2 20050010) + act_id + case_management; participations SubjOfPHC→**20020010** (rich "Variant Patient"), InvestgrOfPHC→**20010010** (rich "Variant Provider"), PhysicianOfPHC→**20000010**, PerAsReporterOfPHC→20010010; nbs_act_entity OrgAsReporterOfPHC/HospOfADT→**20030010** ("Variant Hospital") + PerAsReporterOfPHC→20010010 (nac_page_case_uid → F_TB_PAM key); 2 Confirmation_method rows (LD/CI → CONFIRMATION_METHOD_1/2/ALL + CONFIRMATION_DATE); nbs_case_answer: 4 single-measure (1327/1000/1004/1273) + 9 repeating d_topic questions × 3 DISTINCT codes (seq 1/2/3) so _1/_2/_3 all fill + 2 SMR_EXAM_TY (only 2 codes exist in seed). CDC mirrors ODSE; service event SP + page-builder run D_TB_PAM(147)+12 d_topic SPs; the tb_datamart SPs (routines 206/255/260) the service fires during the CDC drain write the 2nd row. **CEILING:** SMR_EXAM_TY_3 unreachable (PHVS_TB_MICRO_EX_TY has only 2 codes). UIDs consumed: 22050000 PHC/act/act_id/answers.act_uid/Confirmation_method; 22050001 case_management; 22050100-22050196 nbs_case_answer (IDENTITY_INSERT); 22050500-22050502 nbs_act_entity (IDENTITY_INSERT). **ORCH_TODO: add `22050000` to the `PHC_UIDS` list in `run_summary_datamarts` (`scripts/merge_and_verify.sh`)** so the deterministic datamart pass covers it (the service page-builder also processes it during the drain). |
| 22051000 - 22051999 | R4-L covid_contact_datamart. **allocated 2026-06-03**, `zz_covid_contact_fill.sql`. ODSE-ONLY. Target `covid_contact_datamart` (0/94, empty). Root cause (live-verified): `sp_covid_contact_datamart_postprocessing` (315) builds FROM `nrt_contact con INNER JOIN nrt_investigation inv ON con.SUBJECT_ENTITY_PHC_UID=inv.public_health_case_uid WHERE inv.cd='11065' AND inv IN @phcid_list`. COVID index PHC 22003000 (cond 11065, patient_id 20000000) is in $PHC_UIDS, but the only baseline `nrt_contact` rows point at `SUBJECT_ENTITY_PHC_UID=20000100` (Hep A foundation PHC, cond 10110) → fail the `inv.cd='11065'` filter → 0 rows. REACHABLE: `nrt_contact` is reproduced from ODSE `dbo.CT_contact` by the real pipeline (Debezium connector table.include.list contains `dbo.CT_contact` → topic `nbs_CT_contact` → service `InvestigationService` @KafkaListener → `ContactRepository.computeContact` → `sp_contact_record_event` (069) writes `nrt_contact`). Fix: author ONE ODSE `ct_contact` (UID 22051010) with `subject_entity_phc_uid=22003000`, `subject_entity_uid=20000000` (index patient), `contact_entity_uid=22051000` (NEW contact-party entity; UNIQUE on ct_contact.contact_entity_uid forbids reuse), `contact_status=NULL` (dodges the `fn_get_value_by_cd_codeset` 3-part-name CASE in the event SP, mirroring Tier-1 contact.sql v2). NO new PHC, NO nrt_* INSERT, NO EXEC sp_. UIDs consumed: 22051000 (entity+person contact party), 22051010 (act + ct_contact). **ORCH_TODO: none**, since 22003000 already in `PHC_UIDS` and the reporting-pipeline-service fires `sp_covid_contact_datamart_postprocessing` for it during the CDC drain; the Tier-3 drain processes the new CT_contact CDC event end-to-end (service `InvestigationService` → `ContactRepository.computeContact` → `sp_contact_record_event` writes `nrt_contact`, then the contact datamart SP runs). No script step or manual UID list is involved. |
| 22052000 - 22052999 | R4-M TB tail debug/fix (tb_datamart 2nd row) |
| 22053000 - 22053999 | R4-N lab100 + lab101. **allocated 2026-06-03**, `zz_lab100_101_fill.sql`. ODSE-ONLY. Part A (LAB100 36/69→demographics): new fully-attributed Order `22053010` + Result child `22053011` (LOINC 13950-1, cond 10110 baseline-seeded) with participations PATSBJ→20000000 / ORD,VRF→20000010 / AUT,ORD(org)→20000020 / PRF→20000020 + role SPP(PSN)→20000010 (specimen collector) → CDC sets nrt_observation.patient_id/ordering_person_id/author_organization_id/ordering_organization_id/specimen_collector_id → sp_d_labtest_result_postprocessing (017) resolves D_PATIENT 4 / D_PROVIDER 12 / D_ORGANIZATION 7 → fills PERSON_*/PATIENT_*/PROVIDER_*/ORDERING_FACILITY/REPORTING_FACILITY*/ACCESSION_NBR. ROOT CAUSE of NULLs: v2 lab 20070010 had ZERO participations. Part B (LAB101 0/46→unblock): full ODSE I_Order `22053500` + I_Result `22053501` + 'Result' `22053502` + 35 LABxxx I_Result children `22053600-22053634` (cd LAB329a,LAB330..LAB363) each + obs_value_coded(display_name→TEST_RESULT_VAL_CD_DESC) + obs_value_txt, wired child→I_Order via COMP act_relationship so sp_observation_event (055) emits them in the I_Order followup_observations JSON → service sets nrt_observation.followup_observation_uid → sp_lab101 (020) step 2 #tmp_I_Result_vals resolves → 35-col trtdN pivot (LAB1..LAB35) lands. ROOT CAUSE of 0/46: the prior zz_lab101_unblock.sql injected RDB LAB_TEST/LAB_RESULT_VAL directly without a backing nrt_observation INSERT → root-order nrt_observation never existed → chain starved. UIDs consumed: 22053010/22053011 (Part A acts/obs), 22053500/22053501/22053502 (Part B I_Order/I_Result/Result), 22053600-22053634 (35 LABxxx children). **ORCH_TODO: none** — these lab observations are processed by the reporting-pipeline-service during the CDC drain, which runs the lab chain (`sp_observation_event` + `sp_d_labtest_result_postprocessing` + `sp_lab101` + the lab100/101 datamart SPs) off the CDC events; no script obs-UID list to update. SEED note: LAB100/LAB101 are NOT subject to the covid_lab 11065-LOINC seed gate (bug #16); the chain uses baseline-seeded LOINC 13950-1→cond 10110 and culture codes, so CONDITION_CD/PROGRAM_AREA fill without seed edits. |
| 22054000 - 22054999 | R4-O hepatitis_datamart remainder |
| 22055000 - 22055999 | R5-C COVID dedicated patient/provider/org + enriched PHC. **allocated 2026-06-04**, `zz_covid_dedicated_entities.sql` + edits to `covid_investigation_full_chain.sql` (PHC-core scalars) + `zz_investigation_patient_links.sql` (omit 22003000). ODSE-ONLY, ADDITIVE, no shared-dim UPDATE. Fills the ~27 shared-dim NULL cols of `covid_case_datamart` for COVID PHC 22003000 by authoring DEDICATED rich entities and repointing 22003000's participations to them: rich patient `22055000` (PSN/PAT, full name/middle/suffix/DOB/sex/race/ethnicity/marital/age+unit/deceased/full addr/home+work+cell phone w/ work-ext/email) → SubjOfPHC; investigator `22055010` → InvestgrOfPHC; physician `22055020` → PhysicianOfPHC; person-reporter `22055030` → PerAsReporterOfPHC (all PSN/PRV, self-parented, work addr/phone+ext/cell); reporter org `22055040` → OrgAsReporterOfPHC; hospital org `22055050` → HospOfADT (both ORG, addr + work phone+ext). Locators 22055001-006 / 011-013 / 021-023 / 031-033 / 041-042 / 051-052. nbs_act_entity edges (PerAsReporterOfPHC/OrgAsReporterOfPHC/HospOfADT) auto-IDENTITY + natural-key guard (LESSON 11). The pipeline (CDC→nrt_*→sp_*_event/sp_nrt_*_postprocessing) builds D_PATIENT/D_PROVIDER/D_ORGANIZATION + nrt_investigation.{patient,investigator,physician,person_as_reporter,organization,hospital}_id from these per ProcessInvestigationDataUtil.java:211-292; routine 310 reads them. The foundation SubjOfPHC(22003000→20000000) is superseded (DELETE + re-INSERT to 22055000); `zz_investigation_patient_links.sql` no longer lists 22003000 (it sorts AFTER and would otherwise re-add the foundation link → dup SubjOfPHC). **ORCH_TODO: none**, since 22003000 already in `PHC_UIDS`; the Tier-3 CDC drain (900s) projects ODSE→dims and the service fires `sp_covid_case_datamart_postprocessing` off the CDC events during that drain. |
| 22057000 - 22057999 | R5 STD-C dedicated patient/provider/org + enriched PHC. **allocated 2026-06-04**, `zz_std_dedicated_entities.sql` + edits to `std_hiv_investigation_full_chain.sql` (PHC-core scalars) + `zz_investigation_patient_links.sql` (omit 22004000). ODSE-ONLY, ADDITIVE, no shared-dim UPDATE. STD twin of the COVID R5-C block (22055xxx). Fills the shared-dim NULL cols of `std_hiv_datamart` for STD Syphilis-primary PHC 22004000 (cond 10311, PG_STD_Investigation) by authoring DEDICATED rich entities and repointing 22004000's participations to them: rich patient `22057000` (PSN/PAT, full name/middle/suffix/DOB/sex/race 2054-5 Black/ethnicity/marital S/age 33+unit/full addr/home+work+cell phone w/ work-ext/email) → SubjOfPHC → PC.PATIENT_KEY (026:536) → all PATIENT_* (~36 cols, filter PC.PATIENT_KEY!=1 at 026:566 needs a real patient); investigator `22057010` → InvestgrOfPHC → PC.INVESTIGATOR_KEY → INVESTIGATOR_CURRENT_KEY + INVESTIGATOR_CURRENT_QC (CRNTI.PROVIDER_QUICK_CODE 026:336-337/539); physician `22057020` → PhysicianOfPHC → PHYSICIAN_KEY (026:448); person-reporter `22057030` → PerAsReporterOfPHC → REPORTING_PROV_KEY (026:452); reporter org `22057040` → OrgAsReporterOfPHC → REPORTING_ORG_KEY (026:451); hospital org `22057050` → HospOfADT → HOSPITAL_KEY (026:315). Locators 22057001-006 / 011-013 / 021-023 / 031-033 / 041-042 / 051-052. nbs_act_entity edges (PerAsReporterOfPHC/OrgAsReporterOfPHC/HospOfADT) auto-IDENTITY + natural-key guard (LESSON 10/11). 025 derives those PC keys from nrt_investigation.{patient,investigator,physician,person_as_reporter,organization,hospital}_id (025:180-191/215-225); the service maps the participations onto nrt_investigation per ProcessInvestigationDataUtil.java:211-292, person_cd via self-parent (056:356-359). The foundation SubjOfPHC(22004000→20000000) is superseded (DELETE + re-INSERT to 22057000); `zz_investigation_patient_links.sql` no longer lists 22004000 (belt-and-suspenders so exactly ONE SubjOfPHC regardless of run order). PHC-core scalar enrich on 22004000's own public_health_case row (Part 2): hospitalized_ind_cd N→HSPTLIZD_IND, outcome_cd N→DIE_FRM_THIS_ILLNESS_IND, disease_imported_cd OOS→DISEASE_IMPORTED_IND, pat_age_at_onset 33/Y→PATIENT_AGE_AT_ONSET/_UNIT, pregnant_ind N→PATIENT_PREGNANT_IND, detection_method PHC2112→DETECTION_METHOD_DESC_TXT, rpt_source LA→RPT_SRC_CD/_DESC, referral_basis P1→REFERRAL_BASIS, + diagnosis/illness/activity/assigned/rpt dates, transmission_mode 1 (STD heterosexual). **ORCH_TODO: none**, since 22004000 in `PHC_UIDS` already; the Tier-3 CDC drain projects ODSE→dims and the service fires `sp_std_hiv_datamart_postprocessing` off the CDC events during that drain. **NOTE:** D_CASE_MANAGEMENT chunk (FL_*/INIT_*/OOJ_*/CA_*/SURV_* ~32 cols) is a SEPARATE SP path (sp_nrt_case_management_postprocessing); follow-up, not in this block. |
| 22058000 - 22058999 | R5 TB-C dedicated patient/provider/org + repointed participations for TB PHC 22001000. **allocated 2026-06-04**, `zz_tb_dedicated_entities.sql` + edit to `zz_investigation_patient_links.sql` (omit 22001000). ODSE-ONLY, ADDITIVE, no shared-dim UPDATE. TB twin of the COVID (22055xxx) / STD (22057xxx) R5-C blocks. Fills the shared-dim NULL cols of `tb_datamart` (routine 255) AND `tb_hiv_datamart` (routine 260, which copies `d.* FROM TB_DATAMART` 260:161-166, so filling tb_datamart fills tb_hiv too) for the ORIGINAL TB RVCT full-chain PHC 22001000 (cond 10220, INV_FORM_RVCT). Routine 255 builds #PATIENT/#PROVIDER/#PHYSICIAN/#REPORTER/#REPORTING_ORG/#HOSPITAL from `F_TB_PAM` LEFT JOIN D_PATIENT(p.PATIENT_KEY=f.PERSON_KEY)/D_PROVIDER(f.PROVIDER_KEY,f.PHYSICIAN_KEY,f.PERSON_AS_REPORTER_KEY)/D_ORGANIZATION(f.ORG_AS_REPORTER_KEY,f.HOSPITAL_KEY); F_TB_PAM (routine 206) derives those keys from INVESTIGATION.{patient,investigator,physician,person_as_reporter,org_as_reporter,hospital}_id. Authored DEDICATED rich entities + repointed 22001000's participations: rich patient `22058000` (PSN/PAT, full name/middle Anne/suffix SR/DOB/sex F/race Asian 2028-9+Korean 2040-4/ethnicity/marital M/age 46+unit/SSN/full addr+within-city/home+work+cell phone w/ work-ext/email) → SubjOfPHC → PERSON_KEY → PATIENT_* (~39 candidate cols); investigator `22058010` → InvestgrOfPHC → INVESTIGATOR_FIRST/LAST_NAME+PHONE; physician `22058020` → PhysicianOfPHC → PHYSICIAN_FIRST/LAST_NAME+PHONE+KEY; person-reporter `22058030` → PerAsReporterOfPHC → REPORTER_*+PERSON_AS_REPORTER_KEY; reporter org `22058040` → OrgAsReporterOfPHC → REPORTING_SOURCE_NAME; hospital org `22058050` → HospOfADT → HOSPITAL_NAME+KEY. Locators 22058001-006 / 011-013 / 021-023 / 031-033 / 041-042 / 051-052. The service maps person participations onto INVESTIGATION per ProcessInvestigationDataUtil.java:211-292, person_cd via self-parent (056:356-359). org/hospital/reporter ALSO via 056's nbs_act_entity CASE-pivot MAX(entity_uid) per type_cd (056:909-934): we add a SECOND set of edges (PerAsReporterOfPHC/OrgAsReporterOfPHC/HospOfADT → 22058030/40/50); since MAX wins and 22058xxx > the foundation 20000010/20000020 edges authored by `zz_tb_fact_chain.sql`, OURS override while nac_page_case_uid stays 22001000 (MAX(act_uid) unchanged). nbs_act_entity edges auto-IDENTITY + natural-key guard (LESSON 10/11). Foundation SubjOfPHC(22001000→20000000) superseded (DELETE + re-INSERT to 22058000); `zz_investigation_patient_links.sql` no longer lists 22001000 (belt-and-suspenders → exactly ONE SubjOfPHC regardless of run order). Does NOT disturb the 2nd TB investigation 22050000 (`zz_tb_datamart_fill.sql`) nor `zz_tb_fact_chain.sql`'s rows. **ORCH_TODO: none**, since 22001000 already in `PHC_UIDS`; the Tier-3 CDC drain projects ODSE→dims and the service fires sp_tb_datamart/sp_tb_hiv_datamart_postprocessing off the CDC events during that drain. |
| 22059000 - 22059999 | R5 std_hiv D_CASE_MANAGEMENT chain (22004000). **allocated 2026-06-04**, `zz_std_case_management.sql`. ODSE-ONLY, no new UIDs consumed. Fills the ~38 D_CASE_MANAGEMENT-sourced cols of `std_hiv_datamart` for STD PHC 22004000 (FL_FUP_*/INIT_FUP_*/OOJ_*/SURV_*/CA_*/ADI_900/EPI_LINK/INITIATING_AGNCY). ROOT CAUSE: the existing per-investigation ODSE `case_management` source row (case_management_uid **22004001**, authored by `std_hiv_investigation_full_chain.sql`) sets only 5 columns → its event-SP JSON projection (routine 056 lines 603-691, `FROM nbs_odse.dbo.case_management WHERE public_health_case_uid=phc`) carries NULLs → `nrt_investigation_case_management` NULL → `sp_nrt_case_management_postprocessing` (022) UPDATE leaves D_CASE_MANAGEMENT KEY=6 cols NULL → 026 reads them NULL. NOTE: `case_management.case_management_uid` is **NOT an IDENTITY column** in this DB (COLUMNPROPERTY IsIdentity=0; all rows use hardcoded PHC_uid+1), so the "IDENTITY table" premise is incorrect and a 2nd auto-IDENTITY row is neither possible nor desirable (a 2nd case_management row per PHC → 2 nrt rows → non-deterministic last-writer-wins UPDATE of the single D_CASE_MANAGEMENT row keyed on INVESTIGATION_KEY). FIX (deterministic, ODSE-only, additive): UPDATE the currently-NULL columns of the existing per-investigation source row 22004001 (per-investigation ODSE source, NOT a shared dim) with valid `code_value_general` codes (PAT_INTVW_STATUS/SURVEILLANCE_PATIENT_FOLLOWUP/PRVDR_CONTACT_OUTCOME/PRVDR_EXAM_REASON/FIELD_FOLLOWUP_DISPOSITION_STDHIV/NOTIFICATION_PLAN/NOTIFICATION_ACTUAL_METHOD_STD/INTERNET_FOLLOWUP_OUTCOME/OOJ_AGENCY_LOCAL/STD_CREATE_INV_LABMORB_NONSYPHILIS_PROC_DECISION/NOTIFIABLE/YN) + dates + free text, so both raw and `fn_get_value_by_cvg`-decoded columns fill; then bump `public_health_case.last_chg_time` (GETDATE) to re-fire `sp_investigation_event` re-projection during the Tier-3 drain. No nrt_* INSERT, no EXEC sp_, no shared-dim UPDATE. **ORCH_TODO: none**, since 22004000 already in `PHC_UIDS`; the reporting-pipeline-service fires `sp_nrt_case_management_postprocessing` for the investigation before `sp_std_hiv_datamart_postprocessing` during the CDC drain. |
| 22060000 - 22060999 | R5 d_investigation_repeat more forms. **allocated 2026-06-04**, `zz_d_inv_repeat_fill3.sql`. ODSE-ONLY. Target the remaining all-NULL columns of `D_INVESTIGATION_REPEAT` (200/299 populated; 99 NULL at authoring). Prior waves filled TB_LTBI/Trichinellosis (fill) + STEC/Cyclo/Salm/Malaria (fill2). This fixture adds FOUR more mapped, NON-excluded page-builder forms with NO investigation in the corpus, chosen by joining the 99 NULL cols back through `nrt_odse_NBS_rdb_metadata`→`nrt_odse_NBS_ui_metadata` (repeating Qs, `question_group_seq_nbr IS NOT NULL`): **TBRD** PHC `22060000` (cond 10250 → `PG_TBRD_Investigation`, 9 NULL cols), **Monkeypox** PHC `22060200` (cond 11801 → `PG_Monkeypox_Investigation`, 6), **Babesiosis** PHC `22060400` (cond 12010 → `PG_Babesiosis_Investigation`, 5), **Carbon Monoxide** PHC `22060600` (cond 32016 → `PG_Carbon_Monoxide_Investigation`, 4). All four conditions→forms verified present in BOTH `NBS_SRTE.dbo.Condition_code` AND `RDB_MODERN.dbo.nrt_srte_Condition_code` (NONE seed-gated). Distinct union after dedup (TBRD & Babesiosis share EPI_BLOOD_DONATION_DT/EPI_BLOOD_TRANSFUSION_DT/RSK_TICK_BITE_DT/RSK_TICK_BITE_LOCATION) = **18 cols expected to fill**; minus the 1 SP-gated NUMERIC+`unit_type_cd='CODED'` Q (TRV_DURATION_OUTSIDE_US q 10006160 on Babesiosis, routine-010 pivot cannot land on a named form). Each PHC: act + public_health_case + act_id + SubjOfPHC participation→patient 20000000 (D_PATIENT PATIENT_KEY 4) authored INLINE in this fixture (does NOT touch zz_investigation_patient_links.sql) + case_management (AUTO-IDENTITY, guarded on public_health_case_uid) + `nbs_case_answer` rows at `answer_group_seq_nbr` 1/2/3 (AUTO-IDENTITY, guarded on act_uid+nbs_question_uid+answer_group_seq_nbr=1 per LESSON 10/11). Coded answers use real codes (YNU 4150 / STATE_CCD 3920 / PHVS_PERSONORGTAKINGREADING_CO 116350 / PHVS_TREATMENTLOCATION_CO 116650 / MASK_USAGE 117480). CDC mirrors PHC→nrt_investigation; service builds nrt_page_case_answer; during the CDC drain the service's page-builder path (sp_page_builder_postprocessing → `sp_sld_investigation_repeat_postprocessing`, gated on rdb_table_name_list containing 'D_INVESTIGATION_REPEAT') pivots into D_INVESTIGATION_REPEAT. UIDs: `22060000` TBRD PHC/act/act_id; `22060200` Monkeypox; `22060400` Babesiosis; `22060600` Carbon Monoxide (case_management + nbs_case_answer UIDs AUTO-IDENTITY). **ORCH_TODO: ensure the TBRD/Monkeypox/Babesiosis/Carbon-Monoxide `nrt_investigation` rows carry `'D_INVESTIGATION_REPEAT'` in `rdb_table_name_list`** so the CDC page-builder path fires the repeat SP for them. |
| 22061000 - 22061999 | R5 inc-w2 bmird antimicrobial batch graph |
| 22062000 - 22062999 | R5 inc-w2 d_inv_place_repeat |
| 22063000 - 22063999 | R5 inc-w2 covid_contact contact-side investigation |

<!-- Round 6 (post key-gen fixes; non-obs-heavy targets) -->
| 22064000 - 22064999 | R6 d_investigation_repeat, allocated 2026-06-04. Additional investigation repeating-group form answers (d_inv_*_repeat column gaps). Investigation/answer-driven (NO new observations, to avoid enlarging the obs batch / bug #20 fail-fast). |
| 22065000 - 22065999 | R6 summary_report, allocated 2026-06-04. summary_report_case / sr100 fields. Notification/investigation-driven (NO new observations). |
| 22066000 - 22066999 | R6 tb gap, allocated 2026-06-04. tb_datamart + tb_hiv_datamart NON-PATIENT column gap (~25 cols) via RVCT form answers on the existing TB PHC chain. Answer/investigation-driven (NO new observations). |

<!-- Round 6 batch 2 (non-obs-heavy) -->
| 22067000 - 22067999 | R6t2 hepatitis answer-tail, allocated 2026-06-04. hepatitis_datamart/hep100 NULL column tail via additional investigation ANSWERS on existing hep PHC(s). Non-obs. |
| 22068000 - 22068999 | R6t2 d_investigation_repeat-2, allocated 2026-06-04. Remaining d_investigation_repeat NULL cols (243/300) via _OTH/other repeat answers on PHCs NOT covered by zz_d_investigation_repeat_forms.sql. New file zz_d_investigation_repeat_forms_2.sql. Non-obs. |
| (reuses 22065000) | R6t2 summary-debug: wire/trigger sp_summary_report_case_postprocessing + sp_sr100_datamart_postprocessing (currently not firing); covers merge_and_verify.sh `run_summary_datamarts` + zz_summary_report_case.sql. |

<!-- Round 6 batch 3 (non-obs-heavy) -->
| 22069000 - 22069999 | R6t3 LDF subsystem, allocated 2026-06-04. The empty LDF cluster (ldf_bmird/foodborne/hepatitis/mumps/tetanus 0/7, organization/patient/provider_ldf_group 0/3, tb_pam_ldf/var_pam_ldf 0/3) + partials ldf_data 9/17, ldf_dimensional_data 9/16, d_ldf_meta_data 12/14, via LDF (local-data-field) answers. Non-obs. May discover an SRTE LDF-metadata seed gate (document as OOB if so, bug #16 precedent). |
| 22070000 - 22070999 | R6t3 std_hiv_datamart, allocated 2026-06-04. std_hiv_datamart 223/248 (+25 non-PATIENT cols) via STD/HIV investigation ANSWERS on existing STD PHC chain. Non-obs. |
| 22071000 - 22071999 | R6t3 covid_case_datamart, allocated 2026-06-04. covid_case_datamart 372/383 (+11) + investigation 63/71 via COVID investigation ANSWERS on existing COVID PHC chain. Non-obs. |

<!-- Round 6 batch 6 (post bug #20 fix; obs/contact/vaccination now safe from fail-fast collateral) -->
| 22072000 - 22072999 | R6t6 covid_vaccination: covid_vaccination_datamart 39/60 (+21) via vaccination ODSE entities on the COVID case chain. Obs/vaccination now safe (bug #20 fixed). |
| 22073000 - 22073999 | R6t6 contact: d_contact_record 40/66 + covid_contact_datamart 76/94 via contact-record ODSE entities. Contact now safe (bug #20 fixed). |
| 22074000 - 22074999 | R6t6 lab101: investigate why lab101 stayed 0/46 after zz_lab100_101_fill; author what it needs (likely a distinct lab/result shape or CELR-style path). |

<!-- Round 6 batch 7 (conservative answer-only; avoid Confirmation_method + big obs chains) -->
| 22075000 - 22075999 | R6t7 interview: d_interview 18/24 + d_interview_note 0/7 via interview ODSE entities on existing investigation chain. Interview entity (priority 10), now safe (bug #20). |
| 22076000 - 22076999 | R6t7 hepatitis-tail: hepatitis_datamart 181/209 remaining answer-reachable D_INV cols via additional answers on existing hep PHCs. Answer-only. |
