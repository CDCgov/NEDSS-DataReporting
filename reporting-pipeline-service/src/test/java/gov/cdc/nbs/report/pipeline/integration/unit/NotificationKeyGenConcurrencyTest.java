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
 * Concurrency regression test for APP-738 (sibling of APP-736).
 *
 * <p>{@code sp_nrt_notification_postprocessing} (routine 006) allocates {@code d_notification_key}
 * (IDENTITY on {@code nrt_notification_key}, whose {@code notification_uid} has no unique index)
 * and inserts into {@code NOTIFICATION} using a {@code NOTIFICATION_KEY IS NULL} guard that is
 * snapshotted at SP start with {@code (NOLOCK)}. Two concurrent first-time batches for the same
 * {@code notification_uid} therefore both saw NULL, both minted a key, and both INSERTed the same
 * {@code NOTIFICATION} primary key, raising {@code Error 2627}.
 *
 * <p>The single-threaded {@code DataDrivenUnitTests} harness cannot reproduce this; it requires
 * real concurrency. This test seeds fresh {@code nrt_investigation_notification} rows (borrowing an
 * existing investigation context so the {@code NOTIFICATION_EVENT} insert's NOT-NULL keys are
 * satisfied and the SP commits) and fires N threads at the SAME brand-new {@code notification_uid}
 * per round.
 *
 * <p>Against the unfixed routine this fails with a 2627 duplicate-key error; against the fixed
 * routine (an {@code sp_getapplock}-serialized critical section plus a refresh of the at-SP-start
 * {@code NOTIFICATION_KEY} snapshots) it passes and exactly one {@code NOTIFICATION} row lands per
 * uid.
 */
class NotificationKeyGenConcurrencyTest extends UnitTest {

  private static final Logger log =
      LoggerFactory.getLogger(NotificationKeyGenConcurrencyTest.class);

  // The routine + key tables live in RDB_MODERN; the URL targets RDB_MODERN and every object
  // reference
  // is fully database-qualified, so the test never depends on the session's resolved default
  // catalog.
  private static final String CATALOG = "RDB_MODERN";
  private static final String DB = "RDB_MODERN.dbo.";

  // Distinct, well out-of-range notification_uid base so we never collide with seeded fixture data.
  private static final long NOTIF_UID_BASE = 971_000_000L;

  // An existing investigation context to borrow (the Hep-A foundation case): PHC 20000100 /
  // condition
  // 10110 / patient 20000000. It satisfies the NOTIFICATION_EVENT insert's NOT-NULL
  // INVESTIGATION_KEY / CONDITION_KEY so the SP commits and the step-5 NOTIFICATION race can
  // surface.
  private static final long CTX_PHC = 20000100L;
  private static final String CTX_CONDITION = "10110";
  private static final long CTX_PATIENT = 20000000L;

  @Autowired private Environment env;

  private String jdbcUrl;
  private String jdbcUser;
  private String jdbcPassword;

  private final List<Long> insertedNotifUids = new CopyOnWriteArrayList<>();

  /**
   * The nbs-mssql + liquibase stack is started by {@link UnitTest.Initializer} during Spring
   * context initialization (single-start, shared across every {@code @Tag("Unit")} class in the
   * run), so there is no container lifecycle to trigger here.
   */
  @BeforeAll
  void setUp() {
    jdbcUser = env.getProperty("spring.datasource.admin.username", "rtr_admin");
    jdbcPassword = env.getProperty("spring.datasource.admin.password", "rtr_admin");
    String configured =
        env.getProperty(
            "spring.datasource.admin.url",
            "jdbc:sqlserver://localhost:3433;databaseName=NBS_ODSE;encrypt=true;"
                + "trustServerCertificate=true;loginTimeout=3;");
    jdbcUrl = configured.replaceAll("databaseName=[^;]+", "databaseName=" + CATALOG);
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
                  "SELECT OBJECT_ID('" + DB + "sp_nrt_notification_postprocessing') AS oid")) {
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
        "sp_nrt_notification_postprocessing not available before timeout", last);
  }

  @Override
  @AfterAll
  void tearDown() {
    // Intentionally a no-op: never stop the shared nbs-mssql/liquibase stack from this class — it
    // is
    // either an externally-managed stack we reused or a Testcontainers stack other Unit test
    // classes
    // in the same run also share. Ryuk / JVM shutdown reclaims a Testcontainers stack at run end.
  }

  @AfterEach
  void cleanup() throws SQLException {
    if (insertedNotifUids.isEmpty()) {
      return;
    }
    String ncsv = csv(insertedNotifUids);
    try (Connection conn = connection();
        Statement st = conn.createStatement()) {
      // FK-safe order: NOTIFICATION_EVENT + NOTIFICATION (via key) -> key -> source.
      st.execute(
          "DELETE e FROM "
              + DB
              + "NOTIFICATION_EVENT e JOIN "
              + DB
              + "nrt_notification_key k ON e.NOTIFICATION_KEY = k.d_notification_key"
              + " WHERE k.notification_uid IN ("
              + ncsv
              + ")");
      st.execute(
          "DELETE n FROM "
              + DB
              + "NOTIFICATION n JOIN "
              + DB
              + "nrt_notification_key k ON n.NOTIFICATION_KEY = k.d_notification_key"
              + " WHERE k.notification_uid IN ("
              + ncsv
              + ")");
      st.execute(
          "DELETE FROM " + DB + "nrt_notification_key WHERE notification_uid IN (" + ncsv + ")");
      st.execute(
          "DELETE FROM "
              + DB
              + "nrt_investigation_notification WHERE notification_uid IN ("
              + ncsv
              + ")");
    }
    insertedNotifUids.clear();
  }

  @Test
  void concurrentNotificationPostprocessingDoesNotRaceOnNewNotificationKeys() throws Exception {
    final int rounds = 15;
    final int threadsPerRound = 16;

    List<Long> uids = new ArrayList<>();
    for (int r = 0; r < rounds; r++) {
      long uid = NOTIF_UID_BASE + r;
      uids.add(uid);
      insertedNotifUids.add(uid);
    }
    seedNotifications(uids);

    List<Throwable> failures = new CopyOnWriteArrayList<>();
    AtomicInteger keyViolations = new AtomicInteger();

    for (long uid : uids) {
      CountDownLatch ready = new CountDownLatch(threadsPerRound);
      CountDownLatch go = new CountDownLatch(1);
      CountDownLatch done = new CountDownLatch(threadsPerRound);
      ExecutorService pool = Executors.newFixedThreadPool(threadsPerRound);
      try {
        for (int t = 0; t < threadsPerRound; t++) {
          pool.submit(
              () -> {
                try (Connection conn = connection();
                    Statement st = conn.createStatement()) {
                  ready.countDown();
                  go.await();
                  st.execute(
                      "EXEC "
                          + DB
                          + "sp_nrt_notification_postprocessing @notification_uids='"
                          + uid
                          + "'");
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
        assertTrue(ready.await(60, TimeUnit.SECONDS), "threads did not reach the start latch");
        go.countDown();
        assertTrue(done.await(120, TimeUnit.SECONDS), "threads did not finish in time");
      } finally {
        pool.shutdownNow();
      }
    }

    if (!failures.isEmpty()) {
      log.error(
          "{} thread(s) threw; {} were notification key-gen race errors (2627/1205)",
          failures.size(),
          keyViolations.get());
      for (Throwable f : failures) {
        log.error("thread failure: {}", f.getMessage());
      }
    }

    assertTrue(
        failures.isEmpty(),
        () ->
            "Expected no exceptions from concurrent notification postprocessing, but "
                + failures.size()
                + " thread(s) threw ("
                + keyViolations.get()
                + " key-gen race errors: 2627 PK violation / 1205 deadlock). First: "
                + failures.get(0).getMessage());

    // Exactly one NOTIFICATION row per notification_uid: no duplicate-PK survivor, no lost insert.
    try (Connection conn = connection();
        Statement st = conn.createStatement();
        var rs =
            st.executeQuery(
                "SELECT COUNT(*) AS total, COUNT(DISTINCT k.notification_uid) AS uids FROM "
                    + DB
                    + "nrt_notification_key k JOIN "
                    + DB
                    + "NOTIFICATION n ON n.NOTIFICATION_KEY = k.d_notification_key "
                    + "WHERE k.notification_uid IN ("
                    + csv(uids)
                    + ")")) {
      assertTrue(rs.next(), "count query returned no rows");
      assertEquals(
          rounds, rs.getInt("uids"), "expected exactly one NOTIFICATION per notification_uid");
      assertEquals(
          rs.getInt("uids"),
          rs.getInt("total"),
          "duplicate NOTIFICATION rows detected for a notification_uid (key-gen race survivor)");
    }
  }

  private void seedNotifications(List<Long> uids) throws SQLException {
    try (Connection conn = connection();
        Statement st = conn.createStatement()) {
      StringBuilder sb = new StringBuilder("SET NOCOUNT ON; ");
      // APP-738 context: the SP's NOTIFICATION_EVENT insert requires a NOT-NULL INVESTIGATION_KEY
      // (INVESTIGATION joined on CASE_UID = public_health_case_uid). In a clean DB that
      // investigation does not exist, so the NOTIFICATION_EVENT insert rolls the whole proc back
      // and
      // zero notifications land -- masking the key-gen race entirely. Seed it once here (condition
      // CTX_CONDITION already ships in the baseline reference data). Idempotent: this method also
      // runs from LabTestKeyGenConcurrencyTest.
      sb.append(
          "IF NOT EXISTS (SELECT 1 FROM "
              + DB
              + "INVESTIGATION WHERE CASE_UID = "
              + CTX_PHC
              + ") INSERT INTO "
              + DB
              + "INVESTIGATION (INVESTIGATION_KEY, CASE_UID, RECORD_STATUS_CD) VALUES (99100, "
              + CTX_PHC
              + ", 'ACTIVE'); ");
      for (Long uid : uids) {
        // Fresh notification_uid (unseen by nrt_notification_key) so every call hits the first-time
        // key-gen + NOTIFICATION-insert path. refresh_datetime / max_datetime are GENERATED ALWAYS,
        // so
        // they are omitted from the column list.
        sb.append(
            "INSERT INTO "
                + DB
                + "nrt_investigation_notification (source_act_uid, notification_uid,"
                + " public_health_case_uid, condition_cd, local_patient_uid, notif_status,"
                + " notif_local_id) VALUES ("
                + uid
                + ", "
                + uid
                + ", "
                + CTX_PHC
                + ", '"
                + CTX_CONDITION
                + "', "
                + CTX_PATIENT
                + ", 'C', 'NOTIF-RACE-"
                + uid
                + "'); ");
      }
      st.execute(sb.toString());
    } catch (SQLException e) {
      fail("Failed to seed nrt_investigation_notification rows: " + e.getMessage());
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
