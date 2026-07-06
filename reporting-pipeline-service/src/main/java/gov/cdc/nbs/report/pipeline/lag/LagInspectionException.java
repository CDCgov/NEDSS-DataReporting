package gov.cdc.nbs.report.pipeline.lag;

/** Raised when Kafka offsets or record timestamps cannot be read while reporting lag. */
public class LagInspectionException extends RuntimeException {

  public LagInspectionException(String message, Throwable cause) {
    super(message, cause);
  }
}
