IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_f_interview_case_d_interview_key' AND object_id = OBJECT_ID('dbo.F_INTERVIEW_CASE'))
BEGIN
    CREATE NONCLUSTERED INDEX idx_f_interview_case_d_interview_key ON dbo.F_INTERVIEW_CASE (D_INTERVIEW_KEY);
END
