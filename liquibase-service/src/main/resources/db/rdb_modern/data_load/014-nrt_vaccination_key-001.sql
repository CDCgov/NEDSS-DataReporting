IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_vaccination_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_VACCINATION' and xtype = 'U')
    BEGIN

        SET IDENTITY_INSERT [dbo].nrt_vaccination_key ON

        INSERT INTO [dbo].nrt_vaccination_key(
            d_vaccination_key, vaccination_uid
        )
        SELECT 
            dv.d_vaccination_key,
            dv.vaccination_uid as vaccination_uid
        FROM [dbo].D_VACCINATION dv WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_vaccination_key k WITH(NOLOCK)
            ON k.d_vaccination_key = dv.d_vaccination_key 
            and k.vaccination_uid= dv.vaccination_uid
        WHERE 
            k.d_vaccination_key IS NULL 
            AND k.vaccination_uid IS NULL and dv.d_vaccination_key<>1
        order by dv.d_vaccination_key;

        SET IDENTITY_INSERT [dbo].nrt_vaccination_key OFF

    END