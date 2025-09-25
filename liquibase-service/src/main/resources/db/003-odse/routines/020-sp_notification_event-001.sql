IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_notification_event]')
                                      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
    BEGIN
        DROP PROCEDURE [dbo].[sp_notification_event]
    END
GO

CREATE PROCEDURE [dbo].[sp_notification_event] @notification_list nvarchar(max)
AS
BEGIN

    BEGIN TRY

        DECLARE @batch_id BIGINT;


        SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);
        INSERT INTO [rdb].[dbo].[job_flow_log]
        ( batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Msg_Description1])
        VALUES (
                 @batch_id
               , 'Notification PRE-Processing Event'
               , 'NBS_ODSE.sp_notification_event'
               , 'START'
               , 0
               , LEFT ('Pre ID-' + @notification_list, 199)
               , 0
               , LEFT (@notification_list, 199)
               );


        --Payload structure

        SELECT
            results.*
        FROM (SELECT
                  notif.notification_uid,
                  nesteddata.investigation_notifications
              FROM
                  dbo.notification notif WITH (NOLOCK)
                      inner join dbo.act_relationship act WITH (NOLOCK) on act.source_act_uid = notif.notification_uid
                      inner join dbo.public_health_case phc WITH (NOLOCK) on act.target_act_uid = phc.public_health_case_uid
                      outer apply (
                      select
                          *
                      from
                          (
                              SELECT
                                  (
                                      SELECT
                                          act.source_act_uid ,
                                          act.target_act_uid as public_health_case_uid,
                                          act.source_class_cd,
                                          act.target_class_cd,
                                          act.type_cd as act_type_cd,
                                          act.status_cd,
                                          notif.notification_uid,
                                          notif.prog_area_cd,
                                          notif.program_jurisdiction_oid,
                                          notif.jurisdiction_cd,
                                          notif.record_status_time,
                                          notif.status_time,
                                          notif.rpt_sent_time,
                                          notif.record_status_cd as 'notif_status',
                                          notif.local_id as 'notif_local_id',
                                          notif.txt as 'notif_comments',
                                          notif.add_time as 'notif_add_time',
                                          notif.add_user_id as 'notif_add_user_id',
                                          case when notif.add_user_id > 0 then (select * from dbo.fn_get_user_name(notif.add_user_id))
                                              end as 'notif_add_user_name',
                                          notif.last_chg_user_id as 'notif_last_chg_user_id',
                                          case when notif.last_chg_user_id > 0 then (select * from dbo.fn_get_user_name(notif.last_chg_user_id))
                                              end as 'notif_last_chg_user_name',
                                          notif.last_chg_time as 'notif_last_chg_time',
                                          per.local_id as 'local_patient_id',
                                          per.person_uid as 'local_patient_uid',
                                          phc.cd as 'condition_cd',
                                          phc.cd_desc_txt as 'condition_desc',
                                          nh.first_notification_status,
                                          nh.notif_rejected_count,
                                          nh.notif_created_count,
                                          nh.notif_sent_count,
                                          nh.first_notification_send_date,
                                          nh.notif_created_pending_count,
                                          nh.last_notification_date,
                                          nh.last_notification_send_date,
                                          nh.first_notification_date,
                                          nh.first_notification_submitted_by,
                                          nh.last_notification_submitted_by,
                                          nh.notification_date
                                      FROM
                                          dbo.act_relationship act WITH (NOLOCK)
                                              inner join dbo.public_health_case phc WITH (NOLOCK) on act.target_act_uid = phc.public_health_case_uid
                                              left join dbo.participation part with (nolock) ON part.type_cd='SubjOfPHC' AND part.act_uid=act.target_act_uid
                                              left join dbo.person per with (nolock) ON per.cd='PAT' AND per.person_uid = part.subject_entity_uid
                                              LEFT JOIN (
                                              SELECT *
                                              FROM (
                                                       SELECT
                                                           -- Aggregate across all versions
                                                           MIN(CASE WHEN VERSION_CTRL_NBR = 1 THEN RECORD_STATUS_CD END) AS first_notification_status,
                                                           SUM(CASE WHEN RECORD_STATUS_CD = 'REJECTED' THEN 1 ELSE 0 END) AS notif_rejected_count,
                                                           SUM(CASE
                                                                   WHEN RECORD_STATUS_CD IN ('APPROVED', 'PEND_APPR') THEN 1
                                                                   WHEN RECORD_STATUS_CD = 'REJECTED' THEN -1
                                                                   ELSE 0
                                                               END) AS notif_created_count,
                                                           SUM(CASE WHEN RECORD_STATUS_CD = 'COMPLETED' THEN 1 ELSE 0 END) AS notif_sent_count,
                                                           MIN(CASE WHEN RECORD_STATUS_CD = 'COMPLETED' THEN RPT_SENT_TIME END) AS first_notification_send_date,
                                                           SUM(CASE WHEN RECORD_STATUS_CD = 'PEND_APPR' THEN 1 ELSE 0 END) AS notif_created_pending_count,
                                                           MAX(CASE WHEN RECORD_STATUS_CD IN ('APPROVED', 'PEND_APPR') THEN LAST_CHG_TIME END) AS last_notification_date,
                                                           MAX(CASE WHEN RECORD_STATUS_CD = 'COMPLETED' THEN RPT_SENT_TIME END) AS last_notification_send_date,
                                                           MIN(ADD_TIME) AS first_notification_date,
                                                           NULLIF(MAX(CASE WHEN VERSION_CTRL_NBR != 1 THEN -1 ELSE ADD_USER_ID END), -1) AS first_notification_submitted_by,
                                                           NULLIF(MAX(CASE WHEN notif_latest_rownum = 1 THEN LAST_CHG_USER_ID ELSE -1 END), -1) AS last_notification_submitted_by,
                                                           MIN(CASE WHEN RECORD_STATUS_CD = 'COMPLETED' AND RPT_SENT_TIME IS NOT NULL THEN RPT_SENT_TIME END) AS notification_date,
                                                           PUBLIC_HEALTH_CASE_UID,
                                                           NOTIFICATION_UID
                                                       FROM (
                                                                SELECT
                                                                    *,
                                                                    ROW_NUMBER() OVER (PARTITION BY PUBLIC_HEALTH_CASE_UID ORDER BY VERSION_CTRL_NBR DESC) notif_latest_rownum
                                                                FROM (
                                                                         -- Notification_HIST branch
                                                                         SELECT
                                                                             AR.TARGET_ACT_UID AS PUBLIC_HEALTH_CASE_UID,
                                                                             AR.TARGET_CLASS_CD,
                                                                             AR.SOURCE_ACT_UID,
                                                                             AR.SOURCE_CLASS_CD,
                                                                             NF.VERSION_CTRL_NBR,
                                                                             NF.ADD_TIME,
                                                                             NF.ADD_USER_ID,
                                                                             NF.RPT_SENT_TIME,
                                                                             NF.RECORD_STATUS_CD,
                                                                             NF.RECORD_STATUS_TIME,
                                                                             NF.LAST_CHG_TIME,
                                                                             NF.LAST_CHG_USER_ID,
                                                                             'Y' AS HIST_IND,
                                                                             NF.TXT
                                                                                 ,CAST(NULL AS INT) AS NOTIFSENTCOUNT
                                                                                 ,CAST(NULL AS INT) AS NOTIFREJECTEDCOUNT
                                                                                 ,CAST(NULL AS INT) AS NOTIFCREATEDCOUNT
                                                                                 ,CAST(NULL AS INT) AS X1
                                                                                 ,CAST(NULL AS INT) AS X2
                                                                                 ,CAST(NULL AS DATETIME) AS FIRSTNOTIFICATIONSENDDATE
                                                                                 ,CAST(NULL AS DATETIME) AS NOTIFICATIONDATE
                                                                                 ,NF.NOTIFICATION_UID
                                                                         FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
                                                                                  INNER JOIN NBS_ODSE.DBO.NOTIFICATION_HIST NF WITH (NOLOCK)
                                                                                             ON AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
                                                                                                 AND AR.TARGET_ACT_UID = phc.PUBLIC_HEALTH_CASE_UID
                                                                         WHERE AR.SOURCE_CLASS_CD = 'NOTF'
                                                                           AND AR.TARGET_CLASS_CD = 'CASE'
                                                                           AND NF.CD = 'NOTF'
                                                                           AND NF.RECORD_STATUS_CD IN (
                                                                                                       'COMPLETED', 'MSG_FAIL', 'REJECTED', 'PEND_APPR', 'APPROVED'
                                                                             )
                                                                         UNION ALL
                                                                         SELECT
                                                                             AR.TARGET_ACT_UID AS PUBLIC_HEALTH_CASE_UID,
                                                                             AR.TARGET_CLASS_CD,
                                                                             AR.SOURCE_ACT_UID,
                                                                             AR.SOURCE_CLASS_CD,
                                                                             NF.VERSION_CTRL_NBR,
                                                                             NF.ADD_TIME,
                                                                             NF.ADD_USER_ID,
                                                                             NF.RPT_SENT_TIME,
                                                                             NF.RECORD_STATUS_CD,
                                                                             NF.RECORD_STATUS_TIME,
                                                                             NF.LAST_CHG_TIME,
                                                                             NF.LAST_CHG_USER_ID,
                                                                             'N' AS HIST_IND
                                                                                 , NULL AS TXT
                                                                                 ,CAST(NULL AS INT) AS NOTIFSENTCOUNT
                                                                                 ,CAST(NULL AS INT) AS NOTIFREJECTEDCOUNT
                                                                                 ,CAST(NULL AS INT) AS NOTIFCREATEDCOUNT
                                                                                 ,CAST(NULL AS INT) AS X1
                                                                                 ,CAST(NULL AS INT) AS X2
                                                                                 ,CAST(NULL AS DATETIME) AS FIRSTNOTIFICATIONSENDDATE
                                                                                 ,CAST(NULL AS DATETIME) AS NOTIFICATIONDATE
                                                                                 ,NF.NOTIFICATION_UID
                                                                         FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
                                                                                  INNER JOIN NBS_ODSE.DBO.NOTIFICATION NF WITH (NOLOCK)
                                                                                             ON AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
                                                                                                 AND AR.TARGET_ACT_UID = phc.PUBLIC_HEALTH_CASE_UID
                                                                         WHERE AR.SOURCE_CLASS_CD = 'NOTF'
                                                                           AND AR.TARGET_CLASS_CD = 'CASE'
                                                                           AND NF.CD = 'NOTF'
                                                                           AND NF.RECORD_STATUS_CD IN (
                                                                                                       'COMPLETED', 'MSG_FAIL', 'REJECTED', 'PEND_APPR', 'APPROVED'
                                                                             )
                                                                     ) AS combined_sources
                                                            ) AS ranked
                                                       GROUP BY PUBLIC_HEALTH_CASE_UID, NOTIFICATION_UID
                                                   ) AS final_ranked
                                          ) AS nh ON nh.PUBLIC_HEALTH_CASE_UID = phc.PUBLIC_HEALTH_CASE_UID
                                      WHERE
                                          act.source_act_uid = notif.notification_uid
                                        AND notif.cd not in ('EXP_NOTF', 'SHARE_NOTF', 'EXP_NOTF_PHDC','SHARE_NOTF_PHDC')
                                        AND act.source_class_cd = 'NOTF'
                                        AND act.target_class_cd = 'CASE' FOR json path,INCLUDE_NULL_VALUES
                                  ) AS investigation_notifications
                          ) AS investigation_notifications
                  ) as nesteddata
              WHERE
                  notif.notification_uid in (SELECT value FROM STRING_SPLIT(@notification_list
                      , ','))) AS results



        INSERT INTO [rdb].[dbo].[job_flow_log]
        (      batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Msg_Description1])
        VALUES (
                 @batch_id
               , 'Notification PRE-Processing Event'
               , 'NBS_ODSE.sp_notification_event'
               , 'COMPLETE'
               , 0
               , LEFT ('Pre ID-' + @notification_list, 199)
               , 0
               , LEFT (@notification_list, 199)
               );

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


        INSERT INTO [rdb].[dbo].[job_flow_log]
        (      batch_id
        , [Dataflow_Name]
        , [package_Name]
        , [Status_Type]
        , [step_number]
        , [step_name]
        , [row_count]
        , [Msg_Description1]
        , [Error_Description])
        VALUES (
                 @batch_id
               , 'Notification PRE-Processing Event'
               , 'NBS_ODSE.sp_notification_event'
               , 'ERROR'
               , 0
               , 'Notification PRE-Processing Event'
               , 0
               , LEFT (@notification_list, 199)
               , @FullErrorMessage
               );
        return @FullErrorMessage;

    END CATCH

END;