-- patch for CRS013 code being improperly labeled as a date value
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'IMRDBMapping' and xtype = 'U')
BEGIN

    update dbo.IMRDBMapping
        SET DB_table = 'Obs_value_numeric',
            DB_field = 'numeric_value_1'
        WHERE unique_cd = 'CRS013'
              AND DB_table = 'Obs_value_date'
              AND DB_field = 'from_time';

END;

