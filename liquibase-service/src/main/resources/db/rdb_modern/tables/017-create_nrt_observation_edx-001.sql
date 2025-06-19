IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_edx' and xtype = 'U')
CREATE TABLE dbo.nrt_observation_edx
(
    edx_document_uid bigint   NOT NULL,
    edx_act_uid      bigint   NOT NULL,
    edx_add_time     datetime NOT NULL,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
    max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND object_id = OBJECT_ID('nrt_observation_edx'))
    BEGIN
        ALTER TABLE dbo.nrt_observation_edx
        ADD CONSTRAINT pk_nrt_observation_edx PRIMARY KEY (edx_document_uid, edx_act_uid,edx_add_time);
    END;