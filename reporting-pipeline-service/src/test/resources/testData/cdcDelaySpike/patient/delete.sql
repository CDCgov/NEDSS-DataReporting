USE [NBS_ODSE];

DELETE FROM [dbo].[Person_name]
WHERE [person_uid] = 1000014000;

DELETE FROM [dbo].[Person]
WHERE [person_uid] = 1000014000;
