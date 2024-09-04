package gov.cdc.etldatapipeline.service;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class DataPipelineStatusServiceTest {

    @Test
    void statusTest() {
        DataPipelineStatusService statusService = new DataPipelineStatusService();
        Assertions.assertEquals(HttpStatus.OK, statusService.getHealthStatus().getStatusCode());
    }
}

