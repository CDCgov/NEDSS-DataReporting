-- =====================================================================
-- Round 4 (NO-SHORTCUT) — BMIRD Strep pneumo datamart fill (ODSE-only)
-- =====================================================================
-- TARGET: raise dbo.bmird_strep_pneumo_datamart from 49/140 toward full
--   for BMIRD Strep pneumoniae invasive PHC 22005000 (cond 11717, form
--   INV_FORM_BMDSP). The datamart already has its 1 row (49 cols filled
--   from investigation-level nrt_investigation attrs); the gap is 91 NULL
--   observation/multi-value columns.
--
-- HOW THE COLUMNS POPULATE (proven from the routines, 2026-06-03):
--   sp_bmird_strep_pneumo_datamart_postprocessing (routine 140) builds
--   entirely FROM dbo.BMIRD_CASE (+ ANTIMICROBIAL + BMIRD_MULTI_VALUE_FIELD).
--   BMIRD_CASE is itself built by sp_bmird_case_datamart_postprocessing
--   (routine 040) from dbo.v_rdb_obs_mapping (view 010), which is:
--       nrt_srte_IMRDBMapping (unique_cd -> RDB_attribute/db_field)
--       JOIN v_getobs{code,num,txt,date} ON unique_cd = obs.cd
--       filtered branch_type_cd='InvFrmQ'
--   So every BMD* column comes from an InvFrmQ *observation* whose
--   nrt_observation.cd matches an IMRDBMapping unique_cd, with the answer
--   in nrt_observation_coded/_numeric/_txt/_date per the db_field:
--       code            -> Obs_value_coded.code
--       numeric_value_1 -> Obs_value_numeric.numeric_value_1
--       value_txt       -> Obs_value_txt.value_txt
--       from_time       -> Obs_value_date.from_time   (date_response)
--   NOTE: db_field='diagnosis_time'/'duration_amt' are NOT mapped by
--   v_rdb_obs_mapping's CASE (only from_time is date) — so BMD124
--   FIRST_POSITIVE_CULTURE_DT (diagnosis_time) and BMD267 (duration_amt)
--   cannot be filled via this obs path. Excluded below.
--
--   Multi-value-field columns (UNDERLYING_CONDITION_n, NON_STERILE_SITE_n,
--   ADD_CULTURE_{1,2}_SITE_n, TYPE_INFECTION_OTHERS_CONCAT,
--   STERILE_SITE_OTHERS_CONCAT) route via RDB_table='BMIRD_Multi_Value_field'
--   in IMRDBMapping. Routine 040 derives a BMIRD_MULTI_VAL_GRP_KEY for the
--   PHC (currently sentinel 1 = no rows) and one selection per distinct
--   branch_id (= each multi-value observation_uid). Routine 140 then pivots
--   the BMIRD_MULTI_VALUE_FIELD rows into _1/_2/_3 columns. We therefore
--   author multiple distinct observations per multi-value code.
--
-- WHY THE PRIOR FIXTURES DID NOT FILL THESE
--   bmird_investigation_full_chain.sql authored ONLY the ODSE
--   act/public_health_case/act_id/case_management for 22005000 (the
--   investigation-level cols -> 49 filled). Its nrt_observation* INSERTs
--   were stripped in the no-shortcut migration, and
--   zz_bmird_strep_pneumo_datamart_enrich.sql was a pure-nrt no-op after
--   the same strip. So NO observation ever landed for 22005000 — this
--   fixture authors the real ODSE observation backing.
--
-- ODSE-ONLY: no nrt_* INSERTs, no EXEC sp_*, no seed/SRTE/liquibase edits.
--   Additive only (new UID-block entities); no UPDATE of shared dims.
--   Reuses existing PHC 22005000 (already in scripts/merge_and_verify.sh
--   PHC_UIDS, so Step-9 BMIRD SPs already target it). No GENERATED ALWAYS
--   period cols inserted.
--
-- UID block (reserved 22048000-22048999 in catalog/uid_ranges.md):
--   22048001              L1 form Observation (cd INV_FORM_BMDSP)
--   22048100-22048124     direct BMIRD_Case question observations
--   22048200-22048217     multi-value-field observations (multiple
--                         selections per BMD127/125/142/144/118/122)
--
-- Foundation deps (read-only): superuser 10009282; PHC 22005000 (act +
--   public_health_case from bmird_investigation_full_chain.sql).
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @ts datetime = '2026-04-01T00:00:00';
DECLARE @superuser_id bigint = 10009282;
DECLARE @phc_uid bigint = 22005000;   -- existing BMIRD Strep pneumo PHC
DECLARE @l1_uid  bigint = 22048001;    -- L1 form observation for this PHC

-- Only author if the obs graph is not already present (idempotent guard).
IF NOT EXISTS (SELECT 1 FROM [dbo].[Observation] WHERE observation_uid = @l1_uid)
   AND EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @phc_uid)
BEGIN

    -- ----- L1 form observation: target of every InvFrmQ, source of PHCInvForm -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@l1_uid, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation]
        ([observation_uid],[cd],[cd_system_cd],[group_level_cd],[local_id],[obs_domain_cd],
         [status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr])
    VALUES
        (@l1_uid, N'INV_FORM_BMDSP', N'NBS', N'L1', N'OBS22048001GA01', N'CLN',
         N'A', @ts, @phc_uid, N'T', 1);

    -- =================================================================
    -- DIRECT BMIRD_Case question observations (RDB_table='BMIRD_Case')
    -- One act(OBS) + Observation(cd=BMDnnn) + Obs_value_* answer each.
    -- =================================================================

    -- ---- coded (db_field='code') -> Obs_value_coded.code ----
    -- BMD120 BACTERIAL_SPECIES_ISOLATED (BM_SPEC_ISOL)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048100, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048100, N'BMD120', N'NBS', N'OBS22048100GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048100, N'10150');

    -- BMD121 BACTERIAL_OTHER_ISOLATED (BM_OTHER_BAC_SP) -> BACTERIAL_SPECIES_ISOLATED_OTH
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048101, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048101, N'BMD121', N'NBS', N'OBS22048101GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048101, N'1E000');

    -- BMD269 CASE_REPORT_STATUS (BM_CRF_STS)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048102, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048102, N'BMD269', N'NBS', N'OBS22048102GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048102, N'CHRTUNAV3');

    -- BMD131 CULTURE_SEROTYPE (SERO_TYPE)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048103, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048103, N'BMD131', N'NBS', N'OBS22048103GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048103, N'1');

    -- BMD295 INTBODYSITE (BM_ORG_ISO_S3) -> INTERNAL_BODY_SITE
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048104, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048104, N'BMD295', N'NBS', N'OBS22048104GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048104, N'119383005');

    -- BMD137 OXACILLIN_INTERPRETATION (BM_OXA_RSLT)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048105, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048105, N'BMD137', N'NBS', N'OBS22048105GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048105, N'NOTEST');

    -- BMD140 PERSISTENT_DISEASE_IND (YNU)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048106, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048106, N'BMD140', N'NBS', N'OBS22048106GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048106, N'Y');

    -- BMD151 SAME_PATHOGEN_RECURRENT_IND (YNU) -> SAME_PATHOGEN_RECURRENT
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048107, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048107, N'BMD151', N'NBS', N'OBS22048107GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048107, N'Y');

    -- BMD126 UNDERLYING_CONDITION_IND (YNU)
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048108, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048108, N'BMD126', N'NBS', N'OBS22048108GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048108, N'Y');

    -- BMD139 PNEUCONJ_RECEIVED_IND (YNU) -> VACCINE_CONJUGATE
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048109, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048109, N'BMD139', N'NBS', N'OBS22048109GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048109, N'Y');

    -- BMD138 PNEUVACC_RECEIVED_IND (YNU) -> VACCINE_POLYSACCHARIDE
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048110, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048110, N'BMD138', N'NBS', N'OBS22048110GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048110, N'Y');

    -- ---- numeric (db_field='numeric_value_1') -> Obs_value_numeric ----
    -- BMD136 OXACILLIN_ZONE_SIZE
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048111, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048111, N'BMD136', N'NBS', N'OBS22048111GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22048111, 1, 18.0, 0);

    -- ---- date (db_field='from_time') -> Obs_value_date.from_time ----
    -- BMD141 FIRST_ADDITIONAL_SPECIMEN_DT -> ADD_CULTURE_1_DATE
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048112, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048112, N'BMD141', N'NBS', N'OBS22048112GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22048112, 1, '2026-03-15T00:00:00');

    -- BMD143 SECOND_ADDITIONAL_SPECIMEN_DT -> ADD_CULTURE_2_DATE
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048113, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048113, N'BMD143', N'NBS', N'OBS22048113GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22048113, 1, '2026-03-20T00:00:00');

    -- ---- text (db_field='value_txt') -> Obs_value_txt.value_txt ----
    -- BMD119 TYPES_OF_OTHER_INFECTION -> TYPE_INFECTION_OTHER_SPECIFY
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048114, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048114, N'BMD119', N'NBS', N'OBS22048114GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048114, 1, N'Other infection note');

    -- BMD123 STERILE_SITE_OTHER
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048115, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048115, N'BMD123', N'NBS', N'OBS22048115GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048115, 1, N'Sterile site other note');

    -- BMD298 OTHNONSTER -> NON_STERILE_SITE_OTHER
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048116, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048116, N'BMD298', N'NBS', N'OBS22048116GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048116, 1, N'Non sterile site other');

    -- BMD128 OTHER_MALIGNANCY
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048117, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048117, N'BMD128', N'NBS', N'OBS22048117GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048117, 1, N'Other malignancy note');

    -- BMD129 ORGAN_TRANSPLANT
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048118, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048118, N'BMD129', N'NBS', N'OBS22048118GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048118, 1, N'Organ transplant note');

    -- BMD130 UNDERLYING_CONDITIONS_OTHER -> OTHER_PRIOR_ILLNESS_1
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048119, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048119, N'BMD130', N'NBS', N'OBS22048119GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048119, 1, N'Prior illness 1');

    -- BMD296 OTHILL2 -> OTHER_PRIOR_ILLNESS_2
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048120, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048120, N'BMD296', N'NBS', N'OBS22048120GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048120, 1, N'Prior illness 2');

    -- BMD297 OTHILL3 -> OTHER_PRIOR_ILLNESS_3
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048121, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048121, N'BMD297', N'NBS', N'OBS22048121GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048121, 1, N'Prior illness 3');

    -- BMD299 OTHSEROTYPE
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048122, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048122, N'BMD299', N'NBS', N'OBS22048122GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048122, 1, N'Other serotype note');

    -- BMD318 OTH_STREP_PNEUMO1_CULT_SITES -> ADD_CULTURE_1_OTHER_SITE
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048123, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048123, N'BMD318', N'NBS', N'OBS22048123GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048123, 1, N'Add culture 1 other site');

    -- BMD319 OTH_STREP_PNEUMO2_CULT_SITES -> ADD_CULTURE_2_OTHER_SITE
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048124, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048124, N'BMD319', N'NBS', N'OBS22048124GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22048124, 1, N'Add culture 2 other site');

    -- =================================================================
    -- MULTI-VALUE-FIELD observations (RDB_table='BMIRD_Multi_Value_field')
    -- ONE observation per question carrying N distinct Obs_value_coded rows
    -- (one per selection). This is the shape legacy MasterETL (the authority)
    -- requires: BMIRD_Case.sas roots every answer at the form, so it can only
    -- separate multi-selects by cd_seq, which increments across the multiple
    -- coded values WITHIN a single child observation. Authoring each selection
    -- as its own observation makes them all cd_seq=1 and the SAS transpose
    -- collides ("Col_nm ... occurs twice in the same BY group"), emptying
    -- BMIRD_CASE and cascading to F_PAGE_CASE / INV_SUMM_DATAMART. RTR is made
    -- tolerant of this shape downstream (v_getobscode already yields one row per
    -- coded value; routine 040 distinguishes selections per coded value).
    -- =================================================================

    -- BMD127 UNDERLYING_CONDITION_NM (BM_UNDERL_CAUSE) x3 -> UNDERLYING_CONDITION_1..3
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048200, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048200, N'BMD127', N'NBS', N'OBS22048200GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048200, N'19030005'), (22048200, N'20823009'), (22048200, N'414915002');

    -- BMD125 NON_STERILE_SITE (BM_ORG_ISO_S2) x3 -> NON_STERILE_SITE_1..3
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048203, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048203, N'BMD125', N'NBS', N'OBS22048203GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048203, N'AMNIOTIC'), (22048203, N'MIDDLEAR'), (22048203, N'OTH');

    -- BMD142 STREP_PNEUMO_1_CULTURE_SITES (BM_ORG_ISO_S1) x3 -> ADD_CULTURE_1_SITE_1..3
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048206, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048206, N'BMD142', N'NBS', N'OBS22048206GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048206, N'BLOOD'), (22048206, N'BONE'), (22048206, N'CSF');

    -- BMD144 STREP_PNEUMO_2_CULTURE_SITES (BM_ORG_ISO_S1) x3 -> ADD_CULTURE_2_SITE_1..3
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048209, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048209, N'BMD144', N'NBS', N'OBS22048209GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048209, N'BLOOD'), (22048209, N'BONE'), (22048209, N'CSF');

    -- BMD118 TYPES_OF_INFECTIONS (BM_INFEC_TYPE): one recognized (Pneumonia
    -- -> sets TYPE_INFECTION_PNEUMONIA='Yes') + two non-recognized
    -- (Conjunctivitis / Endocarditis -> concatenated into
    -- TYPE_INFECTION_OTHERS_CONCAT).
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048212, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048212, N'BMD118', N'NBS', N'OBS22048212GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048212, N'PNEU'), (22048212, N'9826008'), (22048212, N'56819008');

    -- BMD122 STERILE_SITE (BM_ORG_ISO_S3) x2 -> STERILE_SITE_OTHERS_CONCAT
    -- (routine 140 concatenates BMD122 sterile-site multi-values). Two distinct
    -- sterile sites (the prior fixture repeated 119383005, which can't coexist
    -- under one observation given the obs_value_coded PK on (observation_uid,code)).
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22048215, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr]) VALUES (22048215, N'BMD122', N'NBS', N'OBS22048215GA01', N'A', @ts, @phc_uid, N'T', 1);
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22048215, N'119383005'), (22048215, N'258450006');

    -- =================================================================
    -- InvFrmQ act_relationships: target=L1 form, source=each question obs.
    -- This is what sp_investigation_event turns into
    -- nrt_investigation_observation rows with branch_type_cd='InvFrmQ'
    -- (the v_getobs* filter) and branch_id=the question observation_uid.
    -- =================================================================
    INSERT INTO [dbo].[Act_relationship]
        ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],
         [record_status_cd],[record_status_time],[source_class_cd],[status_cd],
         [status_time],[target_class_cd],[type_desc_txt])
    SELECT @l1_uid, q.src, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts,
           N'OBS', N'Investigation Form Question'
    FROM (VALUES
        (22048100),(22048101),(22048102),(22048103),(22048104),(22048105),
        (22048106),(22048107),(22048108),(22048109),(22048110),(22048111),
        (22048112),(22048113),(22048114),(22048115),(22048116),(22048117),
        (22048118),(22048119),(22048120),(22048121),(22048122),(22048123),
        (22048124),
        (22048200),(22048203),(22048206),(22048209),(22048212),(22048215)
    ) AS q(src);

    -- PHCInvForm: target=PHC, source=L1 form observation. Wires the form
    -- (and thus all its InvFrmQ questions) to public_health_case 22005000.
    INSERT INTO [dbo].[Act_relationship]
        ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],
         [record_status_cd],[record_status_time],[source_class_cd],[status_cd],
         [status_time],[target_class_cd],[type_desc_txt])
    VALUES
        (@phc_uid, @l1_uid, N'PHCInvForm', @ts, CAST(GETDATE() AS DATE), N'ACTIVE', @ts, N'OBS', N'A',
         @ts, N'CASE', N'PHC Investigation Form');
END;
GO

-- Bump last_chg_time so CDC re-emits the investigation and the service
-- re-runs sp_investigation_event, building nrt_investigation_observation
-- with the InvFrmQ branches for this PHC; Step-9 then rebuilds BMIRD_CASE
-- and bmird_strep_pneumo_datamart for 22005000.
UPDATE [NBS_ODSE].[dbo].[public_health_case]
   SET [last_chg_time] = SYSDATETIME()
 WHERE public_health_case_uid = 22005000;
GO
