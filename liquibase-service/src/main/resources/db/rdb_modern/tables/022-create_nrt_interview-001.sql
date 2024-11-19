IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_interview'
                 and xtype = 'U')
CREATE TABLE dbo.nrt_interview
(
    interview_uid       bigint                                          NOT NULL PRIMARY KEY,
    interview_status_cd varchar(4000)                                   NULL,
    interview_date      datetime                                        NULL,
    interviewee_role_cd varchar(4000)                                   NULL,
    interview_type_cd   varchar(4000)                                   NULL,
    interview_loc_cd    varchar(4000)                                   NULL,
    local_id            varchar(4000)                                   NULL,
    record_status_cd    varchar(4000)                                   NULL,
    record_status_time  datetime                                        NULL,
    add_time            datetime                                        NULL,
    add_user_id         numeric                                         NULL,
    last_chg_time       datetime                                        NULL,
    last_chg_user_id    numeric                                         NULL,
    version_ctrl_nbr    numeric                                         NULL,
    ix_status           varchar(4000)                                   NULL,
    ix_interviewee_role varchar(4000)                                   NULL,
    ix_type             varchar(4000)                                   NULL,
    ix_location         varchar(4000)                                   NULL,
    refresh_datetime    datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime        datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);
