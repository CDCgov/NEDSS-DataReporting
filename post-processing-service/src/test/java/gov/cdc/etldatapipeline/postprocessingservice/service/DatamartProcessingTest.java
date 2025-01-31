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
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.List;
import java.util.stream.Stream;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.*;
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

    @ParameterizedTest
    @MethodSource("provideTestData")
    void testDatamartProcess(String conditionCd, String dmEntity, String dmSp, String dmJson) throws Exception {
        String topic = "dummy_investigation";
        DatamartData datamartData = getDatamartData(conditionCd, dmEntity, dmSp);

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(List.of(datamartData));

        Datamart datamart = getDatamart(dmJson);
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

    static Stream<Arguments> provideTestData() {
        return Stream.of(
                Arguments.of("10110", HEPATITIS_DATAMART.getEntityName(), HEPATITIS_DATAMART.getStoredProcedure(), "HepDatamart.json"),
                Arguments.of("10110", STD_HIV_DATAMART.getEntityName(), STD_HIV_DATAMART.getStoredProcedure(), "StdDatamart.json"),
                Arguments.of("12020", GENERIC_CASE.getEntityName(), GENERIC_CASE.getStoredProcedure(), "GenericCaseDatamart.json"),
                Arguments.of("10370", CRS_CASE.getEntityName(), CRS_CASE.getStoredProcedure(), "CRSCaseDatamart.json"),
                Arguments.of("10200", RUBELLA_CASE.getEntityName(), RUBELLA_CASE.getStoredProcedure(), "RubellaCaseDatamart.json"),
                Arguments.of("10140", MEASLES_CASE.getEntityName(), MEASLES_CASE.getStoredProcedure(), "MeaslesCaseDatamart.json"),
                Arguments.of(null, CASE_LAB_DATAMART.getEntityName(), CASE_LAB_DATAMART.getStoredProcedure(), "CaseLabDatamart.json")
        );
    }

    @Test
    void testExcludeCaseLabDatamart() throws Exception {
        String topic = "dummy_investigation";
        DatamartData datamartDataHep = getDatamartData("10110", HEPATITIS_DATAMART.getEntityName(), HEPATITIS_DATAMART.getStoredProcedure());
        DatamartData datamartDataCaseLab = getDatamartData(null, CASE_LAB_DATAMART.getEntityName(), CASE_LAB_DATAMART.getStoredProcedure());

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(List.of(datamartDataHep, datamartDataCaseLab));

        Datamart datamart = getDatamart("HepDatamart.json");
        DatamartKey datamartKey = new DatamartKey();
        datamartKey.setPublicHealthCaseUid(datamartDataHep.getPublicHealthCaseUid());

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
        DatamartData datamartData = getDatamartData("10110", HEPATITIS_DATAMART.getEntityName(), HEPATITIS_DATAMART.getStoredProcedure());
        datamartData.setPublicHealthCaseUid(null);
        List<DatamartData> nullPhcResults = List.of(datamartData);
        assertThrows(RuntimeException.class, () -> datamartProcessor.process(nullPhcResults));
    }

    private DatamartData getDatamartData(String conditionCd, String entityName, String storedProcedure) {
        DatamartData datamartData = new DatamartData();
        datamartData.setPublicHealthCaseUid(123L);
        datamartData.setPatientUid(456L);
        datamartData.setConditionCd(conditionCd);
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
