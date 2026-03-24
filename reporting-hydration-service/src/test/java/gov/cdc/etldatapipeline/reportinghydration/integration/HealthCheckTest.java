package gov.cdc.etldatapipeline.reportinghydration.integration;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

@Disabled("The liquibase container is having startup issues, enable after resolution")
class HealthCheckTest extends AbstractIntegrationTest {

  @Test
  void testServiceIsHealthy() {
    Assertions.assertTrue(
        environment.getContainerByServiceName("reporting-hydration-service").isPresent(),
        "Reporting Hydration Service container should be present");
  }
}
