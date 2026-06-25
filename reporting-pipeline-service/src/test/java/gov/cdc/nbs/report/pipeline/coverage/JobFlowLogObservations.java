package gov.cdc.nbs.report.pipeline.coverage;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

/**
 * The "what was actually executed" side of coverage, derived from {@code job_flow_log} rows: which
 * package identifiers were seen, which completed or errored, and which {@code (package, step)}
 * pairs were reached.
 *
 * @param invokedPackages every distinct {@code package_name} observed
 * @param completedPackages packages that logged a {@code COMPLETE} status
 * @param erroredPackages packages that logged an {@code ERROR} status
 * @param reachedSteps distinct {@code (package_name, step_number)} pairs reached
 */
public record JobFlowLogObservations(
    Set<String> invokedPackages,
    Set<String> completedPackages,
    Set<String> erroredPackages,
    Set<StepKey> reachedSteps) {

  /** A reached step, with the step number normalized so {@code "2.0"} and {@code "2"} match. */
  public record StepKey(String packageName, String stepNumber) {
    public StepKey {
      stepNumber = normalizeStep(stepNumber);
    }
  }

  /** Strips a trailing {@code .0} so float-formatted log values match integer step declarations. */
  static String normalizeStep(String step) {
    if (step == null) {
      return null;
    }
    String trimmed = step.trim();
    return trimmed.endsWith(".0") ? trimmed.substring(0, trimmed.length() - 2) : trimmed;
  }

  /**
   * Folds raw rows into the distinct sets used for coverage. Rows without a package are ignored.
   */
  public static JobFlowLogObservations fromRows(Collection<JobFlowLogRow> rows) {
    Set<String> invoked = new HashSet<>();
    Set<String> completed = new HashSet<>();
    Set<String> errored = new HashSet<>();
    Set<StepKey> reached = new HashSet<>();
    for (JobFlowLogRow row : rows) {
      if (row.packageName() == null) {
        continue;
      }
      invoked.add(row.packageName());
      if ("COMPLETE".equalsIgnoreCase(row.statusType())) {
        completed.add(row.packageName());
      }
      if ("ERROR".equalsIgnoreCase(row.statusType())) {
        errored.add(row.packageName());
      }
      if (row.stepNumber() != null) {
        reached.add(new StepKey(row.packageName(), row.stepNumber()));
      }
    }
    return new JobFlowLogObservations(invoked, completed, errored, reached);
  }
}
