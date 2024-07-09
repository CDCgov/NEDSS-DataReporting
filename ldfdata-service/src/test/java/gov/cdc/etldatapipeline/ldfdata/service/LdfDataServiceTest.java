package gov.cdc.etldatapipeline.ldfdata.service;

import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.ldfdata.repository.LdfDataRepository;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfData;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfDataKey;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.TestInputTopic;
import org.apache.kafka.streams.TopologyTestDriver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.Optional;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class LdfDataServiceTest {

    @Mock
    private LdfDataRepository ldfDataRepository;

    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    public void testProcessMessage() {
        String ldfTopic = "LdfData";
        String ldfTopicOutput = "LdfDataOutput";

        String busObjNm = "PHC";
        long ldfUid = 100000001L;
        long busObjUid = 100000010L;
        String payload = "{\"payload\": {\"after\": {" +
                "\"business_object_nm\": \"" + busObjNm + "\"," +
                "\"ldf_uid\": \"" + ldfUid + "\"," +
                "\"business_object_uid\": \"" + busObjUid + "\"}}}";

        final LdfData ldfData = constructLdfData(busObjNm, ldfUid, busObjUid);
        when(ldfDataRepository.computeLdfData(eq(busObjNm), eq(String.valueOf(ldfUid)), eq(String.valueOf(busObjUid))))
                .thenReturn(Optional.of(ldfData));

        validateData(ldfTopic, ldfTopicOutput, payload, ldfData);

        verify(ldfDataRepository).computeLdfData(eq(busObjNm), eq(String.valueOf(ldfUid)), eq(String.valueOf(busObjUid)));
    }

    private void validateData(String inputTopicName, String outputTopicName,
                              String payload, LdfData ldfData) {
        StreamsBuilder builder = new StreamsBuilder();

        final var investigationService = getInvestigationService(inputTopicName, outputTopicName);
        investigationService.processMessage(builder);

        TopologyTestDriver testDriver = new TopologyTestDriver(builder.build(), new Properties());
        final Serde<String> serdeString = Serdes.String();
        TestInputTopic<String, String> inputTopic = testDriver.createInputTopic(
                inputTopicName, serdeString.serializer(), serdeString.serializer());
        inputTopic.pipeInput("100000001", payload);
        testDriver.close();

        LdfDataKey ldfDataKey = new LdfDataKey();
        ldfDataKey.setLdfUid(ldfData.getLdfUid());
        ldfDataKey.setBusinessObjectUid(ldfData.getBusinessObjectUid());

        String expectedKey = jsonGenerator.generateStringJson(ldfDataKey);
        String expectedValue = jsonGenerator.generateStringJson(ldfData);

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(outputTopicName, topicCaptor.getValue());
        assertEquals(expectedKey, keyCaptor.getValue());
        assertEquals(expectedValue, messageCaptor.getValue());
        assertTrue(keyCaptor.getValue().contains(String.valueOf(ldfDataKey.getLdfUid())));
        assertTrue(keyCaptor.getValue().contains(String.valueOf(ldfDataKey.getBusinessObjectUid())));
    }

    private LdfDataService getInvestigationService(String inputTopicName, String outputTopicName) {
        LdfDataService ldfDataService = new LdfDataService(ldfDataRepository, kafkaTemplate);
        ldfDataService.setLdfDataTopic(inputTopicName);
        ldfDataService.setLdfDataTopicReporting(outputTopicName);
        return ldfDataService;
    }

    private LdfData constructLdfData(String busObjNm, long ldfUid, long busObjUid) {
        LdfData ldfData = new LdfData();

        ldfData.setLdfFieldDataBusinessObjectNm(busObjNm);
        ldfData.setBusinessObjectUid(busObjUid);
        ldfData.setLdfUid(ldfUid);
        return ldfData;
    }
}