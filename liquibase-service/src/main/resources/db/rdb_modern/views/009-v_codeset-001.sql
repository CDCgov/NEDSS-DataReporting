IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_codeset')
BEGIN
    DROP VIEW [dbo].v_codeset
END;
--GO   --"GO" not supported by liquibase, keep "GO" in manual scripts

CREATE VIEW [dbo].v_codeset 
AS
WITH 
totalidm AS (
    SELECT
        unique_cd           AS 'CD',
        SRT_reference       AS 'code_set_nm',
        format              AS 'format',
        label               AS 'cd_desc'
    FROM [dbo].nrt_srte_totalidm WITH (NOLOCK)
),
ALL_CODESET AS (
    SELECT
        LEFT(unique_cd, 7)  AS 'CD',
        LEFT(RDB_table, 32) AS 'TBL_NM',
        RDB_attribute       AS 'COL_NM',
        condition_cd        AS 'condition_cd'
    FROM [dbo].nrt_srte_imrdbmapping WITH (NOLOCK)
),
RDBCodeset AS
(
    SELECT
        m.CD,
        m.TBL_NM,
        m.COL_NM,
        t.code_set_nm,
        LEFT(t.cd_desc,300) AS cd_desc,
        NULL                AS DATA_TYPE,
        NULL                AS DATA_LENGTH
    FROM totalidm t --A
    RIGHT JOIN ALL_CODESET m  --B
        ON t.cd = m.cd
)
SELECT
    agg.CD,
    agg.TBL_NM,
    agg.COL_NM,
    c.source_version_txt AS CD_SYS_VER,
    agg.DATA_TYPE,
    agg.DATA_LENGTH,
    NULLIF(c.code_set_nm,'') AS code_set_nm,
    COALESCE(c.code_set_desc_txt,agg.cd_desc) AS CD_DESC
FROM RDBCodeset agg
LEFT JOIN [dbo].nrt_srte_codeset c WITH (NOLOCK)
    ON c.code_set_nm = agg.code_set_nm;