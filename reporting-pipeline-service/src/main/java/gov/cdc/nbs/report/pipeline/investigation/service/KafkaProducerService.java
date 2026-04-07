package gov.cdc.nbs.report.pipeline.investigation.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class KafkaProducerService {

  private final KafkaTemplate<String, String> kafkaTemplate;

  @Autowired
  public KafkaProducerService(
      @Qualifier("investigationKafkaTemplate") KafkaTemplate<String, String> kafkaTemplate) {
    this.kafkaTemplate = kafkaTemplate;
  }

  public void sendMessage(String topicName, String jsonData) {
    kafkaTemplate.send(topicName, jsonData);
  }
}
