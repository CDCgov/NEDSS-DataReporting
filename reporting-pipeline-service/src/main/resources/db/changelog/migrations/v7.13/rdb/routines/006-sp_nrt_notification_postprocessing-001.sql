IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_notification_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_notification_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_nrt_notification_postprocessing] @notification_uids nvarchar(max), @debug bit = 'false'
AS
BEGIN

    BEGIN TRY

        /* Logging */
        declare @rowcount bigint;
        declare @proc_step_no float = 0;
        declare @proc_step_name varchar(200) = '';
        declare @batch_id bigint;
        declare @create_dttm datetime2(7) = current_timestamp ;
        declare @update_dttm datetime2(7) = current_timestamp ;
        declare @dataflow_name varchar(200) = 'Notification POST-Processing';
        declare @package_name varchar(200) = 'sp_nrt_notification_postprocessing';

        set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

        INSERT INTO [dbo].[job_flow_log]
        ( batch_id,[create_dttm],[update_dttm],[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES 
        (@batch_id,@create_dttm,@update_dttm,@dataflow_name,@package_name,'START',0,'SP_Start',LEFT(@notification_uids,500),0);

        SET @proc_step_name='Create NOTIFICATION and NOTIFICATION_EVENT Temp tables-'+ LEFT(@notification_uids,105);
        SET @proc_step_no = 1;

        /* Temp notification table creation */
        SELECT nrt.notification_uid,
               nrt.notif_status AS NOTIFICATION_STATUS,
               nrt.notif_comments AS NOTIFICATION_COMMENTS,
               nk.d_notification_key AS NOTIFICATION_KEY,
               nrt.notif_local_id AS NOTIFICATION_LOCAL_ID,
               nrt.notif_add_user_id AS NOTIFICATION_SUBMITTED_BY,
               nrt.notif_last_chg_time AS NOTIFICATION_LAST_CHANGE_TIME
        INTO #temp_ntf_table
        FROM dbo.nrt_investigation_notification nrt with (nolock)
                 LEFT JOIN dbo.nrt_notification_key nk with (nolock) ON nrt.notification_uid = nk.notification_uid
        WHERE nrt.notification_uid in (SELECT value FROM STRING_SPLIT(@notification_uids, ','));

        declare @backfill_list nvarchar(max);  
        SET @backfill_list = 
            ( 
              SELECT string_agg(t.value, ',')
              FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@notification_uids, ',')) t
                        left join #temp_ntf_table tmp
                        on tmp.notification_uid = t.value	
                        WHERE tmp.notification_uid is null	
            );

        IF @backfill_list IS NOT NULL
        BEGIN
            SELECT
                0 AS public_health_case_uid,
                CAST(NULL AS BIGINT) AS patient_uid,
                CAST(NULL AS BIGINT) AS observation_uid,
                'Error' AS datamart,
                CAST(NULL AS VARCHAR(50))  AS condition_cd,
                'Missing NRT Record: sp_nrt_notification_postprocessing' AS stored_procedure,
                CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
                WHERE 1=1;
           RETURN;
        END
        
        /* Temp notification_event table creation */
        SELECT nrt.notification_uid,
               COALESCE(p.PATIENT_KEY, 1) AS PATIENT_KEY,
               COALESCE(drpt.DATE_KEY, 1) AS NOTIFICATION_SENT_DT_KEY,
               COALESCE(dsub.DATE_KEY, 1) AS NOTIFICATION_SUBMIT_DT_KEY,
               eve.NOTIFICATION_KEY AS NOTIFICATION_KEY,
               1 AS COUNT,
               inv.INVESTIGATION_KEY,
               cnd.CONDITION_KEY,
               COALESCE(dupd.DATE_KEY, 1) AS NOTIFICATION_UPD_DT_KEY
        INTO #temp_ntf_event_table
        FROM dbo.nrt_investigation_notification nrt with (nolock)
                 LEFT JOIN dbo.nrt_notification_key nk with (nolock) ON nrt.notification_uid = nk.notification_uid
                 LEFT JOIN dbo.NOTIFICATION_EVENT eve with (nolock) ON eve.NOTIFICATION_KEY = nk.d_notification_key
                 LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON nrt.public_health_case_uid = inv.CASE_UID
                 LEFT JOIN dbo.D_PATIENT p with (nolock) ON nrt.local_patient_uid = p.PATIENT_UID
                 LEFT JOIN dbo.RDB_DATE drpt with (nolock) ON CAST(nrt.rpt_sent_time AS DATE) = drpt.DATE_MM_DD_YYYY
                 LEFT JOIN dbo.RDB_DATE dsub with (nolock) ON CAST(nrt.notif_add_time AS DATE) = dsub.DATE_MM_DD_YYYY
                 LEFT JOIN dbo.RDB_DATE dupd with (nolock) ON CAST(nrt.notif_last_chg_time AS DATE) = dupd.DATE_MM_DD_YYYY
                 LEFT JOIN dbo.condition cnd with (nolock) ON nrt.condition_cd = cnd.CONDITION_CD
        WHERE nrt.notification_uid in (SELECT value FROM STRING_SPLIT(@notification_uids, ','));

        /* Logging */
        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@notification_uids,500)
               );

        BEGIN TRANSACTION;

        -- APP-738 (sibling of APP-736): serialize the notification key-gen + dimension inserts and
        -- refresh the at-SP-start snapshots. #temp_ntf_table / #temp_ntf_event_table captured each
        -- notification's NOTIFICATION_KEY (the "is this new?" signal) at SP start with (NOLOCK);
        -- d_notification_key is IDENTITY and nrt_notification_key.notification_uid has no unique index,
        -- so two concurrent first-time batches for the same notification_uid both saw NULL, both minted
        -- a key, and both INSERTed the same NOTIFICATION/NOTIFICATION_EVENT PK -> Error 2627. Hold an
        -- exclusive applock for the rest of this transaction (@LockOwner='Transaction' releases it at
        -- COMMIT), then re-derive NOTIFICATION_KEY from the now-current key/dimension tables so a uid
        -- another session just processed is no longer treated as new.
        DECLARE @applock_rc int;
        EXEC @applock_rc = sp_getapplock @Resource = 'nrt_notification_key_keygen',
            @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 60000;
        IF @applock_rc < 0
            THROW 50026, 'sp_getapplock failed to acquire nrt_notification_key_keygen (serialization lost)', 1;

        UPDATE t
        SET t.NOTIFICATION_KEY = k.d_notification_key
        FROM #temp_ntf_table t
            JOIN dbo.nrt_notification_key k ON t.notification_uid = k.notification_uid
        WHERE t.NOTIFICATION_KEY IS NULL;

        UPDATE te
        SET te.NOTIFICATION_KEY = ne.NOTIFICATION_KEY
        FROM #temp_ntf_event_table te
            JOIN dbo.nrt_notification_key k ON te.notification_uid = k.notification_uid
            JOIN dbo.NOTIFICATION_EVENT ne ON ne.NOTIFICATION_KEY = k.d_notification_key
        WHERE te.NOTIFICATION_KEY IS NULL;

        SET @proc_step_name='Update dbo.nrt_notification_key';
        SET @proc_step_no = 2;

        update k
        SET
          k.updated_dttm = GETDATE()
        FROM dbo.nrt_notification_key k
          INNER JOIN #temp_ntf_table d
            ON K.d_notification_key = d.notification_key;

        set @rowcount=@@rowcount

        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@notification_uids,500)
               );


        SET @proc_step_name='Update NOTIFICATION Dimension';
        SET @proc_step_no = 3;

        /* Notification Update Operation */
        UPDATE dbo.NOTIFICATION
        SET NOTIFICATION_STATUS = ntf.NOTIFICATION_STATUS
          ,NOTIFICATION_COMMENTS = ntf.NOTIFICATION_COMMENTS
          ,NOTIFICATION_LOCAL_ID = ntf.NOTIFICATION_LOCAL_ID
          ,NOTIFICATION_SUBMITTED_BY = ntf.NOTIFICATION_SUBMITTED_BY
          ,NOTIFICATION_LAST_CHANGE_TIME = ntf.NOTIFICATION_LAST_CHANGE_TIME
        FROM #temp_ntf_table ntf
                 INNER JOIN dbo.NOTIFICATION n with (nolock) ON ntf.NOTIFICATION_KEY = n.NOTIFICATION_KEY
            AND ntf.NOTIFICATION_KEY IS NOT NULL;

        /* Logging */
        SET @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@notification_uids,500)
               );

        SET @proc_step_name='Update NOTIFICATION_EVENT Dimension';
        SET @proc_step_no = 4;

        /* Notification_Event Update Operation */
        UPDATE dbo.NOTIFICATION_EVENT
        SET PATIENT_KEY = ntfe.PATIENT_KEY
          ,NOTIFICATION_SENT_DT_KEY = ntfe.NOTIFICATION_SENT_DT_KEY
          ,NOTIFICATION_SUBMIT_DT_KEY = ntfe.NOTIFICATION_SUBMIT_DT_KEY
          ,COUNT = ntfe.COUNT
          ,INVESTIGATION_KEY = ntfe.INVESTIGATION_KEY
          ,CONDITION_KEY = ntfe.CONDITION_KEY
          ,NOTIFICATION_UPD_DT_KEY = ntfe.NOTIFICATION_UPD_DT_KEY
        FROM #temp_ntf_event_table ntfe
                 INNER JOIN dbo.NOTIFICATION_EVENT ne with (nolock) ON ntfe.NOTIFICATION_KEY = ne.NOTIFICATION_KEY
            AND ntfe.NOTIFICATION_KEY IS NOT NULL;

        /* Logging */
        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@notification_uids,500)
               );

        SET @proc_step_name='Insert into NOTIFICATION Dimension';
        SET @proc_step_no = 5;

        /* Notification Insert Operation */

        insert into dbo.nrt_notification_key(notification_uid)
        select notification_uid from #temp_ntf_table where notification_key is null order by notification_uid;

        INSERT INTO dbo.NOTIFICATION
        (NOTIFICATION_STATUS
        ,NOTIFICATION_COMMENTS
        ,NOTIFICATION_KEY
        ,NOTIFICATION_LOCAL_ID
        ,NOTIFICATION_SUBMITTED_BY
        ,NOTIFICATION_LAST_CHANGE_TIME
        )
        SELECT ntf.NOTIFICATION_STATUS
             ,ntf.NOTIFICATION_COMMENTS
             ,k.d_notification_key
             ,ntf.NOTIFICATION_LOCAL_ID
             ,ntf.NOTIFICATION_SUBMITTED_BY
             ,ntf.NOTIFICATION_LAST_CHANGE_TIME
        FROM #temp_ntf_table ntf
                 JOIN dbo.nrt_notification_key k ON ntf.notification_uid = k.notification_uid
        WHERE ntf.NOTIFICATION_KEY IS NULL;

        /* Logging */
        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@notification_uids,500)
               );

        SET @proc_step_name='Insert into NOTIFICATION_EVENT Dimension';
        SET @proc_step_no = 6;

        INSERT INTO dbo.NOTIFICATION_EVENT
        (PATIENT_KEY
        ,NOTIFICATION_SENT_DT_KEY
        ,NOTIFICATION_SUBMIT_DT_KEY
        ,NOTIFICATION_KEY
        ,COUNT
        ,INVESTIGATION_KEY
        ,CONDITION_KEY
        ,NOTIFICATION_UPD_DT_KEY
        )
        SELECT ntfe.PATIENT_KEY
             ,ntfe.NOTIFICATION_SENT_DT_KEY
             ,ntfe.NOTIFICATION_SUBMIT_DT_KEY
             ,k.d_notification_key
             ,ntfe.COUNT
             ,ntfe.INVESTIGATION_KEY
             ,ntfe.CONDITION_KEY
             ,ntfe.NOTIFICATION_UPD_DT_KEY
        FROM #temp_ntf_event_table ntfe
                 JOIN dbo.nrt_notification_key k with (nolock) ON ntfe.notification_uid = k.notification_uid
        WHERE ntfe.NOTIFICATION_KEY IS NULL;

        /* Logging */
        set @rowcount=@@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES (
                 @batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@notification_uids,500)
               );

        COMMIT TRANSACTION;


    IF EXISTS(
       select 1
        from dbo.nrt_investigation_notification notif
        inner join  #temp_ntf_event_table t on t.notification_uid = notif.notification_uid
    )
    BEGIN
        SELECT I.INVESTIGATION_KEY
             ,MIN(notif.rpt_sent_time) AS FIRSTNOTIFICATIONSENDDATE
        INTO #TMP_Notif
        FROM #temp_ntf_event_table AS I WITH(NOLOCK)
                LEFT JOIN dbo.NOTIFICATION_EVENT NE WITH(NOLOCK) ON NE.INVESTIGATION_KEY = I.INVESTIGATION_KEY
            LEFT JOIN dbo.nrt_notification_key NK WITH(NOLOCK)	ON NE.NOTIFICATION_KEY = NK.d_notification_key
            LEFT JOIN dbo.nrt_investigation_notification notif WITH(NOLOCK) ON notif.notification_uid= NK.notification_uid
        WHERE notif.NOTIF_STATUS = 'COMPLETED' and notif.RPT_SENT_TIME IS NOT NULL
        GROUP BY I.INVESTIGATION_KEY
        ORDER BY I.INVESTIGATION_KEY;

        IF EXISTS(select 1 from #TMP_Notif)
        BEGIN
            UPDATE ISD
            SET ISD.INIT_NND_NOT_DT = NND.FIRSTNOTIFICATIONSENDDATE
                FROM dbo.[HEPATITIS_DATAMART] ISD
                             INNER JOIN #TMP_Notif NND with (nolock) ON ISD.INVESTIGATION_KEY = NND.INVESTIGATION_KEY;
        END
    END

        SET @proc_step_name='SP_COMPLETE';
        SET @proc_step_no = 999;

        INSERT INTO [dbo].[job_flow_log]
        (
          batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1]
        )
        VALUES (
                 @batch_id
               ,current_timestamp
               ,current_timestamp
               ,@dataflow_name
               ,@package_name
               ,'COMPLETE'
               ,@proc_step_no
               ,@proc_step_name
               ,0
               ,LEFT(@notification_uids,500)
               );


        SELECT inv.CASE_UID                                     AS public_health_case_uid,
               pat.PATIENT_UID                                  AS patient_uid,
               null                                             AS observation_uid,
               CONCAT_WS(',',dtm.Datamart, ldf.datamart_name)   AS datamart,
               c.CONDITION_CD                                   AS condition_cd,
               dtm.Stored_Procedure                             AS stored_procedure,
               null                                             AS investigation_form_cd
        FROM #temp_ntf_event_table ntf
            LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON inv.INVESTIGATION_KEY = ntf.INVESTIGATION_KEY
            LEFT JOIN dbo.condition c with (nolock) ON c.CONDITION_KEY = ntf.CONDITION_KEY
            LEFT JOIN dbo.D_PATIENT pat with (nolock) ON pat.PATIENT_KEY = ntf.PATIENT_KEY
            INNER JOIN dbo.nrt_datamart_metadata dtm with (nolock) ON dtm.condition_cd = c.CONDITION_CD
            INNER JOIN dbo.nrt_srte_Condition_code ccd with (nolock) ON
                ccd.condition_cd = dtm.condition_cd AND ISNULL(dtm.legacy_form_cd, ccd.investigation_form_cd) = ccd.investigation_form_cd
            LEFT JOIN dbo.LDF_DATAMART_TABLE_REF ldf with (nolock) on ldf.condition_cd = dtm.condition_cd
        WHERE dtm.Datamart NOT IN ('Covid_Contact_Datamart','Covid_Lab_Datamart','Covid_Vaccination_Datamart');

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

        /* Logging */
        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[create_dttm],[update_dttm],[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count],[msg_description1],[Error_Description])
        VALUES
        (@batch_id,current_timestamp,current_timestamp,@dataflow_name,@package_name,'ERROR',@Proc_Step_no,@proc_step_name,0,LEFT(@notification_uids,500),@FullErrorMessage);


    SELECT
        0 AS public_health_case_uid,
        CAST(NULL AS BIGINT) AS patient_uid,
        CAST(NULL AS BIGINT) AS observation_uid,
        'Error' AS datamart,
        CAST(NULL AS VARCHAR(50))  AS condition_cd,
        @FullErrorMessage AS stored_procedure,
        CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
        WHERE 1=1;

    END CATCH
END;