package gov.cdc.nbs.report.pipeline;

import gov.cdc.nbs.report.pipeline.connector.ConnectorProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

/**
 * Main entry point for the Reporting Pipeline Service. This service is intended to consolidate
 * various reporting microservices into a single application to simplify the ETL data pipeline.
 */
@SpringBootApplication
@EnableConfigurationProperties(ConnectorProperties.class)
public class ReportingPipelineServiceApplication {

  /**
   * Starts the Reporting Pipeline Service application.
   *
   * @param args command-line arguments
   */
  public static void main(String[] args) {
    SpringApplication.run(ReportingPipelineServiceApplication.class, args);
  }
}
