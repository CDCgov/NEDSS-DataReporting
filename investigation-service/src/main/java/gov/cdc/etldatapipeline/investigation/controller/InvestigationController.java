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

    @Value("${spring.kafka.input.topic-name-phc}")
    private String investigationTopic;

    @Value("${spring.kafka.input.topic-name-ntf}")
    private String notificationTopic;

    @Value("${spring.kafka.input.topic-name-int}")
    private String interviewTopic;

    @Value("${spring.kafka.input.topic-name-ctr}")
    private String contactTopic;


    @GetMapping("/reporting/investigation-svc/status")
    public ResponseEntity<String> getDataPipelineStatusHealth() {
        log.info("Investigation Service Status OK");
        return ResponseEntity.status(HttpStatus.OK).body("Investigation Service Status OK");
    }

    @PostMapping("/reporting/investigation-svc/investigation")
    public void postInvestigation(@RequestBody String jsonData) {
        producerService.sendMessage(investigationTopic, jsonData);
    }

    @PostMapping("/reporting/investigation-svc/notification")
    public void postNotification(@RequestBody String jsonData) {
        producerService.sendMessage(notificationTopic, jsonData);
    }

    @PostMapping("/reporting/investigation-svc/interview")
    public void postInterview(@RequestBody String jsonData) {
        producerService.sendMessage(interviewTopic, jsonData);
    }

    @PostMapping("/reporting/investigation-svc/contact")
    public void postContact(@RequestBody String jsonData) {
        producerService.sendMessage(contactTopic, jsonData);
    }
}
