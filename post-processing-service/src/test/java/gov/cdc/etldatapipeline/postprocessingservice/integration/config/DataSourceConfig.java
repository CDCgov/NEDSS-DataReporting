package gov.cdc.etldatapipeline.postprocessingservice.integration.config;

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
    @ConfigurationProperties("spring.datasource.primary")
    public DataSourceProperties dataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean
    @Primary
    public DataSource dataSource(DataSourceProperties properties) {
        return properties
                .initializeDataSourceBuilder()
                .build();
    }

    @Bean
    @Primary
    public JdbcClient jdbcClient(DataSource dataSource) {
        return JdbcClient.create(dataSource);
    }

    // Testing specific datasource with db ownership
    @Bean("testProperties")
    @ConfigurationProperties("spring.datasource.test")
    public DataSourceProperties testDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean("testDataSource")
    public DataSource testDataSource(@Qualifier("testProperties") DataSourceProperties properties) {
        return properties
                .initializeDataSourceBuilder()
                .build();
    }

    @Bean("testClient")
    public JdbcClient testJdbcClient(@Qualifier("testDataSource") DataSource dataSource) {
        return JdbcClient.create(dataSource);
    }
}
