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

## LESSON 12 (KEYSTONE): the morb-515 throw + fail-fast skip is the real flakiness/lab-regression cause
LAB_REGRESSION_DIAGNOSIS.md: the service processes each ~20s CDC batch with a FAIL-FAST short-circuit
(PostProcessingService.processIdCache:749-799) — the first entity whose SP THROWS sets
processingFailed=true and ALL lower-priority entities are SKIPPED (priority OBSERVATION=14 < CONTACT=15
< TREATMENT=16 < VACCINATION=17). The morb foundation observation ALREADY throws Error 515
(MORBIDITY_REPORT_EVENT.PATIENT_KEY cannot be NULL) EVERY run (verified in job_flow_log). So whenever
contact/vaccination co-batch with that throwing OBSERVATION, they're skipped -> THIS is why covid_contact
/ d_contact_record / f_vaccination / d_place are "flaky" (not benign timing), and why the lab fixture's
+80 obs deterministically zeroed 6 tables (bigger batch -> guaranteed co-batch).
=> KEYSTONE FIX (item D + prerequisite for B + addresses #26): author the missing patient-subject link on
the morb report so sp_nrt_morbidity_report_postprocessing succeeds -> OBSERVATION stops throwing ->
contact/vaccination/lab never skipped -> those tables populate DETERMINISTICALLY. Lab fixture (B) also
needs its date-children remapped to {LAB334,349,350,356,357,361,362} via the FROM_TIME channel (routine
020 hard convert(datetime) throws otherwise). Spawned morb-fix agent (parallel with COVID-C).
- PHASE C (COVID) + KEYSTONE morb-fix COMMITTED: 68.2% -> 72.1% (+183 cols!), NO regressions.
  covid_case_datamart +54 (dedicated patient/provider/org 22055xxx + enriched PHC), covid_contact +51,
  d_contact_record +39, f_contact_record_case +11, morb_rpt_user_comment +8 (CLOSES #26), lab_rpt_user_comment
  +8, lab100 +5, d_place +6 (all the formerly-"flaky" tables now STABLE+populated - LESSON 12 confirmed:
  they were fail-fast-skipped by the morb-515 throw). morb 515 throw GONE. Phase B (lab) now safe.
- #26 marked complete (keystone closed it). tick: spawned Phase B (lab, now safe post-keystone:
  un-quarantine + date-children fix + harness ORCH_TODO) and STD-C (dedicated entities + PHC enrich
  22004000, UID 22057xxx) in parallel.
- Phase B (lab) RE-QUARANTINED (2nd regression): even post-keystone + date-fix, the lab fixture still
  triggers a throw -> fail-fast skip, zeroing covid_vaccination(-39)/f_vaccination(-6)/d_var_pam(-101)
  (lowest-priority entities). lab100 did +21 but collateral -146 >> gain. Date-fix (code-verified, not
  executed) was insufficient; the real throwing statement is elsewhere (sp_observation_event or
  017/d_lab_test). LAB DEFERRED for the night (~79 cols, repeatedly destabilizing, low ROI vs incremental
  P1/P2/P3). Keeping STD-C (std_hiv +10). Re-validating STD-C alone.
- STD-C COMMITTED (lab quarantined): 72.1% -> 72.2%. std_hiv_datamart +10 (178->188) via dedicated
  patient/provider/org (22057xxx) + PHC enrich. Quarantining lab RESTORED d_var_pam(127)/
  covid_vaccination(39)/f_vaccination(6) -> CONFIRMED lab fixture was the regressor. d_place -6 = flaky
  bounce (accepted). A/C done, D done (keystone), B deferred. Moving to incremental P1/P2/P3.
- INCREMENTAL wave 1: spawned TB-C dedicated entities (22058xxx -> tb_datamart/tb_hiv PATIENT_*/PHYS_*),
  std_hiv D_CASE_MANAGEMENT chain (22059xxx -> FL_*/INIT_*/OOJ_*/CA_*/SURV_*), d_inv_repeat more forms
  (22060xxx). 72.2% -> ceiling ~89%.
- INCREMENTAL wave-1 COMMITTED: 72.2% -> 74.1% (+85 cols). std_hiv-casemgmt: std_hiv_datamart +35
  (188->223) + d_case_management +25 (41->66). d_inv_repeat-more: d_investigation_repeat +19 (4 new
  forms TBRD/Monkeypox/Babesiosis/CarbonMonoxide, PHC_UIDS += 22060000/200/400/600). TB-C
  (zz_tb_dedicated_entities) COVERAGE-NEUTRAL (tb_datamart/tb_hiv unchanged - the ~25 TB gap is not
  PATIENT_*-shaped; kept as harmless additive fidelity). d_place +6 flaky. No regression.
- INCREMENTAL wave-2: spawned bmird-antimicrobial (22061xxx ~40), d_inv_place_repeat (22062xxx ~43),
  covid_contact-side (22063xxx ~43). 74.1% -> ceiling ~89%.

## LESSON 13 (2nd fail-fast trigger): "Followup Observations JSON array null" throw
Wave-2 caused d_var_pam -101 AGAIN (fail-fast skip). Service log: repeated ProcessObservationDataUtil
"Error processing Followup Observations JSON array from observation data: null" (OBSERVATION-priority
throw). bmird-antimicrobial's 45-obs graph enlarged the obs batch so a throwing obs co-batched with the
varicella entity -> skipped. This is a SECOND keystone-class latent throw (distinct from the morb-515
keystone): some observation's followup_observation structure is malformed/null and ProcessObservation
DataUtil chokes building the followup JSON. QUARANTINED zz_bmird_antimicrobial (batch-enlarger that
exposed it) -> kept d_inv_place_repeat(+43) + covid_contact-side(+25). NEXT KEYSTONE: find the obs with
the bad followup linkage (log referenced obs 22043149 / hepatitis range; could be bmird's own ItemToRow
graph producing a null followup) and fix the ODSE data so processObservation stops throwing -> re-land
bmird + immunize future obs-heavy fixtures. (Same class as morb-515: fix the throw, not the batch.)

## LESSON 13 CORRECTED + KEYSTONE #2: the "Followup Observations JSON array null" throw is PRE-EXISTING
With bmird-antimicrobial QUARANTINED, d_var_pam was STILL -101 and the "Followup Observations JSON array
null" / "Error processing observation data ... DataProcessingException" errors STILL fired (on COMMITTED
obs ids: 22048xxx zz_bmird_fill + 22043xxx hepatitis_case_chain + 20080xxx morb + 22022xxx covid-lab-unblock).
=> bmird-antimicrobial was WRONGLY blamed. The real cause is a PRE-EXISTING latent obs throw in
ProcessObservationDataUtil (building the Followup Observations JSON) that fail-fast-skips whichever
low-priority entity co-batches with it -> d_var_pam (varicella) is CHRONICALLY FLAKY 127<->26 (batch-timing),
same class as the morb-515 keystone. This injects +-100 measurement noise and blocks obs-heavy fixtures.
KEYSTONE #2 (spawned): find the obs whose followup_observation linkage is malformed/null (COMP/followup
act_relationship producing a null in the JSON) and fix its ODSE data so processObservation stops throwing
-> stabilizes d_var_pam/vaccination/contact AND lets bmird-antimicrobial + future obs fixtures land.
HOLDING the wave-2 commit (d_inv_place +43, covid_contact +25 are clean gains) until d_var_pam is stable
post-fix. bmird-antimicrobial stays quarantined pending the fix (NOT its fault).

## ===== ROUND 5 WOUND DOWN — final summary =====
**Result: 67.7% (R5 start) -> 75.6% (committed e0dfc3d1).** Session total across R4+R5: **14.0% -> 75.6%**
faithful, no-shortcut, no product/liquibase/seed edits.

### A-B-C-D status
- **A (IDENTITY refactor) DONE** (2ba4f24d): all flood-prone nbs_case_answer IDENTITY_INSERT -> auto-IDENTITY
  + distinguishing-key guards (LESSON 11). L10 hazard eliminated. Coverage-neutral. (varicella left hardcoded
  - below flood range, safe.)
- **C (dedicated patients + enriched PHCs) DONE**: COVID +54, STD +10/+35(casemgmt), TB-C (coverage-neutral).
- **D (covid_contact flakiness) DONE via the KEYSTONE morb-fix** (f26dc05b, +183, closed #26): PATSBJ link
  on morb Order 20080010 stopped the morb-515 throw -> fixed the 1st fail-fast skip.
- **B (lab100/101) DEFERRED + quarantined** — gated on bug #17 (below).

### Incremental gains (R5): std_hiv casemgmt +35/d_case_mgmt +25, d_investigation_repeat +~37 (8 new
forms: TB_LTBI/Trichinellosis/STEC/Cyclo/Salmonella/Malaria/TBRD/Monkeypox/Babesiosis/CarbonMonoxide),
d_inv_place_repeat +43, covid_contact +25, hepatitis +.

### THE GATING BLOCKER — bug #17 (out of bounds; needs YOUR call)
`sp_d_labtest_result_postprocessing`/`sp_d_lab_test_postprocessing` (routines 017/018) generate IDENTITY
keys for nrt_lab_test_result_group_key / nrt_lab_test_key with a NON-ATOMIC IDENT_CURRENT+RESEED+INSERT
pattern that RACES under concurrent processObservation -> intermittent Error 2627 (PK dup key 1) ->
DataProcessingException -> fail-fast skip of CONTACT/TREATMENT/VACCINATION-priority entities. This makes
d_var_pam + f_vaccination + covid_contact_datamart + lab_rpt_user_comment + lab100 + d_place +
d_contact_record FLAKY (±~100 cols run-to-run; the "74-76%" band reflects which ones got skipped). It also
blocks obs-heavy fixtures (lab Phase B, bmird-antimicrobial) from landing reliably. The morb-component
reclassification workaround did NOT fix it (race is also driven by the covid-lab obs) and broke lab tables
-> reverted. This is a ROUTINE concurrency bug, OUT OF BOUNDS for fixtures-only.

### Recommended next moves (need your decision)
1. **Fix bug #17 upstream** (atomic/idempotent key allocation in routines 017/018) -> stabilizes coverage
   measurement AND unlocks lab100/101 + bmird-antimicrobial (re-land both from _quarantine/). HIGHEST leverage.
2. Fix bug #18 (followup-obs NPE, cosmetic log noise) + bug #16 (covid lab LOINC seed) if pursuing those datamarts.
3. After #17: re-land bmird-antimicrobial (~+41) + lab100/101 (~+79) + resume incremental toward the ~89%
   fixtures-only ceiling (var/covid_lab/aggregate remain seed/bug out-of-bounds).

### Quarantined (NOT their fault — gated on bug #17): zz_lab100_101_fill.sql, zz_bmird_antimicrobial.sql.
Resumable: `rm utilities/comparison-fixtures/STOP_LOOP`, fix bug #17, then re-run /loop.

## ===== ROUND 5 RESUMED (bug #17 fixed) =====
- Bug #17 FIXED on this branch (aw/fix-bug17-labtest-keygen-race, commit 0fbda311): sp_getapplock
  serializes the lab key-gen in routines 017+018 (the race caused 2627/1205/silent-lost-inserts ->
  fail-fast skips -> the d_var_pam/obs-set flakiness). TDD'd (LabTestKeyGenConcurrencyTest: RED 149/960
  -> GREEN 960/960). => the obs fail-fast path is now closed; coverage should be STABLE + the obs-heavy
  fixtures can land. RE-LANDED zz_lab100_101_fill.sql (~+79) + zz_bmird_antimicrobial.sql (~+41) from
  quarantine. Barrier-merging to validate (expect coverage UP + d_var_pam stable at 127, no flaky skips).

## Round 6 (2026-06-04) — post key-gen-fix resume
All 3 key-gen defects fixed+merged to remove-nrt (db216afd): #17 race (sp_getapplock), #17 residual
(explicit alloc, key>=2), #19 LAB_TEST 547 (RECORD_STATUS_CD normalize). Verified err2627/1205=0,
err547=0. Isolated PR branch aw/labtest-keygen-fix (off main, fix-only, NOT opened). Filed bug #20
(obs fail-fast = the flakiness root; recommend service fault-isolation). lab100/101 + bmird stay
quarantined (.gated-on-obs-failfast) until #20. RESUME loop on NON-OBS-HEAVY targets (investigation/
answer/notification-driven only — adding observations re-trips #18 + STD dyn-datamart throws → fail-fast
collateral). Run until the user stops it (no plateau auto-wind-down). Targets: d_investigation_repeat
forms, summary_report_case/sr100, tb non-PATIENT gap, then more investigation/condition tails.

### R6 tick 1 (2026-06-04, post key-gen-fix) — net +34, 75.6%->76.3%, ZERO regressions
First clean net-positive since the key-gen fixes: flakiness GONE (d_var_pam STABLE, no fail-fast
collateral), err2627/1205=0, err547=0, 53 "No ids" idle. Landed: d_investigation_repeat +24 (_OTH
free-text cols via OTH^ answers, group-4 guard, 6 page-builder PHCs); tb_datamart +3 / tb_hiv_datamart
+3 / d_tb_pam +3 (RVCT PRIMARY_GUARD_1/2_BIRTH_COUNTRY + INIT_REGIMEN_START_DATE on PHC 22050000);
hepatitis_datamart +1. WIP (uncommitted): zz_summary_report_case.sql + PHC_UIDS 22065000 — upstream
chain CORRECT (ODSE PHC case_type='S' 10110, nrt_investigation_notification=1, SummaryNotification
investigation-observation present) but SUMMARY_REPORT_CASE/SR100 stay 0; only sp_inv_summary_datamart
ran, not sp_summary_report_case/sp_sr100 -> they appear not wired into merge_and_verify Step-9 (or need
EVENT_METRIC first). Next tick: debug-agent to wire/trigger the summary report-case + sr100 SPs.

### R6 tick 2 (2026-06-04) — net +59, 76.3%->77.6%, ZERO regressions; 2 empty tables filled
Landed: summary_report_case 0->11 + sr100 0->19 (via new merge_and_verify Step 8.7 run_summary_datamarts
backstop — realizes the documented Merge-contract Step 9; needed because the service races on summary
cases mid-drain, filed bug #21; SR100 also needed fixture rpt_to_state_time to clear NOT-NULL Error 515),
hepatitis_datamart +21 (D_INV_EPIDEMIOLOGY/TRAVEL/VACCINATION single-dim answers on Hep-A PHC 20000100),
d_investigation_repeat +8 (8 more _OTH cols at group-5, PHCs 22003000/22049000/22047000/22007000/22004000).
err2627/1205=0 err547=0, d_var_pam stable. NOTE: summary/sr100 coverage is harness-Step-8.7-assisted
(documented, transparent) pending the bug #21 service-timing fix.

### R6 tick 3 (2026-06-04) — HIT THE BUG #20 BATCH CEILING; reverted to clean 77.6%
Targeted LDF subsystem + std_hiv + covid_case. All THREE landed real gains (LDF +15 incl 2 empty
tables org/patient_ldf_group 0->3/3; covid_case +6/investigation +4; std_hiv +4) BUT each enlarges/
perturbs the CDC batch past the bug #20 fail-fast threshold -> non-deterministic collateral on a
shifting low-priority victim (full set: morbidity_report_datamart 130->0; minus std: place tables
d_inv_place_repeat 44->1 + d_place 37->31; ldf-only: morb_rpt_user_comment 8->0). Bisected by serial
quarantine; confirmed it is BATCH-SIZE-sensitive, not a single culprit. Ticks 1-2 (answer-only, smaller)
verified genuinely clean via RAW git diff. DECISION: reverted all 3 fixtures to _quarantine
(.gated-on-bug20-* / .suspect-bug20-*) + restored committed coverage; net committed gain this tick = 0.
Filed bug #22 (LDF source + seed/chain gating) + updated bug #20 (batch-size collateral + the awk-bold
verification blindspot -> use raw git diff). The high-value remaining wins (LDF/covid/std, + the obs-heavy
lab/bmird) are ALL gated on the bug #20 service fault-isolation fix. Session committed total: 75.6%->77.6%
(ticks 1-2). PAUSED for a user decision on bug #20 (the durable unblock).

### R6 tick 4 (2026-06-04) — BUG #20 FIXED + validated; +26, 77.6%->78.1%, ZERO collateral
Fixed bug #20 (PostProcessingService fault isolation, commit 32566c8b, TDD-proven, merged to remove-nrt).
Re-landed the 3 quarantined fixtures (LDF org/patient_ldf_group 0->3/3 + ldf_data ->15; covid_case ->378
+ investigation ->67; std_hiv ->227) — ALL landed together with ZERO collateral (morbidity/place-repeat/
morb_rpt_user_comment/f_vaccination all STABLE), proving the fault isolation eliminated the batch fail-fast
collateral that blocked every prior tick-3 attempt. err2627/1205=0, err547=0, idle-drained. Verified with
RAW git diff. NEXT: the obs-heavy lab100/101 + bmird (still in _quarantine .gated-on-obs-failfast, +120)
are now UNBLOCKED — re-land them; ceiling rises toward ~85-89%.

### R6 tick 5 (2026-06-04) — OBS-HEAVY re-land lands; +66, 78.1%->79.5%, d_var_pam STABLE
The culmination of the bug #17/#19/#20 arc: re-landed the obs-heavy lab100/101 + bmird fixtures (the
ORIGINAL bug #20 casualties). bmird_strep_pneumo_datamart 78->119 (+41), lab100 36->57 (+21),
ldf_dimensional_data 9->12, lab_test +1. ZERO collateral — d_var_pam STABLE at 127 (the chronic victim
that bounced +-100 all effort), f_vaccination/covid_contact/morbidity/morb_rpt_user_comment/place all
stable. err2627/1205=0, err547=0, idle-drained, raw-diff verified. Proves the full root-cause chain:
fault isolation (bug #20) means the obs-batch throw no longer skips lower-priority entities. NOTE:
lab101 stayed 0/46 (separate gap — needs more than zz_lab100_101_fill provides; not a regression).

### R6 tick 6 (2026-06-04) — covid_vaccination + contact land; +49, 79.5%->80.5%, d_var_pam stable
Crossed 80%. covid_vaccination_datamart 39->59 (+20, full ODSE vaccination chain), covid_contact_datamart
76->90 (+14) + d_contact_record 40->55 (+15, via CT_CONTACT_ANSWER -> nrt_metadata_columns pivot — found
CT_CONTACT_ANSWER was empty). d_var_pam STABLE at 127. Quarantined zz_lab101_fill.sql (partial +5/46 AND
its big 'Order'-root lab chain tipped d_var_pam -101 under batch volume — a residual skip beyond the
processIdCache fault-isolation; revisit as a bug #20 follow-up: check processCdCache/processDatamartIds).
Notes (minor residuals, NOT fixture defects): case_lab_datamart bounces +-2 and a single
sp_nrt_notification_postprocessing 2627 on the summary notification 22065010 persist — small residual
flakiness vs the old +-100 d_var_pam swings. The zz_var_datamart_enrich CONFIRMATION_METHOD FK 547 seen
mid-debug was TRANSIENT (dim-ordering race), not deterministic — applied clean on retry. Two contact
IDENTITY traps fixed (ct_contact_answer needed SET IDENTITY_INSERT). Block 22072xxx/22073xxx.

### R6 tick 7 (2026-06-04) — interview + hepatitis-tail; +24, 80.5%->81.0%, d_var_pam stable
d_interview 18->24 (FULLY covered — 6 LDF-pivot cols via 6 nbs_answer on interview 20090010; ORCH: added
post-Tier-3 run_interview_chain 'Step 8.8'). hepatitis_datamart 182->198 (+16 D_INV_RISK_FACTOR 9 +
D_INV_MOTHER 7 via 2 new Hep-B PHCs 22076000/22076100 added to PHC_UIDS). case_lab_datamart 33->35
(recovered — confirms the +-2 bounce is flaky noise, not a fixture defect). d_var_pam STABLE 127, no
regressions, raw-diff verified. NOTE: d_interview_note stayed 0/7 (the IXS111 note-answer path didn't
populate — needs more than the single note answer; minor follow-up).
