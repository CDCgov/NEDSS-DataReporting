-- =====================================================================
-- Bug #3 repro: sp_d_morbidity_report_postprocessing — self-defeating
-- join+filter at lines 802-816 prevents MORB_RPT_USER_COMMENT from
-- ever populating.
--
-- File:  liquibase-service/src/main/resources/db/005-rdb_modern/routines/
--        016-sp_nrt_morbidity_report_postprocessing-001.sql
-- SP:    dbo.sp_d_morbidity_report_postprocessing
-- Lines: 802-816 (step "Generating ##SAS_morb_Rpt_User_Comment")
--
-- Note: the SP filename uses "nrt_morbidity_report_postprocessing" but
-- the SP body inside is "sp_d_morbidity_report_postprocessing"
-- (file/SP naming mismatch — also worth noting upstream).
--
-- WHAT THIS SCRIPT ASSUMES
--   - Database is up at localhost,3433.
--   - SQLCMDPASSWORD env var is set.
--   - Tier 1 morbidity fixture is already loaded:
--       fixtures/00_foundation/00_foundation.sql
--       fixtures/10_subjects/morbidity.sql
--     This fixture authors:
--       - v2 Morb Order observation UID 20080010 (obs_domain_cd_st_1='Order',
--         ctrl_cd_display_form='MorbReport')
--       - v2 followup C_Order  UID 20080020 (obs_domain_cd_st_1='C_Order')
--       - v2 followup C_Result UID 20080021 (obs_domain_cd_st_1='C_Result')
--         with nrt_observation_txt.ovt_value_txt =
--         'Tier 1 Morbidity v2 — clinician user comment.'
--       - act_relationship rows (type_cd='COMP'):
--             20080020 (C_Order)  -> 20080010 (Order)
--             20080021 (C_Result) -> 20080020 (C_Order)
--
--   The C_Result carries the user-comment text that should populate
--   MORB_RPT_USER_COMMENT.EXTERNAL_MORB_RPT_COMMENTS for the v2 Morb
--   Order, but the SP at lines 802-816 cannot reach it.
--
-- HOW TO RUN
--   SQLCMDPASSWORD=... sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
--     -i bugs/03_morb_rpt_user_comment/repro.sql
--
-- WHAT THIS SCRIPT DOES NOT DO
--   - Does not modify the RTR routine file.
--   - Does not reset the DB.
--   - Does not modify any fixtures outside this bug's directory.
--   - Read-only verification of preconditions, then EXEC the SP, then
--     read-only verification of the empirical bug.
-- =====================================================================

USE RDB_MODERN;
GO

SET NOCOUNT ON;
GO

PRINT '';
PRINT '====================================================================';
PRINT 'STEP 1 — Verify the source data IS populated.';
PRINT '====================================================================';
PRINT '';

PRINT '-- 1a. nrt_observation_txt has a non-NULL ovt_value_txt for the';
PRINT '--     C_Result UID 20080021. This is the comment text that the SP';
PRINT '--     SHOULD propagate to MORB_RPT_USER_COMMENT.EXTERNAL_MORB_RPT_COMMENTS.';
SELECT observation_uid,
       ovt_txt_type_cd,
       ovt_value_txt
  FROM dbo.nrt_observation_txt
 WHERE observation_uid = 20080021;
GO

PRINT '-- 1b. The Order, C_Order, and C_Result observations all exist and';
PRINT '--     have the expected obs_domain_cd_st_1 values.';
SELECT observation_uid,
       obs_domain_cd_st_1,
       ctrl_cd_display_form
  FROM dbo.nrt_observation
 WHERE observation_uid IN (20080010, 20080020, 20080021)
 ORDER BY observation_uid;
GO

PRINT '-- 1c. act_relationship rows wire the chain Order <- C_Order <- C_Result.';
SELECT source_act_uid,
       target_act_uid,
       type_cd
  FROM nbs_odse.dbo.act_relationship
 WHERE (source_act_uid IN (20080020, 20080021)
        OR target_act_uid IN (20080020, 20080021))
 ORDER BY source_act_uid;
GO

PRINT '';
PRINT '====================================================================';
PRINT 'STEP 2 — Demonstrate the SP-internal self-defeating join in isolation.';
PRINT '====================================================================';
PRINT '';
PRINT '-- The SP joins root.morb_rpt_uid = obs.observation_uid (where';
PRINT '--   root.morb_rpt_uid IS the Order observation_uid 20080010), then';
PRINT '--   filters obs.obs_domain_cd_st_1 IN (''C_Order'',''C_Result'').';
PRINT '--';
PRINT '-- A row where observation_uid=20080010 AND obs_domain_cd_st_1 IN';
PRINT '--   (''C_Order'',''C_Result'') cannot exist: each observation_uid';
PRINT '--   is unique and has exactly ONE obs_domain_cd_st_1 value, and';
PRINT '--   the Order''s value is ''Order''. The join+filter therefore';
PRINT '--   returns 0 rows by construction.';
PRINT '';
PRINT '-- 2a. Self-defeating join — direct count.';
SELECT COUNT(*) AS impossible_join_row_count
  FROM dbo.nrt_observation obs
 WHERE obs.observation_uid = 20080010                 -- Order's UID
   AND obs.obs_domain_cd_st_1 IN ('C_Order', 'C_Result');
GO

PRINT '-- 2b. For comparison: the CORRECT join (traverse act_relationship';
PRINT '--     two hops Order -> C_Order -> C_Result) DOES find a row.';
SELECT child2.observation_uid,
       child2.obs_domain_cd_st_1,
       ovt.ovt_value_txt
  FROM nbs_odse.dbo.act_relationship ar1
  INNER JOIN nbs_odse.dbo.act_relationship ar2
       ON ar2.target_act_uid = ar1.source_act_uid
  INNER JOIN dbo.nrt_observation child2
       ON child2.observation_uid = ar2.source_act_uid
  LEFT JOIN dbo.nrt_observation_txt ovt
       ON ovt.observation_uid = child2.observation_uid
 WHERE ar1.target_act_uid = 20080010                  -- v2 Morb Order
   AND ar1.type_cd = 'COMP'
   AND child2.obs_domain_cd_st_1 IN ('C_Order', 'C_Result');
GO

PRINT '';
PRINT '====================================================================';
PRINT 'STEP 3 — Pre-EXEC state of MORB_RPT_USER_COMMENT.';
PRINT '====================================================================';
PRINT '';
SELECT COUNT(*) AS user_comment_row_count_pre_exec
  FROM dbo.MORB_RPT_USER_COMMENT;
GO

PRINT '';
PRINT '====================================================================';
PRINT 'STEP 4 — Run sp_d_morbidity_report_postprocessing.';
PRINT '====================================================================';
PRINT '';
PRINT '-- @pMorbidityIdList includes both foundation Morb (20000130) and';
PRINT '--   v2 Morb (20080010). The C_Order/C_Result/followups are NOT';
PRINT '--   in the list (per SP filter at lines 281-282: obs_domain=Order';
PRINT '--   AND ctrl_cd_display_form=MorbReport); the SP traverses to them';
PRINT '--   internally via the followup_observation_uid CSV.';
EXEC dbo.sp_d_morbidity_report_postprocessing
     @pMorbidityIdList = N'20000130,20080010',
     @debug = 0;
GO

PRINT '';
PRINT '====================================================================';
PRINT 'STEP 5 — Confirm MORB_RPT_USER_COMMENT remains empty.';
PRINT '====================================================================';
PRINT '';
PRINT '-- 5a. Row count after EXEC: still 0.';
SELECT COUNT(*) AS user_comment_row_count_post_exec
  FROM dbo.MORB_RPT_USER_COMMENT;
GO

PRINT '-- 5b. job_flow_log for this batch — step 19 ("Generating';
PRINT '--     ##SAS_morb_Rpt_User_Comment", the SP body of the bug)';
PRINT '--     returns row_count=0; downstream steps 20, 26, 27 are';
PRINT '--     all 0-row no-ops as a result.';
WITH last_batch AS (
    SELECT MAX(batch_id) AS bid
      FROM dbo.job_flow_log
     WHERE package_name = 'sp_d_morbidity_report_postprocessing'
)
SELECT step_number, step_name, status_type, row_count
  FROM dbo.job_flow_log j
  CROSS JOIN last_batch
 WHERE j.batch_id = last_batch.bid
   AND j.package_name = 'sp_d_morbidity_report_postprocessing'
   AND (j.step_name LIKE '%morb_Rpt_User_Comment%'
        OR j.step_name LIKE '%MORB_RPT_USER_COMMENT%')
 ORDER BY j.step_number;
GO

PRINT '';
PRINT '====================================================================';
PRINT 'EMPIRICAL CONCLUSION';
PRINT '====================================================================';
PRINT '';
PRINT '  - nrt_observation_txt for the C_Result has the user-comment text.';
PRINT '  - The act_relationship chain Order <- C_Order <- C_Result is wired.';
PRINT '  - The SP-internal join (root.morb_rpt_uid = obs.observation_uid)';
PRINT '    AND filter (obs.obs_domain_cd_st_1 IN (C_Order, C_Result))';
PRINT '    returns 0 rows by construction.';
PRINT '  - MORB_RPT_USER_COMMENT remains empty after the SP runs.';
PRINT '';
PRINT '  See findings.md for the annotated walkthrough and suggested fix.';
PRINT '';
GO
