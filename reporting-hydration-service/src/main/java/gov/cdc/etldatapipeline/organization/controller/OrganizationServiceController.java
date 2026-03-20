package gov.cdc.etldatapipeline.organization.controller;

import java.util.UUID;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class OrganizationServiceController {

  private final KafkaTemplate<String, String> kafkaTemplate;

  @Value("${spring.kafka.input.topic-name-organization}")
  private String orgTopicName;

  @Value("${spring.kafka.input.topic-name-place}")
  private String placeTopicName;

  public OrganizationServiceController(
      @Qualifier("organizationKafkaTemplate") KafkaTemplate<String, String> kafkaTemplate) {
    this.kafkaTemplate = kafkaTemplate;
  }

  @PostMapping(value = "/reporting/organization-svc/organization")
  public ResponseEntity<String> postOrganization(@RequestBody String payLoad) {
    try {
      kafkaTemplate.send(orgTopicName, UUID.randomUUID().toString(), payLoad);
      return ResponseEntity.ok("Produced : " + payLoad);
    } catch (Exception ex) {
      return ResponseEntity.internalServerError()
          .body("Error processing the Organization data. Exception: " + ex.getMessage());
    }
  }

  @PostMapping(value = "/reporting/organization-svc/place")
  public ResponseEntity<String> postPlace(@RequestBody String payLoad) {
    try {
      kafkaTemplate.send(placeTopicName, UUID.randomUUID().toString(), payLoad);
      return ResponseEntity.ok("Produced : " + payLoad);
    } catch (Exception ex) {
      return ResponseEntity.internalServerError()
          .body("Error processing the Place data. Exception: " + ex.getMessage());
    }
  }
}
