IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_backfill' and xtype = 'U')
    BEGIN

        CREATE TABLE [dbo].nrt_backfill (
            record_key  bigint IDENTITY(1,1) NOT NULL,
            entity varchar(256)        NULL,
            record_uid_list nvarchar(max)   NULL,
            batch_id bigint                 NULL,
            err_description varchar(1000)   NULL,
            status_cd varchar(256)          NULL,
            retry_count smallint            NULL,
            created_dttm datetime2 DEFAULT getdate(),
            updated_dttm datetime2 DEFAULT getdate()
        );
    END