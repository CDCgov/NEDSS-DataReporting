# Coverage: inv_notification (Tier 2 — `Notification` edge)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: `21000000 - 21000999` (Tier 2, first agent)
- Foundation dependencies (read-only):
  - `@dbo_Act_notification_uid = 20000110` (foundation Notification)
  - `@dbo_Act_investigation_uid = 20000100` (foundation Investigation)
  - `@dbo_Entity_patient_uid = 20000000` (foundation Patient — referenced soft-ly via Notification Tier 1's `nrt_investigation_notification.local_patient_uid`)
- Tier 1 dependencies (read-only):
  - `@dbo_Act_notification_v2_uid = 20060010` (Notification Tier 1)
  - `@dbo_Act_investigation_v2_uid = 20050010` (Investigation Tier 1)
- Pre-fixture infrastructure SPs (run by orchestrator per Merge contract step 2):
  - `EXEC dbo.sp_get_date_dim 2020, 2030` — populates `RDB_DATE`. **NOTE — INFRA_GAP:** the SP body in baseline 6.0.18.1 references a non-existent `dbo.rdb_date_temp` table (line 26 of `014-sp_get_date_dim-001.sql`); see the Gaps section below. For this agent's verification we hand-populated `RDB_DATE` via a recursive CTE.
  - `EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'` — populates `CONDITION` from SRTE for the Hepatitis A condition our staging rows reference.

## Apply result

Clean apply on first attempt.

- Foundation: applied clean.
- Patient Tier 1: applied clean.
- Investigation Tier 1: applied clean.
- Notification Tier 1: applied clean.
- Patient chain (`sp_patient_event` + `sp_nrt_patient_postprocessing`): COMPLETE; 4 D_PATIENT rows.
- Investigation chain (`sp_investigation_event` + `sp_nrt_investigation_postprocessing`): COMPLETE; INVESTIGATION_KEYs 3 (foundation, CASE_UID=20000100) and 4 (v2, CASE_UID=20050010).
- Edge fixture (`fixtures/20_links/inv_notification.sql`): applied clean.
- Notification chain (re-run via fixture tail-EXEC): COMPLETE — both NOTIFICATION + NOTIFICATION_EVENT rows inserted, no FK / NOT-NULL violations.

## Edges authored

| # | source_act_uid | target_act_uid | type_cd | source_class_cd | target_class_cd | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 20000110 (foundation Notif) | 20000100 (foundation Inv) | `Notification` | `NOTF` | `CASE` | foundation→foundation pair |
| 2 | 20060010 (v2 Notif) | 20050010 (v2 Inv) | `Notification` | `NOTF` | `CASE` | v2→v2 pair |

Total: 2 rows in `nbs_odse.dbo.act_relationship`.

`type_cd='Notification'` is verified present in baseline `NBS_SRTE.dbo.code_value_general` for `code_set_nm='AR_TYPE'` (Phase B catalog row in `catalog/edge_types.md`). RTR's hard SP filter at `064-sp_notification_event-001.sql:208-209` is on `source_class_cd='NOTF'` AND `target_class_cd='CASE'`, not on `type_cd` — the literal `Notification` is NBS upstream convention, used for shape consistency.

No new entity / Person / Act / Public_health_case / Notification rows authored (forbidden in Tier 2). No SRTE writes, no foundation/Tier 1 modifications, no INSERTs into RDB_MODERN dim/fact tables. The fixture's tail-EXEC re-runs `sp_nrt_notification_postprocessing` against the wired graph; that SP writes the dim rows.

## SPs verified

- `dbo.sp_nrt_notification_postprocessing @notification_uids = N'20000110,20060010'` — exit code: 0; 2 NOTIFICATION rows + 2 NOTIFICATION_EVENT rows inserted; HEPATITIS_DATAMART INIT_NND_NOT_DT update no-ops at this tier (no datamart facts yet).
- `dbo.sp_notification_event @notification_list = N'20000110,20060010'` — exit code: 0; 2 JSON-projection rows emitted (was 0 pre-edge — the INNER JOIN on act_relationship at line 49 now resolves).
- `dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'` — exit code: 0; both `investigation_act_relationships` and `investigation_notifications` JSON branches now contain the wired notifications (was empty pre-edge).

## Coverage unlocked

### NOTIFICATION dimension (`dbo.NOTIFICATION`) — 6 columns total

Tier 1 isolation baseline (per `coverage_notification.md`): **0/6** (the postprocessing SP rolled back its TRANSACTION on the FK / NOT-NULL violation against NOTIFICATION_EVENT.INVESTIGATION_KEY).

Post-edge merged-sequence: **6/6 across both variants combined** (foundation 4/6 NULL-path + v2 6/6 populated-path).

| Column | Foundation (notif_uid=20000110) | v2 (notif_uid=20060010) | Before edge | After edge |
| --- | --- | --- | --- | --- |
| NOTIFICATION_KEY | 2 (IDENTITY) | 3 (IDENTITY) | NULL (rollback) | populated |
| NOTIFICATION_STATUS | NULL (Tier 1 NULL-path by design) | `COMPLETED` | NULL (rollback) | populated |
| NOTIFICATION_COMMENTS | NULL (Tier 1 NULL-path by design) | `Tier 1 v2 notification comments — exercises NOTIFICATION_COMMENTS.` | NULL (rollback) | populated |
| NOTIFICATION_LOCAL_ID | `NOT20000110GA01` | `NOT20060010GA01` | NULL (rollback) | populated |
| NOTIFICATION_SUBMITTED_BY | 10009282 | 10009282 | NULL (rollback) | populated |
| NOTIFICATION_LAST_CHANGE_TIME | 2026-04-01 00:00:00 | 2026-04-04 00:00:00 | NULL (rollback) | populated |

### NOTIFICATION_EVENT dimension (`dbo.NOTIFICATION_EVENT`) — 8 columns total

Tier 1 isolation baseline: **0/8** (same TRANSACTION rollback).

Post-edge merged-sequence: **8/8**.

| Column | Foundation | v2 | Before | After (real key vs sentinel?) |
| --- | --- | --- | --- | --- |
| NOTIFICATION_KEY | 2 | 3 | NULL | **real (IDENTITY-allocated)** |
| PATIENT_KEY | 3 | 3 | NULL | **REAL key 3** (D_PATIENT.PATIENT_UID=20000000 = foundation Patient). Resolved via `LEFT JOIN dbo.D_PATIENT ON nrt.local_patient_uid = p.PATIENT_UID`. **Not sentinel 1.** |
| NOTIFICATION_SENT_DT_KEY | 1 (sentinel — foundation rpt_sent_time NULL by Tier 1 design; SP COALESCEs to 1) | 2287 | NULL | foundation: sentinel 1 (correct — Tier 1's null-path); **v2: REAL key 2287** (RDB_DATE.DATE_MM_DD_YYYY=2026-04-04). |
| NOTIFICATION_SUBMIT_DT_KEY | 2284 | 2284 | NULL | **REAL key 2284** (RDB_DATE.DATE_MM_DD_YYYY=2026-04-01) for both. |
| COUNT | 1 | 1 | NULL | populated (hard-coded by SP). |
| INVESTIGATION_KEY | 3 | 3 | NULL (FK violation rollback) | **REAL key 3** (INVESTIGATION.CASE_UID=20000100 = foundation Investigation). Both rows resolve to foundation Inv because Notification Tier 1's staging rows both set `public_health_case_uid=20000100`. **Not sentinel 1.** This is by design — Notification Tier 1 chose to point both staging rows at foundation Inv; if Tier 1's v2 staging row pointed at 20050010, v2's INVESTIGATION_KEY would resolve to 4 instead. The wiring of v2 Notif → v2 Inv at the act_relationship level is still correct and is required for sp_notification_event / sp_investigation_event JSON projections. |
| CONDITION_KEY | 3 | 3 | NULL (FK violation rollback) | **REAL key 3** (CONDITION.CONDITION_CD=10110 = Hepatitis A, acute). Resolved via `LEFT JOIN dbo.condition cnd ON nrt.condition_cd = cnd.CONDITION_CD`. **Not sentinel 1.** Required `sp_nrt_srte_condition_code_postprocessing` to have run. |
| NOTIFICATION_UPD_DT_KEY | 2284 | 2287 | NULL | **REAL keys 2284 / 2287** (RDB_DATE rows for 2026-04-01 / 2026-04-04). |

### Cross-FK summary

All four cross-subject FKs that this edge touches resolve to **real** keys (not sentinel 1) for the populated path:

- `INVESTIGATION_KEY` → real (matched on CASE_UID).
- `CONDITION_KEY` → real (matched on CONDITION_CD).
- `PATIENT_KEY` → real (matched on PATIENT_UID).
- `NOTIFICATION_SENT_DT_KEY`, `NOTIFICATION_SUBMIT_DT_KEY`, `NOTIFICATION_UPD_DT_KEY` → real (matched on date).

The only sentinel-1 value remaining is `NOTIFICATION_SENT_DT_KEY` on the foundation row, which is by Tier 1's deliberate NULL-path design (foundation `nrt_investigation_notification.rpt_sent_time` is NULL to exercise the SP's null/blank propagation).

## Coverage still LINK_REQUIRED

Notification's Tier 1 LINK_REQUIRED entries (from `coverage_notification.md` "Gaps reported"):

| LINK_REQUIRED | Resolved by this edge? |
| --- | --- |
| act_relationship Notif → Investigation, type_cd='Notification', NOTF→CASE | **YES — this edge.** |
| participation Patient → Investigation, type_cd='SubjOfPHC' (drives sp_notification_event line 102 nested OUTER APPLY for `local_patient_id`/`local_patient_uid` JSON column) | **NO — waiting on `participation_patient_phc` Tier 2 agent.** Without that edge, the event SP's JSON projection contains `local_patient_id=null, local_patient_uid=null`. **Note:** the postprocessing SP reads `local_patient_uid` from `nrt_investigation_notification` directly (Tier 1's hand-authored staging row sets it to 20000000), so PATIENT_KEY in NOTIFICATION_EVENT is already populated correctly. The participation edge only affects the event SP's downstream-JSON projection, not the dimension columns. |
| NOTIFICATION_HIST history rows + matching act_relationship to populate first/last_notification_*_count, first/last_notification_*_date in event SP's NOTIFICATION_HIST aggregate (lines 132–200 of `064-sp_notification_event`) | **NO — Tier 3 territory.** Per `coverage_notification.md`'s decision to defer NOTIFICATION_HIST to Tier 3. NOTIFICATION_HIST is a history table, not a dim, and doesn't affect NOTIFICATION + NOTIFICATION_EVENT coverage measured here. |

Investigation's Tier 1 LINK_REQUIRED #13 (per `coverage_investigation.md` line 196): **`act_relationship type_cd='Notification' linking foundation Notification → foundation/v2 Investigation — populates the notification_history aggregation (event SP lines 692–845) and downstream notification-driven datamart columns.`** — **YES, RESOLVED.** Investigation event SP's `investigation_notifications` and `investigation_act_relationships` JSON branches both contain the wired notifications post-edge. Hepatitis_Datamart's notification-driven columns (e.g., `INIT_NND_NOT_DT` UPDATE in `sp_nrt_notification_postprocessing` lines 354–358) are exercised: the SP reaches the IF-EXISTS check and would UPDATE if HEPATITIS_DATAMART had matching rows; it currently no-ops because the datamart SP hasn't run yet (deferred to Merge contract step 9 — datamart chain).

## Columns deliberately not exercised by this edge

These belong to other Tier 2 agents and are **not** the responsibility of `inv_notification.sql`:

- LAB_REPORT → CASE (`act_relationship_lab_inv` Tier 2 agent — `type_cd='LabReport'`).
- MORB_REPORT → CASE (`act_relationship_morb_inv` Tier 2 agent — `type_cd='MorbReport'`).
- TREATMENT → CASE (`act_relationship_treatment_inv` Tier 2 agent — `type_cd='TreatmentToPHC'`).
- PARTICIPATION_PATIENT_PHC (`SubjOfPHC` — drives Patient↔Investigation context for downstream Datamart patient columns).
- PARTICIPATION_REPORTER_PHC (`PerAsReporterOfPHC` / `OrgAsReporterOfPHC`).
- PARTICIPATION_PHYSICIAN_PHC (`PhysicianOfPHC`).
- NBS_ACT_ENTITY edges for Vaccination, Interview, Contact (other Tier 2 agents).

## Gaps reported

### INFRA_GAP

- **`dbo.sp_get_date_dim` references non-existent `dbo.rdb_date_temp` table** in baseline 6.0.18.1 (file `liquibase-service/src/main/resources/db/005-rdb_modern/routines/014-sp_get_date_dim-001.sql:26-55`). The SP errors with `Invalid object name 'dbo.rdb_date_temp'` on first execution, and even if the table were pre-created, line 49's `IF NOT EXISTS` branch produces a `#temp_date` table inside the IF body whose scope ends at the IF block — line 57's INSERT references `#temp_date` outside that scope, so the SP fails with `Invalid object name '#temp_date'`. **This is an upstream RTR bug, not a fixture concern.** STRATEGY.md's Merge contract step 2 says `EXEC dbo.sp_get_date_dim 2020, 2030`; until the upstream SP is fixed, the orchestrator should either (a) populate `RDB_DATE` directly (as we did for verification, via a recursive CTE) or (b) fix the SP body. For this agent's verification we used (a). Recommendation: file an RTR bug against `014-sp_get_date_dim-001.sql`.

### SRTE_GAP

None for this edge. `type_cd='Notification'` is verified present in baseline `NBS_SRTE.dbo.code_value_general` `code_set_nm='AR_TYPE'` (Phase B catalog).

### FOUNDATION_GAP

None. Foundation provides `@dbo_Act_notification_uid (20000110)` and `@dbo_Act_investigation_uid (20000100)` with appropriate class_cd values (NOTF, CASE). Tier 1 fixtures provide v2 Notification (20060010) and v2 Investigation (20050010).

### OUT_OF_SCOPE

- **Notification chain UPDATE branch on `dbo.HEPATITIS_DATAMART.INIT_NND_NOT_DT`** (`sp_nrt_notification_postprocessing` lines 336-358). At Tier 2 with the datamart chain not yet run, HEPATITIS_DATAMART has no rows for the notification's INVESTIGATION_KEY, so the `UPDATE ISD SET ISD.INIT_NND_NOT_DT = NND.FIRSTNOTIFICATIONSENDDATE` at line 354-357 no-ops. This is expected per Merge contract: datamart SPs run at step 9, after Tier 2. Re-running the Notification chain post-Hepatitis_Datamart will exercise this UPDATE branch (Tier 3 / final-merge concern).

- **Tier 1 Notification staging row's `public_health_case_uid` for v2.** Notification Tier 1 chose to point both staging rows (foundation + v2) at foundation Investigation (20000100), so NOTIFICATION_EVENT.INVESTIGATION_KEY resolves to foundation Inv's key (3) for both. The act_relationship in this Tier 2 fixture wires v2 Notif → v2 Inv at the ODSE level (per the per-edge prompt's instruction), which IS what sp_notification_event and sp_investigation_event need. The dimension-level INVESTIGATION_KEY discrepancy is a Tier 1 design decision not modifiable from Tier 2; not a gap of this edge.

## Decisions made under prompt ambiguity

- **Did not allocate any UIDs from block 21000000-21000999.** `dbo.act_relationship`'s primary key is the composite (source_act_uid, target_act_uid, type_cd). Both edges' source/target UIDs are foundation/Tier 1 references; no surrogate UID needed. The block is reserved (registry updated) in case a future amendment requires one — e.g., a v3 Notification variant whose own act_uid lives in this Tier 2 block.

- **`type_cd='Notification'`** chosen for both edges, matching NBS upstream convention. RTR doesn't filter on this literal in the relevant SP join — the SP only filters on `source_class_cd='NOTF' AND target_class_cd='CASE'` — but using `'Notification'` matches the catalog row and Phase B's "shape consistency with NBS data" guidance. Any other AR_TYPE code wiring NOTF→CASE would also satisfy the SP joins; we use the canonical one.

- **Edge 2 wires v2 Notif → v2 Inv (20060010 → 20050010)** even though Notification Tier 1's v2 staging row sets `public_health_case_uid=20000100` (foundation Inv). The act_relationship is at the ODSE-act-uid level; the staging row is at the RDB_MODERN level. The per-edge prompt explicitly directs `v2 Notification (UID 20060010) → v2 Investigation (UID 20050010)` for Edge 2; we follow that. The downstream dimensional INVESTIGATION_KEY value of NOTIFICATION_EVENT for the v2 row is governed by the Tier 1 staging row, not by this edge — consistent with the Tier 2 contract (no INSERTs into RDB_MODERN dims).

- **No second `Notification` edge from foundation Notif to v2 Inv (20000110 → 20050010) or v2 Notif to foundation Inv.** The prompt specifies "Two pairs (foundation→foundation + v2→v2)" exactly; we do not author additional cross-pairings.

- **No NOTIFICATION_HIST history rows authored.** Per `coverage_notification.md` Decision: NOTIFICATION_HIST is a history-table concern that doesn't affect NOTIFICATION + NOTIFICATION_EVENT dimension coverage. Deferred to Tier 3.

## Verification recipe (reproducible)

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting
docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure (Merge contract step 2). Note INFRA_GAP for sp_get_date_dim.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "..."   # populate RDB_DATE
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'"

# Foundation + relevant Tier 1
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -i fixtures/00_foundation/00_foundation.sql
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -i fixtures/10_subjects/patient.sql
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -i fixtures/10_subjects/investigation.sql
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -i fixtures/10_subjects/notification.sql

# Run Patient + Investigation chains (NOT Notification — its FK gap blocks it)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010,20020020'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010,20020020', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"

# Apply edge fixture (its tail-EXEC re-runs the Notification chain)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -i fixtures/20_links/inv_notification.sql

# Verify
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "
  SELECT COUNT(*) FROM dbo.NOTIFICATION;        -- expected: 2
  SELECT COUNT(*) FROM dbo.NOTIFICATION_EVENT;  -- expected: 2
  SELECT NOTIFICATION_KEY, PATIENT_KEY, INVESTIGATION_KEY, CONDITION_KEY FROM dbo.NOTIFICATION_EVENT;
"
```

## Confirmation

All three deliverables exist:

- ✓ `fixtures/20_links/inv_notification.sql` (2 act_relationship rows + post-edge SP re-run).
- ✓ `coverage/coverage_inv_notification.md` (this file).
- ✓ `catalog/uid_ranges.md` updated with Tier 2 — `Notification` edge entry.
