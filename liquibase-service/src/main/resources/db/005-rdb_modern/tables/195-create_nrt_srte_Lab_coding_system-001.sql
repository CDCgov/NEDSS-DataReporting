IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Lab_coding_system'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Lab_coding_system
        (
            laboratory_id                varchar(20)  NOT NULL,
            laboratory_system_desc_txt   varchar(100) NULL,
            coding_system_cd             varchar(20)  NULL,
            code_system_desc_txt         varchar(100) NULL,
            electronic_lab_ind           char(1)      NULL,
            effective_from_time          datetime     NULL,
            effective_to_time            datetime     NULL,
            assigning_authority_cd       varchar(199) NULL,
            assigning_authority_desc_txt varchar(100) NULL,
            nbs_uid                      bigint       NULL,
            CONSTRAINT PK_Lab199 PRIMARY KEY CLUSTERED (laboratory_id)
        ) ON [PRIMARY]
    END;