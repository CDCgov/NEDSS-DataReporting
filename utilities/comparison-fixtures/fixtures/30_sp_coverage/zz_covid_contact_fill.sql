-- =====================================================================
-- Tier 3 (NO-SHORTCUT) — ODSE Contact chain for covid_contact_datamart
-- =====================================================================
-- Authored 2026-06-03 (Round 4, agent R4-L). UID block 22051000-22051999.
--
-- TARGET: dbo.covid_contact_datamart (0/94, empty).
--
-- WHY IT WAS EMPTY
--   sp_covid_contact_datamart_postprocessing (routine 315) builds the
--   datamart from:
--       nrt_contact con
--         INNER JOIN nrt_investigation inv
--           ON con.SUBJECT_ENTITY_PHC_UID = inv.public_health_case_uid
--       WHERE inv.cd = '11065'                 -- COVID-19 condition
--         AND inv.public_health_case_uid IN (@phcid_list)
--   The COVID index investigation (PHC 22003000, cond 11065, patient_id
--   20000000) is already in $PHC_UIDS, but the only nrt_contact rows in
--   the baseline point at SUBJECT_ENTITY_PHC_UID = 20000100 (the Hep A
--   foundation PHC, cond 10110) — so the INNER JOIN + inv.cd='11065'
--   filter yields zero rows. No COVID-subject contact existed.
--
-- NO-SHORTCUT CHAIN (ODSE-only)
--   On branch aw/remove-nrt-shortcut, nrt_contact is NOT hand-authored;
--   it is reproduced from ODSE by the real pipeline:
--       NBS_ODSE.dbo.CT_CONTACT  (Debezium CDC source — confirmed in
--         containers/debezium/initialize/odse_main_connector.json
--         table.include.list: "...,dbo.CT_contact,...")
--     → topic nbs_CT_contact
--     → reporting-pipeline-service InvestigationService @KafkaListener
--       (application.yaml topics.nbs.ct-contact)
--     → ContactRepository.computeContact -> EXEC sp_contact_record_event
--       (routine 069; reads NBS_ODSE.dbo.CT_CONTACT, joins NBS_SRTE
--        code_value_general / program_area_code / jurisdiction_code)
--     → service writes nrt_contact + nrt_contact_answer.
--   Then Step 9 of merge_and_verify runs
--   sp_covid_contact_datamart_postprocessing @phcid_list=$PHC_UIDS
--   (22003000 is in the list) → covid_contact_datamart row.
--
--   Therefore this fixture authors ONE ODSE CT_CONTACT row whose
--   subject_entity_phc_uid = 22003000 (the COVID index PHC). Everything
--   downstream is produced by the real pipeline — no nrt_* INSERTs, no
--   EXEC sp_*.
--
-- VERIFIED LIVE (read-only) before authoring:
--   * Public_health_case 22003000 exists, cd=11065, jurisdiction 130001.
--   * nrt_investigation 22003000 has patient_id=20000000 (SubjOfPHC link).
--   * sp_contact_record_event @cc_uids='20120010' runs clean and projects
--     the full contact row (CTT_* SRTE descriptions resolve) — the
--     "BROKEN — skip" comment in merge_and_verify run_contact_chain is
--     stale; the event SP works on this baseline. contact_status is left
--     NULL (as the Tier-1 contact.sql v2 row does) so the event SP's
--     fn_get_value_by_cd_codeset CASE short-circuits and never fires the
--     3-part-name lookup.
--   * ct_contact.contact_entity_uid carries a UNIQUE constraint
--     (UQ_CT_contact_3101); 20000000/20120020 are already consumed, so a
--     NEW contact-party entity is authored in this UID block.
--
-- CODES reused from the proven Tier-1 v2 contact (validated against
--   NBS_SRTE.dbo.code_value_general): shared/symptom/risk/eval/trt 'Y'/'N'
--   (YN/YNU), disposition 'CONF' (NBS_DISPO), priority 'HIGH'
--   (NBS_PRIORITY), relationship 'PARTNER' (NBS_RELATIONSHIP), trt-reason
--   'REFUSETX'/'PROVDEC' (NBS_NO_TRTMNT_REAS), processing 'FF'
--   (STD_CONTACT_RCD_PROCESSING_DECISION), health 'AILL'
--   (NBS_HEALTH_STATUS), referral 'P1' (REFERRAL_BASIS), prog_area 'COV'
--   (COVID program area, matches PHC 22003000), jurisdiction '130001'.
--
-- EXPECTED COLUMNS POPULATED on covid_contact_datamart (1 row):
--   SRC_* (24) — from the COVID index investigation + index patient
--     (D_PATIENT 20000000 / nrt_investigation 22003000): patient name/
--     demographics, inv jurisdiction/status/case id/class, etc.
--   CR_* (contact-record) — CR_JURISDICTION_NM, CR_STATUS, CR_PRIORITY,
--     CR_DISPOSITION, CR_DISPO_DT, CR_INV_ASSIGNED_DT, CR_NAMED_ON_DT,
--     CR_RELATIONSHIP, CR_HEALTH_STATUS, CR_SYMP_IND, CR_SYMP_ONSET_DT,
--     CR_RISK_IND, CR_RISK_NOTES, CR_EVAL_COMPLETED, CR_EVAL_DT,
--     CR_EVAL_NOTES — from the authored ct_contact (via nrt_contact).
--   CTT_PATIENT_* / CTT_INV_* stay NULL: contact_entity_phc_uid is left
--     NULL (no contact-side investigation), so the SP's CTT branch reads
--     D_PATIENT on contact_entity_uid (22051000, which has no D_PATIENT
--     row) — acceptable; the index/contact-record columns are the bulk.
--
-- ORCH_TODO: none. PHC 22003000 is already in $PHC_UIDS in
--   scripts/merge_and_verify.sh, and Step 9 already runs
--   sp_covid_contact_datamart_postprocessing @phcid_list=$PHC_UIDS. The
--   real pipeline drains the new CT_CONTACT CDC event during the Tier-3
--   drain. No new PHC UID is needed (this is a contact OFF the existing
--   COVID PHC, not a new investigation).
--
--   NOTE (harness vs. pipeline): merge_and_verify's run_contact_chain()
--   currently EXECs only the two contact POST-processing SPs for the
--   hardcoded foundation UIDs and skips the event SP. That manual path
--   does NOT pick up this new contact — but it is redundant with the real
--   service, which DOES (CDC on dbo.CT_contact -> sp_contact_record_event
--   -> nrt_contact). If a future no-pipeline/manual-only run is used,
--   run_contact_chain would need '22051010' added to the event +
--   postprocessing UID lists. Under the full-pipeline merge this fixture
--   is sufficient as-is.
-- =====================================================================

USE [NBS_ODSE];
GO

-- ----- references (read-only) -----
DECLARE @superuser_id            bigint = 10009282;   -- conventional NBS superuser id
DECLARE @covid_phc_uid           bigint = 22003000;   -- COVID index investigation (cond 11065)
DECLARE @covid_index_patient_uid bigint = 20000000;   -- COVID index patient (SubjOfPHC of 22003000)

-- ----- UID allocations (block 22051000-22051999) -----
DECLARE @contact_party_uid       bigint = 22051000;   -- NEW contact-party entity (PSN) — UNIQUE on ct_contact.contact_entity_uid
DECLARE @ct_contact_uid          bigint = 22051010;   -- act + ct_contact for the COVID contact record

-- ---------------------------------------------------------------------
-- (1) Contact-party entity + person (the named contact of the COVID case).
--     class PSN / person cd 'PAT'. Satisfies the UNIQUE constraint on
--     ct_contact.contact_entity_uid (foundation patient is already used).
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
    (@contact_party_uid, N'PSN');

INSERT INTO [dbo].[person]
    ([person_uid], [add_time], [add_user_id], [cd],
     [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [first_nm], [last_nm], [version_ctrl_nbr],
     [electronic_ind], [person_parent_uid], [edx_ind])
VALUES
    (@contact_party_uid, '2026-04-15T10:00:00', @superuser_id, N'PAT',
     '2026-04-15T10:00:00', @superuser_id, N'PSN22051000GA01',
     N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00',
     N'COVID Contact', N'Person', 1,
     N'N', @contact_party_uid, N'Y');

-- ---------------------------------------------------------------------
-- (2) Contact Act (ENC/EVN) — same shape as the foundation/v2 contact act.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@ct_contact_uid, N'ENC', N'EVN');

-- ---------------------------------------------------------------------
-- (3) ct_contact row — subject is the COVID index investigation /
--     patient; this is the named contact off PHC 22003000.
--     contact_status LEFT NULL (event-SP fn short-circuit, see header).
--     contact_entity_phc_uid LEFT NULL (no contact-side investigation).
-- ---------------------------------------------------------------------
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
    (@ct_contact_uid, N'CON22051010GA01',
     @covid_index_patient_uid, @contact_party_uid,
     @covid_phc_uid, NULL,
     NULL, NULL,
     N'ACTIVE', '2026-04-15T10:00:00',
     @superuser_id, '2026-04-15T10:00:00', '2026-04-15T10:00:00', @superuser_id,
     1,
     N'COV', N'130001', 9999999,
     N'Y', N'Y',
     NULL,                                         -- contact_status NULL → event SP CASE short-circuits
     N'HIGH', N'GRP_HEPA',
     '2026-04-10T08:00:00', N'CONF', '2026-04-20T08:00:00',
     '2026-04-09T08:00:00', NULL,
     N'PARTNER', N'AILL',
     N'Household contact of confirmed COVID-19 case; identified during case interview.',
     N'Y', '2026-04-12T08:00:00', N'Mild cough and fever, no dyspnea.',
     N'Y', N'Shared household with index case during infectious period.',
     N'Y', '2026-04-13T08:00:00', N'Symptom screen + testing referral completed.',
     N'N', NULL,
     N'REFUSETX',
     N'N', NULL,
     N'PROVDEC', N'No treatment indicated for contact at this time.',
     N'FF',
     N'EPI22003000', N'EPI22051010',
     N'P1');

GO

PRINT 'zz_covid_contact_fill.sql applied: ODSE ct_contact 22051010 (subject_entity_phc_uid=22003000) authored; real pipeline -> nrt_contact -> covid_contact_datamart.';
GO
