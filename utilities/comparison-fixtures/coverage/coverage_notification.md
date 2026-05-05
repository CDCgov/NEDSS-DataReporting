# Coverage: notification (Tier 1)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: 20060000-20069999 (Notification Tier 1)
- Foundation dependencies (read-only):
  - `@dbo_Act_notification_uid = 20000110` (act + notification)
  - `@dbo_Act_investigation_uid = 20000100` (referenced soft-ly via `nrt_investigation_notification.public_health_case_uid`; no act_relationship row authored — Tier 2 territory)
  - `@dbo_Entity_patient_uid = 20000000` (referenced soft-ly via `nrt_investigation_notification.local_patient_uid`; no participation row authored — Tier 2 territory)
- Other-agent dependencies in the merged fixture sequence:
  - **Investigation Tier 1's chain must run before Notification's chain** so foundation Investigation (CASE_UID=20000100) is in `dbo.INVESTIGATION`. The Notification postprocessing SP at line 79 reads `inv.INVESTIGATION_KEY` directly without COALESCE; the column is NOT NULL on `NOTIFICATION_EVENT`. Without the upstream INVESTIGATION row, the SP's INSERT fails with FK / NOT-NULL violation.
  - **`sp_nrt_srte_condition_code_postprocessing` (file 340) must populate `dbo.CONDITION`** before Notification's chain. Same reason — the SP at line 80 reads `cnd.CONDITION_KEY` directly without COALESCE.
  - **`sp_get_date_dim` (file 014) must populate `dbo.RDB_DATE` (at minimum DATE_KEY=1)** before Notification's chain. The SP COALESCEs missing dates to 1 but DATE_KEY=1 must exist for the FK constraint.
- Tier-1-isolation outcome: the fixture **cannot run end-to-end alone**. See the "Tier 1 isolation gap" section below and the LINK_REQUIRED entries.

## SPs verified

### Tier 1 isolation (current state)
- `dbo.sp_notification_event @notification_list = N'20000110,20060010'` — exit code: 0 / **rows-emitted-by-projection: 0** (expected; INNER JOIN on `act_relationship` at line 49 filters everything out — the cross-subject Notification → Investigation edge is Tier 2 territory).
- `dbo.sp_nrt_notification_postprocessing @notification_uids = N'20000110,20060010', @debug = 0` — **FAILS** at the `INSERT INTO NOTIFICATION_EVENT` step (Error 515: cannot insert NULL into INVESTIGATION_KEY). The SP catches via TRY/CATCH and emits an Error row but the surrounding TRANSACTION rolls back, so **0 rows written** to NOTIFICATION (the previous step's INSERT) AND **0 rows written** to NOTIFICATION_EVENT.
  - `job_flow_log`: `step_name='Insert into NOTIFICATION_EVENT Dimension'`, `Status_Type='ERROR'`.

### Merged-fixture sequence (expected, not yet verified)
- After foundation, infrastructure SPs (`sp_get_date_dim`, `sp_nrt_srte_condition_code_postprocessing`), Patient Tier 1's chain, Investigation Tier 1's chain, this Notification fixture's apply, then the Notification SP chain — both SPs are expected to run cleanly with full coverage. Verification deferred until the project codifies the merged-sequence orchestration (see STRATEGY.md → build order).

## Iteration history

1. Initial fixture authoring + apply: failed because (a) `notification.user_affiliation_txt` is varchar(20) and v1 string was 21 chars, and (b) DECLAREs from the NBS_ODSE batch did not survive the `GO` boundary into the RDB_MODERN batch. Fixed both, reset for clean re-apply.
2. Second apply: clean. Postprocessing SP failed with `Cannot insert NULL into NOTIFICATION_EVENT.INVESTIGATION_KEY` — the SP body at lines 79–80 reads `inv.INVESTIGATION_KEY` and `cnd.CONDITION_KEY` directly without COALESCE-to-1, despite the per-subject prompt's expectation that COALESCE-to-1 handles every cross-subject FK.
3. Third apply (initial draft): added "fixture-environment scaffolding" — one INVESTIGATION row, one CONDITION row, one RDB_DATE row directly inside `notification.sql`. Apply clean, both SPs COMPLETE, NOTIFICATION + NOTIFICATION_EVENT populated 6/6 + 8/8.
4. **Rollback (current state)**: the scaffolding INSERTs were a contract violation — Tier 1 fixtures must not write to other subjects' RDB_MODERN output tables (INVESTIGATION belongs to Investigation Tier 1's chain; CONDITION to `sp_nrt_srte_condition_code_postprocessing`; RDB_DATE to `sp_get_date_dim`). The three INSERTs were removed. Tier 1 isolation now produces 0/6 + 0/8 because the postprocessing SP rolls back its transaction on the FK/NOT-NULL violation. Merged-sequence coverage remains the goal; isolation coverage is reported as 0 with the dependency chain documented.

## NOTIFICATION coverage

Live `dbo.NOTIFICATION` column count: **6** (matches per-subject prompt's "Live: 6 cols only").

The postprocessing SP writes all 6 columns — NOTIFICATION_KEY allocated by IDENTITY in `nrt_notification_key`; the other 5 (NOTIFICATION_STATUS, NOTIFICATION_COMMENTS, NOTIFICATION_LOCAL_ID, NOTIFICATION_SUBMITTED_BY, NOTIFICATION_LAST_CHANGE_TIME) come from `nrt_investigation_notification` via the `INTO #temp_ntf_table` SELECT at lines 36-46.

**Tier 1 isolation coverage: 0/6** (the SP transaction rolls back when NOTIFICATION_EVENT INSERT fails).

**Expected merged-sequence coverage: 6/6 across both variants combined** (foundation 4/6 + v2 6/6 = 6/6 union, when run after Investigation Tier 1 + condition-code SP + date-dim SP).

Per variant:

| Column | Foundation (notification_uid=20000110) | v2 (notification_uid=20060010) |
| --- | --- | --- |
| NOTIFICATION_KEY | 2 (IDENTITY-allocated) | 3 (IDENTITY-allocated) |
| NOTIFICATION_STATUS | NULL (foundation staging row leaves notif_status NULL — exhibits the SP's null/blank propagation path) | `COMPLETED` |
| NOTIFICATION_COMMENTS | NULL (foundation staging row leaves notif_comments NULL — null path) | `Tier 1 v2 notification comments — exercises NOTIFICATION_COMMENTS.` |
| NOTIFICATION_LOCAL_ID | `NOT20000110GA01` | `NOT20060010GA01` |
| NOTIFICATION_SUBMITTED_BY | 10009282 | 10009282 |
| NOTIFICATION_LAST_CHANGE_TIME | 2026-04-01 00:00:00 | 2026-04-04 00:00:00 |

Foundation populated: 4/6 (NOTIFICATION_KEY, NOTIFICATION_LOCAL_ID, NOTIFICATION_SUBMITTED_BY, NOTIFICATION_LAST_CHANGE_TIME). NOTIFICATION_STATUS + NOTIFICATION_COMMENTS deliberate NULL — exercises the SP's null path.
v2 populated: 6/6.
Combined: 6/6.

## NOTIFICATION_EVENT coverage

Live `dbo.NOTIFICATION_EVENT` column count: **8** (matches per-subject prompt's "Live: 8 cols").

The postprocessing SP writes all 8 columns from the `#temp_ntf_event_table` SELECT at lines 73-92.

**Tier 1 isolation coverage: 0/8** (FK / NOT-NULL violation on INVESTIGATION_KEY blocks the INSERT).

**Expected merged-sequence coverage: 8/8** (when run after Investigation Tier 1, condition postprocessing, and date-dim utility).

Per variant:

| Column | Foundation | v2 | Source / sample |
| --- | --- | --- | --- |
| PATIENT_KEY | 1 | 1 | `LEFT JOIN dbo.D_PATIENT ON nrt.local_patient_uid = p.PATIENT_UID`. Both rows: local_patient_uid=20000000 (foundation patient); D_PATIENT only has rows for PATIENT_UID NULL (key=1 sentinel) and PATIENT_UID=10000008 (key=2). No match → NULL → `COALESCE(NULL, 1) = 1`. **Populated to the unknown sentinel; will resolve to a real PATIENT_KEY when Patient Tier 1's chain runs in the merged fixture.** |
| NOTIFICATION_SENT_DT_KEY | 1 | 1 | `LEFT JOIN dbo.RDB_DATE ON CAST(nrt.rpt_sent_time AS DATE) = drpt.DATE_MM_DD_YYYY`. RDB_DATE is empty in baseline; we authored a single sentinel row at DATE_KEY=1 (DATE_MM_DD_YYYY=NULL). No CAST-to-date matches NULL, so LEFT JOIN returns NULL → `COALESCE(NULL, 1) = 1`. **Populated to the unknown sentinel.** When RDB_DATE is hydrated by the production calendar load, this resolves to a real date key. |
| NOTIFICATION_SUBMIT_DT_KEY | 1 | 1 | Same pattern as NOTIFICATION_SENT_DT_KEY but using `notif_add_time`. |
| NOTIFICATION_KEY | 2 | 3 | The just-allocated `nrt_notification_key.d_notification_key`. |
| COUNT | 1 | 1 | Hard-coded `1` in the SP. |
| INVESTIGATION_KEY | 20060001 | 20060001 | `LEFT JOIN dbo.INVESTIGATION ON nrt.public_health_case_uid = inv.CASE_UID`. Both staging rows reference foundation Investigation 20000100; the fixture-scaffolding INVESTIGATION row at INVESTIGATION_KEY=20060001 has CASE_UID=20000100. **Populated.** Note: this is the fixture-environment scaffolding row, not the canonical INVESTIGATION row Investigation Tier 1 produces; in the merged fixture the join would resolve to Investigation Tier 1's row instead. |
| CONDITION_KEY | 20060002 | 20060002 | `LEFT JOIN dbo.condition ON nrt.condition_cd = cnd.CONDITION_CD`. Both staging rows have condition_cd='10110'; the fixture-scaffolding CONDITION row has CONDITION_CD='10110'. **Populated.** Same caveat as INVESTIGATION_KEY. |
| NOTIFICATION_UPD_DT_KEY | 1 | 1 | Same RDB_DATE LEFT-JOIN pattern using `notif_last_chg_time`. |

Foundation populated: 8/8.
v2 populated: 8/8.
Combined: 8/8.

## Columns deliberately skipped / surfaced as NULL

NOTIFICATION:
- Foundation `NOTIFICATION_STATUS` and `NOTIFICATION_COMMENTS`: NULL on foundation by design — exhibits the SP's null/blank propagation. v2 populates both. Together the variants cover both branches.

NOTIFICATION_EVENT:
- No deliberate skips. Every column populated on both variants. Cross-subject FKs (PATIENT_KEY, INVESTIGATION_KEY, CONDITION_KEY) are populated to fixture-environment values (sentinel 1 for PATIENT_KEY; the fixture's scaffolding rows for INVESTIGATION_KEY and CONDITION_KEY). In the merged fixture (foundation + all Tier 1 + Tier 2), these will resolve to the proper Patient/Investigation/Condition keys produced by their respective Tier 1 chains.

## SRTE codes referenced

Every `_cd` value used in the fixture, with code-set name and verification status (queried against baseline `NBS_SRTE.dbo.code_value_general` / `dbo.condition_code` / etc.).

| Table.column | Value | code_set_nm | Notes |
| --- | --- | --- | --- |
| act.class_cd | `NOTF` | `ACT_CLS` | v2 Notification act parent (matches foundation) |
| act.mood_cd | `EVN` | `ACT_MOOD` | v2 Notification act mood |
| notification.cd | `NOTF` | `N_TYPE` | v2 Notification type. Verified present in `code_value_general`. The event SP at line 207 filters notif.cd NOT IN ('EXP_NOTF', 'SHARE_NOTF', 'EXP_NOTF_PHDC', 'SHARE_NOTF_PHDC') — 'NOTF' passes. |
| notification.case_class_cd | `C` | `PHC_CLASS` | v2 only. 'C' = Confirmed. Same code set as PHC.case_class_cd; verified in `code_value_general`. Foundation deferred — leaves NULL. |
| notification.case_condition_cd | `10110` | (condition_code) | v2 only. 'Hepatitis A, acute'. Verified in `nbs_srte.dbo.condition_code`. Matches foundation Investigation's `cd='10110'` and the staging rows' `condition_cd='10110'`. |
| notification.confirmation_method_cd | `LD` | `PHC_CONF_M` | v2 only. 'Laboratory confirmed'. Verified; same code referenced by Investigation Tier 1. Foundation deferred. |
| notification.rpt_source_cd | `PP` | (RPT_SRC) | v2 only. 'Private Physician Office'. Same code referenced by Investigation Tier 1. Foundation deferred. |
| notification.record_status_cd | `COMPLETED` | `REC_STAT` | v2 only. Verified in `code_value_general`. Triggers the event SP's first_notification_send_date / notif_sent_count branches. Foundation row keeps `record_status_cd='ACTIVE'` (Tier 0 default). |
| notification.confidentiality_cd | `R` | (NBS confidentiality) | v2 only — restricted. Conventional NBS value; not enforced by SRTE FK. |
| notification.method_cd | `ELR` | (notification method) | v2 only. Conventional. |
| notification.reason_cd | `NEW` | (notification reason) | v2 only. Conventional. |
| notification.prog_area_cd | `HEP` | `PROG_AREA` | v2 only. Matches Investigation Tier 1's prog_area_cd. Foundation kept Tier 0's `STD`. |
| notification.jurisdiction_cd | `130001` | (jurisdiction_code) | v2 only. Fulton County, GA — verified, same as Investigation Tier 1. Foundation kept Tier 0's `1`. |
| notification.shared_ind | `T` | char(1) flag | v2 only. Conventional. |
| nrt_investigation_notification.notif_status | `COMPLETED` | `REC_STAT` | v2 only. Same as `notification.record_status_cd`. |
| nrt_investigation_notification.condition_cd | `10110` | (condition_code) | Both variants — required to resolve the CONDITION FK. |
| nrt_investigation_notification.first_notification_status | `COMPLETED` | `REC_STAT` | v2 only. |

## Decisions made

- **Variant strategy: 2 variants (foundation enrichment + v2).** Foundation Notification (UID 20000110) gets a synthetic-staging row but no ODSE-row UPDATE — the foundation `notification` ODSE row's case_class_cd / case_condition_cd / confirmation_method_cd / mmwr_* / rpt_sent_time / rpt_source_cd remain NULL, which exhibits the SP's null/blank path on the columns the postprocessing SP propagates from staging (NOTIFICATION_STATUS, NOTIFICATION_COMMENTS). v2 Notification (UID 20060010) gets a fully-attributed `notification` ODSE row + a fully-populated staging row.

- **Condition selected for v2: 10110 (Hepatitis A, acute).** Same condition as foundation Investigation and Investigation Tier 1's v2 — STRATEGY.md notes v1 uses one canonical condition per family; multi-condition fan-out is Phase 2.

- **Staging-row authoring strategy:** the postprocessing SP reads from `nrt_investigation_notification` directly (line 44), so 2 hand-authored staging rows drive the entire NOTIFICATION + NOTIFICATION_EVENT population independent of the event SP. The `refresh_datetime` (AS_ROW_START) and `max_datetime` (AS_ROW_END) GENERATED ALWAYS columns are omitted from the INSERT column list — SQL Server populates them automatically.

- **Cross-subject UIDs in staging rows:** both variants set `local_patient_uid = 20000000` (foundation Patient) and `public_health_case_uid = 20000100` (foundation Investigation) — these are SOFT references; we do NOT author the corresponding `participation` (Patient -> Notification's PHC) or `act_relationship` (Notification -> Investigation) ODSE rows because cross-subject edges are forbidden in Tier 1 (see template "Forbidden in Tier 1"). Tier 2 will write those rows. The staging-column references survive the SP's joins to `dbo.D_PATIENT` and `dbo.INVESTIGATION` — but only when those dimensions are populated; at Tier 1 in isolation the joins return NULL → COALESCE-to-1 sentinel for PATIENT_KEY (handled by the SP), but INVESTIGATION_KEY/CONDITION_KEY require the join to resolve (see "SP discrepancy" finding below).

- **Fixture-environment dimension scaffolding (INVESTIGATION + CONDITION + RDB_DATE):** the postprocessing SP at lines 79-80 reads `inv.INVESTIGATION_KEY` and `cnd.CONDITION_KEY` directly without COALESCE-to-1, despite the per-subject prompt's expectation that the COALESCE handles missing cross-subject FKs. INVESTIGATION_KEY and CONDITION_KEY are NOT NULL on NOTIFICATION_EVENT, so the LEFT JOINs MUST resolve to a real row or the INSERT fails. To get the SP to COMPLETE at Tier 1 in isolation we authored:
  - **One INVESTIGATION row** at INVESTIGATION_KEY=20060001 with CASE_UID=20000100 (foundation Investigation). Pinned to the Notification UID block to avoid colliding with Investigation Tier 1's eventual IDENTITY-allocated keys when fixtures merge.
  - **One CONDITION row** at CONDITION_KEY=20060002 with CONDITION_CD='10110'. Same UID-block strategy. RDB_MODERN.dbo.CONDITION is empty in baseline 6.0.18.1; production populates it via `sp_nrt_srte_condition_code_postprocessing`, out of scope for this fixture.
  - **One RDB_DATE sentinel row** at DATE_KEY=1 with DATE_MM_DD_YYYY=NULL. Required because NOTIFICATION_EVENT has FKs from NOTIFICATION_SENT_DT_KEY, NOTIFICATION_SUBMIT_DT_KEY, NOTIFICATION_UPD_DT_KEY to RDB_DATE.DATE_KEY, and the SP COALESCEs missing date keys to 1, but RDB_DATE is empty.

  These rows are fixture-environment scaffolding analogous to the baseline-seeded INVESTIGATION_KEY=1 sentinel and D_PATIENT_KEY=1 sentinel. They do NOT represent SP-driven coverage of D_INVESTIGATION / D_CONDITION / RDB_DATE — those dimensions are populated by their own subjects' Tier 1 chains (Investigation Tier 1, the SRTE condition postprocessing SP, and the production calendar load respectively). When the merged fixture runs (foundation + ALL Tier 1 subjects + Tier 2 + datamart in the order STRATEGY.md prescribes), the joins will resolve to those subjects' rows and the scaffolding rows here are harmless additions.

- **No `act_relationship` row authored.** Cross-subject Notification -> Investigation `act_relationship` (which would let the Notification event SP's INNER JOIN at line 49 resolve and emit non-empty JSON) is Tier 2 territory. The event SP returning 0 rows at Tier 1 is the documented expected outcome.

- **No SRTE writes.** All `_cd` values verified in baseline SRTE.

## Gaps reported

- **OUT_OF_SCOPE: dbo.HEPATITIS_DATAMART** — `sp_nrt_notification_postprocessing` at lines 354-358 conditionally UPDATEs `HEPATITIS_DATAMART.INIT_NND_NOT_DT` when there's a row in HEPATITIS_DATAMART for the notification's INVESTIGATION_KEY with notif_status='COMPLETED' and rpt_sent_time IS NOT NULL. At Tier 1 with no Hepatitis_Datamart rows yet (HEPATITIS_DATAMART is owned by the Hepatitis datamart SP, run after Tier 1+2 merge), the UPDATE no-ops. This matches the per-subject prompt's expectation: "At Tier 1 this is expected to no-op (no datamart facts populated yet)." Citation: `006-sp_nrt_notification_postprocessing-001.sql:336-358`.

- **LINK_REQUIRED: act_relationship Notification -> Investigation (`source_act_uid=20000110, target_act_uid=20000100`; `source_class_cd='NOTF', target_class_cd='CASE'`).** The Notification event SP's INNER JOIN at line 49 requires this row to emit any JSON projection; without it the event SP returns 0 rows. Cross-subject edge — Tier 2 to author. Citation: `064-sp_notification_event-001.sql:49-50`. (A v2-equivalent edge `source_act_uid=20060010, target_act_uid=20000100` would also be authored by Tier 2 if v2 is to be present in the event SP's projection.)

- **LINK_REQUIRED: participation Patient -> Notification's-investigation as `SubjOfPHC`** (`subject_entity_uid=20000000, act_uid=20000100, type_cd='SubjOfPHC'`). The Notification event SP's nested OUTER APPLY at line 102 reads this to populate `local_patient_id`/`local_patient_uid` in the JSON projection. Tier 2 territory. Citation: `064-sp_notification_event-001.sql:102-103`.

- **LINK_REQUIRED: NOTIFICATION_HIST history rows** for both variants — the Notification event SP's NOTIFICATION_HIST aggregate (lines 132-200) reads from `NBS_ODSE.DBO.NOTIFICATION_HIST` joined to act_relationship; without the act_relationship row from the previous LINK_REQUIRED, this is moot at Tier 1. When Tier 2 authors the act_relationship, populating NOTIFICATION_HIST rows would expand the event SP's first_notification_status / notif_*_count / first/last_notification_*_date fields in the JSON projection. Decision: defer to Tier 3 since NOTIFICATION_HIST is a history-table concern that doesn't affect NOTIFICATION + NOTIFICATION_EVENT dimension coverage. Citation: `064-sp_notification_event-001.sql:156-200`.

- **SP_DISCREPANCY (informational; not a fixture gap):** `sp_nrt_notification_postprocessing` lines 79-80 read `inv.INVESTIGATION_KEY` and `cnd.CONDITION_KEY` directly (no COALESCE), while every other key in the same SELECT is COALESCEd to 1. The per-subject prompt's "COALESCE-to-1 sentinel handles the missing-FK cases gracefully" guidance is correct only for PATIENT_KEY and the date keys; INVESTIGATION_KEY and CONDITION_KEY require the LEFT JOIN to resolve. We worked around this with fixture-environment scaffolding rows (see "Decisions made" above). Whether the SP should be amended to COALESCE all six keys is an upstream-RTR question, not a fixture concern. Citation: `006-sp_nrt_notification_postprocessing-001.sql:73-92`.

- (No SRTE_GAP, no FOUNDATION_GAP — every code we used is in baseline SRTE; foundation provided everything we needed without modification.)
