# Bug #9 — sp_dyn_dm_repeatvarch_postprocessing: UNPIVOT type conflict

**Status**: Surfaced 2026-05-21 during work to extend orchestrator
Step 9 with the `sp_dyn_dm_*` chain. **FIXED 2026-05-21** on
`aw/odse-test-seed` (commit `a88e40e5`).

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

## Fix landed (commit a88e40e5)

Same pattern existed in **three** SPs, all fixed:
- `205-sp_dyn_dm_repeatvarch_postprocessing`: build
  `@RDB_COLUMN_CAST_LIST` with `CAST(<col> AS nvarchar(max))`, use in
  inner SELECT before UNPIVOT.
- `235-sp_dyn_dm_repeatnumeric_postprocessing`: same; the output
  column COL1 is `varchar(max)` so nvarchar(max) flows through
  unchanged.
- `210-sp_dyn_dm_repeatdate_postprocessing`: TRY_CAST (not CAST) to
  DATE — output column is `dateColumn DATE`, TRY_CAST handles
  non-date strings gracefully.

Also added `SET QUOTED_IDENTIFIER ON; GO` at the top of each file.
Liquibase applies routines with QI ON by default; sqlcmd-driven
re-applies inherit the session default (typically OFF), which makes
the dynamic SELECT INTO inside the SPs raise Msg 1934 at execution
time. Pinning QI ON in the file makes the SP behavior independent
of the applying tool.

Verified: `sp_dyn_dm_main_postprocessing @datamart_name =
'HEPATITIS_A_ACUTE'` now runs to `SP_COMPLETE` in dyn_dm_main +
createdm + invest_clear sub-SPs. No Msg 8167.

## What didn't move (yet)

`DM_INV_HEPATITIS_A_ACUTE` itself stays at 0 rows because v1/v2 Hep A
Investigations don't have repeating-block answer data. A future
fixture authoring repeat-block answers would populate it. That table
also isn't in the 118-table in-scope catalog.

The downstream in-scope `D_INV_*` dims (D_INV_CLINICAL,
D_INV_EPIDEMIOLOGY, D_INV_LAB_FINDING, D_INV_ADMINISTRATIVE) populate
from a different upstream path (`sp_dyn_dm_page_builder_d_inv_postprocessing`
called repeatedly from dyn_dm_main). Those SPs are now unblocked from
the previous error too; whether they populate depends on richer
nrt_page_case_answer data we have for Hep A.
