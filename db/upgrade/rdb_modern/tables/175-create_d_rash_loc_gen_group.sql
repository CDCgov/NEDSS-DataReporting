IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'D_RASH_LOC_GEN_GROUP'
                 and xtype = 'U')

BEGIN				 
    CREATE TABLE DBO.D_RASH_LOC_GEN_GROUP (
        D_RASH_LOC_GEN_GROUP_KEY BIGINT NOT NULL ,
        CONSTRAINT PK_D_RASH_LOC_GEN_GROUP PRIMARY KEY  CLUSTERED 
        (
            D_RASH_LOC_GEN_GROUP_KEY
        )  ON [PRIMARY ]
    ) ON [PRIMARY];
END;