CREATE OR ALTER PROCEDURE dbo.sp_d_lab_test_postprocessing
    @obs_ids nvarchar(max),
    @debug bit = 'false'
as

BEGIN

    DECLARE @RowCount_no INT ;
    DECLARE @Proc_Step_no FLOAT = 0 ;
    DECLARE @Proc_Step_Name VARCHAR(200) = '' ;
    DECLARE @batch_start_time datetime2(7) = null ;
    DECLARE @batch_end_time datetime2(7) = null ;
    DECLARE @batch_id BIGINT;
    SET @batch_id = cast((format(getdate(),'yyyyMMddHHmmss')) as bigint);

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';

        BEGIN TRANSACTION;

        INSERT INTO dbo.job_flow_log (
                                           batch_id
            ,[Dataflow_Name]
            ,[package_Name]
            ,[Status_Type]
            ,[step_number]
            ,[step_name]
            ,[row_count]
            ,[Msg_Description1]
        )
        VALUES
            (
            @batch_id
                ,'D_LAB_TEST'
                ,'D_LAB_TEST'
                ,'START'
                ,@Proc_Step_no
                ,@Proc_Step_Name
                ,0
                ,LEFT('ID List-' + @obs_ids,500)
            );

        COMMIT TRANSACTION;

        select @batch_start_time = batch_start_dttm,@batch_end_time = batch_end_dttm
        from [dbo].[job_batch_log]
        where status_type = 'start' and type_code='MasterETL'
        ;



			BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = 'GENERATING #s_edx_document1 '; 


			  IF OBJECT_ID('#s_edx_document1', 'U') IS NOT NULL 
			         drop table  #s_edx_document1;

						select EDX_Document_uid, edx_act_uid, edx_add_time
						 into #s_edx_document1
						from (select EDX_Document_uid, edx_act_uid, edx_add_time ,ROW_NUMBER() OVER (PARTITION BY edx_act_uid ORDER BY edx_add_time DESC) rankno
						-- need to replace with dbo.nrt_observation_edx
						 from dbo.nrt_observation_edx edx
						 where  edx.edx_act_uid IN (SELECT value FROM STRING_SPLIT(@obs_ids, ','))
						 ) edx_lst
						 where edx_lst.rankno = 1
						 ;


						-- create table updated_participant as 


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TESTinit_a '; 



			 
			  IF OBJECT_ID('#LAB_TESTinit_a', 'U') IS NOT NULL 
			         drop table  #LAB_TESTinit_a;



						select	distinct
							obs.observation_uid			 	as LAB_TEST_uid_Test,
							cast(1 as bigint)			 	as parent_test_pntr,	
							obs.observation_uid			 	as LAB_TEST_pntr,
							obs.activity_to_time		 	as LAB_TEST_dt,
							obs.method_cd				 	as test_method_cd,
							cast(1 as bigint)			 	as root_ordered_test_pntr,
							obs.method_desc_txt			 	as test_method_cd_desc,
							obs.priority_cd			 	 	as priority_cd,
							obs.target_site_cd			 	as specimen_site,
							obs.target_site_desc_txt  	 	as SPECIMEN_SITE_desc, 
							obs.txt						 	as Clinical_information,
							obs.obs_domain_cd_st_1 		 	as LAB_TEST_Type,
							obs.cd					 	 	as LAB_TEST_cd, 	
							obs.cd_desc_txt			 	as LAB_TEST_cd_desc,
							obs.Cd_system_cd			 	as LAB_TEST_cd_sys_cd,
							obs.Cd_system_desc_txt		 	as LAB_TEST_cd_sys_nm,
							obs.Alt_cd					 	as Alt_LAB_TEST_cd,
							obs.Alt_cd_desc_txt			 	as Alt_LAB_TEST_cd_desc,
							obs.Alt_cd_system_cd		 	as Alt_LAB_TEST_cd_sys_cd,
							obs.Alt_cd_system_desc_txt 	 	as Alt_LAB_TEST_cd_sys_nm,
							obs.effective_from_time	 	 	as specimen_collection_dt,
							obs.local_id				 	as lab_rpt_local_id,
							obs.shared_ind				 	as lab_rpt_share_ind,
							obs.PROGRAM_JURISDICTION_OID 	as oid,	
							obs.record_status_cd         	as record_status_cd,	
							obs.record_status_cd         	as record_status_cd_for_result,
							obs.STATUS_CD	   		 	 	as lab_rpt_status,
							obs.ADD_TIME				 	as LAB_RPT_CREATED_DT,
							obs.ADD_USER_ID  		 	 	as LAB_RPT_CREATED_BY, 
							obs.rpt_to_state_time  		 	as LAB_RPT_RECEIVED_BY_PH_DT, 
							obs.LAST_CHG_TIME 			 	as LAB_RPT_LAST_UPDATE_DT, 
							obs.LAST_CHG_USER_ID		 	as LAB_RPT_LAST_UPDATE_BY, 
							obs.electronic_ind			 	as ELR_IND, 
							obs.jurisdiction_cd		     	as Jurisdiction_cd,
							 cast(null as [varchar](50)) 	as JURISDICTION_NM, -- VS put(obs.jurisdiction_cd, $JURCODE.)  as JURISDICTION_NM,	 
							obs.observation_uid			 	as Lab_Rpt_Uid,
							/*obs.PROG_AREA_CD,*/
							obs.activity_to_time   	 	 	as resulted_lab_report_date,			
							obs.activity_to_time   	 	 	as sus_lab_report_date,
							obs.report_observation_uid,
							obs.report_refr_uid,
							obs.report_sprt_uid,
							obs.followup_observation_uid,
							obs.accession_number,
							obs.morb_hosp_id,
							obs.transcriptionist_auth_type,
							obs.assistant_interpreter_auth_type,
							obs.morb_physician_id,
							obs.morb_reporter_id,
							obs.transcriptionist_val,
							obs.transcriptionist_first_nm,
							obs.transcriptionist_last_nm,
							obs.assistant_interpreter_val,
							obs.assistant_interpreter_first_nm,
							obs.assistant_interpreter_last_nm,
							obs.result_interpreter_id,
							obs.transcriptionist_id_assign_auth,
							obs.assistant_interpreter_id_assign_auth,
							obs.interpretation_cd,
							loinc_con.condition_cd 			as condition_cd,
							cvg.code_short_desc_txt			as LAB_TEST_status,
							obs.PROCESSING_DECISION_CD 
						into #LAB_TESTinit_a
						from dbo.nrt_observation obs 
							left join   nbs_srte..loinc_condition as loinc_con 	on obs.cd = loinc_con.loinc_cd
							left join 	nbs_srte..code_value_general  as cvg on obs.status_cd = cvg.code 	and cvg.code_set_nm = 'ACT_OBJ_ST'
							where obs.obs_domain_cd_st_1 in ('Order','Result','R_Order','R_Result', 'I_Order', 'I_Result', 'Order_rslt') 
								and (obs.CTRL_CD_DISPLAY_FORM = 'LabReport' or obs.CTRL_CD_DISPLAY_FORM = 'LabReportMorb' or obs.CTRL_CD_DISPLAY_FORM is null)
								and obs.observation_uid in (SELECT value FROM STRING_SPLIT(@obs_ids, ','))
						--order by obs.OBSERVATION_UID
						;

						update #LAB_TESTinit_a
						set jurisdiction_nm = (
						select code_short_desc_txt 
						from nbs_srte..jurisdiction_code where code= #LAB_TESTinit_a.Jurisdiction_cd and code_set_nm = 'S_JURDIC_C'
						)
						where Jurisdiction_cd is not null
						;

					if @debug = 'true' select @Proc_Step_Name as step, * from #LAB_TESTinit_a;

			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;


            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #s_edx_document '; 


			  IF OBJECT_ID('#s_edx_document', 'U') IS NOT NULL 
			         drop table  #s_edx_document;

						 select EDX_Document_uid,
							   edx_act_uid,
							   edx_add_time ,
							   CONVERT(varchar, edx_add_time, 101) as add_timeSt, --VS put(datepart(add_time),mmddyy10.) as add_timeSt
							   cast( null as varchar(500)) as document_link
						  into #s_edx_document
						  from #s_edx_document1
						  ;

						

						update #s_edx_document
						set document_link =('<a href="#" '+ replace(('onClick="window.open(''/nbs/viewELRDocument.do?method=viewELRDocument&documentUid=' 
						+ cast(EDX_Document_uid as varchar) + ' &dateReceivedHidden=' + add_timeSt +''' ,''DocumentViewer'',''width=900,height=800,left=0,top=0,
						menubar=no,titlebar=no,toolbar=no,scrollbars=yes,location=no'');">View Lab Document</a>'),' ',''));


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TESTinit '; 


			  IF OBJECT_ID('#LAB_TESTinit', 'U') IS NOT NULL 
			         drop table   #LAB_TESTinit;

						 select distinct a.*, b.document_link 
						 into #LAB_TESTinit
						from #LAB_TESTinit_a a 
						left outer join #s_edx_document b on a.LAB_TEST_uid_test=b.edx_act_uid;

			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST_mat_init '; 


			  IF OBJECT_ID('#LAB_TEST_mat_init', 'U') IS NOT NULL 
			         drop table  #LAB_TEST_mat_init;


						 select 
							mat.act_uid			 as LAB_TEST_uid_mat,
							mat.material_cd						 as specimen_src,
							mat.material_nm						 as specimen_nm,
							mat.material_details			 as Specimen_details,
							mat.material_collection_vol					 as Specimen_collection_vol,
							mat.material_collection_vol_unit				 as Specimen_collection_vol_unit,
							mat.material_desc				 as Specimen_desc,
							mat.risk_cd					 as Danger_cd,
							mat.risk_desc_txt			 as Danger_cd_desc
						  into #LAB_TEST_mat_init
						  from dbo.nrt_observation_material mat where mat.act_uid in (SELECT value FROM STRING_SPLIT(@obs_ids, ','))
						   
							;


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #OBS_REASON '; 


			  IF OBJECT_ID('#OBS_REASON', 'U') IS NOT NULL 
			         drop table  #OBS_REASON;

						 select 
						 rsn.observation_uid,
							rsn.reason_desc_txt,
							rsn.reason_cd ,
						   cast( null as varchar(4000)) as REASON_FOR_TEST_DESC,
						   cast( null as varchar(2000)) as REASON_FOR_TEST_CD
						into  #OBS_REASON
						from dbo.nrt_observation_reason rsn where rsn.observation_uid in (SELECT value FROM STRING_SPLIT(@obs_ids, ','))
						;

						

		SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #OBS_REASON_FINAL '; 


			  IF OBJECT_ID('#OBS_REASON_FINAL', 'U') IS NOT NULL 
			         drop table  #OBS_REASON_FINAL ;


						   SELECT DISTINCT LRV.observation_uid,  
						   SUBSTRING(
								(
									SELECT '|'+coalesce(ST1.reason_cd+'('+reason_desc_txt+')','')  AS [text()]
									FROM #OBS_REASON ST1
									WHERE ST1.observation_uid = LRV.observation_uid
									ORDER BY ST1.observation_uid
									FOR XML PATH ('')
								), 2, 1000) REASON_FOR_TEST_DESC,
							SUBSTRING(
								(
									SELECT '|'+ST1.reason_cd  AS [text()]
									FROM #OBS_REASON ST1
									WHERE ST1.observation_uid = LRV.observation_uid
									ORDER BY ST1.observation_uid
									FOR XML PATH ('')
								), 2, 1000) REASON_FOR_TEST_CD
							into #OBS_REASON_FINAL 
							FROM #OBS_REASON LRV
							;

			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST_oth '; 


			  IF OBJECT_ID('#LAB_TEST_oth', 'U') IS NOT NULL 
			         drop table  #LAB_TEST_oth;

						 select 
							obs.observation_uid			as LAB_TEST_uid_oth,
							lti.interpretation_cd		 as interpretation_flg, 
							lti.accession_number 		 as ACCESSION_NBR, 
							(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(obs.REASON_FOR_TEST_DESC,
							  '&#x09;', CHAR(9)),
							  '&#x0A;', CHAR(10)),
							  '&#x0D;', CHAR(13)),
							  '&#x20;', CHAR(32)),
							  '&amp;', CHAR(38)),
							  '&lt;', CHAR(60)),
							  '&gt;', CHAR(62))) REASON_FOR_TEST_DESC,
							obs.REASON_FOR_TEST_CD,
							rtrim(lti.transcriptionist_first_nm)+' '+rtrim(lti.transcriptionist_last_nm) as transcriptionist_name,
							lti.transcriptionist_id_assign_auth as transcriptionist_ass_auth_cd,
							lti.transcriptionist_auth_type  as Transcriptionist_Ass_Auth_Type,
							lti.transcriptionist_val  as transcriptionist_id,
							rtrim(lti.assistant_interpreter_first_nm)+' '+rtrim(lti.assistant_interpreter_last_nm) as Assistant_Interpreter_Name,
							lti.assistant_interpreter_id_assign_auth  as Assistant_inter_ass_auth_cd,
							lti.assistant_interpreter_auth_type  as Assistant_inter_ass_auth_type,
							lti.assistant_interpreter_val  as Assistant_interpreter_id,
							rtrim(nprov.first_name)+' '+rtrim(nprov.last_name) as result_interpreter_name
						  into #LAB_TEST_oth
						  from #OBS_REASON_FINAL obs 
						  left join #LAB_TESTinit_a lti
						  	on obs.observation_uid = lti.LAB_TEST_uid_Test
						left join dbo.nrt_provider as nprov	on lti.result_interpreter_id= nprov.provider_uid
						;

					if @debug = 'true' select @Proc_Step_Name as step, * from #LAB_TEST_oth;
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_uid '; 


			  IF OBJECT_ID('#LAB_TEST1_uid', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_uid;

								select  LAB_TEST_uid_OTH AS LAB_TEST_uid 
									into #LAB_TEST1_uid
 									  from  #LAB_TEST_oth  union
									 select LAB_TEST_uid_mat 	 from  #LAB_TEST_mat_init  union 
									 select LAB_TEST_uid_test	 from  #LAB_TESTinit  
			 
									 ; 
	
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_TMP '; 


			  IF OBJECT_ID('#LAB_TEST1_TMP', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_TMP ;

 		
							   select  lt1.*,lto.*,ltmi.*,lti.*, lti.Lab_Rpt_Uid as Lab_Rpt_Uid_Test1
									into  #LAB_TEST1_TMP
 									from  #LAB_TEST1_uid lt1
 									  left outer join  #LAB_TEST_oth  lto on lt1.LAB_TEST_uid = lto.LAB_TEST_uid_oth
									  left outer join  #LAB_TEST_mat_init  ltmi  on lt1.LAB_TEST_uid = ltmi.LAB_TEST_uid_mat
									  left outer join  #LAB_TESTinit  lti on lt1.LAB_TEST_uid = lti.LAB_TEST_uid_Test
								;

				ALTER TABLE #LAB_TEST1_TMP DROP COLUMN Lab_Rpt_Uid;

	  


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LabReportMorb '; 


			  IF OBJECT_ID('#LabReportMorb', 'U') IS NOT NULL 
			         drop table  #LabReportMorb;


						  select * 
						  into #LabReportMorb
						  from #LAB_TEST1_TMP
						 where  LAB_TEST_type in ('Order', 'Result', 'Order_rslt') and  oid =4
						;

			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;


			-- IMPORTANT  - ASK UPASANA ABOUT THIS LOGIC
            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #Morb_OID '; 


			  IF OBJECT_ID('#Morb_OID', 'U') IS NOT NULL 
			         drop table  #Morb_OID ;

								select l.*, 
								o.PROGRAM_JURISDICTION_OID as Morb_oid,
								l.Lab_Rpt_Uid_Test1 as Lab_Rpt_Uid_Mor,
								l.LAB_TEST_uid as LAB_TEST_uid_mor ,
								l.LAB_TEST_uid_oth as LAB_TEST_uid_oth_mor
								into  #Morb_OID
								from #LabReportMorb l,
									dbo.nrt_observation l_extension,
									 dbo.nrt_observation o
								where 
								l.Lab_Rpt_Uid_Test1 = l_extension.observation_uid
								and o.observation_uid = l_extension.report_observation_uid -- column seems to be missing, also is it even the right column
								and o.CTRL_CD_DISPLAY_FORM = 'MorbReport'
									;

							   ALTER TABLE #Morb_OID 	DROP COLUMN Lab_Rpt_Uid_Test1,LAB_TEST_uid,LAB_TEST_uid_oth ;


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_uid2 '; 


			  IF OBJECT_ID('#LAB_TEST1_uid2', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_uid2;

								select  lab_rpt_uid_mor as   lab_rpt_uid
									into #LAB_TEST1_uid2
 									  from  #Morb_OID  union
									 select Lab_Rpt_Uid_Test1 	 from  #LAB_TEST1_TMP
			 
									 ; 
	
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST1 '; 


			  IF OBJECT_ID('#LAB_TEST1', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1 ;
 		
							   select  lt1.*,
							   lto.*,
							   tmo.Morb_oid,
							   Cast (null as  [varchar](100)) as PROCESSING_DECISION_DESC
									into  #LAB_TEST1
 									from  #LAB_TEST1_uid2 lt1
 									  left outer join  #LAB_TEST1_TMP  lto on lt1.lab_rpt_uid = lto.Lab_Rpt_Uid_Test1
									  left outer join  #Morb_OID  tmo on lt1.lab_rpt_uid = tmo.lab_rpt_uid_mor
								;

							 update #LAB_TEST1
							 set oid = morb_oid
							 where rtrim(morb_oid) is not null
							 ;
 

							update #LAB_TEST1 
									   set #LAB_TEST1.PROCESSING_DECISION_DESC = cvg.[code_short_desc_txt]
								from nbs_srte..Code_value_general cvg,
									  #LAB_TEST1 tlt1
								 where cvg.code_set_nm = 'STD_NBS_PROCESSING_DECISION_ALL' 
									  and   tlt1.PROCESSING_DECISION_CD = cvg.code
									   and   tlt1.PROCESSING_DECISION_CD is not null
									 ;


							update #LAB_TEST1 
									   set PROCESSING_DECISION_DESC = PROCESSING_DECISION_CD
									   WHERE PROCESSING_DECISION_CD is not null 
										AND PROCESSING_DECISION_DESC IS NULL
										;


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #R_Result_to_R_Order '; 


			-- verified same as classic process join with act_uid
			  IF OBJECT_ID('#R_Result_to_R_Order', 'U') IS NOT NULL 
			         drop table  #R_Result_to_R_Order;


						-- create table R_Result_to_R_Order as
						-- is source the lab_test_uid
						select 	tst.LAB_TEST_uid		'LAB_TEST_uid',	--as LAB_TEST_uid label='R_Result_uid',
						-- is target going to be our report_observation_id
								tst.report_observation_uid	'parent_test_pntr'	---as parent_test_pntr label='R_Order_uid'
						into  #R_Result_to_R_Order
						from 	#LAB_TEST1 as tst
 						where tst.LAB_TEST_type IN ('R_Result', 'I_Result')
								;


						 SELECT @ROWCOUNT_NO = @@ROWCOUNT;
		     INSERT INTO RDB.[DBO].[JOB_FLOW_LOG] 
				(BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
				VALUES(@BATCH_ID,'D_LABTEST','RDB.D_LABTEST','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #R_Result_to_R_Order_to_Order '; 


				-- this step gets the parent to R_Order records
				-- the highest level parent for R_Order is an Order, and that is the root record
			  IF OBJECT_ID('rdb.dbo.#R_Result_to_R_Order_to_Order', 'U') IS NOT NULL 
			         drop table   #R_Result_to_R_Order_to_Order;


						-- create table R_Result_to_R_Order_to_Order as
						select 	tst.*,
								coalesce(tst2.record_status_cd, tst3.record_status_cd, tst4.record_status_cd )
											 as record_status_cd_for_result_drug ,
								parent_test.report_sprt_uid			as root_thru_srpt,
								parent_test.report_refr_uid				as root_thru_refr,
								coalesce(parent_test.report_sprt_uid, 	parent_test.report_observation_uid)
															as root_ordered_test_pntr
						into #R_Result_to_R_Order_to_Order
						from #R_Result_to_R_Order	as tst
							left join 	dbo.nrt_observation as parent_test  
								on   parent_test.observation_uid = tst.parent_test_pntr
							left join dbo.nrt_observation as tst2
								on parent_test.report_sprt_uid = tst2.observation_uid
							left join dbo.nrt_observation as tst3
								on parent_test.report_refr_uid = tst3.observation_uid
							left join dbo.nrt_observation as tst4
								on parent_test.report_observation_uid = tst4.observation_uid
						;

						if @debug = 'true' select 'r_result_to_r_order_to_order' as nm, * from #R_Result_to_R_Order_to_Order;
						 SELECT @ROWCOUNT_NO = @@ROWCOUNT;
		     INSERT INTO RDB.[DBO].[JOB_FLOW_LOG] 
				(BATCH_ID,[DATAFLOW_NAME],[PACKAGE_NAME] ,[STATUS_TYPE],[STEP_NUMBER],[STEP_NAME],[ROW_COUNT])
				VALUES(@BATCH_ID,'D_LABTEST','RDB.D_LABTEST','START',  @PROC_STEP_NO,@PROC_STEP_NAME,@ROWCOUNT_NO);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_testuid '; 


			  IF OBJECT_ID('#LAB_TEST1_testuid', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_testuid;


						select lt1.LAB_TEST_uid
						into #LAB_TEST1_testuid
						from #LAB_TEST1 lt1
						union
						select rrr.LAB_TEST_uid
						from #R_Result_to_R_Order_to_Order rrr
						;


						 SELECT @ROWCOUNT_NO = @@ROWCOUNT;
		     SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_final '; 


			  IF OBJECT_ID('#LAB_TEST1_final', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_final;

						select dimc.LAB_TEST_uid as LAB_TEST_uid_final,
								tlt1.*,
								trr.[record_status_cd_for_result_drug] ,
								trr.[root_thru_srpt] ,
								trr.[root_thru_refr] ,
							   coalesce(trr.parent_test_pntr,tlt1.parent_test_pntr) as parent_test_pntr1, 
							   coalesce(trr.root_ordered_test_pntr,tlt1.root_ordered_test_pntr) as root_ordered_test_pntr1
						into #LAB_TEST1_final
						from #LAB_TEST1_testuid DIMC
											  LEFT OUTER JOIN   #LAB_TEST1 tlt1 ON  tlt1.LAB_TEST_uid  =  dimc.LAB_TEST_uid
											  LEFT OUTER JOIN   #R_Result_to_R_Order_to_Order trr ON  trr.LAB_TEST_uid  =  dimc.LAB_TEST_uid
						;				



							   update #LAB_TEST1_final
							   set  parent_test_pntr = parent_test_pntr1,
								   root_ordered_test_pntr = root_ordered_test_pntr1
		   								;



			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #R_Order_to_Result '; 


			  IF OBJECT_ID('#R_Order_to_Result', 'U') IS NOT NULL 
			         drop table  #R_Order_to_Result;
					 	
						select 	tst.LAB_TEST_uid			as LAB_TEST_uid ,
								tst.report_refr_uid			as parent_test_pntr, 
								tst2.observation_uid			as root_ordered_test_pntr, 
								tst2.record_status_cd as record_status_cd 
						into #R_Order_to_Result
						from 	#LAB_TEST1_final as tst
							LEFT JOIN dbo.nrt_observation obs2
								ON tst.report_refr_uid = obs2.observation_uid
							LEFT JOIN dbo.nrt_observation tst2
								ON obs2.report_observation_uid = tst2.observation_uid
						where tst.LAB_TEST_type IN( 'R_Order','I_Order')
						;


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_final_testuid '; 


			  IF OBJECT_ID('#LAB_TEST1_final_testuid', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_final_testuid;


						select lt1.LAB_TEST_uid
						into #LAB_TEST1_final_testuid
						from #LAB_TEST1_final lt1
						union
						select rrr.LAB_TEST_uid
						from #R_Order_to_Result rrr
						;


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_final_result '; 


			  IF OBJECT_ID('#LAB_TEST1_final_result', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_final_result;


						select dimc.LAB_TEST_uid as LAB_TEST_uid_final_result,
								tlt1.*,
								coalesce(trr.[record_status_cd], tlt1.[record_status_cd]) as record_status_cd2,
							   coalesce(trr.parent_test_pntr,tlt1.parent_test_pntr) as parent_test_pntr2, 
							   coalesce(trr.root_ordered_test_pntr,tlt1.root_ordered_test_pntr) as root_ordered_test_pntr2
						into #LAB_TEST1_final_result
						from #LAB_TEST1_final_testuid DIMC
											  LEFT OUTER JOIN   #LAB_TEST1_final tlt1 ON  tlt1.LAB_TEST_uid  =  dimc.LAB_TEST_uid
											  LEFT OUTER JOIN   #R_Order_to_Result trr ON  trr.LAB_TEST_uid  =  dimc.LAB_TEST_uid
						;				

							   update #LAB_TEST1_final_result
							   set record_status_cd = record_status_cd2,
								   parent_test_pntr = parent_test_pntr2,
								   root_ordered_test_pntr = root_ordered_test_pntr2
		   								;


						-- create table Result_to_Order as


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #Result_to_Order '; 


				-- gets the order (parent, also happens to be the root parents) for a record with type 'Result'
			  IF OBJECT_ID('#Result_to_Order', 'U') IS NOT NULL 
			         drop table  #Result_to_Order;

						select 	tst.LAB_TEST_uid			as LAB_TEST_uid ,
								tst.report_observation_uid			as parent_test_pntr ,
								tst.report_observation_uid			as root_ordered_test_pntr ,
								tst2.record_status_cd as record_status_cd 
						into  #Result_to_Order
						from 	#LAB_TEST1_final_result as tst,
								dbo.nrt_observation as tst2
							where tst.LAB_TEST_type in ('Result', 'Order_rslt')
								and tst2.observation_uid = tst.report_observation_uid
								and tst.lab_test_uid != tst.report_observation_uid
						;



			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST1_final_orderuid '; 


			  IF OBJECT_ID('#LAB_TEST1_final_orderuid', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_final_orderuid;


						select lt1.LAB_TEST_uid
						into #LAB_TEST1_final_orderuid
						from #LAB_TEST1_final_result lt1
						union
						select rrr.LAB_TEST_uid
						from #Result_to_Order rrr
						;


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);
				

			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_TEST1_final_order '; 
			  								

			  IF OBJECT_ID('#LAB_TEST1_final_order', 'U') IS NOT NULL 
			         drop table  r#LAB_TEST1_final_order;

						select distinct dimc.LAB_TEST_uid as LAB_TEST_uid_final_order,
								tlt1.*,
								coalesce( trr.[record_status_cd],tlt1.[record_status_cd]) as record_status_cd3,
							   coalesce(trr.parent_test_pntr,tlt1.parent_test_pntr) as parent_test_pntr3, 
							   coalesce(trr.root_ordered_test_pntr,tlt1.root_ordered_test_pntr) as root_ordered_test_pntr3
						into #LAB_TEST1_final_order
						from #LAB_TEST1_final_orderuid DIMC
											  LEFT OUTER JOIN   #LAB_TEST1_final_result tlt1 ON  tlt1.LAB_TEST_uid  =  dimc.LAB_TEST_uid
											  LEFT OUTER JOIN   #Result_to_Order trr ON  trr.LAB_TEST_uid  =  dimc.LAB_TEST_uid
						;				


							   update #LAB_TEST1_final_order
							   set record_status_cd = record_status_cd3,
								   parent_test_pntr = parent_test_pntr3,
								   root_ordered_test_pntr = root_ordered_test_pntr3
								;


							   update #LAB_TEST1_final_order
							   set parent_test_pntr = LAB_TEST_pntr,
								   root_ordered_test_pntr = LAB_TEST_pntr
								where LAB_TEST_type = 'Order'
								;



			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);

			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST2 '; 





			  IF OBJECT_ID('#LAB_TEST2', 'U') IS NOT NULL 
			         drop table  #LAB_TEST2 ;


						select tst.*,
						 obs.cd_desc_txt 'Root_Ordered_Test_Nm' 
						into #LAB_TEST2
						from      #LAB_TEST1_final_order as tst
							  left outer join dbo.nrt_observation as obs on  tst.root_ordered_test_pntr = obs.observation_uid
						;


			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_TEST3 '; 


			  IF OBJECT_ID('#LAB_TEST3', 'U') IS NOT NULL 
			         drop table  #LAB_TEST3;

						select tst.*, obs.cd_desc_txt 'Parent_Test_Nm' 
						into #LAB_TEST3
						from   #LAB_TEST2 as tst  
	 							  left outer join dbo.nrt_observation as obs on tst.parent_test_pntr = obs.observation_uid
						;


 
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST4 '; 


			  IF OBJECT_ID('#LAB_TEST4', 'U') IS NOT NULL   
 			                     drop table  #LAB_TEST4 ; 

 
						 select tst.*,
							obs.add_time as SPECIMEN_ADD_TIME,
							obs1.last_chg_time as SPECIMEN_LAST_CHANGE_TIME
						 into #LAB_TEST4
						 from #LAB_TEST3 as tst
 							left join dbo.nrt_observation as obs	on tst.LAB_TEST_uid = obs.observation_uid 	
																	  and obs.obs_domain_cd_st_1 = 'Order'  
							left join dbo.nrt_observation as obs1	on tst.LAB_TEST_uid = obs1.observation_uid
																	   and obs1.obs_domain_cd_st_1 = 'Order'  
						;

						
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING TMP_order_test '; 


			  IF OBJECT_ID('#order_test', 'U') IS NOT NULL   
 			                   drop table  #order_test ; 

						

						select 
						oid , 
						root_ordered_test_pntr 
						into #order_test
						from #LAB_TEST4 
						where LAB_TEST_Type = 'Order' and oid <> 4
						;

						alter table #LAB_TEST4 drop column oid ;
						

						/*note: When the OID is null that means this lab report is needing assignment of jurisdiction*/


						
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING TMP_LAB_TEST '; 


			  IF OBJECT_ID('#LAB_TEST', 'U') IS NOT NULL   
 		          	         drop table  #LAB_TEST ; 

						

						select distinct
								lab.*,
								ord.oid as order_oid 
						into #LAB_TEST
						from #LAB_TEST4 lab
							left join	#order_test ord	on lab.root_ordered_test_pntr=ord.root_ordered_test_pntr
						;

						

		SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #Merge_Order '; 


			  IF OBJECT_ID('#Merge_Order', 'U') IS NOT NULL 
			         drop table  #Merge_Order ;
						   


							select 	
								lt.root_ordered_test_pntr  as 	root_ordered_test_pntr_merge,
								obs.accession_number as ACCESSION_NBR_merge	,
								obs.add_user_id	as LAB_RPT_CREATED_BY_merge ,
								obs.ADD_TIME	as LAB_RPT_CREATED_DT,
								obs.JURISDICTION_CD	,
								cast(null as [varchar](50)) as JURISDICTION_NM	,
								obs.activity_to_time as LAB_TEST_dt	,
								obs.effective_from_time	 	 	as specimen_collection_dt	,
								obs.rpt_to_state_time  		 	as LAB_RPT_RECEIVED_BY_PH_DT	,
								obs.LAST_CHG_TIME 			 	as LAB_RPT_LAST_UPDATE_DT,
								obs.LAST_CHG_USER_ID		 	as LAB_RPT_LAST_UPDATE_BY,
								obs.electronic_ind			 	as ELR_IND1 	,
								mat.material_cd						 as specimen_src	,
								obs.target_site_cd			 	as specimen_site	,
								mat.material_desc				 as Specimen_desc	,
								obs.target_site_desc_txt  	 	as SPECIMEN_SITE_desc	,
								obs.local_id				 	as lab_rpt_local_id	,
								obs.record_status_cd as record_status_cd_merge,
								COALESCE(obs2.program_jurisdiction_oid, obs.program_jurisdiction_oid, lt.order_oid) as order_oid
							into #Merge_Order 
							from #LAB_TEST lt	
							left join dbo.nrt_observation obs
								on lt.root_ordered_test_pntr = obs.observation_uid
							left join dbo.nrt_observation obs2
								on obs.report_observation_uid = obs2.observation_uid and obs.ctrl_cd_display_form = 'LabReportMorb'
							left join dbo.nrt_observation_material mat
								on obs.observation_uid = mat.act_uid
								;	

							if @debug  = 'true' SELECT 'lab_test' as nm, * FROM #LAB_TEST;
							if @debug  = 'true' SELECT 'merge_order' as nm, * FROM #Merge_Order;



								
							update #Merge_Order
							set  record_status_cd_merge = 'ACTIVE'
							 where  record_status_cd_merge in ( '' ,	'UNPROCESSED',	'UNPROCESSED_PREV_D',	'PROCESSED' )
							 ;

							update #Merge_Order
							 set  record_status_cd_merge = 'INACTIVE'
							 where  record_status_cd_merge = 'LOG_DEL' 
							 ;

							 update #Merge_Order
							 set  order_oid = NULL
							 where  order_oid = 4
							 ;

							update #Merge_Order
						set jurisdiction_nm = (
						select code_short_desc_txt 
						from nbs_srte..jurisdiction_code where code= #Merge_Order.Jurisdiction_cd and code_set_nm = 'S_JURDIC_C'
						)
						where Jurisdiction_cd is not null
						;

						   update #LAB_TEST
								set record_status_cd = record_status_cd_for_result_drug
							where  record_status_cd ='' 
							;
	 
							update #LAB_TEST
								set LAB_TEST_DT = resulted_lab_report_date
							  where  LAB_TEST_TYPE ='Result' 
						   ; 
		
		
								update #LAB_TEST
								  set LAB_TEST_DT = sus_lab_report_date
								where LAB_TEST_TYPE ='Order_rslt' 
								;

								alter table #LAB_TEST
								drop column
									ACCESSION_NBR	,
									LAB_RPT_CREATED_BY	,
									LAB_RPT_CREATED_DT	,
									JURISDICTION_CD	,
									JURISDICTION_NM	,
									LAB_TEST_dt	,
									specimen_collection_dt	,
									LAB_RPT_RECEIVED_BY_PH_DT	,
									LAB_RPT_LAST_UPDATE_DT	,
									LAB_RPT_LAST_UPDATE_BY	,
								--	ELR_IND	,
									resulted_lab_report_date	,
									sus_lab_report_date	,
									specimen_src	,
									specimen_site	,
									Specimen_desc	,
									SPECIMEN_SITE_desc	,
									LAB_RPT_LOCAL_ID	,
									record_status_cd_for_result	,
									record_status_cd_for_result_drug,
									order_oid;
								
	
							update #LAB_TEST
							set  record_status_cd = 'ACTIVE'
							 where  record_status_cd in ( '' ,	'UNPROCESSED',	'UNPROCESSED_PREV_D',	'PROCESSED' )
								 or record_status_cd is null
							 ;

							update #LAB_TEST
							 set  record_status_cd = 'INACTIVE'
							 where  record_status_cd = 'LOG_DEL' 
							 ;
	

   							update #LAB_TEST
							 set  TEST_METHOD_CD_DESC = null
							  where rtrim(TEST_METHOD_CD_DESC) = ''
							 ;





			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;



            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST_final_root_ordered_test_pntr '; 


			  IF OBJECT_ID('#LAB_TEST_final_root_ordered_test_pntr', 'U') IS NOT NULL 
			         drop table  #LAB_TEST_final_root_ordered_test_pntr;

								select  root_ordered_test_pntr AS LAB_TEST_ptnr 
								 into #LAB_TEST_final_root_ordered_test_pntr
 								  from  #LAB_TEST 
									 union
								 select root_ordered_test_pntr_merge
		 							 from  #Merge_Order  
								 ; 

						
	
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;
			
            BEGIN TRANSACTION; 

			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #LAB_TEST_final'; 


			  IF OBJECT_ID('#LAB_TEST_final', 'U') IS NOT NULL 
			         drop table  #LAB_TEST_final ;

					
							   select  lt1.*,lto.*, ltmi.* 
									into  #LAB_TEST_final
 									from  #LAB_TEST_final_root_ordered_test_pntr lt1
 									  left outer join  #LAB_TEST  lto        on lt1.LAB_TEST_ptnr = lto.root_ordered_test_pntr
									  left outer join #Merge_Order  ltmi  on lt1.LAB_TEST_ptnr = ltmi.root_ordered_test_pntr_merge
								;

								update #LAB_TEST_final
								set ELR_IND = ELR_IND1
								where ELR_IND1 is not null
								;
								 
                               update #LAB_TEST_final
								set record_status_cd = record_status_cd_merge
								where record_status_cd_merge is not null
								;
								 



		                        alter table  #LAB_TEST_final
								   drop column  ELR_IND1;



		
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;


            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #L_LAB_TEST_N '; 


			IF OBJECT_ID('#L_LAB_TEST_N', 'U') IS NOT NULL 
			    drop table  #L_LAB_TEST_N;


								CREATE TABLE #L_LAB_TEST_N
											(
											[LAB_TEST_id]  [int] IDENTITY(1,1) NOT NULL,
                							[LAB_TEST_UID] [numeric](20, 0) NULL,
											[LAB_TEST_KEY] [numeric](18, 0) NULL
											 ) ON [PRIMARY]
											 ;


							-- REMOVES VALUES THAT ARE ALREADY IN LAB_TEST
							insert into #L_LAB_TEST_N	([LAB_TEST_UID])
							SELECT DISTINCT tlt.LAB_TEST_UID 
							  FROM #LAB_TEST_final tlt
							EXCEPT 
							SELECT lt.LAB_TEST_UID 
							FROM rdb_modern..LAB_TEST lt
							;



							UPDATE #L_LAB_TEST_N 
										   SET LAB_TEST_KEY = LAB_TEST_ID + coalesce((SELECT MAX(LAB_TEST_KEY) FROM RDB_modern.dbo.L_LAB_TEST),0)
		


							DELETE FROM #L_LAB_TEST_N WHERE LAB_TEST_UID IS NULL;

		

      SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = 'INSERTING INTO L_LAB_TEST'; 


							INSERT INTO RDB_MODERN..L_LAB_TEST
							 ([LAB_TEST_KEY]
							  ,[LAB_TEST_UID])
							  SELECT    [LAB_TEST_KEY],
							  [LAB_TEST_UID]
	            			FROM #L_LAB_TEST_N
							;



		

			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #D_LAB_TEST_N '; 


			  IF OBJECT_ID('#D_LAB_TEST_N', 'U') IS NOT NULL 
			         drop table  #D_LAB_TEST_N;

						


							SELECT distinct  lt.* , ltn.[LAB_TEST_KEY]
							INTO #D_LAB_TEST_N
							  FROM #LAB_TEST_final  lt, 
								   #L_LAB_TEST_N ltn
							 WHERE lt.LAB_TEST_UID=ltn.LAB_TEST_UID
						;


								 UPDATE  #D_LAB_TEST_N  SET JURISdiction_nm = NULL  where JURISdiction_nm = '' ;
 
								 UPDATE  #D_LAB_TEST_N  SET [ACCESSION_NBR_merge] = NULL  where [ACCESSION_NBR_merge] = '' ;

								 UPDATE  #D_LAB_TEST_N  SET [SPECIMEN_DESC] = NULL  where [SPECIMEN_DESC] = '' ;
   
								 UPDATE  #D_LAB_TEST_N  SET [SPECIMEN_SRC] = NULL  where [SPECIMEN_SRC] = '' ;
    
								 UPDATE  #D_LAB_TEST_N  SET [CLINICAL_INFORMATION] = NULL  where [CLINICAL_INFORMATION] = '' ;
  
								 UPDATE  #D_LAB_TEST_N  SET REASON_FOR_TEST_DESC = NULL  where REASON_FOR_TEST_DESC = '' ;
  
  								 UPDATE  #D_LAB_TEST_N  SET REASON_FOR_TEST_CD = NULL  where REASON_FOR_TEST_CD = '' ;
  
  
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;


			BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #D_LAB_TEST_U '; 


			  IF OBJECT_ID('#D_LAB_TEST_U', 'U') IS NOT NULL 
			         drop table  #D_LAB_TEST_U;

						


							SELECT distinct  lt.*
							INTO #D_LAB_TEST_U
							  FROM #LAB_TEST_final  lt 
							 WHERE lt.LAB_TEST_UID IN (select LAB_TEST_UID FROM rdb_modern.dbo.LAB_TEST)
						;


								 UPDATE  #D_LAB_TEST_U  SET JURISdiction_nm = NULL  where JURISdiction_nm = '' ;
 
								 UPDATE  #D_LAB_TEST_U  SET [ACCESSION_NBR_merge] = NULL  where [ACCESSION_NBR_merge] = '' ;

								 UPDATE  #D_LAB_TEST_U  SET [SPECIMEN_DESC] = NULL  where [SPECIMEN_DESC] = '' ;
   
								 UPDATE  #D_LAB_TEST_U  SET [SPECIMEN_SRC] = NULL  where [SPECIMEN_SRC] = '' ;
    
								 UPDATE  #D_LAB_TEST_U  SET [CLINICAL_INFORMATION] = NULL  where [CLINICAL_INFORMATION] = '' ;
  
								 UPDATE  #D_LAB_TEST_U  SET REASON_FOR_TEST_DESC = NULL  where REASON_FOR_TEST_DESC = '' ;
  
  								 UPDATE  #D_LAB_TEST_U  SET REASON_FOR_TEST_CD = NULL  where REASON_FOR_TEST_CD = '' ;
  
  
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

			if @debug = 'true' RETURN;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = 'insert into rdb_modern..LAB_TEST'; 



				   insert into rdb_modern..LAB_TEST
						 (
						 [LAB_TEST_STATUS]
						  ,[LAB_TEST_KEY]
						  ,[LAB_RPT_LOCAL_ID]
						  ,[TEST_METHOD_CD]
						  ,[TEST_METHOD_CD_DESC]
						  ,[LAB_RPT_SHARE_IND]
						  ,[LAB_TEST_CD]
						  ,[ELR_IND]
						  ,[LAB_RPT_UID]
						  ,[LAB_TEST_CD_DESC]
						  ,[INTERPRETATION_FLG]
						  ,[LAB_RPT_RECEIVED_BY_PH_DT]
						  ,[LAB_RPT_CREATED_BY]
						  ,[REASON_FOR_TEST_DESC]
						  ,[REASON_FOR_TEST_CD]
						  ,[LAB_RPT_LAST_UPDATE_BY]
						  ,[LAB_TEST_DT]
						  ,[LAB_RPT_CREATED_DT]
						  ,[LAB_TEST_TYPE]
						  ,[LAB_RPT_LAST_UPDATE_DT]
						  ,[JURISDICTION_CD]
						  ,[LAB_TEST_CD_SYS_CD]
						  ,[LAB_TEST_CD_SYS_NM]
						  ,[JURISDICTION_NM]
						  ,[OID]
						  ,[ALT_LAB_TEST_CD]
						  ,[LAB_RPT_STATUS]
						  ,[DANGER_CD_DESC]
						  ,ALT_LAB_TEST_CD_DESC
						  ,[ACCESSION_NBR]
						  ,[SPECIMEN_SRC]
						  ,[PRIORITY_CD]
						  ,[ALT_LAB_TEST_CD_SYS_CD]
						  ,[ALT_LAB_TEST_CD_SYS_NM]
						  ,[SPECIMEN_SITE]
						  ,[SPECIMEN_DETAILS]
						  ,[DANGER_CD]
						  ,[SPECIMEN_COLLECTION_VOL]
						  ,[SPECIMEN_COLLECTION_VOL_UNIT]
						  ,[SPECIMEN_DESC]
						  ,[SPECIMEN_SITE_DESC]
						  ,[CLINICAL_INFORMATION]
						  ,[LAB_TEST_UID]
						  ,[ROOT_ORDERED_TEST_PNTR]
						  ,[PARENT_TEST_PNTR]
						  ,[LAB_TEST_PNTR]
						  ,[SPECIMEN_ADD_TIME]
						  ,[SPECIMEN_LAST_CHANGE_TIME]
						  ,[SPECIMEN_COLLECTION_DT]
						  ,[SPECIMEN_NM]
						  ,[ROOT_ORDERED_TEST_NM]
						  ,[PARENT_TEST_NM]
						  ,[TRANSCRIPTIONIST_NAME]
						  ,[TRANSCRIPTIONIST_ID]
						  ,[TRANSCRIPTIONIST_ASS_AUTH_CD]
						  ,[TRANSCRIPTIONIST_ASS_AUTH_TYPE]
						  ,[ASSISTANT_INTERPRETER_NAME]
						  ,[ASSISTANT_INTERPRETER_ID]
						  ,[ASSISTANT_INTER_ASS_AUTH_CD]
						  ,[ASSISTANT_INTER_ASS_AUTH_TYPE]
						  ,[RESULT_INTERPRETER_NAME]
						  ,[RECORD_STATUS_CD]
						  ,[RDB_LAST_REFRESH_TIME]
						  ,[CONDITION_CD]
						  ,[PROCESSING_DECISION_CD]
						  ,[PROCESSING_DECISION_DESC]
						  )
						select rtrim( cast( LAB_TEST_STATUS AS varchar(50)))
						  ,[LAB_TEST_KEY]
						,rtrim( cast( LAB_RPT_LOCAL_ID AS varchar(50)))
						,rtrim( cast( TEST_METHOD_CD AS varchar(199)))
						,rtrim( cast( TEST_METHOD_CD_DESC AS varchar(199)))
						,rtrim( cast( LAB_RPT_SHARE_IND AS varchar(50)))
						,rtrim( cast( LAB_TEST_CD AS varchar(1000)))
						,rtrim( cast( ELR_IND AS varchar(50)))
						  ,[LAB_RPT_UID]
						,rtrim( cast( LAB_TEST_CD_DESC AS varchar(2000)))
						,rtrim( cast( INTERPRETATION_CD AS varchar(20)))
						  ,[LAB_RPT_RECEIVED_BY_PH_DT]
						  ,[LAB_RPT_CREATED_BY_MERGE]
						,rtrim( cast( REASON_FOR_TEST_DESC AS varchar(4000)))
						,rtrim( cast( REASON_FOR_TEST_CD AS varchar(4000)))
						  ,[LAB_RPT_LAST_UPDATE_BY]
						  ,[LAB_TEST_DT]
						  ,[LAB_RPT_CREATED_DT]
						,rtrim( cast( LAB_TEST_TYPE AS varchar(50)))
						  ,[LAB_RPT_LAST_UPDATE_DT]
						,rtrim( cast( JURISDICTION_CD AS varchar(20)))
						,rtrim( cast( LAB_TEST_CD_SYS_CD AS varchar(50)))
						,rtrim( cast( LAB_TEST_CD_SYS_NM AS varchar(100)))
						,rtrim( cast( JURISDICTION_NM AS varchar(50)))
						  ,order_OID
						,rtrim( cast( ALT_LAB_TEST_CD AS varchar(50)))
						, cast( LAB_RPT_STATUS AS char(1))
						,rtrim( cast( DANGER_CD_DESC AS varchar(100)))
						,rtrim( cast( ALT_LAB_TEST_CD_DESC AS varchar(1000)))
						,rtrim( cast( ACCESSION_NBR_MERGE AS varchar(199)))
						,rtrim( cast( SPECIMEN_SRC AS varchar(50)))
						,rtrim( cast( PRIORITY_CD AS varchar(20)))
						,rtrim( cast( ALT_LAB_TEST_CD_SYS_CD AS varchar(50)))
						,rtrim( cast( ALT_LAB_TEST_CD_SYS_NM AS varchar(100)))
						,rtrim( cast( SPECIMEN_SITE AS varchar(20)))
						,rtrim( cast( SPECIMEN_DETAILS AS varchar(1000)))
						,rtrim( cast( DANGER_CD AS varchar(20)))
						,rtrim( cast( SPECIMEN_COLLECTION_VOL AS varchar(20)))
						,rtrim( cast( SPECIMEN_COLLECTION_VOL_UNIT AS varchar(50)))
						,rtrim( cast( SPECIMEN_DESC AS varchar(1000)))
						,rtrim( cast( SPECIMEN_SITE_DESC AS varchar(100)))
						,rtrim( cast( CLINICAL_INFORMATION AS varchar(1000)))
						  ,[LAB_TEST_UID]
						  ,[ROOT_ORDERED_TEST_PNTR]
						  ,[PARENT_TEST_PNTR]
						  ,[LAB_TEST_PNTR]
						  ,[SPECIMEN_ADD_TIME]
						  ,[SPECIMEN_LAST_CHANGE_TIME]
						  ,[SPECIMEN_COLLECTION_DT]
						,rtrim( cast( SPECIMEN_NM AS varchar(100)))
						,rtrim( cast( ROOT_ORDERED_TEST_NM AS varchar(1000)))
						,rtrim( cast( PARENT_TEST_NM AS varchar(1000)))
						,rtrim( cast( TRANSCRIPTIONIST_NAME AS varchar(300)))
						,rtrim( cast( TRANSCRIPTIONIST_ID AS varchar(100)))
						,rtrim( cast( TRANSCRIPTIONIST_ASS_AUTH_CD AS varchar(199)))
						,rtrim( cast( TRANSCRIPTIONIST_ASS_AUTH_TYPE AS varchar(100)))
						,rtrim( cast( ASSISTANT_INTERPRETER_NAME AS varchar(300)))
						,rtrim( cast( ASSISTANT_INTERPRETER_ID AS varchar(100)))
						,rtrim( cast( ASSISTANT_INTER_ASS_AUTH_CD AS varchar(199)))
						,rtrim( cast( ASSISTANT_INTER_ASS_AUTH_TYPE AS varchar(100)))
						,rtrim( cast( RESULT_INTERPRETER_NAME AS varchar(300)))
						,rtrim( cast( RECORD_STATUS_CD AS varchar(8)))
						  ,GETDATE()
						,rtrim( cast( CONDITION_CD AS varchar(20)))
						,rtrim( cast( PROCESSING_DECISION_CD AS varchar(50)))
						,rtrim( cast( PROCESSING_DECISION_DESC AS varchar(50)))
					FROM #D_LAB_TEST_N
						  ;


						/*-------------------------------------------------------

							Lab_Report_User_Comment Dimension

							Note: Comments under the Order Test object (LAB214)
						---------------------------------------------------------*/ 




			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

			BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = 'insert into rdb_modern..LAB_TEST'; 



				   UPDATE 
				   	lt 
				   SET
						 lt.[LAB_TEST_STATUS] = rtrim( cast( dltu.LAB_TEST_STATUS AS varchar(50)))
						  ,lt.[LAB_RPT_LOCAL_ID] = rtrim( cast( dltu.LAB_RPT_LOCAL_ID AS varchar(50)))
						  ,lt.[TEST_METHOD_CD] = rtrim( cast( dltu.TEST_METHOD_CD AS varchar(199)))
						  ,lt.[TEST_METHOD_CD_DESC] = rtrim( cast( dltu.TEST_METHOD_CD_DESC AS varchar(199)))
						  ,lt.[LAB_RPT_SHARE_IND] = rtrim( cast( dltu.LAB_RPT_SHARE_IND AS varchar(50)))
						  ,lt.[LAB_TEST_CD] = rtrim( cast( dltu.LAB_TEST_CD AS varchar(1000)))
						  ,lt.[ELR_IND] = rtrim( cast( dltu.ELR_IND AS varchar(50)))
						  ,lt.[LAB_RPT_UID] = dltu.LAB_RPT_UID
						  ,lt.[LAB_TEST_CD_DESC] = rtrim( cast( dltu.LAB_TEST_CD_DESC AS varchar(2000)))
						  ,lt.[INTERPRETATION_FLG] = rtrim( cast( dltu.INTERPRETATION_CD AS varchar(20)))
						  ,lt.[LAB_RPT_RECEIVED_BY_PH_DT] = dltu.LAB_RPT_RECEIVED_BY_PH_DT
						  ,lt.[LAB_RPT_CREATED_BY] = dltu.LAB_RPT_CREATED_BY_MERGE
						  ,lt.[REASON_FOR_TEST_DESC] = rtrim( cast( dltu.REASON_FOR_TEST_DESC AS varchar(4000)))
						  ,lt.[REASON_FOR_TEST_CD] = rtrim( cast( dltu.REASON_FOR_TEST_CD AS varchar(4000)))
						  ,lt.[LAB_RPT_LAST_UPDATE_BY] = dltu.LAB_RPT_LAST_UPDATE_BY
						  ,lt.[LAB_TEST_DT] = dltu.LAB_TEST_DT
						  ,lt.[LAB_RPT_CREATED_DT] = dltu.LAB_RPT_CREATED_DT
						  ,lt.[LAB_TEST_TYPE] = rtrim( cast( dltu.LAB_TEST_TYPE AS varchar(50)))
						  ,lt.[LAB_RPT_LAST_UPDATE_DT] = dltu.LAB_RPT_LAST_UPDATE_DT
						  ,lt.[JURISDICTION_CD] = rtrim( cast( dltu.JURISDICTION_CD AS varchar(20)))
						  ,lt.[LAB_TEST_CD_SYS_CD] = rtrim( cast( dltu.LAB_TEST_CD_SYS_CD AS varchar(50)))
						  ,lt.[LAB_TEST_CD_SYS_NM] = rtrim( cast( dltu.LAB_TEST_CD_SYS_NM AS varchar(100)))
						  ,lt.[JURISDICTION_NM] = rtrim( cast( dltu.JURISDICTION_NM AS varchar(50)))
						  ,lt.[OID] = dltu.order_OID
						  ,lt.[ALT_LAB_TEST_CD] = rtrim( cast( dltu.ALT_LAB_TEST_CD AS varchar(50)))
						  ,lt.[LAB_RPT_STATUS] = cast( dltu.LAB_RPT_STATUS AS char(1))
						  ,lt.[DANGER_CD_DESC] = rtrim( cast( dltu.DANGER_CD_DESC AS varchar(100)))
						  ,lt.ALT_LAB_TEST_CD_DESC = rtrim( cast( dltu.ALT_LAB_TEST_CD_DESC AS varchar(1000)))
						  ,lt.[ACCESSION_NBR] = rtrim( cast( dltu.ACCESSION_NBR_MERGE AS varchar(199)))
						  ,lt.[SPECIMEN_SRC] = rtrim( cast( dltu.SPECIMEN_SRC AS varchar(50)))
						  ,lt.[PRIORITY_CD] = rtrim( cast( dltu.PRIORITY_CD AS varchar(20)))
						  ,lt.[ALT_LAB_TEST_CD_SYS_CD] = rtrim( cast( dltu.ALT_LAB_TEST_CD_SYS_CD AS varchar(50)))
						  ,lt.[ALT_LAB_TEST_CD_SYS_NM] = rtrim( cast( dltu.ALT_LAB_TEST_CD_SYS_NM AS varchar(100)))
						  ,lt.[SPECIMEN_SITE] = rtrim( cast( dltu.SPECIMEN_SITE AS varchar(20)))
						  ,lt.[SPECIMEN_DETAILS] = rtrim( cast( dltu.SPECIMEN_DETAILS AS varchar(1000)))
						  ,lt.[DANGER_CD] = rtrim( cast( dltu.DANGER_CD AS varchar(20)))
						  ,lt.[SPECIMEN_COLLECTION_VOL] = rtrim( cast( dltu.SPECIMEN_COLLECTION_VOL AS varchar(20)))
						  ,lt.[SPECIMEN_COLLECTION_VOL_UNIT] = rtrim( cast( dltu.SPECIMEN_COLLECTION_VOL_UNIT AS varchar(50)))
						  ,lt.[SPECIMEN_DESC] = rtrim( cast( dltu.SPECIMEN_DESC AS varchar(1000)))
						  ,lt.[SPECIMEN_SITE_DESC] = rtrim( cast( dltu.SPECIMEN_SITE_DESC AS varchar(100)))
						  ,lt.[CLINICAL_INFORMATION] = rtrim( cast( dltu.CLINICAL_INFORMATION AS varchar(1000)))
						  ,lt.[ROOT_ORDERED_TEST_PNTR] = dltu.ROOT_ORDERED_TEST_PNTR
						  ,lt.[PARENT_TEST_PNTR] = dltu.PARENT_TEST_PNTR
						  ,lt.[LAB_TEST_PNTR] = dltu.LAB_TEST_PNTR
						  ,lt.[SPECIMEN_ADD_TIME] = dltu.SPECIMEN_ADD_TIME
						  ,lt.[SPECIMEN_LAST_CHANGE_TIME] = dltu.SPECIMEN_LAST_CHANGE_TIME
						  ,lt.[SPECIMEN_COLLECTION_DT] = dltu.SPECIMEN_COLLECTION_DT
						  ,lt.[SPECIMEN_NM] = rtrim( cast( dltu.SPECIMEN_NM AS varchar(100)))
						  ,lt.[ROOT_ORDERED_TEST_NM] = rtrim( cast( dltu.ROOT_ORDERED_TEST_NM AS varchar(1000)))
						  ,lt.[PARENT_TEST_NM] = rtrim( cast( dltu.PARENT_TEST_NM AS varchar(1000)))
						  ,lt.[TRANSCRIPTIONIST_NAME] = rtrim( cast( dltu.TRANSCRIPTIONIST_NAME AS varchar(300)))
						  ,lt.[TRANSCRIPTIONIST_ID] = rtrim( cast( dltu.TRANSCRIPTIONIST_ID AS varchar(100)))
						  ,lt.[TRANSCRIPTIONIST_ASS_AUTH_CD] = rtrim( cast( dltu.TRANSCRIPTIONIST_ASS_AUTH_CD AS varchar(199)))
						  ,lt.[TRANSCRIPTIONIST_ASS_AUTH_TYPE] = rtrim( cast( dltu.TRANSCRIPTIONIST_ASS_AUTH_TYPE AS varchar(100)))
						  ,lt.[ASSISTANT_INTERPRETER_NAME] = rtrim( cast( dltu.ASSISTANT_INTERPRETER_NAME AS varchar(300)))
						  ,lt.[ASSISTANT_INTERPRETER_ID] = rtrim( cast( dltu.ASSISTANT_INTERPRETER_ID AS varchar(100)))
						  ,lt.[ASSISTANT_INTER_ASS_AUTH_CD] = rtrim( cast( dltu.ASSISTANT_INTER_ASS_AUTH_CD AS varchar(199)))
						  ,lt.[ASSISTANT_INTER_ASS_AUTH_TYPE] = rtrim( cast( dltu.ASSISTANT_INTER_ASS_AUTH_TYPE AS varchar(100)))
						  ,lt.[RESULT_INTERPRETER_NAME] = rtrim( cast( dltu.RESULT_INTERPRETER_NAME AS varchar(300)))
						  ,lt.[RECORD_STATUS_CD] = rtrim( cast( dltu.RECORD_STATUS_CD AS varchar(8)))
						  ,lt.[RDB_LAST_REFRESH_TIME] = GETDATE()
						  ,lt.[CONDITION_CD] = rtrim( cast( dltu.CONDITION_CD AS varchar(20)))
						  ,lt.[PROCESSING_DECISION_CD] = rtrim( cast( dltu.PROCESSING_DECISION_CD AS varchar(50)))
						  ,lt.[PROCESSING_DECISION_DESC] = rtrim( cast( dltu.PROCESSING_DECISION_DESC AS varchar(50)))
					FROM rdb_modern..LAB_TEST lt, #D_LAB_TEST_U dltu
					WHERE lt.lab_test_uid = dltu.lab_test_uid
						  ;


						/*-------------------------------------------------------

							Lab_Report_User_Comment Dimension

							Note: Comments under the Order Test object (LAB214)
						---------------------------------------------------------*/ 




			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #Lab_Rpt_User_Comment_N '; 


			  IF OBJECT_ID('#Lab_Rpt_User_Comment_N', 'U') IS NOT NULL 
			                      drop table  #Lab_Rpt_User_Comment_N;

								CREATE TABLE #Lab_Rpt_User_Comment_N (
									[LAB_COMMENT_id]  [int] IDENTITY(1,1) NOT NULL,
        							[LAB_TEST_Key] [bigint]  NULL,
									[LAB_TEST_uid] [bigint] NULL,
									[COMMENTS_FOR_ELR_DT] [datetime] NULL,
									[USER_COMMENT_CREATED_BY] [bigint] NULL,
									[USER_RPT_COMMENTS] [varchar](8000) NULL,
									[RECORD_STATUS_CD] [varchar](8) NOT NULL,
									[observation_uid] [bigint] NOT NULL,
									USER_COMMENT_KEY [bigint],
									[RDB_LAST_REFRESH_TIME] [datetime] NULL
								) ON [PRIMARY]
								;


							INSERT INTO #Lab_Rpt_User_Comment_N
							select 	distinct tdltn.LAB_TEST_Key,
									tdltn.lab_rpt_uid as LAB_TEST_uid,
									lab214.activity_to_time	'COMMENTS_FOR_ELR_DT' ,
									lab214.add_user_id		'USER_COMMENT_CREATED_BY' ,
									REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')	'USER_RPT_COMMENTS',--TRANSLATE(ovt.value_txt,' ' ,'0D0A'x)	'USER_RPT_COMMENTS' ,
									tdltn.record_status_cd        'RECORD_STATUS_CD' ,
									lab214.observation_uid,
									NULL,
									NULL
							from 	#D_LAB_TEST_N	    as tdltn,
									dbo.nrt_observation		as obs,
									dbo.nrt_observation		as lab214,
									dbo.nrt_observation_txt 	as ovt
							where   ovt.ovt_value_txt is not null
									and obs.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ','))
									and obs.obs_domain_cd_st_1 = 'C_Order'
									and lab214.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ','))
									and lab214.obs_domain_cd_st_1 = 'C_Result'
									and tdltn.followup_observation_uid is not null
									and lab214.observation_uid = ovt.observation_uid
		
							;
	
	                      
			                SELECT @RowCount_no = @@ROWCOUNT;

							update #Lab_Rpt_User_Comment_N
							set  record_status_cd = 'ACTIVE'
							 where  record_status_cd in ( '' ,	'UNPROCESSED',	'PROCESSED' )
							 ;

							update #Lab_Rpt_User_Comment_N
							 set  record_status_cd = 'INACTIVE'
							 where  record_status_cd = 'LOG_DEL' 
							 ;
	
							   UPDATE #Lab_Rpt_User_Comment_N
										   SET USER_COMMENT_KEY= [LAB_COMMENT_id] + coalesce((SELECT MAX(USER_COMMENT_KEY) FROM rdb_modern.dbo.Lab_Rpt_User_Comment),1)
		

							delete from #LAB_RPT_USER_COMMENT_N 
							  where LAB_TEST_KEY= null;

							UPDATE #Lab_Rpt_User_Comment_N
							  set RDB_LAST_REFRESH_TIME=getdate();
   
   
							UPDATE #Lab_Rpt_User_Comment_N
							  set [USER_RPT_COMMENTS]= null
							  where [USER_RPT_COMMENTS] = ''
							  ;
   
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = 'INSERTING INTO rdb_modern..Lab_Rpt_User_Comment'; 



							insert into rdb_modern.dbo.Lab_Rpt_User_Comment
							(
							   [USER_COMMENT_KEY]
							  ,[USER_RPT_COMMENTS]
							  ,[COMMENTS_FOR_ELR_DT]
							  ,[USER_COMMENT_CREATED_BY]
							  ,[LAB_TEST_KEY]
							  ,[RECORD_STATUS_CD]
							  ,[LAB_TEST_UID]
							  ,[RDB_LAST_REFRESH_TIME] 
							  )
							select [USER_COMMENT_KEY]
							  ,rtrim( cast( [USER_RPT_COMMENTS] AS varchar(2000)))
							  ,[COMMENTS_FOR_ELR_DT]
							  ,[USER_COMMENT_CREATED_BY]
							  ,[LAB_TEST_KEY]
							  ,rtrim( cast( [RECORD_STATUS_CD] AS varchar(8)))
							  ,[LAB_TEST_UID]
							  ,[RDB_LAST_REFRESH_TIME]
						  FROM #LAB_RPT_USER_COMMENT_N
						  ;

						  
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

			BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = ' GENERATING #Lab_Rpt_User_Comment_U '; 


			  IF OBJECT_ID('#Lab_Rpt_User_Comment_U', 'U') IS NOT NULL 
			                      drop table  #Lab_Rpt_User_Comment_U;

								CREATE TABLE #Lab_Rpt_User_Comment_U (
									[LAB_COMMENT_id]  [int] IDENTITY(1,1) NOT NULL,
									[LAB_TEST_uid] [bigint] NULL,
									[COMMENTS_FOR_ELR_DT] [datetime] NULL,
									[USER_COMMENT_CREATED_BY] [bigint] NULL,
									[USER_RPT_COMMENTS] [varchar](8000) NULL,
									[RECORD_STATUS_CD] [varchar](8) NOT NULL,
									[observation_uid] [bigint] NOT NULL,
									[RDB_LAST_REFRESH_TIME] [datetime] NULL
								) ON [PRIMARY]
								;


							INSERT INTO #Lab_Rpt_User_Comment_U
							select 	distinct 
									tdltn.lab_rpt_uid as LAB_TEST_uid,
									lab214.activity_to_time	'COMMENTS_FOR_ELR_DT' ,
									lab214.add_user_id		'USER_COMMENT_CREATED_BY' ,
									REPLACE(REPLACE(ovt.ovt_value_txt, CHAR(13), ' '), CHAR(10), ' ')	'USER_RPT_COMMENTS',--TRANSLATE(ovt.value_txt,' ' ,'0D0A'x)	'USER_RPT_COMMENTS' ,
									tdltn.record_status_cd        'RECORD_STATUS_CD' ,
									lab214.observation_uid,
									getdate()
							from 	#D_LAB_TEST_U	    as tdltn,
									dbo.nrt_observation		as obs,
									dbo.nrt_observation		as lab214,
									dbo.nrt_observation_txt 	as ovt
							where   ovt.ovt_value_txt is not null
									and obs.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ','))
									and obs.obs_domain_cd_st_1 = 'C_Order'
									and lab214.observation_uid IN (SELECT value FROM STRING_SPLIT(tdltn.followup_observation_uid, ','))
									and lab214.obs_domain_cd_st_1 = 'C_Result'
									and tdltn.followup_observation_uid is not null
									and lab214.observation_uid = ovt.observation_uid
		
							;
	
	                      
			                SELECT @RowCount_no = @@ROWCOUNT;

							update #Lab_Rpt_User_Comment_U
							set  record_status_cd = 'ACTIVE'
							 where  record_status_cd in ( '' ,	'UNPROCESSED',	'PROCESSED' )
							 ;

							update #Lab_Rpt_User_Comment_U
							 set  record_status_cd = 'INACTIVE'
							 where  record_status_cd = 'LOG_DEL' 
							 ;
		
   
							UPDATE #Lab_Rpt_User_Comment_U
							  set [USER_RPT_COMMENTS]= null
							  where [USER_RPT_COMMENTS] = ''
							  ;
   
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;
			SET @PROC_STEP_NAME = 'UPDATING rdb_modern..Lab_Rpt_User_Comment'; 



							UPDATE 
							lruc
							SET
							  lruc.[USER_RPT_COMMENTS] = lrucu.USER_RPT_COMMENTS
							  ,lruc.[COMMENTS_FOR_ELR_DT] = lrucu.COMMENTS_FOR_ELR_DT
							  ,lruc.[USER_COMMENT_CREATED_BY] = lrucu.USER_COMMENT_CREATED_BY
							  ,lruc.[RECORD_STATUS_CD] = lrucu.RECORD_STATUS_CD
							  ,lruc.[LAB_TEST_UID] = lrucu.LAB_TEST_UID
							  ,lruc.[RDB_LAST_REFRESH_TIME] = lrucu.RDB_LAST_REFRESH_TIME
						  FROM rdb_modern.dbo.Lab_Rpt_User_Comment lruc, #LAB_RPT_USER_COMMENT_U lrucu
						  WHERE lruc.lab_test_uid = lrucu.lab_test_uid
						  ;

						  
			SELECT @RowCount_no = @@ROWCOUNT;
	
		    INSERT INTO [dbo].[job_flow_log]
                (batch_id,[Dataflow_Name],[package_Name] ,[Status_Type],[step_number],[step_name],[row_count])
                VALUES(@batch_id,'D_LAB_TEST','D_LAB_TEST','START',@Proc_Step_no,@Proc_Step_Name,@RowCount_no);


			COMMIT TRANSACTION;

			  IF OBJECT_ID('#s_edx_document1', 'U') IS NOT NULL 
			         drop table  #s_edx_document1;

			  IF OBJECT_ID('#LAB_TESTinit_a', 'U') IS NOT NULL 
			         drop table  #LAB_TESTinit_a;

			  IF OBJECT_ID('#s_edx_document', 'U') IS NOT NULL 
			         drop table  #s_edx_document;

			  IF OBJECT_ID('#LAB_TESTinit', 'U') IS NOT NULL 
			         drop table   #LAB_TESTinit;

			  IF OBJECT_ID('#LAB_TEST_mat_init', 'U') IS NOT NULL 
			         drop table  #LAB_TEST_mat_init;

			  IF OBJECT_ID('#OBS_REASON', 'U') IS NOT NULL 
			         drop table  #OBS_REASON;

			  IF OBJECT_ID('#OBS_REASON_FINAL', 'U') IS NOT NULL 
			         drop table  #OBS_REASON_FINAL ;

			  IF OBJECT_ID('#LAB_TEST_oth', 'U') IS NOT NULL 
			         drop table  #LAB_TEST_oth;

			  IF OBJECT_ID('#LAB_TEST1_uid', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_uid;

			  IF OBJECT_ID('#LAB_TEST1_TMP', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_TMP ;

			  IF OBJECT_ID('#LabReportMorb', 'U') IS NOT NULL 
			         drop table  #LabReportMorb;

			  IF OBJECT_ID('#Morb_OID', 'U') IS NOT NULL 
			         drop table  #Morb_OID ;

			  IF OBJECT_ID('#LAB_TEST1_uid2', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_uid2;

			  IF OBJECT_ID('#LAB_TEST1', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1 ;

			  IF OBJECT_ID('#R_Result_to_R_Order', 'U') IS NOT NULL 
			         drop table  #R_Result_to_R_Order;

			  IF OBJECT_ID('#R_Result_to_R_Order_to_Order', 'U') IS NOT NULL 
			         drop table   #R_Result_to_R_Order_to_Order;

			  IF OBJECT_ID('#LAB_TEST1_testuid', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_testuid;

			  IF OBJECT_ID('#LAB_TEST1_final', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_final;

			  IF OBJECT_ID('#R_Order_to_Result', 'U') IS NOT NULL 
			         drop table  #R_Order_to_Result;

			  IF OBJECT_ID('#LAB_TEST1_final_testuid', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_final_testuid;

			  IF OBJECT_ID('#LAB_TEST1_final_result', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_final_result;

			  IF OBJECT_ID('#Result_to_Order', 'U') IS NOT NULL 
			         drop table  #Result_to_Order;

			  IF OBJECT_ID('#LAB_TEST1_final_orderuid', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_final_orderuid;

			  IF OBJECT_ID('#LAB_TEST1_final_order', 'U') IS NOT NULL 
			         drop table  #LAB_TEST1_final_order;

			  IF OBJECT_ID('#LAB_TEST2', 'U') IS NOT NULL 
			         drop table  #LAB_TEST2 ;

			  IF OBJECT_ID('#LAB_TEST3', 'U') IS NOT NULL 
			         drop table  #LAB_TEST3;

			  IF OBJECT_ID('#LAB_TEST4', 'U') IS NOT NULL   
 			                     drop table  #LAB_TEST4 ;

			  IF OBJECT_ID('#order_test', 'U') IS NOT NULL   
 			                   drop table  #order_test ;

			  IF OBJECT_ID('#LAB_TEST', 'U') IS NOT NULL   
 		          	         drop table  #LAB_TEST ;

			  IF OBJECT_ID('#Merge_Order', 'U') IS NOT NULL 
			         drop table  #Merge_Order ;

			  IF OBJECT_ID('#LAB_TEST_final_root_ordered_test_pntr', 'U') IS NOT NULL 
			         drop table  #LAB_TEST_final_root_ordered_test_pntr;

			  IF OBJECT_ID('#LAB_TEST_final', 'U') IS NOT NULL 
			         drop table  #LAB_TEST_final ;

			  IF OBJECT_ID('#L_LAB_TEST_N', 'U') IS NOT NULL 
			         drop table  #L_LAB_TEST_N;

			  IF OBJECT_ID('#Lab_Rpt_User_Comment', 'U') IS NOT NULL 
			                      drop table  #Lab_Rpt_User_Comment;


            BEGIN TRANSACTION; 
			SET @PROC_STEP_NO =  @PROC_STEP_NO + 1 ;

			SET @Proc_Step_Name = 'SP_COMPLETE'; 


					INSERT INTO rdb.[dbo].[job_flow_log] (
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
						   'D_LAB_TEST'
						   ,'D_LAB_TEST'
						   ,'COMPLETE'
						   ,@Proc_Step_no
						   ,@Proc_Step_name
						   ,@RowCount_no
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


        INSERT INTO [dbo].[job_flow_log] (
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
                ,'D_LAB_TEST'
                ,'D_LAB_TEST'
                ,'ERROR'
                ,@Proc_Step_no
                ,'ERROR - '+ @Proc_Step_name
                , 'Step -' +CAST(@Proc_Step_no AS VARCHAR(3))+' -' +CAST(@ErrorMessage AS VARCHAR(500))
                ,0
            );


        return -1 ;

    END CATCH

END;
