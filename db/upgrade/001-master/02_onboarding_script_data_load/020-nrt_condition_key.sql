  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_condition_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'CONDITION' and xtype = 'U')
    BEGIN
        
        --copy already existing (CONDITION_KEY, CONDITION_CD, PROGRAM_AREA_CD) from CONDITION

        SET IDENTITY_INSERT [dbo].nrt_condition_key ON

        INSERT INTO [dbo].nrt_condition_key(
			CONDITION_KEY, 
			CONDITION_CD,
            PROGRAM_AREA_CD
        )
        SELECT 
			c.CONDITION_KEY, 
			c.CONDITION_CD,
            c.PROGRAM_AREA_CD
        FROM [dbo].CONDITION c WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_condition_key k
            ON k.CONDITION_KEY = c.CONDITION_KEY
                AND COALESCE(k.CONDITION_CD, '') = COALESCE(c.CONDITION_CD, '')
                AND COALESCE(k.PROGRAM_AREA_CD, '') = COALESCE(c.PROGRAM_AREA_CD, '')
        WHERE k.CONDITION_KEY IS NULL AND k.CONDITION_CD IS NULL AND k.PROGRAM_AREA_CD IS NULL
            ORDER BY c.CONDITION_KEY;

        SET IDENTITY_INSERT [dbo].nrt_condition_key OFF
        
    END
