# Coverage: interview_links (IntrvwerOfInterview + IntrvweeOfInterview + OrgAsSiteOfIntv nbs_act_entity edges)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: **21008000 - 21008999** (Tier 2, ninth agent)
- Foundation dependencies:
  - foundation Interview: `act_uid = interview_uid = 20000140` (`@dbo_Act_interview_uid`)
  - foundation Provider: `entity_uid = person_uid = 20000010` (`@dbo_Entity_provider_uid`)
  - foundation Patient: `entity_uid = person_uid = 20000000` (`@dbo_Entity_patient_uid`)
  - foundation Organization: `entity_uid = organization_uid = 20000020` (`@dbo_Entity_organization_uid`)
- Other-agent dependencies (Tier 1 read-only):
  - Interview Tier 1: v2 Interview `act_uid = interview_uid = 20090010` (`@dbo_Act_interview_v2_uid`)
  - Provider Tier 1: v2 Provider `entity_uid = person_uid = 20010010` (`@dbo_Entity_provider_v2_uid`)
  - Patient Tier 1: v2 Patient `entity_uid = person_uid = 20020010` (`@dbo_Entity_patient_v2_uid`)
  - Organization Tier 1: v2 Organization `entity_uid = organization_uid = 20030010` (`@dbo_Entity_organization_v2_uid`)
- Pre-fixture infrastructure (orchestrator-owned):
  - `dbo.RDB_DATE` populated via recursive-CTE seed (per STRATEGY.md "Note: `sp_get_date_dim` in baseline 6.0.18.1 has an RTR bug").
  - `dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'` populated `dbo.CONDITION` for Hep A acute.

## Edges authored

| Table | nbs_act_entity_uid | type_cd | act_uid (Interview) | entity_uid | Endpoint pairing |
| --- | --- | --- | --- | --- | --- |
| `nbs_odse.dbo.nbs_act_entity` | 21008000 | `IntrvwerOfInterview` | 20000140 (foundation Interview) | 20000010 (foundation Provider) | foundation Provider is the interviewer of the foundation Interview |
| `nbs_odse.dbo.nbs_act_entity` | 21008001 | `IntrvwerOfInterview` | 20090010 (v2 Interview)         | 20010010 (v2 Provider)         | v2 Provider is the interviewer of the v2 Interview |
| `nbs_odse.dbo.nbs_act_entity` | 21008002 | `IntrvweeOfInterview` | 20000140 (foundation Interview) | 20000000 (foundation Patient)  | foundation Patient is the interviewee of the foundation Interview |
| `nbs_odse.dbo.nbs_act_entity` | 21008003 | `IntrvweeOfInterview` | 20090010 (v2 Interview)         | 20020010 (v2 Patient)          | v2 Patient is the interviewee of the v2 Interview |
| `nbs_odse.dbo.nbs_act_entity` | 21008004 | `OrgAsSiteOfIntv`     | 20000140 (foundation Interview) | 20000020 (foundation Organization) | foundation Organization is the site of the foundation Interview |
| `nbs_odse.dbo.nbs_act_entity` | 21008005 | `OrgAsSiteOfIntv`     | 20090010 (v2 Interview)         | 20030010 (v2 Organization)         | v2 Organization is the site of the v2 Interview |

**Total: 6 rows**, each consuming a surrogate UID from the
21008000-21008999 block. Same `nbs_act_entity_uid bigint NOT NULL
IDENTITY` allocation pattern as the sibling `vaccination_links` agent
(eighth Tier 2 agent): the INSERT is wrapped in
`SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` to insert
explicit UIDs from this agent's block.

The fixture writes **0 rows** to RDB_MODERN dim/fact tables and
**0 rows** to RDB_MODERN nrt_* staging tables. Tail-EXEC is
`sp_interview_event` only, for SP-callability + JSON-projection
verification.

## SPs verified

- `dbo.sp_interview_event @ix_uids = N'20000140,20090010', @debug = 0`
  — exit code 0.
  - **Pre-edge**: **2 rows projected** (one per Interview UID), but
    with PROVIDER_UID, ORGANIZATION_UID, and PATIENT_UID all NULL
    on every row (the three LEFT JOINs at lines 87-95 of
    `065-sp_interview_event-001.sql` returned no matching
    `nbs_act_entity` rows). Verified directly with
    `EXEC dbo.sp_interview_event ..., @debug = 'true'`:

    | INTERVIEW_UID | INVESTIGATION_UID | PROVIDER_UID | ORGANIZATION_UID | PATIENT_UID |
    | --- | --- | --- | --- | --- |
    | 20000140 | NULL | NULL | NULL | NULL |
    | 20090010 | NULL | NULL | NULL | NULL |

  - **Post-edge**: **2 rows projected** (unchanged count), with
    PROVIDER_UID / ORGANIZATION_UID / PATIENT_UID all populated:

    | INTERVIEW_UID | INVESTIGATION_UID | PROVIDER_UID | ORGANIZATION_UID | PATIENT_UID |
    | --- | --- | --- | --- | --- |
    | 20000140 | NULL | 20000010 | 20000020 | 20000000 |
    | 20090010 | NULL | 20010010 | 20030010 | 20020010 |

    All three JSON-projection fields are now wired correctly to the
    foundation and v2 endpoints. INVESTIGATION_UID remains NULL on
    both rows (driven by the `act_relationship type_cd='IXS'` LEFT
    JOIN at lines 85-86 — that edge is `MISSING_FROM_SRTE` and
    is a separate Tier 2 deliverable, not owned by this agent).

- `dbo.sp_d_interview_postprocessing @interview_uids = N'20000140,20090010', @debug = 0`
  — exit code 0. Re-run post-edge as a sanity check; D_INTERVIEW row
  count and column values **unchanged** at 2 rows. The SP reads from
  `nrt_interview` / `nrt_interview_answer` (hand-authored by Tier 1)
  and does NOT traverse `nbs_act_entity`. **0 D_INTERVIEW columns
  flipped pre/post.** D_INTERVIEW_NOTE also unchanged at 2 rows
  (DELETE-then-INSERT on the v2 row's notes; same final state).

- `dbo.sp_f_interview_case_postprocessing @ix_uids = N'20000140,20090010', @debug = 0`
  — exit code 0. Re-run post-edge as a sanity check; F_INTERVIEW_CASE
  row count and column values **unchanged** at 2 rows. The SP reads
  from `nrt_interview` (hand-authored by Tier 1) and does NOT
  traverse `nbs_act_entity`. **0 F_INTERVIEW_CASE columns flipped
  pre/post by THIS edge.**

## Coverage assessment — honest reporting

This edge is **shape-consistency**, NOT a Tier 1-isolation
RDB_MODERN-coverage unlock. Unlike `vaccination_links` (the sibling
nbs_act_entity agent, whose `SubOfVacc` INNER JOIN at line 108 of
`071-sp_vaccination_event-001.sql` gates the entire SP and returns
0 rows pre-edge), all three Interview event-SP joins are LEFT JOIN
(lines 87-95 of `065-sp_interview_event-001.sql`):

```
LEFT JOIN NBS_ACT_ENTITY nae  ... AND nae.type_cd = 'IntrvwerOfInterview'
LEFT JOIN NBS_ACT_ENTITY nae2 ... AND nae2.type_cd = 'OrgAsSiteOfIntv'
LEFT JOIN NBS_ACT_ENTITY nae3 ... AND nae3.type_cd = 'IntrvweeOfInterview'
```

So the Interview event SP returns rows at Tier 1 isolation
regardless of these edges. Pre-edge, `#INTERVIEW_INIT` projects
PROVIDER_UID / ORGANIZATION_UID / PATIENT_UID as NULL (from the
missing nae* / nae2 / nae3 joins). Post-edge, those same JSON-
projection columns surface the wired entity_uids — but the
postprocessing SPs (`sp_d_interview_postprocessing`,
`sp_f_interview_case_postprocessing`) read from
`nrt_interview` / `nrt_interview_note` / `nrt_interview_answer`
directly and do NOT traverse `nbs_act_entity`. So
`D_INTERVIEW` (18/24 + 6 LDF OUT_OF_SCOPE), `D_INTERVIEW_NOTE`
(7/7), and `F_INTERVIEW_CASE` (8/10) column populations are
**byte-identical pre/post-edge**.

Concrete pre/post deltas:

| Artifact | Pre-edge | Post-edge | Delta |
| --- | --- | --- | --- |
| `dbo.nbs_act_entity` row count (`type_cd='IntrvwerOfInterview'`) | 0 | 2 | +2 |
| `dbo.nbs_act_entity` row count (`type_cd='IntrvweeOfInterview'`) | 0 | 2 | +2 |
| `dbo.nbs_act_entity` row count (`type_cd='OrgAsSiteOfIntv'`) | 0 | 2 | +2 |
| `sp_interview_event` rows projected (foundation Interview)      | 1 | 1 | 0 |
| `sp_interview_event` rows projected (v2 Interview)              | 1 | 1 | 0 |
| Event-SP JSON `PROVIDER_UID` (foundation row)        | NULL | 20000010 | unblocked |
| Event-SP JSON `PROVIDER_UID` (v2 row)                | NULL | 20010010 | unblocked |
| Event-SP JSON `ORGANIZATION_UID` (foundation row)    | NULL | 20000020 | unblocked |
| Event-SP JSON `ORGANIZATION_UID` (v2 row)            | NULL | 20030010 | unblocked |
| Event-SP JSON `PATIENT_UID` (foundation row)         | NULL | 20000000 | unblocked |
| Event-SP JSON `PATIENT_UID` (v2 row)                 | NULL | 20020010 | unblocked |
| Event-SP JSON `INVESTIGATION_UID` (foundation row)   | NULL | NULL | 0 (waits on `IXS` edge) |
| Event-SP JSON `INVESTIGATION_UID` (v2 row)           | NULL | NULL | 0 (waits on `IXS` edge) |
| `D_INTERVIEW` row count                              | 2 | 2 | 0 |
| `D_INTERVIEW` column values                          | 18/24 + 6 OOS | identical | 0 |
| `D_INTERVIEW_NOTE` row count                         | 2 | 2 | 0 |
| `D_INTERVIEW_NOTE` column values                     | 7/7 | identical | 0 |
| `F_INTERVIEW_CASE` row count                         | 2 | 2 | 0 |
| `F_INTERVIEW_CASE` column values                     | 8/10 | identical | 0 |

## Coverage unlocked (at Tier 1 isolation)

**Event-SP-projection unlocks: 2 rows × 3 fields = 6 JSON-projection
fields flipped from NULL to populated** (PROVIDER_UID,
ORGANIZATION_UID, PATIENT_UID for both Interview rows). This is the
form of coverage delivered by the prior shape-consistency Tier 2
agents (e.g., `physician_phc`, `reporter_phc`), not the gating-INNER
unlock delivered by `vaccination_links`.

**RDB_MODERN dim/fact column unlocks at Tier 1 isolation: 0.**
Consistent with the per-edge prompt's guidance: "this edge is
**shape-consistency**, NOT coverage-unlock. Unlike `vaccination_links`
(which had INNER filters that blocked the event SP), all three
Interview event SP joins are **LEFT JOIN** (lines 87-95 of
`065-sp_interview_event-001.sql`) — Interview event SP returns rows
at Tier 1 isolation regardless. Adding these edges populates the JSON
projection's interviewer/interviewee/site UIDs but doesn't change
RDB_MODERN dim/fact column population."

The PRIMARY value of this edge:

1. **Unblocking the Interview event SP's JSON projection** for the
   PROVIDER_UID, ORGANIZATION_UID, PATIENT_UID pivots. Kafka
   consumers in production read this projection.
2. **ODSE graph correctness for the RDB-vs-RDB_MODERN comparison
   test against MasterETL**, which traverses `nbs_act_entity`
   directly to derive analogous Interview-participant linkages on
   the RDB side. Without these edges, MasterETL's output would
   diverge from RTR's downstream output, contaminating the eventual
   RDB-vs-RDB_MODERN comparison. With these edges, the ODSE graph
   carries Interview-interviewer / -interviewee / -site context
   consistently.
3. **Datamart-step coverage value (Merge step 9).** No Datamart SP
   currently reads `nbs_act_entity` for Interview-participant pivots
   directly, but downstream Datamart SPs that read the JSON-projected
   `provider_uid` / `organization_uid` / `patient_uid` from
   `nrt_interview` (post-Kafka in production; the JSON-projection
   verification here is the closest analogue at fixture-test time)
   would resolve those linkages correctly post-edge.

## Coverage still LINK_REQUIRED

Resolved by this edge:

- `coverage_interview.md` does NOT carry a `LINK_REQUIRED` entry that
  specifically names these three edge types. The closest items in
  the Interview Tier 1 coverage report's LINK_REQUIRED section are:
  - `F_INTERVIEW_CASE.PATIENT_KEY` non-NULL coverage — driven by
    `nrt_interview.patient_uid` soft-ref (Tier 1 hand-authored on
    v2), NOT by `nbs_act_entity`. Resolved by merged-fixture
    sequence after Patient Tier 1 chain runs (i.e., already resolved
    at fixture-merge time, not by this edge).
  - `F_INTERVIEW_CASE.INVESTIGATION_KEY` non-NULL coverage — driven
    by `nrt_interview.investigation_uid` soft-ref + Investigation
    Tier 1 chain populating `dbo.INVESTIGATION`. Not driven by
    `nbs_act_entity` and not the responsibility of this agent.
  - `F_INTERVIEW_CASE.IX_INTERVIEWEE_KEY` SUBJECT-branch resolution
    — Tier 3 candidate (a v3 Interview with
    `interviewee_role_cd='SUBJECT'`), unrelated to `nbs_act_entity`.

  This edge therefore does NOT resolve any of the
  `coverage_interview.md` LINK_REQUIRED entries — those are all
  driven by `nrt_interview` soft-refs and dim-table population in
  upstream subjects, not by `nbs_act_entity`. The interview_links
  edge is purely additive shape-consistency: the JSON projection
  is unblocked but no postprocessing-SP behavior changes.

Not resolved by this edge (waiting on other Tier 2 agents or future
Tier 3 / Tier 1 amendments):

- **`#INTERVIEW_INIT.INVESTIGATION_UID`** for both Interview rows.
  This is driven by the `act_relationship` LEFT JOIN at lines 85-86
  of `065-sp_interview_event-001.sql` (`type_cd='IXS'`). `IXS` is
  `MISSING_FROM_SRTE` per Phase B's catalog (it appears in
  `BUS_OBJ_TYPE` and `INFO_SOURCE_COVID` code sets but NOT in
  `AR_TYPE`). RTR filters on the literal regardless. The Interview→
  Investigation `IXS` `act_relationship` edge would be a separate
  Tier 2 deliverable (`interview_to_investigation` or analogous edge
  agent), not owned by this agent. Currently INVESTIGATION_UID
  projects as NULL post-edge for both Interview rows.

## OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP

- **OUT_OF_SCOPE: D_INTERVIEW LDF columns (6 of 24).** Per
  `coverage_interview.md`: IX_CONTACTS_NAMED_IND, IX_900_SITE_TYPE,
  IX_INTERVENTION, IX_900_SITE_ID, IX_900_SITE_ZIP,
  CLN_CARE_STATUS_IXS are populated only via the SP's dynamic PIVOT
  against `nrt_interview_answer`, gated by `nrt_metadata_columns`
  having rows for `TABLE_NAME='D_INTERVIEW'` (empty in baseline).
  Belongs to a Tier 3 LDF-coverage fixture. Unrelated to
  `nbs_act_entity`.
- **OUT_OF_SCOPE: F_INTERVIEW_CASE IX_INTERVIEWEE_ROLE_CD CASE-branch
  resolution (5 role-routed key columns).** Per `coverage_interview.md`:
  INTERPRETER_KEY, PHYSICIAN_KEY, NURSE_KEY, PROXY_KEY,
  IX_INTERVIEWEE_KEY all = 1 at Tier 1 isolation regardless of which
  CASE branch fires (D_PROVIDER and D_PATIENT are populated by
  upstream chains; the merged-fixture sequence resolves these
  to non-1 keys). Unrelated to `nbs_act_entity`.
- **OUT_OF_SCOPE: `sp_interview_event` INVESTIGATION_UID projection.**
  Post-edge INVESTIGATION_UID is NULL on both projected rows because
  this fixture does not author the `act_relationship type_cd='IXS'`
  edge (Interview→Investigation). Out of scope unless Investigation-
  context coverage is later wired by a separate Tier 2 agent.
- **No SRTE_GAP introduced by this fixture.** All three type_cds
  (`IntrvwerOfInterview`, `IntrvweeOfInterview`, `OrgAsSiteOfIntv`)
  are documented as `MISSING_FROM_SRTE` in
  `catalog/edge_types.md` (Phase B finding). Per Phase B's policy:
  "use these type_cds as written (matching the SP literal exactly).
  The corresponding code_value_general rows are NOT seeded by
  baseline SRTE; this is a documented reference-data gap that
  fixture authors do not paper over by inserting into SRTE." This
  fixture honors that policy: it uses the literal type_cd values
  and does NOT INSERT into SRTE. RTR's joins on these are LEFT JOINs,
  so the SRTE gap does not crash the SP — it simply means the
  `code_value_general` lookup yields NULL for description columns
  (none of which the Interview event SP needs for these type_cds,
  since it only projects `nae.entity_uid`, not a code description).
- **No FOUNDATION_GAP.** Foundation Interview (act_uid 20000140 with
  class_cd='ENC', mood='EVN', `interview.interview_uid=20000140`),
  foundation Provider (entity_uid 20000010, class_cd='PSN',
  person.cd='PRV'), foundation Patient (entity_uid 20000000,
  class_cd='PSN', person.cd='PAT'), and foundation Organization
  (entity_uid 20000020, class_cd='ORG') match the
  IntrvwerOfInterview / IntrvweeOfInterview / OrgAsSiteOfIntv
  endpoint constraints exactly. Same applies for v2 Interview
  (20090010), v2 Provider (20010010), v2 Patient (20020010), v2
  Organization (20030010).
- **No new LINK_REQUIRED found.** The SP filter sites visited by this
  edge (lines 87-95) are all single-edge LEFT JOINs — no chained
  joins through other cross-subject edges. The only related
  cross-subject edge the Interview event SP reads (the `IXS`
  act_relationship at lines 85-86) is already documented as a
  separate Tier 2 deliverable above.

## Decisions made under prompt ambiguity

1. **IDENTITY_INSERT wrap required for nbs_act_entity inserts.**
   `nbs_act_entity_uid` is an IDENTITY column in baseline 6.0.18.1
   (verified via `sys.columns.is_identity=1`). Pattern carried over
   directly from the sibling `vaccination_links` agent (eighth Tier 2
   agent, also `nbs_act_entity`). The prompt explicitly called out
   "CRITICAL: nbs_act_entity is an IDENTITY table" with the wrap
   pattern.
2. **`type_cd` populated as `N'IntrvwerOfInterview'`,
   `N'IntrvweeOfInterview'`, `N'OrgAsSiteOfIntv'` (mixed case).**
   The SP filter sites at `065-sp_interview_event-001.sql:89` (`'IntrvwerOfInterview'`),
   :92 (`'OrgAsSiteOfIntv'`), :95 (`'IntrvweeOfInterview'`) all use
   mixed case as written. Default collation
   `SQL_Latin1_General_CP1_CI_AS` is case-insensitive, so either
   choice works, but mixed case mirrors NBS production data
   conventions and matches the catalog's literal spellings.
3. **`entity_version_ctrl_nbr = 1` (smallint).** Standard NBS
   convention for new versioned rows. NOT-NULL column requiring a
   value; same choice as sibling vaccination_links.
4. **`record_status_cd = N'ACTIVE'` populated explicitly even though
   no current SP at lines 87-95 filters on it.** Same shape-
   consistency rationale as prior Tier 2 agents (and sibling
   vaccination_links). Future SP additions might filter; ODSE graph
   correctness for the comparison test against MasterETL also
   benefits.
5. **All 3 type_cds authored in a single fixture file.** The per-
   edge prompt explicitly bundles all 3 types ("Three related edge
   types, all authored in this fixture"). One file, one tail-EXEC,
   six rows — consistent with the prompt's "6 INSERT INTO
   nbs_act_entity rows wrapped in SET IDENTITY_INSERT ON/OFF".
6. **No tail-EXEC of D_INTERVIEW / F_INTERVIEW_CASE postprocessing
   SPs in the fixture file.** The merge orchestrator owns step-7
   re-runs; this fixture's tail-EXEC is `sp_interview_event` only,
   which is the genuine JSON-projection unlock target. We DID re-run
   the postprocessing SPs during verification to confirm they
   produce identical D_INTERVIEW / D_INTERVIEW_NOTE /
   F_INTERVIEW_CASE values pre/post-edge (a sanity check, not a
   fixture-flow requirement) — verified all three populations
   byte-identical.
7. **No surrogate-UID allocation for "future amendment" reservation
   beyond the 6 used.** The 21008000-21008999 block is deliberately
   wide (1000 UIDs); 994 are reserved for future Interview-link
   Tier 2 amendments (e.g., a v3 Interview's edges, or alternative
   interviewer/interviewee endpoints).

## Confirmation deliverables exist

- [x] `fixtures/20_links/interview_links.sql` — 6-row INSERT into
      `nbs_act_entity` (with IDENTITY_INSERT wrap) plus tail-EXEC
      of `sp_interview_event`.
- [x] `coverage/coverage_interview_links.md` — this file.
- [x] `catalog/uid_ranges.md` — Tier 2 section extended with the
      interview_links agent's block (21008000-21008999) and detail
      sub-section listing all 6 surrogate UIDs.
