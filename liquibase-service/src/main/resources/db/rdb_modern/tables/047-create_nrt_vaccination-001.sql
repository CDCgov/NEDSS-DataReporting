IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_vaccination' and xtype = 'U')
CREATE TABLE dbo.nrt_vaccination
(
    VACCINATION_UID         bigint NOT NULL PRIMARY KEY,
    ADD_TIME                datetime NULL,
    ADD_USER_ID             numeric(18,0) NULL,
    AGE_AT_VACCINATION      smallint NULL,
    AGE_AT_VACCINATION_UNIT varchar(300) NULL,
    LAST_CHG_TIME           datetime NULL,
    LAST_CHG_USER_ID        numeric(18,0) NULL,
    LOCAL_ID                varchar(50) NULL,
    RECORD_STATUS_CD        varchar(20) NULL,
    RECORD_STATUS_TIME      datetime NULL,
    VACCINE_ADMINISTERED_DATE   datetime NULL,
    VACCINE_DOSE_NBR            smallint NULL,
    VACCINATION_ADMINISTERED_NM varchar(300) NULL,
    VACCINATION_ANATOMICAL_SITE varchar(300)  NULL,
    VACCINE_EXPIRATION_DT       datetime NULL,
    VACCINE_INFO_SOURCE         varchar(300) NULL,
    VACCINE_LOT_NUMBER_TXT      varchar(50) NULL,
    VACCINE_MANUFACTURER_NM     varchar(300) NULL,
    VERSION_CTRL_NBR            numeric(18,0) NULL,
    ELECTRONIC_IND              char(1) NULL,
    refresh_datetime    datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime        datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

