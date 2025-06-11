IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_condition_dim')
BEGIN
    DROP VIEW [dbo].v_condition_dim
END;
GO

CREATE VIEW [dbo].v_condition_dim 
AS
-- default record for the dimension
WITH default_record AS (
SELECT 1 AS CONDITION_KEY
),
-- CTE containing condition dim transformations
condition_list AS(
SELECT 
    cc.condition_cd,
    cc.condition_desc_txt AS condition_desc,
    cc.condition_short_nm,
    cc.effective_from_time AS condition_cd_eff_dt,
    cc.effective_to_time AS condition_cd_end_dt,
    cc.nnd_ind,
    (ROW_NUMBER() OVER (ORDER BY effective_from_time)) + 1 AS CONDITION_KEY,
    cc.prog_area_cd AS program_area_cd,
    pac.prog_area_desc_txt AS program_area_desc,
    cc.code_system_cd AS condition_cd_sys_cd,
    cc.code_system_desc_txt AS condition_cd_sys_cd_nm,
    cc.assigning_authority_cd,
    cc.assigning_authority_desc_txt AS assigning_authority_desc,
    CASE LEFT(investigation_form_cd, 50)
        WHEN 'INV_FORM_BMD' THEN 'Bmird_Case'
        WHEN 'INV_FORM_CRS' THEN 'CRS_Case'
        WHEN 'INV_FORM_GEN' THEN 'Generic_Case'
        WHEN 'INV_FORM_VAR' THEN 'Generic_Case'
        WHEN 'INV_FORM_RVC' THEN 'Generic_Case'
        WHEN 'INV_FORM_HEP' THEN 'Hepatitis_Case'
        WHEN 'INV_FORM_MEA' THEN 'Measles_Case'
        WHEN 'INV_FORM_PER' THEN 'Pertussis_Case'
        WHEN 'INV_FORM_RUB' THEN 'Rubella_Case'
        ELSE cc.investigation_form_cd
    END AS disease_grp_cd,
    CASE LEFT(investigation_form_cd, 50)
        WHEN 'INV_FORM_BMD' THEN 'Bmird_Case'
        WHEN 'INV_FORM_CRS' THEN 'CRS_Case'
        WHEN 'INV_FORM_GEN' THEN 'Generic_Case'
        WHEN 'INV_FORM_VAR' THEN 'Generic_Case'
        WHEN 'INV_FORM_RVC' THEN 'Generic_Case'
        WHEN 'INV_FORM_HEP' THEN 'Hepatitis_Case'
        WHEN 'INV_FORM_MEA' THEN 'Measles_Case'
        WHEN 'INV_FORM_PER' THEN 'Pertussis_Case'
        WHEN 'INV_FORM_RUB' THEN 'Rubella_Case'
        ELSE cc.investigation_form_cd
    END AS disease_grp_desc,    
    effective_from_time
FROM 
    [dbo].nrt_srte_CONDITION_CODE cc WITH (NOLOCk)
    LEFT JOIN dbo.nrt_srte_Program_area_code pac WITH (NOLOCk)
        ON cc.prog_area_cd = pac.prog_area_cd
),
-- section for records containing only program area information
pam_only AS (
SELECT
    program_area_cd,
    program_area_desc,
    (ROW_NUMBER() OVER (ORDER BY program_area_cd)) + (SELECT COUNT(*) FROM condition_list) + 1 AS CONDITION_KEY
    FROM (SELECT DISTINCT program_area_cd, program_area_desc FROM condition_list) AS dist_pam
)
SELECT 
    NULL AS condition_cd,
    NULL AS condition_desc, 
    NULL AS condition_short_nm, 
    NULL AS condition_cd_eff_dt, 
    NULL AS condition_cd_end_dt, 
    NULL AS nnd_ind, 
    condition_key,
    NULL AS disease_grp_cd, 
    NULL AS disease_grp_desc,
    NULL AS program_area_cd, 
    NULL AS program_area_desc,
    NULL AS condition_cd_sys_cd_nm, 
    NULL AS assigning_authority_cd, 
    NULL AS assigning_authority_desc,
    NULL AS condition_cd_sys_cd
FROM default_record
UNION ALL
SELECT 
    condition_cd,
    condition_desc, 
    condition_short_nm, 
    condition_cd_eff_dt, 
    condition_cd_end_dt, 
    nnd_ind, 
    condition_key,
    disease_grp_cd, 
    disease_grp_desc,
    program_area_cd, 
    program_area_desc,
    condition_cd_sys_cd_nm, 
    assigning_authority_cd, 
    assigning_authority_desc,
    condition_cd_sys_cd
FROM condition_list
UNION ALL
SELECT 
    NULL AS condition_cd,
    NULL AS condition_desc, 
    NULL AS condition_short_nm, 
    NULL AS condition_cd_eff_dt, 
    NULL AS condition_cd_end_dt, 
    NULL AS nnd_ind, 
    condition_key,
    NULL AS disease_grp_cd, 
    NULL AS disease_grp_desc,
    program_area_cd,
    program_area_desc, 
    NULL AS condition_cd_sys_cd_nm, 
    NULL AS assigning_authority_cd, 
    NULL AS assigning_authority_desc,
    NULL AS condition_cd_sys_cd
FROM pam_only;