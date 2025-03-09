


CREATE OR alter PROCEDURE [dbo].sp_dyn_dm_provider_data_post_processing
 
            @batch_id BIGINT,
			@DATAMART_NAME VARCHAR(100), @prv_id_list nvarchar(max)
	AS
BEGIN  
	 BEGIN TRY
	


--DECLARE  @batch_id BIGINT = 999;  DECLARE @DATAMART_NAME  VARCHAR(100) = 'CONG_SYPHILIS';

		

		
		DECLARE @RowCount_no INT = 0 ;
		DECLARE @Proc_Step_no FLOAT = 0 ;
		DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
		DECLARE @batch_start_time datetime = null ;
		DECLARE @batch_end_time datetime = null ;
		DECLARE @nbs_page_form_cd varchar(200)=''


			SET @Proc_Step_no = 1;
	SET @Proc_Step_Name = 'SP_Start';

	

	
	BEGIN TRANSACTION;
	
 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );
  
		
	
    COMMIT TRANSACTION;
	
	
    BEGIN TRANSACTION;
	
	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  FACT_CASE';
		
			


--DECLARE  @batch_id BIGINT = 999;  DECLARE @DATAMART_NAME  VARCHAR(100) = 'CONG_SYPHILIS';
		


      declare @countstd int = 0;


	   select  @COUNTSTD = count(*) 
	    from dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata
        ;


		  declare @FACT_CASE varchar(40) = '';


		  if @countstd > 1
			 begin
			  set @FACT_CASE = 'F_STD_PAGE_CASE';
			end
		  else 
			 begin
			  set @FACT_CASE = 'F_PAGE_CASE';
			 end
		  ;

  
SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

  	
 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );
  
		
	
    COMMIT TRANSACTION;
	
	
    BEGIN TRANSACTION;
	
	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_Provider_Metadata';
		
			
--CREATE TABLE PROVIDER_METADATA  AS 

     IF OBJECT_ID('#tmp_DynDm_Provider_Metadata', 'U') IS NOT NULL   
 			drop table #tmp_DynDm_Provider_Metadata;


/*
SELECT DISTINCT RDB_COLUMN_NM, user_defined_column_nm, part_type_cd ,
cast( null as varchar(2000)) as [Key],
cast( null as varchar(2000)) as Detail,
cast( null as varchar(2000)) as QEC,
cast( null as varchar(2000)) as [UID]
into #tmp_DynDm_Provider_Metadata
FROM NBS_ODSE..NBS_RDB_METADATA 
INNER JOIN NBS_ODSE..NBS_UI_METADATA ON NBS_RDB_METADATA.NBS_UI_METADATA_UID =NBS_UI_METADATA.NBS_UI_METADATA_UID
WHERE INVESTIGATION_FORM_CD  =  @nbs_page_form_cd
AND NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM <> '' 
and NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM IS NOT NULL
AND PART_TYPE_CD IS NOT NULL 
AND RDB_TABLE_NM ='D_PROVIDER' 
AND DATA_TYPE='PART'
;
*/
     
select DISTINCT RDB_COLUMN_NM, user_defined_column_nm, part_type_cd ,
 [Key],Detail, QEC, [UID] 
 into #tmp_DynDm_Provider_Metadata
from dbo.v_nrt_d_provider_rdb_table_metadata  WHERE INVESTIGATION_FORM_CD  =  @nbs_page_form_cd

  
SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

	
 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );
  
		
	
    COMMIT TRANSACTION;
	
	
    BEGIN TRANSACTION;
	
	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_PROVIDER';
		
			
 IF OBJECT_ID('#tmp_DynDm_PROVIDER', 'U') IS NOT NULL   
 				drop table #tmp_DynDm_PROVIDER;


select distinct investigation_key,
cast( null as  [varchar](50)) [PROVIDER_LOCAL_ID],
cast( null as  bigint) [PROVIDER_UID]

into #tmp_DynDm_PROVIDER
 FROM #tmp_DynDm_SUMM_DATAMART
 -- pass the prv_Id_List  param
;


	
  
SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );
  
		
	
    COMMIT TRANSACTION;
	
	
/*    BEGIN TRANSACTION; -- move it to provider metadata view
	
	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  UPDATE tmp_DynDm_Provider_Metadata';
		
			

update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='SUPRVSR_OF_CASE_ASSGNMENT_KEY'	 where  part_type_cd= 'CASupervisorOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='CLOSED_BY_KEY'	 where  part_type_cd= 'ClosureInvestgrOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='DISPOSITIONED_BY_KEY'	 where  part_type_cd= 'DispoFldFupInvestgrOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='INVSTGTR_FLD_FOLLOW_UP_KEY'	 where  part_type_cd= 'FldFupInvestgrOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='PROVIDER_FLD_FOLLOW_UP_KEY'	 where  part_type_cd= 'FldFupProvOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='SUPRVSR_OF_FLD_FOLLOW_UP_KEY'	 where  part_type_cd= 'FldFupSupervisorOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='INIT_ASGNED_FLD_FOLLOW_UP_KEY'	 where  part_type_cd= 'InitFldFupInvestgrOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='INIT_FOLLOW_UP_INVSTGTR_KEY'	 where  part_type_cd= 'InitFupInvestgrOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='INIT_ASGNED_INTERVIEWER_KEY'	 where  part_type_cd= 'InitInterviewerOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='INTERVIEWER_ASSIGNED_KEY'	 where  part_type_cd= 'InterviewerOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='INVESTIGATOR_KEY'	 where  part_type_cd= 'InvestgrOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='DELIVERING_MD_KEY'	 where  part_type_cd= 'PerAsProviderOfDelivery' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='MOTHER_OB_GYN_KEY'	 where  part_type_cd= 'PerAsProviderOfOBGYN' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='PEDIATRICIAN_KEY'	 where  part_type_cd= 'PerAsProvideroOfPediatrics' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='PERSON_AS_REPORTER_KEY'	 where  part_type_cd= 'PerAsReporterOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='PHYSICIAN_KEY'	 where  part_type_cd= 'PhysicianOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='SURVEILLANCE_INVESTIGATOR_KEY'	 where  part_type_cd= 'SurvInvestgrOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='FACILITY_FLD_FOLLOW_UP_KEY'	 where  part_type_cd= 'FldFupFacilityOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='HOSPITAL_KEY'	 where  part_type_cd= 'HospOfADT' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='ORDERING_FACILITY_KEY'	 where  part_type_cd= 'OrgAsClinicOfPHC' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='DELIVERING_HOSP_KEY'	 where  part_type_cd= 'OrgAsHospitalOfDelivery' ;
update #tmp_DynDm_Provider_Metadata  SET PART_TYPE_CD='ORG_AS_REPORTER_KEY'	 where  part_type_cd= 'OrgAsReporterOfPHC' ;


	
  
SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );
  
		
	
    COMMIT TRANSACTION;
	
	*/
    
    /* -- move it to view provider metadata
    BEGIN TRANSACTION;
	
	SET @Proc_Step_no = @Proc_Step_no + 1;
	SET @Proc_Step_Name = 'GENERATING  UPDATE 2 tmp_DynDm_Provider_Metadata';
		
			

update #tmp_DynDm_Provider_Metadata
set 
 [KEY] = substring(USER_DEFINED_COLUMN_NM,1,CHARINDEX('_UID',USER_DEFINED_COLUMN_NM))+'KEY' ,
 DETAIL = substring(USER_DEFINED_COLUMN_NM,1,CHARINDEX('_UID',USER_DEFINED_COLUMN_NM))+'DETAIL' ,
 QEC = substring(USER_DEFINED_COLUMN_NM,1,CHARINDEX('_UID',USER_DEFINED_COLUMN_NM))+'QEC' ,
 [UID] = USER_DEFINED_COLUMN_NM 
 ;



-- select * from  #tmp_DynDm_Provider_Metadata;

	
  
SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );
  
		
	
    COMMIT TRANSACTION;
	
		*/
			

  declare  @USER_DEFINED_COLUMN_NM varchar(max) ,@PART_TYPE_CD  varchar(max) ,@DETAIL  varchar(max) ,@QEC  varchar(max) ,@UID varchar(max);

 

 declare @SQL varchar(max)


--declare @PART_TYPE_CD varchar(max) = null , @SQL varchar(max);


DECLARE db_cursor_org CURSOR  LOCAL FOR 
 select PART_TYPE_CD , [key],DETAIL,QEC ,[UID] from #tmp_DynDm_Provider_Metadata;

OPEN db_cursor_org  
FETCH NEXT FROM db_cursor_org INTO @PART_TYPE_CD ,@USER_DEFINED_COLUMN_NM,@DETAIL ,@QEC ,@UID

WHILE @@FETCH_STATUS = 0  
BEGIN  

    
	
				BEGIN TRANSACTION;
	
				SET @Proc_Step_no = @Proc_Step_no + 1;
				SET @Proc_Step_Name = 'GENERATING  tmp_DynDm_ProvPart_Table_temp';
		

     IF OBJECT_ID('dbo.tmp_DynDm_ProvPart_Table_temp', 'U') IS NOT NULL   
 				drop table dbo.tmp_DynDm_ProvPart_Table_temp;

      
			CREATE TABLE dbo.tmp_DynDm_ProvPart_Table_temp(
				[PROVIDER_KEY] [bigint] NULL,
				[PROVIDER_QUICK_CODE] [varchar](50) NULL,
				[PROVIDER_LOCAL_ID] [varchar](50) NULL,
				[PROVIDER_UID] [bigint] NULL,
				[PROVIDER_FIRST_NAME] [varchar](50) NULL,
				[PROVIDER_MIDDLE_NAME] [varchar](50) NULL,
				[PROVIDER_LAST_NAME] [varchar](50) NULL,
				[PROVIDER_NAME_SUFFIX] [varchar](50) NULL,
				[PROVIDER_NAME_DEGREE] [varchar](50) NULL,
				[PROVIDER_STREET_ADDRESS_1] [varchar](50) NULL,
				[PROVIDER_STREET_ADDRESS_2] [varchar](50) NULL,
				[PROVIDER_CITY] [varchar](50) NULL,
				[PROVIDER_STATE] [varchar](50) NULL,
				[PROVIDER_ZIP] [varchar](50) NULL,
				[PROVIDER_COUNTY] [varchar](50) NULL,
				[PROVIDER_PHONE_WORK] [varchar](50) NULL,
				[PROVIDER_PHONE_EXT_WORK] [varchar](50) NULL,
				[PROVIDER_EMAIL_WORK] [varchar](50) NULL,
				[PART_TYPE_CD] [bigint] NULL,
				[PART_TYPE_CD_NM] [varchar](200) NOT NULL,
				[CITY_STATE_ZIP] [varchar](4000) NULL,
				[PROVIDER_NAME] [varchar](5000) NULL,
                [DETAIL] varchar(2000),
				[INVESTIGATION_KEY] [bigint] NOT NULL
			);


	 	SET @SQL = 	'  insert into  [dbo].tmp_DynDm_ProvPart_Table_temp SELECT  d_p.PROVIDER_KEY, ' +
		' d_p.PROVIDER_QUICK_CODE, ' +
		' d_p.PROVIDER_LOCAL_ID, ' +
		' d_p.PROVIDER_UID, ' +
		' d_p.PROVIDER_FIRST_NAME, ' +
		' d_p.PROVIDER_MIDDLE_NAME, ' + 
		' d_p.PROVIDER_LAST_NAME, ' +
		' d_p.PROVIDER_NAME_SUFFIX, ' + 
		' d_p.PROVIDER_NAME_DEGREE, ' +
		' d_p.PROVIDER_STREET_ADDRESS_1, ' +
		' d_p.PROVIDER_STREET_ADDRESS_2, ' +
		' d_p.PROVIDER_CITY, ' +' d_p.PROVIDER_STATE, ' + ' d_p.PROVIDER_ZIP, ' +
		' d_p.PROVIDER_COUNTY, ' +
		' d_p.PROVIDER_PHONE_WORK, ' +
		' d_p.PROVIDER_PHONE_EXT_WORK, ' +
		'  PROVIDER_EMAIL_WORK, ' +
		 @PART_TYPE_CD +', ' +
		''''+   @PART_TYPE_CD +''', '+
		'   coalesce( ltrim(rtrim(PROVIDER_CITY))+'', '','''')+coalesce( ltrim(rtrim(PROVIDER_STATE))+'' '','''')+coalesce( ltrim(rtrim(PROVIDER_ZIP)),'''') '  + ','+
		' null ,'+
		' null ,'+
        '    s_d.INVESTIGATION_KEY AS INVESTIGATION_KEY ' +
		' FROM #tmp_DynDm_SUMM_DATAMART s_d '+
		' INNER JOIN dbo.'+@FACT_CASE+ '   ON s_d.INVESTIGATION_KEY =  '+@FACT_CASE+ '.INVESTIGATION_KEY '+
		' LEFT JOIN dbo.D_PROVIDER  d_p ON '+@FACT_CASE+'.'+@PART_TYPE_CD+' = d_p.PROVIDER_KEY  '+
		' where d_p.PROVIDER_UID  IN (SELECT value FROM STRING_SPLIT(' + @prv_id_list +','+ ','+'))' +
		 '; '

      --  select 'INSERT',@PART_TYPE_CD,@DETAIL , @SQL;


			EXEC(@SQL);


			
  
SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			
  	
			 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
			 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name  +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );
  
		
	
				COMMIT TRANSACTION;
	
	
				BEGIN TRANSACTION;
	
				SET @Proc_Step_no = @Proc_Step_no + 1;
				SET @Proc_Step_Name = 'GENERATING  UPDATE tmp_DynDm_ProvPart_Table_temp';
		


			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(coalesce(PROVIDER_FIRST_NAME,'')) ) 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(PROVIDER_NAME))  + ' ' +  LTRIM(RTRIM(PROVIDER_MIDDLE_NAME))  WHERE   LEN(LTRIM(RTRIM(PROVIDER_MIDDLE_NAME )))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(PROVIDER_NAME))  + ' ' +  LTRIM(RTRIM(PROVIDER_LAST_NAME))  WHERE   LEN(LTRIM(RTRIM(PROVIDER_LAST_NAME )))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(PROVIDER_NAME))  + ', ' +  LTRIM(RTRIM(PROVIDER_NAME_SUFFIX))  WHERE LEN(LTRIM(RTRIM(PROVIDER_NAME_SUFFIX )))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = LTRIM(  RTRIM(PROVIDER_NAME))  + ', ' +  LTRIM(RTRIM(PROVIDER_NAME_DEGREE))  WHERE    LEN(LTRIM(RTRIM(PROVIDER_NAME_DEGREE )))>0  	 ;
		     
			  UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   PROVIDER_NAME = null where LTRIM(  RTRIM(PROVIDER_NAME)) = '';

		
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL  ='<b></b>'  + RTRIM(PROVIDER_LOCAL_ID)  WHERE   LEN(LTRIM(RTRIM(PROVIDER_LOCAL_ID)))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL))  + '<br>'  +  PROVIDER_NAME	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_NAME)))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL = LTRIM(RTRIM(DETAIL))  + '<br>'  +  LTRIM(RTRIM(PROVIDER_STREET_ADDRESS_1))  WHERE   LEN(LTRIM(RTRIM(PROVIDER_STREET_ADDRESS_1)))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL = LTRIM(RTRIM(DETAIL))  +  '<br>'  +  LTRIM(RTRIM(PROVIDER_STREET_ADDRESS_2)) 	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_STREET_ADDRESS_2)))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br>'  +  LTRIM(  RTRIM(CITY_STATE_ZIP)) 	 WHERE  LEN(LTRIM(RTRIM(CITY_STATE_ZIP)))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br>'  +  LTRIM(RTRIM(PROVIDER_COUNTY)) WHERE  LEN(LTRIM(RTRIM(PROVIDER_COUNTY)))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br>'  +  LTRIM(  RTRIM(PROVIDER_PHONE_WORK)) 	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_PHONE_WORK)))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  ', ext. '  +  LTRIM(  RTRIM(PROVIDER_PHONE_EXT_WORK)) 	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_PHONE_WORK)))>0 and LEN(LTRIM(RTRIM(PROVIDER_PHONE_EXT_WORK)))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br> ext. '  +  LTRIM(  RTRIM(PROVIDER_PHONE_EXT_WORK)) 	 WHERE  LEN(LTRIM(RTRIM(PROVIDER_PHONE_WORK)))=0 and LEN(LTRIM(RTRIM(PROVIDER_PHONE_EXT_WORK)))>0 	 ;
			 UPDATE dbo.tmp_DynDm_ProvPart_Table_temp SET   DETAIL =LTRIM(RTRIM(DETAIL)) +  '<br>' 	 WHERE  LEN(LTRIM(RTRIM(DETAIL )))>0 	 ;


			              
  
 SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			
  	
			 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
			 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name  +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );
  
		
	
				COMMIT TRANSACTION;
	
	
				BEGIN TRANSACTION;
	
				SET @Proc_Step_no = @Proc_Step_no + 1;
				SET @Proc_Step_Name = 'GENERATING  ALTER tmp_DynDm_ProvPart_Table_temp';
		

		--	 select 'tmp_DynDm_ProvPart_Table_temp', * from dbo.tmp_DynDm_ProvPart_Table_temp;


			 SET @SQL =  'alter table dbo.tmp_DynDm_ProvPart_Table_temp add  ' +  @DETAIL  + ' [varchar](2000) , ' +  @USER_DEFINED_COLUMN_NM+ ' bigint , '  +  @QEC+ ' [varchar](50) , ' +  @UID+ ' bigint ; '

     	  --  select 'ALTER', @PART_TYPE_CD, @SQL;


			EXEC(@SQL);


			
			SET @SQL =  'alter table #tmp_DynDm_PROVIDER add   ' +  @DETAIL  + ' [varchar](2000) , ' +  @USER_DEFINED_COLUMN_NM+ ' bigint , '  +  @QEC+ ' [varchar](50) , ' +  @UID+ ' bigint ; '

  	   
			EXEC(@SQL);



			
  
               SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			
  	
			 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
			 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name  +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );
  
		
	
				COMMIT TRANSACTION;
	
	
				BEGIN TRANSACTION;
	
				SET @Proc_Step_no = @Proc_Step_no + 1;
				SET @Proc_Step_Name = 'GENERATING  UPDATE tmp_DynDm_PROVIDER';
		



		--@USER_DEFINED_COLUMN_NM=ORGANIZATION_KEY;
		--@QEC =ORGANIZATION_QUICK_CODE;
		--@UID= ORGANIZATION_UID;

			SET @SQL =  'update tDO SET '
			          +  ' PROVIDER_LOCAL_ID = orgtemp.PROVIDER_LOCAL_ID ,'
			         +  ' PROVIDER_UID = orgtemp.PROVIDER_UID ,'
			          +  @DETAIL  + ' = DETAIL , ' 
			          +  @USER_DEFINED_COLUMN_NM+ ' =  PROVIDER_KEY , '  
					  +  @QEC+ ' = PROVIDER_QUICK_CODE , ' 
					  +  @UID+ ' = orgtemp.PROVIDER_UID '
					  +  ' FROM #tmp_DynDm_PROVIDER  tDO '
                      +  ' INNER JOIN dbo.tmp_DynDm_ProvPart_Table_temp orgtemp  ON  tDO.investigation_key = orgtemp.investigation_key '
					  + ' ; '

  	    --select 'UPDATE', @PART_TYPE_CD, @SQL;


		--select 'tmp_DynDm_PROVIDER', * from #tmp_DynDm_PROVIDER;

			EXEC(@SQL);

			
			
               SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

  	
			 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
			 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name  +'-'+ @PART_TYPE_CD  , @ROWCOUNT_NO );
  
		
	
				COMMIT TRANSACTION;
	
	


      FETCH NEXT FROM db_cursor_org INTO @PART_TYPE_CD ,@USER_DEFINED_COLUMN_NM,@DETAIL ,@QEC ,@UID

END 

CLOSE db_cursor_org  
DEALLOCATE db_cursor_org
;







/*
DATA PROVPART_TABLE;
SET PROVPART_TABLE;
	LENGTH CITY_STATE_ZIP $2000;
	LENGTH DETAIL   $2000;
	LENGTH PROVIDER_NAME  $2000;
	 
	 
	IF   PROVIDER_KEY =1 THEN PROVIDER_KEY=.;
	@USER_DEFINED_COLUMN_NM=PROVIDER_KEY;
	@QEC =PROVIDER_QUICK_CODE;
	@UID=PROVIDER_UID; 
	IF LENGTHN(TRIM(PROVIDER_CITY))>0 THEN CITY_STATE_ZIP =PROPCASE(TRIM(PROVIDER_CITY));
	IF LENGTHN(TRIM(PROVIDER_STATE))>0 THEN CITY_STATE_ZIP = LTRIM(  RTRIM(CITY_STATE_ZIP) || ', ' ||v PROPCASE(TRIM(PROVIDER_STATE)) ;
	IF LENGTHN(TRIM(PROVIDER_ZIP))>0 THEN CITY_STATE_ZIP = LTRIM(  RTRIM(CITY_STATE_ZIP) || ' ' || PROPZASE(TRIM(PROVIDER_ZIP)) ;
	
	PROVIDER_NAME=PROPCASE(TRIM(PROVIDER_FIRST_NAME));


	IF LENGTHN(TRIM(PROVIDER_NAME))>0 AND LENGTHN(TRIM(PROVIDER_MIDDLE_NAME ))>0 THEN PROVIDER_NAME =TRIM(PROVIDER_NAME) ||' '|| PROPCASE(TRIM(PROVIDER_MIDDLE_NAME));
	IF LENGTHN(TRIM(PROVIDER_NAME))=0 AND LENGTHN(TRIM(PROVIDER_MIDDLE_NAME ))>0 THEN PROVIDER_NAME =PROPCASE(TRIM(PROVIDER_MIDDLE_NAME));
	IF LENGTHN(TRIM(PROVIDER_NAME))>0 AND LENGTHN(TRIM(PROVIDER_LAST_NAME ))>0 THEN PROVIDER_NAME =TRIM(PROVIDER_NAME) ||' '|| PROPCASE(TRIM(PROVIDER_LAST_NAME));
	IF LENGTHN(TRIM(PROVIDER_NAME))=0 AND LENGTHN(TRIM(PROVIDER_LAST_NAME ))>0 THEN PROVIDER_NAME = PROPCASE(TRIM(PROVIDER_LAST_NAME));
	IF LENGTHN(TRIM(PROVIDER_NAME))>0 AND LENGTHN(TRIM(PROVIDER_NAME_SUFFIX ))>0 THEN PROVIDER_NAME =TRIM(PROVIDER_NAME) ||', '|| PROPCASE(TRIM(PROVIDER_NAME_SUFFIX));
	IF LENGTHN(TRIM(PROVIDER_NAME))=0 AND LENGTHN(TRIM(PROVIDER_NAME_SUFFIX ))>0 THEN PROVIDER_NAME = PROPCASE(TRIM(PROVIDER_NAME_SUFFIX));
	IF LENGTHN(TRIM(PROVIDER_NAME))>0 AND LENGTHN(TRIM(PROVIDER_NAME_DEGREE ))>0 THEN PROVIDER_NAME =TRIM(PROVIDER_NAME) ||', '|| LTRIM(  RTRIM(PROVIDER_NAME_DEGREE);
	IF LENGTHN(TRIM(PROVIDER_NAME))=0 AND LENGTHN(TRIM(PROVIDER_NAME_DEGREE ))>0  THEN PROVIDER_NAME = LTRIM(  RTRIM(PROVIDER_NAME_DEGREE);


	If LENGTHN(TRIM(PROVIDER_LOCAL_ID))>0 THEN DETAIL  ='<b></b>' ||TRIM(PROVIDER_LOCAL_ID);
	If LENGTHN(TRIM(PROVIDER_NAME))>0 THEN DETAIL  =TRIM(DETAIL ) ||'<br>' || PROVIDER_NAME;
	IF LENGTHN(TRIM(PROVIDER_STREET_ADDRESS_1))>0 THEN DETAIL =  LTRIM(  RTRIM(DETAIL ) ||'<br>' ||PROPCASE(TRIM(PROVIDER_STREET_ADDRESS_1));
	IF LENGTHN(TRIM(PROVIDER_STREET_ADDRESS_2))>0 THEN DETAIL =  LTRIM(  RTRIM(DETAIL ) || '<br>' || PROPCASE(TRIM(PROVIDER_STREET_ADDRESS_2)) ;
	IF LENGTHN(TRIM(CITY_STATE_ZIP))>0 THEN DETAIL = LTRIM(  RTRIM(DETAIL )|| '<br>' || LTRIM(  RTRIM(CITY_STATE_ZIP) ;
	IF LENGTHN(TRIM(PROVIDER_COUNTY))>0 THEN DETAIL = LTRIM(  RTRIM(DETAIL )|| '<br>' || PROPCASE(TRIM(PROVIDER_COUNTY)) ;
	IF LENGTHN(TRIM(PROVIDER_PHONE_WORK))>0 THEN DETAIL = LTRIM(  RTRIM(DETAIL )|| '<br>' || LTRIM(  RTRIM(PROVIDER_PHONE_WORK) ;
	IF LENGTHN(TRIM(PROVIDER_PHONE_WORK))>0 and LENGTHN(TRIM(PROVIDER_PHONE_EXT_WORK))>0 THEN DETAIL = LTRIM(  RTRIM(DETAIL )|| ', ext. ' || LTRIM(  RTRIM(PROVIDER_PHONE_EXT_WORK) ;
	IF LENGTHN(TRIM(PROVIDER_PHONE_WORK))=0 and LENGTHN(TRIM(PROVIDER_PHONE_EXT_WORK))>0 THEN DETAIL = LTRIM(  RTRIM(DETAIL )|| '<br> ext. ' || LTRIM(  RTRIM(PROVIDER_PHONE_EXT_WORK) ;
	IF LENGTHN(TRIM(DETAIL ))>0 then DETAIL = LTRIM(  RTRIM(DETAIL )|| '<br>'; 


	DROP PROVIDER_NAME PROVIDER_FIRST_NAME PROVIDER_MIDDLE_NAME PROVIDER_LAST_NAME PROVIDER_NAME_SUFFIX PROVIDER_NAME_DEGREE PROVIDER_EMAIL_WORK 
	 PROVIDER_STREET_ADDRESS_1 PROVIDER_STREET_ADDRESS_2 PROVIDER_COUNTY PROVIDER_PHONE_WORK PROVIDER_KEY 
	PROVIDER_PHONE_EXT_WORK CITY_STATE_ZIP PROVIDER_CITY PROVIDER_ZIP PROVIDER_STATE PROVIDER_QUICK_CODE @PART_TYPE_CD;

RUN; 

 PROC SORT DATA=PROVPART_TABLE NODUPKEY; BY INVESTIGATION_KEY;RUN;

DATA PROVIDER;
MERGE PROVPART_TABLE PROVIDER;
BY INVESTIGATION_KEY;
RUN;

--%MEND POPULATE_PROVIDER;

*/

/*
	ALTER TABLE  dbo.tmp_DynDm_ProvPart_Table_temp
	DROP COLUMN   PROVIDER_NAME , PROVIDER_FIRST_NAME , PROVIDER_MIDDLE_NAME , PROVIDER_LAST_NAME , PROVIDER_NAME_SUFFIX , PROVIDER_NAME_DEGREE , PROVIDER_EMAIL_WORK , 
	 PROVIDER_STREET_ADDRESS_1 , PROVIDER_STREET_ADDRESS_2 , PROVIDER_COUNTY , PROVIDER_PHONE_WORK , PROVIDER_KEY , 
	PROVIDER_PHONE_EXT_WORK , CITY_STATE_ZIP , PROVIDER_CITY , PROVIDER_ZIP , PROVIDER_STATE , PROVIDER_QUICK_CODE  ;

	
   alter table dbo.tmp_DynDm_ProvPart_Table_temp drop column  PART_TYPE_CD , PART_TYPE_CD_NM ;
   */

   --IF OBJECT_ID('#tmp_DynDm_PROVPART_table', 'U') IS NOT NULL   
 		--		drop table #tmp_DynDm_PROVPART_table;



--select distinct  * 
--into #tmp_DynDm_PROVPART_table
--from  dbo.tmp_DynDm_ProvPart_Table_temp;


--select RPT_PRV_DETAIL,* from #tmp_DynDm_PROVIDER  where lower(RPT_PRV_DETAIL) like lower('%middle%middle%');



			
  	
	
	
				BEGIN TRANSACTION;
	
				SET @Proc_Step_no = @Proc_Step_no + 1;
				SET @Proc_Step_Name = 'SP COMPLETE';
		


		
               SELECT @ROWCOUNT_NO = @@ROWCOUNT; 

			
  	
			 INSERT INTO [dbo].[job_flow_log] ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] ) 
			 VALUES ( @batch_id ,'DYNAMIC_DATAMART' ,'dbo.DynDm_ProvData_sp '+@DATAMART_NAME  ,'START' ,@Proc_Step_no , @Proc_Step_Name , @ROWCOUNT_NO );
  
		
	

          COMMIT TRANSACTION;


    END TRY
            BEGIN CATCH
						IF @@TRANCOUNT > 0
						BEGIN
							ROLLBACK TRANSACTION;
						END;
						DECLARE @ErrorNumber int= ERROR_NUMBER();
						DECLARE @ErrorLine int= ERROR_LINE();
						DECLARE @ErrorMessage nvarchar(4000)= ERROR_MESSAGE();
						DECLARE @ErrorSeverity int= ERROR_SEVERITY();
						DECLARE @ErrorState int= ERROR_STATE();

                        select @ErrorMessage;

						INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
						VALUES( @Batch_id, 'DYNAMIC_DATAMART', 'dbo.DynDm_ProvData_sp', 'ERROR', @Proc_Step_no, 'ERROR - '+@Proc_Step_name, 'Step -'+CAST(@Proc_Step_no AS varchar(3))+' -'+CAST(@ErrorMessage AS varchar(500)), 0 );
						RETURN -1;
	        END CATCH;
END;

