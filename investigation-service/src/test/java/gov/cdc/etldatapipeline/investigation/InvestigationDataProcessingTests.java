package gov.cdc.etldatapipeline.investigation;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.*;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.*;
import gov.cdc.etldatapipeline.investigation.repository.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InterviewReporting;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
import org.jetbrains.annotations.NotNull;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.List;
import java.util.concurrent.CompletableFuture;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static gov.cdc.etldatapipeline.investigation.utils.TestUtils.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class InvestigationDataProcessingTests {
    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Mock
    InvestigationRepository investigationRepository;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private AutoCloseable closeable;
    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final String FILE_PREFIX = "rawDataFiles/";
    private static final String CONFIRMATION_TOPIC = "confirmationTopic";
    private static final String OBSERVATION_TOPIC = "observationTopic";
    private static final String NOTIFICATIONS_TOPIC = "notificationsTopic";
    private static final String PAGE_CASE_ANSWER_TOPIC = "pageCaseAnswerTopic";
    private static final String AGGREGATE_TOPIC = "aggregateTopic";
    private static final String CASE_MANAGEMENT_TOPIC = "caseManagementTopic";
    private static final String INTERVIEW_TOPIC = "interviewTopic";
    private static final String INTERVIEW_ANSWERS_TOPIC = "interviewAnswersTopic";
    private static final String INTERVIEW_NOTE_TOPIC = "interviewNoteTopic";
    private static final String RDB_METADATA_COLS_TOPIC = "rdbMetadataColsTopic";
    private static final String CONTACT_TOPIC = "contactTopic";
    private static final String CONTACT_ANSWERS_TOPIC = "contactAnswersTopic";
    private static final String VACCINATION_TOPIC = "vaccinationTopic";
    private static final String VACCINATION_ANSWERS_TOPIC = "vaccinationAnswersTopic";

    private static final Long INVESTIGATION_UID = 234567890L;
    private static final Long INTERVIEW_UID = 234567890L;
    private static final Long CONTACT_UID = 12345678L;
    private static final Long VACCINATION_UID = 12345678L;
    private static final String INVALID_JSON = "invalidJSON";

    private static final Long BATCH_ID = 11L;

    ProcessInvestigationDataUtil transformer;

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        transformer = new ProcessInvestigationDataUtil(kafkaTemplate, investigationRepository);
        Logger logger = (Logger) LoggerFactory.getLogger(ProcessInvestigationDataUtil.class);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    void tearDown() throws Exception {
        Logger logger = (Logger) LoggerFactory.getLogger(ProcessInvestigationDataUtil.class);
        logger.detachAppender(listAppender);
        closeable.close();
    }

    @Test
    void testConfirmationMethod() throws JsonProcessingException {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationConfirmationMethod(readFileData(FILE_PREFIX + "ConfirmationMethod.json"));
        transformer.investigationConfirmationOutputTopicName = CONFIRMATION_TOPIC;

        InvestigationConfirmationMethodKey confirmationMethodKey = new InvestigationConfirmationMethodKey();
        confirmationMethodKey.setPublicHealthCaseUid(INVESTIGATION_UID);
        confirmationMethodKey.setConfirmationMethodCd("LD");

        InvestigationConfirmationMethod confirmationMethod = new InvestigationConfirmationMethod();
        confirmationMethod.setPublicHealthCaseUid(INVESTIGATION_UID);
        confirmationMethod.setConfirmationMethodCd("LD");
        confirmationMethod.setConfirmationMethodDescTxt("Laboratory confirmed");
        confirmationMethod.setConfirmationMethodTime("2024-01-15T10:20:57.001");
        confirmationMethod.setBatchId(BATCH_ID);

        transformer.setInvestigationObservationOutputTopicName(OBSERVATION_TOPIC);
        transformer.setPageCaseAnswerOutputTopicName(PAGE_CASE_ANSWER_TOPIC);
        transformer.transformInvestigationData(investigation, BATCH_ID);

        verify(kafkaTemplate, timeout(1000).times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        assertEquals(CONFIRMATION_TOPIC, topicCaptor.getAllValues().getFirst());

        var actualConfirmationMethod = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().getLast()).path("payload").toString(), InvestigationConfirmationMethod.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().getLast()).path("payload").toString(), InvestigationConfirmationMethodKey.class);

        assertEquals(confirmationMethodKey, actualKey);
        assertEquals(confirmationMethod, actualConfirmationMethod);
    }

    @Test
    void testTransformInvestigationError(){
        Investigation investigation = new Investigation();
        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);

        investigation.setPersonParticipations(INVALID_JSON);
        investigation.setOrganizationParticipations(INVALID_JSON);
        investigation.setActIds(INVALID_JSON);
        investigation.setInvestigationObservationIds(INVALID_JSON);
        investigation.setInvestigationConfirmationMethod(INVALID_JSON);
        investigation.setInvestigationCaseAnswer(INVALID_JSON);
        investigation.setInvestigationAggregate(INVALID_JSON);
        investigation.setInvestigationCaseCnt(INVALID_JSON);

        transformer.setInvestigationObservationOutputTopicName(OBSERVATION_TOPIC);
        transformer.setPageCaseAnswerOutputTopicName(PAGE_CASE_ANSWER_TOPIC);
        transformer.setInvestigationConfirmationOutputTopicName(CONFIRMATION_TOPIC);
        transformer.transformInvestigationData(investigation, BATCH_ID);
        transformer.processNotifications(INVALID_JSON);

        List<ILoggingEvent> logs = listAppender.list;
        logs.stream().map(ILoggingEvent::getFormattedMessage).filter(m-> m.startsWith("[ERROR]")).forEach(m -> assertTrue(m.contains(INVALID_JSON)));
    }

    @Test
    void testInvestigationObservationIds() throws JsonProcessingException {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationObservationIds(readFileData(FILE_PREFIX + "InvestigationObservationIds.json"));
        transformer.setInvestigationObservationOutputTopicName(OBSERVATION_TOPIC);
        transformer.setInvestigationConfirmationOutputTopicName(CONFIRMATION_TOPIC);
        transformer.setPageCaseAnswerOutputTopicName(PAGE_CASE_ANSWER_TOPIC);

        InvestigationObservation observation = new InvestigationObservation();
        observation.setPublicHealthCaseUid(INVESTIGATION_UID);
        observation.setObservationId(10344738L);
        observation.setRootTypeCd("LabReport");
        observation.setBranchId(10344740L);
        observation.setBranchTypeCd("COMP");
        observation.setBatchId(BATCH_ID);

        transformer.transformInvestigationData(investigation, BATCH_ID);
        verify(kafkaTemplate, timeout(1000).times(6)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        assertEquals(OBSERVATION_TOPIC, topicCaptor.getAllValues().getFirst());

        var actualObservation = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().getFirst()).path("payload").toString(), InvestigationObservation.class);

        assertEquals(observation, actualObservation);
    }

    @Test
    void testProcessNotifications() throws JsonProcessingException {
        Investigation investigation = new Investigation();
        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationNotifications(readFileData(FILE_PREFIX + "InvestigationNotification.json"));
        transformer.investigationNotificationsOutputTopicName = NOTIFICATIONS_TOPIC;

        final var notifications = constructNotifications();

        InvestigationNotificationKey notificationKey = new InvestigationNotificationKey();
        notificationKey.setNotificationUid(notifications.getNotificationUid());

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.processNotifications(investigation.getInvestigationNotifications());
        verify(kafkaTemplate, times (1)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(NOTIFICATIONS_TOPIC, topicCaptor.getValue());

        var actualNotifications = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), InvestigationNotification.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getValue()).path("payload").toString(), InvestigationNotificationKey.class);

        assertEquals(notificationKey, actualKey);
        assertEquals(notifications, actualNotifications);

        JsonNode keyNode = objectMapper.readTree(keyCaptor.getValue()).path("schema").path("fields");
        assertFalse(keyNode.get(0).path("optional").asBoolean());
    }

    @Test
    void testProcessInterviews() throws JsonProcessingException {

        Interview interview = constructInterview(INTERVIEW_UID);
        interview.setAnswers(readFileData(FILE_PREFIX + "InterviewAnswers.json"));
        interview.setNotes(readFileData(FILE_PREFIX + "InterviewNotes.json"));
        transformer.setInterviewOutputTopicName(INTERVIEW_TOPIC);
        transformer.setInterviewAnswerOutputTopicName(INTERVIEW_ANSWERS_TOPIC);
        transformer.setInterviewNoteOutputTopicName(INTERVIEW_NOTE_TOPIC);

        final InterviewReportingKey interviewReportingKey = new InterviewReportingKey();
        interviewReportingKey.setInterviewUid(INTERVIEW_UID);

        final InterviewAnswerKey interviewAnswerKey = new InterviewAnswerKey();
        interviewAnswerKey.setInterviewUid(INTERVIEW_UID);
        interviewAnswerKey.setRdbColumnNm("IX_CONTACTS_NAMED_IND");

        final InterviewNoteKey interviewNoteKey = new InterviewNoteKey();
        interviewNoteKey.setInterviewUid(INTERVIEW_UID);
        interviewNoteKey.setNbsAnswerUid(21L);

        final InterviewReporting interviewReportingValue = constructInvestigationInterview(INTERVIEW_UID, BATCH_ID);
        final InterviewAnswer interviewAnswerValue = constructInvestigationInterviewAnswer(INTERVIEW_UID, BATCH_ID);
        final InterviewNote interviewNoteValue = constructInvestigationInterviewNote(INTERVIEW_UID, BATCH_ID);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.processInterview(interview, BATCH_ID);
        verify(kafkaTemplate, timeout(2000).times(3)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        InterviewReportingKey actualInterviewKey = null;
        InterviewAnswerKey actualInterviewAnswerKey = null;
        InterviewNoteKey actualInterviewNoteKey = null;

        InterviewReporting actualInterviewValue = null;
        InterviewAnswer actualInterviewAnswerValue = null;
        InterviewNote actualInterviewNoteValue = null;

        List<String> topics = topicCaptor.getAllValues();
        List<String> keys = keyCaptor.getAllValues();
        List<String> messages = messageCaptor.getAllValues();
        for (int i = 0; i < topics.size(); i++) {
            switch (topics.get(i)) {
                case INTERVIEW_TOPIC:
                    actualInterviewKey = objectMapper.readValue(
                            objectMapper.readTree(keys.get(i)).path("payload").toString(),
                            InterviewReportingKey.class);
                    actualInterviewValue = objectMapper.readValue(
                            objectMapper.readTree(messages.get(i)).path("payload").toString(),
                            InterviewReporting.class);
                    break;
                case INTERVIEW_ANSWERS_TOPIC:
                    actualInterviewAnswerKey = objectMapper.readValue(
                            objectMapper.readTree(keys.get(i)).path("payload").toString(),
                            InterviewAnswerKey.class);
                    actualInterviewAnswerValue = objectMapper.readValue(
                            objectMapper.readTree(messages.get(i)).path("payload").toString(),
                            InterviewAnswer.class);
                    break;
                case INTERVIEW_NOTE_TOPIC:
                    actualInterviewNoteKey = objectMapper.readValue(
                            objectMapper.readTree(keys.get(i)).path("payload").toString(),
                            InterviewNoteKey.class);
                    actualInterviewNoteValue = objectMapper.readValue(
                            objectMapper.readTree(messages.get(i)).path("payload").toString(),
                            InterviewNote.class);
                    break;
                default:
                    break;
            }
        }

        assertEquals(interviewReportingKey, actualInterviewKey);
        assertEquals(interviewAnswerKey, actualInterviewAnswerKey);
        assertEquals(interviewNoteKey, actualInterviewNoteKey);

        assertEquals(interviewReportingValue, actualInterviewValue);
        assertEquals(interviewAnswerValue, actualInterviewAnswerValue);
        assertEquals(interviewNoteValue, actualInterviewNoteValue);
    }

    @Test
    void testProcessColumnMetadata() throws JsonProcessingException {
        final var rdb_col_name = "CLN_CARE_STATUS_IXS";
        final var tbl_name = "D_INTERVIEW";
        Interview interview = constructInterview(INTERVIEW_UID);
        interview.setRdbCols(readFileData(FILE_PREFIX + "RdbColumns.json"));

        transformer.setRdbMetadataColumnsOutputTopicName(RDB_METADATA_COLS_TOPIC);

        MetadataColumnKey metadataColumnKey = new MetadataColumnKey();
        metadataColumnKey.setRdbColumnName(rdb_col_name);
        metadataColumnKey.setTableName(tbl_name);

        MetadataColumn metadataColumnValue = new MetadataColumn();
        metadataColumnValue.setRdbColumnNm(rdb_col_name);
        metadataColumnValue.setTableName(tbl_name);
        metadataColumnValue.setLastChgTime("2024-05-23T15:42:41.317");
        metadataColumnValue.setLastChgUserId(10000000L);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processColumnMetadata(interview.getRdbCols(), interview.getInterviewUid());
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        var actualRdbMetadataColumnKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getValue()).path("payload").toString(), MetadataColumnKey.class);
        var actualRdbMetadataColumnsValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), MetadataColumn.class);

        assertEquals(metadataColumnKey, actualRdbMetadataColumnKey);
        assertEquals(metadataColumnValue, actualRdbMetadataColumnsValue);
    }

    @Test
    void testProcessInterviewsError(){

        Interview interview = new Interview();
        transformer.processInterview(interview, BATCH_ID);
        verify(kafkaTemplate, never()).send(eq(INTERVIEW_TOPIC), anyString(), anyString());

        interview.setInterviewUid(INTERVIEW_UID);

        interview.setAnswers(INVALID_JSON);
        interview.setNotes(INVALID_JSON);
        transformer.setInterviewOutputTopicName(INTERVIEW_TOPIC);
        transformer.setInterviewAnswerOutputTopicName(INTERVIEW_ANSWERS_TOPIC);
        transformer.setInterviewNoteOutputTopicName(INTERVIEW_NOTE_TOPIC);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processInterview(interview, BATCH_ID);
        verify(kafkaTemplate, timeout(3000).atLeastOnce()).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        ILoggingEvent log = listAppender.list.removeLast();
        assertTrue(log.getFormattedMessage().contains(INVALID_JSON));
        log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains(INVALID_JSON));

        interview.setAnswers(null);
        interview.setNotes(null);
        transformer.processInterview(interview, BATCH_ID);
        verify(kafkaTemplate, timeout(3000).atLeastOnce()).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        log = listAppender.list.removeLast();
        assertTrue(log.getFormattedMessage().contains("Investigation Interview Note"));
        log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains("Investigation Interview Answer"));
    }

    @Test
    void testProcessColumnMetadataError(){

        transformer.setInterviewOutputTopicName(INTERVIEW_TOPIC);
        transformer.setRdbMetadataColumnsOutputTopicName(RDB_METADATA_COLS_TOPIC);

        transformer.processColumnMetadata(INVALID_JSON, BATCH_ID);

        ILoggingEvent log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains(INVALID_JSON));
    }

    @Test
    void testProcessContactWithAnswers() throws JsonProcessingException {

        Contact contact = constructContact(CONTACT_UID);
        contact.setAnswers(readFileData(FILE_PREFIX + "ContactAnswers.json"));
        transformer.setContactOutputTopicName(CONTACT_TOPIC);
        transformer.setContactAnswerOutputTopicName(CONTACT_ANSWERS_TOPIC);

        final  ContactReportingKey contactReportingKey = new ContactReportingKey();
        contactReportingKey.setContactUid(CONTACT_UID);

        final  ContactAnswerKey contactAnswerKey = new ContactAnswerKey();
        contactAnswerKey.setContactUid(CONTACT_UID);
        contactAnswerKey.setRdbColumnNm("CTT_EXPOSURE_TYPE");

        final ContactReporting  contactReportingValue = constructContactReporting(CONTACT_UID);
        final ContactAnswer contactAnswerValue = constructContactAnswers(CONTACT_UID);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processContact(contact);
        verify(kafkaTemplate, timeout(2000).times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        //contact key
        var actualContactKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().getFirst()).path("payload").toString(), ContactReportingKey.class);
        //contact value
        var actualContactValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().getFirst()).path("payload").toString(), ContactReporting.class);

        //contact answer key
        var actualContactAnswerKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().getLast()).path("payload").toString(), ContactAnswerKey.class);
        //contact answer value
        var actualContactAnswerValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().getLast()).path("payload").toString(), ContactAnswer.class);

        assertEquals(contactReportingKey, actualContactKey);
        assertEquals(contactReportingValue, actualContactValue);
        assertEquals(contactAnswerKey, actualContactAnswerKey);
        assertEquals(contactAnswerValue, actualContactAnswerValue);
    }

    @Test
    void testProcessContactError(){

        Contact contact = new Contact();

        transformer.setContactOutputTopicName(CONTACT_TOPIC);
        transformer.setContactAnswerOutputTopicName(CONTACT_ANSWERS_TOPIC);

        transformer.processContact(contact);
        verify(kafkaTemplate, never()).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        ILoggingEvent log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains("Error processing Contact Record "));
    }

    @Test
    void testProcessContactAnswerError(){

        Contact contact = new Contact();
        contact.setContactUid(CONTACT_UID);
        contact.setAnswers(INVALID_JSON);

        transformer.setContactOutputTopicName(CONTACT_TOPIC);
        transformer.setContactAnswerOutputTopicName(CONTACT_ANSWERS_TOPIC);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processContact(contact);
        verify(kafkaTemplate, timeout(1000)).send(anyString(), anyString(), anyString());
        ILoggingEvent log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains(INVALID_JSON));

        contact.setAnswers(null);
        transformer.processContact(contact);
        verify(kafkaTemplate, timeout(1000).atLeastOnce()).send(anyString(), anyString(), anyString());
        log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains("Contact Record Answer"));
    }

    @Test
    void testProcessVaccination() throws JsonProcessingException {

        Vaccination vaccination = constructVaccination(VACCINATION_UID);
        vaccination.setAnswers(null);
        transformer.setVaccinationOutputTopicName(VACCINATION_TOPIC);
        transformer.setVaccinationAnswerOutputTopicName(VACCINATION_ANSWERS_TOPIC);

        final  VaccinationReportingKey vaccinationReportingKey = new VaccinationReportingKey();
        vaccinationReportingKey.setVaccinationUid(VACCINATION_UID);

        final VaccinationReporting vaccinationReportingValue = constructVaccinationReporting(VACCINATION_UID);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processVaccination(vaccination);
        verify(kafkaTemplate, timeout(1000)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        var actualVacKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().getFirst()).path("payload").toString(), VaccinationReportingKey.class);

        var actualVacValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().getFirst()).path("payload").toString(), VaccinationReporting.class);

        assertEquals(vaccinationReportingKey, actualVacKey);
        assertEquals(vaccinationReportingValue, actualVacValue);
    }

    @Test
    void testProcessVaccinationAnswers() throws JsonProcessingException {

        Vaccination vaccination = constructVaccination(VACCINATION_UID);
        vaccination.setAnswers(readFileData(FILE_PREFIX + "VaccinationAnswers.json"));
        transformer.setVaccinationOutputTopicName(VACCINATION_TOPIC);
        transformer.setVaccinationAnswerOutputTopicName(VACCINATION_ANSWERS_TOPIC);

        final  VaccinationReportingKey vaccinationReportingKey = new VaccinationReportingKey();
        vaccinationReportingKey.setVaccinationUid(VACCINATION_UID);
        final VaccinationReporting vaccinationReportingValue = constructVaccinationReporting(VACCINATION_UID);

        final VaccinationAnswerKey vaccinationAnswerKey = new VaccinationAnswerKey();
        vaccinationAnswerKey.setVaccinationUid(VACCINATION_UID);
        vaccinationAnswerKey.setRdbColumnNm("TEST");
        final VaccinationAnswer vaccinationAnswerValue = constructVaccinationAnswers(VACCINATION_UID);


        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processVaccination(vaccination);
        verify(kafkaTemplate, timeout(1000).times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        // key
        var actualVacKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(0)).path("payload").toString(), VaccinationReportingKey.class);
        // value
        var actualVacValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(0)).path("payload").toString(), VaccinationReporting.class);

        // answer key
        var actualVacAnswerKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(1)).path("payload").toString(), VaccinationAnswerKey.class);
        // answer value
        var actualVacAnswerValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(1)).path("payload").toString(), VaccinationAnswer.class);

        assertEquals(vaccinationReportingKey, actualVacKey);
        assertEquals(vaccinationReportingValue, actualVacValue);
        assertEquals(vaccinationAnswerKey, actualVacAnswerKey);
        assertEquals(vaccinationAnswerValue, actualVacAnswerValue);
    }

    @Test
    void testProcessVaccinationError(){

        Vaccination vaccination = constructVaccination(VACCINATION_UID);
        vaccination.setAnswers(INVALID_JSON);

        transformer.setVaccinationOutputTopicName(VACCINATION_TOPIC);
        transformer.setVaccinationAnswerOutputTopicName(VACCINATION_ANSWERS_TOPIC);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.processVaccination(vaccination);
        verify(kafkaTemplate, timeout(1000)).send(anyString(), anyString(), anyString());
        ILoggingEvent log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains(INVALID_JSON));

        vaccination.setAnswers(null);
        transformer.processVaccination(vaccination);
        verify(kafkaTemplate, timeout(1000).atLeastOnce()).send(anyString(), anyString(), anyString());
        log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains("Vaccination Answer"));
    }

    @Test
    void testProcessMissingOrInvalidNotifications() {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationNotifications(null);
        transformer.investigationNotificationsOutputTopicName = NOTIFICATIONS_TOPIC;
        transformer.processNotifications(null);
        transformer.processNotifications("{\"foo\":\"bar\"}");
        verify(kafkaTemplate, never()).send(eq(NOTIFICATIONS_TOPIC), anyString(), anyString());
    }

    @Test
    void testPageCaseAnswer() throws JsonProcessingException {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationCaseAnswer(readFileData(FILE_PREFIX + "InvestigationCaseAnswers.json"));
        transformer.setPageCaseAnswerOutputTopicName(PAGE_CASE_ANSWER_TOPIC);

        PageCaseAnswerKey pageCaseAnswerKey = new PageCaseAnswerKey();
        pageCaseAnswerKey.setActUid(INVESTIGATION_UID);
        pageCaseAnswerKey.setNbsCaseAnswerUid(1235L);

        PageCaseAnswer pageCaseAnswer = constructCaseAnswer();
        pageCaseAnswer.setBatchId(BATCH_ID);

        InvestigationTransformed investigationTransformed = transformer.transformInvestigationData(investigation, BATCH_ID);

        verify(kafkaTemplate, timeout(2000).times(4)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(PAGE_CASE_ANSWER_TOPIC, topicCaptor.getValue());

        var actualPageCaseAnswer = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(1)).path("payload").toString(), PageCaseAnswer.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(1)).path("payload").toString(), PageCaseAnswerKey.class);

        assertEquals(pageCaseAnswerKey, actualKey);
        assertEquals(pageCaseAnswer, actualPageCaseAnswer);

        JsonNode keyNode = objectMapper.readTree(keyCaptor.getValue()).path("schema").path("fields");
        assertFalse(keyNode.get(0).path("optional").asBoolean());
        assertTrue(keyNode.get(1).path("optional").asBoolean());

        assertEquals("D_INV_CLINICAL,D_INV_PLACE_REPEAT,D_INV_ADMINISTRATIVE", investigationTransformed.getRdbTableNameList());
    }

    @Test
    void testPageCaseAnswersDeserialization() throws JsonProcessingException {
        PageCaseAnswer[] answers = objectMapper.readValue(readFileData(FILE_PREFIX + "InvestigationCaseAnswers.json"),
                PageCaseAnswer[].class);

        PageCaseAnswer expected = constructCaseAnswer();

        assertEquals(4, answers.length);
        assertEquals(expected, answers[1]);
    }

    @Test
    void testInvestigationAggregate() throws JsonProcessingException {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationAggregate(readFileData(FILE_PREFIX + "InvestigationAggregate.json"));
        transformer.setInvestigationAggregateOutputTopicName(AGGREGATE_TOPIC);

        PageCaseAnswerKey expectedKey = new PageCaseAnswerKey();
        expectedKey.setActUid(INVESTIGATION_UID);
        expectedKey.setNbsCaseAnswerUid(215086L);

        InvestigationAggregate expected = constructAggregate();
        expected.setBatchId(BATCH_ID);

        transformer.transformInvestigationData(investigation, BATCH_ID);

        verify(kafkaTemplate, timeout(2000).times(7)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(AGGREGATE_TOPIC, topicCaptor.getValue());

        var actual = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().getFirst()).path("payload").toString(), InvestigationAggregate.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().getFirst()).path("payload").toString(), PageCaseAnswerKey.class);

        assertEquals(expectedKey, actualKey);
        assertEquals(expected, actual);

        JsonNode keyNode = objectMapper.readTree(keyCaptor.getValue()).path("schema").path("fields");
        assertFalse(keyNode.get(0).path("optional").asBoolean());
        assertTrue(keyNode.get(1).path("optional").asBoolean());
    }

    @Test
    void testProcessCaseManagement() throws JsonProcessingException {

        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationCaseManagement(readFileData(FILE_PREFIX + "CaseManagement.json"));
        transformer.setInvestigationCaseManagementTopicName(CASE_MANAGEMENT_TOPIC);
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        var caseManagementKey = new InvestigationCaseManagementKey(INVESTIGATION_UID, 1001L);
        var caseManagement = constructCaseManagement(INVESTIGATION_UID);

        transformer.processInvestigationCaseManagement(investigation.getInvestigationCaseManagement());
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(CASE_MANAGEMENT_TOPIC, topicCaptor.getValue());
        var actualCaseManagement = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), InvestigationCaseManagement.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getValue()).path("payload").toString(), InvestigationCaseManagementKey.class);

        assertEquals(caseManagementKey, actualKey);
        assertEquals(caseManagement, actualCaseManagement);
    }

    @Test
    void testProcessMissingOrInvalidCaseManagement() {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationCaseManagement(null);
        transformer.investigationCaseManagementTopicName = CASE_MANAGEMENT_TOPIC;
        transformer.processInvestigationCaseManagement(null);
        transformer.processInvestigationCaseManagement("{\"foo\":\"bar\"}");
        transformer.processInvestigationCaseManagement("{\"investigation_case_management\":}");
        verify(kafkaTemplate, never()).send(eq(CASE_MANAGEMENT_TOPIC), anyString(), anyString());
    }

    @Test
    void testProcessPhcFactDatamartException() {
        final String ERROR_MSG = "Test Error";

        doThrow(new RuntimeException(ERROR_MSG)).when(investigationRepository).populatePhcFact(anyString());
        doThrow(new RuntimeException(ERROR_MSG)).when(investigationRepository).updatePhcFact(anyString(), anyString());

        transformer.processPhcFactDatamart("123");
        ILoggingEvent log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains(ERROR_MSG));

        transformer.processPhcFactDatamart("NOTF","123");
        log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains(ERROR_MSG));
    }

    private @NotNull InvestigationNotification constructNotifications() {
        InvestigationNotification notifications = new InvestigationNotification();
        notifications.setSourceActUid(263748597L);
        notifications.setPublicHealthCaseUid(INVESTIGATION_UID);
        notifications.setSourceClassCd("NOTF");
        notifications.setTargetClassCd("CASE");
        notifications.setActTypeCd("Notification");
        notifications.setStatusCd("A");
        notifications.setNotificationUid(263748597L);
        notifications.setProgAreaCd("XYZ");
        notifications.setProgramJurisdictionOid(9630258741L);
        notifications.setJurisdictionCd("900003");
        notifications.setRecordStatusTime("2024-05-29T16:05:44.523");
        notifications.setStatusTime("2024-05-15T20:25:39.797");
        notifications.setRptSentTime("2024-05-16T20:00:26.380");
        notifications.setNotifStatus("APPROVED");
        notifications.setNotifLocalId("NOT10005003GA01");
        notifications.setNotifComments("test is success");
        notifications.setNotifAddTime("2024-05-15T20:25:39.813");
        notifications.setNotifAddUserId(96325874L);
        notifications.setNotifAddUserName("Zor-El, Kara");
        notifications.setNotifLastChgUserId("96325874");
        notifications.setNotifLastChgUserName("Zor-El, Kara");
        notifications.setNotifLastChgTime("2024-05-29T16:05:44.523");
        notifications.setLocalPatientId("ABC7539512AB01");
        notifications.setLocalPatientUid(75395128L);
        notifications.setConditionCd("11065");
        notifications.setConditionDesc("Novel Coronavirus");
        notifications.setFirstNotificationStatus("APPROVED");
        notifications.setNotifRejectedCount(0L);
        notifications.setNotifCreatedCount(1L);
        notifications.setNotifSentCount(1L);
        notifications.setFirstNotificationSendDate("2025-02-25T20:01:14.210");
        notifications.setNotifCreatedPendingCount(0L);
        notifications.setLastNotificationDate("2025-02-25T16:28:18.923");
        notifications.setLastNotificationSendDate("2025-02-25T20:01:14.210");
        notifications.setFirstNotificationDate("2025-02-25T16:28:18.923");
        notifications.setFirstNotificationSubmittedBy(10055282L);
        notifications.setLastNotificationSubmittedBy(10055282L);
        notifications.setNotificationDate("2025-02-25T20:01:14.210");
        return notifications;
    }

    private @NotNull PageCaseAnswer constructCaseAnswer() {
        PageCaseAnswer expected = new PageCaseAnswer();
        expected.setNbsCaseAnswerUid(1235L);
        expected.setNbsUiMetadataUid(65497311L);
        expected.setNbsRdbMetadataUid(41201011L);
        expected.setRdbTableNm("D_INV_ADMINISTRATIVE");
        expected.setRdbColumnNm("ADM_IMMEDIATE_NND_DESC");
        expected.setCodeSetGroupId(null);
        expected.setAnswerTxt("notify test is success");
        expected.setActUid(INVESTIGATION_UID);
        expected.setRecordStatusCd("OPEN");
        expected.setNbsQuestionUid(12341438L);
        expected.setInvestigationFormCd("PG_Generic_V2_Investigation");
        expected.setUnitValue(null);
        expected.setQuestionIdentifier("QUE126");
        expected.setDataLocation("NBS_CASE_ANSWER.ANSWER_TXT");
        expected.setAnswerGroupSeqNbr(null);
        expected.setQuestionLabel("If yes, describe");
        expected.setOtherValueIndCd(null);
        expected.setUnitTypeCd(null);
        expected.setMask("TXT");
        expected.setBlockNm("BLOCK_8");
        expected.setQuestionGroupSeqNbr(null);
        expected.setDataType("TEXT");
        expected.setLastChgTime("2024-05-29T16:05:44.537");
        expected.setPartTypeCd(null);
        expected.setDatamartColumnNm("CASE_VERIFICATION");
        expected.setSeqNbr(0L);
        expected.setLdfStatusCd(null);
        expected.setNbsUiComponentUid(1007L);
        expected.setNcaAddTime("2025-03-24T15:54:58.623");
        expected.setNuimRecordStatusCd("Active");
        return expected;
    }

    private @NotNull InvestigationAggregate constructAggregate() {
        InvestigationAggregate expected = new InvestigationAggregate();
        expected.setActUid(INVESTIGATION_UID);
        expected.setNbsCaseAnswerUid(215086L);
        expected.setAnswerTxt("8");
        expected.setDataType("Numeric");
        expected.setDatamartColumnNm("TOTAL_COUNT_50_TO_64");
        return expected;
    }
}
