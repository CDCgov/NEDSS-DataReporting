# ODSE volume generator

Generates high-volume synthetic `NBS_ODSE` data for RTR install and Debezium
initial-snapshot performance testing. Target is full ODSE footprint: millions of
patients with realistic per-patient fan-out into investigations, observations, and
the RIM edge tables, reaching tens of GB.

## Design: hybrid

A Python driver owns the graph. It computes every UID deterministically (`keys.py`)
and shards the work so generation stays memory-bounded and reproducible. tablefaker
owns the column values: names, dates, demographics, and coded columns drawn from the
real SRTE code sets. Keys never depend on a lookup, so shards run independently and a
fixed seed reproduces the exact dataset.

Why not scale the existing `synthetic-odse-fixtures`: those are hand-authored literal
INSERTs with primary keys baked into a Markdown registry and verified by draining the
full CDC pipeline per tier. That set is a coverage instrument. This is a volume
generator. It borrows the fixtures' shape rules (which tables a valid subject needs,
the Act/Entity edges, the UI-visibility gates) and drops their hand-authoring.

## Ratios

`config/ratios.yaml` holds every fan-out. Each is `fixed`, `uniform`, or `zipf`. The
zipf option models the real shape: a few patients carry most of the observations. The
numbers are estimates pending a real STLT ODSE profile; swap them when that lands.

## Prototype gate

The first milestone generates 10k patients, each with one investigation that renders
in the classic NBS6 patient file. Visibility needs three things on the
`public_health_case` (per the OKF ui-visibility note): `record_status_cd='OPEN'`, a
`SubjOfPHC` participation to the patient, and a valid `program_jurisdiction_oid`
(`jurisdiction.nbs_uid*100000 + program_area.nbs_uid`). The driver bakes these in.

## Load path

Generate Parquet in shards, then bulk-load into `NBS_ODSE` (bypassing the CDC pipeline;
the pipeline enters only when you measure the snapshot). INSERT statements are too slow
at this scale.

## Layout

- `config/ratios.yaml` — the fan-out model
- `src/odse_volume_generator/keys.py` — deterministic key allocator + sharding
- `src/odse_volume_generator/config.py` — ratios loader + distribution sampler
- `src/odse_volume_generator/schema/` — tablefaker YAML configs per table
- `src/odse_volume_generator/generate.py` — the driver (WIP)
- `src/odse_volume_generator/load.py` — bulk load (WIP)
- `src/odse_volume_generator/verify.py` — curl UI-visibility check (WIP)

## Run

```
uv sync
uv run python -m odse_volume_generator.generate --config config/ratios.yaml
```
