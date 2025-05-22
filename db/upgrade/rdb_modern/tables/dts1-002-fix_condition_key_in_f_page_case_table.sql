IF  EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'INVESTIGATION')
	AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'F_PAGE_CASE')
	AND EXISTS (SELECT * FROM sys.views WHERE name = 'v_condition_dim')
	AND EXISTS (SELECT * FROM nbs_odse.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'public_health_case')
	AND EXISTS (SELECT * FROM nbs_srte.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Condition_code')
BEGIN
	UPDATE f
		SET CONDITION_KEY = (SELECT TOP(1) condition_key FROM [dbo].v_condition_dim WITH (NOLOCK) WHERE condition_cd = cc2.condition_cd)
	FROM [dbo].INVESTIGATION inv WITH (NOLOCK) 
		INNER JOIN [nbs_odse].[dbo].public_health_case phc WITH (NOLOCK) ON phc.public_health_case_uid = inv.CASE_UID 
		INNER JOIN [nbs_srte].[dbo].Condition_code cc2 WITH (NOLOCK) ON cc2.condition_cd = phc.cd
		INNER JOIN [dbo].F_PAGE_CASE f WITH (NOLOCK) ON f.INVESTIGATION_KEY = inv.INVESTIGATION_KEY
		INNER JOIN [dbo].v_condition_dim vc WITH (NOLOCK) ON f.CONDITION_KEY = vc.CONDITION_KEY
	WHERE 
		COALESCE(cc2.condition_cd,'') <> COALESCE(vc.condition_cd,'')
END