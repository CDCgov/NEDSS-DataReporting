-- =====================================================================
-- Tier 3 (NO-SHORTCUT, Round 6 tick 6) — Contact-record GAP fill
--   for d_contact_record (RDB_MODERN 40/66) + covid_contact_datamart
--   (76/94). Authors a NEW, fully-attributed contact-record ODSE chain
--   that the real pipeline turns into datamart coverage.
-- =====================================================================
-- Authored 2026-06-04. UID block 22073000-22073999 (reserved in
--   catalog/uid_ranges.md "R6t6 contact agent"). ODSE-ONLY: no nrt_*
--   INSERTs, no EXEC sp_*, no seed/SRTE/routine edits. Additive only.
--
-- WHY bug #20 (obs-batch fail-fast) made this SAFE NOW
--   Until bug #20 was fixed, a throwing OBSERVATION (priority 14) in a CDC
--   batch set processingFailed and SKIPPED every lower-priority entity,
--   incl. CONTACT (priority 15). So contact fixtures were "flaky" (the
--   covid_contact / d_contact_record bounce documented across R4/R5). With
--   fault isolation in PostProcessingService (bug #20, commit 32566c8b) a
--   throwing OBSERVATION no longer skips CONTACT -> this chain lands
--   deterministically.
--
-- THE CHAIN (CDC -> service -> postprocessing, all ODSE-authored here)
--   dbo.CT_contact (CDC source; in odse_main_connector.json include.list)
--     -> nbs_CT_contact topic
--     -> reporting-pipeline-service ContactRepository.computeContact
--        -> EXEC sp_contact_record_event (routine 069): reads CT_CONTACT
--           + CT_CONTACT_ANSWER (via V_RDB_UI_METADATA_ANSWERS_CONTACT) +
--           NBS_SRTE codesets; emits the contact JSON (answers + rdb_cols)
--     -> service writes nrt_contact + nrt_contact_answer + nrt_metadata_columns
--     -> CONTACT-entity postprocessing (priority 15) runs
--        sp_d_contact_record_postprocessing (036) -> D_CONTACT_RECORD and
--        sp_f_contact_record_case_postprocessing (038) -> F_CONTACT_RECORD_CASE
--   Then Step 9 of merge_and_verify runs
--     sp_covid_contact_datamart_postprocessing @phcid_list=$PHC_UIDS
--   keyed on nrt_contact.SUBJECT_ENTITY_PHC_UID = inv.public_health_case_uid
--   AND inv.cd='11065' AND inv.public_health_case_uid IN ($PHC_UIDS).
--   Our contact's SUBJECT_ENTITY_PHC_UID = 22003000 (COVID index PHC,
--   already in $PHC_UIDS) -> a NEW covid_contact_datamart row (the SP
--   INSERT-only appends; coverage unions across rows).
--
-- ============ TARGET COLUMNS ============
-- (A) d_contact_record DYNAMIC-PIVOT columns (the bulk of the 26 NULLs).
--   Verified live: NRT_METADATA_COLUMNS has 0 rows for D_CONTACT_RECORD and
--   CT_CONTACT_ANSWER is EMPTY (0 rows) -> the SP's PIVOT branch (036:313-
--   338 / 463-490, gated on NRT_METADATA_COLUMNS) NEVER fired, so every
--   answer-driven CTT_* column was NULL. The event SP (069) BUILDS
--   nrt_metadata_columns from #D_CONTACT_RECORD_COLUMNS (the rdb_cols it
--   derives from #UNIONED_DATA via nbs_rdb_metadata WHERE
--   RDB_TABLE_NM='D_CONTACT_RECORD'); the service writes those rows to
--   nrt_metadata_columns -> the PIVOT then fires. So authoring CT_CONTACT_
--   ANSWER rows is sufficient (no NRT_METADATA_COLUMNS hand-seeding -- that
--   would be the banned nrt_* shortcut).
--   Columns filled (14), with their NBS_QUESTION_UID + data_type
--   (verified via NBS_ODSE.dbo.V_RDB_UI_METADATA_ANSWERS_CONTACT, which
--   LEFT-joins CT_CONTACT_ANSWER on nbs_question_uid):
--     CTT_EXPOSURE_TYPE       q=7107      CODED  NBS_EXPOSURE_TYPE  'HOUSEHLD'
--     CTT_EXPOSURE_SITE_TYPE  q=7065      CODED  NBS_EXPOSURE_LOC   'HOME'
--     CTT_FIRST_EXPOSURE_DT   q=7067      DATE   2026-03-28
--     CTT_LAST_EXPOSURE_DT    q=7068      DATE   2026-04-01
--     CTT_FIRST_SEX_EXP_DT    q=10001182  DATE   2026-03-25
--     CTT_LAST_SEX_EXP_DT     q=10001184  DATE   2026-03-30
--     CTT_INITIATE_FOLLOWUP_DT q=10001353 DATE   2026-04-04
--     CTT_REL_WITH_PATIENT    q=10001348  CODED  CONTACT_REL_WITH   'THSPAT'
--     CTT_SOURCE_SPREAD       q=10001194  CODED  SOURCE_SPREAD      'SO'
--     CTT_HEIGHT              q=10001169  TEXT   '5 ft 10 in'
--     CTT_SIZE_BUILD          q=10001170  TEXT   'Medium'
--     CTT_HAIR                q=10001171  TEXT   'Brown'
--     CTT_COMPLEXION          q=10001172  TEXT   'Fair'
--     CTT_OTHER_ID_INFO       q=10001173  TEXT   'Tattoo on left forearm'
--   (All 14 nbs_question_uids verified present in NBS_ODSE.dbo.nbs_rdb_metadata
--   for RDB_TABLE_NM='D_CONTACT_RECORD' so #D_CONTACT_RECORD_COLUMNS lists
--   them and the metadata-columns row is written. CODED group ids 4440/4470/
--   105920/105050 -> code sets NBS_EXPOSURE_TYPE/NBS_EXPOSURE_LOC/
--   CONTACT_REL_WITH/SOURCE_SPREAD all carry the chosen codes in NBS_SRTE.)
--
-- (B) covid_contact_datamart columns:
--   CR_EXPOSURE_TYPE / CR_EXPOSURE_SITE_TY / CR_FIRST_EXPOSURE_DT /
--   CR_LAST_EXPOSURE_DT  <- nrt_contact_answer (con_ans1..4 in routine 315,
--     keyed rdb_column_nm = CTT_EXPOSURE_TYPE/SITE_TYPE/FIRST/LAST_EXPOSURE_DT)
--     -> filled by the SAME CT_CONTACT_ANSWER rows above (the 4 exposure cols).
--   CR_STATUS            <- con.CTT_STATUS_CODE = CT_CONTACT.CONTACT_STATUS.
--     zz_covid_contact_fill left it NULL; we set CONTACT_STATUS='C' here.
--   CR_INV_FIRST_NAME / CR_INV_LAST_NAME  <- ctt_pat_con = D_PATIENT ON
--     PATIENT_UID = con.CONTACT_ENTITY_UID (315:326-327). We make the
--     contact party 22073000 a richly-named SubjOfPHC patient of its OWN
--     contact-side PHC 22073100 -> the pipeline builds D_PATIENT 22073000
--     -> CR_INV_FIRST_NAME/LAST_NAME fill.
--   CTT_INV_DEATH_DT / CTT_INV_STATE_CASE_ID / CTT_INV_LEGACY_CASE_ID  <-
--     con_inv = nrt_investigation ON con.CONTACT_ENTITY_PHC_UID (315:289-290,
--     UNGATED by @phcid_list per the side-fixture finding). Our contact-side
--     PHC 22073100 carries deceased_time / inv_state_case_id (act_id ROOT) /
--     legacy_case_id so these three CTT_INV_* fill from the nrt_investigation
--     scalars. (CTT_INV_CDC_ASSIGNED_ID / _RPTNG_CNTY / _SYMPTOMATIC /
--     _SYMPTOM_STATUS read nrt_page_case_answer on 22073100 -- the 4
--     nbs_case_answer rows below feed the page-builder; if 22073100 is not
--     in $PHC_UIDS the page-builder may not materialise its nrt_page_case_
--     answer, in which case those 4 stay NULL -- see "OUT OF REACH".)
--
-- ============ OUT OF REACH (documented, not attempted) ============
--   d_contact_record:
--     CTT_STATUS        - status lookup fn_get_value_by_cd_codeset on INV109;
--                         NBS_SRTE codeset INV109 ships 0 rows -> SEED-GATED.
--     CTT_GROUP_LOT_ID  - GROUP_NAME_CD -> NBS_GROUP_NM; that codeset ships
--                         0 rows -> SEED-GATED (existing 22051010 has
--                         group_name_cd='GRP_HEPA' yet CTT_GROUP_LOT_ID NULL,
--                         confirming the gate).
--     TREATMNT_END_DESCRIPTION - no nbs_ui_metadata mapping for D_CONTACT_
--                         RECORD (data_location differs) -> unreachable via answers.
--     CR_CONTACT1 / CR_CONTACT2 / CTT_*_NDLSHARE_* / CTT_*_INTERNET* /
--     CTT_SPOUSE_OF_OP / CTT_SEX_EXP_FREQ / CTT_NDLSHARE_EXP_FREQ - STD-
--                         specific follow-up columns; not authored on a COVID
--                         contact (would need STD code sets/forms; low value).
--   covid_contact_datamart:
--     SRC_INV_STATE_CASE_ID / SRC_INV_LEGACY_CASE_ID - read from the SHARED
--                         index PHC 22003000's nrt_investigation, which has
--                         neither (forbidden to UPDATE a shared inv); our new
--                         datamart row's SRC_* reads the same index PHC ->
--                         stay NULL.
--     CTT_PATIENT_AGE_RPTD_UNIT - nrt_contact_patient joined on CONTACT_
--                         ENTITY_PHC_UID = nrt_patient.patient_uid (315:293-294),
--                         i.e. an nrt_patient whose patient_uid equals a PHC
--                         uid -- a structural quirk that cannot be satisfied
--                         cleanly/additively. Left NULL.
--     CTT_PATIENT_DECEASED_DT - contact patient 22073000 is deceased_ind 'N'
--                         by design -> NULL (clinically correct for a contact).
--
-- IDENTITY: nbs_case_answer auto-IDENTITY + natural-key guard (LESSON 10/11:
--   never hardcode IDENTITY_INSERT on the flood-prone nbs_case_answer; guard
--   on (act_uid, nbs_question_uid) + answer_group_seq_nbr IS NULL). All other
--   inserts use explicit in-block UIDs on non-flooded tables.
-- GENERATED ALWAYS period cols omitted from public_health_case.
--
-- ORCH_TODO (optional, NOT required for the gains above): to also fill the
--   4 page-answer-driven CTT_INV_* cols (CDC_ASSIGNED_ID/RPTNG_CNTY/
--   SYMPTOMATIC/SYMPTOM_STATUS), add contact-side PHC 22073100 to $PHC_UIDS
--   in scripts/merge_and_verify.sh so the page-builder materialises its
--   nrt_page_case_answer. Not done here (no harness edit in scope); the
--   nbs_case_answer rows are authored so the gain is available if added.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;   -- conventional NBS superuser id

-- ----- references (read-only, existing) -----
DECLARE @covid_index_phc      bigint = 22003000;   -- COVID index PHC (cond 11065, in $PHC_UIDS)
DECLARE @covid_index_patient  bigint = 20000000;   -- COVID index patient (SubjOfPHC of 22003000)

-- ----- UID allocations (block 22073000-22073999) -----
DECLARE @ctt_party_uid   bigint = 22073000;   -- contact party PSN/PAT (becomes D_PATIENT via its own PHC)
DECLARE @ctt_pst_home    bigint = 22073001;   -- contact home address
DECLARE @ctt_tel_home    bigint = 22073002;   -- contact home phone
DECLARE @ctt_phc_uid     bigint = 22073100;   -- contact-side PHC (con_inv) -> CTT_INV_*
DECLARE @ct_contact_uid  bigint = 22073200;   -- act + ct_contact for the new contact record

-- =====================================================================
-- (1) Contact party 22073000: a richly-named patient person. It is the
--     SubjOfPHC of its OWN contact-side PHC 22073100 (below) so the
--     pipeline builds D_PATIENT 22073000 (CR_INV_FIRST/LAST_NAME +
--     CTT_PATIENT_*). NOT deceased (deceased_ind 'N').
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[person] WHERE person_uid = @ctt_party_uid)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES (@ctt_party_uid, N'PSN');

    INSERT INTO [dbo].[person]
        ([person_uid], [add_time], [add_user_id],
         [birth_gender_cd], [birth_time], [cd], [curr_sex_cd], [deceased_ind_cd],
         [ethnic_group_ind], [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [first_nm], [middle_nm], [last_nm], [version_ctrl_nbr],
         [as_of_date_general], [as_of_date_admin], [as_of_date_sex],
         [electronic_ind], [person_parent_uid], [edx_ind],
         [age_reported], [age_reported_unit_cd],
         [description])
    VALUES
        (@ctt_party_uid, '2026-04-15T10:00:00', @superuser_id,
         N'M', '1988-09-22T00:00:00', N'PAT', N'M', N'N',
         N'2186-5', CAST(GETDATE() AS DATE), @superuser_id, N'PSN22073000GA01',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00',
         N'Daniel', N'James', N'Okafor', 1,
         '2026-04-15T10:00:00', '2026-04-15T10:00:00', '2026-04-15T10:00:00',
         N'N', @ctt_party_uid, N'Y',
         N'37', N'Y',
         N'COVID-19 contact-record subject — Round 6 tick 6 (contact gap)');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (@ctt_party_uid, 1, '2026-04-15T10:00:00', @superuser_id,
         N'Daniel', N'James', N'Okafor', N'L',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00');

    -- person_race so D_PATIENT.PATIENT_RACE_CALCULATED populates and the UI
    -- patient file shows a Race (this patient had none).
    INSERT INTO [dbo].[person_race]
        ([person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
         [as_of_date])
    VALUES
        (@ctt_party_uid, N'2054-5', N'2054-5',  -- Black or African American root
         '2026-04-15T10:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-15T10:00:00',
         '2026-04-15T10:00:00');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [street_addr2], [zip_cd])
    VALUES
        (@ctt_pst_home, '2026-04-15T10:00:00', @superuser_id, N'Atlanta',
         N'840', N'13121', CAST(GETDATE() AS DATE), @superuser_id,
         N'ACTIVE', '2026-04-15T10:00:00', N'13',
         N'47 Tracing Trail', N'Unit 9', N'30303');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (@ctt_tel_home, '2026-04-15T10:00:00', @superuser_id, N'1',
         CAST(GETDATE() AS DATE), @superuser_id, N'404-555-7300',
         N'ACTIVE', '2026-04-15T10:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (@ctt_party_uid, @ctt_pst_home, '2026-04-15T10:00:00', @superuser_id, N'H',
         N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'contact home address',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'H', 1, '2026-04-15T10:00:00'),
        (@ctt_party_uid, @ctt_tel_home, '2026-04-15T10:00:00', @superuser_id, N'PH',
         N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'contact home phone',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'H', 1, '2026-04-15T10:00:00');
END
GO

-- =====================================================================
-- (2) Contact-side PHC 22073100 -> nrt_investigation (con_inv) -> CTT_INV_*.
--     Carries deceased_time (CTT_INV_DEATH_DT), a STATE act_id seq=1
--     (CTT_INV_STATE_CASE_ID) and a LEGACY act_id seq=3
--     (CTT_INV_LEGACY_CASE_ID) -- verified mapping in
--     ProcessInvestigationDataUtil (STATE&&seq1 -> invStateCaseId;
--     LEGACY&&seq3 -> legacyCaseId). cd='11065', jurisdiction 130001.
-- =====================================================================
DECLARE @superuser_id2 bigint = 10009282;
DECLARE @ctt_phc2 bigint = 22073100;

IF NOT EXISTS (SELECT 1 FROM [dbo].[act] WHERE act_uid = @ctt_phc2)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES (@ctt_phc2, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
         [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
         [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
         [program_jurisdiction_oid], [outbreak_ind],
         [mmwr_week], [mmwr_year],
         [hospitalized_ind_cd], [diagnosis_time],
         [effective_from_time], [effective_to_time],
         [outcome_cd], [deceased_time], [activity_from_time])
    VALUES
        (@ctt_phc2, '2026-04-15T10:00:00', @superuser_id2, N'I',
         N'C', N'11065', N'2019 Novel Coronavirus', N'NND', N'NND',
         N'C', CAST(GETDATE() AS DATE), @superuser_id2, N'CAS22073100GA01',
         N'OPEN', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00',
         N'T', 1, N'COV', N'130001',
         22073100, N'N',
         N'16', N'2026',
         N'Y', '2026-04-14T00:00:00',
         '2026-04-12T00:00:00', '2026-04-28T00:00:00',
         N'D', '2026-04-27T00:00:00', '2026-04-15T00:00:00');

    -- act_id seq=1 type=STATE -> nrt_investigation.inv_state_case_id
    --   (ProcessInvestigationDataUtil: typeCode='STATE' && actIdSeq==1).
    -- act_id seq=3 type=LEGACY -> nrt_investigation.legacy_case_id
    --   (ProcessInvestigationDataUtil: typeCode='LEGACY' && actIdSeq==3).
    INSERT INTO [dbo].[act_id]
        ([act_uid], [act_id_seq], [add_time], [add_user_id],
         [assigning_authority_cd], [assigning_authority_desc_txt],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [root_extension_txt], [type_cd],
         [type_desc_txt], [status_cd], [status_time])
    VALUES
        (@ctt_phc2, 1, '2026-04-15T10:00:00', @superuser_id2,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE',
         '2026-04-15T10:00:00', N'GA-COV-22073100', N'STATE',
         N'State Case Identifier', N'A', '2026-04-15T10:00:00'),
        (@ctt_phc2, 3, '2026-04-15T10:00:00', @superuser_id2,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE',
         '2026-04-15T10:00:00', N'LEGACY-22073100', N'LEGACY',
         N'Legacy Case Identifier', N'A', '2026-04-15T10:00:00');
END
GO

-- SubjOfPHC participation: contact-side PHC 22073100 -> contact party 22073000.
-- Routine 056 maps SubjOfPHC + PSN + person cd='PAT' -> nrt_investigation.patient_id
-- -> D_PATIENT 22073000 built -> CR_INV_FIRST/LAST_NAME + CTT_PATIENT_*.
DECLARE @ctt_phc3 bigint = 22073100;
DECLARE @ctt_party3 bigint = 22073000;
DECLARE @superuser_id3 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @ctt_phc3 AND type_cd = 'SubjOfPHC' AND subject_entity_uid = @ctt_party3)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@ctt_phc3, @ctt_party3, N'SubjOfPHC', N'CASE', N'PSN',
     '2026-04-15T10:00:00', @superuser_id3, CAST(GETDATE() AS DATE), @superuser_id3,
     N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'Subject of Public Health Case');
GO

-- =====================================================================
-- (3) Page answers on the contact-side PHC 22073100 (NBS547/NOT113/
--     INV576/NBS555) feeding the page-builder -> nrt_page_case_answer ->
--     CTT_INV_CDC_ASSIGNED_ID / _RPTNG_CNTY / _SYMPTOMATIC / _SYMPTOM_STATUS.
--     (Materialises only if 22073100 is added to $PHC_UIDS — see ORCH_TODO;
--     authored so the gain is available, harmless otherwise.)
--     nbs_case_answer auto-IDENTITY; guard on (act_uid, first q) + group NULL.
-- =====================================================================
DECLARE @page_phc bigint = 22073100;
DECLARE @su4 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @page_phc AND nbs_question_uid = 10004135 AND answer_group_seq_nbr IS NULL)
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid], [add_time], [add_user_id],
     [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [seq_nbr])
VALUES
    -- NBS547 CDC-Assigned Case ID -> text
    (@page_phc, '2026-04-15T10:00:00', @su4,
     N'CDC-22073100', 10004135, 1, CAST(GETDATE() AS DATE), @su4, N'ACTIVE', '2026-04-15T10:00:00', 0),
    -- NOT113 Reporting County -> Fulton (13121)
    (@page_phc, '2026-04-15T10:00:00', @su4,
     N'13121', 10001005, 1, CAST(GETDATE() AS DATE), @su4, N'ACTIVE', '2026-04-15T10:00:00', 0),
    -- INV576 Symptomatic -> Y
    (@page_phc, '2026-04-15T10:00:00', @su4,
     N'Y', 10001027, 1, CAST(GETDATE() AS DATE), @su4, N'ACTIVE', '2026-04-15T10:00:00', 0),
    -- NBS555 Symptom status -> SYMP_RESOLVE
    (@page_phc, '2026-04-15T10:00:00', @su4,
     N'SYMP_RESOLVE', 10004179, 1, CAST(GETDATE() AS DATE), @su4, N'ACTIVE', '2026-04-15T10:00:00', 0);
GO

-- =====================================================================
-- (4) Contact Act (ENC/EVN) + ct_contact: subject = COVID index PHC
--     22003000 (drives the datamart main join + cd=11065). contact party =
--     22073000 (its own contact-side PHC 22073100). CONTACT_STATUS='C' so
--     CR_STATUS fills. Rich CR_* scalars mirror the proven v2 contact.
-- =====================================================================
DECLARE @su5 bigint = 10009282;
DECLARE @ct5 bigint = 22073200;
DECLARE @idxphc5 bigint = 22003000;
DECLARE @idxpat5 bigint = 20000000;
DECLARE @ctparty5 bigint = 22073000;
DECLARE @cttphc5 bigint = 22073100;

IF NOT EXISTS (SELECT 1 FROM [dbo].[ct_contact] WHERE ct_contact_uid = @ct5)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES (@ct5, N'ENC', N'EVN');

    INSERT INTO [dbo].[ct_contact]
        ([ct_contact_uid], [local_id], [subject_entity_uid], [contact_entity_uid],
         [subject_entity_phc_uid], [contact_entity_phc_uid],
         [record_status_cd], [record_status_time],
         [add_user_id], [add_time], [last_chg_time], [last_chg_user_id],
         [version_ctrl_nbr],
         [prog_area_cd], [jurisdiction_cd], [program_jurisdiction_oid],
         [shared_ind_cd], [shared_ind],
         [contact_status],
         [priority_cd], [group_name_cd],
         [investigator_assigned_date], [disposition_cd], [disposition_date],
         [named_on_date],
         [relationship_cd], [health_status_cd],
         [txt],
         [symptom_cd], [symptom_onset_date], [symptom_txt],
         [risk_factor_cd], [risk_factor_txt],
         [evaluation_completed_cd], [evaluation_date], [evaluation_txt],
         [treatment_initiated_cd], [treatment_start_date],
         [treatment_not_start_rsn_cd],
         [treatment_end_cd], [treatment_end_date],
         [treatment_not_end_rsn_cd], [treatment_txt],
         [processing_decision_cd],
         [subject_entity_epi_link_id], [contact_entity_epi_link_id],
         [contact_referral_basis_cd])
    VALUES
        (@ct5, N'CON22073200GA01',
         @idxpat5, @ctparty5,
         @idxphc5, @cttphc5,
         N'ACTIVE', '2026-04-15T10:00:00',
         @su5, '2026-04-15T10:00:00', CAST(GETDATE() AS DATE), @su5,
         1,
         N'COV', N'130001', 9999999,
         N'Y', N'Y',
         N'C',                                          -- CONTACT_STATUS -> CR_STATUS / CTT_STATUS_CODE
         N'HIGH', N'GRP_HEPA',
         '2026-04-10T08:00:00', N'CONF', '2026-04-20T08:00:00',
         '2026-04-09T08:00:00',
         N'PARTNER', N'AILL',
         N'Household contact of confirmed COVID-19 case; identified during interview.',
         N'Y', '2026-04-12T08:00:00', N'Mild cough and fever, no dyspnea.',
         N'Y', N'Shared household with index case during infectious period.',
         N'Y', '2026-04-13T08:00:00', N'Symptom screen + testing referral completed.',
         N'N', NULL,
         N'REFUSETX',
         N'N', NULL,
         N'PROVDEC', N'No treatment indicated for contact at this time.',
         N'FF',
         N'EPI22003000', N'EPI22073200',
         N'P1');
END
GO

-- =====================================================================
-- (5) CT_CONTACT_ANSWER rows for the new contact 22073200 — the unique
--     value-add of this fixture (CT_CONTACT_ANSWER was EMPTY). These flow
--     through V_RDB_UI_METADATA_ANSWERS_CONTACT -> sp_contact_record_event
--     -> nrt_contact_answer (+ nrt_metadata_columns) -> the d_contact_record
--     dynamic pivot (CTT_* answer cols) AND covid_contact_datamart's
--     CR_EXPOSURE_TYPE/SITE_TY/FIRST/LAST_EXPOSURE_DT (con_ans1..4).
--     PK ct_contact_answer_uid only -> safe explicit in-block UIDs.
-- =====================================================================
DECLARE @su6 bigint = 10009282;
DECLARE @ct6 bigint = 22073200;

SET IDENTITY_INSERT [dbo].[ct_contact_answer] ON;

IF NOT EXISTS (SELECT 1 FROM [dbo].[ct_contact_answer]
               WHERE ct_contact_uid = @ct6 AND nbs_question_uid = 7107)
INSERT INTO [dbo].[ct_contact_answer]
    ([ct_contact_answer_uid], [ct_contact_uid], [answer_txt], [nbs_question_uid],
     [nbs_question_version_ctrl_nbr], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [seq_nbr])
VALUES
    -- CODED exposure type/site (codes resolve via NBS_EXPOSURE_TYPE / NBS_EXPOSURE_LOC)
    (22073300, @ct6, N'HOUSEHLD',   7107,      1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    (22073301, @ct6, N'HOME',       7065,      1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    -- DATE exposure first/last
    (22073302, @ct6, N'2026-03-28', 7067,      1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    (22073303, @ct6, N'2026-04-01', 7068,      1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    -- DATE sexual exposure first/last + follow-up initiation
    (22073304, @ct6, N'2026-03-25', 10001182, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    (22073305, @ct6, N'2026-03-30', 10001184, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    (22073306, @ct6, N'2026-04-04', 10001353, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    -- CODED relationship-with-patient / source-spread
    (22073307, @ct6, N'THSPAT',     10001348, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    (22073308, @ct6, N'SO',         10001194, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    -- TEXT physical description
    (22073309, @ct6, N'5 ft 10 in', 10001169, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    (22073310, @ct6, N'Medium',     10001170, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    (22073311, @ct6, N'Brown',      10001171, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    (22073312, @ct6, N'Fair',       10001172, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0),
    (22073313, @ct6, N'Tattoo on left forearm', 10001173, 1, CAST(GETDATE() AS DATE), @su6, N'ACTIVE', '2026-04-15T10:00:00', 0);

SET IDENTITY_INSERT [dbo].[ct_contact_answer] OFF;
GO

-- =====================================================================
-- (6) last_chg_time bump on the new ct_contact to (re)fire CDC on
--     dbo.CT_contact -> sp_contact_record_event -> nrt_contact /
--     nrt_contact_answer / nrt_metadata_columns -> contact postprocessing.
--     Idempotent: only bumps the row we authored.
-- =====================================================================
UPDATE [dbo].[ct_contact]
SET [last_chg_time] = '2026-04-16T10:00:00'
WHERE [ct_contact_uid] = 22073200
  AND [last_chg_time] < '2026-04-16T10:00:00';
GO

PRINT 'zz_contact_record_gap.sql applied: new ODSE contact 22073200 (subject_entity_phc_uid=22003000, contact_entity 22073000 w/ contact-side PHC 22073100) + 14 CT_CONTACT_ANSWER rows + 4 page answers. Pipeline -> nrt_contact/nrt_contact_answer/nrt_metadata_columns -> d_contact_record dynamic pivot + covid_contact_datamart CR_*/CTT_INV_* gap fill.';
GO
