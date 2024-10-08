package gov.cdc.etldatapipeline.person.service;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class PersonStatusServiceTest {

    @Test
    void statusTest() {
        PersonStatusService statusService = new PersonStatusService();
        Assertions.assertEquals(HttpStatus.OK, statusService.getHealthStatus().getStatusCode());
    }
}
