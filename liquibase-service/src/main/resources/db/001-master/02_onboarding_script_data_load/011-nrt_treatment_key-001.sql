  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_treatment_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'TREATMENT' and xtype = 'U')
    BEGIN
        
        --copy already existing (TREATMENT_KEY, TREATMENT_UID) from TREATMENT

        SET IDENTITY_INSERT [dbo].nrt_treatment_key ON

        INSERT INTO [dbo].nrt_treatment_key(
			D_TREATMENT_KEY, 
			TREATMENT_UID
        )
        SELECT 
			tr.TREATMENT_KEY, 
			tr.TREATMENT_UID
        FROM [dbo].TREATMENT tr WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_treatment_key k
          ON k.D_TREATMENT_KEY = tr.TREATMENT_KEY AND COALESCE(k.TREATMENT_UID, 1) = COALESCE(tr.TREATMENT_UID, 1)
        WHERE k.D_TREATMENT_KEY IS NULL AND k.TREATMENT_UID IS NULL
            ORDER BY tr.TREATMENT_KEY;

        SET IDENTITY_INSERT [dbo].nrt_treatment_key OFF
        
    END

