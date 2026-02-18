-- Insert into NBS_ODSE.NBS_Configuration to flag use of RDB_MODERN
INSERT INTO
	NBS_ODSE.DBO.NBS_configuration (
	config_key,
	config_value,
	version_ctrl_nbr,
	add_user_id,
	add_time,
	last_chg_user_id,
	last_chg_time,
	status_cd,
	status_time
	)
VALUES
	('ENV', 'UAT', 1, 99999999, GETDATE(), 99999999, GETDATE(), 'A', GETDATE());

-- Fix for missing columns
ALTER TABLE LDF_GROUP ADD BUSINESS_OBJECT_UID BIGINT NULL;
ALTER TABLE D_VACCINATION ADD VACCINATION_UID BIGINT NULL;