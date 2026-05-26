# L3 — TB / STD-HIV / BMIRD / Varicella datamarts

Cluster tables: `D_TB_PAM`, `TB_DATAMART`, `TB_HIV_DATAMART`,
`STD_HIV_DATAMART`, `BMIRD_STREP_PNEUMO_DATAMART`, `VAR_DATAMART`
(1,427 RDB_MODERN columns total). Column-level lineage is in
`lineage/columns/L3_tb_stdhiv_bmird_var.tsv`.

This cluster spans the **two composition patterns** the project's
datamart SPs use, and all six tables are downstream consumers — none
read `nbs_odse` directly (per the STRATEGY.md convention: only
`sp_*_event` SPs read ODSE; the postprocessing/datamart layer reads
`nrt_*` staging and RDB_MODERN dimensions). The ODSE source columns
below are therefore the *synthesis hop*: the `sp_investigation_event` /
`sp_observation_event` JSON projection that feeds the staging tables
these SPs read.

The two patterns:

- **PAM page-answer pivot** (TB, Varicella, and the TB-HIV sub-mart).
  A per-investigation set of `nbs_case_answer` rows is projected by
  `sp_investigation_event` into `nrt_page_case_answer` (carrying
  `answer_txt`, `datamart_column_nm`, `question_identifier`,
  `code_set_group_id`). The `sp_nrt_d_*_pam_postprocessing` SP `PIVOT`s
  `MAX(answer_txt) FOR datamart_column_nm IN (...)` — so **each
  D_*_PAM column is exactly one PAM question's answer**, code-translated
  via `nrt_srte_code_value_general` for coded answers. The datamart SP
  then projects D_*_PAM through the fact table (`F_TB_PAM` /
  `F_VAR_PAM`) and folds in patient/provider/org dimensions.
- **D_INV_\* / observation dimensional composition** (STD-HIV, BMIRD).
  The datamart SP `LEFT JOIN`s a family of dimension tables
  (`D_INV_ADMINISTRATIVE`, `D_INV_CLINICAL`, `D_INV_COMPLICATION`,
  `D_INV_EPIDEMIOLOGY`, … for STD-HIV; `BMIRD_Case` /
  `BMIRD_MULTI_VALUE_FIELD` / `ANTIMICROBIAL` for BMIRD) keyed off the
  fact row, and projects/CASEs their columns. Most of those `D_INV_*`
  dimensions are **MasterETL-only** (no RTR ODSE path — see
  `catalog/odse_unknown_tables.md` and the STD coverage report's "Key
  takeaway"); the Tier-3 fixtures hand-author the dimension rows
  directly so the datamart join lights up.

Cross-subject person/provider/org columns on every table (PATIENT_NAME,
CURRENT_SEX, PHYSICIAN_*, REPORTER_*, HOSPITAL_*, ORGANIZATION_*, …)
resolve through `D_PATIENT` / `D_PROVIDER` / `D_ORGANIZATION`, which are
populated by their own entity-dim pipelines (MasterETL-side for the
persistent dims). They are flagged `MASTERETL_ONLY` in the appendix
because there is no static TB/STD/BMIRD/Var ODSE→column chain for them —
their lineage belongs to L5 (people/links/dims).

**Status accounting** (1,427 rows): VERIFIED 84, INFERRED 1,156,
MASTERETL_ONLY 174, BLOCKED:#12 13. The high INFERRED count is expected
and honest: the PAM pivots and dimensional joins *map* every column, but
the full-chain fixtures author a deliberately minimum-viable set of
questions/dimension columns to prove each SP runs end-to-end. The
remaining columns are reachable in principle by authoring more PAM
questions / `D_INV_*` columns (a fixture-completeness exercise, not an
infrastructure block) — so they are INFERRED (SP clearly maps them, no
fixture proves the specific column), never confabulated.

---

## D_TB_PAM (166 cols) — `sp_nrt_d_tb_pam_postprocessing`

`D_TB_PAM` is the TB RVCT PAM dimension. The SP filters
`nrt_page_case_answer` to the investigation's `INV_FORM_RVCT` answers
(`data_location = 'NBS_Case_Answer.answer_txt'`, `ldf_status_cd IS NULL`,
`datamart_column_nm` present, minus a 13-question exclusion list), joins
`nrt_srte_codeset_group_metadata` + `nrt_srte_code_value_general` to
translate coded answers, then `PIVOT`s `MAX(ANSWER_TXT) FOR
DATAMART_COLUMN_NM` over the explicit ~158-column IN-list (SP lines
305-359). Every pivot column maps to one TUB question's `answer_txt`;
the ODSE source is `nbs_odse.dbo.nbs_case_answer.answer_txt` tagged by
`nbs_question.datamart_column_nm` / `question_identifier`.

Surrogate/business keys: `D_TB_PAM_KEY` is allocated from the
`nrt_d_tb_pam_key` keystore; `TB_PAM_UID` is the page-case `act_uid`
(= `public_health_case_uid`); `LAST_CHG_TIME` is `MAX(last_chg_time)`
over the answers. Three columns are **computed**, not raw pivots:
`CALC_DISEASE_SITE` (CASE over the multi-value DISEASE_SITE answers →
Pulmonary/Extrapulmonary/Both, SP lines 807-873), `INIT_DRUG_REG_CALC`
(count of `INIT_REGIMEN_*` answers = 'Yes'), and `TB_VERCRIT_CALC_IND`.

Coverage (`coverage_tb_full_chain.md` + the later `zz_tb_datamart_enrich`
expansion → 161/166 in `coverage_merged.md`): the fixture proves the
key/UID/time columns, `CALC_DISEASE_SITE`, `HOMELESS_IND`,
`INIT_REGIMEN_*`, `CASE_VERIFICATION`, `INIT_DRUG_REG_CALC`, and the
three HIV_* columns (TUB154/155/156, via `sp_nrt_d_tb_hiv_postprocessing`).
The remaining pivot columns are INFERRED — fed by TUB questions the
minimum-viable fixture did not author.

## TB_DATAMART (318 cols) — `sp_tb_datamart_postprocessing`

`TB_DATAMART` is the flattened TB case mart. It joins `F_TB_PAM` to
`D_TB_PAM` (the pivot above), the 11 TB topic-group dimensions
(`D_DISEASE_SITE`, `D_ADDL_RISK`, `D_MOVE_*`, `D_GT_12_REAS`,
`D_HC_PROV_TY_3`, `D_SMR_EXAM_TY`, `D_OUT_OF_CNTRY`, `D_MOVED_WHERE`),
`D_PATIENT` / `D_PROVIDER` / `D_ORGANIZATION`, `INVESTIGATION`,
`confirmation_method_group`, and `notification_event`/`notification`.
Clinical TB columns therefore inherit the PAM page-answer lineage
through `D_TB_PAM`; multi-value topic columns inherit from the topic
dimensions' `VALUE` (also page-answer fed); person/provider/org columns
are MASTERETL_ONLY.

Notable gating/transform: confirmation columns come from a `LEFT JOIN`
on `confirmation_method_group` keyed by `INVESTIGATION_KEY`. The TB
coverage report flags an **RTR bug**: `sp_tb_datamart_postprocessing`
has an INSERT-only path with no DELETE/MERGE guard, so re-running for
the same PHC produces duplicate rows (row-count integrity issue for the
diff tool, not a populated-state block). Verified columns are the
INVESTIGATION/disease/case-status anchors plus the D_TB_PAM-derived
clinical columns the enrich fixture lit up.

## TB_HIV_DATAMART (322 cols) — `sp_tb_hiv_datamart_postprocessing`

`TB_HIV_DATAMART` is essentially a re-projection of `TB_DATAMART` for
the TB-HIV co-infection view: its only source tables are `TB_DATAMART`,
`D_TB_PAM`, `D_TB_HIV`, and `INVESTIGATION`. Most columns mirror
`TB_DATAMART` one-for-one (same lineage; INFERRED unless TB_DATAMART
proved them), and the `HIV_*` columns come from `D_TB_HIV`
(`HIV_STATUS`, `HIV_STATE_PATIENT_NUM`, `HIV_CITY_CNTY_PATIENT_NUM`),
which `sp_nrt_d_tb_hiv_postprocessing` pivots from `nrt_page_case_answer`
questions TUB154/155/156 — a verified PAM path. Person/provider/org
columns inherited from TB_DATAMART are MASTERETL_ONLY. Same
duplicate-INSERT bug as TB_DATAMART.

## VAR_DATAMART (233 cols) — `sp_var_datamart_postprocessing`

Varicella mart, structurally the TB twin. It joins `F_VAR_PAM` to
`D_VAR_PAM` (the Varicella PAM pivot, SP 215, `INV_FORM_VAR` answers,
IN-list at SP lines 263-301), the two Varicella topic dimensions
`D_RASH_LOC_GEN` and `D_PCR_SOURCE` (fed by VAR105 / VAR176), plus
`D_PATIENT` / `D_PROVIDER` / `D_ORGANIZATION`, `INVESTIGATION`,
`confirmation_method_group`, `notification`. Clinical Varicella columns
trace to `nbs_case_answer.answer_txt` via the D_VAR_PAM pivot.

Key gating predicate: `VAR_DATAMART` is gated by
`INNER JOIN EVENT_METRIC e ON e.EVENT_UID = d.VAR_PAM_UID` (SP line 692).
`EVENT_METRIC` is empty in a Tier-1-isolation run, so VAR_DATAMART only
populates after the orchestrator's Step 9 runs
`sp_event_metric_datamart_postprocessing` first
(`coverage_varicella_full_chain.md`). Unlike TB, VAR_DATAMART's INSERT
has a `WHERE D.INVESTIGATION_KEY IS NULL` idempotency guard. Verified
columns are the ~25 the full-chain + enrich fixtures authored
(VARICELLA_VACCINE, RASH_LOCATION, lab-test flags, etc.); the rest of
the ~110 VAR questions are INFERRED.

## STD_HIV_DATAMART (248 cols) — `sp_std_hiv_datamart_postprocessing`

The STD/HIV mart uses the **dimensional** pattern, not a PAM pivot. The
SP runs a wide guarded UPDATE/INSERT (every column is `Guarded=yes` in
the catalog) that `LEFT JOIN`s `F_STD_PAGE_CASE` to the `D_INV_*` family
(`D_INV_ADMINISTRATIVE` → `ADM_*`/`ADI_*`, `D_INV_CLINICAL` → `CLN_*`,
`D_INV_COMPLICATION` → `CMP_*`, `D_INV_EPIDEMIOLOGY` → `EPI_*`),
`INV_HIV` → `HIV_*` (which `sp_f_std_page_case`/this SP populate from
the hand-authored `D_INV_HIV` via `L_INV_HIV`), `D_PATIENT`,
`D_PROVIDER`, `D_CASE_MANAGEMENT`, `INVESTIGATION`, and
`CONFIRMATION_METHOD_GROUP`. Column→source is by prefix (HIV_/ADM_/CLN_/
CMP_/EPI_/CA_).

The `D_INV_*` and `L_INV_*` tables are **MasterETL-only** persistent
dimensions: no RTR SP populates them from ODSE, so the STD fixture
authors them by hand and the datamart join reads them. Consequently the
~190 columns sourced purely from a `D_INV_*` dimension are flagged
`MASTERETL_ONLY` (their value lands via a hand-authored fixture row, not
an ODSE→staging→column chain). The VERIFIED set is the ~30 columns the
fixture's five authored dimensions lit up
(`coverage_std_hiv_full_chain.md`): the HIV_* block, a handful of
CLN_/ADM_/CMP_/EPI_ columns, and the INVESTIGATION/condition/MMWR/
confirmation anchors. Transforms of note: `CALC_5_YEAR_AGE_GROUP`
(CASE ladder over `D_PATIENT.PATIENT_AGE_REPORTED`) and `PATIENT_NAME`
concatenation. Two RTR bugs surfaced here — sentinel
`CONFIRMATION_METHOD_GROUP` rows doubling the join cardinality, and an
orchestrator `@phc_ids` vs `@phc_id_list` parameter-name mismatch
(both documented in the coverage report).

## BMIRD_STREP_PNEUMO_DATAMART (140 cols) — `sp_bmird_strep_pneumo_datamart_postprocessing`

The invasive Strep pneumoniae mart is **observation-derived**. Upstream,
`sp_bmird_case_datamart_postprocessing` (SP 040) builds `BMIRD_Case` /
`BMIRD_MULTI_VALUE_FIELD` / `ANTIMICROBIAL` via **dynamic SQL** keyed on
`nrt_srte_IMRDBMapping` (`RDB_TABLE='BMIRD_Case'`), reading the
`nrt_observation*` staging tables (coded/text/numeric/date) that
`sp_observation_event` projects from `nbs_odse.dbo.observation`. SP 140
then `LEFT JOIN`s `BMIRD_Case` (via `v_nrt_inv_keys_attrs_mapping`),
`BMIRD_MULTI_VALUE_FIELD`, `ANTIMICROBIAL`, `D_PATIENT`,
`D_ORGANIZATION`, `INVESTIGATION`, `CONDITION`, `EVENT_METRIC`, and
CASE/pivots the BMD answers into the wide datamart row (e.g.
`TYPE_INFECTION_BACTEREMIA` = CASE WHEN `BM_INFEC_TYPE` …, SP ~line 797;
`EVENT_DATE` = CASE over illness-onset/diagnosis dates).

Three column groups stand out:

- **BLOCKED:#12 (13 cols)** — `UNDERLYING_CONDITION_2..8`,
  `NON_STERILE_SITE_2..3`, `ADD_CULTURE_1_SITE_2..3`,
  `ADD_CULTURE_2_SITE_2..3`. These are the `_2`+ slots of the
  multi-value pivot. Bug #12
  (`bugs/12_bmird_case_datamart_row_number_partition/findings.md`): SP
  040's `ROW_NUMBER() OVER (PARTITION BY public_health_case_uid,
  branch_id ...)` includes `branch_id` in the partition, so every branch
  is alone → `row_num` always 1 → `BMIRD_MULTI_VALUE_FIELD` collapses to
  one row per investigation and only the `_1` slot fills, no matter how
  many answers are authored. Reachable in principle; capped by the bug.
- **ANTIMICROBIAL pivot (~40 cols)** — `ANTIMICROBIAL_AGENT_TESTED_1..8`,
  `SUSCEPTABILITY_METHOD_*`, `MIC_*`, etc. Require root/branch
  Antimicrobial observations (`ANTIMICRO_GAP` in the coverage report);
  out of scope for the current fixture → INFERRED.
- **Verified (~25 cols)** — the single-slot BMD answers and
  INVESTIGATION/condition anchors the full-chain + enrich fixtures
  proved (BACTERIAL_SPECIES_ISOLATED, OXACILLIN_*, CULTURE_SEROTYPE,
  VACCINE_*, HOSPITALIZED_*, EVENT_DATE, MMWR_*, etc.).

Person (`D_PATIENT`) and hospital/reporter (`D_ORGANIZATION`) columns
are MASTERETL_ONLY. SP 140 also has the same INSERT-without-DELETE
re-runnability bug noted for TB/Var (a `WHERE tgt IS NULL` anti-join
that prevents re-INSERT but never updates stale columns).

---

### Cross-cutting notes

- **No PAM/datamart SP reads `nbs_odse` directly.** ODSE columns in the
  appendix are the `sp_investigation_event` / `sp_observation_event`
  projection that feeds `nrt_page_case_answer` / `nrt_observation*`.
- **`MASTERETL_ONLY` here means "no RTR ODSE chain for this column"** —
  it is sourced from a persistent dimension (`D_PATIENT`, `D_PROVIDER`,
  `D_ORGANIZATION`, `D_INV_*`, `L_INV_*`) that RTR joins but does not
  populate from ODSE. For STD/HIV the Tier-3 fixture hand-authors the
  `D_INV_*`/`L_INV_*` rows so the join resolves.
- **INFERRED is the honest default** for the many PAM/BMD questions and
  `D_INV_*` columns that each SP maps but the minimum-viable fixtures did
  not author a feeder for. None were confabulated to VERIFIED.
- **Re-runnability bug** (TB_DATAMART, TB_HIV_DATAMART,
  BMIRD_STREP_PNEUMO_DATAMART): INSERT-only / anti-join INSERT with no
  DELETE-first or MERGE — duplicate or stale rows on replay.
  VAR_DATAMART and the DELETE-then-INSERT marts are safe.
