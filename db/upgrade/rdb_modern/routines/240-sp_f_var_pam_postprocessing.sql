CREATE OR ALTER PROCEDURE [dbo].[sp_f_var_pam_postprocessing] 
    @phc_id_list nvarchar(max),
    @debug bit = 'false'
AS
BEGIN

    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) AS BIGINT);
    PRINT @batch_id;
    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT= 0;
    DECLARE @Proc_Step_Name VARCHAR(200)= '';
	DECLARE @Dataflow_Name VARCHAR(200) = 'F_VAR_PAM POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_f_var_pam_postprocessing';

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
            , LEFT('ID List-' + @phc_id_list, 500));


        IF EXISTS  (
            SELECT PORT_REQ_IND_CD 
            FROM [dbo].nrt_srte_condition_code with (nolock) 
            WHERE condition_cd = '10030' AND PORT_REQ_IND_CD = 'T'
        )
        BEGIN
	
            --------------------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #F_S_VAR_PAM';

            IF OBJECT_ID('tempdb..#F_S_VAR_PAM') IS NOT NULL
            DROP TABLE #F_S_VAR_PAM;
            
            SELECT
                CAST(I.nac_page_case_uid AS BIGINT) AS VAR_PAM_UID,
                I.nac_last_chg_time AS LAST_CHG_TIME,
                MAX(I.investigator_id) AS PROVIDER_UID,
                MAX(I.org_as_reporter_uid) AS ORG_AS_REPORTER_UID,
                MAX(I.hospital_uid) AS HOSPITAL_UID,
                MAX(I.person_as_reporter_uid) AS PERSON_AS_REPORTER_UID,
                MAX(I.patient_id) AS PERSON_UID,
                MAX(I.physician_id) AS PHYSICIAN_UID
            INTO #F_S_VAR_PAM
            FROM [dbo].nrt_investigation I WITH (NOLOCK) 
            INNER JOIN (SELECT TRIM(value) AS value FROM STRING_SPLIT(@phc_id_list, ',')) nu ON nu.value = I.public_health_case_uid
            WHERE 
                I.investigation_form_cd='INV_FORM_VAR'
                AND I.patient_id IS NOT NULL
            GROUP BY I.nac_page_case_uid, I.nac_last_chg_time
            ORDER BY I.nac_page_case_uid

        
            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #F_S_VAR_PAM;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
            
            -------------------------------------------------------------------------------------------------------
            
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #PAT_VAR_keystore';

                IF OBJECT_ID('tempdb..#PAT_VAR_keystore') IS NOT NULL
                DROP TABLE #PAT_VAR_keystore;

            -- PAT_VAR_keystore
            SELECT 
                f.VAR_PAM_UID,
                f.PERSON_UID,
                d.PATIENT_KEY,
                f.PROVIDER_UID,
                f.PHYSICIAN_UID             
            INTO #PAT_VAR_keystore  
            FROM [dbo].D_PATIENT d WITH (NOLOCK) 
            INNER JOIN #F_S_VAR_PAM f
                ON f.PERSON_UID = d.PATIENT_UID;  

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #PAT_VAR_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            ---------------------------------------------------------------------------------------------------------------------   
            
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #PAT_VAR_PROV_keystore';

            IF OBJECT_ID('tempdb..#PAT_VAR_PROV_keystore') IS NOT NULL
                DROP TABLE #PAT_VAR_PROV_keystore;

            ;WITH CTE_PAT_VAR_PROV1_keystore AS (
                SELECT 
                    v.VAR_PAM_UID,
                    v.PERSON_UID,
                    v.PATIENT_KEY,
                    v.PHYSICIAN_UID,
                    v.PROVIDER_UID,
                    COALESCE(p.PROVIDER_KEY, 1) AS PROVIDER_KEY
                FROM #PAT_VAR_keystore v
                LEFT JOIN [dbo].D_PROVIDER p WITH (NOLOCK) 
                ON v.PROVIDER_UID = p.PROVIDER_uid
            ),
            CTE_PAT_VAR_PROV2_keystore_raw AS (
                SELECT 
                    b.VAR_PAM_UID,
                    b.PERSON_UID,
                    b.PATIENT_KEY,
                    b.PROVIDER_UID,
                    b.PROVIDER_KEY,
                    COALESCE(p.PROVIDER_key, 1) AS PHYSICIAN_KEY
                FROM  CTE_PAT_VAR_PROV1_keystore b
                LEFT JOIN [dbo].D_PROVIDER p WITH (NOLOCK)
                ON b.PHYSICIAN_UID = p.PROVIDER_uid
            ),
            CTE_PAT_VAR_PROV2_keystore AS (
                SELECT 
                    VAR_PAM_UID,
                    PERSON_UID,
                    PATIENT_KEY,
                    PROVIDER_UID,
                    PROVIDER_KEY,
                    PHYSICIAN_KEY,
                    ROW_NUMBER() OVER (PARTITION BY VAR_PAM_UID ORDER BY VAR_PAM_UID) as rn
                FROM CTE_PAT_VAR_PROV2_keystore_raw
            )
            SELECT 
                VAR_PAM_UID,
                PERSON_UID,
                PATIENT_KEY,
                PROVIDER_UID,
                PROVIDER_KEY,
                PHYSICIAN_KEY
            INTO #PAT_VAR_PROV_keystore
            FROM CTE_PAT_VAR_PROV2_keystore
            WHERE rn = 1;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #PAT_VAR_PROV_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            ---------------------------------------------------------------------------------------------------------------------   

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_RASH_LOC_GEN';

            IF OBJECT_ID('tempdb..#D_RASH_LOC_GEN') IS NOT NULL
                DROP TABLE #D_RASH_LOC_GEN;

            -- Create temporary tables for distinct group keys
            SELECT DISTINCT D.D_RASH_LOC_GEN_GROUP_KEY, D.VAR_PAM_UID 
            INTO #D_RASH_LOC_GEN
            FROM [dbo].D_RASH_LOC_GEN D WITH (NOLOCK)
            INNER JOIN #F_S_VAR_PAM S ON S.VAR_PAM_UID = D.VAR_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_RASH_LOC_GEN;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------------------- 

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_PCR_SOURCE';

            IF OBJECT_ID('tempdb..#D_PCR_SOURCE') IS NOT NULL
                DROP TABLE #D_PCR_SOURCE;

            -- Create temporary tables for distinct group keys
            SELECT DISTINCT D.D_PCR_SOURCE_GROUP_KEY, D.VAR_PAM_UID 
            INTO #D_PCR_SOURCE
            FROM [dbo].D_PCR_SOURCE D WITH (NOLOCK)
            INNER JOIN #F_S_VAR_PAM S ON S.VAR_PAM_UID = D.VAR_PAM_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_PCR_SOURCE;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------------------- 

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #HOSPITAL_UID_keystore';

            IF OBJECT_ID('tempdb..#HOSPITAL_UID_keystore') IS NOT NULL
                DROP TABLE #HOSPITAL_UID_keystore;
            
            -- HOSPITAL_UID_keystore
            SELECT 
                f.VAR_PAM_UID, 
                f.HOSPITAL_UID, 
                COALESCE(o.ORGANIZATION_KEY, 1) as HOSPITAL_KEY
            INTO #HOSPITAL_UID_keystore    
            FROM #F_S_VAR_PAM f
            LEFT JOIN [dbo].D_ORGANIZATION o WITH (NOLOCK)
            ON f.HOSPITAL_UID = o.ORGANIZATION_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #HOSPITAL_UID_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------------------- 

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #ORG_AS_REPORTER_UID_keystore';

            IF OBJECT_ID('tempdb..#ORG_AS_REPORTER_UID_keystore') IS NOT NULL
                DROP TABLE #ORG_AS_REPORTER_UID_keystore;

            -- ORG_AS_REPORTER_UID_keystore
            SELECT 
                f.VAR_PAM_UID, 
                f.ORG_AS_REPORTER_UID, 
                COALESCE(o.ORGANIZATION_KEY, 1) as ORG_AS_REPORTER_KEY
            INTO #ORG_AS_REPORTER_UID_keystore    
            FROM #F_S_VAR_PAM f
            LEFT JOIN [dbo].D_ORGANIZATION o WITH (NOLOCK)
            ON f.ORG_AS_REPORTER_UID = o.organization_UID;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #ORG_AS_REPORTER_UID_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------------------- 

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #PERSON_AS_REPORTER_keystore';

            IF OBJECT_ID('tempdb..#PERSON_AS_REPORTER_keystore') IS NOT NULL
                DROP TABLE #PERSON_AS_REPORTER_keystore;
            
            -- PERSON_AS_REPORTER_keystore
            SELECT 
                f.VAR_PAM_UID, 
                f.PERSON_AS_REPORTER_UID, 
                COALESCE(p.PROVIDER_KEY, 1) as PERSON_AS_REPORTER_KEY
            INTO #PERSON_AS_REPORTER_keystore    
            FROM #F_S_VAR_PAM f
            LEFT JOIN [dbo].D_PROVIDER p
            ON f.PERSON_AS_REPORTER_UID = p.PROVIDER_uid;

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #PERSON_AS_REPORTER_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            --------------------------------------------------------------------------------------------------------------------- 

            BEGIN TRANSACTION

                SET
                    @PROC_STEP_NO = @PROC_STEP_NO + 1;
                SET
                    @PROC_STEP_NAME = 'DELETE INCOMING RECORDS FROM F_VAR_PAM';

                IF OBJECT_ID('tempdb..#F_VAR_PAM_D') IS NOT NULL
                    DROP TABLE #F_VAR_PAM_D;

                SELECT 
                    F.*
                INTO #F_VAR_PAM_D
                FROM [dbo].F_VAR_PAM F 
                INNER JOIN [dbo].D_VAR_PAM D WITH (NOLOCK) ON D.D_VAR_PAM_KEY = F.D_VAR_PAM_KEY 
                INNER JOIN #F_S_VAR_PAM S ON S.VAR_PAM_UID = D.VAR_PAM_UID

                DELETE F
                FROM [dbo].F_VAR_PAM F 
                INNER JOIN [dbo].D_VAR_PAM D WITH (NOLOCK) ON D.D_VAR_PAM_KEY = F.D_VAR_PAM_KEY 
                INNER JOIN #F_S_VAR_PAM S ON S.VAR_PAM_UID = D.VAR_PAM_UID

                SELECT @RowCount_no = @@ROWCOUNT;

                IF
                    @debug = 'true'
                    SELECT @Proc_Step_Name AS step, *
                    FROM #F_VAR_PAM_D;

                INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
                VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

            COMMIT TRANSACTION;
            
            -------------------------------------------------------------------------------------------

            BEGIN TRANSACTION

                SET
                    @PROC_STEP_NO = @PROC_STEP_NO + 1;
                SET
                    @PROC_STEP_NAME = 'INSERT INCOMING RECORDS TO F_VAR_PAM';

                    IF OBJECT_ID('tempdb..#F_VAR_PAM_I') IS NOT NULL
                        DROP TABLE #F_VAR_PAM_I;

                SELECT 
                    r.D_RASH_LOC_GEN_GROUP_KEY, 
                    p.D_PCR_SOURCE_GROUP_KEY, 
                    k.VAR_PAM_UID, 
                    k.patient_key AS PERSON_KEY, 
                    k.PHYSICIAN_KEY,
                    k.PROVIDER_UID, 
                    k.provider_key AS D_PERSON_RACE_GROUP_KEY, 
                    k.PROVIDER_KEY, 
                    pr.PERSON_AS_REPORTER_KEY,
                    ro.ORG_AS_REPORTER_KEY,
                    h.HOSPITAL_KEY,
                    v.D_VAR_PAM_KEY,
                    inv.INVESTIGATION_KEY,
                    d1.date_key as ADD_DATE_KEY, 
                    d2.date_key as LAST_CHG_DATE_KEY
                INTO #F_VAR_PAM_I
                FROM #D_RASH_LOC_GEN r
                JOIN #PAT_VAR_PROV_keystore k 
                    ON r.VAR_PAM_UID = k.VAR_PAM_UID 
                JOIN #D_PCR_SOURCE p 
                    ON k.VAR_PAM_UID = p.VAR_PAM_UID 
                JOIN [dbo].D_VAR_PAM v WITH (NOLOCK)
                    ON k.VAR_PAM_UID = v.VAR_PAM_UID 
                JOIN #HOSPITAL_UID_keystore h 
                    ON k.VAR_PAM_UID = h.VAR_PAM_UID 
                JOIN #ORG_AS_REPORTER_UID_keystore ro 
                    ON k.VAR_PAM_UID = ro.VAR_PAM_UID 
                JOIN #PERSON_AS_REPORTER_keystore pr 
                    ON k.VAR_PAM_UID = pr.VAR_PAM_UID 
                JOIN [dbo].INVESTIGATION inv WITH (NOLOCK)
                    ON inv.CASE_UID = v.VAR_PAM_UID                 
                LEFT JOIN [dbo].RDB_DATE d1 WITH (NOLOCK)   
                    ON CONVERT(date, d1.DATE_MM_DD_YYYY) = CONVERT(date, inv.ADD_TIME)
                LEFT JOIN [dbo].RDB_DATE d2 WITH (NOLOCK)
                    ON CONVERT(date, d2.DATE_MM_DD_YYYY) = CONVERT(date, inv.LAST_CHG_TIME);

                INSERT INTO [dbo].F_VAR_PAM (
                    PERSON_KEY,
                    D_VAR_PAM_KEY,
                    PROVIDER_KEY,
                    D_PCR_SOURCE_GROUP_KEY,
                    D_RASH_LOC_GEN_GROUP_KEY,
                    HOSPITAL_KEY,
                    ORG_AS_REPORTER_KEY,
                    PERSON_AS_REPORTER_KEY,
                    PHYSICIAN_KEY,
                    ADD_DATE_KEY,
                    LAST_CHG_DATE_KEY,
                    INVESTIGATION_KEY
                    )
                    SELECT 
                        PERSON_KEY,
                        D_VAR_PAM_KEY,
                        PROVIDER_KEY,
                        D_PCR_SOURCE_GROUP_KEY,
                        D_RASH_LOC_GEN_GROUP_KEY,
                        HOSPITAL_KEY,
                        ORG_AS_REPORTER_KEY,
                        PERSON_AS_REPORTER_KEY,
                        PHYSICIAN_KEY,
                        ADD_DATE_KEY,
                        LAST_CHG_DATE_KEY,
                        INVESTIGATION_KEY
                    FROM #F_VAR_PAM_I

                SELECT @RowCount_no = @@ROWCOUNT;

                IF
                    @debug = 'true'
                    SELECT @Proc_Step_Name AS step, *
                    FROM #F_VAR_PAM_I;

                INSERT INTO [dbo].[job_flow_log]
                (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
                VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
                
            COMMIT TRANSACTION;          

            -------------------------------------------------------------------------------------------

        END

        -------------------------------------------------------------------------------------------

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




