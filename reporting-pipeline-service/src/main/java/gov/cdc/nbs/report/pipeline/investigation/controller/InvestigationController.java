package gov.cdc.nbs.report.pipeline.investigation.controller;

import gov.cdc.nbs.report.pipeline.investigation.service.KafkaProducerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@Slf4j
public class InvestigationController {
  private final KafkaProducerService producerService;

  @Value("${spring.kafka.topics.nbs.public-health-case}")
  private String investigationTopic;

  @Value("${spring.kafka.topics.nbs.notification}")
  private String notificationTopic;

  @Value("${spring.kafka.topics.nbs.interview}")
  private String interviewTopic;

  @Value("${spring.kafka.topics.nbs.ct-contact}")
  private String contactTopic;

  @Value("${spring.kafka.topics.nbs.intervention}")
  private String vaccinationTopic;

  @Value("${spring.kafka.topics.nbs.treatment}")
  private String treatmentTopic;

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

  @PostMapping("/reporting/investigation-svc/vaccination")
  public void postVaccination(@RequestBody String jsonData) {
    producerService.sendMessage(vaccinationTopic, jsonData);
  }

  @PostMapping("/reporting/investigation-svc/treatment")
  public void postTreatment(@RequestBody String jsonData) {
    producerService.sendMessage(treatmentTopic, jsonData);
  }
}
