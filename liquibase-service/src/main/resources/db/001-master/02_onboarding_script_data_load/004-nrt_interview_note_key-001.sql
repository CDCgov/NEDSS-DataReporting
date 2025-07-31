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

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_note_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'L_INTERVIEW_NOTE' and xtype = 'U')
    BEGIN
        
        --copy already existing (D_INTERVIEW_KEY, D_INTERVIEW_NOTE_KEY, NBS_ANSWER_UID) from L_INTERVIEW_NOTE

        SET IDENTITY_INSERT [dbo].nrt_interview_note_key ON

        INSERT INTO [dbo].nrt_interview_note_key(
			D_INTERVIEW_KEY,
            D_INTERVIEW_NOTE_KEY, 
			NBS_ANSWER_UID
        )
        SELECT
			ix.D_INTERVIEW_KEY, 
            ix.D_INTERVIEW_NOTE_KEY,
			ix.NBS_ANSWER_UID
        FROM [dbo].L_INTERVIEW_NOTE ix WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_interview_note_key k
          ON k.D_INTERVIEW_KEY = ix.D_INTERVIEW_KEY 
          AND k.D_INTERVIEW_NOTE_KEY = ix.D_INTERVIEW_NOTE_KEY
          AND k.NBS_ANSWER_UID = ix.NBS_ANSWER_UID
        WHERE k.D_INTERVIEW_KEY IS NULL AND k.D_INTERVIEW_NOTE_KEY IS NULL AND k.NBS_ANSWER_UID IS NULL
            ORDER BY ix.D_INTERVIEW_NOTE_KEY;

        SET IDENTITY_INSERT [dbo].nrt_interview_note_key OFF
        
    END