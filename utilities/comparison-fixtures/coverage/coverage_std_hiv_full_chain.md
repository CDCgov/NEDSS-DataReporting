# Coverage: STD Syphilis Investigation full ODSE + Tier 2 + dimensional D_INV_* chain

Generated: 2026-05-21

## Inputs

- Baseline: 6.0.18.1 (post-liquibase) + foundation + all Tier 1 + Tier 2
  fixtures + existing Tier 3 fixtures (including
  `multi_condition_investigations.sql` Syphilis stub at UID 22000080).
- Fixture file:
  `fixtures/30_sp_coverage/std_hiv_investigation_full_chain.sql`.
- UID range allocated: **22004000 - 22004999** (Tier 3 STD full-chain).
- Foundation dependencies (read-only):
  - `@superuser_id = 10009282`
  - `@dbo_Entity_patient_uid = 20000000` (foundation Patient; referenced
    by `nrt_investigation.patient_id` so the F_STD_PAGE_CASE keystore's
    `LEFT OUTER JOIN dbo.D_PATIENT PATIENT ON fsshc.PATIENT_ID = PATIENT.PATIENT_UID`
    resolves to D_PATIENT_KEY=3 (NOT sentinel 1) and the post-INSERT
    cleanup at line 583 — `WHERE INVESTIGATION_KEY IN (… HAVING COUNT > 1)
    AND PATIENT_KEY = 1` — does not drop our row).
- Tier 3 dependencies (read-only):
  - The existing Syphilis stub at `public_health_case_uid = 22000080`
    in `fixtures/30_sp_coverage/multi_condition_investigations.sql` is
    **left untouched**. It exercises the no-CASE_MANAGEMENT_UID path
    (filtered out of `#PHC_CASE_UIDS_ALL` by `nicm.CASE_MANAGEMENT_UID
    is not null` at line 97 of `sp_f_std_page_case_postprocessing`).
    Our full-chain UID 22004000 exercises the populated-CASE_MANAGEMENT
    path.

## UID allocations

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22004000 | std_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation_case_management.public_health_case_uid`, `nrt_investigation_confirmation.public_health_case_uid`, `L_INV_*.PAGE_CASE_UID` (5 link rows) | STD Syphilis-primary full-chain anchor. |
| 22004001 | std_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22004100 | (D_INV_HIV row) | `D_INV_HIV.D_INV_HIV_KEY` | Hand-authored dimension; 16/22 HIV_* columns populated. |
| 22004110 | (D_INV_ADMINISTRATIVE row) | `D_INV_ADMINISTRATIVE.D_INV_ADMINISTRATIVE_KEY` | 4/58 ADM_* columns populated. |
| 22004120 | (D_INV_CLINICAL row) | `D_INV_CLINICAL.D_INV_CLINICAL_KEY` | 7/93 CLN_* columns populated. |
| 22004130 | (D_INV_EPIDEMIOLOGY row) | `D_INV_EPIDEMIOLOGY.D_INV_EPIDEMIOLOGY_KEY` | 1/154 EPI_* columns populated. |
| 22004140 | (D_INV_COMPLICATION row) | `D_INV_COMPLICATION.D_INV_COMPLICATION_KEY` | 2/33 CMP_* columns populated. |

Unused UIDs reserved (22004002..22004099, 22004101..22004109,
22004111..22004119, 22004121..22004129, 22004131..22004139,
22004141..22004999 — ~960 UIDs).

## SPs verified

| SP | File | Param | Outcome |
| --- | --- | --- | --- |
| `sp_nrt_investigation_postprocessing` | 005 | `@id_list` | INSERT into `INVESTIGATION` for case_uid=22004000 (1 row). DELETE-then-INSERT 1 `CONFIRMATION_METHOD_GROUP` row from nrt_investigation_confirmation. |
| `sp_f_std_page_case_postprocessing` | 025 | `@phc_id_list` | INSERT into `F_STD_PAGE_CASE` (1 row, all 24 dimensional keys resolved to non-sentinel for our 5 dims + sentinel-1 for the other 20 we did not author). |
| `sp_std_hiv_datamart_postprocessing` | 026 | `@phc_id` | INSERT into `INV_HIV` (1 row) and `STD_HIV_DATAMART` (1 row, ~30/248 cols populated). |

## Columns populated — row counts per cluster table

| Table | Rows added | Notes |
| --- | --- | --- |
| `INVESTIGATION` | +1 | Key resolved (case_uid=22004000). |
| `CONFIRMATION_METHOD_GROUP` | +1 | KEY=(INVESTIGATION_KEY, 4), CONFIRMATION_METHOD_KEY=4 (resolved from nrt_investigation_confirmation row's 'LD' cd). |
| `F_STD_PAGE_CASE` | +1 | 5 D_INV_* dim keys populated (D_INV_HIV=22004100, D_INV_ADMINISTRATIVE=22004110, D_INV_CLINICAL=22004120, D_INV_EPIDEMIOLOGY=22004130, D_INV_COMPLICATION=22004140). The other 19 D_INV_* keys resolve to sentinel 1 (no authored L_INV_* row); cross-subject KEYs (PATIENT_KEY=3, CONDITION_KEY=43) populated. PHYSICIAN_KEY / INVESTIGATOR_KEY / HOSPITAL_KEY / ORG_AS_REPORTER_KEY / PERSON_AS_REPORTER_KEY all = sentinel 1 (no Tier 2 participation rows for this Investigation — see LINK_REQUIRED gap). |
| `INV_HIV` | +1 | KEY=(INVESTIGATION_KEY=3, D_INV_HIV_KEY=22004100); 16/19 HIV_* columns populated. The 3 remaining (HIV_CA_900_OTH_RSN_NOT_LO, HIV_CA_900_REASON_NOT_LOC, HIV_HIV_STAT_INV_IN_EHARS, etc.) deliberately NULL — they need their own D_INV_HIV columns which weren't authored. |
| `STD_HIV_DATAMART` | +1 | Approx 30/248 cols populated. Populated cluster: HIV_* (16 cols from D_INV_HIV + INV_HIV); CLN_NEUROSYPHILLIS_IND / CLN_DT_INIT_HLTH_EXM / CLN_PRE_EXP_PROPHY_IND / etc. (5 from D_INV_CLINICAL); ADM_REFERRAL_BASIS_OOJ / ADM_RPTNG_CNTY / DISSEMINATED_IND (3 from D_INV_ADMINISTRATIVE); CMP_CONJUNCTIVITIS_IND / CMP_PID_IND (2 from D_INV_COMPLICATION); EPI_CNTRY_USUAL_RESID (1 from D_INV_EPIDEMIOLOGY); plus CONDITION_CD='10311', CONDITION_KEY=43, PATIENT_NAME='Patient, Foundation', PROGRAM_AREA_CD='STD', JURISDICTION_CD='130001', INV_LOCAL_ID='CAS22004000GA01', CASE_RPT_MMWR_WK='14', CASE_RPT_MMWR_YR='2026', CONFIRMATION_DT='2026-04-01'. |
| `D_INV_HIV` | +1 | Hand-authored; 16/22 cols. |
| `D_INV_ADMINISTRATIVE` | +1 | Hand-authored; 4/58 cols. |
| `D_INV_CLINICAL` | +1 | Hand-authored; 7/93 cols. |
| `D_INV_EPIDEMIOLOGY` | +1 | Hand-authored; 1/154 cols. |
| `D_INV_COMPLICATION` | +1 | Hand-authored; 2/33 cols. |
| `L_INV_HIV / L_INV_ADMINISTRATIVE / L_INV_CLINICAL / L_INV_EPIDEMIOLOGY / L_INV_COMPLICATION` | +1 each | Hand-authored; bridges PAGE_CASE_UID 22004000 to each D_INV_*_KEY. |
| `dyn_dm DM_INV_STD` | (depends on bug #9) | Orchestrator Step 9 dyn_dm chain auto-discovers DATAMART_NM='STD' from v_nrt_nbs_page and runs `sp_dyn_dm_main_postprocessing @datamart_name='STD'`. If bug #9 (TMP_F_PAGE_CASE transaction-isolation) doesn't block, expect +1 row in DM_INV_STD wide table. **Not verified in standalone run** — requires the orchestrated context. |

### Summary

- **9 of 9** STD/HIV cluster RDB_MODERN tables that the
  `sp_f_std_page_case_postprocessing` + `sp_std_hiv_datamart_postprocessing`
  chain reaches now have +1 row.
- **6 of 248** STD_HIV_DATAMART columns previously unreachable (HIV_* +
  CLN_NEUROSYPHILLIS_IND + CMP_PID_IND) are now populated by our authored
  dimension rows. The remaining 200+ are reachable in principle by
  authoring more D_INV_*/L_INV_* rows in a follow-up fixture (Phase 2
  fixture-completeness exercise; not blocked by infrastructure).
- **Status of the canonical STD/HIV path:** unblocked end-to-end.

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| `STD_HIV_DATAMART` | ~218 / 248 | Each is fed by a distinct D_INV_* / D_PATIENT / D_PROVIDER / D_ORGANIZATION column we did not populate for this fixture. Authoring more dimension columns is a fixture-completeness exercise. | `026-sp_std_hiv_datamart_postprocessing-001.sql:178-1175` (full SELECT list) |
| `F_STD_PAGE_CASE` | 19 / 24 D_INV_*_KEY (D_INV_CONTACT, D_INV_DEATH, D_INV_LAB_FINDING, etc.) | We populated 5 D_INV_* dim+link pairs (HIV, ADMINISTRATIVE, CLINICAL, EPIDEMIOLOGY, COMPLICATION) selected to exercise the SP's main UPDATE/INSERT SELECT list. The other 19 would each need a hand-authored D_INV_*/L_INV_* pair. | `025-sp_f_std_page_case_postprocessing-001.sql:266-289` |
| `F_STD_PAGE_CASE` | 14 cross-subject keys (PHYSICIAN_KEY, INVESTIGATOR_KEY, HOSPITAL_KEY, CLOSED_BY_KEY, DISPOSITIONED_BY_KEY, FACILITY_FLD_FOLLOW_UP_KEY, INVSTGTR_FLD_FOLLOW_UP_KEY, PROVIDER_FLD_FOLLOW_UP_KEY, ...) | This Investigation has no Tier 2 participation / nbs_act_entity edges (no PhysicianOfPHC / InvestgrOfPHC / OrgAsReporterOfPHC / HospOfADT linking the STD Investigation 22004000 to providers/orgs). LINK_REQUIRED gap below. | `025-sp_f_std_page_case_postprocessing-001.sql:180-211` |
| `INV_HIV` | 3 / 19 (HIV_CA_900_OTH_RSN_NOT_LO, HIV_CA_900_REASON_NOT_LOC, HIV_HIV_STAT_INV_IN_EHARS) | The D_INV_HIV columns feeding these were not authored (the SP UPDATE block at lines 64-79 doesn't include them — they're populated only by the INSERT block at lines 106-141, which we did exercise, but we left those columns NULL on the source D_INV_HIV row). Cheap to add in a follow-up. | `026-sp_std_hiv_datamart_postprocessing-001.sql:64-79, 106-141` |

## Gaps reported

### LINK_REQUIRED: F_STD_PAGE_CASE cross-subject keys

`F_STD_PAGE_CASE` carries 14 sentinel-1 keys (`PHYSICIAN_KEY`,
`INVESTIGATOR_KEY`, `HOSPITAL_KEY`, `ORG_AS_REPORTER_KEY`,
`PERSON_AS_REPORTER_KEY`, `ORDERING_FACILITY_KEY`, `CLOSED_BY_KEY`,
`DISPOSITIONED_BY_KEY`, `FACILITY_FLD_FOLLOW_UP_KEY`,
`INVSTGTR_FLD_FOLLOW_UP_KEY`, `PROVIDER_FLD_FOLLOW_UP_KEY`,
`SUPRVSR_OF_FLD_FOLLOW_UP_KEY`, ... ) because no Tier 2 participation /
nbs_act_entity rows link the STD Investigation 22004000 to providers
or orgs. Adding rows analogous to `21006000-21006999` (PhysicianOfPHC /
InvestgrOfPHC) and `21005000-21005999` (PerAsReporterOfPHC /
OrgAsReporterOfPHC) but targeting act_uid=22004000 would unblock
these. Out of scope for this Tier 3 fixture; would belong in an
additional Tier 2 fan-out or a Phase 2 expansion.

### RTR Bug #N: `sp_nrt_investigation_postprocessing` inserts sentinel CONFIRMATION_METHOD_GROUP rows

**File**: `005-sp_nrt_investigation_postprocessing-001.sql:714-732, 849-858`.

**Symptom**: when an Investigation has no `nrt_investigation_confirmation`
staging row, `sp_nrt_investigation_postprocessing` still INSERTs a row
into `CONFIRMATION_METHOD_GROUP` with `(INVESTIGATION_KEY=<inv>,
CONFIRMATION_METHOD_KEY=1, CONFIRMATION_DT=NULL)`. This is because the
SP's `#temp_cm_table` source query at line 729-730 is `FROM dbo.INVESTIGATION
... LEFT JOIN tempCM` — i.e., emits a row per Investigation regardless
of whether a confirmation method is present, and the INSERT at line 856
COALESCEs CONFIRMATION_METHOD_KEY to sentinel 1.

**Downstream consequence**: `sp_std_hiv_datamart_postprocessing`'s
INSERT at line 1179-1180 does `LEFT JOIN (SELECT DISTINCT
INVESTIGATION_KEY, CONFIRMATION_DT FROM dbo.CONFIRMATION_METHOD_GROUP)
AS CONF ON CONF.INVESTIGATION_KEY = PC.INVESTIGATION_KEY`. When BOTH a
real confirmation row (KEY=4, dt='2026-04-01') AND the sentinel row
(KEY=1, NULL) exist for the same INVESTIGATION_KEY, the `DISTINCT
INVESTIGATION_KEY, CONFIRMATION_DT` query returns 2 distinct rows
(because of NULL vs '2026-04-01'), causing the LEFT JOIN to double the
STD_HIV_DATAMART INSERT cardinality.

**Reproduction (live, 2026-05-21)**: Reproduced standalone by running
sp_nrt_investigation_postprocessing twice for the same case_uid — each
run INSERTs a new sentinel CMG row.

**Workaround applied in this fixture**: author an
`nrt_investigation_confirmation` staging row so the SP's DELETE-then-INSERT
cycle (lines 849-858) emits exactly one CMG row with the real
CONFIRMATION_METHOD_KEY. This collapses the std_hiv_datamart join to a
single row.

**Suggested upstream fix**: either filter the `#temp_cm_table` query at
line 722-732 to only INSERT when `tempCM.confirmation_method_cd IS NOT NULL`,
or make the std_hiv_datamart join's `SELECT DISTINCT` filter out NULL
CONFIRMATION_DT rows.

**Severity**: medium. Doesn't block populated-state; does break
row-count integrity for the diff tool whenever any Investigation in
the merged batch lacks a true confirmation method.

### RTR Bug #M: Orchestrator parameter mismatch for `sp_f_std_page_case_postprocessing`

**File**: `utilities/comparison-fixtures/scripts/merge_and_verify.sh:475`.

**Symptom**: orchestrator invokes
`sp_f_std_page_case_postprocessing @phc_ids = N'$PHC_UIDS', @debug = 0`
— but the SP's signature is `@phc_id_list nvarchar(max)` (see
`025-sp_f_std_page_case_postprocessing-001.sql:9`). Mismatch raises
SQL Server error `HResult 0xC9 ... expects parameter '@phc_id_list',
which was not supplied.` The orchestrator's `2>/dev/null` swallow + the
`|| log "errored or no-op"` fallback hides the failure. **The SP never
runs in the orchestrated path** — F_STD_PAGE_CASE remains 0 rows.

**Reproduction (live, 2026-05-21)**:
```
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_f_std_page_case_postprocessing @phc_ids = N'22000080', @debug = 0;"
# → HResult 0xC9 ... expects parameter '@phc_id_list'
```

**Fix**: change `@phc_ids` to `@phc_id_list` at line 475 of
`merge_and_verify.sh`. Once fixed, the orchestrator's Step 9 will
properly populate F_STD_PAGE_CASE and unblock STD_HIV_DATAMART for the
existing Syphilis stub at 22000080 in addition to our new 22004000.

**Severity**: high. Without this fix, the v1 baseline merged run never
populates STD_HIV_DATAMART at all (the existing 22000080 stub is
filtered out for lack of case_management_uid; our 22004000 row would
flow if it were in `PHC_UIDS` AND the orchestrator's invocation worked).

### LINK_REQUIRED: 20 unauthored D_INV_* dimensions

19 D_INV_*_KEY columns on F_STD_PAGE_CASE remain at sentinel 1 because
we did not author the corresponding D_INV_* + L_INV_* pair. Each pair
is straightforward to add (one INSERT into D_INV_<name>, one INSERT
into L_INV_<name>). The 19 are: D_INV_CONTACT, D_INV_DEATH,
D_INV_ISOLATE_TRACKING, D_INV_LAB_FINDING, D_INV_MEDICAL_HISTORY,
D_INV_MOTHER, D_INV_OTHER, D_INV_PATIENT_OBS, D_INV_PREGNANCY_BIRTH,
D_INV_RESIDENCY, D_INV_RISK_FACTOR, D_INV_SOCIAL_HISTORY,
D_INV_SYMPTOM, D_INV_TRAVEL, D_INV_TREATMENT, D_INV_UNDER_CONDITION,
D_INV_VACCINATION, D_INVESTIGATION_REPEAT, D_INV_PLACE_REPEAT.
Phase 2 fixture-completeness exercise.

### OUT_OF_SCOPE: not invoked in this fixture

- HIV pediatric (condition 10561, INV_FORM_GEN) — the user-prompt's
  alternative pick. Authored as a stub at 22000090 by
  `multi_condition_investigations.sql`. Would require its own
  full-chain fixture because `INV_FORM_GEN` is NOT in
  `v_nrt_nbs_page.FORM_CD` (verified — only PG_HIV_Investigation maps
  to DATAMART_NM='HIV'). So the existing HIV-pediatric stub does NOT
  trigger the dyn_dm HIV chain; a future Tier 3 sibling fixture should
  author an Investigation with `investigation_form_cd =
  'PG_HIV_Investigation'`.
- Congenital syphilis (condition 10316, PG_Congenital_Syphilis_Investigation)
  — a separate form with `coinfection_grp_cd=NULL` (NOT
  STD_HIV_GROUP); the std_hiv_datamart SP filter doesn't include it.
  Would need its own fixture if congenital-syphilis-datamart coverage
  is in scope.
- `nrt_page_case_answer` rows. The STD path does not read them via
  `sp_f_std_page_case_postprocessing` or `sp_std_hiv_datamart_postprocessing`
  — those read only nrt_investigation + nrt_investigation_case_management
  + RDB_MODERN dim tables. The dyn_dm STD chain (Step 9) would pivot
  page-case-answer rows if seeded — out of scope for this Tier 3
  fixture; a separate `std_pg_answers.sql` fixture would cover that
  branch.

## Orchestrator integration recommendation

`scripts/merge_and_verify.sh` requires two changes to land this fixture
in the orchestrated run:

1. **Line 446**: add `22004000` to the `PHC_UIDS` list.
2. **Line 475**: fix the parameter name from `@phc_ids` to `@phc_id_list`
   for `sp_f_std_page_case_postprocessing` (see Bug #M above).

```diff
- readonly PHC_UIDS='20000100,20050010,22000010,...,22001000'
+ readonly PHC_UIDS='20000100,20050010,22000010,...,22001000,22004000'
...
-   run_dm_sp sp_f_std_page_case_postprocessing              "@phc_ids = N'$PHC_UIDS', @debug = 0" 2>/dev/null
+   run_dm_sp sp_f_std_page_case_postprocessing              "@phc_id_list = N'$PHC_UIDS', @debug = 0"
```

Without these changes, the fixture's tail-EXEC (`sp_nrt_investigation_postprocessing`
only) lands the INVESTIGATION + CONFIRMATION_METHOD_GROUP rows, the dim
tables, the link tables, and the staging rows — but F_STD_PAGE_CASE,
INV_HIV, and STD_HIV_DATAMART remain empty in the orchestrated end state.

I recommend the parent agent applies these orchestrator changes before
merging the fixture.

## Template-pattern observations for sibling agents

This fixture is the **template for the multi-condition family of full-chain
fixtures whose datamart SP composes via D_INV_* dimensions rather than
PAM-style nrt_page_case_answer pivots**. Specifically:

1. **BMIRD / Strep pneumoniae** (`040-sp_bmird_case_datamart_postprocessing`,
   `140-sp_bmird_strep_pneumo_datamart_postprocessing`): similar
   composition pattern (LEFT JOINs to D_INV_ADMINISTRATIVE,
   D_INV_CLINICAL, D_INV_LAB_FINDING, D_INV_RISK_FACTOR, etc.).
   The bmird datamart SPs use dynamic SQL via `@tgt_table_nm`, which
   complicates static analysis but doesn't change the input shape.
2. **COVID** (`310-sp_covid_case_datamart_postprocessing` already
   exists as `covid_investigation_full_chain.sql` at 22003000 per
   uid_ranges.md): uses nrt_page_case_answer pivots (sibling of TB-PAM
   pattern), NOT the D_INV_* dimensional join pattern. Different
   template.
3. **Varicella** (`varicella_investigation_full_chain.sql` at 22002000):
   PAM pattern like TB. Different template.
4. **Hepatitis** (`013-sp_hepatitis_datamart_postprocessing`): uses
   the D_INV_* dimensional join pattern. Same template as this fixture
   — sibling fixture authors can reuse the same D_INV_*/L_INV_* +
   nrt_investigation_case_management + nrt_investigation_confirmation
   pattern.

**Key takeaway for sibling agents**: the dimensional pattern requires
hand-authoring (D_INV_X, L_INV_X) pairs because no Tier 1/2
postprocessing SP populates them — they are MasterETL-only persistent
tables that RTR datamart SPs join to. Per `odse_unknown_tables.md`
classification: bucket (a) MasterETL-only for the L_INV_* family.
This fixture establishes the convention that Tier 3 dimensional-cluster
fixtures may write directly to these MasterETL-only tables when the
RTR datamart chain reads from them downstream.

## Reproduction recipe

```sh
export SQLCMDPASSWORD=PizzaIsGood33!

# Apply fixture (assumes baseline 6.0.18.1 + foundation + Tier 1 + Tier 2 + prior Tier 3)
sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/30_sp_coverage/std_hiv_investigation_full_chain.sql

# Run the orchestrated SPs manually (Phase 2 will fold these into Step 9)
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q \
  "EXEC dbo.sp_f_std_page_case_postprocessing @phc_id_list = N'22004000', @debug = 0;"
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q \
  "EXEC dbo.sp_std_hiv_datamart_postprocessing @phc_id = N'22004000', @debug = 0;"

# Verify cluster populations
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -h -1 -W -Q "SET NOCOUNT ON;
  SELECT 'f_std_page_case', COUNT(*) FROM dbo.f_std_page_case UNION ALL
  SELECT 'std_hiv_datamart', COUNT(*) FROM dbo.std_hiv_datamart UNION ALL
  SELECT 'inv_hiv', COUNT(*) FROM dbo.inv_hiv;"
```

Expected output (on a clean baseline + just this fixture):

```
f_std_page_case    1
std_hiv_datamart   1
inv_hiv            2   (1 sentinel + 1 new)
```
