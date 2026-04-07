package gov.cdc.nbs.report.pipeline.organization.controller;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

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

class OrganizationServiceControllerTest {

  @Mock private KafkaTemplate<String, String> mockKafkaTemplate;

  @InjectMocks private OrganizationServiceController controller;

  private AutoCloseable closeable;

  @BeforeEach
  void setup() {
    closeable = MockitoAnnotations.openMocks(this);
    controller = new OrganizationServiceController(mockKafkaTemplate);
  }

  @AfterEach
  void tearDown() throws Exception {
    closeable.close();
  }

  @Test
  void testPostOrganization() {
    String payload = "{\"payload\": {\"after\": {\"organization_uid\": \"10036000\"}}}";

    ResponseEntity<String> response = controller.postOrganization(payload);

    assertEquals("Produced : " + payload, response.getBody());
    assertEquals(HttpStatus.OK, response.getStatusCode());
  }

  @Test
  void testPostPlace() {
    String payload = "{\"payload\": {\"after\": {\"place_uid\": \"10036000\"}}}";

    ResponseEntity<String> response = controller.postPlace(payload);

    assertEquals("Produced : " + payload, response.getBody());
    assertEquals(HttpStatus.OK, response.getStatusCode());
  }

  @ParameterizedTest
  @CsvSource({"organization", "place"})
  void testPostError(String type) {
    final String responseError = "Server ERROR";

    when(mockKafkaTemplate.send(anyString(), anyString(), anyString()))
        .thenThrow(new RuntimeException(responseError));
    ResponseEntity<String> response =
        switch (type) {
          case "organization" -> controller.postOrganization("{}");
          case "place" -> controller.postPlace("{}");
          default -> ResponseEntity.ok("Default");
        };
    assertNotNull(response.getBody());
    assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
    assertTrue(response.getBody().contains(responseError));
  }
}
