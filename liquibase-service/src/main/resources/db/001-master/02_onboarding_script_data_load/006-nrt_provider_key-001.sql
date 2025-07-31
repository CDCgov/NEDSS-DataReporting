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


IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_provider_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_PROVIDER' and xtype = 'U')
    BEGIN
        
        --copy already existing (D_PROVIDER_KEY, PROVIDER_UID) from D_PROVIDER

        SET IDENTITY_INSERT [dbo].nrt_provider_key ON

        INSERT INTO [dbo].nrt_provider_key(
			D_PROVIDER_KEY, 
			PROVIDER_UID
        )
        SELECT 
			prov.PROVIDER_KEY, 
			prov.PROVIDER_UID
        FROM [dbo].D_PROVIDER prov WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_provider_key k
          ON k.D_PROVIDER_KEY = prov.PROVIDER_KEY AND COALESCE(k.PROVIDER_UID, 1) = COALESCE(prov.PROVIDER_UID, 1)
        WHERE k.D_PROVIDER_KEY IS NULL AND k.PROVIDER_UID IS NULL
            ORDER BY prov.PROVIDER_KEY;

        SET IDENTITY_INSERT [dbo].nrt_provider_key OFF
        
    END

