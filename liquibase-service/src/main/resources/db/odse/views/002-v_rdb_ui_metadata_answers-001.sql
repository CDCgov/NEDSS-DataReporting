IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_rdb_ui_metadata_answers')
BEGIN
    DROP VIEW [dbo].v_rdb_ui_metadata_answers
END
--GO   "GO" not supported by liquibase, keep "GO" in manual scripts

CREATE VIEW [dbo].v_rdb_ui_metadata_answers 
AS
SELECT 
	PA.nbs_answer_uid,
	nuim.nbs_ui_metadata_uid,
	nrdbm.nbs_rdb_metadata_uid,
	nrdbm.rdb_table_nm,
	nrdbm.rdb_column_nm,
	nuim.code_set_group_id,
	CAST(REPLACE(answer_txt, CHAR(13) + CHAR(10), ' ') AS VARCHAR(2000)) AS answer_txt,
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
FROM nbs_odse.[dbo].nbs_rdb_metadata nrdbm WITH (NOLOCK)
INNER JOIN nbs_odse.[dbo].nbs_ui_metadata nuim WITH (NOLOCK)
	ON nrdbm.nbs_ui_metadata_uid = nuim.nbs_ui_metadata_uid
LEFT OUTER JOIN nbs_odse.[dbo].nbs_answer pa WITH (NOLOCK)
	ON nuim.nbs_question_uid = pa.nbs_question_uid
LEFT JOIN nbs_srte.[dbo].code_value_general cvg WITH (NOLOCK)
	ON cvg.code = nuim.data_type
WHERE 
	cvg.code_set_nm = 'NBS_DATA_TYPE'
  	AND nuim.data_location = 'NBS_ANSWER.ANSWER_TXT';