IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_material' and xtype = 'U')
CREATE TABLE dbo.nrt_observation_material (
    act_uid                         bigint                                          NOT NULL,
    type_cd                         varchar(50)                                     NULL,
    material_id                     bigint                                          NOT NULL,
    subject_class_cd                varchar(10)                                     NULL,
    record_status                   varchar(20)                                     NULL,
    type_desc_txt                   varchar(100)                                    NULL,
    last_chg_time                   datetime                                        NULL,
    material_cd                     varchar(50)                                     NULL,
    material_nm                     varchar(50)                                     NULL,
    material_details                varchar(1000)                                   NULL,
    material_collection_vol         varchar(20)                                     NULL,
    material_collection_vol_unit    varchar(20)                                     NULL,
    material_desc                   varchar(100)                                    NULL,
    risk_cd                         varchar(20)                                     NULL,
    risk_desc_txt                   varchar(100)                                    NULL,
    refresh_datetime                datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime                    datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);