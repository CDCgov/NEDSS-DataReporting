IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_srte_imrdbmapping')
BEGIN
    DROP VIEW [dbo].v_nrt_srte_imrdbmapping
END
GO

CREATE VIEW [dbo].v_nrt_srte_imrdbmapping 
AS
SELECT 
    *
FROM [dbo].nrt_srte_IMRDBMapping WITH (NOLOCk);