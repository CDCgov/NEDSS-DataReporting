USE [NBS_ODSE];

DECLARE @superuser_id bigint = 10009282;
DECLARE @patient_uid bigint = 1000014000;
DECLARE @patient_local_id nvarchar(40) = N'PSN1000014000GA01';

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd])
VALUES (@patient_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [cd_desc_txt], [first_nm], [last_nm], [middle_nm],
    [record_status_cd], [record_status_time], [status_cd], [status_time],
    [local_id], [version_ctrl_nbr], [electronic_ind], [person_parent_uid]
)
VALUES (
    @patient_uid, N'2026-08-19T00:00:00.000', @superuser_id, N'2026-08-19T00:00:00.000', @superuser_id,
    N'PAT', N'Patient', N'Delayed', N'Patient', NULL,
    N'ACTIVE', N'2026-08-19T00:00:00.000', N'A', N'2026-08-19T00:00:00.000',
    @patient_local_id, 1, N'Y', @patient_uid
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [first_nm], [last_nm], [middle_nm],
    [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [last_chg_time]
)
VALUES (
    @patient_uid, 1, N'Delayed', N'Patient', NULL,
    N'L', N'ACTIVE', N'2026-08-19T00:00:00.000', N'A', N'2026-08-19T00:00:00.000', N'2026-08-19T00:00:00.000'
);
