package gov.cdc.etldatapipeline.commonutil.metrics;

import io.micrometer.core.instrument.*;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.stereotype.Component;

import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

@Component
@RequiredArgsConstructor
@Setter
public class CustomMetrics {
    private final MeterRegistry registry;
    private final ConcurrentMap<String, Meter> meters = new ConcurrentHashMap<>();

    public Counter counter(String name, String... tags) {
        return (Counter) meters.computeIfAbsent(name, k ->
                Counter.builder(name).tags(tags).register(registry));
    }

    public Timer timer(String name, String... tags) {
        return (Timer) meters.computeIfAbsent(name, k ->
                Timer.builder(name).tags(tags).register(registry)
        );
    }

    public <T> void gauge(String name, T obj, java.util.function.ToDoubleFunction<T> valueFunction, String... tags) {
        Objects.requireNonNull(obj, "gauge source");
        meters.computeIfAbsent(name, k ->
                Gauge.builder(name, obj, valueFunction)
                        .tags(tags).register(registry));
    }

    public void recordTime(String name, Runnable runnable, String... tags) {
        timer(name, tags).record(runnable);
    }

    public Timer.Sample startSample() {
        return Timer.start(registry);
    }
    public void stopSample(Timer.Sample sample, Timer timer) {
        sample.stop(timer);
    }
}
