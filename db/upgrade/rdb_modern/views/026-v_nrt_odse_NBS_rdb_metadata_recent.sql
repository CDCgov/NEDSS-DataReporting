IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_odse_NBS_rdb_metadata_recent')
BEGIN
    DROP VIEW [dbo].v_nrt_odse_NBS_rdb_metadata_recent
END;
GO

CREATE VIEW [dbo].v_nrt_odse_NBS_rdb_metadata_recent
AS
WITH 
ordered_cte as(
    SELECT
        nbs_rdb_metadata_uid,
        nbs_page_uid,
        nbs_ui_metadata_uid,
        rdb_table_nm,
        user_defined_column_nm,
        record_status_cd,
        record_status_time,
        last_chg_user_id,
        last_chg_time,
        local_id,
        rpt_admin_column_nm,
        rdb_column_nm,
        block_pivot_nbr,
        RANK() OVER (PARTITION BY nbs_page_uid ORDER BY last_chg_time DESC) as row_num
    FROM [dbo].nrt_odse_NBS_rdb_metadata WITH(NOLOCk)
)
SELECT 
    nbs_rdb_metadata_uid,
    nbs_page_uid,
    nbs_ui_metadata_uid,
    rdb_table_nm,
    user_defined_column_nm,
    record_status_cd,
    record_status_time,
    last_chg_user_id,
    last_chg_time,
    local_id,
    rpt_admin_column_nm,
    rdb_column_nm,
    block_pivot_nbr
FROM ordered_cte
WHERE row_num = 1;

