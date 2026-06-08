# Bug #21: SUMMARY_REPORT_CASE / SR100 silently empty after a fresh service run (drain-ordering race)

When an Investigation CDC event carries case_type_cd='S', PostProcessingService.processSummaryCases()
runs sp_summary_report_case_postprocessing then sp_sr100_datamart_postprocessing. Both DO fire (they
appear in job_flow_log), but they emit 0 rows on a fresh drain:

- sp_summary_report_case_postprocessing's #tmp_SumRptWork CTE INNER JOINs nrt_investigation_observation
  on root_type_cd='SummaryNotification'. When the summary SP runs inside the same investigation-event
  drain, that obs row is not reliably materialized yet, so it emits 0 rows. Re-running the SP after the
  drain completes produces the row immediately. This is a drain-ordering race, not a data/routine bug.
- sr100 then has no SUMMARY_REPORT_CASE parent and also stays empty.

Separately (fixture-side, now fixed): SR100.DATE_REPORTED/MONTH_REPORTED are NOT NULL and map from
INVESTIGATION.EARLIEST_RPT_TO_STATE_DT (public_health_case.rpt_to_state_time). A summary fixture that
omits rpt_to_state_time hits Error 515 on the SR100 insert.

WORKAROUND (in the coverage harness, realizing the documented Merge-contract Step 9 "run datamart SPs"):
merge_and_verify.sh Step 8.7 run_summary_datamarts() EXECs sp_event_metric_datamart_postprocessing ->
sp_summary_report_case_postprocessing -> sp_sr100_datamart_postprocessing over PHC_UIDS AFTER the
Tier-3 drain, so population is deterministic. With it: SUMMARY_REPORT_CASE 1 row / 11-of-12 cols
(SUM_RPT_CASE_COMMENTS needs a SUM105 obs), SR100 1 row / 19-20 cols.

RECOMMENDATION (service): processSummaryCases() should either run after the obs materialization barrier,
or re-drive summary cases once nrt_investigation_observation is settled. Same family as bug #20 (the
obs fail-fast ordering). Routines are correct; the issue is invocation timing.
