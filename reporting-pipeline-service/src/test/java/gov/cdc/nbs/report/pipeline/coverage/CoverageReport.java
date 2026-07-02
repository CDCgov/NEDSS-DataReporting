package gov.cdc.nbs.report.pipeline.coverage;

import gov.cdc.nbs.report.pipeline.coverage.JobFlowLogObservations.StepKey;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Computes stored-procedure coverage by intersecting the {@link StoredProcCatalog} denominator with
 * {@link JobFlowLogObservations} captured from a test run.
 *
 * <p>A procedure is matched to log rows by either of its identifiers — the resolved {@code
 * package_name} or its {@code CREATE PROCEDURE} name — since some procedures log their {@code sp_*}
 * name and others log a datamart label. Only procedures that can log are counted in the
 * denominator.
 */
public final class CoverageReport {

  private CoverageReport() {}

  public static CoverageResult compute(
      List<ProcDefinition> catalog, JobFlowLogObservations observations) {
    List<ProcDefinition> loggable =
        catalog.stream().filter(ProcDefinition::logsToJobFlowLog).toList();

    int invoked = 0;
    int completed = 0;
    int errored = 0;
    int totalSteps = 0;
    int reachedSteps = 0;
    List<String> notInvoked = new ArrayList<>();

    for (ProcDefinition proc : loggable) {
      Set<String> identifiers = identifiers(proc);

      if (anyObserved(identifiers, observations.invokedPackages())) {
        invoked++;
        if (anyObserved(identifiers, observations.completedPackages())) {
          completed++;
        }
        if (anyObserved(identifiers, observations.erroredPackages())) {
          errored++;
        }
      } else {
        notInvoked.add(proc.procName());
      }

      totalSteps += proc.stepCount();
      reachedSteps += reachedStepCount(proc, identifiers, observations);
    }

    notInvoked.sort(Comparator.nullsLast(Comparator.naturalOrder()));
    return new CoverageResult(
        loggable.size(), invoked, completed, errored, notInvoked, totalSteps, reachedSteps);
  }

  private static Set<String> identifiers(ProcDefinition proc) {
    Set<String> identifiers = new LinkedHashSet<>();
    if (proc.packageName() != null) {
      identifiers.add(proc.packageName());
    }
    if (proc.procName() != null) {
      identifiers.add(proc.procName());
    }
    return identifiers;
  }

  private static boolean anyObserved(Set<String> identifiers, Set<String> observed) {
    for (String identifier : identifiers) {
      if (observed.contains(identifier)) {
        return true;
      }
    }
    return false;
  }

  private static int reachedStepCount(
      ProcDefinition proc, Set<String> identifiers, JobFlowLogObservations observations) {
    int reached = 0;
    for (String step : proc.stepNumbers()) {
      for (String identifier : identifiers) {
        if (observations.reachedSteps().contains(new StepKey(identifier, step))) {
          reached++;
          break;
        }
      }
    }
    return reached;
  }
}
