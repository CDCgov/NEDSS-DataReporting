# Bug #20 — service fail-fast skips ALL lower-priority entities on ANY obs-batch throw (the real flakiness root)

`PostProcessingService.processIdCache` (~lines 749-799) processes each CDC batch FAIL-FAST: the first
entity whose SP throws sets processingFailed=true and ALL lower-priority entities are SKIPPED
(priority OBSERVATION=14 < CONTACT=15 < TREATMENT=16 < VACCINATION=17 ...). A single obs-SP throw
anywhere in a batch silently zeroes downstream tables (d_var_pam / f_vaccination / covid_contact /
morbidity_report / d_place / lab_rpt_user_comment); WHICH table is hit depends on batch composition &
timing -> the "coverage flakiness" (tables bounce +-~100 cols run to run).

Throw sources found (fixing each individually = whack-a-mole; the durable fix is the fail-fast design):
- Bug #17 (key-gen race; nrt_lab_test_result_group_key / nrt_lab_test_key) — FIXED (0fbda311 + 7e9ad25d).
- Bug #19 (LAB_TEST RECORD_STATUS_CD 547) — FIXED (722244b).
- Bug #18 (Followup Observations JSON array NPE in ProcessObservationDataUtil) — still firing.
- STD dynamic-datamart SP errors: sp_dyn_dm_main_postprocessing STD (Error 50000 @ line 715) +
  sp_dyn_dm_createdm_postprocessing STD UPDATING DM_INV_STD (Error 206 operand type clash).

RECOMMENDATION (durable fix; a SERVICE change beyond fixtures/routines): make obs-batch processing
fault-ISOLATED — one entity/SP throw must not skip unrelated lower-priority entities (catch & continue
per entity). Then the quarantined obs-heavy fixtures (lab100/101 + bmird-antimicrobial, ~+120 cols,
.gated-on-obs-failfast) land cleanly AND coverage measurement is stable. Until then they stay
quarantined and d_var_pam/morbidity etc. remain flaky.

## Update (R6 tick 3, 2026-06-04) — the collateral is BATCH-SIZE-SENSITIVE and victim is non-deterministic
The key-gen fixes (bugs #17/#19) removed the RACE-driven flakiness, but the fail-fast collateral itself
remains and is triggered purely by batch size/perturbation: once a CDC poll batch is large enough that a
residual throw fires (sp_dyn_dm STD 50000/206, followup-obs NPE, aggregate 207), ALL lower-priority
entities in that batch are skipped — and WHICH table is the victim shifts run to run. Demonstrated:
tick-3 added 3 fixtures (covid new-PHC 22071000, std UPDATE of STD PHC, ldf new-entity); as I stripped
them the regression shrank and the victim moved: full set -> morbidity_report_datamart 130->0; minus std
-> place tables (d_inv_place_repeat 44->1, d_place 37->31); ldf-only -> morb_rpt_user_comment 8->0. The
answer-only ticks 1-2 (no new PHCs / no new entity types / no UPDATEs) stayed UNDER the threshold and
were verified clean. CONSEQUENCE: zero-regression commits are impossible past ~77.6% for any fixture that
enlarges/perturbs the batch (new PHCs, new entity types like LDF, UPDATEs of erroring-condition PHCs) —
the genuine wins LDF (+15, 2 empty tables), covid_case (+10), std_hiv (+4) are all quarantined
.gated-on-bug20-* / .suspect-bug20-* pending the service fault-isolation fix. METHOD NOTE: verify with a
RAW git diff of coverage_merged.md (git diff HEAD -- .../coverage_merged.md | grep '^[+-]| dbo\.') — an
awk split on the pop/total cell silently mis-parses **bold** fully-covered cells and hides their regressions.

## RESOLVED (2026-06-04, commit 32566c8b on aw/fix-bug20-obs-failfast-isolation, merged to remove-nrt)
FIXED via fault isolation in PostProcessingService.processIdCache: each entity is now processed
independently and a throw re-queues ONLY the failed entity (not all lower-priority ones). TDD:
PostProcessingServiceRetryTest.testFaultIsolation_lowerPriorityEntityProcessedWhenHigherPriorityFails
(RED before, GREEN after). VALIDATED END-TO-END: re-landing the 3 previously-collateral-causing fixtures
(LDF +12 incl 2 empty tables, covid_case +6/investigation +4, std_hiv +4) now produces ZERO collateral —
morbidity_report_datamart (130/133), d_inv_place_repeat (44/44), d_place (37/37), l_inv_place_repeat,
morb_rpt_user_comment (8/8), f_vaccination all STABLE — where every prior attempt regressed one of them.
Coverage 77.6%->78.1%. This also unblocks the obs-heavy lab100/101 + bmird fixtures (quarantined
.gated-on-obs-failfast) for re-landing.

## RE-CHARACTERIZED + REVERTED (2026-06-04, revert commit c4882ef2)
On review this is NOT a clean service bug, and the "fix" was reverted. Evidence:
- The batch fail-fast is INTENTIONAL defer-and-retry, not a drop: deferred entities flow through a
  deliberate fully-@Scheduled recovery machine — retryCache -> processRetryCache (re-runs
  processIdCache) -> after maxRetries -> processBackfills -> backfillEvent re-queues STATUS_READY ->
  loop. That is at-least-once / eventual-consistency by design.
- The fault-isolation change converted intentional batch-atomic retry into per-entity isolation — a
  semantic change, and one with mixed effects (empirically it RETAINED d_var_pam/place in the harness
  drain window [81.0%] but LOST d_interview_note [0 vs 7 without it]).
- The earlier d_var_pam causal story was wrong: d_var_pam is priority 0, produced inside INVESTIGATION
  (priority 8) processing; the throws blamed (observation=14, notification=9) sort AFTER it.

ROOT CAUSE is the POISON throws that make a batch fail-fast in the first place — mostly bad-synthetic-
data / robustness symptoms, NOT the fail-fast itself:
- bug #17 (key-gen race) — real, fixed.
- propagating SP errors: sp_dyn_dm_main/createdm STD (50000/206), sp_aggregate_report (207),
  sp_nrt_notification 2627 (PK dup on summary notification 22065010). These re-throw deterministically,
  so any innocent entity co-batched with them is starved until SUSPENDED — that co-batching is
  timing-dependent (the observed "flakiness").
- bug #18 (followup-obs NPE) — separately blocks lab101/CELR followup chains (followup_observation_uid
  stays NULL for non-'Order'-domain roots).

PRINCIPLED FIX (keeps the intended design): eliminate the poisons (fix the throwing SPs / bad data),
so no batch ever poisons -> innocents never deferred -> coverage reached via the normal path with no
service-semantic change. Pursuing bug #18 first (it also unblocks obs-heavy lab coverage).

NOTE: with the fault-isolation reverted, measured coverage returns to ~78% (flaky on d_var_pam/place
depending on poison co-batching). coverage_merged.md (81.0%) reflects the pre-revert run and will be
refreshed after the poison fixes + a fresh measurement.
