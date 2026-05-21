# Coverage: Pertussis Investigation full-chain fixture

Generated: 2026-05-21 (overnight loop iteration #1).

## Inputs

- Baseline: 6.0.18.1 + foundation + all Tier 1 + all Tier 2 + existing
  Tier 3 fixtures (TB, STD/HIV, BMIRD, COVID, Varicella, d_investigation_repeat,
  multi_condition_investigations, ldf_answers_tetanus, f_page_case_unblock).
- Fixture file: `fixtures/30_sp_coverage/pertussis_investigation_full_chain.sql`
- UID range: **22007000-22007999**

## Outcome (post-merge_and_verify)

**Headline coverage delta: 0pp.** The fixture applies cleanly (zero
errors in merge_and_verify) and the live DB shows:

| Table | Before | After | Notes |
| --- | --- | --- | --- |
| `dbo.Pertussis_Suspected_Source_Fld` | 0 rows | 1 row | NOT in scope per `rtr_target_columns.md` |
| `dbo.Pertussis_Treatment_Field`      | 0 rows | 1 row | NOT in scope |
| `dbo.PERTUSSIS_CASE`                 | 0 rows | 0 rows | Empty — see "SP investigation" below |
| `dbo.pertussis_suspected_source_grp` | 1 row  | 1 row | Already covered (sentinel); unchanged |
| `dbo.pertussis_treatment_group`      | 1 row  | 1 row | Already covered (sentinel); unchanged |

The Pertussis condition does **not** have an in-scope datamart wide
table analogous to `tb_datamart` or `covid_case_datamart`. The
condition's wide table is `PERTUSSIS_CASE` itself, but that's not in
`rtr_target_columns.md` either (which only enumerates tables with
*some* SP write reference). So this fixture's net contribution to the
headline number is zero, even when the chain works correctly.

## SP investigation (out of scope for the loop)

`sp_pertussis_case_datamart_postprocessing` runs cleanly (job_flow_log
shows `COMPLETE`) but `Pertussis_Case` ends with 0 rows. Two observations:

1. **All job_flow_log row_counts log as 0** — likely the same
   `@@ROWCOUNT`-after-IF bug pattern as bug 5a (logging-only). When
   the SP is re-invoked manually with `@debug='true'`, step 2's
   intermediate `SELECT` shows 53 rows in `#OBS_CODED_PERTUSSIS_Case`,
   so the SP IS reading my answer data correctly.
2. **The `Pertussis_Suspected_Source_Fld` and `Pertussis_Treatment_Field`
   tables populate correctly** (1 row each from my fixture). So the
   coded/text/numeric/date observation graph IS reaching downstream
   steps — just not all the way through to the main `Pertussis_Case`
   wide insert.

Possible cause: the SP's late steps (INSERT INTO Pertussis_Case at
step ~33) may depend on a row in INVESTIGATION/F_PAGE_CASE that has a
specific INVESTIGATION_FORM_CD or CONDITION_CD that I haven't matched.
Investigation deferred (not in scope per LOOP.md — coverage didn't
regress, fixture is groundwork).

## Forward-looking notes

For the next loop iteration: the BMIRD-template approach (v_rdb_obs_mapping
+ nrt_observation_* graph) works for Pertussis at the observation
layer. The same pattern should work for **Measles, Rubella, Mumps**
(next queue items) — they all use legacy condition-specific case
tables (MEASLES_CASE, RUBELLA_CASE, etc.), most likely also out of
scope per `rtr_target_columns.md`. **Worth checking before authoring
the next 3 fixtures**: does each have an in-scope target table?

If not, the higher-value queue items are:
- LDF answer-chain extensions (per-condition LDF datamart tables ARE
  in scope: `ldf_bmird`, `ldf_foodborne`, `ldf_hepatitis`, `ldf_mumps`,
  `ldf_tetanus`, `ldf_vaccine_prevent_diseases` — 7 cols each, total
  42 cols across 6 tables, all currently 0/7).
- COVID-case-datamart answer expansion (53/383 → could add ~50 more
  answer rows).

## Gaps reported

- **OUT_OF_SCOPE**: Pertussis_Case (0 / 0 in coverage scope; not in
  `rtr_target_columns.md`).
- **DEFERRED**: investigation of why `sp_pertussis_case_datamart_postprocessing`
  produces 0 rows in Pertussis_Case despite the upstream observation
  graph being correctly populated. Per LOOP.md rules, document and
  move on.

## Files

- Fixture: `fixtures/30_sp_coverage/pertussis_investigation_full_chain.sql`
- Orchestrator: `scripts/merge_and_verify.sh` PHC_UIDS extended with
  `22007000`.
