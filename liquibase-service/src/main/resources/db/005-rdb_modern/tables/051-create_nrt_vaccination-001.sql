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
    provider_uid            bigint NULL,
    organization_uid        bigint NULL,
    phc_uid                 bigint NULL,
    patient_uid             bigint NULL,
    refresh_datetime    datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime        datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1
           FROM sysobjects
           WHERE name = 'nrt_vaccination'
             and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1
                      FROM sys.columns
                      WHERE name = N'status_time'
                        AND Object_ID = Object_ID(N'nrt_vaccination'))
            BEGIN
                ALTER TABLE dbo.nrt_vaccination
                    ADD status_time datetime;
            END;

        IF NOT EXISTS(SELECT 1
                      FROM sys.columns
                      WHERE name = N'prog_area_cd'
                        AND Object_ID = Object_ID(N'nrt_vaccination'))
            BEGIN
                ALTER TABLE dbo.nrt_vaccination
                    ADD prog_area_cd varchar(20);
            END;

        IF NOT EXISTS(SELECT 1
                      FROM sys.columns
                      WHERE name = N'jurisdiction_cd'
                        AND Object_ID = Object_ID(N'nrt_vaccination'))
            BEGIN
                ALTER TABLE dbo.nrt_vaccination
                    ADD jurisdiction_cd varchar(20);
            END;

        IF NOT EXISTS(SELECT 1
                      FROM sys.columns
                      WHERE name = N'program_jurisdiction_oid'
                        AND Object_ID = Object_ID(N'nrt_vaccination'))
            BEGIN
                ALTER TABLE dbo.nrt_vaccination
                    ADD program_jurisdiction_oid bigint;
            END;

        --CNDE-2526
        IF NOT EXISTS(SELECT 1
                      FROM sys.columns
                      WHERE name = N'material_cd'
                        AND Object_ID = Object_ID(N'nrt_vaccination'))
            BEGIN
                ALTER TABLE dbo.nrt_vaccination
                    ADD material_cd varchar(20);
            END;
        -- CNDE - 3045
        IF EXISTS(SELECT 1
                  FROM sys.columns
                  WHERE name = N'phc_uid'
                    AND Object_ID = Object_ID(N'nrt_vaccination'))
            BEGIN
                ALTER TABLE dbo.nrt_vaccination
                    ALTER COLUMN phc_uid NVARCHAR(MAX);
            END;
        
    END;


