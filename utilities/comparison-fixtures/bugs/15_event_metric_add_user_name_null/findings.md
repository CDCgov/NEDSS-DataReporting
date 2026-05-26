# Bug #15 — `sp_event_metric_datamart_postprocessing` leaves `ADD_USER_NAME` NULL for some branches, silently blocking SR100

**Severity:** Medium — blocks `dbo.SR100` entirely (0/20) in the
comparison-fixtures pipeline, and likely under-populates
`EVENT_METRIC.ADD_USER_NAME` / `LAST_CHG_USER_NAME` in production for any
event whose row is produced by the affected branch.

**Status:** Documented, not fixed (RTR routine — out of scope per
LOOP.md). Repro is fully reduced below.

## Symptom

`dbo.SR100` stays empty (0 rows / 0 of 20 cols) even though its source
`SUMMARY_REPORT_CASE` row exists and every join in
`sp_sr100_datamart_postprocessing` resolves. The SR100 SP logs
`Insert into SR100 | rows=0` in `JOB_FLOW_LOG` with no surfaced error.

## Root cause (two layers)

### Layer 1 — SR100 SP swallows a NOT NULL violation

`sp_sr100_datamart_postprocessing`
(`155-sp_sr100_datamart_postprocessing-001.sql`) builds `#temp_sr100`
(1 row, verified) then:

```sql
INSERT INTO dbo.SR100 (..., ADD_USER_NAME, ...)
SELECT ..., t.ADD_USER_NAME, ...
FROM #temp_sr100 t LEFT JOIN dbo.SR100 s ON t.INVESTIGATION_KEY = s.INVESTIGATION_KEY
WHERE s.INVESTIGATION_KEY IS NULL;
```

`SR100.ADD_USER_NAME` is **NOT NULL**, but `t.ADD_USER_NAME` (sourced from
`EVENT_METRIC.ADD_USER_NAME` via the temp build's
`INNER JOIN dbo.EVENT_METRIC em ON em.local_id = I.inv_local_id`) is NULL.
→ **Msg 515** ("Cannot insert the value NULL"). The SP's outer
`TRY/CATCH` (`IF @@TRANCOUNT > 0 ROLLBACK`) catches it and exits cleanly,
so the pipeline sees success while SR100 silently stays empty.

Reduced repro (the inline INSERT outside the SP surfaces the real error):

```
temp built: 1
Msg 515, Level 16, State 2 — Cannot insert the value NULL ... ADD_USER_NAME
inserted: 0
```

### Layer 2 — why EVENT_METRIC.ADD_USER_NAME is NULL

`sp_event_metric_datamart_postprocessing`
(`037-sp_event_metric_datamart_postprocessing-001.sql`) assembles
`#TMP_EVENT_METRIC` from **several `INSERT INTO #TMP_EVENT_METRIC`
branches** (notification, observation, and multiple investigation
variants — see the blocks at lines ~336, 479, 529, 579, 634, 711, 785).

- The branch at **line ~785** resolves the name correctly:
  ```sql
  i.add_user_id, ...
  RTRIM(LTRIM(up1.last_nm)) + ', ' + RTRIM(LTRIM(up1.first_nm)) AS ADD_USER_NAME
  ...
  LEFT OUTER JOIN dbo.nrt_auth_user AS up1 ON i.add_user_id = up1.nedss_entry_id   -- line 819
  ```
- The branch at **line ~634** (`FROM dbo.nrt_investigation phc`) selects
  `phc.add_user_id` but does **NOT** join `nrt_auth_user`, so its rows
  get `ADD_USER_NAME = NULL`.

The EVENT_METRIC row for a summary-report investigation is produced by a
branch that does not resolve the name. So even after the upstream data is
made fully correct, ADD_USER_NAME stays NULL.

## What was verified (rules out fixture-side fixes)

For the summary-report PHC `22009000` (INVESTIGATION_KEY 23,
`inv_local_id = CAS22009000GA01`):

- `SUMMARY_REPORT_CASE` row present; condition/county/event_metric joins
  in the SR100 SP all resolve (each cumulative INNER join → 1 row).
- `nrt_auth_user` was **empty** in the baseline (0 rows). Seeded a
  superuser row (`nedss_entry_id = 10009282`, "Super, User"). NOTE:
  `nrt_auth_user` is a **system-versioned temporal table** — omit the
  generated period columns `refresh_datetime` (AS_ROW_START) and
  `max_datetime` (AS_ROW_END) from the INSERT or you hit Msg 13536.
- Set `nrt_investigation.add_user_id = 10009282` for the PHC; confirmed
  the name now joins:
  `nrt_investigation → nrt_auth_user` returns `Super / User`.
- **Despite all that**, re-running `sp_event_metric_datamart_postprocessing`
  (even after DELETEing the stale EVENT_METRIC row to force a fresh
  insert) left `EVENT_METRIC.ADD_USER_NAME` NULL → SR100 still 0.

So this is not a missing-input problem a fixture can solve; it is the SP
branch not resolving the name.

## Suggested fix (RTR)

In `sp_event_metric_datamart_postprocessing`, make every
`#TMP_EVENT_METRIC` branch that selects `add_user_id` /
`last_chg_user_id` also `LEFT JOIN dbo.nrt_auth_user` on
`nedss_entry_id` and project the
`RTRIM(LTRIM(last_nm)) + ', ' + RTRIM(LTRIM(first_nm))` name — i.e. apply
the line-819 pattern uniformly to the line-634 (and sibling)
investigation branch(es). Alternatively, relax `SR100.ADD_USER_NAME` to
allow NULL, or have `sp_sr100_datamart_postprocessing` `COALESCE(...,'')`
the NOT NULL string columns before insert (it already does that style of
defaulting for RPT_SOURCE).

A defensive improvement either way: the SR100 SP should not swallow a
Msg 515 INSERT failure silently — at minimum log the `ERROR_MESSAGE()`
to `JOB_FLOW_LOG` so the empty-table outcome is diagnosable.

## Impact on coverage

`SR100` (0/20) is left empty in the merged pipeline. Not a fixture gap —
flag as an RTR coverage gap for the comparison test. Documented here
instead of fixed, per the project's no-RTR-edits-in-loop rule.
