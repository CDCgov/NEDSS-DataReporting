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
            max(ar1.source_act_uid) as NOTIFICATION_UID
        FROM [dbo].[NOTIFICATION] notif WITH(NOLOCK)
        LEFT JOIN [dbo].NOTIFICATION_EVENT notif_event WITH(NOLOCK)
            ON notif.NOTIFICATION_KEY = notif_event.NOTIFICATION_KEY
        LEFT JOIN [dbo].INVESTIGATION inv WITH(NOLOCK)
            ON inv.INVESTIGATION_KEY = notif_event.INVESTIGATION_KEY
        INNER JOIN NBS_ODSE.[dbo].Act_relationship ar1 WITH(NOLOCK)
            ON inv.CASE_UID = ar1.target_act_uid
            AND ar1.target_class_cd = 'CASE'
            AND ar1.source_class_cd = 'NOTF'
        INNER JOIN NBS_ODSE.[dbo].NOTIFICATION n WITH(NOLOCK)
            ON ar1.source_act_uid = n.notification_uid
        LEFT JOIN [dbo].nrt_notification_key k
            ON k.D_NOTIFICATION_KEY = notif.NOTIFICATION_KEY
            AND COALESCE(k.NOTIFICATION_UID, 1) = COALESCE(ar1.source_act_uid, 1)
        WHERE k.D_NOTIFICATION_KEY IS NULL AND k.NOTIFICATION_UID IS NULL
            AND n.cd not in ('EXP_NOTF', 'SHARE_NOTF', 'EXP_NOTF_PHDC','SHARE_NOTF_PHDC')
        GROUP BY notif.NOTIFICATION_KEY
        ORDER BY notif.NOTIFICATION_KEY;
            

        SET IDENTITY_INSERT [dbo].nrt_notification_key OFF
        
    END
