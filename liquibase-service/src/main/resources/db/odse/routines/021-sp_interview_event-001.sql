CREATE OR ALTER PROCEDURE [dbo].[sp_interview_event] @ix_uids nvarchar(max),
                                                     @debug bit = 'false'
AS
BEGIN

    DECLARE
        @RowCount_no INT;
    DECLARE
        @Proc_Step_no FLOAT = 0;
    DECLARE
        @Proc_Step_Name VARCHAR(200) = '';

    BEGIN TRY

        DECLARE @batch_id BIGINT;

        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmss')) as bigint);

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
               , 'Interview PRE-Processing Event'
               , 'NBS_ODSE.sp_interview_event'
               , 'START'
               , 0
               , LEFT('Pre ID-' + @ix_uids, 199)
               , 0
               , LEFT(@ix_uids, 199));

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #INTERVIEW_INIT';

        SELECT ix.INTERVIEW_UID,
               ix.INTERVIEW_STATUS_CD,
               ix.INTERVIEW_DATE,
               ix.INTERVIEWEE_ROLE_CD,
               ix.INTERVIEW_TYPE_CD,
               ix.INTERVIEW_LOC_CD,
               ix.LOCAL_ID,
               ix.RECORD_STATUS_CD,
               ix.RECORD_STATUS_TIME,
               ix.ADD_TIME,
               ix.ADD_USER_ID,
               ix.last_chg_time,
               ix.LAST_CHG_USER_ID,
               ix.VERSION_CTRL_NBR,
               cvg1.code_short_desc_txt                              AS IX_STATUS,
               cvg2.code_short_desc_txt                              AS IX_INTERVIEWEE_ROLE,
               COALESCE(cvg3.code_short_desc_txt, INTERVIEW_TYPE_CD) AS IX_TYPE,
               cvg4.code_short_desc_txt                              AS IX_LOCATION,
               ar1.target_act_uid                                    AS INVESTIGATION_UID,
               nae.entity_uid                                        AS PROVIDER_UID,
               nae2.entity_uid                                       AS ORGANIZATION_UID,
               nae3.entity_uid                                       AS PATIENT_UID
        INTO #INTERVIEW_INIT
        FROM NBS_ODSE.dbo.INTERVIEW ix WITH (NOLOCK)
                 LEFT JOIN nbs_srte.dbo.Code_value_general cvg1 WITH (NOLOCK)
                           ON ix.interview_status_cd = cvg1.code and cvg1.code_set_nm = 'NBS_INTVW_STATUS'
                 LEFT JOIN nbs_srte.dbo.Code_value_general cvg2 WITH (NOLOCK)
                           ON ix.interviewee_role_cd = cvg2.code and cvg2.code_set_nm = 'NBS_INTVWEE_ROLE'
                 LEFT JOIN nbs_srte.dbo.Code_value_general cvg3 WITH (NOLOCK)
                           ON ix.interview_type_cd = cvg3.code and cvg3.code_set_nm = 'NBS_INTERVIEW_TYPE_STDHIV'
                 LEFT JOIN nbs_srte.dbo.Code_value_general cvg4 WITH (NOLOCK)
                           ON ix.interview_loc_cd = cvg4.code and
                              cvg4.code_set_nm in ('NBS_INTVW_LOC', 'NBS_INTVW_LOC_STDHIV')
                LEFT JOIN NBS_ODSE.dbo.Act_relationship ar1 WITH (NOLOCK)
                    ON ar1.source_act_uid = ix.interview_uid AND ar1.type_cd = 'IXS'
                LEFT JOIN NBS_ODSE.dbo.NBS_act_entity nae  WITH (NOLOCK)
                    on ix.interview_uid = nae.act_uid
                    AND nae.type_cd = 'IntrvwerOfInterview'
                LEFT JOIN NBS_ODSE.dbo.NBS_act_entity nae2  WITH (NOLOCK)
                    on ix.interview_uid = nae2.act_uid
                    AND nae2.type_cd = 'OrgAsSiteOfIntv'
                LEFT JOIN NBS_ODSE.dbo.NBS_act_entity nae3  WITH (NOLOCK)
                    on ix.interview_uid = nae3.act_uid
                    AND nae3.type_cd = 'IntrvweeOfInterview'
        where interview_uid in (SELECT value FROM STRING_SPLIT(@ix_uids, ','));

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #INTERVIEW_INIT;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_TABLE';

        SELECT rdb_column_nm,
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
               nbs_answer_uid,
               CODE_SET_GROUP_ID,
               nbs_question_uid,
               INTERVIEW_UID
        INTO #coded_table
        FROM (SELECT DISTINCT NBS_ANSWER_UID,
                              CASE
                                  WHEN CODE_SET_GROUP_ID IS NULL THEN unit_value
                                  ELSE code_set_group_id
                                  END AS CODE_SET_GROUP_ID,
                              RDB_COLUMN_NM,
                              ANSWER_TXT,
                              ACT_UID AS INTERVIEW_UID,
                              RECORD_STATUS_CD,
                              NBS_QUESTION_UID,
                              CASE
                                  WHEN code_set_group_id IS NULL THEN 'CODED'
                                  ELSE data_type
                                  END AS DATA_TYPE,
                              rdb_table_nm,
                              answer_group_seq_nbr
              FROM dbo.v_rdb_ui_metadata_answers WITH (NOLOCK)
              WHERE ACT_UID IN (SELECT value FROM STRING_SPLIT(@ix_uids, ','))) AS metadata
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL AS CVG WITH (NOLOCK)
                            ON UPPER(CVG.CODE) = UPPER(DATA_TYPE)
        WHERE CVG.CODE_SET_NM = 'NBS_DATA_TYPE'
          AND UPPER(data_type) = 'CODED'
          AND rdb_table_nm = 'D_INTERVIEW'
          AND ANSWER_GROUP_SEQ_NBR IS NULL;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_table;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_SNM';

        SELECT CODED.CODE_SET_GROUP_ID,
               INTERVIEW_UID,
               NBS_QUESTION_UID,
               nbs_answer_uid,
               REPLACE(answer_txt, ' ', '') + ' ' + REPLACE(CODE_SHORT_DESC_TXT, ' ', '') AS ANSWER_TXT,
               CVG.CODE_SET_NM,
               RDB_COLUMN_NM,
               ANSWER_OTH,
               CVG.CODE,
               CODE_SHORT_DESC_TXT                                                        AS ANSWER_TXT2,
               rdb_column_nm2
        INTO #coded_table_snm
        FROM #coded_table AS CODED
                 LEFT JOIN NBS_SRTE.DBO.CODESET_GROUP_METADATA AS METADATA WITH (NOLOCK)
                           ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
                 LEFT JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL AS CVG WITH (NOLOCK)
                           ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
                               AND CVG.CODE = CODED.ANSWER_OTH
        WHERE ANSWER_OTH IS NOT NULL
          AND ANSWER_TXT <> 'OTH';


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_table_snm;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_NONSNM';

        SELECT CODED.CODE_SET_GROUP_ID,
               INTERVIEW_UID,
               NBS_QUESTION_UID,
               NBS_ANSWER_UID,
               ANSWER_TXT,
               CVG.CODE_SET_NM,
               RDB_COLUMN_NM,
               ANSWER_OTH,
               RDB_COLUMN_NM2,
               CVG.CODE,
               CODE_SHORT_DESC_TXT AS ANSWER_TXT1
        INTO #coded_table_nonsnm
        FROM #coded_table AS CODED
                 LEFT JOIN NBS_SRTE.DBO.CODESET_GROUP_METADATA AS METADATA WITH (NOLOCK)
                           ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
                 LEFT JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL AS CVG WITH (NOLOCK)
                           ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
                               AND CVG.CODE = CODED.ANSWER_TXT
        WHERE nbs_answer_uid NOT IN (SELECT nbs_answer_uid FROM #coded_table_snm);


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_table_nonsnm;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_SNTEMP';

        SELECT NBS_ANSWER_UID,
               CODE_SET_GROUP_ID,
               RDB_COLUMN_NM,
               INTERVIEW_UID,
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
        FROM (SELECT DISTINCT NBS_ANSWER_UID,
                              NBS_QUESTION_UID,
                              ANSWER_TXT,
                              RDB_COLUMN_NM,
                              unit_value,
                              INVESTIGATION_FORM_CD,
                              CODE_SET_GROUP_ID,
                              QUESTION_GROUP_SEQ_NBR,
                              DATA_TYPE,
                              ACT_UID AS INTERVIEW_UID,
                              RECORD_STATUS_CD
              FROM dbo.v_rdb_ui_metadata_answers WITH (NOLOCK)
              WHERE RDB_TABLE_NM = 'D_INTERVIEW'
                AND QUESTION_GROUP_SEQ_NBR IS NULL
                AND (
                  (UPPER(DATA_TYPE) = 'NUMERIC' AND UPPER(mask) = 'NUM_TEMP') OR
                  (UPPER(DATA_TYPE) = 'NUMERIC' AND UPPER(mask) = 'NUM_SN' AND unit_type_cd = 'CODED')
                  )
                AND RDB_COLUMN_NM NOT LIKE '%_CD'
                AND ANSWER_GROUP_SEQ_NBR IS NULL) metadata
                 INNER JOIN NBS_SRTE.dbo.CODE_VALUE_GENERAL CVG WITH (NOLOCK)
                            ON UPPER(CVG.CODE) = UPPER(DATA_TYPE)
                                AND upper(data_type) = 'CODED';


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_table_sntemp;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_SNTEMP_TRANS';

        SELECT INTERVIEW_UID,
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
                 LEFT JOIN NBS_SRTE.dbo.CODESET_GROUP_METADATA METADATA WITH (NOLOCK)
                           ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
                 LEFT JOIN NBS_SRTE.dbo.CODE_VALUE_GENERAL CVG WITH (NOLOCK)
                           ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
                               AND CVG.CODE = CODED.ANSWER_TXT_CODE;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_table_sntemp_trans;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
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
               COALESCE(SNT.INTERVIEW_UID, SNM.INTERVIEW_UID, NONSNM.INTERVIEW_UID)          AS INTERVIEW_UID,
               COALESCE(SNT.NBS_QUESTION_UID, SNM.NBS_QUESTION_UID, NONSNM.NBS_QUESTION_UID) AS NBS_QUESTION_UID,
               COALESCE(snm.answer_oth, NONSNM.answer_oth)                                   AS ANSWER_OTH,
               COALESCE(snm.rdb_column_nm2, nonsnm.rdb_column_nm2)                           as rdb_column_nm2
        INTO #CODED_TABLE_SN_MERGED
        FROM #CODED_TABLE_SNTEMP_TRANS SNT
                 FULL OUTER JOIN #CODED_TABLE_SNM SNM
                                 ON SNT.RDB_COLUMN_NM = SNM.RDB_COLUMN_NM AND SNT.NBS_answer_UID = SNM.NBS_answer_UID
                 FULL OUTER JOIN #CODED_TABLE_NONSNM NONSNM
                                 ON (COALESCE(SNT.RDB_COLUMN_NM, SNM.RDB_COLUMN_NM) = NONSNM.RDB_COLUMN_NM
                                     AND COALESCE(SNT.nbs_answer_UID, SNM.nbs_answer_UID) = NONSNM.nbs_answer_UID);

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_table_sn_merged;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_SN_MERGED';

        WITH numbered_answers AS (SELECT INTERVIEW_UID,
                                         NBS_QUESTION_UID,
                                         ANSWER_TXT1,
                                         ROW_NUMBER() OVER (PARTITION BY INTERVIEW_UID, NBS_QUESTION_UID ORDER BY INTERVIEW_UID, NBS_QUESTION_UID) AS rn
                                  FROM #coded_table_sn_merged),
             aggregated_answers AS (SELECT INTERVIEW_UID,
                                           NBS_QUESTION_UID,
                                           STRING_AGG(TRIM(ANSWER_TXT1), ' | ')        AS ANSWER_DESC11

                                    FROM numbered_answers
                                    GROUP BY INTERVIEW_UID,
                                             NBS_QUESTION_UID)

        SELECT aa.INTERVIEW_UID,
               aa.NBS_QUESTION_UID,
               ctsm.RDB_COLUMN_NM,
               CASE
                   WHEN LEN(ANSWER_DESC11) > 0 AND RIGHT(RTRIM(ANSWER_DESC11), 1) = '|'
                       THEN LEFT(RTRIM(ANSWER_DESC11), LEN(RTRIM(ANSWER_DESC11)) - 1)
                   ELSE RTRIM(ANSWER_DESC11)
                   END AS ANSWER_DESC11,
               ctsm.NBS_ANSWER_UID
        into #coded_answer_descs
        FROM aggregated_answers aa
                 LEFT JOIN #CODED_TABLE_SN_MERGED CTSM
                           ON aa.INTERVIEW_UID = CTSM.INTERVIEW_UID
                               AND aa.NBS_QUESTION_UID = ctsm.NBS_QUESTION_UID;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_answer_descs;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_COUNTY_TABLE';

        SELECT CODED.CODE_SET_GROUP_ID,
               INTERVIEW_UID,
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
             NBS_SRTE.dbo.CODESET_GROUP_METADATA AS METADATA WITH (NOLOCK)
             ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
                 LEFT JOIN
             NBS_SRTE.dbo.V_STATE_COUNTY_CODE_VALUE AS CVG WITH (NOLOCK)
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
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_COUNTY_TABLE';

        WITH numbered_answers AS (SELECT INTERVIEW_UID,
                                         NBS_QUESTION_UID,
                                         ANSWER_TXT1,
                                         ROW_NUMBER() OVER (PARTITION BY INTERVIEW_UID, NBS_QUESTION_UID ORDER BY INTERVIEW_UID, NBS_QUESTION_UID) AS rn
                                  FROM #CODED_COUNTY_TABLE),
             aggregated_answers AS (SELECT INTERVIEW_UID,
                                           NBS_QUESTION_UID,
                                           STRING_AGG(TRIM(ANSWER_TXT1), ' | ')        AS ANSWER_DESC11
                                    FROM numbered_answers
                                    GROUP BY INTERVIEW_UID,
                                             NBS_QUESTION_UID)

        SELECT cctd.INTERVIEW_UID,
               cctd.NBS_QUESTION_UID,
               cct.RDB_COLUMN_NM,
               cct.NBS_ANSWER_UID,
               CASE
                   WHEN LEN(ANSWER_DESC11) > 0 AND RIGHT(RTRIM(ANSWER_DESC11), 1) = '|'
                       THEN LEFT(RTRIM(ANSWER_DESC11), LEN(RTRIM(ANSWER_DESC11)) - 1)
                   ELSE RTRIM(ANSWER_DESC11)
                   END AS ANSWER_DESC11
        into #coded_county_table_desc
        FROM aggregated_answers cctd
                 LEFT JOIN #CODED_COUNTY_TABLE cct
                           ON cctd.interview_uid = cct.INTERVIEW_UID
                               AND cctd.NBS_QUESTION_UID = cct.INTERVIEW_UID;


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_county_table_desc;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_OTH';

        SELECT CODED.CODE_SET_GROUP_ID,
               INTERVIEW_UID,
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
        FROM #CODED_TABLE_SN_MERGED AS CODED


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_table_oth;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CODED_TABLE_FINAL';

        SELECT COALESCE(CTO.RDB_COLUMN_NM, CCT.RDB_COLUMN_NM, CTSM.RDB_COLUMN_NM) AS RDB_COLUMN_NM,
               COALESCE(CTO.INTERVIEW_UID, CCT.INTERVIEW_UID, CTSM.INTERVIEW_UID) AS INTERVIEW_UID,
               COALESCE(CCT.ANSWER_DESC11, CTSM.ANSWER_DESC11)                    AS ANSWER_DESC11
        INTO #CODED_TABLE_FINAL
        FROM #CODED_TABLE_OTH CTO
                 FULL OUTER JOIN #CODED_COUNTY_TABLE_DESC CCT
                                 ON CTO.RDB_COLUMN_NM = CCT.RDB_COLUMN_NM AND CTO.NBS_answer_UID = CCT.NBS_answer_UID
                 FULL OUTER JOIN #CODED_ANSWER_DESCS CTSM
                                 ON (COALESCE(CTO.RDB_COLUMN_NM, CCT.RDB_COLUMN_NM) = CTSM.RDB_COLUMN_NM
                                     AND COALESCE(CTO.nbs_answer_UID, CCT.nbs_answer_UID) = CTSM.nbs_answer_UID);


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #coded_table_FINAL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #TEXT_FINAL';

        SELECT NBS_ANSWER_UID,
               RDB_COLUMN_NM,
               ANSWER_TXT,
               INTERVIEW_UID,
               NBS_QUESTION_UID
        INTO #TEXT_FINAL
        FROM (SELECT DISTINCT NBS_ANSWER_UID,
                              CODE_SET_GROUP_ID,
                              RDB_COLUMN_NM,
                              ANSWER_TXT,
                              ACT_UID AS INTERVIEW_UID,
                              RECORD_STATUS_CD,
                              NBS_QUESTION_UID,
                              data_type,
                              rdb_table_nm,
                              answer_group_seq_nbr
              from dbo.v_rdb_ui_metadata_answers WITH (NOLOCK)
              WHERE ACT_UID IN (SELECT value FROM STRING_SPLIT(@ix_uids, ','))) as metadata
                 INNER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL CVG WITH (NOLOCK)
                            ON UPPER(CVG.CODE) = UPPER(DATA_TYPE)
        WHERE CVG.CODE_SET_NM = 'NBS_DATA_TYPE'
          AND CODE = 'TEXT'
          and rdb_table_nm = 'D_INTERVIEW'
          AND ANSWER_GROUP_SEQ_NBR IS NULL


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #TEXT_FINAL;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #NUMERIC_BASE_DATA';

        SELECT NBS_ANSWER_UID,
               metadata.CODE_SET_GROUP_ID,
               RDB_COLUMN_NM,
               ANSWER_TXT,
               PA.ACT_UID AS INTERVIEW_UID,
               PA.RECORD_STATUS_CD,
               metadata.NBS_QUESTION_UID
        INTO #NUMERIC_BASE_DATA
        FROM (SELECT DISTINCT RDB_COLUMN_NM,
                              NBS_QUESTION_UID,
                              CODE_SET_GROUP_ID,
                              INVESTIGATION_FORM_CD,
                              QUESTION_GROUP_SEQ_NBR,
                              DATA_TYPE
              FROM dbo.v_rdb_ui_metadata_answers WITH (NOLOCK)
              WHERE RDB_TABLE_NM = 'D_INTERVIEW'
                AND QUESTION_GROUP_SEQ_NBR IS NULL
                AND UPPER(DATA_TYPE) = 'TEXT'
                AND data_location = 'NBS_ANSWER.ANSWER_TXT'
                AND ACT_UID IN (SELECT value FROM STRING_SPLIT(@ix_uids, ','))) metadata
                 LEFT JOIN
             NBS_ODSE.dbo.NBS_ANSWER AS PA WITH (NOLOCK)
             ON metadata.nbs_question_uid = PA.nbs_question_uid
                 INNER JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH (NOLOCK)
             ON UPPER(CVG.CODE) = UPPER(metadata.DATA_TYPE)
        WHERE CVG.CODE_SET_NM = 'NBS_DATA_TYPE'
          AND CVG.CODE IN ('Numeric', 'NUMERIC')
          AND PA.ANSWER_GROUP_SEQ_NBR IS NULL;


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #NUMERIC_BASE_DATA;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #NUMERIC_DATA1';

        SELECT NBS_ANSWER_UID,
               CODE_SET_GROUP_ID,
               RDB_COLUMN_NM,
               ANSWER_TXT,
               INTERVIEW_UID,
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
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
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
               INTERVIEW_UID,
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
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #NUMERIC_DATA_MERGED';

        SELECT COALESCE(B.NBS_ANSWER_UID, A.NBS_ANSWER_UID)       AS NBS_ANSWER_UID,
               COALESCE(B.CODE_SET_GROUP_ID, A.CODE_SET_GROUP_ID) AS CODE_SET_GROUP_ID,
               COALESCE(B.RDB_COLUMN_NM, A.RDB_COLUMN_NM)         AS RDB_COLUMN_NM,
               COALESCE(B.ANSWER_TXT, A.ANSWER_TXT)               AS ANSWER_TXT,
               COALESCE(B.INTERVIEW_UID, A.INTERVIEW_UID)         AS INTERVIEW_UID,
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
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #NUMERIC_DATA_TRANS';

        SELECT CODED.INTERVIEW_UID,
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
             NBS_SRTE.dbo.CODESET_GROUP_METADATA AS METADATA WITH (NOLOCK)
             ON METADATA.CODE_SET_GROUP_ID = CODED.UNIT_VALUE1
                 LEFT JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH (NOLOCK)
             ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
        WHERE CVG.CODE = CODED.ANSWER_CODED;


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #NUMERIC_DATA_TRANS;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #NUMERIC_DATA_TRANS1';

        SELECT DISTINCT CASE
                            WHEN INTERVIEW_UID IS NULL THEN 1
                            ELSE INTERVIEW_UID
                            END AS INTERVIEW_UID,
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
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);

        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #DATE_DATA';

        SELECT RDB_COLUMN_NM,
               COALESCE(PA.ACT_UID, 1)                                              AS INTERVIEW_UID,
               FORMAT(TRY_CAST(ANSWER_TXT AS datetime2), 'yyyy-MM-dd HH:mm:ss.fff') AS ANSWER_TXT1
        INTO #DATE_DATA
        FROM (SELECT DISTINCT RDB_COLUMN_NM,
                              NBS_QUESTION_UID,
                              CODE_SET_GROUP_ID,
                              INVESTIGATION_FORM_CD,
                              QUESTION_GROUP_SEQ_NBR,
                              DATA_TYPE
              FROM dbo.v_rdb_ui_metadata_answers WITH (NOLOCK)
              WHERE RDB_TABLE_NM = 'D_INTERVIEW'
                AND QUESTION_GROUP_SEQ_NBR IS NULL
                AND DATA_TYPE in ('Date/Time', 'Date', 'DATETIME', 'DATE')
                AND data_location = 'NBS_ANSWER.ANSWER_TXT'
                AND ACT_UID IN (SELECT value FROM STRING_SPLIT(@ix_uids, ','))) metadata
                 LEFT JOIN
             NBS_ODSE.dbo.NBS_ANSWER AS PA WITH (NOLOCK)
             ON metadata.nbs_question_uid = PA.nbs_question_uid
                 INNER JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH (NOLOCK)
             ON UPPER(CVG.CODE) = UPPER(metadata.DATA_TYPE)
        WHERE CVG.CODE_SET_NM = 'NBS_DATA_TYPE'
          AND CVG.CODE IN ('DATETIME', 'DATE')
          AND PA.ANSWER_GROUP_SEQ_NBR IS NULL;


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #DATE_DATA;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #UNIONED_DATA';


        WITH ud AS (SELECT INTERVIEW_UID,
                           RDB_COLUMN_NM,
                           ANSWER_DESC11 AS ANSWER_VAL
                    FROM #CODED_TABLE_FINAL
                    UNION ALL
                    SELECT INTERVIEW_UID,
                           RDB_COLUMN_NM,
                           ANSWER_TXT1 AS ANSWER_VAL
                    FROM #DATE_DATA
                    UNION ALL
                    SELECT INTERVIEW_UID,
                           RDB_COLUMN_NM,
                           ANSWER_TXT AS ANSWER_VAL
                    FROM #NUMERIC_DATA_TRANS1
                    UNION ALL
                    SELECT INTERVIEW_UID,
                           RDB_COLUMN_NM,
                           ANSWER_TXT AS ANSWER_VAL
                    FROM #TEXT_FINAL)
        SELECT INTERVIEW_UID,
               RDB_COLUMN_NM,
               ANSWER_VAL
        INTO #UNIONED_DATA
        FROM ud

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #UNIONED_DATA;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #INTERVIEW_NOTE_INIT';

        SELECT DISTINCT ANSWER_TXT,
                        NBS_ANSWER_UID,
                        ACT_UID                                                AS INTERVIEW_UID,
                        LEFT(ANSWER_TXT, CHARINDEX('~', ANSWER_TXT + '~') - 1) AS [USER],
                        RECORD_STATUS_CD
        INTO #INTERVIEW_NOTE_INIT
        FROM dbo.v_rdb_ui_metadata_answers WITH (NOLOCK)
        WHERE act_uid in (SELECT value FROM STRING_SPLIT(@ix_uids, ','))
          AND QUESTION_IDENTIFIER = 'IXS111'
          AND RDB_TABLE_NM = 'D_INTERVIEW_NOTE';

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #INTERVIEW_NOTE_INIT;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #INTERVIEW_NOTE';

        SELECT DISTINCT ANSWER_TXT,
                        NBS_ANSWER_UID,
                        INTERVIEW_UID,
                        [USER],
                        LEFT([USER], CHARINDEX(' ', [USER] + ' ') - 1) AS USER_FIRST_NAME,
                        SUBSTRING(
                                        [USER],
                                        CHARINDEX(' ', [USER] + ' ') + 1,
                                        LEN(USER)
                        )                                              AS USER_LAST_NAME,
                        SUBSTRING(
                                ANSWER_TXT,
                                CHARINDEX('~~', ANSWER_TXT) + 2,
                                LEN(ANSWER_TXT)
                        )                                              AS USER_COMMENT,
                        TRY_CAST(
                                SUBSTRING(
                                        ANSWER_TXT,
                                        CHARINDEX('~', ANSWER_TXT) + 1,
                                        CHARINDEX('~', ANSWER_TXT + '~', CHARINDEX('~', ANSWER_TXT) + 1) -
                                        CHARINDEX('~', ANSWER_TXT) - 1
                                ) AS datetime
                        )                                              AS COMMENT_DATE
        INTO #INTERVIEW_NOTE
        FROM #INTERVIEW_NOTE_INIT

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #INTERVIEW_NOTE;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;

        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #D_INTERVIEW_COLUMNS';

        WITH ordered_list AS (SELECT 'D_INTERVIEW'                                                              AS TABLE_NAME,
                                     RDB_COLUMN_NM,
                                     1                                                                          AS NEW_FLAG,
                                     LAST_CHG_TIME,
                                     LAST_CHG_USER_ID,
                                     ROW_NUMBER() OVER (PARTITION BY RDB_COLUMN_NM ORDER BY LAST_CHG_TIME DESC) AS rn

                              FROM NBS_ODSE.dbo.NBS_rdb_metadata WITH (NOLOCK)
                              WHERE RDB_TABLE_NM = 'D_INTERVIEW'
                                AND RDB_COLUMN_NM NOT IN (
                                                          'IX_STATUS',
                                                          'IX_TYPE',
                                                          'IX_INTERVIEWEE_ROLE',
                                                          'IX_DATE',
                                                          'IX_LOCATION'
                                  ))
        SELECT TABLE_NAME,
               RDB_COLUMN_NM,
               NEW_FLAG,
               LAST_CHG_TIME,
               LAST_CHG_USER_ID
        INTO #D_INTERVIEW_COLUMNS
        FROM ordered_list
        where rn = 1


        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #D_INTERVIEW_COLUMNS;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


        COMMIT TRANSACTION;


        BEGIN
            TRANSACTION;
        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'SELECT FULL INTERVIEW DATA';

        SELECT ix.INTERVIEW_UID,
               ix.INTERVIEW_STATUS_CD,
               ix.INTERVIEW_DATE,
               ix.INTERVIEWEE_ROLE_CD,
               ix.INTERVIEW_TYPE_CD,
               ix.INTERVIEW_LOC_CD,
               ix.LOCAL_ID,
               ix.RECORD_STATUS_CD,
               ix.RECORD_STATUS_TIME,
               ix.ADD_TIME,
               ix.ADD_USER_ID,
               ix.last_chg_time,
               ix.LAST_CHG_USER_ID,
               ix.VERSION_CTRL_NBR,
               ix.IX_STATUS,
               ix.IX_INTERVIEWEE_ROLE,
               ix.IX_TYPE,
               ix.IX_LOCATION,
               ix.INVESTIGATION_UID,
               ix.PROVIDER_UID,
               ix.ORGANIZATION_UID,
               ix.PATIENT_UID,
               nesteddata.answers,
               nesteddata.notes,
               nesteddata.rdb_cols
        FROM #INTERVIEW_INIT ix
                 OUTER apply (SELECT *
                              FROM (SELECT (SELECT ud.RDB_COLUMN_NM,
                                                   ud.ANSWER_VAL
                                            FROM #UNIONED_DATA ud
                                            WHERE ud.interview_uid = ix.interview_uid
                                            FOR json path,INCLUDE_NULL_VALUES) AS answers) AS answers,
                                   (SELECT (SELECT NBS_ANSWER_UID,
                                                   USER_FIRST_NAME,
                                                   USER_LAST_NAME,
                                                   USER_COMMENT,
                                                   COMMENT_DATE,
                                                   RECORD_STATUS_CD
                                            FROM #INTERVIEW_NOTE ixnote
                                            WHERE ixnote.interview_uid = ix.interview_uid
                                            FOR json path,INCLUDE_NULL_VALUES) AS notes) AS notes,
                                   (SELECT (SELECT TABLE_NAME,
                                                   RDB_COLUMN_NM,
                                                   NEW_FLAG,
                                                   LAST_CHG_TIME,
                                                   LAST_CHG_USER_ID
                                            FROM #D_INTERVIEW_COLUMNS
                                            FOR json path,INCLUDE_NULL_VALUES) AS rdb_cols) AS rdb_cols) AS nesteddata


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, 'Interview PRE-Processing Event', 'nrt_interview', 'START', @Proc_Step_no, @Proc_Step_Name,
                @RowCount_no);


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
               , 'Interview PRE-Processing Event'
               , 'NBS_ODSE.sp_interview_event'
               , 'COMPLETE'
               , 0
               , LEFT('Pre ID-' + @ix_uids, 199)
               , 0
               , LEFT(@ix_uids, 199));

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
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
               , 'Interview PRE-Processing Event'
               , 'NBS_ODSE.sp_interview_event'
               , 'ERROR: ' + @ErrorMessage
               , 0
               , LEFT('Pre ID-' + @ix_uids, 199)
               , 0
               , LEFT(@ix_uids, 199));
        return @ErrorMessage;

    END CATCH

END;