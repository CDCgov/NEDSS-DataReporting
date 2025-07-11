IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_dyn_dm_createdm_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_dyn_dm_createdm_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].sp_dyn_dm_createdm_postprocessing
    @batch_id BIGINT,
    @DATAMART_NAME VARCHAR(100),
    @debug bit = 'false'
AS
BEGIN
    BEGIN TRY



        DECLARE @RowCount_no INT;
        DECLARE @Proc_Step_no FLOAT = 0;
        DECLARE @Proc_Step_Name VARCHAR(200) = '';

        DECLARE @dataflow_name varchar(200) = 'DYNAMIC_DATAMART POST-Processing';
        DECLARE @package_name varchar(200) = 'sp_dyn_dm_createdm_postprocessing: ' + @DATAMART_NAME; --'sp_dyn_dm_createdm_postprocessing';


        DECLARE @temp_sql nvarchar(max);

        DECLARE @datamart_suffix varchar(100) = @DATAMART_NAME+'_'+CAST(@batch_id AS varchar(50))

        DECLARE @tmp_DynDm_INCOMING_DATA varchar(200) = 'tmp_DynDm_INCOMING_DATA_'+@datamart_suffix;
        DECLARE @tmp_DynDm_INACTIVE_INVESTIGATIONS VARCHAR(200) = 'dbo.tmp_DynDm_Inactive_Investigations_'+@datamart_suffix;


    DECLARE @tgt_table_nm NVARCHAR(200) = 'DM_INV_' + @DATAMART_NAME;

        BEGIN TRANSACTION;
	
		SET @Proc_Step_no = @Proc_Step_no + 1;
		SET @Proc_Step_Name = 'CREATING INDEXES';
	
	
			
		SET @temp_sql = 
			'CREATE INDEX idx_tmp_DynDm_INV_SUMM_DATAMART_key  ON dbo.tmp_DynDm_INV_SUMM_DATAMART_' + @datamart_suffix + ' (INVESTIGATION_KEY); 
            CREATE INDEX idx_tmp_DynDm_Investigation_Data_key  ON dbo.tmp_DynDm_Investigation_Data_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_Patient_Data_key  ON dbo.tmp_DynDm_Patient_Data_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_Case_Management_Data_key  ON dbo.tmp_DynDm_Case_Management_Data_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_Administrative_key  ON dbo.tmp_DynDm_D_INV_Administrative_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_CLINICAL_key  ON dbo.tmp_DynDm_D_INV_CLINICAL_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_COMPLICATION_key  ON dbo. tmp_DynDm_D_INV_COMPLICATION_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_CONTACT_key  ON dbo.tmp_DynDm_D_INV_CONTACT_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_DEATH_key  ON dbo.tmp_DynDm_D_INV_DEATH_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_EPIDEMIOLOGY_key  ON dbo.tmp_DynDm_D_INV_EPIDEMIOLOGY_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_HIV_key  ON dbo.tmp_DynDm_D_INV_HIV_' + @datamart_suffix + '	 (	INVESTIGATION_KEY	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_PATIENT_OBS_key  ON dbo.tmp_DynDm_D_INV_PATIENT_OBS_' + @datamart_suffix + '	 (	INVESTIGATION_KEY	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_ISOLATE_TRACKING_key  ON dbo.tmp_DynDm_D_INV_ISOLATE_TRACKING_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_LAB_FINDING_key  ON dbo.tmp_DynDm_D_INV_LAB_FINDING_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_MEDICAL_HISTORY_key  ON dbo.tmp_DynDm_D_INV_MEDICAL_HISTORY_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_MOTHER_key  ON dbo.tmp_DynDm_D_INV_MOTHER_' + @datamart_suffix + '	 (	INVESTIGATION_KEY	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_OTHER_key  ON dbo.tmp_DynDm_D_INV_OTHER_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_PREGNANCY_BIRTH_key  ON dbo.tmp_DynDm_D_INV_PREGNANCY_BIRTH_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_RESIDENCY_key  ON dbo.tmp_DynDm_D_INV_RESIDENCY_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_RISK_FACTOR_key  ON dbo.tmp_DynDm_D_INV_RISK_FACTOR_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_SOCIAL_HISTORY_key  ON dbo.tmp_DynDm_D_INV_SOCIAL_HISTORY_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_SYMPTOM_key  ON dbo.tmp_DynDm_D_INV_SYMPTOM_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_TREATMENT_key  ON dbo.tmp_DynDm_D_INV_TREATMENT_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_TRAVEL_key  ON dbo.tmp_DynDm_D_INV_TRAVEL_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_UNDER_CONDITION_key  ON dbo.tmp_DynDm_D_INV_UNDER_CONDITION_' + @datamart_suffix + '	 (	INVESTIGATION_KEY  	); 
			CREATE INDEX idx_tmp_DynDm_D_INV_VACCINATION_key  ON dbo. tmp_DynDm_D_INV_VACCINATION_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	); 
			CREATE INDEX idx_tmp_DynDm_Organization_key  ON dbo. tmp_DynDm_Organization_' + @datamart_suffix + '	 (	INVESTIGATION_KEY   	); 
			CREATE INDEX idx_tmp_DynDm_PROVIDER_key  ON dbo.tmp_DynDm_PROVIDER_' + @datamart_suffix + '	 (	INVESTIGATION_KEY 	);' 

            exec sp_executesql @temp_sql;




		SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);
  
		
	
    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
        SET @Proc_Step_no = @Proc_Step_no + 1;
        SET @Proc_Step_Name = 'GENERATING  tmp_DynDM_INCOMING_DATA';


        SET @temp_sql = '
		        IF OBJECT_ID('''+@tmp_DynDm_INCOMING_DATA+''', ''U'') IS NOT NULL
		            drop table '+@tmp_DynDm_INCOMING_DATA;
        exec sp_executesql @temp_sql;
        
        DECLARE @JoinColumn NVARCHAR(100) = 'INVESTIGATION_KEY';
        DECLARE @select_cols NVARCHAR(MAX);

        WITH ColumnNames AS (
            SELECT 
                COLUMN_NAME, 
                TABLE_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME IN ('tmp_DynDm_Investigation_Data_' + @datamart_suffix 
            , 'tmp_DynDm_Patient_Data_' + @datamart_suffix
            , 'tmp_DynDm_Case_Management_Data_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_Administrative_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_CLINICAL_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_COMPLICATION_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_CONTACT_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_DEATH_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_EPIDEMIOLOGY_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_HIV_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_PATIENT_OBS_' +@datamart_suffix
            , 'tmp_DynDm_D_INV_ISOLATE_TRACKING_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_LAB_FINDING_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_LAB_FINDING_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_MEDICAL_HISTORY_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_MOTHER_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_OTHER_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_PREGNANCY_BIRTH_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_RESIDENCY_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_RISK_FACTOR_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_SOCIAL_HISTORY_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_SYMPTOM_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_TREATMENT_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_TRAVEL_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_UNDER_CONDITION_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_VACCINATION_' + @datamart_suffix
            , 'tmp_DynDm_D_INV_STD_' + @datamart_suffix
            , 'tmp_DynDm_Organization_' + @datamart_suffix
            , 'tmp_DynDm_PROVIDER_' + @datamart_suffix
            , 'tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR_' + @datamart_suffix
            , 'tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL_' + @datamart_suffix
            , 'tmp_DynDm_INVESTIGATION_REPEAT_DATE_' + @datamart_suffix
            , 'tmp_DynDm_REPEAT_BLOCK_DATE_ALL_' + @datamart_suffix
            , 'tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_' + @datamart_suffix
            , 'tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_' + @datamart_suffix
            )
            AND COLUMN_NAME NOT IN (@JoinColumn, 'rdb_column_nm_list', 'ORGANIZATION_UID', 'PROVIDER_UID', 'PATIENT_LOCAL_ID')
        )
        SELECT @select_cols = STRING_AGG(CAST(QUOTENAME(TABLE_NAME) + '.' + QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), ', ')
        FROM ColumnNames;


                SET @temp_sql = 

        'SELECT disumdt.*, 
        ' + @select_cols + ' 
into dbo.' + @tmp_DynDm_INCOMING_DATA + ' 
FROM dbo.tmp_DynDm_INV_SUMM_DATAMART_' + @datamart_suffix + ' disumdt 
LEFT JOIN dbo.tmp_DynDm_Investigation_Data_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_Investigation_Data_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_Patient_Data_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_Patient_Data_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_Case_Management_Data_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_Case_Management_Data_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_Administrative_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_Administrative_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_CLINICAL_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_CLINICAL_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_COMPLICATION_' + @datamart_suffix + ' with (nolock) ON  tmp_DynDm_D_INV_COMPLICATION_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_CONTACT_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_CONTACT_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_DEATH_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_DEATH_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_EPIDEMIOLOGY_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_EPIDEMIOLOGY_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_HIV_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_HIV_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_PATIENT_OBS_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_PATIENT_OBS_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_ISOLATE_TRACKING_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_ISOLATE_TRACKING_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_LAB_FINDING_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_LAB_FINDING_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_MEDICAL_HISTORY_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_MEDICAL_HISTORY_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_MOTHER_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_MOTHER_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_OTHER_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_OTHER_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_PREGNANCY_BIRTH_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_PREGNANCY_BIRTH_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_RESIDENCY_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_RESIDENCY_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_RISK_FACTOR_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_RISK_FACTOR_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_SOCIAL_HISTORY_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_SOCIAL_HISTORY_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_SYMPTOM_' + @datamart_suffix + '  ON tmp_DynDm_D_INV_SYMPTOM_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_TREATMENT_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_TREATMENT_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_TRAVEL_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_TRAVEL_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_UNDER_CONDITION_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_UNDER_CONDITION_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY  
LEFT JOIN dbo.tmp_DynDm_D_INV_VACCINATION_' + @datamart_suffix + ' with (nolock)  ON  tmp_DynDm_D_INV_VACCINATION_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY  
LEFT JOIN dbo.tmp_DynDm_Organization_' + @datamart_suffix + ' with (nolock)  ON  tmp_DynDm_Organization_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY   
LEFT JOIN dbo.tmp_DynDm_PROVIDER_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_PROVIDER_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_D_INV_STD_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_D_INV_STD_' + @datamart_suffix + '.INVESTIGATION_KEY =disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR_' + @datamart_suffix + '.INVESTIGATION_KEY = disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL_' + @datamart_suffix + '  with (nolock)  ON tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL_' + @datamart_suffix + '.INVESTIGATION_KEY = disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_INVESTIGATION_REPEAT_DATE_' + @datamart_suffix + ' with (nolock) ON tmp_DynDm_INVESTIGATION_REPEAT_DATE_' + @datamart_suffix + '.INVESTIGATION_KEY = disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_REPEAT_BLOCK_DATE_ALL_' + @datamart_suffix + '  with (nolock)     ON tmp_DynDm_REPEAT_BLOCK_DATE_ALL_' + @datamart_suffix + '.INVESTIGATION_KEY = disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_' + @datamart_suffix + '  with (nolock) ON tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_' + @datamart_suffix + '.INVESTIGATION_KEY = disumdt.INVESTIGATION_KEY 
LEFT JOIN dbo.tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_' + @datamart_suffix + '   with (nolock)  ON tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_' + @datamart_suffix + '.INVESTIGATION_KEY = disumdt.INVESTIGATION_KEY 
';
        if @debug = 'true'
        select @Proc_Step_Name, @temp_sql;

        exec sp_executesql @temp_sql;




        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number],[step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name, @ROWCOUNT_NO);
        COMMIT TRANSACTION;


        /*
            There are separate flows for:
                1. Target table DOES NOT exist (SELECT INTO, ALTER to drop columns)
                2. Target table DOES exist (ALTER as needed, UPDATE, INSERT)
        */
        IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = @tgt_table_nm and xtype = 'U')
        BEGIN

            BEGIN TRANSACTION

                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'CREATING ' + @tgt_table_nm;


                SET @temp_sql = '
                    SELECT * 
                    INTO dbo.' + @tgt_table_nm + ' 
                    FROM dbo.' + @tmp_DynDm_INCOMING_DATA + '
                    ';

                if @debug = 'true'
                select @Proc_Step_Name, @temp_sql;

                exec sp_executesql @temp_sql;



            COMMIT TRANSACTION;


        END;
        ELSE
        BEGIN

            BEGIN TRANSACTION

                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'ADD NECESSARY COLUMNS TO ' + @tgt_table_nm;

                set @temp_sql = '
                WITH col_cte as ( 
                select 
                    snt.column_name as col_nm, 
                    snt.data_type as col_data_type, 
                    snt.character_maximum_length as col_CHARACTER_MAXIMUM_LENGTH, 
                    snt.numeric_precision AS col_NUMERIC_PRECISION, 
                    snt.numeric_scale AS col_NUMERIC_SCALE 
                from 
                ( 
                select * from INFORMATION_SCHEMA.columns 
            where table_name = '''+ @tmp_DynDm_INCOMING_DATA +''' and TABLE_SCHEMA = ''dbo'' 
            AND column_name NOT IN (SELECT COLUMN_NAME  
            FROM INFORMATION_SCHEMA.columns 
            where table_name = '''+ @tgt_table_nm +''' and TABLE_SCHEMA = ''dbo'')  
                ) snt) 
                select @altercolsOUT = STRING_AGG(CAST( col_nm + '' '' +  col_data_type + 
                    CASE 
                        WHEN col_data_type IN (''decimal'', ''numeric'') THEN ''('' + CAST(col_NUMERIC_PRECISION AS NVARCHAR) + '','' + CAST(col_NUMERIC_SCALE AS NVARCHAR) + '')'' 
                        WHEN col_data_type = ''varchar'' THEN ''('' + 
                            CASE WHEN col_CHARACTER_MAXIMUM_LENGTH = -1 THEN ''MAX'' ELSE CAST(col_CHARACTER_MAXIMUM_LENGTH AS NVARCHAR) END 
                        + '') '' 
                        ELSE '''' 
                    END AS NVARCHAR(MAX)), '', '') from col_cte';

                DECLARE @altercols NVARCHAR(MAX);

            if @debug = 'true'
            select @Proc_Step_Name, @temp_sql;

            exec sp_executesql @temp_sql, N'@altercolsOUT NVARCHAR(MAX) OUTPUT',@altercolsOUT = @altercols OUTPUT;


            IF (@altercols IS NOT NULL)
            BEGIN
            DECLARE @alterquery NVARCHAR(MAX) = CONCAT('ALTER TABLE dbo.' , @tgt_table_nm , ' ADD ' , @altercols);

            if @debug = 'true'
            select @Proc_Step_Name, @alterquery;

            exec sp_executesql @alterquery;
            END;

            COMMIT TRANSACTION;


            IF OBJECT_ID('dbo.tmp_DynDm_Inactive_Investigations_'+@datamart_suffix, 'U') IS NOT NULL
            BEGIN

            BEGIN TRANSACTION

                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'DELETING INACTIVE RECORDS FROM ' + @tgt_table_nm;

                set @temp_sql = '
                DELETE inv 
                FROM dbo.' + @tgt_table_nm + ' inv 
                INNER JOIN ' + @tmp_DynDm_INACTIVE_INVESTIGATIONS + ' del_inv 
                    ON inv.INVESTIGATION_KEY = del_inv.INVESTIGATION_KEY ';



            if @debug = 'true'
            select @Proc_Step_Name, @temp_sql;

            exec sp_executesql @temp_sql;

            COMMIT TRANSACTION;
                
            END
            

            BEGIN TRANSACTION

                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'UPDATING ' + @tgt_table_nm;

                set @temp_sql = '
            select @update_listOUT =  STRING_AGG(''tgt.'' + 
                                                                    CAST(QUOTENAME(column_name) AS NVARCHAR(MAX)) + 
                                                                    '' = src.'' + 
                                                                    CAST(QUOTENAME(column_name) AS NVARCHAR(MAX)), 
                                                                    '','') from INFORMATION_SCHEMA.columns 
            where table_name = ''' + @tmp_DynDm_INCOMING_DATA + ''' and TABLE_SCHEMA = ''dbo'' 
            AND column_name IN (SELECT COLUMN_NAME  
            FROM INFORMATION_SCHEMA.columns 
            where table_name = ''' + @tgt_table_nm + ''' and TABLE_SCHEMA = ''dbo'')';

            DECLARE @update_list NVARCHAR(MAX);

            if @debug = 'true'
            select @Proc_Step_Name, @temp_sql;

            exec sp_executesql @temp_sql, N'@update_listOUT NVARCHAR(MAX) OUTPUT',@update_listOUT = @update_list OUTPUT;



            DECLARE @update_sql NVARCHAR(MAX) = 
            '
            UPDATE tgt 
            SET 
            ' + @update_list + ' 
            FROM dbo.' + @tmp_DynDm_INCOMING_DATA + ' src 
            LEFT JOIN dbo.' + @tgt_table_nm + ' tgt 
            ON src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY 
            WHERE tgt.INVESTIGATION_KEY IS NOT NULL 
            ';

            if @debug = 'true'
            select @Proc_Step_Name, @update_sql;

            exec sp_executesql @update_sql;


            COMMIT TRANSACTION;

            BEGIN TRANSACTION

                SET @Proc_Step_no = @Proc_Step_no + 1;
                SET @Proc_Step_Name = 'INSERTING INTO ' + @tgt_table_nm;

                set @temp_sql = '
                select @col_listOUT = COALESCE(STRING_AGG(CAST(QUOTENAME(column_name) AS NVARCHAR(MAX)), '','') WITHIN GROUP (ORDER BY column_name), 
                                            '''') from INFORMATION_SCHEMA.columns 
                where table_name = ''' + @tmp_DynDm_INCOMING_DATA + ''' and TABLE_SCHEMA = ''dbo'' 
                AND column_name IN (SELECT COLUMN_NAME  
                FROM INFORMATION_SCHEMA.columns 
                where table_name = ''' + @tgt_table_nm + ''' and TABLE_SCHEMA = ''dbo'')';

                DECLARE @col_list NVARCHAR(MAX);

                exec sp_executesql @temp_sql, N'@col_listOUT NVARCHAR(MAX) OUTPUT',@col_listOUT = @col_list OUTPUT;


                set @temp_sql = '
                select @insert_listOUT = COALESCE(STRING_AGG(''src.'' + CAST(QUOTENAME(column_name) AS NVARCHAR(MAX)), '','') WITHIN GROUP (ORDER BY column_name), 
                                            '''') from INFORMATION_SCHEMA.columns 
                where table_name = ''' + @tmp_DynDm_INCOMING_DATA + ''' and TABLE_SCHEMA = ''dbo'' 
                AND column_name IN (SELECT COLUMN_NAME  
                FROM INFORMATION_SCHEMA.columns  
                where table_name = ''' + @tgt_table_nm + ''' and TABLE_SCHEMA = ''dbo'')';

                DECLARE @insert_list NVARCHAR(MAX);

                exec sp_executesql @temp_sql, N'@insert_listOUT NVARCHAR(MAX) OUTPUT',@insert_listOUT = @insert_list OUTPUT;


                DECLARE @insert_query NVARCHAR(MAX) = '
                INSERT INTO dbo.' + @tgt_table_nm + ' 
                ('
                + @col_list +
                ') 
                SELECT 
                '
                + @insert_list +
                ' 
                FROM ' + @tmp_DynDm_INCOMING_DATA + ' src  
                LEFT JOIN ' + @tgt_table_nm + ' tgt 
                ON src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY 
                WHERE tgt.INVESTIGATION_KEY IS NULL 
                ';

                if @debug = 'true'
                select @Proc_Step_Name, @insert_query;

                exec sp_executesql @insert_query;

            COMMIT TRANSACTION;

        END;

        /*
            DROP unnecessary tables
        */
        SET @temp_sql = '
		        IF OBJECT_ID('''+@tmp_DynDm_INCOMING_DATA+''', ''U'') IS NOT NULL
		            drop table '+@tmp_DynDm_INCOMING_DATA;
        exec sp_executesql @temp_sql;


        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [row_count])
        VALUES ( @batch_id,
                 @dataflow_name
               , @package_name
               , 'COMPLETE'
               , @Proc_Step_no
               , @Proc_Step_name
               , @RowCount_no);

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        -- Construct the error message string_' + @datamart_suffix + ' all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) +
            CHAR(10) + -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [create_dttm]
        , [update_dttm]
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Error_Description])

        VALUES ( @batch_id
               , current_timestamp
               , current_timestamp
               , @dataflow_name
               , @package_name
               , 'ERROR'
               , @Proc_Step_no
               , @proc_step_name
               , 0
               , @FullErrorMessage);


        return -1;

    END CATCH
END;