CREATE OR ALTER PROCEDURE dbo.sp_page_builder_postprocessing
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

        RETURN -1;
    END CATCH;
END;