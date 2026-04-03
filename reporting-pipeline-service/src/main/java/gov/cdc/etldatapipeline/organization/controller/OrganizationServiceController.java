package gov.cdc.etldatapipeline.organization.controller;

import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class OrganizationServiceController {

  @Qualifier("organizationKafkaTemplate")
  private final KafkaTemplate<String, String> kafkaTemplate;

  @Value("${spring.kafka.topics.nbs.organization}")
  private String orgTopicName = "nbs_Organization";

  @Value("${spring.kafka.topics.nbs.place}")
  private String placeTopicName = "nbs_Place";

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
