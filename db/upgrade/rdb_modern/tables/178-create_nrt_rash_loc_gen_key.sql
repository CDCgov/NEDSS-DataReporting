IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_rash_loc_gen_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_rash_loc_gen_key (
            D_RASH_LOC_GEN_KEY bigint IDENTITY (2,1) NOT NULL,
            VAR_PAM_UID bigint NOT NULL,
            NBS_Case_Answer_UID bigint NOT NULL,
            created_dttm DATETIME2 DEFAULT GETDATE(),
            updated_dttm DATETIME2 DEFAULT GETDATE(),
            PRIMARY KEY (D_RASH_LOC_GEN_KEY, VAR_PAM_UID, NBS_Case_Answer_UID)
        );

        declare @max bigint;
        select @max=max(D_RASH_LOC_GEN_KEY)+1 from dbo.d_rash_loc_gen ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_rash_loc_gen_key', RESEED, @max);
    END
