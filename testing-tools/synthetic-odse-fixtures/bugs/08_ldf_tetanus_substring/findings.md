# Bug #8: sp_ldf_tetanus_datamart_postprocessing line 824 (actual: 833): Invalid length parameter passed to LEFT or SUBSTRING

**Status**: Confirmed via live repro. **One instance of a 6-instance bug family across the per-condition LDF datamart SPs.**
**Severity**: Medium (derivative in current fixture state; stand-alone in nature, fires on clean liquibase-applied DB before dynamic columns are ever added).
**Surfaced by**: comparison-fixtures Tier 3 LDF Tetanus answers fixture.

## Bug

`sp_ldf_tetanus_datamart_postprocessing` fails at the unguarded
`SUBSTRING(@dynamiccolumnUpdate, 1, LEN(@dynamiccolumnUpdate) - 1)`
call on line 833 (SQL Server reports "Error Line: 824", which is the
`BEGIN TRANSACTION` opening that block; the source spans 824/833
interchangeably).

When `LDF_TETANUS` has only the 7 baseline-key columns (no dynamic LDF
answer columns yet), the preceding
```sql
SELECT @dynamiccolumnUpdate = COALESCE(@dynamiccolumnUpdate + '...', '...')
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name='LDF_TETANUS' AND COLUMN_NAME NOT IN (<the 7 keys>)
```
matches zero rows, leaving `@dynamiccolumnUpdate = ''`. Then
`LEN('') - 1 = -1`, and `SUBSTRING('', 1, -1)` throws Msg 537. The SP's
outer `TRY/CATCH` swallows it and writes an `ERROR` row to
`job_flow_log` (step_name "UPDATE LDF_TETANUS when there is no record
in the LDF_DIMENSIONAL_DATA", step 14.0).

## Exact error message

```
Msg 537, Level 16, State 3
Invalid length parameter passed to the LEFT or SUBSTRING function.
```

## Root cause chain

`LDF_TETANUS` columns are added dynamically by an `ALTER TABLE … ADD …`
at line 714, gated by `IF EXISTS (SELECT 1 FROM #MISSED_COLS)`.
`#MISSED_COLS` is built from a global temp table seeded from
`LDF_DIMENSIONAL_DATA`. With `LDF_DIMENSIONAL_DATA` empty (Bug #7), no
ALTER runs, the table stays at 7 baseline cols, and the unguarded
SUBSTRING blows up.

## Relationship to Bug #7

Derivative in the current fixture state; **stand-alone in nature**.
The unguarded SUBSTRING also fires on a clean liquibase-applied DB the
first time any per-condition LDF SP is invoked before its dynamic
columns have ever been added. Even if Bug #7 is fixed, the very first
invocation against an empty per-condition LDF table will trip this
defect. Fixing #7 only masks the happy-path occurrence; the latent
bug remains.

## Family-wide audit

The same `SUBSTRING(@dynamiccolumnUpdate, 1, LEN(@dynamiccolumnUpdate) - 1)`
idiom appears at **9 sites across the 6 per-condition LDF datamart SPs**.

**Three are already guarded** with
`IF @Alterdynamiccolumnlist IS NOT NULL AND @Alterdynamiccolumnlist != ''`:
- `285-sp_ldf_bmird_datamart_postprocessing-001.sql:530`
- `295-sp_ldf_mumps_datamart_postprocessing-001.sql:527`
- `320-sp_ldf_hepatitis_datamart_postprocessing-001.sql:523`

**Six are unguarded and vulnerable** (bug #8 is one of these six):
- `285-sp_ldf_bmird_datamart_postprocessing-001.sql:603`
- `290-sp_ldf_foodborne_datamart_postprocessing-001.sql:893`
- `295-sp_ldf_mumps_datamart_postprocessing-001.sql:627`
- `300-sp_ldf_tetanus_datamart_postprocessing-001.sql:833` (this bug)
- `305-sp_ldf_vaccine_prevent_diseases_datamart_postprocessing-001.sql:1105`
- `320-sp_ldf_hepatitis_datamart_postprocessing-001.sql:594`

(`280-sp_ldf_generic_datamart_postprocessing-001.sql` does not contain
the idiom; no per-condition table to NULL-out.)

## Suggested fix

Either of two paths, applied to all 6 unguarded sites:

### Option A: add the existing guard pattern

Wrap the SUBSTRING+EXEC in:
```sql
IF @dynamiccolumnUpdate IS NOT NULL AND @dynamiccolumnUpdate <> ''
BEGIN
    SET @sql = '...' + SUBSTRING(@dynamiccolumnUpdate, 1, LEN(@dynamiccolumnUpdate) - 1) + ...;
    EXEC sp_executesql @sql;
END
```
Matches the existing pattern in the 3 already-guarded sites.

### Option B: use STRING_AGG

Replace the whole `COALESCE(..., '...,')` accumulator + trailing-comma
strip idiom with `STRING_AGG(col, ', ')` which returns NULL on empty
input (and the EXEC is naturally short-circuited by checking for
NULL). The SP already uses `STRING_AGG` at line 865, so the SQL Server
version supports it.

Either change is independent of and additive to fixing Bug #7.

## Reproduction

See `repro.sql` in this directory. It:
1. Shows pre-conditions: `LDF_DIMENSIONAL_DATA` = 0 rows; `LDF_TETANUS`
   has only 7 baseline cols; `INVESTIGATION_KEY=5` for CASE_UID 22000200
   (the Tetanus Investigation variant from Tier 3 multi-condition).
2. Reproduces the exact `SUBSTRING('', 1, LEN('')-1)` call locally and
   catches Msg 537 (severity 16, state 3).
3. EXECs the real SP and queries `job_flow_log` for the resulting
   ERROR row.
4. Confirms post-state unchanged.

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
sqlcmd -S localhost,3433 -U sa -C -i repro.sql
```
