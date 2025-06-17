-- This script to be run outside of Automation as a one time admin user creation
-- Reset password of the login when the script is run
USE
[master]
IF NOT EXISTS (SELECT name
               FROM sys.server_principals
               WHERE name = 'db_deploy_admin')
BEGIN
        CREATE
LOGIN [db_deploy_admin] WITH PASSWORD =N'<to_be_reset_later>', DEFAULT_DATABASE = [master], DEFAULT_LANGUAGE = [us_english], CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;

        ALTER
SERVER ROLE [setupadmin] ADD MEMBER [db_deploy_admin];

        ALTER
SERVER ROLE [processadmin] ADD MEMBER [db_deploy_admin];

        GRANT ALTER
ANY CREDENTIAL TO [db_deploy_admin];

        GRANT ALTER
ANY LOGIN TO [db_deploy_admin];

        GRANT CREATE
ANY DATABASE TO [db_deploy_admin];

        GRANT VIEW
SERVER STATE TO [db_deploy_admin];

END

if
exists (select 1
           from sys.databases
           where name = 'rdsadmin') -- for aws
begin
        USE
msdb;

        IF
NOT EXISTS (SELECT name FROM master.sys.database_principals WHERE name = 'db_deploy_admin')
            CREATE
USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo];

GRANT EXECUTE ON msdb.dbo.rds_cdc_enable_db TO db_deploy_admin;

GRANT EXECUTE ON msdb.dbo.rds_cdc_disable_db TO db_deploy_admin;

end;
else
begin
        -- azure and onprem
        ALTER
SERVER ROLE [sysadmin] ADD MEMBER [db_deploy_admin]

        CREATE
USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]
        GRANT EXECUTE ON sys.sp_cdc_enable_db TO db_deploy_admin;
GRANT EXECUTE ON sys.sp_cdc_disable_db TO db_deploy_admin;
end;


USE
[RDB];

IF
NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
BEGIN
        CREATE
USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]
        ALTER
ROLE [db_owner] ADD MEMBER [db_deploy_admin]
END;

USE
[rdb_modern];

IF
NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
BEGIN
        CREATE
USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]

        ALTER
ROLE [db_owner] ADD MEMBER [db_deploy_admin]
END

USE
[nbs_odse];


IF
NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
BEGIN
        CREATE
USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]

        ALTER
ROLE [db_owner] ADD MEMBER [db_deploy_admin]
END;

USE
[nbs_srte];

IF
NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
BEGIN
        CREATE
USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]

        ALTER
ROLE [db_owner] ADD MEMBER [db_deploy_admin]
END;

USE
[nbs_msgoute]


IF NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
BEGIN
        CREATE
USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]


        ALTER
ROLE [db_owner] ADD MEMBER [db_deploy_admin]
end;


-- ALTER LOGIN db_deploy_admin with password ='<your new pass>';

--------------------------- VALIDATION for CDC -----------------------------
--------------------------- Create test database ---------------------------
/*create database test_cdc;

use test_cdc;
CREATE TABLE dbo.Act (
	act_uid bigint NOT NULL,
	class_cd varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	mood_cd varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CONSTRAINT PK__Act__76CBA758 PRIMARY KEY (act_uid)
);


insert into dbo.Act values(1,2,3);
insert into dbo.Act values(2,2,3);
insert into dbo.Act values(3,2,3);

*/
use
nbs_odse;
if
exists (select 1
           from sys.databases
           where name = 'rdsadmin') -- for aws
begin

        if
not exists (select 1 FROM sys.databases WHERE is_cdc_enabled = 1 and name = 'nbs_odse')
begin
exec msdb.dbo.rds_cdc_enable_db 'nbs_odse';
end;
end;
else
begin
exec sys.sp_cdc_enable_db 'nds_odse'
end;
select name, is_cdc_enabled
FROM sys.databases
WHERE name = 'nbs_odse' if not exists (SELECT name, is_tracked_by_cdc
               FROM sys.tables
               WHERE is_tracked_by_cdc = 1
                 and name = 'Act')
begin
exec sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Act', @role_name = NULL;
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

USE
[master];
IF
NOT EXISTS (SELECT name
               FROM sys.server_principals
               WHERE name = 'test_login2')
    CREATE
LOGIN [test_login2] WITH PASSWORD =N'test123', DEFAULT_DATABASE = [master], DEFAULT_LANGUAGE = [us_english], CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;


USE
[RDB];
IF
NOT EXISTS (SELECT name
               FROM sys.database_principals
               WHERE name = 'test_user2')
    CREATE
USER [test_user2] FOR LOGIN [test_login2] WITH DEFAULT_SCHEMA =[dbo];
ALTER
ROLE [db_owner] ADD MEMBER [test_user2];
ALTER
LOGIN test_login2 with password = 'test1234';