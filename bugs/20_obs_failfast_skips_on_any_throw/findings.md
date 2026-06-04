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
