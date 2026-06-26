package gov.cdc.nbs.report.pipeline.lag;

import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.ReadOperation;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;
import org.springframework.stereotype.Component;

/**
 * Reports the pipeline's outstanding work: how far behind the application's consumer group and the
 * Kafka Connect sink group are from the topics they consume.
 *
 * <p>This is a dedicated actuator endpoint rather than a {@code HealthIndicator} on purpose: it
 * talks to Kafka (consumer-group offset reads), and we only want to pay that cost on an explicit
 * request. As its own endpoint it runs lazily when {@code /actuator/lag} is called and is
 * <em>not</em> aggregated into {@code /actuator/health}.
 *
 * <p>Each group reports {@code messagesQueued} — how many messages are still unconsumed, with a
 * per-topic breakdown. When both groups are caught up the status is {@link #READY}; otherwise
 * {@link #PROCESSING}.
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

  /**
   * Constructs a new {@code LagEndpoint}.
   *
   * @param lagReader reads per-topic lag for a consumer group
   * @param properties the consumer group ids to inspect and whether the report is enabled
   */
  public LagEndpoint(TopicLagReader lagReader, LagProperties properties) {
    this.lagReader = lagReader;
    this.properties = properties;
  }

  /**
   * Reports the backlog of the pipeline and sink consumer groups, exposed at {@code /actuator/lag}.
   * Each group contributes its total {@code messagesQueued} and a per-topic breakdown of the topics
   * still carrying lag.
   *
   * @return {@link #READY} when both groups are caught up; {@link #PROCESSING} when a backlog
   *     remains; {@code UP} with a {@code DISABLED} detail when the report is turned off; or {@code
   *     DOWN} when Kafka offsets cannot be read
   */
  @ReadOperation
  public Health lag() {
    if (!properties.enabled()) {
      return Health.up().withDetail("status", "DISABLED").build();
    }
    try {
      Map<String, TopicLag> pipeline = lagReader.lagByGroup(properties.pipelineGroupId());
      Map<String, TopicLag> sink = lagReader.lagByGroup(properties.sinkGroupId());

      boolean caughtUp = totalLag(pipeline) == 0 && totalLag(sink) == 0;

      Health.Builder builder = caughtUp ? Health.status(READY) : Health.status(PROCESSING);
      builder
          .withDetail("caughtUp", caughtUp)
          .withDetail("pipeline", summarize(pipeline))
          .withDetail("sink", summarize(sink));
      if (!hasData(pipeline)) {
        builder.withDetail("note", "the pipeline consumer group has not consumed anything yet");
      }
      return builder.build();
    } catch (LagInspectionException e) {
      return Health.down(e).build();
    }
  }

  /** Builds the per-group view: total messages queued plus a per-topic count of what remains. */
  private static Map<String, Object> summarize(Map<String, TopicLag> lags) {
    long messagesQueued = 0L;
    Map<String, Long> byTopic = new LinkedHashMap<>();
    for (Map.Entry<String, TopicLag> entry : lags.entrySet()) {
      TopicLag lag = entry.getValue();
      messagesQueued += lag.lag();
      if (!lag.drained()) {
        byTopic.put(entry.getKey(), lag.lag());
      }
    }

    Map<String, Object> summary = new LinkedHashMap<>();
    summary.put("messagesQueued", messagesQueued);
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
