package gov.cdc.etldatapipeline.person.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.etldatapipeline.person.model.dto.user.AuthUser;
import gov.cdc.etldatapipeline.person.repository.PatientRepository;
import gov.cdc.etldatapipeline.person.repository.ProviderRepository;
import gov.cdc.etldatapipeline.person.repository.UserRepository;
import gov.cdc.etldatapipeline.person.transformer.PersonTransformers;
import gov.cdc.etldatapipeline.person.transformer.PersonType;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
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

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.errorMessage;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractUid;

@Service
@Slf4j
@Setter
@RequiredArgsConstructor
public class PersonService {
    private final PatientRepository patientRepository;
    private final ProviderRepository providerRepository;
    private final UserRepository userRepository;
    private final PersonTransformers transformer;

    private final KafkaTemplate<String, String> kafkaTemplate;

    @Value("${spring.kafka.input.topic-name}")
    private String personTopic;

    @Value("${spring.kafka.input.topic-name-user}")
    private String userTopic;

    @Value("${spring.kafka.output.patientElastic.topic-name}")
    private String patientElasticSearchOutputTopic;

    @Value("${spring.kafka.output.patientReporting.topic-name}")
    private String patientReportingOutputTopic;

    @Value("${spring.kafka.output.providerElastic.topic-name}")
    private String providerElasticSearchOutputTopic;

    @Value("${spring.kafka.output.providerReporting.topic-name}")
    private String providerReportingOutputTopic;

    @Value("${spring.kafka.output.userReporting.topic-name}")
    private String userReportingOutputTopic;

    private static final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
    private static String topicDebugLog = "Received {} with id: {} from topic: {}";

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
                    RuntimeException.class,
                    NoDataException.class
            }
    )
    @KafkaListener(
            topics = {
                    "${spring.kafka.input.topic-name}",
                    "${spring.kafka.input.topic-name-user}"
            }
    )
    public void processMessage(String message,
                               @Header(KafkaHeaders.RECEIVED_TOPIC) String topic) {
        if (topic.equals(personTopic)) {
            processPerson(message, topic);
        } else if (topic.equals(userTopic)) {
            processUser(message, topic);
        }
    }

    private void processPerson(String message, String topic) {
        String personUid = "";
        try {
            JsonNode jsonNode = objectMapper.readTree(message);
            JsonNode payloadNode = jsonNode.get("payload").path("after");

            personUid = extractUid(message, "person_uid");
            log.info(topicDebugLog, "Person", personUid, topic);
            List<PatientSp> personDataFromStoredProc = patientRepository.computePatients(personUid);
            processPatientData(personDataFromStoredProc);

            String cd = payloadNode.get("cd").asText();
            List<ProviderSp> providerDataFromStoredProc = new ArrayList<>();
            if (cd != null && cd.equalsIgnoreCase("PRV")) {
                providerDataFromStoredProc = providerRepository.computeProviders(personUid);

                processProviderData(providerDataFromStoredProc);
            } else {
                log.debug("There is no provider to process in the incoming data.");
            }

            if (personDataFromStoredProc.isEmpty() && providerDataFromStoredProc.isEmpty()) {
                throw new EntityNotFoundException("Unable to find Person with id: " + personUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new RuntimeException(errorMessage("Person", personUid, e), e);
        }
    }

    private void processProviderData(List<ProviderSp> providerDataFromStoredProc) {
        providerDataFromStoredProc.forEach(provider -> {
            String reportingKey = transformer.buildProviderKey(provider);
            String reportingData = transformer.processData(provider, PersonType.PROVIDER_REPORTING);
            kafkaTemplate.send(providerReportingOutputTopic, reportingKey, reportingData);
            log.info("Provider data (uid={}) sent to {}", provider.getPersonUid(), providerReportingOutputTopic);
            log.debug("Provider Reporting: {}", reportingData);

            String elasticKey = transformer.buildProviderKey(provider);
            String elasticData = transformer.processData(provider, PersonType.PROVIDER_ELASTIC_SEARCH);
            kafkaTemplate.send(providerElasticSearchOutputTopic, elasticKey, elasticData);
            log.info("Provider data (uid={}) sent to {}", provider.getPersonUid(), providerElasticSearchOutputTopic);
            log.debug("Provider Elastic: {}", elasticData != null ? elasticData : "");
        });
    }

    private void processPatientData(List<PatientSp> personDataFromStoredProc) {
        personDataFromStoredProc.forEach(personData -> {
            String reportingKey = transformer.buildPatientKey(personData);
            String reportingData = transformer.processData(personData, PersonType.PATIENT_REPORTING);
            kafkaTemplate.send(patientReportingOutputTopic, reportingKey, reportingData);
            log.info("Patient data (uid={}) sent to {}", personData.getPersonUid(), patientReportingOutputTopic);
            log.debug("Patient Reporting: {}", reportingData != null ? reportingData : "");

            String elasticKey = transformer.buildPatientKey(personData);
            String elasticData = transformer.processData(personData, PersonType.PATIENT_ELASTIC_SEARCH);
            kafkaTemplate.send(patientElasticSearchOutputTopic, elasticKey, elasticData);
            log.info("Patient data (uid={}) sent to {}", personData.getPersonUid(), patientElasticSearchOutputTopic);
            log.debug("Patient Elastic: {}", elasticData != null ? elasticData : "");
        });
    }

    private void processUser(String message, String topic) {
        String userUid = "";
        try {
            userUid = extractUid(message, "auth_user_uid");
            log.info(topicDebugLog, "User", userUid, topic);
            Optional<List<AuthUser>> userData = userRepository.computeAuthUsers(userUid);

            if (userData.isPresent() && !userData.get().isEmpty()) {
                userData.get().forEach(authUser -> {
                    String jsonKey = transformer.buildUserKey(authUser);
                    String jsonValue = transformer.processData(authUser);
                    kafkaTemplate.send(userReportingOutputTopic, jsonKey, jsonValue);
                    log.info("User data (uid={}) sent to {}", authUser.getAuthUserUid(), userReportingOutputTopic);
                });
            } else {
                throw new EntityNotFoundException("Unable to find AuthUser data for id(s): " + userUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            String msg = "Error processing User data" +
                    (!userUid.isEmpty() ? " with ids '" + userUid + "': " : ": " + e.getMessage());
            throw new RuntimeException(msg, e);
        }
    }
}