IF EXISTS (
    SELECT *
    FROM sysobjects
    WHERE id = object_id(N'[dbo].[sp_add_job_flow_log]')
      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_add_job_flow_log]
END
GO

CREATE PROCEDURE dbo.sp_add_job_flow_log
    @batch_id BIGINT,
    @dataflow_name VARCHAR(200),
    @package_name VARCHAR(200),
    @status_type VARCHAR(20),
    @step_number FLOAT,
    @step_name VARCHAR(200),
    @row_count INT,
    @msg_description1 VARCHAR(200) = NULL,
    @error_description VARCHAR(8000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.job_flow_log
    (
        batch_id,
        Dataflow_Name,
        package_Name,
        Status_Type,
        step_number,
        step_name,
        row_count,
        Msg_Description1,
        Error_Description
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
