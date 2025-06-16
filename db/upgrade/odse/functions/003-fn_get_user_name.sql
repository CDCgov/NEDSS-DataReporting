IF EXISTS (SELECT * FROM   sys.objects WHERE  
    object_id = OBJECT_ID(N'[dbo].[fn_get_user_name]')
    AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[fn_get_user_name]
GO 

CREATE FUNCTION [dbo].fn_get_user_name(
    @user_id AS BIGINT
)
    RETURNS TABLE
        AS RETURN
        
        SELECT CAST((RTRIM(LTRIM(au.user_last_nm)) + ', ' +
                     RTRIM(LTRIM(au.user_first_nm))) AS VARCHAR(150)) AS user_full_name
        FROM NBS_ODSE.[dbo].Auth_user au WITH (NOLOCK)
        WHERE au.NEDSS_ENTRY_ID = @user_id;