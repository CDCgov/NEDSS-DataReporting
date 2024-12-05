CREATE OR ALTER PROCEDURE dbo.sp_d_lab_test_postprocessing @obs_ids nvarchar(max),
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


    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @batch_id BIGINT;
    SET @batch_id = CAST((format(getdate(), 'yyyyMMddHHmmss')) as bigint);

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
               , 'D_LAB_TEST'
               , 'D_LAB_TEST'
               , 'START'
               , @Proc_Step_no
               , @Proc_Step_Name
               , 0
               , LEFT('ID List-' + @obs_ids, 500));

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING #s_edx_document1 ';


        IF OBJECT_ID('#s_edx_document1', 'U') IS NOT NULL
            drop table #s_edx_document1;

        select EDX_Document_uid, edx_act_uid, edx_add_time
        into #s_edx_document1
        from (select EDX_Document_uid,
                     edx_act_uid,
                     edx_add_time,
                     ROW_NUMBER() OVER (PARTITION BY edx_act_uid ORDER BY edx_add_time DESC) rankno
              from dbo.nrt_observation_edx edx
              where edx.edx_act_uid IN (SELECT value FROM STRING_SPLIT(@obs_ids, ','))) edx_lst
        where edx_lst.rankno = 1;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #LAB_TESTinit_a ';


        IF OBJECT_ID('#LAB_TESTinit_a', 'U') IS NOT NULL
            drop table #LAB_TESTinit_a;


        select distinct obs.observation_uid          as LAB_TEST_uid_Test,
                        cast(1 as bigint)            as parent_test_pntr,
                        obs.observation_uid          as LAB_TEST_pntr,
                        obs.activity_to_time         as LAB_TEST_dt,
                        obs.method_cd                as test_method_cd,
                        cast(1 as bigint)            as root_ordered_test_pntr,
                        obs.method_desc_txt          as test_method_cd_desc,
                        obs.priority_cd              as priority_cd,
                        obs.target_site_cd           as specimen_site,
                        obs.target_site_desc_txt     as SPECIMEN_SITE_desc,
                        obs.txt                      as Clinical_information,
                        obs.obs_domain_cd_st_1       as LAB_TEST_Type,
                        obs.cd                       as LAB_TEST_cd,
                        obs.cd_desc_txt              as LAB_TEST_cd_desc,
                        obs.Cd_system_cd             as LAB_TEST_cd_sys_cd,
                        obs.Cd_system_desc_txt       as LAB_TEST_cd_sys_nm,
                        obs.Alt_cd                   as Alt_LAB_TEST_cd,
                        obs.Alt_cd_desc_txt          as Alt_LAB_TEST_cd_desc,
                        obs.Alt_cd_system_cd         as Alt_LAB_TEST_cd_sys_cd,
                        obs.Alt_cd_system_desc_txt   as Alt_LAB_TEST_cd_sys_nm,
                        obs.effective_from_time      as specimen_collection_dt,
                        obs.local_id                 as lab_rpt_local_id,
                        obs.shared_ind               as lab_rpt_share_ind,
                        obs.PROGRAM_JURISDICTION_OID as oid,
                        obs.record_status_cd         as record_status_cd,
                        obs.record_status_cd         as record_status_cd_for_result,
                        obs.STATUS_CD                as lab_rpt_status,
                        obs.ADD_TIME                 as LAB_RPT_CREATED_DT,
                        obs.ADD_USER_ID              as LAB_RPT_CREATED_BY,
                        obs.rpt_to_state_time        as LAB_RPT_RECEIVED_BY_PH_DT,
                        obs.LAST_CHG_TIME            as LAB_RPT_LAST_UPDATE_DT,
                        obs.LAST_CHG_USER_ID         as LAB_RPT_LAST_UPDATE_BY,
                        obs.electronic_ind           as ELR_IND,
                        obs.jurisdiction_cd          as Jurisdiction_cd,
                        CASE
                            WHEN jurisdiction_cd IS NOT NULL THEN jc.code_desc_txt
                            ELSE cast(null as [varchar](50))
                            END                      as JURISDICTION_NM,
                        obs.observation_uid          as Lab_Rpt_Uid,
                        obs.activity_to_time         as resulted_lab_report_date,
                        obs.activity_to_time         as sus_lab_report_date,
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
                        loinc_con.condition_cd       as condition_cd,
                        cvg.code_short_desc_txt      as LAB_TEST_status,
                        obs.PROCESSING_DECISION_CD
        into #LAB_TESTinit_a
        from dbo.nrt_observation obs
                 left join nbs_srte..loinc_condition as loinc_con on obs.cd = loinc_con.loinc_cd
                 left join nbs_srte..code_value_general as cvg
                           on obs.status_cd = cvg.code
                               and cvg.code_set_nm = 'ACT_OBJ_ST'
                 left join nbs_srte..Jurisdiction_code jc
                           on obs.jurisdiction_cd = jc.code
                               and jc.code_set_nm = 'S_JURDIC_C'
        where obs.obs_domain_cd_st_1 in ('Order', 'Result', 'R_Order', 'R_Result', 'I_Order', 'I_Result', 'Order_rslt')
          and (obs.CTRL_CD_DISPLAY_FORM = 'LabReport' or obs.CTRL_CD_DISPLAY_FORM = 'LabReportMorb' or
               obs.CTRL_CD_DISPLAY_FORM is null)
          and obs.observation_uid in (SELECT value FROM STRING_SPLIT(@obs_ids, ','));


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #LAB_TESTinit_a;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #s_edx_document ';


        IF
            OBJECT_ID('#s_edx_document', 'U') IS NOT NULL
            drop table #s_edx_document;

        WITH edx_prep AS (select EDX_Document_uid,
                                 edx_act_uid,
                                 edx_add_time,
                                 CONVERT(varchar, edx_add_time, 101) as add_timeSt
                          from #s_edx_document1)
        select EDX_Document_uid,
               edx_act_uid,
               edx_add_time,
               add_timeSt,
               document_link = ('<a href="#" ' +
                                replace(
                                        ('onClick="window.open(''/nbs/viewELRDocument.do?method=viewELRDocument&documentUid='
                                            + cast(EDX_Document_uid as varchar) + ' &dateReceivedHidden=' + add_timeSt + ''' ,''DocumentViewer'',''width=900,height=800,left=0,top=0,
						menubar=no,titlebar=no,toolbar=no,scrollbars=yes,location=no'');">View Lab Document</a>'), ' ',
                                        ''))
        into #s_edx_document
        from edx_prep;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TESTinit ';


        IF
            OBJECT_ID('#LAB_TESTinit', 'U') IS NOT NULL
            drop table #LAB_TESTinit;

        select distinct a.LAB_TEST_uid_Test,
                        a.parent_test_pntr,
                        a.LAB_TEST_pntr,
                        a.LAB_TEST_dt,
                        a.test_method_cd,
                        a.root_ordered_test_pntr,
                        a.test_method_cd_desc,
                        a.priority_cd,
                        a.specimen_site,
                        a.SPECIMEN_SITE_desc,
                        a.Clinical_information,
                        a.LAB_TEST_Type,
                        a.LAB_TEST_cd,
                        a.LAB_TEST_cd_desc,
                        a.LAB_TEST_cd_sys_cd,
                        a.LAB_TEST_cd_sys_nm,
                        a.Alt_LAB_TEST_cd,
                        a.Alt_LAB_TEST_cd_desc,
                        a.Alt_LAB_TEST_cd_sys_cd,
                        a.Alt_LAB_TEST_cd_sys_nm,
                        a.specimen_collection_dt,
                        a.lab_rpt_local_id,
                        a.lab_rpt_share_ind,
                        a.oid,
                        a.record_status_cd,
                        a.record_status_cd_for_result,
                        a.lab_rpt_status,
                        a.LAB_RPT_CREATED_DT,
                        a.LAB_RPT_CREATED_BY,
                        a.LAB_RPT_RECEIVED_BY_PH_DT,
                        a.LAB_RPT_LAST_UPDATE_DT,
                        a.LAB_RPT_LAST_UPDATE_BY,
                        a.ELR_IND,
                        a.Jurisdiction_cd,
                        a.JURISDICTION_NM,
                        a.Lab_Rpt_Uid,
                        a.resulted_lab_report_date,
                        a.sus_lab_report_date,
                        a.report_observation_uid,
                        a.report_refr_uid,
                        a.report_sprt_uid,
                        a.followup_observation_uid,
                        a.accession_number,
                        a.morb_hosp_id,
                        a.transcriptionist_auth_type,
                        a.assistant_interpreter_auth_type,
                        a.morb_physician_id,
                        a.morb_reporter_id,
                        a.transcriptionist_val,
                        a.transcriptionist_first_nm,
                        a.transcriptionist_last_nm,
                        a.assistant_interpreter_val,
                        a.assistant_interpreter_first_nm,
                        a.assistant_interpreter_last_nm,
                        a.result_interpreter_id,
                        a.transcriptionist_id_assign_auth,
                        a.assistant_interpreter_id_assign_auth,
                        a.interpretation_cd,
                        a.condition_cd,
                        a.LAB_TEST_status,
                        a.PROCESSING_DECISION_CD,
                        b.document_link
        into #LAB_TESTinit
        from #LAB_TESTinit_a a
                 left outer join #s_edx_document b on a.LAB_TEST_uid_test = b.edx_act_uid;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST_mat_init ';


        IF
            OBJECT_ID('#LAB_TEST_mat_init', 'U') IS NOT NULL
            drop table #LAB_TEST_mat_init;

        with ordered_mat as (select mat.act_uid,
                                    mat.material_cd,
                                    mat.material_nm,
                                    mat.material_details,
                                    mat.material_collection_vol,
                                    mat.material_collection_vol_unit,
                                    mat.material_desc,
                                    mat.risk_cd,
                                    mat.risk_desc_txt,
                                    ROW_NUMBER() OVER (PARTITION BY act_uid order by last_chg_time desc) as row_num
                             from dbo.nrt_observation_material mat
                             where mat.act_uid in (SELECT value FROM STRING_SPLIT(@obs_ids, ',')))
        select mat.act_uid                      as LAB_TEST_uid_mat,
               mat.material_cd                  as specimen_src,
               mat.material_nm                  as specimen_nm,
               mat.material_details             as Specimen_details,
               mat.material_collection_vol      as Specimen_collection_vol,
               mat.material_collection_vol_unit as Specimen_collection_vol_unit,
               mat.material_desc                as Specimen_desc,
               mat.risk_cd                      as Danger_cd,
               mat.risk_desc_txt                as Danger_cd_desc
        into #LAB_TEST_mat_init
        from ordered_mat mat
        where row_num = 1;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #OBS_REASON ';


        IF
            OBJECT_ID('#OBS_REASON', 'U') IS NOT NULL
            drop table #OBS_REASON;

        select obs.lab_test_uid_test       as observation_uid,
               rsn.reason_desc_txt,
               rsn.reason_cd,
               cast(null as varchar(4000)) as REASON_FOR_TEST_DESC,
               cast(null as varchar(2000)) as REASON_FOR_TEST_CD
        into #OBS_REASON
        from #LAB_TESTinit_a obs
                 left join dbo.nrt_observation_reason rsn
                           on obs.lab_test_uid_test = rsn.observation_uid
        -- where rsn.observation_uid in (SELECT value FROM STRING_SPLIT(@obs_ids, ','));
        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #OBS_REASON;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #OBS_REASON_FINAL ';


        IF
            OBJECT_ID('#OBS_REASON_FINAL', 'U') IS NOT NULL
            drop table #OBS_REASON_FINAL;


        SELECT DISTINCT LRV.observation_uid,
                        SUBSTRING(
                                (SELECT '|' + coalesce(ST1.reason_cd + '(' + reason_desc_txt + ')', '') AS [text()]
                                 FROM #OBS_REASON ST1
                                 WHERE ST1.observation_uid = LRV.observation_uid
                                 ORDER BY ST1.observation_uid
                                 FOR XML PATH ('')), 2, 1000) REASON_FOR_TEST_DESC,
                        SUBSTRING(
                                (SELECT '|' + ST1.reason_cd AS [text()]
                                 FROM #OBS_REASON ST1
                                 WHERE ST1.observation_uid = LRV.observation_uid
                                 ORDER BY ST1.observation_uid
                                 FOR XML PATH ('')), 2, 1000) REASON_FOR_TEST_CD
        into #OBS_REASON_FINAL
        FROM #OBS_REASON LRV;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #OBS_REASON_FINAL;
        SELECT @RowCount_no = @@ROWCOUNT;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST_oth ';


        IF
            OBJECT_ID('#LAB_TEST_oth', 'U') IS NOT NULL
            drop table #LAB_TEST_oth;

        select obs.observation_uid                                    as LAB_TEST_uid_oth,
               lti.interpretation_cd                                  as interpretation_flg,
               lti.accession_number                                   as ACCESSION_NBR,
               (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(obs.REASON_FOR_TEST_DESC,
                                                                        '&#x09;', CHAR(9)),
                                                                '&#x0A;', CHAR(10)),
                                                        '&#x0D;', CHAR(13)),
                                                '&#x20;', CHAR(32)),
                                        '&amp;', CHAR(38)),
                                '&lt;', CHAR(60)),
                        '&gt;', CHAR(62)))                               REASON_FOR_TEST_DESC,
               obs.REASON_FOR_TEST_CD,
               rtrim(lti.transcriptionist_first_nm) + ' ' +
               rtrim(lti.transcriptionist_last_nm)                    as transcriptionist_name,
               lti.transcriptionist_id_assign_auth                    as transcriptionist_ass_auth_cd,
               lti.transcriptionist_auth_type                         as Transcriptionist_Ass_Auth_Type,
               lti.transcriptionist_val                               as transcriptionist_id,
               rtrim(lti.assistant_interpreter_first_nm) + ' ' +
               rtrim(lti.assistant_interpreter_last_nm)               as Assistant_Interpreter_Name,
               lti.assistant_interpreter_id_assign_auth               as Assistant_inter_ass_auth_cd,
               lti.assistant_interpreter_auth_type                    as Assistant_inter_ass_auth_type,
               lti.assistant_interpreter_val                          as Assistant_interpreter_id,
               rtrim(nprov.first_name) + ' ' + rtrim(nprov.last_name) as result_interpreter_name
        into #LAB_TEST_oth
        from #OBS_REASON_FINAL obs
                 left join #LAB_TESTinit_a lti
                           on obs.observation_uid = lti.LAB_TEST_uid_Test
                 left join dbo.nrt_provider as nprov on lti.result_interpreter_id = nprov.provider_uid;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #LAB_TEST_oth;
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_uid ';


        IF
            OBJECT_ID('#LAB_TEST1_uid', 'U') IS NOT NULL
            drop table #LAB_TEST1_uid;

        select LAB_TEST_uid_OTH AS LAB_TEST_uid
        into #LAB_TEST1_uid
        from #LAB_TEST_oth
        union
        select LAB_TEST_uid_mat
        from #LAB_TEST_mat_init
        union
        select LAB_TEST_uid_test
        from #LAB_TESTinit;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_TMP ';


        IF
            OBJECT_ID('#LAB_TEST1_TMP', 'U') IS NOT NULL
            drop table #LAB_TEST1_TMP;


        select lt1.LAB_TEST_uid,
               lto.LAB_TEST_uid_oth,
               lto.interpretation_flg,
               lto.ACCESSION_NBR,
               lto.REASON_FOR_TEST_DESC,
               lto.REASON_FOR_TEST_CD,
               lto.transcriptionist_name,
               lto.transcriptionist_ass_auth_cd,
               lto.Transcriptionist_Ass_Auth_Type,
               lto.transcriptionist_id,
               lto.Assistant_Interpreter_Name,
               lto.Assistant_inter_ass_auth_cd,
               lto.Assistant_inter_ass_auth_type,
               lto.Assistant_interpreter_id,
               lto.result_interpreter_name,
               ltmi.specimen_src,
               ltmi.specimen_nm,
               ltmi.Specimen_details,
               ltmi.Specimen_collection_vol,
               ltmi.Specimen_collection_vol_unit,
               ltmi.Specimen_desc,
               ltmi.Danger_cd,
               ltmi.Danger_cd_desc,
               lti.parent_test_pntr,
               lti.LAB_TEST_pntr,
               lti.LAB_TEST_dt,
               lti.test_method_cd,
               lti.root_ordered_test_pntr,
               lti.test_method_cd_desc,
               lti.priority_cd,
               lti.specimen_site,
               lti.SPECIMEN_SITE_desc,
               lti.Clinical_information,
               lti.LAB_TEST_Type,
               lti.LAB_TEST_cd,
               lti.LAB_TEST_cd_desc,
               lti.LAB_TEST_cd_sys_cd,
               lti.LAB_TEST_cd_sys_nm,
               lti.Alt_LAB_TEST_cd,
               lti.Alt_LAB_TEST_cd_desc,
               lti.Alt_LAB_TEST_cd_sys_cd,
               lti.Alt_LAB_TEST_cd_sys_nm,
               lti.specimen_collection_dt,
               lti.lab_rpt_local_id,
               lti.lab_rpt_share_ind,
               lti.oid,
               lti.record_status_cd,
               lti.record_status_cd_for_result,
               lti.lab_rpt_status,
               lti.LAB_RPT_CREATED_DT,
               lti.LAB_RPT_CREATED_BY,
               lti.LAB_RPT_RECEIVED_BY_PH_DT,
               lti.LAB_RPT_LAST_UPDATE_DT,
               lti.LAB_RPT_LAST_UPDATE_BY,
               lti.ELR_IND,
               lti.Jurisdiction_cd,
               lti.JURISDICTION_NM,
               lti.resulted_lab_report_date,
               lti.sus_lab_report_date,
               lti.report_observation_uid,
               lti.report_refr_uid,
               lti.report_sprt_uid,
               lti.followup_observation_uid,
               lti.accession_number,
               lti.morb_hosp_id,
               lti.transcriptionist_auth_type,
               lti.assistant_interpreter_auth_type,
               lti.morb_physician_id,
               lti.morb_reporter_id,
               lti.transcriptionist_val,
               lti.transcriptionist_first_nm,
               lti.transcriptionist_last_nm,
               lti.assistant_interpreter_val,
               lti.assistant_interpreter_first_nm,
               lti.assistant_interpreter_last_nm,
               lti.result_interpreter_id,
               lti.transcriptionist_id_assign_auth,
               lti.assistant_interpreter_id_assign_auth,
               lti.interpretation_cd,
               lti.condition_cd,
               lti.LAB_TEST_status,
               lti.processing_decision_cd,
               lti.document_link,
               lti.Lab_Rpt_Uid as Lab_Rpt_Uid_Test1
        into #LAB_TEST1_TMP
        from #LAB_TEST1_uid lt1
                 left outer join #LAB_TEST_oth lto on lt1.LAB_TEST_uid = lto.LAB_TEST_uid_oth
                 left outer join #LAB_TEST_mat_init ltmi on lt1.LAB_TEST_uid = ltmi.LAB_TEST_uid_mat
                 left outer join #LAB_TESTinit lti on lt1.LAB_TEST_uid = lti.LAB_TEST_uid_Test;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LabReportMorb ';


        IF
            OBJECT_ID('#LabReportMorb', 'U') IS NOT NULL
            drop table #LabReportMorb;


        select LAB_TEST_uid,
               LAB_TEST_uid_oth,
               Lab_Rpt_Uid_Test1,
               report_observation_uid
        into #LabReportMorb
        from #LAB_TEST1_TMP
        where LAB_TEST_type in ('Order', 'Result', 'Order_rslt')
          and oid = 4;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #Morb_OID ';


        IF
            OBJECT_ID('#Morb_OID', 'U') IS NOT NULL
            drop table #Morb_OID;

        select o.PROGRAM_JURISDICTION_OID as Morb_oid,
               l.Lab_Rpt_Uid_Test1        as Lab_Rpt_Uid_Mor,
               l.LAB_TEST_uid             as LAB_TEST_uid_mor,
               l.LAB_TEST_uid_oth         as LAB_TEST_uid_oth_mor
        into #Morb_OID
        from #LabReportMorb l,
             dbo.nrt_observation l_extension,
             dbo.nrt_observation o
        where l.Lab_Rpt_Uid_Test1 = l_extension.observation_uid
          and o.observation_uid = l_extension.report_observation_uid
          and o.CTRL_CD_DISPLAY_FORM = 'MorbReport';


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_uid2 ';


        IF
            OBJECT_ID('#LAB_TEST1_uid2', 'U') IS NOT NULL
            drop table #LAB_TEST1_uid2;

        select lab_rpt_uid_mor as lab_rpt_uid
        into #LAB_TEST1_uid2
        from #Morb_OID
        union
        select Lab_Rpt_Uid_Test1
        from #LAB_TEST1_TMP;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST1 ';


        IF
            OBJECT_ID('#LAB_TEST1', 'U') IS NOT NULL
            drop table #LAB_TEST1;

        select lt1.lab_rpt_uid,
               lto.LAB_TEST_uid,
               lto.LAB_TEST_uid_oth,
               lto.interpretation_flg,
               lto.ACCESSION_NBR,
               lto.REASON_FOR_TEST_DESC,
               lto.REASON_FOR_TEST_CD,
               lto.transcriptionist_name,
               lto.transcriptionist_ass_auth_cd,
               lto.Transcriptionist_Ass_Auth_Type,
               lto.transcriptionist_id,
               lto.Assistant_Interpreter_Name,
               lto.Assistant_inter_ass_auth_cd,
               lto.Assistant_inter_ass_auth_type,
               lto.Assistant_interpreter_id,
               lto.result_interpreter_name,
               lto.specimen_src,
               lto.specimen_nm,
               lto.Specimen_details,
               lto.Specimen_collection_vol,
               lto.Specimen_collection_vol_unit,
               lto.Specimen_desc,
               lto.Danger_cd,
               lto.Danger_cd_desc,
               lto.parent_test_pntr,
               lto.LAB_TEST_pntr,
               lto.LAB_TEST_dt,
               lto.test_method_cd,
               lto.root_ordered_test_pntr,
               lto.test_method_cd_desc,
               lto.priority_cd,
               lto.specimen_site,
               lto.SPECIMEN_SITE_desc,
               lto.Clinical_information,
               lto.LAB_TEST_Type,
               lto.LAB_TEST_cd,
               lto.LAB_TEST_cd_desc,
               lto.LAB_TEST_cd_sys_cd,
               lto.LAB_TEST_cd_sys_nm,
               lto.Alt_LAB_TEST_cd,
               lto.Alt_LAB_TEST_cd_desc,
               lto.Alt_LAB_TEST_cd_sys_cd,
               lto.Alt_LAB_TEST_cd_sys_nm,
               lto.specimen_collection_dt,
               lto.lab_rpt_local_id,
               lto.lab_rpt_share_ind,
               CASE
                   WHEN rtrim(tmo.morb_oid) IS NOT NULL THEN tmo.morb_oid
                   ELSE lto.oid
                   END AS oid,
               lto.record_status_cd,
               lto.record_status_cd_for_result,
               lto.lab_rpt_status,
               lto.LAB_RPT_CREATED_DT,
               lto.LAB_RPT_CREATED_BY,
               lto.LAB_RPT_RECEIVED_BY_PH_DT,
               lto.LAB_RPT_LAST_UPDATE_DT,
               lto.LAB_RPT_LAST_UPDATE_BY,
               lto.ELR_IND,
               lto.Jurisdiction_cd,
               lto.JURISDICTION_NM,
               lto.resulted_lab_report_date,
               lto.sus_lab_report_date,
               lto.report_observation_uid,
               lto.report_refr_uid,
               lto.report_sprt_uid,
               lto.followup_observation_uid,
               lto.accession_number,
               lto.morb_hosp_id,
               lto.transcriptionist_auth_type,
               lto.assistant_interpreter_auth_type,
               lto.morb_physician_id,
               lto.morb_reporter_id,
               lto.transcriptionist_val,
               lto.transcriptionist_first_nm,
               lto.transcriptionist_last_nm,
               lto.assistant_interpreter_val,
               lto.assistant_interpreter_first_nm,
               lto.assistant_interpreter_last_nm,
               lto.result_interpreter_id,
               lto.transcriptionist_id_assign_auth,
               lto.assistant_interpreter_id_assign_auth,
               lto.interpretation_cd,
               lto.condition_cd,
               lto.LAB_TEST_status,
               lto.processing_decision_cd,
               lto.document_link,
               lto.Lab_Rpt_Uid_Test1,
               tmo.Morb_oid,
               CASE
                   WHEN cvg.code_short_desc_txt IS NULL AND lto.processing_decision_cd IS NOT NULL
                       THEN lto.processing_decision_cd
                   ELSE cvg.code_short_desc_txt
                   END as PROCESSING_DECISION_DESC
        into #LAB_TEST1
        from #LAB_TEST1_uid2 lt1
                 left outer join #LAB_TEST1_TMP lto on lt1.lab_rpt_uid = lto.Lab_Rpt_Uid_Test1
                 left outer join #Morb_OID tmo on lt1.lab_rpt_uid = tmo.lab_rpt_uid_mor
                 left join nbs_srte..Code_value_general cvg
                           on lto.processing_decision_cd = cvg.code
                               and lto.processing_decision_cd is not null
                               and cvg.code_set_nm = 'STD_NBS_PROCESSING_DECISION_ALL';

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #R_Result_to_R_Order ';


        -- verified same as classic process join with act_uid
        IF
            OBJECT_ID('#R_Result_to_R_Order', 'U') IS NOT NULL
            drop table #R_Result_to_R_Order;


        -- create table R_Result_to_R_Order as
-- is source the lab_test_uid
        select tst.LAB_TEST_uid           'LAB_TEST_uid',    --as LAB_TEST_uid label='R_Result_uid',

               tst.report_observation_uid 'parent_test_pntr' -- is target going to be our report_observation_id
        into #R_Result_to_R_Order
        from #LAB_TEST1 as tst
        where tst.LAB_TEST_type IN ('R_Result', 'I_Result');


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #R_Result_to_R_Order_to_Order ';


        -- this step gets the parent to R_Order records
        -- the highest level parent for R_Order is an Order, and that is the root record
        IF
            OBJECT_ID('#R_Result_to_R_Order_to_Order', 'U') IS NOT NULL
            drop table #R_Result_to_R_Order_to_Order;


-- create table R_Result_to_R_Order_to_Order as
        select tst.LAB_TEST_UID,
               tst.parent_test_pntr,
               coalesce(tst2.record_status_cd, tst3.record_status_cd, tst4.record_status_cd)
                                           as record_status_cd_for_result_drug,
               parent_test.report_sprt_uid as root_thru_srpt,
               parent_test.report_refr_uid as root_thru_refr,
               coalesce(parent_test.report_sprt_uid, parent_test.report_observation_uid)
                                           as root_ordered_test_pntr
        into #R_Result_to_R_Order_to_Order
        from #R_Result_to_R_Order as tst
                 left join dbo.nrt_observation as parent_test
                           on parent_test.observation_uid = tst.parent_test_pntr
                 left join dbo.nrt_observation as tst2
                           on parent_test.report_sprt_uid = tst2.observation_uid
                 left join dbo.nrt_observation as tst3
                           on parent_test.report_refr_uid = tst3.observation_uid
                 left join dbo.nrt_observation as tst4
                           on parent_test.report_observation_uid = tst4.observation_uid;

        if @debug = 'true'
            select 'r_result_to_r_order_to_order' as nm, *
            from #R_Result_to_R_Order_to_Order;
        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_testuid ';


        IF
            OBJECT_ID('#LAB_TEST1_testuid', 'U') IS NOT NULL
            drop table #LAB_TEST1_testuid;


        select lt1.LAB_TEST_uid
        into #LAB_TEST1_testuid
        from #LAB_TEST1 lt1
        union
        select rrr.LAB_TEST_uid
        from #R_Result_to_R_Order_to_Order rrr;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_final ';


        IF
            OBJECT_ID('#LAB_TEST1_final', 'U') IS NOT NULL
            drop table #LAB_TEST1_final;

        select dimc.LAB_TEST_uid                                                 as LAB_TEST_uid_final,
               tlt1.lab_rpt_uid,
               tlt1.LAB_TEST_uid,
               tlt1.LAB_TEST_uid_oth,
               tlt1.interpretation_flg,
               tlt1.ACCESSION_NBR,
               tlt1.REASON_FOR_TEST_DESC,
               tlt1.REASON_FOR_TEST_CD,
               tlt1.transcriptionist_name,
               tlt1.transcriptionist_ass_auth_cd,
               tlt1.Transcriptionist_Ass_Auth_Type,
               tlt1.transcriptionist_id,
               tlt1.Assistant_Interpreter_Name,
               tlt1.Assistant_inter_ass_auth_cd,
               tlt1.Assistant_inter_ass_auth_type,
               tlt1.Assistant_interpreter_id,
               tlt1.result_interpreter_name,
               tlt1.specimen_src,
               tlt1.specimen_nm,
               tlt1.Specimen_details,
               tlt1.Specimen_collection_vol,
               tlt1.Specimen_collection_vol_unit,
               tlt1.Specimen_desc,
               tlt1.Danger_cd,
               tlt1.Danger_cd_desc,
               coalesce(trr.parent_test_pntr, tlt1.parent_test_pntr)             as parent_test_pntr,
               tlt1.LAB_TEST_pntr,
               tlt1.LAB_TEST_dt,
               tlt1.test_method_cd,
               coalesce(trr.root_ordered_test_pntr, tlt1.root_ordered_test_pntr) as root_ordered_test_pntr,
               tlt1.test_method_cd_desc,
               tlt1.priority_cd,
               tlt1.specimen_site,
               tlt1.SPECIMEN_SITE_desc,
               tlt1.Clinical_information,
               tlt1.LAB_TEST_Type,
               tlt1.LAB_TEST_cd,
               tlt1.LAB_TEST_cd_desc,
               tlt1.LAB_TEST_cd_sys_cd,
               tlt1.LAB_TEST_cd_sys_nm,
               tlt1.Alt_LAB_TEST_cd,
               tlt1.Alt_LAB_TEST_cd_desc,
               tlt1.Alt_LAB_TEST_cd_sys_cd,
               tlt1.Alt_LAB_TEST_cd_sys_nm,
               tlt1.specimen_collection_dt,
               tlt1.lab_rpt_local_id,
               tlt1.lab_rpt_share_ind,
               tlt1.oid,
               tlt1.record_status_cd,
               tlt1.record_status_cd_for_result,
               tlt1.lab_rpt_status,
               tlt1.LAB_RPT_CREATED_DT,
               tlt1.LAB_RPT_CREATED_BY,
               tlt1.LAB_RPT_RECEIVED_BY_PH_DT,
               tlt1.LAB_RPT_LAST_UPDATE_DT,
               tlt1.LAB_RPT_LAST_UPDATE_BY,
               tlt1.ELR_IND,
               tlt1.Jurisdiction_cd,
               tlt1.JURISDICTION_NM,
               tlt1.resulted_lab_report_date,
               tlt1.sus_lab_report_date,
               tlt1.report_observation_uid,
               tlt1.report_refr_uid,
               tlt1.report_sprt_uid,
               tlt1.followup_observation_uid,
               tlt1.accession_number,
               tlt1.morb_hosp_id,
               tlt1.transcriptionist_auth_type,
               tlt1.assistant_interpreter_auth_type,
               tlt1.morb_physician_id,
               tlt1.morb_reporter_id,
               tlt1.transcriptionist_val,
               tlt1.transcriptionist_first_nm,
               tlt1.transcriptionist_last_nm,
               tlt1.assistant_interpreter_val,
               tlt1.assistant_interpreter_first_nm,
               tlt1.assistant_interpreter_last_nm,
               tlt1.result_interpreter_id,
               tlt1.transcriptionist_id_assign_auth,
               tlt1.assistant_interpreter_id_assign_auth,
               tlt1.interpretation_cd,
               tlt1.condition_cd,
               tlt1.LAB_TEST_status,
               tlt1.processing_decision_cd,
               tlt1.document_link,
               tlt1.Lab_Rpt_Uid_Test1,
               tlt1.Morb_oid,
               tlt1.PROCESSING_DECISION_DESC,
               trr.[record_status_cd_for_result_drug],
               trr.[root_thru_srpt],
               trr.[root_thru_refr]
        into #LAB_TEST1_final
        from #LAB_TEST1_testuid DIMC
                 LEFT OUTER JOIN #LAB_TEST1 tlt1 ON tlt1.LAB_TEST_uid = dimc.LAB_TEST_uid
                 LEFT OUTER JOIN #R_Result_to_R_Order_to_Order trr ON trr.LAB_TEST_uid = dimc.LAB_TEST_uid;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #R_Order_to_Result ';


        IF
            OBJECT_ID('#R_Order_to_Result', 'U') IS NOT NULL
            drop table #R_Order_to_Result;

        select tst.LAB_TEST_uid      as LAB_TEST_uid,
               tst.report_refr_uid   as parent_test_pntr,
               tst2.observation_uid  as root_ordered_test_pntr,
               tst2.record_status_cd as record_status_cd
        into #R_Order_to_Result
        from #LAB_TEST1_final as tst
                 LEFT JOIN dbo.nrt_observation obs2
                           ON tst.report_refr_uid = obs2.observation_uid
                 LEFT JOIN dbo.nrt_observation tst2
                           ON obs2.report_observation_uid = tst2.observation_uid
        where tst.LAB_TEST_type IN ('R_Order', 'I_Order');


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_final_testuid ';


        IF
            OBJECT_ID('#LAB_TEST1_final_testuid', 'U') IS NOT NULL
            drop table #LAB_TEST1_final_testuid;


        select lt1.LAB_TEST_uid
        into #LAB_TEST1_final_testuid
        from #LAB_TEST1_final lt1
        union
        select rrr.LAB_TEST_uid
        from #R_Order_to_Result rrr;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_final_result ';


        IF
            OBJECT_ID('#LAB_TEST1_final_result', 'U') IS NOT NULL
            drop table #LAB_TEST1_final_result;


        select dimc.LAB_TEST_uid                                                 as LAB_TEST_uid_final_result,
               tlt1.LAB_TEST_uid_final,
               tlt1.lab_rpt_uid,
               tlt1.LAB_TEST_uid,
               tlt1.LAB_TEST_uid_oth,
               tlt1.interpretation_flg,
               tlt1.ACCESSION_NBR,
               tlt1.REASON_FOR_TEST_DESC,
               tlt1.REASON_FOR_TEST_CD,
               tlt1.transcriptionist_name,
               tlt1.transcriptionist_ass_auth_cd,
               tlt1.Transcriptionist_Ass_Auth_Type,
               tlt1.transcriptionist_id,
               tlt1.Assistant_Interpreter_Name,
               tlt1.Assistant_inter_ass_auth_cd,
               tlt1.Assistant_inter_ass_auth_type,
               tlt1.Assistant_interpreter_id,
               tlt1.result_interpreter_name,
               tlt1.specimen_src,
               tlt1.specimen_nm,
               tlt1.Specimen_details,
               tlt1.Specimen_collection_vol,
               tlt1.Specimen_collection_vol_unit,
               tlt1.Specimen_desc,
               tlt1.Danger_cd,
               tlt1.Danger_cd_desc,
               coalesce(trr.parent_test_pntr, tlt1.parent_test_pntr)             as parent_test_pntr,
               tlt1.LAB_TEST_pntr,
               tlt1.LAB_TEST_dt,
               tlt1.test_method_cd,
               coalesce(trr.root_ordered_test_pntr, tlt1.root_ordered_test_pntr) as root_ordered_test_pntr,
               tlt1.test_method_cd_desc,
               tlt1.priority_cd,
               tlt1.specimen_site,
               tlt1.SPECIMEN_SITE_desc,
               tlt1.Clinical_information,
               tlt1.LAB_TEST_Type,
               tlt1.LAB_TEST_cd,
               tlt1.LAB_TEST_cd_desc,
               tlt1.LAB_TEST_cd_sys_cd,
               tlt1.LAB_TEST_cd_sys_nm,
               tlt1.Alt_LAB_TEST_cd,
               tlt1.Alt_LAB_TEST_cd_desc,
               tlt1.Alt_LAB_TEST_cd_sys_cd,
               tlt1.Alt_LAB_TEST_cd_sys_nm,
               tlt1.specimen_collection_dt,
               tlt1.lab_rpt_local_id,
               tlt1.lab_rpt_share_ind,
               tlt1.oid,
               coalesce(trr.[record_status_cd], tlt1.[record_status_cd])         as record_status_cd,
               tlt1.record_status_cd_for_result,
               tlt1.lab_rpt_status,
               tlt1.LAB_RPT_CREATED_DT,
               tlt1.LAB_RPT_CREATED_BY,
               tlt1.LAB_RPT_RECEIVED_BY_PH_DT,
               tlt1.LAB_RPT_LAST_UPDATE_DT,
               tlt1.LAB_RPT_LAST_UPDATE_BY,
               tlt1.ELR_IND,
               tlt1.Jurisdiction_cd,
               tlt1.JURISDICTION_NM,
               tlt1.resulted_lab_report_date,
               tlt1.sus_lab_report_date,
               tlt1.report_observation_uid,
               tlt1.report_refr_uid,
               tlt1.report_sprt_uid,
               tlt1.followup_observation_uid,
               tlt1.accession_number,
               tlt1.morb_hosp_id,
               tlt1.transcriptionist_auth_type,
               tlt1.assistant_interpreter_auth_type,
               tlt1.morb_physician_id,
               tlt1.morb_reporter_id,
               tlt1.transcriptionist_val,
               tlt1.transcriptionist_first_nm,
               tlt1.transcriptionist_last_nm,
               tlt1.assistant_interpreter_val,
               tlt1.assistant_interpreter_first_nm,
               tlt1.assistant_interpreter_last_nm,
               tlt1.result_interpreter_id,
               tlt1.transcriptionist_id_assign_auth,
               tlt1.assistant_interpreter_id_assign_auth,
               tlt1.interpretation_cd,
               tlt1.condition_cd,
               tlt1.LAB_TEST_status,
               tlt1.processing_decision_cd,
               tlt1.document_link,
               tlt1.Lab_Rpt_Uid_Test1,
               tlt1.Morb_oid,
               tlt1.PROCESSING_DECISION_DESC,
               tlt1.[record_status_cd_for_result_drug],
               tlt1.[root_thru_srpt],
               tlt1.[root_thru_refr]
        into #LAB_TEST1_final_result
        from #LAB_TEST1_final_testuid DIMC
                 LEFT OUTER JOIN #LAB_TEST1_final tlt1 ON tlt1.LAB_TEST_uid = dimc.LAB_TEST_uid
                 LEFT OUTER JOIN #R_Order_to_Result trr ON trr.LAB_TEST_uid = dimc.LAB_TEST_uid;

-- create table Result_to_Order as


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #Result_to_Order ';


        -- gets the order (parent, also happens to be the root parents) for a record with type 'Result'
        IF
            OBJECT_ID('#Result_to_Order', 'U') IS NOT NULL
            drop table #Result_to_Order;

        select tst.LAB_TEST_uid           as LAB_TEST_uid,
               tst.report_observation_uid as parent_test_pntr,
               tst.report_observation_uid as root_ordered_test_pntr,
               tst2.record_status_cd      as record_status_cd
        into #Result_to_Order
        from #LAB_TEST1_final_result as tst,
             dbo.nrt_observation as tst2
        where tst.LAB_TEST_type in ('Result', 'Order_rslt')
          and tst2.observation_uid = tst.report_observation_uid
          and tst.lab_test_uid != tst.report_observation_uid;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_final_orderuid ';


        IF
            OBJECT_ID('#LAB_TEST1_final_orderuid', 'U') IS NOT NULL
            drop table #LAB_TEST1_final_orderuid;


        select lt1.LAB_TEST_uid
        into #LAB_TEST1_final_orderuid
        from #LAB_TEST1_final_result lt1
        union
        select rrr.LAB_TEST_uid
        from #Result_to_Order rrr;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING TMP_LAB_TEST1_final_order ';


        IF
            OBJECT_ID('#LAB_TEST1_final_order', 'U') IS NOT NULL
            drop table r#LAB_TEST1_final_order;

        select distinct dimc.LAB_TEST_uid                                         as LAB_TEST_uid_final_order,
                        tlt1.LAB_TEST_uid_final_result,
                        tlt1.LAB_TEST_uid_final,
                        tlt1.lab_rpt_uid,
                        tlt1.LAB_TEST_uid,
                        tlt1.LAB_TEST_uid_oth,
                        tlt1.interpretation_flg,
                        tlt1.ACCESSION_NBR,
                        tlt1.REASON_FOR_TEST_DESC,
                        tlt1.REASON_FOR_TEST_CD,
                        tlt1.transcriptionist_name,
                        tlt1.transcriptionist_ass_auth_cd,
                        tlt1.Transcriptionist_Ass_Auth_Type,
                        tlt1.transcriptionist_id,
                        tlt1.Assistant_Interpreter_Name,
                        tlt1.Assistant_inter_ass_auth_cd,
                        tlt1.Assistant_inter_ass_auth_type,
                        tlt1.Assistant_interpreter_id,
                        tlt1.result_interpreter_name,
                        tlt1.specimen_src,
                        tlt1.specimen_nm,
                        tlt1.Specimen_details,
                        tlt1.Specimen_collection_vol,
                        tlt1.Specimen_collection_vol_unit,
                        tlt1.Specimen_desc,
                        tlt1.Danger_cd,
                        tlt1.Danger_cd_desc,
                        CASE
                            WHEN LAB_TEST_TYPE = 'Order' THEN LAB_TEST_pntr
                            ELSE coalesce(trr.parent_test_pntr, tlt1.parent_test_pntr)
                            end                                                   as parent_test_pntr,
                        tlt1.LAB_TEST_pntr,
                        tlt1.LAB_TEST_dt,
                        tlt1.test_method_cd,
                        CASE
                            WHEN LAB_TEST_TYPE = 'Order' THEN LAB_TEST_pntr
                            else coalesce(trr.root_ordered_test_pntr, tlt1.root_ordered_test_pntr)
                            end                                                   as root_ordered_test_pntr,
                        tlt1.test_method_cd_desc,
                        tlt1.priority_cd,
                        tlt1.specimen_site,
                        tlt1.SPECIMEN_SITE_desc,
                        tlt1.Clinical_information,
                        tlt1.LAB_TEST_Type,
                        tlt1.LAB_TEST_cd,
                        tlt1.LAB_TEST_cd_desc,
                        tlt1.LAB_TEST_cd_sys_cd,
                        tlt1.LAB_TEST_cd_sys_nm,
                        tlt1.Alt_LAB_TEST_cd,
                        tlt1.Alt_LAB_TEST_cd_desc,
                        tlt1.Alt_LAB_TEST_cd_sys_cd,
                        tlt1.Alt_LAB_TEST_cd_sys_nm,
                        tlt1.specimen_collection_dt,
                        tlt1.lab_rpt_local_id,
                        tlt1.lab_rpt_share_ind,
                        tlt1.oid,
                        coalesce(trr.[record_status_cd], tlt1.[record_status_cd]) as record_status_cd,
                        tlt1.record_status_cd_for_result,
                        tlt1.lab_rpt_status,
                        tlt1.LAB_RPT_CREATED_DT,
                        tlt1.LAB_RPT_CREATED_BY,
                        tlt1.LAB_RPT_RECEIVED_BY_PH_DT,
                        tlt1.LAB_RPT_LAST_UPDATE_DT,
                        tlt1.LAB_RPT_LAST_UPDATE_BY,
                        tlt1.ELR_IND,
                        tlt1.Jurisdiction_cd,
                        tlt1.JURISDICTION_NM,
                        tlt1.resulted_lab_report_date,
                        tlt1.sus_lab_report_date,
                        tlt1.report_observation_uid,
                        tlt1.report_refr_uid,
                        tlt1.report_sprt_uid,
                        tlt1.followup_observation_uid,
                        tlt1.accession_number,
                        tlt1.morb_hosp_id,
                        tlt1.transcriptionist_auth_type,
                        tlt1.assistant_interpreter_auth_type,
                        tlt1.morb_physician_id,
                        tlt1.morb_reporter_id,
                        tlt1.transcriptionist_val,
                        tlt1.transcriptionist_first_nm,
                        tlt1.transcriptionist_last_nm,
                        tlt1.assistant_interpreter_val,
                        tlt1.assistant_interpreter_first_nm,
                        tlt1.assistant_interpreter_last_nm,
                        tlt1.result_interpreter_id,
                        tlt1.transcriptionist_id_assign_auth,
                        tlt1.assistant_interpreter_id_assign_auth,
                        tlt1.interpretation_cd,
                        tlt1.condition_cd,
                        tlt1.LAB_TEST_status,
                        tlt1.processing_decision_cd,
                        tlt1.document_link,
                        tlt1.Lab_Rpt_Uid_Test1,
                        tlt1.Morb_oid,
                        tlt1.PROCESSING_DECISION_DESC,
                        tlt1.[record_status_cd_for_result_drug],
                        tlt1.[root_thru_srpt],
                        tlt1.[root_thru_refr]
        into #LAB_TEST1_final_order
        from #LAB_TEST1_final_orderuid DIMC
                 LEFT OUTER JOIN #LAB_TEST1_final_result tlt1 ON tlt1.LAB_TEST_uid = dimc.LAB_TEST_uid
                 LEFT OUTER JOIN #Result_to_Order trr ON trr.LAB_TEST_uid = dimc.LAB_TEST_uid;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST2 ';


        IF
            OBJECT_ID('#LAB_TEST2', 'U') IS NOT NULL
            drop table #LAB_TEST2;


        select tst.LAB_TEST_uid_final_order,
               tst.LAB_TEST_uid_final_result,
               tst.LAB_TEST_uid_final,
               tst.lab_rpt_uid,
               tst.LAB_TEST_uid,
               tst.LAB_TEST_uid_oth,
               tst.interpretation_flg,
               tst.ACCESSION_NBR,
               tst.REASON_FOR_TEST_DESC,
               tst.REASON_FOR_TEST_CD,
               tst.transcriptionist_name,
               tst.transcriptionist_ass_auth_cd,
               tst.Transcriptionist_Ass_Auth_Type,
               tst.transcriptionist_id,
               tst.Assistant_Interpreter_Name,
               tst.Assistant_inter_ass_auth_cd,
               tst.Assistant_inter_ass_auth_type,
               tst.Assistant_interpreter_id,
               tst.result_interpreter_name,
               tst.specimen_src,
               tst.specimen_nm,
               tst.Specimen_details,
               tst.Specimen_collection_vol,
               tst.Specimen_collection_vol_unit,
               tst.Specimen_desc,
               tst.Danger_cd,
               tst.Danger_cd_desc,
               tst.parent_test_pntr,
               tst.LAB_TEST_pntr,
               tst.LAB_TEST_dt,
               tst.test_method_cd,
               tst.root_ordered_test_pntr,
               tst.test_method_cd_desc,
               tst.priority_cd,
               tst.specimen_site,
               tst.SPECIMEN_SITE_desc,
               tst.Clinical_information,
               tst.LAB_TEST_Type,
               tst.LAB_TEST_cd,
               tst.LAB_TEST_cd_desc,
               tst.LAB_TEST_cd_sys_cd,
               tst.LAB_TEST_cd_sys_nm,
               tst.Alt_LAB_TEST_cd,
               tst.Alt_LAB_TEST_cd_desc,
               tst.Alt_LAB_TEST_cd_sys_cd,
               tst.Alt_LAB_TEST_cd_sys_nm,
               tst.specimen_collection_dt,
               tst.lab_rpt_local_id,
               tst.lab_rpt_share_ind,
               tst.oid,
               tst.record_status_cd,
               tst.record_status_cd_for_result,
               tst.lab_rpt_status,
               tst.LAB_RPT_CREATED_DT,
               tst.LAB_RPT_CREATED_BY,
               tst.LAB_RPT_RECEIVED_BY_PH_DT,
               tst.LAB_RPT_LAST_UPDATE_DT,
               tst.LAB_RPT_LAST_UPDATE_BY,
               tst.ELR_IND,
               tst.Jurisdiction_cd,
               tst.JURISDICTION_NM,
               tst.resulted_lab_report_date,
               tst.sus_lab_report_date,
               tst.report_observation_uid,
               tst.report_refr_uid,
               tst.report_sprt_uid,
               tst.followup_observation_uid,
               tst.accession_number,
               tst.morb_hosp_id,
               tst.transcriptionist_auth_type,
               tst.assistant_interpreter_auth_type,
               tst.morb_physician_id,
               tst.morb_reporter_id,
               tst.transcriptionist_val,
               tst.transcriptionist_first_nm,
               tst.transcriptionist_last_nm,
               tst.assistant_interpreter_val,
               tst.assistant_interpreter_first_nm,
               tst.assistant_interpreter_last_nm,
               tst.result_interpreter_id,
               tst.transcriptionist_id_assign_auth,
               tst.assistant_interpreter_id_assign_auth,
               tst.interpretation_cd,
               tst.condition_cd,
               tst.LAB_TEST_status,
               tst.processing_decision_cd,
               tst.document_link,
               tst.Lab_Rpt_Uid_Test1,
               tst.Morb_oid,
               tst.PROCESSING_DECISION_DESC,
               tst.record_status_cd_for_result_drug,
               tst.root_thru_srpt,
               tst.root_thru_refr,
               obs.cd_desc_txt 'Root_Ordered_Test_Nm'
        into #LAB_TEST2
        from #LAB_TEST1_final_order as tst
                 left outer join dbo.nrt_observation as obs on tst.root_ordered_test_pntr = obs.observation_uid;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING TMP_LAB_TEST3 ';


        IF
            OBJECT_ID('#LAB_TEST3', 'U') IS NOT NULL
            drop table #LAB_TEST3;

        select tst.LAB_TEST_uid_final_order,
               tst.LAB_TEST_uid_final_result,
               tst.LAB_TEST_uid_final,
               tst.lab_rpt_uid,
               tst.LAB_TEST_uid,
               tst.LAB_TEST_uid_oth,
               tst.interpretation_flg,
               tst.ACCESSION_NBR,
               tst.REASON_FOR_TEST_DESC,
               tst.REASON_FOR_TEST_CD,
               tst.transcriptionist_name,
               tst.transcriptionist_ass_auth_cd,
               tst.Transcriptionist_Ass_Auth_Type,
               tst.transcriptionist_id,
               tst.Assistant_Interpreter_Name,
               tst.Assistant_inter_ass_auth_cd,
               tst.Assistant_inter_ass_auth_type,
               tst.Assistant_interpreter_id,
               tst.result_interpreter_name,
               tst.specimen_src,
               tst.specimen_nm,
               tst.Specimen_details,
               tst.Specimen_collection_vol,
               tst.Specimen_collection_vol_unit,
               tst.Specimen_desc,
               tst.Danger_cd,
               tst.Danger_cd_desc,
               tst.parent_test_pntr,
               tst.LAB_TEST_pntr,
               tst.LAB_TEST_dt,
               tst.test_method_cd,
               tst.root_ordered_test_pntr,
               tst.test_method_cd_desc,
               tst.priority_cd,
               tst.specimen_site,
               tst.SPECIMEN_SITE_desc,
               tst.Clinical_information,
               tst.LAB_TEST_Type,
               tst.LAB_TEST_cd,
               tst.LAB_TEST_cd_desc,
               tst.LAB_TEST_cd_sys_cd,
               tst.LAB_TEST_cd_sys_nm,
               tst.Alt_LAB_TEST_cd,
               tst.Alt_LAB_TEST_cd_desc,
               tst.Alt_LAB_TEST_cd_sys_cd,
               tst.Alt_LAB_TEST_cd_sys_nm,
               tst.specimen_collection_dt,
               tst.lab_rpt_local_id,
               tst.lab_rpt_share_ind,
               tst.oid,
               tst.record_status_cd,
               tst.record_status_cd_for_result,
               tst.lab_rpt_status,
               tst.LAB_RPT_CREATED_DT,
               tst.LAB_RPT_CREATED_BY,
               tst.LAB_RPT_RECEIVED_BY_PH_DT,
               tst.LAB_RPT_LAST_UPDATE_DT,
               tst.LAB_RPT_LAST_UPDATE_BY,
               tst.ELR_IND,
               tst.Jurisdiction_cd,
               tst.JURISDICTION_NM,
               tst.resulted_lab_report_date,
               tst.sus_lab_report_date,
               tst.report_observation_uid,
               tst.report_refr_uid,
               tst.report_sprt_uid,
               tst.followup_observation_uid,
               tst.accession_number,
               tst.morb_hosp_id,
               tst.transcriptionist_auth_type,
               tst.assistant_interpreter_auth_type,
               tst.morb_physician_id,
               tst.morb_reporter_id,
               tst.transcriptionist_val,
               tst.transcriptionist_first_nm,
               tst.transcriptionist_last_nm,
               tst.assistant_interpreter_val,
               tst.assistant_interpreter_first_nm,
               tst.assistant_interpreter_last_nm,
               tst.result_interpreter_id,
               tst.transcriptionist_id_assign_auth,
               tst.assistant_interpreter_id_assign_auth,
               tst.interpretation_cd,
               tst.condition_cd,
               tst.LAB_TEST_status,
               tst.processing_decision_cd,
               tst.document_link,
               tst.Lab_Rpt_Uid_Test1,
               tst.Morb_oid,
               tst.PROCESSING_DECISION_DESC,
               tst.record_status_cd_for_result_drug,
               tst.root_thru_srpt,
               tst.root_thru_refr,
               tst.Root_Ordered_Test_Nm,
               obs.cd_desc_txt 'Parent_Test_Nm'
        into #LAB_TEST3
        from #LAB_TEST2 as tst
                 left outer join dbo.nrt_observation as obs on tst.parent_test_pntr = obs.observation_uid;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST4 ';


        IF
            OBJECT_ID('#LAB_TEST4', 'U') IS NOT NULL
            drop table #LAB_TEST4;


        select tst.LAB_TEST_uid_final_order,
               tst.LAB_TEST_uid_final_result,
               tst.LAB_TEST_uid_final,
               tst.lab_rpt_uid,
               tst.LAB_TEST_uid,
               tst.LAB_TEST_uid_oth,
               tst.interpretation_flg,
               tst.ACCESSION_NBR,
               tst.REASON_FOR_TEST_DESC,
               tst.REASON_FOR_TEST_CD,
               tst.transcriptionist_name,
               tst.transcriptionist_ass_auth_cd,
               tst.Transcriptionist_Ass_Auth_Type,
               tst.transcriptionist_id,
               tst.Assistant_Interpreter_Name,
               tst.Assistant_inter_ass_auth_cd,
               tst.Assistant_inter_ass_auth_type,
               tst.Assistant_interpreter_id,
               tst.result_interpreter_name,
               tst.specimen_src,
               tst.specimen_nm,
               tst.Specimen_details,
               tst.Specimen_collection_vol,
               tst.Specimen_collection_vol_unit,
               tst.Specimen_desc,
               tst.Danger_cd,
               tst.Danger_cd_desc,
               tst.parent_test_pntr,
               tst.LAB_TEST_pntr,
               tst.LAB_TEST_dt,
               tst.test_method_cd,
               tst.root_ordered_test_pntr,
               tst.test_method_cd_desc,
               tst.priority_cd,
               tst.specimen_site,
               tst.SPECIMEN_SITE_desc,
               tst.Clinical_information,
               tst.LAB_TEST_Type,
               tst.LAB_TEST_cd,
               tst.LAB_TEST_cd_desc,
               tst.LAB_TEST_cd_sys_cd,
               tst.LAB_TEST_cd_sys_nm,
               tst.Alt_LAB_TEST_cd,
               tst.Alt_LAB_TEST_cd_desc,
               tst.Alt_LAB_TEST_cd_sys_cd,
               tst.Alt_LAB_TEST_cd_sys_nm,
               tst.specimen_collection_dt,
               tst.lab_rpt_local_id,
               tst.lab_rpt_share_ind,
               tst.oid,
               case
                   when tst.record_status_cd = '' then tst.record_status_cd_for_result_drug
                   else tst.record_status_cd
                   end            as record_status_cd,
               tst.record_status_cd_for_result,
               tst.lab_rpt_status,
               tst.LAB_RPT_CREATED_DT,
               tst.LAB_RPT_CREATED_BY,
               tst.LAB_RPT_RECEIVED_BY_PH_DT,
               tst.LAB_RPT_LAST_UPDATE_DT,
               tst.LAB_RPT_LAST_UPDATE_BY,
               tst.ELR_IND,
               tst.Jurisdiction_cd,
               tst.JURISDICTION_NM,
               tst.resulted_lab_report_date,
               tst.sus_lab_report_date,
               tst.report_observation_uid,
               tst.report_refr_uid,
               tst.report_sprt_uid,
               tst.followup_observation_uid,
               tst.accession_number,
               tst.morb_hosp_id,
               tst.transcriptionist_auth_type,
               tst.assistant_interpreter_auth_type,
               tst.morb_physician_id,
               tst.morb_reporter_id,
               tst.transcriptionist_val,
               tst.transcriptionist_first_nm,
               tst.transcriptionist_last_nm,
               tst.assistant_interpreter_val,
               tst.assistant_interpreter_first_nm,
               tst.assistant_interpreter_last_nm,
               tst.result_interpreter_id,
               tst.transcriptionist_id_assign_auth,
               tst.assistant_interpreter_id_assign_auth,
               tst.interpretation_cd,
               tst.condition_cd,
               tst.LAB_TEST_status,
               tst.processing_decision_cd,
               tst.document_link,
               tst.Lab_Rpt_Uid_Test1,
               tst.Morb_oid,
               tst.PROCESSING_DECISION_DESC,
               tst.record_status_cd_for_result_drug,
               tst.root_thru_srpt,
               tst.root_thru_refr,
               tst.Root_Ordered_Test_Nm,
               tst.Parent_Test_Nm,
               obs.add_time       as SPECIMEN_ADD_TIME,
               obs1.last_chg_time as SPECIMEN_LAST_CHANGE_TIME
        into #LAB_TEST4
        from #LAB_TEST3 as tst
                 left join dbo.nrt_observation as obs on tst.LAB_TEST_uid = obs.observation_uid
            and obs.obs_domain_cd_st_1 = 'Order'
                 left join dbo.nrt_observation as obs1 on tst.LAB_TEST_uid = obs1.observation_uid
            and obs1.obs_domain_cd_st_1 = 'Order';


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING TMP_order_test ';


        IF
            OBJECT_ID('#order_test', 'U') IS NOT NULL
            drop table #order_test;


        select oid,
               root_ordered_test_pntr
        into #order_test
        from #LAB_TEST4
        where LAB_TEST_Type = 'Order'
          and oid <> 4;

        alter table #LAB_TEST4
            drop column oid;


/*note: When the OID is null that means this lab report is needing assignment of jurisdiction*/


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING TMP_LAB_TEST ';


        IF
            OBJECT_ID('#LAB_TEST', 'U') IS NOT NULL
            drop table #LAB_TEST;


        select distinct lab.LAB_TEST_uid_final_order,
                        lab.LAB_TEST_uid_final_result,
                        lab.LAB_TEST_uid_final,
                        lab.lab_rpt_uid,
                        lab.LAB_TEST_uid,
                        lab.LAB_TEST_uid_oth,
                        lab.interpretation_flg,
                        lab.ACCESSION_NBR,
                        lab.REASON_FOR_TEST_DESC,
                        lab.REASON_FOR_TEST_CD,
                        lab.transcriptionist_name,
                        lab.transcriptionist_ass_auth_cd,
                        lab.Transcriptionist_Ass_Auth_Type,
                        lab.transcriptionist_id,
                        lab.Assistant_Interpreter_Name,
                        lab.Assistant_inter_ass_auth_cd,
                        lab.Assistant_inter_ass_auth_type,
                        lab.Assistant_interpreter_id,
                        lab.result_interpreter_name,
                        lab.specimen_src,
                        lab.specimen_nm,
                        lab.Specimen_details,
                        lab.Specimen_collection_vol,
                        lab.Specimen_collection_vol_unit,
                        lab.Specimen_desc,
                        lab.Danger_cd,
                        lab.Danger_cd_desc,
                        lab.parent_test_pntr,
                        lab.LAB_TEST_pntr,
                        CASE
                            WHEN lab.LAB_TEST_TYPE = 'Result' then lab.resulted_lab_report_date
                            WHEN lab.LAB_TEST_TYPE = 'Order_rslt' then lab.sus_lab_report_date
                            ELSE lab.LAB_TEST_dt
                            END AS LAB_TEST_DT,
                        lab.test_method_cd,
                        lab.root_ordered_test_pntr,
                        CASE
                            WHEN rtrim(lab.test_method_cd_desc) = '' THEN NULL
                            ELSE lab.test_method_cd_desc
                            END AS test_method_cd_desc,
                        lab.priority_cd,
                        lab.specimen_site,
                        lab.SPECIMEN_SITE_desc,
                        lab.Clinical_information,
                        lab.LAB_TEST_Type,
                        lab.LAB_TEST_cd,
                        lab.LAB_TEST_cd_desc,
                        lab.LAB_TEST_cd_sys_cd,
                        lab.LAB_TEST_cd_sys_nm,
                        lab.Alt_LAB_TEST_cd,
                        lab.Alt_LAB_TEST_cd_desc,
                        lab.Alt_LAB_TEST_cd_sys_cd,
                        lab.Alt_LAB_TEST_cd_sys_nm,
                        lab.specimen_collection_dt,
                        lab.lab_rpt_local_id,
                        lab.lab_rpt_share_ind,
                        CASE
                            WHEN lab.record_status_cd IN ('', 'UNPROCESSED', 'UNPROCESSED_PREV_D', 'PROCESSED') or
                                 lab.record_status_cd is null then 'ACTIVE'
                            WHEN lab.record_status_cd = 'INACTIVE' THEN 'LOG_DEL'
                            ELSE lab.record_status_cd
                            END as record_status_cd,
                        lab.record_status_cd_for_result,
                        lab.lab_rpt_status,
                        lab.LAB_RPT_CREATED_DT,
                        lab.LAB_RPT_CREATED_BY,
                        lab.LAB_RPT_RECEIVED_BY_PH_DT,
                        lab.LAB_RPT_LAST_UPDATE_DT,
                        lab.LAB_RPT_LAST_UPDATE_BY,
                        lab.ELR_IND,
                        lab.Jurisdiction_cd,
                        lab.JURISDICTION_NM,
                        lab.resulted_lab_report_date,
                        lab.sus_lab_report_date,
                        lab.report_observation_uid,
                        lab.report_refr_uid,
                        lab.report_sprt_uid,
                        lab.followup_observation_uid,
                        lab.accession_number,
                        lab.morb_hosp_id,
                        lab.transcriptionist_auth_type,
                        lab.assistant_interpreter_auth_type,
                        lab.morb_physician_id,
                        lab.morb_reporter_id,
                        lab.transcriptionist_val,
                        lab.transcriptionist_first_nm,
                        lab.transcriptionist_last_nm,
                        lab.assistant_interpreter_val,
                        lab.assistant_interpreter_first_nm,
                        lab.assistant_interpreter_last_nm,
                        lab.result_interpreter_id,
                        lab.transcriptionist_id_assign_auth,
                        lab.assistant_interpreter_id_assign_auth,
                        lab.interpretation_cd,
                        lab.condition_cd,
                        lab.LAB_TEST_status,
                        lab.processing_decision_cd,
                        lab.document_link,
                        lab.Lab_Rpt_Uid_Test1,
                        lab.Morb_oid,
                        lab.PROCESSING_DECISION_DESC,
                        lab.record_status_cd_for_result_drug,
                        lab.root_thru_srpt,
                        lab.root_thru_refr,
                        lab.Root_Ordered_Test_Nm,
                        lab.Parent_Test_Nm,
                        lab.SPECIMEN_ADD_TIME,
                        lab.SPECIMEN_LAST_CHANGE_TIME,
                        ord.oid as order_oid
        into #LAB_TEST
        from #LAB_TEST4 lab
                 left join #order_test ord on lab.root_ordered_test_pntr = ord.root_ordered_test_pntr;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #Merge_Order ';


        IF
            OBJECT_ID('#Merge_Order', 'U') IS NOT NULL
            drop table #Merge_Order;

        with ordered_mat as (select act_uid,
                                    material_cd,
                                    material_desc,
                                    ROW_NUMBER() OVER (PARTITION BY act_uid order by last_chg_time desc) as row_num
                             from dbo.nrt_observation_material
                             where act_uid in (SELECT root_ordered_Test_pntr from #LAB_TEST))
        select lt.root_ordered_test_pntr                                                                        as root_ordered_test_pntr_merge,
               obs.accession_number                                                                             as ACCESSION_NBR_merge,
               obs.add_user_id                                                                                  as LAB_RPT_CREATED_BY_merge,
               obs.ADD_TIME                                                                                     as LAB_RPT_CREATED_DT,
               obs.JURISDICTION_CD,
               CASE
                   WHEN obs.jurisdiction_cd IS NOT NULL THEN jc.code_short_desc_txt
                   else CAST(NULL AS varchar(50)) end                                                           as JURISDICTION_NM,
               obs.activity_to_time                                                             as LAB_TEST_dt,
               obs.effective_from_time                                                                          as specimen_collection_dt,
               obs.rpt_to_state_time                                                                            as LAB_RPT_RECEIVED_BY_PH_DT,
               obs.LAST_CHG_TIME                                                                                as LAB_RPT_LAST_UPDATE_DT,
               obs.LAST_CHG_USER_ID                                                                             as LAB_RPT_LAST_UPDATE_BY,
               obs.electronic_ind                                                                               as ELR_IND1,
               mat.material_cd                                                                                  as specimen_src,
               obs.target_site_cd                                                                               as specimen_site,
               mat.material_desc                                                                                as Specimen_desc,
               obs.target_site_desc_txt                                                                         as SPECIMEN_SITE_desc,
               obs.local_id                                                                                     as lab_rpt_local_id,
               CASE
                   WHEN obs.record_status_cd IN ('', 'UNPROCESSED', 'UNPROCESSED_PREV_D', 'PROCESSED') THEN 'ACTIVE'
                   WHEN obs.record_status_cd = 'LOG_DEL' THEN 'INACTIVE'
                   ELSE obs.record_status_cd
                   END                                                                                          as record_status_cd_merge,
               CASE
                   WHEN COALESCE(obs2.program_jurisdiction_oid, obs.program_jurisdiction_oid, lt.order_oid) = 4
                       THEN NULL
                   ELSE COALESCE(obs2.program_jurisdiction_oid, obs.program_jurisdiction_oid,
                                 lt.order_oid) END                                                              as order_oid
        into #Merge_Order
        from #LAB_TEST lt
                 left join dbo.nrt_observation obs
                           on lt.root_ordered_test_pntr = obs.observation_uid
                 left join dbo.nrt_observation obs2
                           on obs.report_observation_uid = obs2.observation_uid and
                              obs.ctrl_cd_display_form = 'LabReportMorb'
                 left join (select act_uid,
                                   material_cd,
                                   material_desc
                            FROM ordered_mat
                            where row_num = 1) mat
                           on obs.observation_uid = mat.act_uid
                 left join nbs_srte..jurisdiction_code jc
                           on obs.jurisdiction_cd = jc.code
                               and jc.code_set_nm = 'S_JURDIC_C';

        if
            @debug = 'true'
            SELECT 'lab_test' as nm, *
            FROM #LAB_TEST;
        if
            @debug = 'true'
            SELECT 'merge_order' as nm, *
            FROM #Merge_Order;


        alter table #LAB_TEST
            drop
                column
                    ACCESSION_NBR,
                LAB_RPT_CREATED_BY,
                LAB_RPT_CREATED_DT,
                JURISDICTION_CD,
                JURISDICTION_NM,
                LAB_TEST_dt,
                specimen_collection_dt,
                LAB_RPT_RECEIVED_BY_PH_DT,
                LAB_RPT_LAST_UPDATE_DT,
                LAB_RPT_LAST_UPDATE_BY,
                --	ELR_IND	,
                resulted_lab_report_date,
                sus_lab_report_date,
                specimen_src,
                specimen_site,
                Specimen_desc,
                SPECIMEN_SITE_desc,
                LAB_RPT_LOCAL_ID,
                record_status_cd_for_result,
                record_status_cd_for_result_drug,
                order_oid;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST_final_root_ordered_test_pntr ';


        IF
            OBJECT_ID('#LAB_TEST_final_root_ordered_test_pntr', 'U') IS NOT NULL
            drop table #LAB_TEST_final_root_ordered_test_pntr;

        select root_ordered_test_pntr AS LAB_TEST_ptnr
        into #LAB_TEST_final_root_ordered_test_pntr
        from #LAB_TEST
        union
        select root_ordered_test_pntr_merge
        from #Merge_Order;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #LAB_TEST_final';


        IF
            OBJECT_ID('#LAB_TEST_final', 'U') IS NOT NULL
            drop table #LAB_TEST_final;


        select lt1.LAB_TEST_ptnr,
               lto.LAB_TEST_uid_final_order,
               lto.LAB_TEST_uid_final_result,
               lto.LAB_TEST_uid_final,
               lto.lab_rpt_uid,
               lto.LAB_TEST_uid,
               lto.LAB_TEST_uid_oth,
               lto.interpretation_flg,
               CASE
                   WHEN lto.REASON_FOR_TEST_DESC = '' THEN NULL
                   ELSE lto.REASON_FOR_TEST_DESC
                   END AS REASON_FOR_TEST_DESC,
               CASE
                   WHEN lto.REASON_FOR_TEST_CD = '' THEN NULL
                   ELSE lto.REASON_FOR_TEST_CD
                   END AS REASON_FOR_TEST_CD,
               lto.transcriptionist_name,
               lto.transcriptionist_ass_auth_cd,
               lto.Transcriptionist_Ass_Auth_Type,
               lto.transcriptionist_id,
               lto.Assistant_Interpreter_Name,
               lto.Assistant_inter_ass_auth_cd,
               lto.Assistant_inter_ass_auth_type,
               lto.Assistant_interpreter_id,
               lto.result_interpreter_name,
               lto.specimen_nm,
               lto.Specimen_details,
               lto.Specimen_collection_vol,
               lto.Specimen_collection_vol_unit,
               lto.Danger_cd,
               lto.Danger_cd_desc,
               lto.parent_test_pntr,
               lto.LAB_TEST_pntr,
               lto.test_method_cd,
               lto.root_ordered_test_pntr,
               lto.test_method_cd_desc,
               lto.priority_cd,
               CASE
                   WHEN lto.CLINICAL_INFORMATION = '' THEN NULL
                   ELSE lto.CLINICAL_INFORMATION
                   END AS CLINICAL_INFORMATION,
               lto.LAB_TEST_Type,
               lto.LAB_TEST_cd,
               lto.LAB_TEST_cd_desc,
               lto.LAB_TEST_cd_sys_cd,
               lto.LAB_TEST_cd_sys_nm,
               lto.Alt_LAB_TEST_cd,
               lto.Alt_LAB_TEST_cd_desc,
               lto.Alt_LAB_TEST_cd_sys_cd,
               lto.Alt_LAB_TEST_cd_sys_nm,
               lto.lab_rpt_share_ind,
               CASE
                   WHEN ltmi.record_status_cd_merge IS NOT NULL THEN ltmi.record_status_cd_merge
                   ELSE lto.record_status_cd
                   END AS record_status_cd,
               lto.lab_rpt_status,
               lto.report_observation_uid,
               lto.report_refr_uid,
               lto.report_sprt_uid,
               lto.followup_observation_uid,
               lto.accession_number,
               lto.morb_hosp_id,
               lto.transcriptionist_auth_type,
               lto.assistant_interpreter_auth_type,
               lto.morb_physician_id,
               lto.morb_reporter_id,
               lto.transcriptionist_val,
               lto.transcriptionist_first_nm,
               lto.transcriptionist_last_nm,
               lto.assistant_interpreter_val,
               lto.assistant_interpreter_first_nm,
               lto.assistant_interpreter_last_nm,
               lto.result_interpreter_id,
               lto.transcriptionist_id_assign_auth,
               lto.assistant_interpreter_id_assign_auth,
               lto.interpretation_cd,
               lto.condition_cd,
               lto.LAB_TEST_status,
               lto.processing_decision_cd,
               lto.document_link,
               lto.Lab_Rpt_Uid_Test1,
               lto.Morb_oid,
               lto.PROCESSING_DECISION_DESC,
               lto.root_thru_srpt,
               lto.root_thru_refr,
               lto.Root_Ordered_Test_Nm,
               lto.Parent_Test_Nm,
               lto.SPECIMEN_ADD_TIME,
               lto.SPECIMEN_LAST_CHANGE_TIME,
               case
                   when ltmi.ELR_IND1 IS NOT NULL THEN ltmi.ELR_IND1
                   ELSE lto.ELR_IND
                   END AS ELR_IND,
               CASE
                   WHEN ltmi.ACCESSION_NBR_merge = '' THEN NULL
                   ELSE ltmi.ACCESSION_NBR_merge
                   END AS ACCESSION_NBR_merge,
               ltmi.LAB_RPT_CREATED_BY_merge,
               ltmi.LAB_RPT_CREATED_DT,
               ltmi.jurisdiction_cd,
               CASE
                   WHEN ltmi.JURISDICTION_NM = '' THEN NULL
                   ELSE ltmi.JURISDICTION_NM
                   END AS JURISDICTION_NM,
               ltmi.LAB_TEST_dt,
               ltmi.specimen_collection_dt,
               ltmi.LAB_RPT_RECEIVED_BY_PH_DT,
               ltmi.LAB_RPT_LAST_UPDATE_DT,
               ltmi.LAB_RPT_LAST_UPDATE_BY,
               CASE
                   WHEN ltmi.SPECIMEN_SRC = '' THEN NULL
                   ELSE ltmi.SPECIMEN_SRC
                   END AS SPECIMEN_SRC,
               ltmi.specimen_site,
               CASE
                   WHEN ltmi.SPECIMEN_DESC = '' THEN NULL
                   ELSE ltmi.SPECIMEN_DESC
                   END AS SPECIMEN_DESC,
               ltmi.SPECIMEN_SITE_desc,
               ltmi.lab_rpt_local_id,
               ltmi.order_oid
        into #LAB_TEST_final
        from #LAB_TEST_final_root_ordered_test_pntr lt1
                 left outer join #LAB_TEST lto on lt1.LAB_TEST_ptnr = lto.root_ordered_test_pntr
                 left outer join #Merge_Order ltmi on lt1.LAB_TEST_ptnr = ltmi.root_ordered_test_pntr_merge;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #L_LAB_TEST_N ';


        IF
            OBJECT_ID('#L_LAB_TEST_N', 'U') IS NOT NULL
            drop table #L_LAB_TEST_N;


        CREATE TABLE #L_LAB_TEST_N
        (
            [LAB_TEST_id]  [int] IDENTITY
                (
                1,
                1
                )               NOT NULL,
            [LAB_TEST_UID] [numeric](20, 0) NULL,
            [LAB_TEST_KEY] [numeric](18, 0) NULL
        ) ON [PRIMARY];


-- REMOVES VALUES THAT ARE ALREADY IN LAB_TEST
        insert into #L_LAB_TEST_N ([LAB_TEST_UID])
        SELECT DISTINCT tlt.LAB_TEST_UID
        FROM #LAB_TEST_final tlt
        EXCEPT
        SELECT lt.LAB_TEST_UID
        FROM dbo.L_LAB_TEST lt;

        UPDATE #L_LAB_TEST_N
        SET LAB_TEST_KEY = LAB_TEST_ID + coalesce((SELECT MAX(LAB_TEST_KEY) FROM dbo.L_LAB_TEST), 0)


        DELETE
        FROM #L_LAB_TEST_N
        WHERE LAB_TEST_UID IS NULL;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERTING INTO L_LAB_TEST';


        INSERT INTO dbo.L_LAB_TEST
        ( [LAB_TEST_KEY]
        , [LAB_TEST_UID])
        SELECT [LAB_TEST_KEY], [LAB_TEST_UID]
        FROM #L_LAB_TEST_N;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #D_LAB_TEST_N ';


        IF
            OBJECT_ID('#D_LAB_TEST_N', 'U') IS NOT NULL
            drop table #D_LAB_TEST_N;


        SELECT distinct lt.LAB_TEST_ptnr,
                        lt.LAB_TEST_uid_final_order,
                        lt.LAB_TEST_uid_final_result,
                        lt.LAB_TEST_uid_final,
                        lt.lab_rpt_uid,
                        lt.LAB_TEST_uid,
                        lt.LAB_TEST_uid_oth,
                        lt.interpretation_flg,
                        lt.REASON_FOR_TEST_DESC,
                        lt.REASON_FOR_TEST_CD,
                        lt.transcriptionist_name,
                        lt.transcriptionist_ass_auth_cd,
                        lt.Transcriptionist_Ass_Auth_Type,
                        lt.transcriptionist_id,
                        lt.Assistant_Interpreter_Name,
                        lt.Assistant_inter_ass_auth_cd,
                        lt.Assistant_inter_ass_auth_type,
                        lt.Assistant_interpreter_id,
                        lt.result_interpreter_name,
                        lt.specimen_nm,
                        lt.Specimen_details,
                        lt.Specimen_collection_vol,
                        lt.Specimen_collection_vol_unit,
                        lt.Danger_cd,
                        lt.Danger_cd_desc,
                        lt.parent_test_pntr,
                        lt.LAB_TEST_pntr,
                        lt.test_method_cd,
                        lt.root_ordered_test_pntr,
                        lt.test_method_cd_desc,
                        lt.priority_cd,
                        lt.CLINICAL_INFORMATION,
                        lt.LAB_TEST_Type,
                        lt.LAB_TEST_cd,
                        lt.LAB_TEST_cd_desc,
                        lt.LAB_TEST_cd_sys_cd,
                        lt.LAB_TEST_cd_sys_nm,
                        lt.Alt_LAB_TEST_cd,
                        lt.Alt_LAB_TEST_cd_desc,
                        lt.Alt_LAB_TEST_cd_sys_cd,
                        lt.Alt_LAB_TEST_cd_sys_nm,
                        lt.lab_rpt_share_ind,
                        lt.record_status_cd,
                        lt.lab_rpt_status,
                        lt.report_observation_uid,
                        lt.report_refr_uid,
                        lt.report_sprt_uid,
                        lt.followup_observation_uid,
                        lt.accession_number,
                        lt.morb_hosp_id,
                        lt.transcriptionist_auth_type,
                        lt.assistant_interpreter_auth_type,
                        lt.morb_physician_id,
                        lt.morb_reporter_id,
                        lt.transcriptionist_val,
                        lt.transcriptionist_first_nm,
                        lt.transcriptionist_last_nm,
                        lt.assistant_interpreter_val,
                        lt.assistant_interpreter_first_nm,
                        lt.assistant_interpreter_last_nm,
                        lt.result_interpreter_id,
                        lt.transcriptionist_id_assign_auth,
                        lt.assistant_interpreter_id_assign_auth,
                        lt.interpretation_cd,
                        lt.condition_cd,
                        lt.LAB_TEST_status,
                        lt.processing_decision_cd,
                        lt.document_link,
                        lt.Lab_Rpt_Uid_Test1,
                        lt.Morb_oid,
                        lt.PROCESSING_DECISION_DESC,
                        lt.root_thru_srpt,
                        lt.root_thru_refr,
                        lt.Root_Ordered_Test_Nm,
                        lt.Parent_Test_Nm,
                        lt.SPECIMEN_ADD_TIME,
                        lt.SPECIMEN_LAST_CHANGE_TIME,
                        lt.ELR_IND,
                        lt.ACCESSION_NBR_merge,
                        lt.LAB_RPT_CREATED_BY_merge,
                        lt.LAB_RPT_CREATED_DT,
                        lt.jurisdiction_cd,
                        lt.JURISDICTION_NM,
                        lt.LAB_TEST_dt,
                        lt.specimen_collection_dt,
                        lt.LAB_RPT_RECEIVED_BY_PH_DT,
                        lt.LAB_RPT_LAST_UPDATE_DT,
                        lt.LAB_RPT_LAST_UPDATE_BY,
                        lt.SPECIMEN_SRC,
                        lt.specimen_site,
                        lt.SPECIMEN_DESC,
                        lt.SPECIMEN_SITE_desc,
                        lt.lab_rpt_local_id,
                        lt.order_oid,
                        ltn.[LAB_TEST_KEY]
        INTO #D_LAB_TEST_N
        FROM #LAB_TEST_final lt,
             #L_LAB_TEST_N ltn
        WHERE lt.LAB_TEST_UID = ltn.LAB_TEST_UID;

        if
            @debug = 'true'
            SELECT 'lab_test_n' as nm, *
            FROM #D_LAB_TEST_N
            order by lab_test_key;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #D_LAB_TEST_U ';


        IF
            OBJECT_ID('#D_LAB_TEST_U', 'U') IS NOT NULL
            drop table #D_LAB_TEST_U;


        SELECT distinct lt.LAB_TEST_ptnr,
                        lt.LAB_TEST_uid_final_order,
                        lt.LAB_TEST_uid_final_result,
                        lt.LAB_TEST_uid_final,
                        lt.lab_rpt_uid,
                        lt.LAB_TEST_uid,
                        lt.LAB_TEST_uid_oth,
                        lt.interpretation_flg,
                        lt.REASON_FOR_TEST_DESC,
                        lt.REASON_FOR_TEST_CD,
                        lt.transcriptionist_name,
                        lt.transcriptionist_ass_auth_cd,
                        lt.Transcriptionist_Ass_Auth_Type,
                        lt.transcriptionist_id,
                        lt.Assistant_Interpreter_Name,
                        lt.Assistant_inter_ass_auth_cd,
                        lt.Assistant_inter_ass_auth_type,
                        lt.Assistant_interpreter_id,
                        lt.result_interpreter_name,
                        lt.specimen_nm,
                        lt.Specimen_details,
                        lt.Specimen_collection_vol,
                        lt.Specimen_collection_vol_unit,
                        lt.Danger_cd,
                        lt.Danger_cd_desc,
                        lt.parent_test_pntr,
                        lt.LAB_TEST_pntr,
                        lt.test_method_cd,
                        lt.root_ordered_test_pntr,
                        lt.test_method_cd_desc,
                        lt.priority_cd,
                        lt.CLINICAL_INFORMATION,
                        lt.LAB_TEST_Type,
                        lt.LAB_TEST_cd,
                        lt.LAB_TEST_cd_desc,
                        lt.LAB_TEST_cd_sys_cd,
                        lt.LAB_TEST_cd_sys_nm,
                        lt.Alt_LAB_TEST_cd,
                        lt.Alt_LAB_TEST_cd_desc,
                        lt.Alt_LAB_TEST_cd_sys_cd,
                        lt.Alt_LAB_TEST_cd_sys_nm,
                        lt.lab_rpt_share_ind,
                        lt.record_status_cd,
                        lt.lab_rpt_status,
                        lt.report_observation_uid,
                        lt.report_refr_uid,
                        lt.report_sprt_uid,
                        lt.followup_observation_uid,
                        lt.accession_number,
                        lt.morb_hosp_id,
                        lt.transcriptionist_auth_type,
                        lt.assistant_interpreter_auth_type,
                        lt.morb_physician_id,
                        lt.morb_reporter_id,
                        lt.transcriptionist_val,
                        lt.transcriptionist_first_nm,
                        lt.transcriptionist_last_nm,
                        lt.assistant_interpreter_val,
                        lt.assistant_interpreter_first_nm,
                        lt.assistant_interpreter_last_nm,
                        lt.result_interpreter_id,
                        lt.transcriptionist_id_assign_auth,
                        lt.assistant_interpreter_id_assign_auth,
                        lt.interpretation_cd,
                        lt.condition_cd,
                        lt.LAB_TEST_status,
                        lt.processing_decision_cd,
                        lt.document_link,
                        lt.Lab_Rpt_Uid_Test1,
                        lt.Morb_oid,
                        lt.PROCESSING_DECISION_DESC,
                        lt.root_thru_srpt,
                        lt.root_thru_refr,
                        lt.Root_Ordered_Test_Nm,
                        lt.Parent_Test_Nm,
                        lt.SPECIMEN_ADD_TIME,
                        lt.SPECIMEN_LAST_CHANGE_TIME,
                        lt.ELR_IND,
                        lt.ACCESSION_NBR_merge,
                        lt.LAB_RPT_CREATED_BY_merge,
                        lt.LAB_RPT_CREATED_DT,
                        lt.jurisdiction_cd,
                        lt.JURISDICTION_NM,
                        lt.LAB_TEST_dt,
                        lt.specimen_collection_dt,
                        lt.LAB_RPT_RECEIVED_BY_PH_DT,
                        lt.LAB_RPT_LAST_UPDATE_DT,
                        lt.LAB_RPT_LAST_UPDATE_BY,
                        lt.SPECIMEN_SRC,
                        lt.specimen_site,
                        lt.SPECIMEN_DESC,
                        lt.SPECIMEN_SITE_desc,
                        lt.lab_rpt_local_id,
                        lt.order_oid
        INTO #D_LAB_TEST_U
        FROM #LAB_TEST_final lt
        WHERE lt.LAB_TEST_UID IN (select LAB_TEST_UID FROM dbo.LAB_TEST);

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'insert into dbo.LAB_TEST';


        insert into dbo.LAB_TEST
        ( [LAB_TEST_STATUS]
        , [LAB_TEST_KEY]
        , [LAB_RPT_LOCAL_ID]
        , [TEST_METHOD_CD]
        , [TEST_METHOD_CD_DESC]
        , [LAB_RPT_SHARE_IND]
        , [LAB_TEST_CD]
        , [ELR_IND]
        , [LAB_RPT_UID]
        , [LAB_TEST_CD_DESC]
        , [INTERPRETATION_FLG]
        , [LAB_RPT_RECEIVED_BY_PH_DT]
        , [LAB_RPT_CREATED_BY]
        , [REASON_FOR_TEST_DESC]
        , [REASON_FOR_TEST_CD]
        , [LAB_RPT_LAST_UPDATE_BY]
        , [LAB_TEST_DT]
        , [LAB_RPT_CREATED_DT]
        , [LAB_TEST_TYPE]
        , [LAB_RPT_LAST_UPDATE_DT]
        , [JURISDICTION_CD]
        , [LAB_TEST_CD_SYS_CD]
        , [LAB_TEST_CD_SYS_NM]
        , [JURISDICTION_NM]
        , [OID]
        , [ALT_LAB_TEST_CD]
        , [LAB_RPT_STATUS]
        , [DANGER_CD_DESC]
        , ALT_LAB_TEST_CD_DESC
        , [ACCESSION_NBR]
        , [SPECIMEN_SRC]
        , [PRIORITY_CD]
        , [ALT_LAB_TEST_CD_SYS_CD]
        , [ALT_LAB_TEST_CD_SYS_NM]
        , [SPECIMEN_SITE]
        , [SPECIMEN_DETAILS]
        , [DANGER_CD]
        , [SPECIMEN_COLLECTION_VOL]
        , [SPECIMEN_COLLECTION_VOL_UNIT]
        , [SPECIMEN_DESC]
        , [SPECIMEN_SITE_DESC]
        , [CLINICAL_INFORMATION]
        , [LAB_TEST_UID]
        , [ROOT_ORDERED_TEST_PNTR]
        , [PARENT_TEST_PNTR]
        , [LAB_TEST_PNTR]
        , [SPECIMEN_ADD_TIME]
        , [SPECIMEN_LAST_CHANGE_TIME]
        , [SPECIMEN_COLLECTION_DT]
        , [SPECIMEN_NM]
        , [ROOT_ORDERED_TEST_NM]
        , [PARENT_TEST_NM]
        , [TRANSCRIPTIONIST_NAME]
        , [TRANSCRIPTIONIST_ID]
        , [TRANSCRIPTIONIST_ASS_AUTH_CD]
        , [TRANSCRIPTIONIST_ASS_AUTH_TYPE]
        , [ASSISTANT_INTERPRETER_NAME]
        , [ASSISTANT_INTERPRETER_ID]
        , [ASSISTANT_INTER_ASS_AUTH_CD]
        , [ASSISTANT_INTER_ASS_AUTH_TYPE]
        , [RESULT_INTERPRETER_NAME]
        , [RECORD_STATUS_CD]
        , [RDB_LAST_REFRESH_TIME]
        , [CONDITION_CD]
        , [PROCESSING_DECISION_CD]
        , [PROCESSING_DECISION_DESC])
        select rtrim(cast(LAB_TEST_STATUS AS varchar(50)))
             , [LAB_TEST_KEY]
             , rtrim(cast(LAB_RPT_LOCAL_ID AS varchar(50)))
             , rtrim(cast(TEST_METHOD_CD AS varchar(199)))
             , rtrim(cast(TEST_METHOD_CD_DESC AS varchar(199)))
             , rtrim(cast(LAB_RPT_SHARE_IND AS varchar(50)))
             , rtrim(cast(LAB_TEST_CD AS varchar(1000)))
             , rtrim(cast(ELR_IND AS varchar(50)))
             , [LAB_RPT_UID]
             , rtrim(cast(LAB_TEST_CD_DESC AS varchar(2000)))
             , rtrim(cast(INTERPRETATION_CD AS varchar(20)))
             , [LAB_RPT_RECEIVED_BY_PH_DT]
             , [LAB_RPT_CREATED_BY_MERGE]
             , rtrim(cast(REASON_FOR_TEST_DESC AS varchar(4000)))
             , rtrim(cast(REASON_FOR_TEST_CD AS varchar(4000)))
             , [LAB_RPT_LAST_UPDATE_BY]
             , [LAB_TEST_DT]
             , [LAB_RPT_CREATED_DT]
             , rtrim(cast(LAB_TEST_TYPE AS varchar(50)))
             , [LAB_RPT_LAST_UPDATE_DT]
             , rtrim(cast(JURISDICTION_CD AS varchar(20)))
             , rtrim(cast(LAB_TEST_CD_SYS_CD AS varchar(50)))
             , rtrim(cast(LAB_TEST_CD_SYS_NM AS varchar(100)))
             , rtrim(cast(JURISDICTION_NM AS varchar(50)))
             , order_OID
             , rtrim(cast(ALT_LAB_TEST_CD AS varchar(50)))
             , cast(LAB_RPT_STATUS AS char(1))
             , rtrim(cast(DANGER_CD_DESC AS varchar(100)))
             , rtrim(cast(ALT_LAB_TEST_CD_DESC AS varchar(1000)))
             , rtrim(cast(ACCESSION_NBR_MERGE AS varchar(199)))
             , rtrim(cast(SPECIMEN_SRC AS varchar(50)))
             , rtrim(cast(PRIORITY_CD AS varchar(20)))
             , rtrim(cast(ALT_LAB_TEST_CD_SYS_CD AS varchar(50)))
             , rtrim(cast(ALT_LAB_TEST_CD_SYS_NM AS varchar(100)))
             , rtrim(cast(SPECIMEN_SITE AS varchar(20)))
             , rtrim(cast(SPECIMEN_DETAILS AS varchar(1000)))
             , rtrim(cast(DANGER_CD AS varchar(20)))
             , rtrim(cast(SPECIMEN_COLLECTION_VOL AS varchar(20)))
             , rtrim(cast(SPECIMEN_COLLECTION_VOL_UNIT AS varchar(50)))
             , rtrim(cast(SPECIMEN_DESC AS varchar(1000)))
             , rtrim(cast(SPECIMEN_SITE_DESC AS varchar(100)))
             , rtrim(cast(CLINICAL_INFORMATION AS varchar(1000)))
             , [LAB_TEST_UID]
             , [ROOT_ORDERED_TEST_PNTR]
             , [PARENT_TEST_PNTR]
             , [LAB_TEST_PNTR]
             , [SPECIMEN_ADD_TIME]
             , [SPECIMEN_LAST_CHANGE_TIME]
             , [SPECIMEN_COLLECTION_DT]
             , rtrim(cast(SPECIMEN_NM AS varchar(100)))
             , rtrim(cast(ROOT_ORDERED_TEST_NM AS varchar(1000)))
             , rtrim(cast(PARENT_TEST_NM AS varchar(1000)))
             , rtrim(cast(TRANSCRIPTIONIST_NAME AS varchar(300)))
             , rtrim(cast(TRANSCRIPTIONIST_ID AS varchar(100)))
             , rtrim(cast(TRANSCRIPTIONIST_ASS_AUTH_CD AS varchar(199)))
             , rtrim(cast(TRANSCRIPTIONIST_ASS_AUTH_TYPE AS varchar(100)))
             , rtrim(cast(ASSISTANT_INTERPRETER_NAME AS varchar(300)))
             , rtrim(cast(ASSISTANT_INTERPRETER_ID AS varchar(100)))
             , rtrim(cast(ASSISTANT_INTER_ASS_AUTH_CD AS varchar(199)))
             , rtrim(cast(ASSISTANT_INTER_ASS_AUTH_TYPE AS varchar(100)))
             , rtrim(cast(RESULT_INTERPRETER_NAME AS varchar(300)))
             , rtrim(cast(RECORD_STATUS_CD AS varchar(8)))
             , GETDATE()
             , rtrim(cast(CONDITION_CD AS varchar(20)))
             , rtrim(cast(PROCESSING_DECISION_CD AS varchar(50)))
             , rtrim(cast(PROCESSING_DECISION_DESC AS varchar(50)))
        FROM #D_LAB_TEST_N;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Update dbo.LAB_TEST';


        UPDATE
            lt
        SET lt.[LAB_TEST_STATUS]                = rtrim(cast(dltu.LAB_TEST_STATUS AS varchar(50)))
          , lt.[LAB_RPT_LOCAL_ID]               = rtrim(cast(dltu.LAB_RPT_LOCAL_ID AS varchar(50)))
          , lt.[TEST_METHOD_CD]                 = rtrim(cast(dltu.TEST_METHOD_CD AS varchar(199)))
          , lt.[TEST_METHOD_CD_DESC]            = rtrim(cast(dltu.TEST_METHOD_CD_DESC AS varchar(199)))
          , lt.[LAB_RPT_SHARE_IND]              = rtrim(cast(dltu.LAB_RPT_SHARE_IND AS varchar(50)))
          , lt.[LAB_TEST_CD]                    = rtrim(cast(dltu.LAB_TEST_CD AS varchar(1000)))
          , lt.[ELR_IND]                        = rtrim(cast(dltu.ELR_IND AS varchar(50)))
          , lt.[LAB_RPT_UID]                    = dltu.LAB_RPT_UID
          , lt.[LAB_TEST_CD_DESC]               = rtrim(cast(dltu.LAB_TEST_CD_DESC AS varchar(2000)))
          , lt.[INTERPRETATION_FLG]             = rtrim(cast(dltu.INTERPRETATION_CD AS varchar(20)))
          , lt.[LAB_RPT_RECEIVED_BY_PH_DT]      = dltu.LAB_RPT_RECEIVED_BY_PH_DT
          , lt.[LAB_RPT_CREATED_BY]             = dltu.LAB_RPT_CREATED_BY_MERGE
          , lt.[REASON_FOR_TEST_DESC]           = rtrim(cast(dltu.REASON_FOR_TEST_DESC AS varchar(4000)))
          , lt.[REASON_FOR_TEST_CD]             = rtrim(cast(dltu.REASON_FOR_TEST_CD AS varchar(4000)))
          , lt.[LAB_RPT_LAST_UPDATE_BY]         = dltu.LAB_RPT_LAST_UPDATE_BY
          , lt.[LAB_TEST_DT]                    = dltu.LAB_TEST_DT
          , lt.[LAB_RPT_CREATED_DT]             = dltu.LAB_RPT_CREATED_DT
          , lt.[LAB_TEST_TYPE]                  = rtrim(cast(dltu.LAB_TEST_TYPE AS varchar(50)))
          , lt.[LAB_RPT_LAST_UPDATE_DT]         = dltu.LAB_RPT_LAST_UPDATE_DT
          , lt.[JURISDICTION_CD]                = rtrim(cast(dltu.JURISDICTION_CD AS varchar(20)))
          , lt.[LAB_TEST_CD_SYS_CD]             = rtrim(cast(dltu.LAB_TEST_CD_SYS_CD AS varchar(50)))
          , lt.[LAB_TEST_CD_SYS_NM]             = rtrim(cast(dltu.LAB_TEST_CD_SYS_NM AS varchar(100)))
          , lt.[JURISDICTION_NM]                = rtrim(cast(dltu.JURISDICTION_NM AS varchar(50)))
          , lt.[OID]                            = dltu.order_OID
          , lt.[ALT_LAB_TEST_CD]                = rtrim(cast(dltu.ALT_LAB_TEST_CD AS varchar(50)))
          , lt.[LAB_RPT_STATUS]                 = cast(dltu.LAB_RPT_STATUS AS char(1))
          , lt.[DANGER_CD_DESC]                 = rtrim(cast(dltu.DANGER_CD_DESC AS varchar(100)))
          , lt.ALT_LAB_TEST_CD_DESC             = rtrim(cast(dltu.ALT_LAB_TEST_CD_DESC AS varchar(1000)))
          , lt.[ACCESSION_NBR]                  = rtrim(cast(dltu.ACCESSION_NBR_MERGE AS varchar(199)))
          , lt.[SPECIMEN_SRC]                   = rtrim(cast(dltu.SPECIMEN_SRC AS varchar(50)))
          , lt.[PRIORITY_CD]                    = rtrim(cast(dltu.PRIORITY_CD AS varchar(20)))
          , lt.[ALT_LAB_TEST_CD_SYS_CD]         = rtrim(cast(dltu.ALT_LAB_TEST_CD_SYS_CD AS varchar(50)))
          , lt.[ALT_LAB_TEST_CD_SYS_NM]         = rtrim(cast(dltu.ALT_LAB_TEST_CD_SYS_NM AS varchar(100)))
          , lt.[SPECIMEN_SITE]                  = rtrim(cast(dltu.SPECIMEN_SITE AS varchar(20)))
          , lt.[SPECIMEN_DETAILS]               = rtrim(cast(dltu.SPECIMEN_DETAILS AS varchar(1000)))
          , lt.[DANGER_CD]                      = rtrim(cast(dltu.DANGER_CD AS varchar(20)))
          , lt.[SPECIMEN_COLLECTION_VOL]        = rtrim(cast(dltu.SPECIMEN_COLLECTION_VOL AS varchar(20)))
          , lt.[SPECIMEN_COLLECTION_VOL_UNIT]   = rtrim(cast(dltu.SPECIMEN_COLLECTION_VOL_UNIT AS varchar(50)))
          , lt.[SPECIMEN_DESC]                  = rtrim(cast(dltu.SPECIMEN_DESC AS varchar(1000)))
          , lt.[SPECIMEN_SITE_DESC]             = rtrim(cast(dltu.SPECIMEN_SITE_DESC AS varchar(100)))
          , lt.[CLINICAL_INFORMATION]           = rtrim(cast(dltu.CLINICAL_INFORMATION AS varchar(1000)))
          , lt.[ROOT_ORDERED_TEST_PNTR]         = dltu.ROOT_ORDERED_TEST_PNTR
          , lt.[PARENT_TEST_PNTR]               = dltu.PARENT_TEST_PNTR
          , lt.[LAB_TEST_PNTR]                  = dltu.LAB_TEST_PNTR
          , lt.[SPECIMEN_ADD_TIME]              = dltu.SPECIMEN_ADD_TIME
          , lt.[SPECIMEN_LAST_CHANGE_TIME]      = dltu.SPECIMEN_LAST_CHANGE_TIME
          , lt.[SPECIMEN_COLLECTION_DT]         = dltu.SPECIMEN_COLLECTION_DT
          , lt.[SPECIMEN_NM]                    = rtrim(cast(dltu.SPECIMEN_NM AS varchar(100)))
          , lt.[ROOT_ORDERED_TEST_NM]           = rtrim(cast(dltu.ROOT_ORDERED_TEST_NM AS varchar(1000)))
          , lt.[PARENT_TEST_NM]                 = rtrim(cast(dltu.PARENT_TEST_NM AS varchar(1000)))
          , lt.[TRANSCRIPTIONIST_NAME]          = rtrim(cast(dltu.TRANSCRIPTIONIST_NAME AS varchar(300)))
          , lt.[TRANSCRIPTIONIST_ID]            = rtrim(cast(dltu.TRANSCRIPTIONIST_ID AS varchar(100)))
          , lt.[TRANSCRIPTIONIST_ASS_AUTH_CD]   = rtrim(cast(dltu.TRANSCRIPTIONIST_ASS_AUTH_CD AS varchar(199)))
          , lt.[TRANSCRIPTIONIST_ASS_AUTH_TYPE] = rtrim(cast(dltu.TRANSCRIPTIONIST_ASS_AUTH_TYPE AS varchar(100)))
          , lt.[ASSISTANT_INTERPRETER_NAME]     = rtrim(cast(dltu.ASSISTANT_INTERPRETER_NAME AS varchar(300)))
          , lt.[ASSISTANT_INTERPRETER_ID]       = rtrim(cast(dltu.ASSISTANT_INTERPRETER_ID AS varchar(100)))
          , lt.[ASSISTANT_INTER_ASS_AUTH_CD]    = rtrim(cast(dltu.ASSISTANT_INTER_ASS_AUTH_CD AS varchar(199)))
          , lt.[ASSISTANT_INTER_ASS_AUTH_TYPE]  = rtrim(cast(dltu.ASSISTANT_INTER_ASS_AUTH_TYPE AS varchar(100)))
          , lt.[RESULT_INTERPRETER_NAME]        = rtrim(cast(dltu.RESULT_INTERPRETER_NAME AS varchar(300)))
          , lt.[RECORD_STATUS_CD]               = rtrim(cast(dltu.RECORD_STATUS_CD AS varchar(8)))
          , lt.[RDB_LAST_REFRESH_TIME]          = GETDATE()
          , lt.[CONDITION_CD]                   = rtrim(cast(dltu.CONDITION_CD AS varchar(20)))
          , lt.[PROCESSING_DECISION_CD]         = rtrim(cast(dltu.PROCESSING_DECISION_CD AS varchar(50)))
          , lt.[PROCESSING_DECISION_DESC]       = rtrim(cast(dltu.PROCESSING_DECISION_DESC AS varchar(50)))
        FROM dbo.LAB_TEST lt,
             #D_LAB_TEST_U dltu
        WHERE lt.lab_test_uid = dltu.lab_test_uid;


/*-------------------------------------------------------

    Lab_Report_User_Comment Dimension

    Note: Comments under the Order Test object (LAB214)
---------------------------------------------------------*/


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #Lab_Rpt_User_Comment_N ';


        IF OBJECT_ID('#Lab_Rpt_User_Comment_N', 'U') IS NOT NULL
            drop table #Lab_Rpt_User_Comment_N;

        CREATE TABLE #Lab_Rpt_User_Comment_N
        (
            [LAB_COMMENT_id]          [int] IDENTITY
                (
                1,
                1
                )                                     NOT NULL,
            [LAB_TEST_Key]            [bigint]        NULL,
            [LAB_TEST_uid]            [bigint]        NULL,
            [COMMENTS_FOR_ELR_DT]     [datetime]      NULL,
            [USER_COMMENT_CREATED_BY] [bigint]        NULL,
            [USER_RPT_COMMENTS]       [varchar](8000) NULL,
            [RECORD_STATUS_CD]        [varchar](8)    NOT NULL,
            [observation_uid]         [bigint]        NOT NULL,
            USER_COMMENT_KEY          [bigint],
            [RDB_LAST_REFRESH_TIME]   [datetime]      NULL
        ) ON [PRIMARY];


        INSERT INTO #Lab_Rpt_User_Comment_N
        select distinct tdltn.LAB_TEST_Key,
                        tdltn.lab_rpt_uid as    LAB_TEST_uid,
                        lab214.activity_to_time 'COMMENTS_FOR_ELR_DT',
                        lab214.add_user_id      'USER_COMMENT_CREATED_BY',
                        CASE
                            WHEN REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ') = '' THEN NULL
                            ELSE REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')
                            END           AS    USER_RPT_COMMENTS,
                        tdltn.record_status_cd  'RECORD_STATUS_CD',
                        lab214.observation_uid,
                        NULL              AS    USER_COMMENT_KEY,
                        getdate()         AS    RDB_LAST_REFRESH_TIME
        from #D_LAB_TEST_N as tdltn,
             dbo.nrt_observation as obs,
             dbo.nrt_observation as lab214,
             dbo.nrt_observation_txt as ovt
        where ovt.ovt_value_txt is not null
          and obs.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ','))
          and obs.obs_domain_cd_st_1 = 'C_Order'
          and lab214.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ','))
          and lab214.obs_domain_cd_st_1 = 'C_Result'
          and tdltn.followup_observation_uid is not null
          and lab214.observation_uid = ovt.observation_uid
          and tdltn.LAB_TEST_KEY IS NOT NULL;


        SELECT @RowCount_no = @@ROWCOUNT;

        UPDATE #Lab_Rpt_User_Comment_N
        SET USER_COMMENT_KEY= [LAB_COMMENT_id] +
                              coalesce((SELECT MAX(USER_COMMENT_KEY) FROM dbo.Lab_Rpt_User_Comment), 1)


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERTING INTO dbo.Lab_Rpt_User_Comment';


        insert into dbo.Lab_Rpt_User_Comment
        ( [USER_COMMENT_KEY]
        , [USER_RPT_COMMENTS]
        , [COMMENTS_FOR_ELR_DT]
        , [USER_COMMENT_CREATED_BY]
        , [LAB_TEST_KEY]
        , [RECORD_STATUS_CD]
        , [LAB_TEST_UID]
        , [RDB_LAST_REFRESH_TIME])
        select [USER_COMMENT_KEY]
             , rtrim(cast([USER_RPT_COMMENTS] AS varchar(2000)))
             , [COMMENTS_FOR_ELR_DT]
             , [USER_COMMENT_CREATED_BY]
             , [LAB_TEST_KEY]
             , rtrim(cast([RECORD_STATUS_CD] AS varchar(8)))
             , [LAB_TEST_UID]
             , [RDB_LAST_REFRESH_TIME]
        FROM #LAB_RPT_USER_COMMENT_N;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #Lab_Rpt_User_Comment_U ';


        IF OBJECT_ID('#Lab_Rpt_User_Comment_U', 'U') IS NOT NULL
            drop table #Lab_Rpt_User_Comment_U;

        CREATE TABLE #Lab_Rpt_User_Comment_U
        (
            [
            LAB_COMMENT_id]           [int] IDENTITY
                (
                1,
                1
                )                                     NOT NULL,
            [LAB_TEST_uid]            [bigint]        NULL,
            [COMMENTS_FOR_ELR_DT] [datetime]      NULL,
            [USER_COMMENT_CREATED_BY] [bigint]        NULL,
            [USER_RPT_COMMENTS]       [varchar](8000) NULL,
            [RECORD_STATUS_CD]        [varchar](8)    NOT NULL,
            [observation_uid]         [bigint]        NOT NULL,
            [RDB_LAST_REFRESH_TIME]   [datetime]      NULL
        ) ON [PRIMARY];


        INSERT INTO #Lab_Rpt_User_Comment_U
        select distinct tdltn.lab_rpt_uid as    LAB_TEST_uid,
                        lab214.activity_to_time 'COMMENTS_FOR_ELR_DT',
                        lab214.add_user_id      'USER_COMMENT_CREATED_BY',
                        CASE
                            WHEN REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ') = '' THEN NULL
                            ELSE REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')
                            END           AS    USER_RPT_COMMENTS,
                        tdltn.record_status_cd  'RECORD_STATUS_CD',
                        lab214.observation_uid,
                        getdate()
        from #D_LAB_TEST_U as tdltn,
             dbo.nrt_observation as obs,
             dbo.nrt_observation as lab214,
             dbo.nrt_observation_txt as ovt
        where ovt.ovt_value_txt is not null
          and obs.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ','))
          and obs.obs_domain_cd_st_1 = 'C_Order'
          and lab214.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ','))
          and lab214.obs_domain_cd_st_1 = 'C_Result'
          and tdltn.followup_observation_uid is not null
          and lab214.observation_uid = ovt.observation_uid;


        SELECT @RowCount_no = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'UPDATING dbo.Lab_Rpt_User_Comment';


        UPDATE
            lruc
        SET lruc.[USER_RPT_COMMENTS]       = rtrim(cast(lrucu.USER_RPT_COMMENTS AS varchar(2000)))
          , lruc.[COMMENTS_FOR_ELR_DT]     = lrucu.COMMENTS_FOR_ELR_DT
          , lruc.[USER_COMMENT_CREATED_BY] = lrucu.USER_COMMENT_CREATED_BY
          , lruc.[RECORD_STATUS_CD]        = rtrim(cast(lrucu.RECORD_STATUS_CD AS varchar(8)))
          , lruc.[LAB_TEST_UID]            = lrucu.LAB_TEST_UID
          , lruc.[RDB_LAST_REFRESH_TIME]   = lrucu.RDB_LAST_REFRESH_TIME
        FROM dbo.Lab_Rpt_User_Comment lruc,
             #LAB_RPT_USER_COMMENT_U lrucu
        WHERE lruc.lab_test_uid = lrucu.lab_test_uid;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Update Inactive LAB_TEST Records';


        /* Update records associated to Inactive Orders using Root Order UID. */

        UPDATE lt
        SET record_status_cd = 'INACTIVE'
        FROM
            dbo.LAB_TEST lt
        WHERE
            root_ordered_test_pntr IN
            (
                SELECT l.root_ordered_test_pntr
                FROM dbo.LAB_TEST l
                WHERE l.lab_test_type = 'Order'
                  AND l.record_status_cd = 'INACTIVE')
          AND record_status_cd <> 'INACTIVE';


        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Remove LAB_TEST Results';

        /* Remove records associated to Deleted Results. */
        IF EXISTS (SELECT 1 FROM dbo.LAB_TEST WHERE ROOT_ORDERED_TEST_PNTR = 1)
            BEGIN
                WITH removed_obs as (
                    select LAB_TEST_UID,
                           PARENT_TEST_PNTR,
                           ROOT_ORDERED_TEST_PNTR from dbo.LAB_TEST
                    where ROOT_ORDERED_TEST_PNTR = 1

                    UNION ALL

                    select lt.LAB_TEST_UID,
                           lt.PARENT_TEST_PNTR,
                           lt.ROOT_ORDERED_TEST_PNTR
                    from dbo.LAB_TEST lt
                             inner join removed_obs o on lt.PARENT_TEST_PNTR = o.LAB_TEST_UID
                )
                DELETE FROM dbo.LAB_TEST WHERE LAB_TEST_UID IN (SELECT LAB_TEST_UID FROM removed_obs);
            END


        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'D_LAB_TEST', 'D_LAB_TEST', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;

        IF
            OBJECT_ID('#s_edx_document1', 'U') IS NOT NULL
            drop table #s_edx_document1;

        IF
            OBJECT_ID('#LAB_TESTinit_a', 'U') IS NOT NULL
            drop table #LAB_TESTinit_a;

        IF
            OBJECT_ID('#s_edx_document', 'U') IS NOT NULL
            drop table #s_edx_document;

        IF
            OBJECT_ID('#LAB_TESTinit', 'U') IS NOT NULL
            drop table #LAB_TESTinit;

        IF
            OBJECT_ID('#LAB_TEST_mat_init', 'U') IS NOT NULL
            drop table #LAB_TEST_mat_init;

        IF
            OBJECT_ID('#OBS_REASON', 'U') IS NOT NULL
            drop table #OBS_REASON;

        IF
            OBJECT_ID('#OBS_REASON_FINAL', 'U') IS NOT NULL
            drop table #OBS_REASON_FINAL;

        IF
            OBJECT_ID('#LAB_TEST_oth', 'U') IS NOT NULL
            drop table #LAB_TEST_oth;

        IF
            OBJECT_ID('#LAB_TEST1_uid', 'U') IS NOT NULL
            drop table #LAB_TEST1_uid;

        IF
            OBJECT_ID('#LAB_TEST1_TMP', 'U') IS NOT NULL
            drop table #LAB_TEST1_TMP;

        IF
            OBJECT_ID('#LabReportMorb', 'U') IS NOT NULL
            drop table #LabReportMorb;

        IF
            OBJECT_ID('#Morb_OID', 'U') IS NOT NULL
            drop table #Morb_OID;

        IF
            OBJECT_ID('#LAB_TEST1_uid2', 'U') IS NOT NULL
            drop table #LAB_TEST1_uid2;

        IF
            OBJECT_ID('#LAB_TEST1', 'U') IS NOT NULL
            drop table #LAB_TEST1;

        IF
            OBJECT_ID('#R_Result_to_R_Order', 'U') IS NOT NULL
            drop table #R_Result_to_R_Order;

        IF
            OBJECT_ID('#R_Result_to_R_Order_to_Order', 'U') IS NOT NULL
            drop table #R_Result_to_R_Order_to_Order;

        IF
            OBJECT_ID('#LAB_TEST1_testuid', 'U') IS NOT NULL
            drop table #LAB_TEST1_testuid;

        IF
            OBJECT_ID('#LAB_TEST1_final', 'U') IS NOT NULL
            drop table #LAB_TEST1_final;

        IF
            OBJECT_ID('#R_Order_to_Result', 'U') IS NOT NULL
            drop table #R_Order_to_Result;

        IF
            OBJECT_ID('#LAB_TEST1_final_testuid', 'U') IS NOT NULL
            drop table #LAB_TEST1_final_testuid;

        IF
            OBJECT_ID('#LAB_TEST1_final_result', 'U') IS NOT NULL
            drop table #LAB_TEST1_final_result;

        IF
            OBJECT_ID('#Result_to_Order', 'U') IS NOT NULL
            drop table #Result_to_Order;

        IF
            OBJECT_ID('#LAB_TEST1_final_orderuid', 'U') IS NOT NULL
            drop table #LAB_TEST1_final_orderuid;

        IF
            OBJECT_ID('#LAB_TEST1_final_order', 'U') IS NOT NULL
            drop table #LAB_TEST1_final_order;

        IF
            OBJECT_ID('#LAB_TEST2', 'U') IS NOT NULL
            drop table #LAB_TEST2;

        IF
            OBJECT_ID('#LAB_TEST3', 'U') IS NOT NULL
            drop table #LAB_TEST3;

        IF
            OBJECT_ID('#LAB_TEST4', 'U') IS NOT NULL
            drop table #LAB_TEST4;

        IF
            OBJECT_ID('#order_test', 'U') IS NOT NULL
            drop table #order_test;

        IF
            OBJECT_ID('#LAB_TEST', 'U') IS NOT NULL
            drop table #LAB_TEST;

        IF
            OBJECT_ID('#Merge_Order', 'U') IS NOT NULL
            drop table #Merge_Order;

        IF
            OBJECT_ID('#LAB_TEST_final_root_ordered_test_pntr', 'U') IS NOT NULL
            drop table #LAB_TEST_final_root_ordered_test_pntr;

        IF
            OBJECT_ID('#LAB_TEST_final', 'U') IS NOT NULL
            drop table #LAB_TEST_final;

        IF
            OBJECT_ID('#L_LAB_TEST_N', 'U') IS NOT NULL
            drop table #L_LAB_TEST_N;

        IF
            OBJECT_ID('#Lab_Rpt_User_Comment', 'U') IS NOT NULL
            drop table #Lab_Rpt_User_Comment;



        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;

        SET
            @Proc_Step_Name = 'SP_COMPLETE';


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [row_count])
        VALUES ( @batch_id, 'D_LAB_TEST'
               , 'D_LAB_TEST'
               , 'COMPLETE'
               , @Proc_Step_no
               , @Proc_Step_name
               , @RowCount_no);


        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE
            @ErrorNumber INT = ERROR_NUMBER();
        DECLARE
            @ErrorLine INT = ERROR_LINE();
        DECLARE
            @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE
            @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE
            @ErrorState INT = ERROR_STATE();


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , 'D_LAB_TEST'
               , 'D_LAB_TEST'
               , 'ERROR'
               , @Proc_Step_no
               , 'ERROR - ' + @Proc_Step_name
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0);


        return -1;

    END CATCH

END;