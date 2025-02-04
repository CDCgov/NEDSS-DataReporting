IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation' and xtype = 'U')
CREATE TABLE dbo.nrt_observation
(
    observation_uid                         bigint                                          NOT NULL PRIMARY KEY,
    class_cd                                varchar(10)                                     NULL,
    mood_cd                                 varchar(10)                                     NULL,
    act_uid                                 bigint                                          NULL,
    cd_desc_txt                             varchar(1000)                                   NULL,
    record_status_cd                        varchar(20)                                     NULL,
    jurisdiction_cd                         varchar(20)                                     NULL,
    program_jurisdiction_oid                bigint                                          NULL,
    prog_area_cd                            varchar(20)                                     NULL,
    pregnant_ind_cd                         varchar(20)                                     NULL,
    local_id                                varchar(50)                                     NULL,
    activity_to_time                        datetime                                        NULL,
    effective_from_time                     datetime                                        NULL,
    rpt_to_state_time                       datetime                                        NULL,
    electronic_ind                          char(1)                                         NULL,
    version_ctrl_nbr                        smallint                                        NOT NULL,
    ordering_person_id                      bigint                                          NULL,
    patient_id                              bigint                                          NULL,
    result_observation_uid                  bigint                                          NULL,
    author_organization_id                  bigint                                          NULL,
    ordering_organization_id                bigint                                          NULL,
    performing_organization_id              bigint                                          NULL,
    material_id                             bigint                                          NULL,
    obs_domain_cd_st_1                      varchar(20)                                     NULL,
    processing_decision_cd                  varchar(20)                                     NULL,
    cd                                      varchar(50)                                     NULL,
    shared_ind                              char(1)                                         NULL,
    add_user_id                             bigint                                          NULL,
    add_user_name                           varchar(50)                                     NULL,
    add_time                                datetime                                        NULL,
    last_chg_user_id                        bigint                                          NULL,
    last_chg_user_name                      varchar(50)                                     NULL,
    last_chg_time                           datetime                                        NULL,
    ctrl_cd_display_form                    varchar(20)                                     NULL,
    status_cd                               char(1)                                         NULL,
    cd_system_cd                            varchar(50)                                     NULL,
    cd_system_desc_txt                      varchar(100)                                    NULL,
    ctrl_cd_user_defined_1                  varchar(20)                                     NULL,
    alt_cd                                  varchar(50)                                     NULL,
    alt_cd_desc_txt                         varchar(1000)                                   NULL,
    alt_cd_system_cd                        varchar(300)                                    NULL,
    alt_cd_system_desc_txt                  varchar(100)                                    NULL,
    method_cd                               varchar(2000)                                   NULL,
    method_desc_txt                         varchar(2000)                                   NULL,
    target_site_cd                          varchar(20)                                     NULL,
    target_site_desc_txt                    varchar(100)                                    NULL,
    txt                                     varchar(1000)                                   NULL,
    interpretation_cd                       varchar(20)                                     NULL,
    interpretation_desc_txt                 varchar(100)                                    NULL,
    report_observation_uid                  bigint                                          NULL,
    followup_observation_uid                nvarchar(max)                                   NULL,
    report_refr_uid                         bigint                                          NULL,
    report_sprt_uid                         bigint                                          NULL,
    morb_physician_id                       bigint                                          NULL,
    morb_reporter_id                        bigint                                          NULL,
    transcriptionist_id                     bigint                                          NULL,
    transcriptionist_val                    varchar(20)                                     NULL,
    transcriptionist_first_nm               varchar(50)                                     NULL,
    transcriptionist_last_nm                varchar(50)                                     NULL,
    assistant_interpreter_id                bigint                                          NULL,
    assistant_interpreter_val               varchar(20)                                     NULL,
    assistant_interpreter_first_nm          varchar(50)                                     NULL,
    assistant_interpreter_last_nm           varchar(50)                                     NULL,
    result_interpreter_id                   bigint                                          NULL,
    specimen_collector_id                   bigint                                          NULL,
    copy_to_provider_id                     bigint                                          NULL,
    lab_test_technician_id                  bigint                                          NULL,
    health_care_id                          bigint                                          NULL,
    morb_hosp_reporter_id                   bigint                                          NULL,
    accession_number                        varchar(199)                                    NULL,
    morb_hosp_id                            bigint                                          NULL,
    transcriptionist_id_assign_auth         varchar(199)                                    NULL,
    transcriptionist_auth_type              varchar(100)                                    NULL,
    assistant_interpreter_id_assign_auth    varchar(199)                                    NULL,
    assistant_interpreter_auth_type         varchar(100)                                    NULL,
    priority_cd                             varchar(20)                                     NULL,
    record_status_time                      datetime                                        NULL,
    status_time                             datetime                                        NULL,
    refresh_datetime                        datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime                            datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

