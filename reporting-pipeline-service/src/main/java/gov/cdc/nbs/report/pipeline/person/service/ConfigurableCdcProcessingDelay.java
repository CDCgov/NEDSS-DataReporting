package gov.cdc.nbs.report.pipeline.person.service;

import java.time.Duration;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("test")
class ConfigurableCdcProcessingDelay implements CdcProcessingDelay {
  private final boolean enabled;
  private final String entity;
  private final String uid;
  private final String operation;
  private final long timeoutMillis;
  private final CountDownLatch entered = new CountDownLatch(1);
  private final CountDownLatch released = new CountDownLatch(1);

  ConfigurableCdcProcessingDelay(
      @Value("${spike.cdc-delay.enabled:false}") boolean enabled,
      @Value("${spike.cdc-delay.entity:person}") String entity,
      @Value("${spike.cdc-delay.uid:0}") String uid,
      @Value("${spike.cdc-delay.operation:u}") String operation,
      @Value("${spike.cdc-delay.timeout-ms:10000}") long timeoutMillis) {
    if (timeoutMillis < 1) {
      throw new IllegalArgumentException("CDC delay timeout must be positive");
    }
    this.enabled = enabled;
    this.entity = entity;
    this.uid = uid;
    this.operation = operation;
    this.timeoutMillis = timeoutMillis;
  }

  @Override
  public void await(String eventEntity, String eventUid, String eventOperation) {
    if (!matches(eventEntity, eventUid, eventOperation)) {
      return;
    }

    entered.countDown();
    try {
      if (!released.await(timeoutMillis, TimeUnit.MILLISECONDS)) {
        throw new IllegalStateException("Timed out waiting to release the configured CDC delay");
      }
    } catch (InterruptedException exception) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException(
          "Interrupted while waiting to release the configured CDC delay", exception);
    }
  }

  boolean awaitEntered(Duration timeout) {
    try {
      return entered.await(timeout.toMillis(), TimeUnit.MILLISECONDS);
    } catch (InterruptedException exception) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException(
          "Interrupted while waiting for the configured CDC delay", exception);
    }
  }

  void release() {
    released.countDown();
  }

  private boolean matches(String eventEntity, String eventUid, String eventOperation) {
    return enabled
        && entity.equals(eventEntity)
        && uid.equals(eventUid)
        && operation.equals(eventOperation);
  }
}
