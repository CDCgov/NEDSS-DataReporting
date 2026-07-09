IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_dyn_dm_column_metadata' and xtype = 'U')
BEGIN
    CREATE TABLE dbo.nrt_dyn_dm_column_metadata (
        nbs_page_uid                bigint                      NULL,
        nbs_ui_metadata_uid         bigint                      NULL,
        user_defined_column_nm      VARCHAR(200)                NULL,
        block_pivot_nbr             bigint                      NULL
    );
END;