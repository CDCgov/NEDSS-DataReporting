USE [NBS_ODSE];

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @superuser_id bigint = 10009282;
DECLARE @dbo_Entity_entity_uid bigint = 1000013000;
DECLARE @dbo_Person_local_id varchar(50) = N'PRV1000013000GA01';

-- dbo.Entity
INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd])
VALUES (@dbo_Entity_entity_uid, N'PSN');

-- dbo.Person (cd = 'PRV' marks this Person row as a Provider)
INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [cd_desc_txt], [first_nm], [last_nm], [middle_nm],
    [record_status_cd], [record_status_time], [status_cd], [status_time],
    [local_id], [version_ctrl_nbr], [electronic_ind], [person_parent_uid]
)
VALUES (
    @dbo_Entity_entity_uid, N'2026-07-01T00:00:00.000', @superuser_id, N'2026-07-01T00:00:00.000', @superuser_id,
    N'PRV', N'Provider', N'Grace', N'Hopper', NULL,
    N'ACTIVE', N'2026-07-01T00:00:00.000', N'A', N'2026-07-01T00:00:00.000',
    @dbo_Person_local_id, 1, N'Y', @dbo_Entity_entity_uid
);

-- dbo.Person_name (sp_provider_event sources first/last name from here, not from dbo.Person)
-- No middle name yet, and no phone/email/address on the entity yet -- step 020 adds those.
INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [first_nm], [last_nm], [middle_nm],
    [nm_use_cd], [record_status_cd], [record_status_time], [status_cd], [status_time], [last_chg_time]
)
VALUES (
    @dbo_Entity_entity_uid, 1, N'Grace', N'Hopper', NULL,
    N'L', N'ACTIVE', N'2026-07-01T00:00:00.000', N'A', N'2026-07-01T00:00:00.000', N'2026-07-01T00:00:00.000'
);
