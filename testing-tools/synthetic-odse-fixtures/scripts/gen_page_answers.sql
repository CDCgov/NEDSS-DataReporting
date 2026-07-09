-- gen_page_answers.sql — metadata-derived page-answer generator.
--
-- Emits NBS_ODSE.dbo.nbs_case_answer INSERT statements for an investigation
-- (act_uid) covering EVERY datamart-mapped question of a page form, with a
-- type-correct answer per the real page-builder metadata graph
-- (nbs_ui_metadata -> nbs_rdb_metadata). This is how faithful coverage is
-- recovered after the nrt_* shortcut removal: real question_uids that traverse
-- the metadata so the pipeline (sp_*_event -> service -> postprocessing) routes
-- and populates the D_INV_* dimensions (and thence the datamarts).
--
-- Usage (capture the emitted INSERTs, then apply them to NBS_ODSE):
--   sqlcmd -S localhost,3433 -U sa -C -h -1 -W \
--     -v ACT_UID=22003000 \
--     -i scripts/gen_page_answers.sql > /tmp/answers.sql
--   sqlcmd ... -d NBS_ODSE -i /tmp/answers.sql
--
-- The form is DERIVED from the investigation's condition via
-- NBS_SRTE.condition_code (condition_cd -> investigation_form_cd) so it matches
-- exactly what sp_investigation_event joins on (routine 056, ~line 516-520):
-- only answers on that form resolve a non-null rdb_table_nm, which the service
-- (ProcessInvestigationDataUtil.java:459-468) aggregates into rdb_table_name_list
-- to route the investigation to its condition datamart. Authoring answers against
-- any other form (e.g. a rich PG_* form that the condition does NOT map to) is a
-- no-op for routing. Conditions mapping to legacy forms with no page-builder rdb
-- metadata (e.g. 10220 -> INV_FORM_RVCT) cannot route in this seed.
--
-- Skips questions the act already answers (additive). Coded answers resolve a
-- valid code via Codeset_Group_Metadata -> Code_value_general (fallback 'Y').
SET NOCOUNT ON;

WITH frm AS (
    SELECT cc.investigation_form_cd AS form_cd
    FROM NBS_ODSE.dbo.public_health_case phc
    JOIN NBS_SRTE.dbo.condition_code cc ON cc.condition_cd = phc.cd
    WHERE phc.public_health_case_uid = $(ACT_UID)
), mapped AS (
    SELECT DISTINCT nuim.nbs_question_uid, nuim.data_type, nuim.code_set_group_id
    FROM NBS_ODSE.dbo.nbs_ui_metadata nuim
    JOIN NBS_ODSE.dbo.nbs_rdb_metadata nrdbm
         ON nrdbm.nbs_ui_metadata_uid = nuim.nbs_ui_metadata_uid
    WHERE nuim.investigation_form_cd = (SELECT form_cd FROM frm)
      AND nrdbm.rdb_table_nm IS NOT NULL
      AND nuim.nbs_question_uid IS NOT NULL
), todo AS (
    SELECT m.*, ROW_NUMBER() OVER (ORDER BY m.nbs_question_uid) AS rn
    FROM mapped m
    WHERE NOT EXISTS (SELECT 1 FROM NBS_ODSE.dbo.nbs_case_answer a
                      WHERE a.act_uid = $(ACT_UID) AND a.nbs_question_uid = m.nbs_question_uid)
)
SELECT
  -- nbs_case_answer_uid is an IDENTITY column; omit it (auto-assigned).
  'INSERT INTO NBS_ODSE.dbo.nbs_case_answer (act_uid,nbs_question_uid,'
  + 'nbs_question_version_ctrl_nbr,answer_txt,seq_nbr,answer_group_seq_nbr,add_time,add_user_id,'
  + 'last_chg_time,last_chg_user_id,record_status_cd,record_status_time) VALUES ('
  + CAST($(ACT_UID) AS varchar(20)) + ','
  + CAST(nbs_question_uid AS varchar(20)) + ',1,'
  + CASE UPPER(ISNULL(data_type,'TEXT'))
      WHEN 'NUMERIC'  THEN '''1'''
      WHEN 'DATE'     THEN '''2026-04-01'''
      WHEN 'DATETIME' THEN '''2026-04-01T00:00:00'''
      WHEN 'CODED'    THEN '''' + ISNULL((SELECT TOP 1 cvg.code FROM NBS_SRTE.dbo.Code_value_general cvg
                                          JOIN NBS_SRTE.dbo.Codeset_Group_Metadata cgm ON cgm.code_set_nm = cvg.code_set_nm
                                          WHERE cgm.code_set_group_id = todo.code_set_group_id),'Y') + ''''
      WHEN 'PART'     THEN '''' + ISNULL((SELECT TOP 1 cvg.code FROM NBS_SRTE.dbo.Code_value_general cvg
                                          JOIN NBS_SRTE.dbo.Codeset_Group_Metadata cgm ON cgm.code_set_nm = cvg.code_set_nm
                                          WHERE cgm.code_set_group_id = todo.code_set_group_id),'Y') + ''''
      ELSE '''RTRfix'''
    END
  + ',1,0,GETDATE(),10009282,GETDATE(),10009282,''ACTIVE'',GETDATE());'
FROM todo
ORDER BY rn;
