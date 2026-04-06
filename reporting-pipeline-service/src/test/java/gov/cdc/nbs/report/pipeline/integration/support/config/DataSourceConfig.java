package gov.cdc.nbs.report.pipeline.integration.support.config;

import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.simple.JdbcClient;

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
}
