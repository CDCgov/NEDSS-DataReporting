IF EXISTS (SELECT * FROM   sys.objects WHERE  
    object_id = OBJECT_ID(N'[dbo].[fn_get_value_to_pascal_case]')
    AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[fn_get_value_to_pascal_case]
GO 

CREATE FUNCTION [dbo].fn_get_value_to_pascal_case (
    @Input NVARCHAR(200)
)
    RETURNS NVARCHAR(200)
    AS
    BEGIN
        DECLARE @Result NVARCHAR(200);

        SELECT @Result = STRING_AGG(
            CONCAT(UPPER(LEFT(value, 1)), LOWER(SUBSTRING(value, 2, LEN(value)))),
            ' '
        )
        FROM STRING_SPLIT(@Input, ' ');

        RETURN @Result;
    END
