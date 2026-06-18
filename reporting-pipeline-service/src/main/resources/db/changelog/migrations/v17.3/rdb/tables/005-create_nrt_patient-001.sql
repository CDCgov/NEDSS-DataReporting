IF
    NOT EXISTS (
        SELECT 1 FROM sysobjects
        WHERE name = 'nrt_patient' AND xtype = 'U'
    )
    BEGIN
        CREATE TABLE dbo.nrt_patient
        (
            patient_uid bigint NOT NULL PRIMARY KEY,
            patient_mpr_uid bigint NULL,
            record_status varchar(50) NULL,
            local_id varchar(50) NULL,
            general_comments varchar(2000) NULL,
            first_name varchar(50) NULL,
            middle_name varchar(50) NULL,
            last_name varchar(50) NULL,
            name_suffix varchar(50) NULL,
            nm_use_cd varchar(20) NULL,
            status_name_cd varchar(1) NULL,
            alias_nickname varchar(50) NULL,
            street_address_1 varchar(50) NULL,
            street_address_2 varchar(50) NULL,
            city varchar(50) NULL,
            state varchar(50) NULL,
            state_code varchar(50) NULL,
            zip varchar(50) NULL,
            county varchar(50) NULL,
            county_code varchar(50) NULL,
            country varchar(50) NULL,
            country_code varchar(50) NULL,
            within_city_limits varchar(10) NULL,
            phone_home varchar(50) NULL,
            phone_ext_home varchar(50) NULL,
            phone_work varchar(50) NULL,
            phone_ext_work varchar(50) NULL,
            phone_cell varchar(50) NULL,
            email varchar(100) NULL,
            dob datetime NULL,
            age_reported numeric(18, 0) NULL,
            age_reported_unit varchar(20) NULL,
            age_reported_unit_cd varchar(20) NULL,
            birth_sex varchar(50) NULL,
            current_sex varchar(50) NULL,
            curr_sex_cd varchar(20) NULL,
            deceased_indicator varchar(50) NULL,
            deceased_ind_cd varchar(20) NULL,
            deceased_date datetime NULL,
            marital_status varchar(50) NULL,
            marital_status_cd varchar(20) NULL,
            ssn varchar(50) NULL,
            ethnic_group_ind varchar(20) NULL,
            ethnicity varchar(50) NULL,
            race_calculated varchar(50) NULL,
            race_calc_details varchar(4000) NULL,
            race_amer_ind_1 varchar(50) NULL,
            race_amer_ind_2 varchar(50) NULL,
            race_amer_ind_3 varchar(50) NULL,
            race_amer_ind_gt3_ind varchar(50) NULL,
            race_amer_ind_all varchar(2000) NULL,
            race_asian_1 varchar(50) NULL,
            race_asian_2 varchar(50) NULL,
            race_asian_3 varchar(50) NULL,
            race_asian_gt3_ind varchar(50) NULL,
            race_asian_all varchar(2000) NULL,
            race_black_1 varchar(50) NULL,
            race_black_2 varchar(50) NULL,
            race_black_3 varchar(50) NULL,
            race_black_gt3_ind varchar(50) NULL,
            race_black_all varchar(2000) NULL,
            race_nat_hi_1 varchar(50) NULL,
            race_nat_hi_2 varchar(50) NULL,
            race_nat_hi_3 varchar(50) NULL,
            race_nat_hi_gt3_ind varchar(50) NULL,
            race_nat_hi_all varchar(2000) NULL,
            race_white_1 varchar(50) NULL,
            race_white_2 varchar(50) NULL,
            race_white_3 varchar(50) NULL,
            race_white_gt3_ind varchar(50) NULL,
            race_white_all varchar(2000) NULL,
            patient_number varchar(50) NULL,
            patient_number_auth varchar(199) NULL,
            entry_method varchar(50) NULL,
            speaks_english varchar(100) NULL,
            unk_ethnic_rsn varchar(100) NULL,
            curr_sex_unk_rsn varchar(100) NULL,
            preferred_gender varchar(100) NULL,
            addl_gender_info varchar(100) NULL,
            census_tract varchar(100) NULL,
            race_all varchar(4000) NULL,
            birth_country varchar(50) NULL,
            primary_occupation varchar(50) NULL,
            primary_language varchar(50) NULL,
            add_user_id bigint NULL,
            add_user_name varchar(50) NULL,
            add_time datetime NULL,
            last_chg_user_id bigint NULL,
            last_chg_user_name varchar(50) NULL,
            last_chg_time datetime NULL,
            refresh_datetime datetime2 GENERATED ALWAYS AS ROW START NOT NULL,
            max_datetime datetime2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
            PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
        );
    END


IF
    EXISTS (
        SELECT 1 FROM sysobjects
        WHERE name = 'nrt_patient' AND xtype = 'U'
    )
    BEGIN
        --CNDE-2498
        IF
            NOT EXISTS (
                SELECT 1 FROM sys.columns
                WHERE
                    name = N'nm_use_cd'
                    AND object_id = OBJECT_ID(N'nrt_patient')
            )
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD nm_use_cd varchar(20);
            END;
        IF
            NOT EXISTS (
                SELECT 1 FROM sys.columns
                WHERE
                    name = N'status_name_cd'
                    AND object_id = OBJECT_ID(N'nrt_patient')
            )
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD status_name_cd varchar(1);
            END;
        IF
            NOT EXISTS (
                SELECT 1 FROM sys.columns
                WHERE
                    name = N'ethnic_group_ind'
                    AND object_id = OBJECT_ID(N'nrt_patient')
            )
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD ethnic_group_ind varchar(
                    20
                );
            END;
        IF
            NOT EXISTS (
                SELECT 1 FROM sys.columns
                WHERE
                    name = N'deceased_ind_cd'
                    AND object_id = OBJECT_ID(N'nrt_patient')
            )
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD deceased_ind_cd varchar(20);
            END;
        IF
            NOT EXISTS (
                SELECT 1 FROM sys.columns
                WHERE
                    name = N'curr_sex_cd'
                    AND object_id = OBJECT_ID(N'nrt_patient')
            )
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD curr_sex_cd varchar(20);
            END;
        IF
            NOT EXISTS (
                SELECT 1 FROM sys.columns
                WHERE
                    name = N'age_reported_unit_cd'
                    AND object_id = OBJECT_ID(N'nrt_patient')
            )
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD age_reported_unit_cd varchar(
                    20
                );
            END;

            --CNDE-2838
        IF
            NOT EXISTS (
                SELECT 1 FROM sys.columns
                WHERE
                    name = N'country_code'
                    AND object_id = OBJECT_ID(N'nrt_patient')
            )
            BEGIN
                ALTER TABLE dbo.nrt_patient ADD country_code varchar(50);
            END;
    END;
