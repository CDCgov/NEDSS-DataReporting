package gov.cdc.nbs.report.pipeline.investigation.service;

import static gov.cdc.nbs.report.pipeline.investigation.service.InvestigationService.toBatchId;
import static gov.cdc.nbs.report.pipeline.investigation.utils.TestUtils.*;
import static gov.cdc.nbs.report.pipeline.util.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.ArgumentMatchers.notNull;
import static org.mockito.Mockito.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.nbs.report.pipeline.investigation.repository.*;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.dto.*;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.reporting.*;
import gov.cdc.nbs.report.pipeline.investigation.util.ProcessInvestigationDataUtil;
import gov.cdc.nbs.report.pipeline.util.DataProcessingException;
import gov.cdc.nbs.report.pipeline.util.NoDataException;
import gov.cdc.nbs.report.pipeline.util.kafka.RetryTopicResolver;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.concurrent.*;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.*;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.kafka.support.SendResult;

class InvestigationServiceTest {

  @InjectMocks private InvestigationService investigationService;

  @Mock private InvestigationRepository investigationRepository;

  @Mock private NotificationRepository notificationRepository;

  @Mock private InterviewRepository interviewRepository;

  @Mock private ContactRepository contactRepository;

  @Mock private TreatmentRepository treatmentRepository;

  @Mock private VaccinationRepository vaccinationRepository;

  @Mock KafkaTemplate<String, String> kafkaTemplate;

  @Captor private ArgumentCaptor<String> topicCaptor;

  @Captor private ArgumentCaptor<String> keyCaptor;

  @Captor private ArgumentCaptor<String> messageCaptor;

  private AutoCloseable closeable;

  private final ObjectMapper objectMapper = new ObjectMapper();

  // input topics
  private final String investigationTopic = "Investigation";
  private final String notificationTopic = "Notification";
  private final String interviewTopic = "Interview";
  private final String contactTopic = "Contact";
  private final String vaccinationTopic = "Vaccination";
  private final String treatmentTopic = "Treatment";

  // output topics
  private final String investigationTopicOutput = "InvestigationOutput";
  private final String notificationTopicOutput = "investigationNotification";
  private final String interviewTopicOutput = "InterviewOutput";
  private final String contactTopicOutput = "ContactOutput";
  private final String vaccinationTopicOutput = "VaccinationOutput";
  private final String treatmentTopicOutput = "TreatmentOutput";

  @BeforeEach
  void setUp() {
    closeable = MockitoAnnotations.openMocks(this);
    ProcessInvestigationDataUtil transformer =
        new ProcessInvestigationDataUtil(kafkaTemplate, investigationRepository);

    investigationService =
        new InvestigationService(
            investigationRepository,
            notificationRepository,
            interviewRepository,
            contactRepository,
            vaccinationRepository,
            treatmentRepository,
            kafkaTemplate,
            transformer,
            new RetryTopicResolver(),
            new CustomMetrics(new SimpleMeterRegistry()));

    investigationService.setInvestigationTopic(investigationTopic);
    investigationService.setNotificationTopic(notificationTopic);
    investigationService.setInvestigationTopicReporting(investigationTopicOutput);
    investigationService.setInterviewTopic(interviewTopic);
    investigationService.setContactTopic(contactTopic);
    investigationService.setVaccinationTopic(vaccinationTopic);
    investigationService.setTreatmentTopic(treatmentTopic);
    investigationService.setTreatmentOutputTopicName(treatmentTopicOutput);
    investigationService.setPhcDatamartEnable(true);
    investigationService.setThreadPoolSize(1);
    investigationService.initMetrics();

    transformer.setInvestigationConfirmationOutputTopicName("investigationConfirmation");
    transformer.setInvestigationObservationOutputTopicName("investigationObservation");
    transformer.setInvestigationNotificationsOutputTopicName(notificationTopicOutput);
    transformer.setInterviewOutputTopicName(interviewTopicOutput);
    transformer.setContactOutputTopicName(contactTopicOutput);
    transformer.setContactAnswerOutputTopicName("ContactAnswerOutput");
    transformer.setPageCaseAnswerOutputTopicName("pageCaseAnswer");
    transformer.setInvestigationCaseManagementTopicName("investigationCaseManagement");
    transformer.setInterviewAnswerOutputTopicName("interviewAnswer");
    transformer.setInterviewNoteOutputTopicName("interviewNote");
    transformer.setRdbMetadataColumnsOutputTopicName("metadataColumns");
    transformer.setVaccinationOutputTopicName(vaccinationTopicOutput);
    transformer.setVaccinationAnswerOutputTopicName("VaccinationAnswerOutput");
  }

  @AfterEach
  void tearDown() throws Exception {
    closeable.close();
  }

  @Test
  void testProcessInvestigationMessage() throws JsonProcessingException {
    Long investigationUid = 234567890L;
    String payload =
        "{\"payload\": {\"after\": {\"public_health_case_uid\": \""
            + investigationUid
            + "\", \"prog_area_cd\": \"BMIRD\"}}}";

    final Investigation investigation = constructInvestigation(investigationUid);
    when(investigationRepository.computeInvestigations(String.valueOf(investigationUid)))
        .thenReturn(Optional.of(investigation));
    when(kafkaTemplate.send(anyString(), anyString(), isNull()))
        .thenReturn(CompletableFuture.completedFuture(null));
    when(kafkaTemplate.send(anyString(), anyString(), notNull()))
        .thenReturn(CompletableFuture.completedFuture(null));
    validateInvestigationData(payload, investigation);

    verify(investigationRepository).computeInvestigations(String.valueOf(investigationUid));
    verify(investigationRepository).populatePhcFact(String.valueOf(investigationUid));
  }

  @Test
  void testProcessInvestigationPhcFactDisabled() {
    Long investigationUid = 234567890L;
    String payload =
        "{\"payload\": {\"after\": {\"public_health_case_uid\": \""
            + investigationUid
            + "\", \"prog_area_cd\": \"BMIRD\"}}}";

    final Investigation investigation = constructInvestigation(investigationUid);
    when(investigationRepository.computeInvestigations(String.valueOf(investigationUid)))
        .thenReturn(Optional.of(investigation));
    when(kafkaTemplate.send(anyString(), anyString(), isNull()))
        .thenReturn(CompletableFuture.completedFuture(null));
    when(kafkaTemplate.send(anyString(), anyString(), notNull()))
        .thenReturn(CompletableFuture.completedFuture(null));

    investigationService.setPhcDatamartEnable(false);
    ConsumerRecord<String, String> rec = getRecord(investigationTopic, payload);
    investigationService.processMessage(rec);
    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(investigationRepository, never())
                    .populatePhcFact(String.valueOf(investigationUid)));
  }

  @ParameterizedTest
  @ValueSource(
      strings = {
        investigationTopic,
        notificationTopic,
        interviewTopic,
        contactTopic,
        vaccinationTopic
      })
  void testProcessMessageException(String topic) {
    String invalidPayload = "{\"payload\": {\"after\": }}";
    checkException(topic, invalidPayload, DataProcessingException.class);
  }

  @ParameterizedTest
  @ValueSource(strings = {"Investigation_retry-0", "Investigation_retry-1"})
  void testProcessInvestigationRetryMessage(String retryTopic) {
    String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"1\"}}}";
    when(investigationRepository.computeInvestigations("1")).thenReturn(Optional.empty());
    investigationService.setPhcDatamartEnable(false);

    CompletableFuture<Void> future =
        investigationService.processMessage(retryRecord(retryTopic, investigationTopic, payload));

    assertThrows(CompletionException.class, future::join);
    verify(investigationRepository).computeInvestigations("1");
  }

  @ParameterizedTest
  @ValueSource(strings = {"Notification_retry-0", "Notification_retry-1"})
  void testProcessNotificationRetryMessage(String retryTopic) {
    String payload = "{\"payload\": {\"after\": {\"notification_uid\": \"2\"}}}";
    when(notificationRepository.computeNotifications("2")).thenReturn(Optional.empty());
    investigationService.setPhcDatamartEnable(false);

    CompletableFuture<Void> future =
        investigationService.processMessage(retryRecord(retryTopic, notificationTopic, payload));

    assertThrows(CompletionException.class, future::join);
    verify(notificationRepository).computeNotifications("2");
  }

  @ParameterizedTest
  @ValueSource(strings = {"Interview_retry-0", "Interview_retry-1"})
  void testProcessInterviewRetryMessage(String retryTopic) {
    String payload = "{\"payload\": {\"after\": {\"interview_uid\": \"3\"}}}";
    when(interviewRepository.computeInterviews("3")).thenReturn(Optional.empty());

    CompletableFuture<Void> future =
        investigationService.processMessage(retryRecord(retryTopic, interviewTopic, payload));

    assertThrows(CompletionException.class, future::join);
    verify(interviewRepository).computeInterviews("3");
  }

  @ParameterizedTest
  @ValueSource(strings = {"Contact_retry-0", "Contact_retry-1"})
  void testProcessContactRetryMessage(String retryTopic) {
    String payload = "{\"payload\": {\"after\": {\"ct_contact_uid\": \"4\"}}}";
    when(contactRepository.computeContact("4")).thenReturn(Optional.empty());

    CompletableFuture<Void> future =
        investigationService.processMessage(retryRecord(retryTopic, contactTopic, payload));

    assertThrows(CompletionException.class, future::join);
    verify(contactRepository).computeContact("4");
  }

  @ParameterizedTest
  @ValueSource(strings = {"Vaccination_retry-0", "Vaccination_retry-1"})
  void testProcessVaccinationRetryMessage(String retryTopic) {
    String payload = "{\"payload\": {\"after\": {\"intervention_uid\": \"5\"}, \"op\": \"u\"}}";
    when(vaccinationRepository.computeVaccination("5")).thenReturn(Optional.empty());

    CompletableFuture<Void> future =
        investigationService.processMessage(retryRecord(retryTopic, vaccinationTopic, payload));

    assertThrows(CompletionException.class, future::join);
    verify(vaccinationRepository).computeVaccination("5");
  }

  @ParameterizedTest
  @ValueSource(strings = {"Treatment_retry-0", "Treatment_retry-1"})
  void testProcessTreatmentRetryMessage(String retryTopic) {
    String payload = "{\"payload\": {\"after\": {\"treatment_uid\": \"6\"}, \"op\": \"u\"}}";
    when(treatmentRepository.computeTreatment("6")).thenReturn(Optional.empty());

    CompletableFuture<Void> future =
        investigationService.processMessage(retryRecord(retryTopic, treatmentTopic, payload));

    assertThrows(CompletionException.class, future::join);
    verify(treatmentRepository).computeTreatment("6");
  }

  @Test
  void testProcessMessageRejectsUnknownTopic() {
    ConsumerRecord<String, String> kafkaMessage = getRecord("unknownTopic", null);

    CompletableFuture<Void> future = investigationService.processMessage(kafkaMessage);

    CompletionException exception = assertThrows(CompletionException.class, future::join);
    assertEquals(NoSuchElementException.class, exception.getCause().getCause().getClass());
    verifyNoInteractions(
        investigationRepository,
        notificationRepository,
        interviewRepository,
        contactRepository,
        vaccinationRepository,
        treatmentRepository,
        kafkaTemplate);
  }

  @Test
  void testProcessMessageRejectsUnknownOriginalTopic() {
    ConsumerRecord<String, String> kafkaMessage =
        retryRecord("Investigation_retry-0", "unknownTopic", null);

    CompletableFuture<Void> future = investigationService.processMessage(kafkaMessage);

    CompletionException exception = assertThrows(CompletionException.class, future::join);
    assertEquals(NoSuchElementException.class, exception.getCause().getCause().getClass());
    verifyNoInteractions(
        investigationRepository,
        notificationRepository,
        interviewRepository,
        contactRepository,
        vaccinationRepository,
        treatmentRepository,
        kafkaTemplate);
  }

  @Test
  void testProcessInvestigationNoDataException() {
    Long investigationUid = 234567890L;
    String payload =
        "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\"}}}";

    when(investigationRepository.computeInvestigations(String.valueOf(investigationUid)))
        .thenReturn(Optional.empty());
    checkException(investigationTopic, payload, NoDataException.class);
  }

  @Test
  void testProcessNotificationMessage() {
    Long notificationUid = 123456789L;
    String payload =
        "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";

    final NotificationUpdate notification = constructNotificationUpdate(notificationUid);
    when(notificationRepository.computeNotifications(String.valueOf(notificationUid)))
        .thenReturn(Optional.of(notification));
    investigationService.processMessage(getRecord(notificationTopic, payload));

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () -> {
              verify(notificationRepository).computeNotifications(String.valueOf(notificationUid));
              verify(kafkaTemplate).send(topicCaptor.capture(), anyString(), anyString());
              verify(investigationRepository)
                  .updatePhcFact("NOTF", String.valueOf(notificationUid));
            });
    assertEquals(notificationTopicOutput, topicCaptor.getValue());
  }

  @Test
  void testProcessNotificationPhcFactDisabled() {
    Long notificationUid = 123456789L;
    String payload =
        "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";

    final NotificationUpdate notification = constructNotificationUpdate(notificationUid);
    when(notificationRepository.computeNotifications(String.valueOf(notificationUid)))
        .thenReturn(Optional.of(notification));
    investigationService.setPhcDatamartEnable(false);

    investigationService.processMessage(getRecord(notificationTopic, payload));
    when(kafkaTemplate.send(anyString(), anyString(), isNull()))
        .thenReturn(CompletableFuture.completedFuture(null));
    when(kafkaTemplate.send(anyString(), anyString(), notNull()))
        .thenReturn(CompletableFuture.completedFuture(null));

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () -> verify(investigationRepository, never()).updatePhcFact(anyString(), anyString()));
  }

  @Test
  void testProcessNotificationNoDataException() {
    Long notificationUid = 123456789L;
    String payload =
        "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";
    when(investigationRepository.computeInvestigations(String.valueOf(notificationUid)))
        .thenReturn(Optional.empty());
    checkException(notificationTopic, payload, NoDataException.class);
  }

  @Test
  void testProcessInterviewMessage() throws JsonProcessingException {
    Long interviewUid = 234567890L;
    String payload = "{\"payload\": {\"after\": {\"interview_uid\": \"" + interviewUid + "\"}}}";

    final Interview interview = constructInterview(interviewUid);
    interview.setRdbCols(readFileData(FILE_PATH_PREFIX + "RdbColumns.json"));
    interview.setAnswers(readFileData(FILE_PATH_PREFIX + "InterviewAnswers.json"));
    interview.setNotes(readFileData(FILE_PATH_PREFIX + "InterviewNotes.json"));
    when(interviewRepository.computeInterviews(String.valueOf(interviewUid)))
        .thenReturn(Optional.of(interview));
    when(kafkaTemplate.send(anyString(), anyString(), anyString()))
        .thenReturn(CompletableFuture.completedFuture(null));

    ConsumerRecord<String, String> rec = getRecord(interviewTopic, payload);
    investigationService.processMessage(rec);

    final InterviewReportingKey interviewReportingKey = new InterviewReportingKey();
    interviewReportingKey.setInterviewUid(interviewUid);

    final InterviewReporting interviewReportingValue =
        constructInvestigationInterview(interviewUid, 1L);
    interviewReportingValue.setBatchId(toBatchId.applyAsLong(rec));

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(kafkaTemplate, times(4))
                    .send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));

    String actualTopic = topicCaptor.getAllValues().getFirst();
    String actualKey = keyCaptor.getAllValues().getFirst();
    String actualValue = messageCaptor.getAllValues().getFirst();

    var actualInterviewKey =
        objectMapper.readValue(
            objectMapper.readTree(actualKey).path("payload").toString(),
            InterviewReportingKey.class);
    var actualInterviewValue =
        objectMapper.readValue(
            objectMapper.readTree(actualValue).path("payload").toString(),
            InterviewReporting.class);

    assertEquals(interviewTopicOutput, actualTopic);
    assertEquals(interviewReportingKey, actualInterviewKey);
    assertEquals(interviewReportingValue, actualInterviewValue);

    verify(interviewRepository).computeInterviews(String.valueOf(interviewUid));
  }

  @Test
  void testProcessInterviewNoDataException() {
    Long interviewUid = 123456789L;
    String payload = "{\"payload\": {\"after\": {\"interview_uid\": \"" + interviewUid + "\"}}}";

    when(interviewRepository.computeInterviews(String.valueOf(interviewUid)))
        .thenReturn(Optional.empty());
    checkException(interviewTopic, payload, NoDataException.class);
  }

  @Test
  void testProcessContactMessage() throws JsonProcessingException {
    Long contactUid = 234567890L;
    String payload = "{\"payload\": {\"after\": {\"ct_contact_uid\": \"" + contactUid + "\"}}}";

    final Contact contact = constructContact(contactUid);
    contact.setRdbCols(readFileData(FILE_PATH_PREFIX + "RdbColumns.json"));
    contact.setAnswers(readFileData(FILE_PATH_PREFIX + "ContactAnswers.json"));
    when(contactRepository.computeContact(String.valueOf(contactUid)))
        .thenReturn(Optional.of(contact));
    when(kafkaTemplate.send(anyString(), anyString(), anyString()))
        .thenReturn(CompletableFuture.completedFuture(null));

    investigationService.processMessage(getRecord(contactTopic, payload));

    final ContactReportingKey contactReportingKey = new ContactReportingKey();
    contactReportingKey.setContactUid(contactUid);

    final ContactReporting contactReportingValue = constructContactReporting(contactUid);

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(kafkaTemplate, times(3))
                    .send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));

    String actualTopic = topicCaptor.getAllValues().getFirst();
    String actualKey = keyCaptor.getAllValues().getFirst();
    String actualValue = messageCaptor.getAllValues().getFirst();

    var actualContactKey =
        objectMapper.readValue(
            objectMapper.readTree(actualKey).path("payload").toString(), ContactReportingKey.class);
    var actualContactValue =
        objectMapper.readValue(
            objectMapper.readTree(actualValue).path("payload").toString(), ContactReporting.class);

    assertEquals(contactTopicOutput, actualTopic);
    assertEquals(contactReportingKey, actualContactKey);
    assertEquals(contactReportingValue, actualContactValue);

    verify(contactRepository).computeContact(String.valueOf(contactUid));
  }

  @Test
  void testProcessContactNoDataException() {
    String payload = "{\"payload\": {\"after\": {\"ct_contact_uid\": \"\"}}}";
    checkException(contactTopic, payload, NoDataException.class);
  }

  @Test
  void testProcessVaccinationMessage() throws JsonProcessingException {
    Long vaccinationUid = 234567890L;
    String op = "u";
    String payload =
        "{\"payload\": {\"after\": {\"intervention_uid\": \""
            + vaccinationUid
            + "\"}, \"op\": \""
            + op
            + "\"}}";

    final Vaccination vaccination = constructVaccination(vaccinationUid);
    when(vaccinationRepository.computeVaccination(String.valueOf(vaccinationUid)))
        .thenReturn(Optional.of(vaccination));
    when(kafkaTemplate.send(anyString(), anyString(), anyString()))
        .thenReturn(CompletableFuture.completedFuture(null));

    investigationService.processMessage(getRecord(vaccinationTopic, payload));

    final VaccinationReportingKey vaccinationReportingKey = new VaccinationReportingKey();
    vaccinationReportingKey.setVaccinationUid(vaccinationUid);

    final VaccinationReporting vaccinationReportingValue =
        constructVaccinationReporting(vaccinationUid);

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(kafkaTemplate, times(1))
                    .send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));

    String actualTopic = topicCaptor.getAllValues().getFirst();
    String actualKey = keyCaptor.getAllValues().getFirst();
    String actualValue = messageCaptor.getAllValues().getFirst();

    var actualVaccinationKey =
        objectMapper.readValue(
            objectMapper.readTree(actualKey).path("payload").toString(),
            VaccinationReportingKey.class);
    var actualVaccinationValue =
        objectMapper.readValue(
            objectMapper.readTree(actualValue).path("payload").toString(),
            VaccinationReporting.class);

    assertEquals(vaccinationTopicOutput, actualTopic);
    assertEquals(vaccinationReportingKey, actualVaccinationKey);
    assertEquals(vaccinationReportingValue, actualVaccinationValue);

    verify(vaccinationRepository).computeVaccination(String.valueOf(vaccinationUid));
  }

  @Test
  void testProcessVaccinationMessageUpdateOtherTopic() {
    // given an update message from an act_relationship
    String actRelationshipId = "321";
    String payload =
        """
        {
          "payload": {
            "after": {
              "intervention_uid": 123
            },
            "op": "u"
          }
        }
        """;

    // when the message is processed
    investigationService.processVaccination(payload, false, actRelationshipId);

    // then no action is taken
    verifyNoInteractions(vaccinationRepository);
  }

  @Test
  void testProcessVaccinationMessageCreateOtherTopic() {
    // given a message from an act_relationship
    String actRelationshipId = "321";
    String payload =
        """
        {
          "payload": {
            "after": {
              "source_act_uid": "321"
            },
            "op": "c"
          }
        }
        """;

    final Vaccination vaccination = constructVaccination(Long.parseLong(actRelationshipId));
    when(vaccinationRepository.computeVaccination(actRelationshipId))
        .thenReturn(Optional.of(vaccination));

    // when the message is processed
    investigationService.processVaccination(payload, false, actRelationshipId);

    // then the proper id is used
    verify(vaccinationRepository).computeVaccination(actRelationshipId);
  }

  @Test
  void testProcessVaccinationNonUpdate() {
    Long vaccinationUid = 234567890L;
    String payload =
        "{\"payload\": {\"after\": {\"intervention_uid\": \""
            + vaccinationUid
            + "\"}, \"op\": \"c\"}}";

    final Vaccination vaccination = constructVaccination(vaccinationUid);
    when(vaccinationRepository.computeVaccination(String.valueOf(vaccinationUid)))
        .thenReturn(Optional.of(vaccination));

    investigationService.processMessage(getRecord(vaccinationTopic, payload));
    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(kafkaTemplate)
                    .send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));
  }

  @Test
  void testProcessVaccinationNoDataException() {
    String payload = "{\"payload\": {\"after\": {\"intervention_uid\": \"\"}}}";
    checkException(vaccinationTopic, payload, NoDataException.class);
  }

  private void validateInvestigationData(String payload, Investigation investigation)
      throws JsonProcessingException {
    ConsumerRecord<String, String> rec = getRecord(investigationTopic, payload);
    investigationService.processMessage(rec);

    InvestigationKey investigationKey = new InvestigationKey();
    investigationKey.setPublicHealthCaseUid(investigation.getPublicHealthCaseUid());
    final InvestigationReporting reportingModel =
        constructInvestigationReporting(investigation.getPublicHealthCaseUid());
    reportingModel.setBatchId(toBatchId.applyAsLong(rec));

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () ->
                verify(kafkaTemplate, times(15))
                    .send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));

    String actualTopic = null;
    String actualKey = null;
    String actualValue = null;

    List<String> topics = topicCaptor.getAllValues();
    for (int i = 0; i < topics.size(); i++) {
      if (topics.get(i).equals(investigationTopicOutput)) {
        actualTopic = topics.get(i);
        actualKey = keyCaptor.getAllValues().get(i);
        actualValue = messageCaptor.getAllValues().get(i);
        break;
      }
    }

    var actualReporting =
        objectMapper.readValue(
            objectMapper.readTree(actualValue).path("payload").toString(),
            InvestigationReporting.class);
    var actualInvestigationKey =
        objectMapper.readValue(
            objectMapper.readTree(actualKey).path("payload").toString(), InvestigationKey.class);

    assertEquals(investigationTopicOutput, actualTopic); // investigation topic
    assertEquals(investigationKey, actualInvestigationKey);
    assertEquals(reportingModel, actualReporting);
  }

  @Test
  void testProcessTreatmentMessage() throws JsonProcessingException {
    Long treatmentUid = 234567890L;
    String op = "u";
    String payload =
        "{\"payload\": {\"after\": {\"treatment_uid\": \""
            + treatmentUid
            + "\"}, \"op\": \""
            + op
            + "\"}}";

    final Treatment treatment = constructTreatment(treatmentUid);

    when(treatmentRepository.computeTreatment(String.valueOf(treatmentUid)))
        .thenReturn(Optional.of(treatment));

    CompletableFuture<SendResult<String, String>> future = new CompletableFuture<>();
    when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(future);

    ConsumerRecord<String, String> rec = getRecord(treatmentTopic, payload);
    investigationService.processMessage(rec);
    future.complete(null);

    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () -> {
              verify(treatmentRepository).computeTreatment(String.valueOf(treatmentUid));
              verify(kafkaTemplate)
                  .send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
            });

    assertEquals(treatmentTopicOutput, topicCaptor.getValue());

    String treatmentJson = messageCaptor.getValue();
    Treatment actualTreatment =
        objectMapper.readValue(
            objectMapper.readTree(treatmentJson).path("payload").toString(), Treatment.class);

    String keyJson = keyCaptor.getValue();
    TreatmentReportingKey keyObject =
        objectMapper.readValue(
            objectMapper.readTree(keyJson).path("payload").toString(), TreatmentReportingKey.class);
    assertEquals(treatment.getTreatmentUid(), keyObject.getTreatmentUid());

    assertEquals(treatment, actualTreatment);
  }

  @Test
  void testProcessTreatmentNonUpdate() {
    Long treatmentUid = 234567890L;
    String payload =
        "{\"payload\": {\"after\": {\"treatment_uid\": \"" + treatmentUid + "\"}, \"op\": \"c\"}}";

    final Treatment treatment = constructTreatment(treatmentUid);
    when(treatmentRepository.computeTreatment(String.valueOf(treatmentUid)))
        .thenReturn(Optional.of(treatment));

    investigationService.processMessage(getRecord(treatmentTopic, payload));
    Awaitility.await()
        .atMost(1, TimeUnit.SECONDS)
        .untilAsserted(
            () -> verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString()));
  }

  @Test
  void testProcessTreatmentMessageCreateOtherTopic() {
    // given a message from an act_relationship
    String actRelationshipId = "321";
    String payload =
        """
        {
          "payload": {
            "after": {
              "source_act_uid": "321"
            },
            "op": "c"
          }
        }
        """;

    final Treatment treatment = constructTreatment(Long.parseLong(actRelationshipId));
    when(treatmentRepository.computeTreatment(actRelationshipId))
        .thenReturn(Optional.of(treatment));
    CompletableFuture<SendResult<String, String>> future = new CompletableFuture<>();
    when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(future);

    // when the message is processed
    investigationService.processTreatment(payload, false, actRelationshipId);

    // then the proper id is used
    verify(treatmentRepository).computeTreatment(actRelationshipId);
  }

  @Test
  void testProcessTreatmentException() {
    String invalidPayload = "{\"payload\": {\"after\": {}, \"op\": \"u\"}}";
    checkException(treatmentTopic, invalidPayload, DataProcessingException.class);
  }

  @Test
  void testProcessTreatmentNoDataException() {
    String payload = "{\"payload\": {\"after\": {\"treatment_uid\": \"\"}, \"op\": \"u\"}}";
    checkException(treatmentTopic, payload, NoDataException.class);
  }

  private ConsumerRecord<String, String> getRecord(String topic, String payload) {
    return new ConsumerRecord<>(topic, 0, 11L, null, payload);
  }

  private ConsumerRecord<String, String> retryRecord(
      String retryTopic, String originalTopic, String payload) {
    ConsumerRecord<String, String> kafkaMessage = getRecord(retryTopic, payload);
    kafkaMessage
        .headers()
        .add(KafkaHeaders.ORIGINAL_TOPIC, originalTopic.getBytes(StandardCharsets.UTF_8));
    return kafkaMessage;
  }

  private void checkException(
      String topic, String payload, Class<? extends Exception> exceptionClass) {
    ConsumerRecord<String, String> rec = getRecord(topic, payload);
    CompletableFuture<Void> future = investigationService.processMessage(rec);
    CompletionException ex = assertThrows(CompletionException.class, future::join);
    assertEquals(exceptionClass, ex.getCause().getClass());
  }
}
