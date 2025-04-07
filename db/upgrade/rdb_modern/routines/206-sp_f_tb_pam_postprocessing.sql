CREATE OR ALTER PROCEDURE [dbo].[sp_f_tb_pam_postprocessing] 
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
	DECLARE @Dataflow_Name VARCHAR(200) = 'F_TB_PAM POST-Processing';
	DECLARE @Package_Name VARCHAR(200) = 'sp_f_tb_pam_postprocessing';

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

--------------------------------------------------------------------------------------------------------

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'GENERATING #F_S_TB_PAM';

        IF OBJECT_ID('tempdb..#F_S_TB_PAM') IS NOT NULL
        DROP TABLE #F_S_TB_PAM;
		
        SELECT
            CAST(I.nac_page_case_uid AS BIGINT) AS TB_PAM_UID,
            I.nac_last_chg_time AS LAST_CHG_TIME,
            MAX(I.investigator_id) AS PROVIDER_UID,
            MAX(I.org_as_reporter_uid) AS ORG_AS_REPORTER_UID,
            MAX(I.hospital_uid) AS HOSPITAL_UID,
            MAX(I.person_as_reporter_uid) AS PERSON_AS_REPORTER_UID,
            MAX(I.patient_id) AS PERSON_UID,
            MAX(I.physician_id) AS PHYSICIAN_UID
        INTO #F_S_TB_PAM
        FROM [dbo].nrt_investigation I WITH (NOLOCK) 
        INNER JOIN (SELECT TRIM(value) FROM STRING_SPLIT(@phc_id_list, ',')) nu ON nu.value = I.public_health_case_uid
        WHERE 
            I.investigation_form_cd='INV_FORM_RVCT'
            AND I.patient_id IS NOT NULL
        GROUP BY I.nac_page_case_uid, I.nac_last_chg_time
        ORDER BY I.nac_page_case_uid

        SELECT @RowCount_no = @@ROWCOUNT;

        IF
            @debug = 'true'
            SELECT @Proc_Step_Name AS step, *
            FROM #F_S_TB_PAM;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
--------------------------------------------------------------------------------------------------------
        
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #PAT_keystore';

             IF OBJECT_ID('tempdb..#PAT_keystore') IS NOT NULL
                DROP TABLE #PAT_keystore;

            -- PAT_keystore
            SELECT 
                f.TB_PAM_UID,
                f.PERSON_UID,
                d.PATIENT_KEY AS patient_key,
                f.PROVIDER_UID
            INTO #PAT_keystore  
            FROM [dbo].D_PATIENT d WITH (NOLOCK) 
            INNER JOIN #F_S_TB_PAM f
                ON f.PERSON_UID = d.PATIENT_UID;  

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #PAT_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

---------------------------------------------------------------------------------------------------------------------        

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #PAT_prov_keystore';

            IF OBJECT_ID('#PAT_prov_keystore', 'U') IS NOT NULL
                DROP TABLE #PAT_prov_keystore;

            SELECT DISTINCT
                k.TB_PAM_UID,
                k.PERSON_UID,
                k.PATIENT_KEY,
                k.PROVIDER_UID,
                COALESCE(p.PROVIDER_KEY, 1) AS PROVIDER_KEY
            INTO #PAT_prov_keystore  
            FROM #PAT_keystore k
            LEFT JOIN [dbo].D_PROVIDER p WITH (NOLOCK) 
                ON k.PROVIDER_UID = p.PROVIDER_UID;

            --CREATE NONCLUSTERED INDEX IX_PAT_prov_keystore_TB_PAM_UID ON #PAT_prov_keystore (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #PAT_prov_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_MOVE_STATE';

            IF OBJECT_ID('tempdb..#D_MOVE_STATE') IS NOT NULL
                DROP TABLE #D_MOVE_STATE;

            -- Create temporary tables for distinct group keys
            SELECT DISTINCT D.D_MOVE_STATE_GROUP_KEY, D.TB_PAM_UID
            INTO #D_MOVE_STATE  
            FROM [dbo].D_MOVE_STATE D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;
            
            --CREATE NONCLUSTERED INDEX IX_D_MOVE_STATE_TB_PAM_UID ON #D_MOVE_STATE (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_MOVE_STATE;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_HC_PROV_TY_3';

            IF OBJECT_ID('tempdb..#D_HC_PROV_TY_3') IS NOT NULL
                DROP TABLE #D_HC_PROV_TY_3;

            SELECT DISTINCT D.D_HC_PROV_TY_3_GROUP_KEY, D.TB_PAM_UID
            INTO #D_HC_PROV_TY_3  
            FROM [dbo].D_HC_PROV_TY_3 D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;
            
            --CREATE NONCLUSTERED INDEX IX_D_HC_PROV_TY_3_TB_PAM_UID ON #D_HC_PROV_TY_3 (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_HC_PROV_TY_3;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        

-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_DISEASE_SITE';

            IF OBJECT_ID('tempdb..#D_DISEASE_SITE') IS NOT NULL
                DROP TABLE #D_DISEASE_SITE;

            SELECT DISTINCT D.D_DISEASE_SITE_GROUP_KEY, D.TB_PAM_UID
            INTO #D_DISEASE_SITE  
            FROM [dbo].D_DISEASE_SITE D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;
            
            --CREATE NONCLUSTERED INDEX IX_D_DISEASE_SITE_TB_PAM_UID ON #D_DISEASE_SITE (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_DISEASE_SITE;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_ADDL_RISK';

            IF OBJECT_ID('tempdb..#D_ADDL_RISK') IS NOT NULL
                DROP TABLE #D_ADDL_RISK;

            SELECT DISTINCT D.D_ADDL_RISK_GROUP_KEY, D.TB_PAM_UID
            INTO #D_ADDL_RISK  
            FROM [dbo].D_ADDL_RISK D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;
            
            --CREATE NONCLUSTERED INDEX IX_D_ADDL_RISK_TB_PAM_UID ON #D_ADDL_RISK (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_ADDL_RISK;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_MOVE_CNTY';
    
    
           IF OBJECT_ID('tempdb..#D_MOVE_CNTY') IS NOT NULL
                DROP TABLE #D_MOVE_CNTY;

            SELECT DISTINCT D.D_MOVE_CNTY_GROUP_KEY, D.TB_PAM_UID
            INTO #D_MOVE_CNTY  
            FROM [dbo].D_MOVE_CNTY D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;

            --CREATE NONCLUSTERED INDEX IX_D_MOVE_CNTY_TB_PAM_UID ON #D_MOVE_CNTY (TB_PAM_UID);
    
            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_MOVE_CNTY;
    
            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @dataflow_name, @package_name, 'START', @Proc_Step_no, @Proc_Step_Name,
                    @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_GT_12_REAS';

            IF OBJECT_ID('tempdb..#D_GT_12_REAS') IS NOT NULL
                DROP TABLE #D_GT_12_REAS;

            SELECT DISTINCT D.D_GT_12_REAS_GROUP_KEY, D.TB_PAM_UID
            INTO #D_GT_12_REAS  
            FROM [dbo].D_GT_12_REAS D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;

            --CREATE NONCLUSTERED INDEX IX_D_GT_12_REAS_TB_PAM_UID ON #D_GT_12_REAS (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_GT_12_REAS;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_MOVE_CNTRY';

            IF OBJECT_ID('tempdb..#D_MOVE_CNTRY') IS NOT NULL
                DROP TABLE #D_MOVE_CNTRY;

            SELECT DISTINCT D.D_MOVE_CNTRY_GROUP_KEY, D.TB_PAM_UID
            INTO #D_MOVE_CNTRY  
            FROM [dbo].D_MOVE_CNTRY D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;

            --CREATE NONCLUSTERED INDEX IX_D_MOVE_CNTRY_TB_PAM_UID ON #D_MOVE_CNTRY (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_MOVE_CNTRY;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_MOVED_WHERE';

            IF OBJECT_ID('tempdb..#D_MOVED_WHERE') IS NOT NULL
                DROP TABLE #D_MOVED_WHERE;

            SELECT DISTINCT D.D_MOVED_WHERE_GROUP_KEY, D.TB_PAM_UID
            INTO #D_MOVED_WHERE  
            FROM [dbo].D_MOVED_WHERE D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;

            --CREATE NONCLUSTERED INDEX IX_D_MOVED_WHERE_TB_PAM_UID ON #D_MOVED_WHERE (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_MOVED_WHERE;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_SMR_EXAM_TY';

            IF OBJECT_ID('tempdb..#D_SMR_EXAM_TY') IS NOT NULL
                DROP TABLE #D_SMR_EXAM_TY;

            SELECT DISTINCT D.D_SMR_EXAM_TY_GROUP_KEY, D.TB_PAM_UID
            INTO #D_SMR_EXAM_TY  
            FROM [dbo].D_SMR_EXAM_TY D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;

            --CREATE NONCLUSTERED INDEX IX_D_SMR_EXAM_TY_TB_PAM_UID ON #D_SMR_EXAM_TY (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_SMR_EXAM_TY;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #D_OUT_OF_CNTRY';

            IF OBJECT_ID('tempdb..#D_OUT_OF_CNTRY') IS NOT NULL
                DROP TABLE #D_OUT_OF_CNTRY;

            SELECT DISTINCT D.D_OUT_OF_CNTRY_GROUP_KEY, D.TB_PAM_UID
            INTO #D_OUT_OF_CNTRY  
            FROM [dbo].D_OUT_OF_CNTRY D WITH (NOLOCK)
            INNER JOIN #F_S_TB_PAM S on S.TB_PAM_UID = D.TB_PAM_UID;

            --CREATE NONCLUSTERED INDEX IX_D_OUT_OF_CNTRY_TB_PAM_UID ON #D_OUT_OF_CNTRY (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;
            
            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #D_OUT_OF_CNTRY;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #HOSPITAL_UID_keystore';

            IF OBJECT_ID('tempdb..#HOSPITAL_UID_keystore') IS NOT NULL
                DROP TABLE #HOSPITAL_UID_keystore;

            -- hospital_uid_keystore
            SELECT 
                f.TB_PAM_UID,
                f.HOSPITAL_UID,
                COALESCE(o.ORGANIZATION_KEY, 1) AS HOSPITAL_KEY
            INTO #HOSPITAL_UID_keystore  
            FROM #F_S_TB_PAM f
            LEFT OUTER JOIN [dbo].D_ORGANIZATION o WITH (NOLOCK)
                ON f.HOSPITAL_UID = o.ORGANIZATION_UID;

            --CREATE NONCLUSTERED INDEX IX_HOSPITAL_UID_keystore_TB_PAM_UID ON #HOSPITAL_UID_keystore (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;
                
            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #HOSPITAL_UID_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------
        
            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #ORG_AS_REPORTER_UID_keystore';

            IF OBJECT_ID('tempdb..#ORG_AS_REPORTER_UID_keystore') IS NOT NULL
                DROP TABLE #ORG_AS_REPORTER_UID_keystore;

            -- org_as_reporter_uid_keystore
            SELECT 
                f.TB_PAM_UID,
                f.ORG_AS_REPORTER_UID,
                COALESCE(o.ORGANIZATION_KEY, 1) AS ORG_AS_REPORTER_KEY
            INTO #ORG_AS_REPORTER_UID_keystore  
            FROM #F_S_TB_PAM f
            LEFT OUTER JOIN [dbo].D_ORGANIZATION o WITH (NOLOCK)
                ON f.ORG_AS_REPORTER_UID = o.ORGANIZATION_UID;

            --CREATE NONCLUSTERED INDEX IX_ORG_AS_REPORTER_UID_keystore_TB_PAM_UID ON #ORG_AS_REPORTER_UID_keystore (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #ORG_AS_REPORTER_UID_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #PERSON_AS_REPORTER_keystore';

            IF OBJECT_ID('tempdb..#PERSON_AS_REPORTER_keystore') IS NOT NULL
                DROP TABLE #PERSON_AS_REPORTER_keystore;

            -- person_as_reporter_keystore
            SELECT 
                f.TB_PAM_UID,
                f.PERSON_AS_REPORTER_UID,
                COALESCE(p.PROVIDER_KEY, 1) AS PERSON_AS_REPORTER_KEY
            INTO #PERSON_AS_REPORTER_keystore  
            FROM #F_S_TB_PAM f
            LEFT OUTER JOIN [dbo].D_PROVIDER p
                ON f.PERSON_AS_REPORTER_UID = p.PROVIDER_UID;

            --CREATE NONCLUSTERED INDEX IX_PERSON_AS_REPORTER_keystore_TB_PAM_UID ON #PERSON_AS_REPORTER_keystore (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #PERSON_AS_REPORTER_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'GENERATING #PHYSICIAN_keystore';

            IF OBJECT_ID('tempdb..#PHYSICIAN_keystore') IS NOT NULL
                DROP TABLE #PHYSICIAN_keystore;

            -- PHYSICIAN_keystore
            SELECT 
                f.TB_PAM_UID,
                f.PHYSICIAN_UID,
                COALESCE(p.PROVIDER_KEY, 1) AS PHYSICIAN_KEY
            INTO #PHYSICIAN_keystore  
            FROM #F_S_TB_PAM f
            LEFT OUTER JOIN [dbo].D_PROVIDER p
                ON f.PHYSICIAN_UID = p.PROVIDER_UID;

            --CREATE NONCLUSTERED INDEX IX_PHYSICIAN_keystore_TB_PAM_UID ON #PHYSICIAN_keystore (TB_PAM_UID);

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #PHYSICIAN_keystore;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

            SET
                @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
                @PROC_STEP_NAME = 'DELETE INCOMING RECORDS FROM F_TB_PAM';

            IF OBJECT_ID('tempdb..#F_TB_PAM_D') IS NOT NULL
                DROP TABLE #F_TB_PAM_D;

            SELECT 
                F.*
            INTO #F_TB_PAM_D
            FROM [dbo].F_TB_PAM F 
            INNER JOIN [dbo].D_TB_PAM D WITH (NOLOCK) ON D.D_TB_PAM_KEY = F.D_TB_PAM_KEY 
            INNER JOIN #F_S_TB_PAM S ON S.TB_PAM_UID = D.TB_PAM_UID

            DELETE F
            FROM [dbo].F_TB_PAM F 
            INNER JOIN [dbo].D_TB_PAM D WITH (NOLOCK) ON D.D_TB_PAM_KEY = F.D_TB_PAM_KEY 
            INNER JOIN #F_S_TB_PAM S ON S.TB_PAM_UID = D.TB_PAM_UID
        

            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #F_TB_PAM_D;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
-------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

        SET
            @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET
            @PROC_STEP_NAME = 'INSERT INCOMING RECORDS TO F_TB_PAM';

            IF OBJECT_ID('tempdb..#F_TB_PAM_I') IS NOT NULL
                DROP TABLE #F_TB_PAM_I;

            
            SELECT DISTINCT 
                k.PATIENT_KEY AS PERSON_KEY,
                tb.D_TB_PAM_KEY,
                k.PROVIDER_KEY,
                ms.D_MOVE_STATE_GROUP_KEY,
                hpt.D_HC_PROV_TY_3_GROUP_KEY,
                ds.D_DISEASE_SITE_GROUP_KEY,
                ar.D_ADDL_RISK_GROUP_KEY,
                mc.D_MOVE_CNTY_GROUP_KEY,
                gr.D_GT_12_REAS_GROUP_KEY,
                mct.D_MOVE_CNTRY_GROUP_KEY,
                mw.D_MOVED_WHERE_GROUP_KEY,
                oc.D_OUT_OF_CNTRY_GROUP_KEY,
                sety.D_SMR_EXAM_TY_GROUP_KEY,
                d1.date_key AS ADD_DATE_KEY,
                d2.date_key AS LAST_CHG_DATE_KEY,
                inv.INVESTIGATION_KEY,
                hk.HOSPITAL_KEY,
                ork.ORG_AS_REPORTER_KEY,
                prk.PERSON_AS_REPORTER_KEY,
                pk.PHYSICIAN_KEY
            INTO #F_TB_PAM_I    
            FROM #PAT_prov_keystore k 
            INNER JOIN #D_MOVE_STATE ms
                ON k.TB_PAM_UID = ms.TB_PAM_UID
            INNER JOIN #D_HC_PROV_TY_3 hpt 
                ON k.TB_PAM_UID = hpt.TB_PAM_UID
            INNER JOIN #D_DISEASE_SITE ds 
                ON k.TB_PAM_UID = ds.TB_PAM_UID
            INNER JOIN #D_ADDL_RISK ar 
                ON k.TB_PAM_UID = ar.TB_PAM_UID
            INNER JOIN #D_MOVE_CNTY mc 
                ON k.TB_PAM_UID = mc.TB_PAM_UID
            INNER JOIN #D_GT_12_REAS gr 
                ON k.TB_PAM_UID = gr.TB_PAM_UID
            INNER JOIN #D_MOVE_CNTRY mct 
                ON k.TB_PAM_UID = mct.TB_PAM_UID
            INNER JOIN #D_MOVED_WHERE mw 
                ON k.TB_PAM_UID = mw.TB_PAM_UID
            INNER JOIN #D_SMR_EXAM_TY sety 
                ON k.TB_PAM_UID = sety.TB_PAM_UID
            INNER JOIN #D_OUT_OF_CNTRY oc 
                ON k.TB_PAM_UID = oc.TB_PAM_UID
            INNER JOIN [dbo].D_TB_PAM tb WITH (NOLOCK)
                ON k.TB_PAM_UID = tb.TB_PAM_UID 
            INNER JOIN [dbo].INVESTIGATION inv WITH (NOLOCK)
                ON tb.TB_PAM_UID = inv.CASE_UID
            INNER JOIN [dbo].nrt_investigation i WITH (NOLOCK)
                ON tb.TB_PAM_UID = i.public_health_case_uid
            INNER JOIN #HOSPITAL_UID_keystore hk 
                ON k.TB_PAM_UID = hk.TB_PAM_UID
            INNER JOIN #ORG_AS_REPORTER_UID_keystore ork 
                ON k.TB_PAM_UID = ork.TB_PAM_UID
            INNER JOIN #PERSON_AS_REPORTER_keystore prk 
                ON k.TB_PAM_UID = prk.TB_PAM_UID
            INNER JOIN #PHYSICIAN_keystore pk 
                ON k.TB_PAM_UID = pk.TB_PAM_UID
            LEFT OUTER JOIN [dbo].RDB_DATE d1 WITH (NOLOCK) 
                ON CONVERT(DATE, d1.DATE_MM_DD_YYYY) = CONVERT(DATE, i.ADD_TIME)
            LEFT OUTER JOIN [dbo].RDB_DATE d2 WITH (NOLOCK) 
                ON CONVERT(DATE, d2.DATE_MM_DD_YYYY) = CONVERT(DATE, i.LAST_CHG_TIME);
                
            INSERT INTO [dbo].F_TB_PAM (
                PERSON_KEY,
                D_TB_PAM_KEY,
                PROVIDER_KEY,
                D_MOVE_STATE_GROUP_KEY,
                D_HC_PROV_TY_3_GROUP_KEY,
                D_DISEASE_SITE_GROUP_KEY,
                D_ADDL_RISK_GROUP_KEY,
                D_MOVE_CNTY_GROUP_KEY,
                D_GT_12_REAS_GROUP_KEY,
                D_MOVE_CNTRY_GROUP_KEY,
                D_MOVED_WHERE_GROUP_KEY,
                D_OUT_OF_CNTRY_GROUP_KEY,
                D_SMR_EXAM_TY_GROUP_KEY,
                ADD_DATE_KEY,
                LAST_CHG_DATE_KEY,
                INVESTIGATION_KEY,
                HOSPITAL_KEY,
                ORG_AS_REPORTER_KEY,
                PERSON_AS_REPORTER_KEY,
                PHYSICIAN_KEY
            )
            SELECT 
                PERSON_KEY,
                D_TB_PAM_KEY,
                PROVIDER_KEY,
                D_MOVE_STATE_GROUP_KEY,
                D_HC_PROV_TY_3_GROUP_KEY,
                D_DISEASE_SITE_GROUP_KEY,
                D_ADDL_RISK_GROUP_KEY,
                D_MOVE_CNTY_GROUP_KEY,
                D_GT_12_REAS_GROUP_KEY,
                D_MOVE_CNTRY_GROUP_KEY,
                D_MOVED_WHERE_GROUP_KEY,
                D_OUT_OF_CNTRY_GROUP_KEY,
                D_SMR_EXAM_TY_GROUP_KEY,
                ADD_DATE_KEY,
                LAST_CHG_DATE_KEY,
                INVESTIGATION_KEY,
                HOSPITAL_KEY,
                ORG_AS_REPORTER_KEY,
                PERSON_AS_REPORTER_KEY,
                PHYSICIAN_KEY
            FROM #F_TB_PAM_I


            SELECT @RowCount_no = @@ROWCOUNT;

            IF
                @debug = 'true'
                SELECT @Proc_Step_Name AS step, *
                FROM #F_TB_PAM_I;

            INSERT INTO [dbo].[job_flow_log]
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);
        
        COMMIT TRANSACTION;          
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


---------------------------------------------------END OF PROCEDURE---------------------------------------------------------------------
