package gov.cdc.nbs.report.pipeline.observation.config;

import java.util.HashMap;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.*;

@Slf4j
@EnableKafka
@Configuration("observationKafkaConsumerConfig")
public class KafkaConsumerConfig {
  @Value("${spring.kafka.group-id}")
  private String groupId = "";

  @Value("${spring.kafka.bootstrap-servers}")
  private String bootstrapServers = "";

  // Higher value for more intensive operation, also increase latency
  // default is 30000, equivalent to 5 min
  @Value("${spring.kafka.consumer.maxPollIntervalMs}")
  private String maxPollInterval = "";

  @Value("${spring.kafka.consumer.maxPollRecs}")
  private String maxPollRecords = "";

  @Value("${spring.kafka.consumer.auto-offset-reset}")
  private String autoOffsetReset = "";

  @Bean
  public ConsumerFactory<String, String> observationConsumerFactory() {
    final Map<String, Object> config = new HashMap<>();
    config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    config.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
    config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, autoOffsetReset);
    config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    config.put(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG, maxPollInterval);
    config.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, maxPollRecords);
    return new DefaultKafkaConsumerFactory<>(config);
  }

  // Config for kafka listener aka consumer
  @Bean
  public ConcurrentKafkaListenerContainerFactory<String, String>
      observationKafkaListenerContainerFactory() {
    ConcurrentKafkaListenerContainerFactory<String, String> factory =
        new ConcurrentKafkaListenerContainerFactory<>();
    factory.setConsumerFactory(observationConsumerFactory());
    return factory;
  }
}
