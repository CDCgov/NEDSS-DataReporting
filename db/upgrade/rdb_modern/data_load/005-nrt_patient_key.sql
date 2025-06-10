  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_patient_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_PATIENT' and xtype = 'U')
    BEGIN
        
        --copy already existing (PATIENT_KEY, PATIENT_UID) from D_PATIENT

        SET IDENTITY_INSERT [dbo].nrt_patient_key ON

        INSERT INTO [dbo].nrt_patient_key(
			D_PATIENT_KEY, 
			PATIENT_UID
        )
        SELECT 
			pat.PATIENT_KEY, 
			pat.PATIENT_UID
        FROM [dbo].D_PATIENT pat WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_patient_key k
          ON k.D_PATIENT_KEY = pat.PATIENT_KEY AND COALESCE(k.PATIENT_UID, 1) = COALESCE(pat.PATIENT_UID, 1)
        WHERE k.D_PATIENT_KEY IS NULL AND k.PATIENT_UID IS NULL
            ORDER BY pat.PATIENT_KEY;

        SET IDENTITY_INSERT [dbo].nrt_patient_key OFF
        
    END

