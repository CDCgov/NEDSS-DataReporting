**Title:** Fix sp_nrt_ldf_dimensional_data_postprocessing: stop early-RETURN guard from misclassifying filtered ldf_uids, harmonize INNER→LEFT JOIN

## Description
`sp_nrt_ldf_dimensional_data_postprocessing` never populated `LDF_DIMENSIONAL_DATA` for fixtures with valid LDF answers. Two independent defects, both fixed in this PR:

**1. Early-RETURN guard misclassification (lines 136-158).** The `@backfill_list` computation was driven against `#LDF_META_DATA`, which had already been filtered by a `data_type IN ('ST','CV','LIST_ST')` whitelist. Any `ldf_uid` with a data_type outside the whitelist (e.g. `SUB`) would therefore appear "missing" from the metadata set, trip the guard, and abort the entire batch. The guard now checks `nrt_odse_state_defined_field_metadata` directly so it only fires for genuinely missing source rows.

**2. INNER vs LEFT JOIN inconsistency (line 648).** The `#LDF_DATA` step used `INNER JOIN nrt_srte_LDF_PAGE_SET`, but the corresponding metadata step at line 108 used `LEFT JOIN`. Since `nrt_ldf_data.ldf_page_id` can legitimately be NULL, the INNER JOIN silently dropped those rows. Harmonized to LEFT JOIN so both steps treat the relationship symmetrically.

Verified locally: pre-fix, the SP stopped after step 2 logging "Missing NRT Record" and `LDF_DIMENSIONAL_DATA` stayed at 0. Post-fix, the SP progresses through all 27 steps to `SP_COMPLETE`, step 25 INSERTs 5 rows, and `SELECT COUNT(*) FROM LDF_DIMENSIONAL_DATA` returns 5.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
A `testData/unit` fixture is included. It uses an isolated `97xxxxxx` UID namespace (PHC=97000200, ldf_uids 97001977 SUB + 97001978 CV + 97001979 ST) so it doesn't collide with fixture or baseline rows, and asserts the SP writes the two non-SUB rows to `LDF_DIMENSIONAL_DATA` while the SUB row is filtered through cleanly (no longer tripping the early-RETURN guard).

This fix unblocks the per-condition LDF tables (LDF_TETANUS, LDF_HEPATITIS, etc.) for downstream datamart SPs to populate. The unguarded `SUBSTRING` defect that fires when those per-condition tables are empty is addressed separately in bug #8.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
