  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_summary_case_group_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'SUMMARY_CASE_GROUP' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'SUMMARY_REPORT_CASE' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'INVESTIGATION' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Act_relationship')
     AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Observation')
    BEGIN
        
        --copy already existing (SUMMARY_CASE_SRC_KEY) from SUMMARY_CASE_GROUP,
        --MAX(CASE_UID) as public_health_case_uid from INVESTIGATION
        --MAX(source_act_uid) as ovc_observation_uid from Observation
        --all grouped by SUMMARY_CASE_SRC_KEY

        SET IDENTITY_INSERT [dbo].nrt_summary_case_group_key ON

        INSERT INTO [dbo].nrt_summary_case_group_key(
			summary_case_src_key, 
			public_health_case_uid,
            ovc_observation_uid
        )
        select 
            scg.SUMMARY_CASE_SRC_KEY,
            MAX(inv.CASE_UID) AS public_health_case_uid,
            MAX(ar2.source_act_uid) as ovc_observation_uid
        from dbo.summary_case_group scg
            LEFT JOIN dbo.SUMMARY_REPORT_CASE src
                ON scg.SUMMARY_CASE_SRC_KEY = src.SUMMARY_CASE_SRC_KEY
            LEFT JOIN dbo.INVESTIGATION inv
                ON inv.INVESTIGATION_KEY = src.INVESTIGATION_KEY
            LEFT JOIN NBS_ODSE.dbo.Act_relationship ar1
                ON ar1.target_act_uid = inv.CASE_UID
            LEFT JOIN NBS_ODSE.dbo.Act_relationship ar2
                ON ar1.source_act_uid = ar2.target_act_uid
            INNER JOIN NBS_ODSE.dbo.Observation obs
                ON ar2.source_act_uid = obs.observation_uid AND obs.cd = 'SUM103'
            LEFT JOIN dbo.nrt_summary_case_group_key k
                ON scg.SUMMARY_CASE_SRC_KEY = k.summary_case_src_key
                AND inv.CASE_UID = k.public_health_case_uid
                AND ar2.source_act_uid = k.ovc_observation_uid
        WHERE src.SUMMARY_CASE_SRC_KEY != 1
                AND k.summary_case_src_key IS NULL
                AND k.public_health_case_uid IS NULL
                AND k.ovc_observation_uid IS NULL 
        GROUP BY scg.SUMMARY_CASE_SRC_KEY
        ORDER BY scg.SUMMARY_CASE_SRC_KEY;

        SET IDENTITY_INSERT [dbo].nrt_summary_case_group_key OFF
        
    END

