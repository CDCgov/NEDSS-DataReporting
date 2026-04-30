# Logical Change Report

Source artifact: /Users/patrick/sky/7/NEDSS-DataReporting/local-db-tracing/output/20260430-163203-NBS_ODSE-to-RDB_MODERN/logical-RDB_MODERN/logical-changes.json

## Run Summary

| Metric | Value |
| --- | --- |
| Database | RDB_MODERN |
| Capture window | 2026-04-30T19:23:16+00:00 to 2026-04-30T20:31:45+00:00 (LSN 0x00006be7000004c000d4 -> 0x00006c1b00000158000c) |
| Total logical changes | 804 |
| Inserts | 332 |
| Updates | 327 |
| Deletes | 145 |
| Source actions | CreatePatientAndLabReportSyphilis<br>CreateInvestigationSyphilis<br>AddTreatmentSyphilis<br>InvestigateSyphilisInitialFollowup<br>InvestigateSyphilisAssignFieldFollowup<br>AddInterviewSyphilis<br>AddContactSyphilis<br>ChangeContactInvestigationDisposition<br>CloseInvestigationSyphilis<br>SupervisorRejectsCloseInvestigation<br>CloseInvestigationAndCreateNotificationSyphilis<br>SupervisorApprove |

## Tables Touched

| Table | Change count |
| --- | --- |
| dbo.CASE_COUNT | 18 |
| dbo.CASE_LAB_DATAMART | 18 |
| dbo.CONFIRMATION_METHOD | 1 |
| dbo.CONFIRMATION_METHOD_GROUP | 18 |
| dbo.D_CASE_MANAGEMENT | 9 |
| dbo.D_CONTACT_RECORD | 2 |
| dbo.D_INTERVIEW | 1 |
| dbo.D_INTERVIEW_NOTE | 1 |
| dbo.D_INVESTIGATION_REPEAT | 16 |
| dbo.D_INV_ADMINISTRATIVE | 15 |
| dbo.D_INV_CLINICAL | 13 |
| dbo.D_INV_HIV | 9 |
| dbo.D_INV_MEDICAL_HISTORY | 9 |
| dbo.D_INV_PREGNANCY_BIRTH | 15 |
| dbo.D_INV_RISK_FACTOR | 9 |
| dbo.D_INV_SOCIAL_HISTORY | 9 |
| dbo.D_INV_TREATMENT | 13 |
| dbo.D_PATIENT | 42 |
| dbo.EVENT_METRIC | 27 |
| dbo.EVENT_METRIC_INC | 27 |
| dbo.F_CONTACT_RECORD_CASE | 1 |
| dbo.F_INTERVIEW_CASE | 1 |
| dbo.F_STD_PAGE_CASE | 18 |
| dbo.INVESTIGATION | 18 |
| dbo.INV_HIV | 3 |
| dbo.INV_SUMM_DATAMART | 13 |
| dbo.LAB100 | 1 |
| dbo.LAB_RESULT_VAL | 1 |
| dbo.LAB_RPT_USER_COMMENT | 3 |
| dbo.LAB_TEST | 5 |
| dbo.LAB_TEST_RESULT | 4 |
| dbo.LOOKUP_TABLE_N_INV_ADMINISTRATIVE | 2 |
| dbo.LOOKUP_TABLE_N_INV_CLINICAL | 2 |
| dbo.LOOKUP_TABLE_N_INV_HIV | 2 |
| dbo.LOOKUP_TABLE_N_INV_MEDICAL_HISTORY | 2 |
| dbo.LOOKUP_TABLE_N_INV_PREGNANCY_BIRTH | 2 |
| dbo.LOOKUP_TABLE_N_INV_RISK_FACTOR | 2 |
| dbo.LOOKUP_TABLE_N_INV_SOCIAL_HISTORY | 2 |
| dbo.LOOKUP_TABLE_N_INV_TREATMENT | 2 |
| dbo.LOOKUP_TABLE_N_REPT | 4 |
| dbo.L_INVESTIGATION_REPEAT | 2 |
| dbo.L_INV_ADMINISTRATIVE | 1 |
| dbo.L_INV_CLINICAL | 1 |
| dbo.L_INV_HIV | 1 |
| dbo.L_INV_MEDICAL_HISTORY | 1 |
| dbo.L_INV_PREGNANCY_BIRTH | 1 |
| dbo.L_INV_RISK_FACTOR | 1 |
| dbo.L_INV_SOCIAL_HISTORY | 1 |
| dbo.L_INV_TREATMENT | 1 |
| dbo.NOTIFICATION | 2 |
| dbo.NOTIFICATION_EVENT | 3 |
| dbo.STD_HIV_DATAMART | 9 |
| dbo.TEST_RESULT_GROUPING | 1 |
| dbo.TREATMENT | 1 |
| dbo.TREATMENT_EVENT | 1 |
| dbo.nrt_case_management_key | 10 |
| dbo.nrt_confirmation_method_key | 7 |
| dbo.nrt_contact | 2 |
| dbo.nrt_contact_answer | 6 |
| dbo.nrt_contact_key | 2 |
| dbo.nrt_interview | 1 |
| dbo.nrt_interview_answer | 1 |
| dbo.nrt_interview_key | 1 |
| dbo.nrt_interview_note | 1 |
| dbo.nrt_interview_note_key | 1 |
| dbo.nrt_investigation | 12 |
| dbo.nrt_investigation_case_management | 12 |
| dbo.nrt_investigation_confirmation | 8 |
| dbo.nrt_investigation_key | 10 |
| dbo.nrt_investigation_notification | 9 |
| dbo.nrt_investigation_observation | 35 |
| dbo.nrt_lab_rpt_user_comment_key | 3 |
| dbo.nrt_lab_test_key | 5 |
| dbo.nrt_lab_test_result_group_key | 2 |
| dbo.nrt_metadata_columns | 12 |
| dbo.nrt_notification_key | 2 |
| dbo.nrt_observation | 5 |
| dbo.nrt_observation_material | 3 |
| dbo.nrt_observation_numeric | 1 |
| dbo.nrt_observation_txt | 1 |
| dbo.nrt_page_case_answer | 212 |
| dbo.nrt_patient | 27 |
| dbo.nrt_patient_key | 24 |
| dbo.nrt_treatment | 1 |
| dbo.nrt_treatment_key | 1 |

## Changes

## 1. INSERT dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:27:34.637 |
| LSN | 0x00006bf9000002e00001 |

### Inserted Row

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:27:33.867" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:27:34.6426400" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 2. INSERT dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T19:27:36.620 |
| LSN | 0x00006bf900000310000d |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T19:27:36.5400000" |

## 3. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:27:36.620 |
| LSN | 0x00006bf900000310000d |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:27:33.867" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 4. INSERT dbo.nrt_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:27:43.113 |
| LSN | 0x00006bfa000001c0006d |

### Inserted Row

| Field | Value |
| --- | --- |
| accession_number | "" |
| act_uid | 10009291 |
| activity_to_time | "2026-04-20T00:00:00" |
| add_time | "2026-04-30T19:27:33.910" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| author_organization_id | 10003019 |
| batch_id | 1777577262268 |
| cd | "T-14900" |
| cd_desc_txt | "No Information Given" |
| cd_system_cd | "DEFAULT" |
| cd_system_desc_txt | "Default Manual Lab" |
| class_cd | "OBS" |
| ctrl_cd_display_form | "LabReport" |
| electronic_ind | "N" |
| followup_observation_uid | "10009292,10009293" |
| jurisdiction_cd | "130001" |
| last_chg_time | "2026-04-30T19:27:33.910" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "OBS10001000GA01" |
| material_id | 10009295 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mood_cd | "EVN" |
| obs_domain_cd_st_1 | "Order" |
| observation_uid | 10009291 |
| patient_id | 10009287 |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| record_status_cd | "UNPROCESSED" |
| record_status_time | "2026-04-30T19:27:33.910" |
| refresh_datetime | "2026-04-30T19:27:42.8335213" |
| report_observation_uid | 10009291 |
| result_observation_uid | "10009294" |
| rpt_to_state_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| status_cd | "D" |
| status_time | "2026-04-30T19:27:33.767" |
| target_site_cd | "NI" |
| version_ctrl_nbr | 1 |

## 5. INSERT dbo.nrt_observation_material

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: act_uid=10009291, material_id=10009295 |
| Transaction end | 2026-04-30T19:27:43.113 |
| LSN | 0x00006bfa000001c0006d |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009291 |
| last_chg_time | "2026-04-30T19:27:33.777" |
| material_cd | "" |
| material_desc | "" |
| material_id | 10009295 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:27:42.8335213" |
| subject_class_cd | "MAT" |
| type_cd | "SPC" |
| type_desc_txt | "Specimen" |

## 6. INSERT dbo.nrt_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="OBS10001003GA01" |
| Transaction end | 2026-04-30T19:27:43.133 |
| LSN | 0x00006bfa000001d80003 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009294 |
| alt_cd | "31147-2" |
| alt_cd_desc_txt | "REAGIN AB" |
| alt_cd_system_cd | "LN" |
| batch_id | 1777577262262 |
| cd | "T-58955" |
| cd_desc_txt | "RPR Titer " |
| cd_system_cd | "DEFAULT" |
| cd_system_desc_txt | "Default Manual Lab" |
| class_cd | "OBS" |
| ctrl_cd_display_form | "LabReport" |
| electronic_ind | "N" |
| local_id | "OBS10001003GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mood_cd | "EVN" |
| obs_domain_cd_st_1 | "Result" |
| observation_uid | 10009294 |
| program_jurisdiction_oid | 4 |
| refresh_datetime | "2026-04-30T19:27:43.1346568" |
| report_observation_uid | 10009291 |
| shared_ind | "T" |
| status_time | "2026-04-30T19:27:33.783" |
| version_ctrl_nbr | 1 |

## 7. INSERT dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:27:43.177 |
| LSN | 0x00006bfa000001e00006 |

### Inserted Row

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:33.873" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| age_reported | 41 |
| age_reported_unit | "Years" |
| age_reported_unit_cd | "Y" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:27:33.873" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009287 |
| phone_ext_home | "" |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:27:43.1595805" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 8. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:27:43.177 |
| LSN | 0x00006bfa000001e00006 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T19:27:34.6426400" | "2026-04-30T19:27:43.1595805" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:27:33.867" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:27:43.1595805" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 9. INSERT dbo.nrt_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="OBS10001001GA01" |
| Transaction end | 2026-04-30T19:27:43.177 |
| LSN | 0x00006bfa000001e00006 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009292 |
| activity_to_time | "2026-04-20T00:00:00" |
| batch_id | 1777577262263 |
| cd | "NI" |
| cd_desc_txt | "No Information Given" |
| cd_system_cd | "2.16.840.1.113883" |
| cd_system_desc_txt | "LabComment" |
| class_cd | "OBS" |
| ctrl_cd_display_form | "Lab Report" |
| local_id | "OBS10001001GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mood_cd | "EVN" |
| obs_domain_cd_st_1 | "C_Order" |
| observation_uid | 10009292 |
| program_jurisdiction_oid | 4 |
| refresh_datetime | "2026-04-30T19:27:43.1595805" |
| report_observation_uid | 10009291 |
| rpt_to_state_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| status_cd | "D" |
| status_time | "2026-04-30T19:27:33.777" |
| version_ctrl_nbr | 1 |

## 10. INSERT dbo.nrt_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="OBS10001002GA01" |
| Transaction end | 2026-04-30T19:27:43.177 |
| LSN | 0x00006bfa000001e00006 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009293 |
| activity_to_time | "2026-04-30T19:27:33.777" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777577262264 |
| cd | "LAB214" |
| cd_desc_txt | "User Report Comment" |
| cd_system_cd | "NBS" |
| cd_system_desc_txt | "NEDSS Base System" |
| class_cd | "OBS" |
| ctrl_cd_display_form | "LabComment" |
| local_id | "OBS10001002GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mood_cd | "EVN" |
| obs_domain_cd_st_1 | "C_Result" |
| observation_uid | 10009293 |
| program_jurisdiction_oid | 4 |
| refresh_datetime | "2026-04-30T19:27:43.1595805" |
| report_observation_uid | 10009292 |
| shared_ind | "T" |
| status_cd | "D" |
| status_time | "2026-04-30T19:27:33.777" |
| version_ctrl_nbr | 1 |

## 11. INSERT dbo.nrt_observation_txt

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:27:44.733 |
| LSN | 0x00006bfa000002000031 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777577262264 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_uid | 10009293 |
| ovt_seq | 1 |
| ovt_value_txt | "some comments" |
| refresh_datetime | "2026-04-30T19:27:44.6739810" |

## 12. INSERT dbo.nrt_observation_numeric

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:27:44.733 |
| LSN | 0x00006bfa000002000031 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777577262262 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_uid | 10009294 |
| ovn_comparator_cd_1 | "=" |
| ovn_numeric_value_1 | 1.0 |
| ovn_numeric_value_2 | 128.0 |
| ovn_separator_cd | ":" |
| ovn_seq | 0 |
| refresh_datetime | "2026-04-30T19:27:44.6739810" |

## 13. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T19:27:57.737 |
| LSN | 0x00006bfa000002c80023 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:27:36.5400000" | "2026-04-30T19:27:57.6333333" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T19:27:57.6333333" |

## 14. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:27:57.737 |
| LSN | 0x00006bfa000002c80023 |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:27:33.867" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 15. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:27:57.737 |
| LSN | 0x00006bfa000002c80023 |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:27:33.867" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 16. INSERT dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=5 |
| Transaction end | 2026-04-30T19:27:57.737 |
| LSN | 0x00006bfa000002c80023 |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:57.6733333" |
| d_patient_key | 5 |
| patient_uid | 10009287 |
| updated_dttm | "2026-04-30T19:27:57.6733333" |

## 17. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:27:57.737 |
| LSN | 0x00006bfa000002c80023 |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:33.873" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 5 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:27:33.873" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009287 |
| PATIENT_ZIP | "30033" |

## 18. INSERT dbo.nrt_lab_test_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:27:58.390 |
| LSN | 0x00006bfb000001800002 |

### Inserted Row

| Field | Value |
| --- | --- |
| LAB_TEST_KEY | 2 |
| LAB_TEST_UID | 10009291 |
| created_dttm | "2026-04-30T19:27:58.3266667" |
| updated_dttm | "2026-04-30T19:27:58.3266667" |

## 19. INSERT dbo.nrt_lab_test_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:27:58.390 |
| LSN | 0x00006bfb000001800002 |

### Inserted Row

| Field | Value |
| --- | --- |
| LAB_TEST_KEY | 3 |
| LAB_TEST_UID | 10009294 |
| created_dttm | "2026-04-30T19:27:58.3266667" |
| updated_dttm | "2026-04-30T19:27:58.3266667" |

## 20. INSERT dbo.LAB_TEST

| Metric | Value |
| --- | --- |
| Identity | business_keys: LAB_RPT_LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:27:58.390 |
| LSN | 0x00006bfb000001800002 |

### Inserted Row

| Field | Value |
| --- | --- |
| ELR_IND | "N" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAB_RPT_CREATED_BY | 10009282 |
| LAB_RPT_CREATED_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LAST_UPDATE_BY | 10009282 |
| LAB_RPT_LAST_UPDATE_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LOCAL_ID | "OBS10001000GA01" |
| LAB_RPT_RECEIVED_BY_PH_DT | "2026-04-30T00:00:00" |
| LAB_RPT_SHARE_IND | "T" |
| LAB_RPT_STATUS | "D" |
| LAB_RPT_UID | 10009291 |
| LAB_TEST_CD | "T-14900" |
| LAB_TEST_CD_DESC | "No Information Given" |
| LAB_TEST_CD_SYS_CD | "DEFAULT" |
| LAB_TEST_CD_SYS_NM | "Default Manual Lab" |
| LAB_TEST_DT | "2026-04-20T00:00:00" |
| LAB_TEST_KEY | 2 |
| LAB_TEST_PNTR | 10009291 |
| LAB_TEST_STATUS | "Final" |
| LAB_TEST_TYPE | "Order" |
| LAB_TEST_UID | 10009291 |
| OID | 1300100015 |
| PARENT_TEST_NM | "No Information Given" |
| PARENT_TEST_PNTR | 10009291 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.323" |
| RECORD_STATUS_CD | "ACTIVE" |
| ROOT_ORDERED_TEST_NM | "No Information Given" |
| ROOT_ORDERED_TEST_PNTR | 10009291 |
| SPECIMEN_ADD_TIME | "2026-04-30T19:27:33.910" |
| SPECIMEN_LAST_CHANGE_TIME | "2026-04-30T19:27:33.910" |
| SPECIMEN_SITE | "NI" |

## 21. INSERT dbo.LAB_TEST

| Metric | Value |
| --- | --- |
| Identity | business_keys: LAB_RPT_LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:27:58.390 |
| LSN | 0x00006bfb000001800002 |

### Inserted Row

| Field | Value |
| --- | --- |
| ALT_LAB_TEST_CD | "31147-2" |
| ALT_LAB_TEST_CD_DESC | "REAGIN AB" |
| ALT_LAB_TEST_CD_SYS_CD | "LN" |
| ELR_IND | "N" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAB_RPT_CREATED_BY | 10009282 |
| LAB_RPT_CREATED_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LAST_UPDATE_BY | 10009282 |
| LAB_RPT_LAST_UPDATE_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LOCAL_ID | "OBS10001000GA01" |
| LAB_RPT_RECEIVED_BY_PH_DT | "2026-04-30T00:00:00" |
| LAB_RPT_SHARE_IND | "T" |
| LAB_RPT_UID | 10009294 |
| LAB_TEST_CD | "T-58955" |
| LAB_TEST_CD_DESC | "RPR Titer" |
| LAB_TEST_CD_SYS_CD | "DEFAULT" |
| LAB_TEST_CD_SYS_NM | "Default Manual Lab" |
| LAB_TEST_DT | "2026-04-20T00:00:00" |
| LAB_TEST_KEY | 3 |
| LAB_TEST_PNTR | 10009294 |
| LAB_TEST_TYPE | "Result" |
| LAB_TEST_UID | 10009294 |
| OID | 1300100015 |
| PARENT_TEST_NM | "No Information Given" |
| PARENT_TEST_PNTR | 10009291 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.323" |
| RECORD_STATUS_CD | "ACTIVE" |
| ROOT_ORDERED_TEST_NM | "No Information Given" |
| ROOT_ORDERED_TEST_PNTR | 10009291 |
| SPECIMEN_SITE | "NI" |

## 22. INSERT dbo.nrt_lab_rpt_user_comment_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: USER_COMMENT_KEY=3 |
| Transaction end | 2026-04-30T19:27:58.390 |
| LSN | 0x00006bfb000001800002 |

### Inserted Row

| Field | Value |
| --- | --- |
| LAB_RPT_USER_COMMENT_UID | 10009293 |
| LAB_TEST_UID | 10009291 |
| USER_COMMENT_KEY | 3 |
| created_dttm | "2026-04-30T19:27:58.3600000" |
| updated_dttm | "2026-04-30T19:27:58.3600000" |

## 23. INSERT dbo.LAB_RPT_USER_COMMENT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: LAB_TEST_KEY=2, USER_COMMENT_KEY=3 |
| Transaction end | 2026-04-30T19:27:58.390 |
| LSN | 0x00006bfb000001800002 |

### Inserted Row

| Field | Value |
| --- | --- |
| COMMENTS_FOR_ELR_DT | "2026-04-30T19:27:33.777" |
| LAB_TEST_KEY | 2 |
| LAB_TEST_UID | 10009291 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.323" |
| RECORD_STATUS_CD | "ACTIVE" |
| USER_COMMENT_CREATED_BY | 10009282 |
| USER_COMMENT_KEY | 3 |
| USER_RPT_COMMENTS | "some comments" |

## 24. UPDATE dbo.LAB_TEST

| Metric | Value |
| --- | --- |
| Identity | business_keys: LAB_RPT_LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:27:58.713 |
| LSN | 0x00006bfb000003300013 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.323" | "2026-04-30T19:27:58.673" |

### Row After Change

| Field | Value |
| --- | --- |
| ELR_IND | "N" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAB_RPT_CREATED_BY | 10009282 |
| LAB_RPT_CREATED_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LAST_UPDATE_BY | 10009282 |
| LAB_RPT_LAST_UPDATE_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LOCAL_ID | "OBS10001000GA01" |
| LAB_RPT_RECEIVED_BY_PH_DT | "2026-04-30T00:00:00" |
| LAB_RPT_SHARE_IND | "T" |
| LAB_RPT_STATUS | "D" |
| LAB_RPT_UID | 10009291 |
| LAB_TEST_CD | "T-14900" |
| LAB_TEST_CD_DESC | "No Information Given" |
| LAB_TEST_CD_SYS_CD | "DEFAULT" |
| LAB_TEST_CD_SYS_NM | "Default Manual Lab" |
| LAB_TEST_DT | "2026-04-20T00:00:00" |
| LAB_TEST_KEY | 2 |
| LAB_TEST_PNTR | 10009291 |
| LAB_TEST_STATUS | "Final" |
| LAB_TEST_TYPE | "Order" |
| LAB_TEST_UID | 10009291 |
| OID | 1300100015 |
| PARENT_TEST_NM | "No Information Given" |
| PARENT_TEST_PNTR | 10009291 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.673" |
| RECORD_STATUS_CD | "ACTIVE" |
| ROOT_ORDERED_TEST_NM | "No Information Given" |
| ROOT_ORDERED_TEST_PNTR | 10009291 |
| SPECIMEN_ADD_TIME | "2026-04-30T19:27:33.910" |
| SPECIMEN_LAST_CHANGE_TIME | "2026-04-30T19:27:33.910" |
| SPECIMEN_SITE | "NI" |

## 25. UPDATE dbo.LAB_TEST

| Metric | Value |
| --- | --- |
| Identity | business_keys: LAB_RPT_LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:27:58.713 |
| LSN | 0x00006bfb000003300013 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.323" | "2026-04-30T19:27:58.673" |

### Row After Change

| Field | Value |
| --- | --- |
| ALT_LAB_TEST_CD | "31147-2" |
| ALT_LAB_TEST_CD_DESC | "REAGIN AB" |
| ALT_LAB_TEST_CD_SYS_CD | "LN" |
| ELR_IND | "N" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAB_RPT_CREATED_BY | 10009282 |
| LAB_RPT_CREATED_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LAST_UPDATE_BY | 10009282 |
| LAB_RPT_LAST_UPDATE_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LOCAL_ID | "OBS10001000GA01" |
| LAB_RPT_RECEIVED_BY_PH_DT | "2026-04-30T00:00:00" |
| LAB_RPT_SHARE_IND | "T" |
| LAB_RPT_UID | 10009294 |
| LAB_TEST_CD | "T-58955" |
| LAB_TEST_CD_DESC | "RPR Titer" |
| LAB_TEST_CD_SYS_CD | "DEFAULT" |
| LAB_TEST_CD_SYS_NM | "Default Manual Lab" |
| LAB_TEST_DT | "2026-04-20T00:00:00" |
| LAB_TEST_KEY | 3 |
| LAB_TEST_PNTR | 10009294 |
| LAB_TEST_TYPE | "Result" |
| LAB_TEST_UID | 10009294 |
| OID | 1300100015 |
| PARENT_TEST_NM | "No Information Given" |
| PARENT_TEST_PNTR | 10009291 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.673" |
| RECORD_STATUS_CD | "ACTIVE" |
| ROOT_ORDERED_TEST_NM | "No Information Given" |
| ROOT_ORDERED_TEST_PNTR | 10009291 |
| SPECIMEN_SITE | "NI" |

## 26. UPDATE dbo.nrt_lab_test_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:27:58.713 |
| LSN | 0x00006bfb000003300013 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:27:58.3266667" | "2026-04-30T19:27:58.6733333" |

### Row After Change

| Field | Value |
| --- | --- |
| LAB_TEST_KEY | 2 |
| LAB_TEST_UID | 10009291 |
| created_dttm | "2026-04-30T19:27:58.3266667" |
| updated_dttm | "2026-04-30T19:27:58.6733333" |

## 27. UPDATE dbo.nrt_lab_test_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:27:58.713 |
| LSN | 0x00006bfb000003300013 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:27:58.3266667" | "2026-04-30T19:27:58.6733333" |

### Row After Change

| Field | Value |
| --- | --- |
| LAB_TEST_KEY | 3 |
| LAB_TEST_UID | 10009294 |
| created_dttm | "2026-04-30T19:27:58.3266667" |
| updated_dttm | "2026-04-30T19:27:58.6733333" |

## 28. UPDATE dbo.LAB_RPT_USER_COMMENT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: LAB_TEST_KEY=2, USER_COMMENT_KEY=3 |
| Transaction end | 2026-04-30T19:27:58.713 |
| LSN | 0x00006bfb000003300013 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.323" | "2026-04-30T19:27:58.673" |

### Row After Change

| Field | Value |
| --- | --- |
| COMMENTS_FOR_ELR_DT | "2026-04-30T19:27:33.777" |
| LAB_TEST_KEY | 2 |
| LAB_TEST_UID | 10009291 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.673" |
| RECORD_STATUS_CD | "ACTIVE" |
| USER_COMMENT_CREATED_BY | 10009282 |
| USER_COMMENT_KEY | 3 |
| USER_RPT_COMMENTS | "some comments" |

## 29. UPDATE dbo.nrt_lab_rpt_user_comment_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: USER_COMMENT_KEY=3 |
| Transaction end | 2026-04-30T19:27:58.713 |
| LSN | 0x00006bfb000003300013 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:27:58.3600000" | "2026-04-30T19:27:58.6733333" |

### Row After Change

| Field | Value |
| --- | --- |
| LAB_RPT_USER_COMMENT_UID | 10009293 |
| LAB_TEST_UID | 10009291 |
| USER_COMMENT_KEY | 3 |
| created_dttm | "2026-04-30T19:27:58.3600000" |
| updated_dttm | "2026-04-30T19:27:58.6733333" |

## 30. INSERT dbo.nrt_lab_test_result_group_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: TEST_RESULT_GRP_KEY=2 |
| Transaction end | 2026-04-30T19:27:58.747 |
| LSN | 0x00006bfc000000100006 |

### Inserted Row

| Field | Value |
| --- | --- |
| LAB_TEST_UID | 10009294 |
| TEST_RESULT_GRP_KEY | 2 |
| created_dttm | "2026-04-30T19:27:58.7466667" |
| updated_dttm | "2026-04-30T19:27:58.7466667" |

## 31. UPDATE dbo.nrt_lab_test_result_group_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: TEST_RESULT_GRP_KEY=2 |
| Transaction end | 2026-04-30T19:27:58.833 |
| LSN | 0x00006bfc000000780015 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:27:58.7466667" | "2026-04-30T19:27:58.8333333" |

### Row After Change

| Field | Value |
| --- | --- |
| LAB_TEST_UID | 10009294 |
| TEST_RESULT_GRP_KEY | 2 |
| created_dttm | "2026-04-30T19:27:58.7466667" |
| updated_dttm | "2026-04-30T19:27:58.8333333" |

## 32. INSERT dbo.TEST_RESULT_GROUPING

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: TEST_RESULT_GRP_KEY=2 |
| Transaction end | 2026-04-30T19:27:58.837 |
| LSN | 0x00006bfc000000800005 |

### Inserted Row

| Field | Value |
| --- | --- |
| LAB_TEST_UID | 10009294 |
| TEST_RESULT_GRP_KEY | 2 |

## 33. INSERT dbo.LAB_RESULT_VAL

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: TEST_RESULT_GRP_KEY=2, TEST_RESULT_VAL_KEY=2 |
| Transaction end | 2026-04-30T19:27:58.840 |
| LSN | 0x00006bfc00000088001e |

### Inserted Row

| Field | Value |
| --- | --- |
| LAB_TEST_UID | 10009294 |
| NUMERIC_RESULT | "=1:128" |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.840" |
| RECORD_STATUS_CD | "ACTIVE" |
| TEST_RESULT_GRP_KEY | 2 |
| TEST_RESULT_VAL_KEY | 2 |

## 34. INSERT dbo.LAB_TEST_RESULT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:27:58.877 |
| LSN | 0x00006bfc000000a8000c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONDITION_KEY | 242 |
| COPY_TO_PROVIDER_KEY | 1 |
| INVESTIGATION_KEY | 1 |
| LAB_RPT_DT_KEY | 1 |
| LAB_TEST_KEY | 2 |
| LAB_TEST_TECHNICIAN_KEY | 1 |
| LAB_TEST_UID | 10009291 |
| LDF_GROUP_KEY | 1 |
| MORB_RPT_KEY | 1 |
| ORDERING_ORG_KEY | 1 |
| ORDERING_PROVIDER_KEY | 1 |
| PATIENT_KEY | 5 |
| PERFORMING_LAB_KEY | 1 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.873" |
| RECORD_STATUS_CD | "ACTIVE" |
| REPORTING_LAB_KEY | 4 |
| RESULT_COMMENT_GRP_KEY | 1 |
| SPECIMEN_COLLECTOR_KEY | 1 |
| TEST_RESULT_GRP_KEY | 1 |

## 35. INSERT dbo.LAB_TEST_RESULT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:27:58.877 |
| LSN | 0x00006bfc000000a8000c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONDITION_KEY | 1 |
| COPY_TO_PROVIDER_KEY | 1 |
| INVESTIGATION_KEY | 1 |
| LAB_RPT_DT_KEY | 1 |
| LAB_TEST_KEY | 3 |
| LAB_TEST_TECHNICIAN_KEY | 1 |
| LAB_TEST_UID | 10009294 |
| LDF_GROUP_KEY | 1 |
| MORB_RPT_KEY | 1 |
| ORDERING_ORG_KEY | 1 |
| ORDERING_PROVIDER_KEY | 1 |
| PATIENT_KEY | 5 |
| PERFORMING_LAB_KEY | 1 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.873" |
| RECORD_STATUS_CD | "ACTIVE" |
| REPORTING_LAB_KEY | 1 |
| RESULT_COMMENT_GRP_KEY | 1 |
| SPECIMEN_COLLECTOR_KEY | 1 |
| TEST_RESULT_GRP_KEY | 2 |

## 36. INSERT dbo.LAB100

| Metric | Value |
| --- | --- |
| Identity | business_keys: PERSON_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:27:59.500 |
| LSN | 0x00006bfd00000060003f |

### Inserted Row

| Field | Value |
| --- | --- |
| ADDR_CD_DESC | "HOUSE" |
| ADDR_USE_CD_DESC | "HOME" |
| AGE_REPORTED | 41 |
| ALT_LAB_TEST_CD | "31147-2" |
| ALT_LAB_TEST_CD_DESC | "REAGIN AB" |
| ALT_LAB_TEST_CD_SYS_CD | "LN" |
| ELR_IND | "N" |
| EVENT_DATE | "2026-04-20T00:00:00" |
| INVESTIGATION_KEYS | "1" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAB_RPT_CREATED_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LAST_UPDATE_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LOCAL_ID | "OBS10001000GA01" |
| LAB_RPT_RECEIVED_BY_PH_DT | "2026-04-30T00:00:00" |
| LAB_RPT_STATUS | "D" |
| LAB_TEST_DT | "2026-04-20T00:00:00" |
| LAB_TEST_STATUS | "Final" |
| NUMERIC_RESULT_WITHUNITS | "=1:128" |
| ORDERED_LABTEST_CD_SYS_NM | "Default Manual Lab" |
| ORDERED_LAB_TEST_CD | "T-14900" |
| ORDERED_LAB_TEST_CD_DESC | "No Information Given" |
| ORDERING_PROVIDER_NM | "," |
| PATIENT_ADDRESS | "1313 Pine Way,ATLANTA,Fulton County,30033,Georgia" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_KEY | 5 |
| PATIENT_REPORTED_AGE_UNITS | "Years" |
| PATIENT_STATE | "Georgia" |
| PATIENT_ZIP_CODE | "30033" |
| PERSON_CURR_GENDER | "F" |
| PERSON_DOB | "1985-03-17T00:00:00" |
| PERSON_FIRST_NM | "Taylor" |
| PERSON_LAST_NM | "Swift_fake77gg" |
| PERSON_LOCAL_ID | "PSN10067000GA01" |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_AREA_DESC | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:59.500" |
| RECORD_STATUS_CD | "ACTIVE" |
| REPORTING_FACILITY | "Emory University Hospital" |
| REPORTING_FACILITY_UID | 10003019 |
| RESULTEDTEST_CD_SYS_NM | "Default Manual Lab" |
| RESULTED_LAB_TEST_CD | "T-58955" |
| RESULTED_LAB_TEST_CD_DESC | "RPR Titer" |
| RESULTED_LAB_TEST_KEY | 3 |

## 37. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:27:59.857 |
| LSN | 0x00006bfd000001980011 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:27:33.910" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| ELECTRONIC_IND | "N" |
| EVENT_TYPE | "LabReport" |
| EVENT_UID | 10009291 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:27:33.910" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "OBS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "UNPROCESSED" |
| RECORD_STATUS_DESC_TXT | "Unprocessed" |
| RECORD_STATUS_TIME | "2026-04-30T19:27:33.910" |
| STATUS_CD | "D" |
| STATUS_DESC_TXT | "Completed / Final" |
| STATUS_TIME | "2026-04-30T19:27:33.767" |

## 38. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:27:59.863 |
| LSN | 0x00006bfd000001a8001c |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:27:33.910" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| ELECTRONIC_IND | "N" |
| EVENT_TYPE | "LabReport" |
| EVENT_UID | 10009291 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:27:33.910" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "OBS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "UNPROCESSED" |
| RECORD_STATUS_DESC_TXT | "Unprocessed" |
| RECORD_STATUS_TIME | "2026-04-30T19:27:33.910" |
| STATUS_CD | "D" |
| STATUS_DESC_TXT | "Completed / Final" |
| STATUS_TIME | "2026-04-30T19:27:33.767" |

## 39. DELETE dbo.nrt_observation_material

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: act_uid=10009291, material_id=10009295 |
| Transaction end | 2026-04-30T19:32:04.773 |
| LSN | 0x00006bfe000001700016 |

### Deleted Row

| Field | Value |
| --- | --- |
| act_uid | 10009291 |
| last_chg_time | "2026-04-30T19:27:33.777" |
| material_cd | "" |
| material_desc | "" |
| material_id | 10009295 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:27:42.8335213" |
| subject_class_cd | "MAT" |
| type_cd | "SPC" |
| type_desc_txt | "Specimen" |

## 40. INSERT dbo.nrt_observation_material

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: act_uid=10009291, material_id=10009295 |
| Transaction end | 2026-04-30T19:32:04.773 |
| LSN | 0x00006bfe000001700016 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009291 |
| last_chg_time | "2026-04-30T19:27:33.777" |
| material_cd | "" |
| material_desc | "" |
| material_id | 10009295 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:32:04.7737713" |
| subject_class_cd | "MAT" |
| type_cd | "SPC" |
| type_desc_txt | "Specimen" |

## 41. UPDATE dbo.nrt_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:32:04.793 |
| LSN | 0x00006bfe000001780003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| associated_phc_uids | null | "10009300" |
| batch_id | 1777577262268 | 1777577524335 |
| followup_observation_uid | null | "10009292,10009293" |
| last_chg_time | "2026-04-30T19:27:33.910" | "2026-04-30T19:32:00.707" |
| record_status_cd | "UNPROCESSED" | "PROCESSED" |
| record_status_time | "2026-04-30T19:27:33.910" | "2026-04-30T19:32:00.707" |
| refresh_datetime | "2026-04-30T19:27:42.8335213" | "2026-04-30T19:32:04.7937878" |
| result_observation_uid | null | "10009294" |
| version_ctrl_nbr | 1 | 2 |

### Row After Change

| Field | Value |
| --- | --- |
| accession_number | "" |
| act_uid | 10009291 |
| activity_to_time | "2026-04-20T00:00:00" |
| add_time | "2026-04-30T19:27:33.910" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| associated_phc_uids | "10009300" |
| author_organization_id | 10003019 |
| batch_id | 1777577524335 |
| cd | "T-14900" |
| cd_desc_txt | "No Information Given" |
| cd_system_cd | "DEFAULT" |
| cd_system_desc_txt | "Default Manual Lab" |
| class_cd | "OBS" |
| ctrl_cd_display_form | "LabReport" |
| electronic_ind | "N" |
| followup_observation_uid | "10009292,10009293" |
| jurisdiction_cd | "130001" |
| last_chg_time | "2026-04-30T19:32:00.707" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "OBS10001000GA01" |
| material_id | 10009295 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mood_cd | "EVN" |
| obs_domain_cd_st_1 | "Order" |
| observation_uid | 10009291 |
| patient_id | 10009287 |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| record_status_cd | "PROCESSED" |
| record_status_time | "2026-04-30T19:32:00.707" |
| refresh_datetime | "2026-04-30T19:32:04.7937878" |
| report_observation_uid | 10009291 |
| result_observation_uid | "10009294" |
| rpt_to_state_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| status_cd | "D" |
| status_time | "2026-04-30T19:27:33.767" |
| target_site_cd | "NI" |
| version_ctrl_nbr | 2 |

## 42. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:32:04.823 |
| LSN | 0x00006bfe000001a00005 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777577524326 |
| branch_id | 10009292 |
| branch_type_cd | "APND" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:32:04.8238823" |
| root_type_cd | "LabReport" |

## 43. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:32:04.827 |
| LSN | 0x00006bfe000001a80005 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777577524326 |
| branch_id | 10009294 |
| branch_type_cd | "COMP" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:32:04.8287777" |
| root_type_cd | "LabReport" |

## 44. INSERT dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:32:04.890 |
| LSN | 0x00006bfe000001c00005 |

### Inserted Row

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:32:00.600" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| age_reported | 41 |
| age_reported_unit | "Years" |
| age_reported_unit_cd | "Y" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:32:00.600" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009296 |
| phone_ext_home | "" |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:32:04.8909266" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 45. INSERT dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001000GA01", public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:32:04.963 |
| LSN | 0x00006bfe000001c80003 |

### Inserted Row

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-24T00:00:00" |
| add_time | "2026-04-30T19:32:00.637" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777577524326 |
| case_class_cd | "" |
| case_count | 1 |
| case_management_uid | 1000 |
| case_type_cd | "I" |
| cd | "700" |
| cd_desc_txt | "Syphilis, Unknown" |
| city_county_case_nbr | "" |
| class_cd | "CASE" |
| coinfection_id | "COIN1000XX01" |
| curr_process_state | "Surveillance Follow-up" |
| curr_process_state_cd | "SF" |
| init_fup_investgr_of_phc_uid | 10003010 |
| inv_state_case_id | "" |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Open" |
| investigation_status_cd | "O" |
| investigator_id | 10003010 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T19:32:00.637" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| legacy_case_id | "" |
| local_id | "CAS10001000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "17" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:32:00.637" |
| nac_last_chg_time | "2026-04-30T19:32:00.637" |
| nac_page_case_uid | 10009300 |
| org_as_reporter_uid | 10003019 |
| organization_id | 10003019 |
| patient_id | 10009296 |
| pregnant_ind | "Yes" |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INV_ADMINISTRATIVE" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T19:32:00.637" |
| referral_basis | "T1 - Positive Test" |
| referral_basis_cd | "T1" |
| refresh_datetime | "2026-04-30T19:32:04.9644819" |
| rpt_form_cmplt_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| surv_investgr_of_phc_uid | 10003010 |

## 46. INSERT dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:32:05.187 |
| LSN | 0x00006bfe000001f8004e |

### Inserted Row

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| case_management_uid | 1000 |
| case_oid | 1300100015 |
| epi_link_id | "1310000026" |
| fl_fup_field_record_num | "1310000026" |
| init_fup_initial_foll_up | "Surveillance Follow-up" |
| init_fup_initial_foll_up_cd | "SF" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:32:05.0179689" |
| surv_investigator_assgn_dt | "2026-04-24T00:00:00" |

## 47. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:32:05.207 |
| LSN | 0x00006bfe000002080004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:27:33.867" | "2026-04-30T19:32:00.587" |
| refresh_datetime | "2026-04-30T19:27:43.1595805" | "2026-04-30T19:32:05.2018263" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:32:00.587" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:32:05.2018263" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 48. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:06.820 |
| LSN | 0x00006bfe000002680005 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777577524326 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:32:00.637" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3241 |
| nbs_question_uid | 10001013 |
| nbs_rdb_metadata_uid | 10062226 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012401 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NOT120" |
| question_label | "Immediate National Notifiable Condition" |
| rdb_column_nm | "ADM_IMM_NTNL_NTFBL_CNDTN" |
| rdb_table_nm | "D_INV_ADMINISTRATIVE" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:32:06.7240072" |
| seq_nbr | 0 |

## 49. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:06.820 |
| LSN | 0x00006bfe000002680005 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "30" |
| batch_id | 1777577524326 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:32:00.637" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3242 |
| nbs_question_uid | 10001252 |
| nbs_rdb_metadata_uid | 10062300 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012499 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS128" |
| question_label | "Weeks" |
| rdb_column_nm | "PBI_PATIENT_PREGNANT_WKS" |
| rdb_table_nm | "D_INV_PREGNANCY_BIRTH" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:32:06.7240072" |
| seq_nbr | 0 |

## 50. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T19:32:18.850 |
| LSN | 0x00006bfe00000298002f |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:27:57.6333333" | "2026-04-30T19:32:18.7566667" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T19:32:18.7566667" |

## 51. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:32:18.850 |
| LSN | 0x00006bfe00000298002f |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:27:33.867" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 52. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:32:18.850 |
| LSN | 0x00006bfe00000298002f |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:32:00.587" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 53. INSERT dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=6 |
| Transaction end | 2026-04-30T19:32:18.850 |
| LSN | 0x00006bfe00000298002f |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:18.7866667" |
| d_patient_key | 6 |
| patient_uid | 10009296 |
| updated_dttm | "2026-04-30T19:32:18.7866667" |

## 54. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:32:18.850 |
| LSN | 0x00006bfe00000298002f |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 55. INSERT dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=3 |
| Transaction end | 2026-04-30T19:32:19.157 |
| LSN | 0x00006bfe000003300009 |

### Inserted Row

| Field | Value |
| --- | --- |
| case_uid | 10009300 |
| created_dttm | "2026-04-30T19:32:19.1500000" |
| d_investigation_key | 3 |
| updated_dttm | "2026-04-30T19:32:19.1500000" |

## 56. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:32:19.157 |
| LSN | 0x00006bfe000003300009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Surveillance Follow-up" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:32:00.637" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |

## 57. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=1, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T19:32:19.183 |
| LSN | 0x00006bfe000003400007 |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_METHOD_KEY | 1 |
| INVESTIGATION_KEY | 3 |

## 58. INSERT dbo.LOOKUP_TABLE_N_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:19.773 |
| LSN | 0x00006bff000000b8000f |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 59. INSERT dbo.L_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:19.847 |
| LSN | 0x00006bff000001180005 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PAGE_CASE_UID | 10009300.0 |

## 60. INSERT dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:19.920 |
| LSN | 0x00006bff00000138000a |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 61. INSERT dbo.LOOKUP_TABLE_N_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:20.183 |
| LSN | 0x00006bff00000340000f |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 62. INSERT dbo.L_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:20.203 |
| LSN | 0x00006bff000003a00005 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| PAGE_CASE_UID | 10009300.0 |

## 63. INSERT dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:20.217 |
| LSN | 0x00006bff000003c0000c |

### Inserted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 64. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=217, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=3, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=1, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T19:32:20.357 |
| LSN | 0x00006bff000004300005 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 217 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 3 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 1 |
| RPT_SRC_ORG_KEY | 4 |

## 65. INSERT dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:32:20.410 |
| LSN | 0x00006bff00000468001d |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:20.4066667" |
| d_case_management_key | 2 |
| public_health_case_uid | 10009300 |
| updated_dttm | "2026-04-30T19:32:20.4066667" |

## 66. INSERT dbo.D_CASE_MANAGEMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:20.410 |
| LSN | 0x00006bff00000468001d |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_USER_ID | 10009282.0 |
| CASE_OID | 1300100015.0 |
| D_CASE_MANAGEMENT_KEY | 2.0 |
| EPI_LINK_ID | "1310000026" |
| FL_FUP_FIELD_RECORD_NUM | "1310000026" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INVESTIGATION_KEY | 3.0 |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24" |

## 67. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:20.547 |
| LSN | 0x00006bff000004c00002 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 217 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 1 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 1 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 1 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 1 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 1 |
| D_INV_SOCIAL_HISTORY_KEY | 1 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 1 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 1 |
| INIT_ASGNED_INTERVIEWER_KEY | 1 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 3 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 1 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 1 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 68. UPDATE dbo.LAB_TEST

| Metric | Value |
| --- | --- |
| Identity | business_keys: LAB_RPT_LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:32:20.753 |
| LSN | 0x00006bff00000570001e |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| LAB_RPT_LAST_UPDATE_DT | "2026-04-30T19:27:33.910" | "2026-04-30T19:32:00.707" |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.673" | "2026-04-30T19:32:20.710" |
| SPECIMEN_LAST_CHANGE_TIME | "2026-04-30T19:27:33.910" | "2026-04-30T19:32:00.707" |

### Row After Change

| Field | Value |
| --- | --- |
| ELR_IND | "N" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAB_RPT_CREATED_BY | 10009282 |
| LAB_RPT_CREATED_DT | "2026-04-30T19:27:33.910" |
| LAB_RPT_LAST_UPDATE_BY | 10009282 |
| LAB_RPT_LAST_UPDATE_DT | "2026-04-30T19:32:00.707" |
| LAB_RPT_LOCAL_ID | "OBS10001000GA01" |
| LAB_RPT_RECEIVED_BY_PH_DT | "2026-04-30T00:00:00" |
| LAB_RPT_SHARE_IND | "T" |
| LAB_RPT_STATUS | "D" |
| LAB_RPT_UID | 10009291 |
| LAB_TEST_CD | "T-14900" |
| LAB_TEST_CD_DESC | "No Information Given" |
| LAB_TEST_CD_SYS_CD | "DEFAULT" |
| LAB_TEST_CD_SYS_NM | "Default Manual Lab" |
| LAB_TEST_DT | "2026-04-20T00:00:00" |
| LAB_TEST_KEY | 2 |
| LAB_TEST_PNTR | 10009291 |
| LAB_TEST_STATUS | "Final" |
| LAB_TEST_TYPE | "Order" |
| LAB_TEST_UID | 10009291 |
| OID | 1300100015 |
| PARENT_TEST_NM | "No Information Given" |
| PARENT_TEST_PNTR | 10009291 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:32:20.710" |
| RECORD_STATUS_CD | "ACTIVE" |
| ROOT_ORDERED_TEST_NM | "No Information Given" |
| ROOT_ORDERED_TEST_PNTR | 10009291 |
| SPECIMEN_ADD_TIME | "2026-04-30T19:27:33.910" |
| SPECIMEN_LAST_CHANGE_TIME | "2026-04-30T19:32:00.707" |
| SPECIMEN_SITE | "NI" |

## 69. UPDATE dbo.nrt_lab_test_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:20.753 |
| LSN | 0x00006bff00000570001e |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:27:58.6733333" | "2026-04-30T19:32:20.7100000" |

### Row After Change

| Field | Value |
| --- | --- |
| LAB_TEST_KEY | 2 |
| LAB_TEST_UID | 10009291 |
| created_dttm | "2026-04-30T19:27:58.3266667" |
| updated_dttm | "2026-04-30T19:32:20.7100000" |

## 70. UPDATE dbo.LAB_RPT_USER_COMMENT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: LAB_TEST_KEY=2, USER_COMMENT_KEY=3 |
| Transaction end | 2026-04-30T19:32:20.753 |
| LSN | 0x00006bff00000570001e |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.673" | "2026-04-30T19:32:20.710" |

### Row After Change

| Field | Value |
| --- | --- |
| COMMENTS_FOR_ELR_DT | "2026-04-30T19:27:33.777" |
| LAB_TEST_KEY | 2 |
| LAB_TEST_UID | 10009291 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:32:20.710" |
| RECORD_STATUS_CD | "ACTIVE" |
| USER_COMMENT_CREATED_BY | 10009282 |
| USER_COMMENT_KEY | 3 |
| USER_RPT_COMMENTS | "some comments" |

## 71. UPDATE dbo.nrt_lab_rpt_user_comment_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: USER_COMMENT_KEY=3 |
| Transaction end | 2026-04-30T19:32:20.753 |
| LSN | 0x00006bff00000570001e |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:27:58.6733333" | "2026-04-30T19:32:20.7100000" |

### Row After Change

| Field | Value |
| --- | --- |
| LAB_RPT_USER_COMMENT_UID | 10009293 |
| LAB_TEST_UID | 10009291 |
| USER_COMMENT_KEY | 3 |
| created_dttm | "2026-04-30T19:27:58.3600000" |
| updated_dttm | "2026-04-30T19:32:20.7100000" |

## 72. DELETE dbo.LAB_TEST_RESULT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:21.017 |
| LSN | 0x00006c00000000d80005 |

### Deleted Row

| Field | Value |
| --- | --- |
| CONDITION_KEY | 242 |
| COPY_TO_PROVIDER_KEY | 1 |
| INVESTIGATION_KEY | 1 |
| LAB_RPT_DT_KEY | 1 |
| LAB_TEST_KEY | 2 |
| LAB_TEST_TECHNICIAN_KEY | 1 |
| LAB_TEST_UID | 10009291 |
| LDF_GROUP_KEY | 1 |
| MORB_RPT_KEY | 1 |
| ORDERING_ORG_KEY | 1 |
| ORDERING_PROVIDER_KEY | 1 |
| PATIENT_KEY | 5 |
| PERFORMING_LAB_KEY | 1 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:27:58.873" |
| RECORD_STATUS_CD | "ACTIVE" |
| REPORTING_LAB_KEY | 4 |
| RESULT_COMMENT_GRP_KEY | 1 |
| SPECIMEN_COLLECTOR_KEY | 1 |
| TEST_RESULT_GRP_KEY | 1 |

## 73. INSERT dbo.LAB_TEST_RESULT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:21.017 |
| LSN | 0x00006c00000000d80005 |

### Inserted Row

| Field | Value |
| --- | --- |
| CONDITION_KEY | 242 |
| COPY_TO_PROVIDER_KEY | 1 |
| INVESTIGATION_KEY | 3 |
| LAB_RPT_DT_KEY | 1 |
| LAB_TEST_KEY | 2 |
| LAB_TEST_TECHNICIAN_KEY | 1 |
| LAB_TEST_UID | 10009291 |
| LDF_GROUP_KEY | 1 |
| MORB_RPT_KEY | 1 |
| ORDERING_ORG_KEY | 1 |
| ORDERING_PROVIDER_KEY | 1 |
| PATIENT_KEY | 5 |
| PERFORMING_LAB_KEY | 1 |
| RDB_LAST_REFRESH_TIME | "2026-04-30T19:32:21.017" |
| RECORD_STATUS_CD | "ACTIVE" |
| REPORTING_LAB_KEY | 4 |
| RESULT_COMMENT_GRP_KEY | 1 |
| SPECIMEN_COLLECTOR_KEY | 1 |
| TEST_RESULT_GRP_KEY | 1 |

## 74. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:32:21.650 |
| LSN | 0x00006c03000003b00009 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:27:33.910" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| ELECTRONIC_IND | "N" |
| EVENT_TYPE | "LabReport" |
| EVENT_UID | 10009291 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:27:33.910" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "OBS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "UNPROCESSED" |
| RECORD_STATUS_DESC_TXT | "Unprocessed" |
| RECORD_STATUS_TIME | "2026-04-30T19:27:33.910" |
| STATUS_CD | "D" |
| STATUS_DESC_TXT | "Completed / Final" |
| STATUS_TIME | "2026-04-30T19:27:33.767" |

## 75. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:32:21.650 |
| LSN | 0x00006c03000003b00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:27:33.910" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| ELECTRONIC_IND | "N" |
| EVENT_TYPE | "LabReport" |
| EVENT_UID | 10009291 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:32:00.707" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "OBS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "PROCESSED" |
| RECORD_STATUS_DESC_TXT | "Processed" |
| RECORD_STATUS_TIME | "2026-04-30T19:32:00.707" |
| STATUS_CD | "D" |
| STATUS_DESC_TXT | "Completed / Final" |
| STATUS_TIME | "2026-04-30T19:27:33.767" |

## 76. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:32:21.653 |
| LSN | 0x00006c03000003b80004 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "700" |
| CONDITION_DESC_TXT | "Syphilis, Unknown" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:32:00.637" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:32:00.637" |

## 77. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:32:21.660 |
| LSN | 0x00006c03000003c00009 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:27:33.910" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| ELECTRONIC_IND | "N" |
| EVENT_TYPE | "LabReport" |
| EVENT_UID | 10009291 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:27:33.910" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "OBS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "UNPROCESSED" |
| RECORD_STATUS_DESC_TXT | "Unprocessed" |
| RECORD_STATUS_TIME | "2026-04-30T19:27:33.910" |
| STATUS_CD | "D" |
| STATUS_DESC_TXT | "Completed / Final" |
| STATUS_TIME | "2026-04-30T19:27:33.767" |

## 78. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="OBS10001000GA01" |
| Transaction end | 2026-04-30T19:32:21.660 |
| LSN | 0x00006c03000003c00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:27:33.910" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| ELECTRONIC_IND | "N" |
| EVENT_TYPE | "LabReport" |
| EVENT_UID | 10009291 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:32:00.707" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "OBS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "PROCESSED" |
| RECORD_STATUS_DESC_TXT | "Processed" |
| RECORD_STATUS_TIME | "2026-04-30T19:32:00.707" |
| STATUS_CD | "D" |
| STATUS_DESC_TXT | "Completed / Final" |
| STATUS_TIME | "2026-04-30T19:27:33.767" |

## 79. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:32:21.663 |
| LSN | 0x00006c03000003c80004 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "700" |
| CONDITION_DESC_TXT | "Syphilis, Unknown" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:32:00.637" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:32:00.637" |

## 80. INSERT dbo.INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:32:56.513 |
| LSN | 0x00006c05000001f00005 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 1 |
| INVESTIGATION_KEY | 3 |

## 81. INSERT dbo.STD_HIV_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:32:56.857 |
| LSN | 0x00006c0500000490001c |

### Inserted Row

| Field | Value |
| --- | --- |
| CALC_5_YEAR_AGE_GROUP | " 9" |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| COINFECTION_ID | "COIN1000XX01" |
| CONDITION_CD | "700" |
| CONDITION_KEY | 217 |
| CURR_PROCESS_STATE | "Surveillance Follow-up" |
| EPI_LINK_ID | "1310000026" |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| FIELD_RECORD_NUMBER | "1310000026" |
| HOSPITAL_KEY | 1 |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_STATUS | "Open" |
| INVESTIGATOR_CLOSED_KEY | 1 |
| INVESTIGATOR_CURRENT_KEY | 3 |
| INVESTIGATOR_CURRENT_QC | "2" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 1 |
| INVESTIGATOR_FL_FUP_KEY | 1 |
| INVESTIGATOR_INITIAL_KEY | 3 |
| INVESTIGATOR_INITIAL_QC | "2" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 1 |
| INVESTIGATOR_INIT_INTRVW_KEY | 1 |
| INVESTIGATOR_INTERVIEW_KEY | 1 |
| INVESTIGATOR_SUPER_CASE_KEY | 1 |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 1 |
| INVESTIGATOR_SURV_KEY | 3 |
| INVESTIGATOR_SURV_QC | "2" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| ORDERING_FACILITY_KEY | 1 |
| PATIENT_AGE_REPORTED | "          41 Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_NAME | "Swift_fake77gg, Taylor" |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_PREGNANT_IND | "Yes" |
| PATIENT_RACE | "White" |
| PATIENT_SEX | "Female" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| PHYSICIAN_FL_FUP_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| REFERRAL_BASIS | "T1 - Positive Test" |
| REPORTING_ORG_KEY | 4 |
| REPORTING_PROV_KEY | 1 |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24T00:00:00" |

## 82. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:32:57.153 |
| LSN | 0x00006c05000005780005 |

### Inserted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| DISEASE | "Syphilis, Unknown" |
| DISEASE_CD | "700" |
| EVENT_DATE | "2026-04-24T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:32:00.637" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 83. INSERT dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:32:57.427 |
| LSN | 0x00006c05000006180004 |

### Inserted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CURR_PROCESS_STATE | "Surveillance Follow-up" |
| DISEASE | "Syphilis, Unknown" |
| DISEASE_CD | "700" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Open" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 84. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:32:57.447 |
| LSN | 0x00006c05000006280004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| EVENT_DATE | null | "2026-04-24T00:00:00" |
| EVENT_DATE_TYPE | null | "Investigation Start Date" |

### Row After Change

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CURR_PROCESS_STATE | "Surveillance Follow-up" |
| DISEASE | "Syphilis, Unknown" |
| DISEASE_CD | "700" |
| EVENT_DATE | "2026-04-24T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Open" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 85. INSERT dbo.nrt_treatment

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="TRT10000000GA01" |
| Transaction end | 2026-04-30T19:35:56.577 |
| LSN | 0x00006c0600000968001a |

### Inserted Row

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:35:52.997" |
| add_user_id | 10009282 |
| associated_phc_uids | "10009300" |
| cd | "176" |
| last_change_time | "2026-04-30T19:35:53.003" |
| last_change_user_id | "10009282" |
| local_id | "TRT10000000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| organization_uid | 10003007 |
| patient_treatment_uid | 10009283 |
| provider_uid | 10003004 |
| record_status_cd | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:35:56.4475661" |
| treatment_date | "2026-04-22T00:00:00" |
| treatment_dosage_strength | "2.4" |
| treatment_dosage_strength_unit | "mu" |
| treatment_drug | "176" |
| treatment_frequency | "Once" |
| treatment_name | "Benzathine penicillin G (Bicillin), 2.4 mu, IM, x 1 dose" |
| treatment_oid | "1" |
| treatment_route | "C0556983" |
| treatment_shared_ind | "T" |
| treatment_uid | 10009301 |
| version_control_number | "1" |

## 86. INSERT dbo.nrt_treatment_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:36:01.830 |
| LSN | 0x00006c06000009f00023 |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:36:01.8233333" |
| d_treatment_key | 2 |
| public_health_case_uid | 10009300 |
| treatment_uid | 10009301 |
| updated_dttm | "2026-04-30T19:36:01.8233333" |

## 87. INSERT dbo.TREATMENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: TREATMENT_LOCAL_ID="TRT10000000GA01" |
| Transaction end | 2026-04-30T19:36:01.830 |
| LSN | 0x00006c06000009f00023 |

### Inserted Row

| Field | Value |
| --- | --- |
| RECORD_STATUS_CD | "ACTIVE" |
| TREATMENT_DOSAGE_STRENGTH | "2.4" |
| TREATMENT_DOSAGE_STRENGTH_UNIT | "mu" |
| TREATMENT_DRUG | "176" |
| TREATMENT_FREQUENCY | "Once" |
| TREATMENT_KEY | 2 |
| TREATMENT_LOCAL_ID | "TRT10000000GA01" |
| TREATMENT_NM | "Benzathine penicillin G (Bicillin), 2.4 mu, IM, x 1 dose" |
| TREATMENT_OID | 1 |
| TREATMENT_ROUTE | "C0556983" |
| TREATMENT_SHARED_IND | "T" |
| TREATMENT_UID | 10009301 |

## 88. INSERT dbo.TREATMENT_EVENT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=217, INVESTIGATION_KEY=3, LDF_GROUP_KEY=1, MORB_RPT_KEY=1, PATIENT_KEY=4, TREATMENT_DT_KEY=1, TREATMENT_KEY=2, TREATMENT_PHYSICIAN_KEY=2, TREATMENT_PROVIDING_ORG_KEY=3 |
| Transaction end | 2026-04-30T19:36:01.830 |
| LSN | 0x00006c06000009f00023 |

### Inserted Row

| Field | Value |
| --- | --- |
| CONDITION_KEY | 217 |
| INVESTIGATION_KEY | 3 |
| LDF_GROUP_KEY | 1 |
| MORB_RPT_KEY | 1 |
| PATIENT_KEY | 4 |
| RECORD_STATUS_CD | "ACTIVE" |
| TREATMENT_COUNT | 1 |
| TREATMENT_DT_KEY | 1 |
| TREATMENT_KEY | 2 |
| TREATMENT_PHYSICIAN_KEY | 2 |
| TREATMENT_PROVIDING_ORG_KEY | 3 |

## 89. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:39:28.677 |
| LSN | 0x00006c0600000b980004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577524326 | 1777577968211 |
| refresh_datetime | "2026-04-30T19:32:04.8238823" | "2026-04-30T19:39:28.6773703" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777577968211 |
| branch_id | 10009292 |
| branch_type_cd | "APND" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:39:28.6773703" |
| root_type_cd | "LabReport" |

## 90. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:39:28.677 |
| LSN | 0x00006c0600000b980004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577524326 | 1777577968211 |
| refresh_datetime | "2026-04-30T19:32:04.8287777" | "2026-04-30T19:39:28.6773703" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777577968211 |
| branch_id | 10009294 |
| branch_type_cd | "COMP" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:39:28.6773703" |
| root_type_cd | "LabReport" |

## 91. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:39:28.693 |
| LSN | 0x00006c0600000ba00007 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777577968211 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:39:28.6875516" |
| root_type_cd | "TreatmentToPHC" |

## 92. INSERT dbo.nrt_investigation_confirmation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:39:28.693 |
| LSN | 0x00006c0600000ba00007 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777577968211 |
| confirmation_method_cd | "LD" |
| confirmation_method_desc_txt | "Laboratory confirmed" |
| confirmation_method_time | "2026-04-24T00:00:00" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:39:28.6875516" |

## 93. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:28.750 |
| LSN | 0x00006c0600000bd80002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577524326 | 1777577968211 |
| last_chg_time | "2026-04-30T19:32:00.637" | "2026-04-30T19:39:22.743" |
| refresh_datetime | "2026-04-30T19:32:06.7240072" | "2026-04-30T19:39:28.7074060" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777577968211 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:39:22.743" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3241 |
| nbs_question_uid | 10001013 |
| nbs_rdb_metadata_uid | 10062226 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012401 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NOT120" |
| question_label | "Immediate National Notifiable Condition" |
| rdb_column_nm | "ADM_IMM_NTNL_NTFBL_CNDTN" |
| rdb_table_nm | "D_INV_ADMINISTRATIVE" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" |
| seq_nbr | 0 |

## 94. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:28.750 |
| LSN | 0x00006c0600000bd80002 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/20/2026" |
| batch_id | 1777577968211 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:39:22.743" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3243 |
| nbs_question_uid | 10001192 |
| nbs_rdb_metadata_uid | 10062178 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012367 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD105" |
| question_label | "Treatment Start Date" |
| rdb_column_nm | "TRT_TREATMENT_DATE" |
| rdb_table_nm | "D_INV_TREATMENT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" |
| seq_nbr | 0 |

## 95. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:28.750 |
| LSN | 0x00006c0600000bd80002 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "720" |
| batch_id | 1777577968211 |
| code_set_group_id | 105450 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:39:22.743" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3244 |
| nbs_question_uid | 10001195 |
| nbs_rdb_metadata_uid | 10062221 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012398 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS136" |
| question_label | "Diagnosis Reported to CDC" |
| rdb_column_nm | "CLN_CASE_DIAGNOSIS" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" |
| seq_nbr | 0 |

## 96. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:28.750 |
| LSN | 0x00006c0600000bd80002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577524326 | 1777577968211 |
| last_chg_time | "2026-04-30T19:32:00.637" | "2026-04-30T19:39:22.743" |
| refresh_datetime | "2026-04-30T19:32:06.7240072" | "2026-04-30T19:39:28.7074060" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "30" |
| batch_id | 1777577968211 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:39:22.743" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3242 |
| nbs_question_uid | 10001252 |
| nbs_rdb_metadata_uid | 10062300 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012499 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS128" |
| question_label | "Weeks" |
| rdb_column_nm | "PBI_PATIENT_PREGNANT_WKS" |
| rdb_table_nm | "D_INV_PREGNANCY_BIRTH" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" |
| seq_nbr | 0 |

## 97. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001000GA01", public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:39:28.750 |
| LSN | 0x00006c0600000bd80002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577524326 | 1777577968211 |
| case_class_cd | "" | "C" |
| cd | "700" | "10312" |
| cd_desc_txt | "Syphilis, Unknown" | "Syphilis, secondary" |
| detection_method_cd | null | "21" |
| detection_method_desc_txt | null | "Self-referral" |
| diagnosis_time | null | "2026-04-21T00:00:00" |
| effective_from_time | null | "2026-04-17T00:00:00" |
| hospitalized_ind | null | "No" |
| hospitalized_ind_cd | null | "N" |
| inv_case_status | null | "Confirmed" |
| last_chg_time | "2026-04-30T19:32:00.637" | "2026-04-30T19:39:22.743" |
| nac_last_chg_time | "2026-04-30T19:32:00.637" | "2026-04-30T19:39:22.743" |
| pat_age_at_onset | null | "41" |
| pat_age_at_onset_unit | null | "Years" |
| pat_age_at_onset_unit_cd | null | "Y" |
| person_as_reporter_uid | null | 10003022 |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INV_ADMINISTRATIVE" | "D_INV_PREGNANCY_BIRTH,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_ADMINISTRATIVE" |
| record_status_time | "2026-04-30T19:32:00.637" | "2026-04-30T19:39:22.743" |
| refresh_datetime | "2026-04-30T19:32:04.9644819" | "2026-04-30T19:39:28.7074060" |
| transmission_mode | null | "Sexually Transmitted" |
| transmission_mode_cd | null | "S" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-24T00:00:00" |
| add_time | "2026-04-30T19:32:00.637" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777577968211 |
| case_class_cd | "C" |
| case_count | 1 |
| case_management_uid | 1000 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| city_county_case_nbr | "" |
| class_cd | "CASE" |
| coinfection_id | "COIN1000XX01" |
| curr_process_state | "Surveillance Follow-up" |
| curr_process_state_cd | "SF" |
| detection_method_cd | "21" |
| detection_method_desc_txt | "Self-referral" |
| diagnosis_time | "2026-04-21T00:00:00" |
| effective_from_time | "2026-04-17T00:00:00" |
| hospitalized_ind | "No" |
| hospitalized_ind_cd | "N" |
| init_fup_investgr_of_phc_uid | 10003010 |
| inv_case_status | "Confirmed" |
| inv_state_case_id | "" |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Open" |
| investigation_status_cd | "O" |
| investigator_id | 10003010 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T19:39:22.743" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| legacy_case_id | "" |
| local_id | "CAS10001000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "17" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:32:00.637" |
| nac_last_chg_time | "2026-04-30T19:39:22.743" |
| nac_page_case_uid | 10009300 |
| org_as_reporter_uid | 10003019 |
| organization_id | 10003019 |
| pat_age_at_onset | "41" |
| pat_age_at_onset_unit | "Years" |
| pat_age_at_onset_unit_cd | "Y" |
| patient_id | 10009296 |
| person_as_reporter_uid | 10003022 |
| pregnant_ind | "Yes" |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_ADMINISTRATIVE" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T19:39:22.743" |
| referral_basis | "T1 - Positive Test" |
| referral_basis_cd | "T1" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" |
| rpt_form_cmplt_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| surv_investgr_of_phc_uid | 10003010 |
| transmission_mode | "Sexually Transmitted" |
| transmission_mode_cd | "S" |

## 98. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:39:28.750 |
| LSN | 0x00006c0600000bd80002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T19:32:05.0179689" | "2026-04-30T19:39:28.7074060" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| case_management_uid | 1000 |
| case_oid | 1300100015 |
| epi_link_id | "1310000026" |
| fl_fup_field_record_num | "1310000026" |
| init_fup_initial_foll_up | "Surveillance Follow-up" |
| init_fup_initial_foll_up_cd | "SF" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:39:28.7074060" |
| surv_investigator_assgn_dt | "2026-04-24T00:00:00" |

## 99. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:39:28.770 |
| LSN | 0x00006c0600000be00005 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:32:00.587" | "2026-04-30T19:39:22.713" |
| refresh_datetime | "2026-04-30T19:32:05.2018263" | "2026-04-30T19:39:28.7705331" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:39:22.713" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:39:28.7705331" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 100. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:39:28.880 |
| LSN | 0x00006c0600000bf00003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:32:00.600" | "2026-04-30T19:39:22.727" |
| refresh_datetime | "2026-04-30T19:32:04.8909266" | "2026-04-30T19:39:28.8864534" |
| street_address_2 | null | "" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:32:00.600" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| age_reported | 41 |
| age_reported_unit | "Years" |
| age_reported_unit_cd | "Y" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:39:22.727" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009296 |
| phone_ext_home | "" |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:39:28.8864534" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| street_address_2 | "" |
| zip | "30033" |

## 101. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T19:39:42.033 |
| LSN | 0x00006c0700000258002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:32:18.7566667" | "2026-04-30T19:39:41.9400000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T19:39:41.9400000" |

## 102. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=6 |
| Transaction end | 2026-04-30T19:39:42.033 |
| LSN | 0x00006c0700000258002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:32:18.7866667" | "2026-04-30T19:39:41.9400000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:18.7866667" |
| d_patient_key | 6 |
| patient_uid | 10009296 |
| updated_dttm | "2026-04-30T19:39:41.9400000" |

## 103. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:39:42.033 |
| LSN | 0x00006c0700000258002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:32:00.587" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 104. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:39:42.033 |
| LSN | 0x00006c0700000258002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:39:22.713" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 105. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:39:42.033 |
| LSN | 0x00006c0700000258002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 106. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:39:42.033 |
| LSN | 0x00006c0700000258002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:39:22.727" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 107. UPDATE dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=3 |
| Transaction end | 2026-04-30T19:39:42.423 |
| LSN | 0x00006c0700000390000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:32:19.1500000" | "2026-04-30T19:39:42.4000000" |

### Row After Change

| Field | Value |
| --- | --- |
| case_uid | 10009300 |
| created_dttm | "2026-04-30T19:32:19.1500000" |
| d_investigation_key | 3 |
| updated_dttm | "2026-04-30T19:39:42.4000000" |

## 108. DELETE dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:39:42.423 |
| LSN | 0x00006c0700000390000c |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Surveillance Follow-up" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:32:00.637" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |

## 109. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:39:42.423 |
| LSN | 0x00006c0700000390000c |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Surveillance Follow-up" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_CASE_STATUS | "Confirmed" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:39:22.743" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 110. INSERT dbo.nrt_confirmation_method_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:42.467 |
| LSN | 0x00006c07000003a0000c |

### Inserted Row

| Field | Value |
| --- | --- |
| confirmation_method_cd | "LD" |
| created_dttm | "2026-04-30T19:39:42.4533333" |
| d_confirmation_method_key | 4 |
| updated_dttm | "2026-04-30T19:39:42.4533333" |

## 111. INSERT dbo.CONFIRMATION_METHOD

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4 |
| Transaction end | 2026-04-30T19:39:42.467 |
| LSN | 0x00006c07000003a0000c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_METHOD_CD | "LD" |
| CONFIRMATION_METHOD_DESC | "Laboratory confirmed" |
| CONFIRMATION_METHOD_KEY | 4 |

## 112. DELETE dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=1, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T19:39:42.467 |
| LSN | 0x00006c07000003a0000c |

### Deleted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_METHOD_KEY | 1 |
| INVESTIGATION_KEY | 3 |

## 113. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T19:39:42.467 |
| LSN | 0x00006c07000003a0000c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 114. DELETE dbo.LOOKUP_TABLE_N_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.043 |
| LSN | 0x00006c07000005580005 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 115. DELETE dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.070 |
| LSN | 0x00006c07000005b80006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 116. INSERT dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.130 |
| LSN | 0x00006c07000005d00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 117. INSERT dbo.LOOKUP_TABLE_N_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.577 |
| LSN | 0x00006c07000007d8000f |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_CLINICAL_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 118. INSERT dbo.L_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.603 |
| LSN | 0x00006c07000008500005 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_CLINICAL_KEY | 3.0 |
| PAGE_CASE_UID | 10009300.0 |

## 119. INSERT dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.670 |
| LSN | 0x00006c07000008700019 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 120. INSERT dbo.LOOKUP_TABLE_N_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.773 |
| LSN | 0x00006c0700000a88000f |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 121. INSERT dbo.L_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.793 |
| LSN | 0x00006c0700000af00005 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| PAGE_CASE_UID | 10009300.0 |

## 122. INSERT dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.810 |
| LSN | 0x00006c0700000b10000a |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 123. DELETE dbo.LOOKUP_TABLE_N_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.900 |
| LSN | 0x00006c0700000cd00005 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 124. DELETE dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.927 |
| LSN | 0x00006c08000000400008 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 125. INSERT dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:39:43.937 |
| LSN | 0x00006c0800000058000b |

### Inserted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 126. DELETE dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=217, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=3, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=1, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T19:40:51.817 |
| LSN | 0x00006c0900000be00009 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 217 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 3 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 1 |
| RPT_SRC_ORG_KEY | 4 |

## 127. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=3, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T19:40:51.817 |
| LSN | 0x00006c0900000be00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 3 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 128. UPDATE dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:40:51.877 |
| LSN | 0x00006c0900000c100011 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:32:20.4066667" | "2026-04-30T19:40:51.8700000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:20.4066667" |
| d_case_management_key | 2 |
| public_health_case_uid | 10009300 |
| updated_dttm | "2026-04-30T19:40:51.8700000" |

## 129. DELETE dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:40:52.060 |
| LSN | 0x00006c0900000c500008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 217 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 1 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 1 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 1 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 1 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 1 |
| D_INV_SOCIAL_HISTORY_KEY | 1 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 1 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 1 |
| INIT_ASGNED_INTERVIEWER_KEY | 1 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 3 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 1 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 1 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 130. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:40:52.060 |
| LSN | 0x00006c0900000c500008 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 1 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 1 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 1 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 1 |
| D_INV_SOCIAL_HISTORY_KEY | 1 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 1 |
| INIT_ASGNED_INTERVIEWER_KEY | 1 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 3 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 1 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 1 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 131. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:40:52.143 |
| LSN | 0x00006c0900000c700009 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "700" |
| CONDITION_DESC_TXT | "Syphilis, Unknown" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:32:00.637" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:32:00.637" |

## 132. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:40:52.143 |
| LSN | 0x00006c0900000c700009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:39:22.743" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:39:22.743" |

## 133. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:40:52.153 |
| LSN | 0x00006c0900000c800009 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "700" |
| CONDITION_DESC_TXT | "Syphilis, Unknown" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:32:00.637" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:32:00.637" |

## 134. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:40:52.153 |
| LSN | 0x00006c0900000c800009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:39:22.743" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:39:22.743" |

## 135. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:40:52.437 |
| LSN | 0x00006c0900000d200006 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CASE_STATUS | null | "Confirmed" |
| CONFIRMATION_DT | null | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD | null | "Laboratory confirmed" |
| DIAGNOSIS_DATE | null | "2026-04-21T00:00:00" |
| DISEASE | "Syphilis, Unknown" | "Syphilis, secondary" |
| DISEASE_CD | "700" | "10312" |
| ILLNESS_ONSET_DATE | null | "2026-04-17T00:00:00" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:32:00.637" | "2026-04-30T19:39:22.743" |

### Row After Change

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD | "Laboratory confirmed" |
| CURR_PROCESS_STATE | "Surveillance Follow-up" |
| DIAGNOSIS_DATE | "2026-04-21T00:00:00" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-24T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" |
| ILLNESS_ONSET_DATE | "2026-04-17T00:00:00" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:39:22.743" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Open" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 136. UPDATE dbo.STD_HIV_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:41:52.953 |
| LSN | 0x00006c0b000005400004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CONDITION_CD | "700" | "10312" |
| CONDITION_KEY | 217 | 44 |
| CONFIRMATION_DT | null | "2026-04-24T00:00:00" |
| DETECTION_METHOD_DESC_TXT | null | "Self-referral" |
| DIAGNOSIS | null | "720 - Syphilis, secondary" |
| DIAGNOSIS_CD | null | "720" |
| HSPTLIZD_IND | null | "No" |
| INV_CASE_STATUS | null | "Confirmed" |
| PATIENT_AGE_AT_ONSET | null | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | null | "Years" |
| REPORTING_PROV_KEY | 1 | 6 |
| TRT_TREATMENT_DATE | null | "2026-04-20" |

### Row After Change

| Field | Value |
| --- | --- |
| CALC_5_YEAR_AGE_GROUP | " 9" |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| COINFECTION_ID | "COIN1000XX01" |
| CONDITION_CD | "10312" |
| CONDITION_KEY | 44 |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CURR_PROCESS_STATE | "Surveillance Follow-up" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS | "720 - Syphilis, secondary" |
| DIAGNOSIS_CD | "720" |
| EPI_LINK_ID | "1310000026" |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| FIELD_RECORD_NUMBER | "1310000026" |
| HOSPITAL_KEY | 1 |
| HSPTLIZD_IND | "No" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_STATUS | "Open" |
| INVESTIGATOR_CLOSED_KEY | 1 |
| INVESTIGATOR_CURRENT_KEY | 3 |
| INVESTIGATOR_CURRENT_QC | "2" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 1 |
| INVESTIGATOR_FL_FUP_KEY | 1 |
| INVESTIGATOR_INITIAL_KEY | 3 |
| INVESTIGATOR_INITIAL_QC | "2" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 1 |
| INVESTIGATOR_INIT_INTRVW_KEY | 1 |
| INVESTIGATOR_INTERVIEW_KEY | 1 |
| INVESTIGATOR_SUPER_CASE_KEY | 1 |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 1 |
| INVESTIGATOR_SURV_KEY | 3 |
| INVESTIGATOR_SURV_QC | "2" |
| INV_CASE_STATUS | "Confirmed" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| ORDERING_FACILITY_KEY | 1 |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_AGE_REPORTED | "          41 Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_NAME | "Swift_fake77gg, Taylor" |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_PREGNANT_IND | "Yes" |
| PATIENT_RACE | "White" |
| PATIENT_SEX | "Female" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| PHYSICIAN_FL_FUP_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| REFERRAL_BASIS | "T1 - Positive Test" |
| REPORTING_ORG_KEY | 4 |
| REPORTING_PROV_KEY | 6 |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24T00:00:00" |
| TRT_TREATMENT_DATE | "2026-04-20" |

## 137. DELETE dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:41:53.357 |
| LSN | 0x00006c0b00000620000a |

### Deleted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| DISEASE | "Syphilis, Unknown" |
| DISEASE_CD | "700" |
| EVENT_DATE | "2026-04-24T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:32:00.637" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 138. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:41:53.357 |
| LSN | 0x00006c0b00000620000a |

### Inserted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:39:22.743" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 139. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:44:46.597 |
| LSN | 0x00006c0b000007b80016 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577968211 | 1777578286282 |
| refresh_datetime | "2026-04-30T19:39:28.6773703" | "2026-04-30T19:44:46.5935063" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777578286282 |
| branch_id | 10009292 |
| branch_type_cd | "APND" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:44:46.5935063" |
| root_type_cd | "LabReport" |

## 140. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:44:46.597 |
| LSN | 0x00006c0b000007b80016 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577968211 | 1777578286282 |
| refresh_datetime | "2026-04-30T19:39:28.6773703" | "2026-04-30T19:44:46.5935063" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777578286282 |
| branch_id | 10009294 |
| branch_type_cd | "COMP" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:44:46.5935063" |
| root_type_cd | "LabReport" |

## 141. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:46.620 |
| LSN | 0x00006c0b000007d00004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577968211 | 1777578286282 |
| last_chg_time | "2026-04-30T19:39:22.743" | "2026-04-30T19:44:42.917" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" | "2026-04-30T19:44:46.6095730" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578286282 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:44:42.917" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3241 |
| nbs_question_uid | 10001013 |
| nbs_rdb_metadata_uid | 10062226 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012401 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NOT120" |
| question_label | "Immediate National Notifiable Condition" |
| rdb_column_nm | "ADM_IMM_NTNL_NTFBL_CNDTN" |
| rdb_table_nm | "D_INV_ADMINISTRATIVE" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:44:46.6095730" |
| seq_nbr | 0 |

## 142. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:46.620 |
| LSN | 0x00006c0b000007d00004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577968211 | 1777578286282 |
| last_chg_time | "2026-04-30T19:39:22.743" | "2026-04-30T19:44:42.917" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" | "2026-04-30T19:44:46.6095730" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/20/2026" |
| batch_id | 1777578286282 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:44:42.917" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3243 |
| nbs_question_uid | 10001192 |
| nbs_rdb_metadata_uid | 10062178 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012367 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD105" |
| question_label | "Treatment Start Date" |
| rdb_column_nm | "TRT_TREATMENT_DATE" |
| rdb_table_nm | "D_INV_TREATMENT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:44:46.6095730" |
| seq_nbr | 0 |

## 143. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:44:46.620 |
| LSN | 0x00006c0b000007d00004 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777578286282 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:44:46.6095730" |
| root_type_cd | "TreatmentToPHC" |

## 144. UPDATE dbo.nrt_investigation_confirmation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:44:46.620 |
| LSN | 0x00006c0b000007d00004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577968211 | 1777578286282 |
| refresh_datetime | "2026-04-30T19:39:28.6875516" | "2026-04-30T19:44:46.6095730" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777578286282 |
| confirmation_method_cd | "LD" |
| confirmation_method_desc_txt | "Laboratory confirmed" |
| confirmation_method_time | "2026-04-24T00:00:00" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:44:46.6095730" |

## 145. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:46.670 |
| LSN | 0x00006c0b000007f00002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577968211 | 1777578286282 |
| last_chg_time | "2026-04-30T19:39:22.743" | "2026-04-30T19:44:42.917" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" | "2026-04-30T19:44:46.6235256" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "720" |
| batch_id | 1777578286282 |
| code_set_group_id | 105450 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:44:42.917" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3244 |
| nbs_question_uid | 10001195 |
| nbs_rdb_metadata_uid | 10062221 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012398 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS136" |
| question_label | "Diagnosis Reported to CDC" |
| rdb_column_nm | "CLN_CASE_DIAGNOSIS" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:44:46.6235256" |
| seq_nbr | 0 |

## 146. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:46.670 |
| LSN | 0x00006c0b000007f00002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577968211 | 1777578286282 |
| last_chg_time | "2026-04-30T19:39:22.743" | "2026-04-30T19:44:42.917" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" | "2026-04-30T19:44:46.6235256" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "30" |
| batch_id | 1777578286282 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:44:42.917" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3242 |
| nbs_question_uid | 10001252 |
| nbs_rdb_metadata_uid | 10062300 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012499 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS128" |
| question_label | "Weeks" |
| rdb_column_nm | "PBI_PATIENT_PREGNANT_WKS" |
| rdb_table_nm | "D_INV_PREGNANCY_BIRTH" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:44:46.6235256" |
| seq_nbr | 0 |

## 147. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001000GA01", public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:44:46.670 |
| LSN | 0x00006c0b000007f00002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777577968211 | 1777578286282 |
| curr_process_state | "Surveillance Follow-up" | "Awaiting Interview" |
| curr_process_state_cd | "SF" | "AI" |
| dispo_fld_fupinvestgr_of_phc_uid | null | 10003004 |
| fld_fup_investgr_of_phc_uid | null | 10003013 |
| fld_fup_supervisor_of_phc_uid | null | 10003004 |
| init_fld_fup_investgr_of_phc_uid | null | 10003013 |
| init_interviewer_of_phc_uid | null | 10003004 |
| interviewer_of_phc_uid | null | 10003004 |
| investigator_id | 10003010 | 10003004 |
| last_chg_time | "2026-04-30T19:39:22.743" | "2026-04-30T19:44:42.917" |
| nac_last_chg_time | "2026-04-30T19:39:22.743" | "2026-04-30T19:44:42.917" |
| rdb_table_name_list | null | "D_INV_PREGNANCY_BIRTH,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_ADMINISTRATIVE" |
| record_status_time | "2026-04-30T19:39:22.743" | "2026-04-30T19:44:42.917" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" | "2026-04-30T19:44:46.6235256" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-24T00:00:00" |
| add_time | "2026-04-30T19:32:00.637" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777578286282 |
| case_class_cd | "C" |
| case_count | 1 |
| case_management_uid | 1000 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| city_county_case_nbr | "" |
| class_cd | "CASE" |
| coinfection_id | "COIN1000XX01" |
| curr_process_state | "Awaiting Interview" |
| curr_process_state_cd | "AI" |
| detection_method_cd | "21" |
| detection_method_desc_txt | "Self-referral" |
| diagnosis_time | "2026-04-21T00:00:00" |
| dispo_fld_fupinvestgr_of_phc_uid | 10003004 |
| effective_from_time | "2026-04-17T00:00:00" |
| fld_fup_investgr_of_phc_uid | 10003013 |
| fld_fup_supervisor_of_phc_uid | 10003004 |
| hospitalized_ind | "No" |
| hospitalized_ind_cd | "N" |
| init_fld_fup_investgr_of_phc_uid | 10003013 |
| init_fup_investgr_of_phc_uid | 10003010 |
| init_interviewer_of_phc_uid | 10003004 |
| interviewer_of_phc_uid | 10003004 |
| inv_case_status | "Confirmed" |
| inv_state_case_id | "" |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Open" |
| investigation_status_cd | "O" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T19:44:42.917" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| legacy_case_id | "" |
| local_id | "CAS10001000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "17" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:32:00.637" |
| nac_last_chg_time | "2026-04-30T19:44:42.917" |
| nac_page_case_uid | 10009300 |
| org_as_reporter_uid | 10003019 |
| organization_id | 10003019 |
| pat_age_at_onset | "41" |
| pat_age_at_onset_unit | "Years" |
| pat_age_at_onset_unit_cd | "Y" |
| patient_id | 10009296 |
| person_as_reporter_uid | 10003022 |
| pregnant_ind | "Yes" |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_ADMINISTRATIVE" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T19:44:42.917" |
| referral_basis | "T1 - Positive Test" |
| referral_basis_cd | "T1" |
| refresh_datetime | "2026-04-30T19:44:46.6235256" |
| rpt_form_cmplt_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| surv_investgr_of_phc_uid | 10003010 |
| transmission_mode | "Sexually Transmitted" |
| transmission_mode_cd | "S" |

## 148. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:44:46.670 |
| LSN | 0x00006c0b000007f00002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| ca_init_intvwr_assgn_dt | null | "2026-04-25T00:00:00" |
| ca_interviewer_assign_dt | null | "2026-04-25T00:00:00" |
| ca_patient_intv_status | null | "A - Awaiting" |
| fl_fup_dispo_dt | null | "2026-04-25T00:00:00" |
| fl_fup_disposition_cd | null | "C" |
| fl_fup_disposition_desc | null | "C - Infected, Brought to Treatment" |
| fl_fup_init_assgn_dt | null | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | null | "2026-04-25T00:00:00" |
| fl_fup_notification_plan_cd | null | "3 - Dual" |
| fld_foll_up_notification_plan | null | "3" |
| init_foll_up_notifiable | null | "6-Yes, Notifiable" |
| init_fup_notifiable_cd | null | "06" |
| pat_intv_status_cd | null | "A" |
| refresh_datetime | "2026-04-30T19:39:28.7074060" | "2026-04-30T19:44:46.6235256" |
| surv_patient_foll_up | null | "FF" |
| surv_patient_foll_up_cd | null | "Field Follow-up" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| ca_init_intvwr_assgn_dt | "2026-04-25T00:00:00" |
| ca_interviewer_assign_dt | "2026-04-25T00:00:00" |
| ca_patient_intv_status | "A - Awaiting" |
| case_management_uid | 1000 |
| case_oid | 1300100015 |
| epi_link_id | "1310000026" |
| fl_fup_dispo_dt | "2026-04-25T00:00:00" |
| fl_fup_disposition_cd | "C" |
| fl_fup_disposition_desc | "C - Infected, Brought to Treatment" |
| fl_fup_field_record_num | "1310000026" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_notification_plan_cd | "3 - Dual" |
| fld_foll_up_notification_plan | "3" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Surveillance Follow-up" |
| init_fup_initial_foll_up_cd | "SF" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| pat_intv_status_cd | "A" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:44:46.6235256" |
| surv_investigator_assgn_dt | "2026-04-24T00:00:00" |
| surv_patient_foll_up | "FF" |
| surv_patient_foll_up_cd | "Field Follow-up" |

## 149. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:44:46.687 |
| LSN | 0x00006c0b000007f80003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:39:22.713" | "2026-04-30T19:44:42.890" |
| refresh_datetime | "2026-04-30T19:39:28.7705331" | "2026-04-30T19:44:46.6845323" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:44:42.890" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:44:46.6845323" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 150. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:44:46.690 |
| LSN | 0x00006c0b000008080003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:39:22.727" | "2026-04-30T19:44:42.900" |
| refresh_datetime | "2026-04-30T19:39:28.8864534" | "2026-04-30T19:44:46.6899770" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:32:00.600" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| age_reported | 41 |
| age_reported_unit | "Years" |
| age_reported_unit_cd | "Y" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:44:42.900" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009296 |
| phone_ext_home | "" |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:44:46.6899770" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| street_address_2 | "" |
| zip | "30033" |

## 151. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T19:44:52.367 |
| LSN | 0x00006c0b000008780037 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:39:41.9400000" | "2026-04-30T19:44:52.2700000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T19:44:52.2700000" |

## 152. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=6 |
| Transaction end | 2026-04-30T19:44:52.367 |
| LSN | 0x00006c0b000008780037 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:39:41.9400000" | "2026-04-30T19:44:52.2700000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:18.7866667" |
| d_patient_key | 6 |
| patient_uid | 10009296 |
| updated_dttm | "2026-04-30T19:44:52.2700000" |

## 153. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:44:52.367 |
| LSN | 0x00006c0b000008780037 |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:39:22.713" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 154. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:44:52.367 |
| LSN | 0x00006c0b000008780037 |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:44:42.890" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 155. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:44:52.367 |
| LSN | 0x00006c0b000008780037 |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:39:22.727" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 156. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:44:52.367 |
| LSN | 0x00006c0b000008780037 |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:44:42.900" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 157. UPDATE dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=3 |
| Transaction end | 2026-04-30T19:44:52.730 |
| LSN | 0x00006c0b000009a0000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:39:42.4000000" | "2026-04-30T19:44:52.7100000" |

### Row After Change

| Field | Value |
| --- | --- |
| case_uid | 10009300 |
| created_dttm | "2026-04-30T19:32:19.1500000" |
| d_investigation_key | 3 |
| updated_dttm | "2026-04-30T19:44:52.7100000" |

## 158. DELETE dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:44:52.730 |
| LSN | 0x00006c0b000009a0000c |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Surveillance Follow-up" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_CASE_STATUS | "Confirmed" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:39:22.743" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 159. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:44:52.730 |
| LSN | 0x00006c0b000009a0000c |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Awaiting Interview" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_CASE_STATUS | "Confirmed" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:44:42.917" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 160. UPDATE dbo.nrt_confirmation_method_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:52.760 |
| LSN | 0x00006c0b000009b0000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:39:42.4533333" | "2026-04-30T19:44:52.7433333" |

### Row After Change

| Field | Value |
| --- | --- |
| confirmation_method_cd | "LD" |
| created_dttm | "2026-04-30T19:39:42.4533333" |
| d_confirmation_method_key | 4 |
| updated_dttm | "2026-04-30T19:44:52.7433333" |

## 161. DELETE dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T19:44:52.760 |
| LSN | 0x00006c0b000009b0000c |

### Deleted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 162. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T19:44:52.760 |
| LSN | 0x00006c0b000009b0000c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 163. DELETE dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:53.253 |
| LSN | 0x00006c0b00000bb80006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 164. INSERT dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:53.327 |
| LSN | 0x00006c0b00000bd00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 165. DELETE dbo.LOOKUP_TABLE_N_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:53.820 |
| LSN | 0x00006c0b00000d780005 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_CLINICAL_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 166. DELETE dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:53.847 |
| LSN | 0x00006c0b00000dd80008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 167. INSERT dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:53.907 |
| LSN | 0x00006c0b00000df0000b |

### Inserted Row

| Field | Value |
| --- | --- |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 168. DELETE dbo.LOOKUP_TABLE_N_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:54.003 |
| LSN | 0x00006c0b00000f980005 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 169. DELETE dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:54.030 |
| LSN | 0x00006c0b00000ff80006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 170. INSERT dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:54.040 |
| LSN | 0x00006c0b000010100009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 171. DELETE dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:54.173 |
| LSN | 0x00006c0b000012180008 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 172. INSERT dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:44:54.183 |
| LSN | 0x00006c0b00001230000b |

### Inserted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 173. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T19:46:08.213 |
| LSN | 0x00006c0b000012f8000a |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 174. DELETE dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=3, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T19:46:08.213 |
| LSN | 0x00006c0b000012f8000a |

### Deleted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 3 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 175. UPDATE dbo.D_CASE_MANAGEMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:46:08.267 |
| LSN | 0x00006c0c000000280007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CA_INIT_INTVWR_ASSGN_DT | null | "2026-04-25" |
| CA_INTERVIEWER_ASSIGN_DT | null | "2026-04-25" |
| CA_PATIENT_INTV_STATUS | null | "A - Awaiting" |
| FLD_FOLL_UP_NOTIFICATION_PLAN | null | "3" |
| FL_FUP_DISPOSITION_CD | null | "C" |
| FL_FUP_DISPOSITION_DESC | null | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | null | "2026-04-25" |
| FL_FUP_INIT_ASSGN_DT | null | "2026-04-25" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | null | "2026-04-25" |
| FL_FUP_NOTIFICATION_PLAN_CD | null | "3 - Dual" |
| INIT_FOLL_UP_NOTIFIABLE | null | "6-Yes, Notifiable" |
| INIT_FUP_NOTIFIABLE_CD | null | "06" |
| PAT_INTV_STATUS_CD | null | "A" |
| SURV_PATIENT_FOLL_UP | null | "FF" |
| SURV_PATIENT_FOLL_UP_CD | null | "Field Follow-up" |

### Row After Change

| Field | Value |
| --- | --- |
| ADD_USER_ID | 10009282.0 |
| CASE_OID | 1300100015.0 |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25" |
| CA_PATIENT_INTV_STATUS | "A - Awaiting" |
| D_CASE_MANAGEMENT_KEY | 2.0 |
| EPI_LINK_ID | "1310000026" |
| FLD_FOLL_UP_NOTIFICATION_PLAN | "3" |
| FL_FUP_DISPOSITION_CD | "C" |
| FL_FUP_DISPOSITION_DESC | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25" |
| FL_FUP_FIELD_RECORD_NUM | "1310000026" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25" |
| FL_FUP_NOTIFICATION_PLAN_CD | "3 - Dual" |
| INIT_FOLL_UP_NOTIFIABLE | "6-Yes, Notifiable" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE_CD | "06" |
| INVESTIGATION_KEY | 3.0 |
| PAT_INTV_STATUS_CD | "A" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24" |
| SURV_PATIENT_FOLL_UP | "FF" |
| SURV_PATIENT_FOLL_UP_CD | "Field Follow-up" |

## 176. UPDATE dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:46:08.267 |
| LSN | 0x00006c0c000000280007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:40:51.8700000" | "2026-04-30T19:46:08.2600000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:20.4066667" |
| d_case_management_key | 2 |
| public_health_case_uid | 10009300 |
| updated_dttm | "2026-04-30T19:46:08.2600000" |

## 177. DELETE dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:46:08.397 |
| LSN | 0x00006c0c000000680008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 1 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 1 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 1 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 1 |
| D_INV_SOCIAL_HISTORY_KEY | 1 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 1 |
| INIT_ASGNED_INTERVIEWER_KEY | 1 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 3 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 1 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 1 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 178. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:46:08.397 |
| LSN | 0x00006c0c000000680008 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 1 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 1 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 1 |
| D_INV_SOCIAL_HISTORY_KEY | 1 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 179. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:46:08.470 |
| LSN | 0x00006c0c00000088000a |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:39:22.743" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:39:22.743" |

## 180. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:46:08.470 |
| LSN | 0x00006c0c00000088000a |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:44:42.917" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:44:42.917" |

## 181. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:46:08.477 |
| LSN | 0x00006c0c00000098000a |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:39:22.743" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:39:22.743" |

## 182. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:46:08.477 |
| LSN | 0x00006c0c00000098000a |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:44:42.917" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:44:42.917" |

## 183. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:46:08.690 |
| LSN | 0x00006c0c000001380004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CURR_PROCESS_STATE | "Surveillance Follow-up" | "Awaiting Interview" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:39:22.743" | "2026-04-30T19:44:42.917" |

### Row After Change

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD | "Laboratory confirmed" |
| CURR_PROCESS_STATE | "Awaiting Interview" |
| DIAGNOSIS_DATE | "2026-04-21T00:00:00" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-24T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" |
| ILLNESS_ONSET_DATE | "2026-04-17T00:00:00" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:44:42.917" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Open" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 184. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:46:08.757 |
| LSN | 0x00006c0c000001500004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| EVENT_DATE | "2026-04-24T00:00:00" | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" | "Illness Onset Date" |

### Row After Change

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD | "Laboratory confirmed" |
| CURR_PROCESS_STATE | "Awaiting Interview" |
| DIAGNOSIS_DATE | "2026-04-21T00:00:00" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| ILLNESS_ONSET_DATE | "2026-04-17T00:00:00" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:44:42.917" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Open" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 185. UPDATE dbo.STD_HIV_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:47:09.183 |
| LSN | 0x00006c0c000010100004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CA_INIT_INTVWR_ASSGN_DT | null | "2026-04-25T00:00:00" |
| CA_INTERVIEWER_ASSIGN_DT | null | "2026-04-25T00:00:00" |
| CA_PATIENT_INTV_STATUS | null | "A - Awaiting" |
| CURR_PROCESS_STATE | "Surveillance Follow-up" | "Awaiting Interview" |
| FL_FUP_DISPOSITION | null | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | null | "2026-04-25T00:00:00" |
| FL_FUP_INIT_ASSGN_DT | null | "2026-04-25T00:00:00" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | null | "2026-04-25T00:00:00" |
| FL_FUP_NOTIFICATION_PLAN | null | "3 - Dual" |
| INIT_FUP_NOTIFIABLE | null | "06" |
| INVESTIGATOR_CURRENT_KEY | 3 | 2 |
| INVESTIGATOR_CURRENT_QC | "2" | "1" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 1 | 2 |
| INVESTIGATOR_DISP_FL_FUP_QC | null | "1" |
| INVESTIGATOR_FL_FUP_KEY | 1 | 4 |
| INVESTIGATOR_FL_FUP_QC | null | "3" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 1 | 4 |
| INVESTIGATOR_INIT_FL_FUP_QC | null | "3" |
| INVESTIGATOR_INIT_INTRVW_KEY | 1 | 2 |
| INVESTIGATOR_INIT_INTRVW_QC | null | "1" |
| INVESTIGATOR_INTERVIEW_KEY | 1 | 2 |
| INVESTIGATOR_INTERVIEW_QC | null | "1" |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 1 | 2 |
| INVESTIGATOR_SUPER_FL_FUP_QC | null | "1" |
| SURV_PATIENT_FOLL_UP | null | "Field Follow-up" |

### Row After Change

| Field | Value |
| --- | --- |
| CALC_5_YEAR_AGE_GROUP | " 9" |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25T00:00:00" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25T00:00:00" |
| CA_PATIENT_INTV_STATUS | "A - Awaiting" |
| COINFECTION_ID | "COIN1000XX01" |
| CONDITION_CD | "10312" |
| CONDITION_KEY | 44 |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CURR_PROCESS_STATE | "Awaiting Interview" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS | "720 - Syphilis, secondary" |
| DIAGNOSIS_CD | "720" |
| EPI_LINK_ID | "1310000026" |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| FIELD_RECORD_NUMBER | "1310000026" |
| FL_FUP_DISPOSITION | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25T00:00:00" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_NOTIFICATION_PLAN | "3 - Dual" |
| HOSPITAL_KEY | 1 |
| HSPTLIZD_IND | "No" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE | "06" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_STATUS | "Open" |
| INVESTIGATOR_CLOSED_KEY | 1 |
| INVESTIGATOR_CURRENT_KEY | 2 |
| INVESTIGATOR_CURRENT_QC | "1" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 2 |
| INVESTIGATOR_DISP_FL_FUP_QC | "1" |
| INVESTIGATOR_FL_FUP_KEY | 4 |
| INVESTIGATOR_FL_FUP_QC | "3" |
| INVESTIGATOR_INITIAL_KEY | 3 |
| INVESTIGATOR_INITIAL_QC | "2" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 4 |
| INVESTIGATOR_INIT_FL_FUP_QC | "3" |
| INVESTIGATOR_INIT_INTRVW_KEY | 2 |
| INVESTIGATOR_INIT_INTRVW_QC | "1" |
| INVESTIGATOR_INTERVIEW_KEY | 2 |
| INVESTIGATOR_INTERVIEW_QC | "1" |
| INVESTIGATOR_SUPER_CASE_KEY | 1 |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 2 |
| INVESTIGATOR_SUPER_FL_FUP_QC | "1" |
| INVESTIGATOR_SURV_KEY | 3 |
| INVESTIGATOR_SURV_QC | "2" |
| INV_CASE_STATUS | "Confirmed" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| ORDERING_FACILITY_KEY | 1 |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_AGE_REPORTED | "          41 Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_NAME | "Swift_fake77gg, Taylor" |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_PREGNANT_IND | "Yes" |
| PATIENT_RACE | "White" |
| PATIENT_SEX | "Female" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| PHYSICIAN_FL_FUP_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| REFERRAL_BASIS | "T1 - Positive Test" |
| REPORTING_ORG_KEY | 4 |
| REPORTING_PROV_KEY | 6 |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24T00:00:00" |
| SURV_PATIENT_FOLL_UP | "Field Follow-up" |
| TRT_TREATMENT_DATE | "2026-04-20" |

## 186. DELETE dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:47:09.607 |
| LSN | 0x00006c0c000010f0000a |

### Deleted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:39:22.743" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 187. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:47:09.607 |
| LSN | 0x00006c0c000010f0000a |

### Inserted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:44:42.917" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 188. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:50:55.240 |
| LSN | 0x00006c0c000012980003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:44:42.890" | "2026-04-30T19:50:49.297" |
| refresh_datetime | "2026-04-30T19:44:46.6845323" | "2026-04-30T19:50:55.2386534" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:50:49.297" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:50:55.2386534" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 189. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:50:55.330 |
| LSN | 0x00006c0c000012d00005 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578286282 | 1777578654713 |
| refresh_datetime | "2026-04-30T19:44:46.5935063" | "2026-04-30T19:50:55.3316467" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777578654713 |
| branch_id | 10009292 |
| branch_type_cd | "APND" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:50:55.3316467" |
| root_type_cd | "LabReport" |

## 190. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:50:55.330 |
| LSN | 0x00006c0c000012d00005 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578286282 | 1777578654713 |
| refresh_datetime | "2026-04-30T19:44:46.5935063" | "2026-04-30T19:50:55.3316467" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777578654713 |
| branch_id | 10009294 |
| branch_type_cd | "COMP" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:50:55.3316467" |
| root_type_cd | "LabReport" |

## 191. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.357 |
| LSN | 0x00006c0c000012d8000b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578286282 | 1777578654713 |
| last_chg_time | "2026-04-30T19:44:42.917" | "2026-04-30T19:50:49.327" |
| refresh_datetime | "2026-04-30T19:44:46.6095730" | "2026-04-30T19:50:55.3458259" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3241 |
| nbs_question_uid | 10001013 |
| nbs_rdb_metadata_uid | 10062226 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012401 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NOT120" |
| question_label | "Immediate National Notifiable Condition" |
| rdb_column_nm | "ADM_IMM_NTNL_NTFBL_CNDTN" |
| rdb_table_nm | "D_INV_ADMINISTRATIVE" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3458259" |
| seq_nbr | 0 |

## 192. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:50:55.357 |
| LSN | 0x00006c0c000012d8000b |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777578654713 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:50:55.3458259" |
| root_type_cd | "TreatmentToPHC" |

## 193. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:50:55.357 |
| LSN | 0x00006c0c000012d8000b |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777578654713 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:50:55.3458259" |
| root_type_cd | "IXS" |

## 194. UPDATE dbo.nrt_investigation_confirmation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:50:55.357 |
| LSN | 0x00006c0c000012d8000b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578286282 | 1777578654713 |
| refresh_datetime | "2026-04-30T19:44:46.6095730" | "2026-04-30T19:50:55.3458259" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777578654713 |
| confirmation_method_cd | "LD" |
| confirmation_method_desc_txt | "Laboratory confirmed" |
| confirmation_method_time | "2026-04-24T00:00:00" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:50:55.3458259" |

## 195. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578286282 | 1777578654713 |
| last_chg_time | "2026-04-30T19:44:42.917" | "2026-04-30T19:50:49.327" |
| refresh_datetime | "2026-04-30T19:44:46.6095730" | "2026-04-30T19:50:55.3718440" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/20/2026" |
| batch_id | 1777578654713 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3243 |
| nbs_question_uid | 10001192 |
| nbs_rdb_metadata_uid | 10062178 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012367 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD105" |
| question_label | "Treatment Start Date" |
| rdb_column_nm | "TRT_TREATMENT_DATE" |
| rdb_table_nm | "D_INV_TREATMENT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 196. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578286282 | 1777578654713 |
| last_chg_time | "2026-04-30T19:44:42.917" | "2026-04-30T19:50:49.327" |
| refresh_datetime | "2026-04-30T19:44:46.6235256" | "2026-04-30T19:50:55.3718440" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "720" |
| batch_id | 1777578654713 |
| code_set_group_id | 105450 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3244 |
| nbs_question_uid | 10001195 |
| nbs_rdb_metadata_uid | 10062221 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012398 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS136" |
| question_label | "Diagnosis Reported to CDC" |
| rdb_column_nm | "CLN_CASE_DIAGNOSIS" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 197. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578286282 | 1777578654713 |
| last_chg_time | "2026-04-30T19:44:42.917" | "2026-04-30T19:50:49.327" |
| refresh_datetime | "2026-04-30T19:44:46.6235256" | "2026-04-30T19:50:55.3718440" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "30" |
| batch_id | 1777578654713 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3242 |
| nbs_question_uid | 10001252 |
| nbs_rdb_metadata_uid | 10062300 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012499 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS128" |
| question_label | "Weeks" |
| rdb_column_nm | "PBI_PATIENT_PREGNANT_WKS" |
| rdb_table_nm | "D_INV_PREGNANCY_BIRTH" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 198. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3250 |
| nbs_question_uid | 10001283 |
| nbs_rdb_metadata_uid | 10062358 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012545 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS242" |
| question_label | "Places to Meet Partners" |
| rdb_column_nm | "SOC_PLACES_TO_MEET_PARTNER" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 199. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "R" |
| batch_id | 1777578654713 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3248 |
| nbs_question_uid | 10001285 |
| nbs_rdb_metadata_uid | 10062360 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012549 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS244" |
| question_label | "Places to Have Sex" |
| rdb_column_nm | "SOC_PLACES_TO_HAVE_SEX" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 200. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777578654713 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3255 |
| nbs_question_uid | 10001287 |
| nbs_rdb_metadata_uid | 10062362 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012554 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS223" |
| question_label | "Female Partners (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 201. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777578654713 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3257 |
| nbs_question_uid | 10001288 |
| nbs_rdb_metadata_uid | 10062363 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012555 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS224" |
| question_label | "Number Female (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 202. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777578654713 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3251 |
| nbs_question_uid | 10001289 |
| nbs_rdb_metadata_uid | 10062364 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012556 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS225" |
| question_label | "Male Partners (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 203. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "5" |
| batch_id | 1777578654713 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3252 |
| nbs_question_uid | 10001290 |
| nbs_rdb_metadata_uid | 10062365 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012557 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS226" |
| question_label | "Number Male (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_TOTAL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 204. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3260 |
| nbs_question_uid | 10001291 |
| nbs_rdb_metadata_uid | 10062366 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012558 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS227" |
| question_label | "Transgender Partners (Past Year)" |
| rdb_column_nm | "SOC_TRANSGNDR_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 205. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "7" |
| batch_id | 1777578654713 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3263 |
| nbs_question_uid | 10001293 |
| nbs_rdb_metadata_uid | 10062368 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012560 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD120" |
| question_label | "Total number of sex partners last 12 months?" |
| rdb_column_nm | "RSK_NUM_SEX_PARTNER_12MO" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 206. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3268 |
| nbs_question_uid | 10001294 |
| nbs_rdb_metadata_uid | 10062370 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012561 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD888" |
| question_label | "Patient refused to answer questions regarding number of sex partners" |
| rdb_column_nm | "RSK_ANS_REFUSED_SEX_PARTNER" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 207. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3259 |
| nbs_question_uid | 10001295 |
| nbs_rdb_metadata_uid | 10062372 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012562 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD999" |
| question_label | "Unknown number of sex partners in last 12 months" |
| rdb_column_nm | "RSK_UNK_SEX_PARTNERS" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 208. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777578654713 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3261 |
| nbs_question_uid | 10001296 |
| nbs_rdb_metadata_uid | 10062374 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012564 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS129" |
| question_label | "Female Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 209. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777578654713 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3262 |
| nbs_question_uid | 10001297 |
| nbs_rdb_metadata_uid | 10062375 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012565 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS130" |
| question_label | "Number Female (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 210. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777578654713 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3266 |
| nbs_question_uid | 10001298 |
| nbs_rdb_metadata_uid | 10062376 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012566 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS131" |
| question_label | "Male Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 211. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777578654713 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3267 |
| nbs_question_uid | 10001299 |
| nbs_rdb_metadata_uid | 10062377 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012567 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS132" |
| question_label | "Number Male (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 212. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3264 |
| nbs_question_uid | 10001300 |
| nbs_rdb_metadata_uid | 10062378 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012568 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS133" |
| question_label | "Transgender Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_TRNSGNDR_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 213. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777578654713 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3258 |
| nbs_question_uid | 10001302 |
| nbs_rdb_metadata_uid | 10062380 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012571 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD119" |
| question_label | "Met Sex Partners through the Internet" |
| rdb_column_nm | "SOC_SX_PRTNRS_INTNT_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 214. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3254 |
| nbs_question_uid | 10001316 |
| nbs_rdb_metadata_uid | 10062440 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012614 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD117" |
| question_label | "Previous STD history (self-reported)?" |
| rdb_column_nm | "MDH_PREV_STD_HIST" |
| rdb_table_nm | "D_INV_MEDICAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 215. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777578654713 |
| code_set_group_id | 105500 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3269 |
| nbs_question_uid | 10001321 |
| nbs_rdb_metadata_uid | 10062446 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012622 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS257" |
| question_label | "Enrolled in Partner Services" |
| rdb_column_nm | "HIV_ENROLL_PRTNR_SRVCS_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 216. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3265 |
| nbs_question_uid | 10001322 |
| nbs_rdb_metadata_uid | 10062447 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012624 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS254" |
| question_label | "Previous 900 Test" |
| rdb_column_nm | "HIV_PREVIOUS_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 217. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777578654713 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3247 |
| nbs_question_uid | 10001325 |
| nbs_rdb_metadata_uid | 10062450 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012628 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS260" |
| question_label | "Refer for Test" |
| rdb_column_nm | "HIV_REFER_FOR_900_TEST" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 218. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/24/2026" |
| batch_id | 1777578654713 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3245 |
| nbs_question_uid | 10001326 |
| nbs_rdb_metadata_uid | 10062451 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012629 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS261" |
| question_label | "Referral Date" |
| rdb_column_nm | "HIV_900_TEST_REFERRAL_DT" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 219. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 107870 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3246 |
| nbs_question_uid | 10001327 |
| nbs_rdb_metadata_uid | 10062452 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012630 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS262" |
| question_label | "900 Test" |
| rdb_column_nm | "HIV_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 220. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3249 |
| nbs_question_uid | 10001331 |
| nbs_rdb_metadata_uid | 10062459 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012638 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS266" |
| question_label | "Refer for Care" |
| rdb_column_nm | "HIV_REFER_FOR_900_CARE_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 221. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777578654713 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3256 |
| nbs_question_uid | 10003230 |
| nbs_rdb_metadata_uid | 10062462 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012642 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS443" |
| question_label | "Is the Client Currently On PrEP?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_IND" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 222. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:55.373 |
| LSN | 0x00006c0c000012e00074 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777578654713 |
| code_set_group_id | 107900 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3253 |
| nbs_question_uid | 10003231 |
| nbs_rdb_metadata_uid | 10062463 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012643 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS446" |
| question_label | "Has Client Been Referred to PrEP Provider?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_REFER" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" |
| seq_nbr | 0 |

## 223. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001000GA01", public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:50:55.413 |
| LSN | 0x00006c0c000013100004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578286282 | 1777578654713 |
| curr_process_state | "Awaiting Interview" | "Open Case" |
| curr_process_state_cd | "AI" | "OC" |
| last_chg_time | "2026-04-30T19:44:42.917" | "2026-04-30T19:50:49.327" |
| nac_last_chg_time | "2026-04-30T19:44:42.917" | "2026-04-30T19:50:49.327" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_ADMINISTRATIVE" | "D_INV_PREGNANCY_BIRTH,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_time | "2026-04-30T19:44:42.917" | "2026-04-30T19:50:49.327" |
| refresh_datetime | "2026-04-30T19:44:46.6235256" | "2026-04-30T19:50:55.3997377" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-24T00:00:00" |
| add_time | "2026-04-30T19:32:00.637" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777578654713 |
| case_class_cd | "C" |
| case_count | 1 |
| case_management_uid | 1000 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| city_county_case_nbr | "" |
| class_cd | "CASE" |
| coinfection_id | "COIN1000XX01" |
| curr_process_state | "Open Case" |
| curr_process_state_cd | "OC" |
| detection_method_cd | "21" |
| detection_method_desc_txt | "Self-referral" |
| diagnosis_time | "2026-04-21T00:00:00" |
| dispo_fld_fupinvestgr_of_phc_uid | 10003004 |
| effective_from_time | "2026-04-17T00:00:00" |
| fld_fup_investgr_of_phc_uid | 10003013 |
| fld_fup_supervisor_of_phc_uid | 10003004 |
| hospitalized_ind | "No" |
| hospitalized_ind_cd | "N" |
| init_fld_fup_investgr_of_phc_uid | 10003013 |
| init_fup_investgr_of_phc_uid | 10003010 |
| init_interviewer_of_phc_uid | 10003004 |
| interviewer_of_phc_uid | 10003004 |
| inv_case_status | "Confirmed" |
| inv_state_case_id | "" |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Open" |
| investigation_status_cd | "O" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T19:50:49.327" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| legacy_case_id | "" |
| local_id | "CAS10001000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "17" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:32:00.637" |
| nac_last_chg_time | "2026-04-30T19:50:49.327" |
| nac_page_case_uid | 10009300 |
| org_as_reporter_uid | 10003019 |
| organization_id | 10003019 |
| pat_age_at_onset | "41" |
| pat_age_at_onset_unit | "Years" |
| pat_age_at_onset_unit_cd | "Y" |
| patient_id | 10009296 |
| person_as_reporter_uid | 10003022 |
| pregnant_ind | "Yes" |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T19:50:49.327" |
| referral_basis | "T1 - Positive Test" |
| referral_basis_cd | "T1" |
| refresh_datetime | "2026-04-30T19:50:55.3997377" |
| rpt_form_cmplt_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| surv_investgr_of_phc_uid | 10003010 |
| transmission_mode | "Sexually Transmitted" |
| transmission_mode_cd | "S" |

## 224. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:50:55.413 |
| LSN | 0x00006c0c000013100004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| ca_patient_intv_status | "A - Awaiting" | "I - Interviewed" |
| pat_intv_status_cd | "A" | "I" |
| refresh_datetime | "2026-04-30T19:44:46.6235256" | "2026-04-30T19:50:55.3997377" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| ca_init_intvwr_assgn_dt | "2026-04-25T00:00:00" |
| ca_interviewer_assign_dt | "2026-04-25T00:00:00" |
| ca_patient_intv_status | "I - Interviewed" |
| case_management_uid | 1000 |
| case_oid | 1300100015 |
| epi_link_id | "1310000026" |
| fl_fup_dispo_dt | "2026-04-25T00:00:00" |
| fl_fup_disposition_cd | "C" |
| fl_fup_disposition_desc | "C - Infected, Brought to Treatment" |
| fl_fup_field_record_num | "1310000026" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_notification_plan_cd | "3 - Dual" |
| fld_foll_up_notification_plan | "3" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Surveillance Follow-up" |
| init_fup_initial_foll_up_cd | "SF" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| pat_intv_status_cd | "I" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T19:50:55.3997377" |
| surv_investigator_assgn_dt | "2026-04-24T00:00:00" |
| surv_patient_foll_up | "FF" |
| surv_patient_foll_up_cd | "Field Follow-up" |

## 225. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:50:55.483 |
| LSN | 0x00006c0c000013200005 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:44:42.900" | "2026-04-30T19:50:49.307" |
| refresh_datetime | "2026-04-30T19:44:46.6899770" | "2026-04-30T19:50:55.4841056" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:32:00.600" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| age_reported | 41 |
| age_reported_unit | "Years" |
| age_reported_unit_cd | "Y" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T19:50:49.307" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009296 |
| phone_ext_home | "" |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:50:55.4841056" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| street_address_2 | "" |
| zip | "30033" |

## 226. INSERT dbo.nrt_interview

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="INT10000000GA01" |
| Transaction end | 2026-04-30T19:50:56.430 |
| LSN | 0x00006c0c000014f0001a |

### Inserted Row

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:50:52.317" |
| add_user_id | 10009282 |
| batch_id | 1777578655211 |
| interview_date | "2026-04-24T00:00:00" |
| interview_loc_cd | "T" |
| interview_status_cd | "COMPLETE" |
| interview_type_cd | "INITIAL" |
| interview_uid | 10009302 |
| interviewee_role_cd | "SUBJECT" |
| investigation_uid | 10009300 |
| ix_interviewee_role | "Subject of Investigation" |
| ix_location | "Telephone" |
| ix_status | "Closed/Completed" |
| ix_type | "Initial/Original" |
| last_chg_time | "2026-04-30T19:50:52.317" |
| last_chg_user_id | 10009282 |
| local_id | "INT10000000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| patient_uid | 10009296 |
| provider_uid | 10003004 |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T19:50:52.317" |
| refresh_datetime | "2026-04-30T19:50:56.2167511" |
| version_ctrl_nbr | 1 |

## 227. INSERT dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:57.847 |
| LSN | 0x00006c0d00000020007d |

### Inserted Row

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:48.557" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "CLN_CARE_STATUS_IXS" |
| TABLE_NAME | "D_INTERVIEW" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:50:57.7076732" |

## 228. INSERT dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:57.847 |
| LSN | 0x00006c0d00000020007d |

### Inserted Row

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:48.557" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "IX_900_SITE_ID" |
| TABLE_NAME | "D_INTERVIEW" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:50:57.7076732" |

## 229. INSERT dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:57.847 |
| LSN | 0x00006c0d00000020007d |

### Inserted Row

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:48.557" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "IX_900_SITE_TYPE" |
| TABLE_NAME | "D_INTERVIEW" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:50:57.7076732" |

## 230. INSERT dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:57.847 |
| LSN | 0x00006c0d00000020007d |

### Inserted Row

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:48.557" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "IX_900_SITE_ZIP" |
| TABLE_NAME | "D_INTERVIEW" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:50:57.7076732" |

## 231. INSERT dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:57.847 |
| LSN | 0x00006c0d00000020007d |

### Inserted Row

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:48.557" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "IX_CONTACTS_NAMED_IND" |
| TABLE_NAME | "D_INTERVIEW" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:50:57.7076732" |

## 232. INSERT dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:57.847 |
| LSN | 0x00006c0d00000020007d |

### Inserted Row

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:48.557" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "IX_INTERVENTION" |
| TABLE_NAME | "D_INTERVIEW" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:50:57.7076732" |

## 233. INSERT dbo.nrt_interview_note

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:57.847 |
| LSN | 0x00006c0d00000020007d |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777578655211 |
| comment_date | "2026-04-30T15:50:00" |
| interview_uid | 10009302 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_answer_uid | 2 |
| record_status_cd | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:50:57.7076732" |
| user_comment | "asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say." |
| user_first_name | "Ariella" |
| user_last_name | "Kent" |

## 234. INSERT dbo.nrt_interview_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:50:57.847 |
| LSN | 0x00006c0d00000020007d |

### Inserted Row

| Field | Value |
| --- | --- |
| answer_val | "Yes" |
| batch_id | 1777578655211 |
| interview_uid | 10009302 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| rdb_column_nm | "IX_CONTACTS_NAMED_IND" |
| refresh_datetime | "2026-04-30T19:50:57.7076732" |

## 235. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T19:51:08.700 |
| LSN | 0x00006c0d00000360002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:44:52.2700000" | "2026-04-30T19:51:08.6100000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T19:51:08.6100000" |

## 236. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=6 |
| Transaction end | 2026-04-30T19:51:08.700 |
| LSN | 0x00006c0d00000360002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:44:52.2700000" | "2026-04-30T19:51:08.6100000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:18.7866667" |
| d_patient_key | 6 |
| patient_uid | 10009296 |
| updated_dttm | "2026-04-30T19:51:08.6100000" |

## 237. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:51:08.700 |
| LSN | 0x00006c0d00000360002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:44:42.890" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 238. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:51:08.700 |
| LSN | 0x00006c0d00000360002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:50:49.297" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 239. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:51:08.700 |
| LSN | 0x00006c0d00000360002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:44:42.900" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 240. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:51:08.700 |
| LSN | 0x00006c0d00000360002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:50:49.307" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 241. UPDATE dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=3 |
| Transaction end | 2026-04-30T19:51:09.060 |
| LSN | 0x00006c0d00000490000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:44:52.7100000" | "2026-04-30T19:51:09.0400000" |

### Row After Change

| Field | Value |
| --- | --- |
| case_uid | 10009300 |
| created_dttm | "2026-04-30T19:32:19.1500000" |
| d_investigation_key | 3 |
| updated_dttm | "2026-04-30T19:51:09.0400000" |

## 242. DELETE dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:51:09.060 |
| LSN | 0x00006c0d00000490000c |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Awaiting Interview" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_CASE_STATUS | "Confirmed" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:44:42.917" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 243. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:51:09.060 |
| LSN | 0x00006c0d00000490000c |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Open Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_CASE_STATUS | "Confirmed" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:50:49.327" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 244. UPDATE dbo.nrt_confirmation_method_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:09.090 |
| LSN | 0x00006c0d000004a0000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:44:52.7433333" | "2026-04-30T19:51:09.0733333" |

### Row After Change

| Field | Value |
| --- | --- |
| confirmation_method_cd | "LD" |
| created_dttm | "2026-04-30T19:39:42.4533333" |
| d_confirmation_method_key | 4 |
| updated_dttm | "2026-04-30T19:51:09.0733333" |

## 245. DELETE dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T19:51:09.090 |
| LSN | 0x00006c0d000004a0000c |

### Deleted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 246. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T19:51:09.090 |
| LSN | 0x00006c0d000004a0000c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 247. DELETE dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:09.563 |
| LSN | 0x00006c0d000006b00006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 248. INSERT dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:09.620 |
| LSN | 0x00006c0d000006c80009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 249. INSERT dbo.LOOKUP_TABLE_N_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.030 |
| LSN | 0x00006c0d000008e8000e |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 250. INSERT dbo.L_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.053 |
| LSN | 0x00006c0d000009500005 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| PAGE_CASE_UID | 10009300.0 |

## 251. INSERT dbo.D_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.120 |
| LSN | 0x00006c0d00000970000c |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| RSK_ANS_REFUSED_SEX_PARTNER | "No" |
| RSK_NUM_SEX_PARTNER_12MO | "7" |
| RSK_UNK_SEX_PARTNERS | "No" |
| nbs_case_answer_uid | 3259 |

## 252. DELETE dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.247 |
| LSN | 0x00006c0d00000b800008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 253. INSERT dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.257 |
| LSN | 0x00006c0d00000b98000b |

### Inserted Row

| Field | Value |
| --- | --- |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 254. DELETE dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.377 |
| LSN | 0x00006c0d00000db80006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 255. INSERT dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.387 |
| LSN | 0x00006c0d00000dd00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 256. INSERT dbo.LOOKUP_TABLE_N_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.627 |
| LSN | 0x00006c0d00000fc00010 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 257. INSERT dbo.L_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.647 |
| LSN | 0x00006c0d000010200005 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| PAGE_CASE_UID | 10009300.0 |

## 258. INSERT dbo.D_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.660 |
| LSN | 0x00006c0d00001040000a |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| nbs_case_answer_uid | 3248 |

## 259. INSERT dbo.LOOKUP_TABLE_N_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.770 |
| LSN | 0x00006c0d00001208000f |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 260. INSERT dbo.L_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.790 |
| LSN | 0x00006c0d000012680005 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| PAGE_CASE_UID | 10009300.0 |

## 261. INSERT dbo.D_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.803 |
| LSN | 0x00006c0d00001288000a |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| nbs_case_answer_uid | 3245 |

## 262. DELETE dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:10.973 |
| LSN | 0x00006c0d000014900008 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 263. INSERT dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:11.057 |
| LSN | 0x00006c0d000014a8000b |

### Inserted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 264. INSERT dbo.LOOKUP_TABLE_N_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:11.633 |
| LSN | 0x00006c0d00001690000e |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 265. INSERT dbo.L_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:11.663 |
| LSN | 0x00006c0d000016f00005 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| PAGE_CASE_UID | 10009300.0 |

## 266. INSERT dbo.D_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:51:11.770 |
| LSN | 0x00006c0e000000200110 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| MDH_PREV_STD_HIST | "No" |
| nbs_case_answer_uid | 3254 |

## 267. DELETE dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T19:52:58.460 |
| LSN | 0x00006c0f000018c00007 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 268. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T19:52:58.460 |
| LSN | 0x00006c0f000018c00007 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 269. INSERT dbo.nrt_interview_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_interview_key=2 |
| Transaction end | 2026-04-30T19:52:58.557 |
| LSN | 0x00006c0f000019280036 |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:52:58.5566667" |
| d_interview_key | 2 |
| interview_uid | 10009302 |
| updated_dttm | "2026-04-30T19:52:58.5566667" |

## 270. INSERT dbo.D_INTERVIEW

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="INT10000000GA01" |
| Transaction end | 2026-04-30T19:52:58.577 |
| LSN | 0x00006c0f00001950001d |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:50:52.317" |
| ADD_USER_ID | 10009282 |
| D_INTERVIEW_KEY | 2.0 |
| IX_CONTACTS_NAMED_IND | "Yes" |
| IX_DATE | "2026-04-24T00:00:00" |
| IX_INTERVIEWEE_ROLE | "Subject of Investigation" |
| IX_INTERVIEWEE_ROLE_CD | "SUBJECT" |
| IX_LOCATION | "Telephone" |
| IX_LOCATION_CD | "T" |
| IX_STATUS | "Closed/Completed" |
| IX_STATUS_CD | "COMPLETE" |
| IX_TYPE | "Initial/Original" |
| IX_TYPE_CD | "INITIAL" |
| LAST_CHG_TIME | "2026-04-30T19:50:52.317" |
| LAST_CHG_USER_ID | 10009282 |
| LOCAL_ID | "INT10000000GA01" |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_TIME | "2026-04-30T19:50:52.317" |
| VERSION_CTRL_NBR | 1 |

## 271. INSERT dbo.nrt_interview_note_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_interview_key=2, d_interview_note_key=2 |
| Transaction end | 2026-04-30T19:52:58.590 |
| LSN | 0x00006c0f000019680036 |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:52:58.5900000" |
| d_interview_key | 2 |
| d_interview_note_key | 2 |
| nbs_answer_uid | 2 |
| updated_dttm | "2026-04-30T19:52:58.5900000" |

## 272. INSERT dbo.D_INTERVIEW_NOTE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:52:58.600 |
| LSN | 0x00006c0f00001990001d |

### Inserted Row

| Field | Value |
| --- | --- |
| COMMENT_DATE | "2026-04-30T15:50:00" |
| D_INTERVIEW_KEY | 2.0 |
| D_INTERVIEW_NOTE_KEY | 2.0 |
| NBS_ANSWER_UID | 2.0 |
| USER_COMMENT | "asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say. asd asd asda dasd adsas dad asda lots of things to say." |
| USER_FIRST_NAME | "Ariella" |
| USER_LAST_NAME | "Kent" |

## 273. INSERT dbo.F_INTERVIEW_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:52:58.643 |
| LSN | 0x00006c0f00001a080018 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INTERVIEW_KEY | 2.0 |
| INTERPRETER_KEY | 1.0 |
| INTERVENTION_SITE_KEY | 1 |
| INVESTIGATION_KEY | 3 |
| IX_INTERVIEWEE_KEY | 6.0 |
| IX_INTERVIEWER_KEY | 2 |
| NURSE_KEY | 1.0 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1.0 |
| PROXY_KEY | 1.0 |

## 274. UPDATE dbo.D_CASE_MANAGEMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:52:58.703 |
| LSN | 0x00006c0f00001a380007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CA_PATIENT_INTV_STATUS | "A - Awaiting" | "I - Interviewed" |
| PAT_INTV_STATUS_CD | "A" | "I" |

### Row After Change

| Field | Value |
| --- | --- |
| ADD_USER_ID | 10009282.0 |
| CASE_OID | 1300100015.0 |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25" |
| CA_PATIENT_INTV_STATUS | "I - Interviewed" |
| D_CASE_MANAGEMENT_KEY | 2.0 |
| EPI_LINK_ID | "1310000026" |
| FLD_FOLL_UP_NOTIFICATION_PLAN | "3" |
| FL_FUP_DISPOSITION_CD | "C" |
| FL_FUP_DISPOSITION_DESC | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25" |
| FL_FUP_FIELD_RECORD_NUM | "1310000026" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25" |
| FL_FUP_NOTIFICATION_PLAN_CD | "3 - Dual" |
| INIT_FOLL_UP_NOTIFIABLE | "6-Yes, Notifiable" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE_CD | "06" |
| INVESTIGATION_KEY | 3.0 |
| PAT_INTV_STATUS_CD | "I" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24" |
| SURV_PATIENT_FOLL_UP | "FF" |
| SURV_PATIENT_FOLL_UP_CD | "Field Follow-up" |

## 275. UPDATE dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T19:52:58.703 |
| LSN | 0x00006c0f00001a380007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:46:08.2600000" | "2026-04-30T19:52:58.7000000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:20.4066667" |
| d_case_management_key | 2 |
| public_health_case_uid | 10009300 |
| updated_dttm | "2026-04-30T19:52:58.7000000" |

## 276. DELETE dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:52:58.837 |
| LSN | 0x00006c0f00001a78000d |

### Deleted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 1 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 1 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 1 |
| D_INV_SOCIAL_HISTORY_KEY | 1 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 277. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:52:58.837 |
| LSN | 0x00006c0f00001a78000d |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 3 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 3 |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 278. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:52:58.927 |
| LSN | 0x00006c0f00001ab80016 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:44:42.917" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:44:42.917" |

## 279. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:52:58.927 |
| LSN | 0x00006c0f00001ab80016 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:50:49.327" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:50:49.327" |

## 280. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:52:58.933 |
| LSN | 0x00006c0f00001ac80009 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:44:42.917" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:44:42.917" |

## 281. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T19:52:58.933 |
| LSN | 0x00006c0f00001ac80009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:50:49.327" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:50:49.327" |

## 282. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:52:59.187 |
| LSN | 0x00006c0f00001b680004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CURR_PROCESS_STATE | "Awaiting Interview" | "Open Case" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:44:42.917" | "2026-04-30T19:50:49.327" |

### Row After Change

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD | "Laboratory confirmed" |
| CURR_PROCESS_STATE | "Open Case" |
| DIAGNOSIS_DATE | "2026-04-21T00:00:00" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| ILLNESS_ONSET_DATE | "2026-04-17T00:00:00" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:50:49.327" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Open" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 283. UPDATE dbo.INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:53:59.533 |
| LSN | 0x00006c11000007100004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| D_INV_HIV_KEY | 1 | 3 |
| HIV_900_TEST_IND | null | "No" |
| HIV_900_TEST_REFERRAL_DT | null | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | null | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | null | "No" |
| HIV_REFER_FOR_900_CARE_IND | null | "No" |
| HIV_REFER_FOR_900_TEST | null | "Yes" |

### Row After Change

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| INVESTIGATION_KEY | 3 |

## 284. UPDATE dbo.STD_HIV_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:53:59.667 |
| LSN | 0x00006c11000007380004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CA_PATIENT_INTV_STATUS | "A - Awaiting" | "I - Interviewed" |
| CLN_PRE_EXP_PROPHY_IND | null | "No" |
| CLN_PRE_EXP_PROPHY_REFER | null | "Yes" |
| CURR_PROCESS_STATE | "Awaiting Interview" | "Open Case" |
| HIV_900_TEST_IND | null | "No" |
| HIV_900_TEST_REFERRAL_DT | null | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | null | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | null | "No" |
| HIV_REFER_FOR_900_CARE_IND | null | "No" |
| HIV_REFER_FOR_900_TEST | null | "Yes" |
| IX_DATE_OI | null | "2026-04-24T00:00:00" |
| MDH_PREV_STD_HIST | null | "No" |
| SOC_FEMALE_PRTNRS_12MO_IND | null | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | null | "2" |
| SOC_MALE_PRTNRS_12MO_IND | null | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | null | "5" |
| SOC_PLACES_TO_HAVE_SEX | null | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | null | "No" |
| SOC_PRTNRS_PRD_FML_IND | null | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | null | "1" |
| SOC_PRTNRS_PRD_MALE_IND | null | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | null | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | null | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | null | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | null | "No" |

### Row After Change

| Field | Value |
| --- | --- |
| CALC_5_YEAR_AGE_GROUP | " 9" |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25T00:00:00" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25T00:00:00" |
| CA_PATIENT_INTV_STATUS | "I - Interviewed" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| COINFECTION_ID | "COIN1000XX01" |
| CONDITION_CD | "10312" |
| CONDITION_KEY | 44 |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CURR_PROCESS_STATE | "Open Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS | "720 - Syphilis, secondary" |
| DIAGNOSIS_CD | "720" |
| EPI_LINK_ID | "1310000026" |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| FIELD_RECORD_NUMBER | "1310000026" |
| FL_FUP_DISPOSITION | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25T00:00:00" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_NOTIFICATION_PLAN | "3 - Dual" |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| HOSPITAL_KEY | 1 |
| HSPTLIZD_IND | "No" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE | "06" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_STATUS | "Open" |
| INVESTIGATOR_CLOSED_KEY | 1 |
| INVESTIGATOR_CURRENT_KEY | 2 |
| INVESTIGATOR_CURRENT_QC | "1" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 2 |
| INVESTIGATOR_DISP_FL_FUP_QC | "1" |
| INVESTIGATOR_FL_FUP_KEY | 4 |
| INVESTIGATOR_FL_FUP_QC | "3" |
| INVESTIGATOR_INITIAL_KEY | 3 |
| INVESTIGATOR_INITIAL_QC | "2" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 4 |
| INVESTIGATOR_INIT_FL_FUP_QC | "3" |
| INVESTIGATOR_INIT_INTRVW_KEY | 2 |
| INVESTIGATOR_INIT_INTRVW_QC | "1" |
| INVESTIGATOR_INTERVIEW_KEY | 2 |
| INVESTIGATOR_INTERVIEW_QC | "1" |
| INVESTIGATOR_SUPER_CASE_KEY | 1 |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 2 |
| INVESTIGATOR_SUPER_FL_FUP_QC | "1" |
| INVESTIGATOR_SURV_KEY | 3 |
| INVESTIGATOR_SURV_QC | "2" |
| INV_CASE_STATUS | "Confirmed" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| IX_DATE_OI | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| MDH_PREV_STD_HIST | "No" |
| ORDERING_FACILITY_KEY | 1 |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_AGE_REPORTED | "          41 Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_NAME | "Swift_fake77gg, Taylor" |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_PREGNANT_IND | "Yes" |
| PATIENT_RACE | "White" |
| PATIENT_SEX | "Female" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| PHYSICIAN_FL_FUP_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| REFERRAL_BASIS | "T1 - Positive Test" |
| REPORTING_ORG_KEY | 4 |
| REPORTING_PROV_KEY | 6 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24T00:00:00" |
| SURV_PATIENT_FOLL_UP | "Field Follow-up" |
| TRT_TREATMENT_DATE | "2026-04-20" |

## 285. DELETE dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:54:00.090 |
| LSN | 0x00006c1100000820000a |

### Deleted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:44:42.917" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 286. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T19:54:00.090 |
| LSN | 0x00006c1100000820000a |

### Inserted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:50:49.327" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 287. INSERT dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001001GA01", public_health_case_uid=10009307 |
| Transaction end | 2026-04-30T19:58:03.133 |
| LSN | 0x00006c1100000ab00003 |

### Inserted Row

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-25T00:00:00" |
| add_time | "2026-04-30T19:57:57.590" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777579082726 |
| case_class_cd | "" |
| case_count | 1 |
| case_management_uid | 1001 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| class_cd | "CASE" |
| coinfection_id | "COIN1001XX01" |
| curr_process_state | "Field Follow-up" |
| curr_process_state_cd | "FF" |
| fld_fup_investgr_of_phc_uid | 10003004 |
| init_fld_fup_investgr_of_phc_uid | 10003004 |
| init_fup_investgr_of_phc_uid | 10003004 |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Open" |
| investigation_status_cd | "O" |
| investigator_assigned_datetime | "2026-04-25T00:00:00" |
| investigator_assigned_time | "2026-04-25T00:00:00" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T19:57:57.590" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "CAS10001001GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "16" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:57:57.590" |
| nac_last_chg_time | "2026-04-30T19:57:57.590" |
| nac_page_case_uid | 10009307 |
| patient_id | 10009305 |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009307 |
| raw_record_status_cd | "OPEN" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T19:57:57.590" |
| referral_basis | "P1 - Partner, Sex" |
| referral_basis_cd | "P1" |
| refresh_datetime | "2026-04-30T19:58:03.1280258" |
| shared_ind | "T" |

## 288. INSERT dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009307 |
| Transaction end | 2026-04-30T19:58:03.223 |
| LSN | 0x00006c1100000ad80005 |

### Inserted Row

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| adi_complexion | "" |
| adi_hair | "" |
| adi_height | "" |
| adi_height_legacy_case | "" |
| adi_other_identifying_info | "" |
| adi_size_build | "" |
| case_management_uid | 1001 |
| case_oid | 1300100015 |
| epi_link_id | "1310000026" |
| fl_fup_field_record_num | "1310000126" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Field Follow-up" |
| init_fup_initial_foll_up_cd | "FF" |
| init_fup_internet_foll_up_cd | "" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009307 |
| refresh_datetime | "2026-04-30T19:58:03.2247418" |

## 289. INSERT dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067003GA01" |
| Transaction end | 2026-04-30T19:58:03.257 |
| LSN | 0x00006c1100000ae00004 |

### Inserted Row

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:57:57.537" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| curr_sex_cd | "M" |
| current_sex | "Male" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| entry_method | "N" |
| first_name | "FredContact" |
| last_chg_time | "2026-04-30T19:57:57.537" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "PSN10067003GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009303 |
| patient_uid | 10009303 |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:58:03.2537431" |
| status_name_cd | "A" |

## 290. INSERT dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067003GA01" |
| Transaction end | 2026-04-30T19:58:03.257 |
| LSN | 0x00006c1100000ae00004 |

### Inserted Row

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:57:57.577" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| curr_sex_cd | "M" |
| current_sex | "Male" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| entry_method | "N" |
| first_name | "FredContact" |
| last_chg_time | "2026-04-30T19:57:57.577" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "PSN10067003GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009303 |
| patient_uid | 10009305 |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:58:03.2537431" |
| status_name_cd | "A" |

## 291. INSERT dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067003GA01" |
| Transaction end | 2026-04-30T19:58:03.260 |
| LSN | 0x00006c1100000ae80003 |

### Inserted Row

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:57:57.627" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| curr_sex_cd | "M" |
| current_sex | "Male" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| entry_method | "N" |
| first_name | "FredContact" |
| last_chg_time | "2026-04-30T19:57:57.627" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "PSN10067003GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009303 |
| patient_uid | 10009308 |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T19:58:03.2587962" |
| status_name_cd | "A" |

## 292. INSERT dbo.nrt_contact

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T19:58:04.680 |
| LSN | 0x00006c1100000be00030 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| CONTACT_ENTITY_EPI_LINK_ID | "1310000026" |
| CONTACT_ENTITY_PHC_UID | 10009307 |
| CONTACT_ENTITY_UID | 10009308 |
| CONTACT_UID | 10009310 |
| CTT_EVAL_NOTES | "" |
| CTT_JURISDICTION_NM | "Fulton County" |
| CTT_NOTES | "" |
| CTT_PROCESSING_DECISION | "Field Follow-up" |
| CTT_PROGRAM_AREA | "STD" |
| CTT_REFERRAL_BASIS | "P1 - Partner, Sex" |
| CTT_RISK_NOTES | "" |
| CTT_SHARED_IND | "T" |
| CTT_SYMP_NOTES | "" |
| CTT_TRT_NOTES | "" |
| JURISDICTION_CD | "130001" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LOCAL_ID | "CON10000000GA01" |
| NAMED_DURING_INTERVIEW_UID | 10009302 |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROVIDER_CONTACT_INVESTIGATOR_UID | 10003004 |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |
| SUBJECT_ENTITY_EPI_LINK_ID | "1310000026" |
| SUBJECT_ENTITY_PHC_UID | 10009300 |
| SUBJECT_ENTITY_UID | 10009296 |
| VERSION_CTRL_NBR | 1 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:58:04.3719630" |

## 293. INSERT dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:58:04.690 |
| LSN | 0x00006c1100000bf00003 |

### Inserted Row

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:47.187" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "CTT_FIRST_SEX_EXP_DT" |
| TABLE_NAME | "D_CONTACT_RECORD" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:58:04.6887400" |

## 294. INSERT dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:58:04.690 |
| LSN | 0x00006c1100000bf80004 |

### Inserted Row

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:47.187" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "CTT_LAST_SEX_EXP_DT" |
| TABLE_NAME | "D_CONTACT_RECORD" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:58:04.6887400" |

## 295. INSERT dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:58:04.690 |
| LSN | 0x00006c1100000bf80004 |

### Inserted Row

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:47.187" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "CTT_REL_WITH_PATIENT" |
| TABLE_NAME | "D_CONTACT_RECORD" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T19:58:04.6887400" |

## 296. INSERT dbo.nrt_contact_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:58:05.757 |
| LSN | 0x00006c1100000c180007 |

### Inserted Row

| Field | Value |
| --- | --- |
| answer_val | "This patient" |
| contact_uid | 10009310 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| rdb_column_nm | "CTT_REL_WITH_PATIENT" |
| refresh_datetime | "2026-04-30T19:58:05.7232305" |

## 297. INSERT dbo.nrt_contact_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:58:05.757 |
| LSN | 0x00006c1100000c180007 |

### Inserted Row

| Field | Value |
| --- | --- |
| answer_val | "2026-03-15 00:00:00.000" |
| contact_uid | 10009310 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| rdb_column_nm | "CTT_FIRST_SEX_EXP_DT" |
| refresh_datetime | "2026-04-30T19:58:05.7232305" |

## 298. INSERT dbo.nrt_contact_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:58:05.757 |
| LSN | 0x00006c1100000c180007 |

### Inserted Row

| Field | Value |
| --- | --- |
| answer_val | "2026-04-01 00:00:00.000" |
| contact_uid | 10009310 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| rdb_column_nm | "CTT_LAST_SEX_EXP_DT" |
| refresh_datetime | "2026-04-30T19:58:05.7232305" |

## 299. INSERT dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=7 |
| Transaction end | 2026-04-30T19:58:19.183 |
| LSN | 0x00006c1100000c68001b |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:58:19.1200000" |
| d_patient_key | 7 |
| patient_uid | 10009303 |
| updated_dttm | "2026-04-30T19:58:19.1200000" |

## 300. INSERT dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=8 |
| Transaction end | 2026-04-30T19:58:19.183 |
| LSN | 0x00006c1100000c68001b |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:58:19.1200000" |
| d_patient_key | 8 |
| patient_uid | 10009305 |
| updated_dttm | "2026-04-30T19:58:19.1200000" |

## 301. INSERT dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=9 |
| Transaction end | 2026-04-30T19:58:19.183 |
| LSN | 0x00006c1100000c68001b |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:58:19.1200000" |
| d_patient_key | 9 |
| patient_uid | 10009308 |
| updated_dttm | "2026-04-30T19:58:19.1200000" |

## 302. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T19:58:19.183 |
| LSN | 0x00006c1100000c68001b |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:57:57.537" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 7 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:57:57.537" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PATIENT_MPR_UID | 10009303 |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_UID | 10009303 |

## 303. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T19:58:19.183 |
| LSN | 0x00006c1100000c68001b |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:57:57.577" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 8 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:57:57.577" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PATIENT_MPR_UID | 10009303 |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_UID | 10009305 |

## 304. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T19:58:19.183 |
| LSN | 0x00006c1100000c68001b |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:57:57.627" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 9 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:57:57.627" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PATIENT_MPR_UID | 10009303 |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_UID | 10009308 |

## 305. INSERT dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=4 |
| Transaction end | 2026-04-30T19:58:19.633 |
| LSN | 0x00006c1100000cf00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| case_uid | 10009307 |
| created_dttm | "2026-04-30T19:58:19.6300000" |
| d_investigation_key | 4 |
| updated_dttm | "2026-04-30T19:58:19.6300000" |

## 306. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001001GA01" |
| Transaction end | 2026-04-30T19:58:19.633 |
| LSN | 0x00006c1100000cf00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.590" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 16 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009307 |
| COINFECTION_ID | "COIN1001XX01" |
| CURR_PROCESS_STATE | "Field Follow-up" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_ASSIGNED_DT | "2026-04-25T00:00:00" |
| INV_LOCAL_ID | "CAS10001001GA01" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-25T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.590" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "P1 - Partner, Sex" |

## 307. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=1, INVESTIGATION_KEY=4 |
| Transaction end | 2026-04-30T19:58:19.663 |
| LSN | 0x00006c1100000d000014 |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_METHOD_KEY | 1 |
| INVESTIGATION_KEY | 4 |

## 308. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=4, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=8, PHYSICIAN_KEY=1, REPORTER_KEY=1, RPT_SRC_ORG_KEY=1 |
| Transaction end | 2026-04-30T19:59:28.720 |
| LSN | 0x00006c1100000d800005 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 4 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 8 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 1 |
| RPT_SRC_ORG_KEY | 1 |

## 309. INSERT dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009307 |
| Transaction end | 2026-04-30T19:59:28.780 |
| LSN | 0x00006c1100000da00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:59:28.7766667" |
| d_case_management_key | 3 |
| public_health_case_uid | 10009307 |
| updated_dttm | "2026-04-30T19:59:28.7766667" |

## 310. INSERT dbo.D_CASE_MANAGEMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:59:28.780 |
| LSN | 0x00006c1100000da00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_USER_ID | 10009282.0 |
| ADI_COMPLEXION | "" |
| ADI_HAIR | "" |
| ADI_HEIGHT | "" |
| ADI_HEIGHT_LEGACY_CASE | "" |
| ADI_OTHER_IDENTIFYING_INFO | "" |
| ADI_SIZE_BUILD | "" |
| CASE_OID | 1300100015.0 |
| D_CASE_MANAGEMENT_KEY | 3.0 |
| EPI_LINK_ID | "1310000026" |
| FL_FUP_FIELD_RECORD_NUM | "1310000126" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25" |
| INIT_FOLL_UP_NOTIFIABLE | "6-Yes, Notifiable" |
| INIT_FUP_INITIAL_FOLL_UP | "Field Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "FF" |
| INIT_FUP_INTERNET_FOLL_UP_CD | "" |
| INIT_FUP_NOTIFIABLE_CD | "06" |
| INVESTIGATION_KEY | 4.0 |

## 311. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:59:28.920 |
| LSN | 0x00006c1100000de00006 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 1 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 1 |
| D_INV_CLINICAL_KEY | 1 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 1 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 1 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 1 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 1 |
| D_INV_SOCIAL_HISTORY_KEY | 1 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 1 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 2 |
| INIT_ASGNED_INTERVIEWER_KEY | 1 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 2 |
| INTERVIEWER_ASSIGNED_KEY | 1 |
| INVESTIGATION_KEY | 4 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 2 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 1 |
| PATIENT_KEY | 8 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 1 |
| SURVEILLANCE_INVESTIGATOR_KEY | 1 |

## 312. INSERT dbo.nrt_contact_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_contact_record_key=2 |
| Transaction end | 2026-04-30T19:59:29.010 |
| LSN | 0x00006c1100000e280034 |

### Inserted Row

| Field | Value |
| --- | --- |
| contact_uid | 10009310 |
| created_dttm | "2026-04-30T19:59:29.0100000" |
| d_contact_record_key | 2 |
| updated_dttm | "2026-04-30T19:59:29.0100000" |

## 313. INSERT dbo.D_CONTACT_RECORD

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T19:59:29.033 |
| LSN | 0x00006c1100000e500004 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| CONTACT_ENTITY_EPI_LINK_ID | "1310000026" |
| CTT_EVAL_NOTES | "" |
| CTT_FIRST_SEX_EXP_DT | "2026-03-15T00:00:00" |
| CTT_JURISDICTION_NM | "Fulton County" |
| CTT_LAST_SEX_EXP_DT | "2026-04-01T00:00:00" |
| CTT_NOTES | "" |
| CTT_PROCESSING_DECISION | "Field Follow-up" |
| CTT_PROGRAM_AREA | "STD" |
| CTT_REFERRAL_BASIS | "P1 - Partner, Sex" |
| CTT_REL_WITH_PATIENT | "This patient" |
| CTT_RISK_NOTES | "" |
| CTT_SHARED_IND | "T" |
| CTT_SYMP_NOTES | "" |
| CTT_TRT_NOTES | "" |
| D_CONTACT_RECORD_KEY | 2.0 |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LOCAL_ID | "CON10000000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |
| SUBJECT_ENTITY_EPI_LINK_ID | "1310000026" |
| VERSION_CTRL_NBR | 1 |

## 314. INSERT dbo.F_CONTACT_RECORD_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T19:59:29.090 |
| LSN | 0x00006c1100000ed0001c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONTACT_EXPOSURE_SITE_KEY | 1 |
| CONTACT_INTERVIEW_KEY | 2.0 |
| CONTACT_INVESTIGATION_KEY | 4 |
| CONTACT_INVESTIGATOR_KEY | 2 |
| CONTACT_KEY | 9 |
| DISPOSITIONED_BY_KEY | 1 |
| D_CONTACT_RECORD_KEY | 2.0 |
| SUBJECT_INVESTIGATION_KEY | 3 |
| SUBJECT_KEY | 6 |
| THIRD_PARTY_ENTITY_KEY | 1 |
| THIRD_PARTY_INVESTIGATION_KEY | 1 |

## 315. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001001GA01" |
| Transaction end | 2026-04-30T19:59:29.217 |
| LSN | 0x00006c1100000f480005 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.590" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009307 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.590" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001001GA01" |
| LOCAL_PATIENT_ID | "PSN10067003GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.590" |

## 316. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T19:59:29.217 |
| LSN | 0x00006c1100000f480005 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "CONTACT" |
| EVENT_UID | 10009310 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CON10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_DESC_TXT | "Active" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |

## 317. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001001GA01" |
| Transaction end | 2026-04-30T19:59:29.227 |
| LSN | 0x00006c1100000f580005 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.590" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009307 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.590" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001001GA01" |
| LOCAL_PATIENT_ID | "PSN10067003GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.590" |

## 318. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T19:59:29.227 |
| LSN | 0x00006c1100000f580005 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "CONTACT" |
| EVENT_UID | 10009310 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CON10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_DESC_TXT | "Active" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |

## 319. INSERT dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001001GA01", PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T19:59:29.500 |
| LSN | 0x00006c1100000ff80004 |

### Inserted Row

| Field | Value |
| --- | --- |
| CURR_PROCESS_STATE | "Field Follow-up" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:57:57.590" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:57:57.590" |
| INVESTIGATION_LOCAL_ID | "CAS10001001GA01" |
| INVESTIGATION_STATUS | "Open" |
| INV_START_DT | "2026-04-25T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| MMWR_WEEK | 16 |
| MMWR_YEAR | 2026 |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 8 |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 320. INSERT dbo.INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:00:29.860 |
| LSN | 0x00006c11000019800004 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 1 |
| INVESTIGATION_KEY | 4 |

## 321. INSERT dbo.STD_HIV_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001001GA01", PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:00:30.130 |
| LSN | 0x00006c11000019900004 |

### Inserted Row

| Field | Value |
| --- | --- |
| CASE_RPT_MMWR_WK | 16 |
| CASE_RPT_MMWR_YR | 2026 |
| COINFECTION_ID | "COIN1001XX01" |
| CONDITION_CD | "10312" |
| CONDITION_KEY | 44 |
| CURR_PROCESS_STATE | "Field Follow-up" |
| EPI_LINK_ID | "1310000026" |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| FIELD_RECORD_NUMBER | "1310000126" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25T00:00:00" |
| HOSPITAL_KEY | 1 |
| INIT_FUP_INITIAL_FOLL_UP | "Field Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "FF" |
| INIT_FUP_INTERNET_FOLL_UP | "" |
| INIT_FUP_INTERNET_FOLL_UP_CD | "" |
| INIT_FUP_NOTIFIABLE | "06" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_STATUS | "Open" |
| INVESTIGATOR_CLOSED_KEY | 1 |
| INVESTIGATOR_CURRENT_KEY | 2 |
| INVESTIGATOR_CURRENT_QC | "1" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 1 |
| INVESTIGATOR_FL_FUP_KEY | 2 |
| INVESTIGATOR_FL_FUP_QC | "1" |
| INVESTIGATOR_INITIAL_KEY | 2 |
| INVESTIGATOR_INITIAL_QC | "1" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 2 |
| INVESTIGATOR_INIT_FL_FUP_QC | "1" |
| INVESTIGATOR_INIT_INTRVW_KEY | 1 |
| INVESTIGATOR_INTERVIEW_KEY | 1 |
| INVESTIGATOR_SUPER_CASE_KEY | 1 |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 1 |
| INVESTIGATOR_SURV_KEY | 1 |
| INV_ASSIGNED_DT | "2026-04-25T00:00:00" |
| INV_LOCAL_ID | "CAS10001001GA01" |
| INV_START_DT | "2026-04-25T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| ORDERING_FACILITY_KEY | 1 |
| PATIENT_AGE_REPORTED | "           ." |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PATIENT_NAME | " , FredContact" |
| PATIENT_RACE | "White" |
| PATIENT_SEX | "Male" |
| PHYSICIAN_FL_FUP_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| REFERRAL_BASIS | "P1 - Partner, Sex" |
| REPORTING_ORG_KEY | 1 |
| REPORTING_PROV_KEY | 1 |

## 322. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001001GA01", PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:00:30.370 |
| LSN | 0x00006c1100001a680005 |

### Inserted Row

| Field | Value |
| --- | --- |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-25T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_LOCAL_ID | "CAS10001001GA01" |
| INVESTIGATION_START_DATE | "2026-04-25T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_FIRST_NM | "FredContact" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PHC_ADD_TIME | "2026-04-30T19:57:57.590" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:57:57.590" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |

## 323. UPDATE dbo.nrt_contact

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T20:03:05.777 |
| LSN | 0x00006c1100001c780003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CTT_DISPOSITION | null | "H - Unable to Locate" |
| CTT_DISPO_DT | null | "2026-04-27T00:00:00" |
| refresh_datetime | "2026-04-30T19:58:04.3719630" | "2026-04-30T20:03:05.7777643" |

### Row After Change

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| CONTACT_ENTITY_EPI_LINK_ID | "1310000026" |
| CONTACT_ENTITY_PHC_UID | 10009307 |
| CONTACT_ENTITY_UID | 10009308 |
| CONTACT_UID | 10009310 |
| CTT_DISPOSITION | "H - Unable to Locate" |
| CTT_DISPO_DT | "2026-04-27T00:00:00" |
| CTT_EVAL_NOTES | "" |
| CTT_JURISDICTION_NM | "Fulton County" |
| CTT_NOTES | "" |
| CTT_PROCESSING_DECISION | "Field Follow-up" |
| CTT_PROGRAM_AREA | "STD" |
| CTT_REFERRAL_BASIS | "P1 - Partner, Sex" |
| CTT_RISK_NOTES | "" |
| CTT_SHARED_IND | "T" |
| CTT_SYMP_NOTES | "" |
| CTT_TRT_NOTES | "" |
| JURISDICTION_CD | "130001" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LOCAL_ID | "CON10000000GA01" |
| NAMED_DURING_INTERVIEW_UID | 10009302 |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROVIDER_CONTACT_INVESTIGATOR_UID | 10003004 |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |
| SUBJECT_ENTITY_EPI_LINK_ID | "1310000026" |
| SUBJECT_ENTITY_PHC_UID | 10009300 |
| SUBJECT_ENTITY_UID | 10009296 |
| VERSION_CTRL_NBR | 1 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T20:03:05.7777643" |

## 324. UPDATE dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:05.787 |
| LSN | 0x00006c1100001c880003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T19:58:04.6887400" | "2026-04-30T20:03:05.7871525" |

### Row After Change

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:47.187" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "CTT_FIRST_SEX_EXP_DT" |
| TABLE_NAME | "D_CONTACT_RECORD" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T20:03:05.7871525" |

## 325. UPDATE dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:05.817 |
| LSN | 0x00006c1100001ca80004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T19:58:04.6887400" | "2026-04-30T20:03:05.7921427" |

### Row After Change

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:47.187" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "CTT_LAST_SEX_EXP_DT" |
| TABLE_NAME | "D_CONTACT_RECORD" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T20:03:05.7921427" |

## 326. UPDATE dbo.nrt_metadata_columns

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:05.817 |
| LSN | 0x00006c1100001ca80004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T19:58:04.6887400" | "2026-04-30T20:03:05.7921427" |

### Row After Change

| Field | Value |
| --- | --- |
| LAST_CHG_TIME | "2023-01-18T15:31:47.187" |
| LAST_CHG_USER_ID | 10000000 |
| RDB_COLUMN_NM | "CTT_REL_WITH_PATIENT" |
| TABLE_NAME | "D_CONTACT_RECORD" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| refresh_datetime | "2026-04-30T20:03:05.7921427" |

## 327. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:03:05.817 |
| LSN | 0x00006c1100001ca80004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:57:57.537" | "2026-04-30T20:03:00.863" |
| refresh_datetime | "2026-04-30T19:58:03.2537431" | "2026-04-30T20:03:05.7921427" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:57:57.537" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| curr_sex_cd | "M" |
| current_sex | "Male" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| entry_method | "N" |
| first_name | "FredContact" |
| last_chg_time | "2026-04-30T20:03:00.863" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "PSN10067003GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009303 |
| patient_uid | 10009303 |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:03:05.7921427" |
| status_name_cd | "A" |

## 328. UPDATE dbo.nrt_contact_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:05.817 |
| LSN | 0x00006c1100001ca80004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T19:58:05.7232305" | "2026-04-30T20:03:05.7921427" |

### Row After Change

| Field | Value |
| --- | --- |
| answer_val | "This patient" |
| contact_uid | 10009310 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| rdb_column_nm | "CTT_REL_WITH_PATIENT" |
| refresh_datetime | "2026-04-30T20:03:05.7921427" |

## 329. UPDATE dbo.nrt_contact_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:05.817 |
| LSN | 0x00006c1100001ca80004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T19:58:05.7232305" | "2026-04-30T20:03:05.7921427" |

### Row After Change

| Field | Value |
| --- | --- |
| answer_val | "2026-03-15 00:00:00.000" |
| contact_uid | 10009310 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| rdb_column_nm | "CTT_FIRST_SEX_EXP_DT" |
| refresh_datetime | "2026-04-30T20:03:05.7921427" |

## 330. UPDATE dbo.nrt_contact_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:05.817 |
| LSN | 0x00006c1100001ca80004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T19:58:05.7232305" | "2026-04-30T20:03:05.7921427" |

### Row After Change

| Field | Value |
| --- | --- |
| answer_val | "2026-04-01 00:00:00.000" |
| contact_uid | 10009310 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| rdb_column_nm | "CTT_LAST_SEX_EXP_DT" |
| refresh_datetime | "2026-04-30T20:03:05.7921427" |

## 331. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:03:05.823 |
| LSN | 0x00006c1100001cb00003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:57:57.577" | "2026-04-30T20:03:00.867" |
| refresh_datetime | "2026-04-30T19:58:03.2537431" | "2026-04-30T20:03:05.8224409" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:57:57.577" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| curr_sex_cd | "M" |
| current_sex | "Male" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| entry_method | "N" |
| first_name | "FredContact" |
| last_chg_time | "2026-04-30T20:03:00.867" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "PSN10067003GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009303 |
| patient_uid | 10009305 |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:03:05.8224409" |
| status_name_cd | "A" |

## 332. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:03:05.840 |
| LSN | 0x00006c1100001cd00003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T20:03:05.7921427" | "2026-04-30T20:03:05.8420703" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:57:57.537" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| curr_sex_cd | "M" |
| current_sex | "Male" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| entry_method | "N" |
| first_name | "FredContact" |
| last_chg_time | "2026-04-30T20:03:00.863" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "PSN10067003GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009303 |
| patient_uid | 10009303 |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:03:05.8420703" |
| status_name_cd | "A" |

## 333. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:03:05.930 |
| LSN | 0x00006c1100001d200003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T20:03:05.8224409" | "2026-04-30T20:03:05.9311001" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:57:57.577" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| curr_sex_cd | "M" |
| current_sex | "Male" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| entry_method | "N" |
| first_name | "FredContact" |
| last_chg_time | "2026-04-30T20:03:00.867" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "PSN10067003GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009303 |
| patient_uid | 10009305 |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:03:05.9311001" |
| status_name_cd | "A" |

## 334. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:06.107 |
| LSN | 0x00006c1100001d480006 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009307 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:02~~he wasn't in the park anymore. we don't know where he is." |
| batch_id | 1777579385427 |
| block_nm | "BLOCK_2" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:02:59.263" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3270 |
| nbs_question_uid | 10001240 |
| nbs_rdb_metadata_uid | 10062285 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012474 |
| nca_add_time | "2026-04-30T19:57:57.590" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 2 |
| question_identifier | "NBS185" |
| question_label | "Note" |
| rdb_column_nm | "FL_FUP_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:03:06.1072359" |
| seq_nbr | 0 |

## 335. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:06.110 |
| LSN | 0x00006c1100001d500006 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009307 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 20:03~~the neighbors think he left the country" |
| batch_id | 1777579385427 |
| block_nm | "BLOCK_8" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:03:00.800" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3271 |
| nbs_question_uid | 10001241 |
| nbs_rdb_metadata_uid | 10062286 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012476 |
| nca_add_time | "2026-04-30T19:57:57.590" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 8 |
| question_identifier | "NBS268" |
| question_label | "Note" |
| rdb_column_nm | "FIELD_SUPERVISOR_RVW_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:03:06.1121764" |
| seq_nbr | 0 |

## 336. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001001GA01", public_health_case_uid=10009307 |
| Transaction end | 2026-04-30T20:03:06.153 |
| LSN | 0x00006c1100001d600008 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| activity_to_time | null | "2026-04-27T00:00:00" |
| batch_id | 1777579082726 | 1777579385427 |
| case_class_cd | "" | null |
| dispo_fld_fupinvestgr_of_phc_uid | null | 10003004 |
| fld_fup_supervisor_of_phc_uid | null | 10003013 |
| investigation_status | "Open" | "Closed" |
| investigation_status_cd | "O" | "C" |
| last_chg_time | "2026-04-30T19:57:57.590" | "2026-04-30T20:03:00.873" |
| nac_last_chg_time | "2026-04-30T19:57:57.590" | "2026-04-30T20:03:00.873" |
| rdb_table_name_list | null | "D_INVESTIGATION_REPEAT" |
| record_status_time | "2026-04-30T19:57:57.590" | "2026-04-30T20:03:00.873" |
| refresh_datetime | "2026-04-30T19:58:03.1280258" | "2026-04-30T20:03:06.1341579" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-25T00:00:00" |
| activity_to_time | "2026-04-27T00:00:00" |
| add_time | "2026-04-30T19:57:57.590" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777579385427 |
| case_count | 1 |
| case_management_uid | 1001 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| class_cd | "CASE" |
| coinfection_id | "COIN1001XX01" |
| curr_process_state | "Field Follow-up" |
| curr_process_state_cd | "FF" |
| dispo_fld_fupinvestgr_of_phc_uid | 10003004 |
| fld_fup_investgr_of_phc_uid | 10003004 |
| fld_fup_supervisor_of_phc_uid | 10003013 |
| init_fld_fup_investgr_of_phc_uid | 10003004 |
| init_fup_investgr_of_phc_uid | 10003004 |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Closed" |
| investigation_status_cd | "C" |
| investigator_assigned_datetime | "2026-04-25T00:00:00" |
| investigator_assigned_time | "2026-04-25T00:00:00" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T20:03:00.873" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "CAS10001001GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "16" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:57:57.590" |
| nac_last_chg_time | "2026-04-30T20:03:00.873" |
| nac_page_case_uid | 10009307 |
| patient_id | 10009305 |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009307 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T20:03:00.873" |
| referral_basis | "P1 - Partner, Sex" |
| referral_basis_cd | "P1" |
| refresh_datetime | "2026-04-30T20:03:06.1341579" |
| shared_ind | "T" |

## 337. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009307 |
| Transaction end | 2026-04-30T20:03:06.153 |
| LSN | 0x00006c1100001d600008 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| adi_complexion | "" | null |
| adi_hair | "" | null |
| adi_height | "" | null |
| adi_height_legacy_case | "" | null |
| adi_other_identifying_info | "" | null |
| adi_size_build | "" | null |
| case_review_status | null | "Accept" |
| case_review_status_date | null | "2026-04-30T20:02:58.980" |
| fl_fup_dispo_dt | null | "2026-04-27T00:00:00" |
| fl_fup_disposition_cd | null | "H" |
| fl_fup_disposition_desc | null | "H - Unable to Locate" |
| init_fup_internet_foll_up_cd | "" | null |
| refresh_datetime | "2026-04-30T19:58:03.2247418" | "2026-04-30T20:03:06.1341579" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| case_management_uid | 1001 |
| case_oid | 1300100015 |
| case_review_status | "Accept" |
| case_review_status_date | "2026-04-30T20:02:58.980" |
| epi_link_id | "1310000026" |
| fl_fup_dispo_dt | "2026-04-27T00:00:00" |
| fl_fup_disposition_cd | "H" |
| fl_fup_disposition_desc | "H - Unable to Locate" |
| fl_fup_field_record_num | "1310000126" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Field Follow-up" |
| init_fup_initial_foll_up_cd | "FF" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009307 |
| refresh_datetime | "2026-04-30T20:03:06.1341579" |

## 338. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:06.157 |
| LSN | 0x00006c1100001d680004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579385427 | 1777579385430 |
| refresh_datetime | "2026-04-30T20:03:06.1072359" | "2026-04-30T20:03:06.1547895" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009307 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:02~~he wasn't in the park anymore. we don't know where he is." |
| batch_id | 1777579385430 |
| block_nm | "BLOCK_2" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:02:59.263" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3270 |
| nbs_question_uid | 10001240 |
| nbs_rdb_metadata_uid | 10062285 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012474 |
| nca_add_time | "2026-04-30T19:57:57.590" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 2 |
| question_identifier | "NBS185" |
| question_label | "Note" |
| rdb_column_nm | "FL_FUP_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:03:06.1547895" |
| seq_nbr | 0 |

## 339. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:06.157 |
| LSN | 0x00006c1100001d680004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579385427 | 1777579385430 |
| refresh_datetime | "2026-04-30T20:03:06.1121764" | "2026-04-30T20:03:06.1547895" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009307 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 20:03~~the neighbors think he left the country" |
| batch_id | 1777579385430 |
| block_nm | "BLOCK_8" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:03:00.800" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3271 |
| nbs_question_uid | 10001241 |
| nbs_rdb_metadata_uid | 10062286 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012476 |
| nca_add_time | "2026-04-30T19:57:57.590" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 8 |
| question_identifier | "NBS268" |
| question_label | "Note" |
| rdb_column_nm | "FIELD_SUPERVISOR_RVW_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:03:06.1547895" |
| seq_nbr | 0 |

## 340. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001001GA01", public_health_case_uid=10009307 |
| Transaction end | 2026-04-30T20:03:06.160 |
| LSN | 0x00006c1100001d700004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579385427 | 1777579385430 |
| rdb_table_name_list | null | "D_INVESTIGATION_REPEAT" |
| refresh_datetime | "2026-04-30T20:03:06.1341579" | "2026-04-30T20:03:06.1591513" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-25T00:00:00" |
| activity_to_time | "2026-04-27T00:00:00" |
| add_time | "2026-04-30T19:57:57.590" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777579385430 |
| case_count | 1 |
| case_management_uid | 1001 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| class_cd | "CASE" |
| coinfection_id | "COIN1001XX01" |
| curr_process_state | "Field Follow-up" |
| curr_process_state_cd | "FF" |
| dispo_fld_fupinvestgr_of_phc_uid | 10003004 |
| fld_fup_investgr_of_phc_uid | 10003004 |
| fld_fup_supervisor_of_phc_uid | 10003013 |
| init_fld_fup_investgr_of_phc_uid | 10003004 |
| init_fup_investgr_of_phc_uid | 10003004 |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Closed" |
| investigation_status_cd | "C" |
| investigator_assigned_datetime | "2026-04-25T00:00:00" |
| investigator_assigned_time | "2026-04-25T00:00:00" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T20:03:00.873" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| local_id | "CAS10001001GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "16" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:57:57.590" |
| nac_last_chg_time | "2026-04-30T20:03:00.873" |
| nac_page_case_uid | 10009307 |
| patient_id | 10009305 |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009307 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T20:03:00.873" |
| referral_basis | "P1 - Partner, Sex" |
| referral_basis_cd | "P1" |
| refresh_datetime | "2026-04-30T20:03:06.1591513" |
| shared_ind | "T" |

## 341. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009307 |
| Transaction end | 2026-04-30T20:03:06.160 |
| LSN | 0x00006c1100001d700004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T20:03:06.1341579" | "2026-04-30T20:03:06.1591513" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| case_management_uid | 1001 |
| case_oid | 1300100015 |
| case_review_status | "Accept" |
| case_review_status_date | "2026-04-30T20:02:58.980" |
| epi_link_id | "1310000026" |
| fl_fup_dispo_dt | "2026-04-27T00:00:00" |
| fl_fup_disposition_cd | "H" |
| fl_fup_disposition_desc | "H - Unable to Locate" |
| fl_fup_field_record_num | "1310000126" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Field Follow-up" |
| init_fup_initial_foll_up_cd | "FF" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009307 |
| refresh_datetime | "2026-04-30T20:03:06.1591513" |

## 342. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=7 |
| Transaction end | 2026-04-30T20:03:09.453 |
| LSN | 0x00006c1100001e000037 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:58:19.1200000" | "2026-04-30T20:03:09.3533333" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:58:19.1200000" |
| d_patient_key | 7 |
| patient_uid | 10009303 |
| updated_dttm | "2026-04-30T20:03:09.3533333" |

## 343. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=8 |
| Transaction end | 2026-04-30T20:03:09.453 |
| LSN | 0x00006c1100001e000037 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:58:19.1200000" | "2026-04-30T20:03:09.3533333" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:58:19.1200000" |
| d_patient_key | 8 |
| patient_uid | 10009305 |
| updated_dttm | "2026-04-30T20:03:09.3533333" |

## 344. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:03:09.453 |
| LSN | 0x00006c1100001e000037 |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:57:57.537" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 7 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:57:57.537" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PATIENT_MPR_UID | 10009303 |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_UID | 10009303 |

## 345. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:03:09.453 |
| LSN | 0x00006c1100001e000037 |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:57:57.537" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 7 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:03:00.863" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PATIENT_MPR_UID | 10009303 |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_UID | 10009303 |

## 346. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:03:09.453 |
| LSN | 0x00006c1100001e000037 |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:57:57.577" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 8 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:57:57.577" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PATIENT_MPR_UID | 10009303 |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_UID | 10009305 |

## 347. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:03:09.453 |
| LSN | 0x00006c1100001e000037 |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:57:57.577" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 8 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:03:00.867" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PATIENT_MPR_UID | 10009303 |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_UID | 10009305 |

## 348. UPDATE dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=4 |
| Transaction end | 2026-04-30T20:03:09.950 |
| LSN | 0x00006c1100001f38000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:58:19.6300000" | "2026-04-30T20:03:09.9266667" |

### Row After Change

| Field | Value |
| --- | --- |
| case_uid | 10009307 |
| created_dttm | "2026-04-30T19:58:19.6300000" |
| d_investigation_key | 4 |
| updated_dttm | "2026-04-30T20:03:09.9266667" |

## 349. DELETE dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001001GA01" |
| Transaction end | 2026-04-30T20:03:09.950 |
| LSN | 0x00006c1100001f38000c |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.590" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 16 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009307 |
| COINFECTION_ID | "COIN1001XX01" |
| CURR_PROCESS_STATE | "Field Follow-up" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_ASSIGNED_DT | "2026-04-25T00:00:00" |
| INV_LOCAL_ID | "CAS10001001GA01" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-25T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.590" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "P1 - Partner, Sex" |

## 350. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001001GA01" |
| Transaction end | 2026-04-30T20:03:09.950 |
| LSN | 0x00006c1100001f38000c |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.590" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 16 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009307 |
| COINFECTION_ID | "COIN1001XX01" |
| CURR_PROCESS_STATE | "Field Follow-up" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Closed" |
| INV_ASSIGNED_DT | "2026-04-25T00:00:00" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001001GA01" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-25T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:03:00.873" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "P1 - Partner, Sex" |

## 351. DELETE dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=1, INVESTIGATION_KEY=4 |
| Transaction end | 2026-04-30T20:03:09.983 |
| LSN | 0x00006c1100001f48000a |

### Deleted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_METHOD_KEY | 1 |
| INVESTIGATION_KEY | 4 |

## 352. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=1, INVESTIGATION_KEY=4 |
| Transaction end | 2026-04-30T20:03:09.983 |
| LSN | 0x00006c1100001f48000a |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_METHOD_KEY | 1 |
| INVESTIGATION_KEY | 4 |

## 353. INSERT dbo.LOOKUP_TABLE_N_REPT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:11.560 |
| LSN | 0x00006c11000021a800dd |

### Inserted Row

| Field | Value |
| --- | --- |
| D_REPT_KEY | 1 |
| PAGE_CASE_UID | 10009307 |

## 354. INSERT dbo.L_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:03:11.560 |
| LSN | 0x00006c11000021a800dd |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| PAGE_CASE_UID | 10009307 |

## 355. DELETE dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=4, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=8, PHYSICIAN_KEY=1, REPORTER_KEY=1, RPT_SRC_ORG_KEY=1 |
| Transaction end | 2026-04-30T20:04:56.697 |
| LSN | 0x00006c12000022900007 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 4 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 8 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 1 |
| RPT_SRC_ORG_KEY | 1 |

## 356. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=4, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=8, PHYSICIAN_KEY=1, REPORTER_KEY=1, RPT_SRC_ORG_KEY=1 |
| Transaction end | 2026-04-30T20:04:56.697 |
| LSN | 0x00006c12000022900007 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 4 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 8 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 1 |
| RPT_SRC_ORG_KEY | 1 |

## 357. UPDATE dbo.D_CASE_MANAGEMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:04:56.750 |
| LSN | 0x00006c12000022b00014 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| ADI_COMPLEXION | "" | null |
| ADI_HAIR | "" | null |
| ADI_HEIGHT | "" | null |
| ADI_HEIGHT_LEGACY_CASE | "" | null |
| ADI_OTHER_IDENTIFYING_INFO | "" | null |
| ADI_SIZE_BUILD | "" | null |
| CASE_REVIEW_STATUS | null | "Accept" |
| CASE_REVIEW_STATUS_DATE | null | "2026-04-30" |
| FL_FUP_DISPOSITION_CD | null | "H" |
| FL_FUP_DISPOSITION_DESC | null | "H - Unable to Locate" |
| FL_FUP_DISPO_DT | null | "2026-04-27" |
| INIT_FUP_INTERNET_FOLL_UP_CD | "" | null |

### Row After Change

| Field | Value |
| --- | --- |
| ADD_USER_ID | 10009282.0 |
| CASE_OID | 1300100015.0 |
| CASE_REVIEW_STATUS | "Accept" |
| CASE_REVIEW_STATUS_DATE | "2026-04-30" |
| D_CASE_MANAGEMENT_KEY | 3.0 |
| EPI_LINK_ID | "1310000026" |
| FL_FUP_DISPOSITION_CD | "H" |
| FL_FUP_DISPOSITION_DESC | "H - Unable to Locate" |
| FL_FUP_DISPO_DT | "2026-04-27" |
| FL_FUP_FIELD_RECORD_NUM | "1310000126" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25" |
| INIT_FOLL_UP_NOTIFIABLE | "6-Yes, Notifiable" |
| INIT_FUP_INITIAL_FOLL_UP | "Field Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "FF" |
| INIT_FUP_NOTIFIABLE_CD | "06" |
| INVESTIGATION_KEY | 4.0 |

## 358. UPDATE dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009307 |
| Transaction end | 2026-04-30T20:04:56.750 |
| LSN | 0x00006c12000022b00014 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:59:28.7766667" | "2026-04-30T20:04:56.7433333" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:59:28.7766667" |
| d_case_management_key | 3 |
| public_health_case_uid | 10009307 |
| updated_dttm | "2026-04-30T20:04:56.7433333" |

## 359. DELETE dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:04:56.890 |
| LSN | 0x00006c12000022f00008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 1 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 1 |
| D_INV_CLINICAL_KEY | 1 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 1 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 1 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 1 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 1 |
| D_INV_SOCIAL_HISTORY_KEY | 1 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 1 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 2 |
| INIT_ASGNED_INTERVIEWER_KEY | 1 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 2 |
| INTERVIEWER_ASSIGNED_KEY | 1 |
| INVESTIGATION_KEY | 4 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 2 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 1 |
| PATIENT_KEY | 8 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 1 |
| SURVEILLANCE_INVESTIGATOR_KEY | 1 |

## 360. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:04:56.890 |
| LSN | 0x00006c12000022f00008 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 1 |
| D_INV_CLINICAL_KEY | 1 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 1 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 1 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 1 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 1 |
| D_INV_SOCIAL_HISTORY_KEY | 1 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 1 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 2 |
| INIT_ASGNED_INTERVIEWER_KEY | 1 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 2 |
| INTERVIEWER_ASSIGNED_KEY | 1 |
| INVESTIGATION_KEY | 4 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 2 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 1 |
| PATIENT_KEY | 8 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 4 |
| SURVEILLANCE_INVESTIGATOR_KEY | 1 |

## 361. UPDATE dbo.nrt_contact_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_contact_record_key=2 |
| Transaction end | 2026-04-30T20:04:56.977 |
| LSN | 0x00006c12000023200004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:59:29.0100000" | "2026-04-30T20:04:56.9766667" |

### Row After Change

| Field | Value |
| --- | --- |
| contact_uid | 10009310 |
| created_dttm | "2026-04-30T19:59:29.0100000" |
| d_contact_record_key | 2 |
| updated_dttm | "2026-04-30T20:04:56.9766667" |

## 362. UPDATE dbo.D_CONTACT_RECORD

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T20:04:56.990 |
| LSN | 0x00006c12000023300004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CTT_DISPOSITION | null | "H - Unable to Locate" |
| CTT_DISPO_DT | null | "2026-04-27T00:00:00" |

### Row After Change

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| CONTACT_ENTITY_EPI_LINK_ID | "1310000026" |
| CTT_DISPOSITION | "H - Unable to Locate" |
| CTT_DISPO_DT | "2026-04-27T00:00:00" |
| CTT_EVAL_NOTES | "" |
| CTT_FIRST_SEX_EXP_DT | "2026-03-15T00:00:00" |
| CTT_JURISDICTION_NM | "Fulton County" |
| CTT_LAST_SEX_EXP_DT | "2026-04-01T00:00:00" |
| CTT_NOTES | "" |
| CTT_PROCESSING_DECISION | "Field Follow-up" |
| CTT_PROGRAM_AREA | "STD" |
| CTT_REFERRAL_BASIS | "P1 - Partner, Sex" |
| CTT_REL_WITH_PATIENT | "This patient" |
| CTT_RISK_NOTES | "" |
| CTT_SHARED_IND | "T" |
| CTT_SYMP_NOTES | "" |
| CTT_TRT_NOTES | "" |
| D_CONTACT_RECORD_KEY | 2.0 |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LOCAL_ID | "CON10000000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |
| SUBJECT_ENTITY_EPI_LINK_ID | "1310000026" |
| VERSION_CTRL_NBR | 1 |

## 363. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T20:04:57.150 |
| LSN | 0x00006c1200002398000d |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "CONTACT" |
| EVENT_UID | 10009310 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CON10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_DESC_TXT | "Active" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |

## 364. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T20:04:57.150 |
| LSN | 0x00006c1200002398000d |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "CONTACT" |
| EVENT_UID | 10009310 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CON10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_DESC_TXT | "Active" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |

## 365. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001001GA01" |
| Transaction end | 2026-04-30T20:04:57.150 |
| LSN | 0x00006c1200002398000d |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.590" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009307 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.590" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001001GA01" |
| LOCAL_PATIENT_ID | "PSN10067003GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.590" |

## 366. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001001GA01" |
| Transaction end | 2026-04-30T20:04:57.150 |
| LSN | 0x00006c1200002398000d |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.590" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009307 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:03:00.873" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001001GA01" |
| LOCAL_PATIENT_ID | "PSN10067003GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:03:00.873" |

## 367. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T20:04:57.157 |
| LSN | 0x00006c12000023a8000d |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "CONTACT" |
| EVENT_UID | 10009310 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CON10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_DESC_TXT | "Active" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |

## 368. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CON10000000GA01" |
| Transaction end | 2026-04-30T20:04:57.157 |
| LSN | 0x00006c12000023a8000d |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.627" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "CONTACT" |
| EVENT_UID | 10009310 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.627" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CON10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| RECORD_STATUS_DESC_TXT | "Active" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.627" |

## 369. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001001GA01" |
| Transaction end | 2026-04-30T20:04:57.157 |
| LSN | 0x00006c12000023a8000d |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.590" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009307 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:57:57.590" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001001GA01" |
| LOCAL_PATIENT_ID | "PSN10067003GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:57:57.590" |

## 370. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001001GA01" |
| Transaction end | 2026-04-30T20:04:57.157 |
| LSN | 0x00006c12000023a8000d |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:57:57.590" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009307 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:03:00.873" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001001GA01" |
| LOCAL_PATIENT_ID | "PSN10067003GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:03:00.873" |

## 371. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001001GA01", PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:04:57.380 |
| LSN | 0x00006c12000024480004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:57:57.590" | "2026-04-30T20:03:00.873" |
| INVESTIGATION_STATUS | "Open" | "Closed" |

### Row After Change

| Field | Value |
| --- | --- |
| CURR_PROCESS_STATE | "Field Follow-up" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:57:57.590" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T20:03:00.873" |
| INVESTIGATION_LOCAL_ID | "CAS10001001GA01" |
| INVESTIGATION_STATUS | "Closed" |
| INV_START_DT | "2026-04-25T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| MMWR_WEEK | 16 |
| MMWR_YEAR | 2026 |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 8 |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 372. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001001GA01", PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:04:57.440 |
| LSN | 0x00006c12000024600004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| EVENT_DATE | null | "2026-04-25T00:00:00" |
| EVENT_DATE_TYPE | null | "Investigation Start Date" |

### Row After Change

| Field | Value |
| --- | --- |
| CURR_PROCESS_STATE | "Field Follow-up" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-25T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:57:57.590" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T20:03:00.873" |
| INVESTIGATION_LOCAL_ID | "CAS10001001GA01" |
| INVESTIGATION_STATUS | "Closed" |
| INV_START_DT | "2026-04-25T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| MMWR_WEEK | 16 |
| MMWR_YEAR | 2026 |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_FIRST_NAME | "FredContact" |
| PATIENT_KEY | 8 |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 373. UPDATE dbo.STD_HIV_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001001GA01", PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:05:57.853 |
| LSN | 0x00006c13000017380004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| FL_FUP_DISPOSITION | null | "H - Unable to Locate" |
| FL_FUP_DISPO_DT | null | "2026-04-27T00:00:00" |
| INIT_FUP_INTERNET_FOLL_UP | "" | null |
| INIT_FUP_INTERNET_FOLL_UP_CD | "" | null |
| INVESTIGATION_STATUS | "Open" | "Closed" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 1 | 2 |
| INVESTIGATOR_DISP_FL_FUP_QC | null | "1" |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 1 | 4 |
| INVESTIGATOR_SUPER_FL_FUP_QC | null | "3" |
| INV_CLOSE_DT | null | "2026-04-27T00:00:00" |

### Row After Change

| Field | Value |
| --- | --- |
| CASE_RPT_MMWR_WK | 16 |
| CASE_RPT_MMWR_YR | 2026 |
| COINFECTION_ID | "COIN1001XX01" |
| CONDITION_CD | "10312" |
| CONDITION_KEY | 44 |
| CURR_PROCESS_STATE | "Field Follow-up" |
| EPI_LINK_ID | "1310000026" |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| FIELD_RECORD_NUMBER | "1310000126" |
| FL_FUP_DISPOSITION | "H - Unable to Locate" |
| FL_FUP_DISPO_DT | "2026-04-27T00:00:00" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25T00:00:00" |
| HOSPITAL_KEY | 1 |
| INIT_FUP_INITIAL_FOLL_UP | "Field Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "FF" |
| INIT_FUP_NOTIFIABLE | "06" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_STATUS | "Closed" |
| INVESTIGATOR_CLOSED_KEY | 1 |
| INVESTIGATOR_CURRENT_KEY | 2 |
| INVESTIGATOR_CURRENT_QC | "1" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 2 |
| INVESTIGATOR_DISP_FL_FUP_QC | "1" |
| INVESTIGATOR_FL_FUP_KEY | 2 |
| INVESTIGATOR_FL_FUP_QC | "1" |
| INVESTIGATOR_INITIAL_KEY | 2 |
| INVESTIGATOR_INITIAL_QC | "1" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 2 |
| INVESTIGATOR_INIT_FL_FUP_QC | "1" |
| INVESTIGATOR_INIT_INTRVW_KEY | 1 |
| INVESTIGATOR_INTERVIEW_KEY | 1 |
| INVESTIGATOR_SUPER_CASE_KEY | 1 |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 4 |
| INVESTIGATOR_SUPER_FL_FUP_QC | "3" |
| INVESTIGATOR_SURV_KEY | 1 |
| INV_ASSIGNED_DT | "2026-04-25T00:00:00" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001001GA01" |
| INV_START_DT | "2026-04-25T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| ORDERING_FACILITY_KEY | 1 |
| PATIENT_AGE_REPORTED | "           ." |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PATIENT_NAME | " , FredContact" |
| PATIENT_RACE | "White" |
| PATIENT_SEX | "Male" |
| PHYSICIAN_FL_FUP_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| REFERRAL_BASIS | "P1 - Partner, Sex" |
| REPORTING_ORG_KEY | 1 |
| REPORTING_PROV_KEY | 1 |

## 374. DELETE dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001001GA01", PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:05:58.190 |
| LSN | 0x00006c1300001818000a |

### Deleted Row

| Field | Value |
| --- | --- |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-25T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_LOCAL_ID | "CAS10001001GA01" |
| INVESTIGATION_START_DATE | "2026-04-25T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_FIRST_NM | "FredContact" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PHC_ADD_TIME | "2026-04-30T19:57:57.590" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:57:57.590" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |

## 375. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001001GA01", PATIENT_LOCAL_ID="PSN10067003GA01" |
| Transaction end | 2026-04-30T20:05:58.190 |
| LSN | 0x00006c1300001818000a |

### Inserted Row

| Field | Value |
| --- | --- |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-25T00:00:00" |
| EVENT_DATE_TYPE | "Investigation Start Date" |
| INVESTIGATION_KEY | 4 |
| INVESTIGATION_LOCAL_ID | "CAS10001001GA01" |
| INVESTIGATION_START_DATE | "2026-04-25T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| PATIENT_CURRENT_SEX | "Male" |
| PATIENT_FIRST_NM | "FredContact" |
| PATIENT_LOCAL_ID | "PSN10067003GA01" |
| PHC_ADD_TIME | "2026-04-30T19:57:57.590" |
| PHC_LAST_CHG_TIME | "2026-04-30T20:03:00.873" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |

## 376. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:09:19.730 |
| LSN | 0x00006c13000019b00003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| refresh_datetime | "2026-04-30T19:50:55.3316467" | "2026-04-30T20:09:19.7349773" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777579759399 |
| branch_id | 10009292 |
| branch_type_cd | "APND" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:09:19.7349773" |
| root_type_cd | "LabReport" |

## 377. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:09:19.740 |
| LSN | 0x00006c13000019b8000b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| refresh_datetime | "2026-04-30T19:50:55.3316467" | "2026-04-30T20:09:19.7399421" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777579759399 |
| branch_id | 10009294 |
| branch_type_cd | "COMP" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:09:19.7399421" |
| root_type_cd | "LabReport" |

## 378. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:09:19.740 |
| LSN | 0x00006c13000019b8000b |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777579759399 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:09:19.7399421" |
| root_type_cd | "TreatmentToPHC" |

## 379. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:09:19.740 |
| LSN | 0x00006c13000019b8000b |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777579759399 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:09:19.7399421" |
| root_type_cd | "IXS" |

## 380. UPDATE dbo.nrt_investigation_confirmation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:09:19.740 |
| LSN | 0x00006c13000019b8000b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| refresh_datetime | "2026-04-30T19:50:55.3458259" | "2026-04-30T20:09:19.7399421" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777579759399 |
| confirmation_method_cd | "LD" |
| confirmation_method_desc_txt | "Laboratory confirmed" |
| confirmation_method_time | "2026-04-24T00:00:00" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:09:19.7399421" |

## 381. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3458259" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3241 |
| nbs_question_uid | 10001013 |
| nbs_rdb_metadata_uid | 10062226 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012401 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NOT120" |
| question_label | "Immediate National Notifiable Condition" |
| rdb_column_nm | "ADM_IMM_NTNL_NTFBL_CNDTN" |
| rdb_table_nm | "D_INV_ADMINISTRATIVE" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 382. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/20/2026" |
| batch_id | 1777579759399 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3243 |
| nbs_question_uid | 10001192 |
| nbs_rdb_metadata_uid | 10062178 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012367 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD105" |
| question_label | "Treatment Start Date" |
| rdb_column_nm | "TRT_TREATMENT_DATE" |
| rdb_table_nm | "D_INV_TREATMENT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 383. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "720" |
| batch_id | 1777579759399 |
| code_set_group_id | 105450 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3244 |
| nbs_question_uid | 10001195 |
| nbs_rdb_metadata_uid | 10062221 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012398 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS136" |
| question_label | "Diagnosis Reported to CDC" |
| rdb_column_nm | "CLN_CASE_DIAGNOSIS" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 384. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| batch_id | 1777579759399 |
| block_nm | "BLOCK_2" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3274 |
| nbs_question_uid | 10001240 |
| nbs_rdb_metadata_uid | 10062285 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012474 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 2 |
| question_identifier | "NBS185" |
| question_label | "Note" |
| rdb_column_nm | "FL_FUP_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 385. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "30" |
| batch_id | 1777579759399 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3242 |
| nbs_question_uid | 10001252 |
| nbs_rdb_metadata_uid | 10062300 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012499 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS128" |
| question_label | "Weeks" |
| rdb_column_nm | "PBI_PATIENT_PREGNANT_WKS" |
| rdb_table_nm | "D_INV_PREGNANCY_BIRTH" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 386. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3250 |
| nbs_question_uid | 10001283 |
| nbs_rdb_metadata_uid | 10062358 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012545 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS242" |
| question_label | "Places to Meet Partners" |
| rdb_column_nm | "SOC_PLACES_TO_MEET_PARTNER" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 387. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "R" |
| batch_id | 1777579759399 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3248 |
| nbs_question_uid | 10001285 |
| nbs_rdb_metadata_uid | 10062360 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012549 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS244" |
| question_label | "Places to Have Sex" |
| rdb_column_nm | "SOC_PLACES_TO_HAVE_SEX" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 388. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777579759399 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3255 |
| nbs_question_uid | 10001287 |
| nbs_rdb_metadata_uid | 10062362 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012554 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS223" |
| question_label | "Female Partners (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 389. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777579759399 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3257 |
| nbs_question_uid | 10001288 |
| nbs_rdb_metadata_uid | 10062363 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012555 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS224" |
| question_label | "Number Female (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 390. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777579759399 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3251 |
| nbs_question_uid | 10001289 |
| nbs_rdb_metadata_uid | 10062364 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012556 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS225" |
| question_label | "Male Partners (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 391. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "5" |
| batch_id | 1777579759399 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3252 |
| nbs_question_uid | 10001290 |
| nbs_rdb_metadata_uid | 10062365 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012557 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS226" |
| question_label | "Number Male (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_TOTAL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 392. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3260 |
| nbs_question_uid | 10001291 |
| nbs_rdb_metadata_uid | 10062366 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012558 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS227" |
| question_label | "Transgender Partners (Past Year)" |
| rdb_column_nm | "SOC_TRANSGNDR_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 393. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "7" |
| batch_id | 1777579759399 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3263 |
| nbs_question_uid | 10001293 |
| nbs_rdb_metadata_uid | 10062368 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012560 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD120" |
| question_label | "Total number of sex partners last 12 months?" |
| rdb_column_nm | "RSK_NUM_SEX_PARTNER_12MO" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 394. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3268 |
| nbs_question_uid | 10001294 |
| nbs_rdb_metadata_uid | 10062370 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012561 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD888" |
| question_label | "Patient refused to answer questions regarding number of sex partners" |
| rdb_column_nm | "RSK_ANS_REFUSED_SEX_PARTNER" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 395. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3259 |
| nbs_question_uid | 10001295 |
| nbs_rdb_metadata_uid | 10062372 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012562 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD999" |
| question_label | "Unknown number of sex partners in last 12 months" |
| rdb_column_nm | "RSK_UNK_SEX_PARTNERS" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 396. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777579759399 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3261 |
| nbs_question_uid | 10001296 |
| nbs_rdb_metadata_uid | 10062374 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012564 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS129" |
| question_label | "Female Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 397. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777579759399 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3262 |
| nbs_question_uid | 10001297 |
| nbs_rdb_metadata_uid | 10062375 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012565 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS130" |
| question_label | "Number Female (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 398. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777579759399 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3266 |
| nbs_question_uid | 10001298 |
| nbs_rdb_metadata_uid | 10062376 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012566 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS131" |
| question_label | "Male Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 399. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777579759399 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3267 |
| nbs_question_uid | 10001299 |
| nbs_rdb_metadata_uid | 10062377 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012567 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS132" |
| question_label | "Number Male (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 400. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3264 |
| nbs_question_uid | 10001300 |
| nbs_rdb_metadata_uid | 10062378 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012568 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS133" |
| question_label | "Transgender Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_TRNSGNDR_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 401. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777579759399 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3258 |
| nbs_question_uid | 10001302 |
| nbs_rdb_metadata_uid | 10062380 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012571 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD119" |
| question_label | "Met Sex Partners through the Internet" |
| rdb_column_nm | "SOC_SX_PRTNRS_INTNT_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 402. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3254 |
| nbs_question_uid | 10001316 |
| nbs_rdb_metadata_uid | 10062440 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012614 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD117" |
| question_label | "Previous STD history (self-reported)?" |
| rdb_column_nm | "MDH_PREV_STD_HIST" |
| rdb_table_nm | "D_INV_MEDICAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 403. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777579759399 |
| code_set_group_id | 105500 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3269 |
| nbs_question_uid | 10001321 |
| nbs_rdb_metadata_uid | 10062446 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012622 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS257" |
| question_label | "Enrolled in Partner Services" |
| rdb_column_nm | "HIV_ENROLL_PRTNR_SRVCS_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 404. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3265 |
| nbs_question_uid | 10001322 |
| nbs_rdb_metadata_uid | 10062447 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012624 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS254" |
| question_label | "Previous 900 Test" |
| rdb_column_nm | "HIV_PREVIOUS_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 405. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777579759399 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3247 |
| nbs_question_uid | 10001325 |
| nbs_rdb_metadata_uid | 10062450 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012628 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS260" |
| question_label | "Refer for Test" |
| rdb_column_nm | "HIV_REFER_FOR_900_TEST" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 406. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/24/2026" |
| batch_id | 1777579759399 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3245 |
| nbs_question_uid | 10001326 |
| nbs_rdb_metadata_uid | 10062451 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012629 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS261" |
| question_label | "Referral Date" |
| rdb_column_nm | "HIV_900_TEST_REFERRAL_DT" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 407. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 107870 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3246 |
| nbs_question_uid | 10001327 |
| nbs_rdb_metadata_uid | 10062452 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012630 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS262" |
| question_label | "900 Test" |
| rdb_column_nm | "HIV_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 408. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3249 |
| nbs_question_uid | 10001331 |
| nbs_rdb_metadata_uid | 10062459 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012638 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS266" |
| question_label | "Refer for Care" |
| rdb_column_nm | "HIV_REFER_FOR_900_CARE_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 409. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777579759399 |
| code_set_group_id | 107860 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3273 |
| nbs_question_uid | 10003228 |
| nbs_rdb_metadata_uid | 10062296 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012492 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS444" |
| question_label | "Care Status at Case Close Date" |
| rdb_column_nm | "CLN_CARE_STATUS_CLOSE_DT" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 410. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777579759399 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3256 |
| nbs_question_uid | 10003230 |
| nbs_rdb_metadata_uid | 10062462 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012642 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS443" |
| question_label | "Is the Client Currently On PrEP?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_IND" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 411. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777578654713 | 1777579759399 |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3718440" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777579759399 |
| code_set_group_id | 107900 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3253 |
| nbs_question_uid | 10003231 |
| nbs_rdb_metadata_uid | 10062463 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012643 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS446" |
| question_label | "Has Client Been Referred to PrEP Provider?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_REFER" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| seq_nbr | 0 |

## 412. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001000GA01", public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| activity_to_time | null | "2026-04-27T00:00:00" |
| batch_id | 1777578654713 | 1777579759399 |
| closure_investgr_of_phc_uid | null | 10003004 |
| curr_process_state | "Open Case" | "Closed Case" |
| curr_process_state_cd | "OC" | "CC" |
| investigation_status | "Open" | "Closed" |
| investigation_status_cd | "O" | "C" |
| last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| nac_last_chg_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_time | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| refresh_datetime | "2026-04-30T19:50:55.3997377" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-24T00:00:00" |
| activity_to_time | "2026-04-27T00:00:00" |
| add_time | "2026-04-30T19:32:00.637" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777579759399 |
| case_class_cd | "C" |
| case_count | 1 |
| case_management_uid | 1000 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| city_county_case_nbr | "" |
| class_cd | "CASE" |
| closure_investgr_of_phc_uid | 10003004 |
| coinfection_id | "COIN1000XX01" |
| curr_process_state | "Closed Case" |
| curr_process_state_cd | "CC" |
| detection_method_cd | "21" |
| detection_method_desc_txt | "Self-referral" |
| diagnosis_time | "2026-04-21T00:00:00" |
| dispo_fld_fupinvestgr_of_phc_uid | 10003004 |
| effective_from_time | "2026-04-17T00:00:00" |
| fld_fup_investgr_of_phc_uid | 10003013 |
| fld_fup_supervisor_of_phc_uid | 10003004 |
| hospitalized_ind | "No" |
| hospitalized_ind_cd | "N" |
| init_fld_fup_investgr_of_phc_uid | 10003013 |
| init_fup_investgr_of_phc_uid | 10003010 |
| init_interviewer_of_phc_uid | 10003004 |
| interviewer_of_phc_uid | 10003004 |
| inv_case_status | "Confirmed" |
| inv_state_case_id | "" |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Closed" |
| investigation_status_cd | "C" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| legacy_case_id | "" |
| local_id | "CAS10001000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "17" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:32:00.637" |
| nac_last_chg_time | "2026-04-30T20:09:14.380" |
| nac_page_case_uid | 10009300 |
| org_as_reporter_uid | 10003019 |
| organization_id | 10003019 |
| pat_age_at_onset | "41" |
| pat_age_at_onset_unit | "Years" |
| pat_age_at_onset_unit_cd | "Y" |
| patient_id | 10009296 |
| person_as_reporter_uid | 10003022 |
| pregnant_ind | "Yes" |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T20:09:14.380" |
| referral_basis | "T1 - Positive Test" |
| referral_basis_cd | "T1" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| rpt_form_cmplt_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| surv_investgr_of_phc_uid | 10003010 |
| transmission_mode | "Sexually Transmitted" |
| transmission_mode_cd | "S" |

## 413. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| case_review_status | null | "Ready" |
| case_review_status_date | null | "2026-04-30T20:09:14.247" |
| cc_closed_dt | null | "2026-04-27T00:00:00" |
| refresh_datetime | "2026-04-30T19:50:55.3997377" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| ca_init_intvwr_assgn_dt | "2026-04-25T00:00:00" |
| ca_interviewer_assign_dt | "2026-04-25T00:00:00" |
| ca_patient_intv_status | "I - Interviewed" |
| case_management_uid | 1000 |
| case_oid | 1300100015 |
| case_review_status | "Ready" |
| case_review_status_date | "2026-04-30T20:09:14.247" |
| cc_closed_dt | "2026-04-27T00:00:00" |
| epi_link_id | "1310000026" |
| fl_fup_dispo_dt | "2026-04-25T00:00:00" |
| fl_fup_disposition_cd | "C" |
| fl_fup_disposition_desc | "C - Infected, Brought to Treatment" |
| fl_fup_field_record_num | "1310000026" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_notification_plan_cd | "3 - Dual" |
| fld_foll_up_notification_plan | "3" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Surveillance Follow-up" |
| init_fup_initial_foll_up_cd | "SF" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| pat_intv_status_cd | "I" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| surv_investigator_assgn_dt | "2026-04-24T00:00:00" |
| surv_patient_foll_up | "FF" |
| surv_patient_foll_up_cd | "Field Follow-up" |

## 414. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:09:19.823 |
| LSN | 0x00006c1300001a000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:50:49.297" | "2026-04-30T20:09:14.347" |
| refresh_datetime | "2026-04-30T19:50:55.2386534" | "2026-04-30T20:09:19.7651804" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T20:09:14.347" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 415. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:09:19.827 |
| LSN | 0x00006c1300001a100003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T19:50:49.307" | "2026-04-30T20:09:14.357" |
| refresh_datetime | "2026-04-30T19:50:55.4841056" | "2026-04-30T20:09:19.8310866" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:32:00.600" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| age_reported | 41 |
| age_reported_unit | "Years" |
| age_reported_unit_cd | "Y" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T20:09:14.357" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009296 |
| phone_ext_home | "" |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:09:19.8310866" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| street_address_2 | "" |
| zip | "30033" |

## 416. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T20:09:37.387 |
| LSN | 0x00006c1300001ac0002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:51:08.6100000" | "2026-04-30T20:09:37.2800000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T20:09:37.2800000" |

## 417. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=6 |
| Transaction end | 2026-04-30T20:09:37.387 |
| LSN | 0x00006c1300001ac0002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:51:08.6100000" | "2026-04-30T20:09:37.2800000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:18.7866667" |
| d_patient_key | 6 |
| patient_uid | 10009296 |
| updated_dttm | "2026-04-30T20:09:37.2800000" |

## 418. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:09:37.387 |
| LSN | 0x00006c1300001ac0002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:50:49.297" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 419. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:09:37.387 |
| LSN | 0x00006c1300001ac0002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:09:14.347" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 420. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:09:37.387 |
| LSN | 0x00006c1300001ac0002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T19:50:49.307" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 421. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:09:37.387 |
| LSN | 0x00006c1300001ac0002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:09:14.357" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 422. UPDATE dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=3 |
| Transaction end | 2026-04-30T20:09:37.880 |
| LSN | 0x00006c1300001bf00019 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:51:09.0400000" | "2026-04-30T20:09:37.8566667" |

### Row After Change

| Field | Value |
| --- | --- |
| case_uid | 10009300 |
| created_dttm | "2026-04-30T19:32:19.1500000" |
| d_investigation_key | 3 |
| updated_dttm | "2026-04-30T20:09:37.8566667" |

## 423. DELETE dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:09:37.880 |
| LSN | 0x00006c1300001bf00019 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Open Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_CASE_STATUS | "Confirmed" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:50:49.327" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 424. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:09:37.880 |
| LSN | 0x00006c1300001bf00019 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Closed" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:09:14.380" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 425. UPDATE dbo.nrt_confirmation_method_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:37.910 |
| LSN | 0x00006c1300001c00000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:51:09.0733333" | "2026-04-30T20:09:37.8933333" |

### Row After Change

| Field | Value |
| --- | --- |
| confirmation_method_cd | "LD" |
| created_dttm | "2026-04-30T19:39:42.4533333" |
| d_confirmation_method_key | 4 |
| updated_dttm | "2026-04-30T20:09:37.8933333" |

## 426. DELETE dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T20:09:37.910 |
| LSN | 0x00006c1300001c00000c |

### Deleted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 427. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T20:09:37.910 |
| LSN | 0x00006c1300001c00000c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 428. DELETE dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:38.373 |
| LSN | 0x00006c1300001e080006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 429. INSERT dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:38.443 |
| LSN | 0x00006c1300001e200009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 430. DELETE dbo.LOOKUP_TABLE_N_REPT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:38.757 |
| LSN | 0x00006c1300001ef000bf |

### Deleted Row

| Field | Value |
| --- | --- |
| D_REPT_KEY | 1 |
| PAGE_CASE_UID | 10009307 |

## 431. INSERT dbo.LOOKUP_TABLE_N_REPT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:38.757 |
| LSN | 0x00006c1300001ef000bf |

### Inserted Row

| Field | Value |
| --- | --- |
| D_REPT_KEY | 2 |
| PAGE_CASE_UID | 10009300 |

## 432. INSERT dbo.L_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:38.757 |
| LSN | 0x00006c1300001ef000bf |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| PAGE_CASE_UID | 10009300 |

## 433. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:38.817 |
| LSN | 0x00006c1300001f680007 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_2" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FL_FUP_NOTE | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| PAGE_CASE_UID | 10009300.0 |

## 434. DELETE dbo.LOOKUP_TABLE_N_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:39.310 |
| LSN | 0x00006c13000021280005 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 435. DELETE dbo.D_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:39.337 |
| LSN | 0x00006c13000021880008 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| RSK_ANS_REFUSED_SEX_PARTNER | "No" |
| RSK_NUM_SEX_PARTNER_12MO | "7" |
| RSK_UNK_SEX_PARTNERS | "No" |
| nbs_case_answer_uid | 3259 |

## 436. INSERT dbo.D_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:39.400 |
| LSN | 0x00006c13000021a0000b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| RSK_ANS_REFUSED_SEX_PARTNER | "No" |
| RSK_NUM_SEX_PARTNER_12MO | "7" |
| RSK_UNK_SEX_PARTNERS | "No" |
| nbs_case_answer_uid | 3259 |

## 437. DELETE dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:39.537 |
| LSN | 0x00006c13000023c00008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 438. INSERT dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:39.547 |
| LSN | 0x00006c13000023d80018 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 439. DELETE dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:39.680 |
| LSN | 0x00006c13000025f00006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 440. INSERT dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:39.690 |
| LSN | 0x00006c13000026080009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 441. DELETE dbo.LOOKUP_TABLE_N_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:39.960 |
| LSN | 0x00006c13000027e80005 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 442. DELETE dbo.D_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:39.990 |
| LSN | 0x00006c13000028480006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| nbs_case_answer_uid | 3248 |

## 443. INSERT dbo.D_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:40 |
| LSN | 0x00006c13000028600009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| nbs_case_answer_uid | 3248 |

## 444. DELETE dbo.LOOKUP_TABLE_N_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:41.230 |
| LSN | 0x00006c14000001500005 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 445. DELETE dbo.D_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:41.327 |
| LSN | 0x00006c14000005d80072 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| nbs_case_answer_uid | 3245 |

## 446. INSERT dbo.D_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:41.407 |
| LSN | 0x00006c14000007600016 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| nbs_case_answer_uid | 3245 |

## 447. DELETE dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:41.540 |
| LSN | 0x00006c14000009880008 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 448. INSERT dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:41.547 |
| LSN | 0x00006c14000009a0000b |

### Inserted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 449. DELETE dbo.LOOKUP_TABLE_N_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:41.643 |
| LSN | 0x00006c1400000b480005 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| PAGE_CASE_UID | 10009300 |

## 450. DELETE dbo.D_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:41.667 |
| LSN | 0x00006c1400000ba80008 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| MDH_PREV_STD_HIST | "No" |
| nbs_case_answer_uid | 3254 |

## 451. INSERT dbo.D_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:09:41.677 |
| LSN | 0x00006c1400000bc0000b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| MDH_PREV_STD_HIST | "No" |
| nbs_case_answer_uid | 3254 |

## 452. DELETE dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T20:11:09.167 |
| LSN | 0x00006c1400000cc80017 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 453. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T20:11:09.167 |
| LSN | 0x00006c1400000cc80017 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 454. UPDATE dbo.D_CASE_MANAGEMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:11:09.223 |
| LSN | 0x00006c1400000ce80007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CASE_REVIEW_STATUS | null | "Ready" |
| CASE_REVIEW_STATUS_DATE | null | "2026-04-30" |
| CC_CLOSED_DT | null | "2026-04-27" |

### Row After Change

| Field | Value |
| --- | --- |
| ADD_USER_ID | 10009282.0 |
| CASE_OID | 1300100015.0 |
| CASE_REVIEW_STATUS | "Ready" |
| CASE_REVIEW_STATUS_DATE | "2026-04-30" |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25" |
| CA_PATIENT_INTV_STATUS | "I - Interviewed" |
| CC_CLOSED_DT | "2026-04-27" |
| D_CASE_MANAGEMENT_KEY | 2.0 |
| EPI_LINK_ID | "1310000026" |
| FLD_FOLL_UP_NOTIFICATION_PLAN | "3" |
| FL_FUP_DISPOSITION_CD | "C" |
| FL_FUP_DISPOSITION_DESC | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25" |
| FL_FUP_FIELD_RECORD_NUM | "1310000026" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25" |
| FL_FUP_NOTIFICATION_PLAN_CD | "3 - Dual" |
| INIT_FOLL_UP_NOTIFIABLE | "6-Yes, Notifiable" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE_CD | "06" |
| INVESTIGATION_KEY | 3.0 |
| PAT_INTV_STATUS_CD | "I" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24" |
| SURV_PATIENT_FOLL_UP | "FF" |
| SURV_PATIENT_FOLL_UP_CD | "Field Follow-up" |

## 455. UPDATE dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:11:09.223 |
| LSN | 0x00006c1400000ce80007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T19:52:58.7000000" | "2026-04-30T20:11:09.2166667" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:20.4066667" |
| d_case_management_key | 2 |
| public_health_case_uid | 10009300 |
| updated_dttm | "2026-04-30T20:11:09.2166667" |

## 456. DELETE dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:11:09.377 |
| LSN | 0x00006c1400000d280007 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 1.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 3 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 3 |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 457. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:11:09.377 |
| LSN | 0x00006c1400000d280007 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 2 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 3 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 3 |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 458. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:11:09.470 |
| LSN | 0x00006c1400000d48000c |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:50:49.327" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:50:49.327" |

## 459. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:11:09.470 |
| LSN | 0x00006c1400000d48000c |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:09:14.380" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:09:14.380" |

## 460. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:11:09.477 |
| LSN | 0x00006c1400000d58000a |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T19:50:49.327" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T19:50:49.327" |

## 461. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:11:09.477 |
| LSN | 0x00006c1400000d58000a |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:09:14.380" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:09:14.380" |

## 462. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:11:09.743 |
| LSN | 0x00006c1400000e000004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CURR_PROCESS_STATE | "Open Case" | "Closed Case" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T19:50:49.327" | "2026-04-30T20:09:14.380" |
| INVESTIGATION_STATUS | "Open" | "Closed" |

### Row After Change

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD | "Laboratory confirmed" |
| CURR_PROCESS_STATE | "Closed Case" |
| DIAGNOSIS_DATE | "2026-04-21T00:00:00" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| ILLNESS_ONSET_DATE | "2026-04-17T00:00:00" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T20:09:14.380" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Closed" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 463. UPDATE dbo.STD_HIV_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:12:10.310 |
| LSN | 0x00006c14000017e80004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CC_CLOSED_DT | null | "2026-04-27T00:00:00" |
| CLN_CARE_STATUS_CLOSE_DT | null | "1-In Care" |
| CURR_PROCESS_STATE | "Open Case" | "Closed Case" |
| INVESTIGATION_STATUS | "Open" | "Closed" |
| INVESTIGATOR_CLOSED_KEY | 1 | 2 |
| INVESTIGATOR_CLOSED_QC | null | "1" |
| INV_CLOSE_DT | null | "2026-04-27T00:00:00" |

### Row After Change

| Field | Value |
| --- | --- |
| CALC_5_YEAR_AGE_GROUP | " 9" |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25T00:00:00" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25T00:00:00" |
| CA_PATIENT_INTV_STATUS | "I - Interviewed" |
| CC_CLOSED_DT | "2026-04-27T00:00:00" |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| COINFECTION_ID | "COIN1000XX01" |
| CONDITION_CD | "10312" |
| CONDITION_KEY | 44 |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS | "720 - Syphilis, secondary" |
| DIAGNOSIS_CD | "720" |
| EPI_LINK_ID | "1310000026" |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| FIELD_RECORD_NUMBER | "1310000026" |
| FL_FUP_DISPOSITION | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25T00:00:00" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_NOTIFICATION_PLAN | "3 - Dual" |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| HOSPITAL_KEY | 1 |
| HSPTLIZD_IND | "No" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE | "06" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_STATUS | "Closed" |
| INVESTIGATOR_CLOSED_KEY | 2 |
| INVESTIGATOR_CLOSED_QC | "1" |
| INVESTIGATOR_CURRENT_KEY | 2 |
| INVESTIGATOR_CURRENT_QC | "1" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 2 |
| INVESTIGATOR_DISP_FL_FUP_QC | "1" |
| INVESTIGATOR_FL_FUP_KEY | 4 |
| INVESTIGATOR_FL_FUP_QC | "3" |
| INVESTIGATOR_INITIAL_KEY | 3 |
| INVESTIGATOR_INITIAL_QC | "2" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 4 |
| INVESTIGATOR_INIT_FL_FUP_QC | "3" |
| INVESTIGATOR_INIT_INTRVW_KEY | 2 |
| INVESTIGATOR_INIT_INTRVW_QC | "1" |
| INVESTIGATOR_INTERVIEW_KEY | 2 |
| INVESTIGATOR_INTERVIEW_QC | "1" |
| INVESTIGATOR_SUPER_CASE_KEY | 1 |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 2 |
| INVESTIGATOR_SUPER_FL_FUP_QC | "1" |
| INVESTIGATOR_SURV_KEY | 3 |
| INVESTIGATOR_SURV_QC | "2" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| IX_DATE_OI | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| MDH_PREV_STD_HIST | "No" |
| ORDERING_FACILITY_KEY | 1 |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_AGE_REPORTED | "          41 Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_NAME | "Swift_fake77gg, Taylor" |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_PREGNANT_IND | "Yes" |
| PATIENT_RACE | "White" |
| PATIENT_SEX | "Female" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| PHYSICIAN_FL_FUP_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| REFERRAL_BASIS | "T1 - Positive Test" |
| REPORTING_ORG_KEY | 4 |
| REPORTING_PROV_KEY | 6 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24T00:00:00" |
| SURV_PATIENT_FOLL_UP | "Field Follow-up" |
| TRT_TREATMENT_DATE | "2026-04-20" |

## 464. DELETE dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:12:10.670 |
| LSN | 0x00006c14000018c8000a |

### Deleted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T19:50:49.327" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 465. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:12:10.670 |
| LSN | 0x00006c14000018c8000a |

### Inserted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T20:09:14.380" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 466. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:17:08.243 |
| LSN | 0x00006c1400001ae00014 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7349773" | "2026-04-30T20:17:08.2418651" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580227855 |
| branch_id | 10009292 |
| branch_type_cd | "APND" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:17:08.2418651" |
| root_type_cd | "LabReport" |

## 467. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:17:08.243 |
| LSN | 0x00006c1400001ae00014 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7399421" | "2026-04-30T20:17:08.2418651" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580227855 |
| branch_id | 10009294 |
| branch_type_cd | "COMP" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:17:08.2418651" |
| root_type_cd | "LabReport" |

## 468. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3241 |
| nbs_question_uid | 10001013 |
| nbs_rdb_metadata_uid | 10062226 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012401 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NOT120" |
| question_label | "Immediate National Notifiable Condition" |
| rdb_column_nm | "ADM_IMM_NTNL_NTFBL_CNDTN" |
| rdb_table_nm | "D_INV_ADMINISTRATIVE" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 469. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/20/2026" |
| batch_id | 1777580227855 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3243 |
| nbs_question_uid | 10001192 |
| nbs_rdb_metadata_uid | 10062178 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012367 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD105" |
| question_label | "Treatment Start Date" |
| rdb_column_nm | "TRT_TREATMENT_DATE" |
| rdb_table_nm | "D_INV_TREATMENT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 470. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "720" |
| batch_id | 1777580227855 |
| code_set_group_id | 105450 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3244 |
| nbs_question_uid | 10001195 |
| nbs_rdb_metadata_uid | 10062221 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012398 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS136" |
| question_label | "Diagnosis Reported to CDC" |
| rdb_column_nm | "CLN_CASE_DIAGNOSIS" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 471. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| batch_id | 1777580227855 |
| block_nm | "BLOCK_2" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3274 |
| nbs_question_uid | 10001240 |
| nbs_rdb_metadata_uid | 10062285 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012474 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 2 |
| question_identifier | "NBS185" |
| question_label | "Note" |
| rdb_column_nm | "FL_FUP_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 472. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 20:17~~we need more information before we can close this." |
| batch_id | 1777580227855 |
| block_nm | "BLOCK_8" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:17:00.683" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3275 |
| nbs_question_uid | 10001241 |
| nbs_rdb_metadata_uid | 10062286 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012476 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 8 |
| question_identifier | "NBS268" |
| question_label | "Note" |
| rdb_column_nm | "FIELD_SUPERVISOR_RVW_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 473. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "30" |
| batch_id | 1777580227855 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3242 |
| nbs_question_uid | 10001252 |
| nbs_rdb_metadata_uid | 10062300 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012499 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS128" |
| question_label | "Weeks" |
| rdb_column_nm | "PBI_PATIENT_PREGNANT_WKS" |
| rdb_table_nm | "D_INV_PREGNANCY_BIRTH" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 474. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3250 |
| nbs_question_uid | 10001283 |
| nbs_rdb_metadata_uid | 10062358 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012545 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS242" |
| question_label | "Places to Meet Partners" |
| rdb_column_nm | "SOC_PLACES_TO_MEET_PARTNER" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 475. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "R" |
| batch_id | 1777580227855 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3248 |
| nbs_question_uid | 10001285 |
| nbs_rdb_metadata_uid | 10062360 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012549 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS244" |
| question_label | "Places to Have Sex" |
| rdb_column_nm | "SOC_PLACES_TO_HAVE_SEX" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 476. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580227855 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3255 |
| nbs_question_uid | 10001287 |
| nbs_rdb_metadata_uid | 10062362 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012554 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS223" |
| question_label | "Female Partners (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 477. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580227855 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3257 |
| nbs_question_uid | 10001288 |
| nbs_rdb_metadata_uid | 10062363 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012555 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS224" |
| question_label | "Number Female (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 478. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580227855 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3251 |
| nbs_question_uid | 10001289 |
| nbs_rdb_metadata_uid | 10062364 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012556 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS225" |
| question_label | "Male Partners (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 479. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "5" |
| batch_id | 1777580227855 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3252 |
| nbs_question_uid | 10001290 |
| nbs_rdb_metadata_uid | 10062365 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012557 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS226" |
| question_label | "Number Male (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_TOTAL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 480. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3260 |
| nbs_question_uid | 10001291 |
| nbs_rdb_metadata_uid | 10062366 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012558 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS227" |
| question_label | "Transgender Partners (Past Year)" |
| rdb_column_nm | "SOC_TRANSGNDR_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 481. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "7" |
| batch_id | 1777580227855 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3263 |
| nbs_question_uid | 10001293 |
| nbs_rdb_metadata_uid | 10062368 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012560 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD120" |
| question_label | "Total number of sex partners last 12 months?" |
| rdb_column_nm | "RSK_NUM_SEX_PARTNER_12MO" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 482. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3268 |
| nbs_question_uid | 10001294 |
| nbs_rdb_metadata_uid | 10062370 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012561 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD888" |
| question_label | "Patient refused to answer questions regarding number of sex partners" |
| rdb_column_nm | "RSK_ANS_REFUSED_SEX_PARTNER" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 483. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3259 |
| nbs_question_uid | 10001295 |
| nbs_rdb_metadata_uid | 10062372 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012562 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD999" |
| question_label | "Unknown number of sex partners in last 12 months" |
| rdb_column_nm | "RSK_UNK_SEX_PARTNERS" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 484. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580227855 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3261 |
| nbs_question_uid | 10001296 |
| nbs_rdb_metadata_uid | 10062374 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012564 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS129" |
| question_label | "Female Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 485. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580227855 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3262 |
| nbs_question_uid | 10001297 |
| nbs_rdb_metadata_uid | 10062375 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012565 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS130" |
| question_label | "Number Female (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 486. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580227855 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3266 |
| nbs_question_uid | 10001298 |
| nbs_rdb_metadata_uid | 10062376 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012566 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS131" |
| question_label | "Male Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 487. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580227855 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3267 |
| nbs_question_uid | 10001299 |
| nbs_rdb_metadata_uid | 10062377 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012567 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS132" |
| question_label | "Number Male (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 488. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3264 |
| nbs_question_uid | 10001300 |
| nbs_rdb_metadata_uid | 10062378 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012568 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS133" |
| question_label | "Transgender Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_TRNSGNDR_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 489. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580227855 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3258 |
| nbs_question_uid | 10001302 |
| nbs_rdb_metadata_uid | 10062380 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012571 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD119" |
| question_label | "Met Sex Partners through the Internet" |
| rdb_column_nm | "SOC_SX_PRTNRS_INTNT_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 490. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3254 |
| nbs_question_uid | 10001316 |
| nbs_rdb_metadata_uid | 10062440 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012614 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD117" |
| question_label | "Previous STD history (self-reported)?" |
| rdb_column_nm | "MDH_PREV_STD_HIST" |
| rdb_table_nm | "D_INV_MEDICAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 491. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580227855 |
| code_set_group_id | 105500 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3269 |
| nbs_question_uid | 10001321 |
| nbs_rdb_metadata_uid | 10062446 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012622 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS257" |
| question_label | "Enrolled in Partner Services" |
| rdb_column_nm | "HIV_ENROLL_PRTNR_SRVCS_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 492. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3265 |
| nbs_question_uid | 10001322 |
| nbs_rdb_metadata_uid | 10062447 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012624 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS254" |
| question_label | "Previous 900 Test" |
| rdb_column_nm | "HIV_PREVIOUS_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 493. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580227855 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3247 |
| nbs_question_uid | 10001325 |
| nbs_rdb_metadata_uid | 10062450 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012628 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS260" |
| question_label | "Refer for Test" |
| rdb_column_nm | "HIV_REFER_FOR_900_TEST" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 494. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/24/2026" |
| batch_id | 1777580227855 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3245 |
| nbs_question_uid | 10001326 |
| nbs_rdb_metadata_uid | 10062451 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012629 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS261" |
| question_label | "Referral Date" |
| rdb_column_nm | "HIV_900_TEST_REFERRAL_DT" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 495. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 107870 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3246 |
| nbs_question_uid | 10001327 |
| nbs_rdb_metadata_uid | 10062452 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012630 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS262" |
| question_label | "900 Test" |
| rdb_column_nm | "HIV_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 496. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3249 |
| nbs_question_uid | 10001331 |
| nbs_rdb_metadata_uid | 10062459 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012638 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS266" |
| question_label | "Refer for Care" |
| rdb_column_nm | "HIV_REFER_FOR_900_CARE_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 497. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580227855 |
| code_set_group_id | 107860 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3273 |
| nbs_question_uid | 10003228 |
| nbs_rdb_metadata_uid | 10062296 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012492 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS444" |
| question_label | "Care Status at Case Close Date" |
| rdb_column_nm | "CLN_CARE_STATUS_CLOSE_DT" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 498. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580227855 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3256 |
| nbs_question_uid | 10003230 |
| nbs_rdb_metadata_uid | 10062462 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012642 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS443" |
| question_label | "Is the Client Currently On PrEP?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_IND" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| seq_nbr | 0 |

## 499. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580227855 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| root_type_cd | "TreatmentToPHC" |

## 500. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580227855 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |
| root_type_cd | "IXS" |

## 501. UPDATE dbo.nrt_investigation_confirmation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:17:08.277 |
| LSN | 0x00006c1400001ae8002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7399421" | "2026-04-30T20:17:08.2573628" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580227855 |
| confirmation_method_cd | "LD" |
| confirmation_method_desc_txt | "Laboratory confirmed" |
| confirmation_method_time | "2026-04-24T00:00:00" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:17:08.2573628" |

## 502. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:08.323 |
| LSN | 0x00006c1400001b300002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2824470" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580227855 |
| code_set_group_id | 107900 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:09:14.380" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3253 |
| nbs_question_uid | 10003231 |
| nbs_rdb_metadata_uid | 10062463 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012643 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS446" |
| question_label | "Has Client Been Referred to PrEP Provider?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_REFER" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:17:08.2824470" |
| seq_nbr | 0 |

## 503. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001000GA01", public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:17:08.323 |
| LSN | 0x00006c1400001b300002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777579759399 | 1777580227855 |
| closure_investgr_of_phc_uid | 10003004 | null |
| investigation_status | "Closed" | "Open" |
| investigation_status_cd | "C" | "O" |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:17:00.797" |
| nac_last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:17:00.797" |
| rdb_table_name_list | null | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:17:00.797" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2824470" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-24T00:00:00" |
| activity_to_time | "2026-04-27T00:00:00" |
| add_time | "2026-04-30T19:32:00.637" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777580227855 |
| case_class_cd | "C" |
| case_count | 1 |
| case_management_uid | 1000 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| city_county_case_nbr | "" |
| class_cd | "CASE" |
| coinfection_id | "COIN1000XX01" |
| curr_process_state | "Closed Case" |
| curr_process_state_cd | "CC" |
| detection_method_cd | "21" |
| detection_method_desc_txt | "Self-referral" |
| diagnosis_time | "2026-04-21T00:00:00" |
| dispo_fld_fupinvestgr_of_phc_uid | 10003004 |
| effective_from_time | "2026-04-17T00:00:00" |
| fld_fup_investgr_of_phc_uid | 10003013 |
| fld_fup_supervisor_of_phc_uid | 10003004 |
| hospitalized_ind | "No" |
| hospitalized_ind_cd | "N" |
| init_fld_fup_investgr_of_phc_uid | 10003013 |
| init_fup_investgr_of_phc_uid | 10003010 |
| init_interviewer_of_phc_uid | 10003004 |
| interviewer_of_phc_uid | 10003004 |
| inv_case_status | "Confirmed" |
| inv_state_case_id | "" |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Open" |
| investigation_status_cd | "O" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T20:17:00.797" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| legacy_case_id | "" |
| local_id | "CAS10001000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "17" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:32:00.637" |
| nac_last_chg_time | "2026-04-30T20:17:00.797" |
| nac_page_case_uid | 10009300 |
| org_as_reporter_uid | 10003019 |
| organization_id | 10003019 |
| pat_age_at_onset | "41" |
| pat_age_at_onset_unit | "Years" |
| pat_age_at_onset_unit_cd | "Y" |
| patient_id | 10009296 |
| person_as_reporter_uid | 10003022 |
| pregnant_ind | "Yes" |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T20:17:00.797" |
| referral_basis | "T1 - Positive Test" |
| referral_basis_cd | "T1" |
| refresh_datetime | "2026-04-30T20:17:08.2824470" |
| rpt_form_cmplt_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| surv_investgr_of_phc_uid | 10003010 |
| transmission_mode | "Sexually Transmitted" |
| transmission_mode_cd | "S" |

## 504. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:17:08.323 |
| LSN | 0x00006c1400001b300002 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| case_review_status | "Ready" | "Reject" |
| cc_closed_dt | "2026-04-27T00:00:00" | null |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.2824470" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| ca_init_intvwr_assgn_dt | "2026-04-25T00:00:00" |
| ca_interviewer_assign_dt | "2026-04-25T00:00:00" |
| ca_patient_intv_status | "I - Interviewed" |
| case_management_uid | 1000 |
| case_oid | 1300100015 |
| case_review_status | "Reject" |
| case_review_status_date | "2026-04-30T20:09:14.247" |
| epi_link_id | "1310000026" |
| fl_fup_dispo_dt | "2026-04-25T00:00:00" |
| fl_fup_disposition_cd | "C" |
| fl_fup_disposition_desc | "C - Infected, Brought to Treatment" |
| fl_fup_field_record_num | "1310000026" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_notification_plan_cd | "3 - Dual" |
| fld_foll_up_notification_plan | "3" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Surveillance Follow-up" |
| init_fup_initial_foll_up_cd | "SF" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| pat_intv_status_cd | "I" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:17:08.2824470" |
| surv_investigator_assgn_dt | "2026-04-24T00:00:00" |
| surv_patient_foll_up | "FF" |
| surv_patient_foll_up_cd | "Field Follow-up" |

## 505. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:17:08.343 |
| LSN | 0x00006c1400001b400003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T20:09:14.347" | "2026-04-30T20:17:00.770" |
| refresh_datetime | "2026-04-30T20:09:19.7651804" | "2026-04-30T20:17:08.3434793" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T20:17:00.770" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:17:08.3434793" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 506. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:17:08.507 |
| LSN | 0x00006c1400001b700003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T20:09:14.357" | "2026-04-30T20:17:00.777" |
| refresh_datetime | "2026-04-30T20:09:19.8310866" | "2026-04-30T20:17:08.5070668" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:32:00.600" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| age_reported | 41 |
| age_reported_unit | "Years" |
| age_reported_unit_cd | "Y" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T20:17:00.777" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009296 |
| phone_ext_home | "" |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:17:08.5070668" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| street_address_2 | "" |
| zip | "30033" |

## 507. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T20:17:09.737 |
| LSN | 0x00006c1400001ba0002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:09:37.2800000" | "2026-04-30T20:17:09.6066667" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T20:17:09.6066667" |

## 508. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=6 |
| Transaction end | 2026-04-30T20:17:09.737 |
| LSN | 0x00006c1400001ba0002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:09:37.2800000" | "2026-04-30T20:17:09.6066667" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:18.7866667" |
| d_patient_key | 6 |
| patient_uid | 10009296 |
| updated_dttm | "2026-04-30T20:17:09.6066667" |

## 509. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:17:09.737 |
| LSN | 0x00006c1400001ba0002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:09:14.347" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 510. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:17:09.737 |
| LSN | 0x00006c1400001ba0002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:17:00.770" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 511. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:17:09.737 |
| LSN | 0x00006c1400001ba0002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:09:14.357" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 512. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:17:09.737 |
| LSN | 0x00006c1400001ba0002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:17:00.777" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 513. UPDATE dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=3 |
| Transaction end | 2026-04-30T20:17:10.243 |
| LSN | 0x00006c1400001cc8000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:09:37.8566667" | "2026-04-30T20:17:10.2200000" |

### Row After Change

| Field | Value |
| --- | --- |
| case_uid | 10009300 |
| created_dttm | "2026-04-30T19:32:19.1500000" |
| d_investigation_key | 3 |
| updated_dttm | "2026-04-30T20:17:10.2200000" |

## 514. DELETE dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:17:10.243 |
| LSN | 0x00006c1400001cc8000c |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Closed" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:09:14.380" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 515. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:17:10.243 |
| LSN | 0x00006c1400001cc8000c |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:17:00.797" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 516. UPDATE dbo.nrt_confirmation_method_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:10.273 |
| LSN | 0x00006c1400001cd8000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:09:37.8933333" | "2026-04-30T20:17:10.2600000" |

### Row After Change

| Field | Value |
| --- | --- |
| confirmation_method_cd | "LD" |
| created_dttm | "2026-04-30T19:39:42.4533333" |
| d_confirmation_method_key | 4 |
| updated_dttm | "2026-04-30T20:17:10.2600000" |

## 517. DELETE dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T20:17:10.273 |
| LSN | 0x00006c1400001cd8000c |

### Deleted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 518. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T20:17:10.273 |
| LSN | 0x00006c1400001cd8000c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 519. DELETE dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:10.737 |
| LSN | 0x00006c1400001ee00006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 520. INSERT dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:10.807 |
| LSN | 0x00006c1400001ef80009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 521. DELETE dbo.LOOKUP_TABLE_N_REPT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:11.140 |
| LSN | 0x00006c1400001fd000c6 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_REPT_KEY | 2 |
| PAGE_CASE_UID | 10009300 |

## 522. DELETE dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:11.217 |
| LSN | 0x00006c14000020480007 |

### Deleted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_2" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FL_FUP_NOTE | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| PAGE_CASE_UID | 10009300.0 |

## 523. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:11.217 |
| LSN | 0x00006c14000020480007 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_2" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FL_FUP_NOTE | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| PAGE_CASE_UID | 10009300.0 |

## 524. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:11.217 |
| LSN | 0x00006c14000020480007 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_8" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FIELD_SUPERVISOR_RVW_NOTE | "Ariella Kent~04/30/2026 20:17~~we need more information before we can close this." |
| PAGE_CASE_UID | 10009300.0 |

## 525. DELETE dbo.D_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:12.740 |
| LSN | 0x00006c14000022b00008 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| RSK_ANS_REFUSED_SEX_PARTNER | "No" |
| RSK_NUM_SEX_PARTNER_12MO | "7" |
| RSK_UNK_SEX_PARTNERS | "No" |
| nbs_case_answer_uid | 3259 |

## 526. INSERT dbo.D_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:12.810 |
| LSN | 0x00006c14000022c8000d |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| RSK_ANS_REFUSED_SEX_PARTNER | "No" |
| RSK_NUM_SEX_PARTNER_12MO | "7" |
| RSK_UNK_SEX_PARTNERS | "No" |
| nbs_case_answer_uid | 3259 |

## 527. DELETE dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:12.967 |
| LSN | 0x00006c14000024e80008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 528. INSERT dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:12.983 |
| LSN | 0x00006c1400002500000b |

### Inserted Row

| Field | Value |
| --- | --- |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 529. DELETE dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:13.163 |
| LSN | 0x00006c14000027180006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 530. INSERT dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:13.180 |
| LSN | 0x00006c1400002730000b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 531. DELETE dbo.D_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:14.743 |
| LSN | 0x00006c14000029c00006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| nbs_case_answer_uid | 3248 |

## 532. INSERT dbo.D_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:14.817 |
| LSN | 0x00006c14000029d80009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| nbs_case_answer_uid | 3248 |

## 533. DELETE dbo.D_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:14.960 |
| LSN | 0x00006c1400002c000006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| nbs_case_answer_uid | 3245 |

## 534. INSERT dbo.D_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:14.970 |
| LSN | 0x00006c1400002c180009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| nbs_case_answer_uid | 3245 |

## 535. DELETE dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:15.100 |
| LSN | 0x00006c15000001380008 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 536. INSERT dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:15.107 |
| LSN | 0x00006c1500000150000b |

### Inserted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 537. DELETE dbo.D_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:15.237 |
| LSN | 0x00006c15000003580008 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| MDH_PREV_STD_HIST | "No" |
| nbs_case_answer_uid | 3254 |

## 538. INSERT dbo.D_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:17:15.243 |
| LSN | 0x00006c1500000370000b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| MDH_PREV_STD_HIST | "No" |
| nbs_case_answer_uid | 3254 |

## 539. DELETE dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T20:18:39.447 |
| LSN | 0x00006c1500000b300007 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 540. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T20:18:39.447 |
| LSN | 0x00006c1500000b300007 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 541. UPDATE dbo.D_CASE_MANAGEMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:18:39.507 |
| LSN | 0x00006c1500000b500007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CASE_REVIEW_STATUS | "Ready" | "Reject" |
| CC_CLOSED_DT | "2026-04-27" | null |

### Row After Change

| Field | Value |
| --- | --- |
| ADD_USER_ID | 10009282.0 |
| CASE_OID | 1300100015.0 |
| CASE_REVIEW_STATUS | "Reject" |
| CASE_REVIEW_STATUS_DATE | "2026-04-30" |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25" |
| CA_PATIENT_INTV_STATUS | "I - Interviewed" |
| D_CASE_MANAGEMENT_KEY | 2.0 |
| EPI_LINK_ID | "1310000026" |
| FLD_FOLL_UP_NOTIFICATION_PLAN | "3" |
| FL_FUP_DISPOSITION_CD | "C" |
| FL_FUP_DISPOSITION_DESC | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25" |
| FL_FUP_FIELD_RECORD_NUM | "1310000026" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25" |
| FL_FUP_NOTIFICATION_PLAN_CD | "3 - Dual" |
| INIT_FOLL_UP_NOTIFIABLE | "6-Yes, Notifiable" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE_CD | "06" |
| INVESTIGATION_KEY | 3.0 |
| PAT_INTV_STATUS_CD | "I" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24" |
| SURV_PATIENT_FOLL_UP | "FF" |
| SURV_PATIENT_FOLL_UP_CD | "Field Follow-up" |

## 542. UPDATE dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:18:39.507 |
| LSN | 0x00006c1500000b500007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:11:09.2166667" | "2026-04-30T20:18:39.5000000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:20.4066667" |
| d_case_management_key | 2 |
| public_health_case_uid | 10009300 |
| updated_dttm | "2026-04-30T20:18:39.5000000" |

## 543. DELETE dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:18:39.650 |
| LSN | 0x00006c1500000b900007 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 2 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 3 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 3 |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 544. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:18:39.650 |
| LSN | 0x00006c1500000b900007 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 3 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 3 |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 545. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:18:39.737 |
| LSN | 0x00006c1500000bb0000a |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:09:14.380" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:09:14.380" |

## 546. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:18:39.737 |
| LSN | 0x00006c1500000bb0000a |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:17:00.797" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:17:00.797" |

## 547. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:18:39.747 |
| LSN | 0x00006c1500000bc0000a |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:09:14.380" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:09:14.380" |

## 548. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:18:39.747 |
| LSN | 0x00006c1500000bc0000a |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:17:00.797" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:17:00.797" |

## 549. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:18:39.987 |
| LSN | 0x00006c1500000c600004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T20:09:14.380" | "2026-04-30T20:17:00.797" |
| INVESTIGATION_STATUS | "Closed" | "Open" |

### Row After Change

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD | "Laboratory confirmed" |
| CURR_PROCESS_STATE | "Closed Case" |
| DIAGNOSIS_DATE | "2026-04-21T00:00:00" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| ILLNESS_ONSET_DATE | "2026-04-17T00:00:00" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T20:17:00.797" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Open" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 550. UPDATE dbo.STD_HIV_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:19:40.503 |
| LSN | 0x00006c15000016200004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CC_CLOSED_DT | "2026-04-27T00:00:00" | null |
| INVESTIGATION_STATUS | "Closed" | "Open" |
| INVESTIGATOR_CLOSED_KEY | 2 | 1 |
| INVESTIGATOR_CLOSED_QC | "1" | null |

### Row After Change

| Field | Value |
| --- | --- |
| CALC_5_YEAR_AGE_GROUP | " 9" |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25T00:00:00" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25T00:00:00" |
| CA_PATIENT_INTV_STATUS | "I - Interviewed" |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| COINFECTION_ID | "COIN1000XX01" |
| CONDITION_CD | "10312" |
| CONDITION_KEY | 44 |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS | "720 - Syphilis, secondary" |
| DIAGNOSIS_CD | "720" |
| EPI_LINK_ID | "1310000026" |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| FIELD_RECORD_NUMBER | "1310000026" |
| FL_FUP_DISPOSITION | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25T00:00:00" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_NOTIFICATION_PLAN | "3 - Dual" |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| HOSPITAL_KEY | 1 |
| HSPTLIZD_IND | "No" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE | "06" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_STATUS | "Open" |
| INVESTIGATOR_CLOSED_KEY | 1 |
| INVESTIGATOR_CURRENT_KEY | 2 |
| INVESTIGATOR_CURRENT_QC | "1" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 2 |
| INVESTIGATOR_DISP_FL_FUP_QC | "1" |
| INVESTIGATOR_FL_FUP_KEY | 4 |
| INVESTIGATOR_FL_FUP_QC | "3" |
| INVESTIGATOR_INITIAL_KEY | 3 |
| INVESTIGATOR_INITIAL_QC | "2" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 4 |
| INVESTIGATOR_INIT_FL_FUP_QC | "3" |
| INVESTIGATOR_INIT_INTRVW_KEY | 2 |
| INVESTIGATOR_INIT_INTRVW_QC | "1" |
| INVESTIGATOR_INTERVIEW_KEY | 2 |
| INVESTIGATOR_INTERVIEW_QC | "1" |
| INVESTIGATOR_SUPER_CASE_KEY | 1 |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 2 |
| INVESTIGATOR_SUPER_FL_FUP_QC | "1" |
| INVESTIGATOR_SURV_KEY | 3 |
| INVESTIGATOR_SURV_QC | "2" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| IX_DATE_OI | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| MDH_PREV_STD_HIST | "No" |
| ORDERING_FACILITY_KEY | 1 |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_AGE_REPORTED | "          41 Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_NAME | "Swift_fake77gg, Taylor" |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_PREGNANT_IND | "Yes" |
| PATIENT_RACE | "White" |
| PATIENT_SEX | "Female" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| PHYSICIAN_FL_FUP_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| REFERRAL_BASIS | "T1 - Positive Test" |
| REPORTING_ORG_KEY | 4 |
| REPORTING_PROV_KEY | 6 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24T00:00:00" |
| SURV_PATIENT_FOLL_UP | "Field Follow-up" |
| TRT_TREATMENT_DATE | "2026-04-20" |

## 551. DELETE dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:19:40.863 |
| LSN | 0x00006c1500001700000f |

### Deleted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T20:09:14.380" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 552. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:19:40.863 |
| LSN | 0x00006c1500001700000f |

### Inserted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T20:17:00.797" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 553. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.543 |
| LSN | 0x00006c15000018800004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| refresh_datetime | "2026-04-30T20:17:08.2418651" | "2026-04-30T20:22:52.5410577" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580572198 |
| branch_id | 10009292 |
| branch_type_cd | "APND" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.5410577" |
| root_type_cd | "LabReport" |

## 554. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.543 |
| LSN | 0x00006c15000018800004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| refresh_datetime | "2026-04-30T20:17:08.2418651" | "2026-04-30T20:22:52.5410577" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580572198 |
| branch_id | 10009294 |
| branch_type_cd | "COMP" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.5410577" |
| root_type_cd | "LabReport" |

## 555. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.577 |
| LSN | 0x00006c15000018a0000f |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.5560887" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3241 |
| nbs_question_uid | 10001013 |
| nbs_rdb_metadata_uid | 10062226 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012401 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NOT120" |
| question_label | "Immediate National Notifiable Condition" |
| rdb_column_nm | "ADM_IMM_NTNL_NTFBL_CNDTN" |
| rdb_table_nm | "D_INV_ADMINISTRATIVE" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.5560887" |
| seq_nbr | 0 |

## 556. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.577 |
| LSN | 0x00006c15000018a0000f |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.5560887" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/20/2026" |
| batch_id | 1777580572198 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3243 |
| nbs_question_uid | 10001192 |
| nbs_rdb_metadata_uid | 10062178 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012367 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD105" |
| question_label | "Treatment Start Date" |
| rdb_column_nm | "TRT_TREATMENT_DATE" |
| rdb_table_nm | "D_INV_TREATMENT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.5560887" |
| seq_nbr | 0 |

## 557. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.577 |
| LSN | 0x00006c15000018a0000f |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.5560887" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "720" |
| batch_id | 1777580572198 |
| code_set_group_id | 105450 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3244 |
| nbs_question_uid | 10001195 |
| nbs_rdb_metadata_uid | 10062221 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012398 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS136" |
| question_label | "Diagnosis Reported to CDC" |
| rdb_column_nm | "CLN_CASE_DIAGNOSIS" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.5560887" |
| seq_nbr | 0 |

## 558. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.577 |
| LSN | 0x00006c15000018a0000f |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.5560887" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| batch_id | 1777580572198 |
| block_nm | "BLOCK_2" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3274 |
| nbs_question_uid | 10001240 |
| nbs_rdb_metadata_uid | 10062285 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012474 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 2 |
| question_identifier | "NBS185" |
| question_label | "Note" |
| rdb_column_nm | "FL_FUP_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.5560887" |
| seq_nbr | 0 |

## 559. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.577 |
| LSN | 0x00006c15000018a0000f |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580572198 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.5560887" |
| root_type_cd | "TreatmentToPHC" |

## 560. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.577 |
| LSN | 0x00006c15000018a0000f |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580572198 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.5560887" |
| root_type_cd | "IXS" |

## 561. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.577 |
| LSN | 0x00006c15000018a0000f |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580572198 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.5560887" |
| root_type_cd | "Notification" |

## 562. UPDATE dbo.nrt_investigation_confirmation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.577 |
| LSN | 0x00006c15000018a0000f |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.5560887" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580572198 |
| confirmation_method_cd | "LD" |
| confirmation_method_desc_txt | "Laboratory confirmed" |
| confirmation_method_time | "2026-04-24T00:00:00" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.5560887" |

## 563. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 20:17~~we need more information before we can close this." |
| batch_id | 1777580572198 |
| block_nm | "BLOCK_8" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:17:00.683" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3275 |
| nbs_question_uid | 10001241 |
| nbs_rdb_metadata_uid | 10062286 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012476 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 8 |
| question_identifier | "NBS268" |
| question_label | "Note" |
| rdb_column_nm | "FIELD_SUPERVISOR_RVW_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 564. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:22~~here are some more notes" |
| batch_id | 1777580572198 |
| block_nm | "BLOCK_3" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3279 |
| nbs_question_uid | 10001248 |
| nbs_rdb_metadata_uid | 10062293 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012486 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 3 |
| question_identifier | "NBS195" |
| question_label | "Note" |
| rdb_column_nm | "IX_INV_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 565. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "30" |
| batch_id | 1777580572198 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3242 |
| nbs_question_uid | 10001252 |
| nbs_rdb_metadata_uid | 10062300 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012499 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS128" |
| question_label | "Weeks" |
| rdb_column_nm | "PBI_PATIENT_PREGNANT_WKS" |
| rdb_table_nm | "D_INV_PREGNANCY_BIRTH" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 566. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580572198 |
| code_set_group_id | 105680 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3277 |
| nbs_question_uid | 10001261 |
| nbs_rdb_metadata_uid | 10062318 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012516 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS229" |
| question_label | "Was Behavioral Risk Assessed" |
| rdb_column_nm | "RSK_RISK_FACTORS_ASSESS_IND" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 567. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 105360 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3278 |
| nbs_question_uid | 10001274 |
| nbs_rdb_metadata_uid | 10062340 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012534 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS233" |
| question_label | "No drug use reported" |
| rdb_column_nm | "RSK_NO_DRUG_USE_12MO_IND" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 568. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3250 |
| nbs_question_uid | 10001283 |
| nbs_rdb_metadata_uid | 10062358 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012545 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS242" |
| question_label | "Places to Meet Partners" |
| rdb_column_nm | "SOC_PLACES_TO_MEET_PARTNER" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 569. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "R" |
| batch_id | 1777580572198 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3248 |
| nbs_question_uid | 10001285 |
| nbs_rdb_metadata_uid | 10062360 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012549 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS244" |
| question_label | "Places to Have Sex" |
| rdb_column_nm | "SOC_PLACES_TO_HAVE_SEX" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 570. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572198 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3255 |
| nbs_question_uid | 10001287 |
| nbs_rdb_metadata_uid | 10062362 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012554 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS223" |
| question_label | "Female Partners (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 571. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580572198 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3257 |
| nbs_question_uid | 10001288 |
| nbs_rdb_metadata_uid | 10062363 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012555 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS224" |
| question_label | "Number Female (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 572. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572198 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3251 |
| nbs_question_uid | 10001289 |
| nbs_rdb_metadata_uid | 10062364 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012556 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS225" |
| question_label | "Male Partners (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 573. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "5" |
| batch_id | 1777580572198 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3252 |
| nbs_question_uid | 10001290 |
| nbs_rdb_metadata_uid | 10062365 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012557 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS226" |
| question_label | "Number Male (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_TOTAL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 574. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3260 |
| nbs_question_uid | 10001291 |
| nbs_rdb_metadata_uid | 10062366 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012558 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS227" |
| question_label | "Transgender Partners (Past Year)" |
| rdb_column_nm | "SOC_TRANSGNDR_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 575. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "7" |
| batch_id | 1777580572198 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3263 |
| nbs_question_uid | 10001293 |
| nbs_rdb_metadata_uid | 10062368 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012560 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD120" |
| question_label | "Total number of sex partners last 12 months?" |
| rdb_column_nm | "RSK_NUM_SEX_PARTNER_12MO" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 576. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3268 |
| nbs_question_uid | 10001294 |
| nbs_rdb_metadata_uid | 10062370 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012561 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD888" |
| question_label | "Patient refused to answer questions regarding number of sex partners" |
| rdb_column_nm | "RSK_ANS_REFUSED_SEX_PARTNER" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 577. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3259 |
| nbs_question_uid | 10001295 |
| nbs_rdb_metadata_uid | 10062372 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012562 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD999" |
| question_label | "Unknown number of sex partners in last 12 months" |
| rdb_column_nm | "RSK_UNK_SEX_PARTNERS" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 578. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572198 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3261 |
| nbs_question_uid | 10001296 |
| nbs_rdb_metadata_uid | 10062374 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012564 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS129" |
| question_label | "Female Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 579. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580572198 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3262 |
| nbs_question_uid | 10001297 |
| nbs_rdb_metadata_uid | 10062375 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012565 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS130" |
| question_label | "Number Female (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 580. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572198 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3266 |
| nbs_question_uid | 10001298 |
| nbs_rdb_metadata_uid | 10062376 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012566 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS131" |
| question_label | "Male Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 581. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580572198 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3267 |
| nbs_question_uid | 10001299 |
| nbs_rdb_metadata_uid | 10062377 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012567 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS132" |
| question_label | "Number Male (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 582. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3264 |
| nbs_question_uid | 10001300 |
| nbs_rdb_metadata_uid | 10062378 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012568 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS133" |
| question_label | "Transgender Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_TRNSGNDR_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 583. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572198 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3258 |
| nbs_question_uid | 10001302 |
| nbs_rdb_metadata_uid | 10062380 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012571 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD119" |
| question_label | "Met Sex Partners through the Internet" |
| rdb_column_nm | "SOC_SX_PRTNRS_INTNT_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 584. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3254 |
| nbs_question_uid | 10001316 |
| nbs_rdb_metadata_uid | 10062440 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012614 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD117" |
| question_label | "Previous STD history (self-reported)?" |
| rdb_column_nm | "MDH_PREV_STD_HIST" |
| rdb_table_nm | "D_INV_MEDICAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 585. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580572198 |
| code_set_group_id | 105500 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3269 |
| nbs_question_uid | 10001321 |
| nbs_rdb_metadata_uid | 10062446 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012622 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS257" |
| question_label | "Enrolled in Partner Services" |
| rdb_column_nm | "HIV_ENROLL_PRTNR_SRVCS_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 586. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3265 |
| nbs_question_uid | 10001322 |
| nbs_rdb_metadata_uid | 10062447 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012624 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS254" |
| question_label | "Previous 900 Test" |
| rdb_column_nm | "HIV_PREVIOUS_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 587. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572198 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3247 |
| nbs_question_uid | 10001325 |
| nbs_rdb_metadata_uid | 10062450 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012628 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS260" |
| question_label | "Refer for Test" |
| rdb_column_nm | "HIV_REFER_FOR_900_TEST" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 588. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/24/2026" |
| batch_id | 1777580572198 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3245 |
| nbs_question_uid | 10001326 |
| nbs_rdb_metadata_uid | 10062451 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012629 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS261" |
| question_label | "Referral Date" |
| rdb_column_nm | "HIV_900_TEST_REFERRAL_DT" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 589. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 107870 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3246 |
| nbs_question_uid | 10001327 |
| nbs_rdb_metadata_uid | 10062452 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012630 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS262" |
| question_label | "900 Test" |
| rdb_column_nm | "HIV_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 590. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3249 |
| nbs_question_uid | 10001331 |
| nbs_rdb_metadata_uid | 10062459 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012638 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS266" |
| question_label | "Refer for Care" |
| rdb_column_nm | "HIV_REFER_FOR_900_CARE_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 591. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580572198 |
| code_set_group_id | 107860 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3273 |
| nbs_question_uid | 10003228 |
| nbs_rdb_metadata_uid | 10062296 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012492 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS444" |
| question_label | "Care Status at Case Close Date" |
| rdb_column_nm | "CLN_CARE_STATUS_CLOSE_DT" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 592. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2573628" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572198 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3256 |
| nbs_question_uid | 10003230 |
| nbs_rdb_metadata_uid | 10062462 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012642 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS443" |
| question_label | "Is the Client Currently On PrEP?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_IND" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 593. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| last_chg_time | "2026-04-30T20:09:14.380" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2824470" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580572198 |
| code_set_group_id | 107900 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3253 |
| nbs_question_uid | 10003231 |
| nbs_rdb_metadata_uid | 10062463 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012643 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS446" |
| question_label | "Has Client Been Referred to PrEP Provider?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_REFER" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| seq_nbr | 0 |

## 594. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001000GA01", public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580227855 | 1777580572198 |
| closure_investgr_of_phc_uid | null | 10003004 |
| investigation_status | "Open" | "Closed" |
| investigation_status_cd | "O" | "C" |
| last_chg_time | "2026-04-30T20:17:00.797" | "2026-04-30T20:22:47.510" |
| nac_last_chg_time | "2026-04-30T20:17:00.797" | "2026-04-30T20:22:47.510" |
| rdb_table_name_list | null | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_time | "2026-04-30T20:17:00.797" | "2026-04-30T20:22:47.510" |
| refresh_datetime | "2026-04-30T20:17:08.2824470" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-24T00:00:00" |
| activity_to_time | "2026-04-27T00:00:00" |
| add_time | "2026-04-30T19:32:00.637" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777580572198 |
| case_class_cd | "C" |
| case_count | 1 |
| case_management_uid | 1000 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| city_county_case_nbr | "" |
| class_cd | "CASE" |
| closure_investgr_of_phc_uid | 10003004 |
| coinfection_id | "COIN1000XX01" |
| curr_process_state | "Closed Case" |
| curr_process_state_cd | "CC" |
| detection_method_cd | "21" |
| detection_method_desc_txt | "Self-referral" |
| diagnosis_time | "2026-04-21T00:00:00" |
| dispo_fld_fupinvestgr_of_phc_uid | 10003004 |
| effective_from_time | "2026-04-17T00:00:00" |
| fld_fup_investgr_of_phc_uid | 10003013 |
| fld_fup_supervisor_of_phc_uid | 10003004 |
| hospitalized_ind | "No" |
| hospitalized_ind_cd | "N" |
| init_fld_fup_investgr_of_phc_uid | 10003013 |
| init_fup_investgr_of_phc_uid | 10003010 |
| init_interviewer_of_phc_uid | 10003004 |
| interviewer_of_phc_uid | 10003004 |
| inv_case_status | "Confirmed" |
| inv_state_case_id | "" |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Closed" |
| investigation_status_cd | "C" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| legacy_case_id | "" |
| local_id | "CAS10001000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "17" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:32:00.637" |
| nac_last_chg_time | "2026-04-30T20:22:47.510" |
| nac_page_case_uid | 10009300 |
| org_as_reporter_uid | 10003019 |
| organization_id | 10003019 |
| pat_age_at_onset | "41" |
| pat_age_at_onset_unit | "Years" |
| pat_age_at_onset_unit_cd | "Y" |
| patient_id | 10009296 |
| person_as_reporter_uid | 10003022 |
| pregnant_ind | "Yes" |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T20:22:47.510" |
| referral_basis | "T1 - Positive Test" |
| referral_basis_cd | "T1" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| rpt_form_cmplt_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| surv_investgr_of_phc_uid | 10003010 |
| transmission_mode | "Sexually Transmitted" |
| transmission_mode_cd | "S" |

## 595. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| case_review_status | "Reject" | "Ready" |
| case_review_status_date | "2026-04-30T20:09:14.247" | "2026-04-30T20:22:47.477" |
| cc_closed_dt | null | "2026-04-27T00:00:00" |
| refresh_datetime | "2026-04-30T20:17:08.2824470" | "2026-04-30T20:22:52.6520686" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| ca_init_intvwr_assgn_dt | "2026-04-25T00:00:00" |
| ca_interviewer_assign_dt | "2026-04-25T00:00:00" |
| ca_patient_intv_status | "I - Interviewed" |
| case_management_uid | 1000 |
| case_oid | 1300100015 |
| case_review_status | "Ready" |
| case_review_status_date | "2026-04-30T20:22:47.477" |
| cc_closed_dt | "2026-04-27T00:00:00" |
| epi_link_id | "1310000026" |
| fl_fup_dispo_dt | "2026-04-25T00:00:00" |
| fl_fup_disposition_cd | "C" |
| fl_fup_disposition_desc | "C - Infected, Brought to Treatment" |
| fl_fup_field_record_num | "1310000026" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_notification_plan_cd | "3 - Dual" |
| fld_foll_up_notification_plan | "3" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Surveillance Follow-up" |
| init_fup_initial_foll_up_cd | "SF" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| pat_intv_status_cd | "I" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| surv_investigator_assgn_dt | "2026-04-24T00:00:00" |
| surv_patient_foll_up | "FF" |
| surv_patient_foll_up_cd | "Field Follow-up" |

## 596. INSERT dbo.nrt_investigation_notification

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.880 |
| LSN | 0x00006c150000190000a0 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_type_cd | "Notification" |
| condition_cd | "10312" |
| condition_desc | "Syphilis, secondary" |
| first_notification_date | "2026-04-30T20:22:48.217" |
| first_notification_status | "APPROVED" |
| first_notification_submitted_by | 10009282 |
| jurisdiction_cd | "130001" |
| last_notification_date | "2026-04-30T20:22:48.217" |
| last_notification_submitted_by | 10009282 |
| local_patient_id | "PSN10067000GA01" |
| local_patient_uid | 10009296 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| notif_add_time | "2026-04-30T20:22:48.217" |
| notif_add_user_id | 10009282 |
| notif_add_user_name | "Kent, Ariella" |
| notif_comments | "tell the CDC about this" |
| notif_created_count | 1 |
| notif_created_pending_count | 0 |
| notif_last_chg_time | "2026-04-30T20:22:48.217" |
| notif_last_chg_user_id | 10009282 |
| notif_last_chg_user_name | "Kent, Ariella" |
| notif_local_id | "NOT10000000GA01" |
| notif_rejected_count | 0 |
| notif_sent_count | 0 |
| notif_status | "APPROVED" |
| notification_uid | 10009311 |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| record_status_time | "2026-04-30T20:22:48.217" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| source_act_uid | 10009311 |
| source_class_cd | "NOTF" |
| status_cd | "A" |
| status_time | "2026-04-30T20:22:48.207" |
| target_class_cd | "CASE" |

## 597. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:22:52.900 |
| LSN | 0x00006c15000019500003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T20:17:00.770" | "2026-04-30T20:22:47.497" |
| refresh_datetime | "2026-04-30T20:17:08.3434793" | "2026-04-30T20:22:52.8995270" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T20:22:47.497" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:22:52.8995270" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 598. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.5560887" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3241 |
| nbs_question_uid | 10001013 |
| nbs_rdb_metadata_uid | 10062226 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012401 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NOT120" |
| question_label | "Immediate National Notifiable Condition" |
| rdb_column_nm | "ADM_IMM_NTNL_NTFBL_CNDTN" |
| rdb_table_nm | "D_INV_ADMINISTRATIVE" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 599. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.5560887" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/20/2026" |
| batch_id | 1777580572200 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3243 |
| nbs_question_uid | 10001192 |
| nbs_rdb_metadata_uid | 10062178 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012367 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD105" |
| question_label | "Treatment Start Date" |
| rdb_column_nm | "TRT_TREATMENT_DATE" |
| rdb_table_nm | "D_INV_TREATMENT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 600. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.5560887" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "720" |
| batch_id | 1777580572200 |
| code_set_group_id | 105450 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3244 |
| nbs_question_uid | 10001195 |
| nbs_rdb_metadata_uid | 10062221 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012398 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS136" |
| question_label | "Diagnosis Reported to CDC" |
| rdb_column_nm | "CLN_CASE_DIAGNOSIS" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 601. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.5560887" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| batch_id | 1777580572200 |
| block_nm | "BLOCK_2" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3274 |
| nbs_question_uid | 10001240 |
| nbs_rdb_metadata_uid | 10062285 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012474 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 2 |
| question_identifier | "NBS185" |
| question_label | "Note" |
| rdb_column_nm | "FL_FUP_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 602. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 20:17~~we need more information before we can close this." |
| batch_id | 1777580572200 |
| block_nm | "BLOCK_8" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:17:00.683" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3275 |
| nbs_question_uid | 10001241 |
| nbs_rdb_metadata_uid | 10062286 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012476 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 8 |
| question_identifier | "NBS268" |
| question_label | "Note" |
| rdb_column_nm | "FIELD_SUPERVISOR_RVW_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 603. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:22~~here are some more notes" |
| batch_id | 1777580572200 |
| block_nm | "BLOCK_3" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3279 |
| nbs_question_uid | 10001248 |
| nbs_rdb_metadata_uid | 10062293 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012486 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 3 |
| question_identifier | "NBS195" |
| question_label | "Note" |
| rdb_column_nm | "IX_INV_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 604. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "30" |
| batch_id | 1777580572200 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3242 |
| nbs_question_uid | 10001252 |
| nbs_rdb_metadata_uid | 10062300 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012499 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS128" |
| question_label | "Weeks" |
| rdb_column_nm | "PBI_PATIENT_PREGNANT_WKS" |
| rdb_table_nm | "D_INV_PREGNANCY_BIRTH" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 605. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580572200 |
| code_set_group_id | 105680 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3277 |
| nbs_question_uid | 10001261 |
| nbs_rdb_metadata_uid | 10062318 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012516 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS229" |
| question_label | "Was Behavioral Risk Assessed" |
| rdb_column_nm | "RSK_RISK_FACTORS_ASSESS_IND" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 606. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 105360 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3278 |
| nbs_question_uid | 10001274 |
| nbs_rdb_metadata_uid | 10062340 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012534 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS233" |
| question_label | "No drug use reported" |
| rdb_column_nm | "RSK_NO_DRUG_USE_12MO_IND" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 607. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3250 |
| nbs_question_uid | 10001283 |
| nbs_rdb_metadata_uid | 10062358 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012545 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS242" |
| question_label | "Places to Meet Partners" |
| rdb_column_nm | "SOC_PLACES_TO_MEET_PARTNER" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 608. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "R" |
| batch_id | 1777580572200 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3248 |
| nbs_question_uid | 10001285 |
| nbs_rdb_metadata_uid | 10062360 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012549 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS244" |
| question_label | "Places to Have Sex" |
| rdb_column_nm | "SOC_PLACES_TO_HAVE_SEX" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 609. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572200 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3255 |
| nbs_question_uid | 10001287 |
| nbs_rdb_metadata_uid | 10062362 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012554 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS223" |
| question_label | "Female Partners (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 610. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580572200 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3257 |
| nbs_question_uid | 10001288 |
| nbs_rdb_metadata_uid | 10062363 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012555 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS224" |
| question_label | "Number Female (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 611. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572200 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3251 |
| nbs_question_uid | 10001289 |
| nbs_rdb_metadata_uid | 10062364 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012556 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS225" |
| question_label | "Male Partners (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 612. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "5" |
| batch_id | 1777580572200 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3252 |
| nbs_question_uid | 10001290 |
| nbs_rdb_metadata_uid | 10062365 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012557 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS226" |
| question_label | "Number Male (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_TOTAL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 613. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3260 |
| nbs_question_uid | 10001291 |
| nbs_rdb_metadata_uid | 10062366 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012558 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS227" |
| question_label | "Transgender Partners (Past Year)" |
| rdb_column_nm | "SOC_TRANSGNDR_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 614. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "7" |
| batch_id | 1777580572200 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3263 |
| nbs_question_uid | 10001293 |
| nbs_rdb_metadata_uid | 10062368 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012560 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD120" |
| question_label | "Total number of sex partners last 12 months?" |
| rdb_column_nm | "RSK_NUM_SEX_PARTNER_12MO" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 615. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3268 |
| nbs_question_uid | 10001294 |
| nbs_rdb_metadata_uid | 10062370 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012561 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD888" |
| question_label | "Patient refused to answer questions regarding number of sex partners" |
| rdb_column_nm | "RSK_ANS_REFUSED_SEX_PARTNER" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 616. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3259 |
| nbs_question_uid | 10001295 |
| nbs_rdb_metadata_uid | 10062372 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012562 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD999" |
| question_label | "Unknown number of sex partners in last 12 months" |
| rdb_column_nm | "RSK_UNK_SEX_PARTNERS" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 617. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572200 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3261 |
| nbs_question_uid | 10001296 |
| nbs_rdb_metadata_uid | 10062374 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012564 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS129" |
| question_label | "Female Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 618. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580572200 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3262 |
| nbs_question_uid | 10001297 |
| nbs_rdb_metadata_uid | 10062375 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012565 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS130" |
| question_label | "Number Female (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 619. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572200 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3266 |
| nbs_question_uid | 10001298 |
| nbs_rdb_metadata_uid | 10062376 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012566 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS131" |
| question_label | "Male Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 620. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580572200 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3267 |
| nbs_question_uid | 10001299 |
| nbs_rdb_metadata_uid | 10062377 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012567 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS132" |
| question_label | "Number Male (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 621. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3264 |
| nbs_question_uid | 10001300 |
| nbs_rdb_metadata_uid | 10062378 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012568 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS133" |
| question_label | "Transgender Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_TRNSGNDR_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 622. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572200 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3258 |
| nbs_question_uid | 10001302 |
| nbs_rdb_metadata_uid | 10062380 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012571 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD119" |
| question_label | "Met Sex Partners through the Internet" |
| rdb_column_nm | "SOC_SX_PRTNRS_INTNT_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 623. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3254 |
| nbs_question_uid | 10001316 |
| nbs_rdb_metadata_uid | 10062440 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012614 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD117" |
| question_label | "Previous STD history (self-reported)?" |
| rdb_column_nm | "MDH_PREV_STD_HIST" |
| rdb_table_nm | "D_INV_MEDICAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 624. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580572200 |
| code_set_group_id | 105500 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3269 |
| nbs_question_uid | 10001321 |
| nbs_rdb_metadata_uid | 10062446 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012622 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS257" |
| question_label | "Enrolled in Partner Services" |
| rdb_column_nm | "HIV_ENROLL_PRTNR_SRVCS_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 625. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3265 |
| nbs_question_uid | 10001322 |
| nbs_rdb_metadata_uid | 10062447 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012624 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS254" |
| question_label | "Previous 900 Test" |
| rdb_column_nm | "HIV_PREVIOUS_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 626. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580572200 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3247 |
| nbs_question_uid | 10001325 |
| nbs_rdb_metadata_uid | 10062450 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012628 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS260" |
| question_label | "Refer for Test" |
| rdb_column_nm | "HIV_REFER_FOR_900_TEST" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 627. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/24/2026" |
| batch_id | 1777580572200 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3245 |
| nbs_question_uid | 10001326 |
| nbs_rdb_metadata_uid | 10062451 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012629 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS261" |
| question_label | "Referral Date" |
| rdb_column_nm | "HIV_900_TEST_REFERRAL_DT" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 628. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 107870 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3246 |
| nbs_question_uid | 10001327 |
| nbs_rdb_metadata_uid | 10062452 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012630 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS262" |
| question_label | "900 Test" |
| rdb_column_nm | "HIV_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 629. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3249 |
| nbs_question_uid | 10001331 |
| nbs_rdb_metadata_uid | 10062459 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012638 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS266" |
| question_label | "Refer for Care" |
| rdb_column_nm | "HIV_REFER_FOR_900_CARE_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 630. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580572200 |
| code_set_group_id | 107860 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3273 |
| nbs_question_uid | 10003228 |
| nbs_rdb_metadata_uid | 10062296 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012492 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS444" |
| question_label | "Care Status at Case Close Date" |
| rdb_column_nm | "CLN_CARE_STATUS_CLOSE_DT" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 631. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580572200 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3256 |
| nbs_question_uid | 10003230 |
| nbs_rdb_metadata_uid | 10062462 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012642 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS443" |
| question_label | "Is the Client Currently On PrEP?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_IND" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 632. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580572200 |
| code_set_group_id | 107900 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3253 |
| nbs_question_uid | 10003231 |
| nbs_rdb_metadata_uid | 10062463 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012643 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS446" |
| question_label | "Has Client Been Referred to PrEP Provider?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_REFER" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| seq_nbr | 0 |

## 633. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001000GA01", public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| rdb_table_name_list | null | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-24T00:00:00" |
| activity_to_time | "2026-04-27T00:00:00" |
| add_time | "2026-04-30T19:32:00.637" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777580572200 |
| case_class_cd | "C" |
| case_count | 1 |
| case_management_uid | 1000 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| city_county_case_nbr | "" |
| class_cd | "CASE" |
| closure_investgr_of_phc_uid | 10003004 |
| coinfection_id | "COIN1000XX01" |
| curr_process_state | "Closed Case" |
| curr_process_state_cd | "CC" |
| detection_method_cd | "21" |
| detection_method_desc_txt | "Self-referral" |
| diagnosis_time | "2026-04-21T00:00:00" |
| dispo_fld_fupinvestgr_of_phc_uid | 10003004 |
| effective_from_time | "2026-04-17T00:00:00" |
| fld_fup_investgr_of_phc_uid | 10003013 |
| fld_fup_supervisor_of_phc_uid | 10003004 |
| hospitalized_ind | "No" |
| hospitalized_ind_cd | "N" |
| init_fld_fup_investgr_of_phc_uid | 10003013 |
| init_fup_investgr_of_phc_uid | 10003010 |
| init_interviewer_of_phc_uid | 10003004 |
| interviewer_of_phc_uid | 10003004 |
| inv_case_status | "Confirmed" |
| inv_state_case_id | "" |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Closed" |
| investigation_status_cd | "C" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| legacy_case_id | "" |
| local_id | "CAS10001000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "17" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:32:00.637" |
| nac_last_chg_time | "2026-04-30T20:22:47.510" |
| nac_page_case_uid | 10009300 |
| org_as_reporter_uid | 10003019 |
| organization_id | 10003019 |
| pat_age_at_onset | "41" |
| pat_age_at_onset_unit | "Years" |
| pat_age_at_onset_unit_cd | "Y" |
| patient_id | 10009296 |
| person_as_reporter_uid | 10003022 |
| pregnant_ind | "Yes" |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T20:22:47.510" |
| referral_basis | "T1 - Positive Test" |
| referral_basis_cd | "T1" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| rpt_form_cmplt_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| surv_investgr_of_phc_uid | 10003010 |
| transmission_mode | "Sexually Transmitted" |
| transmission_mode_cd | "S" |

## 634. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T20:22:52.6520686" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| ca_init_intvwr_assgn_dt | "2026-04-25T00:00:00" |
| ca_interviewer_assign_dt | "2026-04-25T00:00:00" |
| ca_patient_intv_status | "I - Interviewed" |
| case_management_uid | 1000 |
| case_oid | 1300100015 |
| case_review_status | "Ready" |
| case_review_status_date | "2026-04-30T20:22:47.477" |
| cc_closed_dt | "2026-04-27T00:00:00" |
| epi_link_id | "1310000026" |
| fl_fup_dispo_dt | "2026-04-25T00:00:00" |
| fl_fup_disposition_cd | "C" |
| fl_fup_disposition_desc | "C - Infected, Brought to Treatment" |
| fl_fup_field_record_num | "1310000026" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_notification_plan_cd | "3 - Dual" |
| fld_foll_up_notification_plan | "3" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Surveillance Follow-up" |
| init_fup_initial_foll_up_cd | "SF" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| pat_intv_status_cd | "I" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| surv_investigator_assgn_dt | "2026-04-24T00:00:00" |
| surv_patient_foll_up | "FF" |
| surv_patient_foll_up_cd | "Field Follow-up" |

## 635. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.5410577" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580572200 |
| branch_id | 10009292 |
| branch_type_cd | "APND" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| root_type_cd | "LabReport" |

## 636. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.5410577" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580572200 |
| branch_id | 10009294 |
| branch_type_cd | "COMP" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| root_type_cd | "LabReport" |

## 637. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580572200 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| root_type_cd | "TreatmentToPHC" |

## 638. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580572200 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| root_type_cd | "IXS" |

## 639. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580572200 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| root_type_cd | "Notification" |

## 640. DELETE dbo.nrt_investigation_notification

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Deleted Row

| Field | Value |
| --- | --- |
| act_type_cd | "Notification" |
| condition_cd | "10312" |
| condition_desc | "Syphilis, secondary" |
| first_notification_date | "2026-04-30T20:22:48.217" |
| first_notification_status | "APPROVED" |
| first_notification_submitted_by | 10009282 |
| jurisdiction_cd | "130001" |
| last_notification_date | "2026-04-30T20:22:48.217" |
| last_notification_submitted_by | 10009282 |
| local_patient_id | "PSN10067000GA01" |
| local_patient_uid | 10009296 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| notif_add_time | "2026-04-30T20:22:48.217" |
| notif_add_user_id | 10009282 |
| notif_add_user_name | "Kent, Ariella" |
| notif_comments | "tell the CDC about this" |
| notif_created_count | 1 |
| notif_created_pending_count | 0 |
| notif_last_chg_time | "2026-04-30T20:22:48.217" |
| notif_last_chg_user_id | 10009282 |
| notif_last_chg_user_name | "Kent, Ariella" |
| notif_local_id | "NOT10000000GA01" |
| notif_rejected_count | 0 |
| notif_sent_count | 0 |
| notif_status | "APPROVED" |
| notification_uid | 10009311 |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| record_status_time | "2026-04-30T20:22:48.217" |
| refresh_datetime | "2026-04-30T20:22:52.6520686" |
| source_act_uid | 10009311 |
| source_class_cd | "NOTF" |
| status_cd | "A" |
| status_time | "2026-04-30T20:22:48.207" |
| target_class_cd | "CASE" |

## 641. INSERT dbo.nrt_investigation_notification

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Inserted Row

| Field | Value |
| --- | --- |
| act_type_cd | "Notification" |
| condition_cd | "10312" |
| condition_desc | "Syphilis, secondary" |
| first_notification_date | "2026-04-30T20:22:48.217" |
| first_notification_status | "APPROVED" |
| first_notification_submitted_by | 10009282 |
| jurisdiction_cd | "130001" |
| last_notification_date | "2026-04-30T20:22:48.217" |
| last_notification_submitted_by | 10009282 |
| local_patient_id | "PSN10067000GA01" |
| local_patient_uid | 10009296 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| notif_add_time | "2026-04-30T20:22:48.217" |
| notif_add_user_id | 10009282 |
| notif_add_user_name | "Kent, Ariella" |
| notif_comments | "tell the CDC about this" |
| notif_created_count | 1 |
| notif_created_pending_count | 0 |
| notif_last_chg_time | "2026-04-30T20:22:48.217" |
| notif_last_chg_user_id | 10009282 |
| notif_last_chg_user_name | "Kent, Ariella" |
| notif_local_id | "NOT10000000GA01" |
| notif_rejected_count | 0 |
| notif_sent_count | 0 |
| notif_status | "APPROVED" |
| notification_uid | 10009311 |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| record_status_time | "2026-04-30T20:22:48.217" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| source_act_uid | 10009311 |
| source_class_cd | "NOTF" |
| status_cd | "A" |
| status_time | "2026-04-30T20:22:48.207" |
| target_class_cd | "CASE" |

## 642. DELETE dbo.nrt_investigation_notification

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Deleted Row

| Field | Value |
| --- | --- |
| act_type_cd | "Notification" |
| condition_cd | "10312" |
| condition_desc | "Syphilis, secondary" |
| first_notification_date | "2026-04-30T20:22:48.217" |
| first_notification_status | "APPROVED" |
| first_notification_submitted_by | 10009282 |
| jurisdiction_cd | "130001" |
| last_notification_date | "2026-04-30T20:22:48.217" |
| last_notification_submitted_by | 10009282 |
| local_patient_id | "PSN10067000GA01" |
| local_patient_uid | 10009296 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| notif_add_time | "2026-04-30T20:22:48.217" |
| notif_add_user_id | 10009282 |
| notif_add_user_name | "Kent, Ariella" |
| notif_comments | "tell the CDC about this" |
| notif_created_count | 1 |
| notif_created_pending_count | 0 |
| notif_last_chg_time | "2026-04-30T20:22:48.217" |
| notif_last_chg_user_id | 10009282 |
| notif_last_chg_user_name | "Kent, Ariella" |
| notif_local_id | "NOT10000000GA01" |
| notif_rejected_count | 0 |
| notif_sent_count | 0 |
| notif_status | "APPROVED" |
| notification_uid | 10009311 |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| record_status_time | "2026-04-30T20:22:48.217" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| source_act_uid | 10009311 |
| source_class_cd | "NOTF" |
| status_cd | "A" |
| status_time | "2026-04-30T20:22:48.207" |
| target_class_cd | "CASE" |

## 643. INSERT dbo.nrt_investigation_notification

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Inserted Row

| Field | Value |
| --- | --- |
| act_type_cd | "Notification" |
| condition_cd | "10312" |
| condition_desc | "Syphilis, secondary" |
| first_notification_date | "2026-04-30T20:22:48.217" |
| first_notification_status | "APPROVED" |
| first_notification_submitted_by | 10009282 |
| jurisdiction_cd | "130001" |
| last_notification_date | "2026-04-30T20:22:48.217" |
| last_notification_submitted_by | 10009282 |
| local_patient_id | "PSN10067000GA01" |
| local_patient_uid | 10009296 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| notif_add_time | "2026-04-30T20:22:48.217" |
| notif_add_user_id | 10009282 |
| notif_add_user_name | "Kent, Ariella" |
| notif_comments | "tell the CDC about this" |
| notif_created_count | 1 |
| notif_created_pending_count | 0 |
| notif_last_chg_time | "2026-04-30T20:22:48.217" |
| notif_last_chg_user_id | 10009282 |
| notif_last_chg_user_name | "Kent, Ariella" |
| notif_local_id | "NOT10000000GA01" |
| notif_rejected_count | 0 |
| notif_sent_count | 0 |
| notif_status | "APPROVED" |
| notification_uid | 10009311 |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| record_status_time | "2026-04-30T20:22:48.217" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| source_act_uid | 10009311 |
| source_class_cd | "NOTF" |
| status_cd | "A" |
| status_time | "2026-04-30T20:22:48.207" |
| target_class_cd | "CASE" |

## 644. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| refresh_datetime | "2026-04-30T20:22:52.8995270" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T20:22:47.497" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 645. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T20:17:00.777" | "2026-04-30T20:22:47.500" |
| refresh_datetime | "2026-04-30T20:17:08.5070668" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:32:00.600" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| age_reported | 41 |
| age_reported_unit | "Years" |
| age_reported_unit_cd | "Y" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T20:22:47.500" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009296 |
| phone_ext_home | "" |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| street_address_2 | "" |
| zip | "30033" |

## 646. UPDATE dbo.nrt_investigation_confirmation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:22:52.927 |
| LSN | 0x00006c1500001998002b |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572198 | 1777580572200 |
| refresh_datetime | "2026-04-30T20:22:52.5560887" | "2026-04-30T20:22:52.9112637" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580572200 |
| confirmation_method_cd | "LD" |
| confirmation_method_desc_txt | "Laboratory confirmed" |
| confirmation_method_time | "2026-04-24T00:00:00" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |

## 647. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T20:22:59.990 |
| LSN | 0x00006c1500001b00002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:17:09.6066667" | "2026-04-30T20:22:59.8800000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T20:22:59.8800000" |

## 648. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=6 |
| Transaction end | 2026-04-30T20:22:59.990 |
| LSN | 0x00006c1500001b00002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:17:09.6066667" | "2026-04-30T20:22:59.8800000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:18.7866667" |
| d_patient_key | 6 |
| patient_uid | 10009296 |
| updated_dttm | "2026-04-30T20:22:59.8800000" |

## 649. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:22:59.990 |
| LSN | 0x00006c1500001b00002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:17:00.770" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 650. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:22:59.990 |
| LSN | 0x00006c1500001b00002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:22:47.497" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 651. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:22:59.990 |
| LSN | 0x00006c1500001b00002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:17:00.777" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 652. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:22:59.990 |
| LSN | 0x00006c1500001b00002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:22:47.500" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 653. UPDATE dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=3 |
| Transaction end | 2026-04-30T20:23:00.487 |
| LSN | 0x00006c1500001c28000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:17:10.2200000" | "2026-04-30T20:23:00.4633333" |

### Row After Change

| Field | Value |
| --- | --- |
| case_uid | 10009300 |
| created_dttm | "2026-04-30T19:32:19.1500000" |
| d_investigation_key | 3 |
| updated_dttm | "2026-04-30T20:23:00.4633333" |

## 654. DELETE dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:23:00.487 |
| LSN | 0x00006c1500001c28000c |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Open" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:17:00.797" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 655. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:23:00.487 |
| LSN | 0x00006c1500001c28000c |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Closed" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:47.510" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 656. UPDATE dbo.nrt_confirmation_method_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:00.517 |
| LSN | 0x00006c1500001c380019 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:17:10.2600000" | "2026-04-30T20:23:00.5000000" |

### Row After Change

| Field | Value |
| --- | --- |
| confirmation_method_cd | "LD" |
| created_dttm | "2026-04-30T19:39:42.4533333" |
| d_confirmation_method_key | 4 |
| updated_dttm | "2026-04-30T20:23:00.5000000" |

## 657. DELETE dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T20:23:00.517 |
| LSN | 0x00006c1500001c380019 |

### Deleted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 658. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T20:23:00.517 |
| LSN | 0x00006c1500001c380019 |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 659. DELETE dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:00.970 |
| LSN | 0x00006c1500001e580006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 660. INSERT dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.037 |
| LSN | 0x00006c1500001e700009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 661. DELETE dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.430 |
| LSN | 0x00006c1500001fd80009 |

### Deleted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_2" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FL_FUP_NOTE | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| PAGE_CASE_UID | 10009300.0 |

## 662. DELETE dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.430 |
| LSN | 0x00006c1500001fd80009 |

### Deleted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_8" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FIELD_SUPERVISOR_RVW_NOTE | "Ariella Kent~04/30/2026 20:17~~we need more information before we can close this." |
| PAGE_CASE_UID | 10009300.0 |

## 663. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.430 |
| LSN | 0x00006c1500001fd80009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_2" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FL_FUP_NOTE | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| PAGE_CASE_UID | 10009300.0 |

## 664. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.430 |
| LSN | 0x00006c1500001fd80009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_3" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| IX_INV_NOTE | "Ariella Kent~04/30/2026 16:22~~here are some more notes" |
| PAGE_CASE_UID | 10009300.0 |

## 665. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.430 |
| LSN | 0x00006c1500001fd80009 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_8" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FIELD_SUPERVISOR_RVW_NOTE | "Ariella Kent~04/30/2026 20:17~~we need more information before we can close this." |
| PAGE_CASE_UID | 10009300.0 |

## 666. DELETE dbo.D_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.690 |
| LSN | 0x00006c15000022000008 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| RSK_ANS_REFUSED_SEX_PARTNER | "No" |
| RSK_NUM_SEX_PARTNER_12MO | "7" |
| RSK_UNK_SEX_PARTNERS | "No" |
| nbs_case_answer_uid | 3259 |

## 667. INSERT dbo.D_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.700 |
| LSN | 0x00006c1500002218000b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| RSK_ANS_REFUSED_SEX_PARTNER | "No" |
| RSK_NO_DRUG_USE_12MO_IND | "No" |
| RSK_NUM_SEX_PARTNER_12MO | "7" |
| RSK_RISK_FACTORS_ASSESS_IND | "1 - Completed Risk Profile" |
| RSK_UNK_SEX_PARTNERS | "No" |
| nbs_case_answer_uid | 3259 |

## 668. DELETE dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.833 |
| LSN | 0x00006c15000024280008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 669. INSERT dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:01.843 |
| LSN | 0x00006c1500002440000b |

### Inserted Row

| Field | Value |
| --- | --- |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 670. DELETE dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:02.160 |
| LSN | 0x00006c15000026480006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 671. INSERT dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:02.200 |
| LSN | 0x00006c15000026680007 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 672. DELETE dbo.D_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:03.767 |
| LSN | 0x00006c15000028c00006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| nbs_case_answer_uid | 3248 |

## 673. INSERT dbo.D_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:03.843 |
| LSN | 0x00006c15000028d8000b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| nbs_case_answer_uid | 3248 |

## 674. DELETE dbo.D_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:03.983 |
| LSN | 0x00006c1500002af80006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| nbs_case_answer_uid | 3245 |

## 675. INSERT dbo.D_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:03.993 |
| LSN | 0x00006c1500002b100009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| nbs_case_answer_uid | 3245 |

## 676. DELETE dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:04.123 |
| LSN | 0x00006c1500002d200008 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 677. INSERT dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:04.130 |
| LSN | 0x00006c1500002d38000b |

### Inserted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 678. DELETE dbo.D_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:04.270 |
| LSN | 0x00006c1500002f400008 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| MDH_PREV_STD_HIST | "No" |
| nbs_case_answer_uid | 3254 |

## 679. INSERT dbo.D_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:23:04.280 |
| LSN | 0x00006c1500002f58000b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| MDH_PREV_STD_HIST | "No" |
| nbs_case_answer_uid | 3254 |

## 680. DELETE dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T20:24:34.660 |
| LSN | 0x00006c15000030800007 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 681. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T20:24:34.660 |
| LSN | 0x00006c15000030800007 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 682. INSERT dbo.nrt_notification_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_notification_key=2 |
| Transaction end | 2026-04-30T20:24:34.740 |
| LSN | 0x00006c1500003100001a |

### Inserted Row

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T20:24:34.7266667" |
| d_notification_key | 2 |
| notification_uid | 10009311 |
| updated_dttm | "2026-04-30T20:24:34.7266667" |

## 683. INSERT dbo.NOTIFICATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: NOTIFICATION_LOCAL_ID="NOT10000000GA01" |
| Transaction end | 2026-04-30T20:24:34.740 |
| LSN | 0x00006c1500003100001a |

### Inserted Row

| Field | Value |
| --- | --- |
| NOTIFICATION_COMMENTS | "tell the CDC about this" |
| NOTIFICATION_KEY | 2 |
| NOTIFICATION_LAST_CHANGE_TIME | "2026-04-30T20:22:48.217" |
| NOTIFICATION_LOCAL_ID | "NOT10000000GA01" |
| NOTIFICATION_STATUS | "APPROVED" |
| NOTIFICATION_SUBMITTED_BY | 10009282 |

## 684. INSERT dbo.NOTIFICATION_EVENT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, NOTIFICATION_KEY=2, NOTIFICATION_SENT_DT_KEY=1, NOTIFICATION_SUBMIT_DT_KEY=1, PATIENT_KEY=6 |
| Transaction end | 2026-04-30T20:24:34.740 |
| LSN | 0x00006c1500003100001a |

### Inserted Row

| Field | Value |
| --- | --- |
| CONDITION_KEY | 44 |
| COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| NOTIFICATION_KEY | 2 |
| NOTIFICATION_SENT_DT_KEY | 1 |
| NOTIFICATION_SUBMIT_DT_KEY | 1 |
| NOTIFICATION_UPD_DT_KEY | 1 |
| PATIENT_KEY | 6 |

## 685. UPDATE dbo.D_CASE_MANAGEMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:24:34.817 |
| LSN | 0x00006c15000031400007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CASE_REVIEW_STATUS | "Reject" | "Ready" |
| CC_CLOSED_DT | null | "2026-04-27" |

### Row After Change

| Field | Value |
| --- | --- |
| ADD_USER_ID | 10009282.0 |
| CASE_OID | 1300100015.0 |
| CASE_REVIEW_STATUS | "Ready" |
| CASE_REVIEW_STATUS_DATE | "2026-04-30" |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25" |
| CA_PATIENT_INTV_STATUS | "I - Interviewed" |
| CC_CLOSED_DT | "2026-04-27" |
| D_CASE_MANAGEMENT_KEY | 2.0 |
| EPI_LINK_ID | "1310000026" |
| FLD_FOLL_UP_NOTIFICATION_PLAN | "3" |
| FL_FUP_DISPOSITION_CD | "C" |
| FL_FUP_DISPOSITION_DESC | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25" |
| FL_FUP_FIELD_RECORD_NUM | "1310000026" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25" |
| FL_FUP_NOTIFICATION_PLAN_CD | "3 - Dual" |
| INIT_FOLL_UP_NOTIFIABLE | "6-Yes, Notifiable" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE_CD | "06" |
| INVESTIGATION_KEY | 3.0 |
| PAT_INTV_STATUS_CD | "I" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24" |
| SURV_PATIENT_FOLL_UP | "FF" |
| SURV_PATIENT_FOLL_UP_CD | "Field Follow-up" |

## 686. UPDATE dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:24:34.817 |
| LSN | 0x00006c15000031400007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:18:39.5000000" | "2026-04-30T20:24:34.8100000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:20.4066667" |
| d_case_management_key | 2 |
| public_health_case_uid | 10009300 |
| updated_dttm | "2026-04-30T20:24:34.8100000" |

## 687. DELETE dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:24:34.957 |
| LSN | 0x00006c16000000100008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 1 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 3 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 3 |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 688. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:24:34.957 |
| LSN | 0x00006c16000000100008 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 2 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 3 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 3 |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 689. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:24:35.060 |
| LSN | 0x00006c1600000058000a |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:17:00.797" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:17:00.797" |

## 690. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:24:35.060 |
| LSN | 0x00006c1600000058000a |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:47.510" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:22:47.510" |

## 691. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="NOT10000000GA01" |
| Transaction end | 2026-04-30T20:24:35.060 |
| LSN | 0x00006c16000000600011 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T20:22:48.217" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "Notification" |
| EVENT_UID | 10009311 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:48.217" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "NOT10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "APPROVED" |
| RECORD_STATUS_DESC_TXT | "Approved" |
| RECORD_STATUS_TIME | "2026-04-30T20:22:48.217" |
| STATUS_TIME | "2026-04-30T20:22:48.207" |

## 692. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:24:35.067 |
| LSN | 0x00006c1600000068000a |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "O" |
| INVESTIGATION_STATUS_DESC_TXT | "Open" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:17:00.797" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:17:00.797" |

## 693. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:24:35.067 |
| LSN | 0x00006c1600000068000a |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:47.510" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:22:47.510" |

## 694. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="NOT10000000GA01" |
| Transaction end | 2026-04-30T20:24:35.070 |
| LSN | 0x00006c16000000700004 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T20:22:48.217" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "Notification" |
| EVENT_UID | 10009311 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:48.217" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "NOT10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "APPROVED" |
| RECORD_STATUS_DESC_TXT | "Approved" |
| RECORD_STATUS_TIME | "2026-04-30T20:22:48.217" |
| STATUS_TIME | "2026-04-30T20:22:48.207" |

## 695. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", NOTIFICATION_LOCAL_ID="NOT10000000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:24:35.300 |
| LSN | 0x00006c16000001200004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T20:17:00.797" | "2026-04-30T20:22:47.510" |
| INVESTIGATION_STATUS | "Open" | "Closed" |
| NOTIFICATION_LAST_UPDATED_DATE | null | "2026-04-30T20:22:48.217" |
| NOTIFICATION_LAST_UPDATED_USER | null | "Kent, Ariella" |
| NOTIFICATION_LOCAL_ID | null | "NOT10000000GA01" |
| NOTIFICATION_STATUS | null | "APPROVED" |
| NOTIFICATION_SUBMITTER | null | "Kent, Ariella" |

### Row After Change

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD | "Laboratory confirmed" |
| CURR_PROCESS_STATE | "Closed Case" |
| DIAGNOSIS_DATE | "2026-04-21T00:00:00" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| ILLNESS_ONSET_DATE | "2026-04-17T00:00:00" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T20:22:47.510" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Closed" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| NOTIFICATION_LAST_UPDATED_DATE | "2026-04-30T20:22:48.217" |
| NOTIFICATION_LAST_UPDATED_USER | "Kent, Ariella" |
| NOTIFICATION_LOCAL_ID | "NOT10000000GA01" |
| NOTIFICATION_STATUS | "APPROVED" |
| NOTIFICATION_SUBMITTER | "Kent, Ariella" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 696. UPDATE dbo.STD_HIV_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:25:35.833 |
| LSN | 0x00006c16000012280004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CC_CLOSED_DT | null | "2026-04-27T00:00:00" |
| INVESTIGATION_STATUS | "Open" | "Closed" |
| INVESTIGATOR_CLOSED_KEY | 1 | 2 |
| INVESTIGATOR_CLOSED_QC | null | "1" |
| RSK_NO_DRUG_USE_12MO_IND | null | "No" |
| RSK_RISK_FACTORS_ASSESS_IND | null | "1 - Completed Risk Profile" |

### Row After Change

| Field | Value |
| --- | --- |
| CALC_5_YEAR_AGE_GROUP | " 9" |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25T00:00:00" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25T00:00:00" |
| CA_PATIENT_INTV_STATUS | "I - Interviewed" |
| CC_CLOSED_DT | "2026-04-27T00:00:00" |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| COINFECTION_ID | "COIN1000XX01" |
| CONDITION_CD | "10312" |
| CONDITION_KEY | 44 |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS | "720 - Syphilis, secondary" |
| DIAGNOSIS_CD | "720" |
| EPI_LINK_ID | "1310000026" |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| FIELD_RECORD_NUMBER | "1310000026" |
| FL_FUP_DISPOSITION | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25T00:00:00" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25T00:00:00" |
| FL_FUP_NOTIFICATION_PLAN | "3 - Dual" |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| HOSPITAL_KEY | 1 |
| HSPTLIZD_IND | "No" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE | "06" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_STATUS | "Closed" |
| INVESTIGATOR_CLOSED_KEY | 2 |
| INVESTIGATOR_CLOSED_QC | "1" |
| INVESTIGATOR_CURRENT_KEY | 2 |
| INVESTIGATOR_CURRENT_QC | "1" |
| INVESTIGATOR_DISP_FL_FUP_KEY | 2 |
| INVESTIGATOR_DISP_FL_FUP_QC | "1" |
| INVESTIGATOR_FL_FUP_KEY | 4 |
| INVESTIGATOR_FL_FUP_QC | "3" |
| INVESTIGATOR_INITIAL_KEY | 3 |
| INVESTIGATOR_INITIAL_QC | "2" |
| INVESTIGATOR_INIT_FL_FUP_KEY | 4 |
| INVESTIGATOR_INIT_FL_FUP_QC | "3" |
| INVESTIGATOR_INIT_INTRVW_KEY | 2 |
| INVESTIGATOR_INIT_INTRVW_QC | "1" |
| INVESTIGATOR_INTERVIEW_KEY | 2 |
| INVESTIGATOR_INTERVIEW_QC | "1" |
| INVESTIGATOR_SUPER_CASE_KEY | 1 |
| INVESTIGATOR_SUPER_FL_FUP_KEY | 2 |
| INVESTIGATOR_SUPER_FL_FUP_QC | "1" |
| INVESTIGATOR_SURV_KEY | 3 |
| INVESTIGATOR_SURV_QC | "2" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| IX_DATE_OI | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| MDH_PREV_STD_HIST | "No" |
| ORDERING_FACILITY_KEY | 1 |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_AGE_REPORTED | "          41 Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_NAME | "Swift_fake77gg, Taylor" |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_PREGNANT_IND | "Yes" |
| PATIENT_RACE | "White" |
| PATIENT_SEX | "Female" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| PHYSICIAN_FL_FUP_KEY | 1 |
| PHYSICIAN_KEY | 1 |
| PROGRAM_AREA_CD | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| REFERRAL_BASIS | "T1 - Positive Test" |
| REPORTING_ORG_KEY | 4 |
| REPORTING_PROV_KEY | 6 |
| RSK_NO_DRUG_USE_12MO_IND | "No" |
| RSK_RISK_FACTORS_ASSESS_IND | "1 - Completed Risk Profile" |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24T00:00:00" |
| SURV_PATIENT_FOLL_UP | "Field Follow-up" |
| TRT_TREATMENT_DATE | "2026-04-20" |

## 697. DELETE dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:25:36.210 |
| LSN | 0x00006c1600001308000c |

### Deleted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T20:17:00.797" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 698. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:25:36.210 |
| LSN | 0x00006c1600001308000c |

### Inserted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T20:22:47.510" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 699. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.273 |
| LSN | 0x00006c16000014380004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.2761219" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580870887 |
| branch_id | 10009292 |
| branch_type_cd | "APND" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:27:51.2761219" |
| root_type_cd | "LabReport" |

## 700. UPDATE dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.273 |
| LSN | 0x00006c16000014380004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.2761219" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580870887 |
| branch_id | 10009294 |
| branch_type_cd | "COMP" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 10009291 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:27:51.2761219" |
| root_type_cd | "LabReport" |

## 701. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.2912429" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3241 |
| nbs_question_uid | 10001013 |
| nbs_rdb_metadata_uid | 10062226 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012401 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NOT120" |
| question_label | "Immediate National Notifiable Condition" |
| rdb_column_nm | "ADM_IMM_NTNL_NTFBL_CNDTN" |
| rdb_table_nm | "D_INV_ADMINISTRATIVE" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |
| seq_nbr | 0 |

## 702. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.2912429" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/20/2026" |
| batch_id | 1777580870887 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3243 |
| nbs_question_uid | 10001192 |
| nbs_rdb_metadata_uid | 10062178 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012367 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD105" |
| question_label | "Treatment Start Date" |
| rdb_column_nm | "TRT_TREATMENT_DATE" |
| rdb_table_nm | "D_INV_TREATMENT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |
| seq_nbr | 0 |

## 703. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.2912429" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "720" |
| batch_id | 1777580870887 |
| code_set_group_id | 105450 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3244 |
| nbs_question_uid | 10001195 |
| nbs_rdb_metadata_uid | 10062221 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012398 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS136" |
| question_label | "Diagnosis Reported to CDC" |
| rdb_column_nm | "CLN_CASE_DIAGNOSIS" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |
| seq_nbr | 0 |

## 704. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.2912429" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| batch_id | 1777580870887 |
| block_nm | "BLOCK_2" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3274 |
| nbs_question_uid | 10001240 |
| nbs_rdb_metadata_uid | 10062285 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012474 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 2 |
| question_identifier | "NBS185" |
| question_label | "Note" |
| rdb_column_nm | "FL_FUP_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |
| seq_nbr | 0 |

## 705. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.2912429" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 20:17~~we need more information before we can close this." |
| batch_id | 1777580870887 |
| block_nm | "BLOCK_8" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:17:00.683" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3275 |
| nbs_question_uid | 10001241 |
| nbs_rdb_metadata_uid | 10062286 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012476 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 8 |
| question_identifier | "NBS268" |
| question_label | "Note" |
| rdb_column_nm | "FIELD_SUPERVISOR_RVW_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |
| seq_nbr | 0 |

## 706. INSERT dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "2" |
| answer_txt | "Ariella Kent~04/30/2026 20:27~~keep updating if new information comes in" |
| batch_id | 1777580870887 |
| block_nm | "BLOCK_8" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:27:43.180" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3280 |
| nbs_question_uid | 10001241 |
| nbs_rdb_metadata_uid | 10062286 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012476 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 8 |
| question_identifier | "NBS268" |
| question_label | "Note" |
| rdb_column_nm | "FIELD_SUPERVISOR_RVW_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |
| seq_nbr | 0 |

## 707. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580870887 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |
| root_type_cd | "TreatmentToPHC" |

## 708. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580870887 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |
| root_type_cd | "IXS" |

## 709. INSERT dbo.nrt_investigation_observation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Inserted Row

| Field | Value |
| --- | --- |
| batch_id | 1777580870887 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| observation_id | 0 |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |
| root_type_cd | "Notification" |

## 710. UPDATE dbo.nrt_investigation_confirmation

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.300 |
| LSN | 0x00006c16000014400017 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.2912429" |

### Row After Change

| Field | Value |
| --- | --- |
| batch_id | 1777580870887 |
| confirmation_method_cd | "LD" |
| confirmation_method_desc_txt | "Laboratory confirmed" |
| confirmation_method_time | "2026-04-24T00:00:00" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:27:51.2912429" |

## 711. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_group_seq_nbr | "1" |
| answer_txt | "Ariella Kent~04/30/2026 16:22~~here are some more notes" |
| batch_id | 1777580870887 |
| block_nm | "BLOCK_3" |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "TEXT" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "TXT" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3279 |
| nbs_question_uid | 10001248 |
| nbs_rdb_metadata_uid | 10062293 |
| nbs_ui_component_uid | 1019 |
| nbs_ui_metadata_uid | 10012486 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_group_seq_nbr | 3 |
| question_identifier | "NBS195" |
| question_label | "Note" |
| rdb_column_nm | "IX_INV_NOTE" |
| rdb_table_nm | "D_INVESTIGATION_REPEAT" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 712. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "30" |
| batch_id | 1777580870887 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3242 |
| nbs_question_uid | 10001252 |
| nbs_rdb_metadata_uid | 10062300 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012499 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS128" |
| question_label | "Weeks" |
| rdb_column_nm | "PBI_PATIENT_PREGNANT_WKS" |
| rdb_table_nm | "D_INV_PREGNANCY_BIRTH" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 713. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580870887 |
| code_set_group_id | 105680 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3277 |
| nbs_question_uid | 10001261 |
| nbs_rdb_metadata_uid | 10062318 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012516 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS229" |
| question_label | "Was Behavioral Risk Assessed" |
| rdb_column_nm | "RSK_RISK_FACTORS_ASSESS_IND" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 714. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 105360 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3278 |
| nbs_question_uid | 10001274 |
| nbs_rdb_metadata_uid | 10062340 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012534 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS233" |
| question_label | "No drug use reported" |
| rdb_column_nm | "RSK_NO_DRUG_USE_12MO_IND" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 715. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3250 |
| nbs_question_uid | 10001283 |
| nbs_rdb_metadata_uid | 10062358 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012545 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS242" |
| question_label | "Places to Meet Partners" |
| rdb_column_nm | "SOC_PLACES_TO_MEET_PARTNER" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 716. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "R" |
| batch_id | 1777580870887 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3248 |
| nbs_question_uid | 10001285 |
| nbs_rdb_metadata_uid | 10062360 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012549 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS244" |
| question_label | "Places to Have Sex" |
| rdb_column_nm | "SOC_PLACES_TO_HAVE_SEX" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 717. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580870887 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3255 |
| nbs_question_uid | 10001287 |
| nbs_rdb_metadata_uid | 10062362 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012554 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS223" |
| question_label | "Female Partners (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 718. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580870887 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3257 |
| nbs_question_uid | 10001288 |
| nbs_rdb_metadata_uid | 10062363 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012555 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS224" |
| question_label | "Number Female (Past Year)" |
| rdb_column_nm | "SOC_FEMALE_PRTNRS_12MO_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 719. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580870887 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3251 |
| nbs_question_uid | 10001289 |
| nbs_rdb_metadata_uid | 10062364 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012556 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS225" |
| question_label | "Male Partners (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 720. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "5" |
| batch_id | 1777580870887 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3252 |
| nbs_question_uid | 10001290 |
| nbs_rdb_metadata_uid | 10062365 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012557 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS226" |
| question_label | "Number Male (Past Year)" |
| rdb_column_nm | "SOC_MALE_PRTNRS_12MO_TOTAL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 721. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3260 |
| nbs_question_uid | 10001291 |
| nbs_rdb_metadata_uid | 10062366 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012558 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS227" |
| question_label | "Transgender Partners (Past Year)" |
| rdb_column_nm | "SOC_TRANSGNDR_PRTNRS_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 722. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "7" |
| batch_id | 1777580870887 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3263 |
| nbs_question_uid | 10001293 |
| nbs_rdb_metadata_uid | 10062368 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012560 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "STD120" |
| question_label | "Total number of sex partners last 12 months?" |
| rdb_column_nm | "RSK_NUM_SEX_PARTNER_12MO" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 723. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3268 |
| nbs_question_uid | 10001294 |
| nbs_rdb_metadata_uid | 10062370 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012561 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD888" |
| question_label | "Patient refused to answer questions regarding number of sex partners" |
| rdb_column_nm | "RSK_ANS_REFUSED_SEX_PARTNER" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 724. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3259 |
| nbs_question_uid | 10001295 |
| nbs_rdb_metadata_uid | 10062372 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012562 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD999" |
| question_label | "Unknown number of sex partners in last 12 months" |
| rdb_column_nm | "RSK_UNK_SEX_PARTNERS" |
| rdb_table_nm | "D_INV_RISK_FACTOR" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 725. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580870887 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3261 |
| nbs_question_uid | 10001296 |
| nbs_rdb_metadata_uid | 10062374 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012564 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS129" |
| question_label | "Female Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 726. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580870887 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3262 |
| nbs_question_uid | 10001297 |
| nbs_rdb_metadata_uid | 10062375 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012565 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS130" |
| question_label | "Number Female (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_FML_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 727. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580870887 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3266 |
| nbs_question_uid | 10001298 |
| nbs_rdb_metadata_uid | 10062376 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012566 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS131" |
| question_label | "Male Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 728. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580870887 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "NUMERIC" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "NUM" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3267 |
| nbs_question_uid | 10001299 |
| nbs_rdb_metadata_uid | 10062377 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012567 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS132" |
| question_label | "Number Male (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_MALE_TTL" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 729. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3264 |
| nbs_question_uid | 10001300 |
| nbs_rdb_metadata_uid | 10062378 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012568 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS133" |
| question_label | "Transgender Partners (Interview Period)" |
| rdb_column_nm | "SOC_PRTNRS_PRD_TRNSGNDR_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 730. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580870887 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3258 |
| nbs_question_uid | 10001302 |
| nbs_rdb_metadata_uid | 10062380 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012571 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD119" |
| question_label | "Met Sex Partners through the Internet" |
| rdb_column_nm | "SOC_SX_PRTNRS_INTNT_12MO_IND" |
| rdb_table_nm | "D_INV_SOCIAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 731. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 105240 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3254 |
| nbs_question_uid | 10001316 |
| nbs_rdb_metadata_uid | 10062440 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012614 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "STD117" |
| question_label | "Previous STD history (self-reported)?" |
| rdb_column_nm | "MDH_PREV_STD_HIST" |
| rdb_table_nm | "D_INV_MEDICAL_HISTORY" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 732. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580870887 |
| code_set_group_id | 105500 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3269 |
| nbs_question_uid | 10001321 |
| nbs_rdb_metadata_uid | 10062446 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012622 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS257" |
| question_label | "Enrolled in Partner Services" |
| rdb_column_nm | "HIV_ENROLL_PRTNR_SRVCS_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 733. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 105370 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3265 |
| nbs_question_uid | 10001322 |
| nbs_rdb_metadata_uid | 10062447 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012624 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS254" |
| question_label | "Previous 900 Test" |
| rdb_column_nm | "HIV_PREVIOUS_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 734. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "Y" |
| batch_id | 1777580870887 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3247 |
| nbs_question_uid | 10001325 |
| nbs_rdb_metadata_uid | 10062450 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012628 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS260" |
| question_label | "Refer for Test" |
| rdb_column_nm | "HIV_REFER_FOR_900_TEST" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 735. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "04/24/2026" |
| batch_id | 1777580870887 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "DATE" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| mask | "DATE" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3245 |
| nbs_question_uid | 10001326 |
| nbs_rdb_metadata_uid | 10062451 |
| nbs_ui_component_uid | 1008 |
| nbs_ui_metadata_uid | 10012629 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS261" |
| question_label | "Referral Date" |
| rdb_column_nm | "HIV_900_TEST_REFERRAL_DT" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 736. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 107870 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3246 |
| nbs_question_uid | 10001327 |
| nbs_rdb_metadata_uid | 10062452 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012630 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS262" |
| question_label | "900 Test" |
| rdb_column_nm | "HIV_900_TEST_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 737. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 4130 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3249 |
| nbs_question_uid | 10001331 |
| nbs_rdb_metadata_uid | 10062459 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012638 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| question_identifier | "NBS266" |
| question_label | "Refer for Care" |
| rdb_column_nm | "HIV_REFER_FOR_900_CARE_IND" |
| rdb_table_nm | "D_INV_HIV" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 738. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "1" |
| batch_id | 1777580870887 |
| code_set_group_id | 107860 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3273 |
| nbs_question_uid | 10003228 |
| nbs_rdb_metadata_uid | 10062296 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012492 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS444" |
| question_label | "Care Status at Case Close Date" |
| rdb_column_nm | "CLN_CARE_STATUS_CLOSE_DT" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 739. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "N" |
| batch_id | 1777580870887 |
| code_set_group_id | 4150 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3256 |
| nbs_question_uid | 10003230 |
| nbs_rdb_metadata_uid | 10062462 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012642 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS443" |
| question_label | "Is the Client Currently On PrEP?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_IND" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 740. UPDATE dbo.nrt_page_case_answer

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| act_uid | 10009300 |
| answer_txt | "2" |
| batch_id | 1777580870887 |
| code_set_group_id | 107900 |
| data_location | "NBS_CASE_ANSWER.ANSWER_TXT" |
| data_type | "CODED" |
| investigation_form_cd | "PG_STD_Investigation" |
| last_chg_time | "2026-04-30T20:22:47.510" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nbs_case_answer_uid | 3253 |
| nbs_question_uid | 10003231 |
| nbs_rdb_metadata_uid | 10062463 |
| nbs_ui_component_uid | 1007 |
| nbs_ui_metadata_uid | 10012643 |
| nca_add_time | "2026-04-30T19:32:00.637" |
| nuim_record_status_cd | "Active" |
| other_value_ind_cd | "F" |
| question_identifier | "NBS446" |
| question_label | "Has Client Been Referred to PrEP Provider?" |
| rdb_column_nm | "CLN_PRE_EXP_PROPHY_REFER" |
| rdb_table_nm | "D_INV_CLINICAL" |
| record_status_cd | "OPEN" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| seq_nbr | 0 |

## 741. UPDATE dbo.nrt_investigation

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="CAS10001000GA01", public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| batch_id | 1777580572200 | 1777580870887 |
| last_chg_time | "2026-04-30T20:22:47.510" | "2026-04-30T20:27:43.313" |
| nac_last_chg_time | "2026-04-30T20:22:47.510" | "2026-04-30T20:27:43.313" |
| rdb_table_name_list | null | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_time | "2026-04-30T20:22:47.510" | "2026-04-30T20:27:43.313" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| activity_from_time | "2026-04-24T00:00:00" |
| activity_to_time | "2026-04-27T00:00:00" |
| add_time | "2026-04-30T19:32:00.637" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| batch_id | 1777580870887 |
| case_class_cd | "C" |
| case_count | 1 |
| case_management_uid | 1000 |
| case_type_cd | "I" |
| cd | "10312" |
| cd_desc_txt | "Syphilis, secondary" |
| city_county_case_nbr | "" |
| class_cd | "CASE" |
| closure_investgr_of_phc_uid | 10003004 |
| coinfection_id | "COIN1000XX01" |
| curr_process_state | "Closed Case" |
| curr_process_state_cd | "CC" |
| detection_method_cd | "21" |
| detection_method_desc_txt | "Self-referral" |
| diagnosis_time | "2026-04-21T00:00:00" |
| dispo_fld_fupinvestgr_of_phc_uid | 10003004 |
| effective_from_time | "2026-04-17T00:00:00" |
| fld_fup_investgr_of_phc_uid | 10003013 |
| fld_fup_supervisor_of_phc_uid | 10003004 |
| hospitalized_ind | "No" |
| hospitalized_ind_cd | "N" |
| init_fld_fup_investgr_of_phc_uid | 10003013 |
| init_fup_investgr_of_phc_uid | 10003010 |
| init_interviewer_of_phc_uid | 10003004 |
| interviewer_of_phc_uid | 10003004 |
| inv_case_status | "Confirmed" |
| inv_state_case_id | "" |
| investigation_count | 1 |
| investigation_form_cd | "PG_STD_Investigation" |
| investigation_status | "Closed" |
| investigation_status_cd | "C" |
| investigator_id | 10003004 |
| jurisdiction_cd | "130001" |
| jurisdiction_nm | "Fulton County" |
| last_chg_time | "2026-04-30T20:27:43.313" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| legacy_case_id | "" |
| local_id | "CAS10001000GA01" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| mmwr_week | "17" |
| mmwr_year | "2026" |
| mood_cd | "EVN" |
| nac_add_time | "2026-04-30T19:32:00.637" |
| nac_last_chg_time | "2026-04-30T20:27:43.313" |
| nac_page_case_uid | 10009300 |
| org_as_reporter_uid | 10003019 |
| organization_id | 10003019 |
| pat_age_at_onset | "41" |
| pat_age_at_onset_unit | "Years" |
| pat_age_at_onset_unit_cd | "Y" |
| patient_id | 10009296 |
| person_as_reporter_uid | 10003022 |
| pregnant_ind | "Yes" |
| pregnant_ind_cd | "Y" |
| prog_area_cd | "STD" |
| program_area_description | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| raw_record_status_cd | "OPEN" |
| rdb_table_name_list | "D_INV_PREGNANCY_BIRTH,D_INVESTIGATION_REPEAT,D_INV_RISK_FACTOR,D_INV_CLINICAL,D_INV_TREATMENT,D_INV_SOCIAL_HISTORY,D_INV_HIV,D_INV_ADMINISTRATIVE,D_INV_MEDICAL_HISTORY" |
| record_status_cd | "ACTIVE" |
| record_status_time | "2026-04-30T20:27:43.313" |
| referral_basis | "T1 - Positive Test" |
| referral_basis_cd | "T1" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| rpt_form_cmplt_time | "2026-04-30T00:00:00" |
| shared_ind | "T" |
| surv_investgr_of_phc_uid | 10003010 |
| transmission_mode | "Sexually Transmitted" |
| transmission_mode_cd | "S" |

## 742. UPDATE dbo.nrt_investigation_case_management

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| case_review_status | "Ready" | "Accept" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.3204332" |

### Row After Change

| Field | Value |
| --- | --- |
| add_user_id | 10009282 |
| ca_init_intvwr_assgn_dt | "2026-04-25T00:00:00" |
| ca_interviewer_assign_dt | "2026-04-25T00:00:00" |
| ca_patient_intv_status | "I - Interviewed" |
| case_management_uid | 1000 |
| case_oid | 1300100015 |
| case_review_status | "Accept" |
| case_review_status_date | "2026-04-30T20:22:47.477" |
| cc_closed_dt | "2026-04-27T00:00:00" |
| epi_link_id | "1310000026" |
| fl_fup_dispo_dt | "2026-04-25T00:00:00" |
| fl_fup_disposition_cd | "C" |
| fl_fup_disposition_desc | "C - Infected, Brought to Treatment" |
| fl_fup_field_record_num | "1310000026" |
| fl_fup_init_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_investigator_assgn_dt | "2026-04-25T00:00:00" |
| fl_fup_notification_plan_cd | "3 - Dual" |
| fld_foll_up_notification_plan | "3" |
| init_foll_up_notifiable | "6-Yes, Notifiable" |
| init_fup_initial_foll_up | "Surveillance Follow-up" |
| init_fup_initial_foll_up_cd | "SF" |
| init_fup_notifiable_cd | "06" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| pat_intv_status_cd | "I" |
| public_health_case_uid | 10009300 |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| surv_investigator_assgn_dt | "2026-04-24T00:00:00" |
| surv_patient_foll_up | "FF" |
| surv_patient_foll_up_cd | "Field Follow-up" |

## 743. DELETE dbo.nrt_investigation_notification

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Deleted Row

| Field | Value |
| --- | --- |
| act_type_cd | "Notification" |
| condition_cd | "10312" |
| condition_desc | "Syphilis, secondary" |
| first_notification_date | "2026-04-30T20:22:48.217" |
| first_notification_status | "APPROVED" |
| first_notification_submitted_by | 10009282 |
| jurisdiction_cd | "130001" |
| last_notification_date | "2026-04-30T20:22:48.217" |
| last_notification_submitted_by | 10009282 |
| local_patient_id | "PSN10067000GA01" |
| local_patient_uid | 10009296 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| notif_add_time | "2026-04-30T20:22:48.217" |
| notif_add_user_id | 10009282 |
| notif_add_user_name | "Kent, Ariella" |
| notif_comments | "tell the CDC about this" |
| notif_created_count | 1 |
| notif_created_pending_count | 0 |
| notif_last_chg_time | "2026-04-30T20:22:48.217" |
| notif_last_chg_user_id | 10009282 |
| notif_last_chg_user_name | "Kent, Ariella" |
| notif_local_id | "NOT10000000GA01" |
| notif_rejected_count | 0 |
| notif_sent_count | 0 |
| notif_status | "APPROVED" |
| notification_uid | 10009311 |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| record_status_time | "2026-04-30T20:22:48.217" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" |
| source_act_uid | 10009311 |
| source_class_cd | "NOTF" |
| status_cd | "A" |
| status_time | "2026-04-30T20:22:48.207" |
| target_class_cd | "CASE" |

## 744. INSERT dbo.nrt_investigation_notification

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c1600001460003a |

### Inserted Row

| Field | Value |
| --- | --- |
| act_type_cd | "Notification" |
| condition_cd | "10312" |
| condition_desc | "Syphilis, secondary" |
| first_notification_date | "2026-04-30T20:22:48.217" |
| first_notification_status | "APPROVED" |
| first_notification_submitted_by | 10009282 |
| jurisdiction_cd | "130001" |
| last_notification_date | "2026-04-30T20:27:43.327" |
| last_notification_submitted_by | 10009282 |
| local_patient_id | "PSN10067000GA01" |
| local_patient_uid | 10009296 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| notif_add_time | "2026-04-30T20:22:48.217" |
| notif_add_user_id | 10009282 |
| notif_add_user_name | "Kent, Ariella" |
| notif_comments | "tell the CDC about this" |
| notif_created_count | 2 |
| notif_created_pending_count | 0 |
| notif_last_chg_time | "2026-04-30T20:27:43.327" |
| notif_last_chg_user_id | 10009282 |
| notif_last_chg_user_name | "Kent, Ariella" |
| notif_local_id | "NOT10000000GA01" |
| notif_rejected_count | 0 |
| notif_sent_count | 0 |
| notif_status | "APPROVED" |
| notification_uid | 10009311 |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| record_status_time | "2026-04-30T20:27:43.327" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| source_act_uid | 10009311 |
| source_class_cd | "NOTF" |
| status_cd | "A" |
| status_time | "2026-04-30T20:22:48.207" |
| target_class_cd | "CASE" |

## 745. DELETE dbo.nrt_investigation_notification

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c16000014980014 |

### Deleted Row

| Field | Value |
| --- | --- |
| act_type_cd | "Notification" |
| condition_cd | "10312" |
| condition_desc | "Syphilis, secondary" |
| first_notification_date | "2026-04-30T20:22:48.217" |
| first_notification_status | "APPROVED" |
| first_notification_submitted_by | 10009282 |
| jurisdiction_cd | "130001" |
| last_notification_date | "2026-04-30T20:27:43.327" |
| last_notification_submitted_by | 10009282 |
| local_patient_id | "PSN10067000GA01" |
| local_patient_uid | 10009296 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| notif_add_time | "2026-04-30T20:22:48.217" |
| notif_add_user_id | 10009282 |
| notif_add_user_name | "Kent, Ariella" |
| notif_comments | "tell the CDC about this" |
| notif_created_count | 2 |
| notif_created_pending_count | 0 |
| notif_last_chg_time | "2026-04-30T20:27:43.327" |
| notif_last_chg_user_id | 10009282 |
| notif_last_chg_user_name | "Kent, Ariella" |
| notif_local_id | "NOT10000000GA01" |
| notif_rejected_count | 0 |
| notif_sent_count | 0 |
| notif_status | "APPROVED" |
| notification_uid | 10009311 |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| record_status_time | "2026-04-30T20:27:43.327" |
| refresh_datetime | "2026-04-30T20:27:51.3204332" |
| source_act_uid | 10009311 |
| source_class_cd | "NOTF" |
| status_cd | "A" |
| status_time | "2026-04-30T20:22:48.207" |
| target_class_cd | "CASE" |

## 746. INSERT dbo.nrt_investigation_notification

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:27:51.380 |
| LSN | 0x00006c16000014980014 |

### Inserted Row

| Field | Value |
| --- | --- |
| act_type_cd | "Notification" |
| condition_cd | "10312" |
| condition_desc | "Syphilis, secondary" |
| first_notification_date | "2026-04-30T20:22:48.217" |
| first_notification_status | "APPROVED" |
| first_notification_submitted_by | 10009282 |
| jurisdiction_cd | "130001" |
| last_notification_date | "2026-04-30T20:27:43.327" |
| last_notification_submitted_by | 10009282 |
| local_patient_id | "PSN10067000GA01" |
| local_patient_uid | 10009296 |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| notif_add_time | "2026-04-30T20:22:48.217" |
| notif_add_user_id | 10009282 |
| notif_add_user_name | "Kent, Ariella" |
| notif_comments | "tell the CDC about this" |
| notif_created_count | 2 |
| notif_created_pending_count | 0 |
| notif_last_chg_time | "2026-04-30T20:27:43.327" |
| notif_last_chg_user_id | 10009282 |
| notif_last_chg_user_name | "Kent, Ariella" |
| notif_local_id | "NOT10000000GA01" |
| notif_rejected_count | 0 |
| notif_sent_count | 0 |
| notif_status | "APPROVED" |
| notification_uid | 10009311 |
| prog_area_cd | "STD" |
| program_jurisdiction_oid | 1300100015 |
| public_health_case_uid | 10009300 |
| record_status_time | "2026-04-30T20:27:43.327" |
| refresh_datetime | "2026-04-30T20:27:51.3850403" |
| source_act_uid | 10009311 |
| source_class_cd | "NOTF" |
| status_cd | "A" |
| status_time | "2026-04-30T20:22:48.207" |
| target_class_cd | "CASE" |

## 747. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:27:51.523 |
| LSN | 0x00006c16000014c80005 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T20:22:47.497" | "2026-04-30T20:27:43.287" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.5282516" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:27:29.850" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T20:27:43.287" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009283 |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:27:51.5282516" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| zip | "30033" |

## 748. UPDATE dbo.nrt_patient

| Metric | Value |
| --- | --- |
| Identity | business_keys: local_id="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:27:51.533 |
| LSN | 0x00006c16000014e00003 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| last_chg_time | "2026-04-30T20:22:47.500" | "2026-04-30T20:27:43.297" |
| refresh_datetime | "2026-04-30T20:22:52.9112637" | "2026-04-30T20:27:51.5380858" |

### Row After Change

| Field | Value |
| --- | --- |
| add_time | "2026-04-30T19:32:00.600" |
| add_user_id | 10009282 |
| add_user_name | "Kent, Ariella" |
| age_reported | 41 |
| age_reported_unit | "Years" |
| age_reported_unit_cd | "Y" |
| birth_sex | "Female" |
| city | "Atlanta" |
| country | "United States" |
| country_code | "840" |
| county | "Fulton County" |
| county_code | "13121" |
| curr_sex_cd | "F" |
| current_sex | "Female" |
| deceased_ind_cd | "N" |
| deceased_indicator | "No" |
| dob | "1985-03-17T00:00:00" |
| email | "taylor@example.com" |
| entry_method | "N" |
| first_name | "Taylor" |
| last_chg_time | "2026-04-30T20:27:43.297" |
| last_chg_user_id | 10009282 |
| last_chg_user_name | "Kent, Ariella" |
| last_name | "Swift_fake77gg" |
| local_id | "PSN10067000GA01" |
| marital_status | "Married" |
| max_datetime | "9999-12-31T23:59:59.9999999" |
| nm_use_cd | "L" |
| patient_mpr_uid | 10009283 |
| patient_uid | 10009296 |
| phone_ext_home | "" |
| phone_home | "201-555-1212" |
| race_all | "White" |
| race_calc_details | "White" |
| race_calculated | "White" |
| record_status | "ACTIVE" |
| refresh_datetime | "2026-04-30T20:27:51.5380858" |
| state | "Georgia" |
| state_code | "13" |
| status_name_cd | "A" |
| street_address_1 | "1313 Pine Way" |
| street_address_2 | "" |
| zip | "30033" |

## 749. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=4 |
| Transaction end | 2026-04-30T20:27:55.333 |
| LSN | 0x00006c1600001528002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:22:59.8800000" | "2026-04-30T20:27:55.1766667" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:27:36.5400000" |
| d_patient_key | 4 |
| patient_uid | 10009283 |
| updated_dttm | "2026-04-30T20:27:55.1766667" |

## 750. UPDATE dbo.nrt_patient_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_patient_key=6 |
| Transaction end | 2026-04-30T20:27:55.333 |
| LSN | 0x00006c1600001528002a |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:22:59.8800000" | "2026-04-30T20:27:55.1766667" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:18.7866667" |
| d_patient_key | 6 |
| patient_uid | 10009296 |
| updated_dttm | "2026-04-30T20:27:55.1766667" |

## 751. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:27:55.333 |
| LSN | 0x00006c1600001528002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:22:47.497" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 752. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:27:55.333 |
| LSN | 0x00006c1600001528002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:27:29.850" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 4 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:27:43.287" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009283 |
| PATIENT_ZIP | "30033" |

## 753. DELETE dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:27:55.333 |
| LSN | 0x00006c1600001528002a |

### Deleted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:22:47.500" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 754. INSERT dbo.D_PATIENT

| Metric | Value |
| --- | --- |
| Identity | business_keys: PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:27:55.333 |
| LSN | 0x00006c1600001528002a |

### Inserted Row

| Field | Value |
| --- | --- |
| PATIENT_ADDED_BY | "Kent, Ariella" |
| PATIENT_ADD_TIME | "2026-04-30T19:32:00.600" |
| PATIENT_AGE_REPORTED | 41 |
| PATIENT_AGE_REPORTED_UNIT | "Years" |
| PATIENT_BIRTH_SEX | "Female" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTRY | "United States" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DECEASED_INDICATOR | "No" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_EMAIL | "taylor@example.com" |
| PATIENT_ENTRY_METHOD | "N" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_CHANGE_TIME | "2026-04-30T20:27:43.297" |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LAST_UPDATED_BY | "Kent, Ariella" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_MARITAL_STATUS | "Married" |
| PATIENT_MPR_UID | 10009283 |
| PATIENT_PHONE_HOME | "201-555-1212" |
| PATIENT_RACE_ALL | "White" |
| PATIENT_RACE_CALCULATED | "White" |
| PATIENT_RACE_CALC_DETAILS | "White" |
| PATIENT_RECORD_STATUS | "ACTIVE" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STATE_CODE | "13" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_UID | 10009296 |
| PATIENT_ZIP | "30033" |

## 755. UPDATE dbo.nrt_investigation_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_investigation_key=3 |
| Transaction end | 2026-04-30T20:27:56 |
| LSN | 0x00006c16000016600001 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:23:00.4633333" | "2026-04-30T20:27:55.9566667" |

### Row After Change

| Field | Value |
| --- | --- |
| case_uid | 10009300 |
| created_dttm | "2026-04-30T19:32:19.1500000" |
| d_investigation_key | 3 |
| updated_dttm | "2026-04-30T20:27:55.9566667" |

## 756. DELETE dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:27:56 |
| LSN | 0x00006c16000016600001 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Closed" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:47.510" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 757. INSERT dbo.INVESTIGATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: INV_LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:27:56 |
| LSN | 0x00006c16000016600001 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| CASE_OID | 1300100015 |
| CASE_RPT_MMWR_WK | 17 |
| CASE_RPT_MMWR_YR | 2026 |
| CASE_TYPE | "I" |
| CASE_UID | 10009300 |
| COINFECTION_ID | "COIN1000XX01" |
| CURR_PROCESS_STATE | "Closed Case" |
| DETECTION_METHOD_DESC_TXT | "Self-referral" |
| DIAGNOSIS_DT | "2026-04-21T00:00:00" |
| HSPTLIZD_IND | "No" |
| ILLNESS_ONSET_DT | "2026-04-17T00:00:00" |
| INVESTIGATION_ADDED_BY | "Kent, Ariella" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDATED_BY | "Kent, Ariella" |
| INVESTIGATION_STATUS | "Closed" |
| INV_CASE_STATUS | "Confirmed" |
| INV_CLOSE_DT | "2026-04-27T00:00:00" |
| INV_LOCAL_ID | "CAS10001000GA01" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_SHARE_IND | "T" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:27:43.313" |
| PATIENT_AGE_AT_ONSET | 41 |
| PATIENT_AGE_AT_ONSET_UNIT | "Years" |
| PATIENT_PREGNANT_IND | "Yes" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| RECORD_STATUS_CD | "ACTIVE" |
| REFERRAL_BASIS | "T1 - Positive Test" |
| TRANSMISSION_MODE | "Sexually Transmitted" |

## 758. UPDATE dbo.nrt_confirmation_method_key

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:56.703 |
| LSN | 0x00006c1600001670000c |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:23:00.5000000" | "2026-04-30T20:27:56.0500000" |

### Row After Change

| Field | Value |
| --- | --- |
| confirmation_method_cd | "LD" |
| created_dttm | "2026-04-30T19:39:42.4533333" |
| d_confirmation_method_key | 4 |
| updated_dttm | "2026-04-30T20:27:56.0500000" |

## 759. DELETE dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T20:27:56.703 |
| LSN | 0x00006c1600001670000c |

### Deleted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 760. INSERT dbo.CONFIRMATION_METHOD_GROUP

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONFIRMATION_METHOD_KEY=4, INVESTIGATION_KEY=3 |
| Transaction end | 2026-04-30T20:27:56.703 |
| LSN | 0x00006c1600001670000c |

### Inserted Row

| Field | Value |
| --- | --- |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD_KEY | 4 |
| INVESTIGATION_KEY | 3 |

## 761. DELETE dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:57.603 |
| LSN | 0x00006c16000018e00006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 762. INSERT dbo.D_INV_PREGNANCY_BIRTH

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:57.677 |
| LSN | 0x00006c1600001900000b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_PREGNANCY_BIRTH_KEY | 3.0 |
| PBI_PATIENT_PREGNANT_WKS | "30" |
| nbs_case_answer_uid | 3242 |

## 763. DELETE dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.353 |
| LSN | 0x00006c1600001a780018 |

### Deleted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_2" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FL_FUP_NOTE | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| PAGE_CASE_UID | 10009300.0 |

## 764. DELETE dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.353 |
| LSN | 0x00006c1600001a780018 |

### Deleted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_3" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| IX_INV_NOTE | "Ariella Kent~04/30/2026 16:22~~here are some more notes" |
| PAGE_CASE_UID | 10009300.0 |

## 765. DELETE dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.353 |
| LSN | 0x00006c1600001a780018 |

### Deleted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_8" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FIELD_SUPERVISOR_RVW_NOTE | "Ariella Kent~04/30/2026 20:17~~we need more information before we can close this." |
| PAGE_CASE_UID | 10009300.0 |

## 766. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.353 |
| LSN | 0x00006c1600001a780018 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_2" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FL_FUP_NOTE | "Ariella Kent~04/30/2026 16:09~~finished gathering information about this case" |
| PAGE_CASE_UID | 10009300.0 |

## 767. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.353 |
| LSN | 0x00006c1600001a780018 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_3" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| IX_INV_NOTE | "Ariella Kent~04/30/2026 16:22~~here are some more notes" |
| PAGE_CASE_UID | 10009300.0 |

## 768. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.353 |
| LSN | 0x00006c1600001a780018 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 1 |
| BLOCK_NM | "BLOCK_8" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FIELD_SUPERVISOR_RVW_NOTE | "Ariella Kent~04/30/2026 20:17~~we need more information before we can close this." |
| PAGE_CASE_UID | 10009300.0 |

## 769. INSERT dbo.D_INVESTIGATION_REPEAT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.353 |
| LSN | 0x00006c1600001a780018 |

### Inserted Row

| Field | Value |
| --- | --- |
| ANSWER_GROUP_SEQ_NBR | 2 |
| BLOCK_NM | "BLOCK_8" |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| FIELD_SUPERVISOR_RVW_NOTE | "Ariella Kent~04/30/2026 20:27~~keep updating if new information comes in" |
| PAGE_CASE_UID | 10009300.0 |

## 770. DELETE dbo.D_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.790 |
| LSN | 0x00006c1600001ca00008 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| RSK_ANS_REFUSED_SEX_PARTNER | "No" |
| RSK_NO_DRUG_USE_12MO_IND | "No" |
| RSK_NUM_SEX_PARTNER_12MO | "7" |
| RSK_RISK_FACTORS_ASSESS_IND | "1 - Completed Risk Profile" |
| RSK_UNK_SEX_PARTNERS | "No" |
| nbs_case_answer_uid | 3259 |

## 771. INSERT dbo.D_INV_RISK_FACTOR

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.850 |
| LSN | 0x00006c1600001cb8000b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_RISK_FACTOR_KEY | 3.0 |
| RSK_ANS_REFUSED_SEX_PARTNER | "No" |
| RSK_NO_DRUG_USE_12MO_IND | "No" |
| RSK_NUM_SEX_PARTNER_12MO | "7" |
| RSK_RISK_FACTORS_ASSESS_IND | "1 - Completed Risk Profile" |
| RSK_UNK_SEX_PARTNERS | "No" |
| nbs_case_answer_uid | 3259 |

## 772. DELETE dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:58.987 |
| LSN | 0x00006c1600001ee80008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 773. INSERT dbo.D_INV_CLINICAL

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59 |
| LSN | 0x00006c1600001f00000b |

### Inserted Row

| Field | Value |
| --- | --- |
| CLN_CARE_STATUS_CLOSE_DT | "1-In Care" |
| CLN_CASE_DIAGNOSIS | "720 - Syphilis, secondary" |
| CLN_PRE_EXP_PROPHY_IND | "No" |
| CLN_PRE_EXP_PROPHY_REFER | "Yes" |
| D_INV_CLINICAL_KEY | 3.0 |
| nbs_case_answer_uid | 3244 |

## 774. DELETE dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.120 |
| LSN | 0x00006c16000021380006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 775. INSERT dbo.D_INV_TREATMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.127 |
| LSN | 0x00006c16000021500016 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_TREATMENT_KEY | 3.0 |
| TRT_TREATMENT_DATE | "2026-04-20" |
| nbs_case_answer_uid | 3243 |

## 776. DELETE dbo.D_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.257 |
| LSN | 0x00006c16000023880006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| nbs_case_answer_uid | 3248 |

## 777. INSERT dbo.D_INV_SOCIAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.267 |
| LSN | 0x00006c16000023a00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_SOCIAL_HISTORY_KEY | 3.0 |
| SOC_FEMALE_PRTNRS_12MO_IND | "Yes" |
| SOC_FEMALE_PRTNRS_12MO_TTL | "2" |
| SOC_MALE_PRTNRS_12MO_IND | "Yes" |
| SOC_MALE_PRTNRS_12MO_TOTAL | "5" |
| SOC_PLACES_TO_HAVE_SEX | "Refused to answer" |
| SOC_PLACES_TO_MEET_PARTNER | "No" |
| SOC_PRTNRS_PRD_FML_IND | "Yes" |
| SOC_PRTNRS_PRD_FML_TTL | "1" |
| SOC_PRTNRS_PRD_MALE_IND | "Yes" |
| SOC_PRTNRS_PRD_MALE_TTL | "2" |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | "No" |
| SOC_SX_PRTNRS_INTNT_12MO_IND | "Yes" |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | "No" |
| nbs_case_answer_uid | 3248 |

## 778. DELETE dbo.D_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.400 |
| LSN | 0x00006c16000025c80006 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| nbs_case_answer_uid | 3245 |

## 779. INSERT dbo.D_INV_HIV

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.407 |
| LSN | 0x00006c16000025e00009 |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_HIV_KEY | 3.0 |
| HIV_900_TEST_IND | "No" |
| HIV_900_TEST_REFERRAL_DT | "2026-04-24" |
| HIV_ENROLL_PRTNR_SRVCS_IND | "Accepted" |
| HIV_PREVIOUS_900_TEST_IND | "No" |
| HIV_REFER_FOR_900_CARE_IND | "No" |
| HIV_REFER_FOR_900_TEST | "Yes" |
| nbs_case_answer_uid | 3245 |

## 780. DELETE dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.530 |
| LSN | 0x00006c16000027f00008 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 781. INSERT dbo.D_INV_ADMINISTRATIVE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.537 |
| LSN | 0x00006c1600002808000b |

### Inserted Row

| Field | Value |
| --- | --- |
| ADM_IMM_NTNL_NTFBL_CNDTN | "No" |
| D_INV_ADMINISTRATIVE_KEY | 3.0 |
| nbs_case_answer_uid | 3241 |

## 782. DELETE dbo.D_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.653 |
| LSN | 0x00006c1600002a100008 |

### Deleted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| MDH_PREV_STD_HIST | "No" |
| nbs_case_answer_uid | 3254 |

## 783. INSERT dbo.D_INV_MEDICAL_HISTORY

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:27:59.663 |
| LSN | 0x00006c1600002a28001b |

### Inserted Row

| Field | Value |
| --- | --- |
| D_INV_MEDICAL_HISTORY_KEY | 3.0 |
| MDH_PREV_STD_HIST | "No" |
| nbs_case_answer_uid | 3254 |

## 784. DELETE dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T20:29:31.217 |
| LSN | 0x00006c1600002b200007 |

### Deleted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 785. INSERT dbo.CASE_COUNT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, INVESTIGATOR_KEY=2, INV_ASSIGNED_DT_KEY=1, PATIENT_KEY=6, PHYSICIAN_KEY=1, REPORTER_KEY=6, RPT_SRC_ORG_KEY=4 |
| Transaction end | 2026-04-30T20:29:31.217 |
| LSN | 0x00006c1600002b200007 |

### Inserted Row

| Field | Value |
| --- | --- |
| ADT_HSPTL_KEY | 1 |
| CASE_COUNT | 1 |
| CONDITION_KEY | 44 |
| DIAGNOSIS_DT_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| INVESTIGATION_COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INV_ASSIGNED_DT_KEY | 1 |
| INV_RPT_DT_KEY | 1 |
| INV_START_DT_KEY | 1 |
| PATIENT_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| REPORTER_KEY | 6 |
| RPT_SRC_ORG_KEY | 4 |

## 786. UPDATE dbo.nrt_notification_key

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: d_notification_key=2 |
| Transaction end | 2026-04-30T20:29:31.287 |
| LSN | 0x00006c1600002b480007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:24:34.7266667" | "2026-04-30T20:29:31.2600000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T20:24:34.7266667" |
| d_notification_key | 2 |
| notification_uid | 10009311 |
| updated_dttm | "2026-04-30T20:29:31.2600000" |

## 787. UPDATE dbo.NOTIFICATION

| Metric | Value |
| --- | --- |
| Identity | business_keys: NOTIFICATION_LOCAL_ID="NOT10000000GA01" |
| Transaction end | 2026-04-30T20:29:31.287 |
| LSN | 0x00006c1600002b480007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| NOTIFICATION_LAST_CHANGE_TIME | "2026-04-30T20:22:48.217" | "2026-04-30T20:27:43.327" |

### Row After Change

| Field | Value |
| --- | --- |
| NOTIFICATION_COMMENTS | "tell the CDC about this" |
| NOTIFICATION_KEY | 2 |
| NOTIFICATION_LAST_CHANGE_TIME | "2026-04-30T20:27:43.327" |
| NOTIFICATION_LOCAL_ID | "NOT10000000GA01" |
| NOTIFICATION_STATUS | "APPROVED" |
| NOTIFICATION_SUBMITTED_BY | 10009282 |

## 788. DELETE dbo.NOTIFICATION_EVENT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, NOTIFICATION_KEY=2, NOTIFICATION_SENT_DT_KEY=1, NOTIFICATION_SUBMIT_DT_KEY=1, PATIENT_KEY=6 |
| Transaction end | 2026-04-30T20:29:31.287 |
| LSN | 0x00006c1600002b480007 |

### Deleted Row

| Field | Value |
| --- | --- |
| CONDITION_KEY | 44 |
| COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| NOTIFICATION_KEY | 2 |
| NOTIFICATION_SENT_DT_KEY | 1 |
| NOTIFICATION_SUBMIT_DT_KEY | 1 |
| NOTIFICATION_UPD_DT_KEY | 1 |
| PATIENT_KEY | 6 |

## 789. INSERT dbo.NOTIFICATION_EVENT

| Metric | Value |
| --- | --- |
| Identity | fallback_primary_key: CONDITION_KEY=44, INVESTIGATION_KEY=3, NOTIFICATION_KEY=2, NOTIFICATION_SENT_DT_KEY=1, NOTIFICATION_SUBMIT_DT_KEY=1, PATIENT_KEY=6 |
| Transaction end | 2026-04-30T20:29:31.287 |
| LSN | 0x00006c1600002b480007 |

### Inserted Row

| Field | Value |
| --- | --- |
| CONDITION_KEY | 44 |
| COUNT | 1 |
| INVESTIGATION_KEY | 3 |
| NOTIFICATION_KEY | 2 |
| NOTIFICATION_SENT_DT_KEY | 1 |
| NOTIFICATION_SUBMIT_DT_KEY | 1 |
| NOTIFICATION_UPD_DT_KEY | 1 |
| PATIENT_KEY | 6 |

## 790. UPDATE dbo.D_CASE_MANAGEMENT

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:29:31.353 |
| LSN | 0x00006c1600002b680007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| CASE_REVIEW_STATUS | "Ready" | "Accept" |

### Row After Change

| Field | Value |
| --- | --- |
| ADD_USER_ID | 10009282.0 |
| CASE_OID | 1300100015.0 |
| CASE_REVIEW_STATUS | "Accept" |
| CASE_REVIEW_STATUS_DATE | "2026-04-30" |
| CA_INIT_INTVWR_ASSGN_DT | "2026-04-25" |
| CA_INTERVIEWER_ASSIGN_DT | "2026-04-25" |
| CA_PATIENT_INTV_STATUS | "I - Interviewed" |
| CC_CLOSED_DT | "2026-04-27" |
| D_CASE_MANAGEMENT_KEY | 2.0 |
| EPI_LINK_ID | "1310000026" |
| FLD_FOLL_UP_NOTIFICATION_PLAN | "3" |
| FL_FUP_DISPOSITION_CD | "C" |
| FL_FUP_DISPOSITION_DESC | "C - Infected, Brought to Treatment" |
| FL_FUP_DISPO_DT | "2026-04-25" |
| FL_FUP_FIELD_RECORD_NUM | "1310000026" |
| FL_FUP_INIT_ASSGN_DT | "2026-04-25" |
| FL_FUP_INVESTIGATOR_ASSGN_DT | "2026-04-25" |
| FL_FUP_NOTIFICATION_PLAN_CD | "3 - Dual" |
| INIT_FOLL_UP_NOTIFIABLE | "6-Yes, Notifiable" |
| INIT_FUP_INITIAL_FOLL_UP | "Surveillance Follow-up" |
| INIT_FUP_INITIAL_FOLL_UP_CD | "SF" |
| INIT_FUP_NOTIFIABLE_CD | "06" |
| INVESTIGATION_KEY | 3.0 |
| PAT_INTV_STATUS_CD | "I" |
| SURV_INVESTIGATOR_ASSGN_DT | "2026-04-24" |
| SURV_PATIENT_FOLL_UP | "FF" |
| SURV_PATIENT_FOLL_UP_CD | "Field Follow-up" |

## 791. UPDATE dbo.nrt_case_management_key

| Metric | Value |
| --- | --- |
| Identity | business_keys: public_health_case_uid=10009300 |
| Transaction end | 2026-04-30T20:29:31.353 |
| LSN | 0x00006c1600002b680007 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| updated_dttm | "2026-04-30T20:24:34.8100000" | "2026-04-30T20:29:31.3500000" |

### Row After Change

| Field | Value |
| --- | --- |
| created_dttm | "2026-04-30T19:32:20.4066667" |
| d_case_management_key | 2 |
| public_health_case_uid | 10009300 |
| updated_dttm | "2026-04-30T20:29:31.3500000" |

## 792. DELETE dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:29:31.497 |
| LSN | 0x00006c1600002bb80008 |

### Deleted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 2 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 3 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 3 |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 793. INSERT dbo.F_STD_PAGE_CASE

| Metric | Value |
| --- | --- |
| Identity | unresolved: unavailable |
| Transaction end | 2026-04-30T20:29:31.497 |
| LSN | 0x00006c1600002bb80008 |

### Inserted Row

| Field | Value |
| --- | --- |
| CLOSED_BY_KEY | 2 |
| CONDITION_KEY | 44 |
| DELIVERING_HOSP_KEY | 1 |
| DELIVERING_MD_KEY | 1 |
| DISPOSITIONED_BY_KEY | 2 |
| D_INVESTIGATION_REPEAT_KEY | 2.0 |
| D_INV_ADMINISTRATIVE_KEY | 3 |
| D_INV_CLINICAL_KEY | 3 |
| D_INV_COMPLICATION_KEY | 1 |
| D_INV_CONTACT_KEY | 1 |
| D_INV_DEATH_KEY | 1 |
| D_INV_EPIDEMIOLOGY_KEY | 1 |
| D_INV_HIV_KEY | 3 |
| D_INV_ISOLATE_TRACKING_KEY | 1 |
| D_INV_LAB_FINDING_KEY | 1 |
| D_INV_MEDICAL_HISTORY_KEY | 3 |
| D_INV_MOTHER_KEY | 1 |
| D_INV_OTHER_KEY | 1 |
| D_INV_PATIENT_OBS_KEY | 1 |
| D_INV_PLACE_REPEAT_KEY | 1.0 |
| D_INV_PREGNANCY_BIRTH_KEY | 3 |
| D_INV_RESIDENCY_KEY | 1 |
| D_INV_RISK_FACTOR_KEY | 3 |
| D_INV_SOCIAL_HISTORY_KEY | 3 |
| D_INV_SYMPTOM_KEY | 1 |
| D_INV_TRAVEL_KEY | 1 |
| D_INV_TREATMENT_KEY | 3 |
| D_INV_UNDER_CONDITION_KEY | 1 |
| D_INV_VACCINATION_KEY | 1 |
| FACILITY_FLD_FOLLOW_UP_KEY | 1 |
| GEOCODING_LOCATION_KEY | 1 |
| HOSPITAL_KEY | 1 |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | 4 |
| INIT_ASGNED_INTERVIEWER_KEY | 2 |
| INIT_FOLLOW_UP_INVSTGTR_KEY | 3 |
| INTERVIEWER_ASSIGNED_KEY | 2 |
| INVESTIGATION_KEY | 3 |
| INVESTIGATOR_KEY | 2 |
| INVSTGTR_FLD_FOLLOW_UP_KEY | 4 |
| MOTHER_OB_GYN_KEY | 1 |
| ORDERING_FACILITY_KEY | 1 |
| ORG_AS_REPORTER_KEY | 4 |
| PATIENT_KEY | 6 |
| PEDIATRICIAN_KEY | 1 |
| PERSON_AS_REPORTER_KEY | 6 |
| PHYSICIAN_KEY | 1 |
| PROVIDER_FLD_FOLLOW_UP_KEY | 1 |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | 1 |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | 2 |
| SURVEILLANCE_INVESTIGATOR_KEY | 3 |

## 794. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="NOT10000000GA01" |
| Transaction end | 2026-04-30T20:29:31.597 |
| LSN | 0x00006c1600002c00000e |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T20:22:48.217" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "Notification" |
| EVENT_UID | 10009311 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:48.217" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "NOT10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "APPROVED" |
| RECORD_STATUS_DESC_TXT | "Approved" |
| RECORD_STATUS_TIME | "2026-04-30T20:22:48.217" |
| STATUS_TIME | "2026-04-30T20:22:48.207" |

## 795. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="NOT10000000GA01" |
| Transaction end | 2026-04-30T20:29:31.597 |
| LSN | 0x00006c1600002c00000e |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T20:22:48.217" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "Notification" |
| EVENT_UID | 10009311 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:27:43.327" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "NOT10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "APPROVED" |
| RECORD_STATUS_DESC_TXT | "Approved" |
| RECORD_STATUS_TIME | "2026-04-30T20:27:43.327" |
| STATUS_TIME | "2026-04-30T20:22:48.207" |

## 796. DELETE dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:29:31.597 |
| LSN | 0x00006c1600002c00000e |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:47.510" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:22:47.510" |

## 797. INSERT dbo.EVENT_METRIC_INC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:29:31.597 |
| LSN | 0x00006c1600002c00000e |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:27:43.313" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:27:43.313" |

## 798. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="NOT10000000GA01" |
| Transaction end | 2026-04-30T20:29:31.603 |
| LSN | 0x00006c1600002c10000e |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T20:22:48.217" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "Notification" |
| EVENT_UID | 10009311 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:48.217" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "NOT10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "APPROVED" |
| RECORD_STATUS_DESC_TXT | "Approved" |
| RECORD_STATUS_TIME | "2026-04-30T20:22:48.217" |
| STATUS_TIME | "2026-04-30T20:22:48.207" |

## 799. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="NOT10000000GA01" |
| Transaction end | 2026-04-30T20:29:31.603 |
| LSN | 0x00006c1600002c10000e |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T20:22:48.217" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| EVENT_TYPE | "Notification" |
| EVENT_UID | 10009311 |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:27:43.327" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "NOT10000000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "APPROVED" |
| RECORD_STATUS_DESC_TXT | "Approved" |
| RECORD_STATUS_TIME | "2026-04-30T20:27:43.327" |
| STATUS_TIME | "2026-04-30T20:22:48.207" |

## 800. DELETE dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:29:31.603 |
| LSN | 0x00006c1600002c10000e |

### Deleted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:22:47.510" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:22:47.510" |

## 801. INSERT dbo.EVENT_METRIC

| Metric | Value |
| --- | --- |
| Identity | business_keys: LOCAL_ID="CAS10001000GA01" |
| Transaction end | 2026-04-30T20:29:31.603 |
| LSN | 0x00006c1600002c10000e |

### Inserted Row

| Field | Value |
| --- | --- |
| ADD_TIME | "2026-04-30T19:32:00.637" |
| ADD_USER_ID | 10009282 |
| ADD_USER_NAME | "Kent, Ariella" |
| CASE_CLASS_CD | "C" |
| CASE_CLASS_DESC_TXT | "Confirmed" |
| CONDITION_CD | "10312" |
| CONDITION_DESC_TXT | "Syphilis, secondary" |
| EVENT_TYPE | "PHCInvForm" |
| EVENT_UID | 10009300 |
| INVESTIGATION_STATUS_CD | "C" |
| INVESTIGATION_STATUS_DESC_TXT | "Closed" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_DESC_TXT | "Fulton County" |
| LAST_CHG_TIME | "2026-04-30T20:27:43.313" |
| LAST_CHG_USER_ID | 10009282 |
| LAST_CHG_USER_NAME | "Kent, Ariella" |
| LOCAL_ID | "CAS10001000GA01" |
| LOCAL_PATIENT_ID | "PSN10067000GA01" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| PROG_AREA_CD | "STD" |
| PROG_AREA_DESC_TXT | "STD" |
| RECORD_STATUS_CD | "OPEN" |
| RECORD_STATUS_DESC_TXT | "Open" |
| RECORD_STATUS_TIME | "2026-04-30T20:27:43.313" |

## 802. UPDATE dbo.INV_SUMM_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", NOTIFICATION_LOCAL_ID="NOT10000000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:29:31.840 |
| LSN | 0x00006c1600002cb00004 |

### Changed Fields

| Field | Before | After |
| --- | --- | --- |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T20:22:47.510" | "2026-04-30T20:27:43.313" |
| NOTIFICATION_LAST_UPDATED_DATE | "2026-04-30T20:22:48.217" | "2026-04-30T20:27:43.327" |

### Row After Change

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| CONFIRMATION_DT | "2026-04-24T00:00:00" |
| CONFIRMATION_METHOD | "Laboratory confirmed" |
| CURR_PROCESS_STATE | "Closed Case" |
| DIAGNOSIS_DATE | "2026-04-21T00:00:00" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| ILLNESS_ONSET_DATE | "2026-04-17T00:00:00" |
| INVESTIGATION_CREATED_BY | "Kent, Ariella" |
| INVESTIGATION_CREATE_DATE | "2026-04-30T19:32:00.637" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LAST_UPDTD_BY | "Kent, Ariella" |
| INVESTIGATION_LAST_UPDTD_DATE | "2026-04-30T20:27:43.313" |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_STATUS | "Closed" |
| INV_RPT_DT | "2026-04-30T00:00:00" |
| INV_START_DT | "2026-04-24T00:00:00" |
| JURISDICTION_NM | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| MMWR_WEEK | 17 |
| MMWR_YEAR | 2026 |
| NOTIFICATION_LAST_UPDATED_DATE | "2026-04-30T20:27:43.327" |
| NOTIFICATION_LAST_UPDATED_USER | "Kent, Ariella" |
| NOTIFICATION_LOCAL_ID | "NOT10000000GA01" |
| NOTIFICATION_STATUS | "APPROVED" |
| NOTIFICATION_SUBMITTER | "Kent, Ariella" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_COUNTY_CODE | "13121" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NAME | "Taylor" |
| PATIENT_KEY | 6 |
| PATIENT_LAST_NAME | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PROGRAM_AREA | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE_CALCULATED | "White" |
| RACE_CALC_DETAILS | "White" |

## 803. DELETE dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:30:32.757 |
| LSN | 0x00006c1b00000158000c |

### Deleted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T20:22:47.510" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |

## 804. INSERT dbo.CASE_LAB_DATAMART

| Metric | Value |
| --- | --- |
| Identity | business_keys: INVESTIGATION_LOCAL_ID="CAS10001000GA01", PATIENT_LOCAL_ID="PSN10067000GA01" |
| Transaction end | 2026-04-30T20:30:32.757 |
| LSN | 0x00006c1b00000158000c |

### Inserted Row

| Field | Value |
| --- | --- |
| AGE_REPORTED | 41 |
| AGE_REPORTED_UNIT | "Years" |
| CASE_STATUS | "Confirmed" |
| DISEASE | "Syphilis, secondary" |
| DISEASE_CD | "10312" |
| EVENT_DATE | "2026-04-17T00:00:00" |
| EVENT_DATE_TYPE | "Illness Onset Date" |
| INVESTIGATION_KEY | 3 |
| INVESTIGATION_LOCAL_ID | "CAS10001000GA01" |
| INVESTIGATION_START_DATE | "2026-04-24T00:00:00" |
| JURISDICTION_NAME | "Fulton County" |
| LABORATORY_INFORMATION | "<b>Local ID:</b> OBS10001000GA01<br><b>Date Received by PH:</b> 04/30/2026<br><b>Specimen Collection Date:</b> <br><b>ELR Indicator:</b>N<br><b>Resulted Test:</b> RPR Titer<br><b>Coded Result:</b> <br><b>Numeric Result:</b> =1:128<br><b>Text Result:</b> <br><b>Comments:</b> <br><br>" |
| PATIENT_CITY | "Atlanta" |
| PATIENT_COUNTY | "Fulton County" |
| PATIENT_CURRENT_SEX | "Female" |
| PATIENT_DOB | "1985-03-17T00:00:00" |
| PATIENT_FIRST_NM | "Taylor" |
| PATIENT_HOME_PHONE | "201-555-1212" |
| PATIENT_LAST_NM | "Swift_fake77gg" |
| PATIENT_LOCAL_ID | "PSN10067000GA01" |
| PATIENT_STATE | "Georgia" |
| PATIENT_STREET_ADDRESS_1 | "1313 Pine Way" |
| PATIENT_ZIP | "30033" |
| PHC_ADD_TIME | "2026-04-30T19:32:00.637" |
| PHC_LAST_CHG_TIME | "2026-04-30T20:27:43.313" |
| PROGRAM_AREA_DESCRIPTION | "STD" |
| PROGRAM_JURISDICTION_OID | 1300100015 |
| RACE | "White" |
| REPORTING_SOURCE | "Emory University Hospital" |
