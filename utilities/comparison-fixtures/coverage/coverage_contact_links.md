# Coverage: contact_links (Tier 2 — `SiteOfExposure` + `InvestgrOfContact` + `DispoInvestgrOfConRec` edges)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: `21010000 - 21010999` (Tier 2, eleventh agent)
- Foundation dependencies (read-only):
  - `@dbo_Act_contact_uid = 20000170` (foundation Contact / ct_contact, class_cd `ENC`)
  - `@dbo_Entity_place_uid = 20000030` (foundation Place)
  - `@dbo_Entity_provider_uid = 20000010` (foundation Provider, class_cd `PSN`)
- Tier 1 dependencies (read-only):
  - `@dbo_Act_contact_v2_uid = 20120010` (Contact Tier 1 v2 ct_contact, class_cd `ENC`)
  - `@dbo_Entity_provider_v2_uid = 20010010` (Provider Tier 1 v2 Provider)
- Pre-fixture infrastructure SPs (run by orchestrator per Merge contract step 2):
  - `RDB_DATE` populated via recursive CTE workaround (per `INFRA_GAP` documented in `coverage_inv_notification.md` — `sp_get_date_dim` is broken upstream).
  - `EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'` — populates `CONDITION` for Hep A acute.

## Apply result

Clean apply on first attempt.

- Foundation: applied clean.
- Tier 1 fixtures applied clean: patient, provider, organization, place, investigation, interview, contact.
- Tier 1 chains run clean in dependency order (provider → organization → patient → place → investigation → interview event/d/f → contact d/f). `sp_contact_record_event` deliberately skipped (broken upstream — see `OUT_OF_SCOPE_RTR_BUG` in `coverage_contact.md`).
- Edge fixture (`fixtures/20_links/contact_links.sql`): applied clean — 6 rows inserted into `dbo.nbs_act_entity` with surrogate UIDs 21010000-21010005. `IDENTITY_INSERT` wrap honored.

## Edges authored

| # | nbs_act_entity_uid | type_cd | act_uid | entity_uid | Notes |
| --- | --- | --- | --- | --- | --- |
| 1 | 21010000 | `SiteOfExposure` | 20000170 (foundation Contact) | 20000030 (foundation Place) | foundation→foundation |
| 2 | 21010001 | `SiteOfExposure` | 20120010 (v2 Contact) | 20000030 (foundation Place) | v2→foundation Place (no v2 Place variant; v1 simplification) |
| 3 | 21010002 | `InvestgrOfContact` | 20000170 (foundation Contact) | 20000010 (foundation Provider) | foundation→foundation |
| 4 | 21010003 | `InvestgrOfContact` | 20120010 (v2 Contact) | 20010010 (v2 Provider) | v2→v2 |
| 5 | 21010004 | `DispoInvestgrOfConRec` | 20000170 (foundation Contact) | 20000010 (foundation Provider) | foundation→foundation; same Provider as InvestgrOfContact |
| 6 | 21010005 | `DispoInvestgrOfConRec` | 20120010 (v2 Contact) | 20010010 (v2 Provider) | v2→v2; same Provider as InvestgrOfContact (v1 simplification) |

Total: 6 rows in `nbs_odse.dbo.nbs_act_entity`.

All three `type_cd` values are `MISSING_FROM_SRTE` per Phase B's catalog (`catalog/edge_types.md` rows 131-133 and 369-371). RTR's `sp_contact_record_event` filters on the literal values directly at lines 155-157 of `069-sp_contact_record_event-001.sql`, regardless of code-set membership. This matches the Phase B "MISSING_FROM_SRTE used anyway" policy.

No new entity / Person / Place / Provider / Act / ct_contact rows authored (forbidden in Tier 2). No SRTE writes, no foundation/Tier 1 modifications, no INSERTs into RDB_MODERN dim/fact tables. The fixture also has **no tail-EXEC** because the only event SP that consumes these edges (`sp_contact_record_event`) is broken upstream (see Gaps).

## SPs verified

- `dbo.sp_d_contact_record_postprocessing @contact_uids = N'20000170,20120010'` — exit code 0; 2 D_CONTACT_RECORD rows; **byte-identical pre/post-edge** (the SP reads from `nrt_contact` and does not traverse `nbs_act_entity`).
- `dbo.sp_f_contact_record_case_postprocessing @contact_uids = N'20000170,20120010'` — exit code 0; 2 F_CONTACT_RECORD_CASE rows; **byte-identical pre/post-edge**.
- `dbo.sp_contact_record_event` — **NOT EXECUTED** (broken upstream — references nonexistent `nbs_odse.dbo.fn_get_value_by_cd_codeset`; see `OUT_OF_SCOPE_RTR_BUG` below).
- Edge-row landing verified directly via `SELECT type_cd, COUNT(*) FROM dbo.nbs_act_entity WHERE type_cd IN (...) GROUP BY type_cd` → 2 rows per type_cd, 6 total.

## Coverage unlocked

**0 RDB_MODERN dim/fact column unlocks at Tier 1 isolation OR in the merged sequence.**

This is a known and documented outcome — not a fixture defect. The two reasons:

1. **Event SP broken upstream.** `sp_contact_record_event` cannot run at all in baseline 6.0.18.1 (`OUT_OF_SCOPE_RTR_BUG` in `coverage_contact.md`). So the three LEFT JOINs at lines 155-157 of `069-sp_contact_record_event-001.sql` that consume these edges never execute. Even when the SP is fixed upstream, the SP's only output is a JSON projection (consumed by Kafka), not RDB_MODERN dim/fact rows.

2. **Postprocessing SPs do not traverse `nbs_act_entity`.** `sp_d_contact_record_postprocessing` and `sp_f_contact_record_case_postprocessing` read soft-ref UIDs (`CONTACT_EXPOSURE_SITE_UID`, `PROVIDER_CONTACT_INVESTIGATOR_UID`, `DISPOSITIONED_BY_UID`) directly from `nrt_contact` (hand-authored by Tier 1). They do not join `nbs_act_entity` at all. So `D_CONTACT_RECORD` (41 SP-write columns populated for v2; 8 system + 33 NULL for foundation) and `F_CONTACT_RECORD_CASE` (11/11 with sentinel-1 cross-FKs at Tier 1 isolation) are unaffected by these edges.

| Table / Column family | Pre-edge | Post-edge | Unlock? |
| --- | --- | --- | --- |
| D_CONTACT_RECORD (41 SP-write columns × 2 rows) | 41/41 v2, 8/41 foundation | 41/41 v2, 8/41 foundation | NO (unchanged) |
| F_CONTACT_RECORD_CASE (11 columns × 2 rows) | 11/11 with sentinel-1 cross-FKs | 11/11 with sentinel-1 cross-FKs | NO (unchanged) |
| `sp_contact_record_event` JSON projection (CONTACT_EXPOSURE_SITE_UID, PROVIDER_CONTACT_INVESTIGATOR_UID, DISPOSITIONED_BY_UID) | N/A — SP cannot execute | N/A — SP cannot execute | BLOCKED by upstream bug |

The PRIMARY value of this fixture is therefore:

1. **ODSE graph correctness** for the eventual RDB-vs-RDB_MODERN comparison test against MasterETL — MasterETL likely traverses these `nbs_act_entity` rows to derive analogous Contact-participant linkages on the RDB side, even though RTR currently does not reach them.

2. **Future-proofing** — when the upstream `sp_contact_record_event` bug is fixed (function aliased into NBS_ODSE or the SP body rewritten with the correct database qualifier), the SP's `#CONTACT_RECORD_INIT` projection will surface these wired entity_uids without any further fixture work. The fixture is ready for that future state.

## Coverage still LINK_REQUIRED

None for this edge type's responsibilities. The Contact subject's Tier 1 coverage report (`coverage_contact.md`) does not enumerate any LINK_REQUIRED entries that this edge type was expected to resolve at Tier 2 — the report explicitly notes (line 145) that the three `nbs_act_entity` LEFT JOINs are "moot at Tier 1 since the event SP is broken anyway."

Cross-subject keys in `F_CONTACT_RECORD_CASE` (THIRD_PARTY_ENTITY_KEY, CONTACT_KEY, SUBJECT_KEY, THIRD_PARTY_INVESTIGATION_KEY, SUBJECT_INVESTIGATION_KEY, CONTACT_INVESTIGATION_KEY, CONTACT_INTERVIEW_KEY) remain at sentinel 1 — these resolve through other paths (D_PATIENT, INVESTIGATION, NRT_INTERVIEW_KEY) at the merged sequence, not through `nbs_act_entity`. They are not this edge's responsibility.

## Columns deliberately not exercised by this edge

These belong to other Tier 2 agents and are **not** the responsibility of `contact_links.sql`:

- All `participation` and `act_relationship` rows for Contact (none currently scheduled — the Contact subject does not have outstanding `participation` or `act_relationship` LINK_REQUIRED entries at Tier 2).

## Gaps reported

### OUT_OF_SCOPE_RTR_BUG

- **`sp_contact_record_event` references nonexistent function `nbs_odse.dbo.fn_get_value_by_cd_codeset`.** The function actually lives in `RDB_MODERN.dbo.fn_get_value_by_cd_codeset` (verified across all 5 baseline DBs; only `RDB_MODERN` has it). The SP at line 69 of `069-sp_contact_record_event-001.sql` wraps the call in a CASE gated by `CONTACT_STATUS is not null and CONTACT_STATUS != ''`, but SQL Server resolves object names at parse time for the entire SELECT — leaving CONTACT_STATUS NULL on every ct_contact row does NOT short-circuit the parser error. The event SP cannot run successfully against any input until either:
  - the function is added to `NBS_ODSE` (or aliased via a synonym), or
  - the SP body is rewritten to use the correct database qualifier.
  - This was originally documented in `coverage_contact.md` (Tier 1) as `OUT_OF_SCOPE_RTR_BUG` and is repeated here because it directly governs whether this edge fixture's tail-EXEC can run. **The fixture deliberately omits a tail-EXEC** because of this bug; running `sp_contact_record_event` fails immediately on parse. Per STRATEGY.md "RTR transformation chain", the event SP is a contract test, not a staging populator; its failure does not gate fixture verification.

### SRTE_GAP

- **`SiteOfExposure`, `InvestgrOfContact`, `DispoInvestgrOfConRec` are MISSING_FROM_SRTE.** None of these three `type_cd` values appears in any baseline SRTE code set (verified in Phase B; rows 131-133 and 369-371 of `catalog/edge_types.md`). RTR's `sp_contact_record_event` nonetheless filters on the literal values directly at lines 155-157 of `069-sp_contact_record_event-001.sql`. Per the Phase B "MISSING_FROM_SRTE used anyway" policy, we author the rows with the literal `type_cd` values. Recommendation: either upstream RTR adds parent rows to a code set (e.g., `PAR_TYPE`), or the `MISSING_FROM_SRTE` annotation is preserved indefinitely as expected behavior. No fix required from fixture authors.

### FOUNDATION_GAP

None. Foundation provides `@dbo_Act_contact_uid (20000170)` (class_cd `ENC`), `@dbo_Entity_place_uid (20000030)`, and `@dbo_Entity_provider_uid (20000010)` (class_cd `PSN`). Tier 1 fixtures provide v2 Contact (20120010) and v2 Provider (20010010).

### OUT_OF_SCOPE

- **No v2 Place variant.** Place Tier 1 does not author a v2 Place; both `SiteOfExposure` rows wire to the foundation Place (20000030). This is a v1 simplification per the per-edge prompt and STRATEGY.md "one canonical Place variant per tier" — not a gap requiring action.

- **Same Provider for InvestgrOfContact and DispoInvestgrOfConRec.** In production these could be distinct providers per Contact record. v1 uses one Provider per tier (foundation Provider 20000010, v2 Provider 20010010) for both roles. Not a gap requiring action; could be expanded in a follow-on phase.

## Decisions made under prompt ambiguity

- **No tail-EXEC of `sp_contact_record_event` in the fixture file.** Because the SP is broken upstream (parse-time failure on every input), invoking it would either (a) produce a parser error in the fixture's apply log (noisy and unhelpful) or (b) require wrapping in `BEGIN TRY / END TRY` (out of fixture-style discipline). We omit the tail-EXEC entirely and document the reason in a comment block at the bottom of the fixture file. Verification is via direct `SELECT` against `dbo.nbs_act_entity`, which is reproducible and noise-free.

- **`SiteOfExposure` v2 row wires to foundation Place, not a v2 Place.** Place Tier 1 authors only one Place (the foundation one). Per the per-edge prompt: *"v2 Contact (20120010) ↔ Foundation Place (20000030) (Contact Tier 1 has only one v2 Contact; place doesn't have a v2 distinct enough to warrant separate pairing for v1.)"* — we follow that.

- **Same Provider for both InvestgrOfContact and DispoInvestgrOfConRec edges.** Per the per-edge prompt: *"could be a different provider than InvestgrOfContact in production; v1 uses same Provider for simplicity."*

- **Did not allocate UIDs from block 21010006-21010999.** Only 6 surrogate UIDs needed (21010000-21010005). Remaining 994 UIDs reserved for future amendments — no functional reason to allocate now.

- **`record_status_cd='ACTIVE'`** chosen for shape parity with sibling `nbs_act_entity` Tier 2 fixtures (vaccination_links / interview_links / phc_roles_nae). The LEFT JOINs at lines 155-157 of `069-sp_contact_record_event-001.sql` have no `record_status_cd` predicate, so any value would satisfy the joins; we use the canonical `'ACTIVE'`.

- **`entity_version_ctrl_nbr = 1`** by NBS convention (smallint; versioning starts at 1 for new rows). Identical to siblings.

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

# Foundation + relevant Tier 1 fixtures
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i fixtures/00_foundation/00_foundation.sql
for f in patient provider organization place investigation interview contact; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains in dependency order (skip sp_contact_record_event — broken)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "
  EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010';
  EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0;
  EXEC dbo.sp_organization_event @org_uids = N'20000020,20030010';
  EXEC dbo.sp_nrt_organization_postprocessing @id_list = N'20000020,20030010', @debug = 0;
  EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010,20020020';
  EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010,20020020', @debug = 0;
  EXEC dbo.sp_place_event @id_list = N'20000030';
  EXEC dbo.sp_nrt_place_postprocessing @id_list = N'20000030', @debug = 0;
  EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010';
  EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0;
  EXEC dbo.sp_d_contact_record_postprocessing @contact_uids = N'20000170,20120010', @debug = 0;
  EXEC dbo.sp_f_contact_record_case_postprocessing @contact_uids = N'20000170,20120010', @debug = 0;"

# Apply edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i fixtures/20_links/contact_links.sql

# Verify (no tail-EXEC because sp_contact_record_event is broken upstream)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_ODSE -Q "
  SELECT type_cd, COUNT(*) FROM dbo.nbs_act_entity
  WHERE type_cd IN ('SiteOfExposure','InvestgrOfContact','DispoInvestgrOfConRec')
  GROUP BY type_cd;"
```

Expected: 3 type_cd values, 2 rows each (6 total).

## Confirmation

All three deliverables exist:

- `fixtures/20_links/contact_links.sql` (6 nbs_act_entity rows; no tail-EXEC due to upstream bug).
- `coverage/coverage_contact_links.md` (this file).
- `catalog/uid_ranges.md` updated with Tier 2 — `contact_links` block.
