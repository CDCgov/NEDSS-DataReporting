IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_notification' and xtype = 'U')
CREATE TABLE dbo.nrt_investigation_notification (
    source_act_uid           bigint                                          NOT NULL,
    public_health_case_uid   bigint                                          NULL,
    source_class_cd          varchar(10)                                     NULL,
    target_class_cd          varchar(10)                                     NULL,
    act_type_cd              varchar(50)                                     NULL,
    status_cd                char(1)                                         NULL,
    notification_uid         bigint                                          NOT NULL,
    prog_area_cd             varchar(20)                                     NULL,
    program_jurisdiction_oid bigint                                          NULL,
    jurisdiction_cd          varchar(20)                                     NULL,
    record_status_time       datetime                                        NULL,
    status_time              datetime                                        NULL,
    rpt_sent_time            datetime                                        NULL,
    notif_status             varchar(20)                                     NULL,
    notif_local_id           varchar(50)                                     NULL,
    notif_comments           varchar(1000)                                   NULL,
    notif_add_time           datetime                                        NULL,
    notif_add_user_id        bigint                                          NULL,
    notif_add_user_name      varchar(50)                                     NULL,
    notif_last_chg_user_id   bigint                                          NULL,
    notif_last_chg_user_name varchar(50)                                     NULL,
    notif_last_chg_time      datetime                                        NULL,
    local_patient_id         varchar(50)                                     NULL,
    local_patient_uid        bigint                                          NULL,
    condition_cd             varchar(50)                                     NULL,
    condition_desc           varchar(100)                                    NULL,
    refresh_datetime         datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime             datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

    --CNDE-2152
    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'first_notification_status' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD first_notification_status varchar(20);
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notif_rejected_count' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD notif_rejected_count bigint;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notif_created_count' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD notif_created_count bigint;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notif_sent_count' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD notif_sent_count bigint;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'first_notification_send_date' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD first_notification_send_date datetime;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notif_created_pending_count' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD notif_created_pending_count bigint;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'last_notification_date' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD last_notification_date datetime;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'last_notification_send_date' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD last_notification_send_date datetime;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'first_notification_date' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD first_notification_date datetime;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'first_notification_submitted_by' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD first_notification_submitted_by bigint;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'last_notification_submitted_by' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD last_notification_submitted_by bigint;
        END;

    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notification_date' AND Object_ID = Object_ID(N'nrt_investigation_notification'))
        BEGIN
            ALTER TABLE dbo.nrt_investigation_notification ADD notification_date datetime;
        END;