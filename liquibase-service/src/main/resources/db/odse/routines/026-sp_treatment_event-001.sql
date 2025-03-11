CREATE OR ALTER PROCEDURE [dbo].[sp_treatment_event]
    @treatment_uids nvarchar(max),
    @debug bit = 'false'
AS
BEGIN

    DECLARE @DATAFLOW_NAME VARCHAR(100) = 'Treatment PRE-Processing Event';
    DECLARE @PACKAGE_NAME VARCHAR(100) = 'NBS_ODSE.sp_treatment_event';
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';

    BEGIN TRY
        DECLARE @batch_id BIGINT;
        SET @batch_id = CAST((FORMAT(GETDATE(), 'yyMMddHHmmss')) AS BIGINT);

        -- Initial log entry
        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Msg_Description1])
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'START',
                   0,
                   LEFT('Pre ID-' + @treatment_uids, 199),
                   0,
                   LEFT(@treatment_uids, 199)
               );

        -- STEP 1: Get base UIDs
        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'COLLECTING BASE UIDS';

        SELECT DISTINCT
            rx1.treatment_uid,
            act1.target_act_uid AS public_health_case_uid,
            par.subject_entity_uid AS organization_uid,
            par1.subject_entity_uid AS provider_uid,
            viewPatientKeys.treatment_uid AS patient_treatment_uid,
            act2.target_act_uid AS morbidity_uid,
            rx1.LOCAL_ID,
            rx1.ADD_TIME,
            rx1.ADD_USER_ID,
            rx1.LAST_CHG_TIME,
            rx1.LAST_CHG_USER_ID,
            rx1.VERSION_CTRL_NBR
        INTO #TREATMENT_UIDS
        FROM NBS_ODSE.dbo.treatment AS rx1 WITH (NOLOCK)
                 INNER JOIN NBS_ODSE.dbo.Treatment_administered AS rx2 WITH (NOLOCK)
                            ON rx1.treatment_uid = rx2.treatment_uid
                 LEFT JOIN NBS_ODSE.dbo.act_relationship AS act1 WITH (NOLOCK)
                           ON rx1.Treatment_uid = act1.source_act_uid
                               AND act1.target_class_cd = 'CASE'
                               AND act1.source_class_cd = 'TRMT'
                               AND act1.type_cd = 'TreatmentToPHC'
                 LEFT JOIN NBS_ODSE.dbo.participation AS par WITH (NOLOCK)
                           ON rx1.Treatment_uid = par.act_uid
                               AND par.type_cd = 'ReporterOfTrmt'
                               AND par.subject_class_cd = 'ORG'
                               AND par.act_class_cd = 'TRMT'
                 LEFT JOIN NBS_ODSE.dbo.participation AS par1 WITH (NOLOCK)
                           ON rx1.Treatment_uid = par1.act_uid
                               AND par1.type_cd = 'ProviderOfTrmt'
                               AND par1.subject_class_cd = 'PSN'
                               AND par1.act_class_cd = 'TRMT'
                 LEFT JOIN NBS_ODSE.dbo.uvw_treatment_patient_keys AS viewPatientKeys WITH (NOLOCK)
                           ON rx1.treatment_uid = viewPatientKeys.treatment_uid
                 LEFT JOIN NBS_ODSE.dbo.act_relationship AS act2 WITH (NOLOCK)
                           ON rx1.Treatment_uid = act2.source_act_uid
                               AND act2.target_class_cd = 'OBS'
                               AND act2.source_class_cd = 'TRMT'
                               AND act2.type_cd = 'TreatmentToMorb'
        WHERE rx1.treatment_uid IN (
            SELECT value
            FROM STRING_SPLIT(@treatment_uids, ',')
        );

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count])
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'START',
                   @Proc_Step_no,
                   @Proc_Step_Name,
                   @RowCount_no
               );
        COMMIT TRANSACTION;

        -- STEP 2: Get Treatment Details
        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'COLLECTING TREATMENT DETAILS';

        SELECT
            t.treatment_uid,
            t.public_health_case_uid,
            t.organization_uid,
            t.provider_uid,
            t.patient_treatment_uid,
            t.morbidity_uid,
            rx1.cd_desc_txt AS Treatment_nm,
            rx1.program_jurisdiction_oid AS Treatment_oid,
            REPLACE(REPLACE(rx1.txt, CHAR(13) + CHAR(10), ' '), CHAR(10), ' ') AS Treatment_comments,
            rx1.shared_ind AS Treatment_shared_ind,
            rx1.cd,
            rx2.effective_from_time AS Treatment_dt,
            rx2.cd AS Treatment_drug,
            rx2.cd_desc_txt AS Treatment_drug_nm,
            rx2.dose_qty AS Treatment_dosage_strength,
            rx2.dose_qty_unit_cd AS Treatment_dosage_strength_unit,
            rx2.interval_cd AS Treatment_frequency,
            rx2.effective_duration_amt AS Treatment_duration,
            rx2.effective_duration_unit_cd AS Treatment_duration_unit,
            rx2.route_cd AS Treatment_route,
            t.LOCAL_ID,
            CASE
                WHEN rx1.record_status_cd = '' THEN 'ACTIVE'
                WHEN rx1.record_status_cd = 'LOG_DEL' THEN 'INACTIVE'
                ELSE rx1.record_status_cd
                END as record_status_cd,
            t.ADD_TIME,
            t.ADD_USER_ID,
            t.LAST_CHG_TIME,
            t.LAST_CHG_USER_ID,
            t.VERSION_CTRL_NBR
        INTO #TREATMENT_DETAILS
        FROM #TREATMENT_UIDS t
                 INNER JOIN NBS_ODSE.dbo.treatment rx1 WITH (NOLOCK)
                            ON t.treatment_uid = rx1.treatment_uid
                 INNER JOIN NBS_ODSE.dbo.Treatment_administered rx2 WITH (NOLOCK)
                            ON rx1.treatment_uid = rx2.treatment_uid;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'START',
                   @Proc_Step_no,
                   @Proc_Step_Name,
                   @RowCount_no
               );
        COMMIT TRANSACTION;

        -- STEP 3: Final Output
        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'GENERATING FINAL OUTPUT';

        SELECT
            t.treatment_uid,
            t.public_health_case_uid,
            t.organization_uid,
            t.provider_uid,
            t.morbidity_uid,
            t.patient_treatment_uid,
            t.Treatment_nm,
            t.Treatment_oid,
            t.Treatment_comments,
            t.Treatment_shared_ind,
            t.cd,
            t.Treatment_dt,
            t.Treatment_drug,
            t.Treatment_drug_nm,
            t.Treatment_dosage_strength,
            t.Treatment_dosage_strength_unit,
            t.Treatment_frequency,
            t.Treatment_duration,
            t.Treatment_duration_unit,
            t.Treatment_route,
            t.LOCAL_ID,
            t.record_status_cd,
            t.ADD_TIME,
            t.ADD_USER_ID,
            t.LAST_CHG_TIME,
            t.LAST_CHG_USER_ID,
            t.VERSION_CTRL_NBR
        FROM #TREATMENT_DETAILS t;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'START',
                   @Proc_Step_no,
                   @Proc_Step_Name,
                   @RowCount_no
               );
        COMMIT TRANSACTION;

        -- Log successful completion
        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count],[Msg_Description1])
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'COMPLETE',
                   @PROC_STEP_NO,
                   @Proc_Step_Name,
                   0,
                   LEFT(@treatment_uids, 199)
               );
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Msg_Description1],
          [Error_Description])
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'ERROR',
                   @PROC_STEP_NO,
                   @PROC_STEP_NAME,
                   0,
                   LEFT(@treatment_uids, 199),
                   @ErrorMessage
               );

        return @ErrorMessage;
    END CATCH
END;
