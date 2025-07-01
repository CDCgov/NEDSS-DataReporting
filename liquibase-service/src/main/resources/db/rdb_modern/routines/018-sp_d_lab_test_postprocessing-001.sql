IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_d_lab_test_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_d_lab_test_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].sp_d_lab_test_postprocessing
    @obs_ids nvarchar(max),
    @debug bit = 'false'
AS

BEGIN
    /*
     * [Description]
     * This stored procedure processes event based updates to LAB_TEST and associated tables.
     * 1. Receives input list of Lab Report based observations from Observation Service.
     * 2. Performs necessary transformations for domains: 'Order', 'Result', 'R_Order', 'R_Result',
     * 	'I_Order', 'I_Result', 'Order_rslt'
     * 3. Updates and inserts records into target dimensions.
     *
     * [Target Dimensions]
     * 1. LAB_TEST
     * 2. LAB_RPT_USER_COMMENT
     */
    
    DECLARE @batch_id BIGINT;
    SET @batch_id = CAST((format(getdate(), 'yyMMddHHmmssffff')) as bigint);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @Dataflow_Name VARCHAR(200) = 'D_LAB_TEST Post-Processing Event';
    DECLARE @Package_Name VARCHAR(200) = 'sp_d_lab_test_postprocessing';
    DECLARE @rdb_last_refresh_time datetime; 

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        BEGIN TRANSACTION;

            INSERT INTO dbo.job_flow_log ( batch_id
                                        , [Dataflow_Name]
                                        , [package_Name]
                                        , [Status_Type]
                                        , [step_number]
                                        , [step_name]
                                        , [row_count]
                                        , [Msg_Description1])
            VALUES ( @batch_id
                , @Dataflow_Name
                , @Package_Name
                , 'START'
                , @Proc_Step_no
                , @Proc_Step_Name
                , 0
                , LEFT('ID List-' + @obs_ids, 500));

        COMMIT TRANSACTION;

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #obs_ids';

        IF OBJECT_ID('#obs_ids', 'U') IS NOT NULL
            DROP TABLE #obs_ids;

        SELECT DISTINCT TRIM(value) AS observation_uid
        INTO #obs_ids
        FROM STRING_SPLIT(@obs_ids, ',');

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #obs_ids;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #edx_document';


        IF OBJECT_ID('#dx_document', 'U') IS NOT NULL
            DROP TABLE #edx_document;

        ;WITH edx_lst AS(
            SELECT 
                EDX_Document_uid,
                edx_act_uid,
                edx_add_time,
                ROW_NUMBER() OVER (PARTITION BY edx_act_uid ORDER BY edx_add_time DESC) AS rankno
            FROM dbo.nrt_observation_edx edx with (nolock)
            INNER JOIN #obs_ids ids ON ids.observation_uid = edx.edx_act_uid 
        )
        SELECT 
            EDX_Document_uid,
            edx_act_uid,
            edx_add_time,
            CONVERT(varchar, edx_add_time, 101) AS add_timeSt,
            ('<a href="#" ' +
            REPLACE(
                ('onClick="window.open(''/nbs/viewELRDocument.do?method=viewELRDocument&documentUid='
                + CAST(EDX_Document_uid AS varchar) + '&dateReceivedHidden=' + CONVERT(varchar, edx_add_time, 101) +
                ''',''DocumentViewer'',''width=900,height=800,left=0,top=0,menubar=no,titlebar=no,toolbar=no,scrollbars=yes,location=no'');">View Lab Document</a>'),
                ' ', '') ) AS document_link
        INTO #edx_document
        FROM edx_lst
        WHERE rankno = 1;        

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #edx_document;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #observation_data';

        IF OBJECT_ID('#observation_data', 'U') IS NOT NULL
            DROP TABLE #observation_data;

        SELECT 
            obs.observation_uid,
            obs.observation_uid AS LAB_TEST_uid,
            obs.observation_uid AS LAB_TEST_pntr,
            obs.activity_to_time AS LAB_TEST_dt,
            obs.method_cd AS test_method_cd,
            obs.method_desc_txt AS test_method_cd_desc,
            obs.priority_cd,
            obs.target_site_cd AS specimen_site,
            obs.target_site_desc_txt AS SPECIMEN_SITE_desc,
            obs.txt AS Clinical_information,
            obs.obs_domain_cd_st_1 AS LAB_TEST_Type,
            obs.cd AS LAB_TEST_cd,
            obs.cd_desc_txt AS LAB_TEST_cd_desc,
            obs.Cd_system_cd AS LAB_TEST_cd_sys_cd,
            obs.Cd_system_desc_txt AS LAB_TEST_cd_sys_nm,
            obs.Alt_cd AS Alt_LAB_TEST_cd,
            obs.Alt_cd_desc_txt AS Alt_LAB_TEST_cd_desc,
            obs.Alt_cd_system_cd AS Alt_LAB_TEST_cd_sys_cd,
            obs.Alt_cd_system_desc_txt AS Alt_LAB_TEST_cd_sys_nm,
            obs.effective_from_time AS specimen_collection_dt,
            obs.local_id AS lab_rpt_local_id,
            obs.shared_ind AS lab_rpt_share_ind,
            obs.PROGRAM_JURISDICTION_OID AS oid,
            CASE 
                WHEN obs.record_status_cd IN ('', 'UNPROCESSED', 'UNPROCESSED_PREV_D', 'PROCESSED') OR obs.record_status_cd IS NULL THEN 'ACTIVE'
                WHEN obs.record_status_cd = 'LOG_DEL' THEN 'INACTIVE'
                ELSE obs.record_status_cd
            END AS record_status_cd,
            obs.STATUS_CD AS lab_rpt_status,
            obs.ADD_TIME AS LAB_RPT_CREATED_DT,
            obs.ADD_USER_ID AS LAB_RPT_CREATED_BY,
            obs.rpt_to_state_time AS LAB_RPT_RECEIVED_BY_PH_DT,
            obs.LAST_CHG_TIME AS LAB_RPT_LAST_UPDATE_DT,
            obs.LAST_CHG_USER_ID AS LAB_RPT_LAST_UPDATE_BY,
            obs.electronic_ind AS ELR_IND,
            obs.jurisdiction_cd,
            jc.code_desc_txt AS JURISDICTION_NM,
            obs.observation_uid AS Lab_Rpt_Uid,
            obs.activity_to_time AS resulted_lab_report_date,
            obs.activity_to_time AS sus_lab_report_date,
            obs.report_observation_uid,
            obs.report_refr_uid,
            obs.report_sprt_uid,
            obs.followup_observation_uid,
            obs.accession_number,
            obs.morb_hosp_id,
            obs.transcriptionist_auth_type,
            obs.assistant_interpreter_auth_type,
            obs.morb_physician_id,
            obs.morb_reporter_id,
            obs.transcriptionist_val,
            obs.transcriptionist_first_nm,
            obs.transcriptionist_last_nm,
            obs.assistant_interpreter_val,
            obs.assistant_interpreter_first_nm,
            obs.assistant_interpreter_last_nm,
            obs.result_interpreter_id,
            obs.transcriptionist_id_assign_auth,
            obs.assistant_interpreter_id_assign_auth,
            obs.interpretation_cd,
            loinc_con.condition_cd,
            cvg.code_short_desc_txt AS LAB_TEST_status,
            obs.PROCESSING_DECISION_CD,
            CASE
                WHEN cvg2.code_short_desc_txt IS NULL AND obs.processing_decision_cd IS NOT NULL
                THEN obs.processing_decision_cd
                ELSE cvg2.code_short_desc_txt
            END AS PROCESSING_DECISION_DESC
        INTO #observation_data
        FROM [dbo].nrt_observation obs WITH (NOLOCK)
        INNER JOIN #obs_ids ids ON ids.observation_uid = obs.observation_uid 
        LEFT JOIN [dbo].nrt_srte_Loinc_condition loinc_con WITH (NOLOCK) 
            ON obs.cd = loinc_con.loinc_cd
        LEFT JOIN [dbo].nrt_srte_Code_value_general cvg WITH (NOLOCK) 
            ON obs.status_cd = cvg.code AND cvg.code_set_nm = 'ACT_OBJ_ST'
        LEFT JOIN [dbo].nrt_srte_Code_value_general cvg2 WITH (NOLOCK) 
            ON obs.PROCESSING_DECISION_CD = cvg2.code AND cvg2.code_set_nm = 'STD_NBS_PROCESSING_DECISION_ALL'
        LEFT JOIN [dbo].nrt_srte_Jurisdiction_code jc WITH (NOLOCK) 
            ON obs.jurisdiction_cd = jc.code AND jc.code_set_nm = 'S_JURDIC_C'
        WHERE 
            obs.obs_domain_cd_st_1 IN ('Order', 'Result', 'R_Order', 'R_Result', 'I_Order', 'I_Result', 'Order_rslt')
            AND (obs.CTRL_CD_DISPLAY_FORM IN ('LabReport', 'LabReportMorb') OR obs.CTRL_CD_DISPLAY_FORM IS NULL);    
        
        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #observation_data;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #material_data';

        IF OBJECT_ID('#material_data', 'U') IS NOT NULL
            DROP TABLE #material_data;
        
        ;WITH mat AS (
            SELECT 
                act_uid,
                material_cd,
                material_nm,
                material_details,
                material_collection_vol,
                material_collection_vol_unit,
                material_desc,
                risk_cd,
                risk_desc_txt,
                ROW_NUMBER() OVER (PARTITION BY act_uid ORDER BY last_chg_time DESC) AS row_num
            FROM [dbo].nrt_observation_material mat WITH(NOLOCK) 
            INNER JOIN #obs_ids ids ON ids.observation_uid = mat.act_uid
        )
        SELECT 
            mat.act_uid AS LAB_TEST_uid,
            mat.material_cd AS specimen_src,
            mat.material_nm AS specimen_nm,
            mat.material_details AS Specimen_details,
            mat.material_collection_vol AS Specimen_collection_vol,
            mat.material_collection_vol_unit AS Specimen_collection_vol_unit,
            mat.material_desc AS Specimen_desc,
            mat.risk_cd AS Danger_cd,
            mat.risk_desc_txt AS Danger_cd_desc
        INTO #material_data
        FROM mat
        WHERE row_num = 1;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #material_data;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #reason_data';

        IF OBJECT_ID('#reason_data', 'U') IS NOT NULL
            DROP TABLE #reason_data;

        SELECT 
            obs.observation_uid,
            STRING_AGG(COALESCE(rsn.reason_cd + '(' + rsn.reason_desc_txt + ')', ''), '|') AS REASON_FOR_TEST_DESC,
            STRING_AGG(rsn.reason_cd, '|') AS REASON_FOR_TEST_CD
        INTO #reason_data
        FROM #observation_data obs	
        LEFT JOIN dbo.nrt_observation_reason rsn ON obs.LAB_TEST_uid = rsn.observation_uid
        INNER JOIN #obs_ids ids ON ids.observation_uid = rsn.observation_uid 
        GROUP BY obs.observation_uid;    

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #reason_data;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #provider_data';

        IF OBJECT_ID('#provider_data', 'U') IS NOT NULL
            DROP TABLE #provider_data;

        SELECT 
            obs.observation_uid AS LAB_TEST_uid,
            RTRIM(nprov.first_name) + ' ' + RTRIM(nprov.last_name) AS result_interpreter_name
        INTO #provider_data
        FROM #observation_data obs
        LEFT JOIN dbo.nrt_provider nprov ON obs.result_interpreter_id = nprov.provider_uid

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #provider_data;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #morb_data';

        IF OBJECT_ID('#morb_data', 'U') IS NOT NULL
            DROP TABLE #morb_data;
        
        SELECT 
            l.Lab_Rpt_Uid AS lab_rpt_uid_mor,
            l.LAB_TEST_uid,
            COALESCE(o.PROGRAM_JURISDICTION_OID, l.oid) AS Morb_oid
        INTO #morb_data
        FROM #observation_data l
        LEFT JOIN dbo.nrt_observation l_extension WITH (NOLOCK) 
            ON l.Lab_Rpt_Uid = l_extension.observation_uid
        LEFT JOIN dbo.nrt_observation o WITH (NOLOCK) 
            ON l_extension.report_observation_uid = o.observation_uid AND o.CTRL_CD_DISPLAY_FORM = 'MorbReport'
        WHERE 
            l.LAB_TEST_Type IN ('Order', 'Result', 'Order_rslt') 
            AND l.oid = 4

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #morb_data;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #hierarchical_data';

        IF OBJECT_ID('#hierarchical_data', 'U') IS NOT NULL
            DROP TABLE #hierarchical_data;

        SELECT 
            tst.LAB_TEST_uid,
            CASE 
                WHEN tst.LAB_TEST_Type IN ('R_Result', 'I_Result') THEN tst.report_observation_uid
                WHEN tst.LAB_TEST_Type IN ('R_Order', 'I_Order') THEN obs2.observation_uid
                WHEN tst.LAB_TEST_Type IN ('Result', 'Order_rslt') AND tst.LAB_TEST_uid != tst.report_observation_uid THEN tst.report_observation_uid
                WHEN tst.LAB_TEST_Type = 'Order' THEN tst.LAB_TEST_pntr
                ELSE tst.LAB_TEST_pntr
            END AS parent_test_pntr,
            CASE 
                WHEN tst.LAB_TEST_Type IN ('R_Result', 'I_Result') THEN COALESCE(parent_test.report_sprt_uid, parent_test.report_observation_uid)
                WHEN tst.LAB_TEST_Type IN ('R_Order', 'I_Order') THEN obs2.observation_uid
                WHEN tst.LAB_TEST_Type IN ('Result', 'Order_rslt') AND tst.LAB_TEST_uid != tst.report_observation_uid THEN tst.report_observation_uid
                WHEN tst.LAB_TEST_Type = 'Order' THEN tst.LAB_TEST_pntr
                ELSE tst.LAB_TEST_pntr
            END AS root_ordered_test_pntr,
            COALESCE(tst2.record_status_cd, tst3.record_status_cd, tst4.record_status_cd, obs3.record_status_cd) AS record_status_cd_for_result_drug,
            parent_test.report_sprt_uid AS root_thru_srpt,
            parent_test.report_refr_uid AS root_thru_refr
        INTO #hierarchical_data
        FROM #observation_data tst
        LEFT JOIN dbo.nrt_observation parent_test WITH (NOLOCK) ON tst.report_observation_uid = parent_test.observation_uid
        LEFT JOIN dbo.nrt_observation tst2 WITH (NOLOCK) ON parent_test.report_sprt_uid = tst2.observation_uid
        LEFT JOIN dbo.nrt_observation tst3 WITH (NOLOCK) ON parent_test.report_refr_uid = tst3.observation_uid
        LEFT JOIN dbo.nrt_observation tst4 WITH (NOLOCK) ON parent_test.report_observation_uid = tst4.observation_uid
        LEFT JOIN dbo.nrt_observation obs2 WITH (NOLOCK) ON tst.report_refr_uid = obs2.observation_uid
        LEFT JOIN dbo.nrt_observation obs3 WITH (NOLOCK) ON obs2.report_observation_uid = obs3.observation_uid;

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #hierarchical_data;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #observation_hierarchical_data';

        IF OBJECT_ID('#observation_hierarchical_data', 'U') IS NOT NULL
            DROP TABLE #observation_hierarchical_data;

        SELECT
            lt.*,
            hd.parent_test_pntr,
            hd.root_ordered_test_pntr
        INTO #observation_hierarchical_data    
        FROM #observation_data lt 
        INNER JOIN #hierarchical_data hd 
            ON hd.LAB_TEST_uid = lt.LAB_TEST_uid

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #observation_hierarchical_data;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #merge_order';

        IF OBJECT_ID('#merge_order', 'U') IS NOT NULL
            DROP TABLE #merge_order;

        ;WITH mat AS (
            SELECT 
                act_uid,
                material_cd,
                material_desc,
                ROW_NUMBER() OVER (PARTITION BY act_uid ORDER BY last_chg_time DESC) AS row_num
            FROM [dbo].nrt_observation_material mat WITH(NOLOCK)
            INNER JOIN #observation_hierarchical_data ohd ON ohd.root_ordered_Test_pntr = mat.act_uid
        )
        SELECT DISTINCT
            lt.root_ordered_test_pntr AS root_ordered_test_pntr,
            obs.accession_number AS ACCESSION_NBR,
            obs.add_user_id AS LAB_RPT_CREATED_BY,
            obs.ADD_TIME AS LAB_RPT_CREATED_DT,
            obs.JURISDICTION_CD,
            jc.code_short_desc_txt AS JURISDICTION_NM,
            obs.activity_to_time AS LAB_TEST_dt,
            obs.effective_from_time AS specimen_collection_dt,
            obs.rpt_to_state_time AS LAB_RPT_RECEIVED_BY_PH_DT,
            obs.LAST_CHG_TIME AS LAB_RPT_LAST_UPDATE_DT,
            obs.LAST_CHG_USER_ID AS LAB_RPT_LAST_UPDATE_BY,
            obs.electronic_ind AS ELR_IND1,
            mat.material_cd AS specimen_src,
            obs.target_site_cd AS specimen_site,
            mat.material_desc AS Specimen_desc,
            obs.target_site_desc_txt AS SPECIMEN_SITE_desc,
            obs.local_id AS lab_rpt_local_id,
            CASE 
                WHEN obs.record_status_cd IN ('', 'UNPROCESSED', 'UNPROCESSED_PREV_D', 'PROCESSED') OR obs.record_status_cd IS NULL THEN 'ACTIVE'
                WHEN obs.record_status_cd = 'LOG_DEL' THEN 'INACTIVE'
                ELSE obs.record_status_cd
            END AS record_status_cd_merge,
            CASE 
                WHEN COALESCE(obs2.program_jurisdiction_oid, obs.program_jurisdiction_oid, lt.oid) = 4 THEN NULL 
                ELSE COALESCE(obs2.program_jurisdiction_oid, obs.program_jurisdiction_oid, lt.oid) 
            END AS order_oid
        INTO #merge_order
        FROM #observation_hierarchical_data lt
        LEFT JOIN [dbo].nrt_observation obs WITH (NOLOCK) 
            ON lt.root_ordered_test_pntr = obs.observation_uid
        LEFT JOIN [dbo].nrt_observation obs2 WITH (NOLOCK) 
            ON obs.report_observation_uid = obs2.observation_uid AND obs.ctrl_cd_display_form = 'LabReportMorb'
        LEFT JOIN mat 
            ON obs.observation_uid = mat.act_uid AND mat.row_num = 1
        LEFT JOIN [dbo].nrt_srte_Jurisdiction_code jc WITH (NOLOCK) 
            ON obs.jurisdiction_cd = jc.code AND jc.code_set_nm = 'S_JURDIC_C';

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #merge_order;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #lab_test_final';

        IF OBJECT_ID('#lab_test_final', 'U') IS NOT NULL
            DROP TABLE #lab_test_final;

        SELECT 
            lt.LAB_TEST_UID,
            lt.LAB_TEST_PNTR,
            lt.TEST_METHOD_CD,
            CASE WHEN lt.TEST_METHOD_CD_DESC = '' THEN NULL ELSE lt.TEST_METHOD_CD_DESC END AS TEST_METHOD_CD_DESC,
            lt.priority_cd,
            CASE WHEN lt.CLINICAL_INFORMATION = '' THEN NULL ELSE lt.CLINICAL_INFORMATION END AS CLINICAL_INFORMATION,
            lt.LAB_TEST_TYPE,
            lt.LAB_TEST_CD,
            lt.LAB_TEST_CD_DESC,
            lt.LAB_TEST_CD_SYS_CD,
            lt.LAB_TEST_CD_SYS_NM,
            lt.ALT_LAB_TEST_CD,
            lt.ALT_LAB_TEST_CD_DESC,
            lt.ALT_LAB_TEST_CD_SYS_CD,
            lt.ALT_LAB_TEST_CD_SYS_NM,
            lt.LAB_RPT_SHARE_IND,
            COALESCE (mo.RECORD_STATUS_CD_MERGE, hd.RECORD_STATUS_CD_FOR_RESULT_DRUG) AS RECORD_STATUS_CD,
            lt.LAB_RPT_STATUS,
            lt.RESULTED_LAB_REPORT_DATE,
            lt.SUS_LAB_REPORT_DATE,
            lt.REPORT_OBSERVATION_UID,
            lt.REPORT_REFR_UID,
            lt.REPORT_SPRT_UID,
            lt.FOLLOWUP_OBSERVATION_UID,
            lt.MORB_HOSP_ID,
            lt.TRANSCRIPTIONIST_AUTH_TYPE AS TRANSCRIPTIONIST_ASS_AUTH_TYPE,
            lt.ASSISTANT_INTERPRETER_AUTH_TYPE AS ASSISTANT_INTER_ASS_AUTH_TYPE,
            lt.MORB_PHYSICIAN_ID,
            lt.MORB_REPORTER_ID,
            lt.TRANSCRIPTIONIST_VAL AS TRANSCRIPTIONIST_ID,
            RTRIM(lt.transcriptionist_first_nm) + ' ' + RTRIM(lt.TRANSCRIPTIONIST_LAST_NM) AS TRANSCRIPTIONIST_NAME,
            lt.ASSISTANT_INTERPRETER_VAL AS ASSISTANT_INTERPRETER_ID,
            RTRIM(lt.ASSISTANT_INTERPRETER_FIRST_NM) + ' ' + RTRIM(lt.ASSISTANT_INTERPRETER_LAST_NM) AS ASSISTANT_INTERPRETER_NAME,
            lt.RESULT_INTERPRETER_ID,
            lt.TRANSCRIPTIONIST_ID_ASSIGN_AUTH AS TRANSCRIPTIONIST_ASS_AUTH_CD,
            lt.ASSISTANT_INTERPRETER_ID_ASSIGN_AUTH AS ASSISTANT_INTER_ASS_AUTH_CD,
            lt.INTERPRETATION_CD AS INTERPRETATION_FLG,
            lt.CONDITION_CD,
            lt.LAB_TEST_STATUS,
            lt.PROCESSING_DECISION_CD,
            lt.PROCESSING_DECISION_DESC,
            ed.DOCUMENT_LINK,
            lt.LAB_RPT_UID,
            CASE WHEN rd.REASON_FOR_TEST_DESC = '' THEN NULL ELSE rd.REASON_FOR_TEST_DESC END AS REASON_FOR_TEST_DESC,
            CASE WHEN rd.REASON_FOR_TEST_CD = '' THEN NULL ELSE rd.REASON_FOR_TEST_CD END AS REASON_FOR_TEST_CD,
            pd.RESULT_INTERPRETER_NAME,
            m.SPECIMEN_NM,
            m.SPECIMEN_DETAILS,
            m.SPECIMEN_COLLECTION_VOL,
            m.SPECIMEN_COLLECTION_VOL_UNIT,
            m.DANGER_CD,
            m.DANGER_CD_DESC,
            COALESCE(hd.PARENT_TEST_PNTR, lt.LAB_TEST_PNTR) AS PARENT_TEST_PNTR,
            COALESCE(hd.ROOT_ORDERED_TEST_PNTR, lt.LAB_TEST_PNTR) AS ROOT_ORDERED_TEST_PNTR,
            hd.ROOT_THRU_SRPT,
            hd.ROOT_THRU_REFR,
            obs_root.CD_DESC_TXT AS ROOT_ORDERED_TEST_NM,
            obs_parent.CD_DESC_TXT AS PARENT_TEST_NM,
            obs_order.ADD_TIME AS SPECIMEN_ADD_TIME,
            obs_order.LAST_CHG_TIME AS SPECIMEN_LAST_CHANGE_TIME,
            CASE WHEN mo.ACCESSION_NBR = '' THEN NULL ELSE mo.ACCESSION_NBR END AS ACCESSION_NBR,
            mo.LAB_RPT_CREATED_BY,
            mo.LAB_RPT_CREATED_DT AS LAB_RPT_CREATED_DT,
            mo.JURISDICTION_CD AS JURISDICTION_CD,
            CASE WHEN mo.JURISDICTION_NM = '' THEN NULL ELSE mo.JURISDICTION_NM END AS JURISDICTION_NM,
            mo.LAB_TEST_DT,
            mo.SPECIMEN_COLLECTION_DT,
            mo.LAB_RPT_RECEIVED_BY_PH_DT,
            mo.LAB_RPT_LAST_UPDATE_DT,
            mo.LAB_RPT_LAST_UPDATE_BY,
            CASE WHEN mo.ELR_IND1 IS NOT NULL THEN mo.ELR_IND1 ELSE lt.ELR_IND END AS ELR_IND,
            CASE WHEN mo.SPECIMEN_SRC = '' THEN NULL ELSE mo.SPECIMEN_SRC END AS SPECIMEN_SRC,
            mo.specimen_site,
            CASE WHEN mo.SPECIMEN_DESC = '' THEN NULL ELSE mo.SPECIMEN_DESC END AS SPECIMEN_DESC,
            mo.SPECIMEN_SITE_DESC,
            mo.LAB_RPT_LOCAL_ID,
            mo.ORDER_OID AS OID
        INTO #lab_test_final    
        FROM #observation_hierarchical_data lt
        LEFT JOIN #edx_document ed ON lt.LAB_TEST_uid = ed.edx_act_uid
        LEFT JOIN #reason_data rd ON lt.LAB_TEST_uid = rd.observation_uid
        LEFT JOIN #provider_data pd ON lt.LAB_TEST_uid = pd.LAB_TEST_uid
        LEFT JOIN #material_data m ON lt.LAB_TEST_uid = m.LAB_TEST_uid
        LEFT JOIN #morb_data morb ON lt.LAB_TEST_uid = morb.LAB_TEST_uid
        LEFT JOIN #hierarchical_data hd ON lt.LAB_TEST_uid = hd.LAB_TEST_uid
        LEFT JOIN [dbo].nrt_observation obs_root WITH (NOLOCK) 
            ON lt.root_ordered_test_pntr = obs_root.observation_uid
        LEFT JOIN [dbo].nrt_observation obs_parent WITH (NOLOCK) 
            ON COALESCE(hd.parent_test_pntr, lt.LAB_TEST_pntr) = obs_parent.observation_uid
        LEFT JOIN [dbo].nrt_observation obs_order WITH (NOLOCK) 
            ON lt.LAB_TEST_uid = obs_order.observation_uid AND obs_order.obs_domain_cd_st_1 = 'Order'
        LEFT JOIN #merge_order mo ON lt.root_ordered_test_pntr = mo.root_ordered_test_pntr;


        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #lab_test_final;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------
        
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #lab_test_N';

        IF OBJECT_ID('#lab_test_N', 'U') IS NOT NULL
            DROP TABLE #lab_test_N;

        SELECT distinct ltf.LAB_TEST_UID
        INTO #lab_test_N
        FROM #lab_test_final ltf
        WHERE ltf.RECORD_STATUS_CD <> 'INACTIVE'
        EXCEPT 
        SELECT LAB_TEST_UID
        FROM [dbo].nrt_lab_test_key WITH (NOLOCK);

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #lab_test_N;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
    
        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #lab_test_E';

        IF OBJECT_ID('#lab_test_E', 'U') IS NOT NULL
            DROP TABLE #lab_test_E;

        SELECT distinct ltf.LAB_TEST_uid
        INTO #lab_test_E
        FROM #lab_test_final ltf
        INNER JOIN [dbo].nrt_lab_test_key ltk WITH (NOLOCK) 
            ON ltk.LAB_TEST_UID = ltf.LAB_TEST_uid
        WHERE ltf.RECORD_STATUS_CD <> 'INACTIVE';

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #lab_test_E;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #lab_test_D';

        IF OBJECT_ID('#lab_test_D', 'U') IS NOT NULL
            DROP TABLE #lab_test_D;

        SELECT distinct ltf.LAB_TEST_uid
        INTO #lab_test_D
        FROM #lab_test_final ltf
        INNER JOIN [dbo].nrt_lab_test_key ltk WITH (NOLOCK) 
            ON ltk.LAB_TEST_UID = ltf.LAB_TEST_uid
        WHERE ltf.RECORD_STATUS_CD = 'INACTIVE';

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #lab_test_D;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        -- Lab_Report_User_Comment Dimension
        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #nrt_observation_txt_data';

        IF OBJECT_ID('#nrt_observation_txt_data', 'U') IS NOT NULL
            DROP TABLE #nrt_observation_txt_data;

        ;WITH 
		followup AS (
			SELECT value as observation_uid  
			FROM STRING_SPLIT(
				(SELECT STRING_AGG(followup_observation_uid , ',' ) FROM #observation_data), ','
			) 
		),
		obstxt AS (
            SELECT obstxt.*
            FROM [dbo].nrt_observation_txt obstxt WITH (NOLOCK)
            INNER JOIN #obs_ids ids ON ids.observation_uid =  obstxt.observation_uid
            UNION ALL 
            SELECT obstxt.*
            FROM [dbo].nrt_observation_txt obstxt WITH (NOLOCK)
			INNER JOIN followup f 
				ON f.observation_uid = obstxt.observation_uid
        )
        SELECT 
            obstxt.*           
        INTO #nrt_observation_txt_data
        FROM obstxt
        LEFT JOIN [dbo].nrt_observation obs WITH (NOLOCk)
            ON obs.observation_uid = obstxt.observation_uid
        WHERE 
            isnull(obs.batch_id,1) = isnull(obstxt.batch_id,1);

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #nrt_observation_txt_data;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #lab_rpt_user_comment_data';

        SELECT DISTINCT 
            tdltn.lab_rpt_uid AS LAB_TEST_uid,
            lab214.observation_uid,
            lab214.activity_to_time  AS COMMENTS_FOR_ELR_DT,
            lab214.add_user_id  AS USER_COMMENT_CREATED_BY, 
            CASE
                WHEN REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ') = '' THEN NULL
                ELSE REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')
            END AS USER_RPT_COMMENTS,
            tdltn.record_status_cd  AS RECORD_STATUS_CD 
        INTO #lab_rpt_user_comment_data
        FROM #lab_test_final AS tdltn,
             dbo.nrt_observation AS obs,
             dbo.nrt_observation AS lab214,
             #nrt_observation_txt_data AS ovt  
        WHERE 
            ovt.ovt_value_txt IS NOT NULL
            AND obs.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ','))   
            AND obs.obs_domain_cd_st_1 = 'C_Order'
            AND lab214.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ',')) 
            AND lab214.obs_domain_cd_st_1 = 'C_Result'
            AND lab214.observation_uid = ovt.observation_uid
            AND tdltn.followup_observation_uid IS NOT NULL
        ORDER BY lab214.observation_uid;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #lab_rpt_user_comment_data;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #lab_rpt_user_comment_N';

        IF OBJECT_ID('#lab_rpt_user_comment_N', 'U') IS NOT NULL
            DROP TABLE #lab_rpt_user_comment_N;

        SELECT distinct cd.OBSERVATION_UID, cd.LAB_TEST_UID
        INTO #lab_rpt_user_comment_N
        FROM #lab_rpt_user_comment_data cd
        LEFT JOIN [dbo].nrt_lab_rpt_user_comment_key uck 
            ON uck.LAB_RPT_USER_COMMENT_UID = cd.observation_uid 
            AND uck.LAB_TEST_UID = cd.LAB_TEST_UID
        WHERE uck.LAB_RPT_USER_COMMENT_UID IS NULL AND uck.LAB_TEST_UID IS NULL 

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #lab_rpt_user_comment_N;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------
        
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #lab_rpt_user_comment_E';

        IF OBJECT_ID('#lab_rpt_user_comment_E', 'U') IS NOT NULL
            DROP TABLE #lab_rpt_user_comment_E;

        SELECT distinct cd.OBSERVATION_UID, cd.LAB_TEST_UID
        INTO #lab_rpt_user_comment_E
        FROM #lab_rpt_user_comment_data cd
        INNER JOIN [dbo].nrt_lab_rpt_user_comment_key uck 
            ON uck.LAB_RPT_USER_COMMENT_UID = cd.observation_uid 
            AND uck.LAB_TEST_UID = cd.LAB_TEST_UID
        WHERE cd.RECORD_STATUS_CD <> 'INACTIVE';

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #lab_rpt_user_comment_E;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------
        
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #lab_rpt_user_comment_D';

        IF OBJECT_ID('#lab_rpt_user_comment_D', 'U') IS NOT NULL
            DROP TABLE #lab_rpt_user_comment_D;

        SELECT distinct cd.OBSERVATION_UID, cd.LAB_TEST_UID
        INTO #lab_rpt_user_comment_D
        FROM #lab_rpt_user_comment_data cd        
        INNER JOIN [dbo].nrt_lab_rpt_user_comment_key uck 
            ON uck.LAB_RPT_USER_COMMENT_UID = cd.observation_uid 
            AND uck.LAB_TEST_UID = cd.LAB_TEST_UID
        WHERE cd.RECORD_STATUS_CD = 'INACTIVE';

        SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true'
            SELECT @Proc_Step_Name AS step, * 
            FROM #lab_rpt_user_comment_D;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

            SELECT @rdb_last_refresh_time = GETDATE()
            
            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'GENERATING keys for #lab_test_N';

            INSERT INTO [dbo].nrt_lab_test_key (LAB_TEST_UID)
            SELECT LAB_TEST_UID 
            FROM #lab_test_N

            SELECT @RowCount_no = @@ROWCOUNT;

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, k.* 
                FROM [dbo].nrt_lab_test_key k WITH (NOLOCK)
                INNER JOIN #lab_test_N ltn
                    ON ltn.LAB_TEST_UID = k.LAB_TEST_UID;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'INSERTING new entries to LAB_TEST';

            INSERT INTO [dbo].LAB_TEST (
                [LAB_TEST_STATUS]
                ,[LAB_TEST_KEY]
                ,[LAB_RPT_LOCAL_ID]
                ,[TEST_METHOD_CD]
                ,[TEST_METHOD_CD_DESC]
                ,[LAB_RPT_SHARE_IND]
                ,[LAB_TEST_CD]
                ,[ELR_IND]
                ,[LAB_RPT_UID]
                ,[LAB_TEST_CD_DESC]
                ,[INTERPRETATION_FLG]
                ,[LAB_RPT_RECEIVED_BY_PH_DT]
                ,[LAB_RPT_CREATED_BY]
                ,[REASON_FOR_TEST_DESC]
                ,[REASON_FOR_TEST_CD]
                ,[LAB_RPT_LAST_UPDATE_BY]
                ,[LAB_TEST_DT]
                ,[LAB_RPT_CREATED_DT]
                ,[LAB_TEST_TYPE]
                ,[LAB_RPT_LAST_UPDATE_DT]
                ,[JURISDICTION_CD]
                ,[LAB_TEST_CD_SYS_CD]
                ,[LAB_TEST_CD_SYS_NM]
                ,[JURISDICTION_NM]
                ,[OID]
                ,[ALT_LAB_TEST_CD]
                ,[LAB_RPT_STATUS]
                ,[DANGER_CD_DESC]
                ,[ALT_LAB_TEST_CD_DESC]
                ,[ACCESSION_NBR]
                ,[SPECIMEN_SRC]
                ,[PRIORITY_CD]
                ,[ALT_LAB_TEST_CD_SYS_CD]
                ,[ALT_LAB_TEST_CD_SYS_NM]
                ,[SPECIMEN_SITE]
                ,[SPECIMEN_DETAILS]
                ,[DANGER_CD]
                ,[SPECIMEN_COLLECTION_VOL]
                ,[SPECIMEN_COLLECTION_VOL_UNIT]
                ,[SPECIMEN_DESC]
                ,[SPECIMEN_SITE_DESC]
                ,[CLINICAL_INFORMATION]
                ,[LAB_TEST_UID]
                ,[ROOT_ORDERED_TEST_PNTR]
                ,[PARENT_TEST_PNTR]
                ,[LAB_TEST_PNTR]
                ,[SPECIMEN_ADD_TIME]
                ,[SPECIMEN_LAST_CHANGE_TIME]
                ,[SPECIMEN_COLLECTION_DT]
                ,[SPECIMEN_NM]
                ,[ROOT_ORDERED_TEST_NM]    
                ,[PARENT_TEST_NM]
                ,[TRANSCRIPTIONIST_NAME]
                ,[TRANSCRIPTIONIST_ID]
                ,[TRANSCRIPTIONIST_ASS_AUTH_CD]
                ,[TRANSCRIPTIONIST_ASS_AUTH_TYPE]
                ,[ASSISTANT_INTERPRETER_NAME]
                ,[ASSISTANT_INTERPRETER_ID]
                ,[ASSISTANT_INTER_ASS_AUTH_CD]
                ,[ASSISTANT_INTER_ASS_AUTH_TYPE]
                ,[RESULT_INTERPRETER_NAME]
                ,[RECORD_STATUS_CD]
                ,[RDB_LAST_REFRESH_TIME]
                ,[CONDITION_CD]
                ,[PROCESSING_DECISION_CD]
                ,[PROCESSING_DECISION_DESC] 
            )
            SELECT 
                RTRIM(CAST(ltf.LAB_TEST_STATUS AS VARCHAR(50))),
                k.LAB_TEST_KEY,
                RTRIM(CAST(ltf.LAB_RPT_LOCAL_ID AS VARCHAR(50))),
                RTRIM(CAST(ltf.TEST_METHOD_CD AS VARCHAR(199))),
                RTRIM(CAST(ltf.TEST_METHOD_CD_DESC AS VARCHAR(100))),
                RTRIM(CAST(ltf.LAB_RPT_SHARE_IND AS VARCHAR(50))),
                RTRIM(CAST(ltf.LAB_TEST_CD AS VARCHAR(1000))),
                RTRIM(CAST(ltf.ELR_IND AS VARCHAR(50))),
                ltf.LAB_RPT_UID,
                RTRIM(CAST(ltf.LAB_TEST_CD_DESC AS VARCHAR(2000))),
                RTRIM(CAST(ltf.INTERPRETATION_FLG as VARCHAR(20))),
                ltf.LAB_RPT_RECEIVED_BY_PH_DT,
                ltf.LAB_RPT_CREATED_BY,
                RTRIM(CAST(ltf.REASON_FOR_TEST_DESC AS VARCHAR(4000))),
                RTRIM(CAST(ltf.REASON_FOR_TEST_CD AS VARCHAR(4000))),
                ltf.LAB_RPT_LAST_UPDATE_BY,
                ltf.LAB_TEST_DT,
                ltf.LAB_RPT_CREATED_DT,
                RTRIM(CAST(ltf.LAB_TEST_TYPE AS VARCHAR(50))),
                ltf.LAB_RPT_LAST_UPDATE_DT,
                RTRIM(CAST(ltf.JURISDICTION_CD AS VARCHAR(20))),
                RTRIM(CAST(ltf.LAB_TEST_CD_SYS_CD AS VARCHAR(50))),
                RTRIM(CAST(ltf.LAB_TEST_CD_SYS_NM AS VARCHAR(100))),
                RTRIM(CAST(ltf.JURISDICTION_NM AS VARCHAR(50))),
                ltf.OID,
                RTRIM(CAST(ltf.ALT_LAB_TEST_CD AS VARCHAR(50))),
                CAST(ltf.LAB_RPT_STATUS AS VARCHAR(1)),
                RTRIM(CAST(ltf.DANGER_CD_DESC AS VARCHAR(100))),
                RTRIM(CAST(ltf.ALT_LAB_TEST_CD_DESC AS VARCHAR(1000))),
                RTRIM(CAST(ltf.ACCESSION_NBR AS VARCHAR(100))),
                RTRIM(CAST(ltf.SPECIMEN_SRC AS VARCHAR(50))),
                RTRIM(CAST(ltf.PRIORITY_CD AS VARCHAR(20))),
                RTRIM(CAST(ltf.ALT_LAB_TEST_CD_SYS_CD AS VARCHAR(50))),
                RTRIM(CAST(ltf.ALT_LAB_TEST_CD_SYS_NM AS VARCHAR(100))),
                RTRIM(CAST(ltf.SPECIMEN_SITE AS VARCHAR(20))),
                RTRIM(CAST(ltf.SPECIMEN_DETAILS AS VARCHAR(100))),
                RTRIM(CAST(ltf.DANGER_CD AS VARCHAR(20))),
                RTRIM(CAST(ltf.SPECIMEN_COLLECTION_VOL AS VARCHAR(20))),
                RTRIM(CAST(ltf.SPECIMEN_COLLECTION_VOL_UNIT AS VARCHAR(50))),
                RTRIM(CAST(ltf.SPECIMEN_DESC AS VARCHAR(1000))),
                RTRIM(CAST(ltf.SPECIMEN_SITE_DESC AS VARCHAR(100))),
                RTRIM(CAST(ltf.CLINICAL_INFORMATION AS VARCHAR(1000))),
                ltf.LAB_TEST_UID,
                ltf.ROOT_ORDERED_TEST_PNTR,
                ltf.PARENT_TEST_PNTR,
                ltf.LAB_TEST_PNTR,
                ltf.SPECIMEN_ADD_TIME,
                ltf.SPECIMEN_LAST_CHANGE_TIME,
                ltf.SPECIMEN_COLLECTION_DT,
                RTRIM(CAST(ltf.SPECIMEN_NM AS VARCHAR(100))),
                RTRIM(CAST(ltf.ROOT_ORDERED_TEST_NM AS VARCHAR(1000))),    
                RTRIM(CAST(ltf.PARENT_TEST_NM AS VARCHAR(1000))),
                RTRIM(CAST(ltf.TRANSCRIPTIONIST_NAME AS VARCHAR(300))),
                RTRIM(CAST(ltf.TRANSCRIPTIONIST_ID AS VARCHAR(100))),
                RTRIM(CAST(ltf.TRANSCRIPTIONIST_ASS_AUTH_CD AS VARCHAR(199))),
                RTRIM(CAST(ltf.TRANSCRIPTIONIST_ASS_AUTH_TYPE AS VARCHAR(100))),
                RTRIM(CAST(ltf.ASSISTANT_INTERPRETER_NAME AS VARCHAR(300))),
                RTRIM(CAST(ltf.ASSISTANT_INTERPRETER_ID AS VARCHAR(100))),
                RTRIM(CAST(ltf.ASSISTANT_INTER_ASS_AUTH_CD AS VARCHAR(199))),
                RTRIM(CAST(ltf.ASSISTANT_INTER_ASS_AUTH_TYPE AS VARCHAR(100))),
                RTRIM(CAST(ltf.RESULT_INTERPRETER_NAME AS VARCHAR(300))),
                RTRIM(CAST(ltf.RECORD_STATUS_CD AS VARCHAR(8))),
                @rdb_last_refresh_time,
                RTRIM(CAST(ltf.CONDITION_CD AS VARCHAR(20))),
                RTRIM(CAST(ltf.PROCESSING_DECISION_CD AS VARCHAR(50))),
                RTRIM(CAST(ltf.PROCESSING_DECISION_DESC AS VARCHAR(50)))
            FROM #lab_test_final ltf 
            INNER JOIN #lab_test_N ltn 
                ON ltn.LAB_TEST_UID = ltf.LAB_TEST_UID
            INNER JOIN [dbo].nrt_lab_test_key k WITH (NOLOCK)
                ON k.LAB_TEST_UID = ltf.LAB_TEST_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, lt.* 
                FROM [dbo].LAB_TEST lt 
                INNER JOIN #lab_test_N ltn 
                    ON ltn.LAB_TEST_UID = lt.LAB_TEST_UID
                INNER JOIN [dbo].nrt_lab_test_key k WITH (NOLOCK)
                    ON k.LAB_TEST_UID = lt.LAB_TEST_UID;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'UPDATING existing entries in LAB_TEST';

            UPDATE lt 
            SET 
                lt.[LAB_TEST_STATUS]                = RTRIM(CAST(ltf.LAB_TEST_STATUS AS varchar(50))),
                lt.[LAB_RPT_LOCAL_ID]               = RTRIM(CAST(ltf.LAB_RPT_LOCAL_ID AS varchar(50))),
                lt.[TEST_METHOD_CD]                 = RTRIM(CAST(ltf.TEST_METHOD_CD AS varchar(199))),
                lt.[TEST_METHOD_CD_DESC]            = RTRIM(CAST(ltf.TEST_METHOD_CD_DESC AS varchar(199))),
                lt.[LAB_RPT_SHARE_IND]              = RTRIM(CAST(ltf.LAB_RPT_SHARE_IND AS varchar(50))),
                lt.[LAB_TEST_CD]                    = RTRIM(CAST(ltf.LAB_TEST_CD AS varchar(1000))),
                lt.[ELR_IND]                        = RTRIM(CAST(ltf.ELR_IND AS varchar(50))),
                lt.[LAB_RPT_UID]                    = ltf.LAB_RPT_UID,
                lt.[LAB_TEST_CD_DESC]               = RTRIM(CAST(ltf.LAB_TEST_CD_DESC AS varchar(2000))),
                lt.[INTERPRETATION_FLG]             = RTRIM(CAST(ltf.INTERPRETATION_FLG AS varchar(20))),
                lt.[LAB_RPT_RECEIVED_BY_PH_DT]      = ltf.LAB_RPT_RECEIVED_BY_PH_DT,
                lt.[LAB_RPT_CREATED_BY]             = ltf.LAB_RPT_CREATED_BY,
                lt.[REASON_FOR_TEST_DESC]           = RTRIM(CAST(ltf.REASON_FOR_TEST_DESC AS varchar(4000))),
                lt.[REASON_FOR_TEST_CD]             = RTRIM(CAST(ltf.REASON_FOR_TEST_CD AS varchar(4000))),
                lt.[LAB_RPT_LAST_UPDATE_BY]         = ltf.LAB_RPT_LAST_UPDATE_BY,
                lt.[LAB_TEST_DT]                    = ltf.LAB_TEST_DT,
                lt.[LAB_RPT_CREATED_DT]             = ltf.LAB_RPT_CREATED_DT,
                lt.[LAB_TEST_TYPE]                  = RTRIM(CAST(ltf.LAB_TEST_TYPE AS varchar(50))),
                lt.[LAB_RPT_LAST_UPDATE_DT]         = ltf.LAB_RPT_LAST_UPDATE_DT,
                lt.[JURISDICTION_CD]                = RTRIM(CAST(ltf.JURISDICTION_CD AS varchar(20))),
                lt.[LAB_TEST_CD_SYS_CD]             = RTRIM(CAST(ltf.LAB_TEST_CD_SYS_CD AS varchar(50))),
                lt.[LAB_TEST_CD_SYS_NM]             = RTRIM(CAST(ltf.LAB_TEST_CD_SYS_NM AS varchar(100))),
                lt.[JURISDICTION_NM]                = RTRIM(CAST(ltf.JURISDICTION_NM AS varchar(50))),
                lt.[OID]                            = ltf.OID,
                lt.[ALT_LAB_TEST_CD]                = RTRIM(CAST(ltf.ALT_LAB_TEST_CD AS varchar(50))),
                lt.[LAB_RPT_STATUS]                 = CAST(ltf.LAB_RPT_STATUS AS char(1)),
                lt.[DANGER_CD_DESC]                 = RTRIM(CAST(ltf.DANGER_CD_DESC AS varchar(100))),
                lt.[ALT_LAB_TEST_CD_DESC]           = RTRIM(CAST(ltf.ALT_LAB_TEST_CD_DESC AS varchar(1000))),
                lt.[ACCESSION_NBR]                  = RTRIM(CAST(ltf.ACCESSION_NBR AS varchar(199))),
                lt.[SPECIMEN_SRC]                   = RTRIM(CAST(ltf.SPECIMEN_SRC AS varchar(50))),
                lt.[PRIORITY_CD]                    = RTRIM(CAST(ltf.PRIORITY_CD AS varchar(20))),
                lt.[ALT_LAB_TEST_CD_SYS_CD]         = RTRIM(CAST(ltf.ALT_LAB_TEST_CD_SYS_CD AS varchar(50))),
                lt.[ALT_LAB_TEST_CD_SYS_NM]         = RTRIM(CAST(ltf.ALT_LAB_TEST_CD_SYS_NM AS varchar(100))),
                lt.[SPECIMEN_SITE]                  = RTRIM(CAST(ltf.SPECIMEN_SITE AS varchar(20))),
                lt.[SPECIMEN_DETAILS]               = RTRIM(CAST(ltf.SPECIMEN_DETAILS AS varchar(1000))),
                lt.[DANGER_CD]                      = RTRIM(CAST(ltf.DANGER_CD AS varchar(20))),
                lt.[SPECIMEN_COLLECTION_VOL]        = RTRIM(CAST(ltf.SPECIMEN_COLLECTION_VOL AS varchar(20))),
                lt.[SPECIMEN_COLLECTION_VOL_UNIT]   = RTRIM(CAST(ltf.SPECIMEN_COLLECTION_VOL_UNIT AS varchar(50))),
                lt.[SPECIMEN_DESC]                  = RTRIM(CAST(ltf.SPECIMEN_DESC AS varchar(1000))),
                lt.[SPECIMEN_SITE_DESC]             = RTRIM(CAST(ltf.SPECIMEN_SITE_DESC AS varchar(100))),
                lt.[CLINICAL_INFORMATION]           = RTRIM(CAST(ltf.CLINICAL_INFORMATION AS varchar(1000))),
                lt.[ROOT_ORDERED_TEST_PNTR]         = ltf.ROOT_ORDERED_TEST_PNTR,
                lt.[PARENT_TEST_PNTR]               = ltf.PARENT_TEST_PNTR,
                lt.[LAB_TEST_PNTR]                  = ltf.LAB_TEST_PNTR,
                lt.[SPECIMEN_ADD_TIME]              = ltf.SPECIMEN_ADD_TIME,
                lt.[SPECIMEN_LAST_CHANGE_TIME]      = ltf.SPECIMEN_LAST_CHANGE_TIME,
                lt.[SPECIMEN_COLLECTION_DT]         = ltf.SPECIMEN_COLLECTION_DT,
                lt.[SPECIMEN_NM]                    = RTRIM(CAST(ltf.SPECIMEN_NM AS varchar(100))),
                lt.[ROOT_ORDERED_TEST_NM]           = RTRIM(CAST(ltf.ROOT_ORDERED_TEST_NM AS varchar(1000))),
                lt.[PARENT_TEST_NM]                 = RTRIM(CAST(ltf.PARENT_TEST_NM AS varchar(1000))),
                lt.[TRANSCRIPTIONIST_NAME]          = RTRIM(CAST(ltf.TRANSCRIPTIONIST_NAME AS varchar(300))),
                lt.[TRANSCRIPTIONIST_ID]            = RTRIM(CAST(ltf.TRANSCRIPTIONIST_ID AS varchar(100))),
                lt.[TRANSCRIPTIONIST_ASS_AUTH_CD]   = RTRIM(CAST(ltf.TRANSCRIPTIONIST_ASS_AUTH_CD AS varchar(199))),
                lt.[TRANSCRIPTIONIST_ASS_AUTH_TYPE] = RTRIM(CAST(ltf.TRANSCRIPTIONIST_ASS_AUTH_TYPE AS varchar(100))),
                lt.[ASSISTANT_INTERPRETER_NAME]     = RTRIM(CAST(ltf.ASSISTANT_INTERPRETER_NAME AS varchar(300))),
                lt.[ASSISTANT_INTERPRETER_ID]       = RTRIM(CAST(ltf.ASSISTANT_INTERPRETER_ID AS varchar(100))),
                lt.[ASSISTANT_INTER_ASS_AUTH_CD]    = RTRIM(CAST(ltf.ASSISTANT_INTER_ASS_AUTH_CD AS varchar(199))),
                lt.[ASSISTANT_INTER_ASS_AUTH_TYPE]  = RTRIM(CAST(ltf.ASSISTANT_INTER_ASS_AUTH_TYPE AS varchar(100))),
                lt.[RESULT_INTERPRETER_NAME]        = RTRIM(CAST(ltf.RESULT_INTERPRETER_NAME AS varchar(300))),
                lt.[RECORD_STATUS_CD]               = RTRIM(CAST(ltf.RECORD_STATUS_CD AS varchar(8))),
                lt.[RDB_LAST_REFRESH_TIME]          = @rdb_last_refresh_time,
                lt.[CONDITION_CD]                   = RTRIM(CAST(ltf.CONDITION_CD AS varchar(20))),
                lt.[PROCESSING_DECISION_CD]         = RTRIM(CAST(ltf.PROCESSING_DECISION_CD AS varchar(50))),
                lt.[PROCESSING_DECISION_DESC]       = RTRIM(CAST(ltf.PROCESSING_DECISION_DESC AS varchar(50)))
            FROM [dbo].LAB_TEST lt 
            INNER JOIN #lab_test_final ltf 
                ON lt.LAB_TEST_UID = ltf.LAB_TEST_UID
            INNER JOIN #lab_test_E lte 
                ON lte.LAB_TEST_UID = ltf.LAB_TEST_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, lt.* 
                FROM [dbo].LAB_TEST lt 
                INNER JOIN #lab_test_final ltf 
                    ON lt.LAB_TEST_UID = ltf.LAB_TEST_UID
                INNER JOIN #lab_test_E lte 
                    ON lte.LAB_TEST_UID = ltf.LAB_TEST_UID;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'Update Inactive LAB_TEST Records';


            /* Update records associated to Inactive Orders using Root Order UID. */

            ;WITH inactive_orders AS (
                SELECT 
                    lt.root_ordered_test_pntr
                FROM dbo.LAB_TEST lt WITH (NOLOCK)
                INNER JOIN #lab_test_D ltd
                    ON ltd.LAB_TEST_UID = lt.LAB_TEST_UID
                WHERE 
                    lt.lab_test_type = 'Order'
                    AND lt.record_status_cd = 'INACTIVE'
            )
            UPDATE lt
            SET record_status_cd = 'INACTIVE'
            FROM [dbo].LAB_TEST lt 
            INNER JOIN inactive_orders inor 
                ON inor.root_ordered_test_pntr = lt.root_ordered_test_pntr
            WHERE
                record_status_cd <> 'INACTIVE';


            SELECT @RowCount_no = @@ROWCOUNT;

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, lt.* 
                FROM [dbo].LAB_TEST lt WITH (NOLOCK) 
                INNER JOIN #lab_test_D ltd
                    ON ltd.LAB_TEST_UID = lt.LAB_TEST_UID;


            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'UPDATING [dbo].nrt_lab_test_key table';

            UPDATE ltk 
            SET 
                ltk.[updated_dttm] = @rdb_last_refresh_time
            FROM [dbo].nrt_lab_test_key ltk
            INNER JOIN #lab_test_E lte 
                ON lte.LAB_TEST_UID = ltk.LAB_TEST_UID;    

            SELECT @RowCount_no = @@ROWCOUNT;

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, ltk.* 
                FROM [dbo].nrt_lab_test_key ltk
                INNER JOIN #lab_test_E lte 
                    ON lte.LAB_TEST_UID = ltk.LAB_TEST_UID;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
            

            --------------------------------------------------------------------------------------------------------

            -- LAB_RPT_USER_COMMENT Dimension 
            --------------------------------------------------------------------------------------------------------
            
            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'GENERATING keys for #lab_rpt_user_comment_N';

            INSERT INTO [dbo].nrt_lab_rpt_user_comment_key (LAB_RPT_USER_COMMENT_UID, LAB_TEST_UID)
            SELECT OBSERVATION_UID, LAB_TEST_UID 
            FROM #lab_rpt_user_comment_N 

            SELECT @RowCount_no = @@ROWCOUNT;

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, k.* 
                FROM [dbo].nrt_lab_rpt_user_comment_key k WITH (NOLOCK)
                INNER JOIN #lab_rpt_user_comment_N ucn
                    ON ucn.observation_uid = k.LAB_RPT_USER_COMMENT_UID
                    AND ucn.LAB_TEST_UID = k.LAB_TEST_UID;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------


            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'INSERTING new entries to LAB_RPT_USER_COMMENT';

            INSERT INTO [dbo].LAB_RPT_USER_COMMENT (
                [USER_COMMENT_KEY]
                ,[USER_RPT_COMMENTS]
                ,[COMMENTS_FOR_ELR_DT]
                ,[USER_COMMENT_CREATED_BY]
                ,[LAB_TEST_KEY]
                ,[RECORD_STATUS_CD]
                ,[LAB_TEST_UID]
                ,[RDB_LAST_REFRESH_TIME]
            )
            SELECT 
                uck.USER_COMMENT_KEY,
                CAST(ucd.USER_RPT_COMMENTS AS VARCHAR(2000)),
                ucd.COMMENTS_FOR_ELR_DT,
                ucd.USER_COMMENT_CREATED_BY,
                lk.LAB_TEST_KEY,
                CAST(ucd.RECORD_STATUS_CD AS VARCHAR(8)) ,
                ucd.LAB_TEST_UID,
                @rdb_last_refresh_time
            FROM #lab_rpt_user_comment_data ucd
            INNER JOIN #lab_rpt_user_comment_N ucdn 
                ON ucdn.observation_uid = ucd.observation_uid 
                AND ucdn.LAB_TEST_UID = ucd.LAB_TEST_UID
            INNER JOIN [dbo].nrt_lab_rpt_user_comment_key uck 
                ON uck.LAB_RPT_USER_COMMENT_UID = ucdn.observation_uid 
                AND uck.LAB_TEST_UID = ucdn.LAB_TEST_UID
            INNER JOIN [dbo].nrt_lab_test_key lk
                    ON lk.LAB_TEST_UID = ucd.LAB_TEST_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, lruc.* 
                FROM [dbo].LAB_RPT_USER_COMMENT lruc WITH (NOLOCK)  
                INNER JOIN [dbo].nrt_lab_rpt_user_comment_key uck 
                    ON uck.USER_COMMENT_KEY = lruc.USER_COMMENT_KEY 
                    AND uck.LAB_TEST_UID = lruc.LAB_TEST_UID
                INNER JOIN #lab_rpt_user_comment_N ucdn 
                    ON ucdn.observation_uid = uck.LAB_RPT_USER_COMMENT_UID 
                    AND ucdn.LAB_TEST_UID = uck.LAB_TEST_UID
                INNER JOIN [dbo].nrt_lab_test_key lk
                    ON lk.LAB_TEST_UID = lruc.LAB_TEST_UID; 

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'UPDATING existing entries in LAB_RPT_USER_COMMENT';
            
            UPDATE LRUC
            SET 
                USER_RPT_COMMENTS = CAST(ucd.USER_RPT_COMMENTS AS VARCHAR(2000)),
                COMMENTS_FOR_ELR_DT = ucd.COMMENTS_FOR_ELR_DT,
                USER_COMMENT_CREATED_BY = ucd.USER_COMMENT_CREATED_BY,
                RECORD_STATUS_CD = CAST(ucd.RECORD_STATUS_CD AS VARCHAR(8)),
                RDB_LAST_REFRESH_TIME = @rdb_last_refresh_time
            FROM [dbo].LAB_RPT_USER_COMMENT lruc 
            INNER JOIN [dbo].nrt_lab_rpt_user_comment_key uck
                ON uck.USER_COMMENT_KEY = lruc.USER_COMMENT_KEY 
                AND uck.LAB_TEST_UID = lruc.LAB_TEST_UID
            INNER JOIN #lab_rpt_user_comment_E ucde
                ON ucde.observation_uid = uck.LAB_RPT_USER_COMMENT_UID
                AND ucde.LAB_TEST_UID = uck.LAB_TEST_UID
            INNER JOIN #lab_rpt_user_comment_data ucd
                ON ucd.observation_uid = ucde.observation_uid
                AND ucd.LAB_TEST_uid = ucde.LAB_TEST_uid
            INNER JOIN [dbo].nrt_lab_test_key lk
                    ON lk.LAB_TEST_UID = ucd.LAB_TEST_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, lruc.* 
                FROM [dbo].LAB_RPT_USER_COMMENT lruc WITH (NOLOCK)  
                INNER JOIN [dbo].nrt_lab_rpt_user_comment_key uck
                    ON uck.USER_COMMENT_KEY = lruc.USER_COMMENT_KEY 
                    AND uck.LAB_TEST_UID = lruc.LAB_TEST_UID
                INNER JOIN #lab_rpt_user_comment_E ucde
                    ON ucde.observation_uid = uck.LAB_RPT_USER_COMMENT_UID
                    AND ucde.LAB_TEST_UID = uck.LAB_TEST_UID
                INNER JOIN #lab_rpt_user_comment_data ucd
                    ON ucd.observation_uid = ucde.observation_uid
                    AND ucd.LAB_TEST_uid = ucde.LAB_TEST_uid
                INNER JOIN [dbo].nrt_lab_test_key lk
                    ON lk.LAB_TEST_UID = ucd.LAB_TEST_UID;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'UPDATING [dbo].nrt_lab_rpt_user_comment_key table';

            UPDATE uck 
            SET 
                uck.[updated_dttm] = @rdb_last_refresh_time
            FROM [dbo].nrt_lab_rpt_user_comment_key uck
            INNER JOIN #lab_rpt_user_comment_E ucde
                ON ucde.observation_uid = uck.LAB_RPT_USER_COMMENT_UID 
                AND ucde.LAB_TEST_UID = uck.LAB_TEST_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, uck.* 
                FROM [dbo].nrt_lab_rpt_user_comment_key uck
                INNER JOIN #lab_rpt_user_comment_E ucde
                    ON ucde.observation_uid = uck.LAB_RPT_USER_COMMENT_UID 
                    AND ucde.LAB_TEST_UID = uck.LAB_TEST_UID;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
            
            --------------------------------------------------------------------------------------------------------
        
            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'DELETING inactive entries from LAB_RPT_USER_COMMENT';

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, uc.* 
                FROM [dbo].LAB_RPT_USER_COMMENT uc 
                INNER JOIN [dbo].nrt_lab_rpt_user_comment_key uck
                    ON uck.LAB_TEST_UID = uc.LAB_TEST_UID 
                    AND uck.USER_COMMENT_KEY = uc.USER_COMMENT_KEY
                INNER JOIN #lab_rpt_user_comment_D ucd
                    ON ucd.LAB_TEST_UID = uck.LAB_TEST_UID 
                    AND ucd.observation_uid = uck.LAB_RPT_USER_COMMENT_UID;

            DELETE uc 
            FROM [dbo].LAB_RPT_USER_COMMENT uc 
            INNER JOIN [dbo].nrt_lab_rpt_user_comment_key uck
                ON uck.LAB_TEST_UID = uc.LAB_TEST_UID 
                AND uck.USER_COMMENT_KEY = uc.USER_COMMENT_KEY
            INNER JOIN #lab_rpt_user_comment_D ucd
                ON ucd.LAB_TEST_UID = uck.LAB_TEST_UID 
                AND ucd.observation_uid = uck.LAB_RPT_USER_COMMENT_UID;
            
            DELETE uck
            FROM [dbo].nrt_lab_rpt_user_comment_key uck
            INNER JOIN #lab_rpt_user_comment_D ucd 
                ON ucd.LAB_TEST_UID = uck.LAB_TEST_UID 
                AND ucd.observation_uid = uck.LAB_RPT_USER_COMMENT_UID;
           

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
            --------------------------------------------------------------------------------------------------------

            -- LAB_TEST Dimension
            --------------------------------------------------------------------------------------------------------

            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET @PROC_STEP_NAME = 'DELETING inactive entries from LAB_TEST';

            IF @debug = 'true'
                SELECT @Proc_Step_Name AS step, lt.* 
                FROM [dbo].LAB_TEST lt 
                INNER JOIN [dbo].nrt_lab_test_key ltk
                    ON ltk.LAB_TEST_KEY = lt.LAB_TEST_KEY
                INNER JOIN #lab_test_D ltd
                    ON ltd.LAB_TEST_UID = ltk.LAB_TEST_UID; 

            DELETE lt 
            FROM [dbo].LAB_TEST lt 
            INNER JOIN [dbo].nrt_lab_test_key ltk
                ON ltk.LAB_TEST_KEY = lt.LAB_TEST_KEY
            INNER JOIN #lab_test_D ltd
                ON ltd.LAB_TEST_UID = ltk.LAB_TEST_UID; 
            
            DELETE ltk
            FROM [dbo].nrt_lab_test_key ltk
            INNER JOIN #lab_test_D ltd
                ON ltd.LAB_TEST_UID = ltk.LAB_TEST_UID; 
           

            SELECT @RowCount_no = @@ROWCOUNT;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION
        
        --------------------------------------------------------------------------------------------------------
        
        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
            DECLARE @FullErrorMessage VARCHAR(8000) =
                'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
                'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error Message: ' + ERROR_MESSAGE();


            INSERT INTO [dbo].[job_flow_log] 
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);

        return -1 ;

    END CATCH

END;