package gov.cdc.nbs.report.pipeline.person;

import gov.cdc.nbs.report.pipeline.person.service.PersonService;
import gov.cdc.nbs.report.pipeline.util.NoDataException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.errors.SerializationException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.retrytopic.DltStrategy;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.retry.annotation.Backoff;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;

@Service
public class PersonListener {

  private final PersonService personService;
  private final ExecutorService executor;

  public PersonListener(
      final PersonService personService,
      @Value("${featureFlag.thread-pool-size:1}") final int threadPoolSize) {
    this.personService = personService;
    this.executor =
        Executors.newFixedThreadPool(threadPoolSize, new CustomizableThreadFactory("prs-"));
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
      exclude = {
        SerializationException.class,
        DeserializationException.class,
        RuntimeException.class,
        NoDataException.class
      },
      kafkaTemplate = "personKafkaTemplate")
  @KafkaListener(
      topics = {"${spring.kafka.topics.nbs.person}"},
      containerFactory = "personKafkaListenerContainerFactory")
  public CompletableFuture<Void> processPersonMessage(ConsumerRecord<String, String> kafkaMessage) {
    return CompletableFuture.runAsync(
        () -> personService.processPerson(kafkaMessage.value(), kafkaMessage.topic()), executor);
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
      exclude = {
        SerializationException.class,
        DeserializationException.class,
        RuntimeException.class,
        NoDataException.class
      },
      kafkaTemplate = "personKafkaTemplate")
  @KafkaListener(
      topics = {"${spring.kafka.topics.nbs.auth-user}"},
      containerFactory = "personKafkaListenerContainerFactory")
  public CompletableFuture<Void> processAuthUserMessage(
      ConsumerRecord<String, String> kafkaMessage) {
    return CompletableFuture.runAsync(
        () -> personService.processUser(kafkaMessage.value(), kafkaMessage.topic()), executor);
  }
}
