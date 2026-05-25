# Empty in-scope tables — triage (2026-05-22)

The merged coverage report shows 18 in-scope tables with 0 rows.
This document categorizes them and identifies the minimum work
required to unblock each. Generated while parallel agents A/B/C/D
work on their own enrichment fixtures.

## Quick-win category — orchestrator UID list patch only

### `LAB100` (69 cols), `LAB101` (46 cols)

**Why empty:** `sp_lab100_datamart_postprocessing` filters
`LAB_TEST_TYPE = 'Result'` over `@labtestuids`. The orchestrator
passes `LAB_OBS_UIDS='20000120,20070010'` (foundation Lab Order +
Tier-1 Lab Order). The corresponding Result row in LAB_TEST is
`20070011` — NOT in the orchestrator's list. So the SP sees zero
result-type rows in its working set.

**LAB101 caveat:** filters `LAB_TEST_TYPE = 'I_Result'` (interpretation
result). We have no I_Result LAB_TEST rows at all. To unblock LAB101,
need a new fixture authoring a parent I_Order + child I_Result lab pair.

**Fix LAB100:** change `LAB_OBS_UIDS='20000120,20070010'` →
`LAB_OBS_UIDS='20000120,20070010,20070011'` in
`scripts/merge_and_verify.sh:451`.

**Estimated yield:** LAB100 unblocks → +50-65/69 cols populated.

## Quick-win category — LDF-flagged answer rows

### `tb_pam_ldf` (3), `var_pam_ldf` (3), `ldf_bmird` (7), `ldf_hepatitis` (7), `ldf_mumps` (7), `organization_ldf_group` (3), `patient_ldf_group` (3), `provider_ldf_group` (3)

**Why empty:** All the LDF SPs gate on
`ldf_status_cd IN ('LDF_UPDATE','LDF_CREATE','LDF_PROCESSED')` over
`nrt_page_case_answer` rows. EVERY current fixture sets
`ldf_status_cd = NULL`. The catch is: LDF-flagged answers are
distinct from normal answers — they represent custom site-specific
fields that supplement the standard form.

**Fix:** author a single small fixture that adds ~6 LDF-flagged
answer rows on existing PHCs:
- 2 on TB PHC 22001000 (`INV_FORM_RVCT`) → unblocks `tb_pam_ldf`
- 2 on Var PHC 22002000 (`INV_FORM_VAR`) → unblocks `var_pam_ldf`
- 2 on BMIRD PHC 22005000 → unblocks `ldf_bmird`
- 2 on Hep PHC 22008000 (post-Agent-B) → unblocks `ldf_hepatitis`
- 2 on Mumps PHC (does one exist? probably 22000050 stub) → may not unblock fully if stub-only, since stubs have no answers; mumps may require a full-chain investigation first

Plus `*_ldf_group` tables — populated by `sp_nrt_ldf_postprocessing`
which reads ALL ldf-flagged answers across patient/provider/org and
groups them. Filling any of the *_pam_ldf tables likely also
populates the *_ldf_group siblings as a side effect (they're aggregations).

**Estimated yield:** +30-40 cols total (most LDF tables are narrow).
The bigger win is unblocking 5-8 tables, improving "fully covered"
count.

## Medium category — full investigation chain needed

### `hep100` (187 cols), `ldf_hepatitis` (7)

**Fix:** Agent B is authoring a full Hep A chain at 22008000. Once
merged, `sp_hep100_datamart_postprocessing` (already in orchestrator
at line 505) should fire automatically — PHC_UIDS already includes
22008000. Expect this to drop significantly once Agent B lands.

### `covid_lab_datamart` (129), `covid_lab_celr_datamart` (101)

**Why empty:** `sp_covid_lab_datamart_postprocessing` filters
observations by `condition_cd = '11065'`. The orchestrator passes
`@observation_id_list = LAB_OBS_UIDS = '20000120,20070010'`. Neither
of those is COVID-coded. The foundation Lab is generic; Tier-1 Lab
is generic.

**Fix:** author a new Tier-3 fixture creating a COVID-coded lab
observation (act_uid in 22011xxx, say) linked to the COVID PHC
22003000, then add 22011xxx to LAB_OBS_UIDS. This is a deferred
"Phase 2" item per the COVID full-chain fixture's report.

**Estimated yield:** +60-80 cols across both.

### `inv_summ_datamart` (58)

**Why empty:** SP joins notifications + investigations + observations.
Likely needs both NOTIF_UIDS coverage of newer PHCs and OBS_UIDS to
match. Worth a focused investigation — may just be a missing join key.

**Estimated yield:** +20-30 cols.

### `sr100` (20 cols), `aggregate_report_datamart` (42)

**Why empty:** Summary reporting tables. Likely gated on
`f_page_case` rows or similar. `sr100` is small enough that even
half-populating is +10 cols.

## Skip / by-design

### `lookup_table_n_rept` (2 cols) — known artifact

Post-bug-#10 fix, this transient staging table is DELETEd by
`sp_sld_investigation_repeat_postprocessing` at start of each run.
Empty is correct. The 2 cols won't ever populate in steady state.
**Don't try to fix.**

## Recommended order of attack

1. **Patch `LAB_OBS_UIDS` to include 20070011** — 1-line change,
   instant +50ish cols on LAB100. Do FIRST.
2. **Author `zz_ldf_flagged_answers.sql`** — single fixture,
   8-12 rows targeting LDF SPs across multiple PHCs. +30-40 cols,
   unblocks 5-8 tables.
3. **Wait for Agent B** — Hep A chain should unblock hep100.
4. **Author COVID-lab fixture** (separate Tier-3 file, UID block
   22011xxx) — +60-80 cols when wired.
5. **Investigate `inv_summ_datamart`** — quick read of SP to find
   missing join keys, then patch.

Items 1-2 are safe to do right now while agents A/B/C/D work; they
don't touch any of the agent-claimed UID ranges or fixture files.
