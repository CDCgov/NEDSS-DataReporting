CREATE OR ALTER PROCEDURE dbo.sp_nrt_place_postprocessing @id_list nvarchar(max),
                                                          @debug bit = 'false'
AS
BEGIN

    BEGIN TRY

        /* Logging */
        declare @rowcount bigint;
        declare @proc_step_no float = 0;
        declare @proc_step_name varchar(200) = '';
        declare @batch_id bigint;
        declare @create_dttm datetime2(7) = current_timestamp;
        declare @update_dttm datetime2(7) = current_timestamp;
        declare @dataflow_name varchar(200) = 'D_Place POST-Processing';
        declare @package_name varchar(200) = 'sp_nrt_place_postprocessing';
        set @batch_id = cast((format(getdate(), 'yyMMddHHmmss')) as bigint);


        INSERT INTO [dbo].[job_flow_log]
        ( batch_id
        , [create_dttm]
        , [update_dttm]
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [msg_description1]
        , [row_count])
        VALUES ( @batch_id
               , @create_dttm
               , @update_dttm
               , @dataflow_name
               , @package_name
               , 'START'
               , 0
               , 'SP_Start'
               , LEFT(@id_list, 500)
               , 0);

        SET @proc_step_name = 'Create D_PLACE Temp table -' + LEFT(@id_list, 160);
        SET @proc_step_no = 1;


        SELECT DISTINCT nrt.place_uid
                      , nrt.cd
                      , nrt.place_type_description
                      , nrt.place_local_id           AS 'PLACE_LOCAL_ID'
                      , nrt.place_name
                      , nrt.place_general_comments
                      , nrt.place_add_time           AS 'PLACE_ADD_TIME'
                      , nrt.place_add_user_id        AS 'PLACE_ADD_USER_ID'
                      , nrt.place_last_change_time   AS 'PLACE_LAST_CHANGE_TIME'
                      , nrt.place_last_chg_user_id   AS 'PLACE_LAST_CHG_USER_ID'
                      , nrt.place_record_status      AS 'PLACE_RECORD_STATUS'
                      , nrt.place_record_status_time AS 'PLACE_RECORD_STATUS_TIME'
                      , nrt.place_status_cd
                      , nrt.place_status_time
                      , nrt.place_quick_code         AS 'PLACE_QUICK_CODE'
                      , nrt.assigning_authority_cd
                      , nrt.place_postal_uid         AS 'PLACE_POSTAL_UID'
                      , nrt.place_zip                AS 'PLACE_ZIP'
                      , nrt.place_city               AS 'PLACE_CITY'
                      , nrt.place_country            AS 'PLACE_COUNTRY'
                      , nrt.place_street_address_1   AS 'PLACE_STREET_ADDRESS_1'
                      , nrt.place_street_address_2   AS 'PLACE_STREET_ADDRESS_2'
                      , nrt.place_county_code        AS 'PLACE_COUNTY_CODE'
                      , nrt.place_state_code         AS 'PLACE_STATE_CODE'
                      , nrt.place_address_comments
                      , CASE
                            WHEN LEN(RTRIM(LTRIM(nrt.place_state_desc))) > 1 THEN nrt.place_state_desc
            END                                      AS PLACE_STATE_DESC
                      , CASE
                            WHEN LEN(RTRIM(LTRIM(nrt.place_county_desc))) > 1 THEN nrt.place_county_desc
            END                                      AS PLACE_COUNTY_DESC
                      , CASE
                            WHEN LEN(RTRIM(LTRIM(nrt.place_country_desc))) > 1 THEN nrt.place_country_desc
            END                                      AS PLACE_COUNTRY_DESC
                      , nrt.place_elp_cd
                      , tele.place_tele_locator_uid  AS 'PLACE_TELE_LOCATOR_UID'
                      , tele.place_phone_ext         AS 'PLACE_PHONE_EXT'
                      , tele.place_phone
                      , tele.place_email
                      , tele.place_phone_comments
                      , tele.tele_use_cd
                      , tele.tele_cd
                      , tele.place_tele_type
                      , tele.place_tele_use
                      , CASE
                            WHEN LEN(RTRIM(LTRIM(b.first_nm))) > 0 AND LEN(RTRIM(LTRIM(b.last_nm))) > 0
                                THEN CAST(RTRIM(LTRIM(b.last_nm)) + ', ' + RTRIM(LTRIM(b.first_nm)) AS VARCHAR(102))
                            WHEN LEN(RTRIM(LTRIM(b.first_nm))) > 0 AND LEN(RTRIM(LTRIM(b.last_nm))) <= 0
                                THEN RTRIM(LTRIM(b.first_nm))
                            WHEN LEN(RTRIM(LTRIM(b.first_nm))) <= 0 AND LEN(RTRIM(LTRIM(b.last_nm))) > 0
                                THEN RTRIM(LTRIM(b.last_nm))
                            ELSE NULL
            END                                      AS PLACE_ADDED_BY
                      , CASE
                            WHEN LEN(RTRIM(LTRIM(c.first_nm))) > 0 AND LEN(RTRIM(LTRIM(c.last_nm))) > 0
                                THEN CAST(RTRIM(LTRIM(c.last_nm)) + ', ' + RTRIM(LTRIM(c.first_nm)) AS VARCHAR(102))
                            WHEN LEN(RTRIM(LTRIM(c.first_nm))) > 0 AND LEN(RTRIM(LTRIM(c.last_nm))) <= 0
                                THEN RTRIM(LTRIM(c.first_nm))
                            WHEN LEN(RTRIM(LTRIM(c.first_nm))) <= 0 AND LEN(RTRIM(LTRIM(c.last_nm))) > 0
                                THEN RTRIM(LTRIM(c.last_nm))
                            ELSE NULL
            END                                      AS PLACE_LAST_UPDATED_BY
        INTO #tmp_place_table
        FROM dbo.nrt_place nrt
                 LEFT JOIN dbo.nrt_place_tele tele on tele.place_uid = nrt.place_uid
                 LEFT OUTER JOIN dbo.USER_PROFILE B
                                 ON nrt.place_add_user_id = b.nedss_entry_id
                 LEFT OUTER JOIN dbo.USER_PROFILE C
                                 ON nrt.place_add_user_id = c.nedss_entry_id
        WHERE nrt.place_uid IN (SELECT value FROM STRING_SPLIT(@id_list, ','));


        IF @debug = 'true' SELECT * FROM #tmp_place_table;

        /* Logging */
        set @rowcount = @@rowcount
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
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               , LEFT(@id_list, 500));

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Prepare data for D_PLACE';
        SET @proc_step_no = @proc_step_no + 1;

        /* Unique row selection for each composite PLACE_LOCATOR_UID:
         * 1. Place_uid specific.
         * 2. Place_uid + Postal_locator_uid
         * 3. Place_uid + Tele_locator_uid
         * 4. Place_uid + Postal_locator_uid + Tele_locator_uid*/

        SELECT PLACE_LOCATOR_UID,
               PLACE_KEY,
               PLACE_ADD_TIME,
               PLACE_ADD_USER_ID,
               PLACE_ADDED_BY,
               PLACE_ADDRESS_COMMENTS,
               PLACE_CITY,
               PLACE_COUNTRY,
               PLACE_COUNTRY_DESC,
               PLACE_COUNTY_CODE,
               PLACE_COUNTY_DESC,
               PLACE_EMAIL,
               PLACE_GENERAL_COMMENTS,
               PLACE_LAST_CHANGE_TIME,
               PLACE_LAST_CHG_USER_ID,
               PLACE_LAST_UPDATED_BY,
               PLACE_LOCAL_ID,
               PLACE_NAME,
               PLACE_PHONE,
               PLACE_PHONE_COMMENTS,
               PLACE_PHONE_EXT,
               PLACE_POSTAL_UID,
               PLACE_QUICK_CODE,
               PLACE_RECORD_STATUS,
               PLACE_RECORD_STATUS_TIME,
               PLACE_STATE_CODE,
               PLACE_STATE_DESC,
               PLACE_STATUS_CD,
               PLACE_STATUS_TIME,
               PLACE_STREET_ADDRESS_1,
               PLACE_STREET_ADDRESS_2,
               PLACE_TELE_LOCATOR_UID,
               PLACE_TELE_TYPE,
               PLACE_TELE_USE, --ELP All
               PLACE_TYPE_DESCRIPTION,
               PLACE_UID,
               PLACE_ZIP
        INTO #tmp_locator_gen
        FROM (
                 --Base: No Postal or Tele information
                 SELECT DISTINCT CASE
                                     WHEN k.place_locator_uid IS NULL
                                         THEN CAST(CAST(S.place_uid AS VARCHAR(10)) + '^^' AS VARCHAR(30))
                                     ELSE k.place_locator_uid END
                                                             AS PLACE_LOCATOR_UID,
                                 NULLIF(k.d_place_key, NULL) AS PLACE_KEY,
                                 S.PLACE_ADD_TIME,
                                 S.PLACE_ADD_USER_ID,
                                 S.PLACE_ADDED_BY,
                                 NULL                        AS PLACE_ADDRESS_COMMENTS,
                                 NULL                        AS PLACE_CITY,
                                 NULL                        AS PLACE_COUNTRY,
                                 NULL                        AS PLACE_COUNTRY_DESC,
                                 NULL                        AS PLACE_COUNTY_CODE,
                                 NULL                        AS PLACE_COUNTY_DESC,
                                 NULL                        AS PLACE_EMAIL,
                                 S.PLACE_GENERAL_COMMENTS,
                                 S.PLACE_LAST_CHANGE_TIME,
                                 S.PLACE_LAST_CHG_USER_ID,
                                 S.PLACE_LAST_UPDATED_BY,
                                 S.PLACE_LOCAL_ID,
                                 S.PLACE_NAME,
                                 NULL                        AS PLACE_PHONE,
                                 NULL                        AS PLACE_PHONE_COMMENTS,
                                 NULL                        AS PLACE_PHONE_EXT,
                                 NULL                        AS PLACE_POSTAL_UID,
                                 S.PLACE_QUICK_CODE,
                                 S.PLACE_RECORD_STATUS,
                                 S.PLACE_RECORD_STATUS_TIME,
                                 NULL                        AS PLACE_STATE_CODE,
                                 NULL                        AS PLACE_STATE_DESC,
                                 S.PLACE_STATUS_CD,
                                 S.PLACE_STATUS_TIME,
                                 NULL                        AS PLACE_STREET_ADDRESS_1,
                                 NULL                        AS PLACE_STREET_ADDRESS_2,
                                 NULL                        AS PLACE_TELE_LOCATOR_UID,
                                 S.PLACE_ELP_CD              AS PLACE_TELE_TYPE, --ELP PLC
                                 S.PLACE_TELE_USE,
                                 S.PLACE_TYPE_DESCRIPTION,
                                 S.PLACE_UID,
                                 NULL                        AS PLACE_ZIP
                 FROM #tmp_place_table s
                          LEFT JOIN dbo.nrt_place_key k on k.place_uid = S.place_uid
                     AND k.place_locator_uid = CAST(CAST(S.place_uid AS VARCHAR(10)) + '^^' AS VARCHAR(30))
                 WHERE S.place_postal_uid IS NOT NULL
                 UNION ALL
                 --Postal: Only Postal Information
                 SELECT DISTINCT CASE
                                     WHEN k.place_locator_uid IS NULL THEN
                                         CAST(CAST(S.place_uid AS VARCHAR(10)) + '^' +
                                              CAST(S.place_postal_uid AS VARCHAR(10)) + '^' AS VARCHAR(30))
                                     ELSE k.place_locator_uid END
                                                             AS PLACE_LOCATOR_UID,
                                 NULLIF(k.d_place_key, NULL) AS PLACE_KEY,
                                 S.PLACE_ADD_TIME,
                                 S.PLACE_ADD_USER_ID,
                                 S.PLACE_ADDED_BY,
                                 S.PLACE_ADDRESS_COMMENTS,
                                 S.PLACE_CITY,
                                 S.PLACE_COUNTRY,
                                 S.PLACE_COUNTRY_DESC,
                                 S.PLACE_COUNTY_CODE,
                                 S.PLACE_COUNTY_DESC,
                                 NULL                        AS PLACE_EMAIL,
                                 S.PLACE_GENERAL_COMMENTS,
                                 S.PLACE_LAST_CHANGE_TIME,
                                 S.PLACE_LAST_CHG_USER_ID,
                                 S.PLACE_LAST_UPDATED_BY,
                                 S.PLACE_LOCAL_ID,
                                 S.PLACE_NAME,
                                 NULL                        AS PLACE_PHONE,
                                 NULL                        AS PLACE_PHONE_COMMENTS,
                                 NULL                        AS PLACE_PHONE_EXT,
                                 S.PLACE_POSTAL_UID,
                                 S.PLACE_QUICK_CODE,
                                 S.PLACE_RECORD_STATUS,
                                 S.PLACE_RECORD_STATUS_TIME,
                                 S.PLACE_STATE_CODE,
                                 S.PLACE_STATE_DESC,
                                 S.PLACE_STATUS_CD,
                                 S.PLACE_STATUS_TIME,
                                 S.PLACE_STREET_ADDRESS_1,
                                 S.PLACE_STREET_ADDRESS_2,
                                 NULL                        AS PLACE_TELE_LOCATOR_UID,
                                 S.PLACE_ELP_CD              AS PLACE_TELE_TYPE, --ELP PLC
                                 S.PLACE_TELE_USE,
                                 S.PLACE_TYPE_DESCRIPTION,
                                 S.PLACE_UID,
                                 S.PLACE_ZIP
                 FROM #tmp_place_table s
                          LEFT JOIN dbo.nrt_place_key k on k.place_uid = S.place_uid
                     AND k.place_locator_uid =
                         CAST(CAST(S.place_uid AS VARCHAR(10)) + '^' + CAST(S.place_postal_uid AS VARCHAR(10)) +
                              '^' AS VARCHAR(30))
                 WHERE S.place_postal_uid IS NOT NULL
                 UNION ALL
                 --Tele: Only Tele Information
                 SELECT DISTINCT CASE
                                     WHEN k.place_locator_uid IS NULL THEN
                                         CAST(CAST(S.place_uid AS VARCHAR(10)) + '^^' +
                                              CAST(S.place_tele_locator_uid AS VARCHAR(10)) AS VARCHAR(30))
                                     ELSE k.place_locator_uid END
                                                             AS PLACE_LOCATOR_UID,
                                 NULLIF(k.d_place_key, NULL) AS PLACE_KEY,
                                 S.PLACE_ADD_TIME,
                                 S.PLACE_ADD_USER_ID,
                                 S.PLACE_ADDED_BY,
                                 NULL                        AS PLACE_ADDRESS_COMMENTS,
                                 NULL                        AS PLACE_CITY,
                                 NULL                        AS PLACE_COUNTRY,
                                 NULL                        AS PLACE_COUNTRY_DESC,
                                 NULL                        AS PLACE_COUNTY_CODE,
                                 NULL                        AS PLACE_COUNTY_DESC,
                                 S.PLACE_EMAIL,
                                 S.PLACE_GENERAL_COMMENTS,
                                 S.PLACE_LAST_CHANGE_TIME,
                                 S.PLACE_LAST_CHG_USER_ID,
                                 S.PLACE_LAST_UPDATED_BY,
                                 S.PLACE_LOCAL_ID,
                                 S.PLACE_NAME,
                                 S.PLACE_PHONE,
                                 S.PLACE_PHONE_COMMENTS,
                                 S.PLACE_PHONE_EXT,
                                 NULL                        AS PLACE_POSTAL_UID,
                                 S.PLACE_QUICK_CODE,
                                 S.PLACE_RECORD_STATUS,
                                 S.PLACE_RECORD_STATUS_TIME,
                                 NULL                        AS PLACE_STATE_CODE,
                                 NULL                        AS PLACE_STATE_DESC,
                                 S.PLACE_STATUS_CD,
                                 S.PLACE_STATUS_TIME,
                                 NULL                        AS PLACE_STREET_ADDRESS_1,
                                 NULL                        AS PLACE_STREET_ADDRESS_2,
                                 S.PLACE_TELE_LOCATOR_UID,
                                 S.PLACE_TELE_TYPE, --PHC TELE
                                 S.PLACE_TELE_USE,
                                 S.PLACE_TYPE_DESCRIPTION,
                                 S.PLACE_UID,
                                 NULL                        AS PLACE_ZIP
                 FROM #tmp_place_table s
                          LEFT JOIN dbo.nrt_place_key k on k.place_uid = S.place_uid
                     AND k.place_locator_uid = CAST(CAST(S.place_uid AS VARCHAR(10)) + '^^' +
                                                    CAST(S.place_tele_locator_uid AS VARCHAR(10)) AS VARCHAR(30))
                 WHERE S.place_tele_locator_uid IS NOT NULL
                 UNION ALL
                 SELECT DISTINCT CASE
                                     WHEN k.place_locator_uid IS NULL THEN
                                         CAST(CAST(S.place_uid AS VARCHAR(10)) + '^' +
                                              CAST(S.place_postal_uid AS VARCHAR(10)) + '^' +
                                              CAST(S.place_tele_locator_uid AS VARCHAR(10)) AS VARCHAR(30))
                                     ELSE k.place_locator_uid END
                                                             AS PLACE_LOCATOR_UID,
                                 NULLIF(k.d_place_key, NULL) AS PLACE_KEY,
                                 S.PLACE_ADD_TIME,
                                 S.PLACE_ADD_USER_ID,
                                 S.PLACE_ADDED_BY,
                                 S.PLACE_ADDRESS_COMMENTS,
                                 S.PLACE_CITY,
                                 S.PLACE_COUNTRY,
                                 S.PLACE_COUNTRY_DESC,
                                 S.PLACE_COUNTY_CODE,
                                 S.PLACE_COUNTY_DESC,
                                 S.PLACE_EMAIL,
                                 S.PLACE_GENERAL_COMMENTS,
                                 S.PLACE_LAST_CHANGE_TIME,
                                 S.PLACE_LAST_CHG_USER_ID,
                                 S.PLACE_LAST_UPDATED_BY,
                                 S.PLACE_LOCAL_ID,
                                 S.PLACE_NAME,
                                 S.PLACE_PHONE,
                                 S.PLACE_PHONE_COMMENTS,
                                 S.PLACE_PHONE_EXT,
                                 S.PLACE_POSTAL_UID,
                                 S.PLACE_QUICK_CODE,
                                 S.PLACE_RECORD_STATUS,
                                 S.PLACE_RECORD_STATUS_TIME,
                                 S.PLACE_STATE_CODE,
                                 S.PLACE_STATE_DESC,
                                 S.PLACE_STATUS_CD,
                                 S.PLACE_STATUS_TIME,
                                 S.PLACE_STREET_ADDRESS_1,
                                 S.PLACE_STREET_ADDRESS_2,
                                 S.PLACE_TELE_LOCATOR_UID,
                                 S.PLACE_TELE_TYPE           AS PLACE_TELE_TYPE,
                                 S.PLACE_TELE_USE, --ELP All: Tele_use
                                 S.PLACE_TYPE_DESCRIPTION,
                                 S.PLACE_UID,
                                 S.PLACE_ZIP
                 FROM #tmp_place_table s
                          LEFT JOIN dbo.nrt_place_key k on k.place_uid = S.place_uid
                     AND k.place_locator_uid =
                         CAST(CAST(S.place_uid AS VARCHAR(10)) + '^' + CAST(S.place_postal_uid AS VARCHAR(10)) + '^' +
                              CAST(S.place_tele_locator_uid AS VARCHAR(10)) AS VARCHAR(30))
                 WHERE S.place_tele_locator_uid IS NOT NULL
                   AND S.place_postal_uid IS NOT NULL) src;


        IF @debug = 'true' SELECT * FROM #tmp_locator_gen;

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
        , [msg_description1])
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               , LEFT(@id_list, 500));
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @proc_step_name = 'Update D_PLACE';
        SET @proc_step_no = @proc_step_no + 1;

        UPDATE dbo.D_PLACE
        SET PLACE_LOCATOR_UID        = tmp.PLACE_LOCATOR_UID,
            PLACE_KEY                = tmp.PLACE_KEY,
            PLACE_ADD_TIME           = tmp.PLACE_ADD_TIME,
            PLACE_ADD_USER_ID        = tmp.PLACE_ADD_USER_ID,
            PLACE_ADDED_BY           = tmp.PLACE_ADDED_BY,
            PLACE_ADDRESS_COMMENTS   = tmp.PLACE_ADDRESS_COMMENTS,
            PLACE_CITY               = tmp.PLACE_CITY,
            PLACE_COUNTRY            = tmp.PLACE_COUNTRY,
            PLACE_COUNTRY_DESC       = tmp.PLACE_COUNTRY_DESC,
            PLACE_COUNTY_CODE        = tmp.PLACE_COUNTY_CODE,
            PLACE_COUNTY_DESC        = tmp.PLACE_COUNTY_DESC,
            PLACE_EMAIL              = tmp.PLACE_EMAIL,
            PLACE_GENERAL_COMMENTS   = tmp.PLACE_GENERAL_COMMENTS,
            PLACE_LAST_CHANGE_TIME   = tmp.PLACE_LAST_CHANGE_TIME,
            PLACE_LAST_CHG_USER_ID   = tmp.PLACE_LAST_CHG_USER_ID,
            PLACE_LAST_UPDATED_BY    = tmp.PLACE_LAST_UPDATED_BY,
            PLACE_LOCAL_ID           = tmp.PLACE_LOCAL_ID,
            PLACE_NAME               = tmp.PLACE_NAME,
            PLACE_PHONE              = tmp.PLACE_PHONE,
            PLACE_PHONE_COMMENTS     = tmp.PLACE_PHONE_COMMENTS,
            PLACE_PHONE_EXT          = tmp.PLACE_PHONE_EXT,
            PLACE_POSTAL_UID         = tmp.PLACE_POSTAL_UID,
            PLACE_QUICK_CODE         = tmp.PLACE_QUICK_CODE,
            PLACE_RECORD_STATUS      = tmp.PLACE_RECORD_STATUS,
            PLACE_RECORD_STATUS_TIME = tmp.PLACE_RECORD_STATUS_TIME,
            PLACE_STATE_CODE         = tmp.PLACE_STATE_CODE,
            PLACE_STATE_DESC         = tmp.PLACE_STATE_DESC,
            PLACE_STATUS_CD          = tmp.PLACE_STATUS_CD,
            PLACE_STATUS_TIME        = tmp.PLACE_STATUS_TIME,
            PLACE_STREET_ADDRESS_1   = tmp.PLACE_STREET_ADDRESS_1,
            PLACE_STREET_ADDRESS_2   = tmp.PLACE_STREET_ADDRESS_2,
            PLACE_TELE_LOCATOR_UID   = tmp.PLACE_TELE_LOCATOR_UID,
            PLACE_TELE_TYPE          = tmp.PLACE_TELE_TYPE,
            PLACE_TELE_USE           = tmp.PLACE_TELE_USE,
            PLACE_TYPE_DESCRIPTION   = tmp.PLACE_TYPE_DESCRIPTION,
            PLACE_UID                = tmp.PLACE_UID,
            PLACE_ZIP                = tmp.PLACE_ZIP
        FROM #tmp_locator_gen tmp
                 INNER JOIN dbo.D_PLACE d ON d.PLACE_KEY = tmp.PLACE_KEY
            AND d.PLACE_LOCATOR_UID = tmp.PLACE_LOCATOR_UID;

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
        , [msg_description1])
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               , LEFT(@id_list, 500));
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @proc_step_name = 'Insert D_PLACE';
        SET @proc_step_no = @proc_step_no + 1;

        /* Generate D_PLACE keys for Insert. */
        INSERT INTO dbo.nrt_place_key (place_uid, place_locator_uid)
        SELECT DISTINCT tmp.place_uid, tmp.place_locator_uid
        FROM #tmp_locator_gen tmp
                 LEFT JOIN dbo.nrt_place_key k on k.place_locator_uid = tmp.place_locator_uid
        WHERE k.d_place_key IS NULL
          and tmp.place_locator_uid IS NOT NULL;

        INSERT INTO dbo.D_PLACE
        (PLACE_LOCATOR_UID,
         PLACE_KEY,
         PLACE_ADD_TIME,
         PLACE_ADD_USER_ID,
         PLACE_ADDED_BY,
         PLACE_ADDRESS_COMMENTS,
         PLACE_CITY,
         PLACE_COUNTRY,
         PLACE_COUNTRY_DESC,
         PLACE_COUNTY_CODE,
         PLACE_COUNTY_DESC,
         PLACE_EMAIL,
         PLACE_GENERAL_COMMENTS,
         PLACE_LAST_CHANGE_TIME,
         PLACE_LAST_CHG_USER_ID,
         PLACE_LAST_UPDATED_BY,
         PLACE_LOCAL_ID,
         PLACE_NAME,
         PLACE_PHONE,
         PLACE_PHONE_COMMENTS,
         PLACE_PHONE_EXT,
         PLACE_POSTAL_UID,
         PLACE_QUICK_CODE,
         PLACE_RECORD_STATUS,
         PLACE_RECORD_STATUS_TIME,
         PLACE_STATE_CODE,
         PLACE_STATE_DESC,
         PLACE_STATUS_CD,
         PLACE_STATUS_TIME,
         PLACE_STREET_ADDRESS_1,
         PLACE_STREET_ADDRESS_2,
         PLACE_TELE_LOCATOR_UID,
         PLACE_TELE_TYPE,
         PLACE_TELE_USE,
         PLACE_TYPE_DESCRIPTION,
         PLACE_UID,
         PLACE_ZIP)
        SELECT tmp_key.PLACE_LOCATOR_UID,
               tmp_key.D_PLACE_KEY,
               tmp.PLACE_ADD_TIME,
               tmp.PLACE_ADD_USER_ID,
               tmp.PLACE_ADDED_BY,
               tmp.PLACE_ADDRESS_COMMENTS,
               tmp.PLACE_CITY,
               tmp.PLACE_COUNTRY,
               tmp.PLACE_COUNTRY_DESC,
               tmp.PLACE_COUNTY_CODE,
               tmp.PLACE_COUNTY_DESC,
               tmp.PLACE_EMAIL,
               tmp.PLACE_GENERAL_COMMENTS,
               tmp.PLACE_LAST_CHANGE_TIME,
               tmp.PLACE_LAST_CHG_USER_ID,
               tmp.PLACE_LAST_UPDATED_BY,
               tmp.PLACE_LOCAL_ID,
               tmp.PLACE_NAME,
               tmp.PLACE_PHONE,
               tmp.PLACE_PHONE_COMMENTS,
               tmp.PLACE_PHONE_EXT,
               tmp.PLACE_POSTAL_UID,
               tmp.PLACE_QUICK_CODE,
               tmp.PLACE_RECORD_STATUS,
               tmp.PLACE_RECORD_STATUS_TIME,
               tmp.PLACE_STATE_CODE,
               tmp.PLACE_STATE_DESC,
               tmp.PLACE_STATUS_CD,
               tmp.PLACE_STATUS_TIME,
               tmp.PLACE_STREET_ADDRESS_1,
               tmp.PLACE_STREET_ADDRESS_2,
               tmp.PLACE_TELE_LOCATOR_UID,
               tmp.PLACE_TELE_TYPE,
               tmp.PLACE_TELE_USE,
               tmp.PLACE_TYPE_DESCRIPTION,
               tmp.PLACE_UID,
               tmp.PLACE_ZIP
        FROM #tmp_locator_gen tmp
                 LEFT JOIN dbo.nrt_place_key tmp_key ON tmp_key.place_locator_uid = tmp.place_locator_uid
                 LEFT JOIN dbo.D_PLACE d ON d.place_key = tmp_key.d_place_key
        WHERE d.place_key IS NULL;

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
        , [msg_description1])
        VALUES ( @batch_id
               , @dataflow_name
               , @package_name
               , 'START'
               , @proc_step_no
               , @proc_step_name
               , @rowcount
               , LEFT(@id_list, 500));
        COMMIT TRANSACTION;

        SET @proc_step_name = 'SP_COMPLETE';
        SET @proc_step_no = @proc_step_no + 1;


        IF OBJECT_ID('#tmp_place_table', 'U') IS NOT NULL drop table #tmp_place_table;
        IF OBJECT_ID('#tmp_locator_gen', 'U') IS NOT NULL drop table #tmp_locator_gen;


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
        , [msg_description1])
        VALUES ( @batch_id
               , current_timestamp
               , current_timestamp
               , @dataflow_name
               , @package_name
               , 'COMPLETE'
               , @proc_step_no
               , @proc_step_name
               , 0
               , LEFT(@id_list, 500));


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
        , [msg_description1])
        VALUES ( @batch_id
               , current_timestamp
               , current_timestamp
               , @dataflow_name
               , @package_name
               , 'ERROR'
               , @Proc_Step_no
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0
               , LEFT(@id_list, 500));


        return @ErrorMessage;

    END CATCH

END;