# RTR bugs surfaced by the synthetic-ODSE-fixtures work

Authoring the fixtures against the **real** ODSE -> CDC -> RTR pipeline (no `nrt_*`
INSERT / `EXEC sp_*` shortcut) surfaced a series of RTR defects, each found and fixed
via TDD. This is a historical summary of the ones that have been **fixed**. The full
per-bug investigations (repro, hypotheses, root cause) were removed when the bug
ledgers were consolidated for the PR; they remain in git history prior to this commit.

## Fixed and merged to main

| Defect | Fix | Reference |
| --- | --- | --- |
| `sp_hepatitis_datamart_postprocessing` logs an incorrect `#TMP_F_PAGE_CASE` row count (`IF @debug` resets `@@ROWCOUNT` before the capture) | logging-only correction | APP-732 (#893) |
| `sp_sld_investigation_repeat_postprocessing` surrogate-key allocation drops new dim rows, and the dynamic TEXT pivot NULL-propagates | explicit key allocation + pivot fix | APP-734 (#894) |
| Follow-up observation NPE on a null `obs_domain_cd_st_1` | null-safe domain compare in `ProcessObservationDataUtil` | APP-735 (#895) |
| `sp_d_lab*_postprocessing` non-atomic key generation races under concurrency (errors 2627 / 1205) | `sp_getapplock` + explicit key allocation; concurrency test | APP-736 (#896) |
| `LAB_TEST.RECORD_STATUS_CD` CHECK violation (547) | normalized status fallback; data-driven test | APP-737 (#897) |
| `sp_nrt_notification_postprocessing` non-atomic key-gen race (2627), sibling of APP-736 | `sp_getapplock` + snapshot refresh; concurrency test | APP-738 (#898) |
| `sp_contact_record_event` references `fn_get_value_by_cd_codeset` in the wrong database | qualify to `RDB_MODERN.dbo` | PR #769 |
| `sp_nrt_provider_postprocessing` temp-table typo (`#PATIENT_UPDATE_LIST` for `#PROVIDER_UPDATE_LIST`) | correct the reference | PR #826 |
| `sp_nrt_ldf_postprocessing` maps the wrong source column into `LDF_DATA.RECORD_STATUS_CD` | correct source column | PR #827 |

## Fixed on this branch (shipping in this PR)

| Defect | Fix | Reference |
| --- | --- | --- |
| `sp_bmird_strep_pneumo_datamart_postprocessing` merges the three additional-site datasets (`#DM_BMD125/142/144`) on `INVESTIGATION_KEY` only, a Cartesian product, so one value repeats across `NON_STERILE_SITE_1..3` / `ADD_CULTURE_1_SITE_1..3` / `ADD_CULTURE_2_SITE_1..3` for any multi-value investigation | rank each set per investigation and align on `(INVESTIGATION_KEY, rn)` | routine `140-sp_bmird_strep_pneumo_datamart_postprocessing-001.sql` |
| `HEPATITIS_DATAMART` blocked by an `nrt_investigation.patient_id` NULL that cascades through the PATIENT sentinel into a `DELETE ... WHERE PATIENT_UID IS NULL` | fixture-side: orchestrator and Tier-3 variants set `patient_id` | fixtures |

Open and documented-only findings (and one retracted non-bug, the obs-batch fail-fast
which is intentional defer-and-retry-backfill) were not carried forward; see git history.
