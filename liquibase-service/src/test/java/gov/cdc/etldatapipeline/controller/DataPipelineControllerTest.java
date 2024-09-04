package gov.cdc.etldatapipeline.controller;

import gov.cdc.etldatapipeline.service.DataPipelineStatusService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DataPipelineControllerTest {

    @Mock
    private DataPipelineStatusService dataPipelineStatusService;

    @InjectMocks
    private DataPipelineController controller;

    private AutoCloseable closeable;

    @BeforeEach
    public void setup() {
        closeable = MockitoAnnotations.openMocks(this);
        controller = new DataPipelineController(dataPipelineStatusService);
    }

    @AfterEach
    public void tearDown() throws Exception {
        closeable.close();
    }

    @Test
    void testGetStatusHealth() {
        final String responseBody = "Status OK";
        when(dataPipelineStatusService.getHealthStatus()).thenReturn(ResponseEntity.ok(responseBody));

        ResponseEntity<String> response = controller.getDataPipelineStatusHealth();

        verify(dataPipelineStatusService).getHealthStatus();
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(responseBody, response.getBody());
    }
}