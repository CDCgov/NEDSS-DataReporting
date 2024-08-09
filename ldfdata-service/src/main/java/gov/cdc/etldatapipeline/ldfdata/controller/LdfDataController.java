package gov.cdc.etldatapipeline.ldfdata.controller;

import gov.cdc.etldatapipeline.ldfdata.service.KafkaProducerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@Slf4j
public class LdfDataController {
    private final KafkaProducerService producerService;

    @Value("${spring.kafka.input.topic-name}")
    private String topicName;

    @GetMapping("/reporting/ldfdata-svc/status")
    @ResponseBody
    public ResponseEntity<String> getDataPipelineStatusHealth() {
        log.info("LdfData Service Status OK");
        return ResponseEntity.status(HttpStatus.OK).body("LdfData Preprocessing Service Status OK");
    }

    @PostMapping("/reporting/ldfdata-svc/publish")
    public void publishMessageToKafka(@RequestBody String jsonData) {
        producerService.sendMessage(topicName, jsonData);
    }
}
