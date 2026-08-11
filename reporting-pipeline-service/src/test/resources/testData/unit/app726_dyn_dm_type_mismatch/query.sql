SELECT
    (SELECT COUNT(*)
     FROM RDB_MODERN.dbo.job_flow_log
     WHERE package_name = 'sp_dyn_dm_createdm_postprocessing: APP726'
       AND status_type = 'ERROR'
       AND error_description LIKE '%Operand type clash%') AS OPERAND_TYPE_CLASH_COUNT,
    (SELECT COUNT(*)
     FROM RDB_MODERN.dbo.job_flow_log
     WHERE package_name = 'sp_dyn_dm_createdm_postprocessing: APP726'
       AND status_type = 'COMPLETE') AS COMPLETE_COUNT,
    (SELECT COUNT(*)
     FROM RDB_MODERN.INFORMATION_SCHEMA.TABLES
     WHERE TABLE_SCHEMA = 'dbo'
       AND TABLE_NAME = 'DM_INV_APP726') AS DM_INV_APP726_EXISTS,
    (SELECT data_type
     FROM RDB_MODERN.INFORMATION_SCHEMA.COLUMNS
     WHERE table_name = 'DM_INV_APP726'
       AND column_name = 'SRC_FLOAT') AS SRC_FLOAT_TYPE,
    (SELECT data_type
     FROM RDB_MODERN.INFORMATION_SCHEMA.COLUMNS
     WHERE table_name = 'DM_INV_APP726'
       AND column_name = 'SRC_DT2') AS SRC_DT2_TYPE,
    (SELECT data_type
     FROM RDB_MODERN.INFORMATION_SCHEMA.COLUMNS
     WHERE table_name = 'DM_INV_APP726'
       AND column_name = 'SRC_DTO') AS SRC_DTO_TYPE,
    (SELECT data_type
     FROM RDB_MODERN.INFORMATION_SCHEMA.COLUMNS
     WHERE table_name = 'DM_INV_APP726'
       AND column_name = 'SRC_TM') AS SRC_TM_TYPE,
    (SELECT data_type
     FROM RDB_MODERN.INFORMATION_SCHEMA.COLUMNS
     WHERE table_name = 'DM_INV_APP726'
       AND column_name = 'SRC_NVC') AS SRC_NVC_TYPE,
    (SELECT data_type
     FROM RDB_MODERN.INFORMATION_SCHEMA.COLUMNS
     WHERE table_name = 'DM_INV_APP726'
       AND column_name = 'SRC_BIN') AS SRC_BIN_TYPE;