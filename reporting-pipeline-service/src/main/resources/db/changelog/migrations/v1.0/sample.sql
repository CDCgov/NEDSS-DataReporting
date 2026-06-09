USE [NBS_ODSE];

IF (SELECT config_value FROM NBS_configuration WHERE config_key = 'EXAMPLE') IS NULL
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
        ('EXAMPLE', 'EXAMPLE', 1, 99999999, GETDATE(), 99999999, GETDATE(), 'A', GETDATE());
END

USE [RDB_MODERN]; -- Have to switch back to RDB_MODERN or else Liquibase gets angry
