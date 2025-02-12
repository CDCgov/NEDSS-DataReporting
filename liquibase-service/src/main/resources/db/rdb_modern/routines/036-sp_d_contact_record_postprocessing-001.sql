CREATE OR ALTER PROCEDURE dbo.sp_d_contact_record_postprocessing(
    @contact_uids NVARCHAR(MAX),
    @debug bit = 'false')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @ColumnAdd_sql NVARCHAR(MAX) = '';
    DECLARE @PivotColumns NVARCHAR(MAX) = '';
    DECLARE @Insert_sql NVARCHAR(MAX) = '';
    DECLARE @Update_sql NVARCHAR(MAX) = '';
    DECLARE @DataAsset_nm VARCHAR(100) = 'D_CONTACT_RECORD';
    -- number of columns for the dynamic sql
    DECLARE @Col_number BIGINT = 0;




    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmss')) AS bigint);

        if
	        @debug = 'true'
	        select @batch_id;


        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @DataAsset_nm, @DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);



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
                WHERE TABLE_NAME = 'D_CONTACT_RECORD'
                    AND TABLE_SCHEMA = 'dbo');

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @DataAsset_nm, @DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #NEW_COLUMNS;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'ADDING COLUMNS TO D_CONTACT_RECORD';

        SELECT @ColumnAdd_sql =
               STRING_AGG('ALTER TABLE dbo.D_CONTACT_RECORD ADD ' + QUOTENAME(RDB_COLUMN_NM) + ' VARCHAR(50);',
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
          AND TABLE_NAME = 'D_CONTACT_RECORD'
          AND RDB_COLUMN_NM in (select RDB_COLUMN_NM from #NEW_COLUMNS);

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@DataAsset_nm,@DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #CONTACT_INIT';

        SELECT
        	ixk.D_CONTACT_RECORD_KEY as D_CONTACT_RECORD_KEY,
            ADD_TIME,
            ADD_USER_ID ,
            CONTACT_ENTITY_EPI_LINK_ID ,
            CTT_STATUS,
            ix.CONTACT_UID as CONTACT_UID,
            CTT_DISPO_DT,
            CTT_EVAL_DT ,
            CTT_EVAL_NOTES ,
            CTT_INV_ASSIGNED_DT ,
            LAST_CHG_TIME ,
            LAST_CHG_USER_ID ,
            LOCAL_ID ,
            CTT_NAMED_ON_DT ,
            PROGRAM_JURISDICTION_OID ,
            RECORD_STATUS_CD  ,
            RECORD_STATUS_TIME ,
            CTT_RISK_NOTES ,
            SUBJECT_ENTITY_EPI_LINK_ID ,
            CTT_SYMP_ONSET_DT ,
            CTT_SYMP_NOTES ,
            CTT_TRT_END_DT ,
            CTT_TRT_START_DT ,
            CTT_TRT_NOTES ,
            CTT_NOTES,
            CTT_PROGRAM_AREA,
            CTT_JURISDICTION_NM ,
            CTT_SHARED_IND,
            CTT_SYMP_IND,
            CTT_RISK_IND ,
            CTT_EVAL_COMPLETED ,
            CTT_TRT_INITIATED_IND  ,
            CTT_DISPOSITION,
            CTT_PRIORITY,
            CTT_RELATIONSHIP ,
            CTT_TRT_NOT_START_RSN  ,
            CTT_TRT_NOT_COMPLETE_RSN,
            CTT_PROCESSING_DECISION ,
            CTT_GROUP_LOT_ID  ,
            CTT_TRT_COMPLETE_IND,
            CTT_HEALTH_STATUS,
            CTT_REFERRAL_BASIS,
            VERSION_CTRL_NBR
        INTO #CONTACT_INIT
        FROM dbo.NRT_CONTACT ix
            LEFT JOIN dbo.NRT_CONTACT_KEY ixk
                ON ix.contact_uid = ixk.contact_uid
        WHERE ix.contact_uid in (SELECT value FROM STRING_SPLIT(@contact_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #CONTACT_INIT;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@DataAsset_nm,@DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;




        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #CONTACT_ANSWERS';

        SELECT contact_uid,
               rdb_column_nm,
               answer_val
        INTO #CONTACT_ANSWERS
        FROM dbo.NRT_CONTACT_ANSWER
        WHERE contact_uid in (SELECT value FROM STRING_SPLIT(@contact_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #CONTACT_ANSWERS;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@DataAsset_nm,@DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO nrt_contact_key';

        INSERT INTO dbo.NRT_CONTACT_KEY(contact_uid)
        SELECT
            contact_uid
        FROM #CONTACT_INIT
        WHERE D_CONTACT_RECORD_KEY IS NULL;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id,@DataAsset_nm,@DataAsset_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'UPDATE D_CONTACT_RECORD';

        SET @PivotColumns = (
        	SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',')
            FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_CONTACT_RECORD'
        );

		SET @Col_number = (
			SELECT COUNT(*)
			FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_CONTACT_RECORD'
		);

        /*
        Query is built one part after another, adding in extra parts
        for the dynamic columns if @Col_number > 0
        */
        SET @Update_sql = '
        UPDATE dl
        SET
        dl.ADD_TIME = ix.ADD_TIME,
        dl.ADD_USER_ID  = ix.ADD_USER_ID ,
        dl.CONTACT_ENTITY_EPI_LINK_ID  = ix.CONTACT_ENTITY_EPI_LINK_ID ,
        dl.CTT_STATUS = ix.CTT_STATUS,
        dl.CTT_DISPO_DT = ix.CTT_DISPO_DT,
        dl.CTT_EVAL_DT  = ix.CTT_EVAL_DT ,
        dl.CTT_EVAL_NOTES  = ix.CTT_EVAL_NOTES ,
        dl.CTT_INV_ASSIGNED_DT  = ix.CTT_INV_ASSIGNED_DT ,
        dl.LAST_CHG_TIME  = ix.LAST_CHG_TIME ,
        dl.LAST_CHG_USER_ID  = ix.LAST_CHG_USER_ID ,
        dl.LOCAL_ID  = ix.LOCAL_ID ,
        dl.CTT_NAMED_ON_DT  = ix.CTT_NAMED_ON_DT ,
        dl.PROGRAM_JURISDICTION_OID  = ix.PROGRAM_JURISDICTION_OID ,
        dl.RECORD_STATUS_CD   = ix.RECORD_STATUS_CD  ,
        dl.RECORD_STATUS_TIME  = ix.RECORD_STATUS_TIME ,
        dl.CTT_RISK_NOTES  = ix.CTT_RISK_NOTES ,
        dl.SUBJECT_ENTITY_EPI_LINK_ID  = ix.SUBJECT_ENTITY_EPI_LINK_ID ,
        dl.CTT_SYMP_ONSET_DT  = ix.CTT_SYMP_ONSET_DT ,
        dl.CTT_SYMP_NOTES  = ix.CTT_SYMP_NOTES ,
        dl.CTT_TRT_END_DT  = ix.CTT_TRT_END_DT ,
        dl.CTT_TRT_START_DT  = ix.CTT_TRT_START_DT ,
        dl.CTT_TRT_NOTES  = ix.CTT_TRT_NOTES ,
        dl.CTT_NOTES = ix.CTT_NOTES,
        dl.CTT_PROGRAM_AREA = ix.CTT_PROGRAM_AREA,
        dl.CTT_JURISDICTION_NM  = ix.CTT_JURISDICTION_NM ,
        dl.CTT_SHARED_IND = ix.CTT_SHARED_IND,
        dl.CTT_SYMP_IND = ix.CTT_SYMP_IND,
        dl.CTT_RISK_IND  = ix.CTT_RISK_IND ,
        dl.CTT_EVAL_COMPLETED  = ix.CTT_EVAL_COMPLETED ,
        dl.CTT_TRT_INITIATED_IND   = ix.CTT_TRT_INITIATED_IND  ,
        dl.CTT_DISPOSITION = ix.CTT_DISPOSITION,
        dl.CTT_PRIORITY = ix.CTT_PRIORITY,
        dl.CTT_RELATIONSHIP  = ix.CTT_RELATIONSHIP ,
        dl.CTT_TRT_NOT_START_RSN   = ix.CTT_TRT_NOT_START_RSN  ,
        dl.CTT_TRT_NOT_COMPLETE_RSN = ix.CTT_TRT_NOT_COMPLETE_RSN,
        dl.CTT_PROCESSING_DECISION  = ix.CTT_PROCESSING_DECISION ,
        dl.CTT_GROUP_LOT_ID   = ix.CTT_GROUP_LOT_ID  ,
        dl.CTT_TRT_COMPLETE_IND = ix.CTT_TRT_COMPLETE_IND,
        dl.CTT_HEALTH_STATUS = ix.CTT_HEALTH_STATUS,
        dl.CTT_REFERRAL_BASIS = ix.CTT_REFERRAL_BASIS,
        dl.VERSION_CTRL_NBR = ix.VERSION_CTRL_NBR
        ' + CASE
                WHEN @Col_number > 0 THEN ',' + (SELECT STRING_AGG('dl.' + QUOTENAME(RDB_COLUMN_NM) + ' = pv.' + QUOTENAME(RDB_COLUMN_NM),',')
                    FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_CONTACT_RECORD' and RDB_COLUMN_NM  in (select rdb_column_nm from #CONTACT_ANSWERS))
            ELSE '' END +
        ' FROM
        #CONTACT_INIT ix
        LEFT JOIN dbo.D_CONTACT_RECORD dl
            ON ix.D_CONTACT_RECORD_KEY = dl.D_CONTACT_RECORD_KEY '
        + CASE
              WHEN @Col_number > 0 THEN
        ' LEFT JOIN (
        SELECT CONTACT_UID, ' + @PivotColumns + '
        FROM (
            SELECT
                CONTACT_UID,
                rdb_column_nm,
                answer_val
            FROM
                #CONTACT_ANSWERS
        ) AS SourceData
        PIVOT (
            MAX(answer_val)
            FOR rdb_column_nm IN (' + @PivotColumns + ')
        ) AS PivotTable) pv
        ON pv.CONTACT_UID = ix.CONTACT_UID'
        ELSE ' ' END +
        ' WHERE
        ix.D_CONTACT_RECORD_KEY IS NOT NULL;';


     	if
            @debug = 'true'
            select @Proc_Step_Name as step, @Update_sql
            ;

     	exec sp_executesql @Update_sql;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@DataAsset_nm,@DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = 'INSERT INTO D_CONTACT_RECORD';

        SET @PivotColumns = (
            SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',')
                FROM dbo.NRT_METADATA_COLUMNS  where TABLE_NAME ='D_CONTACT_RECORD'
        );

        /*
        Query is built one part after another, adding in extra parts
        for the dynamic columns if @Col_number > 0
        */
        SET @Insert_sql = '
        INSERT INTO dbo.D_CONTACT_RECORD (
            D_CONTACT_RECORD_KEY,
            ADD_TIME,
            ADD_USER_ID ,
            CONTACT_ENTITY_EPI_LINK_ID ,
            CTT_STATUS,
            CTT_DISPO_DT,
            CTT_EVAL_DT ,
            CTT_EVAL_NOTES ,
            CTT_INV_ASSIGNED_DT ,
            LAST_CHG_TIME ,
            LAST_CHG_USER_ID ,
            LOCAL_ID ,
            CTT_NAMED_ON_DT ,
            PROGRAM_JURISDICTION_OID ,
            RECORD_STATUS_CD  ,
            RECORD_STATUS_TIME ,
            CTT_RISK_NOTES ,
            SUBJECT_ENTITY_EPI_LINK_ID ,
            CTT_SYMP_ONSET_DT ,
            CTT_SYMP_NOTES ,
            CTT_TRT_END_DT ,
            CTT_TRT_START_DT ,
            CTT_TRT_NOTES ,
            CTT_NOTES,
            CTT_PROGRAM_AREA,
            CTT_JURISDICTION_NM ,
            CTT_SHARED_IND,
            CTT_SYMP_IND,
            CTT_RISK_IND ,
            CTT_EVAL_COMPLETED ,
            CTT_TRT_INITIATED_IND  ,
            CTT_DISPOSITION,
            CTT_PRIORITY,
            CTT_RELATIONSHIP ,
            CTT_TRT_NOT_START_RSN  ,
            CTT_TRT_NOT_COMPLETE_RSN,
            CTT_PROCESSING_DECISION ,
            CTT_GROUP_LOT_ID  ,
            CTT_TRT_COMPLETE_IND,
            CTT_HEALTH_STATUS,
            CTT_REFERRAL_BASIS,
            VERSION_CTRL_NBR
            ' + CASE
            WHEN @Col_number > 0 THEN ',' + (SELECT STRING_AGG(QUOTENAME(RDB_COLUMN_NM), ',') FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_CONTACT_RECORD' ) + ') '
            ELSE ')' end +
            ' SELECT
                ixk.D_CONTACT_RECORD_KEY,
                ix.ADD_TIME,
                ix.ADD_USER_ID ,
                ix.CONTACT_ENTITY_EPI_LINK_ID ,
                ix.CTT_STATUS,
                ix.CTT_DISPO_DT,
                ix.CTT_EVAL_DT ,
                ix.CTT_EVAL_NOTES ,
                ix.CTT_INV_ASSIGNED_DT ,
                ix.LAST_CHG_TIME ,
                ix.LAST_CHG_USER_ID ,
                ix.LOCAL_ID ,
                ix.CTT_NAMED_ON_DT ,
                ix.PROGRAM_JURISDICTION_OID ,
                ix.RECORD_STATUS_CD  ,
                ix.RECORD_STATUS_TIME ,
                ix.CTT_RISK_NOTES ,
                ix.SUBJECT_ENTITY_EPI_LINK_ID ,
                ix.CTT_SYMP_ONSET_DT ,
                ix.CTT_SYMP_NOTES ,
                ix.CTT_TRT_END_DT ,
                ix.CTT_TRT_START_DT ,
                ix.CTT_TRT_NOTES ,
                ix.CTT_NOTES,
                ix.CTT_PROGRAM_AREA,
                ix.CTT_JURISDICTION_NM ,
                ix.CTT_SHARED_IND,
                ix.CTT_SYMP_IND,
                ix.CTT_RISK_IND ,
                ix.CTT_EVAL_COMPLETED ,
                ix.CTT_TRT_INITIATED_IND  ,
                ix.CTT_DISPOSITION,
                ix.CTT_PRIORITY,
                ix.CTT_RELATIONSHIP ,
                ix.CTT_TRT_NOT_START_RSN  ,
                ix.CTT_TRT_NOT_COMPLETE_RSN,
                ix.CTT_PROCESSING_DECISION ,
                ix.CTT_GROUP_LOT_ID  ,
                ix.CTT_TRT_COMPLETE_IND,
                ix.CTT_HEALTH_STATUS,
                ix.CTT_REFERRAL_BASIS,
                ix.VERSION_CTRL_NBR
                ' + CASE
                        WHEN @Col_number > 0 THEN ',' + (SELECT STRING_AGG('pv.' + QUOTENAME(RDB_COLUMN_NM), ',') FROM dbo.NRT_METADATA_COLUMNS where TABLE_NAME ='D_CONTACT_RECORD' )
                        ELSE ' '
                    END +
                ' FROM #CONTACT_INIT ix
                LEFT JOIN dbo.NRT_CONTACT_KEY ixk
                    ON ixk.CONTACT_UID = ix.CONTACT_UID
                LEFT JOIN dbo.D_CONTACT_RECORD dint
                    ON ixk.D_CONTACT_RECORD_KEY = dint.D_CONTACT_RECORD_KEY
                        '
	            + CASE
	            WHEN @Col_number > 0 THEN
	         ' LEFT JOIN (
	        SELECT CONTACT_UID, ' + @PivotColumns + '
	        FROM (
	            SELECT
	                CONTACT_UID,
	                RDB_COLUMN_NM,
	                ANSWER_VAL
	            FROM
	                #CONTACT_ANSWERS
	        ) AS SourceData
	        PIVOT (
	            MAX(answer_val)
	            FOR rdb_column_nm IN (' + @PivotColumns + ')
	        ) AS PivotTable) pv
	        ON pv.CONTACT_UID = ix.CONTACT_UID '
	            ELSE ' ' END
	            + ' WHERE dint.D_CONTACT_RECORD_KEY IS NULL
	                and ixk.D_CONTACT_RECORD_KEY IS NOT NULL';


        if
            @debug = 'true'
            select @Proc_Step_Name as step, @Insert_sql
            ;

		exec sp_executesql @Insert_sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID,@DataAsset_nm,@DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;



        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id,@DataAsset_nm,@DataAsset_nm, 'COMPLETE', 999, 'COMPLETE', 0);

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , @DataAsset_nm
               , @DataAsset_nm
               , 'ERROR'
               , @Proc_Step_no
               , 'ERROR - ' + @Proc_Step_name
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0);


        return -1;

    END CATCH

END

    ;

