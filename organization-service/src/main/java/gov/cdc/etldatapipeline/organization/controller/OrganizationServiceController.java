package gov.cdc.etldatapipeline.organization.controller;

import gov.cdc.etldatapipeline.organization.service.OrganizationStatusService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
public class OrganizationServiceController {

    private final OrganizationStatusService organizationStatusService;

    private final KafkaTemplate<String, String> kafkaTemplate;

    @Value("${spring.kafka.input.topic-name}")
    private String orgTopicName = "nbs_Organization";

    public OrganizationServiceController(OrganizationStatusService organizationStatusService, KafkaTemplate<String, String> kafkaTemplate) {
        this.organizationStatusService = organizationStatusService;
        this.kafkaTemplate = kafkaTemplate;
    }

    @GetMapping("/reporting/organization-svc/status")
    public ResponseEntity<String> getDataPipelineStatusHealth() {
        return this.organizationStatusService.getHealthStatus();
    }

    @PostMapping(value = "/reporting/organization-svc/produce")
    public ResponseEntity<String> postOrganization(@RequestBody String payLoad) {
        try {
            kafkaTemplate.send(orgTopicName,
                    UUID.randomUUID().toString(), payLoad);
            return ResponseEntity.ok("Produced : " + payLoad);
        } catch (Exception ex) {
            return ResponseEntity.internalServerError()
                    .body("Error processing the Organization data. Exception: " + ex.getMessage());
        }
    }
}
