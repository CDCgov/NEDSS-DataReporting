CREATE OR ALTER PROCEDURE [dbo].[sp_d_morbidity_report_postprocessing]
(@pMorbidityIdList nvarchar(max)
, @pDebug bit = 'false')

AS

BEGIN
    /*
     * [Description]
     * This stored procedure is handles event based updates to Morbidity Report based dimensions.
     * 1. Receives input list of Morbidity Report based Observations with Order.
     * 2. Pulls changed records FROM nrt_observation using the input list INTO temporary tables for processing.
     * 3. Deletes records that exist in target dimensions.
     * 4. Inserts updated and new records INTO target dimensions.
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
        SET @PROC_STEP_NAME = 'Generating  updt_MORBIDITY_REPORT_list ';

        IF OBJECT_ID('#tmp_updt_MORBIDITY_REPORT_list', 'U') IS NOT NULL
            DROP TABLE #tmp_updt_MORBIDITY_REPORT_list;

        --List of changed observation_uids for Morbidity Report FROM nrt_observation.
        SELECT
            *
        INTO #nrt_morbidity_observation
        FROM
            DBO.NRT_OBSERVATION WITH (NOLOCK)
        WHERE
            OBSERVATION_UID IN (SELECT VALUE FROM STRING_SPLIT(@pMorbidityIdList, ','));

        --Get associated observation_uids for change uidsd: Includes MorbFormQ, LabReports, and Result uids.
        SELECT
            observation_uid
        INTO #updated_observation_list
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

        --Get a subset of observations required for post-processing
        SELECT
            *
        INTO #morb_obs_reference
        FROM
            dbo.nrt_observation with (nolock)
        WHERE
            observation_uid IN
            (SELECT observation_uid
             FROM #updated_observation_list);

        if @pDebug = 'true' SELECT 'DEBUG: updated_observation_list', * FROM #updated_observation_list;
        if @pDebug = 'true' SELECT 'DEBUG: morb_obs_reference', * FROM #morb_obs_reference;

        SELECT morb_rpt_uid, morb_rpt_key
        INTO #tmp_updt_MORBIDITY_REPORT_list
        FROM MORBIDITY_REPORT
        WHERE morb_rpt_uid IN (SELECT observation_uid FROM #updated_observation_List)
          AND morb_rpt_uid IS NOT NULL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating  tmp_SAS_updt_MORBIDITY_REPORT_list';

        IF OBJECT_ID('#tmp_SAS_updt_MORBIDITY_REPORT_list', 'U') IS NOT NULL
            DROP TABLE #tmp_SAS_updt_MORBIDITY_REPORT_list;

        --CREATE TABLE SAS_updt_MORBIDITY_REPORT_list AS
        SELECT *
        INTO #tmp_SAS_updt_MORBIDITY_REPORT_list
        FROM #tmp_updt_MORBIDITY_REPORT_list;

        --create table updt_MORBIDITY_REPORT_Event_list AS
        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating  #tmp_updt_MORBIDITY_REPORT_Event_list';

        IF OBJECT_ID('#tmp_updt_MORBIDITY_REPORT_Event_list', 'U') IS NOT NULL
            DROP TABLE #tmp_updt_MORBIDITY_REPORT_Event_list ;

        SELECT morb_rpt_key
        INTO #tmp_updt_MORBIDITY_REPORT_Event_list
        FROM dbo.MORBIDITY_REPORT_Event
        WHERE morb_rpt_key IN (SELECT morb_rpt_key FROM #tmp_updt_MORBIDITY_REPORT_list);

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating  #tmp_SAS_up_MORBIDITY_RPT_EVNT_lst';

        IF OBJECT_ID('#tmp_SAS_up_MORBIDITY_RPT_EVNT_lst', 'U') IS NOT NULL
            DROP TABLE #tmp_SAS_up_MORBIDITY_RPT_EVNT_lst ;

        SELECT *
        INTO #tmp_SAS_up_MORBIDITY_RPT_EVNT_lst
        FROM #tmp_updt_MORBIDITY_REPORT_Event_list;

        /*
        ---VS
        /* Texas - Moved code execution to database 08/20/2020 */
        /* delete * FROM MORBIDITY_REPORT_Event WHERE morb_rpt_key in (SELECT morb_rpt_key FROM updt_MORBIDITY_REPORT_Event_list); */

        PROC SQL;
        connect to odbc AS sql (Datasrc=&datasource.  USER=&username.  PASSWORD=&password.);
        EXECUTE (
        delete FROM MORBIDITY_REPORT_Event WHERE morb_rpt_key in (SELECT morb_rpt_key FROM SAS_up_MORBIDITY_RPT_EVNT_lst);
        ) by sql;
        disconnect FROM sql;
        QUIT;
        */

        DELETE FROM MORBIDITY_REPORT_Event
        WHERE morb_rpt_key IN (SELECT morb_rpt_key FROM #tmp_SAS_up_MORBIDITY_RPT_EVNT_lst);

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating  #tmp_UPDT_MORB_RPT_USER_COMMENT_LIST';

        IF OBJECT_ID('#tmp_UPDT_MORB_RPT_USER_COMMENT_LIST', 'U') IS NOT NULL
            DROP TABLE #tmp_UPDT_MORB_RPT_USER_COMMENT_LIST ;

        SELECT MORB_RPT_UID
        INTO #tmp_UPDT_MORB_RPT_USER_COMMENT_LIST
        FROM MORB_RPT_USER_COMMENT
        WHERE MORB_RPT_UID IN (SELECT observation_uid FROM #updated_observation_List);

        /*

        /* Texas - Moved code execution to database 08/20/2020 */
        /* delete * FROM MORB_RPT_USER_COMMENT WHERE morb_rpt_key in (SELECT morb_rpt_key FROM updt_MORBIDITY_REPORT_list); */
        PROC SQL;
        connect to odbc AS sql (Datasrc=&datasource.  USER=&username.  PASSWORD=&password.);
        EXECUTE (
        delete FROM MORB_RPT_USER_COMMENT WHERE morb_rpt_key in (SELECT morb_rpt_key FROM SAS_updt_MORBIDITY_REPORT_list);
        ) by sql;
        disconnect FROM sql;
        QUIT;

        /* Texas - Moved code execution to database 08/20/2020 */
        /* delete * FROM LAB_TEST_RESULT WHERE morb_rpt_key in (SELECT morb_rpt_key FROM updt_MORBIDITY_REPORT_list); */
        PROC SQL;
        connect to odbc AS sql (Datasrc=&datasource.  USER=&username.  PASSWORD=&password.);
        EXECUTE (
        delete FROM LAB_TEST_RESULT WHERE morb_rpt_key in (SELECT morb_rpt_key FROM SAS_updt_MORBIDITY_REPORT_list);
        ) by sql;
        disconnect FROM sql;
        QUIT;

        /* Texas - Moved code execution to database 08/20/2020 */
        /* delete * FROM MORBIDITY_REPORT WHERE morb_rpt_key in (SELECT morb_rpt_key FROM updt_MORBIDITY_REPORT_list); */
        PROC SQL;
        connect to odbc AS sql (Datasrc=&datasource.  USER=&username.  PASSWORD=&password.);
        EXECUTE (
        delete FROM MORBIDITY_REPORT WHERE morb_rpt_key in (SELECT morb_rpt_key FROM SAS_updt_MORBIDITY_REPORT_list);
        ) by sql;
        disconnect FROM sql;
        QUIT;

        */

        DELETE FROM MORB_RPT_USER_COMMENT WHERE morb_rpt_key IN (SELECT morb_rpt_key FROM #tmp_SAS_updt_MORBIDITY_REPORT_list);

        DELETE FROM LAB_TEST_RESULT WHERE morb_rpt_key IN (SELECT morb_rpt_key FROM #tmp_SAS_updt_MORBIDITY_REPORT_list);

        DELETE a FROM Morbidity_Report a inner join #tmp_SAS_updt_MORBIDITY_REPORT_list tsm ON  a.morb_rpt_key = tsm.morb_rpt_key;


        --create table Morb_Root AS

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating  tmp_Morb_Root';


        IF OBJECT_ID('#tmp_Morb_Root', 'U') IS NOT NULL
            DROP TABLE #tmp_Morb_Root ;


        CREATE TABLE #tmp_Morb_Root(
                                       morb_Rpt_Key_id  [int] IDENTITY(1,1) NOT NULL,
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

        INSERT INTO #tmp_Morb_Root(
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
                  obs.record_status_cd,
                  obs.PROCESSING_DECISION_CD ,
                  substring(cvg.Code_short_desc_txt,1,25)

        FROM #nrt_morbidity_observation AS updated_lab
                 inner join dbo.nrt_observation obs ON updated_lab.observation_uid =obs.observation_uid
                 left outer join NBS_SRTE..Code_value_general  cvg ON cvg.code_set_nm = 'STD_NBS_PROCESSING_DECISION_ALL' AND cvg.code = obs.PROCESSING_DECISION_CD
        WHERE obs.obs_domain_cd_st_1 = 'Order'
          and obs.CTRL_CD_DISPLAY_FORM  = 'MorbReport';


        UPDATE #tmp_Morb_Root
        SET jurisdiction_nm = (
            SELECT code_short_desc_txt
            FROM nbs_srte..jurisdiction_code WHERE code= #tmp_Morb_Root.Jurisdiction_cd and code_set_nm = 'S_JURDIC_C'
        )
        WHERE Jurisdiction_cd is not NULL
        ;


        if @pDebug = 'true' SELECT 'DEBUG: tmp_Morb_Root',* FROM #tmp_Morb_Root;


        /*

        proc sort data = Morb_Root;
        by morb_rpt_uid;

        %assign_key(Morb_Root, morb_Rpt_Key); --VS
        proc sql;
        tmp_
        */
        /*

        --delete FROM tmp_Morb_Root WHERE  morb_Rpt_Key=1;


        ALTER TABLE Morb_Root ADD morb_rpt_KEY_MAX_VAL  NUMERIC;


        UPDATE tmp_Morb_Root SET morb_rpt_KEY_MAX_VAL=(SELECT MAX(morb_rpt_KEY) FROM morbidity_report);
        */


        UPDATE #tmp_Morb_Root
        SET morb_rpt_KEY= morb_rpt_KEY_id + coalesce((SELECT MAX(morb_rpt_KEY) FROM dbo.Morbidity_Report),1);

        if @pDebug = 'true' SELECT 'DEBUG: tmp_Morb_Root_keyvalue',* FROM #tmp_Morb_Root;

        -- VS PROCESSING_DECISION_DESC=PUT(PROCESSING_DECISION_CD,$APROCDNF.);

        UPDATE #tmp_Morb_Root
        SET  record_status_cd = 'INACTIVE'
        WHERE  record_status_cd = 'LOG_DEL';

        UPDATE #tmp_Morb_Root
        SET  record_status_cd = 'ACTIVE'
        WHERE  rtrim(record_status_cd) in (  'PROCESSED','UNPROCESSED', '');

        /* Morb Report Form Question */

        --create table MorbFrmQ AS

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
        FROM	#tmp_morb_root					as mr
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
        FROM	#tmp_MorbFrmQ					as oq,
                dbo.nrt_observation_coded AS ob
        WHERE 	oq.observation_uid = ob.observation_uid;

        if @pDebug = 'true' SELECT 'DEBUG: tmp_MorbFrmQCoded',* FROM #tmp_MorbFrmQCoded;

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
        FROM	#tmp_MorbFrmQ					as oq,
                dbo.nrt_observation_date AS ob
        WHERE 	oq.observation_uid = ob.observation_uid;

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
        FROM #tmp_MorbFrmQ					as oq,
             dbo.nrt_observation_txt AS ob
        WHERE 	oq.observation_uid = ob.observation_uid;

        /*

          proc sort data = MorbFrmQTxt;
          by morb_rpt_uid;


          proc transpose data = MorbFrmQCoded out =MorbFrmQCoded2(drop= _name_ _label_);
              id cd;
              var code;
              by morb_rpt_uid;

          run;
          */

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating tmp_MorbFrmQCoded2';


        IF OBJECT_ID('tempdb..##tmp_MorbFrmQCoded2', 'U') IS NOT NULL
            DROP TABLE ##tmp_MorbFrmQCoded2 ;


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
                   ' INTO ##tmp_MorbFrmQCoded2 ' +
                   'FROM (
                   SELECT [morb_rpt_uid], [code] , [CD]
                    FROM #tmp_MorbFrmQCoded
                       group by [morb_rpt_uid], [code] , [CD]
                           ) AS j PIVOT (max(code) FOR [CD] in
                          ('+STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')+')) AS p;';

        print @sql;
        EXEC sp_executesql @sql;


        if @pDebug = 'true' SELECT 'DEBUG: tmp_MorbFrmQCoded2',* FROM ##tmp_MorbFrmQCoded2;


        /*

        proc transpose data = MorbFrmQDate out =MorbFrmQDate2 (drop= _name_ _label_);
            id cd;
            var FROM_time;
            by morb_rpt_uid;
        run;
        */

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQDate2';


        IF OBJECT_ID('tempdb..##tmp_MorbFrmQDate2', 'U') IS NOT NULL
            DROP TABLE ##tmp_MorbFrmQDate2 ;

        --DECLARE @columns NVARCHAR(MAX);
        --DECLARE @sql NVARCHAR(MAX);

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
                   ' INTO ##tmp_MorbFrmQDate2 ' +
                   'FROM (
                   SELECT [morb_rpt_uid], [FROM_time] , [CD]
                    FROM #tmp_MorbFrmQDate
                       group by [morb_rpt_uid], [FROM_time] , [CD]
                           ) AS j PIVOT (max(FROM_time) FOR [CD] in
                          ('+STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')+')) AS p;';

        print @sql;
        EXEC sp_executesql @sql;

        if @pDebug = 'true' SELECT 'DEBUG: tmp_MorbFrmQCoded2',* FROM ##tmp_MorbFrmQDate2;


        /*
        proc transpose data = MorbFrmQTxt out =MorbFrmQTxt2 (drop= _name_ _label_);
            id cd;
            var value_txt;
            by morb_rpt_uid;
        run;

        */

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQTxt2';

        IF OBJECT_ID('tempdb..##tmp_MorbFrmQTxt2', 'U') IS NOT NULL
            DROP TABLE ##tmp_MorbFrmQTxt2;

        --DECLARE @columns NVARCHAR(MAX);
        --DECLARE @sql NVARCHAR(MAX);

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
                   ' INTO ##tmp_MorbFrmQTxt2 ' +
                   'FROM (
               SELECT [morb_rpt_uid], [value_txt] , [CD]
                    FROM #tmp_MorbFrmQTxt
                       group by [morb_rpt_uid], [value_txt] , [CD]
        ) AS j PIVOT (max(value_txt) FOR [CD] in
                          ('+STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')+')) AS p;';

        print @sql;
        EXEC sp_executesql @sql;

        if @pDebug = 'true' SELECT 'DEBUG: tmp_MorbFrmQTxt2',* FROM ##tmp_MorbFrmQTxt2;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQCoded2';

        IF OBJECT_ID('tempdb..##tmp_MorbFrmQCoded2', 'U') IS  NULL
        create table ##tmp_MorbFrmQCoded2 (morb_rpt_uid_coded [bigint] NOT NULL
        ) ON [PRIMARY];


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQDate2';

        IF OBJECT_ID('tempdb..##tmp_MorbFrmQDate2', 'U') IS  NULL
        create table ##tmp_MorbFrmQDate2 (morb_rpt_uid_date [bigint] NOT NULL
        ) ON [PRIMARY];

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating ##tmp_MorbFrmQTxt2';

        IF OBJECT_ID('tempdb..##tmp_MorbFrmQTxt2', 'U') IS  NULL
        create table ##tmp_MorbFrmQTxt2 (	morb_rpt_uid_txt [bigint] NOT NULL
        ) ON [PRIMARY];

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating #tmp_Morbidity_Report';

        IF OBJECT_ID('#tmp_Morbidity_Report', 'U') IS NOT NULL
            DROP TABLE #tmp_Morbidity_Report;

        /*

        data Morbidity_Report;
     merge Morb_Root MorbFrmQCoded2 MorbFrmQDate2 MorbFrmQTxt2;
            by morb_rpt_uid;
        run;
        */

        SELECT mr.*, tmc2.*, tmd2.*,tmt2.*,
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
               Cast( NULL AS datetime)  AS RDB_LAST_REFRESH_TIME
        INTO #tmp_Morbidity_Report
        FROM #TMP_morb_root mr
                 full outer join ##tmp_MorbFrmQCoded2 tmc2 ON mr.morb_rpt_uid = tmc2.morb_rpt_uid_coded
                 full outer join ##tmp_MorbFrmQDate2 tmd2  ON mr.morb_rpt_uid = tmd2.morb_rpt_uid_date
                 full outer join ##tmp_MorbFrmQTxt2 tmt2  ON mr.morb_rpt_uid = tmt2.morb_rpt_uid_txt;


        if @pDebug = 'true' SELECT 'DEBUG: tmp_Morbidity_Report root',* FROM #tmp_Morbidity_Report;

        /*
        data Morbidity_Report;
        format MRB122 MRB165 MRB166 MRB167 DATETIME20. ;
        format INV128 INV145 INV148 INV149 INV178 MRB130 MRB168 $50.;
        format MRB100 MRB161 $20. MRB102 MRB169 $2000.;

            INV128 = '';
            INV145 = '';
            INV148 = '';
            INV149 = '';
            INV178 = '';
            MRB100 = '';
            MRB102 = '';
            MRB122 = .;
            MRB129 = '';
            MRB130 = '';
            MRB161 = '';
            MRB165 = .;
            MRB166 = .;
            MRB167 = .;
            MRB168 = '';
            MRB169 = '';
        */

        /*
            SET Morbidity_Report;
            if record_status_cd = 'LOG_DEL' then record_status_cd = 'INACTIVE' ;
            if record_status_cd = 'PROCESSED' then record_status_cd = 'ACTIVE' ;
            if record_status_cd = 'UNPROCESSED' then record_status_cd = 'ACTIVE' ;
            If record_status_cd = '' then record_status_cd = 'ACTIVE';
        run;
        */

        UPDATE #TMP_Morbidity_Report
        SET record_status_cd = 'INACTIVE'
        WHERE record_status_cd = 'LOG_DEL';

        UPDATE #TMP_Morbidity_Report
        SET record_status_cd = 'ACTIVE'
        WHERE record_status_cd in ( 'PROCESSED','UNPROCESSED')
           or rtrim(record_status_cd) is NULL;

        /*Reason for not using lookup to find rdb column names
            1. Some columns in root obs. These columns must be hard coded, not suitable for lookup
            2. Same AS above for Key columns, must be hard coded
            3. Unique id to Column name lookup table Not Reliable
        */
        /*

        proc datasets lib=work nolist;
            modify Morbidity_Report;
            rename
                /*These were no longer in the logical model*/
                INV128 = HOSPITALIZED_IND
                INV145 = DIE_FROM_ILLNESS_IND
                INV148 = DAYCARE_IND
                INV149 = FOOD_HANDLER_IND
                INV178 = PREGNANT_IND
                MRB100 = MORB_RPT_TYPE
                MRB102 = MORB_RPT_COMMENTS
                MRB122 = TEMP_ILLNESS_ONSET_DT_KEY
       MRB129 = NURSING_HOME_ASSOCIATE_IND
                MRB130 = HEALTHCARE_ORG_ASSOCIATE_IND
                MRB161 = MORB_RPT_DELIVERY_METHOD
                MRB165 = TEMP_DIAGNOSIS_DT_KEY
                MRB166 = HSPTL_ADMISSION_DT
                MRB167 = TEMP_HSPTL_DISCHARGE_DT_KEY
            MRB168 = SUSPECT_FOOD_WTRBORNE_ILLNESS
                MRB169 = MORB_RPT_OTHER_SPECIFY
        ;
   run;
        */

        --UPDATE TMP_Morbidity_Report set	 HOSPITALIZED_IND	=	INV128 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'INV128') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 HOSPITALIZED_IND	=	INV128 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 DIE_FROM_ILLNESS_IND	=	INV145 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'INV145') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 DIE_FROM_ILLNESS_IND	=	INV145 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 DAYCARE_IND	=	INV148 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'INV148') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 DAYCARE_IND	=	INV148 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 FOOD_HANDLER_IND	=	INV149 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'INV149') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 FOOD_HANDLER_IND	=	INV149 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 PREGNANT_IND	=	INV178 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'INV178') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 PREGNANT_IND	=	INV178 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 MORB_RPT_TYPE	=	MRB100 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB100') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 MORB_RPT_TYPE	=	MRB100 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 MORB_RPT_COMMENTS	=	rtrim(MRB102) 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB102') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 MORB_RPT_COMMENTS	=	rtrim(MRB102) 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 TEMP_ILLNESS_ONSET_DT_KEY	=	MRB122 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB122') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 TEMP_ILLNESS_ONSET_DT_KEY	=	MRB122 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 NURSING_HOME_ASSOCIATE_IND	=	substring(MRB129,1,1) 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB129') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 NURSING_HOME_ASSOCIATE_IND	=	substring(MRB129,1,1)  	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 HEALTHCARE_ORG_ASSOCIATE_IND	=	MRB130 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB130') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 HEALTHCARE_ORG_ASSOCIATE_IND	=	MRB130 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 MORB_RPT_DELIVERY_METHOD	=	MRB161 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB161') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 MORB_RPT_DELIVERY_METHOD	=	MRB161 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 TEMP_DIAGNOSIS_DT_KEY	=	MRB165 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB165') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 TEMP_DIAGNOSIS_DT_KEY	=	MRB165 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 DIAGNOSIS_DT	=	MRB165 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB165') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 DIAGNOSIS_DT	=	MRB165 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 HSPTL_ADMISSION_DT	=	MRB166 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB166') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 HSPTL_ADMISSION_DT	=	MRB166 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 TEMP_HSPTL_DISCHARGE_DT_KEY	=	MRB167 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB167') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 TEMP_HSPTL_DISCHARGE_DT_KEY	=	MRB167 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 SUSPECT_FOOD_WTRBORNE_ILLNESS	=	MRB168 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB168') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 SUSPECT_FOOD_WTRBORNE_ILLNESS	=	MRB168 	;
            END;

        --UPDATE #TMP_Morbidity_Report set	 MORB_RPT_OTHER_SPECIFY	=	MRB169 	;
        IF(COL_LENGTH('tempdb..#TMP_Morbidity_Report', 'MRB169') IS  NOT NULL)
            BEGIN
                UPDATE #TMP_Morbidity_Report set	 MORB_RPT_OTHER_SPECIFY	=	MRB169 	;
            END;

        if @pDebug = 'true' SELECT 'DEBUG: tmp_Morbidity_Report',* FROM #tmp_Morbidity_Report;


        /*-------------------------------------------------------

            morb_Report_User_Comment Dimension

            Note: Comments under the Order Test object (LAB214)
        ---------------------------------------------------------*/

        create index IDX_morb_rpt_uid ON #TMP_Morbidity_Report(morb_rpt_uid);

        /*
        /* Texas - Moved code execution to database 08/20/2020 */
        PROC SQL;
        DROP TABLE SAS_morb_Rpt_User_Comment;
        DROP TABLE SAS_Morbidity_Report;
        QUIT;

        PROC SQL;
        CREATE TABLE SAS_Morbidity_Report AS SELECT * FROM Morbidity_Report;
        QUIT;

        PROC SQL;
        connect to odbc AS sql (Datasrc=&datasource.  USER=&username.  PASSWORD=&password.);
        execute (CREATE INDEX morb_rpt_uid ON SAS_Morbidity_Report(morb_rpt_uid)) by sql;
        disconnect FROM sql;
        QUIT;
        */

        -- (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating  SAS_Morbidity_Report';

        IF OBJECT_ID('#tmp_SAS_Morbidity_Report', 'U') IS NOT NULL
            DROP TABLE #tmp_SAS_Morbidity_Report;

        /*		INSERT INTO tmp_SAS_Morbidity_Report
						([TEMP_ILLNESS_ONSET_DT_KEY]
							  ,[TEMP_DIAGNOSIS_DT_KEY]
							  ,[HSPTL_ADMISSION_DT]
							  ,[TEMP_HSPTL_DISCHARGE_DT_KEY]
							  ,[HOSPITALIZED_IND]
							  ,[DIE_FROM_ILLNESS_IND]
							  ,[DAYCARE_IND]
							  ,[FOOD_HANDLER_IND]
							  ,[PREGNANT_IND]
							  ,[HEALTHCARE_ORG_ASSOCIATE_IND]
							  ,[SUSPECT_FOOD_WTRBORNE_ILLNESS]
							  ,[MORB_RPT_TYPE]
							  ,[MORB_RPT_DELIVERY_METHOD]
							  ,[MORB_RPT_COMMENTS]
							  ,[MORB_RPT_OTHER_SPECIFY]
							  ,[NURSING_HOME_ASSOCIATE_IND]
							  ,[morb_Rpt_Key]
							  ,[morb_rpt_local_id]
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
							  ,[processing_decision_cd]
							  ,[PROCESSING_DECISION_DESC])
        */

        SELECT [TEMP_ILLNESS_ONSET_DT_KEY]
             ,[TEMP_DIAGNOSIS_DT_KEY]
             ,[HSPTL_ADMISSION_DT]
             ,[TEMP_HSPTL_DISCHARGE_DT_KEY]
             ,[HOSPITALIZED_IND]
             ,[DIE_FROM_ILLNESS_IND]
             ,[DAYCARE_IND]
             ,[FOOD_HANDLER_IND]
             ,[PREGNANT_IND]
             ,[HEALTHCARE_ORG_ASSOCIATE_IND]
             ,[SUSPECT_FOOD_WTRBORNE_ILLNESS]
             ,[MORB_RPT_TYPE]
             ,[MORB_RPT_DELIVERY_METHOD]
             ,[MORB_RPT_COMMENTS]
             ,[MORB_RPT_OTHER_SPECIFY]
             ,[NURSING_HOME_ASSOCIATE_IND]
             ,[morb_Rpt_Key]
             ,[morb_rpt_local_id]
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
             ,[processing_decision_cd]
             ,[PROCESSING_DECISION_DESC]
        INTO #tmp_SAS_Morbidity_Report
        FROM #tmp_Morbidity_Report;

        --create index IDX_sas_morb_rpt_uid ON SAS_Morbidity_Report(morb_rpt_uid);

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating #SAS_morb_Rpt_User_Comment';

        IF OBJECT_ID('#SAS_morb_Rpt_User_Comment', 'U') IS NOT NULL
            DROP TABLE #SAS_morb_Rpt_User_Comment;

        /*
         PROC SQL;
         connect to odbc AS sql (Datasrc=&datasource.  USER=&username.  PASSWORD=&password.);
         EXECUTE (
         */


        --NRT table update: Test with followup section
        SELECT 	root.morb_Rpt_Key,
                  root.morb_rpt_uid,
                  obs.activity_to_time	 AS user_comments_dt,
                  obs.add_user_id		 AS user_comments_by,
                  REPLACE(ovt.ovt_value_txt,'0D0A',' ') AS external_morb_rpt_comments,  /* TRANSLATE(ovt.value_txt,' ' ,'0D0A'x) 'EXTERNAL_MORB_RPT_COMMENTS' AS external_morb_rpt_comments, */
                  root.record_status_cd
        INTO  #SAS_morb_Rpt_User_Comment
        FROM #tmp_SAS_Morbidity_Report			as root,
             #updated_observation_list AS ls,
             #morb_obs_reference AS obs,
             dbo.nrt_observation_txt AS ovt
        WHERE ls.observation_uid = obs.observation_uid
          and root.morb_rpt_uid = obs.observation_uid
          and ovt.ovt_value_txt is not NULL
          and obs.OBS_DOMAIN_CD_ST_1 IN ('C_Order', 'C_Result');

        if @pDebug = 'true' SELECT 'DEBUG: SAS_morb_Rpt_User_Comment',* FROM #SAS_morb_Rpt_User_Comment;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating #tmp_morb_Rpt_User_Comment';

        IF OBJECT_ID('#tmp_morb_Rpt_User_Comment', 'U') IS NOT NULL
            DROP TABLE #tmp_morb_Rpt_User_Comment;

        CREATE TABLE #tmp_morb_Rpt_User_Comment(
                                                   User_Comment_Key_id  [int] IDENTITY(1,1) NOT NULL,
                                                   [morb_Rpt_Key] [int] NULL,
                                                   [morb_rpt_uid] [bigint] NULL,
                                                   [user_comments_dt] [datetime] NULL,
                                                   [user_comments_by] [bigint] NULL,
                                                   [external_morb_rpt_comments] [varchar](8000) NULL,
                                                   [record_status_cd] [varchar](20) NULL,
                                                   User_Comment_key int
        ) ON [PRIMARY];

        INSERT INTO #tmp_morb_Rpt_User_Comment
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
        FROM #SAS_morb_Rpt_User_Comment;

        UPDATE #tmp_morb_Rpt_User_Comment
        SET User_Comment_key= User_Comment_Key_id + coalesce((SELECT MAX(User_Comment_key) FROM dbo.morb_rpt_user_comment),0);

        /*
       delete FROM dbo.tmp_morb_Rpt_User_Comment WHERE USER_COMMENT_KEY=1 and USER_COMMENT_KEY_MAX_VAL >0;
       delete FROM dbo.tmp_morb_Rpt_User_Comment WHERE USER_COMMENT_KEY=1 and USER_COMMENT_KEY_MAX_VAL is NULL ;
       delete FROM dbo.tmp_morb_Rpt_User_Comment WHERE morb_rpt_KEY is NULL;
       */

        /*

        %assign_key(morb_Rpt_User_Comment, User_Comment_key);


        DATA morb_rpt_user_comment;
        SET morb_rpt_user_comment;
        if morb_rpt_key = . then morb_rpt_key = 1;
    run;

        proc sql;
   ALTER TABLE morb_rpt_user_comment ADD User_Comment_key_MAX_VAL NUMERIC;
        UPDATE  morb_rpt_user_comment SET User_Comment_key_MAX_VAL=(SELECT MAX(User_Comment_key) FROM morb_rpt_user_comment);
        quit;
        DATA  morb_rpt_user_comment;
        SET  morb_rpt_user_comment;
        IF User_Comment_key_MAX_VAL  ~=. THEN User_Comment_key= User_Comment_key+User_Comment_key_MAX_VAL;
        RUN;


        */


        /*-------------------------------------------------------

            MORBIDITY_REPORT_Event( Keys table )

        ---------------------------------------------------------*/

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES
            (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Generating #tmp_MORBIDITY_REPORT_Event_Final';

        IF OBJECT_ID('#tmp_MORBIDITY_REPORT_Event_Final', 'U') IS NOT NULL
            DROP TABLE #tmp_MORBIDITY_REPORT_Event_Final;

        /*NRT Update:*/
        SELECT 	pat.PATIENT_Key				'PATIENT_KEY' ,
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
        INTO #tmp_MORBIDITY_REPORT_Event_Final
        FROM #TMP_Morbidity_Report	rpt
                 inner join #morb_obs_reference n ON rpt.morb_rpt_uid = n.observation_uid
                 left join d_patient AS pat ON n.patient_id = pat.patient_uid
                 left join condition AS con ON  rpt.condition_cd = con.condition_cd	AND rtrim(con.condition_cd) != ''
                 left join d_Organization AS org1 ON org1.Organization_uid = n.health_care_id
            /*HSPTL_DISCHARGE_DT_KEY*/
                 left join rdb_date	as dt3	on rpt.temp_hsptl_discharge_dt_key = dt3.date_mm_dd_yyyy
            /*	HSPTL_KEY*/
                 left join d_Organization AS org2 ON n.morb_hosp_id = org2.Organization_uid
            /*ILLNESS_ONSET_DT_KEY*/
                 left join rdb_date	as dt4 ON rpt.temp_illness_onset_dt_key = dt4.date_mm_dd_yyyy
            /* INVESTIGATION_KEY  */
                 left join dbo.nrt_investigation_observation AS ninv ON rpt.morb_rpt_uid = ninv.observation_id --TODO: Review logic FROM inv
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
                 left join ldf_group AS ldf_g ON rpt.morb_rpt_uid = ldf_g.business_object_uid;

        if @pDebug = 'true' SELECT 'DEBUG: tmp_MORBIDITY_REPORT_Event_Final',* FROM #tmp_MORBIDITY_REPORT_Event_Final;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES 		(@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'UPDATE #tmp_Morbidity_Report ';

        /*

                    /*Need this because there is bad data existing in ODS...once the bad data
        is removed this code will not execute*/
          /*data ;
                    SET MORBIDITY_REPORT_Event;
                    if lab_test_key =. then lab_test_key =1;
                    run;*/

                    data morbidity_report
                        (drop = /*TEMP_PH_RECEIVE_DT_KEY*/
                                TEMP_ILLNESS_ONSET_DT_KEY
                                /*TEMP_DIAGNOSIS_DT_KEY*/
                                /*TEMP_HSPTL_ADMISSION_DT_KEY*/
         TEMP_HSPTL_DISCHARGE_DT_KEY
        /*DIE_FROM_ILLNESS_IND
                                DAYCARE_IND
                                FOOD_HANDLER_IND
                                PREGNANT_IND*/
                                morb_RPT_Created_DT
                                morb_report_date
                                Condition_cd
                                /*HOSPITALIZED_IND*/
                                /*ELECTRONIC_IND*/

                        );

                        SET morbidity_report;
                    run;
                    data morbidity_report
                        (rename = (TEMP_DIAGNOSIS_DT_KEY = DIAGNOSIS_DT))
                        ;
                        SET morbidity_report;
                    data Morbidity_Report;
                        SET Morbidity_Report;
                    run;
                    proc sql;
                    delete FROM MORBIDITY_REPORT WHERE morb_rpt_uid is NULL;
                    quit;
                    */


        /*
        alter table tmp_morbidity_report
            drop column
                    TEMP_ILLNESS_ONSET_DT_KEY
                    ,TEMP_HSPTL_DISCHARGE_DT_KEY
                    ,morb_RPT_Created_DT
                    ,morb_report_date
      ,Condition_cd
                    ;

        */
        /*

        DATA MORBIDITY_REPORT;

        SET MORBIDITY_REPORT;
        RDB_LAST_REFRESH_TIME=DATETIME();
        RUN;
        %dbload (MORBIDITY_REPORT, MORBIDITY_REPORT);
        */

        UPDATE #tmp_Morbidity_Report
        SET PROCESSING_DECISION_CD  = NULL WHERE rtrim(PROCESSING_DECISION_CD) = '';

        update #tmp_Morbidity_Report
        SET RDB_LAST_REFRESH_TIME = GETDATE();

        --alter table tmp_Morbidity_Report
        --  drop column
        --  [morb_Rpt_Key_id]
        --  [PROVIDER_KEY]
        -- [morb_rpt_uid_coded]
        --,[INV128]
        --,[INV145]
        --,[INV148]
        -- ,[INV149]
        -- ,[INV178]
        -- ,[MRB100]
        --  ,[MRB129]
        -- ,[MRB130]
        --  ,[MRB161]
        --  ,[MRB168]
        -- ,[morb_rpt_uid_date]
        --  ,[MRB122]
        --,[MRB165]
        --,[MRB166]
        --,[MRB167]
        -- ,[morb_rpt_uid_txt]
        --,[MRB102]
        --,[MRB169]

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES
            (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Inserting into dbo.Morbidity_Report ';

        INSERT INTO Morbidity_Report
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
        SELECT [MORB_RPT_KEY] --Not Null
             ,MORB_RPT_UID
             , substring(MORB_RPT_LOCAL_ID ,1,50)
             ,MORB_RPT_SHARE_IND
             ,MORB_RPT_OID
             , substring(MORB_RPT_TYPE ,1,50)
             , substring(MORB_RPT_COMMENTS ,1,2000)
             , substring(MORB_RPT_DELIVERY_METHOD ,1,50)
             , substring(SUSPECT_FOOD_WTRBORNE_ILLNESS ,1,50)
             , substring(MORB_RPT_OTHER_SPECIFY ,1,2000)
             , substring(NURSING_HOME_ASSOCIATE_IND ,1,50)
             , substring(JURISDICTION_CD ,1,20)
             , substring(JURISDICTION_NM ,1,100)
             , substring(HEALTHCARE_ORG_ASSOCIATE_IND ,1,50)
             ,MORB_RPT_CREATE_BY
             ,MORB_RPT_LAST_UPDATE_DT
             ,MORB_RPT_LAST_UPDATE_BY
             ,DIAGNOSIS_DT
             ,HSPTL_ADMISSION_DT
             ,PH_RECEIVE_DT
             , substring(DIE_FROM_ILLNESS_IND ,1,50)
             , substring(HOSPITALIZED_IND ,1,50)
             , substring(PREGNANT_IND ,1,50)
             , substring(FOOD_HANDLER_IND ,1,50)
             , substring(DAYCARE_IND ,1,50)
             , substring(ELECTRONIC_IND ,1,50)
             , substring(RECORD_STATUS_CD ,1,8) --Not Null
             ,RDB_LAST_REFRESH_TIME
             , substring(PROCESSING_DECISION_CD ,1,50)
             , substring(PROCESSING_DECISION_DESC ,1,50)
        FROM #tmp_Morbidity_Report;

        if @pDebug = 'true' SELECT 'DEBUG: tmp_Morbidity_Report',* FROM #tmp_Morbidity_Report;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
        VALUES(@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        INSERT INTO dbo.Morbidity_Report (morb_rpt_KEY,[RECORD_STATUS_CD])
        SELECT 1,'ACTIVE'
        WHERE NOT EXISTS (SELECT (morb_rpt_KEY) FROM dbo.Morbidity_Report WHERE morb_rpt_KEY = 1);


        /*
               proc sql;
           delete FROM morb_Rpt_User_Comment WHERE USER_COMMENT_KEY=1 and USER_COMMENT_KEY_MAX_VAL >0;
               delete FROM morb_Rpt_User_Comment WHERE USER_COMMENT_KEY=1 and USER_COMMENT_KEY_MAX_VAL =.;
               delete FROM morb_Rpt_User_Comment WHERE morb_rpt_KEY=.;
               quit;
               PROC SQL;



               data morb_Rpt_User_Comment;
                   SET morb_Rpt_User_Comment;
                   If record_status_cd = '' then record_status_cd = 'ACTIVE';
               run;
               DATA MORB_RPT_USER_COMMENT;
               SET MORB_RPT_USER_COMMENT;
               RDB_LAST_REFRESH_TIME=DATETIME();
               RUN;
               %dbload (MORB_RPT_USER_COMMENT, MORB_RPT_USER_COMMENT);
               PROC SQL;



               data MORBIDITY_REPORT_Event (drop= condition_cd);
                   SET MORBIDITY_REPORT_Event;
                   if patient_key =. then patient_key =1;
                   if condition_key =. then condition_key=1;
                   if investigation_key =. then investigation_key=1;
                   if MORB_RPT_SRC_ORG_KEY=. then MORB_RPT_SRC_ORG_KEY=1;
                   if HSPTL_KEY=. then HSPTL_KEY=1;
                   if HEALTH_CARE_KEY=. then HEALTH_CARE_KEY=1;
                   if PHYSICIAN_KEY=. then PHYSICIAN_KEY=1;
                   if REPORTER_KEY=. then REPORTER_KEY=1;
                   if Nursing_Home_Key=. then Nursing_Home_Key=1;
               run;

               /*if treatment_key = . then treatment_key =1;*/
               data MORBIDITY_REPORT_Event;
                   SET MORBIDITY_REPORT_Event;
               run;
               proc sql;
               delete FROM MORBIDITY_REPORT_Event WHERE morb_rpt_key is NULL;
               quit;
               proc sort data = MORBIDITY_REPORT_Event;
               by morb_rpt_key;
               run;
               DATA MORBIDITY_REPORT_Event;
               SET MORBIDITY_REPORT_Event;
               RDB_LAST_REFRESH_TIME=DATETIME();
               RUN;

               %dbload (MORBIDITY_REPORT_Event, MORBIDITY_REPORT_Event);



               /**Delete temporary data sets**/
               PROC datasets library = work nolist;
               delete
               Morb_Root
               MorbFrmQ
               MorbFrmQCoded
               MorbFrmQDate
               MorbFrmQTxt
               MorbFrmQCoded2
               MorbFrmQDate2
               MorbFrmQTxt2
               Morbidity_Report
               morb_Rpt_User_Comment
               MORBIDITY_REPORT_Event;
               run;
               quit;
               */


        --(@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Inserting into MORBIDITY_REPORT_Event';

        --create table tmp_MORBIDITY_REPORT_Event_Final AS

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
        SELECT  [PATIENT_KEY] --Not Null
             ,coalesce([Condition_Key],'') --Not Null
             ,coalesce([HEALTH_CARE_KEY],'') --Not Null
             ,coalesce([HSPTL_DISCHARGE_DT_KEY],'') --Not Null
             ,coalesce([HSPTL_KEY],'1') --Not Null
             ,coalesce([ILLNESS_ONSET_DT_KEY],'') --Not Null
             ,coalesce([INVESTIGATION_KEY],'1') --Not Null
             ,coalesce([morb_Rpt_Key],'') --Not Null
             ,coalesce([MORB_RPT_CREATE_DT_KEY],'') --Not Null
             ,coalesce([MORB_RPT_DT_KEY],'') --Not Null
             ,coalesce([MORB_RPT_SRC_ORG_KEY],1) --Not Null
             ,coalesce([PHYSICIAN_KEY],'') --Not Null
             ,coalesce([REPORTER_KEY],'1') --Not Null
             ,[LDF_GROUP_KEY] --Not Null
             ,[Morb_Rpt_Count]
             ,[Nursing_Home_Key] --Not Null
             ,substring(RECORD_STATUS_CD ,1,8) --Not Null
        FROM #tmp_MORBIDITY_REPORT_Event_Final;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES  (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
        SET @PROC_STEP_NAME = 'Insert INTO morb_Rpt_User_Comment';

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
        SELECT MORB_RPT_UID
             ,USER_COMMENT_KEY
             ,MORB_RPT_KEY
             ,substring(rtrim(EXTERNAL_MORB_RPT_COMMENTS) ,1,2000)
             ,USER_COMMENTS_BY
             ,USER_COMMENTS_DT
             ,substring(RECORD_STATUS_CD ,1,8)
             ,getdate() AS [RDB_LAST_REFRESH_TIME]
        FROM #tmp_morb_Rpt_User_Comment;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
        VALUES
            (@BATCH_ID,'D_Morbidity_Report','D_Morbidity_Report','START',@PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

        COMMIT TRANSACTION;

        IF OBJECT_ID('tmp_Morbidity_Report', 'U') IS NOT NULL  DROP TABLE    	tmp_Morbidity_Report	;
        IF OBJECT_ID('#tmp_updt_MORBIDITY_REPORT_list', 'U') IS NOT NULL  DROP TABLE    	#tmp_updt_MORBIDITY_REPORT_list 	;
        IF OBJECT_ID('#tmp_SAS_updt_MORBIDITY_REPORT_list', 'U') IS NOT NULL  DROP TABLE    	#tmp_SAS_updt_MORBIDITY_REPORT_list 	;
        IF OBJECT_ID('#tmp_updt_MORBIDITY_REPORT_Event_list', 'U') IS NOT NULL  DROP TABLE    	#tmp_updt_MORBIDITY_REPORT_Event_list 	;
        IF OBJECT_ID('#tmp_SAS_up_MORBIDITY_RPT_EVNT_lst', 'U') IS NOT NULL  DROP TABLE    	#tmp_SAS_up_MORBIDITY_RPT_EVNT_lst 	;
        IF OBJECT_ID('#tmp_UPDT_MORB_RPT_USER_COMMENT_LIST', 'U') IS NOT NULL  DROP TABLE    	#tmp_UPDT_MORB_RPT_USER_COMMENT_LIST 	;
        IF OBJECT_ID('#tmp_Morb_Root', 'U') IS NOT NULL  DROP TABLE    	#tmp_Morb_Root 	;
        IF OBJECT_ID('#tmp_MorbFrmQ', 'U') IS NOT NULL  DROP TABLE    	#tmp_MorbFrmQ 	;
        IF OBJECT_ID('#tmp_MorbFrmQCoded', 'U') IS NOT NULL  DROP TABLE    	#tmp_MorbFrmQCoded 	;
        IF OBJECT_ID('#tmp_MorbFrmQDate', 'U') IS NOT NULL  DROP TABLE    	#tmp_MorbFrmQDate 	;
        IF OBJECT_ID('#tmp_MorbFrmQTxt', 'U') IS NOT NULL  DROP TABLE    	#tmp_MorbFrmQTxt 	;
        IF OBJECT_ID('##tmp_MorbFrmQCoded2', 'U') IS NOT NULL  DROP TABLE    	##tmp_MorbFrmQCoded2 	;
        IF OBJECT_ID('##tmp_MorbFrmQDate2', 'U') IS NOT NULL  DROP TABLE    	##tmp_MorbFrmQDate2 	;
        IF OBJECT_ID('##tmp_MorbFrmQTxt2', 'U') IS NOT NULL  DROP TABLE    	##tmp_MorbFrmQTxt2	;
        IF OBJECT_ID('#tmp_Morbidity_Report', 'U') IS NOT NULL  DROP TABLE    	#tmp_Morbidity_Report	;
        IF OBJECT_ID('#tmp_SAS_Morbidity_Report', 'U') IS NOT NULL  DROP TABLE    	#tmp_SAS_Morbidity_Report	;
        IF OBJECT_ID('#SAS_morb_Rpt_User_Comment', 'U') IS NOT NULL  DROP TABLE    	#SAS_morb_Rpt_User_Comment	;
        IF OBJECT_ID('#tmp_morb_Rpt_User_Comment', 'U') IS NOT NULL  DROP TABLE    	#tmp_morb_Rpt_User_Comment	;
        IF OBJECT_ID('#tmp_MORBIDITY_REPORT_Event_Final', 'U') IS NOT NULL  DROP TABLE    	#tmp_MORBIDITY_REPORT_Event_Final	;

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
