CREATE OR ALTER PROCEDURE dbo.sp_nrt_d_disease_site_postprocessing 
@phc_uids nvarchar(max),
@debug bit = 'false'
AS
BEGIN
    BEGIN TRY
        /* Logging */

            declare @RowCount_no bigint;
            declare @proc_step_no float = 0;
            declare @proc_step_name varchar(200) = '';
            declare @batch_id bigint;
            declare @create_dttm datetime2(7) = current_timestamp ;
            declare @update_dttm datetime2(7) = current_timestamp ;
            declare @dataflow_name varchar(200) = 'DISEASE_SITE POST-Processing';
            declare @package_name varchar(200) = 'RDB_MODERN.sp_nrt_disease_site_postprocessing';

        set @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint);

        SELECT @ROWCOUNT_NO = 0;

        BEGIN TRANSACTION

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @dataflow_name, @package_name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);
                
        COMMIT TRANSACTION;

--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_DISEASE_SITE_CD_TRANSLATED';

        IF OBJECT_ID('#S_DISEASE_SITE_CD_TRANSLATED', 'U') IS NOT NULL
        drop table #S_DISEASE_SITE_CD_TRANSLATED;
        
        SELECT 
            CAST(TB.ACT_UID AS BIGINT) AS TB_PAM_UID,
            TB.SEQ_NBR, 
            TB.DATAMART_COLUMN_NM, 
            TB.NBS_CASE_ANSWER_UID, 
            TB.ANSWER_TXT, 
            TB.CODE_SET_GROUP_ID, 
            TB.LAST_CHG_TIME,
            METADATA.CODE_SET_NM,
            CVG.CODE, 
            CVG.CODE_SHORT_DESC_TXT AS CODE_SHORT_DESC_TXT
        INTO #S_DISEASE_SITE_CD_TRANSLATED 
        FROM DBO.NRT_PAGE_CASE_ANSWER TB with (nolock)
        left join dbo.NRT_INVESTIGATION inv with(nolock)
            on TB.act_uid = inv.public_health_case_uid
        LEFT JOIN DBO.nrt_srte_Codeset_Group_Metadata METADATA with (nolock)
            ON METADATA.CODE_SET_GROUP_ID = TB.CODE_SET_GROUP_ID
        LEFT JOIN DBO.nrt_srte_CODE_VALUE_GENERAL CVG  with (nolock)
            ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
            AND CVG.CODE = TB.ANSWER_TXT
        WHERE TB.DATAMART_COLUMN_NM <> 'n/a'
        and isnull(tb.batch_id, 1) = isnull(inv.batch_id, 1)
        AND QUESTION_IDENTIFIER = 'TUB119'
        and TB.ACT_UID in (SELECT value FROM STRING_SPLIT(@phc_uids, ','))
        option (MAXDOP 1);

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_DISEASE_SITE_CD_TRANSLATED;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;

---------------------------------------------------------------------------------------------------------------------        


        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #S_DISEASE_SITE';

        IF OBJECT_ID('#S_DISEASE_SITE', 'U') IS NOT NULL
        drop table #S_DISEASE_SITE;


        SELECT 
            *, 
            CASE 
                WHEN CODE_SET_GROUP_ID IS NULL OR CODE_SET_GROUP_ID = '' 
                THEN ANSWER_TXT 
                WHEN CODE_SET_GROUP_ID<>'' THEN  CODE_SHORT_DESC_TXT 
                ELSE ANSWER_TXT
            END AS VALUE
        INTO #S_DISEASE_SITE
        FROM #S_DISEASE_SITE_CD_TRANSLATED with (nolock);

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #S_DISEASE_SITE;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;
-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Delete old keys from nrt_disease_site_group_key';

        DELETE FROM DBO.NRT_DISEASE_SITE_GROUP_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;


-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Delete old keys from nrt_disease_site_key ';

        DELETE FROM DBO.NRT_DISEASE_SITE_KEY;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Insert keys to nrt_disease_site_group_key ';

        INSERT INTO  DBO.NRT_DISEASE_SITE_GROUP_KEY(TB_PAM_UID) 
        SELECT DISTINCT TB_PAM_UID FROM #S_DISEASE_SITE;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Insert keys to dbo.nrt_disease_site_key';

        INSERT INTO  DBO.NRT_DISEASE_SITE_KEY(TB_PAM_UID, NBS_CASE_ANSWER_UID) 
        SELECT DISTINCT TB_PAM_UID, NBS_CASE_ANSWER_UID FROM #S_DISEASE_SITE;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #D_TB_PAM_TEMP';

        IF OBJECT_ID('#D_TB_PAM_TEMP', 'U') IS NOT NULL
        drop table #D_TB_PAM_TEMP;
        

        SELECT DISTINCT D_TB_PAM.TB_PAM_UID
            INTO #D_TB_PAM_TEMP
            FROM   (SELECT DISTINCT TB_PAM_UID FROM DBO.D_TB_PAM WHERE TB_PAM_UID IN (SELECT VALUE FROM STRING_SPLIT(@phc_uids, ','))) D_TB_PAM
            LEFT JOIN #S_DISEASE_SITE DISEASE_SITE  with (nolock)
                ON DISEASE_SITE.TB_PAM_UID = D_TB_PAM.TB_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #D_TB_PAM_TEMP;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #L_DISEASE_SITE_GROUP';

        IF OBJECT_ID('#L_DISEASE_SITE_GROUP', 'U') IS NOT NULL
        drop table #L_DISEASE_SITE_GROUP;

        SELECT D_TB_PAM.TB_PAM_UID,   NRT_GROUP_KEY.TB_PAM_UID AS D_DISEASE_SITE_UID , NRT_GROUP_KEY.D_DISEASE_SITE_GROUP_KEY
            INTO #L_DISEASE_SITE_GROUP
            FROM   #D_TB_PAM_TEMP D_TB_PAM  with (nolock)
            LEFT OUTER JOIN DBO.NRT_DISEASE_SITE_GROUP_KEY NRT_GROUP_KEY  with (nolock)
                ON NRT_GROUP_KEY.TB_PAM_UID=D_TB_PAM.TB_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #L_DISEASE_SITE_GROUP;

         SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;               

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #L_DISEASE_SITE';

        IF OBJECT_ID('#L_DISEASE_SITE', 'U') IS NOT NULL
        drop table #L_DISEASE_SITE;

        SELECT LDSG.TB_PAM_UID,  
                NRT_DISEASE_SITE_KEY.NBS_CASE_ANSWER_UID, 
                CASE WHEN LDSG.D_DISEASE_SITE_GROUP_KEY IS NULL THEN 1 ELSE LDSG.D_DISEASE_SITE_GROUP_KEY END AS D_DISEASE_SITE_GROUP_KEY,
                CASE WHEN NRT_DISEASE_SITE_KEY.D_DISEASE_SITE_KEY IS NULL THEN 1 ELSE  NRT_DISEASE_SITE_KEY.D_DISEASE_SITE_KEY END AS D_DISEASE_SITE_KEY
        INTO #L_DISEASE_SITE
        FROM   #L_DISEASE_SITE_GROUP LDSG  with (nolock)
        LEFT OUTER JOIN DBO.NRT_DISEASE_SITE_KEY NRT_DISEASE_SITE_KEY  with (nolock)
            ON NRT_DISEASE_SITE_KEY.TB_PAM_UID=LDSG.TB_PAM_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #L_DISEASE_SITE;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;           

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #TEMP_D_DISEASE_SITE';

        IF OBJECT_ID('#TEMP_D_DISEASE_SITE', 'U') IS NOT NULL
        drop table #TEMP_D_DISEASE_SITE;

        SELECT LDS.TB_PAM_UID,
        LDS.D_DISEASE_SITE_KEY,
        SDS.SEQ_NBR,
        LDS.D_DISEASE_SITE_GROUP_KEY,
        SDS.LAST_CHG_TIME,
        SDS.VALUE
        INTO #TEMP_D_DISEASE_SITE
        FROM   #L_DISEASE_SITE LDS  with (nolock)
        LEFT OUTER JOIN #S_DISEASE_SITE SDS  with (nolock)
            ON 	SDS.TB_PAM_UID=LDS.TB_PAM_UID
            AND SDS.NBS_CASE_ANSWER_UID= LDS.NBS_CASE_ANSWER_UID;

        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEMP_D_DISEASE_SITE;

          SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;    

-------------------------------------------------------------------------------------------
        
        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Insert records to  d_disease_site_group';

        INSERT INTO DBO.D_DISEASE_SITE_GROUP
            ([D_DISEASE_SITE_GROUP_KEY])
            SELECT 
               DISTINCT
                T.D_DISEASE_SITE_GROUP_KEY
            FROM #TEMP_D_DISEASE_SITE T  with (nolock)
            LEFT JOIN DBO.D_DISEASE_SITE_GROUP DSG with (nolock)
            ON 	DSG.D_DISEASE_SITE_GROUP_KEY= T.D_DISEASE_SITE_GROUP_KEY
            WHERE DSG.D_DISEASE_SITE_GROUP_KEY IS NULL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;          
    
-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Update d_disease_site';

        UPDATE DBO.D_DISEASE_SITE
        SET 
        TB_PAM_UID = T.TB_PAM_UID,
        SEQ_NBR = T.SEQ_NBR,
        LAST_CHG_TIME = T.SEQ_NBR,
        VALUE = T.SEQ_NBR
        FROM #TEMP_D_DISEASE_SITE T  with (nolock)
        INNER JOIN DBO.D_DISEASE_SITE D_DISEASE_SITE with (nolock)
            ON 	D_DISEASE_SITE.TB_PAM_UID= T.TB_PAM_UID
        WHERE D_DISEASE_SITE.D_DISEASE_SITE_KEY IS NOT NULL;

         SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;       

-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'Insert records to  d_disease_site';

        INSERT INTO DBO.D_DISEASE_SITE
            ([TB_PAM_UID]
            ,[D_DISEASE_SITE_KEY]
            ,[SEQ_NBR]
            ,[D_DISEASE_SITE_GROUP_KEY]
            ,[LAST_CHG_TIME]
            ,[VALUE])
            SELECT 
                T.TB_PAM_UID,
                T.D_DISEASE_SITE_KEY,
                T.SEQ_NBR,
                T.D_DISEASE_SITE_GROUP_KEY,
                T.LAST_CHG_TIME,
                T.VALUE
            FROM #TEMP_D_DISEASE_SITE T  with (nolock)
            LEFT JOIN DBO.D_DISEASE_SITE D_DISEASE_SITE with (nolock)
            ON 	D_DISEASE_SITE.TB_PAM_UID= T.TB_PAM_UID
            WHERE D_DISEASE_SITE.TB_PAM_UID IS NULL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);
        
        COMMIT TRANSACTION;          
-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET @Proc_Step_no = 999;

        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @dataflow_name, @package_name, 'COMPLETE', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);

        COMMIT TRANSACTION;
    
-------------------------------------------------------------------------------------------
    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


        INSERT INTO dbo.[job_flow_log] (
			batch_id
			,[Dataflow_Name]
			,[package_Name]
			,[Status_Type]
			,[step_number]
			,[step_name]
			,[Error_Description]
			,[row_count]
        )
        VALUES (
            @batch_id
            ,@dataflow_name
            ,@package_name
            ,'ERROR'
            ,@Proc_Step_no
            ,'ERROR - '+ @Proc_Step_name
            , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
            ,0
		);

        return -1 ;

    END CATCH

END;

---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------










