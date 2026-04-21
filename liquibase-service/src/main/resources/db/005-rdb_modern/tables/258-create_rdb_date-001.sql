-- Create RDB_DATE reference table if it does not yet exist.

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'RDB_DATE' AND xtype = 'U')
BEGIN
    CREATE TABLE RDB_DATE (
        DATE_MM_DD_YYYY      datetime,
        DAY_OF_WEEK          varchar(10),
        DAY_NBR_IN_CLNDR_MON numeric(4, 0),
        DAY_NBR_IN_CLNDR_YR  numeric(4, 0),
        WK_NBR_IN_CLNDR_MON  numeric(4, 0),
        WK_NBR_IN_CLNDR_YR   numeric(4, 0),
        CLNDR_MON_NAME       varchar(20),
        CLNDR_MON_IN_YR      numeric(4, 0),
        CLNDR_QRTR           numeric(4, 0),
        CLNDR_YR             numeric(18, 0),
        DATE_KEY             bigint NOT NULL PRIMARY KEY
    )
END

-- Insert NULL row (key = 1) if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM RDB_DATE WHERE DATE_KEY = 1)
BEGIN
    INSERT INTO RDB_DATE (DATE_KEY) VALUES (1)
END

