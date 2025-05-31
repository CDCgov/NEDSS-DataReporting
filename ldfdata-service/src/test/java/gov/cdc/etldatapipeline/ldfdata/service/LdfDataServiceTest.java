package gov.cdc.etldatapipeline.ldfdata.service;

import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.ldfdata.repository.LdfDataRepository;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfData;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfDataKey;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;
import org.apache.kafka.clients.consumer.MockConsumer;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class LdfDataServiceTest {

    @Mock
    private LdfDataRepository ldfDataRepository;

    @Mock
    KafkaTemplate<String, String> kafkaTemplate;

    @Mock
    MockConsumer<String, String> consumer;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    private AutoCloseable closeable;
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();
    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();


    @BeforeEach
    void setUp() {
        closeable=MockitoAnnotations.openMocks(this);

        Logger logger = (Logger) LoggerFactory.getLogger(LdfDataService.class);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    void tearDown() throws Exception {
        closeable.close();
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
    void testProcessDeleteMessage() {
        String ldfTopic = "LdfData";
        String ldfTopicOutput = "LdfDataOutput";

        String busObjNm = "PHC";
        long ldfUid = 100000001L;
        long busObjUid = 100000010L;
        String payload = "{\"payload\": {\"before\": {" +
                "\"business_object_nm\": \"" + busObjNm + "\"," +
                "\"ldf_uid\": \"" + ldfUid + "\"," +
                "\"business_object_uid\": \"" + busObjUid + "\"}, \"op\":\"d\"}}";
        final LdfData ldfData = constructLdfData(busObjNm, ldfUid, busObjUid);
        validateData(ldfTopic, ldfTopicOutput, payload, ldfData);
    }

    @Test
    void testProcessMessageException() {
        String ldfTopic = "LdfData";
        String ldfTopicOutput = "LdfDataOutput";
        String invalidPayload = "{\"payload\": {\"after\": }}";
        ConsumerRecord<String, String> rec = getRecord(invalidPayload, ldfTopic);
        var ldfDataService = getInvestigationService(ldfTopic, ldfTopicOutput);
        assertThrows(RuntimeException.class, () -> ldfDataService.processMessage(rec, consumer));
    }

    @Test
    void testProcessEmptyMessage() {
        String ldfTopic = "LdfData";
        String ldfTopicOutput = "LdfDataOutput";
        testEmptyMessage(ldfTopic, ldfTopicOutput, null);
        testEmptyMessage(ldfTopic, ldfTopicOutput, "");
    }

    private void testEmptyMessage(String ldfTopic, String ldfTopicOutput, String payload){
        ConsumerRecord<String, String> rec = getRecord(payload, ldfTopic);
        final var ldfDataService = getInvestigationService(ldfTopic, ldfTopicOutput);
        ldfDataService.processMessage(rec, consumer);
        List<ILoggingEvent> logs = listAppender.list;
        assertTrue(logs.getFirst().getFormattedMessage().contains("Received null or empty message on topic: "+ldfTopic));
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
        ConsumerRecord<String, String> rec = getRecord(payload, ldfTopic);
        assertThrows(NoDataException.class, () -> ldfDataService.processMessage(rec, consumer));
    }

    @ParameterizedTest
    @CsvSource({
            "'{\"payload\": {\"before\": {}}}'",
            "'{\"payload\": {\"after\": {\"business_object_nm\": \"PHC\", \"business_object_uid\": \"100000010\"}}}'",
            "'{\"payload\": {\"after\": {\"business_object_nm\": \"PHC\", \"ldf_uid\": \"100000001\"}}}'",
            "'{\"payload\": {\"after\": {\"ldf_uid\": \"100000001\", \"business_object_uid\": \"100000010\"}}}'"
    })
    void testProcessMessageIncompleteData(String payload) {
        String ldfTopic = "LdfData";
        String ldfTopicOutput = "LdfDataOutput";

        final var ldfDataService = getInvestigationService(ldfTopic, ldfTopicOutput);
        ConsumerRecord<String, String> rec = getRecord(payload, ldfTopic);
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> ldfDataService.processMessage(rec, consumer));
        assertEquals(NoSuchElementException.class, ex.getCause().getClass());
    }

    private void validateData(String inputTopicName, String outputTopicName,
                              String payload, LdfData ldfData) {
        final var ldfDataService = getInvestigationService(inputTopicName, outputTopicName);
        ConsumerRecord<String, String> rec = getRecord(payload, inputTopicName);
        ldfDataService.processMessage(rec, consumer);

        LdfDataKey ldfDataKey = new LdfDataKey();
        ldfDataKey.setLdfUid(ldfData.getLdfUid());

        String expectedKey = jsonGenerator.generateStringJson(ldfDataKey);
        String expectedValue = jsonGenerator.generateStringJson(ldfData);

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());
        assertEquals(outputTopicName, topicCaptor.getValue());
        assertEquals(expectedKey, keyCaptor.getValue());
        assertEquals(expectedValue, messageCaptor.getValue());
        assertTrue(keyCaptor.getValue().contains(String.valueOf(ldfDataKey.getLdfUid())));
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

    private ConsumerRecord<String, String> getRecord(String payload, String topic) {
        return new ConsumerRecord<>(topic, 0, 11L, null, payload);
    }
}