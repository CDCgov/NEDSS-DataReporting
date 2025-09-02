package gov.cdc.etldatapipeline.postprocessingservice.service;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.etldatapipeline.postprocessingservice.repository.InvestigationRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.PostProcRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.BackfillData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static gov.cdc.etldatapipeline.postprocessingservice.service.ProcessDatamartData.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class PostProcessingServiceRetryTest {

    @InjectMocks
    @Spy

    private PostProcessingService postProcessingServiceMock;
    @Mock
    private PostProcRepository postProcRepositoryMock;
    @Mock
    private static InvestigationRepository investigationRepositoryMock;

    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    private ProcessDatamartData datamartProcessor;

    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
    private AutoCloseable closeable;

    private final String errorMsg = "Test Error";

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        datamartProcessor = new ProcessDatamartData(kafkaTemplate, postProcRepositoryMock, investigationRepositoryMock);
        postProcessingServiceMock = spy(new PostProcessingService(postProcRepositoryMock, investigationRepositoryMock,
                datamartProcessor, new CustomMetrics(new SimpleMeterRegistry())));
        postProcessingServiceMock.setMaxRetries(2);
        postProcessingServiceMock.initMetrics();
        datamartProcessor.setMaxRetries(2);

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
    void testProcessRetryEntity() {
        String patTopic = "dummy_patient";
        String patKey = "{\"payload\":{\"patient_uid\":123}}";
        String invTopic = "dummy_investigation";
        String invKey = "{\"payload\":{\"public_health_case_uid\":234}}";
        String invMsg = "{\"payload\":{\"public_health_case_uid\":234, \"rdb_table_name_list\":\"D_INV_CLINICAL,D_INV_ADMINISTRATIVE\"}}";
        String obsTopic = "dummy_observation";
        String obsKey = "{\"payload\":{\"observation_uid\":567}}";
        String obsMsg = "{\"payload\":{\"observation_uid\":567, \"obs_domain_cd_st_1\": \"Order\",\"ctrl_cd_display_form\": \"LabReport\"}}";

        String patientUid = "123";

        when(postProcRepositoryMock.executeStoredProcForPatientIds(patientUid)).thenThrow(new RuntimeException(errorMsg));
        postProcessingServiceMock.processNrtMessage(patTopic, patKey, patKey);
        postProcessingServiceMock.processNrtMessage(invTopic, invKey, invMsg);
        postProcessingServiceMock.processNrtMessage(obsTopic, obsKey, obsMsg);
        postProcessingServiceMock.processCachedIds();

        assertFalse(postProcessingServiceMock.retryCache.isEmpty());
        assertFalse(datamartProcessor.errorMap.isEmpty());

        Long batchId = postProcessingServiceMock.retryCache.entrySet().iterator().next().getKey();
        assertEquals(errorMsg, datamartProcessor.errorMap.get(batchId));
        assertEquals(6, postProcessingServiceMock.retryCache.get(batchId).size());

        postProcessingServiceMock.processRetryCache();
        verify(postProcRepositoryMock, never()).executeStoredProcForBackfill(
                Entity.PATIENT.getEntityName().toUpperCase(), patientUid, batchId, errorMsg, STATUS_READY, 0);

        postProcessingServiceMock.processRetryCache();
        verify(postProcRepositoryMock).executeStoredProcForBackfill(
                Entity.PATIENT.getEntityName().toUpperCase(), patientUid, batchId, errorMsg, STATUS_READY, 0);

        verify(postProcRepositoryMock, times(3)).executeStoredProcForPatientIds(anyString());
    }

    @Test
    void testProcessRetryEntitySuccess() {
        String patTopic = "dummy_patient";
        String patKey = "{\"payload\":{\"patient_uid\":123}}";

        String patientUid = "123";

        when(postProcRepositoryMock.executeStoredProcForPatientIds(patientUid))
                .thenThrow(new RuntimeException(errorMsg))
                .thenReturn(Collections.emptyList());

        postProcessingServiceMock.processNrtMessage(patTopic, patKey, patKey);
        postProcessingServiceMock.processCachedIds();

        assertFalse(postProcessingServiceMock.retryCache.isEmpty());
        assertFalse(datamartProcessor.errorMap.isEmpty());

        Long batchId = postProcessingServiceMock.retryCache.entrySet().iterator().next().getKey();
        assertEquals(errorMsg, datamartProcessor.errorMap.get(batchId));

        postProcessingServiceMock.processRetryCache();
        verify(postProcRepositoryMock, never()).executeStoredProcForBackfill(
                Entity.PATIENT.getEntityName().toUpperCase(), patientUid, batchId, errorMsg, STATUS_READY, 0);

        verify(postProcRepositoryMock, times(2)).executeStoredProcForPatientIds(anyString());
    }

    @Test
    void testProcessRetryDisabled() {
        String patTopic = "dummy_patient";
        String patKey = "{\"payload\":{\"patient_uid\":123}}";

        postProcessingServiceMock.setMaxRetries(-1);
        when(postProcRepositoryMock.executeStoredProcForPatientIds("123")).thenThrow(new RuntimeException(errorMsg));

        postProcessingServiceMock.processNrtMessage(patTopic, patKey, patKey);
        postProcessingServiceMock.processCachedIds();

        assertTrue(postProcessingServiceMock.retryCache.isEmpty());

        postProcessingServiceMock.backfillEvent();
        verify(postProcRepositoryMock, never()).executeBackfillEvent(anyString());
    }

    @Test
    void testProcessRetryDatamart() {
        String investigationKey = "{\"payload\":{\"public_health_case_uid\":123}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":124}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";

        String invTopic = "dummy_investigation";
        String notTopic = "dummy_notification";
        String obsTopic = "dummy_observation";

        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.processNrtMessage(notTopic, notificationKey, notificationKey);
        postProcessingServiceMock.processNrtMessage(obsTopic, observationKey, observationKey);
        postProcessingServiceMock.processCachedIds();

        String topic = "dummy_datamart";
        String hepDmMsg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10110\"," +
                "\"datamart\":\"Hepatitis_Datamart\",\"stored_procedure\":\"sp_hepatitis_datamart_postprocessing\"}}";
        String genDmMsg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                "\"datamart\":\"Generic_Case\",\"stored_procedure\":\"sp_generic_case_datamart_postprocessing\"}}";

        String phcUid = "123";
        when(investigationRepositoryMock.executeStoredProcForHepDatamart(phcUid)).thenThrow(new RuntimeException(errorMsg));

        postProcessingServiceMock.processDmMessage(topic, hepDmMsg);
        postProcessingServiceMock.processDmMessage(topic, genDmMsg);
        postProcessingServiceMock.processDatamartIds();

        assertFalse(datamartProcessor.retryCache.isEmpty());
        assertFalse(datamartProcessor.errorMap.isEmpty());

        Long batchId = datamartProcessor.retryCache.entrySet().iterator().next().getKey();
        assertEquals(errorMsg, datamartProcessor.errorMap.get(batchId));
        assertEquals(3, datamartProcessor.retryCache.get(batchId).size());
        assertTrue(datamartProcessor.retryCache.get(batchId).containsKey(MULTI_ID_DATAMART));

        String dmEntity = "DM^" + Entity.HEPATITIS_DATAMART.getEntityName();
        datamartProcessor.processRetryCache();
        verify(postProcRepositoryMock, never()).executeStoredProcForBackfill(
                eq(dmEntity), contains(phcUid), eq(batchId), eq(errorMsg), eq(STATUS_READY), eq(0));

        datamartProcessor.processRetryCache();
        verify(postProcRepositoryMock).executeStoredProcForBackfill(
                eq(dmEntity), contains(phcUid), eq(batchId), eq(errorMsg), eq(STATUS_READY), eq(0));

        verify(investigationRepositoryMock, times(3)).executeStoredProcForHepDatamart(anyString());
    }

    @Test
    void testProcessRetryMultiId() {
        String investigationKey = "{\"payload\":{\"public_health_case_uid\":123}}";
        String notificationKey = "{\"payload\":{\"notification_uid\":124}}";
        String observationKey = "{\"payload\":{\"observation_uid\":130}}";

        String invTopic = "dummy_investigation";
        String notTopic = "dummy_notification";
        String obsTopic = "dummy_observation";

        postProcessingServiceMock.processNrtMessage(invTopic, investigationKey, investigationKey);
        postProcessingServiceMock.processNrtMessage(notTopic, notificationKey, notificationKey);
        postProcessingServiceMock.processNrtMessage(obsTopic, observationKey, observationKey);
        postProcessingServiceMock.processCachedIds();

        when(postProcRepositoryMock.executeStoredProcForInvSummaryDatamart("123", "124", "130")).thenThrow(new RuntimeException(errorMsg));
        postProcessingServiceMock.processDatamartIds();

        assertFalse(datamartProcessor.retryCache.isEmpty());
        Long batchId = datamartProcessor.retryCache.entrySet().iterator().next().getKey();
        assertEquals(errorMsg, datamartProcessor.errorMap.get(batchId));
        assertTrue(datamartProcessor.retryCache.get(batchId).containsKey(MULTI_ID_DATAMART));
    }

    @Test
    void testProcessRetryDatamartSuccess() {
        String topic = "dummy_datamart";
        String hepDmMsg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"10110\"," +
                "\"datamart\":\"Hepatitis_Datamart\",\"stored_procedure\":\"sp_hepatitis_datamart_postprocessing\"}}";
        String genDmMsg = "{\"payload\":{\"public_health_case_uid\":123,\"patient_uid\":456,\"condition_cd\":\"12020\"," +
                "\"datamart\":\"Generic_Case\",\"stored_procedure\":\"sp_generic_case_datamart_postprocessing\"}}";

        String phcUid = "123";
        when(investigationRepositoryMock.executeStoredProcForHepDatamart(phcUid))
                .thenThrow(new RuntimeException(errorMsg))
                .thenReturn(Collections.emptyList());

        postProcessingServiceMock.processDmMessage(topic, hepDmMsg);
        postProcessingServiceMock.processDmMessage(topic, genDmMsg);
        postProcessingServiceMock.processDatamartIds();

        assertFalse(datamartProcessor.retryCache.isEmpty());
        assertFalse(datamartProcessor.errorMap.isEmpty());

        Long batchId = datamartProcessor.retryCache.entrySet().iterator().next().getKey();
        assertEquals(errorMsg, datamartProcessor.errorMap.get(batchId));

        String dmEntity = "DM^" + Entity.HEPATITIS_DATAMART.getEntityName();
        datamartProcessor.processRetryCache();

        assertTrue(datamartProcessor.retryAttempts.isEmpty());
        assertTrue(datamartProcessor.errorMap.isEmpty());
        assertTrue(datamartProcessor.retryCache.isEmpty());
        verify(postProcRepositoryMock, never()).executeStoredProcForBackfill(
                eq(dmEntity), contains(phcUid), eq(batchId), eq(errorMsg), eq(STATUS_READY), eq(0));

        verify(investigationRepositoryMock, times(2)).executeStoredProcForHepDatamart(anyString());
        verify(investigationRepositoryMock).executeStoredProcForGenericCaseDatamart(anyString());
    }

    @Test
    void testProcessBackfillEvent() {
        when(postProcRepositoryMock.executeBackfillEvent(STATUS_READY))
                .thenReturn(getBackfills())
                .thenReturn(Collections.emptyList());

        postProcessingServiceMock.backfillEvent();

        assertFalse(postProcessingServiceMock.retryCache.isEmpty());
        assertFalse(datamartProcessor.retryCache.isEmpty());
        assertFalse(datamartProcessor.errorMap.isEmpty());
        assertEquals(errorMsg, datamartProcessor.errorMap.get(123123L));
        assertEquals(errorMsg, datamartProcessor.errorMap.get(123456L));

        postProcessingServiceMock.processRetryCache();
        verify(postProcRepositoryMock).executeStoredProcForBackfill(
                null, null, 123123L, errorMsg, STATUS_SUSPENDED, 0);

        datamartProcessor.processRetryCache();
        verify(postProcRepositoryMock).executeStoredProcForBackfill(
                null, null, 123456L, errorMsg, STATUS_SUSPENDED, 0);

        postProcessingServiceMock.backfillEvent();
        assertTrue(postProcessingServiceMock.retryCache.isEmpty());
    }

    @Test
    void testProcessIdCacheError() {
        String patTopic = "dummy_provider";
        String patKey = "{\"payload\":{\"provider_uid\":123}}";

        when(postProcRepositoryMock.executeStoredProcForProviderIds("123"))
                .thenReturn(getDatamartErr());

        postProcessingServiceMock.processNrtMessage(patTopic, patKey, patKey);
        postProcessingServiceMock.processCachedIds();

        assertFalse(postProcessingServiceMock.retryCache.isEmpty());
        Long batchId = postProcessingServiceMock.retryCache.entrySet().iterator().next().getKey();
        assertEquals(errorMsg, datamartProcessor.errorMap.get(batchId));
    }

    private List<BackfillData> getBackfills() {
        BackfillData backfill = new BackfillData();
        backfill.setRecordKey(12L);
        backfill.setBatchId(123123L);
        backfill.setEntity(Entity.PATIENT.getEntityName().toUpperCase());
        backfill.setRecordUidList("100123");
        backfill.setStatusCd(STATUS_READY);
        backfill.setErrDescription(errorMsg);
        backfill.setRetryCount(2);

        BackfillData backfillDm = new BackfillData();
        backfillDm.setRecordKey(13L);
        backfillDm.setBatchId(123456L);
        backfillDm.setEntity("DM^"+Entity.GENERIC_CASE.getEntityName());
        backfillDm.setRecordUidList("patient:100123 investigation:123124");
        backfillDm.setStatusCd(STATUS_READY);
        backfillDm.setErrDescription(errorMsg);
        backfillDm.setRetryCount(2);

        return new ArrayList<>(List.of(backfill, backfillDm));
    }

    protected List<DatamartData> getDatamartErr() {
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = new DatamartData();
        datamartData.setDatamart("Error");
        datamartData.setStoredProcedure(errorMsg);
        datamartDataLst.add(datamartData);
        return datamartDataLst;
    }
}
