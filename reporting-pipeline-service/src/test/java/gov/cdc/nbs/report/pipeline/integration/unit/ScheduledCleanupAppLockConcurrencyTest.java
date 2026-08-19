package gov.cdc.nbs.report.pipeline.integration.unit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTimeout;
import static org.junit.jupiter.api.Assertions.assertTrue;

import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.util.function.Supplier;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.parallel.Execution;
import org.junit.jupiter.api.parallel.ExecutionMode;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;

@Execution(ExecutionMode.SAME_THREAD)
class ScheduledCleanupAppLockConcurrencyTest extends UnitTest {

  private static final String EVENT_METRIC_LOCK = "RTR:scheduled:event-metric-cleanup";
  private static final String EVENT_METRIC_PROCEDURE = "sp_event_metric_cleanup_postprocessing";
  private static final String LAB100_LOCK = "RTR:scheduled:lab100-cleanup";
  private static final String LAB100_PROCEDURE = "sp_lab100_cleanup";
  private static final Duration SKIP_TIMEOUT = Duration.ofSeconds(2);

  @Autowired private PostProcRepository postProcRepository;

  @Value("${spring.datasource.admin.url}")
  private String adminJdbcUrl;

  @Value("${spring.datasource.admin.username}")
  private String adminJdbcUser;

  @Value("${spring.datasource.admin.password}")
  private String adminJdbcPassword;

  @Test
  void eventMetricCleanupSkipsWithoutWritingNormalJobFlowLogsWhenLocked() throws SQLException {
    assertSkipsWhenLocked(
        EVENT_METRIC_LOCK, EVENT_METRIC_PROCEDURE, postProcRepository::executeEventMetricCleanup);
  }

  @Test
  void lab100CleanupSkipsWithoutWritingNormalJobFlowLogsWhenLocked() throws SQLException {
    assertSkipsWhenLocked(LAB100_LOCK, LAB100_PROCEDURE, postProcRepository::executeLab100Cleanup);
  }

  @Test
  void cleanupLocksDoNotBlockTheOtherCleanupProcedure() throws SQLException {
    try (Connection eventMetricLockOwner = adminConnection()) {
      acquireLock(eventMetricLockOwner, EVENT_METRIC_LOCK);
      try {
        assertEquals(1, postProcRepository.executeLab100Cleanup());
      } finally {
        releaseLock(eventMetricLockOwner, EVENT_METRIC_LOCK);
      }
    }

    try (Connection lab100LockOwner = adminConnection()) {
      acquireLock(lab100LockOwner, LAB100_LOCK);
      try {
        assertEquals(1, postProcRepository.executeEventMetricCleanup());
      } finally {
        releaseLock(lab100LockOwner, LAB100_LOCK);
      }
    }
  }

  private void assertSkipsWhenLocked(
      String lockResource, String procedureName, Supplier<Integer> scheduledProcedure)
      throws SQLException {
    try (Connection lockOwner = adminConnection()) {
      acquireLock(lockOwner, lockResource);
      try {
        long jobFlowLogCount = normalJobFlowLogCount(lockOwner, procedureName);

        assertTimeout(SKIP_TIMEOUT, () -> assertEquals(-2, scheduledProcedure.get()));

        assertEquals(jobFlowLogCount, normalJobFlowLogCount(lockOwner, procedureName));
      } finally {
        releaseLock(lockOwner, lockResource);
      }
    }
  }

  private long normalJobFlowLogCount(Connection connection, String procedureName)
      throws SQLException {
    try (Statement statement = connection.createStatement();
        ResultSet result =
            statement.executeQuery(
                "SELECT COUNT(*) FROM dbo.job_flow_log WHERE package_name = '"
                    + procedureName
                    + "' AND status_type IN ('START', 'COMPLETE')")) {
      result.next();
      return result.getLong(1);
    }
  }

  private void acquireLock(Connection connection, String lockResource) throws SQLException {
    assertTrue(lockResult(connection, lockResource) >= 0);
  }

  private int lockResult(Connection connection, String lockResource) throws SQLException {
    try (Statement statement = connection.createStatement();
        ResultSet result =
            statement.executeQuery(
                "DECLARE @lock_result int; EXEC @lock_result = sys.sp_getapplock "
                    + "@Resource = N'"
                    + lockResource
                    + "', @LockMode = N'Exclusive', @LockOwner = N'Session', @LockTimeout = 0; "
                    + "SELECT @lock_result")) {
      result.next();
      return result.getInt(1);
    }
  }

  private void releaseLock(Connection connection, String lockResource) throws SQLException {
    try (Statement statement = connection.createStatement()) {
      statement.execute(
          "EXEC sys.sp_releaseapplock @Resource = N'"
              + lockResource
              + "', @LockOwner = N'Session'");
    }
  }

  private Connection adminConnection() throws SQLException {
    String rdbJdbcUrl = adminJdbcUrl.replaceAll("databaseName=[^;]+", "databaseName=RDB_MODERN");
    return DriverManager.getConnection(rdbJdbcUrl, adminJdbcUser, adminJdbcPassword);
  }
}
