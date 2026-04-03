package gov.cdc.etldatapipeline.reportingpipeline.integration;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

class HealthCheckTest extends AbstractIntegrationTest {

  @Test
  void testServiceIsHealthy() {
    Assertions.assertTrue(
        environment.getContainerByServiceName("reporting-pipeline-service").isPresent(),
        "Reporting Pipeline Service container should be present");
  }
}
