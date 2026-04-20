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

DECLARE @date DATE = '1990-01-01'
DECLARE @endDate DATE = '2030-12-31'
DECLARE @key bigint = 2
DECLARE @wk_nbr_in_mon numeric(4,0)
SET DATEFIRST 6

WHILE @date <= @endDate
BEGIN
    IF NOT EXISTS (SELECT 1 FROM RDB_DATE WHERE DATE_MM_DD_YYYY = @date)
    BEGIN
        --IF DATENAME(WEEKDAY, @date) = 'Saturday'
        --    SET @wk_nbr_in_mon = DATEDIFF(WEEK, DATEADD(DAY, 1 - DAY(@date), @date), @date) + 2
        --ELSE
        -- SET @wk_nbr_in_mon = DATEDIFF(WEEK, DATEADD(DAY, 1 - DAY(@date), @date), @date) + 1
        SET @wk_nbr_in_mon = DATEDIFF(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, @date), 0), @date) + 1 

        INSERT INTO RDB_DATE (
            DATE_MM_DD_YYYY, DAY_OF_WEEK, DAY_NBR_IN_CLNDR_MON,
            DAY_NBR_IN_CLNDR_YR, WK_NBR_IN_CLNDR_MON, WK_NBR_IN_CLNDR_YR,
            CLNDR_MON_NAME, CLNDR_MON_IN_YR, CLNDR_QRTR, CLNDR_YR, DATE_KEY
        )
        VALUES (
            @date,
            DATENAME(WEEKDAY, @date),
            DAY(@date),
            DATEPART(DAYOFYEAR, @date),
            @wk_nbr_in_mon,
            DATEPART(WEEK, @date),
            DATENAME(MONTH, @date),
            MONTH(@date),
            DATEPART(QUARTER, @date),
            YEAR(@date),
            @key
        )
        SET @key = @key + 1
    END

    SET @date = DATEADD(DAY, 1, @date)
END

