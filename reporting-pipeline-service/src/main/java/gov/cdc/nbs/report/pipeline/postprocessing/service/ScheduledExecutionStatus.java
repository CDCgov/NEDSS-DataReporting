package gov.cdc.nbs.report.pipeline.postprocessing.service;

import gov.cdc.nbs.report.pipeline.util.DataProcessingException;

enum ScheduledExecutionStatus {
  COMPLETED(1),
  SKIPPED(-2),
  FAILED(-1);

  private final int returnCode;

  ScheduledExecutionStatus(int returnCode) {
    this.returnCode = returnCode;
  }

  static ScheduledExecutionStatus fromReturnCode(Integer returnCode) {
    if (returnCode == null) {
      throw new DataProcessingException("Cleanup procedure did not return an execution status");
    }
    for (ScheduledExecutionStatus status : values()) {
      if (status.returnCode == returnCode) {
        return status;
      }
    }
    throw new DataProcessingException("Unexpected cleanup procedure return code: " + returnCode);
  }
}
