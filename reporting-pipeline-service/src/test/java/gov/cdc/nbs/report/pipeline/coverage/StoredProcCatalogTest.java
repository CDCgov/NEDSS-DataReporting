package gov.cdc.nbs.report.pipeline.coverage;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

class StoredProcCatalogTest {

  private final List<ProcDefinition> catalog = new StoredProcCatalog().load();

  @Test
  void finds_every_routine_file() {
    assertEquals(130, catalog.size());
  }

  @Test
  void counts_procs_that_log_to_job_flow_log() {
    assertEquals(128, StoredProcCatalog.loggingProcCount(catalog));
  }

  @Test
  void counts_the_total_step_universe() {
    assertEquals(275, StoredProcCatalog.totalStepCount(catalog));
  }

  @Test
  void resolves_package_name_for_the_large_majority_of_logging_procs() {
    // package_name is best-effort: ~113 of 128 logging procs expose a literal identifier; the
    // remainder (pagebuilder / event-style procs) log it in a shape these patterns don't capture
    // and can be matched on procName or via a small override map at coverage time.
    long resolved =
        catalog.stream()
            .filter(ProcDefinition::logsToJobFlowLog)
            .filter(definition -> definition.packageName() != null)
            .count();
    assertTrue(resolved >= 110, "resolved package names = " + resolved);
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
}
