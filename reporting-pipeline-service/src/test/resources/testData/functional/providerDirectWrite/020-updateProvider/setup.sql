USE [NBS_ODSE];

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_Entity_entity_uid bigint = 1000013000;
DECLARE @dbo_Tele_locator_tele_locator_uid_email bigint = 1000013001;

-- Add a middle name to the provider created in 010-createProvider
UPDATE [dbo].[Person_name]
SET [middle_nm] = N'Brewster', [last_chg_time] = N'2026-07-01T01:00:00.000'
WHERE [person_uid] = @dbo_Entity_entity_uid AND [person_name_seq] = 1;

-- Add a work email (contact info)
INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [email_address], [record_status_cd], [record_status_time])
VALUES (@dbo_Tele_locator_tele_locator_uid_email, N'grace.hopper@navy.mil', N'ACTIVE', N'2026-07-01T01:00:00.000');

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [class_cd], [cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
)
VALUES (
    @dbo_Entity_entity_uid, @dbo_Tele_locator_tele_locator_uid_email, N'TELE', N'O', N'WP',
    N'ACTIVE', N'2026-07-01T01:00:00.000', N'A', 1
);

-- dbo.Person_name/Tele_locator/Entity_locator_participation are not captured by Debezium CDC directly;
-- touch dbo.Person (which is captured) to trigger PersonService to reprocess this provider with the new data.
UPDATE [dbo].[Person]
SET [last_chg_time] = N'2026-07-01T01:00:00.000'
WHERE [person_uid] = @dbo_Entity_entity_uid;
