IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'F_VAR_PAM'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.F_VAR_PAM
        (
            PERSON_KEY               bigint NOT NULL,
            D_VAR_PAM_KEY            bigint NOT NULL,
            PROVIDER_KEY             bigint NOT NULL,
            D_PCR_SOURCE_GROUP_KEY   bigint NOT NULL,
            D_RASH_LOC_GEN_GROUP_KEY bigint NOT NULL,
            HOSPITAL_KEY             bigint NOT NULL,
            ORG_AS_REPORTER_KEY      bigint NOT NULL,
            PERSON_AS_REPORTER_KEY   bigint NOT NULL,
            PHYSICIAN_KEY            bigint NOT NULL,
            ADD_DATE_KEY             bigint NOT NULL,
            LAST_CHG_DATE_KEY        bigint NOT NULL,
            INVESTIGATION_KEY        bigint NOT NULL
        );
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_VAR_PAM' 
        AND constraint_name='FK_F_PCR_SOURCE_GROUP')
    BEGIN
        ALTER TABLE [dbo].[F_VAR_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_PCR_SOURCE_GROUP] FOREIGN KEY([D_PCR_SOURCE_GROUP_KEY])
        REFERENCES [dbo].[D_PCR_SOURCE_GROUP] ([D_PCR_SOURCE_GROUP_KEY])
        
        ALTER TABLE [dbo].[F_VAR_PAM] CHECK CONSTRAINT [FK_F_PCR_SOURCE_GROUP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_VAR_PAM' 
        AND constraint_name='FK_F_RASH_LOC_GEN_GROUP')
    BEGIN
        ALTER TABLE [dbo].[F_VAR_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_RASH_LOC_GEN_GROUP] FOREIGN KEY([D_RASH_LOC_GEN_GROUP_KEY])
        REFERENCES [dbo].[D_RASH_LOC_GEN_GROUP] ([D_RASH_LOC_GEN_GROUP_KEY])

        ALTER TABLE [dbo].[F_VAR_PAM] CHECK CONSTRAINT [FK_F_RASH_LOC_GEN_GROUP]
    END;
    
If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_VAR_PAM' 
        AND constraint_name='FK_F_VAR_PAM_D_VAR_PAM')
    BEGIN
        ALTER TABLE [dbo].[F_VAR_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_VAR_PAM_D_VAR_PAM] FOREIGN KEY([D_VAR_PAM_KEY])
        REFERENCES [dbo].[D_VAR_PAM] ([D_VAR_PAM_KEY])

        ALTER TABLE [dbo].[F_VAR_PAM] CHECK CONSTRAINT [FK_F_VAR_PAM_D_VAR_PAM]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_VAR_PAM' 
        AND constraint_name='FK_F_VAR_PAM_HOSPITAL')
    BEGIN
        ALTER TABLE [dbo].[F_VAR_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_VAR_PAM_HOSPITAL] FOREIGN KEY([HOSPITAL_KEY])
        REFERENCES [dbo].[D_ORGANIZATION] ([ORGANIZATION_KEY])

        ALTER TABLE [dbo].[F_VAR_PAM] CHECK CONSTRAINT [FK_F_VAR_PAM_HOSPITAL]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_VAR_PAM' 
        AND constraint_name='FK_F_VAR_PAM_ORG_REPORTER')
    BEGIN
        ALTER TABLE [dbo].[F_VAR_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_VAR_PAM_ORG_REPORTER] FOREIGN KEY([ORG_AS_REPORTER_KEY])
        REFERENCES [dbo].[D_ORGANIZATION] ([ORGANIZATION_KEY])

        ALTER TABLE [dbo].[F_VAR_PAM] CHECK CONSTRAINT [FK_F_VAR_PAM_ORG_REPORTER]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_VAR_PAM' 
        AND constraint_name='FK_F_VAR_PAM_PERSON')
    BEGIN
        ALTER TABLE [dbo].[F_VAR_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_VAR_PAM_PERSON] FOREIGN KEY([PERSON_KEY])
        REFERENCES [dbo].[D_PATIENT] ([PATIENT_KEY])

        ALTER TABLE [dbo].[F_VAR_PAM] CHECK CONSTRAINT [FK_F_VAR_PAM_PERSON]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_VAR_PAM' 
        AND constraint_name='FK_F_VAR_PAM_PERSON_REPORTER')
    BEGIN
        ALTER TABLE [dbo].[F_VAR_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_VAR_PAM_PERSON_REPORTER] FOREIGN KEY([PERSON_AS_REPORTER_KEY])
        REFERENCES [dbo].[D_PROVIDER] ([PROVIDER_KEY])

        ALTER TABLE [dbo].[F_VAR_PAM] CHECK CONSTRAINT [FK_F_VAR_PAM_PERSON_REPORTER]
    END;