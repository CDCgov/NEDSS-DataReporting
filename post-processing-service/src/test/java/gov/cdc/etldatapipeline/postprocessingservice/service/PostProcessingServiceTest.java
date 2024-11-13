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
import java.util.NoSuchElementException;
import java.util.concurrent.ConcurrentHashMap;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class PostProcessingServiceTest {

    @InjectMocks @Spy
    private PostProcessingService postProcessingServiceMock;
    @Mock
    private PostProcRepository postProcRepositoryMock;
    @Mock
    private InvestigationRepository investigationRepositoryMock;

    @Mock
    KafkaTemplate<String, String> kafkaTemplate;
    @Captor
    private ArgumentCaptor<String> topicCaptor;

    private ProcessDatamartData datamartProcessor;

    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
    private AutoCloseable closeable;

    @BeforeEach
    public void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        datamartProcessor = new ProcessDatamartData(kafkaTemplate);
        postProcessingServiceMock = spy(new PostProcessingService(postProcRepositoryMock, investigationRepositoryMock,
                datamartProcessor));
        Logger logger = (Logger) LoggerFactory.getLogger(PostProcessingService.class);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    public void tearDown() throws Exception {
        Logger logger = (Logger) LoggerFactory.getLogger(PostProcessingService.class);
        logger.detachAppender(listAppender);
        closeable.close();
    }

    @ParameterizedTest
    @CsvSource({
            "dummy_patient, '{\"payload\":{\"patient_uid\":123}}', 123",
            "dummy_provider, '{\"payload\":{\"provider_uid\":123}}', 123",
            "dummy_organization, '{\"payload\":{\"organization_uid\":123}}', 123",
            "dummy_investigation, '{\"payload\":{\"public_health_case_uid\":123}}', 123",
            "dummy_notification, '{\"payload\":{\"notification_uid\":123}}', 123",
            "dummy_ldf_data, '{\"payload\":{\"ldf_uid\":123}}', 123"
    })
    void testPostProcessMessage(String topic, String messageKey, Long expectedId) {
        postProcessingServiceMock.postProcessMessage(topic, messageKey, messageKey);
        assertEquals(expectedId, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));
    }

    @Test
    void testPostProcessPatientMessage() {
        String topic = "dummy_patient";
        String key = "{\"payload\":{\"patient_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedPatientIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForPatientIds(expectedPatientIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessProviderMessage() {
        String topic = "dummy_provider";
        String key = "{\"payload\":{\"provider_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedProviderIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForProviderIds(expectedProviderIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessOrganizationMessage() {
        String topic = "dummy_organization";
        String key = "{\"payload\":{\"organization_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedOrganizationIdsIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForOrganizationIds(expectedOrganizationIdsIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
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
        verify(investigationRepositoryMock).executeStoredProcForCaseCount(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock, never()).executeStoredProcForPageBuilder(anyLong(), anyString());

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(8, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(PostProcessingService.Entity.INVESTIGATION.getStoredProcedure()));
        assertTrue(logs.get(5).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessNotificationMessage() {
        String topic = "dummy_notification";
        String key = "{\"payload\":{\"notification_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedNotificationIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForNotificationIds(expectedNotificationIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(PostProcessingService.Entity.NOTIFICATION.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessPageBuilder() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";
        String msg = "{\"payload\":{\"public_health_case_uid\":123, \"rdb_table_name_list\":\"D_INV_CLINICAL," +
                "D_INV_ADMINISTRATIVE\"}}";

        Long expectedPublicHealthCaseId = 123L;
        String expectedRdbTableNames = "D_INV_CLINICAL,D_INV_ADMINISTRATIVE";

        postProcessingServiceMock.postProcessMessage(topic, key, msg);
        assertTrue(postProcessingServiceMock.idVals.containsKey(expectedPublicHealthCaseId));
        assertTrue(postProcessingServiceMock.idVals.containsValue(expectedRdbTableNames));

        postProcessingServiceMock.processCachedIds();
        assertFalse(postProcessingServiceMock.idVals.containsKey(expectedPublicHealthCaseId));
        verify(investigationRepositoryMock).executeStoredProcForPageBuilder(expectedPublicHealthCaseId,
                expectedRdbTableNames);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(10, logs.size());
        assertTrue(logs.get(7).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessLdfData() {
        String topic = "dummy_ldf_data";
        String key = "{\"payload\":{\"ldf_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        assertEquals(123L, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        postProcessingServiceMock.processCachedIds();

        String expectedLdfIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForLdfIds(expectedLdfIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(PostProcessingService.Entity.LDF_DATA.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessObservationMorb() {
        String topic = "dummy_observation";
        String key = "{\"payload\":{\"observation_uid\":123}}";
        String msg = "{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"MorbReport\"}}";

        postProcessingServiceMock.postProcessMessage(topic, key, msg);
        assertEquals(123L, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));
        assertTrue(postProcessingServiceMock.idVals.containsKey(123L));
        assertTrue(postProcessingServiceMock.idVals.containsValue(PostProcessingService.MORB_REPORT));

        postProcessingServiceMock.processCachedIds();

        String expectedObsIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForMorbReport(expectedObsIdsString);
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains("sp_d_morbidity_report_postprocessing"));assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));

    }

    @ParameterizedTest
    @CsvSource({
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"LabReport\"}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"LabReportMorb\"}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"Result\",\"ctrl_cd_display_form\": \"LabReport\"}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"R_Order\",\"ctrl_cd_display_form\": \"LabReportMorb\"}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"R_Result\",\"ctrl_cd_display_form\": \"LabReport\"}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"I_Order\",\"ctrl_cd_display_form\": null}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"I_Result\",\"ctrl_cd_display_form\": null}}'"
    })
    void testPostProcessObservationLab(String payload) {
        String topic = "dummy_observation";
        String key = "{\"payload\":{\"observation_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, payload);
        assertEquals(123L, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));
        assertTrue(postProcessingServiceMock.idVals.containsKey(123L));
        assertTrue(postProcessingServiceMock.idVals.containsValue(PostProcessingService.LAB_REPORT));

        postProcessingServiceMock.processCachedIds();

        String expectedObsIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForLabTest(expectedObsIdsString);
        verify(postProcRepositoryMock).executeStoredProcForLabTestResult(expectedObsIdsString);
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(10, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains("sp_d_lab_test_postprocessing"));
        assertTrue(logs.get(4).getFormattedMessage().contains("sp_d_labtest_result_postprocessing"));
        assertTrue(logs.get(6).getFormattedMessage().contains("sp_lab100_datamart_postprocessing"));
        assertTrue(logs.get(8).getFormattedMessage().contains("sp_lab101_datamart_postprocessing"));
        assertTrue(logs.get(9).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @ParameterizedTest
    @CsvSource({
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"Result\",\"ctrl_cd_display_form\": \"MorbReport\"}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"NoReport\"}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"NoOrderOrResult\",\"ctrl_cd_display_form\": \"LabReport\"}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": null,\"ctrl_cd_display_form\": \"LabReport\"}}'",
            "'{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"C_Result\",\"ctrl_cd_display_form\": \"LabComment\"}}'"
    })
    void testPostProcessObservationNoReport(String payload) {
        String topic = "dummy_observation";
        String key = "{\"payload\":{\"observation_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, payload);
        assertEquals(123L, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));
        assertTrue(postProcessingServiceMock.idVals.isEmpty());

        postProcessingServiceMock.processCachedIds();

        String expectedObsIdsString = "123";
        verify(postProcRepositoryMock, never()).executeStoredProcForMorbReport(expectedObsIdsString);
        verify(postProcRepositoryMock, never()).executeStoredProcForLabTest(expectedObsIdsString);
        verify(postProcRepositoryMock, never()).executeStoredProcForLabTestResult(expectedObsIdsString);
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(2, logs.size());
    }

    @Test
    void testPostProcessMultipleMessages() {
        String orgKey1 = "{\"payload\":{\"organization_uid\":123}}";
        String orgKey2 = "{\"payload\":{\"organization_uid\":124}}";
        String orgTopic = "dummy_organization";

        String invTopic = "dummy_investigation";
        String invKey1 = "{\"payload\":{\"public_health_case_uid\":234}}";
        String invKey2 = "{\"payload\":{\"public_health_case_uid\":235}}";

        String ntfKey1 = "{\"payload\":{\"notification_uid\":567}}";
        String ntfKey2 = "{\"payload\":{\"notification_uid\":568}}";
        String ntfTopic = "dummy_notification";

        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey1, orgKey1);
        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey2, orgKey2);
        postProcessingServiceMock.postProcessMessage(ntfTopic, ntfKey1, ntfKey1);
        postProcessingServiceMock.postProcessMessage(ntfTopic, ntfKey2, ntfKey2);
        postProcessingServiceMock.postProcessMessage(invTopic, invKey1, invKey1);
        postProcessingServiceMock.postProcessMessage(invTopic, invKey2, invKey2);

        assertTrue(postProcessingServiceMock.idCache.containsKey(orgTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(invTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(ntfTopic));

        postProcessingServiceMock.processCachedIds();

        verify(postProcRepositoryMock).executeStoredProcForOrganizationIds("123,124");
        verify(investigationRepositoryMock).executeStoredProcForPublicHealthCaseIds("234,235");
        verify(postProcRepositoryMock).executeStoredProcForNotificationIds("567,568");
    }

    @Test
    void testPostProcessCacheIdsPriority() {
        String orgKey = "{\"payload\":{\"organization_uid\":123}}";
        String providerKey = "{\"payload\":{\"provider_uid\":124}}";
        String patientKey = "{\"payload\":{\"patient_uid\":125}}";
        String investigationKey = "{\"payload\":{\"public_health_case_uid\":126}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":127}}";
        String ldfKey = "{\"payload\":{\"ldf_uid\":127}}";

        String orgTopic = "dummy_organization";
        String providerTopic = "dummy_provider";
        String patientTopic = "dummy_patient";
        String invTopic = "dummy_investigation";
        String ntfTopic = "dummy_notification";
        String ldfTopic = "dummy_ldf_data";

        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.postProcessMessage(providerTopic, providerKey, providerKey);
        postProcessingServiceMock.postProcessMessage(patientTopic, patientKey, patientKey);
        postProcessingServiceMock.postProcessMessage(ntfTopic, notificationKey, notificationKey);
        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey, orgKey);
        postProcessingServiceMock.postProcessMessage(ldfTopic, ldfKey, ldfKey);
        postProcessingServiceMock.processCachedIds();

        List<ILoggingEvent> logs = listAppender.list;

        List<String> topicLogList = logs.stream().map(ILoggingEvent::getFormattedMessage).filter(m -> m.matches(
                "Processing .+ for topic: .*")).toList();
        assertTrue(topicLogList.get(0).contains(orgTopic));
        assertTrue(topicLogList.get(1).contains(providerTopic));
        assertTrue(topicLogList.get(2).contains(patientTopic));
        assertTrue(topicLogList.get(3).contains(invTopic));
        assertTrue(topicLogList.get(4).contains(invTopic));
        assertTrue(topicLogList.get(6).contains(ntfTopic));
        assertTrue(topicLogList.get(7).contains(ldfTopic));
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

    @ParameterizedTest
    @CsvSource({
            "'{\"payload\":{\"public_health_case_uid\":123,\"rdb_table_name_list\":null}}'",
            "'{\"payload\":{\"patient_uid\":123}}'",
            "'{\"payload\":{invalid}'"
    })
    void testPostProcessNoIdValOrInvalidPayload(String payload) {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, payload);
        assertFalse(postProcessingServiceMock.idVals.containsKey(123L));

        postProcessingServiceMock.processCachedIds();

        verify(investigationRepositoryMock, never()).executeStoredProcForPageBuilder(anyLong(), anyString());
    }

    @Test
    void testProcessMessageEmptyCache() {
        postProcessingServiceMock.processCachedIds();

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(1, logs.size());
        assertTrue(logs.getFirst().getMessage().contains("No ids to process from the topics."));
    }

    @Test
    void testPostProcessMessageException() {
        String invalidKey = "invalid_key";
        String invalidTopic = "dummy_topic";

        assertThrows(RuntimeException.class, () -> postProcessingServiceMock.postProcessMessage(invalidTopic,
                invalidKey, invalidKey));
    }

    @Test
    void testPostProcessNoUidException() {
        String orgKey = "{\"payload\":{}}";
        String topic = "dummy_organization";

        RuntimeException ex = assertThrows(RuntimeException.class, () -> postProcessingServiceMock.postProcessMessage(topic,
                orgKey, orgKey));
        assertEquals(ex.getCause().getClass(), NoSuchElementException.class);
    }

    @Test
    void testPostProcessDatamartException() {
        String topic = "dummy_datamart";
        String invalidMsg = "invalid_msg";

        assertThrows(RuntimeException.class, () -> postProcessingServiceMock.postProcessDatamart(topic, invalidMsg));
    }

    @ParameterizedTest
    @CsvSource({
            "'{\"payload\":null}'",
            "'{\"payload\":{}}'",
            "'{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"datamart\":null}}'"
    })
    void testPostProcessDatamartIncompleteData(String msg) {
        String topic = "dummy_datamart";

        postProcessingServiceMock.postProcessDatamart(topic, msg);
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.getLast().getFormattedMessage().contains("Skipping further processing"));
    }

    @Test
    void testProcessDatamartEmptyCache() {
        postProcessingServiceMock.dmCache.put("Datamart", ConcurrentHashMap.newKeySet());
        postProcessingServiceMock.processDatamartIds();

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(1, logs.size());
        assertTrue(logs.getFirst().getMessage().contains("No data to process from the datamart topics."));
    }

    @Test
    void testPostProcessUnknownTopic() {
        String topic = "dummy_topic";
        String key = "{\"payload\":{\"unknown_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.getLast().getFormattedMessage().contains("Unknown topic: " + topic + " cannot be processed"));
    }

    @Test
    void testShutdown() {
        postProcessingServiceMock.shutdown();
        verify(postProcessingServiceMock, times(1)).processCachedIds();
        verify(postProcessingServiceMock).processDatamartIds();

        InOrder inOrder = inOrder(postProcessingServiceMock);
        inOrder.verify(postProcessingServiceMock).processCachedIds();
        inOrder.verify(postProcessingServiceMock).processDatamartIds();

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