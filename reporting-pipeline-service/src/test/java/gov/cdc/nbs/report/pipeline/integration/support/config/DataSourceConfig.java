package gov.cdc.nbs.report.pipeline.integration.support.config;

import java.io.File;
import javax.sql.DataSource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.simple.JdbcClient;

@Slf4j
@Configuration
@Profile("test")
public class DataSourceConfig {
  // Standard RTR datasource with appropriate permissions
  @Bean
  @Primary
  @ConfigurationProperties("spring.datasource.default")
  public DataSourceProperties dataSourceProperties() {
    return new DataSourceProperties();
  }

  @Bean
  @Primary
  public DataSource dataSource(DataSourceProperties properties) {
    return properties.initializeDataSourceBuilder().build();
  }

  @Primary
  @Bean
  public JdbcClient jdbcClient(DataSource dataSource) {
    return JdbcClient.create(dataSource);
  }

  // Testing specific datasource with db ownership
  @Bean("adminProperties")
  @ConfigurationProperties("spring.datasource.admin")
  public DataSourceProperties testDataSourceProperties() {
    return new DataSourceProperties();
  }

  @Bean("adminDataSource")
  public DataSource testDataSource(@Qualifier("adminProperties") DataSourceProperties properties) {
    return properties.initializeDataSourceBuilder().build();
  }

  @Bean("adminClient")
  public JdbcClient testJdbcClient(@Qualifier("adminDataSource") DataSource dataSource) {
    return JdbcClient.create(dataSource);
  }

  @Bean("customComposeFile")
  public File customFunctionalCompose(Environment env) {
    String filePath = env.getProperty("spring.testcontainers.customComposeFile");

    if (filePath == null || filePath.isBlank()) {
      return null;
    }

    // 1. Try the path as provided (Relative to current working directory)
    File directFile = new File(filePath);
    if (directFile.exists()) {
      log.debug("Found compose file at primary path: {}", directFile.getAbsolutePath());
      return directFile;
    }

    // 2. Try the path relative to the parent directory
    File parentDirFile = new File("..", filePath);
    if (parentDirFile.exists()) {
      log.debug("Found compose file in parent directory: {}", parentDirFile.getAbsolutePath());
      return parentDirFile;
    }

    log.warn("Custom compose file '{}' not found in current or parent directory.", filePath);
    return null;
  }
}
