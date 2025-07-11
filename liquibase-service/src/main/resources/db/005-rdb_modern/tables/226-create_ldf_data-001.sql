IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'LDF_DATA'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE DBO.LDF_DATA (
               LDF_DATA_KEY         BIGINT NOT NULL,
               LDF_GROUP_KEY        BIGINT NULL,
               LDF_COLUMN_TYPE      VARCHAR(300) NULL,
               CONDITION_CD         VARCHAR(10) NULL,
               CONDITION_DESC_TXT   VARCHAR(100) NULL,
               CDC_NATIONAL_ID      VARCHAR(50) NULL,
               CLASS_CD             VARCHAR(20) NULL,
               CODE_SET_NM          VARCHAR(256) NULL,
               BUSINESS_OBJ_NM      VARCHAR(50) NULL,
               DISPLAY_ORDER_NUMBER INT,
               FIELD_SIZE           VARCHAR(10) NULL,
               LDF_VALUE            VARCHAR(2000) NULL,
               IMPORT_VERSION_NBR   BIGINT,
               LABEL_TXT 	    VARCHAR(300) NULL,
               LDF_OID		    VARCHAR(50) NULL,
               NND_IND		    VARCHAR(1) NULL,
               RECORD_STATUS_CD VARCHAR(8) NOT NULL
               CONSTRAINT CHK_LDFDATA_RECORD_STATUS CHECK(RECORD_STATUS_CD IN('ACTIVE' ,'INACTIVE'))
        );
         insert into dbo.ldf_data
                    (ldf_data_key
                    ,ldf_group_key
                    ,ldf_column_type
                    ,condition_cd
                    ,condition_desc_txt
                    ,cdc_national_id
                    ,class_cd
                    ,code_set_nm
                    ,business_obj_nm
                    ,display_order_number
                    ,field_size
                    ,ldf_value
                    ,import_version_nbr
                    ,label_txt
                    ,ldf_oid
                    ,nnd_ind
                    ,record_status_cd                    
                    )
                        values (1
                                ,1
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,'ACTIVE');
    END;