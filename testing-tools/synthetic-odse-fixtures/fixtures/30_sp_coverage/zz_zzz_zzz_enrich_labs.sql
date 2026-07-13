-- =====================================================================
-- zz_zzz_zzz_enrich_labs.sql
-- Adds one condition-appropriate confirmatory lab (Order_rslt observation +
-- coded result + LabReport link to the PHC) per investigation, for conditions
-- with a well-known confirmatory test. Fills the Lab Reports relation and feeds
-- the lab dimensions. ODSE-only; patient + OID resolved from the PHC. Sorts
-- last; idempotent. UID block 22091000-22091099.
-- =====================================================================

USE [NBS_ODSE];
GO
DECLARE @su bigint = 10009282;

-- 11065 confirmatory lab for investigation 22003000
DECLARE @p22091000 bigint=(SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=22003000 AND type_cd='SubjOfPHC');
DECLARE @o22091000 bigint=(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22003000);
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22091000) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22091000,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=22091000)
BEGIN
  INSERT INTO dbo.observation (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
  VALUES (22091000,'2026-04-13T09:00:00',@su,N'94500-6',N'SARS-CoV-2 (COVID-19) RNA [Presence] by NAA',N'2.16.840.1.113883.6.1',N'LN',CAST(GETDATE() AS DATE),@su,N'OBS22091000GA01',N'Order_rslt',N'Order_rslt',N'LabReport',N'PROCESSED','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',@p22091000,N'T',1,N'130001',@o22091000,N'Y','2026-04-13T09:00:00','2026-04-12T18:00:00',N'NASOPH',N'Nasopharyngeal swab');
  INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name) VALUES (22091000,N'260373001',N'2.16.840.1.113883.6.96',N'SCT',N'Detected');
  INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt) VALUES (22091000,@p22091000,N'PATSBJ',N'OBS',N'PSN','2026-04-13T09:00:00',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',N'Patient Subject');
  INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time) VALUES (22003000,22091000,N'LabReport',N'OBS',N'CASE','2026-04-13T09:00:00',@su,'2026-04-13T09:00:00',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',1,N'A','2026-04-13T09:00:00');
END

-- 10311 confirmatory lab for investigation 22004000
DECLARE @p22091001 bigint=(SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=22004000 AND type_cd='SubjOfPHC');
DECLARE @o22091001 bigint=(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22004000);
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22091001) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22091001,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=22091001)
BEGIN
  INSERT INTO dbo.observation (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
  VALUES (22091001,'2026-04-13T09:00:00',@su,N'20507-0',N'Reagin Ab [Presence] in Serum by RPR',N'2.16.840.1.113883.6.1',N'LN',CAST(GETDATE() AS DATE),@su,N'OBS22091001GA01',N'Order_rslt',N'Order_rslt',N'LabReport',N'PROCESSED','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',@p22091001,N'T',1,N'130001',@o22091001,N'Y','2026-04-13T09:00:00','2026-04-12T18:00:00',N'SER',N'Serum');
  INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name) VALUES (22091001,N'11214006',N'2.16.840.1.113883.6.96',N'SCT',N'Reactive');
  INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt) VALUES (22091001,@p22091001,N'PATSBJ',N'OBS',N'PSN','2026-04-13T09:00:00',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',N'Patient Subject');
  INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time) VALUES (22004000,22091001,N'LabReport',N'OBS',N'CASE','2026-04-13T09:00:00',@su,'2026-04-13T09:00:00',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',1,N'A','2026-04-13T09:00:00');
END

-- 10110 confirmatory lab for investigation 22008500
DECLARE @p22091002 bigint=(SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=22008500 AND type_cd='SubjOfPHC');
DECLARE @o22091002 bigint=(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22008500);
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22091002) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22091002,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=22091002)
BEGIN
  INSERT INTO dbo.observation (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
  VALUES (22091002,'2026-04-13T09:00:00',@su,N'13950-1',N'Hepatitis A virus IgM Ab [Presence] in Serum',N'2.16.840.1.113883.6.1',N'LN',CAST(GETDATE() AS DATE),@su,N'OBS22091002GA01',N'Order_rslt',N'Order_rslt',N'LabReport',N'PROCESSED','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',@p22091002,N'T',1,N'130001',@o22091002,N'Y','2026-04-13T09:00:00','2026-04-12T18:00:00',N'SER',N'Serum');
  INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name) VALUES (22091002,N'11214006',N'2.16.840.1.113883.6.96',N'SCT',N'Reactive');
  INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt) VALUES (22091002,@p22091002,N'PATSBJ',N'OBS',N'PSN','2026-04-13T09:00:00',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',N'Patient Subject');
  INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time) VALUES (22008500,22091002,N'LabReport',N'OBS',N'CASE','2026-04-13T09:00:00',@su,'2026-04-13T09:00:00',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',1,N'A','2026-04-13T09:00:00');
END

-- 10100 confirmatory lab for investigation 22046000
DECLARE @p22091003 bigint=(SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=22046000 AND type_cd='SubjOfPHC');
DECLARE @o22091003 bigint=(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22046000);
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22091003) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22091003,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=22091003)
BEGIN
  INSERT INTO dbo.observation (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
  VALUES (22091003,'2026-04-13T09:00:00',@su,N'5195-3',N'Hepatitis B virus surface Ag [Presence] in Serum',N'2.16.840.1.113883.6.1',N'LN',CAST(GETDATE() AS DATE),@su,N'OBS22091003GA01',N'Order_rslt',N'Order_rslt',N'LabReport',N'PROCESSED','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',@p22091003,N'T',1,N'130001',@o22091003,N'Y','2026-04-13T09:00:00','2026-04-12T18:00:00',N'SER',N'Serum');
  INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name) VALUES (22091003,N'11214006',N'2.16.840.1.113883.6.96',N'SCT',N'Reactive');
  INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt) VALUES (22091003,@p22091003,N'PATSBJ',N'OBS',N'PSN','2026-04-13T09:00:00',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',N'Patient Subject');
  INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time) VALUES (22046000,22091003,N'LabReport',N'OBS',N'CASE','2026-04-13T09:00:00',@su,'2026-04-13T09:00:00',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',1,N'A','2026-04-13T09:00:00');
END

-- 10105 confirmatory lab for investigation 22076000
DECLARE @p22091004 bigint=(SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=22076000 AND type_cd='SubjOfPHC');
DECLARE @o22091004 bigint=(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22076000);
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22091004) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22091004,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=22091004)
BEGIN
  INSERT INTO dbo.observation (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
  VALUES (22091004,'2026-04-13T09:00:00',@su,N'5195-3',N'Hepatitis B virus surface Ag [Presence] in Serum',N'2.16.840.1.113883.6.1',N'LN',CAST(GETDATE() AS DATE),@su,N'OBS22091004GA01',N'Order_rslt',N'Order_rslt',N'LabReport',N'PROCESSED','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',@p22091004,N'T',1,N'130001',@o22091004,N'Y','2026-04-13T09:00:00','2026-04-12T18:00:00',N'SER',N'Serum');
  INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name) VALUES (22091004,N'11214006',N'2.16.840.1.113883.6.96',N'SCT',N'Reactive');
  INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt) VALUES (22091004,@p22091004,N'PATSBJ',N'OBS',N'PSN','2026-04-13T09:00:00',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',N'Patient Subject');
  INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time) VALUES (22076000,22091004,N'LabReport',N'OBS',N'CASE','2026-04-13T09:00:00',@su,'2026-04-13T09:00:00',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',1,N'A','2026-04-13T09:00:00');
END

-- 10104 confirmatory lab for investigation 22076100
DECLARE @p22091005 bigint=(SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=22076100 AND type_cd='SubjOfPHC');
DECLARE @o22091005 bigint=(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22076100);
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22091005) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22091005,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=22091005)
BEGIN
  INSERT INTO dbo.observation (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
  VALUES (22091005,'2026-04-13T09:00:00',@su,N'5195-3',N'Hepatitis B virus surface Ag [Presence] in Serum',N'2.16.840.1.113883.6.1',N'LN',CAST(GETDATE() AS DATE),@su,N'OBS22091005GA01',N'Order_rslt',N'Order_rslt',N'LabReport',N'PROCESSED','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',@p22091005,N'T',1,N'130001',@o22091005,N'Y','2026-04-13T09:00:00','2026-04-12T18:00:00',N'SER',N'Serum');
  INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name) VALUES (22091005,N'11214006',N'2.16.840.1.113883.6.96',N'SCT',N'Reactive');
  INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt) VALUES (22091005,@p22091005,N'PATSBJ',N'OBS',N'PSN','2026-04-13T09:00:00',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',N'Patient Subject');
  INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time) VALUES (22076100,22091005,N'LabReport',N'OBS',N'CASE','2026-04-13T09:00:00',@su,'2026-04-13T09:00:00',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',1,N'A','2026-04-13T09:00:00');
END

-- 10190 confirmatory lab for investigation 22006000
DECLARE @p22091006 bigint=(SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=22006000 AND type_cd='SubjOfPHC');
DECLARE @o22091006 bigint=(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22006000);
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22091006) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22091006,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=22091006)
BEGIN
  INSERT INTO dbo.observation (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
  VALUES (22091006,'2026-04-13T09:00:00',@su,N'32700-3',N'Bordetella pertussis DNA [Presence] by NAA',N'2.16.840.1.113883.6.1',N'LN',CAST(GETDATE() AS DATE),@su,N'OBS22091006GA01',N'Order_rslt',N'Order_rslt',N'LabReport',N'PROCESSED','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',@p22091006,N'T',1,N'130001',@o22091006,N'Y','2026-04-13T09:00:00','2026-04-12T18:00:00',N'NASOPH',N'Nasopharyngeal swab');
  INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name) VALUES (22091006,N'260373001',N'2.16.840.1.113883.6.96',N'SCT',N'Detected');
  INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt) VALUES (22091006,@p22091006,N'PATSBJ',N'OBS',N'PSN','2026-04-13T09:00:00',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',N'Patient Subject');
  INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time) VALUES (22006000,22091006,N'LabReport',N'OBS',N'CASE','2026-04-13T09:00:00',@su,'2026-04-13T09:00:00',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',1,N'A','2026-04-13T09:00:00');
END

-- 10190 confirmatory lab for investigation 22007000
DECLARE @p22091007 bigint=(SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=22007000 AND type_cd='SubjOfPHC');
DECLARE @o22091007 bigint=(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22007000);
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22091007) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22091007,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=22091007)
BEGIN
  INSERT INTO dbo.observation (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
  VALUES (22091007,'2026-04-13T09:00:00',@su,N'32700-3',N'Bordetella pertussis DNA [Presence] by NAA',N'2.16.840.1.113883.6.1',N'LN',CAST(GETDATE() AS DATE),@su,N'OBS22091007GA01',N'Order_rslt',N'Order_rslt',N'LabReport',N'PROCESSED','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',@p22091007,N'T',1,N'130001',@o22091007,N'Y','2026-04-13T09:00:00','2026-04-12T18:00:00',N'NASOPH',N'Nasopharyngeal swab');
  INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name) VALUES (22091007,N'260373001',N'2.16.840.1.113883.6.96',N'SCT',N'Detected');
  INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt) VALUES (22091007,@p22091007,N'PATSBJ',N'OBS',N'PSN','2026-04-13T09:00:00',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',N'Patient Subject');
  INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time) VALUES (22007000,22091007,N'LabReport',N'OBS',N'CASE','2026-04-13T09:00:00',@su,'2026-04-13T09:00:00',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',1,N'A','2026-04-13T09:00:00');
END

-- 10130 confirmatory lab for investigation 22049500
DECLARE @p22091008 bigint=(SELECT TOP 1 subject_entity_uid FROM dbo.participation WHERE act_uid=22049500 AND type_cd='SubjOfPHC');
DECLARE @o22091008 bigint=(SELECT program_jurisdiction_oid FROM dbo.public_health_case WHERE public_health_case_uid=22049500);
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid=22091008) INSERT INTO dbo.act (act_uid,class_cd,mood_cd) VALUES (22091008,N'OBS',N'EVN');
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid=22091008)
BEGIN
  INSERT INTO dbo.observation (observation_uid,add_time,add_user_id,cd,cd_desc_txt,cd_system_cd,cd_system_desc_txt,last_chg_time,last_chg_user_id,local_id,obs_domain_cd_st_1,obs_domain_cd,ctrl_cd_display_form,record_status_cd,record_status_time,status_cd,status_time,subject_person_uid,shared_ind,version_ctrl_nbr,jurisdiction_cd,program_jurisdiction_oid,electronic_ind,activity_to_time,effective_from_time,target_site_cd,target_site_desc_txt)
  VALUES (22091008,'2026-04-13T09:00:00',@su,N'32207-9',N'Plasmodium sp [Presence] in Blood by Light microscopy',N'2.16.840.1.113883.6.1',N'LN',CAST(GETDATE() AS DATE),@su,N'OBS22091008GA01',N'Order_rslt',N'Order_rslt',N'LabReport',N'PROCESSED','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',@p22091008,N'T',1,N'130001',@o22091008,N'Y','2026-04-13T09:00:00','2026-04-12T18:00:00',N'BLD',N'Whole blood');
  INSERT INTO dbo.obs_value_coded (observation_uid,code,code_system_cd,code_system_desc_txt,display_name) VALUES (22091008,N'260373001',N'2.16.840.1.113883.6.96',N'SCT',N'Detected');
  INSERT INTO dbo.participation (act_uid,subject_entity_uid,type_cd,act_class_cd,subject_class_cd,add_time,add_user_id,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,status_cd,status_time,type_desc_txt) VALUES (22091008,@p22091008,N'PATSBJ',N'OBS',N'PSN','2026-04-13T09:00:00',@su,CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',N'A','2026-04-13T09:00:00',N'Patient Subject');
  INSERT INTO dbo.act_relationship (target_act_uid,source_act_uid,type_cd,source_class_cd,target_class_cd,add_time,add_user_id,from_time,last_chg_time,last_chg_user_id,record_status_cd,record_status_time,sequence_nbr,status_cd,status_time) VALUES (22049500,22091008,N'LabReport',N'OBS',N'CASE','2026-04-13T09:00:00',@su,'2026-04-13T09:00:00',CAST(GETDATE() AS DATE),@su,N'ACTIVE','2026-04-13T09:00:00',1,N'A','2026-04-13T09:00:00');
END

GO
