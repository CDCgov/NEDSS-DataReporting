package gov.cdc.etldatapipeline.organization.controller;

import gov.cdc.etldatapipeline.organization.service.OrganizationStatusService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.util.StringUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OrganizationServiceControllerTest {

    @Mock
    private OrganizationStatusService dataPipelineStatusService;

    @Mock
    private KafkaTemplate<String, String> mockKafkaTemplate;

    @InjectMocks
    private OrganizationServiceController controller;


    @BeforeEach
    public void setup() {
        final var autoCloseable = MockitoAnnotations.openMocks(this);
        controller = new OrganizationServiceController(dataPipelineStatusService, mockKafkaTemplate);
    }

    @Test
    void testPostOrganization() {
        String payload = "{\"payload\": {\"after\": {\"organization_uid\": \"10036000\"}}}";

        ResponseEntity<String> response = controller.postOrganization(payload);

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

    @Test
    void testPostError() {
        final String responseError = "Server ERROR";

        when(mockKafkaTemplate.send(anyString(), anyString(), anyString())).thenThrow(new RuntimeException(responseError));
        ResponseEntity<String> response = controller.postOrganization("{}");
        assertNotNull(response.getBody());
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertTrue(response.getBody().contains(responseError));
    }
}