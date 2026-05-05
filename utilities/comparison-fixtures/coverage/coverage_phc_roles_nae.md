# Coverage: phc_roles_nae (PerAsReporterOfPHC + OrgAsReporterOfPHC + HospOfADT nbs_act_entity edges)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: **21009000 - 21009999** (Tier 2, tenth agent)
- UIDs consumed: 21009000-21009005 (6 surrogate UIDs for `nbs_act_entity_uid`)
- Foundation dependencies:
  - foundation Investigation: `act_uid = public_health_case_uid = 20000100` (`@dbo_Act_investigation_uid`, class `CASE`)
  - foundation Provider: `entity_uid = person_uid = 20000010` (`@dbo_Entity_provider_uid`, class `PSN`)
  - foundation Organization: `entity_uid = organization_uid = 20000020` (`@dbo_Entity_organization_uid`, class `ORG`)
- Other-agent dependencies (Tier 1 read-only):
  - Investigation Tier 1: v2 Investigation `act_uid = 20050010` (`@dbo_Act_investigation_v2_uid`)
  - Provider Tier 1: v2 Provider `entity_uid = 20010010` (`@dbo_Entity_provider_v2_uid`)
  - Organization Tier 1: v2 Organization `entity_uid = 20030010` (`@dbo_Entity_organization_v2_uid`)
- Sibling Tier 2 agent (read-only awareness): `reporter_phc` (sixth agent, 21005000-21005999) authored complementary `participation` rows for the same source/target endpoints — see "Architectural distinction" below.
- Pre-fixture infrastructure (orchestrator-owned):
  - `dbo.RDB_DATE` populated via recursive-CTE seed (per STRATEGY.md; bypasses the `sp_get_date_dim` RTR bug in baseline 6.0.18.1).
  - `dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'` populated `dbo.CONDITION` for Hep A acute.

## Edges authored

| nbs_act_entity_uid | type_cd | act_uid (Investigation) | entity_uid | Endpoint pairing |
| --- | --- | --- | --- | --- |
| 21009000 | `PerAsReporterOfPHC` | 20000100 (foundation) | 20000010 (foundation Provider) | foundation Provider as person-reporter of foundation Investigation |
| 21009001 | `PerAsReporterOfPHC` | 20050010 (v2)         | 20010010 (v2 Provider)         | v2 Provider as person-reporter of v2 Investigation |
| 21009002 | `OrgAsReporterOfPHC` | 20000100 (foundation) | 20000020 (foundation Org)      | foundation Organization as org-reporter of foundation Investigation |
| 21009003 | `OrgAsReporterOfPHC` | 20050010 (v2)         | 20030010 (v2 Org)              | v2 Organization as org-reporter of v2 Investigation |
| 21009004 | `HospOfADT`          | 20000100 (foundation) | 20000020 (foundation Org)      | foundation Organization as hospital of foundation Investigation |
| 21009005 | `HospOfADT`          | 20050010 (v2)         | 20030010 (v2 Org)              | v2 Organization as hospital of v2 Investigation |

**Total: 6 rows** (2 per type_cd; foundation+v2 pairs). All rows write
`record_status_cd='ACTIVE'`, `entity_version_ctrl_nbr=1`,
`add_user_id=last_chg_user_id=10009282` (superuser) — consistent with
sibling `vaccination_links` and `interview_links` `nbs_act_entity`
fixtures.

The fixture writes **0 rows** to RDB_MODERN dim/fact tables and **0 rows**
to RDB_MODERN nrt_* staging tables. Tail-EXEC is `sp_investigation_event`
for verification of the JSON projection.

## SPs verified

- `dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'` —
  exit code 0 / 2 rows projected. **The CASE-pivot subquery
  `investigation_act_entity` (lines 909-934) now resolves all 3
  in-scope projection columns for both Investigations**:

  ```text
  -- Direct query mirroring the SP's CASE-pivot subquery (lines 909-934):
  public_health_case_uid | person_as_reporter_uid | hospital_uid | org_as_reporter_uid
  -----------------------+------------------------+--------------+--------------------
                20000100 |               20000010 |     20000020 |            20000020
                20050010 |               20010010 |     20030010 |            20030010
  ```

  These columns are projected by the outer SELECT at lines 137/140/141/171
  of `056-sp_investigation_event-001.sql` into the
  `Investigation_Dim_Event` / JSON output payload.

- (No re-run of `sp_nrt_investigation_postprocessing` — the SP reads
  only `nrt_investigation`, never `nbs_act_entity`; INVESTIGATION
  dimension row count and column values are unchanged at 4 rows
  pre/post.)

## Architectural distinction from `reporter_phc` (NOT a duplicate)

The `reporter_phc` agent (sixth Tier 2, 21005000-21005999) authored
**4 rows in `dbo.participation`** for `PerAsReporterOfPHC` +
`OrgAsReporterOfPHC` linking the same Provider/Organization/Investigation
endpoints. THIS agent authors **6 complementary rows in
`dbo.nbs_act_entity`** for the same endpoints (plus 2 additional
`HospOfADT` rows that have no `participation` cousin). Both fixtures
are required for full coverage, and authoring rows in only one of the
two tables would leave half the coverage gap unresolved:

| Row family | Table | Source/target endpoints | What it unblocks |
| --- | --- | --- | --- |
| `PerAsReporterOfPHC` participation (reporter_phc) | `dbo.participation` | foundation/v2 Inv → foundation/v2 Provider | `sp_investigation_event` `person_participations` JSON branch (lines ~339-360); `sp_public_health_case_fact_datamart_event/_update` filtered by `TYPE_CD IN (...)` (072 line 1897-1903 / 073 line 105-110) populating `F_PAGE_CASE.REPORTER_NAME / REPORTER_PHONE` at Merge step 9. |
| `PerAsReporterOfPHC` nbs_act_entity (this agent) | `dbo.nbs_act_entity` | foundation/v2 Inv → foundation/v2 Provider | `sp_investigation_event` CASE-pivot subquery `investigation_act_entity` at line 913 → projects `person_as_reporter_uid` (consumed downstream at Merge step 9 by `sp_inv_summary_datamart_postprocessing`). |
| `OrgAsReporterOfPHC` participation (reporter_phc) | `dbo.participation` | foundation/v2 Inv → foundation/v2 Org | `organization_participations` JSON branch + datamart `F_PAGE_CASE.ORGANIZATION_NAME` at Merge step 9. |
| `OrgAsReporterOfPHC` nbs_act_entity (this agent) | `dbo.nbs_act_entity` | foundation/v2 Inv → foundation/v2 Org | CASE-pivot at line 932 → projects `org_as_reporter_uid` (consumed downstream at Merge step 9 by `F_PAGE_CASE`). |
| `HospOfADT` nbs_act_entity (this agent only) | `dbo.nbs_act_entity` | foundation/v2 Inv → foundation/v2 Org | CASE-pivot at line 914 → projects `hospital_uid` (consumed downstream at Merge step 9 by `F_PAGE_CASE` and Hepatitis_Datamart). `HospOfADT` has no participation cousin in `reporter_phc`'s scope. |

This dual-table design is intentional in the ODSE schema: each row in
one connective table does NOT imply a row in the other. The
investigation_event SP queries `participation` directly (for the
`person_participations` / `organization_participations` JSON branches)
AND `nbs_act_entity` directly (for the `investigation_act_entity`
CASE-pivot subquery). To populate BOTH JSON branches AND the
per-Investigation reporter UID columns, BOTH tables must have the
matching rows. The `coverage_reporter_phc.md` "Coverage still
LINK_REQUIRED" section explicitly defers the `nbs_act_entity` rows to
"a separate Tier 2 agent" — this agent is that follow-up.

## Coverage assessment — honest reporting

Like sibling `interview_links` (and unlike `vaccination_links`), this
edge is a **JSON-projection / shape-consistency unlock at Tier 1
isolation, NOT an RDB_MODERN dim/fact column unlock.** The
investigation_event SP's CASE-pivot subquery is wrapped in a `LEFT JOIN
... ON investigation_act_entity.nac_page_case_uid = results.public_health_case_uid`
at line 909 — so `sp_investigation_event` returns rows for both
Investigations regardless of these edges. Pre-edge, the projection
columns `person_as_reporter_uid` / `hospital_uid` /
`org_as_reporter_uid` (and the 17 deferred Tier 3 `*_of_phc_uid`
columns) all project as NULL on every row. Post-edge, the 3 in-scope
columns surface the wired entity_uids.

What this edge **does** unlock at Tier 1 isolation:

| SP / projection | JOIN site | Effect of edge | RDB_MODERN dim/fact column flipped at Tier 1 isolation? |
| --- | --- | --- | --- |
| `sp_investigation_event` `investigation_act_entity` CASE pivot (lines 909-934) | LEFT JOIN on `nbs_odse.dbo.nbs_act_entity` aggregated by `act_uid`, using `MAX(CASE WHEN type_cd = '<literal>' THEN entity_uid END)` | Each of the 3 in-scope columns now resolves to the wired entity_uid (verified above for both Investigations). | **No** at the INVESTIGATION dimension level — the postprocessing SP reads `nrt_investigation` (hand-authored by Tier 1), not `nbs_act_entity`. The columns are visible in the SP's JSON projection / `Investigation_Dim_Event` output, which is consumed by Kafka in production but not by our local fixture flow. |
| `sp_inv_summary_datamart_postprocessing` (Merge step 9, datamart-side) | Reads `person_as_reporter_uid` from staging derived by event-SP path | Datamart-side reporter columns (e.g., `INV_SUMMARY.REPORTER_*`) can resolve | **Out of scope** for this Tier 2 agent's verification. Lands at Merge step 9. |
| `F_PAGE_CASE` postprocessing (Merge step 9, datamart-side) | Reads `hospital_uid` and `org_as_reporter_uid` from same path | `F_PAGE_CASE.HOSPITAL_*` / `F_PAGE_CASE.ORGANIZATION_*` columns can resolve | **Out of scope** for this Tier 2 agent's verification. Lands at Merge step 9. |
| `Hepatitis_Datamart` postprocessing (Merge step 9, datamart-side) | Reads `hospital_uid` from staging | Hepatitis-specific hospital-context columns can resolve | **Out of scope** — Merge step 9. |

**SQL Server collation note (verified, same convention as
reporter_phc):** Default collation `SQL_Latin1_General_CP1_CI_AS` is
case-insensitive, so the literal values `'PerAsReporterOfPHC'` /
`'OrgAsReporterOfPHC'` / `'HospOfADT'` (mixed case, used by both event
SP and downstream consumers) match consistently across all SP filter
sites.

## Coverage unlocked (at Tier 1 isolation)

**0 RDB_MODERN dim/fact columns flipped from NULL/sentinel-1 to real values.**

This is the honest result, fully consistent with `interview_links`'s
precedent. The 6 nbs_act_entity rows' value lands in RDB_MODERN at
Merge contract step 9 (Datamart SPs:
`sp_inv_summary_datamart_postprocessing`,
`sp_public_health_case_fact_datamart_event/_update`,
`Hepatitis_Datamart`, plus any other condition-specific datamarts
that consume `INVESTIGATION` reporter/hospital UIDs), not at any
Tier 1 chain re-run.

**3 JSON-projection / event-SP-output columns flipped from NULL to
populated** for each of 2 Investigation rows (6 column-row cells total):

| Column | foundation Inv (20000100) | v2 Inv (20050010) |
| --- | --- | --- |
| `person_as_reporter_uid` | NULL → 20000010 (foundation Provider) | NULL → 20010010 (v2 Provider) |
| `hospital_uid`           | NULL → 20000020 (foundation Org)      | NULL → 20030010 (v2 Org) |
| `org_as_reporter_uid`    | NULL → 20000020 (foundation Org)      | NULL → 20030010 (v2 Org) |

These are the in-scope 3 columns out of the 20-column CASE pivot at
lines 909-934. The 17 deferred columns (`ordering_facility_uid`,
`ca_supervisor_of_phc_uid`, `closure_investgr_of_phc_uid`,
`dispo_fld_fupinvestgr_of_phc_uid`, `fld_fup_investgr_of_phc_uid`,
`fld_fup_prov_of_phc_uid`, `fld_fup_supervisor_of_phc_uid`,
`init_fld_fup_investgr_of_phc_uid`, `init_fup_investgr_of_phc_uid`,
`init_interviewer_of_phc_uid`, `interviewer_of_phc_uid`,
`surv_investgr_of_phc_uid`, `fld_fup_facility_of_phc_uid`,
`org_as_hospital_of_delivery_uid`, `per_as_provider_of_delivery_uid`,
`per_as_provider_of_obgyn_uid`, `per_as_provider_of_pediatrics_uid`)
remain NULL — see "Coverage still LINK_REQUIRED" below.

Indirect-but-real values delivered by this fixture:

1. **ODSE graph correctness** — MasterETL traverses `nbs_act_entity`
   directly to populate analogous reporter/hospital-context columns
   on the RDB side. Without these rows, MasterETL's output would
   diverge from RTR's downstream Datamart-SP output, contaminating
   the eventual RDB-vs-RDB_MODERN comparison test. With these rows,
   the ODSE graph carries Provider-as-reporter, Organization-as-reporter,
   and Organization-as-hospital context that both pipelines can read.
2. **Event-SP JSON-projection coverage** — `sp_investigation_event`
   JSON output now projects the 3 in-scope nested columns inside the
   `investigation_act_entity` block. This makes the event-SP output
   structurally complete (matching what production CDC-Debezium-Kafka
   would observe) for the 3 v1 roles.
3. **Pre-requisite for downstream Datamart agents** — any future
   agent (Tier 3 or Datamart-coverage) that needs the nbs_act_entity
   rows for these 3 type_cds to be present can rely on them being
   authored here.

## Coverage still LINK_REQUIRED

Resolved by this edge (combined with `reporter_phc`'s participation
rows):

- `coverage_investigation.md` LINK_REQUIRED #7
  (`nbs_act_entity type_cd='HospOfADT' linking foundation Organization
  → foundation/v2 Investigation — populates nrt_investigation.hospital_uid
  and downstream F_PAGE_CASE / Hepatitis_Datamart`):
  **resolved at the JSON-projection level** (the
  `nrt_investigation.hospital_uid` STAGING column is hand-authored by
  Tier 1 Investigation; this edge resolves the EVENT-SP's CASE-pivot
  projection of `hospital_uid`, not the staging-table column. The
  downstream `F_PAGE_CASE` consumer resolves at Merge step 9 — out of
  scope here).
- `coverage_investigation.md` LINK_REQUIRED #11
  (`nbs_act_entity type_cd='OrgAsReporterOfPHC' linking Organization →
  Investigation — populates org-side *_of_phc_uid columns`):
  **resolved at the JSON-projection level for `OrgAsReporterOfPHC`**.
  The `FldFupFacilityOfPHC` and `OrgAsHospitalOfDelivery` slices of the
  same LINK_REQUIRED entry are NOT resolved here (deferred to Tier 3).
- `coverage_investigation.md` columns table at lines 152-153
  (`person_as_reporter_uid` ← `nbs_act_entity 'PerAsReporterOfPHC'`;
  `hospital_uid` ← `nbs_act_entity 'HospOfADT'`):
  **resolved at the JSON-projection level**. The columns flip from
  NULL to populated in the `Investigation_Dim_Event` / event-SP JSON
  output. They do NOT flip in `INVESTIGATION` dim because the
  postprocessing SP does not consume the event-SP's output (it reads
  `nrt_investigation` directly, hand-authored by Tier 1).

Not resolved by this edge (deferred to Tier 3 — same family of CASE
pivots):

- `coverage_investigation.md` LINK_REQUIRED #8
  (`nbs_act_entity type_cd='OrgAsClinicOfPHC' → ordering_facility_uid`).
  Tier 3 deferred (MISSING_FROM_SRTE).
- `coverage_investigation.md` LINK_REQUIRED #9
  (`nbs_act_entity type_cd='InterviewerOfPHC' / 'InitInterviewerOfPHC'`
  → respective `*_of_phc_uid` columns). Tier 3 deferred
  (MISSING_FROM_SRTE).
- `coverage_investigation.md` LINK_REQUIRED #10
  (`nbs_act_entity type_cd='SurvInvestgrOfPHC' / 'CASupervisorOfPHC' /
  'ClosureInvestgrOfPHC' / 'DispoFldFupInvestgrOfPHC' /
  'FldFupInvestgrOfPHC' / 'FldFupProvOfPHC' / 'FldFupSupervisorOfPHC' /
  'InitFldFupInvestgrOfPHC' / 'InitFupInvestgrOfPHC'` →
  corresponding `*_of_phc_uid` columns). Tier 3 deferred (all 9
  MISSING_FROM_SRTE; same Provider/Investigation pair could be
  bundled in a single Tier 3 agent per the LINK_REQUIRED entry's
  guidance).
- `coverage_investigation.md` LINK_REQUIRED #11 partial
  (`nbs_act_entity type_cd='FldFupFacilityOfPHC' /
  'OrgAsHospitalOfDelivery'`). Tier 3 deferred.
- `coverage_investigation.md` LINK_REQUIRED #12
  (`nbs_act_entity type_cd='PerAsProviderOfDelivery' /
  'PerAsProviderOfOBGYN' / 'PerAsProvideroOfPediatrics'`, typo
  preserved at SP line 931). Tier 3 deferred.

Not resolved by this edge (waiting on other Tier 2 agents — already
authored):

- N/A. The `reporter_phc` agent (sixth Tier 2, 21005000-21005999)
  already authored the `participation`-side cousin rows for the
  `PerAsReporterOfPHC` / `OrgAsReporterOfPHC` family. Those rows
  unblock the `person_participations` / `organization_participations`
  JSON branches and the datamart-side `WHERE PAR.TYPE_CD IN (...)`
  filter; this agent's `nbs_act_entity` rows unblock the
  `investigation_act_entity` CASE-pivot subquery. The two agents are
  complementary, not redundant.

## OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP

- **OUT_OF_SCOPE: `nrt_investigation.person_as_reporter_uid` /
  `org_as_reporter_uid` / `hospital_uid` STAGING-TABLE columns.**
  The `nrt_investigation` staging table is hand-authored by Tier 1
  Investigation (per the v1 fixture-authoring shortcut documented in
  STRATEGY.md "RTR transformation chain (verification recipe)" — we
  bypass CDC and write nrt_* rows directly). The investigation_event
  SP's CASE-pivot output is NOT written back to `nrt_investigation`
  by any SP we control: in production, the event SP's JSON projection
  flows out via Kafka and the kafka-connect JDBC sink writes to
  `nrt_investigation`. For our fixture flow, those staging columns
  remain whatever Tier 1 hand-authored them as. So the edge unblocks
  the EVENT SP's projection (the JSON output), but does NOT
  retroactively populate the `nrt_investigation` staging columns.
  Citation: STRATEGY.md "RTR transformation chain (verification
  recipe)"; `056-sp_investigation_event-001.sql:909-934` (CASE pivot
  with no INSERT INTO `nrt_investigation`); Tier 1
  `coverage_investigation.md` line 247 (cross-subject UID columns
  left NULL).
- **OUT_OF_SCOPE: `INVESTIGATION` dimension columns sourced from
  `nbs_act_entity`.** Verified: `sp_nrt_investigation_postprocessing`
  reads only `nrt_investigation` (via `WHERE
  investigation_uid IN (SELECT value FROM STRING_SPLIT(@id_list, ','))`)
  and never traverses `nbs_act_entity`. So no INVESTIGATION column
  flips at Tier 1 isolation regardless of these edges.
- **OUT_OF_SCOPE: `F_PAGE_CASE.HOSPITAL_*` / `ORGANIZATION_NAME` /
  `REPORTER_*` columns.** These flip at Merge step 9 by datamart SPs
  (`sp_public_health_case_fact_datamart_event/_update`,
  `sp_inv_summary_datamart_postprocessing`, `Hepatitis_Datamart`,
  etc.) — none of which is in scope for this Tier 2 agent's
  verification.
- **No SRTE_GAP.** All three type_cds (`PerAsReporterOfPHC`,
  `OrgAsReporterOfPHC`, `HospOfADT`) are present in baseline
  `nbs_srte.dbo.Participation_type` per Phase B's
  `catalog/edge_types.md` (lines 83, 84, 86). The 17 deferred
  Tier 3 `*OfPHC` codes are MISSING_FROM_SRTE — but those are not
  authored here.
- **No FOUNDATION_GAP.** Foundation Investigation (act_uid 20000100,
  class `CASE`), foundation Provider (entity_uid 20000010, class
  `PSN`), foundation Organization (entity_uid 20000020, class `ORG`)
  match the CASE-pivot endpoint constraints exactly. Same applies for
  v2 Investigation (20050010), v2 Provider (20010010), and v2
  Organization (20030010).
- **No new LINK_REQUIRED found.** The CASE-pivot subquery at lines
  909-934 reads only `nbs_odse.dbo.nbs_act_entity` directly grouped
  by `act_uid` (no join through other connective tables).

## Decisions made under prompt ambiguity

1. **6 rows authored, not 60.** The per-edge prompt explicitly
   specifies 6 UIDs (21009000-21009005) and 6 endpoint pairs (2 per
   type_cd × 3 type_cds). The other 17 CASE-pivot roles in the same
   subquery (CASupervisorOfPHC, FldFupInvestgrOfPHC, etc.) are
   explicitly deferred to Tier 3, not bundled here.
2. **Mixed-case literals chosen for all three `type_cd` values
   (`'PerAsReporterOfPHC'`, `'OrgAsReporterOfPHC'`, `'HospOfADT'`).**
   The SP filter sites in 056 (event SP) all use mixed case —
   verified by direct read of lines 913, 914, 932. Default collation
   `SQL_Latin1_General_CP1_CI_AS` is case-insensitive, so either
   choice works, but mixed case mirrors NBS production data
   conventions and the foundation/Tier 1 fixture conventions.
3. **`record_status_cd = N'ACTIVE'` chosen for shape parity.** The
   CASE-pivot subquery at lines 909-934 has no
   `record_status_cd` predicate (it groups all rows by `act_uid`
   regardless of status). However, downstream consumers at Merge
   step 9 (datamart SPs) DO filter on `record_status_cd='ACTIVE'`
   for sibling participation rows — keeping shape parity with the
   `reporter_phc` agent ensures nbs_act_entity rows authored here are
   not silently filtered out by any future SP that inherits the
   datamart filter convention.
4. **Same Org serves as both Reporter and Hospital.** The per-edge
   prompt explicitly notes this is "common in production data; v1
   simplification". Both edges 3+5 (foundation) and 4+6 (v2) wire to
   the same Org entity_uid. Future Tier 3 amendments can split these
   into distinct entities if datamart coverage requires it.
5. **6 surrogate UIDs allocated (21009000-21009005), not the full
   block.** The remaining 21009006-21009999 (994 UIDs) are reserved
   for future amendments — most likely Tier 3 expansion of the other
   17 *OfPHC roles that share the same Provider/Investigation /
   Organization/Investigation endpoints. Bundling all 23 *OfPHC roles
   under a single Tier 3 agent within this block is a reasonable
   future plan per `coverage_investigation.md` LINK_REQUIRED #10's
   guidance.
6. **`HospOfADT` was kept in v1 alongside the two reporter codes.**
   The per-edge prompt explicitly enumerates HospOfADT as a "high-value"
   v1 role. This decision is grounded in:
   - HospOfADT is **present in baseline SRTE PAR_TYPE** (NOT
     MISSING_FROM_SRTE — verified per catalog line 86), unlike the
     17 deferred roles.
   - HospOfADT surfaces in `F_PAGE_CASE` at Merge step 9 (catalog
     line 86 used-by list).
   - HospOfADT is the only ORG-targeted code in the CASE pivot
     besides OrgAsReporterOfPHC, FldFupFacilityOfPHC, and
     OrgAsHospitalOfDelivery — and the latter two are
     MISSING_FROM_SRTE.
7. **Tail-EXEC is `sp_investigation_event` only**, NOT
   `sp_nrt_investigation_postprocessing`. Consistent with sibling
   `reporter_phc` and `interview_links` precedent: the postprocessing
   SP reads from `nrt_investigation` staging hand-authored by Tier 1
   and does not traverse `nbs_act_entity`, so a re-run would be
   wasted work. The event SP re-run is a SP-callability check (no
   errors) and a coverage spot-check (verifies the rows surface in
   the JSON projection's CASE pivot).
8. **`nbs_act_entity` rows only — no participation rows authored
   here.** The participation cousins for `PerAsReporterOfPHC` /
   `OrgAsReporterOfPHC` are authored by the `reporter_phc` agent
   (sixth Tier 2). Adding participation rows here would duplicate
   that agent's outputs and violate the "don't modify other agents'
   outputs" rule. `HospOfADT` has no participation cousin in the
   `reporter_phc` agent's scope (and no other Tier 2 agent has
   authored a `HospOfADT` participation row); future Tier 3 work
   could add a participation row if a datamart SP filter on
   `participation` for `HospOfADT` is identified.

## Confirmation deliverables exist

- [x] `fixtures/20_links/phc_roles_nae.sql` — 6-row INSERT wrapped in
      `SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF`, plus
      tail-EXEC of `sp_investigation_event`.
- [x] `coverage/coverage_phc_roles_nae.md` — this file.
- [x] `catalog/uid_ranges.md` — Tier 2 section extended with the
      phc_roles_nae agent's block (21009000-21009999) and detail
      sub-section.
