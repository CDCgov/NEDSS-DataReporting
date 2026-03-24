package gov.cdc.etldatapipeline.observation.controller;

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
public class ObservationServiceController {

  @Qualifier("observationKafkaTemplate")
  private final KafkaTemplate<String, String> kafkaTemplate;

  @Value("${spring.kafka.input.topic-name-observation}")
  private String observationTopic = "nbs_Observation";

  @PostMapping(value = "/reporting/observation-svc/observation")
  public ResponseEntity<String> postObservation(@RequestBody String payLoad) {
    try {
      kafkaTemplate.send(observationTopic, UUID.randomUUID().toString(), payLoad);
      return ResponseEntity.ok("Produced : " + payLoad);
    } catch (Exception ex) {
      return ResponseEntity.internalServerError()
          .body("Error processing the Observation data. Exception: " + ex.getMessage());
    }
  }
}
