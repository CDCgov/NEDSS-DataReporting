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

/*CNDE-1954: Separate Hepatitis Datamart condition code addition script.*/
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_datamart_metadata' and xtype = 'U')
    BEGIN
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

    END;

/*CNDE-1954: Page Builder STD HIV Codes determined using nnd_entity_identifier for STD and prog_area_cd for HIV.*/
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_datamart_metadata' and xtype = 'U')
    BEGIN
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

    END;
