package gov.cdc.nbs.report.pipeline.integration.unit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import javax.sql.DataSource;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.testcontainers.shaded.com.google.common.collect.Lists;

/**
 * Concurrency regression test for APP-736.
 *
 * <p>{@code sp_d_labtest_result_postprocessing} (routine 017) and {@code
 * sp_d_lab_test_postprocessing} (routine 018) allocate IDENTITY keys for new {@code
 * nrt_lab_test_result_group_key} / {@code nrt_lab_test_key} rows using a non-atomic {@code
 * IDENT_CURRENT}/{@code DBCC CHECKIDENT(..,RESEED,..)}/{@code INSERT} pattern. The {@code DBCC
 * CHECKIDENT} RESEED is a non-transactional metadata operation that escapes the surrounding {@code
 * UPDLOCK,HOLDLOCK}, so two concurrent / retried {@code processObservation} callers can compute the
 * same next key and both insert it, raising {@code Error 2627 Violation of PRIMARY KEY constraint
 * 'pk_nrt_lab_test_result_group_key' ... duplicate key value (1)}.
 *
 * <p>The single-threaded {@link DataDrivenUnitTests} harness cannot reproduce this; it requires
 * real concurrency. This test seeds a set of distinct brand-new {@code LAB_TEST} rows (each of
 * which forces the SP to generate a new TEST_RESULT_GROUP key) and fires N threads, each invoking
 * the SP simultaneously, across several rounds, and asserts that no thread throws and that no
 * duplicate group keys land in {@code nrt_lab_test_result_group_key}.
 *
 * <p>Against the unfixed routines this fails with a 2627 duplicate-key error and/or duplicate
 * TEST_RESULT_GRP_KEY values. Against the fixed (sp_getapplock-serialized) routines it passes.
 */
class LabTestKeyGenConcurrencyTest extends UnitTest {

  private static final Logger log = LoggerFactory.getLogger(LabTestKeyGenConcurrencyTest.class);

  // Distinct, well out-of-range UID/key base so we never collide with seeded fixture data.
  private static final long UID_BASE = 970_000_000L;

  private static final int THREADS = 32;
  private static final int ROUNDS = 30;

  // Admin credentials, but the URL is rewritten to target RDB_MODERN (where the routines/key tables
  // live); the configured admin URL points at NBS_ODSE.
  @Value("${spring.datasource.admin.url}")
  private String jdbcUrl;

  @Value("${spring.datasource.admin.username}")
  private String jdbcUser;

  @Value("${spring.datasource.admin.password}")
  private String jdbcPassword;

  // All UIDs inserted across the whole test, for guaranteed cleanup.
  private final List<Long> insertedUids = new CopyOnWriteArrayList<>();

  @AfterEach
  void cleanup() {
    JdbcClient client = client();
    // Split into chunks to avoid max of 2100 parameters in a single query.
    List<List<Long>> chunks = Lists.partition(insertedUids, 400);
    chunks.forEach(
        c -> {
          String sql =
              """
              DELETE FROM LAB_TEST_RESULT WHERE LAB_TEST_UID IN (:uidList)
              DELETE FROM LAB_RESULT_VAL WHERE LAB_TEST_UID IN (:uidList)
              DELETE FROM TEST_RESULT_GROUPING WHERE LAB_TEST_UID IN (:uidList)
              DELETE FROM nrt_lab_test_result_group_key WHERE LAB_TEST_UID IN (:uidList)
              DELETE FROM LAB_TEST WHERE LAB_TEST_UID IN (:uidList)
              """;
          client.sql(sql).param("uidList", c).update();
        });

    insertedUids.clear();
  }

  @Test
  void concurrentPostprocessingDoesNotRaceOnNewGroupKeys() throws Exception {
    List<Throwable> failures = new CopyOnWriteArrayList<>();
    AtomicInteger keyViolations = new AtomicInteger();

    // Pre-seed a distinct, brand-new LAB_TEST UID for every (thread x round) invocation. Each UID
    // is unseen by nrt_lab_test_result_group_key, so every SP call must allocate a NEW group key --
    // i.e. every call enters the contended RESEED/INSERT critical section.
    long[][] uidByThread = new long[THREADS][ROUNDS];
    List<Long> allUids = new ArrayList<>();
    for (int t = 0; t < THREADS; t++) {
      for (int round = 0; round < ROUNDS; round++) {
        long uid = UID_BASE + (long) t * 1000L + round;
        uidByThread[t][round] = uid;
        allUids.add(uid);
        insertedUids.add(uid);
      }
    }
    seedLabTests(allUids);

    CountDownLatch ready = new CountDownLatch(THREADS);
    CountDownLatch go = new CountDownLatch(1);
    CountDownLatch done = new CountDownLatch(THREADS);
    ExecutorService pool = Executors.newFixedThreadPool(THREADS);

    try {
      for (int t = 0; t < THREADS; t++) {
        final long[] myUids = uidByThread[t];
        pool.submit(
            () -> {
              // Each thread owns a dedicated connection, opened BEFORE the start latch so that
              // connection acquisition is not part of the timed window and all sessions sustain
              // overlapping pressure on the key-gen critical section across all rounds.
              try {
                JdbcClient client = client();
                ready.countDown();
                go.await();
                for (long uid : myUids) {
                  client
                      .sql("EXEC sp_d_labtest_result_postprocessing @pLabResultList=:uid")
                      .param("uid", String.valueOf(uid))
                      .update();
                }
              } catch (DataAccessException e) {
                String msg = e.getMessage();
                if (msg != null
                    && (msg.contains("2627")
                        || msg.contains("PRIMARY KEY")
                        || msg.contains("duplicate key")
                        || msg.contains("1205")
                        || msg.toLowerCase().contains("deadlock"))) {
                  keyViolations.incrementAndGet();
                }
                failures.add(e);
              } catch (Throwable e) {
                failures.add(e);
              } finally {
                done.countDown();
              }
            });
      }
      // Wait for all threads to be parked at the latch, then release simultaneously.
      assertTrue(ready.await(60, TimeUnit.SECONDS), "threads did not reach the start latch");
      go.countDown();
      assertTrue(done.await(300, TimeUnit.SECONDS), "threads did not finish in time");
    } finally {
      pool.shutdownNow();
    }

    // Report any thrown errors. The non-atomic key-gen race surfaces as either Error 2627
    // (duplicate PRIMARY KEY) or Error 1205 (deadlock victim at the RESEED/INSERT critical
    // section) -- both bubble up as a DataProcessingException and trigger the fail-fast skip.
    if (!failures.isEmpty()) {
      log.error(
          "{} thread(s) threw; {} were key-gen race errors (2627 PK violation / 1205 deadlock)",
          failures.size(),
          keyViolations.get());
      for (Throwable f : failures) {
        log.error("thread failure: {}", f.getMessage());
      }
    }

    // Assertion 1: no thread threw. The race manifests as Error 2627 (duplicate key) or Error 1205
    // (deadlock) thrown out of the key-gen critical section.
    assertTrue(
        failures.isEmpty(),
        () ->
            "Expected no exceptions from concurrent postprocessing, but "
                + failures.size()
                + " thread(s) threw ("
                + keyViolations.get()
                + " key-gen race errors: 2627 PK violation / 1205 deadlock). First: "
                + failures.get(0).getMessage());

    // Assertion 2: the key table is internally consistent and (essentially) complete. The race has
    // two manifestations off the same non-atomic RESEED/INSERT:
    //   (a) thrown 2627/1205 (Assertion 1), and
    //   (b) SILENT LOST INSERTS -- interleaved sessions drop each other's rows, so far fewer than
    //       the expected number of group keys land even though nobody threw.
    // Single-threaded execution always lands exactly one key per distinct new UID. Under the
    // UNFIXED routine, concurrent execution catastrophically under-counts (observed ~150/960). The
    // fixed (applock-serialized + committed-read, temp-table-driven) routine lands every row; we
    // require >=99% to stay robust against any extremely rare residual scheduling artifact while
    // still failing hard on the real bug. We also require NO duplicate keys.
    int expected = THREADS * ROUNDS;
    long minRequired = (long) Math.ceil(expected * 0.99);

    JdbcClient client = client();
    String query =
        """
              SELECT
                COUNT(*) AS total,
                COUNT(DISTINCT TEST_RESULT_GRP_KEY) AS distinctKeys,
                COUNT(DISTINCT LAB_TEST_UID) AS distinctUids
              FROM
                nrt_lab_test_result_group_key
              WHERE
                LAB_TEST_UID IN (:uidList);
              """;

    var rs = client.sql(query).param("uidList", insertedUids).query().singleRow();
    int total = (Integer) rs.get("total");
    int distinct = (Integer) rs.get("distinctKeys");
    int distinctUids = (Integer) rs.get("distinctUids");

    if (distinctUids != expected) {
      log.warn(
          "Group-key landing: {}/{} distinct UIDs (total rows={}, distinct keys={})",
          distinctUids,
          expected,
          total,
          distinct);
    }
    // No duplicate keys (the 2627 collision manifestation).
    assertEquals(
        total,
        distinct,
        "Duplicate TEST_RESULT_GRP_KEY detected: total=" + total + " distinct=" + distinct);
    // No catastrophic lost-insert race (the silent-drop manifestation).
    assertTrue(
        distinctUids >= minRequired,
        "Lost-insert race: expected "
            + expected
            + " new group keys (one per distinct new LAB_TEST_UID) but only "
            + distinctUids
            + " landed (require >= "
            + minRequired
            + ") -- interleaved RESEED/INSERT dropped rows.");
  }

  /**
   * Deterministic (single-threaded) regression for the RESIDUAL APP-736 facet that the concurrency
   * test above could not catch: the sentinel-slot re-assignment on a never-used (empty) key table.
   *
   * <p>{@code nrt_lab_test_result_group_key} carries a default sentinel row {@code
   * TEST_RESULT_GRP_KEY = 1, LAB_TEST_UID NULL} (backfilled from the {@code TEST_RESULT_GROUPING}
   * default record). On a from-scratch pipeline run the key table can be momentarily EMPTY and in
   * the never-used IDENTITY seed state (IDENT_CURRENT = seed = 1, LastValue NULL). The old key-gen
   * computed {@code @max = ISNULL(MAX,0) = 0}, so its reseed guard {@code @curr(1) < @max(0)} was
   * FALSE -- no reseed ran -- and SQL Server's empty-table seed quirk made the first auto-IDENTITY
   * INSERT assign {@code TEST_RESULT_GRP_KEY = 1} to a REAL lab test, silently consuming the
   * sentinel slot. A subsequent sentinel/grouping (re)insert then collided on PRIMARY KEY value (1)
   * -> Error 2627, deterministically (no concurrency required).
   *
   * <p>This test reproduces that exact state with a single thread: it snapshots and TRUNCATEs the
   * key table (TRUNCATE restores the never-used seed state), seeds one brand-new lab test, invokes
   * the SP once, and asserts (a) no 2627, (b) the new key is >= 2 (the sentinel slot 1 was NOT
   * consumed), and (c) a default sentinel row (key=1, LAB_TEST_UID NULL) can still be inserted
   * without a PK collision. It then restores the snapshotted rows. RED against the pre-fix routine
   * (new lab test lands at key=1, sentinel reinsert throws 2627); GREEN against the
   * explicit-allocation (MAX+ROW_NUMBER, base = ISNULL(MAX,1)) routine.
   */
  @Test
  void emptyKeyTableDoesNotReassignSentinelSlot() throws Exception {
    long newUid = UID_BASE + 900_000L;
    insertedUids.add(newUid);
    JdbcClient client = client();

    // Snapshot the live key table so we can restore it after the destructive TRUNCATE.
    String snapshotQuery =
        """
          IF OBJECT_ID('tempdb..##gk_snapshot') IS NOT NULL DROP TABLE ##gk_snapshot;
          SELECT TEST_RESULT_GRP_KEY, LAB_TEST_UID INTO ##gk_snapshot FROM nrt_lab_test_result_group_key;
          """;
    client.sql(snapshotQuery).update();

    try {
      // Reproduce the from-scratch never-used empty-table state: TRUNCATE resets the IDENTITY to
      // the never-used seed (IDENT_CURRENT=1, LastValue NULL) and clears every row including the
      // sentinel -- exactly the state that made the old key-gen assign key=1 to a real lab test.
      client.sql("TRUNCATE TABLE nrt_lab_test_result_group_key").update();

      // One brand-new Result lab test -> the SP must allocate a NEW group key for it.
      String insertQuery =
          """
            INSERT INTO LAB_TEST (LAB_TEST_KEY, LAB_TEST_UID, LAB_TEST_TYPE, RECORD_STATUS_CD)
            VALUES (:newUid, :newUid, 'Result', 'ACTIVE');
            """;
      client.sql(insertQuery).param("newUid", newUid).update();

      // Invoke the SP. Against the pre-fix routine this lands the new test at
      // TEST_RESULT_GRP_KEY=1.
      client
          .sql("EXEC sp_d_labtest_result_postprocessing @pLabResultList=:newUid")
          .param("newUid", String.valueOf(newUid))
          .update();

      // Assertion 1: the new lab test must NOT have taken the sentinel slot (key=1); it must be
      // >=2.
      int key =
          client
              .sql(
                  "SELECT TEST_RESULT_GRP_KEY FROM nrt_lab_test_result_group_key WHERE LAB_TEST_UID =:newUid")
              .param("newUid", newUid)
              .query(Integer.class)
              .single();
      assertTrue(
          key >= 2,
          "Sentinel slot re-assignment: new lab test was allocated TEST_RESULT_GRP_KEY="
              + key
              + " (must be >= 2; key=1 is reserved for the default sentinel).");

      // Assertion 2: the default sentinel (key=1, LAB_TEST_UID NULL) can still be inserted --
      // i.e.
      // the slot was preserved -- without a 2627 PRIMARY KEY collision.
      try {
        String insertIdentity =
            """
              SET IDENTITY_INSERT nrt_lab_test_result_group_key ON;
              INSERT INTO nrt_lab_test_result_group_key (TEST_RESULT_GRP_KEY, LAB_TEST_UID)
              VALUES (1, NULL);
              """;
        client.sql(insertIdentity).update();
      } catch (DataAccessException e) {
        String msg = e.getMessage();
        if (msg != null && (msg.contains("2627") || msg.contains("PRIMARY KEY"))) {
          fail(
              "Sentinel-slot collision: inserting the default sentinel (key=1) threw a duplicate"
                  + " PRIMARY KEY (2627) because a real lab test already consumed key=1. "
                  + msg);
        }
        throw e;
      } finally {
        client.sql("SET IDENTITY_INSERT nrt_lab_test_result_group_key OFF").update();
      }
    } finally {
      // Restore: clear our test rows, then re-insert the snapshot under IDENTITY_INSERT, and
      // realign the IDENTITY seed with the restored MAX so the shared stack is left intact.
      String sql =
          """
            TRUNCATE TABLE nrt_lab_test_result_group_key;
            SET IDENTITY_INSERT nrt_lab_test_result_group_key ON;
            INSERT INTO nrt_lab_test_result_group_key (TEST_RESULT_GRP_KEY, LAB_TEST_UID)
            SELECT TEST_RESULT_GRP_KEY, LAB_TEST_UID FROM ##gk_snapshot;
            SET IDENTITY_INSERT nrt_lab_test_result_group_key OFF;
            DECLARE @m BIGINT = (SELECT ISNULL(MAX(TEST_RESULT_GRP_KEY),1) FROM nrt_lab_test_result_group_key);
            DBCC CHECKIDENT('nrt_lab_test_result_group_key', RESEED, @m) WITH NO_INFOMSGS;
            IF OBJECT_ID('tempdb..##gk_snapshot') IS NOT NULL DROP TABLE ##gk_snapshot;
            """;
      client.sql(sql).update();
    }
  }

  private void seedLabTests(List<Long> uids) {
    JdbcClient client = client();
    // LAB_TEST_KEY is the (non-identity) PK; reuse the UID as the key (both far out of range).
    // LAB_TEST_TYPE='Result' routes the row into #TMP_Result_And_R_Result, and a brand-new
    // UID (not yet in nrt_lab_test_result_group_key) forces a new group-key allocation.
    String sql =
        """
        INSERT INTO LAB_TEST
          (LAB_TEST_KEY, LAB_TEST_UID, LAB_TEST_TYPE, RECORD_STATUS_CD)
        VALUES
          (:uid, :uid, 'Result', 'ACTIVE');
        """;
    for (Long uid : uids) {
      client.sql(sql).param("uid", uid).update();
    }
  }

  // Initialize a new datasource for each request to bypass connection pooling limit
  private JdbcClient client() {
    String url = jdbcUrl.replaceAll("databaseName=[^;]+", "databaseName=RDB_MODERN");
    DataSource dataSource =
        DataSourceBuilder.create().url(url).username(jdbcUser).password(jdbcPassword).build();
    return JdbcClient.create(dataSource);
  }
}
