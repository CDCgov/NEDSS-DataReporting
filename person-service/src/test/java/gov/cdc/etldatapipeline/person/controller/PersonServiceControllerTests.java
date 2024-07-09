package gov.cdc.etldatapipeline.person.controller;

import gov.cdc.etldatapipeline.person.service.PersonStatusService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

public class PersonServiceControllerTests {

    @Mock
    private PersonStatusService dataPipelineStatusService;

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    @InjectMocks
    private PersonServiceController controller;

    @BeforeEach
    public void setup() {
        MockitoAnnotations.openMocks(this);
        controller = new PersonServiceController(dataPipelineStatusService, kafkaTemplate);
    }

    @Test
    public void testPostProvider() throws Exception {
        String payload = "{\"payload\": {\"after\": {\"cd\": \"PRV\"}}}";

        ResponseEntity<String> response = controller.postProvider(payload);

        assertEquals("Produced : " + payload, response.getBody());
        assertEquals(HttpStatus.OK, response.getStatusCode());
    }

    @Test
    public void testPostPatient() {
        String payload = "{\"payload\": {\"after\": {\"cd\": \"PAT\"}}}";

        ResponseEntity<String> response = controller.postPatient(payload);

        assertEquals("Produced : " + payload, response.getBody());
        assertEquals(HttpStatus.OK, response.getStatusCode());
    }

    @Test
    void testGetStatusHealth() {
        final String responseBody = "Person Service Status OK";
        when(dataPipelineStatusService.getHealthStatus()).thenReturn(ResponseEntity.ok(responseBody));

        ResponseEntity<String> response = controller.getDataPipelineStatusHealth();

        verify(dataPipelineStatusService).getHealthStatus();
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(responseBody, response.getBody());
    }
}
