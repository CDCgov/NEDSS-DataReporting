CREATE OR ALTER PROCEDURE dbo.sp_f_contact_record_case_postprocessing(
    @contact_uids NVARCHAR(MAX),
    @debug bit = 'false')
as

BEGIN

    DECLARE @RowCount_no INT;
    DECLARE @Proc_Step_no FLOAT = 0;
    DECLARE @Proc_Step_Name VARCHAR(200) = '';
    DECLARE @ColumnAdd_sql NVARCHAR(MAX) = '';
    DECLARE @DataAsset_nm NVARCHAR(100) = 'F_CONTACT_RECORD_CASE';




    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';
        DECLARE @batch_id bigint;
        SET @batch_id = cast((format(GETDATE(), 'yyMMddHHmmss')) AS bigint);

        if
	        @debug = 'true'
	        select @batch_id;


        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @DataAsset_nm, @DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);



        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #F_CRC_INIT_KEYS';

        SELECT
        	D_CONTACT_RECORD_KEY
        	,CONTACT_UID
        INTO #F_CRC_INIT_KEYS
        FROM dbo.NRT_CONTACT_KEY
        WHERE CONTACT_UID IN (SELECT value FROM STRING_SPLIT(@contact_uids, ',') );

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @DataAsset_nm, @DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_CRC_INIT_KEYS;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #F_CRC_INIT';

        SELECT
        	crsik.D_CONTACT_RECORD_KEY,

        	nc.CONTACT_ENTITY_PHC_UID,
        	coalesce(inv3.INVESTIGATION_KEY, 1) as CONTACT_INVESTIGATION_KEY,

			nc.CONTACT_ENTITY_UID,
			coalesce(pt2.PATIENT_KEY, 1) as CONTACT_KEY,

			nc.NAMED_DURING_INTERVIEW_UID,
			coalesce(intw.D_INTERVIEW_KEY, 1) as CONTACT_INTERVIEW_KEY,

			nc.SUBJECT_ENTITY_PHC_UID,
			coalesce(inv2.INVESTIGATION_KEY, 1) as SUBJECT_INVESTIGATION_KEY,

			nc.SUBJECT_ENTITY_UID,
			coalesce(pt3.PATIENT_KEY, 1) as SUBJECT_KEY,

			nc.THIRD_PARTY_ENTITY_PHC_UID,
			coalesce(inv1.INVESTIGATION_KEY, 1) as THIRD_PARTY_INVESTIGATION_KEY,

			nc.THIRD_PARTY_ENTITY_UID,
			coalesce(pt1.PATIENT_KEY, 1) as THIRD_PARTY_ENTITY_KEY,

			nc.CONTACT_EXPOSURE_SITE_UID,
			coalesce(org.ORGANIZATION_KEY, 1) as CONTACT_EXPOSURE_SITE_KEY,

			nc.PROVIDER_CONTACT_INVESTIGATOR_UID,
			coalesce(pv1.PROVIDER_KEY, 1) as CONTACT_INVESTIGATOR_KEY,

			nc.DISPOSITIONED_BY_UID,
			coalesce(pv2.PROVIDER_KEY, 1) as DISPOSITIONED_BY_KEY

        INTO #F_CRC_INIT
		FROM
			#F_CRC_INIT_KEYS crsik
		LEFT JOIN
			dbo.NRT_CONTACT nc on nc.CONTACT_UID = crsik.CONTACT_UID
		LEFT JOIN
			dbo.L_ORGANIZATION org on org.ORGANIZATION_UID  = nc.CONTACT_EXPOSURE_SITE_UID
		LEFT JOIN
			dbo.L_PROVIDER pv1 on pv1.PROVIDER_UID  = nc.PROVIDER_CONTACT_INVESTIGATOR_UID
		LEFT JOIN
			dbo.L_PROVIDER pv2 on pv2.PROVIDER_UID  = nc.DISPOSITIONED_BY_UID
		LEFT JOIN
			dbo.L_PATIENT pt1 on pt1.PATIENT_UID = nc.THIRD_PARTY_ENTITY_UID
		LEFT JOIN
			dbo.L_PATIENT pt2 on pt2.PATIENT_UID = nc.CONTACT_ENTITY_UID
		LEFT JOIN
			dbo.L_PATIENT pt3 on pt3.PATIENT_UID = nc.SUBJECT_ENTITY_UID
		LEFT JOIN
			dbo.INVESTIGATION inv1 on inv1.CASE_UID = nc.THIRD_PARTY_ENTITY_PHC_UID
		LEFT JOIN
			dbo.INVESTIGATION inv2 on inv2.CASE_UID = nc.SUBJECT_ENTITY_PHC_UID
		LEFT JOIN
			dbo.INVESTIGATION inv3 on inv2.CASE_UID = nc.CONTACT_ENTITY_PHC_UID
		LEFT JOIN
			dbo.L_INTERVIEW intw on intw.INTERVIEW_UID = nc.NAMED_DURING_INTERVIEW_UID
			;

        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @DataAsset_nm, @DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;

         if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_CRC_INIT;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' GENERATING #F_CRC_INIT_NEW';


        SELECT
        	init.D_CONTACT_RECORD_KEY,
            init.CONTACT_INVESTIGATION_KEY,
            init.CONTACT_KEY,
            init.CONTACT_INTERVIEW_KEY,
            init.SUBJECT_INVESTIGATION_KEY,
            init.SUBJECT_KEY,
            init.THIRD_PARTY_INVESTIGATION_KEY,
            init.THIRD_PARTY_ENTITY_KEY,
            init.CONTACT_EXPOSURE_SITE_KEY,
            init.CONTACT_INVESTIGATOR_KEY,
            init.DISPOSITIONED_BY_KEY
        INTO
        	#F_CRC_INIT_NEW
        FROM
        	#F_CRC_INIT init
        LEFT OUTER JOIN
        	dbo.F_CONTACT_RECORD_CASE fact ON fact.D_CONTACT_RECORD_KEY = init.D_CONTACT_RECORD_KEY
        WHERE
        	fact.D_CONTACT_RECORD_KEY is NULL ;

        if
            @debug = 'true'
            select @Proc_Step_Name as step, *
            from #F_CRC_INIT_NEW;


        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @DataAsset_nm, @DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;




        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' INSERT INTO F_CONTACT_RECORD_CASE';

        INSERT INTO dbo.F_CONTACT_RECORD_CASE (
            D_CONTACT_RECORD_KEY,
            CONTACT_INVESTIGATION_KEY,
            CONTACT_KEY,
            CONTACT_INTERVIEW_KEY,
            SUBJECT_INVESTIGATION_KEY,
            SUBJECT_KEY,
            THIRD_PARTY_INVESTIGATION_KEY,
            THIRD_PARTY_ENTITY_KEY,
            CONTACT_EXPOSURE_SITE_KEY,
            CONTACT_INVESTIGATOR_KEY,
            DISPOSITIONED_BY_KEY
        )
        SELECT
            D_CONTACT_RECORD_KEY,
            CONTACT_INVESTIGATION_KEY,
            CONTACT_KEY,
            CONTACT_INTERVIEW_KEY,
            SUBJECT_INVESTIGATION_KEY,
            SUBJECT_KEY,
            THIRD_PARTY_INVESTIGATION_KEY,
            THIRD_PARTY_ENTITY_KEY,
            CONTACT_EXPOSURE_SITE_KEY,
            CONTACT_INVESTIGATOR_KEY,
            DISPOSITIONED_BY_KEY
        FROM
            #F_CRC_INIT_NEW
        ;


        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

        INSERT INTO [DBO].[JOB_FLOW_LOG]
        (BATCH_ID, [DATAFLOW_NAME], [PACKAGE_NAME], [STATUS_TYPE], [STEP_NUMBER], [STEP_NAME], [ROW_COUNT])
        VALUES (@BATCH_ID, @DataAsset_nm, @DataAsset_nm, 'START', @PROC_STEP_NO, @PROC_STEP_NAME, @ROWCOUNT_NO);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @PROC_STEP_NAME = ' UPDATE F_CONTACT_RECORD_CASE';

        UPDATE fact
        SET
            fact.CONTACT_INVESTIGATION_KEY = crsik.CONTACT_INVESTIGATION_KEY,
            fact.CONTACT_KEY = crsik.CONTACT_KEY,
            fact.CONTACT_INTERVIEW_KEY = crsik.CONTACT_INTERVIEW_KEY,
            fact.SUBJECT_INVESTIGATION_KEY = crsik.SUBJECT_INVESTIGATION_KEY,
            fact.SUBJECT_KEY = crsik.SUBJECT_KEY,
            fact.THIRD_PARTY_INVESTIGATION_KEY = crsik.THIRD_PARTY_INVESTIGATION_KEY,
            fact.THIRD_PARTY_ENTITY_KEY = crsik.THIRD_PARTY_ENTITY_KEY,
            fact.CONTACT_EXPOSURE_SITE_KEY = crsik.CONTACT_EXPOSURE_SITE_KEY,
            fact.CONTACT_INVESTIGATOR_KEY = crsik.CONTACT_INVESTIGATOR_KEY,
            fact.DISPOSITIONED_BY_KEY = crsik.DISPOSITIONED_BY_KEY
        FROM dbo.F_CONTACT_RECORD_CASE fact
        INNER JOIN (
            SELECT *
            FROM #F_CRC_INIT
            WHERE D_CONTACT_RECORD_KEY NOT IN (SELECT D_CONTACT_RECORD_KEY FROM #F_CRC_INIT_NEW)
        ) crsik
        ON crsik.D_CONTACT_RECORD_KEY = fact.D_CONTACT_RECORD_KEY;


        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @DataAsset_nm, @DataAsset_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);


        COMMIT TRANSACTION;



        INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @DataAsset_nm, @DataAsset_nm, 'COMPLETE', 999, 'COMPLETE', 0);

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();


        INSERT INTO [dbo].[job_flow_log] ( batch_id
                                         , [Dataflow_Name]
                                         , [package_Name]
                                         , [Status_Type]
                                         , [step_number]
                                         , [step_name]
                                         , [Error_Description]
                                         , [row_count])
        VALUES ( @batch_id
               , 'D_CONTACT_RECORD'
               , 'D_CONTACT_RECORD'
               , 'ERROR'
               , @Proc_Step_no
               , 'ERROR - ' + @Proc_Step_name
               , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               , 0);


        return -1;

    END CATCH

END

    ;

