IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_dyn_dm_dimension_update]') 
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_dyn_dm_dimension_update]
END
GO 

CREATE PROCEDURE dbo.sp_dyn_dm_dimension_update  
    @dimension_nm VARCHAR(200),
    @dimension_update_tbl_nm VARCHAR(200),
    @batch_id BIGINT,
    @debug BIT = 'false'
AS
BEGIN

    BEGIN TRY
        
        declare @rowcount_no bigint = 0;
        declare @proc_step_no float = 0;
        declare @proc_step_name varchar(200) = '';
        declare @dataflow_name varchar(200) = 'Dynamic Datamart Dimension-Only Update';
        declare @package_name varchar(200) = 'sp_dyn_dm_dimension_update';
        declare @full_datamart_error_message NVARCHAR(MAX) = '';


        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start - ' + @dimension_nm + ' Dynamic Datamart Update'

        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );


        SET @proc_step_name= 'GENERATE #DYN_DM_DIMENSION_UPDATE_DATA';
        SET @proc_step_no = 2;

        CREATE TABLE #DYN_DM_DIMENSION_UPDATE_DATA (
            datamart_nm     VARCHAR(100)    NOT NULL,
            tbl_nm          VARCHAR(200)    NOT NULL,
            phc_uid_list    NVARCHAR(MAX)   NOT NULL
        );

        DECLARE @sql NVARCHAR(MAX) = '';

        SET @sql = ' 
        INSERT INTO #DYN_DM_DIMENSION_UPDATE_DATA ( 
            datamart_nm, 
            tbl_nm, 
            phc_uid_list
        )
        SELECT 
            datamart_nm, 
            tbl_nm, 
            phc_uid_list 
        FROM dbo.' + @dimension_update_tbl_nm + '
        ';

        exec sp_executesql @sql;

        if @debug = 'true'
            SELECT @proc_step_name, * FROM #DYN_DM_DIMENSION_UPDATE_DATA;

        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

        IF EXISTS (SELECT 1 FROM #DYN_DM_DIMENSION_UPDATE_DATA)
        BEGIN

            SET @proc_step_name= 'UPDATE DATAMARTS';
            SET @proc_step_no = 3;

            DECLARE @datamart_nm VARCHAR(200);
            DECLARE @tbl_nm NVARCHAR(300);
            DECLARE @phc_uid_list NVARCHAR(MAX);
            DECLARE @sql_statement NVARCHAR(MAX);
            DECLARE @drop_statement NVARCHAR(MAX);
            DECLARE @err_ctr INTEGER;
            DECLARE @errmsg VARCHAR(2000);

            DECLARE dyn_dm_data_cursor CURSOR FOR
            SELECT 
                datamart_nm, 
                tbl_nm, 
                phc_uid_list
            FROM #DYN_DM_DIMENSION_UPDATE_DATA;

            OPEN dyn_dm_data_cursor;

            FETCH NEXT FROM dyn_dm_data_cursor INTO @datamart_nm, @tbl_nm, @phc_uid_list;

            SET @err_ctr = 0;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                BEGIN TRY
                    DECLARE @columns NVARCHAR(MAX) = '';
                    SET @errmsg = '';
                    DECLARE @datamart_table VARCHAR(200) = 'DM_INV_' + @datamart_nm;

                    IF @dimension_nm = 'D_PATIENT'
                        BEGIN
                            exec [dbo].sp_dyn_dm_invest_form_postprocessing_CNDE3066 @batch_id, @datamart_nm, @phc_uid_list, 'true';
                        END
                    ELSE IF @dimension_nm = 'D_ORGANIZATION'
                        BEGIN
                            exec [dbo].sp_dyn_dm_org_data_postprocessing @batch_id, @datamart_nm, @phc_uid_list;
                        END
                    ELSE IF @dimension_nm = 'D_PROVIDER'
                        BEGIN
                            exec [dbo].sp_dyn_dm_provider_data_postprocessing @batch_id, @datamart_nm, @phc_uid_list;
                        END;

                    if @debug = 'true'
                    BEGIN
                            PRINT 'Datamart: ' + @datamart_nm;
                            PRINT 'Table Name: ' + @tbl_nm;
                            PRINT 'PHC UIDs: ' + @phc_uid_list;
                            SET @sql_statement = 'SELECT * FROM ' + @tbl_nm + ';';
                            exec sp_executesql @sql_statement;
                    END;

                    IF OBJECT_ID('dbo.' + @tbl_nm, 'U') IS NULL
                    BEGIN
                        SET @errmsg = 'Source table ''' +  @tbl_nm + ''' does not exist';
                        RAISERROR(@errmsg, 16, 1);
                    END

                    -- Get list of matching columns (excluding the key)
                    SELECT @columns = STRING_AGG(CAST(QUOTENAME(t.COLUMN_NAME) + ' = src.' + QUOTENAME(t.COLUMN_NAME) AS NVARCHAR(MAX)), ', ')
                    FROM INFORMATION_SCHEMA.COLUMNS t
                    INNER JOIN INFORMATION_SCHEMA.COLUMNS s
                        ON t.COLUMN_NAME = s.COLUMN_NAME
                    WHERE t.TABLE_NAME = @datamart_table
                    AND s.TABLE_NAME = @tbl_nm
                    AND t.COLUMN_NAME != 'INVESTIGATION_KEY';

                    BEGIN TRANSACTION
                        SET @sql_statement = '
                            UPDATE tgt
                            SET ' + @columns + '
                            FROM ' + @datamart_table + ' tgt
                            INNER JOIN ' + @tbl_nm + ' src
                                ON tgt.INVESTIGATION_KEY = src.INVESTIGATION_KEY';

                        if @debug = 'true'
                            SELECT @proc_step_name, @sql_statement;

                        EXEC sp_executesql @sql_statement;
                    COMMIT TRANSACTION

                    IF OBJECT_ID('dbo.' + @tbl_nm, 'U') IS NOT NULL
                    BEGIN
                            SET @drop_statement = 'drop table dbo.' + @tbl_nm;
                            exec sp_executesql @drop_statement;
                    END

                END TRY
                BEGIN CATCH

                    set @full_datamart_error_message = @full_datamart_error_message + IIF(@err_ctr = 0, ' ', CHAR(13) + CHAR(10) + ', ') + 'ERROR: ' + ERROR_MESSAGE() + ' DATAMART: '+ @datamart_nm;
                    SET @err_ctr = @err_ctr + 1;

                    IF OBJECT_ID('dbo.' + @tbl_nm, 'U') IS NOT NULL
                    BEGIN
                            SET @drop_statement = 'drop table dbo.' + @tbl_nm;
                            exec sp_executesql @drop_statement;
                    END
                
                END CATCH
                FETCH NEXT FROM dyn_dm_data_cursor INTO @datamart_nm, @tbl_nm, @phc_uid_list;
          END;

        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'START' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );

            -- CHANGE TO CHECK FOR EMPTY STRING
          if @full_datamart_error_message != ''
            BEGIN
                    RAISERROR(@full_datamart_error_message, 16, 1)
            END

          CLOSE dyn_dm_data_cursor;
          DEALLOCATE dyn_dm_data_cursor;

     END;
        
        


        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE - D_PATIENT Update for ' + @datamart_table;

        INSERT INTO dbo.job_flow_log ( batch_id ,[Dataflow_Name] ,[package_Name] ,[Status_Type] ,[step_number] ,[step_name] ,[row_count] )
        VALUES ( @batch_id ,@Dataflow_Name ,@Package_Name  ,'COMPLETE' ,@Proc_Step_no ,@Proc_Step_Name ,@ROWCOUNT_NO );
--------------------------------------------------------------------------------------------------------
       END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        -- Construct the error message string with all details:
            DECLARE @FullErrorMessage VARCHAR(8000) =
                'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +  -- Carriage return and line feed for new lines
                'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
                'Error Message: ' + ERROR_MESSAGE();


            INSERT INTO [dbo].[job_flow_log] 
            (batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count])
            VALUES (@batch_id, @Dataflow_Name, @Package_Name, 'ERROR', @Proc_Step_no, @Proc_Step_name, @FullErrorMessage, 0);

        return -1 ;
    END CATCH
END;