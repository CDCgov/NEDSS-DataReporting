CREATE OR ALTER  VIEW dbo.v_codeset as
WITH totalidm AS (
    SELECT
        unique_cd as  'CD',
        SRT_reference as  'code_set_nm',
        format as  'format',
        label as  'cd_desc'
    FROM dbo.nrt_srte_totalidm t
),
     ALL_CODESET as (
         SELECT
             LEFT(unique_cd, 7) as  'CD',
             LEFT(RDB_table, 32) as  'TBL_NM',
             RDB_attribute as  'COL_NM',
             condition_cd as  'condition_cd'
         FROM dbo.nrt_srte_imrdbmapping),
     RDBCodeset AS
         (
             SELECT
                 m.CD,
                 m.TBL_NM,
                 m.COL_NM,
                 t.code_set_nm,
                 LEFT(t.cd_desc,300) as cd_desc,
                 NULL                 as DATA_TYPE,
                 NULL                 as DATA_LENGTH
             FROM totalidm t --A
                      RIGHT JOIN ALL_CODESET m  --B
                                 ON t.cd = m.cd
         )
SELECT
    agg.CD,
    agg.TBL_NM,
    agg.COL_NM,
    c.source_version_txt as CD_SYS_VER,
    agg.DATA_TYPE,
    agg.DATA_LENGTH,
    NULLIF(c.code_set_nm,'') as code_set_nm,
    COALESCE(c.code_set_desc_txt,agg.cd_desc)	as CD_DESC
FROM RDBCodeset agg
         LEFT JOIN dbo.nrt_srte_codeset c on c.code_set_nm = agg.code_set_nm;