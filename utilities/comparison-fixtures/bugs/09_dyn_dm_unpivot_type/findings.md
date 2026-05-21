# Bug #9 — sp_dyn_dm_repeatvarch_postprocessing: UNPIVOT type conflict

**Status**: Surfaced 2026-05-21 during work to extend orchestrator
Step 9 with the `sp_dyn_dm_*` chain. Not yet investigated in depth;
no fix attempted. Orchestrator catches the error and continues.

## Symptom

```sql
EXEC dbo.sp_dyn_dm_main_postprocessing
    @datamart_name = N'HEPATITIS_A_ACUTE',
    @phc_id_list   = N'20000100,20050010',
    @debug         = 'false';
```

Returns:

```
Error Number: 8167
Error Severity: 16
Error State: 1
Error Line: 1
Error Message: The type of column "EPI_CNTRY_OF_EXP" conflicts with the
type of other columns specified in the UNPIVOT list.

Error Number: 266
Error Line: 446
Error Message: Transaction count after EXECUTE indicates a mismatching
number of BEGIN and COMMIT statements. Previous count = 1, current
count = 0.
```

The 266 is a downstream symptom of the 8167 — the inner `EXEC
sp_executesql @sql` raised and rolled back, leaving the outer
TRY/CATCH txn-counter unbalanced.

## Root cause (initial read)

`liquibase-service/src/main/resources/db/005-rdb_modern/routines/205-sp_dyn_dm_repeatvarch_postprocessing-001.sql:531-557`
("step 16: GENERATING @tmp_DynDm_REPEAT_BLOCK_OUT") builds a dynamic
UNPIVOT over a column list (`@RDB_COLUMN_COMMA_LIST`) derived from
metadata. The columns in the source table
(`tmp_DynDm_REPEAT_BLOCK_<DATAMART_NAME>_<batch_id>`) carry the
**types they were created with**, which depend on the
`nrt_metadata_columns` / `v_nrt_d_inv_repeat_blockdata` rows for the
target datamart. SQL Server's `UNPIVOT` requires every column in the
IN list to share a single type — one mismatch (e.g.,
`EPI_CNTRY_OF_EXP varchar(N)` next to a column declared `varchar(M)` for
M≠N, or `varchar` next to `nvarchar`) raises 8167.

The SP only does `UNPIVOT` — no `CAST` / `CONVERT` to harmonize types
first.

## Why our team likely hasn't seen this in normal UI / comparison
testing

The dyn_dm chain is invoked at production scale across many
investigations whose metadata definitions have been hand-curated by
form authors. Pruduction's `nrt_metadata_columns` rows probably define
the repeat-block columns with **uniform types** (all `varchar(2000)`,
for instance), so the UNPIVOT happens to work. Our baseline ships
NEDSS's standard metadata seed, which appears to declare
heterogeneous types for the repeat-block columns of
`HEPATITIS_A_ACUTE`. Worth confirming whether this is:

- (a) A baseline-data defect — our test image's metadata is wrong and
  prod would not exhibit this; OR
- (b) A latent SP defect that prod happens to dodge via uniform
  metadata, but which would break on any genuine heterogeneous
  schema.

If (b), the fix is a SQL-side `CAST(<col> AS nvarchar(max))` per
column in the dynamic SELECT before UNPIVOT.

## Tables blocked

`DM_INV_HEPATITIS_A_ACUTE` and any other `DM_INV_<DATAMART>` whose
repeat-block column types are heterogeneous in `nrt_metadata_columns`.
At minimum, `HEPATITIS_A_ACUTE` (verified by repro). Likely affects
several other PG_-form datamarts as well; deferred testing until the
fix is in place.

## Implications for the comparison test

`DM_INV_*` tables are **expected output** of RTR's dyn_dm pipeline —
they're the modern equivalent of MasterETL's `DM_INV_*` family. Until
this bug is resolved, every `DM_INV_*` table will appear as "RDB has
rows, RDB_MODERN doesn't" in the diff — a false-positive coverage gap
that hides any real RTR/MasterETL divergence in these tables.

## Suggested fix path

1. Read `nrt_metadata_columns WHERE TABLE_NM LIKE '%REPEAT%' AND
   DATAMART_NM = 'HEPATITIS_A_ACUTE'` to confirm column-type heterogeneity.
2. If heterogeneous: amend the SP's dynamic SQL to wrap each column
   reference in `CAST(<col> AS nvarchar(max))`. The UNPIVOT then sees
   a uniform `nvarchar(max)` IN list.
3. Run repro to confirm `DM_INV_HEPATITIS_A_ACUTE` populates.
4. Add to `bugs/README.md`.

Repro and SP source paths logged for future follow-up.
