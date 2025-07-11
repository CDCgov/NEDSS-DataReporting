IF EXISTS (SELECT * FROM   sys.objects WHERE  
    object_id = OBJECT_ID(N'[dbo].[fn_get_record_status]')
    AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[fn_get_record_status]
GO 

CREATE FUNCTION [dbo].fn_get_record_status (
    @record_status_cd nvarchar(100)
)
    RETURNS NVARCHAR(200)
    AS
    BEGIN
        -- get the record status by code
        -- Other than LOG_DEL rest of them are all ACTIVE
        SELECT  @record_status_cd =
            CASE
                WHEN @record_status_cd = 'LOG_DEL' THEN  'INACTIVE'
                WHEN @record_status_cd = 'SUPERCEDED' THEN  'INACTIVE'
                WHEN @record_status_cd = 'INACTIVE' THEN 'INACTIVE'
                ELSE 'ACTIVE'
            END
            
        RETURN @record_status_cd;
    END