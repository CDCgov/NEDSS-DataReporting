package gov.cdc.etldatapipeline.postprocessing.service;

import gov.cdc.etldatapipeline.postprocessing.repository.DeadLetterLogRepository;
import gov.cdc.etldatapipeline.postprocessing.repository.model.DeadLetterLog;
import java.sql.Timestamp;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Service;

@SuppressWarnings("java:S107")
@Service
public class DeadLetterProcessingService {
  private static final Logger logger = LoggerFactory.getLogger(DeadLetterProcessingService.class);
  private final DeadLetterLogRepository deadLetterLogRepository;

  public DeadLetterProcessingService(DeadLetterLogRepository deadLetterLogRepository) {
    this.deadLetterLogRepository = deadLetterLogRepository;
  }

  @KafkaListener(
      topics = {
        "${spring.kafka.topics.nrt.investigation}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.observation}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.organization}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.patient}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.provider}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nrt.investigation-notification}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.treatment}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nrt.investigation-case-management}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nrt.interview}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.ldf_data}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.place}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nrt.auth-user}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nrt.contact}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.vaccination}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.page}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.datamart}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.state_defined_field_metadata}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topic.condition}${spring.kafka.dlq.dlq-suffix}",

        // investigation-topic
        "${spring.kafka.topics.nbs.public-health-case}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.notification}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.interview}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.ct-contact}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.intervention}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.treatment}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.act-relationship}${spring.kafka.dlq.dlq-suffix}",

        // ldf-topic
        "${spring.kafka.topics.nbs.state-defined-field-data}${spring.kafka.dlq.dlq-suffix}",

        // observation-topic
        "${spring.kafka.topics.nbs.observation}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.act-relationship}${spring.kafka.dlq.dlq-suffix}",

        // organization-topic
        "${spring.kafka.topics.nbs.organization}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.place}${spring.kafka.dlq.dlq-suffix}",

        // person-topic
        "${spring.kafka.topics.nbs.person}${spring.kafka.dlq.dlq-suffix}",
        "${spring.kafka.topics.nbs.auth-user}${spring.kafka.dlq.dlq-suffix}"
      },
      containerFactory = "kafkaListenerContainerFactoryDlt")
  public void handlingDeadLetter(
      String value,
      @Header(KafkaHeaders.RECEIVED_KEY) String key,
      @Header(KafkaHeaders.RECEIVED_TIMESTAMP) Long receiveTimestamp,
      @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
      @Header(KafkaHeaders.EXCEPTION_STACKTRACE) String stackTrace,
      @Header(KafkaHeaders.ORIGINAL_CONSUMER_GROUP) String originalConsumerGroup,
      @Header(KafkaHeaders.EXCEPTION_FQCN) String exceptionFqcn,
      @Header(KafkaHeaders.EXCEPTION_CAUSE_FQCN) String exceptionCauseFqcn,
      @Header(KafkaHeaders.EXCEPTION_MESSAGE) String exceptionMessage) {
    try {
      Timestamp sqlTimestamp = new Timestamp(receiveTimestamp);

      DeadLetterLog log =
          DeadLetterLog.builder()
              .originTopic(topic)
              .payload(value)
              .payloadKey(key)
              .originalConsumerGroup(originalConsumerGroup)
              .exceptionStackTrace(stackTrace)
              .exceptionFqcn(exceptionFqcn)
              .exceptionCauseFqcn(exceptionCauseFqcn)
              .exceptionMessage(exceptionMessage)
              .receivedAt(sqlTimestamp)
              .build();

      deadLetterLogRepository.save(log);
    } catch (Exception e) {
      logger.error(e.getMessage(), e);
    }
  }
}
