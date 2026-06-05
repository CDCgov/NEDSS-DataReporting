**Title:** (merged on main — PR #826)

## Status
**Merged.** The fix landed on `main` as [PR #826](https://github.com/CDCgov/NEDSS-DataReporting/pull/826) (commit `92a56d42`). The accompanying unit test landed at `reporting-pipeline-service/src/test/resources/testData/unit/bug4_provider_update_typo/`.

## Description
`sp_nrt_provider_postprocessing` at line 564 referenced `#PATIENT_UPDATE_LIST`, but the only temp table in scope at that point is `#PROVIDER_UPDATE_LIST`. The UPDATE-with-diff path therefore failed with Msg 208 "Invalid object name '#PATIENT_UPDATE_LIST'" whenever an existing provider had a diff against an incoming `nrt_provider` row.

This PR fixes the single-character typo. Latent on a baseline DB (the UPDATE-with-diff path only fires when an existing `D_PROVIDER` row gets a diff), but trips deterministically on the first such case.

Verified locally: re-applying the routine and re-running the repro causes the SP to complete the diff-update path cleanly (pre-fix it raised Msg 208; post-fix `job_flow_log` shows no error rows).

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
A `testData/unit` fixture is included that seeds an existing `D_PROVIDER` row and an `nrt_provider` row with field-level differences, then asserts `D_PROVIDER` is updated to reflect the new values. Note: `nrt_provider` is a system-versioned temporal table; the fixture excludes the `GENERATED ALWAYS` columns from its INSERT lists.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
