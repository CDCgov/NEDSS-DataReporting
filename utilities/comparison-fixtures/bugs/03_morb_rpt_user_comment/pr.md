**Title:** Fix sp_d_morbidity_report_postprocessing: rewrite user-comment join via NRT staging CSV

## Description
The user-comment query at lines 802-816 of `sp_d_morbidity_report_postprocessing` (file `016-sp_nrt_morbidity_report_postprocessing-001.sql`) was self-defeating: it joined the morbidity Order observation to itself via `root.morb_rpt_uid = obs.observation_uid` and then filtered `obs.obs_domain_cd_st_1 IN ('C_Order', 'C_Result')` — impossible, because the Order row's `obs_domain_cd_st_1` is `'Order'`. The temp table was therefore always empty and `MORB_RPT_USER_COMMENT` never populated even when a comment existed.

This PR replaces the broken self-join with a **staging-side walk** that stays inside RDB_MODERN's NRT layer:

```
root  -- #nrt_morbidity_observation (carries followup_observation_uid CSV)
      -- CROSS APPLY string_split(followup_observation_uid, ',')  → child observation_uids
      -- #morb_obs_reference  WHERE obs_domain_cd_st_1 = 'C_Result'
      -- #tmp_nrt_observation_txt  ON ovt.observation_uid = cr.observation_uid
```

The upstream NRT row `nrt_morbidity_observation.followup_observation_uid` is the debezium projection of the Order's act_relationship children (mixed `C_Order` / `C_Result` / `Result` rows). The `C_Result` filter selects just the user-comment row, whose `activity_to_time`, `add_user_id`, and linked `nrt_observation_txt.ovt_value_txt` carry the user-comment metadata and text.

**Why NRT staging, not `nbs_odse.dbo.act_relationship`:** the `sp_nrt_*_postprocessing` / `sp_d_*` layer reads RDB_MODERN-side staging only. A static audit of every file in `liquibase-service/src/main/resources/db/005-rdb_modern/routines/` shows zero `nbs_odse.dbo.*` joins outside the `sp_*_event` SPs (which project ODSE → JSON by design). An earlier draft of this fix used a two-hop `nbs_odse.dbo.act_relationship` traversal; reviewer feedback flagged it as a convention violation. This rewrite uses the staging projection that already collapses the two-hop graph walk. The convention is documented in `utilities/comparison-fixtures/STRATEGY.md` "Convention: postprocessing SPs read NRT staging only — never ODSE".

Verified locally: applied the routine, truncated `MORB_RPT_USER_COMMENT`, ran `EXEC dbo.sp_d_morbidity_report_postprocessing @pMorbidityIdList = N'20080010'`. `MORB_RPT_USER_COMMENT` now contains the seeded comment for the Tier 1 v2 Morb Order (uid 20080010); `job_flow_log` shows step 19 (`Generating ##SAS_morb_Rpt_User_Comment`) and step 27 (`Insert into morb_Rpt_User_Comment`) both at `row_count=1` with no errors.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
No `testData/unit` fixture was added: exercising the SP requires seeding ~10 tables across both `RDB_MODERN` and `nbs_odse` (essentially reproducing the Tier 1 morbidity fixture). End-to-end repro coverage lives in `utilities/comparison-fixtures/bugs/03_morb_rpt_user_comment/repro.sql`.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
