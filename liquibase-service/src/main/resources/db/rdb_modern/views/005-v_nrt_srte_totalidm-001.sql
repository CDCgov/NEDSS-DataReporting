IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_srte_totalidm')
BEGIN
    DROP VIEW [dbo].v_nrt_srte_totalidm
END
--GO   "GO" not supported by liquibase, keep in manual scripts

CREATE VIEW [dbo].v_nrt_srte_totalidm 
AS
SELECT 
    unique_cd,
    SRT_reference,
    format,
    label
FROM [dbo].nrt_srte_TotalIDM WITH (NOLOCK);