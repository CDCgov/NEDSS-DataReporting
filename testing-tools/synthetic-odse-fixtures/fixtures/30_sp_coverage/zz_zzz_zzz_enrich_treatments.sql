-- =====================================================================
-- zz_zzz_zzz_enrich_treatments.sql
-- Adds one condition-appropriate Treatment event per main investigation
-- (act TRMT/EVN + treatment row with the drug regimen in cd_desc_txt +
-- TreatmentToPHC act_relationship to the PHC). Fills the 'Treatment' event
-- section in the classic patient file and feeds nrt_treatment / the treatment
-- datamart. Mirrors the existing linked treatment 20100010 (no participation
-- needed; patient resolves via the investigation). Sorts last; idempotent.
-- UID block 22090000-22090099.
-- =====================================================================

USE [NBS_ODSE];
GO
DECLARE @su bigint = 10009282;

-- 10220 treatment for investigation 22001000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090000) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090000,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090000)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090000,'2026-04-15T09:00:00',@su,N'1',N'Isoniazid 300 mg + Rifampin 600 mg + Pyrazinamide 1500 mg + Ethambutol 1200 mg (RIPE), PO daily',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090000GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22001000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Standard 4-drug initial-phase anti-TB regimen.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090000 AND target_act_uid=22001000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090000,22001000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 10220 treatment for investigation 22050000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090001) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090001,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090001)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090001,'2026-04-15T09:00:00',@su,N'1',N'Isoniazid 300 mg + Rifampin 600 mg + Pyrazinamide 1500 mg + Ethambutol 1200 mg (RIPE), PO daily',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090001GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22050000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Standard 4-drug initial-phase anti-TB regimen.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090001 AND target_act_uid=22050000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090001,22050000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 502582 treatment for investigation 22047000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090002) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090002,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090002)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090002,'2026-04-15T09:00:00',@su,N'1',N'Isoniazid 300 mg + Rifapentine 900 mg PO weekly x 12 (3HP)',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090002GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22047000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Latent TB short-course regimen.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090002 AND target_act_uid=22047000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090002,22047000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 10311 treatment for investigation 22004000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090003) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090003,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090003)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090003,'2026-04-15T09:00:00',@su,N'1',N'Penicillin G Benzathine 2.4 million units IM x 1',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090003GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22004000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'First-line for primary syphilis.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090003 AND target_act_uid=22004000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090003,22004000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 11065 treatment for investigation 22003000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090004) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090004,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090004)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090004,'2026-04-15T09:00:00',@su,N'1',N'Nirmatrelvir/Ritonavir (Paxlovid) 300/100 mg PO BID x 5 days',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090004GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22003000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Oral antiviral for COVID-19.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090004 AND target_act_uid=22003000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090004,22003000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 10130 treatment for investigation 22049500
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090005) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090005,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090005)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090005,'2026-04-15T09:00:00',@su,N'1',N'Artemether-Lumefantrine 20/120 mg, 4 tablets PO BID x 3 days',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090005GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22049500),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'ACT for uncomplicated malaria.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090005 AND target_act_uid=22049500 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090005,22049500,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 10190 treatment for investigation 22006000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090006) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090006,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090006)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090006,'2026-04-15T09:00:00',@su,N'1',N'Azithromycin 500 mg PO day 1, then 250 mg PO daily x 4 days',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090006GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22006000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Macrolide for pertussis.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090006 AND target_act_uid=22006000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090006,22006000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 10190 treatment for investigation 22007000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090007) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090007,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090007)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090007,'2026-04-15T09:00:00',@su,N'1',N'Azithromycin 500 mg PO day 1, then 250 mg PO daily x 4 days',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090007GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22007000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Macrolide for pertussis.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090007 AND target_act_uid=22007000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090007,22007000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 10030 treatment for investigation 22002000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090008) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090008,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090008)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090008,'2026-04-15T09:00:00',@su,N'1',N'Acyclovir 800 mg PO 5x/day x 7 days',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090008GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22002000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Antiviral for varicella.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090008 AND target_act_uid=22002000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090008,22002000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 11801 treatment for investigation 22060200
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090009) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090009,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090009)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090009,'2026-04-15T09:00:00',@su,N'1',N'Tecovirimat (TPOXX) 600 mg PO BID x 14 days',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090009GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22060200),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Antiviral for mpox.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090009 AND target_act_uid=22060200 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090009,22060200,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 11717 treatment for investigation 22005000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090010) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090010,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090010)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090010,'2026-04-15T09:00:00',@su,N'1',N'Ceftriaxone 2 g IV q24h',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090010GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22005000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Empiric therapy for invasive pneumococcal disease.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090010 AND target_act_uid=22005000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090010,22005000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 10250 treatment for investigation 22060000
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090011) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090011,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090011)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090011,'2026-04-15T09:00:00',@su,N'1',N'Doxycycline 100 mg PO BID x 7 days',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090011GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22060000),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'First-line for spotted fever rickettsiosis.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090011 AND target_act_uid=22060000 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090011,22060000,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 12010 treatment for investigation 22060400
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090012) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090012,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090012)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090012,'2026-04-15T09:00:00',@su,N'1',N'Atovaquone 750 mg PO BID + Azithromycin 500 mg day 1 then 250 mg PO daily x 7-10 days',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090012GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22060400),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Standard for babesiosis.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090012 AND target_act_uid=22060400 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090012,22060400,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


-- 10270 treatment for investigation 22047500
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22090013) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22090013,N'TRMT',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.treatment WHERE treatment_uid=22090013)
  INSERT INTO dbo.treatment (treatment_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,class_cd,last_chg_time,last_chg_user_id,local_id,jurisdiction_cd,program_jurisdiction_oid,record_status_cd,record_status_time,shared_ind,status_cd,status_time,version_ctrl_nbr,activity_from_time,activity_to_time,txt)
  VALUES (22090013,'2026-04-15T09:00:00',@su,N'1',N'Albendazole 400 mg PO BID x 8-14 days',N'2.16.840.1.114222.4.5.1',N'NEDSS Base System',N'TRMT','2026-04-15T09:00:00',@su,N'TRT22090013GA01',N'130001',(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22047500),N'ACTIVE','2026-04-15T09:00:00',N'T',N'A','2026-04-15T09:00:00',1,'2026-04-15T09:00:00','2026-04-29T09:00:00',N'Anthelmintic for trichinellosis.');
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship WHERE source_act_uid=22090013 AND target_act_uid=22047500 AND type_cd='TreatmentToPHC')
  INSERT INTO dbo.act_relationship (source_act_uid,target_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time) VALUES (22090013,22047500,N'TreatmentToPHC',N'TRMT',N'CASE','2026-04-15T09:00:00',@su,'2026-04-15T09:00:00',@su,N'ACTIVE','2026-04-15T09:00:00',N'A','2026-04-15T09:00:00');


GO
