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
    treatment_name                 varchar(500)                                    NULL,
    treatment_oid                  varchar(100)                                    NULL,
    treatment_comments             varchar(500)                                    NULL,
    treatment_shared_ind           varchar(100)                                    NULL,
    cd                             varchar(100)                                    NULL,
    treatment_date                 datetime                                        NULL,
    treatment_drug                 varchar(100)                                    NULL,
    treatment_drug_name            varchar(500)                                    NULL,
    treatment_dosage_strength      varchar(100)                                    NULL,
    treatment_dosage_strength_unit varchar(100)                                    NULL,
    treatment_frequency            varchar(100)                                    NULL,
    treatment_duration             varchar(100)                                    NULL,
    treatment_duration_unit        varchar(100)                                    NULL,
    treatment_route                varchar(100)                                    NULL,
    local_id                       varchar(100)                                    NULL,
    record_status_cd               varchar(100)                                    NULL,
    add_time                       datetime                                        NULL,
    add_user_id                    varchar(100)                                    NULL,
    last_chg_time                  datetime                                        NULL,
    last_chg_user_id               varchar(100)                                    NULL,
    version_ctrl_nbr               varchar(100)                                    NULL,
    refresh_datetime               datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime                   datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
)