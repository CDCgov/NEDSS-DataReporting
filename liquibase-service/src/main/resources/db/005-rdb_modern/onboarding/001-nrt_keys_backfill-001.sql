-- Consolidated Key Table Backfills
-- Stripped of environment switching logic, intended for rdb_modern context.

-----------------------------------------------------------------------
-- 001: nrt_lab_test_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_TEST' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_lab_test_key ON
        INSERT INTO [dbo].nrt_lab_test_key(LAB_TEST_KEY, LAB_TEST_UID)
        SELECT lt.LAB_TEST_KEY, lt.LAB_TEST_UID
        FROM [dbo].LAB_TEST lt WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_lab_test_key k ON k.LAB_TEST_KEY = lt.LAB_TEST_KEY AND k.LAB_TEST_UID= lt.LAB_TEST_UID
        WHERE k.LAB_TEST_KEY IS NULL AND k.LAB_TEST_UID IS NULL
        ORDER BY lt.LAB_TEST_KEY;
        SET IDENTITY_INSERT [dbo].nrt_lab_test_key OFF
    END;

-----------------------------------------------------------------------
-- 002: nrt_lab_rpt_user_comment_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_rpt_user_comment_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_RPT_USER_COMMENT' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Act_relationship') 
    AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Observation') 
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key ON
        ;WITH CommentCTE AS (
            SELECT c.USER_COMMENT_KEY, c.lab_test_uid, ROW_NUMBER() OVER (PARTITION BY c.lab_test_uid ORDER BY c.USER_COMMENT_KEY) AS rn
            FROM [dbo].LAB_RPT_USER_COMMENT c
        ),
        ObsCTE AS (
            SELECT o.observation_uid, ar.target_act_uid AS lab_test_uid, ROW_NUMBER() OVER (PARTITION BY ar.target_act_uid ORDER BY o.observation_uid) AS rn
            FROM [NBS_ODSE].[dbo].Act_relationship ar
            INNER JOIN [NBS_ODSE].[dbo].Act_relationship ar2 ON ar.source_act_uid = ar2.target_act_uid
            INNER JOIN [NBS_ODSE].[dbo].Observation o ON ar2.source_act_uid = o.observation_uid AND o.obs_domain_cd_st_1 = 'C_Result'
        )
        INSERT INTO [dbo].nrt_lab_rpt_user_comment_key(USER_COMMENT_KEY, LAB_RPT_USER_COMMENT_UID, LAB_TEST_UID)
        SELECT c.USER_COMMENT_KEY, o.observation_uid, c.lab_test_uid
        FROM CommentCTE c
        INNER JOIN ObsCTE o ON c.lab_test_uid = o.lab_test_uid AND c.rn = o.rn
        LEFT JOIN [dbo].nrt_lab_rpt_user_comment_key uck ON uck.USER_COMMENT_KEY = c.USER_COMMENT_KEY AND uck.LAB_RPT_USER_COMMENT_UID = o.observation_uid AND uck.LAB_TEST_UID = c.lab_test_uid
        WHERE uck.USER_COMMENT_KEY IS NULL AND uck.LAB_RPT_USER_COMMENT_UID IS NULL AND uck.LAB_TEST_UID IS NULL
        ORDER BY c.USER_COMMENT_KEY;
        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key OFF
    END;

-----------------------------------------------------------------------
-- 003: nrt_interview_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'L_INTERVIEW' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_interview_key ON
        INSERT INTO [dbo].nrt_interview_key(D_INTERVIEW_KEY, INTERVIEW_UID)
        SELECT ix.D_INTERVIEW_KEY, ix.INTERVIEW_UID
        FROM [dbo].L_INTERVIEW ix WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_interview_key k ON k.D_INTERVIEW_KEY = ix.D_INTERVIEW_KEY AND k.INTERVIEW_UID= ix.INTERVIEW_UID
        WHERE k.D_INTERVIEW_KEY IS NULL AND k.INTERVIEW_UID IS NULL
        ORDER BY ix.D_INTERVIEW_KEY;
        SET IDENTITY_INSERT [dbo].nrt_interview_key OFF
    END;

-----------------------------------------------------------------------
-- 003: nrt_lab_result_comment_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_result_comment_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_RESULT_COMMENT' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_lab_result_comment_key ON
        INSERT INTO [dbo].nrt_lab_result_comment_key(LAB_RESULT_COMMENT_KEY, LAB_RESULT_COMMENT_UID)
        SELECT rc.LAB_RESULT_COMMENT_KEY, rc.LAB_TEST_UID 
        FROM [dbo].LAB_RESULT_COMMENT rc WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_lab_result_comment_key k WITH(NOLOCK) ON k.LAB_RESULT_COMMENT_KEY = rc.LAB_RESULT_COMMENT_KEY AND k.LAB_RESULT_COMMENT_UID= rc.LAB_TEST_UID
        WHERE k.LAB_RESULT_COMMENT_KEY IS NULL AND k.LAB_RESULT_COMMENT_UID IS NULL
        ORDER BY rc.LAB_RESULT_COMMENT_KEY;
        SET IDENTITY_INSERT [dbo].nrt_lab_result_comment_key OFF
    END;

-----------------------------------------------------------------------
-- 004: nrt_interview_note_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_note_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'L_INTERVIEW_NOTE' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_interview_note_key ON
        INSERT INTO [dbo].nrt_interview_note_key(D_INTERVIEW_KEY, D_INTERVIEW_NOTE_KEY, NBS_ANSWER_UID)
        SELECT ix.D_INTERVIEW_KEY, ix.D_INTERVIEW_NOTE_KEY, ix.NBS_ANSWER_UID
        FROM [dbo].L_INTERVIEW_NOTE ix WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_interview_note_key k ON k.D_INTERVIEW_KEY = ix.D_INTERVIEW_KEY AND k.D_INTERVIEW_NOTE_KEY = ix.D_INTERVIEW_NOTE_KEY AND k.NBS_ANSWER_UID = ix.NBS_ANSWER_UID
        WHERE k.D_INTERVIEW_KEY IS NULL AND k.D_INTERVIEW_NOTE_KEY IS NULL AND k.NBS_ANSWER_UID IS NULL
        ORDER BY ix.D_INTERVIEW_NOTE_KEY;
        SET IDENTITY_INSERT [dbo].nrt_interview_note_key OFF
    END;

-----------------------------------------------------------------------
-- 004: nrt_lab_test_result_group_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'nrt_lab_test_result_group_key' AND XTYPE = 'U')
    AND EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'TEST_RESULT_GROUPING' AND XTYPE = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].NRT_LAB_TEST_RESULT_GROUP_KEY ON
        INSERT INTO [dbo].NRT_LAB_TEST_RESULT_GROUP_KEY (TEST_RESULT_GRP_KEY, LAB_TEST_UID)
        SELECT RG.TEST_RESULT_GRP_KEY, RG.LAB_TEST_UID
        FROM [dbo].TEST_RESULT_GROUPING AS RG WITH (NOLOCK)
        LEFT JOIN [dbo].NRT_LAB_TEST_RESULT_GROUP_KEY AS K WITH (NOLOCK) ON RG.TEST_RESULT_GRP_KEY = K.TEST_RESULT_GRP_KEY
        WHERE K.TEST_RESULT_GRP_KEY IS NULL
        ORDER BY RG.TEST_RESULT_GRP_KEY;
        SET IDENTITY_INSERT [dbo].NRT_LAB_TEST_RESULT_GROUP_KEY OFF
    END;

-----------------------------------------------------------------------
-- 005: nrt_patient_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_patient_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_PATIENT' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_patient_key ON
        INSERT INTO [dbo].nrt_patient_key(D_PATIENT_KEY, PATIENT_UID)
        SELECT pat.PATIENT_KEY, pat.PATIENT_UID
        FROM [dbo].D_PATIENT pat WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_patient_key k ON k.D_PATIENT_KEY = pat.PATIENT_KEY AND COALESCE(k.PATIENT_UID, 1) = COALESCE(pat.PATIENT_UID, 1)
        WHERE k.D_PATIENT_KEY IS NULL AND k.PATIENT_UID IS NULL
        ORDER BY pat.PATIENT_KEY;
        SET IDENTITY_INSERT [dbo].nrt_patient_key OFF
    END;

-----------------------------------------------------------------------
-- 006: nrt_provider_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_provider_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_PROVIDER' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_provider_key ON
        INSERT INTO [dbo].nrt_provider_key(D_PROVIDER_KEY, PROVIDER_UID)
        SELECT prov.PROVIDER_KEY, prov.PROVIDER_UID
        FROM [dbo].D_PROVIDER prov WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_provider_key k ON k.D_PROVIDER_KEY = prov.PROVIDER_KEY AND COALESCE(k.PROVIDER_UID, 1) = COALESCE(prov.PROVIDER_UID, 1)
        WHERE k.D_PROVIDER_KEY IS NULL AND k.PROVIDER_UID IS NULL
        ORDER BY prov.PROVIDER_KEY;
        SET IDENTITY_INSERT [dbo].nrt_provider_key OFF
    END;

-----------------------------------------------------------------------
-- 007: nrt_investigation_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'INVESTIGATION' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_investigation_key ON
        INSERT INTO [dbo].nrt_investigation_key(d_investigation_key, case_uid)
        SELECT inv.INVESTIGATION_KEY, inv.CASE_UID
        FROM [dbo].INVESTIGATION inv WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_investigation_key k ON k.d_investigation_key = inv.INVESTIGATION_KEY AND COALESCE(k.case_uid, 1) = COALESCE(inv.CASE_UID, 1)
        WHERE k.d_investigation_key IS NULL AND k.case_uid IS NULL
        ORDER BY inv.INVESTIGATION_KEY;
        SET IDENTITY_INSERT [dbo].nrt_investigation_key OFF
    END;

-----------------------------------------------------------------------
-- 008: nrt_organization_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_organization_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_ORGANIZATION' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_organization_key ON
        INSERT INTO [dbo].nrt_organization_key(d_organization_key, organization_uid)
        SELECT org.ORGANIZATION_KEY, org.ORGANIZATION_UID
        FROM [dbo].D_ORGANIZATION org WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_organization_key k ON k.d_organization_key = org.ORGANIZATION_KEY AND COALESCE(k.organization_uid, 1) = COALESCE(org.ORGANIZATION_UID, 1)
        WHERE k.d_organization_key IS NULL AND k.organization_uid IS NULL
        ORDER BY org.ORGANIZATION_KEY;
        SET IDENTITY_INSERT [dbo].nrt_organization_key OFF
    END;

-----------------------------------------------------------------------
-- 009: nrt_confirmation_method_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_confirmation_method_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'CONFIRMATION_METHOD' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_confirmation_method_key ON
        INSERT INTO [dbo].nrt_confirmation_method_key(d_confirmation_method_key, confirmation_method_cd)
        SELECT cm.CONFIRMATION_METHOD_KEY, cm.CONFIRMATION_METHOD_CD
        FROM [dbo].CONFIRMATION_METHOD cm WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_confirmation_method_key k ON k.d_confirmation_method_key = cm.CONFIRMATION_METHOD_KEY AND COALESCE(k.confirmation_method_cd, '') = COALESCE(cm.confirmation_method_cd, '')
        WHERE k.d_confirmation_method_key IS NULL AND k.confirmation_method_cd IS NULL
        ORDER BY cm.CONFIRMATION_METHOD_KEY;
        SET IDENTITY_INSERT [dbo].nrt_confirmation_method_key OFF
    END;

-----------------------------------------------------------------------
-- 010: nrt_place_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_place_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_PLACE' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_place_key ON
        INSERT INTO [dbo].nrt_place_key(d_place_key, place_uid, place_locator_uid)
        SELECT pl.PLACE_KEY, pl.PLACE_UID, pl.PLACE_LOCATOR_UID
        FROM [dbo].D_PLACE pl WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_place_key k ON k.d_place_key = pl.PLACE_KEY AND k.place_uid = pl.PLACE_UID AND k.place_locator_uid = pl.PLACE_LOCATOR_UID
        WHERE k.d_place_key IS NULL AND k.place_uid IS NULL AND k.place_locator_uid IS NULL
        ORDER BY pl.PLACE_KEY;
        SET IDENTITY_INSERT [dbo].nrt_place_key OFF
    END;

-----------------------------------------------------------------------
-- 011: nrt_treatment_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_treatment_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'TREATMENT' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_treatment_key ON
        INSERT INTO [dbo].nrt_treatment_key(D_TREATMENT_KEY, TREATMENT_UID)
        SELECT tr.TREATMENT_KEY, tr.TREATMENT_UID
        FROM [dbo].TREATMENT tr WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_treatment_key k ON k.D_TREATMENT_KEY = tr.TREATMENT_KEY AND COALESCE(k.TREATMENT_UID, 1) = COALESCE(tr.TREATMENT_UID, 1)
        WHERE k.D_TREATMENT_KEY IS NULL AND k.TREATMENT_UID IS NULL
        ORDER BY tr.TREATMENT_KEY;
        SET IDENTITY_INSERT [dbo].nrt_treatment_key OFF
    END;

-----------------------------------------------------------------------
-- 012: nrt_notification_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_notification_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'NOTIFICATION' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'NOTIFICATION_EVENT' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'INVESTIGATION' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Act_relationship')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_notification_key ON
        INSERT INTO [dbo].nrt_notification_key(D_NOTIFICATION_KEY, NOTIFICATION_UID)
        SELECT notif.NOTIFICATION_KEY, max(ar1.source_act_uid) as NOTIFICATION_UID
        FROM [dbo].[NOTIFICATION] notif WITH(NOLOCK)
        LEFT JOIN [dbo].NOTIFICATION_EVENT notif_event WITH(NOLOCK) ON notif.NOTIFICATION_KEY = notif_event.NOTIFICATION_KEY
        LEFT JOIN [dbo].INVESTIGATION inv WITH(NOLOCK) ON inv.INVESTIGATION_KEY = notif_event.INVESTIGATION_KEY
        INNER JOIN NBS_ODSE.[dbo].Act_relationship ar1 WITH(NOLOCK) ON inv.CASE_UID = ar1.target_act_uid AND ar1.target_class_cd = 'CASE' AND ar1.source_class_cd = 'NOTF'
        INNER JOIN NBS_ODSE.[dbo].NOTIFICATION n WITH(NOLOCK) ON ar1.source_act_uid = n.notification_uid
        LEFT JOIN [dbo].nrt_notification_key k ON k.D_NOTIFICATION_KEY = notif.NOTIFICATION_KEY AND COALESCE(k.NOTIFICATION_UID, 1) = COALESCE(ar1.source_act_uid, 1)
        WHERE k.D_NOTIFICATION_KEY IS NULL AND k.NOTIFICATION_UID IS NULL AND n.cd not in ('EXP_NOTF', 'SHARE_NOTF', 'EXP_NOTF_PHDC','SHARE_NOTF_PHDC')
        GROUP BY notif.NOTIFICATION_KEY
        ORDER BY notif.NOTIFICATION_KEY;
        SET IDENTITY_INSERT [dbo].nrt_notification_key OFF
    END;

-----------------------------------------------------------------------
-- 013: nrt_summary_case_group_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_summary_case_group_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'SUMMARY_CASE_GROUP' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'SUMMARY_REPORT_CASE' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'INVESTIGATION' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Act_relationship')
     AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Observation')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_summary_case_group_key ON
        INSERT INTO [dbo].nrt_summary_case_group_key(summary_case_src_key, public_health_case_uid, ovc_observation_uid)
        SELECT scg.SUMMARY_CASE_SRC_KEY, MAX(inv.CASE_UID) AS public_health_case_uid, MAX(ar2.source_act_uid) as ovc_observation_uid
        FROM dbo.summary_case_group scg
        LEFT JOIN dbo.SUMMARY_REPORT_CASE src ON scg.SUMMARY_CASE_SRC_KEY = src.SUMMARY_CASE_SRC_KEY
        LEFT JOIN dbo.INVESTIGATION inv ON inv.INVESTIGATION_KEY = src.INVESTIGATION_KEY
        LEFT JOIN NBS_ODSE.dbo.Act_relationship ar1 ON ar1.target_act_uid = inv.CASE_UID
        INNER JOIN NBS_ODSE.dbo.Act_relationship ar2 ON ar1.source_act_uid = ar2.target_act_uid
        INNER JOIN NBS_ODSE.dbo.Observation obs ON ar2.source_act_uid = obs.observation_uid AND obs.cd = 'SUM103'
        LEFT JOIN dbo.nrt_summary_case_group_key k ON scg.SUMMARY_CASE_SRC_KEY = k.summary_case_src_key AND inv.CASE_UID = k.public_health_case_uid AND ar2.source_act_uid = k.ovc_observation_uid
        WHERE src.SUMMARY_CASE_SRC_KEY != 1 AND k.summary_case_src_key IS NULL AND k.public_health_case_uid IS NULL AND k.ovc_observation_uid IS NULL 
        GROUP BY scg.SUMMARY_CASE_SRC_KEY
        ORDER BY scg.SUMMARY_CASE_SRC_KEY;
        SET IDENTITY_INSERT [dbo].nrt_summary_case_group_key OFF
    END;

-----------------------------------------------------------------------
-- 014: nrt_vaccination_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_vaccination_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_VACCINATION' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_vaccination_key ON
        INSERT INTO [dbo].nrt_vaccination_key(d_vaccination_key, vaccination_uid)
        SELECT dv.d_vaccination_key, dv.vaccination_uid as vaccination_uid
        FROM [dbo].D_VACCINATION dv WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_vaccination_key k WITH(NOLOCK) ON k.d_vaccination_key = dv.d_vaccination_key and k.vaccination_uid= dv.vaccination_uid
        WHERE k.d_vaccination_key IS NULL AND k.vaccination_uid IS NULL and dv.d_vaccination_key<>1
        order by dv.d_vaccination_key;
        SET IDENTITY_INSERT [dbo].nrt_vaccination_key OFF
    END;

-----------------------------------------------------------------------
-- 015: nrt_case_management_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_case_management_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_CASE_MANAGEMENT' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'INVESTIGATION' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_case_management_key ON
        INSERT INTO [dbo].nrt_case_management_key(d_case_management_key, public_health_case_uid)
        SELECT dc.d_case_management_key, i.case_uid as public_health_case_uid
        FROM dbo.D_CASE_MANAGEMENT dc with (nolock) 
        INNER JOIN (SELECT distinct CASE_UID, INVESTIGATION_KEY FROM dbo.INVESTIGATION with (nolock)) i on dc.INVESTIGATION_KEY = i.INVESTIGATION_KEY
        LEFT JOIN dbo.nrt_case_management_key k with (nolock) on k.d_case_management_key = dc.d_case_management_key and k.public_health_case_uid = i.CASE_UID
        WHERE k.d_case_management_key is null and k.public_health_case_uid is null
        ORDER BY dc.d_case_management_key;
        SET IDENTITY_INSERT [dbo].nrt_case_management_key OFF
    END;

-----------------------------------------------------------------------
-- 016: nrt_contact_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_contact_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_CONTACT_RECORD' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_contact_key ON
        INSERT INTO [dbo].nrt_contact_key(d_contact_record_key, contact_uid)
        SELECT dcr.d_contact_record_key, cc.ct_contact_uid as contact_uid
        FROM dbo.d_contact_record dcr with (nolock)
        INNER JOIN (SELECT distinct ct_contact_uid, local_id, version_ctrl_nbr FROM nbs_odse.dbo.CT_CONTACT with (nolock)) cc on dcr.LOCAL_ID = cc.local_id and dcr.version_ctrl_nbr = cc.version_ctrl_nbr
        LEFT JOIN dbo.nrt_contact_key k with (nolock) on k.d_contact_record_key = dcr.d_contact_record_key and k.contact_uid = cc.ct_contact_uid
        WHERE k.d_contact_record_key is null and k.contact_uid is null 
        ORDER BY dcr.d_contact_record_key;
        SET IDENTITY_INSERT [dbo].nrt_contact_key OFF
    END;

-----------------------------------------------------------------------
-- 017: nrt_d_tb_pam_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_tb_pam_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_TB_PAM' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_d_tb_pam_key ON
        INSERT INTO [dbo].nrt_d_tb_pam_key(d_tb_pam_key, tb_pam_uid)
        SELECT d.d_tb_pam_key, d.tb_pam_uid
        FROM dbo.d_tb_pam d with (nolock)
        LEFT JOIN dbo.nrt_d_tb_pam_key k on k.D_TB_PAM_KEY = d.D_TB_PAM_KEY AND k.TB_PAM_UID = d.TB_PAM_UID
        WHERE k.D_TB_PAM_KEY is null and k.TB_PAM_UID is null
        ORDER BY d.d_tb_pam_key;
        SET IDENTITY_INSERT [dbo].nrt_d_tb_pam_key OFF
    END;

-----------------------------------------------------------------------
-- 018: nrt_var_pam_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_var_pam_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_VAR_PAM' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_var_pam_key ON
        INSERT INTO [dbo].nrt_var_pam_key(d_var_pam_key, var_pam_uid)
        SELECT d.d_var_pam_key, d.var_pam_uid
        FROM dbo.d_var_pam d with (nolock)
        LEFT JOIN dbo.nrt_var_pam_key k on k.D_VAR_PAM_KEY = d.D_VAR_PAM_KEY AND k.VAR_PAM_UID = d.VAR_PAM_UID
        WHERE k.D_VAR_PAM_KEY is null and k.VAR_PAM_UID is null
        ORDER BY d.d_var_pam_key;
        SET IDENTITY_INSERT [dbo].nrt_var_pam_key OFF
    END;

-----------------------------------------------------------------------
-- 019: nrt_ldf_group_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_ldf_group_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LDF_GROUP' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_ldf_group_key ON
        INSERT INTO [dbo].nrt_ldf_group_key(d_ldf_group_key, business_object_uid)
        SELECT d.ldf_group_key as d_ldf_group_key, d.business_object_uid
        FROM dbo.LDF_GROUP d with (nolock)
        LEFT JOIN dbo.nrt_ldf_group_key k with (nolock) on k.d_ldf_group_key = d.ldf_group_key and k.business_object_uid = d.business_object_uid 
        WHERE k.d_ldf_group_key is null and k.business_object_uid is null and d.business_object_uid is not null
        ORDER BY d.ldf_group_key;
        SET IDENTITY_INSERT [dbo].nrt_ldf_group_key OFF
    END;

-----------------------------------------------------------------------
-- 020: nrt_condition_key
-----------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_condition_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'CONDITION' and xtype = 'U')
    BEGIN
        SET IDENTITY_INSERT [dbo].nrt_condition_key ON
        INSERT INTO [dbo].nrt_condition_key(CONDITION_KEY, CONDITION_CD, PROGRAM_AREA_CD)
        SELECT c.CONDITION_KEY, c.CONDITION_CD, c.PROGRAM_AREA_CD
        FROM [dbo].CONDITION c WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_condition_key k ON k.CONDITION_KEY = c.CONDITION_KEY AND COALESCE(k.CONDITION_CD, '') = COALESCE(c.CONDITION_CD, '') AND COALESCE(k.PROGRAM_AREA_CD, '') = COALESCE(c.PROGRAM_AREA_CD, '')
        WHERE k.CONDITION_KEY IS NULL AND k.CONDITION_CD IS NULL AND k.PROGRAM_AREA_CD IS NULL
        ORDER BY c.CONDITION_KEY;
        SET IDENTITY_INSERT [dbo].nrt_condition_key OFF
    END;

-----------------------------------------------------------------------
-- Reseed Identity Columns
-----------------------------------------------------------------------
DECLARE @max BIGINT;

-- nrt_patient_key
SELECT @max = MAX(d_patient_key) FROM [dbo].nrt_patient_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_patient_key', RESEED, @max);

-- nrt_provider_key
SELECT @max = MAX(d_provider_key) FROM [dbo].nrt_provider_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_provider_key', RESEED, @max);

-- nrt_investigation_key
SELECT @max = MAX(d_investigation_key) FROM [dbo].nrt_investigation_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_investigation_key', RESEED, @max);

-- nrt_organization_key
SELECT @max = MAX(d_organization_key) FROM [dbo].nrt_organization_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_organization_key', RESEED, @max);

-- nrt_confirmation_method_key
SELECT @max = MAX(d_confirmation_method_key) FROM [dbo].nrt_confirmation_method_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_confirmation_method_key', RESEED, @max);

-- nrt_place_key
SELECT @max = MAX(d_place_key) FROM [dbo].nrt_place_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_place_key', RESEED, @max);

-- nrt_treatment_key
SELECT @max = MAX(d_treatment_key) FROM [dbo].nrt_treatment_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_treatment_key', RESEED, @max);

-- nrt_notification_key
SELECT @max = MAX(d_notification_key) FROM [dbo].nrt_notification_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_notification_key', RESEED, @max);

-- nrt_summary_case_group_key
SELECT @max = MAX(summary_case_src_key) FROM [dbo].nrt_summary_case_group_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_summary_case_group_key', RESEED, @max);

-- nrt_vaccination_key
SELECT @max = MAX(d_vaccination_key) FROM [dbo].nrt_vaccination_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_vaccination_key', RESEED, @max);

-- nrt_case_management_key
SELECT @max = MAX(d_case_management_key) FROM [dbo].nrt_case_management_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_case_management_key', RESEED, @max);

-- nrt_contact_key
SELECT @max = MAX(d_contact_record_key) FROM [dbo].nrt_contact_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_contact_key', RESEED, @max);

-- nrt_d_tb_pam_key
SELECT @max = MAX(d_tb_pam_key) FROM [dbo].nrt_d_tb_pam_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_d_tb_pam_key', RESEED, @max);

-- nrt_var_pam_key
SELECT @max = MAX(d_var_pam_key) FROM [dbo].nrt_var_pam_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_var_pam_key', RESEED, @max);

-- nrt_ldf_group_key
SELECT @max = MAX(d_ldf_group_key) FROM [dbo].nrt_ldf_group_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_ldf_group_key', RESEED, @max);

-- nrt_condition_key
SELECT @max = MAX(condition_key) FROM [dbo].nrt_condition_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_condition_key', RESEED, @max);

-- nrt_lab_test_key
SELECT @max = MAX(lab_test_key) FROM [dbo].nrt_lab_test_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_lab_test_key', RESEED, @max);

-- nrt_lab_rpt_user_comment_key
SELECT @max = MAX(user_comment_key) FROM [dbo].nrt_lab_rpt_user_comment_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_lab_rpt_user_comment_key', RESEED, @max);

-- nrt_interview_key
SELECT @max = MAX(d_interview_key) FROM [dbo].nrt_interview_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_interview_key', RESEED, @max);

-- nrt_lab_result_comment_key
SELECT @max = MAX(lab_result_comment_key) FROM [dbo].nrt_lab_result_comment_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_lab_result_comment_key', RESEED, @max);

-- nrt_interview_note_key
SELECT @max = MAX(d_interview_note_key) FROM [dbo].nrt_interview_note_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_interview_note_key', RESEED, @max);

-- nrt_lab_test_result_group_key
SELECT @max = MAX(test_result_grp_key) FROM [dbo].nrt_lab_test_result_group_key;
IF @max IS NOT NULL DBCC CHECKIDENT ('[dbo].nrt_lab_test_result_group_key', RESEED, @max);
