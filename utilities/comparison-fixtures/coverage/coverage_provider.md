# Coverage: provider (Tier 1 canary)

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: 20010000 - 20019999 (Provider Tier 1, per canary prompt)
  - Note: `catalog/uid_ranges.md` originally proposed 20020000-20029999 for
    Provider; the canary prompt overrides with 20010000-20019999. Registry
    updated to claim 20010000-20019999 for Provider, leaving 20020000-20029999
    re-suggested for Patient (or any other Tier 1 subject).
- Foundation dependencies:
  - `@dbo_Entity_provider_uid` = 20000010 (Provider Person+Entity)
  - `@dbo_Postal_locator_provider` = 20000011 (Provider work postal locator)
  - `@dbo_Tele_locator_provider` = 20000012 (Provider work tele locator, cd='PH')
- Other-agent dependencies: none (canary)

## SPs verified
- `dbo.sp_provider_event` — exit code: 0; emitted 2 rows (foundation + v2). Pure
  SELECT — does NOT write `dbo.nrt_provider`. See "Notes for Tier 1 template".
- `dbo.sp_nrt_provider_postprocessing` — exit code: 0; `job_flow_log`
  status_type=`COMPLETE` recorded for batch under `Provider POST-Processing`,
  step_name=`SP_COMPLETE`. Insert step row_count=2.

## Apply / FK check
- `sqlcmd -i 00_foundation.sql` exit code: 0 (clean re-apply, no iterations).
- `sqlcmd -i 10_subjects/provider.sql` exit code: 0 after fixing two issues
  during authoring (see iteration count below).
- Both SPs ran without `BEGIN CATCH` activation; `job_flow_log` shows no
  ERROR rows for either invocation.

## Iteration count
- 2 baseline-reset cycles.
  - Cycle 1: discovered `sp_provider_event` does not write `nrt_provider`
    (postprocessing returned "Missing NRT Record"). Pivoted strategy to
    populate `dbo.nrt_provider` directly in the fixture.
  - Cycle 2: hit two authoring errors on first apply
    (`person.nm_degree` doesn't exist; `nrt_provider.refresh_datetime` is
    GENERATED ALWAYS). Fixed in-place and re-applied without another reset.
    The reset for cycle 2 was driven by needing a clean slate after the
    cycle-1 nrt_provider population was empty.

## D_PROVIDER coverage
**34/34 columns the SP writes are populated for at least one provider** (v2
provider, UID 20010010, populates every column non-NULL).

| Column | Source (postprocessing SP) | Sample value (v2) | Foundation (20000010) |
| --- | --- | --- | --- |
| PROVIDER_UID | nrt.provider_uid | 20010010 | 20000010 |
| PROVIDER_KEY | nrt_provider_key.d_provider_key (auto-issued by SP) | 13 | 12 |
| PROVIDER_LOCAL_ID | nrt.local_id | `PSN20010010GA01` | `PSN20000010GA01` |
| PROVIDER_RECORD_STATUS | nrt.record_status | `ACTIVE` | `ACTIVE` |
| PROVIDER_NAME_PREFIX | nrt.name_prefix | `DR` | NULL (deliberate) |
| PROVIDER_FIRST_NAME | nrt.first_name | `Variant` | `Foundation` |
| PROVIDER_MIDDLE_NAME | nrt.middle_name | `Q` | NULL (deliberate) |
| PROVIDER_LAST_NAME | nrt.last_name | `Provider` | `Provider` |
| PROVIDER_NAME_SUFFIX | nrt.name_suffix | `JR` | `MD` |
| PROVIDER_NAME_DEGREE | nrt.name_degree | `PhD` | NULL (deliberate) |
| PROVIDER_GENERAL_COMMENTS | nrt.general_comments | `Tier 1 variant provider — exercises every D_PROVIDER column.` | NULL (deliberate) |
| PROVIDER_QUICK_CODE | nrt.quick_code (blank → NULL) | `V2QUICK` | NULL (deliberate) |
| PROVIDER_REGISTRATION_NUM | nrt.provider_registration_num (blank → NULL) | `REG-12345` | NULL (deliberate) |
| PROVIDER_REGISRATION_NUM_AUTH | nrt.provider_registration_num_auth (sic — typo in DDL) | `State Medical Board` | NULL (deliberate) |
| PROVIDER_STREET_ADDRESS_1 | nrt.street_address_1 | `2010 Variant Provider Way` | `200 Provider Plaza` |
| PROVIDER_STREET_ADDRESS_2 | nrt.street_address_2 | `Suite 200` | NULL (deliberate) |
| PROVIDER_CITY | nrt.city | `Atlanta` | `Atlanta` |
| PROVIDER_STATE | nrt.state | `Georgia` | `Georgia` |
| PROVIDER_STATE_CODE | nrt.state_code | `13` | `13` |
| PROVIDER_ZIP | nrt.zip | `30303` | `30303` |
| PROVIDER_COUNTY | nrt.county | `Fulton County` | `Fulton County` |
| PROVIDER_COUNTY_CODE | nrt.county_code | `13121` | `13121` |
| PROVIDER_COUNTRY | nrt.country | `United States` | `United States` |
| PROVIDER_ADDRESS_COMMENTS | nrt.address_comments | `v2 Provider work address` | `Provider work address` |
| PROVIDER_PHONE_WORK | nrt.phone_work | `404-555-1010` | `404-555-0210` |
| PROVIDER_PHONE_EXT_WORK | nrt.phone_ext_work | `5678` | `1234` |
| PROVIDER_EMAIL_WORK | nrt.email_work | `variant.provider@nbs.test` | `foundation.provider@nbs.test` |
| PROVIDER_PHONE_COMMENTS | nrt.phone_comments | `v2 Provider work phone` | `Provider work phone/email` |
| PROVIDER_PHONE_CELL | nrt.phone_cell | `404-555-1011` | NULL (deliberate) |
| PROVIDER_ENTRY_METHOD | nrt.entry_method | `ELECTRONIC` | `ELECTRONIC` |
| PROVIDER_LAST_CHANGE_TIME | nrt.last_chg_time | `2026-04-01 00:00:00` | same |
| PROVIDER_ADD_TIME | nrt.add_time | `2026-04-01 00:00:00` | same |
| PROVIDER_ADDED_BY | nrt.add_user_name | `Kent, Ariella` | `Kent, Ariella` |
| PROVIDER_LAST_UPDATED_BY | nrt.last_chg_user_name | `Kent, Ariella` | `Kent, Ariella` |

Per-row NULL counts (out of 34 SP-written columns):
- 20000010 (foundation, minimal): 9 NULLs (deliberately, to exhibit the
  "blank → NULL" transform path in the SP for QUICK_CODE / REGISTRATION_NUM /
  REGISTRATION_NUM_AUTH / STREET_ADDRESS_2 / etc.).
- 20010010 (v2, fully attributed): 0 NULLs.

## D_PROVIDER_HIST coverage
**Not applicable.** No `D_PROVIDER_HIST` table exists in RDB_MODERN at this
baseline (`SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_NAME='D_PROVIDER_HIST'` returns 0). `catalog/rtr_target_columns.md`
contains no `D_PROVIDER_HIST` entry. The canary prompt's mention of
`D_PROVIDER_HIST` (Step 5 and Stop conditions) is a phantom — likely
copy-paste from a Patient-style prompt where `D_PATIENT_HIST` does exist.
Recorded as `OUT_OF_SCOPE: D_PROVIDER_HIST does not exist in RDB_MODERN`.

## Other RTR-write tables touched by the Provider chain
- `dbo.nrt_provider_key` — 2 rows inserted by the postprocessing SP (one per
  provider UID), surrogate key allocator. Catalog does not list this table
  as an RTR target (it's an internal staging key store).
- `dbo.D_PROVIDER` — 2 rows inserted (above).
- `dbo.job_flow_log` — 8 START rows + 1 COMPLETE row for postprocessing,
  plus 2 rows for the event SP. Logging only; not a coverage target.
- `dbo.PROVIDER_LDF_GROUP` — written by `sp_nrt_ldf_postprocessing`, NOT by
  the provider chain. Out of scope for this canary.

## Columns populated
See D_PROVIDER table above (34/34).

## Columns deliberately skipped
| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| D_PROVIDER (foundation row) | PROVIDER_NAME_PREFIX, MIDDLE_NAME, NAME_DEGREE, GENERAL_COMMENTS, QUICK_CODE, REGISTRATION_NUM, REGISRATION_NUM_AUTH, STREET_ADDRESS_2, PHONE_CELL | Deliberately left NULL on the foundation provider so the SP's `blank/whitespace → NULL` transform path is observable in the diff. The same columns ARE populated on v2 (20010010), so D_PROVIDER coverage = 34/34. | `003-sp_nrt_provider_postprocessing-001.sql:52-94` (CASE WHEN rtrim(ltrim(...)) = '' THEN NULL) |

## Gaps reported

### SRTE_GAP
- (none) — every SRTE code referenced is present in baseline 6.0.18.1.

### LINK_REQUIRED
- (none) — D_PROVIDER coverage requires no cross-subject act_relationship /
  participation / nbs_act_entity rows. Future Tier 2 work might link a
  Provider to an Investigation/Lab via `participation` (e.g.,
  `PhysicianOfPHC`), which would feed Datamart-level provider columns
  (PHYSICIAN_NAME etc.) — those are Datamart-SP responsibilities, not the
  provider postprocessing SP itself.

### OUT_OF_SCOPE
- `D_PROVIDER_HIST` — table does not exist in RDB_MODERN at baseline 6.0.18.1.
  Canary prompt mentions it but neither the catalog nor the live schema has
  it. Likely a copy-paste artifact from Patient context.
- Provider columns appearing on Datamart tables (HEPATITIS_DATAMART,
  TB_DATAMART, MORBIDITY_REPORT_DATAMART, COVID_LAB_DATAMART, INV_SUMM_DATAMART,
  STD_HIV_DATAMART, etc.) such as `PHYSICIAN_NAME`, `INVESTIGATOR_PHONE_NUMBER`,
  `LAB_REPORT_FACILITY_NAME`, `ORDERING_PROVIDER_NAME`. These are written by
  Datamart SPs (`sp_provider_dim_columns_update_to_datamart` and friends) and
  populated only after Tier 2 links plus Datamart SP runs. They are NOT
  written by `sp_nrt_provider_postprocessing` and are out of this canary's
  scope per the stop conditions.
- `dbo.nrt_provider` columns `provider_npi` and `country_code` — present on
  the staging table but `sp_nrt_provider_postprocessing` does not propagate
  them to D_PROVIDER (only `country` and the registration_num fields make
  it through). The fixture sets them on staging anyway for completeness; if
  a future RTR change starts to read `provider_npi`, no fixture change
  required.

### FOUNDATION_GAP
- (none caused this canary to fail), but two **soft-amend candidates** for
  the foundation worth flagging to a future Tier 0 amendment:
  1. The foundation Provider's TELE locator uses `cd='PH'`, but
     `sp_provider_event` filters phone/email on `cd IN ('O')` (lines
     115-118). With only the foundation row, the upstream JSON's
     `phone`/`email` blobs are NULL for the foundation provider. Provider
     fixture compensates by adding a (TELE, WP, O) locator on the
     foundation Provider. If the foundation rather hardcoded `cd='O'` /
     `cd='PH'` more carefully, every Tier 1 agent that consumes the
     Provider's contact info via the event SP would benefit.
  2. The foundation Provider has no `entity_id` row. The Provider event
     SP serializes entity_id rows into the SELECT output's
     `provider_entity` JSON. Tier 0 deliberately deferred entity_id rows;
     this fixture adds `entity_id (NPI)` for both the foundation and v2
     providers to populate that JSON. This is correct per the corrections
     in the prompt header.

## Notes for Tier 1 template

### Things that surprised me / required guesswork / aren't obvious from the prompt and SHOULD be in the template

1. **The `_event` SP does NOT write the `nrt_<entity>` staging table.**
   STRATEGY.md §"RTR transformation chain" reads:
   > `EXEC dbo.sp_<entity>_event @<uid>_list = '<csv>'           -- ODSE → nrt_*`
   This is wrong for at least `sp_provider_event`. The SP body is purely a
   `SELECT` whose output is consumed by the upstream Java service
   (`person-service`), serialized to JSON, published to Kafka, and written
   to `nrt_provider` by a kafka-connect-sink. The SP itself never inserts
   into `nrt_provider`. Running only foundation + EXEC chain results in
   `sp_nrt_provider_postprocessing` returning "Missing NRT Record:
   sp_nrt_provider_postprocessing" with `@backfill_list != NULL`. Every
   Tier 1 agent that follows this template will hit the same wall unless
   the template explicitly says: **populate the `nrt_<entity>` staging
   table directly in your fixture file**, mirroring what the upstream
   Java service would have written.
   - Suggested template language: "After authoring ODSE rows, add direct
     INSERTs to `dbo.nrt_<entity>` in `[RDB_MODERN]` with the columns the
     postprocessing SP reads. Treat the event SP as a *contract test*
     (run it and inspect its SELECT output to ensure your ODSE rows would
     produce the expected JSON), not as the staging-table populator."

2. **The catalog can drift from the live schema.** The canary prompt asks
   for `D_PROVIDER_HIST` coverage, but no such table exists, and the
   catalog (rtr_target_columns.md) doesn't list it. Templates should
   require the agent to verify each named table exists via
   `INFORMATION_SCHEMA.TABLES` before treating it as a coverage target,
   and report dead-named-tables as `OUT_OF_SCOPE` rather than as missing
   coverage.

3. **The postprocessing SP has a known typo / latent bug.** Line 564 of
   `003-sp_nrt_provider_postprocessing-001.sql` references
   `#PATIENT_UPDATE_LIST` but the actual temp table is
   `#PROVIDER_UPDATE_LIST` (declared on line 273). The path is only
   reachable on UPDATE-with-meaningful-diff, and the canary fixture only
   exercises INSERT, so the bug doesn't fire here. Future Tier 1 / Tier 3
   agents who exercise UPDATE flows (re-running the SP after changing
   ODSE for the same UIDs) WILL hit it. Templates should ask the agent
   to spot-grep the SP for obvious typos as part of the static extract.

4. **Column-name typo: `PROVIDER_REGISRATION_NUM_AUTH`** (missing a `T`)
   is the actual column name in D_PROVIDER and nrt_provider — preserve
   the typo when writing INSERTs. Templates should warn agents not to
   "fix" what looks like a typo.

5. **`nrt_<entity>` may have temporal-table system-period columns
   (GENERATED ALWAYS).** `nrt_provider.refresh_datetime` and `max_datetime`
   are `AS_ROW_START` / `AS_ROW_END` columns. INSERTs with column lists
   that include these fail with
   `"Cannot insert an explicit value into a GENERATED ALWAYS column"`.
   Templates should note this and tell agents to either (a) omit those
   columns from the column list, or (b) use `INSERT INTO ... DEFAULT VALUES`
   for those columns.

6. **The prompt's UID block (`20010000-20019999` for Provider) doesn't
   match the registry's suggested block (`20020000-20029999`).** Resolved
   by trusting the prompt and updating the registry. Templates need to
   warn that prompt-supplied UID blocks override the registry's
   "suggested" rows, and that the agent must update the registry as part
   of the deliverable.

7. **`person.nm_degree` does NOT exist on `dbo.person` — only on
   `dbo.person_name`.** Several similar-looking name columns split across
   the two tables. Templates should warn agents to check
   INFORMATION_SCHEMA.COLUMNS before transcribing field lists between
   Person and PersonName.

8. **The event SP filters TELE locators on `cd IN ('O')`, NOT `cd='PH'`,
   to populate phone_work/email_work.** Foundation's Provider TELE row
   uses `cd='PH'` (which matches RTR's general telephone shape but is
   filtered out for Provider work-phone purposes). This subtle filter
   mismatch was the single biggest unintuitive thing about driving
   Provider data flow. Templates should explicitly cite each SP's locator
   filter (e.g., "Provider phone_work requires `(TELE, WP, O)`, not
   `(TELE, WP, PH)`") as part of the per-subject prompt.

9. **`job_flow_log.job_flow_id` is the wrong order column.** The
   canary prompt's verification recipe uses `ORDER BY job_flow_id DESC`,
   but that column doesn't exist; the actual identity column is
   `batch_id` (and `step_number`). Templates should drop `job_flow_id`
   from sample queries.

10. **The `condition_cd` column in some `dbo.code_value_general` filters
    is verified by the catalog, but the locator-side codes (`EL_CLS`,
    `EL_USE`, `EL_TYPE`) are not in `code_value_general` — they live in
    other code-set tables.** I didn't need to grind on this for the
    Provider canary because the foundation already established locator
    codes, but a Tier 1 template that says "verify every code in
    `code_value_general`" will mislead agents.

### Things the prompt got right and should keep

- **Static-extract first, run second.** Reading both SPs end-to-end before
  the first run was the right move; it surfaced the
  `(TELE, WP, O)` filter mismatch on foundation locators *before* I ran
  the SP and saw the JSON `phone` blob be NULL.
- **Iterate via `docker compose down -v` between major changes.** The
  full reset cycle is slow (3-5 min for liquibase) but it eliminates
  state from prior failed runs. For mid-cycle iteration where I just
  want to re-apply the fixture, I could *not* use down -v because the
  postprocessing SP is idempotent only for INSERT-vs-UPDATE — the
  primary key is `provider_uid` so a second run produces UPDATEs and
  exercises a different path. Reset between major iterations is
  correct.
- **`SQLCMDPASSWORD` env var, not `-P`.** Got bitten by zsh history
  expansion on `!` exactly once before adopting the env var; the
  correction in the prompt was correct and saved time.
- **Cite SRTE codes with `code_set_nm`-and-value comments above each
  row.** The grounding discipline made it easy to verify codes when the
  fixture initially failed schema checks (helped me realize the
  `cd='O'` vs `cd='PH'` issue without re-reading the SP).
- **"Enrich foundation Provider rather than create a separate variant"
  unless a CASE branch demands a variant.** I did both: enriched the
  foundation Provider with new locator + entity_id rows AND created a
  separate v2 Provider, because the postprocessing SP doesn't have CASE
  branches I could exercise with a single attribute swap — the only way
  to demonstrate "every column populated for ≥1 provider" while also
  showing the SP's `blank → NULL` path is to have one minimal and one
  fully-attributed row. Worth keeping the guidance and adding "or to
  exercise both `populated` and `blank/NULL` paths in a single SP run".
- **The "stop conditions" list is exactly what an agent needs.** Clear,
  testable, short. Keep.

### Open questions for the human reviewer

1. **Should the fixture populate `nrt_<entity>` directly, or should the
   project add fixture-only SPs that mirror what kafka-connect-sink does
   in production?** The first approach (chosen here) is simple but
   couples the fixture to internal-staging-table column names. If those
   change, every Tier 1 fixture breaks. A
   `dbo.sp_provider_event_to_nrt(@uid_list)` helper SP, parked in
   `utilities/comparison-fixtures/scripts/`, would isolate the
   coupling. Worth considering before all 11 Tier 1 agents copy the
   pattern.

2. **Does the comparison goal (RDB vs RDB_MODERN diff) actually need
   ODSE rows that mirror nrt_provider, or only the nrt_provider rows
   themselves?** I authored both because the prompt's "every code you
   write must exist in baseline SRTE — verify with sqlcmd, cite
   `code_set_nm` and value in a comment" is most naturally interpreted
   as ODSE-INSERT-grounded. If the true goal is just `D_PROVIDER` and
   downstream RDB_MODERN coverage, the ODSE side may be vestigial for
   Tier 1 (still important for Tier 2 / Tier 3 act_relationship +
   participation flows). Want guidance.

3. **Should Tier 1 fixtures include direct writes to `nrt_provider_key`
   to fix the surrogate keys?** Right now, `D_PROVIDER.PROVIDER_KEY` is
   `12` for the foundation provider and `13` for v2. These keys are
   non-deterministic (depend on the IDENTITY column in
   `nrt_provider_key`). The diff tool will need to ignore PROVIDER_KEY
   or remap. Either acceptable; needs a documented decision.

4. **What's the canonical fixture for "minimal but coverable" rows?**
   The foundation provider has 9 NULLs by my choice. If the project
   wants every D_PROVIDER column populated for the foundation
   provider too, I should change the foundation `nrt_provider` row to
   set every column. Conversely, if the project wants to *deliberately*
   exercise "blank → NULL" SP transforms at row level, the current
   approach is correct. Need a project-wide convention.

5. **Should the registry (`uid_ranges.md`) be updated to allocate the
   block the prompt actually uses, or to note that the prompt-block and
   registry-block disagree?** I did the former (claimed
   20010000-20019999 for Provider). If the registry's
   "suggested" rows are normative for downstream agents, they need to
   be reconciled before each Tier 1 agent fires.
