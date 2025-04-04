CREATE OR ALTER PROCEDURE dbo.sp_dyn_dm_invest_clear_postprocessing

    @batch_id BIGINT,
    @DATAMART_NAME VARCHAR(100),
    @debug bit = 'false'
AS
BEGIN
    BEGIN TRY


        DECLARE @RowCount_no INT ;
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;

        DECLARE @Dataflow_Name VARCHAR(100) = 'DYNAMIC_DATAMART POST=PROCESSING' ;
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


        IF OBJECT_ID('dbo.tmp_DynDm_Provider_Metadata_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_Provider_Metadata_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        --        IF OBJECT_ID('dbo.tmp_DynDm_ProvPart_Table_temp'+@datamart_suffix, 'U') IS NOT NULL
--        	SET @temp_sql = 'drop table dbo.tmp_DynDm_ProvPart_Table_temp' + @datamart_suffix;
--        	exec sp_executesql @temp_sql;
--
        IF OBJECT_ID('dbo.tmp_DynDm_Investigation_Data'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_Investigation_Data' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_OrgPart_Table_temp'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_OrgPart_Table_temp' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_Organization'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_Organization' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_Patient_Data_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_Patient_Data_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_Case_Management_Data_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_Case_Management_Data_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_Administrative_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_Administrative_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_CLINICAL'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_CLINICAL' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_CONTACT_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_CONTACT_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_DEATH_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_DEATH_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_EPIDEMIOLOGY_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_EPIDEMIOLOGY_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_HIV_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_HIV_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_PATIENT_OBS_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_PATIENT_OBS_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_ISOLATE_TRACKING_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_ISOLATE_TRACKING_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_LAB_FINDING_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_LAB_FINDING_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_MEDICAL_HISTORY_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_MEDICAL_HISTORY_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_MOTHER_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_MOTHER_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_OTHER_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_OTHER_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_PREGNANCY_BIRTH_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_PREGNANCY_BIRTH_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_RESIDENCY_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_RESIDENCY_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_RISK_FACTOR_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_RISK_FACTOR_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_SOCIAL_HISTORY_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_SOCIAL_HISTORY_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_SYMPTOM_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_SYMPTOM_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_TREATMENT_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_TREATMENT_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_TRAVEL_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_TRAVEL_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_UNDER_CONDITION_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_UNDER_CONDITION_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_VACCINATION_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_VACCINATION_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_STD_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_D_INV_STD_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_PROVIDER_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_PROVIDER_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_PROVIDER_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_PROVIDER_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_DATE_ALL_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_REPEAT_BLOCK_DATE_ALL_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_'+@datamart_suffix, 'U') IS NOT NULL
            SET @temp_sql = 'drop table dbo.tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_' + @datamart_suffix;
        exec sp_executesql @temp_sql;

        --
--        IF OBJECT_ID('dbo.tmp_DynDm_Provider_Metadata', 'U') IS NOT NULL drop table dbo.tmp_DynDm_Provider_Metadata;
--        IF OBJECT_ID('dbo.tmp_DynDm_ProvPart_Table_temp', 'U') IS NOT NULL drop table dbo.tmp_DynDm_ProvPart_Table_temp;
--        IF OBJECT_ID('dbo.tmp_DynDm_Investigation_Data', 'U') IS NOT NULL drop table dbo.tmp_DynDm_Investigation_Data;
--        IF OBJECT_ID('dbo.tmp_DynDm_OrgPart_Table_temp', 'U') IS NOT NULL drop table dbo.tmp_DynDm_OrgPart_Table_temp;
--        IF OBJECT_ID('dbo.tmp_DynDm_Organization', 'U') IS NOT NULL  drop table dbo.tmp_DynDm_Organization;
--        IF OBJECT_ID('dbo.tmp_DynDm_Investigation_Data', 'U') IS NOT NULL drop table dbo.tmp_DynDm_Investigation_Data;

--        IF OBJECT_ID('dbo.tmp_DynDm_Patient_Data', 'U') IS NOT NULL drop table dbo.tmp_DynDm_Patient_Data;
--        IF OBJECT_ID('dbo.tmp_DynDm_Case_Management_Data', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_Case_Management_Data;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_Administrative', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_Administrative;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_CLINICAL', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_CLINICAL;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_COMPLICATION', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_COMPLICATION;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_CONTACT', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_CONTACT;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_DEATH', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_DEATH;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_EPIDEMIOLOGY', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_EPIDEMIOLOGY;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_HIV', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_HIV;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_PATIENT_OBS', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_PATIENT_OBS;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_ISOLATE_TRACKING', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_ISOLATE_TRACKING;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_LAB_FINDING', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_LAB_FINDING;
--
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_MEDICAL_HISTORY', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_MEDICAL_HISTORY;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_MOTHER', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_MOTHER;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_OTHER', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_OTHER;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_PREGNANCY_BIRTH', 'U') IS NOT NULL drop table dbo.tmp_DynDm_D_INV_PREGNANCY_BIRTH;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_RESIDENCY', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_RESIDENCY;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_RISK_FACTOR', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_RISK_FACTOR;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_SOCIAL_HISTORY', 'U') IS NOT NULL  drop table dbo.tmp_DynDm_D_INV_SOCIAL_HISTORY;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_SYMPTOM', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_SYMPTOM;
--
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_TREATMENT', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_TREATMENT;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_TRAVEL', 'U') IS NOT NULL  drop table dbo.tmp_DynDm_D_INV_TRAVEL;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_UNDER_CONDITION', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_UNDER_CONDITION;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_VACCINATION', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_VACCINATION;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_STD', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_D_INV_STD;
--        IF OBJECT_ID('dbo.tmp_DynDm_Organization', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_Organization;
--        IF OBJECT_ID('dbo.tmp_DynDm_PROVIDER', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_PROVIDER;
--
--        IF OBJECT_ID('dbo.tmp_DynDm_INV_SUMM_DATAMART', 'U') IS NOT NULL  DROP TABLE dbo.tmp_DynDm_INV_SUMM_DATAMART  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_PAT_METADATA', 'U') IS NOT NULL     DROP TABLE dbo.tmp_DynDm_PAT_METADATA  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_METADATA', 'U') IS NOT NULL     DROP TABLE dbo.tmp_DynDm_D_INV_METADATA  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_METADATA_distinct', 'U') IS NOT NULL     DROP TABLE dbo.tmp_DynDm_D_INV_METADATA_distinct  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_METADATA_OTH', 'U') IS NOT NULL     DROP TABLE dbo.tmp_DynDm_D_INV_METADATA_OTH  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_METADATA_UNIT', 'U') IS NOT NULL     DROP TABLE dbo.tmp_DynDm_D_INV_METADATA_UNIT  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_Organization_METADATA', 'U') IS NOT NULL     DROP TABLE dbo.tmp_DynDm_Organization_METADATA  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_DISCRETE_ALL', 'U') IS NOT NULL     DROP TABLE dbo.tmp_DynDm_DISCRETE_ALL  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR', 'U') IS NOT NULL     DROP TABLE dbo.tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL', 'U') IS NOT NULL     DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL  ;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_ALL', 'U') IS NOT NULL  drop table dbo.tmp_DynDm_REPEAT_ALL;
--        IF OBJECT_ID('dbo.tmp_DynDm_BLOCK_DATA', 'U') IS NOT NULL  drop table dbo.tmp_DynDm_BLOCK_DATA;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK', 'U') IS NOT NULL drop table dbo.tmp_DynDm_REPEAT_BLOCK;
--        IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE', 'U') IS NOT NULL drop table dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE', 'U') IS NOT NULL drop table dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_ALL', 'U') IS NOT NULL drop table dbo.tmp_DynDm_REPEAT_BLOCK_OUT_ALL;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE', 'U') IS NOT NULL drop table dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK', 'U') IS NOT NULL drop table dbo.tmp_DynDm_REPEAT_BLOCK;
--        IF OBJECT_ID('dbo.tmp_DynDm_METADATA_OUT_final', 'U') IS NOT NULL drop table dbo.tmp_DynDm_METADATA_OUT_final;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_ALL', 'U') IS NOT NULL drop table dbo.tmp_DynDm_REPEAT_ALL;
--        IF OBJECT_ID('dbo.tmp_DynDm_BLOCK_DATA', 'U') IS NOT NULL drop table dbo.tmp_DynDm_BLOCK_DATA;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK', 'U') IS NOT NULL  drop table dbo.tmp_DynDm_REPEAT_BLOCK;
--        IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE', 'U') IS NOT NULL  drop table dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE;
--        IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE', 'U') IS NOT NULL   drop table dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE;
--        IF OBJECT_ID('dbo.tmp_DynDm_D_INV_REPEAT_METADATA_distinct', 'U') IS NOT NULL drop table dbo.tmp_DynDm_D_INV_REPEAT_METADATA_distinct;
--
--        IF OBJECT_ID('[dbo].[tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL]', 'U') IS NOT NULL DROP TABLE [dbo].[tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL];
--        IF OBJECT_ID('[dbo].[tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC]', 'U') IS NOT NULL DROP TABLE [dbo].tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC;
--        IF OBJECT_ID('[dbo].[tmp_DynDm_DISCRETE_ALL]', 'U') IS NOT NULL DROP TABLE [dbo].tmp_DynDm_DISCRETE_ALL;
--        IF OBJECT_ID('[dbo].[tmp_DynDm_REPEAT_ALL]', 'U') IS NOT NULL DROP TABLE [dbo].tmp_DynDm_REPEAT_ALL;


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

