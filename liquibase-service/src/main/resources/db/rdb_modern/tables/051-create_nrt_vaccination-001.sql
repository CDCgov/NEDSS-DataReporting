IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_vaccination' and xtype = 'U')
CREATE TABLE dbo.nrt_vaccination
(
    vaccination_uid         bigint NOT NULL PRIMARY KEY,
    add_time                datetime NULL,
    add_user_id             numeric(18,0) NULL,
    age_at_vaccination      smallint NULL,
    age_at_vaccination_unit varchar(300) NULL,
    last_chg_time           datetime NULL,
    last_chg_user_id        numeric(18,0) NULL,
    local_id                varchar(50) NULL,
    record_status_cd        varchar(20) NULL,
    record_status_time      datetime NULL,
    vaccine_administered_date   datetime NULL,
    vaccine_dose_nbr            smallint NULL,
    vaccination_administered_nm varchar(300) NULL,
    vaccination_anatomical_site varchar(300)  NULL,
    vaccine_expiration_dt       datetime NULL,
    vaccine_info_source         varchar(300) NULL,
    vaccine_lot_number_txt      varchar(50) NULL,
    vaccine_manufacturer_nm     varchar(300) NULL,
    version_ctrl_nbr            numeric(18,0) NULL,
    electronic_ind              char(1) NULL,
    refresh_datetime    datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime        datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

