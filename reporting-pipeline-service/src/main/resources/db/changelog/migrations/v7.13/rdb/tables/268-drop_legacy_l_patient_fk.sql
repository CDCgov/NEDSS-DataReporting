/* APP-973: drop inherited legacy foreign keys that reference L_PATIENT.
   RDB_MODERN is restored from a copy of the legacy RDB, so it inherits constraints such as
   FK_LAB_TEST_RESULT_PATIENT_KEY (LAB_TEST_RESULT) and FK_PATIENT_KEY (MORBIDITY_REPORT_EVENT).
   RTR replaced the L_PATIENT lookup with nrt_patient_key and never writes L_PATIENT, so those
   constraints fail with error 547 on every record RTR creates. Matched by referenced table
   because the constraint names vary by upgrade path. */
IF OBJECT_ID('dbo.L_PATIENT') IS NOT NULL
BEGIN
    DECLARE @constraint_name sysname, @child_table sysname, @sql nvarchar(500);

    WHILE EXISTS (SELECT 1 FROM sys.foreign_keys
                  WHERE referenced_object_id = OBJECT_ID('dbo.L_PATIENT'))
    BEGIN
        SELECT TOP 1 @constraint_name = fk.name,
                     @child_table     = OBJECT_NAME(fk.parent_object_id)
        FROM sys.foreign_keys fk
        WHERE fk.referenced_object_id = OBJECT_ID('dbo.L_PATIENT');

        SET @sql = N'ALTER TABLE dbo.' + QUOTENAME(@child_table)
                 + N' DROP CONSTRAINT ' + QUOTENAME(@constraint_name);
        EXEC sp_executesql @sql;
    END;
END;
