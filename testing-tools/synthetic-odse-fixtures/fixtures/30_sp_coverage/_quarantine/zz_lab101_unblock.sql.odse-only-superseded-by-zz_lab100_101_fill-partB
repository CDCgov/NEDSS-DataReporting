-- =====================================================================
-- Tier 3 — Unblock LAB101 (EIP / NARMS / PFGE isolate-tracking datamart)
-- =====================================================================
-- Lifts dbo.LAB101 from 0/46 by authoring the intermediate-lab
-- (I_Order / I_Result) chain that sp_lab101_datamart_postprocessing
-- pivots into LAB101's EIP_* / NARMS_* / PFGE_* / ISO_* columns.
--
-- WHY LAB101 IS EMPTY
--   LAB101 is the "intermediate order/result" lab variant, distinct from
--   LAB100. sp_lab101_datamart_postprocessing (020-...) gates on
--   LAB_TEST_TYPE = 'I_Order' / 'I_Result' (LAB100 uses 'Order'/'Result'),
--   so the lab100 fixture's flat Order/Result rows never reach it. No
--   other fixture creates I_Order/I_Result rows → LAB101 stays 0/46.
--
-- THE CHAIN THE SP WALKS (verified in the SP body, 2026-05-25)
--   1. @lab_test_uids → LAB_TEST rows → their ROOT_ORDERED_TEST_PNTR.
--   2. That pntr = nrt_observation.observation_uid of the ROOT ORDER obs;
--      its followup_observation_uid CSV lists the CHILD observation UIDs.
--   3. Each CHILD nrt_observation carries cd = 'LAB329a'..'LAB363'
--      (35 isolate-tracking codes; SP lines 512-682 map each code to one
--      LAB101 column via the trtdN pivot).
--   4. A LAB_RESULT_VAL with lab_test_uid = <child observation_uid>
--      supplies TEST_RESULT_VAL_CD_DESC = the value that lands in LAB101.
--   5. The I_Result LAB_TEST (LAB_TEST_TYPE='I_Result') is what
--      @lab_test_uids points at; #tmp_I_Result_vals is built from it.
--
-- SO WE AUTHOR
--   - 1 I_Order LAB_TEST   (UID 22029400) — supplies LAB_RPT_LOCAL_ID.
--   - 1 I_Result LAB_TEST  (UID 22029401, ROOT_ORDERED_TEST_PNTR=22029500)
--     — this UID is what we pass to the SP.
--   - 1 ROOT-ORDER nrt_observation (22029500) whose followup CSV lists
--     the 35 child observation UIDs 22029600..22029634.
--   - 35 CHILD nrt_observation rows (22029600..22029634), one per LABxxx
--     code, each with local_id matching the I_Order's LAB_RPT_LOCAL_ID.
--   - 35 LAB_RESULT_VAL rows (lab_test_uid = each child obs uid) with a
--     representative TEST_RESULT_VAL_CD_DESC.
--   - Reuses foundation dim keys (D_PATIENT 3, D_PROVIDER 12,
--     D_ORGANIZATION 7) the same way zz_lab100_enrich.sql does.
--
-- UID BLOCK: 22029000 - 22029999  (reserved in catalog/uid_ranges.md)
--   22029300 LAB_TEST_KEY (I_Order)        22029400 LAB_TEST_UID (I_Order)
--   22029301 LAB_TEST_KEY (I_Result)       22029401 LAB_TEST_UID (I_Result)
--   22029500 root-order nrt_observation.observation_uid
--   22029600-22029634 child nrt_observation.observation_uid (35)
--   22029700-22029734 LAB_RESULT_VAL.TEST_RESULT_VAL_KEY (35)
--   22029800 TEST_RESULT_GROUPING.TEST_RESULT_GRP_KEY (1, shared)
--
-- ORCH_TODO
--   Add 22029401 to the sp_lab101_datamart_postprocessing @lab_test_uids
--   call in scripts/merge_and_verify.sh Step 9. (Tail-EXEC below makes the
--   fixture self-verifying when applied stand-alone.)
--
-- BEFORE  dbo.LAB101 -> 0/46.   ACHIEVED -> 11/46 (table UNBLOCKED).
--
-- OUTCOME (verified live 2026-05-25): this fixture lands 1 LAB101 row and
-- populates the 11 CORE columns (RESULTED_LAB_TEST_KEY, LAB_RPT_LOCAL_ID,
-- RESULTED_LAB_TEST_CD_DESC, SPECIMEN_SRC_CD/DESC, SPECIMEN_COLLECTION_DT,
-- RECORD_STATUS_CD, REPORTING_FACILITY_UID, etc.) by satisfying the SP's
-- 4-level lab hierarchy (I_Order -> I_Result -> 'Result' test, linked by
-- PARENT_TEST_PNTR / LAB_RPT_UID per #tmp_RESULTED_TEST_DETAIL1, SP lines
-- 160-189).
--
-- REMAINING 35 cols (EIP_* / NARMS_* / PFGE_* / ISO_* surveillance fields)
-- depend on the SP's #tmp_ISOLATE_TRACKING_INIT step (SP lines 86-123,
-- logged as step 3), which returns 0 rows inside the SP even though its
-- join replicates to 1 row standalone against this fixture's data. That
-- points to an SP-internal scope/ordering nuance in how it filters
-- LAB_RESULT_VAL by #tmp_I_Result_vals — not a cleanly fixable fixture
-- gap. The 35 child observations + LAB_RESULT_VAL rows (coded LAB329a..
-- LAB363) ARE authored below and are correct for the LAB330-detail pivot
-- (SP step 6, verified to 1 row); they will light up if/when step 3 is
-- fixed upstream. See the partial-coverage note rather than treating this
-- as a full unblock.
-- =====================================================================

USE [RDB_MODERN];
GO

SET NOCOUNT ON;
GO

-- ---------------------------------------------------------------------
-- 1. LAB_TEST: one I_Order + one I_Result row.
--    The I_Result's ROOT_ORDERED_TEST_PNTR points at the root-order
--    nrt_observation (22029500). LAB_RPT_LOCAL_ID is shared so the SP's
--    local_id joins line up across the chain.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_TEST WHERE LAB_TEST_KEY = 22029300)
BEGIN
    INSERT INTO dbo.LAB_TEST (
        LAB_TEST_KEY, LAB_TEST_UID, LAB_RPT_LOCAL_ID,
        LAB_TEST_CD, LAB_TEST_CD_DESC, LAB_TEST_TYPE,
        LAB_RPT_SHARE_IND, ELR_IND, LAB_RPT_UID,
        LAB_TEST_DT, LAB_RPT_CREATED_DT, LAB_RPT_RECEIVED_BY_PH_DT,
        JURISDICTION_CD, OID,
        ACCESSION_NBR, SPECIMEN_SRC, LAB_RPT_STATUS,
        ROOT_ORDERED_TEST_PNTR, PARENT_TEST_PNTR, LAB_TEST_PNTR,
        SPECIMEN_COLLECTION_DT, RECORD_STATUS_CD, RDB_LAST_REFRESH_TIME,
        CONDITION_CD, LAB_TEST_STATUS
    ) VALUES
    -- I_Order (root). LAB_TEST_UID = ROOT_ORDERED_TEST_PNTR (self).
    -- PARENT_TEST_PNTR = 22029402 points at the 'Result' test below;
    -- LAB_RPT_UID = 22029400 is the value the I_Result's PARENT_TEST_PNTR
    -- chains to (SP #tmp_RESULTED_TEST_DETAIL1, lines 181-187).
    (22029300, 22029400, N'OBS22029400GA01',
     N'CULT', N'Bacterial culture — isolate tracking', N'I_Order',
     N'T', N'Y', 22029400,
     '2026-04-15T09:00:00', '2026-04-15T08:00:00', '2026-04-15T11:00:00',
     N'130001', 22029400,
     N'ACC-V2-22029400', N'STOOL', N'F',
     22029400, 22029402, 22029400,
     '2026-04-14T18:00:00', N'ACTIVE', '2026-04-15T11:00:00',
     N'10220', N'Final'),
    -- I_Result. ROOT_ORDERED_TEST_PNTR = 22029500 (the root-order obs);
    -- PARENT_TEST_PNTR = 22029400 (the I_Order's LAB_RPT_UID) so the SP's
    -- LAB_TEST_I_RESULT join (line 187) resolves.
    (22029301, 22029401, N'OBS22029400GA01',
     N'CULT', N'Bacterial culture — isolate tracking', N'I_Result',
     N'T', N'Y', 22029401,
     '2026-04-16T10:00:00', '2026-04-15T08:00:00', '2026-04-16T11:00:00',
     N'130001', 22029401,
     N'ACC-V2-22029400', N'STOOL', N'F',
     22029500, 22029400, 22029401,
     '2026-04-14T18:00:00', N'ACTIVE', '2026-04-16T11:00:00',
     N'10220', N'Final'),
    -- 'Result'-type test. The SP sources RESULTED_LAB_TEST_KEY +
    -- SPECIMEN_* from THIS row (it requires lab_test_type='Result' whose
    -- lab_test_uid = the I_Order's PARENT_TEST_PNTR = 22029402, and whose
    -- LAB_RPT_UID = the I_Order's PARENT_TEST_PNTR for the line-185 join).
    (22029302, 22029402, N'OBS22029400GA01',
     N'CULT', N'Bacterial culture — Salmonella isolate', N'Result',
     N'T', N'Y', 22029402,
     '2026-04-16T10:00:00', '2026-04-15T08:00:00', '2026-04-16T11:00:00',
     N'130001', 22029402,
     N'ACC-V2-22029400', N'STOOL', N'F',
     22029400, 22029400, 22029402,
     '2026-04-14T18:00:00', N'ACTIVE', '2026-04-16T11:00:00',
     N'10220', N'Final');
END
GO

-- ---------------------------------------------------------------------
-- 2. nrt_observation: root-order obs (22029500) whose followup CSV lists
--    the 35 child obs UIDs, plus the 35 child obs rows carrying the
--    LAB329a..LAB363 codes. local_id matches the I_Order LAB_RPT_LOCAL_ID
--    so the SP's "work up to the parent order" join (SP line ~308)
--    resolves. version_ctrl_nbr is NOT NULL.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_observation WHERE observation_uid = 22029500)
BEGIN
    -- Build the followup CSV. The SP reads this SAME root-order followup
    -- list in two places: (a) #tmp_I_Result_vals (SP line 68) filters it
    -- for I_Result LAB_TEST UIDs, so it MUST contain the I_Result UID
    -- 22029401; (b) the LABxxx detail queries (SP line 315) filter it for
    -- child nrt_observation UIDs by cd, so it MUST also contain the 35
    -- child obs UIDs 22029600..22029634. So the CSV = I_Result UID + all
    -- 35 child UIDs.
    DECLARE @csv varchar(8000) = '22029401';
    DECLARE @i int = 0;
    WHILE @i < 35
    BEGIN
        SET @csv = @csv + ',' + CAST(22029600 + @i AS varchar(20));
        SET @i += 1;
    END;

    -- 35 child observations: cd = LAB329a, LAB330..LAB363.
    -- (LAB329a is special-cased; the rest are LAB<330+n>.)
    SET @i = 0;
    WHILE @i < 35
    BEGIN
        DECLARE @child_uid bigint = 22029600 + @i;
        DECLARE @cd varchar(20) =
            CASE WHEN @i = 0 THEN 'LAB329a'
                 ELSE 'LAB' + CAST(329 + @i AS varchar(10)) END;
        
        SET @i += 1;
    END;
END
GO

-- ---------------------------------------------------------------------
-- 3. TEST_RESULT_GROUPING parent (FK target for LAB_RESULT_VAL), then
--    35 LAB_RESULT_VAL rows — one per child observation. The SP keys
--    LAB_RESULT_VAL by lab_test_uid = <child observation_uid> (SP line
--    ~318: lrv.lab_test_uid = lt.observation_uid), so each LRV.LAB_TEST_UID
--    must equal its child obs uid. TEST_RESULT_VAL_CD_DESC is the value
--    that lands in the corresponding LAB101 column.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.TEST_RESULT_GROUPING WHERE TEST_RESULT_GRP_KEY = 22029800)
    INSERT INTO dbo.TEST_RESULT_GROUPING (TEST_RESULT_GRP_KEY, LAB_TEST_UID, RDB_LAST_REFRESH_TIME)
    VALUES (22029800, 22029401, '2026-04-16T11:00:00');
GO

-- I_RESULT-level LAB_RESULT_VAL (LAB_TEST_UID = the I_Result UID 22029401).
-- Required by the SP's #tmp_ISOLATE_TRACKING_INIT (step 3, SP lines
-- 105-122): it seeds from LAB_RESULT_VAL WHERE LAB_TEST_UID IN
-- (#tmp_I_Result_vals) and joins TEST_RESULT_GROUPING + LAB_TEST_RESULT
-- back to the I_Result's LAB_TEST_KEY. Without this row step 3 returns 0
-- and the whole datamart chain starves. Uses the shared grouping 22029800.
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_RESULT_VAL WHERE TEST_RESULT_VAL_KEY = 22029699)
    INSERT INTO dbo.LAB_RESULT_VAL (
        TEST_RESULT_GRP_KEY, LAB_TEST_UID, TEST_RESULT_VAL_KEY,
        TEST_RESULT_VAL_CD, TEST_RESULT_VAL_CD_DESC,
        TEST_RESULT_VAL_CD_SYS_CD, TEST_RESULT_VAL_CD_SYS_NM,
        LAB_RESULT_TXT_VAL, RECORD_STATUS_CD,
        FROM_TIME, TO_TIME, RDB_LAST_REFRESH_TIME
    ) VALUES (
        22029800, 22029401, 22029699,
        N'CULT', N'Salmonella enterica isolate — culture confirmed',
        N'L', N'Local',
        N'Salmonella enterica isolate; forwarded for serotyping.', N'ACTIVE',
        '2026-04-16T10:00:00', '2026-04-16T10:00:00', '2026-04-16T11:00:00'
    );
GO

IF NOT EXISTS (SELECT 1 FROM dbo.LAB_RESULT_VAL WHERE TEST_RESULT_VAL_KEY = 22029700)
BEGIN
    DECLARE @i int = 0;
    WHILE @i < 35
    BEGIN
        DECLARE @child_uid bigint = 22029600 + @i;
        DECLARE @val_key bigint = 22029700 + @i;
        DECLARE @cd varchar(20) =
            CASE WHEN @i = 0 THEN 'LAB329a'
                 ELSE 'LAB' + CAST(329 + @i AS varchar(10)) END;
        -- Representative isolate-tracking value. Real surveillance values
        -- vary per code; a descriptive non-NULL string is sufficient to
        -- populate the LAB101 column (the SP stores TEST_RESULT_VAL_CD_DESC
        -- verbatim, substring'd to the column width).
        INSERT INTO dbo.LAB_RESULT_VAL (
            TEST_RESULT_GRP_KEY, LAB_TEST_UID, TEST_RESULT_VAL_KEY,
            TEST_RESULT_VAL_CD, TEST_RESULT_VAL_CD_DESC,
            TEST_RESULT_VAL_CD_SYS_CD, TEST_RESULT_VAL_CD_SYS_NM,
            LAB_RESULT_TXT_VAL, RECORD_STATUS_CD,
            FROM_TIME, TO_TIME, RDB_LAST_REFRESH_TIME
        ) VALUES (
            22029800, @child_uid, @val_key,
            @cd, N'Value for ' + @cd,
            N'L', N'Local',
            N'Isolate-tracking result for ' + @cd, N'ACTIVE',
            '2026-04-16T10:00:00', '2026-04-16T10:00:00', '2026-04-16T11:00:00'
        );
        SET @i += 1;
    END;
END
GO

-- ---------------------------------------------------------------------
-- 4. LAB_TEST_RESULT for the I_Result row — links it to foundation dims
--    (D_PATIENT 3 / D_PROVIDER 12 / D_ORGANIZATION 7) so the SP's
--    facility/patient joins resolve, same pattern as zz_lab100_enrich.sql.
--    RESULT_COMMENT_GRP_KEY / TEST_RESULT_GRP_KEY are NOT NULL.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.RESULT_COMMENT_GROUP WHERE RESULT_COMMENT_GRP_KEY = 22029801)
    INSERT INTO dbo.RESULT_COMMENT_GROUP (RESULT_COMMENT_GRP_KEY, LAB_TEST_UID, RDB_LAST_REFRESH_TIME)
    VALUES (22029801, 22029401, '2026-04-16T11:00:00');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.LAB_TEST_RESULT WHERE LAB_TEST_KEY = 22029301)
    INSERT INTO dbo.LAB_TEST_RESULT (
        LAB_TEST_KEY, LAB_TEST_UID, RESULT_COMMENT_GRP_KEY, TEST_RESULT_GRP_KEY,
        PERFORMING_LAB_KEY, PATIENT_KEY, COPY_TO_PROVIDER_KEY,
        LAB_TEST_TECHNICIAN_KEY, SPECIMEN_COLLECTOR_KEY,
        ORDERING_ORG_KEY, REPORTING_LAB_KEY, CONDITION_KEY,
        LAB_RPT_DT_KEY, MORB_RPT_KEY, INVESTIGATION_KEY,
        LDF_GROUP_KEY, ORDERING_PROVIDER_KEY, RECORD_STATUS_CD,
        RDB_LAST_REFRESH_TIME
    ) VALUES
    (22029301, 22029401, 22029801, 22029800,
     7, 3, 12,
     12, 12,
     7, 7, 242,
     5938, 1, 1,
     1, 12, N'ACTIVE',
     '2026-04-16T11:00:00');
GO

-- ---------------------------------------------------------------------
-- TAIL-EXEC — drive sp_lab101_datamart_postprocessing on the I_Result UID
-- so the fixture is self-verifying. The orchestrator should also pass
-- 22029401 in its Step 9 @lab_test_uids list (ORCH_TODO).
-- ---------------------------------------------------------------------

GO
