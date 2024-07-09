package gov.cdc.etldatapipeline.observation.controller;

import gov.cdc.etldatapipeline.observation.service.KafkaProducerService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@Slf4j
public class ObservationController {
    private final KafkaProducerService producerService;

    @Value("${spring.kafka.input.topic-name}")
    private String observationTopic;

    @Autowired
    public ObservationController(KafkaProducerService producerService) {
        this.producerService = producerService;
    }

    @GetMapping("/reporting/observation-svc/status")
    @ResponseBody
    public ResponseEntity<String> getDataPipelineStatusHealth() {
        log.info("Observation Service Status OK");
        return ResponseEntity.status(HttpStatus.OK).body("Observation Service Status OK");
    }

    @PostMapping("/publish")
    public void publishMessageToKafka(@RequestBody String jsonData) {
        producerService.sendMessage(observationTopic, jsonData);
    }
}
