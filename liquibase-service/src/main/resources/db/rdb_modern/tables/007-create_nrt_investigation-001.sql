IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation' and xtype = 'U')
CREATE TABLE dbo.nrt_investigation (
    public_health_case_uid        bigint                                          NOT NULL PRIMARY KEY,
    program_jurisdiction_oid      bigint                                          NULL,
    local_id                      varchar(50)                                     NULL,
    shared_ind                    varchar(50)                                     NULL,
    outbreak_name                 varchar(100)                                    NULL,
    investigation_status          varchar(50)                                     NULL,
    inv_case_status               varchar(50)                                     NULL,
    case_type_cd                  char(1)                                         NULL,
    txt                           varchar(2000)                                   NULL,
    jurisdiction_cd               varchar(20)                                     NULL,
    jurisdiction_nm               varchar(100)                                    NULL,
    earliest_rpt_to_phd_dt        datetime                                        NULL,
    effective_from_time           datetime                                        NULL,
    effective_to_time             datetime                                        NULL,
    rpt_form_cmplt_time           datetime                                        NULL,
    activity_from_time            datetime                                        NULL,
    rpt_src_cd_desc               varchar(100)                                    NULL,
    rpt_to_county_time            datetime                                        NULL,
    rpt_to_state_time             datetime                                        NULL,
    mmwr_week                     varchar(10)                                     NULL,
    mmwr_year                     varchar(10)                                     NULL,
    disease_imported_ind          varchar(100)                                    NULL,
    imported_from_country         varchar(50)                                     NULL,
    imported_from_state           varchar(50)                                     NULL,
    imported_from_county          varchar(50)                                     NULL,
    imported_city_desc_txt        varchar(2000)                                   NULL,
    earliest_rpt_to_cdc_dt        datetime                                        NULL,
    rpt_source_cd                 varchar(20)                                     NULL,
    imported_country_cd           varchar(20)                                     NULL,
    imported_state_cd             varchar(20)                                     NULL,
    imported_county_cd            varchar(20)                                     NULL,
    import_frm_city_cd            varchar(50)                                     NULL,
    diagnosis_time                datetime                                        NULL,
    hospitalized_admin_time       datetime                                        NULL,
    hospitalized_discharge_time   datetime                                        NULL,
    hospitalized_duration_amt     numeric(18, 0)                                  NULL,
    outbreak_ind                  varchar(50)                                     NULL,
    outbreak_ind_val              varchar(300)                                    NULL,
    hospitalized_ind              varchar(50)                                     NULL,
    hospitalized_ind_cd           varchar(20)                                     NULL,
    city_county_case_nbr          varchar(50)                                     NULL,
    transmission_mode_cd          varchar(20)                                     NULL,
    transmission_mode             varchar(50)                                     NULL,
    record_status_cd              varchar(20)                                     NULL,
    pregnant_ind_cd               varchar(20)                                     NULL,
    pregnant_ind                  varchar(50)                                     NULL,
    die_frm_this_illness_ind      varchar(50)                                     NULL,
    day_care_ind                  varchar(50)                                     NULL,
    day_care_ind_cd               varchar(20)                                     NULL,
    food_handler_ind_cd           varchar(20)                                     NULL,
    food_handler_ind              varchar(50)                                     NULL,
    deceased_time                 datetime                                        NULL,
    pat_age_at_onset              varchar(20)                                     NULL,
    pat_age_at_onset_unit_cd      varchar(20)                                     NULL,
    pat_age_at_onset_unit         varchar(20)                                     NULL,
    investigator_assigned_time    datetime                                        NULL,
    detection_method_desc_txt     varchar(50)                                     NULL,
    effective_duration_amt        varchar(50)                                     NULL,
    effective_duration_unit_cd    varchar(20)                                     NULL,
    illness_duration_unit         varchar(50)                                     NULL,
    contact_inv_txt               varchar(2000)                                   NULL,
    contact_inv_priority          varchar(20)                                     NULL,
    infectious_from_date          datetime                                        NULL,
    infectious_to_date            datetime                                        NULL,
    contact_inv_status            varchar(20)                                     NULL,
    activity_to_time              datetime                                        NULL,
    program_area_description      varchar(50)                                     NULL,
    add_user_id                   bigint                                          NULL,
    add_user_name                 varchar(50)                                     NULL,
    add_time                      datetime                                        NULL,
    last_chg_user_id              bigint                                          NULL,
    last_chg_user_name            varchar(50)                                     NULL,
    last_chg_time                 datetime                                        NULL,
    referral_basis_cd             varchar(20)                                     NULL,
    referral_basis                varchar(100)                                    NULL,
    curr_process_state            varchar(100)                                    NULL,
    inv_priority_cd               varchar(100)                                    NULL,
    coinfection_id                varchar(100)                                    NULL,
    legacy_case_id                varchar(100)                                    NULL,
    curr_process_state_cd         varchar(20)                                     NULL,
    investigation_status_cd       varchar(20)                                     NULL,
    notification_local_id         varchar(50)                                     NULL,
    notification_add_time         datetime                                        NULL,
    notification_record_status_cd varchar(20)                                     NULL,
    notification_last_chg_time    datetime                                        NULL,
    investigator_id               bigint                                          NULL,
    physician_id                  bigint                                          NULL,
    patient_id                    bigint                                          NULL,
    organization_id               bigint                                          NULL,
    phc_inv_form_id               bigint                                          NULL,
    outcome_cd                    varchar(20)                                     NULL,
    disease_imported_cd           varchar(20)                                     NULL,
    mood_cd                       varchar(10)                                     NULL,
    class_cd                      varchar(10)                                     NULL,
    case_class_cd                 varchar(20)                                     NULL,
    cd                            varchar(50)                                     NULL,
    cd_desc_txt                   varchar(100)                                    NULL,
    prog_area_cd                  varchar(20)                                     NULL,
    jurisdiction_code             varchar(20)                                     NULL,
    jurisdiction_code_desc_txt    varchar(255)                                    NULL,
    inv_state_case_id             varchar(199)                                    NULL,
    rdb_table_name_list           nvarchar(max)                                   NULL,
    case_management_uid           bigint                                          NULL,
    nac_page_case_uid             bigint                                          NULL,
    nac_last_chg_time             datetime                                        NULL,
    nac_add_time                  datetime                                        NULL,
    person_as_reporter_uid        bigint                                          NULL,
    hospital_uid                  bigint                                          NULL,
    ordering_facility_uid         bigint                                          NULL,
    refresh_datetime              datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime                  datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);


IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation' and xtype = 'U')
    BEGIN

--CNDE-1916
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'investigation_form_cd' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD investigation_form_cd VARCHAR(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'outbreak_name_desc' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation ADD outbreak_name_desc VARCHAR(100);
            END;

--CNDE-1802
        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notification_local_id' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation DROP COLUMN notification_local_id;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notification_add_time' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation DROP COLUMN notification_add_time;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notification_record_status_cd' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation DROP COLUMN notification_record_status_cd;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'notification_last_chg_time' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation DROP COLUMN notification_last_chg_time;
            END;

--CNDE-1602
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'investigation_count' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD investigation_count bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'case_count' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD case_count bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'investigator_assigned_datetime' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD investigator_assigned_datetime datetime;
            END;

--CNDE-1902
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'investigation_form_cd' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD investigation_form_cd VARCHAR(50);
            END;

--CNDE-1913
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ca_supervisor_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD ca_supervisor_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'closure_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD closure_investgr_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'dispo_fld_fupinvestgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD dispo_fld_fupinvestgr_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'fld_fup_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD fld_fup_investgr_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'fld_fup_prov_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD fld_fup_prov_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'fld_fup_supervisor_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD fld_fup_supervisor_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'init_fld_fup_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD init_fld_fup_investgr_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'init_fup_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD init_fup_investgr_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'init_interviewer_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD init_interviewer_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'interviewer_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD interviewer_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'surv_investgr_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD surv_investgr_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'fld_fup_facility_of_phc_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD fld_fup_facility_of_phc_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'org_as_hospital_of_delivery_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD org_as_hospital_of_delivery_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'per_as_provider_of_delivery_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD per_as_provider_of_delivery_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'per_as_provider_of_obgyn_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD per_as_provider_of_obgyn_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'per_as_provider_of_pediatrics_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD per_as_provider_of_pediatrics_uid bigint;
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'org_as_reporter_uid' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation ADD org_as_reporter_uid bigint;
            END;

--CNDE-1968
        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'jurisdiction_code' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation DROP jurisdiction_code;
            END;
        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'jurisdiction_code_desc_txt' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
            ALTER TABLE dbo.nrt_investigation DROP jurisdiction_code_desc_txt;
            END;
    END;