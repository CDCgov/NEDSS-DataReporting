package gov.cdc.etldatapipeline.person.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.etldatapipeline.person.repository.PatientRepository;
import gov.cdc.etldatapipeline.person.repository.ProviderRepository;
import gov.cdc.etldatapipeline.person.transformer.PersonTransformers;
import gov.cdc.etldatapipeline.person.transformer.PersonType;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.common.errors.SerializationException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.retrytopic.DltStrategy;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.retry.annotation.Backoff;
import org.springframework.stereotype.Service;

import java.util.List;


@Service
@Setter
@Slf4j
public class PersonService {
    private final PatientRepository patientRepository;
    private final ProviderRepository providerRepository;
    private final PersonTransformers transformer;

    private final KafkaTemplate<String, String> kafkaTemplate;

    @Value("${spring.kafka.input.topic-name}")
    private String personTopicName;

    @Value("${spring.kafka.output.patientElastic.topic-name}")
    private String patientElasticSearchTopicName;

    @Value("${spring.kafka.output.patientReporting.topic-name}")
    private String patientReportingOutputTopic;

    @Value("${spring.kafka.output.providerElastic.topic-name}")
    private String providerElasticSearchOutputTopic;

    @Value("${spring.kafka.output.providerReporting.topic-name}")
    private String providerReportingOutputTopic;

    public PersonService(PatientRepository patientRepository, ProviderRepository providerRepository, PersonTransformers transformer, KafkaTemplate<String, String> kafkaTemplate) {
        this.patientRepository = patientRepository;
        this.providerRepository = providerRepository;
        this.transformer = transformer;
        this.kafkaTemplate = kafkaTemplate;
    }

    @RetryableTopic(
            attempts = "${spring.kafka.consumer.max-retry}",
            autoCreateTopics = "false",
            dltStrategy = DltStrategy.FAIL_ON_ERROR,
            retryTopicSuffix = "${spring.kafka.dlq.retry-suffix}",
            dltTopicSuffix = "${spring.kafka.dlq.dlq-suffix}",
            // retry topic name, such as topic-retry-1, topic-retry-2, etc
            topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
            // time to wait before attempting to retry
            backoff = @Backoff(delay = 1000, multiplier = 2.0),
            exclude = {
                    SerializationException.class,
                    DeserializationException.class,
                    RuntimeException.class
            }
    )
    @KafkaListener(
            topics = "${spring.kafka.input.topic-name}"
    )
    public void processMessage(String message,
                               @Header(KafkaHeaders.RECEIVED_TOPIC) String topic) {

        try {
            ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
            JsonNode jsonNode = objectMapper.readTree(message);
            JsonNode payloadNode = jsonNode.get("payload").path("after");
            if (payloadNode != null && payloadNode.has("person_uid")) {
                String personUid = payloadNode.get("person_uid").asText();
                String cd = payloadNode.get("cd").asText();
                log.info("Received PersonUid: {} from topic: {}", personUid, topic);
                List<PatientSp> personDataFromStoredProc = patientRepository.computePatients(personUid);

                personDataFromStoredProc.forEach(personData -> {
                    String reportingKey = transformer.buildPatientKey(personData);
                    String reportingData = transformer.processData(personData, PersonType.PATIENT_REPORTING);
                    kafkaTemplate.send(patientReportingOutputTopic, reportingKey, reportingData);
                    log.info("Patient Reporting: {}", reportingData != null ? reportingData.toString() : "");

                    String elasticKey = transformer.buildPatientKey(personData);
                    String elasticData = transformer.processData(personData, PersonType.PATIENT_ELASTIC_SEARCH);
                    kafkaTemplate.send(patientElasticSearchTopicName, elasticKey, elasticData);
                    log.info("Patient Elastic: {}", elasticData != null ? elasticData.toString() : "");
                });

                if (cd != null && cd.equalsIgnoreCase("PRV")) {
                    List<ProviderSp> providerDataFromStoredProc = providerRepository.computeProviders(personUid);

                    providerDataFromStoredProc.forEach(provider -> {
                        String reportingKey = transformer.buildProviderKey(provider);
                        String reportingData = transformer.processData(provider, PersonType.PROVIDER_REPORTING);
                        kafkaTemplate.send(providerReportingOutputTopic, reportingKey, reportingData);
                        log.info("Provider Reporting: {}", reportingData.toString());

                        String elasticKey = transformer.buildProviderKey(provider);
                        String elasticData = transformer.processData(provider, PersonType.PROVIDER_ELASTIC_SEARCH);
                        kafkaTemplate.send(providerElasticSearchOutputTopic, elasticKey, elasticData);
                        log.info("Provider Elastic: {}", elasticData != null ? elasticData.toString() : "");
                    });
                } else {
                    log.debug("There is no provider to process in the incoming data.");
                }
            } else {
                log.debug("Incoming data doesn't contain payload: {}", message);
            }
        } catch (Exception e) {
            log.error("Error processing person message: {}", e.getMessage());
            throw new RuntimeException(e);
        }
    }
}