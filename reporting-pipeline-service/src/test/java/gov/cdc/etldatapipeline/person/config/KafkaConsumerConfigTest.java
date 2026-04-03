package gov.cdc.etldatapipeline.person.config;

import gov.cdc.etldatapipeline.reportingpipeline.util.TestUtils;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.kafka.ConfluentKafkaContainer;
import org.testcontainers.utility.DockerImageName;

class KafkaConsumerConfigTest {
  private static KafkaConsumerConfig kafkaConsumerConfig;
  private static final DockerImageName image = TestUtils.getComposeImageName("kafka");

  @Container
  private static final ConfluentKafkaContainer kafkaContainer = new ConfluentKafkaContainer(image);

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
  void personKafkaListenerContainerFactory_ConfigurationIsValid() {

    // Act
    ConcurrentKafkaListenerContainerFactory<String, String> kafkaListenerContainerFactory =
        kafkaConsumerConfig.personKafkaListenerContainerFactory();

    // Assert
    Assertions.assertNotNull(kafkaListenerContainerFactory);
  }
}
