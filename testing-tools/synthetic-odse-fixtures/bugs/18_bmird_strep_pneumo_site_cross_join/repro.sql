-- Bug #18 repro / diagnostic: routine 140 cross-joins the BMIRD site datasets.
--
-- Precondition: a Strep pneumo investigation whose NON_STERILE_SITE (BMD125),
-- STREP_PNEUMO_1_CULTURE_SITES (BMD142) and STREP_PNEUMO_2_CULTURE_SITES (BMD144)
-- each carry >1 distinct value. fixtures/30_sp_coverage/zz_bmird_fill.sql authors
-- exactly this for PHC 22005000 (one observation per question with N distinct
-- obs_value_coded rows). Run the reload, then:

-- 1) BMIRD_MULTI_VALUE_FIELD holds the CORRECT distinct values, one per row:
SELECT m.NON_STERILE_SITE, m.STREP_PNEUMO_1_CULTURE_SITES, m.STREP_PNEUMO_2_CULTURE_SITES
FROM RDB_MODERN.dbo.BMIRD_MULTI_VALUE_FIELD m
WHERE m.NON_STERILE_SITE IS NOT NULL
   OR m.STREP_PNEUMO_1_CULTURE_SITES IS NOT NULL
ORDER BY 1, 2, 3;
-- Expected (pre-fix and post-fix, this table is correct):
--   Amniotic fluid | Blood | Blood
--   Middle ear     | Bone  | Bone
--   Other          | Cerebral Spinal Fluid | Cerebral Spinal Fluid

-- 2) The datamart's pivoted columns. PRE-FIX (cross-join) they repeat the first
--    value across all three slots; POST-FIX they are the distinct selections.
SELECT NON_STERILE_SITE_1, NON_STERILE_SITE_2, NON_STERILE_SITE_3,
       ADD_CULTURE_1_SITE_1, ADD_CULTURE_1_SITE_2, ADD_CULTURE_1_SITE_3
FROM RDB_MODERN.dbo.bmird_strep_pneumo_datamart d
JOIN RDB_MODERN.dbo.investigation i ON i.INVESTIGATION_KEY = d.INVESTIGATION_KEY
WHERE i.CASE_UID = 22005000;
-- PRE-FIX:  Amniotic fluid | Amniotic fluid | Amniotic fluid | Blood | Blood | Blood
-- POST-FIX: Amniotic fluid | Middle ear     | Other          | Blood | Bone  | Cerebral Spinal Fluid
