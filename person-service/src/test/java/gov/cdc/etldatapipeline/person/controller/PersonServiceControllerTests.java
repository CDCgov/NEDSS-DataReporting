package gov.cdc.etldatapipeline.person.controller;

import gov.cdc.etldatapipeline.person.service.PersonStatusService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PersonServiceControllerTests {

    @Mock
    private PersonStatusService dataPipelineStatusService;

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    @InjectMocks
    private PersonServiceController controller;

    private AutoCloseable closeable;

    @BeforeEach
    public void setup() {
        closeable = MockitoAnnotations.openMocks(this);
        controller = new PersonServiceController(dataPipelineStatusService, kafkaTemplate);
    }

    @AfterEach
    public void tearDown() throws Exception {
        closeable.close();
    }

    @Test
    void testPostProvider() {
        String payload = "{\"payload\": {\"after\": {\"cd\": \"PRV\"}}}";

        ResponseEntity<String> response = controller.postProvider(payload);

        assertEquals("Produced : " + payload, response.getBody());
        assertEquals(HttpStatus.OK, response.getStatusCode());
    }

    @Test
    void testPostPatient() {
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

    @ParameterizedTest
    @CsvSource({"patient", "provider"})
    void testPostPatientError(String type) {
        final String responseError = "Server ERROR";

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenThrow(new RuntimeException(responseError));
        ResponseEntity<String> response = type.equals("patient") ?
                controller.postPatient("{}") : controller.postProvider("{}");
        assertNotNull(response.getBody());
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertTrue(response.getBody().contains(responseError));
    }

}
