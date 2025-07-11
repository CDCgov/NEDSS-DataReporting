  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_notification_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'NOTIFICATION' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'NOTIFICATION_EVENT' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'INVESTIGATION' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Act_relationship')
    BEGIN
        
        --copy already existing (NOTIFICATION_KEY) from NOTIFICATION,
        --SOURCE_ACT_UID as NOTIFICATION_UID from NBS_ODSE.dbo.Act_relationship

        SET IDENTITY_INSERT [dbo].nrt_notification_key ON

        INSERT INTO [dbo].nrt_notification_key(
			D_NOTIFICATION_KEY, 
			NOTIFICATION_UID
        )
        SELECT 
            notif.NOTIFICATION_KEY, 
            ar1.source_act_uid
        FROM [dbo].[NOTIFICATION] notif WITH(NOLOCK) 
        LEFT JOIN [dbo].NOTIFICATION_EVENT notif_event 
            ON notif.NOTIFICATION_KEY = notif_event.NOTIFICATION_KEY
        LEFT JOIN [dbo].INVESTIGATION inv
            ON inv.INVESTIGATION_KEY = notif_event.INVESTIGATION_KEY
        INNER JOIN NBS_ODSE.dbo.Act_relationship ar1
            ON inv.CASE_UID = ar1.target_act_uid
            AND ar1.target_class_cd = 'CASE'
            AND ar1.source_class_cd = 'NOTF'
        LEFT JOIN [dbo].nrt_notification_key k
          ON k.D_NOTIFICATION_KEY = notif.NOTIFICATION_KEY AND COALESCE(k.NOTIFICATION_UID, 1) = COALESCE(ar1.source_act_uid, 1)
        WHERE k.D_NOTIFICATION_KEY IS NULL AND k.NOTIFICATION_UID IS NULL
            ORDER BY notif.NOTIFICATION_KEY;

        SET IDENTITY_INSERT [dbo].nrt_notification_key OFF
        
    END

