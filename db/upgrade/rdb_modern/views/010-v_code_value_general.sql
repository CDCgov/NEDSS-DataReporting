IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_code_value_general')
BEGIN
    DROP VIEW [dbo].v_code_value_general
END;
GO

CREATE VIEW [dbo].v_code_value_general 
AS
SELECT 
    v.code                 AS CODE_VAL,
    v.code_short_desc_txt  AS CODE_DESC,
    v.code_system_cd       AS CODE_SYS_CD,
    v.code_system_desc_txt AS CODE_SYS_CD_DESC,
    v.effective_from_time  AS CODE_EFF_DT,
    v.effective_to_time    AS CODE_END_DT,
    c.cd,
    ROW_NUMBER () over (ORDER BY c.cd) AS CODE_KEY
FROM [dbo].v_codeset c
INNER JOIN [dbo].nrt_srte_code_Value_General v WITH (NOLOCK)
    ON c.code_set_nm = v.code_set_nm;