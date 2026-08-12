package gov.cdc.nbs.report.pipeline.integration.unit;

import static org.junit.jupiter.api.Assertions.assertEquals;

import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class CleanupStatusRepositoryTest extends UnitTest {

  @Autowired private PostProcRepository postProcRepository;

  @Test
  void returnsLegacySuccessForEventMetricCleanup() {
    assertEquals(0, postProcRepository.executeEventMetricCleanup());
  }

  @Test
  void returnsLegacySuccessForLab100Cleanup() {
    assertEquals(0, postProcRepository.executeLab100Cleanup());
  }
}
