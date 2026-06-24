package gov.cdc.nbs.report.pipeline.seeding;

/** Raised when Kafka offsets cannot be read while determining seeding completeness. */
public class SeedingInspectionException extends RuntimeException {

  public SeedingInspectionException(String message, Throwable cause) {
    super(message, cause);
  }
}
