# Coverage: interview_phc (Tier 2 — `IXS` Interview→Investigation edge)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: `21011000 - 21011999` (Tier 2, twelfth agent). No surrogate UIDs consumed (act_relationship has composite PK); block reserved.
- Foundation dependencies (read-only):
  - `@dbo_Act_interview_uid = 20000140` (foundation Interview, class_cd `ENC`)
  - `@dbo_Act_investigation_uid = 20000100` (foundation Investigation, class_cd `CASE`)
- Tier 1 dependencies (read-only):
  - `@dbo_Act_interview_v2_uid = 20090010` (Interview Tier 1)
  - `@dbo_Act_investigation_v2_uid = 20050010` (Investigation Tier 1)
- Pre-fixture infrastructure SPs (run by orchestrator per Merge contract step 2):
  - `RDB_DATE` populated via recursive CTE workaround (per `INFRA_GAP` documented in `coverage_inv_notification.md` — `sp_get_date_dim` is broken upstream).
  - `EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'`.

## Apply result

Clean apply on first attempt.

- Foundation: applied clean.
- Tier 1 fixtures applied clean: patient, provider, organization, place, investigation, interview, contact.
- Tier 1 chains run clean in dependency order. Pre-edge `sp_interview_event` confirmed `INVESTIGATION_UID = NULL` on both `#INTERVIEW_INIT` rows.
- Edge fixture (`fixtures/20_links/interview_phc.sql`): applied clean — 2 rows inserted into `dbo.act_relationship`.
- Tail-EXEC `sp_interview_event @ix_uids = N'20000140,20090010'` post-edge: COMPLETE; **`INVESTIGATION_UID` flipped from NULL to populated** for both rows:
  - foundation Interview (20000140) → `INVESTIGATION_UID = 20000100`
  - v2 Interview (20090010) → `INVESTIGATION_UID = 20050010`

## Edges authored

| # | source_act_uid | target_act_uid | type_cd | source_class_cd | target_class_cd | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 20000140 (foundation Interview) | 20000100 (foundation Investigation) | `IXS` | `ENC` | `CASE` | foundation→foundation pair |
| 2 | 20090010 (v2 Interview) | 20050010 (v2 Investigation) | `IXS` | `ENC` | `CASE` | v2→v2 pair |

Total: 2 rows in `nbs_odse.dbo.act_relationship`.

`type_cd='IXS'` is **MISSING from baseline `NBS_SRTE.dbo.code_value_general` `code_set_nm='AR_TYPE'`** per Phase B's catalog (`catalog/edge_types.md` row 338) — found in `BUS_OBJ_TYPE` and `INFO_SOURCE_COVID` code sets but not in `AR_TYPE`. RTR's `sp_interview_event` filters on the literal `IXS` value at line 86 of `065-sp_interview_event-001.sql` regardless. Per the Phase B "MISSING_FROM_SRTE used anyway" policy, we author with the literal `type_cd` value.

No new entity / Person / Act / Public_health_case / Interview / Investigation rows authored (forbidden in Tier 2). No SRTE writes, no foundation/Tier 1 modifications, no INSERTs into RDB_MODERN dim/fact tables. The fixture's tail-EXEC re-runs `sp_interview_event` against the wired graph; no postprocessing SP re-run is necessary.

## SPs verified

- `dbo.sp_interview_event @ix_uids = N'20000140,20090010', @debug = 0` — **exit code 0**; 2 `#INTERVIEW_INIT` rows projected. `INVESTIGATION_UID` post-edge: **20000100 (foundation), 20050010 (v2)** — flipped from NULL pre-edge.
- `dbo.sp_d_interview_postprocessing` and `dbo.sp_f_interview_case_postprocessing` — **NOT re-run by this edge** (these read from `nrt_interview` / `nrt_interview_note` / `nrt_interview_answer`, not `act_relationship`; coverage is **byte-identical pre/post-edge**).
- Edge-row landing verified directly: `SELECT type_cd, source_class_cd, target_class_cd, source_act_uid, target_act_uid FROM dbo.act_relationship WHERE type_cd = 'IXS'` → 2 rows as expected.

## Coverage unlocked

### Interview event SP JSON projection — 1 column flipped (per row)

| `#INTERVIEW_INIT` row | Column | Pre-edge | Post-edge |
| --- | --- | --- | --- |
| foundation Interview (20000140) | `INVESTIGATION_UID` | NULL | **20000100** (foundation Investigation) |
| v2 Interview (20090010) | `INVESTIGATION_UID` | NULL | **20050010** (v2 Investigation) |

### RDB_MODERN dim/fact unlocks — 0 columns

`D_INTERVIEW` (2 rows, 18/24 + 6 LDF OUT_OF_SCOPE), `D_INTERVIEW_NOTE` (2 rows, 7/7), `F_INTERVIEW_CASE` (2 rows, 8/10) populations are **byte-identical pre/post-edge**. The postprocessing SPs do not traverse `act_relationship`; their input is `nrt_interview*` (hand-authored by Tier 1).

This matches the per-edge prompt's coverage assessment exactly: *"D_INTERVIEW/D_INTERVIEW_NOTE/F_INTERVIEW_CASE unchanged (LEFT JOIN, no unblock). Event-SP JSON projection INVESTIGATION_UID flipped NULL→20000100/20050010."*

The PRIMARY value of this edge is therefore:

1. **JSON-projection coverage** of `sp_interview_event`'s `INVESTIGATION_UID` field, which Kafka consumers in production read.

2. **ODSE graph correctness** for the eventual RDB-vs-RDB_MODERN comparison test against MasterETL — MasterETL traverses `act_relationship` to derive Interview→Investigation linkages on the RDB side.

## Coverage still LINK_REQUIRED

None for this edge type's responsibilities. Interview's Tier 1 / Tier 2 coverage reports (`coverage_interview.md`, `coverage_interview_links.md`) note that `INVESTIGATION_UID` stays NULL post-`interview_links` because `IXS` `act_relationship` is the gating edge — and **this fixture resolves that.**

The other three Interview event-SP JSON-projection columns (`PROVIDER_UID`, `ORGANIZATION_UID`, `PATIENT_UID`) are populated by the `interview_links` Tier 2 fixture (sibling agent, `IntrvwerOfInterview` / `OrgAsSiteOfIntv` / `IntrvweeOfInterview` `nbs_act_entity` edges) — not this fixture's responsibility.

## Columns deliberately not exercised by this edge

These belong to other Tier 2 agents and are **not** the responsibility of `interview_phc.sql`:

- `nbs_act_entity` Interview-participant edges (`IntrvwerOfInterview`, `OrgAsSiteOfIntv`, `IntrvweeOfInterview`) — owned by `interview_links` Tier 2 agent.

## Gaps reported

### SRTE_GAP

- **`type_cd='IXS'` is MISSING_FROM_SRTE for `code_set_nm='AR_TYPE'`** in baseline 6.0.18.1 — found in `BUS_OBJ_TYPE` and `INFO_SOURCE_COVID` code sets but not in `AR_TYPE`. RTR's `sp_interview_event` filters on the literal `IXS` regardless of code-set membership. Per the Phase B "MISSING_FROM_SRTE used anyway" policy, this is intentional retained behavior — not a fixture-side defect. Recommendation: either upstream RTR adds an `IXS` row to `AR_TYPE`, or the annotation is preserved indefinitely. No fix required from fixture authors.

### FOUNDATION_GAP

None. Foundation provides `@dbo_Act_interview_uid (20000140)` (class_cd `ENC`) and `@dbo_Act_investigation_uid (20000100)` (class_cd `CASE`). Tier 1 fixtures provide v2 Interview (20090010, class_cd `ENC`) and v2 Investigation (20050010, class_cd `CASE`).

### OUT_OF_SCOPE

- **D_INTERVIEW / D_INTERVIEW_NOTE / F_INTERVIEW_CASE unchanged at Tier 1 isolation.** The Interview postprocessing SPs read soft-ref columns from `nrt_interview*` (hand-authored by Tier 1) and do not traverse `act_relationship`. The Tier 1 isolation coverage on these dim/fact tables is unaffected by this edge — by design. Documenting for clarity, not as a fix-needed gap.

## Decisions made under prompt ambiguity

- **No surrogate UIDs allocated from block 21011000-21011999.** `dbo.act_relationship`'s primary key is the composite `(source_act_uid, target_act_uid, type_cd)` — it does not need its own surrogate UID. Both edges' source/target UIDs are foundation/Tier 1 references. The block is reserved (registry updated) in case a future amendment requires one.

- **`type_cd='IXS'`** chosen — matches the literal value RTR's SP filters on at line 86 of `065-sp_interview_event-001.sql`. This is the only sensible value; other AR_TYPE codes (or BUS_OBJ_TYPE codes) would not satisfy the SP join.

- **`source_class_cd='ENC'`** verified against:
  - foundation Interview act class_cd at `00_foundation.sql:316` (`(@dbo_Act_interview_uid, N'ENC', N'EVN')`).
  - v2 Interview act class_cd at `interview.sql:188` (`(@dbo_Act_interview_v2_uid, N'ENC', N'EVN')`).

- **`target_class_cd='CASE'`** verified against:
  - foundation Investigation act class_cd at `00_foundation.sql:312` (`(@dbo_Act_investigation_uid, N'CASE', N'EVN')`).

- **`record_status_cd='ACTIVE'`, `status_cd='A'`, `sequence_nbr=1`** — chosen for shape parity with `inv_notification.sql` (sibling `act_relationship` Tier 2 fixture). The LEFT JOIN at lines 85-86 of `065-sp_interview_event-001.sql` has no predicate on these columns, so any value would satisfy the join; we use canonical NBS values.

- **Two pairs only (foundation→foundation + v2→v2).** No cross-pairings (foundation Interview → v2 Inv, etc.) per per-edge prompt explicit specification.

## Verification recipe (reproducible)

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting
docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure (Merge contract step 2). Note INFRA_GAP for sp_get_date_dim.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "
  SET NOCOUNT ON;
  WITH dates AS (
    SELECT CAST('2020-01-01' AS DATE) AS dt
    UNION ALL SELECT DATEADD(day, 1, dt) FROM dates WHERE dt < '2030-12-31'
  )
  INSERT INTO dbo.RDB_DATE (DATE_KEY, DATE_MM_DD_YYYY)
  SELECT DATEDIFF(day, '2010-01-01', dt) + 1, dt FROM dates
  OPTION (MAXRECURSION 0);"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110', @debug = 0"

# Foundation + relevant Tier 1
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i fixtures/00_foundation/00_foundation.sql
for f in patient provider organization investigation interview; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i fixtures/10_subjects/${f}.sql
done

# Run dependent Tier 1 chains
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "
  EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010';
  EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0;
  EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010,20020020';
  EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010,20020020', @debug = 0;
  EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010';
  EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0;
  EXEC dbo.sp_interview_event @ix_uids = N'20000140,20090010', @debug = 0;
  EXEC dbo.sp_d_interview_postprocessing @ix_uids = N'20000140,20090010', @debug = 0;
  EXEC dbo.sp_f_interview_case_postprocessing @ix_uids = N'20000140,20090010', @debug = 0;"

# Apply edge fixture (its tail-EXEC re-runs sp_interview_event)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i fixtures/20_links/interview_phc.sql

# Verify
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_ODSE -Q "
  SELECT type_cd, source_class_cd, target_class_cd, source_act_uid, target_act_uid
  FROM dbo.act_relationship WHERE type_cd = 'IXS' ORDER BY source_act_uid;"
```

Expected: 2 rows; `INVESTIGATION_UID` populated in `sp_interview_event` JSON projection.

## Confirmation

All three deliverables exist:

- `fixtures/20_links/interview_phc.sql` (2 act_relationship rows + tail-EXEC of `sp_interview_event`).
- `coverage/coverage_interview_phc.md` (this file).
- `catalog/uid_ranges.md` updated with Tier 2 — `interview_phc` block.
