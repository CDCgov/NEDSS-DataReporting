CREATE OR ALTER PROCEDURE dbo.sp_f_interview_case_postprocessing @ix_uids nvarchar(max),
                                                                @debug bit = 'false'
as

BEGIN

    DECLARE
        @RowCount_no INT;
    DECLARE
        @Proc_Step_no FLOAT = 0;
    DECLARE
        @Proc_Step_Name VARCHAR(200) = '';
    DECLARE
        @batch_id BIGINT;
    SET
        @batch_id = cast((format(getdate(), 'yyyyMMddHHmmss')) as bigint);

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET
            @Proc_Step_Name = 'SP_Start';

        BEGIN
            TRANSACTION;

        INSERT INTO dbo.job_flow_log ( batch_id
                                     , [Dataflow_Name]
                                     , [package_Name]
                                     , [Status_Type]
                                     , [step_number]
                                     , [step_name]
                                     , [row_count]
                                     , [Msg_Description1])
        VALUES ( @batch_id
               , 'F_INTERVIEW_CASE'
               , 'F_INTERVIEW_CASE'
               , 'START'
               , @Proc_Step_no
               , @Proc_Step_Name
               , 0
               , LEFT('ID List-' + @ix_uids, 500));

        COMMIT TRANSACTION;

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #L_INTERVIEW_INIT';

        SELECT
            INTERVIEW_UID,
            D_INTERVIEW_KEY
        INTO #L_INTERVIEW_INIT
        FROM dbo.nrt_interview_key
        WHERE INTERVIEW_UID IN (SELECT value FROM STRING_SPLIT(@ix_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #L_INTERVIEW_INIT;

        SELECT @RowCount_no = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'F_INTERVIEW_CASE', 'F_INTERVIEW_CASE', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #F_INTERVIEW_CASE_INIT';

        SELECT
            lix.D_INTERVIEW_KEY,
            lpat.PATIENT_KEY,
            COALESCE(lprov.PROVIDER_KEY, 1) AS IX_INTERVIEWER_KEY,
            linv.INVESTIGATION_KEY,
            CASE WHEN dintv.IX_INTERVIEWEE_ROLE_CD = 'INTERP' THEN COALESCE(lprov.PROVIDER_KEY, 1)
                ELSE 1
            END AS INTERPRETER_KEY,
            CASE WHEN dintv.IX_INTERVIEWEE_ROLE_CD = 'PHYS' THEN COALESCE(lprov.PROVIDER_KEY, 1)
                ELSE 1
            END AS PHYSICIAN_KEY,
            CASE WHEN dintv.IX_INTERVIEWEE_ROLE_CD = 'NURSE' THEN COALESCE(lprov.PROVIDER_KEY, 1)
                ELSE 1
            END AS NURSE_KEY,
            CASE WHEN dintv.IX_INTERVIEWEE_ROLE_CD = 'PROXY' THEN COALESCE(lprov.PROVIDER_KEY, 1)
                ELSE 1
            END AS PROXY_KEY,
            CASE WHEN dintv.IX_INTERVIEWEE_ROLE_CD = 'SUBJECT' THEN COALESCE(lpat.PATIENT_KEY, 1)
                ELSE 1
            END AS IX_INTERVIEWEE_KEY,
            COALESCE(lorg.ORGANIZATION_KEY, 1) AS INTERVENTION_SITE_KEY
            INTO #F_INTERVIEW_CASE_INIT
            FROM #L_INTERVIEW_INIT lix
                LEFT JOIN dbo.nrt_interview ix
                    ON ix.interview_uid = lix.INTERVIEW_UID
                LEFT JOIN D_INTERVIEW dintv
                    ON lix.D_INTERVIEW_KEY = dintv.D_INTERVIEW_KEY
                LEFT JOIN dbo.nrt_investigation inv
                    ON inv.public_health_case_uid = ix.investigation_uid
                LEFT JOIN dbo.INVESTIGATION linv
                    ON inv.public_health_case_uid = linv.CASE_UID
                LEFT JOIN DBO.D_PROVIDER lprov
                    ON lprov.PROVIDER_UID = ix.provider_uid
                LEFT JOIN DBO.D_ORGANIZATION lorg
                    ON lorg.ORGANIZATION_UID = ix.organization_uid
                LEFT JOIN DBO.D_PATIENT lpat
                    ON lpat.PATIENT_UID = ix.patient_uid;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_INTERVIEW_CASE_INIT;

        SELECT @RowCount_no = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'F_INTERVIEW_CASE', 'F_INTERVIEW_CASE', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = ' GENERATING #F_INTERVIEW_CASE_N';

        SELECT
            D_INTERVIEW_KEY,
            PATIENT_KEY,
            IX_INTERVIEWER_KEY,
            INVESTIGATION_KEY,
            INTERPRETER_KEY,
            PHYSICIAN_KEY,
            NURSE_KEY,
            PROXY_KEY,
            IX_INTERVIEWEE_KEY,
            INTERVENTION_SITE_KEY
        INTO #F_INTERVIEW_CASE_N
        FROM #F_INTERVIEW_CASE_INIT
            WHERE D_INTERVIEW_KEY NOT IN (SELECT D_INTERVIEW_KEY FROM dbo.F_INTERVIEW_CASE);
                

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_INTERVIEW_CASE_INIT;

        SELECT @RowCount_no = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'F_INTERVIEW_CASE', 'F_INTERVIEW_CASE', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERT INTO dbo.F_INTERVIEW_CASE';

        
        INSERT INTO dbo.F_INTERVIEW_CASE (
            D_INTERVIEW_KEY,
            PATIENT_KEY,
            IX_INTERVIEWER_KEY,
            INVESTIGATION_KEY,
            INTERPRETER_KEY,
            PHYSICIAN_KEY,
            NURSE_KEY,
            PROXY_KEY,
            IX_INTERVIEWEE_KEY,
            INTERVENTION_SITE_KEY
        )
        SELECT
            D_INTERVIEW_KEY,
            PATIENT_KEY,
            IX_INTERVIEWER_KEY,
            INVESTIGATION_KEY,
            INTERPRETER_KEY,
            PHYSICIAN_KEY,
            NURSE_KEY,
            PROXY_KEY,
            IX_INTERVIEWEE_KEY,
            INTERVENTION_SITE_KEY
        FROM #F_INTERVIEW_CASE_N;


        SELECT @RowCount_no = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'F_INTERVIEW_CASE', 'F_INTERVIEW_CASE', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'UPDATE dbo.F_INTERVIEW_CASE';

        
        UPDATE fic
            SET 
                fic.PATIENT_KEY = ficu.PATIENT_KEY,
                fic.IX_INTERVIEWER_KEY = ficu.IX_INTERVIEWER_KEY,
                fic.INVESTIGATION_KEY = ficu.INVESTIGATION_KEY,
                fic.INTERPRETER_KEY = ficu.INTERPRETER_KEY,
                fic.PHYSICIAN_KEY = ficu.PHYSICIAN_KEY,
                fic.NURSE_KEY = ficu.NURSE_KEY,
                fic.PROXY_KEY = ficu.PROXY_KEY,
                fic.IX_INTERVIEWEE_KEY = ficu.IX_INTERVIEWEE_KEY,
                fic.INTERVENTION_SITE_KEY = ficu.INTERVENTION_SITE_KEY
            FROM dbo.F_INTERVIEW_CASE fic
            INNER JOIN (SELECT
                D_INTERVIEW_KEY,
                PATIENT_KEY,
                IX_INTERVIEWER_KEY,
                INVESTIGATION_KEY,
                INTERPRETER_KEY,
                PHYSICIAN_KEY,
                NURSE_KEY,
                PROXY_KEY,
                IX_INTERVIEWEE_KEY,
                INTERVENTION_SITE_KEY
                FROM #F_INTERVIEW_CASE_INIT
                WHERE D_INTERVIEW_KEY NOT IN (SELECT D_INTERVIEW_KEY FROM #F_INTERVIEW_CASE_N)) ficu
            ON fic.D_INTERVIEW_KEY = ficu.D_INTERVIEW_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'F_INTERVIEW_CASE', 'F_INTERVIEW_CASE', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'F_INTERVIEW_CASE', 'F_INTERVIEW_CASE', 'COMPLETE', 999, 'COMPLETE', 0);
        

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
               , 'F_INTERVIEW_CASE'
               , 'F_INTERVIEW_CASE'
               , 'ERROR'
               , @Proc_Step_no
               , 'ERROR - ' + @Proc_Step_name
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0);


        return -1;

    END CATCH

END;
