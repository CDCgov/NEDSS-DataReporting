IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Unit_code'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Unit_code
        (
            unit_uid                     bigint       NOT NULL,
            code_set_nm                  varchar(256) NOT NULL,
            seq_num                      smallint     NOT NULL,
            code                         varchar(20)  NOT NULL,
            unit_desc_txt                varchar(300) NULL,
            assigning_authority_cd       varchar(199) NULL,
            assigning_authority_desc_txt varchar(100) NULL,
            code_system_cd               varchar(300) NULL,
            code_system_desc_txt         varchar(100) NULL,
            nbs_uid                      bigint       NULL,
            is_modifiable_ind            char(1)      NULL,
            status_cd                    char(1)      NULL,
            status_time                  datetime     NULL,
            CONSTRAINT PK_Unit_code235 PRIMARY KEY CLUSTERED (unit_uid)
        ) ON [PRIMARY]

        CREATE UNIQUE NONCLUSTERED INDEX UQ__Unit_code__3FD07829 ON dbo.nrt_srte_Unit_code (nbs_uid)

        ALTER TABLE dbo.nrt_srte_Unit_code
            ADD DEFAULT ('N') FOR is_modifiable_ind
    END;