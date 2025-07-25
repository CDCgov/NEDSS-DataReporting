package gov.cdc.etldatapipeline.postprocessingservice.service;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.etldatapipeline.postprocessingservice.repository.InvestigationRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.PostProcRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.BackfillData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
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

import static gov.cdc.etldatapipeline.postprocessingservice.service.PostProcessingService.STATUS_READY;
import static gov.cdc.etldatapipeline.postprocessingservice.service.PostProcessingService.STATUS_SUSPENDED;
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

    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
    private AutoCloseable closeable;

    private final String errorMsg = "Test Error";

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        ProcessDatamartData datamartProcessor = new ProcessDatamartData(kafkaTemplate);
        postProcessingServiceMock = spy(new PostProcessingService(postProcRepositoryMock, investigationRepositoryMock,
                datamartProcessor));
        postProcessingServiceMock.setMaxRetries(2);

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
    void testProcessRetryCache() {
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
        assertFalse(postProcessingServiceMock.errorMap.isEmpty());

        Long batchId = postProcessingServiceMock.retryCache.entrySet().iterator().next().getKey();
        assertEquals(errorMsg, postProcessingServiceMock.errorMap.get(batchId));
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
    void testProcessRetryCacheSuccess() {
        String patTopic = "dummy_patient";
        String patKey = "{\"payload\":{\"patient_uid\":123}}";

        String patientUid = "123";

        when(postProcRepositoryMock.executeStoredProcForPatientIds(patientUid))
                .thenThrow(new RuntimeException(errorMsg))
                .thenReturn(Collections.emptyList());

        postProcessingServiceMock.processNrtMessage(patTopic, patKey, patKey);
        postProcessingServiceMock.processCachedIds();

        assertFalse(postProcessingServiceMock.retryCache.isEmpty());
        assertFalse(postProcessingServiceMock.errorMap.isEmpty());

        Long batchId = postProcessingServiceMock.retryCache.entrySet().iterator().next().getKey();
        assertEquals(errorMsg, postProcessingServiceMock.errorMap.get(batchId));

        postProcessingServiceMock.processRetryCache();
        verify(postProcRepositoryMock, never()).executeStoredProcForBackfill(
                Entity.PATIENT.getEntityName().toUpperCase(), patientUid, batchId, errorMsg, STATUS_READY, 0);

        verify(postProcRepositoryMock, times(2)).executeStoredProcForPatientIds(anyString());
    }

    @Test
    void testProcessRetryCacheDisabled() {
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
    void testProcessBackfillEvent() {
        when(postProcRepositoryMock.executeBackfillEvent(STATUS_READY))
                .thenReturn(getBackfills())
                .thenReturn(Collections.emptyList());

        postProcessingServiceMock.backfillEvent();

        assertFalse(postProcessingServiceMock.retryCache.isEmpty());
        assertFalse(postProcessingServiceMock.errorMap.isEmpty());
        assertEquals(errorMsg, postProcessingServiceMock.errorMap.get(123123L));

        postProcessingServiceMock.processRetryCache();
        verify(postProcRepositoryMock).executeStoredProcForBackfill(
                null, null, 123123L, errorMsg, STATUS_SUSPENDED, 0);

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
        assertEquals(errorMsg, postProcessingServiceMock.errorMap.get(batchId));
    }

    private List<BackfillData> getBackfills() {
        List<BackfillData> backfills = new ArrayList<>();
        BackfillData backfill = new BackfillData();
        backfill.setRecordKey(12L);
        backfill.setBatchId(123123L);
        backfill.setEntity(Entity.PATIENT.getEntityName().toUpperCase());
        backfill.setRecordUidList("100123");
        backfill.setStatusCd(STATUS_READY);
        backfill.setErrDescription(errorMsg);
        backfill.setRetryCount(2);

        backfills.add(backfill);
        return backfills;
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
