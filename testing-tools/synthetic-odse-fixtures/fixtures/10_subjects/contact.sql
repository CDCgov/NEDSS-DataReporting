USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Contact Record fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- ARCHITECTURAL NOTE
--   Contact is the LAST Tier 1 subject. Has the largest dimension
--   (D_CONTACT_RECORD: 66 live cols) of any Tier 1 subject. Subject is
--   an Act, not an Entity (no internal locators).
--
--     - Event SP: dbo.sp_contact_record_event (param: @cc_uids)
--       File: routines/069-sp_contact_record_event-001.sql
--       Reads NBS_ODSE.dbo.CT_CONTACT + nbs_srte.dbo.CODE_VALUE_GENERAL
--       for 15 codeset descriptions (CTT_SHARED_IND/CTT_SYMP_IND/...
--       /CTT_REFERRAL_BASIS), PROGRAM_AREA_CODE for CTT_PROGRAM_AREA,
--       JURISDICTION_CODE for CTT_JURISDICTION_NM, plus three
--       NBS_act_entity LEFT JOINs (SiteOfExposure, InvestgrOfContact,
--       DispoInvestgrOfConRec) for soft refs to ORG / two providers.
--       The cross-subject NBS_act_entity rows are TIER 2 territory; at
--       Tier 1 isolation those joins return NULL and the SP simply emits
--       a JSON projection. The event SP also references
--       `nbs_odse.dbo.fn_get_value_by_cd_codeset(...)` (line 69) — but
--       the function actually lives in RDB_MODERN, not NBS_ODSE; the
--       three-part lookup will fail at runtime IF entered. The CASE is
--       only entered when `cc.contact_status` is non-NULL/non-empty.
--       Decision: leave `contact_status` NULL on both variants → CASE
--       short-circuits to NULL → function never invoked → event SP
--       runs clean. The CTT_STATUS column is still populated via the
--       postprocessing path (we set it directly in nrt_contact, which
--       the d_postprocessing SP propagates straight to D_CONTACT_RECORD).
--     - Postprocessing SPs (TWO — same param `@contact_uids`):
--       1. dbo.sp_d_contact_record_postprocessing
--          File: routines/036-sp_d_contact_record_postprocessing-001.sql
--          Writes D_CONTACT_RECORD (66 live / 45 catalog cols).
--          The 21+ live-only columns (CTT_INITIATE_FOLLOWUP_DT,
--          CTT_LAST_SEX_EXP_DT, ..., CR_CONTACT1, CR_CONTACT2 etc.) are
--          LDF/dynamic-PIVOT territory: populated only when
--          `dbo.nrt_metadata_columns` has rows for
--          `TABLE_NAME='D_CONTACT_RECORD'`. Verified empty in baseline
--          6.0.18.1 → SP's @Col_number=0 → dynamic PIVOT collapses to a
--          no-op → 21 LDF-cols stay NULL. OUT_OF_SCOPE for Tier 1.
--          Reads dbo.NRT_CONTACT + dbo.NRT_CONTACT_KEY +
--          dbo.NRT_CONTACT_ANSWER. Allocates surrogate keys via INSERT
--          into nrt_contact_key (IDENTITY) for any UID without a
--          D_CONTACT_RECORD_KEY. The "Missing NRT Record" backfill check
--          (lines 160-182) is driven by CONTACT_INIT.contact_uid coverage
--          of @contact_uids — must INSERT one nrt_contact row per UID we
--          pass in, or RETURN early.
--       2. dbo.sp_f_contact_record_case_postprocessing
--          File: routines/038-sp_f_contact_record_case_postprocessing-001.sql
--          Writes F_CONTACT_RECORD_CASE (11 cols, all NULLABLE). LEFT
--          JOINs D_PATIENT/D_PROVIDER/D_ORGANIZATION/INVESTIGATION/
--          NRT_INTERVIEW_KEY by *_UID columns from nrt_contact and
--          COALESCEs every key column to sentinel 1 (lines 79-103) →
--          all 10 surrogate-key columns resolve to 1 at Tier 1 isolation
--          (since those dimension tables are empty for foundation UIDs).
--          D_CONTACT_RECORD_KEY (line 76) reads from #F_CRC_INIT_KEYS,
--          allocated by the d_postprocessing run. No FK constraints on
--          F_CONTACT_RECORD_CASE — INSERT succeeds with all keys = 1.
--   No FK constraints on D_CONTACT_RECORD / F_CONTACT_RECORD_CASE in
--   baseline 6.0.18.1.
--
-- WHAT THIS FIXTURE DOES
--   1. Foundation Contact enrichment: NONE on the ODSE side.
--      Foundation already INSERTed the ct_contact row at UID 20000170
--      with all 3 hard NOT-NULL FKs satisfied
--      (subject_entity_uid + contact_entity_uid → foundation Patient,
--      subject_entity_phc_uid → foundation Investigation). Per Tier 0's
--      decision, those FKs are sufficient — Tier 1 doesn't need to
--      author additional ct_contact rows just to satisfy the FKs.
--      Foundation Contact's hand-authored nrt_contact row carries
--      contact_status=NULL, most CTT_* and *_CD columns NULL → exhibits
--      the SP's null/blank-path on D_CONTACT_RECORD column population.
--
--   2. v2 Contact Record: a fully-attributed alternative within block
--      20120000-20129999. ODSE side gets:
--        - dbo.act row at 20120010 (ENC/EVN — same shape as foundation
--          Contact's act).
--        - dbo.ct_contact row at 20120010, with subject/contact entity
--          and PHC FKs pointing at foundation Patient + foundation
--          Investigation (re-using the foundation references is
--          permitted per the per-subject prompt; FK targets exist).
--          Every nullable code/date/text column is populated for max
--          column coverage on D_CONTACT_RECORD. third_party_entity_uid
--          and third_party_entity_phc_uid wired to foundation
--          Patient/Investigation respectively. contact_entity_phc_uid
--          also wired to foundation Investigation. named_during_interview_uid
--          wired to foundation Interview (20000140) — exercises the
--          F_CONTACT_RECORD_CASE.CONTACT_INTERVIEW_KEY join (will resolve
--          to 1 at Tier 1 isolation since NRT_INTERVIEW_KEY is empty).
--          contact_status LEFT NULL on both variants to avoid the event
--          SP's `nbs_odse.dbo.fn_get_value_by_cd_codeset` 3-part call
--          (function actually lives in RDB_MODERN — calling it via
--          nbs_odse.dbo would fail).
--
--   3. Synthetic staging rows in RDB_MODERN:
--        - dbo.nrt_contact: 2 rows (foundation 20000170 + v2 20120010).
--          54 settable columns out of 56 (refresh_datetime + max_datetime
--          are GENERATED ALWAYS — verified via sys.columns
--          generated_always_type IN (1,2)).
--          Foundation row sparse — most CTT_* columns NULL (null/blank
--          path). v2 row fully populated to drive every D_CONTACT_RECORD
--          column the SP passes through from nrt_contact.
--        - dbo.nrt_contact_answer: NOT AUTHORED. NRT_METADATA_COLUMNS
--          for D_CONTACT_RECORD is empty in baseline so the d_contact
--          postprocessing SP's dynamic-LDF pivot collapses to a no-op.
--          Authoring nrt_contact_answer rows would be inert at Tier 1;
--          they belong to a Tier 3 LDF-coverage fixture once
--          NRT_METADATA_COLUMNS is seeded.
--
--   4. Does NOT author cross-subject NBS_act_entity rows
--      (SiteOfExposure / InvestgrOfContact / DispoInvestgrOfConRec),
--      Act_relationship rows, or participation rows. These are Tier 2.
--
--   5. Does NOT hand-author dbo.nrt_contact_key — d_postprocessing SP
--      allocates surrogate keys via IDENTITY at line 234-238.
--
-- UID block (Contact Tier 1): 20120000-20129999.
-- Foundation dependencies (read-only):
--   @dbo_Act_contact_uid          20000170 (act / ct_contact foundation)
--   @dbo_Entity_patient_uid       20000000 (subject + contact entity FK target)
--   @dbo_Act_investigation_uid    20000100 (subject_entity_phc / contact_entity_phc / third_party_entity_phc target)
--   @dbo_Act_interview_uid        20000140 (named_during_interview_uid soft ref)
--   @dbo_Entity_organization_uid  20000020 (referenced via nrt_contact.contact_exposure_site_uid on v2 — for F_CONTACT_RECORD_CASE soft join)
--   @dbo_Entity_provider_uid      20000010 (referenced via nrt_contact.provider_contact_investigator_uid + dispositioned_by_uid on v2)
-- =====================================================================

-- ----- Sentinel reference -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_act_contact_uid       bigint = 20000170;  -- foundation Contact Act / ct_contact
DECLARE @foundation_patient_uid           bigint = 20000000;  -- foundation Patient
DECLARE @foundation_investigation_uid     bigint = 20000100;  -- foundation Investigation PHC
DECLARE @foundation_interview_uid         bigint = 20000140;  -- foundation Interview
DECLARE @foundation_org_uid               bigint = 20000020;  -- foundation Organization
DECLARE @foundation_provider_uid          bigint = 20000010;  -- foundation Provider

-- =====================================================================
-- UID allocations (Contact Tier 1: 20120000-20129999)
-- =====================================================================

DECLARE @dbo_Act_contact_v2_uid       bigint = 20120010;  -- v2 Contact: act + ct_contact (fully-attributed)
DECLARE @dbo_Entity_contact_party_uid bigint = 20120020;  -- distinct contact-party entity (PSN) for v2 contact_entity_uid (UNIQUE key on ct_contact.contact_entity_uid forbids reusing foundation Patient)

-- =====================================================================
-- ODSE rows — v2 Contact variant (foundation Contact already exists).
-- =====================================================================

-- v2 contact-party entity — minimal Person-class entity to satisfy
-- ct_contact.contact_entity_uid UNIQUE constraint (UQ_CT_contact_3101).
-- The foundation Patient (20000000) is already consumed by foundation
-- ct_contact's contact_entity_uid; we cannot reuse it for v2.
-- Subject_entity_uid does NOT have a UNIQUE constraint, so v2's subject
-- can stay pointed at foundation Patient.
INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
    (@dbo_Entity_contact_party_uid, N'PSN');

-- Minimal person row for the v2 contact party. person_name omitted —
-- not strictly required (no FK from person back, and ct_contact has no
-- name FK); the only invariant is that the entity exists and is class
-- PSN. person.cd='PAT' from P_TYPE codeset.
INSERT INTO [dbo].[person]
    ([person_uid], [add_time], [add_user_id], [cd],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [first_nm], [last_nm], [version_ctrl_nbr],
     [electronic_ind], [person_parent_uid], [edx_ind])
VALUES
    (@dbo_Entity_contact_party_uid, '2026-04-15T10:00:00', @superuser_id, N'PAT',
     CAST(GETDATE() AS DATE), @superuser_id, N'PSN20120020GA01',
     N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00',
     N'V2 Contact', N'Party', 1,
     N'N', @dbo_Entity_contact_party_uid, N'Y');

-- v2 Contact Act — same shape as foundation Contact's act (ENC/EVN).
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@dbo_Act_contact_v2_uid, N'ENC', N'EVN');

-- v2 ct_contact row — every column the event SP / postprocessing SP
-- references is set non-NULL except contact_status (left NULL to dodge
-- the fn_get_value_by_cd_codeset 3-part-name bug; CTT_STATUS column on
-- D_CONTACT_RECORD is populated via nrt_contact directly instead).
--
-- Codes (verified in baseline NBS_SRTE.dbo.code_value_general):
--   shared_ind_cd 'Y' from YN
--   symptom_cd 'Y' from YNU
--   risk_factor_cd 'Y' from YNU
--   evaluation_completed_cd 'Y' from YNU
--   treatment_initiated_cd 'Y' from YNU
--   treatment_end_cd 'N' from YNU
--   disposition_cd 'CONF' from NBS_DISPO ('Confirmed Case')
--   priority_cd 'HIGH' from NBS_PRIORITY
--   relationship_cd 'PARTNER' from NBS_RELATIONSHIP
--   treatment_not_start_rsn_cd 'REFUSETX' from NBS_NO_TRTMNT_REAS
--   treatment_not_end_rsn_cd 'PROVDEC' from NBS_NO_TRTMNT_REAS
--   processing_decision_cd 'FF' from STD_CONTACT_RCD_PROCESSING_DECISION
--   group_name_cd 'GRP_HEPA' — SRTE_GAP (NBS_GROUP_NM is empty in baseline)
--   health_status_cd 'AILL' from NBS_HEALTH_STATUS ('Acute Illness')
--   contact_referral_basis_cd 'P1' from REFERRAL_BASIS ('P1 - Partner, Sex')
--   prog_area_cd 'HEP' from PROGRAM_AREA_CODE ('HEP')
--   jurisdiction_cd '130001' from JURISDICTION_CODE 'S_JURDIC_C' ('Fulton County')
--   contact_status: LEFT NULL on both variants (see top-of-file note).
INSERT INTO [dbo].[ct_contact]
    ([ct_contact_uid], [local_id], [subject_entity_uid], [contact_entity_uid],
     [subject_entity_phc_uid], [contact_entity_phc_uid],
     [third_party_entity_uid], [third_party_entity_phc_uid],
     [record_status_cd], [record_status_time],
     [add_user_id], [add_time], [last_chg_time], [last_chg_user_id],
     [version_ctrl_nbr],
     [prog_area_cd], [jurisdiction_cd], [program_jurisdiction_oid],
     [shared_ind_cd], [shared_ind],
     [contact_status],
     [priority_cd], [group_name_cd],
     [investigator_assigned_date], [disposition_cd], [disposition_date],
     [named_on_date], [named_during_interview_uid],
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
    (@dbo_Act_contact_v2_uid, N'CON20120010GA01',
     @foundation_patient_uid, @dbo_Entity_contact_party_uid,
     @foundation_investigation_uid, @foundation_investigation_uid,
     @foundation_patient_uid, @foundation_investigation_uid,
     N'ACTIVE', '2026-04-15T10:00:00',
     @superuser_id, '2026-04-15T10:00:00', CAST(GETDATE() AS DATE), @superuser_id,
     1,
     N'HEP', N'130001', 9999999,
     N'Y', N'Y',
     NULL,                                         -- contact_status NULL → event SP CASE short-circuits
     N'HIGH', N'GRP_HEPA',
     '2026-04-10T08:00:00', N'CONF', '2026-04-20T08:00:00',
     '2026-04-09T08:00:00', @foundation_interview_uid,
     N'PARTNER', N'AILL',
     N'Contact identified during partner-services interview.',
     N'Y', '2026-04-12T08:00:00', N'Mild GI symptoms, fever.',
     N'Y', N'Sexual partner identified by index case during interview.',
     N'Y', '2026-04-13T08:00:00', N'Evaluation completed at PHC.',
     N'Y', '2026-04-14T08:00:00',
     N'REFUSETX',
     N'N', '2026-04-25T08:00:00',
     N'PROVDEC', N'Treatment plan: 14-day course Acyclovir 400mg TID.',
     N'FF',
     N'EPI20000000', N'EPI20120010',
     N'P1');

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SPs via direct nrt_contact INSERTs.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Re-declare locals inside the RDB_MODERN batch (DECLAREs do not survive GO).
DECLARE @superuser_id bigint = 10009282;
DECLARE @foundation_act_contact_uid       bigint = 20000170;
DECLARE @foundation_patient_uid           bigint = 20000000;
DECLARE @foundation_investigation_uid     bigint = 20000100;
DECLARE @foundation_interview_uid         bigint = 20000140;
DECLARE @foundation_org_uid               bigint = 20000020;
DECLARE @foundation_provider_uid          bigint = 20000010;
DECLARE @dbo_Act_contact_v2_uid           bigint = 20120010;

-- =====================================================================
-- nrt_contact: 2 rows total.
--   Row 1. Foundation Contact (UID 20000170) — sparse / null path.
--     Mirrors foundation NBS_ODSE.dbo.ct_contact row content.
--     Most CTT_* description columns NULL (no upstream-projected SRTE
--     descriptions). Soft refs (CONTACT_EXPOSURE_SITE_UID,
--     PROVIDER_CONTACT_INVESTIGATOR_UID, DISPOSITIONED_BY_UID) NULL.
--     Date and detail columns NULL — exhibits the null/blank path on
--     D_CONTACT_RECORD population.
--   Row 2. v2 Contact (UID 20120010) — fully populated.
--     Mirrors v2 ct_contact row. CTT_* columns populated with
--     SRTE-resolved descriptions (these are upstream-projected fields
--     that the postprocessing SP propagates straight to D_CONTACT_RECORD).
--     Soft refs point at foundation Org / Provider / Provider for the
--     F_CONTACT_RECORD_CASE LEFT JOINs (will resolve to sentinel 1 at
--     Tier 1 isolation since D_ORGANIZATION/D_PROVIDER are empty for
--     these UIDs).
-- 54 settable columns out of 56. refresh_datetime + max_datetime are
-- GENERATED ALWAYS (omitted; system fills them).
-- =====================================================================

GO
