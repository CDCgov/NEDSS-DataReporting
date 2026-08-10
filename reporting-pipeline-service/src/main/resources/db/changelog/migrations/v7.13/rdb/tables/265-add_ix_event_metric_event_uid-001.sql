-- APP-926: covering index on EVENT_METRIC(EVENT_UID).
-- sp_morbidity_report_datamart_postprocessing builds #MORB_EVENT_INIT with
--   LEFT JOIN dbo.EVENT_METRIC EM ON MR.MORB_RPT_UID = EM.EVENT_UID
-- but the clustered PK is (EVENT_TYPE, EVENT_UID), so a join on EVENT_UID alone cannot seek and
-- degrades to a full scan of EVENT_METRIC. This covering
-- index turns that scan into a seek (the plan's own missing-index hint, 32.7% impact). Idempotent.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_EVENT_METRIC_EVENT_UID' AND object_id = OBJECT_ID('dbo.EVENT_METRIC')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_EVENT_METRIC_EVENT_UID
        ON dbo.EVENT_METRIC (EVENT_UID)
        INCLUDE (PROG_AREA_DESC_TXT, ADD_TIME, ADD_USER_ID, LAST_CHG_TIME, LAST_CHG_USER_ID, ADD_USER_NAME, LAST_CHG_USER_NAME);
END
