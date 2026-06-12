IF EXISTS (SELECT * FROM   sys.objects WHERE  
    object_id = OBJECT_ID(N'[dbo].[fn_get_value_by_cvg]')
    AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[fn_get_value_by_cvg]
GO 

CREATE FUNCTION [dbo].fn_get_value_by_cvg(
    @srte_code NVARCHAR(200),
    @cvg_str NVARCHAR(200)
)
    RETURNS TABLE
        AS RETURN

        SELECT cvg.code_short_desc_txt
        FROM nbs_srte.[dbo].code_value_general cvg WITH (NOLOCK)
        WHERE 
            cvg.code_set_nm = @cvg_str
            AND @srte_code = cvg.code
            AND @srte_code IS NOT NULL;