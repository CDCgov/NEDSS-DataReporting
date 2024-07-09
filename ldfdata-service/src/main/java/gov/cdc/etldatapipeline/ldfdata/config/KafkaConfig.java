package gov.cdc.etldatapipeline.ldfdata.config;

import lombok.Getter;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
@ConfigurationProperties
@Getter
public class KafkaConfig {

    @Value("${spring.kafka.stream.input.ldfdata.topic-name}")
    public String ldfInputTopicName;

    @Value("${spring.kafka.stream.output.ldfdata.topic-name-reporting}")
    public String ldfReportingOutputTopicName;

    @Bean
    public NewTopic createLdfInputTopic() {
        return TopicBuilder.name(ldfInputTopicName).build();
    }

    @Bean
    public NewTopic createLdfReportingOutputTopic() {
        return TopicBuilder.name(ldfReportingOutputTopicName).build();
    }
}