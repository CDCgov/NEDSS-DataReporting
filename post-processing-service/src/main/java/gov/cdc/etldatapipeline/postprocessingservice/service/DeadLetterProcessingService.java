package gov.cdc.etldatapipeline.postprocessingservice.service;

import gov.cdc.etldatapipeline.postprocessingservice.repository.DeadLetterLogRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DeadLetterLog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;

@SuppressWarnings("java:S107")
@Service
public class DeadLetterProcessingService {
    private static final Logger logger = LoggerFactory.getLogger(DeadLetterProcessingService.class);
    private final DeadLetterLogRepository deadLetterLogRepository;

    public DeadLetterProcessingService(DeadLetterLogRepository deadLetterLogRepository) {
        this.deadLetterLogRepository = deadLetterLogRepository;
    }

    @KafkaListener(topics = {
            "${spring.kafka.topic.investigation}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.observation}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.organization}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.patient}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.provider}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.notification}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.treatment}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.case_management}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.interview}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.ldf_data}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.place}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.auth_user}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.contact_record}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.vaccination}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.page}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.datamart}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.state_defined_field_metadata}${spring.kafka.dlq.dlq-suffix}",
            "${spring.kafka.topic.condition}${spring.kafka.dlq.dlq-suffix}",

            // investigation-topic
            "${spring.kafka.investigation-topic.topic-name-phc}${spring.kafka.dlq.dlq-suffix-format-2}",
            "${spring.kafka.investigation-topic.topic-name-ntf}${spring.kafka.dlq.dlq-suffix-format-2}",
            "${spring.kafka.investigation-topic.topic-name-int}${spring.kafka.dlq.dlq-suffix-format-2}",
            "${spring.kafka.investigation-topic.topic-name-ctr}${spring.kafka.dlq.dlq-suffix-format-2}",
            "${spring.kafka.investigation-topic.topic-name-vac}${spring.kafka.dlq.dlq-suffix-format-2}",
            "${spring.kafka.investigation-topic.topic-name-tmt}${spring.kafka.dlq.dlq-suffix-format-2}",
            "${spring.kafka.investigation-topic.topic-name-ar}${spring.kafka.dlq.dlq-suffix-format-2}",

            // ldf-topic
            "${spring.kafka.ldf-topic.topic-name}${spring.kafka.dlq.dlq-suffix-format-2}",

            // observation-topic
            "${spring.kafka.observation-topic.topic-name}${spring.kafka.dlq.dlq-suffix-format-2}",
            "${spring.kafka.observation-topic.topic-name-ar}${spring.kafka.dlq.dlq-suffix-format-2}",

            // organization-topic
            "${spring.kafka.organization-topic.topic-name}${spring.kafka.dlq.dlq-suffix-format-2}",
            "${spring.kafka.organization-topic.topic-name-place}${spring.kafka.dlq.dlq-suffix-format-2}",

            // person-topic
            "${spring.kafka.person-topic.topic-name}${spring.kafka.dlq.dlq-suffix-format-2}",
            "${spring.kafka.person-topic.topic-name-user}${spring.kafka.dlq.dlq-suffix-format-2}"
    },
            containerFactory = "kafkaListenerContainerFactoryDlt")
    public void handlingDeadLetter(String value,
                                   @Header(KafkaHeaders.RECEIVED_KEY) String key,
                                   @Header(KafkaHeaders.RECEIVED_TIMESTAMP) Long  receiveTimestamp,
                                   @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
                                   @Header(KafkaHeaders.EXCEPTION_STACKTRACE) String stackTrace,
                                   @Header(KafkaHeaders.ORIGINAL_CONSUMER_GROUP) String originalConsumerGroup,
                                   @Header(KafkaHeaders.EXCEPTION_FQCN) String exceptionFqcn,
                                   @Header(KafkaHeaders.EXCEPTION_CAUSE_FQCN) String exceptionCauseFqcn,
                                   @Header(KafkaHeaders.EXCEPTION_MESSAGE) String exceptionMessage) {
        try {
            Timestamp sqlTimestamp = new Timestamp(receiveTimestamp);

            DeadLetterLog log = DeadLetterLog.builder()
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
