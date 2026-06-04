# Coverage recovery loop — Round 5 (overnight, autonomous, NO-SHORTCUT)

**Active control doc.** Builds directly on `LOOP_round4.md` (which drove 14.0% -> **67.7%** and holds
the architecture cheat-sheet + LESSONS 1-10 — READ IT TOO). Branch: `aw/remove-nrt-shortcut`.
Committed baseline at start of R5: **67.7%** (commit 415f324a/4e88062c).

**Goal:** chase **90%**. First execute the four ordered work items **A -> B -> C -> D** below (each
unblocks or unlocks a big chunk and several are prerequisites for safe further work), THEN resume
incremental P1/P2/P3 gap-filling toward 90%.

**User decisions (carried + extended):**
- **Mixed fidelity**; real for COVID/STD/TB/hepatitis, generic for the tail.
- **FIXTURES-ONLY for data**: no `nrt_*` INSERTs, no `EXEC sp_*` IN FIXTURES, no liquibase/routine
  edits, no DB-seed/SRTE edits. **EXCEPTION (sanctioned this round): the test harness
  `scripts/merge_and_verify.sh` MAY be edited** (it already orchestrates SP runs) — needed for item B.
- **Additive**: new UID-block entities; **never UPDATE shared dims** (D_PATIENT/D_PROVIDER/
  D_ORGANIZATION foundation rows / shared USER_PROFILE). Item C satisfies the "richer patient/provider"
  need ADDITIVELY by authoring DEDICATED per-investigation entities, NOT by UPDATEing shared ones.
- Aim 90%, but it's fine to wind down if truly exhausted (see Stop conditions).

## Carried-forward critical lessons (full text in LOOP_round4.md)
- **L8**: trust coverage ONLY after the service is idle (>=3 "No ids to process"). A drop with service
  idle = REAL regression (quarantine offender); a drop with service NOT idle = drain-timeout (re-measure).
- **L9**: single `D_INV_*` dims build only from `nbs_case_answer` with `answer_group_seq_nbr IS NULL`;
  repeating-block datamart cols (`_1/_2/_3`) need group 1/2/3.
- **L10**: hardcoded `IDENTITY_INSERT` on a high-volume IDENTITY table (nbs_case_answer, observation,
  act, ...) collides once auto-IDENTITY inserts flood `IDENT_CURRENT` past it -> the `IF NOT EXISTS`
  guard sees the auto-row and SILENTLY SKIPS the block. **This is exactly what item A eliminates.**
- Merge/sentinel/barrier mechanics: see "Per-iteration protocol" below (NEVER pgrep merge_and_verify.sh).

## ===== ORDERED WORK ITEMS (do A first; each validated by a clean barrier merge) =====

### A. Refactor the suite off hardcoded IDENTITY_INSERT  (PREREQUISITE — unblocks B, C, and all further answer/obs fixtures)
The L10 hazard makes every new answer/obs fixture risk silently breaking an older one. Eliminate it.
- **A.0 (survey, 1 read-only agent):** inventory EVERY `SET IDENTITY_INSERT ... ON` across
  `fixtures/**` (foundation + tiers). For each block record: file, table, the hardcoded UID range, and
  whether those literal UIDs are REFERENCED elsewhere in the suite (grep the literals across fixtures +
  scripts). Classify: **LEAF** (UID not referenced downstream — e.g. most nbs_case_answer) vs
  **REFERENCED** (UID used as an FK/branch_id/act_id/participation target). Write
  `utilities/comparison-fixtures/IDENTITY_REFACTOR_PLAN.md`. Confirm which tables are IDENTITY +
  high-volume/flood-prone (definitely nbs_case_answer; check observation, act, nbs_act_entity, case_management).
- **A.1..n (convert, batched + validated):**
  - LEAF blocks -> drop `IDENTITY_INSERT`, let IDENTITY auto-assign, change the `IF NOT EXISTS` guard
    from a hardcoded UID to the NATURAL key (e.g. `act_uid + nbs_question_uid (+ seq/group)` for
    nbs_case_answer; the appropriate business key for observation/act). (This is the R4-M fix pattern.)
  - REFERENCED blocks -> rewrite to capture the assigned id (`DECLARE @x bigint; ... ; SET @x=SCOPE_IDENTITY();`
    or an `OUTPUT inserted.<uid>` into a temp/table var) and use `@x` everywhere the literal was used,
    INSTEAD of a hardcoded UID. If a block genuinely cannot be de-hardcoded safely, relocate its UIDs to a
    reserved HIGH range guaranteed above any auto value AND document why.
  - Convert in SMALL batches (by tier or by table). After each batch run a barrier merge: the refactor is
    **coverage-NEUTRAL** — it must HOLD >=67.7% with no table regressing. If a batch drops coverage,
    that batch is wrong (a converted block now mis-links or skips) -> revert/fix that batch, re-validate.
  - **A is DONE** when no hardcoded `IDENTITY_INSERT` remains on the flood-prone IDENTITY tables AND a
    clean merge holds >=67.7% with no regression. Journal it.

### B. Lab100/101 harness rework  (~79 cols: lab100 33 + lab101 46)
- Un-quarantine `_quarantine/zz_lab100_101_fill.sql.identity-flood-regresses-obs-tables` -> back to
  `fixtures/30_sp_coverage/zz_lab100_101_fill.sql` (now safe post-A). Apply its ORCH_TODO in
  `scripts/merge_and_verify.sh` (harness edit SANCTIONED): add its obs UIDs (22053010,22053011,22053500,
  22053501,22053502) to `run_lab_chain()`'s `sp_observation_event` + lab-postprocessing `@obs_ids` lists
  and to `LAB_OBS_UIDS`; AND add a re-run of `sp_d_lab_test_postprocessing` + `sp_d_labtest_result_postprocessing`
  with the extended `@obs_ids` AFTER the Step-9 Tier-3 drain and BEFORE the lab100/101 datamart SPs
  (LAB_TEST is built at Step 5/7, before Tier-3 lab obs exist — that's why lab101 was 0). Validate ->
  lab100/101 populate, no regression. (Full snippet in the fixture header.)

### C. Dedicated patients + enriched PHCs for COVID/STD (+ others)  (the "shared-dim" tails, done ADDITIVELY)
Root cause (verified): only **2 distinct patients** back all ~20 investigations (foundation 20000000 /
20020010), and that person row is demographically sparse -> every datamart's `PATIENT_*`/`PHYS_*`/`RPT_*`
read NULL. FIX additively (NOT by UPDATEing shared dims):
- For COVID 22003000 and STD 22004000 (then TB/hepatitis/others): author a NEW dedicated, richly-attributed
  `person` (full name/middle/suffix, phones, address, race detail, ethnicity, DOB) + dedicated `provider`
  person(s) + `organization` in the investigation's UID block, and link them via that investigation's
  `SubjOfPHC` / `InvestgrOfPHC` / `PhysicianOfPHC` / reporter / hospital participations (REPLACING the
  shared-foundation links for that investigation — additive new entities, no shared-dim UPDATE). The
  pipeline builds new D_PATIENT/D_PROVIDER/D_ORGANIZATION rows -> `PATIENT_*`/`PHYS_*`/`RPT_*` fill.
- ALSO enrich each investigation's OWN `public_health_case` INSERT (per-investigation row, allowed) with the
  PHC-core scalars currently NULL: hospitalization (HSPTL_*/HSPTLIZD), DIAGNOSIS_DATE, ILLNESS_ONSET_*,
  IMPORT_FROM_* , TRANSMISSION_MODE, DETECTION_METHOD, CONFIRMATION_*, OUTBREAK, DAYCARE, FOOD, DIE_*, etc.
  (covid_case ~34 such cols; std_hiv has an analogous PHC-core set + the D_CASE_MANAGEMENT chunk which is a
  separate SP path — sp_nrt_case_management_postprocessing — author that chain if pursuing std_hiv's FL_*/
  INIT_*/OOJ_*/CA_*/SURV_* ~32 cols).
- Parallelizable across investigations (one agent each). Validate per barrier merge.

### D. Stabilize covid_contact_datamart flakiness
covid_contact populated at one tick (1 row) and was 0 at the next with the SAME committed fixture =>
timing race: the `CT_contact` CDC event / `sp_contact_record_event` isn't reliably processed within the
Tier-3 drain before the datamart SP runs. Diagnose (does `wait_for_pipeline_drain` cover the contact
topic? is the contact event processed at all on a clean run? is `nrt_contact` present at coverage time?)
and stabilize — e.g. ensure the contact chain is drained/ordered deterministically (harness edit OK), or
the fixture re-triggers reliably. Goal: covid_contact_datamart consistently >=1 row across runs.

### THEN: incremental P1/P2/P3 toward 90%
Once A-D land, resume the round-4 gap-survey loop: biggest reachable gap each tick (skip OUT-OF-BOUNDS
below), author additive ODSE chains (now collision-safe post-A), validate, commit net-positive.
Remaining reachable buckets: bmird antimicrobial graph (~40), d_case_management/d_contact_record,
d_inv_place_repeat, sr100/summary_report_case, more d_investigation_repeat forms, LDF-flagged tables,
covid_vaccination/std/covid tails via item C.

## OUT OF BOUNDS (do not chase; fixtures-only) — ~494 cols / ~11pts
`var_datamart` (231; SRTE PORT_REQ_IND_CD), `covid_lab_datamart`+`covid_lab_celr_datamart` (221; SRTE
`nrt_srte_Loinc_condition` cond 11065, bug #16), `aggregate_report_datamart` (42; RTR bug #11), `f_var_pam`.
=> 90% is NOT reachable without lifting these; realistic fixtures-only ceiling ~89% IF A-D + all reachable
land. If incremental work plateaus below that, that's the ceiling — wind down (don't thrash).

## Stop / wind-down conditions (check at top of every firing)
1. `utilities/comparison-fixtures/STOP_LOOP` exists -> final journal note, STOP (omit ScheduleWakeup).
2. 90% reached -> success note, STOP.
3. After A-D complete: 3 consecutive incremental ticks net <~0.5pt (above measurement noise) -> write a
   final summary + recommendations, PushNotification one-liner, STOP.
4. `merge_and_verify` fails twice in a row -> write `BLOCKED.md`, STOP.
5. Iteration cap: 40 firings (running count in journal).

## Per-iteration protocol (each firing)
1. **Read this file + LOOP_round4.md lessons.** Check stop conditions.
2. **Determine current phase** from the journal (A.0 / A.batch-n / B / C / D / incremental). Reconcile any
   finished authoring/survey agents (verify ODSE-only: no `nrt_*` INSERT, no `EXEC sp_` IN FIXTURES;
   harness edits to merge_and_verify.sh are OK for B/D). Apply simple PHC_UIDS ORCH_TODOs.
3. **BARRIER (validate)** — only when NO authoring agent is in flight AND no merge running
   (verify: `ps -eo pid,args | grep 'bash [^ ]*merge_and_verify.sh' | grep -v 'bash -c' | grep -v grep`):
   `rm -f /tmp/loop_merge.done; nohup bash -c 'bash scripts/merge_and_verify.sh && bash scripts/coverage_summary.sh; echo EXIT=$? > /tmp/loop_merge.done' >/tmp/loop_merge.log 2>&1 &`
   then a HARNESS-TRACKED `run_in_background` Bash polling `while [ ! -f /tmp/loop_merge.done ]; do sleep 20; done`
   (NEVER pgrep merge_and_verify.sh — it self-matches and hangs). When done: confirm service idle (L8);
   commit if net-positive/coverage-neutral-as-intended with no regression, else quarantine the offender
   (move to `_quarantine/<name>.<reason>`) and re-validate. For phase A, "success" = HOLD >=67.7% (neutral).
4. **Advance the phase** or do the next batch. Top up to ~3 background agents (file-writing + read-only DB
   only; reserve UID blocks in `catalog/uid_ranges.md` + below SAME turn). Two agents never touch the same file/table.
5. **Journal one line** below. **ScheduleWakeup ~1800s**, prompt = the `/loop ...` input verbatim.

## Hard rules
- No `nrt_*` INSERTs, no `EXEC sp_*` in fixtures, no liquibase/routine/seed/SRTE edits. (merge_and_verify.sh
  harness edits OK this round for B/D.) Additive UID-block entities; omit GENERATED ALWAYS period cols;
  never UPDATE shared dims. One bad fixture -> quarantine, never mass-revert. Don't message the user mid-loop
  (write BLOCKED.md if stuck). No AskUserQuestion.

## Available UID blocks (Round 5) — reserve here + in catalog/uid_ranges.md same turn
| Block | Status |
| --- | --- |
| 22055000 - 22055999 | free |
| 22056000 - 22056999 | free |
| 22057000 - 22057999 | free |
| 22058000 - 22058999 | free |
| 22059000 - 22059999 | free |
| 22060000+ | add a row to catalog/uid_ranges.md when allocated |

## Iterations journal
- R5 baseline: 67.7% (415f324a). Plan A->B->C->D then incremental. STOP_LOOP cleared to start.
- A.0 survey done (IDENTITY_REFACTOR_PLAN.md): 42 IDENTITY_INSERT blocks, 40 LEAF / 0 truly REFERENCED
  (0 FKs to these PKs). Flood-prone = nbs_case_answer ONLY (case_management/nbs_act_entity have no auto
  source -> out of scope this pass). All convert via R4-M pattern (auto-IDENTITY + natural-key guard),
  coverage-neutral. A.1 spawned: 1 agent converting ALL ~18 nbs_case_answer IDENTITY_INSERT blocks
  (incl. zz_var_datamart_enrich UPDATE repointing). Validate next tick: merge must HOLD >=67.7%.

## LESSON 11 (Phase-A fix-up): natural-key guards must include the DISTINGUISHING column
Converting nbs_case_answer IDENTITY_INSERT->auto requires a new idempotency guard. A guard of just
`IF NOT EXISTS(act_uid=X AND nbs_question_uid=Q)` is WRONG when another fixture answers the same
(act,Q) with a different answer_group_seq_nbr/seq — chiefly zz_page_answers_datamart_routing.sql,
which answers ALL mapped questions of the form at answer_group_seq_nbr=0 and sorts BEFORE the *_fill
files. The guard then matches page_answers' row -> the whole block SILENTLY SKIPS (saw std_hiv_datamart
167->66, inv_hiv 17->2). FIX: each block's guard must match ONLY its own rows by adding the
distinguishing column: single-dim fills (std_hiv_fill, hepatitis_datamart_fill2) use
`AND answer_group_seq_nbr IS NULL`; repeating fills (covid_case_fill, d_inv_repeat_fill/fill2) use the
block's `AND answer_group_seq_nbr = 1` (or its group). (Validate by checking whether any earlier
fixture answers the guard's (act,Q) at a different group.)
- Phase-A validation merge: 67.5% (net -0.2) but per-table delta exposed std_hiv -101 / inv_hiv -15
  (masked by flaky covid_contact +42, d_contact_record +39 returning). NOT committed. Spawning guard fix-up.
- PHASE A DONE: re-validation #2 = 68.2% (net +22 vs 67.7%), std_hiv restored 167->178, d_var_pam
  restored (varicella reverted to safe-hardcoded - it's below the auto-IDENTITY flood range so was never
  at risk; converting it had regressed d_var_pam -101). 8 files converted to auto-IDENTITY+distinguishing
  guards (covid/tb full_chain, zz_covid_case_fill, zz_d_inv_repeat_fill, zz_d_inv_repeat_fill2,
  zz_hepatitis_datamart_enrich, zz_std_hiv_fill, zz_tb_datamart_enrich); varicella_full_chain +
  zz_var_datamart_enrich intentionally left hardcoded (below flood, collision-safe). L10 hazard
  eliminated for all flood-range nbs_case_answer blocks. d_place -6 = FLAKY (3rd timing-variant dim
  with covid_contact/d_contact_record; went 37->37->31 across runs independent of fixture changes).
- Phase B BLOCKED on re-diagnosis: the tick5 lab-fixture regression (6 obs tables emptied) was
  MIS-attributed to IDENTITY flood, but observation/act are NOT identity columns (survey) -> real cause
  unknown. Re-quarantined zz_lab100_101_fill.sql (.regresses-6-obs-tables-cause-TBD); spawned read-only
  B-diagnosis agent. Proceeding with Phase C (COVID dedicated patient+PHC, 22055xxx) in parallel.
