IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_delete_job_log' and xtype = 'U')
   BEGIN
        CREATE TABLE [dbo].[nrt_delete_job_log](
            RUN_ID              BIGINT IDENTITY(1,1)    NOT NULL,
            RUN_START_DTTM      DATETIME                NULL,
            RUN_END_DTTM        DATETIME                NULL,
            RUN_STATUS          varchar(50)             NULL
            ); 

        SET IDENTITY_INSERT [dbo].nrt_delete_job_log ON;

        INSERT INTO dbo.nrt_delete_job_log(
            RUN_ID,
            RUN_START_DTTM,
            RUN_END_DTTM,
            RUN_STATUS
        )
        SELECT
            1,
            GETDATE(),
            GETDATE(),
            'Initial';

        SET IDENTITY_INSERT [dbo].nrt_delete_job_log OFF;

        DBCC CHECKIDENT ('[dbo].nrt_delete_job_log', RESEED, 2);
   END;
