package gov.cdc.nbs.report.pipeline.coverage;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;

/**
 * Captures stored-procedure coverage from a live test database by reading {@code job_flow_log} and
 * scoring it against the {@link StoredProcCatalog}. Call {@link #record(JdbcClient)} from a suite's
 * teardown <em>before</em> the database container stops.
 *
 * <p>Rows accumulate across calls (the container truncates {@code job_flow_log} on each restart, so
 * each class contributes only its own rows); every call recomputes coverage over the running union,
 * logs a one-line summary, and overwrites {@code build/reports/sproc-coverage.md}. Capture is
 * best-effort — failures are logged, never thrown, so coverage never fails a test run.
 */
public final class StoredProcCoverageRecorder {

  private static final Logger log = LoggerFactory.getLogger(StoredProcCoverageRecorder.class);

  private static final Path REPORT = Path.of("build", "reports", "sproc-coverage.md");
  private static final String QUERY =
      "SELECT package_name, CONVERT(varchar(50), step_number) AS step_number, status_type"
          + " FROM dbo.job_flow_log";

  private static final List<ProcDefinition> CATALOG = new StoredProcCatalog().load();
  private static final Set<JobFlowLogRow> ACCUMULATED = ConcurrentHashMap.newKeySet();

  private StoredProcCoverageRecorder() {}

  /** Reads {@code job_flow_log}, folds it into the running union, then logs and writes coverage. */
  public static synchronized void record(JdbcClient jdbcClient) {
    try {
      List<JobFlowLogRow> rows =
          jdbcClient
              .sql(QUERY)
              .query(
                  (rs, rowNum) ->
                      new JobFlowLogRow(
                          rs.getString("package_name"),
                          rs.getString("step_number"),
                          rs.getString("status_type")))
              .list();
      ACCUMULATED.addAll(rows);

      CoverageResult result =
          CoverageReport.compute(CATALOG, JobFlowLogObservations.fromRows(ACCUMULATED));
      log.info(result.summary());
      writeReport(result);
    } catch (Exception e) {
      log.warn("Stored-proc coverage capture skipped (non-fatal): {}", e.toString());
    }
  }

  private static void writeReport(CoverageResult result) throws IOException {
    StringBuilder md = new StringBuilder();
    md.append("# Stored-procedure coverage\n\n")
        .append(result.summary())
        .append("\n\n")
        .append(
            String.format(
                "- Procedures invoked: %d / %d (%.1f%%)%n",
                result.invokedProcs(), result.loggableProcs(), result.procCoveragePct()))
        .append(
            String.format(
                "- Completed / errored: %d / %d%n", result.completedProcs(), result.erroredProcs()))
        .append(
            String.format(
                "- Steps reached: %d / %d (%.1f%%)%n",
                result.reachedSteps(), result.totalSteps(), result.stepCoveragePct()))
        .append("\n## Procedures not invoked\n\n");
    if (result.notInvokedProcs().isEmpty()) {
      md.append("_none_\n");
    } else {
      result.notInvokedProcs().forEach(proc -> md.append("- ").append(proc).append('\n'));
    }

    Files.createDirectories(REPORT.getParent());
    Files.writeString(REPORT, md.toString());
    log.info("Stored-proc coverage report written to {}", REPORT.toAbsolutePath());
  }
}
