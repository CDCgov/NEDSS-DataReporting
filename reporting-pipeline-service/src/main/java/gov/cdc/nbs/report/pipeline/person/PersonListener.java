package gov.cdc.nbs.report.pipeline.person;

import gov.cdc.nbs.report.pipeline.person.service.PersonService;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;

/**
 * Kafka listener for person change events. Messages are consumed in batches and processed
 * asynchronously on a dedicated executor; retry and dead-letter handling for failed records is
 * delegated to the {@code personBatchErrorHandler} configured on the listener container factory
 * rather than handled here.
 */
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

  /**
   * Consumes a batch of person change events and processes them asynchronously.
   *
   * @param kafkaMessages raw message values for the polled batch, in delivery order
   * @return future completed when the batch has finished processing
   */
  @KafkaListener(
      topics = {"${spring.kafka.topics.nbs.person}"},
      batch = "true",
      containerFactory = "personKafkaListenerContainerFactory")
  public CompletableFuture<Void> processPersonMessage(List<String> kafkaMessages) {
    return CompletableFuture.runAsync(
        () -> personService.processPersonMessages(kafkaMessages), executor);
  }

  /**
   * Consumes a batch of auth-user change events and processes them asynchronously.
   *
   * @param kafkaMessages raw message values for the polled batch, in delivery order
   * @return future completed when the batch has finished processing
   */
  @KafkaListener(
      topics = {"${spring.kafka.topics.nbs.auth-user}"},
      batch = "true",
      containerFactory = "personKafkaListenerContainerFactory")
  public CompletableFuture<Void> processAuthUserMessage(List<String> kafkaMessages) {
    return CompletableFuture.runAsync(() -> personService.processUser(kafkaMessages), executor);
  }
}
