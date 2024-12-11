CREATE OR ALTER VIEW dbo.v_rdb_ui_metadata_answers AS
SELECT PA.nbs_answer_uid,
       nuim.nbs_ui_metadata_uid,
       nrdbm.nbs_rdb_metadata_uid,
       nrdbm.rdb_table_nm,
       nrdbm.rdb_column_nm,
       nuim.code_set_group_id,
       cast(replace(answer_txt, char(13) + char(10), ' ') as varchar(2000)) as answer_txt,
       pa.act_uid,
       pa.record_status_cd,
       nuim.nbs_question_uid,
       nuim.investigation_form_cd,
       nuim.unit_value,
       nuim.question_identifier,
       pa.answer_group_seq_nbr,
       nuim.data_location,
       question_label,
       other_value_ind_cd,
       unit_type_cd,
       mask,
       nuim.block_nm,
       question_group_seq_nbr,
       data_type,
       pa.last_chg_time
from nbs_odse.dbo.nbs_rdb_metadata nrdbm with (nolock)
         inner join nbs_odse.dbo.nbs_ui_metadata nuim
    with (nolock)
                    on
                        nrdbm.nbs_ui_metadata_uid = nuim.nbs_ui_metadata_uid
         left outer join nbs_odse.dbo.nbs_answer pa
    with (nolock)
                         on
                             nuim.nbs_question_uid = pa.nbs_question_uid
         LEFT join nbs_srte.dbo.code_value_general cvg
    with (nolock)
                   on
                       cvg.code = nuim.data_type
where cvg.code_set_nm = 'NBS_DATA_TYPE'
  and nuim.data_location = 'NBS_ANSWER.ANSWER_TXT'
;