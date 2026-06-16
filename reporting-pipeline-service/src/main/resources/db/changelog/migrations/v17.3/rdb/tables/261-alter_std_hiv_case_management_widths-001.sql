IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[nrt_investigation_case_management]')
      AND name = 'fl_fup_actual_ref_type'
      AND system_type_id = 167
      AND collation_name IS NOT NULL
      AND max_length <> 100
)
BEGIN
    ALTER TABLE [dbo].[nrt_investigation_case_management]
        ALTER COLUMN [fl_fup_actual_ref_type] varchar(100) NULL;
END;

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[nrt_investigation_case_management]')
      AND name = 'fl_fup_notification_plan_cd'
      AND system_type_id = 167
      AND collation_name IS NOT NULL
      AND max_length <> 100
)
BEGIN
    ALTER TABLE [dbo].[nrt_investigation_case_management]
        ALTER COLUMN [fl_fup_notification_plan_cd] varchar(100) NULL;
END;

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[D_CASE_MANAGEMENT]')
      AND name = 'FL_FUP_ACTUAL_REF_TYPE'
      AND system_type_id = 167
      AND collation_name IS NOT NULL
      AND max_length <> 100
)
BEGIN
    ALTER TABLE [dbo].[D_CASE_MANAGEMENT]
        ALTER COLUMN [FL_FUP_ACTUAL_REF_TYPE] varchar(100) NULL;
END;

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[D_CASE_MANAGEMENT]')
      AND name = 'FL_FUP_NOTIFICATION_PLAN_CD'
      AND system_type_id = 167
      AND collation_name IS NOT NULL
      AND max_length <> 100
)
BEGIN
    ALTER TABLE [dbo].[D_CASE_MANAGEMENT]
        ALTER COLUMN [FL_FUP_NOTIFICATION_PLAN_CD] varchar(100) NULL;
END;

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[STD_HIV_DATAMART]')
      AND name = 'FL_FUP_ACTUAL_REF_TYPE'
      AND system_type_id = 167
      AND collation_name IS NOT NULL
      AND max_length <> 100
)
BEGIN
    ALTER TABLE [dbo].[STD_HIV_DATAMART]
        ALTER COLUMN [FL_FUP_ACTUAL_REF_TYPE] varchar(100) NULL;
END;

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[STD_HIV_DATAMART]')
      AND name = 'FL_FUP_NOTIFICATION_PLAN'
      AND system_type_id = 167
      AND collation_name IS NOT NULL
      AND max_length <> 100
)
BEGIN
    ALTER TABLE [dbo].[STD_HIV_DATAMART]
        ALTER COLUMN [FL_FUP_NOTIFICATION_PLAN] varchar(100) NULL;
END;

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[DM_INV_HIV]')
      AND name = 'FL_FUP_ACTUAL_REF_TY'
      AND system_type_id = 167
      AND collation_name IS NOT NULL
      AND max_length <> 25
)
BEGIN
    ALTER TABLE [dbo].[DM_INV_HIV]
        ALTER COLUMN [FL_FUP_ACTUAL_REF_TY] varchar(25) NULL;
END;
