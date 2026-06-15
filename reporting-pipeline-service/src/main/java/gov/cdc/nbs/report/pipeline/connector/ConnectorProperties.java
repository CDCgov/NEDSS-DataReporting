package gov.cdc.nbs.report.pipeline.connector;

import java.util.List;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@ConfigurationProperties(prefix = "connector")
public class ConnectorProperties {

  private Group debezium = new Group();
  private Group kafkaConnect = new Group();

  @Data
  public static class Group {
    private boolean enabled;
    private String url;
    private int retryAttempts = 20;
    private long retryDelayMs = 5000;
    private List<String> definitions = List.of();
  }
}
