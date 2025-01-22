IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_place'
                 and xtype = 'U')
CREATE TABLE dbo.nrt_place
(
    place_uid                bigint                                             NOT NULL PRIMARY KEY,
    cd                       varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_type_description   varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_local_id           varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_name               varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_general_comments   varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    place_add_time           datetime                                           NULL,
    place_add_user_id        bigint                                             NULL,
    place_last_change_time   datetime                                           NULL,
    place_last_chg_user_id   bigint                                             NULL,
    place_record_status      varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_record_status_time datetime                                           NULL,
    place_status_cd          char(1) COLLATE SQL_Latin1_General_CP1_CI_AS       NULL,
    place_status_time        datetime                                           NULL,
    place_quick_code         varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
    assigning_authority_cd   varchar(199) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
    place_postal_uid         bigint                                             NULL,
    place_zip                varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_city               varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
    place_country            varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_street_address_1   varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
    place_street_address_2   varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
    place_county_code        varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_state_code         varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_address_comments   varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    place_elp_cd             varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_state_desc         varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    place_county_desc        varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
    place_country_desc       varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
    refresh_datetime         datetime2 generated always as row start            NOT NULL,
    max_datetime             datetime2 generated always as row end hidden       NOT NULL,
    period for system_time (refresh_datetime,max_datetime)
);