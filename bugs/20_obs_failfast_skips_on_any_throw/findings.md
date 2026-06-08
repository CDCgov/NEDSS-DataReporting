# Bug #20: obs-batch fail-fast is intentional defer-and-retry design, NOT a bug (investigated, "fixed" with fault isolation, then reverted)

## Conclusion

This is not a bug. The obs-batch fail-fast in
`PostProcessingService.processIdCache` (~lines 749-799) is intentional
defer-and-retry-backfill design. It was investigated as a bug, a
fault-isolation "fix" was landed (commit 32566c8b on
`aw/fix-bug20-obs-failfast-isolation`, merged to remove-nrt), and then
reverted (revert commit c4882ef2) once review showed it was a semantic
change to intended behavior.

The real coverage poisons are the key-gen races (#17 and #26) and the
dynamic-datamart defect (#25). The fail-fast amplifies them: a poison
throw makes an entire CDC batch fail-fast, and innocent co-batched
entities are then deferred. Eliminating the poisons is the principled
fix; it leaves the intended design intact.

## How the fail-fast works (and why it is intentional)

`PostProcessingService.processIdCache` processes each CDC batch
fail-fast: the first entity whose SP throws sets `processingFailed=true`
and all lower-priority entities in that batch are skipped (priority
OBSERVATION=14 < CONTACT=15 < TREATMENT=16 < VACCINATION=17). A single
obs-SP throw anywhere in a batch defers downstream tables (`d_var_pam`,
`f_vaccination`, `covid_contact`, `morbidity_report`, `d_place`,
`lab_rpt_user_comment`); which table is affected depends on batch
composition and timing, which is the "coverage flakiness" (tables bounce
by ~100 cols run to run).

The skip is a deferral, not a drop. Deferred entities flow through a
fully-`@Scheduled` recovery machine: `retryCache` feeds
`processRetryCache` (which re-runs `processIdCache`); after `maxRetries`,
`processBackfills` runs `backfillEvent`, which re-queues STATUS_READY and
loops. That is at-least-once / eventual-consistency processing by design.

## What the collateral actually depends on

The key-gen fixes (bugs #17/#26) removed the race-driven flakiness, but
the fail-fast deferral itself remains and is triggered by batch
size/perturbation. Once a CDC poll batch is large enough that a residual
throw fires (sp_dyn_dm STD 50000/206, followup-obs NPE, aggregate 207),
all lower-priority entities in that batch are deferred, and which table
is the victim shifts run to run.

Demonstrated: a tick that added 3 fixtures (covid new-PHC 22071000, std
UPDATE of STD PHC, ldf new-entity) showed the victim move as the fixtures
were stripped: the full set deferred `morbidity_report_datamart` (130 to
0); minus std, the place tables (`d_inv_place_repeat` 44 to 1, `d_place`
37 to 31); ldf-only, `morb_rpt_user_comment` (8 to 0). Runs that added no
new PHCs, no new entity types, and no UPDATEs stayed under the threshold
and verified clean.

Consequence: zero-regression commits are impossible past ~77.6% for any
fixture that enlarges or perturbs the batch (new PHCs, new entity types
like LDF, UPDATEs of erroring-condition PHCs). The genuine wins (LDF +15
with 2 empty tables, covid_case +10, std_hiv +4) were quarantined as
`.gated-on-bug20-*` / `.suspect-bug20-*` pending the poison fixes.

Method note: verify with a raw git diff of coverage_merged.md
(`git diff HEAD -- .../coverage_merged.md | grep '^[+-]| dbo\.'`). An awk
split on the pop/total cell silently mis-parses `**bold**` fully-covered
cells and hides their regressions.

## The fault-isolation attempt (commit 32566c8b, reverted in c4882ef2)

A fault-isolation change was made in
`PostProcessingService.processIdCache`: each entity is processed
independently and a throw re-queues only the failed entity, not all
lower-priority ones. TDD:
`PostProcessingServiceRetryTest.testFaultIsolation_lowerPriorityEntityProcessedWhenHigherPriorityFails`
(RED before, GREEN after). Validated end-to-end at the time: re-landing
the 3 previously-collateral-causing fixtures (LDF +12 incl 2 empty
tables, covid_case +6 / investigation +4, std_hiv +4) produced zero
collateral, with `morbidity_report_datamart` (130/133),
`d_inv_place_repeat` (44/44), `d_place` (37/37), `l_inv_place_repeat`,
`morb_rpt_user_comment` (8/8), and `f_vaccination` all stable, where
every prior attempt had regressed one of them. Coverage moved 77.6% to
78.1%.

On review this was reverted (revert commit c4882ef2), because the change
was not a clean service fix:

- The batch fail-fast is intentional defer-and-retry, not a drop (the
  `retryCache` to `processRetryCache` to `processBackfills` to
  `backfillEvent` recovery machine described above). The fault-isolation
  change converted intentional batch-atomic retry into per-entity
  isolation, a semantic change with mixed effects: empirically it
  retained `d_var_pam`/place in the harness drain window (81.0%) but lost
  `d_interview_note` (0 vs 7 without it).
- The earlier `d_var_pam` causal story was wrong. `d_var_pam` is priority
  0, produced inside INVESTIGATION (priority 8) processing; the throws
  blamed (observation=14, notification=9) sort after it.

## Root cause: the poison throws, not the fail-fast

The root cause is the poison throws that make a batch fail-fast in the
first place, mostly bad-synthetic-data and robustness symptoms rather
than the fail-fast itself:

- bug #17 (key-gen race): real, fixed.
- bug #26 (notification key-gen race, sp_nrt_notification 2627): real,
  fixed.
- bug #25 (sp_dyn_dm_main/createdm STD 50000/206 date/float type clash):
  reproducible.
- other propagating SP errors: sp_aggregate_report (207),
  sp_nrt_notification 2627 PK dup on summary notification 22065010. These
  re-throw deterministically, so any innocent entity co-batched with them
  is starved until SUSPENDED, and that co-batching is timing-dependent
  (the observed "flakiness").
- bug #18 (followup-obs NPE): separately blocks lab101/CELR followup
  chains (followup_observation_uid stays NULL for non-'Order'-domain
  roots).

## Principled fix

Eliminate the poisons (fix the throwing SPs and the bad data) so no batch
ever poisons. Innocent entities are then never deferred, and coverage is
reached via the normal path with no service-semantic change.

With the fault-isolation reverted, measured coverage returns to ~78%
(flaky on `d_var_pam`/place depending on poison co-batching).
coverage_merged.md (81.0%) reflects the pre-revert run and is refreshed
after the poison fixes plus a fresh measurement.
