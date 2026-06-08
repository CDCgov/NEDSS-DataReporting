# Bug #18: ProcessObservationDataUtil swallows an NPE building the Followup Observations JSON (cosmetic, but log-noisy)

**Symptom:** repeated `ERROR ProcessObservationDataUtil : Error processing Followup Observations JSON array from observation data: null`.

**Root cause:** `transformFollowupObservations` (~lines 299-334) calls `assertDomainCdMatches(obsDomainCdSt1, ORDER)`, which (~line 573) does `Arrays.stream(vals).noneMatch(value::equals)`. When `value` (the outer observation's `obs_domain_cd_st_1`) is NULL, the bound method reference `value::equals` throws an NPE with a null message. It is caught by `catch (Exception e)` at ~line 329, logged, and the method returns normally (no re-throw).

**Trigger data:** supplemental-investigation "form" observations with NULL `obs_domain_cd_st_1` but a non-empty followup array, e.g. obs 22043001 (INV_FORM_HepatitisInvestigation, 139 followup sources) and 22048001 (INV_FORM_BMDSP, 42 sources). The followup loop runs and NPEs.

**Impact:** COSMETIC. The observation is still published to nrt_observation; this does NOT cause the fail-fast (that's Bug #17). But it spams ERROR logs and was a red herring during diagnosis.

**Fix (upstream):** null-safe comparison, using `Objects.equals(v, value)` instead of `value::equals` in `assertDomainCdMatches` (and/or guard null `obsDomainCdSt1` before the followup loop).

## FIXED (2026-06-04, branch aw/fix-bug18-followup-obs-npe), TDD, cosmetic
Fix: `assertDomainCdMatches` now uses null-safe `Objects.equals(value, v)` instead of the bound
`value::equals`, so a NULL `obs_domain_cd_st_1` takes the clean IllegalArgumentException path (caught +
skipped upstream, INFO level) instead of throwing an NPE (ERROR level). Made the method package-private
for direct unit testing. TDD: ProcessObservationDataUtilTest.nullDomain_isRejectedAsIllegalArgument_notNpe
(RED = NPE before, GREEN = IllegalArgumentException after); + non-matching/matching cases.

SCOPE: COSMETIC, NO COVERAGE CHANGE (confirmed by reading the path). The followup-observation skip for
non-'Order' parents is BY DESIGN (line 310 guards "only Order parents get followups"); the NPE only made
that intended skip ugly/noisy. The observation is still published to nrt_observation either way, and
followup_observation_uid stays NULL for non-'Order' parents (correct). So this removes the ERROR-log red
herring; it does NOT recover coverage.

SEPARATE (not this bug): whether the 'Order'-only followup guard is too restrictive for supplemental
INV_FORM_* observations (which carry large followup arrays that are skipped) is a design question, not a
null-safety fix. And the actual coverage starvation observed earlier is from PROPAGATING SP-error
poisons (sp_dyn_dm STD 50000/206, sp_nrt_notification 2627, sp_aggregate_report 207) co-batching with
innocent entities under the intentional fail-fast. Those (mostly bad-synthetic-data / robustness) are
the real coverage levers to investigate next.
