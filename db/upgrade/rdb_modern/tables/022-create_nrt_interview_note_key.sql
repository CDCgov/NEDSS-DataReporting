DROP TABLE IF EXISTS dbo.nrt_interview_note_key;

CREATE TABLE dbo.nrt_interview_note_key (
	d_interview_note_key bigint IDENTITY(1,1) NOT NULL,
    d_interview_key bigint NOT NULL,
	nbs_answer_uid bigint NULL
);

declare @max bigint;
select @max=max(D_INTERVIEW_NOTE_KEY)+1 from dbo.D_INTERVIEW_NOTE;
select @max;
if @max IS NULL   --check when max is returned as null
  SET @max = 1;
DBCC CHECKIDENT ('dbo.nrt_interview_note_key', RESEED, @max);