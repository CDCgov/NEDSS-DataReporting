-- Query 0: Verify D_INTERVIEW was created
SELECT
    [D_INTERVIEW_KEY],
    [IX_STATUS_CD],
    [IX_DATE],
    [IX_INTERVIEWEE_ROLE_CD],
    [IX_TYPE_CD],
    [IX_LOCATION_CD],
    [LOCAL_ID],
    [RECORD_STATUS_CD],
    [IX_STATUS],
    [IX_INTERVIEWEE_ROLE],
    [IX_TYPE],
    [IX_LOCATION],
    [IX_CONTACTS_NAMED_IND]
FROM [RDB_MODERN].[dbo].[D_INTERVIEW]
WHERE [LOCAL_ID] = 'INT10014318GA01';

-- Query 1: Verify nrt_interview was created
SELECT
    [interview_uid],
    [interview_status_cd],
    [interview_date],
    [interviewee_role_cd],
    [interview_type_cd],
    [interview_loc_cd],
    [local_id],
    [record_status_cd],
    [ix_status],
    [ix_interviewee_role],
    [ix_type],
    [ix_location],
    [investigation_uid],
    [provider_uid],
    [patient_uid]
FROM [RDB_MODERN].[dbo].[nrt_interview]
WHERE [local_id] = 'INT10014318GA01';

-- Query 2: Verify D_INTERVIEW_NOTE entries were created (ordered by note key)
SELECT
    [D_INTERVIEW_KEY],
    [D_INTERVIEW_NOTE_KEY],
    [USER_FIRST_NAME],
    [USER_LAST_NAME],
    [USER_COMMENT],
    [COMMENT_DATE]
FROM [RDB_MODERN].[dbo].[D_INTERVIEW_NOTE]
WHERE [D_INTERVIEW_KEY] IN (
    SELECT [D_INTERVIEW_KEY] FROM [RDB_MODERN].[dbo].[D_INTERVIEW] WHERE [LOCAL_ID] = 'INT10014318GA01'
)
ORDER BY [D_INTERVIEW_NOTE_KEY];

-- Query 3: Verify nrt_interview_note entries were created (ordered by answer uid)
SELECT
    [interview_uid],
    [user_first_name],
    [user_last_name],
    [user_comment],
    [comment_date],
    [record_status_cd]
FROM [RDB_MODERN].[dbo].[nrt_interview_note]
WHERE [interview_uid] = 10014318
ORDER BY [nbs_answer_uid];

-- Query 4: Verify F_INTERVIEW_CASE was created
SELECT
    [D_INTERVIEW_KEY],
    [PATIENT_KEY],
    [IX_INTERVIEWER_KEY],
    [INVESTIGATION_KEY]
FROM [RDB_MODERN].[dbo].[F_INTERVIEW_CASE]
WHERE [D_INTERVIEW_KEY] IN (
    SELECT [D_INTERVIEW_KEY] FROM [RDB_MODERN].[dbo].[D_INTERVIEW] WHERE [LOCAL_ID] = 'INT10014318GA01'
);

-- Query 5: Verify nrt_interview_answer was created
SELECT
    [interview_uid],
    [rdb_column_nm],
    [answer_val]
FROM [RDB_MODERN].[dbo].[nrt_interview_answer]
WHERE [interview_uid] = 10014318;
