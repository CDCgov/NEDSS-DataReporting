CREATE or alter PROCEDURE [dbo].sp_dyn_dm_main_postprocessing
    @datamart_name VARCHAR(100),
    @phc_id_list VARCHAR(MAX) = NULL,
    @debug BIT = 'false'
AS
BEGIN
    BEGIN TRY
        DECLARE @RowCount_no INT;
        DECLARE @Proc_Step_no FLOAT = 0;
        DECLARE @Proc_Step_Name VARCHAR(200) = '';
        DECLARE @DATAMART_TABLE_NAME varchar(100);
        DECLARE @batch_id BIGINT;
        DECLARE @DATAFLOW_NAME VARCHAR(100) = 'DYNAMIC_DATAMART POST-Processing';
        DECLARE @PACKAGE_NAME VARCHAR(100) = 'sp_dyn_dm_main_postprocessing';

        -- Input validation
        IF @datamart_name IS NULL OR LEN(LTRIM(RTRIM(@datamart_name))) = 0
            BEGIN
                -- Log the validation error to job_flow_log
                INSERT INTO [dbo].[job_flow_log] (
                    batch_id,
                    [Dataflow_Name],
                    [package_Name],
                    [Status_Type],
                    [step_number],
                    [step_name],
                    [row_count],
                    [Msg_Description1],
                    [Error_Description]
                )
                VALUES (
                           @batch_id,
                           @DATAFLOW_NAME,
                           @PACKAGE_NAME,
                           'ERROR',
                           0,
                           'Input Validation',
                           0,
                           'Missing required parameter',
                           'Parameter @datamart_name is required'
                       );

                RAISERROR('Parameter @datamart_name is required', 16, 1);

                RETURN -1;
            END

        -- Set up datamart table name
        SET @DATAMART_TABLE_NAME = 'DM_INV_' + LTRIM(RTRIM(@datamart_name));

        -- Generate batch_id for logging
        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);

        if @debug='true'
            print @batch_id;

        INSERT INTO [dbo].[job_flow_log] (
            batch_id,
            [Dataflow_Name],
            [package_Name],
            [Status_Type],
            [step_number],
            [step_name],
            [row_count],
            [Msg_Description1]
        )
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'START',
                   0,
                   'SP_Start',
                   0,
                   LEFT(@phc_id_list, 500)
               );

        -- Log start of processing for this datamart
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' STARTING DYNAMIC DATAMART ' + @datamart_name;

        INSERT INTO [dbo].[job_flow_log] (
            batch_id,
            [Dataflow_Name],
            [package_Name],
            [Status_Type],
            [step_number],
            [step_name],
            [row_count],
            [Msg_Description1]
        )
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'START',
                   @Proc_Step_no,
                   @Proc_Step_Name,
                   0,
                   LEFT('DataMart: ' + @datamart_name, 199)
               );



        -- Clear any temporary tables.
        BEGIN TRANSACTION;
        EXEC [dbo].DynDM_CLEAR_sp;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: DynDM_CLEAR_sp';

        -- Process form and case management data
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_invest_form_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @phc_id_list = @phc_id_list,
        	 @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_invest_form_postprocessing';

        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_case_management_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_case_management_postprocessing';


        -- Process dimension tables - each in a separate transaction
        -- D_INV_ADMINISTRATIVE dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_ADMINISTRATIVE',
             @DIM_KEY = 'D_INV_ADMINISTRATIVE_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_ADMINISTRATIVE';


        -- D_INV_CLINICAL dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_CLINICAL',
             @DIM_KEY = 'D_INV_CLINICAL_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_CLINICAL';

        -- D_INV_COMPLICATION dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_COMPLICATION',
             @DIM_KEY = 'D_INV_COMPLICATION_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_COMPLICATION_KEY';

        -- D_INV_CONTACT dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_CONTACT',
             @DIM_KEY = 'D_INV_CONTACT_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_CONTACT';


        -- D_INV_DEATH dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_DEATH',
             @DIM_KEY = 'D_INV_DEATH_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_DEATH';


        -- D_INV_EPIDEMIOLOGY dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_EPIDEMIOLOGY',
             @DIM_KEY = 'D_INV_EPIDEMIOLOGY_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_EPIDEMIOLOGY_KEY';

        -- D_INV_HIV dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_HIV',
             @DIM_KEY = 'D_INV_HIV_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_HIV';


        -- D_INV_PATIENT_OBS dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_PATIENT_OBS',
             @DIM_KEY = 'D_INV_PATIENT_OBS_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_PATIENT_OBS';


        -- D_INV_ISOLATE_TRACKING dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_ISOLATE_TRACKING',
             @DIM_KEY = 'D_INV_ISOLATE_TRACKING_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_ISOLATE_TRACKING';


        -- D_INV_LAB_FINDING dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_LAB_FINDING',
             @DIM_KEY = 'D_INV_LAB_FINDING_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_LAB_FINDING';


        -- D_INV_MEDICAL_HISTORY dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_MEDICAL_HISTORY',
             @DIM_KEY = 'D_INV_MEDICAL_HISTORY_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_MEDICAL_HISTORY';


        -- D_INV_MOTHER dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_MOTHER',
             @DIM_KEY = 'D_INV_MOTHER_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;
        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_MOTHER';

        -- D_INV_OTHER dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_OTHER',
             @DIM_KEY = 'D_INV_OTHER_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_OTHER';


        -- D_INV_PREGNANCY_BIRTH dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_PREGNANCY_BIRTH',
             @DIM_KEY = 'D_INV_PREGNANCY_BIRTH_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_PREGNANCY_BIRTH';


        -- D_INV_RESIDENCY dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_RESIDENCY',
             @DIM_KEY = 'D_INV_RESIDENCY_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_RESIDENCY';


        -- D_INV_RISK_FACTOR dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_RISK_FACTOR',
             @DIM_KEY = 'D_INV_RISK_FACTOR_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_RISK_FACTOR';


        -- D_INV_SOCIAL_HISTORY dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_SOCIAL_HISTORY',
             @DIM_KEY = 'D_INV_SOCIAL_HISTORY_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_SOCIAL_HISTORY';


        -- D_INV_SYMPTOM dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_SYMPTOM',
             @DIM_KEY = 'D_INV_SYMPTOM_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_SYMPTOM';


        -- D_INV_TREATMENT dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_TREATMENT',
             @DIM_KEY = 'D_INV_TREATMENT_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_TREATMENT';


        -- D_INV_TRAVEL dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_TRAVEL',
             @DIM_KEY = 'D_INV_TRAVEL_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_TRAVEL';


        -- D_INV_UNDER_CONDITION dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_UNDER_CONDITION',
             @DIM_KEY = 'D_INV_UNDER_CONDITION_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_UNDER_CONDITION';


        -- D_INV_VACCINATION dimension
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_page_builder_d_inv_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @RDB_TABLE_NM = 'D_INV_VACCINATION',
             @DIM_KEY = 'D_INV_VACCINATION_KEY',
             @phc_id_list = @phc_id_list,
             @debug = @debug;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_page_builder_d_inv_postprocessing D_INV_VACCINATION';

        -- Process organization data
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_org_data_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @phc_id_list = @phc_id_list;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_org_data_postprocessing';


        -- Process provider data
        BEGIN TRANSACTION;
        EXEC [dbo].sp_dyn_dm_provider_data_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @phc_id_list = @phc_id_list;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_provider_data_postprocessing';


        -- Clean up temporary metadata tables before repeating data processing
        /* BEGIN TRANSACTION;
         IF OBJECT_ID('dbo.tmp_DynDm_METADATA', 'U') IS NOT NULL
             DROP TABLE dbo.tmp_DynDm_METADATA;

         IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_ALL', 'U') IS NOT NULL
             DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK_OUT_ALL;

         IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE', 'U') IS NOT NULL
             DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE;

         IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK', 'U') IS NOT NULL
             DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK;

         IF OBJECT_ID('dbo.tmp_DynDm_METADATA_OUT_final', 'U') IS NOT NULL
             DROP TABLE dbo.tmp_DynDm_METADATA_OUT_final;

         IF OBJECT_ID('dbo.tmp_DynDm_METADATA_UNIT', 'U') IS NOT NULL
             DROP TABLE dbo.tmp_DynDm_METADATA_UNIT;
         COMMIT TRANSACTION;*/

        -- Process repeating varchar data
        BEGIN TRANSACTION;
        EXEC dbo.sp_dyn_dm_repeatvarch_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @phc_id_list = @phc_id_list;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_repeatvarch_postprocessing';

        -- Additional cleanup before date data processing
        /*  BEGIN TRANSACTION;
          IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_METADATA_OUT', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK_METADATA_OUT;

          IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK_OUT;

          IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_ALL', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_REPEAT_ALL;

          IF OBJECT_ID('dbo.tmp_DynDm_BLOCK_DATA', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_BLOCK_DATA;

          IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK;

          IF OBJECT_ID('dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE;

          IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE;

          IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_ALL', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK_OUT_ALL;

          IF OBJECT_ID('dbo.tmp_DynDm_METADATA_UNIT', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_METADATA_UNIT;

          IF OBJECT_ID('dbo.tmp_DynDm_Metadata', 'U') IS NOT NULL
              DROP TABLE dbo.tmp_DynDm_Metadata;
          COMMIT TRANSACTION;*/

        -- Process repeating date data
        BEGIN TRANSACTION;
        EXEC dbo.sp_dyn_dm_repeatdate_postprocessing
             @batch_id = @batch_id,
             @datamart_name = @datamart_name,
             @phc_id_list = @phc_id_list;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_repeatdate_postprocessing';


        -- Additional cleanup before numeric data processing
        /*   BEGIN TRANSACTION;
           IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_ALL', 'U') IS NOT NULL
               DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK_OUT_ALL;

           IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE', 'U') IS NOT NULL
               DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK_OUT_BASE;

           IF OBJECT_ID('dbo.tmp_DynDm_REPEAT_BLOCK', 'U') IS NOT NULL
               DROP TABLE dbo.tmp_DynDm_REPEAT_BLOCK;

           IF OBJECT_ID('dbo.tmp_DynDm_METADATA_OUT_final', 'U') IS NOT NULL
               DROP TABLE dbo.tmp_DynDm_METADATA_OUT_final;

           IF OBJECT_ID('dbo.tmp_DynDm_METADATA_UNIT', 'U') IS NOT NULL
               DROP TABLE dbo.tmp_DynDm_METADATA_UNIT;

           IF OBJECT_ID('dbo.tmp_DynDm_Metadata', 'U') IS NOT NULL
               DROP TABLE dbo.tmp_DynDm_Metadata;
           COMMIT TRANSACTION; */

        -- Process repeating numeric data
        BEGIN TRANSACTION;
        EXEC dbo.sp_dyn_dm_repeatnumeric_postprocessing
         @batch_id = @batch_id,
         @datamart_name = @datamart_name,
         @phc_id_list = @phc_id_list;
        COMMIT TRANSACTION;

       IF @debug = 'true' PRINT 'Step completed: sp_dyn_dm_repeatnumeric_postprocessing';


        /**
        Building temporary table to find any column collisions between all the transient tables
         */
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = ' Building #tmp_DynDm_fixcols:' + @datamart_name;

        select
            table_name,
            column_name,
            cast( null as varchar(max)) as dsql,
            RANK() OVER (PARTITION BY column_name
                order by
                    table_name) as Rank_no
        into
            #tmp_DynDm_fixcols
        from
            INFORMATION_SCHEMA.COLUMNS
        where
            lower(column_name) in (
                SELECT
                    lower(COLUMN_NAME)
                FROM
                    INFORMATION_SCHEMA.COLUMNS
                WHERE
                    ( lower(table_name) like lower('tmp_DynDm_D_INV_%'+@datamart_name+'_'+cast(@batch_id as varchar))
                        or lower(table_name) like lower('tmp_DynDm_%_REPEAT_%'+@datamart_name+'_'+cast(@batch_id as varchar))
                            or lower(table_name) like lower('tmp_DynDm_Investigation_Data_%'+@datamart_name+'_'+cast(@batch_id as varchar))
                            or lower(table_name) like lower('tmp_DynDm_Patient_Data_%'+@datamart_name+'_'+cast(@batch_id as varchar))
                            or lower(table_name) like lower('tmp_DynDm_Case_Management_Data_%'+@datamart_name+'_'+cast(@batch_id as varchar))
                    )
                    and COLUMN_NAME not in (
                     'DATAMART_NM',
                    'OTHER_VALUE_IND_CD',
                    'RDB_COLUMN_NM',
                    'RDB_TABLE_NM',
                    'USER_DEFINED_COLUMN_NM'
                )
                group BY
                    Column_Name
                having
                    count(*) > 1
            )
        and (
            lower(table_name) like lower('tmp_DynDm_D_INV_%'+@datamart_name+'_'+cast(@batch_id as varchar))
            or lower(table_name) like lower('tmp_DynDm_%_REPEAT_%'+@datamart_name+'_'+cast(@batch_id as varchar))
            or lower(table_name) like lower('tmp_DynDm_Investigation_Data_%'+@datamart_name+'_'+cast(@batch_id as varchar))
            or lower(table_name) like lower('tmp_DynDm_Patient_Data_%'+@datamart_name+'_'+cast(@batch_id as varchar))
            or lower(table_name) like lower('tmp_DynDm_Case_Management_Data_%'+@datamart_name+'_'+cast(@batch_id as varchar))
        )
        ;

        if OBJECT_ID('tempdb..#tmp_DynDm_fixcols', 'U') IS NOT NULL
        begin
            update #tmp_DynDm_fixcols
            set dsql = 'exec sp_rename ''dbo.'+table_name+'.'+column_name+''', '''+column_name+ cast(Rank_no as varchar)+''',''COLUMN'' ;'
            where rank_no <> 1

            IF @debug = 'true'
                select '#tmp_DynDm_fixcols',* from #tmp_DynDm_fixcols;

            SELECT @RowCount_no = @@ROWCOUNT;
            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            /**
            Building temporary table to find any column collisions between all the temporary tables
             */
            SET @Proc_Step_no = @Proc_Step_no + 1;
            SET @Proc_Step_Name = ' Renaming columns on the temporary tables for collisions: ' + @datamart_name;

            DECLARE @Sql NVARCHAR(MAX);

            DECLARE c CURSOR LOCAL FAST_FORWARD FOR
                SELECT  dsql
                FROM  #tmp_DynDm_fixcols
                where rank_no <> 1
            ;

            OPEN c
                FETCH NEXT FROM c INTO @Sql

                WHILE (@@FETCH_STATUS = 0)
                BEGIN
                    EXEC sp_executesql @Sql;
                    FETCH NEXT FROM c INTO @Sql
                END

            CLOSE c
            DEALLOCATE c;
        end

        IF @debug = 'true' PRINT 'Step completed: DynDM_AlterKey_sp';

    /*
        BEGIN TRANSACTION;
        EXEC dbo.DynDM_CreateDm_sp
         @batch_id = @batch_id,
        @datamart_name = @datamart_name;
        COMMIT TRANSACTION;

        IF @debug = 'true' PRINT 'Step completed: DynDM_CreateDm_sp';


        -- Cleanup
        BEGIN TRANSACTION;
        EXEC dbo.DynDM_INVEST_FORM_CLEAR_PROC_sp
          @batch_id = @batch_id,
        @datamart_table_name = @DATAMART_TABLE_NAME;
        COMMIT TRANSACTION;

       IF @debug = 'true' PRINT 'Step completed: DynDM_INVEST_FORM_CLEAR_PROC_sp';
     */

        -- Log completion
        BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'COMPLETED DYNAMIC DATAMART ' + @datamart_name;

        INSERT INTO [dbo].[job_flow_log] (
            batch_id,
            [Dataflow_Name],
            [package_Name],
            [Status_Type],
            [step_number],
            [step_name],
            [row_count],
            [Msg_Description1]
        )
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'COMPLETE',
                   @Proc_Step_no,
                   @Proc_Step_Name,
                   0,
                   LEFT('DataMart: ' + @datamart_name, 199)
               );
        COMMIT TRANSACTION;

        -- Final completion log
        BEGIN TRANSACTION;
        INSERT INTO [dbo].[job_flow_log] (
            batch_id,
            [Dataflow_Name],
            [package_Name],
            [Status_Type],
            [step_number],
            [step_name],
            [row_count],
            [Msg_Description1]
        )
        VALUES (
                   @batch_id,
                   @DATAFLOW_NAME,
                   @PACKAGE_NAME,
                   'COMPLETE',
                   0,
                   LEFT( @datamart_name, 199),
                   0,
                   LEFT(@phc_id_list, 500)
               );
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        -- Debug info for developer if debug flag is set
        IF @debug = 1
            BEGIN
                SELECT
                    'Error Info' AS Error_Type,
                    ERROR_NUMBER() AS Error_Number,
                    ERROR_LINE() AS Error_Line,
                    ERROR_MESSAGE() AS Error_Message,
                    ERROR_SEVERITY() AS Error_Severity,
                    ERROR_STATE() AS Error_State;
            END;

        -- Log the error
        INSERT INTO [dbo].[job_flow_log](
            batch_id,
            [Dataflow_Name],
            [package_Name],
            [Status_Type],
            [step_number],
            [step_name],
            [row_count],
            [Msg_Description1],
            [Error_Description]
        )
        VALUES(
                  @batch_id,
                  @DATAFLOW_NAME,
                  @PACKAGE_NAME,
                  'ERROR',
                  @Proc_Step_no,
                  LEFT( @datamart_name, 199),
                  0,
                  LEFT(@phc_id_list, 500),
                  @FullErrorMessage
              );

        RETURN -1;
    END CATCH

END;