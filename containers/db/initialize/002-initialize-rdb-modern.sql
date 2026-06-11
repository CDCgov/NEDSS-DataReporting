USE [NBS_ODSE];
-- Insert into NBS_ODSE.NBS_Configuration to flag use of RDB_MODERN
IF (SELECT config_value FROM NBS_configuration WHERE config_key = 'ENV') IS NULL
BEGIN
    INSERT INTO
        NBS_configuration (
        config_key,
        config_value,
        version_ctrl_nbr,
        add_user_id,
        add_time,
        last_chg_user_id,
        last_chg_time,
        status_cd,
        status_time
        )
    VALUES
        ('ENV', 'UAT', 1, 99999999, GETDATE(), 99999999, GETDATE(), 'A', GETDATE());
END
