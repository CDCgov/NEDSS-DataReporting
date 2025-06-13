
IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_ldf_dimensional_data_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_ldf_dimensional_data_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_nrt_ldf_dimensional_data_postprocessing]
  @ldf_id_list nvarchar(max),
  @debug bit = 'false'
 AS
BEGIN

	DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT =0;
    DECLARE @Proc_Step_no FLOAT = 0; 
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'LDF_DIMENSIONAL_DATA POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_ldf_dimensional_data_postprocessing';
 
	BEGIN TRY
    
		SET @Proc_Step_Name = 'SP_Start';
		
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
            , LEFT('ID List-' + @ldf_id_list, 500));


		------------------------------------------------------------------------------------------------------------------------------------------

		SET
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET
			@PROC_STEP_NAME = 'GENERATING #LDF_UID_LIST TABLE';

		IF OBJECT_ID('#LDF_UID_LIST', 'U') IS NOT NULL
			DROP TABLE #LDF_UID_LIST;

		SELECT distinct TRIM(value) AS ldf_uid 
		INTO  #LDF_UID_LIST
		FROM STRING_SPLIT(@ldf_id_list, ',')
		

		SELECT @RowCount_no = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_UID_LIST;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 	
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
		
		------------------------------------------------------------------------------------------------------------------------------------------	

		SET 
			@PROC_STEP_NO =  @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_META_DATA'; 

		-- Create table LDF_META_DATA
		IF OBJECT_ID('#LDF_META_DATA', 'U') IS NOT NULL  
			DROP TABLE #LDF_META_DATA;

		SELECT 
			a.ldf_uid,
			a.active_ind,
			a.business_object_nm,
			a.cdc_national_id,
			a.class_cd,
			a.code_set_nm,
			a.condition_cd,
			TRIM(a.label_txt) AS label_txt,
			a.state_cd,
			a.custom_subform_metadata_uid,
			page_set.code_short_desc_txt AS page_set,
			a.data_type,
			a.Field_size,
			CASE 
				WHEN a.business_object_nm = 'BMD' AND LEN(TRIM(ISNULL(a.condition_cd, 0))) < 2 THEN 'BMIRD'
				WHEN a.business_object_nm = 'NIP' AND LEN(TRIM(ISNULL(a.condition_cd, 0))) < 2 THEN 'VPD'
				WHEN a.business_object_nm = 'PHC' AND LEN(TRIM(ISNULL(a.condition_cd, 0))) < 2 THEN 'OTHER'
				WHEN a.business_object_nm = 'HEP' AND LEN(TRIM(ISNULL(a.condition_cd, 0))) < 2 THEN 'HEP'
				ELSE a.condition_desc_txt
			END AS LDF_PAGE_SET
		INTO #LDF_META_DATA
		FROM [dbo].nrt_odse_state_defined_field_metadata a WITH ( NOLOCK) 
				LEFT OUTER JOIN 
					dbo.nrt_srte_ldf_page_set page_set WITH ( NOLOCK) 
				ON  
					page_set.ldf_page_id = a.ldf_page_id 
		INNER JOIN #LDF_UID_LIST l 
			ON l.ldf_uid = a.ldf_uid
		WHERE 
			(
				a.condition_cd IN (SELECT condition_cd FROM [dbo].LDF_DATAMART_TABLE_REF WITH (NOLOCK)) 
				OR a.condition_cd IS NULL
			) and
		a.business_object_nm IN ('PHC', 'BMD', 'NIP', 'HEP')
		AND a.data_type IN ('ST', 'CV', 'LIST_ST');
				
		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_META_DATA;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no); 


		------------------------------------------------------------------------------------------------------------------------------------------


		SET 
			@PROC_STEP_NO =  @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_META_DATA_N'; 

		-- Create table #LDF_META_DATA_N
		IF OBJECT_ID('#LDF_META_DATA_N', 'U') IS NOT NULL  
			DROP TABLE #LDF_META_DATA_N;

		SELECT 
			m.* 
		INTO #LDF_META_DATA_N
		FROM #LDF_META_DATA m 
		LEFT JOIN [dbo].D_LDF_META_DATA d WITH (NOLOCK) 
			ON m.ldf_uid = d.ldf_uid
		WHERE d.ldf_uid IS NULL;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_META_DATA_N;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


		------------------------------------------------------------------------------------------------------------------------------------------



		SET 
			@PROC_STEP_NO =  @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_META_DATA_E'; 

		-- Create table #LDF_META_DATA_E
		IF OBJECT_ID('#LDF_META_DATA_E', 'U') IS NOT NULL  
			DROP TABLE #LDF_META_DATA_E;

		SELECT 
			m.* 
		INTO #LDF_META_DATA_E
		FROM #LDF_META_DATA m 
		INNER JOIN [dbo].D_LDF_META_DATA d WITH (NOLOCK) 
			ON m.ldf_uid = d.ldf_uid;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_META_DATA_E;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


		------------------------------------------------------------------------------------------------------------------------------------------


		SET 
			@PROC_STEP_NO =  @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'INSERT NEW METADATA TO D_LDF_META_DATA'; 

		INSERT INTO [dbo].D_LDF_META_DATA (
			ldf_uid,
			active_ind,
			business_object_nm,
			cdc_national_id,
			class_cd,
			code_set_nm,
			condition_cd,
			label_txt,
			state_cd,
			custom_subform_metadata_uid,
			page_set,
			data_type,
			Field_size,
			LDF_PAGE_SET
		)
		SELECT 
			ldf_uid,
			active_ind,
			business_object_nm,
			cdc_national_id,
			class_cd,
			code_set_nm,
			condition_cd,
			label_txt,
			state_cd,
			custom_subform_metadata_uid,
			page_set,
			data_type,
			Field_size,
			LDF_PAGE_SET
		FROM #LDF_META_DATA_N

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_META_DATA_N;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no); 


		------------------------------------------------------------------------------------------------------------------------------------------


		BEGIN TRANSACTION 

			SET 
				@PROC_STEP_NO =  @PROC_STEP_NO + 1;
			SET 
				@PROC_STEP_NAME = 'UPDATE EXISTING METADATA IN D_LDF_META_DATA'; 

			UPDATE D
			SET 
				D.active_ind = m.active_ind,
				D.business_object_nm = m.business_object_nm,
				D.cdc_national_id = m.cdc_national_id,
				D.class_cd = m.class_cd,
				D.code_set_nm = m.code_set_nm,
				D.condition_cd = m.condition_cd,
				D.label_txt = TRIM(m.label_txt),
				D.state_cd = m.state_cd,
				D.custom_subform_metadata_uid = m.custom_subform_metadata_uid,
				D.data_type = m.data_type,
				D.field_size = m.field_size,
				D.LDF_PAGE_SET = m.LDF_PAGE_SET
			FROM [dbo].D_LDF_META_DATA D 
			INNER JOIN #LDF_META_DATA_E m 
				ON m.ldf_uid = d.ldf_uid;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #LDF_META_DATA_E;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		COMMIT TRANSACTION; 


		------------------------------------------------------------------------------------------------------------------------------------------	


		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_METADATA'; 

		IF OBJECT_ID('#LDF_METADATA', 'U') IS NOT NULL  
			DROP TABLE #LDF_METADATA;

		SELECT 
			ISNULL(a.cdc_national_id, '') AS cdc_national_id,
			SUBSTRING(a.label_txt, 1, 50) AS ldf_label,
			a.ldf_uid,
			ISNULL(a.condition_cd, '') AS condition_cd,
			a.class_cd,
			a.custom_subform_metadata_uid,
			a.LDF_PAGE_SET,
			ROW_NUMBER() OVER (ORDER BY a.ldf_uid) + (
				SELECT COALESCE(MAX(REF.LDF_DATAMART_COLUMN_REF_UID), 1)  
				FROM [dbo].LDF_DATAMART_COLUMN_REF REF
			) AS ldf_datamart_column_ref_uid,
			SUBSTRING(
				CASE 
					WHEN a.class_cd = 'State' THEN 'L_' + RTRIM(REPLACE(a.ldf_uid, ' ', '')) + '_'
					WHEN a.class_cd = 'CDC' THEN 'C_' + RTRIM(REPLACE(a.ldf_uid, ' ', '')) + '_'
					WHEN LEN(RTRIM(a.cdc_national_id)) > 1 
						AND LEN(RTRIM(a.cdc_national_id)) + LEN(RTRIM(a.label_txt)) > 0 
						AND LEN(RTRIM(CAST(a.custom_subform_metadata_uid AS VARCHAR(MAX)))) > 1 
						THEN 'C_' + RTRIM(a.cdc_national_id) + '_'
					ELSE ''
				END +
				REPLACE(
					REPLACE( SUBSTRING(RTRIM(a.label_txt), 1, 50), ' ', '_'), 
					'[\/,@\\%[\]#;$\-\.\>\<\=\:\?\(\)\{\}\"&*\+!`\'']', '_'
				)
				, 1, 29
			) AS datamart_column_nm
		INTO #LDF_METADATA
		FROM [dbo].D_LDF_META_DATA a WITH(NOLOCK)
		INNER JOIN #LDF_UID_LIST l 
			ON l.ldf_uid = a.ldf_uid
		GROUP BY 
			a.cdc_national_id,
			a.label_txt,
			a.ldf_uid,
			a.condition_cd,
			a.class_cd,
			a.custom_subform_metadata_uid,
			a.LDF_PAGE_SET;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_METADATA;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);  


		------------------------------------------------------------------------------------------------------------------------------------------

		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_METADATA_N'; 

		IF OBJECT_ID('#LDF_METADATA_N', 'U') IS NOT NULL  
			DROP TABLE #LDF_METADATA_N;

		SELECT 
			a.cdc_national_id,
			a.ldf_label,
			a.ldf_uid,
			a.condition_cd,
			a.class_cd,
			a.custom_subform_metadata_uid,
			a.LDF_PAGE_SET,
			a.ldf_datamart_column_ref_uid,
			a.datamart_column_nm
		INTO #LDF_METADATA_N
		FROM #LDF_METADATA a
		LEFT JOIN [dbo].ldf_datamart_column_ref b WITH(NOLOCK)
			ON a.ldf_uid = b.ldf_uid
		WHERE b.ldf_uid IS NULL;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_METADATA_N;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		------------------------------------------------------------------------------------------------------------------------------------------


		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_METADATA_E'; 

		IF OBJECT_ID('#LDF_METADATA_E', 'U') IS NOT NULL  
			DROP TABLE #LDF_METADATA_E;

		SELECT 
			a.cdc_national_id,
			a.ldf_label,
			a.ldf_uid,
			a.condition_cd,
			a.class_cd,
			a.custom_subform_metadata_uid,
			a.LDF_PAGE_SET,
			a.ldf_datamart_column_ref_uid,
			a.datamart_column_nm
		INTO #LDF_METADATA_E
		FROM #LDF_METADATA a
		INNER JOIN [dbo].ldf_datamart_column_ref b WITH(NOLOCK)
			ON a.ldf_uid = b.ldf_uid;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_METADATA_E;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		------------------------------------------------------------------------------------------------------------------------------------------


		BEGIN TRANSACTION	

			SET 
				@PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET 
				@PROC_STEP_NAME = 'INSERT NEW #LDF_METADATA_N TO LDF_DATAMART_COLUMN_REF'; 

			INSERT INTO [dbo].LDF_DATAMART_COLUMN_REF (
				LDF_DATAMART_COLUMN_REF_UID, 
				CONDITION_CD, 
				LDF_LABEL, 
				DATAMART_COLUMN_NM, 
				LDF_UID, 
				CDC_NATIONAL_ID, 
				LDF_PAGE_SET
			)
			SELECT 
				LDF_DATAMART_COLUMN_REF_UID, 
				CONDITION_CD, 
				TRIM(LDF_LABEL) AS LDF_LABEL, 
				DATAMART_COLUMN_NM, 
				LDF_UID, 
				CDC_NATIONAL_ID, 
				LDF_PAGE_SET
			FROM 
				#LDF_METADATA_N

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #LDF_METADATA_N;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);  

		COMMIT TRANSACTION;	
			

		------------------------------------------------------------------------------------------------------------------------------------------


		BEGIN TRANSACTION 

			SET 
				@PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET 
				@PROC_STEP_NAME = 'UPDATE EXISTING #LDF_METADATA_E IN LDF_DATAMART_COLUMN_REF'; 

			UPDATE D
			SET 
				D.LDF_DATAMART_COLUMN_REF_UID = S.LDF_DATAMART_COLUMN_REF_UID, 
				D.CONDITION_CD = S.CONDITION_CD,
				D.LDF_LABEL = S.LDF_LABEL,
				D.DATAMART_COLUMN_NM = S.DATAMART_COLUMN_NM,
				D.CDC_NATIONAL_ID = S.CDC_NATIONAL_ID,
				D.LDF_PAGE_SET = S.LDF_PAGE_SET 
			FROM  [dbo].LDF_DATAMART_COLUMN_REF D 
			INNER JOIN #LDF_METADATA_E S 
				ON S.LDF_UID = D.LDF_UID

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #LDF_METADATA_E;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);  

		COMMIT TRANSACTION;
			

		------------------------------------------------------------------------------------------------------------------------------------------
		SET 
			@PROC_STEP_NO =  @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'Generate Delete from #LDF_DATA'; 

		-- Create table LDF_DATA_DEL
		IF OBJECT_ID('#LDF_DATA_DEL', 'U') IS NOT NULL  
			DROP TABLE #LDF_DATA_DEL;

		SELECT LDA.LDF_UID INTO 
		#LDF_DATA_DEL
		FROM DBO.LDF_DIMENSIONAL_DATA LDA with (nolock)
		INNER JOIN #LDF_UID_LIST LL
			ON LDA.LDF_UID = LL.LDF_UID
		LEFT JOIN dbo.nrt_ldf_data NRT_LDF_DATA with (nolock)
			ON LDA.LDF_UID = NRT_LDF_DATA.LDF_UID And 
			LDA.investigation_uid = NRT_LDF_DATA.business_object_uid
		where NRT_LDF_DATA.ldf_meta_data_business_object_nm is null 
			and NRT_LDF_DATA.ldf_meta_data_add_time is null;


		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_DATA_DEL;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);  

		------------------------------------------------------------------------------------------------------------------------------------------
		BEGIN TRANSACTION

		SET 
			@PROC_STEP_NO =  @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'Delete from #LDF_DATA'; 

		DELETE LDA
		FROM DBO.LDF_DIMENSIONAL_DATA LDA with (nolock)
		INNER JOIN #LDF_DATA_DEL LDF_DATA_DEL
			ON LDA.LDF_UID = LDF_DATA_DEL.LDF_UID;


		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);  

		COMMIT TRANSACTION; 

		------------------------------------------------------------------------------------------------------------------------------------------


		SET 
			@PROC_STEP_NO =  @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_DATA'; 

		-- Create table ldf_data
		IF OBJECT_ID('#LDF_DATA', 'U') IS NOT NULL  
			DROP TABLE #LDF_DATA;

		SELECT 
			a.ldf_uid,
			a.active_ind,
			a.ldf_meta_data_business_object_nm AS business_object_nm, 
			a.cdc_national_id,
			a.class_cd,
			a.code_set_nm,
			a.condition_cd,
			TRIM(a.label_txt) AS label_txt,
			a.state_cd,
			a.custom_subform_metadata_uid,
			a.business_object_uid,
			a.ldf_value,
			page_set.code_short_desc_txt AS page_set,
			inv.cd AS phc_cd,
			a.data_type,
			a.Field_size,
			c.class_cd AS data_source
		INTO #LDF_DATA
		FROM [dbo].nrt_ldf_data a WITH (NOLOCK)
		INNER JOIN 
		dbo.nrt_srte_LDF_PAGE_SET page_set WITH ( NOLOCK) 
		ON  
		page_set.ldf_page_id =a.ldf_page_id 
		LEFT JOIN [dbo].nrt_srte_Codeset c WITH (NOLOCK) 
			ON a.code_set_nm = c.code_set_nm
        INNER JOIN [dbo].nrt_INVESTIGATION inv WITH (NOLOCK) 
            on a.business_object_uid = inv.public_health_case_uid
		INNER JOIN [dbo].LDF_DATAMART_TABLE_REF b WITH (NOLOCK) 
			ON inv.cd = b.condition_cd
		INNER JOIN #LDF_UID_LIST l 
			ON l.ldf_uid = a.ldf_uid	
				
		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_DATA;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


		------------------------------------------------------------------------------------------------------------------------------------------


		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_DATA_TRANSLATED_ROWS_NE'; 
				
		IF OBJECT_ID('#LDF_DATA_TRANSLATED_ROWS_NE', 'U') IS NOT NULL  
			DROP TABLE #LDF_DATA_TRANSLATED_ROWS_NE;
		
		SELECT  
			data_source,
			business_object_uid, 
			ldf_uid,
			code_set_nm,
			label_txt,
			phc_cd,
			splitted_ldf.item AS COL1
		INTO #LDF_DATA_TRANSLATED_ROWS_NE
		FROM #LDF_DATA f 
		OUTER APPLY [dbo].[NBS_Strings_Split] (f.LDF_VALUE, '|') splitted_ldf
		WHERE DATALENGTH(splitted_ldf.item) > 0;
		
		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_DATA_TRANSLATED_ROWS_NE;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no); 


		------------------------------------------------------------------------------------------------------------------------------------------	
			

		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_BASE_CODED_TRANSLATED'; 

		IF OBJECT_ID('#LDF_BASE_CODED_TRANSLATED', 'U') IS NOT NULL  
			DROP TABLE #LDF_BASE_CODED_TRANSLATED;

		SELECT 	
			CASE 
				WHEN cvg.code_desc_txt IS NOT NULL AND DATALENGTH(cvg.code_desc_txt) > 0 THEN cvg.code_desc_txt 
				ELSE col1 
			END AS col1,
			TRIM(cvg.code_desc_txt) AS code_short_desc_txt, 
			ldf.code_set_nm,
			business_object_uid, 
			ldf_uid,
			data_source,
			phc_cd,
			label_txt					
		INTO #LDF_BASE_CODED_TRANSLATED
		FROM #LDF_DATA_TRANSLATED_ROWS_NE ldf
		LEFT JOIN [dbo].nrt_srte_Code_value_general cvg WITH (NOLOCK)
			ON cvg.code_set_nm=ldf.code_set_nm 	AND cvg.code=ldf.col1 AND ldf.data_source='code_value_general';
	
		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_BASE_CODED_TRANSLATED;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no); 


		------------------------------------------------------------------------------------------------------------------------------------------
				

		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_BASE_CLINICAL_TRANSLATED'; 

		IF OBJECT_ID('#LDF_BASE_CLINICAL_TRANSLATED', 'U') IS NOT NULL  
			DROP TABLE #LDF_BASE_CLINICAL_TRANSLATED;

		SELECT 	
			--col1, 
			CASE 
				WHEN cvg.code_desc_txt IS NOT NULL AND DATALENGTH(cvg.code_desc_txt) > 0 THEN cvg.code_desc_txt 
				ELSE col1 
			END AS col1,
			cvg.code_desc_txt as code_short_desc_txt, 
			ldf.code_set_nm,
			business_object_uid, 
			data_source,
			label_txt,
			phc_cd,
			ldf_uid
		INTO #LDF_BASE_CLINICAL_TRANSLATED
		FROM #LDF_BASE_CODED_TRANSLATED ldf
		LEFT JOIN [dbo].nrt_srte_Code_value_clinical cvg WITH (NOLOCK)
			ON cvg.code_set_nm=ldf.code_set_nm AND cvg.code=ldf.col1 AND ldf.data_source='code_value_clinical';
	
		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_BASE_CLINICAL_TRANSLATED;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

			
		------------------------------------------------------------------------------------------------------------------------------------------	


		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_BASE_STATE_TRANSLATED'; 

		IF OBJECT_ID('#LDF_BASE_STATE_TRANSLATED', 'U') IS NOT NULL  
			DROP TABLE #LDF_BASE_STATE_TRANSLATED;

		SELECT 	
			--col1,  
			CASE 
				WHEN cvg.code_desc_txt IS NOT NULL AND DATALENGTH(cvg.code_desc_txt) > 0 THEN cvg.code_desc_txt 
				ELSE col1 
			END AS col1,
			business_object_uid, 
			cvg.code_desc_txt AS code_short_desc_txt, 
			ldf_uid,
			ldf.code_set_nm,
			label_txt,
			phc_cd,
			data_source
		INTO #LDF_BASE_STATE_TRANSLATED
		FROM #LDF_BASE_CLINICAL_TRANSLATED ldf
		LEFT JOIN [dbo].v_nrt_srte_state_code cvg WITH (NOLOCK)
			ON cvg.code_set_nm=ldf.code_set_nm AND cvg.state_cd=ldf.col1 AND ldf.data_source IN ('STATE_CCD', 'V_state_code');
				
		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_BASE_STATE_TRANSLATED;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);		

		
		------------------------------------------------------------------------------------------------------------------------------------------	

		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_BASE_COUNTRY_TRANSLATED'; 

		IF OBJECT_ID('#LDF_BASE_COUNTRY_TRANSLATED', 'U') IS NOT NULL  
			DROP TABLE #LDF_BASE_COUNTRY_TRANSLATED;

		SELECT
			--col1,  
			CASE 
				WHEN cvg.code_desc_txt IS NOT NULL AND DATALENGTH(cvg.code_desc_txt) > 0 THEN cvg.code_desc_txt 
				ELSE col1 
			END AS col1,
			business_object_uid, 
			cvg.code_desc_txt as code_short_desc_txt, 
			ldf_uid,
			ldf.code_set_nm,
			label_txt,
			phc_cd,
			data_source
		INTO #LDF_BASE_COUNTRY_TRANSLATED
		FROM #LDF_BASE_STATE_TRANSLATED ldf
		LEFT JOIN [dbo].nrt_srte_Country_code cvg WITH (NOLOCK)
			ON cvg.code_set_nm=ldf.code_set_nm AND cvg.code=ldf.col1 AND ldf.data_source in ('COUNTRY_CODE');
		
		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_BASE_COUNTRY_TRANSLATED;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
				
			
		------------------------------------------------------------------------------------------------------------------------------------------	
				

		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_BASE_COUNTRY_TRANSLATED_FINAL'; 

		IF OBJECT_ID('#LDF_BASE_COUNTRY_TRANSLATED_FINAL', 'U') IS NOT NULL  
			DROP TABLE #LDF_BASE_COUNTRY_TRANSLATED_FINAL;

		-- Use a CTE to compute the aggregated Col1 and select distinct rows
		WITH AggregatedData AS (
			SELECT 
				business_object_uid,
				ldf_uid,
				code_short_desc_txt,
				code_set_nm,
				label_txt,
				phc_cd,
				data_source,
				STRING_AGG(Col1, '| ') AS Col1
			FROM #LDF_BASE_COUNTRY_TRANSLATED
			GROUP BY 
				business_object_uid,
				ldf_uid,
				code_short_desc_txt,
				code_set_nm,
				label_txt,
				phc_cd,
				data_source
		)
		SELECT 
			business_object_uid,
			code_short_desc_txt,
			ldf_uid,
			code_set_nm,
			label_txt,
			phc_cd,
			data_source,
			TRIM(Col1) AS Col1
		INTO #LDF_BASE_COUNTRY_TRANSLATED_FINAL
		FROM AggregatedData;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_BASE_COUNTRY_TRANSLATED_FINAL;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
		

		------------------------------------------------------------------------------------------------------------------------------------------


			SET 
				@PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET 
				@PROC_STEP_NAME = 'GENERATING #LDF_TRANSLATED_DATA'; 

			IF OBJECT_ID('#LDF_TRANSLATED_DATA', 'U') IS NOT NULL  
				DROP TABLE #LDF_TRANSLATED_DATA;
			
			SELECT 
				a.col1,  
				a.business_object_uid, 
				a.code_short_desc_txt, 
				a.code_set_nm,
				a.data_source,
				a.phc_cd,
				b.cdc_national_id,
				b.business_object_nm,
				b.condition_cd,
				b.custom_subform_metadata_uid,
				b.page_set,
				b.ldf_uid,
				b.label_txt,
				b.LDF_PAGE_SET,
				b.data_type, 
				b.Field_size
			INTO #LDF_TRANSLATED_DATA 
			FROM [dbo].D_LDF_META_DATA b WITH (NOLOCK)
			RIGHT OUTER JOIN #LDF_BASE_COUNTRY_TRANSLATED_FINAL a
				ON a.ldf_uid= b.ldf_uid 
				AND b.ldf_uid IS NOT NULL 
					
			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #LDF_TRANSLATED_DATA;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
							
	
				
		------------------------------------------------------------------------------------------------------------------------------------------	

		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_DIMENSIONAL_DATA'; 	

		IF OBJECT_ID('#LDF_DIMENSIONAL_DATA', 'U') IS NOT NULL  
			DROP TABLE #LDF_DIMENSIONAL_DATA_N;	

		SELECT 
			dim.col1,  
			dim.business_object_uid AS INVESTIGATION_UID, 
			dim.code_short_desc_txt, 
			dim.ldf_uid,
			dim.code_set_nm,
			dim.label_txt,
			dim.data_source,
			dim.cdc_national_id,
			dim.business_object_nm,
			dim.condition_cd,
			dim.custom_subform_metadata_uid,
			dim.page_set,
			CASE 
				WHEN ISNULL(LEN(ref.datamart_column_nm), 0) < 2 
				THEN ref2.datamart_column_nm 
				ELSE ref.datamart_column_nm 
			END AS datamart_column_nm,						
			dim.phc_cd,
			dim.data_type, 
			dim.field_size
		INTO #LDF_DIMENSIONAL_DATA 	
		FROM #LDF_TRANSLATED_DATA dim 
		LEFT JOIN [dbo].LDF_DATAMART_COLUMN_REF ref WITH(NOLOCK) 
			ON dim.ldf_uid = ref.ldf_uid
		LEFT JOIN [dbo].ldf_datamart_column_ref ref2 WITH(NOLOCK) 
			ON dim.cdc_national_id = ref2.cdc_national_id AND ref2.ldf_uid IS NULL AND ref.cdc_national_id IS NULL

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_DIMENSIONAL_DATA;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
	
				
		------------------------------------------------------------------------------------------------------------------------------------------	

		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_DIMENSIONAL_DATA_N'; 

		IF OBJECT_ID('#LDF_DIMENSIONAL_DATA_N', 'U') IS NOT NULL  
			DROP TABLE #LDF_DIMENSIONAL_DATA_N;

		SELECT 
			a.*
		INTO #LDF_DIMENSIONAL_DATA_N
		FROM #LDF_DIMENSIONAL_DATA a
		LEFT JOIN [dbo].LDF_DIMENSIONAL_DATA b WITH (NOLOCK)
			ON b.LDF_UID = a.LDF_UID
		WHERE b.LDF_UID IS NULL;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_DIMENSIONAL_DATA_N;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no); 

		------------------------------------------------------------------------------------------------------------------------------------------	


		SET 
			@PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET 
			@PROC_STEP_NAME = 'GENERATING #LDF_DIMENSIONAL_DATA_E'; 

		IF OBJECT_ID('#LDF_DIMENSIONAL_DATA_E', 'U') IS NOT NULL  
			DROP TABLE #LDF_DIMENSIONAL_DATA_E;

		SELECT 
			a.*
		INTO #LDF_DIMENSIONAL_DATA_E
		FROM #LDF_DIMENSIONAL_DATA a
		INNER JOIN [dbo].LDF_DIMENSIONAL_DATA b WITH (NOLOCK)
			ON b.LDF_UID = a.LDF_UID;

		IF
			@debug = 'true'
			SELECT @Proc_Step_Name AS step, *
			FROM #LDF_DIMENSIONAL_DATA_E;

		INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES 
			(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no); 

		------------------------------------------------------------------------------------------------------------------------------------------	

			
		BEGIN TRANSACTION

			SET 
				@PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET 
				@PROC_STEP_NAME = 'INSERT NEW LDF_DIMENSIONAL_DATA'; 
				
			INSERT INTO [dbo].LDF_DIMENSIONAL_DATA(
				COL1,
				INVESTIGATION_UID,
				CODE_SHORT_DESC_TXT,
				LDF_UID,
				CODE_SET_NM,
				LABEL_TXT,
				DATA_SOURCE,
				CDC_NATIONAL_ID,
				BUSINESS_OBJECT_NM,
				CONDITION_CD,
				CUSTOM_SUBFORM_METADATA_UID,
				PAGE_SET,
				DATAMART_COLUMN_NM,
				PHC_CD,
				DATA_TYPE,
				FIELD_SIZE
			)
			SELECT
				COL1,
				INVESTIGATION_UID,
				CODE_SHORT_DESC_TXT,
				LDF_UID,
				CODE_SET_NM,
				LABEL_TXT,
				DATA_SOURCE,
				CDC_NATIONAL_ID,
				BUSINESS_OBJECT_NM,
				CONDITION_CD,
				CUSTOM_SUBFORM_METADATA_UID,
				PAGE_SET,
				DATAMART_COLUMN_NM,
				PHC_CD,
				DATA_TYPE,
				FIELD_SIZE
			FROM #LDF_DIMENSIONAL_DATA_N;

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #LDF_DIMENSIONAL_DATA_N;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no); 
			

		COMMIT TRANSACTION;


		------------------------------------------------------------------------------------------------------------------------------------------	

			
		BEGIN TRANSACTION

			SET 
				@PROC_STEP_NO = @PROC_STEP_NO + 1;
			SET 
				@PROC_STEP_NAME = 'UPDATE EXISTING LDF_DIMENSIONAL_DATA'; 

			UPDATE D
			SET 
				D.COL1 = S.COL1,
				D.INVESTIGATION_UID = S.INVESTIGATION_UID,
				D.CODE_SHORT_DESC_TXT = S.CODE_SHORT_DESC_TXT,				
				D.CODE_SET_NM = S.CODE_SET_NM,
				D.LABEL_TXT = S.LABEL_TXT,
				D.DATA_SOURCE = S.DATA_SOURCE,
				D.CDC_NATIONAL_ID = S.CDC_NATIONAL_ID,
				D.BUSINESS_OBJECT_NM = S.BUSINESS_OBJECT_NM,
				D.CONDITION_CD = S.CONDITION_CD,
				D.CUSTOM_SUBFORM_METADATA_UID = S.CUSTOM_SUBFORM_METADATA_UID,
				D.PAGE_SET = S.PAGE_SET,
				D.DATAMART_COLUMN_NM = S.DATAMART_COLUMN_NM,
				D.PHC_CD = S.PHC_CD,
				D.DATA_TYPE = S.DATA_TYPE,
				D.FIELD_SIZE = S.FIELD_SIZE				
			FROM [dbo].LDF_DIMENSIONAL_DATA D 
			INNER JOIN #LDF_DIMENSIONAL_DATA_E S 
				ON S.LDF_UID = D.LDF_UID	

			SELECT @ROWCOUNT_NO = @@ROWCOUNT;

			IF
				@debug = 'true'
				SELECT @Proc_Step_Name AS step, *
				FROM #LDF_DIMENSIONAL_DATA_E;

			INSERT INTO [dbo].[job_flow_log]
				(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES 
				(@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no); 
			

		COMMIT TRANSACTION;
			
		------------------------------------------------------------------------------------------------------------------------------------------		
		
			SET @Proc_Step_no = 999;
			SET @Proc_Step_Name = 'SP_COMPLETE';
			SELECT @ROWCOUNT_NO = 0;

			INSERT INTO [dbo].[job_flow_log] 
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);
		
		-------------------------------------------------------------------------------------------
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
