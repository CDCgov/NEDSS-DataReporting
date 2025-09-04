
IF OBJECT_ID('dbo.job_validation_config', 'U') IS NULL
begin
	create table job_validation_config (
    rdb_entity varchar(500), dataflows varchar(500), validation_query nvarchar(max), dependencies nvarchar(max) default NULL
    )
end;

IF OBJECT_ID('dbo.job_validation_config', 'U') IS NOT NULL
begin
    truncate table job_validation_config;

    insert into job_validation_config values ('D_PROVIDER', 'Provider PRE-Processing Event,Provider POST-Processing',
    'SELECT
    src.person_uid as uid, src.local_id, src.update_time, src.record_status_cd
        , case 
            when nrt.provider_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.provider_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT person_uid, local_id, ISNULL(p.last_chg_time,p.add_time) as update_time, p.record_status_cd
        FROM nbs_odse.dbo.Person p with (nolock)
        WHERE p.cd = ''PRV''
    ) src
    LEFT JOIN dbo.NRT_PROVIDER nrt with (nolock) ON nrt.PROVIDER_UID = src.person_uid
    LEFT JOIN dbo.NRT_PROVIDER_KEY nrtk with (nolock) ON nrtk.PROVIDER_UID = nrt.provider_uid
    LEFT JOIN dbo.D_PROVIDER dp with (nolock) ON dp.PROVIDER_UID = src.person_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''PROVIDER'' 
        AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.person_uid
    )
    WHERE dp.PROVIDER_UID IS NULL', NULL);


    insert into job_validation_config values ('D_PATIENT', 'Patient PRE-Processing Event,Patient POST-Processing',
    'SELECT 
        src.person_uid as uid
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.patient_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.patient_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT person_uid, local_id, ISNULL(p.last_chg_time,p.add_time) as update_time, p.record_status_cd   
        FROM nbs_odse.dbo.Person p with (nolock)
        WHERE p.cd = ''PAT'' 
    ) src
    LEFT JOIN dbo.D_PATIENT dp with (nolock) ON dp.patient_uid = src.person_uid
    LEFT JOIN dbo.NRT_PATIENT nrt with (nolock) ON nrt.patient_uid = src.person_uid
    LEFT JOIN dbo.NRT_PATIENT_KEY nrtk with (nolock) ON nrtk.patient_uid = nrt.patient_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''PATIENT''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.person_uid
    )
    WHERE dp.patient_uid IS NULL', NULL);



    insert into job_validation_config values ('D_ORGANIZATION', 'Organization PRE-Processing Event,Organization POST-Processing',
    'SELECT
        src.organization_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.organization_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.organization_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT organization_uid, local_id, ISNULL(o.last_chg_time,o.add_time) as update_time, o.record_status_cd   
        FROM nbs_odse.dbo.Organization o with (nolock)
    ) src
    LEFT JOIN dbo.D_ORGANIZATION do with (nolock) ON do.organization_uid = src.organization_uid
    LEFT JOIN dbo.NRT_ORGANIZATION nrt with (nolock) ON nrt.organization_uid = src.organization_uid
    LEFT JOIN dbo.NRT_ORGANIZATION_KEY nrtk with (nolock) ON nrtk.organization_uid = nrt.organization_uid
    LEFT JOIN NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''ORGANIZATION''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.organization_uid
    )
    WHERE do.organization_uid IS NULL', NULL);


    insert into job_validation_config values ('INVESTIGATION', 'Investigation PRE-Processing Event,Investigation POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock)
    ) src
    LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON inv.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = nrt.public_health_case_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''INVESTIGATION''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE inv.case_uid IS NULL', NULL);


    insert into job_validation_config values ('TREATMENT', 'Treatment PRE-Processing Event,Treatment POST-Processing',
    'SELECT 
        src.treatment_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.treatment_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.treatment_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT treatment_uid, 
            local_id, 
            record_status_cd,
            ISNULL(last_chg_time, add_time) as update_time
        FROM nbs_odse.dbo.Treatment t 
    ) src
    LEFT JOIN dbo.TREATMENT dt ON dt.treatment_uid = src.treatment_uid
    LEFT JOIN dbo.NRT_TREATMENT nrt ON nrt.treatment_uid = src.treatment_uid
    LEFT JOIN dbo.NRT_TREATMENT_KEY nrtk ON nrtk.treatment_uid = nrt.treatment_uid
    LEFT JOIN dbo.NRT_BACKFILL nb
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''TREATMENT''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.treatment_uid
    )
    WHERE dt.treatment_uid IS NULL', NULL);


    insert into job_validation_config values ('D_CASE_MANAGEMENT', 'Case Management POST-Processing',
    'SELECT 
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT cm.public_health_case_uid, 
            local_id, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.case_management cm with (nolock)
        INNER JOIN nbs_odse.dbo.Public_health_case phc with (nolock) on cm.public_health_case_uid = phc.public_health_case_uid
    ) src
    LEFT JOIN (
        SELECT case_uid 
        FROM dbo.D_CASE_MANAGEMENT dcm with (nolock)
        INNER JOIN dbo.INVESTIGATION i with (nolock) on i.investigation_key = dcm.investigation_key
    ) tgt
    ON tgt.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_CASE_MANAGEMENT_KEY nrtk with (nolock) ON nrtk.public_health_case_uid = nrt.public_health_case_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''CASE_MANAGEMENT''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE tgt.case_uid IS NULL', 'INVESTIGATION');



    insert into job_validation_config values ('D_VACCINATION', 'Vaccination PRE-Processing Event,D_VACCINATION Post-Processing Event',
    'SELECT 
        src.vaccination_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.vaccination_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.vaccination_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT intervention_uid AS vaccination_uid, 
            local_id, 
            record_status_cd,
            ISNULL(last_chg_time, add_time) as update_time
        FROM nbs_odse.dbo.Intervention i with (nolock)
    ) src
    LEFT JOIN dbo.D_VACCINATION dv with (nolock) ON dv.vaccination_uid = src.vaccination_uid
    LEFT JOIN dbo.NRT_VACCINATION nrt with (nolock) ON nrt.vaccination_uid = src.vaccination_uid
    LEFT JOIN dbo.NRT_VACCINATION_KEY nrtk with (nolock) ON nrtk.vaccination_uid = nrt.vaccination_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''VACCINATION''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.vaccination_uid
    )
    WHERE dv.vaccination_uid IS NULL', NULL);



    insert into job_validation_config values ('D_INTERVIEW', 'Interview PRE-Processing Event,D_INTERVIEW',
    'SELECT
        src.interview_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.interview_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.interview_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT interview_uid, 
            local_id, 
            record_status_cd,
            ISNULL(last_chg_time,add_time) as update_time
        FROM nbs_odse.dbo.Interview i with (nolock)
    ) src
    LEFT JOIN (
        SELECT n.interview_uid, d.local_id
        FROM dbo.NRT_INTERVIEW_KEY n with (nolock)
        INNER JOIN dbo.D_INTERVIEW d with (nolock)
        ON d.d_interview_key = n.d_interview_key
    ) di
    ON di.interview_uid = src.interview_uid
    LEFT JOIN dbo.NRT_INTERVIEW nrt with (nolock) ON nrt.interview_uid = src.interview_uid
    LEFT JOIN dbo.NRT_INTERVIEW_KEY nrtk with (nolock) ON nrtk.interview_uid = nrt.interview_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''INTERVIEW''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.interview_uid
    )
    WHERE di.LOCAL_ID IS NULL', NULL);


    insert into job_validation_config values ('LAB_TEST', 'Observation PRE-Processing Event,D_LAB_TEST Post-Processing Event',
    'SELECT 
        src.observation_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.observation_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.lab_test_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT 
            observation_uid,
            local_id,
            record_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            obs_domain_cd_st_1
        FROM nbs_odse.dbo.Observation obs with (nolock)
        WHERE obs.record_status_cd <> ''LOG_DEL''
        AND obs.obs_domain_cd_st_1 IN (''Order'', ''Result'', ''R_Order'', ''R_Result'', ''I_Order'', ''I_Result'', ''Order_rslt'')
                AND (obs.CTRL_CD_DISPLAY_FORM IN (''LabReport'', ''LabReportMorb'') OR obs.CTRL_CD_DISPLAY_FORM IS NULL)
    ) src
    LEFT JOIN dbo.LAB_TEST lt with (nolock) ON lt.LAB_TEST_UID = src.observation_uid
    LEFT JOIN dbo.NRT_OBSERVATION nrt with (nolock) ON nrt.observation_uid = src.observation_uid
    LEFT JOIN dbo.NRT_LAB_TEST_KEY nrtk with (nolock) ON nrtk.lab_test_uid = nrt.observation_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND (nb.entity = ''OBSERVATION'' or nb.entity like ''OBS%'' )
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.observation_uid
    )
    WHERE lt.LAB_TEST_UID IS NULL', NULL);



    insert into job_validation_config values ('LAB_TEST_RESULT', 'Observation PRE-Processing Event,D_LABTEST_RESULTS Post-Processing Event',
    'SELECT 
        src.observation_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.observation_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.lab_test_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT 
            observation_uid,
            local_id,
            record_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            obs_domain_cd_st_1
        FROM nbs_odse.dbo.Observation obs with (nolock)
        WHERE obs.record_status_cd <> ''LOG_DEL''
        AND obs.obs_domain_cd_st_1 IN ( ''Result'', ''R_Result'', ''I_Result'', ''Order_rslt'')
                AND (obs.CTRL_CD_DISPLAY_FORM IN (''LabReport'', ''LabReportMorb'') OR obs.CTRL_CD_DISPLAY_FORM IS NULL)
    ) src
    LEFT JOIN dbo.LAB_TEST_RESULT lt with (nolock) ON lt.LAB_TEST_UID = src.observation_uid
    LEFT JOIN dbo.NRT_OBSERVATION nrt with (nolock) ON nrt.observation_uid = src.observation_uid
    LEFT JOIN dbo.NRT_LAB_TEST_KEY nrtk with (nolock) ON nrtk.lab_test_uid = nrt.observation_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND (nb.entity = ''OBSERVATION'' or nb.entity like ''OBS%'')
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.observation_uid
    )
    WHERE lt.LAB_TEST_UID IS NULL', 'LAB_TEST');



    insert into job_validation_config values ('F_PAGE_CASE', 'F_PAGE_CASE',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock)
        WHERE cd NOT IN (
            SELECT distinct condition_cd FROM dbo.NRT_SRTE_CONDITION_CODE 
            WHERE investigation_form_cd
            NOT IN 	( ''bo.'',''INV_FORM_BMDGBS'',''INV_FORM_BMDGEN'',''INV_FORM_BMDNM'',''INV_FORM_BMDSP'',''INV_FORM_GEN'',''INV_FORM_HEPA'',''INV_FORM_HEPBV'',''INV_FORM_HEPCV'',''INV_FORM_HEPGEN'',''INV_FORM_MEA'',''INV_FORM_PER'',''INV_FORM_RUB'',''INV_FORM_RVCT'',''INV_FORM_VAR'')
        )
    ) src
    LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON inv.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.F_PAGE_CASE fact with (nolock) ON inv.investigation_key = fact.investigation_key
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.d_investigation_key = fact.investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''F_PAGE_CASE''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE fact.investigation_key IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('F_STD_PAGE_CASE', 'F_STD_PAGE_CASE',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        ,  case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table 
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock)
        WHERE cd IN (
            SELECT distinct condition_cd FROM dbo.NRT_SRTE_CONDITION_CODE 
            WHERE investigation_form_cd
            NOT IN 	( ''bo.'',''INV_FORM_BMDGBS'',''INV_FORM_BMDGEN'',''INV_FORM_BMDNM'',''INV_FORM_BMDSP'',''INV_FORM_GEN'',''INV_FORM_HEPA'',''INV_FORM_HEPBV'',''INV_FORM_HEPCV'',''INV_FORM_HEPGEN'',''INV_FORM_MEA'',''INV_FORM_PER'',''INV_FORM_RUB'',''INV_FORM_RVCT'',''INV_FORM_VAR'')
        )
    ) src
    LEFT JOIN dbo.INVESTIGATION inv with (nolock) ON inv.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.F_STD_PAGE_CASE fact with (nolock) ON inv.investigation_key = fact.investigation_key
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.d_investigation_key = fact.investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''F_STD_PAGE_CASE''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE fact.investigation_key IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('F_VACCINATION', 'Vaccination PRE-Processing Event,F_VACCINATION Post-Processing Event',
    'SELECT 
        src.vaccination_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.vaccination_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.vaccination_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT intervention_uid AS vaccination_uid, 
            local_id, 
            record_status_cd,
            ISNULL(last_chg_time, add_time) as update_time
        FROM nbs_odse.dbo.Intervention i with (nolock)
    ) src
    LEFT JOIN dbo.D_VACCINATION dv with (nolock) ON dv.vaccination_uid = src.vaccination_uid
    LEFT JOIN dbo.F_VACCINATION fact with (nolock) ON dv.d_vaccination_key = fact.d_vaccination_key
    LEFT JOIN dbo.NRT_VACCINATION nrt with (nolock) ON nrt.vaccination_uid = src.vaccination_uid
    LEFT JOIN dbo.NRT_VACCINATION_KEY nrtk with (nolock) ON nrtk.vaccination_uid = nrt.vaccination_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''VACCINATION''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.vaccination_uid
    )
    WHERE fact.d_vaccination_key IS NULL', 'D_VACCINATION');


    insert into job_validation_config values ('F_INTERVIEW_CASE', 'Interview PRE-Processing Event,F_INTERVIEW_CASE',
    'SELECT
        src.interview_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.interview_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.interview_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT interview_uid, 
            local_id, 
            record_status_cd,
            ISNULL(last_chg_time,add_time) as update_time
        FROM nbs_odse.dbo.Interview i with (nolock)
    ) src
    LEFT JOIN (
        SELECT n.interview_uid, d.local_id
        FROM dbo.NRT_INTERVIEW_KEY n with (nolock)
        INNER JOIN dbo.D_INTERVIEW d with (nolock)
        ON d.d_interview_key = n.d_interview_key
    ) di
    ON di.interview_uid = src.interview_uid
    LEFT JOIN dbo.NRT_INTERVIEW nrt with (nolock) ON nrt.interview_uid = src.interview_uid
    LEFT JOIN dbo.NRT_INTERVIEW_KEY nrtk with (nolock) ON nrtk.interview_uid = nrt.interview_uid
    LEFT JOIN dbo.F_INTERVIEW_CASE fact with (nolock) ON fact.d_interview_key = nrtk.d_interview_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''INTERVIEW''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.interview_uid
    )
    WHERE fact.d_interview_key IS NULL', 'D_INTERVIEW');


    insert into job_validation_config values ('D_CONTACT_RECORD', 'Contact_Record PRE-Processing Event,D_CONTACT_RECORD Post-Processing Event',
    'SELECT
        src.CT_CONTACT_UID as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.contact_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.contact_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT CT_CONTACT_UID, 
            local_id, 
            record_status_cd,
            ISNULL(last_chg_time,add_time) as update_time
        FROM nbs_odse.dbo.CT_CONTACT with (nolock)
    ) src
    LEFT JOIN (
        SELECT n.contact_uid, d.local_id
        FROM dbo.NRT_CONTACT_KEY n with (nolock)
        INNER JOIN dbo.D_CONTACT_RECORD d with (nolock)
        ON d.d_contact_record_key = n.d_contact_record_key
    ) di
    ON di.contact_uid = src.CT_CONTACT_UID
    LEFT JOIN dbo.NRT_CONTACT nrt with (nolock) ON nrt.contact_uid = src.CT_CONTACT_UID
    LEFT JOIN dbo.NRT_CONTACT_KEY nrtk with (nolock) ON nrtk.contact_uid = nrt.contact_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''CONTACT''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.CT_CONTACT_UID
    )
    WHERE di.contact_uid IS NULL', NULL);


    insert into job_validation_config values ('F_CONTACT_RECORD_CASE', 'Contact_Record PRE-Processing Event,F_CONTACT_RECORD_CASE Post-Processing Event',
    'SELECT
        src.CT_CONTACT_UID as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.contact_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.contact_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT CT_CONTACT_UID, 
            local_id, 
            record_status_cd,
            ISNULL(last_chg_time,add_time) as update_time
        FROM nbs_odse.dbo.CT_CONTACT with (nolock)
    ) src
    LEFT JOIN (
        SELECT n.contact_uid, d.local_id
        FROM dbo.NRT_CONTACT_KEY n with (nolock)
        INNER JOIN dbo.D_CONTACT_RECORD d with (nolock)
        ON d.d_contact_record_key = n.d_contact_record_key
    ) di
    ON di.contact_uid = src.CT_CONTACT_UID
    LEFT JOIN dbo.NRT_CONTACT nrt with (nolock) ON nrt.contact_uid = src.CT_CONTACT_UID
    LEFT JOIN dbo.NRT_CONTACT_KEY nrtk with (nolock) ON nrtk.contact_uid = nrt.contact_uid
    LEFT JOIN dbo.F_CONTACT_RECORD_CASE fact with (nolock) ON fact.d_contact_record_key = nrtk.d_contact_record_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''CONTACT''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.CT_CONTACT_UID
    )
    WHERE fact.d_contact_record_key IS NULL', 'D_CONTACT_RECORD');


    insert into job_validation_config values ('HEPATITIS_DATAMART', 'HEPATITIS_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Hepatitis_Datamart'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.HEPATITIS_DATAMART dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%Hepatitis_Datamart%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');

    insert into job_validation_config values ('STD_HIV_DATAMART', 'STD_HIV_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Std_Hiv_Datamart'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.STD_HIV_DATAMART dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''%Std_Hiv_Datamart%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'F_STD_PAGE_CASE,INVESTIGATION');

    insert into job_validation_config values ('D_TB_HIV', 'D_TB_HIV POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE cd IN (
            SELECT distinct condition_cd FROM dbo.NRT_SRTE_CONDITION_CODE 
            WHERE investigation_form_cd=''INV_FORM_RVCT''
        )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.D_TB_HIV dm with (nolock) ON dm.tb_pam_uid = nrtk.case_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''%d_tb_hiv%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.tb_pam_uid IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('D_TB_PAM', 'D_TB_PAM POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE cd IN (
            SELECT distinct condition_cd FROM dbo.NRT_SRTE_CONDITION_CODE 
            WHERE investigation_form_cd=''INV_FORM_RVCT''
        )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.D_TB_PAM dim with (nolock) ON dim.tb_pam_uid = nrtk.case_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''D_TB_PAM''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.tb_pam_uid IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('F_TB_PAM', 'F_TB_PAM POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE cd IN (
            SELECT distinct condition_cd FROM dbo.NRT_SRTE_CONDITION_CODE 
            WHERE investigation_form_cd=''INV_FORM_RVCT''
        )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.F_TB_PAM fact with (nolock) ON fact.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''F_TB_PAM''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE fact.investigation_key IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('TB_DATAMART', 'TB_DATAMART POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''TB_Datamart'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.TB_DATAMART dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%TB_Datamart%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'F_TB_PAM');

    insert into job_validation_config values ('D_VAR_PAM', 'd_var_pam POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE cd IN (
            SELECT distinct condition_cd FROM dbo.NRT_SRTE_CONDITION_CODE 
            WHERE investigation_form_cd=''INV_FORM_VAR''
        )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.D_VAR_PAM dim with (nolock) ON dim.var_pam_uid = nrtk.case_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''D_VAR_PAM''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.VAR_PAM_UID IS NULL', 'INVESTIGATION');

    insert into job_validation_config values ('F_VAR_PAM', 'F_VAR_PAM POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE cd IN (
            SELECT distinct condition_cd FROM dbo.NRT_SRTE_CONDITION_CODE 
            WHERE investigation_form_cd=''INV_FORM_VAR''
        )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.F_VAR_PAM fact with (nolock) ON fact.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''F_VAR_PAM''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE fact.investigation_key IS NULL', 'D_VAR_PAM');

    insert into job_validation_config values ('VAR_DATAMART', 'var_datamart POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''VAR_Datamart'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.VAR_DATAMART dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%VAR_Datamart%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'F_VAR_PAM');


    insert into job_validation_config values ('CRS_CASE', 'CRS_CASE_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''CRS_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.CRS_CASE dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%CRS_Case%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('RUBELLA_CASE', 'RUBELLA_CASE_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Rubella_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.RUBELLA_CASE dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%Rubella_Case%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('GENERIC_CASE', 'GENERIC_CASE_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Generic_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.GENERIC_CASE dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%Generic_Case%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');

    insert into job_validation_config values ('MEASLES_CASE', 'MEASLES_CASE_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Measles_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.MEASLES_CASE dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%Measles_Case%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');

    insert into job_validation_config values ('BMIRD_CASE', 'BMIRD_CASE_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''BMIRD_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.BMIRD_CASE dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like''%BMIRD_Case%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');

    insert into job_validation_config values ('HEPATITIS_CASE', 'HEPATITIS_CASE_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Hepatitis_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.HEPATITIS_CASE dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%Hepatitis_Case%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('PERTUSSIS_CASE', 'PERTUSSIS_CASE_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Pertussis_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.PERTUSSIS_CASE dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%Pertussis_Case%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('COVID_CASE_DATAMART', 'COVID DATAMART Post-Processing Event',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Covid_Case_Datamart'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.COVID_CASE_DATAMART dm with (nolock) ON dm.public_health_case_uid = nrtk.case_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%Covid_Case_Datamart%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.public_health_case_uid IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('TB_HIV_DATAMART', 'TB_HIV_DATAMART POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd IN (
            SELECT distinct condition_cd FROM dbo.NRT_SRTE_CONDITION_CODE 
            WHERE investigation_form_cd=''INV_FORM_RVCT''
        )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.TB_HIV_DATAMART dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity like ''%tb_hiv_datamart%''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');

    insert into job_validation_config values ('NOTIFICATION', 'Notification PRE-Processing Event,Notification POST-Processing',
    'SELECT
        src.notification_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.notification_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.notification_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT notification_uid, 
            local_id, 
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Notification n with (nolock) 
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION_NOTIFICATION nrt with (nolock) ON nrt.notification_uid = src.notification_uid
    LEFT JOIN dbo.NRT_NOTIFICATION_KEY nrtk with (nolock) ON nrtk.notification_uid = src.notification_uid
    LEFT JOIN dbo.NOTIFICATION n with (nolock) ON n.notification_key = nrtk.d_notification_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''NOTIFICATION''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.notification_uid
    )
    WHERE n.notification_key IS NULL', NULL);

    insert into job_validation_config values ('NOTIFICATION_EVENT', 'Notification PRE-Processing Event,Notification POST-Processing',
    'SELECT
        src.notification_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.notification_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.notification_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT notification_uid, 
            local_id, 
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Notification n with (nolock) 
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION_NOTIFICATION nrt with (nolock) ON nrt.notification_uid = src.notification_uid
    LEFT JOIN dbo.NRT_NOTIFICATION_KEY nrtk with (nolock) ON nrtk.notification_uid = src.notification_uid
    LEFT JOIN dbo.NOTIFICATION_EVENT n with (nolock) ON n.notification_key = nrtk.d_notification_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''NOTIFICATION''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.notification_uid
    )
    WHERE n.notification_key IS NULL', NULL);


    insert into job_validation_config values ('HEP100', 'HEP100_DATAMART',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' AND cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Hepatitis_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.HEP100 dim with (nolock) ON dim.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''HEP100''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.investigation_key IS NULL', 'HEPATITIS_CASE,INVESTIGATION');


    insert into job_validation_config values ('LDF_DIMENSIONAL_DATA', 'LDF_DIMENSIONAL_DATA POST-Processing',
    'SELECT
        src.ldf_uid as uid 
        , src.local_id
        , src.update_time
        , src.active_ind as record_status_cd
        , case 
            when nrt.ldf_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            ldf_uid,
            business_object_nm,
            active_ind,
            NULL as local_id,
            ISNULL(record_status_time, add_time) as update_time
        FROM
            nbs_odse.dbo.STATE_DEFINED_FIELD_METADATA phc with (nolock)
        WHERE
            business_object_nm in (''PHC'', ''BMD'', ''HEP'', ''NIP'')
    ) src
    LEFT JOIN dbo.NRT_ODSE_STATE_DEFINED_FIELD_METADATA nrt with (nolock) ON nrt.ldf_uid = src.ldf_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.ldf_uid
    LEFT JOIN dbo.LDF_DIMENSIONAL_DATA dim with (nolock) ON dim.ldf_uid = nrtk.case_uid
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''ldf_dimensional_data''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.ldf_uid
    )
    WHERE dim.ldf_uid IS NULL', 'INVESTIGATION');


    insert into job_validation_config values ('LDF_GENERIC', 'sp_ldf_generic_datamart_postprocessing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.active_ind as record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd 
        FROM
            nbs_odse.dbo.STATE_DEFINED_FIELD_METADATA sdf with (nolock)
        INNER JOIN 
            nbs_odse.dbo.PUBLIC_HEALTH_CASE phc with (nolock) 
        ON phc.public_health_case_uid = sdf.ldf_uid AND
            sdf.business_object_nm in (''PHC'', ''BMD'', ''HEP'', ''NIP'')
        WHERE phc.record_status_cd <> ''LOG_DEL'' AND sdf.condition_cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''Generic_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.LDF_GENERIC dim with (nolock) ON dim.investigation_key = nrtk.investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''LDF_GENERIC''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.investigation_key IS NULL', 'LDF_DIMENSIONAL_DATA,GENERIC_CASE');

    insert into job_validation_config values ('LDF_BMIRD', 'sp_ldf_bmird_datamart_postprocessing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.active_ind as record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd 
        FROM
            nbs_odse.dbo.STATE_DEFINED_FIELD_METADATA sdf with (nolock)
        INNER JOIN 
            nbs_odse.dbo.PUBLIC_HEALTH_CASE phc with (nolock) 
        ON phc.public_health_case_uid = sdf.ldf_uid AND
            sdf.business_object_nm in (''PHC'', ''BMD'', ''HEP'', ''NIP'')
        WHERE phc.record_status_cd <> ''LOG_DEL'' AND sdf.condition_cd in (SELECT condition_cd FROM dbo.nrt_datamart_metadata WHERE Datamart=''BMIRD_Case'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.LDF_BMIRD dim with (nolock) ON dim.investigation_key = nrtk.investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''LDF_BMIRD''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.investigation_key IS NULL', 'LDF_DIMENSIONAL_DATA,BMIRD_CASE');

    insert into job_validation_config values ('LDF_FOODBORNE', 'LDF_FOODBORNE POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.active_ind as record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd 
        FROM
            nbs_odse.dbo.STATE_DEFINED_FIELD_METADATA sdf with (nolock)
        INNER JOIN 
            nbs_odse.dbo.PUBLIC_HEALTH_CASE phc with (nolock) 
        ON phc.public_health_case_uid = sdf.ldf_uid AND
            sdf.business_object_nm in (''PHC'', ''BMD'', ''HEP'', ''NIP'')
        WHERE 
            phc.record_status_cd <> ''LOG_DEL'' 
            AND phc.condition_cd in (SELECT condition_cd FROM dbo.LDF_DATAMART_TABLE_REF WHERE datamart_name = ''LDF_FOODBORNE'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.LDF_FOODBORNE dim with (nolock) ON dim.investigation_key = nrtk.investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''LDF_FOODBORNE''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.investigation_key IS NULL', 'LDF_DIMENSIONAL_DATA,GENERIC_CASE');

        insert into job_validation_config values ('LDF_MUMPS', 'sp_ldf_mumps_datamart_postprocessing POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.active_ind as record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd 
        FROM
            nbs_odse.dbo.STATE_DEFINED_FIELD_METADATA sdf with (nolock)
        INNER JOIN 
            nbs_odse.dbo.PUBLIC_HEALTH_CASE phc with (nolock) 
        ON phc.public_health_case_uid = sdf.ldf_uid AND
            sdf.business_object_nm in (''PHC'', ''BMD'', ''HEP'', ''NIP'')
        WHERE 
            phc.record_status_cd <> ''LOG_DEL'' 
            AND phc.condition_cd in (SELECT condition_cd FROM dbo.LDF_DATAMART_TABLE_REF WHERE datamart_name = ''LDF_MUMPS'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.LDF_MUMPS dim with (nolock) ON dim.investigation_key = nrtk.investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''LDF_MUMPS''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.investigation_key IS NULL', 'LDF_DIMENSIONAL_DATA,MUMPS_CASE');

    insert into job_validation_config values ('LDF_TETANUS', 'LDF_TETANUS POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.active_ind as record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd 
        FROM
            nbs_odse.dbo.STATE_DEFINED_FIELD_METADATA sdf with (nolock)
        INNER JOIN 
            nbs_odse.dbo.PUBLIC_HEALTH_CASE phc with (nolock) 
        ON phc.public_health_case_uid = sdf.ldf_uid AND
            sdf.business_object_nm in (''PHC'', ''BMD'', ''HEP'', ''NIP'')
        WHERE 
            phc.record_status_cd <> ''LOG_DEL'' 
            AND phc.condition_cd in (SELECT condition_cd FROM dbo.LDF_DATAMART_TABLE_REF WHERE datamart_name = ''LDF_TETANUS'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.LDF_TETANUS dim with (nolock) ON dim.investigation_key = nrtk.investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''LDF_TETANUS''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.investigation_key IS NULL', 'LDF_DIMENSIONAL_DATA,GENERIC_CASE');


    insert into job_validation_config values ('LDF_VACCINE_PREVENT_DISEASES', 'LDF_VACCINE_PREVENT_DISEASES POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.active_ind as record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd 
        FROM
            nbs_odse.dbo.STATE_DEFINED_FIELD_METADATA sdf with (nolock)
        INNER JOIN 
            nbs_odse.dbo.PUBLIC_HEALTH_CASE phc with (nolock) 
        ON phc.public_health_case_uid = sdf.ldf_uid AND
            sdf.business_object_nm in (''PHC'', ''BMD'', ''HEP'', ''NIP'')
        WHERE 
            phc.record_status_cd <> ''LOG_DEL'' 
            AND phc.condition_cd in (SELECT condition_cd FROM dbo.LDF_DATAMART_TABLE_REF WHERE datamart_name = ''LDF_VACCINE_PREVENT_DISEASES'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.LDF_VACCINE_PREVENT_DISEASES dim with (nolock) ON dim.investigation_key = nrtk.investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''LDF_VACCINE_PREVENT_DISEASES''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.investigation_key IS NULL', 'LDF_DIMENSIONAL_DATA,MEASLES_CASE');


    insert into job_validation_config values ('LDF_HEPATITIS', 'sp_ldf_hepatitis_datamart_postprocessing POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.active_ind as record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd 
        FROM
            nbs_odse.dbo.STATE_DEFINED_FIELD_METADATA sdf with (nolock)
        INNER JOIN 
            nbs_odse.dbo.PUBLIC_HEALTH_CASE phc with (nolock) 
        ON phc.public_health_case_uid = sdf.ldf_uid AND
            sdf.business_object_nm in (''PHC'', ''BMD'', ''HEP'', ''NIP'')
        WHERE 
            phc.record_status_cd <> ''LOG_DEL'' 
            AND phc.condition_cd in (SELECT condition_cd FROM dbo.LDF_DATAMART_TABLE_REF WHERE datamart_name = ''LDF_HEPATITIS'' )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.LDF_HEPATITIS dim with (nolock) ON dim.investigation_key = nrtk.investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''LDF_HEPATITIS''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dim.investigation_key IS NULL', 'LDF_DIMENSIONAL_DATA,HEPATITIS_CASE');


    insert into job_validation_config values ('BMIRD_STREP_PNEUMO_DATAMART', 'BMIRD_STREP_PNEUMO Post-Processing Event',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd 
        FROM
            nbs_odse.dbo.PUBLIC_HEALTH_CASE phc with (nolock) 
        WHERE phc.record_status_cd <> ''LOG_DEL'' 
        AND phc.cd in (''11723'',''11717'',''11720'') 
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.BMIRD_STREP_PNEUMO_DATAMART dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''Bmird_Strep_Pneumo_Datamart''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'BMIRD_CASE');

        insert into job_validation_config values ('INV_SUMM_DATAMART', 'INV_SUMM_DATAMART Post-Processing Event',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT
            public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd 
        FROM
            nbs_odse.dbo.PUBLIC_HEALTH_CASE with (nolock) 
        WHERE record_status_cd = ''ACTIVE'' AND case_type_cd = ''I''
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.INV_SUMM_DATAMART dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''DM^MultiId_Datamart''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INVESTIGATION');

    
    insert into job_validation_config values ('DM_INV_<DATAMART_NM>', 'DYNAMIC_DATAMART POST-Processing',
    'SELECT
        src.public_health_case_uid as uid 
        , src.local_id
        , src.update_time
        , src.record_status_cd
        , case 
            when nrt.public_health_case_uid is null then ''FALSE'' 
            else ''TRUE''
        end as record_in_nrt_table
        , case 
            when nrtk.case_uid is null then ''FALSE'' 
            else ''TRUE'' 
        end as record_in_nrt_key_table
        , nb.record_uid_list as retry_list
        , nb.batch_id as retry_job_batch_id
        , nb.retry_count as retry_count
        , nb.err_description as retry_error_desc
    FROM (
        SELECT public_health_case_uid, 
            local_id, 
            cd, 
            investigation_status_cd,
            ISNULL(last_chg_time, add_time) as update_time,
            record_status_cd   
        FROM nbs_odse.dbo.Public_health_case phc with (nolock) 
        WHERE record_status_cd <> ''LOG_DEL'' 
        AND cd in (
            SELECT condition_cd 
            FROM dbo.CONDITION c with ( nolock)  
            INNER JOIN dbo.V_NRT_NBS_INVESTIGATION_RDB_TABLE_METADATA inv_meta 
            ON c.DISEASE_GRP_CD =  inv_meta.FORM_CD AND c.DISEASE_GRP_CD = ''<DISEASE_GRP_CD>''
        )
    ) src
    LEFT JOIN dbo.NRT_INVESTIGATION nrt with (nolock) ON nrt.public_health_case_uid = src.public_health_case_uid
    LEFT JOIN dbo.NRT_INVESTIGATION_KEY nrtk with (nolock) ON nrtk.case_uid = src.public_health_case_uid
    LEFT JOIN dbo.DM_INV_<DATAMART_NM> dm with (nolock) ON dm.investigation_key = nrtk.d_investigation_key
    LEFT JOIN dbo.NRT_BACKFILL nb with (nolock)
    ON nb.status_cd <> ''COMPLETE'' AND nb.entity = ''DM^MultiId_Datamart''
    AND EXISTS (
        SELECT 1
        FROM STRING_SPLIT(nb.record_uid_list, '','') s
        WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
    )
    WHERE dm.investigation_key IS NULL', 'INV_SUMM_DATAMART');

END