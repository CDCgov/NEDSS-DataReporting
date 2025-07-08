package gov.cdc.etldatapipeline.postprocessingservice.service;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.etldatapipeline.postprocessingservice.repository.InvestigationRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.PostProcRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import org.awaitility.Awaitility;
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
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;
import java.util.stream.Stream;

import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class PostProcessingServiceDmTest {
    @InjectMocks
    @Spy

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
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        datamartProcessor = new ProcessDatamartData(kafkaTemplate);
        postProcessingServiceMock = spy(new PostProcessingService(postProcRepositoryMock, investigationRepositoryMock,
                datamartProcessor));

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

    @Test
    void testProduceDatamartTopic() {
        String dmTopic = "dummy_datamart";

        String topicInv = "dummy_investigation";
        String keyInv = "{\"payload\":{\"public_health_case_uid\":123}}";

        String topicNtf = "dummy_notification";
        String keyNtf = "{\"payload\":{\"notification_uid\":124}}";

        datamartProcessor.datamartTopic = dmTopic;
        postProcessingServiceMock.processNrtMessage(topicInv, keyInv, keyInv);
        postProcessingServiceMock.processNrtMessage(topicNtf, keyNtf, keyNtf);

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
        postProcessingServiceMock.processNrtMessage(topic, key, key);
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
        postProcessingServiceMock.processNrtMessage(topic, key, key);
        postProcessingServiceMock.processCachedIds();

        verify(kafkaTemplate, never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void testPostProcessTBDatamart() {
        String topic = "tb_datamart";
        String msg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10160\"," +
                "\"datamart\":\"tb_datamart\",\"stored_procedure\":\"\"}}";

        postProcessingServiceMock.processDmMessage(topic, msg);
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

        postProcessingServiceMock.processDmMessage(topic, msg);
        postProcessingServiceMock.processDatamartIds();

        String id = "123";
        verify(investigationRepositoryMock).executeStoredProcForVarDatamart(id);

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(3, logs.size());
        assertTrue(logs.get(2).getFormattedMessage().contains(VAR_DATAMART.getStoredProcedure()));
    }

    @ParameterizedTest
    @MethodSource("datamartTestData")
    void testProcessDmMessage(DatamartTestCase testCase) {
        String topic = "dummy_datamart";
        postProcessingServiceMock.processDmMessage(topic, testCase.msg);
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

        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey1, investigationKey1);
        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey2, investigationKey2);
        postProcessingServiceMock.processNrtMessage(patTopic, patientKey, patientKey);
        postProcessingServiceMock.processNrtMessage(provTopic, providerKey, providerKey);
        postProcessingServiceMock.processNrtMessage(orgTopic, organizationKey, organizationKey);

        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock).executeStoredProcForHep100("126,235", "127", "130", "123");
    }

    @Test
    void testPostProcessHep100NoIds() {
        // Test with an event that doesn't trigger the Hep100 datamart procedure
        String contactKey = "{\"payload\":{\"contact_uid\":123}}";
        String crTopic = "dummy_contact";
        postProcessingServiceMock.processNrtMessage(crTopic, contactKey, contactKey);
        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock, never()).executeStoredProcForHep100(any(),any(),any(),any());
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals("No updates to HEP100 Datamart", logs.get(6).getFormattedMessage());
    }

    @Test
    void testPostProcessInvSummary() {

        String investigationKey = "{\"payload\":{\"public_health_case_uid\":126}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":127}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";

        String invTopic = "dummy_investigation";
        String notTopic = "dummy_notification";
        String obsTopic = "dummy_observation";

        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.processNrtMessage(notTopic, notificationKey, notificationKey);
        postProcessingServiceMock.processNrtMessage(obsTopic, observationKey, observationKey);

        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock).executeStoredProcForInvSummaryDatamart("126", "127", "130");
    }

    @Test
    void testPostProcessInvSummaryNoIds() {

        String contactKey = "{\"payload\":{\"contact_uid\":123}}";
        String crTopic = "dummy_contact";

        postProcessingServiceMock.processNrtMessage(crTopic, contactKey, contactKey);
        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock, never()).executeStoredProcForInvSummaryDatamart(any(),any(),any());
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals("No updates to INV_SUMMARY Datamart", logs.get(7).getFormattedMessage());
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

        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey1, investigationKey1);
        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey2, investigationKey2);
        postProcessingServiceMock.processNrtMessage(patTopic, patientKey, patientKey);
        postProcessingServiceMock.processNrtMessage(provTopic, providerKey, providerKey);
        postProcessingServiceMock.processNrtMessage(orgTopic, organizationKey, organizationKey);
        postProcessingServiceMock.processNrtMessage(obsTopic, observationKey, observationMsg);

        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock).executeStoredProcForMorbidityReportDatamart("130", "127", "130", "123", "126,235");
    }

    @Test
    void testPostProcessMorbidityReportDatamartNoIds() {
        // Test with an event that doesn't trigger the morbidity report datamart procedure
        String contactKey = "{\"payload\":{\"contact_uid\":123}}";
        String crTopic = "dummy_contact";
        postProcessingServiceMock.processNrtMessage(crTopic, contactKey, contactKey);
        postProcessingServiceMock.processCachedIds();
        postProcessingServiceMock.processDatamartIds();

        verify(postProcRepositoryMock, never()).executeStoredProcForMorbidityReportDatamart(any(),any(),any(),any(),any());
        List<ILoggingEvent> logs = listAppender.list;
        assertEquals("No updates to MORBIDITY_REPORT_DATAMART", logs.getLast().getFormattedMessage());
    }

    @Test
    void testPostProcessDynMarts() {

        String investigationKey = "{\"payload\":{\"public_health_case_uid\":126}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":127}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";

        String invTopic = "dummy_investigation";
        String notTopic = "dummy_notification";
        String obsTopic = "dummy_observation";

        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.processNrtMessage(notTopic, notificationKey, notificationKey);
        postProcessingServiceMock.processNrtMessage(obsTopic, observationKey, observationKey);

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
    void testProcessDmMessageException() {
        String topic = "dummy_datamart";
        String invalidMsg = "invalid_msg";

        assertThrows(RuntimeException.class, () -> postProcessingServiceMock.processDmMessage(topic, invalidMsg));
    }

    @ParameterizedTest
    @CsvSource({
            "'{\"payload\":null}'",
            "'{\"payload\":{}}'",
            "'{\"payload\":{\"public_health_case_uid\":null,\"patient_uid\":456,\"datamart\":\"dummy\"}}'",
            "'{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":null,\"datamart\":\"dummy\"}}'",
            "'{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"datamart\":null}}'",

    })
    void testProcessDmMessageIncompleteData(String msg) {
        String topic = "dummy_datamart";

        postProcessingServiceMock.processDmMessage(topic, msg);
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

        postProcessingServiceMock.processDmMessage(topic, msg);
        postProcessingServiceMock.processDatamartIds();

        List<ILoggingEvent> logs = listAppender.list;
        assertEquals(2, logs.size());
        assertTrue(logs.getLast().getMessage().contains("No associated datamart processing logic found"));
    }

    protected List<DatamartData> getDatamartData(Long phcUid, Long patientUid, String... dmVar) {
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
    }
}
