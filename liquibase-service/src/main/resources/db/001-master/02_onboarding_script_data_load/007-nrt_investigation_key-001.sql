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

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'INVESTIGATION' and xtype = 'U')
    BEGIN
        
        --copy already existing (INVESTIGATION_KEY, CASE_UID) from INVESTIGATION

        SET IDENTITY_INSERT [dbo].nrt_investigation_key ON

        INSERT INTO [dbo].nrt_investigation_key(
			d_investigation_key, 
			case_uid
        )
        SELECT 
			inv.INVESTIGATION_KEY, 
			inv.CASE_UID
        FROM [dbo].INVESTIGATION inv WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_investigation_key k
          ON k.d_investigation_key = inv.INVESTIGATION_KEY AND COALESCE(k.case_uid, 1) = COALESCE(inv.CASE_UID, 1)
        WHERE k.d_investigation_key IS NULL AND k.case_uid IS NULL
            ORDER BY inv.INVESTIGATION_KEY;

        SET IDENTITY_INSERT [dbo].nrt_investigation_key OFF
        
    END

