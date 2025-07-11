--Use admin user created in 1002-enable_cdc_on_odse_database.sql
use nbs_srte;
if exists (select 1
           from sys.databases
           where name = 'rdsadmin') -- for aws
    begin

        if not exists (select 1 FROM sys.databases WHERE is_cdc_enabled = 1 and name = 'nbs_odse')
            begin
                exec msdb.dbo.rds_cdc_enable_db 'nbs_srte';
            end;
    end;
else
    begin
        exec sys.sp_cdc_enable_db 'nbs_srte'
    end;

select name, is_cdc_enabled
FROM sys.databases
WHERE name = 'nbs_srte';


if not exists (SELECT name, is_tracked_by_cdc
               FROM sys.tables
               WHERE is_tracked_by_cdc = 1
                 and name = 'Condition_code')
    begin
        exec sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Condition_code', @role_name = NULL;
    end;

SELECT name, is_tracked_by_cdc
FROM sys.tables
WHERE is_tracked_by_cdc = 1;
/*

if  exists (select 1   FROM sys.databases  WHERE is_cdc_enabled = 1 and name ='test_cdc')
begin
	exec msdb.dbo.rds_cdc_disable_db 'test_cdc';

end;

	select name,is_cdc_enabled  FROM sys.databases  WHERE is_cdc_enabled = 0 and name = 'test_cdc' ;
if  exists (SELECT name FROM sys.tables WHERE is_tracked_by_cdc = 1 and name = 'Act')
begin
	exec sys.sp_cdc_disable_table @source_schema = N'dbo',@source_name = N'Act',@capture_instance = 'all';
end;
	SELECT * FROM sys.tables WHERE is_tracked_by_cdc = 0 and name = 'Act';


*/

USE [master];
IF NOT EXISTS (SELECT name
               FROM sys.server_principals
               WHERE name = 'test_login2')
CREATE LOGIN [test_login2] WITH PASSWORD =N'test123', DEFAULT_DATABASE = [master], DEFAULT_LANGUAGE = [us_english], CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;


USE [RDB];
IF NOT EXISTS (SELECT name
               FROM sys.database_principals
               WHERE name = 'test_user2')
CREATE USER [test_user2] FOR LOGIN [test_login2] WITH DEFAULT_SCHEMA =[dbo];
ALTER ROLE [db_owner] ADD MEMBER [test_user2];
ALTER LOGIN test_login2 with password = 'test1234';