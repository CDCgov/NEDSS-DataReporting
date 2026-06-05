-- =====================================================================
-- zz_tb_fact_chain.sql  (Round 4, no-shortcut, ODSE-only)
-- =====================================================================
-- TARGET: make the TB fact F_TB_PAM populate so its downstream datamarts
--         tb_datamart (0/318) and tb_hiv_datamart (0/322) populate
--         through the REAL pipeline.
--
-- ROOT CAUSE (verified against SP source on 2026-06-03)
--   tb_datamart / tb_hiv_datamart are built FROM dbo.F_TB_PAM
--   (routine 255-sp_tb_datamart_postprocessing). F_TB_PAM was EMPTY even
--   though the D_TB_PAM dimension (155/166 cols) populates.
--
--   In routine 206-sp_f_tb_pam_postprocessing (the fact SP) step 1
--   (lines 57-73) derives the fact's join key as:
--       CAST(I.nac_page_case_uid AS BIGINT) AS TB_PAM_UID
--       FROM dbo.nrt_investigation I
--       WHERE I.investigation_form_cd='INV_FORM_RVCT'
--         AND I.patient_id IS NOT NULL
--       GROUP BY I.nac_page_case_uid, I.nac_last_chg_time
--   Every downstream temp table (#PAT_keystore, #D_MOVE_STATE,
--   #D_DISEASE_SITE, ... and the final INSERT at lines 615-720) INNER
--   JOINs on TB_PAM_UID. If nac_page_case_uid is NULL the key is NULL,
--   NULL never equals anything, and the fact inserts ZERO rows.
--
--   Live check (RDB_MODERN.dbo.nrt_investigation, PHC 22001000):
--       nac_page_case_uid = NULL   <-- the blocker
--       patient_id        = 20000000 (already linked; not the problem)
--       investigation_form_cd = 'INV_FORM_RVCT' (matches; not the problem)
--   D_TB_PAM has TB_PAM_UID=22001000 because routine 147 derives ITS key
--   from nrt_page_case_answer.ACT_UID (a DIFFERENT source) -- which is why
--   the dim populates but the fact does not.
--
--   nac_page_case_uid is set ONLY by routine 056-sp_investigation_event
--   (lines 910-935): a LEFT JOIN to a subquery over
--   NBS_ODSE.dbo.nbs_act_entity grouped by act_uid, where
--   nac_page_case_uid = act_uid. With ZERO nbs_act_entity rows for the
--   PHC the LEFT JOIN yields NULL. Our TB investigation 22001000 has NO
--   nbs_act_entity rows (confirmed: COUNT=0).
--
--   The two foundation investigations that DO get a non-NULL
--   nac_page_case_uid (20000100, 20050010) each carry exactly three
--   nbs_act_entity rows: PerAsReporterOfPHC, OrgAsReporterOfPHC,
--   HospOfADT (the same three type_cds routine 056 lines 913-932 pull
--   into person_as_reporter_uid / org_as_reporter_uid / hospital_uid).
--
-- FIX (ODSE-only, additive)
--   Author the same three nbs_act_entity rows for the TB PHC 22001000,
--   pointing at the foundation Organization (20000020) and Provider
--   (20000010) entities -- both of which already resolve to real
--   D_ORGANIZATION / D_PROVIDER keys, so the fact gets REAL org/provider
--   dimension keys (not just the COALESCE(...,1) sentinel). Then bump
--   public_health_case.last_chg_time so the CDC->service path re-runs
--   sp_investigation_event for 22001000 AFTER the entity rows exist,
--   populating nac_page_case_uid=22001000 in nrt_investigation. On the
--   next Step-9 rebuild sp_f_tb_pam_postprocessing then finds a non-NULL
--   TB_PAM_UID and the fact (and both datamarts) populate.
--
-- WHY THIS IS THE COMPLETE SET OF FACT PREREQUISITES
--   Re-reading routine 206 end to end, the ONLY hard gate that was
--   unsatisfied is nac_page_case_uid (every other join is either an
--   already-satisfied dim -- #D_MOVE_STATE..#D_OUT_OF_CNTRY all already
--   have rows for TB_PAM_UID=22001000, verified live -- or a
--   LEFT JOIN ... COALESCE(...,1) keystore that cannot drop the row).
--   D_PATIENT (PERSON_UID=20000000) already exists. INVESTIGATION and
--   nrt_investigation rows for 22001000 already exist. So the single
--   missing ODSE input is nbs_act_entity.
--
-- WHICH SP(s) PICK THIS UP
--   056-sp_investigation_event           (service, on CDC re-capture):
--       reads nbs_act_entity -> sets nrt_investigation.nac_page_case_uid
--   206-sp_f_tb_pam_postprocessing        (Step 9): F_TB_PAM populates
--   255-sp_tb_datamart_postprocessing     (Step 9): tb_datamart +
--   tb_hiv_datamart populate (both built FROM F_TB_PAM).
--
-- UID BLOCK (this fixture): 22040000-22040999
--   22040000  nbs_act_entity_uid  OrgAsReporterOfPHC  -> org 20000020
--   22040001  nbs_act_entity_uid  HospOfADT           -> org 20000020
--   22040002  nbs_act_entity_uid  PerAsReporterOfPHC  -> person 20000010
--
-- REUSED UIDs (read-only, already in DB):
--   22001000  TB PHC (act_uid + public_health_case_uid) -- in PHC_UIDS,
--             so Step-9 SPs (206, 255) rebuild it automatically.
--   20000020  foundation Organization entity (D_ORGANIZATION key exists)
--   20000010  foundation Person/Provider entity (D_PROVIDER key exists)
--   10009282  superuser id
--
-- IDEMPOTENT: guarded by NOT EXISTS on nbs_act_entity_uid 22040000.
-- ADDITIVE: inserts new nbs_act_entity rows + bumps the TB PHC's
--   last_chg_time only. No UPDATE of any shared dim (D_PATIENT /
--   F_*_PAM / USER_PROFILE). No nrt_* INSERT. No EXEC sp_*. No
--   liquibase / seed / SRTE edit.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;
DECLARE @tb_phc_uid   bigint = 22001000;   -- act_uid of the TB PHC
DECLARE @org_uid      bigint = 20000020;   -- foundation Organization entity
DECLARE @person_uid   bigint = 20000010;   -- foundation Person/Provider entity

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity] WHERE nbs_act_entity_uid = 22040000)
BEGIN
    -- nbs_act_entity_uid is an IDENTITY column; pin our reserved UIDs.
    SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;

    INSERT INTO [dbo].[nbs_act_entity]
        ([nbs_act_entity_uid], [act_uid], [add_time], [add_user_id],
         [entity_uid], [entity_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [type_cd])
    VALUES
        -- OrgAsReporterOfPHC -> org_as_reporter_uid (routine 056 line 932)
        (22040000, @tb_phc_uid, '2026-04-01T00:00:00', @superuser_id,
         @org_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         N'ACTIVE', '2026-04-01T00:00:00', N'OrgAsReporterOfPHC'),
        -- HospOfADT -> hospital_uid (routine 056 line 914)
        (22040001, @tb_phc_uid, '2026-04-01T00:00:00', @superuser_id,
         @org_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         N'ACTIVE', '2026-04-01T00:00:00', N'HospOfADT'),
        -- PerAsReporterOfPHC -> person_as_reporter_uid (routine 056 line 913)
        (22040002, @tb_phc_uid, '2026-04-01T00:00:00', @superuser_id,
         @person_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         N'ACTIVE', '2026-04-01T00:00:00', N'PerAsReporterOfPHC');

    SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
END
GO

-- ---------------------------------------------------------------------
-- Re-trigger CDC -> service so sp_investigation_event re-runs for the TB
-- PHC AFTER the nbs_act_entity rows exist, populating
-- nrt_investigation.nac_page_case_uid=22001000. public_health_case is
-- the CDC-tracked table (capture instance dbo_Public_health_case) that
-- the reporting-pipeline-service keys investigation reprocessing on; the
-- same last_chg_time bump pattern used by
-- zz_page_answers_datamart_routing.sql.
-- ---------------------------------------------------------------------
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid = 22001000;
GO
