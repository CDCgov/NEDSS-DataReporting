-- Regression test for APP-781.
--
-- The bug: when a Strep pneumo case had more than one value for one of the
-- additional-site questions, the datamart showed a single value repeated in every
-- slot (NON_STERILE_SITE_1/2/3 and the two ADD_CULTURE_*_SITE_1/2/3 sets) instead
-- of the distinct sites that were entered. It lived in routine 140,
-- sp_bmird_strep_pneumo_datamart_postprocessing, which combined the three site
-- lists by matching every value against every other (a Cartesian product).
--
-- This seeds one Strep pneumo investigation (PHC 22781000, condition 11723) with
-- three distinct values for each additional-site question and then runs the
-- datamart procedure. The rows go straight into the RDB_MODERN dimension tables
-- (rather than through the full ODSE -> pipeline path) so the test exercises only
-- this one procedure.
--
-- query.sql then checks that the three NON_STERILE_SITE slots hold the three
-- distinct values. Against the old routine they all come out 'Amniotic fluid', so
-- the query finds no row, the Await poll times out, and the test fails (RED);
-- with the fix the slots are distinct and the test passes (GREEN).
USE RDB_MODERN;

-- Parent rows the BMIRD_CASE row needs. RDB_DATE, LDF_GROUP and
-- BMIRD_MULTI_VALUE_FIELD_GROUP have no usable row to point at in the restored
-- RDB_MODERN, so create the specific keys this case references. Each needs only
-- its key column. D_PATIENT needs a real local id because the datamart's
-- PATIENT_LOCAL_ID is NOT NULL and the shared key=1 patient leaves it null.
INSERT INTO [dbo].[RDB_DATE] ([DATE_KEY]) VALUES (22781004);
INSERT INTO [dbo].[LDF_GROUP] ([LDF_GROUP_KEY]) VALUES (22781003);
INSERT INTO [dbo].[BMIRD_MULTI_VALUE_FIELD_GROUP] ([BMIRD_MULTI_VAL_GRP_KEY]) VALUES (22781002);
INSERT INTO [dbo].[D_PATIENT] ([PATIENT_KEY], [PATIENT_LOCAL_ID]) VALUES (22781005, N'PSN22781000GA01');

INSERT INTO [dbo].[CONDITION] ([CONDITION_KEY], [CONDITION_CD], [CONDITION_SHORT_NM])
VALUES (22781001, N'11723', N'Streptococcus pneumoniae');

-- The case must be active and a non-summary case_type, and its CASE_UID has to
-- match the @phc_uids passed to the procedure below.
INSERT INTO [dbo].[INVESTIGATION]
    ([INVESTIGATION_KEY], [CASE_UID], [CASE_OID], [INV_LOCAL_ID], [CASE_TYPE], [RECORD_STATUS_CD])
VALUES
    (22781000, 22781000, 22781000, N'CAS22781000GA01', N'I', N'ACTIVE');

-- The remaining BMIRD_CASE keys (investigator/physician/reporter, organizations)
-- point at the existing shared key=1 rows.
INSERT INTO [dbo].[BMIRD_CASE]
    ([INVESTIGATION_KEY], [CONDITION_KEY], [BMIRD_MULTI_VAL_GRP_KEY], [ANTIMICROBIAL_GRP_KEY],
     [PATIENT_KEY], [INVESTIGATOR_KEY], [PHYSICIAN_KEY], [REPORTER_KEY], [NURSING_HOME_KEY],
     [DAYCARE_FACILITY_KEY], [INV_ASSIGNED_DT_KEY], [ADT_HSPTL_KEY], [RPT_SRC_ORG_KEY], [LDF_GROUP_KEY])
VALUES
    (22781000, 22781001, 22781002, 1, 22781005, 1, 1, 1, 1, 1, 22781004, 1, 1, 22781003);

-- Three distinct answers for each of the three additional-site questions, one
-- answer per row. This is the multi-value shape that triggers the bug; with a
-- single answer per question it never showed up.
INSERT INTO [dbo].[BMIRD_MULTI_VALUE_FIELD]
    ([BMIRD_MULTI_VAL_FIELD_KEY], [BMIRD_MULTI_VAL_GRP_KEY],
     [NON_STERILE_SITE], [STREP_PNEUMO_1_CULTURE_SITES], [STREP_PNEUMO_2_CULTURE_SITES])
VALUES
    (22781010, 22781002, N'Amniotic fluid', NULL, NULL),
    (22781011, 22781002, N'Middle ear',     NULL, NULL),
    (22781012, 22781002, N'Other',          NULL, NULL),
    (22781013, 22781002, NULL, N'Blood',                 NULL),
    (22781014, 22781002, NULL, N'Bone',                  NULL),
    (22781015, 22781002, NULL, N'Cerebral Spinal Fluid', NULL),
    (22781016, 22781002, NULL, NULL, N'Joint Fluid'),
    (22781017, 22781002, NULL, NULL, N'Lung'),
    (22781018, 22781002, NULL, NULL, N'Sinus');

EXEC dbo.sp_bmird_strep_pneumo_datamart_postprocessing @phc_uids = N'22781000', @debug = 0;
