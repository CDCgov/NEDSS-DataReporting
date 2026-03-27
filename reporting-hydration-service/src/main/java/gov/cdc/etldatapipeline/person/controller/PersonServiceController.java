package gov.cdc.etldatapipeline.person.controller;

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
public class PersonServiceController {

  @Qualifier("personKafkaTemplate")
  private final KafkaTemplate<String, String> kafkaTemplate;

  private static final String PRODUCED = "Produced : ";

  @Value("${spring.kafka.topics.nbs.person}")
  private String personTopicName = "nbs_Person";

  @Value("${spring.kafka.topics.nbs.auth-user}")
  private String userTopicName = "nbs_Auth_user";

  @PostMapping(value = "/reporting/person-svc/provider")
  public ResponseEntity<String> postProvider(@RequestBody String payLoad) {
    try {
      kafkaTemplate.send(personTopicName, UUID.randomUUID().toString(), payLoad);
      return ResponseEntity.ok(PRODUCED + payLoad);
    } catch (Exception ex) {
      return ResponseEntity.internalServerError()
          .body("Failed to process the provider. Exception : " + ex.getMessage());
    }
  }

  @PostMapping(value = "/reporting/person-svc/patient")
  public ResponseEntity<String> postPatient(@RequestBody String payLoad) {
    try {
      kafkaTemplate.send(personTopicName, UUID.randomUUID().toString(), payLoad);
      return ResponseEntity.ok(PRODUCED + payLoad);
    } catch (Exception ex) {
      return ResponseEntity.internalServerError()
          .body("Failed to process the Patient. Exception : " + ex.getMessage());
    }
  }

  @PostMapping(value = "/reporting/person-svc/user")
  public ResponseEntity<String> postUser(@RequestBody String payLoad) {
    try {
      kafkaTemplate.send(userTopicName, UUID.randomUUID().toString(), payLoad);
      return ResponseEntity.ok(PRODUCED + payLoad);
    } catch (Exception ex) {
      return ResponseEntity.internalServerError()
          .body("Failed to process the User. Exception : " + ex.getMessage());
    }
  }
}
