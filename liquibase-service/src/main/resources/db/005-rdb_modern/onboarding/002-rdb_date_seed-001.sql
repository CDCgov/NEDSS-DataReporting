-- Populate RDB_DATE using the canonical date-dimension procedure.
IF OBJECT_ID('dbo.sp_get_date_dim', 'P') IS NOT NULL
BEGIN
    EXEC dbo.sp_get_date_dim @start = 1990, @end = 2030;
END
GO
