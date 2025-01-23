IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_place_tele'
                 and xtype = 'U')
CREATE TABLE dbo.nrt_place_tele
(
    place_uid                bigint                                             NOT NULL,
    place_tele_locator_uid   bigint                                             NOT NULL,
    place_phone_ext          varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_phone              varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_email              varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
    place_phone_comments     varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    tele_use_cd              varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    tele_cd                  varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_tele_type          varchar(14) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_tele_use           varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    refresh_datetime         datetime2 generated always as row start            NOT NULL,
    max_datetime             datetime2 generated always as row end hidden       NOT NULL,
    period for system_time (refresh_datetime,max_datetime)
);