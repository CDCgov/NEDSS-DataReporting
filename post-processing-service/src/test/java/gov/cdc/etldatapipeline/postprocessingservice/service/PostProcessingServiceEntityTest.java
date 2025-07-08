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

import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.*;
import static gov.cdc.etldatapipeline.postprocessingservice.service.PostProcessingService.LAB_REPORT;
import static gov.cdc.etldatapipeline.postprocessingservice.service.PostProcessingService.MORB_REPORT;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class PostProcessingServiceEntityTest {

    @InjectMocks @Spy

    private PostProcessingService postProcessingServiceMock;
    @Mock
    private PostProcRepository postProcRepositoryMock;
    @Mock
    private static InvestigationRepository investigationRepositoryMock;

    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
    private AutoCloseable closeable;

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        ProcessDatamartData datamartProcessor = new ProcessDatamartData(kafkaTemplate);
        postProcessingServiceMock = spy(new PostProcessingService(postProcRepositoryMock, investigationRepositoryMock,
                datamartProcessor));

        postProcessingServiceMock.setInvestigationTopic("dummy_investigation");

        Logger logger = (Logger) LoggerFactory.getLogger(PostProcessingService.class);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    void tearDown() throws Exception {
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
            "dummy_NBS_page, '{\"payload\":{\"nbs_page_uid\":123}}', 123",
            "dummy_state_defined_field_metadata, '{\"payload\":{\"ldf_uid\":123}}', 123"
    })
    void testProcessNrtMessage(String topic, String messageKey, Long expectedId) {
        postProcessingServiceMock.processNrtMessage(topic, messageKey, messageKey);
        assertEquals(expectedId, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));
    }

    @Test
    void testPostProcessPatientMessage() {
        String topic = "dummy_patient";
        String key = "{\"payload\":{\"patient_uid\":123}}";

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
        postProcessingServiceMock.processNrtMessage(topic, key, key);
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

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
        postProcessingServiceMock.processNrtMessage(topic, key, key);
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

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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

        postProcessingServiceMock.processNrtMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedNBSPageIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForNBSPage(expectedNBSPageIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(5, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(PAGE.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessConditionCodeMessage() {
        String topic = "dummy_Condition_code";
        String key = "{\"payload\":{\"condition_cd\":\"123A\"}}";

        postProcessingServiceMock.processNrtMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        String expectedConditionCdsString = "123A";
        verify(postProcRepositoryMock).executeStoredProcForConditionCode(expectedConditionCdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(4, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(CONDITION.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessSummaryNotificationMessage() {
        String topic = "dummy_notification";
        String key = "{\"payload\":{\"public_health_case_uid\":122,\"notification_uid\":123,\"act_type_cd\":\"SummaryNotification\"}}";

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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

        postProcessingServiceMock.processNrtMessage(topic, key1, msg1);
        assertTrue(postProcessingServiceMock.pbCache.containsKey(expectedRdbTableName));
        assertTrue(postProcessingServiceMock.pbCache.get(expectedRdbTableName).contains(expectedPublicHealthCaseId));

        postProcessingServiceMock.processNrtMessage(topic, key2, msg2);

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

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
    void testPostStateDefinedFieldMetaData() {
        String topic = "dummy_state_defined_field_metadata";
        String key = "{\"payload\":{\"ldf_uid\":123}}";

        postProcessingServiceMock.processNrtMessage(topic, key, key);
        assertEquals(123L, postProcessingServiceMock.idCache.get(topic).element());
        assertTrue(postProcessingServiceMock.idCache.containsKey(topic));

        postProcessingServiceMock.processCachedIds();

        String expectedLdfIdsString = "123";
        verify(postProcRepositoryMock).executeStoredProcForLdfIds(expectedLdfIdsString);
        verify(postProcRepositoryMock).executeStoredProcForLdfDimensionalData(expectedLdfIdsString);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(7, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(STATE_DEFINED_FIELD_METADATA.getStoredProcedure()));
        assertTrue(logs.get(3).getMessage().contains(PostProcessingService.SP_EXECUTION_COMPLETED));
    }

    @Test
    void testPostProcessObservationMorb() {
        String topic = "dummy_observation";
        String key = "{\"payload\":{\"observation_uid\":123}}";
        String msg = "{\"payload\":{\"observation_uid\":123, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"MorbReport\"}}";

        postProcessingServiceMock.processNrtMessage(topic, key, msg);
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

        postProcessingServiceMock.processNrtMessage(topic, key, payload);
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

        postProcessingServiceMock.processNrtMessage(topic, key, payload);
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

        String conditionCodeKey1 = "{\"payload\":{\"condition_cd\":\"123B\"}}";
        String conditionCodeKey2 = "{\"payload\":{\"condition_cd\":\"111\"}}";
        String conditionCodeTopic = "dummy_Condition_code";

        postProcessingServiceMock.processNrtMessage(orgTopic, orgKey1, orgKey1);
        postProcessingServiceMock.processNrtMessage(orgTopic, orgKey2, orgKey2);
        postProcessingServiceMock.processNrtMessage(ntfTopic, ntfKey1, ntfKey1);
        postProcessingServiceMock.processNrtMessage(ntfTopic, ntfKey2, ntfKey2);
        postProcessingServiceMock.processNrtMessage(invTopic, invKey1, invKey1);
        postProcessingServiceMock.processNrtMessage(invTopic, invKey2, invKey2);
        postProcessingServiceMock.processNrtMessage(placeTopic, placeKey1, placeKey1);
        postProcessingServiceMock.processNrtMessage(placeTopic, placeKey2, placeKey2);
        postProcessingServiceMock.processNrtMessage(treatmentTopic, treatmentKey1, treatmentKey1);
        postProcessingServiceMock.processNrtMessage(treatmentTopic, treatmentKey2, treatmentKey2);
        postProcessingServiceMock.processNrtMessage(conditionCodeTopic, conditionCodeKey1, conditionCodeKey1);
        postProcessingServiceMock.processNrtMessage(conditionCodeTopic, conditionCodeKey2, conditionCodeKey2);

        assertTrue(postProcessingServiceMock.idCache.containsKey(orgTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(invTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(ntfTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(placeTopic));
        assertTrue(postProcessingServiceMock.idCache.containsKey(treatmentTopic));
        assertTrue(postProcessingServiceMock.cdCache.containsKey(conditionCodeTopic));

        postProcessingServiceMock.processCachedIds();

        verify(postProcRepositoryMock).executeStoredProcForOrganizationIds("123,124");
        verify(investigationRepositoryMock).executeStoredProcForPublicHealthCaseIds("234,235");
        verify(investigationRepositoryMock).executeStoredProcForNotificationIds("567,568");
        verify(postProcRepositoryMock).executeStoredProcForDPlace("123,124");
        verify(postProcRepositoryMock).executeStoredProcForTreatment("789,790");
        verify(postProcRepositoryMock).executeStoredProcForConditionCode("123B,111");
    }

    @Test
    void testPostProcessContactData() {
        String topic = "dummy_contact";
        String key = "{\"payload\":{\"contact_uid\":123}}";

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
        String stateDefinedFieldMetadataTopic = "dummy_state_defined_field_metadata";
        String cmTopic = "dummy_case_management";
        String obsTopic = "dummy_observation";
        String contactTopic = "dummy_contact";
        String treatmentTopic = "dummy_treatment";
        String vacTopic = "dummy_vaccination";

        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.processNrtMessage(providerTopic, providerKey, providerKey);
        postProcessingServiceMock.processNrtMessage(patientTopic, patientKey, patientKey);
        postProcessingServiceMock.processNrtMessage(userProfileTopic, userProfileKey, userProfileKey);
        postProcessingServiceMock.processNrtMessage(placeTopic, placeKey, placeKey);
        postProcessingServiceMock.processNrtMessage(intTopic, interviewKey, interviewKey);
        postProcessingServiceMock.processNrtMessage(ntfTopic, notificationKey, notificationKey);
        postProcessingServiceMock.processNrtMessage(treatmentTopic, treatmentKey, treatmentKey);
        postProcessingServiceMock.processNrtMessage(orgTopic, orgKey, orgKey);
        postProcessingServiceMock.processNrtMessage(obsTopic, observationKey, observationMsg);
        postProcessingServiceMock.processNrtMessage(stateDefinedFieldMetadataTopic, ldfKey, ldfKey);
        postProcessingServiceMock.processNrtMessage(ldfTopic, ldfKey, ldfKey);
        postProcessingServiceMock.processNrtMessage(pageTopic, pageKey, pageKey);
        postProcessingServiceMock.processNrtMessage(cmTopic, caseManagementKey, caseManagementKey);
        postProcessingServiceMock.processNrtMessage(contactTopic, contactKey, contactKey);
        postProcessingServiceMock.processNrtMessage(vacTopic, vacKey, vacKey);

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
        assertTrue(topicLogList.get(10).contains(intTopic));
        assertTrue(topicLogList.get(11).contains(intTopic));
        assertTrue(topicLogList.get(12).contains(cmTopic));
        assertTrue(topicLogList.get(13).contains(cmTopic));        
        assertTrue(topicLogList.get(14).contains(stateDefinedFieldMetadataTopic));
        assertTrue(topicLogList.get(15).contains(stateDefinedFieldMetadataTopic));
        assertTrue(topicLogList.get(16).contains(ldfTopic));
        assertTrue(topicLogList.get(17).contains(ldfTopic));
        assertTrue(topicLogList.get(18).contains(obsTopic));
        assertTrue(topicLogList.get(19).contains(contactTopic));
        assertTrue(topicLogList.get(20).contains(contactTopic));
        assertTrue(topicLogList.get(21).contains(treatmentTopic));
        assertTrue(topicLogList.get(22).contains(vacTopic));
        assertTrue(topicLogList.get(23).contains(vacTopic));
    }

    @Test
    void testPostProcessEventMetricNoIds() {
        // Test with an event that doesn't trigger the event metric datamart procedure
        String orgKey = "{\"payload\":{\"organization_uid\":123}}";
        String orgTopic = "dummy_organization";
        postProcessingServiceMock.processNrtMessage(orgTopic, orgKey, orgKey);
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

        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey1, investigationKey1);
        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey2, investigationKey2);
        postProcessingServiceMock.processNrtMessage(ntfTopic, notificationKey, notificationKey);
        postProcessingServiceMock.processNrtMessage(obsTopic, observationKey, observationMsg);
        postProcessingServiceMock.processNrtMessage(crTopic, contactKey, contactKey);
        postProcessingServiceMock.processNrtMessage(vaxTopic, vaccinationKey, vaccinationKey);
        postProcessingServiceMock.processCachedIds();

        verify(postProcRepositoryMock).executeStoredProcForEventMetric("126,235", "130", "127", "123", "999");
    }

    @Test
    void testPostProcessUserProfileMessage() {
        String topic = "dummy_auth_user";
        String key = "{\"payload\":{\"auth_user_uid\":123}}";

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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

        postProcessingServiceMock.processNrtMessage(userProfileTopic, userProfileKey1, userProfileKey1);
        postProcessingServiceMock.processNrtMessage(userProfileTopic, userProfileKey2, userProfileKey2);

        assertTrue(postProcessingServiceMock.idCache.containsKey(userProfileTopic));
        postProcessingServiceMock.processCachedIds();
        verify(postProcRepositoryMock).executeStoredProcForUserProfile("123,124");
    }

    @Test
    void testPostProcessNoUserProfileUidException() {
        String userProfileKey = "{\"payload\":{}}";
        String topic = "dummy_user_profile";

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> postProcessingServiceMock.processNrtMessage(topic, userProfileKey, userProfileKey));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @Test
    void testPostProcessPlaceMessage() {
        String topic = "dummy_place";
        String key = "{\"payload\":{\"place_uid\":123}}";

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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

        postProcessingServiceMock.processNrtMessage(placeTopic, placeKey1, placeKey1);
        postProcessingServiceMock.processNrtMessage(placeTopic, placeKey2, placeKey2);

        assertTrue(postProcessingServiceMock.idCache.containsKey(placeTopic));

        postProcessingServiceMock.processCachedIds();
        verify(postProcRepositoryMock).executeStoredProcForDPlace("123,124");
    }

    @Test
    void testPostProcessNoPlaceUidException() {
        String placeKey = "{\"payload\":{}}";
        String topic = "dummy_place";

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> postProcessingServiceMock.processNrtMessage(topic, placeKey, placeKey));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @Test
    void testPostProcessTreatmentMessage() {
        String topic = "dummy_treatment";
        String key = "{\"payload\":{\"treatment_uid\":123}}";

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
                () -> postProcessingServiceMock.processNrtMessage(topic, treatmentKey, treatmentKey));
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

        postProcessingServiceMock.processNrtMessage(topic, key, payload);
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
    void testProcessNrtMessageException() {
        String invalidKey = "invalid_key";
        String invalidTopic = "dummy_topic";

        assertThrows(RuntimeException.class, () -> postProcessingServiceMock.processNrtMessage(invalidTopic,
                invalidKey, invalidKey));
    }

    @Test
    void testPostProcessNoUidException() {
        String orgKey = "{\"payload\":{}}";
        String topic = "dummy_organization";

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> postProcessingServiceMock.processNrtMessage(topic,
                        orgKey, orgKey));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    @ParameterizedTest
    @CsvSource({
            "{\"payload\":{\"unknown_uid\":123}}",
            "{\"payload\":{\"unknown_uid\":\"123\"}}"
    })
    void testPostProcessUnknownTopic(String key) {
        String topic = "dummy_topic";

        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
}