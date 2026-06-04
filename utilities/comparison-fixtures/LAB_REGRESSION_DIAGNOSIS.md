# LAB100/101 fixture regression — root-cause diagnosis (Phase-B, Round 5)

Read-only investigation of why un-quarantining
`fixtures/30_sp_coverage/zz_lab100_101_fill.sql` regresses SIX tables to empty
(covid_contact_datamart, covid_vaccination_datamart, f_contact_record_case,
f_vaccination, lab100, lab_rpt_user_comment).

The original "IDENTITY flood on `observation`/`act`" explanation (LESSON 10) is
**wrong** — `observation` and `act` are not IDENTITY columns, and the fixture
uses explicit non-colliding UIDs (22053xxx). The real cause is different and is
proven below.

---

## TL;DR root cause

The pipeline is now **fully CDC/service-driven** (the manual `EXEC sp_*` chain
functions `run_lab_chain`/`run_vaccination_chain`/`run_contact_chain`/… in
`scripts/merge_and_verify.sh` are **dead code — never called by `main()`**;
`main()` only applies fixtures tier-by-tier and lets the
reporting-pipeline-service consume CDC events). The service batches all CDC ids
that arrive in a ~20 s window (`service.fixed-delay.cached-ids = 20000`,
`application.yaml:106`) and processes them in one `processIdCache(...)` pass.

That pass has a **fail-fast short-circuit**: the first entity whose stored proc
throws sets `processingFailed = true` and **all lower-priority entities in the
same batch are skipped** (pushed to the retry/dead-letter cache), and the
datamart fan-out (`dmProcessor.process(dmData)`) only ever sees the `dmData`
accumulated *before* the failure. See
`PostProcessingService.processIdCache` lines 749-799:

```java
boolean processingFailed = false;
for (Entry<String,List<Long>> entry : sortedEntries) {   // sorted by Entity.priority ASC
  if (processingFailed) { ...retryCache.add(ids); continue; }   // SKIP the rest
  try { processEntity(...); }
  catch (Exception e) { processingFailed = true; buildRetryCache(...); }
}
...
dmProcessor.process(dmData);   // only the pre-failure dmData
```

`Entity` priority order (`Entity.java:22-25`):

| priority | entity      | builds |
| --- | --- | --- |
| 14 | **OBSERVATION** | LAB_TEST / LAB_RESULT_VAL / **lab100** / **lab_rpt_user_comment** / lab101 (and morb report) |
| 15 | **CONTACT**     | D_CONTACT_RECORD / **f_contact_record_case** |
| 16 | TREATMENT       | treatment |
| 17 | **VACCINATION** | D_VACCINATION / **f_vaccination** |

`processObservation` (priority 14) runs **morb first, then lab** in one call
(`PostProcessingService.java:1234-1278`). When OBSERVATION throws, CONTACT(15),
TREATMENT(16) and VACCINATION(17) are all skipped for that batch, and the
covid_contact / covid_vaccination datamarts (which read the
D_CONTACT_RECORD / D_/F_VACCINATION dims those skipped entities build) produce 0
rows. That is exactly the 6-table set.

**The throw that triggers the short-circuit already exists *without* the lab
fixture.** It is `sp_nrt_morbidity_report_postprocessing` failing on the
foundation morb obs:

```
Step: Inserting into MORBIDITY_REPORT_EVENT
Error 515: Cannot insert the value NULL into column 'PATIENT_KEY',
           table 'RDB_MODERN.dbo.MORBIDITY_REPORT_EVENT'
```
(live `RDB_MODERN.dbo.job_flow_log`, batches at 06:35 / 06:37 / 06:44 on the
CURRENT lab-quarantined run; and the matching service log
`Error processing observation data with ids '…': DataProcessingException`
retried attempts #1-3 then dead-lettered.)

So the morb obs SP throws on *every* batch that contains it. Whether the 6
tables end up populated is therefore decided by **CDC batch timing** — i.e. whether
the CONTACT/VACCINATION CDC ids happen to land in a *different* 20 s window than
the failing morb-observation batch (then they process fine), or in the *same*
window (then they are skipped). This is precisely the long-noted
"covid_contact / f_contact / f_vaccination flakiness" (LOOP_round4 LESSON 8 area;
LOOP_round5 item D).

**What the lab fixture does is make the bad outcome (near-)deterministic.** It
adds ~80 new lab observations (Order/Result + I_Order/I_Result/Result + 35
LABxxx children) to NBS_ODSE → CDC mirrors them to `nrt_observation` in the
Tier-3 drain → they swell the OBSERVATION ids in the same drain window that
also carries the morb obs + the contact/vaccination ids. The bigger, slower
observation batch (a) keeps OBSERVATION failing (morb still throws, and the lab
SPs add their own failure surface — see below), and (b) widens the window in
which CONTACT/VACCINATION co-batch with the failing OBSERVATION entity, so they
get skipped → the 6 tables go to 0 every run instead of "sometimes". Quarantining
the fixture shrinks the observation batch back to the flaky-but-often-OK size.

### Net: the lab fixture is a *deterministic aggravator* of a *pre-existing*
### batch-failure/short-circuit bug, NOT a UID collision and NOT an IDENTITY flood.

---

## Evidence per hypothesis

**H1 — UID collision: NO.** The fixture's explicit UIDs (act/observation/act_id/
participation/act_relationship 22053010-22053011, 22053500-22053502,
22053600-22053634) do not exist in NBS_ODSE today and do not appear in any
hardcoded `@obs` list in `merge_and_verify.sh`. Its `local_id`s
(`OBS22053010GA01`, `OBS22053500GA01`) do not collide with any existing
observation local_id (live `NBS_ODSE.dbo.observation` survey: existing ids are
OBS20000120GA01 … OBS22048216GA01). `program_jurisdiction_oid` 20053010/20053500
are unique. No key conflict feeds the 6 tables' chains. **Ruled out.**

**H2 — shared-entity interference: NO (not the cause).** The fixture *does*
re-use the shared foundation entities (`@pat_uid=20000000`, `@prov_uid=20000010`,
`@org_uid=20000020`) for its PATSBJ/ORD/AUT/SPP participations, and adds a `role`
row (SPP) scoped to the patient. But those are additive participations on *new*
acts; they do not change the join cardinality of the contact/vaccination/morb
chains (which key off their own acts 20120010 / 20110010 / 20080010). The 6
tables break because their *entities are skipped*, not because a shared join
multiplied. **Not the mechanism.**

**H3 — batch-failure / shared-SP short-circuit: YES — this is the root cause.**
Proven above: `processIdCache` fail-fast (lines 749-799) + `Entity` priority
14<15<16<17 + `processObservation` running the throwing morb SP at priority 14 →
CONTACT/TREATMENT/VACCINATION skipped + truncated `dmData` for the datamart
fan-out. Confirmed live by the recurring Error-515 in `job_flow_log` and the
`DataProcessingException` retries in the service log on the CURRENT
lab-quarantined run, with covid_contact_datamart=0, f_contact_record_case=0,
lab_rpt_user_comment=0 right now.

Additional lab-side throw surface that the fixture *adds* to the same OBSERVATION
batch (so even if the morb obs were fixed, the lab fixture could still trip the
short-circuit):
- `sp_d_labtest_result_postprocessing` (routine 017) has a TRY/CATCH that
  re-raises on any error (lines ~1955+), so any lab-row defect propagates as a
  service exception and short-circuits the batch.
- `sp_lab101_datamart_postprocessing` (routine 020) does **hard**
  `convert(datetime, replace(LAB.LABn,'-',' '), 0)` for the 7 date pivot
  columns LAB6/21/22/28/29/33/34 (lines 839-845), sourced from
  `LAB_RESULT_VAL.FROM_TIME` for cds LAB334/349/350/356/357/361/362
  (trtd6/21/22/28/29/33/34 join filters, lines 535-679). The fixture seeds
  `obs_value_coded.display_name='04-21-2026'` for cds
  `LAB334,LAB349,LAB354,LAB360,LAB361,LAB362,LAB363` — note `LAB354/360` are
  **not** date columns while `LAB350/356/357` **are** and get plain text
  (`'Value for LAB350'` …). The fixture relies on `FROM_TIME` being NULL for the
  text children (so the date CONVERT sees NULL and yields NULL); that holds only
  because the fixture sets no `obs_value_date`. This is fragile — any future edit
  that lands a non-date string into a FROM_TIME-mapped LABn column would make
  routine 020 throw and short-circuit the batch on its own. (Not the *current*
  trigger — the morb obs throws first — but a latent second one.)

**H4 — apply order / IF-NOT-EXISTS pre-occupation: NO.** All Tier-3 fixtures are
applied in Step 8 *before* the single Step-9 drain (`main()` lines 696-701), so
CDC mirrors the entire Tier-3 set together regardless of the `zz_*`
alphabetical position of `zz_lab100_101_fill.sql`. The fixture's only guard
(`IF NOT EXISTS … role … SPP`) touches a shared role, not anything the 6 tables
read. Order is not the lever. **Ruled out.**

---

## Which of the 6 break, and why

| table | builder | why it goes to 0 when the OBSERVATION batch fails |
| --- | --- | --- |
| **lab100** | `sp_d_lab_test_postprocessing` (LAB path of `processObservation`, prio 14, runs AFTER the throwing morb SP) | morb throws first → lab SPs in the same `processObservation` call never run |
| **lab_rpt_user_comment** | same `sp_d_lab_test_postprocessing` (routine 018) | same — lab path skipped |
| **f_contact_record_case** | CONTACT entity (prio 15), `sp_f_contact_record_case_postprocessing` | priority 15 > 14 → skipped after OBSERVATION fails |
| **f_vaccination** | VACCINATION entity (prio 17), `sp_f_vaccination_postprocessing` | priority 17 > 14 → skipped |
| **covid_contact_datamart** | `nbs_Datamart` topic → dmCache, but reads D_CONTACT_RECORD built by CONTACT(15) | CONTACT skipped → no/stale dim → datamart SP yields 0 |
| **covid_vaccination_datamart** | `nbs_Datamart` topic → dmCache, but reads D_/F_VACCINATION built by VACCINATION(17) | VACCINATION skipped → datamart SP yields 0 |

Without the lab fixture these can populate when CONTACT/VACCINATION happen to
batch separately from the failing morb obs (timing) — hence the historical
"flaky +42/+39" swings. With the lab fixture the failing observation batch is
big and slow enough that the co-batch (and thus the skip) is effectively every
run.

---

## SAFE-REWORK VERDICT

**Safe to author lab100/lab101 — but ONLY with the changes below. As written +
the proposed ORCH_TODO it is NOT safe**, because the regression is not about the
lab data per se; it is about the lab obs joining a shared, fail-fast CDC batch
whose morb obs already throws. A non-colliding UID range / dedicated act
(hypotheses the brief floated) does **not** help, because the failure is the
shared-batch short-circuit, not a UID/entity collision.

There are two independent fixes; do the harness one first (it removes the whole
class of flakiness), the lab-data hardening second.

### Fix A (REQUIRED, harness — sanctioned this round): stop one throwing observation from nuking the batch
The pre-existing `MORBIDITY_REPORT_EVENT.PATIENT_KEY` NULL throw is what trips
the short-circuit today; the lab fixture only makes it deterministic. Options,
best first:
1. **Make the morb foundation obs stop throwing.** The morb obs (20080010 /
   20000130) reaches `sp_nrt_morbidity_report_postprocessing` with a NULL
   PATIENT_KEY (no resolvable patient link), violating the NOT NULL on
   `MORBIDITY_REPORT_EVENT.PATIENT_KEY`. Author the missing patient link
   (a `PATSBJ`/subject participation resolving to D_PATIENT) for the morb obs in
   a Tier-1/Tier-2 fixture so the morb SP succeeds → OBSERVATION no longer
   throws → CONTACT/VACCINATION never get skipped → the 6 tables stop being
   flaky AND the lab fixture can ride along safely. This is the highest-leverage
   fix (also stabilizes LOOP item D).
2. If the morb obs cannot be made to succeed via fixtures, **isolate lab obs
   from the morb/contact/vaccination batch** by introducing a dedicated post-
   Step-9 drain step that re-emits ONLY the lab obs ids (so they process in a
   batch that contains no throwing morb obs). This is a `merge_and_verify.sh`
   edit (sanctioned). It does NOT cure the underlying flakiness (contact/vacc
   can still co-batch with morb), but it makes the lab fixture coverage-additive
   and non-regressing.

   Note the dead manual-chain functions (`run_lab_chain`, etc.) are NOT executed
   by `main()` — adding the fixture's UIDs to them (the fixture-header ORCH_TODO)
   would be a **no-op** and must NOT be relied on. Any harness orchestration for
   lab100/101 has to be wired into `main()`’s real (CDC-drain) flow, e.g. a
   genuine post-Step-9 re-drain or a real `EXEC` step, not the dead helpers.

### Fix B (REQUIRED, lab fixture data hardening): make the lab SPs unable to throw
Even after Fix A, harden the fixture so routines 017/020 can't throw on it:
- **Align the date children to routine 020's actual date columns.** The
  FROM_TIME (datetime) pivot columns are LAB6/21/22/28/29/33/34 = cds
  **LAB334, LAB349, LAB350, LAB356, LAB357, LAB361, LAB362** (routine 020 lines
  535-679). The fixture currently date-flags `LAB334,LAB349,LAB354,LAB360,
  LAB361,LAB362,LAB363` — i.e. it dates two NON-date cols (LAB354,LAB360,LAB363)
  and leaves three real date cols (LAB350,LAB356,LAB357) as text. Fix the
  CASE list to exactly `{LAB334,LAB349,LAB350,LAB356,LAB357,LAB361,LAB362}`.
- **Feed the date through a channel routine 020 actually reads as FROM_TIME.**
  The date columns come from `LAB_RESULT_VAL.FROM_TIME`, which
  `sp_d_labtest_result_postprocessing` derives from the observation's date value
  — not from `obs_value_coded.display_name`. Author `obs_value_date` (or the
  obs scalar the SP maps to FROM_TIME) for those 7 children with a valid
  datetime, and give the text children NO FROM_TIME. Then routine 020's
  `convert(datetime, …)` only ever sees real datetimes or NULL — never a stray
  string — so it cannot throw regardless of batch composition.
- Keep `obs_value_numeric.low_range/high_range` as the current strings
  (`'0.00'`,`'0.90'`) — those columns are `varchar(20)` (verified), so they are
  safe; routine 017 only `SUBSTRING`s them.

### Validation expectation
With Fix A (morb link) + Fix B (lab date alignment), a clean
`merge_and_verify` should: keep lab100 ≥ its current 1 and add the new
demographics row, populate lab101 (>0), keep f_vaccination / f_contact_record_case /
covid_vaccination_datamart / covid_contact_datamart at or above their pre-fixture
counts (no longer zeroed), and show the observation batch draining to idle with
**no** `DataProcessingException` / Error-515 in the service log + `job_flow_log`.
If the morb link (Fix A.1) can't be done fixtures-only, use the isolation
drain (Fix A.2) and accept that contact/vacc remain timing-flaky independent of
the lab fixture.
