package gov.cdc.etldatapipeline.postprocessingservice.integration.util;

import java.time.Duration;
import java.util.Optional;
import java.util.function.Function;

public class Await {

  private static final Duration DEFAULT_RETRY_DELAY = Duration.ofSeconds(6);
  private static final int DEFAULT_MAX_RETRY = 40;

  /**
   * Calls the provided function until it returns a non-empty Optional or the retry limit is
   * reached.
   *
   * @param <I> Generic Input
   * @param <O> Generic Output
   * @param function Function that accepts a single parameter of type I and returns an
   *     Optional{@literal <O>}
   * @param parameter The single parameter of type I to be passed to the function
   * @return
   */
  public static <I, O> Optional<O> waitFor(Function<I, Optional<O>> function, I parameter) {
    return waitFor(function, parameter, DEFAULT_MAX_RETRY, DEFAULT_RETRY_DELAY);
  }

  @SuppressWarnings("java:S2925") // this code sleeps while waiting.
  public static <A, B> Optional<B> waitFor(
      Function<A, Optional<B>> function, A parameter, int maxRetry, Duration retryDelay) {
    int retryCount = 0;
    Optional<B> result = Optional.empty();

    while (retryCount < maxRetry && result.isEmpty()) {
      retryCount += 1;
      result = function.apply(parameter);

      if (result.isEmpty()) {
        try {
          Thread.sleep(retryDelay);
        } catch (InterruptedException e) {
          return result;
        }
      }
    }
    return result;
  }
}
