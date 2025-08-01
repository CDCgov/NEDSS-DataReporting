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
                                              join dbo.public_health_case phc WITH (NOLOCK) on act.target_act_uid = phc.public_health_case_uid
                                              left join dbo.participation part with (nolock) ON part.type_cd='SubjOfPHC' AND part.act_uid=act.target_act_uid
                                              left join dbo.person per with (nolock) ON per.cd='PAT' AND per.person_uid = part.subject_entity_uid
                                              left join dbo.v_notification_hist nh  with (nolock) on nh.public_health_case_uid = phc.public_health_case_uid
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