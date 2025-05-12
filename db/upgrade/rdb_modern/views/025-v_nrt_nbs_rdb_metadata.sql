CREATE OR ALTER VIEW [dbo].[v_nrt_nbs_rdb_metadata] AS
	SELECT * FROM [dbo].nrt_odse_NBS_rdb_metadata WITH(NOLOCK);