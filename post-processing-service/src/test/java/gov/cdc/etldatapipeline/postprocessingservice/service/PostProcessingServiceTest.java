package gov.cdc.etldatapipeline.postprocessingservice.service;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.etldatapipeline.postprocessingservice.repository.*;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
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
    @Captor
    private ArgumentCaptor<String> keyCaptor;

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
            "dummy_place, '{\"payload\":{\"place_uid\":123}}', 123",
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
        verify(investigationRepositoryMock).executeStoredProcForNotificationIds(expectedNotificationIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(PostProcessingService.Entity.NOTIFICATION.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessCaseManagementMessage() {
        String topic = "dummy_case_management";
        String key = "{\"payload\":{\"public_health_case_uid\":123,\"case_management_uid\":1001}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedPublicHealthCaseIdsString = "123";
        verify(investigationRepositoryMock).executeStoredProcForCaseManagement(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForFStdPageCase(expectedPublicHealthCaseIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(6, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(PostProcessingService.Entity.CASE_MANAGEMENT.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
        assertTrue(logs.get(4).getFormattedMessage().contains(PostProcessingService.Entity.F_STD_PAGE_CASE.getStoredProcedure()));
        assertTrue(logs.get(5).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
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
    void testPostProcessInterviewData() {
        String topic = "dummy_interview";
        String key = "{\"payload\":{\"interview_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        assertEquals(123L, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        postProcessingServiceMock.processCachedIds();

        String expectedIntIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForDInterview(expectedIntIdsString);
        verify(postProcRepositoryMock).executeStoredProcForFInterviewCase(expectedIntIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(6, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(PostProcessingService.Entity.INTERVIEW.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
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

        String placeKey1 = "{\"payload\":{\"place_uid\":123}}";
        String placeKey2 = "{\"payload\":{\"place_uid\":124}}";
        String placeTopic = "dummy_place";

        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey1, orgKey1);
        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey2, orgKey2);
        postProcessingServiceMock.postProcessMessage(ntfTopic, ntfKey1, ntfKey1);
        postProcessingServiceMock.postProcessMessage(ntfTopic, ntfKey2, ntfKey2);
        postProcessingServiceMock.postProcessMessage(invTopic, invKey1, invKey1);
        postProcessingServiceMock.postProcessMessage(invTopic, invKey2, invKey2);
        postProcessingServiceMock.postProcessMessage(placeTopic, placeKey1, placeKey1);
        postProcessingServiceMock.postProcessMessage(placeTopic, placeKey2, placeKey2);

        assertTrue(postProcessingServiceMock.idCache.containsKey(orgTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(invTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(ntfTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(placeTopic));

        postProcessingServiceMock.processCachedIds();

        verify(postProcRepositoryMock).executeStoredProcForOrganizationIds("123,124");
        verify(investigationRepositoryMock).executeStoredProcForPublicHealthCaseIds("234,235");
        verify(investigationRepositoryMock).executeStoredProcForNotificationIds("567,568");
        verify(postProcRepositoryMock).executeStoredProcForDPlace("123,124");
    }

    @Test
    void testPostProcessCacheIdsPriority() {
        String orgKey = "{\"payload\":{\"organization_uid\":123}}";
        String providerKey = "{\"payload\":{\"provider_uid\":124}}";
        String patientKey = "{\"payload\":{\"patient_uid\":125}}";
        String placeKey = "{\"payload\":{\"place_uid\":131}}";
        String investigationKey = "{\"payload\":{\"public_health_case_uid\":126}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":127}}";
        String caseManagementKey = "{\"payload\":{\"public_health_case_uid\":128,\"case_management_uid\":1001}}";
        String ldfKey = "{\"payload\":{\"ldf_uid\":129}}";
        String interviewKey = "{\"payload\":{\"interview_uid\":130}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";
        String observationMsg = "{\"payload\":{\"observation_uid\":130, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"MorbReport\"}}";


        String orgTopic = "dummy_organization";
        String providerTopic = "dummy_provider";
        String patientTopic = "dummy_patient";
        String placeTopic = "dummy_place";
        String invTopic = "dummy_investigation";
        String ntfTopic = "dummy_notification";
        String intTopic = "dummy_interview";
        String ldfTopic = "dummy_ldf_data";
        String cmTopic = "dummy_case_management";
        String obsTopic = "dummy_observation";



        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.postProcessMessage(providerTopic, providerKey, providerKey);
        postProcessingServiceMock.postProcessMessage(patientTopic, patientKey, patientKey);
        postProcessingServiceMock.postProcessMessage(placeTopic, placeKey, placeKey);
        postProcessingServiceMock.postProcessMessage(intTopic, interviewKey, interviewKey);
        postProcessingServiceMock.postProcessMessage(ntfTopic, notificationKey, notificationKey);
        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey, orgKey);
        postProcessingServiceMock.postProcessMessage(obsTopic, observationKey, observationMsg);
        postProcessingServiceMock.postProcessMessage(ldfTopic, ldfKey, ldfKey);
        postProcessingServiceMock.postProcessMessage(cmTopic, caseManagementKey, caseManagementKey);
        postProcessingServiceMock.processCachedIds();

        List<ILoggingEvent> logs = listAppender.list;

        List<String> topicLogList = logs.stream().map(ILoggingEvent::getFormattedMessage).filter(m -> m.matches(
                "Processing .+ for topic: .*")).toList();
        assertTrue(topicLogList.get(0).contains(orgTopic));
        assertTrue(topicLogList.get(1).contains(providerTopic));
        assertTrue(topicLogList.get(2).contains(patientTopic));
        assertTrue(topicLogList.get(3).contains(placeTopic));
        assertTrue(topicLogList.get(4).contains(invTopic));
        assertTrue(topicLogList.get(5).contains(invTopic));
        assertTrue(topicLogList.get(6).contains(invTopic));
        assertTrue(topicLogList.get(7).contains(ntfTopic));
        assertTrue(topicLogList.get(8).contains(intTopic));
        assertTrue(topicLogList.get(9).contains(intTopic));
        assertTrue(topicLogList.get(10).contains(cmTopic));
        assertTrue(topicLogList.get(11).contains(cmTopic));
        assertTrue(topicLogList.get(12).contains(ldfTopic));
        assertTrue(topicLogList.get(13).contains(obsTopic));
    }

    @Test
    void testPostProcessHepatitsDatamart() {
        String topic = "dummy_datamart";
        String msg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456," +
                "\"investigation_key\":100,\"patient_key\":200,\"condition_cd\":\"10110\"," +
                "\"datamart\":\"Hepatitis_Datamart\",\"stored_procedure\":\"sp_hepatitis_datamart_postprocessing\"}}";

        postProcessingServiceMock.postProcessDatamart(topic, msg);
        postProcessingServiceMock.processDatamartIds();

        verify(investigationRepositoryMock).executeStoredProcForHepDatamart("123");
        assertTrue(postProcessingServiceMock.dmCache.containsKey(PostProcessingService.Entity.HEPATITIS_DATAMART.getEntityName()));
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(3, logs.size());
    }

    @Test
    void testPostProcessStdHIVDatamart() {
        String topic = "dummy_datamart";
        String msg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456," +
                "\"investigation_key\":100,\"patient_key\":200,\"condition_cd\":\"10110\"," +
                "\"datamart\":\"Std_Hiv_Datamart\",\"stored_procedure\":\"sp_std_hiv_datamart_postprocessing\"}}";

        postProcessingServiceMock.postProcessDatamart(topic, msg);
        postProcessingServiceMock.processDatamartIds();

        verify(investigationRepositoryMock).executeStoredProcForStdHIVDatamart("123");
        assertTrue(postProcessingServiceMock.dmCache.containsKey(PostProcessingService.Entity.STD_HIV_DATAMART.getEntityName()));
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(3, logs.size());
    }

    @Test
    void testProduceDatamartTopic() {
        String dmTopic = "dummy_datamart";

        String topicInv = "dummy_investigation";
        String keyInv = "{\"payload\":{\"public_health_case_uid\":123}}";

        String topicNtf = "dummy_notification";
        String keyNtf = "{\"payload\":{\"notification_uid\":124}}";

        datamartProcessor.datamartTopic = dmTopic;
        postProcessingServiceMock.postProcessMessage(topicInv, keyInv, keyInv);
        postProcessingServiceMock.postProcessMessage(topicNtf, keyNtf, keyNtf);

        List<DatamartData> masterData = getDatamartData(123L, 200L);
        List<DatamartData> notificationData = getDatamartData(123L, 200L);
        notificationData.addAll(getDatamartData(124L, 201L));

        when(investigationRepositoryMock.executeStoredProcForPublicHealthCaseIds("123")).thenReturn(masterData);
        when(investigationRepositoryMock.executeStoredProcForNotificationIds("124")).thenReturn(notificationData);
        postProcessingServiceMock.processCachedIds();

        // verify that only unique datamart data items (2 of 3) are processed
        verify(kafkaTemplate, times(2)).send(topicCaptor.capture(), keyCaptor.capture(), anyString());
        assertEquals(dmTopic, topicCaptor.getValue());
        assertTrue(keyCaptor.getAllValues().get(0).contains("123"));
        assertTrue(keyCaptor.getAllValues().get(1).contains("124"));
    }

    @Test
    void testProduceDatamartTopicWithNoPatient() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";
        String dmTopic = "dummy_datamart";

        // patientKey=1L for no patient data in D_PATIENT
        List<DatamartData> invResults = getDatamartData(123L, 1L);

        datamartProcessor.datamartTopic = dmTopic;
        when(investigationRepositoryMock.executeStoredProcForPublicHealthCaseIds("123")).thenReturn(invResults);
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void testPostProcessPlaceMessage() {
        String topic = "dummy_place";
        String key = "{\"payload\":{\"place_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedPlaceIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForDPlace(expectedPlaceIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(PostProcessingService.Entity.D_PLACE.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessMultipleMessages_WithPlace() {
        String placeKey1 = "{\"payload\":{\"place_uid\":123}}";
        String placeKey2 = "{\"payload\":{\"place_uid\":124}}";
        String placeTopic = "dummy_place";

        postProcessingServiceMock.postProcessMessage(placeTopic, placeKey1, placeKey1);
        postProcessingServiceMock.postProcessMessage(placeTopic, placeKey2, placeKey2);

        assertTrue(postProcessingServiceMock.idCache.containsKey(placeTopic));

        postProcessingServiceMock.processCachedIds();

        verify(postProcRepositoryMock).executeStoredProcForDPlace("123,124");
    }
    @Test
    void testPostProcessNoPlaceUidException() {
        String placeKey = "{\"payload\":{}}";
        String topic = "dummy_place";

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> postProcessingServiceMock.postProcessMessage(topic, placeKey, placeKey));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
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
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
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

    private List<DatamartData> getDatamartData(Long phcUid, Long patientKey) {
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = new DatamartData();
        datamartData.setPublicHealthCaseUid(phcUid);
        datamartData.setInvestigationKey(100L);
        datamartData.setPatientUid(456L);
        datamartData.setPatientKey(patientKey);
        datamartData.setConditionCd("10110");
        datamartData.setDatamart(PostProcessingService.Entity.HEPATITIS_DATAMART.getEntityName());
        datamartData.setStoredProcedure(PostProcessingService.Entity.HEPATITIS_DATAMART.getStoredProcedure());
        datamartDataLst.add(datamartData);
        return datamartDataLst;
    }
}