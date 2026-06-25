package gov.cdc.nbs.report.pipeline.coverage;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

class CoverageReportTest {

  private static ProcDefinition proc(String name, String pkg, Set<String> steps, boolean logs) {
    return new ProcDefinition(name + ".sql", name, pkg, steps, logs);
  }

  @Test
  void counts_invoked_completed_errored_steps_and_the_gap_list() {
    List<ProcDefinition> catalog =
        List.of(
            proc("sp_a", "sp_a", Set.of("1", "2", "3"), true), // invoked + completed, 2/3 steps
            proc("sp_b", "B_LABEL", Set.of("1", "2"), true), //    invoked + errored via packageName
            proc("sp_c", "sp_c", Set.of("1"), true), //            never invoked
            proc("sp_d", null, Set.of(), false)); //               non-logging -> excluded

    List<JobFlowLogRow> rows =
        List.of(
            new JobFlowLogRow("sp_a", "1", "START"),
            new JobFlowLogRow("sp_a", "2.0", "START"), // 2.0 normalizes to 2
            new JobFlowLogRow("sp_a", null, "COMPLETE"),
            new JobFlowLogRow("B_LABEL", "1", "START"),
            new JobFlowLogRow("B_LABEL", null, "ERROR"),
            new JobFlowLogRow("legacy_proc", "1", "START")); // not in catalog -> ignored

    CoverageResult result = CoverageReport.compute(catalog, JobFlowLogObservations.fromRows(rows));

    assertEquals(3, result.loggableProcs()); // a, b, c (d excluded)
    assertEquals(2, result.invokedProcs()); // a, b
    assertEquals(1, result.completedProcs()); // a
    assertEquals(1, result.erroredProcs()); // b
    assertEquals(List.of("sp_c"), result.notInvokedProcs());
    assertEquals(6, result.totalSteps()); // 3 + 2 + 1
    assertEquals(3, result.reachedSteps()); // a: {1,2}; b: {1}
    assertEquals(66.7, round(result.procCoveragePct()));
    assertEquals(50.0, round(result.stepCoveragePct()));
  }

  @Test
  void matches_proc_by_create_procedure_name_when_package_label_differs() {
    // proc logs its sp_ name even though the catalog also carries a different package label
    List<ProcDefinition> catalog = List.of(proc("sp_x", "SOME_LABEL", Set.of("1"), true));
    List<JobFlowLogRow> rows = List.of(new JobFlowLogRow("sp_x", "1", "START"));

    CoverageResult result = CoverageReport.compute(catalog, JobFlowLogObservations.fromRows(rows));

    assertEquals(1, result.invokedProcs());
    assertEquals(1, result.reachedSteps());
  }

  @Test
  void empty_observations_yield_zero_coverage_and_full_gap_list() {
    List<ProcDefinition> catalog =
        List.of(
            proc("sp_a", "sp_a", Set.of("1"), true), proc("sp_b", "sp_b", Set.of("1", "2"), true));

    CoverageResult result =
        CoverageReport.compute(catalog, JobFlowLogObservations.fromRows(List.of()));

    assertEquals(0, result.invokedProcs());
    assertEquals(0, result.reachedSteps());
    assertEquals(List.of("sp_a", "sp_b"), result.notInvokedProcs());
    assertEquals(0.0, result.procCoveragePct());
    assertEquals(0.0, result.stepCoveragePct());
  }

  @Test
  void summary_includes_both_measures() {
    List<ProcDefinition> catalog = List.of(proc("sp_a", "sp_a", Set.of("1", "2"), true));
    List<JobFlowLogRow> rows = List.of(new JobFlowLogRow("sp_a", "1", "COMPLETE"));

    String summary =
        CoverageReport.compute(catalog, JobFlowLogObservations.fromRows(rows)).summary();

    assertTrue(summary.contains("procs 1/1"), summary);
    assertTrue(summary.contains("steps 1/2"), summary);
  }

  private static double round(double value) {
    return Math.round(value * 10.0) / 10.0;
  }
}
