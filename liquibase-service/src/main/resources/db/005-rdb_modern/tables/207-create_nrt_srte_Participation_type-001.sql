IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Participation_type'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Participation_type
        (
            act_class_cd        varchar(20)  NOT NULL,
            record_status_cd    varchar(20)  NOT NULL,
            record_status_time  datetime     NOT NULL,
            subject_class_cd    varchar(20)  NOT NULL,
            type_cd             varchar(50)  NOT NULL,
            type_desc_txt       varchar(100) NOT NULL,
            question_identifier varchar(50)  NOT NULL,
            type_prefix         varchar(8)   NOT NULL,
            CONSTRAINT PK_participation_type PRIMARY KEY CLUSTERED (act_class_cd, subject_class_cd, type_cd, question_identifier)
        ) ON [PRIMARY]

        ALTER TABLE dbo.nrt_srte_Participation_type
            ADD DEFAULT ('0') FOR type_prefix
    END;