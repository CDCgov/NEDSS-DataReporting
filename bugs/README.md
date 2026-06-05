# RTR bugs surfaced by the comparison-fixtures no-shortcut work

Each `NN_*/findings.md` has the repro, root cause, and fix/triage. Removing the `nrt_*`/`EXEC`
shortcut and running the real ODSE→CDC→RTR pipeline surfaced these defects — most were masked by
the shortcut's hand-authored rows and manual SP invocation.

| # | Area | Status |
|---|---|---|
| 17 | `sp_d_lab*_postprocessing` non-atomic key-gen race (2627/1205 under concurrency) | **FIXED** — `sp_getapplock` + explicit key allocation; concurrency test |
| 19 | `LAB_TEST.RECORD_STATUS_CD` CHECK violation (547) | **FIXED** — normalize the status fallback; data-driven test |
| 26 | `sp_nrt_notification_postprocessing` non-atomic key-gen race (2627) — sibling of #17 | **FIXED** — `sp_getapplock` + snapshot refresh; concurrency test |
| 18 | followup-observation NPE on null `obs_domain_cd_st_1` | **FIXED** (cosmetic) — null-safe compare; unit test |
| 20 | obs-batch "fail-fast" skips lower-priority entities on any throw | **NOT A BUG** — intentional defer-and-retry-backfill; fix reverted (see findings) |
| 16 | `covid_lab*_datamart` empty — `Loinc_condition` has no row for condition 11065 | Seed-gated (out of bounds for ODSE-only fixtures) |
| 21 | `SUMMARY_REPORT_CASE`/`SR100` empty after a fresh run — service drain-ordering race | Documented; harness Step-8.7 backstop populates deterministically |
| 22 | LDF datamart tables — seed/chain gating (no LDF metadata / empty `GENERIC_CASE`) | Documented (out of bounds); real source = `State_Defined_Field_Data` |
| 24 | `sp_dyn_dm` routine-040 `PARTITION BY ... branch_id` caps multi-value fields to 1 row/PHC | Documented (routine defect) — NULLs `bmird _2.._8` for any fixture |
| 25 | `sp_dyn_dm_createdm` 206 `date`/`float` clash — legacy `DM_INV_*` `float` shells vs `date` metadata | Documented (routine/env defect); reproduced at zero rows |

Notes:
- **#20 was the key correction**: it was initially diagnosed as a bug and "fixed" with fault
  isolation, but the fail-fast is intentional (`@Scheduled` retry/backfill recovery). The reverted
  finding documents the evidence. The real coverage poisons are the key-gen races (#17/#26) and the
  dyn-datamart defect (#25), amplified by the intentional fail-fast.
- Bugs #1–#15 predate this branch (the shortcut-era fixtures) and are not tracked here.
- #23 is intentionally absent (it is a non-bug docs task in the project tracker, not a finding).
