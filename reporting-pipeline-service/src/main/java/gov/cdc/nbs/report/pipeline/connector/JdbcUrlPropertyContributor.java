package gov.cdc.nbs.report.pipeline.connector;

import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.stereotype.Component;
import org.springframework.util.PlaceholderResolutionException;

@Component
public class JdbcUrlPropertyContributor {

  private static final Logger log = LoggerFactory.getLogger(JdbcUrlPropertyContributor.class);

  static final String SOURCE_NAME = "connector-derived";
  static final String URL_KEY = "connector.database.url";
  static final String HOST_KEY = "connector.database.host";
  static final String PORT_KEY = "connector.database.port";

  public JdbcUrlPropertyContributor(ConfigurableEnvironment environment) {
    String url;
    try {
      url = environment.getProperty(URL_KEY);
    } catch (PlaceholderResolutionException e) {
      log.info("{} placeholder unresolved; skipping host/port derivation", URL_KEY);
      return;
    }
    if (url == null) {
      log.info("{} not set; skipping host/port derivation", URL_KEY);
      return;
    }
    Map<String, Object> derived = new HashMap<>();
    derived.put(HOST_KEY, JdbcUrlParser.host(url));
    derived.put(PORT_KEY, JdbcUrlParser.port(url));
    environment.getPropertySources().addLast(new MapPropertySource(SOURCE_NAME, derived));
    log.info(
        "Derived {}={} and {}={} from {}",
        HOST_KEY,
        derived.get(HOST_KEY),
        PORT_KEY,
        derived.get(PORT_KEY),
        URL_KEY);
  }
}
