  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'L_INTERVIEW' and xtype = 'U')
    BEGIN
        
        --copy already existing (D_INTERVIEW_KEY, INTERVIEW_UID) from L_INTERVIEW

        SET IDENTITY_INSERT [dbo].nrt_interview_key ON

        INSERT INTO [dbo].nrt_interview_key(
			D_INTERVIEW_KEY, 
			INTERVIEW_UID
        )
        SELECT 
			ix.D_INTERVIEW_KEY, 
			ix.INTERVIEW_UID
        FROM [dbo].L_INTERVIEW ix WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_interview_key k
          ON k.D_INTERVIEW_KEY = ix.D_INTERVIEW_KEY AND k.INTERVIEW_UID= ix.INTERVIEW_UID
        WHERE k.D_INTERVIEW_KEY IS NULL AND k.INTERVIEW_UID IS NULL
            ORDER BY ix.D_INTERVIEW_KEY;

        SET IDENTITY_INSERT [dbo].nrt_interview_key OFF
        
    END