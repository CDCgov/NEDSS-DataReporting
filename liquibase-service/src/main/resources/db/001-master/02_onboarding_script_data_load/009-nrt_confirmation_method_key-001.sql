  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_confirmation_method_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'CONFIRMATION_METHOD' and xtype = 'U')
    BEGIN
        
        --copy already existing (CONFIRMATION_METHOD_KEY, CONFIRMATION_METHOD_CD) from CONFIRMATION_METHOD

        SET IDENTITY_INSERT [dbo].nrt_confirmation_method_key ON

        INSERT INTO [dbo].nrt_confirmation_method_key(
			d_confirmation_method_key, 
			confirmation_method_cd
        )
        SELECT 
			cm.CONFIRMATION_METHOD_KEY, 
			cm.CONFIRMATION_METHOD_CD
        FROM [dbo].CONFIRMATION_METHOD cm WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_confirmation_method_key k
          ON k.d_confirmation_method_key = cm.CONFIRMATION_METHOD_KEY AND COALESCE(k.confirmation_method_cd, '') = COALESCE(cm.confirmation_method_cd, '')
        WHERE k.d_confirmation_method_key IS NULL AND k.confirmation_method_cd IS NULL
            ORDER BY cm.CONFIRMATION_METHOD_KEY;

        SET IDENTITY_INSERT [dbo].nrt_confirmation_method_key OFF
        
    END


