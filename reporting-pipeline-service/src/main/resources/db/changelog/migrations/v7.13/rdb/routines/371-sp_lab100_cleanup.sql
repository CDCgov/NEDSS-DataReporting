IF EXISTS (SELECT *
           FROM   sysobjects
           WHERE  id = Object_id(N'[dbo].[sp_lab100_cleanup]')
                  AND Objectproperty(id, N'IsProcedure') = 1)
  BEGIN
      DROP PROCEDURE [dbo].[sp_lab100_cleanup]
  END

GO

CREATE PROCEDURE [dbo].[Sp_lab100_cleanup] @debug BIT = 'false'
AS
  BEGIN
      DECLARE @batch_id BIGINT;

      SET @batch_id = Cast(( Format(Getdate(), 'yyMMddHHmmssffff') ) AS BIGINT);

      PRINT @batch_id;

      DECLARE @RowCount_no INT;
      DECLARE @Proc_Step_no FLOAT= 0;
      DECLARE @Proc_Step_Name VARCHAR(200)= '';
      DECLARE @Dataflow_Name VARCHAR(200) = 'Lab 100 Cleanup';
      DECLARE @Package_Name VARCHAR(200) = 'sp_lab100_cleanup';

      BEGIN try
          SET @Proc_Step_Name = 'SP_Start';

          INSERT INTO dbo.job_flow_log
                      (batch_id,
                       [dataflow_name],
                       [package_name],
                       [status_type],
                       [step_number],
                       [step_name],
                       [row_count])
          VALUES      ( @batch_id,
                        @Dataflow_Name,
                        @Package_Name,
                        'START',
                        @Proc_Step_no,
                        @Proc_Step_Name,
                        0);

          ------------------------------------------------------------------------------------------------------------------------------------------------
          /* Update records associated to Inactive Orders using LAB_TEST */
          BEGIN TRANSACTION;
          SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
          SET @PROC_STEP_NAME = 'UPDATE INACTIVE LAB100 RECORDS';

          UPDATE l
          SET record_status_cd = 'INACTIVE'
          FROM dbo.LAB100 l
          WHERE
              RESULTED_LAB_TEST_KEY IN (
                  SELECT
                      l.RESULTED_LAB_TEST_KEY
                  FROM dbo.LAB_TEST lt
                          INNER JOIN dbo.LAB100 l on
                      l.RESULTED_LAB_TEST_KEY = lt.LAB_TEST_KEY
                  WHERE
                      ROOT_ORDERED_TEST_PNTR IN
                      (
                          SELECT ROOT_ORDERED_TEST_PNTR
                          FROM dbo.LAB_TEST ltr
                          WHERE
                              LAB_TEST_TYPE = 'Order'
                            AND record_status_cd = 'INACTIVE'
                      )
                    AND l.record_status_cd <> 'INACTIVE'
              );
          
          SELECT @ROWCOUNT_NO = @@ROWCOUNT;

          INSERT INTO [DBO].[job_flow_log]
                      (batch_id,
                       [dataflow_name],
                       [package_name],
                       [status_type],
                       [step_number],
                       [step_name],
                       [row_count])
          VALUES      (@BATCH_ID,
                       @Dataflow_Name,
                       @Package_Name,
                       'START',
                       @PROC_STEP_NO,
                       @PROC_STEP_NAME,
                       @ROWCOUNT_NO);

          COMMIT TRANSACTION;

          /* Remove keys in LAB100 that no longer exist in LAB_TEST. */
          BEGIN TRANSACTION;

          SET @PROC_STEP_NO = @PROC_STEP_NO + 1;
          SET @PROC_STEP_NAME = 'DELETE REMOVED OBSERVATIONS FROM LAB100';

          /* Remove keys in LAB100 that no longer exist in LAB_TEST. */
          DELETE FROM dbo.lab100
          WHERE  resulted_lab_test_key IN (
                 SELECT DISTINCT l.resulted_lab_test_key
                 FROM   dbo.lab100 l
                 EXCEPT
                 SELECT lt.lab_test_key
                 FROM   dbo.lab_test lt);

          SELECT @ROWCOUNT_NO = @@ROWCOUNT;

          INSERT INTO [DBO].[job_flow_log]
                      (batch_id,
                       [dataflow_name],
                       [package_name],
                       [status_type],
                       [step_number],
                       [step_name],
                       [row_count])
          VALUES      (@BATCH_ID,
                       @Dataflow_Name,
                       @Package_Name,
                       'START',
                       @PROC_STEP_NO,
                       @PROC_STEP_NAME,
                       @ROWCOUNT_NO);

          COMMIT TRANSACTION;

                  BEGIN TRANSACTION;

        SET @PROC_STEP_NO =  999 ;
        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO [DBO].[job_flow_log]
                      (batch_id,
                       [dataflow_name],
                       [package_name],
                       [status_type],
                       [step_number],
                       [step_name],
                       [row_count])
          VALUES      (@BATCH_ID,
                       @Dataflow_Name,
                       @Package_Name,
                       'COMPLETE',
                       @PROC_STEP_NO,
                       @PROC_STEP_NAME,
                       @ROWCOUNT_NO);


        COMMIT TRANSACTION;
      ------------------------------------------------------------------------------------------------------------------------------------------------
      END try

      BEGIN catch
          IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

          -- Construct the error message string with all details:
          DECLARE @FullErrorMessage VARCHAR(8000) = 'Error Number: '
            + Cast(Error_number() AS VARCHAR(10))
            + Char(13) + Char(10) +
            -- Carriage return and line feed for new lines
            'Error Severity: '
            + Cast(Error_severity() AS VARCHAR(10))
            + Char(13) + Char(10) + 'Error State: '
            + Cast(Error_state() AS VARCHAR(10))
            + Char(13) + Char(10) + 'Error Line: '
            + Cast(Error_line() AS VARCHAR(10))
            + Char(13) + Char(10) + 'Error Message: '
            + Error_message();

          INSERT INTO [dbo].[job_flow_log]
                      (batch_id,
                       [dataflow_name],
                       [package_name],
                       [status_type],
                       [step_number],
                       [step_name],
                       [error_description],
                       [row_count])
          VALUES      (@batch_id,
                       @Dataflow_Name,
                       @Package_Name,
                       'ERROR',
                       @Proc_Step_no,
                       @Proc_Step_name,
                       @FullErrorMessage,
                       0);

          RETURN -1;
      END catch
  END; 
  