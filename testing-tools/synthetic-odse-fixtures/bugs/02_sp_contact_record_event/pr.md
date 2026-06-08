**Title:** (not applicable; bug already fixed on main via PR #769)

## Description
`sp_contact_record_event` previously referenced `nbs_odse.dbo.fn_get_value_by_cd_codeset`, but the function actually lives in `RDB_MODERN.dbo`, so the SP failed on every invocation with "function not found".

Investigation confirmed this was resolved by [PR #769 "change call to stored procedure"](https://github.com/cdcent/NEDSS-DataReporting/pull/769) (commit `a0dbf3be`, 2026-04-27), which schema-qualified the call to the two-part name `dbo.fn_get_value_by_cd_codeset`. `main` at line 69 is already correct and the repro now passes without error.

No new fix branch was opened; the empty `aw/app-471/bug-2` placeholder was deleted.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
This entry is retained in the bug catalog for traceability; the comparison-fixtures investigation predated PR #769.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
