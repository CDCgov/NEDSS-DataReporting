package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.postprocessingservice.repository.*;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@EnableScheduling
public class PostProcessingService {
    private static final Logger logger = LoggerFactory.getLogger(PostProcessingService.class);
    final Map<String, List<Long>> idCache = new ConcurrentHashMap<>();
    final Map<Long, String> idVals = new ConcurrentHashMap<>();

    private final PatientRepository patientRepository;
    private final ProviderRepository providerRepository;
    private final OrganizationRepository organizationRepository;
    private final InvestigationRepository investigationRepository;
    private final NotificationRepository notificationRepository;
    private final PageBuilderRepository pageBuilderRepository;

    static final String PAYLOAD = "payload";
    static final String INVESTIGATION = "investigation";
    static final String NOTIFICATIONS = "notifications";
    static final String PATIENT = "patient";
    static final String ORGANIZATION = "organization";
    static final String PROVIDER = "provider";
    static final String SP_EXECUTION_COMPLETED = "Stored proc execution completed";

    @KafkaListener(topics = {
            "${spring.kafka.topic.investigation}",
            "${spring.kafka.topic.organization}",
            "${spring.kafka.topic.patient}",
            "${spring.kafka.topic.provider}",
            "${spring.kafka.topic.notification}"
    })
    public void postProcessMessage(
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_KEY) String key,
            @Payload String payload) {
        Long id = extractIdFromMessage(topic, key, payload);
        if (id != null) {
            idCache.computeIfAbsent(topic, k -> new CopyOnWriteArrayList<>()).add(id);
        }
    }

    @Scheduled(fixedDelay = 5000)
    protected void processCachedIds() {
        for (Map.Entry<String, List<Long>> entry : idCache.entrySet()) {
            if(!entry.getValue().isEmpty()) {
                String keyTopic = entry.getKey();
                List<Long> ids = entry.getValue();
                idCache.put(keyTopic, new ArrayList<>());
                if(keyTopic.contains(ORGANIZATION)) {
                    processTopic(keyTopic, ids, organizationRepository::executeStoredProcForOrganizationIds, ORGANIZATION, "sp_nrt_organization_postprocessing");
                }
                if(keyTopic.contains(PROVIDER)) {
                    processTopic(keyTopic, ids, providerRepository::executeStoredProcForProviderIds, PROVIDER, "sp_nrt_provider_postprocessing");
                }
                if(keyTopic.contains(PATIENT)) {
                    processTopic(keyTopic, ids, patientRepository::executeStoredProcForPatientIds, PATIENT, "sp_nrt_patient_postprocessing");
                }
                if(keyTopic.contains(INVESTIGATION)) {
                    //List<InvestigationResult> res =
                    processTopic(keyTopic, ids, investigationRepository::executeStoredProcForPublicHealthCaseIds, INVESTIGATION,"sp_nrt_investigation_postprocessing");
                    ids.forEach(id -> {
                        if (idVals.containsKey(id)) {
                            processId(id, idVals.get(id), pageBuilderRepository::executeStoredProcForPageBuilder, "case answers","sp_page_builder_postprocessing");
                            idVals.remove(id);
                        }
                    });
                    processTopic(keyTopic, ids, investigationRepository::executeStoredProcForFPageCase, INVESTIGATION,"sp_f_page_case_postprocessing");
                }
                if(keyTopic.contains(NOTIFICATIONS)) {
                    processTopic(keyTopic, ids, notificationRepository::executeStoredProcForNotificationIds, NOTIFICATIONS, "sp_nrt_notification_postprocessing");
                }
            }
            else {
                logger.info("No ids to process from the topics.");
            }
        }
    }

    Long extractIdFromMessage(String topic, String messageKey, String payload) {
        Long id = null;
        try {
            ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
            JsonNode keyNode = objectMapper.readTree(messageKey);
            JsonNode payloadNode = objectMapper.readTree(payload);
            logger.info("Got this key payload: {} from the topic: {}", messageKey, topic);
            if(topic.contains(PATIENT)) {
                id = keyNode.get(PAYLOAD).get("patient_uid").asLong();

            }
            if(topic.contains(PROVIDER)) {
                id = keyNode.get(PAYLOAD).get("provider_uid").asLong();
            }
            if(topic.contains(ORGANIZATION)) {
                id = keyNode.get(PAYLOAD).get("organization_uid").asLong();
            }
            if(topic.contains(INVESTIGATION)) {
                id = keyNode.get(PAYLOAD).get("public_health_case_uid").asLong();
                JsonNode tblNode = payloadNode.get(PAYLOAD).get("rdb_table_name_list");
                if (tblNode != null && !tblNode.isNull()) {
                    idVals.put(id, tblNode.asText());
                }
            }
            if(topic.contains(NOTIFICATIONS)) {
                id = keyNode.get(PAYLOAD).get("notification_uid").asLong();
            }
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return id;
    }

    private void processTopic(String keyTopic, List<Long> ids, Consumer<String> repositoryMethod, String entity, String proc) {
        String idsString = prepareAndLog(keyTopic, ids, entity, proc);
        repositoryMethod.accept(idsString);
        logger.info(SP_EXECUTION_COMPLETED);
    }

    private <T> List<T> processTopic(String keyTopic, List<Long> ids, Function<String, List<T>> repositoryMethod, String entity, String proc) {
        String idsString = prepareAndLog(keyTopic, ids, entity, proc);
        List<T> result = repositoryMethod.apply(idsString);
        logger.info(SP_EXECUTION_COMPLETED);
        return result;
    }

    private String prepareAndLog(String keyTopic, List<Long> ids, String entity, String proc) {
        String idsString = ids.stream().map(String::valueOf).collect(Collectors.joining(","));
        logger.info("Processing the {} message topic: {}. Calling stored proc: {}('{}')", entity, keyTopic, proc, idsString);
        return idsString;
    }

    private void processId(Long id, String vals,BiConsumer<Long, String> repositoryMethod, String entity, String proc) {
        logger.info("Processing PHC ID for {}. Calling stored proc: {}({}, '{}')", entity, proc, id, vals);
        repositoryMethod.accept(id, vals);
        logger.info(SP_EXECUTION_COMPLETED);
    }
}
