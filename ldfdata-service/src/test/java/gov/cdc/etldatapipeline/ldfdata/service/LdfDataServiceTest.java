package gov.cdc.etldatapipeline.ldfdata.service;

import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.etldatapipeline.ldfdata.repository.LdfDataRepository;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfData;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfDataKey;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.*;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class LdfDataServiceTest {

    @InjectMocks
    private LdfDataService ldfDataService;

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

    private AutoCloseable closeable;
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();
    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();


    @BeforeEach
    void setUp() {
        closeable=MockitoAnnotations.openMocks(this);

        ldfDataService = new LdfDataService(ldfDataRepository, kafkaTemplate, new CustomMetrics(new SimpleMeterRegistry()));
        ldfDataService.setThreadPoolSize(1);
        ldfDataService.initMetrics();

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
        setupLdfService(ldfTopic, ldfTopicOutput);
        CompletableFuture<Void> future = ldfDataService.processMessage(getRecord(invalidPayload, ldfTopic));
        CompletionException ex = assertThrows(CompletionException.class, future::join);
        assertEquals(DataProcessingException.class, ex.getCause().getClass());
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
        setupLdfService(ldfTopic, ldfTopicOutput);
        ldfDataService.processMessage(rec);
        List<ILoggingEvent> logs = listAppender.list;
        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                assertTrue(logs.getFirst().getFormattedMessage().contains("Received null or empty message on topic: "+ldfTopic)));
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
        setupLdfService(ldfTopic, ldfTopicOutput);
        CompletableFuture<Void> future = ldfDataService.processMessage(getRecord(payload, ldfTopic));
        CompletionException ex = assertThrows(CompletionException.class, future::join);
        assertEquals(NoDataException.class, ex.getCause().getClass());
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

        setupLdfService(ldfTopic, ldfTopicOutput);
        CompletableFuture<Void> future = ldfDataService.processMessage(getRecord(payload, ldfTopic));
        CompletionException ex = assertThrows(CompletionException.class, future::join);
        assertEquals(DataProcessingException.class, ex.getCause().getClass());
    }

    private void validateData(String inputTopicName, String outputTopicName,
                              String payload, LdfData ldfData) {
        setupLdfService(inputTopicName, outputTopicName);
        ConsumerRecord<String, String> rec = getRecord(payload, inputTopicName);
        ldfDataService.processMessage(rec);

        LdfDataKey ldfDataKey = new LdfDataKey();
        ldfDataKey.setLdfUid(ldfData.getLdfUid());
        ldfDataKey.setBusObjUid(ldfData.getBusinessObjectUid());

        String expectedKey = jsonGenerator.generateStringJson(ldfDataKey);
        String expectedValue = jsonGenerator.generateStringJson(ldfData);

        Awaitility.await().atMost(1, TimeUnit.SECONDS).untilAsserted(() ->
                verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture()));
        assertEquals(outputTopicName, topicCaptor.getValue());
        assertEquals(expectedKey, keyCaptor.getValue());
        assertEquals(expectedValue, messageCaptor.getValue());
        assertTrue(keyCaptor.getValue().contains(String.valueOf(ldfDataKey.getLdfUid())));
    }

    private void setupLdfService(String inputTopicName, String outputTopicName) {
        ldfDataService.setLdfDataTopic(inputTopicName);
        ldfDataService.setLdfDataTopicReporting(outputTopicName);
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