# Bug #1: sp_get_date_dim references nonexistent dbo.rdb_date_temp

**Status**: **Resolved — non-issue in normal environments** (2026-05-19). In all normal working environments `RDB_DATE` is correctly populated by the database seeds, so `sp_get_date_dim` is never invoked on the path observed here. A separate PR is in-flight to correct the seed path. The defects below are real, but the SP itself is dead code on the live path. See `pr.md` for the no-PR resolution.
**Severity (historical)**: High (RDB_DATE calendar dim cannot be populated via documented path).
**Surfaced by**: comparison-fixtures Tier 2 inv_notification agent.

## Source

- File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/014-sp_get_date_dim-001.sql`
- Baseline: NEDSSDB image at `DATABASE_VERSION=6.0.18.1`

## What it tries to do

Build `dbo.RDB_DATE` calendar dimension for years `[@start, @end]`.
Inserts a sentinel row at `DATE_KEY=1`, then loops one day at a time
decomposing each date into `RDB_DATE`'s columns. The intermediate
staging table named in source is `dbo.rdb_date_temp`. **No DDL anywhere
creates that table.**

## What's broken

### Bug 1A — `dbo.rdb_date_temp` does not exist

Source-file lines 26, 27, 36, 55 reference it. SP fails on first
reference with deferred-name-resolution error 208. Exhaustive grep
across the entire source tree (NEDSS-DataReporting, NEDSSDB submodule
including all `src/migrations/6.0.*/RDB`, `Mo DB Scripts`, `NBS_DB`)
confirms no DDL anywhere creates `dbo.rdb_date_temp`;
`OBJECT_ID(N'dbo.rdb_date_temp')` returns NULL on a fresh baseline.

### Bug 1B — Inverted IF predicate + loop-local SELECT INTO at lines 49-60

The original prompt called this a "scope bug"; it isn't (T-SQL temp
tables are NOT scoped to IF blocks — verified empirically:
`SELECT INTO #t` inside an IF body remains visible after the IF). The
actual defects:

1. **Line 52: `IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name='RDB_DATE' AND xtype='U')`** — guard fires only when `RDB_DATE` does NOT exist, but it always exists in RDB_MODERN. So `#temp_date` is never created and line 60's `from #temp_date` would fail with `Invalid object name '#temp_date'`.
2. **Even if the IF were inverted to `IF EXISTS`, `SELECT … INTO #temp_date` is inside the WHILE loop**. Iteration 2 would fail with `There is already an object named '#temp_date' in the database` — `SELECT INTO` creates, doesn't append.
3. **The `#temp_date` indirection is structurally redundant**; the loop could insert directly into `RDB_DATE` once after building staging.

Bug 1B is dormant today because Bug 1A short-circuits the SP at
compile-line 18.

## Exact error message (live capture)

```
error_number    208
error_severity  16
error_state     1
error_procedure dbo.sp_get_date_dim
error_line      18      (procedure-body offset; first source reference is line 26 of source file)
error_message   Invalid object name 'dbo.rdb_date_temp'.
```

## Suggested fix (source-code level)

### Option A — minimal diff

Rename `dbo.rdb_date_temp` to a session-temp `#rdb_date_temp` and
CREATE it once at the top of the SP body; delete the inverted-IF block
and the loop-local `SELECT INTO #temp_date`; do one `INSERT INTO
dbo.RDB_DATE … SELECT FROM #rdb_date_temp` after the WHILE loop.
Preserves the original public contract `(@start INT, @end INT)` and the
original output (sentinel + one row per day).

### Option B — recommended, recursive CTE

Collapse the entire body to a single `INSERT … SELECT` from a recursive
date CTE (`OPTION (MAXRECURSION 0)`). Drops the loop and the temp
table entirely. Functionally equivalent. This is what the
comparison-fixtures orchestrator uses today as the workaround.

```sql
CREATE PROCEDURE dbo.sp_get_date_dim @start int, @end int
AS
BEGIN
    DECLARE @start_dt date = DATEFROMPARTS(@start, 1, 1);
    DECLARE @end_dt   date = DATEFROMPARTS(@end,  12, 31);

    IF NOT EXISTS (SELECT 1 FROM dbo.RDB_DATE WHERE DATE_KEY = 1)
        INSERT INTO dbo.RDB_DATE (DATE_KEY) VALUES (1);

    ;WITH cal AS (
        SELECT @start_dt AS d, CAST(2 AS bigint) AS k
        UNION ALL
        SELECT DATEADD(day, 1, d), k + 1 FROM cal WHERE d < @end_dt
    )
    INSERT INTO dbo.RDB_DATE (DATE_KEY, DATE_MM_DD_YYYY, DAY_OF_WEEK,
        DAY_NBR_IN_CLNDR_MON, DAY_NBR_IN_CLNDR_YR, WK_NBR_IN_CLNDR_MON,
        WK_NBR_IN_CLNDR_YR, CLNDR_MON_NAME, CLNDR_MON_IN_YR, CLNDR_QRTR, CLNDR_YR)
    SELECT k, CAST(d AS datetime), DATENAME(dw, d), DAY(d), DATEPART(dayofyear, d),
           DATEDIFF(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, d), 0), d) + 1,
           DATEPART(week, d), DATENAME(month, d), MONTH(d),
           DATEPART(QUARTER, d), DATENAME(year, d)
    FROM cal OPTION (MAXRECURSION 0);
END;
```

Either option fixes both 1A and 1B in one changeset.

## Workarounds

Yes — the comparison-fixtures orchestrator (`STRATEGY.md` "Pre-Tier-2
infrastructure step"; `coverage_inv_notification.md` Inputs/INFRA_GAP)
bypasses `sp_get_date_dim` entirely and populates `RDB_DATE` via a
recursive CTE in `scripts/merge_and_verify.sh`. The SP is never EXEC'd
in our pipeline. **Anyone following RTR's documented setup path that
says "EXEC `sp_get_date_dim`" is broken on first run.**

## Related issues found during investigation

1. **Idempotency (separate from a bug).** Even after fixing 1A and 1B,
   the SP unconditionally inserts; re-invoking it for an overlapping
   year range would PK-violate on `DATE_KEY`. The line-26 `IF NOT EXISTS`
   guard hints that some idempotency was intended, but the rest of the
   body doesn't honor it. Maintainer should decide whether the SP is
   one-shot or re-runnable.
2. **No CREATE TABLE schema for the missing staging table.** Column
   types must be inferred from the SELECT list at source lines 36-47,
   cross-referenced with `INFORMATION_SCHEMA.COLUMNS` for `RDB_DATE`.
3. **No unit test exercises this SP.** Grep across
   `liquibase-service/src/test/` returns zero hits. A single
   end-to-end test that EXEC'd it once on a fresh DB would have caught
   this at CI time.
4. **Liquibase routines run with `runOnChange=false` typically.** When
   fixed upstream, deployments built on top of an already-applied
   6.0.18.1 baseline won't auto-pick-up the corrected definition unless
   the changelog id is bumped or the routine is re-deployed via a new
   migration. Worth confirming with the RTR release process.

## Reproduction

See `repro.sql` in this directory. Run with:

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
sqlcmd -S localhost,3433 -U sa -C -i repro.sql
```

Single .sql file, runnable read-only — wraps `EXEC dbo.sp_get_date_dim
2026, 2026` in TRY/CATCH and prints captured `ERROR_NUMBER` /
`ERROR_MESSAGE` / etc.; verified working against the live DB; touches
no state.
