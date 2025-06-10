IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_srte_codeset')
BEGIN
    DROP VIEW [dbo].v_nrt_srte_codeset
END
GO

CREATE VIEW [dbo].v_nrt_srte_codeset 
AS
SELECT 
    *
FROM [dbo].nrt_srte_Codeset;