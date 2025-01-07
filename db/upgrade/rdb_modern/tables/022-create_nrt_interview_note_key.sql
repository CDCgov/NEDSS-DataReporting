-- table is not dropped and recreated so as to stay consistent with the design of nrt_interview_key

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_note_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_interview_note_key (
          d_interview_note_key bigint IDENTITY(1,1) NOT NULL,
          d_interview_key bigint NOT NULL,
          nbs_answer_uid bigint NULL
        );
        declare @max bigint;
        select @max=max(d_interview_note_key)+1 from dbo.D_INTERVIEW_NOTE ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, as default record with key = 1 is not stored in D_INTERVIEW_NOTE
        DBCC CHECKIDENT ('dbo.nrt_interview_note_key', RESEED, @max);

    END