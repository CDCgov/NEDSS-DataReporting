package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import gov.cdc.nbs.report.pipeline.util.DataProcessingException;
import org.junit.jupiter.api.Test;

class ScheduledExecutionStatusTest {

  @Test
  void mapsExplicitCompletionSkipAndFailureReturnCodes() {
    assertEquals(ScheduledExecutionStatus.COMPLETED, ScheduledExecutionStatus.fromReturnCode(1));
    assertEquals(ScheduledExecutionStatus.SKIPPED, ScheduledExecutionStatus.fromReturnCode(-2));
    assertEquals(ScheduledExecutionStatus.FAILED, ScheduledExecutionStatus.fromReturnCode(-1));
  }

  @Test
  void rejectsZeroAndMissingOrUnexpectedReturnCodes() {
    assertThrows(DataProcessingException.class, () -> ScheduledExecutionStatus.fromReturnCode(0));
    assertThrows(
        DataProcessingException.class, () -> ScheduledExecutionStatus.fromReturnCode(null));
    assertThrows(DataProcessingException.class, () -> ScheduledExecutionStatus.fromReturnCode(2));
  }
}
