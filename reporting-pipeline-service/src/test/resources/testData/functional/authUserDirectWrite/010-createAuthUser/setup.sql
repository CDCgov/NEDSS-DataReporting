USE [NBS_ODSE];

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @superuser_id bigint = 10009282;
DECLARE @dbo_Auth_user_auth_user_uid bigint = 1000012000;
DECLARE @dbo_Auth_user_nedss_entry_id bigint = 1000012000;

-- dbo.Auth_user
SET IDENTITY_INSERT [dbo].[Auth_user] ON;
INSERT INTO [dbo].[Auth_user] (
    [auth_user_uid], [user_id], [user_first_nm], [user_last_nm], [nedss_entry_id],
    [provider_uid], [add_user_id], [last_chg_user_id], [add_time], [last_chg_time],
    [record_status_cd], [record_status_time]
)
VALUES (
    @dbo_Auth_user_auth_user_uid, N'ada.lovelace', N'Ada', N'Lovelace', @dbo_Auth_user_nedss_entry_id,
    NULL, @superuser_id, @superuser_id, N'2026-07-01T00:00:00.000', N'2026-07-01T00:00:00.000',
    N'ACTIVE', N'2026-07-01T00:00:00.000'
);
SET IDENTITY_INSERT [dbo].[Auth_user] OFF;
