CREATE OR ALTER PROCEDURE dbo.sp_repeated_place_postprocessing
    @Batch_id bigint,
    @phc_id bigint,
    @debug bit = 'false'
AS

BEGIN

    BEGIN TRY

        DECLARE @rowcount INT;
        DECLARE @dataflow_name varchar(200) = 'INV_PLACE_REPEAT';
        DECLARE @package_name varchar(200) = 'D_INV_PLACE_REPEAT';
        DECLARE @Proc_Step_no FLOAT = 0 ;
        DECLARE @Proc_Step_Name VARCHAR(200) = '' ;

        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [msg_description1])
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , 0
               , 'SP_Start'
               , 0
               ,LEFT(CAST(@phc_id AS VARCHAR(10)), 500));

        SET @proc_step_name = 'Create PLACE_INIT_OUT Temp table -' + CAST(@phc_id AS VARCHAR(10));
        SET @proc_step_no = 1;

        SELECT
            DISTINCT
            CASE WHEN len(ANSWER_TXT) - len(REPLACE(ANSWER_TXT,'^',''))<2 THEN REPLACE(CONCAT(ANSWER_TXT,'^'),' ','')
                 ELSE ANSWER_TXT END AS ANSWER_TXT,
            ACT_UID AS 'PAGE_CASE_UID',
            ANSWER_GROUP_SEQ_NBR,
            NBS_QUESTION_UID,
            QUESTION_IDENTIFIER,
            PART_TYPE_CD
        INTO #PLACE_INIT_OUT
        FROM
            dbo.nrt_page_case_answer NBS_CASE_ANSWER
        WHERE act_uid = @phc_id
          AND PART_TYPE_CD IN ('PlaceAsHangoutOfPHC','PlaceAsSexOfPHC')
        ORDER BY
            ACT_UID,
            ANSWER_GROUP_SEQ_NBR;

        IF @debug = 'true' SELECT '#PLACE_INIT_OUT', * FROM #PLACE_INIT_OUT;

        /* Logging */
        SET @rowcount = @@rowcount;
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Pivot PLACE_INIT_OUT';
        SET @proc_step_no = @proc_step_no + 1;


        with place_pivot as (
            SELECT
                PAGE_CASE_UID,
                ANSWER_GROUP_SEQ_NBR,
                [PlaceAsHangoutOfPHC] AS PlaceAsHangoutOfPHC,
                [PlaceAsSexOfPHC] AS PlaceAsSexOfPHC
            FROM
                (
                    SELECT
                        PAGE_CASE_UID,
                        ANSWER_GROUP_SEQ_NBR,
                        LTRIM(RTRIM(PART_TYPE_CD)) PART_TYPE_CD,
                        ANSWER_TXT
                    FROM
                        #PLACE_INIT_OUT) AS src_place
                    PIVOT
                    ( MAX(ANSWER_TXT)
                    FOR PART_TYPE_CD IN ([PlaceAsHangoutOfPHC], [PlaceAsSexOfPHC])
                    ) AS src_pivot
        )
        SELECT
            PAGE_CASE_UID,
            ANSWER_GROUP_SEQ_NBR,
            PlaceAsHangoutOfPHC,
            PlaceAsSexOfPHC,
            CASE temp.place WHEN  'PlaceAsHangoutOfPHC' THEN ISNULL(PlaceAsHangoutOfPHC,'')
                            ELSE '' END AS PLACE_HANGOUT_OF_PHC,
            CASE temp.place WHEN  'PlaceAsSexOfPHC' THEN ISNULL(PlaceAsSexOfPHC,'')
                            ELSE '' END AS PLACE_AS_SEX_OF_PHC
        INTO #PLACE_INIT
        FROM place_pivot p
                 CROSS APPLY (
            SELECT 'PlaceAsHangoutOfPHC' as place where p.PlaceAsHangoutOfPHC IS NOT NULL
            UNION ALL
            SELECT 'PlaceAsSexOfPHC' as place where p.PlaceAsSexOfPHC IS NOT NULL
        ) temp;

        IF @debug = 'true' SELECT '#PLACE_INIT', * FROM #PLACE_INIT;

        /* Logging */
        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Create #S_INV_PLACE_REPEAT';
        SET @proc_step_no = @proc_step_no + 1;

        SELECT
            PLACE_INIT.*, D_PLACE.*
        INTO #S_INV_PLACE_REPEAT
        FROM #PLACE_INIT PLACE_INIT
                 INNER JOIN DBO.D_PLACE ON D_PLACE.PLACE_LOCATOR_UID= PLACE_INIT.PLACE_AS_SEX_OF_PHC
            OR  D_PLACE.PLACE_LOCATOR_UID= PLACE_INIT.PLACE_HANGOUT_OF_PHC;

        IF @debug = 'true' SELECT '#S_INV_PLACE_REPEAT', * FROM #S_INV_PLACE_REPEAT;

        /* Logging */
        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Create L_INV_PLACE_REPEAT if missing';
        SET @proc_step_no = @proc_step_no + 1;


        IF OBJECT_ID('dbo.L_INV_PLACE_REPEAT', 'U') IS NULL
            BEGIN
                CREATE TABLE dbo.L_INV_PLACE_REPEAT(
                                                       PAGE_CASE_UID FLOAT NULL,
                                                       D_INV_PLACE_REPEAT_KEY FLOAT NULL
                )ON [PRIMARY];

                INSERT INTO dbo.L_INV_PLACE_REPEAT(PAGE_CASE_UID,D_INV_PLACE_REPEAT_KEY)
                VALUES (NULL, 1);

            END;

        /* Logging */
        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Create D_INV_PLACE_REPEAT if missing';
        SET @proc_step_no = @proc_step_no + 1;


        IF OBJECT_ID('dbo.D_INV_PLACE_REPEAT', 'U') IS NULL
            BEGIN
                CREATE TABLE [dbo].[D_INV_PLACE_REPEAT]
                (
                    PAGE_CASE_UID numeric(20,0) NULL,
                    answer_group_seq_nbr numeric(11,0) NULL,
                    PLACE_HANGOUT_OF_PHC varchar(2000) NULL,
                    PLACE_AS_SEX_OF_PHC varchar(2000) NULL,
                    PLACE_KEY float NULL,
                    PLACE_ADD_TIME datetime2(3) NULL,
                    PLACE_ADD_USER_ID numeric(21,0) NULL,
                    PLACE_ADDED_BY varchar(102) NULL,
                    PLACE_ADDRESS_COMMENTS varchar(2000) NULL,
                    PLACE_CITY varchar(100) NULL,
                    PLACE_COUNTRY varchar(20) NULL,
                    PLACE_COUNTRY_DESC varchar(50) NULL,
                    PLACE_COUNTY_CODE varchar(20) NULL,
                    PLACE_COUNTY_DESC varchar(255) NULL,
                    PLACE_EMAIL varchar(100) NULL,
                    PLACE_GENERAL_COMMENTS varchar(1000) NULL,
                    PLACE_LAST_CHANGE_TIME datetime2(3) NULL,
                    PLACE_LAST_CHG_USER_ID numeric(21,0) NULL,
                    PLACE_LAST_UPDATED_BY varchar(102) NULL,
                    PLACE_LOCAL_ID varchar(50) NULL,
                    PLACE_LOCATOR_UID varchar(30) NULL,
                    PLACE_NAME varchar(50) NULL,
                    PLACE_PHONE varchar(20) NULL,
                    PLACE_PHONE_COMMENTS varchar(2000) NULL,
                    PLACE_PHONE_EXT varchar(20) NULL,
                    PLACE_POSTAL_UID numeric(21,0) NULL,
                    PLACE_QUICK_CODE varchar(100) NULL,
                    PLACE_RECORD_STATUS varchar(20) NULL,
                    PLACE_RECORD_STATUS_TIME datetime2(3) NULL,
                    PLACE_STATE_CODE varchar(20) NULL,
                    PLACE_STATE_DESC varchar(50) NULL,
                    PLACE_STATUS_CD varchar(1) NULL,
                    PLACE_STATUS_TIME datetime2(3) NULL,
                    PLACE_STREET_ADDRESS_1 varchar(100) NULL,
                    PLACE_STREET_ADDRESS_2 varchar(100) NULL,
                    PLACE_TELE_LOCATOR_UID numeric(21,0) NULL,
                    PLACE_TELE_TYPE varchar(14) NULL,
                    PLACE_TELE_USE varchar(10) NULL,
                    PLACE_TYPE_DESCRIPTION varchar(25) NULL,
                    PLACE_UID numeric(21,0) NULL,
                    PLACE_ZIP varchar(20) NULL,
                    D_INV_PLACE_REPEAT_KEY float NULL
                )
                    ON [PRIMARY];

                IF NOT EXISTS
                    (
                        SELECT D_INV_PLACE_REPEAT_KEY
                        FROM [dbo].[D_INV_PLACE_REPEAT]
                        WHERE D_INV_PLACE_REPEAT_KEY = 1
                    )
                    BEGIN
                        INSERT INTO [dbo].[D_INV_PLACE_REPEAT]( [D_INV_PLACE_REPEAT_KEY] )
                        VALUES( 1 );
                    END;

            END;

        /* Logging */
        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Update D_INV_PLACE_REPEAT Schema';
        SET @proc_step_no = @proc_step_no + 1;


        IF EXISTS(
            SELECT 1
            FROM tempdb.INFORMATION_SCHEMA.COLUMNS s
            WHERE TABLE_NAME LIKE '#S_INV_PLACE_REPEAT%'
              AND NOT EXISTS (
                SELECT 1
                FROM INFORMATION_SCHEMA.COLUMNS d
                WHERE  TABLE_NAME = 'D_INV_PLACE_REPEAT' AND d.COLUMN_NAME = s.COLUMN_NAME
            )
        )
            BEGIN
                DECLARE @colAlt NVARCHAR(MAX) =''
                SELECT @colAlt = @colAlt +'ALTER TABLE dbo.D_INV_PLACE_REPEAT ADD ['+COLUMN_NAME+'] '+DATA_TYPE +
                                 CASE
                                     WHEN DATA_TYPE IN( 'char', 'varchar', 'nchar', 'nvarchar' )
                                         THEN ' (' +
                                              CASE
                                                  WHEN CHARACTER_MAXIMUM_LENGTH > 2000 OR CHARACTER_MAXIMUM_LENGTH = -1
                                                      THEN '2000'
                                                  ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10))
                                                  END + ')'
                                     ELSE ''
                                     END +
                                 CASE
                                     WHEN IS_NULLABLE = 'NO' THEN ' NOT NULL '
                                     ELSE ' NULL '
                                     END +'; '
                FROM tempdb.INFORMATION_SCHEMA.COLUMNS AS c
                WHERE TABLE_NAME LIKE '#S_INV_PLACE_REPEAT%' AND
                    NOT EXISTS
                        (
                            SELECT 1
                            FROM INFORMATION_SCHEMA.COLUMNS
                            WHERE TABLE_NAME = 'D_INV_PLACE_REPEAT' AND
                                COLUMN_NAME = c.COLUMN_NAME
                        ) ;

                IF @debug = 'true' print @colAlt;
                IF @colAlt <> ''
                    EXEC sp_executesql @colAlt;

            END;


        /* Logging */
        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Generate D_INV_PLACE_REPEAT_KEY';
        SET @proc_step_no = @proc_step_no + 1;

        /*Key generation: If PAGE_CASE_UID doesn't exist in L_INV_PLACE_REPEAT.*/
        WITH key_vals AS
                 (
                     SELECT DISTINCT PAGE_CASE_UID,
                                     DENSE_RANK () OVER (ORDER BY s.PAGE_CASE_UID) AS temp_key
                     FROM #S_INV_PLACE_REPEAT s
                 ),
             key_offset AS
                 (SELECT COALESCE(max(D_INV_PLACE_REPEAT_KEY),0) as max_key
                  FROM dbo.L_INV_PLACE_REPEAT

                 )
        INSERT INTO dbo.L_INV_PLACE_REPEAT(PAGE_CASE_UID,D_INV_PLACE_REPEAT_KEY)
        SELECT distinct kv.page_case_uid,
                        kv.temp_key + ko.max_key as d_inv_place_key
        FROM key_vals kv
                 CROSS JOIN key_offset ko
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.L_INV_PLACE_REPEAT l
            WHERE kv.PAGE_CASE_UID = l.PAGE_CASE_UID
        );

        /* Logging */
        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Update D_INV_PLACE_REPEAT';
        SET @proc_step_no = @proc_step_no + 1;

        UPDATE dbo.D_INV_PLACE_REPEAT
        SET
            PAGE_CASE_UID = s.PAGE_CASE_UID,
            answer_group_seq_nbr = s.answer_group_seq_nbr,
            PlaceAsSexOfPHC = s.PlaceAsSexOfPHC,
            PlaceAsHangoutOfPHC = s.PlaceAsHangoutOfPHC,
            PLACE_HANGOUT_OF_PHC = s.PLACE_HANGOUT_OF_PHC,
            PLACE_AS_SEX_OF_PHC = s.PLACE_AS_SEX_OF_PHC,
            PLACE_KEY = s.PLACE_KEY,
            PLACE_ADD_TIME = s.PLACE_ADD_TIME,
            PLACE_ADD_USER_ID = s.PLACE_ADD_USER_ID,
            PLACE_ADDED_BY = s.PLACE_ADDED_BY,
            PLACE_ADDRESS_COMMENTS = s.PLACE_ADDRESS_COMMENTS,
            PLACE_CITY = s.PLACE_CITY,
            PLACE_COUNTRY = s.PLACE_COUNTRY,
            PLACE_COUNTRY_DESC = s.PLACE_COUNTRY_DESC,
            PLACE_COUNTY_CODE = s.PLACE_COUNTY_CODE,
            PLACE_COUNTY_DESC = s.PLACE_COUNTY_DESC,
            PLACE_EMAIL = s.PLACE_EMAIL,
            PLACE_GENERAL_COMMENTS = s.PLACE_GENERAL_COMMENTS,
            PLACE_LAST_CHANGE_TIME = s.PLACE_LAST_CHANGE_TIME,
            PLACE_LAST_CHG_USER_ID = s.PLACE_LAST_CHG_USER_ID,
            PLACE_LAST_UPDATED_BY = s.PLACE_LAST_UPDATED_BY,
            PLACE_LOCAL_ID = s.PLACE_LOCAL_ID,
            PLACE_LOCATOR_UID = s.PLACE_LOCATOR_UID,
            PLACE_NAME = s.PLACE_NAME,
            PLACE_PHONE = s.PLACE_PHONE,
            PLACE_PHONE_COMMENTS = s.PLACE_PHONE_COMMENTS,
            PLACE_PHONE_EXT = s.PLACE_PHONE_EXT,
            PLACE_POSTAL_UID = s.PLACE_POSTAL_UID,
            PLACE_QUICK_CODE = s.PLACE_QUICK_CODE,
            PLACE_RECORD_STATUS = s.PLACE_RECORD_STATUS,
            PLACE_RECORD_STATUS_TIME = s.PLACE_RECORD_STATUS_TIME,
            PLACE_STATE_CODE = s.PLACE_STATE_CODE,
            PLACE_STATE_DESC = s.PLACE_STATE_DESC,
            PLACE_STATUS_CD = s.PLACE_STATUS_CD,
            PLACE_STATUS_TIME = s.PLACE_STATUS_TIME,
            PLACE_STREET_ADDRESS_1 = s.PLACE_STREET_ADDRESS_1,
            PLACE_STREET_ADDRESS_2 = s.PLACE_STREET_ADDRESS_2,
            PLACE_TELE_LOCATOR_UID = s.PLACE_TELE_LOCATOR_UID,
            PLACE_TELE_TYPE = s.PLACE_TELE_TYPE,
            PLACE_TELE_USE = s.PLACE_TELE_USE,
            PLACE_TYPE_DESCRIPTION = s.PLACE_TYPE_DESCRIPTION,
            PLACE_UID = s.PLACE_UID,
            PLACE_ZIP = s.PLACE_ZIP,
            D_INV_PLACE_REPEAT_KEY = l.D_INV_PLACE_REPEAT_KEY
        FROM #S_INV_PLACE_REPEAT s
                 INNER JOIN dbo.L_INV_PLACE_REPEAT l ON s.PAGE_CASE_UID = l.PAGE_CASE_UID
                 INNER JOIN dbo.D_INV_PLACE_REPEAT d ON l.D_INV_PLACE_REPEAT_KEY = d.D_INV_PLACE_REPEAT_KEY;

        /* Logging */
        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Insert D_INV_PLACE_REPEAT';
        SET @proc_step_no = @proc_step_no + 1;

        INSERT INTO dbo.D_INV_PLACE_REPEAT
        (PAGE_CASE_UID, answer_group_seq_nbr,
         PlaceAsSexOfPHC, PlaceAsHangoutOfPHC,
         PLACE_HANGOUT_OF_PHC, PLACE_AS_SEX_OF_PHC, PLACE_KEY, PLACE_ADD_TIME, PLACE_ADD_USER_ID, PLACE_ADDED_BY, PLACE_ADDRESS_COMMENTS, PLACE_CITY, PLACE_COUNTRY, PLACE_COUNTRY_DESC, PLACE_COUNTY_CODE, PLACE_COUNTY_DESC, PLACE_EMAIL, PLACE_GENERAL_COMMENTS, PLACE_LAST_CHANGE_TIME, PLACE_LAST_CHG_USER_ID, PLACE_LAST_UPDATED_BY, PLACE_LOCAL_ID, PLACE_LOCATOR_UID, PLACE_NAME, PLACE_PHONE, PLACE_PHONE_COMMENTS, PLACE_PHONE_EXT, PLACE_POSTAL_UID, PLACE_QUICK_CODE, PLACE_RECORD_STATUS, PLACE_RECORD_STATUS_TIME, PLACE_STATE_CODE, PLACE_STATE_DESC, PLACE_STATUS_CD, PLACE_STATUS_TIME, PLACE_STREET_ADDRESS_1, PLACE_STREET_ADDRESS_2, PLACE_TELE_LOCATOR_UID, PLACE_TELE_TYPE, PLACE_TELE_USE, PLACE_TYPE_DESCRIPTION, PLACE_UID, PLACE_ZIP, D_INV_PLACE_REPEAT_KEY)
        SELECT
            s.PAGE_CASE_UID,
            s.answer_group_seq_nbr,
            s.PlaceAsSexOfPHC,
            s.PlaceAsHangoutOfPHC,
            s.PLACE_HANGOUT_OF_PHC,
            s.PLACE_AS_SEX_OF_PHC,
            s.PLACE_KEY,
            s.PLACE_ADD_TIME,
            s.PLACE_ADD_USER_ID,
            s.PLACE_ADDED_BY,
            s.PLACE_ADDRESS_COMMENTS,
            s.PLACE_CITY,
            s.PLACE_COUNTRY,
            s.PLACE_COUNTRY_DESC,
            s.PLACE_COUNTY_CODE,
            s.PLACE_COUNTY_DESC,
            s.PLACE_EMAIL,
            s.PLACE_GENERAL_COMMENTS,
            s.PLACE_LAST_CHANGE_TIME,
            s.PLACE_LAST_CHG_USER_ID,
            s.PLACE_LAST_UPDATED_BY,
            s.PLACE_LOCAL_ID,
            s.PLACE_LOCATOR_UID,
            s.PLACE_NAME,
            s.PLACE_PHONE,
            s.PLACE_PHONE_COMMENTS,
            s.PLACE_PHONE_EXT,
            s.PLACE_POSTAL_UID,
            s.PLACE_QUICK_CODE,
            s.PLACE_RECORD_STATUS,
            s.PLACE_RECORD_STATUS_TIME,
            s.PLACE_STATE_CODE,
            s.PLACE_STATE_DESC,
            s.PLACE_STATUS_CD,
            s.PLACE_STATUS_TIME,
            s.PLACE_STREET_ADDRESS_1,
            s.PLACE_STREET_ADDRESS_2,
            s.PLACE_TELE_LOCATOR_UID,
            s.PLACE_TELE_TYPE,
            s.PLACE_TELE_USE,
            s.PLACE_TYPE_DESCRIPTION,
            s.PLACE_UID,
            s.PLACE_ZIP,
            l.D_INV_PLACE_REPEAT_KEY
        FROM #S_INV_PLACE_REPEAT s
                 LEFT JOIN dbo.L_INV_PLACE_REPEAT l ON s.PAGE_CASE_UID = l.PAGE_CASE_UID
                 LEFT JOIN dbo.D_INV_PLACE_REPEAT d ON l.D_INV_PLACE_REPEAT_KEY = d.D_INV_PLACE_REPEAT_KEY
        WHERE d.D_INV_PLACE_REPEAT_KEY IS NULL;

        /* Logging */
        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );
        COMMIT TRANSACTION;


        SET @proc_step_name = 'SP_COMPLETE';
        SET @proc_step_no = @proc_step_no + 1;

        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               );

    END TRY

    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        /* Logging */
        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [create_dttm]
        , [update_dttm]
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        )
        VALUES ( @batch_id
               , current_timestamp
               , current_timestamp
               , @dataflow_name
               , @package_name
               , 'ERROR'
               , @Proc_Step_no
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0
               );


        return @ErrorMessage;

    END CATCH

END
