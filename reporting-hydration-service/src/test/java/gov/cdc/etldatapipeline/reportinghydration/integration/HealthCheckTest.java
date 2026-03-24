package gov.cdc.etldatapipeline.reportinghydration.integration;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

class HealthCheckTest extends AbstractIntegrationTest {

  @Test
  void testServiceIsHealthy() {
    Assertions.assertTrue(
        environment.getContainerByServiceName("reporting-hydration-service").isPresent(),
        "Reporting Hydration Service container should be present");
  }
}
