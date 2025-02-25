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
import org.awaitility.Awaitility;
import org.springframework.kafka.support.SendResult;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
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
    private static final String CASE_MANAGEMENT_TOPIC = "caseManagementTopic";
    private static final String INTERVIEW_TOPIC = "interviewTopic";
    private static final String INTERVIEW_ANSWERS_TOPIC = "interviewAnswersTopic";
    private static final String INTERVIEW_NOTE_TOPIC = "interviewNoteTopic";
    private static final String RDB_METADATA_COLS_TOPIC = "rdbMetadataColsTopic";
    private static final String CONTACT_TOPIC = "contactTopic";
    private static final String CONTACT_ANSWERS_TOPIC = "contactAnswersTopic";
    private static final String TREATMENT_TOPIC = "treatmentTopic";
    private static final Long INVESTIGATION_UID = 234567890L;
    private static final Long INTERVIEW_UID = 234567890L;
    private static final Long CONTACT_UID = 12345678L;
    private static final Long TREATMENT_UID = 34567890L;
    private static final String INVALID_JSON = "invalidJSON";
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

        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));
        when(kafkaTemplate.send(anyString(), anyString(), notNull())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.setInvestigationObservationOutputTopicName(OBSERVATION_TOPIC);
        transformer.setPageCaseAnswerOutputTopicName(PAGE_CASE_ANSWER_TOPIC);
        transformer.transformInvestigationData(investigation);

        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(5)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        assertEquals(CONFIRMATION_TOPIC, topicCaptor.getAllValues().get(1));

        var actualConfirmationMethod = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(4)).path("payload").toString(), InvestigationConfirmationMethod.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(4)).path("payload").toString(), InvestigationConfirmationMethodKey.class);

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
        investigation.setInvestigationCaseCnt(INVALID_JSON);

        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.setInvestigationObservationOutputTopicName(OBSERVATION_TOPIC);
        transformer.setPageCaseAnswerOutputTopicName(PAGE_CASE_ANSWER_TOPIC);
        transformer.setInvestigationConfirmationOutputTopicName(CONFIRMATION_TOPIC);
        transformer.transformInvestigationData(investigation);
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

        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));
        when(kafkaTemplate.send(anyString(), anyString(), notNull())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.transformInvestigationData(investigation);

        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(9)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        assertEquals(OBSERVATION_TOPIC, topicCaptor.getAllValues().getFirst());

        var actualObservation = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(3)).path("payload").toString(), InvestigationObservation.class);

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

        Interview interview = constructInterview();
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

        final InterviewReporting interviewReportingValue = constructInvestigationInterview();
        final InterviewAnswer interviewAnswerValue = constructInvestigationInterviewAnswer();
        final InterviewNote interviewNoteValue = constructInvestigationInterviewNote();

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.processInterview(interview);
        Awaitility.await()
                .atMost(2, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(5)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        //test interview key
        InterviewReportingKey actualInterviewKey1 = null;
        //interview key used for interview answer tombstone message
        InterviewReportingKey actualInterviewKey2 = null;
        //interview key used for interview note tombstone message
        InterviewReportingKey actualInterviewKey3 = null;

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
                    actualInterviewKey1 = objectMapper.readValue(
                            objectMapper.readTree(keys.get(i)).path("payload").toString(),
                            InterviewReportingKey.class);
                    actualInterviewValue = objectMapper.readValue(
                            objectMapper.readTree(messages.get(i)).path("payload").toString(),
                            InterviewReporting.class);
                    break;
                case INTERVIEW_ANSWERS_TOPIC:
                    if (messages.get(i) == null) {
                        actualInterviewKey2 = objectMapper.readValue(
                                objectMapper.readTree(keys.get(i)).path("payload").toString(),
                                InterviewReportingKey.class);
                    } else {
                        actualInterviewAnswerKey = objectMapper.readValue(
                                objectMapper.readTree(keys.get(i)).path("payload").toString(),
                                InterviewAnswerKey.class);
                        actualInterviewAnswerValue = objectMapper.readValue(
                                objectMapper.readTree(messages.get(i)).path("payload").toString(),
                                InterviewAnswer.class);
                    }
                    break;
                case INTERVIEW_NOTE_TOPIC:
                    if (messages.get(i) == null) {
                        actualInterviewKey3 = objectMapper.readValue(
                                objectMapper.readTree(keys.get(i)).path("payload").toString(),
                                InterviewReportingKey.class);
                    } else {
                        actualInterviewNoteKey = objectMapper.readValue(
                                objectMapper.readTree(keys.get(i)).path("payload").toString(),
                                InterviewNoteKey.class);
                        actualInterviewNoteValue = objectMapper.readValue(
                                objectMapper.readTree(messages.get(i)).path("payload").toString(),
                                InterviewNote.class);
                    }
                    break;
                default:
                    break;
            }
        }

        assertEquals(interviewReportingKey, actualInterviewKey1);
        assertEquals(interviewReportingKey, actualInterviewKey2);
        assertEquals(interviewReportingKey, actualInterviewKey3);

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
        Interview interview = constructInterview();
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
        metadataColumnValue.setNewFlag(1);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processColumnMetadata(interview.getRdbCols(), interview.getInterviewUid());
        verify(kafkaTemplate, times (1)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

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
        interview.setInterviewUid(INTERVIEW_UID);

        interview.setAnswers(INVALID_JSON);
        interview.setNotes(INVALID_JSON);
        transformer.setInterviewOutputTopicName(INTERVIEW_TOPIC);
        transformer.setInterviewAnswerOutputTopicName(INTERVIEW_ANSWERS_TOPIC);
        transformer.setInterviewNoteOutputTopicName(INTERVIEW_NOTE_TOPIC);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processInterview(interview);
        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(3)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        ILoggingEvent log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains(INVALID_JSON));
    }

    @Test
    void testProcessContacts() throws JsonProcessingException {

        Contact contact = constructContact();
        contact.setAnswers(readFileData(FILE_PREFIX + "ContactAnswers.json"));
        transformer.setContactOutputTopicName(CONTACT_TOPIC);
        transformer.setContactAnswerOutputTopicName(CONTACT_ANSWERS_TOPIC);

        final  ContactReportingKey contactReportingKey = new ContactReportingKey();
        contactReportingKey.setContactUid(CONTACT_UID);
        final ContactReporting  contactReportingValue = constructContactReporting();

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processContact(contact);
        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        var actualContactKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().getFirst()).path("payload").toString(), ContactReportingKey.class);

        var actualContactValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().getFirst()).path("payload").toString(), ContactReporting.class);

        assertEquals(contactReportingKey, actualContactKey);
        assertEquals(contactReportingValue, actualContactValue);
    }

    @Test
    void testProcessContactAnswers() throws JsonProcessingException {

        Contact contact = constructContact();
        contact.setAnswers(readFileData(FILE_PREFIX + "ContactAnswers.json"));
        transformer.setContactOutputTopicName(CONTACT_TOPIC);
        transformer.setContactAnswerOutputTopicName(CONTACT_ANSWERS_TOPIC);

        final  ContactReportingKey contactReportingKey = new ContactReportingKey();
        contactReportingKey.setContactUid(CONTACT_UID);

        final  ContactAnswerKey contactAnswerKey = new ContactAnswerKey();
        contactAnswerKey.setContactUid(CONTACT_UID);
        contactAnswerKey.setRdbColumnNm("CTT_EXPOSURE_TYPE");

        final ContactReporting  contactReportingValue = constructContactReporting();
        final ContactAnswer contactAnswerValue = constructContactAnswers();

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processContact(contact);
        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        //contact key
        var actualContactKey1 = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(0)).path("payload").toString(), ContactReportingKey.class);
        //contact value
        var actualContactValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(0)).path("payload").toString(), ContactReporting.class);

        //contact answer key
        var actualContactAnswerKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(1)).path("payload").toString(), ContactAnswerKey.class);
        //contact answer value
        var actualContactAnswerValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(1)).path("payload").toString(), ContactAnswer.class);

        assertEquals(contactReportingKey, actualContactKey1);
        assertEquals(contactReportingValue, actualContactValue);
        assertEquals(contactAnswerKey, actualContactAnswerKey);
        assertEquals(contactAnswerValue, actualContactAnswerValue);
    }

    @Test
    void testProcessContactError(){

        Contact contact = new Contact();
        contact.setContactUid(CONTACT_UID);
        contact.setAnswers(INVALID_JSON);

        transformer.setContactOutputTopicName(CONTACT_TOPIC);
        transformer.setContactAnswerOutputTopicName(CONTACT_ANSWERS_TOPIC);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processContact(contact);
        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(1)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        ILoggingEvent log = listAppender.list.getLast();
        assertTrue(log.getFormattedMessage().contains(INVALID_JSON));
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
        transformer.setInvestigationObservationOutputTopicName(NOTIFICATIONS_TOPIC);
        transformer.setPageCaseAnswerOutputTopicName(PAGE_CASE_ANSWER_TOPIC);
        transformer.setInvestigationConfirmationOutputTopicName(CONFIRMATION_TOPIC);

        PageCaseAnswer caseAnswer = new PageCaseAnswer();
        caseAnswer.setActUid(INVESTIGATION_UID);

        PageCaseAnswerKey pageCaseAnswerKey = new PageCaseAnswerKey();
        pageCaseAnswerKey.setActUid(INVESTIGATION_UID);
        pageCaseAnswerKey.setNbsCaseAnswerUid(1235L);

        PageCaseAnswer pageCaseAnswer = constructCaseAnswer();

        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));
        InvestigationTransformed investigationTransformed = transformer.transformInvestigationData(investigation);

        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(7)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );
        assertEquals(PAGE_CASE_ANSWER_TOPIC, topicCaptor.getValue());

        var actualPageCaseAnswer = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(4)).path("payload").toString(), PageCaseAnswer.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(4)).path("payload").toString(), PageCaseAnswerKey.class);

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
    void testProcessCaseManagement() throws JsonProcessingException {

        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationCaseManagement(readFileData(FILE_PREFIX + "CaseManagement.json"));
        transformer.setInvestigationCaseManagementTopicName(CASE_MANAGEMENT_TOPIC);
        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        var caseManagementKey = new InvestigationCaseManagementKey(INVESTIGATION_UID, 1001L);
        var caseManagement = constructCaseManagement();

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
        verify(kafkaTemplate, never()).send(eq(CASE_MANAGEMENT_TOPIC), anyString(), anyString());
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
        return expected;
    }

    private InvestigationCaseManagement constructCaseManagement() {
        InvestigationCaseManagement expected = new InvestigationCaseManagement();
        expected.setCaseManagementUid(1001L);
        expected.setPublicHealthCaseUid(INVESTIGATION_UID);
        expected.setAddUserId(10055001L);
        expected.setCaseOid(1300110031L);
        expected.setInitFupInitialFollUpCd("SF");
        expected.setInitFupInitialFollUp("Surveillance Follow-up");
        expected.setInitFupInternetFollUpCd("N");
        expected.setInternetFollUp("No");
        expected.setInitFupNotifiableCd("06");
        expected.setInitFollUpNotifiable("6-Yes, Notifiable");
        expected.setInitFupClinicCode("80000");
        expected.setSurvInvestigatorAssgnDt("2024-07-15T00:00:00");
        expected.setSurvClosedDt("2024-07-22T00:00:00");
        expected.setSurvProviderContactCd("S");
        expected.setSurvProviderContact("S - Successful");
        expected.setSurvProvExmReason("M");
        expected.setSurvProviderExamReason("Community Screening");
        expected.setSurvProviderDiagnosis("900");
        expected.setSurvPatientFollUp("FF");
        expected.setSurvPatientFollUpCd("Field Follow-up");
        expected.setAdi900StatusCd("02");
        expected.setStatus900("2 - Newly Diagnosed");
        expected.setFlFupFieldRecordNum("1310005124");
        expected.setFlFupInvestigatorAssgnDt("2024-07-23T00:00:00");
        expected.setFlFupInitAssgnDt("2024-07-23T00:00:00");
        expected.setFldFollUpProvExmReason("M");
        expected.setFlFupProvExmReason("Community Screening");
        expected.setFldFollUpProvDiagnosis("900");
        expected.setFlFupProvDiagnosis("900");
        expected.setFldFollUpNotificationPlan("3");
        expected.setFlFupNotificationPlanCd("3 - Dual");
        expected.setFldFollUpExpectedIn("Y");
        expected.setFlFupExpectedInInd("Yes");
        expected.setFlFupExpectedDt("2024-07-21T00:00:00");
        expected.setFlFupExamDt("2024-07-19T00:00:00");
        expected.setFlFupDispositionCd("1");
        expected.setFlFupDispositionDesc("1 - Prev. Pos");
        expected.setFlFupDispoDt("2024-07-23T00:00:00");
        expected.setActRefTypeCd("2");
        expected.setFlFupActualRefType("2 - Provider");
        expected.setFlFupInternetOutcomeCd("I1");
        expected.setFlFupInternetOutcome("I1 - Informed, Urgent Health Matter");
        expected.setCaInterviewerAssignDt("2024-07-22T00:00:00");
        expected.setCaInitIntvwrAssgnDt("2024-07-22T00:00:00");
        expected.setEpiLinkId("1310005124");
        expected.setPatIntvStatusCd("A");
        expected.setCaPatientIntvStatus("A - Awaiting");
        expected.setInitiatingAgncy("Arizona");
        expected.setOojInitgAgncyRecdDate("2024-07-15T00:00:00");
        return expected;
    }

    private Interview constructInterview() {
        Interview interview = new Interview();
        interview.setInterviewUid(INTERVIEW_UID);
        interview.setInterviewDate("2024-11-11 00:00:00.000");
        interview.setInterviewStatusCd("COMPLETE");
        interview.setInterviewLocCd("C");
        interview.setInterviewTypeCd("REINTVW");
        interview.setIntervieweeRoleCd("SUBJECT");
        interview.setIxIntervieweeRole("Subject of Investigation");
        interview.setIxLocation("Clinic");
        interview.setIxStatus("Closed/Completed");
        interview.setIxType("Re-Interview");
        interview.setLastChgTime("2024-11-13 20:27:39.587");
        interview.setAddTime("2024-11-13 20:27:39.587");
        interview.setAddUserId(10055282L);
        interview.setLastChgUserId(10055282L);
        interview.setLocalId("INT10099004GA01");
        interview.setRecordStatusCd("ACTIVE");
        interview.setRecordStatusTime("2024-11-13 20:27:39.587");
        interview.setVersionCtrlNbr(1L);
        return interview;
    }

    private InterviewReporting constructInvestigationInterview() {
        InterviewReporting interviewReporting = new InterviewReporting();
        interviewReporting.setInterviewUid(INTERVIEW_UID);
        interviewReporting.setInterviewDate("2024-11-11 00:00:00.000");
        interviewReporting.setInterviewStatusCd("COMPLETE");
        interviewReporting.setInterviewLocCd("C");
        interviewReporting.setInterviewTypeCd("REINTVW");
        interviewReporting.setIntervieweeRoleCd("SUBJECT");
        interviewReporting.setIxIntervieweeRole("Subject of Investigation");
        interviewReporting.setIxLocation("Clinic");
        interviewReporting.setIxStatus("Closed/Completed");
        interviewReporting.setIxType("Re-Interview");
        interviewReporting.setLastChgTime("2024-11-13 20:27:39.587");
        interviewReporting.setAddTime("2024-11-13 20:27:39.587");
        interviewReporting.setAddUserId(10055282L);
        interviewReporting.setLastChgUserId(10055282L);
        interviewReporting.setLocalId("INT10099004GA01");
        interviewReporting.setRecordStatusCd("ACTIVE");
        interviewReporting.setRecordStatusTime("2024-11-13 20:27:39.587");
        interviewReporting.setVersionCtrlNbr(1L);
        return interviewReporting;
    }

    private InterviewAnswer constructInvestigationInterviewAnswer() {
        InterviewAnswer interviewAnswer = new InterviewAnswer();
        interviewAnswer.setInterviewUid(INTERVIEW_UID);
        interviewAnswer.setAnswerVal("Yes");
        interviewAnswer.setRdbColumnNm("IX_CONTACTS_NAMED_IND");
        return interviewAnswer;
    }

    private InterviewNote constructInvestigationInterviewNote() {
        InterviewNote interviewNote = new InterviewNote();
        interviewNote.setInterviewUid(INTERVIEW_UID);
        interviewNote.setNbsAnswerUid(21L);
        interviewNote.setCommentDate("2024-11-13T15:27:00");
        interviewNote.setUserFirstName("super");
        interviewNote.setUserLastName("user");
        interviewNote.setUserComment("Test123");
        interviewNote.setRecordStatusCd("");
        return interviewNote;
    }

    private Contact constructContact() {
        Contact contact = new Contact();
        contact.setContactUid(CONTACT_UID);
        contact.setAddTime("2024-01-01T10:00:00");
        contact.setAddUserId(100L);
        contact.setContactEntityEpiLinkId("EPI123");
        contact.setContactEntityPhcUid(1L);
        contact.setContactEntityUid(1L);
        contact.setCttReferralBasis("Referral");
        contact.setCttStatus("Active");
        contact.setCttDispoDt("2024-01-10");
        contact.setCttDisposition("Completed");
        contact.setCttEvalCompleted("Yes");
        contact.setCttEvalDt("2024-01-05");
        contact.setCttEvalNotes("Evaluation completed successfully.");
        contact.setCttGroupLotId("LOT123");
        contact.setCttHealthStatus("Good");
        contact.setCttInvAssignedDt("2024-01-02");
        contact.setCttJurisdictionNm("JurisdictionA");
        contact.setCttNamedOnDt("2024-01-03");
        contact.setCttNotes("General notes.");
        contact.setCttPriority("High");
        contact.setCttProcessingDecision("Approved");
        contact.setCttProgramArea("ProgramX");
        contact.setCttRelationship("Close Contact");
        contact.setCttRiskInd("Low");
        contact.setCttRiskNotes("Minimal risk identified.");
        contact.setCttSharedInd("Yes");
        contact.setCttSympInd("No");
        contact.setCttSympNotes("No symptoms reported.");
        contact.setCttSympOnsetDt(null);
        contact.setThirdPartyEntityPhcUid(1L);
        contact.setThirdPartyEntityUid(1L);
        contact.setCttTrtCompleteInd("Yes");
        contact.setCttTrtEndDt("2024-02-01");
        contact.setCttTrtInitiatedInd("Yes");
        contact.setCttTrtNotCompleteRsn(null);
        contact.setCttTrtNotStartRsn(null);
        contact.setCttTrtNotes("Treatment completed successfully.");
        contact.setCttTrtStartDt("2024-01-15");
        contact.setLastChgTime("2024-02-05T12:00:00");
        contact.setLastChgUserId(200L);
        contact.setLocalId("LOC456");
        contact.setNamedDuringInterviewUid(1L);
        contact.setProgramJurisdictionOid(300L);
        contact.setRecordStatusCd("Active");
        contact.setRecordStatusTime("2024-02-06T08:00:00");
        contact.setSubjectEntityEpiLinkId("EPI456");
        contact.setSubjectEntityPhcUid(10L);
        contact.setVersionCtrlNbr(1L);
        contact.setContactExposureSiteUid(123L);
        contact.setProviderContactInvestigatorUid(1234L);
        contact.setDispositionedByUid(123L);
        return contact;
    }

    private ContactReporting constructContactReporting() {
        ContactReporting contactReporting = new ContactReporting();
        contactReporting.setContactUid(CONTACT_UID);
        contactReporting.setAddTime("2024-01-01T10:00:00");
        contactReporting.setAddUserId(100L);
        contactReporting.setContactEntityEpiLinkId("EPI123");
        contactReporting.setContactEntityPhcUid(1L);
        contactReporting.setContactEntityUid(1L);
        contactReporting.setCttReferralBasis("Referral");
        contactReporting.setCttStatus("Active");
        contactReporting.setCttDispoDt("2024-01-10");
        contactReporting.setCttDisposition("Completed");
        contactReporting.setCttEvalCompleted("Yes");
        contactReporting.setCttEvalDt("2024-01-05");
        contactReporting.setCttEvalNotes("Evaluation completed successfully.");
        contactReporting.setCttGroupLotId("LOT123");
        contactReporting.setCttHealthStatus("Good");
        contactReporting.setCttInvAssignedDt("2024-01-02");
        contactReporting.setCttJurisdictionNm("JurisdictionA");
        contactReporting.setCttNamedOnDt("2024-01-03");
        contactReporting.setCttNotes("General notes.");
        contactReporting.setCttPriority("High");
        contactReporting.setCttProcessingDecision("Approved");
        contactReporting.setCttProgramArea("ProgramX");
        contactReporting.setCttRelationship("Close Contact");
        contactReporting.setCttRiskInd("Low");
        contactReporting.setCttRiskNotes("Minimal risk identified.");
        contactReporting.setCttSharedInd("Yes");
        contactReporting.setCttSympInd("No");
        contactReporting.setCttSympNotes("No symptoms reported.");
        contactReporting.setCttSympOnsetDt(null);
        contactReporting.setThirdPartyEntityPhcUid(1L);
        contactReporting.setThirdPartyEntityUid(1L);
        contactReporting.setCttTrtCompleteInd("Yes");
        contactReporting.setCttTrtEndDt("2024-02-01");
        contactReporting.setCttTrtInitiatedInd("Yes");
        contactReporting.setCttTrtNotCompleteRsn(null);
        contactReporting.setCttTrtNotStartRsn(null);
        contactReporting.setCttTrtNotes("Treatment completed successfully.");
        contactReporting.setCttTrtStartDt("2024-01-15");
        contactReporting.setLastChgTime("2024-02-05T12:00:00");
        contactReporting.setLastChgUserId(200L);
        contactReporting.setLocalId("LOC456");
        contactReporting.setNamedDuringInterviewUid(1L);
        contactReporting.setProgramJurisdictionOid(300L);
        contactReporting.setRecordStatusCd("Active");
        contactReporting.setRecordStatusTime("2024-02-06T08:00:00");
        contactReporting.setSubjectEntityEpiLinkId("EPI456");
        contactReporting.setSubjectEntityPhcUid(10L);
        contactReporting.setVersionCtrlNbr(1L);
        contactReporting.setContactExposureSiteUid(123L);
        contactReporting.setProviderContactInvestigatorUid(1234L);
        contactReporting.setDispositionedByUid(123L);
        return contactReporting;
    }

    private ContactAnswer constructContactAnswers() {
        ContactAnswer contactAnswer = new ContactAnswer();
        contactAnswer.setContactUid(CONTACT_UID);
        contactAnswer.setAnswerVal("Common Space");
        contactAnswer.setRdbColumnNm("CTT_EXPOSURE_TYPE");
        return contactAnswer;
    }

    @Test
    void testProcessTreatment() throws JsonProcessingException {
        transformer.setTreatmentOutputTopicName(TREATMENT_TOPIC);

        Treatment treatment = constructTreatment();

        final TreatmentReportingKey treatmentReportingKey = new TreatmentReportingKey();
        treatmentReportingKey.setTreatmentUid(treatment.getTreatmentUid());
        final TreatmentReporting treatmentReportingValue = constructTreatmentReporting();

        CompletableFuture<SendResult<String, String>> future = new CompletableFuture<>();

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(future);
        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(future);

        transformer.processTreatment(treatment);

        future.complete(null);

        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        assertEquals(TREATMENT_TOPIC, topicCaptor.getAllValues().get(0));
        assertEquals(TREATMENT_TOPIC, topicCaptor.getAllValues().get(1));

        assertNull(messageCaptor.getAllValues().get(0));

        String firstKey = keyCaptor.getAllValues().get(0);
        String secondKey = keyCaptor.getAllValues().get(1);

        var firstKeyObj = objectMapper.readValue(
                objectMapper.readTree(firstKey).path("payload").toString(),
                TreatmentReportingKey.class);
        var secondKeyObj = objectMapper.readValue(
                objectMapper.readTree(secondKey).path("payload").toString(),
                TreatmentReportingKey.class);

        assertEquals(treatmentReportingKey, firstKeyObj);
        assertEquals(treatmentReportingKey, secondKeyObj);

        String treatmentJson = messageCaptor.getAllValues().get(1);
        var actualTreatmentValue = objectMapper.readValue(
                objectMapper.readTree(treatmentJson).path("payload").toString(),
                TreatmentReporting.class);

        assertEquals(treatmentReportingValue, actualTreatmentValue);
    }

    @Test
    void testProcessTreatmentError() {
        Treatment treatment = new Treatment();
        // Setup to throw an exception during processing,no uid set
        transformer.setTreatmentOutputTopicName(TREATMENT_TOPIC);
        when(kafkaTemplate.send(anyString(), anyString(), isNull())).thenReturn(CompletableFuture.completedFuture(null));
        try {
            transformer.processTreatment(treatment);
        } catch (Exception e) {
        }
        List<ILoggingEvent> logs = listAppender.list;
        boolean foundErrorLog = logs.stream()
                .map(ILoggingEvent::getFormattedMessage)
                .anyMatch(m -> m.contains("Error processing Treatment data"));

        assertTrue(foundErrorLog, "Error processing Treatment data");

    }


    private Treatment constructTreatment() {
        Treatment treatment = new Treatment();
        treatment.setTreatmentUid(TREATMENT_UID.toString());
        treatment.setPublicHealthCaseUid("12345");
        treatment.setOrganizationUid("67890");
        treatment.setProviderUid("11111");
        treatment.setPatientTreatmentUid("22222");
        treatment.setTreatmentName("Test Treatment");
        treatment.setTreatmentOid("33333");
        treatment.setTreatmentComments("Test Comments");
        treatment.setTreatmentSharedInd("Y");
        treatment.setCd("TEST_CD");
        treatment.setTreatmentDate("2024-01-01T10:00:00");
        treatment.setTreatmentDrug("Drug123");
        treatment.setTreatmentDrugName("Test Drug");
        treatment.setTreatmentDosageStrength("100");
        treatment.setTreatmentDosageStrengthUnit("mg");
        treatment.setTreatmentFrequency("Daily");
        treatment.setTreatmentDuration("7");
        treatment.setTreatmentDurationUnit("days");
        treatment.setTreatmentRoute("Oral");
        treatment.setLocalId("LOC123");
        treatment.setRecordStatusCd("Active");
        treatment.setAddTime("2024-01-01T10:00:00");
        treatment.setAddUserId("44444");
        treatment.setLastChangeTime("2024-01-01T10:00:00");
        treatment.setLastChangeUserId("55555");
        treatment.setVersionControlNumber("1");
        return treatment;
    }

    private TreatmentReporting constructTreatmentReporting() {
        TreatmentReporting treatmentReporting = new TreatmentReporting();
        treatmentReporting.setTreatmentUid(TREATMENT_UID.toString());
        treatmentReporting.setPublicHealthCaseUid("12345");
        treatmentReporting.setOrganizationUid("67890");
        treatmentReporting.setProviderUid("11111");
        treatmentReporting.setPatientTreatmentUid("22222");
        treatmentReporting.setTreatmentName("Test Treatment");
        treatmentReporting.setTreatmentOid("33333");
        treatmentReporting.setTreatmentComments("Test Comments");
        treatmentReporting.setTreatmentSharedInd("Y");
        treatmentReporting.setCd("TEST_CD");
        treatmentReporting.setTreatmentDate("2024-01-01T10:00:00");
        treatmentReporting.setTreatmentDrug("Drug123");
        treatmentReporting.setTreatmentDrugName("Test Drug");
        treatmentReporting.setTreatmentDosageStrength("100");
        treatmentReporting.setTreatmentDosageStrengthUnit("mg");
        treatmentReporting.setTreatmentFrequency("Daily");
        treatmentReporting.setTreatmentDuration("7");
        treatmentReporting.setTreatmentDurationUnit("days");
        treatmentReporting.setTreatmentRoute("Oral");
        treatmentReporting.setLocalId("LOC123");
        treatmentReporting.setRecordStatusCd("Active");
        treatmentReporting.setAddTime("2024-01-01T10:00:00");
        treatmentReporting.setAddUserId("44444");
        treatmentReporting.setLastChangeTime("2024-01-01T10:00:00");
        treatmentReporting.setLastChangeUserId("55555");
        treatmentReporting.setVersionControlNumber("1");
        return treatmentReporting;
    }
}
