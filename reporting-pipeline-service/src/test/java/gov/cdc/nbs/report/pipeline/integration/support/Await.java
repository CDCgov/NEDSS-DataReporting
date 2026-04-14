package gov.cdc.nbs.report.pipeline.integration.support;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import java.text.SimpleDateFormat;
import java.time.Duration;
import java.util.Optional;
import java.util.function.Supplier;
import org.json.JSONException;
import org.skyscreamer.jsonassert.JSONCompare;
import org.skyscreamer.jsonassert.JSONCompareMode;

public class Await {

  private static final Duration DEFAULT_RETRY_DELAY = Duration.ofSeconds(6);
  private static final int DEFAULT_MAX_RETRY = 20;
  private static final ObjectMapper MAPPER =
      new ObjectMapper()
          .enable(SerializationFeature.INDENT_OUTPUT)
          .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
          .setDateFormat(new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS"));

  private Await() {}

  /**
   * Calls the provided function until it returns a non-empty Optional or the retry limit is
   * reached.
   *
   * @param <O> Generic Output
   * @param function Supplier that returns an Optional{@literal <O>}s
   * @return
   */
  public static <O> Optional<O> waitFor(Supplier<Optional<O>> function) {
    return waitFor(function, DEFAULT_MAX_RETRY, DEFAULT_RETRY_DELAY);
  }

  @SuppressWarnings("java:S2925") // this code sleeps while waiting.
  public static <O> Optional<O> waitFor(
      Supplier<Optional<O>> function, int maxRetry, Duration retryDelay) {
    int retryCount = 0;
    Optional<O> result = Optional.empty();

    while (retryCount < maxRetry && result.isEmpty()) {
      retryCount += 1;
      result = function.get();

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

  /**
   * Calls the provided function until it returns a non-empty Optional that matches the expected
   * value or the retry limit is reached. Compares results to the expected by using {@link
   * JSONCompare#compareJSON} with compare mode set to LENIENT
   *
   * @param <O> Generic Output
   * @param function Supplier that returns an Optional{@literal <O>}s
   * @param expected The expected data that the query will return
   * @return
   */
  public static <O> Optional<O> waitForMatch(Supplier<Optional<O>> function, String expected)
      throws JsonProcessingException, JSONException {
    return waitForMatch(function, expected, DEFAULT_MAX_RETRY, DEFAULT_RETRY_DELAY);
  }

  @SuppressWarnings("java:S2925") // this code sleeps while waiting.
  public static <O> Optional<O> waitForMatch(
      Supplier<Optional<O>> function, String expected, int maxRetry, Duration retryDelay)
      throws JSONException, JsonProcessingException {
    int retryCount = 0;
    Optional<O> result = Optional.empty();

    while (retryCount < maxRetry) {
      retryCount += 1;
      result = function.get();

      if (result.isPresent()
          && JSONCompare.compareJSON(
                  expected, MAPPER.writeValueAsString(result.get()), JSONCompareMode.LENIENT)
              .passed()) {
        return result;
      }

      try {
        Thread.sleep(retryDelay);
      } catch (InterruptedException e) {
        return result;
      }
    }
    return result;
  }
}
