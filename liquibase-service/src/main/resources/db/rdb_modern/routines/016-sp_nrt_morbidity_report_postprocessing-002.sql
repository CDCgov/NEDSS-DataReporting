CREATE OR ALTER PROCEDURE [dbo].[sp_d_morbidity_report_postprocessing]
(@pMorbidityIdList nvarchar(max)
, @pDebug bit = 'false')

AS

BEGIN
    /*
     * [Description]
     * This stored procedure is handles event based updates to Morbidity Report based dimensions.
     * 1. Receives input list of Morbidity Report based Observations with Order.
     * 2. Pulls changed records from nrt_observation using the input list into temporary tables for processing.
     * 3. Inserts and updates new records into target dimensions.
     *
     * [Target Dimensions]
     * 1. MORBIDITY_REPORT
     * 2. MORBIDITY_REPORT_EVENT
     * 3. MORB_RPT_USER_COMMENT
     */

    DECLARE @batch_id BIGINT;
    SET @batch_id = CAST((FORMAT(GETDATE(), 'yyMMddHHmmss')) AS BIGINT);
    DECLARE @RowCount_no INT ;
    DECLARE @Proc_Step_no FLOAT = 0 ;
    DECLARE @Proc_Step_Name VARCHAR(200) = '' ;


    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        BEGIN TRANSACTION;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating #nrt_morbidity_observation';


        --List of new observation_uids for Morbidity Report from nrt_observation.
        SELECT
            *
        INTO #nrt_morbidity_observation
        FROM
            nrt_observation WITH (NOLOCK)
        WHERE
            observation_uid IN (SELECT value FROM STRING_SPLIT(@pMorbidityIdList, ','));


        --Get map act_relationship associations for observation_uids.
        SELECT
            observation_uid
        INTO #updated_morb_observation_list
        FROM
            (
                SELECT DISTINCT observation_uid
                FROM #nrt_morbidity_observation
                UNION
                SELECT try_cast(followupObs.value  AS bigint) AS observation_uid
                FROM #nrt_morbidity_observation
                         --act_relationship.source_act_uids associated to each uid where obs_domain_cd_st_1 <> 'Result'
                         CROSS APPLY string_split(rtrim(ltrim(followup_observation_uid)),',') AS followupObs
                UNION
                SELECT try_cast(resultObs.value AS bigint) AS observation_uid
                FROM #nrt_morbidity_observation
                         --act_relationship.source_act_uids associated to each uid where obs_domain_cd_st_1 = 'Result'
                         CROSS APPLY string_split(result_observation_uid,',') AS resultObs
            ) AS getFollowup;


        --Get subset of observations required for post-processing.
        SELECT
            *
        INTO #morb_obs_reference
        FROM
            dbo.nrt_observation with (nolock)
        WHERE
            observation_uid IN
            (SELECT observation_uid
             FROM #updated_morb_observation_list);

        if @pDebug = 'true' SELECT 'DEBUG: updated_morb_observation_list', * FROM #updated_morb_observation_list;
        if @pDebug = 'true' SELECT 'DEBUG: morb_obs_reference', * FROM #morb_obs_reference;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating  tmp_morb_root';


        IF OBJECT_ID('#tmp_morb_root', 'U') IS NOT NULL
            DROP TABLE #tmp_morb_root ;


        CREATE TABLE #tmp_morb_root(
                                       [morb_rpt_local_id] [varchar](50) NULL,
                                       [morb_rpt_share_ind] [char](1) NOT NULL,
                                       [morb_rpt_oid] [bigint] NULL,
                                       [morb_RPT_Created_DT] [datetime] NULL,
                                       [morb_RPT_Create_BY] [bigint] NULL,
                                       [PH_RECEIVE_DT] [datetime] NULL,
                                       [morb_RPT_LAST_UPDATE_DT] [datetime] NULL,
                                       [morb_RPT_LAST_UPDATE_BY] [bigint] NULL,
                                       [Jurisdiction_cd] [varchar](20) NULL,
                                       [Jurisdiction_nm] [varchar](50)  NULL,
                                       [morb_report_date] [datetime] NULL,
                                       [Condition_cd] [varchar](50) NULL,
                                       [morb_rpt_uid] [bigint] NOT NULL,
                                       [ELECTRONIC_IND] [char](1) NULL,
                                       [record_status_cd] [varchar](20) NULL,
                                       [PROCESSING_DECISION_CD] [varchar](20) NULL,
                                       [PROCESSING_DECISION_DESC] [varchar](25) NULL,
                                       [PROVIDER_KEY] [numeric](18, 0) NULL,
                                       morb_rpt_KEY int

        ) ON [PRIMARY];

        INSERT INTO #tmp_morb_root(
                                    [morb_rpt_local_id]
                                  ,[morb_rpt_share_ind]
                                  ,[morb_rpt_oid]
                                  ,[morb_RPT_Created_DT]
                                  ,[morb_RPT_Create_BY]
                                  ,[PH_RECEIVE_DT]
                                  ,[morb_RPT_LAST_UPDATE_DT]
                                  ,[morb_RPT_LAST_UPDATE_BY]
                                  ,[Jurisdiction_cd]
                                  ,[Jurisdiction_nm]
                                  ,[morb_report_date]
                                  ,[Condition_cd]
                                  ,[morb_rpt_uid]
                                  ,[ELECTRONIC_IND]
                                  ,[record_status_cd]
                                  ,[PROCESSING_DECISION_CD]
                                  ,[PROCESSING_DECISION_DESC]
        )
        SELECT 	obs.local_id				 AS morb_rpt_local_id,
                  obs.shared_ind				 AS morb_rpt_share_ind,
                  obs.PROGRAM_JURISDICTION_OID  AS morb_rpt_oid,
                  obs.ADD_TIME				 AS morb_RPT_Created_DT,
                  obs.ADD_USER_ID  		 	 AS morb_RPT_Create_BY,
                  obs.rpt_to_state_time  		 AS PH_RECEIVE_DT,
                  obs.LAST_CHG_TIME 			 AS morb_RPT_LAST_UPDATE_DT,
                  obs.LAST_CHG_USER_ID		 AS morb_RPT_LAST_UPDATE_BY, /**/
                  obs.jurisdiction_cd			 AS Jurisdiction_cd,		/*mrb137*/
                  NULL, --VS put(obs.jurisdiction_cd, $JURCODE.)  AS Jurisdiction_nm,
                  obs.activity_to_time   	 	 AS morb_report_date, 	/*mrb101*/
                  obs.cd						 AS Condition_cd, 		/*MRB121*/
                  obs.observation_uid			 AS morb_rpt_uid,
                  obs.electronic_ind			 AS ELECTRONIC_IND,
                  CASE
                      WHEN obs.[record_status_cd] = 'LOG_DEL' THEN 'INACTIVE'
                      WHEN obs.[record_status_cd] IN ('PROCESSED','UNPROCESSED') OR rtrim(obs.record_status_cd) IS NULL THEN 'ACTIVE'
                      ELSE obs.[record_status_cd]
                      END AS record_status_cd,
                  obs.PROCESSING_DECISION_CD ,
                  substring(cvg.Code_short_desc_txt,1,25)
        FROM #nrt_morbidity_observation AS updated_lab
                 INNER JOIN nrt_observation obs ON updated_lab.observation_uid = obs.observation_uid
                 LEFT OUTER JOIN NBS_SRTE.dbo.Code_value_general cvg ON cvg.code_set_nm = 'STD_NBS_PROCESSING_DECISION_ALL'
            AND cvg.code = obs.PROCESSING_DECISION_CD
        WHERE obs.obs_domain_cd_st_1 = 'Order'
          AND obs.CTRL_CD_DISPLAY_FORM  = 'MorbReport';


        UPDATE #tmp_morb_root
        SET jurisdiction_nm = (
            SELECT code_short_desc_txt
            FROM NBS_SRTE.dbo.jurisdiction_code WHERE code= #tmp_morb_root.Jurisdiction_cd and code_set_nm = 'S_JURDIC_C'
        )
        WHERE Jurisdiction_cd IS NOT NULL;


        if @pDebug = 'true' SELECT 'DEBUG: tmp_morb_root', * FROM #tmp_morb_root;


        /*Key Generation*/
        UPDATE tmp_val
        SET tmp_val.morb_rpt_key = mr.morb_rpt_key
        FROM #tmp_morb_root tmp_val
                 INNER JOIN Morbidity_Report mr ON mr.morb_rpt_uid = tmp_val.morb_rpt_uid;


        CREATE TABLE #tmp_id_assignment(
                                           morb_rpt_key_id [int] IDENTITY(1,1) NOT NULL,
                                           morb_rpt_uid [bigint] NOT NULL
        )
        INSERT INTO #tmp_id_assignment
        SELECT tmp_morb.morb_rpt_uid
        FROM #tmp_morb_root tmp_morb
                 LEFT JOIN Morbidity_Report mr ON mr.morb_rpt_uid = tmp_morb.morb_rpt_uid
        WHERE mr.morb_rpt_uid IS NULL;


        UPDATE tmp_morb
        SET tmp_morb.morb_rpt_key =
                morb_rpt_key_id + COALESCE((SELECT MAX(morb_rpt_key) FROM Morbidity_Report),1)
        FROM #tmp_morb_root tmp_morb
                 LEFT JOIN #tmp_id_assignment id ON tmp_morb.morb_rpt_uid = id.morb_rpt_uid
        WHERE tmp_morb.morb_rpt_key IS NULL;

        /*
        UPDATE #tmp_morb_root
        SET morb_rpt_KEY= morb_rpt_KEY_id + coalesce((SELECT MAX(morb_rpt_KEY) FROM dbo.Morbidity_Report),1);
        */

        if @pDebug = 'true' SELECT 'DEBUG: tmp_morb_root_keyvalue', * FROM #tmp_morb_root;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating #tmp_MorbFrmQ';

        IF OBJECT_ID('#tmp_MorbFrmQ', 'U') IS NOT NULL
            DROP TABLE #tmp_MorbFrmQ ;

        --Get MorbFrmQ associated to observation using cd in nrt_observation.
        SELECT mr.morb_rpt_uid,
               no2.cd,
               no2.observation_uid
        into #tmp_MorbFrmQ
        FROM #tmp_morb_root					AS mr
                 inner join #nrt_morbidity_observation o ON mr.morb_rpt_uid = o.observation_uid
                 cross apply string_split(rtrim(ltrim(followup_observation_uid)),',') AS followup_obs
                 join #morb_obs_reference AS no2 ON followup_obs.value = no2.observation_uid
        WHERE mr.morb_rpt_uid = o.observation_uid
          and no2.cd IN ('INV128', 'INV145', 'INV148', 'INV149', 'INV178', 'MRB100', 'MRB102',
                         'MRB122', 'MRB129', 'MRB130', 'MRB161', 'MRB161', 'MRB165', 'MRB166', 'MRB167', 'MRB168' , 'MRB169');

        if @pDebug = 'true' SELECT 'DEBUG: tmp_MorbFrmQ',* FROM #tmp_MorbFrmQ;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating  #tmp_MorbFrmQCoded';

        IF OBJECT_ID('#tmp_MorbFrmQCoded', 'U') IS NOT NULL
            DROP TABLE #tmp_MorbFrmQCoded ;

        SELECT 	oq.*,
                ob.ovc_code AS [code]
        INTO #tmp_MorbFrmQCoded
        FROM #tmp_MorbFrmQ					AS oq
                 INNER JOIN nrt_observation_coded AS ob
                            ON oq.observation_uid = ob.observation_uid;

        if @pDebug = 'true' SELECT 'DEBUG: tmp_MorbFrmQCoded', * FROM #tmp_MorbFrmQCoded;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating #tmp_MorbFrmQDate';

        IF OBJECT_ID('#tmp_MorbFrmQDate', 'U') IS NOT NULL
            DROP TABLE #tmp_MorbFrmQDate;

        SELECT 	oq.*,
                  ob.ovd_FROM_date AS [FROM_time]
        INTO #tmp_MorbFrmQDate
        FROM	#tmp_MorbFrmQ					AS oq
                    INNER JOIN  nrt_observation_date AS ob ON
            oq.observation_uid = ob.observation_uid;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating #tmp_MorbFrmQTxt';

        IF OBJECT_ID('#tmp_MorbFrmQTxt', 'U') IS NOT NULL
            DROP TABLE #tmp_MorbFrmQTxt ;

        SELECT 	oq.*,
                  REPLACE(REPLACE(ob.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')	as VALUE_TXT
        INTO #tmp_MorbFrmQTxt
        FROM #tmp_MorbFrmQ					AS oq
                 INNER JOIN  nrt_observation_txt AS ob ON oq.observation_uid = ob.observation_uid;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQCoded2';

        DECLARE @tmp_MorbFrmQCoded2 varchar(100) = '';
        SET @tmp_MorbFrmQCoded2 = '##tmp_MorbFrmQCoded2'+'_'+CAST(@batch_id AS varchar(50));


        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MorbFrmQCoded2+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@tmp_MorbFrmQCoded2+';
		END;')


        DECLARE @columns NVARCHAR(MAX);
        DECLARE @sql NVARCHAR(MAX);

        SET @columns = N'';

        SELECT @columns+=N', p.'+QUOTENAME(LTRIM(RTRIM([CD])))
        FROM
            (
                SELECT [CD]
                FROM #tmp_MorbFrmQCoded AS p
                GROUP BY [CD]
            ) AS x;
        SET @sql = N'
						SELECT [morb_rpt_uid] AS morb_rpt_uid_coded, '+STUFF(@columns, 1, 2, '')+
                   ' INTO ' + @tmp_MorbFrmQCoded2 +
                   ' FROM (
                   SELECT [morb_rpt_uid], [code] , [CD]
                    FROM #tmp_MorbFrmQCoded
                       group by [morb_rpt_uid], [code] , [CD]
                           ) AS j PIVOT (max(code) FOR [CD] in
                          ('+STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')+')) AS p;';


        if @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;

        SELECT @RowCount_no = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQDate2';


        DECLARE @tmp_MorbFrmQDate2 varchar(100) = '';
        SET @tmp_MorbFrmQDate2 = '##tmp_MorbFrmQDate2'+'_'+CAST(@batch_id AS varchar(50));


        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MorbFrmQDate2+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@tmp_MorbFrmQDate2+';
		END;')


        SET @columns = N'';

        SELECT @columns+=N', p.'+QUOTENAME(LTRIM(RTRIM([CD])))
        FROM
            (
                SELECT [CD]
                FROM #tmp_MorbFrmQDate AS p
                GROUP BY [CD]
            ) AS x;

        SET @sql = N'
						SELECT [morb_rpt_uid] AS morb_rpt_uid_date, '+STUFF(@columns, 1, 2, '')+
                   ' INTO ' + @tmp_MorbFrmQDate2 +
                   ' FROM (
                   SELECT [morb_rpt_uid], [FROM_time] , [CD]
                    FROM #tmp_MorbFrmQDate
                       group by [morb_rpt_uid], [FROM_time] , [CD]
                           ) AS j PIVOT (max(FROM_time) FOR [CD] in
                          ('+STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')+')) AS p;';

        if @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQTxt2';

        DECLARE @tmp_MorbFrmQTxt2 varchar(100) = '';
        SET @tmp_MorbFrmQTxt2 = '##tmp_MorbFrmQTxt2'+'_'+CAST(@batch_id as varchar(50));


        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MorbFrmQTxt2+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@tmp_MorbFrmQTxt2+';
		END;')

        SET @columns = N'';

        SELECT @columns+=N', p.'+QUOTENAME(LTRIM(RTRIM([CD])))
        FROM
            (
                SELECT [CD]
                FROM #tmp_MorbFrmQTxt AS p
                GROUP BY [CD]
            ) AS x;
        SET @sql = N'
						SELECT [morb_rpt_uid] AS morb_rpt_uid_txt, '+STUFF(@columns, 1, 2, '')+
                   ' INTO ' + @tmp_MorbFrmQTxt2 +
                   ' FROM (
               SELECT [morb_rpt_uid], [value_txt] , [CD]
                    FROM #tmp_MorbFrmQTxt
                       group by [morb_rpt_uid], [value_txt] , [CD]
        ) AS j PIVOT (max(value_txt) FOR [CD] in
                          ('+STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')+')) AS p;';

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQCoded2';

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MorbFrmQCoded2+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@tmp_MorbFrmQCoded2+ N'
				(morb_rpt_uid_coded [bigint] NOT NULL
        ) ON [PRIMARY];
		END;')


        /*
         IF OBJECT_ID('tempdb..##tmp_MorbFrmQCoded2', 'U') IS  NULL
         create table ##tmp_MorbFrmQCoded2 (morb_rpt_uid_coded [bigint] NOT NULL
         ) ON [PRIMARY];*/


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQDate2';

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MorbFrmQDate2+''', ''U'') IS NULL
			BEGIN
				CREATE TABLE '+@tmp_MorbFrmQDate2+ N'
					(morb_rpt_uid_date [bigint] NOT NULL
	        ) ON [PRIMARY];
			END;')

        /*
        IF OBJECT_ID('tempdb..##tmp_MorbFrmQDate2', 'U') IS  NULL
        create table ##tmp_MorbFrmQDate2 (morb_rpt_uid_date [bigint] NOT NULL
        ) ON [PRIMARY];
        */

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQTxt2';

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MorbFrmQTxt2+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@tmp_MorbFrmQTxt2+ N'
				(morb_rpt_uid_txt [bigint] NOT NULL
        ) ON [PRIMARY];
		END;')

        /*
        IF OBJECT_ID('tempdb..##tmp_MorbFrmQTxt2', 'U') IS  NULL
        create table ##tmp_MorbFrmQTxt2 (	morb_rpt_uid_txt [bigint] NOT NULL
        ) ON [PRIMARY];
        */

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_Morbidity_Report';

        DECLARE @tmp_Morbidity_Report varchar(100) = '';
        SET @tmp_Morbidity_Report = '##tmp_Morbidity_Report'+'_'+CAST(@batch_id as varchar(50));

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_Morbidity_Report+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@tmp_Morbidity_Report+';
		END;')

        SET @sql = N'
        SELECT mr.[morb_rpt_local_id],
			   mr.[morb_rpt_key],
               mr.[morb_rpt_share_ind],
               mr.[morb_rpt_oid],
               mr.[morb_RPT_Created_DT],
               mr.[morb_RPT_Create_BY],
               mr.[PH_RECEIVE_DT],
               mr.[morb_RPT_LAST_UPDATE_DT],
               mr.[morb_RPT_LAST_UPDATE_BY],
               mr.[Jurisdiction_cd],
               mr.[Jurisdiction_nm],
               mr.[morb_report_date],
               mr.[Condition_cd],
               mr.[morb_rpt_uid],
               mr.[ELECTRONIC_IND],
			   CASE
					WHEN rtrim(mr.[PROCESSING_DECISION_CD])  = '''' THEN NULL
					ELSE mr.[PROCESSING_DECISION_CD]
				  END AS PROCESSING_DECISION_CD,
               mr.[PROCESSING_DECISION_DESC],
			   mr.[record_status_cd], --Updated in #tmp_morb_root
			   tmc2.*, tmd2.*,tmt2.*,
               Cast( NULL AS datetime) AS TEMP_ILLNESS_ONSET_DT_KEY,
               Cast( NULL AS datetime) AS TEMP_DIAGNOSIS_DT_KEY,
               Cast( NULL AS datetime) AS DIAGNOSIS_DT,
               Cast( NULL AS datetime) AS HSPTL_ADMISSION_DT,
               Cast( NULL AS datetime) AS TEMP_HSPTL_DISCHARGE_DT_KEY,
               Cast( NULL AS VARCHAR(50)) AS HOSPITALIZED_IND,
               Cast( NULL AS VARCHAR(50)) AS DIE_FROM_ILLNESS_IND,
               Cast( NULL AS VARCHAR(50)) AS DAYCARE_IND,
               Cast( NULL AS VARCHAR(50)) AS FOOD_HANDLER_IND,
               Cast( NULL AS VARCHAR(50)) AS PREGNANT_IND,
               Cast( NULL AS VARCHAR(50)) AS HEALTHCARE_ORG_ASSOCIATE_IND,
               Cast( NULL AS VARCHAR(50)) AS SUSPECT_FOOD_WTRBORNE_ILLNESS,
               Cast( NULL AS VARCHAR(20)) AS MORB_RPT_TYPE,
               Cast( NULL AS VARCHAR(20)) AS MORB_RPT_DELIVERY_METHOD,
               Cast( NULL AS VARCHAR(2000)) AS MORB_RPT_COMMENTS,
    		   Cast( NULL AS VARCHAR(2000)) AS MORB_RPT_OTHER_SPECIFY,
               Cast( NULL AS VARCHAR(1)) AS NURSING_HOME_ASSOCIATE_IND,
               GETDATE()  AS RDB_LAST_REFRESH_TIME
        INTO '+@tmp_Morbidity_Report+'
        FROM #tmp_morb_root mr
                 FULL OUTER JOIN '+@tmp_MorbFrmQCoded2+' tmc2 ON mr.morb_rpt_uid = tmc2.morb_rpt_uid_coded
                 FULL OUTER JOIN '+@tmp_MorbFrmQDate2+' tmd2  ON mr.morb_rpt_uid = tmd2.morb_rpt_uid_date
                 FULL OUTER JOIN '+@tmp_MorbFrmQTxt2+' tmt2  ON mr.morb_rpt_uid = tmt2.morb_rpt_uid_txt;';

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;


        DECLARE @morb_columns NVARCHAR(MAX) = '';

        --Handle dynamic column assignment
        SELECT @morb_columns = @morb_columns +
                               CASE
                                   WHEN name = 'INV128' THEN N'HOSPITALIZED_IND = INV128, '
                                   WHEN name = 'INV145' THEN N'DIE_FROM_ILLNESS_IND = INV145, '
                                   WHEN name = 'INV148' THEN N'DAYCARE_IND = INV148, '
                                   WHEN name = 'INV149' THEN N'FOOD_HANDLER_IND = INV149, '
                                   WHEN name = 'INV178' THEN N'PREGNANT_IND = INV178, '
                                   WHEN name = 'MRB100' THEN N'MORB_RPT_TYPE = MRB100, '
                                   WHEN name = 'MRB102' THEN N'MORB_RPT_COMMENTS = rtrim(MRB102), '
                                   WHEN name = 'MRB122' THEN N'TEMP_ILLNESS_ONSET_DT_KEY = MRB122, '
                                   WHEN name = 'MRB129' THEN N'NURSING_HOME_ASSOCIATE_IND = substring(MRB129,1,1), '
                                   WHEN name = 'MRB130' THEN N'HEALTHCARE_ORG_ASSOCIATE_IND = MRB130, '
                                   WHEN name = 'MRB161' THEN N'MORB_RPT_DELIVERY_METHOD = MRB161, '
                                   WHEN name = 'MRB165' THEN N'TEMP_DIAGNOSIS_DT_KEY = MRB165, DIAGNOSIS_DT = MRB165, '
                                   WHEN name = 'MRB166' THEN N'HSPTL_ADMISSION_DT = MRB166, '
                                   WHEN name = 'MRB168' THEN N'SUSPECT_FOOD_WTRBORNE_ILLNESS = MRB168, '
                                   WHEN name = 'MRB167' THEN N'TEMP_HSPTL_DISCHARGE_DT_KEY = MRB167, '
                                   WHEN name = 'MRB169' THEN N'MORB_RPT_OTHER_SPECIFY = MRB169, '
                                   ELSE N''
                                   END
        FROM tempdb.sys.columns
        WHERE object_id = object_id('tempdb..' + @tmp_Morbidity_Report)
          AND name IN ('INV128','INV145','INV148','INV149','INV178','MRB100','MRB102',
                       'MRB122','MRB129','MRB130','MRB161','MRB165','MRB166','MRB168',
                       'MRB167', 'MRB169');


        --Trailing comma removal.
        IF LEN(@morb_columns) > 0
            BEGIN
                SET @morb_columns = LEFT(@morb_columns, LEN(@morb_columns) - 1);
            END;

        --Handling 0 columns.
        IF LEN(@morb_columns) > 0
            BEGIN
                SET @sql = N'
                    UPDATE '+@tmp_Morbidity_Report+' SET ' + @morb_columns +' ;'
                EXEC sp_executesql @sql;
            END


        IF @pDebug = 'true' print @sql;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##SAS_morb_Rpt_User_Comment';

        DECLARE @SAS_morb_Rpt_User_Comment varchar(100) = '';
        SET @SAS_morb_Rpt_User_Comment = '##SAS_morb_Rpt_User_Comment'+'_'+CAST(@batch_id as varchar(50));

        EXEC ('IF OBJECT_ID(''tempdb..'+@SAS_morb_Rpt_User_Comment+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@SAS_morb_Rpt_User_Comment+';
		END;')


        SET @sql = N'
        SELECT 	root.morb_Rpt_Key,
                root.morb_rpt_uid,
                obs.activity_to_time	 AS user_comments_dt,
                obs.add_user_id		 AS user_comments_by,
				REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13) + CHAR(10),'' ''), CHAR(10), '' '') AS external_morb_rpt_comments,
                  root.record_status_cd
        INTO '+@SAS_morb_Rpt_User_Comment+'
        FROM '+@tmp_Morbidity_Report+'	as root
            INNER JOIN #morb_obs_reference AS obs ON root.morb_rpt_uid = obs.observation_uid
            INNER JOIN #updated_morb_observation_list AS ls ON ls.observation_uid = obs.observation_uid
            INNER JOIN dbo.nrt_observation_txt AS ovt ON ovt.observation_uid = obs.observation_uid
        WHERE
          ovt.ovt_value_txt IS NOT NULL
          AND obs.obs_domain_cd_st_1 IN (''C_Order'', ''C_Result'');';

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_morb_Rpt_User_Comment';

        DECLARE @tmp_morb_Rpt_User_Comment varchar(100) = '';
        SET @tmp_morb_Rpt_User_Comment = '##tmp_morb_Rpt_User_Comment'+'_'+CAST(@batch_id as varchar(50));

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_morb_Rpt_User_Comment+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@tmp_morb_Rpt_User_Comment+';
		END;')


        SET @sql = N'
        CREATE TABLE '+@tmp_morb_Rpt_User_Comment+'(
                                [morb_Rpt_Key] [int] NULL,
                                                   [morb_rpt_uid] [bigint] NULL,
                                                   [user_comments_dt] [datetime] NULL,
                                                   [user_comments_by] [bigint] NULL,
                                                   [external_morb_rpt_comments] [varchar](8000) NULL,
                                                   [record_status_cd] [varchar](20) NULL,
                           						   [User_Comment_key] int
        ) ON [PRIMARY];

        INSERT INTO '+@tmp_morb_Rpt_User_Comment+'
        ( [morb_Rpt_Key]
        ,[morb_rpt_uid]
        ,[user_comments_dt]
        ,[user_comments_by]
        ,[external_morb_rpt_comments]
        ,[record_status_cd]
        )
        SELECT distinct [morb_Rpt_Key]
                      ,[morb_rpt_uid]
                      ,[user_comments_dt]
                      ,[user_comments_by]
                      ,[external_morb_rpt_comments]
                      ,[record_status_cd]
        FROM '+@SAS_morb_Rpt_User_Comment+';';

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;


        /*Key Generation: MORB_RPT_USER_COMMENT */
        SET @sql = N'
      	UPDATE tmp_val
        SET tmp_val.user_comment_key = mruc.user_comment_key
	    FROM '+@tmp_morb_Rpt_User_Comment+' tmp_val
	    INNER JOIN MORB_RPT_USER_COMMENT mruc ON mruc.morb_rpt_uid = tmp_val.morb_rpt_uid;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;

        DECLARE @tmp_id_assignment varchar(100) = '';
        SET @tmp_id_assignment = '##tmp_id_assignment'+'_'+CAST(@batch_id as varchar(50));

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_id_assignment+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@tmp_id_assignment+';
		END;')


        SET @sql = N'
       CREATE TABLE '+@tmp_id_assignment+'(
               user_comment_key_id [int] IDENTITY(1,1) NOT NULL,
               [morb_rpt_uid] [bigint] NOT NULL
               )
	     INSERT INTO '+@tmp_id_assignment+'
	        SELECT rslt.morb_rpt_uid
	        FROM '+@tmp_morb_Rpt_User_Comment+' rslt
	        LEFT JOIN MORB_RPT_USER_COMMENT mru ON mru.morb_rpt_uid = rslt.morb_rpt_uid
	        WHERE mru.morb_rpt_uid IS NULL;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;

        SET @sql = N'
	    UPDATE tmp_val
        SET tmp_val.user_comment_key =
        user_comment_key_id + COALESCE((SELECT MAX(user_comment_key) FROM MORB_RPT_USER_COMMENT),1)
	    FROM '+@tmp_morb_Rpt_User_Comment+' tmp_val
	    LEFT JOIN '+@tmp_id_assignment+' id ON tmp_val.morb_rpt_uid = id.morb_rpt_uid
	    WHERE tmp_val.user_comment_key IS NULL;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;


        /*
        UPDATE #tmp_morb_Rpt_User_Comment
        SET User_Comment_key = User_Comment_Key_id + coalesce((SELECT MAX(User_Comment_key) FROM dbo.morb_rpt_user_comment),0);
        */


        /*-------------------------------------------------------

            MORBIDITY_REPORT_Event( Keys table)

        ---------------------------------------------------------*/

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES
            (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MORBIDITY_REPORT_Event_Final';

        DECLARE @tmp_MORBIDITY_REPORT_Event_Final varchar(100) = '';
        SET @tmp_MORBIDITY_REPORT_Event_Final = '##tmp_MORBIDITY_REPORT_Event_Final'+'_'+CAST(@batch_id as varchar(50));

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MORBIDITY_REPORT_Event_Final+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@tmp_MORBIDITY_REPORT_Event_Final+';
		END;')


        SET @sql = N'
        SELECT 	pat.PATIENT_KEY				PATIENT_KEY ,
                  con.CONDITION_KEY,
                  --con.condition_cd,
                  coalesce(org1.Organization_key,1)				as HEALTH_CARE_KEY,
                  coalesce(dt3.Date_key,1)	as HSPTL_DISCHARGE_DT_KEY,
                  org2.Organization_key				as HSPTL_KEY,
                  coalesce(dt4.Date_key,1)	as ILLNESS_ONSET_DT_KEY,
                  inv.INVESTIGATION_KEY,
                  rpt.morb_Rpt_Key,

                  coalesce(dt5.Date_key,1)	as MORB_RPT_CREATE_DT_KEY,
                  coalesce(dt6.Date_key,1)	as MORB_RPT_DT_KEY,

                  org3.Organization_Key				as MORB_RPT_SRC_ORG_KEY,
                  coalesce(phy.provider_key,1)		as PHYSICIAN_KEY,
                  per1.provider_key				as REPORTER_KEY,
                  --'' AS LDF_GROUP_KEY, --VS
                  coalesce(ldf_g.ldf_group_key,1) AS LDF_GROUP_KEY,
                  1							as Morb_Rpt_Count,
                  1							as Nursing_Home_Key, /*cannot find mapping*/
                  rpt.record_status_cd
        INTO '+@tmp_MORBIDITY_REPORT_Event_Final+'
        FROM '+@tmp_Morbidity_Report+' rpt
                 inner join #morb_obs_reference n ON rpt.morb_rpt_uid = n.observation_uid
                 left join d_patient AS pat ON n.patient_id = pat.patient_uid
                 left join condition AS con ON  rpt.condition_cd = con.condition_cd	AND rtrim(con.condition_cd) != ''''
     left join d_Organization AS org1 ON org1.Organization_uid = n.health_care_id
            /*HSPTL_DISCHARGE_DT_KEY*/
                 left join rdb_date	as dt3	on rpt.temp_hsptl_discharge_dt_key = dt3.date_mm_dd_yyyy
            /*	HSPTL_KEY*/
                 left join d_Organization AS org2 ON n.morb_hosp_id = org2.Organization_uid
            /*ILLNESS_ONSET_DT_KEY*/
                 left join rdb_date	as dt4 ON rpt.temp_illness_onset_dt_key = dt4.date_mm_dd_yyyy
            /* INVESTIGATION_KEY  */
                 left join dbo.nrt_investigation_observation AS ninv ON rpt.morb_rpt_uid = ninv.observation_id
                 left join Investigation inv ON ninv.public_health_case_uid = inv.case_uid
            /*MORB_RPT_CREATE_DT_KEY*/
                 left join rdb_date AS dt5 ON CAST(CONVERT(VARCHAR,rpt.morb_RPT_Created_DT,102) AS DATETIME)  = dt5.DATE_MM_DD_YYYY
            /*MORB_RPT_DT_KEY*/
                 left join rdb_date	as dt6 ON rpt.morb_report_date = dt6.DATE_MM_DD_YYYY
            /*MORB_RPT_SRC_ORG_KEY */
                 left join d_Organization AS org3 ON n.morb_hosp_reporter_id = org3.Organization_uid
            /*PHYSICIAN_KEY*/
                 left join d_provider AS phy ON n.morb_physician_id = phy.provider_uid
            /*	REPORTER_KEY           */
            --morb_reporter_id
                 left join d_provider AS per1 ON n.morb_reporter_id = per1.provider_uid
            /*Ldf group key*/
                 left join ldf_group AS ldf_g ON rpt.morb_rpt_uid = ldf_g.business_object_uid;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES 		(@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Update Morbidity_Report';

        SET @sql= N'
        UPDATE MORBIDITY_REPORT
        SET
            [MORB_RPT_KEY]	 = 	tmp.[MORB_RPT_KEY], --Not Null
			[MORB_RPT_LOCAL_ID]	 = 	substring(tmp.MORB_RPT_LOCAL_ID ,1,50),
			[MORB_RPT_SHARE_IND]	 = 	tmp.MORB_RPT_SHARE_IND,
			[MORB_RPT_OID]	 = 	tmp.MORB_RPT_OID,
			[MORB_RPT_TYPE]	 = 	substring(tmp.MORB_RPT_TYPE ,1,50),
			[MORB_RPT_COMMENTS]	 = 	substring(tmp.MORB_RPT_COMMENTS ,1,2000),
			[MORB_RPT_DELIVERY_METHOD]	 = 	substring(tmp.MORB_RPT_DELIVERY_METHOD ,1,50),
			[SUSPECT_FOOD_WTRBORNE_ILLNESS]	 = 	substring(tmp.SUSPECT_FOOD_WTRBORNE_ILLNESS ,1,50),
			[MORB_RPT_OTHER_SPECIFY]	 = 	substring(tmp.MORB_RPT_OTHER_SPECIFY ,1,2000),
			[NURSING_HOME_ASSOCIATE_IND]	 = 	substring(tmp.NURSING_HOME_ASSOCIATE_IND ,1,50),
			[JURISDICTION_CD]	 = 	substring(tmp.JURISDICTION_CD ,1,20),
			[JURISDICTION_NM]	 = 	substring(tmp.JURISDICTION_NM ,1,100),
			[HEALTHCARE_ORG_ASSOCIATE_IND]	 = 	substring(tmp.HEALTHCARE_ORG_ASSOCIATE_IND ,1,50),
			[MORB_RPT_CREATE_BY]	 = 	tmp.MORB_RPT_CREATE_BY,
			[MORB_RPT_LAST_UPDATE_DT]	 = 	tmp.MORB_RPT_LAST_UPDATE_DT,
			[MORB_RPT_LAST_UPDATE_BY]	 = 	tmp.MORB_RPT_LAST_UPDATE_BY,
			[DIAGNOSIS_DT]	 = 	tmp.DIAGNOSIS_DT,
			[HSPTL_ADMISSION_DT]	 = 	tmp.HSPTL_ADMISSION_DT,
			[PH_RECEIVE_DT]	 = 	tmp.PH_RECEIVE_DT,
			[DIE_FROM_ILLNESS_IND]	 = 	substring(tmp.DIE_FROM_ILLNESS_IND ,1,50),
			[HOSPITALIZED_IND]	 = 	substring(tmp.HOSPITALIZED_IND ,1,50),
			[PREGNANT_IND]	 = 	substring(tmp.PREGNANT_IND ,1,50),
			[FOOD_HANDLER_IND]	 = 	substring(tmp.FOOD_HANDLER_IND ,1,50),
			[DAYCARE_IND]	 = 	substring(tmp.DAYCARE_IND ,1,50),
			[ELECTRONIC_IND]	 = 	substring(tmp.ELECTRONIC_IND ,1,50),
			[RECORD_STATUS_CD]	 = 	substring(tmp.RECORD_STATUS_CD ,1,8), --Not Null
			[RDB_LAST_REFRESH_TIME]	 = 	tmp.RDB_LAST_REFRESH_TIME,
			[PROCESSING_DECISION_CD]	 = 	substring(tmp.PROCESSING_DECISION_CD ,1,50),
			[PROCESSING_DECISION_DESC]	 = 	substring(tmp.PROCESSING_DECISION_DESC ,1,50)
        FROM '+@tmp_Morbidity_Report+' tmp
      	 INNER JOIN MORBIDITY_REPORT m ON m.morb_rpt_uid = tmp.morb_rpt_uid;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Inserting into dbo.Morbidity_Report';

        SET @sql= N'
        INSERT INTO MORBIDITY_REPORT
        ([MORB_RPT_KEY]
        ,[MORB_RPT_UID]
        ,[MORB_RPT_LOCAL_ID]
        ,[MORB_RPT_SHARE_IND]
        ,[MORB_RPT_OID]
        ,[MORB_RPT_TYPE]
        ,[MORB_RPT_COMMENTS]
        ,[MORB_RPT_DELIVERY_METHOD]
        ,[SUSPECT_FOOD_WTRBORNE_ILLNESS]
        ,[MORB_RPT_OTHER_SPECIFY]
        ,[NURSING_HOME_ASSOCIATE_IND]
        ,[JURISDICTION_CD]
        ,[JURISDICTION_NM]
        ,[HEALTHCARE_ORG_ASSOCIATE_IND]
        ,[MORB_RPT_CREATE_BY]
        ,[MORB_RPT_LAST_UPDATE_DT]
        ,[MORB_RPT_LAST_UPDATE_BY]
        ,[DIAGNOSIS_DT]
        ,[HSPTL_ADMISSION_DT]
        ,[PH_RECEIVE_DT]
        ,[DIE_FROM_ILLNESS_IND]
        ,[HOSPITALIZED_IND]
        ,[PREGNANT_IND]
        ,[FOOD_HANDLER_IND]
        ,[DAYCARE_IND]
        ,[ELECTRONIC_IND]
        ,[RECORD_STATUS_CD]
        ,[RDB_LAST_REFRESH_TIME]
        ,[PROCESSING_DECISION_CD]
        ,[PROCESSING_DECISION_DESC])
        SELECT tmp.[MORB_RPT_KEY] --Not Null
             ,tmp.MORB_RPT_UID
             ,substring(tmp.MORB_RPT_LOCAL_ID ,1,50)
          ,tmp.MORB_RPT_SHARE_IND
             ,tmp.MORB_RPT_OID
             , substring(tmp.MORB_RPT_TYPE ,1,50)
             , substring(tmp.MORB_RPT_COMMENTS ,1,2000)
             , substring(tmp.MORB_RPT_DELIVERY_METHOD ,1,50)
             , substring(tmp.SUSPECT_FOOD_WTRBORNE_ILLNESS ,1,50)
             , substring(tmp.MORB_RPT_OTHER_SPECIFY ,1,2000)
             , substring(tmp.NURSING_HOME_ASSOCIATE_IND ,1,50)
             , substring(tmp.JURISDICTION_CD ,1,20)
             , substring(tmp.JURISDICTION_NM ,1,100)
             , substring(tmp.HEALTHCARE_ORG_ASSOCIATE_IND ,1,50)
             ,tmp.MORB_RPT_CREATE_BY
             ,tmp.MORB_RPT_LAST_UPDATE_DT
             ,tmp.MORB_RPT_LAST_UPDATE_BY
             ,tmp.DIAGNOSIS_DT
             ,tmp.HSPTL_ADMISSION_DT
             ,tmp.PH_RECEIVE_DT
             , substring(tmp.DIE_FROM_ILLNESS_IND ,1,50)
             , substring(tmp.HOSPITALIZED_IND ,1,50)
             , substring(tmp.PREGNANT_IND ,1,50)
             , substring(tmp.FOOD_HANDLER_IND ,1,50)
             , substring(tmp.DAYCARE_IND ,1,50)
             , substring(tmp.ELECTRONIC_IND ,1,50)
             , substring(tmp.RECORD_STATUS_CD ,1,8) --Not Null
             ,tmp.RDB_LAST_REFRESH_TIME
             , substring(tmp.PROCESSING_DECISION_CD ,1,50)
             , substring(tmp.PROCESSING_DECISION_DESC ,1,50)
        FROM '+@tmp_Morbidity_Report+' tmp
      	 LEFT JOIN MORBIDITY_REPORT m ON m.morb_rpt_uid = tmp.morb_rpt_uid
        WHERE m.morb_rpt_uid is null;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        INSERT INTO dbo.Morbidity_Report (morb_rpt_KEY,[RECORD_STATUS_CD])
        SELECT 1,'ACTIVE'
        WHERE NOT EXISTS (SELECT (morb_rpt_KEY) FROM dbo.Morbidity_Report WHERE morb_rpt_KEY = 1);

        BEGIN TRANSACTION;
        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Updating MORBIDITY_REPORT_EVENT';

        SET @sql= N'
        UPDATE dbo.MORBIDITY_REPORT_EVENT
        SET
	        [PATIENT_KEY] = tmp.[PATIENT_KEY],
			[Condition_Key] = coalesce(tmp.[Condition_Key], ''''),
			[HEALTH_CARE_KEY] = coalesce(tmp.[HEALTH_CARE_KEY], ''''),
			[HSPTL_DISCHARGE_DT_KEY] = coalesce(tmp.[HSPTL_DISCHARGE_DT_KEY], ''''),
			[HSPTL_KEY] = coalesce(tmp.[HSPTL_KEY], 1),
			[ILLNESS_ONSET_DT_KEY] = coalesce(tmp.[ILLNESS_ONSET_DT_KEY], ''''),
			[INVESTIGATION_KEY] = coalesce(tmp.[INVESTIGATION_KEY], 1),
			[MORB_RPT_CREATE_DT_KEY] = coalesce(tmp.[MORB_RPT_CREATE_DT_KEY], ''''),
			[MORB_RPT_DT_KEY] = coalesce(tmp.[MORB_RPT_DT_KEY], ''''),
			[MORB_RPT_SRC_ORG_KEY] = coalesce(tmp.[MORB_RPT_SRC_ORG_KEY], 1),
			[PHYSICIAN_KEY] = coalesce(tmp.[PHYSICIAN_KEY], ''''),
			[REPORTER_KEY] = coalesce(tmp.[REPORTER_KEY],1),
			[LDF_GROUP_KEY] = tmp.[LDF_GROUP_KEY],
			[Morb_Rpt_Count] = tmp.[Morb_Rpt_Count],
			[Nursing_Home_Key] = tmp.[Nursing_Home_Key],
			[record_status_cd] = SUBSTRING(tmp.RECORD_STATUS_CD ,1,8)
		FROM
			'+@tmp_MORBIDITY_REPORT_Event_Final+' tmp
       	INNER JOIN MORBIDITY_REPORT_EVENT mre ON mre.morb_rpt_key = tmp.morb_rpt_key;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Inserting into MORBIDITY_REPORT_EVENT';


        SET @sql= N'
        INSERT INTO dbo.MORBIDITY_REPORT_EVENT
        ( [PATIENT_KEY]
        ,[Condition_Key]
        ,[HEALTH_CARE_KEY]
        ,[HSPTL_DISCHARGE_DT_KEY]
        ,[HSPTL_KEY]
        ,[ILLNESS_ONSET_DT_KEY]
        ,[INVESTIGATION_KEY]
        ,[morb_Rpt_Key]
        ,[MORB_RPT_CREATE_DT_KEY]
        ,[MORB_RPT_DT_KEY]
        ,[MORB_RPT_SRC_ORG_KEY]
        ,[PHYSICIAN_KEY]
        ,[REPORTER_KEY]
        ,[LDF_GROUP_KEY]
        ,[Morb_Rpt_Count]
        ,[Nursing_Home_Key]
        ,[record_status_cd]
        )
        SELECT  tmp.[PATIENT_KEY] --Not Null
             ,coalesce(tmp.[Condition_Key],'''') --Not Null
             ,coalesce(tmp.[HEALTH_CARE_KEY],'''') --Not Null
             ,coalesce(tmp.[HSPTL_DISCHARGE_DT_KEY],'''') --Not Null
             ,coalesce(tmp.[HSPTL_KEY],1) --Not Null
             ,coalesce(tmp.[ILLNESS_ONSET_DT_KEY],'''') --Not Null
             ,coalesce(tmp.[INVESTIGATION_KEY],1) --Not Null
             ,coalesce(tmp.[morb_Rpt_Key],'''') --Not Null
             ,coalesce(tmp.[MORB_RPT_CREATE_DT_KEY],'''') --Not Null
             ,coalesce(tmp.[MORB_RPT_DT_KEY],'''') --Not Null
             ,coalesce(tmp.[MORB_RPT_SRC_ORG_KEY],1) --Not Null
             ,coalesce(tmp.[PHYSICIAN_KEY],'''') --Not Null
             ,coalesce(tmp.[REPORTER_KEY],1) --Not Null
             ,tmp.[LDF_GROUP_KEY] --Not Null
             ,tmp.[Morb_Rpt_Count]
             ,tmp.[Nursing_Home_Key] --Not Null
             ,substring(tmp.RECORD_STATUS_CD ,1,8) --Not Null
        FROM '+@tmp_MORBIDITY_REPORT_Event_Final+' tmp
       	LEFT JOIN MORBIDITY_REPORT_EVENT mre ON mre.morb_rpt_key = tmp.morb_rpt_key
        WHERE mre.morb_rpt_key IS NULL;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Update morb_Rpt_User_Comment';


        SET @sql= N'
        UPDATE morb_Rpt_User_Comment
        SET
        [MORB_RPT_UID]	 =	tmp.MORB_RPT_UID,
		[USER_COMMENT_KEY]	 =	tmp.USER_COMMENT_KEY,
		[MORB_RPT_KEY]	 =	tmp.MORB_RPT_KEY,
		[EXTERNAL_MORB_RPT_COMMENTS]	 =	substring(rtrim(tmp.EXTERNAL_MORB_RPT_COMMENTS), 1, 2000),
		[USER_COMMENTS_BY]	 =	tmp.USER_COMMENTS_BY,
		[USER_COMMENTS_DT]	 =	tmp.USER_COMMENTS_DT,
		[RECORD_STATUS_CD]	 =	substring(tmp.RECORD_STATUS_CD, 1, 8),
		[RDB_LAST_REFRESH_TIME]	 =	getdate()
        FROM '+@tmp_morb_Rpt_User_Comment+' tmp
      	 INNER JOIN morb_Rpt_User_Comment c ON c.MORB_RPT_UID = tmp.MORB_RPT_UID
			AND c.USER_COMMENT_KEY = tmp.USER_COMMENT_KEY ;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES
            (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Insert into morb_Rpt_User_Comment';

        SET @sql = N'
        INSERT INTO morb_Rpt_User_Comment
        (
          [MORB_RPT_UID]
        ,[USER_COMMENT_KEY]
        ,[MORB_RPT_KEY]
        ,[EXTERNAL_MORB_RPT_COMMENTS]
        ,[USER_COMMENTS_BY]
        ,[USER_COMMENTS_DT]
        ,[RECORD_STATUS_CD]
        ,[RDB_LAST_REFRESH_TIME]
        )
        SELECT tmp.MORB_RPT_UID
             ,tmp.USER_COMMENT_KEY
             ,tmp.MORB_RPT_KEY
             ,substring(rtrim(tmp.EXTERNAL_MORB_RPT_COMMENTS) ,1,2000)
             ,tmp.USER_COMMENTS_BY
             ,tmp.USER_COMMENTS_DT
             ,substring(tmp.RECORD_STATUS_CD ,1,8)
             ,getdate() AS [RDB_LAST_REFRESH_TIME]
        FROM '+@tmp_morb_Rpt_User_Comment+' tmp
      	 LEFT JOIN morb_Rpt_User_Comment c ON c.MORB_RPT_UID = tmp.MORB_RPT_UID
        WHERE c.MORB_RPT_UID is null;'

        IF @pDebug = 'true' print @sql;
        EXEC sp_executesql @sql;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES
            (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;


        IF OBJECT_ID('tmp_Morbidity_Report', 'U') IS NOT NULL  DROP TABLE    	tmp_Morbidity_Report	;
        IF OBJECT_ID('#tmp_morb_root', 'U') IS NOT NULL  DROP TABLE    	#tmp_morb_root 	;
        IF OBJECT_ID('#tmp_MorbFrmQ', 'U') IS NOT NULL  DROP TABLE    	#tmp_MorbFrmQ 	;
        IF OBJECT_ID('#tmp_MorbFrmQCoded', 'U') IS NOT NULL  DROP TABLE    	#tmp_MorbFrmQCoded 	;
        IF OBJECT_ID('#tmp_MorbFrmQDate', 'U') IS NOT NULL  DROP TABLE    	#tmp_MorbFrmQDate 	;
        IF OBJECT_ID('#tmp_MorbFrmQTxt', 'U') IS NOT NULL  DROP TABLE    	#tmp_MorbFrmQTxt 	;

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MorbFrmQCoded2+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@tmp_MorbFrmQCoded2+';
		END;');

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MorbFrmQDate2+''', ''U'') IS NOT NULL
				BEGIN
					DROP TABLE '+@tmp_MorbFrmQDate2+';
				END;');

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MorbFrmQTxt2+''', ''U'') IS NOT NULL
				BEGIN
					DROP TABLE '+@tmp_MorbFrmQTxt2+';
				END;');

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_Morbidity_Report+''', ''U'') IS NOT NULL
				BEGIN
					DROP TABLE '+@tmp_Morbidity_Report+';
				END;');

        EXEC ('IF OBJECT_ID(''tempdb..'+@SAS_morb_Rpt_User_Comment+''', ''U'') IS NOT NULL
				BEGIN
					DROP TABLE '+@SAS_morb_Rpt_User_Comment+';
				END;');

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_morb_Rpt_User_Comment+''', ''U'') IS NOT NULL
				BEGIN
					DROP TABLE '+@tmp_morb_Rpt_User_Comment+';
				END;');

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_id_assignment+''', ''U'') IS NOT NULL
				BEGIN
					DROP TABLE '+@tmp_id_assignment+';
				END;');

        EXEC ('IF OBJECT_ID(''tempdb..'+@tmp_MORBIDITY_REPORT_Event_Final+''', ''U'') IS NOT NULL
				BEGIN
					DROP TABLE '+@tmp_MORBIDITY_REPORT_Event_Final+';
				END;');


        BEGIN TRANSACTION;


        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
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
        VALUES  				   (
                                   @batch_id,
                                   'D_Morbidity_Report'
                                 ,'D_Morbidity_Report'
                                 ,'COMPLETE'
                                 ,@Proc_Step_no
                                 ,@Proc_Step_name
                                 ,@RowCount_no
                                 );

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        INSERT INTO [dbo].[job_flow_log] (
                                           batch_id
                                         ,[Dataflow_Name]
                                         ,[package_Name]
                                         ,[Status_Type]
                                         ,[step_number]
                                         ,[step_name]
                                         ,[Error_Description]
                                         ,[row_count]
        )
        VALUES
            (
              @batch_id
            ,'D_Morbidity_Report'
            ,'D_Morbidity_Report'
            ,'ERROR'
            ,@Proc_Step_no
            ,'ERROR - '+ @Proc_Step_name
            , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
            ,0
            );

        --COMMIT TRANSACTION;

        RETURN -1 ;

    END CATCH

END;