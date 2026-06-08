**Title:** Fix LDF datamart SPs: guard unguarded SUBSTRING idiom across 6 per-condition SPs

## Description
Six per-condition LDF datamart SPs (`bmird`, `foodborne`, `mumps`, `tetanus`, `vaccine_prevent_diseases`, `hepatitis`) build a comma-separated `@dynamiccolumnUpdate` from `INFORMATION_SCHEMA.COLUMNS`, then unconditionally strip the trailing comma with `SUBSTRING(@dynamiccolumnUpdate, 1, LEN(@dynamiccolumnUpdate) - 1)`. When the per-condition `LDF_<COND>` table has only its baseline-key columns (no dynamic LDF answer columns added yet), the SELECT matches zero rows, `@dynamiccolumnUpdate` stays `''`, and `SUBSTRING('', 1, -1)` raises Msg 537. The outer TRY/CATCH swallows it into a `job_flow_log` ERROR row.

Three peer sites in the same files already wrap the SUBSTRING + EXEC in `IF @dynamiccolumnUpdate IS NOT NULL AND @dynamiccolumnUpdate != '' BEGIN ... END`. This applies that same guard to the six unguarded sites:

- `285-sp_ldf_bmird_datamart_postprocessing-001.sql:603`
- `290-sp_ldf_foodborne_datamart_postprocessing-001.sql:893`
- `295-sp_ldf_mumps_datamart_postprocessing-001.sql:627`
- `300-sp_ldf_tetanus_datamart_postprocessing-001.sql:833`
- `305-sp_ldf_vaccine_prevent_diseases_datamart_postprocessing-001.sql:1105`
- `320-sp_ldf_hepatitis_datamart_postprocessing-001.sql:594`

Verified locally: none of the six SPs emit a Msg 537 ERROR row in `job_flow_log` when executed against an empty per-condition LDF table.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
Independent of bug #7: fires on a clean liquibase-applied DB the first time any per-condition LDF SP runs, before its dynamic columns are ever added.

Site `290` (foodborne) was already guarded with a different form (`IF LEN(@dynamiccolumnUpdate) > 0`); rewritten to match the `IS NOT NULL AND != ''` form used at the five peer sites.

Includes a `testData/unit` fixture that EXECs the tetanus SP against an empty `LDF_TETANUS` and asserts no Msg 537 ERROR row in `job_flow_log`.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
