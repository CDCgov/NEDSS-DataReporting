# Bug #13 — sp_sld_investigation_repeat_postprocessing: TEXT pivot column-list builder NULL-propagates

**Status**: Surfaced 2026-05-24 by Agent H. Not fixed. Open. Real RTR bug.

## Symptom

After applying both `zz_d_inv_place_repeat_enrich.sql` and any other
fixture authoring TEXT-typed answers on the same PHC (22006000),
`sp_sld_investigation_repeat_postprocessing` silently fails to populate
the TEXT columns of `D_INVESTIGATION_REPEAT`. The SP's tail-EXEC
returns 0 rows affected on its dynamic SQL, but no error is raised.

Repro:
1. Apply `zz_d_inv_place_repeat_enrich.sql` (agent-D2 fixture).
2. Apply any fixture adding answer rows with `data_type='TEXT'` on PHC 22006000.
3. Run `EXEC dbo.sp_sld_investigation_repeat_postprocessing @batch_id=<n>, @phc_id_list=N'22006000', @debug=0;`
4. Query `D_INVESTIGATION_REPEAT` — TEXT columns are NULL even where the source answer rows have non-NULL `answer_txt`.

## Root cause

In `liquibase-service/src/main/resources/db/005-rdb_modern/routines/010-sp_sld_investigation_repeat_postprocessing-001.sql`,
around line 212, the SP builds its dynamic pivot column list:

```sql
DECLARE @cols nvarchar(max) = N'';
SELECT @cols += N', p.' + QUOTENAME(RDB_COLUMN_NM) + ...
FROM #text_data_REPT;
```

T-SQL's compound assignment `@cols += <expr>` propagates NULL: if any
row in `#text_data_REPT` has `RDB_COLUMN_NM = NULL`, the assignment
`@cols = @cols + ', p.' + QUOTENAME(NULL) + ...` yields NULL. From that
point on `@cols` stays NULL, the constructed `@sql` is NULL, and the
final `EXEC sp_executesql @sql` silently no-ops.

The `zz_d_inv_place_repeat_enrich.sql` fixture (agent-D2, UIDs
22010001-22010006) authors 6 nrt_page_case_answer rows with
`rdb_column_nm = NULL` (intentionally — they target a different SP via
`part_type_cd`, not the repeat-block SP). Those rows end up in
`#text_data_REPT` for PHC 22006000 because the temp-table population
filter doesn't exclude NULL rdb_column_nm rows.

## Suggested fix

Two options:

1. **In the SP**: add `WHERE RDB_COLUMN_NM IS NOT NULL` to:
   - The temp-table population query that builds `#text_data_REPT`
     (the column list builder operates on what's in there).
   - The pivot inner SELECT(s) at line ~212 and the equivalent
     date/numeric/coded pivot builders elsewhere in the file.

2. **Defensive coalesce**: `@cols += COALESCE(N', p.' + QUOTENAME(RDB_COLUMN_NM) + ..., N'')` — guards against the NULL row contaminating the entire assignment.

Option 1 is preferred — the temp-table-level filter is more efficient
than building rows you'll skip in the pivot.

## Tables blocked

- `D_INVESTIGATION_REPEAT` — TEXT columns stay NULL when any
  same-PHC fixture authors NULL-rdb_column_nm answer rows. This means
  the d_investigation_repeat enrich fixture's TEXT columns can't
  populate without either:
  (a) the SP being fixed, or
  (b) removing/rewriting the place-repeat fixture rows.

## Workaround

Agent H's `zz_d_investigation_repeat_more_blocks.sql` (UIDs
22014000-22014999) emphasized DATE / NUMERIC / CODED answer types
(which use separate pivot builders that don't hit this bug) and
avoided TEXT to sidestep the issue.

The downstream effect on column coverage: ~30-40 TEXT-typed D_INV_REPEAT
columns will stay unpopulated until either bug #13 is fixed upstream
or the place-repeat fixture is reworked to not use PHC 22006000
(but that would lose the place-repeat coverage entirely, since 22006000
is the only Pertussis Investigation).

## Cross-cutting impact

This is a generic dynamic-SQL builder pattern that may exist in other
RTR SPs (any SP that does dynamic UNPIVOT/PIVOT over a temp-table
column list). A targeted audit:

```
grep -rn "@\w* += N'" liquibase-service/src/main/resources/db/005-rdb_modern/routines/ | head
```

would find every analogous case. Same fix (filter NULLs at temp-table
population or COALESCE the concat) applies.
