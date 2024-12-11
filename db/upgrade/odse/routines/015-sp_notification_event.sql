CREATE OR ALTER PROCEDURE [dbo].[sp_notification_event] @notification_list nvarchar(max)
AS
BEGIN

    BEGIN TRY

        DECLARE @batch_id BIGINT;


        SET @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint);
        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
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
                  nesteddata.investigation_notifications,
                  nesteddata.notification_history
              FROM
                  notification notif WITH (NOLOCK)
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
                                          phc.cd_desc_txt as 'condition_desc'
                                      FROM
                                          act_relationship act WITH (NOLOCK)
                                              join public_health_case phc WITH (NOLOCK) on act.target_act_uid = phc.public_health_case_uid
                                              join participation part with (nolock) ON part.type_cd='SubjOfPHC' AND part.act_uid=act.target_act_uid
                                              join person per with (nolock) ON per.cd='PAT' AND per.person_uid = part.subject_entity_uid
                                      WHERE
                                          act.source_act_uid = notif.notification_uid
                                        AND notif.cd not in ('EXP_NOTF', 'SHARE_NOTF', 'EXP_NOTF_PHDC','SHARE_NOTF_PHDC')
                                        AND act.source_class_cd = 'NOTF'
                                        AND act.target_class_cd = 'CASE' FOR json path,INCLUDE_NULL_VALUES
                                  ) AS investigation_notifications
                          ) AS investigation_notifications,
                          (
                              select
                                  (
                                      select distinct min(case
                                          when version_ctrl_nbr = 1
                                              then nf.record_status_cd
                                          end) as first_notification_status
                                                    ,sum(case
                                          when nf.record_status_cd = 'REJECTED'
                                              then 1
                                          else 0
                                          end) notif_rejected_count
                                                    ,sum(case
                                          when nf.record_status_cd = 'APPROVED'
                                              or nf.record_status_cd = 'PEND_APPR'
                                              then 1
                                          when nf.record_status_cd = 'REJECTED'
                                              then -1
                                          else 0
                                          end) notif_created_count
                                                    ,sum(case
                                          when nf.record_status_cd = 'COMPLETED'
                                              then 1
                                          else 0
                                          end) notif_sent_count
                                                    ,min(case
                                          when nf.record_status_cd = 'COMPLETED'
                                              then rpt_sent_time
                                          end) as first_notification_send_date
                                                    ,
                                          sum(case
                                              when nf.record_status_cd = 'PEND_APPR'
                                                  then 1
                                              else 0
                                              end) notif_created_pendings_count
                                                    ,max(case
                                          when nf.record_status_cd = 'APPROVED'
                                              or nf.record_status_cd = 'PEND_APPR'
                                              then nf.last_chg_time
                                          end) as last_notification_date
                                                    ,
                                                    --done?
                                          max(case
                                              when nf.record_status_cd = 'COMPLETED'
                                                  then rpt_sent_time
                                              end) as last_notification_send_date
                                                    ,
                                                    --done?
                                          min(nf.add_time) as first_notification_date
                                                    ,
                                                    --done
                                          min(nf.add_user_id) as first_notification_submitted_by
                                                    ,
                                                    --done
                                          min(nf.add_user_id) as last_notification_submittedby
                                                    --done
                                                    --min(case when record_status_cd='completed' then  last_chg_user_id end) as firstnotificationsubmittedby,
                                                    ,min(case
                                          when nf.record_status_cd = 'COMPLETED'
                                              and rpt_sent_time is not null
                                              then rpt_sent_time
                                          end) as notificationdate
                                      from nbs_odse.dbo.act_relationship ar with (nolock)
                                               inner join nbs_odse.dbo.notification_hist nf with (nolock) on ar.source_act_uid = nf.notification_uid
                                      where
                                          ar.source_act_uid = notif.notification_uid
                                        and
                                          source_class_cd = 'NOTF'
                                        and target_class_cd = 'CASE'
                                        and nf.cd='NOTF'
                                        and (
                                          nf.record_status_cd = 'COMPLETED'
                                              OR nf.record_status_cd = 'MSG_FAIL'
                                              OR nf.record_status_cd = 'REJECTED'
                                              OR nf.record_status_cd = 'PEND_APPR'
                                              OR nf.record_status_cd = 'APPROVED'
                                          )
                                      FOR json path,INCLUDE_NULL_VALUES
                                  ) AS notification_history
                          ) AS notification_history
                  ) as nesteddata
              WHERE
                  notif.notification_uid in (SELECT value FROM STRING_SPLIT(@notification_list
                      , ','))) AS results



        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
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

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
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
               , 'ERROR: ' + @ErrorMessage
               , 0
               , LEFT ('Pre ID-' + @notification_list, 199)
               , 0
               , LEFT (@notification_list, 199)
               );
        return @ErrorMessage;

    END CATCH

END;