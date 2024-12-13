package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.InvestigationResult;
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
import static gov.cdc.etldatapipeline.postprocessingservice.service.PostProcessingService.Entity.HEPATITIS_DATAMART;
import static gov.cdc.etldatapipeline.postprocessingservice.service.PostProcessingService.Entity.STD_HIV_DATAMART;
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
        List<InvestigationResult> investigationResults = new ArrayList<>();
        InvestigationResult invResult = getInvestigationResult(123L, HEPATITIS_DATAMART.getEntityName(), HEPATITIS_DATAMART.getStoredProcedure());
        investigationResults.add(invResult);

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(investigationResults);

        Datamart datamart = getDatamart("HepDatamart.json");
        DatamartKey datamartKey = new DatamartKey();
        datamartKey.setPublicHealthCaseUid(invResult.getPublicHealthCaseUid());

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
        List<InvestigationResult> investigationResults = new ArrayList<>();
        InvestigationResult invResult = getInvestigationResult(123L, STD_HIV_DATAMART.getEntityName(), STD_HIV_DATAMART.getStoredProcedure());
        investigationResults.add(invResult);

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(investigationResults);

        Datamart datamart = getDatamart("StdDatamart.json");
        DatamartKey datamartKey = new DatamartKey();
        datamartKey.setPublicHealthCaseUid(invResult.getPublicHealthCaseUid());

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
        List<InvestigationResult> nullPhcResults = Collections.singletonList(getInvestigationResult(null, HEPATITIS_DATAMART.getEntityName(), HEPATITIS_DATAMART.getStoredProcedure()));
        assertThrows(RuntimeException.class, () -> datamartProcessor.process(nullPhcResults));
    }

    private InvestigationResult getInvestigationResult(Long phcUid, String entityName, String storedProcedure) {
        InvestigationResult investigationResult = new InvestigationResult();
        investigationResult.setPublicHealthCaseUid(phcUid);
        investigationResult.setInvestigationKey(100L);
        investigationResult.setPatientUid(456L);
        investigationResult.setPatientKey(200L);
        investigationResult.setConditionCd("10110");
        investigationResult.setDatamart(entityName);
        investigationResult.setStoredProcedure(storedProcedure);
        return investigationResult;
    }



    private Datamart getDatamart(String jsonFile) throws Exception {
        String dmJson = readFileData(FILE_PREFIX + jsonFile);
        JsonNode dmNode = objectMapper.readTree(dmJson);
        return objectMapper.readValue(dmNode.get(PAYLOAD).toString(), Datamart.class);
    }

  }
