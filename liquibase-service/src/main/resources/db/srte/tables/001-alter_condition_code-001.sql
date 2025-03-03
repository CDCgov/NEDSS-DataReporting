IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'Condition_code' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'rhap_parse_nbs_ind' AND Object_ID = Object_ID(N'Condition_code'))
            BEGIN
                ALTER TABLE dbo.Condition_code
                    ADD rhap_parse_nbs_ind varchar(1);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'rhap_action_value' AND Object_ID = Object_ID(N'Condition_code'))
            BEGIN
                ALTER TABLE dbo.Condition_code
                    ADD rhap_action_value varchar(200);
            END;

        -- CNDE-2138
        /*
            The update statement below is for enabling the creation of Legacy Pertussis cases.

            It will also cause the Legacy ETL to treat all existing pagebuilder Pertussis cases
            as legacy cases, meaning mostly NULL rows will be inserted into dbo.Pertussis_Case
            for each pagebuilder Pertussis Case.

            This change will need to be removed/reverted when moving to a production environment.
        */
        UPDATE dbo.condition_code
        SET investigation_form_cd = 'INV_FORM_PER'
        WHERE condition_cd = '10190';
    END;