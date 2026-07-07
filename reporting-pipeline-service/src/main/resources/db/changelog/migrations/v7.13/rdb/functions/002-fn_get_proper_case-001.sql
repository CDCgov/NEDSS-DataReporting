IF EXISTS (SELECT * FROM   sys.objects WHERE  
    object_id = OBJECT_ID(N'[dbo].[fn_get_proper_case]')
    AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[fn_get_proper_case]
GO 

CREATE FUNCTION [dbo].fn_get_proper_case(
    @txt AS NVARCHAR(MAX)
)
    RETURNS NVARCHAR(MAX)
    AS
    BEGIN
        DECLARE @reset BIT;
        DECLARE @ret NVARCHAR(MAX);
        DECLARE @i INT;
        DECLARE @c CHAR(1);

        SELECT @Reset = 1, @i=1, @Ret = '';
        
        WHILE (@i <= LEN(@txt))
            SELECT 
                @c= SUBSTRING(@txt,@i,1),
                @ret = @ret + CASE WHEN @reset=1 THEN UPPER(@c) ELSE LOWER(@c) END,
                @reset = CASE WHEN @c LIKE '[a-zA-Z]' THEN 0 ELSE 1 END,
                @i = @i +1
        
        RETURN @ret;
    END