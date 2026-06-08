# Bug #22: LDF (Local Data Field) subsystem: real source + which tables are seed/chain-gated

FINDING (architecture): the faithful no-shortcut source for the LDF datamart tables is
NBS_ODSE.dbo.State_Defined_Field_Data (the LDF answer), CDC-captured -> LdfDataService ->
sp_ldf_data_event (dispatched by business_object_nm: PAT/PRV/ORG/PHC) -> nrt_ldf_data ->
PostProcessingService auto-runs sp_nrt_ldf_postprocessing + sp_nrt_ldf_dimensional_data_postprocessing
+ per-condition LDF datamart SPs. The three pre-existing fixtures (ldf_answers_bmird_hepatitis.sql,
ldf_answers_tetanus.sql, zz_ldf_flagged_answers.sql) are GUTTED NO-OPS on this branch; their
nrt_ldf_data / nrt_odse_state_defined_field_metadata INSERTs + EXEC sp_* were stripped (now-forbidden
shortcuts), leaving only comments. That is why the LDF tables are empty.

AUTHORABLE (ODSE-only, fixture zz_ldf_subsystem.sql, currently quarantined, see bug #20):
PATIENT_LDF_GROUP, ORGANIZATION_LDF_GROUP (0 -> 3/3 each), plus rows into LDF_DATA (9->15),
LDF_DIMENSIONAL_DATA (9->12), LDF_GROUP, D_LDF_META_DATA, via PAT/ORG/PHC State_Defined_Field_Data
answers on existing entities (person 10000008, org 10003001, PHC 22047500 cd=10270).

OUT OF BOUNDS (seed/chain-gated, do not chase from ODSE-only fixtures):
- LDF_BMIRD, LDF_HEPATITIS: SEED-GATED. Zero seeded State_Defined_Field_MetaData rows for any BMIRD/HEP
  condition or business_object_nm IN ('BMD','HEP'). Needs metadata seeding (bug #16 class).
- LDF_FOODBORNE, LDF_MUMPS, LDF_TETANUS: CHAIN-GATED. Their SPs inner-join GENERIC_CASE (empty;
  only populated for investigation_form_cd LIKE 'INV_FORM_GEN%', which no fixture creates).
- TB_PAM_LDF, VAR_PAM_LDF: SEED-GATED via nrt_page_case_answer.ldf_status_cd (NULL for all 12531
  nbs_ui_metadata rows; no RVCT/VAR question carries both an LDF flag and a datamart_column_nm).
- PROVIDER_LDF_GROUP: DATA-SHAPE-GATED. All 21 seeded PRV persons have person_uid=person_parent_uid,
  which the provider event proc (routine 057) filters out. Needs a new foundation provider.
