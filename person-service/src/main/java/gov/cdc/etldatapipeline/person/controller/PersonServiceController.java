package gov.cdc.etldatapipeline.person.controller;

import gov.cdc.etldatapipeline.person.service.PersonStatusService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class PersonServiceController {

    private final PersonStatusService dataPipelineStatusSvc;
    private final KafkaTemplate<String, String> kafkaTemplate;

    private static final String PRODUCED = "Produced : ";

    @Value("${spring.kafka.input.topic-name}")
    private String personTopicName = "nbs_Person";

    @Value("${spring.kafka.input.topic-name-user}")
    private String userTopicName = "nbs_Auth_user";

    @GetMapping("/reporting/person-svc/status")
    public ResponseEntity<String> getDataPipelineStatusHealth() {
        return this.dataPipelineStatusSvc.getHealthStatus();
    }

    @PostMapping(value = "/reporting/person-svc/provider")
    public ResponseEntity<String> postProvider(@RequestBody String payLoad) {
        try {
            kafkaTemplate.send(personTopicName, UUID.randomUUID().toString(), payLoad);
            return ResponseEntity.ok(PRODUCED + payLoad);
        } catch (Exception ex) {
            return ResponseEntity.internalServerError().body("Failed to process the provider. Exception : " + ex.getMessage());
        }
    }

    @PostMapping(value = "/reporting/person-svc/patient")
    public ResponseEntity<String> postPatient(@RequestBody String payLoad) {
        try {
            kafkaTemplate.send(personTopicName, UUID.randomUUID().toString(), payLoad);
            return ResponseEntity.ok(PRODUCED + payLoad);
        } catch (Exception ex) {
            return ResponseEntity.internalServerError().body("Failed to process the Patient. Exception : " + ex.getMessage());
        }
    }

    @PostMapping(value = "/reporting/person-svc/user")
    public ResponseEntity<String> postUser(@RequestBody String payLoad) {
        try {
            kafkaTemplate.send(userTopicName, UUID.randomUUID().toString(), payLoad);
            return ResponseEntity.ok(PRODUCED + payLoad);
        } catch (Exception ex) {
            return ResponseEntity.internalServerError().body("Failed to process the User. Exception : " + ex.getMessage());
        }
    }
}
