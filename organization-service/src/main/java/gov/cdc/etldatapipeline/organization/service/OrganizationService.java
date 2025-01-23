package gov.cdc.etldatapipeline.organization.service;

import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationSp;
import gov.cdc.etldatapipeline.organization.model.dto.place.Place;
import gov.cdc.etldatapipeline.organization.model.dto.place.PlaceTele;
import gov.cdc.etldatapipeline.organization.repository.OrgRepository;
import gov.cdc.etldatapipeline.organization.repository.PlaceRepository;
import gov.cdc.etldatapipeline.organization.transformer.DataTransformers;
import gov.cdc.etldatapipeline.organization.transformer.OrganizationType;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.common.errors.SerializationException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.retrytopic.DltStrategy;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.retry.annotation.Backoff;
import org.springframework.stereotype.Service;
import org.springframework.util.ObjectUtils;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.errorMessage;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractUid;

@Service
@Slf4j
@Setter @RequiredArgsConstructor
public class OrganizationService {
    @Value("${spring.kafka.input.topic-name}")
    private String orgTopic;

    @Value("${spring.kafka.input.topic-name-place}")
    private String placeTopic;

    @Value("${spring.kafka.output.organization.topic-name-elastic}")
    private String orgElasticSearchTopic;

    @Value("${spring.kafka.output.organization.topic-name-reporting}")
    private String orgReportingOutputTopic;

    @Value("${spring.kafka.output.place.topic-name}")
    private String placeReportingOutputTopic;

    @Value("${spring.kafka.output.place.topic-name-tele}")
    private String teleOutputTopic;

    private final OrgRepository orgRepository;
    private final PlaceRepository placeRepository;
    private final DataTransformers transformer;
    private final KafkaTemplate<String, String> kafkaTemplate;

    private static String topicDebugLog = "Received {} with id: {} from topic: {}";

    @RetryableTopic(
            attempts = "${spring.kafka.consumer.max-retry}",
            autoCreateTopics = "false",
            dltStrategy = DltStrategy.FAIL_ON_ERROR,
            retryTopicSuffix = "${spring.kafka.dlq.retry-suffix}",
            dltTopicSuffix = "${spring.kafka.dlq.dlq-suffix}",
            // retry topic name, such as topic-retry-1, topic-retry-2, etc
            topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
            // time to wait before attempting to retry
            backoff = @Backoff(delay = 1000, multiplier = 2.0),
            exclude = {
                    SerializationException.class,
                    DeserializationException.class,
                    RuntimeException.class,
                    NoDataException.class
            }
    )
    @KafkaListener(
            topics = {
                    "${spring.kafka.input.topic-name}",
                    "${spring.kafka.input.topic-name-place}"
            }
    )
    public void processMessage(String message,
                               @Header(KafkaHeaders.RECEIVED_TOPIC) String topic) {
        if (topic.equals(orgTopic)) {
            processOrganization(message, topic);
        } else if (topic.equals(placeTopic)) {
            processPlace(message, topic);
        }
    }

    private void processOrganization(String message, String topic) {
        String organizationUid = "";
        try {
            final String orgUid = organizationUid = extractUid(message,"organization_uid");
            log.info(topicDebugLog, "Organization", organizationUid, topic);
            Set<OrganizationSp> organizations = orgRepository.computeAllOrganizations(organizationUid);

            if (!organizations.isEmpty()) {
                organizations.forEach(org -> {
                    String reportingKey = transformer.buildOrganizationKey(org);
                    String reportingData = transformer.processData(org, OrganizationType.ORGANIZATION_REPORTING);
                    kafkaTemplate.send(orgReportingOutputTopic, reportingKey, reportingData);
                    log.info("Organization data (uid={}) sent to {}", orgUid, orgReportingOutputTopic);
                    log.debug("Organization Reporting: {}", reportingData);

                    String elasticKey = transformer.buildOrganizationKey(org);
                    String elasticData = transformer.processData(org, OrganizationType.ORGANIZATION_ELASTIC_SEARCH);
                    kafkaTemplate.send(orgElasticSearchTopic, elasticKey, elasticData);
                    log.info("Organization data (uid={}) sent to {}", orgUid, orgElasticSearchTopic);
                    log.debug("Organization Elastic: {}", elasticData!= null ? elasticData : "");
                });
            } else {
                throw new EntityNotFoundException("Unable to find Organization with id: " + organizationUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new RuntimeException(errorMessage("Organization", organizationUid, e), e);
        }
    }

    private void processPlace(String message, String topic) {
        String placeUid = "";
        try {
            placeUid = extractUid(message,"place_uid");
            log.info(topicDebugLog, "Place", placeUid, topic);
            Optional<List<Place>> placeData = placeRepository.computeAllPlaces(placeUid);

            if (placeData.isPresent() && !placeData.get().isEmpty()) {
                placeData.get().forEach(place -> {
                    processPlaceTele(place);

                    String jsonKey = transformer.buildPlaceKey(place);
                    String jsonValue = transformer.processData(place);
                    kafkaTemplate.send(placeReportingOutputTopic, jsonKey, jsonValue);
                    log.info("Place data (uid={}) sent to {}", place.getPlaceUid(), placeReportingOutputTopic);
                });
            } else {
                throw new EntityNotFoundException("Unable to find Place data for id(s): " + placeUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new RuntimeException(errorMessage("Place", placeUid, e), e);
        }
    }

    private void processPlaceTele(Place place) {
        try {
            // Tombstone message to delete previous place tele data for specified place uid
            kafkaTemplate.send(teleOutputTopic, transformer.buildPlaceKey(place), null);

            List<PlaceTele> teleData = transformer.buildPlaceTele(place.getPlaceTele());

            if (ObjectUtils.isEmpty(teleData)) {
                throw new IllegalArgumentException("PlaceTele array is null.");
            }

            teleData.forEach(tele -> {
                String jsonKey = transformer.buildPlaceTeleKey(tele);
                String jsonValue = transformer.processData(tele);
                kafkaTemplate.send(teleOutputTopic, jsonKey, jsonValue);
                log.info("Place Tele data (uid={}) sent to {}", tele.getPlaceTeleLocatorUid(), teleOutputTopic);
            });
        } catch (IllegalArgumentException ex) {
            log.info(ex.getMessage());
        } catch (Exception e) {
            log.error("Error processing Place Tele JSON array from Place data: {}", e.getMessage());
        }
    }
}