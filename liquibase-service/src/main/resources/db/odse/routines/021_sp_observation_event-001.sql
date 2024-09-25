CREATE OR ALTER PROCEDURE [dbo].[sp_observation_event] @obs_id_list nvarchar(max)
AS
BEGIN

    BEGIN TRY

        DECLARE @batch_id BIGINT;
        SET @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint);

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

        SELECT
            act.act_uid,
            act.class_cd,
            act.mood_cd,
            oi.interpretation_cd,
            oi.interpretation_desc_txt
                ,results.*
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
                     o.status_cd,
                     o.cd_system_cd,
                     o.cd_system_desc_txt,
                     o.ctrl_cd_user_defined_1,
                     o.alt_cd,
                     o.alt_cd_desc_txt,
                     o.alt_cd_system_cd,
                     o.alt_cd_system_desc_txt,
                     o.method_cd,
                     o.method_desc_txt,
                     o.target_site_cd,
                     o.target_site_desc_txt,
                     o.txt,
                     o.add_user_id,
                     case
                         when o.add_user_id > 0 then (select * from dbo.fn_get_user_name(o.add_user_id))
                         end as      add_user_name,
                     o.last_chg_user_id,
                     case
                         when o.last_chg_user_id > 0 then (select * from dbo.fn_get_user_name(o.last_chg_user_id))
                         end as      last_chg_user_name,
                     o.add_time      add_time,
                     o.last_chg_time last_chg_time
                      ,nesteddata.person_participations
                      ,nesteddata.organization_participations
                      ,nesteddata.material_participations
                      ,nesteddata.followup_observations
                      ,nesteddata.parent_observations
                      ,nesteddata.act_ids
                      ,nesteddata.edx_ids
                      ,nesteddata.obs_reason
                      ,nesteddata.obs_txt
                      ,nesteddata.obs_code
                      ,nesteddata.obs_date
                      ,nesteddata.obs_num
              -- ,nesteddata.associated_investigations
              -- ,nesteddata.ldf_observation
              FROM Observation o WITH (NOLOCK) OUTER apply (
                  SELECT
                      *
                  FROM
                      -- follow up observations associated with observation-nested obs handling
                      (
                          SELECT
                              (
                                  SELECT
                                      o2.observation_uid as [result_observation_uid],
                                      o2.cd AS [cd],
                                      o2.cd_desc_txt AS [cd_desc_txt],
                                      o2.obs_domain_cd_st_1 AS [domain_cd_st_1]
                                  FROM
                                      observation o2 WITH (NOLOCK)
                                  WHERE
                                      o2.observation_uid
                                          IN (
                                          select sai.observation_uid
                                          from (
                                                   select act1.source_act_uid as observation_uid
                                                   from nbs_odse.dbo.act_relationship act1 with (nolock)
                                                   where source_act_uid is not null and act1.target_act_uid = o.observation_uid
                                                   union
                                                   select act2.source_act_uid as observation_uid from nbs_odse..act_relationship act1 with (nolock)
                                                                                                          left outer join nbs_odse.dbo.act_relationship act2 with (nolock)  on act1.source_act_uid=act2.target_act_uid
                                                   where act2.source_act_uid is not null and act1.target_act_uid  = o.observation_uid
                                                   union
                                                   select act3.source_act_uid as observation_uid from nbs_odse..act_relationship act1 with (nolock)
                                                                                                          left outer join nbs_odse.dbo.act_relationship act2 with (nolock) on act1.source_act_uid=act2.target_act_uid
                                                                                                          left outer join nbs_odse.dbo.act_relationship act3 with (nolock) on act2.source_act_uid=act3.target_act_uid
                                                   where act3.source_act_uid is not null and act1.target_act_uid  = o.observation_uid
                                                   union
                                                   select act4.source_act_uid as observation_uid from nbs_odse..act_relationship act1 with (nolock)
                                                                                                          left outer join nbs_odse.dbo.act_relationship act2 with (nolock) on act1.source_act_uid=act2.target_act_uid
                                                                                                          left outer join nbs_odse.dbo.act_relationship act3 with (nolock) on act2.source_act_uid=act3.target_act_uid
                                                                                                          left outer join nbs_odse.dbo.act_relationship act4 with (nolock) on act3.source_act_uid=act4.target_act_uid
                                                   where act4.source_act_uid is not null and act1.target_act_uid = o.observation_uid
                                               ) sai
                                      )
                                  FOR json path, INCLUDE_NULL_VALUES
                              ) AS followup_observations
                      ) AS followup_observations,
                      (
                          -- parent observation associated with current observation
                          SELECT
                              (
                                  SELECT
                                      ar.type_cd as [parent_type_cd],
                                      ar.source_act_uid as [report_observation_uid],
                                      o2.observation_uid as [parent_uid],
                                      o2.cd AS [parent_cd],
                                      o2.cd_desc_txt AS [parent_cd_desc_txt],
                                      o2.obs_domain_cd_st_1 AS [parent_domain_cd_st_1]
                                  FROM
                                      act_relationship ar WITH (NOLOCK)
                                          join observation o2  WITH (NOLOCK) on ar.target_act_uid = o2.observation_uid
                                  WHERE
                                      ar.source_act_uid = o.observation_uid
                                    and ar.target_class_cd = 'OBS'
                                  FOR json path,INCLUDE_NULL_VALUES
                              ) AS parent_observations
                      ) AS parent_observations,
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
                                      person.person_cd,
                                      person.person_parent_uid,
                                      person.person_record_status,
                                      person.person_last_chg_time,
                                      person.person_id_val,
                                      person.patient_id_type,
                                      person.person_id_assign_auth_cd,
                                      person.entity_record_status_cd,
                                      person.person_id_type_desc,
                                      person.last_nm,
                                      person.first_nm
                                  FROM
                                      participation p WITH (NOLOCK)
                                          JOIN (
                                          select
                                              person.[person_parent_uid],
                                              person.cd AS [person_cd],
                                              person.record_status_cd AS [person_record_status],
                                              person.last_chg_time AS [person_last_chg_time],
                                              e.root_extension_txt as [person_id_val],
                                              e.type_cd as [patient_id_type],
                                              e.assigning_authority_cd as [person_id_assign_auth_cd],
                                              e.record_status_cd as [entity_record_status_cd],
                                              cvg.code_short_desc_txt as [person_id_type_desc],
                                              STRING_ESCAPE(REPLACE(pn.last_nm, '-', ' '), 'json') AS [last_nm],
                                              STRING_ESCAPE(pn.first_nm, 'json')                   AS [first_nm],
                                              person.person_uid
                                          from
                                              dbo.person WITH (NOLOCK)
                                                  join nbs_odse.dbo.person_name pn WITH (NOLOCK) on pn.person_uid = person.person_uid
                                                  left join entity_id e WITH (NOLOCK) ON e.entity_uid = person.person_uid
                                                  left join nbs_srte.dbo.code_value_general as cvg WITH (NOLOCK) on e.type_cd = cvg.code
                                                  and cvg.code_set_nm = 'EI_TYPE'
                                      ) person on person.person_uid = p.subject_entity_uid
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
                                      -- m.cd_desc_txt AS [material_cd_desc_txt],
                                      m.nm						 as [material_nm],
                                      m.description				 as [material_details],
                                      m.qty						 as [material_collection_vol],
                                      m.qty_unit_cd				 as [material_collection_vol_unit],
                                      m.Cd_desc_txt				 as [material_desc],
                                      m.Risk_cd					 as [risk_cd],
                                      m.Risk_desc_txt			 as [risk_desc_txt]
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
                      ) AS act_ids,
                      (
                          SELECT
                              (
                                  SELECT
                                      EDX_Document_uid AS [edx_document_uid],
                                      act_uid AS [edx_act_uid],
                                      add_time AS [edx_add_time]
                                  FROM
                                      EDX_Document WITH (NOLOCK)
                                  WHERE
                                      act_uid = o.observation_uid FOR json path,INCLUDE_NULL_VALUES
                              ) AS edx_ids
                      ) AS edx_ids,
                      (
                          SELECT
                              (
                                  SELECT
                                      obr.observation_uid,
                                      obr.reason_cd,
                                      obr.reason_desc_txt
                                  FROM
                                      Observation_reason obr WITH (NOLOCK)
                                  WHERE
                                      obr.observation_uid = o.observation_uid
                                  FOR json path,INCLUDE_NULL_VALUES
                              ) AS obs_reason
                      ) AS obs_reason, -- can be more than 1
                      (
                          SELECT
                              (
                                  SELECT
                                      ot.observation_uid,
                                      ot.obs_value_txt_seq as [ovt_seq],
                                      ot.txt_type_cd as [ovt_txt_type_cd],
                                      REPLACE(REPLACE(ot.value_txt, CHAR(13), ' '), CHAR(10), ' ')	as [ovt_value_txt]
                                  FROM
                                      obs_value_txt ot WITH (NOLOCK)
                                  WHERE
                                      ot.observation_uid = o.observation_uid and ot.value_txt is not null
                                  FOR json path,INCLUDE_NULL_VALUES
                              ) AS obs_txt
                      ) AS obs_txt, -- can be more than 1
                      (
                          SELECT
                              (
                                  SELECT
                                      ob.observation_uid,
                                      STRING_ESCAPE(ob.display_name, 'json') AS [ovc_display_name],
                                      ob.code AS [ovc_code],
                                      ob.code_system_cd as [ovc_code_system_cd],
                                      ob.code_system_desc_txt as [ovc_code_system_desc_txt],
                                      ob.alt_cd AS [ovc_alt_cd],
                                      ob.alt_cd_desc_txt AS [ovc_alt_cd_desc_txt],
                                      ob.alt_cd_system_cd AS [ovc_alt_cd_system_cd]
                                  FROM
                                      obs_value_coded ob WITH (NOLOCK)
                                  WHERE
                                      ob.observation_uid = o.observation_uid
                                  FOR json path,INCLUDE_NULL_VALUES
                              ) AS obs_code
                      ) AS obs_code, -- can be more than 1
                      (
                          SELECT
                              (
                                  SELECT
                                      od.observation_uid,
                                      od.from_time as [ovd_from_date],
                                      od.to_time as [ovd_to_date]
                                  FROM
                                      obs_value_date od WITH (NOLOCK)
                                  WHERE
                                      od.observation_uid = o.observation_uid
                                  FOR json path,INCLUDE_NULL_VALUES
                              ) AS obs_date
                      ) AS obs_date, -- can be more than 1
                      (
                          SELECT
                              (
                                  SELECT
                                      ovn.observation_uid,
                                      ovn.comparator_cd_1 as [ovn_comparator_cd_1],
                                      ovn.numeric_value_1 as [ovn_numeric_value_1],
                                      ovn.separator_cd as [ovn_separator_cd],
                                      ovn.numeric_value_2 as [ovn_numeric_value_2],
                                      ovn.numeric_unit_cd as [ovn_numeric_unit_cd], -- asresult_units,
                                      substring(ovn.low_range,1,20) as [ovn_low_range], -- as ref_range_frm,
                                      substring(ovn.high_range,1,20) as [ovn_high_range] -- as ref_range_to,
                                  FROM
                                      obs_value_numeric ovn WITH (NOLOCK)
                                  WHERE
                                      ovn.observation_uid = o.observation_uid
                                  FOR json path,INCLUDE_NULL_VALUES
                              ) AS obs_num
                      ) AS obs_num -- can be more than 1

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
                 join act WITH (NOLOCK) ON results.observation_uid = act.act_uid
                 left outer join nbs_odse.dbo.observation_interp oi WITH (NOLOCK) on results.observation_uid = oi.observation_uid --1:1

        ;

        -- select * from dbo.Observation_Dim_Event;

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (     batch_id
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