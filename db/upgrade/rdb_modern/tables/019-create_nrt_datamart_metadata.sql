IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_datamart_metadata' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_datamart_metadata
            (
                condition_cd       varchar(20) NOT NULL,
                condition_desc_txt varchar(300) NULL,
                Datamart           varchar(18) NOT NULL,
                Stored_Procedure   varchar(36) NOT NULL
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
                         , '10102'
                         , '10103'
                         , '10105'
                         , '10481'
                         , '50248'
                         , '999999' )
                    ) hep_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = hep_codes.condition_cd);
            END;

        /*CNDE-1954: Page Builder STD HIV Codes determined using nnd_entity_identifier for STD and prog_area_cd for HIV.*/
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
                     WHERE cc.nnd_entity_identifier = 'STD_Case_Map_v1.0' or cc.prog_area_cd = 'HIV'
                         AND (cc.investigation_form_cd IS NOT NULL and cc.investigation_form_cd LIKE '%PG_%')
                    ) std_hiv_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = std_hiv_codes.condition_cd);
            END;


        --Increase varchar length according to accomodate data
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
    END;

    /*BMIRD_Case Datamart condition code addition script.*/
        IF NOT EXISTS (SELECT 1 FROM dbo.nrt_datamart_metadata ndm WHERE ndm.Datamart = 'Bmird_Case_Datamart')
            BEGIN
                INSERT INTO dbo.nrt_datamart_metadata
                SELECT condition_cd,
                       condition_desc_txt,
                       'Bmird_Case_Datamart',
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