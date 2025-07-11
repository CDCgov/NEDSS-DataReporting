
IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_condition_dim')
BEGIN
    DROP VIEW [dbo].v_condition_dim
END
