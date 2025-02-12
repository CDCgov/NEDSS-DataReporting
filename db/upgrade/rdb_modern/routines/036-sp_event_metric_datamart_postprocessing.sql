CREATE OR ALTER PROCEDURE dbo.sp_event_metric_datamart_postprocessing @phc_uids nvarchar(max),
    @obs_uids nvarchar(max),
    @notif_uids nvarchar(max),
    @ct_uids nvarchar(max),
    @debug bit = 'false'
    as

BEGIN

    DECLARE
@RowCount_no INT;
    DECLARE
@Proc_Step_no FLOAT = 0;
    DECLARE
@Proc_Step_Name VARCHAR(200) = '';
    DECLARE
@batch_id BIGINT;
    SET
@batch_id = cast((format(getdate(), 'yyyyMMddHHmmss')) as bigint);

    -- used in the logging statements
    DECLARE
@datamart_nm VARCHAR(100) = 'EVENT_METRIC_DATAMART';

BEGIN TRY

SET @Proc_Step_no = 1;
        SET
@Proc_Step_Name = 'SP_Start';

BEGIN
TRANSACTION;

INSERT INTO dbo.job_flow_log
( batch_id
, [Dataflow_Name]
, [package_Name]
, [Status_Type]
, [step_number]
, [step_name]
, [ row_count]
, [Msg_Description1])
VALUES ( @batch_id
           , @datamart_nm
           , @datamart_nm
           , 'START'
           , @Proc_Step_no
           , @Proc_Step_Name
           , 0
           , LEFT('ID List-' + @phc_uids, 500));

COMMIT TRANSACTION;

/*
Check for if id list is empty string, only do certain blocks if
id list is length > 0
*/

BEGIN
TRANSACTION;

        SET
@Proc_Step_name = 'Generating #TMP_EVENT_METRIC';
        SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;


        IF
OBJECT_ID('#TMP_EVENT_METRIC', 'U') IS NOT NULL
drop table #TMP_EVENT_METRIC;

SELECT [EVENT_TYPE],
    [EVENT_UID],
    [LOCAL_ID],
    [LOCAL_PATIENT_ID],
    [CONDITION_CD],
    [CONDITION_DESC_TXT],
    [PROG_AREA_CD],
    [PROG_AREA_DESC_TXT],
    [PROGRAM_JURISDICTION_OID],
    [JURISDICTION_CD],
    [JURISDICTION_DESC_TXT],
    [RECORD_STATUS_CD],
    [RECORD_STATUS_DESC_TXT],
    [RECORD_STATUS_TIME],
    [ELECTRONIC_IND],
    [STATUS_CD],
    [STATUS_DESC_TXT],
    [STATUS_TIME],
    [ADD_TIME],
    [ADD_USER_ID],
    [LAST_CHG_TIME],
    [LAST_CHG_USER_ID],
    [CASE_CLASS_CD],
    [CASE_CLASS_DESC_TXT],
    [INVESTIGATION_STATUS_CD],
    [INVESTIGATION_STATUS_DESC_TXT],
    [ADD_USER_NAME],
    [LAST_CHG_USER_NAME]
INTO #TMP_EVENT_METRIC
FROM dbo.EVENT_METRIC
WHERE 1 = 0;


COMMIT TRANSACTION;

IF
@notif_uids != ''
BEGIN
BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Generating #TMP_NOTIFICATION';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;


                IF
OBJECT_ID('#TMP_NOTIFICATION', 'U') IS NOT NULL
drop table #TMP_NOTIFICATION;

SELECT 'Notification'             as EVENT_TYPE,
       n.notification_uid         as EVENT_UID,
       n.notif_local_id           as LOCAL_ID,
       pat.local_id               as LOCAL_PATIENT_ID,
       n.prog_area_cd,
       n.program_jurisdiction_oid,
       n.jurisdiction_cd,
       n.notif_status             AS record_status_cd,
       n.record_status_time,
       n.status_time,
       n.notif_add_time           as add_time,
       n.notif_add_user_id        as add_user_id,
       n.notif_last_chg_time      as last_chg_time,
       n.notif_last_chg_user_id   as last_chg_user_id,
       N.notif_add_user_name      as add_user_name,
       N.notif_last_chg_user_name as last_chg_user_name
INTO #TMP_NOTIFICATION
FROM dbo.nrt_investigation_notification N
         LEFT JOIN dbo.nrt_investigation inv
                   ON N.public_health_case_uid = inv.public_health_case_uid
         LEFT JOIN dbo.nrt_patient pat
                   ON inv.patient_id = pat.patient_uid
WHERE N.notification_uid in (SELECT value
                             FROM STRING_SPLIT(@notif_uids, ','));

if
@debug = 'true'
select @Proc_Step_Name as step, *
from #TMP_NOTIFICATION;

SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;

BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Generating #TMP_NOT_PROG';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;


                IF
OBJECT_ID('#TMP_NOT_PROG', 'U') IS NOT NULL
drop table #TMP_NOT_PROG;

SELECT N.EVENT_TYPE,
       N.EVENT_UID,
       N.LOCAL_ID,
       N.LOCAL_PATIENT_ID,
       N.prog_area_cd,
       p.prog_area_desc_txt as PROG_AREA_DESC_TXT,
       N.program_jurisdiction_oid,
       N.jurisdiction_cd,
       N.record_status_cd,
       N.record_status_time,
       N.status_time,
       N.add_time,
       N.add_user_id,
       N.last_chg_time,
       N.last_chg_user_id,
       N.add_user_name,
       N.last_chg_user_name
INTO #TMP_NOT_PROG
FROM #TMP_NOTIFICATION N
         LEFT OUTER JOIN [NBS_SRTE].dbo.program_area_code p
with (nolock)
ON N.prog_area_cd = p.prog_area_cd;


if
@debug = 'true'
select @Proc_Step_Name as step, *
from #TMP_NOT_PROG;

SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;


BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Generating #TMP_NOT_PROG_JURI';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;


                IF
OBJECT_ID('#TMP_NOT_PROG_JURI', 'U') IS NOT NULL
drop table #TMP_NOT_PROG_JURI;

SELECT N.EVENT_TYPE,
       N.EVENT_UID,
       N.LOCAL_ID,
       N.LOCAL_PATIENT_ID,
       N.prog_area_cd,
       N.PROG_AREA_DESC_TXT,
       N.program_jurisdiction_oid,
       N.jurisdiction_cd,
       J.code_desc_txt as JURISDICTION_DESC_TXT,
       N.record_status_cd,
       N.record_status_time,
       N.status_time,
       N.add_time,
       N.add_user_id,
       N.last_chg_time,
       N.last_chg_user_id,
       N.add_user_name,
       N.last_chg_user_name
INTO #TMP_NOT_PROG_JURI
FROM #TMP_NOT_PROG N
         LEFT OUTER JOIN [NBS_SRTE].dbo.jurisdiction_code as J
with (nolock)
ON N.jurisdiction_cd = J.code;


if
@debug = 'true'
select @Proc_Step_Name as step, *
from #TMP_NOT_PROG_JURI;

SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;


BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Generating #TMP_NOT_PROG_JURI_CVG';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;


                IF
OBJECT_ID('#TMP_NOT_PROG_JURI_CVG', 'U') IS NOT NULL
drop table #TMP_NOT_PROG_JURI_CVG;

SELECT N.EVENT_TYPE,
       N.EVENT_UID,
       N.LOCAL_ID,
       N.LOCAL_PATIENT_ID,
       N.prog_area_cd,
       N.PROG_AREA_DESC_TXT,
       N.program_jurisdiction_oid,
       N.jurisdiction_cd,
       N.JURISDICTION_DESC_TXT,
       N.record_status_cd,
       C.CODE_DESC_TXT as RECORD_STATUS_DESC_TXT,
       N.record_status_time,
       N.status_time,
       N.add_time,
       N.add_user_id,
       N.last_chg_time,
       N.last_chg_user_id,
       N.add_user_name,
       N.last_chg_user_name
INTO #TMP_NOT_PROG_JURI_CVG
FROM #TMP_NOT_PROG_JURI N
         LEFT OUTER JOIN [NBS_SRTE].dbo.code_value_general as C
with (nolock)
on N.record_status_cd = C.code
    and c.code_set_nm = 'REC_STAT';


if
@debug = 'true'
select @Proc_Step_Name as step, *
from #TMP_NOT_PROG_JURI_CVG;

SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;


BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Inserting Notifications into #TMP_EVENT_METRIC';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;


INSERT INTO #TMP_EVENT_METRIC
SELECT N.EVENT_TYPE,
       N.EVENT_UID,
       N.LOCAL_ID,
       N.LOCAL_PATIENT_ID,
       NULL as CONDITION_CD,
       NULL as CONDITION_DESC_TXT,
       N.prog_area_cd,
       N.PROG_AREA_DESC_TXT,
       N.program_jurisdiction_oid,
       N.jurisdiction_cd,
       N.JURISDICTION_DESC_TXT,
       N.record_status_cd,
       N.RECORD_STATUS_DESC_TXT,
       N.record_status_time,
       NULL as electronic_ind,
       NULL as STATUS_CD,
       NULL as STATUS_DESC_TXT,
       N.status_time,
       N.add_time,
       N.add_user_id,
       N.last_chg_time,
       N.last_chg_user_id,
       NULL as CASE_CLASS_CD,
       NULL as CASE_CLASS_DESC_TXT,
       NULL as INVESTIGATION_STATUS_CD,
       NULL as INVESTIGATION_STATUS_DESC_TXT,
       N.add_user_name,
       N.last_chg_user_name
FROM #TMP_NOT_PROG_JURI_CVG N;


SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;
END;

        IF
@obs_uids != ''
BEGIN
BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Generating #TMP_EVENT_OBS';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;


                IF
OBJECT_ID('#TMP_EVENT_OBS', 'U') IS NOT NULL
drop table #TMP_EVENT_OBS;


SELECT NULL                AS EVENT_TYPE,
       o.observation_uid,
       o.local_id,
       pat.local_id        as Local_Patient_ID,
       CASE
           WHEN o.ctrl_cd_display_form = 'MorbReport' THEN o.cd
           ELSE NULL
           END             as Condition_cd,
       CASE
           WHEN o.ctrl_cd_display_form = 'MorbReport' THEN q.condition_short_nm
           ELSE NULL
           END             as Condition_desc_txt,
       o.prog_area_cd,
       p.prog_area_desc_txt,
       o.program_jurisdiction_oid,
       o.jurisdiction_cd,
       j.code_desc_txt     as Jurisdiction_DESC_TXT,
       o.record_status_cd,
       c.CODE_DESC_TXT     as Record_status_desc_txt,
       o.record_status_time,
       o.electronic_ind,
       o.STATUS_CD,
       cvgst.CODE_DESC_TXT as status_desc_txt,
       o.STATUS_TIME,
       o.add_time,
       o.add_user_id,
       o.last_chg_time,
       o.last_chg_user_id,
       NULL                AS case_class_cd,
       NULL                AS case_class_desc_txt,
       NULL                AS investigation_status_cd,
       NULL                AS investigation_status_desc_txt,
       o.ADD_USER_NAME,
       o.last_chg_user_name,
       o.obs_domain_cd_st_1,
       o.ctrl_cd_display_form
INTO #TMP_EVENT_OBS
FROM dbo.nrt_observation o
         LEFT OUTER JOIN [NBS_SRTE].dbo.program_area_code as p
with (nolock)
ON o.prog_area_cd = p.prog_area_cd
    LEFT OUTER JOIN [NBS_SRTE].dbo.jurisdiction_code as j
with (nolock)
ON o.jurisdiction_cd = j.code
    LEFT OUTER JOIN [NBS_SRTE].dbo.condition_code as q
with (nolock)
ON o.cd = q.condition_cd
    LEFT OUTER JOIN [NBS_SRTE].dbo.code_value_general as c
with (nolock)
ON o.record_status_cd = c.code AND
    c.code_set_nm = 'REC_STAT'
    left outer join [NBS_SRTE].dbo.code_value_general as cvgst
with (nolock)
ON o.status_cd = cvgst.code
    and cvgst.code_set_nm = 'ACT_OBJ_ST'
    LEFT JOIN dbo.nrt_patient pat
with (nolock)
ON pat.patient_uid = o.patient_id
WHERE o.observation_uid in (SELECT value
    FROM STRING_SPLIT(@obs_uids
    , ','));


if
@debug = 'true'
select @Proc_Step_Name as step, *
from #TMP_EVENT_OBS;

SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;


BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Inserting Non-ELR LabReports into #TMP_EVENT_METRIC';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;

INSERT INTO #TMP_EVENT_METRIC
SELECT 'LabReport',
       observation_uid,
       local_id,
       Local_Patient_ID,
       Condition_cd,
       Condition_desc_txt,
       prog_area_cd,
       prog_area_desc_txt,
       program_jurisdiction_oid,
       jurisdiction_cd,
       Jurisdiction_DESC_TXT,
       record_status_cd,
       Record_status_desc_txt,
       record_status_time,
       electronic_ind,
       STATUS_CD,
       status_desc_txt,
       STATUS_TIME,
       add_time,
       add_user_id,
       last_chg_time,
       last_chg_user_id,
       NULL,
       NULL,
       NULL,
       NULL,
       ADD_USER_NAME,
       last_chg_user_name
FROM #TMP_EVENT_OBS o
WHERE o.obs_domain_cd_st_1 = 'Order'
  AND o.ctrl_cd_display_form = 'LabReport'
  AND o.electronic_ind <> 'Y';

SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;

BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Inserting ELR LabReports into #TMP_EVENT_METRIC';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;

INSERT INTO #TMP_EVENT_METRIC
SELECT 'LabReport',
       observation_uid,
       local_id,
       Local_Patient_ID,
       Condition_cd,
       Condition_desc_txt,
       prog_area_cd,
       prog_area_desc_txt,
       program_jurisdiction_oid,
       jurisdiction_cd,
       Jurisdiction_DESC_TXT,
       record_status_cd,
       Record_status_desc_txt,
       record_status_time,
       electronic_ind,
       STATUS_CD,
       status_desc_txt,
       STATUS_TIME,
       add_time,
       add_user_id,
       last_chg_time,
       last_chg_user_id,
       NULL,
       NULL,
       NULL,
       NULL,
       ADD_USER_NAME,
       last_chg_user_name
FROM #TMP_EVENT_OBS o
WHERE o.obs_domain_cd_st_1 = 'Order'
  AND o.ctrl_cd_display_form = 'LabReport'
  AND o.electronic_ind = 'Y';

SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;

BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Inserting Morbidity Reports into #TMP_EVENT_METRIC';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;

INSERT INTO #TMP_EVENT_METRIC
SELECT 'MorbReport',
       observation_uid,
       local_id,
       Local_Patient_ID,
       Condition_cd,
       Condition_desc_txt,
       prog_area_cd,
       prog_area_desc_txt,
       program_jurisdiction_oid,
       jurisdiction_cd,
       Jurisdiction_DESC_TXT,
       record_status_cd,
       Record_status_desc_txt,
       record_status_time,
       electronic_ind,
       STATUS_CD,
       status_desc_txt,
       STATUS_TIME,
       add_time,
       add_user_id,
       last_chg_time,
       last_chg_user_id,
       NULL,
       NULL,
       NULL,
       NULL,
       ADD_USER_NAME,
       last_chg_user_name
FROM #TMP_EVENT_OBS o
WHERE o.obs_domain_cd_st_1 = 'Order'
  AND o.ctrl_cd_display_form = 'MorbReport';

SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;

END;

        IF
@phc_uids != ''
BEGIN
BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Inserting Public Health Cases into #TMP_EVENT_METRIC';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;


INSERT INTO #TMP_EVENT_METRIC
SELECT 'PHCInvForm'                                                              as Event_Type,
       phc.public_health_case_uid                                                as EVENT_UID,
       phc.local_id,
       pat.local_id                                                              as local_Patient_id,
       phc.cd                                                                    as Condition_Cd,
       phc.cd_desc_txt                                                           as Condition_desc_txt,
       phc.prog_area_cd,
       p.prog_area_desc_txt,
       phc.program_jurisdiction_oid,
       phc.jurisdiction_cd                                                       as Jurisdiction_cd,
       j.code_desc_txt                                                           as Jurisdiction_desc_txt,
       phc.raw_record_status_cd                                                  as record_status_cd,
       c.code_desc_txt                                                           as Record_status_desc_txt,
       phc.record_status_time,
       NULL                                                                      as electronic_ind,
       NULL                                                                      as status_cd,
       NULL                                                                      as status_desc_txt,
       phc.status_time,
       phc.add_time,
       phc.add_user_id,
       phc.last_chg_time,
       phc.last_chg_user_id,
       case when len(phc.case_class_cd) = 0 then NULL else phc.case_class_cd end as case_class_cd,
       d.code_short_desc_txt                                                     as case_class_desc_txt,
       phc.investigation_status_cd,
       e.code_desc_txt                                                           as investigation_status_desc_txt,
       phc.add_user_name,
       phc.last_chg_user_name
FROM dbo.nrt_investigation phc
         LEFT OUTER JOIN dbo.nrt_patient pat ON pat.patient_uid = phc.patient_id
         LEFT OUTER JOIN [NBS_SRTE].dbo.program_area_code p
with (nolock)
ON phc.prog_area_cd = p.prog_area_cd
    LEFT OUTER JOIN [NBS_SRTE].dbo.jurisdiction_code j
with (nolock)
ON phc.jurisdiction_cd = j.code
    LEFT OUTER JOIN [NBS_SRTE].dbo.code_value_general c
with (nolock)
ON phc.record_status_cd = c.code AND
    c.code_set_nm = 'REC_STAT'
    LEFT OUTER JOIN [NBS_SRTE].dbo.code_value_general d
with (nolock)
ON phc.case_class_cd = d.code AND
    d.code_set_nm = 'PHC_CLASS'
    LEFT OUTER JOIN [NBS_SRTE].dbo.code_value_general e
with (nolock)
ON phc.investigation_status_cd = e.code AND
    e.code_set_nm = 'PHC_IN_STS'
WHERE phc.public_health_case_uid in (SELECT value
    FROM STRING_SPLIT(@phc_uids
    , ','));;


SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;

END;


        IF
@ct_uids != ''
BEGIN
BEGIN
TRANSACTION;

                SET
@Proc_Step_name = 'Inserting CT_Contact Records into #TMP_EVENT_METRIC';
                SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;


INSERT INTO #TMP_EVENT_METRIC
SELECT 'CONTACT',
       ct.CONTACT_UID,
       ct.LOCAL_ID,
       pat.LOCAL_ID                                                  AS LOCAL_PATIENT_ID,
       NULL                                                          as Condition_cd,
       NULL                                                          as Condition_desc_txt,
       ct.PROG_AREA_CD,
       P.PROG_AREA_DESC_TXT,
       ct.PROGRAM_JURISDICTION_OID,
       ct.JURISDICTION_CD,
       J.CODE_DESC_TXT,
       ct.RECORD_STATUS_CD,
       C.CODE_DESC_TXT,
       ct.RECORD_STATUS_TIME,
       NULL,
       NULL,
       NULL,
       NULL,
       ct.ADD_TIME,
       ct.ADD_USER_ID,
       ct.LAST_CHG_TIME,
       ct.LAST_CHG_USER_ID,
       NULL,
       NULL,
       NULL,
       NULL,
       RTRIM(Ltrim(up1.last_nm)) + ', ' + RTRIM(Ltrim(up1.first_nm)) as ADD_USER_NAME,
       RTRIM(Ltrim(up2.last_nm)) + ', ' + RTRIM(Ltrim(up2.first_nm)) as LAST_CHG_USER_NAME
FROM dbo.nrt_contact ct
         LEFT JOIN dbo.nrt_patient pat
                   ON ct.subject_entity_uid = pat.patient_uid
         INNER JOIN [NBS_SRTE].dbo.PROGRAM_AREA_CODE AS P
with (nolock)
ON ct.PROG_AREA_CD = P.PROG_AREA_CD
    INNER JOIN [NBS_SRTE].dbo.JURISDICTION_CODE AS J
with (nolock)
ON ct.JURISDICTION_CD = J.CODE
    INNER JOIN [NBS_SRTE].dbo.CODE_VALUE_GENERAL C
with (nolock)
ON ct.RECORD_STATUS_CD = C.CODE AND C.CODE_SET_NM = 'REC_STAT'
    LEFT OUTER JOIN dbo.nrt_auth_user AS UP1
with (nolock)
ON ct.ADD_USER_ID = UP1.NEDSS_ENTRY_ID
    LEFT OUTER JOIN dbo.nrt_auth_user AS UP2
with (nolock)
ON ct.LAST_CHG_USER_ID = UP2.NEDSS_ENTRY_ID
WHERE ct.CONTACT_UID in (SELECT value
    FROM STRING_SPLIT(@ct_uids
    , ','));


SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;

END;

/*
    TO DO: Add vaccination data once intervention has been moved to NRT.
    (Leave this comment in until completed)
*/

BEGIN
TRANSACTION;

        SET
@Proc_Step_name = 'Generating #TMP_EVENT_METRIC_FINAL';
        SET
@PROC_STEP_NO = @PROC_STEP_NO + 1;

/*
    @lookback_days:

    This variable stores the maximum age in days of an event for it to be valid in EVENT_METRIC.
    All new records are inserted in EVENT_METRIC_INC, but if a record is too old, it is not valid
    for EVENT_METRIC. This value should be stored in an NRT table that mirrors NBS_ODSE.dbo.NBS_configuration.
    When this table is brought in, change this value to the result of a query that references whatever
    is in the aforementioned table as opposed to the hardcoded value.
*/
        DECLARE
@lookback_days BIGINT = 730;


        IF
OBJECT_ID('#TMP_EVENT_METRIC_FINAL', 'U') IS NOT NULL
drop table #TMP_EVENT_METRIC_FINAL;

SELECT TEM.[EVENT_TYPE],
       TEM.[EVENT_UID],
       TEM.[LOCAL_ID],
       TEM.[LOCAL_PATIENT_ID],
       TEM.[CONDITION_CD],
       TEM.[CONDITION_DESC_TXT],
       TEM.[PROG_AREA_CD],
       TEM.[PROG_AREA_DESC_TXT],
       TEM.[PROGRAM_JURISDICTION_OID],
       TEM.[JURISDICTION_CD],
       TEM.[JURISDICTION_DESC_TXT],
       TEM.[RECORD_STATUS_CD],
       TEM.[RECORD_STATUS_DESC_TXT],
       TEM.[RECORD_STATUS_TIME],
       TEM.[ELECTRONIC_IND],
       TEM.[STATUS_CD],
       TEM.[STATUS_DESC_TXT],
       TEM.[STATUS_TIME],
       TEM.[ADD_TIME],
       TEM.[ADD_USER_ID],
       TEM.[LAST_CHG_TIME],
       TEM.[LAST_CHG_USER_ID],
       TEM.[CASE_CLASS_CD],
       TEM.[CASE_CLASS_DESC_TXT],
       TEM.[INVESTIGATION_STATUS_CD],
       TEM.[INVESTIGATION_STATUS_DESC_TXT],
       TEM.[ADD_USER_NAME],
       TEM.[LAST_CHG_USER_NAME],
       CASE
           WHEN DATEDIFF(day, TEM.[ADD_TIME], GETDATE()) between 0 and @lookback_days THEN 1
           ELSE 0
           END AS CURRENT_FLAG,
       CASE
           WHEN (EM.[EVENT_UID] IS NULL AND EM.[EVENT_TYPE] IS NULL) THEN 'I'
           ELSE 'U'
           END AS DML_IND
INTO #TMP_EVENT_METRIC_FINAL
FROM #TMP_EVENT_METRIC TEM
         LEFT JOIN dbo.EVENT_METRIC_INC EM
                   ON EM.[EVENT_UID] = TEM.[EVENT_UID]
                       and EM.[EVENT_TYPE] = TEM.[EVENT_TYPE];

COMMIT TRANSACTION;

BEGIN
TRANSACTION
            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
@PROC_STEP_NAME = 'Update [dbo].[EVENT_METRIC_INC]';

UPDATE [dbo].[EVENT_METRIC_INC]

SET [EVENT_TYPE]=TEM.[EVENT_TYPE],
    [EVENT_UID]= TEM.[EVENT_UID],
    [LOCAL_ID] =TEM.[LOCAL_ID],
    [LOCAL_PATIENT_ID]=TEM.[LOCAL_PATIENT_ID],
    [CONDITION_CD]=TEM.[CONDITION_CD],
    [CONDITION_DESC_TXT]=TEM.[CONDITION_DESC_TXT],
    [PROG_AREA_CD]=TEM.[PROG_AREA_CD],
    [PROG_AREA_DESC_TXT]=TEM.[PROG_AREA_DESC_TXT],
    [PROGRAM_JURISDICTION_OID]=TEM.[PROGRAM_JURISDICTION_OID],
    [JURISDICTION_CD]=TEM.[JURISDICTION_CD],
    [JURISDICTION_DESC_TXT]=TEM.[JURISDICTION_DESC_TXT],
    [RECORD_STATUS_CD]=TEM.[RECORD_STATUS_CD],
    [RECORD_STATUS_DESC_TXT]=TEM.[RECORD_STATUS_DESC_TXT],
    [RECORD_STATUS_TIME]=TEM.[RECORD_STATUS_TIME],
    [ELECTRONIC_IND]=TEM.[ELECTRONIC_IND],
    [STATUS_CD]=TEM.[STATUS_CD],
    [STATUS_DESC_TXT]=TEM.[STATUS_DESC_TXT],
    [STATUS_TIME]=TEM.[STATUS_TIME],
    [ADD_TIME]=TEM.[ADD_TIME],
    [ADD_USER_ID]=TEM.[ADD_USER_ID],
    [LAST_CHG_TIME]=TEM.[LAST_CHG_TIME],
    [LAST_CHG_USER_ID]=TEM.[LAST_CHG_USER_ID],
    [CASE_CLASS_CD]=TEM.[CASE_CLASS_CD],
    [CASE_CLASS_DESC_TXT]=TEM.[CASE_CLASS_DESC_TXT],
    [INVESTIGATION_STATUS_CD]=TEM.[INVESTIGATION_STATUS_CD],
    [INVESTIGATION_STATUS_DESC_TXT]=TEM.[INVESTIGATION_STATUS_DESC_TXT],
    [ADD_USER_NAME]=TEM.[ADD_USER_NAME],
    [LAST_CHG_USER_NAME]=TEM.[LAST_CHG_USER_NAME]
FROM #TMP_EVENT_METRIC_FINAL TEM
WHERE TEM.DML_IND = 'U'
  and TEM.[EVENT_UID] = [dbo].[EVENT_METRIC_INC].[EVENT_UID]
  and TEM.[EVENT_TYPE] = [dbo].[EVENT_METRIC_INC].[EVENT_TYPE]


SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;


BEGIN
TRANSACTION
            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
@PROC_STEP_NAME = 'INSERTING INTO EVENT METRIC_INC';


INSERT INTO dbo.EVENT_METRIC_INC
([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [CONDITION_CD], [CONDITION_DESC_TXT],
    [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [PROGRAM_JURISDICTION_OID], [JURISDICTION_CD],
    [JURISDICTION_DESC_TXT],
    [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ELECTRONIC_IND], [STATUS_CD],
    [STATUS_DESC_TXT], [STATUS_TIME], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID],
    [CASE_CLASS_CD], [CASE_CLASS_DESC_TXT], [INVESTIGATION_STATUS_CD], [INVESTIGATION_STATUS_DESC_TXT],
    [ADD_USER_NAME], [LAST_CHG_USER_NAME])


SELECT TEM.[EVENT_TYPE],
       TEM.[EVENT_UID],
       TEM.[LOCAL_ID],
       TEM.[LOCAL_PATIENT_ID],
       TEM.[CONDITION_CD],
       TEM.[CONDITION_DESC_TXT],
       TEM.[PROG_AREA_CD],
       TEM.[PROG_AREA_DESC_TXT],
       TEM.[PROGRAM_JURISDICTION_OID],
       TEM.[JURISDICTION_CD],
       TEM.[JURISDICTION_DESC_TXT],
       TEM.[RECORD_STATUS_CD],
       TEM.[RECORD_STATUS_DESC_TXT],
       TEM.[RECORD_STATUS_TIME],
       TEM.[ELECTRONIC_IND],
       TEM.[STATUS_CD],
       TEM.[STATUS_DESC_TXT],
       TEM.[STATUS_TIME],
    [ADD_TIME],
    TEM.[ADD_USER_ID],
    TEM.[LAST_CHG_TIME],
    TEM.[LAST_CHG_USER_ID],
    TEM.[CASE_CLASS_CD],
    TEM.[CASE_CLASS_DESC_TXT],
    TEM.[INVESTIGATION_STATUS_CD],
    TEM.[INVESTIGATION_STATUS_DESC_TXT],
    TEM.[ADD_USER_NAME],
    TEM.[LAST_CHG_USER_NAME]

FROM #TMP_EVENT_METRIC_FINAL TEM
WHERE TEM.DML_IND = 'I'


SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;

BEGIN
TRANSACTION
            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
@PROC_STEP_NAME = 'Update [dbo].[EVENT_METRIC]';

UPDATE [dbo].[EVENT_METRIC]

SET [EVENT_TYPE]=TEM.[EVENT_TYPE],
    [EVENT_UID]= TEM.[EVENT_UID],
    [LOCAL_ID] =TEM.[LOCAL_ID],
    [LOCAL_PATIENT_ID]=TEM.[LOCAL_PATIENT_ID],
    [CONDITION_CD]=TEM.[CONDITION_CD],
    [CONDITION_DESC_TXT]=TEM.[CONDITION_DESC_TXT],
    [PROG_AREA_CD]=TEM.[PROG_AREA_CD],
    [PROG_AREA_DESC_TXT]=TEM.[PROG_AREA_DESC_TXT],
    [PROGRAM_JURISDICTION_OID]=TEM.[PROGRAM_JURISDICTION_OID],
    [JURISDICTION_CD]=TEM.[JURISDICTION_CD],
    [JURISDICTION_DESC_TXT]=TEM.[JURISDICTION_DESC_TXT],
    [RECORD_STATUS_CD]=TEM.[RECORD_STATUS_CD],
    [RECORD_STATUS_DESC_TXT]=TEM.[RECORD_STATUS_DESC_TXT],
    [RECORD_STATUS_TIME]=TEM.[RECORD_STATUS_TIME],
    [ELECTRONIC_IND]=TEM.[ELECTRONIC_IND],
    [STATUS_CD]=TEM.[STATUS_CD],
    [STATUS_DESC_TXT]=TEM.[STATUS_DESC_TXT],
    [STATUS_TIME]=TEM.[STATUS_TIME],
    [ADD_TIME]=TEM.[ADD_TIME],
    [ADD_USER_ID]=TEM.[ADD_USER_ID],
    [LAST_CHG_TIME]=TEM.[LAST_CHG_TIME],
    [LAST_CHG_USER_ID]=TEM.[LAST_CHG_USER_ID],
    [CASE_CLASS_CD]=TEM.[CASE_CLASS_CD],
    [CASE_CLASS_DESC_TXT]=TEM.[CASE_CLASS_DESC_TXT],
    [INVESTIGATION_STATUS_CD]=TEM.[INVESTIGATION_STATUS_CD],
    [INVESTIGATION_STATUS_DESC_TXT]=TEM.[INVESTIGATION_STATUS_DESC_TXT],
    [ADD_USER_NAME]=TEM.[ADD_USER_NAME],
    [LAST_CHG_USER_NAME]=TEM.[LAST_CHG_USER_NAME]
FROM #TMP_EVENT_METRIC_FINAL TEM
WHERE TEM.DML_IND = 'U'
  and TEM.[EVENT_UID] = [dbo].[EVENT_METRIC].[EVENT_UID]
  and TEM.[EVENT_TYPE] = [dbo].[EVENT_METRIC].[EVENT_TYPE]


SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;


BEGIN
TRANSACTION
            SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
            SET
@PROC_STEP_NAME = 'INSERTING INTO EVENT_METRIC';

INSERT INTO dbo.EVENT_METRIC
([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [CONDITION_CD], [CONDITION_DESC_TXT],
    [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [PROGRAM_JURISDICTION_OID], [JURISDICTION_CD],
    [JURISDICTION_DESC_TXT],
    [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ELECTRONIC_IND], [STATUS_CD],
    [STATUS_DESC_TXT], [STATUS_TIME], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID],
    [CASE_CLASS_CD], [CASE_CLASS_DESC_TXT], [INVESTIGATION_STATUS_CD], [INVESTIGATION_STATUS_DESC_TXT],
    [ADD_USER_NAME], [LAST_CHG_USER_NAME])


SELECT TEM.[EVENT_TYPE],
       TEM.[EVENT_UID],
       TEM.[LOCAL_ID],
       TEM.[LOCAL_PATIENT_ID],
       TEM.[CONDITION_CD],
       TEM.[CONDITION_DESC_TXT],
       TEM.[PROG_AREA_CD],
       TEM.[PROG_AREA_DESC_TXT],
       TEM.[PROGRAM_JURISDICTION_OID],
       TEM.[JURISDICTION_CD],
       TEM.[JURISDICTION_DESC_TXT],
       TEM.[RECORD_STATUS_CD],
       TEM.[RECORD_STATUS_DESC_TXT],
       TEM.[RECORD_STATUS_TIME],
       TEM.[ELECTRONIC_IND],
       TEM.[STATUS_CD],
       TEM.[STATUS_DESC_TXT],
       TEM.[STATUS_TIME],
    [ADD_TIME],
    TEM.[ADD_USER_ID],
    TEM.[LAST_CHG_TIME],
    TEM.[LAST_CHG_USER_ID],
    TEM.[CASE_CLASS_CD],
    TEM.[CASE_CLASS_DESC_TXT],
    TEM.[INVESTIGATION_STATUS_CD],
    TEM.[INVESTIGATION_STATUS_DESC_TXT],
    TEM.[ADD_USER_NAME],
    TEM.[LAST_CHG_USER_NAME]


FROM #TMP_EVENT_METRIC_FINAL TEM
WHERE TEM.DML_IND = 'I'
  AND TEM.CURRENT_FLAG = 1;

SELECT @RowCount_no = @@ROWCOUNT;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no);

COMMIT TRANSACTION;

INSERT INTO [dbo].[job_flow_log]
(batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count])
VALUES (@batch_id, @datamart_nm, @datamart_nm, 'COMPLETE', 999, 'COMPLETE', 0);


END TRY
BEGIN CATCH


IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;


        DECLARE
@ErrorNumber INT = ERROR_NUMBER();
        DECLARE
@ErrorLine INT = ERROR_LINE();
        DECLARE
@ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE
@ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE
@ErrorState INT = ERROR_STATE();


INSERT INTO [dbo].[job_flow_log]
( batch_id
    , [Dataflow_Name]
    , [package_Name]
    , [Status_Type]
    , [step_number]
    , [step_name]
    , [Error_Description]
    , [row_count])
VALUES ( @batch_id
        , @datamart_nm
        , @datamart_nm
        , 'ERROR'
        , @Proc_Step_no
        , 'ERROR - ' + @Proc_Step_name
        , 'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
        , 0);


return -1;

END CATCH

END;
