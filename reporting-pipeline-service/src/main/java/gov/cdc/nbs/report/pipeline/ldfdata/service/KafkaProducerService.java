package gov.cdc.nbs.report.pipeline.ldfdata.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service("LDFDataKafkaProducerService")
public class KafkaProducerService {

  private final KafkaTemplate<String, String> kafkaTemplate;

  @Autowired
  public KafkaProducerService(
      @Qualifier("ldfdataKafkaTemplate") KafkaTemplate<String, String> kafkaTemplate) {
    this.kafkaTemplate = kafkaTemplate;
  }

  public void sendMessage(String topicName, String jsonData) {
    kafkaTemplate.send(topicName, jsonData);
  }
}
