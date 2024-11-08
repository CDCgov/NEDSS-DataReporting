CREATE or ALTER PROCEDURE [dbo].[sp_nrt_case_count_postprocessing] @phc_id_list nvarchar(max)
AS
BEGIN
BEGIN TRY

   declare @rowcount_no bigint;
   declare @proc_step_no float = 0;
   declare @proc_step_name varchar(200) = '';
   declare @batch_id bigint;
   declare @create_dttm datetime2(7) = current_timestamp;
   declare @update_dttm datetime2(7) = current_timestamp;
   declare @dataflow_name varchar(200) = 'Case Count POST-Processing';
   declare @package_name varchar(200) = 'sp_nrt_case_count_postprocessing';

   SET @batch_id = cast((format(getdate(),'yyMMddHHmmss')) as bigint);

INSERT INTO [dbo].[job_flow_log]
(batch_id
    ,[create_dttm]
    ,[update_dttm]
    ,[Dataflow_Name]
    ,[package_Name]
    ,[Status_Type]
    ,[step_number]
    ,[step_name]
    ,[msg_description1]
    ,[row_count])
VALUES (@batch_id
        ,@create_dttm
        ,@update_dttm
        ,@dataflow_name
        ,@package_name
        ,'START'
        ,0
        ,'SP_Start'
        ,LEFT(@phc_id_list, 500)
        ,0);


SET @proc_step_no = 1;
   	SET @proc_step_name = ' Create Key Associations table';

BEGIN TRANSACTION;

  	--TODO: remove unused columns
	--TODO: add nolock
select
    distinct cc.public_health_case_uid,
             i.investigation_key,
             con.condition_key,
             cc.patient_id,
             coalesce(dpat.patient_key, 1) as patient_key,
             cc.investigator_id,
             coalesce(dpro1.provider_key, 1) as Investigator_key,
             cc.physician_id,
             coalesce(dpro2.provider_key, 1) as Physician_key,
             cc.person_as_reporter_uid,
             coalesce(dpro3.provider_key, 1) as Reporter_key,
             cc.organization_id,
             coalesce(dorg1.organization_key, 1)			as Rpt_Src_Org_key,
             cc.hospital_uid,
             coalesce(dorg2.Organization_key, 1)			as ADT_HSPTL_KEY,
             cc.investigator_assigned_datetime,
             coalesce(rd1.Date_key, 1)			as Inv_Assigned_dt_key,
             cc.activity_from_time,
             coalesce(rd2.Date_key, 1)			as INV_START_DT_KEY,
             cc.diagnosis_time,
             coalesce(rd3.Date_key, 1)			as DIAGNOSIS_DT_KEY,
             cc.rpt_form_cmplt_time,
             coalesce(rd4.Date_key, 1)			as INV_RPT_DT_KEY,
             cc.case_type_cd,
             cc.investigation_count,
             cc.case_count,
             1 as geocoding_location_key
into #CASE_COUNT
from dbo.nrt_investigation cc
         inner join dbo.INVESTIGATION i on cc.public_health_case_uid = i.case_uid
         inner join dbo.CONDITION con on	con.condition_cd = cc.CD
         left outer join dbo.D_PATIENT dpat on cc.patient_id = dpat.patient_uid
         left outer join dbo.D_PROVIDER dpro1 on cc.investigator_id = dpro1.provider_uid
         left outer join dbo.D_PROVIDER dpro2 on cc.physician_id = dpro2.provider_uid
         left outer join dbo.D_PROVIDER dpro3 on cc.person_as_reporter_uid = dpro3.provider_uid
         left outer join dbo.D_ORGANIZATION dorg1 on cc.organization_id = dorg1.organization_uid
         left outer join dbo.D_ORGANIZATION dorg2 on cc.hospital_uid = dorg2.organization_uid
         left outer join dbo.RDB_DATE rd1 on cc.investigator_assigned_datetime = rd1.DATE_MM_DD_YYYY
         left outer join dbo.RDB_DATE rd2 on cc.activity_from_time = rd2.DATE_MM_DD_YYYY
         left outer join dbo.RDB_DATE rd3 on cc.diagnosis_time = rd3.DATE_MM_DD_YYYY
         left outer join dbo.RDB_DATE rd4 on cc.rpt_form_cmplt_time = rd4.DATE_MM_DD_YYYY
where cc.public_health_case_uid in (
    SELECT value FROM STRING_SPLIT(@phc_id_list, ',')
)
;
COMMIT TRANSACTION;

BEGIN TRANSACTION;

	SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
	SET @PROC_STEP_NAME = ' GENERATING Case Count Table - Update';


update dbo.CASE_COUNT
set
    case_count = src.case_count,
    investigator_key = src.investigator_key,
    reporter_key = src.reporter_key,
    physician_key = src.physician_key,
    rpt_src_org_key = src.rpt_src_org_key,
    inv_assigned_dt_key = src.inv_assigned_dt_key,
    patient_key = src.patient_key,
    investigation_count = src.investigation_count,
    condition_key = src.condition_key,
    adt_hsptl_key = src.adt_hsptl_key,
    inv_start_dt_key = src.inv_start_dt_key,
    diagnosis_dt_key = src.diagnosis_dt_key,
    inv_rpt_dt_key = src.inv_rpt_dt_key,
    geocoding_location_key = src.geocoding_location_key
    from
			dbo.CASE_COUNT tgt
		inner join #CASE_COUNT src
on src.investigation_key = tgt.investigation_key;

SELECT @ROWCOUNT_NO = @@ROWCOUNT;
INSERT INTO dbo.[JOB_FLOW_LOG]
(BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
VALUES(@BATCH_ID,'CASE_COUNT','CASE_COUNT','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);

SET @PROC_STEP_NO =  @PROC_STEP_NO + 1;
	    SET @PROC_STEP_NAME = ' GENERATING Case Count Table - Insert';

insert into dbo.[CASE_COUNT](
    case_count,
    investigator_key,
    reporter_key,
    physician_key,
    rpt_src_org_key,
    inv_assigned_dt_key,
    patient_key,
    investigation_key,
    investigation_count,
    condition_key,
    adt_hsptl_key,
    inv_start_dt_key,
    diagnosis_dt_key,
    inv_rpt_dt_key,
    geocoding_location_key
)
SELECT
    distinct
    src.case_count,
    src.investigator_key,
    src.reporter_key,
    src.physician_key,
    src.rpt_src_org_key,
    src.inv_assigned_dt_key,
    src.patient_key,
    src.investigation_key,
    src.investigation_count,
    src.condition_key,
    src.adt_hsptl_key,
    src.inv_start_dt_key,
    src.diagnosis_dt_key,
    src.inv_rpt_dt_key,
    src.geocoding_location_key
from
    #CASE_COUNT src
left outer join dbo.CASE_COUNT tgt
    on src.investigation_key = tgt.investigation_key
where tgt.investigation_key is null
;


COMMIT TRANSACTION;



INSERT INTO [rdb_modern].[dbo].[job_flow_log]
(   batch_id
    , [Dataflow_Name]
    , [package_Name]
    , [Status_Type]
    , [step_number]
    , [step_name]
    , [row_count]
    , [Msg_Description1])
VALUES (
    @batch_id
        , 'Investigation PRE-Processing Event'
        , 'NBS_ODSE.sp_investigation_event'
        , 'COMPLETE'
        , 0
        , LEFT ('Pre ID-' + @phc_id_list, 199)
        , 0
        , LEFT (@phc_id_list, 199)
    );


BEGIN TRANSACTION;

	SET @PROC_STEP_NO =  999 ;
	SET @Proc_Step_Name = 'SP_COMPLETE';

INSERT INTO dbo.[job_flow_log]
(batch_id,[Dataflow_Name],[package_Name],[Status_Type] ,[step_number],[step_name],[row_count])
VALUES
    (@batch_id,'Case Count','Case Count','COMPLETE',@Proc_Step_no,@Proc_Step_name,@RowCount_no);

COMMIT TRANSACTION;


END TRY

BEGIN CATCH

IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorLine INT = ERROR_LINE();
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();


INSERT INTO dbo.[job_flow_log] (
                                 batch_id
    ,[Dataflow_Name]
    ,[package_Name]
    ,[Status_Type]
    ,[step_number]
    ,[step_name]
    ,[Error_Description]
    ,[row_count]
)
VALUES
    (
    @batch_id
        ,'Case Count'
        ,'Case Count'
        ,'ERROR'
        ,@Proc_Step_no
        ,'ERROR - '+ @Proc_Step_name
        , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
        ,0
    );


return -1 ;

END CATCH

END
;