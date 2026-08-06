IF
    EXISTS (
        SELECT *
        FROM sysobjects
        WHERE
            id = object_id(N'[dbo].[sp_add_job_flow_log]')
            AND objectproperty(id, N'IsProcedure') = 1
    )
    BEGIN
        DROP PROCEDURE [dbo].[sp_add_job_flow_log]
    END
GO

CREATE PROCEDURE dbo.sp_add_job_flow_log
    @batch_id BIGINT,
    @dataflow_name VARCHAR(199),
    @package_name VARCHAR(199),
    @status_type VARCHAR(500),
    @step_number FLOAT,
    @step_name VARCHAR(199),
    @row_count INT,
    @msg_description1 NVARCHAR(500) = NULL,
    @error_description NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.job_flow_log
    (
        batch_id,
        dataflow_name,
        package_name,
        status_type,
        step_number,
        step_name,
        row_count,
        msg_description1,
        error_description
    )
    VALUES
    (
        @batch_id,
        @dataflow_name,
        @package_name,
        @status_type,
        @step_number,
        @step_name,
        @row_count,
        @msg_description1,
        @error_description
    );
END
GO
