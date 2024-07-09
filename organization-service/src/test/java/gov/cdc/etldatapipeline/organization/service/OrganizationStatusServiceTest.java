package gov.cdc.etldatapipeline.organization.service;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class OrganizationStatusServiceTest {

    @Test
    public void statusTest() {
        OrganizationStatusService statusService = new OrganizationStatusService();
        Assertions.assertEquals(HttpStatus.OK, statusService.getHealthStatus().getStatusCode());
    }
}