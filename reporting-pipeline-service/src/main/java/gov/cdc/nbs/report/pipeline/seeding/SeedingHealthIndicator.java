package gov.cdc.nbs.report.pipeline.seeding;

import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.boot.actuate.health.Status;
import org.springframework.stereotype.Component;

/**
 * Reports whether the initial Debezium snapshot has finished seeding the reporting database.
 *
 * <p>Seeding is complete when the pipeline has drained the {@code nbs_*} topics (no unconsumed
 * snapshot events remain) and the JDBC sink has drained the {@code nrt_*} topics (everything
 * produced has been written to {@code RDB_MODERN}). Until then the indicator reports the custom
 * {@link #SEEDING} status — deliberately <em>not</em> {@code DOWN}, so a normal seeding window does
 * not flip the service's overall health red or trip Kubernetes liveness/readiness probes.
 *
 * <p>Exposed at {@code /actuator/health/seeding}. When it reports {@code UP}, it is safe to enable
 * post-processing (see {@code documentation/SnapshotAwarePostProcessing.md}).
 */
@Component("seeding")
public class SeedingHealthIndicator implements HealthIndicator {

  /** Normal, expected state while the initial snapshot is still being loaded. */
  public static final Status SEEDING = new Status("SEEDING");

  private final TopicLagReader lagReader;
  private final SeedingProperties properties;

  public SeedingHealthIndicator(TopicLagReader lagReader, SeedingProperties properties) {
    this.lagReader = lagReader;
    this.properties = properties;
  }

  @Override
  public Health health() {
    if (!properties.enabled()) {
      return Health.up().withDetail("status", "DISABLED").build();
    }
    try {
      Map<String, TopicLag> nbs =
          lagReader.lagByTopic(properties.pipelineGroupId(), properties.nbsTopicPrefix());
      Map<String, TopicLag> nrt =
          lagReader.lagByTopic(properties.sinkGroupId(), properties.nrtTopicPrefix());

      long nbsLag = totalLag(nbs);
      long nrtLag = totalLag(nrt);
      boolean snapshotStarted = hasData(nbs);
      boolean drained = nbsLag == 0 && nrtLag == 0;
      boolean seeded = snapshotStarted && drained;

      Health.Builder builder = seeded ? Health.up() : Health.status(SEEDING);
      builder
          .withDetail("seeded", seeded)
          .withDetail("nbsTopicLag", nbsLag)
          .withDetail("nrtTopicLag", nrtLag)
          .withDetail("pendingNbsTopics", pending(nbs))
          .withDetail("pendingNrtTopics", pending(nrt));
      if (!snapshotStarted) {
        builder.withDetail(
            "note", "no nbs_* data observed yet; the initial snapshot may not have started");
      }
      return builder.build();
    } catch (SeedingInspectionException e) {
      return Health.down(e).build();
    }
  }

  private static long totalLag(Map<String, TopicLag> lags) {
    return lags.values().stream().mapToLong(TopicLag::lag).sum();
  }

  private static boolean hasData(Map<String, TopicLag> lags) {
    return lags.values().stream().anyMatch(TopicLag::hasData);
  }

  /** Topics still carrying lag, with their remaining count — the detail an operator wants. */
  private static Map<String, Long> pending(Map<String, TopicLag> lags) {
    Map<String, Long> pending = new LinkedHashMap<>();
    lags.forEach(
        (topic, lag) -> {
          if (!lag.drained()) {
            pending.put(topic, lag.lag());
          }
        });
    return pending;
  }
}
