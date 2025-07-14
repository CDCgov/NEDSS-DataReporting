--Use admin user created in 000-create_rtr_admin_user-001.sql
use nbs_odse;
if exists (select 1
           from sys.databases
           where name = 'rdsadmin') -- for aws
    begin

        if not exists (select 1 FROM sys.databases WHERE is_cdc_enabled = 1 and name = 'nbs_odse')
            begin
                exec msdb.dbo.rds_cdc_enable_db 'nbs_odse';
            end;
    end;
else
    begin
        exec sys.sp_cdc_enable_db 'nbs_odse'
    end;
select name, is_cdc_enabled
FROM sys.databases
WHERE name = 'nbs_odse';


if not exists (SELECT name, is_tracked_by_cdc
               FROM sys.tables
               WHERE is_tracked_by_cdc = 1
                 and name = 'Act')
    begin
        exec sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Act', @role_name = NULL;
    end;

SELECT name, is_tracked_by_cdc
FROM sys.tables
WHERE is_tracked_by_cdc = 1;