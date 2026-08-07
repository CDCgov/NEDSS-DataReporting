package gov.cdc.nbs.report.pipeline.coverage;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

class StoredProcCatalogTest {

  private final List<ProcDefinition> catalog = new StoredProcCatalog().load();

  @Test
  void finds_every_routine_file() {
    assertEquals(131, catalog.size());
  }

  @Test
  void counts_procs_that_log_to_job_flow_log() {
    assertEquals(129, StoredProcCatalog.loggingProcCount(catalog));
  }

  @Test
  void counts_the_total_step_universe() {
    assertEquals(275, StoredProcCatalog.totalStepCount(catalog));
  }

  @Test
  void resolves_package_name_for_the_large_majority_of_logging_procs() {
    // package_name is best-effort: ~113 of 129 logging procs expose a literal identifier; the
    // remainder (pagebuilder / event-style/helper procs) log it in a shape these patterns don't
    // capture
    // and can be matched on procName or via a small override map at coverage time.
    long resolved =
        catalog.stream()
            .filter(ProcDefinition::logsToJobFlowLog)
            .filter(definition -> definition.packageName() != null)
            .count();
    assertTrue(resolved >= 110, "resolved package names = " + resolved);
  }

  @Test
  void keeps_representative_simple_and_detailed_event_procedures_coverable() {
    ProcDefinition simple = find("sp_organization_event");
    ProcDefinition detailed = find("sp_public_health_case_fact_datamart_event");

    assertTrue(simple.logsToJobFlowLog());
    assertTrue(detailed.logsToJobFlowLog());
    assertTrue(detailed.stepCount() > 0);

    String detailedStep = detailed.stepNumbers().iterator().next();
    CoverageResult result =
        CoverageReport.compute(
            List.of(simple, detailed),
            JobFlowLogObservations.fromRows(
                List.of(
                    new JobFlowLogRow(simple.procName(), null, "COMPLETE"),
                    new JobFlowLogRow(detailed.procName(), detailedStep, "START"),
                    new JobFlowLogRow(detailed.procName(), null, "COMPLETE"))));

    assertEquals(2, result.invokedProcs());
    assertEquals(2, result.completedProcs());
    assertEquals(1, result.reachedSteps());
  }

  @Test
  void extracts_create_procedure_name() {
    ProcDefinition organization =
        catalog.stream()
            .filter(
                definition -> definition.fileName().contains("sp_nrt_organization_postprocessing"))
            .findFirst()
            .orElseThrow();
    assertEquals("sp_nrt_organization_postprocessing", organization.procName());
  }

  private ProcDefinition find(String procedureName) {
    return catalog.stream()
        .filter(definition -> definition.procName().equals(procedureName))
        .findFirst()
        .orElseThrow();
  }
}
