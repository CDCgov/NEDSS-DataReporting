IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_odse_lookup_question' and xtype = 'U')
CREATE TABLE dbo.nrt_odse_lookup_question
(
    lookup_question_uid            bigint                                       not null primary key,
    FROM_QUESTION_IDENTIFIER       varchar(250)                                 null,
    FROM_QUESTION_DISPLAY_NAME     varchar(250)                                 null,
    FROM_CODE_SYSTEM_CD            varchar(250)                                 null,
    FROM_CODE_SYSTEM_DESC_TXT      varchar(250)                                 null,
    FROM_DATA_TYPE                 varchar(250)                                 null,
    FROM_CODE_SET                  varchar(250)                                 null,
    FROM_FORM_CD                   varchar(250)                                 null,
    TO_QUESTION_IDENTIFIER         varchar(250)                                 null,
    TO_QUESTION_DISPLAY_NAME       varchar(250)                                 null,
    TO_CODE_SYSTEM_CD              varchar(250)                                 null,
    TO_CODE_SYSTEM_DESC_TXT        varchar(250)                                 null,
    TO_DATA_TYPE                   varchar(250)                                 null,
    TO_CODE_SET                    varchar(250)                                 null,
    TO_FORM_CD                     varchar(250)                                 null,
    RDB_COLUMN_NM                  varchar(30)                                  null,
    ADD_TIME                       datetime                                     null,
    ADD_USER_ID                    bigint                                       null,
    LAST_CHG_TIME                  datetime                                     null,
    LAST_CHG_USER_ID               bigint                                       null,
    STATUS_CD                      varchar(1)                                   null,
    STATUS_TIME                    datetime                                     null,
    refresh_datetime               datetime2 generated always as row start     not null,
    max_datetime                   datetime2 generated always as row end hidden not null,
    period for system_time (refresh_datetime,max_datetime)
);