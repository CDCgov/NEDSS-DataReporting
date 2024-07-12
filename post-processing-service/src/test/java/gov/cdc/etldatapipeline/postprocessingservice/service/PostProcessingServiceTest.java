package gov.cdc.etldatapipeline.postprocessingservice.service;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.etldatapipeline.postprocessingservice.repository.*;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.InvestigationResult;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.*;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class PostProcessingServiceTest {

    @InjectMocks
    private PostProcessingService postProcessingServiceMock;
    @Mock
    private PatientRepository patientRepositoryMock;
    @Mock
    private ProviderRepository providerRepositoryMock;
    @Mock
    private OrganizationRepository organizationRepositoryMock;
    @Mock
    private InvestigationRepository investigationRepositoryMock;
    @Mock
    private NotificationRepository notificationRepositoryMock;

    @Mock
    KafkaTemplate<String, String> kafkaTemplate;
    @Captor
    private ArgumentCaptor<String> topicCaptor;

    private ProcessDatamartData datamartProcessor;

    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();

    @BeforeEach
    public void setUp() {
        MockitoAnnotations.openMocks(this);
        datamartProcessor = new ProcessDatamartData(kafkaTemplate);
        postProcessingServiceMock = new PostProcessingService(patientRepositoryMock, providerRepositoryMock,
                organizationRepositoryMock, investigationRepositoryMock, notificationRepositoryMock,
                datamartProcessor);
        Logger logger = (Logger) LoggerFactory.getLogger(PostProcessingService.class);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    public void tearDown() {
        Logger logger = (Logger) LoggerFactory.getLogger(PostProcessingService.class);
        logger.detachAppender(listAppender);
    }

    @ParameterizedTest
    @CsvSource({
            "dummy_patient, '{\"payload\":{\"patient_uid\":123}}', 123",
            "dummy_provider, '{\"payload\":{\"provider_uid\":123}}', 123",
            "dummy_organization, '{\"payload\":{\"organization_uid\":123}}', 123",
            "dummy_investigation, '{\"payload\":{\"public_health_case_uid\":123}}', 123",
            "dummy_notifications, '{\"payload\":{\"notification_uid\":123}}', 123"
    })
    void testExtractIdFromMessage(String topic, String messageKey, Long expectedId) {
        Long extractedId = postProcessingServiceMock.extractIdFromMessage(topic, messageKey, messageKey);
        assertEquals(expectedId, extractedId);
    }

    @Test
    void testPostProcessPatientMessage() {
        String topic = "dummy_patient";
        String key = "{\"payload\":{\"patient_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedPatientIdsString = "123";
        verify(patientRepositoryMock).executeStoredProcForPatientIds(expectedPatientIdsString);
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(3, logs.size());
        assertTrue(logs.get(2).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessProviderMessage() {
        String topic = "dummy_provider";
        String key = "{\"payload\":{\"provider_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedProviderIdsString = "123";
        verify(providerRepositoryMock).executeStoredProcForProviderIds(expectedProviderIdsString);
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(3, logs.size());
        assertTrue(logs.get(2).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessOrganizationMessage() {
        String topic = "dummy_organization";
        String key = "{\"payload\":{\"organization_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedOrganizationIdsIdsString = "123";
        verify(organizationRepositoryMock).executeStoredProcForOrganizationIds(expectedOrganizationIdsIdsString);
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(3, logs.size());
        assertTrue(logs.get(2).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessInvestigationMessage() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedPublicHealthCaseIdsString = "123";
        verify(investigationRepositoryMock).executeStoredProcForPublicHealthCaseIds(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForFPageCase(expectedPublicHealthCaseIdsString);
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(5, logs.size());
        assertTrue(logs.get(4).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessNotificationMessage() {
        String topic = "dummy_notifications";
        String key = "{\"payload\":{\"notification_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedNotificationIdsString = "123";
        verify(notificationRepositoryMock).executeStoredProcForNotificationIds(expectedNotificationIdsString);
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(3, logs.size());
        assertTrue(logs.get(2).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessPageBuilder() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";
        String msg = "{\"payload\":{\"public_health_case_uid\":123, \"rdb_table_name_list\":\"D_INV_CLINICAL,D_INV_ADMINISTRATIVE\"}}";

        Long expectedPublicHealthCaseId = 123L;
        String expectedRdbTableNames = "D_INV_CLINICAL,D_INV_ADMINISTRATIVE";

        postProcessingServiceMock.postProcessMessage(topic, key, msg);
        assertTrue(postProcessingServiceMock.idVals.containsKey(expectedPublicHealthCaseId));
        assertTrue(postProcessingServiceMock.idVals.containsValue(expectedRdbTableNames));

        postProcessingServiceMock.processCachedIds();
        assertFalse(postProcessingServiceMock.idVals.containsKey(expectedPublicHealthCaseId));
        verify(investigationRepositoryMock).executeStoredProcForPageBuilder(expectedPublicHealthCaseId, expectedRdbTableNames);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(7, logs.size());
        assertTrue(logs.get(6).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessMultipleMessages() {
        String orgKey1 = "{\"payload\":{\"organization_uid\":123}}";
        String orgKey2 = "{\"payload\":{\"organization_uid\":124}}";
        String orgTopic = "dummy_organization";

        String ntfKey1 = "{\"payload\":{\"notification_uid\":234}}";
        String ntfKey2 = "{\"payload\":{\"notification_uid\":235}}";
        String ntfTopic = "dummy_notifications";

        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey1, orgKey1);
        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey2, orgKey2);
        postProcessingServiceMock.postProcessMessage(ntfTopic, ntfKey1, ntfKey1);
        postProcessingServiceMock.postProcessMessage(ntfTopic, ntfKey2, ntfKey2);

        postProcessingServiceMock.processCachedIds();

        verify(organizationRepositoryMock).executeStoredProcForOrganizationIds("123,124");
        assertTrue(postProcessingServiceMock.idCache.containsKey(orgTopic));

        verify(notificationRepositoryMock).executeStoredProcForNotificationIds("234,235");
        assertTrue(postProcessingServiceMock.idCache.containsKey(ntfTopic));
    }

    @Test
    void testPostProcessCacheIdsPriority() {
        String orgKey = "{\"payload\":{\"organization_uid\":123}}";
        String providerKey = "{\"payload\":{\"provider_uid\":124}}";
        String patientKey = "{\"payload\":{\"patient_uid\":125}}";
        String investigationKey = "{\"payload\":{\"public_health_case_uid\":126}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":127}}";

        String orgTopic = "dummy_organization";
        String providerTopic = "dummy_provider";
        String patientTopic = "dummy_patient";
        String invTopic = "dummy_investigation";
        String notfTopic = "dummy_notifications";

        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.postProcessMessage(providerTopic, providerKey, providerKey);
        postProcessingServiceMock.postProcessMessage(patientTopic, patientKey, patientKey);
        postProcessingServiceMock.postProcessMessage(notfTopic, notificationKey, notificationKey);
        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey, orgKey);
        postProcessingServiceMock.processCachedIds();

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(17, logs.size());

        List<String> topicLogList = logs.stream().map(ILoggingEvent::getFormattedMessage).filter(m -> m.contains("message topic")).toList();
        assertTrue(topicLogList.get(0).contains(orgTopic));
        assertTrue(topicLogList.get(1).contains(providerTopic));
        assertTrue(topicLogList.get(2).contains(patientTopic));
        assertTrue(topicLogList.get(3).contains(invTopic));
        assertTrue(topicLogList.get(4).contains(invTopic));
        assertTrue(topicLogList.get(5).contains(notfTopic));
    }

    @Test
    void testPostProcessDatamart() {
        String topic = "dummy_datamart";
        String msg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456," +
                "\"investigation_key\":100,\"patient_key\":200,\"condition_cd\":\"10110\"," +
                "\"datamart\":\"Hepatitis_Datamart\",\"stored_procedure\":\"sp_hepatitis_datamart_postprocessing\"}}";

        postProcessingServiceMock.postProcessDatamart(topic, msg);
        postProcessingServiceMock.processDatamartIds();

        verify(investigationRepositoryMock).executeStoredProcForHepDatamart("123", "456");
        assertTrue(postProcessingServiceMock.dmCache.containsKey("Hepatitis_Datamart"));
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(3, logs.size());
    }

    @Test
    void testProduceDatamartTopic() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";
        String dmTopic = "dummy_datamart";

        List<InvestigationResult> invResults = getInvestigationResults(123L, 200L);

        datamartProcessor.datamartTopic = dmTopic;
        when(investigationRepositoryMock.executeStoredProcForPublicHealthCaseIds("123")).thenReturn(invResults);
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        verify(kafkaTemplate).send(topicCaptor.capture(), anyString(), anyString());
        assertEquals(dmTopic, topicCaptor.getValue());
    }

    @Test
    void testProduceDatamartTopicWithNoPatient() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";
        String dmTopic = "dummy_datamart";

        // patientKey=1L for no patient data in D_PATIENT
        List<InvestigationResult> invResults = getInvestigationResults(123L, 1L);

        datamartProcessor.datamartTopic = dmTopic;
        when(investigationRepositoryMock.executeStoredProcForPublicHealthCaseIds("123")).thenReturn(invResults);
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void testPostProcessPageBuilderWithNoTableCache() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        verify(investigationRepositoryMock, never()).executeStoredProcForPageBuilder(anyLong(), anyString());
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(5, logs.size());
    }

    @Test
    void testProcessMessageEmptyCache() {
        String topic = "dummy_patient";

        postProcessingServiceMock.idCache.put(topic, new CopyOnWriteArrayList<>());
        postProcessingServiceMock.processCachedIds();

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(1, logs.size());
        assertTrue(logs.get(0).getMessage().contains("No ids to process from the topics."));
    }

    @Test
    void testExtractIdFromMessageException() {
        String invalidKey = "invalid_key";
        String invalidTopic = "dummy_topic";

        assertThrows(RuntimeException.class, () -> postProcessingServiceMock.extractIdFromMessage(invalidTopic, invalidKey, invalidKey));
    }

    @Test
    void testPostProcessDatamartException() {
        String topic = "dummy_datamart";
        String invalidMsg = "invalid_msg";

        assertThrows(RuntimeException.class, () -> postProcessingServiceMock.postProcessDatamart(topic, invalidMsg));
    }

    private List<InvestigationResult> getInvestigationResults(Long phcUid, Long patientKey) {
        List<InvestigationResult> investigationResults = new ArrayList<>();
        InvestigationResult investigationResult = new InvestigationResult();
        investigationResult.setPublicHealthCaseUid(phcUid);
        investigationResult.setInvestigationKey(100L);
        investigationResult.setPatientUid(456L);
        investigationResult.setPatientKey(patientKey);
        investigationResult.setConditionCd("10110");
        investigationResult.setDatamart("Hepatitis_Datamart");
        investigationResult.setStoredProcedure("sp_hepatitis_datamart_postprocessing");
        investigationResults.add(investigationResult);
        return investigationResults;
    }
}