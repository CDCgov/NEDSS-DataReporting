IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_move_cnty_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_move_cnty_key (
            D_MOVE_CNTY_KEY bigint IDENTITY (2,1) NOT NULL,
            TB_PAM_UID bigint NOT NULL,
            NBS_Case_Answer_UID bigint NOT NULL,
            created_dttm DATETIME2 DEFAULT GETDATE(),
            updated_dttm DATETIME2 DEFAULT GETDATE()
        );

        declare @max bigint;
        select @max=max(D_MOVE_CNTY_KEY)+1 from dbo.d_move_cnty ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_move_cnty_key', RESEED, @max);
    END
