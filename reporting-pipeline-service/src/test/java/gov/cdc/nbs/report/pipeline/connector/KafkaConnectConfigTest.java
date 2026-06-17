package gov.cdc.nbs.report.pipeline.connector;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.io.DefaultResourceLoader;

class KafkaConnectConfigTest {

  @Test
  void run_is_noop_when_disabled() throws Exception {
    new KafkaConnectConfig(
            new ConnectorProperties(),
            new ObjectMapper(),
            new DefaultResourceLoader(),
            new StandardEnvironment())
        .run(null);
  }
}
