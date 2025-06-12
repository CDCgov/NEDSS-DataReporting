IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_d_vaccination_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_d_vaccination_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_d_vaccination_postprocessing] @vac_uids nvarchar(max), @debug bit = 'false'
as
BEGIN

	DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
	DECLARE @ColumnAdd_sql NVARCHAR(MAX) = '';
	DECLARE @PivotColumns NVARCHAR(MAX) = '';
	DECLARE @Insert_sql NVARCHAR(MAX) = '';
    DECLARE @Update_sql NVARCHAR(MAX) = '';
	DECLARE @Col_number BIGINT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';

    DECLARE
        @Dataflow_Name VARCHAR(200) = 'D_VACCINATION Post-Processing Event';
    DECLARE
        @Package_Name VARCHAR(200) = 'sp_d_vaccination_postprocessing';

	BEGIN TRY
	    SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmssffff')) AS bigint);

        if
            @debug = 'true'
            select @batch_id;


        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT], [Msg_Description1])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT(@vac_uids, 199));


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #NEW_COLUMNS';

        SELECT RDB_COLUMN_NM
        INTO #NEW_COLUMNS
        FROM dbo.NRT_METADATA_COLUMNS
        WHERE NEW_FLAG = 1
        AND RDB_COLUMN_NM NOT IN (
          SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = 'D_VACCINATION'
                    AND TABLE_SCHEMA = 'dbo');

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @Dataflow_Name, @Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' ADDING COLUMNS TO D_VACCINATION';

        SELECT @ColumnAdd_sql =
               STRING_AGG('ALTER TABLE dbo.D_VACCINATION ADD ' + QUOTENAME(RDB_COLUMN_NM) + ' VARCHAR(50);',
                          CHAR(13) + CHAR(10))
        FROM #NEW_COLUMNS;


        -- if there aren't any new columns to add, sp_executesql won't fire
        IF @ColumnAdd_sql IS NOT NULL
            BEGIN
                EXEC sp_executesql @ColumnAdd_sql;
            END

		if
            @debug = 'true'
            select @Proc_Step_Name as step, @ColumnAdd_sql
            ;

        UPDATE dbo.NRT_METADATA_COLUMNS
        SET NEW_FLAG = 0
        WHERE NEW_FLAG = 1
        AND TABLE_NAME = 'D_VACCINATION'
        AND RDB_COLUMN_NM in (
            SELECT COLUMN_NAME
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = 'D_VACCINATION'
              AND TABLE_SCHEMA = 'dbo'
        );

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #D_VACCINATION_INIT';

        SELECT
        	ixk.D_VACCINATION_KEY as D_VACCINATION_KEY,
           	ix.ADD_TIME ,
			ix.ADD_USER_ID,
			ix.AGE_AT_VACCINATION ,
			ix.AGE_AT_VACCINATION_UNIT ,
			ix.LAST_CHG_TIME,
			ix.LAST_CHG_USER_ID,
			ix.LOCAL_ID,
			ix.RECORD_STATUS_CD,
			ix.RECORD_STATUS_TIME,
			ix.VACCINE_ADMINISTERED_DATE,
			ix.VACCINE_DOSE_NBR,
			ix.VACCINATION_ADMINISTERED_NM ,
			ix.VACCINATION_ANATOMICAL_SITE ,
			ix.VACCINATION_UID ,
			ix.VACCINE_EXPIRATION_DT,
			ix.VACCINE_INFO_SOURCE,
			ix.VACCINE_LOT_NUMBER_TXT,
			ix.VACCINE_MANUFACTURER_NM ,
			ix.VERSION_CTRL_NBR,
			ix.ELECTRONIC_IND
        INTO #D_VACCINATION_INIT
        FROM dbo.NRT_VACCINATION ix
            LEFT JOIN dbo.NRT_VACCINATION_KEY ixk
                ON ix.vaccination_uid = ixk.vaccination_uid
        WHERE ix.vaccination_uid in (SELECT value FROM STRING_SPLIT(@vac_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #D_VACCINATION_INIT;

		SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;




        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #VACCINATION_ANSWERS';

        SELECT vaccination_uid,
               rdb_column_nm,
               answer_val
        INTO #VACCINATION_ANSWERS
        FROM dbo.NRT_VACCINATION_ANSWER
        WHERE vaccination_uid in (SELECT value FROM STRING_SPLIT(@vac_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #VACCINATION_ANSWERS;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'Update nrt_vaccination_key updated_dttm';

        UPDATE tgt 
        SET tgt.[updated_dttm] = GETDATE()
        FROM [dbo].NRT_VACCINATION_KEY tgt 
        INNER JOIN #D_VACCINATION_INIT g 
            ON g.D_VACCINATION_KEY = tgt.D_VACCINATION_KEY
            AND g.VACCINATION_UID = tgt.VACCINATION_UID;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id,@Dataflow_Name,@Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO nrt_vaccination_key';

        INSERT INTO dbo.NRT_VACCINATION_KEY(vaccination_uid)
        SELECT
            vaccination_uid
        FROM #D_VACCINATION_INIT
        WHERE D_VACCINATION_KEY IS NULL;


        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id,@Dataflow_Name,@Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE D_VACCINATION';

        SET @PivotColumns = (
        	SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',')
            FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_VACCINATION'
        );

		SET @Col_number = (
			SELECT COUNT(*)
			FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_VACCINATION'
		);

        /*
        Query is built one part after another, adding in extra parts
        for the dynamic columns if @Col_number > 0
        */
        SET @Update_sql = '
        UPDATE dl
        SET
        	dl.D_VACCINATION_KEY = ix.D_VACCINATION_KEY,
           	dl.ADD_TIME = ix.ADD_TIME ,
			dl.ADD_USER_ID = ix.ADD_USER_ID,
			dl.AGE_AT_VACCINATION = ix.AGE_AT_VACCINATION ,
			dl.AGE_AT_VACCINATION_UNIT = ix.AGE_AT_VACCINATION_UNIT ,
			dl.LAST_CHG_TIME = ix.LAST_CHG_TIME,
			dl.LAST_CHG_USER_ID = ix.LAST_CHG_USER_ID,
			dl.LOCAL_ID = ix.LOCAL_ID,
			dl.RECORD_STATUS_CD = ix.RECORD_STATUS_CD,
			dl.RECORD_STATUS_TIME = ix.RECORD_STATUS_TIME,
			dl.VACCINE_ADMINISTERED_DATE = ix.VACCINE_ADMINISTERED_DATE,
			dl.VACCINE_DOSE_NBR = ix.VACCINE_DOSE_NBR,
			dl.VACCINATION_ADMINISTERED_NM = ix.VACCINATION_ADMINISTERED_NM ,
			dl.VACCINATION_ANATOMICAL_SITE = ix.VACCINATION_ANATOMICAL_SITE ,
			dl.VACCINATION_UID = ix.VACCINATION_UID ,
			dl.VACCINE_EXPIRATION_DT = ix.VACCINE_EXPIRATION_DT,
			dl.VACCINE_INFO_SOURCE = ix.VACCINE_INFO_SOURCE,
			dl.VACCINE_LOT_NUMBER_TXT = ix.VACCINE_LOT_NUMBER_TXT,
			dl.VACCINE_MANUFACTURER_NM = ix.VACCINE_MANUFACTURER_NM ,
			dl.VERSION_CTRL_NBR = ix.VERSION_CTRL_NBR,
			dl.ELECTRONIC_IND = ix.ELECTRONIC_IND
        ' + CASE
                WHEN @Col_number > 0 THEN ',' + (SELECT STRING_AGG('dl.' + QUOTENAME(RDB_COLUMN_NM) + ' = pv.' + QUOTENAME(RDB_COLUMN_NM),',')
                    FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_VACCINATION' )
            ELSE '' END +
        ' FROM
        #D_VACCINATION_INIT ix
        LEFT JOIN dbo.D_VACCINATION dl
            ON ix.D_VACCINATION_KEY = dl.D_VACCINATION_KEY '
        + CASE
              WHEN @Col_number > 0 THEN
        ' LEFT JOIN (
        SELECT VACCINATION_UID, ' + @PivotColumns + '
        FROM (
            SELECT
                VACCINATION_UID,
                RDB_COLUMN_NM,
                ANSWER_VAL
            FROM
                #VACCINATION_ANSWERS
        ) AS SourceData
        PIVOT (
            MAX(answer_val)
            FOR rdb_column_nm IN (' + @PivotColumns + ')
        ) AS PivotTable) pv
        ON pv.VACCINATION_UID = ix.VACCINATION_UID'
        ELSE ' ' END +
        ' WHERE
        ix.D_VACCINATION_KEY IS NOT NULL;';


     	if
            @debug = 'true'
            select @Proc_Step_Name as step, @Update_sql
            ;

     	exec sp_executesql @Update_sql;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO D_VACCINATION';

        SET @PivotColumns = (
            SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',')
                FROM dbo.NRT_METADATA_COLUMNS  where TABLE_NAME ='D_VACCINATION'
        );

        /*
        Query is built one part after another, adding in extra parts
        for the dynamic columns if @Col_number > 0
        */
        SET @Insert_sql = '
        INSERT INTO dbo.D_VACCINATION (
            D_VACCINATION_KEY,
            ADD_TIME ,
            ADD_USER_ID,
            AGE_AT_VACCINATION ,
            AGE_AT_VACCINATION_UNIT ,
            LAST_CHG_TIME,
            LAST_CHG_USER_ID,
            LOCAL_ID,
            RECORD_STATUS_CD,
            RECORD_STATUS_TIME,
            VACCINE_ADMINISTERED_DATE,
            VACCINE_DOSE_NBR,
            VACCINATION_ADMINISTERED_NM ,
            VACCINATION_ANATOMICAL_SITE ,
            VACCINATION_UID ,
            VACCINE_EXPIRATION_DT,
            VACCINE_INFO_SOURCE,
            VACCINE_LOT_NUMBER_TXT,
            VACCINE_MANUFACTURER_NM ,
            VERSION_CTRL_NBR,
            ELECTRONIC_IND
            ' + CASE
            WHEN @Col_number > 0 THEN ',' + (SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',') FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_VACCINATION' ) + ') '
            ELSE ')' end +
            ' SELECT
                ixk.D_VACCINATION_KEY,
                ix.ADD_TIME ,
                ix.ADD_USER_ID,
                ix.AGE_AT_VACCINATION ,
                ix.AGE_AT_VACCINATION_UNIT ,
                ix.LAST_CHG_TIME,
                ix.LAST_CHG_USER_ID,
                ix.LOCAL_ID,
                ix.RECORD_STATUS_CD,
                ix.RECORD_STATUS_TIME,
                ix.VACCINE_ADMINISTERED_DATE,
                ix.VACCINE_DOSE_NBR,
                ix.VACCINATION_ADMINISTERED_NM ,
                ix.VACCINATION_ANATOMICAL_SITE ,
                ix.VACCINATION_UID ,
                ix.VACCINE_EXPIRATION_DT,
                ix.VACCINE_INFO_SOURCE,
                ix.VACCINE_LOT_NUMBER_TXT,
                ix.VACCINE_MANUFACTURER_NM ,
                ix.VERSION_CTRL_NBR,
                ix.ELECTRONIC_IND
                ' + CASE
                        WHEN @Col_number > 0 THEN ',' + (SELECT STRING_AGG('pv.' + QUOTENAME(RDB_COLUMN_NM), ',') FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_VACCINATION' )
                        ELSE ' '
                    END +
                ' FROM #D_VACCINATION_INIT ix
                LEFT JOIN dbo.NRT_VACCINATION_KEY ixk
                    ON ixk.VACCINATION_UID = ix.VACCINATION_UID
                LEFT JOIN dbo.D_VACCINATION dint
                    ON ixk.D_VACCINATION_KEY = dint.D_VACCINATION_KEY
                        '
	            + CASE
	            WHEN @Col_number > 0 THEN
	         ' LEFT JOIN (
	        SELECT VACCINATION_UID, ' + @PivotColumns + '
	        FROM (
	            SELECT
	                VACCINATION_UID,
	                RDB_COLUMN_NM,
	                ANSWER_VAL
	            FROM
	                #VACCINATION_ANSWERS
	        ) AS SourceData
	        PIVOT (
	            MAX(answer_val)
	            FOR rdb_column_nm IN (' + @PivotColumns + ')
	        ) AS PivotTable) pv
	        ON pv.VACCINATION_UID = ix.VACCINATION_UID '
	            ELSE ' ' END
	            + ' WHERE dint.D_VACCINATION_KEY IS NULL
	                and ixk.D_VACCINATION_KEY IS NOT NULL';


        if
            @debug = 'true'
            select @Proc_Step_Name as step, @Insert_sql
            ;

		exec sp_executesql @Insert_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id,@Dataflow_Name,@Package_Name, 'COMPLETE', 999, 'COMPLETE', 0);

        SELECT
            nrt.vaccination_uid                                 AS public_health_case_uid,
            nrt.patient_uid                                     AS patient_uid,
            null                                                AS observation_uid,
            dtm.Datamart                                        AS datamart,
            dtm.condition_cd                                    AS condition_cd,
            dtm.Stored_Procedure                                AS stored_procedure,
            null                                                AS investigation_form_cd
        FROM #D_VACCINATION_INIT v
            INNER JOIN dbo.nrt_vaccination nrt with (nolock) ON v.VACCINATION_UID = nrt.vaccination_uid
            INNER JOIN dbo.nrt_datamart_metadata dtm with (nolock) ON dtm.Datamart = 'Covid_Vaccination_Datamart'-- replace with 'Covid_Vaccination_Datamart'
        WHERE nrt.material_cd IN('207', '208', '213');

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

		INSERT INTO [dbo].[job_flow_log] (
			batch_id,
			[Dataflow_Name],
			[package_Name],
			[Status_Type],
			[step_number],
			[step_name],
			[Error_Description],
			[row_count]
		)
		VALUES (
		   @batch_id,
		   @Dataflow_Name,
		   @Package_Name,
		   'ERROR' ,
		   @Proc_Step_no,
		   @PROC_STEP_NAME,
		   @FullErrorMessage,
		   0
		);


		return -1 ;

	END CATCH

END;