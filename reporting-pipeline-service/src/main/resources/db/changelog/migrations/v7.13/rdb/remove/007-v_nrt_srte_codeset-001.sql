
IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_srte_codeset')
BEGIN
    DROP VIEW [dbo].v_nrt_srte_codeset
END
