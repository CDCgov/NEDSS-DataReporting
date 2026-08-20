package gov.cdc.nbs.report.pipeline.person.service;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

interface CdcProcessingDelay {
  void await(String entity, String uid, String operation);
}

@Component
@Profile("!test")
class NoOpCdcProcessingDelay implements CdcProcessingDelay {
  @Override
  public void await(String entity, String uid, String operation) {
    // Intentionally blank: CDC delay behavior is available only in the test profile.
  }
}
