package gov.cdc.etldatapipeline.person.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import gov.cdc.etldatapipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.etldatapipeline.person.model.dto.user.AuthUser;
import gov.cdc.etldatapipeline.person.repository.PatientRepository;
import gov.cdc.etldatapipeline.person.repository.ProviderRepository;
import gov.cdc.etldatapipeline.person.repository.UserRepository;
import gov.cdc.etldatapipeline.person.transformer.PersonTransformers;
import gov.cdc.etldatapipeline.person.transformer.PersonType;
import io.micrometer.core.instrument.Counter;
import jakarta.annotation.PostConstruct;
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
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;

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

    @Value("${featureFlag.elastic-search-enable}")
    private boolean elasticSearchEnable;

    @Value("${featureFlag.phc-datamart-disable}")
    private boolean phcDatamartDisable;

    @Value("${featureFlag.thread-pool-size:1}")
    private int threadPoolSize;

    private static int nProc = Runtime.getRuntime().availableProcessors();
    private ExecutorService rtrExecutor = Executors.newFixedThreadPool(nProc*2, new CustomizableThreadFactory("rtr-"));
    private ExecutorService prsExecutor;

    private static final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
    private static String topicDebugLog = "Received {} with id: {} from topic: {}";

    private static final String SERVICE_NAME = "person-reporting";

    private final CustomMetrics metrics;

    private Counter msgProcessed;
    private Counter msgSuccess;
    private Counter msgFailure;

    @PostConstruct
    void initMetrics() {
        String[] tags = {"service", SERVICE_NAME};

        msgProcessed = metrics.counter("person_msg_processed", tags);
        msgSuccess = metrics.counter( "person_msg_success", tags);
        msgFailure = metrics.counter("person_msg_failure", tags);

        prsExecutor = Executors.newFixedThreadPool(threadPoolSize, new CustomizableThreadFactory("prs-"));
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
    public CompletableFuture<Void> processMessage(String message,
                               @Header(KafkaHeaders.RECEIVED_TOPIC) String topic) {
        if (topic.equals(personTopic)) {
            return CompletableFuture.runAsync(() -> processPerson(message, topic), prsExecutor);
        } else if (topic.equals(userTopic)) {
            return CompletableFuture.runAsync(() -> processUser(message, topic), prsExecutor);
        } else {
            return CompletableFuture.failedFuture(new DataProcessingException("Received data from an unknown topic: " + topic, new NoSuchElementException()));
        }
    }

    private void processPerson(String message, String topic) {
        msgProcessed.increment();
        metrics.recordTime("person_msg_processing_seconds", () -> {
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
                msgSuccess.increment();
            } catch (EntityNotFoundException ex) {
                msgFailure.increment();
                throw new NoDataException(ex.getMessage(), ex);
            } catch (Exception e) {
                msgFailure.increment();
                throw new DataProcessingException(errorMessage("Person", personUid, e), e);
            }
        }, "service", SERVICE_NAME);
    }

    private void processProviderData(List<ProviderSp> providerData) {
        final String uids = providerData.stream()
                .filter(p -> p.getPersonUid().equals(p.getPersonParentUid()))
                .map(ProviderSp::getPersonUid).map(String::valueOf)
                .collect(Collectors.joining(","));

        if (!phcDatamartDisable) {
            CompletableFuture.runAsync(() -> processPhcFactDatamart("PRV", uids), rtrExecutor);
        }

        providerData.forEach(provider -> {
            String reportingKey = transformer.buildProviderKey(provider);
            String reportingData = transformer.processData(provider, PersonType.PROVIDER_REPORTING);
            kafkaTemplate.send(providerReportingOutputTopic, reportingKey, reportingData);
            log.info("Provider data (uid={}) sent to {}", provider.getPersonUid(), providerReportingOutputTopic);
            log.debug("Provider Reporting: {}", reportingData);

            if (elasticSearchEnable) {
                String elasticKey = transformer.buildProviderKey(provider);
                String elasticData = transformer.processData(provider, PersonType.PROVIDER_ELASTIC_SEARCH);
                kafkaTemplate.send(providerElasticSearchOutputTopic, elasticKey, elasticData);
                log.info("Provider data (uid={}) sent to {}", provider.getPersonUid(), providerElasticSearchOutputTopic);
                log.debug("Provider Elastic: {}", elasticData != null ? elasticData : "");
            }
        });
    }

    private void processPatientData(List<PatientSp> patientData) {
        final String uids = patientData.stream()
                .filter(p -> p.getPersonUid().equals(p.getPersonParentUid()))
                .map(PatientSp::getPersonUid).map(String::valueOf)
                .collect(Collectors.joining(","));

        if (!phcDatamartDisable) {
            CompletableFuture.runAsync(() -> processPhcFactDatamart("PAT", uids), rtrExecutor);
        }

        patientData.forEach(personData -> {
            String reportingKey = transformer.buildPatientKey(personData);
            String reportingData = transformer.processData(personData, PersonType.PATIENT_REPORTING);
            kafkaTemplate.send(patientReportingOutputTopic, reportingKey, reportingData);
            log.info("Patient data (uid={}) sent to {}", personData.getPersonUid(), patientReportingOutputTopic);
            log.debug("Patient Reporting: {}", reportingData != null ? reportingData : "");

            if (elasticSearchEnable) {
                String elasticKey = transformer.buildPatientKey(personData);
                String elasticData = transformer.processData(personData, PersonType.PATIENT_ELASTIC_SEARCH);
                kafkaTemplate.send(patientElasticSearchOutputTopic, elasticKey, elasticData);
                log.info("Patient data (uid={}) sent to {}", personData.getPersonUid(), patientElasticSearchOutputTopic);
                log.debug("Patient Elastic: {}", elasticData != null ? elasticData : "");
            }
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
            throw new DataProcessingException(errorMessage("User", userUid, e), e);
        }
    }

    public void processPhcFactDatamart(String objName, String uids) {
        if (!uids.isEmpty()) {
            try {
                // Calling sp_public_health_case_fact_datamart_update
                log.info("Executing stored proc: sp_public_health_case_fact_datamart_update '{}', '{}' to update PHС fact datamart", objName, uids);
                patientRepository.updatePhcFact(objName, uids);
                log.info("Stored proc execution completed: sp_public_health_case_fact_datamart_update '{}", uids);
            } catch (Exception dbe) {
                log.warn("Error updating PHC fact datamart: {}", dbe.getMessage());
            }
        }
    }
}