IF EXISTS (SELECT * FROM   sys.objects WHERE  
    object_id = OBJECT_ID(N'[dbo].[fn_get_value_by_cd_ques]')
    AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[fn_get_value_by_cd_ques]
GO 

CREATE FUNCTION [dbo].fn_get_value_by_cd_ques(
    @srte_code NVARCHAR(200),
    @ques_identifier NVARCHAR(200)
)
    RETURNS TABLE
        AS RETURN

        SELECT
            cvg.code_short_desc_txt
        FROM nbs_odse.[dbo].nbs_question nq WITH (NOLOCK)
        JOIN nbs_srte.[dbo].codeset cd WITH (NOLOCK) 
            ON cd.code_set_group_id = nq.code_set_group_id
        JOIN nbs_srte.[dbo].code_value_general cvg WITH (NOLOCK) 
            ON cvg.code_set_nm = cd.code_set_nm
            AND nq.question_identifier = (@ques_identifier)
            AND @srte_code = cvg.code
            AND @srte_code IS NOT NULL
        UNION
        SELECT
            cvg.code_short_desc_txt
        FROM
            nbs_odse.[dbo].nbs_question nq WITH (NOLOCK),
            nbs_srte.[dbo].codeset cd WITH (NOLOCK),
            nbs_srte.[dbo].naics_industry_code cvg WITH (NOLOCK)
        WHERE
            nq.question_identifier = (@ques_identifier)
            AND @ques_identifier = 'DEM139'
            AND cd.code_set_group_id = nq.code_set_group_id
            AND cvg.code_set_nm = cd.code_set_nm
            AND @srte_code = cvg.code
            AND @srte_code IS NOT NULL
        UNION
        SELECT
            cvg.code_short_desc_txt
        FROM
            nbs_odse.[dbo].nbs_question nq WITH (NOLOCK),
            nbs_srte.[dbo].codeset cd WITH (NOLOCK),
            nbs_srte.[dbo].language_code cvg WITH (NOLOCK)
        WHERE
            nq.question_identifier = (@ques_identifier)
            AND @ques_identifier = 'DEM142'
            AND cd.code_set_group_id = nq.code_set_group_id
            AND cvg.code_set_nm = cd.code_set_nm
            AND @srte_code = cvg.code
            AND @srte_code IS NOT NULL;