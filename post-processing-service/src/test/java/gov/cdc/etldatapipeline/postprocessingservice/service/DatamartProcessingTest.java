package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.InvestigationResult;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.Datamart;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.DatamartKey;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.function.BiFunction;
import java.util.function.Function;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
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
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private ProcessDatamartData datamartProcessor;

    BiFunction<String, List<String>, Boolean> containsWords = (input, words) ->
            words.stream().allMatch(input::contains);

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        datamartProcessor = new ProcessDatamartData(kafkaTemplate);
    }

    @Test
    void testDatamartProcess() {
        String topic = "dummy_investigation";
        List<InvestigationResult> investigationResults = new ArrayList<>();
        InvestigationResult invResult = getInvestigationResult();
        investigationResults.add(invResult);

        Function<InvestigationResult, List<String>> dmDetails =  r -> Arrays.asList(
                String.valueOf(r.getPublicHealthCaseUid()),
                String.valueOf(r.getInvestigationKey()),
                String.valueOf(r.getPatientUid()),
                String.valueOf(r.getPatientKey()),
                r.getConditionCd(),
                r.getDatamart(),
                r.getStoredProcedure());

        datamartProcessor.datamartTopic = topic;
        datamartProcessor.process(investigationResults);

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        DatamartKey dmKey = DatamartKey.builder().publicHealthCaseUid(invResult.getPublicHealthCaseUid()).build();

        assertEquals(topic, topicCaptor.getValue());
        assertTrue(keyCaptor.getValue().contains(String.valueOf(dmKey.getPublicHealthCaseUid())));
        assertTrue(containsWords.apply(messageCaptor.getValue(), dmDetails.apply(invResult)));
    }

    @Test
    void testDatamartProcessException() {
        assertThrows(RuntimeException.class, () -> datamartProcessor.process(null));
    }

    @Test
    void testDataMartDeserialization() throws Exception {
        String dmJson = readFileData(FILE_PREFIX + "Datamart.json");
        JsonNode dmNode = objectMapper.readTree(dmJson);

        Datamart dm = objectMapper.readValue(dmNode.get(PostProcessingService.PAYLOAD).toString(), Datamart.class);
        assertNotNull(dm);
        assertEquals(123L, dm.getPublicHealthCaseUid());
        assertEquals(456L, dm.getPatientUid());
        assertEquals(100L, dm.getInvestigationKey());
        assertEquals(200L, dm.getPatientKey());
        assertEquals("10110", dm.getConditionCd());
        assertEquals("Hepatitis_Datamart", dm.getDatamart());
        assertEquals("sp_hepatitis_datamart_postprocessing", dm.getStoredProcedure());
    }

    private InvestigationResult getInvestigationResult() {
        InvestigationResult investigationResult = new InvestigationResult();
        investigationResult.setPublicHealthCaseUid(123L);
        investigationResult.setInvestigationKey(100L);
        investigationResult.setPatientUid(456L);
        investigationResult.setPatientKey(200L);
        investigationResult.setConditionCd("10110");
        investigationResult.setDatamart("Hepatitis_Datamart");
        investigationResult.setStoredProcedure("sp_hepatitis_datamart_postprocessing");
        return investigationResult;

    }
}
