IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_delete_job_log' and xtype = 'U')
   BEGIN
        CREATE TABLE [dbo].[nrt_delete_job_log](
            RUN_ID              BIGINT IDENTITY(1,1)    NOT NULL,
            RUN_START_DTTM      DATETIME                NULL,
            RUN_END_DTTM        DATETIME                NULL,
            RUN_STATUS          varchar(50)             NULL
            ); 

        INSERT INTO dbo.nrt_delete_job_log(
            RUN_START_DTTM,
            RUN_END_DTTM,
            RUN_STATUS
        )
        SELECT
            GETDATE(),
            GETDATE(),
            'Initial';

   END;
