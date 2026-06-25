package gov.cdc.nbs.report.pipeline.coverage;

import java.util.List;

/**
 * The computed stored-procedure coverage for one test run.
 *
 * @param loggableProcs procedures that can log to {@code job_flow_log} (the denominator)
 * @param invokedProcs loggable procedures observed executing
 * @param completedProcs invoked procedures that logged a {@code COMPLETE}
 * @param erroredProcs invoked procedures that logged an {@code ERROR}
 * @param notInvokedProcs procedure names never seen (the gap list), sorted
 * @param totalSteps total step universe across loggable procedures
 * @param reachedSteps distinct steps reached
 */
public record CoverageResult(
    int loggableProcs,
    int invokedProcs,
    int completedProcs,
    int erroredProcs,
    List<String> notInvokedProcs,
    int totalSteps,
    int reachedSteps) {

  public double procCoveragePct() {
    return percentage(invokedProcs, loggableProcs);
  }

  public double stepCoveragePct() {
    return percentage(reachedSteps, totalSteps);
  }

  private static double percentage(int numerator, int denominator) {
    return denominator == 0 ? 0.0 : 100.0 * numerator / denominator;
  }

  /** One-line, log-friendly summary of both coverage measures. */
  public String summary() {
    return String.format(
        "Stored-proc coverage: procs %d/%d (%.1f%%) [completed=%d errored=%d] | steps %d/%d (%.1f%%)",
        invokedProcs,
        loggableProcs,
        procCoveragePct(),
        completedProcs,
        erroredProcs,
        reachedSteps,
        totalSteps,
        stepCoveragePct());
  }
}
