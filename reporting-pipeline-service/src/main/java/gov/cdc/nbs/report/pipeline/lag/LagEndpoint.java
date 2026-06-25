package gov.cdc.nbs.report.pipeline.lag;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.LongSupplier;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.ReadOperation;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;
import org.springframework.stereotype.Component;

/**
 * Reports the pipeline's outstanding work: how far behind the {@code nbs_*} consumer (the pipeline
 * app) and the {@code nrt_*} consumer (the Kafka Connect sink) are from the end of their topics.
 *
 * <p>This is a dedicated actuator endpoint rather than a {@code HealthIndicator} on purpose: it
 * talks to Kafka (offset reads plus a record peek), and we only want to pay that cost on an
 * explicit request. As its own endpoint it runs lazily when {@code /actuator/lag} is called and is
 * <em>not</em> aggregated into {@code /actuator/health}.
 *
 * <p>Each side reports two complementary measures of backlog: {@code recordsBehind} (how many
 * messages are queued, with a per-topic breakdown) and {@code timeLagSecs} (how far back in time
 * the oldest unconsumed record was produced). When both sides are caught up the status is {@link
 * #READY}; otherwise {@link #PROCESSING}.
 */
@Component
@Endpoint(id = "lag")
public class LagEndpoint {

  /** Both consumer groups are caught up — no backlog remains. */
  public static final Status READY = new Status("READY");

  /** Backlog remains — at least one consumer group is still working through its topics. */
  public static final Status PROCESSING = new Status("PROCESSING");

  private final TopicLagReader lagReader;
  private final LagProperties properties;
  private final LongSupplier clock;

  @Autowired
  public LagEndpoint(TopicLagReader lagReader, LagProperties properties) {
    this(lagReader, properties, System::currentTimeMillis);
  }

  LagEndpoint(TopicLagReader lagReader, LagProperties properties, LongSupplier clock) {
    this.lagReader = lagReader;
    this.properties = properties;
    this.clock = clock;
  }

  @ReadOperation
  public Health lag() {
    if (!properties.enabled()) {
      return Health.up().withDetail("status", "DISABLED").build();
    }
    try {
      Map<String, TopicLag> nbs =
          lagReader.lagByTopic(properties.pipelineGroupId(), properties.nbsTopicPrefix());
      Map<String, TopicLag> nrt =
          lagReader.lagByTopic(properties.sinkGroupId(), properties.nrtTopicPrefix());

      long now = clock.getAsLong();
      boolean caughtUp = totalLag(nbs) == 0 && totalLag(nrt) == 0;

      Health.Builder builder = caughtUp ? Health.status(READY) : Health.status(PROCESSING);
      builder
          .withDetail("caughtUp", caughtUp)
          .withDetail("nbs", summarize(nbs, now))
          .withDetail("nrt", summarize(nrt, now));
      if (!hasData(nbs)) {
        builder.withDetail(
            "note", "no nbs_* data observed yet; the initial snapshot may not have started");
      }
      return builder.build();
    } catch (LagInspectionException e) {
      return Health.down(e).build();
    }
  }

  /** Builds the per-group view: total records behind, the worst time-lag, and a per-topic count. */
  private static Map<String, Object> summarize(Map<String, TopicLag> lags, long now) {
    long recordsBehind = 0L;
    Long oldest = null;
    Map<String, Long> byTopic = new LinkedHashMap<>();
    for (Map.Entry<String, TopicLag> entry : lags.entrySet()) {
      TopicLag lag = entry.getValue();
      recordsBehind += lag.lag();
      if (!lag.drained()) {
        byTopic.put(entry.getKey(), lag.lag());
      }
      Long timestamp = lag.oldestUnconsumedTimestampMillis();
      if (timestamp != null) {
        oldest = (oldest == null) ? timestamp : Math.min(oldest, timestamp);
      }
    }

    Map<String, Object> summary = new LinkedHashMap<>();
    summary.put("recordsBehind", recordsBehind);
    summary.put("timeLagSecs", oldest == null ? 0L : Math.max(0L, now - oldest) / 1000L);
    summary.put("byTopic", byTopic);
    return summary;
  }

  private static long totalLag(Map<String, TopicLag> lags) {
    return lags.values().stream().mapToLong(TopicLag::lag).sum();
  }

  private static boolean hasData(Map<String, TopicLag> lags) {
    return lags.values().stream().anyMatch(TopicLag::hasData);
  }
}
