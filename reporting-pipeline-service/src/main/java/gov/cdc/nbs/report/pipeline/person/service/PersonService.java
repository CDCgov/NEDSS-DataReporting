package gov.cdc.nbs.report.pipeline.person.service;

import static gov.cdc.nbs.report.pipeline.util.UtilHelper.errorMessage;
import static gov.cdc.nbs.report.pipeline.util.UtilHelper.extractUid;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.nbs.report.pipeline.config.EventProcedureLoggingProperties;
import gov.cdc.nbs.report.pipeline.person.model.dto.patient.PatientReporting;
import gov.cdc.nbs.report.pipeline.person.model.dto.patient.PatientSp;
import gov.cdc.nbs.report.pipeline.person.model.dto.provider.ProviderReporting;
import gov.cdc.nbs.report.pipeline.person.model.dto.provider.ProviderSp;
import gov.cdc.nbs.report.pipeline.person.model.dto.user.AuthUser;
import gov.cdc.nbs.report.pipeline.person.model.entity.NrtAuthUser;
import gov.cdc.nbs.report.pipeline.person.model.entity.NrtPatient;
import gov.cdc.nbs.report.pipeline.person.model.entity.NrtProvider;
import gov.cdc.nbs.report.pipeline.person.repository.NrtAuthUserRepository;
import gov.cdc.nbs.report.pipeline.person.repository.NrtPatientRepository;
import gov.cdc.nbs.report.pipeline.person.repository.NrtProviderRepository;
import gov.cdc.nbs.report.pipeline.person.repository.PatientRepository;
import gov.cdc.nbs.report.pipeline.person.repository.ProviderRepository;
import gov.cdc.nbs.report.pipeline.person.repository.UserRepository;
import gov.cdc.nbs.report.pipeline.person.transformer.PersonTransformers;
import gov.cdc.nbs.report.pipeline.person.transformer.PersonType;
import gov.cdc.nbs.report.pipeline.util.DataProcessingException;
import gov.cdc.nbs.report.pipeline.util.NoDataException;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.Counter;
import jakarta.annotation.PostConstruct;
import jakarta.persistence.EntityNotFoundException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.listener.BatchListenerFailedException;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
  private final EventProcedureLoggingProperties eventProcedureLoggingProperties;
  private final NrtPatientRepository nrtPatientRepository;
  private final NrtProviderRepository nrtProviderRepository;
  private final NrtAuthUserRepository nrtAuthUserRepository;

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

  @Value("${featureFlag.phc-datamart-enable}")
  private boolean phcDatamartEnable;

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

  /**
   * Processes a batch of person change events, partitioned by record type ({@code PAT} / {@code
   * PRV}) and grouped for bulk lookup and transformation.
   *
   * <p>On failure, throws {@link BatchListenerFailedException} identifying the index of the first
   * unprocessed record in {@code kafkaMessages}. The container uses this index to commit offsets
   * for records that completed successfully and to redeliver only the failed record and those after
   * it, rather than the entire batch.
   *
   * @param kafkaMessages raw message values for the polled batch, in delivery order
   * @throws BatchListenerFailedException identifying the first record that failed to process
   */
  public void processPersonMessages(List<String> kafkaMessages) {
    msgProcessed.increment(kafkaMessages.size());
    metrics.recordTime(
        "person_msg_processing_seconds",
        () -> {
          // group messages based on patient cd value
          Map<String, List<Integer>> indicesByCd = groupIndicesByCd(kafkaMessages);
          List<Integer> patIndices = indicesByCd.getOrDefault("PAT", List.of());
          List<Integer> prvIndices = indicesByCd.getOrDefault("PRV", List.of());

          boolean patientsProcessed = false;
          try {
            processPatientMessages(valuesAt(kafkaMessages, patIndices));
            patientsProcessed = true;

            processProviderMessages(valuesAt(kafkaMessages, prvIndices));

            msgSuccess.increment(kafkaMessages.size());
          } catch (EntityNotFoundException ex) {
            msgFailure.increment();
            throw new BatchListenerFailedException(
                ex.getMessage(),
                new NoDataException(ex.getMessage(), ex),
                firstFailedIndex(patientsProcessed, patIndices, prvIndices));
          } catch (Exception e) {
            msgFailure.increment();
            String message = errorMessage("Person", "", e);
            throw new BatchListenerFailedException(
                message,
                new DataProcessingException(message, e),
                firstFailedIndex(patientsProcessed, patIndices, prvIndices));
          }
        },
        "service",
        SERVICE_NAME);
  }

  /**
   * Partitions message indices by their {@code cd} field, preserving each message's position in the
   * original batch.
   *
   * @param messages raw message values for the polled batch
   * @return batch indices grouped by {@code cd} value
   * @throws BatchListenerFailedException identifying the index of the first message that could not
   *     be parsed
   */
  private Map<String, List<Integer>> groupIndicesByCd(List<String> messages) {
    Map<String, List<Integer>> indicesByCd = new LinkedHashMap<>();
    for (int i = 0; i < messages.size(); i++) {
      final String cd;
      try {
        cd = parsePersonCd(messages.get(i));
      } catch (RuntimeException e) {
        msgFailure.increment();
        throw new BatchListenerFailedException(
            "Failed to parse 'cd' from person message",
            new NoDataException("Failed to parse 'cd' from person message", e),
            i);
      }
      indicesByCd.computeIfAbsent(cd, k -> new ArrayList<>()).add(i);
    }
    return indicesByCd;
  }

  /**
   * Resolves the given batch indices to their corresponding message values.
   *
   * @param messages raw message values for the polled batch
   * @param indices batch indices to resolve
   * @return message values at the given indices, in order
   */
  private static List<String> valuesAt(List<String> messages, List<Integer> indices) {
    return indices.stream().map(messages::get).toList();
  }

  /**
   * Determines the batch index to report on failure, based on which processing stage failed.
   *
   * @param patientsProcessed whether patient processing completed successfully
   * @param patIndices batch indices for patient records
   * @param prvIndices batch indices for provider records
   * @return index of the first record belonging to the failed stage
   */
  private static int firstFailedIndex(
      boolean patientsProcessed, List<Integer> patIndices, List<Integer> prvIndices) {
    if (!patientsProcessed) {
      return patIndices.isEmpty() ? 0 : patIndices.get(0);
    }
    return prvIndices.isEmpty() ? 0 : prvIndices.get(0);
  }

  private void processPatientMessages(List<String> messages) {
    if (messages == null || messages.isEmpty()) {
      return;
    }
    String idList =
        messages.stream().map(this::parsePersonUid).distinct().collect(Collectors.joining(","));
    List<PatientSp> patientData =
        patientRepository.computePatients(
            idList, eventProcedureLoggingProperties.eventProcedureDebugLogging());

    if (patientData.isEmpty()) {
      throw new EntityNotFoundException("Unable to find Person with ids: " + idList);
    }

    if (phcDatamartEnable) {
      final String mprUids =
          patientData.stream()
              .filter(p -> p.getPersonUid().equals(p.getPersonParentUid()))
              .map(PatientSp::getPersonUid)
              .map(String::valueOf)
              .collect(Collectors.joining(","));
      CompletableFuture.runAsync(() -> processPhcFactDatamart("PAT", mprUids), rtrExecutor);
    }

    // transform PatientSp to PatientReporting format
    List<PatientReporting> reportingPatients =
        patientData.stream()
            .map(
                p ->
                    (PatientReporting)
                        transformer.processData(p, null, PersonType.PATIENT_REPORTING))
            .toList();

    // transform PatientReporting to NrtPatient format and persist
    List<NrtPatient> nrtPatients = reportingPatients.stream().map(NrtPatient::from).toList();
    nrtPatientRepository.saveAll(nrtPatients);

    // post messages to Kafka topic
    sendPersonKafkaMessages(reportingPatients);
  }

  private void sendPersonKafkaMessages(List<PatientReporting> reportingPatients) {
    for (PatientReporting patient : reportingPatients) {
      String key = transformer.buildPatientKey(patient);
      String data = transformer.processData(patient);

      kafkaTemplate.send(patientReportingOutputTopic, key, data);
      log.info(
          "Patient data (uid={}) sent to {}", patient.getPatientUid(), patientReportingOutputTopic);
      log.debug("Patient Reporting: {}", data != null ? data : "");
    }
  }

  private void processProviderMessages(List<String> messages) {
    if (messages == null || messages.isEmpty()) {
      return;
    }

    String idList =
        messages.stream().map(this::parsePersonUid).distinct().collect(Collectors.joining(","));
    List<ProviderSp> providerData =
        providerRepository.computeProviders(
            idList, eventProcedureLoggingProperties.eventProcedureDebugLogging());

    if (providerData.isEmpty()) {
      throw new EntityNotFoundException("Unable to find Person with ids: " + idList);
    }

    if (phcDatamartEnable) {
      final String mprUids =
          providerData.stream()
              .filter(p -> p.getPersonUid().equals(p.getPersonParentUid()))
              .map(ProviderSp::getPersonUid)
              .map(String::valueOf)
              .distinct()
              .collect(Collectors.joining(","));
      CompletableFuture.runAsync(() -> processPhcFactDatamart("PRV", mprUids), rtrExecutor);
    }

    // transform ProviderSp to ProviderReporting
    List<ProviderReporting> reportingProviders =
        providerData.stream()
            .map(
                p ->
                    (ProviderReporting)
                        transformer.processData(null, p, PersonType.PROVIDER_REPORTING))
            .toList();

    // transform ProviderReporting to NrtProvider and persist
    List<NrtProvider> nrtProviders = reportingProviders.stream().map(NrtProvider::from).toList();
    nrtProviderRepository.saveAll(nrtProviders);

    // post messages to Kafka topic
    sendProviderKafkaMessages(reportingProviders);
  }

  private void sendProviderKafkaMessages(List<ProviderReporting> providers) {
    for (ProviderReporting provider : providers) {
      String key = transformer.buildProviderKey(provider);
      String data = transformer.processData(provider);

      kafkaTemplate.send(providerReportingOutputTopic, key, data);
      log.info(
          "Provider data (uid={}) sent to {}",
          provider.getProviderUid(),
          providerReportingOutputTopic);
      log.debug("Provider Reporting: {}", data);
    }
  }

  String parsePersonCd(String message) {
    try {
      return objectMapper.readTree(message).get("payload").path("after").get("cd").asText();
    } catch (NullPointerException | JsonProcessingException e) {
      throw new NoSuchElementException("Failed to parse 'cd' from person message", e);
    }
  }

  String parsePersonUid(String message) {
    try {
      return extractUid(message, "person_uid");
    } catch (JsonProcessingException e) {
      throw new NoSuchElementException("Failed to parse 'person_uid' from person message", e);
    }
  }

  @Transactional
  public void processUser(List<String> messages) {
    String userUids = "";
    try {
      userUids =
          messages.stream().map(this::parseAuthUserUid).distinct().collect(Collectors.joining(","));
      log.info(topicDebugLog, "User", userUids, userTopic);
      Optional<List<AuthUser>> userData =
          userRepository.computeAuthUsers(
              userUids, eventProcedureLoggingProperties.eventProcedureDebugLogging());

      List<AuthUser> authUsers;

      if (userData.isPresent() && !userData.get().isEmpty()) {
        authUsers = userData.get();
      } else {
        throw new EntityNotFoundException("Unable to find AuthUser data for id(s): " + userUids);
      }

      // transform AuthUser to NrtAuthUser and persist
      List<NrtAuthUser> nrtAuthUsers = authUsers.stream().map(NrtAuthUser::from).toList();
      nrtAuthUserRepository.saveAll(nrtAuthUsers);

      // post messages to Kafka topic
      sendAuthUserKafkaMessages(authUsers);

    } catch (EntityNotFoundException ex) {
      throw new NoDataException(ex.getMessage(), ex);
    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("User", userUids, e), e);
    }
  }

  private String parseAuthUserUid(String message) {
    try {
      return extractUid(message, "auth_user_uid");
    } catch (JsonProcessingException e) {
      throw new NoSuchElementException("Failed to parse 'person_uid' from person message", e);
    }
  }

  private void sendAuthUserKafkaMessages(List<AuthUser> authUsers) {
    for (AuthUser authUser : authUsers) {
      String jsonKey = transformer.buildUserKey(authUser);
      String jsonValue = transformer.processData(authUser);
      kafkaTemplate.send(userReportingOutputTopic, jsonKey, jsonValue);
      log.info(
          "User data (uid={}) sent to {}", authUser.getAuthUserUid(), userReportingOutputTopic);
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
