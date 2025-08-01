IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_provider' and xtype = 'U')
CREATE TABLE dbo.nrt_provider
(
    provider_uid                   bigint                                       not null primary key,
    local_id                       varchar(50)                                  null,
    record_status                  varchar(50)                                  null,
    name_prefix                    varchar(50)                                  null,
    first_name                     varchar(50)                                  null,
    middle_name                    varchar(50)                                  null,
    last_name                      varchar(50)                                  null,
    name_suffix                    varchar(50)                                  null,
    name_degree                    varchar(50)                                  null,
    general_comments               varchar(2000)                                null,
    quick_code                     varchar(50)                                  null,
    provider_registration_num      varchar(50)                                  null,
    provider_registration_num_auth varchar(199)                                 null,
    provider_npi                   varchar(50)                                  null,
    street_address_1               varchar(50)                                  null,
    street_address_2               varchar(50)                                  null,
    city                           varchar(50)                                  null,
    state                          varchar(50)                                  null,
    state_code                     varchar(50)                                  null,
    zip                            varchar(50)                                  null,
    county                         varchar(50)                                  null,
    county_code                    varchar(50)                                  null,
    country                        varchar(50)                                  null,
    country_code                   varchar(50)                                  null,
    address_comments               varchar(2000)                                null,
    phone_work                     varchar(50)                                  null,
    phone_ext_work                 varchar(50)                                  null,
    email_work                     varchar(50)                                  null,
    phone_comments                 varchar(2000)                                null,
    phone_cell                     varchar(50)                                  null,
    entry_method                   varchar(50)                                  null,
    add_user_id                    bigint                                       null,
    add_user_name                  varchar(50)                                  null,
    add_time                       datetime                                     null,
    last_chg_user_id               bigint                                       null,
    last_chg_user_name             varchar(50)                                  null,
    last_chg_time                  datetime                                     null,
    refresh_datetime               datetime2 generated always as row start      not null,
    max_datetime                   datetime2 generated always as row end hidden not null,
    period for system_time (refresh_datetime,max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_provider' and xtype = 'U')
    BEGIN

        --CNDE-2838
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'country_code' AND Object_ID = Object_ID(N'nrt_provider'))
            BEGIN
                ALTER TABLE dbo.nrt_provider ADD country_code VARCHAR(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'provider_npi' AND Object_ID = Object_ID(N'nrt_provider'))
            BEGIN
                ALTER TABLE dbo.nrt_provider ADD provider_npi VARCHAR(50);
            END;

    END;