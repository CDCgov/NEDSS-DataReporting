package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.InvestigationRepository;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.lang.reflect.Method;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;

class EventMetricCleanupTest {

  @Mock private PostProcRepository postProcRepository;
  @Mock private InvestigationRepository investigationRepository;
  @Mock private KafkaTemplate<String, String> kafkaTemplate;

  private PostProcessingService service;
  private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();
  private AutoCloseable closeable;

  @BeforeEach
  void setUp() {
    closeable = MockitoAnnotations.openMocks(this);
    ProcessDatamartData datamartProcessor =
        new ProcessDatamartData(
            kafkaTemplate,
            postProcRepository,
            investigationRepository,
            new CustomMetrics(new SimpleMeterRegistry()));
    service =
        spy(
            new PostProcessingService(
                postProcRepository,
                investigationRepository,
                datamartProcessor,
                new CustomMetrics(new SimpleMeterRegistry())));
    service.initMetrics();
    datamartProcessor.initMetrics();
    service.setInvestigationTopic("dummy_investigation");
    service.setServiceEnable(true);

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
  void eventMetricCleanup_invokesRepository() {
    service.eventMetricCleanup();

    verify(postProcRepository, times(1)).executeEventMetricCleanup();
  }

  @Test
  void eventMetricCleanup_logsCompletion() {
    service.eventMetricCleanup();

    boolean completionLogged =
        listAppender.list.stream()
            .anyMatch(
                e -> e.getFormattedMessage().contains("sp_event_metric_cleanup_postprocessing"));
    assertTrue(
        completionLogged, "Expected completion log for sp_event_metric_cleanup_postprocessing");
  }

  @Test
  void eventMetricCleanup_isScheduledWithCorrectCronProperty() throws NoSuchMethodException {
    Method method = PostProcessingService.class.getDeclaredMethod("eventMetricCleanup");
    Scheduled scheduled = method.getAnnotation(Scheduled.class);

    assertNotNull(scheduled, "eventMetricCleanup must be annotated with @Scheduled");
    assertEquals(
        "${service.schedule.event-metric-cleanup}",
        scheduled.cron(),
        "cron must reference the event-metric-cleanup property");
  }

  @Test
  void eventMetricCleanup_propagatesRepositoryException() {
    doThrow(new RuntimeException("proc failed"))
        .when(postProcRepository)
        .executeEventMetricCleanup();

    org.junit.jupiter.api.Assertions.assertThrows(
        RuntimeException.class, () -> service.eventMetricCleanup());
  }
}
