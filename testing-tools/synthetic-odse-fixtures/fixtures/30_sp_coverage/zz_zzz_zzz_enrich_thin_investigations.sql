-- =====================================================================
-- zz_zzz_zzz_enrich_thin_investigations.sql
--
-- ABSOLUTE LAST-SORTING Tier-3 fixture (after the PHCs, the OID/date
-- normalization, and the patient redistribution).
--
-- Three investigations were authored as bare datamart-fill shells with no
-- clinical data, so they open as hollow investigations in the classic NBS UI:
--   22063100  COVID  (zz_covid_case_answer_gap.sql / zz_covid_contact_side.sql)
--   22071000  COVID  (zz_covid_case_answer_gap.sql)
--   22065000  Hep A  (zz_summary_report_case.sql)
--
-- Give each a small, condition-correct set of nbs_case_answer rows (the
-- investigation form data) plus one lab Observation linked to the PHC
-- (LabReport), so the detail page shows real symptoms/risk factors and a
-- result. ODSE-only (the classic UI reads ODSE directly); no nrt_* inserts.
--
-- The lab's patient subject and program_jurisdiction_oid are resolved from the
-- PHC's current SubjOfPHC patient and OID (this fixture sorts after the
-- redistribution + OID normalization), so the lab is attributed to whoever owns
-- the investigation and is visible under the same row-level-security context.
--
-- Question UIDs verified against the COVID full chain (symptoms, CSG 4150 YNU)
-- and the hepatitis answer-gap fixture (risk factors). Idempotent via guards.
-- Lab observation UIDs: 22063190 / 22071090 / 22065090 (free).
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @su bigint = 10009282;

-- Reusable column shapes are inlined per block (T-SQL has no row constructors
-- for this), but every block follows the same pattern:
--   case answers -> act -> observation -> obs_value_coded -> PATSBJ -> LabReport.

-- =====================================================================
-- COVID 22063100  (SARS-CoV-2 RNA detected)
-- =====================================================================
DECLARE @c1 bigint = 22063100, @c1lab bigint = 22063190;
DECLARE @c1pat bigint = (SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=@c1 AND type_cd='SubjOfPHC');
DECLARE @c1oid bigint = (SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=@c1);

IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@c1 AND nbs_question_uid=10001378)
INSERT INTO dbo.nbs_case_answer (act_uid,add_time,add_user_id,answer_txt,nbs_question_uid,nbs_question_version_ctrl_nbr,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,seq_nbr) VALUES
    (@c1,'2026-04-10',@su,N'Y',10001378,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-10',0), -- FEVER
    (@c1,'2026-04-10',@su,N'Y',10001379,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-10',0), -- CHILLS/RIGORS
    (@c1,'2026-04-10',@su,N'Y',10001380,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-10',0), -- FATIGUE/MALAISE
    (@c1,'2026-04-10',@su,N'Y',10001382,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-10',0), -- HEADACHE
    (@c1,'2026-04-10',@su,N'Y',10001383,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-10',0), -- MYALGIA
    (@c1,'2026-04-10',@su,N'N',10001390,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-10',0); -- ALT_MENTAL_STATUS

IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=@c1lab)
    INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (@c1lab,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=@c1lab)
BEGIN
    INSERT INTO dbo.observation
        (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,
         last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,
         record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,
         shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,
         activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
    VALUES
        (@c1lab,'2026-04-10T08:00:00',@su,N'94500-6',N'SARS-CoV-2 (COVID-19) RNA [Presence] by NAA',N'2.16.840.1.113883.6.1',N'LN',
         CAST(GETDATE() AS DATE),@su,N'OBS22063190GA01',N'Order_rslt',N'Order_rslt',N'LabReport',
         N'PROCESSED','2026-04-10T10:00:00',N'A','2026-04-10T10:00:00',@c1pat,
         N'T',1,N'130001',@c1oid,N'Y',
         '2026-04-10T08:00:00','2026-04-09T18:00:00',N'NASOPH',N'Nasopharyngeal swab');
    INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name)
        VALUES (@c1lab,N'260373001',N'2.16.840.1.113883.6.96',N'SCT',N'Detected');
    INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt)
        VALUES (@c1lab,@c1pat,N'PATSBJ',N'OBS',N'PSN','2026-04-10',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-10',N'A','2026-04-10',N'Patient Subject');
    INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time)
        VALUES (@c1,@c1lab,N'LabReport',N'OBS',N'CASE','2026-04-10',@su,'2026-04-10',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-10',1,N'A','2026-04-10');
END
GO

-- =====================================================================
-- COVID 22071000  (SARS-CoV-2 RNA detected)
-- =====================================================================
DECLARE @su bigint = 10009282;
DECLARE @c2 bigint = 22071000, @c2lab bigint = 22071090;
DECLARE @c2pat bigint = (SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=@c2 AND type_cd='SubjOfPHC');
DECLARE @c2oid bigint = (SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=@c2);

IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@c2 AND nbs_question_uid=10001378)
INSERT INTO dbo.nbs_case_answer (act_uid,add_time,add_user_id,answer_txt,nbs_question_uid,nbs_question_version_ctrl_nbr,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,seq_nbr) VALUES
    (@c2,'2026-04-12',@su,N'Y',10001378,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-12',0), -- FEVER
    (@c2,'2026-04-12',@su,N'N',10001379,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-12',0), -- CHILLS/RIGORS
    (@c2,'2026-04-12',@su,N'Y',10001380,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-12',0), -- FATIGUE/MALAISE
    (@c2,'2026-04-12',@su,N'Y',10001382,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-12',0), -- HEADACHE
    (@c2,'2026-04-12',@su,N'N',10001383,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-12',0); -- MYALGIA

IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=@c2lab)
    INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (@c2lab,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=@c2lab)
BEGIN
    INSERT INTO dbo.observation
        (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,
         last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,
         record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,
         shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,
         activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
    VALUES
        (@c2lab,'2026-04-12T08:00:00',@su,N'94500-6',N'SARS-CoV-2 (COVID-19) RNA [Presence] by NAA',N'2.16.840.1.113883.6.1',N'LN',
         CAST(GETDATE() AS DATE),@su,N'OBS22071090GA01',N'Order_rslt',N'Order_rslt',N'LabReport',
         N'PROCESSED','2026-04-12T10:00:00',N'A','2026-04-12T10:00:00',@c2pat,
         N'T',1,N'130001',@c2oid,N'Y',
         '2026-04-12T08:00:00','2026-04-11T18:00:00',N'NASOPH',N'Nasopharyngeal swab');
    INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name)
        VALUES (@c2lab,N'260373001',N'2.16.840.1.113883.6.96',N'SCT',N'Detected');
    INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt)
        VALUES (@c2lab,@c2pat,N'PATSBJ',N'OBS',N'PSN','2026-04-12',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-12',N'A','2026-04-12',N'Patient Subject');
    INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time)
        VALUES (@c2,@c2lab,N'LabReport',N'OBS',N'CASE','2026-04-12',@su,'2026-04-12',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-12',1,N'A','2026-04-12');
END
GO

-- =====================================================================
-- Hepatitis A 22065000  (HAV IgM reactive)
-- =====================================================================
DECLARE @su bigint = 10009282;
DECLARE @h1 bigint = 22065000, @h1lab bigint = 22065090;
DECLARE @h1pat bigint = (SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=@h1 AND type_cd='SubjOfPHC');
DECLARE @h1oid bigint = (SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=@h1);

IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE act_uid=@h1 AND nbs_question_uid=10001141)
INSERT INTO dbo.nbs_case_answer (act_uid,add_time,add_user_id,answer_txt,nbs_question_uid,nbs_question_version_ctrl_nbr,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,seq_nbr) VALUES
    (@h1,'2026-04-11',@su,N'Y',10001141,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-11',0), -- HepContactEver
    (@h1,'2026-04-11',@su,N'N',10001142,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-11',0), -- BloodWorkerEver
    (@h1,'2026-04-11',@su,N'N',10001136,1,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-11',0); -- ClottingPrior87

IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=@h1lab)
    INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (@h1lab,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=@h1lab)
BEGIN
    INSERT INTO dbo.observation
        (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,
         last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,
         record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,
         shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,
         activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
    VALUES
        (@h1lab,'2026-04-11T08:00:00',@su,N'80375-5',N'Hepatitis A virus IgM Ab',N'2.16.840.1.113883.6.1',N'LN',
         CAST(GETDATE() AS DATE),@su,N'OBS22065090GA01',N'Order_rslt',N'Order_rslt',N'LabReport',
         N'PROCESSED','2026-04-11T10:30:00',N'A','2026-04-11T10:30:00',@h1pat,
         N'T',1,N'130001',@h1oid,N'Y',
         '2026-04-11T08:00:00','2026-04-10T18:00:00',N'SER',N'Serum');
    INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name)
        VALUES (@h1lab,N'10828004',N'2.16.840.1.113883.6.96',N'SCT',N'Positive');
    INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt)
        VALUES (@h1lab,@h1pat,N'PATSBJ',N'OBS',N'PSN','2026-04-11',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-11',N'A','2026-04-11',N'Patient Subject');
    INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time)
        VALUES (@h1,@h1lab,N'LabReport',N'OBS',N'CASE','2026-04-11',@su,'2026-04-11',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-11',1,N'A','2026-04-11');
END
GO
