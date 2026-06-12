# RDB vs RDB_MODERN Comparison Report

- RDB (legacy): `RDB`
- RDB_MODERN: `RDB_MODERN`
- Generated at: 2026-06-08T19:43:44+00:00

## Summary

| Metric | Count |
| --- | ---: |
| Tables discovered | 180 |
| Tables compared | 180 |
| Tables skipped | 0 |
| Tables needing attention | 11 |
| Column diffs: NEW | 207 |
| Column diffs: KNOWN_BUG | 6 |
| Column diffs: EXPECTED | 0 |
| Column diffs: IGNORED | 35 |

## Tables needing attention (NEW differences)

### `D_ORGANIZATION`

- Presence: `both`
- Key columns: ORGANIZATION_LOCAL_ID
- Row counts: RDB=16, RDB_MODERN=16
- Keys: matched=15, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| ORGANIZATION_EMAIL | 15 | 4 | 26.7% | NEW | - | `NULL` → ``; `NULL` → ``; `NULL` → ``; (+1 more) |
| ORGANIZATION_PHONE_COMMENTS | 15 | 5 | 33.3% | NEW | - | `NULL` → ``; `NULL` → ``; `NULL` → ``; (+2 more) |
| ORGANIZATION_PHONE_EXT_WORK | 15 | 5 | 33.3% | NEW | - | `NULL` → ``; `NULL` → ``; `NULL` → ``; (+2 more) |
| ORGANIZATION_KEY | 15 | 4 | 26.7% | IGNORED | IGN-key_offset-ALL | `9` → `11`; `10` → `12`; `11` → `9`; (+1 more) |

### `D_PROVIDER`

- Presence: `both`
- Key columns: PROVIDER_LOCAL_ID
- Row counts: RDB=25, RDB_MODERN=25
- Keys: matched=24, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| PROVIDER_PHONE_COMMENTS | 24 | 2 | 8.3% | NEW | - | `v2 Provider work email` → `v2 Provider work phone`; `phys work email` → `phys work phone` |
| PROVIDER_PHONE_EXT_WORK | 24 | 2 | 8.3% | NEW | - | `NULL` → `5678`; `NULL` → `1111` |
| PROVIDER_PHONE_WORK | 24 | 2 | 8.3% | NEW | - | `NULL` → `404-555-1010`; `NULL` → `404-555-9110` |
| PROVIDER_KEY | 24 | 12 | 50.0% | IGNORED | IGN-key_offset-ALL | `14` → `18`; `15` → `19`; `16` → `14`; (+9 more) |

### `D_TB_PAM`

- Presence: `both`
- Key columns: TB_PAM_UID
- Row counts: RDB=2, RDB_MODERN=2
- Keys: matched=2, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| CASE_VERIFICATION | 2 | 1 | 50.0% | NEW | - | `NULL` → `5 - Suspect` |
| CHEST_XRAY_CAVITY_EVIDENCE | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| CHEST_XRAY_MILIARY_EVIDENCE | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| CHEST_XRAY_RESULT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| COMMENTS_FOLLOW_UP_1 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB270-VAL` |
| COMMENTS_FOLLOW_UP_2 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB271-VAL` |
| CORRECTIONAL_FACIL_CUSTODY_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| CORRECTIONAL_FACIL_RESIDENT | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| CORRECTIONAL_FACIL_TY | 2 | 1 | 50.0% | NEW | - | `NULL` → `Juvenile Correctional Facility` |
| COUNTRY_OF_VERIFIED_CASE | 2 | 1 | 50.0% | NEW | - | `NULL` → `UNITED STATES` |
| COUNT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| COUNT_STATUS | 2 | 1 | 50.0% | NEW | - | `NULL` → `Count as a TB Case` |
| CT_SCAN_CAVITY_EVIDENCE | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| CT_SCAN_MILIARY_EVIDENCE | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| CT_SCAN_RESULT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| CULT_TISSUE_COLLECT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| CULT_TISSUE_RESULT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Negative` |
| CULT_TISSUE_RESULT_RPT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| CULT_TISSUE_RESULT_RPT_LAB_TY | 2 | 1 | 50.0% | NEW | - | `NULL` → `Other` |
| CULT_TISSUE_SITE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Liver` |
| DATE_ARRIVED_IN_US | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| DOT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Yes, Totally Directly Observed` |
| DOT_NUMBER_WEEKS | 2 | 1 | 50.0% | NEW | - | `NULL` → `42` |
| EXCESS_ALCOHOL_USE_PAST_YEAR | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| FINAL_ISOLATE_COLLECT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| FINAL_ISOLATE_IS_SPUTUM_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| FINAL_ISOLATE_NOT_SPUTUM | 2 | 1 | 50.0% | NEW | - | `NULL` → `Liver` |
| FINAL_SUSCEPT_AMIKACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_CAPREOMYCIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_CIPROFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_CYCLOSERINE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_ETHAMBUTOL | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_ETHIONAMIDE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_ISONIAZID | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_KANAMYCIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_LEVOFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_MOXIFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_OFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_OTHER | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB263-VAL` |
| FINAL_SUSCEPT_OTHER_2 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB265-VAL` |
| FINAL_SUSCEPT_OTHER_2_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_OTHER_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_OTHER_QUINOLONES | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_PA_SALICYLIC_ACI | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_PYRAZINAMIDE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_RIFABUTIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_RIFAPENTINE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_STREPTOMYCIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| FINAL_SUSCEPT_TESTING | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| FIRST_ISOLATE_COLLECT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| FIRST_ISOLATE_IS_SPUTUM_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| FIRST_ISOLATE_NOT_SPUTUM | 2 | 1 | 50.0% | NEW | - | `NULL` → `Liver` |
| HOMELESS_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| IGRA_COLLECT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| IGRA_RESULT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Negative` |
| IGRA_TEST_TY | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB152-VAL` |
| IMMIGRATION_STATUS_AT_US_ENTRY | 2 | 1 | 50.0% | NEW | - | `NULL` → `Refugee` |
| INIT_DRUG_REG_CALC | 2 | 1 | 50.0% | NEW | - | `9` → `0` |
| INIT_REGIMEN_AMIKACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_CAPREOMYCIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_CIPROFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_CYCLOSERINE | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_ETHAMBUTOL | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_ETHIONAMIDE | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_ISONIAZID | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_KANAMYCIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_LEVOFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_MOXIFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_OFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_OTHER_1 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB189-VAL` |
| INIT_REGIMEN_OTHER_1_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_OTHER_2 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB191-VAL` |
| INIT_REGIMEN_OTHER_2_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_PYRAZINAMIDE | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_RIFABUTIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_RIFAMPIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_RIFAPENTINE | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_REGIMEN_STREPTOMYCIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INIT_SUSCEPT_AMIKACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_CAPREOMYCIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_CIPROFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_CYCLOSERINE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_ETHAMBUTOL | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_ETHIONAMIDE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_ISONIAZID | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_KANAMYCIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_LEVOFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_MOXIFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_OFLOXACIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_OTHER_1 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB217-VAL` |
| INIT_SUSCEPT_OTHER_1_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_OTHER_2 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB219-VAL` |
| INIT_SUSCEPT_OTHER_2_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_OTHER_QUNINOLONES | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_PA_SALICYLIC_ACID | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_PYRAZINAMIDE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_RIFABUTIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_RIFAMPIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_RIFAPENTINE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_STREPTOMYCIN | 2 | 1 | 50.0% | NEW | - | `NULL` → `Not Done` |
| INIT_SUSCEPT_TESTING_DONE | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| INJECT_DRUG_USE_PAST_YEAR | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| ISOLATE_ACCESSION_NUM | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB193-VAL` |
| ISOLATE_SUBMITTED_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| LINK_REASON_1 | 2 | 1 | 50.0% | NEW | - | `NULL` → `2 - Epidemiologically linked case` |
| LINK_REASON_2 | 2 | 1 | 50.0% | NEW | - | `NULL` → `2 - Epidemiologically linked case` |
| LINK_STATE_CASE_NUM_1 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-LINK-01` |
| LINK_STATE_CASE_NUM_2 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB102-VAL` |
| LONGTERM_CARE_FACIL_RESIDENT | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| LONGTERM_CARE_FACIL_TY | 2 | 1 | 50.0% | NEW | - | `NULL` → `Other Long-Term Care Facility` |
| MOVED_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| MOVE_CITY | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB227-VAL` |
| MOVE_CITY_2 | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB272-VAL` |
| NAA_COLLECT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| NAA_RESULT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Negative` |
| NAA_RESULT_RPT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| NAA_RPT_LAB_TY | 2 | 1 | 50.0% | NEW | - | `NULL` → `Other` |
| NAA_SPEC_IS_SPUTUM_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| NAA_SPEC_NOT_SPUTUM | 2 | 1 | 50.0% | NEW | - | `NULL` → `Liver` |
| NONINJECT_DRUG_USE_PAST_YEAR | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| NO_CONV_DOC_OTHER_REASON | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB223-VAL` |
| NO_CONV_DOC_REASON | 2 | 1 | 50.0% | NEW | - | `NULL` → `Died` |
| OCCUPATION_RISK | 2 | 1 | 50.0% | NEW | - | `NULL` → `Retired` |
| OTHER_TB_RISK_FACTORS | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB168-VAL` |
| PATIENT_BIRTH_COUNTRY | 2 | 1 | 50.0% | NEW | - | `NULL` → `UNITED STATES` |
| PATIENT_OUTSIDE_US_GT_2_MONTHS | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| PREVIOUS_DIAGNOSIS_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| PREVIOUS_DIAGNOSIS_YEAR | 2 | 1 | 50.0% | NEW | - | `NULL` → `42` |
| PRIMARY_GUARD_1_BIRTH_COUNTRY | 2 | 1 | 50.0% | NEW | - | `NULL` → `UNITED STATES` |
| PRIMARY_GUARD_2_BIRTH_COUNTRY | 2 | 1 | 50.0% | NEW | - | `NULL` → `UNITED STATES` |
| PRIMARY_REASON_EVALUATED | 2 | 1 | 50.0% | NEW | - | `NULL` → `Abnormal Chest Radiograph` |
| PROVIDER_OVERRIDE_COMMENTS | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB279-VAL` |
| SMR_PATH_CYTO_COLLECT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| SMR_PATH_CYTO_RESULT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Negative` |
| SMR_PATH_CYTO_SITE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Liver` |
| SPUTUM_CULTURE_CONV_DOCUMENTED | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| SPUTUM_CULTURE_RESULT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Negative` |
| SPUTUM_CULT_COLLECT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| SPUTUM_CULT_RESULT_RPT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| SPUTUM_CULT_RPT_LAB_TY | 2 | 1 | 50.0% | NEW | - | `NULL` → `Other` |
| SPUTUM_SMEAR_COLLECT_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| SPUTUM_SMEAR_RESULT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Negative` |
| STATUS_AT_DIAGNOSIS | 2 | 1 | 50.0% | NEW | - | `NULL` → `Dead` |
| TB_SPUTUM_CULTURE_NEGATIVE_DAT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| TB_VERCRIT_CALC_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `FALSE` |
| THERAPY_EXTEND_GT_12_OTHER | 2 | 1 | 50.0% | NEW | - | `NULL` → `TB-TUB236-VAL` |
| THERAPY_STOP_CAUSE_OF_DEATH | 2 | 1 | 50.0% | NEW | - | `NULL` → `Related to TB disease` |
| THERAPY_STOP_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| THERAPY_STOP_REASON | 2 | 1 | 50.0% | NEW | - | `NULL` → `Completed Therapy` |
| TRANSNATIONAL_REFERRAL_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| TST_MM_INDURATION | 2 | 1 | 50.0% | NEW | - | `NULL` → `42` |
| TST_PLACED_DATE | 2 | 1 | 50.0% | NEW | - | `NULL` → `Apr  5 2026 12:00AM` |
| TST_RESULT | 2 | 1 | 50.0% | NEW | - | `NULL` → `Negative` |
| US_BORN_IND | 2 | 1 | 50.0% | NEW | - | `NULL` → `No` |
| D_TB_PAM_KEY | 2 | 2 | 100.0% | IGNORED | IGN-key_offset-ALL | `1` → `2`; `2` → `3` |

### `D_VAR_PAM`

- Presence: `both`
- Key columns: VAR_PAM_UID
- Row counts: RDB=1, RDB_MODERN=1
- Keys: matched=1, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| PATIENT_BIRTH_COUNTRY | 1 | 1 | 100.0% | NEW | - | `Canada` → `124` |
| D_VAR_PAM_KEY | 1 | 1 | 100.0% | IGNORED | IGN-key_offset-ALL | `1` → `2` |

### `HEP100`

- Presence: `both`
- Key columns: PATIENT_LOCAL_ID
- Row counts: RDB=1, RDB_MODERN=1
- Keys: matched=1, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| REFRESH_DATETIME | 1 | 1 | 100.0% | NEW | - | `Jun  8 2026  7:38PM` → `Jun  8 2026  7:35PM` |
| INVESTIGATION_KEY | 1 | 1 | 100.0% | IGNORED | IGN-key_offset-ALL | `14` → `17` |

### `INVESTIGATION`

- Presence: `both`
- Key columns: INV_LOCAL_ID
- Row counts: RDB=33, RDB_MODERN=33
- Keys: matched=32, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| CITY_COUNTY_CASE_NBR | 32 | 7 | 21.9% | NEW | - | `GA-2026-STATE-22001000` → `NULL`; `GA-2026-STATE-22002000` → `NULL`; `GA-2026-STATE-22003000` → `NULL`; (+4 more) |
| CURR_PROCESS_STATE | 32 | 2 | 6.2% | NEW | - | `OPEN-NEW` → `NULL`; `OPEN-NEW` → `NULL` |
| DAYCARE_ASSOCIATION_IND | 32 | 1 | 3.1% | NEW | - | `NULL` → `No` |
| DIE_FRM_THIS_ILLNESS_IND | 32 | 3 | 9.4% | NEW | - | `D` → `NULL`; `C` → `NULL`; `D` → `NULL` |
| FOOD_HANDLR_IND | 32 | 1 | 3.1% | NEW | - | `NULL` → `No` |
| HSPTLIZD_IND | 32 | 1 | 3.1% | NEW | - | `NULL` → `Yes` |
| HSPTL_ADMISSION_DT | 32 | 1 | 3.1% | NEW | - | `NULL` → `Mar 25 2026  8:00AM` |
| HSPTL_DISCHARGE_DT | 32 | 1 | 3.1% | NEW | - | `NULL` → `Apr  2 2026 12:00PM` |
| HSPTL_DURATION_DAYS | 32 | 1 | 3.1% | NEW | - | `NULL` → `8` |
| IMPORT_FRM_CITY | 32 | 1 | 3.1% | NEW | - | `NULL` → `Atlanta` |
| IMPORT_FRM_CNTRY | 32 | 1 | 3.1% | NEW | - | `NULL` → `United States` |
| IMPORT_FRM_CNTRY_CD | 32 | 1 | 3.1% | NEW | - | `NULL` → `840` |
| IMPORT_FRM_CNTY | 32 | 1 | 3.1% | NEW | - | `NULL` → `Fulton County` |
| IMPORT_FRM_CNTY_CD | 32 | 1 | 3.1% | NEW | - | `NULL` → `13121` |
| IMPORT_FRM_STATE | 32 | 1 | 3.1% | NEW | - | `NULL` → `GA` |
| IMPORT_FRM_STATE_CD | 32 | 1 | 3.1% | NEW | - | `NULL` → `13` |
| INV_ASSIGNED_DT | 32 | 1 | 3.1% | NEW | - | `NULL` → `Apr  1 2026 12:00AM` |
| INV_COMMENTS | 32 | 2 | 6.2% | NEW | - | `Tier 1 v2 investigation comments â€” ex…` → `Tier 1 v2 investigation comments — exer…`; `TB R4-K dimensional-tail investigation …` → `TB R4-K dimensional-tail investigation …` |
| INV_STATE_CASE_ID | 32 | 29 | 90.6% | NEW | - | `CAS20000100GA01` → `NULL`; `CAS20050010GA01` → `NULL`; `CAS22001000GA01` → `NULL`; (+17 more) |
| JURISDICTION_NM | 32 | 1 | 3.1% | NEW | - | `1` → `NULL` |
| LEGACY_CASE_ID | 32 | 7 | 21.9% | NEW | - | `FULTON-2026-CITY-22001000` → `NULL`; `FULTON-2026-CITY-22002000` → `NULL`; `FULTON-2026-CITY-22003000` → `NULL`; (+4 more) |
| OUTBREAK_NAME_DESC | 32 | 8 | 25.0% | NEW | - | `V2 Hepatitis Outbreak` → `NULL`; `Cluster 22001000` → `NULL`; `Cluster 22003000` → `NULL`; (+5 more) |
| PATIENT_PREGNANT_IND | 32 | 1 | 3.1% | NEW | - | `NULL` → `No` |
| REFERRAL_BASIS | 32 | 1 | 3.1% | NEW | - | `AI` → `NULL` |
| INVESTIGATION_KEY | 32 | 30 | 93.8% | IGNORED | IGN-key_offset-ALL | `4` → `7`; `5` → `8`; `6` → `9`; (+17 more) |

### `LAB100`

- Presence: `both`
- Key columns: LAB_RPT_LOCAL_ID
- Row counts: RDB=5, RDB_MODERN=5
- Keys: matched=5, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| PROGRAM_AREA_CD | 5 | 3 | 60.0% | NEW | - | `VPD` → `NULL`; `VPD` → `NULL`; `VPD` → `NULL` |
| PROGRAM_AREA_DESC | 5 | 3 | 60.0% | NEW | - | `VPD` → `NULL`; `VPD` → `NULL`; `VPD` → `NULL` |
| INVESTIGATION_KEYS | 5 | 2 | 40.0% | IGNORED | IGN-key_offset-INVESTIGATION_KEYS | `4` → `1`; `7` → `10` |
| PATIENT_KEY | 5 | 3 | 60.0% | IGNORED | IGN-key_offset-ALL | `3` → `4`; `3` → `4`; `3` → `4` |
| RDB_LAST_REFRESH_TIME | 5 | 5 | 100.0% | IGNORED | IGN-env_timestamp-LAST_REFRESH_TIME | `Jun  8 2026  7:38PM` → `Jun  8 2026  7:34PM`; `Jun  8 2026  7:38PM` → `Jun  8 2026  7:35PM`; `Jun  8 2026  7:38PM` → `Jun  8 2026  7:35PM`; (+2 more) |
| RESULTED_LAB_TEST_KEY | 5 | 5 | 100.0% | IGNORED | IGN-key_offset-ALL | `363` → `5`; `400` → `42`; `402` → `44`; (+2 more) |

### `LAB_RESULT_VAL`

- Presence: `both`
- Key columns: LAB_TEST_UID
- Row counts: RDB=40, RDB_MODERN=77 (differs)
- Keys: matched=40, rdb-only=0, modern-only=37

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| LAB_RESULT_TXT_VAL | 40 | 4 | 10.0% | NEW | - | `NULL` → `Tier 1 Morbidity v2 — other-specify fre…`; `NULL` → `Morb-datamart enrichment comments narra…`; `NULL` → `Suspect foodborne; ill at restaurant.`; (+1 more) |
| RDB_LAST_REFRESH_TIME | 40 | 40 | 100.0% | IGNORED | IGN-env_timestamp-LAST_REFRESH_TIME | `Jun  8 2026  7:38PM` → `Jun  8 2026  7:35PM`; `Jun  8 2026  7:38PM` → `Jun  8 2026  7:34PM`; `Jun  8 2026  7:38PM` → `Jun  8 2026  7:34PM`; (+17 more) |
| TEST_RESULT_GRP_KEY | 40 | 36 | 90.0% | IGNORED | IGN-key_offset-ALL | `37` → `2`; `25` → `3`; `26` → `4`; (+17 more) |
| TEST_RESULT_VAL_KEY | 40 | 36 | 90.0% | IGNORED | IGN-key_offset-ALL | `37` → `2`; `25` → `3`; `26` → `4`; (+17 more) |

### `LAB_TEST`

- Presence: `both`
- Key columns: LAB_TEST_UID
- Row counts: RDB=45, RDB_MODERN=85 (differs)
- Keys: matched=45, rdb-only=0, modern-only=40

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| ELR_IND | 45 | 32 | 71.1% | NEW | - | `NULL` → `Y`; `NULL` → `Y`; `NULL` → `Y`; (+17 more) |
| JURISDICTION_CD | 45 | 35 | 77.8% | NEW | - | `NULL` → `130001`; `NULL` → `130001`; `NULL` → `130001`; (+17 more) |
| JURISDICTION_NM | 45 | 35 | 77.8% | NEW | - | `NULL` → `Fulton County`; `NULL` → `Fulton County`; `NULL` → `Fulton County`; (+17 more) |
| LAB_RPT_CREATED_BY | 45 | 35 | 77.8% | NEW | - | `NULL` → `10009282`; `NULL` → `10009282`; `NULL` → `10009282`; (+17 more) |
| LAB_RPT_CREATED_DT | 45 | 35 | 77.8% | NEW | - | `NULL` → `Apr  4 2026 12:00AM`; `NULL` → `Apr  4 2026 12:00AM`; `NULL` → `Apr  4 2026 12:00AM`; (+17 more) |
| LAB_RPT_LOCAL_ID | 45 | 35 | 77.8% | NEW | - | `NULL` → `OBS20080010GA01`; `NULL` → `OBS20080010GA01`; `NULL` → `OBS20080010GA01`; (+17 more) |
| LAB_RPT_RECEIVED_BY_PH_DT | 45 | 35 | 77.8% | NEW | - | `NULL` → `Apr  4 2026 10:00AM`; `NULL` → `Apr  4 2026 10:00AM`; `NULL` → `Apr  4 2026 10:00AM`; (+17 more) |
| LAB_TEST_DT | 45 | 35 | 77.8% | NEW | - | `NULL` → `Apr  4 2026  8:00AM`; `NULL` → `Apr  4 2026  8:00AM`; `NULL` → `Apr  4 2026  8:00AM`; (+17 more) |
| OID | 45 | 35 | 77.8% | NEW | - | `NULL` → `20080010`; `NULL` → `20080010`; `NULL` → `20080010`; (+17 more) |
| PARENT_TEST_NM | 45 | 35 | 77.8% | NEW | - | `NULL` → `Hepatitis A, acute`; `NULL` → `Hepatitis A, acute`; `NULL` → `Hepatitis A, acute`; (+17 more) |
| PARENT_TEST_PNTR | 45 | 35 | 77.8% | NEW | - | `1` → `20080010`; `1` → `20080010`; `1` → `20080010`; (+17 more) |
| ROOT_ORDERED_TEST_NM | 45 | 35 | 77.8% | NEW | - | `NULL` → `Hepatitis A, acute`; `NULL` → `Hepatitis A, acute`; `NULL` → `Hepatitis A, acute`; (+17 more) |
| ROOT_ORDERED_TEST_PNTR | 45 | 35 | 77.8% | NEW | - | `1` → `20080010`; `1` → `20080010`; `1` → `20080010`; (+17 more) |
| SPECIMEN_COLLECTION_DT | 45 | 35 | 77.8% | NEW | - | `NULL` → `Apr  3 2026  6:00PM`; `NULL` → `Apr  3 2026  6:00PM`; `NULL` → `Apr  3 2026  6:00PM`; (+17 more) |
| SPECIMEN_SITE | 45 | 16 | 35.6% | NEW | - | `NULL` → `WBLD`; `NULL` → `WBLD`; `NULL` → `WBLD`; (+13 more) |
| SPECIMEN_SITE_DESC | 45 | 16 | 35.6% | NEW | - | `NULL` → `Whole blood`; `NULL` → `Whole blood`; `NULL` → `Whole blood`; (+13 more) |
| LAB_RPT_LAST_UPDATE_BY | 45 | 35 | 77.8% | KNOWN_BUG | BUG-LAB_TEST-LAB_RPT_LAST_UPDATE_BY | `NULL` → `10009282`; `NULL` → `10009282`; `NULL` → `10009282`; (+17 more) |
| LAB_TEST_KEY | 45 | 45 | 100.0% | KNOWN_BUG | BUG-LAB_TEST-LAB_TEST_KEY_OFFSET | `362` → `4`; `363` → `5`; `364` → `6`; (+17 more) |
| LAB_RPT_LAST_UPDATE_DT | 45 | 35 | 77.8% | IGNORED | IGN-env_timestamp-LAST_UPDATE_DT | `NULL` → `Apr  4 2026 12:00AM`; `NULL` → `Apr  4 2026 12:00AM`; `NULL` → `Apr  4 2026 12:00AM`; (+17 more) |
| RDB_LAST_REFRESH_TIME | 45 | 45 | 100.0% | IGNORED | IGN-env_timestamp-LAST_REFRESH_TIME | `Jun  8 2026  7:38PM` → `Jun  8 2026  7:34PM`; `Jun  8 2026  7:38PM` → `Jun  8 2026  7:34PM`; `Jun  8 2026  7:38PM` → `Jun  8 2026  7:35PM`; (+17 more) |

### `NOTIFICATION`

- Presence: `both`
- Key columns: NOTIFICATION_LOCAL_ID
- Row counts: RDB=4, RDB_MODERN=3 (differs)
- Keys: matched=3, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| NOTIFICATION_COMMENTS | 3 | 2 | 66.7% | NEW | - | `Tier 1 v2 notification comments â€” exe…` → `Tier 1 v2 notification comments — exerc…`; `Summary report case comments â€” exerci…` → `Summary report case comments — exercise…` |

### `TREATMENT`

- Presence: `both`
- Key columns: TREATMENT_LOCAL_ID
- Row counts: RDB=7, RDB_MODERN=7
- Keys: matched=6, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| TREATMENT_COMMENTS | 6 | 1 | 16.7% | NEW | - | `Tier 1 Treatment v2 â€” clinician comme…` → `Tier 1 Treatment v2 — clinician comment…` |

## Known-bug differences

### `D_INTERVIEW_NOTE`

- Presence: `both`
- Key columns: NBS_ANSWER_UID
- Row counts: RDB=1, RDB_MODERN=1
- Keys: matched=1, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| D_INTERVIEW_NOTE_KEY | 1 | 1 | 100.0% | KNOWN_BUG | BUG-D_INTERVIEW_NOTE-not_populated | `2` → `3` |

### `LAB_RESULT_COMMENT`

- Presence: `both`
- Key columns: LAB_TEST_UID
- Row counts: RDB=5, RDB_MODERN=5
- Keys: matched=5, rdb-only=0, modern-only=0

| Column | Compared | Mismatches | Rate | Verdict | Rule | Sample (rdb → modern) |
| --- | ---: | ---: | ---: | --- | --- | --- |
| LAB_RESULT_COMMENT_KEY | 5 | 5 | 100.0% | KNOWN_BUG | BUG-LAB_RESULT_COMMENT-modern_only | `2` → `3`; `3` → `4`; `4` → `5`; (+2 more) |
| RDB_LAST_REFRESH_TIME | 5 | 5 | 100.0% | KNOWN_BUG | BUG-LAB_RESULT_COMMENT-modern_only | `Jun  8 2026  7:38PM` → `Jun  8 2026  7:35PM`; `Jun  8 2026  7:38PM` → `Jun  8 2026  7:35PM`; `Jun  8 2026  7:38PM` → `Jun  8 2026  7:35PM`; (+2 more) |
| RESULT_COMMENT_GRP_KEY | 5 | 5 | 100.0% | KNOWN_BUG | BUG-LAB_RESULT_COMMENT-modern_only | `2` → `3`; `3` → `4`; `4` → `5`; (+2 more) |

## Expected differences

_None._

## Skipped / ignored tables

_None._
