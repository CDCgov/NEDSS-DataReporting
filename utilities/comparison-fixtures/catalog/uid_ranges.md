# UID range registry

Single source of truth for UID allocation across all tiers. Every
fixture-authoring agent reads this before writing. Adding a new tier or
block requires appending to this file in the same PR/turn that authors the
corresponding fixture.

Reservation rules (from STRATEGY.md "UID range registry"):

- Tier 0 owns `20000000 - 20009999`.
- Each Tier 1 agent gets a 10000-wide block in `200_____0 - 200_____9999`.
- Tier 2 agents allocate within `21000000 - 21099999`.
- Tier 3 agents allocate within `22000000 - 22099999`.
- Sentinel UIDs (e.g., `superuser_id = 10009282`) are referenced by symbolic
  name through `DECLARE`s and never reallocated.
- An agent allocates only within its assigned block. Cross-references to other
  agents' UIDs are by reading this registry, not by guessing.
- Foreign key targets that live outside ODSE (e.g., SRTE codes) are by string
  value, never UID.

## Tier 0 — Foundation (20000000 - 20009999)

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

## Tier 1 — Subjects (200_____0 - 200_____9999)

*Allocations made by Tier 1 agents. Format: 10000-wide block per subject.
Suggested ranges (claim by appending here):*

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

### Tier 1 — Provider (20010000 - 20019999)

Allocated by Tier 1 Provider canary. Source:
`fixtures/10_subjects/provider.sql`. Coverage report:
`coverage/coverage_provider.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20010001 | @dbo_Tele_locator_provider_work_o | `tele_locator.tele_locator_uid` for foundation Provider's (TELE, WP, `O`) work-phone/email locator | Adds the cd='O' tele locator the Provider event SP requires (lines 115-118), since foundation's tele_locator at 20000012 uses cd='PH'. Also referenced by an `entity_locator_participation` row pointing at @dbo_Entity_provider_uid (20000010). |
| 20010002 | @dbo_Postal_locator_provider_v1_alt | (reserved for foundation Provider variant address — not currently used) | Held for future Tier 3 expansion. |
| 20010010 | @dbo_Entity_provider_v2_uid | v2 Provider `entity.entity_uid`, `person.person_uid`, `person.person_parent_uid` | Class `PSN`, person.cd `PRV`. Fully-attributed Provider variant for column coverage. |
| 20010011 | @dbo_Postal_locator_provider_v2 | v2 Provider work `postal_locator.postal_locator_uid` | Wired via entity_locator_participation (PST/WP/O). |
| 20010012 | @dbo_Tele_locator_provider_v2_work | v2 Provider work phone `tele_locator.tele_locator_uid` | Wired via entity_locator_participation (TELE/WP/O). |
| 20010013 | @dbo_Tele_locator_provider_v2_email | v2 Provider email `tele_locator.tele_locator_uid` | Wired via entity_locator_participation (TELE/WP/O). email_address column. |
| 20010014 | @dbo_Tele_locator_provider_v2_cell | v2 Provider cell phone `tele_locator.tele_locator_uid` | Wired via entity_locator_participation (TELE/WP/`CP`) — cd='CP' filter at sp_provider_event line 132. |

Unused UIDs in Provider Tier 1 block (20010000, 20010003-20010009,
20010015-20019999) are reserved for future Provider Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Provider Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_provider`
keyed on `provider_uid` 20000010 (foundation) and 20010010 (v2). Those
identities are not new UIDs — they reference the entities created in
foundation and the v2 entity above.

### Tier 1 — Organization (20030000 - 20039999)

Allocated by Tier 1 Organization agent. Source:
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
identities are not new UIDs — they reference the entities created in
foundation and the v2 entity above.

### Tier 1 — Patient (20020000 - 20029999)

Allocated by Tier 1 Patient agent. Source:
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
| 20020020 | @dbo_Entity_patient_v3_uid | v3 deceased Patient `entity.entity_uid`, `person.person_uid`, `person.person_parent_uid` | Class `PSN`, person.cd `PAT`. deceased_ind_cd='Y' with deceased_time='2025-12-15' so PATIENT_DECEASED_DATE and PATIENT_DECEASED_INDICATOR='Yes' are populated for at least one variant. No locators / entity_id / person_race — minimal demographic content; the postprocessing SP propagates all D_PATIENT columns regardless of the source ODSE row's auxiliary children, since nrt_patient is hand-written. |

Unused UIDs in Patient Tier 1 block (20020000, 20020003-20020009,
20020017-20020019, 20020021-20029999) are reserved for future Patient
Tier 1 / Tier 3 amendments. Do not allocate from this range outside of
Patient Tier 1.

The fixture also writes 3 rows directly to `RDB_MODERN.dbo.nrt_patient`
keyed on `patient_uid` 20000000 (foundation), 20020010 (v2), and
20020020 (v3 deceased). Those identities are not new UIDs — they
reference the foundation entity created in 00_foundation.sql plus the
two v2/v3 entities above.

### Tier 1 — Place (20040000 - 20049999)

Allocated by Tier 1 Place agent. Source:
`fixtures/10_subjects/place.sql`. Coverage report:
`coverage/coverage_place.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20040000 | @dbo_Postal_locator_place_wp | foundation Place work-place `postal_locator.postal_locator_uid` (PST/WP/PLC) | Wired to @dbo_Entity_place_uid (20000030) via a new (PST,WP,PLC) `entity_locator_participation` row in this block. Required because the event SP at lines 91-94 filters `(USE_CD='WP', CD='PLC', CLASS_CD='PST')` and foundation's existing ELP on postal_locator 20000031 is (PST,H,H). The ELP PK is (entity_uid, locator_uid), so a second ELP row for 20000031 with a different (use_cd, cd) collides — hence a new locator. |
| 20040001 | @dbo_Tele_locator_place_phone | foundation Place work-phone `tele_locator.tele_locator_uid` (TELE/WP/PH) | Foundation Place has no tele locator; this adds one. Drives PLACE_PHONE on the foundation Place's tele rows. nrt_place_tele row keyed on (place_uid=20000030, place_tele_locator_uid=20040001). |
| 20040010 | @dbo_Entity_place_v2_uid | v2 Place `entity.entity_uid` / `place.place_uid` | Class `PLC`, place.cd `M` (Motel/Hotel from PLACE_TYPE). Fully-attributed Place variant for D_PLACE column coverage. |
| 20040011 | @dbo_Postal_locator_place_v2 | v2 Place work-place `postal_locator.postal_locator_uid` (PST/WP/PLC) | Wired via (PST,WP,PLC) ELP. |
| 20040012 | @dbo_Tele_locator_place_v2_phone | v2 Place work-phone `tele_locator.tele_locator_uid` (TELE/WP/PH) | Wired via (TELE,WP,PH) ELP. Includes `extension_txt` and `email_address`. nrt_place_tele row keyed on (place_uid=20040010, place_tele_locator_uid=20040012). |
| 20040013 | @dbo_Tele_locator_place_v2_fax | v2 Place work-fax `tele_locator.tele_locator_uid` (TELE/WP/FAX) | Wired via (TELE,WP,FAX) ELP. Shape-only on the ODSE side — exercises the EL_TYPE_TELE_PLC `FAX` code in the event SP's JSON projection. The hand-authored nrt_place_tele row on v2 references the phone locator (20040012), not this fax locator. |

Unused UIDs in Place Tier 1 block (20040002-20040009,
20040014-20049999) are reserved for future Place Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Place Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_place`
keyed on `place_uid` 20000030 (foundation) and 20040010 (v2), and 2
rows to `RDB_MODERN.dbo.nrt_place_tele` keyed on the same two
place_uids. Those identities are not new UIDs — they reference the
foundation entity created in 00_foundation.sql plus the v2 entity
above.

### Tier 1 — Investigation (20050000 - 20059999)

Allocated by Tier 1 Investigation agent. Source:
`fixtures/10_subjects/investigation.sql`. Coverage report:
`coverage/coverage_investigation.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20050010 | @dbo_Act_investigation_v2_uid | v2 Investigation `act.act_uid`, `public_health_case.public_health_case_uid` | Class `CASE`, mood `EVN`, case_class_cd `C` (Confirmed), cd `10110` (Hepatitis A, acute), prog_area_cd `HEP`, jurisdiction_cd `130001` (Fulton County), investigation_form_cd `PG_Hepatitis_A_Acute_Investigation`. Fully-attributed Investigation variant for INVESTIGATION column coverage. |
| 20050011 | @dbo_Case_management_v2_uid | v2 case_management `case_management.case_management_uid` (IDENTITY column — toggled IDENTITY_INSERT) | Wired to @dbo_Act_investigation_v2_uid via case_management.public_health_case_uid. Used by sp_investigation_event's case_management JSON branch (lines 603-691). INVESTIGATION dimension does not directly store case-management columns — added for event SP projection completeness on v2. |

The fixture also adds **one new act_id row** keyed on
`act_uid = @dbo_Act_investigation_uid (20000100)` (foundation Investigation
enrichment — foundation has no act_id rows). That row's identity is the
foundation Act UID, not a new UID; act_id keys on (act_uid, act_id_seq).

The fixture writes **2 rows** directly to `RDB_MODERN.dbo.nrt_investigation`
keyed on `public_health_case_uid` 20000100 (foundation) and 20050010
(v2). Those identities reference the foundation PHC + the v2 PHC; not
new UIDs.

The fixture writes **1 row** directly to
`RDB_MODERN.dbo.nrt_investigation_confirmation` keyed on
`public_health_case_uid = 20050010` (v2 only). Foundation Investigation
has no confirmation method — exercises the no-CM branch.

Unused UIDs in Investigation Tier 1 block (20050000-20050009,
20050012-20059999) are reserved for future Investigation Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Investigation
Tier 1.

### Tier 1 — Notification (20060000 - 20069999)

Allocated by Tier 1 Notification agent. Source:
`fixtures/10_subjects/notification.sql`. Coverage report:
`coverage/coverage_notification.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20060001 | (no symbolic — INVESTIGATION dim scaffolding) | `RDB_MODERN.dbo.INVESTIGATION.INVESTIGATION_KEY` | Fixture-environment scaffolding row that lets `sp_nrt_notification_postprocessing`'s `LEFT JOIN dbo.INVESTIGATION` resolve when Notification runs in isolation. CASE_UID=20000100 (foundation Investigation). The SP at lines 79-80 reads `inv.INVESTIGATION_KEY` directly (no COALESCE), and INVESTIGATION_KEY is NOT NULL on NOTIFICATION_EVENT, so the join MUST resolve to a row or the INSERT fails. NOT a coverage row for INVESTIGATION dimension — Investigation Tier 1's own postprocessing-SP-driven row is the canonical INVESTIGATION coverage. |
| 20060002 | (no symbolic — CONDITION dim scaffolding) | `RDB_MODERN.dbo.CONDITION.CONDITION_KEY` | Fixture-environment scaffolding row with CONDITION_CD='10110' (Hepatitis A, acute). Same rationale as INVESTIGATION_KEY=20060001 — the SP reads `cnd.CONDITION_KEY` directly and CONDITION_KEY is NOT NULL on NOTIFICATION_EVENT. RDB_MODERN.dbo.CONDITION is empty in baseline 6.0.18.1 (production populates it via `sp_nrt_srte_condition_code_postprocessing`, out of scope for this fixture). |
| 20060010 | @dbo_Act_notification_v2_uid | v2 Notification `act.act_uid`, `notification.notification_uid` | Class `NOTF`, mood `EVN`. Fully-attributed Notification variant for column coverage — every Tier-1 deferred column populated (case_class_cd 'C', case_condition_cd '10110', confirmation_method_cd 'LD', mmwr_week '14', mmwr_year '2026', rpt_sent_time, rpt_source_cd 'PP', record_status_cd 'COMPLETED'). |

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

### Tier 1 — Lab (20070000 - 20079999)

Allocated by Tier 1 Lab agent. Source:
`fixtures/10_subjects/lab.sql`. Coverage report:
`coverage/coverage_lab.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20070010 | @dbo_Act_lab_v2_order_uid | v2 Order observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='Order'`, `ctrl_cd_display_form='LabReport'`. cd='13950-1' (LOINC Hepatitis A IgM Ab → condition '10110' via baseline `nrt_srte_Loinc_condition`). Fully-attributed Lab Order variant for column coverage. |
| 20070011 | @dbo_Act_lab_v2_result_uid | v2 Result observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='Result'`, `ctrl_cd_display_form='LabReport'`. Lab-internal child of 20070010 via `act_relationship` (type_cd='COMP') AND `nrt_observation.report_observation_uid=20070010`. Carries result values (coded POS, numeric >1.10, date, FT/N text). |
| 20070020 | @dbo_Act_lab_v2_corder_uid | v2 followup C_Order observation `act.act_uid` / `observation.observation_uid` | Class `OBS`, mood `EVN`, `obs_domain_cd_st_1='C_Order'`. Drives `LAB_RPT_USER_COMMENT` path. NOT in @obs_ids — reached via v2 Order's `followup_observation_uid='20070020,20070021'` CSV. |
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
not new UIDs — they reference observation UIDs declared above.

The fixture also enriches foundation Lab (`act_uid=20000120`) with one
new `act_id` row (act_id_seq=1) and adds 2 `act_id` rows to v2 Order
(act_id_seq 1 and 2). `act_id` keys on (act_uid, act_id_seq); identities
are not new UIDs.

The fixture runs an IDENTITY-advance routine
(`SET IDENTITY_INSERT ON; INSERT high-key; OFF; DELETE`) against
`dbo.nrt_lab_test_result_group_key` and `dbo.nrt_lab_test_key` in
RDB_MODERN to work around a baseline-data quirk in 6.0.18.1
(IDENTITY counter NULL while seeded sentinel row exists at KEY=1). This
is not allocation of UIDs — it's IDENTITY-counter maintenance. See
`coverage_lab.md` BASELINE_QUIRK section.

### Tier 1 — Morbidity (20080000 - 20089999)

Allocated by Tier 1 Morbidity agent. Source:
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
(foundation Morbidity enrichment — foundation has none) and 1 `act_id`
row keyed on `act_uid=20080010` (v2 Morb Order). `act_id` keys on
(act_uid, act_id_seq); identities are not new UIDs.

The fixture writes **20 rows** directly to `RDB_MODERN.dbo.nrt_observation`
keyed on `observation_uid` 20000130 (foundation), 20080010 (v2 Order),
20080020/20080021 (v2 C_Order/C_Result), and 20080100..20080115 (16 INV/MRB
followups), plus 10 rows to `nrt_observation_coded`, 4 rows to
`nrt_observation_date`, 3 rows to `nrt_observation_txt`. Those
identities are not new UIDs — they reference observation UIDs declared
above.

No surrogate-key tables hand-authored — Morbidity uses inline
IDENTITY-temp-table allocation rather than IDENTITY-column nrt_*_key
tables, so no Lab-style IDENTITY-counter quirk applies.

### Tier 1 — Treatment (20100000 - 20109999)

Allocated by Tier 1 Treatment agent. Source:
`fixtures/10_subjects/treatment.sql`. Coverage report:
`coverage/coverage_treatment.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20100010 | @dbo_Act_treatment_v2_uid | v2 Treatment `act.act_uid` / `treatment.treatment_uid` / `treatment_administered.treatment_uid` | Class `TRMT`, mood `EVN`. Fully-attributed variant — Acyclovir composite. cd='1' (TREAT_COMPOSITE), treatment_drug='500' (TREAT_DRUG Acyclovir), route_cd='C0205531' (TREAT_ROUTE PO), dose_qty_unit_cd='mg' (TREAT_DOSE_UNIT), interval_cd='TID' (TREAT_FREQ_UNIT), effective_duration_unit_cd='D' (TREAT_DUR_UNIT). Drives populated path on every TREATMENT-dim column. |
| 20100020 | @dbo_Act_treatment_v3_uid | v3 Treatment `act.act_uid` / `treatment.treatment_uid` / `treatment_administered.treatment_uid` | Class `TRMT`, mood `EVN`. cd='OTH' free-text variant — drives the CUSTOM_TREATMENT CASE THEN branch in `sp_nrt_treatment_postprocessing` line 88. Other clinical columns NULL since v2 already covers their populated path. |

Unused UIDs in Treatment Tier 1 block (20100000-20100009,
20100011-20100019, 20100021-20109999) are reserved for future Treatment
Tier 1 / Tier 3 amendments. Do not allocate from this range outside of
Treatment Tier 1.

The fixture also writes:
- 1 row to `NBS_ODSE.dbo.act_id` keyed on `act_uid=20000150` (foundation Treatment enrichment — foundation has no act_id rows on Treatment).
- 1 row to `NBS_ODSE.dbo.treatment_administered` keyed on `treatment_uid=20000150` (foundation enrichment — required for the event SP's INNER JOIN at line 65 to surface the foundation Treatment row).
- 3 rows to `RDB_MODERN.dbo.nrt_treatment` keyed on `treatment_uid` 20000150 (foundation), 20100010 (v2), 20100020 (v3). Those identities are not new UIDs — they reference the foundation Treatment + v2/v3 entities above.

No surrogate-key tables hand-authored — Treatment's `nrt_treatment_key` IDENTITY counter is in a sane state at baseline (IDENT_CURRENT=2 after the seed sentinel row at d_treatment_key=1), so no Lab-style IDENTITY-counter quirk applies.

### Tier 1 — Vaccination (20110000 - 20119999)

Allocated by Tier 1 Vaccination agent. Source:
`fixtures/10_subjects/vaccination.sql`. Coverage report:
`coverage/coverage_vaccination.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20110010 | @dbo_Act_vaccination_v2_uid | v2 Vaccination `act.act_uid` / `intervention.intervention_uid` | Class `INTV`, mood `EVN`. Fully-attributed Vaccination variant — Hep A adult (VAC_NM cd='52'), aligned with foundation Investigation condition_cd='10110' (Hep A acute). Drives populated path on every D_VACCINATION column the postprocessing SP reads from nrt_vaccination. |

Unused UIDs in Vaccination Tier 1 block (20110000-20110009,
20110011-20119999) are reserved for future Vaccination Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Vaccination Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_vaccination`
keyed on `vaccination_uid` 20000160 (foundation) and 20110010 (v2). Those
identities are not new UIDs — they reference the foundation Vaccination
created in 00_foundation.sql plus the v2 entity above. No
`nrt_vaccination_answer` rows authored (NRT_METADATA_COLUMNS for
D_VACCINATION is empty in baseline; LDF-column dynamic PIVOT is a
no-op).

No surrogate-key tables hand-authored — Vaccination's
`nrt_vaccination_key` IDENTITY counter is in a sane state at baseline
(IDENT_CURRENT=2 after the seed sentinel row at d_vaccination_key=1),
so no Lab-style IDENTITY-counter quirk applies. The d_vaccination
postprocessing SP allocates surrogate keys via IDENTITY at lines
205-209.

### Tier 1 — Interview (20090000 - 20099999)

Allocated by Tier 1 Interview agent. Source:
`fixtures/10_subjects/interview.sql`. Coverage report:
`coverage/coverage_interview.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20090010 | @dbo_Act_interview_v2_uid | v2 Interview `act.act_uid` / `interview.interview_uid` | Class `ENC`, mood `EVN`. Fully-attributed Interview variant — interviewee_role_cd='PHYS' (NBS_INTVWEE_ROLE) to exercise F_INTERVIEW_CASE.PHYSICIAN_KEY CASE branch (sp_f_interview_case_postprocessing line 98). interview_status_cd='COMPLETE' (NBS_INTVW_STATUS), interview_type_cd='REINTVW' (NBS_INTERVIEW_TYPE_STDHIV), interview_loc_cd='PHCLINIC' (NBS_INTVW_LOC). |
| 20090020 | (no symbolic — note 1 nbs_answer_uid) | `nrt_interview_note.nbs_answer_uid` for v2 note 1 | Standalone identity value inside Interview's UID block; not a real NBS_ANSWER row UID (the SP only reads it as a column on nrt_interview_note + nrt_interview_note_key, no FK enforced). |
| 20090021 | (no symbolic — note 2 nbs_answer_uid) | `nrt_interview_note.nbs_answer_uid` for v2 note 2 | Same as above. |

Unused UIDs in Interview Tier 1 block (20090000-20090009,
20090011-20090019, 20090022-20099999) are reserved for future Interview
Tier 1 / Tier 3 amendments (e.g., Tier 3 v3 with
`interviewee_role_cd='SUBJECT'` to exercise IX_INTERVIEWEE_KEY THEN
branch). Do not allocate from this range outside of Interview Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_interview`
keyed on `interview_uid` 20000140 (foundation) and 20090010 (v2), and 2
rows to `RDB_MODERN.dbo.nrt_interview_note` keyed on
`interview_uid=20090010` with `nbs_answer_uid` 20090020 and 20090021.
Those identities are not new UIDs — they reference the foundation
Interview created in 00_foundation.sql plus the v2 entity above.

No `nrt_interview_answer` rows authored — `dbo.nrt_metadata_columns` is
empty for `TABLE_NAME='D_INTERVIEW'` in baseline 6.0.18.1, so the
postprocessing SP's dynamic PIVOT collapses to a no-op (verified). LDF
column coverage on D_INTERVIEW (IX_CONTACTS_NAMED_IND, IX_900_SITE_TYPE,
IX_INTERVENTION, IX_900_SITE_ID, IX_900_SITE_ZIP, CLN_CARE_STATUS_IXS)
is a Tier 3 LDF-coverage concern.

No surrogate-key tables hand-authored — the d_interview postprocessing
SP allocates `nrt_interview_key` IDENTITY at lines 206-210 and
`nrt_interview_note_key` IDENTITY at lines 476-481. IDENT_CURRENT
verified at 2 for both at baseline (clean state, sane).

### Tier 1 — Contact (20120000 - 20129999)

Allocated by Tier 1 Contact agent. Source:
`fixtures/10_subjects/contact.sql`. Coverage report:
`coverage/coverage_contact.md`.

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20120010 | @dbo_Act_contact_v2_uid | v2 Contact `act.act_uid` + `ct_contact.ct_contact_uid` | Class `ENC`, mood `EVN`. Fully-attributed Contact variant; every column the postprocessing SPs read from `nrt_contact` set non-NULL except CONTACT_STATUS (left NULL to side-step the event SP's `nbs_odse.dbo.fn_get_value_by_cd_codeset` 3-part-name bug — the function actually lives in RDB_MODERN.dbo). |
| 20120020 | @dbo_Entity_contact_party_uid | v2 contact-party `entity.entity_uid` + `person.person_uid` + `person.person_parent_uid` | Class `PSN`, person.cd `PAT`. Required because `ct_contact.contact_entity_uid` has a UNIQUE constraint (`UQ_CT_contact_3101`); foundation Patient (20000000) is consumed by foundation ct_contact's contact_entity_uid, so v2 needs a distinct entity. Subject_entity_uid + third_party_entity_uid have no UNIQUE constraint and remain pointed at foundation Patient. Minimal person row (no person_name). |

Unused UIDs in Contact Tier 1 block (20120000-20120009, 20120011-20120019,
20120021-20129999) are reserved for future Contact Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Contact Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_contact`
keyed on `contact_uid` 20000170 (foundation) and 20120010 (v2). Those
identities are not new UIDs — they reference the foundation Contact
created in 00_foundation.sql plus the v2 Act+ct_contact above.

No `nrt_contact_answer` rows authored — `dbo.nrt_metadata_columns` is
empty for `TABLE_NAME='D_CONTACT_RECORD'` in baseline 6.0.18.1, so the
postprocessing SP's dynamic PIVOT collapses to a no-op (verified). LDF
column coverage on D_CONTACT_RECORD (the 23 LDF/dynamic columns
including CTT_INITIATE_FOLLOWUP_DT, CTT_*_SEX_EXP_DT, CTT_HEIGHT,
CTT_HAIR, etc.) is a Tier 3 LDF-coverage concern.

No surrogate-key tables hand-authored — the d_contact_record
postprocessing SP allocates `nrt_contact_key` IDENTITY at lines 234-238.
IDENT_CURRENT verified at 2 at baseline (clean state, sane).

## Tier 2 — Links (21000000 - 21099999)

*Allocations made by Tier 2 agents.*

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

### Tier 2 — `Notification` edge (21000000 - 21000999)

Allocated by Tier 2 inv_notification agent. Source:
`fixtures/20_links/inv_notification.sql`. Coverage report:
`coverage/coverage_inv_notification.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.act_relationship`
(`type_cd='Notification'`, source_class_cd='NOTF', target_class_cd='CASE'):

1. foundation Notification (20000110) → foundation Investigation (20000100)
2. v2 Notification          (20060010) → v2 Investigation         (20050010)

`act_relationship`'s composite PK is (source_act_uid, target_act_uid,
type_cd) — the rows do **not** require their own surrogate UID, so no
UID is allocated from the 21000000-21000999 block. The block is reserved
for any future amendment (e.g., a Tier 3 v3 Notification variant whose
own act_uid would live in this Tier 2 block, or future surrogate-UID
needs).

Unused UIDs: 21000000-21000999 (entire block reserved). Do not allocate
from this range outside of the inv_notification edge agent.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables.
Coverage of `NOTIFICATION` and `NOTIFICATION_EVENT` is unlocked indirectly
by the post-edge re-run of `sp_nrt_notification_postprocessing` (in the
fixture's tail-EXEC), which now succeeds because (a) the edge wires the
ODSE act_relationship the SPs need, and (b) the merge orchestrator has
already populated `INVESTIGATION` (via Investigation Tier 1's chain),
`CONDITION` (via `sp_nrt_srte_condition_code_postprocessing`), and
`RDB_DATE` (via `sp_get_date_dim` — see INFRA_GAP in the coverage
report).

### Tier 2 — `LabReport` edge (21001000 - 21001999)

Allocated by Tier 2 lab_inv agent. Source:
`fixtures/20_links/lab_inv.sql`. Coverage report:
`coverage/coverage_lab_inv.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.act_relationship`
(`type_cd='LabReport'`, source_class_cd='OBS', target_class_cd='CASE'):

1. foundation Lab Order (20000120) → foundation Investigation (20000100)
2. v2 Lab Order         (20070010) → v2 Investigation         (20050010)

`act_relationship`'s composite PK is (source_act_uid, target_act_uid,
type_cd) — the rows do **not** require their own surrogate UID, so no
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
from this range outside of the lab_inv edge agent.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables.
Coverage of `LAB_TEST_RESULT.INVESTIGATION_KEY` is unlocked indirectly
by the post-edge re-runs of `sp_d_lab_test_postprocessing` and
`sp_d_labtest_result_postprocessing` (in the fixture's tail-EXEC).

### Tier 2 — `MorbReport` edge (21002000 - 21002999)

Allocated by Tier 2 morb_inv agent. Source:
`fixtures/20_links/morb_inv.sql`. Coverage report:
`coverage/coverage_morb_inv.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.act_relationship`
(`type_cd='MorbReport'`, source_class_cd='OBS', target_class_cd='CASE'):

1. foundation Morb Order (20000130) → foundation Investigation (20000100)
2. v2 Morb Order         (20080010) → v2 Investigation         (20050010)

`act_relationship`'s composite PK is (source_act_uid, target_act_uid,
type_cd) — the rows do **not** require their own surrogate UID, so no
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
(equality, not STRING_SPLIT — per the SP comment block at lines 204-210,
"For MorbReport observations, there can only be one associated
investigation"). Without the staging mirror, INVESTIGATION_KEY would
remain at sentinel 1.

Unused UIDs: 21002000-21002999 (entire block reserved). Do not allocate
from this range outside of the morb_inv edge agent.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables.
Coverage of `MORBIDITY_REPORT_EVENT` and `MORB_RPT_USER_COMMENT` is
unlocked indirectly by the post-edge re-run of
`sp_d_morbidity_report_postprocessing` (in the fixture's tail-EXEC).

### Tier 2 — `TreatmentToPHC` + `TreatmentToMorb` edges (21003000 - 21003999)

Allocated by Tier 2 treatment_inv agent. Source:
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
type_cd) — the rows do **not** require their own surrogate UID, so no
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
from this range outside of the treatment_inv edge agent.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables.
Coverage of `TREATMENT_EVENT.INVESTIGATION_KEY` / `CONDITION_KEY` for
foundation and v3 Treatment rows is unlocked indirectly by the post-edge
re-run of `sp_nrt_treatment_postprocessing` (in the fixture's tail-EXEC),
which now resolves those keys to non-sentinel values (foundation Inv key
3 / Hep A acute condition key 42).

The TreatmentToMorb rows are shape-consistency-only at this Tier 2
agent's level: the postprocessing SP reads
`nrt_treatment.morbidity_uid` (set by Tier 1 on v2 only); the
TreatmentToMorb act_relationship row is what `sp_treatment_event`
projects into the JSON `morbidity_uid` field that CDC-Debezium would
mirror into staging. Authoring the rows makes the ODSE graph correct
for the comparison test against MasterETL. MORB_RPT_KEY on v2 will
resolve to a real key only after the `morb_inv` Tier 2 agent's edge
is applied AND Morbidity's chain re-runs (a separate Tier 2 agent's
deliverable; not this fixture's responsibility).

### Tier 2 — `SubjOfPHC` edge (21004000 - 21004999)

Allocated by Tier 2 patient_phc agent. Source:
`fixtures/20_links/patient_phc.sql`. Coverage report:
`coverage/coverage_patient_phc.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.participation`
(`type_cd='SubjOfPHC'`, `act_class_cd='CASE'`, `subject_class_cd='PSN'`):

1. foundation Patient (entity_uid 20000000) AS subject of foundation Investigation (act_uid 20000100)
2. v2 Patient         (entity_uid 20020010) AS subject of v2 Investigation         (act_uid 20050010)

`participation`'s composite PK is (subject_entity_uid, act_uid,
type_cd) — the rows do **not** require their own surrogate UID, so no
UID is allocated from the 21004000-21004999 block. The block is reserved
for any future amendment (e.g., a Tier 3 v3 Patient or v3 Investigation
variant whose own UIDs would need to live in this Tier 2 block, or
future surrogate-UID needs).

Unused UIDs: 21004000-21004999 (entire block reserved). Do not allocate
from this range outside of the patient_phc edge agent.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_investigation_event` only (SP-callability check; the event SP's
JSON projection now contains the SubjOfPHC participation row in the
`person_participations` branch).

Honest coverage assessment: this edge is **shape-consistency-mostly at
Tier 1 isolation** — 0 RDB_MODERN dim/fact columns flip from
NULL/sentinel-1 to populated values. The participation row's value
lands in RDB_MODERN at Merge contract step 9 (Datamart SPs:
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

### Tier 2 — `PerAsReporterOfPHC` + `OrgAsReporterOfPHC` edges (21005000 - 21005999)

Allocated by Tier 2 reporter_phc agent. Source:
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
type_cd) — the rows do **not** require their own surrogate UID, so no
UID is allocated from the 21005000-21005999 block. The block is reserved
for any future amendment (e.g., Tier 3 cross-pair variants whose UIDs
would need to live in this Tier 2 block, or future surrogate-UID needs).

Unused UIDs: 21005000-21005999 (entire block reserved). Do not allocate
from this range outside of the reporter_phc edge agent.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_investigation_event` only (SP-callability check; the event SP's
JSON projection now contains all 4 reporter participation rows in the
`person_participations` / `organization_participations` branches —
verified for both foundation and v2 Investigations).

Honest coverage assessment: this edge is **shape-consistency-mostly at
Tier 1 isolation** — 0 RDB_MODERN dim/fact columns flip from
NULL/sentinel-1 to populated values. The participation rows' value
lands in RDB_MODERN at Merge contract step 9 (Datamart SPs:
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
A separate Tier 2 `nbs_act_entity_reporter` agent is required to
populate those columns. The two edge tables (participation vs
nbs_act_entity) are complementary — participation drives the datamart
SPs, while nbs_act_entity drives the event SP's reporter-uid
projection into nrt_investigation.

### Tier 2 — `PhysicianOfPHC` + `InvestgrOfPHC` edges (21006000 - 21006999)

Allocated by Tier 2 physician_phc agent. Source:
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
type_cd) — the rows do **not** require their own surrogate UID, so no
UID is allocated from the 21006000-21006999 block. The block is reserved
for any future amendment (e.g., distinct-Provider variants where the
Physician and Investigator are different Providers — common in
production but skipped in v1 per STRATEGY.md simplification).

Unused UIDs: 21006000-21006999 (entire block reserved). Do not allocate
from this range outside of the physician_phc edge agent.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_investigation_event` only (SP-callability check; the event SP's
JSON projection now contains the InvestgrOfPHC participation row's
`from_time` as `investigator_assigned_datetime` for both foundation
and v2 Investigations — verified by grep on the JSON output).

Honest coverage assessment: this edge is **shape-consistency-mostly at
Tier 1 isolation** — 0 RDB_MODERN dim/fact columns flip from
NULL/sentinel-1 to populated values. The participation rows' value
lands in RDB_MODERN at Merge contract step 9 (Datamart SPs:
`sp_public_health_case_fact_datamart_event` lines 1897-1903 / 1934-1962,
`sp_public_health_case_fact_datamart_update` lines 105-110 / 152-160).
Both SPs filter the participation INNER JOIN on
`TYPE_CD IN ('OrgAsReporterOfPHC','InvestgrOfPHC','PerAsReporterOfPHC',
'PhysicianOfPHC')` AND `RECORD_STATUS_CD='ACTIVE'`, populating
F_PAGE_CASE.PROVIDERNAME / PROVIDERPHONE (from PhysicianOfPHC) and
INVESTIGATORNAME / INVESTIGATORPHONE / INVESTIGATORASSIGNEDDATE (from
InvestgrOfPHC). Detail: `coverage/coverage_physician_phc.md`.

Note on `nrt_investigation.investigator_id` and `physician_id`:
spot-checked post-edge — both remain NULL. The investigation_event SP
at line 848 projects `par2.from_time` as `investigator_assigned_datetime`
ONLY (it does NOT project the subject_entity_uid as `investigator_id`).
The `investigator_id` and `physician_id` columns on `nrt_investigation`
are hand-authored staging columns; no SP derives them from the
InvestgrOfPHC / PhysicianOfPHC participation rows. PhysicianOfPHC is
not read by the investigation_event SP at all (verified by zero
matches for 'PhysicianOfPHC' in 056-sp_investigation_event-001.sql).
Documented as OUT_OF_SCOPE in the coverage report.

### Tier 2 — `SubOfVacc` + `PerformerOfVacc` edges (21007000 - 21007999)

Allocated by Tier 2 vaccination_links agent. Source:
`fixtures/20_links/vaccination_links.sql`. Coverage report:
`coverage/coverage_vaccination_links.md`.

The fixture authors **4 rows** in `nbs_odse.dbo.nbs_act_entity`
(2 SubOfVacc + 2 PerformerOfVacc):

SubOfVacc (`type_cd='SubOfVacc'`, act endpoint=Intervention/INTV,
entity endpoint=Person/PAT — Patient):

1. (21007000) foundation Vaccination (act_uid 20000160) ← foundation Patient (entity_uid 20000000)
2. (21007001) v2 Vaccination         (act_uid 20110010) ← v2 Patient         (entity_uid 20020010)

PerformerOfVacc (`type_cd='PerformerOfVacc'`, act endpoint=Intervention/INTV,
entity endpoint=Person/PSN — Provider):

3. (21007002) foundation Vaccination (act_uid 20000160) ← foundation Provider (entity_uid 20000010)
4. (21007003) v2 Vaccination         (act_uid 20110010) ← v2 Provider         (entity_uid 20010010)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 21007000 | (SubOfVacc foundation) | `nbs_act_entity.nbs_act_entity_uid` | foundation Vacc → foundation Patient. |
| 21007001 | (SubOfVacc v2)         | `nbs_act_entity.nbs_act_entity_uid` | v2 Vacc → v2 Patient. |
| 21007002 | (PerformerOfVacc foundation) | `nbs_act_entity.nbs_act_entity_uid` | foundation Vacc → foundation Provider. |
| 21007003 | (PerformerOfVacc v2)         | `nbs_act_entity.nbs_act_entity_uid` | v2 Vacc → v2 Provider. |

`nbs_act_entity` has a surrogate UID column
(`nbs_act_entity_uid bigint NOT NULL IDENTITY`) — **unlike all 7 prior
Tier 2 edge agents which used composite-PK tables (participation,
act_relationship)**, this agent allocates 4 surrogate UIDs from its
block. The fixture wraps the INSERT in
`SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` to insert
explicit UIDs (the IDENTITY column otherwise auto-allocates).

Unused UIDs: 21007004-21007999 (996 UIDs reserved). Do not allocate
from this range outside of the vaccination_links edge agent. Reserved
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
FROM clause — pre-edge it returns 0 rows; post-edge it returns 2 rows
(one per vaccination UID), with PATIENT_UID and PROVIDER_UID JSON
fields populated. **0 RDB_MODERN dim/fact column unlocks at Tier 1
isolation** (the postprocessing SPs read `nrt_vaccination` directly,
not `nbs_act_entity`); D_VACCINATION (3 rows, 21/21 columns) and
F_VACCINATION (2 rows, 6/6 columns) are byte-identical pre/post-edge.
Detail: `coverage/coverage_vaccination_links.md`.

The `PerformerOfVacc`-to-Organization variant (catalog row notes
"Person (provider) or Organization") is NOT authored here — per the
per-edge prompt: "Skip for v1 unless the SP coverage demonstrably
needs it." Result: post-edge ORGANIZATION_UID JSON field projects as
NULL on both vaccination rows. A future amendment within this block
can add a 5th row pointing to `entity_uid=20000020` (foundation
Organization) if Organization-performer event-SP-projection coverage
is needed.

The `act_relationship type_cd='1180'` VaccinationToPHC edge (used at
event SP line 1167 to project PHC_UID) is a **separate Tier 2
deliverable**, not owned by this agent. Currently PHC_UID projects as
NULL post-edge for both vaccination rows.

### Tier 2 — `IntrvwerOfInterview` + `IntrvweeOfInterview` + `OrgAsSiteOfIntv` edges (21008000 - 21008999)

Allocated by Tier 2 interview_links agent. Source:
`fixtures/20_links/interview_links.sql`. Coverage report:
`coverage/coverage_interview_links.md`.

The fixture authors **6 rows** in `nbs_odse.dbo.nbs_act_entity`
(2 IntrvwerOfInterview + 2 IntrvweeOfInterview + 2 OrgAsSiteOfIntv):

IntrvwerOfInterview (`type_cd='IntrvwerOfInterview'`, act endpoint=
Interview, entity endpoint=Person/PSN — Provider as interviewer):

1. (21008000) foundation Interview (act_uid 20000140) ← foundation Provider (entity_uid 20000010)
2. (21008001) v2 Interview         (act_uid 20090010) ← v2 Provider         (entity_uid 20010010)

IntrvweeOfInterview (`type_cd='IntrvweeOfInterview'`, act endpoint=
Interview, entity endpoint=Person/PSN — Patient as interviewee):

3. (21008002) foundation Interview (act_uid 20000140) ← foundation Patient (entity_uid 20000000)
4. (21008003) v2 Interview         (act_uid 20090010) ← v2 Patient         (entity_uid 20020010)

OrgAsSiteOfIntv (`type_cd='OrgAsSiteOfIntv'`, act endpoint=Interview,
entity endpoint=Organization/ORG — Org as interview site):

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
(`nbs_act_entity_uid bigint NOT NULL IDENTITY`) — same pattern as the
sibling `vaccination_links` agent (the eighth Tier 2 agent, also
`nbs_act_entity`). The fixture wraps the INSERT in
`SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` to insert
explicit UIDs.

Unused UIDs: 21008006-21008999 (994 UIDs reserved). Do not allocate
from this range outside of the interview_links edge agent. Reserved
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
surface the wired entity_uids — but the postprocessing SPs
(`sp_d_interview_postprocessing`,
`sp_f_interview_case_postprocessing`) read from
`nrt_interview` / `nrt_interview_note` / `nrt_interview_answer`
directly and do NOT traverse `nbs_act_entity`. So `D_INTERVIEW`
(2 rows, 18/24 + 6 LDF OUT_OF_SCOPE), `D_INTERVIEW_NOTE` (2 rows,
7/7), and `F_INTERVIEW_CASE` (2 rows, 8/10) column populations are
**byte-identical pre/post-edge**. **0 RDB_MODERN dim/fact column
unlocks at Tier 1 isolation** (LEFT JOINs in event SP); the value of
this edge is at Merge step 9 (Datamart-step) and the post-Kafka JSON
projection in production. Detail:
`coverage/coverage_interview_links.md`.

The `act_relationship type_cd='IXS'` Interview→Investigation edge
(used at event SP lines 85-86 to project INVESTIGATION_UID) is a
**separate Tier 2 deliverable** (`IXS` is `MISSING_FROM_SRTE` per
Phase B's catalog), not owned by this agent. Currently
INVESTIGATION_UID projects as NULL post-edge for both Interview rows.

### Tier 2 — `PerAsReporterOfPHC` + `OrgAsReporterOfPHC` + `HospOfADT` edges (21009000 - 21009999)

Allocated by Tier 2 phc_roles_nae agent (the **tenth** Tier 2 agent).
Source: `fixtures/20_links/phc_roles_nae.sql`. Coverage report:
`coverage/coverage_phc_roles_nae.md`.

The fixture authors **6 rows** in `nbs_odse.dbo.nbs_act_entity`
(2 PerAsReporterOfPHC + 2 OrgAsReporterOfPHC + 2 HospOfADT). This is
the THIRD `nbs_act_entity` Tier 2 edge agent (after `vaccination_links`
21007000-21007999 and `interview_links` 21008000-21008999) — same
`SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` wrap pattern.

PerAsReporterOfPHC (`type_cd='PerAsReporterOfPHC'`, act endpoint=Public
Health Case/CASE, entity endpoint=Person/PSN — Provider as
person-reporter):

1. (21009000) foundation Investigation (act_uid 20000100) → foundation Provider (entity_uid 20000010)
2. (21009001) v2 Investigation         (act_uid 20050010) → v2 Provider         (entity_uid 20010010)

OrgAsReporterOfPHC (`type_cd='OrgAsReporterOfPHC'`, act endpoint=CASE,
entity endpoint=Organization/ORG — Org as reporting source):

3. (21009002) foundation Investigation (act_uid 20000100) → foundation Organization (entity_uid 20000020)
4. (21009003) v2 Investigation         (act_uid 20050010) → v2 Organization         (entity_uid 20030010)

HospOfADT (`type_cd='HospOfADT'`, act endpoint=CASE, entity endpoint=
Organization/ORG — Org as hospital of ADT):

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
for v1 simplification (one canonical Org variant per tier — common
in production data per the per-edge prompt).

Unused UIDs: 21009006-21009999 (994 UIDs reserved). Do not allocate
from this range outside of the phc_roles_nae edge agent. Reserved
specifically for future Tier 3 expansion of the other 17 *OfPHC roles
in the same CASE-pivot subquery (lines 909-934 of
`056-sp_investigation_event-001.sql`) — `OrgAsClinicOfPHC`,
`CASupervisorOfPHC`, `ClosureInvestgrOfPHC`,
`DispoFldFupInvestgrOfPHC`, `FldFupInvestgrOfPHC`, `FldFupProvOfPHC`,
`FldFupSupervisorOfPHC`, `InitFldFupInvestgrOfPHC`,
`InitFupInvestgrOfPHC`, `InitInterviewerOfPHC`, `InterviewerOfPHC`,
`SurvInvestgrOfPHC`, `FldFupFacilityOfPHC`, `OrgAsHospitalOfDelivery`,
`PerAsProviderOfDelivery`, `PerAsProviderOfOBGYN`,
`PerAsProvideroOfPediatrics` (all MISSING_FROM_SRTE per Phase B).
A single Tier 3 agent can author all 17 deferred roles within this
block (e.g., 21009006-21009039 for 17 foundation rows + 21009040-
21009056 for 17 v2 rows = 34 rows).

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_investigation_event` only.

**Architectural distinction from `reporter_phc` (sixth Tier 2 agent,
21005000-21005999):** The `reporter_phc` agent authored 4
`participation` rows for `PerAsReporterOfPHC` + `OrgAsReporterOfPHC`
linking the same Provider/Organization/Investigation endpoints. THIS
agent authors **complementary** `nbs_act_entity` rows for the same
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
    at Merge step 9.
- `phc_roles_nae`'s nbs_act_entity rows feed:
  - `sp_investigation_event` CASE-pivot subquery
    `investigation_act_entity` at lines 909-934 → projects
    `person_as_reporter_uid` (line 913), `hospital_uid` (line 914),
    `org_as_reporter_uid` (line 932) into the JSON output.
  - `F_PAGE_CASE` consumes `hospital_uid` downstream at Merge step 9
    (datamart-side; out of scope here).

The two tables (`participation` and `nbs_act_entity`) are different
connective tables in the ODSE schema; each row in one does NOT imply
a row in the other. Authoring in only one would leave half the
projection NULL — `coverage_reporter_phc.md`'s "Coverage still
LINK_REQUIRED" section explicitly defers the `nbs_act_entity` rows
to a separate Tier 2 agent (this one).

Honest coverage assessment: **this edge is JSON-projection /
shape-consistency, NOT a Tier 1-isolation RDB_MODERN-coverage
unlock.** Like sibling `interview_links` (and unlike
`vaccination_links`'s INNER JOIN at vaccination event SP line 108),
the CASE-pivot subquery at `056-sp_investigation_event-001.sql:909`
joins `LEFT JOIN ... ON investigation_act_entity.nac_page_case_uid =
results.public_health_case_uid` — so `sp_investigation_event` returns
rows for both Investigations regardless of these edges. Pre-edge,
the projection columns `person_as_reporter_uid` / `hospital_uid` /
`org_as_reporter_uid` (and the 17 deferred Tier 3 `*_of_phc_uid`
columns) all project as NULL on every row. Post-edge, the 3 in-scope
columns surface the wired entity_uids:

- foundation Inv 20000100 → person_as_reporter=20000010,
  hospital=20000020, org_as_reporter=20000020.
- v2 Inv 20050010 → person_as_reporter=20010010,
  hospital=20030010, org_as_reporter=20030010.

**0 RDB_MODERN dim/fact column unlocks at Tier 1 isolation** — the
postprocessing SP (`sp_nrt_investigation_postprocessing`) reads
from `nrt_investigation` (hand-authored by Tier 1 Investigation) and
does NOT traverse `nbs_act_entity`. INVESTIGATION dimension column
populations are byte-identical pre/post-edge. Detail:
`coverage/coverage_phc_roles_nae.md`.

### Tier 2 — `SiteOfExposure` + `InvestgrOfContact` + `DispoInvestgrOfConRec` edges (21010000 - 21010999)

Allocated by Tier 2 contact_links agent (the **eleventh** Tier 2 agent).
Source: `fixtures/20_links/contact_links.sql`. Coverage report:
`coverage/coverage_contact_links.md`.

The fixture authors **6 rows** in `nbs_odse.dbo.nbs_act_entity`
(2 SiteOfExposure + 2 InvestgrOfContact + 2 DispoInvestgrOfConRec).
This is the FOURTH `nbs_act_entity` Tier 2 edge agent (after
`vaccination_links` 21007000-21007999, `interview_links`
21008000-21008999, `phc_roles_nae` 21009000-21009999) — same
`SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` wrap pattern.

All three `type_cd` values are MISSING_FROM_SRTE per Phase B
(`catalog/edge_types.md` rows 131-133 and 369-371). RTR's
`sp_contact_record_event` filters on the literal values directly at
lines 155-157 of `069-sp_contact_record_event-001.sql`.

SiteOfExposure (`type_cd='SiteOfExposure'`, act endpoint=Contact /
ct_contact (ENC), entity endpoint=Place — exposure site):

1. (21010000) foundation Contact (act_uid 20000170) → foundation Place (entity_uid 20000030)
2. (21010001) v2 Contact         (act_uid 20120010) → foundation Place (entity_uid 20000030) (no v2 Place; v1 simplification)

InvestgrOfContact (`type_cd='InvestgrOfContact'`, act endpoint=ENC,
entity endpoint=Person/PSN — Provider as investigator):

3. (21010002) foundation Contact (act_uid 20000170) → foundation Provider (entity_uid 20000010)
4. (21010003) v2 Contact         (act_uid 20120010) → v2 Provider         (entity_uid 20010010)

DispoInvestgrOfConRec (`type_cd='DispoInvestgrOfConRec'`, act endpoint=
ENC, entity endpoint=Person/PSN — Provider as disposition investigator;
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
from this range outside of the contact_links edge agent.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The fixture has
**no tail-EXEC** because `sp_contact_record_event` is BROKEN
UPSTREAM in baseline 6.0.18.1 — it references nonexistent
`nbs_odse.dbo.fn_get_value_by_cd_codeset` (the function actually lives
in `RDB_MODERN.dbo`). Verification is via direct `SELECT` against
`dbo.nbs_act_entity` (6 rows expected, 2 per `type_cd`).

Honest coverage assessment: **0 RDB_MODERN dim/fact column unlocks at
Tier 1 isolation OR in the merged sequence** — both because the event
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

### Tier 2 — `IXS` Interview→Investigation edge (21011000 - 21011999)

Allocated by Tier 2 interview_phc agent (the **twelfth** Tier 2 agent).
Source: `fixtures/20_links/interview_phc.sql`. Coverage report:
`coverage/coverage_interview_phc.md`.

The fixture authors **2 rows** in `nbs_odse.dbo.act_relationship` with
`type_cd='IXS'`. This is the SECOND `act_relationship` Tier 2 edge
agent (after `inv_notification` 21000000-21000999) — same composite-PK
pattern (no surrogate UID needed; block reserved for future
amendments).

`type_cd='IXS'` is **MISSING from baseline `NBS_SRTE.dbo.code_value_general`
`code_set_nm='AR_TYPE'`** per Phase B (`catalog/edge_types.md` row 338) —
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
from this range outside of the interview_phc edge agent.

This fixture writes **0 rows** directly to RDB_MODERN dim/fact tables
**and 0 rows to RDB_MODERN nrt_\* staging tables**. The tail-EXEC is
`sp_interview_event` only.

Honest coverage assessment: **0 RDB_MODERN dim/fact column unlocks at
Tier 1 isolation** — like sibling `interview_links`, the join at lines
85-86 of `065-sp_interview_event-001.sql` is a `LEFT JOIN`, so
`sp_interview_event` returns rows regardless of this edge.
`D_INTERVIEW` (2 rows, 18/24 + 6 LDF OUT_OF_SCOPE), `D_INTERVIEW_NOTE`
(2 rows, 7/7), and `F_INTERVIEW_CASE` (2 rows, 8/10) populations are
byte-identical pre/post-edge — the postprocessing SPs read from
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
remaining NULL field in the Interview event SP's JSON projection — now
populated by this edge.

## Tier 3 — Gap-driven SP coverage (22000000 - 22099999)

*Allocations made by Tier 3 agents (only on reported gaps).*

| Range | Agent / fixture | Status |
| --- | --- | --- |
| 22000000 - 22000999 | `multi_condition_investigations` (10 stubs, one per condition) | **allocated**. nrt_investigation-only shortcut rows for TB / Varicella / Mumps / Pertussis / Measles / Rubella / COVID-19 / Syphilis / HIV / Strep pneumoniae. |
| 22001000 - 22001999 | `tb_investigation_full_chain` (full ODSE + NBS_case_answer chain for TB) | **allocated**. See block detail below. |
| 22002000 - 22002999 | `varicella_investigation_full_chain` (full ODSE + NBS_case_answer chain for Varicella) | **allocated**. See block detail below. |
| 22003000 - 22003999 | `covid_investigation_full_chain` (full ODSE + NBS_case_answer chain for COVID-19) | **allocated**. See block detail below. |
| 22004000 - 22004999 | `std_hiv_investigation_full_chain` (full ODSE + Tier 2 + dimensional D_INV_* chain for STD Syphilis primary) | **allocated**. See block detail below. |
| 22005000 - 22005999 | `bmird_investigation_full_chain` (full ODSE + nrt_investigation_observation graph for BMIRD Strep pneumo invasive) | **allocated**. See block detail below. |
| 22006000 - 22006999 | `d_investigation_repeat` (full ODSE + nrt_page_case_answer repeating-block chain for Pertussis form) | **allocated**. See block detail below. |
| 22007000 - 22007999 | `zz_covid_case_datamart_enrich` (extra nrt_page_case_answer answers for existing COVID PHC 22003000 to lift COVID_CASE_DATAMART column coverage) | **reserved 2026-05-22**. Parallel agent A. |
| 22008000 - 22008999 | `zz_hepatitis_datamart_enrich` (full ODSE + answers chain for a Hep A Investigation to lift HEPATITIS_DATAMART column coverage) | **reserved 2026-05-22**. Parallel agent B. |
| 22009000 - 22009999 | `zz_var_datamart_enrich` (extra answers for existing Varicella PHC 22002000 to lift VAR_DATAMART column coverage beyond the curated 25-question set) | **reserved 2026-05-22**. Parallel agent C. |
| 22010000 - 22010999 | `zz_d_inv_place_repeat_enrich` (repeating-block place-of-exposure answers to populate D_INV_PLACE_REPEAT baseline columns) | **reserved 2026-05-22**. Parallel agent D. |
| 22011000 - 22011999 | `zz_tb_datamart_enrich` (extra TUB* answer rows for existing TB PHC 22001000 to lift TB_DATAMART / TB_HIV_DATAMART / D_TB_PAM column coverage) | **reserved 2026-05-24**. Parallel agent E. |
| 22012000 - 22012999 | `zz_std_hiv_datamart_enrich` (extra answers for existing STD PHC 22004000 to lift STD_HIV_DATAMART column coverage) | **reserved 2026-05-24**. Parallel agent F. |
| 22013000 - 22013999 | `zz_bmird_strep_pneumo_datamart_enrich` (extra answers / observation rows for existing BMIRD PHC 22005000 to lift BMIRD_STREP_PNEUMO_DATAMART column coverage) | **reserved 2026-05-24**. Parallel agent G. |
| 22014000 - 22014999 | `zz_d_investigation_repeat_more_blocks` (more repeating-block answer-row variants on PHC 22006000 across additional BLOCK_NM × seq combinations to lift D_INVESTIGATION_REPEAT row count and column coverage) | **reserved 2026-05-24**. Parallel agent H. |

### Tier 3 — TB Investigation full chain (22001000 - 22001999)

Allocated by Tier 3 tb_investigation_full_chain agent. Source:
`fixtures/30_sp_coverage/tb_investigation_full_chain.sql`. Coverage
report: `coverage/coverage_tb_full_chain.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22001000 | tb_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (all 23 answer rows) | The single TB Investigation full-chain anchor. condition_cd `10220` Tuberculosis, prog_area_cd `TB`, investigation_form_cd `INV_FORM_RVCT`. Adds the populated-PAM-answers path alongside the existing 22000010 stub's no-answers path. |
| 22001001 | tb_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22001100..22001112 | (13 d_topic feeders) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per excluded-from-TB-PAM-pivot TUB question (TUB119, TUB129, TUB154, TUB155, TUB156, TUB167, TUB225, TUB228, TUB229, TUB230, TUB235, TUB237, TUB114). |
| 22001113..22001122 | (10 D_TB_PAM main-pivot feeders) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | A curated 10-question minimum-viable set proving the wide D_TB_PAM pivot path works end-to-end. The remaining ~150 TUB questions are deferred to fixture-completeness Phase 2. |

Unused UIDs: 22001002..22001099, 22001123..22001999 (978 UIDs reserved). Do not allocate
from this range outside of the tb_investigation_full_chain agent.

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
require separate LDF-flagged answer rows — Phase 2 LDF work.

### Tier 3 — Varicella Investigation full chain (22002000 - 22002999)

Allocated by Tier 3 varicella_investigation_full_chain agent. Source:
`fixtures/30_sp_coverage/varicella_investigation_full_chain.sql`.
Coverage report: `coverage/coverage_varicella_full_chain.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22002000 | var_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (all 25 answer rows) | The single Varicella Investigation full-chain anchor. condition_cd `10030` Varicella (Chickenpox), prog_area_cd `GCD`, investigation_form_cd `INV_FORM_VAR`. Adds the populated-PAM-answers path alongside the existing 22000020 stub's no-answers path. |
| 22002001 | var_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22002100..22002124 | (25 VAR answer rows: VAR101, VAR103, VAR105, VAR111, VAR113, VAR122, VAR123, VAR126, VAR128, VAR129, VAR135, VAR139, VAR143, VAR150, VAR154, VAR156, VAR158, VAR170, VAR171, VAR174, VAR176, VAR178, VAR180, VAR188, VAR195) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | A curated minimum-viable set proving the D_VAR_PAM wide-pivot + D_RASH_LOC_GEN (VAR105 → 'Trunk') + D_PCR_SOURCE (VAR176 → 'Scab') paths work end-to-end. |

Unused UIDs: 22002002..22002099, 22002125..22002999 (974 UIDs reserved).
Do not allocate from this range outside of the
varicella_investigation_full_chain agent.

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
F_VAR_PAM and VAR_DATAMART populate at orchestrator Step 9 (gated on
EVENT_METRIC for var_datamart); the parent agent must extend the
orchestrator's PHC_UIDS to include 22002000 — see
`coverage/coverage_varicella_full_chain.md` ORCH_TODO section.
VAR_PAM_LDF remains 0 (requires LDF-flagged answer rows — Phase 2 LDF
work).

### Tier 3 — COVID-19 Investigation full chain (22003000 - 22003999)

Allocated by Tier 3 covid_investigation_full_chain agent. Source:
`fixtures/30_sp_coverage/covid_investigation_full_chain.sql`. Coverage
report: `coverage/coverage_covid_full_chain.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22003000 | covid_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (all 22 answer rows) | The single COVID Investigation full-chain anchor. condition_cd `11065` 2019 Novel Coronavirus, prog_area_cd `COV` (matching the stub convention; SRTE canonical is `GCD` — see coverage report SRTE_GAP), investigation_form_cd `PG_COVID-19_v1.1`. Adds the discrete + Type-3 repeating-block answers path alongside the existing 22000070 stub's no-answers path. |
| 22003001 | covid_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22003100..22003121 | (22 nbs_case_answer + nrt_page_case_answer pairs) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per COVID datamart-column-mapped question: 9 symptoms (FEVER, CHILLS_RIGORS, FATIGUE_MALAISE, HEADACHE, MYALGIA, ALT_MENTAL_STATUS, NAUSEA, DIARRHEA, ABDOMINAL_PAIN — all SNOMED-coded), 2 disposition (HOSPITAL_ICU_STAY, US_HC_WORKER_IND), 6 exposure (TRAVEL_DOMESTICALLY, TRAVEL_INTERNATIONAL, CRUISE_TRAVEL_EXP, AIR_TRAVEL_EXP, WORKPLACE_EXP, ANIMAL_EXPOSURE_IND), 3 Type-3 labs (TEST_TYPE, TEST_RESULT, PERFORMING_LAB_TYPE — `answer_group_seq_nbr='1'` → `_1` repeating-block columns), 2 comorbidity/status (HYPERTENSION, Symptomatic). |

Unused UIDs: 22003002..22003099, 22003122..22003999 (978 UIDs
reserved). Do not allocate from this range outside of the
covid_investigation_full_chain agent.

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
linked to the Investigation) — Phase 2 follow-on.

**Orchestrator pending action**: add 22003000 to `PHC_UIDS` in
`scripts/merge_and_verify.sh` line 446 so Step 9 picks up this
Investigation for `sp_covid_case_datamart_postprocessing`. Otherwise
the SP-tail-EXEC's effect persists but the merged run won't
re-execute against the full PHC list.

### Tier 3 — STD Syphilis Investigation full chain (22004000 - 22004999)

Allocated by Tier 3 std_hiv_investigation_full_chain agent. Source:
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
std_hiv_investigation_full_chain agent. Reserved for future expansion:
broader D_INV_* column coverage; sibling HIV-pediatric full-chain
(condition 10561, currently stubbed at 22000090); congenital syphilis
(condition 10316, PG_Congenital_Syphilis_Investigation — a separate
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
- `F_STD_PAGE_CASE` +1 row (after orchestrator Step 9 invokes
  `sp_f_std_page_case_postprocessing`)
- `INV_HIV` +1 row
- `STD_HIV_DATAMART` +1 row (after Step 9 invokes
  `sp_std_hiv_datamart_postprocessing`)

**Orchestrator pending actions** (Phase 2 follow-on, NOT this fixture's
responsibility):
1. Add 22004000 to `PHC_UIDS` in `scripts/merge_and_verify.sh` line 446
   so Step 9 picks up this Investigation for `sp_std_hiv_datamart_postprocessing`,
   `sp_f_std_page_case_postprocessing`, and the dyn_dm STD chain.
2. Fix orchestrator bug at line 475: `sp_f_std_page_case_postprocessing`
   is invoked with `@phc_ids = N'...'` — the SP's actual parameter is
   `@phc_id_list`. The 2>/dev/null masks the silent failure; the SP
   never runs in the orchestrated path. See report deliverable for
   detail.

### Tier 3 — BMIRD (Strep pneumo) Investigation full chain (22005000 - 22005999)

Allocated by Tier 3 bmird_investigation_full_chain agent. Source:
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
bmird_investigation_full_chain agent. Reserved for: more BMD/INV
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
- 1 sentinel seed to `RDB_MODERN.dbo.LDF_GROUP` (KEY=1, idempotent IF NOT EXISTS)
  — required by BMIRD_Case FK on LDF_GROUP_KEY.

It populates **3 of 5** BMIRD-cluster RDB_MODERN tables (BMIRD_Case +
BMIRD_STREP_PNEUMO_DATAMART + BMIRD_MULTI_VALUE_FIELD). The 2
remaining (`ANTIMICROBIAL`, `LDF_BMIRD`) require additional fixture
work — Antimicrobial needs root-observation + branch_id structure for
batch-entry observations (out of scope for v1; reserve 22005200-22005299
UID range); LDF_BMIRD needs LDF_DIMENSIONAL_DATA seed rows.

**Orchestrator integration** (applied alongside this fixture):
1. Add 22005000 to `PHC_UIDS` in `scripts/merge_and_verify.sh` line 446
   so Step 9 picks up this Investigation for `sp_bmird_case_datamart_postprocessing`,
   `sp_bmird_strep_pneumo_datamart_postprocessing`, and
   `sp_ldf_bmird_datamart_postprocessing`. **Done in same commit.**

### Tier 3 — d_investigation_repeat full chain (22006000 - 22006999)

Allocated by Tier 3 d_investigation_repeat agent. Source:
`fixtures/30_sp_coverage/d_investigation_repeat.sql`. Coverage
report: `coverage/coverage_d_investigation_repeat.md`.

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22006000 | inv_rept_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (all 24 answer rows) | The single Pertussis-form Investigation full-chain anchor for `sp_sld_investigation_repeat_postprocessing`. condition_cd `10190` Pertussis, prog_area_cd `VAC`, investigation_form_cd `PG_Pertussis_Investigation` — NOT in the SP's form_cd exclusion list at line 84. Adds the populated-repeating-block path alongside the existing 22000040 Pertussis stub's no-answers path. |
| 22006001 | inv_rept_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22006100..22006123 | (24 nbs_case_answer + nrt_page_case_answer pairs) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per repeating-block answer. Layout: 2 BLOCK_NMs (TRAVEL_BLOCK, EXPOSURE_BLOCK) × 3 answer_group_seq_nbr values × 4 data types (TEXT, CODED, DATE, NUMERIC) = 24 rows. Each row carries a unique RDB_COLUMN_NM so the SP's dynamic ALTER TABLE loop widens D_INVESTIGATION_REPEAT by 8 new columns. Fictional `nbs_question_uid` values (22006001..22006014) — the SP does not FK-validate against `nbs_question`. |

Unused UIDs: 22006002..22006099, 22006015..22006099, 22006124..22006999
(~975 UIDs reserved). Do not allocate from this range outside of the
d_investigation_repeat agent. Reserved for: more BLOCK_NMs, more
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

After this fixture applies and its tail-EXEC runs, the chain unblocks:
- `d_investigation_repeat`: 2 → 8 rows (+6 new dim rows; 1 PHC × 2 blocks × 3 seq) AND +8 dynamically-added RDB_COLUMN_NM columns (was 1/244, now ~11/252)
- `lookup_table_n_rept`: 0 → 1 row (was 0/2)
- `l_investigation_repeat_inc`: 0 → 6 rows (was 0/2)
- `l_investigation_repeat`: 1 → 7 rows (sentinel + 6 new)

**Orchestrator pending action** (Phase 2 follow-on, NOT this fixture's
responsibility): Neither `scripts/merge_and_verify.sh` nor
`sp_dyn_dm_main_postprocessing` invoke `sp_sld_investigation_repeat_postprocessing`
or its wrapper `sp_page_builder_postprocessing @rdb_table_name='D_INVESTIGATION_REPEAT'`.
Add a Step 8.5 invocation so the merged-fixture run populates the dim
end-to-end for every PHC_UIDS member that has repeating-block answers.
Without it, future fixture-authored Investigations with repeating-block
data will silently drop those answers in the orchestrated run.
| 22007000-22007999 | Pertussis full chain | 30 observations (20 coded + 1 txt + 1 num + 7 date) attached to PHC 22007000 via nrt_investigation_observation 'InvFrmQ' edges. Mirrors BMIRD template. Net headline coverage: 0pp (PERTUSSIS_CASE not in rtr_target_columns.md scope) but populates out-of-scope PERTUSSIS_SUSPECTED_SOURCE_FLD and PERTUSSIS_TREATMENT_FIELD. |
| 22008000-22008999 | LDF Foodborne | New Salmonellosis (10470) Investigation. 5 nrt_ldf_data rows on this PHC + 5 more on Mumps stub (22000030). Unlocked ldf_foodborne (0/12 -> 11/12) and grew ldf_dimensional_data + ldf_group. ldf_mumps stayed empty (cause TBD). |
