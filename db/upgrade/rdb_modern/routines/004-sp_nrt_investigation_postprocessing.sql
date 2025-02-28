CREATE OR ALTER PROCEDURE dbo.sp_nrt_investigation_postprocessing @id_list nvarchar(max),@debug bit = 'false'
AS
BEGIN
    /*
     * [Description]
     * This stored procedure is handles event based updates to Investigation, Confirmation
     * Method and Confirmation Method Group Dimensions.
     *
     * 1. Receives input list of Public_health_case_uids.
     * 2. Pulls records from nrt_investigation, nrt_investigation_observation and
     * nrt_investigation_confirmation to insert/update dimensions.
     * 3. Returns datamart signal if condition code exists in nrt_datamart_metadata.
     * */

    BEGIN TRY

        /* Logging */
        declare @rowcount bigint;
        declare @proc_step_no float = 0;
        declare @proc_step_name varchar(200) = '';
        declare @batch_id bigint;
        declare @create_dttm datetime2(7) = current_timestamp;
        declare @update_dttm datetime2(7) = current_timestamp;
        declare @dataflow_name varchar(200) = 'Investigation POST-Processing';
        declare @package_name varchar(200) = 'sp_nrt_investigation_postprocessing';

        set @batch_id = cast((format(getdate(), 'yyMMddHHmmss')) as bigint);

        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[msg_description1]
        ,[row_count])
        VALUES (@batch_id
               ,@create_dttm
               ,@update_dttm
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,0
               ,'SP_Start'
               ,LEFT(@id_list, 500)
               ,0);

        SET @proc_step_name = 'Create INVESTIGATION Temp table -' + LEFT(@id_list, 160);
        SET @proc_step_no = 1;

        /* Temp investigation table creation*/
        select INVESTIGATION_KEY,
               public_health_case_uid          as CASE_UID,
               program_jurisdiction_oid        as CASE_OID,
               nrt.local_id                    as INV_LOCAL_ID,
               nrt.shared_ind                  as INV_SHARE_IND,
               NULLIF(nrt.outbreak_name,'')               as OUTBREAK_NAME,
               nrt.investigation_status        as INVESTIGATION_STATUS,
               nrt.inv_case_status             as INV_CASE_STATUS,
               nrt.case_type_cd                as CASE_TYPE,
               NULLIF(nrt.txt,'')			   as INV_COMMENTS,
               nrt.jurisdiction_cd             as JURISDICTION_CD,
               nrt.jurisdiction_nm             as JURISDICTION_NM,
               nrt.earliest_rpt_to_phd_dt      as EARLIEST_RPT_TO_PHD_DT,
               nrt.effective_from_time         as ILLNESS_ONSET_DT,
               nrt.effective_to_time           as ILLNESS_END_DT,
               nrt.rpt_form_cmplt_time         as INV_RPT_DT,
               nrt.activity_from_time          as INV_START_DT,
               nrt.rpt_src_cd_desc             as RPT_SRC_CD_DESC,
               nrt.rpt_to_county_time          as EARLIEST_RPT_TO_CNTY_DT,
               nrt.rpt_to_state_time           as EARLIEST_RPT_TO_STATE_DT,
               nrt.mmwr_week                   as CASE_RPT_MMWR_WK,
               nrt.mmwr_year                   as CASE_RPT_MMWR_YR,
               nrt.disease_imported_ind        as DISEASE_IMPORTED_IND,
               NULLIF(nrt.imported_from_country,'')        as IMPORT_FRM_CNTRY,
               NULLIF(nrt.imported_from_state,'')          as IMPORT_FRM_STATE,
               NULLIF(nrt.imported_from_county,'')         as IMPORT_FRM_CNTY,
               NULLIF(nrt.imported_city_desc_txt,'')       as IMPORT_FRM_CITY,
               nrt.earliest_rpt_to_cdc_dt      as EARLIEST_RPT_TO_CDC_DT,
               NULLIF(nrt.rpt_source_cd,'')               as RPT_SRC_CD,
               NULLIF(nrt.imported_country_cd,'')          as IMPORT_FRM_CNTRY_CD,
               NULLIF(nrt.imported_state_cd,'')            as IMPORT_FRM_STATE_CD,
               NULLIF(nrt.imported_county_cd,'')           as IMPORT_FRM_CNTY_CD,
               NULLIF(nrt.import_frm_city_cd,'')           as IMPORT_FRM_CITY_CD,
               nrt.diagnosis_time              as DIAGNOSIS_DT,
               nrt.hospitalized_admin_time     as HSPTL_ADMISSION_DT,
               nrt.hospitalized_discharge_time as HSPTL_DISCHARGE_DT,
               nrt.hospitalized_duration_amt   as HSPTL_DURATION_DAYS,
               nrt.outbreak_ind_val            as OUTBREAK_IND,
               nrt.hospitalized_ind            as HSPTLIZD_IND,
               CASE WHEN nrt.inv_state_case_id = '' OR nrt.inv_state_case_id = 'null' THEN NULL
                    ELSE  nrt.inv_state_case_id END          as INV_STATE_CASE_ID,
               NULLIF(nrt.city_county_case_nbr,'')        as CITY_COUNTY_CASE_NBR,
               nrt.transmission_mode           as TRANSMISSION_MODE,
               nrt.record_status_cd            as RECORD_STATUS_CD,
               nrt.pregnant_ind                as PATIENT_PREGNANT_IND,
               nrt.die_frm_this_illness_ind    as DIE_FRM_THIS_ILLNESS_IND,
               nrt.day_care_ind                as DAYCARE_ASSOCIATION_IND,
               nrt.food_handler_ind            as FOOD_HANDLR_IND,
               nrt.deceased_time               as INVESTIGATION_DEATH_DATE,
               case
                   when isnumeric(nrt.pat_age_at_onset) = 1 then cast(nrt.pat_age_at_onset as int)
                   else null
                   end                         as PATIENT_AGE_AT_ONSET,
               nrt.pat_age_at_onset_unit       as PATIENT_AGE_AT_ONSET_UNIT,
               nrt.investigator_assigned_time  as INV_ASSIGNED_DT,
               nrt.detection_method_desc_txt   as DETECTION_METHOD_DESC_TXT,
               case
                   when isnumeric(nrt.effective_duration_amt) = 1 then cast(nrt.effective_duration_amt as int)
                   else null
                   end                         as ILLNESS_DURATION,
               nrt.illness_duration_unit       as ILLNESS_DURATION_UNIT,
               NULLIF(nrt.contact_inv_txt,'')             as CONTACT_INV_COMMENTS,
               nrt.contact_inv_priority        as CONTACT_INV_PRIORITY,
               nrt.infectious_from_date        as CONTACT_INFECTIOUS_FROM_DATE,
               nrt.infectious_to_date          as CONTACT_INFECTIOUS_TO_DATE,
               nrt.contact_inv_status          as CONTACT_INV_STATUS,
               nrt.activity_to_time            as INV_CLOSE_DT,
               nrt.program_area_description    as PROGRAM_AREA_DESCRIPTION,
               nrt.add_time                    as ADD_TIME,
               nrt.last_chg_time               as LAST_CHG_TIME,
               nrt.add_user_name               as INVESTIGATION_ADDED_BY,
               nrt.last_chg_user_name          as INVESTIGATION_LAST_UPDATED_BY,
               nrt.referral_basis              as REFERRAL_BASIS,
               nrt.curr_process_state          as CURR_PROCESS_STATE,
               nrt.inv_priority_cd             as INV_PRIORITY_CD,
               nrt.coinfection_id              as COINFECTION_ID,
               NULLIF(nrt.legacy_case_id,'')              as LEGACY_CASE_ID,
               NULLIF(nrt.outbreak_name_desc, '')               as OUTBREAK_NAME_DESC,
               nrt.cd,
               nrt.investigation_form_cd,
               nrt.investigator_assigned_datetime as INV_ASSIGNED_DT_LEGACY,
               nrt.patient_id
        into #temp_inv_table
        from dbo.nrt_investigation nrt
                 left join dbo.investigation i with (nolock) on i.case_uid = nrt.public_health_case_uid
        where nrt.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@id_list, ','));

        IF @debug = 'true' SELECT * FROM #temp_inv_table;

        /* Logging */
        set @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500));



        SET @proc_step_name = 'Update Legacy Investigation Values -' + LEFT(@id_list, 160);
        SET @proc_step_no = 1;


        /* Sub-step: Update Investigation values for Legacy Investigation Forms. */
        DECLARE @COUNT_LEGACY_INV AS int;
        SET @COUNT_LEGACY_INV =
                (
                    SELECT COUNT(*)
                    FROM #temp_inv_table tmp
                    WHERE tmp.investigation_form_cd IN ('INV_FORM_BMDGAS','INV_FORM_BMDGBS','INV_FORM_BMDGEN','INV_FORM_BMDNM','INV_FORM_BMDHI',
                                                        'INV_FORM_BMDSP','INV_FORM_GEN','INV_FORM_HEPA','INV_FORM_HEPBV','INV_FORM_HEPCV',
                                                        'INV_FORM_HEPGEN','INV_FORM_MEA','INV_FORM_PER','INV_FORM_RUB')
                );


        IF (@COUNT_LEGACY_INV>0)
            BEGIN


                SELECT nio.public_health_case_uid, nio.observation_id, nio.branch_id, nio.branch_type_cd
                INTO #temp_inv_obs
                FROM #temp_inv_table t
                         LEFT JOIN dbo.nrt_investigation_observation nio on nio.public_health_case_uid = t.case_uid
                WHERE nio.branch_type_cd = 'InvFrmQ';

                IF @debug = 'true' SELECT '#temp_inv_obs', * FROM #temp_inv_table;

                /*Coded*/
                SELECT
                    tnio.public_health_case_uid
                     ,tnio.observation_id
                     ,tnio.branch_id
                     ,tnio.branch_type_cd
                     ,c.cd
                     ,c.response
                     ,c.response_cd
                INTO #tmp_coded
                FROM #temp_inv_obs tnio with (nolock)
                         INNER JOIN dbo.v_getobscode c with (nolock) on tnio.branch_id = c.branch_id
                WHERE c.cd IN 	('INV153',	/* Import country*/
                                  'INV154', 	/* state*/
                                  'INV156', 	/* county*/
                                  'INV128',	/* HSPTLIZD_IND*/
                                  'RUB162',  /* DIE_FRM_THIS_ILLNESS_IND */
                                  'MEA078',  /* DIE_FRM_THIS_ILLNESS_IND */
                                  'PRT103', 	/* DIE_FRM_THIS_ILLNESS_IND */
                                  'INV145',	/* DIE_FRM_THIS_ILLNESS_IND in Generic */
                                  'INV149',  /* FOOD_HANDLR_IND */
                                  'INV178',  /* PATIENT_PREGNANT_IND */
                                  'INV148');  /* DAYCARE_ASSOCIATION_IND */

                IF @debug = 'true' SELECT '#tmp_coded', * FROM #tmp_coded;

                /*Text*/
                SELECT
                    tnio.public_health_case_uid
                     ,tnio.observation_id
                     ,tnio.branch_id
                     ,tnio.branch_type_cd
                     ,t.cd
                     ,t.response
                INTO #tmp_txt
                FROM #temp_inv_obs tnio with (nolock)
                         INNER JOIN dbo.v_getobstxt t with (nolock) ON tnio.branch_id = t.branch_id
                WHERE t.cd = 'INV155'; /* city */

                IF @debug = 'true' SELECT '#tmp_txt', * FROM #tmp_txt;

                /*Numeric*/
                SELECT
                    tnio.public_health_case_uid
                     ,tnio.observation_id
                     ,tnio.branch_id
                     ,tnio.branch_type_cd
                     ,n.cd
                     ,n.response
                INTO #tmp_num
                FROM #temp_inv_obs tnio with (nolock)
                         INNER JOIN dbo.v_getobsnum n with (nolock) ON tnio.branch_id = n.branch_id
                WHERE n.cd = 'INV134'; /* HSPTL_DURATION_DAYS */

                IF @debug = 'true' SELECT '#tmp_num', * FROM #tmp_num;

                /*Numeric*/
                SELECT
                    tnio.public_health_case_uid
                     ,tnio.observation_id
                     ,tnio.branch_id
                     ,tnio.branch_type_cd
                     ,d.cd
                     ,d.response
                INTO #tmp_date
                FROM #temp_inv_obs tnio
                         INNER JOIN dbo.v_getobsdate d on tnio.branch_id = d.branch_id
                WHERE d.cd IN ('INV132',	/* HSPTL_ADMISSION_DT */
                               'INV133'		/* HSPTL_DISCHARGE_DT */
                    );

                IF @debug = 'true' SELECT '#tmp_date', * FROM #tmp_date;


                SELECT
                    tnio.public_health_case_uid,
                    max(CASE WHEN c.cd = 'INV128' THEN c.response
                             ELSE NULL END) AS HSPTLIZD_IND,
                    max(CASE WHEN c.cd = 'INV153' THEN c.response_cd
                             ELSE NULL END) AS IMPORT_FRM_CNTRY_CD,
                    max(CASE WHEN c.cd = 'INV153' THEN c.response
                             ELSE NULL END) AS IMPORT_FRM_CNTRY,
                    max(CASE WHEN c.cd = 'INV154' THEN c.response_cd
                             ELSE NULL END) AS IMPORT_FRM_STATE_CD,
                    max(CASE WHEN c.cd = 'INV154' THEN c.response
                             ELSE NULL END) AS IMPORT_FRM_STATE,
                    max(CASE WHEN c.cd = 'INV156' THEN c.response_cd
                             ELSE NULL END) AS IMPORT_FRM_CNTY_CD,
                    max(CASE WHEN c.cd = 'INV156' THEN c.response
                             ELSE NULL END) AS IMPORT_FRM_CNTY,
                    max(CASE WHEN c.cd = 'INV149' THEN c.response
                             ELSE NULL END) AS FOOD_HANDLR_IND,
                    max(CASE WHEN c.cd = 'INV178' THEN c.response
                             ELSE NULL END) AS PATIENT_PREGNANT_IND,
                    max(CASE WHEN c.cd = 'INV148' THEN c.response
                             ELSE NULL END) AS DAYCARE_ASSOCIATION_IND,
                    max(CASE WHEN c.cd = 'INV145' THEN c.response
                             ELSE NULL END) AS DIE_FRM_THIS_ILLNESS_IND_INV145,
                    max(CASE WHEN c.cd = 'RUB162' THEN c.response
                             ELSE NULL END) AS DIE_FRM_THIS_ILLNESS_IND_RUB162,
                    max(CASE WHEN c.cd = 'MEA078' THEN c.response
                             ELSE NULL END) AS DIE_FRM_THIS_ILLNESS_IND_MEA078,
                    max(CASE WHEN c.cd = 'PRT103' THEN c.response
                             ELSE NULL END) AS DIE_FRM_THIS_ILLNESS_IND_PRT103,
                    max(CASE WHEN t.cd = 'INV155' THEN t.response
                             ELSE NULL END) AS IMPORT_FRM_CITY,
                    max(CASE WHEN d.cd = 'INV132' THEN d.response
                             ELSE NULL END) AS HSPTL_ADMISSION_DT,
                    max(CASE WHEN d.cd = 'INV133' THEN d.response
                             ELSE NULL END) AS HSPTL_DISCHARGE_DT,
                    max(CASE WHEN n.cd = 'INV134' THEN n.response
                             ELSE NULL END) AS HSPTL_DURATION_DAYS
                INTO #final_inv_obs
                FROM #temp_inv_obs tnio with (nolock)
                         LEFT JOIN #tmp_coded c with (nolock) on tnio.public_health_case_uid = c.public_health_case_uid
                         LEFT JOIN #tmp_txt t with (nolock) on tnio.public_health_case_uid = t.public_health_case_uid
                         LEFT JOIN #tmp_num n with (nolock) on tnio.public_health_case_uid = n.public_health_case_uid
                         LEFT JOIN #tmp_date d with (nolock) on tnio.observation_id = d.observation_id
                GROUP BY tnio.public_health_case_uid;

                IF @debug = 'true' SELECT '#final_inv_obs', * FROM #final_inv_obs;

                /*Update statement considers Investigation codes that are mapped directly. The non-null condition is selected.*/
                UPDATE tmp
                SET
                    HSPTLIZD_IND = COALESCE(tmp.HSPTLIZD_IND, obs.HSPTLIZD_IND),
                    IMPORT_FRM_CNTRY_CD = COALESCE(tmp.IMPORT_FRM_CNTRY_CD,obs.IMPORT_FRM_CNTRY_CD),
                    IMPORT_FRM_CNTRY = COALESCE(tmp.IMPORT_FRM_CNTRY,obs.IMPORT_FRM_CNTRY),
                    IMPORT_FRM_STATE_CD = COALESCE(tmp.IMPORT_FRM_STATE_CD, obs.IMPORT_FRM_STATE_CD),
                    IMPORT_FRM_STATE = COALESCE(tmp.IMPORT_FRM_STATE, obs.IMPORT_FRM_STATE),
                    IMPORT_FRM_CNTY_CD = COALESCE(tmp.IMPORT_FRM_CNTY_CD, obs.IMPORT_FRM_CNTY_CD),
                    IMPORT_FRM_CNTY = COALESCE(tmp.IMPORT_FRM_CNTY, obs.IMPORT_FRM_CNTY),
                    FOOD_HANDLR_IND = COALESCE(tmp.FOOD_HANDLR_IND, obs.FOOD_HANDLR_IND),
                    PATIENT_PREGNANT_IND = COALESCE(tmp.PATIENT_PREGNANT_IND, obs.PATIENT_PREGNANT_IND),
                    DAYCARE_ASSOCIATION_IND = COALESCE(tmp.DAYCARE_ASSOCIATION_IND, obs.DAYCARE_ASSOCIATION_IND),
                    DIE_FRM_THIS_ILLNESS_IND = CASE WHEN obs.DIE_FRM_THIS_ILLNESS_IND_INV145 IS NOT NULL THEN obs.DIE_FRM_THIS_ILLNESS_IND_INV145
                                                    ELSE COALESCE(tmp.DIE_FRM_THIS_ILLNESS_IND,obs.DIE_FRM_THIS_ILLNESS_IND_PRT103, obs.DIE_FRM_THIS_ILLNESS_IND_MEA078, obs.DIE_FRM_THIS_ILLNESS_IND_RUB162)
                        END,
                    IMPORT_FRM_CITY = COALESCE(tmp.IMPORT_FRM_CITY, obs.IMPORT_FRM_CITY),
                    HSPTL_ADMISSION_DT = COALESCE(tmp.HSPTL_ADMISSION_DT, obs.HSPTL_ADMISSION_DT),
                    HSPTL_DISCHARGE_DT = COALESCE(tmp.HSPTL_DISCHARGE_DT, obs.HSPTL_DISCHARGE_DT),
                    HSPTL_DURATION_DAYS = COALESCE(tmp.HSPTL_DURATION_DAYS, obs.HSPTL_DURATION_DAYS),
                    INV_ASSIGNED_DT = COALESCE(tmp.INV_ASSIGNED_DT, tmp.INV_ASSIGNED_DT_LEGACY)
                FROM #temp_inv_table tmp with (nolock)
                         LEFT JOIN #final_inv_obs obs with (nolock) on tmp.case_uid = obs.public_health_case_uid;

                IF @debug = 'true' SELECT '#temp_inv_table', * FROM #temp_inv_table;

                /* Logging */
                set @rowcount = @@rowcount
                INSERT INTO [dbo].[job_flow_log]
                (batch_id
                ,[Dataflow_Name]
                ,[package_Name]
                ,[Status_Type]
                ,[step_number]
                ,[step_name]
                ,[row_count]
                ,[msg_description1])
                VALUES (@batch_id
                       ,@dataflow_name
                       ,@package_name
                       ,'START'
                       ,@proc_step_no
                       ,@proc_step_name
                       ,@rowcount
                       ,LEFT(@id_list, 500));

            END


        /* Investigation Update Operation */
        BEGIN TRANSACTION;
        SET @proc_step_name = 'Update INVESTIGATION Dimension';
        SET @proc_step_no = 2;

        update dbo.INVESTIGATION
        set [INVESTIGATION_KEY]             = inv.INVESTIGATION_KEY,
            [CASE_OID]         = inv.CASE_OID,
            [CASE_UID]                      = inv.CASE_UID,
            [INV_LOCAL_ID]    = inv.INV_LOCAL_ID,
            [INV_SHARE_IND] = inv.INV_SHARE_IND,
            [OUTBREAK_NAME]                 = inv.OUTBREAK_NAME,
            [INVESTIGATION_STATUS]          = inv.INVESTIGATION_STATUS,
            [INV_CASE_STATUS]               = inv.INV_CASE_STATUS,
            [CASE_TYPE]                     = inv.CASE_TYPE,
            [INV_COMMENTS]                  = inv.INV_COMMENTS,
            [JURISDICTION_CD]               = inv.JURISDICTION_CD,
            [JURISDICTION_NM]               = inv.JURISDICTION_NM,
            [EARLIEST_RPT_TO_PHD_DT]        = inv.EARLIEST_RPT_TO_PHD_DT,
            [ILLNESS_ONSET_DT]              = inv.ILLNESS_ONSET_DT,
            [ILLNESS_END_DT]                = inv.ILLNESS_END_DT,
            [INV_RPT_DT]                    = inv.INV_RPT_DT,
            [INV_START_DT]                  = inv.INV_START_DT,
            [RPT_SRC_CD_DESC]               = inv.RPT_SRC_CD_DESC,
            [EARLIEST_RPT_TO_CNTY_DT]      = inv.EARLIEST_RPT_TO_CNTY_DT,
            [EARLIEST_RPT_TO_STATE_DT]      = inv.EARLIEST_RPT_TO_STATE_DT,
            [CASE_RPT_MMWR_WK]              = inv.CASE_RPT_MMWR_WK,
            [CASE_RPT_MMWR_YR]              = inv.CASE_RPT_MMWR_YR,
            [DISEASE_IMPORTED_IND]          = inv.DISEASE_IMPORTED_IND,
            [IMPORT_FRM_CNTRY]              = inv.IMPORT_FRM_CNTRY,
            [IMPORT_FRM_STATE]              = inv.IMPORT_FRM_STATE,
            [IMPORT_FRM_CNTY]               = inv.IMPORT_FRM_CNTY,
            [IMPORT_FRM_CITY]               = inv.IMPORT_FRM_CITY,
            [EARLIEST_RPT_TO_CDC_DT]        = inv.EARLIEST_RPT_TO_CDC_DT,
            [RPT_SRC_CD]                    = inv.RPT_SRC_CD,
            [IMPORT_FRM_CNTRY_CD]           = inv.IMPORT_FRM_CNTRY_CD,
            [IMPORT_FRM_STATE_CD]           = inv.IMPORT_FRM_STATE_CD,
            [IMPORT_FRM_CNTY_CD]            = inv.IMPORT_FRM_CNTY_CD,
            [IMPORT_FRM_CITY_CD]            = inv.IMPORT_FRM_CITY_CD,
            [DIAGNOSIS_DT]                  = inv.DIAGNOSIS_DT,
            [HSPTL_ADMISSION_DT]            = inv.HSPTL_ADMISSION_DT,
            [HSPTL_DISCHARGE_DT]            = inv.HSPTL_DISCHARGE_DT,
            [HSPTL_DURATION_DAYS]           = inv.HSPTL_DURATION_DAYS,
            [OUTBREAK_IND]                  = inv.OUTBREAK_IND,
            [HSPTLIZD_IND]                  = inv.HSPTLIZD_IND,
            [INV_STATE_CASE_ID]             = inv.INV_STATE_CASE_ID,
            [CITY_COUNTY_CASE_NBR]          = inv.CITY_COUNTY_CASE_NBR,
            [TRANSMISSION_MODE]             = inv.TRANSMISSION_MODE,
            [RECORD_STATUS_CD]              = inv.RECORD_STATUS_CD,
            [PATIENT_PREGNANT_IND]          = inv.PATIENT_PREGNANT_IND,
            [DIE_FRM_THIS_ILLNESS_IND]      = inv.DIE_FRM_THIS_ILLNESS_IND,
            [DAYCARE_ASSOCIATION_IND]       = inv.DAYCARE_ASSOCIATION_IND,
            [FOOD_HANDLR_IND]               = inv.FOOD_HANDLR_IND,
            [INVESTIGATION_DEATH_DATE]      = inv.INVESTIGATION_DEATH_DATE,
            [PATIENT_AGE_AT_ONSET]          = inv.PATIENT_AGE_AT_ONSET,
            [PATIENT_AGE_AT_ONSET_UNIT]     = inv.PATIENT_AGE_AT_ONSET_UNIT,
            [INV_ASSIGNED_DT]               = inv.INV_ASSIGNED_DT,
            [DETECTION_METHOD_DESC_TXT]     = inv.DETECTION_METHOD_DESC_TXT,
            [ILLNESS_DURATION]              = inv.ILLNESS_DURATION,
            [ILLNESS_DURATION_UNIT]         = inv.ILLNESS_DURATION_UNIT,
            [CONTACT_INV_COMMENTS]          = inv.CONTACT_INV_COMMENTS,
            [CONTACT_INV_PRIORITY]          = inv.CONTACT_INV_PRIORITY,
            [CONTACT_INFECTIOUS_FROM_DATE]  = inv.CONTACT_INFECTIOUS_FROM_DATE,
            [CONTACT_INFECTIOUS_TO_DATE]    = inv.CONTACT_INFECTIOUS_TO_DATE,
            [CONTACT_INV_STATUS]            = inv.CONTACT_INV_STATUS,
            [PROGRAM_AREA_DESCRIPTION]      = inv.PROGRAM_AREA_DESCRIPTION,
            [ADD_TIME]          = inv.ADD_TIME,
            [LAST_CHG_TIME]                 = inv.LAST_CHG_TIME,
            [INVESTIGATION_ADDED_BY]        = inv.INVESTIGATION_ADDED_BY,
            [INVESTIGATION_LAST_UPDATED_BY] = inv.INVESTIGATION_LAST_UPDATED_BY,
            [REFERRAL_BASIS]                = inv.REFERRAL_BASIS,
            [CURR_PROCESS_STATE]            = inv.CURR_PROCESS_STATE,
            [INV_PRIORITY_CD]               = inv.INV_PRIORITY_CD,
            [COINFECTION_ID]                = inv.COINFECTION_ID,
            [LEGACY_CASE_ID]                = inv.LEGACY_CASE_ID,
            [OUTBREAK_NAME_DESC]            = inv.OUTBREAK_NAME_DESC,
            [INV_CLOSE_DT]            = inv.INV_CLOSE_DT
        from #temp_inv_table inv
                 inner join dbo.investigation i with (nolock) on inv.case_uid = i.case_uid
            and inv.investigation_key = i.investigation_key
            and i.investigation_key is not null;

        /* Logging */
        set @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500));


        /* Investigation Insert Operation */
        SET @proc_step_name = 'Insert into INVESTIGATION Dimension';
        SET @proc_step_no = 3;

        -- delete from the key table to generate new keys for the resulting new data to be inserted
        delete from dbo.nrt_investigation_key;
        insert into dbo.nrt_investigation_key(case_uid)
        select case_uid
        from #temp_inv_table
        where investigation_key is null
        order by case_uid;

        insert into dbo.INVESTIGATION
        ([INVESTIGATION_KEY],
         [CASE_OID],
         [CASE_UID],
         [INV_LOCAL_ID],
         [INV_SHARE_IND],
         [OUTBREAK_NAME],
         [INVESTIGATION_STATUS],
         [INV_CASE_STATUS],
         [CASE_TYPE],
         [INV_COMMENTS],
         [JURISDICTION_CD],
         [JURISDICTION_NM],
         [EARLIEST_RPT_TO_PHD_DT],
         [ILLNESS_ONSET_DT],
         [ILLNESS_END_DT],
         [INV_RPT_DT],
         [INV_START_DT],
         [RPT_SRC_CD_DESC],
         [EARLIEST_RPT_TO_CNTY_DT],
         [EARLIEST_RPT_TO_STATE_DT],
         [CASE_RPT_MMWR_WK],
         [CASE_RPT_MMWR_YR],
         [DISEASE_IMPORTED_IND],
         [IMPORT_FRM_CNTRY],
         [IMPORT_FRM_STATE],
         [IMPORT_FRM_CNTY],
         [IMPORT_FRM_CITY],
         [EARLIEST_RPT_TO_CDC_DT],
         [RPT_SRC_CD],
         [IMPORT_FRM_CNTRY_CD],
         [IMPORT_FRM_STATE_CD],
         [IMPORT_FRM_CNTY_CD],
         [IMPORT_FRM_CITY_CD],
         [DIAGNOSIS_DT],
         [HSPTL_ADMISSION_DT],
         [HSPTL_DISCHARGE_DT],
         [HSPTL_DURATION_DAYS],
         [OUTBREAK_IND],
         [HSPTLIZD_IND],
         [INV_STATE_CASE_ID],
         [CITY_COUNTY_CASE_NBR],
         [TRANSMISSION_MODE],
         [RECORD_STATUS_CD],
         [PATIENT_PREGNANT_IND],
         [DIE_FRM_THIS_ILLNESS_IND],
         [DAYCARE_ASSOCIATION_IND],
         [FOOD_HANDLR_IND],
         [INVESTIGATION_DEATH_DATE],
         [PATIENT_AGE_AT_ONSET],
         [PATIENT_AGE_AT_ONSET_UNIT],
         [INV_ASSIGNED_DT],
         [DETECTION_METHOD_DESC_TXT],
         [ILLNESS_DURATION],
         [ILLNESS_DURATION_UNIT],
         [CONTACT_INV_COMMENTS],
         [CONTACT_INV_PRIORITY],
         [CONTACT_INFECTIOUS_FROM_DATE],
         [CONTACT_INFECTIOUS_TO_DATE],
         [CONTACT_INV_STATUS],
         [PROGRAM_AREA_DESCRIPTION],
         [ADD_TIME],
         [LAST_CHG_TIME],
         [INVESTIGATION_ADDED_BY],
         [INVESTIGATION_LAST_UPDATED_BY],
         [REFERRAL_BASIS],
         [CURR_PROCESS_STATE],
         [INV_PRIORITY_CD],
         [COINFECTION_ID],
         [LEGACY_CASE_ID],
         [OUTBREAK_NAME_DESC],
         [INV_CLOSE_DT])
        select k.[d_INVESTIGATION_KEY] as INVESTIGATION_KEY,
               inv.CASE_OID,
               inv.CASE_UID,
               inv.INV_LOCAL_ID,
               inv.INV_SHARE_IND,
               inv.OUTBREAK_NAME,
               inv.INVESTIGATION_STATUS,
               inv.INV_CASE_STATUS,
               inv.CASE_TYPE,
               inv.INV_COMMENTS,
               inv.JURISDICTION_CD,
               inv.JURISDICTION_NM,
               inv.EARLIEST_RPT_TO_PHD_DT,
               inv.ILLNESS_ONSET_DT,
               inv.ILLNESS_END_DT,
               inv.INV_RPT_DT,
               inv.INV_START_DT,
               inv.RPT_SRC_CD_DESC,
               inv.EARLIEST_RPT_TO_CNTY_DT,
               inv.EARLIEST_RPT_TO_STATE_DT,
               inv.CASE_RPT_MMWR_WK,
               inv.CASE_RPT_MMWR_YR,
               inv.DISEASE_IMPORTED_IND,
               inv.IMPORT_FRM_CNTRY,
               inv.IMPORT_FRM_STATE,
               inv.IMPORT_FRM_CNTY,
               inv.IMPORT_FRM_CITY,
               inv.EARLIEST_RPT_TO_CDC_DT,
               inv.RPT_SRC_CD,
               inv.IMPORT_FRM_CNTRY_CD,
               inv.IMPORT_FRM_STATE_CD,
               inv.IMPORT_FRM_CNTY_CD,
               inv.IMPORT_FRM_CITY_CD,
               inv.DIAGNOSIS_DT,
               inv.HSPTL_ADMISSION_DT,
               inv.HSPTL_DISCHARGE_DT,
               inv.HSPTL_DURATION_DAYS,
               inv.OUTBREAK_IND,
               inv.HSPTLIZD_IND,
               inv.INV_STATE_CASE_ID,
               inv.CITY_COUNTY_CASE_NBR,
               inv.TRANSMISSION_MODE,
               inv.RECORD_STATUS_CD,
               inv.PATIENT_PREGNANT_IND,
               inv.DIE_FRM_THIS_ILLNESS_IND,
               inv.DAYCARE_ASSOCIATION_IND,
               inv.FOOD_HANDLR_IND,
               inv.INVESTIGATION_DEATH_DATE,
               inv.PATIENT_AGE_AT_ONSET,
               inv.PATIENT_AGE_AT_ONSET_UNIT,
               inv.INV_ASSIGNED_DT,
               inv.DETECTION_METHOD_DESC_TXT,
               inv.ILLNESS_DURATION,
               inv.ILLNESS_DURATION_UNIT,
               inv.CONTACT_INV_COMMENTS,
               inv.CONTACT_INV_PRIORITY,
               inv.CONTACT_INFECTIOUS_FROM_DATE,
               inv.CONTACT_INFECTIOUS_TO_DATE,
               inv.CONTACT_INV_STATUS,
               inv.PROGRAM_AREA_DESCRIPTION,
               inv.ADD_TIME,
               inv.LAST_CHG_TIME,
               inv.INVESTIGATION_ADDED_BY,
               inv.INVESTIGATION_LAST_UPDATED_BY,
               inv.REFERRAL_BASIS,
               inv.CURR_PROCESS_STATE,
               inv.INV_PRIORITY_CD,
               inv.COINFECTION_ID,
               inv.LEGACY_CASE_ID,
               inv.OUTBREAK_NAME_DESC,
               inv.INV_CLOSE_DT
        FROM #temp_inv_table inv
                 join dbo.nrt_investigation_key k with (nolock) on inv.case_uid = k.case_uid
        where inv.investigation_key is null;

        COMMIT TRANSACTION;

        /* Logging */
        set @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500));

        BEGIN TRANSACTION;

        SET @proc_step_name = 'Update CONFIRMATION_METHOD';
        SET @proc_step_no = 3;

        /*Temp Confirmation Method Table*/
        select distinct nrt.PUBLIC_HEALTH_CASE_UID,
                        i.INVESTIGATION_KEY,
                        nrt.CONFIRMATION_METHOD_CD,
                        nrt.CONFIRMATION_METHOD_DESC_TXT,
                        nrt.CONFIRMATION_METHOD_TIME as CONFIRMATION_DT,
                        cm.CONFIRMATION_METHOD_KEY
        into #temp_cm_table
        from dbo.nrt_investigation_confirmation nrt
                 left join dbo.confirmation_method cm with (nolock) on cm.confirmation_method_cd = nrt.confirmation_method_cd
                 left join dbo.investigation i with (nolock) on i.case_uid = nrt.public_health_case_uid
        where nrt.public_health_case_uid in (select value FROM STRING_SPLIT(@id_list, ','));

        if @debug = 'true' select * from #temp_cm_table;

        -- if confirmation_method_key for the cd exists get the key or insert a new row to rdb.confirmation_method

        /*Update Operation for confirmation_method and confirmation_method_group*/
        update cm
        set cm.CONFIRMATION_METHOD_DESC = cmt.CONFIRMATION_METHOD_DESC_TXT
        from #temp_cm_table cmt
                 inner join dbo.confirmation_method cm with (nolock)
                            on cmt.confirmation_method_key = cm.confirmation_method_key
                                and cmt.CONFIRMATION_METHOD_KEY is not null;

        /*Logging*/
        SET @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500));


        SET @proc_step_name = 'Insert into CONFIRMATION_METHOD';
        SET @proc_step_no = 4;

        -- generate new CONFIRMATION_METHOD_KEY for the corresponding cd
        delete from dbo.nrt_confirmation_method_key;

        insert into dbo.nrt_confirmation_method_key(confirmation_method_cd)
        select distinct cmt.confirmation_method_cd
        from #temp_cm_table cmt
        where cmt.CONFIRMATION_METHOD_KEY is null
          and not exists (select confirmation_method_cd
                          from dbo.confirmation_method cd
                          where cd.confirmation_method_cd = cmt.confirmation_method_cd);

        /* Insert confirmation_method */
        insert into dbo.confirmation_method(CONFIRMATION_METHOD_KEY,CONFIRMATION_METHOD_CD,CONFIRMATION_METHOD_DESC)
        select distinct cmk.D_CONFIRMATION_METHOD_KEY, cmt.confirmation_method_cd, cmt.CONFIRMATION_METHOD_DESC_TXT
        from #temp_cm_table cmt
                 join dbo.nrt_confirmation_method_key cmk with (nolock) on cmk.confirmation_method_cd = cmt.confirmation_method_cd
        where cmt.CONFIRMATION_METHOD_KEY is null
          and not exists (select confirmation_method_cd
                          from dbo.confirmation_method cd
                          where cd.confirmation_method_cd = cmt.confirmation_method_cd);

        /* Logging */
        set @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500));

        SET @proc_step_name = 'UPDATE CONFIRMATION_METHOD_GROUP';
        SET @proc_step_no = 5;

        delete dbo.CONFIRMATION_METHOD_GROUP
        where investigation_key in
              (select investigation_key from dbo.INVESTIGATION where case_uid in
                                                                     (select value FROM STRING_SPLIT(@id_list, ','))
              )

        insert into dbo.CONFIRMATION_METHOD_GROUP ([INVESTIGATION_KEY],[CONFIRMATION_METHOD_KEY],[CONFIRMATION_DT])
        select cmt.INVESTIGATION_KEY, cm.CONFIRMATION_METHOD_KEY, cmt.CONFIRMATION_DT
        from #temp_cm_table cmt
                 left outer join dbo.confirmation_method cm with (nolock) on cmt.confirmation_method_cd = cm.confirmation_method_cd

        /* Logging */
        set @rowcount = @@rowcount
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,@dataflow_name
               ,@package_name
               ,'START'
               ,@proc_step_no
               ,@proc_step_name
               ,@rowcount
               ,LEFT(@id_list, 500));

        COMMIT TRANSACTION;


        SET @proc_step_name='SP_COMPLETE';
        SET @proc_step_no = 6;

        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,current_timestamp
               ,current_timestamp
               ,@dataflow_name
               ,@package_name
               ,'COMPLETE'
               ,@proc_step_no
               ,@proc_step_name
               ,0
               ,LEFT(@id_list, 500));


        SELECT nrt.CASE_UID                       AS public_health_case_uid,
               nrt.patient_id                     AS patient_uid,
               dtm.Datamart                       AS datamart,
               nrt.cd                             AS condition_cd,
               dtm.Stored_Procedure               AS stored_procedure
        FROM #temp_inv_table nrt
                 LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON inv.CASE_UID = nrt.CASE_UID
                 LEFT JOIN dbo.D_PATIENT pat with (nolock) ON pat.PATIENT_UID = nrt.patient_id
                 LEFT JOIN dbo.nrt_datamart_metadata dtm with (nolock) ON dtm.condition_cd = nrt.cd
        UNION
        SELECT nrt.CASE_UID                       AS public_health_case_uid,
               nrt.patient_id                     AS patient_uid,
               dtm.Datamart                       AS datamart,
               null                               AS condition_cd,
               dtm.Stored_Procedure               AS stored_procedure
        FROM #temp_inv_table nrt
                 LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON inv.CASE_UID = nrt.CASE_UID
                 LEFT JOIN dbo.D_PATIENT pat with (nolock) ON pat.PATIENT_UID = nrt.patient_id
                 LEFT JOIN dbo.nrt_datamart_metadata dtm with (nolock) ON dtm.Datamart = 'Case_Lab_Datamart';

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        /* Logging */
        INSERT INTO [dbo].[job_flow_log]
        (batch_id
        ,[create_dttm]
        ,[update_dttm]
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[msg_description1])
        VALUES (@batch_id
               ,current_timestamp
               ,current_timestamp
               ,@dataflow_name
               ,@package_name
               ,'ERROR'
               ,@Proc_Step_no
               ,'Step -' + CAST(@Proc_Step_no AS VARCHAR(3)) + ' -' + CAST(@ErrorMessage AS VARCHAR(500))
               ,0
               ,LEFT(@id_list, 500));


        return -1;

    END CATCH

END;