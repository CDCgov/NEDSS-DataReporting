SELECT
    ld.RECORD_STATUS_CD
FROM RDB_MODERN.dbo.LDF_DATA ld
JOIN RDB_MODERN.dbo.nrt_ldf_data_key k
  ON ld.ldf_data_key = k.d_ldf_data_key
WHERE k.business_object_uid = 96000600;
