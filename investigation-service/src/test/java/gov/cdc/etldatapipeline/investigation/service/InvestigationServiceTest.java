package gov.cdc.etldatapipeline.investigation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.commonutil.NoDataException;

import gov.cdc.etldatapipeline.investigation.repository.*;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.*;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.*;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.MockConsumer;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.*;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

import java.util.List;
import java.util.NoSuchElementException;
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

    @Mock
    MockConsumer<String, String> consumer;

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

        investigationService = new InvestigationService(investigationRepository, notificationRepository, interviewRepository, contactRepository, vaccinationRepository, treatmentRepository, kafkaTemplate, transformer);

        investigationService.setPhcDatamartEnable(true);
        investigationService.setBmirdCaseEnable(true);
        investigationService.setContactRecordEnable(true);
        investigationService.setTreatmentEnable(true);
        investigationService.setInvestigationTopic(investigationTopic);
        investigationService.setNotificationTopic(notificationTopic);
        investigationService.setInvestigationTopicReporting(investigationTopicOutput);
        investigationService.setInterviewTopic(interviewTopic);
        investigationService.setContactTopic(contactTopic);
        investigationService.setVaccinationTopic(vaccinationTopic);
        investigationService.setTreatmentTopic(treatmentTopic);
        investigationService.setTreatmentOutputTopicName(treatmentTopicOutput);
        investigationService.setActRelationshipTopic(actRelationshipTopic);

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
    void testProcessInvestigationBmirdFeatureDisabled() {
        Long investigationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\", \"prog_area_cd\": \"BMIRD\"}}}";

        final Investigation investigation = constructInvestigation(investigationUid);
        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.of(investigation));

        investigationService.setBmirdCaseEnable(false);
        investigationService.processMessage(getRecord(investigationTopic, payload), consumer);
        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void testProcessInvestigationException() {
        String invalidPayload = "{\"payload\": {\"after\": }}";
        ConsumerRecord<String, String> rec = getRecord(investigationTopic, invalidPayload);
        assertThrows(RuntimeException.class, () -> investigationService.processMessage(rec, consumer));
    }

    @Test
    void testProcessInvestigationNoDataException() {
        Long investigationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"public_health_case_uid\": \"" + investigationUid + "\"}}}";
        ConsumerRecord<String, String> rec = getRecord(investigationTopic, payload);

        when(investigationRepository.computeInvestigations(String.valueOf(investigationUid))).thenReturn(Optional.empty());
        assertThrows(NoDataException.class, () -> investigationService.processMessage(rec, consumer));
    }

    @Test
    void testProcessNotificationMessage() {
        Long notificationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";

        final NotificationUpdate notification = constructNotificationUpdate(notificationUid);
        when(notificationRepository.computeNotifications(String.valueOf(notificationUid))).thenReturn(Optional.of(notification));
        investigationService.processMessage(getRecord(notificationTopic, payload), consumer);

        verify(notificationRepository).computeNotifications(String.valueOf(notificationUid));
        verify(kafkaTemplate).send(topicCaptor.capture(), anyString(), anyString());
        assertEquals(notificationTopicOutput, topicCaptor.getValue());
    }

    @Test
    void testProcessNotificationException() {
        String invalidPayload = "{\"payload\": {\"after\": {}}}";
        ConsumerRecord<String, String> rec = getRecord(notificationTopic, invalidPayload);
        RuntimeException ex = assertThrows(RuntimeException.class, () -> investigationService.processMessage(rec, consumer));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @Test
    void testProcessNotificationNoDataException() {
        Long notificationUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"notification_uid\": \"" + notificationUid + "\"}}}";
        ConsumerRecord<String, String> rec = getRecord(notificationTopic, payload);

        when(investigationRepository.computeInvestigations(String.valueOf(notificationUid))).thenReturn(Optional.empty());
        assertThrows(NoDataException.class, () -> investigationService.processMessage(rec, consumer));
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
        investigationService.processMessage(rec, consumer);

        final InterviewReportingKey interviewReportingKey = new InterviewReportingKey();
        interviewReportingKey.setInterviewUid(interviewUid);

        final InterviewReporting interviewReportingValue = constructInvestigationInterview(interviewUid, 1L);
        interviewReportingValue.setBatchId(toBatchId.applyAsLong(rec));

        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(4)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

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
    void testProcessInterviewException() {
        String invalidPayload = "{\"payload\": {\"after\": {}}}";
        ConsumerRecord<String, String> rec = getRecord(interviewTopic, invalidPayload);
        RuntimeException ex = assertThrows(RuntimeException.class, () -> investigationService.processMessage(rec, consumer));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @Test
    void testProcessInterviewNoDataException() {
        Long interviewUid = 123456789L;
        String payload = "{\"payload\": {\"after\": {\"interview_uid\": \"" + interviewUid + "\"}}}";
        ConsumerRecord<String, String> rec = getRecord(interviewTopic, payload);

        when(interviewRepository.computeInterviews(String.valueOf(interviewUid))).thenReturn(Optional.empty());
        assertThrows(NoDataException.class, () -> investigationService.processMessage(rec, consumer));
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

        investigationService.processMessage(getRecord(contactTopic, payload), consumer);

        final ContactReportingKey contactReportingKey = new ContactReportingKey();
        contactReportingKey.setContactUid(contactUid);

        final ContactReporting contactReportingValue = constructContactReporting(contactUid);

        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(3)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

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
    void testProcessContactMessageWhenFeatureDisabled() {
        Long contactUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"ct_contact_uid\": \"" + contactUid + "\"}}}";

        final Contact contact = constructContact(contactUid);
        when(contactRepository.computeContact(String.valueOf(contactUid))).thenReturn(Optional.of(contact));

        investigationService.setContactRecordEnable(false);
        investigationService.processMessage(getRecord(contactTopic, payload), consumer);
        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void testProcessContactException() {
        String invalidPayload = "{\"payload\": {\"after\": {}}}";
        ConsumerRecord<String, String> rec = getRecord(contactTopic, invalidPayload);
        RuntimeException ex = assertThrows(RuntimeException.class, () -> investigationService.processMessage(rec, consumer));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @Test
    void testProcessContactNoDataException() {
        String payload = "{\"payload\": {\"after\": {\"ct_contact_uid\": \"\"}}}";
        ConsumerRecord<String, String> rec = getRecord(contactTopic, payload);
        assertThrows(NoDataException.class, () -> investigationService.processMessage(rec, consumer));
    }

    @Test
    void testProcessVaccinationMessage() throws JsonProcessingException {
        Long vaccinationUid = 234567890L;
        String op = "u";
        String payload = "{\"payload\": {\"after\": {\"intervention_uid\": \"" + vaccinationUid + "\"}, \"op\": \"" + op + "\"}}";

        final Vaccination vaccination = constructVaccination(vaccinationUid);
        when(vaccinationRepository.computeVaccination(String.valueOf(vaccinationUid))).thenReturn(Optional.of(vaccination));
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        investigationService.processMessage(getRecord(vaccinationTopic, payload), consumer);

        final VaccinationReportingKey vaccinationReportingKey = new VaccinationReportingKey();
        vaccinationReportingKey.setVaccinationUid(vaccinationUid);

        final VaccinationReporting vaccinationReportingValue = constructVaccinationReporting(vaccinationUid);

        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(1)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

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
    void testProcessVaccinationException() {
        String invalidPayload = "{\"payload\": {\"after\": {}}}";
        ConsumerRecord<String, String> rec = getRecord(vaccinationTopic, invalidPayload);
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> investigationService.processMessage(rec, consumer));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @Test
    void testProcessVaccinationNonUpdate() {
        Long vaccinationUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"intervention_uid\": \"" + vaccinationUid + "\"}, \"op\": \"c\"}}";

        final Vaccination vaccination = constructVaccination(vaccinationUid);
        when(vaccinationRepository.computeVaccination(String.valueOf(vaccinationUid))).thenReturn(Optional.of(vaccination));

        investigationService.processMessage(getRecord(vaccinationTopic, payload), consumer);
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
    }

    @Test
    void testProcessVaccinationNoDataException() {
        String payload = "{\"payload\": {\"after\": {\"intervention_uid\": \"\"}}}";
        ConsumerRecord<String, String> rec = getRecord(vaccinationTopic, payload);
        assertThrows(NoDataException.class, () -> investigationService.processMessage(rec, consumer));
    }

    @ParameterizedTest
    @CsvSource(
            {"c,1180",
            "u,1180",
            "u,1180",
            "d,1180",
            "c,OTHER"
            }
    )
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

        if (typeCd.equals("OTHER")) {
            investigationService.processMessage(rec, consumer);
            verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
        } else {
            investigationService.processMessage(rec, consumer);
            future.complete(null);

            final VaccinationReportingKey vaccinationReportingKey = new VaccinationReportingKey();
            vaccinationReportingKey.setVaccinationUid(sourceActUid);

            final VaccinationReporting vaccinationReportingValue = constructVaccinationReporting(sourceActUid);

            Awaitility.await()
                    .atMost(1, TimeUnit.SECONDS)
                    .untilAsserted(() ->
                            verify(kafkaTemplate, times(1)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                    );

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
    @CsvSource(
                {"d,TreatmentToPHC,true",
                        "d,TreatmentToPHC,false",
                        "d,TreatmentToMorb,true",
                        "d,TreatmentToMorb,false",
                        "c,TreatmentToPHC,true",
                        "c,TreatmentToPHC,false",
                        "c,TreatmentToMorb,true",
                        "c,TreatmentToMorb,false",
                        "c,OTHER,true"}
    )
    void testProcessActRelationshipTreatment(String op, String typeCd, String treatmentEnabled) throws JsonProcessingException {
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

        if (treatmentEnabled.equals("false") || typeCd.equals("OTHER")) {
            investigationService.setTreatmentEnable(false);
            investigationService.processMessage(rec, consumer);
            verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
        }
        else {
            investigationService.processMessage(rec, consumer);
            future.complete(null);

            verify(treatmentRepository).computeTreatment(String.valueOf(sourceActUid));
            verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

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

        investigationService.processMessage(rec, consumer);

        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @ParameterizedTest
    @CsvSource(
            {
                    "d",
                    "c"
            }
    )
    void testProcessActRelationshipException(String op) {
        String payload = "{\"payload\": {\"before\": { }," +
                "\"after\": { }," +
                "\"op\": \"" + op + "\"}}";
        ConsumerRecord<String, String> rec = getRecord(actRelationshipTopic, payload);

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> investigationService.processMessage(rec, consumer));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    private void validateInvestigationData(String payload, Investigation investigation) throws JsonProcessingException {

        ConsumerRecord<String, String> rec = getRecord(investigationTopic, payload);
        investigationService.processMessage(rec, consumer);

        InvestigationKey investigationKey = new InvestigationKey();
        investigationKey.setPublicHealthCaseUid(investigation.getPublicHealthCaseUid());
        final InvestigationReporting reportingModel = constructInvestigationReporting(investigation.getPublicHealthCaseUid());
        reportingModel.setBatchId(toBatchId.applyAsLong(rec));

        verify(kafkaTemplate, times(15)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

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

        // Create a ConsumerRecord object
        ConsumerRecord<String, String> rec = getRecord(treatmentTopic, payload);
        investigationService.processMessage(rec, consumer);
        future.complete(null);

        verify(treatmentRepository).computeTreatment(String.valueOf(treatmentUid));
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

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
    void testProcessTreatmentWhenFeatureDisabled() {
        Long treatmentUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"treatment_uid\": \"" + treatmentUid + "\"}, \"op\": \"u\"}}";

        final Treatment treatment = constructTreatment(treatmentUid);
        when(treatmentRepository.computeTreatment(String.valueOf(treatmentUid))).thenReturn(Optional.of(treatment));

        investigationService.setTreatmentEnable(false);
        investigationService.processMessage(getRecord(treatmentTopic, payload), consumer);
        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void testProcessTreatmentNonUpdate() {
        Long treatmentUid = 234567890L;
        String payload = "{\"payload\": {\"after\": {\"treatment_uid\": \"" + treatmentUid + "\"}, \"op\": \"c\"}}";

        final Treatment treatment = constructTreatment(treatmentUid);
        when(treatmentRepository.computeTreatment(String.valueOf(treatmentUid))).thenReturn(Optional.of(treatment));

        investigationService.processMessage(getRecord(treatmentTopic, payload), consumer);
        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void testProcessTreatmentException() {
        String invalidPayload = "{\"payload\": {\"after\": {}, \"op\": \"u\"}}";
        // Create a ConsumerRecord object
        ConsumerRecord<String, String> rec = getRecord(treatmentTopic, invalidPayload);
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> investigationService.processMessage(rec, consumer));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @Test
    void testProcessTreatmentNoDataException() {
        String payload = "{\"payload\": {\"after\": {\"treatment_uid\": \"\"}, \"op\": \"u\"}}";
        // Create a ConsumerRecord object
        ConsumerRecord<String, String> rec = getRecord(treatmentTopic, payload);
        assertThrows(NoDataException.class, () -> investigationService.processMessage(rec, consumer));
    }

    private ConsumerRecord<String, String> getRecord(String topic, String payload) {
        return new ConsumerRecord<>(topic, 0, 11L, null, payload);
    }
}
