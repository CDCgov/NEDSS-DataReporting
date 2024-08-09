package gov.cdc.etldatapipeline.investigation;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.*;
import gov.cdc.etldatapipeline.investigation.repository.rdb.InvestigationCaseAnswerRepository;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.function.BiFunction;
import java.util.function.Function;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.*;

class InvestigationDataProcessingTests {
    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Mock
    InvestigationCaseAnswerRepository investigationCaseAnswerRepository;

    @Mock
    private ObjectMapper objectMapper;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private static final String FILE_PREFIX = "rawDataFiles/";
    private static final String CONFIRMATION_TOPIC = "confirmationTopic";
    private static final String OBSERVATION_TOPIC = "observationTopic";
    private static final String NOTIFICATIONS_TOPIC = "notificationsTopic";
    private static final Long investigationUid = 234567890L;

    ProcessInvestigationDataUtil transformer;

    BiFunction<String, List<String>, Boolean> containsWords = (input, words) ->
            words.stream().allMatch(input::contains);

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        transformer = new ProcessInvestigationDataUtil(kafkaTemplate, investigationCaseAnswerRepository);
    }

    @Test
    void testConfirmationMethod() {
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
        confirmationMethod.setConfirmationMethodTime("2024-01-15T10:20:57.647");

        transformer.transformInvestigationData(investigation);
        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(CONFIRMATION_TOPIC, topicCaptor.getValue());

        Function<InvestigationConfirmationMethod, List<String>> cmDetailsFn = m -> Arrays.asList(
                String.valueOf(m.getPublicHealthCaseUid()),
                m.getConfirmationMethodCd(),
                m.getConfirmationMethodDescTxt(),
                m.getConfirmationMethodTime());

        Function<InvestigationConfirmationMethodKey, List<String>> cmKeyFn = k -> Arrays.asList(
                String.valueOf(k.getPublicHealthCaseUid()),
                k.getConfirmationMethodCd());

        assertTrue(containsWords.apply(keyCaptor.getValue(), cmKeyFn.apply(confirmationMethodKey)));
        assertTrue(containsWords.apply(messageCaptor.getValue(), cmDetailsFn.apply(confirmationMethod)));
    }

    @Test
    void testObservationNotificationIds() {
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

        Function<InvestigationObservation, List<String>> oDetailsFn = o -> Arrays.asList(
                String.valueOf(o.getPublicHealthCaseUid()),
                String.valueOf(o.getObservationId()));

        String actualCombined = String.join(" ",messageCaptor.getAllValues());

        assertTrue(containsWords.apply(actualCombined, oDetailsFn.apply(observation)));
    }

    @Test
    void testNotifications() {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setInvestigationNotifications(readFileData(FILE_PREFIX + "InvestigationNotifications.json"));
        transformer.investigationNotificationsOutputTopicName = NOTIFICATIONS_TOPIC;

        InvestigationNotificationsKey notificationsKey = new InvestigationNotificationsKey();
        notificationsKey.setNotificationUid(263748597L);

        InvestigationNotifications notifications = new InvestigationNotifications();
        notifications.setPublicHealthCaseUid(investigationUid);
        notifications.setSourceActUid(263748597L);
        notifications.setNotificationUid(263748597L);
        notifications.setLocalPatientUid(75395128L);
        notifications.setSourceClassCd("NOTF");
        notifications.setTargetClassCd("CASE");
        notifications.setNotifStatus("APPROVED");
        notifications.setNotifAddUserId(96325874L);
        notifications.setConditionCd("11065");

        when(kafkaTemplate.send(anyString(), anyString(), anyString())).thenReturn(CompletableFuture.completedFuture(null));

        transformer.processNotifications(investigation.getInvestigationNotifications(), new ObjectMapper());
        verify(kafkaTemplate, times (1)).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(NOTIFICATIONS_TOPIC, topicCaptor.getValue());

        Function<InvestigationNotifications, List<String>> nDetailsFn = n -> Arrays.asList(
                String.valueOf(n.getPublicHealthCaseUid()),
                String.valueOf(n.getSourceActUid()),
                String.valueOf(n.getNotificationUid()),
                String.valueOf(n.getLocalPatientUid()),
                n.getSourceClassCd(),
                n.getTargetClassCd(),
                n.getNotifStatus(),
                String.valueOf(n.getNotifAddUserId()),
                n.getConditionCd());

        String actualCombined = String.join(" ",messageCaptor.getAllValues());

        assertTrue(containsWords.apply(keyCaptor.getValue(), Collections.singletonList(String.valueOf(notificationsKey.getNotificationUid()))));
        assertTrue(containsWords.apply(actualCombined, nDetailsFn.apply(notifications)));
    }

    @Test
    void testInvestigationCaseAnswer() throws JsonProcessingException {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setInvestigationCaseAnswer(readFileData(FILE_PREFIX + "InvestigationCaseAnswer.json"));

        InvestigationCaseAnswer caseAnswer = new InvestigationCaseAnswer();
        caseAnswer.setActUid(investigationUid);

        transformer.transformInvestigationData(investigation);

        when(investigationCaseAnswerRepository.findByActUid(investigationUid)).thenReturn(new ArrayList<>());

        List<InvestigationCaseAnswer> caseAnswers = new ArrayList<>();
        caseAnswers.add(caseAnswer);

        when(objectMapper.treeToValue(any(JsonNode.class), eq(InvestigationCaseAnswer.class)))
                .thenReturn(caseAnswer);

        verify(investigationCaseAnswerRepository).findByActUid(investigationUid);
        verify(investigationCaseAnswerRepository, never()).deleteByActUid(anyLong());
        verify(investigationCaseAnswerRepository).saveAll(anyList());
    }

    @Test
    void testInvestigationCaseAnswerExistingRecords() throws JsonProcessingException {
        Investigation investigation = new Investigation();

        investigation.setPublicHealthCaseUid(investigationUid);
        investigation.setInvestigationCaseAnswer(readFileData(FILE_PREFIX + "InvestigationCaseAnswer.json"));

        InvestigationCaseAnswer caseAnswer = new InvestigationCaseAnswer();
        caseAnswer.setActUid(investigationUid);

        List<InvestigationCaseAnswer> investigationCaseAnswerDataIfPresent = new ArrayList<>();
        investigationCaseAnswerDataIfPresent.add(new InvestigationCaseAnswer());
        when(investigationCaseAnswerRepository.findByActUid(investigationUid)).thenReturn(investigationCaseAnswerDataIfPresent);

        InvestigationTransformed investigationTransformed = transformer.transformInvestigationData(investigation);
        assertEquals("D_INV_CLINICAL,D_INV_ADMINISTRATIVE", investigationTransformed.getRdbTableNameList());

        List<InvestigationCaseAnswer> caseAnswers = new ArrayList<>();
        caseAnswers.add(caseAnswer);

        when(objectMapper.treeToValue(any(JsonNode.class), eq(InvestigationCaseAnswer.class)))
                .thenReturn(caseAnswer);

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
}
