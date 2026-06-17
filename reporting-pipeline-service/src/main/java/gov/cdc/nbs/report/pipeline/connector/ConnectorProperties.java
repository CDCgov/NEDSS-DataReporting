package gov.cdc.nbs.report.pipeline.connector;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;
import org.springframework.boot.context.properties.bind.DefaultValue;

@ConfigurationProperties(prefix = "connector")
public record ConnectorProperties(@DefaultValue Group debezium, @DefaultValue Group kafkaConnect) {

  @ConstructorBinding
  public ConnectorProperties {}

  public ConnectorProperties() {
    this(new Group(), new Group());
  }

  public record Group(
      boolean enabled,
      String url,
      @DefaultValue("20") int retryAttempts,
      @DefaultValue("5000") long retryDelayMs,
      @DefaultValue List<String> definitions) {

    @ConstructorBinding
    public Group {}

    public Group() {
      this(false, null, 20, 5000L, List.of());
    }
  }
}
