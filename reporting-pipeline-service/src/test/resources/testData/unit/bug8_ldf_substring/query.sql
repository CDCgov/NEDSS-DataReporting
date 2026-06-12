SELECT COUNT(*) AS msg537_count
FROM   [RDB_MODERN].[dbo].[job_flow_log] WITH (NOLOCK)
WHERE  [Status_Type] = 'ERROR'
  AND  [Dataflow_Name] IN (
         'sp_ldf_bmird_datamart_postprocessing POST-Processing',
         'LDF_FOODBORNE POST-Processing',
         'sp_ldf_mumps_datamart_postprocessing POST-Processing',
         'LDF_TETANUS POST-Processing',
         'LDF_VACCINE_PREVENT_DISEASES POST-Processing',
         'sp_ldf_hepatitis_datamart_postprocessing POST-Processing'
       )
  AND  [Error_Description] LIKE '%Invalid length parameter passed to the LEFT or SUBSTRING function%'
  AND  [create_dttm] > DATEADD(MINUTE, -10, GETDATE())
