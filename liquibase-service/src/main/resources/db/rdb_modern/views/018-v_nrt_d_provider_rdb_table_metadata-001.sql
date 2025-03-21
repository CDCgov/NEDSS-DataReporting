

Create OR alter view dbo.v_nrt_d_provider_rdb_table_metadata as 
SELECT DISTINCT RDB_COLUMN_NM, user_defined_column_nm, 
case
	when part_type_cd= 'CASupervisorOfPHC' then 'SUPRVSR_OF_CASE_ASSGNMENT_KEY'
	when PART_TYPE_CD='ClosureInvestgrOfPHC' then 'CLOSED_BY_KEY'	   
when PART_TYPE_CD= 'DispoFldFupInvestgrOfPHC' then 'DISPOSITIONED_BY_KEY'	   
when PART_TYPE_CD= 'FldFupInvestgrOfPHC'  then'INVSTGTR_FLD_FOLLOW_UP_KEY'	  
when PART_TYPE_CD= 'FldFupProvOfPHC' then'PROVIDER_FLD_FOLLOW_UP_KEY'	   
when PART_TYPE_CD= 'FldFupSupervisorOfPHC' then'SUPRVSR_OF_FLD_FOLLOW_UP_KEY'	   
when PART_TYPE_CD= 'InitFldFupInvestgrOfPHC' then'INIT_ASGNED_FLD_FOLLOW_UP_KEY'	  
when PART_TYPE_CD= 'InitFupInvestgrOfPHC' then'INIT_FOLLOW_UP_INVSTGTR_KEY'	   
when PART_TYPE_CD= 'InitInterviewerOfPHC' then'INIT_ASGNED_INTERVIEWER_KEY'	  
when PART_TYPE_CD= 'InterviewerOfPHC' then'INTERVIEWER_ASSIGNED_KEY'	 
when PART_TYPE_CD= 'InvestgrOfPHC' then'INVESTIGATOR_KEY'	  
when PART_TYPE_CD= 'PerAsProviderOfDelivery' then'DELIVERING_MD_KEY'	  
when PART_TYPE_CD= 'PerAsProviderOfOBGYN' then'MOTHER_OB_GYN_KEY'	   
when  PART_TYPE_CD= 'PerAsProvideroOfPediatrics' then'PEDIATRICIAN_KEY'	  
when PART_TYPE_CD= 'PerAsReporterOfPHC' then'PERSON_AS_REPORTER_KEY'	   
when PART_TYPE_CD= 'PhysicianOfPHC' then'PHYSICIAN_KEY'	  
when PART_TYPE_CD= 'SurvInvestgrOfPHC' then'SURVEILLANCE_INVESTIGATOR_KEY'	   
when PART_TYPE_CD= 'FldFupFacilityOfPHC' then'FACILITY_FLD_FOLLOW_UP_KEY'	   
when PART_TYPE_CD= 'HospOfADT' then'HOSPITAL_KEY'	   
when PART_TYPE_CD= 'OrgAsClinicOfPHC' then'ORDERING_FACILITY_KEY'	   
when PART_TYPE_CD= 'OrgAsHospitalOfDelivery' then 'DELIVERING_HOSP_KEY'	   
when PART_TYPE_CD= 'OrgAsReporterOfPHC' then 'ORG_AS_REPORTER_KEY'	 
end part_type_cd ,
cast(substring(USER_DEFINED_COLUMN_NM,1,CHARINDEX('_UID',USER_DEFINED_COLUMN_NM))+'KEY' as varchar(2000)) as [Key],
cast( substring(USER_DEFINED_COLUMN_NM,1,CHARINDEX('_UID',USER_DEFINED_COLUMN_NM))+'DETAIL'  as varchar(2000)) as Detail,
cast( substring(USER_DEFINED_COLUMN_NM,1,CHARINDEX('_UID',USER_DEFINED_COLUMN_NM))+'QEC' as varchar(2000)) as QEC,
cast( USER_DEFINED_COLUMN_NM as varchar(2000)) as [UID],INVESTIGATION_FORM_CD

-- into #tmp_DynDm_Provider_Metadata
FROM NBS_ODSE..NBS_RDB_METADATA 
INNER JOIN NBS_ODSE..NBS_UI_METADATA ON NBS_RDB_METADATA.NBS_UI_METADATA_UID =NBS_UI_METADATA.NBS_UI_METADATA_UID
WHERE NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM <> '' 
and NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM IS NOT NULL
AND PART_TYPE_CD IS NOT NULL 
AND RDB_TABLE_NM ='D_PROVIDER' 
AND DATA_TYPE='PART'
--and INVESTIGATION_FORM_CD  =  (SELECT FORM_CD FROM dbo.NBS_PAGE WHERE DATAMART_NM = @DATAMART_NAME)

;