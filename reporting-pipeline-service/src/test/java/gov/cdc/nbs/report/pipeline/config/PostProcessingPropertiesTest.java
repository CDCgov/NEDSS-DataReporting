package gov.cdc.nbs.report.pipeline.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.autoconfigure.context.ConfigurationPropertiesAutoConfiguration;
import org.springframework.boot.autoconfigure.validation.ValidationAutoConfiguration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

class PostProcessingPropertiesTest {

  private final ApplicationContextRunner contextRunner =
      new ApplicationContextRunner()
          .withConfiguration(
              AutoConfigurations.of(
                  ConfigurationPropertiesAutoConfiguration.class,
                  ValidationAutoConfiguration.class))
          .withUserConfiguration(TestConfiguration.class)
          .withPropertyValues(
              "service.post-processing.max-batch-size=${POST_PROCESSING_MAX_BATCH_SIZE:1000}");

  @Test
  void bindsConfiguredMaxBatchSize() {
    contextRunner
        .withPropertyValues("service.post-processing.max-batch-size=25")
        .run(
            context -> {
              PostProcessingProperties properties = context.getBean(PostProcessingProperties.class);
              assertEquals(25, properties.maxBatchSize());
            });
  }

  @Test
  void usesDefaultMaxBatchSize() {
    contextRunner.run(
        context -> {
          PostProcessingProperties properties = context.getBean(PostProcessingProperties.class);
          assertEquals(1000, properties.maxBatchSize());
        });
  }

  @Test
  void bindsEnvironmentOverride() {
    contextRunner
        .withSystemProperties("POST_PROCESSING_MAX_BATCH_SIZE=25")
        .run(
            context -> {
              PostProcessingProperties properties = context.getBean(PostProcessingProperties.class);
              assertEquals(25, properties.maxBatchSize());
            });
  }

  @Test
  void allowsZeroToDisableBatching() {
    contextRunner
        .withPropertyValues("service.post-processing.max-batch-size=0")
        .run(
            context -> {
              PostProcessingProperties properties = context.getBean(PostProcessingProperties.class);
              assertEquals(0, properties.maxBatchSize());
            });
  }

  @Test
  void rejectsNegativeMaxBatchSize() {
    contextRunner
        .withPropertyValues("service.post-processing.max-batch-size=-1")
        .run(
            context -> {
              assertNotNull(context.getStartupFailure());
            });
  }

  @EnableConfigurationProperties(PostProcessingProperties.class)
  private static class TestConfiguration {}
}
