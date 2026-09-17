package gov.cdc.nbs.report.pipeline.person;

import gov.cdc.nbs.report.pipeline.person.service.PersonService;
import java.util.List;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

/**
 * Kafka listener for person and auth-user change events. Messages are consumed in batches and
 * processed synchronously on the listener container thread.
 *
 * <p>Processing is intentionally synchronous. Retry and dead-letter handling are delegated to the
 * {@code personBatchErrorHandler} configured on the listener container factory, and that handler
 * is only invoked when the listener method itself throws. If a batch listener returns a {@code
 * CompletableFuture} instead, Spring Kafka handles a failed future inside the listener adapter
 * ({@code MessagingMessageListenerAdapter.asyncFailure}), which logs the error and acknowledges the
 * batch - the container error handler, {@link
 * org.springframework.kafka.listener.BatchListenerFailedException} index, retries, and dead-letter
 * topic are all bypassed. Async retry support in Spring Kafka exists only for single-record
 * listeners.
 *
 * <p>Parallelism is provided by the container's concurrency setting (one consumer per partition up
 * to the configured concurrency) rather than a separate executor.
 */
@Service
public class PersonListener {

  private final PersonService personService;

  public PersonListener(final PersonService personService) {
    this.personService = personService;
  }

  /**
   * Consumes a batch of person change events.
   *
   * <p>Exceptions thrown by {@link PersonService#processPersonMessages(List)} propagate to the
   * container error handler. A {@link
   * org.springframework.kafka.listener.BatchListenerFailedException} commits offsets before the
   * failed index and retries from that record.
   *
   * @param kafkaMessages raw message values for the polled batch, in delivery order
   */
  @KafkaListener(
      topics = {"${spring.kafka.topics.nbs.person}"},
      batch = "true",
      containerFactory = "personKafkaListenerContainerFactory")
  public void processPersonMessage(List<String> kafkaMessages) {
    personService.processPersonMessages(kafkaMessages);
  }

  /**
   * Consumes a batch of auth-user change events.
   *
   * <p>Exceptions thrown by {@link PersonService#processUser(List)} propagate to the container
   * error handler.
   *
   * @param kafkaMessages raw message values for the polled batch, in delivery order
   */
  @KafkaListener(
      topics = {"${spring.kafka.topics.nbs.auth-user}"},
      batch = "true",
      containerFactory = "personKafkaListenerContainerFactory")
  public void processAuthUserMessage(List<String> kafkaMessages) {
    personService.processUser(kafkaMessages);
  }
}
