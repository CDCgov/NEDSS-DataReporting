package gov.cdc.nbs.report.pipeline.util;

public class NoDataException extends RuntimeException {
  public NoDataException(String message) {
    super(message);
  }

  public NoDataException(String message, Throwable cause) {
    super(message, cause);
  }
}
