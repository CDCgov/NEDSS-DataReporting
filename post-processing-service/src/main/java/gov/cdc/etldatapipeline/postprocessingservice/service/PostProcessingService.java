package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.postprocessingservice.repository.*;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.Datamart;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.apache.kafka.common.errors.SerializationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.retrytopic.DltStrategy;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.retry.annotation.Backoff;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.*;
import java.util.Map.Entry;
import java.util.concurrent.*;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.*;

@Service
@RequiredArgsConstructor
@Setter
@EnableScheduling
public class PostProcessingService {
    private static final Logger logger = LoggerFactory.getLogger(PostProcessingService.class);

    // cache to store ids from nrt topics that needs to be processed for loading dims and facts
    // a map of nrt topic name and its associated ids
    final Map<String, Queue<Long>> idCache = new ConcurrentHashMap<>();

    // cache to store PHC ids from for specific case types to run summary and aggregate reports
    // a map of case type (sum/agg) and its associated ids
    final Map<String, Queue<Long>> sumCache = new ConcurrentHashMap<>();

    // cache to store ids and additional information specific to those IDs like page case information
    // a map of ids (phc_ids as of now) and a comma seperated string of information
    final Map<Long, String> idVals = new ConcurrentHashMap<>();

    // cache to store ids that needs to be processed for datamarts
    // a map of datamart names and the needed ids
    final Map<String, Map<String, Queue<Long>>> dmCache = new ConcurrentHashMap<>();

    private static int nProc = Runtime.getRuntime().availableProcessors();
    private final ExecutorService dynDmExecutor = Executors.newFixedThreadPool(nProc, new CustomizableThreadFactory("dynDm-"));

    private final PostProcRepository postProcRepository;
    private final InvestigationRepository investigationRepository;

    private final ProcessDatamartData datamartProcessor;

    static final String PAYLOAD = "payload";
    static final String SP_EXECUTION_COMPLETED = "Stored proc execution completed: {}";
    static final String PROCESSING_MESSAGE_TOPIC_LOG_MSG = "Processing {} message topic. Calling stored proc: {} '{}'";
    static final String MULTIID = "MultiId_Datamart";

    static final String MORB_REPORT = "MorbReport";
    static final String LAB_REPORT = "LabReport";
    static final String LAB_REPORT_MORB = "LabReportMorb";

    static final String CASE_TYPE_SUM = "Summary";
    static final String CASE_TYPE_AGG = "Aggregate";
    static final String ACT_TYPE_SUM = "SummaryNotification";

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
    private final Object cacheLock = new Object();

    @Value("${spring.kafka.topic.investigation}")
    private String investigationTopic;

    @Value("${featureFlag.morb-report-dm-enable}")
    private boolean morbReportDmEnable;

    @Value("${featureFlag.inv-summary-dm-enable}")
    private boolean invSummaryDmEnable;

    @Value("${featureFlag.summary-report-enable}")
    private boolean summaryReportEnable;

    @Value("${featureFlag.aggregate-report-enable}")
    private boolean aggregateReportEnable;

    @Value("${featureFlag.d-tb-hiv-enable}")
    private boolean dTbHivEnable;

    @Value("${featureFlag.dyn-dm-enable}")
    private boolean dynDmEnable;


    @RetryableTopic(
            attempts = "${spring.kafka.consumer.max-retry}", 
            autoCreateTopics = "false", 
            dltStrategy = DltStrategy.FAIL_ON_ERROR, 
            retryTopicSuffix = "${spring.kafka.dlq.retry-suffix}", 
            dltTopicSuffix = "${spring.kafka.dlq.dlq-suffix}",
            // retry topic name, such as topic-retry-1, topic-retry-2, etc
            topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
            // time to wait before attempting to retry
            backoff = @Backoff(delay = 1000, multiplier = 2.0), exclude = {
                    SerializationException.class,
                    DeserializationException.class,
                    RuntimeException.class
            })
    @KafkaListener(topics = {
            "${spring.kafka.topic.investigation}",
            "${spring.kafka.topic.organization}",
            "${spring.kafka.topic.patient}",
            "${spring.kafka.topic.provider}",
            "${spring.kafka.topic.notification}",
            "${spring.kafka.topic.case_management}",
            "${spring.kafka.topic.interview}",
            "${spring.kafka.topic.ldf_data}",
            "${spring.kafka.topic.observation}",
            "${spring.kafka.topic.place}",
            "${spring.kafka.topic.auth_user}",
            "${spring.kafka.topic.contact_record}",
            "${spring.kafka.topic.treatment}",
            "${spring.kafka.topic.vaccination}"
    })
    /**
     * Processes a message from a Kafka topic. This method is the entry point for handling messages
     * from Kafka topics.
     *
     * @param topic The name of the Kafka topic from which the message was received.
     * @param key The key of the Kafka message, typically used for partitioning.
     * @param value The value of the Kafka message, which contains the payload to be processed.
     *
     * Steps:
     * 1. Identify the entity type based on the topic.
     * 2. Extract relevant IDs or data from the message payload.
     * 3. Cache the extracted IDs for further processing in idCache and data in idVals.
     */
    public void postProcessMessage(
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_KEY) String key,
            @Payload String payload) {

        Long id = extractIdFromMessage(topic, key);
        idCache.computeIfAbsent(topic, k -> new ConcurrentLinkedQueue<>()).add(id);
        Optional<String> val = Optional.ofNullable(extractValFromMessage(id, topic, payload));
        val.ifPresent(v -> idVals.put(id, v));
    }

    /**
     * Extract id from the kafka message key
     * @param topic
     * @param messageKey
     * @return id or uid
     */
    private Long extractIdFromMessage(String topic, String messageKey) {
        try {
            logger.info("Got this key payload: {} from the topic: {}", messageKey, topic);
            JsonNode keyNode = objectMapper.readTree(messageKey);

            Entity entity = getEntityByTopic(topic);
            if (Objects.isNull(keyNode.get(PAYLOAD).get(entity.getUidName()))) {
                throw new NoSuchElementException(
                        "The '" + entity.getUidName() + "' value is missing in the '" + topic + "' message payload.");
            }
            return keyNode.get(PAYLOAD).get(entity.getUidName()).asLong();
        } catch (Exception e) {
            String msg = "Error processing '" + topic + "'  message: " + e.getMessage();
            throw new DataProcessingException(msg, e);
        }
    }
    /**
     * Extracts relevant value from the kafka message payload
     * @param uid
     * @param topic
     * @param payload
     * @return String
     */
    private String extractValFromMessage(Long uid, String topic, String payload) {
        try {
            JsonNode payloadNode = objectMapper.readTree(payload).get(PAYLOAD);
            if (topic.endsWith(INVESTIGATION.getEntityName())) {
                extractSummaryCase(uid, payloadNode.path("case_type_cd").asText());

                JsonNode tblNode = payloadNode.path("rdb_table_name_list");
                if (!tblNode.isMissingNode() && !tblNode.isNull()) {
                    return tblNode.asText();
                }
            } else if (topic.endsWith(NOTIFICATION.getEntityName())) {
                String actTypeCd = payloadNode.path("act_type_cd").asText();
                Long phcUid = payloadNode.get(INVESTIGATION.getUidName()).asLong();
                extractSummaryCase(phcUid, actTypeCd);
            } else if (topic.endsWith(OBSERVATION.getEntityName())) {
                String domainCd = payloadNode.path("obs_domain_cd_st_1").asText();
                String ctrlCd = Optional
                        .ofNullable(payloadNode.get("ctrl_cd_display_form"))
                        .filter(node -> !node.isNull()).map(JsonNode::asText).orElse(null);

                if (MORB_REPORT.equals(ctrlCd)) {
                    if ("Order".equals(domainCd)) {
                        return ctrlCd;
                    }
                } else if (assertMatches(ctrlCd, LAB_REPORT, LAB_REPORT_MORB, null) &&
                        assertMatches(domainCd, "Order", "Result", "R_Order", "R_Result", "I_Order", "I_Result",
                                "Order_rslt")) {
                    return LAB_REPORT;
                }
            }
        } catch (Exception ex) {
            logger.warn("Error processing ID values for the {} message: {}", topic, ex.getMessage());
        }
        return null;
    }

    private void extractSummaryCase(Long uid, String caseType) {
        if (ACT_TYPE_SUM.equals(caseType) || "S".equals(caseType)) {
            sumCache.computeIfAbsent(CASE_TYPE_SUM, k -> new ConcurrentLinkedQueue<>()).add(uid);
        }
        if (ACT_TYPE_SUM.equals(caseType) || "A".equals(caseType)) {
            sumCache.computeIfAbsent(CASE_TYPE_AGG, k -> new ConcurrentLinkedQueue<>()).add(uid);
        }
    }

    @RetryableTopic(
        attempts = "${spring.kafka.consumer.max-retry}", 
        autoCreateTopics = "false", 
        dltStrategy = DltStrategy.FAIL_ON_ERROR, 
        retryTopicSuffix = "${spring.kafka.dlq.retry-suffix}", 
        dltTopicSuffix = "${spring.kafka.dlq.dlq-suffix}", 
        topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE, 
        backoff = @Backoff(delay = 1000, multiplier = 2.0), exclude = {
            SerializationException.class,
            DeserializationException.class,
            RuntimeException.class
    })
    @KafkaListener(topics = { "${spring.kafka.topic.datamart}" })
    public void postProcessDatamart(
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Payload String payload) {
        try {
            logger.info("Got this payload: {} from the topic: {}", payload, topic);
            JsonNode payloadNode = objectMapper.readTree(payload);

            Datamart dmData = objectMapper.readValue(payloadNode.get(PAYLOAD).toString(), Datamart.class);
            if (Objects.isNull(dmData)) {
                logger.info("For payload: {} DataMart object is null. Skipping further processing", payloadNode);
                return;
            }
            if (Objects.isNull(dmData.getPublicHealthCaseUid()) || Objects.isNull(dmData.getPatientUid())) {
                logger.info(
                        "For payload: {} DataMart Public Health Case/Patient Id is null. Skipping further processing",
                        payloadNode);
                return;
            }
            if (Objects.isNull(dmData.getDatamart())) {
                logger.info("For payload: {} DataMart value is null. Skipping further processing", payloadNode);
                return;
            }

            Map<String, Queue<Long>> dmMap = dmCache.computeIfAbsent(dmData.getDatamart(), k -> new ConcurrentHashMap<>());
            dmMap.computeIfAbsent(INVESTIGATION.getEntityName(),
                    k -> new ConcurrentLinkedQueue<>()).add(dmData.getPublicHealthCaseUid());

        } catch (Exception e) {
            String msg = "Error processing datamart message: " + e.getMessage();
            throw new DataProcessingException(msg, e);
        }
    }

    /**
     * Processes all cached IDs for various entities (e.g., investigations, notifications, organizations)
     * and executes the appropriate stored procedures for each entity type. This method triggers at fixed intervals and
     * consolidates the processing of IDs collected from multiple Kafka messages.
     *
     * Steps:
     * 1. Iterate through cached IDs grouped by entity type.
     * 2. Execute the corresponding stored procedure for each entity type.
     * 3. Log the execution status for debugging and monitoring purposes.
     * 4. Store the entity name and ids for later if it is needed for data marts (both direct dependent and also for multi-id data marts)
     * 5. Process event metric and summary data marts
     * 6. Send the event message to the kafka topic that handles data mart events for building other data marts
     */
    @Scheduled(fixedDelayString = "${service.fixed-delay.cached-ids}")
    protected void processCachedIds() {

        // Making cache snapshot preventing out-of-sequence ids processing
        // creates a deep copy of idCache into idCacheSnapshot and idVals into idValsSnapshot
        final Map<String, List<Long>> idCacheSnapshot;
        final Map<Long, String> idValsSnapshot;

        synchronized (cacheLock) {
            idCacheSnapshot = idCache.entrySet().stream()
                    .collect(Collectors.toMap(Map.Entry::getKey, entry -> new ArrayList<>(entry.getValue())));
            idCache.clear();

            idValsSnapshot = idVals.entrySet().stream()
                    .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
            idVals.clear();
        }

        if (!idCacheSnapshot.isEmpty()) {
            // sorting idCacheSnapshot so that entities with higher priority is processed first
            List<Entry<String, List<Long>>> sortedEntries = idCacheSnapshot.entrySet().stream()
                    .sorted(Comparator.comparingInt(entry -> getEntityByTopic(entry.getKey()).getPriority())).toList();

            // list to store details of datamarts and the associated ids that needs to be hydrated downstream
            List<DatamartData> dmData = new ArrayList<>();

            // Isolated temporary map to accumulate entity ID collections by entity type.
            // After processing, it is merged into dmCache for multi-ID datamarts invocation.
            // Isolation prevents conflicts from concurrent modifications by the datamart processing thread.
            Map<String, Queue<Long>> newDmMulti = new ConcurrentHashMap<>();

            for (Entry<String, List<Long>> entry : sortedEntries) {
                String keyTopic = entry.getKey();
                List<Long> ids = entry.getValue();

                logger.info("Processing {} id(s) from topic: {}", ids.size(), keyTopic);

                Entity entity = getEntityByTopic(keyTopic);
                switch (entity) {
                    case ORGANIZATION:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForOrganizationIds);
                        newDmMulti.computeIfAbsent(ORGANIZATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case PROVIDER:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForProviderIds);
                        newDmMulti.computeIfAbsent(PROVIDER.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case PATIENT:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForPatientIds);
                        newDmMulti.computeIfAbsent(PATIENT.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case AUTH_USER:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForUserProfile);
                        break;
                    case D_PLACE:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDPlace);
                        break;
                    case INVESTIGATION:
                        dmData = processInvestigation(keyTopic, entity, ids, idValsSnapshot);
                        newDmMulti.computeIfAbsent(INVESTIGATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case CONTACT:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDContactRecord);
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForFContactRecordCase,
                                "sp_f_contact_record_case_postprocessing");
                        newDmMulti.computeIfAbsent(CONTACT.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case NOTIFICATION:
                        List<DatamartData> dmDataN = processTopic(keyTopic, entity, ids,
                                investigationRepository::executeStoredProcForNotificationIds);
                        dmData = Stream.concat(dmData.stream(), dmDataN.stream()).distinct().toList();
                        newDmMulti.computeIfAbsent(NOTIFICATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case TREATMENT:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForTreatment);
                        break;
                    case CASE_MANAGEMENT:
                        processTopic(keyTopic, entity, ids, investigationRepository::executeStoredProcForCaseManagement);
                        processTopic(keyTopic, entity, ids, investigationRepository::executeStoredProcForFStdPageCase,
                                "sp_f_std_page_case_postprocessing");
                        break;
                    case INTERVIEW:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDInterview);
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForFInterviewCase,
                                "sp_f_interview_case_postprocessing");
                        break;
                    case LDF_DATA:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForLdfIds);
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForLdfDimensionalData);
                        break;
                    case OBSERVATION:
                        dmData = processObservation(idValsSnapshot, keyTopic, entity, dmData);
                        newDmMulti.computeIfAbsent(OBSERVATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case VACCINATION:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDVaccination);
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForFVaccination,
                                "sp_f_vaccination_postprocessing");
                        newDmMulti.computeIfAbsent(VACCINATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    default:
                        logger.warn("Unknown topic: {} cannot be processed", keyTopic);
                        break;
                }
            }
            // process METRIC_EVENT datamart since multiple datamarts depend on it
            processMetricEventDatamart(newDmMulti);
            processSummaryCases();
            datamartProcessor.process(dmData);

            // merge entity IDs collections from temporary map `newDmMulti` into main datamart cache
            synchronized (cacheLock) {
                Map<String, Queue<Long>> dmMulti = dmCache.computeIfAbsent(MULTIID, k -> new ConcurrentHashMap<>());
                newDmMulti.forEach((key, queue) ->
                        dmMulti.computeIfAbsent(key, k -> new ConcurrentLinkedQueue<>()).addAll(queue));
            }
        } else {
            logger.info("No ids to process from the topics.");
        }
    }

    private void processSummaryCases() {
        // Making cache snapshot preventing out-of-sequence ids processing
        final Set<Long> sumUids;
        final Set<Long> aggUids;

        synchronized (cacheLock) {
            sumUids = Optional.ofNullable(sumCache.get(CASE_TYPE_SUM))
                    .map(HashSet::new)
                    .orElse(new HashSet<>());
            aggUids = Optional.ofNullable(sumCache.get(CASE_TYPE_AGG))
                    .map(HashSet::new)
                    .orElse(new HashSet<>());
            sumCache.clear();
        }

        if (summaryReportEnable) {
            processTopic(investigationTopic, SUMMARY_REPORT_CASE, sumUids,
                    investigationRepository::executeStoredProcForSummaryReportCase);

            processTopic(investigationTopic, SR100_DATAMART, sumUids,
                    investigationRepository::executeStoredProcForSR100Datamart);
        }

        if (aggregateReportEnable) {
            processTopic(investigationTopic, AGGREGATE_REPORT_DATAMART, aggUids,
                    investigationRepository::executeStoredProcForAggregateReport);
        }
    }

    private List<DatamartData> processInvestigation(String keyTopic, Entity entity, List<Long> ids,
            Map<Long, String> idValsSnapshot) {
        List<DatamartData> dmData;
        dmData = processTopic(keyTopic, entity, ids,
                investigationRepository::executeStoredProcForPublicHealthCaseIds);

        ids.stream().filter(idValsSnapshot::containsKey)
                .forEach(id -> processTopic(keyTopic, CASE_ANSWERS, id, idValsSnapshot.get(id),
                        investigationRepository::executeStoredProcForPageBuilder));

        processTopic(keyTopic, F_PAGE_CASE, ids, investigationRepository::executeStoredProcForFPageCase);
        processTopic(keyTopic, CASE_COUNT, ids, investigationRepository::executeStoredProcForCaseCount);
        processTopic(keyTopic, D_TB_PAM, ids, investigationRepository::executeStoredProcForDTbPam);
        processTopic(keyTopic, D_ADDL_RISK, ids, investigationRepository::executeStoredProcForDAddlRisk);
        processTopic(keyTopic, D_DISEASE_SITE, ids, investigationRepository::executeStoredProcForDDiseaseSite);

        if(dTbHivEnable) {
            //TB
            processTopic(keyTopic, D_TB_HIV, ids, investigationRepository::executeStoredProcForDTbHiv);
            processTopic(keyTopic, D_GT_12_REAS, ids, investigationRepository::executeStoredProcForDGt12Reas);
            processTopic(keyTopic, D_MOVE_CNTRY, ids, investigationRepository::executeStoredProcForDMoveCntry);
            processTopic(keyTopic, D_MOVE_CNTY, ids, investigationRepository::executeStoredProcForDMoveCnty);
            processTopic(keyTopic, D_MOVE_STATE, ids, investigationRepository::executeStoredProcForDMoveState);
            processTopic(keyTopic, D_MOVED_WHERE, ids, investigationRepository::executeStoredProcForDMovedWhere);
            processTopic(keyTopic, D_HC_PROV_TY_3, ids, investigationRepository::executeStoredProcForDHcProvTy3);
            processTopic(keyTopic, D_OUT_OF_CNTRY, ids, investigationRepository::executeStoredProcForDOutOfCntry);
            processTopic(keyTopic, D_SMR_EXAM_TY, ids, investigationRepository::executeStoredProcForDSmrExamTy);
            processTopic(keyTopic, F_TB_PAM, ids, investigationRepository::executeStoredProcForFTbPam);
            processTopic(keyTopic, TB_PAM_LDF, ids, investigationRepository::executeStoredProcForTbPamLdf);
           
            //VAR
            processTopic(keyTopic, D_VAR_PAM, ids, investigationRepository::executeStoredProcForDVarPam);
            processTopic(keyTopic, D_RASH_LOC_GEN, ids, investigationRepository::executeStoredProcForDRashLocGen);
            processTopic(keyTopic, D_PCR_SOURCE, ids, investigationRepository::executeStoredProcForDPcrSource);
            processTopic(keyTopic, F_VAR_PAM, ids, investigationRepository::executeStoredProcForFVarPam);
            processTopic(keyTopic, VAR_PAM_LDF, ids, investigationRepository::executeStoredProcForVarPamLdf);
        }   
        
        return dmData;
    }

    private List<DatamartData> processObservation(Map<Long, String> idValsSnapshot, String keyTopic, Entity entity,
            List<DatamartData> dmData) {
        final List<Long> morbIds;
        final List<Long> labIds;
        synchronized (cacheLock) {
            morbIds = idValsSnapshot.entrySet().stream()
                    .filter(e -> e.getValue().equals(MORB_REPORT)).map(Entry::getKey).toList();
            labIds = idValsSnapshot.entrySet().stream()
                    .filter(e -> e.getValue().equals(LAB_REPORT)).map(Entry::getKey).toList();
        }

        if (!morbIds.isEmpty()) {
            List<DatamartData> dmDataM = processTopic(keyTopic, entity, morbIds,
                    postProcRepository::executeStoredProcForMorbReport, "sp_d_morbidity_report_postprocessing");
            dmData = Stream.concat(dmData.stream(), dmDataM.stream()).distinct().toList();
        }

        if (!labIds.isEmpty()) {
            processTopic(keyTopic, entity, labIds,
                    postProcRepository::executeStoredProcForLabTest, "sp_d_lab_test_postprocessing");

            List<DatamartData> dmDataL = processTopic(keyTopic, entity, labIds,
                    postProcRepository::executeStoredProcForLabTestResult, "sp_d_labtest_result_postprocessing");
            dmData = Stream.concat(dmData.stream(), dmDataL.stream()).distinct().toList();

            processTopic(keyTopic, entity, labIds,
                    postProcRepository::executeStoredProcForLab100Datamart, "sp_lab100_datamart_postprocessing");
            processTopic(keyTopic, entity, labIds,
                    postProcRepository::executeStoredProcForLab101Datamart, "sp_lab101_datamart_postprocessing");
        }
        return dmData;
    }

    /**
     * Processes cached IDs for datamarts by executing the appropriate stored procedures. This method triggers at fixed
     * intervals and handles the processing of data that needs to be loaded into specific datamarts.
     *
     * Steps:
     * 1. Iterate through cached IDs grouped by datamart type.
     * 2. Execute the corresponding stored procedure for each datamart type.
     * 3. Log the execution status for debugging and monitoring purposes.
     */
    @Scheduled(fixedDelayString = "${service.fixed-delay.datamart}")
    protected void processDatamartIds() {
        for (Map.Entry<String, Map<String, Queue<Long>>> entry : dmCache.entrySet()) {
            if (!entry.getValue().isEmpty()) {
                String dmType = entry.getKey();

                // skip multi ID processing here, it should after this processing
                if (MULTIID.equals(dmType)) {
                    continue;
                }

                Queue<Long> uids = entry.getValue().get(INVESTIGATION.getEntityName());
                dmCache.put(dmType, new ConcurrentHashMap<>());

                // list of phc uids are concatenated together with ',' to be passed as input for the stored procs
                String cases = uids.stream().map(String::valueOf).collect(Collectors.joining(","));

                // make sure the entity names for datamart enum values follows the same naming
                // as the enum itself
                switch (Entity.valueOf(dmType.toUpperCase())) {
                    case HEPATITIS_DATAMART:
                        executeDatamartProc(CASE_LAB_DATAMART,
                                investigationRepository::executeStoredProcForCaseLabDatamart, cases);
                        executeDatamartProc(HEPATITIS_DATAMART,
                                investigationRepository::executeStoredProcForHepDatamart, cases);
                        break;
                    case STD_HIV_DATAMART:
                        executeDatamartProc(STD_HIV_DATAMART,
                                investigationRepository::executeStoredProcForStdHIVDatamart, cases);
                        break;
                    case GENERIC_CASE:
                        executeDatamartProc(GENERIC_CASE,
                                investigationRepository::executeStoredProcForGenericCaseDatamart, cases);
                        break;
                    case CRS_CASE:
                        executeDatamartProc(CRS_CASE,
                                investigationRepository::executeStoredProcForCRSCaseDatamart, cases);
                        break;
                    case RUBELLA_CASE:
                        executeDatamartProc(RUBELLA_CASE,
                                investigationRepository::executeStoredProcForRubellaCaseDatamart, cases);
                        break;
                    case MEASLES_CASE:
                        executeDatamartProc(MEASLES_CASE,
                                investigationRepository::executeStoredProcForMeaslesCaseDatamart, cases);
                        break;
                    case CASE_LAB_DATAMART:
                        executeDatamartProc(CASE_LAB_DATAMART,
                                investigationRepository::executeStoredProcForCaseLabDatamart, cases);
                        break;
                    case BMIRD_CASE:
                        executeDatamartProc(BMIRD_CASE,
                                investigationRepository::executeStoredProcForBmirdCaseDatamart, cases);
                        executeDatamartProc(BMIRD_STREP_PNEUMO_DATAMART,
                                investigationRepository::executeStoredProcForBmirdStrepPneumoDatamart, cases);
                        break;
                    case HEPATITIS_CASE:
                        executeDatamartProc(HEPATITIS_CASE,
                                investigationRepository::executeStoredProcForHepatitisCaseDatamart, cases);
                        break;
                    case PERTUSSIS_CASE:
                        executeDatamartProc(PERTUSSIS_CASE,
                                investigationRepository::executeStoredProcForPertussisCaseDatamart, cases);
                        break;
                    case TB_DATAMART:
                        if(dTbHivEnable) {
                            executeDatamartProc(TB_DATAMART,
                                    investigationRepository::executeStoredProcForTbDatamart, cases);
                            
                            executeDatamartProc(TB_HIV_DATAMART,
                                    investigationRepository::executeStoredProcForTbHivDatamart, cases);
                        }
                        break;
                    case VAR_DATAMART:
                        if(dTbHivEnable) {
                            executeDatamartProc(VAR_DATAMART,
                                investigationRepository::executeStoredProcForVarDatamart, cases);
                        }
                        break;
                    default:
                        logger.info("No associated datamart processing logic found for the key: {} ", dmType);
                }
            } else {
                logger.info("No data to process from the datamart topics.");
            }
        }

        Optional.ofNullable(dmCache.get(MULTIID)).ifPresent(multi -> {
            dmCache.put(MULTIID, new ConcurrentHashMap<>());
            processMultiIdDatamart(multi);
        });
    }

    private void executeDatamartProc(Entity dmEntity, Consumer<String> repositoryMethod, String ids) {
        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmEntity.getEntityName(), dmEntity.getStoredProcedure(), ids);
        repositoryMethod.accept(ids);
        completeLog(dmEntity.getStoredProcedure());
    }

    private void processMetricEventDatamart(Map<String, Queue<Long>> dmMulti) {
        String invString = listToParameterString(dmMulti.get(INVESTIGATION.getEntityName()));
        String obsString = listToParameterString(dmMulti.get(OBSERVATION.getEntityName()));
        String notifString = listToParameterString(dmMulti.get(NOTIFICATION.getEntityName()));
        String ctrString = listToParameterString(dmMulti.get(CONTACT.getEntityName()));
        String vaxString = listToParameterString(dmMulti.get(VACCINATION.getEntityName()));

        int totalLengthEventMetric = invString.length() + obsString.length() + notifString.length()
                + ctrString.length() + vaxString.length();

        if (totalLengthEventMetric > 0) {
            postProcRepository.executeStoredProcForEventMetric(invString, obsString, notifString, ctrString, vaxString);
        } else {
            logger.info("No updates to EVENT_METRIC Datamart");
        }
    }

    /**
     * Processes cached IDs for multi-ID datamarts by executing the appropriate stored procedures.
     * @param dmMulti
     */
    private void processMultiIdDatamart(Map<String, Queue<Long>> dmMulti) {
        String invString = listToParameterString(dmMulti.get(INVESTIGATION.getEntityName()));
        String obsString = listToParameterString(dmMulti.get(OBSERVATION.getEntityName()));
        String notifString = listToParameterString(dmMulti.get(NOTIFICATION.getEntityName()));
        String patString = listToParameterString(dmMulti.get(PATIENT.getEntityName()));
        String provString = listToParameterString(dmMulti.get(PROVIDER.getEntityName()));
        String orgString = listToParameterString(dmMulti.get(ORGANIZATION.getEntityName()));

        int totalLengthHep100 = invString.length() + patString.length() + provString.length() + orgString.length();
        int totalLengthInvSummary = invString.length() + notifString.length() + obsString.length();
        int totalLengthMorbReportDM = obsString.length() + patString.length() + provString.length() + orgString.length() + invString.length();

        if (totalLengthHep100 > 0) {
            postProcRepository.executeStoredProcForHep100(invString, patString, provString, orgString);
        } else {
            logger.info("No updates to HEP100 Datamart");
        }

        if (totalLengthInvSummary > 0 && invSummaryDmEnable) {
            List<DatamartData> dmDataList; //reusing the same DTO class for Dynamic Marts
            dmDataList = postProcRepository.executeStoredProcForInvSummaryDatamart(invString, notifString, obsString);

            if(!dmDataList.isEmpty() && dynDmEnable) {

                Map<String, String> datamartPhcIdMap = dmDataList.stream()
                        .collect(Collectors.groupingBy(
                                DatamartData::getDatamart,
                                Collectors.mapping(
                                        dmData -> String.valueOf(dmData.getPublicHealthCaseUid()),
                                        Collectors.joining(",")
                                )
                        ));
                datamartPhcIdMap.forEach((datamart, phcIds) ->
                            CompletableFuture.runAsync(() -> postProcRepository.executeStoredProcForDynDatamart(datamart, phcIds), dynDmExecutor)
                                    .thenRun(() -> logger.info("Updates to Dynamic Datamart: {} ", datamart))
                );

            } else {
                logger.info("No updates to Dynamic Datamarts");
            }

        } else {
            logger.info("No updates to INV_SUMMARY Datamart");
        }

        if (totalLengthMorbReportDM > 0 && morbReportDmEnable) {
            postProcRepository.executeStoredProcForMorbidityReportDatamart(obsString, patString, provString, orgString, invString);
        } else {
            logger.info("No updates to MORBIDITY_REPORT_DATAMART");
        }
    }


    private String listToParameterString(Collection<Long> inputList) {
        return Optional.ofNullable(inputList)
                .map(list -> list.stream().map(String::valueOf).collect(Collectors.joining(",")))
                .orElse("");
    }

    @PreDestroy
    public void shutdown() {
        processCachedIds();
        processDatamartIds();
    }

    private boolean assertMatches(String value, String... vals) {
        return Arrays.asList(vals).contains(value);
    }

    /**
     * Retrieves the entity type (e.g., INVESTIGATION, NOTIFICATION, ORGANIZATION) based on the Kafka
     * topic name. This mapping is used to determine how to process the message and which stored
     * procedure to execute.
     *
     * @param topic The name of the Kafka topic (e.g., "dummy_investigation", "dummy_notification").
     * @return The corresponding entity type as an `Entity` enum value.
     *
     * Example:
     * If the topic is "dummy_investigation", the method will return `Entity.INVESTIGATION`.
     *
     * @throws IllegalArgumentException If the topic does not map to a known entity type.
     */
    private Entity getEntityByTopic(String topic) {
        return Arrays.stream(Entity.values())
                .filter(entity -> entity.getPriority() > 0)
                .filter(entity -> topic.endsWith(entity.getEntityName()))
                .findFirst()
                .orElse(UNKNOWN);
    }

    private void processTopic(String keyTopic, Entity entity, Collection<Long> ids, Consumer<String> repositoryMethod,
            String... names) {
        if (!ids.isEmpty()) {
            String spName = names.length > 0 ? names[0] : entity.getStoredProcedure();
            String idsString = prepareAndLog(keyTopic, ids, entity.getEntityName(), spName);
            repositoryMethod.accept(idsString);
            completeLog(spName);
        }
    }

    private <T> List<T> processTopic(String keyTopic, Entity entity, Collection<Long> ids,
            Function<String, List<T>> repositoryMethod, String... names) {
        String spName = names.length > 0 ? names[0] : entity.getStoredProcedure();
        String idsString = prepareAndLog(keyTopic, ids, entity.getEntityName(), spName);
        List<T> result = repositoryMethod.apply(idsString);
        completeLog(spName);
        return result;
    }

    private void processTopic(String keyTopic, Entity entity, Long id, String vals,
            BiConsumer<Long, String> repositoryMethod) {
        String name = entity.getEntityName();
        name = logger.isInfoEnabled() ? StringUtils.capitalize(name) : name;
        logger.info("Processing {} for topic: {}. Calling stored proc: {} '{}', '{}'", name, keyTopic,
                entity.getStoredProcedure(), id, vals);
        repositoryMethod.accept(id, vals);
        completeLog(entity.getStoredProcedure());
    }

    private String prepareAndLog(String keyTopic, Collection<Long> ids, String name, String spName) {
        String idsString = ids.stream().map(String::valueOf).collect(Collectors.joining(","));
        name = logger.isInfoEnabled() ? StringUtils.capitalize(name) : name;
        logger.info("Processing {} for topic: {}. Calling stored proc: {} '{}'", name, keyTopic,
                spName, idsString);
        return idsString;
    }

    private void completeLog(String sp) {
        logger.info(SP_EXECUTION_COMPLETED, sp);
    }

}