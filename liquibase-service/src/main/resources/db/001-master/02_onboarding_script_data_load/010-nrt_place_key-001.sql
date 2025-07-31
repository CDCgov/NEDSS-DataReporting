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

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_place_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_PLACE' and xtype = 'U')
    BEGIN
        
        --copy already existing (PLACE_KEY, PLACE_UID, PLACE_LOCATOR_UID) from D_PLACE

        SET IDENTITY_INSERT [dbo].nrt_place_key ON

        INSERT INTO [dbo].nrt_place_key(
			d_place_key, 
			place_uid,
            place_locator_uid
        )
        SELECT 
			pl.PLACE_KEY, 
			pl.PLACE_UID,
            pl.PLACE_LOCATOR_UID
        FROM [dbo].D_PLACE pl WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_place_key k
          ON k.d_place_key = pl.PLACE_KEY 
          AND k.place_uid = pl.PLACE_UID
          AND k.place_locator_uid = pl.PLACE_LOCATOR_UID
        WHERE k.d_place_key IS NULL AND k.place_uid IS NULL AND k.place_locator_uid IS NULL
            ORDER BY pl.PLACE_KEY;

        SET IDENTITY_INSERT [dbo].nrt_place_key OFF
        
    END
