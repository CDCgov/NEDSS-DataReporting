package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doAnswer;

import gov.cdc.nbs.report.pipeline.postprocessing.repository.InvestigationRepository;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.util.Collections;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

/**
 * Concurrency regression test for the id-cache snapshot/clear race in {@link
 * PostProcessingService}.
 *
 * <p>{@code idCache} (and its siblings {@code cdCache}/{@code pbCache}/{@code obsCache}/{@code
 * sumCache}/{@code dmCache}) is drained on a schedule by copying each queue's contents and then
 * clearing the whole map, both under {@code cacheLock}. Before this fix, producers (a Kafka
 * listener thread, or a direct-write caller like {@code PersonService} via {@link
 * PostProcessingService#enqueue(String, Long)}) added to those queues without taking {@code
 * cacheLock}. If an add landed between the drain's snapshot copy and its {@code clear()}, the map
 * entry backing that queue was dropped from under it — the id was not delayed to the next cycle, it
 * was lost permanently, since a later {@code computeIfAbsent} call creates a brand-new queue rather
 * than reusing the orphaned one.
 *
 * <p>This fires many concurrent producers against a tight drain loop and asserts every enqueued id
 * is eventually seen by the postprocessing stored procedure call exactly once. Against the
 * unsynchronized producer side this test is flaky-to-failing (ids go missing); with producer adds
 * synchronized on {@code cacheLock} it passes deterministically.
 */
class PostProcessingServiceCacheConcurrencyTest {

  @Mock private PostProcRepository postProcRepositoryMock;
  @Mock private InvestigationRepository investigationRepositoryMock;
  @Mock private KafkaTemplate<String, String> kafkaTemplate;

  private PostProcessingService postProcessingService;
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
    postProcessingService.setMaxRetries(0);
    postProcessingService.initMetrics();
    postProcessingService.setServiceEnable(true);
  }

  @AfterEach
  void tearDown() throws Exception {
    closeable.close();
  }

  @Test
  void concurrentEnqueueDuringDrainLosesNoIds() throws InterruptedException {
    final String topic = "dummy_patient";
    final int producerThreads = 12;
    final int idsPerThread = 200;
    final int totalIds = producerThreads * idsPerThread;

    Set<Long> observedIds = ConcurrentHashMap.newKeySet();
    doAnswer(
            invocation -> {
              String idsCsv = invocation.getArgument(0);
              for (String id : idsCsv.split(",")) {
                if (!id.isBlank()) {
                  observedIds.add(Long.valueOf(id));
                }
              }
              return Collections.emptyList();
            })
        .when(postProcRepositoryMock)
        .executeStoredProcForPatientIds(anyString());

    AtomicBoolean producing = new AtomicBoolean(true);

    // Drain thread: hammers processCachedIds() continuously -- far more often than the real
    // @Scheduled cycle would -- to maximize the odds of hitting the snapshot/clear race window.
    Thread drainThread =
        new Thread(
            () -> {
              while (producing.get()) {
                postProcessingService.processCachedIds();
              }
            });
    drainThread.start();

    ExecutorService producers = Executors.newFixedThreadPool(producerThreads);
    CountDownLatch done = new CountDownLatch(producerThreads);
    try {
      for (int t = 0; t < producerThreads; t++) {
        final int threadIndex = t;
        producers.submit(
            () -> {
              try {
                for (int i = 0; i < idsPerThread; i++) {
                  long id = (long) threadIndex * idsPerThread + i;
                  postProcessingService.enqueue(topic, id);
                }
              } finally {
                done.countDown();
              }
            });
      }
      assertTrue(done.await(30, TimeUnit.SECONDS), "producer threads did not finish in time");
    } finally {
      producers.shutdownNow();
    }

    producing.set(false);
    drainThread.join(TimeUnit.SECONDS.toMillis(10));

    // Final drain to catch anything enqueued right at the end of the producer run.
    postProcessingService.processCachedIds();

    assertEquals(
        totalIds,
        observedIds.size(),
        () ->
            "expected all "
                + totalIds
                + " enqueued ids to be observed by the postprocessing call, but only saw "
                + observedIds.size()
                + " -- ids are being silently dropped by a producer/drain race");
  }
}
