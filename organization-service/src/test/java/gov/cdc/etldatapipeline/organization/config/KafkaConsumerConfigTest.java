package gov.cdc.etldatapipeline.organization.config;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.testcontainers.kafka.ConfluentKafkaContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.utility.DockerImageName;

import java.time.Duration;

class KafkaConsumerConfigTest {
    private static KafkaConsumerConfig kafkaConsumerConfig;
    private static DockerImageName image = DockerImageName.parse("confluentinc/cp-kafka:8.0.4");

    @Container
    private static ConfluentKafkaContainer kafkaContainer = new ConfluentKafkaContainer(image);

    @BeforeAll
    static void setUp() {
        kafkaContainer.start();
        kafkaConsumerConfig = new KafkaConsumerConfig();
    }

    @AfterAll
    static void tearDown() {
        kafkaContainer.stop();
    }

    @Test
    void kafkaListenerContainerFactory_ConfigurationIsValid() {

        // Act
        ConcurrentKafkaListenerContainerFactory<String, String> kafkaListenerContainerFactory = kafkaConsumerConfig
                .kafkaListenerContainerFactory();

        // Assert
        Assertions.assertNotNull(kafkaListenerContainerFactory);
    }

}