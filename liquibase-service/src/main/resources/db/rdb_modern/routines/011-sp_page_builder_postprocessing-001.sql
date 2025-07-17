IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_page_builder_postprocessing]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_page_builder_postprocessing]
END
GO

CREATE PROCEDURE dbo.sp_page_builder_postprocessing
    @phc_id_list nvarchar(max),
    @rdb_table_name nvarchar(300),
    @debug bit = 'false'
AS
begin

    begin try

        Declare @category varchar(250);
        DECLARE @batch_id BIGINT = 0 ;
        declare @step_name varchar(500) = '';

        set @batch_id = cast((format(getdate(),'yyMMddHHmmssffff')) as bigint)

        if @debug = 'true' Select @batch_id, @phc_id_list, @rdb_table_name;


        INSERT INTO [dbo].[job_flow_log](batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @batch_id, 'Page builder process', LEFT(@rdb_table_name,199), 'START', 0,'Step - Page Builder tables', 0 );

        declare @backfill_list nvarchar(max);
        SET @backfill_list =
        (
            SELECT string_agg(t.value, ',')
            FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@phc_id_list, ',')) t
                left join dbo.NRT_INVESTIGATION nrt
                on nrt.public_health_case_uid = t.value
                WHERE nrt.public_health_case_uid is null
        );

        IF @backfill_list IS NOT NULL
        BEGIN
            SELECT
                0 AS public_health_case_uid,
                CAST(NULL AS BIGINT) AS patient_uid,
                CAST(NULL AS BIGINT) AS observation_uid,
                'Error' AS datamart,
                CAST(NULL AS VARCHAR(50))  AS condition_cd,
                'Missing NRT Record: sp_page_builder_postprocessing' AS stored_procedure,
                CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
                WHERE 1=1;
            RETURN;
        END

        SET @backfill_list =
        (
            SELECT string_agg(t.value, ',')
            FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@phc_id_list, ',')) t
                left join dbo.NRT_PAGE_CASE_ANSWER nrt
                on nrt.act_uid = t.value
                WHERE nrt.act_uid is null
        );

        IF @backfill_list IS NOT NULL
        BEGIN
            SELECT
                0 AS public_health_case_uid,
                CAST(NULL AS BIGINT) AS patient_uid,
                CAST(NULL AS BIGINT) AS observation_uid,
                'Error' AS datamart,
                CAST(NULL AS VARCHAR(50))  AS condition_cd,
                'Missing NRT Record: sp_page_builder_postprocessing' AS stored_procedure,
                CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
                WHERE 1=1;
            RETURN;
        END



        if  left(trim(@rdb_table_name), 6) = 'D_INV_' AND trim(@rdb_table_name) != 'D_INV_PLACE_REPEAT'
            begin
                set @category = trim(SUBSTRING(@rdb_table_name, 3, LEN(@rdb_table_name)));

                set @step_name = @rdb_table_name;

                INSERT INTO [dbo].[job_flow_log](batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count], [msg_description1] )
                VALUES( @batch_id, 'Page builder staging process', @rdb_table_name , 'START', 0,'Step - ' + @step_name , 0, LEFT(@phc_id_list, 500) );

                execute dbo.sp_s_pagebuilder_postprocessing @batch_id, @phc_id_list, @rdb_table_name, @category;

                INSERT INTO [dbo].[job_flow_log](batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
                VALUES( @batch_id, 'Page builder lookup  process', @rdb_table_name , 'START', 0,'Step - ' + @step_name, 0 );

                execute dbo.sp_l_pagebuilder_postprocessing @batch_id, @phc_id_list, @rdb_table_name, @category;

                INSERT INTO [dbo].[job_flow_log](batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
                VALUES( @batch_id, 'Page builder dim process', @rdb_table_name , 'START', 0,'Step - ' + @step_name , 0 );

                execute dbo.sp_d_pagebuilder_postprocessing @batch_id, @phc_id_list, @rdb_table_name, @category;
            end
            else
                begin
                    if upper(@rdb_table_name) = 'D_INV_PLACE_REPEAT'
                        begin
                            execute dbo.sp_repeated_place_postprocessing @batch_id, @phc_id_list;
                        end
                    if upper(@rdb_table_name) = 'D_INVESTIGATION_REPEAT'
                        begin
                            execute dbo.sp_sld_investigation_repeat_postprocessing @batch_id, @phc_id_list;
                        end
                end

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @batch_id, 'Page builder process', LEFT(@rdb_table_name,199), 'COMPLETE', 0,'Step - Page Builder tables', 0 );

        SELECT
            CAST(NULL AS BIGINT) AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            CAST(NULL AS VARCHAR(30)) AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            CAST(NULL AS VARCHAR(200)) AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=0;
    end try

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        -- Construct the error message string with all details:
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: ' + ERROR_MESSAGE();

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count],[Error_Description] )
        VALUES( @batch_id
          , 'Page builder process'
          , @rdb_table_name
          , 'ERROR'
          , 0
          ,'Step - Page Builder tables'
          , 0
        , @FullErrorMessage);


        SELECT
            0 AS public_health_case_uid,
            CAST(NULL AS BIGINT) AS patient_uid,
            CAST(NULL AS BIGINT) AS observation_uid,
            'Error' AS datamart,
            CAST(NULL AS VARCHAR(50))  AS condition_cd,
            @FullErrorMessage AS stored_procedure,
            CAST(NULL AS VARCHAR(50))  AS investigation_form_cd
            WHERE 1=1;

    END CATCH;
END;