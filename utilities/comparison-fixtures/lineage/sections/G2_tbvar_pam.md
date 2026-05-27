## G2 — TB / Varicella PAM facts, LDFs, STD page-case fact & BMIRD/Pertussis groups

Gap-fill slice for the PAM facts/dims, page-case fact, LDF dynamic tables,
and the tiny BMIRD/pertussis group-bridge tables that L3 narrated but did
not enumerate. Column-level lineage is in
`lineage/columns/G2_tbvar_pam.tsv` (233 rows). All eleven tables are
downstream consumers — none read `nbs_odse` directly (STRATEGY.md
convention: only `sp_*_event` SPs read ODSE; the
postprocessing/datamart layer reads `nrt_*` staging + RDB_MODERN
dimensions). The ODSE columns in the appendix are therefore the
*synthesis hop*: the `sp_investigation_event` JSON projection that feeds
`nrt_investigation` / `nrt_page_case_answer`.

**Status accounting** (233 rows): VERIFIED 89, INFERRED 122, DYNAMIC 4,
MASTERETL_ONLY 18. As with L3, the high INFERRED count is honest, not a
gap: the PAM pivot and the F_STD_PAGE_CASE keystore *map* every column,
but the minimum-viable full-chain fixtures author a deliberately small
set of PAM questions / dimension rows / participation edges to prove each
SP runs end-to-end. Un-authored columns are INFERRED (SP clearly maps
them, no fixture proves the specific col), never confabulated.

---

### D_VAR_PAM (129 cols) — `sp_nrt_d_var_pam_postprocessing` (215)

`D_VAR_PAM` is the Varicella PAM dimension and the structural twin of
L3's `D_TB_PAM`. The SP filters `nrt_page_case_answer` to the
investigation's `INV_FORM_VAR` answers (`data_location =
'NBS_Case_Answer.answer_txt'`, `ldf_status_cd IS NULL`, SP lines 86-92),
code-translates coded answers through `nrt_srte_code_value_general` (with
special handling for STATE/COUNTY/COUNTRY/jurisdiction/program code-sets,
SP lines 126-194 — e.g. `PATIENT_BIRTH_COUNTRY` resolves `PSL_CNTRY`
answers via `nrt_srte_country_code.code_desc_txt`), then `PIVOT`s
`MAX(ANSWER_TXT) FOR DATAMART_COLUMN_NM` over the explicit ~122-column
IN-list (SP lines 263-301). **Every pivot column is exactly one VAR
question's `answer_txt`**, tagged by `nbs_question.datamart_column_nm`;
the ODSE source is `nbs_odse.dbo.nbs_case_answer.answer_txt`.

Keys: `D_VAR_PAM_KEY` is allocated from the `nrt_var_pam_key` keystore
(SP line 510); `VAR_PAM_UID` is the page-case `public_health_case_uid`;
`LAST_CHG_TIME` is the answer-set last-change time. Coverage
(`coverage_varicella_full_chain.md` + `zz_var_datamart_enrich.sql` →
127/129 in `coverage_merged.md`): the fixture proves the key/UID/time
columns plus a ~25-question minimum-viable set (`VARICELLA_VACCINE`,
`RASH_LOCATION`, `VESICLES`, `FEVER`, `PCR_TEST`/`PCR_TEST_RESULT`,
`COMPLICATIONS*`, `EPI_LINKED`, `TRANSMISSION_SETTING`, etc.). The other
~100 pivot columns are INFERRED — fed by VAR questions the fixture did
not author (a fixture-completeness exercise, not an infrastructure
block).

### F_TB_PAM (20 cols) — `sp_f_tb_pam_postprocessing` (206) and F_VAR_PAM (12 cols) — `sp_f_var_pam_postprocessing` (240)

These are the TB/Varicella PAM **fact** tables — all-key rows that hang
the PAM dimension off the patient/provider/org dimensions, the
topic-group dimensions, and the date dimension. Both read the
`INV_FORM_RVCT` / `INV_FORM_VAR` rows of `nrt_investigation` for the
driving UID set, then build per-UID keystores that resolve each
entity UID to a surrogate key: `nrt_investigation.patient_id` →
`D_PATIENT.PATIENT_KEY`, `investigator_id`/`physician_id`/
`person_as_reporter_uid` → `D_PROVIDER.PROVIDER_KEY`, and
`hospital_uid`/`org_as_reporter_uid` → `D_ORGANIZATION.ORGANIZATION_KEY`
(all `COALESCE(..., 1)`). `INVESTIGATION_KEY` joins `INVESTIGATION` on
`CASE_UID`; `ADD_DATE_KEY`/`LAST_CHG_DATE_KEY` resolve via `RDB_DATE` on
the staging add/last-change times; `D_*_PAM_KEY` is the FK to the PAM
pivot. F_TB_PAM additionally carries the 10 TB topic-group keys
(`D_DISEASE_SITE_GROUP_KEY`, `D_ADDL_RISK_GROUP_KEY`, `D_MOVE_*`,
`D_GT_12_REAS_GROUP_KEY`, `D_HC_PROV_TY_3_GROUP_KEY`,
`D_OUT_OF_CNTRY_GROUP_KEY`, `D_MOVED_WHERE_GROUP_KEY`,
`D_SMR_EXAM_TY_GROUP_KEY`), and F_VAR_PAM the two VAR topic-group keys
(`D_RASH_LOC_GEN_GROUP_KEY`, `D_PCR_SOURCE_GROUP_KEY`) — these inherit
the multi-value page-answer lineage from their `D_*` topic dimensions
(group key set by the `sp_nrt_d_*_postprocessing` group-dim SPs, which
the catalog lists as co-writers via UPDATE).

The whole F_VAR_PAM body is gated by an `IF EXISTS` on condition
`10030` having `PORT_REQ_IND_CD = 'T'` (SP lines 47-51). Both facts are
VERIFIED (F_TB_PAM 20/20, F_VAR_PAM 12/12 in `coverage_merged.md`,
spot-checked in the coverage reports), but note that the
physician/reporter/hospital/provider keys resolve to **sentinel 1** —
the standalone TB/VAR Phase-2 investigations carry no `PhysicianOfPHC` /
`PerAsReporterOfPHC` / `OrgAsReporterOfPHC` / `HospOfADT` participation
edges (the `LINK_REQUIRED` gap in both coverage reports). The values are
populated and the mapping verified; only the *resolved* (non-sentinel)
value awaits a Tier-2 edge follow-on.

### D_TB_HIV (6 cols) — `sp_nrt_d_tb_hiv_postprocessing` (160)

A narrow PAM sub-pivot: it filters `nrt_page_case_answer` for the RVCT
investigation to the three HIV questions `TUB154`/`TUB155`/`TUB156` (SP
line 104), code-translates, then `PIVOT`s into `HIV_STATE_PATIENT_NUM`,
`HIV_STATUS`, `HIV_CITY_CNTY_PATIENT_NUM` (SP lines 300-312). `TB_PAM_UID`
is `CAST(ACT_UID AS BIGINT)`, `D_TB_HIV_KEY` is from the `nrt_d_tb_hiv_key`
keystore, `LAST_CHG_TIME` is the `MAX` over the three answers. These three
HIV columns are the verified path L3 cited as feeding `TB_HIV_DATAMART`'s
`HIV_*` block. All 6/6 VERIFIED (`coverage_tb_full_chain.md`).

### TB_PAM_LDF (5 cols) — `sp_nrt_tb_pam_ldf_postprocessing` (220) and VAR_PAM_LDF (5 cols) — `sp_nrt_var_pam_ldf_postprocessing` (235)

These are the LDF (locally-defined field) tables — the clearest example
in the cluster of the **page-builder/PAM-answer dynamic-pivot
mechanism**. Each SP filters `nrt_page_case_answer` to the RVCT/VAR
investigation's *LDF-flagged* answers (`LDF_STATUS_CD IN
('LDF_UPDATE','LDF_CREATE','LDF_PROCESSED')`, SP 220 lines 83-85), runs
the answer through the SRTE translation ladder (code_value_general →
clinical → state → country, with `STRING_AGG` concatenation for
multi-select), then discovers which `datamart_column_nm` values are
*not* yet columns of the target table, **`ALTER TABLE ... ADD`s those
columns at runtime**, and finally `PIVOT`s `MAX(ANSWER_TXT) FOR
DATAMART_COLUMN_NM IN (<dynamic list>)` into them via `sp_executesql`
(SP 220 lines 344-491). Because the column set is whatever LDF questions
exist in `nbs_page_answer` / `nbs_question` metadata, the data columns
are **not statically derivable**.

In the appendix the three base columns are static and VERIFIED:
`INVESTIGATION_KEY` (LEFT JOIN `investigation` on `*_PAM_UID = CASE_UID`),
`*_PAM_UID` (the page-case `ACT_UID`), and `ADD_TIME` (the answer's
`NCA_ADD_TIME` — present in the SP INSERT and the live 6/6 population but
missing from the static catalog extract). The two columns the catalog
*did* statically capture, `END` and `THEN`, are SQL-keyword
`datamart_column_nm` values from LDF questions and are flagged
**DYNAMIC** (driving table: `nbs_page_answer` / `nbs_question` LDF
metadata). The coverage reports note both tables show **0 rows** in the
TB/VAR full-chain runs (LDF_GAP — the full-chain fixtures author only
`ldf_status_cd IS NULL` answers); `coverage_merged.md` shows **6/6** for
both because `zz_ldf_flagged_answers.sql` later authors LDF-flagged
`nrt_page_case_answer` rows for the RVCT/VAR PHCs and tail-EXECs these
two SPs (the orchestrator does not call them in its main chain).

### F_STD_PAGE_CASE (52 cols) — `sp_f_std_page_case_postprocessing` (025)

The STD/HIV page-case **fact** — an all-key row that L3's
`STD_HIV_DATAMART` joins to reach the `D_INV_*` dimensional cluster. It
reads `nrt_investigation` (+ `nrt_investigation_case_management`) for
non-PAM, case-managed investigations (the form-cd exclusion list at SP
lines 152-154, gated on `CASE_MANAGEMENT_UID IS NOT NULL`), then resolves
three families of keys:

1. **Entity keys** (`PATIENT_KEY`, `PHYSICIAN_KEY`, `INVESTIGATOR_KEY`,
   `HOSPITAL_KEY`, `ORG_AS_REPORTER_KEY`, plus the ~14 follow-up /
   delivery / OB-GYN provider+org keys) — each `COALESCE(..., 1)` joins a
   UID column on the staging row to `D_PATIENT`/`D_PROVIDER`/
   `D_ORGANIZATION` (SP lines 176-239). `CONDITION_KEY` joins `CONDITION`
   on `CD`; `ADD_DATE_KEY`/`LAST_CHG_DATE_KEY` join `RDB_DATE`;
   `INVESTIGATION_KEY` joins `INVESTIGATION` on `CASE_UID`.
2. **`D_INV_*_KEY` dimensional keys** (24 of them) — each
   `COALESCE(..., 1)` resolves through an `L_INV_*` link table to a
   `D_INV_*` dimension keyed on `PAGE_CASE_UID` (SP lines 265-289).
3. **`GEOCODING_LOCATION_KEY`** — joins `GEOCODING_LOCATION` on the
   patient entity UID.

The `D_INV_*`/`L_INV_*` dimensions and `GEOCODING_LOCATION` are
**MasterETL-only** persistent dimensions — no RTR SP populates them from
ODSE (see L3 and `catalog/odse_unknown_tables.md`). The STD full-chain
fixture hand-authors **five** D_INV/L_INV pairs (HIV, ADMINISTRATIVE,
CLINICAL, EPIDEMIOLOGY, COMPLICATION), so those 5 keys + the
entity/condition/date keys are VERIFIED; the other 17 `D_INV_*` keys and
`GEOCODING_LOCATION_KEY` are flagged `MASTERETL_ONLY` (they populate at
sentinel 1 because no `L_INV_*` row exists for them). `D_INVESTIGATION_REPEAT_KEY`
/ `D_INV_PLACE_REPEAT_KEY` are INFERRED (those dims *are* RTR-populated
elsewhere — L6 — but no `L_*` row links this PHC). The 14 follow-up /
delivery cross-subject keys are INFERRED (sentinel 1, no Tier-2
participation edges — the coverage report's `LINK_REQUIRED` gap). Two RTR
issues surfaced here, both documented in `coverage_std_hiv_full_chain.md`:
the orchestrator `@phc_ids` vs `@phc_id_list` parameter-name mismatch
(Bug #M — F_STD_PAGE_CASE stays 0 rows in the orchestrated path until
fixed), and the sentinel-`CONFIRMATION_METHOD_GROUP` join-cardinality
issue on the downstream datamart.

### BMIRD & Pertussis group-bridge tables (1 col each)

`ANTIMICROBIAL_GROUP` and `BMIRD_MULTI_VALUE_FIELD_GROUP` (written by
`sp_bmird_case_datamart_postprocessing`, SP 040) and
`PERTUSSIS_SUSPECTED_SOURCE_GRP` and `PERTUSSIS_TREATMENT_GROUP` (written
by `sp_pertussis_case_datamart_postprocessing`, SP 043) are
single-column **group-bridge** tables. Each holds one surrogate
group-key column (`*_GRP_KEY`). The mechanism is identical across all
four: the datamart SP computes a multi-value group key per
investigation; for PHCs whose group key is **unresolved** (left at the
sentinel value 1 because no matching multi-value/antimicrobial group
exists), it loads `public_health_case_uid` into a `nrt_*_group_key`
keystore (which DELETEs then re-INSERTs every run), then `INSERT`s the
allocated `*_GRP_KEY` from that keystore into the group-bridge table
(SP 040 lines 398-425 and 588-612; SP 043 lines 605-632 and 816-838).
There is **no direct ODSE column** — the value is a generated surrogate
key, so the appendix records the keystore as the staging source and
`—` for the ODSE column. All four are VERIFIED at 1/1 in
`coverage_merged.md` (the full-chain fixtures for BMIRD/pertussis each
produce the single sentinel group row).

These tables relate to the L3 BMIRD note about **bug #12**: SP 040's
`ROW_NUMBER() OVER (PARTITION BY public_health_case_uid, branch_id ...)`
collapses `BMIRD_MULTI_VALUE_FIELD` to one row per investigation, capping
the `_2`+ pivot slots on `BMIRD_STREP_PNEUMO_DATAMART`. The group-bridge
tables themselves are not blocked — they only ever hold the sentinel
group key in the current fixtures — but the bug is why their downstream
multi-value fan-out stays single-slot.

---

### Cross-cutting notes

- **No PAM/fact/LDF SP reads `nbs_odse` directly.** ODSE columns are the
  `sp_investigation_event` projection that feeds `nrt_investigation` /
  `nrt_page_case_answer`.
- **The PAM-answer pivot** (D_VAR_PAM, D_TB_HIV) and the **dynamic LDF
  pivot** (TB_PAM_LDF, VAR_PAM_LDF) are the same idiom at two levels of
  staticness: D_VAR_PAM/D_TB_HIV pivot over a *fixed* IN-list (statically
  mappable → INFERRED/VERIFIED per column), whereas the LDF tables
  `ALTER TABLE` + pivot over a *runtime-discovered* `datamart_column_nm`
  list (DYNAMIC for the answer columns; only the base keys are static).
- **`MASTERETL_ONLY`** on F_STD_PAGE_CASE means the `D_INV_*` /
  `GEOCODING_LOCATION` dimension is a persistent dim RTR joins but does
  not populate from ODSE; the STD fixture hand-authors a subset so the
  join resolves.
- **Sentinel-1 keys are populated, not missing.** Several VERIFIED fact
  keys (provider/org/physician on F_TB_PAM/F_VAR_PAM/F_STD_PAGE_CASE)
  resolve to 1 only because the Phase-2 investigations lack Tier-2
  participation edges (`LINK_REQUIRED`) — the mapping is proven, the
  resolved value awaits an edge fixture.
