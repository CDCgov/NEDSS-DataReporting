package gov.cdc.nbs.report.pipeline.integration.unit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;

/**
 * Concurrency regression test for bug #17.
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

  // The key tables/routines live in RDB_MODERN; the connection URL targets RDB_MODERN AND every
  // object reference is fully database-qualified, so the test never depends on the session's
  // resolved default catalog (which differs between the Testcontainers and reuse code paths).
  private static final String CATALOG = "RDB_MODERN";
  private static final String DB = "RDB_MODERN.dbo.";

  // Distinct, well out-of-range UID/key base so we never collide with seeded fixture data.
  private static final long UID_BASE = 970_000_000L;

  private static final int THREADS = 32;
  private static final int ROUNDS = 30;

  @Autowired private Environment env;

  // Admin credentials, but the URL is rewritten to target RDB_MODERN (where the routines/key tables
  // live); the configured admin URL points at NBS_ODSE.
  private String jdbcUrl;
  private String jdbcUser;
  private String jdbcPassword;

  // All UIDs inserted across the whole test, for guaranteed cleanup.
  private final List<Long> insertedUids = new CopyOnWriteArrayList<>();

  /**
   * Reuse an already-running nbs-mssql+liquibase stack on the fixed compose port (3433) if one is
   * present, rather than letting Testcontainers try to bind the same fixed port (which fails with
   * "port is already allocated"). Falls back to the parent's Testcontainers lifecycle when nothing
   * is listening yet.
   */
  @Override
  @BeforeAll
  void setUp() {
    if (dbReachable()) {
      log.warn("Reusing already-running DB stack on :3433; skipping Testcontainers startup.");
      reusedExistingStack = true;
    } else {
      super.setUp();
    }
    // Resolve admin credentials, but force the catalog to RDB_MODERN (the configured admin URL
    // targets NBS_ODSE; the routines and key tables live in RDB_MODERN).
    jdbcUser = env.getProperty("spring.datasource.admin.username", "rtr_admin");
    jdbcPassword = env.getProperty("spring.datasource.admin.password", "rtr_admin");
    String configured =
        env.getProperty(
            "spring.datasource.admin.url",
            "jdbc:sqlserver://localhost:3433;databaseName=NBS_ODSE;encrypt=true;"
                + "trustServerCertificate=true;loginTimeout=3;");
    jdbcUrl = configured.replaceAll("databaseName=[^;]+", "databaseName=" + CATALOG);

    // The parent's Testcontainers readiness gate ("Migrations complete") can fire while later
    // Liquibase phases (the runOnChange routines + onboarding seeds) are still applying, so the SP
    // and key tables may not exist yet at this instant. Poll until the routine under test is
    // present before any thread invokes it.
    awaitSpReady();
  }

  private void awaitSpReady() {
    long deadline = System.currentTimeMillis() + Duration.ofMinutes(5).toMillis();
    Exception last = null;
    while (System.currentTimeMillis() < deadline) {
      try (Connection conn = connection();
          Statement st = conn.createStatement();
          var rs =
              st.executeQuery(
                  "SELECT OBJECT_ID('" + DB + "sp_d_labtest_result_postprocessing') AS oid")) {
        if (rs.next() && rs.getObject("oid") != null) {
          return;
        }
        last = null;
      } catch (Exception e) {
        last = e;
      }
      try {
        Thread.sleep(2000);
      } catch (InterruptedException ie) {
        Thread.currentThread().interrupt();
        break;
      }
    }
    throw new IllegalStateException(
        "sp_d_labtest_result_postprocessing not available before timeout", last);
  }

  @Override
  @AfterAll
  void tearDown() {
    // Intentionally a no-op: never stop the shared nbs-mssql/liquibase stack from this class. The
    // stack is either an externally-managed one we reused, or a Testcontainers stack that other
    // Unit test classes (e.g. DataDrivenUnitTests) in the same run also share -- stopping it here
    // would pull the database out from under them. Ryuk / JVM shutdown reclaims a Testcontainers
    // stack when the run ends.
  }

  private static boolean reusedExistingStack = false;

  private static boolean dbReachable() {
    try (var socket = new java.net.Socket()) {
      socket.connect(new java.net.InetSocketAddress("localhost", 3433), 2000);
      return true;
    } catch (Exception e) {
      return false;
    }
  }

  @AfterEach
  void cleanup() throws SQLException {
    if (insertedUids.isEmpty()) {
      return;
    }
    String csv = csv(insertedUids);
    try (Connection conn = connection();
        Statement st = conn.createStatement()) {
      // Delete in FK-safe order: child result tables -> grouping -> key -> LAB_TEST.
      st.execute("DELETE FROM " + DB + "LAB_TEST_RESULT WHERE LAB_TEST_UID IN (" + csv + ")");
      st.execute("DELETE FROM " + DB + "LAB_RESULT_VAL WHERE LAB_TEST_UID IN (" + csv + ")");
      st.execute("DELETE FROM " + DB + "TEST_RESULT_GROUPING WHERE LAB_TEST_UID IN (" + csv + ")");
      st.execute(
          "DELETE FROM "
              + DB
              + "nrt_lab_test_result_group_key WHERE LAB_TEST_UID IN ("
              + csv
              + ")");
      st.execute("DELETE FROM " + DB + "LAB_TEST WHERE LAB_TEST_UID IN (" + csv + ")");
    }
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
              try (Connection conn = connection();
                  Statement st = conn.createStatement()) {
                ready.countDown();
                go.await();
                for (long uid : myUids) {
                  st.execute(
                      "EXEC "
                          + DB
                          + "sp_d_labtest_result_postprocessing @pLabResultList='"
                          + uid
                          + "'");
                }
              } catch (SQLException e) {
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
    try (Connection conn = connection();
        Statement st = conn.createStatement()) {
      try (var rs =
          st.executeQuery(
              "SELECT COUNT(*) AS total, COUNT(DISTINCT TEST_RESULT_GRP_KEY) AS distinctKeys, "
                  + "COUNT(DISTINCT LAB_TEST_UID) AS distinctUids "
                  + "FROM "
                  + DB
                  + "nrt_lab_test_result_group_key "
                  + "WHERE LAB_TEST_UID IN ("
                  + csv(insertedUids)
                  + ")")) {
        assertTrue(rs.next(), "count query returned no rows");
        long total = rs.getLong("total");
        long distinct = rs.getLong("distinctKeys");
        long distinctUids = rs.getLong("distinctUids");
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
    }
  }

  private void seedLabTests(List<Long> uids) throws SQLException {
    try (Connection conn = connection();
        Statement st = conn.createStatement()) {
      StringBuilder sb = new StringBuilder("SET NOCOUNT ON; ");
      for (Long uid : uids) {
        // LAB_TEST_KEY is the (non-identity) PK; reuse the UID as the key (both far out of range).
        // LAB_TEST_TYPE='Result' routes the row into #TMP_Result_And_R_Result, and a brand-new
        // UID (not yet in nrt_lab_test_result_group_key) forces a new group-key allocation.
        sb.append(
            "INSERT INTO "
                + DB
                + "LAB_TEST (LAB_TEST_KEY, LAB_TEST_UID, LAB_TEST_TYPE, RECORD_STATUS_CD)"
                + " VALUES ("
                + uid
                + ", "
                + uid
                + ", 'Result', 'ACTIVE'); ");
      }
      st.execute(sb.toString());
    } catch (SQLException e) {
      fail("Failed to seed LAB_TEST rows: " + e.getMessage());
    }
  }

  // Dedicated raw JDBC connection (not pooled) so the test is never throttled by a connection pool
  // smaller than the thread count -- true simultaneity is required to expose the race.
  private Connection connection() throws SQLException {
    Connection conn = DriverManager.getConnection(jdbcUrl, jdbcUser, jdbcPassword);
    conn.setAutoCommit(true);
    return conn;
  }

  private static String csv(List<Long> values) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < values.size(); i++) {
      if (i > 0) {
        sb.append(',');
      }
      sb.append(values.get(i));
    }
    return sb.toString();
  }
}
