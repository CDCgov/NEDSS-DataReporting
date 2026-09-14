USE [NBS_ODSE];

UPDATE [dbo].[Person]
SET [last_nm] = N'StaleUpdate',
    [last_chg_time] = N'2026-08-19T00:01:00.000',
    [version_ctrl_nbr] = 2
WHERE [person_uid] = 1000014000;

UPDATE [dbo].[Person_name]
SET [last_nm] = N'StaleUpdate',
    [last_chg_time] = N'2026-08-19T00:01:00.000'
WHERE [person_uid] = 1000014000;
