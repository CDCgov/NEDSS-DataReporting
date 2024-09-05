package gov.cdc.etldatapipeline.investigation;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.*;
import gov.cdc.etldatapipeline.investigation.repository.rdb.InvestigationCaseAnswerRepository;
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

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.*;

class InvestigationDataProcessingTests {
    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Mock
    InvestigationCaseAnswerRepository investigationCaseAnswerRepository;

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
    private static final Long investigationUid = 234567890L;

    ProcessInvestigationDataUtil transformer;

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        transformer = new ProcessInvestigationDataUtil(kafkaTemplate, investigationCaseAnswerRepository);
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

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setInvestigationConfirmationMethod(readFileData(FILE_PREFIX + "ConfirmationMethod.json"));
        transformer.investigationConfirmationOutputTopicName = CONFIRMATION_TOPIC;

        InvestigationConfirmationMethodKey confirmationMethodKey = new InvestigationConfirmationMethodKey();
        confirmationMethodKey.setPublicHealthCaseUid(investigationUid);
        confirmationMethodKey.setConfirmationMethodCd("LD");

        InvestigationConfirmationMethod confirmationMethod = new InvestigationConfirmationMethod();
        confirmationMethod.setPublicHealthCaseUid(investigationUid);
        confirmationMethod.setConfirmationMethodCd("LD");
        confirmationMethod.setConfirmationMethodDescTxt("Laboratory confirmed");
        confirmationMethod.setConfirmationMethodTime("2024-01-15T10:20:57.001");

        transformer.transformInvestigationData(investigation);
        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(CONFIRMATION_TOPIC, topicCaptor.getValue());

        var actualConfirmationMethod = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), InvestigationConfirmationMethod.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getValue()).path("payload").toString(), InvestigationConfirmationMethodKey.class);

        assertEquals(confirmationMethodKey, actualKey);
        assertEquals(confirmationMethod, actualConfirmationMethod);
    }

    @Test
    void testTransformInvestigationError(){
        Investigation investigation = new Investigation();
        investigation.setPublicHealthCaseUid(investigationUid);
        String invalidJSON = "invalidJSON";

        investigation.setPersonParticipations(invalidJSON);
        investigation.setOrganizationParticipations(invalidJSON);
        investigation.setActIds(invalidJSON);
        investigation.setObservationNotificationIds(invalidJSON);
        investigation.setInvestigationConfirmationMethod(invalidJSON);
        investigation.setInvestigationCaseAnswer(invalidJSON);

        transformer.transformInvestigationData(investigation);
        transformer.processNotifications(invalidJSON, objectMapper);

        List<ILoggingEvent> logs = listAppender.list;
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains(invalidJSON)));
    }

        @Test
    void testObservationNotificationIds() throws JsonProcessingException {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setObservationNotificationIds(readFileData(FILE_PREFIX + "ObservationNotificationIds.json"));
        transformer.investigationObservationOutputTopicName = OBSERVATION_TOPIC;

        InvestigationObservation observation = new InvestigationObservation();
        observation.setPublicHealthCaseUid(investigationUid);
        observation.setObservationId(263748596L);

        transformer.transformInvestigationData(investigation);
        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(OBSERVATION_TOPIC, topicCaptor.getValue());

        var actualObservation = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), InvestigationObservation.class);

        assertEquals(observation, actualObservation);
    }

    @Test
    void testProcessNotifications() throws JsonProcessingException {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setInvestigationNotifications(readFileData(FILE_PREFIX + "InvestigationNotifications.json"));
        transformer.investigationNotificationsOutputTopicName = NOTIFICATIONS_TOPIC;

        final var notifications = constructNotifications();

        InvestigationNotificationsKey notificationKey = new InvestigationNotificationsKey();
        notificationKey.setNotificationUid(notifications.getNotificationUid());

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.processNotifications(investigation.getInvestigationNotifications(), new ObjectMapper());
        verify(kafkaTemplate, times (1)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(NOTIFICATIONS_TOPIC, topicCaptor.getValue());

        var actualNotifications = objectMapper.readValue(
                objectMapper.readTree(messageCaptor.getValue()).path("payload").toString(), InvestigationNotifications.class);
        var actualKey = objectMapper.readValue(
                objectMapper.readTree(keyCaptor.getValue()).path("payload").toString(), InvestigationNotificationsKey.class);

        assertEquals(notificationKey, actualKey);
        assertEquals(notifications, actualNotifications);
    }

    @Test
    void testProcessMissingOrInvalidNotifications() {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setInvestigationNotifications(null);
        transformer.investigationNotificationsOutputTopicName = NOTIFICATIONS_TOPIC;
        transformer.processNotifications(null, new ObjectMapper());
        transformer.processNotifications("{\"foo\":\"bar\"}", new ObjectMapper());
        verify(kafkaTemplate, never()).send(eq(NOTIFICATIONS_TOPIC), anyString(), anyString());
    }

    @Test
    void testProcessInvestigationCaseAnswers() {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setInvestigationCaseAnswer(readFileData(FILE_PREFIX + "InvestigationCaseAnswers.json"));

        InvestigationCaseAnswer caseAnswer = new InvestigationCaseAnswer();
        caseAnswer.setActUid(investigationUid);

        transformer.transformInvestigationData(investigation);

        when(investigationCaseAnswerRepository.findByActUid(investigationUid)).thenReturn(new ArrayList<>());

        verify(investigationCaseAnswerRepository).findByActUid(investigationUid);
        verify(investigationCaseAnswerRepository, never()).deleteByActUid(anyLong());
        verify(investigationCaseAnswerRepository).saveAll(anyList());
    }

    @Test
    void testInvestigationCaseAnswerExistingRecords() {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setInvestigationCaseAnswer(readFileData(FILE_PREFIX + "InvestigationCaseAnswers.json"));

        InvestigationCaseAnswer caseAnswer = new InvestigationCaseAnswer();
        caseAnswer.setActUid(investigationUid);

        List<InvestigationCaseAnswer> investigationCaseAnswerDataIfPresent = new ArrayList<>();
        investigationCaseAnswerDataIfPresent.add(new InvestigationCaseAnswer());
        when(investigationCaseAnswerRepository.findByActUid(investigationUid)).thenReturn(investigationCaseAnswerDataIfPresent);

        InvestigationTransformed investigationTransformed = transformer.transformInvestigationData(investigation);
        assertEquals("D_INV_CLINICAL,D_INV_ADMINISTRATIVE", investigationTransformed.getRdbTableNameList());

        verify(investigationCaseAnswerRepository).findByActUid(investigationUid);
        verify(investigationCaseAnswerRepository).deleteByActUid(investigationUid);
        verify(investigationCaseAnswerRepository).saveAll(anyList());
    }

    @Test
    void testInvestigationCaseAnswerInvalidJson() {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setInvestigationCaseAnswer("{ invalid json }");

        transformer.transformInvestigationData(investigation);

        verify(investigationCaseAnswerRepository, never()).findByActUid(investigationUid);
    }

    @Test
    void testInvestigationCaseAnswersDeserialization() throws JsonProcessingException {
        InvestigationCaseAnswer[] answers = objectMapper.readValue(readFileData(FILE_PREFIX + "InvestigationCaseAnswers.json"),
                InvestigationCaseAnswer[].class);

        InvestigationCaseAnswer expected = constructCaseAnswer();

        assertEquals(3, answers.length);
        assertEquals(expected, answers[1]);
    }

    private @NotNull InvestigationNotifications constructNotifications() {
        InvestigationNotifications notifications = new InvestigationNotifications();
        notifications.setSourceActUid(263748597L);
        notifications.setPublicHealthCaseUid(investigationUid);
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

    private @NotNull InvestigationCaseAnswer constructCaseAnswer() {
        InvestigationCaseAnswer expected = new InvestigationCaseAnswer();
        expected.setNbsCaseAnswerUid(1235L);
        expected.setNbsUiMetadataUid(65497311L);
        expected.setNbsRdbMetadataUid(41201011L);
        expected.setRdbTableNm("D_INV_ADMINISTRATIVE");
        expected.setRdbColumnNm("ADM_IMMEDIATE_NND_DESC");
        expected.setCodeSetGroupId(null);
        expected.setAnswerTxt("notify test is success");
        expected.setActUid(investigationUid);
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
        return expected;
    }
}
