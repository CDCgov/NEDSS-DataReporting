package gov.cdc.etldatapipeline.postprocessingservice.integration.util;

import java.time.Duration;
import java.util.Optional;
import java.util.function.Function;

public class Await {

    private static final int DEFAULT_MAX_RETRY = 6;
    private static final Duration DEFAULT_RETRY_DELAY = Duration.ofSeconds(10);

    public static <A, B> Optional<B> waitFor(
            Function<A, Optional<B>> function,
            A parameter) {
        return waitFor(function, parameter, DEFAULT_MAX_RETRY, DEFAULT_RETRY_DELAY);
    }

    @SuppressWarnings("java:S2925") // this code sleeps while waiting.
    public static <A, B> Optional<B> waitFor(
            Function<A, Optional<B>> function,
            A parameter,
            int maxRetry,
            Duration retryDelay) {
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
