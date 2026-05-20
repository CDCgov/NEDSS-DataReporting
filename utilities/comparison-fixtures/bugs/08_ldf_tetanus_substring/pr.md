**Title:** Fix LDF datamart SPs: guard unguarded SUBSTRING idiom across 6 per-condition SPs

## Description
Six per-condition LDF datamart SPs (`bmird`, `foodborne`, `mumps`, `tetanus`, `vaccine_prevent_diseases`, `hepatitis`) contained an unguarded `SUBSTRING(@dynamiccolumnUpdate, 1, LEN(@dynamiccolumnUpdate) - 1)` idiom. When the per-condition `LDF_<COND>` table has only its baseline-key columns (no dynamic LDF answer columns added yet), the preceding `SELECT @dynamiccolumnUpdate = COALESCE(...) FROM INFORMATION_SCHEMA.COLUMNS WHERE ...` matches zero rows, leaving `@dynamiccolumnUpdate = ''`. Then `LEN('') - 1 = -1`, and `SUBSTRING('', 1, -1)` throws Msg 537 "Invalid length parameter passed to LEFT or SUBSTRING". The outer TRY/CATCH swallows it and writes an ERROR row to `job_flow_log`.

Three peer sites in the same SP family already used the correct guard pattern (`IF @dynamiccolumnUpdate IS NOT NULL AND @dynamiccolumnUpdate != ''`). This PR applies the same existing pattern at the six unguarded sites:

- `285-sp_ldf_bmird_datamart_postprocessing-001.sql:603`
- `290-sp_ldf_foodborne_datamart_postprocessing-001.sql:893`
- `295-sp_ldf_mumps_datamart_postprocessing-001.sql:627`
- `300-sp_ldf_tetanus_datamart_postprocessing-001.sql:833`
- `305-sp_ldf_vaccine_prevent_diseases_datamart_postprocessing-001.sql:1105`
- `320-sp_ldf_hepatitis_datamart_postprocessing-001.sql:594`

Verified locally: post-fix, none of the six SPs emit Msg 537 ERROR rows when executed against an empty per-condition LDF table.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
This is a stand-alone fix: the unguarded SUBSTRING fires on a clean liquibase-applied DB the very first time any per-condition LDF SP is invoked, before its dynamic columns have ever been added — independent of the LDF_DIMENSIONAL_DATA issue in bug #7.

Site `290` (foodborne) was already guarded with a different style (`IF LEN(@dynamiccolumnUpdate) > 0`). It was rewritten in this PR to use the same `IS NOT NULL AND != ''` form as the five peer sites for visual consistency across the family.

A `testData/unit` fixture is included that EXECs the tetanus SP against an empty `LDF_TETANUS` and asserts no Msg 537 ERROR row appears in `job_flow_log` for that batch.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
