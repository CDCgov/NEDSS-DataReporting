IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_auth_user'
                 and xtype = 'U')
CREATE TABLE dbo.nrt_auth_user
(
    auth_user_uid      bigint                                            NOT NULL primary key,
    user_id            varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    first_nm           varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    last_nm            varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    nedss_entry_id     bigint                                            NOT NULL,
    provider_uid       bigint                                            NULL,
    add_time           datetime                                          NOT NULL,
    add_user_id        bigint                                            NOT NULL,
    last_chg_time      datetime                                          NOT NULL,
    last_chg_user_id   bigint                                            NOT NULL,
    record_status_cd   varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS  NOT NULL,
    record_status_time datetime                                          NOT NULL,
    refresh_datetime   datetime2 generated always as row start           not null,
    max_datetime       datetime2 generated always as row end hidden      not null,
    period for system_time (refresh_datetime,max_datetime)
);