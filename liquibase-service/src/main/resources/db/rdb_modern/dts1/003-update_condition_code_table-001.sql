/*
    This file is a DTS1 ONLY Script and should NOT be checked into the Liquibase Changelog
*/

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'Condition_code' and xtype = 'U')
    BEGIN
        -- CNDE-2138
        /*
            The update statement below is for enabling the creation of Legacy Pertussis cases.

            It will also cause the Legacy ETL to treat all existing pagebuilder Pertussis cases
            as legacy cases, meaning mostly NULL rows will be inserted into dbo.Pertussis_Case
            for each pagebuilder Pertussis Case.

            This change will need to be removed/reverted when moving to a production environment.
        */
        UPDATE dbo.condition_code
        SET investigation_form_cd = 'INV_FORM_PER',
            port_req_ind_cd = 'T'
        WHERE condition_cd = '10190';

        -- CNDE2595

        -- enable Mumps LDF page and legacy page
        UPDATE nbs_srte.dbo.condition_code
        SET port_req_ind_cd = 'T',
            investigation_form_cd = 'INV_FORM_GEN'
        WHERE condition_cd = '10180';

        -- enable Tetanus LDF page and legacy page
        UPDATE nbs_srte.dbo.condition_code
        SET port_req_ind_cd = 'T',
            investigation_form_cd = 'INV_FORM_GEN'
        WHERE condition_cd = '10210';
    END;