**Title:** (not applicable — resolved out-of-band; no PR needed)

## Status
**Resolved.** Bug #1 is a non-issue in all normal working environments — `RDB_DATE` is correctly populated by the database seeds, so `sp_get_date_dim` is never actually invoked on the path observed in the comparison-fixtures investigation. A separate PR is in-flight to correct the seed path that originally led the investigation here.

The local fix branch (`aw/app-471/bug-1`, commits `1092a23f` + `4a66bb8f`) is retained for reference but will not be opened as a PR. The `repro.sql` and `findings.md` entries are kept for traceability.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)
