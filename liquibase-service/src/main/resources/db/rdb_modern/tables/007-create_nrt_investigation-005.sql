IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation' and xtype = 'U')
BEGIN

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ca_supervisor_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD ca_supervisor_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'closure_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD closure_investgr_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'dispo_fld_fupinvestgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD dispo_fld_fupinvestgr_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'fld_fup_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD fld_fup_investgr_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'fld_fup_prov_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD fld_fup_prov_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'fld_fup_supervisor_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD fld_fup_supervisor_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'init_fld_fup_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD init_fld_fup_investgr_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'init_fup_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD init_fup_investgr_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'init_interviewer_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD init_interviewer_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'interviewer_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD interviewer_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'surv_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD surv_investgr_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'fld_fup_facility_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD fld_fup_facility_of_phc_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'org_as_hospital_of_delivery_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD org_as_hospital_of_delivery_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'per_as_provider_of_delivery_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD per_as_provider_of_delivery_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'per_as_provider_of_obgyn_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD per_as_provider_of_obgyn_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'per_as_provider_of_pediatrics_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD per_as_provider_of_pediatrics_uid bigint;
END;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'org_as_reporter_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
BEGIN
ALTER TABLE dbo.nrt_investigation ADD org_as_reporter_uid bigint;
END;

END;