package gov.cdc.nbs.report.pipeline.integration.unit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;

class ScheduledCleanupAppLockReleaseTest extends UnitTest {

  private static final String EVENT_METRIC_LOCK = "RTR:scheduled:event-metric-cleanup";
  private static final String LAB100_LOCK = "RTR:scheduled:lab100-cleanup";
  private static final String LAB100_FAILURE_TRIGGER = "trg_test_lab100_cleanup_failure";

  @Autowired private PostProcRepository postProcRepository;

  @Value("${spring.datasource.admin.url}")
  private String adminJdbcUrl;

  @Value("${spring.datasource.admin.username}")
  private String adminJdbcUser;

  @Value("${spring.datasource.admin.password}")
  private String adminJdbcPassword;

  @Test
  void releasesEventMetricLockAfterAProcedureFailure() throws SQLException {
    try (Connection connection = adminConnection()) {
      String originalValue = readMetricsLookbackDays(connection);
      try {
        updateMetricsLookbackDays(connection, "not-a-number");

        assertEquals(-1, postProcRepository.executeEventMetricCleanup());
        assertTrue(canAcquireLock(EVENT_METRIC_LOCK));
      } finally {
        updateMetricsLookbackDays(connection, originalValue);
      }
    }
  }

  @Test
  void releasesLab100LockAfterAProcedureFailure() throws SQLException {
    try (Connection connection = adminConnection()) {
      try (Statement statement = connection.createStatement()) {
        statement.execute(
            "CREATE TRIGGER dbo."
                + LAB100_FAILURE_TRIGGER
                + " ON dbo.LAB100 AFTER UPDATE AS BEGIN THROW 51000, 'test failure', 1; END");
        assertEquals(-1, postProcRepository.executeLab100Cleanup());
        assertTrue(canAcquireLock(LAB100_LOCK));
      } finally {
        try (Statement statement = connection.createStatement()) {
          statement.execute("DROP TRIGGER IF EXISTS dbo." + LAB100_FAILURE_TRIGGER);
        }
      }
    }
  }

  private String readMetricsLookbackDays(Connection connection) throws SQLException {
    try (Statement statement = connection.createStatement();
        ResultSet result =
            statement.executeQuery(
                "SELECT config_value FROM dbo.nrt_odse_NBS_configuration "
                    + "WHERE config_key = 'METRICS_GOBACKBY_DAYS'")) {
      result.next();
      return result.getString(1);
    }
  }

  private void updateMetricsLookbackDays(Connection connection, String value) throws SQLException {
    try (Statement statement = connection.createStatement()) {
      statement.executeUpdate(
          "UPDATE dbo.nrt_odse_NBS_configuration SET config_value = '"
              + value.replace("'", "''")
              + "' WHERE config_key = 'METRICS_GOBACKBY_DAYS'");
    }
  }

  private boolean canAcquireLock(String lockResource) throws SQLException {
    try (Connection connection = adminConnection();
        Statement statement = connection.createStatement()) {
      int lockResult;
      try (ResultSet result =
          statement.executeQuery(
              "DECLARE @lock_result int; EXEC @lock_result = sys.sp_getapplock "
                  + "@Resource = N'"
                  + lockResource
                  + "', @LockMode = N'Exclusive', @LockOwner = N'Session', @LockTimeout = 0; "
                  + "SELECT @lock_result")) {
        result.next();
        lockResult = result.getInt(1);
      }
      if (lockResult >= 0) {
        statement.execute(
            "EXEC sys.sp_releaseapplock @Resource = N'"
                + lockResource
                + "', @LockOwner = N'Session'");
      }
      return lockResult >= 0;
    }
  }

  private Connection adminConnection() throws SQLException {
    String rdbJdbcUrl = adminJdbcUrl.replaceAll("databaseName=[^;]+", "databaseName=RDB_MODERN");
    return DriverManager.getConnection(rdbJdbcUrl, adminJdbcUser, adminJdbcPassword);
  }
}
