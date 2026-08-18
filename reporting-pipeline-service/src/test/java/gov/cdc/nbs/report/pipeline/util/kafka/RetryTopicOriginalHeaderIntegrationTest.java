package gov.cdc.nbs.report.pipeline.util.kafka;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.header.Header;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafkaRetryTopic;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.kafka.test.EmbeddedKafkaBroker;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.kafka.test.utils.KafkaTestUtils;
import org.springframework.retry.annotation.Backoff;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

@SpringJUnitConfig(classes = RetryTopicOriginalHeaderIntegrationTest.TestConfiguration.class)
@DirtiesContext
@EmbeddedKafka(
    partitions = 1,
    topics = {
      RetryTopicOriginalHeaderIntegrationTest.MAIN_TOPIC,
      RetryTopicOriginalHeaderIntegrationTest.RETRY_TOPIC_ZERO,
      RetryTopicOriginalHeaderIntegrationTest.RETRY_TOPIC_ONE,
      RetryTopicOriginalHeaderIntegrationTest.DLT_TOPIC
    })
class RetryTopicOriginalHeaderIntegrationTest {

  static final String MAIN_TOPIC = "retry-header-test";
  static final String RETRY_TOPIC_ZERO = MAIN_TOPIC + "_retry-0";
  static final String RETRY_TOPIC_ONE = MAIN_TOPIC + "_retry-1";
  static final String DLT_TOPIC = MAIN_TOPIC + "_dlt";
  private static final String GROUP_ID = "retry-header-test-group";

  @Autowired private KafkaTemplate<String, String> kafkaTemplate;
  @Autowired private RetryingListener listener;

  @Test
  void preservesOriginalTopicThroughTwoRetryLevels() throws Exception {
    kafkaTemplate.send(MAIN_TOPIC, "test-key", "test-value").get();

    assertTrue(listener.await(Duration.ofSeconds(20)), "Timed out waiting for retry deliveries");
    List<Delivery> deliveries = listener.deliveries();

    assertAll(
        () -> assertEquals(3, deliveries.size()),
        () -> assertEquals(MAIN_TOPIC, deliveries.get(0).physicalTopic()),
        () -> assertNull(deliveries.get(0).originalTopic()),
        () -> assertEquals(RETRY_TOPIC_ZERO, deliveries.get(1).physicalTopic()),
        () -> assertEquals(MAIN_TOPIC, deliveries.get(1).originalTopic()),
        () -> assertEquals(RETRY_TOPIC_ONE, deliveries.get(2).physicalTopic()),
        () -> assertEquals(MAIN_TOPIC, deliveries.get(2).originalTopic()),
        () ->
            assertEquals(
                List.of(MAIN_TOPIC, MAIN_TOPIC, MAIN_TOPIC),
                deliveries.stream().map(Delivery::logicalTopic).toList()));
  }

  record Delivery(String physicalTopic, String logicalTopic, String originalTopic) {}

  static final class RetryingListener {
    private final RetryTopicResolver resolver;
    private final List<Delivery> deliveries = new CopyOnWriteArrayList<>();
    private final CountDownLatch deliveryLatch = new CountDownLatch(3);
    private final AtomicInteger attempts = new AtomicInteger();

    RetryingListener(RetryTopicResolver resolver) {
      this.resolver = resolver;
    }

    @RetryableTopic(
        attempts = "3",
        autoCreateTopics = "false",
        retryTopicSuffix = "_retry",
        dltTopicSuffix = "_dlt",
        topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
        backoff = @Backoff(delay = 10, multiplier = 2.0),
        kafkaTemplate = "kafkaTemplate")
    @KafkaListener(topics = MAIN_TOPIC, groupId = GROUP_ID)
    void listen(ConsumerRecord<String, String> record) {
      TopicResolution resolution = resolver.resolve(record, Set.of(MAIN_TOPIC));
      deliveries.add(
          new Delivery(
              resolution.physicalTopic(), resolution.logicalTopic(), originalTopic(record)));
      deliveryLatch.countDown();

      if (attempts.incrementAndGet() < 3) {
        throw new IllegalStateException("Force retry");
      }
    }

    boolean await(Duration timeout) throws InterruptedException {
      return deliveryLatch.await(timeout.toMillis(), java.util.concurrent.TimeUnit.MILLISECONDS);
    }

    List<Delivery> deliveries() {
      return new ArrayList<>(deliveries);
    }

    private String originalTopic(ConsumerRecord<String, String> record) {
      Header header = record.headers().lastHeader(KafkaHeaders.ORIGINAL_TOPIC);
      return header == null ? null : new String(header.value(), StandardCharsets.UTF_8);
    }
  }

  @Configuration
  @EnableKafkaRetryTopic
  static class TestConfiguration {

    @Bean
    RetryTopicResolver retryTopicResolver() {
      return new RetryTopicResolver();
    }

    @Bean
    RetryingListener retryingListener(RetryTopicResolver resolver) {
      return new RetryingListener(resolver);
    }

    @Bean
    TaskScheduler taskScheduler() {
      ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
      scheduler.setPoolSize(1);
      scheduler.setThreadNamePrefix("retry-header-test-");
      return scheduler;
    }

    @Bean
    ProducerFactory<String, String> producerFactory(EmbeddedKafkaBroker broker) {
      Map<String, Object> properties = KafkaTestUtils.producerProps(broker);
      properties.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
      properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
      return new DefaultKafkaProducerFactory<>(properties);
    }

    @Bean
    KafkaTemplate<String, String> kafkaTemplate(ProducerFactory<String, String> producerFactory) {
      return new KafkaTemplate<>(producerFactory);
    }

    @Bean
    ConsumerFactory<String, String> consumerFactory(EmbeddedKafkaBroker broker) {
      Map<String, Object> properties = KafkaTestUtils.consumerProps(GROUP_ID, "false", broker);
      properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
      properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
      properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
      return new DefaultKafkaConsumerFactory<>(properties);
    }

    @Bean
    ConcurrentKafkaListenerContainerFactory<String, String> kafkaListenerContainerFactory(
        ConsumerFactory<String, String> consumerFactory) {
      ConcurrentKafkaListenerContainerFactory<String, String> factory =
          new ConcurrentKafkaListenerContainerFactory<>();
      factory.setConsumerFactory(consumerFactory);
      return factory;
    }
  }
}
