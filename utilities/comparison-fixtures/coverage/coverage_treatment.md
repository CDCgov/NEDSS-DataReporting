# Coverage: treatment (Treatment)

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 20100000 - 20109999
- Foundation dependencies:
  - `@dbo_Act_treatment_uid` (20000150) — foundation Treatment Act / treatment row (sparse — see `coverage_foundation.md` "Columns deliberately skipped: treatment").
  - `@dbo_Entity_patient_uid` (20000000) — referenced via `nrt_treatment.patient_treatment_uid` (soft).
  - `@dbo_Entity_provider_uid` (20000010) — referenced via `nrt_treatment.provider_uid` (soft).
  - `@dbo_Entity_organization_uid` (20000020) — referenced via `nrt_treatment.organization_uid` (soft).
  - `@dbo_Act_morbidity_uid` (20000130) — referenced via `nrt_treatment.morbidity_uid` (soft).
  - `@dbo_Act_investigation_uid` (20000100) — referenced via `nrt_treatment.associated_phc_uids` CSV (soft).
- Other-agent dependencies: baseline SRTE only (`code_value_general` for `TREAT_DRUG`, `TREAT_DOSE_UNIT`, `TREAT_FREQ_UNIT`, `TREAT_DUR_UNIT`, `TREAT_ROUTE`, `TREAT_COMPOSITE`).

## SPs verified
- `dbo.sp_treatment_event @treatment_uids = N'20000150,20100010,20100020', @debug = 0` — exit code 0; emits a JSON-shaped projection (one row per surfaced treatment_uid; foundation surfaces because of the additive `treatment_administered` row authored in this fixture, satisfying the SP's INNER JOIN at line 65). 3 rows projected.
- `dbo.sp_nrt_treatment_postprocessing @treatment_uids = N'20000150,20100010,20100020', @debug = 0` — exit code 0; `job_flow_log` shows step 999 / `step_name='SP_COMPLETE'` / `status_type='COMPLETE'`. INSERT INTO TREATMENT: 3 rows. INSERT INTO TREATMENT_EVENT: 3 rows.

## Apply / FK check
- `sqlcmd -i fixtures/00_foundation/00_foundation.sql` exit code 0 (existing canary).
- `sqlcmd -i fixtures/10_subjects/treatment.sql` exit code 0 — **clean apply on first iteration**.
- ODSE INSERTs:
  - 2 rows to `act_id` (foundation Treatment local-id + v2 Treatment local-id).
  - 2 rows to `act` (v2 + v3 Treatment).
  - 2 rows to `treatment` (v2 + v3).
  - 3 rows to `treatment_administered` (foundation enrichment + v2 + v3).
- RDB_MODERN INSERTs:
  - 3 rows to `dbo.nrt_treatment` (foundation, v2, v3).
- `DBCC CHECKCONSTRAINTS` on `dbo.act`, `dbo.act_id`, `dbo.treatment`, `dbo.treatment_administered`: all clean.
- **Iteration count: 1** baseline-reset cycle (the 3-variant version verified end-to-end on first apply against a fresh baseline).

## Coverage by target table

### TREATMENT — 16 / 16 live columns populated

Live column count: 16 (matches per-subject prompt's "Live: 16 cols / catalog: 17"). The catalog overcount of 1 is consistent with previously-observed catalog drifts (e.g., Lab 67 catalog / 66 live; Notification's CUSTOM_<x> drift).

| Column | Populated on foundation (UID 20000150) | Populated on v2 (UID 20100010) | Populated on v3 (UID 20100020) | Source / SP transform |
| --- | --- | --- | --- | --- |
| TREATMENT_KEY | yes (=2, IDENTITY) | yes (=3) | yes (=4) | `nrt_treatment_key.d_treatment_key` IDENTITY at SP line 414-418 |
| TREATMENT_UID | yes | yes | yes | `nrt_treatment.treatment_uid` |
| TREATMENT_LOCAL_ID | yes (`TRT20000150GA01`) | yes (`TRT20100010GA01`) | yes (`TRT20100020GA01`) | `nrt_treatment.local_id` |
| TREATMENT_NM | NULL (null path) | yes (`Acyclovir, 200 mg, PO, 5ID, x 5 days`) | yes (`Free-text custom treatment plan`) | `trim(nrt.treatment_name)` (line 79) |
| TREATMENT_DRUG | NULL | yes (`500`) | NULL | `nrt.treatment_drug` (line 80) — TREAT_DRUG code |
| TREATMENT_DOSAGE_STRENGTH | NULL | yes (`200`) | NULL | `nrt.treatment_dosage_strength` (line 81) |
| TREATMENT_DOSAGE_STRENGTH_UNIT | NULL | yes (`mg`) | NULL | `nrt.treatment_dosage_strength_unit` (line 82) — TREAT_DOSE_UNIT code |
| TREATMENT_FREQUENCY | NULL | yes (`TID`) | NULL | `nrt.treatment_frequency` (line 83) — TREAT_FREQ_UNIT code |
| TREATMENT_DURATION | NULL | yes (`5`) | NULL | `nrt.treatment_duration` (line 84) |
| TREATMENT_DURATION_UNIT | NULL | yes (`D`) | NULL | `nrt.treatment_duration_unit` (line 85) — TREAT_DUR_UNIT code |
| TREATMENT_COMMENTS | NULL | yes (`Tier 1 Treatment v2 — clinician comments on therapy course.`) | NULL | `trim(nrt.treatment_comments)` (line 86) |
| TREATMENT_ROUTE | NULL | yes (`C0205531`) | NULL | `nrt.treatment_route` (line 87) — TREAT_ROUTE code |
| CUSTOM_TREATMENT | NULL (cd!='OTH' → ELSE NULL) | NULL (cd='1' → ELSE NULL) | yes (`Free-text custom treatment plan`) | `CASE WHEN nrt.cd='OTH' THEN nrt.treatment_name ELSE NULL END` (line 88). v3 (cd='OTH') exhibits the populated branch; foundation (cd='TRMT100') and v2 (cd='1') exhibit the ELSE-NULL branch. |
| TREATMENT_SHARED_IND | yes (`F`) | yes (`T`) | yes (`F`) | `nrt.treatment_shared_ind` (line 89) |
| TREATMENT_OID | NULL | yes (=20100010) | NULL | `nrt.treatment_oid` (line 90). Note: `nrt_treatment.treatment_oid` is varchar(100) but `TREATMENT.TREATMENT_OID` is bigint; SQL Server implicit-converts during INSERT. |
| RECORD_STATUS_CD | yes (`ACTIVE`) | yes (`ACTIVE`) | yes (`ACTIVE`) | `nrt.record_status_cd` (line 91, no transform — passed through verbatim, unlike Morbidity which applies `dbo.fn_get_record_status`) |

The two-variant + extra cd='OTH' v3 pattern jointly exercises:
- **Null-propagation path**: foundation's all-NULL clinical columns produce TREATMENT_NM..TREATMENT_ROUTE all NULL.
- **Populated path**: v2 fills every clinical column.
- **CUSTOM_TREATMENT 'OTH' branch**: v3 exhibits the THEN branch where treatment_name surfaces as CUSTOM_TREATMENT. v2 + foundation cover the ELSE-NULL branch.
- **TREATMENT_SHARED_IND** populated path includes both `T` (v2) and `F` (foundation, v3) values.

### TREATMENT_EVENT — 11 / 11 live columns populated

Live column count: 11 (matches per-subject prompt's "Live: 11 cols / catalog: 12"). Same catalog-vs-live drift pattern as TREATMENT.

All cross-subject FK columns COALESCE to sentinel 1 in the SP (lines 184-193). At Tier 1 isolation D_PATIENT / D_ORGANIZATION / D_PROVIDER / RDB_DATE / dbo.condition / MORBIDITY_REPORT / INVESTIGATION / LDF_GROUP all return no row matching our soft refs, so every COALESCE resolves to 1. No FK constraints on TREATMENT_EVENT, so the INSERT succeeds.

| Column | Foundation (TREATMENT_KEY=2) | v2 (TREATMENT_KEY=3) | v3 (TREATMENT_KEY=4) | Source / SP transform |
| --- | --- | --- | --- | --- |
| TREATMENT_KEY | yes (=2) | yes (=3) | yes (=4) | non-sentinel from `nrt_treatment_key` IDENTITY |
| TREATMENT_DT_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | `COALESCE(dtt.DATE_KEY, 1)` (line 184); RDB_DATE empty in baseline. |
| PATIENT_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | `COALESCE(p.PATIENT_KEY, 1)` (line 185); D_PATIENT empty for these UIDs at Tier 1 isolation. |
| TREATMENT_PROVIDING_ORG_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | `COALESCE(org.ORGANIZATION_KEY, 1)` (line 186); D_ORGANIZATION empty. |
| TREATMENT_PHYSICIAN_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | `COALESCE(prv.PROVIDER_KEY, 1)` (line 187); D_PROVIDER empty. |
| TREATMENT_COUNT | yes (=1) | yes (=1) | yes (=1) | hardcoded `1` (line 188). |
| MORB_RPT_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | `COALESCE(mrb.MORB_RPT_KEY, 1)` (line 190); MORBIDITY_REPORT empty for these UIDs at Tier 1 isolation. |
| INVESTIGATION_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | `COALESCE(inv.INVESTIGATION_KEY, 1)` (line 191); INVESTIGATION empty for these CASE_UIDs. |
| CONDITION_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | `COALESCE(cnd.CONDITION_KEY, 1)` (line 192); dbo.condition empty in baseline (populated by `sp_nrt_srte_condition_code_postprocessing`, out-of-scope for this fixture). |
| LDF_GROUP_KEY | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | `COALESCE(ldf.LDF_GROUP_KEY, 1)` (line 193); LDF_GROUP empty. |
| RECORD_STATUS_CD | yes (`ACTIVE`) | yes (`ACTIVE`) | yes (`ACTIVE`) | `nrt.record_status_cd` (line 194). |

Expected merged-fixture sequence behavior: the 8 sentinel-1 FK columns will resolve to non-sentinel keys after upstream Tier 1 chains and infrastructure SPs run (Patient → D_PATIENT, Organization → D_ORGANIZATION, Provider → D_PROVIDER, Investigation → INVESTIGATION, Morbidity → MORBIDITY_REPORT, `sp_get_date_dim` → RDB_DATE, `sp_nrt_srte_condition_code_postprocessing` → dbo.condition, LDF chain → LDF_GROUP). Tier 2 cross-subject `act_relationship` rows (TreatmentToPHC, TreatmentToMorb) and `participation` rows (SubjOfTrmt / ProviderOfTrmt / ReporterOfTrmt) wire the same UIDs at the ODSE-graph level; the postprocessing SP resolves cross-subject keys via `nrt_treatment` soft-ref columns we authored, not via ODSE participation/act_relationship rows.

## SRTE codes referenced

| Table.column | Value | code_set_nm | Notes |
| --- | --- | --- | --- |
| treatment.cd / nrt_treatment.cd (v2) | `1` | `TREAT_COMPOSITE` | verified — Acyclovir, 200 mg, PO, 5ID, x 5 days. Single-condition-per-family v1 (the per-subject prompt suggests `condition_cd='10110'` for Hep A; treatment.cd is a separate code set — TREAT_COMPOSITE — and we ground it there. The v2 Treatment is logically associated with the foundation Investigation (Hep A acute, condition_cd='10110') via `nrt_treatment.associated_phc_uids='20000100'` soft ref.) |
| treatment.cd (v3) | `OTH` | (literal value — no SRTE FK; SP CASE compares the literal string 'OTH' at line 88) | Drives the CUSTOM_TREATMENT THEN branch. |
| treatment_administered.cd / nrt_treatment.treatment_drug (v2) | `500` | `TREAT_DRUG` | verified — Acyclovir |
| treatment_administered.dose_qty_unit_cd / nrt_treatment.treatment_dosage_strength_unit (v2) | `mg` | `TREAT_DOSE_UNIT` | verified — milligram |
| treatment_administered.interval_cd / nrt_treatment.treatment_frequency (v2) | `TID` | `TREAT_FREQ_UNIT` | verified — Three times a day |
| treatment_administered.effective_duration_unit_cd / nrt_treatment.treatment_duration_unit (v2) | `D` | `TREAT_DUR_UNIT` | verified — Days |
| treatment_administered.route_cd / nrt_treatment.treatment_route (v2) | `C0205531` | `TREAT_ROUTE` | verified — PO (oral). Note: SRTE PO is encoded as the C-code, not the literal 'PO'. |
| treatment.class_cd | `TRMT` | `ACT_CLS` | per foundation pattern |
| act.class_cd | `TRMT` | `ACT_CLS` | v2 + v3 |
| act.mood_cd | `EVN` | `ACT_MOOD` | event mood |
| treatment.shared_ind / nrt_treatment.treatment_shared_ind | `F`, `T` | char(1) flag — not coded | foundation/v3 sparse; v2 shared |
| treatment.record_status_cd / nrt_treatment.record_status_cd | `PROCESSED` (ODSE), `ACTIVE` (nrt) | `STD_NBS_PROCESSING_DECISION_ALL` family | ODSE status `PROCESSED` is the source-system value; `nrt_treatment.record_status_cd` is `ACTIVE` (the staging-row passthrough). The postprocessing SP at line 91 reads `nrt.record_status_cd` directly (no transform), so TREATMENT.RECORD_STATUS_CD = 'ACTIVE'. |
| act_id.type_cd | `TRMT_LOCAL_ID` | conventional (not SRTE-FK) | matches morbidity foundation enrichment pattern |
| act_id.assigning_authority_cd | `2.16.840.1.114222.4.5.1.1` | OID | conventional |
| treatment.prog_area_cd | `STD` | NBS program-area | per foundation pattern |
| treatment.jurisdiction_cd (v2) | `130001` | `S_JURDIC_C` (via `nrt_srte_Jurisdiction_code`) | Fulton County — same as Investigation/Morbidity Tier 1 chose |
| treatment.jurisdiction_cd (v3) | `130001` | `S_JURDIC_C` | same |

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| TREATMENT | (none — all 16 live columns covered across foundation/v2/v3 variants.) | n/a | n/a |
| TREATMENT_EVENT | (none — all 11 live columns covered. The 8 cross-subject FK columns are populated with sentinel 1 at Tier 1 isolation; merged-fixture sequence resolves them to non-sentinel keys.) | n/a | n/a |

## Gaps reported

### LINK_REQUIRED
- **TREATMENT_EVENT cross-subject FK columns** (8 of 11): `TREATMENT_DT_KEY`, `PATIENT_KEY`, `TREATMENT_PROVIDING_ORG_KEY`, `TREATMENT_PHYSICIAN_KEY`, `MORB_RPT_KEY`, `INVESTIGATION_KEY`, `CONDITION_KEY`, `LDF_GROUP_KEY` — all currently resolve to **sentinel 1** via `COALESCE(<lookup>, 1)`. Resolved to non-sentinel keys in merged-fixture sequence after the upstream subjects' chains have populated their dimensions: Patient Tier 1 → D_PATIENT, Organization Tier 1 → D_ORGANIZATION, Provider Tier 1 → D_PROVIDER, Investigation Tier 1 → INVESTIGATION, Morbidity Tier 1 → MORBIDITY_REPORT, infrastructure SP `sp_get_date_dim` → RDB_DATE, infrastructure SP `sp_nrt_srte_condition_code_postprocessing` → dbo.condition, LDF chain → LDF_GROUP. **Importantly**, this is NOT a fixture failure at Tier 1 isolation — both INSERTs succeed cleanly with sentinel 1 keys because TREATMENT_EVENT has no FK constraints. The Treatment SP differs from Morbidity here: Morbidity's PATIENT_KEY had no COALESCE and was NOT NULL, blocking that fixture's INSERT at isolation. Treatment's all-cross-subject-COALESCE pattern means full 11/11 column population at isolation.

### OUT_OF_SCOPE
- **Catalog overcount on TREATMENT** (catalog: 17 / live: 16) — known catalog drift; we measure against live. The catalog row count includes a 17th column that doesn't exist in baseline 6.0.18.1. Same drift pattern as Lab (catalog 67 / live 66) and Morbidity (catalog 31 / live 30). All 16 live columns are populated.
- **Catalog overcount on TREATMENT_EVENT** (catalog: 12 / live: 11) — same drift pattern. All 11 live columns are populated.
- **Tier 2 cross-subject edges** — `act_relationship` rows for TreatmentToPHC (Treatment → Investigation) and TreatmentToMorb (Treatment → Morbidity), and `participation` rows for SubjOfTrmt / ProviderOfTrmt / ReporterOfTrmt. These are explicitly Tier 2 territory per the per-subject prompt and STRATEGY.md "Tier 2 — Links". The event SP's projection at Tier 1 isolation produces NULL for organization_uid / provider_uid / patient_treatment_uid / morbidity_uid in the JSON output (LEFT JOINs on participation and act_relationship). The postprocessing SP reads cross-subject UIDs directly from `nrt_treatment` columns we hand-author (soft refs to foundation entities), so postprocessing is unaffected.
- **CUSTOM_TREATMENT 'OTH' branch covered intentionally** — the third variant (v3, cd='OTH') was added beyond the standard two-variant pattern to exercise this branch within Tier 1. This is in-scope rather than deferred.

### SRTE_GAP
- (none — every code referenced is grounded in baseline SRTE or is a literal-string the SP CASE-compares directly: `'OTH'`, the foundation `'TRMT100'`, the act_id type_cd `'TRMT_LOCAL_ID'`.)

### FOUNDATION_GAP
- (none — the foundation's `treatment` row at UID 20000150 is the only parent row required. Foundation does NOT have a `treatment_administered` row, but adding one at Tier 1 is allowed-and-encouraged additive enrichment per the template's "additive child rows tied to a foundation UID" guidance.)

## Decisions made under ambiguity

- **Variant strategy:** **3 variants** instead of the standard 2:
  - **Foundation** (UID 20000150) — sparse, all clinical columns NULL on `nrt_treatment`. Exercises the SP's null-propagation path on TREATMENT_NM / DRUG / DOSAGE / FREQUENCY / DURATION / COMMENTS / ROUTE / OID.
  - **v2** (UID 20100010) — fully attributed Acyclovir composite (cd='1'). All clinical columns populated. Exercises the SP's populated path on every TREATMENT-dim column.
  - **v3** (UID 20100020) — cd='OTH' free-text. Exercises the CUSTOM_TREATMENT CASE THEN branch. Other clinical columns NULL since v2 already covers their populated path.

- **Foundation enrichment without UPDATE:** the foundation `treatment` row is left untouched. We add a NEW `treatment_administered` row keyed on 20000150 (foundation has none) so the event SP's INNER JOIN at line 65 surfaces foundation in the output. Per-template guidance: "Additive child rows tied to a foundation UID are allowed and encouraged."

- **Treatment code chosen for v2:** `cd='1'` (TREAT_COMPOSITE — Acyclovir). The per-subject prompt says "use a treatment code from `nrt_srte_Treatment_code` (verify which codes are present)". Verified the seed contains 1, 10, 100, 101, 102 etc.; chose 1 as the canonical Acyclovir composite. The treatment is logically aligned with foundation Investigation's condition_cd='10110' (Hepatitis A acute) — Acyclovir is reasonable for HAV-related antiviral therapy in the context of fixture data. (Strictly accurate clinical pairing isn't required; the comparison test diffs RDB vs RDB_MODERN on shape, not on clinical realism.)

- **`condition_cd` is NOT a Treatment column.** The per-subject prompt mentions `condition_cd='10110'` (Hep A acute) per STRATEGY.md v1 single-condition-per-family. Treatment doesn't carry a condition code directly — the condition is resolved in TREATMENT_EVENT.CONDITION_KEY via the join chain `nrt_treatment.associated_phc_uids → nrt_investigation.cd → dbo.condition.CONDITION_CD → CONDITION_KEY` (SP lines 200-205). At Tier 1 isolation `dbo.condition` is empty, so CONDITION_KEY = 1 (sentinel). In merged-fixture sequence after `sp_nrt_srte_condition_code_postprocessing` runs, CONDITION_KEY will resolve to the real key for code `10110` based on v2's `associated_phc_uids='20000100'` and Investigation Tier 1's `nrt_investigation.cd='10110'` for that PHC.

- **`record_status_cd` passthrough vs Morbidity transform:** Treatment's postprocessing SP at line 91 reads `nrt.record_status_cd` directly with no transform, unlike Morbidity which applies `CASE 'PROCESSED' THEN 'ACTIVE'`. The synthetic `nrt_treatment` row therefore carries `'ACTIVE'` directly (not `'PROCESSED'`), matching the staging-row format that production CDC would emit after upstream service applied the transform. The ODSE `treatment.record_status_cd` is set to `'PROCESSED'` (matching Morb's ODSE shape) but the SP reads from nrt_treatment, not from ODSE.

- **GENERATED ALWAYS columns omitted:** `nrt_treatment.refresh_datetime` (generated_always_type=1, AS_ROW_START) and `nrt_treatment.max_datetime` (generated_always_type=2, AS_ROW_END). The system fills these on INSERT.

- **No `dbo.nrt_treatment_key` hand-write.** The postprocessing SP allocates surrogate keys via IDENTITY in `nrt_treatment_key` at line 414-418. IDENT_CURRENT was 2 going in (one sentinel row at d_treatment_key=1 already), so the IDENTITY allocator produces clean keys 2, 3, 4 for our 3 variants. **No Lab-style IDENTITY-counter quirk** — the baseline IDENTITY counter is in a sane state. (Lab's quirk affected `nrt_lab_test_result_group_key` and `nrt_lab_test_key`; Treatment's `nrt_treatment_key` is unaffected.)

- **No participation / act_relationship rows authored.** The event SP requires (LEFT JOIN) `participation.type_cd IN ('SubjOfTrmt', 'ProviderOfTrmt', 'ReporterOfTrmt')` and `act_relationship.type_cd IN ('TreatmentToMorb', 'TreatmentToPHC')` to populate organization_uid / provider_uid / patient_treatment_uid / morbidity_uid / associated_phc_uids in the JSON projection. These are CROSS-subject edges (Treatment → Patient/Provider/Org/Morb/Investigation) and are explicitly Tier 2 territory. The event SP runs cleanly with these LEFT JOINs returning NULL — they do not block. The postprocessing SP reads cross-subject UIDs directly from `nrt_treatment` columns (we author them as soft refs), independent of ODSE participation/act_relationship rows.

- **`treatment_oid` type mismatch handled implicitly.** `nrt_treatment.treatment_oid` is `varchar(100)` but `RDB_MODERN.dbo.TREATMENT.TREATMENT_OID` is `bigint`. The postprocessing SP at line 90 does no explicit CAST — relies on SQL Server implicit conversion. We chose `'20100010'` (a string of digits) for v2 so the implicit conversion to bigint succeeds (= 20100010). Setting a non-numeric string would fail with a conversion error; documenting the choice for future fixture authors.

## UID allocation table

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20100010 | @dbo_Act_treatment_v2_uid | v2 Treatment `act.act_uid` / `treatment.treatment_uid` / `treatment_administered.treatment_uid` | Class `TRMT`, mood `EVN`. Fully-attributed Treatment variant — Acyclovir composite (TREAT_COMPOSITE cd='1'). Drives populated path on every TREATMENT-dim column the postprocessing SP reads from nrt_treatment. |
| 20100020 | @dbo_Act_treatment_v3_uid | v3 Treatment `act.act_uid` / `treatment.treatment_uid` / `treatment_administered.treatment_uid` | Class `TRMT`, mood `EVN`. cd='OTH' (literal string, no SRTE code) variant — drives the CUSTOM_TREATMENT CASE THEN branch (line 88 of `sp_nrt_treatment_postprocessing`). Other clinical columns NULL on this row since v2 already covers their populated path. |

Unused UIDs in Treatment Tier 1 block (20100000-20100009, 20100011-20100019,
20100021-20109999) are reserved for future Treatment Tier 1 / Tier 3
amendments. Do not allocate from this range outside of Treatment Tier 1.

The fixture also writes:
- 1 row to `NBS_ODSE.dbo.act_id` keyed on `act_uid=20000150` (foundation Treatment enrichment — foundation has no act_id rows on Treatment).
- 1 row to `NBS_ODSE.dbo.act_id` keyed on `act_uid=20100010` (v2 Treatment local-id).
- 1 row to `NBS_ODSE.dbo.treatment_administered` keyed on `treatment_uid=20000150` (foundation enrichment — foundation has none; required for the event SP's INNER JOIN to surface the foundation Treatment).
- 2 rows to `NBS_ODSE.dbo.act` (v2 + v3 Treatment).
- 2 rows to `NBS_ODSE.dbo.treatment` (v2 + v3).
- 2 rows to `NBS_ODSE.dbo.treatment_administered` (v2 + v3).

In RDB_MODERN:
- 3 rows to `dbo.nrt_treatment` (foundation 20000150, v2 20100010, v3 20100020).

No surrogate-key tables hand-authored. No cross-subject `act_relationship`, `participation`, `nbs_act_entity` rows. No INSERTs into other subjects' RDB_MODERN output tables (D_PATIENT, INVESTIGATION, CONDITION, RDB_DATE, MORBIDITY_REPORT, D_ORGANIZATION, D_PROVIDER, LDF_GROUP). Foundation rows unmodified (only additive child rows authored).
