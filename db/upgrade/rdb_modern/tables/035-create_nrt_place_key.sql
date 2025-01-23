IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_place_key'
                 and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_place_key
        (
            d_place_key       bigint IDENTITY (1,1) NOT NULL,
            place_uid         bigint                NULL,
            place_locator_uid varchar(30)           NULL,
        );
        declare @max bigint;
        select @max = max(place_key) + 1 from dbo.D_PLACE;
        select @max;
        if @max IS NULL --check when max is returned as null
            SET @max = 2; --Start from key=2
        DBCC CHECKIDENT ('dbo.nrt_place_key', RESEED, @max);

    END