CREATE OR ALTER PROCEDURE [dbo].[sp_treatment_event_copy]
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
        SET @batch_id = CAST((FORMAT(GETDATE(), 'yyMMddHHmmssffff')) AS BIGINT);

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
            -- Leaving column in until updates to postprocessing are done to keep liquibase
            -- run from failing in the meantime
            NULL AS public_health_case_uid,
            par.subject_entity_uid AS organization_uid,
            par1.subject_entity_uid AS provider_uid,
            viewPatientKeys.treatment_uid AS patient_treatment_uid,
            act1.target_act_uid AS morbidity_uid,
            rx1.local_id,
            rx1.add_time,
            rx1.add_user_id,
            rx1.last_chg_time,
            rx1.last_chg_user_id,
            rx1.version_ctrl_nbr
        INTO #TREATMENT_UIDS
        FROM NBS_ODSE.dbo.treatment AS rx1 WITH (NOLOCK)
                 INNER JOIN NBS_ODSE.dbo.Treatment_administered AS rx2 WITH (NOLOCK)
                            ON rx1.treatment_uid = rx2.treatment_uid
                --  LEFT JOIN NBS_ODSE.dbo.act_relationship AS act1 WITH (NOLOCK)
                --            ON rx1.Treatment_uid = act1.source_act_uid
                --                AND act1.target_class_cd = 'CASE'
                --                AND act1.source_class_cd = 'TRMT'
                --                AND act1.type_cd = 'TreatmentToPHC'
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
                 LEFT JOIN NBS_ODSE.dbo.act_relationship AS act1 WITH (NOLOCK)
                           ON rx1.Treatment_uid = act1.source_act_uid
                               AND act1.target_class_cd = 'OBS'
                               AND act1.source_class_cd = 'TRMT'
                               AND act1.type_cd = 'TreatmentToMorb'
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

        -- STEP 2: CREATE #ASSOCIATED_PHC_UIDS
        BEGIN TRANSACTION;
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'CREATING #ASSOCIATED_PHC_UIDS';

        SELECT DISTINCT
            source_act_uid as treatment_uid,
            STRING_AGG(target_act_uid, ',') AS associated_phc_uids
        INTO #ASSOCIATED_PHC_UIDS
        FROM NBS_ODSE.dbo.act_relationship WITH (NOLOCK)
            where source_act_uid IN (
            SELECT value
            FROM STRING_SPLIT(@treatment_uids, ',')
        )
            AND target_class_cd = 'CASE'
            AND source_class_cd = 'TRMT'
            AND type_cd = 'TreatmentToPHC'
            GROUP BY source_act_uid
        ;

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

        -- STEP 3: Get Treatment Details
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
            rx1.cd_desc_txt AS treatment_name,
            rx1.program_jurisdiction_oid AS treatment_oid,
            REPLACE(REPLACE(rx1.txt, CHAR(13) + CHAR(10), ' '), CHAR(10), ' ') AS treatment_comments,
            rx1.shared_ind AS treatment_shared_ind,
            rx1.cd,
            rx2.effective_from_time AS treatment_date,
            rx2.cd AS treatment_drug,
            rx2.cd_desc_txt AS treatment_drug_name,
            rx2.dose_qty AS treatment_dosage_strength,
            rx2.dose_qty_unit_cd AS treatment_dosage_strength_unit,
            rx2.interval_cd AS treatment_frequency,
            rx2.effective_duration_amt AS treatment_duration,
            rx2.effective_duration_unit_cd AS treatment_duration_unit,
            rx2.route_cd AS treatment_route,
            t.local_id,
            dbo.fn_get_record_status(rx1.record_status_cd) as record_status_cd,
            t.add_time,
            t.add_user_id,
            t.last_chg_time,
            t.last_chg_user_id,
            t.version_ctrl_nbr,
            aphc.associated_phc_uids
        INTO #TREATMENT_DETAILS
        FROM #TREATMENT_UIDS t
                 LEFT JOIN #ASSOCIATED_PHC_UIDS aphc
                            ON t.treatment_uid = aphc.treatment_uid 
                 INNER JOIN NBS_ODSE.dbo.treatment rx1 WITH (NOLOCK)
                            ON t.treatment_uid = rx1.treatment_uid
                 INNER JOIN NBS_ODSE.dbo.Treatment_administered rx2 WITH (NOLOCK)
                            ON rx1.treatment_uid = rx2.treatment_uid
                    ;

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


        -- STEP 4: Final Output
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
            t.treatment_name,
            t.treatment_oid,
            t.treatment_comments,
            t.treatment_shared_ind,
            t.cd,
            t.treatment_date,
            t.treatment_drug,
            t.treatment_drug_name,
            t.treatment_dosage_strength,
            t.treatment_dosage_strength_unit,
            t.treatment_frequency,
            t.treatment_duration,
            t.treatment_duration_unit,
            t.treatment_route,
            t.local_id,
            t.record_status_cd,
            t.add_time,
            t.add_user_id,
            t.last_chg_time,
            t.last_chg_user_id,
            t.version_ctrl_nbr,
            t.associated_phc_uids
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
