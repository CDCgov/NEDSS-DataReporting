package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.InvestigationRepository;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;

/**
 * Single-threaded correctness/contract tests for {@link PostProcessingService#enqueue(String,
 * Long)}. Concurrency behavior (producer/drain race safety) is covered separately in {@link
 * PostProcessingServiceCacheConcurrencyTest}.
 */
class PostProcessingServiceEnqueueTest {

  @Mock private PostProcRepository postProcRepositoryMock;
  @Mock private InvestigationRepository investigationRepositoryMock;
  @Mock private KafkaTemplate<String, String> kafkaTemplate;

  private PostProcessingService postProcessingService;
  private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
  private AutoCloseable closeable;

  @BeforeEach
  void setUp() {
    closeable = MockitoAnnotations.openMocks(this);
    ProcessDatamartData datamartProcessor =
        new ProcessDatamartData(
            kafkaTemplate,
            postProcRepositoryMock,
            investigationRepositoryMock,
            new CustomMetrics(new SimpleMeterRegistry()));
    datamartProcessor.initMetrics();

    postProcessingService =
        new PostProcessingService(
            postProcRepositoryMock,
            investigationRepositoryMock,
            datamartProcessor,
            new CustomMetrics(new SimpleMeterRegistry()));
    postProcessingService.initMetrics();
    postProcessingService.setServiceEnable(true);

    Logger logger = (Logger) LoggerFactory.getLogger(PostProcessingService.class);
    listAppender.start();
    logger.addAppender(listAppender);
  }

  @AfterEach
  void tearDown() throws Exception {
    Logger logger = (Logger) LoggerFactory.getLogger(PostProcessingService.class);
    logger.detachAppender(listAppender);
    closeable.close();
  }

  @Test
  void enqueueAddsIdToCache() {
    String topic = "dummy_patient";

    postProcessingService.enqueue(topic, 123L);

    assertTrue(postProcessingService.idCache.containsKey(topic));
    assertEquals(123L, postProcessingService.idCache.get(topic).element());
  }

  @Test
  void enqueueAccumulatesMultipleIdsUnderSameTopic() {
    String topic = "dummy_provider";

    postProcessingService.enqueue(topic, 1L);
    postProcessingService.enqueue(topic, 2L);
    postProcessingService.enqueue(topic, 3L);

    assertEquals(List.of(1L, 2L, 3L), new ArrayList<>(postProcessingService.idCache.get(topic)));
  }

  @Test
  void enqueueKeepsDifferentTopicsIsolated() {
    postProcessingService.enqueue("dummy_patient", 100L);
    postProcessingService.enqueue("dummy_provider", 200L);

    assertEquals(2, postProcessingService.idCache.size());
    assertEquals(100L, postProcessingService.idCache.get("dummy_patient").element());
    assertEquals(200L, postProcessingService.idCache.get("dummy_provider").element());
  }

  @Test
  void enqueuedPatientIdIsDrainedToPatientStoredProc() {
    when(postProcRepositoryMock.executeStoredProcForPatientIds(anyString()))
        .thenReturn(Collections.emptyList());

    postProcessingService.enqueue("dummy_patient", 555L);
    postProcessingService.processCachedIds();

    verify(postProcRepositoryMock).executeStoredProcForPatientIds("555");
    assertTrue(postProcessingService.idCache.isEmpty());
  }

  @Test
  void enqueuedProviderIdIsDrainedToProviderStoredProc() {
    when(postProcRepositoryMock.executeStoredProcForProviderIds(anyString()))
        .thenReturn(Collections.emptyList());

    postProcessingService.enqueue("dummy_provider", 777L);
    postProcessingService.processCachedIds();

    verify(postProcRepositoryMock).executeStoredProcForProviderIds("777");
    assertTrue(postProcessingService.idCache.isEmpty());
  }

  @Test
  void enqueuedAuthUserIdIsDrainedToUserProfileStoredProc() {
    when(postProcRepositoryMock.executeStoredProcForUserProfile(anyString()))
        .thenReturn(Collections.emptyList());

    postProcessingService.enqueue("dummy_auth_user", 999L);
    postProcessingService.processCachedIds();

    verify(postProcRepositoryMock).executeStoredProcForUserProfile("999");
    assertTrue(postProcessingService.idCache.isEmpty());
  }

  @Test
  void enqueueIgnoresServiceEnableFlag() {
    postProcessingService.setServiceEnable(false);

    postProcessingService.enqueue("dummy_patient", 42L);

    assertTrue(postProcessingService.idCache.containsKey("dummy_patient"));
  }

  @Test
  void enqueueRejectsNullUid() {
    assertThrows(
        NullPointerException.class, () -> postProcessingService.enqueue("dummy_patient", null));
  }

  @Test
  void enqueueRejectsNullTopic() {
    assertThrows(NullPointerException.class, () -> postProcessingService.enqueue(null, 1L));
  }

  @Test
  void enqueueOnUnrecognizedTopicIsSilentlyDroppedByDrainWithWarning() {
    String topic = "dummy_totally_unknown_entity";

    postProcessingService.enqueue(topic, 1234L);
    postProcessingService.processCachedIds();

    verifyNoInteractions(postProcRepositoryMock);
    assertTrue(postProcessingService.idCache.isEmpty());
    assertTrue(
        listAppender.list.stream().anyMatch(event -> event.getFormattedMessage().contains(topic)),
        "expected a warning log naming the unrecognized topic");
  }
}
