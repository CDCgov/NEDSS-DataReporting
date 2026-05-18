SELECT COUNT(*) AS msg537_count
FROM   [RDB_MODERN].[dbo].[job_flow_log] WITH (NOLOCK)
WHERE  [Dataflow_Name] = 'sp_ldf_tetanus_datamart_postprocessing POST-Processing'
  AND  [Msg_Description1] LIKE '%Invalid length parameter passed to the LEFT or SUBSTRING function%'
  AND  [create_dttm] > DATEADD(MINUTE, -10, GETDATE())
