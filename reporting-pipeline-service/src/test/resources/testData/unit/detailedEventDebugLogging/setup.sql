USE [RDB_MODERN]

DELETE FROM dbo.job_flow_log
WHERE package_Name IN (
    'sp_interview_event',
    'sp_contact_record_event',
    'sp_treatment_event',
    'sp_vaccination_event'
)

EXEC dbo.sp_interview_event @ix_uids = '990000071', @debug = 0, @debug_logging = 0
EXEC dbo.sp_interview_event @ix_uids = '990000071', @debug = 0, @debug_logging = 1
EXEC dbo.sp_interview_event @ix_uids = '990000071', @debug = 1, @debug_logging = 0
EXEC dbo.sp_interview_event @ix_uids = '990000071', @debug = 1, @debug_logging = 1

EXEC dbo.sp_contact_record_event @cc_uids = '990000072', @debug = 0, @debug_logging = 0
EXEC dbo.sp_contact_record_event @cc_uids = '990000072', @debug = 0, @debug_logging = 1
EXEC dbo.sp_contact_record_event @cc_uids = '990000072', @debug = 1, @debug_logging = 0
EXEC dbo.sp_contact_record_event @cc_uids = '990000072', @debug = 1, @debug_logging = 1

EXEC dbo.sp_treatment_event @treatment_uids = '990000073', @debug = 0, @debug_logging = 0
EXEC dbo.sp_treatment_event @treatment_uids = '990000073', @debug = 0, @debug_logging = 1
EXEC dbo.sp_treatment_event @treatment_uids = '990000073', @debug = 1, @debug_logging = 0
EXEC dbo.sp_treatment_event @treatment_uids = '990000073', @debug = 1, @debug_logging = 1

EXEC dbo.sp_vaccination_event @vac_uids = '990000074', @debug = 0, @debug_logging = 0
EXEC dbo.sp_vaccination_event @vac_uids = '990000074', @debug = 0, @debug_logging = 1
EXEC dbo.sp_vaccination_event @vac_uids = '990000074', @debug = 1, @debug_logging = 0
EXEC dbo.sp_vaccination_event @vac_uids = '990000074', @debug = 1, @debug_logging = 1
