USE [NBS_ODSE];
DECLARE @superuser_id bigint = 10009282;

-- Use the same UIDs from step 1
DECLARE @patient_uid_2 bigint = 10014315;
DECLARE @investigation_uid bigint = 10014317;
DECLARE @interview_uid bigint = 10014318;

-- Derived local_id
DECLARE @interview_local_id nvarchar(40) = N'INT' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @interview_uid))) + N'GA01';

-- =====================================================================================
-- STEP 2: CREATE INTERVIEW
-- =====================================================================================

-- dbo.Act for interview
INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd])
VALUES (@interview_uid, N'IXS', N'EVN');

-- dbo.Interview
INSERT INTO [dbo].[Interview] (
    [interview_uid], [interview_status_cd], [interview_date], [interviewee_role_cd],
    [interview_type_cd], [interview_loc_cd], [local_id], [record_status_cd],
    [record_status_time], [add_time], [add_user_id], [last_chg_time],
    [last_chg_user_id], [version_ctrl_nbr]
)
VALUES (
    @interview_uid, N'COMPLETE', N'2026-04-18T00:00:00', N'SUBJECT', N'PRESMPTV', N'I',
    @interview_local_id, N'ACTIVE', N'2026-04-20T04:25:03.323', N'2026-04-20T04:25:03.320',
    @superuser_id, N'2026-04-20T04:25:03.323', @superuser_id, 1
);

-- =====================================================================================
-- STEP 3: CREATE INTERVIEW ANSWERS (including notes)
-- =====================================================================================

-- dbo.nbs_answer (contacts named indicator)
DECLARE @nbs_answer_uid bigint;
DECLARE @nbs_answer_uid_output TABLE ([value] bigint);

INSERT INTO [dbo].[nbs_answer] (
    [act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
    [seq_nbr], [record_status_cd], [record_status_time], [last_chg_time], [last_chg_user_id]
)
OUTPUT INSERTED.[nbs_answer_uid] INTO @nbs_answer_uid_output ([value])
VALUES (
    @interview_uid, N'N', 10001355, 3, 0, N'ACTIVE', N'2026-04-20T04:25:03.323',
    N'2026-04-20T04:25:03.323', @superuser_id
);

-- dbo.nbs_answer (note 1 - stored in a special format with tilde delimiters)
INSERT INTO [dbo].[nbs_answer] (
    [act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
    [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
    [last_chg_time], [last_chg_user_id]
)
OUTPUT INSERTED.[nbs_answer_uid] INTO @nbs_answer_uid_output ([value])
VALUES (
    @interview_uid, N'Ariella Kent~04/19/2026 21:24~~This is a note', 10001024, 3, 0, 1,
    N'ACTIVE', N'2026-04-20T04:25:03.323', N'2026-04-20T04:25:03.323', @superuser_id
);

-- dbo.nbs_answer (note 2)
INSERT INTO [dbo].[nbs_answer] (
    [act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
    [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
    [last_chg_time], [last_chg_user_id]
)
OUTPUT INSERTED.[nbs_answer_uid] INTO @nbs_answer_uid_output ([value])
VALUES (
    @interview_uid, N'Ariella Kent~04/19/2026 21:24~~This is another note! ', 10001024, 3, 0, 2,
    N'ACTIVE', N'2026-04-20T04:25:03.323', N'2026-04-20T04:25:03.323', @superuser_id
);

-- dbo.nbs_answer (note 3)
INSERT INTO [dbo].[nbs_answer] (
    [act_uid], [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
    [seq_nbr], [answer_group_seq_nbr], [record_status_cd], [record_status_time],
    [last_chg_time], [last_chg_user_id]
)
OUTPUT INSERTED.[nbs_answer_uid] INTO @nbs_answer_uid_output ([value])
VALUES (
    @interview_uid, N'Ariella Kent~04/19/2026 21:24~~Lorem ipsum dolor sit emet', 10001024, 3, 0, 3,
    N'ACTIVE', N'2026-04-20T04:25:03.323', N'2026-04-20T04:25:03.323', @superuser_id
);

-- =====================================================================================
-- STEP 4: LINK INTERVIEW TO INVESTIGATION AND ENTITIES
-- =====================================================================================

-- dbo.NBS_act_entity (interviewer)
INSERT INTO [dbo].[NBS_act_entity] (
    [act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr],
    [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]
)
VALUES (
    @interview_uid, N'2026-04-20T04:25:03.320', @superuser_id, 10003013, 1,
    N'2026-04-20T04:25:03.323', @superuser_id, N'ACTIVE', N'2026-04-20T04:25:03.323',
    N'IntrvwerOfInterview'
);

-- dbo.NBS_act_entity (interviewee)
INSERT INTO [dbo].[NBS_act_entity] (
    [act_uid], [add_time], [add_user_id], [entity_uid], [entity_version_ctrl_nbr],
    [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [type_cd]
)
VALUES (
    @interview_uid, N'2026-04-20T04:25:03.320', @superuser_id, @patient_uid_2, 1,
    N'2026-04-20T04:25:03.323', @superuser_id, N'ACTIVE', N'2026-04-20T04:25:03.323',
    N'IntrvweeOfInterview'
);

-- dbo.Participation (interviewer)
INSERT INTO [dbo].[Participation] (
    [subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id],
    [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
    [status_cd], [status_time], [subject_class_cd]
)
VALUES (
    10003013, @interview_uid, N'IntrvwerOfInterview', N'IXS', N'2026-04-20T04:25:03.327',
    @superuser_id, N'2026-04-20T04:25:03.327', @superuser_id, N'ACTIVE',
    N'2026-04-20T04:25:03.327', N'A', N'2026-04-20T04:25:03.327', N'PSN'
);

-- dbo.Participation (interviewee)
INSERT INTO [dbo].[Participation] (
    [subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id],
    [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
    [status_cd], [status_time], [subject_class_cd]
)
VALUES (
    @patient_uid_2, @interview_uid, N'IntrvweeOfInterview', N'IXS', N'2026-04-20T04:25:03.327',
    @superuser_id, N'2026-04-20T04:25:03.327', @superuser_id, N'ACTIVE',
    N'2026-04-20T04:25:03.327', N'A', N'2026-04-20T04:25:03.327', N'PSN'
);

-- dbo.Act_relationship (link interview to investigation)
INSERT INTO [dbo].[Act_relationship] (
    [target_act_uid], [source_act_uid], [type_cd], [add_reason_cd], [add_time],
    [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
    [source_class_cd], [status_cd], [status_time], [target_class_cd]
)
VALUES (
    @investigation_uid, @interview_uid, N'IXS', N'because', N'2026-04-20T04:25:03.437',
    N'2026-04-20T04:25:03.437', @superuser_id, N'ACTIVE', N'2026-04-20T04:25:03.437',
    N'OBS', N'A', N'2026-04-20T04:25:03.437', N'CASE'
);
