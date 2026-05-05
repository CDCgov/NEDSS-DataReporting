# Coverage: vaccination (Vaccination)

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 20110000 - 20119999
- Foundation dependencies:
  - `@dbo_Act_vaccination_uid` (20000160) — foundation Vaccination Act / intervention row (sparse — see `coverage_foundation.md` "Columns deliberately skipped: intervention" — `activity_from_time, activity_to_time, target_site_cd, method_cd, vacc_mfgr_cd, age_at_vacc, material_lot_nm, material_expiration_time, vacc_info_source_cd`).
  - `@dbo_Entity_patient_uid` (20000000) — referenced via `nrt_vaccination.patient_uid` (soft).
  - `@dbo_Entity_provider_uid` (20000010) — referenced via `nrt_vaccination.provider_uid` (soft).
  - `@dbo_Entity_organization_uid` (20000020) — referenced via `nrt_vaccination.organization_uid` (soft).
  - `@dbo_Act_investigation_uid` (20000100) — referenced via `nrt_vaccination.phc_uid` (soft).
- Other-agent dependencies: baseline SRTE only (`code_value_general` for `VAC_NM`, `NIP_ANATOMIC_ST`, `AGE_UNIT`, `VAC_MFGR`, `PHVS_VACCINEEVENTINFORMATIONSOURCE_NND`).

## SPs verified
- `dbo.sp_vaccination_event @vac_uids = N'20000160,20110010', @debug = 0` — exit code 0; emits a JSON-shaped projection. **0 rows projected** because the SP filters on `NBS_ACT_ENTITY.TYPE_CD='SubOfVacc'` (line 108) which is a CROSS-subject participation row (Vaccination → Patient, Tier 2 territory). The event SP is a JSON-projection / contract test only — it does not write `nrt_vaccination` (we hand-author that). Empty result is expected at Tier 1 isolation; not a fixture failure. The merged-fixture sequence will surface vaccination rows after Tier 2 wires SubOfVacc participation rows.
- `dbo.sp_d_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0` — exit code 0; `job_flow_log` shows step 999 / `step_name='COMPLETE'` / `status_type='COMPLETE'`. INSERT INTO nrt_vaccination_key: 2 rows (allocated D_VACCINATION_KEY = 2, 3 via IDENTITY). INSERT INTO D_VACCINATION: 2 rows.
- `dbo.sp_f_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0` — exit code 0; `job_flow_log` shows step 999 / `step_name='COMPLETE'` / `status_type='COMPLETE'`. INSERT INTO F_VACCINATION: 2 rows. UPDATE F_VACCINATION: 0 rows (first-time insert path).

## Apply / FK check
- `sqlcmd -i fixtures/00_foundation/00_foundation.sql` exit code 0.
- `sqlcmd -i fixtures/10_subjects/vaccination.sql` exit code 0 — **clean apply on first iteration**.
- ODSE INSERTs:
  - 1 row to `act` (v2 Vaccination).
  - 1 row to `intervention` (v2 Vaccination — fully attributed).
- RDB_MODERN INSERTs:
  - 2 rows to `dbo.nrt_vaccination` (foundation 20000160, v2 20110010).
- `DBCC CHECKCONSTRAINTS` on `dbo.act`, `dbo.intervention`: clean.
- **Iteration count: 1** baseline-reset cycle (the 2-variant version verified end-to-end on first apply against a fresh baseline).

## Coverage by target table

### D_VACCINATION — 21 / 21 live columns populated

Live column count: 21 (matches per-subject prompt's "Live: 21 cols / catalog: 24"). The catalog overcount of 3 is consistent with previously-observed catalog drifts. All 21 live columns are populated for at least one variant; foundation exhibits the null/blank-to-NULL transform paths.

| Column | Foundation (UID 20000160, D_VACCINATION_KEY=2) | v2 (UID 20110010, D_VACCINATION_KEY=3) | Source / SP transform |
| --- | --- | --- | --- |
| D_VACCINATION_KEY | yes (=2, IDENTITY) | yes (=3) | `nrt_vaccination_key.d_vaccination_key` IDENTITY at SP lines 205-209 |
| ADD_TIME | yes (`2026-04-01`) | yes (`2026-04-15 10:00:00`) | `nrt_vaccination.add_time` |
| ADD_USER_ID | yes (=10009282) | yes (=10009282) | `nrt_vaccination.add_user_id` |
| AGE_AT_VACCINATION | NULL (null path) | yes (=42) | `nrt_vaccination.age_at_vaccination` |
| AGE_AT_VACCINATION_UNIT | NULL (blank → NULL via NULLIF) | yes (`Years`) | `NULLIF(ix.age_at_vaccination_unit, '')` (line 246 / 353) |
| LAST_CHG_TIME | yes (`2026-04-01`) | yes (`2026-04-15 10:00:00`) | `nrt_vaccination.last_chg_time` |
| LAST_CHG_USER_ID | yes (=10009282) | yes (=10009282) | `nrt_vaccination.last_chg_user_id` |
| LOCAL_ID | yes (`VAC20000160GA01`) | yes (`VAC20110010GA01`) | `nrt_vaccination.local_id` |
| RECORD_STATUS_CD | yes (`ACTIVE`) | yes (`ACTIVE`) | `nrt_vaccination.record_status_cd` |
| RECORD_STATUS_TIME | yes (`2026-04-01`) | yes (`2026-04-15 10:00:00`) | `nrt_vaccination.record_status_time` |
| VACCINE_ADMINISTERED_DATE | NULL (null path) | yes (`2026-04-15 10:00:00`) | `nrt_vaccination.vaccine_administered_date` |
| VACCINE_DOSE_NBR | NULL (null path) | yes (=2) | `nrt_vaccination.vaccine_dose_nbr` |
| VACCINATION_ADMINISTERED_NM | NULL (blank → NULL via NULLIF) | yes (`Hep A, adult`) | `NULLIF(ix.vaccination_administered_nm, '')` (line 254 / 361) |
| VACCINATION_ANATOMICAL_SITE | NULL (blank → NULL via NULLIF) | yes (`Left Deltoid`) | `NULLIF(ix.vaccination_anatomical_site, '')` (line 255 / 362) |
| VACCINATION_UID | yes (=20000160) | yes (=20110010) | `nrt_vaccination.vaccination_uid` |
| VACCINE_EXPIRATION_DT | NULL (null path) | yes (`2027-12-31`) | `nrt_vaccination.vaccine_expiration_dt` |
| VACCINE_INFO_SOURCE | NULL (blank → NULL via NULLIF) | yes (`New immunization record`) | `NULLIF(ix.vaccine_info_source, '')` (line 258 / 365) |
| VACCINE_LOT_NUMBER_TXT | NULL (null path) | yes (`LOT-HEPA-2026-A`) | `nrt_vaccination.vaccine_lot_number_txt` |
| VACCINE_MANUFACTURER_NM | NULL (blank → NULL via NULLIF) | yes (`Merck & Co., Inc.`) | `NULLIF(ix.vaccine_manufacturer_nm, '')` (line 260 / 367) |
| VERSION_CTRL_NBR | yes (=1) | yes (=1) | `nrt_vaccination.version_ctrl_nbr` |
| ELECTRONIC_IND | yes (`N`) | yes (`Y`) | `nrt_vaccination.electronic_ind` |

The two-variant pattern jointly exercises:
- **Null-propagation path**: foundation's NULL clinical columns (date / dose / lot / expiration / age) produce D_VACCINATION column NULL.
- **Blank-to-NULL via NULLIF transform**: foundation passes empty strings on AGE_AT_VACCINATION_UNIT, VACCINATION_ADMINISTERED_NM, VACCINATION_ANATOMICAL_SITE, VACCINE_INFO_SOURCE, VACCINE_MANUFACTURER_NM — the SP's NULLIF turns them into NULL on the dim side. Confirmed in result rows (foundation has NULL on these 5 columns despite the staging row carrying `N''`).
- **Populated path**: v2 fills every clinical column.

### F_VACCINATION — 6 / 6 live columns populated

Live column count: 6 (matches per-subject prompt). All 6 columns populated for both rows.

| Column | Foundation (D_VACCINATION_KEY=2) | v2 (D_VACCINATION_KEY=3) | Source / SP transform |
| --- | --- | --- | --- |
| D_VACCINATION_KEY | yes (=2) | yes (=3) | `dim.D_VACCINATION_KEY` (line 71); non-sentinel from D_VACCINATION INSERT just done. |
| PATIENT_KEY | 1 (sentinel) | 1 (sentinel) | `COALESCE(pt1.PATIENT_KEY, 1)` (line 74); D_PATIENT empty for these UIDs at Tier 1 isolation. |
| VACCINE_GIVEN_BY_KEY | 1 (sentinel) | 1 (sentinel) | `COALESCE(pv1.PROVIDER_KEY, 1)` (line 77); D_PROVIDER empty for these UIDs. |
| VACCINE_GIVEN_BY_ORG_KEY | 1 (sentinel) | 1 (sentinel) | `COALESCE(org.ORGANIZATION_KEY, 1)` (line 80); D_ORGANIZATION empty for these UIDs. |
| D_VACCINATION_REPEAT_KEY | yes (=1.0) | yes (=1.0) | hardcoded `1` (line 82). |
| INVESTIGATION_KEY | 1 (sentinel) | 1 (sentinel) | `COALESCE(inv1.INVESTIGATION_KEY, 1)` (line 85); INVESTIGATION empty for these CASE_UIDs at Tier 1 isolation. |

Expected merged-fixture sequence behavior: the 4 sentinel-1 FK columns (PATIENT_KEY, VACCINE_GIVEN_BY_KEY, VACCINE_GIVEN_BY_ORG_KEY, INVESTIGATION_KEY) will resolve to non-sentinel keys after upstream Tier 1 chains run (Patient → D_PATIENT, Provider → D_PROVIDER, Organization → D_ORGANIZATION, Investigation → INVESTIGATION). Tier 2 cross-subject `participation` rows (SubOfVacc / PerformerOfVacc) and `act_relationship` rows (type_cd='1180' for VaccinationToPHC) wire the same UIDs at the ODSE-graph level for the event SP, but the postprocessing SPs resolve cross-subject keys via `nrt_vaccination` soft-ref columns we author, not via ODSE participation/act_relationship rows.

## SRTE codes referenced

| Table.column | Value | code_set_nm | Notes |
| --- | --- | --- | --- |
| intervention.cd / nrt_vaccination.material_cd (v2) | `52` | `VAC_NM` | verified — Hep A, adult. Aligned with foundation Investigation `cd='10110'` (Hepatitis A acute) per v1 single-condition-per-family. |
| intervention.material_cd / nrt_vaccination.material_cd (foundation) | `207` | `VAC_NM` | verified — SARS-COV-2 (COVID-19) vaccine. Inherited from foundation per `coverage_foundation.md`; this is also the CVX value the d_vaccination postprocessing SP's tail SELECT (line 433) filters on for `Covid_Vaccination_Datamart` (out-of-scope for Tier 1 — verified the trailing query reports `'Covid_Vaccination_Datamart'` for foundation, but the datamart SP itself is out-of-scope). |
| intervention.target_site_cd (v2) | `LD` | `NIP_ANATOMIC_ST` | verified — Left Deltoid |
| intervention.age_at_vacc_unit_cd (v2) | `Y` | `AGE_UNIT` | verified — Years |
| intervention.vacc_mfgr_cd (v2) | `MSD` | `VAC_MFGR` | verified — Merck & Co., Inc. |
| intervention.vacc_info_source_cd (v2) | `9` | `PHVS_VACCINEEVENTINFORMATIONSOURCE_NND` | verified — New immunization record |
| intervention.method_cd (v2) | `IM` | (literal — not asserted in baseline SRTE for this fixture; `dbo.code_value_general` query for `IM`/`SBADM_ROUTE` not run). The d_vaccination postprocessing SP does not read `method_cd` — it's set on the ODSE row for shape consistency only. |  |
| intervention.class_cd | `INTV` | `ACT_CLS` | per foundation pattern |
| act.class_cd | `INTV` | `ACT_CLS` | v2 |
| act.mood_cd | `EVN` | `ACT_MOOD` | event mood |
| intervention.shared_ind / nrt_vaccination — | `T` (v2), `F` (foundation) | char(1) flag — not coded | foundation sparse; v2 shared |
| intervention.record_status_cd / nrt_vaccination.record_status_cd | `ACTIVE` | `STD_NBS_PROCESSING_DECISION_ALL` family | the d_vaccination postprocessing SP at lines 250 / 357 reads `nrt.record_status_cd` directly (no transform), so D_VACCINATION.RECORD_STATUS_CD = 'ACTIVE' on both rows. |
| intervention.prog_area_cd | `IMM` | NBS program-area | per foundation pattern |
| intervention.jurisdiction_cd (v2) | `130001` | `S_JURDIC_C` (via `nrt_srte_Jurisdiction_code`) | Fulton County — same as Investigation/Treatment Tier 1 chose |

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| D_VACCINATION | (none — all 21 live columns covered across foundation/v2 variants.) | n/a | n/a |
| F_VACCINATION | (none — all 6 live columns covered. The 4 cross-subject FK columns are populated with sentinel 1 at Tier 1 isolation; merged-fixture sequence resolves them to non-sentinel keys.) | n/a | n/a |

## Gaps reported

### LINK_REQUIRED
- **F_VACCINATION cross-subject FK columns** (4 of 6): `PATIENT_KEY`, `VACCINE_GIVEN_BY_KEY`, `VACCINE_GIVEN_BY_ORG_KEY`, `INVESTIGATION_KEY` — all currently resolve to **sentinel 1** via `COALESCE(<lookup>, 1)`. Resolved to non-sentinel keys in merged-fixture sequence after the upstream subjects' chains have populated their dimensions: Patient Tier 1 → D_PATIENT, Provider Tier 1 → D_PROVIDER, Organization Tier 1 → D_ORGANIZATION, Investigation Tier 1 → INVESTIGATION. **Importantly**, this is NOT a fixture failure at Tier 1 isolation — both INSERTs succeed cleanly with sentinel 1 keys because F_VACCINATION has no FK constraints.
- **Tier 2 cross-subject edges** required for the event SP to surface rows: `participation.type_cd='SubOfVacc'` (Vaccination → Patient) — read at sp_vaccination_event line 108 (INNER JOIN); `participation.type_cd='PerformerOfVacc'` (Vaccination → Provider/Organization) — read at lines 1135, 1146; `act_relationship.type_cd='1180'` (Vaccination → Investigation) — read at line 1167. The event SP's SubOfVacc INNER JOIN means the event SP returns 0 rows at Tier 1 isolation. The postprocessing SPs are unaffected because they read `nrt_vaccination` directly.

### OUT_OF_SCOPE
- **Catalog overcount on D_VACCINATION** (catalog: 24 / live: 21) — known catalog drift; we measure against live. The catalog row count includes 3 columns that don't exist as physical columns in baseline 6.0.18.1 (per `rtr_target_columns.md` entries `THEN`, `RDB_COLUMN_NM`, plus possibly one more — these are dynamic-LDF columns that would only exist if `NRT_METADATA_COLUMNS` for `D_VACCINATION` had rows, which it does not in baseline — verified). All 21 live columns are populated.
- **`sp_vaccination_event`** returns 0 rows at Tier 1 isolation — by-design event SP is a JSON contract test that depends on Tier 2 cross-subject participation/act_relationship rows. Documented per Treatment-canary precedent.
- **`sp_covid_vaccination_datamart_postprocessing`** — explicitly out-of-scope per the per-subject prompt. The d_vaccination postprocessing SP's tail SELECT (line 433) filters foundation's `material_cd IN ('207', '208', '213')` and surfaces a `Covid_Vaccination_Datamart` reference, but invoking the datamart SP is out of Tier 1 scope (Datamart tier).
- **`sp_ldf_intervention_event`** — explicitly out-of-scope per the per-subject prompt. The LDF chain has no rows here because no `nbs_answer` rows exist for our intervention UIDs (LDF data is form-based and form metadata for the v1 single-condition-per-family is Hep A which doesn't drive Vaccination LDFs).
- **`sp_ldf_vaccine_prevent_diseases_datamart_postprocessing`** — explicitly out-of-scope per the per-subject prompt.
- **`nrt_vaccination_answer`** — no rows authored. `NRT_METADATA_COLUMNS` for `D_VACCINATION` is empty in baseline (verified: `SELECT COUNT(*) FROM RDB_MODERN.dbo.NRT_METADATA_COLUMNS WHERE TABLE_NAME='D_VACCINATION'` returns 0), so the SP's PIVOT on dynamic LDF columns is a no-op. Authoring nrt_vaccination_answer rows would not add coverage at Tier 1 isolation; reserved for Tier 3 LDF coverage if/when LDF metadata rows are added to the baseline.

### SRTE_GAP
- (none — every code referenced is grounded in baseline SRTE. `intervention.method_cd='IM'` is a literal placeholder not read by the d_vaccination postprocessing SP and not asserted against SRTE.)

### FOUNDATION_GAP
- (none — the foundation's `intervention` row at UID 20000160 is the only parent row required. Foundation already provides the `act + intervention` parent rows; no additive child rows needed since Vaccination has no internal entity-locator-participation pattern.)

## Decisions made under ambiguity

- **Variant strategy:** **2 variants** — the standard Tier 1 pattern:
  - **Foundation** (UID 20000160) — sparse on clinical columns, blank strings on the 5 NULLIF-guarded text columns (AGE_AT_VACCINATION_UNIT, VACCINATION_ADMINISTERED_NM, VACCINATION_ANATOMICAL_SITE, VACCINE_INFO_SOURCE, VACCINE_MANUFACTURER_NM). Exercises both null-propagation and blank-to-NULL transform paths. Soft refs (patient/provider/org/phc) all NULL → exhibits the no-cross-subject path on F_VACCINATION (still resolves to sentinel-1 keys, confirming the COALESCE is the actual sentinel source, not the lookup).
  - **v2** (UID 20110010) — fully attributed Hep A adult vaccination (CVX `52`). All clinical columns populated, soft refs point at foundation Patient/Provider/Org/Investigation. Drives populated path on every D_VACCINATION column the postprocessing SP reads from nrt_vaccination.

- **Vaccine code chosen for v2:** `VAC_NM cd='52'` (Hep A, adult). Per the per-subject prompt: "Pick a real vaccine code from baseline SRTE for v2 (CVX 31 Hep A pediatric or CVX 52 Hep A adult ideally for v1 condition consistency)". Verified `52` exists in `VAC_NM` (also exists in `INT_TYPE`, `MSL_VAC_NM`, `RUB_VAC_NM`). Hep A adult aligns with foundation Investigation `condition_cd='10110'` (Hepatitis A acute) per v1 single-condition-per-family. CVX 31 (Hep A pediatric) was the alternate choice; chose 52 (adult) since the foundation Patient `birth_time='1990-01-15'` makes the vaccine subject an adult.

- **Foundation enrichment via no UPDATEs:** the foundation `intervention` row is left untouched. No additive child ODSE rows are needed for Vaccination — vaccination is an Act, not an Entity, and has no internal `entity_locator_participation` pattern. The v2 path covers the populated branches; foundation row's NULL clinical columns + blank NULLIF columns cover the null path. Per-template guidance respected: no UPDATE on foundation rows.

- **GENERATED ALWAYS columns omitted:** `nrt_vaccination.refresh_datetime` (generated_always_type=1, AS_ROW_START) and `nrt_vaccination.max_datetime` (generated_always_type=2, AS_ROW_END). Same for `nrt_vaccination_answer`. The system fills these on INSERT.

- **No `dbo.nrt_vaccination_key` hand-write.** The d_vaccination postprocessing SP allocates surrogate keys via IDENTITY in `nrt_vaccination_key` at lines 205-209. IDENT_CURRENT was 2 going in (one sentinel row at d_vaccination_key=1 already), so the IDENTITY allocator produces clean keys 2, 3 for our 2 variants. No Lab-style IDENTITY-counter quirk — the baseline IDENTITY counter is sane.

- **No participation / act_relationship rows authored.** The event SP requires (INNER JOIN at line 108) `NBS_ACT_ENTITY.TYPE_CD='SubOfVacc'`, plus LEFT JOINs (lines 1135, 1146, 1167) for `PerformerOfVacc` participation and `act_relationship.type_cd='1180'` for VaccinationToPHC. These are CROSS-subject edges and are explicitly Tier 2 territory. The event SP returns 0 rows at Tier 1 isolation; this is documented behavior, not a failure. The postprocessing SPs read cross-subject UIDs directly from `nrt_vaccination` columns (we author them as soft refs), independent of ODSE participation/act_relationship rows.

- **No `nrt_vaccination_answer` rows.** The d_vaccination postprocessing SP's PIVOT logic (lines 225-298 / 313-399) operates on `NRT_METADATA_COLUMNS` for `D_VACCINATION`. That table has 0 rows for `D_VACCINATION` in baseline 6.0.18.1, so `@PivotColumns` is NULL and the SP skips the dynamic-LDF-column branches entirely. Authoring `nrt_vaccination_answer` rows at Tier 1 would not add coverage; reserved for Tier 3 if LDF metadata is added to baseline.

- **Trailing SELECT in d_vaccination postprocessing returns Covid_Vaccination_Datamart row**: at line 433 the SP filters `nrt.material_cd IN ('207', '208', '213')` and joins `nrt_datamart_metadata` for the COVID datamart marker. Foundation's `material_cd='207'` matches (carried over from foundation `intervention.material_cd='207'`), so the SP's tail SELECT projects one row referencing the `Covid_Vaccination_Datamart` SP. This is an event-marker projection, not an INSERT into D_VACCINATION; documented for completeness. v2 (`material_cd='52'`) does not match the COVID filter.

## UID allocation table

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20110010 | @dbo_Act_vaccination_v2_uid | v2 Vaccination `act.act_uid` / `intervention.intervention_uid` | Class `INTV`, mood `EVN`. Fully-attributed Vaccination variant — Hep A adult (VAC_NM cd='52'), aligned with foundation Investigation condition_cd='10110' (Hep A acute). Drives populated path on every D_VACCINATION column the postprocessing SP reads from nrt_vaccination. |

Unused UIDs in Vaccination Tier 1 block (20110000-20110009, 20110011-20119999) are reserved for future Vaccination Tier 1 / Tier 3 amendments. Do not allocate from this range outside of Vaccination Tier 1.

The fixture also writes:
- 1 row to `NBS_ODSE.dbo.act` (v2 Vaccination).
- 1 row to `NBS_ODSE.dbo.intervention` (v2 Vaccination).

In RDB_MODERN:
- 2 rows to `dbo.nrt_vaccination` (foundation 20000160, v2 20110010).

No `nrt_vaccination_answer` rows. No surrogate-key tables hand-authored. No cross-subject `act_relationship`, `participation`, `nbs_act_entity` rows. No INSERTs into other subjects' RDB_MODERN output tables (D_PATIENT, INVESTIGATION, D_ORGANIZATION, D_PROVIDER). Foundation rows unmodified.
