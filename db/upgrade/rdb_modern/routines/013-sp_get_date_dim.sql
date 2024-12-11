CREATE  OR ALTER PROCEDURE dbo.sp_get_date_dim @start int, @end int
    AS
begin


-- get the first day of the start year
declare @start_dt datetime =  DATEFROMPARTS(@start, 1, 1)

-- get the last day of the end year
declare @end_dt datetime = DATEFROMPARTS(@end, 12, 31)

declare @date datetime = @start_dt

-- this is a default row with key as 1
declare @date_key int = 1

-- insert a default row with key as 1
if not exists (select * from dbo.rdb_date_temp where date_key=@date_key)
Insert into dbo.rdb_date_temp(date_key) select @date_key

--loop through each date
                                                                                   while  @start_dt <= @end_dt
begin
	set @date = @start_dt
	-- get the next key
	set @date_key = @date_key + 1

	insert into rdb_modern.dbo.rdb_date_temp
    select DATEADD(dd, 0, DATEDIFF(dd, 0, @date))  DATE_MM_DD_YYYY
     ,DATENAME(dw,@date) DAY_OF_WEEK -- Friday
     ,day(@date) DAY_NBR_IN_CLNDR_MON
     ,DATEPART(dayofyear, @date) DAY_NBR_IN_CLNDR_YR
     ,DATEDIFF(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, @date), 0), @date) + 1 WK_NBR_IN_CLNDR_MON
     ,DATEPART(week, @date) WK_NBR_IN_CLNDR_YR
     ,DATENAME(month,@date) CLNDR_MON_NAME
     ,month(@date) CLNDR_MON_IN_YR
     ,DATEPART(QUARTER, @date)  CLNDR_QRTR
     ,DATENAME(year,@date) CLNDR_YR
     ,@date_key

-- get the next date
set @start_dt = @start_dt + 1

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'RDB_DATE' and xtype = 'U')
select DISTINCT DATE_KEY, DATE_MM_DD_YYYY, DAY_OF_WEEK, DAY_NBR_IN_CLNDR_MON, DAY_NBR_IN_CLNDR_YR, WK_NBR_IN_CLNDR_MON, WK_NBR_IN_CLNDR_YR, CLNDR_MON_NAME, CLNDR_MON_IN_YR, CLNDR_QRTR, CLNDR_YR
into #temp_date
from rdb_modern.dbo.rdb_date_temp;

INSERT INTO rdb_modern.dbo.RDB_DATE
(DATE_KEY,DATE_MM_DD_YYYY, DAY_OF_WEEK, DAY_NBR_IN_CLNDR_MON, DAY_NBR_IN_CLNDR_YR, WK_NBR_IN_CLNDR_MON, WK_NBR_IN_CLNDR_YR, CLNDR_MON_NAME, CLNDR_MON_IN_YR, CLNDR_QRTR, CLNDR_YR)
select DATE_KEY, DATE_MM_DD_YYYY, DAY_OF_WEEK, DAY_NBR_IN_CLNDR_MON, DAY_NBR_IN_CLNDR_YR, WK_NBR_IN_CLNDR_MON, WK_NBR_IN_CLNDR_YR, CLNDR_MON_NAME, CLNDR_MON_IN_YR, CLNDR_QRTR, CLNDR_YR
from #temp_date;

end

end