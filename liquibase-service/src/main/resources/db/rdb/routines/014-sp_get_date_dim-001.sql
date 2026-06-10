IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_get_date_dim]')
                                      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
    BEGIN
        DROP PROCEDURE [dbo].[sp_get_date_dim]
    END
GO

CREATE PROCEDURE dbo.sp_get_date_dim @start int, @end int
AS
BEGIN

    SET LANGUAGE us_english;

    DECLARE @StartDate date = DATEFROMPARTS(@start, 1, 1);
    DECLARE @EndDate   date = DATEFROMPARTS(@end, 12, 31);
    DECLARE @CurrentDate date = @StartDate;

    -- Add the NULL/unknown date row if missing
    IF NOT EXISTS (
        SELECT 1
        FROM [dbo].[RDB_DATE]
        WHERE [DATE_KEY] = 1
    )
    BEGIN
        INSERT INTO [dbo].[RDB_DATE] (
            [DATE_MM_DD_YYYY],
            [DAY_OF_WEEK],
            [DAY_NBR_IN_CLNDR_MON],
            [DAY_NBR_IN_CLNDR_YR],
            [WK_NBR_IN_CLNDR_MON],
            [WK_NBR_IN_CLNDR_YR],
            [CLNDR_MON_NAME],
            [CLNDR_MON_IN_YR],
            [CLNDR_QRTR],
            [CLNDR_YR],
            [DATE_KEY]
        )
        VALUES (
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1
        );
    END;

    WHILE @CurrentDate <= @EndDate
    BEGIN
        DECLARE @DayOfYear int;
        DECLARE @DateKey numeric(18, 0);

        DECLARE @YearStart date;
        DECLARE @MonthStart date;
        DECLARE @FirstSaturdayInYear date;
        DECLARE @FirstSaturdayInMonth date;
        DECLARE @DaysUntilFirstSaturdayInYear int;
        DECLARE @DaysUntilFirstSaturdayInMonth int;
        DECLARE @SaturdaysInYearToDate int;
        DECLARE @SaturdaysInMonthToDate int;
        DECLARE @YearWeek int;
        DECLARE @MonthWeek int;

        SET @DayOfYear = DATEPART(DAYOFYEAR, @CurrentDate);

        /*
            Legacy RDB_DATE week rule:

            Week 1 exists before the first Saturday.
            Each Saturday increments the week number.
            If Jan 1 / month 1 starts on Saturday, that day is week 2.
        */

        SET @YearStart = DATEFROMPARTS(YEAR(@CurrentDate), 1, 1);
        SET @MonthStart = DATEFROMPARTS(YEAR(@CurrentDate), MONTH(@CurrentDate), 1);

        -- 1900-01-06 was a Saturday
        SET @DaysUntilFirstSaturdayInYear =
            (7 - ((DATEDIFF(DAY, CONVERT(date, '1900-01-06'), @YearStart) % 7 + 7) % 7)) % 7;

        SET @FirstSaturdayInYear =
            DATEADD(DAY, @DaysUntilFirstSaturdayInYear, @YearStart);

        IF @CurrentDate < @FirstSaturdayInYear
            SET @SaturdaysInYearToDate = 0;
        ELSE
            SET @SaturdaysInYearToDate =
                (DATEDIFF(DAY, @FirstSaturdayInYear, @CurrentDate) / 7) + 1;

        SET @YearWeek = @SaturdaysInYearToDate + 1;


        SET @DaysUntilFirstSaturdayInMonth =
            (7 - ((DATEDIFF(DAY, CONVERT(date, '1900-01-06'), @MonthStart) % 7 + 7) % 7)) % 7;

        SET @FirstSaturdayInMonth =
            DATEADD(DAY, @DaysUntilFirstSaturdayInMonth, @MonthStart);

        IF @CurrentDate < @FirstSaturdayInMonth
            SET @SaturdaysInMonthToDate = 0;
        ELSE
            SET @SaturdaysInMonthToDate =
                (DATEDIFF(DAY, @FirstSaturdayInMonth, @CurrentDate) / 7) + 1;

        SET @MonthWeek = @SaturdaysInMonthToDate + 1;

        -- DATE_KEY 1 is the NULL row, so 1990-01-01 starts at DATE_KEY 2
        SET @DateKey = DATEDIFF(DAY, CONVERT(date, '1990-01-01'), @CurrentDate) + 2;

        IF NOT EXISTS (
            SELECT 1
            FROM [dbo].[RDB_DATE]
            WHERE [DATE_KEY] = @DateKey
        )
        BEGIN
            INSERT INTO [dbo].[RDB_DATE] (
                [DATE_MM_DD_YYYY],
                [DAY_OF_WEEK],
                [DAY_NBR_IN_CLNDR_MON],
                [DAY_NBR_IN_CLNDR_YR],
                [WK_NBR_IN_CLNDR_MON],
                [WK_NBR_IN_CLNDR_YR],
                [CLNDR_MON_NAME],
                [CLNDR_MON_IN_YR],
                [CLNDR_QRTR],
                [CLNDR_YR],
                [DATE_KEY]
            )
            VALUES (
                CONVERT(datetime, @CurrentDate),
                DATENAME(WEEKDAY, @CurrentDate),
                DAY(@CurrentDate),
                @DayOfYear,
                @MonthWeek,
                @YearWeek,
                DATENAME(MONTH, @CurrentDate),
                MONTH(@CurrentDate),
                DATEPART(QUARTER, @CurrentDate),
                YEAR(@CurrentDate),
                @DateKey
            );
        END;

        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END;

end