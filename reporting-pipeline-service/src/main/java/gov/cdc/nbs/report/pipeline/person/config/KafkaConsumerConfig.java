package gov.cdc.nbs.report.pipeline.person.config;

import gov.cdc.nbs.report.pipeline.util.NoDataException;
import java.util.HashMap;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.KafkaOperations;
import org.springframework.kafka.listener.CommonErrorHandler;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.util.backoff.FixedBackOff;

@Slf4j
@EnableKafka
@Configuration("personKafkaConsumerConfig")
public class KafkaConsumerConfig {

  @Value("${spring.kafka.group-id}")
  private String groupId = "";

  @Value("${spring.kafka.bootstrap-servers}")
  private String bootstrapServers = "";

  @Value("${spring.kafka.consumer.maxPollIntervalMs}")
  private String maxPollInterval = "";

  @Value("${spring.kafka.consumer.maxPollRecs}")
  private String maxPollRecords = "";

  @Value("${spring.kafka.consumer.auto-offset-reset}")
  private String autoOffsetReset = "";

  @Value("${spring.kafka.consumer.max-retry:3}")
  private int maxRetryAttempts;

  @Value("${spring.kafka.dlq.dlq-suffix:_dlt}")
  private String dlqSuffix;

  @Value("${featureFlag.thread-pool-size:1}")
  private int concurrency = 1;

  @Bean
  public ConsumerFactory<String, String> personConsumerFactory() {
    final Map<String, Object> config = new HashMap<>();
    config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    config.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
    config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, autoOffsetReset);
    config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    config.put(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG, maxPollInterval);
    config.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, maxPollRecords);
    return new DefaultKafkaConsumerFactory<>(config);
  }

  /**
   * Publishes an individually failed record to a dead-letter topic named {@code
   * <source-topic>{dlqSuffix}}, preserving the original partition.
   *
   * @param kafkaTemplate template used to publish to the dead-letter topic
   * @return recoverer invoked by {@link #personBatchErrorHandler} once retries are exhausted
   */
  @Bean
  public DeadLetterPublishingRecoverer personDeadLetterRecoverer(
      @Qualifier("personKafkaTemplate") KafkaOperations<String, String> kafkaTemplate) {
    return new DeadLetterPublishingRecoverer(
        kafkaTemplate,
        (message, ex) -> new TopicPartition(message.topic() + dlqSuffix, message.partition()));
  }

  /**
   * Error handler for the person batch listener.
   *
   * <p>On {@link org.springframework.kafka.listener.BatchListenerFailedException}, offsets
   * preceding the failed index are committed, and the failed record together with any subsequent
   * records in the batch are re-seeked for redelivery according to the configured backoff. Once the
   * backoff is exhausted, only the offending record is routed to the dead-letter topic via {@link
   * #personDeadLetterRecoverer}; the remainder of the batch is unaffected.
   *
   * <p>{@link NoDataException} and {@link DeserializationException} are excluded from retry since
   * neither is resolved by reprocessing the same payload.
   *
   * @param personDeadLetterRecoverer recoverer for records that exhaust retry attempts
   * @return configured batch-capable error handler
   */
  @Bean
  public CommonErrorHandler personBatchErrorHandler(
      DeadLetterPublishingRecoverer personDeadLetterRecoverer) {
    DefaultErrorHandler handler =
        new DefaultErrorHandler(
            personDeadLetterRecoverer, new FixedBackOff(1000L, maxRetryAttempts));
    handler.addNotRetryableExceptions(NoDataException.class, DeserializationException.class);
    handler.setCommitRecovered(true);
    handler.setSeekAfterError(true);
    return handler;
  }

  /**
   * Container factory for the person batch listener, wired with the batch-aware error handler
   * defined above.
   *
   * <p>Listeners using this factory must process synchronously (return {@code void}) and must not
   * enable async acks. The error handler is only invoked when the listener method throws; a failed
   * {@code CompletableFuture} from a batch listener is logged and acknowledged by Spring Kafka
   * without reaching the error handler.
   *
   * <p>Parallelism comes from container concurrency ({@code featureFlag.thread-pool-size}), which
   * creates one consumer per partition up to that number.
   *
   * @param personBatchErrorHandler error handler applied to containers built by this factory
   * @return configured listener container factory
   */
  @Bean
  public ConcurrentKafkaListenerContainerFactory<String, String>
      personKafkaListenerContainerFactory(CommonErrorHandler personBatchErrorHandler) {
    ConcurrentKafkaListenerContainerFactory<String, String> factory =
        new ConcurrentKafkaListenerContainerFactory<>();
    factory.setBatchListener(true);
    factory.setConsumerFactory(personConsumerFactory());
    factory.setConcurrency(concurrency);
    factory.setCommonErrorHandler(personBatchErrorHandler);
    return factory;
  }
}
