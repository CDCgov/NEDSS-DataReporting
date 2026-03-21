package gov.cdc.etldatapipeline.person.config;

import gov.cdc.etldatapipeline.reportinghydration.util.TestUtils;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.kafka.ConfluentKafkaContainer;
import org.testcontainers.utility.DockerImageName;

class KafkaProducerConfigTest {
  private static KafkaProducerConfig kafkaProducerConfig;
  private static final DockerImageName image = TestUtils.getComposeImageName("kafka");

  @Container
  private static final ConfluentKafkaContainer kafkaContainer = new ConfluentKafkaContainer(image);

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
    var target = kafkaProducerConfig.personProducerFactory();

    // Assert
    Assertions.assertNotNull(target);
  }

  @Test
  void kafkaTemplate_configValid() {

    // Act
    var target = kafkaProducerConfig.personKafkaTemplate();

    // Assert
    Assertions.assertNotNull(target);
  }
}
