package gov.cdc.etldatapipeline.organization.config;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.kafka.ConfluentKafkaContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.utility.DockerImageName;

import java.time.Duration;

class KafkaProducerConfigTest {
    private static KafkaProducerConfig kafkaProducerConfig;
    private static DockerImageName image = DockerImageName.parse("confluentinc/cp-kafka:8.0.4");

    @Container
    private static ConfluentKafkaContainer kafkaContainer = new ConfluentKafkaContainer(image);

    @BeforeAll
    static void setUp() {
        kafkaContainer.start();
        kafkaProducerConfig = new KafkaProducerConfig();
    }

    @AfterAll
    static void tearDown() {
        kafkaContainer.stop();
    }

    @Test
    void producerFactory_configValid() {

        // Act
        var target = kafkaProducerConfig.producerFactory();

        // Assert
        Assertions.assertNotNull(target);
    }

    @Test
    void kafkaTemplate_configValid() {

        // Act
        var target = kafkaProducerConfig.kafkaTemplate();

        // Assert
        Assertions.assertNotNull(target);
    }
}