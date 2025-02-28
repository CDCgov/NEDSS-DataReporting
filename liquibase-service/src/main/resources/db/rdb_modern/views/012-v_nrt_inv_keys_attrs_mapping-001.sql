create or alter view dbo.v_nrt_inv_keys_attrs_mapping as
select inv.public_health_case_uid,
       inv.program_jurisdiction_oid,
       inv.local_id,
       inv.shared_ind,
       inv.outbreak_name,
       inv.investigation_status,
       inv.inv_case_status,
       inv.case_type_cd,
       inv.txt,
       inv.jurisdiction_cd,
       inv.jurisdiction_nm,
       inv.earliest_rpt_to_phd_dt,
       inv.effective_from_time,
       inv.effective_to_time,
       inv.rpt_form_cmplt_time,
       inv.activity_from_time,
       inv.rpt_src_cd_desc,
       inv.rpt_to_county_time,
       inv.rpt_to_state_time,
       inv.mmwr_week,
       inv.mmwr_year,
       inv.disease_imported_ind,
       inv.imported_from_country,
       inv.imported_from_state,
       inv.imported_from_county,
       inv.imported_city_desc_txt,
       inv.earliest_rpt_to_cdc_dt,
       inv.rpt_source_cd,
       inv.imported_country_cd,
       inv.imported_state_cd,
       inv.imported_county_cd,
       inv.import_frm_city_cd,
       inv.diagnosis_time,
       inv.hospitalized_admin_time,
       inv.hospitalized_discharge_time,
       inv.hospitalized_duration_amt,
       inv.outbreak_ind,
       inv.outbreak_ind_val,
       inv.hospitalized_ind,
       inv.hospitalized_ind_cd,
       inv.city_county_case_nbr,
       inv.transmission_mode_cd,
       inv.transmission_mode,
       inv.record_status_cd,
       inv.pregnant_ind_cd,
       inv.pregnant_ind,
       inv.die_frm_this_illness_ind,
       inv.day_care_ind,
       inv.day_care_ind_cd,
       inv.food_handler_ind_cd,
       inv.food_handler_ind,
       inv.deceased_time,
       inv.pat_age_at_onset,
       inv.pat_age_at_onset_unit_cd,
       inv.pat_age_at_onset_unit,
       inv.investigator_assigned_time,
       inv.detection_method_desc_txt,
       inv.effective_duration_amt,
       inv.effective_duration_unit_cd,
       inv.illness_duration_unit,
       inv.contact_inv_txt,
       inv.contact_inv_priority,
       inv.infectious_from_date,
       inv.infectious_to_date,
       inv.contact_inv_status,
       inv.activity_to_time,
       inv.program_area_description,
       inv.add_user_id,
       inv.add_user_name,
       inv.add_time,
       inv.last_chg_user_id,
       inv.last_chg_user_name,
       inv.last_chg_time,
       inv.referral_basis_cd,
       inv.referral_basis,
       inv.curr_process_state,
       inv.inv_priority_cd,
       inv.coinfection_id,
       inv.legacy_case_id,
       inv.curr_process_state_cd,
       inv.investigation_status_cd,
       inv.investigator_id,
       inv.physician_id,
       inv.patient_id,
       inv.organization_id,
       inv.phc_inv_form_id,
       inv.outcome_cd,
       inv.disease_imported_cd,
       inv.mood_cd,
       inv.class_cd,
       inv.case_class_cd,
       inv.cd,
       inv.cd_desc_txt,
       inv.prog_area_cd,
       inv.inv_state_case_id,
       inv.rdb_table_name_list,
       inv.case_management_uid,
       inv.nac_page_case_uid,
       inv.nac_last_chg_time,
       inv.nac_add_time,
       inv.person_as_reporter_uid,
       inv.hospital_uid,
       inv.ordering_facility_uid,
       inv.refresh_datetime,
       inv.investigation_form_cd,
       inv.detection_method_cd,
       i.investigation_key                 as INVESTIGATION_KEY,
       con.condition_key                   as CONDITION_KEY,
       coalesce(dpat.patient_key, 1)       as patient_key,
       coalesce(dpro1.provider_key, 1)     as Investigator_key,
       coalesce(dpro2.provider_key, 1)     as Physician_key,
       coalesce(dpro3.provider_key, 1)     as Reporter_key,
       coalesce(dorg1.organization_key, 1) as Rpt_Src_Org_key,
       coalesce(dorg2.Organization_key, 1) as ADT_HSPTL_KEY,
       coalesce(dorg3.Organization_key, 1) as NURSING_HOME_KEY,
       coalesce(dorg4.Organization_key, 1) as DAYCARE_FACILITY_KEY,
       coalesce(rd1.Date_key, 1)           as Inv_Assigned_dt_key,
       coalesce(rd2.Date_key, 1)           as INV_START_DT_KEY,
       coalesce(rd3.Date_key, 1)           as DIAGNOSIS_DT_KEY,
       coalesce(rd4.Date_key, 1)           as INV_RPT_DT_KEY,
       1                                   AS GEOCODING_LOCATION_KEY,
       COALESCE(lg.ldf_group_key, 1)       as LDF_GROUP_KEY
from dbo.nrt_investigation inv
    inner join dbo.INVESTIGATION i with (nolock) on
    inv.public_health_case_uid = i.case_uid
    inner join dbo.v_condition_dim con with (nolock) on
    con.condition_cd = inv.CD
    left outer join dbo.LDF_GROUP lg on
    lg.BUSINESS_OBJECT_UID = inv.public_health_case_uid
    left outer join dbo.D_PATIENT dpat with (nolock) on
    inv.patient_id = dpat.patient_uid
    left outer join dbo.D_PROVIDER dpro1 with (nolock) on
    inv.investigator_id = dpro1.provider_uid
    left outer join dbo.D_PROVIDER dpro2 with (nolock) on
    inv.physician_id = dpro2.provider_uid
    left outer join dbo.D_PROVIDER dpro3 with (nolock) on
    inv.person_as_reporter_uid = dpro3.provider_uid
    left outer join dbo.D_ORGANIZATION dorg1 with (nolock) on
    inv.organization_id = dorg1.organization_uid
    left outer join dbo.D_ORGANIZATION dorg2 with (nolock) on
    inv.hospital_uid = dorg2.organization_uid
    left outer join dbo.D_ORGANIZATION dorg3 with (nolock) on
    inv.chronic_care_fac_uid = dorg3.organization_uid
    left outer join dbo.D_ORGANIZATION dorg4 with (nolock) on
    inv.daycare_fac_uid = dorg4.organization_uid
    left outer join dbo.RDB_DATE rd1 with (nolock) on
    inv.investigator_assigned_datetime = rd1.DATE_MM_DD_YYYY
    left outer join dbo.RDB_DATE rd2 with (nolock) on
    inv.activity_to_time = rd2.DATE_MM_DD_YYYY
    left outer join dbo.RDB_DATE rd3 with (nolock) on
    inv.diagnosis_time = rd3.DATE_MM_DD_YYYY
    left outer join dbo.RDB_DATE rd4 with (nolock) on
    inv.rpt_form_cmplt_time = rd4.DATE_MM_DD_YYYY;