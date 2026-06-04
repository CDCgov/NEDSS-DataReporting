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
