package gov.cdc.etldatapipeline.postprocessingservice.integration.kafkasink;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class KafkaSinkClient {

  private static final RestTemplate restTemplate = new RestTemplate();
  private static final String URL =
      "http://localhost:8083/connectors/Kafka-Connect-SqlServer-Sink/restart?includeTasks=true";

  public static void restartSinkConnector() {
    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);

    restTemplate.postForObject(URL, new HttpEntity<>(null, headers), String.class);
  }
}
