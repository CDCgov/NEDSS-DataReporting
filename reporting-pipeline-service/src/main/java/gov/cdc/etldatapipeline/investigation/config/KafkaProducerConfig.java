package gov.cdc.etldatapipeline.investigation.config;

import java.util.HashMap;
import java.util.Map;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;

@Configuration("InvestigationKafkaProducerConfig")
public class KafkaProducerConfig {
  @Value("${spring.kafka.bootstrap-servers}")
  private String bootstrapServers = "";

  @Bean
  public ProducerFactory<String, String> investigationProducerFactory() {
    final Map<String, Object> config = new HashMap<>();
    config.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
    config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);

    return new DefaultKafkaProducerFactory<>(config);
  }

  @Bean(name = "investigationKafkaTemplate")
  public KafkaTemplate<String, String> investigationKafkaTemplate() {
    // set factory for both producer and consumer
    return new KafkaTemplate<>(investigationProducerFactory());
  }
}
