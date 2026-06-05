# L4 — COVID family lineage

Cluster: `COVID_CASE_DATAMART`, `COVID_CONTACT_DATAMART`,
`COVID_VACCINATION_DATAMART`, `INV_SUMM_DATAMART`.

Writing SPs (all `datamart_postprocessing`, no `_event` partner — they read
RDB_MODERN-side staging / dimensions only, per STRATEGY.md "postprocessing SPs
read NRT staging only"):

| SP | File | Target |
| --- | --- | --- |
| `sp_covid_case_datamart_postprocessing` | `routines/310-...` | `COVID_CASE_DATAMART` |
| `sp_covid_contact_datamart_postprocessing` | `routines/315-...` | `COVID_CONTACT_DATAMART` |
| `sp_covid_vaccination_datamart_postprocessing` | `routines/320-...` | `COVID_VACCINATION_DATAMART` |
| `sp_inv_summary_datamart_postprocessing` | `routines/045-...` | `INV_SUMM_DATAMART` |

The three COVID SPs all gate on COVID condition code `'11065'`. The
`INV_SUMM_DATAMART` SP is condition-agnostic (it summarises every active
investigation). The ODSE→staging hop for the COVID case/contact SPs is the
debezium projection of `sp_investigation_event` (056), `sp_patient_event`
(054), `sp_contact_record_event` (069) and `sp_vaccination_event` (071); the
postprocessing SPs themselves never touch `nbs_odse.dbo.*`. `INV_SUMM_DATAMART`
sits one tier further downstream — it reads only RDB_MODERN dimensions/facts
(`INVESTIGATION`, `D_PATIENT`, `D_PROVIDER`, `NOTIFICATION`, the per-condition
`*_CASE` fact tables, `CASE_LAB_DATAMART`, `lab100`), each of which is itself
built by an upstream `sp_nrt_*`/`sp_d_*`/`sp_f_*` SP — so its ODSE roots are
recorded transitively (INVESTIGATION → `nrt_investigation` → ODSE
`public_health_case`).

Live coverage (coverage_merged.md, 2026-05-25 clean run):
`covid_case_datamart` 379/383, `covid_contact_datamart` 89/94,
`covid_vaccination_datamart` 60/60, `inv_summ_datamart` 58/58.

---

## COVID_CASE_DATAMART

Row flow: `sp_covid_case_datamart_postprocessing @phc_uids` builds `#PHC_LIST`
by joining `NRT_INVESTIGATION` to the CSV of PHC UIDs filtered on
`nrtInv.cd = '11065'` (Step 1). It is idempotent: DELETE-then-INSERT per PHC,
and drops `LOG_DEL` rows before insert. It then assembles three static temp
tables and up to five dynamic ones, and finally builds the INSERT itself as
dynamic SQL.

The **statically traceable** columns come from three temp tables:

- `#COVID_CASE_CORE_DATA` (Step 4) — `NRT_INVESTIGATION phc` columns mapped
  near-1:1 to datamart columns (`phc.CD→CONDITION_CD`,
  `phc.JURISDICTION_CD→JURISDICTION_CD`, `phc.ACTIVITY_FROM_TIME→INV_START_DT`,
  `phc.CASE_CLASS_CD→INV_CASE_STATUS`, `phc.MMWR_WEEK/YEAR`, the
  `HOSPITALIZED_*`, `EFFECTIVE_*`, `OUTCOME_CD→DIE_FROM_ILLNESS_IND`, etc.).
  `NRT_INVESTIGATION` is the debezium projection of `sp_investigation_event`,
  whose primary FROM is `nbs_odse.dbo.public_health_case phc` (event SP
  line 335), so the ODSE source for every core column is the same-named
  `public_health_case` column. `NOTIFICATION_SUBMIT_DT / SENT_DT /
  LOCAL_ID` come from `NRT_INVESTIGATION_NOTIFICATION`; `CONFIRMATION_METHOD /
  _DT` from a `STRING_AGG` over `NRT_INVESTIGATION_CONFIRMATION` joined to
  `NRT_SRTE_CODE_VALUE_GENERAL` (codeset `PHC_CONF_M`); `JURISDICTION_NM` from
  `NRT_SRTE_JURISDICTION_CODE`.
- `#COVID_PATIENT_DATA` (Step 5) — joins `D_PATIENT pat` (built by
  `sp_d_patient`/`sp_patient_event` from ODSE `person`) on
  `inv.patient_id`, plus `NRT_PATIENT nrtPat` (status `'A'`, name-use `'L'`)
  for the codeset-unit fields (`AGE_REPORTED_UNIT_CD`, `DECEASED_IND_CD`,
  `MARITAL_STATUS_CD`, `STATE_CODE`, `COUNTY_CODE`, `COUNTRY_CODE`,
  `ETHNIC_GROUP_IND`).
- `#COVID_ENTITIES_DATA` (Step 6) — resolves the soft-ref FKs on
  `NRT_INVESTIGATION` (`investigator_id`, `physician_id`,
  `person_as_reporter_uid`, `organization_id`, `hospital_uid`) against
  `D_PROVIDER` / `D_ORGANIZATION` to produce `PHC_INV_*`, `PHYS_*`,
  `RPT_PRV_*`, `RPT_ORG_*`, `HOSPITAL_NAME`. These were the columns the
  round-1 fixture left NULL; `zz_covid_case_datamart_round2.sql` adds the
  provider/org rows and re-points the FKs to light them up.

The **form-driven** columns (the overwhelming majority — ~440 of them) are
not in any DDL. Steps 7/10/13 run `ALTER TABLE COVID_CASE_DATAMART ADD <col>
varchar(2000|8000)` for every `user_defined_column_nm` discovered in
`NRT_ODSE_NBS_RDB_METADATA ⋈ NRT_ODSE_NBS_UI_METADATA` for
`investigation_form_cd = 'PG_COVID-19_v1.1'`; Steps 8/11/14 PIVOT
`NRT_PAGE_CASE_ANSWER` (answer value =
`replace(ISNULL(code_short_desc_txt, answer_txt), …)`) keyed on
`nbs_question_uid + act_uid`. Discrete answers (component NOT IN 1013,1025,
`question_group_seq_nbr IS NULL`), multi-string answers (component IN
1013,1025), and three repeating-block slices (`_1/_2/_3`,
`answer_group_seq_nbr`) feed `@tmp_COVID_CASE_DISCRETE/MULTI/RPT_DATA_*`. The
**final INSERT is itself dynamic SQL** — the entire column list is read from
`tempdb.INFORMATION_SCHEMA.COLUMNS` of those temp tables and executed via
`EXEC sp_executesql @insert_query` (lines 1119–1245). These columns are
`DYNAMIC`: their ODSE source is `nbs_odse.dbo.nbs_case_answer.answer_txt` (via
`nrt_page_case_answer`), keyed dynamically by form metadata, not statically
derivable per target column.

> **Surprise / catalog caveat.** `rtr_target_columns.md` lists exactly one
> column for this table — `PATH`, guarded. That is a **parser false-positive**:
> it matched the `FOR XML PATH('')` literal inside the dynamic INSERT-string
> assembly (310-...:551,1128,…), not a real column. COVID_CASE_DATAMART has
> **no static column list at all** — every column is added/inserted via
> dynamic SQL. `PATH` is flagged `DYNAMIC`/parser-artifact in the appendix.

Blocked/skipped: coverage_merged shows 379/383 populated; the round-1
coverage_covid_full_chain.md "deliberately skipped" list (CONFIRMATION_*,
PHC_INV_*/PHYS_*/RPT_*/HOSPITAL_NAME, NOTIFICATION_*) was subsequently
unblocked by round2. The residual ~4 columns are form questions for which no
answer row is authored — reachable by mechanical fixture expansion, not a bug.

## COVID_CONTACT_DATAMART

Row flow (Step 1 single big SELECT … INTO `#COVID_CONTACT_DATAMART`):
`NRT_CONTACT con` INNER JOIN `NRT_INVESTIGATION inv` on
`con.SUBJECT_ENTITY_PHC_UID = inv.public_health_case_uid` (and
`con.RECORD_STATUS_CD <> 'LOG_DEL'`), filtered `inv.cd = '11065'` and
`inv.public_health_case_uid IN STRING_SPLIT(@phcid_list)`. So a contact only
materialises if its **subject** investigation is COVID. This is the gating
predicate that kept the table at 0 rows until `zz_covid_contact.sql` authored
an `nrt_contact` row pointing at COVID PHC 22003000.

The 89-column row is assembled in three families:

- `SRC_*` (index-investigation/patient) — `inv.*` columns
  (`activity_from_time`, `investigation_status_cd`, `case_class_cd`,
  `hospitalized_ind_cd`, `outcome_cd`, `infectious_from/to_date`,
  `contact_inv_*`) and `D_PATIENT pat`/`NRT_PATIENT nrt_pat` for the index
  patient. Four `SRC_INV_*` answer columns come from `NRT_PAGE_CASE_ANSWER`
  by `question_identifier` (`NBS547` CDC-assigned ID, `NOT113` reporting
  county, `INV576` symptomatic, `NBS555` symptom status), batch-id matched.
- `CR_*` (contact record) — `NRT_CONTACT con` columns
  (`CTT_JURISDICTION_NM`, `CTT_STATUS_CODE`, `CTT_PRIORITY`,
  `CTT_INV_ASSIGNED_DT`, `CTT_DISPOSITION`, `CTT_NAMED_ON_DT`,
  `CTT_RELATIONSHIP`, `CTT_HEALTH_STATUS`, dates/notes) plus four
  `NRT_CONTACT_ANSWER` joins by `rdb_column_nm`
  (`CTT_EXPOSURE_TYPE/SITE_TYPE`, `CTT_FIRST/LAST_EXPOSURE_DT`). Investigator
  name comes from `D_PATIENT ctt_pat_con`. Many `CR_*` codes resolve through
  `NRT_SRTE_CODE_VALUE_GENERAL` by codeset (`NBS_PRIORITY`, `NBS_DISPO`,
  `NBS_RELATIONSHIP`, `NBS_HEALTH_STATUS`, `YNU`).
- `CTT_*` (contact-as-subject) — a CASE switch: if
  `con.CONTACT_ENTITY_PHC_UID IS NOT NULL` use the contact's own
  investigation/patient (`con_inv` / `ctt_pat_inv`), else fall back to the
  contact-record patient (`ctt_pat_con`). Sex/deceased/country are resolved
  through `v_code_value_general` (DEM113/DEM127/DEM126) fed by an OUTER APPLY
  that picks the same branch.

`NRT_CONTACT` / `NRT_CONTACT_ANSWER` are the debezium projection of
`sp_contact_record_event` (069), whose ODSE source is `nbs_odse.dbo.contact`
(+ `contact`-scoped answers). `NRT_INVESTIGATION` traces to ODSE
`public_health_case` as above; `D_PATIENT`/`NRT_PATIENT` to ODSE `person`.

Blocked/skipped: 89/94 live. Five columns require a fully-attributed contact
investigation (`CONTACT_ENTITY_PHC_UID` branch) not authored in the fixture —
INFERRED, reachable via a second COVID investigation linked as the contact's
own subject. No bug caps this table.

## COVID_VACCINATION_DATAMART

Row flow: `sp_covid_vaccination_datamart_postprocessing @vac_uids,@patient_uids`
builds `#VAC_LIST` from `NRT_VACCINATION` filtered on
`material_cd IN ('207','208','213')` (the COVID vaccine product codes) — that
is the gating predicate, not a condition code. Idempotent DELETE-then-INSERT
keyed on `local_id`; `LOG_DEL` dropped. The INSERT is `INSERT INTO
COVID_VACCINATION_DATAMART SELECT DISTINCT …` with **no column list** (hence
the catalog's `<all>`), so the 60 targets are positional from the SELECT.

`NRT_VACCINATION` supplies the keys + `INVESTIGATION_DT`
(`COALESCE(nrtinv.activity_from_time, nrtinv.add_time)` via the LEFT JOIN to
`NRT_INVESTIGATION` on `phc_uid`) and `INVESTIGATION_LOCAL_ID`
(`nrtinv.local_id`). Everything else comes from RDB_MODERN dimensions joined
on the CTE soft-refs:

- `D_VACCINATION dvac` (on `vaccination_uid`) — `VACCINATION_ADMINISTERED_NM`,
  `VACCINE_ADMINISTERED_DATE`, `VACCINATION_ANATOMICAL_SITE`,
  `AGE_AT_VACCINATION(_UNIT)`, `VACCINE_MANUFACTURER_NM`,
  `VACCINE_LOT_NUMBER_TXT`, `VACCINE_EXPIRATION_DT`, `VACCINE_DOSE_NBR`,
  `VACCINE_INFO_SOURCE`, `ELECTRONIC_IND`, `RECORD_STATUS_CD`, `LOCAL_ID`,
  add/chg audit columns.
- `D_PATIENT patient` (on `patient_uid`) — all `PATIENT_*`; `PATIENT_BIRTH_SEX`
  via a correlated subselect on `PATIENT_MPR_UID`; `PATIENT_RACE_CALC_DETAILS`
  with `REPLACE(' |',';')`; `PATIENT_COUNTRY` upper-cased.
- `D_PROVIDER provider` / `D_ORGANIZATION org` (on `provider_uid` /
  `organization_uid`) — `PROVIDER_*` / `ORGANIZATION_*`, country upper-cased,
  addr-2 `ISNULL('')`.
- `COVID_VACCINATION_DATAMART_KEY` =
  `CONCAT(vaccination_uid, phc_uid) + RIGHT(YEAR(add_time),2)`.

ODSE roots: `NRT_VACCINATION` ⟶ `sp_vaccination_event` (071) ⟶
`nbs_odse.dbo.intervention` (`vaccination_uid = intervention_uid`,
`material_cd`); `D_VACCINATION` is built from the same intervention chain;
`D_PATIENT`/`D_PROVIDER`/`D_ORGANIZATION` from ODSE `person`/`organization`.

Status: 60/60 live (full). `zz_covid_vaccination_datamart_enrich.sql` authored
a fully-attributed COVID vaccination (patient+provider+org) on top of the
foundation vaccination, which alone left dim-sourced columns NULL. All 60 are
VERIFIED.

## INV_SUMM_DATAMART

This SP is structurally different: **no COVID filter, no `nrt_*` reads** — it
summarises every active investigation (`INVESTIGATION.CASE_TYPE='I'`,
`RECORD_STATUS_CD='ACTIVE'`) whose `CASE_UID` is in `@phc_uids` (or whose
notification was just updated, via `#TMP_UPDATED_INV_WITH_NOTIF`). It runs an
INSERT-new + UPDATE-existing pair, then DELETEs inactive rows, then two
follow-on UPDATEs (EVENT_DATE/specimen, INIT_NND_NOT_DT).

Column families and their RDB_MODERN sources:

- Investigation columns (`INVESTIGATION_KEY/STATUS/LOCAL_ID`, MMWR, dates,
  `CASE_STATUS`, `PROGRAM_AREA`, `PROGRAM_JURISDICTION_OID`,
  `CURR_PROCESS_STATE`, `JURISDICTION_NM`, create/update audit) — the
  `INVESTIGATION` dimension, `SUBSTRING`-truncated to fit. `INVESTIGATION` is
  built by `sp_nrt_investigation_postprocessing` from `nrt_investigation`,
  i.e. ODSE `public_health_case`.
- `PATIENT_KEY`/`PHYSICIAN_KEY` — resolved by a `CASE`/`COALESCE` priority
  ladder across eleven per-condition fact tables (`GENERIC_CASE`, `CRS_CASE`,
  `MEASLES_CASE`, `RUBELLA_CASE`, `HEPATITIS_CASE`, `BMIRD_CASE`,
  `PERTUSSIS_CASE`, `F_TB_PAM`, `F_VAR_PAM`, `F_PAGE_CASE`, `F_STD_PAGE_CASE`)
  — first key > 1 wins. STD vs non-STD branch chosen by
  `count(*) nrt_investigation_case_management`.
- Patient demographics (`PATIENT_FIRST/LAST_NAME`, DOB, sex, age,
  address, county, ethnicity, race, local id) — `D_PATIENT` on `PATIENT_KEY`.
- `PHYSICIAN_FIRST/LAST_NAME` — `D_PROVIDER` on `PHYSICIAN_KEY`.
- `DISEASE`/`DISEASE_CD` — `CASE_COUNT ⋈ condition` (dim) on
  `CONDITION_KEY`.
- `CONFIRMATION_METHOD`/`CONFIRMATION_DT` — `STRING_AGG('|')` over
  `CONFIRMATION_METHOD ⋈ CONFIRMATION_METHOD_GROUP`.
- Notification columns (`NOTIFICATION_STATUS/LOCAL_ID/CREATE_DATE/SENT_DATE/
  SUBMITTER/LAST_UPDATED_*`) — `NOTIFICATION ⋈ NOTIFICATION_EVENT ⋈ RDB_DATE`,
  `ROW_NUMBER() … rn=1` to take the earliest. `INIT_NND_NOT_DT` from a later
  `nrt_investigation_notification` aggregate (`FIRSTNOTIFICATIONSENDDATE`).
- Lab columns (`LABORATORY_INFORMATION`, `EVENT_DATE(_TYPE)`,
  `FIRST_POSITIVE_CULTURE_DT`, `Earliest_specimen_collect_date`) —
  `CASE_LAB_DATAMART` + a `LAB_TEST_RESULT ⋈ LAB_TEST ⋈ lab100` chain;
  `FIRST_POSITIVE_CULTURE_DT` from `BMIRD_CASE`.

Because none of these are `nrt_*` reads, the appendix records the RDB_MODERN
dim/fact column as the proximate source and the transitive ODSE root where it
is unambiguous (investigation/patient/provider → public_health_case/person).
`EVENT_DATE`/`EVENT_DATE_TYPE` originate entirely inside the lab datamart
(L1's CASE_LAB_DATAMART) and are copied here — INFERRED on the COVID side.

Status: 58/58 live (full). `zz_inv_summ_datamart_unblock.sql` corrected the
earlier "chicken-and-egg" misreading (the `@INV_SUMMARY_DATAMART_COUNT > 0`
predicate gates only the optional notif-update temp table, not the main insert)
and supplied the joined dims; all 58 are VERIFIED.
