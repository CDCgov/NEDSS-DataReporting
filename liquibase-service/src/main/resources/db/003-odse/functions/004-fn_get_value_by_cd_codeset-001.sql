IF EXISTS (SELECT * FROM   sys.objects WHERE  
    object_id = OBJECT_ID(N'[dbo].[fn_get_value_by_cd_codeset]')
    AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[fn_get_value_by_cd_codeset]
GO 

CREATE FUNCTION [dbo].fn_get_value_by_cd_codeset(
    @srte_code NVARCHAR(200),
    @unique_cd NVARCHAR(200)
)
    RETURNS TABLE
        AS RETURN

        SELECT cvg.code_short_desc_txt
        FROM nbs_srte.[dbo].codeset cd WITH (NOLOCK)
        JOIN nbs_srte.[dbo].totalidm tidm WITH (NOLOCK) 
            ON tidm.SRT_reference = cd.code_set_nm 
            AND tidm.unique_cd = (@unique_cd)
        JOIN nbs_srte.[dbo].code_value_general cvg WITH (NOLOCK) 
            ON cvg.code_set_nm = cd.code_set_nm
            AND  cvg.code = @srte_code
            AND  @srte_code IS NOT NULL;