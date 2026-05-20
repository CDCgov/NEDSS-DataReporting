**Title:** Fix sp_d_morbidity_report_postprocessing: rewrite user-comment join via NRT staging CSV

## Description
The user-comment query at lines 802-816 of `sp_d_morbidity_report_postprocessing` was self-defeating: it joined the morb Order to itself and filtered `obs_domain_cd_st_1 IN ('C_Order','C_Result')` — impossible, since the Order row's domain is `'Order'`. Result: `MORB_RPT_USER_COMMENT` never populated.

The fix walks Order → C_Result via the staging CSV that NRT already projects (`nrt_morbidity_observation.followup_observation_uid`), filtered to `obs_domain_cd_st_1 = 'C_Result'`. No cross-DB reads — postprocessing SPs read NRT staging only.

Verified locally: `MORB_RPT_USER_COMMENT` populates with the seeded comment for morb uid 20080010; `job_flow_log` steps 19 + 27 both at row_count=1.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
No `testData/unit` fixture: exercising the SP needs ~10 seeded tables across RDB_MODERN + nbs_odse. End-to-end repro lives in `utilities/comparison-fixtures/bugs/03_morb_rpt_user_comment/repro.sql`.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
