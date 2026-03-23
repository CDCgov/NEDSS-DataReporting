package gov.cdc.etldatapipeline.reportinghydration;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Main entry point for the Reporting Hydration Service. This service is intended to consolidate
 * various reporting microservices into a single application to simplify the ETL data pipeline.
 */
@SpringBootApplication
@ComponentScan(basePackages = {"gov.cdc.etldatapipeline"})
@EnableJpaRepositories(basePackages = {"gov.cdc.etldatapipeline"})
@EntityScan(basePackages = {"gov.cdc.etldatapipeline"})
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
