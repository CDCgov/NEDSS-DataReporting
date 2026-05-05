# Tier 1 — Investigation

You are a Tier 1 sub-agent. Your subject is **Investigation**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

## Subject identity

- **Subject name:** investigation
- **Foundation row:** `@dbo_Act_investigation_uid = 20000100`
  (`act.act_uid`, `public_health_case.public_health_case_uid`); class
  `CASE`, mood `EVN`. Foundation has `case_class_cd=NULL` and
  `cd_system_cd=NULL` (Tier 1 deferred — see `coverage_foundation.md`).
- **No internal locators.** Investigation is an Act, not an Entity —
  locators belong to Entities (Patient, Provider, Org).
- **Your UID block:** `20050000–20059999` per `catalog/uid_ranges.md`.
  Update the registry with your final allocation.

## SP chain

- Event SP: `dbo.sp_investigation_event @phc_id_list nvarchar(max)`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/056-sp_investigation_event-001.sql`
  - **Param name is `@phc_id_list` (Public Health Case UIDs).** Different
    from Provider's `@user_id_list`, Org's `@org_id_list`, Place's
    `@id_list`.
- Postprocessing SP: `dbo.sp_nrt_investigation_postprocessing @id_list, @debug = 0`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/005-sp_nrt_investigation_postprocessing-001.sql`
- **NOT in scope:**
  - `sp_sld_investigation_repeat_postprocessing @phc_id_list` (file 010) —
    handles repeating-block dimensions (`D_INVESTIGATION_REPEAT`,
    244 cols, mostly dynamic). Requires repeating-block
    `act_relationship`/`participation` rows. Tier 2/Tier 3 territory.
  - `sp_dyn_dm_invest_form_postprocessing` (115) and
    `sp_dyn_dm_invest_clear_postprocessing` (250) — dynamic-target
    datamart SPs. Tier 2/Tier 3.
  - `sp_public_health_case_fact_datamart_event` (072) and
    `sp_public_health_case_fact_datamart_update` (073) — datamart-side
    fact assembly. They read PARTICIPATION rows that Tier 2 will write.

  Do NOT invoke any of these. Document expected Tier 2/3 wiring as
  `LINK_REQUIRED` in coverage.

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md` and live schema:

- `dbo.INVESTIGATION` — primary write target. **Live: 71 cols**
  (catalog says 72; minor drift). Verify live count first.
- `dbo.confirmation_method` — confirmation-method dimension. The
  postprocessing SP allocates surrogate keys for new confirmation methods
  (lines 802–855). May or may not insert depending on whether your
  fixture introduces a new value not present in baseline.
- `dbo.CONFIRMATION_METHOD_GROUP` — link table from INVESTIGATION_KEY
  to CONFIRMATION_METHOD_KEY (lines 855+).
- `dbo.nrt_investigation` — synthetic staging row(s) you write directly.
- `dbo.nrt_investigation_key` — surrogate-key store; **do not hand-write**.
- `dbo.nrt_confirmation_method_key` — surrogate-key store; **do not
  hand-write**.

## Cross-subject dependencies — read carefully

The Investigation event SP references `act_relationship`, `participation`,
and `nbs_act_entity` **~20 times**. It expects:

- A `participation` row of `type_cd='SubjOfPHC'` linking the foundation
  Patient → this Investigation (Patient as subject of PHC).
- A `participation` row for `PerAsReporterOfPHC` / `OrgAsReporterOfPHC`
  / `PhysicianOfPHC` / `InvestgrOfPHC` / etc. — most of these are
  flagged as `MISSING_FROM_SRTE` in `catalog/edge_types.md`, but they
  are still RTR-filtered codes. The SP filters on these literals
  regardless of SRTE presence; the codes work as data even if no SRTE
  parent row exists.
- An `act_relationship` row for `Notification` / `LabReport` /
  `MorbReport` / `TreatmentToPHC` linking those Acts → this
  Investigation. Source: `catalog/edge_types.md`.

**These are Tier 2 rows. Do NOT author them in your fixture.** That
means the Investigation event SP's JSON projection will have NULL/empty
arrays for participations and act_relationships. `INVESTIGATION` columns
that depend on those joins (e.g., `PATIENT_NAME`,
`PHYSICIAN_OF_RECORD_NAME`, `REPORTER_NAME`, `INVESTIGATOR_NAME`,
`NOTIFICATION_*`, datamart-side fields) **will be NULL on the foundation
and v2 Investigation rows** at Tier 1.

Document each such NULL column as `LINK_REQUIRED: <participation/edge
type> needed by Tier 2 to populate <INVESTIGATION column>`. This is
the expected outcome — Investigation has the most LINK_REQUIRED entries
of any Tier 1 subject. Do not invent placeholder rows.

## Variant strategy (apply the template's two-variant pattern)

- **Foundation Investigation enrichment**: hang additive child rows off
  `@dbo_Act_investigation_uid = 20000100`. Candidates:
  - Additional `act_id` rows (the Investigation has none — `act_id` is
    keyed on `act_uid`).
  - Additional `case_management` data if the SP reads it (check the
    SP body).
  - LDF rows (NBS_LDF data) if relevant — verify against the SP body.
  - Leave `case_class_cd`, `cd_system_cd`, `condition_cd`, etc. NULL on
    the foundation Investigation. The SP's null-handling path will be
    exercised.
- **v2 Investigation**: a separate fully-attributed Investigation in
  your block (e.g., UID 20050010 for the Act/PHC). Set every column
  the postprocessing SP populates from `nrt_investigation` directly:
  `case_class_cd`, `cd_system_cd`, `condition_cd`, `mmwr_week`,
  `mmwr_year`, `outbreak_*`, `outcome_*`, `disease_imported_cd`,
  hospitalized_*, etc. Use this to exercise the populated path for
  every column the SP writes from staging-table data alone (without
  cross-subject joins).

The two-variant pattern still applies. Pick **one condition** for v2
(e.g., a Hepatitis condition code, or whichever is most common in
baseline SRTE) — `STRATEGY.md` notes that v1 of this project uses one
canonical condition per family; per-condition fan-out is Phase 2.

## condition_cd / cd_system_cd

`public_health_case.condition_cd` should be a real condition code from
SRTE. Verify:

```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_SRTE \
  -Q "SET NOCOUNT ON; SELECT TOP 5 condition_cd, condition_short_nm
      FROM dbo.condition_code WHERE family_cd LIKE '%HEPATITIS%' ORDER BY condition_cd"
```

Pick a code that exists. Cite condition_cd, family_cd, etc. in SQL
comments above the row. `cd_system_cd` is typically `'NND'` or
`'PHCCODE'` — verify against `code_value_general` or via the SP's join.

## Forbidden (inherited from template, repeated for clarity)

- **No cross-subject `act_relationship`, `participation`, or
  `nbs_act_entity` rows.** This is especially load-bearing for
  Investigation. Even if your row references foundation Patient/Provider
  via UID, do not author the connective-table edge — Tier 2 will. If
  your variant strategy *requires* the edge to demonstrate a column,
  promote it to a `LINK_REQUIRED` finding instead.
- No SRTE writes.
- **No UPDATE/DELETE against any foundation row.** Even
  `case_class_cd` and `cd_system_cd`, which `coverage_foundation.md`
  flags as Tier-1-deferred — populate on v2 only.
- Do not write `nrt_investigation_key` or `nrt_confirmation_method_key`.
- Do not invoke the four out-of-scope SPs listed above.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/investigation.sql

# event SP — @phc_id_list (NOT @id_list / @user_id_list)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"

# postprocessing SP
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.INVESTIGATION WHERE CASE_UID IN (20000100, 20050010)" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape. Report
`<populated>/<live_INVESTIGATION_count>`. Expect a **non-trivial number
of LINK_REQUIRED columns** — that's expected for Investigation; it's
the most-connected Tier 1 subject.
