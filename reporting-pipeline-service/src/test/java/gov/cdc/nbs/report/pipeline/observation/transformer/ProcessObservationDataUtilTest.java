package gov.cdc.nbs.report.pipeline.observation.transformer;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.kafka.core.KafkaTemplate;

class ProcessObservationDataUtilTest {

  @SuppressWarnings("unchecked")
  private final ProcessObservationDataUtil util =
      new ProcessObservationDataUtil(Mockito.mock(KafkaTemplate.class));

  // APP-735: a NULL obs_domain_cd_st_1 must be treated as "not a valid domain" and rejected with a
  // clean IllegalArgumentException (the same path a non-matching value like 'I_Order' takes), NOT a
  // NullPointerException from the bound `value::equals` reference. Both are caught upstream, but
  // the
  // NPE was logged at ERROR and was a persistent diagnostic red herring.
  @Test
  void nullDomain_isRejectedAsIllegalArgument_notNpe() {
    assertThrows(IllegalArgumentException.class, () -> util.assertDomainCdMatches(null, "Order"));
  }

  @Test
  void nonMatchingDomain_isRejectedAsIllegalArgument() {
    assertThrows(
        IllegalArgumentException.class, () -> util.assertDomainCdMatches("I_Order", "Order"));
  }

  @Test
  void matchingDomain_passes() {
    assertDoesNotThrow(() -> util.assertDomainCdMatches("Order", "Order", "Result"));
  }
}
