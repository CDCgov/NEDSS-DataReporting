# Methodology — Comparison-Fixtures (APP-471)

For a technical reader fluent in NBS, NBS7, and RTR. Full agent
contract in [`STRATEGY.md`](./STRATEGY.md); this document focuses on
**how** we arrived at a working fixture set rather than what the final
artifact looks like.

## The problem

To diff RDB (MasterETL) against RDB_MODERN (RTR) we needed an NBS_ODSE
state that, after both pipelines run, exercises every column RTR can
write. Production extracts won't do — they hit narrow happy paths,
leave most CASE branches unvisited, and carry PII. Hand-authored
synthetic data is the only option, and the authoring problem isn't
"make ODSE inserts that look plausible." It's "make ODSE inserts that,
after a multi-hop transformation chain we don't fully understand,
populate a specific RDB_MODERN column."

## We worked the chain in reverse

Rather than starting at ODSE and hoping the right things happened
downstream, we started at the **end** of the RTR chain — the RDB_MODERN
write targets — and walked backward through the SP code to discover
what ODSE inputs cause each target column to populate.

```
NBS_ODSE  →  CDC → nrt_* staging  →  sp_*_event (JSON projection)
          →  sp_nrt_*_postprocessing  →  RDB_MODERN dims/facts
          →  sp_*_datamart_postprocessing  →  RDB_MODERN datamart facts
```

Two reverse-engineering passes seeded everything else:

1. **Phase 0 — RDB_MODERN target column catalog.** Static analysis of
   every routine in `005-rdb_modern/routines/` extracts the set of
   `(table, column)` pairs *any* RTR SP writes. Output:
   `catalog/rtr_target_columns.md`. This is the canonical scope — every
   later coverage report is measured against it. 118 in-scope tables,
   ~4,600 columns.
2. **Phase B — Edge-type catalog.** Enumerate from live baseline SRTE
   every legal `type_cd` for the connective tables (`act_relationship`,
   `participation`, `nbs_act_entity`, `entity_locator_participation`,
   `role`, `act_id`), together with the source/target `class_cd`
   constraints each implies. Output: `catalog/edge_types.md`. Fixture
   agents pick edge codes from this catalog rather than inventing them.

These two catalogs convert "what does the RTR pipeline expect?" from
folklore to a queryable artifact.

## Per-SP authoring loop

Each fixture agent runs the same six-step pattern, driven by reading
the postprocessing SP body line-by-line:

1. **Read the postprocessing SP.** Extract every column written and
   every staging column read. This becomes the column target list.
2. **Read the event SP** — but only as a contract test. The event SP
   does not populate staging (a common misconception). In production,
   staging is written by CDC → Kafka → kafka-connect; the event SP only
   emits a JSON projection for downstream consumers. We bypass the CDC
   pipeline entirely (see below).
3. **Inspect DDL for every table on both sides** — the ODSE tables we'll
   INSERT into, the `nrt_*` staging table, and the RDB_MODERN target.
   Identify NOT-NULL columns; skip `GENERATED ALWAYS` temporal-system
   columns; preserve any schema-level typos verbatim (`PROVIDER_REGISRATION_NUM_AUTH`,
   missing the `T` — we don't get to silently correct it).
4. **Verify SRTE codes live.** Every `*_cd` value gets a `sqlcmd`
   against `code_value_general` (or the relevant sub-table) before
   appearing in a fixture. No invented codes.
5. **Author the fixture** — ODSE INSERTs that hang off the foundation
   parent UID plus a fully-populated v2 variant in a fresh UID block,
   then synthetic `nrt_*` rows that mirror what kafka-connect would
   have written. The two variants together exercise the SP's
   populated path *and* its null/blank/CASE branches.
6. **Verify and report.** Run event SP → postprocessing SP against a
   fresh baseline. Inspect each RDB_MODERN target column. NULL columns
   that the SP demonstrably *can* populate are coverage gaps — iterate
   on the fixture. NULL columns the SP does not write are
   `OUT_OF_SCOPE`. Missing data the SP needs is logged as
   `SRTE_GAP` / `FOUNDATION_GAP` / `LINK_REQUIRED` — silent skips
   forbidden.

The agent produces a coverage report keyed to `rtr_target_columns.md`:
which columns populated, which deliberately skipped (with reason and
SP-body citation), which gap findings, which `LINK_REQUIRED` edges for
a later tier to provide.

## The NRT-staging shortcut

In production, `nrt_*` rows are written by **SQL Server CDC → Debezium
→ Kafka → kafka-connect JDBC sink**. Standing that pipeline up locally
adds four services to every reset and 60-90s per cycle for staging to
flow. We deliberately bypass it — agents author `nrt_*` rows **by
hand**, alongside their ODSE INSERTs, in the same SQL file. The diff
target is the postprocessing SP's transformation logic, not CDC payload
fidelity. This is the single biggest reason iteration is fast enough
to run ~5-minute end-to-end cycles instead of half-hour ones.

## Tier composition

Subjects don't exist in isolation — Investigation joins to Patient,
Lab joins to Investigation, etc. We decomposed into tiers so each
agent's outputs become the next tier's read-only inputs:

- **Tier 0** — Foundation. One canonical instance of each of the 11
  subjects (UIDs `20000000-20009999`).
- **Tier 1** — Subjects (one agent per subject). Owns internal edges
  only. 10k-wide per-subject blocks.
- **Tier 2** — Links (one agent per edge type). Cross-subject
  `act_relationship` / `participation` / `nbs_act_entity` rows. UIDs
  `21000000-21099999`.
- **Tier 3** — Gap-driven targeted additions on SPs whose Tier 1/2
  verification reported reachable-but-uncovered columns. UIDs
  `22000000-22099999`.

A single UID range registry (`catalog/uid_ranges.md`) is the source of
truth. Collisions fail the merge loudly — no auto-deduplication.

## Reproducibility

`scripts/merge_and_verify.sh` runs the deterministic 9-step Merge
contract end-to-end: `docker compose down -v` → liquibase image
rebuild → infrastructure SPs (RDB_DATE, CONDITION) → foundation →
Tier 1 → Tier 1 chains → Tier 2 → re-run affected chains → Tier 3 →
datamart SPs (incl. the dynamic-datamart chain, whose applicable
datamarts are discovered at runtime by joining
`nrt_investigation.investigation_form_cd` against `v_nrt_nbs_page`).
Same fixtures + same baseline image → identical RDB_MODERN state every
run. Wall-clock ~5 min. The liquibase image is rebuilt on every reset
so working-tree edits to routines reach the running DB — we don't
depend on `runOnChange` checksum diffing against a baked image.
`scripts/coverage_summary.sh` writes the canonical headline report.

## Bug discovery as a byproduct

Authoring fixtures that exercise every column path inevitably surfaces
SPs that don't behave the way their column comments suggest. **Ten
RTR bugs surfaced to date** (5 fixed upstream, 3 squashed on this
branch, 2 documented with repros for follow-up). Each is documented
in `bugs/<N>_<slug>/findings.md` with a minimal repro. They range
from trivial (`IF @debug` resetting `@@ROWCOUNT` and zeroing
job_flow_log row counts; column-name typos; SUBSTRING-with-empty-string
crashes) to architectural (postprocessing SPs that try to traverse
ODSE through the NRT staging boundary; dynamic UNPIVOTs that assume
uniform column types; surrogate-key allocations that default to a
filtered-out sentinel). See [`bugs/README.md`](./bugs/README.md) for
the rolling status table.
