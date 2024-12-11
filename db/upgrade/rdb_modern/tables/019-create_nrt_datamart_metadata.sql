IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_datamart_metadata' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_datamart_metadata
            (
                condition_cd       varchar(20) NOT NULL,
                condition_desc_txt varchar(300) NULL,
                Datamart           varchar(18) NOT NULL,
                Stored_Procedure   varchar(36) NOT NULL
            );
        INSERT INTO dbo.nrt_datamart_metadata
        (condition_cd,condition_desc_txt,Datamart,Stored_Procedure)
        SELECT condition_cd,
               condition_desc_txt,
               'Hepatitis_Datamart',
               'sp_hepatitis_datamart_postprocessing'
        FROM NBS_SRTE.[dbo].[Condition_code]
                 WITH (NOLOCK)
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
            , '999999' );
    END