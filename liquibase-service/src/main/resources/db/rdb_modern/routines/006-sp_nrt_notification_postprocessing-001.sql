CREATE OR ALTER PROCEDURE [dbo].[sp_nrt_notification_postprocessing] @notification_uids nvarchar(max), @debug bit = 'false'
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

        set @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint);

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
        ,[msg_description1]
        ,[row_count]
        )
        VALUES (
                 @batch_id
               ,@create_dttm
               ,@update_dttm
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,0
               ,'SP_Start'
               ,LEFT(@notification_uids,500)
               ,0
               );

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
        FROM dbo.nrt_investigation_notification nrt
            LEFT JOIN dbo.nrt_notification_key nk with (nolock) ON nrt.notification_uid = nk.notification_uid
        WHERE nrt.notification_uid in (SELECT value FROM STRING_SPLIT(@notification_uids, ','));

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
        FROM dbo.nrt_investigation_notification nrt
                 LEFT JOIN dbo.nrt_notification_key nk ON nrt.notification_uid = nk.notification_uid
                 LEFT JOIN dbo.NOTIFICATION_EVENT eve with (nolock) ON eve.NOTIFICATION_KEY = nk.d_notification_key
                 LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON nrt.public_health_case_uid = inv.CASE_UID
                 LEFT JOIN dbo.D_PATIENT p with (nolock) ON nrt.local_patient_uid = p.PATIENT_UID
                 LEFT JOIN dbo.RDB_DATE drpt with (nolock) ON CAST(nrt.rpt_sent_time AS DATE) = drpt.DATE_MM_DD_YYYY
                 LEFT JOIN dbo.RDB_DATE dsub with (nolock) ON CAST(nrt.notif_add_time AS DATE) = dsub.DATE_MM_DD_YYYY
                 LEFT JOIN dbo.RDB_DATE dupd with (nolock) ON CAST(nrt.notif_last_chg_time AS DATE) = dupd.DATE_MM_DD_YYYY
                 LEFT JOIN dbo.CONDITION cnd with (nolock) ON nrt.condition_cd = cnd.CONDITION_CD
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
        SET @proc_step_name='Update NOTIFICATION Dimension';
        SET @proc_step_no = 2;

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
        SET @proc_step_no = 3;

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
        SET @proc_step_no = 4;

        /* Notification Insert Operation */
        -- delete from the key table to generate new keys for the resulting new data to be inserted
        -- delete from dbo.nrt_notification_key;
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
        SET @proc_step_no = 5;

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

        SET @proc_step_name='SP_COMPLETE';
        SET @proc_step_no = 6;

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


        SELECT inv.CASE_UID                       AS public_health_case_uid,
               pat.PATIENT_UID                    AS patient_uid,
               dtm.Datamart                       AS datamart,
               c.CONDITION_CD                     AS condition_cd,
               dtm.Stored_Procedure               AS stored_procedure
        FROM #temp_ntf_event_table ntf
            LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON inv.INVESTIGATION_KEY = ntf.INVESTIGATION_KEY
            LEFT JOIN dbo.CONDITION c ON c.CONDITION_KEY = ntf.CONDITION_KEY
            LEFT JOIN dbo.D_PATIENT pat with (nolock) ON pat.PATIENT_KEY = ntf.PATIENT_KEY
            LEFT JOIN dbo.nrt_datamart_metadata dtm with (nolock) ON dtm.condition_cd = c.CONDITION_CD;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        /* Logging */
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
        VALUES
            (
              @batch_id
            ,current_timestamp
            ,current_timestamp
            ,@dataflow_name
            ,@package_name
            ,'ERROR'
            ,@Proc_Step_no
            , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
            ,0
            ,LEFT(@notification_uids,500)
            );


        RETURN @ErrorMessage;

    END CATCH
END;