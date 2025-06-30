IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_nbs_d_organization_rdb_table_metadata')
BEGIN
    DROP VIEW [dbo].v_nrt_nbs_d_organization_rdb_table_metadata
END
GO

CREATE VIEW [dbo].v_nrt_nbs_d_organization_rdb_table_metadata 
AS
SELECT DISTINCT 
	RDB_COLUMN_NM, 
	user_defined_column_nm, 
	CASE 
		WHEN part_type_cd = 'FldFupFacilityOfPHC' THEN 'FACILITY_FLD_FOLLOW_UP_KEY'
		WHEN part_type_cd = 'HospOfADT' THEN 'HOSPITAL_KEY'
		WHEN part_type_cd = 'OrgAsClinicOfPHC' THEN 'ORDERING_FACILITY_KEY'
		WHEN part_type_cd = 'OrgAsHospitalOfDelivery' THEN 'DELIVERING_HOSP_KEY'
		WHEN part_type_cd = 'OrgAsReporterOfPHC' THEN 'ORG_AS_REPORTER_KEY'
	END  part_type_cd,
	CAST(SUBSTRING(USER_DEFINED_COLUMN_NM,1,CHARINDEX('_UID',USER_DEFINED_COLUMN_NM))+'KEY' AS VARCHAR(2000)) AS [Key],
	CAST(SUBSTRING(USER_DEFINED_COLUMN_NM,1,CHARINDEX('_UID',USER_DEFINED_COLUMN_NM))+'DETAIL' AS VARCHAR(2000)) AS Detail,
	CAST(SUBSTRING(USER_DEFINED_COLUMN_NM,1,CHARINDEX('_UID',USER_DEFINED_COLUMN_NM))+'QEC' AS VARCHAR(2000)) AS QEC,
	cast(USER_DEFINED_COLUMN_NM AS VARCHAR(2000)) AS [UID],
	INVESTIGATION_FORM_CD
FROM [dbo].v_nrt_odse_NBS_rdb_metadata_recent rdb_meta WITH(NOLOCk)
INNER JOIN [dbo].nrt_odse_NBS_ui_metadata ui_meta WITH(NOLOCk)
	ON rdb_meta.NBS_UI_METADATA_UID = ui_meta.NBS_UI_METADATA_UID
WHERE 
	rdb_meta.USER_DEFINED_COLUMN_NM <> '' 
	AND rdb_meta.USER_DEFINED_COLUMN_NM IS NOT NULL
	AND PART_TYPE_CD IS NOT NULL 
	AND RDB_TABLE_NM ='D_ORGANIZATION' 
	AND DATA_TYPE='PART';