CREATE OR ALTER PROCEDURE dbo.sp_nrt_case_management_postprocessing @id_list nvarchar(max), @debug bit = 'false'
AS
BEGIN

    BEGIN TRY

        /* Logging */
        declare @rowcount bigint;
        declare @proc_step_no float = 0;
        declare @proc_step_name varchar(200) = '';
        declare @batch_id bigint;
        declare @create_dttm datetime2(7) = current_timestamp;
        declare @update_dttm datetime2(7) = current_timestamp;
        declare @dataflow_name varchar(200) = 'Case Management POST-Processing';
        declare @package_name varchar(200) = 'sp_nrt_case_management_postprocessing';

        set @batch_id = cast((format(getdate(), 'yyMMddHHmmss')) as bigint);

        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[msg_description1]
        ,[row_count])
        VALUES (@batch_id
               ,@create_dttm
               ,@update_dttm
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,0
               ,'SP_Start'
               ,LEFT(@id_list, 500)
               ,0);

        SET @proc_step_name = 'Create CASE_MANAGEMENT Temp table -' + LEFT(@id_list, 160);
        SET @proc_step_no = 1;

        SELECT
               nrt.public_health_case_uid,
               nrt.act_ref_type_cd,
               nrt.add_user_id,
               nrt.adi_900_status_cd,
               nrt.adi_complexion,
               nrt.adi_ehars_id,
               nrt.adi_hair,
               nrt.adi_height,
               nrt.adi_height_legacy_case,
               nrt.adi_other_identifying_info,
               nrt.adi_size_build,
               nrt.ca_init_intvwr_assgn_dt,
               nrt.ca_interviewer_assign_dt,
               nrt.ca_patient_intv_status,
               nrt.case_oid,
               nrt.case_review_status,
               nrt.case_review_status_date,
               nrt.cc_closed_dt,
               dim.D_CASE_MANAGEMENT_KEY,
               nrt.epi_link_id,
               nrt.field_foll_up_ooj_outcome,
               nrt.fl_fup_actual_ref_type,
               nrt.fl_fup_dispo_dt,
               nrt.fl_fup_disposition_cd,
               nrt.fl_fup_disposition_desc,
               nrt.fl_fup_exam_dt,
               nrt.fl_fup_expected_dt,
               nrt.fl_fup_expected_in_ind,
               nrt.fl_fup_field_record_num,
               nrt.fl_fup_init_assgn_dt,
               nrt.fl_fup_internet_outcome,
               nrt.fl_fup_internet_outcome_cd,
               nrt.fl_fup_investigator_assgn_dt,
               nrt.fl_fup_notification_plan_cd,
               nrt.fl_fup_ooj_outcome,
               nrt.fl_fup_prov_diagnosis,
               nrt.fl_fup_prov_exm_reason,
               nrt.fld_foll_up_expected_in,
               nrt.fld_foll_up_notification_plan,
               nrt.fld_foll_up_prov_diagnosis,
               nrt.fld_foll_up_prov_exm_reason,
               nrt.init_fup_clinic_code,
               nrt.init_fup_closed_dt,
               nrt.init_fup_initial_foll_up,
               nrt.init_fup_initial_foll_up_cd,
               nrt.init_fup_internet_foll_up_cd,
               LEFT(nrt.init_foll_up_notifiable, 27) AS init_foll_up_notifiable,
               nrt.init_fup_notifiable_cd,
               LEFT(nrt.initiating_agncy, 20) AS initiating_agncy,
               nrt.internet_foll_up,
               inv.INVESTIGATION_KEY,
               LEFT(nrt.ooj_agency, 20) AS ooj_agency,
               nrt.ooj_due_date,
               nrt.ooj_initg_agncy_outc_due_date,
               nrt.ooj_initg_agncy_outc_snt_date,
               nrt.ooj_initg_agncy_recd_date,
               nrt.ooj_number,
               nrt.pat_intv_status_cd,
               nrt.status_900,
               nrt.surv_closed_dt,
               nrt.surv_investigator_assgn_dt,
               nrt.surv_patient_foll_up,
               nrt.surv_patient_foll_up_cd,
               nrt.surv_prov_exm_reason,
               nrt.surv_provider_contact,
               nrt.surv_provider_contact_cd,
               nrt.surv_provider_diagnosis,
               nrt.surv_provider_exam_reason
        INTO #temp_cm_table
        FROM dbo.nrt_investigation_case_management nrt WITH (NOLOCK)
            INNER JOIN dbo.INVESTIGATION inv WITH (NOLOCK) ON inv.CASE_UID = nrt.public_health_case_uid
            LEFT JOIN dbo.D_CASE_MANAGEMENT dim WITH (NOLOCK) ON dim.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
        WHERE nrt.public_health_case_uid IN (SELECT value FROM STRING_SPLIT(@id_list, ','));

        if @debug = 'true' select * from #temp_cm_table;

        /* Logging */
        set @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500));

        /* Investigation Update Operation */
        BEGIN TRANSACTION;
        SET @proc_step_name = 'Update D_CASE_MANAGEMENT';
        SET @proc_step_no = 2;

        UPDATE dbo.D_CASE_MANAGEMENT
        SET
            ACT_REF_TYPE_CD = cmt.act_ref_type_cd,
            ADD_USER_ID = cmt.add_user_id,
            ADI_900_STATUS_CD = cmt.adi_900_status_cd,
            ADI_COMPLEXION = cmt.adi_complexion,
            ADI_EHARS_ID = cmt.adi_ehars_id,
            ADI_HAIR = cmt.adi_hair,
            ADI_HEIGHT = cmt.adi_height,
            ADI_HEIGHT_LEGACY_CASE = cmt.adi_height_legacy_case,
            ADI_OTHER_IDENTIFYING_INFO = cmt.adi_other_identifying_info,
            ADI_SIZE_BUILD = cmt.adi_size_build,
            CA_INIT_INTVWR_ASSGN_DT = cmt.ca_init_intvwr_assgn_dt,
            CA_INTERVIEWER_ASSIGN_DT = cmt.ca_interviewer_assign_dt,
            CA_PATIENT_INTV_STATUS = cmt.ca_patient_intv_status,
            CASE_OID = cmt.case_oid,
            CASE_REVIEW_STATUS = cmt.case_review_status,
            CASE_REVIEW_STATUS_DATE = cmt.case_review_status_date,
            CC_CLOSED_DT = cmt.cc_closed_dt,
            EPI_LINK_ID = cmt.epi_link_id,
            FIELD_FOLL_UP_OOJ_OUTCOME = cmt.field_foll_up_ooj_outcome,
            FL_FUP_ACTUAL_REF_TYPE = cmt.fl_fup_actual_ref_type,
            FL_FUP_DISPO_DT = cmt.fl_fup_dispo_dt,
            FL_FUP_DISPOSITION_CD = cmt.fl_fup_disposition_cd,
            FL_FUP_DISPOSITION_DESC = cmt.fl_fup_disposition_desc,
            FL_FUP_EXAM_DT = cmt.fl_fup_exam_dt,
            FL_FUP_EXPECTED_DT = cmt.fl_fup_expected_dt,
            FL_FUP_EXPECTED_IN_IND = cmt.fl_fup_expected_in_ind,
            FL_FUP_FIELD_RECORD_NUM = cmt.fl_fup_field_record_num,
            FL_FUP_INIT_ASSGN_DT = cmt.fl_fup_init_assgn_dt,
            FL_FUP_INTERNET_OUTCOME = cmt.fl_fup_internet_outcome,
            FL_FUP_INTERNET_OUTCOME_CD = cmt.fl_fup_internet_outcome_cd,
            FL_FUP_INVESTIGATOR_ASSGN_DT = cmt.fl_fup_investigator_assgn_dt,
            FL_FUP_NOTIFICATION_PLAN_CD = cmt.fl_fup_notification_plan_cd,
            FL_FUP_OOJ_OUTCOME = cmt.fl_fup_ooj_outcome,
            FL_FUP_PROV_DIAGNOSIS = cmt.fl_fup_prov_diagnosis,
            FL_FUP_PROV_EXM_REASON = cmt.fl_fup_prov_exm_reason,
            FLD_FOLL_UP_EXPECTED_IN = cmt.fld_foll_up_expected_in,
            FLD_FOLL_UP_NOTIFICATION_PLAN = cmt.fld_foll_up_notification_plan,
            FLD_FOLL_UP_PROV_DIAGNOSIS = cmt.fld_foll_up_prov_diagnosis,
            FLD_FOLL_UP_PROV_EXM_REASON = cmt.fld_foll_up_prov_exm_reason,
            INIT_FUP_CLINIC_CODE = cmt.init_fup_clinic_code,
            INIT_FUP_CLOSED_DT = cmt.init_fup_closed_dt,
            INIT_FUP_INITIAL_FOLL_UP = cmt.init_fup_initial_foll_up,
            INIT_FUP_INITIAL_FOLL_UP_CD = cmt.init_fup_initial_foll_up_cd,
            INIT_FUP_INTERNET_FOLL_UP_CD = cmt.init_fup_internet_foll_up_cd,
            INIT_FOLL_UP_NOTIFIABLE = cmt.init_foll_up_notifiable,
            INIT_FUP_NOTIFIABLE_CD = cmt.init_fup_notifiable_cd,
            INITIATING_AGNCY = cmt.initiating_agncy,
            INTERNET_FOLL_UP = cmt.internet_foll_up,
            OOJ_AGENCY = cmt.ooj_agency,
            OOJ_DUE_DATE = cmt.ooj_due_date,
            OOJ_INITG_AGNCY_OUTC_DUE_DATE = cmt.ooj_initg_agncy_outc_due_date,
            OOJ_INITG_AGNCY_OUTC_SNT_DATE = cmt.ooj_initg_agncy_outc_snt_date,
            OOJ_INITG_AGNCY_RECD_DATE = cmt.ooj_initg_agncy_recd_date,
            OOJ_NUMBER = cmt.ooj_number,
            PAT_INTV_STATUS_CD = cmt.pat_intv_status_cd,
            STATUS_900 = cmt.status_900,
            SURV_CLOSED_DT = cmt.surv_closed_dt,
            SURV_INVESTIGATOR_ASSGN_DT = cmt.surv_investigator_assgn_dt,
            SURV_PATIENT_FOLL_UP = cmt.surv_patient_foll_up,
            SURV_PATIENT_FOLL_UP_CD = cmt.surv_patient_foll_up_cd,
            SURV_PROV_EXM_REASON = cmt.surv_prov_exm_reason,
            SURV_PROVIDER_CONTACT = cmt.surv_provider_contact,
            SURV_PROVIDER_CONTACT_CD = cmt.surv_provider_contact_cd,
            SURV_PROVIDER_DIAGNOSIS = cmt.surv_provider_diagnosis,
            SURV_PROVIDER_EXAM_REASON = cmt.surv_provider_exam_reason
        FROM #temp_cm_table cmt
            INNER JOIN dbo.D_CASE_MANAGEMENT d WITH (NOLOCK)
                ON d.D_CASE_MANAGEMENT_KEY = cmt.D_CASE_MANAGEMENT_KEY
                       AND cmt.D_CASE_MANAGEMENT_KEY IS NOT NULL;


        /* Logging */
        set @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500));

        /* Investigation Insert Operation */
        SET @proc_step_name = 'Insert into D_CASE_MANAGEMENT';
        SET @proc_step_no = 3;

        -- delete from the key table to generate new keys for the resulting new data to be inserted
        DELETE FROM dbo.nrt_case_management_key;
        INSERT INTO dbo.nrt_case_management_key(public_health_case_uid)
        SELECT public_health_case_uid
        FROM #temp_cm_table
        WHERE D_CASE_MANAGEMENT_KEY is null
        ORDER BY public_health_case_uid;

        if @debug = 'true' select * from dbo.nrt_case_management_key;

        INSERT INTO dbo.D_CASE_MANAGEMENT
            (ACT_REF_TYPE_CD,
             ADD_USER_ID,
             ADI_900_STATUS_CD,
             ADI_COMPLEXION,
             ADI_EHARS_ID,
             ADI_HAIR,
             ADI_HEIGHT,
             ADI_HEIGHT_LEGACY_CASE,
             ADI_OTHER_IDENTIFYING_INFO,
             ADI_SIZE_BUILD,
             CA_INIT_INTVWR_ASSGN_DT,
             CA_INTERVIEWER_ASSIGN_DT,
             CA_PATIENT_INTV_STATUS,
             CASE_OID,
             CASE_REVIEW_STATUS,
             CASE_REVIEW_STATUS_DATE,
             CC_CLOSED_DT,
             D_CASE_MANAGEMENT_KEY,
             EPI_LINK_ID,
             FIELD_FOLL_UP_OOJ_OUTCOME,
             FL_FUP_ACTUAL_REF_TYPE,
             FL_FUP_DISPO_DT,
             FL_FUP_DISPOSITION_CD,
             FL_FUP_DISPOSITION_DESC,
             FL_FUP_EXAM_DT,
             FL_FUP_EXPECTED_DT,
             FL_FUP_EXPECTED_IN_IND,
             FL_FUP_FIELD_RECORD_NUM,
             FL_FUP_INIT_ASSGN_DT,
             FL_FUP_INTERNET_OUTCOME,
             FL_FUP_INTERNET_OUTCOME_CD,
             FL_FUP_INVESTIGATOR_ASSGN_DT,
             FL_FUP_NOTIFICATION_PLAN_CD,
             FL_FUP_OOJ_OUTCOME,
             FL_FUP_PROV_DIAGNOSIS,
             FL_FUP_PROV_EXM_REASON,
             FLD_FOLL_UP_EXPECTED_IN,
             FLD_FOLL_UP_NOTIFICATION_PLAN,
             FLD_FOLL_UP_PROV_DIAGNOSIS,
             FLD_FOLL_UP_PROV_EXM_REASON,
             INIT_FUP_CLINIC_CODE,
             INIT_FUP_CLOSED_DT,
             INIT_FUP_INITIAL_FOLL_UP,
             INIT_FUP_INITIAL_FOLL_UP_CD,
             INIT_FUP_INTERNET_FOLL_UP_CD,
             INIT_FOLL_UP_NOTIFIABLE,
             INIT_FUP_NOTIFIABLE_CD,
             INITIATING_AGNCY,
             INTERNET_FOLL_UP,
             INVESTIGATION_KEY,
             OOJ_AGENCY,
             OOJ_DUE_DATE,
             OOJ_INITG_AGNCY_OUTC_DUE_DATE,
             OOJ_INITG_AGNCY_OUTC_SNT_DATE,
             OOJ_INITG_AGNCY_RECD_DATE,
             OOJ_NUMBER,
             PAT_INTV_STATUS_CD,
             STATUS_900,
             SURV_CLOSED_DT,
             SURV_INVESTIGATOR_ASSGN_DT,
             SURV_PATIENT_FOLL_UP,
             SURV_PATIENT_FOLL_UP_CD,
             SURV_PROV_EXM_REASON,
             SURV_PROVIDER_CONTACT,
             SURV_PROVIDER_CONTACT_CD,
             SURV_PROVIDER_DIAGNOSIS,
             SURV_PROVIDER_EXAM_REASON)
        SELECT
            cmt.act_ref_type_cd,
            cmt.add_user_id,
            cmt.adi_900_status_cd,
            cmt.adi_complexion,
            cmt.adi_ehars_id,
            cmt.adi_hair,
            cmt.adi_height,
            cmt.adi_height_legacy_case,
            cmt.adi_other_identifying_info,
            cmt.adi_size_build,
            cmt.ca_init_intvwr_assgn_dt,
            cmt.ca_interviewer_assign_dt,
            cmt.ca_patient_intv_status,
            cmt.case_oid,
            cmt.case_review_status,
            cmt.case_review_status_date,
            cmt.cc_closed_dt,
            k.D_CASE_MANAGEMENT_KEY,
            cmt.epi_link_id,
            cmt.field_foll_up_ooj_outcome,
            cmt.fl_fup_actual_ref_type,
            cmt.fl_fup_dispo_dt,
            cmt.fl_fup_disposition_cd,
            cmt.fl_fup_disposition_desc,
            cmt.fl_fup_exam_dt,
            cmt.fl_fup_expected_dt,
            cmt.fl_fup_expected_in_ind,
            cmt.fl_fup_field_record_num,
            cmt.fl_fup_init_assgn_dt,
            cmt.fl_fup_internet_outcome,
            cmt.fl_fup_internet_outcome_cd,
            cmt.fl_fup_investigator_assgn_dt,
            cmt.fl_fup_notification_plan_cd,
            cmt.fl_fup_ooj_outcome,
            cmt.fl_fup_prov_diagnosis,
            cmt.fl_fup_prov_exm_reason,
            cmt.fld_foll_up_expected_in,
            cmt.fld_foll_up_notification_plan,
            cmt.fld_foll_up_prov_diagnosis,
            cmt.fld_foll_up_prov_exm_reason,
            cmt.init_fup_clinic_code,
            cmt.init_fup_closed_dt,
            cmt.init_fup_initial_foll_up,
            cmt.init_fup_initial_foll_up_cd,
            cmt.init_fup_internet_foll_up_cd,
            cmt.init_foll_up_notifiable,
            cmt.init_fup_notifiable_cd,
            cmt.initiating_agncy,
            cmt.internet_foll_up,
            cmt.INVESTIGATION_KEY,
            cmt.ooj_agency,
            cmt.ooj_due_date,
            cmt.ooj_initg_agncy_outc_due_date,
            cmt.ooj_initg_agncy_outc_snt_date,
            cmt.ooj_initg_agncy_recd_date,
            cmt.ooj_number,
            cmt.pat_intv_status_cd,
            cmt.status_900,
            cmt.surv_closed_dt,
            cmt.surv_investigator_assgn_dt,
            cmt.surv_patient_foll_up,
            cmt.surv_patient_foll_up_cd,
            cmt.surv_prov_exm_reason,
            cmt.surv_provider_contact,
            cmt.surv_provider_contact_cd,
            cmt.surv_provider_diagnosis,
            cmt.surv_provider_exam_reason
        FROM #temp_cm_table cmt
            JOIN dbo.nrt_case_management_key k with (nolock) ON cmt.public_health_case_uid = k.public_health_case_uid
        WHERE cmt.D_CASE_MANAGEMENT_KEY IS NULL;

        /* Logging */
        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500)
               );

        COMMIT TRANSACTION;
        /* Logging */
        set @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,@dataflow_name
               ,@package_name
               ,'COMPLETE'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500));

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        /* Logging */
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,current_timestamp
               ,current_timestamp
               ,@dataflow_name
               ,@package_name
               ,'ERROR'
               ,@Proc_Step_no
               ,'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               ,0
               ,LEFT(@id_list, 500));

        return @ErrorMessage;

    END CATCH

END;