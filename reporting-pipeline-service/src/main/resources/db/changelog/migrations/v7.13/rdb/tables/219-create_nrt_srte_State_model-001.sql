IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_State_model'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_State_model
        (
            business_trigger_code_set_nm varchar(256) NOT NULL,
            business_trigger_set_seq_num smallint     NOT NULL,
            business_trigger_code        varchar(20)  NOT NULL,
            module_cd                    varchar(20)  NOT NULL,
            record_status_code_set_nm    varchar(256) NOT NULL,
            record_status_from_code      varchar(20)  NOT NULL,
            record_status_to_code        varchar(20)  NOT NULL,
            record_status_seq_nm         smallint     NOT NULL,
            object_status_code_set_nm    varchar(256) NOT NULL,
            object_status_from_code      varchar(20)  NOT NULL,
            object_status_to_code        varchar(20)  NOT NULL,
            object_status_seq_nm         smallint     NOT NULL,
            nbs_uid                      int          NULL,
            CONSTRAINT PK_State_model172 PRIMARY KEY CLUSTERED (business_trigger_code_set_nm,
                                                                business_trigger_set_seq_num, business_trigger_code,
                                                                module_cd, record_status_from_code)
        ) ON [PRIMARY]

        CREATE UNIQUE NONCLUSTERED INDEX UQ__State_model__2E1BDC42 ON dbo.nrt_srte_State_model (nbs_uid)
    END;