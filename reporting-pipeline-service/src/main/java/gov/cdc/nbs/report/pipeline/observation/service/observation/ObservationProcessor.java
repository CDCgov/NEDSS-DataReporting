package gov.cdc.nbs.report.pipeline.observation.service.observation;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.errorMessage;

import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.Observation;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationKey;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationReporting;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ParsedObservation;
import gov.cdc.nbs.report.pipeline.observation.repository.ObservationRepository;
import gov.cdc.nbs.report.pipeline.observation.transformer.ObservationParser;
import io.micrometer.core.instrument.Counter;
import jakarta.persistence.EntityNotFoundException;
import java.util.Optional;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

/** Handles the processing of Observation data */
@Component
public class ObservationProcessor {
  private static final Logger logger = LoggerFactory.getLogger(ObservationProcessor.class);

  private final ObservationRepository observationRepository;
  private final KafkaTemplate<String, String> kafkaTemplate;
  private final NrtObservationWriter nrtWriter;

  private final String nrtObservationTopic;

  private final ModelMapper modelMapper = new ModelMapper();
  private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

  private final CustomMetrics metrics;
  private static final String[] TAGS = {"service", "observation-reporting"};
  private Counter msgProcessed;
  private Counter msgSuccess;
  private Counter msgFailure;

  public ObservationProcessor(
      final CustomMetrics metrics,
      final ObservationRepository observationRepository,
      @Qualifier("observationKafkaTemplate") final KafkaTemplate<String, String> kafkaTemplate,
      @Value("${spring.kafka.topics.nrt.observation}") final String nrtObservationTopic,
      final NrtObservationWriter nrtWriter) {
    this.metrics = metrics;
    this.observationRepository = observationRepository;
    this.kafkaTemplate = kafkaTemplate;
    this.nrtObservationTopic = nrtObservationTopic;
    this.nrtWriter = nrtWriter;

    msgProcessed = metrics.counter("obs_msg_processed", TAGS);
    msgSuccess = metrics.counter("obs_msg_success", TAGS);
    msgFailure = metrics.counter("obs_msg_failure", TAGS);
  }

  public void process(final long batchId, final String observationUid) {
    msgProcessed.increment();

    metrics.recordTime(
        "obs_msg_processing_seconds",
        () -> {
          try {
            logger.info("Received Observation with id: {}", observationUid);

            // Query NBS_ODSE for observation data
            Optional<Observation> observationData =
                observationRepository.computeObservations(observationUid);

            // Ensure data is returned
            if (observationData.isEmpty()) {
              throw new EntityNotFoundException(
                  "Unable to find Observation with id: " + observationUid);
            }

            // Convert Entity to reporting object that will be sent to nrt_observation
            ObservationReporting reportingModel =
                modelMapper.map(observationData.get(), ObservationReporting.class);

            // Parse all fields from incoming mesage
            ParsedObservation parsed = ObservationParser.parse(observationData.get(), batchId);

            // Push parsed fields into reporting object
            modelMapper.map(parsed.transformed(), reportingModel);

            // Insert parsed data into nrt_observation_* database tables
            nrtWriter.persist(parsed);

            // Send reporting object to nrt_observation kafka topic
            ObservationKey observationKey = new ObservationKey(Long.valueOf(observationUid));
            pushKeyValuePairToKafka(observationKey, reportingModel, nrtObservationTopic);
            logger.info(
                "Observation data (uid={}) sent to {}", observationUid, nrtObservationTopic);

            msgSuccess.increment();

          } catch (EntityNotFoundException ex) {
            msgFailure.increment();
            throw new NoDataException(ex.getMessage(), ex);

          } catch (Exception e) {
            msgFailure.increment();
            throw new DataProcessingException(errorMessage("Observation", observationUid, e), e);
          }
        },
        TAGS);
  }

  private void pushKeyValuePairToKafka(
      ObservationKey observationKey, Object model, String topicName) {
    String jsonKey = jsonGenerator.generateStringJson(observationKey);
    String jsonValue = jsonGenerator.generateStringJson(model);
    kafkaTemplate.send(topicName, jsonKey, jsonValue);
  }
}
