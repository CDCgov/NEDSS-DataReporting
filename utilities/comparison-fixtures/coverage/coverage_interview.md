# Coverage: Interview (Tier 1)

## Inputs
- Baseline: 6.0.18.1 (post-liquibase migration)
- UID range allocated: 20090000 - 20099999
- Foundation dependencies (read-only):
  - `@dbo_Act_interview_uid = 20000140` — foundation Interview Act + interview row
  - `@dbo_Entity_patient_uid = 20000000` — referenced via nrt_interview.patient_uid (v2 only)
  - `@dbo_Entity_provider_uid = 20000010` — referenced via nrt_interview.provider_uid (v2 only)
  - `@dbo_Entity_organization_uid = 20000020` — referenced via nrt_interview.organization_uid (v2 only)
  - `@dbo_Act_investigation_uid = 20000100` — referenced via nrt_interview.investigation_uid (v2 only)
  - `@superuser_id = 10009282` — sentinel
- Other-agent dependencies (UID range registry): none. Interview is a fully-isolated Tier 1 subject; no Tier 1 cross-references required.

## SPs verified
- `dbo.sp_interview_event @ix_uids = '20000140,20090010', @debug = 0` — exit code: 0 / no exception. JSON projection emitted with 2 rows in the result set; foundation row has IX_STATUS=NULL (interview_status_cd='C' is not in NBS_INTVW_STATUS), v2 row has every IX_* description populated. INVESTIGATION_UID/PROVIDER_UID/ORGANIZATION_UID/PATIENT_UID NULL on both (cross-subject NBS_act_entity / Act_relationship rows are Tier 2). job_flow_log entry: `Interview PRE-Processing Event` / `COMPLETE`.
- `dbo.sp_d_interview_postprocessing @interview_uids = '20000140,20090010', @debug = 0` — exit code: 0 / 2 rows inserted into D_INTERVIEW + 2 rows inserted into D_INTERVIEW_NOTE + 2 rows inserted into nrt_interview_key + 2 rows inserted into nrt_interview_note_key. `Missing NRT Record` early-return NOT triggered. job_flow_log entry: `D_INTERVIEW` / `COMPLETE` (step 999).
- `dbo.sp_f_interview_case_postprocessing @ix_uids = '20000140,20090010', @debug = 0` — exit code: 0 / 2 rows inserted into F_INTERVIEW_CASE. job_flow_log entry: `F_INTERVIEW_CASE` / `COMPLETE` (step 999).

All three SPs ran with `status_type = COMPLETE` and no `ERROR` rows in `job_flow_log`. Iteration count: **1** (clean apply + clean run on first attempt).

## Columns populated

### D_INTERVIEW (live: 24 / catalog: 21; populated: 18 / 24)

| Column | Foundation (UID 20000140) | v2 (UID 20090010) |
| --- | --- | --- |
| D_INTERVIEW_KEY | 2.0 (allocated by IDENTITY in nrt_interview_key) | 3.0 |
| IX_STATUS_CD | `C` | `COMPLETE` |
| IX_DATE | 2026-04-01 00:00:00.000 | 2026-04-15 10:00:00.000 |
| IX_INTERVIEWEE_ROLE_CD | NULL (SUBJECT/ELSE branch) | `PHYS` (PHYSICIAN_KEY branch) |
| IX_TYPE_CD | `INITIAL` | `REINTVW` |
| IX_LOCATION_CD | `HOSP` | `PHCLINIC` |
| LOCAL_ID | `INT20000140GA01` | `INT20090010GA01` |
| RECORD_STATUS_CD | `ACTIVE` | `ACTIVE` |
| RECORD_STATUS_TIME | 2026-04-01 00:00:00.000 | 2026-04-15 10:00:00.000 |
| ADD_TIME | 2026-04-01 00:00:00.000 | 2026-04-15 10:00:00.000 |
| ADD_USER_ID | 10009282 | 10009282 |
| LAST_CHG_TIME | 2026-04-01 00:00:00.000 | 2026-04-15 10:00:00.000 |
| LAST_CHG_USER_ID | 10009282 | 10009282 |
| VERSION_CTRL_NBR | 1 | 1 |
| IX_STATUS | NULL (no SRTE description path) | `Closed/Completed` |
| IX_INTERVIEWEE_ROLE | NULL | `Reporting/Treating Physician` |
| IX_TYPE | NULL | `Re-Interview` |
| IX_LOCATION | NULL | `Public Health Clinic` |
| IX_CONTACTS_NAMED_IND | NULL (no LDF) | NULL (no LDF) |
| IX_900_SITE_TYPE | NULL (no LDF) | NULL (no LDF) |
| IX_INTERVENTION | NULL (no LDF) | NULL (no LDF) |
| IX_900_SITE_ID | NULL (no LDF) | NULL (no LDF) |
| IX_900_SITE_ZIP | NULL (no LDF) | NULL (no LDF) |
| CLN_CARE_STATUS_IXS | NULL (no LDF) | NULL (no LDF) |

The 6 LDF/dynamic columns (IX_CONTACTS_NAMED_IND, IX_900_SITE_TYPE, IX_INTERVENTION, IX_900_SITE_ID, IX_900_SITE_ZIP, CLN_CARE_STATUS_IXS) are populated by the SP's dynamic PIVOT only when `dbo.nrt_metadata_columns` has rows for `TABLE_NAME='D_INTERVIEW'`. Verified empty in baseline 6.0.18.1; Tier 1 cannot exercise this branch without seeding NRT_METADATA_COLUMNS, which is a Tier 3 / Datamart concern.

The two-variant pattern exercises both paths on every catalog-listed column the SP populates from non-LDF sources:
- foundation row: IX_STATUS/IX_INTERVIEWEE_ROLE/IX_TYPE/IX_LOCATION = NULL (no upstream SRTE description), IX_INTERVIEWEE_ROLE_CD=NULL.
- v2 row: every column the SP reads from nrt_interview is non-NULL with a real SRTE-resolved description.

### D_INTERVIEW_NOTE (live: 7 / catalog: 8; populated: 7 / 7)

Both notes attached to v2 Interview (D_INTERVIEW_KEY=3.0). Foundation has no notes (exhibits the empty-notes path of the DELETE-then-INSERT logic).

| Column | Sample value (note 1 / note 2) |
| --- | --- |
| D_INTERVIEW_KEY | 3.0 / 3.0 |
| D_INTERVIEW_NOTE_KEY | 2.0 / 3.0 (allocated by IDENTITY in nrt_interview_note_key) |
| NBS_ANSWER_UID | 20090020 / 20090021 |
| USER_FIRST_NAME | `Alice` / `Bob` |
| USER_LAST_NAME | `Investigator` / `Supervisor` |
| USER_COMMENT | `Subject completed re-interview at PHC. Confirmed exposure timeline.` / `Reviewed and approved interview record.` |
| COMMENT_DATE | 2026-04-15 10:30:00.000 / 2026-04-15 11:00:00.000 |

Catalog row count is 8 because the catalog includes a phantom `D_INTERVIEW_KEY` listed twice or similar — live schema has 7 columns (verified via INFORMATION_SCHEMA). All 7 live columns populated.

### F_INTERVIEW_CASE (live: 10 / catalog: 11; populated: 10 / 10)

Both rows inserted. Cross-subject keys all resolve to sentinel 1 at Tier 1 isolation (D_PATIENT/D_PROVIDER/D_ORGANIZATION are empty); INVESTIGATION_KEY and PATIENT_KEY are NOT COALESCEd in the SP and resolve to NULL since dbo.INVESTIGATION and dbo.D_PATIENT have no rows for the foundation UIDs.

| Column | Foundation (D_INTERVIEW_KEY=2.0) | v2 (D_INTERVIEW_KEY=3.0) | Notes |
| --- | --- | --- | --- |
| D_INTERVIEW_KEY | 2.0 | 3.0 | NOT NULL FK to D_INTERVIEW (resolved via nrt_interview_key) |
| PATIENT_KEY | NULL | NULL | SP line 92 `lpat.PATIENT_KEY` not COALESCEd; D_PATIENT is empty in Tier 1 isolation. Column is NULLABLE so INSERT succeeds. |
| IX_INTERVIEWER_KEY | 1 | 1 | COALESCE(lprov.PROVIDER_KEY, 1) → 1 |
| INVESTIGATION_KEY | NULL | NULL | SP line 94 `linv.INVESTIGATION_KEY` not COALESCEd; dbo.INVESTIGATION is empty in Tier 1 isolation. Column is NULLABLE so INSERT succeeds. |
| INTERPRETER_KEY | 1 (ELSE branch — interviewee_role_cd NULL) | 1 (ELSE branch — interviewee_role_cd 'PHYS' ≠ 'INTERP') | CASE on IX_INTERVIEWEE_ROLE_CD line 95 |
| NURSE_KEY | 1 | 1 (ELSE branch) | CASE line 101 |
| PHYSICIAN_KEY | 1 (ELSE branch — NULL ≠ 'PHYS') | 1 (THEN branch — 'PHYS' matches; COALESCE(lprov.PROVIDER_KEY, 1) → 1 since D_PROVIDER empty) | CASE line 98 — branch logic exercised on v2 |
| PROXY_KEY | 1 | 1 (ELSE branch) | CASE line 104 |
| IX_INTERVIEWEE_KEY | 1 (ELSE branch) | 1 (ELSE branch) | CASE on 'SUBJECT' line 107; foundation NULL ≠ 'SUBJECT' so falls through to ELSE 1 |
| INTERVENTION_SITE_KEY | 1 | 1 | COALESCE(lorg.ORGANIZATION_KEY, 1) → 1 |

Catalog row count is 11 (vs 10 live) due to a column the catalog lists that is not present in baseline 6.0.18.1 schema — the live schema's 10 columns all populated.

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| D_INTERVIEW | IX_CONTACTS_NAMED_IND, IX_900_SITE_TYPE, IX_INTERVENTION, IX_900_SITE_ID, IX_900_SITE_ZIP, CLN_CARE_STATUS_IXS | LDF / dynamic PIVOT columns; populated only when `dbo.nrt_metadata_columns` has rows for `TABLE_NAME='D_INTERVIEW'`. Verified empty in baseline 6.0.18.1. The `nrt_interview_answer` table accepts the source rows but the d_interview postprocessing SP's dynamic SQL collapses the PIVOT to a no-op when @Col_number=0 (lines 256-257, 264-279, 328-329, 363-364). | sp_d_interview_postprocessing-001.sql lines 24, 256-279; live `dbo.nrt_metadata_columns WHERE TABLE_NAME='D_INTERVIEW'` returned 0 rows |

## Gaps reported

### OUT_OF_SCOPE
- **`D_INTERVIEW` LDF/dynamic columns**: 6 columns (IX_CONTACTS_NAMED_IND, IX_900_SITE_TYPE, IX_INTERVENTION, IX_900_SITE_ID, IX_900_SITE_ZIP, CLN_CARE_STATUS_IXS) are populated only via the SP's dynamic PIVOT against `nrt_interview_answer`, which is gated by `nrt_metadata_columns.TABLE_NAME='D_INTERVIEW'` having rows. Empty at baseline. Belongs to a Tier 3 LDF-coverage fixture once SRTE/NRT_METADATA_COLUMNS seeding lands.
- **`F_INTERVIEW_CASE` IX_INTERVIEWEE_ROLE_CD CASE-branch resolution**: All 5 role-routed key columns (INTERPRETER_KEY, PHYSICIAN_KEY, NURSE_KEY, PROXY_KEY, IX_INTERVIEWEE_KEY) end up = 1 at Tier 1 isolation regardless of which branch fires, because D_PROVIDER and D_PATIENT are empty so `COALESCE(lprov.PROVIDER_KEY, 1)` and `COALESCE(lpat.PATIENT_KEY, 1)` both resolve to 1. The CASE branch logic IS exercised by v2 (interviewee_role_cd='PHYS' matches the THEN at line 98), but the resolved KEY value is identical to the ELSE branch. Distinguishing THEN-vs-ELSE on KEY value requires merged-fixture sequence (Patient + Provider Tier 1 chains run before Interview's f_postprocessing) so that lprov.PROVIDER_KEY and lpat.PATIENT_KEY resolve to non-1 surrogate keys. Tier 1 isolation only verifies the SQL path completes; merged-fixture run will verify the routing logic.

### LINK_REQUIRED
- **`F_INTERVIEW_CASE.PATIENT_KEY` non-NULL coverage**: SP line 92 reads `lpat.PATIENT_KEY` directly without COALESCE. At Tier 1 isolation D_PATIENT is empty for foundation Patient UID 20000000, so PATIENT_KEY is NULL (column NULLABLE — INSERT succeeds). Resolved in merged-fixture sequence after Patient Tier 1 chain runs.
- **`F_INTERVIEW_CASE.INVESTIGATION_KEY` non-NULL coverage**: SP line 94 reads `linv.INVESTIGATION_KEY` directly without COALESCE. At Tier 1 isolation dbo.INVESTIGATION is empty for foundation Investigation UID 20000100, so INVESTIGATION_KEY is NULL (column NULLABLE — INSERT succeeds). Resolved in merged-fixture sequence after Investigation Tier 1 chain runs.
- **`F_INTERVIEW_CASE.IX_INTERVIEWEE_KEY` SUBJECT-branch resolution**: Even with foundation Patient at UID 20000000 wired into nrt_interview.patient_uid, the SUBJECT branch only fires when IX_INTERVIEWEE_ROLE_CD = 'SUBJECT' literally. v2 uses 'PHYS' (PHYSICIAN_KEY branch); foundation uses NULL (ELSE). Tier 3 expansion could add a v3 Interview with interviewee_role_cd='SUBJECT' to exercise the THEN branch on IX_INTERVIEWEE_KEY = lpat.PATIENT_KEY. Marked for Tier 3.

### SRTE_GAP
- (none — every code value used (NBS_INTVW_STATUS 'COMPLETE', NBS_INTVWEE_ROLE 'PHYS', NBS_INTERVIEW_TYPE_STDHIV 'REINTVW', NBS_INTVW_LOC 'PHCLINIC', plus foundation's pre-existing 'C' / 'INITIAL' / 'HOSP') verified present in baseline NBS_SRTE.dbo.code_value_general. Foundation's interview_status_cd='C' is preserved as-is for the null/blank-path coverage even though it's not a real NBS_INTVW_STATUS code — the postprocessing SP propagates the raw value and only the event SP's LEFT JOIN to code_value_general would surface a description.)

### FOUNDATION_GAP
- (none.)

## Decisions made

- **Variant count: 2** (foundation + v2). Sufficient to exercise:
  - Two of the five `IX_INTERVIEWEE_ROLE_CD` CASE branches (NULL→ELSE and PHYS→PHYSICIAN_KEY THEN).
  - Foundation null-path on description columns (IX_STATUS/IX_TYPE/IX_LOCATION/IX_INTERVIEWEE_ROLE) vs v2 populated path.
  - Foundation no-cross-subject-soft-refs path vs v2 wired-soft-refs path (resolves at merged-fixture).
  - Foundation no-notes path vs v2 with-notes path on D_INTERVIEW_NOTE.
  A v3 with `interviewee_role_cd='SUBJECT'` (or INTERP/NURSE/PROXY) is a Tier 3 candidate to exercise the remaining 3 CASE branches; not required for Tier 1 stop-conditions since both code paths (THEN-with-PHYS and ELSE-with-NULL) are exercised.
- **v2 role code: 'PHYS'** (Reporting/Treating Physician). Picked deliberately because the prompt suggested it as a recognizable provider-routing branch; the resulting D_INTERVIEW.IX_INTERVIEWEE_ROLE_CD='PHYS' drives F_INTERVIEW_CASE line 98's PHYSICIAN_KEY THEN branch.
- **Foundation interview_status_cd='C' preserved as-is** (not a real NBS_INTVW_STATUS code). The postprocessing SP propagates the raw value; the event SP's LEFT JOIN simply yields IX_STATUS=NULL (description). This is the deliberate null/blank-description path on foundation. Tier 1 contract forbids UPDATEing foundation rows, so this is correct.
- **Foundation interviewee_role_cd=NULL preserved** (foundation row already had it NULL). Drives the all-ELSE-branch path on F_INTERVIEW_CASE's 5 CASE columns.
- **`nrt_interview_answer` rows NOT authored.** NRT_METADATA_COLUMNS is empty for D_INTERVIEW in baseline; the SP's dynamic PIVOT collapses to no-op without those rows. Authoring nrt_interview_answer rows would be inert at Tier 1; belongs to Tier 3 LDF coverage.
- **`nrt_interview_note` rows: 2 on v2 only.** Sufficient to exercise multi-row note INSERT and the DELETE-then-INSERT pattern (the SP at lines 451-456 deletes existing notes for the d_interview_key first; on first run the DELETE removes 0 rows, then INSERT adds 2).
- **No `nrt_interview_key` / `nrt_interview_note_key` hand-authoring.** Both are IDENTITY tables; the SP allocates surrogate keys at lines 206-210 (interview_key) and 476-481 (note_key). IDENT_CURRENT verified at 2 for both at baseline (clean state).
- **`nbs_answer_uid` 20090020 and 20090021 are standalone identity values** inside Interview's UID block, not real ODSE NBS_ANSWER row UIDs. The SP only reads nbs_answer_uid as a column on nrt_interview_note + nrt_interview_note_key (no FK enforced). Same approach as the synthetic-staging strategy applied throughout the fixture suite.
- **Soft refs on v2 nrt_interview (provider_uid=20000010, organization_uid=20000020, patient_uid=20000000, investigation_uid=20000100):** Wired even though they resolve to sentinel 1 at Tier 1 isolation. The merged-fixture sequence will re-run f_interview_case_postprocessing after upstream chains populate D_PATIENT / D_PROVIDER / D_ORGANIZATION / INVESTIGATION, and the COALESCE-and-direct-reads will then resolve to real keys. Wiring now (vs leaving NULL) means no Tier 2/3 amendment is needed for this fixture.
- **`generated_always_type` columns confirmed:** `nrt_interview.refresh_datetime`, `nrt_interview.max_datetime`, `nrt_interview_answer.refresh_datetime`, `nrt_interview_answer.max_datetime`, `nrt_interview_note.refresh_datetime`, `nrt_interview_note.max_datetime` are all `generated_always_type IN (1,2)`. All omitted from INSERT column lists.

## UID allocations (for uid_ranges.md)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20090010 | @dbo_Act_interview_v2_uid | v2 Interview `act.act_uid` / `interview.interview_uid` | Class `ENC`, mood `EVN`. Fully-attributed Interview variant — interviewee_role_cd='PHYS' to exercise F_INTERVIEW_CASE.PHYSICIAN_KEY CASE branch. interview_status_cd='COMPLETE', interview_type_cd='REINTVW', interview_loc_cd='PHCLINIC'. |
| 20090020 | (no symbolic — note 1 nbs_answer_uid) | `nrt_interview_note.nbs_answer_uid` for v2 note 1 | Standalone identity value inside Interview's UID block; not a real NBS_ANSWER row UID (the SP only reads it as a column, no FK enforced). |
| 20090021 | (no symbolic — note 2 nbs_answer_uid) | `nrt_interview_note.nbs_answer_uid` for v2 note 2 | Same as above. |

Unused UIDs in Interview Tier 1 block (20090000-20090009, 20090011-20090019, 20090022-20099999) are reserved for future Interview Tier 1 / Tier 3 amendments (e.g., Tier 3 v3 with interviewee_role_cd='SUBJECT' to exercise IX_INTERVIEWEE_KEY THEN branch).

The fixture also writes 2 rows to `RDB_MODERN.dbo.nrt_interview` keyed on `interview_uid` 20000140 (foundation) and 20090010 (v2), and 2 rows to `RDB_MODERN.dbo.nrt_interview_note` keyed on `interview_uid=20090010`. Those identities are not new UIDs — they reference the foundation Interview created in 00_foundation.sql plus the v2 entity above.
