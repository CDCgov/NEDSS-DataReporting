IF EXISTS ( SELECT 1 FROM RDB.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'REF_FORMCODE_TRANSLATION') AND
   EXISTS ( SELECT 1 FROM RDB_MODERN.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'REF_FORMCODE_TRANSLATION') 
 BEGIN
    -- Add missing rows to RDB_MODERN
    ;WITH 
    missing_in_rdb_modern AS 
    (
        SELECT 
            PAGE_CODE_SET_NM,
            INVESTIGATION_FORM_CD,
            CODE_SET_NM,
            CODE,
            CODE_SHORT_DESC_TXT,
            CODE_SET_GROUP_ID,
            QUESTION_IDENTIFIER,
            NBS_QUESTION_UID
        FROM [rdb].[dbo].REF_FORMCODE_TRANSLATION WITH(NOLOCK)
        EXCEPT
        SELECT 
            PAGE_CODE_SET_NM,
            INVESTIGATION_FORM_CD,
            CODE_SET_NM,
            CODE,
            CODE_SHORT_DESC_TXT,
            CODE_SET_GROUP_ID,
            QUESTION_IDENTIFIER,
            NBS_QUESTION_UID
        FROM [rdb_modern].[dbo].REF_FORMCODE_TRANSLATION WITH(NOLOCK)
    )
    INSERT INTO [rdb_modern].[dbo].REF_FORMCODE_TRANSLATION (
        PAGE_CODE_SET_NM,
        INVESTIGATION_FORM_CD,
        CODE_SET_NM,
        CODE,
        CODE_SHORT_DESC_TXT,
        CODE_SET_GROUP_ID,
        QUESTION_IDENTIFIER,
        NBS_QUESTION_UID)
    SELECT 
        PAGE_CODE_SET_NM,
        INVESTIGATION_FORM_CD,
        CODE_SET_NM,
        CODE,
        CODE_SHORT_DESC_TXT,
        CODE_SET_GROUP_ID,
        QUESTION_IDENTIFIER,
        NBS_QUESTION_UID
    FROM missing_in_rdb_modern; 

    -- Remove extra rows from RDB_MODERN
    ;WITH 
    extra_in_rdb_modern AS 
    (
        SELECT 
            PAGE_CODE_SET_NM,
            INVESTIGATION_FORM_CD,
            CODE_SET_NM,
            CODE,
            CODE_SHORT_DESC_TXT,
            CODE_SET_GROUP_ID,
            QUESTION_IDENTIFIER,
            NBS_QUESTION_UID
        FROM [rdb_modern].[dbo].REF_FORMCODE_TRANSLATION WITH(NOLOCK)
        EXCEPT
        SELECT 
            PAGE_CODE_SET_NM,
            INVESTIGATION_FORM_CD,
            CODE_SET_NM,
            CODE,
            CODE_SHORT_DESC_TXT,
            CODE_SET_GROUP_ID,
            QUESTION_IDENTIFIER,
            NBS_QUESTION_UID
        FROM [rdb].[dbo].REF_FORMCODE_TRANSLATION WITH(NOLOCK)
    )
    DELETE RFT
    FROM [rdb_modern].[dbo].REF_FORMCODE_TRANSLATION RFT 
    INNER JOIN extra_in_rdb_modern e
        ON  e.PAGE_CODE_SET_NM      = RFT.PAGE_CODE_SET_NM
        AND e.INVESTIGATION_FORM_CD = RFT.INVESTIGATION_FORM_CD
        AND e.CODE_SET_NM           = RFT.CODE_SET_NM
        AND e.CODE                  = RFT.CODE
        AND e.CODE_SHORT_DESC_TXT   = RFT.CODE_SHORT_DESC_TXT
        AND e.CODE_SET_GROUP_ID     = RFT.CODE_SET_GROUP_ID
        AND e.QUESTION_IDENTIFIER   = RFT.QUESTION_IDENTIFIER
        AND e.NBS_QUESTION_UID      = RFT.NBS_QUESTION_UID;

 END  
