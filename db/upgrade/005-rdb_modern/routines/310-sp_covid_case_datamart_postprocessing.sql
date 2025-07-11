IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_covid_case_datamart_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_covid_case_datamart_postprocessing]
END
GO 

CREATE PROCEDURE dbo.sp_covid_case_datamart_postprocessing(
    @phc_uids NVARCHAR(MAX),
    @debug bit = 'false')
    as

BEGIN
    /*
    * [Description]
    * This stored procedure is builds the covid_case_datamart
    * 1. It builds 3 primary tmp tables -
        one for case related information,
        another for patient and
        last one for provider & org information
    * 2. It then builds case answer table for type 1 questions (discrete)
            i.e, question_group_seq_nbr IS NULL and nbs_ui_component_uid NOT IN(1013, 1025)
    * 3. It then builds case answer table for type 2 questions (multi string)
            i.e, question_group_seq_nbr IS NULL and nbs_ui_component_uid IN(1013, 1025)
    * 4. It then builds 3 case answer tables for type 3 questions (multi-select)
            i.e, question_group_seq_nbr IS NOT NULL and nbs_ui_component_uid NOT IN(1013, 1025)
            This appears to be like a limitation if the multi select is more than 3 but this mart will capture only 3.
    * 5. Final step joins all the data together to insert into the datamart
    */
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    
    DECLARE @conditionCd VARCHAR(200);
    SET @conditionCd = '11065'; -- COVID-19
  	
    DECLARE @Dataflow_Name VARCHAR(200) = 'COVID DATAMART Post-Processing Event';
    DECLARE @Package_Name VARCHAR(200) = 'sp_covid_case_datamart_postprocessing';

    DECLARE @inv_form_cd VARCHAR(100);
    SET @inv_form_cd = (select investigation_form_cd from dbo.nrt_srte_CONDITION_CODE cDim where
              condition_cd = @conditionCd);

BEGIN TRY

    SET @Proc_Step_no = 1;
    SET @Proc_Step_Name = 'SP_Start';
    DECLARE @batch_id bigint;
    SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmssffff')) AS bigint);
	DECLARE @tmp_COVID_CASE_DISCRETE_DATA varchar(150)= '##tmp_COVID_CASE_DISCRETE_DATA_' + CAST(@batch_id AS varchar(50));
    DECLARE @tmp_COVID_CASE_MULTI_DATA varchar(150)= '##tmp_COVID_CASE_MULTI_DATA_' + CAST(@batch_id AS varchar(50));
    DECLARE @tmp_COVID_CASE_RPT_DATA_1 varchar(150)= '##tmp_COVID_CASE_RPT_DATA_1_' + CAST(@batch_id AS varchar(50));
    DECLARE @tmp_COVID_CASE_RPT_DATA_2 varchar(150)= '##tmp_COVID_CASE_RPT_DATA_2_' + CAST(@batch_id AS varchar(50));
    DECLARE @tmp_COVID_CASE_RPT_DATA_3 varchar(150)= '##tmp_COVID_CASE_RPT_DATA_3_' + CAST(@batch_id AS varchar(50));
    if
        @debug = 'true'
    select @batch_id;


    SELECT @ROWCOUNT_NO = 0;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT] , [Msg_Description1])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO, LEFT('ID List-' + @phc_uids, 500));

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' GENERATING #PHC_LIST';

    --Step 1: Create #PHC_LIST
    select nrtInv.public_health_case_uid, nrtInv.record_status_cd
    into #PHC_LIST
    from dbo.NRT_INVESTIGATION nrtInv
    inner join (SELECT value FROM STRING_SPLIT(@phc_uids, ',')) phcList
    on nrtInv.public_health_case_uid = phcList.value and nrtInv.cd = @conditionCd;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from #PHC_LIST;

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' DELETING FROM COVID_CASE_DATAMART';

    --Step 2: Delete records from COVID_CASE_DATAMART where PHC data is going to be inserted
	DELETE FROM dbo.COVID_CASE_DATAMART
	WHERE public_health_case_uid IN (SELECT public_health_case_uid FROM #PHC_LIST);

    --Step 3.1: Delete records from COVID_CASE_DATAMART where PHC is LOG_DEL
    -- this is already deleted from datamart in prior step
    DELETE FROM #PHC_LIST
    WHERE record_status_cd = 'LOG_DEL';

    -- Step 3.2: Check if there are no rows in #PHC_LIST
    IF NOT EXISTS (SELECT 1 FROM #PHC_LIST)
    BEGIN
        if @debug='true'
            PRINT 'No rows found in #TempTable. Exiting procedure.';
        RETURN;
    END

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' GENERATING #COVID_CASE_CORE_DATA';

    --Step 4: Create #COVID_CASE_CORE_DATA
    SELECT
        phc.public_health_case_uid,
        phc.public_health_case_uid AS COVID_CASE_DATAMART_KEY,
        phc.LOCAL_ID AS 'INV_LOCAL_ID',
        phc.ADD_TIME,
        phc.LAST_CHG_TIME,
        phc.CD AS 'CONDITION_CD',
        noti.NOTIF_ADD_TIME AS 'NOTIFICATION_SUBMIT_DT',
        noti.RPT_SENT_TIME AS 'NOTIFICATION_SENT_DT',
        noti.NOTIF_LOCAL_ID AS 'NOTIFICATION_LOCAL_ID',
        phc.JURISDICTION_CD AS 'JURISDICTION_CD',
        jcode.CODE_DESC_TXT AS 'JURISDICTION_NM',
        phc.PROG_AREA_CD AS 'PROGRAM_AREA_CD',
        phc.ACTIVITY_FROM_TIME AS 'INV_START_DT',
        phc.INVESTIGATION_STATUS_CD AS 'INVESTIGATION_STATUS_CD',
        phc.INV_STATE_CASE_ID AS 'INV_STATE_CASE_ID',
        phc.LEGACY_CASE_ID AS 'INV_LEGACY_CASE_ID',
        phc.INVESTIGATOR_ASSIGNED_TIME AS 'INV_ASSIGNED_DT',
        phc.RPT_FORM_CMPLT_TIME AS 'INV_RPT_DT',
        phc.RPT_TO_COUNTY_TIME AS 'EARLIEST_RPT_TO_CNTY_DT',
        phc.RPT_TO_STATE_TIME AS 'EARLIEST_RPT_TO_ST_DT',
        phc.RPT_SOURCE_CD AS 'RPT_SOURCE_CD',
        phc.HOSPITALIZED_IND_CD AS 'HSPTLIZD_IND',
        phc.HOSPITALIZED_ADMIN_TIME AS 'HSPTL_ADMISSION_DT',
        phc.HOSPITALIZED_DISCHARGE_TIME AS 'HSPTL_DISCHARGE_DT',
        phc.HOSPITALIZED_DURATION_AMT AS 'HSPTL_DURATION_DAYS',
        phc.DIAGNOSIS_TIME AS 'DIAGNOSIS_DT',
        phc.EFFECTIVE_FROM_TIME AS 'ILLNESS_ONSET_DT',
        phc.EFFECTIVE_TO_TIME AS 'ILLNESS_END_DT',
        phc.EFFECTIVE_DURATION_AMT AS 'ILLNESS_DURATION',
        phc.EFFECTIVE_DURATION_UNIT_CD AS 'ILLNESS_DURATION_UNIT',
        phc.PAT_AGE_AT_ONSET AS 'PATIENT_ONSET_AGE',
        phc.PAT_AGE_AT_ONSET_UNIT_CD AS 'PATIENT_ONSET_AGE_UNIT',
        phc.PREGNANT_IND_CD AS 'PATIENT_PREGNANT_IND',
        phc.OUTCOME_CD AS 'DIE_FROM_ILLNESS_IND',
        phc.DECEASED_TIME AS 'INV_DEATH_DT',
        phc.DAY_CARE_IND_CD AS 'DAYCARE_ASSOC_IND',
        phc.FOOD_HANDLER_IND_CD AS 'FOOD_HANDLER_IND',
        phc.OUTBREAK_IND AS 'OUTBREAK_IND',
        phc.OUTBREAK_NAME AS 'OUTBREAK_NAME',
        phc.DISEASE_IMPORTED_CD AS 'DISEASE_IMPORTED_IND',
        phc.IMPORTED_COUNTRY_CD AS 'IMPORT_FROM_CNTRY',
        phc.IMPORTED_STATE_CD AS 'IMPORT_FROM_STATE',
        phc.IMPORTED_CITY_DESC_TXT AS 'IMPORT_FROM_CITY',
        phc.IMPORTED_COUNTY_CD AS 'IMPORT_FROM_CNTY',
        phc.TRANSMISSION_MODE_CD AS 'TRANSMISSION_MODE_CD',
        phc.DETECTION_METHOD_CD AS 'DETECT_METHOD_CD',
        phc.CASE_CLASS_CD AS 'INV_CASE_STATUS',
        phc.MMWR_WEEK AS 'CASE_RPT_MMWR_WK',
        phc.MMWR_YEAR AS 'CASE_RPT_MMWR_YR',
        replace(phc.TXT, CHAR(13) + CHAR(10), ' ') AS 'INV_COMMENTS',
        phc.INV_PRIORITY_CD AS 'CTT_INV_PRIORITY_CD',
        phc.INFECTIOUS_FROM_DATE AS 'CTT_INFECTIOUS_FROM_DT',
        phc.INFECTIOUS_TO_DATE AS 'CTT_INFECTIOUS_TO_DT',
        phc.CONTACT_INV_STATUS AS 'CTT_INV_STATUS',
        replace(phc.CONTACT_INV_TXT, CHAR(13) + CHAR(10), ' ') AS 'CTT_INV_COMMENTS',
        confMethod.CONFIRMATION_METHOD,
        confMethod.CONFIRMATION_DT,
        phc.notes AS 'NOTES'
    INTO #COVID_CASE_CORE_DATA
    from
        #PHC_LIST phc_list
    inner join
        dbo.NRT_INVESTIGATION phc WITH(NOLOCK) ON phc.public_health_case_uid = phc_list.public_health_case_uid
    LEFT OUTER JOIN
    (
        SELECT 
            cm.Public_health_case_uid,
            STRING_AGG(cvg.code_short_desc_txt, '; ') AS CONFIRMATION_METHOD,
            MAX(cm.confirmation_method_time) AS CONFIRMATION_DT
        FROM dbo.NRT_INVESTIGATION_CONFIRMATION cm WITH(NOLOCK)
		INNER JOIN #PHC_LIST l 
			ON l.public_health_case_uid = cm.Public_health_case_uid
		LEFT JOIN dbo.NRT_SRTE_CODE_VALUE_GENERAL cvg WITH(NOLOCK)
			ON cm.confirmation_method_cd = cvg.code AND cvg.code_set_nm = 'PHC_CONF_M'
        GROUP BY cm.Public_health_case_uid
    ) confMethod
        ON confMethod.public_health_case_uid = phc.public_health_case_uid
    left outer join
        dbo.V_GETOBSCODE obscode ON obscode.public_health_case_uid = phc.public_health_case_uid
    left outer join
        dbo.NRT_INVESTIGATION_NOTIFICATION noti on noti.public_health_case_uid = phc.public_health_case_uid
    left outer join
        dbo.NRT_SRTE_JURISDICTION_CODE jcode ON phc.JURISDICTION_CD = jcode.code
    WHERE phc.record_status_cd = 'ACTIVE';


    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from #COVID_CASE_CORE_DATA;
--------------------------------------------------------------------------------------------------------------------------------------------------



    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' DELETING FROM COVID_PATIENT_DATA';

    --Step 5: Create #COVID_PATIENT_DATA
    SELECT
        inv.public_health_case_uid AS 'PAT_CASE_UID',
        pat.PATIENT_LOCAL_ID as 'PATIENT_LOCAL_ID',
        replace(pat.PATIENT_GENERAL_COMMENTS, CHAR(13) + CHAR(10), ' ') AS 'PATIENT_GEN_COMMENTS',
        pat.PATIENT_FIRST_NAME AS 'PATIENT_FIRST_NAME',
        pat.PATIENT_MIDDLE_NAME AS 'PATIENT_MIDDLE_NAME',
        pat.PATIENT_LAST_NAME AS 'PATIENT_LAST_NAME',
        cast(pat.PATIENT_NAME_SUFFIX as varchar(20)) AS 'PATIENT_NAME_SUFFIX',
        pat.PATIENT_DOB AS 'PATIENT_DOB',
        cast(pat.PATIENT_AGE_REPORTED as varchar(10)) AS 'PATIENT_AGE_REPORTED',
        pat.PATIENT_AGE_REPORTED_UNIT AS 'PATIENT_AGE_RPTD_UNIT',
        cast(pat.PATIENT_BIRTH_COUNTRY as varchar(20)) AS 'PATIENT_BIRTH_COUNTRY',
        cast(pat.PATIENT_CURRENT_SEX as varchar(1)) AS 'PATIENT_CURRENT_SEX',
        cast(pat.PATIENT_DECEASED_INDICATOR as varchar(20)) AS 'PATIENT_DECEASED_IND',
        pat.PATIENT_DECEASED_DATE AS 'PATIENT_DECEASED_DT',
        pat.PATIENT_MARITAL_STATUS AS 'PATIENT_MARITAL_STS',
        pat.PATIENT_STREET_ADDRESS_1 AS 'PATIENT_STREET_ADDR_1',
        pat.PATIENT_STREET_ADDRESS_2 AS 'PATIENT_STREET_ADDR_2',
        pat.PATIENT_CITY AS 'PATIENT_CITY',
        cast(pat.PATIENT_STATE as varchar(20)) AS 'PATIENT_STATE',
        cast(pat.PATIENT_ZIP as varchar(20)) AS 'PATIENT_ZIP',
        pat.PATIENT_COUNTY AS 'PATIENT_COUNTY',
        cast(pat.PATIENT_COUNTRY as varchar(20)) AS 'PATIENT_COUNTRY',
        cast(pat.PATIENT_PHONE_HOME as varchar(20)) AS 'PATIENT_TEL_HOME',
        cast(pat.PATIENT_PHONE_WORK as varchar(20)) AS 'PATIENT_PHONE_WORK',
        cast(pat.PATIENT_PHONE_EXT_WORK as varchar(20)) AS 'PATIENT_PHONE_EXT_WORK',
        cast(pat.PATIENT_PHONE_CELL as varchar(20)) AS 'PATIENT_TEL_CELL',
        pat.PATIENT_EMAIL AS 'PATIENT_EMAIL',
        cast(pat.PATIENT_ETHNICITY as varchar(20)) AS 'PATIENT_ETHNICITY',
        pat.PATIENT_RACE_CALCULATED AS 'PATIENT_RACE_CALC'
    INTO
        #COVID_PATIENT_DATA
    FROM
        dbo.NRT_INVESTIGATION inv
    inner join
        #PHC_LIST phc_list on inv.public_health_case_uid = phc_list.public_health_case_uid
    left outer join
    (
        select dPat.*
        from dbo.D_PATIENT dPat WITH(NOLOCK)
    	inner join  dbo.NRT_PATIENT nrtPat WITH(NOLOCK)
    		on nrtPat.patient_uid = dPat.patient_uid
    		and nrtPat.status_name_cd  = 'A' and nrtPat.nm_use_cd = 'L'
    ) pat
    ON inv.patient_id = pat.patient_uid ;


    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from #COVID_PATIENT_DATA;
--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' CREATING #COVID_ENTITIES_DATA';

    --Step 6: Create #COVID_ENTITIES_DATA
    with UID_CTE as (
        select
            nrtinv.public_health_case_uid as public_health_case_uid,
            nrtinv.investigator_id as INVESTIGATOR_UID,
            nrtinv.person_as_reporter_uid as PERSON_AS_REPORTER_UID,
            nrtinv.patient_id as PATIENT_UID,
            nrtinv.physician_id as PHYSICIAN_UID,
            nrtinv.hospital_uid as HOSPITAL_UID,
            nrtinv.organization_id as ORG_AS_REPORTER_UID,
            nrtinv.ordering_facility_uid as ORDERING_FACILTY_UID
        from #PHC_LIST phc_list
        inner join
        	dbo.NRT_INVESTIGATION nrtinv
            	on phc_list.public_health_case_uid = nrtinv.public_health_case_uid
    )
    SELECT
        cte.public_health_case_uid AS 'ENTITY_CASE_UID',
        hospital.ORGANIZATION_NAME AS 'HOSPITAL_NAME',
        investigator.PROVIDER_LAST_NAME AS 'PHC_INV_LAST_NAME',
        investigator.PROVIDER_FIRST_NAME AS 'PHC_INV_FIRST_NAME',
        physician.PROVIDER_LAST_NAME AS 'PHYS_LAST_NAME',
        physician.PROVIDER_FIRST_NAME AS 'PHYS_FIRST_NAME',
        physician.PROVIDER_PHONE_WORK AS 'PHYS_TEL_WORK',
        physician.PROVIDER_PHONE_EXT_WORK AS 'PHYS_TEL_EXT_WORK',
        reporter.PROVIDER_LAST_NAME AS 'RPT_PRV_LAST_NAME',
        reporter.PROVIDER_FIRST_NAME AS 'RPT_PRV_FIRST_NAME',
        reporter.PROVIDER_PHONE_WORK AS 'RPT_PRV_TEL_WORK',
        reporter.PROVIDER_PHONE_EXT_WORK AS 'RPT_PRV_TEL_EXT_WORK',
        reporterOrg.ORGANIZATION_NAME AS 'RPT_ORG_NAME',
        reporterOrg.ORGANIZATION_PHONE_WORK AS 'RPT_ORG_TEL_WORK',
        reporterOrg.ORGANIZATION_PHONE_EXT_WORK AS 'RPT_ORG_TEL_EXT_WORK'
    INTO #COVID_ENTITIES_DATA
    FROM UID_CTE  cte
    left outer join dbo.D_PATIENT PATIENT WITH (NOLOCK) ON cte.PATIENT_UID= PATIENT.PATIENT_UID
    left outer join dbo.D_ORGANIZATION  HOSPITAL WITH (NOLOCK) ON cte.HOSPITAL_UID= HOSPITAL.ORGANIZATION_UID
    left outer join dbo.D_ORGANIZATION reporterOrg WITH (NOLOCK) ON cte.ORG_AS_REPORTER_UID= reporterOrg.ORGANIZATION_UID
    left outer join dbo.D_PROVIDER reporter WITH (NOLOCK) ON cte.PERSON_AS_REPORTER_UID= reporter.PROVIDER_UID
    left outer join dbo.D_PROVIDER investigator WITH (NOLOCK) ON cte.INVESTIGATOR_UID= investigator.PROVIDER_UID
    left outer join dbo.D_PROVIDER physician WITH (NOLOCK) ON cte.PHYSICIAN_UID= physician.PROVIDER_UID
    left outer join dbo.INVESTIGATION  INVESTIGATION WITH (NOLOCK) ON cte.public_health_case_uid= INVESTIGATION.CASE_UID
    ;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from #COVID_ENTITIES_DATA;

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Create and Run ALTER TABLE statements COVID_CASE_DATAMART for discrete data';


    DECLARE @column_name VARCHAR(200);
    DECLARE @Count INT;
    DECLARE @Max INT;

    --Step 7: Create and Run ALTER TABLE statements for COVID_CASE_DATAMART
    DECLARE @Table TABLE
    (
        ID          INT IDENTITY(1, 1),
        COLUMN_NAME VARCHAR(200)
    );

    INSERT INTO @Table
    SELECT [user_defined_column_nm]
    FROM
        dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta WITH(NOLOCK)
    inner join
        dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
            ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                AND question_group_seq_nbr IS NULL
                AND nbs_ui_component_uid NOT IN(1013, 1025)
                AND data_location LIKE '%Answer_txt'
                AND user_defined_column_nm IS NOT NULL
                AND uiMeta.investigation_form_cd = @inv_form_cd
    EXCEPT
    SELECT COLUMN_NAME
    FROM
        INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'COVID_CASE_DATAMART';


    SET @Count =
    (
        SELECT MAX(ID)
        FROM @Table t
    );
    SET @Max = 0;
    WHILE @Count > @Max
        BEGIN
            SET @Max = @Max + 1;
            SET @column_name =
            (
                SELECT COLUMN_NAME
                FROM @Table t
                WHERE ID = @Max
            );
            if
            @debug = 'true'
                PRINT('ALTER TABLE COVID_CASE_DATAMART ADD ' + @column_name) + ' varchar(2000)';
            EXEC ('ALTER TABLE COVID_CASE_DATAMART ADD '+@column_name+' varchar(2000)');
        END;


    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from @Table;
--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Construct '+@tmp_COVID_CASE_DISCRETE_DATA;


     IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_DISCRETE_DATA, 'U') IS NOT NULL
            exec ('drop table '+@tmp_COVID_CASE_DISCRETE_DATA);

    --Step 8: Construct COVID_CASE_DISCRETE_DATA
    DECLARE @columns NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);
    SET @columns = N'';
    SELECT @columns+=N', rdbMeta.' + QUOTENAME(LTRIM(RTRIM([user_defined_column_nm])))
    FROM
    (
        SELECT [user_defined_column_nm]
        FROM
            dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta WITH(NOLOCK)
        inner join
            dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
                ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                AND question_group_seq_nbr IS NULL
                AND nbs_ui_component_uid NOT IN(1013, 1025)
                AND data_location LIKE '%Answer_txt'
                AND user_defined_column_nm IS NOT NULL
                AND uiMeta.investigation_form_cd = @inv_form_cd
    ) AS x;

    if
    @debug = 'true'
        PRINT @columns;

    SET @sql = N'SELECT [ACT_UID] as ACT_DISCRETE_UID , ' + STUFF(@columns, 1, 2, '')
            + ' into '+ @tmp_COVID_CASE_DISCRETE_DATA+ ' FROM (
                    SELECT [ACT_UID],
                        replace(ISNULL(CAST(code_short_desc_txt AS VARCHAR(2000)), answer_txt ), CHAR(13) + CHAR(10), '' '') as answer_txt ,
                        [user_defined_column_nm]
                        from
                            dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta with (nolock)
                        inner join
                            dbo.NRT_ODSE_NBS_UI_METADATA uiMeta with (nolock) on uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                                and question_group_seq_nbr is null and nbs_ui_component_uid not in (1013,1025)
                                and data_location like ''%ANSWER_TXT''
                                AND user_defined_column_nm is not null
                                AND uiMeta.investigation_form_cd = '''+ @inv_form_cd + '''
                        left outer join
                            dbo.NRT_PAGE_CASE_ANSWER caseAns with (nolock) on caseAns.nbs_question_uid = uiMeta.nbs_question_uid
                        inner join
                            #COVID_CASE_CORE_DATA phc on phc.public_health_case_uid = caseAns.act_uid
                        LEFT OUTER JOIN
                            dbo.NRT_SRTE_CODESET codeset ON codeset.code_set_group_id = uiMeta.code_set_group_id
                        LEFT OUTER JOIN
                            dbo.NRT_SRTE_CODE_VALUE_GENERAL cvg ON cvg.code_set_nm = codeset.code_set_nm
                                AND cvg.code = caseAns.answer_txt
                        group by [ACT_UID], [answer_txt] , [user_defined_column_nm],code_short_desc_txt
                    ) AS j PIVOT (max(answer_txt) FOR [user_defined_column_nm] in
                (' + STUFF(REPLACE(@columns, ', rdbMeta.[', ',['), 1, 1, '') + ')) AS rdbMeta;';

    if @debug='true'
	    select @sql as COVID_CASE_DISCRETE_DATA_SCRIPT;
    EXEC sp_executesql @sql;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        exec('select  '''+@Proc_Step_Name+''' as step, * from '+@tmp_COVID_CASE_DISCRETE_DATA);

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Construct #COVID_CASE_MULTI_ANS_DATA';


    --Step 9: Construct COVID_CASE_MULTI_ANS_DATA
    SELECT DISTINCT
        act_uid,
        caseAns.nbs_question_uid,
        ISNULL(code_short_desc_txt, answer_txt) AS answer_txt,
        seq_nbr
    INTO
        #COVID_CASE_MULTI_ANS_DATA
    FROM
        #COVID_CASE_CORE_DATA caseData
        inner join
            dbo.condition cDim WITH(NOLOCK)
                ON cDim.condition_cd = caseData.condition_cd
        inner join
            dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
                ON cDim.disease_grp_cd = uiMeta.investigation_form_cd
                    AND nbs_ui_component_uid IN(1013, 1025)
        LEFT OUTER JOIN
            dbo.NRT_PAGE_CASE_ANSWER caseAns WITH(NOLOCK)
                ON uiMeta.nbs_question_uid = caseAns.nbs_question_uid
                    AND caseAns.act_uid = caseData.public_health_case_uid
                    AND caseAns.seq_nbr IS NOT NULL
        LEFT OUTER JOIN
            dbo.NRT_SRTE_CODESET codeset WITH(NOLOCK)
                ON codeset.code_set_group_id = uiMeta.code_set_group_id
        LEFT OUTER JOIN
            dbo.NRT_SRTE_CODE_VALUE_GENERAL cvg WITH(NOLOCK)
                ON codeset.code_set_nm = cvg.code_set_nm
                    AND answer_txt = cvg.code
    WHERE cDim.condition_cd = '11065'
    ORDER BY act_uid,
            nbs_question_uid,
            seq_nbr;

    SELECT
        b.act_uid,
        b.nbs_question_uid,
        LTRIM(STUFF(
        (
            SELECT ' | ' + a.answer_txt
            FROM
                #COVID_CASE_MULTI_ANS_DATA a
            WHERE
                a.act_uid = b.act_uid
                    AND a.nbs_question_uid = b.nbs_question_uid FOR XML PATH(''), TYPE
        ).value('.', 'VARCHAR(MAX)'), 1, 2, '')) AS answer_txt
    INTO
        #COVID_CASE_MULTI_ANS_MULTI_DATA
    FROM
        #COVID_CASE_MULTI_ANS_DATA b
    GROUP BY act_uid, nbs_question_uid;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from #COVID_CASE_MULTI_ANS_MULTI_DATA;
--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Create and Run ALTER TABLE statements COVID_CASE_DATAMART for multi-string data';

    --Step 10: Create and Run ALTER TABLE statements for COVID_CASE_DATAMART
    DECLARE @Table2 TABLE
    (ID         INT IDENTITY(1, 1),
    COLUMN_NAME VARCHAR(200)
    );

    INSERT INTO @Table2
    SELECT [user_defined_column_nm]
    FROM
        dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta
    inner join
        dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
        ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
            AND question_group_seq_nbr IS NULL
            AND nbs_ui_component_uid IN (1013, 1025)
            AND data_location LIKE '%Answer_txt'
            AND user_defined_column_nm IS NOT NULL
    inner join
        dbo.condition cDim WITH(NOLOCK)
        ON cDim.disease_grp_cd = uiMeta.investigation_form_cd
            AND cDim.condition_cd = '11065'
    EXCEPT
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'COVID_CASE_DATAMART';

    SET @Count =
    (
        SELECT MAX(ID)
        FROM @Table2 t
    );
    SET @Max = 0;
    WHILE @Count > @Max
        BEGIN
            SET @Max = @Max + 1;
            SET @column_name =
            (
                SELECT COLUMN_NAME
                FROM @Table2 t
                WHERE ID = @Max
            );
            if
            @debug = 'true'
                PRINT('ALTER TABLE COVID_CASE_DATAMART ADD ' + @column_name) + ' varchar(8000)';
            EXEC ('ALTER TABLE COVID_CASE_DATAMART ADD '+@column_name+' varchar(8000)');
        END;


    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from @Table2;
--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Construct '+@tmp_COVID_CASE_MULTI_DATA;

	IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_MULTI_DATA, 'U') IS NOT NULL
        exec ('drop table '+@tmp_COVID_CASE_MULTI_DATA);

    SET @columns = N'';
    SELECT @columns+=N', rdbMeta.' + QUOTENAME(LTRIM(RTRIM([user_defined_column_nm])))
    FROM
    (
        SELECT [user_defined_column_nm]
        FROM
            dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta
        inner join
            dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
                ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                    AND question_group_seq_nbr IS NULL
                    AND nbs_ui_component_uid IN (1013, 1025)
                    AND data_location LIKE '%Answer_txt'
                    AND user_defined_column_nm IS NOT NULL
                    AND uiMeta.investigation_form_cd = @inv_form_cd
    ) AS x;

    if
    @debug ='true'
        PRINT @columns;


    SET @sql = N'SELECT [ACT_UID] as ACT_MULTI_UID, ' + STUFF(@columns, 1, 2, '')
        + ' into ' + @tmp_COVID_CASE_MULTI_DATA + ' FROM
        (
            SELECT [ACT_UID],
                    multiAnsData.[answer_txt],
                    [user_defined_column_nm]
            FROM
                #COVID_CASE_MULTI_ANS_MULTI_DATA multiAnsData
            inner join
            (
                SELECT NBS_QUESTION_UID, user_defined_column_nm
                FROM
                    dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta with (nolock)
                inner join
                    dbo.NRT_ODSE_NBS_UI_METADATA uiMeta with (nolock)
                        ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                            AND question_group_seq_nbr IS NULL
                            AND nbs_ui_component_uid IN(1013, 1025)
                            AND data_location like ''%Answer_txt''
                            AND user_defined_column_nm is not null
                            AND uiMeta.investigation_form_cd = '''+ @inv_form_cd + '''
                ) AS RDB_METADATA
                    ON multiAnsData.nbs_question_uid = RDB_METADATA.nbs_question_uid
                GROUP BY act_uid,
                    multiAnsData.nbs_question_uid,
                    answer_txt, user_defined_column_nm
            ) AS j PIVOT (max(answer_txt) FOR [user_defined_column_nm] in
                            (' + STUFF(REPLACE(@columns, ', rdbMeta.[', ',['), 1, 1, '') + ')) AS rdbMeta;';
    if @debug='true'
	    select @sql as COVID_CASE_MULTI_DATA_SCRIPT;
    EXEC sp_executesql @sql;


    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
    	exec('select  '''+@Proc_Step_Name+'''  as step,* from '+@tmp_COVID_CASE_MULTI_DATA);

--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Create and Run ALTER TABLE statements COVID_CASE_DATAMART for multi-answer data (1)';

    DECLARE @Table3 TABLE
    (
        ID          INT IDENTITY(1, 1),
        COLUMN_NAME VARCHAR(200)
    );

    INSERT INTO @Table3
    SELECT [user_defined_column_nm] + '_1' AS user_defined_column_nm
    FROM
        dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta WITH(NOLOCK)
    inner join
        dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
            ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                AND question_group_seq_nbr IS NOT NULL
                AND nbs_ui_component_uid NOT IN(1013, 1025)
                AND data_location LIKE '%Answer_txt'
                AND user_defined_column_nm IS NOT NULL
                AND uiMeta.investigation_form_cd = @inv_form_cd
    EXCEPT
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'COVID_CASE_DATAMART';


    SET @Count =
    (
        SELECT MAX(ID)
        FROM @Table3 t
    );
    SET @Max = 0;
    WHILE @Count > @Max
        BEGIN
            SET @Max = @Max + 1;
            SET @column_name =
            (
                SELECT COLUMN_NAME
                FROM @Table3 t
                WHERE ID = @Max
            );
            if
            @debug = 'true'
                PRINT('ALTER TABLE COVID_CASE_DATAMART ADD ' + @column_name) + ' varchar(2000)';
            EXEC ('ALTER TABLE COVID_CASE_DATAMART ADD '+@column_name+' varchar(2000)');
        END;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from @Table3;
--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Construct '+@tmp_COVID_CASE_RPT_DATA_1;

    IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_RPT_DATA_1, 'U') IS NOT NULL
        exec ('drop table '+@tmp_COVID_CASE_RPT_DATA_1);

    DECLARE @columns1 NVARCHAR(MAX);
    SET @columns1 = N'';
    SELECT @columns1+=N', rdbMeta.' + QUOTENAME(LTRIM(RTRIM([user_defined_column_nm])))
    FROM
    (
        SELECT [user_defined_column_nm] + '_1' AS user_defined_column_nm
        FROM
            dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta WITH(NOLOCK)
        inner join
            dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
                ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                    AND question_group_seq_nbr IS NOT NULL
                    AND nbs_ui_component_uid NOT IN(1013, 1025)
                    AND data_location LIKE '%Answer_txt'
                    AND user_defined_column_nm IS NOT NULL
                    AND uiMeta.investigation_form_cd = @inv_form_cd
    ) AS x;

    if
    @debug = 'true'
        PRINT @columns1;

    SET @sql = N'SELECT [ACT_UID] as ACT_RPT_1_UID , ' + STUFF(@columns1, 1, 2, '')
            + ' into '+@tmp_COVID_CASE_RPT_DATA_1+ ' FROM (
                SELECT [ACT_UID], replace(ISNULL(CAST(code_short_desc_txt AS VARCHAR(2000)), CAST(answer_txt AS VARCHAR(2000) )), CHAR(13) + CHAR(10), '' '') as answer_txt , user_defined_column_nm' + '+''_1'' as user_defined_column_nm
                FROM
                    dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta with (nolock)
                inner join
                    dbo.NRT_ODSE_NBS_UI_METADATA uiMeta with (nolock)
                        on uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                            and question_group_seq_nbr is not null and nbs_ui_component_uid not in (1013,1025)
                            and data_location like ''%ANSWER_TXT''
                            and user_defined_column_nm is not null
                            and uiMeta.investigation_form_cd = '''+ @inv_form_cd + '''
                left outer join
                    dbo.NRT_PAGE_CASE_ANSWER caseAns with (nolock)
                        on caseAns.nbs_question_uid = uiMeta.nbs_question_uid and caseAns.answer_group_seq_nbr=1
                inner join
                    #COVID_CASE_CORE_DATA phc
                        on phc.public_health_case_uid = caseAns.act_uid
                left outer join
                    dbo.NRT_SRTE_CODESET codeset
                        ON codeset.code_set_group_id = uiMeta.code_set_group_id
                left outer join
                    dbo.NRT_SRTE_CODE_VALUE_GENERAL cvg ON cvg.code_set_nm = codeset.code_set_nm
                                                                                AND cvg.code = caseAns.answer_txt
                group by [ACT_UID], [answer_txt] , [user_defined_column_nm],code_short_desc_txt
                    ) AS j PIVOT (max(answer_txt) FOR [user_defined_column_nm] in
                (' + STUFF(REPLACE(@columns1, ', rdbMeta.[', ',['), 1, 1, '') + ')) AS rdbMeta;';

    if @debug='true'
	    select @sql as COVID_CASE_RPT_DATA_1_SCRIPT;
    EXEC sp_executesql @sql;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
         exec('select  '''+@Proc_Step_Name+'''  as step,* from '+@tmp_COVID_CASE_RPT_DATA_1);
--------------------------------------------------------------------------------------------------------------------------------------------------
    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Create and Run ALTER TABLE statements COVID_CASE_DATAMART for multi-answer data (2)';


    DECLARE @Table4 TABLE
    (
    ID          INT IDENTITY(1, 1),
    COLUMN_NAME VARCHAR(200)
    );

    INSERT INTO @Table4
    SELECT [user_defined_column_nm] + '_2' AS user_defined_column_nm
    FROM
        dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta WITH(NOLOCK)
    inner join
        dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
            ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                AND question_group_seq_nbr IS NOT NULL
                AND nbs_ui_component_uid NOT IN(1013, 1025)
                AND data_location LIKE '%Answer_txt'
                AND user_defined_column_nm IS NOT NULL
                AND uiMeta.investigation_form_cd = @inv_form_cd
    EXCEPT
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'COVID_CASE_DATAMART';


    SET @Count =
    (
        SELECT MAX(ID)
        FROM @Table4 t
    );
    SET @Max = 0;
    WHILE @Count > @Max
        BEGIN
            SET @Max = @Max + 1;
            SET @column_name =
            (
                SELECT COLUMN_NAME
                FROM @Table4 t
                WHERE ID = @Max
            );
            if
            @debug = 'true'
                PRINT('ALTER TABLE COVID_CASE_DATAMART ADD ' + @column_name) + ' varchar(2000)';
            EXEC ('ALTER TABLE COVID_CASE_DATAMART ADD '+@column_name+' varchar(2000)');
        END;


    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        select @Proc_Step_Name as step, *
        from @Table4;
--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Construct '+@tmp_COVID_CASE_RPT_DATA_2;

    IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_RPT_DATA_2, 'U') IS NOT NULL
        exec ('drop table '+@tmp_COVID_CASE_RPT_DATA_2);

    SET @columns1 = N'';
    SELECT @columns1+=N', rdbMeta.' + QUOTENAME(LTRIM(RTRIM([user_defined_column_nm])))
    FROM
    (
        SELECT [user_defined_column_nm] + '_2' AS user_defined_column_nm
        FROM
            dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta WITH(NOLOCK)
        inner join
        	dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
	            ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
	                AND question_group_seq_nbr IS NOT NULL
	                AND nbs_ui_component_uid NOT IN(1013, 1025)
	                AND data_location LIKE '%Answer_txt'
	                AND user_defined_column_nm IS NOT NULL
                    AND uiMeta.investigation_form_cd = @inv_form_cd
    ) AS x;

    if
    @debug = 'true'
        PRINT @columns1;

    SET @sql = N'SELECT [ACT_UID] as ACT_RPT_2_UID , ' + STUFF(@columns1, 1, 2, '')
    	+ ' into '+@tmp_COVID_CASE_RPT_DATA_2 + ' FROM (
            SELECT [ACT_UID], replace(ISNULL(CAST(code_short_desc_txt AS VARCHAR(2000)), CAST(answer_txt AS VARCHAR(2000) )), CHAR(13) + CHAR(10), '' '') as answer_txt , user_defined_column_nm' + '+''_2'' as user_defined_column_nm
            from
                dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta with (nolock)
            inner join
                dbo.NRT_ODSE_NBS_UI_METADATA uiMeta with (nolock)
                    on uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                        and question_group_seq_nbr is not null and nbs_ui_component_uid not in (1013,1025)
                        and data_location like ''%ANSWER_TXT''
                        AND user_defined_column_nm is not null
                        AND uiMeta.investigation_form_cd = '''+ @inv_form_cd + '''
            left outer join
                dbo.NRT_PAGE_CASE_ANSWER caseAns with (nolock)
                    on caseAns.nbs_question_uid = uiMeta.nbs_question_uid
                        and caseAns.answer_group_seq_nbr=2
            inner join
                #COVID_CASE_CORE_DATA phc with (nolock)
                    on phc.public_health_case_uid = caseAns.act_uid
            left outer join
                dbo.NRT_SRTE_CODESET codeset
                    ON codeset.code_set_group_id = uiMeta.code_set_group_id
            left outer join
                dbo.NRT_SRTE_CODE_VALUE_GENERAL cvg
                    ON cvg.code_set_nm = codeset.code_set_nm
                        AND cvg.code = caseAns.answer_txt
            group by [ACT_UID], [answer_txt] , [user_defined_column_nm],code_short_desc_txt
                ) AS j PIVOT (max(answer_txt) FOR [user_defined_column_nm] in
            (' + STUFF(REPLACE(@columns1, ', rdbMeta.[', ',['), 1, 1, '') + ')) AS rdbMeta;';

    if @debug='true'
	    select @sql as COVID_CASE_RPT_DATA_2_SCRIPT;
    EXEC sp_executesql @sql;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
        exec('select  '''+@Proc_Step_Name+'''  as step,* from '+@tmp_COVID_CASE_RPT_DATA_2);
--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Create and Run ALTER TABLE statements COVID_CASE_DATAMART for multi-answer data (3)';

    DECLARE @Table5 TABLE
    (
        ID          INT IDENTITY(1, 1),
        COLUMN_NAME VARCHAR(200)
    );

    insert into @Table5
    select [user_defined_column_nm] + '_3' AS user_defined_column_nm
    from
        dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta WITH(NOLOCK)
    inner join
        dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
            ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                AND question_group_seq_nbr IS NOT NULL
                AND nbs_ui_component_uid NOT IN(1013, 1025)
                AND data_location LIKE '%Answer_txt'
                AND user_defined_column_nm IS NOT NULL
                AND uiMeta.investigation_form_cd = @inv_form_cd
    EXCEPT
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'COVID_CASE_DATAMART';

    SET @Count =
    (
        SELECT MAX(ID)
        FROM @Table5 t
    );
    SET @Max = 0;
    WHILE @Count > @Max
        BEGIN
            SET @Max = @Max + 1;
            SET @column_name =
            (
                SELECT COLUMN_NAME
                FROM @Table5 t
                WHERE ID = @Max
            );
            if
            @debug = 'true'
                PRINT('ALTER TABLE COVID_CASE_DATAMART ADD ' + @column_name) + ' varchar(2000)';
            EXEC ('ALTER TABLE COVID_CASE_DATAMART ADD '+@column_name+' varchar(2000)');
        END;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
    select @Proc_Step_Name as step, *
    from @Table5;
--------------------------------------------------------------------------------------------------------------------------------------------------

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' Construct '+@tmp_COVID_CASE_RPT_DATA_3;

    IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_RPT_DATA_3, 'U') IS NOT NULL
        exec ('drop table '+@tmp_COVID_CASE_RPT_DATA_3);

    SET @columns1 = N'';
    SELECT @columns1+=N', rdbMeta.' + QUOTENAME(LTRIM(RTRIM([user_defined_column_nm])))
    FROM
    (
        SELECT [user_defined_column_nm] + '_3' AS user_defined_column_nm
        FROM
            dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta WITH(NOLOCK)
        inner join
            dbo.NRT_ODSE_NBS_UI_METADATA uiMeta WITH(NOLOCK)
                ON uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                    AND question_group_seq_nbr IS NOT NULL
                    AND nbs_ui_component_uid NOT IN(1013, 1025)
                    AND data_location LIKE '%Answer_txt'
                    AND user_defined_column_nm IS NOT NULL
                    AND uiMeta.investigation_form_cd = @inv_form_cd
    ) AS x;

    if
    @debug = 'true'
        PRINT @columns1;

    SET @sql = N'SELECT [ACT_UID] as ACT_RPT_3_UID , ' + STUFF(@columns1, 1, 2, '')
            + ' into '+@tmp_COVID_CASE_RPT_DATA_3 + ' FROM (
                SELECT [ACT_UID], replace(ISNULL(CAST(code_short_desc_txt AS VARCHAR(2000)), CAST(answer_txt AS VARCHAR(2000) )), CHAR(13) + CHAR(10), '' '') as answer_txt , user_defined_column_nm' + '+''_3'' as user_defined_column_nm
                from
                    dbo.NRT_ODSE_NBS_RDB_METADATA rdbMeta with (nolock)
                inner join
                    dbo.NRT_ODSE_NBS_UI_METADATA uiMeta with (nolock)
                        on uiMeta.nbs_ui_metadata_uid = rdbMeta.nbs_ui_metadata_uid
                            and question_group_seq_nbr is not null and nbs_ui_component_uid not in (1013,1025)
                            and data_location like ''%ANSWER_TXT''
                            and user_defined_column_nm is not null
                            and uiMeta.investigation_form_cd = '''+ @inv_form_cd + '''
                left outer join
                    dbo.NRT_PAGE_CASE_ANSWER caseAns with (nolock)
                        on caseAns.nbs_question_uid = uiMeta.nbs_question_uid
                            and caseAns.answer_group_seq_nbr=3
                inner join
                    #COVID_CASE_CORE_DATA phc with (nolock)
                        on phc.public_health_case_uid = caseAns.act_uid
                left outer join
                    dbo.NRT_SRTE_CODESET codeset
                        ON codeset.code_set_group_id = uiMeta.code_set_group_id
                left outer join
                    dbo.NRT_SRTE_CODE_VALUE_GENERAL cvg
                        ON cvg.code_set_nm = codeset.code_set_nm
                            AND cvg.code = caseAns.answer_txt
                group by [ACT_UID], [answer_txt] , [user_defined_column_nm],code_short_desc_txt
                    ) AS j PIVOT (max(answer_txt) FOR [user_defined_column_nm] in
                (' + STUFF(REPLACE(@columns1, ', rdbMeta.[', ',['), 1, 1, '') + ')) AS rdbMeta;';

   if @debug='true'
	    select @sql as COVID_CASE_RPT_DATA_3_SCRIPT;
    EXEC sp_executesql @sql;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

    if
    @debug = 'true'
   	exec('select '''+@Proc_Step_Name+'''  as step,* from '+@tmp_COVID_CASE_RPT_DATA_3);
--------------------------------------------------------------------------------------------------------------------------------------------------

    BEGIN TRANSACTION; 

    SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET @PROC_STEP_NAME = ' INSERTING INTO COVID_CASE_DATAMART';

    IF OBJECT_ID('#CASTED_COLUMNS') IS NOT NULL
		DROP TABLE #CASTED_COLUMNS;
	
	SELECT 
		c.COLUMN_NAME,
		c.DATA_TYPE,
		c.CHARACTER_MAXIMUM_LENGTH,
		CASE 
			WHEN UPPER(C.DATA_TYPE) = 'VARCHAR'
			THEN 'CAST(' + c.column_name + ' AS ' + c.DATA_TYPE + '(' + 
				CASE CHARACTER_MAXIMUM_LENGTH 
					WHEN -1 
					THEN 'MAX' 
					ELSE TRIM(STR(CHARACTER_MAXIMUM_LENGTH )) 
				END + '))'
			ELSE c.COLUMN_NAME
		END AS casted_column
	INTO #CASTED_COLUMNS		
	FROM rdb.INFORMATION_SCHEMA.COLUMNS c WITH(NOLOCK)
	WHERE c.TABLE_NAME = 'COVID_CASE_DATAMART' AND TABLE_SCHEMA = 'dbo'

    DECLARE @insert_query NVARCHAR(MAX);
    SET @insert_query =
    (	
    SELECT 'INSERT INTO  dbo.COVID_CASE_DATAMART( ' +
    STUFF((
	    SELECT ', [' + column_name + ']'
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS 		
	    WHERE table_name LIKE '#COVID_CASE_CORE_DATA%' 
        ORDER BY column_name
	    FOR XML PATH('')
    ), 1, 1, '') + ',' +
    STUFF((
    	SELECT ', [' + column_name + ']'
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS
	    WHERE table_name LIKE '#COVID_PATIENT_DATA%' AND column_name NOT IN('PAT_CASE_UID') 
        ORDER BY column_name 
		FOR XML PATH('')
	), 1, 1, '') + ',' +
	STUFF((
	    SELECT ', [' + column_name + ']'
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS
	    WHERE table_name LIKE '#COVID_ENTITIES_DATA%' AND column_name NOT IN('ENTITY_CASE_UID') 
        ORDER BY column_name 
		FOR XML PATH('')
	), 1, 1, '') + ',' +
	STUFF((
	    SELECT ', [' + column_name + ']'
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS
	    WHERE table_name = @tmp_COVID_CASE_DISCRETE_DATA AND column_name NOT IN('ACT_DISCRETE_UID') 
        ORDER BY column_name FOR XML PATH('')
	), 1, 1, '') + ', ' +
	STUFF((
	    SELECT ', [' + column_name + ']'
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS
	    WHERE table_name = @tmp_COVID_CASE_MULTI_DATA AND column_name NOT IN('ACT_MULTI_UID') 
        ORDER BY column_name FOR XML PATH('')
	    ), 1, 1, '') + ', ' +
	STUFF((
	    SELECT ', [' + column_name + ']'
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS
	    WHERE table_name = @tmp_COVID_CASE_RPT_DATA_1 AND column_name NOT IN('ACT_RPT_1_UID') 
        ORDER BY column_name FOR XML PATH('')
	    ), 1, 1, '') + ',' +
	STUFF((
	    SELECT ', [' + column_name + ']'
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS
	    WHERE table_name = @tmp_COVID_CASE_RPT_DATA_2 AND column_name NOT IN('ACT_RPT_2_UID') 
        ORDER BY column_name FOR XML PATH('')
	    ), 1, 1, '') + ',' +
	STUFF((
	    SELECT ', [' + column_name + ']'
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS
	    WHERE table_name = @tmp_COVID_CASE_RPT_DATA_3 AND column_name NOT IN('ACT_RPT_3_UID') 
        ORDER BY column_name FOR XML PATH('')
	    ), 1, 1, '')
+ ' ) select distinct ' +
	STUFF((
    	SELECT ', ' + cc.casted_column 
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS tt
		INNER JOIN #CASTED_COLUMNS cc on cc.COLUMN_NAME = tt.COLUMN_NAME
	    WHERE tt.table_name LIKE '#COVID_CASE_CORE_DATA%'
		ORDER BY tt.column_name
	    FOR XML PATH('')
    ), 1, 1, '') + ',' +
    STUFF((
	    SELECT ', ' + cc.casted_column 
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS tt
		INNER JOIN #CASTED_COLUMNS cc on cc.COLUMN_NAME = tt.COLUMN_NAME
	    WHERE tt.table_name LIKE '#COVID_PATIENT_DATA%' AND tt.column_name NOT IN('PAT_CASE_UID') 
        ORDER BY tt.column_name FOR XML PATH('')
	), 1, 1, '') + ',' +
	STUFF((
	    SELECT ', ' + cc.casted_column
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS tt
		INNER JOIN #CASTED_COLUMNS cc on cc.COLUMN_NAME = tt.COLUMN_NAME
	    WHERE tt.table_name LIKE '#COVID_ENTITIES_DATA%' AND tt.column_name NOT IN('ENTITY_CASE_UID') 
        ORDER BY tt.column_name FOR XML PATH('')
	), 1, 1, '') + ',' +
	STUFF((
	    SELECT ', ' + cc.casted_column
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS tt
		INNER JOIN #CASTED_COLUMNS cc on cc.COLUMN_NAME = tt.COLUMN_NAME
	    WHERE tt.table_name = @tmp_COVID_CASE_DISCRETE_DATA AND tt.column_name NOT IN('ACT_DISCRETE_UID') 
        ORDER BY tt.column_name FOR XML PATH('')
	), 1, 1, '') + ', ' +
	STUFF((
	    SELECT ', ' + cc.casted_column
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS tt
		INNER JOIN #CASTED_COLUMNS cc on cc.COLUMN_NAME = tt.COLUMN_NAME
	    WHERE tt.table_name = @tmp_COVID_CASE_MULTI_DATA AND tt.column_name NOT IN('ACT_MULTI_UID') 
        ORDER BY tt.column_name FOR XML PATH('')
    ), 1, 1, '') + ', ' +
    STUFF((
	    SELECT ', ' + cc.casted_column
	    FROM tempdb.INFORMATION_SCHEMA.COLUMNS tt
		INNER JOIN #CASTED_COLUMNS cc on cc.COLUMN_NAME = tt.COLUMN_NAME
	    WHERE tt.table_name = @tmp_COVID_CASE_RPT_DATA_1 AND tt.column_name NOT IN('ACT_RPT_1_UID') 
        ORDER BY tt.column_name FOR XML PATH('')
    ), 1, 1, '') + ',' +
    STUFF((
    SELECT ', ' + cc.casted_column
    FROM tempdb.INFORMATION_SCHEMA.COLUMNS tt
	INNER JOIN #CASTED_COLUMNS cc on cc.COLUMN_NAME = tt.COLUMN_NAME
    WHERE tt.table_name = @tmp_COVID_CASE_RPT_DATA_2 AND tt.column_name NOT IN('ACT_RPT_2_UID') 
    ORDER BY tt.column_name FOR XML PATH('')
    ), 1, 1, '') + ',' +
    STUFF((
    SELECT ', ' + cc.casted_column
    FROM tempdb.INFORMATION_SCHEMA.COLUMNS tt
	INNER JOIN #CASTED_COLUMNS cc on cc.COLUMN_NAME = tt.COLUMN_NAME
    WHERE tt.table_name = @tmp_COVID_CASE_RPT_DATA_3 AND tt.column_name NOT IN('ACT_RPT_3_UID') 
    ORDER BY tt.column_name FOR XML PATH('')
    ), 1, 1, '') + '
    FROM #COVID_CASE_CORE_DATA coreData
    INNER JOIN #COVID_PATIENT_DATA patData ON coreData.public_health_case_uid = patData.PAT_CASE_UID
    LEFT OUTER JOIN #COVID_ENTITIES_DATA entData ON coreData.public_health_case_uid = entData.ENTITY_CASE_UID
    LEFT OUTER JOIN '+@tmp_COVID_CASE_DISCRETE_DATA+' disData ON coreData.public_health_case_uid = disData.ACT_DISCRETE_UID
    LEFT OUTER JOIN '+@tmp_COVID_CASE_MULTI_DATA+' multiData ON coreData.public_health_case_uid = multiData.ACT_MULTI_UID
    LEFT OUTER JOIN '+@tmp_COVID_CASE_RPT_DATA_1+' rptData1 ON coreData.public_health_case_uid = rptData1.ACT_RPT_1_UID
    LEFT OUTER JOIN '+@tmp_COVID_CASE_RPT_DATA_2+' rptData2 ON coreData.public_health_case_uid = rptData2.ACT_RPT_2_UID
    LEFT OUTER JOIN '+@tmp_COVID_CASE_RPT_DATA_3+' rptData3 ON coreData.public_health_case_uid = rptData3.ACT_RPT_3_UID'
    );

    if @debug='true'
	    select @insert_query as insert_query;
    EXEC sp_executesql @insert_query;

    SELECT @ROWCOUNT_NO = @@ROWCOUNT;

    COMMIT TRANSACTION; 
    
    INSERT INTO [DBO].[JOB_FLOW_LOG]
    (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
    VALUES (@BATCH_ID, @Dataflow_Name,@Package_Name, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);


--------------------------------------------------------------------------------------------------------------------------------------------------
    INSERT INTO [dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name,@Package_Name, 'COMPLETE', 999, 'COMPLETE', 0);



    IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_DISCRETE_DATA, 'U') IS NOT NULL
        exec ('drop table '+@tmp_COVID_CASE_DISCRETE_DATA);
	IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_MULTI_DATA, 'U') IS NOT NULL
        exec ('drop table '+@tmp_COVID_CASE_MULTI_DATA);
	IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_RPT_DATA_1, 'U') IS NOT NULL
        exec ('drop table '+@tmp_COVID_CASE_RPT_DATA_1);
  	IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_RPT_DATA_2, 'U') IS NOT NULL
        exec ('drop table '+@tmp_COVID_CASE_RPT_DATA_2);
  	IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_RPT_DATA_3, 'U') IS NOT NULL
        exec ('drop table '+@tmp_COVID_CASE_RPT_DATA_3);

    END TRY
    BEGIN CATCH

		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_DISCRETE_DATA, 'U') IS NOT NULL
	        exec ('drop table '+@tmp_COVID_CASE_DISCRETE_DATA);
		IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_MULTI_DATA, 'U') IS NOT NULL
	        exec ('drop table '+@tmp_COVID_CASE_MULTI_DATA);
		IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_RPT_DATA_1, 'U') IS NOT NULL
	        exec ('drop table '+@tmp_COVID_CASE_RPT_DATA_1);
	  	IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_RPT_DATA_2, 'U') IS NOT NULL
	        exec ('drop table '+@tmp_COVID_CASE_RPT_DATA_2);
	  	IF OBJECT_ID('tempdb..' +@tmp_COVID_CASE_RPT_DATA_3, 'U') IS NOT NULL
	        exec ('drop table '+@tmp_COVID_CASE_RPT_DATA_3);

		         -- Construct the error message string with all details:
		        DECLARE @FullErrorMessage VARCHAR(8000) =
		            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
		            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
		            'Error Message: ' + ERROR_MESSAGE();


		INSERT INTO [dbo].[job_flow_log] ( batch_id
		    , [Dataflow_Name]
		    , [package_Name]
		    , [Status_Type]
		    , [step_number]
		    , [step_name]
		    , [Error_Description]
		    , [row_count])
		VALUES ( @batch_id
		        , @Dataflow_Name
		        , @Package_Name
		        , 'ERROR'
		        , @Proc_Step_no
		        , @Proc_Step_name
		        , @FullErrorMessage
		        , 0);


		return -1;

END CATCH

END;