IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_public_health_case_fact_datamart_update]')
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_public_health_case_fact_datamart_update]
END
GO

CREATE PROCEDURE dbo.sp_public_health_case_fact_datamart_update @obj_nm varchar(20), @uid_list nvarchar(max), @debug bit = 'false'
AS
BEGIN
    declare @rowcount bigint;
    declare @dataflow_name varchar(200) = 'NBS_ODSE.PublicHealthCaseFact Update: ' + @obj_nm;
    declare @package_name varchar(200) = 'PCHMartETL';
    declare @proc_step_no float = 0;
    declare @proc_step_name varchar(200) = 'SP_Start';
    declare @batch_id bigint;
    set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint);

    BEGIN TRY

        INSERT INTO [dbo].[job_flow_log]
        (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES
            (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,LEFT(@uid_list,500),0);

        SELECT value AS ENTITY_UID
        INTO #TMP_ENTITY
        FROM STRING_SPLIT(@uid_list, ',')

        IF @obj_nm = 'PAT'
            BEGIN
                SET @proc_step_no = @proc_step_no + 1;
                SET @proc_step_name = 'Generating #TMP_MPR_UPDATE';

                SELECT PHC.public_health_case_uid
                     ,MPR.MULTIPLE_BIRTH_IND
                     ,MPR.OCCUPATION_CD
                     ,MPR.PRIM_LANG_CD
                     ,MPR.ADULTS_IN_HOUSE_NBR
                     ,MPR.BIRTH_GENDER_CD
                     ,MPR.BIRTH_ORDER_NBR
                     ,MPR.CHILDREN_IN_HOUSE_NBR
                     ,MPR.EDUCATION_LEVEL_CD
                     ,CVG.CODE_SHORT_DESC_TXT AS EDUCATION_LEVEL_DESC_TXT
                     ,MPR.LAST_CHG_TIME AS MPR_LAST_CHG_TIME
                INTO #TMP_MPR_UPDATE
                FROM NBS_ODSE.DBO.PERSON PER WITH (NOLOCK)
                    INNER JOIN NBS_ODSE.DBO.PARTICIPATION PAR WITH (NOLOCK) ON PER.PERSON_UID = PAR.SUBJECT_ENTITY_UID
                    INNER JOIN NBS_ODSE.DBO.Public_health_case PHC WITH (NOLOCK) ON PAR.act_uid = PHC.public_health_case_uid
                    INNER JOIN NBS_ODSE.DBO.PERSON MPR WITH (NOLOCK) ON PER.PERSON_PARENT_UID = MPR.PERSON_UID
                    LEFT OUTER JOIN NBS_SRTE.DBO.CODE_VALUE_GENERAL CVG WITH (NOLOCK)
                        ON MPR.EDUCATION_LEVEL_CD = CVG.CODE AND CVG.CODE_SET_NM = 'P_EDUC_LVL'
                WHERE PAR.TYPE_CD = 'SUBJOFPHC' AND MPR.PERSON_UID IN (SELECT ENTITY_UID FROM #TMP_ENTITY)

                if @debug = 'true' select '#TMP_MPR_UPDATE', * from #TMP_MPR_UPDATE;

                SET @rowcount = @@ROWCOUNT;

                INSERT INTO [dbo].[job_flow_log]
                    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
                VALUES
                    (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

                SET @proc_step_no = @proc_step_no + 1;
                SET @proc_step_name = 'Updating NBS_ODSE..PublicHealthCaseFact';

                BEGIN TRANSACTION;

                UPDATE NBS_ODSE.dbo.PublicHealthCaseFact
                SET multiple_birth_ind       = tmp.MULTIPLE_BIRTH_IND,
                    occupation_cd            = tmp.OCCUPATION_CD,
                    prim_lang_cd             = tmp.PRIM_LANG_CD,
                    adults_in_house_nbr      = tmp.ADULTS_IN_HOUSE_NBR,
                    birth_gender_cd          = tmp.BIRTH_GENDER_CD,
                    birth_order_nbr          = tmp.BIRTH_ORDER_NBR,
                    children_in_house_nbr    = tmp.CHILDREN_IN_HOUSE_NBR,
                    education_level_cd       = tmp.EDUCATION_LEVEL_CD,
                    education_level_desc_txt = tmp.EDUCATION_LEVEL_DESC_TXT
                FROM #TMP_MPR_UPDATE tmp
                WHERE tmp.public_health_case_uid = NBS_ODSE.dbo.PublicHealthCaseFact.public_health_case_uid;

                SET @rowcount = @@ROWCOUNT;

                INSERT INTO [dbo].[job_flow_log]
                    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
                VALUES
                    (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

                COMMIT TRANSACTION;

           END
        ELSE IF @obj_nm = 'PRV'
           BEGIN
               SET @proc_step_no = @proc_step_no + 1;
               SET @proc_step_name = 'Generating #TMP_PHC_PRV';

               SELECT PAR.ACT_UID
                    ,TYPE_CD
                    ,P.PERSON_UID
                    ,PAR.FROM_TIME
               INTO #TMP_PHC_PRV
               FROM NBS_ODSE.DBO.PARTICIPATION AS PAR WITH (NOLOCK)
                   INNER JOIN NBS_ODSE.DBO.PERSON AS P WITH (NOLOCK) ON P.PERSON_UID = PAR.SUBJECT_ENTITY_UID
                   INNER JOIN NBS_ODSE.DBO.Public_health_case AS PHC WITH (NOLOCK) ON PAR.act_uid = PHC.public_health_case_uid
               WHERE PAR.TYPE_CD IN ('InvestgrOfPHC', 'PerAsReporterOfPHC', 'PhysicianOfPHC', 'OrgAsReporterOfPHC')
                 AND P.PERSON_UID IN (SELECT ENTITY_UID FROM #TMP_ENTITY)

               if @debug = 'true' select '#TMP_PHC_PRV', * from #TMP_PHC_PRV;

               SET @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
               (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

               SET @proc_step_no = @proc_step_no + 1;
               SET @proc_step_name = 'Generating #TMP_PRV_DATA';

               SELECT P.PERSON_UID, PNM.NAME, TEL.PHONE_NBR_TXT
               INTO #TMP_PRV_DATA
               FROM NBS_ODSE.DBO.PERSON AS P WITH (NOLOCK)
                   LEFT JOIN (
                   select PERSON_UID, NAME, isnull(RECORD_STATUS_CD, 'ACTIVE') as RECORD_STATUS_CD, NM_USE_CD
                   from (
                            select PERSON_UID, isnull(RTRIM(LTRIM(LAST_NM)), '') + ', ' + isnull(FIRST_NM, '') AS NAME, NM_USE_CD,
                                   RECORD_STATUS_CD, LAST_CHG_TIME, ROW_NUMBER() OVER(partition by PERSON_UID ORDER BY last_chg_time desc ) AS rnum
                            from NBS_ODSE.DBO.PERSON_NAME WITH (NOLOCK) ) t
                   where rnum=1 ) PNM ON PNM.PERSON_UID = P.PERSON_UID AND PNM.NM_USE_CD = 'L' AND PNM.RECORD_STATUS_CD = 'ACTIVE'
                   LEFT JOIN NBS_ODSE.DBO.ENTITY_LOCATOR_PARTICIPATION AS ELP WITH (NOLOCK)
                       ON ELP.ENTITY_UID = P.PERSON_UID
                              AND ELP.CLASS_CD = 'TELE'
                              AND ELP.USE_CD = 'WP'
                              AND ELP.CD = 'PH'
                              AND ELP.RECORD_STATUS_CD = 'ACTIVE'
                   LEFT JOIN NBS_ODSE.DBO.TELE_LOCATOR AS TEL WITH (NOLOCK) ON ELP.LOCATOR_UID = TEL.TELE_LOCATOR_UID
               WHERE P.PERSON_UID IN (SELECT ENTITY_UID FROM #TMP_ENTITY)

               if @debug = 'true' select '#TMP_PRV_DATA', * from #TMP_PRV_DATA;

               SET @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
               (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

               SET @proc_step_no = @proc_step_no + 1;
               SET @proc_step_name = 'Generating #TMP_PRV_UPDATE';

               SELECT ACT_UID
                    ,PROVIDERNAME             = MAX(CASE WHEN TYPE_CD = 'PhysicianOfPHC' THEN NAME END)
                    ,PROVIDERPHONE            = MAX(CASE WHEN TYPE_CD = 'PhysicianOfPHC' THEN PHONE_NBR_TXT END)
                    ,REPORTERNAME             = MAX(CASE WHEN TYPE_CD = 'PerAsReporterOfPHC' THEN NAME END)
                    ,REPORTERPHONE            = MAX(CASE WHEN TYPE_CD = 'PerAsReporterOfPHC' THEN PHONE_NBR_TXT END)
                    ,INVESTIGATORNAME         = MAX(CASE WHEN TYPE_CD = 'InvestgrOfPHC' THEN NAME END)
                    ,INVESTIGATORPHONE        = MAX(CASE WHEN TYPE_CD = 'InvestgrOfPHC' THEN PHONE_NBR_TXT END)
                    ,INVESTIGATORASSIGNEDDATE = MAX(CASE WHEN TYPE_CD = 'InvestgrOfPHC' THEN FROM_TIME END)
                    ,ORGANIZATIONNAME         = MAX(CASE WHEN TYPE_CD = 'OrgAsReporterOfPHC' THEN NAME END)
               INTO #TMP_PRV_UPDATE
               FROM #TMP_PHC_PRV WITH (NOLOCK)
               LEFT JOIN #TMP_PRV_DATA WITH (NOLOCK) ON #TMP_PHC_PRV.PERSON_UID = #TMP_PRV_DATA.PERSON_UID
               GROUP BY ACT_UID

               if @debug = 'true' select '#TMP_PRV_UPDATE', * from #TMP_PRV_UPDATE;

               SET @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
               (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

               SET @proc_step_no = @proc_step_no + 1;
               SET @proc_step_name = 'Updating NBS_ODSE..PublicHealthCaseFact';

               BEGIN TRANSACTION;

               UPDATE NBS_ODSE.dbo.PublicHealthCaseFact
               SET providerName = tmp.PROVIDERNAME,
                   providerPhone = tmp.PROVIDERPHONE,
                   reporterName = tmp.REPORTERNAME,
                   reporterPhone = tmp.REPORTERPHONE,
                   investigatorName = tmp.INVESTIGATORNAME,
                   investigatorPhone = tmp.INVESTIGATORPHONE,
                   investigatorAssignedDate = tmp.INVESTIGATORASSIGNEDDATE,
                   organizationName = tmp.ORGANIZATIONNAME
               FROM #TMP_PRV_UPDATE tmp
               WHERE tmp.ACT_UID = NBS_ODSE.dbo.PublicHealthCaseFact.public_health_case_uid;

               SET @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
               (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

               COMMIT TRANSACTION;
           END
        ELSE IF @obj_nm = 'ORG'
           BEGIN
               SET @proc_step_no = @proc_step_no + 1;
               SET @proc_step_name = 'Generating #TMP_PHC_ORG';

               SELECT PAR.ACT_UID
                    ,ORG.ORGANIZATION_UID
                    ,ORG.NM_TXT AS NAME
               INTO #TMP_PHC_ORG
               FROM NBS_ODSE.DBO.PARTICIPATION AS PAR WITH (NOLOCK)
                   INNER JOIN NBS_ODSE.DBO.Public_health_case AS PHC WITH (NOLOCK) ON PAR.act_uid = PHC.public_health_case_uid
                   INNER JOIN NBS_ODSE.DBO.ORGANIZATION_NAME AS ORG WITH (NOLOCK) ON ORG.ORGANIZATION_UID = PAR.SUBJECT_ENTITY_UID
               WHERE PAR.TYPE_CD = 'OrgAsReporterOfPHC'
                 AND ORG.ORGANIZATION_UID IN (SELECT ENTITY_UID FROM #TMP_ENTITY)

               if @debug = 'true' select '#TMP_PHC_ORG', * from #TMP_PHC_ORG;

               SET @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
               (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

               SET @proc_step_no = @proc_step_no + 1;
               SET @proc_step_name = 'Updating NBS_ODSE..PublicHealthCaseFact';

               BEGIN TRANSACTION;

               UPDATE NBS_ODSE.dbo.PublicHealthCaseFact
               SET organizationName = tmp.NAME
               FROM #TMP_PHC_ORG tmp
               WHERE tmp.ACT_UID = NBS_ODSE.dbo.PublicHealthCaseFact.public_health_case_uid;

               SET @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
                   (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

               COMMIT TRANSACTION;
           END
        ELSE IF @obj_nm = 'NOTF'
           BEGIN

               SET @proc_step_no = @proc_step_no + 1;
               SET @proc_step_name = 'Generating #TMP_LATEST_NOT';

               SELECT TARGET_ACT_UID AS PUBLIC_HEALTH_CASE_UID
                    ,ar.SOURCE_ACT_UID
                    ,SOURCE_CLASS_CD
                    ,NF.RECORD_STATUS_CD AS NOTIFCURRENTSTATE
                    ,NF.txt
                    ,NF.local_id AS NOTIFICATION_LOCAL_ID
               INTO #TMP_LATEST_NOT
               FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
                  ,NBS_ODSE.DBO.NOTIFICATION NF WITH (NOLOCK)
               WHERE AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
                 AND SOURCE_CLASS_CD = 'NOTF'
                 AND TARGET_CLASS_CD = 'CASE'
                 AND (
                   NF.RECORD_STATUS_CD = 'COMPLETED'
                       OR NF.RECORD_STATUS_CD = 'PEND_APPR'
                       OR NF.RECORD_STATUS_CD = 'APPROVED'
                   )
                 AND  AR.SOURCE_ACT_UID IN (SELECT ENTITY_UID FROM #TMP_ENTITY WITH (NOLOCK))

               if @debug = 'true' Select '#TMP_LATEST_NOT', * from #TMP_LATEST_NOT;

               SET @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
               (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;


               SET @proc_step_no = @Proc_Step_no + 1;
               SET @proc_step_name = 'Generating #TMP_NOTIFICATION';

               SELECT DISTINCT TARGET_ACT_UID AS PUBLIC_HEALTH_CASE_UID
                             ,TARGET_CLASS_CD
                             ,SOURCE_ACT_UID
                             ,SOURCE_CLASS_CD
                             ,NF.VERSION_CTRL_NBR
                             ,NF.ADD_TIME
                             ,NF.ADD_USER_ID
                             ,NF.RPT_SENT_TIME
                             ,NF.RECORD_STATUS_CD
                             ,NF.RECORD_STATUS_TIME
                             ,NF.LAST_CHG_TIME
                             ,NF.LAST_CHG_USER_ID
                             ,'Y' AS HIST_IND
                             , NF.txt
                             ,CAST(NULL AS INT) AS NOTIFSENTCOUNT
                             ,CAST(NULL AS INT) AS NOTIFREJECTEDCOUNT
                             ,CAST(NULL AS INT) AS NOTIFCREATEDCOUNT
                             ,CAST(NULL AS INT) AS X1
                             ,CAST(NULL AS INT) AS X2
                             ,CAST(NULL AS DATETIME) AS FIRSTNOTIFICATIONSENDDATE
                             ,CAST(NULL AS DATETIME) AS NOTIFICATIONDATE
               INTO #TMP_NOTIFICATION
               FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
                   INNER JOIN NBS_ODSE.DBO.NOTIFICATION_HIST NF WITH (NOLOCK) ON AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
               WHERE SOURCE_CLASS_CD = 'NOTF'
                 AND TARGET_CLASS_CD = 'CASE'
                 AND NF.CD='NOTF'
                 AND (
                   NF.RECORD_STATUS_CD = 'COMPLETED'
                       OR NF.RECORD_STATUS_CD = 'MSG_FAIL'
                       OR NF.RECORD_STATUS_CD = 'REJECTED'
                       OR NF.RECORD_STATUS_CD = 'PEND_APPR'
                       OR NF.RECORD_STATUS_CD = 'APPROVED'
                   )
                 AND AR.SOURCE_ACT_UID IN (SELECT ENTITY_UID FROM #TMP_ENTITY WITH (NOLOCK))

               UNION

               SELECT TARGET_ACT_UID
                    ,TARGET_CLASS_CD
                    ,SOURCE_ACT_UID
                    ,SOURCE_CLASS_CD
                    ,NF.VERSION_CTRL_NBR
                    ,NF.ADD_TIME
                    ,NF.ADD_USER_ID
                    ,NF.RPT_SENT_TIME
                    ,NF.RECORD_STATUS_CD
                    ,NF.RECORD_STATUS_TIME
                    ,NF.LAST_CHG_TIME
                    ,NF.LAST_CHG_USER_ID
                    ,'N' AS HIST_IND
                    , NULL AS TXT
                    ,CAST(NULL AS INT) AS NOTIFSENTCOUNT
                    ,CAST(NULL AS INT) AS NOTIFREJECTEDCOUNT
                    ,CAST(NULL AS INT) AS NOTIFCREATEDCOUNT
                    ,CAST(NULL AS INT) AS X1
                    ,CAST(NULL AS INT) AS X2
                    ,CAST(NULL AS DATETIME) AS FIRSTNOTIFICATIONSENDDATE
                    ,CAST(NULL AS DATETIME) AS NOTIFICATIONDATE
               FROM NBS_ODSE.DBO.ACT_RELATIONSHIP AR WITH (NOLOCK)
                  ,NBS_ODSE.DBO.NOTIFICATION NF WITH (NOLOCK)
               WHERE AR.SOURCE_ACT_UID = NF.NOTIFICATION_UID
                 AND SOURCE_CLASS_CD = 'NOTF'
                 AND TARGET_CLASS_CD = 'CASE'
                 AND NF.CD='NOTF'
                 AND (
                   NF.RECORD_STATUS_CD = 'COMPLETED'
                       OR NF.RECORD_STATUS_CD = 'MSG_FAIL'
                       OR NF.RECORD_STATUS_CD = 'REJECTED'
                       OR NF.RECORD_STATUS_CD = 'PEND_APPR'
                       OR NF.RECORD_STATUS_CD = 'APPROVED'
                   )
                 and AR.SOURCE_ACT_UID IN (SELECT ENTITY_UID FROM #TMP_ENTITY WITH (NOLOCK))
               ORDER BY SOURCE_ACT_UID, LAST_CHG_TIME;

               if @debug = 'true' Select '#TMP_NOTIFICATION', * from #TMP_NOTIFICATION;

               SELECT @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
                   (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

               SET @proc_step_no = @Proc_Step_no + 1;
               SET @proc_step_name = 'Generating #TMP_MIN_MAX_NOTIFICATION';

               WITH orderedHist AS(
                   SELECT
                       PUBLIC_HEALTH_CASE_UID
                        ,TARGET_CLASS_CD
                        ,SOURCE_ACT_UID
                        ,SOURCE_CLASS_CD
                        ,VERSION_CTRL_NBR
                        ,ADD_TIME
                        ,ADD_USER_ID
                        ,RPT_SENT_TIME
                        ,RECORD_STATUS_CD
                        ,RECORD_STATUS_TIME
                        ,LAST_CHG_TIME
                        ,LAST_CHG_USER_ID
                        ,HIST_IND
                        ,TXT
                        ,NOTIFSENTCOUNT
                        ,NOTIFREJECTEDCOUNT
                        ,NOTIFCREATEDCOUNT
                        ,X1
                        ,X2
                        ,FIRSTNOTIFICATIONSENDDATE
                        ,NOTIFICATIONDATE
                        ,ROW_NUMBER() OVER (PARTITION BY PUBLIC_HEALTH_CASE_UID ORDER BY VERSION_CTRL_NBR DESC) notif_latest_rownum
                   FROM #TMP_NOTIFICATION
               )
               SELECT DISTINCT
                   MIN(CASE
                           WHEN VERSION_CTRL_NBR = 1 THEN RECORD_STATUS_CD
                       END) AS FIRSTNOTIFICATIONSTATUS,
                   SUM(CASE
                           WHEN RECORD_STATUS_CD = 'REJECTED' THEN 1 ELSE 0
                       END) AS NOTIFREJECTEDCOUNT,
                   SUM(CASE
                           WHEN RECORD_STATUS_CD = 'APPROVED' OR RECORD_STATUS_CD = 'PEND_APPR' THEN 1
                           WHEN RECORD_STATUS_CD = 'REJECTED' THEN -1 ELSE 0
                       END) AS NOTIFCREATEDCOUNT,
                   SUM(CASE
                           WHEN RECORD_STATUS_CD = 'COMPLETED' THEN 1 ELSE 0
                       END) AS NOTIFSENTCOUNT,
                   MIN(CASE
                           WHEN RECORD_STATUS_CD = 'COMPLETED' THEN RPT_SENT_TIME
                       END) AS FIRSTNOTIFICATIONSENDDATE,
                   SUM(CASE
                           WHEN RECORD_STATUS_CD = 'PEND_APPR' THEN 1 ELSE 0
                       END) AS NOTIFCREATEDPENDINGSCOUNT,
                   MAX(CASE
                           WHEN RECORD_STATUS_CD = 'APPROVED' OR RECORD_STATUS_CD = 'PEND_APPR' THEN LAST_CHG_TIME
                       END) AS LASTNOTIFICATIONDATE,
                             --DONE?
                   MAX(CASE
                           WHEN RECORD_STATUS_CD = 'COMPLETED' THEN RPT_SENT_TIME
                       END) AS LASTNOTIFICATIONSENDDATE,
                             --DONE?
                   MIN(ADD_TIME) AS FIRSTNOTIFICATIONDATE,
                             --DONE
                   NULLIF(MAX(CASE
                                  WHEN VERSION_CTRL_NBR != 1 THEN -1
                                  ELSE ADD_USER_ID
                              END), -1) AS FIRSTNOTIFICATIONSUBMITTEDBY,
                             --DONE
                   NULLIF(MAX(CASE
                                  WHEN notif_latest_rownum != 1 THEN -1
                                  ELSE LAST_CHG_USER_ID
                              END), -1) AS LASTNOTIFICATIONSUBMITTEDBY,
                             --DONE
                   MIN(CASE
                           WHEN RECORD_STATUS_CD = 'COMPLETED' AND RPT_SENT_TIME IS NOT NULL
                           THEN RPT_SENT_TIME
                      END) AS NOTIFICATIONDATE,
                   PUBLIC_HEALTH_CASE_UID
               INTO #TMP_MIN_MAX_NOTIFICATION
               FROM orderedHist WITH (NOLOCK)
               GROUP BY PUBLIC_HEALTH_CASE_UID;

               UPDATE #TMP_MIN_MAX_NOTIFICATION set NOTIFCREATEDCOUNT = NOTIFCREATEDCOUNT-1 where NOTIFCREATEDPENDINGSCOUNT>0 and NOTIFCREATEDCOUNT>0;
               UPDATE #TMP_MIN_MAX_NOTIFICATION set NOTIFCREATEDCOUNT = 1 where NOTIFCREATEDPENDINGSCOUNT>0 and NOTIFCREATEDCOUNT=0 and NOTIFREJECTEDCOUNT=0;

               if @debug = 'true' Select '#TMP_MIN_MAX_NOTIFICATION', * from #TMP_MIN_MAX_NOTIFICATION;

               SELECT @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
               (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;


               SET @proc_step_no = @Proc_Step_no + 1;
               SET @proc_step_name = 'Generating #TMP_SUB_CASE_NOTIF';

               SELECT DISTINCT tn.PUBLIC_HEALTH_CASE_UID
                             ,NOTIFCREATEDCOUNT
                             ,NOTIFSENTCOUNT
                             ,NOTIFICATIONDATE
                             ,FIRSTNOTIFICATIONSTATUS
                             ,FIRSTNOTIFICATIONSENDDATE
                             ,LASTNOTIFICATIONDATE
                             ,LASTNOTIFICATIONSENDDATE
                             ,FIRSTNOTIFICATIONDATE
                             ,FIRSTNOTIFICATIONSUBMITTEDBY
                             ,LASTNOTIFICATIONSUBMITTEDBY
                             ,t.TXT AS NOTITXT
                             ,t.NOTIFICATION_LOCAL_ID
                             ,t.NOTIFCURRENTSTATE
               INTO #TMP_SUB_CASE_NOTIF
               FROM #TMP_MIN_MAX_NOTIFICATION tn WITH (NOLOCK)
                    LEFT JOIN #TMP_LATEST_NOT t WITH (NOLOCK) ON t.PUBLIC_HEALTH_CASE_UID = tn.PUBLIC_HEALTH_CASE_UID;

               if @debug = 'true' Select '#TMP_SUB_CASE_NOTIF', * from #TMP_SUB_CASE_NOTIF;

               SELECT @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
               (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;


               SET @proc_step_no = @proc_step_no + 1;
               SET @proc_step_name = 'Updating NBS_ODSE..PublicHealthCaseFact';

               BEGIN TRANSACTION;

               UPDATE NBS_ODSE.dbo.PublicHealthCaseFact
               SET notifCreatedCount            = tmp.NOTIFCREATEDCOUNT,
                   notifSentCount               = tmp.NOTIFSENTCOUNT,
                   notificationdate             = tmp.NOTIFICATIONDATE,
                   firstNotificationStatus      = tmp.FIRSTNOTIFICATIONSTATUS,
                   firstNotificationdate        = tmp.FIRSTNOTIFICATIONDATE,
                   firstNotificationSenddate    = tmp.FIRSTNOTIFICATIONSENDDATE,
                   lastNotificationdate         = tmp.LASTNOTIFICATIONDATE,
                   lastNotificationSenddate     = tmp.LASTNOTIFICATIONSENDDATE,
                   firstNotificationSubmittedBy = tmp.FIRSTNOTIFICATIONSUBMITTEDBY,
                   lastNotificationSubmittedBy  = tmp.LASTNOTIFICATIONSUBMITTEDBY,
                   NOTITXT                      = tmp.NOTITXT,
                   NOTIFICATION_LOCAL_ID        = tmp.NOTIFICATION_LOCAL_ID,
                   NOTIFCURRENTSTATE            = tmp.NOTIFCURRENTSTATE
               FROM #TMP_SUB_CASE_NOTIF tmp
               WHERE tmp.PUBLIC_HEALTH_CASE_UID = NBS_ODSE.dbo.PublicHealthCaseFact.public_health_case_uid;

               SELECT @rowcount = @@ROWCOUNT;

               INSERT INTO [dbo].[job_flow_log]
               (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
               VALUES
                   (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,@rowcount);;

               COMMIT TRANSACTION;
           END


        SET @proc_step_no = 999;
        SET @proc_step_name = 'SP_Complete';
        SELECT @rowcount = 0;

        INSERT INTO [dbo].[job_flow_log]
            (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[msg_description1],[row_count])
        VALUES
            (@batch_id,@dataflow_name,@package_name,'COMPLETED',@proc_step_no,@proc_step_name,LEFT(@uid_list,500),@rowcount);;

    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log] (
                                              batch_id
                                            ,[Dataflow_Name]
                                            ,[package_Name]
                                            ,[Status_Type]
                                            ,[step_number]
                                            ,[step_name]
                                            ,[Error_Description]
                                            ,[row_count]
                                            ,[Msg_Description1]
        )
        VALUES (
                 @batch_id
               ,'PCHMartETL'
               ,'PCHMartETL'
               ,'ERROR'
               ,@Proc_Step_no
               ,@Proc_Step_name
               ,@FullErrorMessage
               ,0
               ,LEFT(@uid_list, 199)
               );

        RETURN @FullErrorMessage;
    END CATCH

END
