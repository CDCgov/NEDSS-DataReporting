-- The three non-sterile-site slots should hold the three distinct values that were
-- entered (slot 1 'Amniotic fluid', slot 2 'Middle ear', slot 3 'Other'). The old
-- routine repeated the first value in every slot, so requiring slot 2 = 'Middle ear'
-- and slot 3 = 'Other' returns no row, the Await poll then times out and the test
-- fails (RED). With the fix the row is found and the test passes (GREEN).
SELECT
    NON_STERILE_SITE_1, NON_STERILE_SITE_2, NON_STERILE_SITE_3,
    ADD_CULTURE_1_SITE_1, ADD_CULTURE_1_SITE_2, ADD_CULTURE_1_SITE_3,
    ADD_CULTURE_2_SITE_1, ADD_CULTURE_2_SITE_2, ADD_CULTURE_2_SITE_3
FROM RDB_MODERN.dbo.BMIRD_STREP_PNEUMO_DATAMART
WHERE INVESTIGATION_KEY = 22781000
  AND NON_STERILE_SITE_2 = N'Middle ear'
  AND NON_STERILE_SITE_3 = N'Other';
