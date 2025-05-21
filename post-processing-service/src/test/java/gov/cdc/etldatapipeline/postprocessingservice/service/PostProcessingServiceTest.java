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
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.*;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Consumer;
import java.util.stream.Stream;

import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.*;
import static gov.cdc.etldatapipeline.postprocessingservice.service.PostProcessingService.LAB_REPORT;
import static gov.cdc.etldatapipeline.postprocessingservice.service.PostProcessingService.MORB_REPORT;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import org.awaitility.Awaitility;
import java.util.concurrent.TimeUnit;

class PostProcessingServiceTest {

    @InjectMocks @Spy

    private PostProcessingService postProcessingServiceMock;
    @Mock
    private PostProcRepository postProcRepositoryMock;
    @Mock
    private static InvestigationRepository investigationRepositoryMock;

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

        postProcessingServiceMock.setInvestigationTopic("dummy_investigation");

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
            "dummy_ldf_data, '{\"payload\":{\"ldf_uid\":123}}', 123",
            "dummy_auth_user, '{\"payload\":{\"auth_user_uid\":123}}', 123",
            "dummy_NBS_page, '{\"payload\":{\"nbs_page_uid\":123}}', 123"
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
        assertEquals(5, logs.size());
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessProviderMessage() {
        String topic = "dummy_provider";
        String key = "{\"payload\":{\"provider_uid\":123}}";
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        String expectedProviderIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForProviderIds(expectedProviderIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(6, logs.size());
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
        assertEquals(5, logs.size());
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
        verify(investigationRepositoryMock, never()).executeStoredProcForPageBuilder(anyString(), anyString());
        verify(investigationRepositoryMock, never()).executeStoredProcForSummaryReportCase(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock, never()).executeStoredProcForSR100Datamart(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock, never()).executeStoredProcForAggregateReport(expectedPublicHealthCaseIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(8, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(INVESTIGATION.getStoredProcedure()));
        assertTrue(logs.get(5).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }


    @Test
    void testPostProcessInvestigationTBMessage() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":12}}";

        List<DatamartData> masterData = getTBDatamart(123L, 201L);
        when(investigationRepositoryMock.executeStoredProcForPublicHealthCaseIds("12")).thenReturn(masterData);
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();
        String expectedPublicHealthCaseIdsString = "123";

        verify(investigationRepositoryMock).executeStoredProcForDTbPam(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDTbHiv(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDDiseaseSite(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDAddlRisk(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDGt12Reas(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDMoveCntry(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDMoveCnty(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDMoveState(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDMovedWhere(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDHcProvTy3(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDOutOfCntry(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDSmrExamTy(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForFTbPam(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForTbPamLdf(expectedPublicHealthCaseIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(36, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(INVESTIGATION.getStoredProcedure()));
        assertTrue(logs.get(5).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessInvestigationVARMessage() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":12}}";

        List<DatamartData> masterData = getVarDatamart(123L, 201L);
        when(investigationRepositoryMock.executeStoredProcForPublicHealthCaseIds("12")).thenReturn(masterData);
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();
        String expectedPublicHealthCaseIdsString = "123";

        verify(investigationRepositoryMock).executeStoredProcForDVarPam(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDRashLocGen(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForDPcrSource(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForVarPamLdf(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForFVarPam(expectedPublicHealthCaseIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(18, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(INVESTIGATION.getStoredProcedure()));
        assertTrue(logs.get(5).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }


    @Test
    void testPostProcessSummaryMessage() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123,\"case_type_cd\":\"S\"}}";
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedPublicHealthCaseIdsString = "123";
        verify(investigationRepositoryMock).executeStoredProcForSummaryReportCase(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForSR100Datamart(expectedPublicHealthCaseIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(12, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(INVESTIGATION.getStoredProcedure()));
        assertTrue(logs.get(5).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessAggregateMessage() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123,\"case_type_cd\":\"A\"}}";
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedPublicHealthCaseIdsString = "123";
        verify(investigationRepositoryMock).executeStoredProcForAggregateReport(expectedPublicHealthCaseIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(10, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(INVESTIGATION.getStoredProcedure()));
        assertTrue(logs.get(5).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessNotificationMessage() {
        String topic = "dummy_notification";
        String key = "{\"payload\":{\"public_health_case_uid\":122,\"notification_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedNotificationIdsString = "123";
        verify(investigationRepositoryMock).executeStoredProcForNotificationIds(expectedNotificationIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(NOTIFICATION.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessNBSPageMessage() {
        String topic = "dummy_NBS_page";
        String key = "{\"payload\":{\"nbs_page_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedNBSPageIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForNBSPage(expectedNBSPageIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(5, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(PAGE.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessSummaryNotificationMessage() {
        String topic = "dummy_notification";
        String key = "{\"payload\":{\"public_health_case_uid\":122,\"notification_uid\":123,\"act_type_cd\":\"SummaryNotification\"}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedPublicHealthCaseIdsString = "122";
        String expectedNotificationIdsString = "123";
        verify(investigationRepositoryMock).executeStoredProcForNotificationIds(expectedNotificationIdsString);
        verify(investigationRepositoryMock).executeStoredProcForSummaryReportCase(expectedPublicHealthCaseIdsString);
        verify(investigationRepositoryMock).executeStoredProcForSR100Datamart(expectedPublicHealthCaseIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(10, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(NOTIFICATION.getStoredProcedure()));
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
        assertEquals(7, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(CASE_MANAGEMENT.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
        assertTrue(logs.get(4).getFormattedMessage().contains(F_STD_PAGE_CASE.getStoredProcedure()));
        assertTrue(logs.get(5).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessPageBuilder() {
        String topic = "dummy_investigation";
        String key1 = "{\"payload\":{\"public_health_case_uid\":123}}";
        String key2 = "{\"payload\":{\"public_health_case_uid\":124}}";
        String msg1 = "{\"payload\":{\"public_health_case_uid\":123, \"rdb_table_name_list\":\"D_INV_CLINICAL,D_INV_ADMINISTRATIVE\"}}";
        String msg2 = "{\"payload\":{\"public_health_case_uid\":124, \"rdb_table_name_list\":\"D_INV_ADMINISTRATIVE\"}}";

        Long expectedPublicHealthCaseId = 123L;
        String expectedRdbTableName = "D_INV_CLINICAL";

        postProcessingServiceMock.postProcessMessage(topic, key1, msg1);
        assertTrue(postProcessingServiceMock.pbCache.containsKey(expectedRdbTableName));
        assertTrue(postProcessingServiceMock.pbCache.get(expectedRdbTableName).contains(expectedPublicHealthCaseId));

        postProcessingServiceMock.postProcessMessage(topic, key2, msg2);

        postProcessingServiceMock.processCachedIds();
        assertTrue(postProcessingServiceMock.pbCache.isEmpty());
        verify(investigationRepositoryMock).executeStoredProcForPageBuilder("123", "D_INV_CLINICAL");
        verify(investigationRepositoryMock).executeStoredProcForPageBuilder("123,124", "D_INV_ADMINISTRATIVE");

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(15, logs.size());
        assertTrue(logs.getLast().getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
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
        assertEquals(7, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(INTERVIEW.getStoredProcedure()));
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
        verify(postProcRepositoryMock).executeStoredProcForLdfDimensionalData(expectedLdfIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(7, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(LDF_DATA.getStoredProcedure()));
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

        assertTrue(postProcessingServiceMock.obsCache.containsKey(MORB_REPORT));
        assertTrue(postProcessingServiceMock.obsCache.get(MORB_REPORT).contains(123L));

        postProcessingServiceMock.processCachedIds();
        assertTrue(postProcessingServiceMock.obsCache.isEmpty());

        String expectedObsIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForMorbReport(expectedObsIdsString);
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains("sp_d_morbidity_report_postprocessing"));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));

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

        assertTrue(postProcessingServiceMock.obsCache.containsKey(LAB_REPORT));
        assertTrue(postProcessingServiceMock.obsCache.get(LAB_REPORT).contains(123L));

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
        assertTrue(postProcessingServiceMock.obsCache.isEmpty());

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

        String treatmentKey1 = "{\"payload\":{\"treatment_uid\":789}}";
        String treatmentKey2 = "{\"payload\":{\"treatment_uid\":790}}";
        String treatmentTopic = "dummy_treatment";

        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey1, orgKey1);
        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey2, orgKey2);
        postProcessingServiceMock.postProcessMessage(ntfTopic, ntfKey1, ntfKey1);
        postProcessingServiceMock.postProcessMessage(ntfTopic, ntfKey2, ntfKey2);
        postProcessingServiceMock.postProcessMessage(invTopic, invKey1, invKey1);
        postProcessingServiceMock.postProcessMessage(invTopic, invKey2, invKey2);
        postProcessingServiceMock.postProcessMessage(placeTopic, placeKey1, placeKey1);
        postProcessingServiceMock.postProcessMessage(placeTopic, placeKey2, placeKey2);
        postProcessingServiceMock.postProcessMessage(treatmentTopic, treatmentKey1, treatmentKey1);
        postProcessingServiceMock.postProcessMessage(treatmentTopic, treatmentKey2, treatmentKey2);

        assertTrue(postProcessingServiceMock.idCache.containsKey(orgTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(invTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(ntfTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(placeTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(treatmentTopic));

        postProcessingServiceMock.processCachedIds();

        verify(postProcRepositoryMock).executeStoredProcForOrganizationIds("123,124");
        verify(investigationRepositoryMock).executeStoredProcForPublicHealthCaseIds("234,235");
        verify(investigationRepositoryMock).executeStoredProcForNotificationIds("567,568");
        verify(postProcRepositoryMock).executeStoredProcForDPlace("123,124");
        verify(postProcRepositoryMock).executeStoredProcForTreatment("789,790");
    }

    @Test
    void testPostProcessContactData() {
        String topic = "dummy_contact";
        String key = "{\"payload\":{\"contact_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        assertEquals(123L, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        postProcessingServiceMock.processCachedIds();

        String expectedIntIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForDContactRecord(expectedIntIdsString);
        verify(postProcRepositoryMock).executeStoredProcForFContactRecordCase(expectedIntIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(6, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(CONTACT.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessVaccinationData() {
        String topic = "dummy_vaccination";
        String key = "{\"payload\":{\"vaccination_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        assertEquals(123L, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        postProcessingServiceMock.processCachedIds();

        String expectedIntIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForDVaccination(expectedIntIdsString);
        verify(postProcRepositoryMock).executeStoredProcForFVaccination(expectedIntIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(6, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(VACCINATION.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessCacheIdsPriority() {

        String pageKey = "{\"payload\":{\"nbs_page_uid\":122}}";
        String orgKey = "{\"payload\":{\"organization_uid\":123}}";
        String providerKey = "{\"payload\":{\"provider_uid\":124}}";
        String patientKey = "{\"payload\":{\"patient_uid\":125}}";
        String userProfileKey = "{\"payload\":{\"auth_user_uid\":132}}";
        String placeKey = "{\"payload\":{\"place_uid\":131}}";
        String investigationKey = "{\"payload\":{\"public_health_case_uid\":126}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":127}}";
        String caseManagementKey = "{\"payload\":{\"public_health_case_uid\":128,\"case_management_uid\":1001}}";
        String ldfKey = "{\"payload\":{\"ldf_uid\":129}}";
        String interviewKey = "{\"payload\":{\"interview_uid\":130}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";
        String observationMsg = "{\"payload\":{\"observation_uid\":130, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"MorbReport\"}}";
        String contactKey = "{\"payload\":{\"contact_uid\":123}}";
        String treatmentKey = "{\"payload\":{\"treatment_uid\":133}}";
        String vacKey = "{\"payload\":{\"vaccination_uid\":123}}";

        String pageTopic = "dummy_NBS_page";
        String orgTopic = "dummy_organization";
        String providerTopic = "dummy_provider";
        String patientTopic = "dummy_patient";
        String userProfileTopic = "dummy_auth_user";
        String placeTopic = "dummy_place";
        String invTopic = "dummy_investigation";
        String ntfTopic = "dummy_notification";
        String intTopic = "dummy_interview";
        String ldfTopic = "dummy_ldf_data";
        String cmTopic = "dummy_case_management";
        String obsTopic = "dummy_observation";
        String contactTopic = "dummy_contact";
        String treatmentTopic = "dummy_treatment";
        String vacTopic = "dummy_vaccination";

        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.postProcessMessage(providerTopic, providerKey, providerKey);
        postProcessingServiceMock.postProcessMessage(patientTopic, patientKey, patientKey);
        postProcessingServiceMock.postProcessMessage(userProfileTopic, userProfileKey, userProfileKey);
        postProcessingServiceMock.postProcessMessage(placeTopic, placeKey, placeKey);
        postProcessingServiceMock.postProcessMessage(intTopic, interviewKey, interviewKey);
        postProcessingServiceMock.postProcessMessage(ntfTopic, notificationKey, notificationKey);
        postProcessingServiceMock.postProcessMessage(treatmentTopic, treatmentKey, treatmentKey);
        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey, orgKey);
        postProcessingServiceMock.postProcessMessage(obsTopic, observationKey, observationMsg);
        postProcessingServiceMock.postProcessMessage(ldfTopic, ldfKey, ldfKey);
        postProcessingServiceMock.postProcessMessage(pageTopic, pageKey, pageKey);
        postProcessingServiceMock.postProcessMessage(cmTopic, caseManagementKey, caseManagementKey);
        postProcessingServiceMock.postProcessMessage(contactTopic, contactKey, contactKey);
        postProcessingServiceMock.postProcessMessage(vacTopic, vacKey, vacKey);

        postProcessingServiceMock.processCachedIds();

        List<ILoggingEvent> logs = listAppender.list;

        List<String> topicLogList = logs.stream().map(ILoggingEvent::getFormattedMessage).filter(m -> m.matches(
                "Processing .+ for topic: .*")).toList();
        assertTrue(topicLogList.get(0).contains(pageTopic));
        assertTrue(topicLogList.get(1).contains(orgTopic));
        assertTrue(topicLogList.get(2).contains(providerTopic));
        assertTrue(topicLogList.get(3).contains(patientTopic));
        assertTrue(topicLogList.get(4).contains(userProfileTopic));
        assertTrue(topicLogList.get(5).contains(placeTopic));
        assertTrue(topicLogList.get(6).contains(invTopic));
        assertTrue(topicLogList.get(8).contains(invTopic));
        assertTrue(topicLogList.get(9).contains(ntfTopic));
        assertTrue(topicLogList.get(10).contains(treatmentTopic));
        assertTrue(topicLogList.get(11).contains(intTopic));
        assertTrue(topicLogList.get(12).contains(intTopic));
        assertTrue(topicLogList.get(13).contains(cmTopic));
        assertTrue(topicLogList.get(14).contains(cmTopic));
        assertTrue(topicLogList.get(15).contains(ldfTopic));
        assertTrue(topicLogList.get(16).contains(ldfTopic));
        assertTrue(topicLogList.get(17).contains(obsTopic));
        assertTrue(topicLogList.get(18).contains(contactTopic));
        assertTrue(topicLogList.get(19).contains(contactTopic));
        assertTrue(topicLogList.get(20).contains(vacTopic));
        assertTrue(topicLogList.get(21).contains(vacTopic));
    }

    @Test
    void testPostProcessTBDatamart() {
        String topic = "tb_datamart";
        String msg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10160\"," +
                "\"datamart\":\"tb_datamart\",\"stored_procedure\":\"\"}}";

        postProcessingServiceMock.postProcessDatamart(topic, msg);
        postProcessingServiceMock.processDatamartIds();

        String id = "123";
        verify(investigationRepositoryMock).executeStoredProcForTbDatamart(id);
        verify(investigationRepositoryMock).executeStoredProcForTbHivDatamart(id);

        
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(5, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(TB_DATAMART.getStoredProcedure()));
        assertTrue(logs.get(4).getFormattedMessage().contains(TB_HIV_DATAMART.getStoredProcedure()));
    }

    @Test
    void testPostProcessVarDatamart() {
        String topic = "var_datamart";
        String msg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10160\"," +
                "\"datamart\":\"var_datamart\",\"stored_procedure\":\"\"}}";

        postProcessingServiceMock.postProcessDatamart(topic, msg);
        postProcessingServiceMock.processDatamartIds();

        String id = "123";
        verify(investigationRepositoryMock).executeStoredProcForVarDatamart(id);
        
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(3, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(VAR_DATAMART.getStoredProcedure()));
    }


    @ParameterizedTest
    @MethodSource("datamartTestData")
    void testPostProcessDatamart(DatamartTestCase testCase) {
        String topic = "dummy_datamart";
        postProcessingServiceMock.postProcessDatamart(topic, testCase.msg);
        postProcessingServiceMock.processDatamartIds();
        testCase.verificationStep.accept(investigationRepositoryMock);
        assertTrue(postProcessingServiceMock.dmCache.containsKey(testCase.datamartEntityName));
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(testCase.logSize, logs.size());
        assertEquals(logs.getLast().getFormattedMessage(),
                "Stored proc execution completed: " + testCase.storedProcedure);
    }

    static Stream<DatamartTestCase> datamartTestData() {
        return Stream.of(
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10110\"," +
                                "\"datamart\":\"Hepatitis_Datamart\",\"stored_procedure\":\"sp_hepatitis_datamart_postprocessing\"}}",
                        HEPATITIS_DATAMART.getEntityName(), HEPATITIS_DATAMART.getStoredProcedure(), 5,
                        repo -> verify(repo).executeStoredProcForHepDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10110\"," +
                                "\"datamart\":\"Std_Hiv_Datamart\",\"stored_procedure\":\"sp_std_hiv_datamart_postprocessing\"}}",
                        STD_HIV_DATAMART.getEntityName(), STD_HIV_DATAMART.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForStdHIVDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                                "\"datamart\":\"Generic_Case\",\"stored_procedure\":\"sp_generic_case_datamart_postprocessing\"}}",
                        GENERIC_CASE.getEntityName(), GENERIC_CASE.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForGenericCaseDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                                "\"datamart\":\"Generic_Case,LDF_GENERIC\",\"stored_procedure\":\"sp_ldf_generic_datamart_postprocessing\"}}",
                        "Generic_Case,LDF_GENERIC", LDF_GENERIC.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForGenericCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfGenericDatamart("123");
                        }),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                                "\"datamart\":\"Generic_Case,LDF_MUMPS\",\"stored_procedure\":\"sp_ldf_mumps_datamart_postprocessing\"}}",
                        "Generic_Case,LDF_MUMPS", LDF_MUMPS.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForGenericCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfMumpsDatamart("123");
                            }
                        ),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                                "\"datamart\":\"Generic_Case,LDF_FOODBORNE\",\"stored_procedure\":\"sp_ldf_mumps_datamart_postprocessing\"}}",
                        "Generic_Case,LDF_FOODBORNE", LDF_FOODBORNE.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForGenericCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfFoodBorneDatamart("123");
                        }
                ),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                                "\"datamart\":\"Generic_Case,LDF_TETANUS\",\"stored_procedure\":\"sp_ldf_mumps_datamart_postprocessing\"}}",
                        "Generic_Case,LDF_TETANUS", LDF_TETANUS.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForGenericCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfTetanusDatamart("123");
                        }
                ),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10370\"," +
                                "\"datamart\":\"CRS_Case\",\"stored_procedure\":\"sp_crs_case_datamart_postprocessing\"}}",
                                    CRS_CASE.getEntityName(), CRS_CASE.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForCRSCaseDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10370\"," +
                                "\"datamart\":\"CRS_Case,LDF_VACCINE_PREVENT_DISEASES\",\"stored_procedure\":\"sp_crs_case_datamart_postprocessing\"}}",
                        "CRS_Case,LDF_VACCINE_PREVENT_DISEASES", LDF_VACCINE_PREVENT_DISEASES.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForCRSCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfVacPreventDiseasesDatamart("123");
                        }),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10200\"," +
                                "\"datamart\":\"Rubella_Case\",\"stored_procedure\":\"sp_rubella_case_datamart_postprocessing\"}}",
                        RUBELLA_CASE.getEntityName(), RUBELLA_CASE.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForRubellaCaseDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10200\"," +
                                "\"datamart\":\"Rubella_Case,LDF_VACCINE_PREVENT_DISEASES\",\"stored_procedure\":\"sp_rubella_case_datamart_postprocessing\"}}",
                        "Rubella_Case,LDF_VACCINE_PREVENT_DISEASES", LDF_VACCINE_PREVENT_DISEASES.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForRubellaCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfVacPreventDiseasesDatamart("123");
                        }),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10140\"," +
                                "\"datamart\":\"Measles_Case\",\"stored_procedure\":\"sp_measles_case_datamart_postprocessing\"}}",
                        MEASLES_CASE.getEntityName(), MEASLES_CASE.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForMeaslesCaseDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10140\"," +
                                "\"datamart\":\"Measles_Case,LDF_VACCINE_PREVENT_DISEASES\",\"stored_procedure\":\"sp_measles_case_datamart_postprocessing\"}}",
                        "Measles_Case,LDF_VACCINE_PREVENT_DISEASES", LDF_VACCINE_PREVENT_DISEASES.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForMeaslesCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfVacPreventDiseasesDatamart("123");
                        }),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":null," +
                                "\"datamart\":\"Case_Lab_Datamart\",\"stored_procedure\":\"sp_case_lab_datamart_postprocessing\"}}",
                        CASE_LAB_DATAMART.getEntityName(), CASE_LAB_DATAMART.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForCaseLabDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10160\"," +
                                "\"datamart\":\"BMIRD_Case\",\"stored_procedure\":\"sp_bmird_case_datamart_postprocessing\"}}",
                        BMIRD_CASE.getEntityName(), BMIRD_STREP_PNEUMO_DATAMART.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForBmirdCaseDatamart("123");
                            verify(repo).executeStoredProcForBmirdStrepPneumoDatamart("123");
                        }),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10160\"," +
                                "\"datamart\":\"BMIRD_Case,LDF_BMIRD\",\"stored_procedure\":\"sp_bmird_case_datamart_postprocessing\"}}",
                        "BMIRD_Case,LDF_BMIRD", BMIRD_STREP_PNEUMO_DATAMART.getStoredProcedure(), 7,
                        repo -> {
                            verify(repo).executeStoredProcForBmirdCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfBmirdDatamart("123");
                            verify(repo).executeStoredProcForBmirdStrepPneumoDatamart("123");
                        }),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                                "\"datamart\":\"Hepatitis_Case\",\"stored_procedure\":\"sp_hepatitis_case_datamart_postprocessing\"}}",
                        HEPATITIS_CASE.getEntityName(), HEPATITIS_CASE.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForHepatitisCaseDatamart("123")),
                    new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10110\"," +
                                "\"datamart\":\"Hepatitis_Case,LDF_HEPATITIS\",\"stored_procedure\":\"sp_hepatitis_case_datamart_postprocessing\"}}",
                        "Hepatitis_Case,LDF_HEPATITIS", LDF_HEPATITIS.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForHepatitisCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfHepatitisDatamart("123");
                        }), 
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                                "\"datamart\":\"Pertussis_Case\",\"stored_procedure\":\"sp_pertussis_case_datamart_postprocessing\"}}",
                        PERTUSSIS_CASE.getEntityName(), PERTUSSIS_CASE.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForPertussisCaseDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                                "\"datamart\":\"Pertussis_Case,LDF_VACCINE_PREVENT_DISEASES\",\"stored_procedure\":\"sp_pertussis_case_datamart_postprocessing\"}}",
                        "Pertussis_Case,LDF_VACCINE_PREVENT_DISEASES", LDF_VACCINE_PREVENT_DISEASES.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForPertussisCaseDatamart("123");
                            verify(repo).executeStoredProcForLdfVacPreventDiseasesDatamart("123");
                        }),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"11065\"," +
                                "\"datamart\":\"Covid_Case_Datamart\",\"stored_procedure\":\"sp_covid_case_datamart_postprocessing\"}}",
                        COVID_CASE_DATAMART.getEntityName(), COVID_CASE_DATAMART.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForCovidCaseDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"11065\"," +
                                "\"datamart\":\"Covid_Contact_Datamart\",\"stored_procedure\":\"sp_covid_contact_datamart_postprocessing\"}}",
                        COVID_CONTACT_DATAMART.getEntityName(), COVID_CONTACT_DATAMART.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForCovidContactDatamart("123")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"11065\"," +
                                "\"datamart\":\"Covid_Vaccination_Datamart\",\"stored_procedure\":\"sp_covid_vaccination_datamart_postprocessing\"}}",
                        COVID_VACCINATION_DATAMART.getEntityName(), COVID_VACCINATION_DATAMART.getStoredProcedure(), 3,
                        repo -> verify(repo).executeStoredProcForCovidVacDatamart("123", "456")),
                new DatamartTestCase(
                        "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"observation_uid\":789,\"condition_cd\":\"11065\"," +
                                "\"datamart\":\"Covid_Lab_Datamart\",\"stored_procedure\":\"sp_covid_lab_datamart_postprocessing\"}}",
                        COVID_LAB_DATAMART.getEntityName(), COVID_LAB_CELR_DATAMART.getStoredProcedure(), 5,
                        repo -> {
                            verify(repo).executeStoredProcForCovidLabDatamart("789");
                            verify(repo).executeStoredProcForCovidLabCelrDatamart("789");
                        })
        );
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
        List<DatamartData> invResults = getDatamartData(123L, null);

        datamartProcessor.datamartTopic = dmTopic;
        when(investigationRepositoryMock.executeStoredProcForPublicHealthCaseIds("123")).thenReturn(invResults);
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void testProduceDatamartTopicWithNoDatamart() {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";
        String dmTopic = "dummy_datamart";

        List<DatamartData> invResults = getDatamartData(123L, 200L, "");

        datamartProcessor.datamartTopic = dmTopic;
        when(investigationRepositoryMock.executeStoredProcForPublicHealthCaseIds("123")).thenReturn(invResults);
        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void testPostProcessEventMetricNoIds() {
        // Test with an event that doesn't trigger the event metric datamart procedure
        String orgKey = "{\"payload\":{\"organization_uid\":123}}";
        String orgTopic = "dummy_organization";
        postProcessingServiceMock.postProcessMessage(orgTopic, orgKey, orgKey);
        postProcessingServiceMock.processCachedIds();

        verify(postProcRepositoryMock, never()).executeStoredProcForEventMetric(any(),any(),any(),any(),any());
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals("No updates to EVENT_METRIC Datamart", logs.get(4).getFormattedMessage());
    }

    @Test
    void testPostProcessEventMetric() {

        String investigationKey1 = "{\"payload\":{\"public_health_case_uid\":126}}";
        String investigationKey2 = "{\"payload\":{\"public_health_case_uid\":235}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":127}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";
        String observationMsg = "{\"payload\":{\"observation_uid\":130, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"MorbReport\"}}";
        String contactKey = "{\"payload\":{\"contact_uid\":123}}";
        String vaccinationKey = "{\"payload\":{\"vaccination_uid\":999}}";

        String invTopic = "dummy_investigation";
        String ntfTopic = "dummy_notification";
        String obsTopic = "dummy_observation";
        String crTopic = "dummy_contact";
        String vaxTopic = "dummy_vaccination";

        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey1, investigationKey1);
        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey2, investigationKey2);
        postProcessingServiceMock.postProcessMessage(ntfTopic, notificationKey, notificationKey);
        postProcessingServiceMock.postProcessMessage(obsTopic, observationKey, observationMsg);
        postProcessingServiceMock.postProcessMessage(crTopic, contactKey, contactKey);
        postProcessingServiceMock.postProcessMessage(vaxTopic, vaccinationKey, vaccinationKey);
        postProcessingServiceMock.processCachedIds();

        verify(postProcRepositoryMock).executeStoredProcForEventMetric("126,235", "130", "127", "123", "999");
    }

    @Test
    void testPostProcessHep100NoIds() {
        // Test with an event that doesn't trigger the Hep100 datamart procedure
        String contactKey = "{\"payload\":{\"contact_uid\":123}}";
        String crTopic = "dummy_contact";
        postProcessingServiceMock.postProcessMessage(crTopic, contactKey, contactKey);
        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock, never()).executeStoredProcForHep100(any(),any(),any(),any());
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals("No updates to HEP100 Datamart", logs.get(6).getFormattedMessage());
    }

    @Test
    void testPostProcessHep100() {

        String investigationKey1 = "{\"payload\":{\"public_health_case_uid\":126}}";
        String investigationKey2 = "{\"payload\":{\"public_health_case_uid\":235}}";
        String patientKey = "{\"payload\":{\"patient_uid\":127}}";
        String providerKey = "{\"payload\":{\"provider_uid\":130}}";
        String organizationKey = "{\"payload\":{\"organization_uid\":123}}";


        String invTopic = "dummy_investigation";
        String patTopic = "dummy_patient";
        String provTopic = "dummy_provider";
        String orgTopic = "dummy_organization";

        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey1, investigationKey1);
        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey2, investigationKey2);
        postProcessingServiceMock.postProcessMessage(patTopic, patientKey, patientKey);
        postProcessingServiceMock.postProcessMessage(provTopic, providerKey, providerKey);
        postProcessingServiceMock.postProcessMessage(orgTopic, organizationKey, organizationKey);

        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock).executeStoredProcForHep100("126,235", "127", "130", "123");
    }

    @Test
    void testPostProcessInvSummary() {

        String investigationKey = "{\"payload\":{\"public_health_case_uid\":126}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":127}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";

        String invTopic = "dummy_investigation";
        String notTopic = "dummy_notification";
        String obsTopic = "dummy_observation";

        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.postProcessMessage(notTopic, notificationKey, notificationKey);
        postProcessingServiceMock.postProcessMessage(obsTopic, observationKey, observationKey);

        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock).executeStoredProcForInvSummaryDatamart("126", "127", "130");
    }

    @Test
    void testPostProcessInvSummaryNoIds() {

        String contactKey = "{\"payload\":{\"contact_uid\":123}}";
        String crTopic = "dummy_contact";

        postProcessingServiceMock.postProcessMessage(crTopic, contactKey, contactKey);
        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock, never()).executeStoredProcForInvSummaryDatamart(any(),any(),any());
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals("No updates to INV_SUMMARY Datamart", logs.get(7).getFormattedMessage());
    }

    @Test
    void testPostProcessMorbidityReportDatamartNoIds() {
        // Test with an event that doesn't trigger the morbidity report datamart procedure
        String contactKey = "{\"payload\":{\"contact_uid\":123}}";
        String crTopic = "dummy_contact";
        postProcessingServiceMock.postProcessMessage(crTopic, contactKey, contactKey);
        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock, never()).executeStoredProcForMorbidityReportDatamart(any(),any(),any(),any(),any());
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals("No updates to MORBIDITY_REPORT_DATAMART", logs.getLast().getFormattedMessage());
    }


    @Test
    void testPostProcessMorbidityReportDatamart() {

        String investigationKey1 = "{\"payload\":{\"public_health_case_uid\":126}}";
        String investigationKey2 = "{\"payload\":{\"public_health_case_uid\":235}}";
        String patientKey = "{\"payload\":{\"patient_uid\":127}}";
        String providerKey = "{\"payload\":{\"provider_uid\":130}}";
        String organizationKey = "{\"payload\":{\"organization_uid\":123}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";
        String observationMsg = "{\"payload\":{\"observation_uid\":130, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"MorbReport\"}}";

        String invTopic = "dummy_investigation";
        String patTopic = "dummy_patient";
        String provTopic = "dummy_provider";
        String orgTopic = "dummy_organization";
        String obsTopic = "dummy_observation";

        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey1, investigationKey1);
        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey2, investigationKey2);
        postProcessingServiceMock.postProcessMessage(patTopic, patientKey, patientKey);
        postProcessingServiceMock.postProcessMessage(provTopic, providerKey, providerKey);
        postProcessingServiceMock.postProcessMessage(orgTopic, organizationKey, organizationKey);
        postProcessingServiceMock.postProcessMessage(obsTopic, observationKey, observationMsg);

        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock).executeStoredProcForMorbidityReportDatamart("130", "127", "130", "123", "126,235");
    }

    @Test
    void testPostProcessDynMarts() {

        String investigationKey = "{\"payload\":{\"public_health_case_uid\":126}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":127}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";

        String invTopic = "dummy_investigation";
        String notTopic = "dummy_notification";
        String obsTopic = "dummy_observation";

        postProcessingServiceMock.postProcessMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.postProcessMessage(notTopic, notificationKey, notificationKey);
        postProcessingServiceMock.postProcessMessage(obsTopic, observationKey, observationKey);

        List<DatamartData> masterData = new ArrayList<>();
        DatamartData datamartData = new DatamartData();
        datamartData.setDatamart("GENERIC_V2");
        datamartData.setPublicHealthCaseUid(126L);
        masterData.add(datamartData);
        when(postProcRepositoryMock.executeStoredProcForInvSummaryDatamart("126", "127", "130")).thenReturn(masterData);

        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();


        Awaitility.await()
            .atMost(5, TimeUnit.SECONDS)
            .untilAsserted(() -> {
                verify(postProcRepositoryMock).executeStoredProcForInvSummaryDatamart("126","127","130");
                verify(postProcRepositoryMock).executeStoredProcForDynDatamart("GENERIC_V2", "126");
            });
    }


    @Test
    void testPostProcessUserProfileMessage() {
        String topic = "dummy_auth_user";
        String key = "{\"payload\":{\"auth_user_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedUserProfileIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForUserProfile(expectedUserProfileIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(5, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(AUTH_USER.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessMultipleMessagesWithUserProfile() {
        String userProfileKey1 = "{\"payload\":{\"auth_user_uid\":123}}";
        String userProfileKey2 = "{\"payload\":{\"auth_user_uid\":124}}";
        String userProfileTopic = "dummy_auth_user";

        postProcessingServiceMock.postProcessMessage(userProfileTopic, userProfileKey1, userProfileKey1);
        postProcessingServiceMock.postProcessMessage(userProfileTopic, userProfileKey2, userProfileKey2);

        assertTrue(postProcessingServiceMock.idCache.containsKey(userProfileTopic));
        postProcessingServiceMock.processCachedIds();
        verify(postProcRepositoryMock).executeStoredProcForUserProfile("123,124");
    }

    @Test
    void testPostProcessNoUserProfileUidException() {
        String userProfileKey = "{\"payload\":{}}";
        String topic = "dummy_user_profile";

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> postProcessingServiceMock.postProcessMessage(topic, userProfileKey, userProfileKey));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
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
        assertEquals(5, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(D_PLACE.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessMultipleMessagesWithPlace() {
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

    @Test
    void testPostProcessTreatmentMessage() {
        String topic = "dummy_treatment";
        String key = "{\"payload\":{\"treatment_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        assertEquals(123L, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        String expectedTreatmentIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForTreatment(expectedTreatmentIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(9, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(TREATMENT.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessNoTreatmentUidException() {
        String treatmentKey = "{\"payload\":{}}";
        String topic = "dummy_treatment";

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> postProcessingServiceMock.postProcessMessage(topic, treatmentKey, treatmentKey));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @ParameterizedTest
    @CsvSource({
            "'{\"payload\":{\"public_health_case_uid\":123,\"rdb_table_name_list\":null}}'",
            "'{\"payload\":{\"patient_uid\":123}}'",
            "'{\"payload\":{invalid}'"
    })
    void testPostProcessNoTablesOrInvalidPayload(String payload) {
        String topic = "dummy_investigation";
        String key = "{\"payload\":{\"public_health_case_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, payload);
        assertTrue(postProcessingServiceMock.pbCache.isEmpty());

        postProcessingServiceMock.processCachedIds();
        verify(investigationRepositoryMock, never()).executeStoredProcForPageBuilder(anyString(), anyString());
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

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> postProcessingServiceMock.postProcessMessage(topic,
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
            "'{\"payload\":{\"public_health_case_uid\":null,\"patient_uid\":456,\"datamart\":\"dummy\"}}'",
            "'{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":null,\"datamart\":\"dummy\"}}'",
            "'{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"datamart\":null}}'",

    })
    void testPostProcessDatamartIncompleteData(String msg) {
        String topic = "dummy_datamart";

        postProcessingServiceMock.postProcessDatamart(topic, msg);
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.getLast().getFormattedMessage().contains("Skipping further processing"));
    }

    @Test
    void testProcessDatamartEmptyCache() {
        postProcessingServiceMock.dmCache.put("Datamart", new ConcurrentHashMap<>());
        postProcessingServiceMock.processDatamartIds();

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(1, logs.size());
        assertTrue(logs.getFirst().getMessage().contains("No data to process from the datamart topics."));
    }

    @Test
    void testProcessDatamartInvalidKey() {
        String topic = "dummy_datamart";
        String msg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10370\"," +
                "\"datamart\":\"UNKNOWN\",\"stored_procedure\":\"sp_nrt_unknown_postprocessing\"}}";

        postProcessingServiceMock.postProcessDatamart(topic, msg);
        postProcessingServiceMock.processDatamartIds();

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(2, logs.size());
        assertTrue(logs.getLast().getMessage().contains("No associated datamart processing logic found"));
    }

    @Test
    void testPostProcessUnknownTopic() {
        String topic = "dummy_topic";
        String key = "{\"payload\":{\"unknown_uid\":123}}";

        postProcessingServiceMock.postProcessMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.get(2).getFormattedMessage().contains("Unknown topic: " + topic + " cannot be processed"));
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

    private List<DatamartData> getDatamartData(Long phcUid, Long patientUid, String... dmVar) {
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = new DatamartData();
        datamartData.setPublicHealthCaseUid(phcUid);
        datamartData.setPatientUid(patientUid);
        datamartData.setConditionCd("10110");
        datamartData.setDatamart(dmVar.length > 0 ? dmVar[0] : HEPATITIS_DATAMART.getEntityName());
        datamartData.setStoredProcedure(HEPATITIS_DATAMART.getStoredProcedure());
        datamartDataLst.add(datamartData);
        return datamartDataLst;
    }

    private List<DatamartData> getTBDatamart(Long phcUid, Long patientUid, String... dmVar) {
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = new DatamartData();
        datamartData.setPublicHealthCaseUid(phcUid);
        datamartData.setPatientUid(patientUid);
        datamartData.setConditionCd("10220");
        datamartData.setDatamart(dmVar.length > 0 ? dmVar[0] : TB_DATAMART.getEntityName());
        datamartData.setStoredProcedure(TB_DATAMART.getStoredProcedure());
        datamartData.setInvestigationFormCd("INV_FORM_RVCT");
        datamartDataLst.add(datamartData);
        return datamartDataLst;
    }

    private List<DatamartData> getVarDatamart(Long phcUid, Long patientUid, String... dmVar) {
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = new DatamartData();
        datamartData.setPublicHealthCaseUid(phcUid);
        datamartData.setPatientUid(patientUid);
        datamartData.setConditionCd("10030");
        datamartData.setDatamart(dmVar.length > 0 ? dmVar[0] : VAR_DATAMART.getEntityName());
        datamartData.setStoredProcedure(VAR_DATAMART.getStoredProcedure());
        datamartData.setInvestigationFormCd("INV_FORM_VAR");
        datamartDataLst.add(datamartData);
        return datamartDataLst;
    }

    static class DatamartTestCase {
        String msg;
        String datamartEntityName;
        String storedProcedure;
        int logSize;
        Consumer<InvestigationRepository> verificationStep;

        DatamartTestCase(String msg, String datamartEntityName, String storedProcedure,
                int logSize, Consumer<InvestigationRepository> verificationStep) {
            this.msg = msg;
            this.datamartEntityName = datamartEntityName;
            this.storedProcedure = storedProcedure;
            this.logSize = logSize;
            this.verificationStep = verificationStep;
        }
    }}