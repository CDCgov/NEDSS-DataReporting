# Bug #18 — ProcessObservationDataUtil swallows an NPE building the Followup Observations JSON (cosmetic, but log-noisy)

**Symptom:** repeated `ERROR ProcessObservationDataUtil : Error processing Followup Observations JSON array from observation data: null`.

**Root cause:** `transformFollowupObservations` (~lines 299-334) calls `assertDomainCdMatches(obsDomainCdSt1, ORDER)` → `assertDomainCdMatches` (~line 573) does `Arrays.stream(vals).noneMatch(value::equals)`. When `value` (the outer observation's `obs_domain_cd_st_1`) is NULL, the bound method reference `value::equals` throws an NPE with a null message. It is caught by `catch (Exception e)` at ~line 329, logged, and the method returns normally (no re-throw).

**Trigger data:** supplemental-investigation "form" observations with NULL `obs_domain_cd_st_1` but a non-empty followup array — e.g. obs 22043001 (INV_FORM_HepatitisInvestigation, 139 followup sources) and 22048001 (INV_FORM_BMDSP, 42 sources). The followup loop runs and NPEs.

**Impact:** COSMETIC — the observation is still published to nrt_observation; this does NOT cause the fail-fast (that's Bug #17). But it spams ERROR logs and was a red herring during diagnosis.

**Fix (upstream):** null-safe comparison — use `Objects.equals(v, value)` instead of `value::equals` in `assertDomainCdMatches` (and/or guard null `obsDomainCdSt1` before the followup loop).
