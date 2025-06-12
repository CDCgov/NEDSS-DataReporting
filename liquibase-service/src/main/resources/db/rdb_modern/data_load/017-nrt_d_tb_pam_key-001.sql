IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_tb_pam_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_TB_PAM' and xtype = 'U')
    BEGIN

        SET IDENTITY_INSERT [dbo].nrt_d_tb_pam_key ON

        INSERT INTO [dbo].nrt_d_tb_pam_key(
            d_tb_pam_key, tb_pam_uid
        )
        select d.d_tb_pam_key,
            d.tb_pam_uid
        from dbo.d_tb_pam d with (nolock)
        left join dbo.nrt_d_tb_pam_key k
            on k.D_TB_PAM_KEY = d.D_TB_PAM_KEY AND
            k.TB_PAM_UID = d.TB_PAM_UID
        where k.D_TB_PAM_KEY is null and k.TB_PAM_UID is null
        order by d.d_tb_pam_key;

        SET IDENTITY_INSERT [dbo].nrt_d_tb_pam_key OFF

    END