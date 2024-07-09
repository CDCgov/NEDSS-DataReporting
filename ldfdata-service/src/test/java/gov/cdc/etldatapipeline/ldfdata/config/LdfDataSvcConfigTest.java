package gov.cdc.etldatapipeline.ldfdata.config;

import org.apache.kafka.streams.StreamsConfig;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.ConfigDataApplicationContextInitializer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.util.Properties;

@ExtendWith(SpringExtension.class)
@ContextConfiguration(initializers = ConfigDataApplicationContextInitializer.class)
@EnableConfigurationProperties(value = KafkaConfig.class)
@ActiveProfiles("test")
public class LdfDataSvcConfigTest {

    @Autowired
    private KafkaConfig kafkaConfig;

    @Autowired
    private KafkaStreamsConfig kafkaStreamsConfig;

    @Test
    void testBindingYMLConfigFile_SetsAllFields() {
        Assertions.assertEquals("nbs_state_defined_field_data", kafkaConfig.getLdfInputTopicName());
        Assertions.assertEquals("nrt_ldf_data", kafkaConfig.getLdfReportingOutputTopicName());

        Properties props = kafkaStreamsConfig.kStreamsConfigs().asProperties();
        Assertions.assertEquals("ldfdata-reporting-consumer-app", props.get(StreamsConfig.APPLICATION_ID_CONFIG));
        Assertions.assertEquals("localhost:9092", props.get(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG));
    }

    @Configuration
    static class TestConfig {
        @Bean
        public KafkaConfig kafkaConfig() {
            return new KafkaConfig();
        }

        @Bean
        public KafkaStreamsConfig kafkaStreamsConfig() {
            return new KafkaStreamsConfig();
        }
    }
}
