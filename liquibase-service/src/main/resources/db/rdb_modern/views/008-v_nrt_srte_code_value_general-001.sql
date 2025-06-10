IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_srte_code_value_general')
BEGIN
    DROP VIEW [dbo].v_nrt_srte_code_value_general
END
GO

CREATE VIEW [dbo].v_nrt_srte_code_value_general 
AS
SELECT 
    *
FROM [dbo].nrt_srte_Code_value_general;