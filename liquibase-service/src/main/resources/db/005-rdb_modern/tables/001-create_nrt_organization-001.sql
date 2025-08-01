IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_organization' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_organization
        (
            organization_uid   bigint                                          NOT NULL,
            local_id           varchar(50)                                     NULL,
            record_status      varchar(50)                                     NULL,
            organization_name  varchar(50)                                     NULL,
            general_comments   varchar(2000)                                   NULL,
            quick_code         varchar(50)                                     NULL,
            stand_ind_class    varchar(50)                                     NULL,
            facility_id        varchar(50)                                     NULL,
            facility_id_auth   varchar(199)                                    NULL,
            street_address_1   varchar(50)                                     NULL,
            street_address_2   varchar(50)                                     NULL,
            city               varchar(50)                                     NULL,
            state              varchar(50)                                     NULL,
            state_code         varchar(50)                                     NULL,
            zip                varchar(10)                                     NULL,
            county             varchar(50)                                     NULL,
            county_code        varchar(50)                                     NULL,
            country            varchar(50)                                     NULL,
            country_code       varchar(50)                                     NULL,
            address_comments   varchar(2000)                                   NULL,
            phone_work         varchar(50)                                     NULL,
            phone_ext_work     varchar(50)                                     NULL,
            email              varchar(50)                                     NULL,
            phone_comments     varchar(2000)                                   NULL,
            fax                varchar(50)                                     NULL,
            entry_method       varchar(50)                                     NULL,
            add_user_id        bigint                                          NULL,
            add_user_name      varchar(50)                                     NULL,
            add_time           datetime                                        NULL,
            last_chg_user_id   bigint                                          NULL,
            last_chg_user_name varchar(50)                                     NULL,
            last_chg_time      datetime                                        NULL,
            refresh_datetime   datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
            max_datetime       datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
            PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
        );
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_organization'))
    BEGIN
        ALTER TABLE dbo.nrt_organization
        ADD CONSTRAINT pk_nrt_organization PRIMARY KEY (organization_uid);
    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_organization' and xtype = 'U')
    BEGIN

        --CNDE-2838
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'country_code' AND Object_ID = Object_ID(N'nrt_organization'))
            BEGIN
                ALTER TABLE dbo.nrt_organization ADD country_code VARCHAR(50);
            END;

    END;