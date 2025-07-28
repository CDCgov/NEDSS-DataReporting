-- use rdb_modern;


/*ODSE config: dbo.Page_cond_mapping, dbo.NBS_page, dbo.NBS_ui_metadata, dbo.NBS_rdb_metadata, dbo.state_defined_field_metadata, dbo.NBS_configuration, dbo.LOOKUP_QUESTION
*/
-- these scripts are to bulk load the metadata information from odse to reporting database

IF OBJECT_ID('dbo.nrt_odse_LOOKUP_QUESTION', 'U') IS NOT NULL
begin
	Truncate Table dbo.nrt_odse_LOOKUP_QUESTION;
	insert into dbo.nrt_odse_LOOKUP_QUESTION select * from nbs_odse.dbo.LOOKUP_QUESTION;
end;

IF OBJECT_ID('dbo.nrt_odse_NBS_configuration', 'U') IS NOT NULL
begin
	Truncate Table dbo.nrt_odse_NBS_configuration;
	insert into dbo.nrt_odse_NBS_configuration select * from nbs_odse.dbo.NBS_configuration;
end;

IF OBJECT_ID('dbo.nrt_odse_NBS_page', 'U') IS NOT NULL
begin
	Truncate Table dbo.nrt_odse_NBS_page;
	insert into dbo.nrt_odse_NBS_page select * from nbs_odse.dbo.NBS_page;
end;

IF OBJECT_ID('dbo.nrt_odse_NBS_rdb_metadata', 'U') IS NOT NULL
begin
	Truncate Table dbo.nrt_odse_NBS_rdb_metadata;
	insert into dbo.nrt_odse_NBS_rdb_metadata select * from nbs_odse.dbo.NBS_rdb_metadata;
end;

IF OBJECT_ID('dbo.nrt_odse_NBS_ui_metadata', 'U') IS NOT NULL
begin
	Truncate Table dbo.nrt_odse_NBS_ui_metadata;
	insert into dbo.nrt_odse_NBS_ui_metadata select * from nbs_odse.dbo.NBS_ui_metadata; 
end;

IF OBJECT_ID('dbo.nrt_odse_Page_cond_mapping', 'U') IS NOT NULL
begin
	Truncate Table dbo.nrt_odse_Page_cond_mapping;
	insert into dbo.nrt_odse_Page_cond_mapping select * from nbs_odse.dbo.Page_cond_mapping;
end;

IF OBJECT_ID('dbo.nrt_odse_state_defined_field_metadata', 'U') IS NOT NULL
begin
	Truncate Table dbo.nrt_odse_state_defined_field_metadata;
	insert into dbo.nrt_odse_state_defined_field_metadata select * from nbs_odse.dbo.state_defined_field_metadata;
end;

-- these scripts are to bulk load the metadata information from srte to reporting database

/*
-- SRTE config: dbo.Condition_code,dbo.Program_area_code,dbo.Language_code,dbo.State_code,dbo.Unit_code, dbo.Cntycity_code_value,dbo.Lab_result,dbo.Country_code,dbo.Labtest_loinc,dbo.ELR_XREF,       ,dbo.Loinc_condition,dbo.Loinc_snomed_condition,dbo.Lab_test,dbo.Zip_code_value,dbo.Zipcnty_code_value,dbo.Lab_result_Snomed,dbo.Investigation_code,dbo.TotalIDM      dbo.IMRDBMapping,dbo.Anatomic_site_code,dbo.Jurisdiction_code,dbo.Lab_coding_system,dbo.City_code_value,dbo.LDF_page_set,dbo.LOINC_code,dbo.NAICS_Industry_code,           dbo.Codeset_Group_Metadata,dbo.Country_Code_ISO,dbo.Occupation_code,dbo.Country_XREF,dbo.Standard_XREF,dbo.Code_value_clinical,dbo.Code_value_general,dbo.Race_code,dbo.Participation_type,         dbo.Specimen_source_code,dbo.Snomed_code,dbo.State_county_code_value,dbo.State_model,dbo.Codeset,                             dbo.Jurisdiction_participation,dbo.Labtest_Progarea_Mapping,dbo.Treatment_code,dbo.Snomed_condition
*/


IF OBJECT_ID('dbo.nrt_srte_Anatomic_site_code', 'U') IS NOT NULL
begin
	truncate table dbo.nrt_srte_Anatomic_site_code;
	insert into dbo.nrt_srte_Anatomic_site_code select * from nbs_srte.dbo.Anatomic_site_code;
end;

IF OBJECT_ID('dbo.nrt_srte_City_code_value', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_City_code_value;
	insert into dbo.nrt_srte_City_code_value select * from nbs_srte.dbo.City_code_value;
end;

IF OBJECT_ID('dbo.nrt_srte_Cntycity_code_value', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Cntycity_code_value;
	insert into dbo.nrt_srte_Cntycity_code_value select * from nbs_srte.dbo.Cntycity_code_value;
end;

IF OBJECT_ID('dbo.nrt_srte_Code_value_clinical', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Code_value_clinical; 
	insert into dbo.nrt_srte_Code_value_clinical select * from nbs_srte.dbo.Code_value_clinical;
end;

IF OBJECT_ID('dbo.nrt_srte_Code_value_general', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Code_value_general; 
	insert into dbo.nrt_srte_Code_value_general select * from nbs_srte.dbo.Code_value_general;
end;
  
IF OBJECT_ID('dbo.nrt_srte_Codeset', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Codeset; 
	insert into dbo.nrt_srte_Codeset select * from nbs_srte.dbo.Codeset;
end;

IF OBJECT_ID('dbo.nrt_srte_Codeset_Group_Metadata', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Codeset_Group_Metadata; 
	insert into dbo.nrt_srte_Codeset_Group_Metadata select * from nbs_srte.dbo.Codeset_Group_Metadata;
end;

IF OBJECT_ID('dbo.nrt_srte_Condition_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Condition_code; 
	insert into dbo.nrt_srte_Condition_code select * from nbs_srte.dbo.Condition_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Country_Code_ISO', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Country_Code_ISO; 
	insert into dbo.nrt_srte_Country_Code_ISO select * from nbs_srte.dbo.Country_Code_ISO;
end;

IF OBJECT_ID('dbo.nrt_srte_Country_XREF', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Country_XREF; 
	insert into dbo.nrt_srte_Country_XREF select * from nbs_srte.dbo.Country_XREF;
end;

IF OBJECT_ID('dbo.nrt_srte_Country_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Country_code; 
	insert into dbo.nrt_srte_Country_code select * from nbs_srte.dbo.Country_code;
end;

IF OBJECT_ID('dbo.nrt_srte_ELR_XREF', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_ELR_XREF; 
	insert into dbo.nrt_srte_ELR_XREF select * from nbs_srte.dbo.ELR_XREF;
end;

IF OBJECT_ID('dbo.nrt_srte_IMRDBMapping', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_IMRDBMapping; 
	insert into dbo.nrt_srte_IMRDBMapping select * from nbs_srte.dbo.IMRDBMapping;
end;

IF OBJECT_ID('dbo.nrt_srte_Investigation_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Investigation_code; 
	insert into dbo.nrt_srte_Investigation_code select * from nbs_srte.dbo.Investigation_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Jurisdiction_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Jurisdiction_code; 
	insert into dbo.nrt_srte_Jurisdiction_code select * from nbs_srte.dbo.Jurisdiction_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Jurisdiction_participation', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Jurisdiction_participation; 
	insert into dbo.nrt_srte_Jurisdiction_participation select * from nbs_srte.dbo.Jurisdiction_participation;
end;

IF OBJECT_ID('dbo.nrt_srte_LDF_page_set', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_LDF_page_set;
	insert into dbo.nrt_srte_LDF_page_set select * from nbs_srte.dbo.LDF_page_set;
end;

IF OBJECT_ID('dbo.nrt_srte_LOINC_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_LOINC_code; 
	insert into dbo.nrt_srte_LOINC_code select * from nbs_srte.dbo.LOINC_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Lab_coding_system', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Lab_coding_system; 
	insert into dbo.nrt_srte_Lab_coding_system select * from nbs_srte.dbo.Lab_coding_system;
end;

IF OBJECT_ID('dbo.nrt_srte_Lab_result', 'U') IS NOT NULL 
begin
	truncate table .dbo.nrt_srte_Lab_result; 
	insert into dbo.nrt_srte_Lab_result select * from nbs_srte.dbo.Lab_result;
end;

IF OBJECT_ID('dbo.nrt_srte_Lab_result_Snomed', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Lab_result_Snomed; 
	insert into dbo.nrt_srte_Lab_result_Snomed select * from nbs_srte.dbo.Lab_result_Snomed;
end;

IF OBJECT_ID('dbo.nrt_srte_Lab_test', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Lab_test;
	insert into dbo.nrt_srte_Lab_test select * from nbs_srte.dbo.Lab_test;
end;

IF OBJECT_ID('dbo.nrt_srte_Labtest_Progarea_Mapping', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Labtest_Progarea_Mapping; 
	insert into dbo.nrt_srte_Labtest_Progarea_Mapping select * from nbs_srte.dbo.Labtest_Progarea_Mapping;
end;

IF OBJECT_ID('dbo.nrt_srte_Labtest_loinc', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Labtest_loinc; 
	insert into dbo.nrt_srte_Labtest_loinc select * from nbs_srte.dbo.Labtest_loinc;
end;

IF OBJECT_ID('dbo.nrt_srte_Language_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Language_code;
	insert into dbo.nrt_srte_Language_code select * from nbs_srte.dbo.Language_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Loinc_condition', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Loinc_condition; 
	insert into dbo.nrt_srte_Loinc_condition select * from nbs_srte.dbo.Loinc_condition;
end;

IF OBJECT_ID('dbo.nrt_srte_Loinc_snomed_condition', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Loinc_snomed_condition; 
	insert into dbo.nrt_srte_Loinc_snomed_condition select * from nbs_srte.dbo.Loinc_snomed_condition;
end;

IF OBJECT_ID('dbo.nrt_srte_NAICS_Industry_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_NAICS_Industry_code;
	insert into dbo.nrt_srte_NAICS_Industry_code select * from nbs_srte.dbo.NAICS_Industry_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Occupation_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Occupation_code; 
	insert into dbo.nrt_srte_Occupation_code select * from nbs_srte.dbo.Occupation_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Participation_type', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Participation_type; 
	insert into dbo.nrt_srte_Participation_type select * from nbs_srte.dbo.Participation_type;
end;

IF OBJECT_ID('dbo.nrt_srte_Program_area_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Program_area_code; 
	insert into dbo.nrt_srte_Program_area_code select * from nbs_srte.dbo.Program_area_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Race_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Race_code; 
	insert into dbo.nrt_srte_Race_code select * from nbs_srte.dbo.Race_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Snomed_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Snomed_code; 
	insert into dbo.nrt_srte_Snomed_code select * from nbs_srte.dbo.Snomed_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Snomed_condition', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Snomed_condition;
	insert into dbo.nrt_srte_Snomed_condition select * from nbs_srte.dbo.Snomed_condition;
end;

IF OBJECT_ID('dbo.nrt_srte_Specimen_source_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Specimen_source_code;
	insert into dbo.nrt_srte_Specimen_source_code select * from nbs_srte.dbo.Specimen_source_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Standard_XREF', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Standard_XREF;
	insert into dbo.nrt_srte_Standard_XREF select * from nbs_srte.dbo.Standard_XREF;
end;

IF OBJECT_ID('dbo.nrt_srte_State_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_State_code;
	insert into dbo.nrt_srte_State_code select * from nbs_srte.dbo.State_code;
end;

IF OBJECT_ID('dbo.nrt_srte_State_county_code_value', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_State_county_code_value;
	insert into dbo.nrt_srte_State_county_code_value select * from nbs_srte.dbo.State_county_code_value;
end;

IF OBJECT_ID('dbo.nrt_srte_State_model', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_State_model; 
	insert into dbo.nrt_srte_State_model select * from nbs_srte.dbo.State_model;
end;

IF OBJECT_ID('dbo.nrt_srte_TotalIDM', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_TotalIDM; 
	insert into dbo.nrt_srte_TotalIDM select * from nbs_srte.dbo.TotalIDM;
end;

IF OBJECT_ID('dbo.nrt_srte_Treatment_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Treatment_code;
	insert into dbo.nrt_srte_Treatment_code select * from nbs_srte.dbo.Treatment_code;
end;

IF OBJECT_ID('dbo.nrt_srte_Unit_code', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Unit_code;
	insert into dbo.nrt_srte_Unit_code select * from nbs_srte.dbo.Unit_code;
end;

/* IF OBJECT_ID('dbo.nrt_srte_XSS_Filter_Pattern', 'U') IS NOT NULL - No PK in source
begin
	truncate table dbo.nrt_srte_XSS_Filter_Pattern; 
	insert into dbo.nrt_srte_XSS_Filter_Pattern select * from nbs_srte.dbo.XSS_Filter_Pattern;
end;
*/

IF OBJECT_ID('dbo.nrt_srte_Zip_code_value', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Zip_code_value; 
	insert into dbo.nrt_srte_Zip_code_value select * from nbs_srte.dbo.Zip_code_value;
end;

IF OBJECT_ID('dbo.nrt_srte_Zipcnty_code_value', 'U') IS NOT NULL 
begin
	truncate table dbo.nrt_srte_Zipcnty_code_value; 
	insert into dbo.nrt_srte_Zipcnty_code_value select * from nbs_srte.dbo.Zipcnty_code_value;
end;
