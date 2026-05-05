# Coverage: place (Tier 1)

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 20040000 - 20049999 (Place Tier 1)
- Foundation dependencies:
  - `@dbo_Entity_place_uid` = 20000030 (entity / place; class `PLC`)
  - `@dbo_Postal_locator_place` = 20000031 (PST/H/H — read-only;
    foundation has this locator wired to the Place via an
    `entity_locator_participation` row keyed (PST,H,H). The Tier 1
    fixture does NOT reuse this locator for the (PST,WP,PLC) ELP edge
    the event SP requires — the ELP table's PK is
    `(entity_uid, locator_uid)`, so a second ELP row for the same
    locator with a different (use_cd, cd) tuple collides. A new
    postal_locator (`@dbo_Postal_locator_place_wp` = 20040000) is
    allocated in the Tier 1 block instead.)
- Other-agent dependencies: none. The fixture intentionally avoids
  cross-subject `act_relationship` / `participation` / `nbs_act_entity`
  rows (Tier 2 territory).

## SPs verified
- `dbo.sp_place_event` — exit code: 0; emitted 2 rows (foundation +
  v2). Pure SELECT — does NOT write `dbo.nrt_place` or
  `dbo.nrt_place_tele` (matches the Provider / Organization / Patient
  canary observations; the same shape applies for Place). Verified by
  inspecting the SP body in
  `liquibase-service/src/main/resources/db/005-rdb_modern/routines/068-sp_place_event-001.sql`:
  the body is one large `SELECT ... FROM nbs_odse.dbo.Place ...` with no
  `INSERT INTO nrt_*`. Subordinate `OUTER APPLY` blocks populate the
  JSON projections `place_entity`, `place_address`, `place_tele` — all
  three resolved to non-NULL JSON for the v2 row, and `place_address`
  + `place_tele` resolved for the foundation row. `place_entity` is
  NULL on the foundation row because the fixture does not seed an
  `entity_id` row of `type_cd='QEC'` for the foundation Place
  (deliberate — exhibits the no-entity-id branch).
- `dbo.sp_nrt_place_postprocessing` — exit code: 0; `job_flow_log`
  shows `Dataflow_Name='D_Place POST-Processing'`,
  `step_name='SP_COMPLETE'`, `status_type='COMPLETE'` for batch
  `2605050745034900`. Step 6 ("Insert D_PLACE") completed without
  error. 8 rows inserted into D_PLACE (4 per place_uid: Base,
  Postal-only, Tele-only, Postal+Tele — the SP emits one composite
  PLACE_LOCATOR_UID row per cardinality combination per
  `028-sp_nrt_place_postprocessing-001.sql:162-402`). No `ERROR` rows
  in `job_flow_log` for this invocation. The dispatch's "do not invoke
  `sp_repeated_place_postprocessing`" warning was observed —
  `sp_repeated_place_postprocessing` (file 035) is NOT executed by this
  fixture (it requires `@phc_id_list` — Tier 2/3 territory).

## Apply / FK check
- `sqlcmd -i 00_foundation.sql` exit code: 0.
- `sqlcmd -i 10_subjects/place.sql` exit code: 0 on second attempt.
  - First attempt failed with PK violation
    (`PK__Entity_locator_p__33D4B598`) when the fixture tried to add a
    second ELP row for the foundation postal_locator (20000031) to
    introduce the (PST,WP,PLC) tuple. Root cause: ELP PK is
    `(entity_uid, locator_uid)`. Fix: allocate a new postal_locator
    (20040000) in the Tier 1 block and wire that one with (PST,WP,PLC).
    Second apply was clean.
- `DBCC CHECKCONSTRAINTS` run on every NBS_ODSE table written
  (`entity`, `place`, `entity_id`, `tele_locator`, `postal_locator`,
  `entity_locator_participation`). All checks completed without
  constraint-violation rows.

## Iteration count
- 2 baseline-reset cycles: the dispatch reset (after Patient
  verification) and one mid-authoring reset to recover from the PK
  violation noted above.

## D_PLACE coverage
**37 / 37 live D_PLACE columns are populated for at least one
D_PLACE row across the 8 rows the postprocessing SP emits.**
(Live D_PLACE column count verified at 37 via
`sys.columns WHERE object_id=OBJECT_ID('dbo.D_PLACE')`. The Phase 0
catalog says "~38" — actual live count is 37, matching the Patient-era
guidance that the catalog can drift by 1–8 columns from the live
schema.)

The 8 rows are 4 per place_uid because
`028-sp_nrt_place_postprocessing-001.sql:162-402` UNION-ALLs four
composite-key variants — Base (no postal/tele), Postal-only, Tele-only,
Postal+Tele — and emits one D_PLACE row per variant where the source
data has the cardinality. Both place_uids in this fixture have a
postal AND a tele staging row, so all four variants fire for each.

| Column | Populated rows (of 8) | Source (postprocessing SP) | Sample value (v2 Postal+Tele row, place_uid=20040010) | Foundation row (place_uid=20000030, Postal+Tele) |
| --- | --- | --- | --- | --- |
| PLACE_KEY | 8 | `nrt_place_key.d_place_key` (auto-issued by SP) | 9 | 5 |
| PLACE_LOCATOR_UID | 8 | composite — `<place_uid>^<postal_uid>^<tele_uid>` (lines 209-211, 256-259, 306-309, 354-358) | `20040010^20040011^20040012` | `20000030^20040000^20040001` |
| PLACE_UID | 8 | `nrt.place_uid` (cast numeric on D_PLACE) | 20040010 | 20000030 |
| PLACE_LOCAL_ID | 8 | `nrt.place_local_id` | `PLC20040010GA01` | `PLC20000030GA01` |
| PLACE_NAME | 8 | `nrt.place_name` | `Variant Motel` | `Foundation Place` |
| PLACE_RECORD_STATUS | 8 | `nrt.place_record_status` | `ACTIVE` | `ACTIVE` |
| PLACE_RECORD_STATUS_TIME | 8 | `nrt.place_record_status_time` | `2026-04-01 00:00:00` | same |
| PLACE_STATUS_CD | 8 | `nrt.place_status_cd` | `A` | `A` |
| PLACE_STATUS_TIME | 8 | `nrt.place_status_time` | `2026-04-01 00:00:00` | same |
| PLACE_ADD_TIME | 8 | `nrt.place_add_time` | `2026-04-01 00:00:00` | same |
| PLACE_ADD_USER_ID | 8 | `nrt.place_add_user_id` | 10003000 | 10009282 |
| PLACE_LAST_CHANGE_TIME | 8 | `nrt.place_last_change_time` | `2026-04-01 00:00:00` | same |
| PLACE_LAST_CHG_USER_ID | 8 | `nrt.place_last_chg_user_id` | 10003000 | 10009282 |
| PLACE_GENERAL_COMMENTS | 4 | `nrt.place_general_comments` | `Tier 1 variant place — exercises every D_PLACE column.` | NULL (deliberate) |
| PLACE_QUICK_CODE | 4 | `nrt.place_quick_code` | `PLC-V2-QEC` | NULL (deliberate; foundation has no QEC entity_id row) |
| PLACE_TELE_TYPE | 8 | `nrt.place_elp_cd` (Base + Postal-only branches map `place_elp_cd → PLACE_TELE_TYPE`) on no-tele rows; `tele.place_tele_type` on Tele-bearing rows | `Phone` (Tele rows); `PLC` (Base / Postal-only rows) | `Phone` / `PLC` |
| PLACE_TELE_USE | 8 | `nrt.place_tele_use` (read from `nrt_place.place_tele_use` only, not from nrt_place_tele) | `Work Place` | `Work Place` |
| PLACE_TYPE_DESCRIPTION | 4 | `nrt.place_type_description` (only set on v2; foundation NULL) | `Motel/Hotel` | NULL (deliberate; foundation `place.cd` is NULL per Tier 0 contract) |
| PLACE_ADDED_BY | 4 | `USER_PROFILE.last_nm + ', ' + USER_PROFILE.first_nm` joined on `nrt.place_add_user_id = USER_PROFILE.nedss_entry_id` (lines 84-91) | `Nelson, Jay` | NULL (deliberate; foundation uses 10009282 which has no USER_PROFILE row) |
| PLACE_LAST_UPDATED_BY | 4 | same as PLACE_ADDED_BY (line 92-100; the SP joins USER_PROFILE again on `place_add_user_id`, NOT on `place_last_chg_user_id` — see Decisions section below) | `Nelson, Jay` | NULL (deliberate) |
| PLACE_POSTAL_UID | 4 | `nrt.place_postal_uid` (Postal + Postal+Tele branches only) | 20040011 | 20040000 |
| PLACE_ZIP | 4 | `nrt.place_zip` | `30303` | `30303` |
| PLACE_CITY | 4 | `nrt.place_city` | `Atlanta` | `Atlanta` |
| PLACE_COUNTRY | 4 | `CASE WHEN LEN(RTRIM(LTRIM(nrt.place_country_desc))) > 0 THEN nrt.place_country_desc END` (lines 59-61) | `United States` | `United States` |
| PLACE_COUNTRY_DESC | 4 | `nrt.place_country_desc` (also propagated to PLACE_COUNTRY via the case-when above) | `United States` | `United States` |
| PLACE_COUNTY_CODE | 4 | `nrt.place_county_code` | `13121` | `13121` |
| PLACE_COUNTY_DESC | 4 | `nrt.place_county_desc` | `Fulton County` | `Fulton County` |
| PLACE_STATE_CODE | 4 | `nrt.place_state_code` | `13` | `13` |
| PLACE_STATE_DESC | 4 | `nrt.place_state_desc` (postprocessing SP also writes this column even though the catalog calls it `PLACE_STATE`; see decisions) | `Georgia` | `Georgia` |
| PLACE_STREET_ADDRESS_1 | 4 | `nrt.place_street_address_1` | `4010 Variant Motel Drive` | `400 Place Avenue` |
| PLACE_STREET_ADDRESS_2 | 2 | `nrt.place_street_address_2` | `Suite 200` | NULL (deliberate; foundation has no street_addr2) |
| PLACE_ADDRESS_COMMENTS | 4 | `nrt.place_address_comments` | `v2 Place work-place address` | `Foundation Place address` |
| PLACE_TELE_LOCATOR_UID | 4 | `tele.place_tele_locator_uid` (Tele + Postal+Tele branches only) | 20040012 | 20040001 |
| PLACE_PHONE | 4 | `tele.place_phone` | `404-555-4010` | `404-555-0400` |
| PLACE_PHONE_EXT | 2 | `tele.place_phone_ext` | `5678` | NULL (deliberate; foundation tele has no extension) |
| PLACE_PHONE_COMMENTS | 4 | `tele.place_phone_comments` | `v2 Place work phone` | `Foundation Place work phone` |
| PLACE_EMAIL | 2 | `tele.place_email` | `variant.place@nbs.test` | NULL (deliberate; foundation tele has no email_address) |

Per-row populated counts: each of the 8 rows leaves a different subset
of columns NULL by SP design (the union branches NULL out the
postal/tele columns where the variant doesn't include them). Across
the 8 rows, every D_PLACE column appears non-NULL on at least one row,
so coverage is 37/37. The deliberately-NULL choices on the foundation
inputs surface as additional NULLs across all 4 of foundation's rows
(PLACE_TYPE_DESCRIPTION, PLACE_GENERAL_COMMENTS, PLACE_QUICK_CODE,
PLACE_ADDED_BY, PLACE_LAST_UPDATED_BY, PLACE_STREET_ADDRESS_2,
PLACE_PHONE_EXT, PLACE_EMAIL) and contrast with v2's full population.

## UID allocations (Place Tier 1)

| UID | Symbolic name | Entity / column | Notes |
| --- | --- | --- | --- |
| 20040000 | @dbo_Postal_locator_place_wp | foundation Place work-place `postal_locator.postal_locator_uid` | Wired to @dbo_Entity_place_uid (20000030) via a (PST,WP,PLC) `entity_locator_participation` row in this block. Required because the event SP at lines 91-94 filters `(USE_CD='WP', CD='PLC', CLASS_CD='PST')` and foundation's existing ELP on postal_locator 20000031 is (PST,H,H). The ELP PK is (entity_uid, locator_uid), so a second ELP row for 20000031 with a different (use_cd, cd) collides — hence a new locator. Drives PLACE_POSTAL_UID, PLACE_STREET_ADDRESS_1/2, PLACE_CITY, PLACE_STATE_*, etc. on the foundation Place's D_PLACE rows. |
| 20040001 | @dbo_Tele_locator_place_phone | foundation Place work-phone `tele_locator.tele_locator_uid` | Wired via (TELE,WP,PH) ELP. Foundation Place has no tele locator; this adds one. Drives PLACE_PHONE on the foundation Place's tele rows. nrt_place_tele row keyed on (place_uid=20000030, place_tele_locator_uid=20040001). |
| 20040010 | @dbo_Entity_place_v2_uid | v2 Place `entity.entity_uid` / `place.place_uid` | Class `PLC`, place.cd `M` (Motel/Hotel from PLACE_TYPE). Fully-attributed Place variant for D_PLACE column coverage. |
| 20040011 | @dbo_Postal_locator_place_v2 | v2 Place work-place `postal_locator.postal_locator_uid` | Wired via (PST,WP,PLC) ELP. |
| 20040012 | @dbo_Tele_locator_place_v2_phone | v2 Place work-phone `tele_locator.tele_locator_uid` | Wired via (TELE,WP,PH) ELP. Includes `extension_txt` and `email_address`. nrt_place_tele row keyed on (place_uid=20040010, place_tele_locator_uid=20040012). |
| 20040013 | @dbo_Tele_locator_place_v2_fax | v2 Place work-fax `tele_locator.tele_locator_uid` | Wired via (TELE,WP,FAX) ELP. Shape-only on the ODSE side — exercises the EL_TYPE_TELE_PLC `FAX` code in the event SP's JSON projection. The postprocessing SP joins one nrt_place_tele row per place_uid; the synthetic staging row on v2 references the phone locator (20040012), not this fax locator. |

Unused UIDs in Place Tier 1 block (20040002-20040009, 20040014-20049999)
are reserved for future Place Tier 1 / Tier 3 amendments. Do not
allocate from this range outside of Place Tier 1.

The fixture also writes 2 rows directly to `RDB_MODERN.dbo.nrt_place`
keyed on `place_uid` 20000030 (foundation) and 20040010 (v2), and 2
rows to `RDB_MODERN.dbo.nrt_place_tele` keyed on the same two
place_uids. Those identities are not new UIDs — they reference the
foundation entity created in 00_foundation.sql plus the v2 entity above.

## SRTE codes referenced

| Table.column | Value | code_set_nm | Notes |
| --- | --- | --- | --- |
| place.cd (v2 only) | `M` | `PLACE_TYPE` | Motel/Hotel — verified in `code_value_general WHERE code_set_nm='PLACE_TYPE'`. Foundation place.cd left NULL per Tier 0 contract. |
| entity.class_cd (v2) | `PLC` | `ENTITY_CLS` | matches foundation Place |
| entity_locator_participation.class_cd | `PST` | `EL_CLS` | postal pivot |
| entity_locator_participation.class_cd | `TELE` | `EL_CLS` | tele pivot |
| entity_locator_participation.use_cd | `WP` | `EL_USE` | work-place; required by event SP's address pivot at lines 91-94 |
| entity_locator_participation.cd (postal) | `PLC` | `EL_TYPE_PST_PLC` | event SP filter at line 93 (`elp.CD='PLC'`); SRTE has only this one code in the codeset |
| entity_locator_participation.cd (tele phone) | `PH` | `EL_TYPE_TELE_PLC` | event SP exposes via `fn_get_value_by_cvg(elp.cd, 'EL_TYPE_TELE_PLC')` at line 105-110 |
| entity_locator_participation.cd (tele fax) | `FAX` | `EL_TYPE_TELE_PLC` | shape-only on v2 — additional locator |
| entity_id.type_cd (v2) | `QEC` | `EI_TYPE` (event SP filter at line 68) | Quick Entry Code; surfaces in the `place_entity` JSON branch as `place_quick_code` |
| place / postal_locator state_cd | `13` | (read-through to `nbs_srte.dbo.State_code`) | Georgia |
| place / postal_locator cnty_cd | `13121` | (read-through to `nbs_srte.dbo.State_county_code_value`) | Fulton County |
| place / postal_locator cntry_cd | `840` | (read-through to `nbs_srte.dbo.Country_code`) | United States |
| postal_locator zip_cd | `30303` | not coded | conventional |

`EL_USE_TELE_PLC` has only the code `WP` (verified). The event SP
exposes it via `fn_get_value_by_cvg(elp.use_cd, 'EL_USE_TELE_PLC')` at
lines 111-116; the fixture uses `WP` for both the foundation and v2
tele ELP rows.

`EL_USE_PST_PLC` has only the code `WP` (verified). The event SP does
not invoke `fn_get_value_by_cvg(elp.use_cd, 'EL_USE_PST_PLC')` — it
uses `elp.use_cd='WP'` directly as a filter (line 92). Documenting the
codeset for completeness.

## nrt_place / nrt_place_tele shape decisions

- `nrt_place` columns set: `place_uid`, `cd`, `place_type_description`,
  `place_local_id`, `place_name`, `place_general_comments`,
  `place_add_time`, `place_add_user_id`, `place_last_change_time`,
  `place_last_chg_user_id`, `place_record_status`,
  `place_record_status_time`, `place_status_cd`, `place_status_time`,
  `place_quick_code`, `assigning_authority_cd`, `place_postal_uid`,
  `place_zip`, `place_city`, `place_country`,
  `place_street_address_1`, `place_street_address_2`,
  `place_county_code`, `place_state_code`, `place_address_comments`,
  `place_elp_cd`, `place_state_desc`, `place_county_desc`,
  `place_country_desc`. All non-generated columns set; the two
  `GENERATED ALWAYS` columns (`refresh_datetime` AS_ROW_START,
  `max_datetime` AS_ROW_END — verified via
  `sys.columns.generated_always_type IN (1,2)`) are omitted from the
  INSERT column list per the Tier 1 contract.
- `nrt_place_tele` columns set: `place_uid`,
  `place_tele_locator_uid`, `place_phone_ext`, `place_phone`,
  `place_email`, `place_phone_comments`, `tele_use_cd`, `tele_cd`,
  `place_tele_type`, `place_tele_use`. Both NOT-NULL columns
  (`place_uid`, `place_tele_locator_uid`) are populated; the same two
  GENERATED ALWAYS columns (`refresh_datetime`, `max_datetime`) are
  omitted.
- `nrt_place_key` is NOT hand-written, per the Tier 1 contract — the
  postprocessing SP allocates surrogate keys via IDENTITY at
  lines 566-571.

## Decisions made under ambiguity

- **Place type:** `cd='M'` (Motel/Hotel) chosen for v2 from the
  PLACE_TYPE codeset. PLACE_TYPE has 25 codes; any would have worked.
  Motel/Hotel is conventional NBS for fixture work and the
  short-description "Motel/Hotel" cleanly fits D_PLACE
  PLACE_TYPE_DESCRIPTION's varchar(25). The dispatch's reminder
  ("place.cd flagged 'Tier 1 place agent picks place type' — populate
  on v2 only, NOT via UPDATE on foundation") was followed exactly.
- **Foundation Place: postal locator allocation strategy.** The
  event SP's address pivot at lines 91-94 requires (PST,WP,PLC).
  Foundation's postal_locator 20000031 is wired via (PST,H,H).
  Two ways to introduce the (PST,WP,PLC) tuple:
  (a) add a second ELP row for the same locator with the new
  (use_cd,cd) pair, or
  (b) allocate a new postal_locator and wire it via (PST,WP,PLC).
  Option (a) fails: ELP PK is `(entity_uid, locator_uid)` (verified
  the hard way — first apply attempt violated `PK__Entity_locator_p__33D4B598`).
  Option (b) is implemented. The new locator (20040000) carries the
  same address content as 20000031 so the (PST,WP,PLC) ELP edge
  exposes a meaningful row to the event SP without modifying the
  foundation locator. The synthetic `nrt_place` row for the
  foundation Place sets `place_postal_uid=20040000` (the new
  work-place locator) so D_PLACE.PLACE_POSTAL_UID mirrors the
  (PST,WP,PLC) edge the event SP would have pivoted in production.
- **PLACE_LAST_UPDATED_BY uses `place_add_user_id`, not
  `place_last_chg_user_id`.** This is a quirk of the
  postprocessing SP at lines 104-107: both USER_PROFILE joins
  (alias `B` for ADDED_BY, alias `C` for LAST_UPDATED_BY) JOIN ON
  `nrt.place_add_user_id = b.nedss_entry_id` /
  `nrt.place_add_user_id = c.nedss_entry_id`. The
  `nrt.place_last_chg_user_id` column exists on `nrt_place` and is
  read separately into `PLACE_LAST_CHG_USER_ID`, but it is not used
  to derive the LAST_UPDATED_BY name. This appears to be a SP
  authoring typo (should the second join be on
  `place_last_chg_user_id`?), but per the Tier 1 contract we don't
  own the SP — fixture matches what the SP does. Documented here for
  the diff tool / Tier 3 review.
- **PLACE_STATE column.** The postprocessing SP's INSERT INTO
  D_PLACE column list (lines 573-610) does NOT include a column named
  `PLACE_STATE` — D_PLACE has `PLACE_STATE_DESC` and `PLACE_STATE_CODE`
  only (verified via `sys.columns`). The catalog
  (`rtr_target_columns.md` line 1148-1149) lists both
  `PLACE_STATE_CODE` and `PLACE_STATE_DESC`, no separate `PLACE_STATE`.
  The Patient SP exposes a `PATIENT_STATE` column; Place does not.
  The local SELECT inside the SP at line 56-58 aliases
  `nrt.place_state_desc` as `PLACE_STATE`, but that's an
  intermediate-temp-table column, not a D_PLACE column.
- **place.cd_desc_txt set to 'Motel/Hotel' on v2.** The event SP
  computes `place_type_description` via
  `fn_get_value_by_cvg(p.cd, 'PLACE_TYPE')`. Setting cd_desc_txt is
  shape-only — the SP doesn't read it; we set it for ODSE-row
  shape consistency.
- **assigning_authority_cd on nrt_place.** The event SP at lines
  64-69 emits `assigning_authority_cd` from the entity_id row when
  `type_cd='QEC'`. v2 has a QEC entity_id row with
  `assigning_authority_cd=NULL` (no authority for an internal
  quick-entry code), so the JSON projection emits null. The
  hand-authored `nrt_place` v2 row sets
  `assigning_authority_cd='NBS'` (internal placeholder) to drive a
  non-null value into D_PLACE — but D_PLACE has no
  `ASSIGNING_AUTHORITY_CD` column (verified). The column is
  read into the SP's #tmp_place_table at line 52 but is never
  propagated to D_PLACE in either the UPDATE (lines 452-489) or
  INSERT (lines 573-610) of the SP. Recording this as
  `OUT_OF_SCOPE` below.
- **Foundation Place add_user_id stays at 10009282.** The
  superuser_id 10009282 is not present in baseline RDB_MODERN
  USER_PROFILE, so the LEFT JOIN to USER_PROFILE returns NULL and
  PLACE_ADDED_BY / PLACE_LAST_UPDATED_BY are NULL on the foundation
  Place's D_PLACE rows. v2 uses `place_add_user_id=10003000` (Nelson,
  Jay — verified present in baseline USER_PROFILE) so v2's
  PLACE_ADDED_BY = `Nelson, Jay`. This pairs the populated and
  null-USER_PROFILE-match paths via the variant strategy.

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| nrt_place | refresh_datetime, max_datetime | GENERATED ALWAYS (AS_ROW_START / AS_ROW_END temporal-table system-period). SQL Server populates them on INSERT; explicit INSERTs into them fail. | `sys.columns.generated_always_type IN (1,2)` |
| nrt_place_tele | refresh_datetime, max_datetime | same | same |
| nrt_place_key | (all columns) | Per the Tier 1 contract, surrogate-key store is allocated by the postprocessing SP via IDENTITY (lines 566-571). Hand-authoring keys would be non-deterministic and would shift across runs. | `prompts/templates/tier_1_subject.md` "Do NOT write nrt_<<subject>>_key" |
| place | from_time, to_time, duration_amt, duration_unit_cd, user_affiliation_txt, add_reason_cd, last_chg_reason_cd, city_cd, phone_nbr, phone_cntry_cd | The event SP and the postprocessing SP do not read these `place` columns. None are referenced anywhere in `rtr_target_columns.md` for `D_PLACE`. | `068-sp_place_event-001.sql` SELECT projection — none of these columns appear |
| D_PLACE | (none) | Every column the postprocessing SP writes is populated for at least one D_PLACE row in this fixture. | this report |

## Gaps reported

- `OUT_OF_SCOPE: nrt_place.assigning_authority_cd is read into
  #tmp_place_table at sp_nrt_place_postprocessing-001.sql:52 but is
  never propagated into D_PLACE — no ASSIGNING_AUTHORITY_CD column
  exists on D_PLACE (verified via sys.columns), and neither the UPDATE
  (lines 452-489) nor the INSERT (lines 573-610) of the SP references
  it. This appears to be dead read in the SP. Documenting for the
  comparison-tool diff phase / Tier 3 review.`
- `OUT_OF_SCOPE: D_INV_PLACE_REPEAT / L_INV_PLACE_REPEAT — written
  by sp_repeated_place_postprocessing (file 035), which takes
  @phc_id_list (Public Health Case UIDs) and requires Investigation +
  cross-subject act_relationship/participation rows wiring PHC →
  places. That SP is Tier 2 / Tier 3 territory per the Place dispatch
  prompt. The Place fixture deliberately does NOT invoke
  sp_repeated_place_postprocessing.`
- `LINK_REQUIRED: act_relationship + participation rows wiring the v2
  Place (UID 20040010) to the foundation Investigation (UID 20000100)
  via type_cd 'PlaceOfExposure' / 'HangoutOfPHC' / 'SexOfPHC' (per
  catalog/edge_types.md and sp_repeated_place_postprocessing). When
  Tier 2 picks this up, the resulting D_INV_PLACE_REPEAT /
  L_INV_PLACE_REPEAT rows will reference the v2 Place's
  PLACE_LOCATOR_UID. Tier 1 Place exposes the population side;
  Tier 2 owns the linkage side.`
- (no SRTE_GAP)
- (no FOUNDATION_GAP)

## Notes for the Tier 1 template

- **First subject with two staging tables.** Place is the first
  Tier 1 subject to require a second `nrt_*` staging table
  (`nrt_place_tele` in addition to `nrt_place`). The postprocessing
  SP's LEFT JOIN at line 103 means the tele staging row is optional
  — if missing, every PLACE_PHONE / PLACE_EMAIL /
  PLACE_TELE_LOCATOR_UID column comes through NULL. To exercise the
  populated-tele path you must hand-author `nrt_place_tele` rows.
  The same two GENERATED ALWAYS columns (`refresh_datetime`,
  `max_datetime`) appear on both tables.
- **ELP composite-PK gotcha.** The
  `entity_locator_participation` table's PK is
  `(entity_uid, locator_uid)`, NOT `(entity_uid, locator_uid,
  use_cd, cd)`. To introduce a second `(use_cd, cd)` tuple for a
  given (entity, locator) pair, you must allocate a new
  `tele_locator` / `postal_locator` and wire it as a separate ELP
  row. Adding an ELP "second edge" for the same locator UID
  collides on PK. The Place fixture took an iteration to discover
  this; future subjects with similar enrichment patterns (i.e.,
  needing to attach a foundation-locator under a different ELP
  tuple) should allocate a new locator from the start.
- **Postprocessing-SP UNION ALL fan-out.** Place is the first
  subject where the postprocessing SP UNION-ALLs four composite-key
  branches (Base / Postal-only / Tele-only / Both — see
  `028-sp_nrt_place_postprocessing-001.sql:206-402`). When both
  postal and tele are present on a place_uid, this produces 4
  D_PLACE rows per place_uid — not 1. Coverage analysis must
  account for this: a column NULL on the Tele-only row but
  populated on the Both row is still "covered" overall.
- **PLACE_LAST_UPDATED_BY apparent SP typo.** The two USER_PROFILE
  joins both ON `nrt.place_add_user_id`. The "last updated by" name
  is therefore the same person as "added by". This is in the SP body
  as written and the fixture matches it. Future subjects should
  spot-check their postprocessing SP for similar copy-paste errors
  (the Provider canary's `#PATIENT_UPDATE_LIST` typo was the same
  family).
