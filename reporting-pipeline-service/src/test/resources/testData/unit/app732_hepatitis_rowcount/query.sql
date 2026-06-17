-- GREEN only when the step-3 JOB_FLOW_LOG row_count reflects the populated temp
-- table. Pre-fix it is 0, so this returns nothing and Await times out (RED).
SELECT ROW_COUNT
FROM RDB_MODERN.dbo.JOB_FLOW_LOG
WHERE DATAFLOW_NAME = 'HEPATITIS_DATAMART'
  AND STEP_NUMBER = 3
  AND ROW_COUNT >= 1;
