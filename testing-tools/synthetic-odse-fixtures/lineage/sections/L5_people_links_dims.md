# L5 — People, Links & Dimensions

Cluster owned by Agent L5: the core RDB_MODERN dimension and fact tables
for the "people" subjects (`d_patient`, `d_provider`, `d_organization`,
`D_PLACE`), the act-based subjects (`D_INTERVIEW`/`D_INTERVIEW_NOTE`,
`D_VACCINATION`, `D_CONTACT_RECORD`, `NOTIFICATION`, `TREATMENT`,
`MORBIDITY_REPORT` + its datamart), their fact bridges
(`F_VACCINATION`, `F_CONTACT_RECORD_CASE`, `F_INTERVIEW_CASE`,
`NOTIFICATION_EVENT`, `TREATMENT_EVENT`, `MORBIDITY_REPORT_EVENT`,
`morb_Rpt_User_Comment`), **and all Tier-2 link edges** that flip the
cross-subject sentinel keys on those fact tables to real FKs.

Column appendix: `lineage/columns/L5_people_links_dims.tsv` — 532 rows,
one per (table, column) the catalog records for these tables. 526
VERIFIED, 6 DYNAMIC, 0 INFERRED, 0 MASTERETL_ONLY, 0 currently
BLOCKED (bug #03 was the only blocker and is fixed on `aw/odse-test-seed`).

## How to read the chain for this cluster

Every column in this cluster follows the STRATEGY.md convention:

- The `sp_<subject>_event` SP reads `nbs_odse.dbo.*` and projects a JSON
  view. It does **not** write `nrt_*`; in production CDC/Debezium does.
  This is the **ODSE → staging** edge, and it is the column in the
  appendix's `odse_source_col(s)` field.
- The `sp_nrt_<subject>_postprocessing` / `sp_d_<subject>_postprocessing`
  SP reads only RDB_MODERN-side `nrt_*` staging (never ODSE) and writes
  the dimension/fact. This is the **staging → RDB_MODERN** edge and is
  the `nrt_staging_source` + `transform_note` fields.

Because this cluster is the canonical home of the Tier-1 subject
fixtures, the ODSE→staging hop is unusually well documented: each
fixture header and `coverage_<subject>.md` SRTE table names the exact
`person.*` / `postal_locator.*` / `observation.*` column that feeds each
staging field. The appendix's ODSE attributions are synthesised from
those artifacts, not re-derived from SP source.

## The dimension tables (Tier 1)

**`d_patient` (81/81 VERIFIED).** `sp_nrt_patient_postprocessing` reads
`nrt_patient` and writes `D_PATIENT`. The event SP `sp_patient_event`
projects `nbs_odse.dbo.Person` plus its locator children
(`Entity_locator_participation` → `Postal_locator` / `Tele_locator`),
`person_name`, `person_race` (via the nested `sp_patient_race_event`),
and `entity_id`. Notable transforms: nearly every demographic `*_cd`
resolves to a description through `fn_get_value_by_cd_ques` against a
named code set (e.g. `birth_gender_cd`→SEX via DEM114,
`deceased_ind_cd`→YNU via DEM127); addresses pivot on
`entity_locator_participation.use_cd`/`cd` (`H`/`BIR`/`NET`/`CP`); the
postprocessing SP applies a uniform `blank → NULL` guard
(`004-...:41-170`). The 25-column race breakdown (`PATIENT_RACE_*_1/2/3/
GT3_IND/ALL` across five categories) is rolled up from `person_race.race_cd`
rows keyed by `parent_is_cd='ROOT'` + detail rows. The fixture exercises
all paths across three variants (foundation = null/blank path, v2 =
fully attributed multi-race, v3 = deceased branch).

**`d_provider` (34/34 VERIFIED)** and **`d_organization` (30/30
VERIFIED)** follow the same Person/Organization → locators → name →
entity_id shape via `sp_provider_event` / `sp_organization_event` into
`nrt_provider` / `nrt_organization`. Provider keys off `person.cd='PRV'`;
Organization sources its name from `organization_name` and its
`FACILITY_ID`/`STAND_IND_CLASS` from `entity_id` (CLIA) and the NAICS
code set. **Bug #04** (`#PATIENT_UPDATE_LIST` typo in
`sp_nrt_provider_postprocessing` line 564) is flagged on
`PROVIDER_LAST_UPDATED_BY` but is *not* a coverage blocker — it only
fires on the UPDATE-with-diff re-run path, the INSERT path used by the
fixture is clean, and the fix is already merged on main (PR #826).

**`D_PLACE` (37/37 VERIFIED).** `sp_nrt_place_postprocessing` reads
`nrt_place` (sourced from `nbs_odse.dbo.Place` + `Entity_id` + locators
via `sp_place_event`) and emits **four UNION-ALL variants** per
`place_uid` — Base / Postal-only / Tele-only / Postal+Tele — so a single
place can produce up to four `D_PLACE` rows. `PLACE_LOCATOR_UID` is a
composite `<place_uid>^<postal_uid>^<tele_uid>` key; `PLACE_ADDED_BY` /
`PLACE_LAST_UPDATED_BY` both join `USER_PROFILE` on `place_add_user_id`
(the SP uses `add_user_id` for both, never `last_chg_user_id`).

**`D_VACCINATION` (21 clinical VERIFIED + 2 DYNAMIC).**
`sp_d_vaccination_postprocessing` reads `nrt_vaccination` (projected from
`nbs_odse.dbo.INTERVENTION` by `sp_vaccination_event`). Clinical columns
use a `NULLIF(x,'')` blank-to-NULL idiom; `VACCINATION_ADMINISTERED_NM`
resolves `material_cd` through the VAC_NM code set. `RDB_COLUMN_NM` and
`THEN` are dynamic-PIVOT helper columns for LDF answers
(`V_RDB_UI_METADATA_ANSWERS_VACCINATION`), gated by
`nrt_metadata_columns(D_VACCINATION)` being non-empty — empty at baseline,
so flagged **DYNAMIC**.

**`D_INTERVIEW` (18 VERIFIED + 2 DYNAMIC) / `D_INTERVIEW_NOTE` (7/7
VERIFIED).** `sp_d_interview_postprocessing` reads `nrt_interview` /
`nrt_interview_note` (from `nbs_odse.dbo.INTERVIEW` via
`sp_interview_event`). The four `IX_*_CD`→`IX_*` description pairs resolve
through SRTE. The note table sources `USER_COMMENT` / author name / date
from the interview-note answer observations. Six live LDF columns
(IX_CONTACTS_NAMED_IND etc.) are dynamic-PIVOT and not in the catalog
write-set, hence not in this appendix; the two catalog dynamic helpers
(`RDB_COLUMN_NM`, `THEN`) are flagged DYNAMIC.

## The act-based dimensions with transform logic

**`NOTIFICATION` (6/6) / `NOTIFICATION_EVENT` (8/8) VERIFIED.**
`sp_nrt_notification_postprocessing` reads `nrt_investigation_notification`
(projected from `nbs_odse.dbo.notification` joined through
`act_relationship` → `public_health_case` by `sp_notification_event`).
At Tier-1 isolation the chain rolls back because `NOTIFICATION_EVENT`'s
`INVESTIGATION_KEY` has no resolvable PHC; the `inv_notification`
Tier-2 edge resolves it (see Tier-2 below). The three `*_DT_KEY` columns
join `RDB_DATE`; `CONDITION_KEY` joins `dbo.condition` (populated by the
infrastructure SP `sp_nrt_srte_condition_code_postprocessing`).

**`TREATMENT` (16/16) / `TREATMENT_EVENT` (11/11) VERIFIED.**
`sp_nrt_treatment_postprocessing` reads `nrt_treatment` (from
`nbs_odse.dbo.treatment` + `Treatment_administered` via
`sp_treatment_event`). Drug attributes resolve through TREAT_* code sets;
`CUSTOM_TREATMENT` is a `CASE WHEN cd='OTH'` branch (exercised by the v3
fixture variant); `RECORD_STATUS_CD` is pass-through (unlike Morbidity,
which transforms `PROCESSED→ACTIVE`). All eight cross-subject FK columns
on `TREATMENT_EVENT` `COALESCE(...,1)` to sentinel 1 at isolation; with
no FK constraints the INSERT succeeds at sentinel, then `treatment_inv`
flips them.

**`MORBIDITY_REPORT` (30/30), `MORBIDITY_REPORT_EVENT` (17/17),
`morb_Rpt_User_Comment` (8/8) VERIFIED.**
`sp_d_morbidity_report_postprocessing` (defined in the misleadingly-named
`016-sp_nrt_morbidity_report_postprocessing` file) reads `nrt_observation`
+ `nrt_morbidity_observation` + `nrt_observation_txt` (from
`nbs_odse.dbo.observation` + `obs_value_coded/txt/date` via
`sp_observation_event`). The "Order" observation is the morb root; ~16
INV*/MRB* follow-up observations are reached via the
`followup_observation_uid` CSV and pivoted into the dimension's clinical
columns (e.g. INV128→`HOSPITALIZED_IND`, MRB165→`DIAGNOSIS_DT`).
`MORBIDITY_REPORT_EVENT.PATIENT_KEY` is NOT-NULL with **no** COALESCE, so
at Tier-1 isolation the EVENT INSERT fails until the Patient chain has
populated `D_PATIENT` — a `LINK_REQUIRED` resolved by running the Patient
chain + the `morb_inv` edge.

`morb_Rpt_User_Comment` was **BLOCKED:#03** in pristine baseline: the SP's
user-comment temp-table query (lines 802-816) had a self-defeating join
(`root.morb_rpt_uid = obs.observation_uid` binds the Order to itself,
then filters `obs_domain_cd_st_1 IN ('C_Order','C_Result')` which the
Order can never satisfy), so 0 rows ever inserted. The fix (rewrite to
walk Order→C_Order→C_Result via the staging `followup_observation_uid`
CSV, staying inside RDB_MODERN per the postprocessing-reads-NRT
convention) is **squashed onto `aw/odse-test-seed`** (`[SQUASH bug-3]`,
upstream PR #837). On this branch the 8 columns populate end-to-end, so
they are recorded **VERIFIED** with a `bugs/03` cross-reference in the
transform note; revert the fix and they return to BLOCKED:#03.

**`MORBIDITY_REPORT_DATAMART` (133/133 VERIFIED).** The only datamart in
this cluster. `sp_morbidity_report_datamart_postprocessing` has **no
event-SP partner** — it reads exclusively from already-populated
RDB_MODERN tables: `MORBIDITY_REPORT`/`_EVENT` as the spine, dimension
joins to `D_PATIENT` / `D_PROVIDER` (physician + reporter) /
`D_ORGANIZATION` (report-facility + hospital) / `INVESTIGATION` /
`CONDITION` / `RDB_DATE`, plus `ROW_NUMBER()` `_1/_2/_3` pivots over
`LAB_TEST`/`LAB_TEST_RESULT`/`LAB_RESULT_VAL`/`LAB_RESULT_COMMENT` (lab
columns) and `TREATMENT_EVENT`/`TREATMENT` (treatment columns). Patient
and provider demographic columns are also overlaid by the two
`sp_*_dim_columns_update_to_datamart` SPs. Their *ultimate* ODSE origin
is therefore the same `person`/`observation`/`treatment` columns
documented on the dimension rows above (the appendix points back to
those rows rather than restating the chain). Verified at 133/133 by the
Tier-3 `zz_morbidity_report_datamart_enrich.sql` fixture, which authors a
third fully-attributed morbidity report with 3 labs + 3 treatments to
land every `_1/_2/_3` suffix.

## The fact bridges and the sentinel → FK flip (Tier 2)

The fact tables (`F_VACCINATION`, `F_CONTACT_RECORD_CASE`,
`F_INTERVIEW_CASE`, `NOTIFICATION_EVENT`, `TREATMENT_EVENT`,
`MORBIDITY_REPORT_EVENT`) all carry cross-subject surrogate-key columns
(`PATIENT_KEY`, `*_PROVIDER_KEY`, `*_ORGANIZATION_KEY`,
`INVESTIGATION_KEY`, etc.). At Tier-1 isolation the dimension tables hold
no matching row, so the postprocessing SP resolves each via
`COALESCE(<dim>.<KEY>, 1)` to **sentinel 1** (or, where there is no
COALESCE, NULL — which either is allowed or blocks the INSERT, as with
Morbidity's PATIENT_KEY). The fact INSERT succeeds at sentinel; the value
is wrong but the shape is right.

**Tier-2 edges flip the sentinel to a real FK.** There are two mechanisms,
and the distinction is load-bearing for this cluster:

1. **`act_relationship` edges mirrored via a staging soft-ref UPDATE.**
   For Notification, Lab, Morbidity and Treatment, the postprocessing SP
   resolves `INVESTIGATION_KEY` (and CONDITION/MORB keys) by joining
   `dbo.INVESTIGATION` on a PHC UID it reads from a *staging* column —
   `nrt_observation.associated_phc_uids` or
   `nrt_investigation_notification.public_health_case_uid`. The Tier-2
   fixture authors the `act_relationship` row (e.g.
   `MorbReport`/`LabReport`/`Notification`/`TreatmentToPHC`,
   `source_class_cd`/`target_class_cd` matching the event-SP filter)
   **and** issues an UPDATE on that `nrt_*.associated_phc_uids` column to
   mirror what CDC would have projected, then re-EXECs the postprocessing
   SP. On the re-run the join resolves and the key flips from 1 to the
   real `INVESTIGATION_KEY`. This is genuine RDB_MODERN coverage-unlock:
   `inv_notification` flips NOTIFICATION_EVENT.INVESTIGATION_KEY,
   `morb_inv` flips MORBIDITY_REPORT_EVENT (and unblocks the whole EVENT
   INSERT), `treatment_inv` flips TREATMENT_EVENT.INVESTIGATION_KEY +
   CONDITION_KEY for foundation/v3, `lab_inv` (L1's table) the analogous
   lab keys.

2. **`participation` / `nbs_act_entity` edges — JSON-projection-only at
   the postprocessing layer.** `patient_phc` (SubjOfPHC),
   `reporter_phc` (Per/OrgAsReporterOfPHC), `physician_phc`
   (Physician/InvestgrOfPHC), `phc_roles_nae` (NAE role edges),
   `interview_links` (Intrvwer/Intrvwee/OrgAsSiteOfIntv NAE),
   `contact_links` (SiteOfExposure/InvestgrOfContact/DispoInvestgr NAE),
   `vaccination_links` (SubOfVacc/PerformerOfVacc NAE) all author the
   connective rows correctly and flip the **event-SP JSON projection**
   (verified pre/post), but they do **not** flip any RDB_MODERN dim/fact
   column at the postprocessing layer — because the postprocessing SPs
   read the cross-subject UID from a `nrt_*` soft-ref column (hand-authored
   by Tier 1), never from the graph table. So `F_VACCINATION`,
   `F_CONTACT_RECORD_CASE`, `F_INTERVIEW_CASE` keys resolve through their
   own dimension joins in the merged sequence (after Patient/Provider/Org/
   Investigation/Interview chains run), and these NAE/participation edges
   are documented as *shape-consistency* (they keep the ODSE graph
   honest and unlock the Datamart-layer F_PAGE_CASE INNER JOINs at Merge
   step 9, which is L6/datamart territory). Several of the edge `type_cd`
   values (`IXS`, `SiteOfExposure`, `TreatmentToMorb`, etc.) are
   `MISSING_FROM_SRTE` but the RTR event SPs filter on the literal anyway,
   so the fixtures author them with the literal value per the Phase-B
   "MISSING_FROM_SRTE used anyway" policy.

In the appendix, fact-table FK columns are attributed to the staging
soft-ref the SP actually reads, with the transform note recording the
`sentinel-1 -> FK` flip and which Tier-2 fixture (or merged-sequence
chain) performs it.

## Blocked / skipped / dynamic columns

- **DYNAMIC (6):** `D_VACCINATION.RDB_COLUMN_NM`, `D_VACCINATION.THEN`,
  `D_INTERVIEW.RDB_COLUMN_NM`, `D_INTERVIEW.THEN`,
  `D_CONTACT_RECORD.RDB_COLUMN_NM`, `D_CONTACT_RECORD.THEN`. These are
  dynamic-PIVOT helper columns driven by `nrt_metadata_columns` /
  `v_rdb_ui_metadata_answers` page-builder metadata, empty at baseline.
  The associated live LDF columns (23 on D_CONTACT_RECORD, 6 on
  D_INTERVIEW) are NOT in the catalog write-set and are deferred to a
  Tier-3 LDF fixture; they are out of scope for this appendix per the
  catalog-driven row set.
- **BLOCKED:#03 (resolved):** the 8 `morb_Rpt_User_Comment` columns —
  blocked in pristine baseline, VERIFIED on `aw/odse-test-seed` where the
  bug-3 fix is squashed in. Recorded VERIFIED with the bug cross-reference.
- **Bug #02** (`sp_contact_record_event` 3-part-name error) and **bug #04**
  (provider UPDATE-path typo) touch this cluster but block **no** columns:
  #02 is bypassed because `sp_d_contact_record_postprocessing` reads
  `nrt_contact` directly (and the bug is fixed on main, PR #769); #04 only
  fires on the UPDATE-diff re-run, not the INSERT path (fixed on main,
  PR #826). Both are noted in the relevant transform notes, not flagged
  BLOCKED.
- **No MASTERETL_ONLY columns** in this cluster — every column has a real
  RTR SP write path and a fixture/coverage proof.
