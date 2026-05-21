# Overnight autonomous loop — APP-471 coverage push

**Started**: 2026-05-21 (timestamp recorded on first iteration)
**Budget**: 5 hours wall-clock. **Hard stop** at T+5h00m.
**Goal**: Push RDB_MODERN column coverage as high as possible without:
- Fixing RTR bugs (document only)
- Squashing / rebasing / amending commits (linear history only)
- Modifying anything outside `fixtures/30_sp_coverage/` and the planning docs
  (no liquibase routines, no `fixtures/00_foundation/`, no Tier 1, no Tier 2,
  no `scripts/` unless a fixture genuinely needs it)

## Baseline (start of overnight run)

- Fully covered: 65
- Partial: 32
- Empty: 20
- Column coverage: **33.9%** (1566 / 4615 cols populated)
- Last commit: `9ae6c9b7` Docs sweep
- See `coverage/coverage_merged.md` for the canonical state.

## Per-iteration protocol

Each /loop firing:

1. **Read this file first** to recover context.
2. **Check wall-clock**: if T+5h elapsed (compute from "Started" above),
   write `SESSION_SUMMARY.md` and STOP (omit ScheduleWakeup at end of turn).
3. **Check for user abort**: if `STOP_LOOP` file exists at project root,
   write `SESSION_SUMMARY.md` and STOP.
4. **Check coverage_merged.md** for current numbers. Don't trust this file;
   trust only what `merge_and_verify.sh` produces.
5. **Pick ONE bounded item** from the queue below (top of queue first).
6. **Author / fix the item**. Apply fixture, run merge_and_verify, check
   coverage. If coverage IMPROVED, commit with a focused message.
   If coverage REGRESSED or apply ERRORED, revert your fixture (move to
   `_quarantine/`) and move to next queue item.
7. **Update this file**: add a line under "Iterations log" with the result.
8. **ScheduleWakeup** for ~1200-1800s. Pass `/loop <<autonomous-loop-dynamic>>`
   as prompt (the sentinel re-fires this same plan).
9. **DO NOT message the user, ask questions, or use AskUserQuestion**.
   If you'd genuinely block — write the question to `BLOCKED.md`, stop the
   loop, and let me see it in the morning.

## Queue (work top-down)

Each item is bounded. If an item takes more than ~45min in one iteration,
split it across iterations using "Resume notes" below.

### High-value (largest expected unlock)

1. **Pertussis full-chain fixture** (UID 22007000-22007999). Mirror TB
   template. Should unlock `pertussis_case_datamart` (currently 0 / N cols).
   Stub already at 22000040.
2. **Measles full-chain fixture** (22008000-22008999). Mirrors TB template.
   Stub at 22000050. Unlocks `measles_case_datamart`.
3. **Rubella full-chain fixture** (22009000-22009999). Stub at 22000060.
   Unlocks `rubella_case_datamart`.
4. **Mumps full-chain fixture** (22010000-22010999). Stub at 22000030.
   Unlocks `mumps_case_datamart` (and `ldf_mumps` if LDF chain works for it).
5. **Tetanus LDF answer-chain expansion** — extend the existing
   `ldf_answers_tetanus.sql` to produce a full LDF_TETANUS row. Bug-7
   fix is squashed on this branch so `LDF_DIMENSIONAL_DATA` should now
   work; verify and extend.
6. **Per-condition LDF chains** — author equivalents of
   `ldf_answers_tetanus.sql` for the other 5 conditions that have
   per-condition LDF datamart SPs (BMIRD, foodborne, hepatitis, mumps,
   vaccine_prevent_diseases).

### Medium-value (close out partials)

7. **`covid_case_datamart`** is at 53/383 (gap 330). The COVID agent's
   fixture authored 22 answers; adding more SNOMED-coded answers + lab
   observation/vaccination edges would push coverage up. Read the SP
   body to identify the column groups (~10 are clustered) you can hit
   with one batch of answer rows.
8. **`std_hiv_datamart`** at 78/248 (gap 170). Same pattern — read SP,
   identify next answer batch.
9. **`bmird_strep_pneumo_datamart`** at 69/140 (gap 71). Same pattern.

### Lower-priority

10. **Spike `etl_dq_log`** — Tier-1/2-reachable per the classification
    catalog. Three page-builder/SLD SPs write DQ-failure rows. Cheap
    win (1 row × 15 cols).
11. **Spike `summary_report_case`** — 0/12 cols. Investigate via SP grep.

## Iterations log

(append one line per iteration; format: `T+Xh Ym | iter N | <action>
| coverage X.X% (Δ +Y) | commit <hash>` or `| reverted | reason`)

## Resume notes

(if an iteration partial-completed, scratch your handoff state here)

## Stop conditions checklist

End-of-session SUMMARY.md should report:

- Total iterations
- Final coverage % and delta from 33.9%
- New fully-covered tables (count)
- Bugs surfaced (filed only, no fixes — list with severity)
- Fixtures landed (file list)
- Fixtures abandoned / reverted (file list with reason)
- Wall-clock used
- Items left in queue
