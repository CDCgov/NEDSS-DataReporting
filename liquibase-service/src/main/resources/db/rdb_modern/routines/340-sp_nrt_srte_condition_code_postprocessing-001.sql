CREATE OR ALTER PROCEDURE [dbo].[sp_nrt_srte_condition_code_postprocessing]
    @condition_cd_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'nrt_srte_condition_code POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_nrt_srte_condition_code_postprocessing';

    BEGIN TRY
        

        SET @Proc_Step_Name = 'SP_Start';

        INSERT INTO dbo.job_flow_log ( batch_id
                                    , [Dataflow_Name]
                                    , [package_Name]
                                    , [Status_Type]
                                    , [step_number]
                                    , [step_name]
                                    , [row_count]
                                    , [Msg_Description1])
        VALUES ( @batch_id
            , @Dataflow_Name
            , @Package_Name
            , 'START'
            , @Proc_Step_no
            , @Proc_Step_Name
            , 0
            , LEFT('ID List-' + @condition_cd_list, 500));
        
--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #CONDITION_INIT';

        
        WITH condition_list AS(
            SELECT 
                cc.condition_cd,
                cc.condition_desc_txt AS condition_desc,
                cc.condition_short_nm,
                cc.effective_from_time AS condition_cd_eff_dt,
                cc.effective_to_time AS condition_cd_end_dt,
                cc.nnd_ind,
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
            FROM [dbo].nrt_srte_CONDITION_CODE cc WITH (NOLOCk)
                LEFT JOIN dbo.nrt_srte_Program_area_code pac WITH (NOLOCk)
                    ON cc.prog_area_cd = pac.prog_area_cd
            WHERE cc.condition_cd IN (SELECT value FROM STRING_SPLIT(@condition_cd_list, ','))
        ),
        -- section for records containing only program area information
        pam_only AS (
            SELECT
                program_area_cd,
                program_area_desc
            FROM (SELECT DISTINCT program_area_cd, program_area_desc FROM condition_list) AS dist_pam
        ),
        cond_pam_union AS (
            SELECT 
                condition_cd,
                condition_desc, 
                condition_short_nm, 
                condition_cd_eff_dt, 
                condition_cd_end_dt, 
                nnd_ind, 
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
                NULL AS disease_grp_cd, 
                NULL AS disease_grp_desc,
                program_area_cd,
                program_area_desc, 
                NULL AS condition_cd_sys_cd_nm, 
                NULL AS assigning_authority_cd, 
                NULL AS assigning_authority_desc,
                NULL AS condition_cd_sys_cd
            FROM pam_only
        )
        SELECT 
            cu.condition_cd,
            cu.condition_desc, 
            cu.condition_short_nm, 
            cu.condition_cd_eff_dt, 
            cu.condition_cd_end_dt, 
            cu.nnd_ind, 
            condition_key,
            cu.disease_grp_cd, 
            cu.disease_grp_desc,
            cu.program_area_cd, 
            cu.program_area_desc,
            cu.condition_cd_sys_cd_nm, 
            cu.assigning_authority_cd, 
            cu.assigning_authority_desc,
            cu.condition_cd_sys_cd
        INTO #CONDITION_INIT
        FROM cond_pam_union cu
            LEFT JOIN dbo.nrt_condition_key ck
            ON COALESCE(ck.CONDITION_CD, '') = COALESCE(cu.CONDITION_CD, '')
                AND COALESCE(ck.PROGRAM_AREA_CD, '') = COALESCE(cu.PROGRAM_AREA_CD, '');


        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

        IF @debug = 'true'
            SELECT * FROM #CONDITION_INIT;


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'UPDATE dbo.nrt_condition_key';




        SELECT @ROWCOUNT_NO = @@ROWCOUNT; 


        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_name, @RowCount_no);


--------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);
    
-------------------------------------------------------------------------------------------
    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
            DECLARE @FullErrorMessage VARCHAR(8000) =
                'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
                'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error Message: ' + ERROR_MESSAGE();


            INSERT INTO [dbo].[job_flow_log] 
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);

        return -1 ;

    END CATCH

END;

