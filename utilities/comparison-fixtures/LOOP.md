# Multi-agent top-up loop — APP-471 coverage push round 2

**Started**: 2026-05-24 22:00 PDT
**Hard stop**: 2026-05-25 05:00 PDT (T+7h from start)
**Cadence**: every ~15 minutes (900s) via ScheduleWakeup
**Goal**: keep ~5 agents in flight at all times, each authoring a
Tier-3 enrichment fixture targeting a specific datamart/dim coverage
gap, until the hard stop or the user aborts.

The prior overnight loop (T+5h, single-agent serial) is archived in
`LOOP_round1.md` for reference.

## Per-iteration protocol

Each /loop firing:

1. **Read this file first** (you are here).
2. **Check wall-clock**: if T+7h elapsed (compute from "Started" above),
   write end-of-loop note in "Iterations log" and STOP — omit
   `ScheduleWakeup` at end of turn.
3. **Check for user abort**: if `STOP_LOOP` file exists at
   `utilities/comparison-fixtures/STOP_LOOP`, write end-of-loop note
   and STOP.
4. **Survey running agents**: call TaskList. Background agents may
   have completed since the last tick; check task notifications in
   conversation context.
5. **Reconcile completed agents**:
   - For each completed agent that hasn't been processed yet:
     - If they committed directly to `aw/odse-test-seed`, verify
       commits and fixture file presence.
     - If they worked in a worktree, cherry-pick their commits.
       Find new commits with `git log --oneline <prev-head>..<worktree-branch> --no-merges`.
     - Apply fixture to live DB: `sqlcmd -I -i <fixture>`. EXEC the
       SP(s) the agent identified. Query coverage.
     - Run `bash scripts/coverage_summary.sh` to refresh
       `coverage/coverage_merged.md`.
     - If headline improved, commit (include before/after numbers).
     - TaskUpdate that agent's "Wait for Agent X" task to `completed`.
   - If an ORCH_TODO from the agent (PHC_UIDS extension, Step 8.6-style
     wiring), apply it directly.
6. **Top up to 5 in flight**: count in_progress background agents.
   If fewer than 5, spawn new ones. Each new agent gets a fresh UID
   block from "Available UID blocks" below. Update both
   `catalog/uid_ranges.md` (reserve the block) AND "Available UID
   blocks" (mark allocated) in the same turn.
7. **Update this file**: append one line under "Iterations log".
8. **ScheduleWakeup** for 900s. Pass the literal sentinel
   `<<autonomous-loop-dynamic>>` as `prompt` so the runtime re-enters
   this skill on the next tick.

## Hard rules (DO NOT VIOLATE)

- DO NOT message the user unless something is BLOCKED (write to
  `BLOCKED.md` and stop the loop instead).
- DO NOT use `AskUserQuestion`.
- DO NOT modify the orchestrator's UID lists or fixture files outside
  `fixtures/30_sp_coverage/` UNLESS a completed agent's ORCH_TODO
  explicitly calls for it.
- DO NOT touch liquibase routines (RTR bug territory). If an agent
  surfaces a bug, document at `bugs/NN_<name>/findings.md` — do not
  fix.
- DO NOT spawn agents that target the same datamart/dim as a running
  one. Pick from the queue below or the next-biggest-gap survey.
- USE the DB lock when applying fixtures or refreshing coverage.
  Hold it minimally — agents use it too.
- DO NOT use `with_db_lock <<HEREDOC` — known bug. Use explicit
  `acquire_db_lock` / `release_db_lock` pair (see `scripts/db_lock.sh`).
- DO NOT mass-revert. If a fixture errors, move it to
  `fixtures/30_sp_coverage/_quarantine/` and continue.

## Available UID blocks for loop top-up

| Block | Status |
| --- | --- |
| 22016000 - 22016999 | **allocated** Agent J (hep100 unblock — direct HEPATITIS_CASE seed) |
| 22017000 - 22017999 | **allocated** Agent K (case_lab_datamart enrich) |
| 22018000 - 22018999 | available |
| 22019000 - 22019999 | available |
| 22020000+ | UNRESERVED — if you need more, add a new row to `catalog/uid_ranges.md` in the same turn you allocate. |

## Round-2 targets (currently in flight; do NOT re-spawn)

- **Agent E**: TB cluster (TB_DATAMART 95/318, TB_HIV_DATAMART 99/322,
  D_TB_PAM 9/166) — UID 22011xxx
- **Agent F**: STD_HIV_DATAMART (135/248) — UID 22012xxx
- **Agent G**: BMIRD_STREP_PNEUMO_DATAMART (69/140) — UID 22013xxx
- **Agent H**: D_INVESTIGATION_REPEAT block/seq expansion (39/256) — UID 22014xxx
- **Agent I**: MORBIDITY_REPORT_DATAMART (78/133) — UID 22015xxx

## Round-3 target queue (claim top-down)

Each target lists the gap + standard enrichment playbook. Prefer
targets that don't overlap with currently-running agents.

1. **HEP100 unblock** (gap 187, 0/187) — needs direct seeding of
   `dbo.HEPATITIS_CASE` (no SP writes to it in routines layer; it's
   normally populated by Kafka/Debezium). Author a fixture that
   directly INSERTs a HEPATITIS_CASE row keyed on existing Hep PHC
   22008500. **Largest single-table win in the queue.**
2. **CASE_LAB_DATAMART** (gap 26, 9/35) — needs case-lab investigation
   linkage. Investigate `sp_case_lab_datamart_postprocessing` filters.
3. **COVID_CONTACT_DATAMART** (gap 23, 71/94) — existing 1 row. Easy
   expansion via more nrt_page_case_answer rows for missing CTT_*
   questions.
4. **D_CONTACT_RECORD** (gap 24, 42/66) — sibling of #3. Probably
   covered by COVID contact enrich; check overlap before spawning.
5. **COVID_VAX via PATIENT enrich** (gap 50, 10/60) — many missing cols
   are patient demographics tied to foundation Patient 20000000
   (NULL middle_name, SSN, etc.). Cascading effect on many datamarts.
   **CAUTION**: discuss with user before pursuing if it requires
   touching the foundation Patient row directly. Write to BLOCKED.md
   and stop the loop if unsure.
6. **AGGREGATE_REPORT_DATAMART** (0/42) — **BLOCKED on bug #11** (RTR
   schema mismatch). Skip.
7. **LAB100 / LAB101 / COVID_LAB_DATAMART / COVID_LAB_CELR_DATAMART** —
   needs lab-investigation linkage. The LAB_OBS_UIDS patch in
   merge_and_verify.sh:451 should help on next full verify. Plan a
   `bash scripts/merge_and_verify.sh` near loop end to confirm.
8. **LDF cluster** (tb_pam_ldf, var_pam_ldf, ldf_bmird, ldf_mumps,
   ldf_hepatitis, *_ldf_group siblings) — needs nrt_page_case_answer
   rows with `ldf_status_cd IN ('LDF_CREATE','LDF_PROCESSED','LDF_UPDATE')`.
   **Wait until TB/VAR/BMIRD agents finish** to avoid PHC overlap.
9. **D_TB_PAM expansion** — if agent E doesn't fill all 166 cols.
   Hold until E finishes.

### When the queue is empty

Survey `coverage/coverage_merged.md` for the next biggest gap:
```
awk -F'|' '/^\| dbo\./ {gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $5); if ($5 !~ /[*]/ && $5 ~ /\//) {split($5,a,"/"); if (a[1]+0 < a[2]+0 && a[1]+0 > 0) print (a[2]-a[1])"\t"$5"\t"$2}}' coverage/coverage_merged.md | sort -k1 -nr | head -10
```

Pick the next biggest gap and queue it.

## Spawning a new agent — prompt template

Use Agent tool with `isolation: "worktree"`, `run_in_background: true`,
and `subagent_type: "general-purpose"`. Prompt skeleton:

```
You are Agent <LETTER>, one of N parallel agents in a multi-agent loop.

## Goal
<one-sentence goal>. Lift dbo.<table> from X/Y to as high as possible
(target: +Z cols).

## CRITICAL — commit early, commit often
You're in a git worktree. After every meaningful step, `git add -A &&
git commit -m 'WIP: <what>'`.

## Your assigned UID block
22<NNNN>000 - 22<NNNN>999. Stay strictly within this range.

## Context
- Live DB at localhost:3433. SQLCMDPASSWORD=PizzaIsGood33!. Use `-I`
  flag on every sqlcmd.
- <related existing fixtures + relevant SP name(s) + reuse-PHC pointer>

## Required discovery steps (do FIRST)
1. Read related existing fixtures (cite paths).
2. Find the SP and verify its parameter signature via `grep -A 3
   "CREATE PROCEDURE.*sp_<name>" liquibase-service/...` — common
   pitfall: `@phc_id` vs `@phc_id_list` vs `@phc_uids`.
3. List unpopulated cols of target table using the per-column COUNT
   pattern.
4. Verify codes against `nrt_srte_Code_Value_General` for any coded
   answers — agent-C2's lesson: invalid codes silently collapse to NULL.

## Fixture authoring rules
- UIDs from 22<NNNN>000-22<NNNN>999.
- Reuse existing PHC where possible.
- Idempotent IF NOT EXISTS guards.
- Tail-EXEC the SP chain at bottom, wrap in TRY/CATCH.

## DB-touching work — USE THE LOCK
\`\`\`
source /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/scripts/db_lock.sh
acquire_db_lock "agent-<LETTER>"
trap 'release_db_lock "agent-<LETTER>"' EXIT
# DB work
release_db_lock "agent-<LETTER>"
trap - EXIT
\`\`\`
DO NOT use `with_db_lock <<HEREDOC` (known bug).

## What to deliver
1. Fixture file committed with WIP checkpoints.
2. Short final report (<300 words): before/after, SP+param signature,
   gotchas, ORCH_TODO if any.

DO NOT touch files outside your fixture. uid_ranges.md slot already
reserved by parent loop.
```

## Iterations log

(append one line per tick; format: `T+Xh Ym | iter N | <action> |
headline X.X% (Δ +Y) | in flight: M`)

T+0h 00m | iter 0 | Loop launched. 5 agents (E/F/G/H/I) in flight at start. Coverage 53.3% (2468/4627). Targets: TB cluster / STD / BMIRD / D_INV_REPEAT / MORB.
T+0h 39m | iter 1 | Agents E (TB cluster) + F (STD_HIV) completed and reconciled. Spawned J (hep100 unblock, 22016xxx) + K (case_lab_datamart, 22017xxx) to top up to 5 in flight (J, K, G, H, I). Coverage 53.3% → 67.1% (+13.8pp / +638 cols).

## End-of-loop note

(write here when loop ends: at hard stop, STOP_LOOP, or 3 consecutive
empty queue iterations.)
