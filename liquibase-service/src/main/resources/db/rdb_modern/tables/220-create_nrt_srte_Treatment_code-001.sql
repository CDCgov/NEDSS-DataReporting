IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Treatment_code'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Treatment_code
        (
            treatment_cd                 varchar(20)  NOT NULL,
            treatment_desc_txt           varchar(300) NULL,
            assigning_authority_cd       varchar(199) NULL,
            assigning_authority_desc_txt varchar(100) NULL,
            code_system_cd               varchar(300) NULL,
            code_system_desc_txt         varchar(80)  NULL,
            code_version                 varchar(10)  NULL,
            treatment_type_cd            char(1)      NULL,
            nbs_uid                      smallint     NULL,
            effective_from_time          datetime     NULL,
            effective_to_time            datetime     NULL,
            status_cd                    varchar(1)   NULL,
            status_time                  datetime     NULL,
            source_concept_id            varchar(20)  NULL,
            code_set_nm                  varchar(256) NULL,
            seq_num                      smallint     NOT NULL,
            drug_cd                      varchar(20)  NULL,
            drug_desc_txt                varchar(255) NULL,
            dose_qty                     varchar(20)  NULL,
            dose_qty_unit_cd             varchar(10)  NULL,
            route_cd                     varchar(20)  NULL,
            route_desc_txt               varchar(255) NULL,
            interval_cd                  varchar(20)  NULL,
            interval_desc_txt            varchar(300) NULL,
            duration_amt                 varchar(20)  NULL,
            duration_unit_cd             varchar(20)  NULL,
            CONSTRAINT PK_Treatment_code211 PRIMARY KEY CLUSTERED (treatment_cd)
        ) ON [PRIMARY]
    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_Treatment_code' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'short_list_ind_cd' AND Object_ID = Object_ID(N'nrt_srte_Treatment_code'))
            BEGIN
                ALTER TABLE dbo.nrt_srte_Treatment_code
                ADD short_list_ind_cd char(1) DEFAULT 'Y' NULL;
            END;
    END;