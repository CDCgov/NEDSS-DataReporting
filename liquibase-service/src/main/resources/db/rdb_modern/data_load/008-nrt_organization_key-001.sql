  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_organization_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_ORGANIZATION' and xtype = 'U')
    BEGIN
        
        --copy already existing (ORGANIZATION_KEY, ORGANIZATION_UID) from D_ORGANIZATION

        SET IDENTITY_INSERT [dbo].nrt_organization_key ON

        INSERT INTO [dbo].nrt_organization_key(
			d_organization_key, 
			organization_uid
        )
        SELECT 
			org.ORGANIZATION_KEY, 
			org.ORGANIZATION_UID
        FROM [dbo].D_ORGANIZATION org WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_organization_key k
          ON k.d_organization_key = org.ORGANIZATION_KEY AND COALESCE(k.organization_uid, 1) = COALESCE(org.ORGANIZATION_UID, 1)
        WHERE k.d_organization_key IS NULL AND k.organization_uid IS NULL
            ORDER BY org.ORGANIZATION_KEY;

        SET IDENTITY_INSERT [dbo].nrt_organization_key OFF
        
    END

