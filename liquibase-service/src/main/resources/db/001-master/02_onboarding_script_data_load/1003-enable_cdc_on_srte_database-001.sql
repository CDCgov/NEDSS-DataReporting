--Use admin user created in 000-create_rtr_admin_user-001.sql
use nbs_srte;
if exists (select 1
           from sys.databases
           where name = 'rdsadmin') -- for aws
    begin

        if not exists (select 1 FROM sys.databases WHERE is_cdc_enabled = 1 and name = 'nbs_srte')
            begin
                exec msdb.dbo.rds_cdc_enable_db 'nbs_srte';
            end;
    end;
else
    begin
        exec sys.sp_cdc_enable_db 'nbs_srte'
    end;

select name, is_cdc_enabled
from sys.databases
where name = 'nbs_srte';