# Bug #4: sp_nrt_provider_postprocessing line 564 typo

**Status**: Confirmed via static analysis + live repro.
**Severity**: Low/latent (only fires on UPDATE-with-diff path; INSERT-only flows never trip it).
**Surfaced by**: comparison-fixtures Tier 1 Provider canary static-extract pass.

## Bug

`dbo.sp_nrt_provider_postprocessing` references a non-existent temp table
`#PATIENT_UPDATE_LIST` at source-file line 564. The temp table is actually
named `#PROVIDER_UPDATE_LIST` and is declared at line 273 of the same SP.
The typo is a copy-paste from a Patient-style postprocessing template.

### Citations

| File | Line | Token | Status |
| --- | --- | --- | --- |
| `liquibase-service/src/main/resources/db/005-rdb_modern/routines/003-sp_nrt_provider_postprocessing-001.sql` | 273 | `into #PROVIDER_UPDATE_LIST` | correct (declaration) |
| same file | 545 | `select 1 from #PROVIDER_UPDATE_LIST` | correct (read inside `IF EXISTS`) |
| same file | **564** | `FROM #PATIENT_UPDATE_LIST` | **TYPO — temp table never created** |

Static count via `sys.sql_modules`: bad_ref_count=1, good_ref_count=2.

## Why it is latent in baseline 6.0.18.1

1. **Deferred name resolution for `#` temp tables.** SQL Server does NOT
   bind `#PATIENT_UPDATE_LIST` at `CREATE PROCEDURE` time, so the SP installs
   without warning.
2. **Gated by `IF EXISTS` (lines 544-551).** The `SELECT ... FROM
   #PATIENT_UPDATE_LIST FOR JSON PATH` at lines 557-566 lives inside the
   `BEGIN ... END` block of the `IF EXISTS` over `#PROVIDER_UPDATE_LIST`.
   When the predicate is false the binder never resolves the bad name.
3. **`#PROVIDER_UPDATE_LIST` is built by `D_PROVIDER p INNER JOIN
   #temp_prv_table tpt ON tpt.provider_key = p.provider_key`** (lines
   231-276). On the first run for a UID (INSERT path) the row does not yet
   exist in `D_PROVIDER`, so the join produces 0 rows. `IF EXISTS` is
   trivially false.
4. **Even on an UPDATE re-run with no diff**, every CASE evaluates to 0;
   the `>= 1` filter keeps `IF EXISTS` false.

The Tier 1 Provider canary only exercises the INSERT path, so it never trips
this bug. Per `coverage_provider.md` "Notes for Tier 1 template" item 3, this
typo was spotted statically during the canary but not exercised.

## When it fires

Whenever `sp_nrt_provider_postprocessing` runs against UIDs already in
`D_PROVIDER` AND the staging row in `nrt_provider` differs on any of:

| CASE flag | Compared columns |
| --- | --- |
| `datamart_update` | `PROVIDER_LAST_NAME, PROVIDER_FIRST_NAME, PROVIDER_CITY, PROVIDER_STATE, PROVIDER_ZIP` |
| `tb_datamart_update` | `PROVIDER_LAST_NAME, PROVIDER_FIRST_NAME, PROVIDER_PHONE_WORK` |
| `morbidity_datamart_update` | `PROVIDER_STREET_ADDRESS_1, PROVIDER_STREET_ADDRESS_2, PROVIDER_PHONE_WORK, PROVIDER_PHONE_EXT_WORK` |
| `std_hiv_datamart_update` | `PROVIDER_QUICK_CODE` |
| `hep100_datamart_update` | `PROVIDER_MIDDLE_NAME, PROVIDER_COUNTY` |

Any change to any of those 11 distinct attributes between two consecutive
runs of the SP for the same UID will fire `Msg 208 — Invalid object name
'#PATIENT_UPDATE_LIST'`. The SP aborts with the `BEGIN TRANSACTION` (line
193) still open; the entire postprocessing batch fails and the Datamart
fan-out call to `sp_provider_dim_columns_update_to_datamart` (line 568) is
silently lost.

## Live reproduction

`repro.sql` in this directory was run against the live baseline. Step 3
output (verbatim):

```
error_number=208, error_severity=16, error_state=0,
error_procedure=dbo.sp_nrt_provider_postprocessing,
error_line_reported=545,
error_message=Invalid object name '#PATIENT_UPDATE_LIST'.
```

`error_line_reported=545` is the `IF EXISTS` block start; the actual bad
token is at source-file line 564. The mutation was wrapped in a
`BEGIN TRAN ... ROLLBACK`, and post-rollback `nrt_provider.last_name` for
UID 20010010 is verified back to `'Provider'`.

## Suggested fix

One-line edit. In `003-sp_nrt_provider_postprocessing-001.sql`, line 564:

```diff
-                    FROM #PATIENT_UPDATE_LIST
+                    FROM #PROVIDER_UPDATE_LIST
```

No other change required. The `SELECT` at lines 557-566 reads only
`provider_uid` and the five `*_update` flag columns — all already present in
`#PROVIDER_UPDATE_LIST` (declared at line 273 with the same column shape).

## Reproduction

See `repro.sql` in this directory. Run with:

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
sqlcmd -S localhost,3433 -U sa -C -i repro.sql
```

The repro uses `BEGIN TRAN ... ROLLBACK` so the database state is
unchanged after running. Steps: (1) static-extract the bad reference,
(2) confirm INSERT path is clean, (3) trigger the UPDATE-with-diff path
and capture Msg 208, (4) document suggested fix.
