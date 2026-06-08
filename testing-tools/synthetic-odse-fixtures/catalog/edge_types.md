# Edge-type catalog

Generated: 2026-05-04
Baseline: 6.0.18.1 (post-liquibase)

## How to use

When a Tier 2 (link) fixture authors a row in one of these tables, it
must pick a `type_cd` (or analogous discriminator) listed in the
load-bearing section. The legal endpoint shapes (`source_class_cd` /
`target_class_cd` / `act_class_cd` / `subject_class_cd` / `class_cd`) are
stated alongside, with citations:

- "SRTE" means the value exists in `NBS_SRTE.dbo.code_value_general` for the
  named `code_set_nm`.
- "SP <file>:<line>" means the endpoint constraint is asserted in an RTR
  routine `WHERE` / `JOIN` clause, not in SRTE. All file paths are relative
  to `NEDSS-DataReporting/liquibase-service/src/main/resources/db/005-rdb_modern/routines/`.

Codes not listed here either don't appear in baseline SRTE, or no RTR SP
filters on them, so using one is a bug. Codes listed under
"Codes seen in SRTE but not used by RTR" are reference-only; Tier 2 fixtures
should not pick from that appendix without explicit authorization.

`MISSING_FROM_SRTE` findings (codes RTR filters on but absent from baseline
SRTE) are listed at the bottom of this file. Fixtures that need those codes
must seed them or accept that the corresponding RTR branch will not match
any row.

## dbo.act_relationship

Discriminators: `type_cd`, `source_class_cd`, `target_class_cd`. Both source
and target are Acts. `source_class_cd` / `target_class_cd` legal values come
from `code_set_nm = 'ACT_CLS'` in SRTE: `CASE` (Public health case), `NOTF`
(Notification), `OBS` (Observation), `TRMT` (Treatment), `INTV`
(Intervention), `ENC`, `PROC`, `REFR`, `SBADM`, `WKUP`, `DOCCLIN`.

| type_cd | source_class_cd | target_class_cd | Used by SP(s) | SRTE / SP source |
| --- | --- | --- | --- | --- |
| `LabReport` | `OBS` | `CASE` | `sp_observation_event` (lab → PHC association lookup); consumed downstream by `sp_d_lab_test_postprocessing`, `sp_d_labtest_result_postprocessing`, `sp_hepatitis_datamart_postprocessing`, `sp_lab100_datamart_postprocessing`, `sp_covid_lab_datamart_postprocessing` | SRTE `AR_TYPE`; SP filter at `055-sp_observation_event-001.sql:116-117` and `:430-431` |
| `MorbReport` | `OBS` | `CASE` | `sp_observation_event` (morb → PHC association lookup); consumed downstream by `sp_d_morbidity_report_postprocessing`, `sp_morbidity_report_datamart_postprocessing`, `sp_hepatitis_datamart_postprocessing` | SRTE `AR_TYPE`; SP filter at `055-sp_observation_event-001.sql:116-117` |
| `TreatmentToPHC` | `TRMT` | `CASE` | `sp_treatment_event` (treatment → PHC association lookup); consumed by `sp_nrt_treatment_postprocessing`, `sp_morbidity_report_datamart_postprocessing` | SRTE `AR_TYPE`; SP filter at `070-sp_treatment_event-001.sql:127-129` |
| `Notification` | `NOTF` | `CASE` | `sp_notification_event` (notification → PHC join); consumed by `sp_nrt_notification_postprocessing`, `sp_hepatitis_datamart_postprocessing`, `sp_event_metric_datamart_postprocessing` | SRTE `AR_TYPE`; endpoint constraint `source_class_cd='NOTF' AND target_class_cd='CASE'` at `064-sp_notification_event-001.sql:208-209`. (Note: SP joins on `act.source_act_uid = notif.notification_uid` without filtering `type_cd`. `Notification` is the conventional type_cd value used by upstream NBS rather than a hard SP filter, so any AR_TYPE code linking `NOTF`→`CASE` would join. Authoring fixtures with `Notification` keeps shape consistent with NBS data.) |
| `PHCInvForm` | `CASE` | `OBS` | `sp_public_health_case_fact_datamart_event` (PHC → InvForm observation lookup for INV128/INV132/INV133) | SRTE `AR_TYPE`; SP filter at `072-sp_public_health_case_fact_datamart_event-001.sql:404` and `:440` |
| `InvFrmQ` | `OBS` | `OBS` | `sp_nrt_investigation_postprocessing` (branch_type filter on observation tree); `sp_observation_event` (root/branch chain rooted by `ItemToRow`) | SRTE `AR_TYPE`; SP filter at `005-sp_nrt_investigation_postprocessing-001.sql:213` (`branch_type_cd = 'InvFrmQ'`) |
| `ItemToRow` | `OBS` | `OBS` | `sp_investigation_event` (observation root marker for repeating-block tree); `sp_observation_event` | SRTE `AR_TYPE`; SP filter at `056-sp_investigation_event-001.sql:405` (`root.type_cd = 'ItemToRow'`) |
| `SummaryForm` | `OBS` | `CASE` | `sp_investigation_event` (Summary Report Form → PHC); `sp_summary_report_case_postprocessing` (root_type filter); `sp_public_health_case_fact_datamart_event` | SRTE `AR_TYPE`; SP filter at `056-sp_investigation_event-001.sql:867` (`ar2.type_cd = 'SummaryForm'`), `150-sp_summary_report_case_postprocessing-001.sql:60`, `072-sp_public_health_case_fact_datamart_event-001.sql:1284` |
| `SummaryFrmQ` | `OBS` | `OBS` | `sp_investigation_event` (sum107 row → Summary_Report_Form parent); `sp_public_health_case_fact_datamart_event` | SRTE `AR_TYPE`; SP filter at `056-sp_investigation_event-001.sql:862` (`ar1.type_cd = 'SummaryFrmQ'`), `072-sp_public_health_case_fact_datamart_event-001.sql:1279` |
| `SummaryNotification` | `OBS` | `CASE` | `sp_summary_report_case_postprocessing` (root_type filter alongside `SummaryForm`) | SRTE `AR_TYPE`; SP filter at `150-sp_summary_report_case_postprocessing-001.sql:60` (`nio.root_type_cd IN ('SummaryForm','SummaryNotification')`) |

Endpoint notes for ambiguous rows:

- `LabReport` / `MorbReport`: source is always an `OBS` whose
  `obs_domain_cd_st_1` is `Order` (the lab order or morbidity report
  observation). Target is the `Public_health_case` Act (`CASE`). The same
  underlying type_cd is used regardless of obs domain because RTR
  disambiguates lab vs. morbidity by joining the source observation's
  `cd` and `obs_domain_cd_st_1`, not by AR type.
- `Notification` source/target classes are not enforced via a `type_cd`
  literal in any RTR SP. RTR only enforces `source_class_cd='NOTF' AND
  target_class_cd='CASE'`. The catalog row encodes the conventional
  upstream NBS type_cd value so Tier 2 fixtures match production shape.
- `InvFrmQ` and `ItemToRow` form a two-level tree on observations
  (root `ItemToRow` → branches `InvFrmQ`). Both endpoints are `OBS`.
- `SummaryFrmQ` connects an OBS row (sum107 question) to its parent
  Summary_Report_Form OBS. `SummaryForm` connects that
  Summary_Report_Form OBS to the PHC `CASE`.

## dbo.participation

Discriminators: `type_cd`, `act_class_cd`, `subject_class_cd`. Links an Act
(`act_uid`) to an Entity (`subject_entity_uid`). `act_class_cd` legal
values from SRTE `ACT_CLS`; `subject_class_cd` legal values from SRTE
`ENTITY_CLS` (`PSN`, `ORG`, `PLC`, `MAT`, `NLIV`, `GRP`).

| type_cd | act_class_cd | subject_class_cd | Used by SP(s) | SRTE / SP source |
| --- | --- | --- | --- | --- |
| `SubjOfPHC` | `CASE` | `PSN` | `sp_investigation_event`, `sp_notification_event`, `sp_public_health_case_fact_datamart_event`, `sp_public_health_case_fact_datamart_update` | SRTE `PAR_TYPE`; SP filter at `056-sp_investigation_event-001.sql:741`, `064-sp_notification_event-001.sql:102`, `072-sp_public_health_case_fact_datamart_event-001.sql:147` (`SUBJOFPHC`), `073-sp_public_health_case_fact_datamart_update-001.sql:54` |
| `SubjOfTrmt` | `TRMT` | `PSN` | `sp_treatment_event` (subject patient on a treatment) | SRTE `PAR_TYPE`; SP filter at `070-sp_treatment_event-001.sql:79-81` |
| `ProviderOfTrmt` | `TRMT` | `PSN` | `sp_treatment_event` (provider on a treatment). Note: SRTE has only `ProviderOfTrtmt` and `ReporterOfTreatment`; RTR uses an abbreviated form not in baseline SRTE. See MISSING_FROM_SRTE. | SP filter at `070-sp_treatment_event-001.sql:74-76` |
| `ReporterOfTrmt` | `TRMT` | `ORG` | `sp_treatment_event` (reporting organization on a treatment). MISSING_FROM_SRTE. | SP filter at `070-sp_treatment_event-001.sql:69-71` |
| `InvestgrOfPHC` | `CASE` | `PSN` | `sp_investigation_event` (PHC investigator name pivot); `sp_public_health_case_fact_datamart_event`/`_update` | SRTE `PAR_TYPE`; SP at `056-sp_investigation_event-001.sql:872, 919`, `072-sp_public_health_case_fact_datamart_event-001.sql:1899, 1952-1960`, `073-sp_public_health_case_fact_datamart_update-001.sql:106, 157-159` |
| `PerAsReporterOfPHC` | `CASE` | `PSN` | `sp_investigation_event` (person-as-reporter pivot); `sp_public_health_case_fact_datamart_event`/`_update` | SRTE `PAR_TYPE`; SP at `056-sp_investigation_event-001.sql:913`, `072-...:1900, 1944-1948`, `073-...:106, 155-156` |
| `OrgAsReporterOfPHC` | `CASE` | `ORG` | `sp_investigation_event`; `sp_public_health_case_fact_datamart_event`/`_update` (organization-as-reporter pivot) | SRTE `PAR_TYPE`; SP at `056-sp_investigation_event-001.sql:932`, `072-...:1898, 1917, 1964`, `073-...:106, 160, 213` |
| `PhysicianOfPHC` | `CASE` | `PSN` | `sp_public_health_case_fact_datamart_event`/`_update` (physician name/phone pivot). NOT referenced in `056-sp_investigation_event` (which uses `HospOfADT` etc.); appears in DM SPs as the canonical "Provider Name" source. | SRTE `PAR_TYPE`; SP at `072-...:1901, 1936-1940`, `073-...:106, 153-154` |
| `HospOfADT` | `CASE` | `ORG` | `sp_investigation_event` (hospital pivot for Investigation form) | SRTE `PAR_TYPE`; SP at `056-sp_investigation_event-001.sql:914` |
| `OrgAsClinicOfPHC` | `CASE` | `ORG` | `sp_investigation_event` (ordering facility pivot). MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:915` |
| `CASupervisorOfPHC` | `CASE` | `PSN` | `sp_investigation_event` (CA supervisor pivot). MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:916` |
| `ClosureInvestgrOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:917` |
| `DispoFldFupInvestgrOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:918` |
| `FldFupInvestgrOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:919` |
| `FldFupProvOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:920` |
| `FldFupSupervisorOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:921` |
| `InitFldFupInvestgrOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:922` |
| `InitFupInvestgrOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:923` |
| `InitInterviewerOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:924` |
| `InterviewerOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:925` |
| `SurvInvestgrOfPHC` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:926` |
| `FldFupFacilityOfPHC` | `CASE` | `ORG` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:927` |
| `OrgAsHospitalOfDelivery` | `CASE` | `ORG` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:928` |
| `PerAsProviderOfDelivery` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:929` |
| `PerAsProviderOfOBGYN` | `CASE` | `PSN` | `sp_investigation_event`. MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:930` |
| `PerAsProvideroOfPediatrics` | `CASE` | `PSN` | `sp_investigation_event` (note the typo `Provideroo`, matching the SP literal exactly). MISSING_FROM_SRTE. | SP filter at `056-sp_investigation_event-001.sql:931` |

Notes:

- `act_class_cd` is always `CASE` for the `*OfPHC`/`*OfPhc` family; the
  participation row's `subject_entity_uid` points to a `Person` or
  `Organization` row, with `subject_class_cd` matching that entity's class.
- The `056-sp_investigation_event` SP MAX-CASE pivot (lines 913–932) reads
  every PAR_TYPE row hung off the PHC and selects the entity_uid for each
  named code; it does not enforce `subject_class_cd`. The endpoint-class
  constraint on each row is therefore inferred from the column name (e.g.,
  `org_as_reporter_uid` is an organization, `physician_of_phc_uid` is a
  person). Fixture authors must keep `subject_class_cd` consistent with the
  intended entity class so downstream joins (e.g.,
  `nbs_odse.dbo.organization` joins on `subject_entity_uid`) succeed.

## dbo.nbs_act_entity

Discriminators: `type_cd`, plus the implicit endpoint shapes (`act_uid` is
always an Act, `entity_uid` is always an Entity). The table has no
`source_class_cd` / `target_class_cd` columns; endpoint shapes are derived
from how the SP joins `act_uid` against `intervention` / `ct_contact` and
`entity_uid` against `person` / `organization`.

| type_cd | Act endpoint (act_uid) | Entity endpoint (entity_uid) | Used by SP(s) | SRTE / SP source |
| --- | --- | --- | --- | --- |
| `SubOfVacc` | `Intervention` (vaccination) | `Person` (patient) | `sp_vaccination_event` | SRTE `PAR_TYPE`; SP filter at `071-sp_vaccination_event-001.sql:108`, `:1156` |
| `PerformerOfVacc` | `Intervention` (vaccination) | `Person` (provider) or `Organization` | `sp_vaccination_event` | SRTE `PAR_TYPE`; SP filter at `071-sp_vaccination_event-001.sql:1135`, `:1146` |
| `SiteOfExposure` | `CT_contact` (contact record) | `Place` (exposure site) | `sp_contact_record_event` | SP filter at `069-sp_contact_record_event-001.sql:155`. MISSING_FROM_SRTE (not in any reference set in baseline SRTE). |
| `InvestgrOfContact` | `CT_contact` | `Person` (investigator) | `sp_contact_record_event` | SP filter at `069-sp_contact_record_event-001.sql:156`. MISSING_FROM_SRTE. |
| `DispoInvestgrOfConRec` | `CT_contact` | `Person` (disposition investigator) | `sp_contact_record_event` | SP filter at `069-sp_contact_record_event-001.sql:157`. MISSING_FROM_SRTE. |
| `IntrvwerOfInterview` | `Interview` | `Person` (interviewer) | `sp_interview_event` | SP filter at `065-sp_interview_event-001.sql:89`. MISSING_FROM_SRTE. |
| `IntrvweeOfInterview` | `Interview` | `Person` (interviewee) | `sp_interview_event` | SP filter at `065-sp_interview_event-001.sql:95`. MISSING_FROM_SRTE. |
| `OrgAsSiteOfIntv` | `Interview` | `Organization` (interview site) | `sp_interview_event` | SP filter at `065-sp_interview_event-001.sql:92`. MISSING_FROM_SRTE. |

Notes:

- Vaccination's `nbs_act_entity` rows attach to `intervention.intervention_uid`,
  not directly to a vaccination Act in `act`. The SP joins
  `nbs_act_entity.act_uid = src.VACCINATION_UID` where
  `src.VACCINATION_UID` came from `intervention`.
- Interview rows attach to `interview.interview_uid`. The interview SP joins
  three `nbs_act_entity` rows per interview (interviewer, interviewee, site).
- All five `*Interview*` / `*Contact*` codes are MISSING_FROM_SRTE (see
  MISSING_FROM_SRTE section). RTR's joins on these are `LEFT JOIN`s, so the
  absence does not crash the SP, but downstream columns
  (`PROVIDER_CONTACT_INVESTIGATOR_UID` etc.) will be NULL whenever the
  fixture lacks the matching `nbs_act_entity` row.

## dbo.entity_locator_participation

Discriminators: `class_cd` (locator class), `use_cd` (locator use), `type_cd`
(locator role). RTR filters primarily on `class_cd` × `use_cd` to pivot
postal/tele/email/fax locators per entity.

`class_cd` legal values, confirmed exactly three from SRTE `EL_CLS`:

| class_cd | Description |
| --- | --- |
| `PST` | Postal locator (joins `postal_locator`) |
| `TELE` | Telecommunications locator (joins `tele_locator`) |
| `PHYS` | Physical locator (joins `physical_locator`) |

`use_cd` legal values from SRTE `EL_USE` (11 values total): `AN`, `BIR`,
`DTH`, `EC`, `H`, `MC`, `OC`, `PB`, `SB`, `TMP`, `WP`. RTR filter sites:

| (class_cd, use_cd, cd) tuple | Used by SP(s) | SP source |
| --- | --- | --- |
| (`PST`, `WP`, *) | `sp_organization_event`, `sp_provider_event` (work address) | `051-sp_organization_event-001.sql:96-97`, `052-sp_provider_event-001.sql:99` |
| (`TELE`, `WP`, *) | `sp_organization_event` (work phone) | `051-sp_organization_event-001.sql:118-119` |
| (`TELE`, `WP`, `FAX`) | `sp_organization_event` (work fax) | `051-sp_organization_event-001.sql:131-133` |
| (`PST`, `H` \| `BIR`, *) | `sp_patient_event` (home / birth address) | `054-sp_patient_event-001.sql:251-252` |
| (`TELE`, *, *) | `sp_patient_event` (any tele locator) | `054-sp_patient_event-001.sql:265` |
| (`TELE`, *, `NET`) | `sp_patient_event` (email, `cd='NET'`) | `054-sp_patient_event-001.sql:278-279` |
| (`TELE`, *, *) | `sp_provider_event` (any tele locator) | `052-sp_provider_event-001.sql:144` |
| (`TELE`, *, *) | `sp_place_event` | `068-sp_place_event-001.sql:121` |

`type_cd` (locator role on the entity, e.g., `BIR`/`H`/`WP` analogue) is not
filtered on by any RTR SP; RTR uses `use_cd` for the same conceptual
purpose. SRTE `EL_TYPE` has 8 values; treat as reference-only.

Sanity check: `class_cd` = exactly `{PST, TELE, PHYS}` ← confirmed against
`SELECT code FROM nbs_srte.dbo.code_value_general WHERE code_set_nm='EL_CLS'`.

## dbo.role

Discriminators: `cd` (role code; RTR aliases this as `role_cd` in SP
selects; the actual column name in `nbs_odse.dbo.role` is `cd`),
`subject_class_cd`, `scoping_class_cd`.

No RTR SP filters on a specific `role.cd` value. The only RTR consumer of
`dbo.role` is `055-sp_observation_event-001.sql:202-228`, which left-joins
the role table to obtain `r.cd AS [role_cd]`, `r.subject_class_cd`, and
`r.scoping_class_cd` for the person participating in the observation, then
emits them as JSON for downstream postprocessing. The values are passed
through, not filtered.

Therefore:

- For load-bearing fixtures: any `cd` value from SRTE `RL_TYPE` (171 codes,
  generic role types like `OP`, `RPT`, `LABP`, `PHYS`, `NRS`, `PHN`),
  `RL_TYPE_PRV` (24 provider-specific codes, e.g., `OP`, `LABP`, `RPT`),
  or `RL_TYPE_ORG` (114 organization-specific codes) is acceptable.
- `subject_class_cd` should be `PSN` (the role table is read only against
  `person` joins via `r.subject_entity_uid = person.person_uid`).
- `scoping_class_cd` is typically `ORG` (the scoping organization the
  person performs the role at) or NULL for self-scoped roles.

| cd (role_cd) | subject_class_cd | scoping_class_cd | Used by SP(s) | SRTE source |
| --- | --- | --- | --- | --- |
| any from `RL_TYPE` / `RL_TYPE_PRV` / `RL_TYPE_ORG` | `PSN` | `ORG` or NULL | `sp_observation_event` (read-through, no filter) | SRTE `RL_TYPE`, `RL_TYPE_PRV`, `RL_TYPE_ORG` |

For Tier 2 fixture authoring, prefer codes that match the fixture's intent:
`OP` (Ordering Provider) for a lab observation's reporting
provider, `RPT` (Reporter) for a reporting provider, `LABP` (Laboratory
Provider) for a lab. These are stable, widely-used codes in baseline SRTE.

## dbo.act_id

Discriminators: `type_cd`, `assigning_authority_cd` (with companion
`assigning_authority_desc_txt` / `assigning_authority_id_type`).

No RTR SP filters on a specific `act_id.type_cd` or
`assigning_authority_cd` value. RTR consumers:

- `056-sp_investigation_event-001.sql:410-421`: emits all `act_id` rows
  (`act_uid = phc.public_health_case_uid`) into JSON, with
  `act_id.type_cd`, `act_id.root_extension_txt`,
  `act_id.assigning_authority_cd` (implicit via outer scope) preserved.
- `055-sp_observation_event-001.sql:284-300`: same shape for observation
  act_ids.

Legal `type_cd` values come from SRTE `AI_TYPE` (11 codes): `CHART`, `EII`,
`FILENO`, `FN`, `LID`, `MC`, `OTH`, `PN`, `SID`, `STATE`, `U`. Legal
`assigning_authority_cd` values from SRTE `AI_AUTH` (multiple codes;
verify per fixture if a specific authority is needed).

| type_cd | assigning_authority_cd | Used by SP(s) | SRTE source |
| --- | --- | --- | --- |
| any from `AI_TYPE` (RTR is read-through) | any from `AI_AUTH`, or NULL | `sp_investigation_event`, `sp_observation_event` (read-through) | SRTE `AI_TYPE`, SRTE `AI_AUTH` |

Tier 2 default: `type_cd='LID'` (Local ID) with
`root_extension_txt = '<local-key-string>'` and `assigning_authority_cd=NULL`.
This matches the conventional NBS shape and avoids tripping any
downstream code-set lookup.

## dbo.entity_id

Discriminators: `type_cd`, `assigning_authority_cd`. The `class_cd` mentioned
in the Phase B prompt is not a column on `entity_id`; the entity's class is
inherited from the parent `entity` row (`person.cd='PAT'/'PRV'`,
`organization`, `place`). RTR's filter is on `type_cd` indirectly via the
SRTE join (`code_set_nm='EI_TYPE'`).

RTR consumers:

- `055-sp_observation_event-001.sql:227-230`: joins `entity_id` to
  `code_value_general` on `code_set_nm='EI_TYPE'` to translate
  `entity_id.type_cd` to a description; no value filter.
- `054-sp_patient_event-001.sql:343-350`: emits all `entity_id` rows for the
  patient as JSON, including `type_cd` and `assigning_authority_cd`.
- `052-sp_provider_event-001.sql:177-182`: same for provider.
- `051-sp_organization_event-001.sql:138-148`: same for organization, with a
  case branch `WHEN ei.type_cd = 'FI' AND ei.assigning_authority_cd IS NOT
  NULL THEN <lookup against code_set_nm='EI_AUTH_ORG'>`. Facility
  identifiers (`type_cd='FI'`) are the only `entity_id` rows with a
  data-driven branch in RTR.

Per-entity-class legal `type_cd` values from SRTE:

| Entity class | code_set_nm | Sample `type_cd` codes |
| --- | --- | --- |
| Patient | `EI_TYPE_PAT` | `AN`, `APT`, `CI`, `DL`, `IIS`, `MA`, `MC`, `MR`, `MO`, `OTH`, `PI`, `PIN`, `PN`, `PSID`, `PT`, `RW`, `SS`, `VS`, `WC` (19 codes) |
| Provider | `EI_TYPE_PRV` | `EI`, `EN`, `LN`, `NH`, `NPI`, `OTH`, `PN`, `PRN`, `SL`, `UPIN` (10 codes) |
| Organization | `EI_TYPE_ORG` | `ABC`, `CLIA`, `FI`, `MID`, `NE`, `NH`, `OTH`, `PSID`, `XX` (9 codes) |
| Generic | `EI_TYPE` | superset (24+ codes) |

Load-bearing entries:

| type_cd | Owning entity class | assigning_authority_cd | Used by SP(s) | SRTE / SP source |
| --- | --- | --- | --- | --- |
| `FI` | Organization | from `EI_AUTH_ORG` (e.g., facility OID), required for the case branch | `sp_organization_event` (case branch on `ei.type_cd='FI' AND ei.assigning_authority_cd IS NOT NULL`) | SRTE `EI_TYPE_ORG`; SP filter at `051-sp_organization_event-001.sql:146-148` |
| any from `EI_TYPE_PAT` | Patient | optional from `AI_AUTH`/`ASSGN_AUTHORITY` | `sp_patient_event` (read-through) | SRTE `EI_TYPE_PAT` |
| any from `EI_TYPE_PRV` | Provider | optional | `sp_provider_event` (read-through) | SRTE `EI_TYPE_PRV` |

Tier 2 defaults:

- Patient identifier: `type_cd='PI'` (Patient Internal Identifier) or
  `type_cd='MR'` (Medical record number) with a non-null
  `root_extension_txt` and `assigning_authority_cd` set to a baseline-SRTE
  value if testing the EI_AUTH lookup, otherwise NULL.
- Provider identifier: `type_cd='NPI'` with a 10-digit
  `root_extension_txt`.
- Organization (when exercising the FI branch): `type_cd='FI'` with
  `assigning_authority_cd` set to a value present in
  `code_set_nm='EI_AUTH_ORG'` so the `fn_get_value_by_cvg` lookup resolves.

## Codes seen in SRTE but not used by RTR SPs

Reference-only. Tier 2 fixtures should not pick from this appendix without
explicit authorization. Listed counts come from `SELECT COUNT(DISTINCT code)
FROM code_value_general WHERE code_set_nm = '<set>'` against baseline SRTE.

| Table | code_set_nm | Total codes in SRTE | Total used by RTR | Reason for inclusion |
| --- | --- | --- | --- | --- |
| `act_relationship.type_cd` | `AR_TYPE` | 81 | 11 | Most AR types (e.g., `APND`, `AUTH`, `CHRG`, `COMP`, `INST`, `Intervention`, `InvFrmHosp`, `MORBInvFrm`, `TrmtItemToRow`, `1180` "Vaccination to PHC", `BIR`) are legacy MasterETL or non-RTR concepts. Sample unused: `APND`, `AUTH`, `BIR`, `CHRG`, `CIND`, `COMP`, `COVBY`, `CREDIT`, `CST`, `DerivedObs`, `DISP`, `DOC`, `EXPL`, `FLFS`, `GEN`, `GenericObs`, `GEVL`, `GOAL`, `INST`, `Intervention`, `InterventionVacc`, `InvFrmHosp`, `ITGT`, `LAB105`, `LabGenObs`, `LabMicroObs`, `LIMIT`, `MORBInvFrm`, `PrimQ`, `RISK`, `SummaryRowItem`, `TRIG`, `TrmtItemToRow`, `1180`. |
| `participation.type_cd` | `PAR_TYPE` | 70 | ~9 (8 in SRTE + 1 alt) | Most PAR types are HL7 / NBS upstream codes RTR doesn't pivot on. Sample unused (in SRTE but not filtered by any RTR routine): `ASS`, `AUT`, `BBY`, `BEN`, `CBC`, `ChronicCareFac`, `CNS`, `CollegeUniversity`, `CON`, `CSM`, `CST`, `DaycareFac`, `DEV`, `DIR`, `DON`, `DST`, `ENT`, `ESC`, `HospOfBirth`, `HospOfCulture`, `HospOfMorbObs`, `INF`, `LOC`, `MotherOfInvSubj`, `MTH`, `NOK`, `NRD`, `ODV`, `ORD`, `ORG`, `OTH`, `PAT`, `PATSBJ`, `PhysicianOfMorb`, `PRD`, `PRF`, `ProviderOfTrtmt` (note the spelling; RTR uses `ProviderOfTrmt` instead, see MISSING_FROM_SRTE), `PYL`, `RDV`, `ReAdmHosp`, `REF`, `ReporterOfMorbReport`, `ReporterOfPHC`, `ReporterOfTreatment` (RTR uses `ReporterOfTrmt`), `ReportingSourceOfPHC`, `REV`, `RML`, `SBJ`, `SPC`, `SPV`, `SubjOfGenObs`, `SubjOfMorbReport`, `TPA`, `TransferHosp`, `TRC`, `VaccGiven`, `VIA`, `VRF`, `WIT`. |
| `entity_locator_participation.use_cd` | `EL_USE` | 11 | 4 (`H`, `BIR`, `WP`, plus `cd='NET'`/`'FAX'` overlaid on TELE) | Unused: `AN`, `DTH`, `EC`, `MC`, `OC`, `PB`, `SB`, `TMP`. None referenced by any RTR routine. |
| `role.cd` | `RL_TYPE` (171), `RL_TYPE_PRV` (24), `RL_TYPE_ORG` (114) | 309 total | 0 hard-filtered | RTR reads role rows through; no specific code is required for any SP branch. |
| `act_id.type_cd` | `AI_TYPE` | 11 | 0 hard-filtered | RTR reads act_id rows through (`056-sp_investigation_event:410`, `055-sp_observation_event:288`); no specific code is required. |
| `entity_id.type_cd` | `EI_TYPE` (24+), `EI_TYPE_PAT` (19), `EI_TYPE_PRV` (10), `EI_TYPE_ORG` (9) | ~62 distinct | 1 hard-filtered (`FI` for orgs) | All other codes are read-through. |

## MISSING_FROM_SRTE

Codes that RTR SPs filter on with literal `WHERE type_cd = '<code>'` /
`WHERE TYPE_CD = '<code>'` clauses but which are **NOT** present in the
matching baseline SRTE code set. Verified by:

```sql
SELECT code_set_nm, code FROM nbs_srte.dbo.code_value_general
 WHERE code IN (...)
```

Run against baseline 6.0.18.1 post-liquibase. Each finding is a real
fixture-authoring concern: if Tier 2 inserts an ODSE row using one of these
type_cds, the row is internally referentially-broken (no SRTE parent), but
RTR's joins are mostly LEFT JOINs that won't crash; they silently
NULL-out the affected dimension columns. For comparison testing this is
fine as long as both RDB and RDB_MODERN are populated equivalently, but
the underlying SRTE gap should be flagged to the reference-data owner.

### MISSING_FROM_SRTE: act_relationship.type_cd

| code | SP filter | Cited at | Notes |
| --- | --- | --- | --- |
| `IXS` | `sp_interview_event` (act_relationship link from interview to subject) | `065-sp_interview_event-001.sql:86` | Found in `BUS_OBJ_TYPE` and `INFO_SOURCE_COVID` code sets but **NOT** in `AR_TYPE`. |
| `TreatmentToMorb` | `sp_treatment_event` (treatment → morbidity report) | `070-sp_treatment_event-001.sql:86` | Not in any code set in baseline SRTE. RTR also defines `TreatmentToPHC` analogously, which IS in SRTE. |

### MISSING_FROM_SRTE: participation.type_cd

| code | SP filter | Cited at | Notes |
| --- | --- | --- | --- |
| `OrgAsClinicOfPHC` | `sp_investigation_event` (ordering facility pivot) | `056-sp_investigation_event-001.sql:915` | Not in any code set. |
| `CASupervisorOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:916` | Not in any code set. |
| `ClosureInvestgrOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:917` | Not in any code set. |
| `DispoFldFupInvestgrOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:918` | Not in any code set. |
| `FldFupInvestgrOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:919` | Not in any code set. |
| `FldFupProvOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:920` | Not in any code set. |
| `FldFupSupervisorOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:921` | Not in any code set. |
| `InitFldFupInvestgrOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:922` | Not in any code set. |
| `InitFupInvestgrOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:923` | Not in any code set. |
| `InitInterviewerOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:924` | Not in any code set. |
| `InterviewerOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:925` | Not in any code set. |
| `SurvInvestgrOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:926` | Not in any code set. |
| `FldFupFacilityOfPHC` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:927` | Not in any code set. |
| `OrgAsHospitalOfDelivery` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:928` | Not in any code set. |
| `PerAsProviderOfDelivery` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:929` | Not in any code set. |
| `PerAsProviderOfOBGYN` | `sp_investigation_event` | `056-sp_investigation_event-001.sql:930` | Not in any code set. |
| `PerAsProvideroOfPediatrics` | `sp_investigation_event` (note typo `Provideroo`) | `056-sp_investigation_event-001.sql:931` | Not in any code set. |
| `ProviderOfTrmt` | `sp_treatment_event` | `070-sp_treatment_event-001.sql:74` | SRTE has `ProviderOfTrtmt` (with a `t` after `Tr`); RTR uses the abbreviated `ProviderOfTrmt`. |
| `ReporterOfTrmt` | `sp_treatment_event` | `070-sp_treatment_event-001.sql:69` | SRTE has `ReporterOfTreatment` and `ReporterOfMorbReport`; RTR uses `ReporterOfTrmt`. |

### MISSING_FROM_SRTE: nbs_act_entity.type_cd

| code | SP filter | Cited at | Notes |
| --- | --- | --- | --- |
| `SiteOfExposure` | `sp_contact_record_event` | `069-sp_contact_record_event-001.sql:155` | Not in any code set. |
| `InvestgrOfContact` | `sp_contact_record_event` | `069-sp_contact_record_event-001.sql:156` | Not in any code set. |
| `DispoInvestgrOfConRec` | `sp_contact_record_event` | `069-sp_contact_record_event-001.sql:157` | Not in any code set. |
| `IntrvwerOfInterview` | `sp_interview_event` | `065-sp_interview_event-001.sql:89` | Not in any code set. |
| `IntrvweeOfInterview` | `sp_interview_event` | `065-sp_interview_event-001.sql:95` | Not in any code set. |
| `OrgAsSiteOfIntv` | `sp_interview_event` | `065-sp_interview_event-001.sql:92` | Not in any code set. |

Total MISSING_FROM_SRTE codes: **27** across `act_relationship`,
`participation`, and `nbs_act_entity`.

Recommendation: when authoring Tier 0 / Tier 2 fixtures, use these
type_cds as written (matching the SP literal exactly, including
`PerAsProvideroOfPediatrics`'s typo). The corresponding
`code_value_general` rows are NOT seeded by baseline SRTE; this is a
documented reference-data gap that fixture authors do not paper over by
inserting into SRTE. Tier 1 coverage reports should record any column
populated through one of these codes as also depending on the gap.
