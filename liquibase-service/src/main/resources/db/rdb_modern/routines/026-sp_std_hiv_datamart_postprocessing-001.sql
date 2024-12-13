CREATE OR ALTER PROCEDURE [dbo].[sp_std_hiv_datamart_postprocessing]
    @phc_id nvarchar(max),
    @debug bit = 'false'
AS

BEGIN

    /*
     * [Description]
     * This stored procedure is handles event based updates to STD_HIV_Datamart and INV_HIV.
     * 1. Receives input list of public_health_case_uids. The public_health_case_uids are
     * determined using the condition codes associated to STD and HIV page builder investigations.
     * 2. Relevant dimensions and f_std_page_case fact table are used to build the records.
     * 3. The stored procedure inserts or updates records based on the INVESTIGATION_KEY.
     * */


    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyyyMMddHHmmss')) as bigint);
    PRINT @batch_id;
    DECLARE @RowCount_no int;
    DECLARE @Proc_Step_no float= 0;
    DECLARE @Proc_Step_Name varchar(200)= '';


    BEGIN TRY

        BEGIN TRANSACTION;
        SET @Proc_Step_Name = 'SP_Start';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;


        /* Get list of Investigations*/
        SELECT *
        INTO #tmp_investigation
        FROM dbo.Investigation i
        WHERE i.case_uid IN (SELECT value FROM STRING_SPLIT(@phc_id, ','));

        if @debug = 'true' select '#tmp_investigation', * from #tmp_investigation;


        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type] ,[step_number],[step_name],[row_count])
        VALUES( @Batch_id,'STD_HIV_DATAMART','STD_HIV_DATAMART','START',@Proc_Step_no,@Proc_Step_Name,0);
        COMMIT TRANSACTION;

        /*New logic for INV_HIV*/
        --IF @COUNTSTD>0 AND @COUNTHIV>0
        --PRINT 'STEP2 Counter @COUNTSTD>0 and @COUNTHIV<1...'+ @COUNTSTDStr + ' @COUNTHIVStr...'+@COUNTHIVStr + CONVERT(varchar(20), getdate(),120)


        BEGIN TRANSACTION;
        SET @Proc_Step_Name = 'Update INV_HIV table';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        UPDATE ih
        SET
            ih.D_INV_HIV_KEY	 = 	PC.D_INV_HIV_KEY	,
            ih.HIV_STATE_CASE_ID	 = 	dih.HIV_STATE_CASE_ID	,
            ih.HIV_LAST_900_TEST_DT	 = 	dih.HIV_LAST_900_TEST_DT	,
            ih.HIV_900_TEST_REFERRAL_DT	 = 	dih.HIV_900_TEST_REFERRAL_DT	,
            ih.HIV_ENROLL_PRTNR_SRVCS_IND	 = 	dih.HIV_ENROLL_PRTNR_SRVCS_IND	,
            ih.HIV_PREVIOUS_900_TEST_IND	 = 	dih.HIV_PREVIOUS_900_TEST_IND	,
            ih.HIV_SELF_REPORTED_RSLT_900	 = 	dih.HIV_SELF_REPORTED_RSLT_900	,
            ih.HIV_REFER_FOR_900_TEST	 = 	dih.HIV_REFER_FOR_900_TEST	,
            ih.HIV_900_TEST_IND 	 = 	dih.HIV_900_TEST_IND 	,
            ih.HIV_900_RESULT 	 = 	dih.HIV_900_RESULT 	,
            ih.HIV_RST_PROVIDED_900_RSLT_IND 	 = 	dih.HIV_RST_PROVIDED_900_RSLT_IND 	,
            ih.HIV_POST_TEST_900_COUNSELING 	 = 	dih.HIV_POST_TEST_900_COUNSELING 	,
            ih.HIV_REFER_FOR_900_CARE_IND 	 = 	dih.HIV_REFER_FOR_900_CARE_IND 	,
            ih.HIV_KEEP_900_CARE_APPT_IND 	 = 	dih.HIV_KEEP_900_CARE_APPT_IND 	,
            ih.HIV_AV_THERAPY_LAST_12MO_IND 	 = 	dih.HIV_AV_THERAPY_LAST_12MO_IND 	,
            ih.HIV_AV_THERAPY_EVER_IND	 = 	dih.HIV_AV_THERAPY_EVER_IND	,
            ih.INVESTIGATION_KEY	 = 	PC.INVESTIGATION_KEY
        FROM [DBO].[INV_HIV] ih
                 INNER JOIN [DBO].[F_STD_PAGE_CASE] PC on ih.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                 INNER JOIN #tmp_investigation inv ON inv.INVESTIGATION_KEY= PC.INVESTIGATION_KEY
                 LEFT OUTER JOIN [DBO].[D_INV_HIV] dih ON dih.D_INV_HIV_KEY = PC.D_INV_HIV_KEY
        WHERE
            RECORD_STATUS_CD='ACTIVE'
          AND EXISTS
            (
                SELECT 1 FROM DBO.INV_HIV ih
                WHERE ih.INVESTIGATION_KEY = PC.INVESTIGATION_KEY

            );

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@Batch_id,'STD_HIV_DATAMART','INV_HIV','START',@Proc_Step_no,@Proc_Step_name,@RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @Proc_Step_Name = 'Inserting data into INV_HIV table';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        --PRINT 'STEP2 Counter @COUNTSTD>0 and @COUNTHIV<1...'+ @COUNTSTDStr + ' @COUNTHIVStr...'+@COUNTHIVStr + CONVERT(varchar(20), getdate(),120)

        INSERT INTO [DBO].[INV_HIV]
        (D_INV_HIV_KEY,
         HIV_STATE_CASE_ID,
         HIV_LAST_900_TEST_DT,
         HIV_900_TEST_REFERRAL_DT,
         HIV_ENROLL_PRTNR_SRVCS_IND,
         HIV_PREVIOUS_900_TEST_IND,
         HIV_SELF_REPORTED_RSLT_900,
         HIV_REFER_FOR_900_TEST,
         HIV_900_TEST_IND ,
         HIV_900_RESULT ,
         HIV_RST_PROVIDED_900_RSLT_IND ,
         HIV_POST_TEST_900_COUNSELING ,
         HIV_REFER_FOR_900_CARE_IND ,
         HIV_KEEP_900_CARE_APPT_IND ,
         HIV_AV_THERAPY_LAST_12MO_IND ,
         HIV_AV_THERAPY_EVER_IND,
         PC.INVESTIGATION_KEY)
        SELECT
            PC.D_INV_HIV_KEY,
            HIV_STATE_CASE_ID,
            HIV_LAST_900_TEST_DT,
            HIV_900_TEST_REFERRAL_DT,
            HIV_ENROLL_PRTNR_SRVCS_IND,
            HIV_PREVIOUS_900_TEST_IND,
            HIV_SELF_REPORTED_RSLT_900,
            HIV_REFER_FOR_900_TEST,
            HIV_900_TEST_IND ,
            HIV_900_RESULT ,
            HIV_RST_PROVIDED_900_RSLT_IND ,
            HIV_POST_TEST_900_COUNSELING ,
            HIV_REFER_FOR_900_CARE_IND ,
            HIV_KEEP_900_CARE_APPT_IND ,
            HIV_AV_THERAPY_LAST_12MO_IND ,
            HIV_AV_THERAPY_EVER_IND,
            PC.INVESTIGATION_KEY
        FROM
            [DBO].[F_STD_PAGE_CASE] PC
                LEFT OUTER JOIN
            [DBO].[D_INV_HIV] dih
            ON	dih.D_INV_HIV_KEY = PC.D_INV_HIV_KEY
                LEFT OUTER JOIN
            #tmp_investigation inv
            ON
                inv.INVESTIGATION_KEY= PC.INVESTIGATION_KEY
        WHERE
            RECORD_STATUS_CD='ACTIVE'
          AND NOT EXISTS
            (
                SELECT 1 FROM DBO.INV_HIV ih
                WHERE ih.INVESTIGATION_KEY = PC.INVESTIGATION_KEY

            )
        ORDER BY PC.INVESTIGATION_KEY;


        SELECT @RowCount_no = @@ROWCOUNT;
        --INSERT INTO [DBO].[INV_HIV] (INVESTIGATION_KEY) VALUES (1);

        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@Batch_id,'STD_HIV_DATAMART','INV_HIV','START',@Proc_Step_no,@Proc_Step_name,@RowCount_no);

        COMMIT TRANSACTION;

        /*Update logic for STD HIV*/
        --IF @COUNTSTD >0
        BEGIN TRANSACTION;
        SET @Proc_Step_Name = 'Update STD_HIV_DATAMART';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        UPDATE shd
        SET
            [ADI_900_STATUS]	 = 	STATUS_900
          ,[ADI_900_STATUS_CD]	 = 	CM.ADI_900_STATUS_CD
          ,[ADM_REFERRAL_BASIS_OOJ]	 = 	AM.ADM_REFERRAL_BASIS_OOJ
          ,[ADM_RPTNG_CNTY]	 = 	AM.ADM_RPTNG_CNTY
          ,[CA_INIT_INTVWR_ASSGN_DT]	 = 	CM.CA_INIT_INTVWR_ASSGN_DT
          ,[CA_INTERVIEWER_ASSIGN_DT]	 = 	CM.CA_INTERVIEWER_ASSIGN_DT
          ,[CA_PATIENT_INTV_STATUS]	 = 	CM.CA_PATIENT_INTV_STATUS
          ,[CALC_5_YEAR_AGE_GROUP]	 = 	CASE
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 0
                                                    AND PAT.PATIENT_AGE_REPORTED <= 4
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN ' 1'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 5
                                                    AND PAT.PATIENT_AGE_REPORTED <= 9
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN ' 2'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 10
                                                    AND PAT.PATIENT_AGE_REPORTED <= 14
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN ' 3'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 15
                                                    AND PAT.PATIENT_AGE_REPORTED <= 19
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN ' 4'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 20
                                                    AND PAT.PATIENT_AGE_REPORTED <= 24
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN ' 5'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 25
                                                    AND PAT.PATIENT_AGE_REPORTED <= 29
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN ' 6'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 30
                                                    AND PAT.PATIENT_AGE_REPORTED <= 34
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN ' 7'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 35
                                                    AND PAT.PATIENT_AGE_REPORTED <= 39
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN ' 8'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 40
                                                    AND PAT.PATIENT_AGE_REPORTED <= 44
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN ' 9'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 45
                                                    AND PAT.PATIENT_AGE_REPORTED <= 49
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN '10'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 50
                                                    AND PAT.PATIENT_AGE_REPORTED <= 54
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN '11'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 55
                                                    AND PAT.PATIENT_AGE_REPORTED <= 59
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN '12'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 60
                                                    AND PAT.PATIENT_AGE_REPORTED <= 64
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN '13'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 65
                                                    AND PAT.PATIENT_AGE_REPORTED <= 69
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN '14'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 70
                                                    AND PAT.PATIENT_AGE_REPORTED <= 74
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN '15'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 75
                                                    AND PAT.PATIENT_AGE_REPORTED <= 79
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN '16'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 80
                                                    AND PAT.PATIENT_AGE_REPORTED <= 84
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN '17'
                                                WHEN PAT.PATIENT_AGE_REPORTED >= 85
                                                    AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                                    THEN '18'
                                                ELSE NULL END
          ,[CASE_RPT_MMWR_WK]	 = 	INV.CASE_RPT_MMWR_WK
          ,[CASE_RPT_MMWR_YR]	 = 	INV.CASE_RPT_MMWR_YR
          ,[CC_CLOSED_DT]	 = 	CM.CC_CLOSED_DT
          ,[CLN_CARE_STATUS_CLOSE_DT]	 = 	CLN.CLN_CARE_STATUS_CLOSE_DT
          ,[CLN_CONDITION_RESISTANT_TO]	 = 	CLN.CLN_CONDITION_RESISTANT_TO
          ,[CLN_DT_INIT_HLTH_EXM]	 = 	CLN.CLN_DT_INIT_HLTH_EXM
          ,[CLN_NEUROSYPHILLIS_IND]	 = 	CLN.CLN_NEUROSYPHILLIS_IND
          ,[CLN_PRE_EXP_PROPHY_IND]	 = 	CLN.CLN_PRE_EXP_PROPHY_IND
          ,[CLN_PRE_EXP_PROPHY_REFER]	 = 	CLN.CLN_PRE_EXP_PROPHY_REFER
          ,[CLN_SURV_PROVIDER_DIAG_CD]	 = 	CM.SURV_PROVIDER_DIAGNOSIS
          ,[CMP_CONJUNCTIVITIS_IND]	 = 	CMP.CMP_CONJUNCTIVITIS_IND
          ,[CMP_PID_IND]	 = 	CMP.CMP_PID_IND
          ,[COINFECTION_ID]	 = 	INV.COINFECTION_ID
          ,[CONDITION_CD]	 = 	COND.CONDITION_CD
          ,[CONDITION_KEY]	 = 	COND.CONDITION_KEY
          ,[CONFIRMATION_DT]	 = 	CAST(FORMAT(CONF.CONFIRMATION_DT, 'yyyy-MM-dd') AS datetime)
          ,[CURR_PROCESS_STATE]	 = 	INV.CURR_PROCESS_STATE
          ,[DETECTION_METHOD_DESC_TXT]	 = 	INV.DETECTION_METHOD_DESC_TXT
          ,[DIAGNOSIS]	 = 	CLN.CLN_CASE_DIAGNOSIS
          ,[DIAGNOSIS_CD]	 = 	SUBSTRING(CLN.CLN_CASE_DIAGNOSIS, 1, 3)
          ,[DIE_FRM_THIS_ILLNESS_IND]	 = 	INV.DIE_FRM_THIS_ILLNESS_IND
          ,[DISEASE_IMPORTED_IND]	 = 	INV.DISEASE_IMPORTED_IND
          ,[DISSEMINATED_IND]	 = 	AM.ADM_DISSEMINATED_IND
          ,[EPI_CNTRY_USUAL_RESID]	 = 	EPI.EPI_CNTRY_USUAL_RESID
          ,[EPI_LINK_ID]	 = 	CM.EPI_LINK_ID
          ,[FACILITY_FLD_FOLLOW_UP_KEY]	 = 	PC.FACILITY_FLD_FOLLOW_UP_KEY
          ,[FIELD_RECORD_NUMBER]	 = 	CM.FL_FUP_FIELD_RECORD_NUM
          ,[FL_FUP_ACTUAL_REF_TYPE]	 = 	CM.FL_FUP_ACTUAL_REF_TYPE
          ,[FL_FUP_DISPO_DT]	 = 	CM.FL_FUP_DISPO_DT
          ,[FL_FUP_DISPOSITION]	 = 	CM.FL_FUP_DISPOSITION_DESC
          ,[FL_FUP_EXAM_DT]	 = 	CM.FL_FUP_EXAM_DT
          ,[FL_FUP_EXPECTED_DT]	 = 	CM.FL_FUP_EXPECTED_DT
          ,[FL_FUP_EXPECTED_IN_IND_CD]	 = 	SUBSTRING(CM.FL_FUP_EXPECTED_IN_IND, 1, 1)
          ,[FL_FUP_INIT_ASSGN_DT]	 = 	CM.FL_FUP_INIT_ASSGN_DT
          ,[FL_FUP_INTERNET_OUTCOME_CD]	 = 	CM.FL_FUP_INTERNET_OUTCOME_CD
          ,[FL_FUP_INVESTIGATOR_ASSGN_DT]	 = 	CM.FL_FUP_INVESTIGATOR_ASSGN_DT
          ,[FL_FUP_NOTIFICATION_PLAN]	 = 	CM.FL_FUP_NOTIFICATION_PLAN_CD
          ,[FL_FUP_OOJ_OUTCOME]	 = 	CM.FL_FUP_OOJ_OUTCOME
          ,[FL_FUP_PROV_DIAGNOSIS_CD]	 = 	SUBSTRING(CM.FL_FUP_PROV_DIAGNOSIS, 1, 3)
          ,[FL_FUP_PROV_EXM_REASON]	 = 	CM.FL_FUP_PROV_EXM_REASON
          ,[HIV_900_RESULT]	 = 	RTRIM(LTRIM(HIV.HIV_900_RESULT))
          ,[HIV_900_TEST_IND]	 = 	HIV.HIV_900_TEST_IND
          ,[HIV_900_TEST_REFERRAL_DT]	 = 	HIV.HIV_900_TEST_REFERRAL_DT
          ,[HIV_AV_THERAPY_EVER_IND]	 = 	HIV.HIV_AV_THERAPY_EVER_IND
          ,[HIV_AV_THERAPY_LAST_12MO_IND]	 = 	HIV.HIV_AV_THERAPY_LAST_12MO_IND
          ,[HIV_CA_900_OTH_RSN_NOT_LO]	 = 	RTRIM(LTRIM(HIV.HIV_CA_900_OTH_RSN_NOT_LO))
          ,[HIV_CA_900_REASON_NOT_LOC]	 = 	HIV.HIV_CA_900_REASON_NOT_LOC
          ,[HIV_ENROLL_PRTNR_SRVCS_IND]	 = 	HIV.HIV_ENROLL_PRTNR_SRVCS_IND
          ,[HIV_KEEP_900_CARE_APPT_IND]	 = 	HIV.HIV_KEEP_900_CARE_APPT_IND
          ,[HIV_LAST_900_TEST_DT]	 = 	HIV.HIV_LAST_900_TEST_DT
          ,[HIV_POST_TEST_900_COUNSELING]	 = 	RTRIM(LTRIM(HIV.HIV_POST_TEST_900_COUNSELING))
          ,[HIV_PREVIOUS_900_TEST_IND]	 = 	HIV.HIV_PREVIOUS_900_TEST_IND
          ,[HIV_REFER_FOR_900_CARE_IND]	 = 	HIV.HIV_REFER_FOR_900_CARE_IND
          ,[HIV_REFER_FOR_900_TEST]	 = 	RTRIM(LTRIM(HIV.HIV_REFER_FOR_900_TEST))
          ,[HIV_RST_PROVIDED_900_RSLT_IND]	 = 	HIV.HIV_RST_PROVIDED_900_RSLT_IND
          ,[HIV_SELF_REPORTED_RSLT_900]	 = 	HIV.HIV_SELF_REPORTED_RSLT_900
          ,[HIV_STATE_CASE_ID]	 = 	RTRIM(LTRIM(HIV.HIV_STATE_CASE_ID))
          ,[HOSPITAL_KEY]	 = 	PC.HOSPITAL_KEY
          ,[HSPTLIZD_IND]	 = 	INV.HSPTLIZD_IND
          ,[INVESTIGATION_KEY]	 = 	PC.INVESTIGATION_KEY
          ,[INIT_FUP_CLINIC_CODE]	 = 	CM.INIT_FUP_CLINIC_CODE
          ,[INIT_FUP_CLOSED_DT]	 = 	CM.INIT_FUP_CLOSED_DT
          ,[INIT_FUP_INITIAL_FOLL_UP]	 = 	CM.INIT_FUP_INITIAL_FOLL_UP
          ,[INIT_FUP_INTERNET_FOLL_UP]	 = 	CM.INIT_FUP_INTERNET_FOLL_UP_CD
          ,[INIT_FUP_INITIAL_FOLL_UP_CD]	 = 	CM.INIT_FUP_INITIAL_FOLL_UP_CD
          ,[INIT_FUP_INTERNET_FOLL_UP_CD]	 = 	CM.INIT_FUP_INTERNET_FOLL_UP_CD
          ,[INIT_FUP_NOTIFIABLE]	 = 	CM.INIT_FUP_NOTIFIABLE_CD
          ,[INITIATING_AGNCY]	 = 	CM.INITIATING_AGNCY
          ,[INV_ASSIGNED_DT]	 = 	CAST(FORMAT(INV.INV_ASSIGNED_DT, 'yyyy-MM-dd') AS datetime)
          ,[INV_CASE_STATUS]	 = 	INV.INV_CASE_STATUS
          ,[INV_CLOSE_DT]	 = 	CAST(FORMAT(INV.INV_CLOSE_DT, 'yyyy-MM-dd') AS datetime)
          ,[INV_LOCAL_ID]	 = 	INV.INV_LOCAL_ID
          ,[INV_RPT_DT]	 = 	CAST(FORMAT(INV.INV_RPT_DT, 'yyyy-MM-dd') AS datetime)
          ,[INV_START_DT]	 = 	CAST(FORMAT(INV.INV_START_DT, 'yyyy-MM-dd') AS datetime)
          ,[INVESTIGATION_DEATH_DATE]	 = 	CAST(FORMAT(INV.INVESTIGATION_DEATH_DATE, 'yyyy-MM-dd') AS datetime)
          ,[INVESTIGATION_STATUS]	 = 	INV.INVESTIGATION_STATUS
          ,[INVESTIGATOR_CLOSED_KEY]	 = 	PC.CLOSED_BY_KEY
          ,[INVESTIGATOR_CLOSED_QC]	 = 	INVEST.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_CURRENT_KEY]	 = 	PC.INVESTIGATOR_KEY
          ,[INVESTIGATOR_CURRENT_QC]	 = 	CRNTI.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_DISP_FL_FUP_KEY]	 = 	PC.DISPOSITIONED_BY_KEY
          ,[INVESTIGATOR_DISP_FL_FUP_QC]	 = 	DISP.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_FL_FUP_KEY]	 = 	PC.INVSTGTR_FLD_FOLLOW_UP_KEY
          ,[INVESTIGATOR_FL_FUP_QC]	 = 	FLD.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_INIT_INTRVW_KEY]	 = 	PC.INIT_ASGNED_INTERVIEWER_KEY
          ,[INVESTIGATOR_INIT_INTRVW_QC]	 = 	INITIV.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_INIT_FL_FUP_KEY]	 = 	PC.INIT_ASGNED_FLD_FOLLOW_UP_KEY
          ,[INVESTIGATOR_INIT_FL_FUP_QC]	 = 	FUP.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_INITIAL_KEY]	 = 	PC.INIT_FOLLOW_UP_INVSTGTR_KEY
          ,[INVESTIGATOR_INITIAL_QC]	 = 	INIT.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_INTERVIEW_KEY]	 = 	PC.INTERVIEWER_ASSIGNED_KEY
          ,[INVESTIGATOR_INTERVIEW_QC]	 = 	IVW.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_SUPER_CASE_KEY]	 = 	PC.SUPRVSR_OF_CASE_ASSGNMENT_KEY
          ,[INVESTIGATOR_SUPER_CASE_QC]	 = 	SUPV.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_SUPER_FL_FUP_KEY]	 = 	PC.SUPRVSR_OF_FLD_FOLLOW_UP_KEY
          ,[INVESTIGATOR_SUPER_FL_FUP_QC]	 = 	SUPVFUP.PROVIDER_QUICK_CODE
          ,[INVESTIGATOR_SURV_KEY]	 = 	PC.SURVEILLANCE_INVESTIGATOR_KEY
          ,[INVESTIGATOR_SURV_QC]	 = 	SURV.PROVIDER_QUICK_CODE
          ,[IPO_CURRENTLY_IN_INSTITUTION]	 = 	OBS.IPO_CURRENTLY_IN_INSTITUTION
          ,[IPO_LIVING_WITH]	 = 	RTRIM(LTRIM(OBS.IPO_LIVING_WITH))
          ,[IPO_NAME_OF_INSTITUTITION]	 = 	RTRIM(LTRIM(OBS.IPO_NAME_OF_INSTITUTITION))
          ,[IPO_TIME_AT_ADDRESS_NUM]	 = 	OBS.IPO_TIME_AT_ADDRESS_NUM
          ,[IPO_TIME_AT_ADDRESS_UNIT]	 = 	OBS.IPO_TIME_AT_ADDRESS_UNIT
          ,[IPO_TIME_IN_COUNTRY_NUM]	 = 	OBS.IPO_TIME_IN_COUNTRY_NUM
          ,[IPO_TIME_IN_COUNTRY_UNIT]	 = 	OBS.IPO_TIME_IN_COUNTRY_UNIT
          ,[IPO_TIME_IN_STATE_NUM]	 = 	OBS.IPO_TIME_IN_STATE_NUM
          ,[IPO_TIME_IN_STATE_UNIT]	 = 	OBS.IPO_TIME_IN_STATE_UNIT
          ,[IPO_TYPE_OF_INSTITUTITION]	 = 	RTRIM(LTRIM(OBS.IPO_TYPE_OF_INSTITUTITION))
          ,[IPO_TYPE_OF_RESIDENCE]	 = 	OBS.IPO_TYPE_OF_RESIDENCE
          ,[IX_DATE_OI]	 = 	CAST(FORMAT(DIVW.IX_DATE, 'yyyy-MM-dd') AS datetime)
          ,[JURISDICTION_CD]	 = 	INV.JURISDICTION_CD
          ,[JURISDICTION_NM]	 = 	INV.JURISDICTION_NM
          ,[LAB_HIV_SPECIMEN_COLL_DT]	 = 	LF.LAB_HIV_SPECIMEN_COLL_DT
          ,[LAB_NONTREP_SYPH_RSLT_QNT]	 = 	LF.LAB_NONTREP_SYPH_RSLT_QNT
          ,[LAB_NONTREP_SYPH_RSLT_QUA]	 = 	LF.LAB_NONTREP_SYPH_RSLT_QUA
          ,[LAB_NONTREP_SYPH_TEST_TYP]	 = 	LF.LAB_NONTREP_SYPH_TEST_TYP
          ,[LAB_SYPHILIS_TST_PS_IND]	 = 	LF.LAB_SYPHILIS_TST_PS_IND
          ,[LAB_SYPHILIS_TST_RSLT_PS]	 = 	LF.LAB_SYPHILIS_TST_RSLT_PS
          ,[LAB_TESTS_PERFORMED]	 = 	LF.LAB_TESTS_PERFORMED
          ,[LAB_TREP_SYPH_RESULT_QUAL]	 = 	LF.LAB_TREP_SYPH_RESULT_QUAL
          ,[LAB_TREP_SYPH_TEST_TYPE]	 = 	LF.LAB_TREP_SYPH_TEST_TYPE
          ,[MDH_PREV_STD_HIST]	 = 	MH.MDH_PREV_STD_HIST
          ,[OOJ_AGENCY_SENT_TO]	 = 	CM.OOJ_AGENCY
          ,[OOJ_DUE_DATE_SENT_TO]	 = 	CAST(FORMAT(CM.OOJ_DUE_DATE, 'yyyy-MM-dd') AS datetime)
          ,[OOJ_FR_NUMBER_SENT_TO]	 = 	CM.OOJ_NUMBER
          ,[OOJ_INITG_AGNCY_OUTC_DUE_DATE]	 = 	CAST(FORMAT(CM.OOJ_INITG_AGNCY_OUTC_DUE_DATE, 'yyyy-MM-dd') AS datetime)
          ,[OOJ_INITG_AGNCY_OUTC_SNT_DATE]	 = 	CAST(FORMAT(CM.OOJ_INITG_AGNCY_OUTC_SNT_DATE, 'yyyy-MM-dd') AS datetime)
          ,[OOJ_INITG_AGNCY_RECD_DATE]	 = 	CAST(FORMAT(CM.OOJ_INITG_AGNCY_RECD_DATE, 'yyyy-MM-dd') AS datetime)
          ,[ORDERING_FACILITY_KEY]	 = 	PC.ORDERING_FACILITY_KEY
          ,[OUTBREAK_IND]	 = 	INV.OUTBREAK_IND
          ,[OUTBREAK_NAME]	 = 	INV.OUTBREAK_NAME
          ,[PATIENT_ADDL_GENDER_INFO]	 = 	PAT.PATIENT_ADDL_GENDER_INFO
          ,[PATIENT_AGE_AT_ONSET]	 = 	INV.PATIENT_AGE_AT_ONSET
          ,[PATIENT_AGE_AT_ONSET_UNIT]	 = 	INV.PATIENT_AGE_AT_ONSET_UNIT
          ,[PATIENT_AGE_REPORTED]	 = 	CASE
                                               WHEN PAT.PATIENT_AGE_REPORTED IS NULL
                                                   AND PAT.PATIENT_AGE_REPORTED_UNIT IS NULL THEN '           .'
                                               WHEN PAT.PATIENT_AGE_REPORTED IS NULL THEN RTRIM('           .'+ ' ' + PAT.PATIENT_AGE_REPORTED_UNIT)
                                               WHEN PAT.PATIENT_AGE_REPORTED_UNIT IS NULL THEN (SELECT RIGHT('            ' + CAST(PAT.PATIENT_AGE_REPORTED AS VARCHAR(50)), 12))
                                               ELSE (SELECT RIGHT('            ' + CAST(PAT.PATIENT_AGE_REPORTED AS VARCHAR(50)), 12) + ' ' + PAT.PATIENT_AGE_REPORTED_UNIT)
            END
          ,[PATIENT_ALIAS]	 = 	PAT.PATIENT_ALIAS_NICKNAME
          ,[PATIENT_BIRTH_COUNTRY]	 = 	PAT.PATIENT_BIRTH_COUNTRY
          ,[PATIENT_BIRTH_SEX]	 = 	PAT.PATIENT_BIRTH_SEX
          ,[PATIENT_CENSUS_TRACT]	 = 	PAT.PATIENT_CENSUS_TRACT
          ,[PATIENT_CITY]	 = 	PAT.PATIENT_CITY
          ,[PATIENT_COUNTRY]	 = 	PAT.PATIENT_COUNTRY
          ,[PATIENT_COUNTY]	 = 	PAT.PATIENT_COUNTY
          ,[PATIENT_CURR_SEX_UNK_RSN]	 = 	PAT.PATIENT_CURR_SEX_UNK_RSN
          ,[PATIENT_CURRENT_SEX]	 = 	PAT.PATIENT_CURRENT_SEX
          ,[PATIENT_DECEASED_DATE]	 = 	CAST(FORMAT(PAT.PATIENT_DECEASED_DATE, 'yyyy-MM-dd') AS datetime)
          ,[PATIENT_DECEASED_INDICATOR]	 = 	PAT.PATIENT_DECEASED_INDICATOR
          ,[PATIENT_DOB]	 = 	CAST(FORMAT(PAT.PATIENT_DOB, 'yyyy-MM-dd') AS datetime)
          ,[PATIENT_EMAIL]	 = 	PAT.PATIENT_EMAIL
          ,[PATIENT_ETHNICITY]	 = 	PAT.PATIENT_ETHNICITY
          ,[PATIENT_LOCAL_ID]	 = 	PAT.PATIENT_LOCAL_ID
          ,[PATIENT_MARITAL_STATUS]	 = 	PAT.PATIENT_MARITAL_STATUS
          ,[PATIENT_NAME]	 = 	RTRIM((ISNULL(RTRIM(LTRIM(PAT.PATIENT_LAST_NAME)), ' ') + ', ' +
                                          ISNULL(RTRIM(LTRIM(PAT.PATIENT_FIRST_NAME)), ' ') + ' ' +
                                          ISNULL(RTRIM(LTRIM(PAT.PATIENT_MIDDLE_NAME)), '')))
          ,[PATIENT_PHONE_CELL]	 = 	PAT.PATIENT_PHONE_CELL
          ,[PATIENT_PHONE_HOME]	 = 	CASE
                                             WHEN PAT.PATIENT_PHONE_EXT_HOME IS NULL THEN PAT.PATIENT_PHONE_HOME
                                             ELSE ISNULL(PAT.PATIENT_PHONE_HOME, ' ') + ' Ext ' + PAT.PATIENT_PHONE_EXT_HOME
            END
          ,[PATIENT_PHONE_WORK]	 = 	CASE
                                             WHEN PAT.PATIENT_PHONE_EXT_WORK IS NULL THEN PAT.PATIENT_PHONE_WORK
                                             ELSE ISNULL(PAT.PATIENT_PHONE_WORK, ' ') + ' Ext ' + PAT.PATIENT_PHONE_EXT_WORK
            END
          ,[PATIENT_PREFERRED_GENDER]	 = 	PAT.PATIENT_PREFERRED_GENDER
          ,[PATIENT_PREGNANT_IND]	 = 	INV.PATIENT_PREGNANT_IND
          ,[PATIENT_RACE]	 = 	PAT.PATIENT_RACE_CALCULATED
          ,[PATIENT_SEX]	 = 	CASE
                                      WHEN PAT.PATIENT_PREFERRED_GENDER IS NULL THEN ISNULL(PAT.PATIENT_CURR_SEX_UNK_RSN, PAT.PATIENT_CURRENT_SEX)
                                      ELSE PAT.PATIENT_PREFERRED_GENDER
            END
          ,[PATIENT_STATE]	 = 	PAT.PATIENT_STATE
          ,[PATIENT_STREET_ADDRESS_1]	 = 	PAT.PATIENT_STREET_ADDRESS_1
          ,[PATIENT_STREET_ADDRESS_2]	 = 	PAT.PATIENT_STREET_ADDRESS_2
          ,[PATIENT_UNK_ETHNIC_RSN]	 = 	PAT.PATIENT_UNK_ETHNIC_RSN
          ,[PATIENT_ZIP]	 = 	PAT.PATIENT_ZIP
          ,[PBI_IN_PRENATAL_CARE_IND]	 = 	PBI.PBI_IN_PRENATAL_CARE_IND
          ,[PBI_PATIENT_PREGNANT_WKS]	 = 	PBI.PBI_PATIENT_PREGNANT_WKS
          ,[PBI_PREG_AT_EXAM_IND]	 = 	PBI.PBI_PREG_AT_EXAM_IND
          ,[PBI_PREG_AT_EXAM_WKS]	 = 	PBI.PBI_PREG_AT_EXAM_WKS
          ,[PBI_PREG_AT_IX_IND]	 = 	PBI.PBI_PREG_AT_IX_IND
          ,[PBI_PREG_AT_IX_WKS]	 = 	PBI.PBI_PREG_AT_IX_WKS
          ,[PBI_PREG_IN_LAST_12MO_IND]	 = 	PBI.PBI_PREG_IN_LAST_12MO_IND
          ,[PBI_PREG_OUTCOME]	 = 	PBI.PBI_PREG_OUTCOME_CD
          ,[PHYSICIAN_FL_FUP_KEY]	 = 	PC.PROVIDER_FLD_FOLLOW_UP_KEY
          ,[PHYSICIAN_KEY]	 = 	PC.PHYSICIAN_KEY
          ,[PROGRAM_AREA_CD]	 = 	COND.PROGRAM_AREA_CD
          ,[PROGRAM_JURISDICTION_OID]	 = 	INV.CASE_OID
          ,[REPORTING_ORG_KEY]	 = 	PC.ORG_AS_REPORTER_KEY
          ,[REPORTING_PROV_KEY]	 = 	PC.PERSON_AS_REPORTER_KEY
          ,[RPT_ELICIT_INTERNET_INFO]	 = 	ICC.CTT_RPT_ELICIT_INTERNET_INFO
          ,[RPT_FIRST_NDLSHARE_EXP_DT]	 = 	ICC.CTT_RPT_FIRST_NDLSHARE_EXP_DT
          ,[RPT_FIRST_SEX_EXP_DT]	 = 	ICC.CTT_RPT_FIRST_SEX_EXP_DT
          ,[RPT_LAST_NDLSHARE_EXP_DT]	 = 	ICC.CTT_RPT_LAST_NDLSHARE_EXP_DT
          ,[PROVIDER_REASON_VISIT_DT]	 = 	MH.MDH_PROVIDER_REASON_VISIT_DT
          ,[REFERRAL_BASIS]	 = 	INV.REFERRAL_BASIS
          ,[RPT_LAST_SEX_EXP_DT]	 = 	ICC.CTT_RPT_LAST_SEX_EXP_DT
          ,[RPT_MET_OP_INTERNET]	 = 	ICC.CTT_RPT_MET_OP_INTERNET
          ,[RPT_NDLSHARE_EXP_FREQ]	 = 	ICC.CTT_RPT_NDLSHARE_EXP_FREQ
          ,[RPT_RELATIONSHIP_TO_OP]	 = 	ICC.CTT_RPT_RELATIONSHIP_TO_OP
          ,[RPT_SEX_EXP_FREQ]	 = 	ICC.CTT_RPT_SEX_EXP_FREQ
          ,[RPT_SRC_CD_DESC]	 = 	INV.RPT_SRC_CD_DESC
          ,[RPT_SPOUSE_OF_OP]	 = 	ICC.CTT_RPT_SPOUSE_OF_OP
          ,[RSK_BEEN_INCARCERATD_12MO_IND]	 = 	RI.RSK_BEEN_INCARCERATD_12MO_IND
          ,[RSK_COCAINE_USE_12MO_IND]	 = 	RI.RSK_COCAINE_USE_12MO_IND
          ,[RSK_CRACK_USE_12MO_IND]	 = 	RI.RSK_CRACK_USE_12MO_IND
          ,[RSK_ED_MEDS_USE_12MO_IND]	 = 	RI.RSK_ED_MEDS_USE_12MO_IND
          ,[RSK_HEROIN_USE_12MO_IND]	 = 	RI.RSK_HEROIN_USE_12MO_IND
          ,[RSK_INJ_DRUG_USE_12MO_IND]	 = 	RI.RSK_INJ_DRUG_USE_12MO_IND
          ,[RSK_METH_USE_12MO_IND]	 = 	RI.RSK_METH_USE_12MO_IND
          ,[RSK_NITR_POP_USE_12MO_IND]	 = 	RI.RSK_NITR_POP_USE_12MO_IND
          ,[RSK_NO_DRUG_USE_12MO_IND]	 = 	RI.RSK_NO_DRUG_USE_12MO_IND
          ,[RSK_OTHER_DRUG_SPEC]	 = 	RTRIM(LTRIM(RI.RSK_OTHER_DRUG_SPEC))
          ,[RSK_OTHER_DRUG_USE_12MO_IND]	 = 	RI.RSK_OTHER_DRUG_USE_12MO_IND
          ,[RSK_RISK_FACTORS_ASSESS_IND]	 = 	RI.RSK_RISK_FACTORS_ASSESS_IND
          ,[RSK_SEX_EXCH_DRGS_MNY_12MO_IND]	 = 	RI.RSK_SEX_EXCH_DRGS_MNY_12MO_IND
          ,[RSK_SEX_INTOXCTED_HGH_12MO_IND]	 = 	RI.RSK_SEX_INTOXCTED_HGH_12MO_IND
          ,[RSK_SEX_W_ANON_PTRNR_12MO_IND]	 = 	RI.RSK_SEX_W_ANON_PTRNR_12MO_IND
          ,[RSK_SEX_W_FEMALE_12MO_IND]	 = 	RI.RSK_SEX_W_FEMALE_12MO_IND
          ,[RSK_SEX_W_KNOWN_IDU_12MO_IND]	 = 	RI.RSK_SEX_W_KNOWN_IDU_12MO_IND
          ,[RSK_SEX_W_KNWN_MSM_12M_FML_IND]	 = 	RI.RSK_SEX_W_KNWN_MSM_12M_FML_IND
          ,[RSK_SEX_W_MALE_12MO_IND]	 = 	RI.RSK_SEX_W_MALE_12MO_IND
          ,[RSK_SEX_W_TRANSGNDR_12MO_IND]	 = 	RI.RSK_SEX_W_TRANSGNDR_12MO_IND
          ,[RSK_SEX_WOUT_CONDOM_12MO_IND]	 = 	RI.RSK_SEX_WOUT_CONDOM_12MO_IND
          ,[RSK_SHARED_INJ_EQUIP_12MO_IND]	 = 	RI.RSK_SHARED_INJ_EQUIP_12MO_IND
          ,[RSK_TARGET_POPULATIONS]	 = 	RI.RSK_TARGET_POPULATIONS
          ,[SOC_FEMALE_PRTNRS_12MO_IND]	 = 	SH.SOC_FEMALE_PRTNRS_12MO_IND
          ,[SOC_FEMALE_PRTNRS_12MO_TTL]	 = 	SH.SOC_FEMALE_PRTNRS_12MO_TTL
          ,[SOC_MALE_PRTNRS_12MO_IND]	 = 	SH.SOC_MALE_PRTNRS_12MO_IND
          ,[SOC_MALE_PRTNRS_12MO_TOTAL]	 = 	SH.SOC_MALE_PRTNRS_12MO_TOTAL
          ,[SOC_PLACES_TO_HAVE_SEX]	 = 	SH.SOC_PLACES_TO_HAVE_SEX
          ,[SOC_PLACES_TO_MEET_PARTNER]	 = 	SH.SOC_PLACES_TO_MEET_PARTNER
          ,[SOC_PRTNRS_PRD_FML_IND]	 = 	SH.SOC_PRTNRS_PRD_FML_IND
          ,[SOC_PRTNRS_PRD_FML_TTL]	 = 	SH.SOC_PRTNRS_PRD_FML_TTL
          ,[SOC_PRTNRS_PRD_MALE_IND]	 = 	SH.SOC_PRTNRS_PRD_MALE_IND
          ,[SOC_PRTNRS_PRD_MALE_TTL]	 = 	SH.SOC_PRTNRS_PRD_MALE_TTL
          ,[SOC_PRTNRS_PRD_TRNSGNDR_IND]	 = 	SH.SOC_PRTNRS_PRD_TRNSGNDR_IND
          ,[SOC_SX_PRTNRS_INTNT_12MO_IND]	 = 	SH.SOC_SX_PRTNRS_INTNT_12MO_IND
          ,[SOC_TRANSGNDR_PRTNRS_12MO_IND]	 = 	SH.SOC_TRANSGNDR_PRTNRS_12MO_IND
          ,[SOC_TRANSGNDR_PRTNRS_12MO_TTL]	 = 	SH.SOC_TRANSGNDR_PRTNRS_12MO_TTL
          ,[SOURCE_SPREAD]	 = 	EPI.SOURCE_SPREAD
          ,[STD_PRTNRS_PRD_TRNSGNDR_TTL]	 = 	SH.SOC_PRTNRS_PRD_TRNSGNDR_TTL
          ,[SURV_CLOSED_DT]	 = 	CM.SURV_CLOSED_DT
          ,[SURV_INVESTIGATOR_ASSGN_DT]	 = 	CM.SURV_INVESTIGATOR_ASSGN_DT
          ,[SURV_PATIENT_FOLL_UP]	 = 	CM.SURV_PATIENT_FOLL_UP_CD
          ,[SURV_PROVIDER_CONTACT]	 = 	CM.SURV_PROVIDER_CONTACT_CD
          ,[SURV_PROVIDER_EXAM_REASON]	 = 	CM.SURV_PROVIDER_EXAM_REASON
          ,[SYM_NEUROLOGIC_SIGN_SYM]	 = 	SYM.SYM_NEUROLOGIC_SIGN_SYM
          ,[SYM_OCULAR_MANIFESTATIONS]	 = 	SYM.SYM_OCULAR_MANIFESTATIONS
          ,[SYM_OTIC_MANIFESTATION]	 = 	SYM.SYM_OTIC_MANIFESTATION
          ,[SYM_LATE_CLINICAL_MANIFES]	 = 	SYM.SYM_LATE_CLINICAL_MANIFES
          ,[TRT_TREATMENT_DATE]	 = 	TRT.TRT_TREATMENT_DATE
        FROM [dbo].[STD_HIV_DATAMART] shd
                 INNER JOIN dbo.F_STD_PAGE_CASE PC ON  shd.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                 INNER JOIN #tmp_investigation INV ON INV.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                 LEFT JOIN dbo.CONDITION COND ON COND.CONDITION_KEY = PC.CONDITION_KEY
                 LEFT JOIN (SELECT DISTINCT INVESTIGATION_KEY, CONFIRMATION_DT         -- CAN HAVE MULTIPLE METHODS BUT THE DATE IS ALWAYS THE SAME
                            FROM dbo.CONFIRMATION_METHOD_GROUP) AS CONF ON CONF.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                 LEFT JOIN dbo.D_CASE_MANAGEMENT CM ON CM.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                 LEFT JOIN dbo.D_INV_ADMINISTRATIVE AM ON AM.D_INV_ADMINISTRATIVE_KEY = PC.D_INV_ADMINISTRATIVE_KEY
                 LEFT JOIN dbo.D_INV_CLINICAL CLN ON CLN.D_INV_CLINICAL_KEY = PC.D_INV_CLINICAL_KEY
                 LEFT JOIN dbo.D_INV_COMPLICATION CMP ON CMP.D_INV_COMPLICATION_KEY = PC.D_INV_COMPLICATION_KEY
                 LEFT JOIN dbo.D_INV_CONTACT ICC ON ICC.D_INV_CONTACT_KEY = PC.D_INV_CONTACT_KEY
                 LEFT JOIN dbo.D_INV_EPIDEMIOLOGY EPI ON EPI.D_INV_EPIDEMIOLOGY_KEY = PC.D_INV_EPIDEMIOLOGY_KEY
                 LEFT JOIN dbo.INV_HIV HIV ON HIV.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                 LEFT JOIN dbo.D_INV_LAB_FINDING LF ON LF.D_INV_LAB_FINDING_KEY = PC.D_INV_LAB_FINDING_KEY
                 LEFT JOIN dbo.D_INV_MEDICAL_HISTORY MH ON MH.D_INV_MEDICAL_HISTORY_KEY = PC.D_INV_MEDICAL_HISTORY_KEY
                 LEFT JOIN dbo.D_INV_PATIENT_OBS OBS ON OBS.D_INV_PATIENT_OBS_KEY = PC.D_INV_PATIENT_OBS_KEY
                 LEFT JOIN dbo.D_INV_PREGNANCY_BIRTH PBI ON PBI.D_INV_PREGNANCY_BIRTH_KEY = PC.D_INV_PREGNANCY_BIRTH_KEY
                 LEFT JOIN dbo.D_INV_RISK_FACTOR RI ON RI.D_INV_RISK_FACTOR_KEY = PC.D_INV_RISK_FACTOR_KEY
                 LEFT JOIN dbo.D_INV_SOCIAL_HISTORY SH ON SH.D_INV_SOCIAL_HISTORY_KEY = PC.D_INV_SOCIAL_HISTORY_KEY
                 LEFT JOIN dbo.D_INV_SYMPTOM SYM ON SYM.D_INV_SYMPTOM_KEY = PC.D_INV_SYMPTOM_KEY
                 LEFT JOIN dbo.D_INV_TREATMENT TRT ON TRT.D_INV_TREATMENT_KEY = PC.D_INV_TREATMENT_KEY
                 LEFT JOIN dbo.D_PATIENT PAT ON PAT.PATIENT_KEY = PC.PATIENT_KEY
                 LEFT JOIN dbo.D_PROVIDER INVEST ON INVEST.PROVIDER_KEY = PC.CLOSED_BY_KEY
            AND INVEST.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER CRNTI ON CRNTI.PROVIDER_KEY = PC.INVESTIGATOR_KEY
            AND CRNTI.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER DISP ON DISP.PROVIDER_KEY = PC.DISPOSITIONED_BY_KEY
            AND DISP.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER FLD ON FLD.PROVIDER_KEY = PC.INVSTGTR_FLD_FOLLOW_UP_KEY
            AND FLD.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER INITIV ON INITIV.PROVIDER_KEY = PC.INIT_ASGNED_INTERVIEWER_KEY
            AND INITIV.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER FUP ON FUP.PROVIDER_KEY = PC.INIT_ASGNED_FLD_FOLLOW_UP_KEY
            AND FUP.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER INIT ON INIT.PROVIDER_KEY = PC.INIT_FOLLOW_UP_INVSTGTR_KEY
            AND INIT.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER IVW ON IVW.PROVIDER_KEY = PC.INTERVIEWER_ASSIGNED_KEY
            AND IVW.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER SUPV ON SUPV.PROVIDER_KEY = PC.SUPRVSR_OF_CASE_ASSGNMENT_KEY
            AND SUPV.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER SUPVFUP ON SUPVFUP.PROVIDER_KEY = PC.SUPRVSR_OF_FLD_FOLLOW_UP_KEY
            AND SUPVFUP.PROVIDER_KEY != 1
                 LEFT JOIN dbo.D_PROVIDER SURV ON SURV.PROVIDER_KEY = PC.SURVEILLANCE_INVESTIGATOR_KEY
            AND SURV.PROVIDER_KEY != 1
                 LEFT JOIN (SELECT IXC.INVESTIGATION_KEY, DV.IX_DATE
                            FROM dbo.F_INTERVIEW_CASE IXC
                                     LEFT JOIN dbo.D_INTERVIEW DV ON DV.D_INTERVIEW_KEY = IXC.D_INTERVIEW_KEY
                            WHERE DV.IX_TYPE_CD = 'INITIAL'
                              AND DV.RECORD_STATUS_CD = 'ACTIVE') DIVW ON DIVW.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
        WHERE
            INV.RECORD_STATUS_CD = 'ACTIVE'
          AND PC.PATIENT_KEY != 1
          AND EXISTS
            (
                SELECT 1 FROM DBO.STD_HIV_DATAMART shd
                WHERE shd.INVESTIGATION_KEY = PC.INVESTIGATION_KEY

            );

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@Batch_id,'STD_HIV_DATAMART','STD_HIV_DATAMART','START',@Proc_Step_no,@Proc_Step_name,@RowCount_no);

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @Proc_Step_Name = 'Insert into STD_HIV_DATAMART';
        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;

        INSERT INTO [dbo].[STD_HIV_DATAMART]
        ([ADI_900_STATUS]
        ,[ADI_900_STATUS_CD]
        ,[ADM_REFERRAL_BASIS_OOJ]
        ,[ADM_RPTNG_CNTY]
        ,[CA_INIT_INTVWR_ASSGN_DT]
        ,[CA_INTERVIEWER_ASSIGN_DT]
        ,[CA_PATIENT_INTV_STATUS]
        ,[CALC_5_YEAR_AGE_GROUP]
        ,[CASE_RPT_MMWR_WK]
        ,[CASE_RPT_MMWR_YR]
        ,[CC_CLOSED_DT]
        ,[CLN_CARE_STATUS_CLOSE_DT]
        ,[CLN_CONDITION_RESISTANT_TO]
        ,[CLN_DT_INIT_HLTH_EXM]
        ,[CLN_NEUROSYPHILLIS_IND]
        ,[CLN_PRE_EXP_PROPHY_IND]
        ,[CLN_PRE_EXP_PROPHY_REFER]
        ,[CLN_SURV_PROVIDER_DIAG_CD]
        ,[CMP_CONJUNCTIVITIS_IND]
        ,[CMP_PID_IND]
        ,[COINFECTION_ID]
        ,[CONDITION_CD]
        ,[CONDITION_KEY]
        ,[CONFIRMATION_DT]
        ,[CURR_PROCESS_STATE]
        ,[DETECTION_METHOD_DESC_TXT]
        ,[DIAGNOSIS]
        ,[DIAGNOSIS_CD]
        ,[DIE_FRM_THIS_ILLNESS_IND]
        ,[DISEASE_IMPORTED_IND]
        ,[DISSEMINATED_IND]
        ,[EPI_CNTRY_USUAL_RESID]
        ,[EPI_LINK_ID]
        ,[FACILITY_FLD_FOLLOW_UP_KEY]
        ,[FIELD_RECORD_NUMBER]
        ,[FL_FUP_ACTUAL_REF_TYPE]
        ,[FL_FUP_DISPO_DT]
        ,[FL_FUP_DISPOSITION]
        ,[FL_FUP_EXAM_DT]
        ,[FL_FUP_EXPECTED_DT]
        ,[FL_FUP_EXPECTED_IN_IND_CD]
        ,[FL_FUP_INIT_ASSGN_DT]
        ,[FL_FUP_INTERNET_OUTCOME_CD]
        ,[FL_FUP_INVESTIGATOR_ASSGN_DT]
        ,[FL_FUP_NOTIFICATION_PLAN]
        ,[FL_FUP_OOJ_OUTCOME]
        ,[FL_FUP_PROV_DIAGNOSIS_CD]
        ,[FL_FUP_PROV_EXM_REASON]
        ,[HIV_900_RESULT]
        ,[HIV_900_TEST_IND]
        ,[HIV_900_TEST_REFERRAL_DT]
        ,[HIV_AV_THERAPY_EVER_IND]
        ,[HIV_AV_THERAPY_LAST_12MO_IND]
        ,[HIV_CA_900_OTH_RSN_NOT_LO]
        ,[HIV_CA_900_REASON_NOT_LOC]
        ,[HIV_ENROLL_PRTNR_SRVCS_IND]
        ,[HIV_KEEP_900_CARE_APPT_IND]
        ,[HIV_LAST_900_TEST_DT]
        ,[HIV_POST_TEST_900_COUNSELING]
        ,[HIV_PREVIOUS_900_TEST_IND]
        ,[HIV_REFER_FOR_900_CARE_IND]
        ,[HIV_REFER_FOR_900_TEST]
        ,[HIV_RST_PROVIDED_900_RSLT_IND]
        ,[HIV_SELF_REPORTED_RSLT_900]
        ,[HIV_STATE_CASE_ID]
        ,[HOSPITAL_KEY]
        ,[HSPTLIZD_IND]
        ,[INVESTIGATION_KEY]
        ,[INIT_FUP_CLINIC_CODE]
        ,[INIT_FUP_CLOSED_DT]
        ,[INIT_FUP_INITIAL_FOLL_UP]
        ,[INIT_FUP_INTERNET_FOLL_UP]
        ,[INIT_FUP_INITIAL_FOLL_UP_CD]
        ,[INIT_FUP_INTERNET_FOLL_UP_CD]
        ,[INIT_FUP_NOTIFIABLE]
        ,[INITIATING_AGNCY]
        ,[INV_ASSIGNED_DT]
        ,[INV_CASE_STATUS]
        ,[INV_CLOSE_DT]
        ,[INV_LOCAL_ID]
        ,[INV_RPT_DT]
        ,[INV_START_DT]
        ,[INVESTIGATION_DEATH_DATE]
        ,[INVESTIGATION_STATUS]
        ,[INVESTIGATOR_CLOSED_KEY]
        ,[INVESTIGATOR_CLOSED_QC]
        ,[INVESTIGATOR_CURRENT_KEY]
        ,[INVESTIGATOR_CURRENT_QC]
        ,[INVESTIGATOR_DISP_FL_FUP_KEY]
        ,[INVESTIGATOR_DISP_FL_FUP_QC]
        ,[INVESTIGATOR_FL_FUP_KEY]
        ,[INVESTIGATOR_FL_FUP_QC]
        ,[INVESTIGATOR_INIT_INTRVW_KEY]
        ,[INVESTIGATOR_INIT_INTRVW_QC]
        ,[INVESTIGATOR_INIT_FL_FUP_KEY]
        ,[INVESTIGATOR_INIT_FL_FUP_QC]
        ,[INVESTIGATOR_INITIAL_KEY]
        ,[INVESTIGATOR_INITIAL_QC]
        ,[INVESTIGATOR_INTERVIEW_KEY]
        ,[INVESTIGATOR_INTERVIEW_QC]
        ,[INVESTIGATOR_SUPER_CASE_KEY]
        ,[INVESTIGATOR_SUPER_CASE_QC]
        ,[INVESTIGATOR_SUPER_FL_FUP_KEY]
        ,[INVESTIGATOR_SUPER_FL_FUP_QC]
        ,[INVESTIGATOR_SURV_KEY]
        ,[INVESTIGATOR_SURV_QC]
        ,[IPO_CURRENTLY_IN_INSTITUTION]
        ,[IPO_LIVING_WITH]
        ,[IPO_NAME_OF_INSTITUTITION]
        ,[IPO_TIME_AT_ADDRESS_NUM]
        ,[IPO_TIME_AT_ADDRESS_UNIT]
        ,[IPO_TIME_IN_COUNTRY_NUM]
        ,[IPO_TIME_IN_COUNTRY_UNIT]
        ,[IPO_TIME_IN_STATE_NUM]
        ,[IPO_TIME_IN_STATE_UNIT]
        ,[IPO_TYPE_OF_INSTITUTITION]
        ,[IPO_TYPE_OF_RESIDENCE]
        ,[IX_DATE_OI]
        ,[JURISDICTION_CD]
        ,[JURISDICTION_NM]
        ,[LAB_HIV_SPECIMEN_COLL_DT]
        ,[LAB_NONTREP_SYPH_RSLT_QNT]
        ,[LAB_NONTREP_SYPH_RSLT_QUA]
        ,[LAB_NONTREP_SYPH_TEST_TYP]
        ,[LAB_SYPHILIS_TST_PS_IND]
        ,[LAB_SYPHILIS_TST_RSLT_PS]
        ,[LAB_TESTS_PERFORMED]
        ,[LAB_TREP_SYPH_RESULT_QUAL]
        ,[LAB_TREP_SYPH_TEST_TYPE]
        ,[MDH_PREV_STD_HIST]
        ,[OOJ_AGENCY_SENT_TO]
        ,[OOJ_DUE_DATE_SENT_TO]
        ,[OOJ_FR_NUMBER_SENT_TO]
        ,[OOJ_INITG_AGNCY_OUTC_DUE_DATE]
        ,[OOJ_INITG_AGNCY_OUTC_SNT_DATE]
        ,[OOJ_INITG_AGNCY_RECD_DATE]
        ,[ORDERING_FACILITY_KEY]
        ,[OUTBREAK_IND]
        ,[OUTBREAK_NAME]
        ,[PATIENT_ADDL_GENDER_INFO]
        ,[PATIENT_AGE_AT_ONSET]
        ,[PATIENT_AGE_AT_ONSET_UNIT]
        ,[PATIENT_AGE_REPORTED]
        ,[PATIENT_ALIAS]
        ,[PATIENT_BIRTH_COUNTRY]
        ,[PATIENT_BIRTH_SEX]
        ,[PATIENT_CENSUS_TRACT]
        ,[PATIENT_CITY]
        ,[PATIENT_COUNTRY]
        ,[PATIENT_COUNTY]
        ,[PATIENT_CURR_SEX_UNK_RSN]
        ,[PATIENT_CURRENT_SEX]
        ,[PATIENT_DECEASED_DATE]
        ,[PATIENT_DECEASED_INDICATOR]
        ,[PATIENT_DOB]
        ,[PATIENT_EMAIL]
        ,[PATIENT_ETHNICITY]
        ,[PATIENT_LOCAL_ID]
        ,[PATIENT_MARITAL_STATUS]
        ,[PATIENT_NAME]
        ,[PATIENT_PHONE_CELL]
        ,[PATIENT_PHONE_HOME]
        ,[PATIENT_PHONE_WORK]
        ,[PATIENT_PREFERRED_GENDER]
        ,[PATIENT_PREGNANT_IND]
        ,[PATIENT_RACE]
        ,[PATIENT_SEX]
        ,[PATIENT_STATE]
        ,[PATIENT_STREET_ADDRESS_1]
        ,[PATIENT_STREET_ADDRESS_2]
        ,[PATIENT_UNK_ETHNIC_RSN]
        ,[PATIENT_ZIP]
        ,[PBI_IN_PRENATAL_CARE_IND]
        ,[PBI_PATIENT_PREGNANT_WKS]
        ,[PBI_PREG_AT_EXAM_IND]
        ,[PBI_PREG_AT_EXAM_WKS]
        ,[PBI_PREG_AT_IX_IND]
        ,[PBI_PREG_AT_IX_WKS]
        ,[PBI_PREG_IN_LAST_12MO_IND]
        ,[PBI_PREG_OUTCOME]
        ,[PHYSICIAN_FL_FUP_KEY]
        ,[PHYSICIAN_KEY]
        ,[PROGRAM_AREA_CD]
        ,[PROGRAM_JURISDICTION_OID]
        ,[REPORTING_ORG_KEY]
        ,[REPORTING_PROV_KEY]
        ,[RPT_ELICIT_INTERNET_INFO]
        ,[RPT_FIRST_NDLSHARE_EXP_DT]
        ,[RPT_FIRST_SEX_EXP_DT]
        ,[RPT_LAST_NDLSHARE_EXP_DT]
        ,[PROVIDER_REASON_VISIT_DT]
        ,[REFERRAL_BASIS]
        ,[RPT_LAST_SEX_EXP_DT]
        ,[RPT_MET_OP_INTERNET]
        ,[RPT_NDLSHARE_EXP_FREQ]
        ,[RPT_RELATIONSHIP_TO_OP]
        ,[RPT_SEX_EXP_FREQ]
        ,[RPT_SRC_CD_DESC]
        ,[RPT_SPOUSE_OF_OP]
        ,[RSK_BEEN_INCARCERATD_12MO_IND]
        ,[RSK_COCAINE_USE_12MO_IND]
        ,[RSK_CRACK_USE_12MO_IND]
        ,[RSK_ED_MEDS_USE_12MO_IND]
        ,[RSK_HEROIN_USE_12MO_IND]
        ,[RSK_INJ_DRUG_USE_12MO_IND]
        ,[RSK_METH_USE_12MO_IND]
        ,[RSK_NITR_POP_USE_12MO_IND]
        ,[RSK_NO_DRUG_USE_12MO_IND]
        ,[RSK_OTHER_DRUG_SPEC]
        ,[RSK_OTHER_DRUG_USE_12MO_IND]
        ,[RSK_RISK_FACTORS_ASSESS_IND]
        ,[RSK_SEX_EXCH_DRGS_MNY_12MO_IND]
        ,[RSK_SEX_INTOXCTED_HGH_12MO_IND]
        ,[RSK_SEX_W_ANON_PTRNR_12MO_IND]
        ,[RSK_SEX_W_FEMALE_12MO_IND]
        ,[RSK_SEX_W_KNOWN_IDU_12MO_IND]
        ,[RSK_SEX_W_KNWN_MSM_12M_FML_IND]
        ,[RSK_SEX_W_MALE_12MO_IND]
        ,[RSK_SEX_W_TRANSGNDR_12MO_IND]
        ,[RSK_SEX_WOUT_CONDOM_12MO_IND]
        ,[RSK_SHARED_INJ_EQUIP_12MO_IND]
        ,[RSK_TARGET_POPULATIONS]
        ,[SOC_FEMALE_PRTNRS_12MO_IND]
        ,[SOC_FEMALE_PRTNRS_12MO_TTL]
        ,[SOC_MALE_PRTNRS_12MO_IND]
        ,[SOC_MALE_PRTNRS_12MO_TOTAL]
        ,[SOC_PLACES_TO_HAVE_SEX]
        ,[SOC_PLACES_TO_MEET_PARTNER]
        ,[SOC_PRTNRS_PRD_FML_IND]
        ,[SOC_PRTNRS_PRD_FML_TTL]
        ,[SOC_PRTNRS_PRD_MALE_IND]
        ,[SOC_PRTNRS_PRD_MALE_TTL]
        ,[SOC_PRTNRS_PRD_TRNSGNDR_IND]
        ,[SOC_SX_PRTNRS_INTNT_12MO_IND]
        ,[SOC_TRANSGNDR_PRTNRS_12MO_IND]
        ,[SOC_TRANSGNDR_PRTNRS_12MO_TTL]
        ,[SOURCE_SPREAD]
        ,[STD_PRTNRS_PRD_TRNSGNDR_TTL]
        ,[SURV_CLOSED_DT]
        ,[SURV_INVESTIGATOR_ASSGN_DT]
        ,[SURV_PATIENT_FOLL_UP]
        ,[SURV_PROVIDER_CONTACT]
        ,[SURV_PROVIDER_EXAM_REASON]
        ,[SYM_NEUROLOGIC_SIGN_SYM]
        ,[SYM_OCULAR_MANIFESTATIONS]
        ,[SYM_OTIC_MANIFESTATION]
        ,[SYM_LATE_CLINICAL_MANIFES]
        ,[TRT_TREATMENT_DATE])
            (SELECT DISTINCT
                 STATUS_900
                           ,CM.ADI_900_STATUS_CD
                           ,AM.ADM_REFERRAL_BASIS_OOJ
                           ,AM.ADM_RPTNG_CNTY
                           ,CM.CA_INIT_INTVWR_ASSGN_DT
                           ,CM.CA_INTERVIEWER_ASSIGN_DT
                           ,CM.CA_PATIENT_INTV_STATUS
                           ,(CASE
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 0
                                     AND PAT.PATIENT_AGE_REPORTED <= 4
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN ' 1'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 5
                                     AND PAT.PATIENT_AGE_REPORTED <= 9
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN ' 2'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 10
                                     AND PAT.PATIENT_AGE_REPORTED <= 14
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN ' 3'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 15
                                     AND PAT.PATIENT_AGE_REPORTED <= 19
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN ' 4'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 20
                                     AND PAT.PATIENT_AGE_REPORTED <= 24
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN ' 5'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 25
                                     AND PAT.PATIENT_AGE_REPORTED <= 29
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN ' 6'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 30
                                     AND PAT.PATIENT_AGE_REPORTED <= 34
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN ' 7'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 35
                                     AND PAT.PATIENT_AGE_REPORTED <= 39
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN ' 8'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 40
                                     AND PAT.PATIENT_AGE_REPORTED <= 44
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN ' 9'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 45
                                     AND PAT.PATIENT_AGE_REPORTED <= 49
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN '10'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 50
                                     AND PAT.PATIENT_AGE_REPORTED <= 54
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN '11'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 55
                                     AND PAT.PATIENT_AGE_REPORTED <= 59
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN '12'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 60
                                     AND PAT.PATIENT_AGE_REPORTED <= 64
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN '13'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 65
                                     AND PAT.PATIENT_AGE_REPORTED <= 69
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN '14'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 70
                                     AND PAT.PATIENT_AGE_REPORTED <= 74
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN '15'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 75
                                     AND PAT.PATIENT_AGE_REPORTED <= 79
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN '16'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 80
                                     AND PAT.PATIENT_AGE_REPORTED <= 84
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN '17'
                                 WHEN PAT.PATIENT_AGE_REPORTED >= 85
                                     AND PAT.PATIENT_AGE_REPORTED_UNIT = 'YEARS'
                                     THEN '18'
                                 ELSE NULL END )
                           ,INV.CASE_RPT_MMWR_WK
                           ,INV.CASE_RPT_MMWR_YR
                           ,CM.CC_CLOSED_DT
                           ,CLN.CLN_CARE_STATUS_CLOSE_DT
                           ,CLN.CLN_CONDITION_RESISTANT_TO
                           ,CLN.CLN_DT_INIT_HLTH_EXM
                           ,CLN.CLN_NEUROSYPHILLIS_IND
                           ,CLN.CLN_PRE_EXP_PROPHY_IND
                           ,CLN.CLN_PRE_EXP_PROPHY_REFER
                           ,CM.SURV_PROVIDER_DIAGNOSIS
                           ,CMP.CMP_CONJUNCTIVITIS_IND
                           ,CMP.CMP_PID_IND
                           ,INV.COINFECTION_ID
                           ,COND.CONDITION_CD
                           ,COND.CONDITION_KEY
                           ,CAST(FORMAT(CONF.CONFIRMATION_DT, 'yyyy-MM-dd') AS datetime)
                           ,INV.CURR_PROCESS_STATE
                           ,INV.DETECTION_METHOD_DESC_TXT
                           ,CLN.CLN_CASE_DIAGNOSIS
                           ,SUBSTRING(CLN.CLN_CASE_DIAGNOSIS, 1, 3)
                           ,INV.DIE_FRM_THIS_ILLNESS_IND
                           ,INV.DISEASE_IMPORTED_IND
                           ,AM.ADM_DISSEMINATED_IND
                           ,EPI.EPI_CNTRY_USUAL_RESID
                           ,CM.EPI_LINK_ID
                           ,PC.FACILITY_FLD_FOLLOW_UP_KEY
                           ,CM.FL_FUP_FIELD_RECORD_NUM
                           ,CM.FL_FUP_ACTUAL_REF_TYPE
                           ,CM.FL_FUP_DISPO_DT
                           ,CM.FL_FUP_DISPOSITION_DESC
                           ,CM.FL_FUP_EXAM_DT
                           ,CM.FL_FUP_EXPECTED_DT
                           -- CODE TO GENERATE THE CORRECT FL_FUP_EXPECTED_IND_CD FIELD AS WILL BE IN THE NBS 6.2 RELEASE (DEFECT 12626)
                           ,SUBSTRING(CM.FL_FUP_EXPECTED_IN_IND, 1, 1)
                           ,CM.FL_FUP_INIT_ASSGN_DT
                           ,CM.FL_FUP_INTERNET_OUTCOME_CD
                           ,CM.FL_FUP_INVESTIGATOR_ASSGN_DT
                           ,CM.FL_FUP_NOTIFICATION_PLAN_CD
                           ,CM.FL_FUP_OOJ_OUTCOME
                           ,SUBSTRING(CM.FL_FUP_PROV_DIAGNOSIS, 1, 3)
                           ,CM.FL_FUP_PROV_EXM_REASON
                           ,RTRIM(LTRIM(HIV.HIV_900_RESULT))
                           ,HIV.HIV_900_TEST_IND
                           ,HIV.HIV_900_TEST_REFERRAL_DT
                           ,HIV.HIV_AV_THERAPY_EVER_IND
                           ,HIV.HIV_AV_THERAPY_LAST_12MO_IND
                           ,RTRIM(LTRIM(HIV.HIV_CA_900_OTH_RSN_NOT_LO))
                           ,HIV.HIV_CA_900_REASON_NOT_LOC
                           ,HIV.HIV_ENROLL_PRTNR_SRVCS_IND
                           ,HIV.HIV_KEEP_900_CARE_APPT_IND
                           ,HIV.HIV_LAST_900_TEST_DT
                           ,RTRIM(LTRIM(HIV.HIV_POST_TEST_900_COUNSELING))
                           ,HIV.HIV_PREVIOUS_900_TEST_IND
                           ,HIV.HIV_REFER_FOR_900_CARE_IND
                           ,RTRIM(LTRIM(HIV.HIV_REFER_FOR_900_TEST))
                           ,HIV.HIV_RST_PROVIDED_900_RSLT_IND
                           ,HIV.HIV_SELF_REPORTED_RSLT_900
                           ,RTRIM(LTRIM(HIV.HIV_STATE_CASE_ID))
                           ,PC.HOSPITAL_KEY
                           ,INV.HSPTLIZD_IND
                           ,PC.INVESTIGATION_KEY
                           ,CM.INIT_FUP_CLINIC_CODE
                           ,CM.INIT_FUP_CLOSED_DT
                           ,CM.INIT_FUP_INITIAL_FOLL_UP
                           ,CM.INIT_FUP_INTERNET_FOLL_UP_CD
                           ,CM.INIT_FUP_INITIAL_FOLL_UP_CD
                           ,CM.INIT_FUP_INTERNET_FOLL_UP_CD
                           ,CM.INIT_FUP_NOTIFIABLE_CD
                           ,CM.INITIATING_AGNCY
                           ,CAST(FORMAT(INV.INV_ASSIGNED_DT, 'yyyy-MM-dd') AS datetime)
                           ,INV.INV_CASE_STATUS
                           ,CAST(FORMAT(INV.INV_CLOSE_DT, 'yyyy-MM-dd') AS datetime)
                           ,INV.INV_LOCAL_ID
                           ,CAST(FORMAT(INV.INV_RPT_DT, 'yyyy-MM-dd') AS datetime)
                           ,CAST(FORMAT(INV.INV_START_DT, 'yyyy-MM-dd') AS datetime)
                           ,CAST(FORMAT(INV.INVESTIGATION_DEATH_DATE, 'yyyy-MM-dd') AS datetime)
                           ,INV.INVESTIGATION_STATUS
                           ,PC.CLOSED_BY_KEY
                           ,INVEST.PROVIDER_QUICK_CODE
                           ,PC.INVESTIGATOR_KEY
                           ,CRNTI.PROVIDER_QUICK_CODE
                           ,PC.DISPOSITIONED_BY_KEY
                           ,DISP.PROVIDER_QUICK_CODE
                           ,PC.INVSTGTR_FLD_FOLLOW_UP_KEY
                           ,FLD.PROVIDER_QUICK_CODE
                           ,PC.INIT_ASGNED_INTERVIEWER_KEY
                           ,INITIV.PROVIDER_QUICK_CODE
                           ,PC.INIT_ASGNED_FLD_FOLLOW_UP_KEY
                           ,FUP.PROVIDER_QUICK_CODE
                           ,PC.INIT_FOLLOW_UP_INVSTGTR_KEY
                           ,INIT.PROVIDER_QUICK_CODE
                           ,PC.INTERVIEWER_ASSIGNED_KEY
                           ,IVW.PROVIDER_QUICK_CODE
                           ,PC.SUPRVSR_OF_CASE_ASSGNMENT_KEY
                           ,SUPV.PROVIDER_QUICK_CODE
                           ,PC.SUPRVSR_OF_FLD_FOLLOW_UP_KEY
                           ,SUPVFUP.PROVIDER_QUICK_CODE
                           ,PC.SURVEILLANCE_INVESTIGATOR_KEY
                           ,SURV.PROVIDER_QUICK_CODE
                           ,OBS.IPO_CURRENTLY_IN_INSTITUTION
                           ,RTRIM(LTRIM(OBS.IPO_LIVING_WITH))
                           ,RTRIM(LTRIM(OBS.IPO_NAME_OF_INSTITUTITION))
                           ,OBS.IPO_TIME_AT_ADDRESS_NUM
                           ,OBS.IPO_TIME_AT_ADDRESS_UNIT
                           ,OBS.IPO_TIME_IN_COUNTRY_NUM
                           ,OBS.IPO_TIME_IN_COUNTRY_UNIT
                           ,OBS.IPO_TIME_IN_STATE_NUM
                           ,OBS.IPO_TIME_IN_STATE_UNIT
                           ,RTRIM(LTRIM(OBS.IPO_TYPE_OF_INSTITUTITION))
                           ,OBS.IPO_TYPE_OF_RESIDENCE
                           ,CAST(FORMAT(DIVW.IX_DATE, 'yyyy-MM-dd') AS datetime)
                           ,INV.JURISDICTION_CD
                           ,INV.JURISDICTION_NM
                           ,LF.LAB_HIV_SPECIMEN_COLL_DT
                           ,LF.LAB_NONTREP_SYPH_RSLT_QNT
                           ,LF.LAB_NONTREP_SYPH_RSLT_QUA
                           ,LF.LAB_NONTREP_SYPH_TEST_TYP
                           ,LF.LAB_SYPHILIS_TST_PS_IND
                           ,LF.LAB_SYPHILIS_TST_RSLT_PS
                           ,LF.LAB_TESTS_PERFORMED
                           ,LF.LAB_TREP_SYPH_RESULT_QUAL
                           ,LF.LAB_TREP_SYPH_TEST_TYPE
                           ,MH.MDH_PREV_STD_HIST
                           ,CM.OOJ_AGENCY
                           ,CAST(FORMAT(CM.OOJ_DUE_DATE, 'yyyy-MM-dd') AS datetime)
                           ,CM.OOJ_NUMBER
                           ,CAST(FORMAT(CM.OOJ_INITG_AGNCY_OUTC_DUE_DATE, 'yyyy-MM-dd') AS datetime)
                           ,CAST(FORMAT(CM.OOJ_INITG_AGNCY_OUTC_SNT_DATE, 'yyyy-MM-dd') AS datetime)
                           ,CAST(FORMAT(CM.OOJ_INITG_AGNCY_RECD_DATE, 'yyyy-MM-dd') AS datetime)
                           ,PC.ORDERING_FACILITY_KEY
                           ,INV.OUTBREAK_IND
                           ,INV.OUTBREAK_NAME
                           ,PAT.PATIENT_ADDL_GENDER_INFO
                           ,INV.PATIENT_AGE_AT_ONSET
                           ,INV.PATIENT_AGE_AT_ONSET_UNIT
                           -- EMULATING THE SAS PROCESS, NOT SURE WHY SAS DOES THIS BUT MAKING IT THE SAME
                           ,CASE
                                WHEN PAT.PATIENT_AGE_REPORTED IS NULL
                                    AND PAT.PATIENT_AGE_REPORTED_UNIT IS NULL THEN '           .'
                                WHEN PAT.PATIENT_AGE_REPORTED IS NULL THEN RTRIM('           .'+ ' ' + PAT.PATIENT_AGE_REPORTED_UNIT)
                                WHEN PAT.PATIENT_AGE_REPORTED_UNIT IS NULL THEN (SELECT RIGHT('            ' + CAST(PAT.PATIENT_AGE_REPORTED AS VARCHAR(50)), 12))
                                ELSE (SELECT RIGHT('            ' + CAST(PAT.PATIENT_AGE_REPORTED AS VARCHAR(50)), 12) + ' ' + PAT.PATIENT_AGE_REPORTED_UNIT)
                    END
                           ,PAT.PATIENT_ALIAS_NICKNAME
                           ,PAT.PATIENT_BIRTH_COUNTRY
                           ,PAT.PATIENT_BIRTH_SEX
                           ,PAT.PATIENT_CENSUS_TRACT
                           ,PAT.PATIENT_CITY
                           ,PAT.PATIENT_COUNTRY
                           ,PAT.PATIENT_COUNTY
                           ,PAT.PATIENT_CURR_SEX_UNK_RSN
                           ,PAT.PATIENT_CURRENT_SEX
                           ,CAST(FORMAT(PAT.PATIENT_DECEASED_DATE, 'yyyy-MM-dd') AS datetime)
                           ,PAT.PATIENT_DECEASED_INDICATOR
                           ,CAST(FORMAT(PAT.PATIENT_DOB, 'yyyy-MM-dd') AS datetime)
                           ,PAT.PATIENT_EMAIL
                           ,PAT.PATIENT_ETHNICITY
                           ,PAT.PATIENT_LOCAL_ID
                           ,PAT.PATIENT_MARITAL_STATUS
                           ,RTRIM((ISNULL(RTRIM(LTRIM(PAT.PATIENT_LAST_NAME)), ' ') + ', ' +
                                   ISNULL(RTRIM(LTRIM(PAT.PATIENT_FIRST_NAME)), ' ') + ' ' +
                                   ISNULL(RTRIM(LTRIM(PAT.PATIENT_MIDDLE_NAME)), '')))
                           ,PAT.PATIENT_PHONE_CELL
                           -- EMULATE SAS
                           ,CASE
                                WHEN PAT.PATIENT_PHONE_EXT_HOME IS NULL THEN PAT.PATIENT_PHONE_HOME
                                ELSE ISNULL(PAT.PATIENT_PHONE_HOME, ' ') + ' Ext ' + PAT.PATIENT_PHONE_EXT_HOME
                    END
                           ,CASE
                                WHEN PAT.PATIENT_PHONE_EXT_WORK IS NULL THEN PAT.PATIENT_PHONE_WORK
                                ELSE ISNULL(PAT.PATIENT_PHONE_WORK, ' ') + ' Ext ' + PAT.PATIENT_PHONE_EXT_WORK
                    END
                           ,PAT.PATIENT_PREFERRED_GENDER
                           ,INV.PATIENT_PREGNANT_IND
                           ,PAT.PATIENT_RACE_CALCULATED
                           ,CASE
                                WHEN PAT.PATIENT_PREFERRED_GENDER IS NULL THEN ISNULL(PAT.PATIENT_CURR_SEX_UNK_RSN, PAT.PATIENT_CURRENT_SEX)
                                ELSE PAT.PATIENT_PREFERRED_GENDER
                    END
                           ,PAT.PATIENT_STATE
                           ,PAT.PATIENT_STREET_ADDRESS_1
                           ,PAT.PATIENT_STREET_ADDRESS_2
                           ,PAT.PATIENT_UNK_ETHNIC_RSN
                           ,PAT.PATIENT_ZIP
                           ,PBI.PBI_IN_PRENATAL_CARE_IND
                           ,PBI.PBI_PATIENT_PREGNANT_WKS
                           ,PBI.PBI_PREG_AT_EXAM_IND
                           ,PBI.PBI_PREG_AT_EXAM_WKS
                           ,PBI.PBI_PREG_AT_IX_IND
                           ,PBI.PBI_PREG_AT_IX_WKS
                           ,PBI.PBI_PREG_IN_LAST_12MO_IND
                           ,PBI.PBI_PREG_OUTCOME_CD
                           ,PC.PROVIDER_FLD_FOLLOW_UP_KEY
                           ,PC.PHYSICIAN_KEY
                           ,COND.PROGRAM_AREA_CD
                           ,INV.CASE_OID
                           ,PC.ORG_AS_REPORTER_KEY
                           ,PC.PERSON_AS_REPORTER_KEY
                           ,ICC.CTT_RPT_ELICIT_INTERNET_INFO
                           ,ICC.CTT_RPT_FIRST_NDLSHARE_EXP_DT
                           ,ICC.CTT_RPT_FIRST_SEX_EXP_DT
                           ,ICC.CTT_RPT_LAST_NDLSHARE_EXP_DT
                           ,MH.MDH_PROVIDER_REASON_VISIT_DT
                           ,INV.REFERRAL_BASIS
                           ,ICC.CTT_RPT_LAST_SEX_EXP_DT
                           ,ICC.CTT_RPT_MET_OP_INTERNET
                           ,ICC.CTT_RPT_NDLSHARE_EXP_FREQ
                           ,ICC.CTT_RPT_RELATIONSHIP_TO_OP
                           ,ICC.CTT_RPT_SEX_EXP_FREQ
                           ,INV.RPT_SRC_CD_DESC
                           ,ICC.CTT_RPT_SPOUSE_OF_OP
                           ,RI.RSK_BEEN_INCARCERATD_12MO_IND
                           ,RI.RSK_COCAINE_USE_12MO_IND
                           ,RI.RSK_CRACK_USE_12MO_IND
                           ,RI.RSK_ED_MEDS_USE_12MO_IND
                           ,RI.RSK_HEROIN_USE_12MO_IND
                           ,RI.RSK_INJ_DRUG_USE_12MO_IND
                           ,RI.RSK_METH_USE_12MO_IND
                           ,RI.RSK_NITR_POP_USE_12MO_IND
                           ,RI.RSK_NO_DRUG_USE_12MO_IND
                           ,RTRIM(LTRIM(RI.RSK_OTHER_DRUG_SPEC))
                           ,RI.RSK_OTHER_DRUG_USE_12MO_IND
                           ,RI.RSK_RISK_FACTORS_ASSESS_IND
                           ,RI.RSK_SEX_EXCH_DRGS_MNY_12MO_IND
                           ,RI.RSK_SEX_INTOXCTED_HGH_12MO_IND
                           ,RI.RSK_SEX_W_ANON_PTRNR_12MO_IND
                           ,RI.RSK_SEX_W_FEMALE_12MO_IND
                           ,RI.RSK_SEX_W_KNOWN_IDU_12MO_IND
                           ,RI.RSK_SEX_W_KNWN_MSM_12M_FML_IND
                           ,RI.RSK_SEX_W_MALE_12MO_IND
                           ,RI.RSK_SEX_W_TRANSGNDR_12MO_IND
                           ,RI.RSK_SEX_WOUT_CONDOM_12MO_IND
                           ,RI.RSK_SHARED_INJ_EQUIP_12MO_IND
                           ,RI.RSK_TARGET_POPULATIONS
                           ,SH.SOC_FEMALE_PRTNRS_12MO_IND
                           ,SH.SOC_FEMALE_PRTNRS_12MO_TTL
                           ,SH.SOC_MALE_PRTNRS_12MO_IND
                           ,SH.SOC_MALE_PRTNRS_12MO_TOTAL
                           ,SH.SOC_PLACES_TO_HAVE_SEX
                           ,SH.SOC_PLACES_TO_MEET_PARTNER
                           ,SH.SOC_PRTNRS_PRD_FML_IND
                           ,SH.SOC_PRTNRS_PRD_FML_TTL
                           ,SH.SOC_PRTNRS_PRD_MALE_IND
                           ,SH.SOC_PRTNRS_PRD_MALE_TTL
                           ,SH.SOC_PRTNRS_PRD_TRNSGNDR_IND
                           ,SH.SOC_SX_PRTNRS_INTNT_12MO_IND
                           ,SH.SOC_TRANSGNDR_PRTNRS_12MO_IND
                           ,SH.SOC_TRANSGNDR_PRTNRS_12MO_TTL
                           ,EPI.SOURCE_SPREAD
                           ,SH.SOC_PRTNRS_PRD_TRNSGNDR_TTL
                           ,CM.SURV_CLOSED_DT
                           ,CM.SURV_INVESTIGATOR_ASSGN_DT
                           ,CM.SURV_PATIENT_FOLL_UP_CD
                           ,CM.SURV_PROVIDER_CONTACT_CD
                           ,CM.SURV_PROVIDER_EXAM_REASON
                           ,SYM.SYM_NEUROLOGIC_SIGN_SYM
                           ,SYM.SYM_OCULAR_MANIFESTATIONS
                           ,SYM.SYM_OTIC_MANIFESTATION
                           ,SYM.SYM_LATE_CLINICAL_MANIFES
                           ,TRT.TRT_TREATMENT_DATE

             FROM dbo.F_STD_PAGE_CASE PC
                      INNER JOIN #tmp_investigation INV ON INV.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                      LEFT JOIN dbo.CONDITION COND ON COND.CONDITION_KEY = PC.CONDITION_KEY
                      LEFT JOIN (SELECT DISTINCT INVESTIGATION_KEY, CONFIRMATION_DT         -- CAN HAVE MULTIPLE METHODS BUT THE DATE IS ALWAYS THE SAME
                                 FROM dbo.CONFIRMATION_METHOD_GROUP) AS CONF ON CONF.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                      LEFT JOIN dbo.D_CASE_MANAGEMENT CM ON CM.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                      LEFT JOIN dbo.D_INV_ADMINISTRATIVE AM ON AM.D_INV_ADMINISTRATIVE_KEY = PC.D_INV_ADMINISTRATIVE_KEY
                      LEFT JOIN dbo.D_INV_CLINICAL CLN ON CLN.D_INV_CLINICAL_KEY = PC.D_INV_CLINICAL_KEY
                      LEFT JOIN dbo.D_INV_COMPLICATION CMP ON CMP.D_INV_COMPLICATION_KEY = PC.D_INV_COMPLICATION_KEY
                      LEFT JOIN dbo.D_INV_CONTACT ICC ON ICC.D_INV_CONTACT_KEY = PC.D_INV_CONTACT_KEY
                      LEFT JOIN dbo.D_INV_EPIDEMIOLOGY EPI ON EPI.D_INV_EPIDEMIOLOGY_KEY = PC.D_INV_EPIDEMIOLOGY_KEY
                      LEFT JOIN dbo.INV_HIV HIV ON HIV.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
                      LEFT JOIN dbo.D_INV_LAB_FINDING LF ON LF.D_INV_LAB_FINDING_KEY = PC.D_INV_LAB_FINDING_KEY
                      LEFT JOIN dbo.D_INV_MEDICAL_HISTORY MH ON MH.D_INV_MEDICAL_HISTORY_KEY = PC.D_INV_MEDICAL_HISTORY_KEY
                      LEFT JOIN dbo.D_INV_PATIENT_OBS OBS ON OBS.D_INV_PATIENT_OBS_KEY = PC.D_INV_PATIENT_OBS_KEY
                      LEFT JOIN dbo.D_INV_PREGNANCY_BIRTH PBI ON PBI.D_INV_PREGNANCY_BIRTH_KEY = PC.D_INV_PREGNANCY_BIRTH_KEY
                      LEFT JOIN dbo.D_INV_RISK_FACTOR RI ON RI.D_INV_RISK_FACTOR_KEY = PC.D_INV_RISK_FACTOR_KEY
                      LEFT JOIN dbo.D_INV_SOCIAL_HISTORY SH ON SH.D_INV_SOCIAL_HISTORY_KEY = PC.D_INV_SOCIAL_HISTORY_KEY
                      LEFT JOIN dbo.D_INV_SYMPTOM SYM ON SYM.D_INV_SYMPTOM_KEY = PC.D_INV_SYMPTOM_KEY
                      LEFT JOIN dbo.D_INV_TREATMENT TRT ON TRT.D_INV_TREATMENT_KEY = PC.D_INV_TREATMENT_KEY
                      LEFT JOIN dbo.D_PATIENT PAT ON PAT.PATIENT_KEY = PC.PATIENT_KEY
                      LEFT JOIN dbo.D_PROVIDER INVEST ON INVEST.PROVIDER_KEY = PC.CLOSED_BY_KEY
                 AND INVEST.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER CRNTI ON CRNTI.PROVIDER_KEY = PC.INVESTIGATOR_KEY
                 AND CRNTI.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER DISP ON DISP.PROVIDER_KEY = PC.DISPOSITIONED_BY_KEY
                 AND DISP.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER FLD ON FLD.PROVIDER_KEY = PC.INVSTGTR_FLD_FOLLOW_UP_KEY
                 AND FLD.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER INITIV ON INITIV.PROVIDER_KEY = PC.INIT_ASGNED_INTERVIEWER_KEY
                 AND INITIV.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER FUP ON FUP.PROVIDER_KEY = PC.INIT_ASGNED_FLD_FOLLOW_UP_KEY
                 AND FUP.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER INIT ON INIT.PROVIDER_KEY = PC.INIT_FOLLOW_UP_INVSTGTR_KEY
                 AND INIT.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER IVW ON IVW.PROVIDER_KEY = PC.INTERVIEWER_ASSIGNED_KEY
                 AND IVW.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER SUPV ON SUPV.PROVIDER_KEY = PC.SUPRVSR_OF_CASE_ASSGNMENT_KEY
                 AND SUPV.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER SUPVFUP ON SUPVFUP.PROVIDER_KEY = PC.SUPRVSR_OF_FLD_FOLLOW_UP_KEY
                 AND SUPVFUP.PROVIDER_KEY != 1
                      LEFT JOIN dbo.D_PROVIDER SURV ON SURV.PROVIDER_KEY = PC.SURVEILLANCE_INVESTIGATOR_KEY
                 AND SURV.PROVIDER_KEY != 1
                      LEFT JOIN (SELECT IXC.INVESTIGATION_KEY, DV.IX_DATE
                                 FROM dbo.F_INTERVIEW_CASE IXC
                                          LEFT JOIN dbo.D_INTERVIEW DV ON DV.D_INTERVIEW_KEY = IXC.D_INTERVIEW_KEY
                                 WHERE DV.IX_TYPE_CD = 'INITIAL'
                                   AND DV.RECORD_STATUS_CD = 'ACTIVE') DIVW ON DIVW.INVESTIGATION_KEY = PC.INVESTIGATION_KEY
             WHERE
                 INV.RECORD_STATUS_CD = 'ACTIVE'
               AND PC.PATIENT_KEY != 1
               AND NOT EXISTS
                 (
                     SELECT 1 FROM DBO.STD_HIV_DATAMART shd
                     WHERE shd.INVESTIGATION_KEY = PC.INVESTIGATION_KEY

                 )
            );

        SELECT @RowCount_no = @@ROWCOUNT;
        --PRINT 'STD_HIV_DATAMART ENDING...'+ CONVERT(VARCHAR(20), GETDATE(),120)

        INSERT INTO [dbo].[job_flow_log] (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
        VALUES(@Batch_id,'STD_HIV_DATAMART','STD_HIV_DATAMART','START',@Proc_Step_no,@Proc_Step_name,@RowCount_no);

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
        SET @Proc_Step_Name = 'SP_COMPLETE';
        INSERT INTO [dbo].[job_flow_log]
        (batch_id,
         [Dataflow_Name],
         [package_Name],
         [Status_Type],
         [step_number],
         [step_name],
         [row_count]
        )
        VALUES
            (@batch_id,
             'STD_HIV_DATAMART',
             'STD_HIV_DATAMART',
             'COMPLETE',
             @Proc_Step_no,
             @Proc_Step_name,
             @RowCount_no
            );
        COMMIT TRANSACTION;


    END TRY


    BEGIN CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
        VALUES( @Batch_id, 'STD_HIV_DATAMART', 'STD_HIV_DATAMART', 'ERROR', @Proc_Step_no, 'ERROR - '+@Proc_Step_name, 'Step -'+CAST(@Proc_Step_no AS varchar(3))+' -'+CAST(@ErrorMessage AS varchar(500)), 0 );
        RETURN -1;

    END CATCH;
END;
