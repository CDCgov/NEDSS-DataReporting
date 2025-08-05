-- use rdb_modern;
IF EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV' AND config_value ='UAT')
    BEGIN
        USE [rdb_modern];
        PRINT 'Switched to database [rdb_modern]'
    END
ELSE
    BEGIN
        USE [rdb];
        PRINT 'Switched to database [rdb]';
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_var_pam_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_VAR_PAM' and xtype = 'U')
    BEGIN

        SET IDENTITY_INSERT [dbo].nrt_var_pam_key ON

        INSERT INTO [dbo].nrt_var_pam_key(
            d_var_pam_key, var_pam_uid
        )
        select d.d_var_pam_key,
            d.var_pam_uid
        from dbo.d_var_pam d with (nolock)
        left join dbo.nrt_var_pam_key k
            on k.D_VAR_PAM_KEY = d.D_VAR_PAM_KEY AND
            k.VAR_PAM_UID = d.VAR_PAM_UID
        where k.D_VAR_PAM_KEY is null and k.VAR_PAM_UID is null
        order by d.d_var_pam_key;

        SET IDENTITY_INSERT [dbo].nrt_var_pam_key OFF

    END