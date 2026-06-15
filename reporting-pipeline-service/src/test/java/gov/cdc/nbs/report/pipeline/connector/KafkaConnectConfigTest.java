package gov.cdc.nbs.report.pipeline.connector;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.DefaultResourceLoader;

class KafkaConnectConfigTest {

  @Test
  void run_is_noop_when_disabled() throws Exception {
    ConnectorProperties properties = new ConnectorProperties();
    properties.getKafkaConnect().setEnabled(false);
    properties.getKafkaConnect().setUrl("http://unreachable:9999");

    new KafkaConnectConfig(properties, new ObjectMapper(), new DefaultResourceLoader()).run(null);
  }
}
