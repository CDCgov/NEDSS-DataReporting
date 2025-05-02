CREATE OR ALTER PROCEDURE [dbo].[sp_investigation_event] @phc_id_list nvarchar(max)
AS
BEGIN

    BEGIN TRY

        DECLARE @batch_id BIGINT;
        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);

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
               , 'Investigation PRE-Processing Event'
               , 'NBS_ODSE.sp_investigation_event'
               , 'START'
               , 0
               , LEFT('Pre ID-' + @phc_id_list, 199)
               , 0
               , LEFT(@phc_id_list, 199));

        /*Complete Investigation section*/
        SELECT results.public_health_case_uid,
               results.program_jurisdiction_oid                                     as program_jurisdiction_oid,
               jc.code_desc_txt                                                     as jurisdiction_nm,
               act.mood_cd,
               act.class_cd,
               results.case_type_cd,
               results.case_class_cd,
               results.inv_case_status,
               NULLIF(results.outbreak_name, '')                                    as outbreak_name,
               results.cd,
               results.cd_desc_txt,
               results.prog_area_cd,
               results.jurisdiction_cd,
               NULLIF(results.pregnant_ind_cd, '')                                  as pregnant_ind_cd,
               results.pregnant_ind,
               results.local_id,
               results.rpt_form_cmplt_time,
               results.activity_to_time,
               results.activity_from_time,
               results.add_user_id,
               case
                   when results.add_user_id > 0 then (select * from dbo.fn_get_user_name(results.add_user_id))
                   end                                                              as add_user_name,
               results.add_time,
               results.last_chg_user_id,
               case
                   when results.last_chg_user_id > 0 then (select * from dbo.fn_get_user_name(results.last_chg_user_id))
                   end                                                              as last_chg_user_name,
               results.last_chg_time,
               NULLIF(results.curr_process_state_cd, '')                            as curr_process_state_cd,
               results.curr_process_state,
               results.investigation_status_cd,
               results.investigation_status,
               case
                   when (results.record_status_cd is not null or results.record_status_cd != '')
                       then dbo.fn_get_record_status(results.record_status_cd)
                   end                                                              as record_status_cd,
               results.record_status_cd                                             as raw_record_status_cd,
               results.shared_ind,
               NULLIF(results.txt, '')                                              as txt,
               results.effective_from_time,
               results.effective_to_time,
               NULLIF(results.rpt_source_cd, '')                                    as rpt_source_cd,
               NULLIF(COALESCE(results.rpt_src_cd_desc, results.rpt_source_cd), '') as rpt_src_cd_desc,
               results.rpt_to_county_time,
               results.rpt_to_state_time,
               results.mmwr_week,
               results.mmwr_year,
               NULLIF(results.disease_imported_cd, '')                              as disease_imported_cd,
               results.disease_imported_ind,
               NULLIF(results.imported_country_cd, '')                              as imported_country_cd,
               NULLIF(results.imported_state_cd, '')                                as imported_state_cd,
               NULLIF(results.imported_county_cd, '')                               as imported_county_cd,
               results.imported_from_country,
               sc.state_nm                                                          as imported_from_state,
               sccv.code_desc_txt                                                   as imported_from_county,
               NULLIF(results.imported_city_desc_txt, '')                           as imported_city_desc_txt,
               results.diagnosis_time,
               results.hospitalized_admin_time,
               results.hospitalized_discharge_time,
               results.hospitalized_duration_amt,
               NULLIF(results.outbreak_ind, '')                                     as outbreak_ind,
               results.outbreak_ind_val,
               results.outbreak_name_desc,
               NULLIF(results.hospitalized_ind_cd, '')                              as hospitalized_ind_cd,
               results.hospitalized_ind,
               NULLIF(results.transmission_mode_cd, '')                             as transmission_mode_cd,
               results.transmission_mode,
               NULLIF(results.outcome_cd, '')                                       as outcome_cd,
               results.die_frm_this_illness_ind,
               NULLIF(results.day_care_ind_cd, '')                                  as day_care_ind_cd,
               results.day_care_ind,
               NULLIF(results.food_handler_ind_cd, '')                              as food_handler_ind_cd,
               results.food_handler_ind,
               results.deceased_time,
               NULLIF(results.pat_age_at_onset, '')                                 as pat_age_at_onset,
               NULLIF(results.pat_age_at_onset_unit_cd, '')                         as pat_age_at_onset_unit_cd,
               results.pat_age_at_onset_unit,
               NULLIF(results.detection_method_cd, '')                              as detection_method_cd,
               NULLIF(results.priority_cd, '')                                      as priority_cd,
               NULLIF(results.contact_inv_status_cd, '')                            as contact_inv_status_cd,
               cvg.code_desc_txt                                                       detection_method_desc_txt,
               cvg1.code_short_desc_txt                                                contact_inv_priority,
               NULLIF(cvg2.code_short_desc_txt, '')                                 as contact_inv_status,
               results.investigator_assigned_time,
               NULLIF(results.effective_duration_amt, '')                           as effective_duration_amt,
               NULLIF(results.effective_duration_unit_cd, '')                       as effective_duration_unit_cd,
               results.illness_duration_unit,
               results.infectious_from_date,
               results.infectious_to_date,
               results.referral_basis_cd,
               results.referral_basis,
               results.inv_priority_cd,
               results.coinfection_id,
               NULLIF(results.contact_inv_txt, '')                                  as contact_inv_txt,
               results.status_time,
               results.record_status_time,
               pac.prog_area_desc_txt                                               as program_area_description,
               cm.case_management_uid,
               results.rpt_cnty_cd,
               investigation_act_entity.nac_page_case_uid,
               investigation_act_entity.nac_last_chg_time,
               investigation_act_entity.nac_add_time,
               investigation_act_entity.person_as_reporter_uid,
               investigation_act_entity.hospital_uid,
               investigation_act_entity.ordering_facility_uid,
               investigation_act_entity.ca_supervisor_of_phc_uid,
               investigation_act_entity.closure_investgr_of_phc_uid,
               investigation_act_entity.dispo_fld_fupinvestgr_of_phc_uid,
               investigation_act_entity.fld_fup_investgr_of_phc_uid,
               investigation_act_entity.fld_fup_prov_of_phc_uid,
               investigation_act_entity.fld_fup_supervisor_of_phc_uid,
               investigation_act_entity.init_fld_fup_investgr_of_phc_uid,
               investigation_act_entity.init_fup_investgr_of_phc_uid,
               investigation_act_entity.init_interviewer_of_phc_uid,
               investigation_act_entity.interviewer_of_phc_uid,
               investigation_act_entity.surv_investgr_of_phc_uid,
               investigation_act_entity.fld_fup_facility_of_phc_uid,
               investigation_act_entity.org_as_hospital_of_delivery_uid,
               investigation_act_entity.per_as_provider_of_delivery_uid,
               investigation_act_entity.per_as_provider_of_obgyn_uid,
               investigation_act_entity.per_as_provider_of_pediatrics_uid,
               investigation_act_entity.org_as_reporter_uid,
               results.act_ids,
               results.investigation_observation_ids,
               results.person_participations,
               results.organization_participations,
               results.investigation_confirmation_method,
               results.investigation_case_answer,
               results.investigation_aggregate,
               results.investigation_case_management,
               results.investigation_notifications,
               results.investigation_case_count,
               con.investigation_form_cd,
               nt.phc_notes
        -- ,results.investigation_act_entity
        -- ,results.ldf_public_health_case
        -- into dbo.Investigation_Dim_Event
        FROM (SELECT phc.public_health_case_uid,
                     phc.program_jurisdiction_oid program_jurisdiction_oid,
                     phc.case_type_cd,
                     phc.case_class_cd,
                     case
                         when (phc.case_class_cd is not null or phc.case_class_cd != '') then (select *
                                                                                               from dbo.fn_get_value_by_cd_codeset(phc.case_class_cd, 'INV163'))
                         end as                   inv_case_status,
                     phc.outbreak_name,
                     phc.cd,
                     phc.cd_desc_txt              cd_desc_txt,
                     phc.prog_area_cd             prog_area_cd,
                     phc.jurisdiction_cd          jurisdiction_cd,
                     phc.pregnant_ind_cd          pregnant_ind_cd,
                     case
                         when (phc.pregnant_ind_cd is not null or phc.pregnant_ind_cd != '') then (select *
                                                                                                   from dbo.fn_get_value_by_cd_codeset(phc.pregnant_ind_cd, 'INV178'))
                         end as                   pregnant_ind,
                     phc.local_id                 local_id,
                     phc.rpt_form_cmplt_time      rpt_form_cmplt_time,
                     phc.activity_to_time         activity_to_time,
                     phc.add_time                 add_time,
                     phc.activity_from_time       activity_from_time,
                     phc.last_chg_time,
                     phc.add_user_id              add_user_id,
                     phc.last_chg_user_id         last_chg_user_id,
                     phc.curr_process_state_cd    curr_process_state_cd,
                     case
                         when (phc.curr_process_state_cd is not null or phc.curr_process_state_cd != '') then (select *
                                                                                                               from dbo.fn_get_value_by_cvg(
                                                                                                                       phc.curr_process_state_cd,
                                                                                                                       'CM_PROCESS_STAGE'))
                         end as                   curr_process_state,
                     phc.investigation_status_cd,
                     case
                         when (phc.investigation_status_cd is not null or phc.investigation_status_cd != '')
                             then (select *
                                   from dbo.fn_get_value_by_cd_codeset(
                                           phc.investigation_status_cd,
                                           'INV109'))
                         end as                   investigation_status,
                     phc.record_status_cd,
                     phc.record_status_time,
                     phc.shared_ind,
                     phc.txt,
                     phc.effective_from_time,
                     phc.effective_to_time,
                     phc.rpt_source_cd,
                     case
                         when (phc.rpt_source_cd is not null or phc.rpt_source_cd != '') then (select *
                                                                                               from dbo.fn_get_value_by_cd_codeset(phc.rpt_source_cd, 'INV112'))
                         end as                   rpt_src_cd_desc,
                     phc.rpt_to_county_time,
                     phc.rpt_to_state_time,
                     phc.mmwr_week,
                     phc.mmwr_year,
                     phc.disease_imported_cd,
                     case
                         when (phc.disease_imported_cd is not null or phc.disease_imported_cd != '') then (select *
                                                                                                           from dbo.fn_get_value_by_cd_codeset(phc.disease_imported_cd, 'INV152'))
                         end as                   disease_imported_ind,
                     phc.imported_city_desc_txt,
                     phc.imported_country_cd,
                     case
                         when (phc.imported_country_cd is not null or phc.imported_country_cd != '') then (select *
                                                                                                           from dbo.fn_get_value_by_cd_codeset(phc.imported_country_cd, 'INV153'))
                         end as                   imported_from_country,
                     phc.imported_state_cd,
                     phc.imported_county_cd,
                     phc.diagnosis_time,
                     phc.hospitalized_admin_time,
                     phc.hospitalized_discharge_time,
                     phc.hospitalized_duration_amt,
                     phc.outbreak_ind,
                     case
                         when (phc.outbreak_ind is not null or phc.outbreak_ind != '') then (select *
                                                                                             from dbo.fn_get_value_by_cd_codeset(phc.outbreak_ind, 'INV150'))
                         end as                   outbreak_ind_val,
                     case
                         when (phc.outbreak_ind is not null or phc.outbreak_ind != '') then (select *
                                                                                             from dbo.fn_get_value_by_cd_codeset(phc.outbreak_name, 'INV151'))
                         end as                   outbreak_name_desc,
                     phc.hospitalized_ind_cd,
                     case
                         when (phc.hospitalized_ind_cd is not null or phc.hospitalized_ind_cd != '') then (select *
                                                                                                           from dbo.fn_get_value_by_cd_codeset(phc.hospitalized_ind_cd, 'INV128'))
                         end as      hospitalized_ind,
                     phc.transmission_mode_cd,
                     case
                         when (phc.transmission_mode_cd is not null or phc.transmission_mode_cd != '') then (select *
                                                                                                             from dbo.fn_get_value_by_cd_codeset(phc.transmission_mode_cd, 'INV157'))
                         end as                   transmission_mode,
                     phc.outcome_cd,
                     case
                         when (phc.outcome_cd != '') then (select *
                                                           from dbo.fn_get_value_by_cd_codeset(phc.outcome_cd, 'INV145'))
                         end as                   die_frm_this_illness_ind,
                     phc.day_care_ind_cd,
                     case
                         when (phc.day_care_ind_cd is not null or phc.day_care_ind_cd != '') then (select *
                                                                                                   from dbo.fn_get_value_by_cd_codeset(phc.day_care_ind_cd, 'INV148'))
                         end as                   day_care_ind,
                     phc.food_handler_ind_cd,
                     case
                         when (phc.food_handler_ind_cd is not null or phc.food_handler_ind_cd != '') then (select *
                                                                                                           from dbo.fn_get_value_by_cd_codeset(phc.food_handler_ind_cd, 'INV149'))
                         end as                   food_handler_ind,
                     phc.deceased_time,
                     phc.pat_age_at_onset,
                     phc.pat_age_at_onset_unit_cd,
                     case
                         when (phc.pat_age_at_onset_unit_cd is not null or phc.pat_age_at_onset_unit_cd != '')
                             then (select *
                                   from dbo.fn_get_value_by_cd_codeset(
                                           phc.pat_age_at_onset_unit_cd,
                                           'INV144'))
                         end as                   pat_age_at_onset_unit,
                     phc.detection_method_cd,
                     phc.priority_cd,
                     phc.investigator_assigned_time,
                     phc.effective_duration_amt,
                     phc.effective_duration_unit_cd,
                     case
                         when (phc.effective_duration_unit_cd is not null or phc.effective_duration_unit_cd != '')
                             then (select *
                                   from dbo.fn_get_value_by_cd_codeset(phc.effective_duration_unit_cd, 'INV144'))
                         end as                   illness_duration_unit,
                     phc.infectious_from_date,
                     phc.infectious_to_date,
                     phc.referral_basis_cd,
                     case
                         when (phc.referral_basis_cd is not null or phc.referral_basis_cd != '') then (select *
                                                                                                       from dbo.fn_get_value_by_cvg(phc.referral_basis_cd, 'REFERRAL_BASIS'))
                         end as                   referral_basis,
                     phc.inv_priority_cd,
                     phc.contact_inv_status_cd,
                     phc.coinfection_id,
                     phc.contact_inv_txt,
                     phc.status_time,
                     phc.rpt_cnty_cd,
                     nesteddata.act_ids,
                     nesteddata.investigation_observation_ids,
                     nesteddata.person_participations,
                     nesteddata.organization_participations,
                     nesteddata.investigation_confirmation_method,
                     nesteddata.investigation_case_answer,
                     nesteddata.investigation_aggregate,
                     nesteddata.investigation_case_management,
                     nesteddata.investigation_notifications,
                     nesteddata.investigation_case_count
              --,nesteddata.ldf_public_health_case
              FROM
                  --public health case
                  dbo.public_health_case phc WITH (NOLOCK)
                      OUTER apply (SELECT *
                                   FROM (
                                            -- persons associated with public_health_case
                                            SELECT (SELECT p.act_uid                              AS [act_uid],
                                                           p.type_cd                              AS [type_cd],
                                                           p.subject_entity_uid                   AS [entity_id],
                                                           p.subject_class_cd                     AS [subject_class_cd],
                                                           p.record_status_cd                     AS [participation_record_status],
                                                           p.last_chg_time                        AS [participation_last_change_time],
                                                           STRING_ESCAPE(person.first_nm, 'json') AS [first_name],
                                                           STRING_ESCAPE(person.last_nm, 'json')  AS [last_name],
                                                           person.local_id                        AS [local_id],
                                                           person.birth_time                      AS [birth_time],
                                                           person.curr_sex_cd                     AS [curr_sex_cd],
                                                           person.cd                              AS [person_cd],
                                                           person.person_parent_uid               AS [person_parent_uid],
                                                           person.record_status_cd                AS [person_record_status],
                                                           person.last_chg_time                   AS [person_last_chg_time]
                                                    FROM dbo.participation p
                                                             WITH (NOLOCK)
                                                             JOIN dbo.person WITH (NOLOCK) ON person.person_uid =
                                                                                              (select person.person_parent_uid
                                                                                               from dbo.person
                                                                                               where person.person_uid = p.subject_entity_uid)
                                                    WHERE p.act_uid = phc.public_health_case_uid
                                                    FOR json path,INCLUDE_NULL_VALUES) AS person_participations) AS person_participations,
                                        (SELECT (SELECT p.act_uid                             AS [act_uid],
                                                        p.type_cd                             AS [type_cd],
                                                        p.subject_entity_uid                  AS [entity_id],
                                                        p.subject_class_cd                    AS [subject_class_cd],
                                                        p.record_status_cd                    AS [record_status],
                                                        p.last_chg_time                       AS [participation_last_change_time],
                                                        STRING_ESCAPE(org.display_nm, 'json') AS [name],
                                                        org.last_chg_time                     AS [org_last_change_time]
                                                 FROM dbo.participation p
                                                          WITH (NOLOCK)
                                                          JOIN dbo.organization org WITH (NOLOCK)
                                                               ON org.organization_uid = p.subject_entity_uid
                                                 WHERE p.act_uid = phc.public_health_case_uid
                                                 FOR json path,INCLUDE_NULL_VALUES) AS organization_participations) AS organization_participations
                                        -- act_ids associated with public health case
                                           ,
                                        (SELECT (SELECT act.source_act_uid,
                                                        act.target_Act_uid   as public_health_case_uid,
                                                        act.source_class_cd,
                                                        act.target_class_cd,
                                                        act.type_cd          as act_type_cd,
                                                        act.status_cd,
                                                        act.add_time            act_add_time,
                                                        act.add_user_id         act_add_user_id,
                                                        case
                                                            when act.add_user_id > 0
                                                                then (select * from dbo.fn_get_user_name(act.add_user_id))
                                                            end              as add_user_name,
                                                        act.last_chg_user_id    act_last_chg_user_id,
                                                        case
                                                            when act.last_chg_user_id > 0
                                                                then (select * from dbo.fn_get_user_name(act.last_chg_user_id))
                                                            end              as last_chg_user_name,
                                                        act.last_chg_time    as act_last_chg_time,
                                                        COALESCE(root.target_act_uid, branch.target_act_uid) AS root_uid,
                                                        branch.source_act_uid  as branch_uid,
                                                        branch.target_class_cd as root_source_class_cd,
                                                        branch.source_class_cd as branch_source_class_cd,
                                                        branch.type_cd         as branch_type_cd
                                                 FROM dbo.act_relationship act WITH (NOLOCK)
                                                          left join dbo.act_relationship branch WITH (NOLOCK)
                                                                    on act.source_act_uid = branch.target_act_uid
                                                          left join dbo.act_relationship AS root WITH (NOLOCK)
                                                                    on branch.source_act_uid = root.source_act_uid and root.type_cd = 'ItemToRow'
                                                 WHERE act.target_act_uid = phc.public_health_case_uid
                                                 FOR json path,INCLUDE_NULL_VALUES) AS investigation_observation_ids) AS investigation_observation_ids
                                        -- act_ids associated with public health case
                                           ,
                                        (SELECT (SELECT act_id.act_uid            AS [id],
                                                        act_id_seq                AS [act_id_seq],
                                                        act_id.record_status_cd   AS [record_status],
                                                        act_id.root_extension_txt AS [root_extension_txt],
                                                        act_id.type_cd            AS [type_cd],
                                                        act_id.type_desc_txt      AS [type_desc_txt],
                                                        act_id.add_time              act_id_add_time,
                                                        act_id.add_user_id           act_id_add_user_id,
                                                        act_id.last_chg_user_id      act_id_last_chg_user_id,
                                                        act_id.last_chg_time      AS [act_id_last_change_time]
                                                 FROM dbo.act_id WITH (NOLOCK)
                                                 WHERE act_uid = phc.public_health_case_uid
                                                 FOR json path,INCLUDE_NULL_VALUES) AS act_ids) AS act_ids,
                                        -- get associated confirmation method
                                        (SELECT (select cm.public_health_case_uid,
                                                        cm.confirmation_method_cd,
                                                        cvg.CODE_SHORT_DESC_TXT as confirmation_method_desc_txt,
                                                        cm.confirmation_method_time,
                                                        phc1.last_chg_time      as phc_last_chg_time
                                                 from dbo.Confirmation_method cm
                                                          left join nbs_srte.dbo.Code_value_general cvg WITH (NOLOCK)
                                                                    on cvg.code = cm.confirmation_method_cd and cvg.code_set_nm = 'PHC_CONF_M'
                                                          join dbo.Public_health_case phc1 WITH (NOLOCK)
                                                               on cm.public_health_case_uid = phc1.public_health_case_uid
                                                 WHERE cm.public_health_case_uid = phc.public_health_case_uid
                                                 FOR json path,INCLUDE_NULL_VALUES) AS investigation_confirmation_method) AS investigation_confirmation_method,
                                        -- NBS case answer associated with phc
                                        (SELECT (SELECT nbs_case_answer_uid,
                                                        nbs_ui_metadata_uid,
                                                        nbs_rdb_metadata_uid,
                                                        rdb_table_nm,
                                                        rdb_column_nm,
                                                        code_set_group_id,
                                                        answer_txt,
                                                        act_uid,
                                                        record_status_cd,
                                                        nbs_question_uid,
                                                        investigation_form_cd,
                                                        unit_value,
                                                        question_identifier,
                                                        data_location,
                                                        answer_group_seq_nbr,
                                                        question_label,
                                                        other_value_ind_cd,
                                                        unit_type_cd,
                                                        mask,
                                                        block_nm,
                                                        question_group_seq_nbr,
                                                        data_type,
                                                        part_type_cd,
                                                        last_chg_time,
                                                        datamart_column_nm,
                                                        seq_nbr,
                                                        ldf_status_cd,
                                                        nbs_ui_component_uid,
                                                        nca_add_time,
                                                        nuim_record_status_cd
                                                 FROM (SELECT *,
                                                              ROW_NUMBER() OVER (PARTITION BY NBS_QUESTION_UID, answer_txt, answer_group_seq_nbr
                                                                  order by
                                                                      NBS_QUESTION_UID,
                                                                      other_value_ind_cd desc) rowid
                                                       FROM (SELECT distinct nbs_case_answer_uid,
                                                                             pa.act_uid,
                                                                             pa.record_status_cd,
                                                                             pa.last_chg_time,
                                                                             cast(replace(answer_txt, char(13) + char(10), ' ') as varchar(2000)) as answer_txt,
                                                                             pa.answer_group_seq_nbr,
                                                                             nuim.nbs_ui_metadata_uid,
                                                                             nuim.code_set_group_id,
                                                                             nuim.nbs_question_uid,
                                                                             nuim.investigation_form_cd,
                                                                             nuim.unit_value,
                                                                             nuim.question_identifier,
                                                                             nuim.data_location,
                                                                             nuim.block_nm,
                                                                             nrdbm.nbs_rdb_metadata_uid,
                                                                             nrdbm.rdb_table_nm,
                                                                             nrdbm.rdb_column_nm,
                                                                             nuim.question_label,
                                                                             nuim.other_value_ind_cd,
                                                                             nuim.unit_type_cd,
                                                                             nuim.mask,
                                                                             nuim.question_group_seq_nbr,
                                                                             nuim.data_type,
                                                                             nuim.part_type_cd,
                                                                             --NEW COLUMNS
                                                                             null as datamart_column_nm,
                                                                             pa.seq_nbr,
                                                                             nuim.ldf_status_cd,
                                                                             nuim.nbs_ui_component_uid,
                                                                             pa.add_time as nca_add_time,
                                                                             nuim.record_status_cd as nuim_record_status_cd
                                                             from nbs_odse.dbo.nbs_rdb_metadata nrdbm with (nolock)
                                                                      inner join nbs_odse.dbo.nbs_ui_metadata nuim with (nolock)
                                                                                 on
                                                                                     nrdbm.nbs_ui_metadata_uid = nuim.nbs_ui_metadata_uid
                                                                 --and question_group_seq_nbr is null
                                                                      left join nbs_odse.dbo.nbs_case_answer pa with (nolock)
                                                                                on
                                                                                    nuim.nbs_question_uid = pa.nbs_question_uid
                                                                 --  and
                                                                 --pa.answer_group_seq_nbr is null
                                                                      inner join nbs_srte.dbo.code_value_general cvg with (nolock)
                                                                                 on
                                                                                     cvg.code = nuim.data_type
                                                                      inner join nbs_srte.dbo.condition_code cc with (nolock)
                                                                                 on
                                                                                     cc.condition_cd = phc.cd
                                                             where cvg.code_set_nm = 'NBS_DATA_TYPE'
                                                               and nuim.investigation_form_cd = cc.investigation_form_cd
                                                               and pa.act_uid = phc.public_health_case_uid
                                                             --and pa.last_chg_time>=phc.last_chg_time
                                                             union
                                                             SELECT distinct
                                                                 pa.nbs_case_answer_uid,
                                                                 pa.act_uid,
                                                                 pa.record_status_cd,
                                                                 pa.last_chg_time,
                                                                 pa.answer_txt,
                                                                 pa.answer_group_seq_nbr,
                                                                 nuim.nbs_ui_metadata_uid,
                                                                 pq.code_set_group_id,
                                                                 nuim.nbs_question_uid,
                                                                 nuim.investigation_form_cd,
                                                                 nuim.unit_value,
                                                                 nuim.question_identifier,
                                                                 nuim.data_location,
                                                                 nuim.block_nm,
                                                                 null as nbs_rdb_metadata_uid,
                                                                 null as rdb_table_nm,
                                                                 null as rdb_column_nm,
                                                                 nuim.question_label,
                                                                 nuim.other_value_ind_cd,
                                                                 nuim.unit_type_cd,
                                                                 nuim.mask,
                                                                 nuim.question_group_seq_nbr,
                                                                 nuim.data_type,
                                                                 nuim.part_type_cd,
                                                                 --NEW COLUMNS
                                                                 pq.datamart_column_nm,
                                                                 pa.seq_nbr,
                                                                 nuim.ldf_status_cd,
                                                                 nuim.nbs_ui_component_uid,
                                                                 pa.add_time as nca_add_time,
                                                                 nuim.record_status_cd as nuim_record_status_cd
                                                             from nbs_odse.dbo.nbs_question pq with (nolock)
                                                                      join nbs_odse.dbo.nbs_case_answer pa with (nolock)
                                                                           on pq.nbs_question_uid = pa.nbs_question_uid
                                                                      left join nbs_odse.dbo.nbs_ui_metadata nuim with (nolock)
                                                                                on
                                                                                    pq.nbs_question_uid = nuim.nbs_question_uid
                                                                      inner join nbs_srte.dbo.condition_code cc with (nolock)
                                                                                 on
                                                                                     cc.condition_cd = phc.cd
                                                             where pq.datamart_column_nm is not null
                                                               and nuim.investigation_form_cd = cc.investigation_form_cd
                                                               and nuim.investigation_form_cd in ('INV_FORM_RVCT','INV_FORM_VAR')
                                                               and pa.act_uid = phc.public_health_case_uid
                                                            ) as answer_table) as answer_table
                                                 where rowid = 1
                                                 FOR json path,INCLUDE_NULL_VALUES) AS investigation_case_answer) AS investigation_case_answer,
                                        -- get aggregate case answers
                                        (SELECT (select *
                                                 from (select na.act_uid as act_uid,
                                                              na.nbs_case_answer_uid,
                                                              na.answer_txt,
                                                              nq.code_set_group_id,
                                                              nq.data_type,
                                                              ntm.datamart_column_nm
                                                       from dbo.NBS_case_answer na with (nolock )
                                                                join dbo.NBS_table_metadata ntm with (nolock)
                                                                     on ntm.nbs_table_metadata_uid = na.nbs_table_metadata_uid
                                                                join dbo.NBS_question nq with (nolock)
                                                                     on nq.nbs_question_uid = na.nbs_question_uid
                                                       WHERE na.nbs_table_metadata_uid is not null
                                                         and na.act_uid = phc.public_health_case_uid
                                                       union
                                                       select na.act_uid,
                                                              na.nbs_case_answer_uid,
                                                              na.answer_txt,
                                                              nq.code_set_group_id,
                                                              nq.data_type,
                                                              nq.datamart_column_nm
                                                       from dbo.NBS_case_answer na with (nolock )
                                                                join dbo.NBS_question nq with (nolock)
                                                                     on nq.nbs_question_uid = na.nbs_question_uid
                                                       WHERE na.nbs_table_metadata_uid is null
                                                         and na.act_uid = phc.public_health_case_uid
                                                      ) as agg_rep
                                                 WHERE phc.case_type_cd = 'A' /* Aggregate Report */
                                                 FOR json path,INCLUDE_NULL_VALUES) as investigation_aggregate) as investigation_aggregate,
                                        -- get associated case management
                                        (SELECT (select cm.case_management_uid,
                                                        cm.public_health_case_uid,
                                                        phc.add_user_id,
                                                        phc.program_jurisdiction_oid                                                   as case_oid,
                                                        ooj_initg_agncy_outc_snt_date,
                                                        init_foll_up                                                                   as init_fup_initial_foll_up_cd,
                                                        (select *
                                                         from fn_get_value_by_cvg(init_foll_up,
                                                                                  'STD_CREATE_INV_LABMORB_NONSYPHILIS_PROC_DECISION')) as init_fup_initial_foll_up,
                                                        init_foll_up_closed_date                                                       as init_fup_closed_dt,
                                                        internet_foll_up                                                               as init_fup_internet_foll_up_cd,
                                                        (select * from fn_get_value_by_cvg(internet_foll_up, 'YN'))                    as internet_foll_up,
                                                        init_foll_up_notifiable                                   as init_fup_notifiable_cd,
                                                        (select *
                                                         from fn_get_value_by_cvg(init_foll_up_notifiable, 'NOTIFIABLE'))              as init_foll_up_notifiable,
                                                        init_foll_up_clinic_code                                                       as init_fup_clinic_code,
                                                        surv_assigned_date                              as surv_investigator_assgn_dt,
                                                        surv_closed_date                                                               as surv_closed_dt,
                                                        surv_provider_contact                          as surv_provider_contact_cd,
                                                        (select *
                                                         from fn_get_value_by_cvg(surv_provider_contact, 'PRVDR_CONTACT_OUTCOME'))     as surv_provider_contact,
                                                        surv_prov_exm_reason,
                                                        (select *
                                                         from fn_get_value_by_cvg(surv_prov_exm_reason, 'PRVDR_EXAM_REASON'))          as surv_provider_exam_reason,
                                                        surv_prov_diagnosis                        as surv_provider_diagnosis,
                                                        surv_patient_foll_up,
                                                        (select *
                                                         from fn_get_value_by_cvg(surv_patient_foll_up,
                                                                                  'SURVEILLANCE_PATIENT_FOLLOWUP'))                    as surv_patient_foll_up_cd,
                                                        status_900                                                                     as adi_900_status_cd,
                                                        (select * from fn_get_value_by_cvg(status_900, 'STATUS_900'))                  as status_900,
                                                        ehars_id           as adi_ehars_id,
                                                        subj_height                                                                    as adi_height,
                                                        subj_height                                                                    as adi_height_legacy_case,
                                                        subj_size_build                                                                as adi_size_build,
                                                        subj_hair                                                                      as adi_hair,
                                                        subj_complexion                                                                as adi_complexion,
                                                        subj_oth_idntfyng_info                                                         as adi_other_identifying_info,
                                                        field_record_number                                                            as fl_fup_field_record_num,
                                                        foll_up_assigned_date                                                          as fl_fup_investigator_assgn_dt,
                                                        init_foll_up_assigned_date                                                     as fl_fup_init_assgn_dt,
                                                        fld_foll_up_prov_exm_reason,
                                                        (select *
                                                         from fn_get_value_by_cvg(fld_foll_up_prov_exm_reason, 'PRVDR_EXAM_REASON'))   as fl_fup_prov_exm_reason,
                                                        fld_foll_up_prov_diagnosis,
                                                        LEFT(fld_foll_up_prov_diagnosis, 3)                                            as fl_fup_prov_diagnosis,
                                                        fld_foll_up_notification_plan,
                                                        (select *
                                                         from fn_get_value_by_cvg(fld_foll_up_notification_plan,
                                                                                  'NOTIFICATION_PLAN'))                                as fl_fup_notification_plan_cd,
                                                        fld_foll_up_expected_in,
                                                        (select * from fn_get_value_by_cvg(fld_foll_up_expected_in, 'YN'))             as fl_fup_expected_in_ind,
                                                        fld_foll_up_expected_date                                                      as fl_fup_expected_dt,
                                                        fld_foll_up_exam_date                                                          as fl_fup_exam_dt,
                                                        fld_foll_up_dispo                            as fl_fup_disposition_cd,
                                                        (select *
                                                         from fn_get_value_by_cvg(fld_foll_up_dispo,
                                                                                  'FIELD_FOLLOWUP_DISPOSITION_STDHIV'))                as fl_fup_disposition_desc,
                                                        fld_foll_up_dispo_date                                                         as fl_fup_dispo_dt,
                                                        act_ref_type_cd,
                                                        (select *
                                                         from fn_get_value_by_cvg(act_ref_type_cd, 'NOTIFICATION_ACTUAL_METHOD_STD'))  as fl_fup_actual_ref_type,
                                                        case_review_status,
                                                        case_review_status_date,
                                                        fld_foll_up_internet_outcome                                                   as fl_fup_internet_outcome_cd,
                                                        (select *
                                                         from fn_get_value_by_cvg(fld_foll_up_internet_outcome,
                                                                                  'INTERNET_FOLLOWUP_OUTCOME'))                        as fl_fup_internet_outcome,
                                                        (select * from fn_get_value_by_cvg(ooj_agency, 'OOJ_AGENCY_LOCAL'))            as ooj_agency,
                                                        ooj_number,
                                                        ooj_due_date,
                                                        field_foll_up_ooj_outcome,
                                                        (select *
                                                         from fn_get_value_by_cvg(field_foll_up_ooj_outcome,
                                                                                  'FIELD_FOLLOWUP_DISPOSITION_STDHIV'))                as fl_fup_ooj_outcome,
                                                        interview_assigned_date                                                        as ca_interviewer_assign_dt,
                                                        init_interview_assigned_date                                                   as ca_init_intvwr_assgn_dt,
                                                        epi_link_id,
                                                        pat_intv_status_cd,
                                                        (select *
                                                         from fn_get_value_by_cvg(pat_intv_status_cd, 'PAT_INTVW_STATUS'))             as ca_patient_intv_status,
                                                        case_closed_date                                 as cc_closed_dt,
                                                        (select *
                                                         from fn_get_value_by_cvg(initiating_agncy, 'OOJ_AGENCY_LOCAL'))               as initiating_agncy,
                                                        ooj_initg_agncy_recd_date,
                                                        ooj_initg_agncy_outc_due_date
                                                 from dbo.case_management cm
                                                 WHERE cm.public_health_case_uid = phc.public_health_case_uid
                                                 FOR json path,INCLUDE_NULL_VALUES) AS investigation_case_management) AS investigation_case_management,
                                        -- investigation notification columns
                                        (SELECT (SELECT act.source_act_uid,
                                                        act.target_act_uid     as public_health_case_uid,
                                                        act.source_class_cd,
                                                        act.target_class_cd,
                                                        act.type_cd            as act_type_cd,
                                                        act.status_cd,
                                                        notif.notification_uid,
                                                        notif.prog_area_cd,
                                                        notif.program_jurisdiction_oid,
                                                        notif.jurisdiction_cd,
                                                        notif.record_status_time,
                                                        notif.status_time,
                                                        notif.rpt_sent_time,
                                                        notif.record_status_cd as 'notif_status',
                                                        notif.local_id         as 'notif_local_id',
                                                        notif.txt              as 'notif_comments',
                                                        notif.add_time         as 'notif_add_time',
                                                        notif.add_user_id      as 'notif_add_user_id',
                                                        case
                                                            when notif.add_user_id > 0
                                                                then (select * from dbo.fn_get_user_name(notif.add_user_id))
                                                            end                as 'notif_add_user_name',
                                                        notif.last_chg_user_id as 'notif_last_chg_user_id',
                                                        case
                                                            when notif.last_chg_user_id > 0
                                                                then (select * from dbo.fn_get_user_name(notif.last_chg_user_id))
                                                            end                as 'notif_last_chg_user_name',
                                                        notif.last_chg_time    as 'notif_last_chg_time',
                                                        per.local_id           as 'local_patient_id',
                                                        per.person_uid         as 'local_patient_uid',
                                                        phc.cd                 as 'condition_cd',
                                                        phc.cd_desc_txt        as 'condition_desc',
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
                                                 FROM act_relationship act WITH (NOLOCK)
                                                          join notification notif WITH (NOLOCK)
                                                               on act.source_act_uid = notif.notification_uid
                                                          left join nbs_odse.dbo.participation part with (nolock)
                                                                    ON part.type_cd = 'SubjOfPHC' AND part.act_uid = act.target_act_uid
                                                          left join nbs_odse.dbo.person per with (nolock)
                                                                    ON per.cd = 'PAT' AND per.person_uid = part.subject_entity_uid
                                                          left join nbs_odse.dbo.v_notification_hist nh  with (nolock) on nh.public_health_case_uid = phc.public_health_case_uid
                                                 WHERE act.target_act_uid = phc.public_health_case_uid
                                                   AND notif.cd not in
                                                       ('EXP_NOTF', 'SHARE_NOTF', 'EXP_NOTF_PHDC', 'SHARE_NOTF_PHDC')
                                                   AND act.source_class_cd = 'NOTF'
                                                   AND act.target_class_cd = 'CASE'
                                                 FOR json path,INCLUDE_NULL_VALUES) AS investigation_notifications) AS investigation_notifications,
                                        (select (select phcase.group_case_cnt                                         as investigation_count,
                                                        round(COALESCE(gcs.group_case_cnt, phcase.group_case_cnt), 0) as case_count,
                                                        par2.from_time                                                as investigator_assigned_datetime
                                                 from nbs_odse.dbo.Public_health_case phcase with (nolock)
                                                          left outer join (select public_health_case_uid,
                                                                                  ovn.numeric_value_1 as group_case_cnt
                                                                           from nbs_odse.dbo.Public_health_case phci with (nolock),
                                                                                nbs_odse.dbo.act_relationship as ar2 with (nolock), /*OBS Summary_Report_Form to phc */
                                                                                nbs_odse.dbo.act_relationship as ar1 with (nolock), /*-- OBS sum107 to OBS Summary_Report_Form */
                                                                                nbs_odse.dbo.observation as ob1 with (nolock), /*--SUM107 */
                                                                                nbs_odse.dbo.observation as ob2 with (nolock), /* --Summary_Report_Form*/
                                                                                nbs_odse.dbo.obs_value_numeric as ovn with (nolock) /*--group_case_cnt*/
                                                                           where phci.case_type_cd = 'S'
                                                                             and phci.public_health_case_uid = ar2.target_act_uid
                                                                             and ar1.source_act_uid = ob1.observation_uid
                                                                             and ar1.target_act_uid = ob2.observation_uid
                                                                             and ar1.type_cd = 'SummaryFrmQ'
                                                                             and ob1.cd = 'SUM107'
                                                                             and ob2.cd = 'Summary_Report_Form'
                                                                             and ob1.observation_uid = ovn.observation_uid
                                                                             and ob2.observation_uid = ar2.source_act_uid
                                                                             and ar2.type_cd = 'SummaryForm') gcs
                                                                          on gcs.public_health_case_uid = phcase.public_health_case_uid
                                                          left outer join nbs_odse.dbo.participation par2 with (nolock)
                                                                          on phcase.public_health_case_uid =
                                                                             par2.act_uid
                                                                              and par2.type_cd = 'InvestgrOfPHC'
                                                                              and par2.act_class_cd = 'CASE'
                                                                              and par2.subject_class_cd = 'PSN'
                                                 where phcase.public_health_case_uid = phc.public_health_case_uid
                                                 FOR json path,INCLUDE_NULL_VALUES) as investigation_case_count) as investigation_case_count
                      /*
                              -- ldf_phc associated with phc
                    ,(
                SELECT
                                 (
                                  select * from nbs_odse..v_ldf_phc ldf
                                    WHERE ldf.public_health_case_uid = phc.public_health_case_uid
           Order By ldf.public_health_case_uid, ldf.display_order_nbr
                                            FOR json path,INCLUDE_NULL_VALUES
                                 ) AS ldf_public_health_case
                             ) AS ldf_public_health_case
                             */

                  ) as nestedData
              WHERE phc.public_health_case_uid in (SELECT value
                                                   FROM STRING_SPLIT(@phc_id_list
                                                       , ','))) AS results
                 LEFT JOIN nbs_srte.dbo.jurisdiction_code jc WITH (NOLOCK) ON results.jurisdiction_cd = jc.code
                 LEFT JOIN act WITH (NOLOCK) ON act.act_uid = results.public_health_case_uid
                 LEFT JOIN nbs_srte.dbo.program_area_code pac WITH (NOLOCK) on results.prog_area_cd = pac.prog_area_cd
                 LEFT JOIN nbs_srte.dbo.state_code sc WITH (NOLOCK) ON results.imported_state_cd = sc.state_cd
                 LEFT JOIN nbs_srte.dbo.state_county_code_value sccv WITH (NOLOCK)
                           ON results.imported_county_cd = sccv.code
                 LEFT JOIN nbs_srte.dbo.code_value_general cvg WITH (NOLOCK)
                           ON results.detection_method_cd = cvg.code and
                              cvg.code_set_nm in ('PHC_DET_MT', 'PHVS_DETECTIONMETHOD_STD')
                 LEFT JOIN nbs_srte.dbo.code_value_general cvg1 WITH (NOLOCK)
                           on results.priority_cd = cvg1.code and cvg1.code_set_nm = 'NBS_PRIORITY'
                 LEFT JOIN nbs_srte.dbo.code_value_general cvg2 WITH (NOLOCK)
                           on results.contact_inv_status_cd = cvg2.code and cvg2.code_set_nm = 'PHC_IN_STS'
                 LEFT OUTER JOIN nbs_odse.dbo.case_management cm WITH (NOLOCK)
                                 on results.public_health_case_uid = cm.public_health_case_uid
                 LEFT JOIN
             (SELECT DISTINCT act_uid            AS                                                     nac_page_case_uid,
                              MAX(last_chg_time) AS                                                     nac_last_chg_time,
                              MIN(add_time)      AS                                                     nac_add_time,
                              MAX(CASE WHEN type_cd = 'PerAsReporterOfPHC' THEN entity_uid END)         person_as_reporter_uid,
                              MAX(CASE WHEN type_cd = 'HospOfADT' THEN entity_uid END)                  hospital_uid,
                              MAX(CASE WHEN type_cd = 'OrgAsClinicOfPHC' THEN entity_uid END)           ordering_facility_uid,
                              MAX(CASE WHEN type_cd = 'CASupervisorOfPHC' THEN entity_uid END)          ca_supervisor_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'ClosureInvestgrOfPHC' THEN entity_uid END)       closure_investgr_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'DispoFldFupInvestgrOfPHC' THEN entity_uid END)   dispo_fld_fupinvestgr_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'FldFupInvestgrOfPHC' THEN entity_uid END)        fld_fup_investgr_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'FldFupProvOfPHC' THEN entity_uid END)      fld_fup_prov_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'FldFupSupervisorOfPHC' THEN entity_uid END)      fld_fup_supervisor_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'InitFldFupInvestgrOfPHC' THEN entity_uid END)    init_fld_fup_investgr_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'InitFupInvestgrOfPHC' THEN entity_uid END)       init_fup_investgr_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'InitInterviewerOfPHC' THEN entity_uid END)       init_interviewer_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'InterviewerOfPHC' THEN entity_uid END)           interviewer_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'SurvInvestgrOfPHC' THEN entity_uid END)          surv_investgr_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'FldFupFacilityOfPHC' THEN entity_uid END)        fld_fup_facility_of_phc_uid,
                              MAX(CASE WHEN type_cd = 'OrgAsHospitalOfDelivery' THEN entity_uid END)    org_as_hospital_of_delivery_uid,
                              MAX(CASE WHEN type_cd = 'PerAsProviderOfDelivery' THEN entity_uid END)    per_as_provider_of_delivery_uid,
                              MAX(CASE WHEN type_cd = 'PerAsProviderOfOBGYN' THEN entity_uid END)       per_as_provider_of_obgyn_uid,
                              MAX(CASE WHEN type_cd = 'PerAsProvideroOfPediatrics' THEN entity_uid END) per_as_provider_of_pediatrics_uid,
                              MAX(CASE WHEN type_cd = 'OrgAsReporterOfPHC' THEN entity_uid END)         org_as_reporter_uid
              FROM nbs_act_entity nac WITH (NOLOCK)
              GROUP BY act_uid) AS investigation_act_entity
             ON investigation_act_entity.nac_page_case_uid = results.public_health_case_uid
                 LEFT JOIN nbs_srte.dbo.condition_code con on results.cd = con.condition_cd
                 LEFT JOIN  (SELECT
                                 note_parent_uid,
                                 STUFF(
                                         (
                                             SELECT '; ' + CAST(add_time AS VARCHAR(20)) + '^' + replace(replace(replace(note, CHAR(0x0002), ''), CHAR(0x0001), ''), CHAR(0x0000), '')
                                             FROM nbs_odse.dbo.NBS_Note nbsNote
                                             WHERE note_parent_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','))
                                               and nbsNote.note_parent_uid = NBS_NOTE.note_parent_uid FOR XML PATH, TYPE, BINARY BASE64
                                         ).value('.[1]', 'varchar(max)'), 1, 2, '') PHC_NOTES
                             FROM nbs_odse.dbo.NBS_NOTE WITH(NOLOCK)
                             GROUP BY note_parent_uid
        ) nt on nt.note_parent_uid = results.public_health_case_uid;

        -- select * from dbo.Investigation_Dim_Event;

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
               , 'Investigation PRE-Processing Event'
               , 'NBS_ODSE.sp_investigation_event'
               , 'COMPLETE'
               , 0
               , LEFT('Pre ID-' + @phc_id_list, 199)
               , 0
               , LEFT(@phc_id_list, 199));

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
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
        , [Error_Description]
        )
        VALUES ( @batch_id
               , 'Investigation PRE-Processing Event'
               , 'NBS_ODSE.sp_investigation_event'
               , 'ERROR'
               , 0
               , 'Investigation PRE-Processing Event'
               , 0
               , LEFT(@phc_id_list, 199)
               , @FullErrorMessage
               );
        return @FullErrorMessage;

    END CATCH

END;