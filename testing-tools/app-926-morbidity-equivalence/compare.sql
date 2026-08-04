/*  APP-926 equivalence compare.
    Assumes dbo.orig_1..8 and dbo.new_1..8 already captured.
    Full-row set difference BOTH directions via EXCEPT (NULL-safe).
    PASS = equal row counts AND zero diff both ways.
*/
SET NOCOUNT ON;

CREATE TABLE #res (sc INT, orig_rows INT, new_rows INT, o_minus_n INT, n_minus_o INT, verdict VARCHAR(6));

DECLARE @i INT = 1;
WHILE @i <= 8
BEGIN
    DECLARE @o TABLE(x INT); DECLARE @sql NVARCHAR(MAX);
    DECLARE @orig INT, @new INT, @omn INT, @nmo INT;
    SET @sql = N'
        SELECT @orig = (SELECT COUNT(*) FROM dbo.orig_' + CAST(@i AS VARCHAR) + N'),
               @new  = (SELECT COUNT(*) FROM dbo.new_'  + CAST(@i AS VARCHAR) + N'),
               @omn  = (SELECT COUNT(*) FROM (SELECT * FROM dbo.orig_' + CAST(@i AS VARCHAR) + N' EXCEPT SELECT * FROM dbo.new_' + CAST(@i AS VARCHAR) + N') a),
               @nmo  = (SELECT COUNT(*) FROM (SELECT * FROM dbo.new_'  + CAST(@i AS VARCHAR) + N' EXCEPT SELECT * FROM dbo.orig_' + CAST(@i AS VARCHAR) + N') b);';
    EXEC sp_executesql @sql,
        N'@orig INT OUTPUT,@new INT OUTPUT,@omn INT OUTPUT,@nmo INT OUTPUT',
        @orig=@orig OUTPUT,@new=@new OUTPUT,@omn=@omn OUTPUT,@nmo=@nmo OUTPUT;
    INSERT INTO #res VALUES (@i,@orig,@new,@omn,@nmo,
        CASE WHEN @orig=@new AND @omn=0 AND @nmo=0 THEN 'PASS' ELSE 'FAIL' END);
    SET @i += 1;
END

SELECT
    sc AS scenario,
    CASE sc WHEN 1 THEN 'obs-only' WHEN 2 THEN 'pat-only' WHEN 3 THEN 'prov-only'
            WHEN 4 THEN 'org-only' WHEN 5 THEN 'inv-only' WHEN 6 THEN 'mixed'
            WHEN 7 THEN 'empty' WHEN 8 THEN 'junk-obs' END AS name,
    orig_rows, new_rows, o_minus_n AS diff_orig_minus_new, n_minus_o AS diff_new_minus_orig, verdict
FROM #res ORDER BY sc;
