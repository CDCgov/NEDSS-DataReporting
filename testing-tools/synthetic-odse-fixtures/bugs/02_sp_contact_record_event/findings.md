# Bug #2: sp_contact_record_event references nbs_odse.dbo.fn_get_value_by_cd_codeset

**Status**: Confirmed. SP unrunnable against any input.
**Severity**: High (the contact-record event chain cannot run at all).
**Surfaced by**: comparison-fixtures Tier 1 Contact Record fixture authoring.

## The bug

```sql
-- File: liquibase-service/src/main/resources/db/005-rdb_modern/routines/069-sp_contact_record_event-001.sql
-- Line 69 (inside SELECT INTO #CONTACT_RECORD_INIT, lines 60-158):
case
    when (cc.CONTACT_STATUS is not null and cc.CONTACT_STATUS != '')
        then (select * from nbs_odse.dbo.fn_get_value_by_cd_codeset(cc.CONTACT_STATUS, 'INV109'))
    end as CTT_STATUS,
```

The function `fn_get_value_by_cd_codeset` is defined in `RDB_MODERN.dbo`, not `nbs_odse.dbo`. SQL Server resolves 3-part names at compile time when both database and schema exist, so Msg 208 fires before any row is evaluated. The `CASE` gate on `cc.CONTACT_STATUS` does not short-circuit it; setting `CONTACT_STATUS=NULL` on every `ct_contact` row does not help. The SP is unrunnable against any input.

## Exact error message

```
Msg 208, Level 16, State 1, Server buildkitsandbox, Procedure dbo.sp_contact_record_event, Line 52
Invalid object name 'nbs_odse.dbo.fn_get_value_by_cd_codeset'.
Msg 266, Level 16, State 2, Server buildkitsandbox, Procedure dbo.sp_contact_record_event, Line 52
Transaction count after EXECUTE indicates a mismatching number of BEGIN and COMMIT statements. Previous count = 0, current count = 1.
```

(SP error_line=52 is the `BEGIN TRANSACTION`; the offending function call is at source-file line 69. The Msg 266 follow-on is a side-effect of compile-time failure inside the SP's `BEGIN TRANSACTION` block.)

## Where the function actually lives

Verified via `sys.objects` queries against all five baseline DBs (see `repro.sql` step 1):

| database | object | type_desc |
| --- | --- | --- |
| RDB_MODERN | fn_get_value_by_cd_codeset | SQL_INLINE_TABLE_VALUED_FUNCTION |
| nbs_odse | (not found) | — |
| nbs_srte | (not found) | — |
| RDB | (not found) | — |
| NBS_MSGOUTE | (not found) | — |

Created by `liquibase-service/src/main/resources/db/005-rdb_modern/functions/006-fn_get_value_by_cd_codeset-001.sql`. Its body internally references `nbs_srte.dbo.codeset` and `nbs_srte.dbo.code_value_general`, but the function object itself is owned by `RDB_MODERN.dbo`.

## Other routines with the same cross-DB function-resolution bug?

None. Grep across the entire DB tree:

```
$ grep -rn "nbs_odse\.dbo\.fn_" liquibase-service/src/main/resources/db/
liquibase-service/src/main/resources/db/005-rdb_modern/routines/069-sp_contact_record_event-001.sql:69:
    then (select * from nbs_odse.dbo.fn_get_value_by_cd_codeset(cc.CONTACT_STATUS, 'INV109'))
```

The only other RTR routine that calls `fn_get_value_by_cd_codeset` is `005-rdb_modern/routines/056-sp_investigation_event-001.sql`, which does so correctly via 2-part `dbo.fn_get_value_by_cd_codeset` at 15 call sites (lines 181, 191, 212, 225, 234, 240, 251, 255, 260, 269, 277, 282, 287, 295, 307). That SP is invoked under `RDB_MODERN` context so `dbo.` resolves correctly.

The bug is isolated to a single line in a single SP, almost certainly a copy-paste artefact from the SP's many correct `nbs_odse.dbo.<table>` references (`nbs_odse.dbo.CT_CONTACT` at line 137; `nbs_odse.dbo.NBS_ACT_ENTITY` at lines 155-157).

## Suggested fix

**Recommended (1-line change):**

```diff
@@ -66,7 +66,7 @@
         cc.CONTACT_REFERRAL_BASIS_CD,
         case
             when (cc.CONTACT_STATUS is not null and cc.CONTACT_STATUS != '')
-                then (select * from nbs_odse.dbo.fn_get_value_by_cd_codeset(cc.CONTACT_STATUS, 'INV109'))
+                then (select * from dbo.fn_get_value_by_cd_codeset(cc.CONTACT_STATUS, 'INV109'))
             end as CTT_STATUS,
```

`sp_contact_record_event` is itself defined in `RDB_MODERN.dbo` (CREATE statement is `CREATE PROCEDURE [dbo].[sp_contact_record_event]`; file is under `db/005-rdb_modern/routines/`), so unqualified `dbo.` binds correctly. This matches the convention used by `sp_investigation_event` (the only other RTR caller). Verified by `repro.sql` step 4.

**Alternative (more invasive):** explicit `RDB_MODERN.dbo.fn_get_value_by_cd_codeset` qualifier. Works, but brittle in renamed-DB environments and inconsistent with the established pattern.

**Not recommended:** moving the function into `nbs_odse.dbo`. This would introduce an RTR-specific function in the OLTP database, a layering violation. Fix the caller, not the function.

## Comparison-fixtures workaround

The comparison-fixtures project's `merge_and_verify.sh` orchestrator
skips invoking `sp_contact_record_event` entirely, since the SP
is unrunnable. The Contact postprocessing SPs
(`sp_d_contact_record_postprocessing`, `sp_f_contact_record_case_postprocessing`)
read from `nrt_contact` staging directly and do not require the event SP
to have run. So contact-record dim/fact coverage is unaffected by this
bug; only the JSON-projection that would feed downstream Kafka/Datamart
is missing.

Per `STRATEGY.md`, the fixture project deliberately bypasses CDC anyway,
so this bug is documented but not blocking for the fixture's purpose.

## Reproduction

See `repro.sql` in this directory. Run with:

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
sqlcmd -S localhost,3433 -U sa -C -i repro.sql
```

Expected output: Step 1 confirms function only in `RDB_MODERN`; Step 2
confirms SP source still has the bad reference; Step 3 EXECs the SP
inside TRY/CATCH and surfaces Msg 208; Step 4 demonstrates the fix
works via correct 2-part name.
