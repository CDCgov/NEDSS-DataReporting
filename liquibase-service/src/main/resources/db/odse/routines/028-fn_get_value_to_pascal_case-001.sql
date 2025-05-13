CREATE or ALTER FUNCTION dbo.fn_get_value_to_pascal_case (
    @Input nvarchar(200)
)
RETURNS nvarchar(200)
AS
BEGIN
    DECLARE @Result nvarchar(200);

    SELECT @Result = STRING_AGG(
        CONCAT(UPPER(LEFT(value, 1)), LOWER(SUBSTRING(value, 2, LEN(value)))),
        ' '
    )
    FROM STRING_SPLIT(@Input, ' ');

    RETURN @Result;
END;
