package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.nbs.report.pipeline.config.PostProcessingProperties;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.InvestigationRepository;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import gov.cdc.nbs.report.pipeline.util.DataProcessingException;
import gov.cdc.nbs.report.pipeline.util.kafka.RetryTopicResolver;
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

class Lab100CleanupTest {

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
            new PostProcessingProperties(0),
            new CustomMetrics(new SimpleMeterRegistry()));
    service =
        spy(
            new PostProcessingService(
                postProcRepository,
                investigationRepository,
                datamartProcessor,
                new RetryTopicResolver(),
                new PostProcessingProperties(0),
                new CustomMetrics(new SimpleMeterRegistry())));
    PostProcessingTestUtils.configureNrtTopics(service);
    service.initMetrics();
    datamartProcessor.initMetrics();
    service.setServiceEnable(true);
    when(postProcRepository.executeLab100Cleanup()).thenReturn(1);

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
  void lab100Cleanup_invokesRepository() {
    service.lab100Cleanup();

    verify(postProcRepository, times(1)).executeLab100Cleanup();
  }

  @Test
  void lab100Cleanup_logsCompletion() {
    service.lab100Cleanup();

    assertTrue(
        listAppender.list.stream()
            .anyMatch(
                e ->
                    e.getFormattedMessage()
                        .equals("Stored proc execution completed: sp_lab100_cleanup")));
  }

  @Test
  void lab100Cleanup_logsAlreadyRunningSkipWithoutCompletion() {
    when(postProcRepository.executeLab100Cleanup()).thenReturn(-2);

    service.lab100Cleanup();

    assertTrue(
        listAppender.list.stream()
            .anyMatch(
                e ->
                    e.getFormattedMessage()
                        .contains("Skipped sp_lab100_cleanup because it's already running")));
    assertTrue(
        listAppender.list.stream()
            .noneMatch(
                e ->
                    e.getFormattedMessage()
                        .contains("Stored proc execution completed: sp_lab100_cleanup")));
    verify(postProcRepository).executeLab100Cleanup();
  }

  @Test
  void lab100Cleanup_isScheduledWithCorrectCronProperty() throws NoSuchMethodException {
    Method method = PostProcessingService.class.getDeclaredMethod("lab100Cleanup");
    Scheduled scheduled = method.getAnnotation(Scheduled.class);

    assertNotNull(scheduled, "lab100Cleanup must be annotated with @Scheduled");
    assertEquals(
        "${service.schedule.lab100-cleanup}",
        scheduled.cron(),
        "cron must reference the lab100-cleanup property");
  }

  @Test
  void lab100Cleanup_throwsWhenProcedureReportsFailure() {
    when(postProcRepository.executeLab100Cleanup()).thenReturn(-1);

    assertThrows(DataProcessingException.class, () -> service.lab100Cleanup());
    verify(postProcRepository).executeLab100Cleanup();
  }

  @Test
  void lab100Cleanup_propagatesRepositoryException() {
    doThrow(new RuntimeException("proc failed")).when(postProcRepository).executeLab100Cleanup();

    assertThrows(RuntimeException.class, () -> service.lab100Cleanup());
    verify(postProcRepository).executeLab100Cleanup();
  }
}
