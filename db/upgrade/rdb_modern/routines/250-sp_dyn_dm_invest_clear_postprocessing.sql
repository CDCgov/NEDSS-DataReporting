CREATE OR ALTER PROCEDURE dbo.sp_dyn_dm_invest_clear_postprocessing

    @batch_id BIGINT,
    @DATAMART_NAME VARCHAR(100), --HEPATITIS_A_ACUTE
    @debug bit = 'false'
AS
BEGIN
    BEGIN TRY


        DECLARE @RowCount_no INT ;
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;

        DECLARE @Dataflow_Name VARCHAR(100) = 'DYNAMIC_DATAMART POST-Processing' ;
        DECLARE @package_Name VARCHAR(100) = 'sp_dyn_dm_invest_clear_postprocessing: '+ @DATAMART_NAME;

        DECLARE @temp_sql nvarchar(max);
        DECLARE @datamart_suffix varchar(100) = @DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50));

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';


        INSERT INTO [dbo].[job_flow_log] (
                                           batch_id
                                         ,[Dataflow_Name]
                                         ,[package_Name]
                                         ,[Status_Type]
                                         ,[step_number]
                                         ,[step_name]
                                         ,[row_count]
        )
        VALUES
            (
              @batch_id
            ,@Dataflow_Name
            ,@package_Name
            ,'START'
            ,@Proc_Step_no
            ,@Proc_Step_Name
            ,0
            );


        BEGIN TRANSACTION;

        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'Drop persisted temp tables';


        IF OBJECT_ID('dbo.tmp_DynDm_Provider_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_Provider_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_Investigation_Data_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_Investigation_Data_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_Inactive_Investigations_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_Inactive_Investigations_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_INV_SUMM_DATAMART_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_INV_SUMM_DATAMART_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_Organization_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_Organization_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_Patient_Data_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_Patient_Data_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_Case_Management_Data_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_Case_Management_Data_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_Administrative_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_Administrative_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_CLINICAL_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_CLINICAL_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_CONTACT_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_CONTACT_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDM_D_INV_COMPLICATION_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDM_D_INV_COMPLICATION_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_DEATH_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_DEATH_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_EPIDEMIOLOGY_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_EPIDEMIOLOGY_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_HIV_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_HIV_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_PATIENT_OBS_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_PATIENT_OBS_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_ISOLATE_TRACKING_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_ISOLATE_TRACKING_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_LAB_FINDING_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_LAB_FINDING_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_MEDICAL_HISTORY_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_MEDICAL_HISTORY_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_MOTHER_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_MOTHER_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_OTHER_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_OTHER_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_PREGNANCY_BIRTH_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_PREGNANCY_BIRTH_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_RESIDENCY_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_RESIDENCY_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_RISK_FACTOR_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_RISK_FACTOR_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_SOCIAL_HISTORY_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_SOCIAL_HISTORY_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_SYMPTOM_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_SYMPTOM_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_TREATMENT_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_TREATMENT_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_TRAVEL_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_TRAVEL_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_UNDER_CONDITION_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_UNDER_CONDITION_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_VACCINATION_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_VACCINATION_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_STD_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_STD_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_DATE_ALL_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_REPEAT_BLOCK_DATE_ALL_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_REPEAT_BLOCK_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END

        IF OBJECT_ID('dbo.tmp_DynDm_INCOMING_DATA_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN
                SET @temp_sql = 'drop table dbo.tmp_DynDm_INCOMING_DATA_' + @datamart_suffix;
                exec sp_executesql @temp_sql;
            END


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@package_Name ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

        COMMIT TRANSACTION;

        --
--        BEGIN TRANSACTION;
--
--
--        declare @SQL varchar(max);
--
--        SET @SQL =   '    alter  table DBO.dbo.'+@DATAMART_NAME +'_T ' +
--                     '  drop column ' +
--            -- ' INVESTIGATION_KEY_INVESTIGATION_DATA , ' +
--            -- ' INVESTIGATION_KEY_PATIENT_DATA , ' +
--            -- ' INVESTIGATION_KEY_CASE_MANAGEMENT_DATA , ' +
--                     ' INVESTIGATION_KEY_D_INV_ADMINISTRATIVE , ' +
--                     ' INVESTIGATION_KEY_D_INV_CLINICAL , ' +
--                     ' INVESTIGATION_KEY_D_INV_COMPLICATION , ' +
--                     ' INVESTIGATION_KEY_D_INV_CONTACT , ' +
--                     ' INVESTIGATION_KEY_D_INV_DEATH , ' +
--                     ' INVESTIGATION_KEY_D_INV_EPIDEMIOLOGY , ' +
--                     ' INVESTIGATION_KEY_D_INV_HIV , ' +
--                     ' INVESTIGATION_KEY_D_INV_PATIENT_OBS , ' +
--                     ' INVESTIGATION_KEY_D_INV_ISOLATE_TRACKING , ' +
--                     ' INVESTIGATION_KEY_D_INV_LAB_FINDING , ' +
--                     ' INVESTIGATION_KEY_D_INV_MEDICAL_HISTORY , ' +
--                     ' INVESTIGATION_KEY_D_INV_MOTHER , ' +
--                     ' INVESTIGATION_KEY_D_INV_OTHER , ' +
--                     ' INVESTIGATION_KEY_D_INV_PREGNANCY_BIRTH , ' +
--                     ' INVESTIGATION_KEY_D_INV_RESIDENCY , ' +
--                     ' INVESTIGATION_KEY_D_INV_RISK_FACTOR , ' +
--                     ' INVESTIGATION_KEY_D_INV_SOCIAL_HISTORY , ' +
--                     ' INVESTIGATION_KEY_D_INV_SYMPTOM , ' +
--                     ' INVESTIGATION_KEY_D_INV_TREATMENT , ' +
--                     ' INVESTIGATION_KEY_D_INV_TRAVEL , ' +
--                     ' INVESTIGATION_KEY_D_INV_UNDER_CONDITION , ' +
--                     ' INVESTIGATION_KEY_D_INV_VACCINATION , ' +
--                     ' INVESTIGATION_KEY_D_INV_STD , ' +
--                     ' INVESTIGATION_KEY_ORGANIZATION , ' +
--                     ' INVESTIGATION_KEY_PROVIDER , ' +
--                     'PATIENT_LOCAL_ID_PATIENT_DATA ;'
--        ;
--
--
---- EXEC (@SQL) ;
--
--        COMMIT TRANSACTION;



        SET @Proc_Step_no = 99;
        SET @Proc_Step_Name = 'SP_COMPLETE';


        INSERT INTO [dbo].[job_flow_log] (
                                           batch_id
                                         ,[Dataflow_Name]
                                         ,[package_Name]
                                         ,[Status_Type]
                                         ,[step_number]
                                         ,[step_name]
                                         ,[row_count]
        )
        VALUES
            (
              @batch_id,
              @Dataflow_Name
            ,@package_Name
            ,'COMPLETE'
            ,@Proc_Step_no
            ,@Proc_Step_name
            ,@RowCount_no
            );



    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                COMMIT TRANSACTION;
            END;

        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) + -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        select @FullErrorMessage;

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
        VALUES( @Batch_id, @Dataflow_Name, @package_Name, 'ERROR',@Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0 );
        RETURN -1;

    END CATCH;
END;