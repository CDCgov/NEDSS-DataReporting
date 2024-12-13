DROP TABLE IF EXISTS dbo.nrt_interview_key;

CREATE TABLE dbo.nrt_interview_key (
	d_interview_key bigint IDENTITY(1,1) NOT NULL,
	interview_uid bigint NULL
);

declare @max bigint;
select @max=max(D_INTERVIEW_KEY)+1 from dbo.D_INTERVIEW;
select @max;
if @max IS NULL   --check when max is returned as null
  SET @max = 1;
DBCC CHECKIDENT ('dbo.nrt_interview_key', RESEED, @max);