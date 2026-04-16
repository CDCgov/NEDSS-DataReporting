package gov.cdc.nbs.report.pipeline.observation.service.observation;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.errorMessage;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractUid;

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

  private final String observationTopicOutputReporting;
  private final String observationTopic;

  private final ModelMapper modelMapper = new ModelMapper();
  private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

  private final CustomMetrics metrics;
  private Counter msgProcessed;
  private Counter msgSuccess;
  private Counter msgFailure;

  public ObservationProcessor(
      final CustomMetrics metrics,
      final ObservationRepository observationRepository,
      @Qualifier("observationKafkaTemplate") final KafkaTemplate<String, String> kafkaTemplate,
      @Value("${spring.kafka.topics.nrt.observation}") final String observationTopicOutputReporting,
      @Value("${spring.kafka.topics.nbs.observation}") final String observationTopic,
      final NrtObservationWriter nrtWriter) {
    this.metrics = metrics;
    this.observationRepository = observationRepository;
    this.kafkaTemplate = kafkaTemplate;
    this.observationTopicOutputReporting = observationTopicOutputReporting;
    this.observationTopic = observationTopic;
    this.nrtWriter = nrtWriter;

    String[] tags = {"service", "observation-reporting"};

    msgProcessed = metrics.counter("obs_msg_processed", tags);
    msgSuccess = metrics.counter("obs_msg_success", tags);
    msgFailure = metrics.counter("obs_msg_failure", tags);
  }

  public void process(
      String value,
      long batchId,
      boolean isFromObservationTopic,
      String actRelationshipSourceActUid) {
    msgProcessed.increment();

    metrics.recordTime(
        "obs_msg_processing_seconds",
        () -> {
          String observationUid = "";
          try {
            // Get the relevant observation_uid
            observationUid =
                isFromObservationTopic
                    ? extractUid(value, "observation_uid")
                    : actRelationshipSourceActUid;

            ObservationKey observationKey = new ObservationKey(Long.valueOf(observationUid));

            logger.info(
                "Received Observation with id: {} from topic: {}",
                observationUid,
                observationTopic);

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

            // Insert parsed data into nrt_ database
            nrtWriter.persist(parsed);

            // Send to reporting object to nrt_observation kafka topic
            pushKeyValuePairToKafka(
                observationKey, reportingModel, observationTopicOutputReporting);
            logger.info(
                "Observation data (uid={}) sent to {}",
                observationUid,
                observationTopicOutputReporting);

            msgSuccess.increment();

          } catch (EntityNotFoundException ex) {
            msgFailure.increment();
            throw new NoDataException(ex.getMessage(), ex);

          } catch (Exception e) {
            msgFailure.increment();
            throw new DataProcessingException(errorMessage("Observation", observationUid, e), e);
          }
        },
        "service",
        "observation-reporting");
  }

  private void pushKeyValuePairToKafka(
      ObservationKey observationKey, Object model, String topicName) {
    String jsonKey = jsonGenerator.generateStringJson(observationKey);
    String jsonValue = jsonGenerator.generateStringJson(model);
    kafkaTemplate.send(topicName, jsonKey, jsonValue);
  }
}
