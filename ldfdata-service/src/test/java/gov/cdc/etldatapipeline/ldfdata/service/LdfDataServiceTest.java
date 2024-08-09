package gov.cdc.etldatapipeline.ldfdata.service;

import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.ldfdata.repository.LdfDataRepository;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfData;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfDataKey;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
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
    void testProcessMessage() {
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
        when(ldfDataRepository.computeLdfData(busObjNm, String.valueOf(ldfUid), String.valueOf(busObjUid)))
                .thenReturn(Optional.of(ldfData));

        validateData(ldfTopic, ldfTopicOutput, payload, ldfData);

        verify(ldfDataRepository).computeLdfData(busObjNm, String.valueOf(ldfUid), String.valueOf(busObjUid));
    }

    @Test
    void testProcessMessageException() {
        String ldfTopic = "LdfData";
        String ldfTopicOutput = "LdfDataOutput";
        String invalidPayload = "{\"payload\": {\"after\": }}";

        final var ldfDataService = getInvestigationService(ldfTopic, ldfTopicOutput);
        assertThrows(RuntimeException.class, () -> ldfDataService.processMessage(invalidPayload, ldfTopic));
    }

    @Test
    void testProcessMessageNoDataException() {
        String ldfTopic = "LdfData";
        String ldfTopicOutput = "LdfDataOutput";

        String busObjNm = "PHC";
        long ldfUid = 100000001L;
        long busObjUid = 100000010L;
        String payload = "{\"payload\": {\"after\": {" +
                "\"business_object_nm\": \"" + busObjNm + "\"," +
                "\"ldf_uid\": \"" + ldfUid + "\"," +
                "\"business_object_uid\": \"" + busObjUid + "\"}}}";

        when(ldfDataRepository.computeLdfData(busObjNm, String.valueOf(ldfUid), String.valueOf(busObjUid)))
                .thenReturn(Optional.empty());
        final var ldfDataService = getInvestigationService(ldfTopic, ldfTopicOutput);
        assertThrows(NoDataException.class, () -> ldfDataService.processMessage(payload, ldfTopic));
    }

    private void validateData(String inputTopicName, String outputTopicName,
                              String payload, LdfData ldfData) {
        final var ldfDataService = getInvestigationService(inputTopicName, outputTopicName);
        ldfDataService.processMessage(payload, inputTopicName);

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