package gov.cdc.etldatapipeline.person;

import gov.cdc.etldatapipeline.person.service.PersonStatusService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

public class PersonStatusServiceTest {

    @Test
    public void statusTest() {
        PersonStatusService statusService = new PersonStatusService();
        Assertions.assertEquals(HttpStatus.OK, statusService.getHealthStatus().getStatusCode());
    }
}
