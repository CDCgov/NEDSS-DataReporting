IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_contact_record_event]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_contact_record_event]
END
GO

CREATE PROCEDURE [dbo].[sp_contact_record_event] @cc_uids nvarchar(max),
                                                     @debug bit = 'false'
AS
BEGIN

    DECLARE
        @RowCount_no INT;
    DECLARE
        @Proc_Step_no FLOAT = 0;
    DECLARE
        @Proc_Step_Name VARCHAR(200) = 'Contact_Record PRE-Processing Event';
    DECLARE
        @Dataflow_Name VARCHAR(200) = 'Contact_Record PRE-Processing Event';
    DECLARE
        @Package_Name VARCHAR(200) = 'NBS_ODSE.sp_contact_record_event';

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
           , LEFT('Pre ID-' + @cc_uids, 199)
           , 0
           , LEFT(@cc_uids, 199));

    BEGIN TRANSACTION;
    SET
        @PROC_STEP_NO = @PROC_STEP_NO + 1;
    SET
        @PROC_STEP_NAME = 'GENERATING #CONTACT_RECORD_INIT';


    SELECT
        cc.ADD_TIME,
        cc.ADD_USER_ID ,
        cc.CONTACT_ENTITY_EPI_LINK_ID AS CONTACT_ENTITY_EPI_LINK_ID ,
        cc.CONTACT_ENTITY_PHC_UID AS CONTACT_ENTITY_PHC_UID ,
        cc.CONTACT_ENTITY_UID AS CONTACT_ENTITY_UID ,
        cc.CONTACT_REFERRAL_BASIS_CD,
        case
            when (cc.CONTACT_STATUS is not null or cc.CONTACT_STATUS != '')
                then (select * from nbs_odse.dbo.fn_get_value_by_cd_codeset(cc.CONTACT_STATUS, 'INV109'))
            end as CTT_STATUS,
        cc.CT_CONTACT_UID,
        cc.DISPOSITION_CD,
        cc.DISPOSITION_DATE AS CTT_DISPO_DT,
        cc.EVALUATION_COMPLETED_CD,
        cc.EVALUATION_DATE AS CTT_EVAL_DT ,
        cc.EVALUATION_TXT AS CTT_EVAL_NOTES ,
        cc.GROUP_NAME_CD,
        cc.HEALTH_STATUS_CD,
        cc.INVESTIGATOR_ASSIGNED_DATE AS CTT_INV_ASSIGNED_DT ,
        cc.JURISDICTION_CD,
        cc.LAST_CHG_TIME AS LAST_CHG_TIME ,
        cc.LAST_CHG_USER_ID AS LAST_CHG_USER_ID ,
        cc.LOCAL_ID AS LOCAL_ID ,
        cc.NAMED_DURING_INTERVIEW_UID,
        cc.NAMED_ON_DATE AS CTT_NAMED_ON_DT ,
        cc.PRIORITY_CD,
        cc.PROCESSING_DECISION_CD,
        cc.PROG_AREA_CD,
        cc.PROGRAM_JURISDICTION_OID AS PROGRAM_JURISDICTION_OID ,
        cc.RECORD_STATUS_CD AS RECORD_STATUS_CD  ,
        cc.RECORD_STATUS_TIME AS RECORD_STATUS_TIME ,
        cc.RELATIONSHIP_CD,
        cc.RISK_FACTOR_CD,
        cc.RISK_FACTOR_TXT AS CTT_RISK_NOTES ,
        cc.SHARED_IND_CD,
        cc.SUBJECT_ENTITY_EPI_LINK_ID AS SUBJECT_ENTITY_EPI_LINK_ID ,
        cc.SUBJECT_ENTITY_PHC_UID,
        cc.SUBJECT_ENTITY_UID,
        cc.SYMPTOM_CD,
        cc.SYMPTOM_ONSET_DATE AS CTT_SYMP_ONSET_DT ,
        cc.SYMPTOM_TXT AS CTT_SYMP_NOTES ,
        cc.THIRD_PARTY_ENTITY_PHC_UID,
        cc.THIRD_PARTY_ENTITY_UID,
        cc.TREATMENT_END_CD,
        cc.TREATMENT_END_DATE AS CTT_TRT_END_DT ,
        cc.TREATMENT_INITIATED_CD,
        cc.TREATMENT_NOT_END_RSN_CD,
        cc.TREATMENT_NOT_START_RSN_CD,
        cc.TREATMENT_START_DATE AS CTT_TRT_START_DT ,
        cc.TREATMENT_TXT AS CTT_TRT_NOTES ,
        cc.TXT AS CTT_NOTES,
        pac.prog_area_desc_txt as CTT_PROGRAM_AREA,
        jc.code_desc_txt as CTT_JURISDICTION_NM ,
        case when cvg1.code_short_desc_txt is null  then cc.SHARED_IND_CD else cvg1.code_short_desc_txt end as CTT_SHARED_IND,
        cvg2.code_short_desc_txt as CTT_SYMP_IND,
        cvg3.code_short_desc_txt as CTT_RISK_IND ,
        cvg4.code_short_desc_txt as CTT_EVAL_COMPLETED ,
        cvg5.code_short_desc_txt as CTT_TRT_INITIATED_IND  ,
        cvg6.code_short_desc_txt as CTT_DISPOSITION,
        cvg7.code_short_desc_txt as CTT_PRIORITY,
        cvg8.code_short_desc_txt as CTT_RELATIONSHIP ,
        cvg9.code_short_desc_txt as CTT_TRT_NOT_START_RSN  ,
        cvg10.code_short_desc_txt as CTT_TRT_NOT_COMPLETE_RSN,
        cvg11.code_short_desc_txt as CTT_PROCESSING_DECISION ,
        cvg12.code_short_desc_txt as CTT_GROUP_LOT_ID  ,
        cvg13.code_short_desc_txt as CTT_TRT_COMPLETE_IND,
        cvg14.code_short_desc_txt as CTT_HEALTH_STATUS,
        cvg15.code_short_desc_txt as CTT_REFERRAL_BASIS,
        cc.version_ctrl_nbr,
        act_entities1.entity_uid as CONTACT_EXPOSURE_SITE_UID,
        act_entities2.entity_uid as PROVIDER_CONTACT_INVESTIGATOR_UID,
        act_entities3.entity_uid as DISPOSITIONED_BY_UID
    into #CONTACT_RECORD_INIT
    from nbs_odse.dbo.CT_CONTACT cc  with (nolock)
    left outer join nbs_srte.dbo.PROGRAM_AREA_CODE pac with (nolock) on cc.prog_area_cd  = pac.prog_area_cd
    left outer join nbs_srte.dbo.JURISDICTION_CODE jc with (nolock) on cc.JURISDICTION_CD  = jc.code and jc.code_set_nm = 'S_JURDIC_C'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg1 with (nolock) on cc.SHARED_IND_CD  = cvg1.code and cvg1.code_set_nm = 'YN'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg2 with (nolock) on cc.SYMPTOM_CD  = cvg2.code and cvg2.code_set_nm = 'YNU'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg3 with (nolock) on cc.RISK_FACTOR_CD  = cvg3.code and cvg3.code_set_nm = 'YNU'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg4 with (nolock) on cc.EVALUATION_COMPLETED_CD  = cvg4.code and cvg4.code_set_nm = 'YNU'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg5 with (nolock) on cc.TREATMENT_INITIATED_CD  = cvg5.code and cvg5.code_set_nm = 'YNU'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg6 with (nolock) on cc.DISPOSITION_CD  = cvg6.code and cvg6.code_set_nm in ( 'NBS_DISPO', 'FIELD_FOLLOWUP_DISPOSITION_STD')
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg7 with (nolock) on cc.PRIORITY_CD  = cvg7.code and cvg7.code_set_nm = 'NBS_PRIORITY'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg8 with (nolock) on cc.RELATIONSHIP_CD  = cvg8.code and cvg8.code_set_nm = 'NBS_RELATIONSHIP'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg9 with (nolock) on cc.TREATMENT_NOT_START_RSN_CD  = cvg9.code and cvg9.code_set_nm = 'NBS_NO_TRTMNT_REAS'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg10 with (nolock) on cc.TREATMENT_NOT_END_RSN_CD  = cvg10.code and cvg10.code_set_nm = 'NBS_NO_TRTMNT_REAS'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg11 with (nolock) on cc.PROCESSING_DECISION_CD  = cvg11.code and cvg11.code_set_nm = 'STD_CONTACT_RCD_PROCESSING_DECISION'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg12 with (nolock) on cc.GROUP_NAME_CD  = cvg12.code and cvg12.code_set_nm = 'NBS_GROUP_NM'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg13 with (nolock) on cc.TREATMENT_END_CD  = cvg13.code and cvg13.code_set_nm = 'YNU'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg14 with (nolock) on cc.HEALTH_STATUS_CD  = cvg14.code and cvg14.code_set_nm = 'NBS_HEALTH_STATUS'
    left outer join nbs_srte.dbo.CODE_VALUE_GENERAL cvg15 with (nolock) on cc.CONTACT_REFERRAL_BASIS_CD  = cvg15.code and cvg15.code_set_nm = 'REFERRAL_BASIS'
	left outer join nbs_odse.dbo.NBS_ACT_ENTITY act_entities1 with (nolock) on cc.CT_CONTACT_UID = act_entities1.ACT_UID and act_entities1.TYPE_CD='SiteOfExposure'
	left outer join nbs_odse.dbo.NBS_ACT_ENTITY act_entities2 with (nolock) on cc.CT_CONTACT_UID = act_entities2.ACT_UID and act_entities2.TYPE_CD='InvestgrOfContact'
	left outer join nbs_odse.dbo.NBS_ACT_ENTITY act_entities3 with (nolock) on cc.CT_CONTACT_UID = act_entities3.ACT_UID and act_entities3.TYPE_CD='DispoInvestgrOfConRec'
    where CT_CONTACT_UID in (SELECT value FROM STRING_SPLIT(@cc_uids, ','));

    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #CONTACT_RECORD_INIT;


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
        CT_CONTACT_UID
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
            CT_CONTACT_UID,
            RECORD_STATUS_CD,
            NBS_QUESTION_UID,
            CASE
                WHEN code_set_group_id IS NULL THEN 'CODED'
                ELSE data_type
            END AS DATA_TYPE,
            rdb_table_nm,
            answer_group_seq_nbr
        FROM dbo.V_RDB_UI_METADATA_ANSWERS_CONTACT
        WHERE
        CODE_SET_NM = 'NBS_DATA_TYPE'
      AND UPPER(data_type) = 'CODED'
      AND rdb_table_nm = 'D_CONTACT_RECORD'
      AND ANSWER_GROUP_SEQ_NBR IS NULL
      AND CT_CONTACT_UID IN (SELECT value FROM STRING_SPLIT(@cc_uids, ','))
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
           CT_CONTACT_UID,
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
             LEFT JOIN NBS_SRTE.DBO.CODESET_GROUP_METADATA metadata WITH (NOLOCK)
                       ON metadata.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
             LEFT JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL cvg WITH (NOLOCK)
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
           CT_CONTACT_UID,
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
    LEFT JOIN nbs_srte.dbo.CODESET_GROUP_METADATA metadata WITH (NOLOCK)
            ON metadata.CODE_SET_GROUP_ID = coded.CODE_SET_GROUP_ID
    LEFT JOIN nbs_srte.dbo.CODE_VALUE_GENERAL cvg WITH (NOLOCK)
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
	    CT_CONTACT_UID,
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
	        CT_CONTACT_UID,
	        RECORD_STATUS_CD
        FROM dbo.V_RDB_UI_METADATA_ANSWERS_CONTACT
        WHERE RDB_TABLE_NM = 'D_CONTACT_RECORD'
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


    SELECT CT_CONTACT_UID,
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
    LEFT JOIN nbs_srte.dbo.CODESET_GROUP_METADATA metadata WITH (NOLOCK)
            ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
    LEFT JOIN nbs_srte.dbo.CODE_VALUE_GENERAL CVG WITH (NOLOCK)
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
        COALESCE(SNT.CT_CONTACT_UID, SNM.CT_CONTACT_UID, NONSNM.CT_CONTACT_UID)          AS CT_CONTACT_UID,
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
        SELECT CT_CONTACT_UID,
            NBS_QUESTION_UID,
            STRING_AGG(TRIM(ANSWER_TXT1), ' | ')        AS ANSWER_DESC11

        FROM #coded_table_sn_merged
        GROUP BY CT_CONTACT_UID,
                NBS_QUESTION_UID
    )
    SELECT
        aa.CT_CONTACT_UID,
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
            ON aa.CT_CONTACT_UID = CTSM.CT_CONTACT_UID
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
        CT_CONTACT_UID,
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
        nbs_srte.dbo.CODESET_GROUP_METADATA AS METADATA WITH (NOLOCK)
        ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID
    LEFT JOIN
        nbs_srte.dbo.V_STATE_COUNTY_CODE_VALUE AS CVG WITH (NOLOCK)
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
            CT_CONTACT_UID,
            NBS_QUESTION_UID,
            STRING_AGG(TRIM(ANSWER_TXT1),
            ' | ') AS ANSWER_DESC11
        FROM
            #CODED_COUNTY_TABLE
        GROUP BY
            CT_CONTACT_UID,
            NBS_QUESTION_UID
    )
    SELECT
        cctd.CT_CONTACT_UID,
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
        cctd.CT_CONTACT_UID = cct.CT_CONTACT_UID
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
        CT_CONTACT_UID,
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
                COALESCE(CTO.CT_CONTACT_UID, CCT.CT_CONTACT_UID, CTSM.CT_CONTACT_UID) AS CT_CONTACT_UID,
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
        CT_CONTACT_UID,
        NBS_QUESTION_UID
    INTO #TEXT_FINAL
    FROM (
    	SELECT DISTINCT
	        NBS_ANSWER_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT,
	        CT_CONTACT_UID,
	        NBS_QUESTION_UID
        FROM dbo.V_RDB_UI_METADATA_ANSWERS_CONTACT
        WHERE
        CODE_SET_NM = 'NBS_DATA_TYPE'
        AND CODE = 'TEXT'
        AND rdb_table_nm = 'D_CONTACT_RECORD'
        AND ANSWER_GROUP_SEQ_NBR IS NULL
        AND CT_CONTACT_UID IN (SELECT value FROM STRING_SPLIT(@cc_uids, ','))
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
        CT_CONTACT_UID,
        NBS_QUESTION_UID,
        RECORD_STATUS_CD
    INTO #NUMERIC_BASE_DATA
    FROM (
    	SELECT DISTINCT
	    	NBS_ANSWER_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT,
	        CT_CONTACT_UID,
	        NBS_QUESTION_UID,
	        CODE_SET_GROUP_ID,
	        RECORD_STATUS_CD
        FROM dbo.V_RDB_UI_METADATA_ANSWERS_CONTACT
        WHERE RDB_TABLE_NM = 'D_CONTACT_RECORD'
            AND QUESTION_GROUP_SEQ_NBR IS NULL
            AND ANSWER_GROUP_SEQ_NBR IS NULL
            AND data_location = 'CT_CONTACT_ANSWER.ANSWER_TXT'
            AND CODE_SET_NM = 'NBS_DATA_TYPE'
	    	AND CODE IN ('Numeric', 'NUMERIC')
            AND CT_CONTACT_UID IN (SELECT value FROM STRING_SPLIT(@cc_uids, ','))
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
        CT_CONTACT_UID,
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
        CT_CONTACT_UID,
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
           COALESCE(B.CT_CONTACT_UID, A.CT_CONTACT_UID)         AS CT_CONTACT_UID,
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

    SELECT CODED.CT_CONTACT_UID,
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
         nbs_srte.dbo.CODESET_GROUP_METADATA AS METADATA WITH (NOLOCK)
         ON METADATA.CODE_SET_GROUP_ID = CODED.UNIT_VALUE1
             LEFT JOIN
         nbs_srte.dbo.CODE_VALUE_GENERAL AS CVG WITH (NOLOCK)
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
                        WHEN CT_CONTACT_UID IS NULL THEN 1
                        ELSE CT_CONTACT_UID
                        END AS CT_CONTACT_UID,
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

    SELECT
        RDB_COLUMN_NM,
        CT_CONTACT_UID,
        case
            when trim(ANSWER_TXT)='' then ''
            else FORMAT(TRY_CAST(ANSWER_TXT AS datetime2), 'yyyy-MM-dd HH:mm:ss.fff')
        end as ANSWER_TXT1
    INTO #DATE_DATA
    FROM (
    	SELECT DISTINCT
    	    CT_CONTACT_UID,
    		RDB_COLUMN_NM,
           NBS_QUESTION_UID,
              CODE_SET_GROUP_ID,
              INVESTIGATION_FORM_CD,
              QUESTION_GROUP_SEQ_NBR,
              ANSWER_TXT,
              DATA_TYPE
          FROM dbo.V_RDB_UI_METADATA_ANSWERS_CONTACT
          WHERE RDB_TABLE_NM = 'D_CONTACT_RECORD'
            AND QUESTION_GROUP_SEQ_NBR IS NULL
            AND data_location = 'CT_CONTACT_ANSWER.ANSWER_TXT'
            AND CODE_SET_NM = 'NBS_DATA_TYPE'
		      AND CODE IN ('DATETIME', 'DATE')
		      AND ANSWER_GROUP_SEQ_NBR IS NULL
            AND CT_CONTACT_UID IN (SELECT value FROM STRING_SPLIT(@cc_uids, ','))
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
	    SELECT CT_CONTACT_UID,
	       RDB_COLUMN_NM,
	       ANSWER_DESC11 AS ANSWER_VAL
	    FROM #CODED_TABLE_FINAL
	    UNION ALL
	    SELECT CT_CONTACT_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT1 AS ANSWER_VAL
	    FROM #DATE_DATA
	    UNION ALL
	    SELECT CT_CONTACT_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT AS ANSWER_VAL
	    FROM #NUMERIC_DATA_TRANS1
	    UNION ALL
	    SELECT CT_CONTACT_UID,
	        RDB_COLUMN_NM,
	        ANSWER_TXT AS ANSWER_VAL
	    FROM #TEXT_FINAL
    )
    SELECT CT_CONTACT_UID,
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
        @PROC_STEP_NAME = 'GENERATING #D_CONTACT_RECORD_COLUMNS';


    WITH ordered_list AS (
        SELECT RDB_TABLE_NM as TABLE_NAME,
            RDB_COLUMN_NM,
            1                                                                          AS NEW_FLAG,
            LAST_CHG_TIME,
            LAST_CHG_USER_ID,
            ROW_NUMBER() OVER (PARTITION BY RDB_COLUMN_NM ORDER BY LAST_CHG_TIME DESC) AS rn

        FROM NBS_ODSE.dbo.NBS_rdb_metadata WITH (NOLOCK)
        WHERE RDB_TABLE_NM = 'D_CONTACT_RECORD' and RDB_COLUMN_NM in (select RDB_COLUMN_NM from #UNIONED_DATA)
    )
    SELECT distinct TABLE_NAME,
           RDB_COLUMN_NM,
           NEW_FLAG,
           LAST_CHG_TIME,
           LAST_CHG_USER_ID
    INTO #D_CONTACT_RECORD_COLUMNS
    FROM ordered_list
    where rn = 1;


    if
        @debug = 'true'
        select @Proc_Step_Name as step, *
        from #D_CONTACT_RECORD_COLUMNS;

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
        @PROC_STEP_NAME = 'SELECT FULL CONTACT DATA';

    SELECT ADD_TIME,
    ADD_USER_ID ,
    CONTACT_ENTITY_EPI_LINK_ID ,
    CONTACT_ENTITY_PHC_UID ,
    CONTACT_ENTITY_UID ,
    CONTACT_REFERRAL_BASIS_CD,
    CTT_STATUS,
    CT_CONTACT_UID,
    DISPOSITION_CD,
    CTT_DISPO_DT,
    EVALUATION_COMPLETED_CD,
    CTT_EVAL_DT ,
    CTT_EVAL_NOTES ,
    GROUP_NAME_CD,
    HEALTH_STATUS_CD,
    CTT_INV_ASSIGNED_DT ,
    JURISDICTION_CD,
    LAST_CHG_TIME ,
    LAST_CHG_USER_ID ,
    LOCAL_ID ,
    NAMED_DURING_INTERVIEW_UID,
    CTT_NAMED_ON_DT ,
    PRIORITY_CD,
    PROCESSING_DECISION_CD,
    PROG_AREA_CD,
    PROGRAM_JURISDICTION_OID ,
    RECORD_STATUS_CD  ,
    RECORD_STATUS_TIME ,
    RELATIONSHIP_CD,
    RISK_FACTOR_CD,
    CTT_RISK_NOTES ,
    SHARED_IND_CD,
    SUBJECT_ENTITY_EPI_LINK_ID ,
    SUBJECT_ENTITY_PHC_UID,
    SUBJECT_ENTITY_UID,
    SYMPTOM_CD,
    CTT_SYMP_ONSET_DT ,
    CTT_SYMP_NOTES ,
    THIRD_PARTY_ENTITY_PHC_UID,
    THIRD_PARTY_ENTITY_UID,
    TREATMENT_END_CD,
    CTT_TRT_END_DT ,
    TREATMENT_INITIATED_CD,
    TREATMENT_NOT_END_RSN_CD,
    TREATMENT_NOT_START_RSN_CD,
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
    VERSION_CTRL_NBR,
    CONTACT_EXPOSURE_SITE_UID,
    PROVIDER_CONTACT_INVESTIGATOR_UID,
    DISPOSITIONED_BY_UID,
    nesteddata.answers,
    nesteddata.rdb_cols
    FROM #CONTACT_RECORD_INIT ix
    OUTER apply (
        SELECT * FROM
            (SELECT (SELECT ud.RDB_COLUMN_NM,
                               ud.ANSWER_VAL
                        FROM #UNIONED_DATA ud
                        WHERE ud.CT_CONTACT_UID = ix.CT_CONTACT_UID
                        FOR json path,INCLUDE_NULL_VALUES) AS answers) AS answers,
            (SELECT (SELECT TABLE_NAME,
                           RDB_COLUMN_NM,
                           NEW_FLAG,
                           LAST_CHG_TIME,
                           LAST_CHG_USER_ID
                    FROM #D_CONTACT_RECORD_COLUMNS
                    FOR json path,INCLUDE_NULL_VALUES) AS rdb_cols) AS rdb_cols
    ) AS nesteddata;


    SELECT @RowCount_no = @@ROWCOUNT;

    INSERT INTO [rdb_modern].[dbo].[job_flow_log]
    (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
    VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name,
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
           , @Dataflow_Name
           , @Package_Name
           , 'COMPLETE'
           , 0
           , LEFT('Pre ID-' + @cc_uids, 199)
           , 0
           , LEFT(@cc_uids, 199));

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

         DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Msg_Description1]
        , [Error_Description])
        VALUES ( @batch_id
               , @Dataflow_Name
               , @Package_Name
               , 'ERROR'
               , @Proc_Step_no
               , @Proc_Step_Name
               , 0
               , LEFT(@cc_uids, 199)
               ,@FullErrorMessage
        );
        return -1;

    END CATCH

END;