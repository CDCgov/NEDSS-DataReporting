package gov.cdc.nbs.report.pipeline;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main entry point for the Reporting Pipeline Service. This service is intended to consolidate
 * various reporting microservices into a single application to simplify the ETL data pipeline.
 */
@SpringBootApplication
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
