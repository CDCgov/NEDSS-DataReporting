# Coverage: organization (Tier 1)

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 20030000 - 20039999 (Organization Tier 1)
- Foundation dependencies:
  - `@dbo_Entity_organization_uid` = 20000020 (entity / organization /
    organization_name; class `ORG`)
  - `@dbo_Postal_locator_org` = 20000021 (PST/WP/O — work address)
  - `@dbo_Tele_locator_org` = 20000022 (TELE/WP/PH — work phone)
- Other-agent dependencies: none. The fixture intentionally avoids
  cross-subject `act_relationship` / `participation` / `nbs_act_entity`
  rows (Tier 2 territory).

## SPs verified
- `dbo.sp_organization_event` — exit code: 0; emitted 2 rows (foundation +
  v2). Pure SELECT — does NOT write `dbo.nrt_organization` (matches the
  Provider canary observation; same shape applies for Organization).
  Verified by inspecting the SP body: lines 39-156 are a single SELECT,
  no INSERT into `nrt_organization`. Subordinate `OUTER APPLY` blocks
  populate the JSON projections `organization_name`,
  `organization_address`, `organization_telephone`, `organization_fax`,
  and `organization_entity_id` — all five resolved to non-NULL JSON for
  both rows in this fixture.
- `dbo.sp_nrt_organization_postprocessing` — exit code: 0; `job_flow_log`
  shows `Dataflow_Name='Organization POST-Processing'`,
  `step_name='SP_COMPLETE'`, `status_type='COMPLETE'` for batch
  `2605050623553430`. Step 4 ("Insert into D_ORAGANIZATION Dimension")
  reported `row_count=2`. No `ERROR` rows in `job_flow_log` for this
  invocation.

## Apply / FK check
- `sqlcmd -i 00_foundation.sql` exit code: 0.
- `sqlcmd -i 10_subjects/organization.sql` exit code: 0 on first attempt
  (no iterations needed during authoring).
- `DBCC CHECKCONSTRAINTS` run on every NBS_ODSE table written
  (`entity`, `organization`, `organization_name`, `entity_id`,
  `tele_locator`, `postal_locator`, `entity_locator_participation`).
  All checks completed without constraint-violation rows.

## Iteration count
- 1 baseline-reset cycle (the dispatch reset before applying foundation
  + this fixture). Apply was clean on first attempt and both SPs ran
  without error on first invocation. The Provider canary's hard-won
  template guidance (skip GENERATED ALWAYS columns; populate
  `nrt_<entity>` directly; use `SQLCMDPASSWORD`; preserve column-name
  typos; verify locator filters in the SP) absorbed every issue ahead
  of time.

## D_ORGANIZATION coverage
**30 / 30 columns the SP writes are populated for at least one
organization** (v2 organization, UID 20030010, populates every column
non-NULL). Foundation organization (UID 20000020) leaves 5 columns
deliberately NULL to exercise the SP's `null/blank → NULL` handling
in the INSERT SELECT (lines 251-267 of
`002-sp_nrt_organization_postprocessing-001.sql`).

| Column | Source (postprocessing SP) | Sample value (v2, 20030010) | Foundation (20000020) |
| --- | --- | --- | --- |
| ORGANIZATION_KEY | `nrt_organization_key.d_organization_key` (auto-issued by SP) | 8 | 7 |
| ORGANIZATION_UID | `nrt.organization_uid` | 20030010 | 20000020 |
| ORGANIZATION_LOCAL_ID | `nrt.local_id` | `ORG20030010GA01` | `ORG20000020GA01` |
| ORGANIZATION_RECORD_STATUS | `nrt.record_status` | `ACTIVE` | `ACTIVE` |
| ORGANIZATION_NAME | `nrt.organization_name` (cast varchar(50)) | `Variant Hospital` | `Foundation Organization` |
| ORGANIZATION_GENERAL_COMMENTS | `nrt.general_comments` | `Tier 1 variant organization — exercises every D_ORGANIZATION column.` | NULL (deliberate) |
| ORGANIZATION_QUICK_CODE | `nrt.quick_code` (blank → NULL) | `V2QUICK` | NULL (deliberate) |
| ORGANIZATION_STAND_IND_CLASS | `nrt.stand_ind_class` | `General Medical and Surgical Hospitals` | NULL (deliberate — exercises null-NAICS path) |
| ORGANIZATION_FACILITY_ID | `nrt.facility_id` | `22D9999999` | `11D2030855` |
| ORGANIZATION_FACILITY_ID_AUTH | `nrt.facility_id_auth` | `CLIA (CMS)` | `CLIA (CMS)` |
| ORGANIZATION_STREET_ADDRESS_1 | `nrt.street_address_1` | `3010 Variant Hospital Way` | `300 Organization Boulevard` |
| ORGANIZATION_STREET_ADDRESS_2 | `nrt.street_address_2` | `Building B` | NULL (deliberate) |
| ORGANIZATION_CITY | `nrt.city` | `Atlanta` | `Atlanta` |
| ORGANIZATION_STATE | `nrt.state` | `Georgia` | `Georgia` |
| ORGANIZATION_STATE_CODE | `nrt.state_code` | `13` | `13` |
| ORGANIZATION_ZIP | `nrt.zip` | `30303` | `30303` |
| ORGANIZATION_COUNTY | `nrt.county` | `Fulton County` | `Fulton County` |
| ORGANIZATION_COUNTY_CODE | `nrt.county_code` | `13121` | `13121` |
| ORGANIZATION_COUNTRY | `nrt.country` | `United States` | `United States` |
| ORGANIZATION_ADDRESS_COMMENTS | `nrt.address_comments` (RTRIM/LTRIM if non-NULL) | `v2 Organization work address` | `Organization work address` |
| ORGANIZATION_PHONE_WORK | `nrt.phone_work` | `404-555-3010` | `404-555-0300` |
| ORGANIZATION_PHONE_EXT_WORK | `nrt.phone_ext_work` | `8765` | NULL (deliberate) |
| ORGANIZATION_EMAIL | `nrt.email` (cast varchar(50); blank → NULL) | `variant.org@nbs.test` | NULL (deliberate) |
| ORGANIZATION_PHONE_COMMENTS | `nrt.phone_comments` (RTRIM/LTRIM if non-NULL) | `v2 Organization work phone` | `Organization work phone` |
| ORGANIZATION_FAX | `nrt.fax` | `404-555-3099` | `404-555-0399` |
| ORGANIZATION_ENTRY_METHOD | `nrt.entry_method` | `ELECTRONIC` | `ELECTRONIC` |
| ORGANIZATION_LAST_CHANGE_TIME | `nrt.last_chg_time` | `2026-04-01 00:00:00` | same |
| ORGANIZATION_ADD_TIME | `nrt.add_time` | `2026-04-01 00:00:00` | same |
| ORGANIZATION_ADDED_BY | `nrt.add_user_name` | `Kent, Ariella` | `Kent, Ariella` |
| ORGANIZATION_LAST_UPDATED_BY | `nrt.last_chg_user_name` | `Kent, Ariella` | `Kent, Ariella` |

Per-row NULL counts (out of 30 SP-written columns):
- 20000020 (foundation, minimal): 6 NULLs (deliberately, to exhibit the
  SP's null/blank handling for GENERAL_COMMENTS, QUICK_CODE,
  STREET_ADDRESS_2, PHONE_EXT_WORK, EMAIL, STAND_IND_CLASS).
- 20030010 (v2, fully attributed): 0 NULLs.

## UID allocations (Organization Tier 1)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20030001 | @dbo_Tele_locator_org_fax | `tele_locator.tele_locator_uid` for foundation Org's (TELE, WP, `FAX`) work-fax locator | Drives `D_ORGANIZATION.ORGANIZATION_FAX` on the foundation row by satisfying the event SP's fax filter at `sp_organization_event:124-135`. |
| 20030010 | @dbo_Entity_organization_v2_uid | v2 Organization `entity.entity_uid`, `organization.organization_uid`, `organization_name.organization_uid` | Class `ORG`. Fully-attributed Organization variant for column coverage. |
| 20030011 | @dbo_Postal_locator_org_v2 | v2 Org work `postal_locator.postal_locator_uid` | Wired via entity_locator_participation (PST/WP/O). |
| 20030012 | @dbo_Tele_locator_org_v2_phone | v2 Org work phone `tele_locator.tele_locator_uid` | Wired via ELP (TELE/WP/PH). Includes `extension_txt` and `email_address`. |
| 20030013 | @dbo_Tele_locator_org_v2_fax | v2 Org work fax `tele_locator.tele_locator_uid` | Wired via ELP (TELE/WP/FAX). |

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_organization`
keyed on `organization_uid` 20000020 (foundation) and 20030010 (v2). Those
identities are not new UIDs — they reference the entities created in
foundation and the v2 entity above.

Unused UIDs in Organization Tier 1 block (20030000, 20030002-20030009,
20030014-20039999) are reserved for future Organization Tier 1 / Tier 3
amendments.

## SRTE codes referenced
Every `*_cd` value chosen for organization rows (additive to foundation),
with its baseline SRTE code set. All values verified present at baseline
6.0.18.1.

| Table.column | Value | code_set_nm | Notes |
| --- | --- | --- | --- |
| entity.class_cd | `ORG` | `ENTITY_CLS` | v2 Org (matches foundation Org) |
| entity_locator_participation.class_cd | `TELE` | `EL_CLS` | foundation fax + v2 phone/fax |
| entity_locator_participation.class_cd | `PST` | `EL_CLS` | v2 postal address |
| entity_locator_participation.use_cd | `WP` | `EL_USE` | all new Org locators |
| entity_locator_participation.cd | `O` | `EL_TYPE` | v2 Org postal address |
| entity_locator_participation.cd | `PH` | `EL_TYPE` | v2 Org work phone |
| entity_locator_participation.cd | `FAX` | `EL_TYPE` | foundation + v2 fax |
| entity_id.type_cd | `FI` | `EI_TYPE_ORG` | facility identifier — drives ORGANIZATION_FACILITY_ID; the only hard-filtered entity_id type for Org per `edge_types.md` |
| entity_id.assigning_authority_cd | `CLIA` | `EI_AUTH_ORG` | drives the case branch at `sp_organization_event:146-148` (`fn_get_value_by_cvg`); resolves to `CLIA (CMS)` via baseline CVG |
| organization.standard_industry_class_cd | `622110` | NAICS_INDUSTRY_CODE | (`code_short_desc_txt='General Medical and Surgical Hospitals'`); joined at `sp_organization_event:154`. Set on v2 only — foundation Org's column is NULL (read-only). |
| organization_name.nm_use_cd | `L` | (legal name; reference-only) | matches foundation dialect |
| organization.record_status_cd | `ACTIVE` | reference value (event SP at line 43 wraps with `dbo.fn_get_record_status`) | conventional |
| organization.status_cd | `A` | conventional | |
| organization.electronic_ind | `Y` (v2) | conventional char(1) | |
| organization.edx_ind | `Y` (v2) | conventional | |

Codes that the SP DOES NOT join through SRTE for D_ORGANIZATION coverage
(read-through, no validation):
- `nrt_organization.entry_method` `'ELECTRONIC'` (free text on D_ORGANIZATION).
- `nrt_organization.country` `'United States'` and `country_code` `'840'` —
  read by SP but only `country` propagates to `D_ORGANIZATION.ORGANIZATION_COUNTRY`
  (column `country_code` is not part of the SP's INSERT SELECT). See OUT_OF_SCOPE.

## Columns deliberately skipped
| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| D_ORGANIZATION (foundation row) | ORGANIZATION_GENERAL_COMMENTS, ORGANIZATION_QUICK_CODE, ORGANIZATION_STREET_ADDRESS_2, ORGANIZATION_PHONE_EXT_WORK, ORGANIZATION_EMAIL, ORGANIZATION_STAND_IND_CLASS | Deliberately left NULL on the foundation organization so the SP's `null/blank → NULL` transform path is observable in the diff. The same columns ARE populated on v2 (20030010), so D_ORGANIZATION coverage = 30/30 for at least one variant. ORGANIZATION_STAND_IND_CLASS is NULL on foundation because the foundation `organization` row is read-only (no UPDATEs allowed); v2 sets `standard_industry_class_cd='622110'` to exercise the populated NAICS path. | `002-sp_nrt_organization_postprocessing-001.sql:251-267` (`isnull(NULLIF(cast(...) as varchar), '')`, `case when org.[X] is null then null else ... end`) |

## Other RTR-write tables touched by the Organization chain
- `dbo.nrt_organization_key` — 2 rows inserted by the postprocessing SP
  (one per organization UID), surrogate key allocator. Catalog does not
  list this as an RTR target column-by-column (it's an internal staging
  key store; agents do not hand-write per the template).
- `dbo.D_ORGANIZATION` — 2 rows inserted (above).
- `dbo.job_flow_log` — `START` and `COMPLETE` rows for the event SP +
  postprocessing SP. Logging only; not a coverage target.
- `dbo.ORGANIZATION_LDF_GROUP` — written by `sp_nrt_ldf_postprocessing`,
  NOT by the Organization chain. Out of scope per the per-subject prompt.
- The postprocessing SP attempts dynamic-datamart updates at steps 5-8
  (`#F_PAGE_CASE_ORGS`, `#F_STD_PAGE_CASE_ORGS`,
  `sp_dyn_dm_dimension_update`). With no `F_PAGE_CASE` rows existing
  (Tier 2 territory), these steps INNER-JOIN to empty and emit zero
  affected rows; `sp_dyn_dm_dimension_update` returns success and the
  SP's `SP_COMPLETE` log row fires. No additional fixture data is
  required at Tier 1 for the SP to complete cleanly.

## Gaps reported

### SRTE_GAP
- (none) — every SRTE code referenced is present in baseline 6.0.18.1.

### LINK_REQUIRED
- (none) — D_ORGANIZATION coverage requires no cross-subject
  act_relationship / participation / nbs_act_entity rows. Future Tier 2
  work will link Organization to Investigation / Lab / Notification via
  `participation` rows (`OrgAsReporterOfPHC`, `LabReportFacility`,
  `Hospital`, etc.) per `edge_types.md`. Those edges drive Datamart-level
  organization columns (HOSPITAL_KEY, ORG_AS_REPORTER_KEY pivots in
  `F_PAGE_CASE`, etc.) — Datamart SP responsibility, not the Organization
  postprocessing SP itself.

### OUT_OF_SCOPE
- `nrt_organization.country_code` — present on the staging table but
  `sp_nrt_organization_postprocessing` does not propagate it to
  D_ORGANIZATION (only `country` makes it through, into ORGANIZATION_COUNTRY).
  The fixture sets `country_code` on staging anyway for completeness; if
  a future RTR change starts to read `country_code`, no fixture change
  required.
- `dbo.ORGANIZATION_LDF_GROUP` — written by `sp_nrt_ldf_postprocessing`,
  not by `sp_nrt_organization_postprocessing`. The per-subject prompt
  flags it as out-of-scope for this subject. No LDF-template seeding
  required here.
- Organization columns appearing on Datamart tables (HEPATITIS_DATAMART,
  TB_DATAMART, MORBIDITY_REPORT_DATAMART, COVID_LAB_DATAMART,
  STD_HIV_DATAMART, F_PAGE_CASE, etc.) — `HOSPITAL_KEY`,
  `ORG_AS_REPORTER_KEY`, `REPORTING_FACILITY_NAME`, etc. — are written
  by Datamart SPs after Tier 2 links + Datamart SP runs. They are NOT
  written by `sp_nrt_organization_postprocessing` and are out of this
  subject's scope per the stop conditions.

### FOUNDATION_GAP
- (none caused this fixture to fail). The foundation Org's locators
  (PST/WP/O for postal, TELE/WP/PH for tele) line up cleanly with the
  event SP's address and phone filters. Only fax (TELE/WP/FAX) was
  missing on the foundation Org, and the per-subject prompt explicitly
  asked the Tier 1 agent to add that locator in its own block — done
  via @dbo_Tele_locator_org_fax (20030001) without modifying foundation.

## Decisions made under ambiguity

- **`organization.standard_industry_class_cd` left NULL on the foundation
  Org.** Foundation's INSERT in `00_foundation.sql` does not set this
  column. An earlier draft of this fixture UPDATEd the foundation row
  to populate it, on the theory that `coverage_foundation.md`'s
  "Columns deliberately skipped" entry for `organization`/
  `standard_industry_class_cd` ("Tier 1 organization agent") licensed
  the modification. **That was wrong.** The template's "no foundation
  modifications" contract applies even to columns flagged as
  Tier-1-deferred; the deferral describes which *variant* exercises the
  populated path (the v2 Org), not which agent gets to UPDATE foundation
  rows. Reverted: the foundation Org now exhibits the null-NAICS path
  in `D_ORGANIZATION.ORGANIZATION_STAND_IND_CLASS`, while the v2 Org
  populates it. Both branches of the SP's NAICS join (resolved vs
  null) are exercised, and the read-only contract on foundation rows
  is preserved.
- **`assigning_authority_cd='CLIA'` chosen for both `entity_id` rows.**
  The case branch at `sp_organization_event:146-148` requires
  `type_cd='FI' AND assigning_authority_cd IS NOT NULL` and resolves
  `fn_get_value_by_cvg(assigning_authority_cd, 'EI_AUTH_ORG')` to the
  authority's display value. `CLIA` is one of the four EI_AUTH_ORG
  codes in baseline (`AHA`, `CLIA`, `CMS`, `OTH`) and resolves to
  `CLIA (CMS)`. Same value used for both rows so the SP's branch is
  exercised on both rows; the `root_extension_txt` differs (`11D2030855`
  vs `22D9999999`) so they're distinguishable in diff output.
- **`organization_name_seq=1` for v2 organization_name.** Foundation uses
  1; matched here for consistency. The column is `smallint NOT NULL` and
  both 0 and 1 are valid — preserving the foundation dialect.
- **No `role` rows authored.** The per-subject prompt mentioned
  potentially adding `role` rows for Org-as-Hospital / Org-as-Clinic,
  but none of the columns in `D_ORGANIZATION` written by
  `sp_nrt_organization_postprocessing` derive from `role`. Role-based
  pivots (e.g., scoping organization on F_PAGE_CASE) are
  Tier-2-and-later concerns. Skipped.
- **Foundation Org `entity_id` row added with `type_cd='FI'`.** The
  per-subject prompt suggested either FI or another EI_TYPE_ORG code
  for foundation enrichment. FI was chosen so both organization rows
  drive both branches of the SP's facility_id_auth case (one with
  authority resolved via CVG, one with the same).
- **Variant strategy mirrors the Provider canary.** Foundation Org gets
  enrichment that satisfies the event SP's filters (added fax locator,
  added entity_id, set NAICS) but leaves several `nrt_organization`
  columns NULL to exercise the postprocessing SP's null-handling path
  (general_comments, quick_code, street_address_2, phone_ext_work,
  email). v2 Org is fully attributed: every nrt column non-NULL. This
  delivers 30/30 coverage with both branches of every guarded transform
  exercised.
- **`country_code` populated on `nrt_organization` despite not being
  propagated to `D_ORGANIZATION`.** Set for both rows for completeness;
  documented as OUT_OF_SCOPE for the comparison test (the SP does not
  read it through). If RTR maintainers wire `country_code` later, the
  fixture is already shaped for it.
- **No modification of foundation rows.** The foundation Org's parent
  rows (`entity`, `organization`, `organization_name`, foundation
  locators) are not modified by this fixture. Enrichment is restricted
  to *additive child rows* tied to the foundation Org's UID — a fax
  `tele_locator` + `entity_locator_participation` row, an `entity_id`
  row — all allocated within this fixture's UID block. No `UPDATE` or
  `DELETE` against foundation rows. This preserves the build-order
  invariant that foundation is read-only across all Tier 1 fixtures.

## Notes for the Tier 1 template (delta from Provider canary)

The Provider canary's "Notes for Tier 1 template" section captures
nearly every surprise; this fixture confirmed they're real and that
the template's mitigations work. Two small additions worth noting:

1. **Tier 1 agents must NOT UPDATE foundation rows, even for columns
   `coverage_foundation.md` flags as "Tier 1 will populate".** An
   earlier draft of this fixture UPDATEd
   `organization.standard_industry_class_cd` on the foundation Org
   because that column appears in foundation's "Columns deliberately
   skipped" → "Tier 1 organization agent" entry. That violated the
   template's read-only-foundation contract. The deferral language in
   `coverage_foundation.md` describes *which variant exercises the
   populated path* (the Tier 1 v2 variant), not *which agent UPDATEs
   the foundation row*. The template now states this explicitly. The
   correct pattern: leave the foundation row's column NULL (exercises
   the null path) and populate the column on the v2 variant inside
   the Tier 1 UID block (exercises the populated path).

2. **The postprocessing SP's dynamic-datamart steps 5-8 emit zero rows
   on a Tier 1 baseline because `F_PAGE_CASE` is empty until Tier 2
   participation rows wire Investigation→Organization. The SP's
   `INNER JOIN` and `sp_dyn_dm_dimension_update` handle this gracefully
   and the SP completes with `SP_COMPLETE / COMPLETE`.** No fixture
   action required at Tier 1 — but agents who see step 7/8 row_count=0
   might worry. Note in the template: "Datamart-bridge steps emitting
   row_count=0 at Tier 1 is expected; they require Tier 2 cross-subject
   edges to populate F_PAGE_CASE."
