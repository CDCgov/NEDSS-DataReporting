# Bug #11 — sp_aggregate_report_datamart_postprocessing references a column AGGREGATE_REPORT_DATAMART does not have

**Status**: Surfaced 2026-05-21 (overnight loop iter 5). Not fixed.
Open. Real RTR bug.

## Symptom

```sql
EXEC dbo.sp_aggregate_report_datamart_postprocessing
    @id_list = N'22010000', @debug = 0;
```

returns "1 rows affected" (the SP's terminal job_flow_log INSERT)
but never populates `dbo.AGGREGATE_REPORT_DATAMART`. The SP's
try/catch swallows the inner error. `job_flow_log` reveals:

```
step 5 (UPDATE dbo.AGGREGATE_REPORT_DATAMART)  ERROR
  Error Number: 207
  Error Severity: 16
  Error State: 1
  Error Line: 11
  Error Message: Invalid column name 'NOTIFICATION_UPD_DT_KEY'.
```

## Root cause

`050-sp_aggregate_report_datamart_postprocessing-001.sql` builds a
dynamic UPDATE statement (line 177-238) that includes:

```sql
NOTIFICATION_UPD_DT_KEY = src.NOTIFICATION_UPD_DT_KEY,
```

referencing both `tgt.NOTIFICATION_UPD_DT_KEY` (target table column)
and `src.NOTIFICATION_UPD_DT_KEY` (sourced from `#AGG_EVENT`,
populated at line 118 from `NOTIFICATION_EVENT.NOTIFICATION_UPD_DT_KEY`).

The source-side reference is fine — `NOTIFICATION_EVENT` does have
that column. But the target table `AGGREGATE_REPORT_DATAMART` has
only `NOTIFICATION_STATUS` and `NOTIFICATION_LOCAL_ID` — no
`NOTIFICATION_UPD_DT_KEY` column. Verified live 2026-05-21:

```sql
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='aggregate_report_datamart' AND COLUMN_NAME LIKE '%NOTIFICATION%';
-- Returns: NOTIFICATION_STATUS, NOTIFICATION_LOCAL_ID (no _UPD_DT_KEY)
```

The same column also appears in the dynamic INSERT statement (line
268) but the UPDATE fires first and errors, so the INSERT never
runs.

### Second phantom column (re-confirmed 2026-06-02)

`NOTIFICATION_UPD_DT_KEY` is not the only phantom. The SP's UPDATE
(line 190) and INSERT (lines 271, 289) also reference
`NOTIFICATION_LAST_CHANGE_TIME`, which the target table likewise does
**not** have:

```sql
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='AGGREGATE_REPORT_DATAMART' AND COLUMN_NAME LIKE 'NOTIFICATION%';
-- Returns ONLY: NOTIFICATION_STATUS, NOTIFICATION_LOCAL_ID
```

So even after dropping `NOTIFICATION_UPD_DT_KEY`, the UPDATE would
fail again on `NOTIFICATION_LAST_CHANGE_TIME` (next msg-207). Any fix
must remove (or add) **both** columns. Both are sourced fine from
`NOTIFICATION_EVENT.NOTIFICATION_UPD_DT_KEY` /
`NOTIFICATION.NOTIFICATION_LAST_CHANGE_TIME` in `#AGG_EVENT` (lines
118, 121) — the defect is purely the target-side reference.

## Why production likely hasn't seen this

`AGGREGATE_REPORT_DATAMART` is a Tier 3 / niche path — only fires
when an Investigation has `case_type_cd='A'` (Aggregate). Most
Investigations in production are `case_type_cd='I'` (Individual)
or `'S'` (Summary). Aggregate reports are weekly count summaries —
relatively few are submitted, and the population path may not be
fully exercised in normal operation.

## Suggested fix

Three options for the RTR team:

1. **Add `NOTIFICATION_UPD_DT_KEY` column to `aggregate_report_datamart`**
   (schema change). Mirrors how `summary_report_case` has both
   `NOTIFICATION_SEND_DT_KEY` and `LAST_UPDATE_DT_KEY`.
2. **Remove `NOTIFICATION_UPD_DT_KEY` from the SP's UPDATE and
   INSERT statements** (lines 187, 268, 286). Drop it from
   `#AGG_EVENT` too (lines 118, 138).
3. **Cast the column at the UPDATE site as a no-op**
   (`NOTIFICATION_UPD_DT_KEY = NULL` is still column-named, would
   still fail). Not viable.

Option 1 is the cleaner fix — aggregate reports have notifications
just like other Investigation types, and there's no reason their
update date wouldn't be useful in the datamart.

## Tables blocked

- `aggregate_report_datamart` — stays at 0 rows even with a correctly
  authored Aggregate-type Investigation + nrt_investigation_aggregate
  count rows (see `fixtures/30_sp_coverage/aggregate_report.sql`).

## Repro

```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -i \
  fixtures/30_sp_coverage/aggregate_report.sql
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q \
  "EXEC dbo.sp_aggregate_report_datamart_postprocessing @id_list = N'22010000', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q \
  "SELECT TOP 1 Error_Description FROM dbo.job_flow_log
   WHERE dataflow_name='AGGREGATE_REPORT_DATAMART' AND status_type='ERROR'
   ORDER BY record_id DESC"
-- Returns: Error Number: 207, Invalid column name 'NOTIFICATION_UPD_DT_KEY'
```
