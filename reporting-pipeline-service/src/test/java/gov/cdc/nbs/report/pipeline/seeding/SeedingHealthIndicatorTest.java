package gov.cdc.nbs.report.pipeline.seeding;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;

class SeedingHealthIndicatorTest {

  private static final SeedingProperties ENABLED =
      new SeedingProperties(true, "pipeline-consumer-app", "connect-sink", "nbs_", "nrt_", 10000L);

  /** Routes the two prefix-scoped lookups to canned results so the decision logic is isolated. */
  private static TopicLagReader reader(Map<String, TopicLag> nbs, Map<String, TopicLag> nrt) {
    return (groupId, topicPrefix) -> topicPrefix.equals("nbs_") ? nbs : nrt;
  }

  @Test
  void up_when_snapshot_data_present_and_both_groups_drained() {
    TopicLagReader reader =
        reader(
            Map.of("nbs_Person", new TopicLag(1000, 0)),
            Map.of("nrt_patient", new TopicLag(1000, 0)));

    Health health = new SeedingHealthIndicator(reader, ENABLED).health();

    assertEquals(Status.UP, health.getStatus());
    assertEquals(true, health.getDetails().get("seeded"));
  }

  @Test
  void seeding_when_nbs_topics_still_have_lag() {
    TopicLagReader reader =
        reader(
            Map.of("nbs_Person", new TopicLag(1000, 250)),
            Map.of("nrt_patient", new TopicLag(750, 0)));

    Health health = new SeedingHealthIndicator(reader, ENABLED).health();

    assertEquals(SeedingHealthIndicator.SEEDING, health.getStatus());
    assertEquals(false, health.getDetails().get("seeded"));
    assertEquals(250L, health.getDetails().get("nbsTopicLag"));
    @SuppressWarnings("unchecked")
    Map<String, Long> pending = (Map<String, Long>) health.getDetails().get("pendingNbsTopics");
    assertEquals(250L, pending.get("nbs_Person"));
  }

  @Test
  void seeding_when_sink_has_not_drained_nrt_topics() {
    TopicLagReader reader =
        reader(
            Map.of("nbs_Person", new TopicLag(1000, 0)),
            Map.of("nrt_patient", new TopicLag(1000, 40)));

    Health health = new SeedingHealthIndicator(reader, ENABLED).health();

    assertEquals(SeedingHealthIndicator.SEEDING, health.getStatus());
    assertEquals(40L, health.getDetails().get("nrtTopicLag"));
  }

  @Test
  void seeding_with_note_when_snapshot_has_not_started() {
    // Zero lag everywhere, but no data has been produced yet — must not be mistaken for "seeded".
    TopicLagReader reader =
        reader(Map.of("nbs_Person", new TopicLag(0, 0)), Map.of("nrt_patient", new TopicLag(0, 0)));

    Health health = new SeedingHealthIndicator(reader, ENABLED).health();

    assertEquals(SeedingHealthIndicator.SEEDING, health.getStatus());
    assertEquals(false, health.getDetails().get("seeded"));
    assertTrue(health.getDetails().containsKey("note"));
  }

  @Test
  void down_when_offsets_cannot_be_read() {
    TopicLagReader reader =
        (groupId, topicPrefix) -> {
          throw new SeedingInspectionException("broker unreachable", new RuntimeException());
        };

    Health health = new SeedingHealthIndicator(reader, ENABLED).health();

    assertEquals(Status.DOWN, health.getStatus());
  }

  @Test
  void up_and_disabled_when_check_is_turned_off() {
    SeedingProperties disabled = new SeedingProperties(false, "g", "s", "nbs_", "nrt_", 10000L);
    TopicLagReader reader =
        (groupId, topicPrefix) -> {
          throw new AssertionError("reader must not be called when disabled");
        };

    Health health = new SeedingHealthIndicator(reader, disabled).health();

    assertEquals(Status.UP, health.getStatus());
    assertEquals("DISABLED", health.getDetails().get("status"));
    assertFalse(health.getDetails().containsKey("seeded"));
  }
}
