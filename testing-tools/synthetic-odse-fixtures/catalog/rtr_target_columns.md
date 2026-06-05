# RTR Target Columns

Generated: 2026-05-04
Source: NEDSS-DataReporting/liquibase-service/src/main/resources/db/005-rdb_modern/routines/

This is a static-analysis catalog of every (table, column) pair RTR's stored
procedures can write in RDB_MODERN. It is the canonical scope file for the
comparison-fixtures project (see STRATEGY.md). Every Tier 1 coverage report
measures itself against this map.

## Method

- Parsed every routine in `005-rdb_modern/routines/` (130 .sql files).
- Extracted target tables and column lists from `INSERT INTO`, `UPDATE ... SET`,
  and `MERGE INTO` statements.
- Aliases used in `UPDATE <alias> SET ... FROM <real_table> <alias>` patterns
  were resolved by scanning surrounding `FROM`/`JOIN` clauses.
- Dynamic SQL (`SET @sql = '... INSERT INTO ' + @<var> + ...'`) is captured as
  `<dynamic:@var>` — column lists are not statically derivable. Aliases that
  resolve only inside dynamic SQL string assembly (`tgt`, `TBL`, `tDO`,
  `aoe`) were folded into the corresponding `<dynamic:alias_*>` placeholder
  rather than being reported as real tables.
- `MERGE` contributes both its `WHEN MATCHED ... UPDATE SET` columns and its
  `WHEN NOT MATCHED ... INSERT (cols)` columns to the target.
- `nrt_*`, `tmp_*`, `#temp`, and `@table_var` targets are classified as
  intermediate (RTR staging) and listed separately, not as in-scope targets.
- A column is flagged `Guarded = yes` if its write site contains a `CASE`
  expression in the surrounding `INSERT ... SELECT` / `UPDATE SET` body.
  The predicate itself is not parsed; treat as a hint, not a contract.
- A column is flagged `Dynamic = yes` if its INSERT/UPDATE statement is
  constructed in a string literal and executed via `EXEC sp_executesql` or
  `EXEC (@sql)`. Most truly-dynamic writes appear under the `Dynamic-SQL
  targets` section instead, since both the table name *and* column list are
  runtime-determined.

## Summary

- SPs analyzed: 130
- Distinct in-scope target tables (real RDB_MODERN tables, excludes
  intermediate / staging / dynamic placeholders): 118
- Distinct (table, column) pairs: 3593
- Column-level guarded writes: 962
- Column-level dynamic-SQL writes: 0
- Distinct intermediate / staging tables touched: 152
- Distinct dynamic-SQL target placeholders: 15
- SPs that emit dynamic-SQL writes (subset of the above): 17
- Views written to: 0 (none — RTR never writes to views)

### SP type counts

| Type | Count |
| ---- | ----- |
| datamart | 3 |
| datamart_postprocessing | 35 |
| dyn_dm_postprocessing | 11 |
| dyn_dm_utility | 1 |
| event | 22 |
| nrt_postprocessing | 31 |
| postprocessing | 23 |
| utility | 4 |

## Per-table breakdown

Tables are listed alphabetically. Column lists are extracted exactly as
they appear in the SP's `INSERT (...)` or `MERGE ... INSERT (...)` clauses,
plus any column on the left of an `UPDATE ... SET col = ...`. RTR does not
define DDL for most fact / dimension targets — those are pre-created by the
legacy MasterETL pipeline and RTR only writes to them.

### dbo.AGGREGATE_REPORT_DATAMART

Writers:
- `sp_provider_dim_columns_update_to_datamart` (datamart) — ops: UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| INVESTIGATOR_CLOSED_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_CURRENT_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_DISP_FL_FUP_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_FIRST_NAME | sp_provider_dim_columns_update_to_datamart | no | no |
| INVESTIGATOR_FL_FUP_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_INIT_FL_FUP_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_INIT_INTRVW_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_INITIAL_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_INTERVIEW_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_LAST_NAME | sp_provider_dim_columns_update_to_datamart | no | no |
| INVESTIGATOR_NAME | sp_provider_dim_columns_update_to_datamart | no | no |
| INVESTIGATOR_PHONE_NUMBER | sp_provider_dim_columns_update_to_datamart | no | no |
| INVESTIGATOR_SUPER_CASE_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_SUPER_FL_FUP_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| INVESTIGATOR_SURV_QC | sp_provider_dim_columns_update_to_datamart | yes | no |
| PHYSICIAN_ADDRESS_TYPE_DESC | sp_provider_dim_columns_update_to_datamart | yes | no |
| PHYSICIAN_ADDRESS_USE_DESC | sp_provider_dim_columns_update_to_datamart | yes | no |
| PHYSICIAN_CITY | sp_provider_dim_columns_update_to_datamart | yes | no |
| PHYSICIAN_COUNTY | sp_provider_dim_columns_update_to_datamart | yes | no |
| PHYSICIAN_FIRST_NAME | sp_provider_dim_columns_update_to_datamart | no | no |
| PHYSICIAN_LAST_NAME | sp_provider_dim_columns_update_to_datamart | no | no |
| PHYSICIAN_NAME | sp_provider_dim_columns_update_to_datamart | yes | no |
| PHYSICIAN_PHONE_NUMBER | sp_provider_dim_columns_update_to_datamart | no | no |
| PHYSICIAN_STATE | sp_provider_dim_columns_update_to_datamart | yes | no |
| PROVIDER_QUICK_CODE | sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_FIRST_NAME | sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_LAST_NAME | sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_PHONE_NUMBER | sp_provider_dim_columns_update_to_datamart | no | no |

### dbo.ANTIMICROBIAL_GROUP

Writers:
- `sp_bmird_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ANTIMICROBIAL_GRP_KEY | sp_bmird_case_datamart_postprocessing | no | no |

### dbo.BMIRD_MULTI_VALUE_FIELD_GROUP

Writers:
- `sp_bmird_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| BMIRD_MULTI_VAL_GRP_KEY | sp_bmird_case_datamart_postprocessing | no | no |

### dbo.BMIRD_STREP_PNEUMO_DATAMART

Writers:
- `sp_bmird_strep_pneumo_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE
- `sp_patient_dim_columns_update_to_datamart` (datamart) — ops: UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_CULTURE_1_DATE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ADD_CULTURE_1_OTHER_SITE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ADD_CULTURE_1_SITE_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ADD_CULTURE_1_SITE_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ADD_CULTURE_1_SITE_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ADD_CULTURE_2_DATE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ADD_CULTURE_2_OTHER_SITE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ADD_CULTURE_2_SITE_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ADD_CULTURE_2_SITE_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ADD_CULTURE_2_SITE_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| AGE_REPORTED | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| AGE_REPORTED_UNIT | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| ANTIMIC_GT_8_AGENT_AND_RESULT | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ANTIMICROBIAL_AGENT_TESTED_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ANTIMICROBIAL_AGENT_TESTED_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ANTIMICROBIAL_AGENT_TESTED_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ANTIMICROBIAL_AGENT_TESTED_4 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ANTIMICROBIAL_AGENT_TESTED_5 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ANTIMICROBIAL_AGENT_TESTED_6 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ANTIMICROBIAL_AGENT_TESTED_7 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ANTIMICROBIAL_AGENT_TESTED_8 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| BACTERIAL_SPECIES_ISOLATED | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| BACTERIAL_SPECIES_ISOLATED_OTH | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| CASE_REPORT_STATUS | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| CASE_STATUS | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| CULTURE_SEROTYPE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| DIE_FRM_THIS_ILLNESS_IND | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| DISEASE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| DISEASE_CD | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| EARLIEST_RPT_TO_CNTY_DT | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| EARLIEST_RPT_TO_STATE_DT | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| EVENT_DATE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| EVENT_DATE_TYPE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| FIRST_POSITIVE_CULTURE_DT | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| GENERAL_COMMENTS | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| HOSPITAL_NAME | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| HOSPITALIZED | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| HOSPITALIZED_ADMISSION_DATE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| HOSPITALIZED_DISCHARGE_DATE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| HOSPITALIZED_DURATION_DAYS | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ILLNESS_END_DATE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ILLNESS_ONSET_DATE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| INTERNAL_BODY_SITE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| INVESTIGATION_LOCAL_ID | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_SIGN_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_SIGN_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_SIGN_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_SIGN_4 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_SIGN_5 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_SIGN_6 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_SIGN_7 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_SIGN_8 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_VALUE_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_VALUE_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_VALUE_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_VALUE_4 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_VALUE_5 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_VALUE_6 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_VALUE_7 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MIC_VALUE_8 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MMWR_WEEK | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| MMWR_YEAR | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| NON_STERILE_SITE_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| NON_STERILE_SITE_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| NON_STERILE_SITE_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| NON_STERILE_SITE_OTHER | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| ORGAN_TRANSPLANT | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| OTHER_MALIGNANCY | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| OTHER_PRIOR_ILLNESS_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| OTHER_PRIOR_ILLNESS_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| OTHER_PRIOR_ILLNESS_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| OTHSEROTYPE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| OXACILLIN_INTERPRETATION | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| OXACILLIN_ZONE_SIZE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| PATIENT_CITY | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_COUNTY | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_CURRENT_SEX | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_DOB | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_ETHNICITY | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_FIRST_NAME | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_LAST_NAME | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_LOCAL_ID | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| PATIENT_STATE | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_STREET_ADDRESS_1 | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_STREET_ADDRESS_2 | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_ZIP | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PERSISTENT_DISEASE_IND | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| PHC_ADD_TIME | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| PHC_LAST_CHG_TIME | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| RACE_CALC_DETAILS | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| RACE_CALCULATED | sp_bmird_strep_pneumo_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| S_I_R_U_RESULT_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| S_I_R_U_RESULT_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| S_I_R_U_RESULT_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| S_I_R_U_RESULT_4 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| S_I_R_U_RESULT_5 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| S_I_R_U_RESULT_6 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| S_I_R_U_RESULT_7 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| S_I_R_U_RESULT_8 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| SAME_PATHOGEN_RECURRENT | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| STERILE_SITE_BLOOD | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| STERILE_SITE_CEREBRAL_SF | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| STERILE_SITE_JOINT_FLUID | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| STERILE_SITE_OTHER | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| STERILE_SITE_OTHERS_CONCAT | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| STERILE_SITE_PERICARDIAL_FLUID | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| STERILE_SITE_PERITONEAL_FLUID | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| STERILE_SITE_PLEURAL_FLUID | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| SUSCEPTABILITY_METHOD_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| SUSCEPTABILITY_METHOD_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| SUSCEPTABILITY_METHOD_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| SUSCEPTABILITY_METHOD_4 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| SUSCEPTABILITY_METHOD_5 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| SUSCEPTABILITY_METHOD_6 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| SUSCEPTABILITY_METHOD_7 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| SUSCEPTABILITY_METHOD_8 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_BACTEREMIA | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_CELLULITIS | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_EMPYEMA | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_MENINGITIS | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_OTHER_SPECIFY | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_OTHERS_CONCAT | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_PERICARDITIS | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_PERITONITIS | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_PNEUMONIA | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_PUERPERAL_SEP | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| TYPE_INFECTION_SEP_ARTHRITIS | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| UNDERLYING_CONDITION_1 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| UNDERLYING_CONDITION_2 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| UNDERLYING_CONDITION_3 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| UNDERLYING_CONDITION_4 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| UNDERLYING_CONDITION_5 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| UNDERLYING_CONDITION_6 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| UNDERLYING_CONDITION_7 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| UNDERLYING_CONDITION_8 | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| UNDERLYING_CONDITION_IND | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| VACCINE_CONJUGATE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |
| VACCINE_POLYSACCHARIDE | sp_bmird_strep_pneumo_datamart_postprocessing | no | no |

### dbo.CASE_COUNT

Writers:
- `sp_nrt_case_count_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| adt_hsptl_key | sp_nrt_case_count_postprocessing | yes | no |
| case_count | sp_nrt_case_count_postprocessing | yes | no |
| condition_key | sp_nrt_case_count_postprocessing | yes | no |
| diagnosis_dt_key | sp_nrt_case_count_postprocessing | yes | no |
| geocoding_location_key | sp_nrt_case_count_postprocessing | yes | no |
| inv_assigned_dt_key | sp_nrt_case_count_postprocessing | yes | no |
| inv_rpt_dt_key | sp_nrt_case_count_postprocessing | yes | no |
| inv_start_dt_key | sp_nrt_case_count_postprocessing | yes | no |
| investigation_count | sp_nrt_case_count_postprocessing | yes | no |
| investigation_key | sp_nrt_case_count_postprocessing | yes | no |
| investigator_key | sp_nrt_case_count_postprocessing | yes | no |
| patient_key | sp_nrt_case_count_postprocessing | yes | no |
| physician_key | sp_nrt_case_count_postprocessing | yes | no |
| reporter_key | sp_nrt_case_count_postprocessing | yes | no |
| rpt_src_org_key | sp_nrt_case_count_postprocessing | yes | no |

### dbo.CASE_LAB_DATAMART

Writers:
- `sp_case_lab_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT_NOCOL
- `sp_patient_dim_columns_update_to_datamart` (datamart) — ops: UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| <all> | sp_case_lab_datamart_postprocessing | no | no |
| AGE_REPORTED | sp_patient_dim_columns_update_to_datamart | yes | no |
| AGE_REPORTED_UNIT | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_CITY | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_COUNTY | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_CURRENT_SEX | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_DOB | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_FIRST_NM | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_HOME_PHONE | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_LAST_NM | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_MIDDLE_NM | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_STATE | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_STREET_ADDRESS_1 | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_STREET_ADDRESS_2 | sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_ZIP | sp_patient_dim_columns_update_to_datamart | yes | no |
| RACE | sp_patient_dim_columns_update_to_datamart | yes | no |

### dbo.CONDITION

Writers:
- `sp_nrt_srte_condition_code_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| assigning_authority_cd | sp_nrt_srte_condition_code_postprocessing | no | no |
| assigning_authority_desc | sp_nrt_srte_condition_code_postprocessing | no | no |
| condition_cd | sp_nrt_srte_condition_code_postprocessing | no | no |
| condition_cd_eff_dt | sp_nrt_srte_condition_code_postprocessing | no | no |
| condition_cd_end_dt | sp_nrt_srte_condition_code_postprocessing | no | no |
| condition_cd_sys_cd | sp_nrt_srte_condition_code_postprocessing | no | no |
| condition_cd_sys_cd_nm | sp_nrt_srte_condition_code_postprocessing | no | no |
| condition_desc | sp_nrt_srte_condition_code_postprocessing | no | no |
| condition_key | sp_nrt_srte_condition_code_postprocessing | no | no |
| condition_short_nm | sp_nrt_srte_condition_code_postprocessing | no | no |
| disease_grp_cd | sp_nrt_srte_condition_code_postprocessing | no | no |
| disease_grp_desc | sp_nrt_srte_condition_code_postprocessing | no | no |
| nnd_ind | sp_nrt_srte_condition_code_postprocessing | no | no |
| program_area_cd | sp_nrt_srte_condition_code_postprocessing | no | no |
| program_area_desc | sp_nrt_srte_condition_code_postprocessing | no | no |

### dbo.confirmation_method

Writers:
- `sp_nrt_investigation_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CONFIRMATION_METHOD_CD | sp_nrt_investigation_postprocessing | yes | no |
| CONFIRMATION_METHOD_DESC | sp_nrt_investigation_postprocessing | yes | no |
| CONFIRMATION_METHOD_KEY | sp_nrt_investigation_postprocessing | yes | no |

### dbo.CONFIRMATION_METHOD_GROUP

Writers:
- `sp_nrt_investigation_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CONFIRMATION_DT | sp_nrt_investigation_postprocessing | yes | no |
| CONFIRMATION_METHOD_KEY | sp_nrt_investigation_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_nrt_investigation_postprocessing | yes | no |

### dbo.COVID_CASE_DATAMART

Writers:
- `sp_covid_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| PATH | sp_covid_case_datamart_postprocessing | yes | no |

### dbo.COVID_CONTACT_DATAMART

Writers:
- `sp_covid_contact_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CR_DISPO_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CR_DISPOSITION | sp_covid_contact_datamart_postprocessing | no | no |
| CR_EVAL_COMPLETED | sp_covid_contact_datamart_postprocessing | no | no |
| CR_EVAL_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CR_EVAL_NOTES | sp_covid_contact_datamart_postprocessing | no | no |
| CR_EXPOSURE_SITE_TY | sp_covid_contact_datamart_postprocessing | no | no |
| CR_EXPOSURE_TYPE | sp_covid_contact_datamart_postprocessing | no | no |
| CR_FIRST_EXPOSURE_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CR_HEALTH_STATUS | sp_covid_contact_datamart_postprocessing | no | no |
| CR_INV_ASSIGNED_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CR_INV_FIRST_NAME | sp_covid_contact_datamart_postprocessing | no | no |
| CR_INV_LAST_NAME | sp_covid_contact_datamart_postprocessing | no | no |
| CR_JURISDICTION_NM | sp_covid_contact_datamart_postprocessing | no | no |
| CR_LAST_EXPOSURE_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CR_NAMED_ON_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CR_PRIORITY | sp_covid_contact_datamart_postprocessing | no | no |
| CR_RELATIONSHIP | sp_covid_contact_datamart_postprocessing | no | no |
| CR_RISK_IND | sp_covid_contact_datamart_postprocessing | no | no |
| CR_RISK_NOTES | sp_covid_contact_datamart_postprocessing | no | no |
| CR_STATUS | sp_covid_contact_datamart_postprocessing | no | no |
| CR_SYMP_IND | sp_covid_contact_datamart_postprocessing | no | no |
| CR_SYMP_ONSET_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_CASE_STATUS | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_CDC_ASSIGNED_ID | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_DEATH_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_DIE_FRM_ILLNESS_IND | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_HSPTLIZD_IND | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_ILLNESS_END_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_ILLNESS_ONSET_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_JURISDICTION_NM | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_LEGACY_CASE_ID | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_RPTNG_CNTY | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_START_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_STATE_CASE_ID | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_STATUS | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_SYMPTOM_STATUS | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_INV_SYMPTOMATIC | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_AGE_REPORTED | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_AGE_RPTD_UNIT | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_CITY | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_COUNTRY | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_COUNTY | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_CURRENT_SEX | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_DECEASED_DT | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_DECEASED_IND | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_DOB | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_EMAIL | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_FIRST_NAME | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_LAST_NAME | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_MIDDLE_NAME | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_PHONE_EXT_WORK | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_PHONE_WORK | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_STATE | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_STREET_ADDR_1 | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_STREET_ADDR_2 | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_TEL_CELL | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_TEL_HOME | sp_covid_contact_datamart_postprocessing | no | no |
| CTT_PATIENT_ZIP | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_CTT_INV_COMMENTS | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_CTT_INV_INFECTIOUS_FRM_DT | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_CTT_INV_INFECTIOUS_TO_DT | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_CTT_INV_PRIORITY | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_CTT_INV_STATUS | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_CASE_STATUS | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_CDC_ASSIGNED_ID | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_DEATH_DT | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_DIE_FRM_ILLNESS_IND | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_HSPTLIZD_IND | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_ILLNESS_END_DT | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_ILLNESS_ONSET_DT | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_JURISDICTION_NM | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_LEGACY_CASE_ID | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_RPTNG_CNTY | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_START_DT | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_STATE_CASE_ID | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_STATUS | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_SYMPTOM_STATUS | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_INV_SYMPTOMATIC | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_AGE_REPORTED | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_AGE_RPTD_UNIT | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_CITY | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_COUNTRY | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_COUNTY | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_CURRENT_SEX | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_DECEASED_DT | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_DECEASED_IND | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_DOB | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_FIRST_NAME | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_LAST_NAME | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_MIDDLE_NAME | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_STATE | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_STREET_ADDR_1 | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_STREET_ADDR_2 | sp_covid_contact_datamart_postprocessing | no | no |
| SRC_PATIENT_ZIP | sp_covid_contact_datamart_postprocessing | no | no |

### dbo.COVID_LAB_CELR_DATAMART

Writers:
- `sp_covid_lab_celr_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT_NOCOL

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| <all> | sp_covid_lab_celr_datamart_postprocessing | no | no |

### dbo.COVID_LAB_DATAMART

Writers:
- `sp_covid_lab_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| COVID_LAB_CORE_DATA | sp_covid_lab_datamart_postprocessing | yes | no |

### dbo.COVID_VACCINATION_DATAMART

Writers:
- `sp_covid_vaccination_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT_NOCOL

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| <all> | sp_covid_vaccination_datamart_postprocessing | no | no |

### dbo.D_ADDL_RISK

Writers:
- `sp_nrt_d_addl_risk_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_ADDL_RISK_GROUP_KEY | sp_nrt_d_addl_risk_postprocessing | yes | no |
| D_ADDL_RISK_KEY | sp_nrt_d_addl_risk_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_addl_risk_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_addl_risk_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_addl_risk_postprocessing | yes | no |
| VALUE | sp_nrt_d_addl_risk_postprocessing | yes | no |

### dbo.D_ADDL_RISK_GROUP

Writers:
- `sp_nrt_d_addl_risk_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_ADDL_RISK_GROUP_KEY | sp_nrt_d_addl_risk_postprocessing | yes | no |

### dbo.D_CASE_MANAGEMENT

Writers:
- `sp_nrt_case_management_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ACT_REF_TYPE_CD | sp_nrt_case_management_postprocessing | yes | no |
| ADD_USER_ID | sp_nrt_case_management_postprocessing | yes | no |
| ADI_900_STATUS_CD | sp_nrt_case_management_postprocessing | yes | no |
| ADI_COMPLEXION | sp_nrt_case_management_postprocessing | yes | no |
| ADI_EHARS_ID | sp_nrt_case_management_postprocessing | yes | no |
| ADI_HAIR | sp_nrt_case_management_postprocessing | yes | no |
| ADI_HEIGHT | sp_nrt_case_management_postprocessing | yes | no |
| ADI_HEIGHT_LEGACY_CASE | sp_nrt_case_management_postprocessing | yes | no |
| ADI_OTHER_IDENTIFYING_INFO | sp_nrt_case_management_postprocessing | yes | no |
| ADI_SIZE_BUILD | sp_nrt_case_management_postprocessing | yes | no |
| CA_INIT_INTVWR_ASSGN_DT | sp_nrt_case_management_postprocessing | yes | no |
| CA_INTERVIEWER_ASSIGN_DT | sp_nrt_case_management_postprocessing | yes | no |
| CA_PATIENT_INTV_STATUS | sp_nrt_case_management_postprocessing | yes | no |
| CASE_OID | sp_nrt_case_management_postprocessing | yes | no |
| CASE_REVIEW_STATUS | sp_nrt_case_management_postprocessing | yes | no |
| CASE_REVIEW_STATUS_DATE | sp_nrt_case_management_postprocessing | yes | no |
| CC_CLOSED_DT | sp_nrt_case_management_postprocessing | yes | no |
| D_CASE_MANAGEMENT_KEY | sp_nrt_case_management_postprocessing | yes | no |
| EPI_LINK_ID | sp_nrt_case_management_postprocessing | yes | no |
| FIELD_FOLL_UP_OOJ_OUTCOME | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_ACTUAL_REF_TYPE | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_DISPO_DT | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_DISPOSITION_CD | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_DISPOSITION_DESC | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_EXAM_DT | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_EXPECTED_DT | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_EXPECTED_IN_IND | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_FIELD_RECORD_NUM | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_INIT_ASSGN_DT | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_INTERNET_OUTCOME | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_INTERNET_OUTCOME_CD | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_INVESTIGATOR_ASSGN_DT | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_NOTIFICATION_PLAN_CD | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_OOJ_OUTCOME | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_PROV_DIAGNOSIS | sp_nrt_case_management_postprocessing | yes | no |
| FL_FUP_PROV_EXM_REASON | sp_nrt_case_management_postprocessing | yes | no |
| FLD_FOLL_UP_EXPECTED_IN | sp_nrt_case_management_postprocessing | yes | no |
| FLD_FOLL_UP_NOTIFICATION_PLAN | sp_nrt_case_management_postprocessing | yes | no |
| FLD_FOLL_UP_PROV_DIAGNOSIS | sp_nrt_case_management_postprocessing | yes | no |
| FLD_FOLL_UP_PROV_EXM_REASON | sp_nrt_case_management_postprocessing | yes | no |
| INIT_FOLL_UP_NOTIFIABLE | sp_nrt_case_management_postprocessing | yes | no |
| INIT_FUP_CLINIC_CODE | sp_nrt_case_management_postprocessing | yes | no |
| INIT_FUP_CLOSED_DT | sp_nrt_case_management_postprocessing | yes | no |
| INIT_FUP_INITIAL_FOLL_UP | sp_nrt_case_management_postprocessing | yes | no |
| INIT_FUP_INITIAL_FOLL_UP_CD | sp_nrt_case_management_postprocessing | yes | no |
| INIT_FUP_INTERNET_FOLL_UP_CD | sp_nrt_case_management_postprocessing | yes | no |
| INIT_FUP_NOTIFIABLE_CD | sp_nrt_case_management_postprocessing | yes | no |
| INITIATING_AGNCY | sp_nrt_case_management_postprocessing | yes | no |
| INTERNET_FOLL_UP | sp_nrt_case_management_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_nrt_case_management_postprocessing | yes | no |
| OOJ_AGENCY | sp_nrt_case_management_postprocessing | yes | no |
| OOJ_DUE_DATE | sp_nrt_case_management_postprocessing | yes | no |
| OOJ_INITG_AGNCY_OUTC_DUE_DATE | sp_nrt_case_management_postprocessing | yes | no |
| OOJ_INITG_AGNCY_OUTC_SNT_DATE | sp_nrt_case_management_postprocessing | yes | no |
| OOJ_INITG_AGNCY_RECD_DATE | sp_nrt_case_management_postprocessing | yes | no |
| OOJ_NUMBER | sp_nrt_case_management_postprocessing | yes | no |
| PAT_INTV_STATUS_CD | sp_nrt_case_management_postprocessing | yes | no |
| STATUS_900 | sp_nrt_case_management_postprocessing | yes | no |
| SURV_CLOSED_DT | sp_nrt_case_management_postprocessing | yes | no |
| SURV_INVESTIGATOR_ASSGN_DT | sp_nrt_case_management_postprocessing | yes | no |
| SURV_PATIENT_FOLL_UP | sp_nrt_case_management_postprocessing | yes | no |
| SURV_PATIENT_FOLL_UP_CD | sp_nrt_case_management_postprocessing | yes | no |
| SURV_PROV_EXM_REASON | sp_nrt_case_management_postprocessing | yes | no |
| SURV_PROVIDER_CONTACT | sp_nrt_case_management_postprocessing | yes | no |
| SURV_PROVIDER_CONTACT_CD | sp_nrt_case_management_postprocessing | yes | no |
| SURV_PROVIDER_DIAGNOSIS | sp_nrt_case_management_postprocessing | yes | no |
| SURV_PROVIDER_EXAM_REASON | sp_nrt_case_management_postprocessing | yes | no |

### dbo.D_CONTACT_RECORD

Writers:
- `sp_d_contact_record_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_TIME | sp_d_contact_record_postprocessing | yes | no |
| ADD_USER_ID | sp_d_contact_record_postprocessing | yes | no |
| CONTACT_ENTITY_EPI_LINK_ID | sp_d_contact_record_postprocessing | yes | no |
| CTT_DISPO_DT | sp_d_contact_record_postprocessing | yes | no |
| CTT_DISPOSITION | sp_d_contact_record_postprocessing | yes | no |
| CTT_EVAL_COMPLETED | sp_d_contact_record_postprocessing | yes | no |
| CTT_EVAL_DT | sp_d_contact_record_postprocessing | yes | no |
| CTT_EVAL_NOTES | sp_d_contact_record_postprocessing | yes | no |
| CTT_GROUP_LOT_ID | sp_d_contact_record_postprocessing | yes | no |
| CTT_HEALTH_STATUS | sp_d_contact_record_postprocessing | yes | no |
| CTT_INV_ASSIGNED_DT | sp_d_contact_record_postprocessing | yes | no |
| CTT_JURISDICTION_NM | sp_d_contact_record_postprocessing | yes | no |
| CTT_NAMED_ON_DT | sp_d_contact_record_postprocessing | yes | no |
| CTT_NOTES | sp_d_contact_record_postprocessing | yes | no |
| CTT_PRIORITY | sp_d_contact_record_postprocessing | yes | no |
| CTT_PROCESSING_DECISION | sp_d_contact_record_postprocessing | yes | no |
| CTT_PROGRAM_AREA | sp_d_contact_record_postprocessing | yes | no |
| CTT_REFERRAL_BASIS | sp_d_contact_record_postprocessing | yes | no |
| CTT_RELATIONSHIP | sp_d_contact_record_postprocessing | yes | no |
| CTT_RISK_IND | sp_d_contact_record_postprocessing | yes | no |
| CTT_RISK_NOTES | sp_d_contact_record_postprocessing | yes | no |
| CTT_SHARED_IND | sp_d_contact_record_postprocessing | yes | no |
| CTT_STATUS | sp_d_contact_record_postprocessing | yes | no |
| CTT_SYMP_IND | sp_d_contact_record_postprocessing | yes | no |
| CTT_SYMP_NOTES | sp_d_contact_record_postprocessing | yes | no |
| CTT_SYMP_ONSET_DT | sp_d_contact_record_postprocessing | yes | no |
| CTT_TRT_COMPLETE_IND | sp_d_contact_record_postprocessing | yes | no |
| CTT_TRT_END_DT | sp_d_contact_record_postprocessing | yes | no |
| CTT_TRT_INITIATED_IND | sp_d_contact_record_postprocessing | yes | no |
| CTT_TRT_NOT_COMPLETE_RSN | sp_d_contact_record_postprocessing | yes | no |
| CTT_TRT_NOT_START_RSN | sp_d_contact_record_postprocessing | yes | no |
| CTT_TRT_NOTES | sp_d_contact_record_postprocessing | yes | no |
| CTT_TRT_START_DT | sp_d_contact_record_postprocessing | yes | no |
| D_CONTACT_RECORD_KEY | sp_d_contact_record_postprocessing | yes | no |
| LAST_CHG_TIME | sp_d_contact_record_postprocessing | yes | no |
| LAST_CHG_USER_ID | sp_d_contact_record_postprocessing | yes | no |
| LOCAL_ID | sp_d_contact_record_postprocessing | yes | no |
| PROGRAM_JURISDICTION_OID | sp_d_contact_record_postprocessing | yes | no |
| RDB_COLUMN_NM | sp_d_contact_record_postprocessing | yes | no |
| RECORD_STATUS_CD | sp_d_contact_record_postprocessing | yes | no |
| RECORD_STATUS_TIME | sp_d_contact_record_postprocessing | yes | no |
| SUBJECT_ENTITY_EPI_LINK_ID | sp_d_contact_record_postprocessing | yes | no |
| THEN | sp_d_contact_record_postprocessing | yes | no |
| VERSION_CTRL_NBR | sp_d_contact_record_postprocessing | yes | no |

### dbo.D_DISEASE_SITE

Writers:
- `sp_nrt_d_disease_site_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_DISEASE_SITE_GROUP_KEY | sp_nrt_d_disease_site_postprocessing | yes | no |
| D_DISEASE_SITE_KEY | sp_nrt_d_disease_site_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_disease_site_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_disease_site_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_disease_site_postprocessing | yes | no |
| VALUE | sp_nrt_d_disease_site_postprocessing | yes | no |

### dbo.D_DISEASE_SITE_GROUP

Writers:
- `sp_nrt_d_disease_site_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_DISEASE_SITE_GROUP_KEY | sp_nrt_d_disease_site_postprocessing | yes | no |

### dbo.D_GT_12_REAS

Writers:
- `sp_nrt_d_gt_12_reas_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_GT_12_REAS_GROUP_KEY | sp_nrt_d_gt_12_reas_postprocessing | yes | no |
| D_GT_12_REAS_KEY | sp_nrt_d_gt_12_reas_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_gt_12_reas_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_gt_12_reas_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_gt_12_reas_postprocessing | yes | no |
| VALUE | sp_nrt_d_gt_12_reas_postprocessing | yes | no |

### dbo.D_GT_12_REAS_GROUP

Writers:
- `sp_nrt_d_gt_12_reas_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_GT_12_REAS_GROUP_KEY | sp_nrt_d_gt_12_reas_postprocessing | yes | no |

### dbo.D_HC_PROV_TY_3

Writers:
- `sp_nrt_d_hc_prov_ty_3_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_HC_PROV_TY_3_GROUP_KEY | sp_nrt_d_hc_prov_ty_3_postprocessing | yes | no |
| D_HC_PROV_TY_3_KEY | sp_nrt_d_hc_prov_ty_3_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_hc_prov_ty_3_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_hc_prov_ty_3_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_hc_prov_ty_3_postprocessing | yes | no |
| VALUE | sp_nrt_d_hc_prov_ty_3_postprocessing | yes | no |

### dbo.D_HC_PROV_TY_3_GROUP

Writers:
- `sp_nrt_d_hc_prov_ty_3_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_HC_PROV_TY_3_GROUP_KEY | sp_nrt_d_hc_prov_ty_3_postprocessing | yes | no |

### dbo.D_INTERVIEW

Writers:
- `sp_d_interview_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_TIME | sp_d_interview_postprocessing | yes | no |
| ADD_USER_ID | sp_d_interview_postprocessing | yes | no |
| D_INTERVIEW_KEY | sp_d_interview_postprocessing | yes | no |
| IX_DATE | sp_d_interview_postprocessing | yes | no |
| IX_INTERVIEWEE_ROLE | sp_d_interview_postprocessing | yes | no |
| IX_INTERVIEWEE_ROLE_CD | sp_d_interview_postprocessing | yes | no |
| IX_LOCATION | sp_d_interview_postprocessing | yes | no |
| IX_LOCATION_CD | sp_d_interview_postprocessing | yes | no |
| IX_STATUS | sp_d_interview_postprocessing | yes | no |
| IX_STATUS_CD | sp_d_interview_postprocessing | yes | no |
| IX_TYPE | sp_d_interview_postprocessing | yes | no |
| IX_TYPE_CD | sp_d_interview_postprocessing | yes | no |
| LAST_CHG_TIME | sp_d_interview_postprocessing | yes | no |
| LAST_CHG_USER_ID | sp_d_interview_postprocessing | yes | no |
| LOCAL_ID | sp_d_interview_postprocessing | yes | no |
| RDB_COLUMN_NM | sp_d_interview_postprocessing | yes | no |
| RECORD_STATUS_CD | sp_d_interview_postprocessing | yes | no |
| RECORD_STATUS_TIME | sp_d_interview_postprocessing | yes | no |
| THEN | sp_d_interview_postprocessing | yes | no |
| VERSION_CTRL_NBR | sp_d_interview_postprocessing | yes | no |

### dbo.D_INTERVIEW_NOTE

Writers:
- `sp_d_interview_postprocessing` (postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| COMMENT_DATE | sp_d_interview_postprocessing | no | no |
| D_INTERVIEW_KEY | sp_d_interview_postprocessing | no | no |
| D_INTERVIEW_NOTE_KEY | sp_d_interview_postprocessing | no | no |
| NBS_ANSWER_UID | sp_d_interview_postprocessing | no | no |
| USER_COMMENT | sp_d_interview_postprocessing | no | no |
| USER_FIRST_NAME | sp_d_interview_postprocessing | no | no |
| USER_LAST_NAME | sp_d_interview_postprocessing | no | no |

### dbo.D_INV_PLACE_REPEAT

Writers:
- `sp_nrt_place_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_repeated_place_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| answer_group_seq_nbr | sp_repeated_place_postprocessing | no | no |
| D_INV_PLACE_REPEAT_KEY | sp_repeated_place_postprocessing | yes | no |
| PAGE_CASE_UID | sp_repeated_place_postprocessing | no | no |
| PLACE_ADD_TIME | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_ADD_USER_ID | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_ADDED_BY | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_ADDRESS_COMMENTS | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_AS_SEX_OF_PHC | sp_repeated_place_postprocessing | no | no |
| PLACE_CITY | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_COUNTRY | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_COUNTRY_DESC | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_COUNTY_CODE | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_COUNTY_DESC | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_EMAIL | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_GENERAL_COMMENTS | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_HANGOUT_OF_PHC | sp_repeated_place_postprocessing | no | no |
| PLACE_KEY | sp_repeated_place_postprocessing | no | no |
| PLACE_LAST_CHANGE_TIME | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_LAST_CHG_USER_ID | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_LAST_UPDATED_BY | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_LOCAL_ID | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_LOCATOR_UID | sp_repeated_place_postprocessing | no | no |
| PLACE_NAME | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_PHONE | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_PHONE_COMMENTS | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_PHONE_EXT | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_POSTAL_UID | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_QUICK_CODE | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_RECORD_STATUS | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_RECORD_STATUS_TIME | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_STATE_CODE | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_STATE_DESC | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_STATUS_CD | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_STATUS_TIME | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_STREET_ADDRESS_1 | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_STREET_ADDRESS_2 | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_TELE_LOCATOR_UID | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_TELE_TYPE | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_TELE_USE | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_TYPE_DESCRIPTION | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_UID | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PLACE_ZIP | sp_nrt_place_postprocessing, sp_repeated_place_postprocessing | no | no |
| PlaceAsHangoutOfPHC | sp_repeated_place_postprocessing | no | no |
| PlaceAsSexOfPHC | sp_repeated_place_postprocessing | no | no |

### dbo.D_INVESTIGATION_REPEAT

Writers:
- `sp_sld_investigation_repeat_postprocessing` (postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_INVESTIGATION_REPEAT_KEY | sp_sld_investigation_repeat_postprocessing | yes | no |
| S_INVESTIGATION_REPEAT | sp_sld_investigation_repeat_postprocessing | yes | no |

### dbo.D_LDF_META_DATA

Writers:
- `sp_nrt_ldf_dimensional_data_postprocessing` (nrt_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| active_ind | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| business_object_nm | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| cdc_national_id | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| class_cd | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| code_set_nm | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| condition_cd | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| custom_subform_metadata_uid | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| data_type | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| Field_size | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| label_txt | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LDF_PAGE_SET | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| ldf_uid | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| page_set | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| state_cd | sp_nrt_ldf_dimensional_data_postprocessing | no | no |

### dbo.D_MOVE_CNTRY

Writers:
- `sp_nrt_d_move_cntry_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_MOVE_CNTRY_GROUP_KEY | sp_nrt_d_move_cntry_postprocessing | yes | no |
| D_MOVE_CNTRY_KEY | sp_nrt_d_move_cntry_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_move_cntry_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_move_cntry_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_move_cntry_postprocessing | yes | no |
| VALUE | sp_nrt_d_move_cntry_postprocessing | yes | no |

### dbo.D_MOVE_CNTRY_GROUP

Writers:
- `sp_nrt_d_move_cntry_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_MOVE_CNTRY_GROUP_KEY | sp_nrt_d_move_cntry_postprocessing | yes | no |

### dbo.D_MOVE_CNTY

Writers:
- `sp_nrt_d_move_cnty_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_MOVE_CNTY_GROUP_KEY | sp_nrt_d_move_cnty_postprocessing | yes | no |
| D_MOVE_CNTY_KEY | sp_nrt_d_move_cnty_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_move_cnty_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_move_cnty_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_move_cnty_postprocessing | yes | no |
| VALUE | sp_nrt_d_move_cnty_postprocessing | yes | no |

### dbo.D_MOVE_CNTY_GROUP

Writers:
- `sp_nrt_d_move_cnty_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_MOVE_CNTY_GROUP_KEY | sp_nrt_d_move_cnty_postprocessing | yes | no |

### dbo.D_MOVE_STATE

Writers:
- `sp_nrt_d_move_state_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_MOVE_STATE_GROUP_KEY | sp_nrt_d_move_state_postprocessing | yes | no |
| D_MOVE_STATE_KEY | sp_nrt_d_move_state_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_move_state_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_move_state_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_move_state_postprocessing | yes | no |
| VALUE | sp_nrt_d_move_state_postprocessing | yes | no |

### dbo.D_MOVE_STATE_GROUP

Writers:
- `sp_nrt_d_move_state_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_MOVE_STATE_GROUP_KEY | sp_nrt_d_move_state_postprocessing | yes | no |

### dbo.D_MOVED_WHERE

Writers:
- `sp_nrt_d_moved_where_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_MOVED_WHERE_GROUP_KEY | sp_nrt_d_moved_where_postprocessing | yes | no |
| D_MOVED_WHERE_KEY | sp_nrt_d_moved_where_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_moved_where_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_moved_where_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_moved_where_postprocessing | yes | no |
| VALUE | sp_nrt_d_moved_where_postprocessing | yes | no |

### dbo.D_MOVED_WHERE_GROUP

Writers:
- `sp_nrt_d_moved_where_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_MOVED_WHERE_GROUP_KEY | sp_nrt_d_moved_where_postprocessing | yes | no |

### dbo.d_organization

Writers:
- `sp_nrt_organization_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ORGANIZATION_ADD_TIME | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_ADDED_BY | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_ADDRESS_COMMENTS | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_CITY | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_COUNTRY | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_COUNTY | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_COUNTY_CODE | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_EMAIL | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_ENTRY_METHOD | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_FACILITY_ID | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_FACILITY_ID_AUTH | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_FAX | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_GENERAL_COMMENTS | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_KEY | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_LAST_CHANGE_TIME | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_LAST_UPDATED_BY | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_LOCAL_ID | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_NAME | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_PHONE_COMMENTS | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_PHONE_EXT_WORK | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_PHONE_WORK | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_QUICK_CODE | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_RECORD_STATUS | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_STAND_IND_CLASS | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_STATE | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_STATE_CODE | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_STREET_ADDRESS_1 | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_STREET_ADDRESS_2 | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_UID | sp_nrt_organization_postprocessing | yes | no |
| ORGANIZATION_ZIP | sp_nrt_organization_postprocessing | yes | no |

### dbo.D_OUT_OF_CNTRY

Writers:
- `sp_nrt_d_out_of_cntry_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_OUT_OF_CNTRY_GROUP_KEY | sp_nrt_d_out_of_cntry_postprocessing | yes | no |
| D_OUT_OF_CNTRY_KEY | sp_nrt_d_out_of_cntry_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_out_of_cntry_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_out_of_cntry_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_out_of_cntry_postprocessing | yes | no |
| VALUE | sp_nrt_d_out_of_cntry_postprocessing | yes | no |

### dbo.D_OUT_OF_CNTRY_GROUP

Writers:
- `sp_nrt_d_out_of_cntry_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_OUT_OF_CNTRY_GROUP_KEY | sp_nrt_d_out_of_cntry_postprocessing | yes | no |

### dbo.d_patient

Writers:
- `sp_nrt_patient_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| PATIENT_ADD_TIME | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_ADDED_BY | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_ADDL_GENDER_INFO | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_AGE_REPORTED | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_AGE_REPORTED_UNIT | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_ALIAS_NICKNAME | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_BIRTH_COUNTRY | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_BIRTH_SEX | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_CENSUS_TRACT | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_CITY | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_COUNTRY | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_COUNTY | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_COUNTY_CODE | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_CURR_SEX_UNK_RSN | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_CURRENT_SEX | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_DECEASED_DATE | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_DECEASED_INDICATOR | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_DOB | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_EMAIL | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_ENTRY_METHOD | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_ETHNICITY | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_FIRST_NAME | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_GENERAL_COMMENTS | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_KEY | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_LAST_CHANGE_TIME | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_LAST_NAME | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_LAST_UPDATED_BY | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_LOCAL_ID | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_MARITAL_STATUS | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_MIDDLE_NAME | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_MPR_UID | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_NAME_SUFFIX | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_NUMBER | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_NUMBER_AUTH | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_PHONE_CELL | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_PHONE_EXT_HOME | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_PHONE_EXT_WORK | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_PHONE_HOME | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_PHONE_WORK | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_PREFERRED_GENDER | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_PRIMARY_LANGUAGE | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_PRIMARY_OCCUPATION | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_ALL | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_AMER_IND_1 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_AMER_IND_2 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_AMER_IND_3 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_AMER_IND_ALL | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_AMER_IND_GT3_IND | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_ASIAN_1 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_ASIAN_2 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_ASIAN_3 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_ASIAN_ALL | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_ASIAN_GT3_IND | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_BLACK_1 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_BLACK_2 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_BLACK_3 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_BLACK_ALL | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_BLACK_GT3_IND | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_CALC_DETAILS | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_CALCULATED | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_NAT_HI_1 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_NAT_HI_2 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_NAT_HI_3 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_NAT_HI_ALL | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_NAT_HI_GT3_IND | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_WHITE_1 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_WHITE_2 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_WHITE_3 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_WHITE_ALL | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RACE_WHITE_GT3_IND | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_RECORD_STATUS | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_SPEAKS_ENGLISH | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_SSN | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_STATE | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_STATE_CODE | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_STREET_ADDRESS_1 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_STREET_ADDRESS_2 | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_UID | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_UNK_ETHNIC_RSN | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_WITHIN_CITY_LIMITS | sp_nrt_patient_postprocessing | yes | no |
| PATIENT_ZIP | sp_nrt_patient_postprocessing | yes | no |

### dbo.D_PCR_SOURCE

Writers:
- `sp_nrt_d_pcr_source_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_PCR_SOURCE_GROUP_KEY | sp_nrt_d_pcr_source_postprocessing | yes | no |
| D_PCR_SOURCE_KEY | sp_nrt_d_pcr_source_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_pcr_source_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_pcr_source_postprocessing | yes | no |
| VALUE | sp_nrt_d_pcr_source_postprocessing | yes | no |
| VAR_PAM_UID | sp_nrt_d_pcr_source_postprocessing | yes | no |

### dbo.D_PCR_SOURCE_GROUP

Writers:
- `sp_nrt_d_pcr_source_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_PCR_SOURCE_GROUP_KEY | sp_nrt_d_pcr_source_postprocessing | yes | no |

### dbo.D_PLACE

Writers:
- `sp_nrt_place_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| PLACE_ADD_TIME | sp_nrt_place_postprocessing | yes | no |
| PLACE_ADD_USER_ID | sp_nrt_place_postprocessing | yes | no |
| PLACE_ADDED_BY | sp_nrt_place_postprocessing | yes | no |
| PLACE_ADDRESS_COMMENTS | sp_nrt_place_postprocessing | yes | no |
| PLACE_CITY | sp_nrt_place_postprocessing | yes | no |
| PLACE_COUNTRY | sp_nrt_place_postprocessing | yes | no |
| PLACE_COUNTRY_DESC | sp_nrt_place_postprocessing | yes | no |
| PLACE_COUNTY_CODE | sp_nrt_place_postprocessing | yes | no |
| PLACE_COUNTY_DESC | sp_nrt_place_postprocessing | yes | no |
| PLACE_EMAIL | sp_nrt_place_postprocessing | yes | no |
| PLACE_GENERAL_COMMENTS | sp_nrt_place_postprocessing | yes | no |
| PLACE_KEY | sp_nrt_place_postprocessing | yes | no |
| PLACE_LAST_CHANGE_TIME | sp_nrt_place_postprocessing | yes | no |
| PLACE_LAST_CHG_USER_ID | sp_nrt_place_postprocessing | yes | no |
| PLACE_LAST_UPDATED_BY | sp_nrt_place_postprocessing | yes | no |
| PLACE_LOCAL_ID | sp_nrt_place_postprocessing | yes | no |
| PLACE_LOCATOR_UID | sp_nrt_place_postprocessing | yes | no |
| PLACE_NAME | sp_nrt_place_postprocessing | yes | no |
| PLACE_PHONE | sp_nrt_place_postprocessing | yes | no |
| PLACE_PHONE_COMMENTS | sp_nrt_place_postprocessing | yes | no |
| PLACE_PHONE_EXT | sp_nrt_place_postprocessing | yes | no |
| PLACE_POSTAL_UID | sp_nrt_place_postprocessing | yes | no |
| PLACE_QUICK_CODE | sp_nrt_place_postprocessing | yes | no |
| PLACE_RECORD_STATUS | sp_nrt_place_postprocessing | yes | no |
| PLACE_RECORD_STATUS_TIME | sp_nrt_place_postprocessing | yes | no |
| PLACE_STATE_CODE | sp_nrt_place_postprocessing | yes | no |
| PLACE_STATE_DESC | sp_nrt_place_postprocessing | yes | no |
| PLACE_STATUS_CD | sp_nrt_place_postprocessing | yes | no |
| PLACE_STATUS_TIME | sp_nrt_place_postprocessing | yes | no |
| PLACE_STREET_ADDRESS_1 | sp_nrt_place_postprocessing | yes | no |
| PLACE_STREET_ADDRESS_2 | sp_nrt_place_postprocessing | yes | no |
| PLACE_TELE_LOCATOR_UID | sp_nrt_place_postprocessing | yes | no |
| PLACE_TELE_TYPE | sp_nrt_place_postprocessing | yes | no |
| PLACE_TELE_USE | sp_nrt_place_postprocessing | yes | no |
| PLACE_TYPE_DESCRIPTION | sp_nrt_place_postprocessing | yes | no |
| PLACE_UID | sp_nrt_place_postprocessing | yes | no |
| PLACE_ZIP | sp_nrt_place_postprocessing | yes | no |

### dbo.d_provider

Writers:
- `sp_nrt_provider_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| PROVIDER_ADD_TIME | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_ADDED_BY | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_ADDRESS_COMMENTS | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_CITY | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_COUNTRY | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_COUNTY | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_COUNTY_CODE | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_EMAIL_WORK | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_ENTRY_METHOD | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_FIRST_NAME | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_GENERAL_COMMENTS | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_KEY | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_LAST_CHANGE_TIME | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_LAST_NAME | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_LAST_UPDATED_BY | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_LOCAL_ID | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_MIDDLE_NAME | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_NAME_DEGREE | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_NAME_PREFIX | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_NAME_SUFFIX | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_PHONE_CELL | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_PHONE_COMMENTS | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_PHONE_EXT_WORK | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_PHONE_WORK | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_QUICK_CODE | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_RECORD_STATUS | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_REGISRATION_NUM_AUTH | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_REGISTRATION_NUM | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_STATE | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_STATE_CODE | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_STREET_ADDRESS_1 | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_STREET_ADDRESS_2 | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_UID | sp_nrt_provider_postprocessing | yes | no |
| PROVIDER_ZIP | sp_nrt_provider_postprocessing | yes | no |

### dbo.D_RASH_LOC_GEN

Writers:
- `sp_nrt_d_rash_loc_gen_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_RASH_LOC_GEN_GROUP_KEY | sp_nrt_d_rash_loc_gen_postprocessing | yes | no |
| D_RASH_LOC_GEN_KEY | sp_nrt_d_rash_loc_gen_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_rash_loc_gen_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_rash_loc_gen_postprocessing | yes | no |
| VALUE | sp_nrt_d_rash_loc_gen_postprocessing | yes | no |
| VAR_PAM_UID | sp_nrt_d_rash_loc_gen_postprocessing | yes | no |

### dbo.D_RASH_LOC_GEN_GROUP

Writers:
- `sp_nrt_d_rash_loc_gen_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_RASH_LOC_GEN_GROUP_KEY | sp_nrt_d_rash_loc_gen_postprocessing | yes | no |

### dbo.D_SMR_EXAM_TY

Writers:
- `sp_nrt_d_smr_exam_ty_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_SMR_EXAM_TY_GROUP_KEY | sp_nrt_d_smr_exam_ty_postprocessing | yes | no |
| D_SMR_EXAM_TY_KEY | sp_nrt_d_smr_exam_ty_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_d_smr_exam_ty_postprocessing | yes | no |
| SEQ_NBR | sp_nrt_d_smr_exam_ty_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_d_smr_exam_ty_postprocessing | yes | no |
| VALUE | sp_nrt_d_smr_exam_ty_postprocessing | yes | no |

### dbo.D_SMR_EXAM_TY_GROUP

Writers:
- `sp_nrt_d_smr_exam_ty_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_SMR_EXAM_TY_GROUP_KEY | sp_nrt_d_smr_exam_ty_postprocessing | yes | no |

### dbo.D_TB_HIV

Writers:
- `sp_nrt_d_tb_hiv_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_TB_HIV_KEY | sp_nrt_d_tb_hiv_postprocessing | no | no |
| HIV_CITY_CNTY_PATIENT_NUM | sp_nrt_d_tb_hiv_postprocessing | no | no |
| HIV_STATE_PATIENT_NUM | sp_nrt_d_tb_hiv_postprocessing | no | no |
| HIV_STATUS | sp_nrt_d_tb_hiv_postprocessing | no | no |
| LAST_CHG_TIME | sp_nrt_d_tb_hiv_postprocessing | no | no |
| TB_PAM_UID | sp_nrt_d_tb_hiv_postprocessing | no | no |

### dbo.D_TB_PAM

Writers:
- `sp_nrt_d_tb_pam_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CALC_DISEASE_SITE | sp_nrt_d_tb_pam_postprocessing | no | no |
| CASE_VERIFICATION | sp_nrt_d_tb_pam_postprocessing | no | no |
| CHEST_XRAY_CAVITY_EVIDENCE | sp_nrt_d_tb_pam_postprocessing | no | no |
| CHEST_XRAY_MILIARY_EVIDENCE | sp_nrt_d_tb_pam_postprocessing | no | no |
| CHEST_XRAY_RESULT | sp_nrt_d_tb_pam_postprocessing | no | no |
| COMMENTS_FOLLOW_UP_1 | sp_nrt_d_tb_pam_postprocessing | no | no |
| COMMENTS_FOLLOW_UP_2 | sp_nrt_d_tb_pam_postprocessing | no | no |
| CORRECTIONAL_FACIL_CUSTODY_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| CORRECTIONAL_FACIL_RESIDENT | sp_nrt_d_tb_pam_postprocessing | no | no |
| CORRECTIONAL_FACIL_TY | sp_nrt_d_tb_pam_postprocessing | no | no |
| COUNT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| COUNT_STATUS | sp_nrt_d_tb_pam_postprocessing | no | no |
| COUNTRY_OF_VERIFIED_CASE | sp_nrt_d_tb_pam_postprocessing | no | no |
| CT_SCAN_CAVITY_EVIDENCE | sp_nrt_d_tb_pam_postprocessing | no | no |
| CT_SCAN_MILIARY_EVIDENCE | sp_nrt_d_tb_pam_postprocessing | no | no |
| CT_SCAN_RESULT | sp_nrt_d_tb_pam_postprocessing | no | no |
| CULT_TISSUE_COLLECT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| CULT_TISSUE_RESULT | sp_nrt_d_tb_pam_postprocessing | no | no |
| CULT_TISSUE_RESULT_RPT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| CULT_TISSUE_RESULT_RPT_LAB_TY | sp_nrt_d_tb_pam_postprocessing | no | no |
| CULT_TISSUE_SITE | sp_nrt_d_tb_pam_postprocessing | no | no |
| D_TB_PAM_KEY | sp_nrt_d_tb_pam_postprocessing | no | no |
| DATE_ARRIVED_IN_US | sp_nrt_d_tb_pam_postprocessing | no | no |
| DATE_SUBMITTED | sp_nrt_d_tb_pam_postprocessing | no | no |
| DISEASE_SITE | sp_nrt_d_tb_pam_postprocessing | no | no |
| DOT | sp_nrt_d_tb_pam_postprocessing | no | no |
| DOT_NUMBER_WEEKS | sp_nrt_d_tb_pam_postprocessing | no | no |
| EXCESS_ALCOHOL_USE_PAST_YEAR | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_ISOLATE_COLLECT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_ISOLATE_IS_SPUTUM_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_ISOLATE_NOT_SPUTUM | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_AMIKACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_CAPREOMYCIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_CIPROFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_CYCLOSERINE | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_ETHAMBUTOL | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_ETHIONAMIDE | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_ISONIAZID | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_KANAMYCIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_LEVOFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_MOXIFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_OFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_2 | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_2_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_QUINOLONES | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_PA_SALICYLIC_ACI | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_PYRAZINAMIDE | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_RIFABUTIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_RIFAMPIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_RIFAPENTINE | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_STREPTOMYCIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| FINAL_SUSCEPT_TESTING | sp_nrt_d_tb_pam_postprocessing | no | no |
| FIRST_ISOLATE_COLLECT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| FIRST_ISOLATE_IS_SPUTUM_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| FIRST_ISOLATE_NOT_SPUTUM | sp_nrt_d_tb_pam_postprocessing | no | no |
| HIV_CITY_CNTY_PATIENT_NUM | sp_nrt_d_tb_pam_postprocessing | no | no |
| HIV_STATE_PATIENT_NUM | sp_nrt_d_tb_pam_postprocessing | no | no |
| HIV_STATUS | sp_nrt_d_tb_pam_postprocessing | no | no |
| HOMELESS_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| IGRA_COLLECT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| IGRA_RESULT | sp_nrt_d_tb_pam_postprocessing | no | no |
| IGRA_TEST_TY | sp_nrt_d_tb_pam_postprocessing | no | no |
| IMMIGRATION_STATUS_AT_US_ENTRY | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_DRUG_REG_CALC | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_AMIKACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_CAPREOMYCIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_CIPROFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_CYCLOSERINE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_ETHAMBUTOL | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_ETHIONAMIDE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_ISONIAZID | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_KANAMYCIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_LEVOFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_MOXIFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_OFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_OTHER_1 | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_OTHER_1_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_OTHER_2 | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_OTHER_2_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_PA_SALICYLIC_ACID | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_PYRAZINAMIDE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_RIFABUTIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_RIFAMPIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_RIFAPENTINE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_START_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_REGIMEN_STREPTOMYCIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_AMIKACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_CAPREOMYCIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_CIPROFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_CYCLOSERINE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_ETHAMBUTOL | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_ETHIONAMIDE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_ISONIAZID | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_KANAMYCIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_LEVOFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_MOXIFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_OFLOXACIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_1 | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_1_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_2 | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_2_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_QUNINOLONES | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_PA_SALICYLIC_ACID | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_PYRAZINAMIDE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_RIFABUTIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_RIFAMPIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_RIFAPENTINE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_STREPTOMYCIN | sp_nrt_d_tb_pam_postprocessing | no | no |
| INIT_SUSCEPT_TESTING_DONE | sp_nrt_d_tb_pam_postprocessing | no | no |
| INJECT_DRUG_USE_PAST_YEAR | sp_nrt_d_tb_pam_postprocessing | no | no |
| ISOLATE_ACCESSION_NUM | sp_nrt_d_tb_pam_postprocessing | no | no |
| ISOLATE_SUBMITTED_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| LAST_CHG_TIME | sp_nrt_d_tb_pam_postprocessing | no | no |
| LINK_REASON_1 | sp_nrt_d_tb_pam_postprocessing | no | no |
| LINK_REASON_2 | sp_nrt_d_tb_pam_postprocessing | no | no |
| LINK_STATE_CASE_NUM_1 | sp_nrt_d_tb_pam_postprocessing | no | no |
| LINK_STATE_CASE_NUM_2 | sp_nrt_d_tb_pam_postprocessing | no | no |
| LONGTERM_CARE_FACIL_RESIDENT | sp_nrt_d_tb_pam_postprocessing | no | no |
| LONGTERM_CARE_FACIL_TY | sp_nrt_d_tb_pam_postprocessing | no | no |
| MOVE_CITY | sp_nrt_d_tb_pam_postprocessing | no | no |
| MOVE_CITY_2 | sp_nrt_d_tb_pam_postprocessing | no | no |
| MOVED_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| NAA_COLLECT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| NAA_RESULT | sp_nrt_d_tb_pam_postprocessing | no | no |
| NAA_RESULT_RPT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| NAA_RPT_LAB_TY | sp_nrt_d_tb_pam_postprocessing | no | no |
| NAA_SPEC_IS_SPUTUM_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| NAA_SPEC_NOT_SPUTUM | sp_nrt_d_tb_pam_postprocessing | no | no |
| NO_CONV_DOC_OTHER_REASON | sp_nrt_d_tb_pam_postprocessing | no | no |
| NO_CONV_DOC_REASON | sp_nrt_d_tb_pam_postprocessing | no | no |
| NONINJECT_DRUG_USE_PAST_YEAR | sp_nrt_d_tb_pam_postprocessing | no | no |
| OCCUPATION_RISK | sp_nrt_d_tb_pam_postprocessing | no | no |
| OTHER_TB_RISK_FACTORS | sp_nrt_d_tb_pam_postprocessing | no | no |
| PATIENT_BIRTH_COUNTRY | sp_nrt_d_tb_pam_postprocessing | no | no |
| PATIENT_OUTSIDE_US_GT_2_MONTHS | sp_nrt_d_tb_pam_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_YEAR | sp_nrt_d_tb_pam_postprocessing | no | no |
| PRIMARY_GUARD_1_BIRTH_COUNTRY | sp_nrt_d_tb_pam_postprocessing | no | no |
| PRIMARY_GUARD_2_BIRTH_COUNTRY | sp_nrt_d_tb_pam_postprocessing | no | no |
| PRIMARY_REASON_EVALUATED | sp_nrt_d_tb_pam_postprocessing | no | no |
| PROVIDER_OVERRIDE_COMMENTS | sp_nrt_d_tb_pam_postprocessing | no | no |
| SMR_PATH_CYTO_COLLECT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| SMR_PATH_CYTO_RESULT | sp_nrt_d_tb_pam_postprocessing | no | no |
| SMR_PATH_CYTO_SITE | sp_nrt_d_tb_pam_postprocessing | no | no |
| SPUTUM_CULT_COLLECT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| SPUTUM_CULT_RESULT_RPT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| SPUTUM_CULT_RPT_LAB_TY | sp_nrt_d_tb_pam_postprocessing | no | no |
| SPUTUM_CULTURE_CONV_DOCUMENTED | sp_nrt_d_tb_pam_postprocessing | no | no |
| SPUTUM_CULTURE_RESULT | sp_nrt_d_tb_pam_postprocessing | no | no |
| SPUTUM_SMEAR_COLLECT_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| SPUTUM_SMEAR_RESULT | sp_nrt_d_tb_pam_postprocessing | no | no |
| STATUS_AT_DIAGNOSIS | sp_nrt_d_tb_pam_postprocessing | no | no |
| TB_PAM_UID | sp_nrt_d_tb_pam_postprocessing | no | no |
| TB_SPUTUM_CULTURE_NEGATIVE_DAT | sp_nrt_d_tb_pam_postprocessing | no | no |
| TB_VERCRIT_CALC_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| THERAPY_EXTEND_GT_12_OTHER | sp_nrt_d_tb_pam_postprocessing | no | no |
| THERAPY_STOP_CAUSE_OF_DEATH | sp_nrt_d_tb_pam_postprocessing | no | no |
| THERAPY_STOP_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| THERAPY_STOP_REASON | sp_nrt_d_tb_pam_postprocessing | no | no |
| TRANSNATIONAL_REFERRAL_IND | sp_nrt_d_tb_pam_postprocessing | no | no |
| TST_MM_INDURATION | sp_nrt_d_tb_pam_postprocessing | no | no |
| TST_PLACED_DATE | sp_nrt_d_tb_pam_postprocessing | no | no |
| TST_RESULT | sp_nrt_d_tb_pam_postprocessing | no | no |
| US_BORN_IND | sp_nrt_d_tb_pam_postprocessing | no | no |

### dbo.D_VACCINATION

Writers:
- `sp_d_vaccination_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_TIME | sp_d_vaccination_postprocessing | yes | no |
| ADD_USER_ID | sp_d_vaccination_postprocessing | yes | no |
| AGE_AT_VACCINATION | sp_d_vaccination_postprocessing | yes | no |
| AGE_AT_VACCINATION_UNIT | sp_d_vaccination_postprocessing | yes | no |
| D_VACCINATION_KEY | sp_d_vaccination_postprocessing | yes | no |
| ELECTRONIC_IND | sp_d_vaccination_postprocessing | yes | no |
| LAST_CHG_TIME | sp_d_vaccination_postprocessing | yes | no |
| LAST_CHG_USER_ID | sp_d_vaccination_postprocessing | yes | no |
| LOCAL_ID | sp_d_vaccination_postprocessing | yes | no |
| RDB_COLUMN_NM | sp_d_vaccination_postprocessing | yes | no |
| RECORD_STATUS_CD | sp_d_vaccination_postprocessing | yes | no |
| RECORD_STATUS_TIME | sp_d_vaccination_postprocessing | yes | no |
| THEN | sp_d_vaccination_postprocessing | yes | no |
| VACCINATION_ADMINISTERED_NM | sp_d_vaccination_postprocessing | yes | no |
| VACCINATION_ANATOMICAL_SITE | sp_d_vaccination_postprocessing | yes | no |
| VACCINATION_UID | sp_d_vaccination_postprocessing | yes | no |
| VACCINE_ADMINISTERED_DATE | sp_d_vaccination_postprocessing | yes | no |
| VACCINE_DOSE_NBR | sp_d_vaccination_postprocessing | yes | no |
| VACCINE_EXPIRATION_DT | sp_d_vaccination_postprocessing | yes | no |
| VACCINE_INFO_SOURCE | sp_d_vaccination_postprocessing | yes | no |
| VACCINE_LOT_NUMBER_TXT | sp_d_vaccination_postprocessing | yes | no |
| VACCINE_MANUFACTURER_NM | sp_d_vaccination_postprocessing | yes | no |
| VERSION_CTRL_NBR | sp_d_vaccination_postprocessing | yes | no |

### dbo.D_VAR_PAM

Writers:
- `sp_nrt_d_var_pam_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| COMPLICATIONS | sp_nrt_d_var_pam_postprocessing | no | no |
| COMPLICATIONS_CEREB_ATAXIA | sp_nrt_d_var_pam_postprocessing | no | no |
| COMPLICATIONS_DEHYDRATION | sp_nrt_d_var_pam_postprocessing | no | no |
| COMPLICATIONS_ENCEPHALITIS | sp_nrt_d_var_pam_postprocessing | no | no |
| COMPLICATIONS_HEMORRHAGIC | sp_nrt_d_var_pam_postprocessing | no | no |
| COMPLICATIONS_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| COMPLICATIONS_OTHER_SPECIFY | sp_nrt_d_var_pam_postprocessing | no | no |
| COMPLICATIONS_PNEU_DIAG_BY | sp_nrt_d_var_pam_postprocessing | no | no |
| COMPLICATIONS_PNEUMONIA | sp_nrt_d_var_pam_postprocessing | no | no |
| COMPLICATIONS_SKIN_INFECTION | sp_nrt_d_var_pam_postprocessing | no | no |
| CROPS_WAVES | sp_nrt_d_var_pam_postprocessing | no | no |
| CULTURE_TEST | sp_nrt_d_var_pam_postprocessing | no | no |
| CULTURE_TEST_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| CULTURE_TEST_RESULT | sp_nrt_d_var_pam_postprocessing | no | no |
| D_VAR_PAM_KEY | sp_nrt_d_var_pam_postprocessing | no | no |
| DEATH_AUTOPSY | sp_nrt_d_var_pam_postprocessing | no | no |
| DEATH_CAUSE | sp_nrt_d_var_pam_postprocessing | no | no |
| DEATH_VARICELLA | sp_nrt_d_var_pam_postprocessing | no | no |
| DEATH_VARICELLA_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| DFA_TEST | sp_nrt_d_var_pam_postprocessing | no | no |
| DFA_TEST_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| DFA_TEST_RESULT | sp_nrt_d_var_pam_postprocessing | no | no |
| EPI_LINKED | sp_nrt_d_var_pam_postprocessing | no | no |
| EPI_LINKED_CASE_TYPE | sp_nrt_d_var_pam_postprocessing | no | no |
| FEVER | sp_nrt_d_var_pam_postprocessing | no | no |
| FEVER_DURATION_DAYS | sp_nrt_d_var_pam_postprocessing | no | no |
| FEVER_ONSET_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| FEVER_TEMPERATURE | sp_nrt_d_var_pam_postprocessing | no | no |
| FEVER_TEMPERATURE_UNIT | sp_nrt_d_var_pam_postprocessing | no | no |
| GENOTYPING_SENT_TO_CDC | sp_nrt_d_var_pam_postprocessing | no | no |
| GENOTYPING_SENT_TO_CDC_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| HEALTHCARE_WORKER | sp_nrt_d_var_pam_postprocessing | no | no |
| HEMORRHAGIC | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_ACUTE_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_ACUTE_RESULT | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_ACUTE_VALUE | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_CONVALESCENT_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_CONVALESCENT_RESULT | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_CONVALESCENT_VALUE | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_GP_ELISA_MFGR | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_TYPE | sp_nrt_d_var_pam_postprocessing | no | no |
| IGG_TEST_WHOLE_CELL_MFGR | sp_nrt_d_var_pam_postprocessing | no | no |
| IGM_TEST | sp_nrt_d_var_pam_postprocessing | no | no |
| IGM_TEST_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| IGM_TEST_RESULT | sp_nrt_d_var_pam_postprocessing | no | no |
| IGM_TEST_RESULT_VALUE | sp_nrt_d_var_pam_postprocessing | no | no |
| IGM_TEST_TYPE | sp_nrt_d_var_pam_postprocessing | no | no |
| IGM_TEST_TYPE_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| IMMUNOCOMPROMISED | sp_nrt_d_var_pam_postprocessing | no | no |
| IMMUNOCOMPROMISED_CONDITION | sp_nrt_d_var_pam_postprocessing | no | no |
| ITCHY | sp_nrt_d_var_pam_postprocessing | no | no |
| LAB_TESTING | sp_nrt_d_var_pam_postprocessing | no | no |
| LAB_TESTING_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| LAB_TESTING_OTHER_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| LAB_TESTING_OTHER_RESULT | sp_nrt_d_var_pam_postprocessing | no | no |
| LAB_TESTING_OTHER_RESULT_VALUE | sp_nrt_d_var_pam_postprocessing | no | no |
| LAB_TESTING_OTHER_SPECIFY | sp_nrt_d_var_pam_postprocessing | no | no |
| LAST_CHG_TIME | sp_nrt_d_var_pam_postprocessing | no | no |
| LESIONS_TOTAL | sp_nrt_d_var_pam_postprocessing | no | no |
| LESIONS_TOTAL_LT50 | sp_nrt_d_var_pam_postprocessing | no | no |
| MACULAR_PAPULAR | sp_nrt_d_var_pam_postprocessing | no | no |
| MACULES | sp_nrt_d_var_pam_postprocessing | no | no |
| MACULES_NUMBER | sp_nrt_d_var_pam_postprocessing | no | no |
| MEDICATION_NAME | sp_nrt_d_var_pam_postprocessing | no | no |
| MEDICATION_NAME_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| MEDICATION_START_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| MEDICATION_STOP_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| PAPULES | sp_nrt_d_var_pam_postprocessing | no | no |
| PAPULES_NUMBER | sp_nrt_d_var_pam_postprocessing | no | no |
| PATIENT_BIRTH_COUNTRY | sp_nrt_d_var_pam_postprocessing | no | no |
| PATIENT_VISIT_HC_PROVIDER | sp_nrt_d_var_pam_postprocessing | no | no |
| PCR_TEST | sp_nrt_d_var_pam_postprocessing | no | no |
| PCR_TEST_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| PCR_TEST_RESULT | sp_nrt_d_var_pam_postprocessing | no | no |
| PCR_TEST_RESULT_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| PCR_TEST_SOURCE_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| PREGNANT_TRIMESTER | sp_nrt_d_var_pam_postprocessing | no | no |
| PREGNANT_WEEKS | sp_nrt_d_var_pam_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS | sp_nrt_d_var_pam_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_AGE | sp_nrt_d_var_pam_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_AGE_UNIT | sp_nrt_d_var_pam_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_BY | sp_nrt_d_var_pam_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_BY_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| RASH_CRUST | sp_nrt_d_var_pam_postprocessing | no | no |
| RASH_CRUSTED_DAYS | sp_nrt_d_var_pam_postprocessing | no | no |
| RASH_DURATION_DAYS | sp_nrt_d_var_pam_postprocessing | no | no |
| RASH_LOCATION | sp_nrt_d_var_pam_postprocessing | no | no |
| RASH_LOCATION_DERMATOME | sp_nrt_d_var_pam_postprocessing | no | no |
| RASH_LOCATION_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| RASH_ONSET_DATE | sp_nrt_d_var_pam_postprocessing | no | no |
| SCABS | sp_nrt_d_var_pam_postprocessing | no | no |
| SEROLOGY_TEST | sp_nrt_d_var_pam_postprocessing | no | no |
| STRAIN_IDENTIFICATION_SENT | sp_nrt_d_var_pam_postprocessing | no | no |
| STRAIN_TYPE | sp_nrt_d_var_pam_postprocessing | no | no |
| TRANSMISSION_SETTING | sp_nrt_d_var_pam_postprocessing | no | no |
| TRANSMISSION_SETTING_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| TREATED | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_DATE_1 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_DATE_2 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_DATE_3 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_DATE_4 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_DATE_5 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_LOT_1 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_LOT_2 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_LOT_3 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_LOT_4 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_LOT_5 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_MANUFACTURER_1 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_MANUFACTURER_2 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_MANUFACTURER_3 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_MANUFACTURER_4 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_MANUFACTURER_5 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_TYPE_1 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_TYPE_2 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_TYPE_3 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_TYPE_4 | sp_nrt_d_var_pam_postprocessing | no | no |
| VACCINE_TYPE_5 | sp_nrt_d_var_pam_postprocessing | no | no |
| VAR_PAM_UID | sp_nrt_d_var_pam_postprocessing | no | no |
| VARICELLA_NO_2NDVACCINE_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| VARICELLA_NO_2NDVACCINE_REASON | sp_nrt_d_var_pam_postprocessing | no | no |
| VARICELLA_NO_VACCINE_OTHER | sp_nrt_d_var_pam_postprocessing | no | no |
| VARICELLA_NO_VACCINE_REASON | sp_nrt_d_var_pam_postprocessing | no | no |
| VARICELLA_VACCINE | sp_nrt_d_var_pam_postprocessing | no | no |
| VARICELLA_VACCINE_DOSES_NUMBER | sp_nrt_d_var_pam_postprocessing | no | no |
| VESICLES | sp_nrt_d_var_pam_postprocessing | no | no |
| VESICLES_NUMBER | sp_nrt_d_var_pam_postprocessing | no | no |
| VESICULAR | sp_nrt_d_var_pam_postprocessing | no | no |

### dbo.ETL_DQ_LOG

Writers:
- `sp_f_std_page_case_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_s_pagebuilder_postprocessing` (postprocessing) — ops: INSERT
- `sp_sld_investigation_repeat_postprocessing` (postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| DQ_ETL_PROCESS_COLUMN | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| DQ_ETL_PROCESS_TABLE | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| DQ_ISSUE_ANSWER_TXT | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| DQ_ISSUE_CD | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| DQ_ISSUE_DESC_TXT | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| DQ_ISSUE_QUESTION_IDENTIFIER | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| DQ_ISSUE_RDB_LOCATION | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| DQ_ISSUE_SOURCE_LOCATION | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| DQ_ISSUE_SOURCE_QUESTION_LABEL | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| DQ_STATUS_TIME | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| EVENT_LOCAL_ID | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| EVENT_TYPE | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| EVENT_UID | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |
| JOB_BATCH_LOG_UID | sp_f_std_page_case_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing | yes | no |

### dbo.EVENT_METRIC

Writers:
- `sp_event_metric_cleanup_postprocessing` (postprocessing) — ops: INSERT
- `sp_event_metric_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_TIME | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| ADD_USER_ID | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| ADD_USER_NAME | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| CASE_CLASS_CD | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| CASE_CLASS_DESC_TXT | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| CONDITION_CD | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| CONDITION_DESC_TXT | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| ELECTRONIC_IND | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| EVENT_TYPE | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| EVENT_UID | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS_CD | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS_DESC_TXT | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| JURISDICTION_CD | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| JURISDICTION_DESC_TXT | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| LAST_CHG_TIME | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| LAST_CHG_USER_ID | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| LAST_CHG_USER_NAME | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| LOCAL_ID | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| LOCAL_PATIENT_ID | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| PROG_AREA_CD | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| PROG_AREA_DESC_TXT | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| RECORD_STATUS_CD | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| RECORD_STATUS_DESC_TXT | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| RECORD_STATUS_TIME | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| STATUS_CD | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| STATUS_DESC_TXT | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |
| STATUS_TIME | sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing | no | no |

### dbo.EVENT_METRIC_INC

Writers:
- `sp_event_metric_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_TIME | sp_event_metric_datamart_postprocessing | no | no |
| ADD_USER_ID | sp_event_metric_datamart_postprocessing | no | no |
| ADD_USER_NAME | sp_event_metric_datamart_postprocessing | no | no |
| CASE_CLASS_CD | sp_event_metric_datamart_postprocessing | no | no |
| CASE_CLASS_DESC_TXT | sp_event_metric_datamart_postprocessing | no | no |
| CONDITION_CD | sp_event_metric_datamart_postprocessing | no | no |
| CONDITION_DESC_TXT | sp_event_metric_datamart_postprocessing | no | no |
| ELECTRONIC_IND | sp_event_metric_datamart_postprocessing | no | no |
| EVENT_TYPE | sp_event_metric_datamart_postprocessing | no | no |
| EVENT_UID | sp_event_metric_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS_CD | sp_event_metric_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS_DESC_TXT | sp_event_metric_datamart_postprocessing | no | no |
| JURISDICTION_CD | sp_event_metric_datamart_postprocessing | no | no |
| JURISDICTION_DESC_TXT | sp_event_metric_datamart_postprocessing | no | no |
| LAST_CHG_TIME | sp_event_metric_datamart_postprocessing | no | no |
| LAST_CHG_USER_ID | sp_event_metric_datamart_postprocessing | no | no |
| LAST_CHG_USER_NAME | sp_event_metric_datamart_postprocessing | no | no |
| LOCAL_ID | sp_event_metric_datamart_postprocessing | no | no |
| LOCAL_PATIENT_ID | sp_event_metric_datamart_postprocessing | no | no |
| PROG_AREA_CD | sp_event_metric_datamart_postprocessing | no | no |
| PROG_AREA_DESC_TXT | sp_event_metric_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_event_metric_datamart_postprocessing | no | no |
| RECORD_STATUS_CD | sp_event_metric_datamart_postprocessing | no | no |
| RECORD_STATUS_DESC_TXT | sp_event_metric_datamart_postprocessing | no | no |
| RECORD_STATUS_TIME | sp_event_metric_datamart_postprocessing | no | no |
| STATUS_CD | sp_event_metric_datamart_postprocessing | no | no |
| STATUS_DESC_TXT | sp_event_metric_datamart_postprocessing | no | no |
| STATUS_TIME | sp_event_metric_datamart_postprocessing | no | no |

### dbo.F_CONTACT_RECORD_CASE

Writers:
- `sp_f_contact_record_case_postprocessing` (postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CONTACT_EXPOSURE_SITE_KEY | sp_f_contact_record_case_postprocessing | no | no |
| CONTACT_INTERVIEW_KEY | sp_f_contact_record_case_postprocessing | no | no |
| CONTACT_INVESTIGATION_KEY | sp_f_contact_record_case_postprocessing | no | no |
| CONTACT_INVESTIGATOR_KEY | sp_f_contact_record_case_postprocessing | no | no |
| CONTACT_KEY | sp_f_contact_record_case_postprocessing | no | no |
| D_CONTACT_RECORD_KEY | sp_f_contact_record_case_postprocessing | no | no |
| DISPOSITIONED_BY_KEY | sp_f_contact_record_case_postprocessing | no | no |
| SUBJECT_INVESTIGATION_KEY | sp_f_contact_record_case_postprocessing | no | no |
| SUBJECT_KEY | sp_f_contact_record_case_postprocessing | no | no |
| THIRD_PARTY_ENTITY_KEY | sp_f_contact_record_case_postprocessing | no | no |
| THIRD_PARTY_INVESTIGATION_KEY | sp_f_contact_record_case_postprocessing | no | no |

### dbo.F_INTERVIEW_CASE

Writers:
- `sp_f_interview_case_postprocessing` (postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_INTERVIEW_KEY | sp_f_interview_case_postprocessing | no | no |
| INTERPRETER_KEY | sp_f_interview_case_postprocessing | no | no |
| INTERVENTION_SITE_KEY | sp_f_interview_case_postprocessing | no | no |
| INVESTIGATION_KEY | sp_f_interview_case_postprocessing | no | no |
| IX_INTERVIEWEE_KEY | sp_f_interview_case_postprocessing | no | no |
| IX_INTERVIEWER_KEY | sp_f_interview_case_postprocessing | no | no |
| NURSE_KEY | sp_f_interview_case_postprocessing | no | no |
| PATIENT_KEY | sp_f_interview_case_postprocessing | no | no |
| PHYSICIAN_KEY | sp_f_interview_case_postprocessing | no | no |
| PROXY_KEY | sp_f_interview_case_postprocessing | no | no |

### dbo.F_PAGE_CASE

Writers:
- `sp_f_page_case_postprocessing` (postprocessing) — ops: INSERT_NOCOL

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| <all> | sp_f_page_case_postprocessing | no | no |

### dbo.F_STD_PAGE_CASE

Writers:
- `sp_f_std_page_case_postprocessing` (postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_DATE_KEY | sp_f_std_page_case_postprocessing | no | no |
| CLOSED_BY_KEY | sp_f_std_page_case_postprocessing | no | no |
| CONDITION_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_ADMINISTRATIVE_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_CLINICAL_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_COMPLICATION_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_CONTACT_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_DEATH_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_EPIDEMIOLOGY_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_HIV_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_ISOLATE_TRACKING_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_LAB_FINDING_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_MEDICAL_HISTORY_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_MOTHER_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_OTHER_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_PATIENT_OBS_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_PLACE_REPEAT_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_PREGNANCY_BIRTH_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_RESIDENCY_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_RISK_FACTOR_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_SOCIAL_HISTORY_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_SYMPTOM_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_TRAVEL_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_TREATMENT_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_UNDER_CONDITION_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INV_VACCINATION_KEY | sp_f_std_page_case_postprocessing | no | no |
| D_INVESTIGATION_REPEAT_KEY | sp_f_std_page_case_postprocessing | no | no |
| DELIVERING_HOSP_KEY | sp_f_std_page_case_postprocessing | no | no |
| DELIVERING_MD_KEY | sp_f_std_page_case_postprocessing | no | no |
| DISPOSITIONED_BY_KEY | sp_f_std_page_case_postprocessing | no | no |
| FACILITY_FLD_FOLLOW_UP_KEY | sp_f_std_page_case_postprocessing | no | no |
| GEOCODING_LOCATION_KEY | sp_f_std_page_case_postprocessing | no | no |
| HOSPITAL_KEY | sp_f_std_page_case_postprocessing | no | no |
| INIT_ASGNED_FLD_FOLLOW_UP_KEY | sp_f_std_page_case_postprocessing | no | no |
| INIT_ASGNED_INTERVIEWER_KEY | sp_f_std_page_case_postprocessing | no | no |
| INIT_FOLLOW_UP_INVSTGTR_KEY | sp_f_std_page_case_postprocessing | no | no |
| INTERVIEWER_ASSIGNED_KEY | sp_f_std_page_case_postprocessing | no | no |
| INVESTIGATION_KEY | sp_f_std_page_case_postprocessing | no | no |
| INVESTIGATOR_KEY | sp_f_std_page_case_postprocessing | no | no |
| INVSTGTR_FLD_FOLLOW_UP_KEY | sp_f_std_page_case_postprocessing | no | no |
| LAST_CHG_DATE_KEY | sp_f_std_page_case_postprocessing | no | no |
| MOTHER_OB_GYN_KEY | sp_f_std_page_case_postprocessing | no | no |
| ORDERING_FACILITY_KEY | sp_f_std_page_case_postprocessing | no | no |
| ORG_AS_REPORTER_KEY | sp_f_std_page_case_postprocessing | no | no |
| PATIENT_KEY | sp_f_std_page_case_postprocessing | no | no |
| PEDIATRICIAN_KEY | sp_f_std_page_case_postprocessing | no | no |
| PERSON_AS_REPORTER_KEY | sp_f_std_page_case_postprocessing | no | no |
| PHYSICIAN_KEY | sp_f_std_page_case_postprocessing | no | no |
| PROVIDER_FLD_FOLLOW_UP_KEY | sp_f_std_page_case_postprocessing | no | no |
| SUPRVSR_OF_CASE_ASSGNMENT_KEY | sp_f_std_page_case_postprocessing | no | no |
| SUPRVSR_OF_FLD_FOLLOW_UP_KEY | sp_f_std_page_case_postprocessing | no | no |
| SURVEILLANCE_INVESTIGATOR_KEY | sp_f_std_page_case_postprocessing | no | no |

### dbo.F_TB_PAM

Writers:
- `sp_f_tb_pam_postprocessing` (postprocessing) — ops: INSERT
- `sp_nrt_d_addl_risk_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_disease_site_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_gt_12_reas_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_hc_prov_ty_3_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_move_cntry_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_move_cnty_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_move_state_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_moved_where_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_out_of_cntry_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_smr_exam_ty_postprocessing` (nrt_postprocessing) — ops: UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_DATE_KEY | sp_f_tb_pam_postprocessing | no | no |
| D_ADDL_RISK_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_addl_risk_postprocessing | no | no |
| D_DISEASE_SITE_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_disease_site_postprocessing | no | no |
| D_GT_12_REAS_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_gt_12_reas_postprocessing | no | no |
| D_HC_PROV_TY_3_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing | no | no |
| D_MOVE_CNTRY_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_move_cntry_postprocessing | no | no |
| D_MOVE_CNTY_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_move_cnty_postprocessing | no | no |
| D_MOVE_STATE_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_move_state_postprocessing | no | no |
| D_MOVED_WHERE_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_moved_where_postprocessing | no | no |
| D_OUT_OF_CNTRY_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_out_of_cntry_postprocessing | no | no |
| D_SMR_EXAM_TY_GROUP_KEY | sp_f_tb_pam_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing | no | no |
| D_TB_PAM_KEY | sp_f_tb_pam_postprocessing | no | no |
| HOSPITAL_KEY | sp_f_tb_pam_postprocessing | no | no |
| INVESTIGATION_KEY | sp_f_tb_pam_postprocessing | no | no |
| LAST_CHG_DATE_KEY | sp_f_tb_pam_postprocessing | no | no |
| ORG_AS_REPORTER_KEY | sp_f_tb_pam_postprocessing | no | no |
| PERSON_AS_REPORTER_KEY | sp_f_tb_pam_postprocessing | no | no |
| PERSON_KEY | sp_f_tb_pam_postprocessing | no | no |
| PHYSICIAN_KEY | sp_f_tb_pam_postprocessing | no | no |
| PROVIDER_KEY | sp_f_tb_pam_postprocessing | no | no |

### dbo.F_VACCINATION

Writers:
- `sp_f_vaccination_postprocessing` (postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_VACCINATION_KEY | sp_f_vaccination_postprocessing | no | no |
| D_VACCINATION_REPEAT_KEY | sp_f_vaccination_postprocessing | no | no |
| INVESTIGATION_KEY | sp_f_vaccination_postprocessing | no | no |
| PATIENT_KEY | sp_f_vaccination_postprocessing | no | no |
| VACCINE_GIVEN_BY_KEY | sp_f_vaccination_postprocessing | no | no |
| VACCINE_GIVEN_BY_ORG_KEY | sp_f_vaccination_postprocessing | no | no |

### dbo.F_VAR_PAM

Writers:
- `sp_f_var_pam_postprocessing` (postprocessing) — ops: INSERT
- `sp_nrt_d_pcr_source_postprocessing` (nrt_postprocessing) — ops: UPDATE
- `sp_nrt_d_rash_loc_gen_postprocessing` (nrt_postprocessing) — ops: UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_DATE_KEY | sp_f_var_pam_postprocessing | no | no |
| D_PCR_SOURCE_GROUP_KEY | sp_f_var_pam_postprocessing, sp_nrt_d_pcr_source_postprocessing | no | no |
| D_RASH_LOC_GEN_GROUP_KEY | sp_f_var_pam_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing | no | no |
| D_VAR_PAM_KEY | sp_f_var_pam_postprocessing | no | no |
| HOSPITAL_KEY | sp_f_var_pam_postprocessing | no | no |
| INVESTIGATION_KEY | sp_f_var_pam_postprocessing | no | no |
| LAST_CHG_DATE_KEY | sp_f_var_pam_postprocessing | no | no |
| ORG_AS_REPORTER_KEY | sp_f_var_pam_postprocessing | no | no |
| PERSON_AS_REPORTER_KEY | sp_f_var_pam_postprocessing | no | no |
| PERSON_KEY | sp_f_var_pam_postprocessing | no | no |
| PHYSICIAN_KEY | sp_f_var_pam_postprocessing | no | no |
| PROVIDER_KEY | sp_f_var_pam_postprocessing | no | no |

### dbo.HEP100

Writers:
- `sp_hep100_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE
- `sp_patient_dim_columns_update_to_datamart` (datamart) — ops: UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADDR_CD_DESC | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| ADDR_USE_CD_DESC | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| ALT_RESULT_DT | sp_hep100_datamart_postprocessing | no | no |
| ALT_SGPT_RESULT | sp_hep100_datamart_postprocessing | no | no |
| ALT_SGPT_RESULT_UPPER_LIMIT | sp_hep100_datamart_postprocessing | no | no |
| ANTI_HBS_POSITIVE_REACTIVE_IND | sp_hep100_datamart_postprocessing | no | no |
| ANTI_HBSAG_TESTED_IND | sp_hep100_datamart_postprocessing | no | no |
| ANTIHCV_SIGNAL_TO_CUTOFF_RATIO | sp_hep100_datamart_postprocessing | no | no |
| ANTIHCV_SUPPLEMENTAL_ASSAY | sp_hep100_datamart_postprocessing | no | no |
| ASSOCIATED_OUTBRK_TYPE | sp_hep100_datamart_postprocessing | no | no |
| AST_RESULT_DT | sp_hep100_datamart_postprocessing | no | no |
| AST_SGOT_RESULT | sp_hep100_datamart_postprocessing | no | no |
| AST_SGOT_RESULT_UPPER_LIMIT | sp_hep100_datamart_postprocessing | no | no |
| B_INCARCERATED24PLUSHRSIN6WKMO | sp_hep100_datamart_postprocessing | no | no |
| B_INCARCERATED_6PLUS_MON_IND | sp_hep100_datamart_postprocessing | no | no |
| B_LAST6PLUSMON_INCARCERATE_YR | sp_hep100_datamart_postprocessing | no | no |
| B_LAST_INCARCERATE_PERIOD_UNIT | sp_hep100_datamart_postprocessing | no | no |
| BLAST6PLUSMO_INCARCERATEPERIOD | sp_hep100_datamart_postprocessing | no | no |
| BLOOD_CONTAMINATION_IN6WKMON | sp_hep100_datamart_postprocessing | no | no |
| BLOOD_CONTAMINATION_IN_2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| BLOOD_EXPOSURE_IN2WK6MO_OTHER | sp_hep100_datamart_postprocessing | no | no |
| BLOOD_EXPOSURE_IN6WKMON_OTHER | sp_hep100_datamart_postprocessing | no | no |
| BLOOD_EXPOSURE_IN_LAST2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| BLOOD_EXPOSURE_IN_LAST6WKMON | sp_hep100_datamart_postprocessing | no | no |
| BLOOD_TRANSFUSION_BEFORE_1992 | sp_hep100_datamart_postprocessing | no | no |
| C_INCARCERATED_6PLUS_MON_IND | sp_hep100_datamart_postprocessing | no | no |
| C_LAST6PLUSMON_INCARCERATE_YR | sp_hep100_datamart_postprocessing | no | no |
| C_LAST_INCARCERATE_PERIOD_UNIT | sp_hep100_datamart_postprocessing | no | no |
| CASE_RPT_MMWR_WEEK | sp_hep100_datamart_postprocessing | no | no |
| CASE_RPT_MMWR_YEAR | sp_hep100_datamart_postprocessing | no | no |
| CASE_UID | sp_hep100_datamart_postprocessing | no | no |
| CLAST6PLUSMO_INCARCERATEPERIOD | sp_hep100_datamart_postprocessing | no | no |
| CLOT_FACTOR_CONCERN_BEFORE1987 | sp_hep100_datamart_postprocessing | no | no |
| CONDITION | sp_hep100_datamart_postprocessing | no | no |
| CONDITION_CD | sp_hep100_datamart_postprocessing | no | no |
| D_N_P_EMPLOYEE_IND | sp_hep100_datamart_postprocessing | no | no |
| D_N_P_HOUSEHOLD_CONTACT_IND | sp_hep100_datamart_postprocessing | no | no |
| DEN_WORK_OR_SURGERY_IN2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| DEN_WORK_OR_SURGERY_IN6WKMON | sp_hep100_datamart_postprocessing | no | no |
| DIAGNOSIS_DT | sp_hep100_datamart_postprocessing | no | no |
| DIE_FRM_THIS_ILLNESS_IND | sp_hep100_datamart_postprocessing | no | no |
| DISEASE_IMPORTED_IND | sp_hep100_datamart_postprocessing | no | no |
| EARLIEST_RPT_TO_CNTY_DT | sp_hep100_datamart_postprocessing | no | no |
| EARLIEST_RPT_TO_STATE_DT | sp_hep100_datamart_postprocessing | no | no |
| EVENT_DATE | sp_hep100_datamart_postprocessing | no | no |
| EVER_INCARCERATED_IND | sp_hep100_datamart_postprocessing | no | no |
| EVER_INJECT_NONPRESCRIBED_DRUG | sp_hep100_datamart_postprocessing | no | no |
| FOODBORNE_OUTBRK_FOOD_ITEM | sp_hep100_datamart_postprocessing | no | no |
| FOODHANDLER_2_WK_PRIOR_ONSET | sp_hep100_datamart_postprocessing | no | no |
| GLOBULIN_LAST_RECEIVED_YR | sp_hep100_datamart_postprocessing | no | no |
| HCV_RNA | sp_hep100_datamart_postprocessing | no | no |
| HEMODIALYSIS_IN_LAST_2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| HEMODIALYSIS_IN_LAST_6WKMON | sp_hep100_datamart_postprocessing | no | no |
| HEP_A_CONTACTED_IND | sp_hep100_datamart_postprocessing | no | no |
| HEP_A_EPLINK_IND | sp_hep100_datamart_postprocessing | no | no |
| HEP_A_IGM_ANTIBODY | sp_hep100_datamart_postprocessing | no | no |
| HEP_A_KEYENT_IN_CHILDCARE_IND | sp_hep100_datamart_postprocessing | no | no |
| HEP_A_TOTAL_ANTIBODY | sp_hep100_datamart_postprocessing | no | no |
| HEP_A_VACC_LAST_RECEIVED_YR | sp_hep100_datamart_postprocessing | no | no |
| HEP_A_VACC_RECEIVED_DOSE | sp_hep100_datamart_postprocessing | no | no |
| HEP_A_VACC_RECEIVED_IND | sp_hep100_datamart_postprocessing | no | no |
| HEP_B_CONTACTED_IND | sp_hep100_datamart_postprocessing | no | no |
| HEP_B_DNA | sp_hep100_datamart_postprocessing | no | no |
| HEP_B_E_ANTIGEN | sp_hep100_datamart_postprocessing | no | no |
| HEP_B_IGM_ANTIBODY | sp_hep100_datamart_postprocessing | no | no |
| HEP_B_SURFACE_ANTIGEN | sp_hep100_datamart_postprocessing | no | no |
| HEP_B_TOTAL_ANTIBODY | sp_hep100_datamart_postprocessing | no | no |
| HEP_B_VACC_LAST_RECEIVED_YR | sp_hep100_datamart_postprocessing | no | no |
| HEP_B_VACC_RECEIVED_IND | sp_hep100_datamart_postprocessing | no | no |
| HEP_B_VACC_SHOT_RECEIVED_NBR | sp_hep100_datamart_postprocessing | no | no |
| HEP_C_CONTACTED_IND | sp_hep100_datamart_postprocessing | no | no |
| HEP_C_TOTAL_ANTIBODY | sp_hep100_datamart_postprocessing | no | no |
| HEP_D_TOTAL_ANTIBODY | sp_hep100_datamart_postprocessing | no | no |
| HEP_E_TOTAL_ANTIBODY | sp_hep100_datamart_postprocessing | no | no |
| HEP_MULTI_VAL_GRP_KEY | sp_hep100_datamart_postprocessing | no | no |
| HEPA_FEMALE_SEX_PARTNER_NBR | sp_hep100_datamart_postprocessing | no | no |
| HEPA_MALE_SEX_PARTNER_NBR | sp_hep100_datamart_postprocessing | no | no |
| HEPATITIS_CONTACT_TYPE | sp_hep100_datamart_postprocessing | no | no |
| HEPATITIS_CONTACTED_IND | sp_hep100_datamart_postprocessing | no | no |
| HEPATITIS_OTHER_CONTACT_TYPE | sp_hep100_datamart_postprocessing | no | no |
| HEPB_BLOOD_RECEIVED_DT | sp_hep100_datamart_postprocessing | no | no |
| HEPB_BLOOD_RECEIVED_IN6WKMON | sp_hep100_datamart_postprocessing | no | no |
| HEPB_FEMALE_SEX_PARTNER_NBR | sp_hep100_datamart_postprocessing | no | no |
| HEPB_MALE_SEX_PARTNER_NBR | sp_hep100_datamart_postprocessing | no | no |
| HEPB_MED_DEN_BLOOD_CONTACT_FRQ | sp_hep100_datamart_postprocessing | no | no |
| HEPB_MED_DEN_EMPLOYEE_IN6WKMON | sp_hep100_datamart_postprocessing | no | no |
| HEPB_PUB_SAFETY_WORKER_IN6WKMO | sp_hep100_datamart_postprocessing | no | no |
| HEPB_PUBSAFETY_BLOODCONTACTFRQ | sp_hep100_datamart_postprocessing | no | no |
| HEPB_STD_LAST_TREATMENT_YR | sp_hep100_datamart_postprocessing | no | no |
| HEPB_STD_TREATED_IND | sp_hep100_datamart_postprocessing | no | no |
| HEPC_BLOOD_RECEIVED_DT | sp_hep100_datamart_postprocessing | no | no |
| HEPC_BLOOD_RECEIVED_IN_2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| HEPC_FEMALE_SEX_PARTNER_NBR | sp_hep100_datamart_postprocessing | no | no |
| HEPC_MALE_SEX_PARTNER_NBR | sp_hep100_datamart_postprocessing | no | no |
| HEPC_MED_DEN_BLOOD_CONTACT_FRQ | sp_hep100_datamart_postprocessing | no | no |
| HEPC_MED_DEN_EMPLOYEE_IND | sp_hep100_datamart_postprocessing | no | no |
| HEPC_PUBSAFETY_BLOODCONTACTFRQ | sp_hep100_datamart_postprocessing | no | no |
| HEPC_STD_LAST_TREATMENT_YR | sp_hep100_datamart_postprocessing | no | no |
| HEPC_STD_TREATED_IND | sp_hep100_datamart_postprocessing | no | no |
| HOUSEHOLD_NPP_OUT_USA_CAN | sp_hep100_datamart_postprocessing | no | no |
| HSPTL_ADMISSION_DT | sp_hep100_datamart_postprocessing | no | no |
| HSPTL_DISCHARGE_DT | sp_hep100_datamart_postprocessing | no | no |
| HSPTL_DURATION_DAYS | sp_hep100_datamart_postprocessing | no | no |
| HSPTLIZD_IN2WK6MO_BEFORE_ONSET | sp_hep100_datamart_postprocessing | no | no |
| HSPTLIZD_IN6WKMON_BEFORE_ONSET | sp_hep100_datamart_postprocessing | no | no |
| HSPTLIZD_IND | sp_hep100_datamart_postprocessing | no | no |
| ILLNESS_ONSET_DT | sp_hep100_datamart_postprocessing | no | no |
| IMMUNE_GLOBULIN_RECEIVED_IND | sp_hep100_datamart_postprocessing | no | no |
| IMPORT_FROM_CITY | sp_hep100_datamart_postprocessing | no | no |
| IMPORT_FROM_COUNTRY | sp_hep100_datamart_postprocessing | no | no |
| IMPORT_FROM_COUNTY | sp_hep100_datamart_postprocessing | no | no |
| IMPORT_FROM_STATE | sp_hep100_datamart_postprocessing | no | no |
| INCARCERATED_24PLUSHRSIN2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| INV_CASE_STATUS | sp_hep100_datamart_postprocessing | no | no |
| INV_COMMENTS | sp_hep100_datamart_postprocessing | no | no |
| INV_JURISDICTION_NM | sp_hep100_datamart_postprocessing | no | no |
| INV_LOCAL_ID | sp_hep100_datamart_postprocessing | no | no |
| INV_RPT_DT | sp_hep100_datamart_postprocessing | no | no |
| INV_START_DT | sp_hep100_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_hep100_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS | sp_hep100_datamart_postprocessing | no | no |
| INVESTIGATOR_NAME | sp_hep100_datamart_postprocessing | no | no |
| INVESTIGATOR_UID | sp_hep100_datamart_postprocessing | no | no |
| LIFETIME_SEX_PARTNER_NBR | sp_hep100_datamart_postprocessing | no | no |
| LONGTERM_HEMODIALYSIS_IND | sp_hep100_datamart_postprocessing | no | no |
| LONGTERMCARE_RESIDENT_IN2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| LONGTERMCARE_RESIDENT_IN6WKMON | sp_hep100_datamart_postprocessing | no | no |
| MED_DEN_EMPLOYEE_IN_2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| NON_ORAL_SURGERY_IN2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| NON_ORAL_SURGERY_IN6WKMON | sp_hep100_datamart_postprocessing | no | no |
| ORGAN_TRANSPLANT_BEFORE_1992 | sp_hep100_datamart_postprocessing | no | no |
| OUTBREAK_IND | sp_hep100_datamart_postprocessing | no | no |
| OUTPATIENT_IV_INFUSION_IN6WKMO | sp_hep100_datamart_postprocessing | no | no |
| OUTPATIENT_IV_INFUSIONIN2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| PART_OF_AN_OUTBRK_IND | sp_hep100_datamart_postprocessing | no | no |
| PATIENT_ADDRESS | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_CITY | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_COUNTY | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_CURR_GENDER | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_DOB | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_ELECTRONIC_IND | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_FIRST_NM | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_JUNDICED_IND | sp_hep100_datamart_postprocessing | no | no |
| PATIENT_LAST_NM | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_LOCAL_ID | sp_hep100_datamart_postprocessing | no | no |
| PATIENT_MIDDLE_NM | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_PREGNANCY_DUE_DT | sp_hep100_datamart_postprocessing | no | no |
| PATIENT_PREGNANT_IND | sp_hep100_datamart_postprocessing | no | no |
| PATIENT_REPORTED_AGE_UNITS | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_REPORTEDAGE | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PATIENT_SYMPTOMATIC_IND | sp_hep100_datamart_postprocessing | no | no |
| PATIENT_UID | sp_hep100_datamart_postprocessing | no | no |
| PATIENT_ZIP_CODE | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| PHYSICIAN_ADDRESS_TYPE_DESC | sp_hep100_datamart_postprocessing | no | no |
| PHYSICIAN_ADDRESS_USE_DESC | sp_hep100_datamart_postprocessing | no | no |
| PHYSICIAN_CITY | sp_hep100_datamart_postprocessing | no | no |
| PHYSICIAN_COUNTY | sp_hep100_datamart_postprocessing | no | no |
| PHYSICIAN_NAME | sp_hep100_datamart_postprocessing | no | no |
| PHYSICIAN_STATE | sp_hep100_datamart_postprocessing | no | no |
| PHYSICIAN_UID | sp_hep100_datamart_postprocessing | no | no |
| PIERCING_IN2WK6MO_BEFORE_ONSET | sp_hep100_datamart_postprocessing | no | no |
| PIERCING_IN2WK6MO_LOCATION | sp_hep100_datamart_postprocessing | no | no |
| PIERCING_IN6WKMON_BEFORE_ONSET | sp_hep100_datamart_postprocessing | no | no |
| PLACE_OF_BIRTH | sp_hep100_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_hep100_datamart_postprocessing | no | no |
| PUBLIC_SAFETY_WORKER_IN_2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| RACE | sp_hep100_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | yes | no |
| REFRESH_DATETIME | sp_hep100_datamart_postprocessing | no | no |
| REPORTING_SOURCE | sp_hep100_datamart_postprocessing | no | no |
| REPORTING_SOURCE_ADDRESS_TYPE | sp_hep100_datamart_postprocessing | no | no |
| REPORTING_SOURCE_ADDRESS_USE | sp_hep100_datamart_postprocessing | no | no |
| REPORTING_SOURCE_CITY | sp_hep100_datamart_postprocessing | no | no |
| REPORTING_SOURCE_COUNTY | sp_hep100_datamart_postprocessing | no | no |
| REPORTING_SOURCE_STATE | sp_hep100_datamart_postprocessing | no | no |
| REPORTING_SOURCE_UID | sp_hep100_datamart_postprocessing | no | no |
| RPT_SRC_CD_DESC | sp_hep100_datamart_postprocessing | no | no |
| STREET_DRUG_INJECTED_IN6WKMON | sp_hep100_datamart_postprocessing | no | no |
| STREET_DRUG_INJECTED_IN_2_6_WK | sp_hep100_datamart_postprocessing | no | no |
| STREET_DRUG_INJECTED_IN_2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| STREET_DRUG_USED_IN6WKMON | sp_hep100_datamart_postprocessing | no | no |
| STREET_DRUG_USED_IN_2_6_WK | sp_hep100_datamart_postprocessing | no | no |
| STREET_DRUG_USED_IN_2WK6MO | sp_hep100_datamart_postprocessing | no | no |
| TATTOOED_IN2WK6MO_BEFORE_ONSET | sp_hep100_datamart_postprocessing | no | no |
| TATTOOED_IN2WK6MO_LOCATION | sp_hep100_datamart_postprocessing | no | no |
| TATTOOED_IN6WKMON_BEFORE_ONSET | sp_hep100_datamart_postprocessing | no | no |
| TRANSMISSION_MODE | sp_hep100_datamart_postprocessing | no | no |
| TRAVEL_OUT_USA_CAN_IND | sp_hep100_datamart_postprocessing | no | no |

### dbo.HEP_MULTI_VALUE_FIELD_GROUP

Writers:
- `sp_hepatitis_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| HEP_MULTI_VAL_GRP_KEY | sp_hepatitis_case_datamart_postprocessing | no | no |

### dbo.HEPATITIS_DATAMART

Writers:
- `sp_hepatitis_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE
- `sp_nrt_notification_postprocessing` (nrt_postprocessing) — ops: UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ALT_RESULT_DT | sp_hepatitis_datamart_postprocessing | no | no |
| ALT_SGPT_RESULT | sp_hepatitis_datamart_postprocessing | no | no |
| ALT_SGPT_RSLT_UP_LMT | sp_hepatitis_datamart_postprocessing | no | no |
| ANTI_HBS_POS_REAC_IND | sp_hepatitis_datamart_postprocessing | no | no |
| ANTI_HBSAG_TESTED_IND | sp_hepatitis_datamart_postprocessing | no | no |
| ANTIHCV_SIGCUT_RATIO | sp_hepatitis_datamart_postprocessing | no | no |
| ANTIHCV_SUPP_ASSAY | sp_hepatitis_datamart_postprocessing | no | no |
| AST_RESULT_DT | sp_hepatitis_datamart_postprocessing | no | no |
| AST_SGOT_RESULT | sp_hepatitis_datamart_postprocessing | no | no |
| AST_SGOT_RSLT_UP_LMT | sp_hepatitis_datamart_postprocessing | no | no |
| BINATIONAL_RPTNG_CRIT | sp_hepatitis_datamart_postprocessing | no | no |
| BLD_CONTAM_IND | sp_hepatitis_datamart_postprocessing | no | no |
| BLD_EXPOSURE_IND | sp_hepatitis_datamart_postprocessing | no | no |
| BLD_EXPOSURE_OTH | sp_hepatitis_datamart_postprocessing | no | no |
| BLD_RECVD_DT | sp_hepatitis_datamart_postprocessing | no | no |
| BLD_RECVD_IND | sp_hepatitis_datamart_postprocessing | no | no |
| BLD_TRANSF_PRIOR_1992 | sp_hepatitis_datamart_postprocessing | no | no |
| CASE_RPT_MMWR_WEEK | sp_hepatitis_datamart_postprocessing | no | no |
| CASE_RPT_MMWR_YEAR | sp_hepatitis_datamart_postprocessing | no | no |
| CASE_UID | sp_hepatitis_datamart_postprocessing | no | no |
| CHILDCARE_CASE_IND | sp_hepatitis_datamart_postprocessing | no | no |
| CLOTFACTOR_PRIOR_1987 | sp_hepatitis_datamart_postprocessing | no | no |
| CNTRY_USUAL_RESIDENCE | sp_hepatitis_datamart_postprocessing | no | no |
| COM_SRC_OUTBREAK_IND | sp_hepatitis_datamart_postprocessing | no | no |
| CONDITION_CD | sp_hepatitis_datamart_postprocessing | no | no |
| CONTACT_TYPE_OTH | sp_hepatitis_datamart_postprocessing | no | no |
| CT_BABYSITTER_IND | sp_hepatitis_datamart_postprocessing | no | no |
| CT_CHILDCARE_IND | sp_hepatitis_datamart_postprocessing | no | no |
| CT_HOUSEHOLD_IND | sp_hepatitis_datamart_postprocessing | no | no |
| CT_PLAYMATE_IND | sp_hepatitis_datamart_postprocessing | no | no |
| DEN_WORK_OR_SURG_IND | sp_hepatitis_datamart_postprocessing | no | no |
| DIABETES_DX_DT | sp_hepatitis_datamart_postprocessing | no | no |
| DIABETES_IND | sp_hepatitis_datamart_postprocessing | no | no |
| DIAGNOSIS_DT | sp_hepatitis_datamart_postprocessing | no | no |
| DIE_FRM_THIS_ILLNESS_IND | sp_hepatitis_datamart_postprocessing | no | no |
| DISEASE_IMPORTED_IND | sp_hepatitis_datamart_postprocessing | no | no |
| DNP_EMPLOYEE_IND | sp_hepatitis_datamart_postprocessing | no | no |
| DNP_HOUSEHOLD_CT_IND | sp_hepatitis_datamart_postprocessing | no | no |
| EARLIEST_RPT_TO_CNTY | sp_hepatitis_datamart_postprocessing | no | no |
| EARLIEST_RPT_TO_STATE_DT | sp_hepatitis_datamart_postprocessing | no | no |
| EVENT_DATE | sp_hepatitis_datamart_postprocessing | no | no |
| EVENT_DATE_TYPE | sp_hepatitis_datamart_postprocessing | no | no |
| EVER_INCAR_IND | sp_hepatitis_datamart_postprocessing | no | no |
| EVER_INJCT_NOPRSC_DRG | sp_hepatitis_datamart_postprocessing | no | no |
| FEMALE_SEX_PRTNR_NBR | sp_hepatitis_datamart_postprocessing | no | no |
| FOOD_OBRK_FOOD_ITEM | sp_hepatitis_datamart_postprocessing | no | no |
| FOODHNDLR_PRIOR_IND | sp_hepatitis_datamart_postprocessing | no | no |
| GLOB_LAST_RECVD_YR | sp_hepatitis_datamart_postprocessing | no | no |
| HBE_AG_DT | sp_hepatitis_datamart_postprocessing | no | no |
| HBS_AG_DT | sp_hepatitis_datamart_postprocessing | no | no |
| HBV_NAT_DT | sp_hepatitis_datamart_postprocessing | no | no |
| HCV_RNA | sp_hepatitis_datamart_postprocessing | no | no |
| HCV_RNA_DT | sp_hepatitis_datamart_postprocessing | no | no |
| HEMODIALYSIS_IND | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_A_EPLINK_IND | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_A_IGM_ANTIBODY | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_A_TOTAL_ANTIBODY | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_B_DNA | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_B_IGM_ANTIBODY | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_B_SURFACE_ANTIGEN | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_B_TOTAL_ANTIBODY | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_C_TOTAL_ANTIBODY | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_CARE_PROVIDER | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_CONTACT_EVER_IND | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_CONTACT_IND | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_D_INFECTION_IND | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_D_TEST_IND | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_D_TOTAL_ANTIBODY | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_E_ANTIGEN | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_E_TOTAL_ANTIBODY | sp_hepatitis_datamart_postprocessing | no | no |
| HEP_MEDS_RECVD_IND | sp_hepatitis_datamart_postprocessing | no | no |
| HOUSEHOLD_TRAVEL_IND | sp_hepatitis_datamart_postprocessing | no | no |
| HOUSEHOLD_TRAVEL_LOC | sp_hepatitis_datamart_postprocessing | no | no |
| HSPTL_ADMISSION_DT | sp_hepatitis_datamart_postprocessing | no | no |
| HSPTL_DISCHARGE_DT | sp_hepatitis_datamart_postprocessing | no | no |
| HSPTL_DURATION_DAYS | sp_hepatitis_datamart_postprocessing | no | no |
| HSPTL_PRIOR_ONSET_IND | sp_hepatitis_datamart_postprocessing | no | no |
| HSPTLIZD_IND | sp_hepatitis_datamart_postprocessing | no | no |
| IGM_ANTI_HAV_DT | sp_hepatitis_datamart_postprocessing | no | no |
| IGM_ANTI_HBC_DT | sp_hepatitis_datamart_postprocessing | no | no |
| ILLNESS_ONSET_DT | sp_hepatitis_datamart_postprocessing | no | no |
| IMM_GLOB_RECVD_IND | sp_hepatitis_datamart_postprocessing | no | no |
| IMPORT_FROM_CITY | sp_hepatitis_datamart_postprocessing | no | no |
| IMPORT_FROM_COUNTRY | sp_hepatitis_datamart_postprocessing | no | no |
| IMPORT_FROM_COUNTY | sp_hepatitis_datamart_postprocessing | no | no |
| IMPORT_FROM_STATE | sp_hepatitis_datamart_postprocessing | no | no |
| INCAR_24PLUSHRS_IND | sp_hepatitis_datamart_postprocessing | no | no |
| INCAR_6PLUS_MO_IND | sp_hepatitis_datamart_postprocessing | no | no |
| INCAR_TYPE_JAIL_IND | sp_hepatitis_datamart_postprocessing | no | no |
| INCAR_TYPE_JUV_IND | sp_hepatitis_datamart_postprocessing | no | no |
| INCAR_TYPE_PRISON_IND | sp_hepatitis_datamart_postprocessing | no | no |
| INIT_NND_NOT_DT | sp_hepatitis_datamart_postprocessing, sp_nrt_notification_postprocessing | no | no |
| INNC_NOTIFICATION_DT | sp_hepatitis_datamart_postprocessing | no | no |
| INV_CASE_STATUS | sp_hepatitis_datamart_postprocessing | no | no |
| INV_COMMENTS | sp_hepatitis_datamart_postprocessing | no | no |
| INV_LOCAL_ID | sp_hepatitis_datamart_postprocessing | no | no |
| INV_RPT_DT | sp_hepatitis_datamart_postprocessing | no | no |
| INV_START_DT | sp_hepatitis_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_hepatitis_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS | sp_hepatitis_datamart_postprocessing | no | no |
| INVESTIGATOR_NAME | sp_hepatitis_datamart_postprocessing | no | no |
| INVESTIGATOR_UID | sp_hepatitis_datamart_postprocessing | no | no |
| JURISDICTION_NM | sp_hepatitis_datamart_postprocessing | no | no |
| LAST6PLUSMO_INCAR_PER | sp_hepatitis_datamart_postprocessing | no | no |
| LAST6PLUSMO_INCAR_YR | sp_hepatitis_datamart_postprocessing | no | no |
| LEGACY_CASE_ID | sp_hepatitis_datamart_postprocessing | no | no |
| LIFE_SEX_PRTNR_NBR | sp_hepatitis_datamart_postprocessing | no | no |
| LT_HEMODIALYSIS_IND | sp_hepatitis_datamart_postprocessing | no | no |
| LTCARE_RESIDENT_IND | sp_hepatitis_datamart_postprocessing | no | no |
| MALE_SEX_PRTNR_NBR | sp_hepatitis_datamart_postprocessing | no | no |
| MED_DEN_BLD_CT_FRQ | sp_hepatitis_datamart_postprocessing | no | no |
| MED_DEN_EMP_EVER_IND | sp_hepatitis_datamart_postprocessing | no | no |
| MED_DEN_EMPLOYEE_IND | sp_hepatitis_datamart_postprocessing | no | no |
| MTH_BIRTH_COUNTRY | sp_hepatitis_datamart_postprocessing | no | no |
| MTH_BORN_OUTSIDE_US | sp_hepatitis_datamart_postprocessing | no | no |
| MTH_ETHNICITY | sp_hepatitis_datamart_postprocessing | no | no |
| MTH_HBS_AG_PRIOR_POS | sp_hepatitis_datamart_postprocessing | no | no |
| MTH_POS_AFTER | sp_hepatitis_datamart_postprocessing | no | no |
| MTH_POS_TEST_DT | sp_hepatitis_datamart_postprocessing | no | no |
| MTH_RACE | sp_hepatitis_datamart_postprocessing | no | no |
| NON_ORAL_SURGERY_IND | sp_hepatitis_datamart_postprocessing | no | no |
| NOT_SUBMIT_DT | sp_hepatitis_datamart_postprocessing | no | no |
| OBRK_FOODHNDLR_IND | sp_hepatitis_datamart_postprocessing | no | no |
| OBRK_NOFOODHNDLR_IND | sp_hepatitis_datamart_postprocessing | no | no |
| OBRK_UNIDENTIFIED_IND | sp_hepatitis_datamart_postprocessing | no | no |
| OBRK_WATERBORNE_IND | sp_hepatitis_datamart_postprocessing | no | no |
| ORGN_TRNSP_PRIOR_1992 | sp_hepatitis_datamart_postprocessing | no | no |
| OTHER_CONTACT_IND | sp_hepatitis_datamart_postprocessing | no | no |
| OUTBREAK_IND | sp_hepatitis_datamart_postprocessing | no | no |
| OUTPAT_IV_INF_IND | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_BIRTH_COUNTRY | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_CITY | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_COUNTRY | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_COUNTY | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_CURR_GENDER | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_DOB | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_ELECTRONIC_IND | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_ETHNICITY | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_FIRST_NM | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_JUNDICED_IND | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_LAST_NM | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_LOCAL_ID | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_MIDDLE_NM | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_PREGNANT_IND | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_PREV_AWARE_IND | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_RACE | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_REPORTED_AGE | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_REPORTED_AGE_UNIT | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_STATE | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_STREET_ADDR_1 | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_STREET_ADDR_2 | sp_hepatitis_datamart_postprocessing | no | no |
| PAT_ZIP_CODE | sp_hepatitis_datamart_postprocessing | no | no |
| PATIENT_UID | sp_hepatitis_datamart_postprocessing | no | no |
| PHYS_CITY | sp_hepatitis_datamart_postprocessing | no | no |
| PHYS_COUNTY | sp_hepatitis_datamart_postprocessing | no | no |
| PHYS_NAME | sp_hepatitis_datamart_postprocessing | no | no |
| PHYS_STATE | sp_hepatitis_datamart_postprocessing | no | no |
| PHYSICIAN_UID | sp_hepatitis_datamart_postprocessing | no | no |
| PIERC_PERF_LOC | sp_hepatitis_datamart_postprocessing | no | no |
| PIERC_PERF_LOC_OTH | sp_hepatitis_datamart_postprocessing | no | no |
| PIERC_PRIOR_ONSET_IND | sp_hepatitis_datamart_postprocessing | no | no |
| PREGNANCY_DUE_DT | sp_hepatitis_datamart_postprocessing | no | no |
| PREV_NEG_HEP_TEST_IND | sp_hepatitis_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_hepatitis_datamart_postprocessing | no | no |
| PUB_SAFETY_BLD_CT_FRQ | sp_hepatitis_datamart_postprocessing | no | no |
| PUB_SAFETY_WORKER_IND | sp_hepatitis_datamart_postprocessing | no | no |
| REFRESH_DATETIME | sp_hepatitis_datamart_postprocessing | no | no |
| REPORTING_SOURCE_UID | sp_hepatitis_datamart_postprocessing | no | no |
| RPT_SRC_CD_DESC | sp_hepatitis_datamart_postprocessing | no | no |
| RPT_SRC_CITY | sp_hepatitis_datamart_postprocessing | no | no |
| RPT_SRC_COUNTY | sp_hepatitis_datamart_postprocessing | no | no |
| RPT_SRC_COUNTY_CD | sp_hepatitis_datamart_postprocessing | no | no |
| RPT_SRC_SOURCE_NM | sp_hepatitis_datamart_postprocessing | no | no |
| RPT_SRC_STATE | sp_hepatitis_datamart_postprocessing | no | no |
| SEX_PREF | sp_hepatitis_datamart_postprocessing | no | no |
| SEXUAL_PARTNER_IND | sp_hepatitis_datamart_postprocessing | no | no |
| STD_LAST_TREATMENT_YR | sp_hepatitis_datamart_postprocessing | no | no |
| STD_TREATED_IND | sp_hepatitis_datamart_postprocessing | no | no |
| STREET_DRUG_INJECTED | sp_hepatitis_datamart_postprocessing | no | no |
| STREET_DRUG_USED | sp_hepatitis_datamart_postprocessing | no | no |
| SUPP_ANTI_HCV_DT | sp_hepatitis_datamart_postprocessing | no | no |
| SYMPTOMATIC_IND | sp_hepatitis_datamart_postprocessing | no | no |
| TATT_PRIOR_LOC_OTH | sp_hepatitis_datamart_postprocessing | no | no |
| TATT_PRIOR_ONSET_IND | sp_hepatitis_datamart_postprocessing | no | no |
| TATTOO_PERF_LOC | sp_hepatitis_datamart_postprocessing | no | no |
| TEST_REASON | sp_hepatitis_datamart_postprocessing | no | no |
| TEST_REASON_OTH | sp_hepatitis_datamart_postprocessing | no | no |
| TOTAL_ANTI_HAV_DT | sp_hepatitis_datamart_postprocessing | no | no |
| TOTAL_ANTI_HBC_DT | sp_hepatitis_datamart_postprocessing | no | no |
| TOTAL_ANTI_HCV_DT | sp_hepatitis_datamart_postprocessing | no | no |
| TOTAL_ANTI_HDV_DT | sp_hepatitis_datamart_postprocessing | no | no |
| TOTAL_ANTI_HEV_DT | sp_hepatitis_datamart_postprocessing | no | no |
| TRANSMISSION_MODE | sp_hepatitis_datamart_postprocessing | no | no |
| TRAVEL_OUT_USACAN_IND | sp_hepatitis_datamart_postprocessing | no | no |
| TRAVEL_OUT_USACAN_LOC | sp_hepatitis_datamart_postprocessing | no | no |
| TRAVEL_REASON | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_DOSE_NBR_1 | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_DOSE_NBR_2 | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_DOSE_NBR_3 | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_DOSE_NBR_4 | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_DOSE_RECVD_NBR | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_GT_4_IND | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_LAST_RECVD_YR | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_RECVD_DT_1 | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_RECVD_DT_2 | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_RECVD_DT_3 | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_RECVD_DT_4 | sp_hepatitis_datamart_postprocessing | no | no |
| VACC_RECVD_IND | sp_hepatitis_datamart_postprocessing | no | no |
| VERIFIED_TEST_DT | sp_hepatitis_datamart_postprocessing | no | no |

### dbo.INV_HIV

Writers:
- `sp_std_hiv_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_INV_HIV_KEY | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_900_RESULT | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_900_TEST_IND | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_900_TEST_REFERRAL_DT | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_AV_THERAPY_EVER_IND | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_AV_THERAPY_LAST_12MO_IND | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_ENROLL_PRTNR_SRVCS_IND | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_KEEP_900_CARE_APPT_IND | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_LAST_900_TEST_DT | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_POST_TEST_900_COUNSELING | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_PREVIOUS_900_TEST_IND | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_REFER_FOR_900_CARE_IND | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_REFER_FOR_900_TEST | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_RST_PROVIDED_900_RSLT_IND | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_SELF_REPORTED_RSLT_900 | sp_std_hiv_datamart_postprocessing | no | no |
| HIV_STATE_CASE_ID | sp_std_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_std_hiv_datamart_postprocessing | no | no |

### dbo.INV_SUMM_DATAMART

Writers:
- `sp_inv_summary_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| AGE_REPORTED | sp_inv_summary_datamart_postprocessing | no | no |
| AGE_REPORTED_UNIT | sp_inv_summary_datamart_postprocessing | no | no |
| CASE_STATUS | sp_inv_summary_datamart_postprocessing | no | no |
| CONFIRMATION_DT | sp_inv_summary_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD | sp_inv_summary_datamart_postprocessing | no | no |
| CURR_PROCESS_STATE | sp_inv_summary_datamart_postprocessing | no | no |
| DIAGNOSIS_DATE | sp_inv_summary_datamart_postprocessing | no | no |
| DISEASE | sp_inv_summary_datamart_postprocessing | no | no |
| DISEASE_CD | sp_inv_summary_datamart_postprocessing | no | no |
| EARLIEST_RPT_TO_CNTY_DT | sp_inv_summary_datamart_postprocessing | no | no |
| EARLIEST_RPT_TO_STATE_DT | sp_inv_summary_datamart_postprocessing | no | no |
| Earliest_specimen_collect_date | sp_inv_summary_datamart_postprocessing | no | no |
| EVENT_DATE | sp_inv_summary_datamart_postprocessing | no | no |
| EVENT_DATE_TYPE | sp_inv_summary_datamart_postprocessing | no | no |
| FIRST_POSITIVE_CULTURE_DT | sp_inv_summary_datamart_postprocessing | no | no |
| HSPTL_ADMISSION_DT | sp_inv_summary_datamart_postprocessing | no | no |
| ILLNESS_ONSET_DATE | sp_inv_summary_datamart_postprocessing | no | no |
| INIT_NND_NOT_DT | sp_inv_summary_datamart_postprocessing | no | no |
| INV_RPT_DT | sp_inv_summary_datamart_postprocessing | no | no |
| INV_START_DT | sp_inv_summary_datamart_postprocessing | no | no |
| INVESTIGATION_CREATE_DATE | sp_inv_summary_datamart_postprocessing | no | no |
| INVESTIGATION_CREATED_BY | sp_inv_summary_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_inv_summary_datamart_postprocessing | no | no |
| INVESTIGATION_LAST_UPDTD_BY | sp_inv_summary_datamart_postprocessing | no | no |
| INVESTIGATION_LAST_UPDTD_DATE | sp_inv_summary_datamart_postprocessing | no | no |
| INVESTIGATION_LOCAL_ID | sp_inv_summary_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS | sp_inv_summary_datamart_postprocessing | no | no |
| JURISDICTION_NM | sp_inv_summary_datamart_postprocessing | no | no |
| LABORATORY_INFORMATION | sp_inv_summary_datamart_postprocessing | no | no |
| MMWR_WEEK | sp_inv_summary_datamart_postprocessing | no | no |
| MMWR_YEAR | sp_inv_summary_datamart_postprocessing | no | no |
| NOTIFICATION_CREATE_DATE | sp_inv_summary_datamart_postprocessing | no | no |
| NOTIFICATION_LAST_UPDATED_DATE | sp_inv_summary_datamart_postprocessing | no | no |
| NOTIFICATION_LAST_UPDATED_USER | sp_inv_summary_datamart_postprocessing | no | no |
| NOTIFICATION_LOCAL_ID | sp_inv_summary_datamart_postprocessing | no | no |
| NOTIFICATION_SENT_DATE | sp_inv_summary_datamart_postprocessing | no | no |
| NOTIFICATION_STATUS | sp_inv_summary_datamart_postprocessing | no | no |
| NOTIFICATION_SUBMITTER | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_CITY | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_COUNTY | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_COUNTY_CODE | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_CURRENT_SEX | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_DOB | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_ETHNICITY | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_FIRST_NAME | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_KEY | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_LAST_NAME | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_LOCAL_ID | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_STATE | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_STREET_ADDRESS_1 | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_STREET_ADDRESS_2 | sp_inv_summary_datamart_postprocessing | no | no |
| PATIENT_ZIP | sp_inv_summary_datamart_postprocessing | no | no |
| PHYSICIAN_FIRST_NAME | sp_inv_summary_datamart_postprocessing | no | no |
| PHYSICIAN_LAST_NAME | sp_inv_summary_datamart_postprocessing | no | no |
| PROGRAM_AREA | sp_inv_summary_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_inv_summary_datamart_postprocessing | no | no |
| RACE_CALC_DETAILS | sp_inv_summary_datamart_postprocessing | no | no |
| RACE_CALCULATED | sp_inv_summary_datamart_postprocessing | no | no |

### dbo.INVESTIGATION

Writers:
- `sp_nrt_investigation_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_TIME | sp_nrt_investigation_postprocessing | yes | no |
| CASE_OID | sp_nrt_investigation_postprocessing | yes | no |
| CASE_RPT_MMWR_WK | sp_nrt_investigation_postprocessing | yes | no |
| CASE_RPT_MMWR_YR | sp_nrt_investigation_postprocessing | yes | no |
| CASE_TYPE | sp_nrt_investigation_postprocessing | yes | no |
| CASE_UID | sp_nrt_investigation_postprocessing | yes | no |
| CITY_COUNTY_CASE_NBR | sp_nrt_investigation_postprocessing | yes | no |
| COINFECTION_ID | sp_nrt_investigation_postprocessing | yes | no |
| CONTACT_INFECTIOUS_FROM_DATE | sp_nrt_investigation_postprocessing | yes | no |
| CONTACT_INFECTIOUS_TO_DATE | sp_nrt_investigation_postprocessing | yes | no |
| CONTACT_INV_COMMENTS | sp_nrt_investigation_postprocessing | yes | no |
| CONTACT_INV_PRIORITY | sp_nrt_investigation_postprocessing | yes | no |
| CONTACT_INV_STATUS | sp_nrt_investigation_postprocessing | yes | no |
| CURR_PROCESS_STATE | sp_nrt_investigation_postprocessing | yes | no |
| DAYCARE_ASSOCIATION_IND | sp_nrt_investigation_postprocessing | yes | no |
| DETECTION_METHOD_DESC_TXT | sp_nrt_investigation_postprocessing | yes | no |
| DIAGNOSIS_DT | sp_nrt_investigation_postprocessing | yes | no |
| DIE_FRM_THIS_ILLNESS_IND | sp_nrt_investigation_postprocessing | yes | no |
| DISEASE_IMPORTED_IND | sp_nrt_investigation_postprocessing | yes | no |
| EARLIEST_RPT_TO_CDC_DT | sp_nrt_investigation_postprocessing | yes | no |
| EARLIEST_RPT_TO_CNTY_DT | sp_nrt_investigation_postprocessing | yes | no |
| EARLIEST_RPT_TO_PHD_DT | sp_nrt_investigation_postprocessing | yes | no |
| EARLIEST_RPT_TO_STATE_DT | sp_nrt_investigation_postprocessing | yes | no |
| FOOD_HANDLR_IND | sp_nrt_investigation_postprocessing | yes | no |
| HSPTL_ADMISSION_DT | sp_nrt_investigation_postprocessing | yes | no |
| HSPTL_DISCHARGE_DT | sp_nrt_investigation_postprocessing | yes | no |
| HSPTL_DURATION_DAYS | sp_nrt_investigation_postprocessing | yes | no |
| HSPTLIZD_IND | sp_nrt_investigation_postprocessing | yes | no |
| ILLNESS_DURATION | sp_nrt_investigation_postprocessing | yes | no |
| ILLNESS_DURATION_UNIT | sp_nrt_investigation_postprocessing | yes | no |
| ILLNESS_END_DT | sp_nrt_investigation_postprocessing | yes | no |
| ILLNESS_ONSET_DT | sp_nrt_investigation_postprocessing | yes | no |
| IMPORT_FRM_CITY | sp_nrt_investigation_postprocessing | yes | no |
| IMPORT_FRM_CITY_CD | sp_nrt_investigation_postprocessing | yes | no |
| IMPORT_FRM_CNTRY | sp_nrt_investigation_postprocessing | yes | no |
| IMPORT_FRM_CNTRY_CD | sp_nrt_investigation_postprocessing | yes | no |
| IMPORT_FRM_CNTY | sp_nrt_investigation_postprocessing | yes | no |
| IMPORT_FRM_CNTY_CD | sp_nrt_investigation_postprocessing | yes | no |
| IMPORT_FRM_STATE | sp_nrt_investigation_postprocessing | yes | no |
| IMPORT_FRM_STATE_CD | sp_nrt_investigation_postprocessing | yes | no |
| INV_ASSIGNED_DT | sp_nrt_investigation_postprocessing | yes | no |
| INV_CASE_STATUS | sp_nrt_investigation_postprocessing | yes | no |
| INV_CLOSE_DT | sp_nrt_investigation_postprocessing | yes | no |
| INV_COMMENTS | sp_nrt_investigation_postprocessing | yes | no |
| INV_LOCAL_ID | sp_nrt_investigation_postprocessing | yes | no |
| INV_PRIORITY_CD | sp_nrt_investigation_postprocessing | yes | no |
| INV_RPT_DT | sp_nrt_investigation_postprocessing | yes | no |
| INV_SHARE_IND | sp_nrt_investigation_postprocessing | yes | no |
| INV_START_DT | sp_nrt_investigation_postprocessing | yes | no |
| INV_STATE_CASE_ID | sp_nrt_investigation_postprocessing | yes | no |
| INVESTIGATION_ADDED_BY | sp_nrt_investigation_postprocessing | yes | no |
| INVESTIGATION_DEATH_DATE | sp_nrt_investigation_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_nrt_investigation_postprocessing | yes | no |
| INVESTIGATION_LAST_UPDATED_BY | sp_nrt_investigation_postprocessing | yes | no |
| INVESTIGATION_STATUS | sp_nrt_investigation_postprocessing | yes | no |
| JURISDICTION_CD | sp_nrt_investigation_postprocessing | yes | no |
| JURISDICTION_NM | sp_nrt_investigation_postprocessing | yes | no |
| LAST_CHG_TIME | sp_nrt_investigation_postprocessing | yes | no |
| LEGACY_CASE_ID | sp_nrt_investigation_postprocessing | yes | no |
| OUTBREAK_IND | sp_nrt_investigation_postprocessing | yes | no |
| OUTBREAK_NAME | sp_nrt_investigation_postprocessing | yes | no |
| OUTBREAK_NAME_DESC | sp_nrt_investigation_postprocessing | yes | no |
| PATIENT_AGE_AT_ONSET | sp_nrt_investigation_postprocessing | yes | no |
| PATIENT_AGE_AT_ONSET_UNIT | sp_nrt_investigation_postprocessing | yes | no |
| PATIENT_PREGNANT_IND | sp_nrt_investigation_postprocessing | yes | no |
| PROGRAM_AREA_DESCRIPTION | sp_nrt_investigation_postprocessing | yes | no |
| RECORD_STATUS_CD | sp_nrt_investigation_postprocessing | yes | no |
| REFERRAL_BASIS | sp_nrt_investigation_postprocessing | yes | no |
| RPT_SRC_CD | sp_nrt_investigation_postprocessing | yes | no |
| RPT_SRC_CD_DESC | sp_nrt_investigation_postprocessing | yes | no |
| TRANSMISSION_MODE | sp_nrt_investigation_postprocessing | yes | no |

### dbo.job_batch_rebuild_log

Writers:
- `sp_sld_investigation_repeat_postprocessing` (postprocessing) — ops: UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| batch_end_dttm | sp_sld_investigation_repeat_postprocessing | no | no |
| status_type | sp_sld_investigation_repeat_postprocessing | no | no |

### dbo.job_flow_log

Writers:
- `sp_aggregate_report_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_alter_datamart_schema_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_auth_user_event` (event) — ops: INSERT [guarded]
- `sp_batch_id_cleanup_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_bmird_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_bmird_strep_pneumo_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_case_lab_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_contact_record_event` (event) — ops: INSERT [guarded]
- `sp_covid_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_covid_contact_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_covid_lab_celr_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_covid_lab_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_covid_vaccination_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_crs_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_d_contact_record_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_d_interview_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_d_lab_test_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_d_labtest_result_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_d_morbidity_report_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_d_pagebuilder_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_d_vaccination_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_case_management_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_createdm_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_dimension_update` (dyn_dm_utility) — ops: INSERT
- `sp_dyn_dm_invest_clear_postprocessing` (dyn_dm_postprocessing) — ops: INSERT
- `sp_dyn_dm_invest_form_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_main_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_org_data_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_page_builder_d_inv_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_provider_data_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_repeatdate_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_repeatnumeric_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_dyn_dm_repeatvarch_postprocessing` (dyn_dm_postprocessing) — ops: INSERT [guarded]
- `sp_event_metric_cleanup_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_event_metric_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_execute_ldf_generic` (utility) — ops: INSERT [guarded]
- `sp_f_contact_record_case_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_f_interview_case_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_f_page_case_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_f_std_page_case_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_f_tb_pam_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_f_vaccination_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_f_var_pam_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_generic_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_hep100_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_hepatitis_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_hepatitis_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_interview_event` (event) — ops: INSERT [guarded]
- `sp_inv_summary_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_investigation_event` (event) — ops: INSERT
- `sp_l_pagebuilder_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_lab100_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_lab101_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_ldf_bmird_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_ldf_data_event` (event) — ops: INSERT
- `sp_ldf_foodborne_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_ldf_generic_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT
- `sp_ldf_hepatitis_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_ldf_intervention_event` (event) — ops: INSERT
- `sp_ldf_mumps_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_ldf_observation_event` (event) — ops: INSERT
- `sp_ldf_organization_event` (event) — ops: INSERT
- `sp_ldf_patient_event` (event) — ops: INSERT
- `sp_ldf_phc_event` (event) — ops: INSERT
- `sp_ldf_provider_event` (event) — ops: INSERT
- `sp_ldf_tetanus_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_ldf_vaccine_prevent_diseases_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_measles_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_merge_tables` (utility) — ops: INSERT [guarded]
- `sp_morbidity_report_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_notification_event` (event) — ops: INSERT [guarded]
- `sp_nrt_backfill_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_case_count_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_case_management_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_addl_risk_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_disease_site_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_gt_12_reas_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_hc_prov_ty_3_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_move_cntry_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_move_cnty_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_move_state_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_moved_where_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_out_of_cntry_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_pcr_source_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_rash_loc_gen_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_smr_exam_ty_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_tb_hiv_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_tb_pam_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_d_var_pam_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_investigation_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_ldf_dimensional_data_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_notification_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_odse_nbs_page_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_organization_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_patient_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_place_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_provider_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_srte_condition_code_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_tb_pam_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_treatment_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_nrt_var_pam_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]
- `sp_observation_event` (event) — ops: INSERT
- `sp_organization_event` (event) — ops: INSERT [guarded]
- `sp_page_builder_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_patient_dim_columns_update_to_datamart` (datamart) — ops: INSERT [guarded]
- `sp_patient_event` (event) — ops: INSERT [guarded]
- `sp_patient_race_event` (event) — ops: INSERT
- `sp_pertussis_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_place_event` (event) — ops: INSERT [guarded]
- `sp_provider_dim_columns_update_to_datamart` (datamart) — ops: INSERT [guarded]
- `sp_provider_event` (event) — ops: INSERT [guarded]
- `sp_public_health_case_fact_datamart_event` (event) — ops: INSERT [guarded]
- `sp_public_health_case_fact_datamart_update` (datamart) — ops: INSERT [guarded]
- `sp_repeated_place_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_rubella_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_s_pagebuilder_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_sld_investigation_repeat_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_sr100_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_std_hiv_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_summary_report_case_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_tb_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_tb_hiv_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]
- `sp_treatment_event` (event) — ops: INSERT [guarded]
- `sp_user_profile_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_user_report_permissions` (utility) — ops: INSERT
- `sp_vaccination_event` (event) — ops: INSERT [guarded]
- `sp_var_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| batch_id | sp_aggregate_report_datamart_postprocessing, sp_alter_datamart_schema_postprocessing, sp_auth_user_event, sp_batch_id_cleanup_postprocessing, sp_bmird_case_datamart_postprocessing, sp_bmird_strep_pneumo_datamart_postprocessing, sp_case_lab_datamart_postprocessing, sp_contact_record_event, sp_covid_case_datamart_postprocessing, sp_covid_contact_datamart_postprocessing, sp_covid_lab_celr_datamart_postprocessing, sp_covid_lab_datamart_postprocessing, sp_covid_vaccination_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_d_contact_record_postprocessing, sp_d_interview_postprocessing, sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing, sp_d_pagebuilder_postprocessing, sp_d_vaccination_postprocessing, sp_dyn_dm_case_management_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_dimension_update, sp_dyn_dm_invest_clear_postprocessing, sp_dyn_dm_invest_form_postprocessing, sp_dyn_dm_main_postprocessing, sp_dyn_dm_org_data_postprocessing, sp_dyn_dm_page_builder_d_inv_postprocessing, sp_dyn_dm_provider_data_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing, sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing, sp_execute_ldf_generic, sp_f_contact_record_case_postprocessing, sp_f_interview_case_postprocessing, sp_f_page_case_postprocessing, sp_f_std_page_case_postprocessing, sp_f_tb_pam_postprocessing, sp_f_vaccination_postprocessing, sp_f_var_pam_postprocessing, sp_generic_case_datamart_postprocessing, sp_hep100_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_hepatitis_datamart_postprocessing, sp_interview_event, sp_inv_summary_datamart_postprocessing, sp_investigation_event, sp_l_pagebuilder_postprocessing, sp_lab100_datamart_postprocessing, sp_lab101_datamart_postprocessing, sp_ldf_bmird_datamart_postprocessing, sp_ldf_data_event, sp_ldf_foodborne_datamart_postprocessing, sp_ldf_generic_datamart_postprocessing, sp_ldf_hepatitis_datamart_postprocessing, sp_ldf_intervention_event, sp_ldf_mumps_datamart_postprocessing, sp_ldf_observation_event, sp_ldf_organization_event, sp_ldf_patient_event, sp_ldf_phc_event, sp_ldf_provider_event, sp_ldf_tetanus_datamart_postprocessing, sp_ldf_vaccine_prevent_diseases_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_merge_tables, sp_morbidity_report_datamart_postprocessing, sp_notification_event, sp_nrt_backfill_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_d_addl_risk_postprocessing, sp_nrt_d_disease_site_postprocessing, sp_nrt_d_gt_12_reas_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing, sp_nrt_d_move_cntry_postprocessing, sp_nrt_d_move_cnty_postprocessing, sp_nrt_d_move_state_postprocessing, sp_nrt_d_moved_where_postprocessing, sp_nrt_d_out_of_cntry_postprocessing, sp_nrt_d_pcr_source_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing, sp_nrt_d_tb_hiv_postprocessing, sp_nrt_d_tb_pam_postprocessing, sp_nrt_d_var_pam_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_dimensional_data_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_odse_nbs_page_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_nrt_srte_condition_code_postprocessing, sp_nrt_tb_pam_ldf_postprocessing, sp_nrt_treatment_postprocessing, sp_nrt_var_pam_ldf_postprocessing, sp_observation_event, sp_organization_event, sp_page_builder_postprocessing, sp_patient_dim_columns_update_to_datamart, sp_patient_event, sp_patient_race_event, sp_pertussis_case_datamart_postprocessing, sp_place_event, sp_provider_dim_columns_update_to_datamart, sp_provider_event, sp_public_health_case_fact_datamart_event, sp_public_health_case_fact_datamart_update, sp_repeated_place_postprocessing, sp_rubella_case_datamart_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing, sp_sr100_datamart_postprocessing, sp_std_hiv_datamart_postprocessing, sp_summary_report_case_postprocessing, sp_tb_datamart_postprocessing, sp_tb_hiv_datamart_postprocessing, sp_treatment_event, sp_user_profile_postprocessing, sp_user_report_permissions, sp_vaccination_event, sp_var_datamart_postprocessing | yes | no |
| create_dttm | sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_f_std_page_case_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_repeated_place_postprocessing | yes | no |
| Dataflow_Name | sp_aggregate_report_datamart_postprocessing, sp_alter_datamart_schema_postprocessing, sp_auth_user_event, sp_batch_id_cleanup_postprocessing, sp_bmird_case_datamart_postprocessing, sp_bmird_strep_pneumo_datamart_postprocessing, sp_case_lab_datamart_postprocessing, sp_contact_record_event, sp_covid_case_datamart_postprocessing, sp_covid_contact_datamart_postprocessing, sp_covid_lab_celr_datamart_postprocessing, sp_covid_lab_datamart_postprocessing, sp_covid_vaccination_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_d_contact_record_postprocessing, sp_d_interview_postprocessing, sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing, sp_d_pagebuilder_postprocessing, sp_d_vaccination_postprocessing, sp_dyn_dm_case_management_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_dimension_update, sp_dyn_dm_invest_clear_postprocessing, sp_dyn_dm_invest_form_postprocessing, sp_dyn_dm_main_postprocessing, sp_dyn_dm_org_data_postprocessing, sp_dyn_dm_page_builder_d_inv_postprocessing, sp_dyn_dm_provider_data_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing, sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing, sp_execute_ldf_generic, sp_f_contact_record_case_postprocessing, sp_f_interview_case_postprocessing, sp_f_page_case_postprocessing, sp_f_std_page_case_postprocessing, sp_f_tb_pam_postprocessing, sp_f_vaccination_postprocessing, sp_f_var_pam_postprocessing, sp_generic_case_datamart_postprocessing, sp_hep100_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_hepatitis_datamart_postprocessing, sp_interview_event, sp_inv_summary_datamart_postprocessing, sp_investigation_event, sp_l_pagebuilder_postprocessing, sp_lab100_datamart_postprocessing, sp_lab101_datamart_postprocessing, sp_ldf_bmird_datamart_postprocessing, sp_ldf_data_event, sp_ldf_foodborne_datamart_postprocessing, sp_ldf_generic_datamart_postprocessing, sp_ldf_hepatitis_datamart_postprocessing, sp_ldf_intervention_event, sp_ldf_mumps_datamart_postprocessing, sp_ldf_observation_event, sp_ldf_organization_event, sp_ldf_patient_event, sp_ldf_phc_event, sp_ldf_provider_event, sp_ldf_tetanus_datamart_postprocessing, sp_ldf_vaccine_prevent_diseases_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_merge_tables, sp_morbidity_report_datamart_postprocessing, sp_notification_event, sp_nrt_backfill_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_d_addl_risk_postprocessing, sp_nrt_d_disease_site_postprocessing, sp_nrt_d_gt_12_reas_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing, sp_nrt_d_move_cntry_postprocessing, sp_nrt_d_move_cnty_postprocessing, sp_nrt_d_move_state_postprocessing, sp_nrt_d_moved_where_postprocessing, sp_nrt_d_out_of_cntry_postprocessing, sp_nrt_d_pcr_source_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing, sp_nrt_d_tb_hiv_postprocessing, sp_nrt_d_tb_pam_postprocessing, sp_nrt_d_var_pam_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_dimensional_data_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_odse_nbs_page_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_nrt_srte_condition_code_postprocessing, sp_nrt_tb_pam_ldf_postprocessing, sp_nrt_treatment_postprocessing, sp_nrt_var_pam_ldf_postprocessing, sp_observation_event, sp_organization_event, sp_page_builder_postprocessing, sp_patient_dim_columns_update_to_datamart, sp_patient_event, sp_patient_race_event, sp_pertussis_case_datamart_postprocessing, sp_place_event, sp_provider_dim_columns_update_to_datamart, sp_provider_event, sp_public_health_case_fact_datamart_event, sp_public_health_case_fact_datamart_update, sp_repeated_place_postprocessing, sp_rubella_case_datamart_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing, sp_sr100_datamart_postprocessing, sp_std_hiv_datamart_postprocessing, sp_summary_report_case_postprocessing, sp_tb_datamart_postprocessing, sp_tb_hiv_datamart_postprocessing, sp_treatment_event, sp_user_profile_postprocessing, sp_user_report_permissions, sp_vaccination_event, sp_var_datamart_postprocessing | yes | no |
| Error_Description | sp_aggregate_report_datamart_postprocessing, sp_alter_datamart_schema_postprocessing, sp_auth_user_event, sp_batch_id_cleanup_postprocessing, sp_bmird_case_datamart_postprocessing, sp_bmird_strep_pneumo_datamart_postprocessing, sp_case_lab_datamart_postprocessing, sp_contact_record_event, sp_covid_case_datamart_postprocessing, sp_covid_contact_datamart_postprocessing, sp_covid_lab_celr_datamart_postprocessing, sp_covid_lab_datamart_postprocessing, sp_covid_vaccination_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_d_contact_record_postprocessing, sp_d_interview_postprocessing, sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing, sp_d_pagebuilder_postprocessing, sp_d_vaccination_postprocessing, sp_dyn_dm_case_management_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_dimension_update, sp_dyn_dm_invest_clear_postprocessing, sp_dyn_dm_invest_form_postprocessing, sp_dyn_dm_main_postprocessing, sp_dyn_dm_org_data_postprocessing, sp_dyn_dm_page_builder_d_inv_postprocessing, sp_dyn_dm_provider_data_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing, sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing, sp_execute_ldf_generic, sp_f_contact_record_case_postprocessing, sp_f_interview_case_postprocessing, sp_f_page_case_postprocessing, sp_f_std_page_case_postprocessing, sp_f_tb_pam_postprocessing, sp_f_vaccination_postprocessing, sp_f_var_pam_postprocessing, sp_generic_case_datamart_postprocessing, sp_hep100_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_hepatitis_datamart_postprocessing, sp_interview_event, sp_inv_summary_datamart_postprocessing, sp_investigation_event, sp_l_pagebuilder_postprocessing, sp_lab100_datamart_postprocessing, sp_lab101_datamart_postprocessing, sp_ldf_bmird_datamart_postprocessing, sp_ldf_data_event, sp_ldf_foodborne_datamart_postprocessing, sp_ldf_generic_datamart_postprocessing, sp_ldf_hepatitis_datamart_postprocessing, sp_ldf_intervention_event, sp_ldf_mumps_datamart_postprocessing, sp_ldf_observation_event, sp_ldf_organization_event, sp_ldf_patient_event, sp_ldf_phc_event, sp_ldf_provider_event, sp_ldf_tetanus_datamart_postprocessing, sp_ldf_vaccine_prevent_diseases_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_merge_tables, sp_morbidity_report_datamart_postprocessing, sp_notification_event, sp_nrt_backfill_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_d_addl_risk_postprocessing, sp_nrt_d_disease_site_postprocessing, sp_nrt_d_gt_12_reas_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing, sp_nrt_d_move_cntry_postprocessing, sp_nrt_d_move_cnty_postprocessing, sp_nrt_d_move_state_postprocessing, sp_nrt_d_moved_where_postprocessing, sp_nrt_d_out_of_cntry_postprocessing, sp_nrt_d_pcr_source_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing, sp_nrt_d_tb_hiv_postprocessing, sp_nrt_d_tb_pam_postprocessing, sp_nrt_d_var_pam_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_dimensional_data_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_odse_nbs_page_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_nrt_srte_condition_code_postprocessing, sp_nrt_tb_pam_ldf_postprocessing, sp_nrt_treatment_postprocessing, sp_nrt_var_pam_ldf_postprocessing, sp_observation_event, sp_organization_event, sp_page_builder_postprocessing, sp_patient_event, sp_patient_race_event, sp_pertussis_case_datamart_postprocessing, sp_place_event, sp_provider_event, sp_public_health_case_fact_datamart_event, sp_public_health_case_fact_datamart_update, sp_repeated_place_postprocessing, sp_rubella_case_datamart_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing, sp_sr100_datamart_postprocessing, sp_std_hiv_datamart_postprocessing, sp_summary_report_case_postprocessing, sp_tb_datamart_postprocessing, sp_tb_hiv_datamart_postprocessing, sp_treatment_event, sp_user_profile_postprocessing, sp_user_report_permissions, sp_vaccination_event, sp_var_datamart_postprocessing | yes | no |
| msg_description1 | sp_aggregate_report_datamart_postprocessing, sp_auth_user_event, sp_bmird_case_datamart_postprocessing, sp_bmird_strep_pneumo_datamart_postprocessing, sp_case_lab_datamart_postprocessing, sp_contact_record_event, sp_covid_case_datamart_postprocessing, sp_covid_contact_datamart_postprocessing, sp_covid_lab_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_d_contact_record_postprocessing, sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing, sp_d_pagebuilder_postprocessing, sp_d_vaccination_postprocessing, sp_dyn_dm_main_postprocessing, sp_dyn_dm_page_builder_d_inv_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_dyn_dm_repeatnumeric_postprocessing, sp_event_metric_datamart_postprocessing, sp_execute_ldf_generic, sp_f_interview_case_postprocessing, sp_f_page_case_postprocessing, sp_f_std_page_case_postprocessing, sp_f_tb_pam_postprocessing, sp_f_var_pam_postprocessing, sp_generic_case_datamart_postprocessing, sp_hep100_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_hepatitis_datamart_postprocessing, sp_interview_event, sp_inv_summary_datamart_postprocessing, sp_investigation_event, sp_ldf_bmird_datamart_postprocessing, sp_ldf_data_event, sp_ldf_foodborne_datamart_postprocessing, sp_ldf_generic_datamart_postprocessing, sp_ldf_hepatitis_datamart_postprocessing, sp_ldf_intervention_event, sp_ldf_mumps_datamart_postprocessing, sp_ldf_observation_event, sp_ldf_organization_event, sp_ldf_patient_event, sp_ldf_phc_event, sp_ldf_provider_event, sp_ldf_tetanus_datamart_postprocessing, sp_ldf_vaccine_prevent_diseases_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_merge_tables, sp_morbidity_report_datamart_postprocessing, sp_notification_event, sp_nrt_backfill_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_d_addl_risk_postprocessing, sp_nrt_d_disease_site_postprocessing, sp_nrt_d_gt_12_reas_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing, sp_nrt_d_move_cntry_postprocessing, sp_nrt_d_move_cnty_postprocessing, sp_nrt_d_move_state_postprocessing, sp_nrt_d_moved_where_postprocessing, sp_nrt_d_out_of_cntry_postprocessing, sp_nrt_d_pcr_source_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing, sp_nrt_d_tb_hiv_postprocessing, sp_nrt_d_tb_pam_postprocessing, sp_nrt_d_var_pam_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_dimensional_data_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_odse_nbs_page_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_nrt_srte_condition_code_postprocessing, sp_nrt_tb_pam_ldf_postprocessing, sp_nrt_treatment_postprocessing, sp_nrt_var_pam_ldf_postprocessing, sp_observation_event, sp_organization_event, sp_page_builder_postprocessing, sp_patient_dim_columns_update_to_datamart, sp_patient_event, sp_patient_race_event, sp_pertussis_case_datamart_postprocessing, sp_place_event, sp_provider_dim_columns_update_to_datamart, sp_provider_event, sp_public_health_case_fact_datamart_event, sp_public_health_case_fact_datamart_update, sp_repeated_place_postprocessing, sp_rubella_case_datamart_postprocessing, sp_sld_investigation_repeat_postprocessing, sp_sr100_datamart_postprocessing, sp_std_hiv_datamart_postprocessing, sp_summary_report_case_postprocessing, sp_tb_datamart_postprocessing, sp_tb_hiv_datamart_postprocessing, sp_treatment_event, sp_user_report_permissions, sp_vaccination_event, sp_var_datamart_postprocessing | yes | no |
| msg_description2 | sp_inv_summary_datamart_postprocessing | no | no |
| package_Name | sp_aggregate_report_datamart_postprocessing, sp_alter_datamart_schema_postprocessing, sp_auth_user_event, sp_batch_id_cleanup_postprocessing, sp_bmird_case_datamart_postprocessing, sp_bmird_strep_pneumo_datamart_postprocessing, sp_case_lab_datamart_postprocessing, sp_contact_record_event, sp_covid_case_datamart_postprocessing, sp_covid_contact_datamart_postprocessing, sp_covid_lab_celr_datamart_postprocessing, sp_covid_lab_datamart_postprocessing, sp_covid_vaccination_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_d_contact_record_postprocessing, sp_d_interview_postprocessing, sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing, sp_d_pagebuilder_postprocessing, sp_d_vaccination_postprocessing, sp_dyn_dm_case_management_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_dimension_update, sp_dyn_dm_invest_clear_postprocessing, sp_dyn_dm_invest_form_postprocessing, sp_dyn_dm_main_postprocessing, sp_dyn_dm_org_data_postprocessing, sp_dyn_dm_page_builder_d_inv_postprocessing, sp_dyn_dm_provider_data_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing, sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing, sp_execute_ldf_generic, sp_f_contact_record_case_postprocessing, sp_f_interview_case_postprocessing, sp_f_page_case_postprocessing, sp_f_std_page_case_postprocessing, sp_f_tb_pam_postprocessing, sp_f_vaccination_postprocessing, sp_f_var_pam_postprocessing, sp_generic_case_datamart_postprocessing, sp_hep100_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_hepatitis_datamart_postprocessing, sp_interview_event, sp_inv_summary_datamart_postprocessing, sp_investigation_event, sp_l_pagebuilder_postprocessing, sp_lab100_datamart_postprocessing, sp_lab101_datamart_postprocessing, sp_ldf_bmird_datamart_postprocessing, sp_ldf_data_event, sp_ldf_foodborne_datamart_postprocessing, sp_ldf_generic_datamart_postprocessing, sp_ldf_hepatitis_datamart_postprocessing, sp_ldf_intervention_event, sp_ldf_mumps_datamart_postprocessing, sp_ldf_observation_event, sp_ldf_organization_event, sp_ldf_patient_event, sp_ldf_phc_event, sp_ldf_provider_event, sp_ldf_tetanus_datamart_postprocessing, sp_ldf_vaccine_prevent_diseases_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_merge_tables, sp_morbidity_report_datamart_postprocessing, sp_notification_event, sp_nrt_backfill_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_d_addl_risk_postprocessing, sp_nrt_d_disease_site_postprocessing, sp_nrt_d_gt_12_reas_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing, sp_nrt_d_move_cntry_postprocessing, sp_nrt_d_move_cnty_postprocessing, sp_nrt_d_move_state_postprocessing, sp_nrt_d_moved_where_postprocessing, sp_nrt_d_out_of_cntry_postprocessing, sp_nrt_d_pcr_source_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing, sp_nrt_d_tb_hiv_postprocessing, sp_nrt_d_tb_pam_postprocessing, sp_nrt_d_var_pam_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_dimensional_data_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_odse_nbs_page_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_nrt_srte_condition_code_postprocessing, sp_nrt_tb_pam_ldf_postprocessing, sp_nrt_treatment_postprocessing, sp_nrt_var_pam_ldf_postprocessing, sp_observation_event, sp_organization_event, sp_page_builder_postprocessing, sp_patient_dim_columns_update_to_datamart, sp_patient_event, sp_patient_race_event, sp_pertussis_case_datamart_postprocessing, sp_place_event, sp_provider_dim_columns_update_to_datamart, sp_provider_event, sp_public_health_case_fact_datamart_event, sp_public_health_case_fact_datamart_update, sp_repeated_place_postprocessing, sp_rubella_case_datamart_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing, sp_sr100_datamart_postprocessing, sp_std_hiv_datamart_postprocessing, sp_summary_report_case_postprocessing, sp_tb_datamart_postprocessing, sp_tb_hiv_datamart_postprocessing, sp_treatment_event, sp_user_profile_postprocessing, sp_user_report_permissions, sp_vaccination_event, sp_var_datamart_postprocessing | yes | no |
| row_count | sp_aggregate_report_datamart_postprocessing, sp_alter_datamart_schema_postprocessing, sp_auth_user_event, sp_batch_id_cleanup_postprocessing, sp_bmird_case_datamart_postprocessing, sp_bmird_strep_pneumo_datamart_postprocessing, sp_case_lab_datamart_postprocessing, sp_contact_record_event, sp_covid_case_datamart_postprocessing, sp_covid_contact_datamart_postprocessing, sp_covid_lab_celr_datamart_postprocessing, sp_covid_lab_datamart_postprocessing, sp_covid_vaccination_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_d_contact_record_postprocessing, sp_d_interview_postprocessing, sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing, sp_d_pagebuilder_postprocessing, sp_d_vaccination_postprocessing, sp_dyn_dm_case_management_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_dimension_update, sp_dyn_dm_invest_clear_postprocessing, sp_dyn_dm_invest_form_postprocessing, sp_dyn_dm_main_postprocessing, sp_dyn_dm_org_data_postprocessing, sp_dyn_dm_page_builder_d_inv_postprocessing, sp_dyn_dm_provider_data_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing, sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing, sp_execute_ldf_generic, sp_f_contact_record_case_postprocessing, sp_f_interview_case_postprocessing, sp_f_page_case_postprocessing, sp_f_std_page_case_postprocessing, sp_f_tb_pam_postprocessing, sp_f_vaccination_postprocessing, sp_f_var_pam_postprocessing, sp_generic_case_datamart_postprocessing, sp_hep100_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_hepatitis_datamart_postprocessing, sp_interview_event, sp_inv_summary_datamart_postprocessing, sp_investigation_event, sp_l_pagebuilder_postprocessing, sp_lab100_datamart_postprocessing, sp_lab101_datamart_postprocessing, sp_ldf_bmird_datamart_postprocessing, sp_ldf_data_event, sp_ldf_foodborne_datamart_postprocessing, sp_ldf_generic_datamart_postprocessing, sp_ldf_hepatitis_datamart_postprocessing, sp_ldf_intervention_event, sp_ldf_mumps_datamart_postprocessing, sp_ldf_observation_event, sp_ldf_organization_event, sp_ldf_patient_event, sp_ldf_phc_event, sp_ldf_provider_event, sp_ldf_tetanus_datamart_postprocessing, sp_ldf_vaccine_prevent_diseases_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_merge_tables, sp_morbidity_report_datamart_postprocessing, sp_notification_event, sp_nrt_backfill_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_d_addl_risk_postprocessing, sp_nrt_d_disease_site_postprocessing, sp_nrt_d_gt_12_reas_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing, sp_nrt_d_move_cntry_postprocessing, sp_nrt_d_move_cnty_postprocessing, sp_nrt_d_move_state_postprocessing, sp_nrt_d_moved_where_postprocessing, sp_nrt_d_out_of_cntry_postprocessing, sp_nrt_d_pcr_source_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing, sp_nrt_d_tb_hiv_postprocessing, sp_nrt_d_tb_pam_postprocessing, sp_nrt_d_var_pam_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_dimensional_data_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_odse_nbs_page_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_nrt_srte_condition_code_postprocessing, sp_nrt_tb_pam_ldf_postprocessing, sp_nrt_treatment_postprocessing, sp_nrt_var_pam_ldf_postprocessing, sp_observation_event, sp_organization_event, sp_page_builder_postprocessing, sp_patient_dim_columns_update_to_datamart, sp_patient_event, sp_patient_race_event, sp_pertussis_case_datamart_postprocessing, sp_place_event, sp_provider_dim_columns_update_to_datamart, sp_provider_event, sp_public_health_case_fact_datamart_event, sp_public_health_case_fact_datamart_update, sp_repeated_place_postprocessing, sp_rubella_case_datamart_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing, sp_sr100_datamart_postprocessing, sp_std_hiv_datamart_postprocessing, sp_summary_report_case_postprocessing, sp_tb_datamart_postprocessing, sp_tb_hiv_datamart_postprocessing, sp_treatment_event, sp_user_profile_postprocessing, sp_user_report_permissions, sp_vaccination_event, sp_var_datamart_postprocessing | yes | no |
| Status_Type | sp_aggregate_report_datamart_postprocessing, sp_alter_datamart_schema_postprocessing, sp_auth_user_event, sp_batch_id_cleanup_postprocessing, sp_bmird_case_datamart_postprocessing, sp_bmird_strep_pneumo_datamart_postprocessing, sp_case_lab_datamart_postprocessing, sp_contact_record_event, sp_covid_case_datamart_postprocessing, sp_covid_contact_datamart_postprocessing, sp_covid_lab_celr_datamart_postprocessing, sp_covid_lab_datamart_postprocessing, sp_covid_vaccination_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_d_contact_record_postprocessing, sp_d_interview_postprocessing, sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing, sp_d_pagebuilder_postprocessing, sp_d_vaccination_postprocessing, sp_dyn_dm_case_management_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_dimension_update, sp_dyn_dm_invest_clear_postprocessing, sp_dyn_dm_invest_form_postprocessing, sp_dyn_dm_main_postprocessing, sp_dyn_dm_org_data_postprocessing, sp_dyn_dm_page_builder_d_inv_postprocessing, sp_dyn_dm_provider_data_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing, sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing, sp_execute_ldf_generic, sp_f_contact_record_case_postprocessing, sp_f_interview_case_postprocessing, sp_f_page_case_postprocessing, sp_f_std_page_case_postprocessing, sp_f_tb_pam_postprocessing, sp_f_vaccination_postprocessing, sp_f_var_pam_postprocessing, sp_generic_case_datamart_postprocessing, sp_hep100_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_hepatitis_datamart_postprocessing, sp_interview_event, sp_inv_summary_datamart_postprocessing, sp_investigation_event, sp_l_pagebuilder_postprocessing, sp_lab100_datamart_postprocessing, sp_lab101_datamart_postprocessing, sp_ldf_bmird_datamart_postprocessing, sp_ldf_data_event, sp_ldf_foodborne_datamart_postprocessing, sp_ldf_generic_datamart_postprocessing, sp_ldf_hepatitis_datamart_postprocessing, sp_ldf_intervention_event, sp_ldf_mumps_datamart_postprocessing, sp_ldf_observation_event, sp_ldf_organization_event, sp_ldf_patient_event, sp_ldf_phc_event, sp_ldf_provider_event, sp_ldf_tetanus_datamart_postprocessing, sp_ldf_vaccine_prevent_diseases_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_merge_tables, sp_morbidity_report_datamart_postprocessing, sp_notification_event, sp_nrt_backfill_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_d_addl_risk_postprocessing, sp_nrt_d_disease_site_postprocessing, sp_nrt_d_gt_12_reas_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing, sp_nrt_d_move_cntry_postprocessing, sp_nrt_d_move_cnty_postprocessing, sp_nrt_d_move_state_postprocessing, sp_nrt_d_moved_where_postprocessing, sp_nrt_d_out_of_cntry_postprocessing, sp_nrt_d_pcr_source_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing, sp_nrt_d_tb_hiv_postprocessing, sp_nrt_d_tb_pam_postprocessing, sp_nrt_d_var_pam_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_dimensional_data_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_odse_nbs_page_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_nrt_srte_condition_code_postprocessing, sp_nrt_tb_pam_ldf_postprocessing, sp_nrt_treatment_postprocessing, sp_nrt_var_pam_ldf_postprocessing, sp_observation_event, sp_organization_event, sp_page_builder_postprocessing, sp_patient_dim_columns_update_to_datamart, sp_patient_event, sp_patient_race_event, sp_pertussis_case_datamart_postprocessing, sp_place_event, sp_provider_dim_columns_update_to_datamart, sp_provider_event, sp_public_health_case_fact_datamart_event, sp_public_health_case_fact_datamart_update, sp_repeated_place_postprocessing, sp_rubella_case_datamart_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing, sp_sr100_datamart_postprocessing, sp_std_hiv_datamart_postprocessing, sp_summary_report_case_postprocessing, sp_tb_datamart_postprocessing, sp_tb_hiv_datamart_postprocessing, sp_treatment_event, sp_user_profile_postprocessing, sp_user_report_permissions, sp_vaccination_event, sp_var_datamart_postprocessing | yes | no |
| step_name | sp_aggregate_report_datamart_postprocessing, sp_alter_datamart_schema_postprocessing, sp_auth_user_event, sp_batch_id_cleanup_postprocessing, sp_bmird_case_datamart_postprocessing, sp_bmird_strep_pneumo_datamart_postprocessing, sp_case_lab_datamart_postprocessing, sp_contact_record_event, sp_covid_case_datamart_postprocessing, sp_covid_contact_datamart_postprocessing, sp_covid_lab_celr_datamart_postprocessing, sp_covid_lab_datamart_postprocessing, sp_covid_vaccination_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_d_contact_record_postprocessing, sp_d_interview_postprocessing, sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing, sp_d_pagebuilder_postprocessing, sp_d_vaccination_postprocessing, sp_dyn_dm_case_management_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_dimension_update, sp_dyn_dm_invest_clear_postprocessing, sp_dyn_dm_invest_form_postprocessing, sp_dyn_dm_main_postprocessing, sp_dyn_dm_org_data_postprocessing, sp_dyn_dm_page_builder_d_inv_postprocessing, sp_dyn_dm_provider_data_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing, sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing, sp_execute_ldf_generic, sp_f_contact_record_case_postprocessing, sp_f_interview_case_postprocessing, sp_f_page_case_postprocessing, sp_f_std_page_case_postprocessing, sp_f_tb_pam_postprocessing, sp_f_vaccination_postprocessing, sp_f_var_pam_postprocessing, sp_generic_case_datamart_postprocessing, sp_hep100_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_hepatitis_datamart_postprocessing, sp_interview_event, sp_inv_summary_datamart_postprocessing, sp_investigation_event, sp_l_pagebuilder_postprocessing, sp_lab100_datamart_postprocessing, sp_lab101_datamart_postprocessing, sp_ldf_bmird_datamart_postprocessing, sp_ldf_data_event, sp_ldf_foodborne_datamart_postprocessing, sp_ldf_generic_datamart_postprocessing, sp_ldf_hepatitis_datamart_postprocessing, sp_ldf_intervention_event, sp_ldf_mumps_datamart_postprocessing, sp_ldf_observation_event, sp_ldf_organization_event, sp_ldf_patient_event, sp_ldf_phc_event, sp_ldf_provider_event, sp_ldf_tetanus_datamart_postprocessing, sp_ldf_vaccine_prevent_diseases_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_merge_tables, sp_morbidity_report_datamart_postprocessing, sp_notification_event, sp_nrt_backfill_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_d_addl_risk_postprocessing, sp_nrt_d_disease_site_postprocessing, sp_nrt_d_gt_12_reas_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing, sp_nrt_d_move_cntry_postprocessing, sp_nrt_d_move_cnty_postprocessing, sp_nrt_d_move_state_postprocessing, sp_nrt_d_moved_where_postprocessing, sp_nrt_d_out_of_cntry_postprocessing, sp_nrt_d_pcr_source_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing, sp_nrt_d_tb_hiv_postprocessing, sp_nrt_d_tb_pam_postprocessing, sp_nrt_d_var_pam_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_dimensional_data_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_odse_nbs_page_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_nrt_srte_condition_code_postprocessing, sp_nrt_tb_pam_ldf_postprocessing, sp_nrt_treatment_postprocessing, sp_nrt_var_pam_ldf_postprocessing, sp_observation_event, sp_organization_event, sp_page_builder_postprocessing, sp_patient_dim_columns_update_to_datamart, sp_patient_event, sp_patient_race_event, sp_pertussis_case_datamart_postprocessing, sp_place_event, sp_provider_dim_columns_update_to_datamart, sp_provider_event, sp_public_health_case_fact_datamart_event, sp_public_health_case_fact_datamart_update, sp_repeated_place_postprocessing, sp_rubella_case_datamart_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing, sp_sr100_datamart_postprocessing, sp_std_hiv_datamart_postprocessing, sp_summary_report_case_postprocessing, sp_tb_datamart_postprocessing, sp_tb_hiv_datamart_postprocessing, sp_treatment_event, sp_user_profile_postprocessing, sp_user_report_permissions, sp_vaccination_event, sp_var_datamart_postprocessing | yes | no |
| step_number | sp_aggregate_report_datamart_postprocessing, sp_alter_datamart_schema_postprocessing, sp_auth_user_event, sp_batch_id_cleanup_postprocessing, sp_bmird_case_datamart_postprocessing, sp_bmird_strep_pneumo_datamart_postprocessing, sp_case_lab_datamart_postprocessing, sp_contact_record_event, sp_covid_case_datamart_postprocessing, sp_covid_contact_datamart_postprocessing, sp_covid_lab_celr_datamart_postprocessing, sp_covid_lab_datamart_postprocessing, sp_covid_vaccination_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_d_contact_record_postprocessing, sp_d_interview_postprocessing, sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing, sp_d_pagebuilder_postprocessing, sp_d_vaccination_postprocessing, sp_dyn_dm_case_management_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_dimension_update, sp_dyn_dm_invest_clear_postprocessing, sp_dyn_dm_invest_form_postprocessing, sp_dyn_dm_main_postprocessing, sp_dyn_dm_org_data_postprocessing, sp_dyn_dm_page_builder_d_inv_postprocessing, sp_dyn_dm_provider_data_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing, sp_event_metric_cleanup_postprocessing, sp_event_metric_datamart_postprocessing, sp_execute_ldf_generic, sp_f_contact_record_case_postprocessing, sp_f_interview_case_postprocessing, sp_f_page_case_postprocessing, sp_f_std_page_case_postprocessing, sp_f_tb_pam_postprocessing, sp_f_vaccination_postprocessing, sp_f_var_pam_postprocessing, sp_generic_case_datamart_postprocessing, sp_hep100_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_hepatitis_datamart_postprocessing, sp_interview_event, sp_inv_summary_datamart_postprocessing, sp_investigation_event, sp_l_pagebuilder_postprocessing, sp_lab100_datamart_postprocessing, sp_lab101_datamart_postprocessing, sp_ldf_bmird_datamart_postprocessing, sp_ldf_data_event, sp_ldf_foodborne_datamart_postprocessing, sp_ldf_generic_datamart_postprocessing, sp_ldf_hepatitis_datamart_postprocessing, sp_ldf_intervention_event, sp_ldf_mumps_datamart_postprocessing, sp_ldf_observation_event, sp_ldf_organization_event, sp_ldf_patient_event, sp_ldf_phc_event, sp_ldf_provider_event, sp_ldf_tetanus_datamart_postprocessing, sp_ldf_vaccine_prevent_diseases_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_merge_tables, sp_morbidity_report_datamart_postprocessing, sp_notification_event, sp_nrt_backfill_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_d_addl_risk_postprocessing, sp_nrt_d_disease_site_postprocessing, sp_nrt_d_gt_12_reas_postprocessing, sp_nrt_d_hc_prov_ty_3_postprocessing, sp_nrt_d_move_cntry_postprocessing, sp_nrt_d_move_cnty_postprocessing, sp_nrt_d_move_state_postprocessing, sp_nrt_d_moved_where_postprocessing, sp_nrt_d_out_of_cntry_postprocessing, sp_nrt_d_pcr_source_postprocessing, sp_nrt_d_rash_loc_gen_postprocessing, sp_nrt_d_smr_exam_ty_postprocessing, sp_nrt_d_tb_hiv_postprocessing, sp_nrt_d_tb_pam_postprocessing, sp_nrt_d_var_pam_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_dimensional_data_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_odse_nbs_page_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_nrt_srte_condition_code_postprocessing, sp_nrt_tb_pam_ldf_postprocessing, sp_nrt_treatment_postprocessing, sp_nrt_var_pam_ldf_postprocessing, sp_observation_event, sp_organization_event, sp_page_builder_postprocessing, sp_patient_dim_columns_update_to_datamart, sp_patient_event, sp_patient_race_event, sp_pertussis_case_datamart_postprocessing, sp_place_event, sp_provider_dim_columns_update_to_datamart, sp_provider_event, sp_public_health_case_fact_datamart_event, sp_public_health_case_fact_datamart_update, sp_repeated_place_postprocessing, sp_rubella_case_datamart_postprocessing, sp_s_pagebuilder_postprocessing, sp_sld_investigation_repeat_postprocessing, sp_sr100_datamart_postprocessing, sp_std_hiv_datamart_postprocessing, sp_summary_report_case_postprocessing, sp_tb_datamart_postprocessing, sp_tb_hiv_datamart_postprocessing, sp_treatment_event, sp_user_profile_postprocessing, sp_user_report_permissions, sp_vaccination_event, sp_var_datamart_postprocessing | yes | no |
| update_dttm | sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_repeatdate_postprocessing, sp_f_std_page_case_postprocessing, sp_nrt_case_count_postprocessing, sp_nrt_case_management_postprocessing, sp_nrt_investigation_postprocessing, sp_nrt_ldf_postprocessing, sp_nrt_notification_postprocessing, sp_nrt_organization_postprocessing, sp_nrt_patient_postprocessing, sp_nrt_place_postprocessing, sp_nrt_provider_postprocessing, sp_repeated_place_postprocessing | yes | no |

### dbo.L_INV_PLACE_REPEAT

Writers:
- `sp_repeated_place_postprocessing` (postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_INV_PLACE_REPEAT_KEY | sp_repeated_place_postprocessing | yes | no |
| PAGE_CASE_UID | sp_repeated_place_postprocessing | yes | no |

### dbo.L_INVESTIGATION_REPEAT

Writers:
- `sp_sld_investigation_repeat_postprocessing` (postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_INVESTIGATION_REPEAT_KEY | sp_sld_investigation_repeat_postprocessing | yes | no |
| PAGE_CASE_UID | sp_sld_investigation_repeat_postprocessing | yes | no |

### dbo.L_INVESTIGATION_REPEAT_INC

Writers:
- `sp_sld_investigation_repeat_postprocessing` (postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| D_INVESTIGATION_REPEAT_KEY | sp_sld_investigation_repeat_postprocessing | yes | no |
| PAGE_CASE_UID | sp_sld_investigation_repeat_postprocessing | yes | no |

### dbo.LAB100

Writers:
- `sp_lab100_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ACCESSION_NBR | sp_lab100_datamart_postprocessing | no | no |
| ADDR_CD_DESC | sp_lab100_datamart_postprocessing | no | no |
| ADDR_USE_CD_DESC | sp_lab100_datamart_postprocessing | no | no |
| ADDRESS_DATE | sp_lab100_datamart_postprocessing | no | no |
| AGE_REPORTED | sp_lab100_datamart_postprocessing | no | no |
| ALT_LAB_TEST_CD | sp_lab100_datamart_postprocessing | no | no |
| ALT_LAB_TEST_CD_DESC | sp_lab100_datamart_postprocessing | no | no |
| ALT_LAB_TEST_CD_SYS_CD | sp_lab100_datamart_postprocessing | no | no |
| ALT_LAB_TEST_CD_SYS_NM | sp_lab100_datamart_postprocessing | no | no |
| CONDITION_CD | sp_lab100_datamart_postprocessing | no | no |
| CONDITION_SHORT_NM | sp_lab100_datamart_postprocessing | no | no |
| ELR_IND | sp_lab100_datamart_postprocessing | no | no |
| EVENT_DATE | sp_lab100_datamart_postprocessing | no | no |
| INVESTIGATION_KEYS | sp_lab100_datamart_postprocessing | no | no |
| JURISDICTION_CD | sp_lab100_datamart_postprocessing | no | no |
| JURISDICTION_NM | sp_lab100_datamart_postprocessing | no | no |
| LAB_RESULT_COMMENTS | sp_lab100_datamart_postprocessing | no | no |
| LAB_RESULT_TXT_VAL | sp_lab100_datamart_postprocessing | no | no |
| LAB_RPT_CREATED_DT | sp_lab100_datamart_postprocessing | no | no |
| LAB_RPT_LAST_UPDATE_DT | sp_lab100_datamart_postprocessing | no | no |
| LAB_RPT_LOCAL_ID | sp_lab100_datamart_postprocessing | no | no |
| LAB_RPT_RECEIVED_BY_PH_DT | sp_lab100_datamart_postprocessing | no | no |
| LAB_RPT_STATUS | sp_lab100_datamart_postprocessing | no | no |
| LAB_TEST_DT | sp_lab100_datamart_postprocessing | no | no |
| LAB_TEST_STATUS | sp_lab100_datamart_postprocessing | no | no |
| LDF_GROUP_KEY | sp_lab100_datamart_postprocessing | no | no |
| MORB_RPT_KEY | sp_lab100_datamart_postprocessing | no | no |
| NUMERIC_RESULT_WITHUNITS | sp_lab100_datamart_postprocessing | no | no |
| ORDERED_LAB_TEST_CD | sp_lab100_datamart_postprocessing | no | no |
| ORDERED_LAB_TEST_CD_DESC | sp_lab100_datamart_postprocessing | no | no |
| ORDERED_LABTEST_CD_SYS_NM | sp_lab100_datamart_postprocessing | no | no |
| ORDERING_FACILITY | sp_lab100_datamart_postprocessing | no | no |
| ORDERING_PROVIDER_NM | sp_lab100_datamart_postprocessing | no | no |
| PATIENT_ADDRESS | sp_lab100_datamart_postprocessing | no | no |
| PATIENT_CITY | sp_lab100_datamart_postprocessing | no | no |
| PATIENT_COUNTY | sp_lab100_datamart_postprocessing | no | no |
| PATIENT_KEY | sp_lab100_datamart_postprocessing | no | no |
| PATIENT_REPORTED_AGE_UNITS | sp_lab100_datamart_postprocessing | no | no |
| PATIENT_STATE | sp_lab100_datamart_postprocessing | no | no |
| PATIENT_ZIP_CODE | sp_lab100_datamart_postprocessing | no | no |
| PERSON_CURR_GENDER | sp_lab100_datamart_postprocessing | no | no |
| PERSON_DOB | sp_lab100_datamart_postprocessing | no | no |
| PERSON_FIRST_NM | sp_lab100_datamart_postprocessing | no | no |
| PERSON_LAST_NM | sp_lab100_datamart_postprocessing | no | no |
| PERSON_LOCAL_ID | sp_lab100_datamart_postprocessing | no | no |
| PERSON_MIDDLE_NM | sp_lab100_datamart_postprocessing | no | no |
| PROGRAM_AREA_CD | sp_lab100_datamart_postprocessing | no | no |
| PROGRAM_AREA_DESC | sp_lab100_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_lab100_datamart_postprocessing | no | no |
| PROVIDER_ADDRESS | sp_lab100_datamart_postprocessing | no | no |
| PROVIDER_PHONE | sp_lab100_datamart_postprocessing | no | no |
| PRV_ADDR_CD_DESC | sp_lab100_datamart_postprocessing | no | no |
| PRV_ADDR_USE_CD_DESC | sp_lab100_datamart_postprocessing | no | no |
| RDB_LAST_REFRESH_TIME | sp_lab100_datamart_postprocessing | no | no |
| REASON_FOR_TEST_DESC | sp_lab100_datamart_postprocessing | no | no |
| RECORD_STATUS_CD | sp_lab100_datamart_postprocessing | no | no |
| REPORTING_FACILITY | sp_lab100_datamart_postprocessing | no | no |
| REPORTING_FACILITY_UID | sp_lab100_datamart_postprocessing | no | no |
| RESULT_REF_RANGE_FRM | sp_lab100_datamart_postprocessing | no | no |
| RESULT_REF_RANGE_TO | sp_lab100_datamart_postprocessing | no | no |
| RESULTED_LAB_TEST_CD | sp_lab100_datamart_postprocessing | no | no |
| RESULTED_LAB_TEST_CD_DESC | sp_lab100_datamart_postprocessing | no | no |
| RESULTED_LAB_TEST_KEY | sp_lab100_datamart_postprocessing | no | no |
| RESULTEDTEST_CD_SYS_NM | sp_lab100_datamart_postprocessing | no | no |
| RESULTEDTEST_VAL_CD | sp_lab100_datamart_postprocessing | no | no |
| RESULTEDTEST_VAL_CD_DESC | sp_lab100_datamart_postprocessing | no | no |
| SPECIMEN_COLLECTION_DT | sp_lab100_datamart_postprocessing | no | no |
| SPECIMEN_SRC_CD | sp_lab100_datamart_postprocessing | no | no |
| SPECIMEN_SRC_DESC | sp_lab100_datamart_postprocessing | no | no |

### dbo.LAB101

Writers:
- `sp_lab101_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CASE_LAB_CONFIRMED_IND | sp_lab101_datamart_postprocessing | no | no |
| EIP_ACTUAL_SHIP_DATE | sp_lab101_datamart_postprocessing | no | no |
| EIP_EXPECTED_SHIP_DATE | sp_lab101_datamart_postprocessing | no | no |
| EIP_ISO_IND | sp_lab101_datamart_postprocessing | no | no |
| EIP_SHIP_LOCATION | sp_lab101_datamart_postprocessing | no | no |
| EIP_SPEC_ACTUAL_RESHIP_DATE | sp_lab101_datamart_postprocessing | no | no |
| EIP_SPEC_AVAIL_IND | sp_lab101_datamart_postprocessing | no | no |
| EIP_SPEC_EXPECTED_RESHIP_DATE | sp_lab101_datamart_postprocessing | no | no |
| EIP_SPEC_NO_REASON | sp_lab101_datamart_postprocessing | no | no |
| EIP_SPEC_NO_REASON_OTH | sp_lab101_datamart_postprocessing | no | no |
| EIP_SPEC_RESHIP_IND | sp_lab101_datamart_postprocessing | no | no |
| EIP_SPEC_RESHIP_REASON | sp_lab101_datamart_postprocessing | no | no |
| EIP_SPEC_RESHIP_REASON_OTH | sp_lab101_datamart_postprocessing | no | no |
| EVENT_DATE | sp_lab101_datamart_postprocessing | no | no |
| ISO_NO_RECEIVED_REASON | sp_lab101_datamart_postprocessing | no | no |
| ISO_NO_RECEIVED_REASON_OTH | sp_lab101_datamart_postprocessing | no | no |
| ISO_RECEIVED_DATE | sp_lab101_datamart_postprocessing | no | no |
| ISO_RECEIVED_IND | sp_lab101_datamart_postprocessing | no | no |
| ISO_SENT_CDC_IND | sp_lab101_datamart_postprocessing | no | no |
| ISO_STATEID_NUM | sp_lab101_datamart_postprocessing | no | no |
| LAB_RPT_LOCAL_ID | sp_lab101_datamart_postprocessing | no | no |
| NARMS_ACTUAL_SHIP_DATE | sp_lab101_datamart_postprocessing | no | no |
| NARMS_EXPECTED_SHIP_DATE | sp_lab101_datamart_postprocessing | no | no |
| NARMS_ISO_IND | sp_lab101_datamart_postprocessing | no | no |
| NARMS_ISO_SENT_IND | sp_lab101_datamart_postprocessing | no | no |
| NARMS_NO_SENT_REASON | sp_lab101_datamart_postprocessing | no | no |
| NARMS_STATEID_NUM | sp_lab101_datamart_postprocessing | no | no |
| PATIENT_STATUS | sp_lab101_datamart_postprocessing | no | no |
| PFGE_PULSENET_ENZYME1 | sp_lab101_datamart_postprocessing | no | no |
| PFGE_PULSENET_ENZYME2 | sp_lab101_datamart_postprocessing | no | no |
| PFGE_PULSENET_ENZYME3 | sp_lab101_datamart_postprocessing | no | no |
| PFGE_PULSENET_SENT | sp_lab101_datamart_postprocessing | no | no |
| PFGE_STATELAB_ENZYME1 | sp_lab101_datamart_postprocessing | no | no |
| PFGE_STATELAB_ENZYME2 | sp_lab101_datamart_postprocessing | no | no |
| PFGE_STATELAB_ENZYME3 | sp_lab101_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_lab101_datamart_postprocessing | no | no |
| PULSENET_ISO_IND | sp_lab101_datamart_postprocessing | no | no |
| RDB_LAST_REFRESH_TIME | sp_lab101_datamart_postprocessing | no | no |
| RECORD_STATUS_CD | sp_lab101_datamart_postprocessing | no | no |
| REPORTING_FACILITY_UID | sp_lab101_datamart_postprocessing | no | no |
| RESULTED_LAB_TEST_CD_DESC | sp_lab101_datamart_postprocessing | no | no |
| RESULTED_LAB_TEST_KEY | sp_lab101_datamart_postprocessing | no | no |
| SPECIMEN_COLLECTION_DT | sp_lab101_datamart_postprocessing | no | no |
| SPECIMEN_SRC_CD | sp_lab101_datamart_postprocessing | no | no |
| SPECIMEN_SRC_DESC | sp_lab101_datamart_postprocessing | no | no |
| TRACK_ISO_IND | sp_lab101_datamart_postprocessing | no | no |

### dbo.Lab_Result_Comment

Writers:
- `sp_d_labtest_result_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| LAB_RESULT_COMMENT_KEY | sp_d_labtest_result_postprocessing | yes | no |
| LAB_RESULT_COMMENTS | sp_d_labtest_result_postprocessing | yes | no |
| LAB_TEST_UID | sp_d_labtest_result_postprocessing | yes | no |
| RDB_LAST_REFRESH_TIME | sp_d_labtest_result_postprocessing | yes | no |
| RECORD_STATUS_CD | sp_d_labtest_result_postprocessing | yes | no |
| RESULT_COMMENT_GRP_KEY | sp_d_labtest_result_postprocessing | yes | no |

### dbo.LAB_RESULT_VAL

Writers:
- `sp_d_labtest_result_postprocessing` (postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ALT_RESULT_VAL_CD | sp_d_labtest_result_postprocessing | no | no |
| ALT_RESULT_VAL_CD_DESC | sp_d_labtest_result_postprocessing | no | no |
| ALT_RESULT_VAL_CD_SYS_CD | sp_d_labtest_result_postprocessing | no | no |
| ALT_RESULT_VAL_CD_SYS_NM | sp_d_labtest_result_postprocessing | no | no |
| FROM_TIME | sp_d_labtest_result_postprocessing | no | no |
| LAB_RESULT_TXT_VAL | sp_d_labtest_result_postprocessing | no | no |
| LAB_TEST_UID | sp_d_labtest_result_postprocessing | no | no |
| NUMERIC_RESULT | sp_d_labtest_result_postprocessing | no | no |
| RDB_LAST_REFRESH_TIME | sp_d_labtest_result_postprocessing | no | no |
| RECORD_STATUS_CD | sp_d_labtest_result_postprocessing | no | no |
| REF_RANGE_FRM | sp_d_labtest_result_postprocessing | no | no |
| REF_RANGE_TO | sp_d_labtest_result_postprocessing | no | no |
| RESULT_UNITS | sp_d_labtest_result_postprocessing | no | no |
| TEST_RESULT_GRP_KEY | sp_d_labtest_result_postprocessing | no | no |
| TEST_RESULT_VAL_CD | sp_d_labtest_result_postprocessing | no | no |
| TEST_RESULT_VAL_CD_DESC | sp_d_labtest_result_postprocessing | no | no |
| TEST_RESULT_VAL_CD_SYS_CD | sp_d_labtest_result_postprocessing | no | no |
| TEST_RESULT_VAL_CD_SYS_NM | sp_d_labtest_result_postprocessing | no | no |
| TEST_RESULT_VAL_KEY | sp_d_labtest_result_postprocessing | no | no |
| TO_TIME | sp_d_labtest_result_postprocessing | no | no |

### dbo.LAB_RPT_USER_COMMENT

Writers:
- `sp_d_lab_test_postprocessing` (postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| COMMENTS_FOR_ELR_DT | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_KEY | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_UID | sp_d_lab_test_postprocessing | no | no |
| RDB_LAST_REFRESH_TIME | sp_d_lab_test_postprocessing | no | no |
| RECORD_STATUS_CD | sp_d_lab_test_postprocessing | no | no |
| USER_COMMENT_CREATED_BY | sp_d_lab_test_postprocessing | no | no |
| USER_COMMENT_KEY | sp_d_lab_test_postprocessing | no | no |
| USER_RPT_COMMENTS | sp_d_lab_test_postprocessing | no | no |

### dbo.LAB_TEST

Writers:
- `sp_d_lab_test_postprocessing` (postprocessing) — ops: INSERT,UPDATE
- `sp_d_labtest_result_postprocessing` (postprocessing) — ops: UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ACCESSION_NBR | sp_d_lab_test_postprocessing | no | no |
| ALT_LAB_TEST_CD | sp_d_lab_test_postprocessing | no | no |
| ALT_LAB_TEST_CD_DESC | sp_d_lab_test_postprocessing | no | no |
| ALT_LAB_TEST_CD_SYS_CD | sp_d_lab_test_postprocessing | no | no |
| ALT_LAB_TEST_CD_SYS_NM | sp_d_lab_test_postprocessing | no | no |
| ASSISTANT_INTER_ASS_AUTH_CD | sp_d_lab_test_postprocessing | no | no |
| ASSISTANT_INTER_ASS_AUTH_TYPE | sp_d_lab_test_postprocessing | no | no |
| ASSISTANT_INTERPRETER_ID | sp_d_lab_test_postprocessing | no | no |
| ASSISTANT_INTERPRETER_NAME | sp_d_lab_test_postprocessing | no | no |
| CLINICAL_INFORMATION | sp_d_lab_test_postprocessing | no | no |
| CONDITION_CD | sp_d_lab_test_postprocessing | no | no |
| DANGER_CD | sp_d_lab_test_postprocessing | no | no |
| DANGER_CD_DESC | sp_d_lab_test_postprocessing | no | no |
| ELR_IND | sp_d_lab_test_postprocessing | no | no |
| INTERPRETATION_FLG | sp_d_lab_test_postprocessing | no | no |
| JURISDICTION_CD | sp_d_lab_test_postprocessing | no | no |
| JURISDICTION_NM | sp_d_lab_test_postprocessing | no | no |
| LAB_RPT_CREATED_BY | sp_d_lab_test_postprocessing | no | no |
| LAB_RPT_CREATED_DT | sp_d_lab_test_postprocessing | no | no |
| LAB_RPT_LAST_UPDATE_BY | sp_d_lab_test_postprocessing | no | no |
| LAB_RPT_LAST_UPDATE_DT | sp_d_lab_test_postprocessing | no | no |
| LAB_RPT_LOCAL_ID | sp_d_lab_test_postprocessing | no | no |
| LAB_RPT_RECEIVED_BY_PH_DT | sp_d_lab_test_postprocessing | no | no |
| LAB_RPT_SHARE_IND | sp_d_lab_test_postprocessing | no | no |
| LAB_RPT_STATUS | sp_d_lab_test_postprocessing | no | no |
| LAB_RPT_UID | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_CD | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_CD_DESC | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_CD_SYS_CD | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_CD_SYS_NM | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_DT | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_KEY | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_PNTR | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_STATUS | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_TYPE | sp_d_lab_test_postprocessing | no | no |
| LAB_TEST_UID | sp_d_lab_test_postprocessing | no | no |
| OID | sp_d_lab_test_postprocessing | no | no |
| PARENT_TEST_NM | sp_d_lab_test_postprocessing | no | no |
| PARENT_TEST_PNTR | sp_d_lab_test_postprocessing | no | no |
| PRIORITY_CD | sp_d_lab_test_postprocessing | no | no |
| PROCESSING_DECISION_CD | sp_d_lab_test_postprocessing | no | no |
| PROCESSING_DECISION_DESC | sp_d_lab_test_postprocessing | no | no |
| RDB_LAST_REFRESH_TIME | sp_d_lab_test_postprocessing | no | no |
| REASON_FOR_TEST_CD | sp_d_lab_test_postprocessing | no | no |
| REASON_FOR_TEST_DESC | sp_d_lab_test_postprocessing | no | no |
| RECORD_STATUS_CD | sp_d_lab_test_postprocessing, sp_d_labtest_result_postprocessing | no | no |
| RESULT_INTERPRETER_NAME | sp_d_lab_test_postprocessing | no | no |
| ROOT_ORDERED_TEST_NM | sp_d_lab_test_postprocessing | no | no |
| ROOT_ORDERED_TEST_PNTR | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_ADD_TIME | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_COLLECTION_DT | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_COLLECTION_VOL | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_COLLECTION_VOL_UNIT | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_DESC | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_DETAILS | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_LAST_CHANGE_TIME | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_NM | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_SITE | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_SITE_DESC | sp_d_lab_test_postprocessing | no | no |
| SPECIMEN_SRC | sp_d_lab_test_postprocessing | no | no |
| TEST_METHOD_CD | sp_d_lab_test_postprocessing | no | no |
| TEST_METHOD_CD_DESC | sp_d_lab_test_postprocessing | no | no |
| TRANSCRIPTIONIST_ASS_AUTH_CD | sp_d_lab_test_postprocessing | no | no |
| TRANSCRIPTIONIST_ASS_AUTH_TYPE | sp_d_lab_test_postprocessing | no | no |
| TRANSCRIPTIONIST_ID | sp_d_lab_test_postprocessing | no | no |
| TRANSCRIPTIONIST_NAME | sp_d_lab_test_postprocessing | no | no |

### dbo.LAB_TEST_RESULT

Writers:
- `sp_d_labtest_result_postprocessing` (postprocessing) — ops: INSERT [guarded]
- `sp_d_morbidity_report_postprocessing` (postprocessing) — ops: UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CONDITION_KEY | sp_d_labtest_result_postprocessing | yes | no |
| COPY_TO_PROVIDER_KEY | sp_d_labtest_result_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_d_labtest_result_postprocessing | yes | no |
| LAB_RPT_DT_KEY | sp_d_labtest_result_postprocessing | yes | no |
| LAB_TEST_KEY | sp_d_labtest_result_postprocessing | yes | no |
| LAB_TEST_TECHNICIAN_KEY | sp_d_labtest_result_postprocessing | yes | no |
| LAB_TEST_UID | sp_d_labtest_result_postprocessing | yes | no |
| LDF_GROUP_KEY | sp_d_labtest_result_postprocessing | yes | no |
| morb_rpt_key | sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing | yes | no |
| ORDERING_ORG_KEY | sp_d_labtest_result_postprocessing | yes | no |
| ORDERING_PROVIDER_KEY | sp_d_labtest_result_postprocessing | yes | no |
| PATIENT_KEY | sp_d_labtest_result_postprocessing | yes | no |
| PERFORMING_LAB_KEY | sp_d_labtest_result_postprocessing | yes | no |
| RDB_LAST_REFRESH_TIME | sp_d_labtest_result_postprocessing, sp_d_morbidity_report_postprocessing | yes | no |
| RECORD_STATUS_CD | sp_d_labtest_result_postprocessing | yes | no |
| REPORTING_LAB_KEY | sp_d_labtest_result_postprocessing | yes | no |
| RESULT_COMMENT_GRP_KEY | sp_d_labtest_result_postprocessing | yes | no |
| SPECIMEN_COLLECTOR_KEY | sp_d_labtest_result_postprocessing | yes | no |
| TEST_RESULT_GRP_KEY | sp_d_labtest_result_postprocessing | yes | no |

### dbo.LDF_BMIRD

Writers:
- `sp_ldf_bmird_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| dynamiccolumnList | sp_ldf_bmird_datamart_postprocessing | yes | no |

### dbo.LDF_DATA

Writers:
- `sp_nrt_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| business_obj_nm | sp_nrt_ldf_postprocessing | no | no |
| cdc_national_id | sp_nrt_ldf_postprocessing | no | no |
| class_cd | sp_nrt_ldf_postprocessing | no | no |
| code_set_nm | sp_nrt_ldf_postprocessing | no | no |
| condition_cd | sp_nrt_ldf_postprocessing | no | no |
| condition_desc_txt | sp_nrt_ldf_postprocessing | no | no |
| display_order_number | sp_nrt_ldf_postprocessing | no | no |
| field_size | sp_nrt_ldf_postprocessing | no | no |
| import_version_nbr | sp_nrt_ldf_postprocessing | no | no |
| label_txt | sp_nrt_ldf_postprocessing | no | no |
| ldf_column_type | sp_nrt_ldf_postprocessing | no | no |
| ldf_data_key | sp_nrt_ldf_postprocessing | no | no |
| ldf_group_key | sp_nrt_ldf_postprocessing | no | no |
| ldf_oid | sp_nrt_ldf_postprocessing | no | no |
| ldf_value | sp_nrt_ldf_postprocessing | no | no |
| nnd_ind | sp_nrt_ldf_postprocessing | no | no |
| record_status_cd | sp_nrt_ldf_postprocessing | no | no |

### dbo.LDF_DATAMART_COLUMN_REF

Writers:
- `sp_nrt_ldf_dimensional_data_postprocessing` (nrt_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| BUSINESS_OBJECT_NM | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| CDC_NATIONAL_ID | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| CONDITION_CD | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| DATAMART_COLUMN_NM | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LDF_DATAMART_COLUMN_REF_UID | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LDF_LABEL | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LDF_PAGE_SET | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LDF_UID | sp_nrt_ldf_dimensional_data_postprocessing | no | no |

### dbo.LDF_DIMENSIONAL_DATA

Writers:
- `sp_nrt_ldf_dimensional_data_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| active_ind | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| BUSINESS_OBJECT_NM | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| CDC_NATIONAL_ID | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| class_cd | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| CODE_SET_NM | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| CODE_SHORT_DESC_TXT | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| COL1 | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| CONDITION_CD | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| CUSTOM_SUBFORM_METADATA_UID | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| DATA_SOURCE | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| DATA_TYPE | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| DATAMART_COLUMN_NM | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| FIELD_SIZE | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| INVESTIGATION_UID | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LABEL_TXT | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LDF_DATAMART_COLUMN_REF_UID | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LDF_LABEL | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LDF_PAGE_SET | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| LDF_UID | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| PAGE_SET | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| PHC_CD | sp_nrt_ldf_dimensional_data_postprocessing | no | no |
| state_cd | sp_nrt_ldf_dimensional_data_postprocessing | no | no |

### dbo.LDF_FOODBORNE

Writers:
- `sp_ldf_foodborne_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| DISEASE_NAME | sp_ldf_foodborne_datamart_postprocessing | yes | no |
| END | sp_ldf_foodborne_datamart_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_ldf_foodborne_datamart_postprocessing | yes | no |
| INVESTIGATION_LOCAL_ID | sp_ldf_foodborne_datamart_postprocessing | yes | no |
| PATIENT_KEY | sp_ldf_foodborne_datamart_postprocessing | yes | no |
| PATIENT_LOCAL_ID | sp_ldf_foodborne_datamart_postprocessing | yes | no |
| PROGRAM_JURISDICTION_OID | sp_ldf_foodborne_datamart_postprocessing | yes | no |
| THEN | sp_ldf_foodborne_datamart_postprocessing | yes | no |

### dbo.LDF_GROUP

Writers:
- `sp_nrt_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| business_object_uid | sp_nrt_ldf_postprocessing | yes | no |
| ldf_group_key | sp_nrt_ldf_postprocessing | yes | no |

### dbo.LDF_HEPATITIS

Writers:
- `sp_ldf_hepatitis_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| dynamiccolumnList | sp_ldf_hepatitis_datamart_postprocessing | yes | no |

### dbo.LDF_MUMPS

Writers:
- `sp_ldf_mumps_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| dynamiccolumnList | sp_ldf_mumps_datamart_postprocessing | yes | no |

### dbo.LDF_TETANUS

Writers:
- `sp_ldf_tetanus_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| DISEASE_NAME | sp_ldf_tetanus_datamart_postprocessing | yes | no |
| END | sp_ldf_tetanus_datamart_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_ldf_tetanus_datamart_postprocessing | yes | no |
| INVESTIGATION_LOCAL_ID | sp_ldf_tetanus_datamart_postprocessing | yes | no |
| PATIENT_KEY | sp_ldf_tetanus_datamart_postprocessing | yes | no |
| PATIENT_LOCAL_ID | sp_ldf_tetanus_datamart_postprocessing | yes | no |
| PROGRAM_JURISDICTION_OID | sp_ldf_tetanus_datamart_postprocessing | yes | no |
| THEN | sp_ldf_tetanus_datamart_postprocessing | yes | no |

### dbo.LDF_VACCINE_PREVENT_DISEASES

Writers:
- `sp_ldf_vaccine_prevent_diseases_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| DISEASE_NAME | sp_ldf_vaccine_prevent_diseases_datamart_postprocessing | yes | no |
| END | sp_ldf_vaccine_prevent_diseases_datamart_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_ldf_vaccine_prevent_diseases_datamart_postprocessing | yes | no |
| INVESTIGATION_LOCAL_ID | sp_ldf_vaccine_prevent_diseases_datamart_postprocessing | yes | no |
| PATIENT_KEY | sp_ldf_vaccine_prevent_diseases_datamart_postprocessing | yes | no |
| PATIENT_LOCAL_ID | sp_ldf_vaccine_prevent_diseases_datamart_postprocessing | yes | no |
| PROGRAM_JURISDICTION_OID | sp_ldf_vaccine_prevent_diseases_datamart_postprocessing | yes | no |
| THEN | sp_ldf_vaccine_prevent_diseases_datamart_postprocessing | yes | no |

### dbo.LOOKUP_TABLE_N_REPT

Writers:
- `sp_sld_investigation_repeat_postprocessing` (postprocessing) — ops: INSERT_NOCOL

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| <all> | sp_sld_investigation_repeat_postprocessing | no | no |

### dbo.morb_Rpt_User_Comment

Writers:
- `sp_d_morbidity_report_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| EXTERNAL_MORB_RPT_COMMENTS | sp_d_morbidity_report_postprocessing | yes | no |
| MORB_RPT_KEY | sp_d_morbidity_report_postprocessing | yes | no |
| MORB_RPT_UID | sp_d_morbidity_report_postprocessing | yes | no |
| RDB_LAST_REFRESH_TIME | sp_d_morbidity_report_postprocessing | yes | no |
| RECORD_STATUS_CD | sp_d_morbidity_report_postprocessing | yes | no |
| USER_COMMENT_KEY | sp_d_morbidity_report_postprocessing | yes | no |
| USER_COMMENTS_BY | sp_d_morbidity_report_postprocessing | yes | no |
| USER_COMMENTS_DT | sp_d_morbidity_report_postprocessing | yes | no |

### dbo.MORBIDITY_REPORT

Writers:
- `sp_d_morbidity_report_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| DAYCARE_IND | sp_d_morbidity_report_postprocessing | no | no |
| DIAGNOSIS_DT | sp_d_morbidity_report_postprocessing | no | no |
| DIE_FROM_ILLNESS_IND | sp_d_morbidity_report_postprocessing | no | no |
| ELECTRONIC_IND | sp_d_morbidity_report_postprocessing | no | no |
| FOOD_HANDLER_IND | sp_d_morbidity_report_postprocessing | no | no |
| HEALTHCARE_ORG_ASSOCIATE_IND | sp_d_morbidity_report_postprocessing | no | no |
| HOSPITALIZED_IND | sp_d_morbidity_report_postprocessing | no | no |
| HSPTL_ADMISSION_DT | sp_d_morbidity_report_postprocessing | no | no |
| JURISDICTION_CD | sp_d_morbidity_report_postprocessing | no | no |
| JURISDICTION_NM | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_COMMENTS | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_CREATE_BY | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_DELIVERY_METHOD | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_KEY | sp_d_morbidity_report_postprocessing | yes | no |
| MORB_RPT_LAST_UPDATE_BY | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_LAST_UPDATE_DT | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_LOCAL_ID | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_OID | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_OTHER_SPECIFY | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_SHARE_IND | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_TYPE | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_UID | sp_d_morbidity_report_postprocessing | no | no |
| NURSING_HOME_ASSOCIATE_IND | sp_d_morbidity_report_postprocessing | no | no |
| PH_RECEIVE_DT | sp_d_morbidity_report_postprocessing | no | no |
| PREGNANT_IND | sp_d_morbidity_report_postprocessing | no | no |
| PROCESSING_DECISION_CD | sp_d_morbidity_report_postprocessing | no | no |
| PROCESSING_DECISION_DESC | sp_d_morbidity_report_postprocessing | no | no |
| RDB_LAST_REFRESH_TIME | sp_d_morbidity_report_postprocessing | no | no |
| RECORD_STATUS_CD | sp_d_morbidity_report_postprocessing | yes | no |
| SUSPECT_FOOD_WTRBORNE_ILLNESS | sp_d_morbidity_report_postprocessing | no | no |

### dbo.MORBIDITY_REPORT_DATAMART

Writers:
- `sp_morbidity_report_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE
- `sp_patient_dim_columns_update_to_datamart` (datamart) — ops: UPDATE
- `sp_provider_dim_columns_update_to_datamart` (datamart) — ops: UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| AGE_REPORTED | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| AGE_REPORTED_UNIT | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| CASE_STATUS | sp_morbidity_report_datamart_postprocessing | no | no |
| CONDITION_NAME | sp_morbidity_report_datamart_postprocessing | no | no |
| DAYCARE | sp_morbidity_report_datamart_postprocessing | no | no |
| DELIVERY_METHOD | sp_morbidity_report_datamart_postprocessing | no | no |
| DIAGNOSIS_DATE | sp_morbidity_report_datamart_postprocessing | no | no |
| DIE_FROM_ILLNESS | sp_morbidity_report_datamart_postprocessing | no | no |
| EXTERNAL_IND | sp_morbidity_report_datamart_postprocessing | no | no |
| FOOD_HANDLER | sp_morbidity_report_datamart_postprocessing | no | no |
| FOOD_WATERBORNE_ILLNESS | sp_morbidity_report_datamart_postprocessing | no | no |
| HEALTHCARE_ORGANIZATION | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_ADMIN_DATE | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_DISCHARGE_DATE | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_FAC_CITY | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_FAC_NAME | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_FAC_PHONE | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_FAC_PHONE_EXT | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_FAC_STATE | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_FAC_STREET_ADDR_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_FAC_STREET_ADDR_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITAL_FAC_ZIP | sp_morbidity_report_datamart_postprocessing | no | no |
| HOSPITALIZED | sp_morbidity_report_datamart_postprocessing | no | no |
| ILLNESS_ONSET_DATE | sp_morbidity_report_datamart_postprocessing | no | no |
| INVESTIGATION_CREATED_IND | sp_morbidity_report_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_morbidity_report_datamart_postprocessing | no | no |
| JURISDICTION_NAME | sp_morbidity_report_datamart_postprocessing | no | no |
| LAB_GT3_CREATED_IND | sp_morbidity_report_datamart_postprocessing | no | no |
| LAB_REPORT_DATE_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| LAB_REPORT_DATE_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| LAB_REPORT_DATE_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| LAB_RESULT_COMMENTS_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| LAB_RESULT_COMMENTS_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| LAB_RESULT_COMMENTS_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| MORB_REPORT_CREATE_DATE | sp_morbidity_report_datamart_postprocessing | no | no |
| MORB_REPORT_CREATED_BY | sp_morbidity_report_datamart_postprocessing | no | no |
| MORB_REPORT_LAST_UPDATED_BY | sp_morbidity_report_datamart_postprocessing | no | no |
| MORB_REPORT_LAST_UPDATED_DATE | sp_morbidity_report_datamart_postprocessing | no | no |
| MORB_RPT_COMMENTS | sp_morbidity_report_datamart_postprocessing | no | no |
| MORBIDITY_REPORT_DATE | sp_morbidity_report_datamart_postprocessing | no | no |
| MORBIDITY_REPORT_KEY | sp_morbidity_report_datamart_postprocessing | no | no |
| MORBIDITY_REPORT_LOCAL_ID | sp_morbidity_report_datamart_postprocessing | no | no |
| MORBIDITY_REPORT_TYPE | sp_morbidity_report_datamart_postprocessing | no | no |
| NURSING_HOME | sp_morbidity_report_datamart_postprocessing | no | no |
| OTHER_EPI | sp_morbidity_report_datamart_postprocessing | no | no |
| PATIENT_CITY | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_COUNTRY | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_COUNTY | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_CURRENT_SEX | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_DECEASED_DATE | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_DECEASED_INDICATOR | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_DOB | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_ETHNICITY | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_FIRST_NAME | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_GENERAL_COMMENTS | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_LAST_NAME | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_LOCAL_ID | sp_morbidity_report_datamart_postprocessing | no | no |
| PATIENT_MARITAL_STATUS | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_MIDDLE_NAME | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_NAME_SUFFIX | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_PHONE_EXT_HOME | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_PHONE_EXT_WORK | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_PHONE_NUMBER_HOME | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_PHONE_NUMBER_WORK | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_SSN | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_STATE | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_STREET_ADDRESS_1 | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_STREET_ADDRESS_2 | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_ZIP | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| PH_RECEIVE_DT | sp_morbidity_report_datamart_postprocessing | no | no |
| PREGNANT | sp_morbidity_report_datamart_postprocessing | no | no |
| PROGRAM_AREA_DESCRIPTION | sp_morbidity_report_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_morbidity_report_datamart_postprocessing | no | no |
| PROVIDER_CITY | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| PROVIDER_FIRST_NAME | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| PROVIDER_LAST_NAME | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| PROVIDER_PHONE | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| PROVIDER_PHONE_EXT | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| PROVIDER_STATE | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| PROVIDER_STREET_ADDR_1 | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| PROVIDER_STREET_ADDR_2 | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| PROVIDER_ZIP | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| RACE_CALCULATED | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| RACE_CALCULATED_DETAILS | sp_morbidity_report_datamart_postprocessing, sp_patient_dim_columns_update_to_datamart | no | no |
| REPORT_FAC_CITY | sp_morbidity_report_datamart_postprocessing | no | no |
| REPORT_FAC_NAME | sp_morbidity_report_datamart_postprocessing | no | no |
| REPORT_FAC_PHONE | sp_morbidity_report_datamart_postprocessing | no | no |
| REPORT_FAC_PHONE_EXT | sp_morbidity_report_datamart_postprocessing | no | no |
| REPORT_FAC_STATE | sp_morbidity_report_datamart_postprocessing | no | no |
| REPORT_FAC_STREET_ADDR_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| REPORT_FAC_STREET_ADDR_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| REPORT_FAC_ZIP | sp_morbidity_report_datamart_postprocessing | no | no |
| REPORTER_CITY | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_FIRST_NAME | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_LAST_NAME | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_PHONE | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_PHONE_EXT | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_STATE | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_STREET_ADDR_1 | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_STREET_ADDR_2 | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTER_ZIP | sp_morbidity_report_datamart_postprocessing, sp_provider_dim_columns_update_to_datamart | no | no |
| REPORTING_FACILITY_UID | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_NAME_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_NAME_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_NAME_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_NUMERIC_CONCAT_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_NUMERIC_CONCAT_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_NUMERIC_CONCAT_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_RESULT_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_RESULT_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_RESULT_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_TEXT_RESULT_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_TEXT_RESULT_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| RESULTED_TEST_TEXT_RESULT_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| SPECIMEN_COLLECTION_DATE_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| SPECIMEN_COLLECTION_DATE_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| SPECIMEN_COLLECTION_DATE_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| SPECIMEN_SOURCE_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| SPECIMEN_SOURCE_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| SPECIMEN_SOURCE_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_COMMENTS_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_COMMENTS_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_COMMENTS_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_CUSTOM_NAME_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_CUSTOM_NAME_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_CUSTOM_NAME_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_DATE_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_DATE_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_DATE_3 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_GT3_CREATED_IND | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_NAME_1 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_NAME_2 | sp_morbidity_report_datamart_postprocessing | no | no |
| TREATMENT_NAME_3 | sp_morbidity_report_datamart_postprocessing | no | no |

### dbo.MORBIDITY_REPORT_EVENT

Writers:
- `sp_d_morbidity_report_postprocessing` (postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| Condition_Key | sp_d_morbidity_report_postprocessing | no | no |
| HEALTH_CARE_KEY | sp_d_morbidity_report_postprocessing | no | no |
| HSPTL_DISCHARGE_DT_KEY | sp_d_morbidity_report_postprocessing | no | no |
| HSPTL_KEY | sp_d_morbidity_report_postprocessing | no | no |
| ILLNESS_ONSET_DT_KEY | sp_d_morbidity_report_postprocessing | no | no |
| INVESTIGATION_KEY | sp_d_morbidity_report_postprocessing | no | no |
| LDF_GROUP_KEY | sp_d_morbidity_report_postprocessing | no | no |
| Morb_Rpt_Count | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_CREATE_DT_KEY | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_DT_KEY | sp_d_morbidity_report_postprocessing | no | no |
| morb_Rpt_Key | sp_d_morbidity_report_postprocessing | no | no |
| MORB_RPT_SRC_ORG_KEY | sp_d_morbidity_report_postprocessing | no | no |
| Nursing_Home_Key | sp_d_morbidity_report_postprocessing | no | no |
| PATIENT_KEY | sp_d_morbidity_report_postprocessing | no | no |
| PHYSICIAN_KEY | sp_d_morbidity_report_postprocessing | no | no |
| record_status_cd | sp_d_morbidity_report_postprocessing | no | no |
| REPORTER_KEY | sp_d_morbidity_report_postprocessing | no | no |

### dbo.NOTIFICATION

Writers:
- `sp_nrt_notification_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| NOTIFICATION_COMMENTS | sp_nrt_notification_postprocessing | yes | no |
| NOTIFICATION_KEY | sp_nrt_notification_postprocessing | yes | no |
| NOTIFICATION_LAST_CHANGE_TIME | sp_nrt_notification_postprocessing | yes | no |
| NOTIFICATION_LOCAL_ID | sp_nrt_notification_postprocessing | yes | no |
| NOTIFICATION_STATUS | sp_nrt_notification_postprocessing | yes | no |
| NOTIFICATION_SUBMITTED_BY | sp_nrt_notification_postprocessing | yes | no |

### dbo.NOTIFICATION_EVENT

Writers:
- `sp_nrt_notification_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CONDITION_KEY | sp_nrt_notification_postprocessing | yes | no |
| COUNT | sp_nrt_notification_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_nrt_notification_postprocessing | yes | no |
| NOTIFICATION_KEY | sp_nrt_notification_postprocessing | yes | no |
| NOTIFICATION_SENT_DT_KEY | sp_nrt_notification_postprocessing | yes | no |
| NOTIFICATION_SUBMIT_DT_KEY | sp_nrt_notification_postprocessing | yes | no |
| NOTIFICATION_UPD_DT_KEY | sp_nrt_notification_postprocessing | yes | no |
| PATIENT_KEY | sp_nrt_notification_postprocessing | yes | no |

### dbo.ORGANIZATION_LDF_GROUP

Writers:
- `sp_nrt_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| LDF_GROUP_KEY | sp_nrt_ldf_postprocessing | no | no |
| ORGANIZATION_KEY | sp_nrt_ldf_postprocessing | no | no |
| RECORD_STATUS_CD | sp_nrt_ldf_postprocessing | no | no |

### dbo.PATIENT_LDF_GROUP

Writers:
- `sp_nrt_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| LDF_GROUP_KEY | sp_nrt_ldf_postprocessing | no | no |
| PATIENT_KEY | sp_nrt_ldf_postprocessing | no | no |
| RECORD_STATUS_CD | sp_nrt_ldf_postprocessing | no | no |

### dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP

Writers:
- `sp_pertussis_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| PERTUSSIS_SUSPECT_SRC_GRP_KEY | sp_pertussis_case_datamart_postprocessing | no | no |

### dbo.PERTUSSIS_TREATMENT_GROUP

Writers:
- `sp_pertussis_case_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| PERTUSSIS_TREATMENT_GRP_KEY | sp_pertussis_case_datamart_postprocessing | no | no |

### dbo.PROVIDER_LDF_GROUP

Writers:
- `sp_nrt_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| LDF_GROUP_KEY | sp_nrt_ldf_postprocessing | no | no |
| PROVIDER_KEY | sp_nrt_ldf_postprocessing | no | no |
| RECORD_STATUS_CD | sp_nrt_ldf_postprocessing | no | no |

### dbo.RDB_DATE

Writers:
- `sp_get_date_dim` (utility) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CLNDR_MON_IN_YR | sp_get_date_dim | no | no |
| CLNDR_MON_NAME | sp_get_date_dim | no | no |
| CLNDR_QRTR | sp_get_date_dim | no | no |
| CLNDR_YR | sp_get_date_dim | no | no |
| DATE_KEY | sp_get_date_dim | no | no |
| DATE_MM_DD_YYYY | sp_get_date_dim | no | no |
| DAY_NBR_IN_CLNDR_MON | sp_get_date_dim | no | no |
| DAY_NBR_IN_CLNDR_YR | sp_get_date_dim | no | no |
| DAY_OF_WEEK | sp_get_date_dim | no | no |
| WK_NBR_IN_CLNDR_MON | sp_get_date_dim | no | no |
| WK_NBR_IN_CLNDR_YR | sp_get_date_dim | no | no |

### dbo.RESULT_COMMENT_GROUP

Writers:
- `sp_d_labtest_result_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| LAB_TEST_UID | sp_d_labtest_result_postprocessing | yes | no |
| RDB_LAST_REFRESH_TIME | sp_d_labtest_result_postprocessing | yes | no |
| RESULT_COMMENT_GRP_KEY | sp_d_labtest_result_postprocessing | yes | no |

### dbo.SR100

Writers:
- `sp_sr100_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_USER_NAME | sp_sr100_datamart_postprocessing | no | no |
| CONDITION | sp_sr100_datamart_postprocessing | no | no |
| CONDITION_CD | sp_sr100_datamart_postprocessing | no | no |
| COUNTY_CD | sp_sr100_datamart_postprocessing | no | no |
| COUNTY_NAME | sp_sr100_datamart_postprocessing | no | no |
| DATE_ADDED | sp_sr100_datamart_postprocessing | no | no |
| DATE_REPORTED | sp_sr100_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_sr100_datamart_postprocessing | no | no |
| LOCAL_ID | sp_sr100_datamart_postprocessing | no | no |
| MMWRWK | sp_sr100_datamart_postprocessing | no | no |
| MMWRYR | sp_sr100_datamart_postprocessing | no | no |
| MONTH_REPORTED | sp_sr100_datamart_postprocessing | no | no |
| NBR_CASES | sp_sr100_datamart_postprocessing | no | no |
| NOTIF_CREATE_DATE | sp_sr100_datamart_postprocessing | no | no |
| NOTIF_CREATE_MONTH | sp_sr100_datamart_postprocessing | no | no |
| NOTIF_CREATE_YEAR | sp_sr100_datamart_postprocessing | no | no |
| REPORT_COMMENTS | sp_sr100_datamart_postprocessing | no | no |
| RPT_SOURCE | sp_sr100_datamart_postprocessing | no | no |
| RPT_SOURCE_DESC | sp_sr100_datamart_postprocessing | no | no |
| STATE_CD | sp_sr100_datamart_postprocessing | no | no |

### dbo.STD_HIV_DATAMART

Writers:
- `sp_patient_dim_columns_update_to_datamart` (datamart) — ops: UPDATE [guarded]
- `sp_std_hiv_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADI_900_STATUS | sp_std_hiv_datamart_postprocessing | yes | no |
| ADI_900_STATUS_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| ADM_REFERRAL_BASIS_OOJ | sp_std_hiv_datamart_postprocessing | yes | no |
| ADM_RPTNG_CNTY | sp_std_hiv_datamart_postprocessing | yes | no |
| CA_INIT_INTVWR_ASSGN_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| CA_INTERVIEWER_ASSIGN_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| CA_PATIENT_INTV_STATUS | sp_std_hiv_datamart_postprocessing | yes | no |
| CALC_5_YEAR_AGE_GROUP | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| CASE_RPT_MMWR_WK | sp_std_hiv_datamart_postprocessing | yes | no |
| CASE_RPT_MMWR_YR | sp_std_hiv_datamart_postprocessing | yes | no |
| CC_CLOSED_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| CLN_CARE_STATUS_CLOSE_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| CLN_CONDITION_RESISTANT_TO | sp_std_hiv_datamart_postprocessing | yes | no |
| CLN_DT_INIT_HLTH_EXM | sp_std_hiv_datamart_postprocessing | yes | no |
| CLN_NEUROSYPHILLIS_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| CLN_PRE_EXP_PROPHY_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| CLN_PRE_EXP_PROPHY_REFER | sp_std_hiv_datamart_postprocessing | yes | no |
| CLN_SURV_PROVIDER_DIAG_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| CMP_CONJUNCTIVITIS_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| CMP_PID_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| COINFECTION_ID | sp_std_hiv_datamart_postprocessing | yes | no |
| CONDITION_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| CONDITION_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| CONFIRMATION_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| CURR_PROCESS_STATE | sp_std_hiv_datamart_postprocessing | yes | no |
| DETECTION_METHOD_DESC_TXT | sp_std_hiv_datamart_postprocessing | yes | no |
| DIAGNOSIS | sp_std_hiv_datamart_postprocessing | yes | no |
| DIAGNOSIS_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| DIE_FRM_THIS_ILLNESS_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| DISEASE_IMPORTED_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| DISSEMINATED_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| EPI_CNTRY_USUAL_RESID | sp_std_hiv_datamart_postprocessing | yes | no |
| EPI_LINK_ID | sp_std_hiv_datamart_postprocessing | yes | no |
| FACILITY_FLD_FOLLOW_UP_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| FIELD_RECORD_NUMBER | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_ACTUAL_REF_TYPE | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_DISPO_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_DISPOSITION | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_EXAM_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_EXPECTED_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_EXPECTED_IN_IND_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_INIT_ASSGN_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_INTERNET_OUTCOME_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_INVESTIGATOR_ASSGN_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_NOTIFICATION_PLAN | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_OOJ_OUTCOME | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_PROV_DIAGNOSIS_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| FL_FUP_PROV_EXM_REASON | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_900_RESULT | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_900_TEST_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_900_TEST_REFERRAL_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_AV_THERAPY_EVER_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_AV_THERAPY_LAST_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_CA_900_OTH_RSN_NOT_LO | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_CA_900_REASON_NOT_LOC | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_ENROLL_PRTNR_SRVCS_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_KEEP_900_CARE_APPT_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_LAST_900_TEST_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_POST_TEST_900_COUNSELING | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_PREVIOUS_900_TEST_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_REFER_FOR_900_CARE_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_REFER_FOR_900_TEST | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_RST_PROVIDED_900_RSLT_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_SELF_REPORTED_RSLT_900 | sp_std_hiv_datamart_postprocessing | yes | no |
| HIV_STATE_CASE_ID | sp_std_hiv_datamart_postprocessing | yes | no |
| HOSPITAL_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| HSPTLIZD_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| INIT_FUP_CLINIC_CODE | sp_std_hiv_datamart_postprocessing | yes | no |
| INIT_FUP_CLOSED_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| INIT_FUP_INITIAL_FOLL_UP | sp_std_hiv_datamart_postprocessing | yes | no |
| INIT_FUP_INITIAL_FOLL_UP_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| INIT_FUP_INTERNET_FOLL_UP | sp_std_hiv_datamart_postprocessing | yes | no |
| INIT_FUP_INTERNET_FOLL_UP_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| INIT_FUP_NOTIFIABLE | sp_std_hiv_datamart_postprocessing | yes | no |
| INITIATING_AGNCY | sp_std_hiv_datamart_postprocessing | yes | no |
| INV_ASSIGNED_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| INV_CASE_STATUS | sp_std_hiv_datamart_postprocessing | yes | no |
| INV_CLOSE_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| INV_LOCAL_ID | sp_std_hiv_datamart_postprocessing | yes | no |
| INV_RPT_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| INV_START_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATION_DEATH_DATE | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATION_STATUS | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_CLOSED_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_CLOSED_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_CURRENT_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_CURRENT_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_DISP_FL_FUP_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_DISP_FL_FUP_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_FL_FUP_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_FL_FUP_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_INIT_FL_FUP_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_INIT_FL_FUP_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_INIT_INTRVW_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_INIT_INTRVW_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_INITIAL_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_INITIAL_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_INTERVIEW_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_INTERVIEW_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_SUPER_CASE_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_SUPER_CASE_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_SUPER_FL_FUP_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_SUPER_FL_FUP_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_SURV_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| INVESTIGATOR_SURV_QC | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_CURRENTLY_IN_INSTITUTION | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_LIVING_WITH | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_NAME_OF_INSTITUTITION | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_TIME_AT_ADDRESS_NUM | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_TIME_AT_ADDRESS_UNIT | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_TIME_IN_COUNTRY_NUM | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_TIME_IN_COUNTRY_UNIT | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_TIME_IN_STATE_NUM | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_TIME_IN_STATE_UNIT | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_TYPE_OF_INSTITUTITION | sp_std_hiv_datamart_postprocessing | yes | no |
| IPO_TYPE_OF_RESIDENCE | sp_std_hiv_datamart_postprocessing | yes | no |
| IX_DATE_OI | sp_std_hiv_datamart_postprocessing | yes | no |
| JURISDICTION_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| JURISDICTION_NM | sp_std_hiv_datamart_postprocessing | yes | no |
| LAB_HIV_SPECIMEN_COLL_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| LAB_NONTREP_SYPH_RSLT_QNT | sp_std_hiv_datamart_postprocessing | yes | no |
| LAB_NONTREP_SYPH_RSLT_QUA | sp_std_hiv_datamart_postprocessing | yes | no |
| LAB_NONTREP_SYPH_TEST_TYP | sp_std_hiv_datamart_postprocessing | yes | no |
| LAB_SYPHILIS_TST_PS_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| LAB_SYPHILIS_TST_RSLT_PS | sp_std_hiv_datamart_postprocessing | yes | no |
| LAB_TESTS_PERFORMED | sp_std_hiv_datamart_postprocessing | yes | no |
| LAB_TREP_SYPH_RESULT_QUAL | sp_std_hiv_datamart_postprocessing | yes | no |
| LAB_TREP_SYPH_TEST_TYPE | sp_std_hiv_datamart_postprocessing | yes | no |
| MDH_PREV_STD_HIST | sp_std_hiv_datamart_postprocessing | yes | no |
| OOJ_AGENCY_SENT_TO | sp_std_hiv_datamart_postprocessing | yes | no |
| OOJ_DUE_DATE_SENT_TO | sp_std_hiv_datamart_postprocessing | yes | no |
| OOJ_FR_NUMBER_SENT_TO | sp_std_hiv_datamart_postprocessing | yes | no |
| OOJ_INITG_AGNCY_OUTC_DUE_DATE | sp_std_hiv_datamart_postprocessing | yes | no |
| OOJ_INITG_AGNCY_OUTC_SNT_DATE | sp_std_hiv_datamart_postprocessing | yes | no |
| OOJ_INITG_AGNCY_RECD_DATE | sp_std_hiv_datamart_postprocessing | yes | no |
| ORDERING_FACILITY_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| OUTBREAK_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| OUTBREAK_NAME | sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_ADDL_GENDER_INFO | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_AGE_AT_ONSET | sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_AGE_AT_ONSET_UNIT | sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_AGE_REPORTED | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_ALIAS | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_BIRTH_COUNTRY | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_BIRTH_SEX | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_CENSUS_TRACT | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_CITY | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_COUNTRY | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_COUNTY | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_CURR_SEX_UNK_RSN | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_CURRENT_SEX | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_DECEASED_DATE | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_DECEASED_INDICATOR | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_DOB | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_EMAIL | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_ETHNICITY | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_LOCAL_ID | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_MARITAL_STATUS | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_NAME | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_PHONE_CELL | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_PHONE_HOME | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_PHONE_WORK | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_PREFERRED_GENDER | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_PREGNANT_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_RACE | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_SEX | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_STATE | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_STREET_ADDRESS_1 | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_STREET_ADDRESS_2 | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_UNK_ETHNIC_RSN | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PATIENT_ZIP | sp_patient_dim_columns_update_to_datamart, sp_std_hiv_datamart_postprocessing | yes | no |
| PBI_IN_PRENATAL_CARE_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| PBI_PATIENT_PREGNANT_WKS | sp_std_hiv_datamart_postprocessing | yes | no |
| PBI_PREG_AT_EXAM_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| PBI_PREG_AT_EXAM_WKS | sp_std_hiv_datamart_postprocessing | yes | no |
| PBI_PREG_AT_IX_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| PBI_PREG_AT_IX_WKS | sp_std_hiv_datamart_postprocessing | yes | no |
| PBI_PREG_IN_LAST_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| PBI_PREG_OUTCOME | sp_std_hiv_datamart_postprocessing | yes | no |
| PHYSICIAN_FL_FUP_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| PHYSICIAN_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| PROGRAM_AREA_CD | sp_std_hiv_datamart_postprocessing | yes | no |
| PROGRAM_JURISDICTION_OID | sp_std_hiv_datamart_postprocessing | yes | no |
| PROVIDER_REASON_VISIT_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| REFERRAL_BASIS | sp_std_hiv_datamart_postprocessing | yes | no |
| REPORTING_ORG_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| REPORTING_PROV_KEY | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_ELICIT_INTERNET_INFO | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_FIRST_NDLSHARE_EXP_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_FIRST_SEX_EXP_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_LAST_NDLSHARE_EXP_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_LAST_SEX_EXP_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_MET_OP_INTERNET | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_NDLSHARE_EXP_FREQ | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_RELATIONSHIP_TO_OP | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_SEX_EXP_FREQ | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_SPOUSE_OF_OP | sp_std_hiv_datamart_postprocessing | yes | no |
| RPT_SRC_CD_DESC | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_BEEN_INCARCERATD_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_COCAINE_USE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_CRACK_USE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_ED_MEDS_USE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_HEROIN_USE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_INJ_DRUG_USE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_METH_USE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_NITR_POP_USE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_NO_DRUG_USE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_OTHER_DRUG_SPEC | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_OTHER_DRUG_USE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_RISK_FACTORS_ASSESS_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SEX_EXCH_DRGS_MNY_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SEX_INTOXCTED_HGH_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SEX_W_ANON_PTRNR_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SEX_W_FEMALE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SEX_W_KNOWN_IDU_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SEX_W_KNWN_MSM_12M_FML_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SEX_W_MALE_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SEX_W_TRANSGNDR_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SEX_WOUT_CONDOM_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_SHARED_INJ_EQUIP_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| RSK_TARGET_POPULATIONS | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_FEMALE_PRTNRS_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_FEMALE_PRTNRS_12MO_TTL | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_MALE_PRTNRS_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_MALE_PRTNRS_12MO_TOTAL | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_PLACES_TO_HAVE_SEX | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_PLACES_TO_MEET_PARTNER | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_PRTNRS_PRD_FML_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_PRTNRS_PRD_FML_TTL | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_PRTNRS_PRD_MALE_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_PRTNRS_PRD_MALE_TTL | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_PRTNRS_PRD_TRNSGNDR_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_SX_PRTNRS_INTNT_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_TRANSGNDR_PRTNRS_12MO_IND | sp_std_hiv_datamart_postprocessing | yes | no |
| SOC_TRANSGNDR_PRTNRS_12MO_TTL | sp_std_hiv_datamart_postprocessing | yes | no |
| SOURCE_SPREAD | sp_std_hiv_datamart_postprocessing | yes | no |
| STD_PRTNRS_PRD_TRNSGNDR_TTL | sp_std_hiv_datamart_postprocessing | yes | no |
| SURV_CLOSED_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| SURV_INVESTIGATOR_ASSGN_DT | sp_std_hiv_datamart_postprocessing | yes | no |
| SURV_PATIENT_FOLL_UP | sp_std_hiv_datamart_postprocessing | yes | no |
| SURV_PROVIDER_CONTACT | sp_std_hiv_datamart_postprocessing | yes | no |
| SURV_PROVIDER_EXAM_REASON | sp_std_hiv_datamart_postprocessing | yes | no |
| SYM_LATE_CLINICAL_MANIFES | sp_std_hiv_datamart_postprocessing | yes | no |
| SYM_NEUROLOGIC_SIGN_SYM | sp_std_hiv_datamart_postprocessing | yes | no |
| SYM_OCULAR_MANIFESTATIONS | sp_std_hiv_datamart_postprocessing | yes | no |
| SYM_OTIC_MANIFESTATION | sp_std_hiv_datamart_postprocessing | yes | no |
| TRT_TREATMENT_DATE | sp_std_hiv_datamart_postprocessing | yes | no |

### dbo.SUMMARY_CASE_GROUP

Writers:
- `sp_summary_report_case_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| SUMMARY_CASE_SRC_KEY | sp_summary_report_case_postprocessing | yes | no |
| SUMMARY_CASE_SRC_TXT | sp_summary_report_case_postprocessing | yes | no |

### dbo.SUMMARY_REPORT_CASE

Writers:
- `sp_summary_report_case_postprocessing` (postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CONDITION_KEY | sp_summary_report_case_postprocessing | no | no |
| COUNTY_CD | sp_summary_report_case_postprocessing | no | no |
| COUNTY_NAME | sp_summary_report_case_postprocessing | no | no |
| INVESTIGATION_KEY | sp_summary_report_case_postprocessing | no | no |
| LAST_UPDATE_DT_KEY | sp_summary_report_case_postprocessing | no | no |
| LDF_GROUP_KEY | sp_summary_report_case_postprocessing | no | no |
| NOTIFICATION_SEND_DT_KEY | sp_summary_report_case_postprocessing | no | no |
| STATE_CD | sp_summary_report_case_postprocessing | no | no |
| SUM_RPT_CASE_COMMENTS | sp_summary_report_case_postprocessing | no | no |
| SUM_RPT_CASE_COUNT | sp_summary_report_case_postprocessing | no | no |
| SUM_RPT_CASE_STATUS | sp_summary_report_case_postprocessing | no | no |
| SUMMARY_CASE_SRC_KEY | sp_summary_report_case_postprocessing | no | no |

### dbo.TB_DATAMART

Writers:
- `sp_patient_dim_columns_update_to_datamart` (datamart) — ops: UPDATE
- `sp_tb_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADDL_RISK_1 | sp_tb_datamart_postprocessing | no | no |
| ADDL_RISK_2 | sp_tb_datamart_postprocessing | no | no |
| ADDL_RISK_3 | sp_tb_datamart_postprocessing | no | no |
| ADDL_RISK_ALL | sp_tb_datamart_postprocessing | no | no |
| ADDL_RISK_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| AGE_REPORTED | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| AGE_REPORTED_UNIT | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| CALC_10_YEAR_AGE_GROUP | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| CALC_5_YEAR_AGE_GROUP | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| CALC_DISEASE_SITE | sp_tb_datamart_postprocessing | no | no |
| CALC_REPORTED_AGE | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| CASE_STATUS | sp_tb_datamart_postprocessing | no | no |
| CASE_VERIFICATION | sp_tb_datamart_postprocessing | no | no |
| CHEST_XRAY_CAVITY_EVIDENCE | sp_tb_datamart_postprocessing | no | no |
| CHEST_XRAY_MILIARY_EVIDENCE | sp_tb_datamart_postprocessing | no | no |
| CHEST_XRAY_RESULT | sp_tb_datamart_postprocessing | no | no |
| CITY_COUNTY_CASE_NUMBER | sp_tb_datamart_postprocessing | no | no |
| COMMENTS_FOLLOW_UP_1 | sp_tb_datamart_postprocessing | no | no |
| COMMENTS_FOLLOW_UP_2 | sp_tb_datamart_postprocessing | no | no |
| CONFIRMATION_DATE | sp_tb_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_1 | sp_tb_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_2 | sp_tb_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_3 | sp_tb_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_ALL | sp_tb_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| CORRECTIONAL_FACIL_CUSTODY_IND | sp_tb_datamart_postprocessing | no | no |
| CORRECTIONAL_FACIL_RESIDENT | sp_tb_datamart_postprocessing | no | no |
| CORRECTIONAL_FACIL_TY | sp_tb_datamart_postprocessing | no | no |
| COUNT_DATE | sp_tb_datamart_postprocessing | no | no |
| COUNT_STATUS | sp_tb_datamart_postprocessing | no | no |
| COUNTRY_OF_VERIFIED_CASE | sp_tb_datamart_postprocessing | no | no |
| CT_SCAN_CAVITY_EVIDENCE | sp_tb_datamart_postprocessing | no | no |
| CT_SCAN_MILIARY_EVIDENCE | sp_tb_datamart_postprocessing | no | no |
| CT_SCAN_RESULT | sp_tb_datamart_postprocessing | no | no |
| CULT_TISSUE_COLLECT_DATE | sp_tb_datamart_postprocessing | no | no |
| CULT_TISSUE_RESULT | sp_tb_datamart_postprocessing | no | no |
| CULT_TISSUE_RESULT_RPT_DATE | sp_tb_datamart_postprocessing | no | no |
| CULT_TISSUE_RESULT_RPT_LAB_TY | sp_tb_datamart_postprocessing | no | no |
| CULT_TISSUE_SITE | sp_tb_datamart_postprocessing | no | no |
| DATE_ARRIVED_IN_US | sp_tb_datamart_postprocessing | no | no |
| DATE_REPORTED | sp_tb_datamart_postprocessing | no | no |
| DATE_REPORTED_TO_COUNTY | sp_tb_datamart_postprocessing | no | no |
| DATE_SUBMITTED | sp_tb_datamart_postprocessing | no | no |
| DAYCARE | sp_tb_datamart_postprocessing | no | no |
| DETECTION_METHOD | sp_tb_datamart_postprocessing | no | no |
| DIAGNOSIS_DATE | sp_tb_datamart_postprocessing | no | no |
| DIE_FRM_THIS_ILLNESS_IND | sp_tb_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_CITY | sp_tb_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_COUNTRY | sp_tb_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_COUNTY | sp_tb_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_STATE | sp_tb_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_WHERE | sp_tb_datamart_postprocessing | no | no |
| DISEASE_SITE_1 | sp_tb_datamart_postprocessing | no | no |
| DISEASE_SITE_2 | sp_tb_datamart_postprocessing | no | no |
| DISEASE_SITE_3 | sp_tb_datamart_postprocessing | no | no |
| DISEASE_SITE_ALL | sp_tb_datamart_postprocessing | no | no |
| DISEASE_SITE_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| DOT | sp_tb_datamart_postprocessing | no | no |
| DOT_NUMBER_WEEKS | sp_tb_datamart_postprocessing | no | no |
| EXCESS_ALCOHOL_USE_PAST_YEAR | sp_tb_datamart_postprocessing | no | no |
| FINAL_ISOLATE_COLLECT_DATE | sp_tb_datamart_postprocessing | no | no |
| FINAL_ISOLATE_IS_SPUTUM_IND | sp_tb_datamart_postprocessing | no | no |
| FINAL_ISOLATE_NOT_SPUTUM | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_AMIKACIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_CAPREOMYCIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_CIPROFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_CYCLOSERINE | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_ETHAMBUTOL | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_ETHIONAMIDE | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_ISONIAZID | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_KANAMYCIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_LEVOFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_MOXIFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_2 | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_2_IND | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_IND | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_QUINOLONES | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_PA_SALICYLIC_ACI | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_PYRAZINAMIDE | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_RIFABUTIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_RIFAMPIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_RIFAPENTINE | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_STREPTOMYCIN | sp_tb_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_TESTING | sp_tb_datamart_postprocessing | no | no |
| FIRST_ISOLATE_COLLECT_DATE | sp_tb_datamart_postprocessing | no | no |
| FIRST_ISOLATE_IS_SPUTUM_IND | sp_tb_datamart_postprocessing | no | no |
| FIRST_ISOLATE_NOT_SPUTUM | sp_tb_datamart_postprocessing | no | no |
| FOOD_HANDLER | sp_tb_datamart_postprocessing | no | no |
| GENERAL_COMMENTS | sp_tb_datamart_postprocessing | no | no |
| GT_12_REAS_1 | sp_tb_datamart_postprocessing | no | no |
| GT_12_REAS_2 | sp_tb_datamart_postprocessing | no | no |
| GT_12_REAS_3 | sp_tb_datamart_postprocessing | no | no |
| GT_12_REAS_ALL | sp_tb_datamart_postprocessing | no | no |
| GT_12_REAS_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| HC_PROV_TY_1 | sp_tb_datamart_postprocessing | no | no |
| HC_PROV_TY_2 | sp_tb_datamart_postprocessing | no | no |
| HC_PROV_TY_3 | sp_tb_datamart_postprocessing | no | no |
| HC_PROV_TY_ALL | sp_tb_datamart_postprocessing | no | no |
| HC_PROV_TY_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| HOMELESS_IND | sp_tb_datamart_postprocessing | no | no |
| HOSPITAL_NAME | sp_tb_datamart_postprocessing | no | no |
| HOSPITALIZED | sp_tb_datamart_postprocessing | no | no |
| HOSPITALIZED_ADMISSION_DATE | sp_tb_datamart_postprocessing | no | no |
| HOSPITALIZED_DISCHARGE_DATE | sp_tb_datamart_postprocessing | no | no |
| HOSPITALIZED_DURATION_DAYS | sp_tb_datamart_postprocessing | no | no |
| IGRA_COLLECT_DATE | sp_tb_datamart_postprocessing | no | no |
| IGRA_RESULT | sp_tb_datamart_postprocessing | no | no |
| IGRA_TEST_TY | sp_tb_datamart_postprocessing | no | no |
| ILLNESS_DURATION | sp_tb_datamart_postprocessing | no | no |
| ILLNESS_DURATION_UNIT | sp_tb_datamart_postprocessing | no | no |
| ILLNESS_END_DATE | sp_tb_datamart_postprocessing | no | no |
| ILLNESS_ONSET_AGE | sp_tb_datamart_postprocessing | no | no |
| ILLNESS_ONSET_AGE_UNIT | sp_tb_datamart_postprocessing | no | no |
| ILLNESS_ONSET_DATE | sp_tb_datamart_postprocessing | no | no |
| IMMIGRATION_STATUS_AT_US_ENTRY | sp_tb_datamart_postprocessing | no | no |
| INIT_DRUG_REG_CALC | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_AMIKACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_CAPREOMYCIN | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_CIPROFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_CYCLOSERINE | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_ETHAMBUTOL | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_ETHIONAMIDE | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_ISONIAZID | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_KANAMYCIN | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_LEVOFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_MOXIFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_OFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_OTHER_1 | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_OTHER_1_IND | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_OTHER_2 | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_OTHER_2_IND | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_PA_SALICYLIC_ACID | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_PYRAZINAMIDE | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_RIFABUTIN | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_RIFAMPIN | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_RIFAPENTINE | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_START_DATE | sp_tb_datamart_postprocessing | no | no |
| INIT_REGIMEN_STREPTOMYCIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_AMIKACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_CAPREOMYCIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_CIPROFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_CYCLOSERINE | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_ETHAMBUTOL | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_ETHIONAMIDE | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_ISONIAZID | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_KANAMYCIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_LEVOFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_MOXIFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OFLOXACIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_1 | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_1_IND | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_2 | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_2_IND | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_QUNINOLONES | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_PA_SALICYLIC_ACID | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_PYRAZINAMIDE | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_RIFABUTIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_RIFAMPIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_RIFAPENTINE | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_STREPTOMYCIN | sp_tb_datamart_postprocessing | no | no |
| INIT_SUSCEPT_TESTING_DONE | sp_tb_datamart_postprocessing | no | no |
| INJECT_DRUG_USE_PAST_YEAR | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATION_CREATE_DATE | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATION_CREATED_BY | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATION_DEATH_DATE | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATION_LAST_UPDTD_BY | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATION_LAST_UPDTD_DATE | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATION_LOCAL_ID | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATION_START_DATE | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATOR_ASSIGN_DATE | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATOR_FIRST_NAME | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATOR_LAST_NAME | sp_tb_datamart_postprocessing | no | no |
| INVESTIGATOR_PHONE_NUMBER | sp_tb_datamart_postprocessing | no | no |
| ISOLATE_ACCESSION_NUM | sp_tb_datamart_postprocessing | no | no |
| ISOLATE_SUBMITTED_IND | sp_tb_datamart_postprocessing | no | no |
| JURISDICTION_NAME | sp_tb_datamart_postprocessing | no | no |
| LINK_REASON_1 | sp_tb_datamart_postprocessing | no | no |
| LINK_REASON_2 | sp_tb_datamart_postprocessing | no | no |
| LINK_STATE_CASE_NUM_1 | sp_tb_datamart_postprocessing | no | no |
| LINK_STATE_CASE_NUM_2 | sp_tb_datamart_postprocessing | no | no |
| LONGTERM_CARE_FACIL_RESIDENT | sp_tb_datamart_postprocessing | no | no |
| LONGTERM_CARE_FACIL_TY | sp_tb_datamart_postprocessing | no | no |
| MMWR_WEEK | sp_tb_datamart_postprocessing | no | no |
| MMWR_YEAR | sp_tb_datamart_postprocessing | no | no |
| MOVE_CITY | sp_tb_datamart_postprocessing | no | no |
| MOVE_CITY_2 | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTRY_1 | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTRY_2 | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTRY_3 | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTRY_ALL | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTRY_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTY_1 | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTY_2 | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTY_3 | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTY_ALL | sp_tb_datamart_postprocessing | no | no |
| MOVE_CNTY_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| MOVE_STATE_1 | sp_tb_datamart_postprocessing | no | no |
| MOVE_STATE_2 | sp_tb_datamart_postprocessing | no | no |
| MOVE_STATE_3 | sp_tb_datamart_postprocessing | no | no |
| MOVE_STATE_ALL | sp_tb_datamart_postprocessing | no | no |
| MOVE_STATE_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| MOVED_IND | sp_tb_datamart_postprocessing | no | no |
| MOVED_WHERE_1 | sp_tb_datamart_postprocessing | no | no |
| MOVED_WHERE_2 | sp_tb_datamart_postprocessing | no | no |
| MOVED_WHERE_3 | sp_tb_datamart_postprocessing | no | no |
| MOVED_WHERE_ALL | sp_tb_datamart_postprocessing | no | no |
| MOVED_WHERE_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| NAA_COLLECT_DATE | sp_tb_datamart_postprocessing | no | no |
| NAA_RESULT | sp_tb_datamart_postprocessing | no | no |
| NAA_RESULT_RPT_DATE | sp_tb_datamart_postprocessing | no | no |
| NAA_RPT_LAB_TY | sp_tb_datamart_postprocessing | no | no |
| NAA_SPEC_IS_SPUTUM_IND | sp_tb_datamart_postprocessing | no | no |
| NAA_SPEC_NOT_SPUTUM | sp_tb_datamart_postprocessing | no | no |
| NO_CONV_DOC_OTHER_REASON | sp_tb_datamart_postprocessing | no | no |
| NO_CONV_DOC_REASON | sp_tb_datamart_postprocessing | no | no |
| NONINJECT_DRUG_USE_PAST_YEAR | sp_tb_datamart_postprocessing | no | no |
| NOTIFICATION_LOCAL_ID | sp_tb_datamart_postprocessing | no | no |
| NOTIFICATION_SENT_DATE | sp_tb_datamart_postprocessing | no | no |
| NOTIFICATION_STATUS | sp_tb_datamart_postprocessing | no | no |
| NOTIFICATION_SUBMITTER | sp_tb_datamart_postprocessing | no | no |
| OCCUPATION_RISK | sp_tb_datamart_postprocessing | no | no |
| OTHER_TB_RISK_FACTORS | sp_tb_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_1 | sp_tb_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_2 | sp_tb_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_3 | sp_tb_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_ALL | sp_tb_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| OUTBREAK | sp_tb_datamart_postprocessing | no | no |
| OUTBREAK_NAME | sp_tb_datamart_postprocessing | no | no |
| PATIENT_BIRTH_COUNTRY | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_BIRTH_SEX | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_CITY | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_COUNTRY | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_COUNTY | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_CURRENT_SEX | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_DECEASED_DATE | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_DECEASED_INDICATOR | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_DOB | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_ETHNICITY | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_FIRST_NAME | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_GENERAL_COMMENTS | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_LAST_NAME | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_LOCAL_ID | sp_tb_datamart_postprocessing | no | no |
| PATIENT_MARITAL_STATUS | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_MIDDLE_NAME | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_NAME_SUFFIX | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_OUTSIDE_US_GT_2_MONTHS | sp_tb_datamart_postprocessing | no | no |
| PATIENT_PHONE_EXT_HOME | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_PHONE_EXT_WORK | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_PHONE_NUMBER_HOME | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_PHONE_NUMBER_WORK | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_SSN | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_STATE | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_STREET_ADDRESS_1 | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_STREET_ADDRESS_2 | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_WITHIN_CITY_LIMITS | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PATIENT_ZIP | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| PHYSICIAN_FIRST_NAME | sp_tb_datamart_postprocessing | no | no |
| PHYSICIAN_LAST_NAME | sp_tb_datamart_postprocessing | no | no |
| PHYSICIAN_PHONE_NUMBER | sp_tb_datamart_postprocessing | no | no |
| PREGNANT | sp_tb_datamart_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_IND | sp_tb_datamart_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_YEAR | sp_tb_datamart_postprocessing | no | no |
| PRIMARY_GUARD_1_BIRTH_COUNTRY | sp_tb_datamart_postprocessing | no | no |
| PRIMARY_GUARD_2_BIRTH_COUNTRY | sp_tb_datamart_postprocessing | no | no |
| PRIMARY_REASON_EVALUATED | sp_tb_datamart_postprocessing | no | no |
| PROGRAM_AREA_DESCRIPTION | sp_tb_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_tb_datamart_postprocessing | no | no |
| PROVIDER_OVERRIDE_COMMENTS | sp_tb_datamart_postprocessing | no | no |
| RACE_ASIAN_1 | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_ASIAN_2 | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_ASIAN_3 | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_ASIAN_ALL | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_ASIAN_GT3_IND | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_CALC_DETAILS | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_CALCULATED | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_NAT_HI_1 | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_NAT_HI_2 | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_NAT_HI_3 | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_NAT_HI_ALL | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| RACE_NAT_HI_GT3_IND | sp_patient_dim_columns_update_to_datamart, sp_tb_datamart_postprocessing | no | no |
| REPORTER_FIRST_NAME | sp_tb_datamart_postprocessing | no | no |
| REPORTER_LAST_NAME | sp_tb_datamart_postprocessing | no | no |
| REPORTER_PHONE_NUMBER | sp_tb_datamart_postprocessing | no | no |
| REPORTING_SOURCE_NAME | sp_tb_datamart_postprocessing | no | no |
| REPORTING_SOURCE_TYPE | sp_tb_datamart_postprocessing | no | no |
| SMR_EXAM_TY_1 | sp_tb_datamart_postprocessing | no | no |
| SMR_EXAM_TY_2 | sp_tb_datamart_postprocessing | no | no |
| SMR_EXAM_TY_3 | sp_tb_datamart_postprocessing | no | no |
| SMR_EXAM_TY_ALL | sp_tb_datamart_postprocessing | no | no |
| SMR_EXAM_TY_GT3_IND | sp_tb_datamart_postprocessing | no | no |
| SMR_PATH_CYTO_COLLECT_DATE | sp_tb_datamart_postprocessing | no | no |
| SMR_PATH_CYTO_RESULT | sp_tb_datamart_postprocessing | no | no |
| SMR_PATH_CYTO_SITE | sp_tb_datamart_postprocessing | no | no |
| SPUTUM_CULT_COLLECT_DATE | sp_tb_datamart_postprocessing | no | no |
| SPUTUM_CULT_RESULT_RPT_DATE | sp_tb_datamart_postprocessing | no | no |
| SPUTUM_CULT_RPT_LAB_TY | sp_tb_datamart_postprocessing | no | no |
| SPUTUM_CULTURE_CONV_DOCUMENTED | sp_tb_datamart_postprocessing | no | no |
| SPUTUM_CULTURE_RESULT | sp_tb_datamart_postprocessing | no | no |
| SPUTUM_SMEAR_COLLECT_DATE | sp_tb_datamart_postprocessing | no | no |
| SPUTUM_SMEAR_RESULT | sp_tb_datamart_postprocessing | no | no |
| STATE_CASE_NUMBER | sp_tb_datamart_postprocessing | no | no |
| STATUS_AT_DIAGNOSIS | sp_tb_datamart_postprocessing | no | no |
| TB_SPUTUM_CULTURE_NEGATIVE_DAT | sp_tb_datamart_postprocessing | no | no |
| THERAPY_EXTEND_GT_12_OTHER | sp_tb_datamart_postprocessing | no | no |
| THERAPY_STOP_CAUSE_OF_DEATH | sp_tb_datamart_postprocessing | no | no |
| THERAPY_STOP_DATE | sp_tb_datamart_postprocessing | no | no |
| THERAPY_STOP_REASON | sp_tb_datamart_postprocessing | no | no |
| TRANSMISSION_MODE | sp_tb_datamart_postprocessing | no | no |
| TRANSNATIONAL_REFERRAL_IND | sp_tb_datamart_postprocessing | no | no |
| TST_MM_INDURATION | sp_tb_datamart_postprocessing | no | no |
| TST_PLACED_DATE | sp_tb_datamart_postprocessing | no | no |
| TST_RESULT | sp_tb_datamart_postprocessing | no | no |
| US_BORN_IND | sp_tb_datamart_postprocessing | no | no |

### dbo.TB_HIV_DATAMART

Writers:
- `sp_patient_dim_columns_update_to_datamart` (datamart) — ops: UPDATE
- `sp_tb_hiv_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADDL_RISK_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| ADDL_RISK_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| ADDL_RISK_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| ADDL_RISK_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| ADDL_RISK_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| AGE_REPORTED | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| AGE_REPORTED_UNIT | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| CALC_10_YEAR_AGE_GROUP | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| CALC_5_YEAR_AGE_GROUP | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| CALC_DISEASE_SITE | sp_tb_hiv_datamart_postprocessing | no | no |
| CALC_REPORTED_AGE | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| CASE_STATUS | sp_tb_hiv_datamart_postprocessing | no | no |
| CASE_VERIFICATION | sp_tb_hiv_datamart_postprocessing | no | no |
| CHEST_XRAY_CAVITY_EVIDENCE | sp_tb_hiv_datamart_postprocessing | no | no |
| CHEST_XRAY_MILIARY_EVIDENCE | sp_tb_hiv_datamart_postprocessing | no | no |
| CHEST_XRAY_RESULT | sp_tb_hiv_datamart_postprocessing | no | no |
| CITY_COUNTY_CASE_NUMBER | sp_tb_hiv_datamart_postprocessing | no | no |
| COMMENTS_FOLLOW_UP_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| COMMENTS_FOLLOW_UP_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| CONFIRMATION_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| CORRECTIONAL_FACIL_CUSTODY_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| CORRECTIONAL_FACIL_RESIDENT | sp_tb_hiv_datamart_postprocessing | no | no |
| CORRECTIONAL_FACIL_TY | sp_tb_hiv_datamart_postprocessing | no | no |
| COUNT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| COUNT_STATUS | sp_tb_hiv_datamart_postprocessing | no | no |
| COUNTRY_OF_VERIFIED_CASE | sp_tb_hiv_datamart_postprocessing | no | no |
| CT_SCAN_CAVITY_EVIDENCE | sp_tb_hiv_datamart_postprocessing | no | no |
| CT_SCAN_MILIARY_EVIDENCE | sp_tb_hiv_datamart_postprocessing | no | no |
| CT_SCAN_RESULT | sp_tb_hiv_datamart_postprocessing | no | no |
| CULT_TISSUE_COLLECT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| CULT_TISSUE_RESULT | sp_tb_hiv_datamart_postprocessing | no | no |
| CULT_TISSUE_RESULT_RPT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| CULT_TISSUE_RESULT_RPT_LAB_TY | sp_tb_hiv_datamart_postprocessing | no | no |
| CULT_TISSUE_SITE | sp_tb_hiv_datamart_postprocessing | no | no |
| D_TB_HIV_KEY | sp_tb_hiv_datamart_postprocessing | no | no |
| DATE_ARRIVED_IN_US | sp_tb_hiv_datamart_postprocessing | no | no |
| DATE_REPORTED | sp_tb_hiv_datamart_postprocessing | no | no |
| DATE_REPORTED_TO_COUNTY | sp_tb_hiv_datamart_postprocessing | no | no |
| DATE_SUBMITTED | sp_tb_hiv_datamart_postprocessing | no | no |
| DAYCARE | sp_tb_hiv_datamart_postprocessing | no | no |
| DETECTION_METHOD | sp_tb_hiv_datamart_postprocessing | no | no |
| DIAGNOSIS_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| DIE_FRM_THIS_ILLNESS_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_CITY | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_COUNTRY | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_COUNTY | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_STATE | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_WHERE | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_SITE_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_SITE_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_SITE_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_SITE_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| DISEASE_SITE_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| DOT | sp_tb_hiv_datamart_postprocessing | no | no |
| DOT_NUMBER_WEEKS | sp_tb_hiv_datamart_postprocessing | no | no |
| EXCESS_ALCOHOL_USE_PAST_YEAR | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_ISOLATE_COLLECT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_ISOLATE_IS_SPUTUM_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_ISOLATE_NOT_SPUTUM | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_AMIKACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_CAPREOMYCIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_CIPROFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_CYCLOSERINE | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_ETHAMBUTOL | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_ETHIONAMIDE | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_ISONIAZID | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_KANAMYCIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_LEVOFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_MOXIFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_2_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_OTHER_QUINOLONES | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_PA_SALICYLIC_ACI | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_PYRAZINAMIDE | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_RIFABUTIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_RIFAMPIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_RIFAPENTINE | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_STREPTOMYCIN | sp_tb_hiv_datamart_postprocessing | no | no |
| FINAL_SUSCEPT_TESTING | sp_tb_hiv_datamart_postprocessing | no | no |
| FIRST_ISOLATE_COLLECT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| FIRST_ISOLATE_IS_SPUTUM_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| FIRST_ISOLATE_NOT_SPUTUM | sp_tb_hiv_datamart_postprocessing | no | no |
| FOOD_HANDLER | sp_tb_hiv_datamart_postprocessing | no | no |
| GENERAL_COMMENTS | sp_tb_hiv_datamart_postprocessing | no | no |
| GT_12_REAS_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| GT_12_REAS_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| GT_12_REAS_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| GT_12_REAS_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| GT_12_REAS_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| HC_PROV_TY_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| HC_PROV_TY_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| HC_PROV_TY_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| HC_PROV_TY_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| HC_PROV_TY_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| HIV_CITY_CNTY_PATIENT_NUM | sp_tb_hiv_datamart_postprocessing | no | no |
| HIV_STATE_PATIENT_NUM | sp_tb_hiv_datamart_postprocessing | no | no |
| HIV_STATUS | sp_tb_hiv_datamart_postprocessing | no | no |
| HOMELESS_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| HOSPITAL_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| HOSPITALIZED | sp_tb_hiv_datamart_postprocessing | no | no |
| HOSPITALIZED_ADMISSION_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| HOSPITALIZED_DISCHARGE_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| HOSPITALIZED_DURATION_DAYS | sp_tb_hiv_datamart_postprocessing | no | no |
| IGRA_COLLECT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| IGRA_RESULT | sp_tb_hiv_datamart_postprocessing | no | no |
| IGRA_TEST_TY | sp_tb_hiv_datamart_postprocessing | no | no |
| ILLNESS_DURATION | sp_tb_hiv_datamart_postprocessing | no | no |
| ILLNESS_DURATION_UNIT | sp_tb_hiv_datamart_postprocessing | no | no |
| ILLNESS_END_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| ILLNESS_ONSET_AGE | sp_tb_hiv_datamart_postprocessing | no | no |
| ILLNESS_ONSET_AGE_UNIT | sp_tb_hiv_datamart_postprocessing | no | no |
| ILLNESS_ONSET_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| IMMIGRATION_STATUS_AT_US_ENTRY | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_DRUG_REG_CALC | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_AMIKACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_CAPREOMYCIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_CIPROFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_CYCLOSERINE | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_ETHAMBUTOL | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_ETHIONAMIDE | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_ISONIAZID | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_KANAMYCIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_LEVOFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_MOXIFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_OFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_OTHER_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_OTHER_1_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_OTHER_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_OTHER_2_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_PA_SALICYLIC_ACID | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_PYRAZINAMIDE | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_RIFABUTIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_RIFAMPIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_RIFAPENTINE | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_START_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_REGIMEN_STREPTOMYCIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_AMIKACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_CAPREOMYCIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_CIPROFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_CYCLOSERINE | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_ETHAMBUTOL | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_ETHIONAMIDE | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_ISONIAZID | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_KANAMYCIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_LEVOFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_MOXIFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OFLOXACIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_1_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_2_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_OTHER_QUNINOLONES | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_PA_SALICYLIC_ACID | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_PYRAZINAMIDE | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_RIFABUTIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_RIFAMPIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_RIFAPENTINE | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_STREPTOMYCIN | sp_tb_hiv_datamart_postprocessing | no | no |
| INIT_SUSCEPT_TESTING_DONE | sp_tb_hiv_datamart_postprocessing | no | no |
| INJECT_DRUG_USE_PAST_YEAR | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_CREATE_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_CREATED_BY | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_DEATH_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_LAST_UPDTD_BY | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_LAST_UPDTD_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_LOCAL_ID | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_START_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATOR_ASSIGN_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATOR_FIRST_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATOR_LAST_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| INVESTIGATOR_PHONE_NUMBER | sp_tb_hiv_datamart_postprocessing | no | no |
| ISOLATE_ACCESSION_NUM | sp_tb_hiv_datamart_postprocessing | no | no |
| ISOLATE_SUBMITTED_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| JURISDICTION_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| LINK_REASON_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| LINK_REASON_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| LINK_STATE_CASE_NUM_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| LINK_STATE_CASE_NUM_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| LONGTERM_CARE_FACIL_RESIDENT | sp_tb_hiv_datamart_postprocessing | no | no |
| LONGTERM_CARE_FACIL_TY | sp_tb_hiv_datamart_postprocessing | no | no |
| MMWR_WEEK | sp_tb_hiv_datamart_postprocessing | no | no |
| MMWR_YEAR | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CITY | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CITY_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTRY_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTRY_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTRY_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTRY_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTRY_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTY_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTY_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTY_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTY_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_CNTY_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_STATE_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_STATE_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_STATE_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_STATE_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVE_STATE_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVED_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVED_WHERE_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVED_WHERE_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVED_WHERE_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVED_WHERE_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| MOVED_WHERE_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| NAA_COLLECT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| NAA_RESULT | sp_tb_hiv_datamart_postprocessing | no | no |
| NAA_RESULT_RPT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| NAA_RPT_LAB_TY | sp_tb_hiv_datamart_postprocessing | no | no |
| NAA_SPEC_IS_SPUTUM_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| NAA_SPEC_NOT_SPUTUM | sp_tb_hiv_datamart_postprocessing | no | no |
| NO_CONV_DOC_OTHER_REASON | sp_tb_hiv_datamart_postprocessing | no | no |
| NO_CONV_DOC_REASON | sp_tb_hiv_datamart_postprocessing | no | no |
| NONINJECT_DRUG_USE_PAST_YEAR | sp_tb_hiv_datamart_postprocessing | no | no |
| NOTIFICATION_LOCAL_ID | sp_tb_hiv_datamart_postprocessing | no | no |
| NOTIFICATION_SENT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| NOTIFICATION_STATUS | sp_tb_hiv_datamart_postprocessing | no | no |
| NOTIFICATION_SUBMITTER | sp_tb_hiv_datamart_postprocessing | no | no |
| OCCUPATION_RISK | sp_tb_hiv_datamart_postprocessing | no | no |
| OTHER_TB_RISK_FACTORS | sp_tb_hiv_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| OUT_OF_CNTRY_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| OUTBREAK | sp_tb_hiv_datamart_postprocessing | no | no |
| OUTBREAK_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_BIRTH_COUNTRY | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_BIRTH_SEX | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_CITY | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_COUNTRY | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_COUNTY | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_CURRENT_SEX | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_DECEASED_DATE | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_DECEASED_INDICATOR | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_DOB | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_ETHNICITY | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_FIRST_NAME | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_GENERAL_COMMENTS | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_LAST_NAME | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_LOCAL_ID | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_MARITAL_STATUS | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_MIDDLE_NAME | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_NAME_SUFFIX | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_OUTSIDE_US_GT_2_MONTHS | sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_PHONE_EXT_HOME | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_PHONE_EXT_WORK | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_PHONE_NUMBER_HOME | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_PHONE_NUMBER_WORK | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_SSN | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_STATE | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_STREET_ADDRESS_1 | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_STREET_ADDRESS_2 | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_WITHIN_CITY_LIMITS | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PATIENT_ZIP | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| PHYSICIAN_FIRST_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| PHYSICIAN_LAST_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| PHYSICIAN_PHONE_NUMBER | sp_tb_hiv_datamart_postprocessing | no | no |
| PREGNANT | sp_tb_hiv_datamart_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_YEAR | sp_tb_hiv_datamart_postprocessing | no | no |
| PRIMARY_GUARD_1_BIRTH_COUNTRY | sp_tb_hiv_datamart_postprocessing | no | no |
| PRIMARY_GUARD_2_BIRTH_COUNTRY | sp_tb_hiv_datamart_postprocessing | no | no |
| PRIMARY_REASON_EVALUATED | sp_tb_hiv_datamart_postprocessing | no | no |
| PROGRAM_AREA_DESCRIPTION | sp_tb_hiv_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_tb_hiv_datamart_postprocessing | no | no |
| PROVIDER_OVERRIDE_COMMENTS | sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_ASIAN_1 | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_ASIAN_2 | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_ASIAN_3 | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_ASIAN_ALL | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_ASIAN_GT3_IND | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_CALC_DETAILS | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_CALCULATED | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_NAT_HI_1 | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_NAT_HI_2 | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_NAT_HI_3 | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_NAT_HI_ALL | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| RACE_NAT_HI_GT3_IND | sp_patient_dim_columns_update_to_datamart, sp_tb_hiv_datamart_postprocessing | no | no |
| REPORTER_FIRST_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| REPORTER_LAST_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| REPORTER_PHONE_NUMBER | sp_tb_hiv_datamart_postprocessing | no | no |
| REPORTING_SOURCE_NAME | sp_tb_hiv_datamart_postprocessing | no | no |
| REPORTING_SOURCE_TYPE | sp_tb_hiv_datamart_postprocessing | no | no |
| SMR_EXAM_TY_1 | sp_tb_hiv_datamart_postprocessing | no | no |
| SMR_EXAM_TY_2 | sp_tb_hiv_datamart_postprocessing | no | no |
| SMR_EXAM_TY_3 | sp_tb_hiv_datamart_postprocessing | no | no |
| SMR_EXAM_TY_ALL | sp_tb_hiv_datamart_postprocessing | no | no |
| SMR_EXAM_TY_GT3_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| SMR_PATH_CYTO_COLLECT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| SMR_PATH_CYTO_RESULT | sp_tb_hiv_datamart_postprocessing | no | no |
| SMR_PATH_CYTO_SITE | sp_tb_hiv_datamart_postprocessing | no | no |
| SPUTUM_CULT_COLLECT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| SPUTUM_CULT_RESULT_RPT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| SPUTUM_CULT_RPT_LAB_TY | sp_tb_hiv_datamart_postprocessing | no | no |
| SPUTUM_CULTURE_CONV_DOCUMENTED | sp_tb_hiv_datamart_postprocessing | no | no |
| SPUTUM_CULTURE_RESULT | sp_tb_hiv_datamart_postprocessing | no | no |
| SPUTUM_SMEAR_COLLECT_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| SPUTUM_SMEAR_RESULT | sp_tb_hiv_datamart_postprocessing | no | no |
| STATE_CASE_NUMBER | sp_tb_hiv_datamart_postprocessing | no | no |
| STATUS_AT_DIAGNOSIS | sp_tb_hiv_datamart_postprocessing | no | no |
| TB_SPUTUM_CULTURE_NEGATIVE_DAT | sp_tb_hiv_datamart_postprocessing | no | no |
| THERAPY_EXTEND_GT_12_OTHER | sp_tb_hiv_datamart_postprocessing | no | no |
| THERAPY_STOP_CAUSE_OF_DEATH | sp_tb_hiv_datamart_postprocessing | no | no |
| THERAPY_STOP_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| THERAPY_STOP_REASON | sp_tb_hiv_datamart_postprocessing | no | no |
| TRANSMISSION_MODE | sp_tb_hiv_datamart_postprocessing | no | no |
| TRANSNATIONAL_REFERRAL_IND | sp_tb_hiv_datamart_postprocessing | no | no |
| TST_MM_INDURATION | sp_tb_hiv_datamart_postprocessing | no | no |
| TST_PLACED_DATE | sp_tb_hiv_datamart_postprocessing | no | no |
| TST_RESULT | sp_tb_hiv_datamart_postprocessing | no | no |
| US_BORN_IND | sp_tb_hiv_datamart_postprocessing | no | no |

### dbo.TB_PAM_LDF

Writers:
- `sp_nrt_tb_pam_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| END | sp_nrt_tb_pam_ldf_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_nrt_tb_pam_ldf_postprocessing | yes | no |
| TB_PAM_UID | sp_nrt_tb_pam_ldf_postprocessing | yes | no |
| THEN | sp_nrt_tb_pam_ldf_postprocessing | yes | no |

### dbo.TEST_RESULT_GROUPING

Writers:
- `sp_d_labtest_result_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| LAB_TEST_UID | sp_d_labtest_result_postprocessing | yes | no |
| RDB_LAST_REFRESH_TIME | sp_d_labtest_result_postprocessing | yes | no |
| TEST_RESULT_GRP_KEY | sp_d_labtest_result_postprocessing | yes | no |

### dbo.TREATMENT

Writers:
- `sp_nrt_treatment_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CUSTOM_TREATMENT | sp_nrt_treatment_postprocessing | yes | no |
| RECORD_STATUS_CD | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_COMMENTS | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_DOSAGE_STRENGTH | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_DOSAGE_STRENGTH_UNIT | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_DRUG | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_DURATION | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_DURATION_UNIT | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_FREQUENCY | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_KEY | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_LOCAL_ID | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_NM | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_OID | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_ROUTE | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_SHARED_IND | sp_nrt_treatment_postprocessing | yes | no |
| TREATMENT_UID | sp_nrt_treatment_postprocessing | yes | no |

### dbo.TREATMENT_EVENT

Writers:
- `sp_nrt_treatment_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| CONDITION_KEY | sp_nrt_treatment_postprocessing | no | no |
| INVESTIGATION_KEY | sp_nrt_treatment_postprocessing | no | no |
| LDF_GROUP_KEY | sp_nrt_treatment_postprocessing | no | no |
| MORB_RPT_KEY | sp_nrt_treatment_postprocessing | no | no |
| PATIENT_KEY | sp_nrt_treatment_postprocessing | no | no |
| RECORD_STATUS_CD | sp_nrt_treatment_postprocessing | no | no |
| TREATMENT_COUNT | sp_nrt_treatment_postprocessing | no | no |
| TREATMENT_DT_KEY | sp_nrt_treatment_postprocessing | no | no |
| TREATMENT_KEY | sp_nrt_treatment_postprocessing | no | no |
| TREATMENT_PHYSICIAN_KEY | sp_nrt_treatment_postprocessing | no | no |
| TREATMENT_PROVIDING_ORG_KEY | sp_nrt_treatment_postprocessing | no | no |

### dbo.USER_PROFILE

Writers:
- `sp_user_profile_postprocessing` (postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| FIRST_NM | sp_user_profile_postprocessing | yes | no |
| LAST_NM | sp_user_profile_postprocessing | yes | no |
| LAST_UPD_TIME | sp_user_profile_postprocessing | yes | no |
| NEDSS_ENTRY_ID | sp_user_profile_postprocessing | yes | no |
| PROVIDER_KEY | sp_user_profile_postprocessing | yes | no |
| PROVIDER_QUICK_CODE | sp_user_profile_postprocessing | yes | no |
| PROVIDER_UID | sp_user_profile_postprocessing | yes | no |
| USER_NM | sp_user_profile_postprocessing | yes | no |

### dbo.VAR_DATAMART

Writers:
- `sp_patient_dim_columns_update_to_datamart` (datamart) — ops: UPDATE
- `sp_var_datamart_postprocessing` (datamart_postprocessing) — ops: INSERT,UPDATE

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| AGE_REPORTED | sp_var_datamart_postprocessing | no | no |
| AGE_REPORTED_UNIT | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| CASE_STATUS | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS_CEREB_ATAXIA | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS_DEHYDRATION | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS_ENCEPHALITIS | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS_HEMORRHAGIC | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS_OTHER | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS_OTHER_SPECIFY | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS_PNEU_DIAG_BY | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS_PNEUMONIA | sp_var_datamart_postprocessing | no | no |
| COMPLICATIONS_SKIN_INFECTION | sp_var_datamart_postprocessing | no | no |
| CONFIRMATION_DATE | sp_var_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_1 | sp_var_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_2 | sp_var_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_3 | sp_var_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_ALL | sp_var_datamart_postprocessing | no | no |
| CONFIRMATION_METHOD_GT3_IND | sp_var_datamart_postprocessing | no | no |
| CROPS_WAVES | sp_var_datamart_postprocessing | no | no |
| CULTURE_TEST | sp_var_datamart_postprocessing | no | no |
| CULTURE_TEST_DATE | sp_var_datamart_postprocessing | no | no |
| CULTURE_TEST_RESULT | sp_var_datamart_postprocessing | no | no |
| DATE_REPORTED | sp_var_datamart_postprocessing | no | no |
| DATE_REPORTED_TO_COUNTY | sp_var_datamart_postprocessing | no | no |
| DATE_REPORTED_TO_STATE | sp_var_datamart_postprocessing | no | no |
| DAYCARE | sp_var_datamart_postprocessing | no | no |
| DEATH_AUTOPSY | sp_var_datamart_postprocessing | no | no |
| DEATH_CAUSE | sp_var_datamart_postprocessing | no | no |
| DETECTION_METHOD | sp_var_datamart_postprocessing | no | no |
| DFA_TEST | sp_var_datamart_postprocessing | no | no |
| DFA_TEST_DATE | sp_var_datamart_postprocessing | no | no |
| DFA_TEST_RESULT | sp_var_datamart_postprocessing | no | no |
| DIAGNOSIS_DATE | sp_var_datamart_postprocessing | no | no |
| DIE_FRM_THIS_ILLNESS_IND | sp_var_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_CITY | sp_var_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_COUNTRY | sp_var_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_COUNTY | sp_var_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_STATE | sp_var_datamart_postprocessing | no | no |
| DISEASE_ACQUIRED_WHERE | sp_var_datamart_postprocessing | no | no |
| EPI_LINKED | sp_var_datamart_postprocessing | no | no |
| EPI_LINKED_CASE_TYPE | sp_var_datamart_postprocessing | no | no |
| EVENT_DATE | sp_var_datamart_postprocessing | no | no |
| EVENT_DATE_TYPE | sp_var_datamart_postprocessing | no | no |
| FEVER | sp_var_datamart_postprocessing | no | no |
| FEVER_DURATION_DAYS | sp_var_datamart_postprocessing | no | no |
| FEVER_ONSET_DATE | sp_var_datamart_postprocessing | no | no |
| FEVER_TEMPERATURE | sp_var_datamart_postprocessing | no | no |
| FEVER_TEMPERATURE_UNIT | sp_var_datamart_postprocessing | no | no |
| FOOD_HANDLER | sp_var_datamart_postprocessing | no | no |
| GENERAL_COMMENTS | sp_var_datamart_postprocessing | no | no |
| GENOTYPING_SENT_TO_CDC | sp_var_datamart_postprocessing | no | no |
| GENOTYPING_SENT_TO_CDC_DATE | sp_var_datamart_postprocessing | no | no |
| HEALTHCARE_WORKER | sp_var_datamart_postprocessing | no | no |
| HEMORRHAGIC | sp_var_datamart_postprocessing | no | no |
| HOSPITAL_NAME | sp_var_datamart_postprocessing | no | no |
| HOSPITALIZED | sp_var_datamart_postprocessing | no | no |
| HOSPITALIZED_ADMISSION_DATE | sp_var_datamart_postprocessing | no | no |
| HOSPITALIZED_DISCHARGE_DATE | sp_var_datamart_postprocessing | no | no |
| HOSPITALIZED_DURATION_DAYS | sp_var_datamart_postprocessing | no | no |
| IGG_TEST | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_ACUTE_DATE | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_ACUTE_RESULT | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_ACUTE_VALUE | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_CONVALESCENT_DATE | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_CONVALESCENT_RESULT | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_CONVALESCENT_VALUE | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_GP_ELISA_MFGR | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_OTHER | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_TYPE | sp_var_datamart_postprocessing | no | no |
| IGG_TEST_WHOLE_CELL_MFGR | sp_var_datamart_postprocessing | no | no |
| IGM_TEST | sp_var_datamart_postprocessing | no | no |
| IGM_TEST_DATE | sp_var_datamart_postprocessing | no | no |
| IGM_TEST_RESULT | sp_var_datamart_postprocessing | no | no |
| IGM_TEST_RESULT_VALUE | sp_var_datamart_postprocessing | no | no |
| IGM_TEST_TYPE | sp_var_datamart_postprocessing | no | no |
| IGM_TEST_TYPE_OTHER | sp_var_datamart_postprocessing | no | no |
| ILLNESS_DURATION | sp_var_datamart_postprocessing | no | no |
| ILLNESS_DURATION_UNIT | sp_var_datamart_postprocessing | no | no |
| ILLNESS_END_DATE | sp_var_datamart_postprocessing | no | no |
| ILLNESS_ONSET_AGE | sp_var_datamart_postprocessing | no | no |
| ILLNESS_ONSET_AGE_UNIT | sp_var_datamart_postprocessing | no | no |
| ILLNESS_ONSET_DATE | sp_var_datamart_postprocessing | no | no |
| IMMUNOCOMPROMISED | sp_var_datamart_postprocessing | no | no |
| IMMUNOCOMPROMISED_CONDITION | sp_var_datamart_postprocessing | no | no |
| INVESTIGATION_CREATE_DATE | sp_var_datamart_postprocessing | no | no |
| INVESTIGATION_CREATED_BY | sp_var_datamart_postprocessing | no | no |
| INVESTIGATION_DEATH_DATE | sp_var_datamart_postprocessing | no | no |
| INVESTIGATION_KEY | sp_var_datamart_postprocessing | no | no |
| INVESTIGATION_LAST_UPDTD_BY | sp_var_datamart_postprocessing | no | no |
| INVESTIGATION_LAST_UPDTD_DATE | sp_var_datamart_postprocessing | no | no |
| INVESTIGATION_LOCAL_ID | sp_var_datamart_postprocessing | no | no |
| INVESTIGATION_START_DATE | sp_var_datamart_postprocessing | no | no |
| INVESTIGATION_STATUS | sp_var_datamart_postprocessing | no | no |
| INVESTIGATOR_ASSIGN_DATE | sp_var_datamart_postprocessing | no | no |
| INVESTIGATOR_FIRST_NAME | sp_var_datamart_postprocessing | no | no |
| INVESTIGATOR_LAST_NAME | sp_var_datamart_postprocessing | no | no |
| INVESTIGATOR_PHONE_NUMBER | sp_var_datamart_postprocessing | no | no |
| ITCHY | sp_var_datamart_postprocessing | no | no |
| JURISDICTION_NAME | sp_var_datamart_postprocessing | no | no |
| LAB_TESTING | sp_var_datamart_postprocessing | no | no |
| LAB_TESTING_OTHER | sp_var_datamart_postprocessing | no | no |
| LAB_TESTING_OTHER_DATE | sp_var_datamart_postprocessing | no | no |
| LAB_TESTING_OTHER_RESULT | sp_var_datamart_postprocessing | no | no |
| LAB_TESTING_OTHER_RESULT_VALUE | sp_var_datamart_postprocessing | no | no |
| LAB_TESTING_OTHER_SPECIFY | sp_var_datamart_postprocessing | no | no |
| LESIONS_TOTAL | sp_var_datamart_postprocessing | no | no |
| LESIONS_TOTAL_LT50 | sp_var_datamart_postprocessing | no | no |
| MACULAR_PAPULAR | sp_var_datamart_postprocessing | no | no |
| MACULES | sp_var_datamart_postprocessing | no | no |
| MACULES_NUMBER | sp_var_datamart_postprocessing | no | no |
| MEDICATION_NAME | sp_var_datamart_postprocessing | no | no |
| MEDICATION_NAME_OTHER | sp_var_datamart_postprocessing | no | no |
| MEDICATION_START_DATE | sp_var_datamart_postprocessing | no | no |
| MEDICATION_STOP_DATE | sp_var_datamart_postprocessing | no | no |
| MMWR_WEEK | sp_var_datamart_postprocessing | no | no |
| MMWR_YEAR | sp_var_datamart_postprocessing | no | no |
| NOTIFICATION_LOCAL_ID | sp_var_datamart_postprocessing | no | no |
| NOTIFICATION_SENT_DATE | sp_var_datamart_postprocessing | no | no |
| NOTIFICATION_STATUS | sp_var_datamart_postprocessing | no | no |
| NOTIFICATION_SUBMITTER | sp_var_datamart_postprocessing | no | no |
| OUTBREAK | sp_var_datamart_postprocessing | no | no |
| OUTBREAK_NAME | sp_var_datamart_postprocessing | no | no |
| PAPULES | sp_var_datamart_postprocessing | no | no |
| PAPULES_NUMBER | sp_var_datamart_postprocessing | no | no |
| PATIENT_AGE_REPORTED | sp_patient_dim_columns_update_to_datamart | no | no |
| PATIENT_BIRTH_COUNTRY | sp_var_datamart_postprocessing | no | no |
| PATIENT_CITY | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_COUNTRY | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_COUNTY | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_CURRENT_SEX | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_DECEASED_DATE | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_DECEASED_INDICATOR | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_DOB | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_ETHNICITY | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_FIRST_NAME | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_GENERAL_COMMENTS | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_LAST_NAME | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_LOCAL_ID | sp_var_datamart_postprocessing | no | no |
| PATIENT_MARITAL_STATUS | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_MIDDLE_NAME | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_NAME_SUFFIX | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_PHONE_EXT_HOME | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_PHONE_EXT_WORK | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_PHONE_NUMBER_HOME | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_PHONE_NUMBER_WORK | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_SSN | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_STATE | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_STREET_ADDRESS_1 | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_STREET_ADDRESS_2 | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PATIENT_VISIT_HC_PROVIDER | sp_var_datamart_postprocessing | no | no |
| PATIENT_ZIP | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| PCR_TEST | sp_var_datamart_postprocessing | no | no |
| PCR_TEST_DATE | sp_var_datamart_postprocessing | no | no |
| PCR_TEST_RESULT | sp_var_datamart_postprocessing | no | no |
| PCR_TEST_RESULT_OTHER | sp_var_datamart_postprocessing | no | no |
| PCR_TEST_SOURCE_1 | sp_var_datamart_postprocessing | no | no |
| PCR_TEST_SOURCE_2 | sp_var_datamart_postprocessing | no | no |
| PCR_TEST_SOURCE_3 | sp_var_datamart_postprocessing | no | no |
| PCR_TEST_SOURCE_ALL | sp_var_datamart_postprocessing | no | no |
| PCR_TEST_SOURCE_GT3_IND | sp_var_datamart_postprocessing | no | no |
| PCR_TEST_SOURCE_OTHER | sp_var_datamart_postprocessing | no | no |
| PHYSICIAN_FIRST_NAME | sp_var_datamart_postprocessing | no | no |
| PHYSICIAN_LAST_NAME | sp_var_datamart_postprocessing | no | no |
| PHYSICIAN_PHONE_NUMBER | sp_var_datamart_postprocessing | no | no |
| PREGNANT | sp_var_datamart_postprocessing | no | no |
| PREGNANT_TRIMESTER | sp_var_datamart_postprocessing | no | no |
| PREGNANT_WEEKS | sp_var_datamart_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS | sp_var_datamart_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_AGE | sp_var_datamart_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_AGE_UNIT | sp_var_datamart_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_BY | sp_var_datamart_postprocessing | no | no |
| PREVIOUS_DIAGNOSIS_BY_OTHER | sp_var_datamart_postprocessing | no | no |
| PROGRAM_AREA_DESCRIPTION | sp_var_datamart_postprocessing | no | no |
| PROGRAM_JURISDICTION_OID | sp_var_datamart_postprocessing | no | no |
| RACE_CALC_DETAILS | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| RACE_CALCULATED | sp_patient_dim_columns_update_to_datamart, sp_var_datamart_postprocessing | no | no |
| RASH_CRUST | sp_var_datamart_postprocessing | no | no |
| RASH_CRUSTED_DAYS | sp_var_datamart_postprocessing | no | no |
| RASH_DURATION_DAYS | sp_var_datamart_postprocessing | no | no |
| RASH_LOCATION | sp_var_datamart_postprocessing | no | no |
| RASH_LOCATION_DERMATOME | sp_var_datamart_postprocessing | no | no |
| RASH_LOCATION_GENERAL_1 | sp_var_datamart_postprocessing | no | no |
| RASH_LOCATION_GENERAL_2 | sp_var_datamart_postprocessing | no | no |
| RASH_LOCATION_GENERAL_3 | sp_var_datamart_postprocessing | no | no |
| RASH_LOCATION_GENERAL_ALL | sp_var_datamart_postprocessing | no | no |
| RASH_LOCATION_GENERAL_GT3_IND | sp_var_datamart_postprocessing | no | no |
| RASH_LOCATION_OTHER | sp_var_datamart_postprocessing | no | no |
| RASH_ONSET_DATE | sp_var_datamart_postprocessing | no | no |
| REPORTER_FIRST_NAME | sp_var_datamart_postprocessing | no | no |
| REPORTER_LAST_NAME | sp_var_datamart_postprocessing | no | no |
| REPORTER_PHONE_NUMBER | sp_var_datamart_postprocessing | no | no |
| REPORTING_SOURCE_NAME | sp_var_datamart_postprocessing | no | no |
| REPORTING_SOURCE_TYPE | sp_var_datamart_postprocessing | no | no |
| SCABS | sp_var_datamart_postprocessing | no | no |
| SEROLOGY_TEST | sp_var_datamart_postprocessing | no | no |
| STATE_CASE_NUMBER | sp_var_datamart_postprocessing | no | no |
| STRAIN_IDENTIFICATION_SENT | sp_var_datamart_postprocessing | no | no |
| STRAIN_TYPE | sp_var_datamart_postprocessing | no | no |
| TRANSMISSION_MODE | sp_var_datamart_postprocessing | no | no |
| TRANSMISSION_SETTING | sp_var_datamart_postprocessing | no | no |
| TRANSMISSION_SETTING_OTHER | sp_var_datamart_postprocessing | no | no |
| TREATED | sp_var_datamart_postprocessing | no | no |
| VACCINE_DATE_1 | sp_var_datamart_postprocessing | no | no |
| VACCINE_DATE_2 | sp_var_datamart_postprocessing | no | no |
| VACCINE_DATE_3 | sp_var_datamart_postprocessing | no | no |
| VACCINE_DATE_4 | sp_var_datamart_postprocessing | no | no |
| VACCINE_DATE_5 | sp_var_datamart_postprocessing | no | no |
| VACCINE_LOT_1 | sp_var_datamart_postprocessing | no | no |
| VACCINE_LOT_2 | sp_var_datamart_postprocessing | no | no |
| VACCINE_LOT_3 | sp_var_datamart_postprocessing | no | no |
| VACCINE_LOT_4 | sp_var_datamart_postprocessing | no | no |
| VACCINE_LOT_5 | sp_var_datamart_postprocessing | no | no |
| VACCINE_MANUFACTURER_1 | sp_var_datamart_postprocessing | no | no |
| VACCINE_MANUFACTURER_2 | sp_var_datamart_postprocessing | no | no |
| VACCINE_MANUFACTURER_3 | sp_var_datamart_postprocessing | no | no |
| VACCINE_MANUFACTURER_4 | sp_var_datamart_postprocessing | no | no |
| VACCINE_MANUFACTURER_5 | sp_var_datamart_postprocessing | no | no |
| VACCINE_TYPE_1 | sp_var_datamart_postprocessing | no | no |
| VACCINE_TYPE_2 | sp_var_datamart_postprocessing | no | no |
| VACCINE_TYPE_3 | sp_var_datamart_postprocessing | no | no |
| VACCINE_TYPE_4 | sp_var_datamart_postprocessing | no | no |
| VACCINE_TYPE_5 | sp_var_datamart_postprocessing | no | no |
| VARICELLA_NO_2NDVACCINE_OTHER | sp_var_datamart_postprocessing | no | no |
| VARICELLA_NO_2NDVACCINE_REASON | sp_var_datamart_postprocessing | no | no |
| VARICELLA_NO_VACCINE_OTHER | sp_var_datamart_postprocessing | no | no |
| VARICELLA_NO_VACCINE_REASON | sp_var_datamart_postprocessing | no | no |
| VARICELLA_VACCINE | sp_var_datamart_postprocessing | no | no |
| VARICELLA_VACCINE_DOSES_NUMBER | sp_var_datamart_postprocessing | no | no |
| VESICLES | sp_var_datamart_postprocessing | no | no |
| VESICLES_NUMBER | sp_var_datamart_postprocessing | no | no |
| VESICULAR | sp_var_datamart_postprocessing | no | no |
| WITHIN_CITY_LIMITS | sp_patient_dim_columns_update_to_datamart | no | no |

### dbo.VAR_PAM_LDF

Writers:
- `sp_nrt_var_pam_ldf_postprocessing` (nrt_postprocessing) — ops: INSERT,UPDATE [guarded]

| Column | Writer SP(s) | Guarded | Dynamic |
| ------ | ------------ | ------- | ------- |
| ADD_TIME | sp_nrt_var_pam_ldf_postprocessing | yes | no |
| END | sp_nrt_var_pam_ldf_postprocessing | yes | no |
| INVESTIGATION_KEY | sp_nrt_var_pam_ldf_postprocessing | yes | no |
| THEN | sp_nrt_var_pam_ldf_postprocessing | yes | no |
| VAR_PAM_UID | sp_nrt_var_pam_ldf_postprocessing | yes | no |

## Dynamic-SQL targets (table name resolved at runtime)

These writes target a table whose name is concatenated into the SQL string
at runtime (typically a parameter such as `@tgt_table_nm`). The actual
RDB_MODERN table is determined by the caller of the SP and / or the
`@tgt_table_nm` value picked up from `nrt_datamart_metadata` or similar.
Column lists are not statically extractable from the SP body alone — they
are also assembled at runtime from `nrt_dyn_dm_column_metadata`,
page-builder metadata, or `STRING_AGG` over a metadata table.

`<dynamic:alias_*>` entries are dynamic-SQL writes that addressed an alias
(`tgt`, `TBL`, `tDO`, `aoe`) inside a `SET @sql = '...'` literal; the alias
is bound at exec time to whatever table the `FROM ... AS alias` clause
attaches.

| Placeholder | Writer SP(s) |
| ----------- | ------------ |
| `<dynamic:@LOOKUP_TABLE_INC_TABLE_NAME>` | sp_l_pagebuilder_postprocessing |
| `<dynamic:@OUTPUT_TABLE>` | sp_merge_tables |
| `<dynamic:@am_tgt_table_nm>` | sp_bmird_case_datamart_postprocessing |
| `<dynamic:@multival_tgt_table_nm>` | sp_bmird_case_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing |
| `<dynamic:@prt_src_table_nm>` | sp_pertussis_case_datamart_postprocessing |
| `<dynamic:@prt_treatment_table_nm>` | sp_pertussis_case_datamart_postprocessing |
| `<dynamic:@rdb_table_name>` | sp_d_pagebuilder_postprocessing |
| `<dynamic:@target_table_name>` | sp_execute_ldf_generic |
| `<dynamic:@tgt_table_nm>` | sp_aggregate_report_datamart_postprocessing, sp_bmird_case_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_generic_case_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_pertussis_case_datamart_postprocessing, sp_rubella_case_datamart_postprocessing |
| `<dynamic:@tmp_Morbidity_Report>` | sp_d_morbidity_report_postprocessing |
| `<dynamic:@tmp_id_assignment>` | sp_d_morbidity_report_postprocessing |
| `<dynamic:@tmp_morb_Rpt_User_Comment>` | sp_d_morbidity_report_postprocessing |
| `<dynamic:alias_TBL>` | sp_execute_ldf_generic |
| `<dynamic:alias_tDO>` | sp_dyn_dm_org_data_postprocessing, sp_dyn_dm_provider_data_postprocessing |
| `<dynamic:alias_tgt>` | sp_aggregate_report_datamart_postprocessing, sp_bmird_case_datamart_postprocessing, sp_crs_case_datamart_postprocessing, sp_dyn_dm_createdm_postprocessing, sp_dyn_dm_dimension_update, sp_generic_case_datamart_postprocessing, sp_hepatitis_case_datamart_postprocessing, sp_measles_case_datamart_postprocessing, sp_pertussis_case_datamart_postprocessing, sp_rubella_case_datamart_postprocessing |

## Intermediate / staging targets (not in scope)

These are RTR-side staging tables: `nrt_*` (populated by `_event` SPs and
consumed by `_postprocessing` SPs), `nrt_*_key` lookup tables (populated by
postprocessing SPs but RTR-internal — not RDB_MODERN payload), `#temp`
tables, `@table_var` table-variables, and a few SP-internal `tmp_*`
working tables. They are listed for cross-reference but are not part of
the comparison scope; downstream agents should treat them as opaque
pipeline plumbing.

Note: `nrt_*_key` tables (e.g., `nrt_patient_key`, `nrt_organization_key`,
`nrt_disease_site_key`) are populated by postprocessing SPs as a side
effect of building dimensional surrogate keys. They are RTR's own data and
are not what we are comparing against MasterETL output, so they are listed
here rather than under `Per-table breakdown`.

| Table | Writer SP(s) |
| ----- | ------------ |
| `dbo.#CODED_TABLE_CAT_INV` | sp_s_pagebuilder_postprocessing |
| `dbo.#coded_table_INV` | sp_s_pagebuilder_postprocessing |
| `dbo.#CODED_TABLE_MERGED_INV` | sp_s_pagebuilder_postprocessing |
| `dbo.#CODED_TABLE_OTH_REPT` | sp_sld_investigation_repeat_postprocessing |
| `dbo.#CODED_TABLE_OTHER_INV` | sp_s_pagebuilder_postprocessing |
| `dbo.#CODED_TABLE_SNTEMP_INV` | sp_s_pagebuilder_postprocessing |
| `dbo.#CODED_TABLE_SNTEMP_REPT` | sp_sld_investigation_repeat_postprocessing |
| `dbo.#CODED_TABLE_SNTEMP_TRANS_A_INV` | sp_s_pagebuilder_postprocessing |
| `dbo.#CODED_TABLE_SNTEMP_TRANS_A_REPT` | sp_sld_investigation_repeat_postprocessing |
| `dbo.#CODED_TABLE_SNTEMP_TRANS_CODE_INV` | sp_s_pagebuilder_postprocessing |
| `dbo.#CODED_TABLE_SNTEMP_TRANS_CODE_REPT` | sp_sld_investigation_repeat_postprocessing |
| `dbo.#coded_table_TEMP_REPT` | sp_sld_investigation_repeat_postprocessing |
| `dbo.#covid_lab_aoe_data` | sp_covid_lab_datamart_postprocessing |
| `dbo.#COVID_LAB_AOE_DATA` | sp_covid_lab_datamart_postprocessing |
| `dbo.#D_TB_PAM_E` | sp_nrt_d_tb_pam_postprocessing |
| `dbo.#DATE_DATA_INV` | sp_s_pagebuilder_postprocessing |
| `dbo.#DYN_DM_DIMENSION_UPDATE_DATA` | sp_dyn_dm_dimension_update |
| `dbo.#L_TB_PAM_BASE_NEW` | sp_nrt_d_tb_pam_postprocessing |
| `dbo.#missed_cols` | sp_alter_datamart_schema_postprocessing |
| `dbo.#NUMERIC_BASE_DATA_INV_CAT` | sp_s_pagebuilder_postprocessing |
| `dbo.#NUMERIC_DATA1_REPT` | sp_sld_investigation_repeat_postprocessing |
| `dbo.#NUMERIC_DATA2_REPT` | sp_sld_investigation_repeat_postprocessing |
| `dbo.#NUMERIC_DATA_2_INV_CAT` | sp_s_pagebuilder_postprocessing |
| `dbo.#NUMERIC_DATA_TRANS_INV_CAT` | sp_s_pagebuilder_postprocessing |
| `dbo.#NUMERIC_DATA_TRANS_REPT` | sp_sld_investigation_repeat_postprocessing |
| `dbo.#PAGE_DATE_TABLE_INV` | sp_s_pagebuilder_postprocessing |
| `dbo.#PAGE_DATE_TABLE_REPT` | sp_sld_investigation_repeat_postprocessing |
| `dbo.#PHC_UIDS` | sp_l_pagebuilder_postprocessing |
| `dbo.#temp_inv_table` | sp_nrt_investigation_postprocessing |
| `dbo.#TEMP_MIN_MAX_NOTIFICATION` | sp_public_health_case_fact_datamart_event |
| `dbo.#TEMP_PHC_FACT` | sp_public_health_case_fact_datamart_event |
| `dbo.#TEMP_PHCINFO1` | sp_public_health_case_fact_datamart_event |
| `dbo.#TEMP_PHCPATIENTINFO` | sp_public_health_case_fact_datamart_event |
| `dbo.#TEMP_PHCPERSONRACE` | sp_public_health_case_fact_datamart_event |
| `dbo.#Temp_Query_Table` | sp_d_pagebuilder_postprocessing |
| `dbo.#temp_race_table` | sp_patient_event |
| `dbo.#TMP_AM_GRP` | sp_bmird_case_datamart_postprocessing |
| `dbo.#TMP_CASE_LAB_DATAMART_MODIFIED` | sp_inv_summary_datamart_postprocessing |
| `dbo.#TMP_CLDM_CASE_LAB_DATAMART_FINAL` | sp_case_lab_datamart_postprocessing |
| `dbo.#TMP_CLDM_GEN_PATCOMPL_INV_PROVIDER` | sp_case_lab_datamart_postprocessing |
| `dbo.#TMP_CLDM_GEN_PATIENT_ADD` | sp_case_lab_datamart_postprocessing |
| `dbo.#tmp_DynDm_D_INV_METADATA` | sp_dyn_dm_page_builder_d_inv_postprocessing |
| `dbo.#tmp_DynDm_D_INV_REPEAT_METADATA` | sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing |
| `dbo.#tmp_DynDm_fixcols` | sp_dyn_dm_main_postprocessing |
| `dbo.#tmp_DynDm_METADATA` | sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing |
| `dbo.#tmp_DynDM_Metadata` | sp_dyn_dm_repeatdate_postprocessing |
| `dbo.#tmp_DynDm_METADATA_OUT_final` | sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing |
| `dbo.#tmp_DynDm_OrgPart_Table_temp` | sp_dyn_dm_org_data_postprocessing |
| `dbo.#tmp_DynDm_ProvPart_Table_temp` | sp_dyn_dm_provider_data_postprocessing |
| `dbo.#tmp_DynDM_REPEAT_BLOCK_OUT` | sp_dyn_dm_repeatdate_postprocessing |
| `dbo.#tmp_DynDm_REPEAT_BLOCK_OUT_ALL` | sp_dyn_dm_repeatnumeric_postprocessing, sp_dyn_dm_repeatvarch_postprocessing |
| `dbo.#tmp_DynDM_REPEAT_BLOCK_OUT_ALL` | sp_dyn_dm_repeatdate_postprocessing |
| `dbo.#tmp_DynDM_REPEAT_BLOCK_OUT_BASE_max_1` | sp_dyn_dm_repeatdate_postprocessing |
| `dbo.#TMP_Event` | sp_hepatitis_datamart_postprocessing |
| `dbo.#TMP_EVENT_METRIC` | sp_event_metric_datamart_postprocessing |
| `dbo.#TMP_HEPATITIS_CASE_BASE` | sp_hepatitis_datamart_postprocessing |
| `dbo.#tmp_id_assignment` | sp_d_morbidity_report_postprocessing |
| `dbo.#TMP_Lab_Result_Val` | sp_d_labtest_result_postprocessing |
| `dbo.#TMP_lab_test_result1` | sp_d_labtest_result_postprocessing |
| `dbo.#TMP_Lab_Test_Result3` | sp_d_labtest_result_postprocessing |
| `dbo.#TMP_LABTEST_ORDER1` | sp_lab100_datamart_postprocessing |
| `dbo.#TMP_MIN_MAX_NOTIFICATION` | sp_public_health_case_fact_datamart_update |
| `dbo.#tmp_morb_root` | sp_d_morbidity_report_postprocessing |
| `dbo.#TMP_MV_GRP` | sp_bmird_case_datamart_postprocessing |
| `dbo.#TMP_New_Lab_Result_Comment` | sp_d_labtest_result_postprocessing |
| `dbo.#TMP_New_Lab_Result_Comment_FINAL` | sp_d_labtest_result_postprocessing |
| `dbo.#TMP_PATIENT_LOCATION_KEYS_INIT` | sp_inv_summary_datamart_postprocessing |
| `dbo.#TMP_PERSON_ORDER_PROVIDER` | sp_lab100_datamart_postprocessing |
| `dbo.#tmp_Result_Comment_Group` | sp_d_labtest_result_postprocessing |
| `dbo.#tmp_RESULTED_TEST_DETAILS_final` | sp_lab101_datamart_postprocessing |
| `dbo.#TMP_S_PERSON_AMER_INDIAN_RACE` | sp_patient_race_event |
| `dbo.#TMP_S_PERSON_ASIAN_RACE` | sp_patient_race_event |
| `dbo.#TMP_S_PERSON_BLACK_RACE` | sp_patient_race_event |
| `dbo.#TMP_S_PERSON_HAWAIIAN_RACE` | sp_patient_race_event |
| `dbo.#tmp_s_person_race_out` | sp_patient_race_event |
| `dbo.#TMP_S_PERSON_ROOT_RACE` | sp_patient_race_event |
| `dbo.#TMP_S_PERSON_WHITE_RACE` | sp_patient_race_event |
| `dbo.#TMP_SRC_GRP` | sp_pertussis_case_datamart_postprocessing |
| `dbo.#TMP_TREATMENT_GRP` | sp_pertussis_case_datamart_postprocessing |
| `dbo.#TMP_VAC_REPEAT_OUT_DATE` | sp_hepatitis_datamart_postprocessing |
| `dbo.#TMP_VAC_REPEAT_OUT_DATE_Pivot` | sp_hepatitis_datamart_postprocessing |
| `dbo.#TMP_VAC_REPEAT_OUT_FINAL1` | sp_hepatitis_datamart_postprocessing |
| `dbo.#TMP_VAC_REPEAT_OUT_NUM` | sp_hepatitis_datamart_postprocessing |
| `dbo.#TMP_VAC_REPEAT_OUT_NUM_Pivot` | sp_hepatitis_datamart_postprocessing |
| `dbo.@Table` | sp_covid_case_datamart_postprocessing |
| `dbo.@Table2` | sp_covid_case_datamart_postprocessing |
| `dbo.@Table3` | sp_covid_case_datamart_postprocessing |
| `dbo.@Table4` | sp_covid_case_datamart_postprocessing |
| `dbo.@Table5` | sp_covid_case_datamart_postprocessing |
| `dbo.@Temp_Query_Table` | sp_covid_lab_datamart_postprocessing, sp_sld_investigation_repeat_postprocessing |
| `dbo.nrt_addl_risk_group_key` | sp_nrt_d_addl_risk_postprocessing |
| `dbo.nrt_addl_risk_key` | sp_nrt_d_addl_risk_postprocessing |
| `dbo.nrt_antimicrobial_group_key` | sp_bmird_case_datamart_postprocessing |
| `dbo.nrt_antimicrobial_key` | sp_bmird_case_datamart_postprocessing |
| `dbo.nrt_backfill` | sp_nrt_backfill_postprocessing |
| `dbo.nrt_bmird_multi_val_group_key` | sp_bmird_case_datamart_postprocessing |
| `dbo.nrt_bmird_multi_val_key` | sp_bmird_case_datamart_postprocessing |
| `dbo.nrt_case_management_key` | sp_nrt_case_management_postprocessing |
| `dbo.nrt_condition_key` | sp_nrt_srte_condition_code_postprocessing |
| `dbo.nrt_confirmation_method_key` | sp_nrt_investigation_postprocessing |
| `dbo.nrt_contact_key` | sp_d_contact_record_postprocessing |
| `dbo.nrt_d_gt_12_reas_group_key` | sp_nrt_d_gt_12_reas_postprocessing |
| `dbo.nrt_d_gt_12_reas_key` | sp_nrt_d_gt_12_reas_postprocessing |
| `dbo.nrt_d_hc_prov_ty_3_group_key` | sp_nrt_d_hc_prov_ty_3_postprocessing |
| `dbo.nrt_d_hc_prov_ty_3_key` | sp_nrt_d_hc_prov_ty_3_postprocessing |
| `dbo.nrt_d_out_of_cntry_group_key` | sp_nrt_d_out_of_cntry_postprocessing |
| `dbo.nrt_d_out_of_cntry_key` | sp_nrt_d_out_of_cntry_postprocessing |
| `dbo.nrt_d_pcr_source_group_key` | sp_nrt_d_pcr_source_postprocessing |
| `dbo.nrt_d_pcr_source_key` | sp_nrt_d_pcr_source_postprocessing |
| `dbo.nrt_d_smr_exam_ty_group_key` | sp_nrt_d_smr_exam_ty_postprocessing |
| `dbo.nrt_d_smr_exam_ty_key` | sp_nrt_d_smr_exam_ty_postprocessing |
| `dbo.nrt_d_tb_hiv_key` | sp_nrt_d_tb_hiv_postprocessing |
| `dbo.nrt_d_tb_pam_key` | sp_nrt_d_tb_pam_postprocessing |
| `dbo.nrt_delete_job_log` | sp_batch_id_cleanup_postprocessing |
| `dbo.nrt_disease_site_group_key` | sp_nrt_d_disease_site_postprocessing |
| `dbo.nrt_disease_site_key` | sp_nrt_d_disease_site_postprocessing |
| `dbo.nrt_dyn_dm_column_metadata` | sp_nrt_odse_nbs_page_postprocessing |
| `dbo.nrt_hepatitis_case_group_key` | sp_hepatitis_case_datamart_postprocessing |
| `dbo.nrt_hepatitis_case_multi_val_key` | sp_hepatitis_case_datamart_postprocessing |
| `dbo.nrt_interview_key` | sp_d_interview_postprocessing |
| `dbo.nrt_interview_note_key` | sp_d_interview_postprocessing |
| `dbo.nrt_investigation_key` | sp_nrt_investigation_postprocessing |
| `dbo.nrt_lab_result_comment_key` | sp_d_labtest_result_postprocessing |
| `dbo.nrt_lab_rpt_user_comment_key` | sp_d_lab_test_postprocessing |
| `dbo.nrt_lab_test_key` | sp_d_lab_test_postprocessing |
| `dbo.nrt_lab_test_result_group_key` | sp_d_labtest_result_postprocessing |
| `dbo.nrt_ldf_data_key` | sp_nrt_ldf_postprocessing |
| `dbo.nrt_ldf_group_key` | sp_nrt_ldf_postprocessing |
| `dbo.nrt_move_cntry_group_key` | sp_nrt_d_move_cntry_postprocessing |
| `dbo.nrt_move_cntry_key` | sp_nrt_d_move_cntry_postprocessing |
| `dbo.nrt_move_cnty_group_key` | sp_nrt_d_move_cnty_postprocessing |
| `dbo.nrt_move_cnty_key` | sp_nrt_d_move_cnty_postprocessing |
| `dbo.nrt_move_state_group_key` | sp_nrt_d_move_state_postprocessing |
| `dbo.nrt_move_state_key` | sp_nrt_d_move_state_postprocessing |
| `dbo.nrt_moved_where_group_key` | sp_nrt_d_moved_where_postprocessing |
| `dbo.nrt_moved_where_key` | sp_nrt_d_moved_where_postprocessing |
| `dbo.nrt_notification_key` | sp_nrt_notification_postprocessing |
| `dbo.nrt_organization_key` | sp_nrt_organization_postprocessing |
| `dbo.nrt_patient_key` | sp_nrt_patient_postprocessing |
| `dbo.nrt_pertussis_source_group_key` | sp_pertussis_case_datamart_postprocessing |
| `dbo.nrt_pertussis_source_key` | sp_pertussis_case_datamart_postprocessing |
| `dbo.nrt_pertussis_treatment_group_key` | sp_pertussis_case_datamart_postprocessing |
| `dbo.nrt_pertussis_treatment_key` | sp_pertussis_case_datamart_postprocessing |
| `dbo.nrt_place_key` | sp_nrt_place_postprocessing |
| `dbo.nrt_provider_key` | sp_nrt_provider_postprocessing |
| `dbo.nrt_rash_loc_gen_group_key` | sp_nrt_d_rash_loc_gen_postprocessing |
| `dbo.nrt_rash_loc_gen_key` | sp_nrt_d_rash_loc_gen_postprocessing |
| `dbo.nrt_summary_case_group_key` | sp_summary_report_case_postprocessing |
| `dbo.nrt_treatment_key` | sp_nrt_treatment_postprocessing |
| `dbo.nrt_vaccination_key` | sp_d_vaccination_postprocessing |
| `dbo.nrt_var_pam_key` | sp_nrt_d_var_pam_postprocessing |
| `dbo.rdb_date_temp` | sp_get_date_dim |

## Views (excluded from fixture scope)

These are defined under `db/005-rdb_modern/views/`. RTR reads from them
but never writes to them. None of the targets above are views.

| View | DDL file |
| ---- | -------- |
| `dbo.v_codeset` | `001-v_codeset-001.sql` |
| `dbo.v_getobscode` | `002-v_getobscode-001.sql` |
| `dbo.v_getobsdate` | `003-v_getobsdate-001.sql` |
| `dbo.v_getobsnum` | `004-v_getobsnum-001.sql` |
| `dbo.v_getobstxt` | `005-v_getobstxt-001.sql` |
| `dbo.v_nrt_srte_totalidm` | `006-v_nrt_srte_totalidm-001.sql` |
| `dbo.v_code_value_general` | `007-v_code_value_general-001.sql` |
| `dbo.v_nrt_inv_keys_attrs_mapping` | `009-v_nrt_inv_keys_attrs_mapping-001.sql` |
| `dbo.v_rdb_obs_mapping` | `010-v_rdb_obs_mapping-001.sql` |
| `dbo.v_nrt_nbs_page` | `011-v_nrt_nbs_page-001.sql` |
| `dbo.v_nrt_odse_NBS_rdb_metadata_recent` | `012-v_nrt_odse_NBS_rdb_metadata_recent-001.sql` |
| `dbo.v_nrt_nbs_investigation_rdb_table_metadata` | `013-v_nrt_nbs_investigation_rdb_table_metadata-001.sql` |
| `dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata` | `014-v_nrt_nbs_d_case_mgmt_rdb_table_metadata-001.sql` |
| `dbo.v_nrt_d_inv_metadata` | `015-v_nrt_d_inv_metadata-001.sql` |
| `dbo.v_nrt_d_provider_rdb_table_metadata` | `016-v_nrt_d_provider_rdb_table_metadata-001.sql` |
| `dbo.v_nrt_nbs_d_organization_rdb_table_metadata` | `017-v_nrt_nbs_d_organization_rdb_table_metadata-001.sql` |
| `dbo.v_nrt_nbs_d_patient_rdb_table_metadata` | `018-v_nrt_nbs_d_patient_rdb_table_metadata-001.sql` |
| `dbo.v_nrt_nbs_repeatvarch_rdb_table_metadata` | `019-v_nrt_nbs_repeatvarch_rdb_table_metadata-001.sql` |
| `dbo.v_nrt_srte_state_code` | `020-v_nrt_srte_state_code-001.sql` |
| `dbo.v_nrt_d_inv_repeat_blockdata` | `021-v_nrt_d_inv_repeat_blockdata-001.sql` |
| `dbo.v_nrt_d_inv_repeat_metadata` | `022-v_nrt_d_inv_repeat_metadata-001.sql` |
| `dbo.v_nrt_nbs_repeatnumeric_rdb_table_metadata` | `023-v_nrt_nbs_repeatnumeric_rdb_table_metadata-001.sql` |
| `dbo.v_nrt_ref_formcode_translation` | `024-v_nrt_ref_formcode_translation-001.sql` |

## SP catalog

One row per `.sql` file in `routines/`. `Type` is one of:

- `event` — reads NBS_ODSE, writes `dbo.nrt_*` staging only.
- `nrt_postprocessing` — reads `dbo.nrt_*` staging, writes RDB_MODERN dim /
  fact / lookup tables and RTR-side `nrt_*_key` tables.
- `datamart_postprocessing` — reads RDB_MODERN dimensions, writes datamart
  tables (HEPATITIS_DATAMART, STD_HIV_DATAMART, etc.).
- `datamart` — datamart-shaped SP without `_postprocessing` suffix.
- `dyn_dm_postprocessing` / `dyn_dm_utility` — dynamic-datamart family
  (operates on `nrt_dyn_dm_*` metadata, generates / mutates datamart
  tables and columns at runtime).
- `postprocessing` — postprocessing SP that doesn't fit the above buckets.
- `utility` — schema-altering or housekeeping SP (cleanup, backfill,
  date-dim build, etc.).

`Reads from` lists tables read via `FROM` / `JOIN` (filtered to known real
tables and views; CTEs and pure temp-table reads elided). `Writes to (top-
level)` is the distinct set of RDB_MODERN target tables this SP writes to,
case-insensitively deduplicated. Pure-staging targets (`nrt_*`, `tmp_*`,
`#temp`) are included so the chain is visible. `<dynamic:@var>` markers
indicate the SP writes to a runtime-resolved table.

| File | SP | Type | Reads from (sample) | Writes to (top-level) |
| ---- | -- | ---- | ------------------- | --------------------- |
| `002-sp_nrt_organization_postprocessing-001.sql` | `sp_nrt_organization_postprocessing` | nrt_postprocessing | dbo.nrt_odse_NBS_page, dbo.nrt_organization, dbo.nrt_organization_key | dbo.job_flow_log, dbo.nrt_organization_key, dbo.d_organization |
| `003-sp_nrt_provider_postprocessing-001.sql` | `sp_nrt_provider_postprocessing` | nrt_postprocessing | dbo.nrt_odse_NBS_page, dbo.nrt_provider, dbo.nrt_provider_key | dbo.job_flow_log, dbo.nrt_provider_key, dbo.d_provider |
| `004-sp_nrt_patient_postprocessing-001.sql` | `sp_nrt_patient_postprocessing` | nrt_postprocessing | dbo.nrt_datamart_metadata, dbo.nrt_investigation, dbo.nrt_odse_NBS_page, dbo.nrt_patient, dbo.nrt_patient_key, … (+1 more) | dbo.job_flow_log, dbo.nrt_patient_key, dbo.d_patient |
| `005-sp_nrt_investigation_postprocessing-001.sql` | `sp_nrt_investigation_postprocessing` | nrt_postprocessing | dbo.nrt_confirmation_method_key, dbo.nrt_datamart_metadata, dbo.nrt_investigation, dbo.nrt_investigation_confirmation, dbo.nrt_investigation_key, … (+6 more) | dbo.job_flow_log, dbo.nrt_investigation_key, dbo.INVESTIGATION, dbo.nrt_confirmation_method_key, dbo.confirmation_method, dbo.CONFIRMATION_METHOD_GROUP |
| `006-sp_nrt_notification_postprocessing-001.sql` | `sp_nrt_notification_postprocessing` | nrt_postprocessing | dbo.nrt_datamart_metadata, dbo.nrt_investigation_notification, dbo.nrt_notification_key, dbo.nrt_srte_Condition_code | dbo.job_flow_log, dbo.nrt_notification_key, dbo.NOTIFICATION, dbo.NOTIFICATION_EVENT, dbo.HEPATITIS_DATAMART |
| `007-sp_s_pagebuilder_postprocessing-001.sql` | `sp_s_pagebuilder_postprocessing` | postprocessing | dbo.nrt_investigation, dbo.nrt_page_case_answer, dbo.nrt_srte_Code_value_general, dbo.nrt_srte_Codeset, dbo.nrt_srte_Codeset_Group_Metadata, … (+3 more) | dbo.job_flow_log, dbo.ETL_DQ_LOG |
| `008-sp_l_pagebuilder_postprocessing-001.sql` | `sp_l_pagebuilder_postprocessing` | postprocessing | dbo.nrt_investigation | dbo.job_flow_log, <dynamic:@LOOKUP_TABLE_INC_TABLE_NAME> |
| `009-sp_d_pagebuilder_postprocessing-001.sql` | `sp_d_pagebuilder_postprocessing` | postprocessing |  | dbo.job_flow_log, <dynamic:@rdb_table_name> |
| `010-sp_sld_investigation_repeat_postprocessing-001.sql` | `sp_sld_investigation_repeat_postprocessing` | postprocessing | dbo.nrt_investigation, dbo.nrt_page_case_answer, dbo.nrt_srte_Code_value_general, dbo.nrt_srte_Codeset_Group_Metadata, dbo.nrt_srte_Condition_code, … (+1 more) | dbo.job_flow_log, dbo.ETL_DQ_LOG, dbo.L_INVESTIGATION_REPEAT_INC, dbo.L_INVESTIGATION_REPEAT, dbo.D_INVESTIGATION_REPEAT, dbo.LOOKUP_TABLE_N_REPT, dbo.job_batch_rebuild_log |
| `011-sp_page_builder_postprocessing-001.sql` | `sp_page_builder_postprocessing` | postprocessing | dbo.nrt_investigation, dbo.nrt_page_case_answer | dbo.job_flow_log |
| `012-sp_f_page_case_postprocessing-001.sql` | `sp_f_page_case_postprocessing` | postprocessing | dbo.nrt_investigation | dbo.job_flow_log, dbo.F_PAGE_CASE |
| `013-sp_hepatitis_datamart_postprocessing-001.sql` | `sp_hepatitis_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_investigation, dbo.nrt_investigation_notification, dbo.nrt_investigation_observation, dbo.nrt_notification_key, dbo.nrt_observation, … (+1 more) | dbo.job_flow_log, dbo.HEPATITIS_DATAMART |
| `014-sp_get_date_dim-001.sql` | `sp_get_date_dim` | utility |  | dbo.rdb_date_temp, dbo.RDB_DATE |
| `015-sp_nrt_ldf_postprocessing-001.sql` | `sp_nrt_ldf_postprocessing` | nrt_postprocessing | dbo.LDF_DATA, dbo.LDF_GROUP, dbo.ORGANIZATION_LDF_GROUP, dbo.PATIENT_LDF_GROUP, dbo.PROVIDER_LDF_GROUP, … (+5 more) | dbo.job_flow_log, dbo.nrt_ldf_group_key, dbo.LDF_GROUP, dbo.nrt_ldf_data_key, dbo.LDF_DATA, dbo.PATIENT_LDF_GROUP, dbo.PROVIDER_LDF_GROUP, dbo.ORGANIZATION_LDF_GROUP |
| `016-sp_nrt_morbidity_report_postprocessing-001.sql` | `sp_d_morbidity_report_postprocessing` | postprocessing | dbo.LDF_GROUP, dbo.nrt_datamart_metadata, dbo.nrt_observation, dbo.nrt_observation_coded, dbo.nrt_observation_date, … (+4 more) | dbo.JOB_FLOW_LOG, dbo.MORBIDITY_REPORT, dbo.MORBIDITY_REPORT_EVENT, dbo.morb_Rpt_User_Comment, dbo.LAB_TEST_RESULT, <dynamic:@tmp_morb_Rpt_User_Comment>, <dynamic:@tmp_id_assignment>, <dynamic:@tmp_Morbidity_Report> |
| `017-sp_d_labtest_result_postprocessing-001.sql` | `sp_d_labtest_result_postprocessing` | postprocessing | dbo.LDF_GROUP, dbo.nrt_datamart_metadata, dbo.nrt_lab_result_comment_key, dbo.nrt_lab_test_result_group_key, dbo.nrt_observation, … (+6 more) | dbo.JOB_FLOW_LOG, dbo.nrt_lab_result_comment_key, dbo.nrt_lab_test_result_group_key, dbo.TEST_RESULT_GROUPING, dbo.LAB_RESULT_VAL, dbo.RESULT_COMMENT_GROUP, dbo.Lab_Result_Comment, dbo.LAB_TEST_RESULT, … (+1 more) |
| `018-sp_d_lab_test_postprocessing-001.sql` | `sp_d_lab_test_postprocessing` | postprocessing | dbo.nrt_lab_rpt_user_comment_key, dbo.nrt_lab_test_key, dbo.nrt_observation, dbo.nrt_observation_edx, dbo.nrt_observation_material, … (+6 more) | dbo.job_flow_log, dbo.nrt_lab_test_key, dbo.LAB_TEST, dbo.nrt_lab_rpt_user_comment_key, dbo.LAB_RPT_USER_COMMENT |
| `019-sp_lab100_datamart_postprocessing-001.sql` | `sp_lab100_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_srte_Condition_code, dbo.nrt_srte_Labtest_loinc, dbo.nrt_srte_Loinc_condition, dbo.nrt_srte_Program_area_code, dbo.nrt_srte_Snomed_condition | dbo.JOB_FLOW_LOG, dbo.LAB100 |
| `020-sp_lab101_datamart_postprocessing-001.sql` | `sp_lab101_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_observation | dbo.JOB_FLOW_LOG, dbo.LAB101 |
| `021-sp_nrt_case_count_postprocessing-001.sql` | `sp_nrt_case_count_postprocessing` | nrt_postprocessing | dbo.nrt_investigation | dbo.job_flow_log, dbo.CASE_COUNT |
| `022-sp_nrt_case_management_postprocessing-001.sql` | `sp_nrt_case_management_postprocessing` | nrt_postprocessing | dbo.nrt_case_management_key, dbo.nrt_investigation_case_management | dbo.job_flow_log, dbo.nrt_case_management_key, dbo.D_CASE_MANAGEMENT |
| `023-sp_d_interview_postprocessing-001.sql` | `sp_d_interview_postprocessing` | postprocessing | dbo.nrt_interview, dbo.nrt_interview_answer, dbo.nrt_interview_key, dbo.nrt_interview_note, dbo.nrt_interview_note_key, … (+1 more) | dbo.JOB_FLOW_LOG, dbo.nrt_interview_key, dbo.D_INTERVIEW, dbo.nrt_interview_note_key, dbo.D_INTERVIEW_NOTE |
| `024-sp_f_interview_case_postprocessing-001.sql` | `sp_f_interview_case_postprocessing` | postprocessing | dbo.nrt_interview, dbo.nrt_interview_key, dbo.nrt_investigation | dbo.job_flow_log, dbo.F_INTERVIEW_CASE |
| `025-sp_f_std_page_case_postprocessing-001.sql` | `sp_f_std_page_case_postprocessing` | postprocessing | dbo.nrt_investigation, dbo.nrt_investigation_case_management, dbo.nrt_srte_Condition_code | dbo.job_flow_log, dbo.ETL_DQ_LOG, dbo.F_STD_PAGE_CASE |
| `026-sp_std_hiv_datamart_postprocessing-001.sql` | `sp_std_hiv_datamart_postprocessing` | datamart_postprocessing | dbo.INV_HIV, dbo.STD_HIV_DATAMART | dbo.job_flow_log, dbo.INV_HIV, dbo.STD_HIV_DATAMART |
| `027-sp_user_profile_postprocessing-001.sql` | `sp_user_profile_postprocessing` | postprocessing | dbo.nrt_auth_user | dbo.job_flow_log, dbo.USER_PROFILE |
| `028-sp_nrt_place_postprocessing-001.sql` | `sp_nrt_place_postprocessing` | nrt_postprocessing | dbo.nrt_place, dbo.nrt_place_key, dbo.nrt_place_tele | dbo.job_flow_log, dbo.nrt_place_key, dbo.D_PLACE, dbo.D_INV_PLACE_REPEAT |
| `029-sp_alter_datamart_schema_postprocessing-001.sql` | `sp_alter_datamart_schema_postprocessing` | datamart_postprocessing |  | dbo.JOB_FLOW_LOG |
| `030-sp_generic_case_datamart_postprocessing-001.sql` | `sp_generic_case_datamart_postprocessing` | datamart_postprocessing | dbo.v_nrt_inv_keys_attrs_mapping, dbo.v_rdb_obs_mapping | dbo.job_flow_log, <dynamic:@tgt_table_nm> |
| `031-sp_rubella_case_datamart_postprocessing-001.sql` | `sp_rubella_case_datamart_postprocessing` | datamart_postprocessing | dbo.v_nrt_inv_keys_attrs_mapping, dbo.v_rdb_obs_mapping | dbo.job_flow_log, <dynamic:@tgt_table_nm> |
| `032-sp_crs_case_datamart_postprocessing-001.sql` | `sp_crs_case_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_srte_Code_value_general, dbo.v_nrt_inv_keys_attrs_mapping, dbo.v_rdb_obs_mapping | dbo.job_flow_log, <dynamic:@tgt_table_nm> |
| `033-sp_measles_case_datamart_postprocessing-001.sql` | `sp_measles_case_datamart_postprocessing` | datamart_postprocessing | dbo.v_nrt_inv_keys_attrs_mapping, dbo.v_rdb_obs_mapping | dbo.job_flow_log, <dynamic:@tgt_table_nm> |
| `034-sp_case_lab_datamart_postprocessing-001.sql` | `sp_case_lab_datamart_postprocessing` | datamart_postprocessing | dbo.CASE_LAB_DATAMART | dbo.JOB_FLOW_LOG, dbo.CASE_LAB_DATAMART |
| `035-sp_repeated_place_postprocessing-001.sql` | `sp_repeated_place_postprocessing` | postprocessing | dbo.nrt_investigation, dbo.nrt_page_case_answer | dbo.job_flow_log, dbo.L_INV_PLACE_REPEAT, dbo.D_INV_PLACE_REPEAT |
| `036-sp_d_contact_record_postprocessing-001.sql` | `sp_d_contact_record_postprocessing` | postprocessing | dbo.nrt_contact, dbo.nrt_contact_answer, dbo.nrt_contact_key, dbo.nrt_datamart_metadata, dbo.nrt_investigation, … (+1 more) | dbo.JOB_FLOW_LOG, dbo.nrt_contact_key, dbo.D_CONTACT_RECORD |
| `037-sp_event_metric_datamart_postprocessing-001.sql` | `sp_event_metric_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_auth_user, dbo.nrt_contact, dbo.nrt_investigation, dbo.nrt_investigation_notification, dbo.nrt_observation, … (+7 more) | dbo.job_flow_log, dbo.EVENT_METRIC_INC, dbo.EVENT_METRIC |
| `038-sp_f_contact_record_case_postprocessing-001.sql` | `sp_f_contact_record_case_postprocessing` | postprocessing | dbo.nrt_contact, dbo.nrt_contact_key, dbo.nrt_interview_key | dbo.JOB_FLOW_LOG, dbo.F_CONTACT_RECORD_CASE |
| `039-sp_hepatitis_case_datamart_postprocessing-001.sql` | `sp_hepatitis_case_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_hepatitis_case_group_key, dbo.nrt_hepatitis_case_multi_val_key, dbo.v_nrt_inv_keys_attrs_mapping, dbo.v_rdb_obs_mapping | dbo.job_flow_log, dbo.nrt_hepatitis_case_group_key, dbo.nrt_hepatitis_case_multi_val_key, dbo.HEP_MULTI_VALUE_FIELD_GROUP, <dynamic:@tgt_table_nm>, <dynamic:@multival_tgt_table_nm> |
| `040-sp_bmird_case_datamart_postprocessing-001.sql` | `sp_bmird_case_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_antimicrobial_group_key, dbo.nrt_antimicrobial_key, dbo.nrt_bmird_multi_val_group_key, dbo.nrt_bmird_multi_val_key, dbo.v_nrt_inv_keys_attrs_mapping, … (+1 more) | dbo.job_flow_log, dbo.nrt_antimicrobial_group_key, dbo.ANTIMICROBIAL_GROUP, dbo.nrt_antimicrobial_key, dbo.nrt_bmird_multi_val_group_key, dbo.BMIRD_MULTI_VALUE_FIELD_GROUP, dbo.nrt_bmird_multi_val_key, <dynamic:@tgt_table_nm>, … (+2 more) |
| `042-sp_hep100_datamart_postprocessing-001.sql` | `sp_hep100_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_investigation | dbo.job_flow_log, dbo.HEP100 |
| `043-sp_pertussis_case_datamart_postprocessing-001.sql` | `sp_pertussis_case_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_pertussis_source_group_key, dbo.nrt_pertussis_source_key, dbo.nrt_pertussis_treatment_group_key, dbo.nrt_pertussis_treatment_key, dbo.v_nrt_inv_keys_attrs_mapping, … (+1 more) | dbo.job_flow_log, dbo.nrt_pertussis_treatment_group_key, dbo.PERTUSSIS_TREATMENT_GROUP, dbo.nrt_pertussis_treatment_key, dbo.nrt_pertussis_source_group_key, dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP, dbo.nrt_pertussis_source_key, <dynamic:@tgt_table_nm>, … (+2 more) |
| `044-sp_d_vaccination_postprocessing-001.sql` | `sp_d_vaccination_postprocessing` | postprocessing | dbo.nrt_datamart_metadata, dbo.nrt_metadata_columns, dbo.nrt_vaccination, dbo.nrt_vaccination_answer, dbo.nrt_vaccination_key | dbo.JOB_FLOW_LOG, dbo.nrt_vaccination_key, dbo.D_VACCINATION |
| `045-sp_inv_summary_datamart_postprocessing-001.sql` | `sp_inv_summary_datamart_postprocessing` | datamart_postprocessing | dbo.CASE_LAB_DATAMART, dbo.F_TB_PAM, dbo.F_VAR_PAM, dbo.nrt_investigation_case_management, dbo.nrt_investigation_notification, … (+2 more) | dbo.job_flow_log, dbo.INV_SUMM_DATAMART |
| `046-sp_f_vaccination_postprocessing-001.sql` | `sp_f_vaccination_postprocessing` | postprocessing | dbo.nrt_vaccination, dbo.nrt_vaccination_key | dbo.JOB_FLOW_LOG, dbo.F_VACCINATION |
| `047-sp_nrt_treatment_postprocessing-001.sql` | `sp_nrt_treatment_postprocessing` | nrt_postprocessing | dbo.LDF_GROUP, dbo.TREATMENT, dbo.TREATMENT_EVENT, dbo.nrt_investigation, dbo.nrt_treatment, … (+1 more) | dbo.job_flow_log, dbo.nrt_treatment_key, dbo.TREATMENT, dbo.TREATMENT_EVENT |
| `048-sp_morbidity_report_datamart_postprocessing-001.sql` | `sp_morbidity_report_datamart_postprocessing` | datamart_postprocessing | dbo.MORBIDITY_REPORT_DATAMART, dbo.TREATMENT, dbo.TREATMENT_EVENT, dbo.nrt_srte_Code_value_general | dbo.JOB_FLOW_LOG, dbo.MORBIDITY_REPORT_DATAMART |
| `050-sp_aggregate_report_datamart_postprocessing-001.sql` | `sp_aggregate_report_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_investigation, dbo.nrt_investigation_aggregate, dbo.nrt_srte_Code_value_general, dbo.nrt_srte_Codeset_Group_Metadata, dbo.nrt_srte_State_county_code_value | dbo.JOB_FLOW_LOG, <dynamic:@tgt_table_nm> |
| `051-sp_organization_event-001.sql` | `sp_organization_event` | event |  | dbo.job_flow_log |
| `052-sp_provider_event-001.sql` | `sp_provider_event` | event |  | dbo.job_flow_log |
| `053-sp_patient_race_event-001.sql` | `sp_patient_race_event` | event |  | dbo.job_flow_log |
| `054-sp_patient_event-001.sql` | `sp_patient_event` | event |  | dbo.job_flow_log |
| `055-sp_observation_event-001.sql` | `sp_observation_event` | event |  | dbo.job_flow_log |
| `056-sp_investigation_event-001.sql` | `sp_investigation_event` | event |  | dbo.job_flow_log |
| `057-sp_ldf_provider_event-001.sql` | `sp_ldf_provider_event` | event |  | dbo.job_flow_log |
| `058-sp_ldf_organization_event-001.sql` | `sp_ldf_organization_event` | event |  | dbo.job_flow_log |
| `059-sp_ldf_patient_event-001.sql` | `sp_ldf_patient_event` | event |  | dbo.job_flow_log |
| `060-sp_ldf_observation_event-001.sql` | `sp_ldf_observation_event` | event |  | dbo.job_flow_log |
| `061-sp_ldf_phc_event-001.sql` | `sp_ldf_phc_event` | event |  | dbo.job_flow_log |
| `062-sp_ldf_intervention_event-001.sql` | `sp_ldf_intervention_event` | event |  | dbo.job_flow_log |
| `063-sp_ldf_data_event-001.sql` | `sp_ldf_data_event` | event |  | dbo.job_flow_log |
| `064-sp_notification_event-001.sql` | `sp_notification_event` | event |  | dbo.job_flow_log |
| `065-sp_interview_event-001.sql` | `sp_interview_event` | event |  | dbo.job_flow_log |
| `066-sp_user_report_permissions-001.sql` | `sp_user_report_permissions` | utility |  | dbo.job_flow_log |
| `067-sp_auth_user_event-001.sql` | `sp_auth_user_event` | event |  | dbo.job_flow_log |
| `068-sp_place_event-001.sql` | `sp_place_event` | event |  | dbo.job_flow_log |
| `069-sp_contact_record_event-001.sql` | `sp_contact_record_event` | event |  | dbo.job_flow_log |
| `070-sp_treatment_event-001.sql` | `sp_treatment_event` | event |  | dbo.job_flow_log |
| `071-sp_vaccination_event-001.sql` | `sp_vaccination_event` | event |  | dbo.job_flow_log |
| `072-sp_public_health_case_fact_datamart_event-001.sql` | `sp_public_health_case_fact_datamart_event` | event |  | dbo.job_flow_log |
| `073-sp_public_health_case_fact_datamart_update-001.sql` | `sp_public_health_case_fact_datamart_update` | datamart |  | dbo.job_flow_log |
| `115-sp_dyn_dm_invest_form_postprocessing-001.sql` | `sp_dyn_dm_invest_form_postprocessing` | dyn_dm_postprocessing | dbo.v_nrt_nbs_d_patient_rdb_table_metadata, dbo.v_nrt_nbs_investigation_rdb_table_metadata, dbo.v_nrt_nbs_page | dbo.job_flow_log |
| `120-sp_dyn_dm_provider_data_postprocessing-001.sql` | `sp_dyn_dm_provider_data_postprocessing` | dyn_dm_postprocessing | dbo.v_nrt_d_provider_rdb_table_metadata, dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata, dbo.v_nrt_nbs_page | dbo.job_flow_log |
| `125-sp_dyn_dm_page_builder_d_inv_postprocessing-001.sql` | `sp_dyn_dm_page_builder_d_inv_postprocessing` | dyn_dm_postprocessing | dbo.v_nrt_d_inv_metadata, dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata, dbo.v_nrt_nbs_page | dbo.job_flow_log |
| `130-sp_dyn_dm_case_management_postprocessing-001.sql` | `sp_dyn_dm_case_management_postprocessing` | dyn_dm_postprocessing | dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata, dbo.v_nrt_nbs_page | dbo.job_flow_log |
| `135-sp_dyn_dm_org_data_postprocessing-001.sql` | `sp_dyn_dm_org_data_postprocessing` | dyn_dm_postprocessing | dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata, dbo.v_nrt_nbs_d_organization_rdb_table_metadata, dbo.v_nrt_nbs_page | dbo.job_flow_log |
| `140-sp_bmird_strep_pneumo_datamart_postprocessing-001.sql` | `sp_bmird_strep_pneumo_datamart_postprocessing` | datamart_postprocessing | dbo.BMIRD_STREP_PNEUMO_DATAMART, dbo.v_nrt_inv_keys_attrs_mapping | dbo.job_flow_log, dbo.BMIRD_STREP_PNEUMO_DATAMART |
| `145-sp_nrt_d_disease_site_postprocessing-001.sql` | `sp_nrt_d_disease_site_postprocessing` | nrt_postprocessing | dbo.D_DISEASE_SITE, dbo.D_DISEASE_SITE_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_disease_site_group_key, … (+5 more) | dbo.JOB_FLOW_LOG, dbo.nrt_disease_site_group_key, dbo.nrt_disease_site_key, dbo.D_DISEASE_SITE_GROUP, dbo.D_DISEASE_SITE, dbo.F_TB_PAM |
| `146-sp_nrt_d_addl_risk_postprocessing-001.sql` | `sp_nrt_d_addl_risk_postprocessing` | nrt_postprocessing | dbo.D_ADDL_RISK, dbo.D_ADDL_RISK_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_addl_risk_group_key, … (+5 more) | dbo.JOB_FLOW_LOG, dbo.nrt_addl_risk_group_key, dbo.nrt_addl_risk_key, dbo.D_ADDL_RISK_GROUP, dbo.D_ADDL_RISK, dbo.F_TB_PAM |
| `147-sp_nrt_d_tb_pam_postprocessing-001.sql` | `sp_nrt_d_tb_pam_postprocessing` | nrt_postprocessing | dbo.D_TB_PAM, dbo.nrt_d_tb_pam_key, dbo.nrt_investigation, dbo.nrt_page_case_answer, dbo.nrt_srte_Code_value_general, … (+2 more) | dbo.job_flow_log, dbo.nrt_d_tb_pam_key, dbo.D_TB_PAM |
| `150-sp_summary_report_case_postprocessing-001.sql` | `sp_summary_report_case_postprocessing` | postprocessing | dbo.SUMMARY_CASE_GROUP, dbo.SUMMARY_REPORT_CASE, dbo.nrt_investigation, dbo.nrt_investigation_notification, dbo.nrt_investigation_observation, … (+6 more) | dbo.JOB_FLOW_LOG, dbo.nrt_summary_case_group_key, dbo.SUMMARY_CASE_GROUP, dbo.SUMMARY_REPORT_CASE |
| `155-sp_sr100_datamart_postprocessing-001.sql` | `sp_sr100_datamart_postprocessing` | datamart_postprocessing | dbo.SR100, dbo.SUMMARY_CASE_GROUP, dbo.SUMMARY_REPORT_CASE, dbo.nrt_srte_State_county_code_value, dbo.v_code_value_general | dbo.JOB_FLOW_LOG, dbo.SR100 |
| `156-sp_nrt_d_move_cntry_postprocessing-001.sql` | `sp_nrt_d_move_cntry_postprocessing` | nrt_postprocessing | dbo.D_MOVE_CNTRY, dbo.D_MOVE_CNTRY_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_investigation, … (+5 more) | dbo.JOB_FLOW_LOG, dbo.nrt_move_cntry_group_key, dbo.nrt_move_cntry_key, dbo.D_MOVE_CNTRY_GROUP, dbo.D_MOVE_CNTRY, dbo.F_TB_PAM |
| `160-sp_nrt_d_tb_hiv_postprocessing-001.sql` | `sp_nrt_d_tb_hiv_postprocessing` | nrt_postprocessing | dbo.D_TB_HIV, dbo.nrt_d_tb_hiv_key, dbo.nrt_investigation, dbo.nrt_page_case_answer, dbo.nrt_srte_Code_value_general, … (+1 more) | dbo.job_flow_log, dbo.nrt_d_tb_hiv_key, dbo.D_TB_HIV |
| `170-sp_nrt_d_gt_12_reas_postprocessing-001.sql` | `sp_nrt_d_gt_12_reas_postprocessing` | nrt_postprocessing | dbo.D_GT_12_REAS, dbo.D_GT_12_REAS_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_d_gt_12_reas_group_key, … (+5 more) | dbo.job_flow_log, dbo.nrt_d_gt_12_reas_group_key, dbo.nrt_d_gt_12_reas_key, dbo.D_GT_12_REAS_GROUP, dbo.D_GT_12_REAS, dbo.F_TB_PAM |
| `175-sp_nrt_d_move_cnty_postprocessing-001.sql` | `sp_nrt_d_move_cnty_postprocessing` | nrt_postprocessing | dbo.D_MOVE_CNTY, dbo.D_MOVE_CNTY_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_investigation, … (+5 more) | dbo.JOB_FLOW_LOG, dbo.nrt_move_cnty_group_key, dbo.nrt_move_cnty_key, dbo.D_MOVE_CNTY_GROUP, dbo.D_MOVE_CNTY, dbo.F_TB_PAM |
| `180-sp_nrt_d_hc_prov_ty_3_postprocessing-001.sql` | `sp_nrt_d_hc_prov_ty_3_postprocessing` | nrt_postprocessing | dbo.D_HC_PROV_TY_3, dbo.D_HC_PROV_TY_3_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_d_hc_prov_ty_3_group_key, … (+5 more) | dbo.job_flow_log, dbo.nrt_d_hc_prov_ty_3_group_key, dbo.nrt_d_hc_prov_ty_3_key, dbo.D_HC_PROV_TY_3_GROUP, dbo.D_HC_PROV_TY_3, dbo.F_TB_PAM |
| `185-sp_nrt_d_move_state_postprocessing-001.sql` | `sp_nrt_d_move_state_postprocessing` | nrt_postprocessing | dbo.D_MOVE_STATE, dbo.D_MOVE_STATE_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_investigation, … (+5 more) | dbo.JOB_FLOW_LOG, dbo.nrt_move_state_group_key, dbo.nrt_move_state_key, dbo.D_MOVE_STATE_GROUP, dbo.D_MOVE_STATE, dbo.F_TB_PAM |
| `190-sp_nrt_d_out_of_cntry_postprocessing-001.sql` | `sp_nrt_d_out_of_cntry_postprocessing` | nrt_postprocessing | dbo.D_OUT_OF_CNTRY, dbo.D_OUT_OF_CNTRY_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_d_out_of_cntry_group_key, … (+5 more) | dbo.job_flow_log, dbo.nrt_d_out_of_cntry_group_key, dbo.nrt_d_out_of_cntry_key, dbo.D_OUT_OF_CNTRY_GROUP, dbo.D_OUT_OF_CNTRY, dbo.F_TB_PAM |
| `195-sp_nrt_d_moved_where_postprocessing-001.sql` | `sp_nrt_d_moved_where_postprocessing` | nrt_postprocessing | dbo.D_MOVED_WHERE, dbo.D_MOVED_WHERE_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_investigation, … (+5 more) | dbo.JOB_FLOW_LOG, dbo.nrt_moved_where_group_key, dbo.nrt_moved_where_key, dbo.D_MOVED_WHERE_GROUP, dbo.D_MOVED_WHERE, dbo.F_TB_PAM |
| `200-sp_nrt_d_smr_exam_ty_postprocessing-001.sql` | `sp_nrt_d_smr_exam_ty_postprocessing` | nrt_postprocessing | dbo.D_SMR_EXAM_TY, dbo.D_SMR_EXAM_TY_GROUP, dbo.D_TB_PAM, dbo.F_TB_PAM, dbo.nrt_d_smr_exam_ty_group_key, … (+5 more) | dbo.job_flow_log, dbo.nrt_d_smr_exam_ty_group_key, dbo.nrt_d_smr_exam_ty_key, dbo.D_SMR_EXAM_TY_GROUP, dbo.D_SMR_EXAM_TY, dbo.F_TB_PAM |
| `205-sp_dyn_dm_repeatvarch_postprocessing-001.sql` | `sp_dyn_dm_repeatvarch_postprocessing` | dyn_dm_postprocessing | dbo.v_nrt_d_inv_repeat_blockdata, dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata, dbo.v_nrt_nbs_page, dbo.v_nrt_nbs_repeatvarch_rdb_table_metadata | dbo.job_flow_log |
| `206-sp_f_tb_pam_postprocessing-001.sql` | `sp_f_tb_pam_postprocessing` | postprocessing | dbo.D_ADDL_RISK, dbo.D_DISEASE_SITE, dbo.D_GT_12_REAS, dbo.D_HC_PROV_TY_3, dbo.D_MOVED_WHERE, … (+8 more) | dbo.job_flow_log, dbo.F_TB_PAM |
| `210-sp_dyn_dm_repeatdate_postprocessing-001.sql` | `sp_dyn_dm_repeatdate_postprocessing` | dyn_dm_postprocessing | dbo.v_nrt_d_inv_repeat_metadata, dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata, dbo.v_nrt_nbs_page | dbo.job_flow_log |
| `215-sp_nrt_d_var_pam_postprocessing-001.sql` | `sp_nrt_d_var_pam_postprocessing` | nrt_postprocessing | dbo.D_VAR_PAM, dbo.nrt_investigation, dbo.nrt_page_case_answer, dbo.nrt_srte_Code_value_general, dbo.nrt_srte_Codeset_Group_Metadata, … (+3 more) | dbo.JOB_FLOW_LOG, dbo.nrt_var_pam_key, dbo.D_VAR_PAM |
| `220-sp_nrt_tb_pam_ldf_postprocessing-001.sql` | `sp_nrt_tb_pam_ldf_postprocessing` | nrt_postprocessing | dbo.TB_PAM_LDF, dbo.nrt_investigation, dbo.nrt_page_case_answer, dbo.nrt_srte_Code_value_clinical, dbo.nrt_srte_Code_value_general, … (+4 more) | dbo.job_flow_log, dbo.TB_PAM_LDF |
| `225-sp_dyn_dm_main_postprocessing-001.sql` | `sp_dyn_dm_main_postprocessing` | dyn_dm_postprocessing |  | dbo.job_flow_log |
| `225-sp_nrt_d_rash_loc_gen_postprocessing-001.sql` | `sp_nrt_d_rash_loc_gen_postprocessing` | nrt_postprocessing | dbo.D_RASH_LOC_GEN, dbo.D_RASH_LOC_GEN_GROUP, dbo.D_VAR_PAM, dbo.F_VAR_PAM, dbo.nrt_investigation, … (+5 more) | dbo.JOB_FLOW_LOG, dbo.nrt_rash_loc_gen_group_key, dbo.nrt_rash_loc_gen_key, dbo.D_RASH_LOC_GEN_GROUP, dbo.D_RASH_LOC_GEN, dbo.F_VAR_PAM |
| `230-sp_nrt_d_pcr_source_postprocessing-001.sql` | `sp_nrt_d_pcr_source_postprocessing` | nrt_postprocessing | dbo.D_PCR_SOURCE, dbo.D_PCR_SOURCE_GROUP, dbo.D_VAR_PAM, dbo.F_VAR_PAM, dbo.nrt_d_pcr_source_group_key, … (+5 more) | dbo.job_flow_log, dbo.nrt_d_pcr_source_group_key, dbo.nrt_d_pcr_source_key, dbo.D_PCR_SOURCE_GROUP, dbo.D_PCR_SOURCE, dbo.F_VAR_PAM |
| `235-sp_dyn_dm_repeatnumeric_postprocessing-001.sql` | `sp_dyn_dm_repeatnumeric_postprocessing` | dyn_dm_postprocessing | dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata, dbo.v_nrt_nbs_page, dbo.v_nrt_nbs_repeatnumeric_rdb_table_metadata | dbo.job_flow_log |
| `235-sp_nrt_var_pam_ldf_postprocessing-001.sql` | `sp_nrt_var_pam_ldf_postprocessing` | nrt_postprocessing | dbo.VAR_PAM_LDF, dbo.nrt_investigation, dbo.nrt_page_case_answer, dbo.nrt_srte_Code_value_clinical, dbo.nrt_srte_Code_value_general, … (+4 more) | dbo.JOB_FLOW_LOG, dbo.VAR_PAM_LDF |
| `240-sp_f_var_pam_postprocessing-001.sql` | `sp_f_var_pam_postprocessing` | postprocessing | dbo.D_PCR_SOURCE, dbo.D_RASH_LOC_GEN, dbo.D_VAR_PAM, dbo.F_VAR_PAM, dbo.nrt_investigation, … (+1 more) | dbo.job_flow_log, dbo.F_VAR_PAM |
| `245-sp_dyn_dm_createdm_postprocessing-001.sql` | `sp_dyn_dm_createdm_postprocessing` | dyn_dm_postprocessing |  | dbo.job_flow_log, <dynamic:@tgt_table_nm> |
| `250-sp_dyn_dm_invest_clear_postprocessing-001.sql` | `sp_dyn_dm_invest_clear_postprocessing` | dyn_dm_postprocessing |  | dbo.job_flow_log |
| `250-sp_var_datamart_postprocessing-001.sql` | `sp_var_datamart_postprocessing` | datamart_postprocessing | dbo.D_PCR_SOURCE, dbo.D_RASH_LOC_GEN, dbo.D_VAR_PAM, dbo.F_VAR_PAM, dbo.nrt_investigation, … (+2 more) | dbo.JOB_FLOW_LOG, dbo.VAR_DATAMART |
| `255-sp_tb_datamart_postprocessing-001.sql` | `sp_tb_datamart_postprocessing` | datamart_postprocessing | dbo.D_ADDL_RISK, dbo.D_DISEASE_SITE, dbo.D_GT_12_REAS, dbo.D_HC_PROV_TY_3, dbo.D_MOVED_WHERE, … (+11 more) | dbo.job_flow_log, dbo.TB_DATAMART |
| `260-sp_tb_hiv_datamart_postprocessing-001.sql` | `sp_tb_hiv_datamart_postprocessing` | datamart_postprocessing | dbo.D_TB_HIV, dbo.D_TB_PAM, dbo.TB_DATAMART, dbo.TB_HIV_DATAMART | dbo.job_flow_log, dbo.TB_HIV_DATAMART |
| `265-sp_nrt_ldf_dimensional_data_postprocessing-001.sql` | `sp_nrt_ldf_dimensional_data_postprocessing` | nrt_postprocessing | dbo.D_LDF_META_DATA, dbo.LDF_DATAMART_COLUMN_REF, dbo.LDF_DIMENSIONAL_DATA, dbo.nrt_investigation, dbo.nrt_ldf_data, … (+7 more) | dbo.job_flow_log, dbo.D_LDF_META_DATA, dbo.LDF_DATAMART_COLUMN_REF, dbo.LDF_DIMENSIONAL_DATA |
| `270-sp_merge_tables-001.sql` | `sp_merge_tables` | utility |  | dbo.job_flow_log, <dynamic:@OUTPUT_TABLE> |
| `275-sp_execute_ldf_generic-001.sql` | `sp_execute_ldf_generic` | utility | dbo.LDF_DATAMART_COLUMN_REF, dbo.LDF_DIMENSIONAL_DATA | dbo.job_flow_log, <dynamic:@target_table_name> |
| `280-sp_ldf_generic_datamart_postprocessing-001.sql` | `sp_ldf_generic_datamart_postprocessing` | datamart_postprocessing |  | dbo.job_flow_log |
| `285-sp_ldf_bmird_datamart_postprocessing-001.sql` | `sp_ldf_bmird_datamart_postprocessing` | datamart_postprocessing | dbo.LDF_BMIRD, dbo.LDF_DATAMART_COLUMN_REF, dbo.LDF_DIMENSIONAL_DATA | dbo.job_flow_log, dbo.LDF_BMIRD |
| `290-sp_ldf_foodborne_datamart_postprocessing-001.sql` | `sp_ldf_foodborne_datamart_postprocessing` | datamart_postprocessing | dbo.LDF_DATAMART_COLUMN_REF, dbo.LDF_DIMENSIONAL_DATA, dbo.LDF_FOODBORNE | dbo.job_flow_log, dbo.LDF_FOODBORNE |
| `295-sp_ldf_mumps_datamart_postprocessing-001.sql` | `sp_ldf_mumps_datamart_postprocessing` | datamart_postprocessing | dbo.LDF_DATAMART_COLUMN_REF, dbo.LDF_DIMENSIONAL_DATA, dbo.LDF_MUMPS | dbo.job_flow_log, dbo.LDF_MUMPS |
| `300-sp_ldf_tetanus_datamart_postprocessing-001.sql` | `sp_ldf_tetanus_datamart_postprocessing` | datamart_postprocessing | dbo.LDF_DATAMART_COLUMN_REF, dbo.LDF_DIMENSIONAL_DATA, dbo.LDF_TETANUS | dbo.job_flow_log, dbo.LDF_TETANUS |
| `305-sp_ldf_vaccine_prevent_diseases_datamart_postprocessing-001.sql` | `sp_ldf_vaccine_prevent_diseases_datamart_postprocessing` | datamart_postprocessing | dbo.LDF_DATAMART_COLUMN_REF, dbo.LDF_DIMENSIONAL_DATA, dbo.LDF_VACCINE_PREVENT_DISEASES | dbo.job_flow_log, dbo.LDF_VACCINE_PREVENT_DISEASES |
| `310-sp_covid_case_datamart_postprocessing-001.sql` | `sp_covid_case_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_investigation, dbo.nrt_investigation_confirmation, dbo.nrt_investigation_notification, dbo.nrt_odse_NBS_rdb_metadata, dbo.nrt_odse_NBS_ui_metadata, … (+7 more) | dbo.JOB_FLOW_LOG, dbo.COVID_CASE_DATAMART |
| `315-sp_covid_contact_datamart_postprocessing-001.sql` | `sp_covid_contact_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_contact, dbo.nrt_contact_answer, dbo.nrt_investigation, dbo.nrt_page_case_answer, dbo.nrt_patient, … (+3 more) | dbo.job_flow_log, dbo.COVID_CONTACT_DATAMART |
| `320-sp_covid_vaccination_datamart_postprocessing-001.sql` | `sp_covid_vaccination_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_investigation, dbo.nrt_vaccination | dbo.JOB_FLOW_LOG, dbo.COVID_VACCINATION_DATAMART |
| `320-sp_ldf_hepatitis_datamart_postprocessing-001.sql` | `sp_ldf_hepatitis_datamart_postprocessing` | datamart_postprocessing | dbo.LDF_DATAMART_COLUMN_REF, dbo.LDF_DIMENSIONAL_DATA, dbo.LDF_HEPATITIS | dbo.job_flow_log, dbo.LDF_HEPATITIS |
| `325-sp_covid_lab_celr_datamart_postprocessing-001.sql` | `sp_covid_lab_celr_datamart_postprocessing` | datamart_postprocessing | dbo.COVID_LAB_CELR_DATAMART, dbo.nrt_srte_State_code | dbo.JOB_FLOW_LOG, dbo.COVID_LAB_CELR_DATAMART |
| `330-sp_covid_lab_datamart_postprocessing-001.sql` | `sp_covid_lab_datamart_postprocessing` | datamart_postprocessing | dbo.nrt_investigation, dbo.nrt_observation, dbo.nrt_observation_coded, dbo.nrt_observation_material, dbo.nrt_observation_numeric, … (+11 more) | dbo.job_flow_log, dbo.COVID_LAB_DATAMART |
| `335-sp_nrt_odse_nbs_page_postprocessing-001.sql` | `sp_nrt_odse_nbs_page_postprocessing` | nrt_postprocessing | dbo.nrt_dyn_dm_column_metadata, dbo.nrt_odse_NBS_page, dbo.nrt_odse_NBS_rdb_metadata, dbo.nrt_odse_NBS_ui_metadata, dbo.v_nrt_odse_NBS_rdb_metadata_recent | dbo.job_flow_log, dbo.nrt_dyn_dm_column_metadata |
| `340-sp_nrt_srte_condition_code_postprocessing-001.sql` | `sp_nrt_srte_condition_code_postprocessing` | nrt_postprocessing | dbo.nrt_condition_key, dbo.nrt_srte_Condition_code, dbo.nrt_srte_Program_area_code | dbo.job_flow_log, dbo.nrt_condition_key, dbo.CONDITION |
| `345-sp_event_metric_cleanup_postprocessing-001.sql` | `sp_event_metric_cleanup_postprocessing` | postprocessing | dbo.nrt_odse_NBS_configuration | dbo.job_flow_log, dbo.EVENT_METRIC |
| `350-sp_batch_id_cleanup_postprocessing-001.sql` | `sp_batch_id_cleanup_postprocessing` | postprocessing | dbo.nrt_delete_job_log, dbo.nrt_interview, dbo.nrt_interview_answer, dbo.nrt_interview_note, dbo.nrt_investigation, … (+9 more) | dbo.job_flow_log, dbo.nrt_delete_job_log |
| `355-sp_nrt_backfill_postprocessing-001.sql` | `sp_nrt_backfill_postprocessing` | nrt_postprocessing | dbo.nrt_backfill | dbo.nrt_backfill, dbo.job_flow_log |
| `360-sp_nrt_backfill_event-001.sql` | `sp_nrt_backfill_event` | event | dbo.nrt_backfill |  |
| `365-sp_dyn_dm_dimension_update-001.sql` | `sp_dyn_dm_dimension_update` | dyn_dm_utility |  | dbo.job_flow_log |
| `365-sp_patient_dim_columns_update_to_datamart.sql` | `sp_patient_dim_columns_update_to_datamart` | datamart | dbo.BMIRD_STREP_PNEUMO_DATAMART, dbo.CASE_LAB_DATAMART, dbo.F_TB_PAM, dbo.F_VAR_PAM, dbo.MORBIDITY_REPORT_DATAMART, … (+3 more) | dbo.job_flow_log, dbo.CASE_LAB_DATAMART, dbo.BMIRD_STREP_PNEUMO_DATAMART, dbo.HEP100, dbo.MORBIDITY_REPORT_DATAMART, dbo.STD_HIV_DATAMART, dbo.VAR_DATAMART, dbo.TB_DATAMART, … (+1 more) |
| `370-sp_provider_dim_columns_update_to_datamart.sql` | `sp_provider_dim_columns_update_to_datamart` | datamart | dbo.AGGREGATE_REPORT_DATAMART, dbo.F_TB_PAM, dbo.MORBIDITY_REPORT_DATAMART, dbo.STD_HIV_DATAMART, dbo.TB_DATAMART, … (+1 more) | dbo.job_flow_log, dbo.MORBIDITY_REPORT_DATAMART, dbo.AGGREGATE_REPORT_DATAMART |

## Notes

- The `_event` SPs (`sp_*_event`) write only to `dbo.nrt_*` staging plus
  `dbo.job_flow_log`. Their staging targets are listed under intermediate
  and the SP catalog; per-table breakdown deliberately excludes them.
- `dbo.job_flow_log` is touched by virtually every SP for run logging. It
  is listed as in-scope because it is a real RDB_MODERN table, but it is
  not a fixture coverage target — any SP execution will populate it.
- `dbo.morb_Rpt_User_Comment` and `dbo.confirmation_method` are listed with
  the (lowercase) casing RTR uses in the SP body. Both are real RDB tables;
  the legacy DDL uses uppercase names. Treat as case-insensitive.
- Datamart-family SPs (Hepatitis_Case, Generic_Case, Pertussis_Case,
  BMIRD_Case, CRS_Case, Measles_Case, Rubella_Case, Aggregate_Report,
  dyn_dm_createdm) select their actual datamart table by `@tgt_table_nm`
  from `dbo.nrt_datamart_metadata` and assemble the column list at runtime
  from `nrt_dyn_dm_column_metadata` / page-builder metadata. The static
  column lists captured here cover only the literal portion of the
  `INSERT` / `UPDATE` statement; the dynamic columns appended via
  `STRING_AGG` over a metadata table are out of reach for static analysis.
  Coverage measurement for those columns must be done at runtime against
  the actual datamart table populated post-EXEC.
- `sp_dyn_dm_dimension_update`, `sp_alter_datamart_schema_postprocessing`,
  `sp_dyn_dm_createdm_postprocessing`, and `sp_dyn_dm_invest_clear_postprocessing`
  are schema mutators — they `CREATE TABLE` / `ALTER TABLE` datamarts
  rather than (or in addition to) writing data. Their captured writes are
  the data writes only.
- `sp_patient_dim_columns_update_to_datamart` and
  `sp_provider_dim_columns_update_to_datamart` propagate dimension changes
  outward into every datamart that denormalizes patient / provider columns.
  They are why most datamart tables show two writers (the originating
  `*_datamart_postprocessing` SP plus the back-propagation SP). The
  back-propagation columns are guarded by `WHEN MATCHED` joins and never
  introduce a row themselves.
- File `016-sp_nrt_morbidity_report_postprocessing-001.sql` defines a SP
  named `sp_d_morbidity_report_postprocessing` (file naming convention does
  not match SP name in this case). The catalog uses the SP name from the
  `CREATE OR ALTER PROCEDURE` clause.
- Several SPs call other SPs via `EXEC dbo.<sp>`. The chain
  `sp_<entity>_event` → `sp_nrt_<entity>_postprocessing` is the canonical
  RTR transformation; verification recipes in STRATEGY.md describe how to
  exercise it. Datamart SPs are invoked once dimensions are populated.