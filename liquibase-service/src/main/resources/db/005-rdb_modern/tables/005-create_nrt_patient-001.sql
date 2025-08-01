IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_patient' and xtype = 'U')
    BEGIN
        create table dbo.nrt_patient
        (
            patient_uid           bigint                                       not null primary key,
            patient_mpr_uid       bigint                                       null,
            record_status         varchar(50)                                  null,
            local_id              varchar(50)                                  null,
            general_comments      varchar(2000)                                null,
            first_name            varchar(50)                                  null,
            middle_name           varchar(50)                                  null,
            last_name             varchar(50)                                  null,
            name_suffix           varchar(50)                                  null,
            nm_use_cd             varchar(20)                                  null,
            status_name_cd        varchar(1)                                   null,
            alias_nickname        varchar(50)                                  null,
            street_address_1      varchar(50)                                  null,
            street_address_2      varchar(50)                                  null,
            city                  varchar(50)                                  null,
            state                 varchar(50)                                  null,
            state_code            varchar(50)                                  null,
            zip                   varchar(50)                                  null,
            county                varchar(50)                                  null,
            county_code           varchar(50)                                  null,
            country               varchar(50)                                  null,
            country_code          varchar(50)                                  null,
            within_city_limits    varchar(10)                                  null,
            phone_home            varchar(50)                                  null,
            phone_ext_home        varchar(50)                                  null,
            phone_work            varchar(50)                                  null,
            phone_ext_work        varchar(50)                                  null,
            phone_cell            varchar(50)                                  null,
            email                 varchar(100)                                 null,
            dob                   datetime                                     null,
            age_reported          numeric(18, 0)                               null,
            age_reported_unit     varchar(20)                                  null,
            age_reported_unit_cd  varchar(20)                                  null,
            birth_sex             varchar(50)                                  null,
            current_sex           varchar(50)                                  null,
            curr_sex_cd           varchar(20)                                  null,
            deceased_indicator    varchar(50)                                  null,
            deceased_ind_cd       varchar(20)                                  null,
            deceased_date         datetime                                     null,
            marital_status        varchar(50)                                  null,
            ssn                   varchar(50)                                  null,
            ethnic_group_ind      varchar(20)                                  null,
            ethnicity             varchar(50)                                  null,
            race_calculated       varchar(50)                                  null,
            race_calc_details     varchar(4000)                                null,
            race_amer_ind_1       varchar(50)                                  null,
            race_amer_ind_2       varchar(50)                                  null,
            race_amer_ind_3       varchar(50)                                  null,
            race_amer_ind_gt3_ind varchar(50)                                  null,
            race_amer_ind_all     varchar(2000)                                null,
            race_asian_1          varchar(50)                                  null,
            race_asian_2          varchar(50)                                  null,
            race_asian_3          varchar(50)                                  null,
            race_asian_gt3_ind    varchar(50)                                  null,
            race_asian_all        varchar(2000)                                null,
            race_black_1          varchar(50)                                  null,
            race_black_2          varchar(50)                                  null,
            race_black_3          varchar(50)                                  null,
            race_black_gt3_ind    varchar(50)                                  null,
            race_black_all        varchar(2000)                                null,
            race_nat_hi_1         varchar(50)                                  null,
            race_nat_hi_2         varchar(50)                                  null,
            race_nat_hi_3         varchar(50)                                  null,
            race_nat_hi_gt3_ind   varchar(50)                                  null,
            race_nat_hi_all       varchar(2000)                                null,
            race_white_1          varchar(50)                                  null,
            race_white_2          varchar(50)                                  null,
            race_white_3          varchar(50)                                  null,
            race_white_gt3_ind    varchar(50)                                  null,
            race_white_all        varchar(2000)                                null,
            patient_number        varchar(50)                                  null,
            patient_number_auth   varchar(199)                                 null,
            entry_method          varchar(50)                                  null,
            speaks_english        varchar(100)                                 null,
            unk_ethnic_rsn        varchar(100)                                 null,
            curr_sex_unk_rsn      varchar(100)                                 null,
            preferred_gender      varchar(100)                                 null,
            addl_gender_info      varchar(100)                                 null,
            census_tract          varchar(100)                                 null,
            race_all              varchar(4000)                                null,
            birth_country         varchar(50)                                  null,
            primary_occupation    varchar(50)                                  null,
            primary_language      varchar(50)                                  null,
            add_user_id           bigint                                       null,
            add_user_name         varchar(50)                                  null,
            add_time              datetime                                     null,
            last_chg_user_id      bigint                                       null,
            last_chg_user_name    varchar(50)                                  null,
            last_chg_time         datetime                                     null,
            refresh_datetime      datetime2 generated always as row start      not null,
            max_datetime          datetime2 generated always as row end hidden not null,
            period for system_time (refresh_datetime,max_datetime)
        );
    END


IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_patient' and xtype = 'U')
    BEGIN
        --CNDE-2498
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'nm_use_cd' AND Object_ID = Object_ID(N'nrt_patient'))
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD nm_use_cd varchar(20);
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'status_name_cd' AND Object_ID = Object_ID(N'nrt_patient'))
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD status_name_cd varchar(1);
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'ethnic_group_ind' AND Object_ID = Object_ID(N'nrt_patient'))
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD ethnic_group_ind varchar(20);
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'deceased_ind_cd' AND Object_ID = Object_ID(N'nrt_patient'))
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD deceased_ind_cd varchar(20);
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'curr_sex_cd' AND Object_ID = Object_ID(N'nrt_patient'))
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD curr_sex_cd varchar(20);
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'age_reported_unit_cd' AND Object_ID = Object_ID(N'nrt_patient'))
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD age_reported_unit_cd varchar(20);
            END;

        --CNDE-2838
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'country_code' AND Object_ID = Object_ID(N'nrt_patient'))
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD country_code VARCHAR(50);
            END;
    END;
