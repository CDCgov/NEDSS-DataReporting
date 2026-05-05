# Comparison Fixtures

Synthetic NBS_ODSE INSERTs designed to maximize RDB_MODERN coverage when RTR
runs initial hydration. Used as input to a planned RDB-vs-RDB_MODERN
comparison test against MasterETL.

Read [`STRATEGY.md`](./STRATEGY.md) first — it is the contract every
sub-agent and every fixture file references.

## Layout

| Path | Purpose |
| ---  | ---     |
| `STRATEGY.md` | Strategy, baseline, build order, contracts |
| `catalog/` | Reference data: target columns, edge-type catalog, UID registry |
| `fixtures/` | Tiered SQL files, applied in numeric order |
| `coverage/` | One markdown report per fixture file |
| `prompts/` | Sub-agent prompts (one per phase) and templates |
| `scripts/` | Baseline reset, fixture apply, SP verify helpers |

## Build order

See `STRATEGY.md` → "Build order". Summary:

1. Phase 0 (`prompts/phase_0_target_columns.md`) → `catalog/rtr_target_columns.md`
2. Phase B (`prompts/phase_b_edge_catalog.md`) → `catalog/edge_types.md`
3. Tier 0 (`prompts/tier_0_foundation.md`) → `fixtures/00_foundation/`
4. Provider canary (`prompts/tier_1_provider_canary.md`) → derive Tier 1 template
5. Tier 1 batch (per-subject)
6. Tier 2 (cross-subject links)
7. Tier 3 (gap-driven SP coverage)
8. Final merge + verification
