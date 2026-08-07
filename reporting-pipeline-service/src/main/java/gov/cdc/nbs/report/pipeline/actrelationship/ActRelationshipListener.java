package gov.cdc.nbs.report.pipeline.actrelationship;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.retrytopic.DltStrategy;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.retry.annotation.Backoff;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;

@Service
public class ActRelationshipListener {

  private final ActRelationshipProcessor processor;
  private final ExecutorService executor;

  public ActRelationshipListener(
      final ActRelationshipProcessor processor,
      @Value("${featureFlag.thread-pool-size:1}") final int threadPoolSize) {
    this.processor = processor;
    this.executor =
        Executors.newFixedThreadPool(
            threadPoolSize, new CustomizableThreadFactory("act-relationship-"));
  }

  @RetryableTopic(
      attempts = "${spring.kafka.consumer.max-retry}",
      autoCreateTopics = "false",
      dltStrategy = DltStrategy.FAIL_ON_ERROR,
      retryTopicSuffix = "${spring.kafka.dlq.retry-suffix}",
      dltTopicSuffix = "${spring.kafka.dlq.dlq-suffix}",
      // retry topic name, such as topic-retry-1, topic-retry-2, etc
      topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
      // time to wait before attempting to retry
      backoff = @Backoff(delay = 1000, multiplier = 2.0),
      exclude = {RuntimeException.class},
      kafkaTemplate = "investigationKafkaTemplate")
  @KafkaListener(
      topics = {"${spring.kafka.topics.nbs.act-relationship}"},
      containerFactory = "actRelationshipKafkaListenerContainerFactory")
  public CompletableFuture<Void> processMessage(ConsumerRecord<String, String> kafkaMessage) {
    return CompletableFuture.runAsync(
        () -> processor.process(kafkaMessage.value(), generateBatchId(kafkaMessage)), executor);
  }

  long generateBatchId(ConsumerRecord<String, String> kafkaMessage) {
    return kafkaMessage.timestamp() + kafkaMessage.offset() + kafkaMessage.partition();
  }
}
