# Functional Tests

## Adding a new functional test

To avoid clashes, each  functional test is assigned 1000 ids. The ids are in ranges higher than 1 000 000 000.  
For example bmirdCase is assigned 1000001000 to 1000001999. (It actually uses only up to 1000001031).  
When adding a new functional test, pick the next available range, and add your test id range to the list below.

## IDs Used by functional tests


| Test                     | Starting ID | Ending ID  |
| ------------------------ | ----------- | ---------- |
| casesBmirdGeneric        | 1000001000  | 1000001031 |
| covidMarkReviewed        | 1000002000  | 1000002013 |
| fullPathSupervisorReview | 1000003000  | 1000003009 |
| interview                | 1000004000  | 1000004005 |
| morbidityReport          | 1000005000  | 1000005027 |
| skipSupervisorReview     | 1000006000  | 1000006030 |
| stdContactTracing        | 1000007000  | 1000007028 |
| elrEColi                 | 1000008000  | 1000008049 |
| stdContactTracingPartTwo | 1000009000  | 1000009028 |
| hivNotificationPlan      | 1000010000  | 1000010004 |
| d_tb_pam                 | 1000011000  | 1000011004 |
| authUserDirectWrite      | 1000012000  | 1000012000 |
| providerDirectWrite      | 1000013000  | 1000013000 |

## Helper tools

Tools to help create functional tests are available in NEDSS-DataReporting/testing-tools.
`trace_db_dual_capture.py` and `validate_rdb_selects.py` are particularly useful in creating test data. `shift_test_ids.py` can be used to change the ids a test is using.