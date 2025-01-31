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
    private static final String INTERVIEW_NOTE_TOPIC = "interviewAnswersTopic";
    private static final String RDB_METADATA_COLS_TOPIC = "rdbMetadataColsTopic";
    private static final Long INVESTIGATION_UID = 234567890L;
    private static final Long INTERVIEW_UID = 234567890L;
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

        transformer.transformInvestigationData(investigation);
        verify(kafkaTemplate, times(4)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(CONFIRMATION_TOPIC, topicCaptor.getAllValues().getFirst());

        var actualConfirmationMethod = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(2)).path("payload").toString(), InvestigationConfirmationMethod.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(2)).path("payload").toString(), InvestigationConfirmationMethodKey.class);

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
        transformer.transformInvestigationData(investigation);
        transformer.processNotifications(INVALID_JSON);

        List<ILoggingEvent> logs = listAppender.list;
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains(INVALID_JSON)));
    }

    @Test
    void testInvestigationObservationIds() throws JsonProcessingException {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(INVESTIGATION_UID);
        investigation.setInvestigationObservationIds(readFileData(FILE_PREFIX + "InvestigationObservationIds.json"));
        transformer.investigationObservationOutputTopicName = OBSERVATION_TOPIC;

        InvestigationObservation observation = new InvestigationObservation();
        observation.setPublicHealthCaseUid(INVESTIGATION_UID);
        observation.setObservationId(10344738L);
        observation.setRootTypeCd("LabReport");
        observation.setBranchId(10344740L);
        observation.setBranchTypeCd("COMP");

        transformer.transformInvestigationData(investigation);
        verify(kafkaTemplate, times(9)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(OBSERVATION_TOPIC, topicCaptor.getAllValues().getFirst());

        var actualObservation = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(1)).path("payload").toString(), InvestigationObservation.class);

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

        final InterviewReporting interviewReportingValue = constructInvestigationInterview(INTERVIEW_UID);
        final InterviewAnswer interviewAnswerValue = constructInvestigationInterviewAnswer(INTERVIEW_UID);
        final InterviewNote interviewNoteValue = constructInvestigationInterviewNote(INTERVIEW_UID);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processInterview(interview);
        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(5)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );
        //test interview key
        var actualInterviewKey1 = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(0)).path("payload").toString(), InterviewReportingKey.class);
        //test interview key used for interview answer tombstone message
        var actualInterviewKey2 = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(1)).path("payload").toString(), InterviewReportingKey.class);
        //test interview key used for interview note tombstone message
        var actualInterviewKey3 = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(3)).path("payload").toString(), InterviewReportingKey.class);



        var actualInterviewValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(0)).path("payload").toString(), InterviewReporting.class);
        var actualInterviewAnswerValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(2)).path("payload").toString(), InterviewAnswer.class);
        var actualInterviewNoteValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(4)).path("payload").toString(), InterviewNote.class);


        assertEquals(interviewReportingKey, actualInterviewKey1);
        assertEquals(interviewReportingKey, actualInterviewKey2);
        assertEquals(interviewReportingKey, actualInterviewKey3);
        assertEquals(interviewReportingValue, actualInterviewValue);
        assertEquals(interviewAnswerValue, actualInterviewAnswerValue);
        assertEquals(interviewNoteValue, actualInterviewNoteValue);

    }

    @Test
    void testProcessInterviewAnswers() throws JsonProcessingException {

        final var interviewUid =  234567890L;
        final var interviewAnsColNm = "IX_CONTACTS_NAMED_IND";
        Interview interview = constructInterview(interviewUid);
        interview.setAnswers(readFileData(FILE_PREFIX + "InterviewAnswers.json"));

        transformer.setInterviewOutputTopicName(INTERVIEW_TOPIC);
        transformer.setInterviewAnswerOutputTopicName(INTERVIEW_ANSWERS_TOPIC);

        final InterviewReportingKey interviewReportingKey = new InterviewReportingKey();
        interviewReportingKey.setInterviewUid(interviewUid);

        final InterviewAnswerKey interviewAnswerKey = new InterviewAnswerKey();
        interviewAnswerKey.setInterviewUid(interviewUid);
        interviewAnswerKey.setRdbColumnNm(interviewAnsColNm);

        final InterviewReporting interviewReportingValue = constructInvestigationInterview(interviewUid);
        final InterviewAnswer interviewAnswerValue = constructInvestigationInterviewAnswer(interviewUid);


        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processInterview(interview);
        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(4)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        //interview key
        var actualInterviewKey1 = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(0)).path("payload").toString(), InterviewReportingKey.class);
        //interview value
        var actualInterviewValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(0)).path("payload").toString(), InterviewReporting.class);
        //interview key used for tombstone
        var actualInterviewKey2 = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(1)).path("payload").toString(), InterviewReportingKey.class);
        //interview answer key
        var actualInterviewAnswerKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(2)).path("payload").toString(), InterviewAnswerKey.class);
        //interview answer value
        var actualInterviewAnswerValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(2)).path("payload").toString(), InterviewAnswer.class);

        assertEquals(interviewReportingKey, actualInterviewKey1);
        assertEquals(interviewReportingKey, actualInterviewKey2);
        assertEquals(interviewReportingValue, actualInterviewValue);
        assertEquals(interviewAnswerKey, actualInterviewAnswerKey);
        assertEquals(interviewAnswerValue, actualInterviewAnswerValue);
    }


    @Test
    void testProcessInterviewNotes() throws JsonProcessingException {

        final var interviewUid =  234567890L;
        final var interviewAnsUid = 21L;
        Interview interview = constructInterview(interviewUid);
        interview.setNotes(readFileData(FILE_PREFIX + "InterviewNotes.json"));

        transformer.setInterviewOutputTopicName(INTERVIEW_TOPIC);
        transformer.setInterviewNoteOutputTopicName(INTERVIEW_NOTE_TOPIC);


        final InterviewReportingKey interviewReportingKey = new InterviewReportingKey();
        interviewReportingKey.setInterviewUid(interviewUid);
        final InterviewNoteKey interviewNoteKey = new InterviewNoteKey();
        interviewNoteKey.setInterviewUid(interviewUid);
        interviewNoteKey.setNbsAnswerUid(interviewAnsUid);

        final InterviewReporting interviewReportingValue = constructInvestigationInterview(interviewUid);
        final InterviewNote interviewNoteValue = constructInvestigationInterviewNote(interviewUid);

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));
        transformer.processInterview(interview);
        Awaitility.await()
                .atMost(1, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(kafkaTemplate, times(4)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture())
                );

        //interview key
        var actualInterviewKey1 = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(0)).path("payload").toString(), InterviewReportingKey.class);
        //interview value
        var actualInterviewValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(0)).path("payload").toString(), InterviewReporting.class);
        //interview key for tombstone message
        var actualInterviewKey2 = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(2)).path("payload").toString(), InterviewReportingKey.class);
        //interview note key
        var actualInterviewNoteKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(3)).path("payload").toString(), InterviewNoteKey.class);
        //interview note value
        var actualInterviewNoteValue = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(3)).path("payload").toString(), InterviewNote.class);


        assertEquals(interviewReportingKey, actualInterviewKey1);
        assertEquals(interviewReportingKey, actualInterviewKey2);
        assertEquals(interviewReportingValue, actualInterviewValue);
        assertEquals(interviewNoteKey, actualInterviewNoteKey);
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

        PageCaseAnswer caseAnswer = new PageCaseAnswer();
        caseAnswer.setActUid(INVESTIGATION_UID);

        PageCaseAnswerKey pageCaseAnswerKey = new PageCaseAnswerKey();
        pageCaseAnswerKey.setActUid(INVESTIGATION_UID);
        pageCaseAnswerKey.setNbsCaseAnswerUid(1235L);

        PageCaseAnswer pageCaseAnswer = constructCaseAnswer();

        transformer.transformInvestigationData(investigation);
        verify(kafkaTemplate, times(6)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(PAGE_CASE_ANSWER_TOPIC, topicCaptor.getValue());

        var actualPageCaseAnswer = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getAllValues().get(3)).path("payload").toString(), PageCaseAnswer.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getAllValues().get(3)).path("payload").toString(), PageCaseAnswerKey.class);

        assertEquals(pageCaseAnswerKey, actualKey);
        assertEquals(pageCaseAnswer, actualPageCaseAnswer);

        JsonNode keyNode = objectMapper.readTree(keyCaptor.getValue()).path("schema").path("fields");
        assertFalse(keyNode.get(0).path("optional").asBoolean());
        assertTrue(keyNode.get(1).path("optional").asBoolean());

        InvestigationTransformed investigationTransformed = transformer.transformInvestigationData(investigation);
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

    private Interview constructInterview(Long interviewUid) {
        Interview interview = new Interview();
        interview.setInterviewUid(interviewUid);
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

    private InterviewReporting constructInvestigationInterview(Long interviewUid) {
        InterviewReporting interviewReporting = new InterviewReporting();
        interviewReporting.setInterviewUid(interviewUid);
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

    private InterviewAnswer constructInvestigationInterviewAnswer(Long interviewUid) {
        InterviewAnswer interviewAnswer = new InterviewAnswer();
        interviewAnswer.setInterviewUid(interviewUid);
        interviewAnswer.setAnswerVal("Yes");
        interviewAnswer.setRdbColumnNm("IX_CONTACTS_NAMED_IND");
        return interviewAnswer;
    }

    private InterviewNote constructInvestigationInterviewNote(Long interviewUid) {
        InterviewNote interviewNote = new InterviewNote();
        interviewNote.setInterviewUid(interviewUid);
        interviewNote.setNbsAnswerUid(21L);
        interviewNote.setCommentDate("2024-11-13T15:27:00");
        interviewNote.setUserFirstName("super");
        interviewNote.setUserLastName("user");
        interviewNote.setUserComment("Test123");
        interviewNote.setRecordStatusCd("");
        return interviewNote;
    }

}
