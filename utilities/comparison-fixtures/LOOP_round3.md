# Coverage top-up loop — Round 3 (overnight, autonomous)

**Active control doc for the current self-paced loop.** Round 1 → `LOOP_round1.md`,
Round 2 → `LOOP.md` (both historical; this is the live one).

**Goal**: raise overall column coverage above the current baseline (89.9%,
4165/4633) by authoring Tier-3 enrichment fixtures that fill empty / low-partial
tables. Fan out ~3–5 background agents per iteration for comprehensiveness:
more columns, more tables, more tiers.

**Cadence**: self-paced via `ScheduleWakeup` (~1200s between ticks).
**Branch**: commit improvements to `aw/odse-test-seed`.

## Stop conditions (check at top of every firing)
1. `utilities/comparison-fixtures/STOP_LOOP` file exists → write end note, STOP
   (omit ScheduleWakeup).
2. Iteration cap: 24 firings (write running count to the journal below).
3. Coverage plateau: 3 consecutive iterations with **zero** net new populated
   columns AND no agents in flight → STOP.
4. Pipeline broken: if `merge_and_verify`/`coverage_summary` fails twice in a row
   → write to `BLOCKED.md`, STOP.

## Per-iteration protocol (each firing)
1. **Read this file.** Check stop conditions above.
2. **Reconcile finished agents** (TaskList + task notifications):
   - Verify their fixture file is under `fixtures/30_sp_coverage/`.
   - Acquire DB lock (`scripts/db_lock.sh` — explicit `acquire_db_lock` /
     `release_db_lock`, NOT the heredoc form). Apply the fixture with `sqlcmd`,
     EXEC the SP(s) the agent named, then run `bash scripts/coverage_summary.sh`.
     Release the lock.
   - If headline column count went **up** and nothing regressed → `git add` the
     fixture + refreshed `coverage/coverage_merged.md` + any per-fixture coverage,
     commit with before→after numbers. Else if the fixture errored → move it to
     `fixtures/30_sp_coverage/_quarantine/<name>.sql.<reason>` and note it.
   - Mark that agent's task completed.
3. **Survey gaps**: from `coverage/coverage_merged.md`, list tables by
   (total_cols − populated_cols) descending. Skip tables already owned by an
   in-flight agent and known MasterETL-only tables (`catalog/odse_unknown_tables.md`).
4. **Top up to ~4 agents in flight.** For each new agent: allocate the next free
   UID block (see below; reserve it in `catalog/uid_ranges.md` AND mark it here in
   the SAME turn), then spawn a background `Agent` whose contract is:
   "Author one Tier-3 fixture at `fixtures/30_sp_coverage/<name>.sql` targeting
   <table/datamart gap>, following `STRATEGY.md` + the matching `prompts/` contract
   + an existing similar fixture as template. Use only your UID block. Author both
   the ODSE rows and the nrt_* staging rows. Tail-EXEC the SP(s) that populate the
   target. Report the SP(s) + UIDs to run and any RTR bug you hit (do NOT fix
   liquibase — describe it for `bugs/`). Do not apply to the shared DB yourself;
   the orchestrator applies under the DB lock."
5. **Append one line** to the Iterations journal.
6. **ScheduleWakeup ~1200s**, prompt = literal `<<autonomous-loop-dynamic>>`.

## Hard rules (DO NOT VIOLATE)
- DO NOT message the user mid-loop. If genuinely blocked, write `BLOCKED.md` + STOP.
- DO NOT use `AskUserQuestion`.
- DO NOT touch liquibase routines (RTR-fix territory). Surface bugs as
  `bugs/NN_<name>/findings.md` only.
- DO NOT modify orchestrator UID lists / fixtures outside `30_sp_coverage/` unless a
  finished agent's ORCH_TODO explicitly requires it (then do it in the reconcile step).
- USE the DB lock for every apply/coverage refresh; hold it minimally.
- DO NOT mass-revert. One bad fixture → quarantine + continue.
- Two agents must never target the same datamart/dim in the same iteration.

## Seed target queue (biggest yield first; refine from live survey each tick)
- ~~`aggregate_report_datamart` (0/42)~~ — BUG-BLOCKED (bug #11); fixture ready, do NOT re-spawn until SP fixed.
- `sr100` / SR100 datamart (0/20).
- `var_datamart` (210/231 — close the last 21).
- `ldf_bmird` (0/7), `ldf_hepatitis` (0/7) — LDF-flagged answer rows (see
  `EMPTY_TABLES_TRIAGE.md` LDF section; gate is `ldf_status_cd IN (...)`).
- `lookup_table_n_rept` (0/2).
- `d_investigation_repeat` (250/253 — last 3).
- TB / STD_HIV / BMIRD datamarts — remaining partial columns.

## Available UID blocks (Round 3)
| Block | Status |
| --- | --- |
| 22023000 - 22023999 | **allocated** R3-A (aggregate_report_datamart) |
| 22024000 - 22024999 | **allocated** R3-B (sr100 datamart) |
| 22025000 - 22025999 | **allocated** R3-C (ldf_bmird + ldf_hepatitis) |
| 22026000 - 22026999 | **allocated** R3-D (var_datamart remainder) |
| 22027000 - 22027999 | **allocated** R3-E (TB_DATAMART remainder) |
| 22028000 - 22028999 | free |
| 22029000 - 22029999 | free |
| 22030000+ | add a new row to `catalog/uid_ranges.md` when you allocate |

## Iterations journal
(append one line per firing: tick #, time, agents spawned/reconciled, coverage before→after)
- (baseline established this session: 89.9% / 4165-4633; stack healthy)
- tick 1: spawned R3-A (aggregate_report_datamart 0/42), R3-B (sr100 0/20), R3-C (ldf_bmird+ldf_hepatitis), R3-D (var_datamart 210/231). UID 22023xxx-22026xxx. Awaiting agents.
- R3-A reconciled: zz_aggregate_report_enrich.sql applies clean but aggregate_report_datamart stays 0 — BUG-BLOCKED by RTR bug #11 (phantom cols NOTIFICATION_UPD_DT_KEY + NOTIFICATION_LAST_CHANGE_TIME). Fixture committed as prepared/ready-when-fixed. Target marked blocked (no re-spawn). No coverage delta. Spawned R3-E (TB_DATAMART remainder) as replacement, UID 22027xxx.
