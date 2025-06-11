
IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_srte_code_value_general')
BEGIN
    DROP VIEW [dbo].v_nrt_srte_code_value_general
END
