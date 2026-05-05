# Coverage: treatment_inv (TreatmentToPHC + TreatmentToMorb)

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 21003000 - 21003999 (Tier 2, fourth agent)
- Foundation dependencies:
  - `@dbo_Act_treatment_uid` (20000150) - foundation Treatment Act
  - `@dbo_Act_investigation_uid` (20000100) - foundation Investigation Act / PHC
  - `@dbo_Act_morbidity_uid` (20000130) - foundation Morbidity Order observation
- Other-agent (Tier 1) dependencies (read-only):
  - `@dbo_Act_treatment_v2_uid` (20100010) - v2 Treatment (Tier 1 Treatment block)
  - `@dbo_Act_treatment_v3_uid` (20100020) - v3 Treatment cd='OTH' (Tier 1 Treatment block)
  - `@dbo_Act_investigation_v2_uid` (20050010) - v2 Investigation (Tier 1 Investigation block)
  - `@dbo_Act_morb_v2_order_uid` (20080010) - v2 Morbidity Order (Tier 1 Morbidity block)
- SRTE references:
  - `AR_TYPE` row `TreatmentToPHC` (verified present in baseline SRTE).
  - `AR_TYPE` row `TreatmentToMorb` is **MISSING_FROM_SRTE** per Phase B catalog (`catalog/edge_types.md`); SP filters on the literal anyway.

## SPs verified
- `dbo.sp_nrt_treatment_postprocessing @treatment_uids = N'20000150,20100010,20100020', @debug = 0` (post-edge re-run in fixture's tail-EXEC):
  - exit code 0
  - `dbo.TREATMENT`: 3 rows (TREATMENT_KEY 3 / 5 / 6 for v2 / foundation / v3 — TREATMENT_KEYs for foundation and v3 were re-IDENTITY-allocated since their join key `(treatment_uid, public_health_case_uid)` flipped from `(uid, NULL)` pre-edge to `(uid, 20000100)` post-edge).
  - `dbo.TREATMENT_EVENT`: 3 rows.

## Apply / FK check
- `sqlcmd -i fixtures/20_links/treatment_inv.sql` exit code 0 - **clean apply on first iteration**.
- ODSE INSERTs: 6 rows to `dbo.act_relationship` (no surrogate UIDs allocated).
- RDB_MODERN UPDATEs: 2 UPDATE statements against `dbo.nrt_treatment` (associated_phc_uids on foundation 20000150 and v3 20100020). v2 (20100010) was already correct from Tier 1.
- **Iteration count: 1** baseline-reset cycle.

## Edges authored

### TreatmentToPHC (TRMT -> CASE), 3 rows
| source_act_uid | target_act_uid | type_cd | source_class | target_class |
| --- | --- | --- | --- | --- |
| 20000150 (foundation Treatment) | 20000100 (foundation Investigation) | TreatmentToPHC | TRMT | CASE |
| 20100010 (v2 Treatment) | 20050010 (v2 Investigation) | TreatmentToPHC | TRMT | CASE |
| 20100020 (v3 Treatment, cd='OTH') | 20000100 (foundation Investigation) | TreatmentToPHC | TRMT | CASE |

### TreatmentToMorb (TRMT -> OBS), 3 rows
| source_act_uid | target_act_uid | type_cd | source_class | target_class |
| --- | --- | --- | --- | --- |
| 20000150 (foundation Treatment) | 20000130 (foundation Morb Order) | TreatmentToMorb | TRMT | OBS |
| 20100010 (v2 Treatment) | 20080010 (v2 Morb Order) | TreatmentToMorb | TRMT | OBS |
| 20100020 (v3 Treatment) | 20000130 (foundation Morb Order) | TreatmentToMorb | TRMT | OBS |

Total: **6 act_relationship rows** (3 TreatmentToPHC + 3 TreatmentToMorb).

## Coverage unlocked

**This edge IS coverage-unlock for foundation + v3 (in addition to its declared shape-consistency role)**: although Tier 1 already populated 11/11 TREATMENT_EVENT columns at isolation, 8 of those 11 columns were sentinel 1 (`COALESCE(<lookup>, 1)`). The staging UPDATE on `nrt_treatment.associated_phc_uids` upgrades **2 of those columns to real keys** for the foundation and v3 Treatment rows.

### TREATMENT_EVENT key changes (pre-edge -> post-edge)

Pre-edge state captured from running the Treatment Tier 1 chain only (after foundation + Tier 1 fixtures applied + Provider/Org/Patient/Investigation chains run):

| TREATMENT_KEY | TREATMENT_UID | INVESTIGATION_KEY | CONDITION_KEY | Other FK columns |
| --- | --- | --- | --- | --- |
| 2 (foundation 20000150) | 20000150 | **1 (sentinel)** | **1 (sentinel)** | DT=1, PAT=1, ORG=1, PHY=1, MORB=1, LDF=1 |
| 3 (v2 20100010) | 20100010 | 3 (real) | 42 (real) | DT=5936, PAT=3, ORG=7, PHY=12, MORB=1, LDF=1 |
| 4 (v3 20100020) | 20100020 | **1 (sentinel)** | **1 (sentinel)** | DT=1, PAT=1, ORG=1, PHY=1, MORB=1, LDF=1 |

Post-edge state (after applying this fixture and re-running `sp_nrt_treatment_postprocessing`):

| TREATMENT_KEY | TREATMENT_UID | INVESTIGATION_KEY | CONDITION_KEY | Other FK columns |
| --- | --- | --- | --- | --- |
| 5 (foundation 20000150) | 20000150 | **3 (foundation Inv real key)** | **42 (Hep A acute real key)** | DT=1, PAT=1, ORG=1, PHY=1, MORB=1, LDF=1 |
| 3 (v2 20100010) | 20100010 | 3 (real) | 42 (real) | unchanged - DT=5936, PAT=3, ORG=7, PHY=12, MORB=1, LDF=1 |
| 6 (v3 20100020) | 20100020 | **3 (foundation Inv real key)** | **42 (Hep A acute real key)** | DT=1, PAT=1, ORG=1, PHY=1, MORB=1, LDF=1 |

(TREATMENT_KEYs renumbered for foundation/v3 because the postprocessing SP's join into `nrt_treatment_key` keys on `(treatment_uid, public_health_case_uid)`. Pre-edge that pair was `(uid, NULL)`; post-edge it's `(uid, 20000100)` - a new IDENTITY key was allocated, the old key 2 / 4 row in TREATMENT_EVENT was overwritten by the SP's MERGE-style upsert.)

### Columns flipped sentinel-1 -> real key

| Table.Column | Foundation pre-edge -> post-edge | v3 pre-edge -> post-edge |
| --- | --- | --- |
| `TREATMENT_EVENT.INVESTIGATION_KEY` | 1 -> 3 | 1 -> 3 |
| `TREATMENT_EVENT.CONDITION_KEY` | 1 -> 42 | 1 -> 42 |

(v2 was already at real keys pre-edge; this edge does not change v2.)

### ODSE-graph correctness

The act_relationship rows (the 6 INSERTs into `nbs_odse.dbo.act_relationship`) are **shape-consistency only** for RTR's postprocessing SP — RTR reads `nrt_treatment.associated_phc_uids` and `nrt_treatment.morbidity_uid` from staging, NOT the act_relationship table directly. The INSERTs into the act_relationship table:
- Are what the event SP (`sp_treatment_event` lines 82-86 for TreatmentToMorb, lines 118-131 for TreatmentToPHC) reads to project the JSON `associated_phc_uids` / `morbidity_uid` fields that CDC-Debezium would mirror into staging.
- Are what MasterETL traverses for the same projection.
- Make the comparison test against MasterETL meaningful: both pipelines now reach the same Investigation / Morbidity from the Treatment endpoint.

The staging UPDATE (`nrt_treatment.associated_phc_uids`) is the CDC-equivalent that this fixture writes by hand (since we bypass Debezium per STRATEGY.md "verification recipe"). It is the SP-driven coverage-unlock mechanism.

## Coverage still LINK_REQUIRED

| Table.Column | Pre-edge | Post-edge | Resolved by |
| --- | --- | --- | --- |
| `TREATMENT_EVENT.MORB_RPT_KEY` (v2 20100010) | 1 (sentinel) | 1 (sentinel) | Requires `morb_inv` Tier 2 edge applied AND Morbidity's chain re-run. v2's `nrt_treatment.morbidity_uid` is 20000130 (set by Tier 1); MORB_RPT_KEY only resolves once `dbo.MORBIDITY_REPORT` has a row for `MORB_RPT_UID=20000130`, which requires the `morb_inv` agent's deliverable. Foundation/v3 leave morbidity_uid NULL by Tier 1 design and are not affected. |
| `TREATMENT_EVENT.TREATMENT_DT_KEY` (foundation 20000150, v3 20100020) | 1 (sentinel) | 1 (sentinel) | Foundation/v3 `nrt_treatment.treatment_date` is NULL by Tier 1 design (only v2 has a real treatment_date). Not affected by this edge or any Tier 2 edge. To resolve, Tier 1 Treatment would need additional variants with non-NULL treatment_date - out of Tier 2 scope. |
| `TREATMENT_EVENT.PATIENT_KEY` / `TREATMENT_PROVIDING_ORG_KEY` / `TREATMENT_PHYSICIAN_KEY` (foundation 20000150, v3 20100020) | 1 (sentinel) | 1 (sentinel) | Foundation/v3 `nrt_treatment.patient_treatment_uid` / `organization_uid` / `provider_uid` are NULL by Tier 1 design. Not affected by this edge or any participation edge currently planned (no `tier_2_participation_treatment` agent yet). |
| `TREATMENT_EVENT.LDF_GROUP_KEY` (all 3 rows) | 1 (sentinel) | 1 (sentinel) | LDF chain populates `dbo.LDF_GROUP` keyed on `business_object_uid = treatment_uid`. No LDF rows authored for Treatment — out of Tier 2 scope (LDF is an orthogonal Tier 1 / Tier 3 concern). |

## Decisions made under prompt ambiguity

- **Edge row count: 6, not 7.** The system reminder mentioned "4 TreatmentToPHC ... plus one more pair if needed". The per-edge prompt enumerates only 3 explicit endpoint pairs for TreatmentToPHC (foundation->foundation, v2->v2, v3->foundation Inv). I followed the explicit per-edge prompt enumeration (3 + 3 = 6) — the "if needed" extra pair was not needed; the 3-pair pattern already exercises:
  - foundation Treatment -> foundation Investigation (foundation->foundation pair)
  - v2 Treatment -> v2 Investigation (v2->v2 pair)
  - v3 Treatment -> foundation Investigation (multi-treatment-per-investigation pair, v3 cd='OTH' variant + foundation Inv)
- **Staging UPDATE limited to `associated_phc_uids`.** The per-edge prompt's "Critical reminders" section says "May UPDATE nrt_treatment.associated_phc_uids if Tier 1's value isn't already correct." It did not authorize updating `morbidity_uid`. The morbidity_uid is set on v2 only at Tier 1 (=20000130); foundation and v3 leave it NULL. Updating morbidity_uid on foundation/v3 would not unlock additional coverage at this stage (MORBIDITY_REPORT remains empty without morb_inv applied), so it was skipped. Adding it would be shape-consistency-only with no functional effect on TREATMENT_EVENT — judged out of scope for this edge.
- **TreatmentToMorb authored despite MISSING_FROM_SRTE.** Per Phase B's `MISSING_FROM_SRTE` policy and the per-edge prompt's explicit instruction ("Author with the literal `'TreatmentToMorb'` value"), the row is written with the literal even though SRTE has no matching `code_value_general` row in the `AR_TYPE` set. The SP filters on the literal regardless. Recorded as a SRTE_GAP finding below.
- **Treatment chain run pre-edge to capture pre-state.** Per the system reminder ("Treatment's chain WORKS at Tier 1 isolation (no FK gap), so run it BEFORE applying your edge fixture to capture the pre-edge state"), I ran the chain pre-edge. This differs from the inv_notification / morb_inv pattern where the affected Tier 1 chain was deliberately NOT run pre-edge because the Tier 1 SP-INSERT failed without the edge.

## Gaps reported

### LINK_REQUIRED
- See "Coverage still LINK_REQUIRED" table above. The remaining sentinel-1 columns require other Tier 2 edges (specifically `morb_inv` for MORB_RPT_KEY on v2) or are out of Tier 2 scope (LDF, Tier 1 variants with richer cross-subject UIDs).

### SRTE_GAP
- **`TreatmentToMorb`** (used in `dbo.act_relationship.type_cd` for the 3 TreatmentToMorb rows authored). Verified absent from baseline SRTE `code_value_general` for `code_set_nm='AR_TYPE'`. RTR's `sp_treatment_event` at line 86 filters on the literal `'TreatmentToMorb'` regardless. Phase B catalog already documented this in MISSING_FROM_SRTE; this fixture inherits that gap rather than papering over it by inserting into SRTE.
- **`ProviderOfTrmt`** / **`ReporterOfTrmt`** (participation type_cds) - flagged in Phase B for `participation`-row Tier 2 edges (not authored by this fixture). Mentioned for completeness; relevant to a hypothetical `participation_provider_trmt` Tier 2 agent (not yet decomposed). Not a gap introduced by this fixture.

### FOUNDATION_GAP
- (none - all required foundation entities and Tier 1 entities exist.)

### OUT_OF_SCOPE
- **Participation rows for `SubjOfTrmt` / `ProviderOfTrmt` / `ReporterOfTrmt`** — these are the Patient/Provider/Organization edges on a Treatment Act, separate from the act_relationship-shaped edges this agent owns. Per the per-edge prompt ("Your edge type is `TreatmentToPHC` ... You'll also author the related `TreatmentToMorb` edges"), participation edges are out of scope. They would be a separate Tier 2 agent (`participation_subject_trmt` or similar). Tier 1 Treatment's `nrt_treatment.patient_treatment_uid` / `organization_uid` / `provider_uid` set on v2 already drive the cross-subject FK lookups via the staging mirror, so PATIENT_KEY / TREATMENT_PROVIDING_ORG_KEY / TREATMENT_PHYSICIAN_KEY resolve to real keys for v2 (verified in pre-edge state above).
- **Treatment's INNER JOIN on `treatment_administered`** in `sp_treatment_event` line 65 means rows without a treatment_administered child are not surfaced in the JSON projection. Tier 1 Treatment authored a treatment_administered row for foundation (20000150) as part of "additive child rows tied to a foundation UID". This is unrelated to act_relationship/TreatmentToPHC and is in Tier 1 scope.
- **`sp_treatment_event` is not invoked by this fixture's verification recipe.** Per STRATEGY.md, the event SP is "not invoked in fixture verification — it's a no-op for our purposes since its only side effect is the JSON-emit query, and the staging row we'd want it to produce is the one we just hand-authored." This fixture's UPDATE on `nrt_treatment.associated_phc_uids` IS the hand-authored CDC-equivalent of what the event SP's JSON projection would produce after consuming the new act_relationship rows.

## UID allocation table

(No new UIDs allocated. The 21003000-21003999 block is reserved for any future amendment - e.g., a Tier 3 v4 Treatment variant whose own act_uid would live in this Tier 2 block, or future surrogate-UID needs.)

The fixture's writes:
- 6 rows to `NBS_ODSE.dbo.act_relationship` (composite PK on `(source_act_uid, target_act_uid, type_cd)`; no surrogate UID required).
- 2 UPDATEs against `RDB_MODERN.dbo.nrt_treatment` (staging table, not a dim/fact). UPDATEs target `treatment_uid` 20000150 (foundation) and 20100020 (v3); v2 already correct from Tier 1.
- 0 rows to RDB_MODERN dim/fact tables. Coverage of `TREATMENT_EVENT.INVESTIGATION_KEY` / `CONDITION_KEY` for foundation/v3 is unlocked indirectly by the post-edge re-run of `sp_nrt_treatment_postprocessing` (in the fixture's tail-EXEC).
