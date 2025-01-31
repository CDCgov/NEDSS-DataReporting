package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.Datamart;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.DatamartKey;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static gov.cdc.etldatapipeline.postprocessingservice.service.PostProcessingService.Entity.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.verify;

class DatamartProcessingTest {
    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private static final String FILE_PREFIX = "rawDataFiles/";
    private static final String PAYLOAD = "payload";
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private ProcessDatamartData datamartProcessor;
    private AutoCloseable closeable;

    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        datamartProcessor = new ProcessDatamartData(kafkaTemplate);
    }

    @AfterEach
    void tearDown() throws Exception {
        closeable.close();
    }

    @Test
    void testHepDatamartProcess() throws Exception {
        String topic = "dummy_investigation";
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = getDatamartData(123L, HEPATITIS_DATAMART.getEntityName(), HEPATITIS_DATAMART.getStoredProcedure());
        datamartDataLst.add(datamartData);

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(datamartDataLst);

        Datamart datamart = getDatamart("HepDatamart.json");
        DatamartKey datamartKey = new DatamartKey();
        datamartKey.setPublicHealthCaseUid(datamartData.getPublicHealthCaseUid());

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        String actualMessage = messageCaptor.getValue();
        String actualKey = keyCaptor.getValue();

        var actualReporting = objectMapper.readValue(
                objectMapper.readTree(actualMessage).path(PAYLOAD).toString(), Datamart.class);
        var actualDatamartKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path(PAYLOAD).toString(), DatamartKey.class);

        assertEquals(topic, topicCaptor.getValue());
        assertEquals(datamartKey, actualDatamartKey);
        assertEquals(datamart, actualReporting);
    }

    @Test
    void testStdDatamartProcess() throws Exception {
        String topic = "dummy_investigation";
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = getDatamartData(123L, STD_HIV_DATAMART.getEntityName(), STD_HIV_DATAMART.getStoredProcedure());
        datamartDataLst.add(datamartData);

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(datamartDataLst);

        Datamart datamart = getDatamart("StdDatamart.json");
        DatamartKey datamartKey = new DatamartKey();
        datamartKey.setPublicHealthCaseUid(datamartData.getPublicHealthCaseUid());

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        String actualMessage = messageCaptor.getValue();
        String actualKey = keyCaptor.getValue();

        var actualReporting = objectMapper.readValue(
                objectMapper.readTree(actualMessage).path(PAYLOAD).toString(), Datamart.class);
        var actualDatamartKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path(PAYLOAD).toString(), DatamartKey.class);

        assertEquals(topic, topicCaptor.getValue());
        assertEquals(datamartKey, actualDatamartKey);
        assertEquals(datamart, actualReporting);
    }

    @Test
    void testGenericCaseDatamartProcess() throws Exception {
        String topic = "dummy_investigation";
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = getDatamartData(10009757L, GENERIC_CASE.getEntityName(), GENERIC_CASE.getStoredProcedure());
        datamartData.setConditionCd("12020");
        datamartDataLst.add(datamartData);

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(datamartDataLst);

        Datamart datamart = getDatamart("GenericCaseDatamart.json");
        DatamartKey datamartKey = new DatamartKey();
        datamartKey.setPublicHealthCaseUid(datamartData.getPublicHealthCaseUid());

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        String actualMessage = messageCaptor.getValue();
        String actualKey = keyCaptor.getValue();

        var actualReporting = objectMapper.readValue(
                objectMapper.readTree(actualMessage).path(PAYLOAD).toString(), Datamart.class);
        var actualDatamartKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path(PAYLOAD).toString(), DatamartKey.class);

        assertEquals(topic, topicCaptor.getValue());
        assertEquals(datamartKey, actualDatamartKey);
        assertEquals(datamart, actualReporting);
    }

    @Test
    void testCRSCaseDatamartProcess() throws Exception {
        String topic = "dummy_investigation";
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = getDatamartData(101L, CRS_CASE.getEntityName(), CRS_CASE.getStoredProcedure());
        datamartData.setConditionCd("10370");
        datamartDataLst.add(datamartData);

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(datamartDataLst);

        Datamart datamart = getDatamart("CRSCaseDatamart.json");
        DatamartKey datamartKey = new DatamartKey();
        datamartKey.setPublicHealthCaseUid(datamartData.getPublicHealthCaseUid());

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        String actualMessage = messageCaptor.getValue();
        String actualKey = keyCaptor.getValue();

        var actualReporting = objectMapper.readValue(
                objectMapper.readTree(actualMessage).path(PAYLOAD).toString(), Datamart.class);
        var actualDatamartKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path(PAYLOAD).toString(), DatamartKey.class);

        assertEquals(topic, topicCaptor.getValue());
        assertEquals(datamartKey, actualDatamartKey);
        assertEquals(datamart, actualReporting);
    }

    @Test
    void testRubellaCaseDatamartProcess() throws Exception {
        String topic = "dummy_investigation";
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = getDatamartData(101L, RUBELLA_CASE.getEntityName(), RUBELLA_CASE.getStoredProcedure());
        datamartData.setConditionCd("10200");
        datamartDataLst.add(datamartData);

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(datamartDataLst);

        Datamart datamart = getDatamart("RubellaCaseDatamart.json");
        DatamartKey datamartKey = new DatamartKey();
        datamartKey.setPublicHealthCaseUid(datamartData.getPublicHealthCaseUid());

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        String actualMessage = messageCaptor.getValue();
        String actualKey = keyCaptor.getValue();

        var actualReporting = objectMapper.readValue(
                objectMapper.readTree(actualMessage).path(PAYLOAD).toString(), Datamart.class);
        var actualDatamartKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path(PAYLOAD).toString(), DatamartKey.class);

        assertEquals(topic, topicCaptor.getValue());
        assertEquals(datamartKey, actualDatamartKey);
        assertEquals(datamart, actualReporting);
    }

    @Test
    void testMeaslesCaseDatamartProcess() throws Exception {
        String topic = "dummy_investigation";
        List<DatamartData> datamartDataLst = new ArrayList<>();
        DatamartData datamartData = getDatamartData(101L, MEASLES_CASE.getEntityName(), MEASLES_CASE.getStoredProcedure());
        datamartData.setConditionCd("10140");
        datamartDataLst.add(datamartData);

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(datamartDataLst);

        Datamart datamart = getDatamart("MeaslesCaseDatamart.json");
        DatamartKey datamartKey = new DatamartKey();
        datamartKey.setPublicHealthCaseUid(datamartData.getPublicHealthCaseUid());

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        String actualMessage = messageCaptor.getValue();
        String actualKey = keyCaptor.getValue();

        var actualReporting = objectMapper.readValue(
                objectMapper.readTree(actualMessage).path(PAYLOAD).toString(), Datamart.class);
        var actualDatamartKey = objectMapper.readValue(
                objectMapper.readTree(actualKey).path(PAYLOAD).toString(), DatamartKey.class);

        assertEquals(topic, topicCaptor.getValue());
        assertEquals(datamartKey, actualDatamartKey);
        assertEquals(datamart, actualReporting);
    }

    @Test
    void testDatamartProcessNoExceptionWhenDataIsNull() {
        assertDoesNotThrow(() -> datamartProcessor.process(null));
    }

    @Test
    void testDatamartProcessException() {
        List<DatamartData> nullPhcResults = Collections.singletonList(getDatamartData(null, HEPATITIS_DATAMART.getEntityName(), HEPATITIS_DATAMART.getStoredProcedure()));
        assertThrows(RuntimeException.class, () -> datamartProcessor.process(nullPhcResults));
    }

    private DatamartData getDatamartData(Long phcUid, String entityName, String storedProcedure) {
        DatamartData datamartData = new DatamartData();
        datamartData.setPublicHealthCaseUid(phcUid);
        datamartData.setInvestigationKey(100L);
        datamartData.setPatientUid(456L);
        datamartData.setPatientKey(200L);
        datamartData.setConditionCd("10110");
        datamartData.setDatamart(entityName);
        datamartData.setStoredProcedure(storedProcedure);
        return datamartData;
    }

    private Datamart getDatamart(String jsonFile) throws Exception {
        String dmJson = readFileData(FILE_PREFIX + jsonFile);
        JsonNode dmNode = objectMapper.readTree(dmJson);
        return objectMapper.readValue(dmNode.get(PAYLOAD).toString(), Datamart.class);
    }

  }
