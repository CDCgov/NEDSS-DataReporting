**Title:** Fix sp_nrt_ldf_dimensional_data_postprocessing: stop early-RETURN guard from misclassifying filtered ldf_uids, harmonize INNER to LEFT JOIN

## Description
`sp_nrt_ldf_dimensional_data_postprocessing` never populated `LDF_DIMENSIONAL_DATA` for fixtures with valid LDF answers. Two independent defects, both fixed here:

1. **Early-RETURN guard misclassification (lines 136-158).** `@backfill_list` was computed against `#LDF_META_DATA`, which had already been filtered by a `data_type IN ('ST','CV','LIST_ST')` whitelist. Any `ldf_uid` with a data_type outside the whitelist (e.g. `SUB`) showed up as "missing" from the metadata set, tripped the guard, and aborted the batch. Guard now reads `nrt_odse_state_defined_field_metadata` directly so it only fires for genuinely missing source rows.

2. **INNER vs LEFT JOIN inconsistency (line 648).** The `#LDF_DATA` step joined `nrt_srte_LDF_PAGE_SET` with `INNER JOIN`, but the metadata step at line 108 uses `LEFT JOIN` on the same relationship. Since `nrt_ldf_data.ldf_page_id` can legitimately be NULL, the INNER side was silently dropping rows. Harmonized to LEFT JOIN.

Verified locally: pre-fix the SP exited at step 2 logging "Missing NRT Record" with `LDF_DIMENSIONAL_DATA` at 0; post-fix it runs to `SP_COMPLETE`, step 25 inserts 5 rows, and the table has 5 rows.

## Related Issue
[APP-471](https://cdc-nbs.atlassian.net/browse/APP-471)

## Additional Notes
A `testData/unit` fixture is included (isolated `97xxxxxx` UID namespace) that seeds three ldf_uids (a SUB, a CV, and an ST) and asserts the two non-SUB rows land in `LDF_DIMENSIONAL_DATA` while SUB is filtered cleanly through the corrected guard.

Unblocks the per-condition LDF tables (LDF_TETANUS, LDF_HEPATITIS, etc.) for downstream datamart SPs. The unguarded SUBSTRING that fires when those tables are still empty is handled separately in bug #8.

## Checklist
- [ ] I have ensured that the pull request is of a manageable size, allowing it to be reviewed within a single session.
- [ ] I have reviewed my changes to ensure they are clear, concise, and well-documented.
- [ ] I have updated the documentation, if applicable.
- [ ] I have added or updated test cases to cover my changes, if applicable.
