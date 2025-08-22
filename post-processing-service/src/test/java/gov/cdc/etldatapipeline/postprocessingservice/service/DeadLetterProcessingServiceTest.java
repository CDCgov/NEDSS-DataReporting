package gov.cdc.etldatapipeline.postprocessingservice.service;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern.DeadLetterLogRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern.model.DeadLetterLog;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.test.util.ReflectionTestUtils;

import java.lang.reflect.Method;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DeadLetterProcessingServiceTest {

    @Mock
    private DeadLetterLogRepository deadLetterLogRepository;

    @InjectMocks
    private DeadLetterProcessingService deadLetterProcessingService;

    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
    private Logger logger;

    @BeforeEach
    void setUp() {
        // Set up logging capture
        logger = (Logger) LoggerFactory.getLogger(DeadLetterProcessingService.class);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    void tearDown() {
        logger.detachAppender(listAppender);
        listAppender.stop();
    }

    @Test
    void testConstructor() {
        // Test that the service is properly constructed
        assertNotNull(deadLetterProcessingService);
        assertNotNull(ReflectionTestUtils.getField(deadLetterProcessingService, "deadLetterLogRepository"));
    }

    @Test
    void testHandlingDeadLetter_Success() throws Exception {
        // Arrange
        String payload = "test payload";
        String key = "test key";
        Long receiveTimestamp = System.currentTimeMillis();
        String topic = "test-topic";
        String stackTrace = "test stack trace";
        String originalConsumerGroup = "test-consumer-group";
        String exceptionFqcn = "test.exception.Class";
        String exceptionCauseFqcn = "test.cause.Exception";
        String exceptionMessage = "test exception message";

        DeadLetterLog savedLog = DeadLetterLog.builder()
                .id("test-id")
                .originTopic(topic)
                .payload(payload)
                .payloadKey(key)
                .originalConsumerGroup(originalConsumerGroup)
                .exceptionStackTrace(stackTrace)
                .exceptionFqcn(exceptionFqcn)
                .exceptionCauseFqcn(exceptionCauseFqcn)
                .exceptionMessage(exceptionMessage)
                .receivedAt(Timestamp.valueOf(LocalDateTime.now()))
                .build();

        when(deadLetterLogRepository.save(any(DeadLetterLog.class))).thenReturn(savedLog);

        // Act
        deadLetterProcessingService.handlingDeadLetter(
                payload, key, receiveTimestamp, topic, stackTrace,
                originalConsumerGroup, exceptionFqcn, exceptionCauseFqcn, exceptionMessage
        );

        // Assert
        ArgumentCaptor<DeadLetterLog> logCaptor = ArgumentCaptor.forClass(DeadLetterLog.class);
        verify(deadLetterLogRepository).save(logCaptor.capture());

        DeadLetterLog capturedLog = logCaptor.getValue();
        assertEquals(topic, capturedLog.getOriginTopic());
        assertEquals(payload, capturedLog.getPayload());
        assertEquals(key, capturedLog.getPayloadKey());
        assertEquals(originalConsumerGroup, capturedLog.getOriginalConsumerGroup());
        assertEquals(stackTrace, capturedLog.getExceptionStackTrace());
        assertEquals(exceptionFqcn, capturedLog.getExceptionFqcn());
        assertEquals(exceptionCauseFqcn, capturedLog.getExceptionCauseFqcn());
        assertEquals(exceptionMessage, capturedLog.getExceptionMessage());
        assertNotNull(capturedLog.getReceivedAt());
    }

    @Test
    void testHandlingDeadLetter_WithNullValues() throws Exception {
        // Arrange
        String payload = "test payload";
        String key = "test key";
        Long receiveTimestamp = System.currentTimeMillis();
        String topic = "test-topic";
        String stackTrace = null;
        String originalConsumerGroup = null;
        String exceptionFqcn = null;
        String exceptionCauseFqcn = null;
        String exceptionMessage = null;

        DeadLetterLog savedLog = DeadLetterLog.builder()
                .id("test-id")
                .originTopic(topic)
                .payload(payload)
                .payloadKey(key)
                .originalConsumerGroup(originalConsumerGroup)
                .exceptionStackTrace(stackTrace)
                .exceptionFqcn(exceptionFqcn)
                .exceptionCauseFqcn(exceptionCauseFqcn)
                .exceptionMessage(exceptionMessage)
                .receivedAt(Timestamp.valueOf(LocalDateTime.now()))
                .build();

        when(deadLetterLogRepository.save(any(DeadLetterLog.class))).thenReturn(savedLog);

        // Act
        deadLetterProcessingService.handlingDeadLetter(
                payload, key, receiveTimestamp, topic, stackTrace,
                originalConsumerGroup, exceptionFqcn, exceptionCauseFqcn, exceptionMessage
        );

        // Assert
        ArgumentCaptor<DeadLetterLog> logCaptor = ArgumentCaptor.forClass(DeadLetterLog.class);
        verify(deadLetterLogRepository).save(logCaptor.capture());

        DeadLetterLog capturedLog = logCaptor.getValue();
        assertEquals(topic, capturedLog.getOriginTopic());
        assertEquals(payload, capturedLog.getPayload());
        assertEquals(key, capturedLog.getPayloadKey());
        assertNull(capturedLog.getOriginalConsumerGroup());
        assertNull(capturedLog.getExceptionStackTrace());
        assertNull(capturedLog.getExceptionFqcn());
        assertNull(capturedLog.getExceptionCauseFqcn());
        assertNull(capturedLog.getExceptionMessage());
        assertNotNull(capturedLog.getReceivedAt());
    }

    @Test
    void testHandlingDeadLetter_RepositoryException() throws Exception {
        // Arrange
        String payload = "test payload";
        String key = "test key";
        Long receiveTimestamp = System.currentTimeMillis();
        String topic = "test-topic";
        String stackTrace = "test stack trace";
        String originalConsumerGroup = "test-consumer-group";
        String exceptionFqcn = "test.exception.Class";
        String exceptionCauseFqcn = "test.cause.Exception";
        String exceptionMessage = "test exception message";

        when(deadLetterLogRepository.save(any(DeadLetterLog.class)))
                .thenThrow(new RuntimeException("Database connection failed"));

        // Act
        deadLetterProcessingService.handlingDeadLetter(
                payload, key, receiveTimestamp, topic, stackTrace,
                originalConsumerGroup, exceptionFqcn, exceptionCauseFqcn, exceptionMessage
        );

        // Assert
        verify(deadLetterLogRepository).save(any(DeadLetterLog.class));
        
        // Verify that the exception was logged
        List<ILoggingEvent> logs = listAppender.list;
        assertFalse(logs.isEmpty());
        assertTrue(logs.stream()
                .anyMatch(log -> log.getMessage().contains("Database connection failed")));
    }

    @Test
    void testHandlingDeadLetter_EmptyPayload() throws Exception {
        // Arrange
        String payload = "";
        String key = "";
        Long receiveTimestamp = System.currentTimeMillis();
        String topic = "test-topic";
        String stackTrace = "test stack trace";
        String originalConsumerGroup = "test-consumer-group";
        String exceptionFqcn = "test.exception.Class";
        String exceptionCauseFqcn = "test.cause.Exception";
        String exceptionMessage = "test exception message";

        DeadLetterLog savedLog = DeadLetterLog.builder()
                .id("test-id")
                .originTopic(topic)
                .payload(payload)
                .payloadKey(key)
                .originalConsumerGroup(originalConsumerGroup)
                .exceptionStackTrace(stackTrace)
                .exceptionFqcn(exceptionFqcn)
                .exceptionCauseFqcn(exceptionCauseFqcn)
                .exceptionMessage(exceptionMessage)
                .receivedAt(Timestamp.valueOf(LocalDateTime.now()))
                .build();

        when(deadLetterLogRepository.save(any(DeadLetterLog.class))).thenReturn(savedLog);

        // Act
        deadLetterProcessingService.handlingDeadLetter(
                payload, key, receiveTimestamp, topic, stackTrace,
                originalConsumerGroup, exceptionFqcn, exceptionCauseFqcn, exceptionMessage
        );

        // Assert
        ArgumentCaptor<DeadLetterLog> logCaptor = ArgumentCaptor.forClass(DeadLetterLog.class);
        verify(deadLetterLogRepository).save(logCaptor.capture());

        DeadLetterLog capturedLog = logCaptor.getValue();
        assertEquals("", capturedLog.getPayload());
        assertEquals("", capturedLog.getPayloadKey());
    }

    @Test
    void testHandlingDeadLetter_LargePayload() throws Exception {
        // Arrange
        String payload = "x".repeat(10000); // Large payload
        String key = "test key";
        Long receiveTimestamp = System.currentTimeMillis();
        String topic = "test-topic";
        String stackTrace = "test stack trace";
        String originalConsumerGroup = "test-consumer-group";
        String exceptionFqcn = "test.exception.Class";
        String exceptionCauseFqcn = "test.cause.Exception";
        String exceptionMessage = "test exception message";

        DeadLetterLog savedLog = DeadLetterLog.builder()
                .id("test-id")
                .originTopic(topic)
                .payload(payload)
                .payloadKey(key)
                .originalConsumerGroup(originalConsumerGroup)
                .exceptionStackTrace(stackTrace)
                .exceptionFqcn(exceptionFqcn)
                .exceptionCauseFqcn(exceptionCauseFqcn)
                .exceptionMessage(exceptionMessage)
                .receivedAt(Timestamp.valueOf(LocalDateTime.now()))
                .build();

        when(deadLetterLogRepository.save(any(DeadLetterLog.class))).thenReturn(savedLog);

        // Act
        deadLetterProcessingService.handlingDeadLetter(
                payload, key, receiveTimestamp, topic, stackTrace,
                originalConsumerGroup, exceptionFqcn, exceptionCauseFqcn, exceptionMessage
        );

        // Assert
        ArgumentCaptor<DeadLetterLog> logCaptor = ArgumentCaptor.forClass(DeadLetterLog.class);
        verify(deadLetterLogRepository).save(logCaptor.capture());

        DeadLetterLog capturedLog = logCaptor.getValue();
        assertEquals(10000, capturedLog.getPayload().length());
        assertEquals(payload, capturedLog.getPayload());
    }

    @Test
    void testHandlingDeadLetter_SpecialCharacters() throws Exception {
        // Arrange
        String payload = "payload with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?";
        String key = "key with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?";
        Long receiveTimestamp = System.currentTimeMillis();
        String topic = "test-topic";
        String stackTrace = "stack trace with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?";
        String originalConsumerGroup = "consumer-group with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?";
        String exceptionFqcn = "exception.fqcn.with.special.chars:!@#$%^&*()_+-=[]{}|;':\",./<>?";
        String exceptionCauseFqcn = "cause.fqcn.with.special.chars:!@#$%^&*()_+-=[]{}|;':\",./<>?";
        String exceptionMessage = "exception message with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?";

        DeadLetterLog savedLog = DeadLetterLog.builder()
                .id("test-id")
                .originTopic(topic)
                .payload(payload)
                .payloadKey(key)
                .originalConsumerGroup(originalConsumerGroup)
                .exceptionStackTrace(stackTrace)
                .exceptionFqcn(exceptionFqcn)
                .exceptionCauseFqcn(exceptionCauseFqcn)
                .exceptionMessage(exceptionMessage)
                .receivedAt(Timestamp.valueOf(LocalDateTime.now()))
                .build();

        when(deadLetterLogRepository.save(any(DeadLetterLog.class))).thenReturn(savedLog);

        // Act
        deadLetterProcessingService.handlingDeadLetter(
                payload, key, receiveTimestamp, topic, stackTrace,
                originalConsumerGroup, exceptionFqcn, exceptionCauseFqcn, exceptionMessage
        );

        // Assert
        ArgumentCaptor<DeadLetterLog> logCaptor = ArgumentCaptor.forClass(DeadLetterLog.class);
        verify(deadLetterLogRepository).save(logCaptor.capture());

        DeadLetterLog capturedLog = logCaptor.getValue();
        assertEquals(payload, capturedLog.getPayload());
        assertEquals(key, capturedLog.getPayloadKey());
        assertEquals(stackTrace, capturedLog.getExceptionStackTrace());
        assertEquals(originalConsumerGroup, capturedLog.getOriginalConsumerGroup());
        assertEquals(exceptionFqcn, capturedLog.getExceptionFqcn());
        assertEquals(exceptionCauseFqcn, capturedLog.getExceptionCauseFqcn());
        assertEquals(exceptionMessage, capturedLog.getExceptionMessage());
    }

    @Test
    void testHandlingDeadLetter_TimestampHandling() throws Exception {
        // Arrange
        String payload = "test payload";
        String key = "test key";
        Long receiveTimestamp = 1640995200000L; // Fixed timestamp for testing
        String topic = "test-topic";
        String stackTrace = "test stack trace";
        String originalConsumerGroup = "test-consumer-group";
        String exceptionFqcn = "test.exception.Class";
        String exceptionCauseFqcn = "test.cause.Exception";
        String exceptionMessage = "test exception message";

        DeadLetterLog savedLog = DeadLetterLog.builder()
                .id("test-id")
                .originTopic(topic)
                .payload(payload)
                .payloadKey(key)
                .originalConsumerGroup(originalConsumerGroup)
                .exceptionStackTrace(stackTrace)
                .exceptionFqcn(exceptionFqcn)
                .exceptionCauseFqcn(exceptionCauseFqcn)
                .exceptionMessage(exceptionMessage)
                .receivedAt(Timestamp.valueOf(LocalDateTime.now()))
                .build();

        when(deadLetterLogRepository.save(any(DeadLetterLog.class))).thenReturn(savedLog);

        // Act
        deadLetterProcessingService.handlingDeadLetter(
                payload, key, receiveTimestamp, topic, stackTrace,
                originalConsumerGroup, exceptionFqcn, exceptionCauseFqcn, exceptionMessage
        );

        // Assert
        ArgumentCaptor<DeadLetterLog> logCaptor = ArgumentCaptor.forClass(DeadLetterLog.class);
        verify(deadLetterLogRepository).save(logCaptor.capture());

        DeadLetterLog capturedLog = logCaptor.getValue();
        assertNotNull(capturedLog.getReceivedAt());
        
        // Verify that the receivedAt timestamp is close to the current time
        long currentTime = System.currentTimeMillis();
        long receivedTime = capturedLog.getReceivedAt().getTime();
        assertTrue(Math.abs(currentTime - receivedTime) < 1000); // Within 1 second
    }

    @Test
    void testHandlingDeadLetter_MultipleCalls() throws Exception {
        // Arrange
        String[] payloads = {"payload1", "payload2", "payload3"};
        String[] keys = {"key1", "key2", "key3"};
        String[] topics = {"topic1", "topic2", "topic3"};
        
        DeadLetterLog savedLog = DeadLetterLog.builder()
                .id("test-id")
                .originTopic("test-topic")
                .payload("test-payload")
                .payloadKey("test-key")
                .originalConsumerGroup("test-consumer-group")
                .exceptionStackTrace("test stack trace")
                .exceptionFqcn("test.exception.Class")
                .exceptionCauseFqcn("test.cause.Exception")
                .exceptionMessage("test exception message")
                .receivedAt(Timestamp.valueOf(LocalDateTime.now()))
                .build();

        when(deadLetterLogRepository.save(any(DeadLetterLog.class))).thenReturn(savedLog);

        // Act - Call the method multiple times
        for (int i = 0; i < payloads.length; i++) {
            deadLetterProcessingService.handlingDeadLetter(
                    payloads[i], keys[i], System.currentTimeMillis(), topics[i], "stack trace",
                    "consumer-group", "exception.fqcn", "cause.fqcn", "exception message"
            );
        }

        // Assert - Verify that save was called for each payload
        verify(deadLetterLogRepository, times(3)).save(any(DeadLetterLog.class));
    }

    @Test
    void testKafkaListenerAnnotation() throws Exception {
        // Test that the KafkaListener annotation is present with correct configuration
        Method method = DeadLetterProcessingService.class.getMethod("handlingDeadLetter",
                String.class, String.class, Long.class, String.class, String.class,
                String.class, String.class, String.class, String.class);

        assertTrue(method.isAnnotationPresent(org.springframework.kafka.annotation.KafkaListener.class));
        
        org.springframework.kafka.annotation.KafkaListener annotation = 
                method.getAnnotation(org.springframework.kafka.annotation.KafkaListener.class);
        
        assertNotNull(annotation);
        assertTrue(annotation.topics().length > 0);
        assertEquals("kafkaListenerContainerFactoryDlt", annotation.containerFactory());
    }

    @Test
    void testTransactionalAnnotation() throws Exception {
        // Test that the Transactional annotation is present with correct configuration
        Method method = DeadLetterProcessingService.class.getMethod("handlingDeadLetter",
                String.class, String.class, Long.class, String.class, String.class,
                String.class, String.class, String.class, String.class);

        assertTrue(method.isAnnotationPresent(org.springframework.transaction.annotation.Transactional.class));
        
        org.springframework.transaction.annotation.Transactional annotation = 
                method.getAnnotation(org.springframework.transaction.annotation.Transactional.class);
        
        assertNotNull(annotation);
        assertEquals("modernTransactionManager", annotation.value());
    }

    @Test
    void testDeadLetterLogBuilder() {
        // Test the DeadLetterLog builder functionality
        DeadLetterLog log = DeadLetterLog.builder()
                .originTopic("test-topic")
                .payload("test-payload")
                .payloadKey("test-key")
                .originalConsumerGroup("test-consumer-group")
                .exceptionStackTrace("test stack trace")
                .exceptionFqcn("test.exception.Class")
                .exceptionCauseFqcn("test.cause.Exception")
                .exceptionMessage("test exception message")
                .receivedAt(Timestamp.valueOf(LocalDateTime.now()))
                .build();

        assertNotNull(log);
        assertEquals("test-topic", log.getOriginTopic());
        assertEquals("test-payload", log.getPayload());
        assertEquals("test-key", log.getPayloadKey());
        assertEquals("test-consumer-group", log.getOriginalConsumerGroup());
        assertEquals("test stack trace", log.getExceptionStackTrace());
        assertEquals("test.exception.Class", log.getExceptionFqcn());
        assertEquals("test.cause.Exception", log.getExceptionCauseFqcn());
        assertEquals("test exception message", log.getExceptionMessage());
        assertNotNull(log.getReceivedAt());
    }
}
