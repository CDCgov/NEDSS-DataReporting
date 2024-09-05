CREATE OR ALTER PROCEDURE dbo.sp_observation_event @obs_id_list nvarchar(max)
AS
BEGIN

    BEGIN TRY

        DECLARE @batch_id BIGINT;
        SET @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint)
        INSERT INTO [rdb_modern].[dbo].[job_flow_log] (
                                                        batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
                                                      ,[Msg_Description1]
        )
        VALUES (
                 @batch_id
               ,'Observation PRE-Processing Event'
               ,'NBS_ODSE.sp_observation_event'
               ,'START'
               ,0
               ,LEFT('Pre ID-' + @obs_id_list,199)
               ,0
               ,LEFT(@obs_id_list,199)
               );
        SELECT act.act_uid,
               act.class_cd,
               act.mood_cd,
               results.*
-- into dbo.Observation_Dim_Event
        FROM (SELECT o.observation_uid,
                     o.obs_domain_cd_st_1,
                     o.cd_desc_txt,
                     o.record_status_cd,
                     o.program_jurisdiction_oid,
                     o.prog_area_cd,
                     o.jurisdiction_cd,
                     o.pregnant_ind_cd,
                     o.local_id      local_id,
                     o.activity_to_time,
                     o.effective_from_time,
                     o.rpt_to_state_time,
                     o.electronic_ind,
                     o.version_ctrl_nbr,
                     o.ctrl_cd_display_form,
                     o.processing_decision_cd,
                     o.cd,
                     o.shared_ind,
                     o.add_user_id,
                     case
                         when o.add_user_id > 0 then (select * from dbo.fn_get_user_name(o.add_user_id))
                         end as      add_user_name,
                     o.last_chg_user_id,
                     case
                         when o.last_chg_user_id > 0 then (select * from dbo.fn_get_user_name(o.last_chg_user_id))
                         end as      last_chg_user_name,
                     -- (select * from dbo.get_user_name(o.add_user_id, o.last_chg_user_id)) as t ,
                     o.add_time      add_time,
                     o.last_chg_time last_chg_time,
                     nesteddata.person_participations,
                     nesteddata.organization_participations,
                     nesteddata.material_participations,
                     nesteddata.followup_observations,
                     -- nesteddata.associated_investigations,
                     nesteddata.act_ids
              -- ,nesteddata.ldf_observation
              FROM Observation o WITH (NOLOCK) OUTER apply (
                  SELECT
                      *
                  FROM
                      (
                          -- follow up observations associated with observation
                          SELECT
                              (
                                  SELECT
                                      o2.cd AS [cd],
                                      o2.cd_desc_txt AS [cd_desc_txt],
                                      o2.obs_domain_cd_st_1 AS [domain_cd_st_1],
                                      o2.status_cd AS [status_cd],
                                      o2.alt_cd AS [alt_cd],
                                      STRING_ESCAPE(o2.alt_cd_desc_txt, 'json') AS [alt_cd_desc_txt],
                                      o2.alt_cd_system_cd AS [alt_cd_system_cd],
                                      STRING_ESCAPE(ovc.display_name, 'json') AS [display_name],
                                      ovc.code AS [ovc_code],
                                      ovc.alt_cd AS [ovc_alt_cd],
                                      ovc.alt_cd_desc_txt AS [ovc_alt_cd_desc_txt],
                                      ovc.alt_cd_system_cd AS [ovc_alt_cd_system_cd]
                                          ,o2.observation_uid as [result_observation_uid]
                                  FROM
                                      observation o2 WITH (NOLOCK)
                                          LEFT JOIN Obs_value_coded ovc WITH (NOLOCK) ON ovc.observation_uid = o2.observation_uid
                                  WHERE
                                      o2.observation_uid in(
                                          SELECT
                                              ar.source_act_uid
                                          FROM
                                              act_relationship ar WITH (NOLOCK)
                                          WHERE
                                              ar.target_act_uid = o.observation_uid
                                      ) FOR json path,INCLUDE_NULL_VALUES
                              ) AS followup_observations
                      ) AS followup_observations,
                      (
                          -- persons associated with observation
                          SELECT
                              (
                                  SELECT
                                      p.act_uid AS [act_uid],
                                      p.type_cd AS [type_cd],
                                      p.subject_entity_uid AS [entity_id],
                                      p.subject_class_cd AS [subject_class_cd],
                                      p.record_status_cd AS [participation_record_status],
                                      p.last_chg_time AS [participation_last_change_time],
                                      p.type_desc_txt AS [type_desc_txt],
                                      STRING_ESCAPE(person.first_nm, 'json') AS [first_name],
                                      STRING_ESCAPE(person.last_nm, 'json') AS [last_name],
                                      person.local_id AS [local_id],
                                      person.birth_time AS [birth_time],
                                      person.curr_sex_cd AS [curr_sex_cd],
                                      person.cd AS [person_cd],
                                      person.person_parent_uid AS [person_parent_uid],
                                      person.record_status_cd AS [person_record_status],
                                      person.last_chg_time AS [person_last_chg_time]
                                  FROM
                                      participation p WITH (NOLOCK)
                                          JOIN person WITH (NOLOCK) ON person.person_uid = (
                                          select
                                              person.person_parent_uid
                                          from
                                              dbo.person WITH (NOLOCK)
                                          where
                                              person.person_uid = p.subject_entity_uid
                                      )
                                  WHERE
                                      p.act_uid = o.observation_uid FOR json path,INCLUDE_NULL_VALUES
                              ) AS person_participations
                      ) AS person_participations,
                      -- organizations associated with observation
                      (
                          SELECT
                              (
                                  SELECT
                                      p.act_uid AS [act_uid],
                                      p.type_cd AS [type_cd],
                                      p.subject_entity_uid AS [entity_id],
                                      p.subject_class_cd AS [subject_class_cd],
                                      p.record_status_cd AS [record_status],
                                      p.type_desc_txt AS [type_desc_txt],
                                      p.last_chg_time AS [last_change_time],
                                      STRING_ESCAPE(org.display_nm, 'json') AS [name],
                                      org.last_chg_time AS [org_last_change_time]
                                  FROM
                                      dbo.participation p WITH (NOLOCK)
                                          JOIN dbo.organization org WITH (NOLOCK) ON org.organization_uid = p.subject_entity_uid
                                  WHERE
                                      p.act_uid = o.observation_uid FOR json path,INCLUDE_NULL_VALUES
                              ) AS organization_participations
                      ) AS organization_participations,
                      (
                          -- material participations associated with observation
                          SELECT
                              (
                                  SELECT
                                      p.act_uid AS [act_uid],
                                      p.type_cd AS [type_cd],
                                      p.subject_entity_uid AS [entity_id],
                                      p.subject_class_cd AS [subject_class_cd],
                                      p.record_status_cd AS [record_status],
                                      p.type_desc_txt AS [type_desc_txt],
                                      p.last_chg_time AS [last_change_time],
                                      STRING_ESCAPE(m.cd, 'json') AS [material_cd],
                                      m.cd_desc_txt AS [material_cd_desc_txt]
                                  FROM
                                      participation p WITH (NOLOCK)
                                          JOIN material m WITH (NOLOCK) ON m.material_uid = p.subject_entity_uid
                                  WHERE
                                      p.act_uid = o.observation_uid FOR json path,INCLUDE_NULL_VALUES
                              ) AS material_participations
                      ) AS material_participations,
                      -- act_ids associated with observation
                      (
                          SELECT
                              (
                                  SELECT
                                      act_uid AS [id],
                                      act_id_seq AS [act_id_seq],
                                      record_status_cd AS [record_status],
                                      STRING_ESCAPE(root_extension_txt, 'json') AS [root_extension_txt],
                                      type_cd AS [type_cd],
                                      type_desc_txt AS [type_desc_txt],
                                      last_chg_time AS [act_last_change_time]
                                  FROM
                                      act_id WITH (NOLOCK)
                                  WHERE
                                      act_uid = o.observation_uid FOR json path,INCLUDE_NULL_VALUES
                              ) AS act_ids
                      ) AS act_ids
                  /* -- ldf_observation associated with observation
                   (
                     SELECT
                       (
                        select * from nbs_odse..v_ldf_observation ldf
                          WHERE   ldf.observation_uid = o.observation_uid
                          Order By ldf.observation_uid, ldf.display_order_nbr
                                 FOR json path,INCLUDE_NULL_VALUES
                       ) AS ldf_observation
                   ) AS ldf_observation*/
                  /* , -- public health cases associated with lab report
                   (
                     SELECT
                       (
                         SELECT
                           phc.public_health_case_uid AS [public_health_case_uid],
                           phc.last_chg_time AS [last_change_time],
                           phc.cd_desc_txt AS [cd_desc_txt],
                           phc.local_id AS [local_id],
                           ar.last_chg_time AS [act_relationship_last_change_time]
                         FROM
                           Public_health_case phc WITH (NOLOCK)
                           JOIN Act_relationship ar WITH (NOLOCK) ON ar.target_act_uid = phc.public_health_case_uid
                         WHERE
                           phc.public_health_case_uid in (
                             SELECT
                               ar.target_act_uid
                             FROM
                               Act_relationship ar WITH (NOLOCK)
                             WHERE
                               ar.source_act_uid = o.observation_uid
                                 AND source_class_cd = 'OBS'
                               AND target_class_cd = 'CASE'
                        ) FOR JSON path,INCLUDE_NULL_VALUES
                       ) AS associated_investigations
                   ) as associated_investigations*/
              ) AS nesteddata
              WHERE
                  o.observation_uid in (SELECT value FROM STRING_SPLIT(@obs_id_list
                      , ','))) as results
                 JOIN act WITH (NOLOCK)
                      ON results.observation_uid = act.act_uid
        ;

-- select * from dbo.Observation_Dim_Event;

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
               , 'Observation PRE-Processing Event'
               , 'NBS_ODSE.sp_observation_event'
               , 'COMPLETE'
               , 0
               , LEFT ('Pre ID-' + @obs_id_list, 199)
               , 0
               , LEFT (@obs_id_list, 199)
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
               , 'Observation PRE-Processing Event'
               , 'NBS_ODSE.sp_observation_event'
               , 'ERROR: ' + @ErrorMessage
               , 0
               , LEFT ('Pre ID-' + @obs_id_list, 199)
               , 0
               , LEFT (@obs_id_list, 199)
               );

        return @ErrorMessage;

    END CATCH

END;