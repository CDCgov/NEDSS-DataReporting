USE msdb;
GO

DECLARE
    @JobName NVARCHAR(128) = N'EventMetricCleanup',
    @StepName NVARCHAR(128) = N'RunEventMetricCleanupProcedure',
    /*
        NOTE:

        This schedule is not to be applied to any other job. Otherwise,
        there may be issue if this script is run a second time.
    */
    @ScheduleName NVARCHAR(128) = N'EventMetricCleanupSchedule',
    @ProcName NVARCHAR(256) = N'sp_event_metric_cleanup_postprocessing',
    @ServerName NVARCHAR(128) = N'(LOCAL)', -- (LOCAL) is a reference to the server running the script
    @JobDescription NVARCHAR(512) = N'Event Metric Cleanup Job';

    DECLARE @DatabaseName NVARCHAR(128);
    IF EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV' AND config_value ='UAT')
        BEGIN
            SET @DatabaseName = N'rdb_modern'
        END
    ELSE
        BEGIN
            SET @DatabaseName = N'rdb'
        END

DECLARE @JobCommand NVARCHAR(MAX);
SET @JobCommand = N'EXEC ' + QUOTENAME(@DatabaseName) + N'.dbo.' + QUOTENAME(@ProcName) + N';';
-------------------------------------------------------------------------------------
-- Step 0: Drop existing job (which also removes associated steps and schedules)
-------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @JobName)
    BEGIN
        -- If the schedule attached to the job is orphaned after the job is deleted,
        -- the schedule will also be deleted
        EXEC sp_delete_job @job_name = @JobName, @delete_unused_schedule = 1;
    END

-- Drop schedule separately in case it's not tied to only this job

CREATE TABLE #ScheduleInfo (
	schedule_id INT,
	schedule_uid UNIQUEIDENTIFIER,
	name NVARCHAR(128),
	enabled TINYINT,
	freq_type TINYINT,
	freq_interval INT,
	freq_subday_type TINYINT,
	freq_subday_interval INT,
	freq_relative_interval TINYINT,
	freq_recurrence_factor INT,
	active_start_date INT,
	active_end_date INT,
	active_start_time INT,
	active_end_time INT,
	date_created DATETIME,
	schedule_description NVARCHAR(512),
	job_count INT
);

INSERT INTO #ScheduleInfo
EXEC msdb.dbo.sp_help_schedule;

DECLARE @sql NVARCHAR(MAX);

SELECT @sql = STRING_AGG(CAST('
EXEC msdb.dbo.sp_delete_schedule @schedule_id = ' + CAST(schedule_id AS NVARCHAR(10)) + ';
' AS NVARCHAR(MAX)), CHAR(13) + CHAR(10))
FROM #ScheduleInfo
WHERE name = @ScheduleName;

EXEC sp_executesql @sql;

-------------------------------------------------------------------------------------
-- Step 1: Create the Job
-------------------------------------------------------------------------------------
EXEC sp_add_job
     @job_name = @JobName,
     @enabled = 1,
     @description = @JobDescription;

-------------------------------------------------------------------------------------
-- Step 2: Add a Job Step to run the stored procedure
-------------------------------------------------------------------------------------
EXEC sp_add_jobstep
     @job_name = @JobName,
     @step_name = @StepName,
     @subsystem = N'TSQL',
     @command = @JobCommand,
     @database_name = @DatabaseName,
     @on_success_action = 1,
     @on_fail_action = 2;

-------------------------------------------------------------------------------------
-- Step 3: Create a Schedule to run daily at midnight
-------------------------------------------------------------------------------------
EXEC sp_add_schedule
     @schedule_name = @ScheduleName,
     @freq_type = 4,              -- Daily
     @freq_interval = 1,          -- Every 1 day
     @active_start_time = 000000, -- Midnight
     @enabled = 1;

-------------------------------------------------------------------------------------
-- Step 4: Attach the Schedule to the Job
-------------------------------------------------------------------------------------
EXEC sp_attach_schedule
     @job_name = @JobName,
     @schedule_name = @ScheduleName;

-------------------------------------------------------------------------------------
-- Step 5: Add the job to SQL Server Agent
-------------------------------------------------------------------------------------
EXEC sp_add_jobserver
     @job_name = @JobName,
     @server_name = @ServerName;