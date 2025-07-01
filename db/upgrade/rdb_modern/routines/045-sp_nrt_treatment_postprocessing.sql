IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_nrt_treatment_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_nrt_treatment_postprocessing]
END
GO 

CREATE PROCEDURE [dbo].[sp_nrt_treatment_postprocessing] 
       @treatment_uids nvarchar(max),
       @debug bit = 'false'
AS
BEGIN

	DECLARE @RowCount_no bigint;
	DECLARE @proc_step_no float = 0;
	DECLARE @proc_step_name varchar(200) = '';
	DECLARE @batch_id bigint;
	DECLARE @dataflow_name varchar(200) = 'Treatment POST-Processing';
	DECLARE @package_name varchar(200) = 'sp_nrt_treatment_postprocessing';

	SET @batch_id = cast((format(getdate(), 'yyMMddHHmmssffff')) as bigint);

    BEGIN TRY

		SET @Proc_Step_no = 1;
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
			, LEFT('ID List-' + @treatment_uids, 500));

       --------------------------------------------------------------------------------------------------------
		SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
		SET @PROC_STEP_NAME = 'GENERATING #treatment_uids';

		IF OBJECT_ID('#treatment_uids', 'U') IS NOT NULL
			DROP TABLE #treatment_uids;

		SELECT value AS treatment_uid
		INTO #treatment_uids
		FROM STRING_SPLIT(@treatment_uids, ',');

		SELECT @RowCount_no = @@ROWCOUNT;

		IF @debug = 'true'
			SELECT @Proc_Step_Name AS step, * 
			FROM #treatment_uids;

		INSERT INTO [dbo].[job_flow_log]
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
		VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

       --------------------------------------------------------------------------------------------------------

        SET @proc_step_name = 'Generating #treatment';
        SET @proc_step_no = @PROC_STEP_NO + 1;

		IF OBJECT_ID('#treatment', 'U') IS NOT NULL
			DROP TABLE #treatment;

        /* Temp treatment table creation */
        SELECT 
			nrt.treatment_uid                                            AS treatment_uid,
			nrt.local_id                                                 AS TREATMENT_LOCAL_ID,
			nrt.treatment_name                                           AS TREATMENT_NM,
			nrt.treatment_drug                                           AS TREATMENT_DRUG,
			nrt.treatment_dosage_strength                                AS TREATMENT_DOSAGE_STRENGTH,
			nrt.treatment_dosage_strength_unit                           AS TREATMENT_DOSAGE_STRENGTH_UNIT,
			nrt.treatment_frequency                                      AS TREATMENT_FREQUENCY,
			nrt.treatment_duration                                       AS TREATMENT_DURATION,
			nrt.treatment_duration_unit                                  AS TREATMENT_DURATION_UNIT,
			nrt.treatment_comments                                       AS TREATMENT_COMMENTS,
			nrt.treatment_route                                          AS TREATMENT_ROUTE,
			CASE WHEN nrt.cd = 'OTH' THEN nrt.treatment_name ELSE '' END AS CUSTOM_TREATMENT,
			nrt.treatment_shared_ind                                     AS TREATMENT_SHARED_IND,
			nrt.treatment_oid                                            AS TREATMENT_OID,
			nrt.record_status_cd                                         AS RECORD_STATUS_CD,
			tk.d_treatment_key                                           AS TREATMENT_KEY,
			nrt.morbidity_uid,
			nrt.organization_uid,
			nrt.patient_treatment_uid,
			nrt.provider_uid,
			nrt.treatment_date,
			nrt.public_health_case_uid
        INTO #treatment
        FROM (SELECT 
				t.treatment_uid,
				t.organization_uid,
				t.provider_uid,
				t.patient_treatment_uid,
				t.treatment_name,
				t.Treatment_oid,
				t.Treatment_comments,
				t.Treatment_shared_ind,
				t.cd,
				t.treatment_date,
				t.Treatment_drug,
				t.treatment_drug_name,
				t.Treatment_dosage_strength,
				t.Treatment_dosage_strength_unit,
				t.Treatment_frequency,
				t.Treatment_duration,
				t.Treatment_duration_unit,
				t.Treatment_route,
				t.LOCAL_ID,
				t.record_status_cd,
				t.ADD_TIME,
				t.ADD_USER_ID,
				t.last_change_time,
				t.last_change_user_id,
				t.version_control_number,
				t.refresh_datetime,
				t.max_datetime,
				t.morbidity_uid,
				t.associated_phc_uids,
				CAST(phc.value AS BIGINT)  AS public_health_case_uid
			FROM dbo.nrt_treatment t WITH (NOLOCK)
			INNER JOIN #treatment_uids uids
				ON uids.treatment_uid = t.treatment_uid
			OUTER APPLY STRING_SPLIT(t.associated_phc_uids, ',') AS phc) nrt
			LEFT JOIN dbo.nrt_treatment_key tk WITH (NOLOCK)
				ON nrt.treatment_uid = tk.treatment_uid
				AND COALESCE(nrt.public_health_case_uid, 1) = COALESCE(tk.public_health_case_uid, 1)

		declare @backfill_list nvarchar(max);  
        SET @backfill_list = 
            ( 
              SELECT string_agg(t.value, ',')
              FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@treatment_uids, ',')) t
                        left join #treatment tmp
                        on tmp.treatment_uid = t.value	
                        WHERE tmp.treatment_uid is null	
            );

          IF @backfill_list IS NOT NULL
               BEGIN
                    EXECUTE dbo.sp_nrt_backfill_postprocessing 
                    @entity_type = 'TREATMENT',
                    @record_uid_list = @treatment_uids,
                    @rdb_table_map = NULL,
                    @batch_id = @batch_id,
                    @err_description = 'Missing NRT Record: sp_nrt_treatment_postprocessing',
                    @status_cd  = 'READY',
                    @retry_count = 0
               RETURN;
          END  
		
		SELECT @RowCount_no = @@ROWCOUNT;

        IF @debug = 'true' 
			SELECT @proc_step_name AS step, * 
			FROM #treatment;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		--------------------------------------------------------------------------------------------------------

		SET @proc_step_name = 'Generating #treatment_event';
        SET @proc_step_no = @PROC_STEP_NO + 1;

		IF OBJECT_ID('#treatment_event', 'U') IS NOT NULL
			DROP TABLE #treatment_event;

        /* Temp treatment_event table creation */
        SELECT 
			nrt.treatment_uid                  AS TREATMENT_UID,
			COALESCE(dtt.DATE_KEY, 1)          AS TREATMENT_DT_KEY,
			COALESCE(p.PATIENT_KEY, 1)         AS PATIENT_KEY,
			COALESCE(org.ORGANIZATION_KEY, 1)  AS TREATMENT_PROVIDING_ORG_KEY,
			COALESCE(prv.PROVIDER_KEY, 1)      AS TREATMENT_PHYSICIAN_KEY,
			1                                  AS TREATMENT_COUNT,
			trt.TREATMENT_KEY,
			COALESCE(mrb.MORB_RPT_KEY, 1)      AS MORB_RPT_KEY,
			COALESCE(inv.INVESTIGATION_KEY, 1) AS INVESTIGATION_KEY,
			COALESCE(cnd.CONDITION_KEY, 1)     AS CONDITION_KEY,
			COALESCE(ldf.LDF_GROUP_KEY, 1)     AS LDF_GROUP_KEY,
			nrt.record_status_cd               AS RECORD_STATUS_CD,
			nrt.public_health_case_uid
        INTO #treatment_event
        FROM #treatment nrt
		LEFT JOIN dbo.TREATMENT trt WITH (NOLOCK) 
			ON trt.TREATMENT_KEY = nrt.treatment_key
		LEFT JOIN dbo.INVESTIGATION inv WITH (NOLOCK)
			ON nrt.public_health_case_uid = inv.CASE_UID
		LEFT JOIN dbo.nrt_investigation nrt_inv WITH (NOLOCK)
			ON nrt.public_health_case_uid = nrt_inv.public_health_case_uid
		LEFT JOIN dbo.v_condition_dim cnd WITH (NOLOCK) 
			ON nrt_inv.cd = cnd.CONDITION_CD
		LEFT JOIN dbo.D_PATIENT p WITH (NOLOCK) 
			ON nrt.patient_treatment_uid = p.PATIENT_UID
		LEFT JOIN dbo.D_ORGANIZATION org WITH (NOLOCK)
			ON nrt.organization_uid = org.ORGANIZATION_UID
		LEFT JOIN dbo.D_PROVIDER prv WITH (NOLOCK) 
			ON nrt.provider_uid = prv.PROVIDER_UID
		LEFT JOIN dbo.RDB_DATE dtt WITH (NOLOCK) 
			ON CAST(nrt.treatment_date AS DATE) = dtt.DATE_MM_DD_YYYY
		LEFT JOIN dbo.MORBIDITY_REPORT mrb WITH (NOLOCK)
			ON nrt.morbidity_uid = mrb.MORB_RPT_UID
		LEFT JOIN dbo.LDF_GROUP ldf WITH (NOLOCK)
			ON nrt.treatment_uid = ldf.business_object_uid

        SELECT @RowCount_no = @@ROWCOUNT;
		
		IF @debug = 'true' 
			SELECT @proc_step_name AS step, * 
			FROM #treatment_event;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		--------------------------------------------------------------------------------------------------------

        SET @proc_step_name = 'Get old treatment keys';
        SET @proc_step_no =  @PROC_STEP_NO + 1;

		IF OBJECT_ID('#OLD_TREATMENT_KEYS', 'U') IS NOT NULL
			DROP TABLE #OLD_TREATMENT_KEYS;

        SELECT
        	trk.D_TREATMENT_KEY AS TREATMENT_KEY
        INTO #OLD_TREATMENT_KEYS
        FROM dbo.nrt_treatment_key trk WITH (NOLOCK)
		INNER JOIN #treatment_uids uids
				ON uids.treatment_uid = trk.treatment_uid
		WHERE 
			D_TREATMENT_KEY NOT IN (SELECT COALESCE(TREATMENT_KEY, 1) FROM #treatment);

        SELECT @RowCount_no = @@ROWCOUNT;

		IF @debug = 'true' 
			SELECT @proc_step_name AS step, * 
			FROM #OLD_TREATMENT_KEYS;

		INSERT INTO [dbo].[job_flow_log]
        (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        --------------------------------------------------------------------------------------------------------       

        BEGIN TRANSACTION
			SET @proc_step_name = 'Remove old keys from dbo.nrt_treatment_key';
			SET @proc_step_no = @PROC_STEP_NO + 1;

			IF @debug = 'true' 
				SELECT @proc_step_name AS step, tk.* 
				FROM dbo.nrt_treatment_key tk WITH (NOLOCK)
				INNER JOIN #OLD_TREATMENT_KEYS ok 
					ON ok.TREATMENT_KEY = tk.D_TREATMENT_KEY;

			DELETE tk
			FROM dbo.nrt_treatment_key tk 
			INNER JOIN #OLD_TREATMENT_KEYS ok 
				ON ok.TREATMENT_KEY = tk.D_TREATMENT_KEY;

			SELECT @RowCount_no = @@ROWCOUNT;

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

		COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION
			SET @proc_step_name = 'Remove old keys from dbo.TREATMENT_EVENT';
			SET @proc_step_no = @PROC_STEP_NO + 1;

			IF @debug = 'true' 
				SELECT @proc_step_name AS step, te.* 
				FROM dbo.TREATMENT_EVENT te WITH (NOLOCK)
				INNER JOIN #OLD_TREATMENT_KEYS ok 
					ON ok.TREATMENT_KEY = te.TREATMENT_KEY;

			DELETE te
			FROM dbo.TREATMENT_EVENT te
			INNER JOIN #OLD_TREATMENT_KEYS ok 
				ON ok.TREATMENT_KEY = te.TREATMENT_KEY;

			SELECT @RowCount_no = @@ROWCOUNT;

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION

			SET @proc_step_name = 'Remove old keys from dbo.TREATMENT';
			SET @proc_step_no = @PROC_STEP_NO + 1;

			IF @debug = 'true' 
				SELECT @proc_step_name AS step, t.* 
				FROM dbo.TREATMENT t WITH (NOLOCK)
				INNER JOIN #OLD_TREATMENT_KEYS ok 
					ON ok.TREATMENT_KEY = t.TREATMENT_KEY;

			DELETE t
			FROM dbo.TREATMENT t
			INNER JOIN #OLD_TREATMENT_KEYS ok 
				ON ok.TREATMENT_KEY = t.TREATMENT_KEY;

			SELECT @RowCount_no = @@ROWCOUNT;

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------

        BEGIN TRANSACTION;

			SET @proc_step_name = 'Update TREATMENT Dimension';
			SET @proc_step_no = @PROC_STEP_NO + 1;

			/* Treatment Update Operation */
			UPDATE dbo.TREATMENT
			SET TREATMENT_LOCAL_ID             = trt.TREATMENT_LOCAL_ID,
				TREATMENT_NM                   = trt.TREATMENT_NM,
				TREATMENT_DRUG                 = trt.TREATMENT_DRUG,
				TREATMENT_DOSAGE_STRENGTH      = trt.TREATMENT_DOSAGE_STRENGTH,
				TREATMENT_DOSAGE_STRENGTH_UNIT = trt.TREATMENT_DOSAGE_STRENGTH_UNIT,
				TREATMENT_FREQUENCY            = trt.TREATMENT_FREQUENCY,
				TREATMENT_DURATION             = trt.TREATMENT_DURATION,
				TREATMENT_DURATION_UNIT        = trt.TREATMENT_DURATION_UNIT,
				TREATMENT_COMMENTS             = trt.TREATMENT_COMMENTS,
				TREATMENT_ROUTE                = trt.TREATMENT_ROUTE,
				CUSTOM_TREATMENT               = trt.CUSTOM_TREATMENT,
				TREATMENT_SHARED_IND           = trt.TREATMENT_SHARED_IND,
				TREATMENT_OID                  = trt.TREATMENT_OID,
				RECORD_STATUS_CD               = trt.RECORD_STATUS_CD
			FROM #treatment trt
			INNER JOIN dbo.TREATMENT t 
				ON trt.TREATMENT_KEY = t.TREATMENT_KEY
			WHERE trt.TREATMENT_KEY IS NOT NULL;

			SELECT @RowCount_no = @@ROWCOUNT;

			IF @debug = 'true' 
				SELECT @proc_step_name AS step, trt.* 
				FROM #treatment trt
				INNER JOIN dbo.TREATMENT t WITH (NOLOCK)
					ON trt.TREATMENT_KEY = t.TREATMENT_KEY
				WHERE trt.TREATMENT_KEY IS NOT NULL;

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

			--------------------------------------------------------------------------------------------------------

			SET @proc_step_name = 'Update TREATMENT_EVENT Dimension';
			SET @proc_step_no = @PROC_STEP_NO + 1;

			/* Treatment_Event Update Operation */
			UPDATE dbo.TREATMENT_EVENT
			SET TREATMENT_DT_KEY            = trte.TREATMENT_DT_KEY,
				PATIENT_KEY                 = trte.PATIENT_KEY,
				TREATMENT_PROVIDING_ORG_KEY = trte.TREATMENT_PROVIDING_ORG_KEY,
				TREATMENT_PHYSICIAN_KEY     = trte.TREATMENT_PHYSICIAN_KEY,
				TREATMENT_COUNT             = trte.TREATMENT_COUNT,
				MORB_RPT_KEY                = trte.MORB_RPT_KEY,
				INVESTIGATION_KEY           = trte.INVESTIGATION_KEY,
				CONDITION_KEY               = trte.CONDITION_KEY,
				LDF_GROUP_KEY               = trte.LDF_GROUP_KEY,
				RECORD_STATUS_CD            = trte.RECORD_STATUS_CD
			FROM #treatment_event trte
			INNER JOIN dbo.TREATMENT_EVENT te WITH (NOLOCK)
				ON trte.TREATMENT_KEY = te.TREATMENT_KEY
			WHERE trte.TREATMENT_KEY IS NOT NULL;

			SELECT @RowCount_no = @@ROWCOUNT;

			IF @debug = 'true' 
				SELECT @proc_step_name AS step, trt.* 
				FROM #treatment trt
				INNER JOIN dbo.TREATMENT t WITH (NOLOCK)
					ON trt.TREATMENT_KEY = t.TREATMENT_KEY
				WHERE trt.TREATMENT_KEY IS NOT NULL;

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

			--------------------------------------------------------------------------------------------------------

			SET @proc_step_name = 'Insert into TREATMENT Dimension';
			SET @proc_step_no = @PROC_STEP_NO + 1;

			/* Treatment Insert Operation - Generate keys first */
			INSERT INTO dbo.nrt_treatment_key(treatment_uid, public_health_case_uid)
			SELECT treatment_uid, public_health_case_uid
			FROM #treatment
			WHERE TREATMENT_KEY IS NULL
			ORDER BY treatment_uid;

			/* Perform inserts with the new keys */
			INSERT INTO dbo.TREATMENT(
				TREATMENT_KEY,
				TREATMENT_UID,
				TREATMENT_LOCAL_ID,
				TREATMENT_NM,
				TREATMENT_DRUG,
				TREATMENT_DOSAGE_STRENGTH,
				TREATMENT_DOSAGE_STRENGTH_UNIT,
				TREATMENT_FREQUENCY,
				TREATMENT_DURATION,
				TREATMENT_DURATION_UNIT,
				TREATMENT_COMMENTS,
				TREATMENT_ROUTE,
				CUSTOM_TREATMENT,
				TREATMENT_SHARED_IND,
				TREATMENT_OID,
				RECORD_STATUS_CD)
			SELECT 
				k.d_treatment_key,
				trt.treatment_uid,
				trt.TREATMENT_LOCAL_ID,
				trt.TREATMENT_NM,
				trt.TREATMENT_DRUG,
				trt.TREATMENT_DOSAGE_STRENGTH,
				trt.TREATMENT_DOSAGE_STRENGTH_UNIT,
				trt.TREATMENT_FREQUENCY,
				trt.TREATMENT_DURATION,
				trt.TREATMENT_DURATION_UNIT,
				trt.TREATMENT_COMMENTS,
				trt.TREATMENT_ROUTE,
				trt.CUSTOM_TREATMENT,
				trt.TREATMENT_SHARED_IND,
				trt.TREATMENT_OID,
				trt.RECORD_STATUS_CD
			FROM #treatment trt
			JOIN dbo.nrt_treatment_key k
				ON trt.treatment_uid = k.treatment_uid
				AND COALESCE(trt.public_health_case_uid, 1) = COALESCE(k.public_health_case_uid, 1)
			WHERE trt.TREATMENT_KEY IS NULL;

			SELECT @RowCount_no = @@ROWCOUNT;

			IF @debug = 'true' 
				SELECT @proc_step_name AS step, trt.* 
				FROM #treatment trt
				JOIN dbo.nrt_treatment_key k
					ON trt.treatment_uid = k.treatment_uid
					AND COALESCE(trt.public_health_case_uid, 1) = COALESCE(k.public_health_case_uid, 1)
				WHERE trt.TREATMENT_KEY IS NULL;

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

			--------------------------------------------------------------------------------------------------------

			SET @proc_step_name = 'Insert into TREATMENT_EVENT Dimension';
			SET @proc_step_no = @PROC_STEP_NO + 1;

			INSERT INTO dbo.TREATMENT_EVENT(
				TREATMENT_DT_KEY,
				TREATMENT_PROVIDING_ORG_KEY,
				PATIENT_KEY,
				TREATMENT_COUNT,
				TREATMENT_KEY,
				MORB_RPT_KEY,
				TREATMENT_PHYSICIAN_KEY,
				INVESTIGATION_KEY,
				CONDITION_KEY,
				LDF_GROUP_KEY,
				RECORD_STATUS_CD)
			SELECT trte.TREATMENT_DT_KEY,
				trte.TREATMENT_PROVIDING_ORG_KEY,
				trte.PATIENT_KEY,
				trte.TREATMENT_COUNT,
				k.d_treatment_key,
				trte.MORB_RPT_KEY,
				trte.TREATMENT_PHYSICIAN_KEY,
				trte.INVESTIGATION_KEY,
				trte.CONDITION_KEY,
				trte.LDF_GROUP_KEY,
				trte.RECORD_STATUS_CD
			FROM #treatment_event trte
			JOIN dbo.nrt_treatment_key k WITH (NOLOCK)
				ON trte.treatment_uid = k.treatment_uid
				AND COALESCE(trte.public_health_case_uid, 1) = COALESCE(k.public_health_case_uid, 1)
			WHERE trte.TREATMENT_KEY IS NULL;

			SELECT @RowCount_no = @@ROWCOUNT;

			IF @debug = 'true' 
				SELECT @proc_step_name AS step, trte.* 
				FROM #treatment_event trte
				JOIN dbo.nrt_treatment_key k WITH (NOLOCK)
					ON trte.treatment_uid = k.treatment_uid
					AND COALESCE(trte.public_health_case_uid, 1) = COALESCE(k.public_health_case_uid, 1)
				WHERE trte.TREATMENT_KEY IS NULL;

			INSERT INTO [dbo].[job_flow_log]
			(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
			VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

        COMMIT TRANSACTION;

		--------------------------------------------------------------------------------------------------------

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        SELECT @ROWCOUNT_NO = 0;

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
        VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'COMPLETE', 999, @Proc_Step_name, @RowCount_no);

		--------------------------------------------------------------------------------------------------------

    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @FullErrorMessage NVARCHAR(4000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log] 
		(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
		VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);

        RETURN -1;
    END CATCH
END;