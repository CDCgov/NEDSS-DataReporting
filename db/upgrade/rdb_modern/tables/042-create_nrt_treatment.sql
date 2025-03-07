IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_treatment'
                 and xtype = 'U')
CREATE TABLE dbo.nrt_treatment
(
    treatment_uid                  varchar(100)                                    NOT NULL,
    public_health_case_uid         varchar(100)                                    NULL,
    organization_uid               varchar(100)                                    NULL,
    provider_uid                   varchar(100)                                    NULL,
    patient_treatment_uid          varchar(100)                                    NULL,
    morbidity_uid                  varchar(100)                                    NULL,
    Treatment_nm                   varchar(500)                                    NULL,
    Treatment_oid                  varchar(100)                                    NULL,
    Treatment_comments             varchar(500)                                    NULL,
    Treatment_shared_ind           varchar(100)                                    NULL,
    cd                             varchar(100)                                    NULL,
    Treatment_dt                   datetime                                        NULL,
    Treatment_drug                 varchar(100)                                    NULL,
    Treatment_drug_nm              varchar(500)                                    NULL,
    Treatment_dosage_strength      varchar(100)                                    NULL,
    Treatment_dosage_strength_unit varchar(100)                                    NULL,
    Treatment_frequency            varchar(100)                                    NULL,
    Treatment_duration             varchar(100)                                    NULL,
    Treatment_duration_unit        varchar(100)                                    NULL,
    Treatment_route                varchar(100)                                    NULL,
    LOCAL_ID                       varchar(100)                                    NULL,
    record_status_cd               varchar(100)                                    NULL,
    ADD_TIME                       datetime                                        NULL,
    ADD_USER_ID                    varchar(100)                                    NULL,
    LAST_CHG_TIME                  datetime                                        NULL,
    LAST_CHG_USER_ID               varchar(100)                                    NULL,
    VERSION_CTRL_NBR               varchar(100)                                    NULL,
    refresh_datetime               datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime                   datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
)
