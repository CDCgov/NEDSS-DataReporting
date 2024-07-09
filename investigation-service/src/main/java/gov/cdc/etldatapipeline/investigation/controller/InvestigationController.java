package gov.cdc.etldatapipeline.investigation.controller;

import gov.cdc.etldatapipeline.investigation.service.KafkaProducerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@Slf4j
public class InvestigationController {
    private final KafkaProducerService producerService;

    @Value("${spring.kafka.input.topic-name}")
    private String topicName;

    @GetMapping("/reporting/investigation-svc/status")
    @ResponseBody
    public ResponseEntity<String> getDataPipelineStatusHealth() {
        log.info("Investigation Service Status OK");
        return ResponseEntity.status(HttpStatus.OK).body("Investigation Service Status OK");
    }

    @PostMapping("/publish")
    public void publishMessageToKafka(@RequestBody String jsonData) {
        producerService.sendMessage(topicName, jsonData);
    }
}
