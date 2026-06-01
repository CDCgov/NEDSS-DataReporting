# Methodology: Comparison-Fixtures (APP-471)

For a technical reader fluent in NBS, NBS7, and RTR. Full agent
contract in [`STRATEGY.md`](./STRATEGY.md); this document focuses on
how we arrived at a working fixture set rather than what the final
artifact looks like.

## The problem

To diff RDB (MasterETL) against RDB_MODERN (RTR) we needed an NBS_ODSE
state that, after both pipelines run, exercises every column RTR can
write. Production extracts won't do. They hit narrow happy paths, leave
most CASE branches unvisited, and carry PII. Hand-authored synthetic
data is the only option. Authoring "plausible" ODSE rows is easy;
authoring rows that survive a multi-hop transformation chain we don't
fully understand and then populate a specific RDB_MODERN column is the
hard problem this project solves.

## We worked the chain in reverse

Rather than starting at ODSE and hoping the right things happened
downstream, we started at the end of the RTR chain (the RDB_MODERN
write targets) and walked backward through the SP code to discover what
ODSE inputs cause each target column to populate.

```
NBS_ODSE  →  CDC → nrt_* staging  →  sp_*_event (JSON projection)
          →  sp_nrt_*_postprocessing  →  RDB_MODERN dims/facts
          →  sp_*_datamart_postprocessing  →  RDB_MODERN datamart facts
```

Two reverse-engineering passes seeded everything else. They are called
Phase 0 and Phase B in `STRATEGY.md`; the letter naming is historical
and there is no Phase A.

1. **Phase 0: RDB_MODERN target column catalog.** Static analysis of
   every routine in `005-rdb_modern/routines/` (130 .sql files) extracts
   the set of `(table, column)` pairs any RTR SP writes. Output:
   `catalog/rtr_target_columns.md`. 118 in-scope tables; 4,633 total
   columns; 3,593 statically-extracted write pairs. The headline "89.9%
   column coverage" in `coverage/coverage_merged.md` (measured
   2026-05-27 against a fresh from-scratch run) is exactly 4,165 / 4,633
   measured against this catalog, so the fraction is of *this file*
   rather than of "everything RDB_MODERN could be." That definition is
   load-bearing for the whole project. The 572-column gap between
   measured-populated (4,165) and statically-extracted (3,593) write
   pairs reflects columns that populate without appearing on the left
   side of an `INSERT`/`UPDATE`/`MERGE`: DDL `DEFAULT` clauses,
   `IDENTITY` sequences, and the temporal-system
   `SysStartTime`/`SysEndTime` machinery. Static extraction gives a
   lower bound on the writable surface.

   **Extraction method.** We grepped `INSERT INTO`, `UPDATE … SET`,
   `MERGE [INTO]`, and `SELECT … INTO` against the routines tree.
   `INSERT` alone undercounts because RTR uses all four patterns
   (postprocessing SPs prefer `MERGE`; datamart SPs prefer
   `UPDATE … FROM`). Pure `FROM`-clause references were filtered out,
   so the catalog reflects writes only. `nrt_*`, `tmp_*`, `#temp`, and
   `@table_var` targets are reported separately as intermediate, rather
   than as in-scope coverage targets.

   **Why static and not live introspection.** The SP code is the source
   of truth for what RTR is *capable* of writing, independent of
   whether any production data has yet exercised those paths. A live
   `INFORMATION_SCHEMA` / row-count introspection would understate the
   target by exactly the coverage gap we are trying to measure:
   unexercised CASE branches would silently drop out of scope. Static
   extraction is the only method that surfaces them.

   **Dynamic-SQL caveat.** Datamart SPs that build their `INSERT` as
   `'INSERT INTO dbo.' + @tgt_table_nm + …` can't be statically
   resolved from the `INSERT` text, because the target is a runtime
   parameter. For these (17 SPs, including
   `sp_dyn_dm_createdm_postprocessing` and the per-condition
   `sp_<cond>_case_datamart_postprocessing` family) we walked the
   `DECLARE @tgt_table_nm` at the top of each SP, or the row in
   `nrt_datamart_metadata` it joins against, to resolve the table.
   These appear in the catalog as `<dynamic:…>` placeholders
   (17 distinct, e.g. `<dynamic:@tgt_table_nm>`). Column lists are not
   statically derivable; the dynamic-datamart chain is verified
   post-hoc by inspecting the materialized tables after a run.

   **What 118 means.** This counts the RDB_MODERN tables some RTR SP
   writes, rather than every RDB_MODERN table. Tables MasterETL writes
   that RTR does not are out of scope by construction; they surface as
   legitimate diff findings in the comparison tool rather than as
   fixture gaps. `catalog/odse_unknown_tables.md` bucket (a), which
   lists 22 MasterETL-only tables, makes this category explicit.
2. **Phase B: Edge-type catalog.** Enumerate from live baseline SRTE
   every legal `type_cd` (or analogous discriminator) for the seven
   connective tables (`act_relationship`, `participation`,
   `nbs_act_entity`, `entity_locator_participation`, `role`, `act_id`,
   `entity_id`), together with the source/target `class_cd` constraints
   each implies, plus a per-row citation back to the RTR routine that
   filters on it. Output: `catalog/edge_types.md`. The catalog holds 48
   distinct discriminator values across the seven tables, each tied to
   one or more routine line numbers. Fixture agents pick edge codes
   from this catalog rather than inventing them; codes RTR filters on
   but missing from baseline SRTE are flagged in a `MISSING_FROM_SRTE`
   appendix instead of silently dropped.

These two catalogs convert "what does the RTR pipeline expect?" from
folklore to a queryable artifact.

## Per-SP authoring loop

Each fixture agent runs the same six-step pattern, driven by reading
the postprocessing SP body line-by-line:

1. **Read the postprocessing SP.** Extract every column written and
   every staging column read. This becomes the column target list.
2. **Read the event SP**, but only as a contract test. The event SP
   does not populate staging (a common misconception). In production,
   staging is written by CDC → Kafka → kafka-connect; the event SP
   only emits a JSON projection for downstream consumers. We bypass
   the CDC pipeline entirely (see below).
3. **Inspect DDL for every table on both sides:** the ODSE tables
   we'll INSERT into, the `nrt_*` staging table, and the RDB_MODERN
   target. Identify NOT-NULL columns; skip `GENERATED ALWAYS`
   temporal-system columns; preserve any schema-level typos verbatim
   (`PROVIDER_REGISRATION_NUM_AUTH`, missing the `T`; we don't get to
   silently correct it).
4. **Verify SRTE codes live.** Every `*_cd` value gets a `sqlcmd`
   against `code_value_general` (or the relevant sub-table) before
   appearing in a fixture. No invented codes.
5. **Author the fixture.** ODSE INSERTs that hang off the foundation
   parent UID plus a fully-populated v2 variant in a fresh UID block,
   then synthetic `nrt_*` rows that mirror what kafka-connect would
   have written. The two variants together exercise the SP's populated
   path *and* its null/blank/CASE branches.
6. **Verify and report.** Run event SP → postprocessing SP against a
   fresh baseline. Inspect each RDB_MODERN target column. NULL columns
   that the SP demonstrably *can* populate are coverage gaps; iterate
   on the fixture. NULL columns the SP does not write are
   `OUT_OF_SCOPE`. Missing data the SP needs is logged as `SRTE_GAP` /
   `FOUNDATION_GAP` / `LINK_REQUIRED`. Silent skips are forbidden.

The agent produces a coverage report keyed to `rtr_target_columns.md`:
which columns populated, which deliberately skipped (with reason and
SP-body citation), which gap findings, which `LINK_REQUIRED` edges for
a later tier to provide.

## The NRT-staging shortcut

In production, `nrt_*` rows are written by SQL Server CDC → Debezium
→ Kafka → kafka-connect JDBC sink. Standing that pipeline up locally
adds four services to every reset and 60-90s per cycle for staging to
flow. We deliberately bypass it. Agents author `nrt_*` rows by hand,
alongside their ODSE INSERTs, in the same SQL file. The diff target is
the postprocessing SP's transformation logic; CDC payload fidelity is
irrelevant here. This is the single biggest reason iteration is fast
enough to run ~5-minute end-to-end cycles instead of half-hour ones.

## Tier composition

Subjects don't exist in isolation; Investigation joins to Patient, Lab
joins to Investigation, etc. We decomposed into tiers so each agent's
outputs become the next tier's read-only inputs:

- **Tier 0.** Foundation. One canonical instance of each of the 12
  subjects (Patient, Provider, Organization, Place, Investigation,
  Notification, Lab Report, Morbidity Report, Interview, Treatment,
  Vaccination, Contact Record) at UIDs `20000000-20009999`.
- **Tier 1.** Subjects (one agent per subject). Owns internal edges
  only. 10k-wide per-subject blocks.
- **Tier 2.** Links (one agent per edge type). Cross-subject
  `act_relationship` / `participation` / `nbs_act_entity` rows. UIDs
  `21000000-21099999`.
- **Tier 3.** Gap-driven targeted additions on SPs whose Tier 1/2
  verification reported reachable-but-uncovered columns. UIDs
  `22000000-22099999`.

A single UID range registry (`catalog/uid_ranges.md`) is the source of
truth. Collisions fail the merge loudly; auto-deduplication is
forbidden.

## Scaling: parallel agents

The per-SP loop is the unit of work; coverage scales by running many
of them concurrently. Each agent claims one datamart or dimension plus
a reserved UID block, works in its own git worktree, and commits
incrementally. A parent loop reconciles the worktrees via cherry-pick
under a `mkdir`-based DB lock (`scripts/db_lock.sh`) and a single
foreground re-apply. Because UID-range discipline keeps agents from
colliding, per-table gains are additive. Two such multi-agent loops
drove the bulk of the climb from 41.4% to the current 89.9%, with
SP-level defects logged as `bugs/<N>_*/findings.md` rather than fixed
mid-loop.

## Reproducibility

`scripts/merge_and_verify.sh` runs the deterministic 9-step Merge
contract end-to-end: `docker compose down -v` → liquibase image rebuild
→ infrastructure SPs (RDB_DATE, CONDITION) → foundation → Tier 1 →
Tier 1 chains → Tier 2 → re-run affected chains → Tier 3 → datamart
SPs (incl. the dynamic-datamart chain, whose applicable datamarts are
discovered at runtime by joining `nrt_investigation.investigation_form_cd`
against `v_nrt_nbs_page`). Same fixtures + same baseline image →
identical RDB_MODERN state every run. Wall-clock ~5 min. The liquibase
image is rebuilt on every reset so working-tree edits to routines
reach the running DB; we don't depend on `runOnChange` checksum
diffing against a baked image. `scripts/coverage_summary.sh` writes
the canonical headline report.

## What this doesn't measure

The "89.9% column coverage" headline answers one specific question: of
the columns RTR's stored procedures can write, how many ended up
populated after our fixtures ran? It deliberately does not answer
several adjacent questions a reader may assume it does.

Row-level equivalence against MasterETL is one of them. We measure
whether each target column has ≥1 non-NULL row; we do not measure
whether RTR's output value-for-value matches what MasterETL would have
written for the same input. Value-level equivalence is a separate diff
phase handled by the comparison tool that consumes this fixture set,
and it does not roll into the 89.9% figure.

The uncovered 10.1% is also not synonymous with "broken." A substantial
chunk of those uncovered columns are confirmed `OUT_OF_SCOPE` (the SP
cannot write them; they exist on the target table for legacy MasterETL
reasons) or are blocked on external SRTE additions or open RTR bugs
already filed. `bugs/README.md` and the per-SP `LINK_REQUIRED` /
`SRTE_GAP` findings carry the breakdown.

Finally, synthetic fixtures do not approximate production
distributions. They exercise schema shape and SP code paths only.
Whether RTR produces statistically realistic values is a separate
question for downstream QA on metric shape, and belongs to a different
harness.

## Bug discovery as a byproduct

Authoring fixtures that exercise every column path inevitably surfaces
SPs that don't behave the way their column comments suggest. Fourteen
RTR bugs surfaced to date: 3 fixes merged upstream, 6 fixed on this
branch, 5 documented with repros for follow-up. Each is documented in
`bugs/<N>_<slug>/findings.md` with a minimal repro. They range from
trivial (`IF @debug` resetting `@@ROWCOUNT` and zeroing job_flow_log
row counts; column-name typos; SUBSTRING-with-empty-string crashes) to
architectural (postprocessing SPs that try to traverse ODSE through
the NRT staging boundary; dynamic UNPIVOTs that assume uniform column
types; surrogate-key allocations that default to a filtered-out
sentinel). See [`bugs/README.md`](./bugs/README.md) for the rolling
status table.
