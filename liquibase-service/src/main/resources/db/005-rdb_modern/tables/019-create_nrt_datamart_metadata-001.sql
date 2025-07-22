IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_datamart_metadata' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_datamart_metadata
        (
            condition_cd       varchar(20)  NOT NULL,
            condition_desc_txt varchar(300) NULL,
            Datamart           varchar(18)  NOT NULL,
            Stored_Procedure   varchar(36)  NOT NULL,
            legacy_form_cd     varchar(50)  NULL
        );
    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_datamart_metadata' and xtype = 'U')
    BEGIN
        /*CNDE-1954: Separate Hepatitis Datamart condition code addition script.*/
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Hepatitis_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'Hepatitis_Datamart',
                       'sp_hepatitis_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.[dbo].[Condition_code] cc WITH (NOLOCK)
                     WHERE CONDITION_CD IN ( '10110'
                         , '10104'
                         , '10100'
                         , '10106'
                         , '10101'
                         , '10103'
                         , '10105'
                         , '50248'
                         )
                    ) hep_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = hep_codes.condition_cd);
            END;

        /*CNDE-1954: Page Builder STD HIV Codes determined using nnd_entity_identifier for STD and prog_area_cd for HIV.
          CNDE-2506: (Update) Check for baseline STD prog area condition. If there exists 1 or more conditions with
          nnd_entity_identifier= 'STD_Case_Map_v1.0' and port_req_ind_cd ='F', the complete STD prog_area_cd set of
          codes will be included, along with HIV. If the baseline condition is not fulfilled,add only HIV prog area codes.*/
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Std_Hiv_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'Std_Hiv_Datamart',
                       'sp_std_hiv_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE
                         (EXISTS (SELECT 1 FROM NBS_SRTE.dbo.Condition_code WHERE nnd_entity_identifier= 'STD_Case_Map_v1.0'
                                                                              and port_req_ind_cd ='F')
                             AND cc.prog_area_cd IN ('HIV', 'STD'))
                        OR (cc.prog_area_cd = 'HIV')
                         AND (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE '%PG_%')
                    ) std_hiv_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = std_hiv_codes.condition_cd);
            END;

        --Increase varchar length according to accommodate data
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = object_id('nrt_datamart_metadata') AND name='Stored_Procedure' AND max_length=36)
            BEGIN
                ALTER TABLE dbo.nrt_datamart_metadata
                    ALTER COLUMN Stored_Procedure VARCHAR(200)
            END

        /*CNDE-2046: Generic_Case Datamart condition code addition script.*/
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Generic_Case')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'Generic_Case',
                       'sp_generic_case_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE 'INV_FORM_GEN%')
                    ) gen_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = gen_codes.condition_cd);
            END;

        /*CRS_Case Datamart condition code addition script.*/
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'CRS_Case')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'CRS_Case',
                       'sp_crs_case_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE 'INV_FORM_CRS%')
                    ) crs_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = crs_codes.condition_cd);
            END;

        /*Rubella_Case Datamart condition code addition script.*/
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Rubella_Case')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'Rubella_Case',
                       'sp_rubella_case_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE 'INV_FORM_RUB%')
                    ) rub_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = rub_codes.condition_cd);
            END;

        /*Measles_Case Datamart condition code addition script.*/
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Measles_Case')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'Measles_Case',
                       'sp_measles_case_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE 'INV_FORM_MEA%')
                    ) measles_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = measles_codes.condition_cd);
            END;

        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Case_Lab_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                VALUES ('', '', 'Case_Lab_Datamart', 'sp_case_lab_datamart_postprocessing')
            END;

        /*BMIRD_Case Datamart condition code addition script.*/
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'BMIRD_Case')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'BMIRD_Case',
                       'sp_bmird_case_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE 'INV_FORM_BMD%')
                    ) bmird_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = bmird_codes.condition_cd);
            END;

        /*CNDE-2129: Separate Hepatitis Datamart condition code addition script.*/
        --fix to remove incorrectly mapped
        IF EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Hepatitis_Datamart'
                                                                 and condition_cd in ( '999999','10481', '10102') )
            BEGIN
                DELETE FROM dbo.nrt_datamart_metadata where Datamart = 'Hepatitis_Datamart' and condition_cd in ( '999999','10481', '10102') ;
            END
        --adding the legacy Hep cases
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Hepatitis_Case')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'Hepatitis_Case',
                       'sp_hepatitis_case_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE 'INV_FORM_HEP%')
                    ) hep_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = hep_codes.condition_cd);
            END;

        --adding the legacy pertussis cases
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Pertussis_Case')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'Pertussis_Case',
                       'sp_pertussis_case_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE 'INV_FORM_PER%')
                    ) per_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = per_codes.condition_cd);
            END;

        -- TB_DATAMART
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'TB_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'TB_Datamart',
                       'sp_tb_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE 'INV_FORM_RVCT%')
                    ) gen_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = gen_codes.condition_cd);
            END;

        -- VAR_DATAMART
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'VAR_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'VAR_Datamart',
                       'sp_var_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE 'INV_FORM_VAR%')
                    ) gen_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = gen_codes.condition_cd);
            END;

        /*CNDE-2506: Adding missing Syphilis, congenital code if Std_Hiv_Datamart has already been registered
          baseline STD condition is fulfilled.*/
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Std_Hiv_Datamart' and ndm.condition_cd = 10316)
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT cc.condition_cd,
                       cc.condition_desc_txt,
                       'Std_Hiv_Datamart',
                       'sp_std_hiv_datamart_postprocessing'
                FROM
                    NBS_SRTE.dbo.Condition_code cc
                WHERE cc.condition_cd = '10316'
                  AND EXISTS (SELECT 1 FROM NBS_SRTE.dbo.Condition_code WHERE nnd_entity_identifier= 'STD_Case_Map_v1.0'
                                                                          and port_req_ind_cd ='F');
            END;
        --Increase varchar length for covid datamarts
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = object_id('nrt_datamart_metadata') AND name='Datamart' AND max_length=18)
            BEGIN
                ALTER TABLE dbo.nrt_datamart_metadata
                    ALTER COLUMN Datamart VARCHAR(30)
            END

        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Covid_Case_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                        condition_desc_txt,
                        'Covid_Case_Datamart',
                        'sp_covid_case_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                    FROM NBS_SRTE.[dbo].[Condition_code] cc WITH (NOLOCK)
                    WHERE CONDITION_CD IN ( '11065')
                    ) hep_codes
                    WHERE NOT EXISTS
                            (SELECT 1
                            FROM dbo.nrt_datamart_metadata ndm
                            WHERE ndm.condition_cd = hep_codes.condition_cd and ndm.Datamart = 'Covid_Case_Datamart');
            END;

        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Covid_Lab_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                        condition_desc_txt,
                        'Covid_Lab_Datamart',
                        'sp_covid_lab_celr_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                    FROM NBS_SRTE.[dbo].[Condition_code] cc WITH (NOLOCK)
                    WHERE CONDITION_CD IN ( '11065')
                    ) hep_codes
                    WHERE NOT EXISTS
                            (SELECT 1
                            FROM dbo.nrt_datamart_metadata ndm
                            WHERE ndm.condition_cd = hep_codes.condition_cd and ndm.Datamart = 'Covid_Lab_Datamart');
            END;

        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Covid_Contact_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                        condition_desc_txt,
                        'Covid_Contact_Datamart',
                        'sp_covid_contact_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                    FROM NBS_SRTE.[dbo].[Condition_code] cc WITH (NOLOCK)
                    WHERE CONDITION_CD IN ( '11065')
                    ) hep_codes
                    WHERE NOT EXISTS
                            (SELECT 1
                            FROM dbo.nrt_datamart_metadata ndm
                            WHERE ndm.condition_cd = hep_codes.condition_cd and ndm.Datamart = 'Covid_Contact_Datamart');
            END;

        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Covid_Vaccination_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                        condition_desc_txt,
                        'Covid_Vaccination_Datamart',
                        'sp_covid_vaccination_datamart_postprocessing'
                FROM
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt
                    FROM NBS_SRTE.[dbo].[Condition_code] cc WITH (NOLOCK)
                    WHERE CONDITION_CD IN ( '11065')
                    ) hep_codes
                    WHERE NOT EXISTS
                            (SELECT 1
                            FROM dbo.nrt_datamart_metadata ndm
                            WHERE ndm.condition_cd = hep_codes.condition_cd and ndm.Datamart = 'Covid_Vaccination_Datamart');
            END;

        -- CNDE-2709 add legacy_form_cd to metadata table and update with current value of investigation_form_cd
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'legacy_form_cd' AND Object_ID = Object_ID(N'nrt_datamart_metadata'))
            BEGIN
                ALTER TABLE dbo.nrt_datamart_metadata
                    ADD legacy_form_cd varchar(50) NULL;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'legacy_form_cd' AND Object_ID = Object_ID(N'nrt_datamart_metadata'))
            BEGIN
                EXEC('
                UPDATE ndm
                SET legacy_form_cd = cc.investigation_form_cd
                FROM dbo.nrt_datamart_metadata ndm
                    INNER JOIN NBS_SRTE.dbo.Condition_code cc WITH (NOLOCK)
                        ON cc.condition_cd = ndm.condition_cd
                WHERE (
                    (ndm.Datamart = ''Generic_Case'' AND cc.investigation_form_cd LIKE ''INV_FORM_GEN%'') OR
                    (ndm.Datamart = ''CRS_Case'' AND cc.investigation_form_cd LIKE ''INV_FORM_CRS%'') OR
                    (ndm.Datamart = ''Rubella_Case'' AND cc.investigation_form_cd LIKE ''INV_FORM_RUB%'') OR
                    (ndm.Datamart = ''Measles_Case'' AND cc.investigation_form_cd LIKE ''INV_FORM_MEA%'') OR
                    (ndm.Datamart = ''BMIRD_Case'' AND cc.investigation_form_cd LIKE ''INV_FORM_BMD%'') OR
                    (ndm.Datamart = ''Hepatitis_Case'' AND cc.investigation_form_cd LIKE ''INV_FORM_HEP%'') OR
                    (ndm.Datamart = ''Pertussis_Case'' AND cc.investigation_form_cd LIKE ''INV_FORM_PER%'') OR
                    (ndm.Datamart = ''TB_Datamart'' AND cc.investigation_form_cd LIKE ''INV_FORM_RVCT%'') OR
                    (ndm.Datamart = ''VAR_Datamart'' AND cc.investigation_form_cd LIKE ''INV_FORM_VAR%'')
                )');
            END;
    END;