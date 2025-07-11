IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_vaccination_event]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_vaccination_event]
END
GO 

CREATE PROCEDURE [dbo].[sp_vaccination_event] @vac_uids nvarchar(max), @debug bit = 'false'
as
BEGIN
 DECLARE
        @RowCount_no INT;
    DECLARE
        @Proc_Step_no FLOAT = 0;
    DECLARE
        @Proc_Step_Name VARCHAR(200) = '';
    DECLARE
        @Dataflow_Name VARCHAR(200) = 'Vaccination PRE-Processing Event';
    DECLARE
        @Package_Name VARCHAR(200) = 'NBS_ODSE.sp_vaccination_event';

    BEGIN TRY

    DECLARE @batch_id BIGINT;

    SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);

    if
        @debug = 'true'
        select @batch_id as Batch_id;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    ( batch_id
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
           , 0
           , LEFT('Pre ID-' + @vac_uids, 199)
           , 0
           , LEFT(@vac_uids, 199));


 	BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #VACCINATION_RECORD_INIT';

    with CodeLookup as (
        SELECT
        nq.question_identifier,
        cvg.code,
        cvg.code_short_desc_txt
        FROM NBS_ODSE.dbo.NBS_question nq with (nolock)
        INNER JOIN NBS_SRTE.dbo.Codeset cd with (nolock)
        ON cd.code_set_group_id = nq.code_set_group_id
        INNER JOIN NBS_SRTE.dbo.Code_value_general cvg with (nolock)
        ON cvg.code_set_nm = cd.code_set_nm
        WHERE nq.question_identifier IN ('VAC101', 'VAC104', 'VAC106', 'VAC107', 'VAC147')
    )
	SELECT
		I.ADD_TIME,
		I.ADD_USER_ID,
		I.AGE_AT_VACC	AS	AGE_AT_VACCINATION ,
		I.LAST_CHG_TIME  ,
		I.LAST_CHG_USER_ID ,
		I.LOCAL_ID,
		I.RECORD_STATUS_CD,
		I.RECORD_STATUS_TIME ,
		I.ACTIVITY_FROM_TIME	AS	VACCINE_ADMINISTERED_DATE ,
		I.VACC_DOSE_NBR	AS	VACCINE_DOSE_NBR ,
		I.INTERVENTION_UID AS VACCINATION_UID ,
		I.MATERIAL_EXPIRATION_TIME AS VACCINE_EXPIRATION_DT ,
		I.MATERIAL_LOT_NM	AS	VACCINE_LOT_NUMBER_TXT ,
		I.VERSION_CTRL_NBR ,
		I.ELECTRONIC_IND,
		I.MATERIAL_CD,
        I.STATUS_TIME,
        I.PROG_AREA_CD,
        I.JURISDICTION_CD,
        I.PROGRAM_JURISDICTION_OID,
		COALESCE(cvg1.code_short_desc_txt, '') AS VACCINATION_ADMINISTERED_NM,
		I.TARGET_SITE_CD,
	    COALESCE(cvg2.code_short_desc_txt, '') AS VACCINATION_ANATOMICAL_SITE,
	    I.AGE_AT_VACC_UNIT_CD,
	    COALESCE(cvg3.code_short_desc_txt, '') AS AGE_AT_VACCINATION_UNIT,
	    I.VACC_MFGR_CD,
	    COALESCE(cvg4.code_short_desc_txt, '') AS VACCINE_MANUFACTURER_NM,
	    I.VACC_INFO_SOURCE_CD,
	    COALESCE(cvg5.code_short_desc_txt, '') AS VACCINE_INFO_SOURCE
	INTO #TMP_VACCINATION_INIT
	FROM NBS_ODSE.dbo.INTERVENTION I with (nolock)
	INNER JOIN (
		SELECT
			INTERVENTION_UID, TYPE_CD
		FROM NBS_ODSE.dbo.INTERVENTION with (nolock)
		INNER JOIN NBS_ODSE.dbo.NBS_ACT_ENTITY with (nolock)
			ON NBS_ACT_ENTITY.ACT_UID = INTERVENTION.INTERVENTION_UID
		WHERE NBS_ACT_ENTITY.TYPE_CD='SubOfVacc' and INTERVENTION_UID in (SELECT value FROM STRING_SPLIT(@vac_uids, ','))
	) S ON I.INTERVENTION_UID =S.INTERVENTION_UID
    LEFT JOIN CodeLookup cvg1 ON I.MATERIAL_CD = cvg1.code AND cvg1.question_identifier = 'VAC101'
    LEFT JOIN CodeLookup cvg2 ON I.TARGET_SITE_CD = cvg2.code AND cvg2.question_identifier = 'VAC104'
    LEFT JOIN CodeLookup cvg3 ON I.AGE_AT_VACC_UNIT_CD = cvg3.code AND cvg3.question_identifier = 'VAC106'
    LEFT JOIN CodeLookup cvg4 ON I.VACC_MFGR_CD = cvg4.code AND cvg4.question_identifier = 'VAC107'
    LEFT JOIN CodeLookup cvg5 ON I.VACC_INFO_SOURCE_CD = cvg5.code AND cvg5.question_identifier = 'VAC147';


	SELECT @RowCount_no = @@ROWCOUNT;
    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


	COMMIT TRANSACTION;


	BEGIN TRANSACTION;

    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_TABLE';


    SELECT
        rdb_column_nm,
        CASE
           WHEN CHARINDEX('^', answer_txt) > 0
               THEN SUBSTRING(answer_txt, CHARINDEX('^', answer_txt) + 1, LEN(answer_txt))
           ELSE NULL
        END AS answer_oth,
       CASE
           WHEN CHARINDEX('^', answer_txt) > 0 THEN
               CASE
      				WHEN UPPER(SUBSTRING(answer_txt, 1, CHARINDEX('^', answer_txt) - 1)) = 'OTH' THEN 'OTH'
                   	ELSE SUBSTRING(answer_txt, 1, CHARINDEX('^', answer_txt) - 1)
                   END
           ELSE answer_txt
        END AS answer_txt,
       CASE
           WHEN LEN(
                CASE
                    WHEN CHARINDEX('^', answer_txt) > 0
                        THEN SUBSTRING(answer_txt, CHARINDEX('^', answer_txt) + 1, LEN(answer_txt))
                    ELSE NULL
                    END
            ) > 0
            THEN RTRIM(rdb_column_nm) + '_OTH'
            ELSE NULL
        END AS rdb_column_nm2,
        NBS_ANSWER_UID,
        CODE_SET_GROUP_ID,
        NBS_QUESTION_UID,
        INTERVENTION_UID
    INTO #coded_table
    FROM (
        SELECT DISTINCT
            NBS_ANSWER_UID,
            CASE
                WHEN CODE_SET_GROUP_ID IS NULL THEN unit_value
                ELSE code_set_group_id
            END AS CODE_SET_GROUP_ID,
            RDB_COLUMN_NM,
            ANSWER_TXT,
            INTERVENTION_UID,
            RECORD_STATUS_CD,
            NBS_QUESTION_UID,
            CASE
                WHEN code_set_group_id IS NULL THEN 'CODED'
                ELSE data_type
            END AS DATA_TYPE,
            rdb_table_nm,
            answer_group_seq_nbr
        FROM dbo.V_RDB_UI_METADATA_ANSWERS_VACCINATION
        WHERE
        CODE_SET_NM = 'NBS_DATA_TYPE'
      AND UPPER(data_type) = 'CODED'
      AND rdb_table_nm = 'D_VACCINATION'
      AND ANSWER_GROUP_SEQ_NBR IS NULL
      AND INTERVENTION_UID IN (SELECT value FROM STRING_SPLIT(@vac_uids, ','))
    ) as metadata
    ;

    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #CODED_TABLE;


    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;

    BEGIN TRANSACTION;

    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_SNM';

    SELECT coded.CODE_SET_GROUP_ID,
           INTERVENTION_UID,
           NBS_QUESTION_UID,
           NBS_ANSWER_UID,
           REPLACE(answer_txt, ' ', '') + ' ' + REPLACE(CODE_SHORT_DESC_TXT, ' ', '') as ANSWER_TXT,
           cvg.CODE_SET_NM,
           RDB_COLUMN_NM,
           ANSWER_OTH,
           cvg.CODE,
           CODE_SHORT_DESC_TXT as ANSWER_TXT2,
           rdb_column_nm2
    INTO #CODED_TABLE_SNM
    FROM #CODED_TABLE coded
             LEFT JOIN NBS_SRTE.DBO.CODESET_GROUP_METADATA metadata with (nolock)
                       ON metadata.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
             LEFT JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL cvg with (nolock)
                       ON cvg.CODE_SET_NM = metadata.CODE_SET_NM
                           AND cvg.CODE = CODED.ANSWER_OTH
    WHERE ANSWER_OTH IS NOT NULL
      AND ANSWER_TXT <> 'OTH';


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #coded_table_snm;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;

    BEGIN TRANSACTION;

    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_NONSNM';

    SELECT coded.CODE_SET_GROUP_ID,
           INTERVENTION_UID,
           NBS_QUESTION_UID,
           NBS_ANSWER_UID,
           ANSWER_TXT,
           cvg.CODE_SET_NM,
           RDB_COLUMN_NM,
           ANSWER_OTH,
           RDB_COLUMN_NM2,
           cvg.CODE,
           CODE_SHORT_DESC_TXT AS ANSWER_TXT1
    INTO #CODED_TABLE_NONSNM
    FROM #CODED_TABLE coded
    LEFT JOIN nbs_srte.dbo.CODESET_GROUP_METADATA metadata with (nolock)
            ON metadata.CODE_SET_GROUP_ID = coded.CODE_SET_GROUP_ID
    LEFT JOIN nbs_srte.dbo.CODE_VALUE_GENERAL cvg with (nolock)
            ON cvg.CODE_SET_NM = metadata.CODE_SET_NM
                AND cvg.CODE = coded.ANSWER_TXT
    WHERE NBS_ANSWER_UID NOT IN (SELECT NBS_ANSWER_UID FROM #coded_table_snm);


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #CODED_TABLE_NONSNM;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;

    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_SNTEMP';


    SELECT
	    NBS_ANSWER_UID,
	    CODE_SET_GROUP_ID,
	    RDB_COLUMN_NM,
	    INTERVENTION_UID,
	    RECORD_STATUS_CD,
	    NBS_QUESTION_UID,
	    CASE
	        WHEN CHARINDEX('^', ANSWER_TXT) > 0
	            THEN SUBSTRING(ANSWER_TXT, CHARINDEX('^', ANSWER_TXT) + 1, LEN(ANSWER_TXT))
	        ELSE NULL
	        END AS ANSWER_TXT_CODE,
	    CASE
	        WHEN CHARINDEX('^', ANSWER_TXT) > 0
	            THEN CAST(SUBSTRING(ANSWER_TXT, 1, CHARINDEX('^', ANSWER_TXT) - 1) AS INT)
	            ELSE NULL
	            END AS ANSWER_VALUE
    INTO #CODED_TABLE_SNTEMP
    FROM (
        SELECT DISTINCT
	        NBS_ANSWER_UID,
	        NBS_QUESTION_UID,
	        ANSWER_TXT,
	        RDB_COLUMN_NM,
	        CODE_SET_GROUP_ID,
	        DATA_TYPE,
	        INTERVENTION_UID,
	        RECORD_STATUS_CD
        FROM dbo.V_RDB_UI_METADATA_ANSWERS_VACCINATION
        WHERE RDB_TABLE_NM = 'D_VACCINATION'
            AND QUESTION_GROUP_SEQ_NBR IS NULL
            AND (
            (UPPER(DATA_TYPE) = 'NUMERIC' AND UPPER(mask) = 'NUM_TEMP') OR
            (UPPER(DATA_TYPE) = 'NUMERIC' AND UPPER(mask) = 'NUM_SN' AND unit_type_cd = 'CODED')
            )
            AND RDB_COLUMN_NM NOT LIKE '%_CD'
            AND ANSWER_GROUP_SEQ_NBR IS NULL
            AND upper(data_type) = 'CODED'
        ) metadata
            ;


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #coded_table_sntemp;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;

    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_SNTEMP_TRANS';


    SELECT INTERVENTION_UID,
        CODED.ANSWER_TXT_CODE,
        CODED.ANSWER_VALUE,
        NBS_ANSWER_UID,
        CVG.CODE_SET_NM,
        CODED.RDB_COLUMN_NM,
        CVG.CODE,
        CVG.CODE_SHORT_DESC_TXT                                                                AS ANSWER_TXT2,
        NBS_QUESTION_UID,
        REPLACE(CODED.ANSWER_VALUE, ' ', '') + ' ' + REPLACE(CVG.CODE_SHORT_DESC_TXT, ' ', '') AS ANSWER_TXT
    INTO #CODED_TABLE_SNTEMP_TRANS
    FROM #CODED_TABLE_SNTEMP CODED
    LEFT JOIN nbs_srte.dbo.CODESET_GROUP_METADATA metadata with (nolock)
            ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
    LEFT JOIN nbs_srte.dbo.CODE_VALUE_GENERAL CVG with (nolock)
            ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
                AND CVG.CODE = CODED.ANSWER_TXT_CODE;

    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #coded_table_sntemp_trans;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_SN_MERGED';


    SELECT COALESCE(SNM.CODE_SET_GROUP_ID, NONSNM.CODE_SET_GROUP_ID)                     AS CODE_SET_GROUP_ID,
    COALESCE(SNT.NBS_ANSWER_UID, SNM.NBS_ANSWER_UID, NONSNM.NBS_ANSWER_UID)       AS NBS_ANSWER_UID,
    COALESCE(SNT.RDB_COLUMN_NM, SNM.RDB_COLUMN_NM, NONSNM.RDB_COLUMN_NM)          AS RDB_COLUMN_NM,
    COALESCE(SNT.ANSWER_TXT, SNM.ANSWER_TXT, NONSNM.ANSWER_TXT)                   AS ANSWER_TXT,
    SNT.ANSWER_VALUE,
    CASE
        WHEN TRIM(NONSNM.ANSWER_TXT1) = '' THEN COALESCE(SNT.ANSWER_TXT, SNM.ANSWER_TXT, NONSNM.ANSWER_TXT)
            ELSE NONSNM.answer_txt1 END                                               AS ANSWER_TXT1,
        COALESCE(SNT.CODE_SET_NM, SNM.CODE_SET_NM, NONSNM.CODE_SET_NM)                AS CODE_SET_NM,
        COALESCE(SNT.CODE, SNM.CODE, NONSNM.CODE)                                     AS CODE,
        COALESCE(SNT.ANSWER_TXT2, SNM.ANSWER_TXT2)                                    AS ANSWER_TXT2,
        COALESCE(SNT.INTERVENTION_UID, SNM.INTERVENTION_UID, NONSNM.INTERVENTION_UID)          AS INTERVENTION_UID,
        COALESCE(SNT.NBS_QUESTION_UID, SNM.NBS_QUESTION_UID, NONSNM.NBS_QUESTION_UID) AS NBS_QUESTION_UID,
        COALESCE(snm.answer_oth, NONSNM.answer_oth)                                   AS ANSWER_OTH,
        COALESCE(snm.rdb_column_nm2, nonsnm.rdb_column_nm2)                           as rdb_column_nm2
    INTO #CODED_TABLE_SN_MERGED
    FROM #CODED_TABLE_SNTEMP_TRANS SNT
    FULL OUTER JOIN #CODED_TABLE_SNM SNM
                    ON SNT.RDB_COLUMN_NM = SNM.RDB_COLUMN_NM AND SNT.NBS_ANSWER_UID = SNM.NBS_ANSWER_UID
    FULL OUTER JOIN #CODED_TABLE_NONSNM NONSNM
                    ON (COALESCE(SNT.RDB_COLUMN_NM, SNM.RDB_COLUMN_NM) = NONSNM.RDB_COLUMN_NM
                        AND COALESCE(SNT.NBS_ANSWER_UID, SNM.NBS_ANSWER_UID) = NONSNM.NBS_ANSWER_UID);
    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #coded_table_sn_merged;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_ANSWER_DESCS';

    WITH aggregated_answers AS (
        SELECT INTERVENTION_UID,
            NBS_QUESTION_UID,
            STRING_AGG(TRIM(ANSWER_TXT1), ' | ')        AS ANSWER_DESC11

        FROM #coded_table_sn_merged
        GROUP BY INTERVENTION_UID,
                NBS_QUESTION_UID
    )
    SELECT
        aa.INTERVENTION_UID,
        aa.NBS_QUESTION_UID,
        ctsm.RDB_COLUMN_NM,
        CASE
            WHEN LEN(RTRIM(LTRIM(ANSWER_DESC11))) > 0 AND RIGHT(RTRIM(ANSWER_DESC11), 1) = '|'
                THEN LEFT(RTRIM(ANSWER_DESC11), LEN(RTRIM(ANSWER_DESC11)) - 1)
            ELSE RTRIM(ANSWER_DESC11)
            END AS ANSWER_DESC11,
        ctsm.NBS_ANSWER_UID
    into #coded_answer_descs
    FROM aggregated_answers aa
    LEFT JOIN #CODED_TABLE_SN_MERGED CTSM
            ON aa.INTERVENTION_UID = CTSM.INTERVENTION_UID
                AND aa.NBS_QUESTION_UID = ctsm.NBS_QUESTION_UID;

    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #coded_answer_descs;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_COUNTY_TABLE';


    SELECT
        CODED.CODE_SET_GROUP_ID,
        INTERVENTION_UID,
        NBS_QUESTION_UID,
        NBS_ANSWER_UID,
        ANSWER_TXT,
        CVG.CODE_SET_NM,
        RDB_COLUMN_NM,
        ANSWER_OTH,
        RDB_COLUMN_NM2,
        CVG.CODE,
        CODE_SHORT_DESC_TXT AS ANSWER_TXT1
    INTO #CODED_COUNTY_TABLE
    FROM #CODED_TABLE_SN_MERGED AS CODED
    LEFT JOIN
        nbs_srte.dbo.CODESET_GROUP_METADATA AS METADATA with (nolock)
        ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
    LEFT JOIN
        nbs_srte.dbo.V_STATE_COUNTY_CODE_VALUE AS CVG with (nolock)
        ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
            AND CVG.CODE = CODED.ANSWER_TXT
    WHERE METADATA.CODE_SET_NM = 'COUNTY_CCD';


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #coded_county_table;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_COUNTY_TABLE_DESC';


    WITH aggregated_answers AS (
        SELECT
            INTERVENTION_UID,
            NBS_QUESTION_UID,
            STRING_AGG(TRIM(ANSWER_TXT1),
            ' | ') AS ANSWER_DESC11
        FROM
            #CODED_COUNTY_TABLE
        GROUP BY
            INTERVENTION_UID,
            NBS_QUESTION_UID
    )
    SELECT
        cctd.INTERVENTION_UID,
        cctd.NBS_QUESTION_UID,
        cct.RDB_COLUMN_NM,
        cct.NBS_ANSWER_UID,
        CASE
            WHEN LEN(LTRIM(RTRIM(ANSWER_DESC11))) > 0
            AND RIGHT(RTRIM(ANSWER_DESC11),
            1) = '|'
                        THEN LEFT(RTRIM(ANSWER_DESC11),
            LEN(RTRIM(ANSWER_DESC11)) - 1)
            ELSE RTRIM(ANSWER_DESC11)
        END AS ANSWER_DESC11
    into #CODED_COUNTY_TABLE_DESC
    FROM
        aggregated_answers cctd
    LEFT JOIN #CODED_COUNTY_TABLE cct
                            ON
        cctd.INTERVENTION_UID = cct.INTERVENTION_UID
        AND cctd.NBS_QUESTION_UID = cct.NBS_QUESTION_UID;


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #CODED_COUNTY_TABLE_DESC;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_OTH';


    SELECT CODED.CODE_SET_GROUP_ID,
        INTERVENTION_UID,
        NBS_QUESTION_UID,
        NBS_ANSWER_UID,
        ANSWER_TXT,
        CODE_SET_NM,
        ANSWER_OTH,
        RDB_COLUMN_NM2,
        CODE,
        ANSWER_TXT1,
        CASE
            WHEN LEN(LTRIM(RTRIM(RDB_COLUMN_NM2))) > 0 THEN RDB_COLUMN_NM2
            ELSE RDB_COLUMN_NM
        END AS RDB_COLUMN_NM
    INTO #CODED_TABLE_OTH
    FROM #CODED_TABLE_SN_MERGED AS CODED;


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #coded_table_oth;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_FINAL';

    SELECT COALESCE(CTO.RDB_COLUMN_NM, CCT.RDB_COLUMN_NM, CTSM.RDB_COLUMN_NM) AS RDB_COLUMN_NM,
                COALESCE(CTO.INTERVENTION_UID, CCT.INTERVENTION_UID, CTSM.INTERVENTION_UID) AS INTERVENTION_UID,
                COALESCE(CCT.ANSWER_DESC11, CTSM.ANSWER_DESC11)                    AS ANSWER_DESC11
    INTO #CODED_TABLE_FINAL
    FROM #CODED_TABLE_OTH CTO
            FULL OUTER JOIN #CODED_COUNTY_TABLE_DESC CCT
                            ON CTO.RDB_COLUMN_NM = CCT.RDB_COLUMN_NM AND CTO.NBS_ANSWER_UID = CCT.NBS_ANSWER_UID
            FULL OUTER JOIN #CODED_ANSWER_DESCS CTSM
                            ON (COALESCE(CTO.RDB_COLUMN_NM, CCT.RDB_COLUMN_NM) = CTSM.RDB_COLUMN_NM
                                AND COALESCE(CTO.NBS_ANSWER_UID, CCT.NBS_ANSWER_UID) = CTSM.NBS_ANSWER_UID);
        if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #coded_table_FINAL;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #TEXT_FINAL';

    SELECT NBS_ANSWER_UID,
        RDB_COLUMN_NM,
        ANSWER_TXT,
        INTERVENTION_UID,
        NBS_QUESTION_UID
    INTO #TEXT_FINAL
    FROM (
    	SELECT DISTINCT
	        NBS_ANSWER_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT,
	        INTERVENTION_UID,
	        NBS_QUESTION_UID
        FROM dbo.V_RDB_UI_METADATA_ANSWERS_VACCINATION
        WHERE
        CODE_SET_NM = 'NBS_DATA_TYPE'
        AND CODE = 'TEXT'
        AND rdb_table_nm = 'D_VACCINATION'
        AND ANSWER_GROUP_SEQ_NBR IS NULL
        AND INTERVENTION_UID IN (SELECT value FROM STRING_SPLIT(@vac_uids, ','))
    ) as metadata
    ;

    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #TEXT_FINAL;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #NUMERIC_BASE_DATA';

     SELECT
		NBS_ANSWER_UID,
		CODE_SET_GROUP_ID,
        RDB_COLUMN_NM,
        ANSWER_TXT,
        INTERVENTION_UID,
        NBS_QUESTION_UID,
        RECORD_STATUS_CD
    INTO #NUMERIC_BASE_DATA
    FROM (
    	SELECT DISTINCT
	    	NBS_ANSWER_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT,
	        INTERVENTION_UID,
	        NBS_QUESTION_UID,
	        CODE_SET_GROUP_ID,
	        RECORD_STATUS_CD
        FROM dbo.V_RDB_UI_METADATA_ANSWERS_VACCINATION
        WHERE RDB_TABLE_NM = 'D_VACCINATION'
            AND QUESTION_GROUP_SEQ_NBR IS NULL
            AND ANSWER_GROUP_SEQ_NBR IS NULL
            AND data_location = 'NBS_ANSWER.ANSWER_TXT'
            AND CODE_SET_NM = 'NBS_DATA_TYPE'
	    	AND CODE IN ('Numeric', 'NUMERIC')
        AND INTERVENTION_UID IN (SELECT value FROM STRING_SPLIT(@vac_uids, ','))
        ) metadata



    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #NUMERIC_BASE_DATA;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #NUMERIC_DATA1';


    SELECT NBS_ANSWER_UID,
        CODE_SET_GROUP_ID,
        RDB_COLUMN_NM,
        ANSWER_TXT,
        INTERVENTION_UID,
        RECORD_STATUS_CD,
        NBS_QUESTION_UID,
        CASE
            WHEN CHARINDEX('^', ANSWER_TXT) > 0
                THEN LEFT(ANSWER_TXT, CHARINDEX('^', ANSWER_TXT) - 1)
            ELSE NULL
            END AS ANSWER_UNIT,
        CASE
            WHEN CHARINDEX('^', ANSWER_TXT) > 0
                THEN SUBSTRING(ANSWER_TXT, CHARINDEX('^', ANSWER_TXT) + 1, LEN(ANSWER_TXT))
            ELSE NULL
            END AS ANSWER_CODED,
        CASE
            WHEN CHARINDEX('^', ANSWER_TXT) > 0
                THEN TRY_CAST(REPLACE(LEFT(ANSWER_TXT, CHARINDEX('^', ANSWER_TXT) - 1), ',', '') AS FLOAT)
            ELSE NULL
            END AS UNIT_VALUE1,
        CASE
            WHEN LEN(
                        CASE
                            WHEN CHARINDEX('^', ANSWER_TXT) > 0
                                THEN SUBSTRING(ANSWER_TXT, CHARINDEX('^', ANSWER_TXT) + 1, LEN(ANSWER_TXT))
                            ELSE NULL
                            END
                ) > 0
                THEN RTRIM(RDB_COLUMN_NM) + ' UNIT'
            ELSE RDB_COLUMN_NM
            END AS RDB_COLUMN_NM2
    INTO #NUMERIC_DATA1
    FROM #NUMERIC_BASE_DATA;

    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #NUMERIC_DATA1;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #NUMERIC_DATA2';

    SELECT NBS_ANSWER_UID,
        CODE_SET_GROUP_ID,
        CASE
            WHEN LEN(RDB_COLUMN_NM2) > 0 THEN RDB_COLUMN_NM2
            ELSE RDB_COLUMN_NM
            END AS RDB_COLUMN_NM,
        ANSWER_TXT,
        INTERVENTION_UID,
        RECORD_STATUS_CD,
        NBS_QUESTION_UID,
        ANSWER_UNIT,
        ANSWER_CODED,
        UNIT_VALUE1
    INTO #NUMERIC_DATA2
    FROM #NUMERIC_DATA1;


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #NUMERIC_DATA2;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #NUMERIC_DATA_MERGED';

    SELECT COALESCE(B.NBS_ANSWER_UID, A.NBS_ANSWER_UID)       AS NBS_ANSWER_UID,
           COALESCE(B.CODE_SET_GROUP_ID, A.CODE_SET_GROUP_ID) AS CODE_SET_GROUP_ID,
           COALESCE(B.RDB_COLUMN_NM, A.RDB_COLUMN_NM)         AS RDB_COLUMN_NM,
           COALESCE(B.ANSWER_TXT, A.ANSWER_TXT)               AS ANSWER_TXT,
           COALESCE(B.INTERVENTION_UID, A.INTERVENTION_UID)         AS INTERVENTION_UID,
           COALESCE(B.RECORD_STATUS_CD, A.RECORD_STATUS_CD)   AS RECORD_STATUS_CD,
           COALESCE(B.NBS_QUESTION_UID, A.NBS_QUESTION_UID)   AS NBS_QUESTION_UID,
           COALESCE(B.ANSWER_UNIT, A.ANSWER_UNIT)             AS ANSWER_UNIT,
           COALESCE(B.ANSWER_CODED, A.ANSWER_CODED)           AS ANSWER_CODED,
           COALESCE(B.UNIT_VALUE1, A.UNIT_VALUE1)             AS UNIT_VALUE1
    INTO #NUMERIC_DATA_MERGED
    FROM #NUMERIC_DATA1 AS A
             FULL OUTER JOIN
         #NUMERIC_DATA2 AS B
         ON
             A.NBS_ANSWER_UID = B.NBS_ANSWER_UID
                 AND A.RDB_COLUMN_NM = B.RDB_COLUMN_NM;

    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #NUMERIC_DATA_MERGED;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);

    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #NUMERIC_DATA_TRANS';

    SELECT CODED.INTERVENTION_UID,
           CODED.NBS_QUESTION_UID,
           CODED.NBS_ANSWER_UID,
           CODED.ANSWER_UNIT,
           CODED.ANSWER_CODED,
           CVG.CODE_SET_NM,
           CODED.RDB_COLUMN_NM,
           CASE
               WHEN (TRIM(CVG.CODE_SHORT_DESC_TXT) = '') THEN CODED.ANSWER_TXT
               WHEN CHARINDEX(' UNIT', CODED.RDB_COLUMN_NM) > 0 THEN CVG.CODE_SHORT_DESC_TXT
               ELSE CODED.ANSWER_UNIT
               END                 AS ANSWER_TXT,
           CVG.CODE,
           CVG.CODE_SHORT_DESC_TXT AS UNIT
    INTO #NUMERIC_DATA_TRANS
    FROM #NUMERIC_DATA_MERGED AS CODED
             LEFT JOIN
         nbs_srte.dbo.CODESET_GROUP_METADATA AS METADATA with (nolock)
         ON METADATA.CODE_SET_GROUP_ID = CODED.UNIT_VALUE1
             LEFT JOIN
         nbs_srte.dbo.CODE_VALUE_GENERAL AS CVG with (nolock)
         ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
    WHERE CVG.CODE = CODED.ANSWER_CODED;


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #NUMERIC_DATA_TRANS;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);

    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #NUMERIC_DATA_TRANS1';

    SELECT DISTINCT CASE
                        WHEN INTERVENTION_UID IS NULL THEN 1
                        ELSE INTERVENTION_UID
                        END AS INTERVENTION_UID,
                    RDB_COLUMN_NM,
                    ANSWER_UNIT,
                    ANSWER_TXT
    INTO #NUMERIC_DATA_TRANS1
    FROM #NUMERIC_DATA_TRANS;


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #NUMERIC_DATA_TRANS;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);

    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #DATE_DATA';

    SELECT RDB_COLUMN_NM,
           INTERVENTION_UID,
           FORMAT(TRY_CAST(ANSWER_TXT AS datetime2), 'yyyy-MM-dd HH:mm:ss.fff') AS ANSWER_TXT1
    INTO #DATE_DATA
    FROM (
    	SELECT DISTINCT
    	    INTERVENTION_UID,
    		RDB_COLUMN_NM,
           NBS_QUESTION_UID,
              CODE_SET_GROUP_ID,
              INVESTIGATION_FORM_CD,
              QUESTION_GROUP_SEQ_NBR,
              ANSWER_TXT,
              DATA_TYPE
          FROM dbo.V_RDB_UI_METADATA_ANSWERS_VACCINATION
          WHERE RDB_TABLE_NM = 'D_VACCINATION'
            AND QUESTION_GROUP_SEQ_NBR IS NULL
            AND data_location = 'NBS_ANSWER.ANSWER_TXT'
            AND CODE_SET_NM = 'NBS_DATA_TYPE'
		    AND CODE IN ('DATETIME', 'DATE')
		    AND ANSWER_GROUP_SEQ_NBR IS NULL
            AND INTERVENTION_UID IN (SELECT value FROM STRING_SPLIT(@vac_uids, ','))
   ) metadata
;



    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #DATE_DATA;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #UNIONED_DATA';


    WITH ud AS (
	    SELECT INTERVENTION_UID,
	       RDB_COLUMN_NM,
	       ANSWER_DESC11 AS ANSWER_VAL
	    FROM #CODED_TABLE_FINAL
	    UNION ALL
	    SELECT INTERVENTION_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT1 AS ANSWER_VAL
	    FROM #DATE_DATA
	    UNION ALL
	    SELECT INTERVENTION_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT AS ANSWER_VAL
	    FROM #NUMERIC_DATA_TRANS1
	    UNION ALL
	    SELECT INTERVENTION_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT AS ANSWER_VAL
	    FROM #TEXT_FINAL
    )
    SELECT INTERVENTION_UID,
        RDB_COLUMN_NM,
        ANSWER_VAL
    INTO #UNIONED_DATA
    FROM ud;

    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #UNIONED_DATA;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #D_VACCINATION_COLUMNS';


    WITH ordered_list AS (
        SELECT RDB_TABLE_NM as TABLE_NAME,
            RDB_COLUMN_NM,
            1   AS NEW_FLAG,
            LAST_CHG_TIME,
            LAST_CHG_USER_ID,
            ROW_NUMBER() OVER (PARTITION BY RDB_COLUMN_NM ORDER BY LAST_CHG_TIME DESC) AS rn

        FROM NBS_ODSE.dbo.NBS_rdb_metadata with (nolock)
        WHERE RDB_TABLE_NM = 'D_VACCINATION' and RDB_COLUMN_NM in (select RDB_COLUMN_NM from #UNIONED_DATA)
    )
    SELECT distinct TABLE_NAME,
           RDB_COLUMN_NM,
           NEW_FLAG,
           LAST_CHG_TIME,
           LAST_CHG_USER_ID
    INTO #D_VACCINATION_COLUMNS
    FROM ordered_list
    where rn = 1;


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #D_VACCINATION_COLUMNS;

    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
            @RowCount_no);


    COMMIT TRANSACTION;

     BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'SELECT FULL VACCINATION DATA';

     with PROVIDER_INFO as (
        select
            src.VACCINATION_UID,
            actent.ENTITY_UID as PROVIDER_UID
        from #TMP_VACCINATION_INIT src
        inner join NBS_ODSE.dbo.NBS_ACT_ENTITY actent with (nolock)
        	ON actent.ACT_UID = src.VACCINATION_UID and TYPE_CD = 'PerformerOfVacc'
        inner join NBS_ODSE.dbo.Person p with (nolock)
        	ON p.PERSON_UID = actent.ENTITY_UID

    )
    , ORG_INFO as (
        select
            src.VACCINATION_UID,
            actent.ENTITY_UID as ORGANIZATION_UID
        from #TMP_VACCINATION_INIT src
        inner join NBS_ODSE.dbo.NBS_ACT_ENTITY actent with (nolock)
             ON actent.ACT_UID = src.VACCINATION_UID and TYPE_CD='PerformerOfVacc'
        inner join NBS_ODSE.dbo.ORGANIZATION o with (nolock)
        	ON o.ORGANIZATION_UID = actent.ENTITY_UID
    )
    , PAT_INFO as (
        select
            src.VACCINATION_UID,
            actent.ENTITY_UID as PATIENT_UID
        from #TMP_VACCINATION_INIT src
        inner join NBS_ODSE.dbo.NBS_ACT_ENTITY actent with (nolock)
             ON actent.ACT_UID = src.VACCINATION_UID and TYPE_CD='SubOfVacc'
        inner join NBS_ODSE.dbo.Person p with (nolock)
        	ON p.PERSON_UID = actent.ENTITY_UID
    )
     , CASE_INFO as (
        select
            src.VACCINATION_UID,
            actrel.TARGET_ACT_UID as PHC_UID
        from #TMP_VACCINATION_INIT src
        inner join NBS_ODSE.dbo.ACT_RELATIONSHIP actrel with (nolock)
             ON actrel.SOURCE_ACT_UID = src.VACCINATION_UID
        where TYPE_CD='1180'
    )
    SELECT
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
		ix.ELECTRONIC_IND,
        ix.STATUS_TIME,
        ix.PROG_AREA_CD,
        ix.JURISDICTION_CD,
        ix.PROGRAM_JURISDICTION_OID,
        ix.MATERIAL_CD,
		prov.PROVIDER_UID,
		org.ORGANIZATION_UID,
		cas.PHC_UID,
		pat.PATIENT_UID,
	    nesteddata.answers,
	    nesteddata.rdb_cols
    FROM #TMP_VACCINATION_INIT ix
    LEFT OUTER JOIN PROVIDER_INFO prov on prov.VACCINATION_UID = ix.VACCINATION_UID
    LEFT OUTER JOIN ORG_INFO org on org.VACCINATION_UID = ix.VACCINATION_UID
    LEFT OUTER JOIN PAT_INFO pat on pat.VACCINATION_UID = ix.VACCINATION_UID
    LEFT OUTER JOIN CASE_INFO cas on cas.VACCINATION_UID = ix.VACCINATION_UID
    OUTER apply (
        SELECT * FROM
            (SELECT (SELECT ud.RDB_COLUMN_NM,
                               ud.ANSWER_VAL
                        FROM #UNIONED_DATA ud
                        WHERE ud.INTERVENTION_UID = ix.VACCINATION_UID
                        FOR json path,INCLUDE_NULL_VALUES) AS answers) AS answers,
            (SELECT (SELECT TABLE_NAME,
                           RDB_COLUMN_NM,
                           NEW_FLAG,
                           LAST_CHG_TIME,
                           LAST_CHG_USER_ID
                    FROM #D_VACCINATION_COLUMNS
                    FOR json path,INCLUDE_NULL_VALUES) AS rdb_cols) AS rdb_cols
    ) AS nesteddata;


    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


    COMMIT TRANSACTION;

     INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    ( batch_id
    , [Dataflow_Name]
    , [package_Name]
    , [Status_Type]
    , [step_number]
    , [step_name]
    , [row_count]
    , [Msg_Description1])
    VALUES ( @batch_id
           , @Dataflow_Name
           , 'NBS_ODSE.sp_vaccination_record_event'
           , 'COMPLETE'
           , 0
           , LEFT('Pre ID-' + @vac_uids, 199)
           , 0
           , LEFT(@vac_uids, 199));

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


	return -1 ;

END CATCH

END;