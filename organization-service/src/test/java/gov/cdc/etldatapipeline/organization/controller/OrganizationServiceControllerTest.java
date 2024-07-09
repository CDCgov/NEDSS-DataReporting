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

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
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
        MockitoAnnotations.openMocks(this);
        controller = new OrganizationServiceController(dataPipelineStatusService, mockKafkaTemplate);
    }

    @Test
    public void testPostOrganization() throws Exception {
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
}