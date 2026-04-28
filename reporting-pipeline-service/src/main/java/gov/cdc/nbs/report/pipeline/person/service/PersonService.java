package gov.cdc.nbs.report.pipeline.person.service;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.errorMessage;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractUid;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.nbs.report.pipeline.person.model.dto.patient.PatientSp;
import gov.cdc.nbs.report.pipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.nbs.report.pipeline.person.model.dto.user.AuthUser;
import gov.cdc.nbs.report.pipeline.person.repository.PatientRepository;
import gov.cdc.nbs.report.pipeline.person.repository.ProviderRepository;
import gov.cdc.nbs.report.pipeline.person.repository.UserRepository;
import gov.cdc.nbs.report.pipeline.person.transformer.PersonTransformers;
import gov.cdc.nbs.report.pipeline.person.transformer.PersonType;
import io.micrometer.core.instrument.Counter;
import jakarta.annotation.PostConstruct;
import jakarta.persistence.EntityNotFoundException;
import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.common.errors.SerializationException;
import org.springframework.beans.factory.annotation.Qualifier;
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

/**
 * Service class for processing Person-related change events in the Real Time Reporting (RTR)
 * pipeline. This service handles the "hydration" of data for Patients, Providers, and Auth Users by
 * consuming Kafka events from transactional source topics, transforming them, and producing them to
 * reporting topics.
 *
 * <p>Key responsibilities include:
 *
 * <ul>
 *   <li>Consuming CDC (Change Data Capture) events for Patients, Providers, and Users.
 *   <li>Fetching enriched data from the database using stored procedures.
 *   <li>Transforming raw data into reporting-optimized formats (both for ElasticSearch and NRT
 *       tables).
 *   <li>Triggering PHC (Public Health Case) datamart updates when necessary.
 *   <li>Handling retries and dead-letter topics (DLT) for resilient processing.
 * </ul>
 */
@Service
@Slf4j
@Setter
@RequiredArgsConstructor
public class PersonService {
  private final PatientRepository patientRepository;
  private final ProviderRepository providerRepository;
  private final UserRepository userRepository;
  private final PersonTransformers transformer;

  @Qualifier("personKafkaTemplate")
  private final KafkaTemplate<String, String> kafkaTemplate;

  @Value("${spring.kafka.topics.nbs.person}")
  private String personTopic;

  @Value("${spring.kafka.topics.nbs.auth-user}")
  private String userTopic;

  @Value("${spring.kafka.topics.elastic.patient}")
  private String patientElasticSearchOutputTopic;

  @Value("${spring.kafka.topics.nrt.patient}")
  private String patientReportingOutputTopic;

  @Value("${spring.kafka.topics.elastic.provider}")
  private String providerElasticSearchOutputTopic;

  @Value("${spring.kafka.topics.nrt.provider}")
  private String providerReportingOutputTopic;

  @Value("${spring.kafka.topics.nrt.auth-user}")
  private String userReportingOutputTopic;

  @Value("${featureFlag.elastic-search-enable}")
  private boolean elasticSearchEnable;

  @Value("${featureFlag.phc-datamart-enable}")
  private boolean phcDatamartEnable;

  @Value("${featureFlag.thread-pool-size:1}")
  private int threadPoolSize;

  private ExecutorService rtrExecutor;

  private static final ObjectMapper objectMapper =
      new ObjectMapper().registerModule(new JavaTimeModule());
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
    msgSuccess = metrics.counter("person_msg_success", tags);
    msgFailure = metrics.counter("person_msg_failure", tags);

    int nproc = Runtime.getRuntime().availableProcessors();
    rtrExecutor = Executors.newFixedThreadPool(nproc * 2, new CustomizableThreadFactory("rtr-"));
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
      },
      kafkaTemplate = "personKafkaTemplate")
  @KafkaListener(
      topics = {"${spring.kafka.topics.nbs.person}", "${spring.kafka.topics.nbs.auth-user}"},
      containerFactory = "personKafkaListenerContainerFactory")
  public void processMessage(String message, @Header(KafkaHeaders.RECEIVED_TOPIC) String topic) {
    if (topic.equals(personTopic)) {
      processPerson(message, topic);
    } else if (topic.equals(userTopic)) {
      processUser(message, topic);
    } else {
      throw new DataProcessingException(
          "Received data from an unknown topic: " + topic, new NoSuchElementException());
    }
  }

  private void processPerson(String message, String topic) {
    msgProcessed.increment();
    metrics.recordTime(
        "person_msg_processing_seconds",
        () -> {
          String personUid = "";
          try {
            JsonNode jsonNode = objectMapper.readTree(message);
            JsonNode payloadNode = jsonNode.get("payload").path("after");

            personUid = extractUid(message, "person_uid");
            log.info(topicDebugLog, "Person", personUid, topic);

            List<ProviderSp> providerDataFromStoredProc = new ArrayList<>();
            List<PatientSp> personDataFromStoredProc = new ArrayList<>();

            String cd = payloadNode.get("cd").asText();
            switch (cd) {
              case "PAT":
                personDataFromStoredProc = patientRepository.computePatients(personUid);
                processPatientData(personDataFromStoredProc);
                break;
              case "PRV":
                providerDataFromStoredProc = providerRepository.computeProviders(personUid);
                processProviderData(providerDataFromStoredProc);
                break;
              default:
                throw new IllegalArgumentException(
                    "No data to process for this entity type: " + cd);
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
        },
        "service",
        SERVICE_NAME);
  }

  private void processProviderData(List<ProviderSp> providerData) {
    final String uids =
        providerData.stream()
            .filter(p -> p.getPersonUid().equals(p.getPersonParentUid()))
            .map(ProviderSp::getPersonUid)
            .map(String::valueOf)
            .collect(Collectors.joining(","));

    if (phcDatamartEnable) {
      CompletableFuture.runAsync(() -> processPhcFactDatamart("PRV", uids), rtrExecutor);
    }

    providerData.forEach(
        provider -> {
          String reportingKey = transformer.buildProviderKey(provider);
          String reportingData = transformer.processData(provider, PersonType.PROVIDER_REPORTING);
          kafkaTemplate.send(providerReportingOutputTopic, reportingKey, reportingData);
          log.info(
              "Provider data (uid={}) sent to {}",
              provider.getPersonUid(),
              providerReportingOutputTopic);
          log.debug("Provider Reporting: {}", reportingData);

          if (elasticSearchEnable) {
            String elasticKey = transformer.buildProviderKey(provider);
            String elasticData =
                transformer.processData(provider, PersonType.PROVIDER_ELASTIC_SEARCH);
            kafkaTemplate.send(providerElasticSearchOutputTopic, elasticKey, elasticData);
            log.info(
                "Provider data (uid={}) sent to {}",
                provider.getPersonUid(),
                providerElasticSearchOutputTopic);
            log.debug("Provider Elastic: {}", elasticData != null ? elasticData : "");
          }
        });
  }

  private void processPatientData(List<PatientSp> patientData) {
    final String uids =
        patientData.stream()
            .filter(p -> p.getPersonUid().equals(p.getPersonParentUid()))
            .map(PatientSp::getPersonUid)
            .map(String::valueOf)
            .collect(Collectors.joining(","));

    if (phcDatamartEnable) {
      CompletableFuture.runAsync(() -> processPhcFactDatamart("PAT", uids), rtrExecutor);
    }

    patientData.forEach(
        personData -> {
          String reportingKey = transformer.buildPatientKey(personData);
          String reportingData = transformer.processData(personData, PersonType.PATIENT_REPORTING);
          kafkaTemplate.send(patientReportingOutputTopic, reportingKey, reportingData);
          log.info(
              "Patient data (uid={}) sent to {}",
              personData.getPersonUid(),
              patientReportingOutputTopic);
          log.debug("Patient Reporting: {}", reportingData != null ? reportingData : "");

          if (elasticSearchEnable) {
            String elasticKey = transformer.buildPatientKey(personData);
            String elasticData =
                transformer.processData(personData, PersonType.PATIENT_ELASTIC_SEARCH);
            kafkaTemplate.send(patientElasticSearchOutputTopic, elasticKey, elasticData);
            log.info(
                "Patient data (uid={}) sent to {}",
                personData.getPersonUid(),
                patientElasticSearchOutputTopic);
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
        userData
            .get()
            .forEach(
                authUser -> {
                  String jsonKey = transformer.buildUserKey(authUser);
                  String jsonValue = transformer.processData(authUser);
                  kafkaTemplate.send(userReportingOutputTopic, jsonKey, jsonValue);
                  log.info(
                      "User data (uid={}) sent to {}",
                      authUser.getAuthUserUid(),
                      userReportingOutputTopic);
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
        log.info(
            "Executing stored proc: sp_public_health_case_fact_datamart_update '{}', '{}' to update"
                + " PHС fact datamart",
            objName,
            uids);
        patientRepository.updatePhcFact(objName, uids);
        log.info(
            "Stored proc execution completed: sp_public_health_case_fact_datamart_update '{}",
            uids);
      } catch (Exception dbe) {
        log.warn("Error updating PHC fact datamart: {}", dbe.getMessage());
      }
    }
  }
}
