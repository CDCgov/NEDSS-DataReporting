IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'F_TB_PAM'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.F_TB_PAM
        (
            PERSON_KEY               bigint NOT NULL,
            D_TB_PAM_KEY             bigint NOT NULL,
            PROVIDER_KEY             bigint NOT NULL,
            D_MOVE_STATE_GROUP_KEY   bigint NOT NULL,
            D_HC_PROV_TY_3_GROUP_KEY bigint NOT NULL,
            D_DISEASE_SITE_GROUP_KEY bigint NOT NULL,
            D_ADDL_RISK_GROUP_KEY    bigint NOT NULL,
            D_MOVE_CNTY_GROUP_KEY    bigint NOT NULL,
            D_GT_12_REAS_GROUP_KEY   bigint NOT NULL,
            D_MOVE_CNTRY_GROUP_KEY   bigint NOT NULL,
            D_MOVED_WHERE_GROUP_KEY  bigint NOT NULL,
            D_OUT_OF_CNTRY_GROUP_KEY bigint NOT NULL,
            D_SMR_EXAM_TY_GROUP_KEY  bigint NOT NULL,
            ADD_DATE_KEY             bigint NOT NULL,
            LAST_CHG_DATE_KEY        bigint NOT NULL,
            INVESTIGATION_KEY        bigint NOT NULL,
            HOSPITAL_KEY             bigint NOT NULL,
            ORG_AS_REPORTER_KEY      bigint NOT NULL,
            PERSON_AS_REPORTER_KEY   bigint NOT NULL,
            PHYSICIAN_KEY            bigint NOT NULL
        );

    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_ADDL_RISK_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_ADDL_RISK_GRP] FOREIGN KEY([D_ADDL_RISK_GROUP_KEY])
        REFERENCES [dbo].[D_ADDL_RISK_GROUP] ([D_ADDL_RISK_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_ADDL_RISK_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_DIS_SITE_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_DIS_SITE_GRP] FOREIGN KEY([D_DISEASE_SITE_GROUP_KEY])
        REFERENCES [dbo].[D_DISEASE_SITE_GROUP] ([D_DISEASE_SITE_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_DIS_SITE_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_GT_12_REAS_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_GT_12_REAS_GRP] FOREIGN KEY([D_GT_12_REAS_GROUP_KEY])
        REFERENCES [dbo].[D_GT_12_REAS_GROUP] ([D_GT_12_REAS_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_GT_12_REAS_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_HC_PROV_TY3_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_HC_PROV_TY3_GRP] FOREIGN KEY([D_HC_PROV_TY_3_GROUP_KEY])
        REFERENCES [dbo].[D_HC_PROV_TY_3_GROUP] ([D_HC_PROV_TY_3_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_HC_PROV_TY3_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_MOVE_CNTRY_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_MOVE_CNTRY_GRP] FOREIGN KEY([D_MOVE_CNTRY_GROUP_KEY])
        REFERENCES [dbo].[D_MOVE_CNTRY_GROUP] ([D_MOVE_CNTRY_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_MOVE_CNTRY_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_MOVE_CNTY_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_MOVE_CNTY_GRP] FOREIGN KEY([D_MOVE_CNTY_GROUP_KEY])
        REFERENCES [dbo].[D_MOVE_CNTY_GROUP] ([D_MOVE_CNTY_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_MOVE_CNTY_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_MOVE_STATE_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_MOVE_STATE_GRP] FOREIGN KEY([D_MOVE_STATE_GROUP_KEY])
        REFERENCES [dbo].[D_MOVE_STATE_GROUP] ([D_MOVE_STATE_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_MOVE_STATE_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_MOVED_WHERE_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_MOVED_WHERE_GRP] FOREIGN KEY([D_MOVED_WHERE_GROUP_KEY])
        REFERENCES [dbo].[D_MOVED_WHERE_GROUP] ([D_MOVED_WHERE_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_MOVED_WHERE_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_OUT_OF_CTRY_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_OUT_OF_CTRY_GRP] FOREIGN KEY([D_OUT_OF_CNTRY_GROUP_KEY])
        REFERENCES [dbo].[D_OUT_OF_CNTRY_GROUP] ([D_OUT_OF_CNTRY_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_OUT_OF_CTRY_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_SMR_EXAM_TY_GRP')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_SMR_EXAM_TY_GRP] FOREIGN KEY([D_SMR_EXAM_TY_GROUP_KEY])
        REFERENCES [dbo].[D_SMR_EXAM_TY_GROUP] ([D_SMR_EXAM_TY_GROUP_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_SMR_EXAM_TY_GRP]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_D_TB_PAM')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_D_TB_PAM] FOREIGN KEY([D_TB_PAM_KEY])
        REFERENCES [dbo].[D_TB_PAM] ([D_TB_PAM_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_D_TB_PAM]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_HOSPITAL')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_HOSPITAL] FOREIGN KEY([HOSPITAL_KEY])
        REFERENCES [dbo].[D_ORGANIZATION] ([ORGANIZATION_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_HOSPITAL]
    END;


If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_ORG_REPORTER')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_ORG_REPORTER] FOREIGN KEY([ORG_AS_REPORTER_KEY])
        REFERENCES [dbo].[D_ORGANIZATION] ([ORGANIZATION_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_ORG_REPORTER]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_PERSON')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_PERSON] FOREIGN KEY([PERSON_KEY])
        REFERENCES [dbo].[D_PATIENT] ([PATIENT_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_PERSON]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_PERSON_REPORTER')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_PERSON_REPORTER] FOREIGN KEY([PERSON_AS_REPORTER_KEY])
        REFERENCES [dbo].[D_PROVIDER] ([PROVIDER_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_PERSON_REPORTER]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_PHYSICIAN')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_PHYSICIAN] FOREIGN KEY([PHYSICIAN_KEY])
        REFERENCES [dbo].[D_PROVIDER] ([PROVIDER_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_PHYSICIAN]
    END;

If NOT EXISTS (SELECT 1 
    FROM information_schema.table_constraints 
    WHERE 
        table_schema='dbo' 
        AND table_name='F_TB_PAM' 
        AND constraint_name='FK_F_TB_PAM_PROVIDER')
    BEGIN
        ALTER TABLE [dbo].[F_TB_PAM]  WITH CHECK ADD  CONSTRAINT [FK_F_TB_PAM_PROVIDER] FOREIGN KEY([PROVIDER_KEY])
        REFERENCES [dbo].[D_PROVIDER] ([PROVIDER_KEY])

        ALTER TABLE [dbo].[F_TB_PAM] CHECK CONSTRAINT [FK_F_TB_PAM_PROVIDER]
    END;    