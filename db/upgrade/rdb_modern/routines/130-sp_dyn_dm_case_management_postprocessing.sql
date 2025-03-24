CREATE OR ALTER PROCEDURE [dbo].sp_dyn_dm_case_management_postprocessing
            @batch_id BIGINT,
			@DATAMART_NAME VARCHAR(100),
			@phc_id_list nvarchar(max)
	AS
BEGIN
	 BEGIN TRY

	    --	DECLARE  @batch_id BIGINT = 999;  DECLARE  @DATAMART_NAME VARCHAR(100) = 'TB_LTBI_GA';
		DECLARE @RowCount_no INT ;
		DECLARE @Proc_Step_no FLOAT = 0 ;
		DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
		DECLARE @batch_start_time datetime = null ;
		DECLARE @batch_end_time datetime = null ;
		DECLARE @nbs_page_form_cd varchar(200)=''



	SET @Proc_Step_no = 1;
	SET @Proc_Step_Name = 'SP_Start';




	BEGIN TRANSACTION;

    INSERT INTO dbo.[job_flow_log] (
	        batch_id
		   ,[Dataflow_Name]
		   ,[package_Name]
		    ,[Status_Type]
           ,[step_number]
           ,[step_name]
           ,[row_count]
           )
		   VALUES
           (
		   @batch_id
           ,'DYNAMIC_DATAMART'
           ,'DBO.DynDM_Manage_Case_Management ' + @DATAMART_NAME
		   ,'START'
		   ,@Proc_Step_no
		   ,@Proc_Step_Name
           ,0
		   );


    COMMIT TRANSACTION;


    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  LIST STRING';

	SET @nbs_page_form_cd = (SELECT FORM_CD FROM dbo.v_nrt_nbs_page WHERE DATAMART_NM=@DATAMART_NAME)



/*Creating the list in the rdb_column_name_list with all the user defined column name*/

--DECLARE @DATAMART_NAME varchar(100) = 'CONG_SYPHILIS';

--DX select * from dbo.tmp_DynDm_Case_Management_Metadata;



 DECLARE @listStr VARCHAR(MAX) = null;
/*
SELECT @listStr = COALESCE(@listStr+',' ,'') +  RDB_COLUMN_NM  + ' '+ coalesce(USER_DEFINED_COLUMN_NM,'')
FROM  dbo.tmp_DynDm_Case_Management_Metadata with (nolock);
*/
SELECT rdb_column_nm_list FROM  dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata where datamart_nm = @DATAMART_NAME;



--DX SELECT @listStr



/*it creates the case_management_data table with the rdb_column_nm associated to the case management plus the investigation key*/

	-- CREATE TABLE CASE_MANAGEMENT_DATA AS

				SELECT @ROWCOUNT_NO = @@ROWCOUNT;

 INSERT INTO dbo.[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'DBO.DynDM_Manage_Case_Management '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );



    COMMIT TRANSACTION;


    BEGIN TRANSACTION;

	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_Case_Management_Data';




  IF OBJECT_ID('#tmp_DynDm_Case_Management_Data', 'U') IS NOT NULL
 				drop table #tmp_DynDm_Case_Management_Data;


	SELECT  isd.INVESTIGATION_KEY ,rdb_column_nm_list
		INTO #tmp_DynDM_CASE_MANAGEMENT_DATA
		FROM dbo.tmp_DynDM_SUMM_DATAMART isd
		join dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata case_mgmt_meta on  case_mgmt_meta.INVESTIGATION_FORM_CD = isd.DISEASE_GRP_CD
			and case_mgmt_meta.datamart_nm = @DATAMART_NAME and isd.DISEASE_GRP_CD = @nbs_page_form_cd
			and case_mgmt_meta.INVESTIGATION_FORM_CD = @nbs_page_form_cd
		INNER JOIN dbo.nrt_investigation_key nrt_inv_key with (nolock) ON isd.investigation_key = nrt_inv_key.d_investigation_key
		and nrt_inv_key.case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','))
		LEFT JOIN  dbo.D_CASE_MANAGEMENT case_mgmt ON isd.INVESTIGATION_KEY = case_mgmt.INVESTIGATION_KEY
		 WHERE  case_mgmt.INVESTIGATION_KEY>1 ;


		SELECT @ROWCOUNT_NO = @@ROWCOUNT;

 INSERT INTO dbo.[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'DBO.DynDM_Manage_Case_Management '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );



	COMMIT TRANSACTION;


					BEGIN TRANSACTION;

					SET @Proc_Step_no = @Proc_Step_no + 1;
					SET @Proc_Step_Name = 'SP_COMPLETE';


					INSERT INTO dbo.[job_flow_log] (
							batch_id
							,[Dataflow_Name]
						   ,[package_Name]
							,[Status_Type]
						   ,[step_number]
						   ,[step_name]
						   ,[row_count]
						   )
						   VALUES
						   (
						   @batch_id,
						   'DYNAMIC_DATAMART'
						   ,'DBO.DynDM_Manage_Case_Management '+@DATAMART_NAME
						   ,'COMPLETE'
						   ,@Proc_Step_no
						   ,@Proc_Step_name
						   ,0
						   );


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
           ,'DYNAMIC_DATAMART'
           ,'DBO.DynDM_Manage_Case_Management'
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