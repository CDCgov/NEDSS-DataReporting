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
                    (SELECT distinct cc.condition_cd, cc.condition_desc_txt,cc.investigation_form_cd
                     FROM NBS_SRTE.dbo.Condition_code cc
                     WHERE cc.nnd_entity_identifier = 'STD_Case_Map_v1.0'
                     UNION
                     SELECT distinct cc.condition_cd, cc.condition_desc_txt,cc.investigation_form_cd
                     FROM NBS_SRTE.dbo.Condition_code cc
                     where cc.prog_area_cd = 'HIV' AND cc.investigation_form_cd IN ('PG_HIV_Investigation')
                    ) std_hiv_codes
                WHERE NOT EXISTS
                          (SELECT 1
                           FROM dbo.nrt_datamart_metadata ndm
                           WHERE ndm.condition_cd = std_hiv_codes.condition_cd);
            END;

    END;