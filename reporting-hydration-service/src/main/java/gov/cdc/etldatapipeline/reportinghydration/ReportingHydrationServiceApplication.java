package gov.cdc.etldatapipeline.reportinghydration;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main entry point for the Reporting Hydration Service. This service is intended to consolidate
 * various reporting microservices into a single application to simplify the ETL data pipeline.
 */
@SpringBootApplication
public class ReportingHydrationServiceApplication {

  /**
   * Starts the Reporting Hydration Service application.
   *
   * @param args command-line arguments
   */
  public static void main(String[] args) {
    SpringApplication.run(ReportingHydrationServiceApplication.class, args);
  }
}
