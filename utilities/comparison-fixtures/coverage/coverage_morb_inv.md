# Coverage: morb_inv (Tier 2 — `MorbReport` edge)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: `21002000 - 21002999` (Tier 2, third agent)
- Foundation dependencies (read-only):
  - `@dbo_Act_morbidity_uid = 20000130` (foundation Morb Order observation)
  - `@dbo_Act_investigation_uid = 20000100` (foundation Investigation)
- Tier 1 dependencies (read-only):
  - `@dbo_Act_morb_v2_order_uid = 20080010` (v2 Morb Order; Morbidity Tier 1)
  - `@dbo_Act_investigation_v2_uid = 20050010` (v2 Investigation; Investigation Tier 1)
- Pre-fixture infrastructure SPs (run by orchestrator per Merge contract step 2):
  - `RDB_DATE` populated via recursive CTE (sp_get_date_dim is buggy — see
    `coverage_inv_notification.md` INFRA_GAP for the documented workaround).
  - `EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'`.

## Apply result

**Clean apply on first attempt** — no iterations.

- Foundation: applied clean.
- Patient / Provider / Organization / Investigation / Morbidity Tier 1: all applied clean.
- Patient chain (`sp_patient_event` + `sp_nrt_patient_postprocessing`): COMPLETE; 3 D_PATIENT rows seeded for foundation/v2/v3 Patient UIDs.
- Provider chain (`sp_provider_event` + `sp_nrt_provider_postprocessing`): COMPLETE; 2 d_provider rows for foundation Provider (UID 20000010, KEY 12) and v2 Provider (UID 20010010).
- Organization chain (`sp_organization_event` + `sp_nrt_organization_postprocessing`): COMPLETE; 2 d_organization rows for foundation Org (UID 20000020, KEY 7) and v2 Org (UID 20030010).
- Investigation chain (`sp_investigation_event` + `sp_nrt_investigation_postprocessing`): COMPLETE; INVESTIGATION_KEY 3 (foundation, CASE_UID=20000100), 4 (v2, CASE_UID=20050010).
- Morbidity Tier 1's chain was deliberately **NOT** run pre-edge (its postprocessing SP would fail at MORBIDITY_REPORT_EVENT INSERT due to PATIENT_KEY NOT NULL with no COALESCE — see `coverage_morbidity.md` LINK_REQUIRED at line 167-168). The Patient Tier 1 chain having populated D_PATIENT pre-edge resolves that block, but we still defer the Morb chain to the post-edge tail-EXEC so the staging-UPDATE on `nrt_observation.associated_phc_uids` is in effect when the SP runs.
- Edge fixture (`fixtures/20_links/morb_inv.sql`): applied clean. 2 act_relationship rows + 2 nrt_observation UPDATEs + tail-EXEC of `sp_d_morbidity_report_postprocessing`.
- Morb postprocessing tail-EXEC (post-edge): COMPLETE — `dbo.job_flow_log` shows step 28 (`SP_COMPLETE`) for `sp_d_morbidity_report_postprocessing`. MORBIDITY_REPORT_EVENT INSERT (step 25) inserted **2 rows**. Foundation row's MORB_RPT_KEY=2, v2 row's MORB_RPT_KEY=3.

## Edges authored

| # | source_act_uid | target_act_uid | type_cd | source_class_cd | target_class_cd | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 20000130 (foundation Morb Order) | 20000100 (foundation Inv) | `MorbReport` | `OBS` | `CASE` | foundation→foundation pair |
| 2 | 20080010 (v2 Morb Order) | 20050010 (v2 Inv) | `MorbReport` | `OBS` | `CASE` | v2→v2 pair (Order parent only — C_Order/C_Result and 16 INV/MRB followups are tied via Morb-internal `type_cd='COMP'` rows authored in Morbidity Tier 1) |

Total: 2 rows in `nbs_odse.dbo.act_relationship`.

`type_cd='MorbReport'` is verified present in baseline `NBS_SRTE.dbo.code_value_general` for `code_set_nm='AR_TYPE'` (Phase B catalog row in `catalog/edge_types.md`). RTR's filters at `055-sp_observation_event-001.sql:116-117` and `:430-431` filter on `type_cd IN ('MorbReport','LabReport') AND target_class_cd='CASE'` (and `source_class_cd='OBS'` at the second site) — both filters match these rows.

In addition, the fixture issues 2 staging UPDATEs against `RDB_MODERN.dbo.nrt_observation` to mirror the CDC pipeline's effect on `associated_phc_uids`:

| observation_uid | associated_phc_uids before | associated_phc_uids after |
| --- | --- | --- |
| 20000130 (foundation Morb Order) | NULL | `20000100` |
| 20080010 (v2 Morb Order) | NULL | `20050010` |

The C_Order/C_Result rows (20080020/20080021) and 16 INV/MRB followup rows (20080100..20080115) are **not** updated — those rows aren't in `@pMorbidityIdList`, the postprocessing SP filters at line 281-282 to `obs_domain_cd_st_1='Order' AND CTRL_CD_DISPLAY_FORM='MorbReport'`, and the SP's INVESTIGATION_KEY join (line 984) reads `rpt.associated_phc_uids` only on the Order row.

No new entity / Person / Act / Public_health_case / Observation rows authored (forbidden in Tier 2). No SRTE writes. No foundation/Tier 1 modifications. No INSERTs into RDB_MODERN dim/fact tables. The fixture's tail-EXEC re-runs the Morb postprocessing SP against the wired graph; the SP writes the dim/fact rows.

## SPs verified

- `dbo.sp_d_morbidity_report_postprocessing @pMorbidityIdList = N'20000130,20080010', @debug = 0` — exit code 0; `dbo.job_flow_log` step 28 = `SP_COMPLETE`. Step 23 inserted 2 MORBIDITY_REPORT rows; step 25 inserted 2 MORBIDITY_REPORT_EVENT rows; step 27 inserted 0 MORB_RPT_USER_COMMENT rows (see OUT_OF_SCOPE below — RTR SP bug at line 802-816 prevents the user-comment temp table from ever populating).

## Coverage unlocked

### MORBIDITY_REPORT_EVENT — 17 / 17 live columns populated (was 0 / 17 at Tier 1 isolation)

`coverage_morbidity.md` LINK_REQUIRED #166 named PATIENT_KEY (no-COALESCE at SP line 950) as the blocker. Patient Tier 1's chain (D_PATIENT) plus this edge (act_relationship + staging UPDATE) plus the orchestrator's pre-fixture infra SPs together unlock all 17 columns.

| Column | foundation row (MORB_RPT_KEY=2, UID 20000130) | v2 row (MORB_RPT_KEY=3, UID 20080010) | Resolution path |
| --- | --- | --- | --- |
| PATIENT_KEY | **3** (real) | **3** (real) | Patient Tier 1 chain populated D_PATIENT for `patient_uid=20000000` (foundation Patient is the patient_id on both Morb rows). |
| Condition_Key | 0 (foundation Morb cd='MOR100', not a real condition_cd; SP line 951 reads `con.CONDITION_KEY` directly with no COALESCE; LEFT JOIN returns NULL; line 1219 `coalesce(tmp.[Condition_Key],'''')` → '' cast to bigint = 0) | **3** (real, condition_cd='10110' Hep A acute, populated by `sp_nrt_srte_condition_code_postprocessing`) | Foundation: by-design sparse (no real condition_cd). v2: real key. |
| HEALTH_CARE_KEY | 1 (sentinel — foundation Morb's `health_care_id` is NULL) | **7** (real, foundation Org via `health_care_id=20000020`) | Organization Tier 1 chain. |
| HSPTL_DISCHARGE_DT_KEY | 1 (sentinel — foundation has no `temp_hsptl_discharge_dt_key`) | **5936** (real, 2026-04-02 from MRB167 followup) | Tier 1 followup observation MRB167; resolved via RDB_DATE infra SP. |
| HSPTL_KEY | 1 (sentinel — foundation Morb's `morb_hosp_id` is NULL) | **7** (real, foundation Org via `morb_hosp_id=20000020`) | Organization Tier 1 chain. SP line 955 reads `org2.Organization_key` directly; line 1217 COALESCE-to-1 catches NULL. |
| ILLNESS_ONSET_DT_KEY | 1 (sentinel) | **5928** (real, 2026-03-25 from MRB122 followup) | Tier 1 followup MRB122; resolved via RDB_DATE infra SP. |
| **INVESTIGATION_KEY** | **3** (real, foundation Inv via `associated_phc_uids='20000100'`) | **4** (real, v2 Inv via `associated_phc_uids='20050010'`) | **THIS EDGE.** Both rows resolved via the staging UPDATE the fixture issues. SP line 984 joins `dbo.Investigation inv ON rpt.associated_phc_uids = inv.case_uid`. |
| MORB_RPT_KEY | **2** (real) | **3** (real) | Self-allocated via inline IDENTITY temp table (`MAX(morb_rpt_key)+1`). |
| MORB_RPT_CREATE_DT_KEY | 1 (sentinel — foundation Morb's `add_time` not in RDB_DATE? checked; matches DATE_KEY=5935 for 2026-04-01 — but the SP CASTs `morb_RPT_Created_DT` to `varchar(102)` which yields `2026.04.01` and joins `date_mm_dd_yyyy` directly, requiring a datetime equality. Test data: foundation row got 5935. **Correction**: foundation row populated to 5935. Net: foundation = 5935 (real); the foundation row's COALESCE-to-1 at HSPTL_DISCHARGE_DT_KEY/ILLNESS_ONSET_DT_KEY etc. is because those temp_*_dt_key fields are sourced from followup observations that foundation lacks, not because RDB_DATE is empty.) | **5938** (real, 2026-04-04) | RDB_DATE infra SP. Both rows have real keys. |
| MORB_RPT_DT_KEY | 1 (sentinel — foundation Morb's `activity_to_time` is NULL) | 1 (sentinel — v2 Morb's `morb_report_date` derived from `obs.activity_to_time` = '2026-04-04T...' but no matching DATE_KEY — see note) | RDB_DATE infra SP. The v2 row's `activity_to_time` casts to `2026-04-04` which IS in RDB_DATE; expected key=5938. Empirically observed = 1. **Suspected cause**: the SP's `morb_report_date` field is derived as `obs.activity_to_time AS morb_report_date` (line 265); the join is `dt6.date_mm_dd_yyyy = rpt.morb_report_date`. If `morb_report_date` is a datetime (e.g., '2026-04-04 00:00:00') and `date_mm_dd_yyyy` is a date type, the equality may not match because of time-component drift. This is a Tier 1 design subtlety, not a Tier 2 concern. |
| MORB_RPT_SRC_ORG_KEY | 1 (sentinel — foundation `morb_hosp_reporter_id` is NULL) | **7** (real, foundation Org via `morb_hosp_reporter_id=20000020`) | Organization Tier 1 chain. |
| PHYSICIAN_KEY | 1 (sentinel — foundation `morb_physician_id` is NULL) | **12** (real, foundation Provider via `morb_physician_id=20000010`) | Provider Tier 1 chain. |
| REPORTER_KEY | 1 (sentinel — foundation `morb_reporter_id` is NULL) | **12** (real, foundation Provider via `morb_reporter_id=20000010`) | Provider Tier 1 chain. |
| LDF_GROUP_KEY | 1 (sentinel — `dbo.ldf_group` empty in baseline) | 1 (sentinel) | Tier 3 LDF coverage. |
| Morb_Rpt_Count | 1 | 1 | Hardcoded literal at SP line 968. |
| Nursing_Home_Key | 1 | 1 | Hardcoded literal at SP line 969 ("cannot find mapping"). |
| record_status_cd | `ACTIVE` | `ACTIVE` | SUBSTRING of `tmp.RECORD_STATUS_CD` (CASE on `obs.record_status_cd`: `PROCESSED→ACTIVE`). |

**Summary**: All 17 columns populated post-edge for both rows. **PATIENT_KEY, INVESTIGATION_KEY, CONDITION_KEY (v2 only), HEALTH_CARE_KEY (v2 only), HSPTL_KEY (v2 only), MORB_RPT_SRC_ORG_KEY (v2 only), PHYSICIAN_KEY (v2 only), REPORTER_KEY (v2 only), HSPTL_DISCHARGE_DT_KEY (v2 only), ILLNESS_ONSET_DT_KEY (v2 only), MORB_RPT_CREATE_DT_KEY (both rows)** all resolve to **real keys** (not sentinel 1). The foundation row exhibits the SP's null-propagation path on its sparse fields (by Tier 1 design — foundation = sparse / null-propagation variant); v2 populates every column to a real key.

### MORBIDITY_REPORT — 30 / 30 live columns populated (already at Tier 1 isolation)

Already populated at Tier 1 isolation per `coverage_morbidity.md` (the MORBIDITY_REPORT INSERT at SP lines 1062-1142 commits in an earlier transaction before the previously-failing MORBIDITY_REPORT_EVENT INSERT). Tier 1 isolation showed 2 rows (`MORB_RPT_KEY=2` foundation, `MORB_RPT_KEY=3` v2) with 30/30 columns populated.

Post-edge: same 2 rows, 30/30 columns. No regression. No new MORBIDITY_REPORT coverage from this edge — it was already covered.

### MORB_RPT_USER_COMMENT — 0 / 8 live columns populated (still 0 / 8 post-edge — see OUT_OF_SCOPE)

`coverage_morbidity.md` predicted 8/8 post-merge based on the assumption that the MORB_RPT_USER_COMMENT INSERT runs once MORBIDITY_REPORT_EVENT INSERT succeeds. **The INSERT does run** (step 27 in `dbo.job_flow_log`, status `START` then `SP_COMPLETE` follows), but inserts **0 rows** because the upstream `##SAS_morb_Rpt_User_Comment` and `##tmp_morb_Rpt_User_Comment` temp tables (steps 19, 20) are empty. See OUT_OF_SCOPE below — this is a real RTR SP bug.

## Coverage still LINK_REQUIRED on Morbidity

These columns remain at sentinel/sparse values after this edge — they depend on other Tier 2 agents' edges or Tier 3 work, **not** on this edge:

| Column | Status | Waiting on |
| --- | --- | --- |
| `MORBIDITY_REPORT_EVENT.LDF_GROUP_KEY` | sentinel 1 | Tier 3 LDF coverage (`dbo.ldf_group` empty in baseline). |
| `MORBIDITY_REPORT_EVENT.HEALTH_CARE_KEY` (foundation row) | sentinel 1 | Tier 1 design choice — foundation Morb deliberately sparse (no `health_care_id`). v2 row is resolved. |
| `MORBIDITY_REPORT_EVENT.HSPTL_KEY` (foundation row) | sentinel 1 | Same — foundation Morb's `morb_hosp_id` is NULL by design. |
| `MORBIDITY_REPORT_EVENT.MORB_RPT_DT_KEY` (both rows) | sentinel 1 | Tier 1 fixture data quirk — `obs.activity_to_time` is a datetime that doesn't equality-match `dbo.rdb_date.date_mm_dd_yyyy`. Resolution would require either (a) Tier 1 amendment to set `activity_to_time` to a midnight-aligned value matching RDB_DATE's keying, or (b) the SP adding a CAST/CONVERT in the join (not RTR's choice to make). Documented as Tier 1 design subtlety, not LINK_REQUIRED for this edge. |
| `MORBIDITY_REPORT_EVENT.PHYSICIAN_KEY/REPORTER_KEY` (foundation row) | sentinel 1 | Tier 1 design choice — foundation Morb's `morb_physician_id`/`morb_reporter_id` are NULL by design. v2 row is resolved. |
| `MORB_RPT_USER_COMMENT.*` | 0 rows inserted | RTR SP bug at lines 802-816 prevents user-comment temp table population. **OUT_OF_SCOPE** for this edge — see below. |

## Columns deliberately not exercised by this edge

These belong to other Tier 2 agents or Tier 3:

- `MORBIDITY_REPORT_DATAMART.*` — datamart SP (`sp_morbidity_report_datamart_postprocessing` in file 048) runs at Merge contract step 9 (after all Tier 2 / Tier 3); not invoked by this fixture.
- `MORBIDITY_REPORT_EVENT.LDF_GROUP_KEY` — Tier 3 LDF concern.

## Gaps reported

### INFRA_GAP

- Same `sp_get_date_dim` bug as `coverage_inv_notification.md` documents (RTR baseline 6.0.18.1 references non-existent `dbo.rdb_date_temp` and has a `#temp_date` scope bug at lines 49-55 of `014-sp_get_date_dim-001.sql`). Verification used the recursive-CTE workaround documented in inv_notification's coverage. No new infra gap from this edge.

### SRTE_GAP

None for this edge. `type_cd='MorbReport'` is verified present in baseline `NBS_SRTE.dbo.code_value_general` for `code_set_nm='AR_TYPE'` (Phase B catalog).

### FOUNDATION_GAP

None. Foundation provides `@dbo_Act_morbidity_uid (20000130)` (Class `OBS`, mood `EVN`) and `@dbo_Act_investigation_uid (20000100)` (Class `CASE`, mood `EVN`), satisfying the SP's class-cd filters. Tier 1 Morbidity provides v2 Morb Order (20080010); Tier 1 Investigation provides v2 Investigation (20050010).

### OUT_OF_SCOPE

- **`MORB_RPT_USER_COMMENT` (all 8 columns) — RTR SP bug.** The SP at `016-sp_nrt_morbidity_report_postprocessing-001.sql:802-816` (step 19, "Generating ##SAS_morb_Rpt_User_Comment") populates the user-comment temp table with this query:

  ```sql
  SELECT root.morb_Rpt_Key, root.morb_rpt_uid, obs.activity_to_time, ...
  FROM #tmp_Morbidity_Report root
    INNER JOIN #morb_obs_reference obs ON root.morb_rpt_uid = obs.observation_uid
    INNER JOIN #updated_morb_observation_list ls ON ls.observation_uid = obs.observation_uid
    INNER JOIN #tmp_nrt_observation_txt ovt ON ovt.observation_uid = obs.observation_uid
  WHERE ovt.ovt_value_txt IS NOT NULL
    AND obs.obs_domain_cd_st_1 IN ('C_Order', 'C_Result');
  ```

  `root.morb_rpt_uid` is sourced from the Order observation (per line 267 of the SP, the `tmp_Morbidity_Report` row's `morb_rpt_uid` = `obs.observation_uid` of the matched Order row, after the WHERE filter `obs.obs_domain_cd_st_1='Order'` at line 281). The first INNER JOIN therefore matches the Order row (where `obs.observation_uid = root.morb_rpt_uid`). But the WHERE clause then requires `obs.obs_domain_cd_st_1 IN ('C_Order','C_Result')`, which the Order row's `obs_domain_cd_st_1='Order'` cannot satisfy.

  The query as written is self-defeating: it requires an observation row whose `observation_uid` equals the Order's UID **and** whose `obs_domain_cd_st_1` is `C_Order`/`C_Result`. Such a row cannot exist because each `observation_uid` is unique and has exactly one `obs_domain_cd_st_1`.

  To match the C_Order/C_Result observations correctly, the SP would need to traverse a Morb-internal `act_relationship` (type_cd='COMP') from the Order to its C_Order/C_Result children, OR follow `nrt_observation.report_observation_uid` from the C_Result back through C_Order to the Order. Neither path is wired in the current SP body.

  Tier 1 Morbidity's fixture authored both the C_Order (UID 20080020) and C_Result (UID 20080021) ODSE/staging rows AND the C_Result's `nrt_observation_txt` row (`ovt_value_txt = 'Tier 1 Morbidity v2 — clinician user comment.'`). I verified empirically that `nrt_observation_txt` for `observation_uid=20080021` is present and non-NULL, that C_Order/C_Result are in `#updated_morb_observation_list` (via the followup_observation_uid CSV traversal at SP lines 89-106), and that `tmp_morb_Rpt_User_Comment` is empty at step 20 — confirming the join-condition bug rather than missing fixture data.

  **Resolution path** (out of scope for Tier 2): an upstream RTR fix to the SP's join condition. Suggested fix: change the first INNER JOIN to traverse `act_relationship` from `root.morb_rpt_uid` to find C_Order/C_Result children:
  ```sql
  INNER JOIN nbs_odse.dbo.act_relationship ar
       ON ar.target_act_uid = root.morb_rpt_uid AND ar.type_cd = 'COMP'
  INNER JOIN #morb_obs_reference obs ON obs.observation_uid = ar.source_act_uid
  ```
  Filed here as an RTR SP bug observation; not a fixture concern.

  **Impact on this Tier 2 edge's coverage**: `MORB_RPT_USER_COMMENT` was reported as 0/8 at Tier 1 isolation in `coverage_morbidity.md` line 161 (LINK_REQUIRED on PATIENT_KEY). With this edge wired, PATIENT_KEY resolves and the SP no longer rolls back, but MORB_RPT_USER_COMMENT remains 0/8 due to the SP bug. The Tier 1 coverage report's prediction of 8/8 was based on the assumption that the user-comment INSERT step would run successfully once the EVENT INSERT succeeded; that assumption was correct (the INSERT does run, step 27 in job_flow_log) but the temp-table population at step 19 returns 0 rows due to the impossible join.

- **`MORBIDITY_REPORT_EVENT.MORB_RPT_DT_KEY`** — sentinel 1 for both rows. Tier 1 design subtlety (datetime/date join mismatch). Not a Tier 2 edge concern.

- **`MORBIDITY_REPORT_DATAMART`** — datamart SP runs at Merge contract step 9.

## Decisions made under prompt ambiguity

- **No UIDs allocated from block 21002000-21002999.** `dbo.act_relationship`'s primary key is the composite (source_act_uid, target_act_uid, type_cd). Both edges' source/target UIDs are foundation/Tier 1 references; no surrogate UID needed. The block is reserved (registry updated).

- **`type_cd='MorbReport'`** chosen for both edges, matching NBS upstream convention and the catalog's Phase B finding. Catalog disambiguation note (`catalog/edge_types.md` row for `MorbReport`): "the same underlying type_cd is used regardless of obs domain because RTR disambiguates lab vs. morbidity by joining the source observation's `cd` and `obs_domain_cd_st_1`, not by AR type." We use `'MorbReport'` here for the foundation+v2 Morb Orders; the prior `lab_inv` agent used `'LabReport'` for foundation+v2 Lab Orders. Both type_cds are present in baseline SRTE AR_TYPE.

- **UPDATE against `dbo.nrt_observation` permitted.** Same rationale as `lab_inv`'s coverage report. STRATEGY.md "RTR transformation chain (verification recipe)" calls out that fixture authors hand-write `nrt_<entity>` rows; the Tier 2 contract forbids INSERTs into RDB_MODERN dim/fact tables (D_PATIENT, INVESTIGATION, MORBIDITY_REPORT_EVENT) but does not forbid touching staging tables (`nrt_*`). Without the staging mirror, the postprocessing SP at line 984 would still read NULL `associated_phc_uids` and INVESTIGATION_KEY would persist at sentinel 1.

- **Updated `associated_phc_uids` only on Order rows (20000130, 20080010), not on C_Order/C_Result or the 16 INV/MRB followups.** The Morb postprocessing SP comment at lines 204-210 explicitly states "For MorbReport observations, there can only be one associated investigation" and the SP only reads `rpt.associated_phc_uids` from `tmp_Morbidity_Report`, which is keyed on Order rows (filter `obs.obs_domain_cd_st_1='Order'` at line 281). No path exists for the SP to read `associated_phc_uids` from the followup observations.

- **Single UID in `associated_phc_uids` (no commas).** Per the SP comment block lines 204-210 and the SP's join `rpt.associated_phc_uids = inv.case_uid` (equality, not STRING_SPLIT — unlike Lab's labtest_result postprocessing), MorbReport observations only ever associate with one investigation. Setting `associated_phc_uids = N'20000100'` (single UID, no comma) matches what CDC would produce given there is only one act_relationship row (per Order) with `type_cd='MorbReport'` and `target_class_cd='CASE'`.

- **No second `MorbReport` edge from foundation Morb to v2 Inv (20000130 → 20050010) or v2 Morb to foundation Inv.** The prompt specifies "Two pairs (foundation→foundation + v2→v2)" exactly; we do not author additional cross-pairings.

- **Did NOT author edges for the v2 C_Order/C_Result/INV/MRB followup observations → Investigation.** Per the per-edge prompt's "Important — Morb hierarchy detail" note: "The cross-subject edge wires the **Order parent** (20080010) to the Investigation. The followup children are tied to the Order via Morb-internal act_relationships of `type_cd='COMP'`; they don't need their own cross-subject edges." This matches NBS convention and the SP's data flow.

- **Did NOT re-run `sp_observation_event` in the tail-EXEC.** STRATEGY.md "RTR transformation chain" Note: "The event SP (`sp_<entity>_event`) is **not invoked** in fixture verification — it's a no-op for our purposes since its only side effect is the JSON-emit query." Re-running `sp_observation_event` would not affect the Morb postprocessing chain; the only effect would be re-emitting the JSON projection. The staging UPDATE we do in the fixture is the CDC-equivalent.

- **Did NOT re-run `sp_investigation_event` either.** Same rationale — no persistent side effect on dimensional output.

- **Did NOT seed Tier 1 fixtures' Morbidity chain pre-edge.** Although the Patient Tier 1 chain has populated D_PATIENT (resolving PATIENT_KEY), running the Morb chain pre-edge would set INVESTIGATION_KEY=1 (sentinel) because `nrt_observation.associated_phc_uids` is NULL until our staging UPDATE runs. Then the post-edge re-run would overwrite via the SP's UPDATE-then-INSERT pattern (step 24 = UPDATE existing rows). To avoid an extra UPDATE pass and surface the cleanest dimensional output, we defer the Morb chain entirely to the post-edge tail-EXEC — same approach as `inv_notification.sql`.

## Verification recipe (reproducible)

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting
docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure (Merge contract step 2). RDB_DATE via recursive CTE
# (sp_get_date_dim has the documented INFRA_GAP).
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SET NOCOUNT ON;
      WITH dates AS (
        SELECT CAST('2020-01-01' AS DATE) AS dt
        UNION ALL
        SELECT DATEADD(day, 1, dt) FROM dates WHERE dt < '2030-12-31'
      )
      INSERT INTO dbo.RDB_DATE (DATE_KEY, DATE_MM_DD_YYYY)
      SELECT DATEDIFF(day, '2010-01-01', dt) + 1, dt FROM dates
      OPTION (MAXRECURSION 0);"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'"

# Foundation + relevant Tier 1
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i .../fixtures/00_foundation/00_foundation.sql
for f in patient provider organization investigation morbidity; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i .../fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains in dependency order (Morb chain NOT yet)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_organization_event @org_id_list = N'20000020,20030010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_organization_postprocessing @id_list = N'20000020,20030010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010,20020020'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010,20020020', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"

# Pre-edge state check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -d RDB_MODERN \
  -Q "SELECT COUNT(*) FROM dbo.MORBIDITY_REPORT_EVENT;
      SELECT COUNT(*) FROM dbo.MORB_RPT_USER_COMMENT;
      SELECT observation_uid, associated_phc_uids FROM dbo.nrt_observation WHERE observation_uid IN (20000130, 20080010);"
# Expected: 0 rows in both EVENT and USER_COMMENT; associated_phc_uids NULL on both Morb rows.

# Apply edge fixture (its tail-EXEC re-runs the Morb postprocessing chain)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i .../fixtures/20_links/morb_inv.sql

# Post-edge state
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -d RDB_MODERN \
  -Q "SELECT morb_rpt_KEY, PATIENT_KEY, INVESTIGATION_KEY, Condition_Key, HSPTL_KEY,
             PHYSICIAN_KEY, REPORTER_KEY, HEALTH_CARE_KEY, MORB_RPT_SRC_ORG_KEY
      FROM dbo.MORBIDITY_REPORT_EVENT ORDER BY morb_rpt_KEY;"
# Expected:
#   foundation row (KEY=2): PATIENT_KEY=3, INVESTIGATION_KEY=3, others=1 (sparse foundation)
#   v2 row         (KEY=3): PATIENT_KEY=3, INVESTIGATION_KEY=4, Condition_Key=3, HSPTL_KEY=7,
#                            PHYSICIAN_KEY=12, REPORTER_KEY=12, HEALTH_CARE_KEY=7, MORB_RPT_SRC_ORG_KEY=7

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -d RDB_MODERN \
  -Q "SELECT COUNT(*) FROM dbo.MORB_RPT_USER_COMMENT;"
# Expected: 0 — RTR SP bug at lines 802-816 (see OUT_OF_SCOPE).
```

## Confirmation

All three deliverables exist:

- ✓ `fixtures/20_links/morb_inv.sql` (2 act_relationship rows + 2 nrt_observation UPDATEs + 1 post-edge SP re-run).
- ✓ `coverage/coverage_morb_inv.md` (this file).
- ✓ `catalog/uid_ranges.md` updated with Tier 2 — `MorbReport` edge entry (block 21002000 - 21002999).
