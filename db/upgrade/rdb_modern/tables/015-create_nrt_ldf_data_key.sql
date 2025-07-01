IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_ldf_data_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_ldf_data_key(
            d_ldf_data_key      bigint IDENTITY (1,1) NOT NULL,
            d_ldf_group_key     bigint                NULL,
            business_object_uid bigint                NULL,
            ldf_uid             bigint                NULL,
            created_dttm DATETIME2 DEFAULT GETDATE(),
            updated_dttm DATETIME2 DEFAULT GETDATE(),
            PRIMARY KEY (d_ldf_data_key)
        );

        declare @max bigint;
        select @max=max(ldf_data_key)+2 from dbo.ldf_data;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2;
        DBCC CHECKIDENT ('dbo.nrt_ldf_data_key', RESEED, @max);

    END