package gov.cdc.nbs.report.pipeline.person.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalStateException;

import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import org.junit.jupiter.api.Test;

class ConfigurableCdcProcessingDelayTest {

  @Test
  void doesNotDelayWhenDisabled() {
    ConfigurableCdcProcessingDelay delay =
        new ConfigurableCdcProcessingDelay(false, "person", "42", "u", 10);

    delay.await("person", "42", "u");

    assertThat(delay.awaitEntered(Duration.ofMillis(1))).isFalse();
  }

  @Test
  void doesNotDelayWhenEventDoesNotMatchConfiguration() {
    ConfigurableCdcProcessingDelay delay =
        new ConfigurableCdcProcessingDelay(true, "person", "42", "u", 10);

    delay.await("person", "43", "u");

    assertThat(delay.awaitEntered(Duration.ofMillis(1))).isFalse();
  }

  @Test
  void waitsForReleaseWhenEventMatchesConfiguration() {
    ConfigurableCdcProcessingDelay delay =
        new ConfigurableCdcProcessingDelay(true, "person", "42", "u", 1000);

    CompletableFuture<Void> delayed =
        CompletableFuture.runAsync(() -> delay.await("person", "42", "u"));

    assertThat(delay.awaitEntered(Duration.ofSeconds(1))).isTrue();
    assertThat(delayed).isNotCompleted();

    delay.release();

    assertThat(delayed).succeedsWithin(Duration.ofSeconds(1));
  }

  @Test
  void failsWhenMatchingEventIsNotReleasedBeforeTimeout() {
    ConfigurableCdcProcessingDelay delay =
        new ConfigurableCdcProcessingDelay(true, "person", "42", "u", 1);

    assertThatIllegalStateException().isThrownBy(() -> delay.await("person", "42", "u"));
  }
}
