-- Unit test: sp_d_morbidity_report_postprocessing should populate
-- MORB_RPT_USER_COMMENT from an externally-entered morb report's user comment.
--
-- Regression coverage for RTR bug #3 (PR #837). The comment lives in NBS as a
-- C_Result child observation (cd MRB180, "User Report Comment") hung off the morb
-- Order through a C_Order ("MorbComment") wrapper. NBS flattens the Order's child
-- observation_uids into followup_observation_uid as a CSV, so the SP walks that CSV
-- and picks the C_Result sibling.
--
-- The old SP self-joined the Order to itself and filtered obs_domain_cd_st_1 IN
-- ('C_Order','C_Result'), which the Order row (domain 'Order') never matches, so
-- the table stayed empty.
--
-- Rows set up below:
--   Order    92000001  domain 'Order'    followup CSV = '92000002,92000003'
--   C_Order  92000002  domain 'C_Order'  ('MorbComment' wrapper, excluded)
--   C_Result 92000003  domain 'C_Result' (cd 'MRB180', carries the comment text)
--   D_PATIENT 92000010 gives MORBIDITY_REPORT_EVENT its non-null PATIENT_KEY.
USE RDB_MODERN;

DECLARE @order_uid   bigint = 92000001;   -- morb Order (externally entered report)
DECLARE @corder_uid  bigint = 92000002;   -- C_Order wrapper, excluded
DECLARE @cresult_uid bigint = 92000003;   -- C_Result, the comment row
DECLARE @patient_uid bigint = 92000010;   -- patient the report is about

-- ---- idempotent cleanup (test data only) ----
DELETE FROM RDB_MODERN.dbo.MORBIDITY_REPORT_EVENT WHERE MORB_RPT_KEY IN (SELECT MORB_RPT_KEY FROM RDB_MODERN.dbo.MORBIDITY_REPORT WHERE morb_rpt_uid = @order_uid);
DELETE FROM RDB_MODERN.dbo.MORB_RPT_USER_COMMENT  WHERE morb_rpt_uid = @order_uid;
DELETE FROM RDB_MODERN.dbo.MORBIDITY_REPORT       WHERE morb_rpt_uid = @order_uid;
DELETE FROM RDB_MODERN.dbo.D_PATIENT              WHERE patient_uid = @patient_uid;
DELETE FROM RDB_MODERN.dbo.nrt_observation_txt    WHERE observation_uid IN (@order_uid,@corder_uid,@cresult_uid);
DELETE FROM RDB_MODERN.dbo.nrt_observation        WHERE observation_uid IN (@order_uid,@corder_uid,@cresult_uid);

-- ---- patient dimension row (supplies MORBIDITY_REPORT_EVENT.PATIENT_KEY) ----
INSERT INTO RDB_MODERN.dbo.D_PATIENT (PATIENT_KEY, patient_uid) VALUES (@patient_uid, @patient_uid);

-- ---- the morb Order (externally entered) ----
INSERT INTO RDB_MODERN.dbo.nrt_observation
  (observation_uid, class_cd, mood_cd, obs_domain_cd_st_1, ctrl_cd_display_form,
   cd, cd_desc_txt, local_id, record_status_cd, electronic_ind, shared_ind,
   jurisdiction_cd, prog_area_cd, program_jurisdiction_oid, patient_id,
   add_user_id, add_user_name, add_time, last_chg_time,
   activity_to_time, rpt_to_state_time, followup_observation_uid,
   version_ctrl_nbr)
VALUES
  (@order_uid, 'OBS', 'EVN', 'Order', 'MorbReport',
   '10311', 'Syphilis, primary', 'OBS92000001GA01', 'UNPROCESSED', 'E', 'T',
   '130001', 'STD', 1300100015, @patient_uid,
   10009283, 'Person, External', '2026-06-01 23:54:56', '2026-06-02 00:17:35',
   '2026-06-01 23:54:56', '2026-06-01 23:54:56',
   CAST(@corder_uid AS varchar(20)) + ',' + CAST(@cresult_uid AS varchar(20)),
   2);

-- ---- the C_Order child (MorbComment wrapper); a sibling that should be excluded ----
INSERT INTO RDB_MODERN.dbo.nrt_observation
  (observation_uid, class_cd, mood_cd, obs_domain_cd_st_1, ctrl_cd_display_form,
   cd, cd_desc_txt, local_id, record_status_cd, shared_ind, status_cd,
   report_observation_uid, program_jurisdiction_oid,
   version_ctrl_nbr)
VALUES
  (@corder_uid, 'OBS', 'EVN', 'C_Order', 'MorbComment',
   'NI', 'No Information Given', 'OBS92000002GA01', 'ACTIVE', 'T', 'D',
   @order_uid, 4,
   1);

-- ---- the C_Result child (MRB180), the user comment ----
INSERT INTO RDB_MODERN.dbo.nrt_observation
  (observation_uid, class_cd, mood_cd, obs_domain_cd_st_1,
   cd, cd_desc_txt, cd_system_cd, local_id, record_status_cd, shared_ind, status_cd,
   report_observation_uid, program_jurisdiction_oid,
   add_user_id, add_user_name, activity_to_time, effective_from_time, rpt_to_state_time,
   version_ctrl_nbr)
VALUES
  (@cresult_uid, 'OBS', 'EVN', 'C_Result',
   'MRB180', 'User Report Comment', 'NBS', 'OBS92000003GA01', 'ACTIVE', 'T', 'D',
   @corder_uid, 4,
   10009282, 'Kent, Ariella', '2026-06-02 00:17:01', '2026-06-02 00:17:01', '2026-06-02 00:17:01',
   1);

-- ---- the comment text, carried on the C_Result ----
INSERT INTO RDB_MODERN.dbo.nrt_observation_txt
  (observation_uid, ovt_seq, ovt_txt_type_cd, ovt_value_txt)
VALUES
  (@cresult_uid, 1, 'N', 'comment from a user on an externally created morb report');

-- ---- run the postprocessing SP for this morb report ----
EXEC RDB_MODERN.dbo.sp_d_morbidity_report_postprocessing @pMorbidityIdList = N'92000001', @debug = 0;
