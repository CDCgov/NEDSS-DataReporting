USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Treatment fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- ARCHITECTURAL NOTE
--   Treatment is a small, simple subject:
--     - Event SP: dbo.sp_treatment_event (param: @treatment_uids)
--       File: routines/070-sp_treatment_event-001.sql
--       INNER JOINs dbo.treatment + dbo.Treatment_administered (so both
--       must exist for the SP to surface a row); LEFT JOINs participation
--       (SubjOfTrmt / ProviderOfTrmt / ReporterOfTrmt) and act_relationship
--       (TreatmentToPHC, TreatmentToMorb). Cross-subject participation /
--       act_relationship rows are TIER 2 territory, so the event-SP joins
--       resolve to NULL at Tier 1 isolation. The event SP simply emits a
--       sparse JSON projection — its INNER JOINs do not block the
--       postprocessing SP.
--     - Postprocessing SP: dbo.sp_nrt_treatment_postprocessing
--       (param: @treatment_uids, same name as event SP)
--       File: routines/047-sp_nrt_treatment_postprocessing-001.sql
--       Reads from dbo.nrt_treatment (which we hand-author) and joins to
--       D_PATIENT / D_ORGANIZATION / D_PROVIDER / MORBIDITY_REPORT /
--       INVESTIGATION / RDB_DATE / dbo.condition / LDF_GROUP for
--       TREATMENT_EVENT FK key resolution. ALL eight cross-subject FK
--       columns on TREATMENT_EVENT are COALESCEd to sentinel 1 (lines
--       184-193 of the SP), so Tier 1 isolation populates TREATMENT_EVENT
--       with sentinel 1 keys for cross-subject FKs and a real
--       TREATMENT_KEY for the dim FK.
--   No FK constraints exist on either RDB_MODERN.dbo.TREATMENT or
--   RDB_MODERN.dbo.TREATMENT_EVENT — verified via INFORMATION_SCHEMA.
--   Therefore Tier 1 isolation is expected to populate 16/16 TREATMENT
--   columns and 11/11 TREATMENT_EVENT columns cleanly.
--
-- WHAT THIS FIXTURE DOES
--   1. Foundation Treatment enrichment:
--        - Foundation already has the dbo.treatment row at UID 20000150
--          (sparse — most clinical columns NULL; see coverage_foundation.md
--          "Columns deliberately skipped" — treatment row).
--        - Add ONE NEW dbo.treatment_administered row keyed on 20000150
--          (foundation has none). All clinical columns (drug, dose,
--          frequency, duration, route) NULL on this row to exhibit the
--          SP's null-propagation path on every TREATMENT-dim column the
--          postprocessing SP reads from nrt_treatment.
--        - Add ONE act_id row for foundation Treatment local-id.
--        - Hand-author one nrt_treatment row keyed on treatment_uid
--          20000150, with all detail columns NULL (foundation
--          null-propagation variant).
--
--   2. v2 Treatment: a fully-attributed alternative within block
--      20100000-20109999.
--        - dbo.treatment row at 20100010 with all (postprocessing-
--          referenced) columns set.
--        - dbo.treatment_administered row at 20100010 with drug, dose,
--          frequency, duration, route — every column the SP reads.
--        - dbo.act row at 20100010 (TRMT/EVN).
--        - dbo.act_id row for v2 Treatment local-id.
--        - cd='1' (TREAT_COMPOSITE) — Acyclovir composite per
--          nrt_srte_Treatment_code seed; treatment_drug='500' (TREAT_DRUG
--          Acyclovir); route_cd='C0205531' (TREAT_ROUTE PO);
--          dose_qty_unit_cd='mg' (TREAT_DOSE_UNIT); interval_cd='TID'
--          (TREAT_FREQ_UNIT Three times a day); effective_duration_unit_cd
--          ='D' (TREAT_DUR_UNIT Days).
--        - Hand-author the nrt_treatment row keyed on 20100010 with:
--            * patient_treatment_uid=20000000 (foundation Patient)
--            * provider_uid=20000010 (foundation Provider)
--            * organization_uid=20000020 (foundation Organization)
--            * morbidity_uid=20000130 (foundation Morbidity Order — soft ref)
--            * associated_phc_uids='20000100' (foundation Investigation)
--            * cd, treatment_name, treatment_drug, drug_name, dose_qty,
--              dose_qty_unit, frequency, duration, duration_unit, route,
--              comments, treatment_oid, shared_ind set
--            * treatment_date populated to drive RDB_DATE join (will
--              COALESCE-to-1 since RDB_DATE is empty in baseline)
--            * record_status_cd='ACTIVE' (note: the foundation
--              treatment.record_status_cd is 'ACTIVE' too; the SP applies
--              dbo.fn_get_record_status only in event-SP logic, not in
--              postprocessing — postprocessing SP just passes the value
--              through).
--
--   3. CUSTOM_TREATMENT branch coverage:
--      The postprocessing SP at line 88:
--        CASE WHEN nrt.cd = 'OTH' THEN nrt.treatment_name ELSE NULL END AS CUSTOM_TREATMENT
--      The v2 treatment uses cd='1' (a real TREAT_COMPOSITE code), so v2's
--      CUSTOM_TREATMENT will be NULL (the ELSE branch). The foundation
--      row's nrt_treatment cd='TRMT100' (per foundation.sql's
--      treatment.cd) — also not 'OTH', so foundation's CUSTOM_TREATMENT
--      also NULL. Both variants exhibit the ELSE-NULL path. The 'OTH'
--      branch is not exercised by Tier 1 isolation; documented as
--      OUT_OF_SCOPE_BRANCH in coverage report (Tier 3 candidate).
--
--   4. Synthetic staging rows in RDB_MODERN.dbo.nrt_treatment:
--        - 2 rows: foundation Treatment (UID 20000150) + v2 Treatment
--          (UID 20100010)
--      27 settable columns (29 total minus refresh_datetime/max_datetime
--      which are GENERATED ALWAYS / ROW START / ROW END).
--
--   5. Does NOT author cross-subject act_relationship (TreatmentToPHC,
--      TreatmentToMorb) or participation (SubjOfTrmt, ProviderOfTrmt,
--      ReporterOfTrmt) rows — these are Tier 2.
--
--   6. Does NOT hand-author dbo.nrt_treatment_key — postprocessing SP
--      allocates surrogate keys via IDENTITY at lines 414-418.
--
-- UID block (Treatment Tier 1): 20100000-20109999.
-- Foundation dependencies (read-only):
--   @dbo_Act_treatment_uid       20000150  (act / treatment foundation)
--   @dbo_Entity_patient_uid      20000000  (referenced via nrt_treatment.patient_treatment_uid)
--   @dbo_Entity_provider_uid     20000010  (referenced via nrt_treatment.provider_uid)
--   @dbo_Entity_organization_uid 20000020  (referenced via nrt_treatment.organization_uid)
--   @dbo_Act_morbidity_uid       20000130  (referenced via nrt_treatment.morbidity_uid soft ref)
--   @dbo_Act_investigation_uid   20000100  (referenced via nrt_treatment.associated_phc_uids CSV soft ref)
-- =====================================================================

-- ----- Sentinel reference -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_act_treatment_uid bigint = 20000150;  -- foundation Treatment Act / treatment
DECLARE @foundation_patient_uid       bigint = 20000000;  -- foundation Patient
DECLARE @foundation_provider_uid      bigint = 20000010;  -- foundation Provider
DECLARE @foundation_org_uid           bigint = 20000020;  -- foundation Organization
DECLARE @foundation_morb_uid          bigint = 20000130;  -- foundation Morbidity Order observation
DECLARE @foundation_investigation_uid bigint = 20000100;  -- foundation Investigation PHC

-- =====================================================================
-- UID allocations (Treatment Tier 1: 20100000-20109999)
-- =====================================================================

DECLARE @dbo_Act_treatment_v2_uid     bigint = 20100010;  -- v2 Treatment act / treatment / treatment_administered (cd='1', a real TREAT_COMPOSITE code)
DECLARE @dbo_Act_treatment_v3_uid     bigint = 20100020;  -- v3 Treatment with cd='OTH' to exercise CUSTOM_TREATMENT branch

-- =====================================================================
-- ODSE rows — additive enrichments and v2 variant.
-- =====================================================================

-- =====================================================================
-- Foundation Treatment enrichment: act_id (local id) + treatment_administered.
-- The foundation treatment 20000150 has neither row. Adding both:
--   - act_id: gives the event SP's act-id JSON branch a local-id row
--   - treatment_administered: REQUIRED for the event SP's INNER JOIN
--     (line 65) to surface the foundation row. All clinical columns
--     left NULL on this row — exhibits the null-propagation path on
--     TREATMENT-dim columns the SP reads from nrt_treatment.
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@foundation_act_treatment_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'TRT20000150GA01', N'TRMT_LOCAL_ID',
     N'Local Treatment Identifier', N'A', '2026-04-01T00:00:00');

-- Foundation treatment_administered row — sparse, drives null-propagation path.
INSERT INTO [dbo].[treatment_administered]
    ([treatment_uid], [treatment_administered_seq], [status_cd], [status_time])
VALUES
    (@foundation_act_treatment_uid, 1, N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- v2 Treatment: fully-attributed alternative.
-- =====================================================================

-- v2 + v3 act parent rows.
-- act.class_cd 'TRMT' from SRTE ACT_CLS; mood_cd 'EVN'.
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@dbo_Act_treatment_v2_uid, N'TRMT', N'EVN'),
    (@dbo_Act_treatment_v3_uid, N'TRMT', N'EVN');

-- v2 treatment row — every column the postprocessing SP reads from
-- nrt_treatment is set on the corresponding nrt_treatment column
-- below; this ODSE row is the canonical source row for shape
-- consistency with the event SP's projection.
INSERT INTO [dbo].[treatment]
    ([treatment_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [cd_system_cd], [cd_system_desc_txt], [class_cd],
     [last_chg_time], [last_chg_user_id], [local_id],
     [prog_area_cd], [jurisdiction_cd], [program_jurisdiction_oid],
     [record_status_cd], [record_status_time],
     [shared_ind], [status_cd], [status_time],
     [version_ctrl_nbr], [activity_from_time], [activity_to_time],
     [txt])
VALUES
    (@dbo_Act_treatment_v2_uid, '2026-04-01T00:00:00', @superuser_id,
     N'1', N'Acyclovir, 200 mg, PO, 5ID, x 5 days',
     N'2.16.840.1.114222.4.5.1', N'NEDSS Base System', N'TRMT',
     CAST(GETDATE() AS DATE), @superuser_id, N'TRT20100010GA01',
     N'STD', N'130001', 20100010,
     N'ACTIVE', '2026-04-01T00:00:00',
     N'T', N'A', '2026-04-01T00:00:00',
     1, '2026-04-02T08:00:00', '2026-04-06T20:00:00',
     N'Tier 1 Treatment v2 — clinician comments on therapy course.');

-- v2 treatment_administered row — drives event SP rx2 detail joins.
INSERT INTO [dbo].[treatment_administered]
    ([treatment_uid], [treatment_administered_seq],
     [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [dose_qty], [dose_qty_unit_cd],
     [effective_duration_amt], [effective_duration_unit_cd],
     [effective_from_time], [effective_to_time],
     [interval_cd], [interval_desc_txt],
     [route_cd], [route_desc_txt],
     [status_cd], [status_time])
VALUES
    (@dbo_Act_treatment_v2_uid, 1,
     N'500', N'Acyclovir', N'TREAT_DRUG', N'NEDSS Treatment Drug',
     N'200', N'mg',
     N'5', N'D',
     '2026-04-02T08:00:00', '2026-04-06T20:00:00',
     N'TID', N'Three times a day',
     N'C0205531', N'PO',
     N'A', '2026-04-01T00:00:00');

-- v2 act_id row — local id assignment.
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@dbo_Act_treatment_v2_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'TRT20100010GA01', N'TRMT_LOCAL_ID',
     N'Local Treatment Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- v3 Treatment: cd='OTH' free-text variant.
--   Drives the postprocessing SP's CUSTOM_TREATMENT CASE branch
--   (line 88: WHEN nrt.cd = 'OTH' THEN nrt.treatment_name).
--   No 'OTH' code needs to exist in NBS_SRTE — the SP's CASE compares
--   the literal string 'OTH' from nrt_treatment.cd. v1/v2/foundation
--   exhibit the ELSE-NULL branch; v3 exhibits the THEN branch with
--   the treatment_name surfaced as CUSTOM_TREATMENT.
-- =====================================================================
INSERT INTO [dbo].[treatment]
    ([treatment_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [class_cd],
     [last_chg_time], [last_chg_user_id], [local_id],
     [prog_area_cd], [jurisdiction_cd],
     [record_status_cd], [record_status_time],
     [shared_ind], [status_cd], [status_time],
     [version_ctrl_nbr])
VALUES
    (@dbo_Act_treatment_v3_uid, '2026-04-01T00:00:00', @superuser_id,
     N'OTH', N'Other / free-text treatment',
     N'TRMT',
     CAST(GETDATE() AS DATE), @superuser_id, N'TRT20100020GA01',
     N'STD', N'130001',
     N'ACTIVE', '2026-04-01T00:00:00',
     N'F', N'A', '2026-04-01T00:00:00',
     1);

INSERT INTO [dbo].[treatment_administered]
    ([treatment_uid], [treatment_administered_seq],
     [status_cd], [status_time])
VALUES
    (@dbo_Act_treatment_v3_uid, 1,
     N'A', '2026-04-01T00:00:00');

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SP via direct nrt_treatment INSERTs.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Re-declare locals inside the RDB_MODERN batch (DECLAREs do not survive GO).
DECLARE @superuser_id bigint = 10009282;
DECLARE @foundation_act_treatment_uid bigint = 20000150;
DECLARE @foundation_patient_uid       bigint = 20000000;
DECLARE @foundation_provider_uid      bigint = 20000010;
DECLARE @foundation_org_uid           bigint = 20000020;
DECLARE @foundation_morb_uid          bigint = 20000130;
DECLARE @foundation_investigation_uid bigint = 20000100;
DECLARE @dbo_Act_treatment_v2_uid     bigint = 20100010;
DECLARE @dbo_Act_treatment_v3_uid     bigint = 20100020;

-- =====================================================================
-- nrt_treatment: 2 rows total.
--   - foundation Treatment (UID 20000150) — sparse / null-propagation
--   - v2 Treatment (UID 20100010) — fully populated
-- 27 settable columns. refresh_datetime + max_datetime are GENERATED
-- ALWAYS (omitted; system fills them).
-- =====================================================================

GO
