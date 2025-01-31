IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'IMRDBMapping' and xtype = 'U')
BEGIN
    WITH missing_records_imrdbmapping as (
    SELECT 'CRS_Case' AS RDB_table, 'CRS023' AS unique_cd, 'Obs_value_numeric' AS DB_table, 'numeric_value_1' as DB_field, 'MOTHER_RASH_LAST_DAY_NBR' AS RDB_ATTRIBUTE, 'MOTHER_RASH_LAST_DAY_NBR' as unique_name, 'CRS' AS condition_cd, '' as other_attributes, 'Record added manually' as [description]
    UNION ALL
    SELECT 'CRS_Case', 'CRS155', 'Obs_value_txt', 'value_txt', 'RT_PCR_OTHER_SRC', 'RT_PCR_OTHER_SRC', 'CRS', '', 'Record added manually'
    UNION ALL
    SELECT 'Generic_Case', 'INV113', 'Obs_value_coded', 'code', 'OTHER_RPT_SRC', 'OTHER_RPT_SRC', 'INVESTIGATION', '', 'Record added manually'
    UNION ALL
    SELECT 'Generic_Case', 'INV189', 'Obs_value_coded', 'code', 'CULTER_IDENT_ORG_ID', 'CULTER_IDENT_ORG_ID', 'INVESTIGATION', '', 'Record added manually'
    UNION ALL
    SELECT 'Generic_Case', 'INV191', 'Obs_value_date', 'from_time', 'BIRTH_HSPTL_ID', 'BIRTH_HSPTL_ID', 'INVESTIGATION', '', 'Record added manually'
    UNION ALL
    SELECT 'Measles_Case', 'MEA023', 'Obs_value_coded', 'code', 'PATIENT_HOSPTLIZED_IND', 'PATIENT_HOSPTLIZED_IND', 'MEASLES', '', 'Record added manually'
    UNION ALL
    SELECT 'Measles_Case', 'MEA024', 'Obs_value_date', 'from_time', 'HSPTL_ADMISSION_DT', 'HSPTL_ADMISSION_DT', 'MEASLES', '', 'Record added manually'
    UNION ALL
    SELECT 'Measles_Case', 'MEA025', 'Obs_value_date', 'from_time', 'HSPTL_DISCHARGE_DT', 'HSPTL_DISCHARGE_DT', 'MEASLES', '', 'Record added manually'
    UNION ALL
    SELECT 'Measles_Case', 'MEA026', 'Obs_value_numeric', 'numeric_value_1', 'HSPTLIZE_DURATION_DAYS', 'HSPTLIZE_DURATION_DAYS', 'MEASLES', '', 'Record added manually'
    UNION ALL
    SELECT 'Measles_Case', 'MEA041', 'Obs_value_coded', 'code', 'NO_MEASLES_VACC_OTHER_REASON', 'NO_MEASLES_VACC_OTHER_REASON', 'MEASLES', '', 'Record added manually'
    UNION ALL
    SELECT 'Measles_Case', 'MEA055', 'Obs_value_date', 'from_time', 'RPT_TO_HEALTH_DEPT_DT', 'RPT_TO_HEALTH_DEPT_DT', 'MEASLES', '', 'Record added manually'
    UNION ALL
    SELECT 'Measles_Case', 'MEA056', 'Obs_value_date', 'from_time', 'DIAGNOSIS_DT', 'DIAGNOSIS_DT', 'MEASLES', '', 'Record added manually'
    UNION ALL
    SELECT 'Rubella_Case', 'RUB032', 'Obs_value_date', 'from_time', 'HSPTLIZED_DAY_NBR', 'HSPTLIZED_DAY_NBR' , 'RUBELLA', '', 'Record added manually'
    UNION ALL
    SELECT 'Rubella_Case', 'RUB095', 'Obs_value_txt', 'value_txt', 'RUBELLAVACCINED_NOTOTHERREASON', 'RUBELLAVACCINED_NOTOTHERREASON', 'RUBELLA', '', 'Record added manually'
    UNION ALL
    SELECT 'Rubella_Case', 'RUB098', 'Obs_value_date', 'from_time', 'RUBELLA_VACCINE_RECEIVED_DT', 'RUBELLA_VACCINE_RECEIVED_DT', 'RUBELLA', '', 'Record added manually'
    UNION ALL
    SELECT 'Rubella_Case', 'RUB105', 'Obs_value_date', 'from_time', 'RUBELLA_VACCINE_EXPIRATION_DT', 'RUBELLA_VACCINE_EXPIRATION_DT', 'RUBELLA', '', 'Record added manually'
    UNION ALL
    SELECT 'Rubella_Case', 'RUB106', 'Obs_value_date', 'from_time', 'INV_RPT_DT', 'INV_RPT_DT', 'RUBELLA', '', 'Record added manually'
    UNION ALL
    SELECT 'Rubella_Case', 'RUB107', 'Obs_value_date', 'from_time', 'DIAGNOSIS_DT', 'DIAGNOSIS_DT', 'RUBELLA', '', 'Record added manually'
    UNION ALL
    SELECT 'Rubella_Case', 'RUB131', 'Obs_value_txt', 'value_txt', 'PREGNANCY_OTHER_OUTCOME', 'PREGNANCY_OTHER_OUTCOME', 'RUBELLA', '', 'Record added manually'
    UNION ALL
    SELECT 'BMIRD_Case', 'BMD154', 'Obs_value_date', 'from_time', 'SPECIMEN_COLLECT_DT', 'SPECIMEN_COLLECT_DT', 'BMIRD', '', 'Record added manually'
    UNION ALL
    SELECT 'BMIRD_Case', 'BMD155', 'Obs_value_coded', 'code', 'ISOLATE_SEND_TO_CDC_IND', 'ISOLATE_SEND_TO_CDC_IND', 'BMIRD', '', 'Record added manually'
    UNION ALL
    SELECT 'BMIRD_Case', 'BMD156', 'Obs_value_date', 'from_time', 'ISOLATE_SEND_TO_CDC_DT', 'ISOLATE_SEND_TO_CDC_DT', 'BMIRD', '', 'Record added manually'
    UNION ALL
    SELECT 'BMIRD_Case', 'BMD157', 'Obs_value_coded', 'code', 'ISOLATE_SEND_TO_ST_IND', 'ISOLATE_SEND_TO_ST_IND', 'BMIRD', '', 'Record added manually'
    UNION ALL
    SELECT 'BMIRD_Case', 'BMD158', 'Obs_value_date', 'from_time', 'ISOLATE_SEND_TO_ST_DT', 'ISOLATE_SEND_TO_ST_DT', 'BMIRD', '', 'Record added manually'
    )
    INSERT INTO dbo.IMRDBMapping
    (
        IMRDBMAPPING_id,
        unique_cd,
        unique_name,
        [description],
        db_table,
        db_field,
        rdb_table,
        rdb_attribute,
        other_attributes,
        condition_cd
    )
    SELECT (SELECT COUNT(*) FROM dbo.IMRDBMAPPING) + ROW_NUMBER() OVER (ORDER BY UNIQUE_CD) AS IMRDBMapping_id,
    unique_cd,
    unique_name,
    [description],
    DB_table,
    DB_field,
    RDB_table,
    RDB_ATTRIBUTE,
    other_attributes,
    condition_cd
    from missing_records_imrdbmapping
    WHERE unique_cd NOT IN (SELECT unique_cd FROM NBS_SRTE.dbo.IMRDBMAPPING);

    update dbo.IMRDBMapping
        SET DB_table = 'Obs_value_numeric',
            DB_field = 'numeric_value_1'
        WHERE unique_cd = 'CRS013'
              AND DB_table = 'Obs_value_date'
              AND DB_field = 'from_time';

END;