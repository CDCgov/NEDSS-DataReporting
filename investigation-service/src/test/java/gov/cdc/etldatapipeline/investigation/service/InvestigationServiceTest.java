package gov.cdc.etldatapipeline.investigation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.NoDataException;

import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.etldatapipeline.investigation.repository.*;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.*;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.*;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.*;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.*;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static gov.cdc.etldatapipeline.investigation.service.InvestigationService.toBatchId;

import static gov.cdc.etldatapipeline.investigation.utils.TestUtils.FILE_PATH_PREFIX;
import static gov.cdc.etldatapipeline.investigation.utils.TestUtils.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class InvestigationServiceTest {

    @InjectMocks
    private InvestigationService investigationService;

    @Mock
    private InvestigationRepository investigationRepository;

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private InterviewRepository interviewRepository;

    @Mock
    private ContactRepository contactRepository;

    @Mock
    private TreatmentRepository treatmentRepository;

    @Mock
    private VaccinationRepository vaccinationRepository;

    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private AutoCloseable closeable;

    private final ObjectMapper objectMapper = new ObjectMapper();

    //input topics
    private final String investigationTopic = "Investigation";
    private final String notificationTopic = "Notification";
    private final String interviewTopic = "Interview";
    private final String contactTopic = "Contact";
    private final String vaccinationTopic = "Vaccination";
    private final String treatmentTopic = "Treatment";
    private final String actRelationshipTopic = "Act_relationship";

    //output topics
    private final String investigationTopicOutput = "InvestigationOutput";
    private final String notificationTopicOutput = "investigationNotification";
    private final String interviewTopicOutput = "InterviewOutput";
    private final String contactTopicOutput = "ContactOutput";
    private final String vaccinationTopicOutput = "VaccinationOutput";
    private final String treatmentTopicOutput = "TreatmentOutput";

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        ProcessInvestigationDataUtil transformer = new ProcessInvestigationDataUtil(kafkaTemplate, investigationRepository);

        investigationService = new InvestigationService(
                investigationRepository, notificationRepository, interviewRepository, contactRepository, vaccinationRepository, treatmentRepository,
                kafkaTemplate, transformer, new CustomMetrics(new SimpleMeterRegistry()));

        investigationService.setInvestigationTopic(investigationTopic);
        investigationService.setNotificationTopic(notificationTopic);
        investigationService.setInvestigationTopicReporting(investigationTopicOutput);
        investigationService.setInterviewTopic(interviewTopic);
        investigationService.setContactTopic(contactTopic);
        investigationService.setVaccinationTopic(vaccinationTopic);
        investigationService.setTreatmentTopic(treatmentTopic);
        investigationService.setTreatmentOutputTopicName(treatmentTopicOutput);
        investigationService.setActRelationshipTopic(actRelationshipTopic);
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
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\", \"prog_area_cd\": \"BMIRD\"}}}";

        final Investigation investigation = constructInvestigation(investigationUid);
        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.of(investigation));
        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));
        when(kafkaTemplate.send(anyString(), anyString(), notNull())).thenReturn(CompletableFuture.completedFuture(null));
        validateInvestigationData(payload, investigation);

        verify(investigationRepository).computeInvestigations(String.valueOf(investigationUid));
        verify(investigationRepository).populatePhcFact(String.valueOf(investigationUid));
    }

    @Test
    void testProcessInvestigationPhcFactDisabled() {
        Long investigationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\", \"prog_area_cd\": \"BMIRD\"}}}";

        final Investigation investigation = constructInvestigation(investigationUid);
        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.of(investigation));
        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));
        when(kafkaTemplate.send(anyString(), anyString(), notNull())).thenReturn(CompletableFuture.completedFuture(null));

        investigationService.setPhcDatamartDisable(true);
        ConsumerRecord<String, String> rec = getRecord(investigationTopic, payload);
        investigationService.processMessage(rec);
        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
            verify(investigationRepository, never()).populatePhcFact(String.valueOf(investigationUid)));
    }

    @ParameterizedTest
    @ValueSource(strings = {investigationTopic, notificationTopic, interviewTopic, contactTopic, vaccinationTopic})
    void testProcessMessageException(String topic) {
        String invalidPayload = "{\"payload\": {\"after\": }}";
        checkException(topic, invalidPayload, DataProcessingException.class);
    }

    @Test
    void testProcessInvestigationNoDataException() {
        Long investigationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\"}}}";

        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.empty());
        checkException(investigationTopic, payload, NoDataException.class);
    }

    @Test
    void testProcessNotificationMessage() {
        Long notificationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";

        final NotificationUpdate notification = constructNotificationUpdate(notificationUid);
        when(notificationRepository.computeNotifications(String.valueOf(notificationUid))).thenReturn(Optional.of(notification));
        investigationService.processMessage(getRecord(notificationTopic, payload));

        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() -> {
            verify(notificationRepository).computeNotifications(String.valueOf(notificationUid));
            verify(kafkaTemplate).send(topicCaptor.capture(), anyString(), anyString());
            verify(investigationRepository).updatePhcFact("NOTF", String.valueOf(notificationUid));
        });
        assertEquals(notificationTopicOutput, topicCaptor.getValue());
    }

    @Test
    void testProcessNotificationPhcFactDisabled() {
        Long notificationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";

        final NotificationUpdate notification = constructNotificationUpdate(notificationUid);
        when(notificationRepository.computeNotifications(String.valueOf(notificationUid))).thenReturn(Optional.of(notification));
        investigationService.setPhcDatamartDisable(true);

        investigationService.processMessage(getRecord(notificationTopic, payload));
        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));
        when(kafkaTemplate.send(anyString(), anyString(), notNull())).thenReturn(CompletableFuture.completedFuture(null));

        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                verify(investigationRepository, never()).updatePhcFact(anyString(), anyString()));
    }

    @Test
    void testProcessNotificationNoDataException() {
        Long notificationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";
        when(investigationRepository.computeInvestigations(String.valueOf(notificationUid))).thenReturn(Optional.empty());
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
        when(interviewRepository.computeInterviews(String.valueOf(interviewUid))).thenReturn(Optional.of(interview));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        ConsumerRecord<String, String> rec = getRecord(interviewTopic, payload);
        investigationService.processMessage(rec);

        final InterviewReportingKey interviewReportingKey = new InterviewReportingKey();
        interviewReportingKey.setInterviewUid(interviewUid);

        final InterviewReporting interviewReportingValue = constructInvestigationInterview(interviewUid, 1L);
        interviewReportingValue.setBatchId(toBatchId.applyAsLong(rec));

        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                verify(kafkaTemplate, times(4)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));

        String actualTopic = topicCaptor.getAllValues().getFirst();
        String actualKey = keyCaptor.getAllValues().getFirst();
        String actualValue = messageCaptor.getAllValues().getFirst();

        var actualInterviewKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), InterviewReportingKey.class);
        var actualInterviewValue = objectMapper.readValue(
                objectMapper.readTree(actualValue).path("payload").toString(), InterviewReporting.class);

        assertEquals(interviewTopicOutput, actualTopic);
        assertEquals(interviewReportingKey, actualInterviewKey);
        assertEquals(interviewReportingValue, actualInterviewValue);

        verify(interviewRepository).computeInterviews(String.valueOf(interviewUid));
    }

    @Test
    void testProcessInterviewNoDataException() {
        Long interviewUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"interview_uid\": \"" + interviewUid + "\"}}}";

        when(interviewRepository.computeInterviews(String.valueOf(interviewUid))).thenReturn(Optional.empty());
        checkException(interviewTopic, payload, NoDataException.class);
    }

    @Test
    void testProcessContactMessage() throws JsonProcessingException {
        Long contactUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"ct_contact_uid\": \"" + contactUid + "\"}}}";

        final Contact contact = constructContact(contactUid);
        contact.setRdbCols(readFileData(FILE_PATH_PREFIX + "RdbColumns.json"));
        contact.setAnswers(readFileData(FILE_PATH_PREFIX + "ContactAnswers.json"));
        when(contactRepository.computeContact(String.valueOf(contactUid))).thenReturn(Optional.of(contact));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        investigationService.processMessage(getRecord(contactTopic, payload));

        final ContactReportingKey contactReportingKey = new ContactReportingKey();
        contactReportingKey.setContactUid(contactUid);

        final ContactReporting contactReportingValue = constructContactReporting(contactUid);

        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                verify(kafkaTemplate, times(3)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));

        String actualTopic = topicCaptor.getAllValues().getFirst();
        String actualKey = keyCaptor.getAllValues().getFirst();
        String actualValue = messageCaptor.getAllValues().getFirst();

        var actualContactKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), ContactReportingKey.class);
        var actualContactValue = objectMapper.readValue(
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
        String payload = "{\"payload\": {\"after\": {\"intervention_uid\": \"" + vaccinationUid + "\"}, \"op\": \"" + op + "\"}}";

        final Vaccination vaccination = constructVaccination(vaccinationUid);
        when(vaccinationRepository.computeVaccination(String.valueOf(vaccinationUid))).thenReturn(Optional.of(vaccination));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        investigationService.processMessage(getRecord(vaccinationTopic, payload));

        final VaccinationReportingKey vaccinationReportingKey = new VaccinationReportingKey();
        vaccinationReportingKey.setVaccinationUid(vaccinationUid);

        final VaccinationReporting vaccinationReportingValue = constructVaccinationReporting(vaccinationUid);

        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                verify(kafkaTemplate, times(1)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));

        String actualTopic = topicCaptor.getAllValues().getFirst();
        String actualKey = keyCaptor.getAllValues().getFirst();
        String actualValue = messageCaptor.getAllValues().getFirst();

        var actualVaccinationKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), VaccinationReportingKey.class);
        var actualVaccinationValue = objectMapper.readValue(
                objectMapper.readTree(actualValue).path("payload").toString(), VaccinationReporting.class);

        assertEquals(vaccinationTopicOutput, actualTopic);
        assertEquals(vaccinationReportingKey, actualVaccinationKey);
        assertEquals(vaccinationReportingValue, actualVaccinationValue);

        verify(vaccinationRepository).computeVaccination(String.valueOf(vaccinationUid));
    }

    @Test
    void testProcessVaccinationNonUpdate() {
        Long vaccinationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"intervention_uid\": \"" + vaccinationUid + "\"}, \"op\": \"c\"}}";

        final Vaccination vaccination = constructVaccination(vaccinationUid);
        when(vaccinationRepository.computeVaccination(String.valueOf(vaccinationUid))).thenReturn(Optional.of(vaccination));

        investigationService.processMessage(getRecord(vaccinationTopic, payload));
        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));
    }

    @Test
    void testProcessVaccinationNoDataException() {
        String payload = "{\"payload\": {\"after\": {\"intervention_uid\": \"\"}}}";
        checkException(vaccinationTopic, payload, NoDataException.class);
    }

    @ParameterizedTest
    @CsvSource({
            "c,1180",
            "u,1180",
            "u,1180",
            "d,1180",
            "c,OTHER"
    })
    void testProcessActRelationshipVaccination(String op, String typeCd) throws JsonProcessingException {
        Long sourceActUid = 123456789L;

        String payload = "{\"payload\": {\"before\": {\"source_act_uid\": \"" + sourceActUid + "\", \"type_cd\": \"" + typeCd + "\"}," +
                "\"after\": {\"source_act_uid\": \"" + sourceActUid + "\", \"type_cd\": \"" + typeCd + "\"}," +
                "\"op\": \"" + op + "\"}}";

        final Vaccination vaccination = constructVaccination(sourceActUid);

        when(vaccinationRepository.computeVaccination(String.valueOf(sourceActUid))).thenReturn(Optional.of(vaccination));

        CompletableFuture<SendResult<String, String>> future = new CompletableFuture<>();
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(future);

        // Create a ConsumerRecord object
        ConsumerRecord<String, String> rec = getRecord(actRelationshipTopic, payload);

        if (typeCd.equals("OTHER") || op.equals("u")) {
            investigationService.processMessage(rec);
            Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                    verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString()));
        } else {
            investigationService.processMessage(rec);

            final VaccinationReportingKey vaccinationReportingKey = new VaccinationReportingKey();
            vaccinationReportingKey.setVaccinationUid(sourceActUid);

            final VaccinationReporting vaccinationReportingValue = constructVaccinationReporting(sourceActUid);

            Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                    verify(kafkaTemplate, times(1)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));

            String actualTopic = topicCaptor.getAllValues().getFirst();
            String actualKey = keyCaptor.getAllValues().getFirst();
            String actualValue = messageCaptor.getAllValues().getFirst();

            var actualVaccinationKey = objectMapper.readValue(
                    objectMapper.readTree(actualKey).path("payload").toString(), VaccinationReportingKey.class);
            var actualVaccinationValue = objectMapper.readValue(
                    objectMapper.readTree(actualValue).path("payload").toString(), VaccinationReporting.class);

            assertEquals(vaccinationTopicOutput, actualTopic);
            assertEquals(vaccinationReportingKey, actualVaccinationKey);
            assertEquals(vaccinationReportingValue, actualVaccinationValue);

        }
    }


    @ParameterizedTest
    @CsvSource({
            "d,TreatmentToPHC",
            "d,TreatmentToMorb",
            "c,TreatmentToPHC",
            "c,TreatmentToMorb",
            "c,OTHER,true"
    })
    void testProcessActRelationshipTreatment(String op, String typeCd) throws JsonProcessingException {
        Long sourceActUid = 123456789L;

        String payload = "{\"payload\": {\"before\": {\"source_act_uid\": \"" + sourceActUid + "\", \"type_cd\": \"" + typeCd + "\"}," +
                "\"after\": {\"source_act_uid\": \"" + sourceActUid + "\", \"type_cd\": \"" + typeCd + "\"}," +
                "\"op\": \"" + op + "\"}}";

        final Treatment treatment = constructTreatment(sourceActUid);

        when(treatmentRepository.computeTreatment(String.valueOf(sourceActUid))).thenReturn(Optional.of(treatment));

        CompletableFuture<SendResult<String, String>> future = new CompletableFuture<>();
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(future);

        // Create a ConsumerRecord object
        ConsumerRecord<String, String> rec = getRecord(actRelationshipTopic, payload);

        if (typeCd.equals("OTHER")) {
            investigationService.processMessage(rec);
            Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                    verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString()));
        }
        else {
            investigationService.processMessage(rec);
            future.complete(null);

            Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() -> {
                verify(treatmentRepository).computeTreatment(String.valueOf(sourceActUid));
                verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
            });

            assertEquals(treatmentTopicOutput, topicCaptor.getValue());

            String treatmentJson = messageCaptor.getValue();
            Treatment actualTreatment = objectMapper.readValue(
                    objectMapper.readTree(treatmentJson).path("payload").toString(),
                    Treatment.class);

            String keyJson = keyCaptor.getValue();
            TreatmentReportingKey keyObject = objectMapper.readValue(
                    objectMapper.readTree(keyJson).path("payload").toString(),
                    TreatmentReportingKey.class);
            assertEquals(treatment.getTreatmentUid(), keyObject.getTreatmentUid());
            assertEquals(treatment, actualTreatment);
        }
    }

    @Test
    void testProcessActRelationshipNullPayload() {
        ConsumerRecord<String, String> rec = getRecord(actRelationshipTopic, null);
        investigationService.processMessage(rec);

        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString()));
    }

    @ParameterizedTest
    @CsvSource({"d", "c"})
    void testProcessActRelationshipException(String op) {
        String payload = "{\"payload\": {\"before\": {}," + "\"after\": { }, \"op\": \"" + op + "\"}}";
        checkException(actRelationshipTopic, payload, DataProcessingException.class);
    }

    private void validateInvestigationData(String payload, Investigation investigation) throws JsonProcessingException {
        ConsumerRecord<String, String> rec = getRecord(investigationTopic, payload);
        investigationService.processMessage(rec);

        InvestigationKey investigationKey = new InvestigationKey();
        investigationKey.setPublicHealthCaseUid(investigation.getPublicHealthCaseUid());
        final InvestigationReporting reportingModel = constructInvestigationReporting(investigation.getPublicHealthCaseUid());
        reportingModel.setBatchId(toBatchId.applyAsLong(rec));

        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                verify(kafkaTemplate, times(15)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));

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

        var actualReporting = objectMapper.readValue(
                objectMapper.readTree(actualValue).path("payload").toString(), InvestigationReporting.class);
        var actualInvestigationKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path("payload").toString(), InvestigationKey.class);

        assertEquals(investigationTopicOutput, actualTopic); // investigation topic
        assertEquals(investigationKey, actualInvestigationKey);
        assertEquals(reportingModel, actualReporting);
    }

    @Test
    void testProcessTreatmentMessage() throws JsonProcessingException {
        Long treatmentUid = 234567890L;
        String op = "u";
        String payload = "{\"payload\": {\"after\": {\"treatment_uid\": \"" + treatmentUid + "\"}, \"op\": \"" + op + "\"}}";

        final Treatment treatment = constructTreatment(treatmentUid);

        when(treatmentRepository.computeTreatment(String.valueOf(treatmentUid))).thenReturn(Optional.of(treatment));

        CompletableFuture<SendResult<String, String>> future = new CompletableFuture<>();
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(future);

        ConsumerRecord<String, String> rec = getRecord(treatmentTopic, payload);
        investigationService.processMessage(rec);
        future.complete(null);

        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() -> {
            verify(treatmentRepository).computeTreatment(String.valueOf(treatmentUid));
            verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        });

        assertEquals(treatmentTopicOutput, topicCaptor.getValue());

        String treatmentJson = messageCaptor.getValue();
        Treatment actualTreatment = objectMapper.readValue(
                objectMapper.readTree(treatmentJson).path("payload").toString(),
                Treatment.class);

        String keyJson = keyCaptor.getValue();
        TreatmentReportingKey keyObject = objectMapper.readValue(
                objectMapper.readTree(keyJson).path("payload").toString(),
                TreatmentReportingKey.class);
        assertEquals(treatment.getTreatmentUid(), keyObject.getTreatmentUid());

        assertEquals(treatment, actualTreatment);
    }

    @Test
    void testProcessTreatmentNonUpdate() {
        Long treatmentUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"treatment_uid\": \"" + treatmentUid + "\"}, \"op\": \"c\"}}";

        final Treatment treatment = constructTreatment(treatmentUid);
        when(treatmentRepository.computeTreatment(String.valueOf(treatmentUid))).thenReturn(Optional.of(treatment));

        investigationService.processMessage(getRecord(treatmentTopic, payload));
        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString()));
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

    private void checkException(String topic, String payload, Class<? extends Exception> exceptionClass) {
        ConsumerRecord<String, String> rec = getRecord(topic, payload);
        CompletableFuture<Void> future = investigationService.processMessage(rec);
        CompletionException ex = assertThrows(CompletionException.class, future::join);
        assertEquals(exceptionClass, ex.getCause().getClass());
    }
}
