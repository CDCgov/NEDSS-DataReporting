**Title:** (merged on main — PR #827)

## Status
**Merged.** The fix landed on `main` as [PR #827](https://github.com/CDCgov/NEDSS-DataReporting/pull/827) (commit `bb882115`). The accompanying unit test landed at `reporting-pipeline-service/src/test/resources/testData/unit/bug6_ldf_data_truncation/`.

## Description
`sp_nrt_ldf_postprocessing` mapped `nrt_ldf_data.metadata_record_status_cd` (typically holds the canonical upstream ETL flag `'LDF_PROCESSED'`, 13 chars) into `LDF_DATA.RECORD_STATUS_CD` (`varchar(8)` with a CHECK constraint for `'ACTIVE'`/`'INACTIVE'`). The INSERT therefore failed with Msg 2628 "String or binary data would be truncated" the first time any LDF data was flowed through.

This was a mapping bug, not a width oversight: the destination column was sized for the lifecycle status (`ACTIVE`/`INACTIVE`), not for the ETL processing flag. The peer column `nrt_ldf_data.record_status_cd` is the LDF-answer's own active/inactive status and is the semantically correct source. The SP already filters on this column at line 873 (`where ld.RECORD_STATUS_CD is not null`) but never selected it.

This PR changes the source column from `metadata_record_status_cd` to `record_status_cd` at all three sites in the SP (SELECT INTO at line 874, UPDATE at line 1017, INSERT at line 1143 — including the SELECT INTO that propagates the column name into a temp table).

Verified locally: post-fix, `LDF_DATA` accepts the inserted row with `RECORD_STATUS_CD='ACTIVE'` (passes CHECK constraint); no Msg 2628 in `job_flow_log`.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
Line numbers drifted slightly from the original investigation (874/1017/1143 on current `main` vs 863/1006/1132 in `findings.md`). A `testData/unit` fixture is included that seeds `nrt_ldf_data` with `metadata_record_status_cd='LDF_PROCESSED'` and `record_status_cd='ACTIVE'`, EXECs the SP, and asserts `LDF_DATA.RECORD_STATUS_CD='ACTIVE'`.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
