package gov.cdc.etldatapipeline.person.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
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

class PersonServiceControllerTests {

  @Mock private KafkaTemplate<String, String> kafkaTemplate;

  @InjectMocks private PersonServiceController controller;

  private AutoCloseable closeable;

  @BeforeEach
  void setup() {
    closeable = MockitoAnnotations.openMocks(this);
    controller = new PersonServiceController(kafkaTemplate);
  }

  @AfterEach
  void tearDown() throws Exception {
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
  void testPostUser() {
    String payload = "{\"payload\": {\"after\": {\"auth_user_uid\": \"11\"}}}";

    ResponseEntity<String> response = controller.postUser(payload);

    assertEquals("Produced : " + payload, response.getBody());
    assertEquals(HttpStatus.OK, response.getStatusCode());
  }

  @ParameterizedTest
  @CsvSource({"patient", "provider", "user"})
  void testPostPatientError(String type) {
    final String responseError = "Server ERROR";

    when(kafkaTemplate.send(anyString(), anyString(), anyString()))
        .thenThrow(new RuntimeException(responseError));
    ResponseEntity<String> response =
        switch (type) {
          case "patient" -> controller.postPatient("{}");
          case "provider" -> controller.postProvider("{}");
          case "user" -> controller.postUser("{}");
          default -> ResponseEntity.ok("Default");
        };
    assertNotNull(response.getBody());
    assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
    assertTrue(response.getBody().contains(responseError));
  }
}
