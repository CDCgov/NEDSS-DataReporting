package gov.cdc.etldatapipeline.observation.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;
import static org.mockito.Mockito.verify;
import static org.junit.jupiter.api.Assertions.assertEquals;

class KafkaProducerServiceTest {

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    @InjectMocks
    private KafkaProducerService kafkaProducerService;

    @Captor
    private ArgumentCaptor<String> topicCaptor;

    @Captor
    private ArgumentCaptor<String> messageCaptor;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testSendMessage() {
        String topicName = "test-topic";
        String jsonData = "{\"key\":\"value\"}";

        kafkaProducerService.sendMessage(topicName, jsonData);

        verify(kafkaTemplate).send(topicCaptor.capture(), messageCaptor.capture());
        assertEquals(topicName, topicCaptor.getValue());
        assertEquals(jsonData, messageCaptor.getValue());
    }
}
