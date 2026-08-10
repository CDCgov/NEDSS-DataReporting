# Person Module ModelMapper Integration (Proposed)

> **Status: not yet implemented.** This document records a deliberate, scoped refactor plan for later. It is large enough that it's being tracked here rather than implemented inline with the bug investigation that motivated it.

## Context

Investigation, observation, and postprocessing already use `ReportingPipelineModelMapper` (a `ModelMapper` subclass that converts blank/whitespace-only strings to `null`) to prevent empty strings from being persisted to `RDB_MODERN`. The person module (Patient/Provider/AuthUser) never adopted `ModelMapper` at all — it uses hand-written Lombok `.builder()` chains (`PersonTransformers.buildPatientReporting`/`buildProviderReporting`/`buildPatientElasticSearch`/`buildProviderElasticSearch`) and static factory methods (`NrtPatient.from()`, `NrtProvider.from()`, `NrtAuthUser.from()`), none of which normalize blank strings.

This was confirmed live: `RDB_MODERN.dbo.nrt_patient.street_address_1`/`street_address_2` came back as `''` for a test patient, while the same source data produces `NULL` in legacy `RDB.D_PATIENT` via MasterEtl. Downstream, `sp_nrt_patient_postprocessing`/`sp_nrt_provider_postprocessing` only guard a handful of columns manually (16/155 and 12/95 respectively), and `sp_user_profile_postprocessing` guards none (0/52) — so this is a real, only-partially-mitigated gap.

This is an explicitly separate, deliberate refactor (not bundled with a narrower one-off fix). The goal is architectural consistency with the rest of the codebase's blank-to-null handling, which the person module gets as a side effect once its hand-written copying is replaced by `modelMapper.map()`.

`DataPostProcessor` (6 methods: name/address/race/telephone/entityData/email) is confirmed **not** expressible via ModelMapper — it does stateful, multi-record disambiguation (group-by + max-of-N-candidates) over JSON arrays, not a 1:1 field copy. It stays completely untouched, called exactly as today, after the ModelMapper-based build step.

## Two real field-name collisions found (must be handled explicitly, not left to ModelMapper's default matching)

1. **`PatientSp` has both `birthSex` and `birthGenderCd` as distinct properties** (`model/dto/patient/PatientSp.java:65-69`). `PatientElasticSearch.birthSex` must come from `getBirthGenderCd()` per the existing hand-written code — if left to default name-matching, ModelMapper would instead pull it from `PatientSp.birthSex`, silently changing behavior. (Note: `PatientReporting.birthSex` is fine as a default same-name match to `PatientSp.birthSex` — verified, no override needed there, only `PatientElasticSearch` needs the override.)

2. **`ProviderSp` declares bare `firstNm`/`middleNm`/`lastNm`/`nmSuffix`/`cd` properties** (`model/dto/provider/ProviderSp.java:35-48`), which exact-name-collide with same-named fields on `ProviderReporting` (`firstNm`/`middleNm`/`lastNm`/`nmSuffix` — confirmed present, no `cd` field on this one) and `ProviderElasticSearch` (all five, including `cd` — confirmed present). Today these are deliberately left unset by the hand-written builders and populated later, conditionally, by `DataPostProcessor.processPersonName`. Left to default matching, ModelMapper would auto-populate them from the raw `ProviderSp` values, which would leak through whenever `DataPostProcessor`'s nested-array lookup doesn't find a match (currently always `null` in that case; would become the raw unprocessed value). Must be explicitly `skip()`-ed in both `ProviderSp→ProviderReporting` and `ProviderSp→ProviderElasticSearch` TypeMaps.

   Also confirmed: **`PatientElasticSearch` has its own `cd` field** matching `PatientSp.cd` (currently always unset) — needs the same `skip()` treatment. `PatientReporting` has no `cd` field at all, so no skip needed there.

No other collisions found across the ~140 remaining same-name fields spanning all 7 source→destination pairs.

## Rename/conversion inventory (verified against actual field lists)

| Mapping | Renames needed | Type converters needed |
|---|---|---|
| `PatientSp → PatientReporting` | 12 (see below) | none |
| `PatientSp → PatientElasticSearch` | 3 (`patientUid`←`personUid`, `birthSex`←`birthGenderCd`, `primLangCd`←`primLang`) + skip `cd` | none |
| `ProviderSp → ProviderReporting` | 4 (`providerUid`←`personUid`, `recordStatus`←`recordStatusCd`, `entryMethod`←`electronicInd`, `generalComments`←`description`) + skip `firstNm`/`middleNm`/`lastNm`/`nmSuffix` | none |
| `ProviderSp → ProviderElasticSearch` | 5 (`providerUid`←`personUid`, `personFirstNm`←`firstNm`, `personMiddleNm`←`middleNm`, `personLastNm`←`lastNm`, `personNmSuffix`←`nmSuffix`) + skip `firstNm`/`middleNm`/`lastNm`/`nmSuffix`/`cd` | none |
| `PatientReporting → NrtPatient` | 1 (`country`←`homeCountry`) | `String→LocalDateTime` (dob, deceasedDate, addTime, lastChgTime — all same-name), `String→BigDecimal` (ageReported — same-name) |
| `ProviderReporting → NrtProvider` | 0 (`country`←`getCountry()` is same-name here, unlike Patient) | `String→LocalDateTime` (addTime, lastChgTime) |
| `AuthUser → NrtAuthUser` | 1 (`authUserId`←`authUserUid` — `Id`/`Uid` token mismatch, default matching won't catch this) | `String→LocalDateTime` (addTime, lastChgTime, recordStatusTime) |

`PatientSp → PatientReporting` renames: `patientUid`←`personUid`, `addlGenderInfo`←`additionalGenderCd`, `dob`←`birthTime`, `deceasedIndicator`←`deceasedInd`, `deceasedDate`←`deceasedTime`, `generalComments`←`description`, `entryMethod`←`electronicInd`, `unkEthnicRsn`←`ethnicUnkReason`, `patientMprUid`←`personParentUid`, `primaryLanguage`←`primLang`, `recordStatus`←`recordStatusCd`, `currSexUnkRsn`←`sexUnkReasonCd`.

`UtilHelper.parseDateTime(String)`/`parseBigDecimal(String)` (`util/UtilHelper.java:76-93`) already guard blank/null input, returning `null` — registering them as ModelMapper `Converter`s via method reference gets blank-safety for free, no extra wrapping needed.

Confirmed `org.modelmapper:modelmapper:3.2.0` (`reporting-pipeline-service/build.gradle:126`) supports the lambda/method-reference `typeMap.addMappings(mapper -> mapper.map(Source::getX, Dest::setY))` / `mapper.skip(Dest::setY)` API — use this style throughout, not the older string-property-path API.

## Implementation

### 1. `person/transformer/PersonTransformers.java`
Add `private final ModelMapper modelMapper = new ReportingPipelineModelMapper();` and register the 4 `TypeMap`s above in the constructor (a single `ModelMapper` instance can hold independent `TypeMap`s for multiple unrelated type pairs — confirmed no cross-contamination risk between e.g. `PatientSp→PatientReporting` and `PatientSp→PatientElasticSearch`). Replace each of the 4 builder methods' bodies with a one-line `return modelMapper.map(p, X.class);`.

### 2-4. `person/model/entity/{NrtPatient,NrtProvider,NrtAuthUser}.java`
Each is a static-factory JPA entity (no Spring DI). Preserve the public `.from(x)` API exactly (zero changes needed in `PersonService.java`) by giving each class its own `private static final ModelMapper MAPPER = new ReportingPipelineModelMapper();`, configured once in a `static { }` block with that class's `Converter`s and `TypeMap` (per the inventory table above). Replace each `.from()` body with `return MAPPER.map(source, Dest.class);`, deleting the hand-written field-copy code (90 lines in `NrtPatient`, ~45 in `NrtProvider`, ~15 in `NrtAuthUser`). The `Converter<String,LocalDateTime>`/`Converter<String,BigDecimal>` lambdas (`ctx -> parseDateTime(ctx.getSource())` etc.) are intentionally duplicated across the 3 files rather than centralized — keeps each entity self-contained and doesn't expand `UtilHelper.java`'s blast radius; a discretionary DRY cleanup, not required.

`refreshDatetime` (DB-generated, `insertable=false,updatable=false`) has no source-side counterpart in any of the 3 Reporting/AuthUser DTOs, so ModelMapper naturally leaves it unset — no special handling needed.

### Unchanged
`DataPostProcessor.java`, `PersonService.java` (all call sites keep identical signatures), `ReportingPipelineModelMapper.java` itself (not modified — each consumer layers its own `Converter`/`TypeMap` config on top of its own instance, same pattern as `InvestigationService`/`ObservationService`/`ProcessDatamartData`).

## Verification plan (for whenever this is implemented)

1. **New unit tests** (no dedicated coverage exists today for `PersonTransformers`'s build methods or the 3 `.from()` factories in isolation):
   - `person/transformer/PersonTransformersTest.java` — build `PatientSp`/`ProviderSp` via `.builder()` with **distinct, differentiating values** for every collision field (different strings for `birthSex` vs `birthGenderCd`; non-blank `firstNm`/`middleNm`/`lastNm`/`nmSuffix`/`cd` on `ProviderSp`, non-blank `cd`/`birthSex` on `PatientSp`), call each `buildXxx`, and assert: all 24 renames land correctly; `PatientElasticSearch.getBirthSex()` equals the `birthGenderCd` test value and *not* the `birthSex` value; `ProviderReporting`/`ProviderElasticSearch`'s skipped fields and `PatientElasticSearch.getCd()` are `null` after the build step; blank/whitespace fields resolve to `null`.
   - `person/model/entity/{NrtPatientTest,NrtProviderTest,NrtAuthUserTest}.java` — build the Reporting/AuthUser source with blank strings in a couple of fields plus the `homeCountry`/`authUserUid` renames, call `.from()`, assert renames, date/decimal parsing (including blank→`null`), and blank-to-null resolution — same style as the existing `ReportingPipelineModelMapperTest.java` (don't modify that file; these are new, separate files).

   **Important correction to note**: the existing `PersonServiceTest.java` (`constructPatient()`/`constructProviderCase()`, lines 381-408) builds its `PatientSp`/`ProviderSp` test fixtures with **only `personUid` and the nested JSON fields set** — `birthSex`, `birthGenderCd`, `firstNm`, `middleNm`, `lastNm`, `nmSuffix`, `cd` are all left `null`/unset. So this existing test does **not** currently exercise either collision and can't serve as a regression gate for them — verified directly, not assumed. It should still be run and must still pass unmodified (general wiring/smoke coverage), but `PersonTransformersTest` above is the real authority on the two collisions; don't expand `PersonServiceTest`'s fixtures as part of this change (avoids scope creep into a widely-used existing test file).

2. **Existing tests that must pass unmodified**: `PersonServiceTest.java`, `PersonDataPostProcessingTests.java` (exercises `DataPostProcessor` directly — unaffected since that file doesn't change; passing confirms the `skip()`s correctly hand ownership to it), `PersonDetailsDeserializationTests.java` (unrelated, JSON deserialization only).

3. **Compile check** after wiring: `./gradlew :reporting-pipeline-service:compileJava :reporting-pipeline-service:compileTestJava` — mechanically catches any typo across the 26 rename mappings + 9 `skip()` calls via method-reference compile errors.

4. **Full suite**: `./gradlew :reporting-pipeline-service:test`, `:test-unit`, `:test-functional` (tear down any stale containers first).

5. **Live acceptance re-check**: replay the same `interview/010-createPatientAndInvestigation` setup that originally proved `nrt_patient.street_address_1`/`street_address_2 = ''` (fresh UIDs to avoid collision, or truncate/redo), rebuild+restart `reporting-pipeline-service` with the fix, and confirm those columns now come back `NULL`. This directly closes the loop on the originally-reported bug.

6. **Optional/discretionary, not required for this refactor**: add a `testData/functional/patientDirectWrite/` scenario (parallel to the existing `providerDirectWrite`/`authUserDirectWrite`) seeding a patient with blank `street_address_1`/`street_address_2` and asserting `nrt_patient` shows `null` — gives durable automated regression coverage instead of relying on the one-off manual check in step 5.
