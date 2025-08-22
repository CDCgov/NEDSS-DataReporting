package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.google.common.base.Strings;
import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.InvestigationRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.PostProcRepository;
import gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.model.BackfillData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.model.DatamartData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.model.dto.Datamart;
import gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.model.dto.DatamartKey;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.Collections;
import java.util.concurrent.*;
import java.util.function.BiFunction;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.UnaryOperator;
import java.util.stream.Collectors;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.errorMessage;
import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.*;

@Component
@RequiredArgsConstructor @Setter
public class ProcessDatamartData {
    private static final Logger logger = LoggerFactory.getLogger(ProcessDatamartData.class);

    // unique per instance, randomly assigned once
    static final int INSTANCE_ID = new Random(System.identityHashCode(ProcessDatamartData.class))
            .nextInt(1 << 10); // 10-bit random ID

    private static int nProc = Runtime.getRuntime().availableProcessors();
    private final ExecutorService dynDmExecutor = Executors.newFixedThreadPool(nProc, new CustomizableThreadFactory("dynDm-"));

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final PostProcRepository procRepository;
    private final InvestigationRepository invRepository;

    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();
    private final ModelMapper modelMapper = new ModelMapper();
    private final Object cacheLock = new Object();

    // set of caches for retrying failed datamarts/IDs and tracking retry attempts
    final Map<Long, Map<String, Map<String, Queue<Long>>>> retryCache = new ConcurrentHashMap<>();
    final Map<Long, String> errorMap = new ConcurrentHashMap<>();
    final Map<Long, Integer> retryAttempts = new ConcurrentHashMap<>();
    final Map<Long, Integer> backfillAttempts = new ConcurrentHashMap<>();

    @Value("${service.max-retries}")
    private int maxRetries;

    static final String MULTI_ID_DATAMART = "MultiId_Datamart";
    static final String SP_EXECUTION_COMPLETED = "Stored proc execution completed: {}";
    static final String PROCESSING_MESSAGE_TOPIC_LOG_MSG = "Processing {} message topic. Calling stored proc: {} '{}'";
    static final String PROCESSING_MESSAGE_TOPIC_LOG_MSG_2 = "Processing {} message topic. Calling stored proc: {} '{}', '{}";

    static final String STATUS_READY = "READY";
    static final String STATUS_COMPLETE = "COMPLETE";
    static final String STATUS_SUSPENDED = "SUSPENDED";

    @Value("${spring.kafka.topic.datamart}")
    public String datamartTopic;

    public void process(List<DatamartData> data) {
        if (Objects.nonNull(data) && !data.isEmpty()) {
            data = reduce(data);
            try {
                for (DatamartData datamartData : data) {

                    if (Strings.isNullOrEmpty(datamartData.getDatamart())
                            || Objects.isNull(datamartData.getPatientUid())) {
                        continue; // skipping now for empty datamart or unprocessed patients
                    }

                    Datamart dmart = modelMapper.map(datamartData, Datamart.class);
                    DatamartKey dmKey = new DatamartKey();
                    dmKey.setEntityUid(datamartData.getPublicHealthCaseUid());
                    String jsonKey = jsonGenerator.generateStringJson(dmKey);
                    String jsonMessage = jsonGenerator.generateStringJson(dmart);

                    kafkaTemplate.send(datamartTopic, jsonKey, jsonMessage);
                    logger.info("Datamart data: uid={}, datamart={} sent to {} topic", dmart.getPublicHealthCaseUid(), dmart.getDatamart(), datamartTopic);
                }
            } catch (Exception e) {
                String msg = "Error processing Datamart JSON array from datamart data: " + e.getMessage();
                throw new DataProcessingException(msg, e);
            }
        }
    }

    private List<DatamartData> reduce(List<DatamartData> dmData) {
        List<Long> hepUidsAlreadyInDmData =
                dmData.stream().filter(Objects::nonNull)
                        .filter(d -> HEPATITIS_DATAMART.getEntityName().equals(d.getDatamart()))
                        .map(DatamartData::getPublicHealthCaseUid).toList();

        return dmData.stream().filter(Objects::nonNull)
                .filter(d -> {
                    boolean isCaseLab = CASE_LAB_DATAMART.getEntityName().equals(d.getDatamart());
                    boolean hasHepAlready = hepUidsAlreadyInDmData.contains(d.getPublicHealthCaseUid());
                    // If it's Case_Lab_Datamart AND we already have that UID in Hepatitis_Datamart -> exclude
                    return !(isCaseLab && hasHepAlready);
                }).toList();
    }

    protected boolean processDmCache(Map<String, Map<String, List<Long>>> dmCache, Long batchId) {
        List<Long> ldfUids = new ArrayList<>();
        boolean failed = false;

        for (Map.Entry<String, Map<String, List<Long>>> entry : dmCache.entrySet()) {
            String dmKey = entry.getKey();
            Map<String, List<Long>> dmValues = entry.getValue();

            List<Long> uids = getUids(dmValues, INVESTIGATION);

            if (failed) {
                updateRetryCache(batchId, dmKey, dmValues);
            } else {
                if (batchId != null) {
                    logger.info("Retrying {} id(s) from datamart topic: {}, attempt #{} for batch id: {}",
                            uids.size(), dmKey, retryAttempts.getOrDefault(batchId, 0) + 1, batchId);
                }

                try {
                    processDatamart(dmKey, dmValues, ldfUids);
                } catch (Exception e) {
                    logger.error(errorMessage(dmKey, listToParameterString(uids), new Exception(e.getClass().getSimpleName())));
                    failed = true;
                    batchId = buildRetryCache(batchId, dmKey, dmValues, e);
                }
            }
        }

        failed = processLdfVaccinePreventDm(batchId, ldfUids, failed);

        if (dmCache.containsKey(MULTI_ID_DATAMART)) {
            failed = processMultiIdDatamart(batchId, dmCache.get(MULTI_ID_DATAMART), failed);
        }

        return !failed;
    }

    /**
     * Processes a datamart entry and calls the appropriate stored procedures.
     *
     * <p>The {@code dmKey} can include a primary datamart (e.g., {@code HEPATITIS_DATAMART}) and an optional
     * LDF (Legacy Data Form) type separated by a comma.
     * The {@code idMap} pairs entity names with the IDs to be processed.
     *
     * @param dmKey   the datamart key, optionally with an LDF type after a comma
     * @param idMap   a map of entity names to lists of IDs
     * @param ldfUids a list to store case IDs for LDF-related datamarts
     */
    private void processDatamart(String dmKey, Map<String, List<Long>> idMap, List<Long> ldfUids) {

        if (MULTI_ID_DATAMART.equals(dmKey)) {
            return;
        }

        List<Long> uids = getUids(idMap, INVESTIGATION);
        List<Long> patUids = getUids(idMap, PATIENT);
        List<Long> obsUids = getUids(idMap, OBSERVATION);

        // for complex value (e.g. "GENERIC_CASE,LDF_GENERIC") the key should be parsed
        String[] dmTypes = dmKey.split(",");
        String dmType =  dmTypes[0];
        String ldfType = dmTypes.length > 1 ? dmTypes[1] : "UNKNOWN" ;

        if (ldfType.equalsIgnoreCase(LDF_VACCINE_PREVENT_DISEASES.getEntityName())) {
            ldfUids.addAll(uids);
        }

        // list of phc uids concatenated together with ',' to be passed as input for the stored procs
        // for COVID_VAC_DATAMART it actually contains vaccination uids
        String cases = listToParameterString(uids);

        // make sure the entity names for datamart enum values follows the same naming
        // as the enum itself
        switch (Entity.valueOf(dmType.toUpperCase())) {
            case HEPATITIS_DATAMART:
                executeDmProc(CASE_LAB_DATAMART,
                        invRepository::executeStoredProcForCaseLabDatamart, cases, this::checkResult);
                executeDmProc(HEPATITIS_DATAMART,
                        invRepository::executeStoredProcForHepDatamart, cases, this::checkResult);
                break;
            case STD_HIV_DATAMART:
                executeDmProc(STD_HIV_DATAMART,
                        invRepository::executeStoredProcForStdHIVDatamart, cases, this::checkResult);
                break;
            case GENERIC_CASE:
                executeDmProc(GENERIC_CASE,
                        invRepository::executeStoredProcForGenericCaseDatamart, cases, this::checkResult);
                processLdfLegacy(ldfType, cases);
                break;
            case CRS_CASE:
                executeDmProc(CRS_CASE,
                        invRepository::executeStoredProcForCRSCaseDatamart, cases, this::checkResult);
                break;
            case RUBELLA_CASE:
                executeDmProc(RUBELLA_CASE,
                        invRepository::executeStoredProcForRubellaCaseDatamart, cases, this::checkResult);
                break;
            case MEASLES_CASE:
                executeDmProc(MEASLES_CASE,
                        invRepository::executeStoredProcForMeaslesCaseDatamart, cases, this::checkResult);
                break;
            case CASE_LAB_DATAMART:
                executeDmProc(CASE_LAB_DATAMART,
                        invRepository::executeStoredProcForCaseLabDatamart, cases, this::checkResult);
                break;
            case BMIRD_CASE:
                executeDmProc(BMIRD_CASE,
                        invRepository::executeStoredProcForBmirdCaseDatamart, cases, this::checkResult);
                executeDmProc(BMIRD_STREP_PNEUMO_DATAMART,
                        invRepository::executeStoredProcForBmirdStrepPneumoDatamart, cases, this::checkResult);
                processLdfLegacy(ldfType, cases);
                break;
            case HEPATITIS_CASE:
                executeDmProc(HEPATITIS_CASE,
                        invRepository::executeStoredProcForHepatitisCaseDatamart, cases, this::checkResult);
                executeDmProc(HEP100,
                        invRepository::executeStoredProcForHep100, cases, this::checkResult);
                processLdfLegacy(ldfType, cases);
                break;
            case PERTUSSIS_CASE:
                executeDmProc(PERTUSSIS_CASE,
                        invRepository::executeStoredProcForPertussisCaseDatamart, cases, this::checkResult);
                break;
            case TB_DATAMART:
                executeDmProc(TB_DATAMART,
                        invRepository::executeStoredProcForTbDatamart, cases, this::checkResult);

                executeDmProc(TB_HIV_DATAMART,
                        invRepository::executeStoredProcForTbHivDatamart, cases, this::checkResult);
                break;
            case VAR_DATAMART:
                executeDmProc(VAR_DATAMART,
                        invRepository::executeStoredProcForVarDatamart, cases, this::checkResult);
                break;
            case COVID_CASE_DATAMART:
                executeDmProc(COVID_CASE_DATAMART,
                        invRepository::executeStoredProcForCovidCaseDatamart, cases, this::checkResult);
                break;
            case COVID_CONTACT_DATAMART:
                executeDmProc(COVID_CONTACT_DATAMART,
                        invRepository::executeStoredProcForCovidContactDatamart, cases, this::checkResult);
                break;
            case COVID_VACCINATION_DATAMART:
                String pats = listToParameterString(patUids);
                executeDmProc(COVID_VACCINATION_DATAMART,
                        invRepository::executeStoredProcForCovidVacDatamart, cases, pats, this::checkResult);
                break;
            case COVID_LAB_DATAMART:
                String labs = listToParameterString(obsUids);
                executeDmProc(COVID_LAB_DATAMART,
                        invRepository::executeStoredProcForCovidLabDatamart, labs, this::checkResult);
                executeDmProc(COVID_LAB_CELR_DATAMART,
                        invRepository::executeStoredProcForCovidLabCelrDatamart, labs, this::checkResult);
                break;
            default:
                logger.info("No associated datamart processing logic found for the key: {} ", dmType);
        }
    }

    private boolean processLdfVaccinePreventDm(Long batchId, List<Long> ldfUids, boolean failed) {
        if (!failed) {

            String cases = listToParameterString(ldfUids);
            try {
                executeDmProc(LDF_VACCINE_PREVENT_DISEASES,
                        invRepository::executeStoredProcForLdfVacPreventDiseasesDatamart, cases, this::checkResult);
            } catch (Exception e) {
                String ldfType = LDF_VACCINE_PREVENT_DISEASES.getEntityName();
                String dmKey = "LDF," + ldfType;

                logger.error(errorMessage(ldfType, cases, new Exception(e.getClass().getSimpleName())));
                buildRetryCache(batchId, dmKey, Collections.singletonMap(INVESTIGATION.getEntityName(), ldfUids), e);
                failed = true;
            }
        }
        return failed;
    }

    private void processLdfLegacy(String ldfType, String cases) {
        switch (Entity.valueOf(ldfType.toUpperCase())) {
            case LDF_GENERIC:
                executeDmProc(LDF_GENERIC,
                        invRepository::executeStoredProcForLdfGenericDatamart, cases, this::checkResult);
                break;
            case LDF_FOODBORNE:
                executeDmProc(LDF_FOODBORNE,
                        invRepository::executeStoredProcForLdfFoodBorneDatamart, cases, this::checkResult);
                break;
            case LDF_TETANUS:
                // to test this, Tetanus must be added as a legacy page and
                // [dbo].nrt_datamart_metadata table must be updated adding TETANUS
                executeDmProc(LDF_TETANUS,
                        invRepository::executeStoredProcForLdfTetanusDatamart, cases, this::checkResult);
                break;
            case LDF_MUMPS:
                executeDmProc(LDF_MUMPS,
                        invRepository::executeStoredProcForLdfMumpsDatamart, cases, this::checkResult);
                break;
            case LDF_BMIRD:
                executeDmProc(LDF_BMIRD,
                        invRepository::executeStoredProcForLdfBmirdDatamart, cases, this::checkResult);
                break;
            case LDF_HEPATITIS:
                executeDmProc(LDF_HEPATITIS,
                        invRepository::executeStoredProcForLdfHepatitisDatamart, cases, this::checkResult);
                break;
            default:
                break;
        }
    }

    /**
     * Processes cached IDs for multi-ID datamarts by executing the appropriate stored procedures.
     * @param dmMulti
     */
    private boolean processMultiIdDatamart(Long batchId, Map<String, List<Long>> dmMulti, boolean failed) {
        if (failed) {
            updateRetryCache(batchId, MULTI_ID_DATAMART, dmMulti);
        } else {
            String invString = listToParameterString(dmMulti.get(INVESTIGATION.getEntityName()));
            String obsString = listToParameterString(dmMulti.get(OBSERVATION.getEntityName()));
            String notifString = listToParameterString(dmMulti.get(NOTIFICATION.getEntityName()));
            String patString = listToParameterString(dmMulti.get(PATIENT.getEntityName()));
            String provString = listToParameterString(dmMulti.get(PROVIDER.getEntityName()));
            String orgString = listToParameterString(dmMulti.get(ORGANIZATION.getEntityName()));

            int totalLengthInvSummary = invString.length() + notifString.length() + obsString.length();
            int totalLengthMorbReportDM = obsString.length() + patString.length() + provString.length() + orgString.length() + invString.length();

            try {
                if (totalLengthInvSummary > 0) {
                    //reusing the same DTO class for Dynamic Marts
                    List<DatamartData> dmDataList = procRepository.executeStoredProcForInvSummaryDatamart(invString, notifString, obsString);
                    processDynDatamart(dmDataList);
                } else {
                    logger.info("No updates to INV_SUMMARY Datamart");
                }

                if (totalLengthMorbReportDM > 0) {
                    procRepository.executeStoredProcForMorbidityReportDatamart(obsString, patString, provString, orgString, invString);
                } else {
                    logger.info("No updates to MORBIDITY_REPORT_DATAMART");
                }
            } catch (Exception e) {
                logger.error(errorMessage(MULTI_ID_DATAMART, invString, new Exception(e.getClass().getSimpleName())));
                buildRetryCache(batchId, MULTI_ID_DATAMART, dmMulti, e);
                failed = true;
            }
        }
        return failed;
    }

    private void processDynDatamart(List<DatamartData> dmDataList) {
        if (!dmDataList.isEmpty()) {
            Map<String, String> datamartPhcIdMap = dmDataList.stream()
                    .collect(Collectors.groupingBy(
                            DatamartData::getDatamart,
                            Collectors.mapping(
                                    dmData -> String.valueOf(dmData.getPublicHealthCaseUid()),
                                    Collectors.joining(",")
                            )
                    ));

            datamartPhcIdMap.forEach((datamart, phcIds) ->
                    CompletableFuture.runAsync(() -> procRepository.executeStoredProcForDynDatamart(datamart, phcIds), dynDmExecutor)
                            .thenRun(() -> logger.info("Updates to Dynamic Datamart: {} ", datamart))
            );
        } else {
            logger.info("No updates to Dynamic Datamarts");
        }
    }

    /**
     * Scheduled task to reprocess failed datamarts by iterating through retry cache and invoking {@link #processDmCache(Map, Long)}
     * with snapshots of the cached IDs.
     * <ul>1. Updates backfill records, manages retry attempts</ul>
     * <ul>2. Clear caches on success</ul>
     * <ul>3. Persists remaining IDs when the maximum retry limit is reached</ul>
     */
    @Scheduled(fixedDelayString = "${service.fixed-delay.datamart}")
    protected void processRetryCache() {

        for (Map.Entry<Long, Map<String, Map<String, Queue<Long>>>> retryEntry : retryCache.entrySet()) {

            Long batchId = retryEntry.getKey();

            // Making a cache snapshot preventing out-of-sequence ids processing
            // creates a deep copy of cache into snapshot
            final Map<String, Map<String, List<Long>>> retryCacheSnapshot;

            synchronized (cacheLock) {
                retryCacheSnapshot = retryEntry.getValue().entrySet().stream()
                        .collect(Collectors.toMap(Map.Entry::getKey, e -> e.getValue().entrySet().stream()
                                .collect(Collectors.toMap(Map.Entry::getKey,
                                        idEntry -> new ArrayList<>(idEntry.getValue())
                                ))
                        ));
                retryCache.remove(batchId);
            }

            boolean processed = processDmCache(retryCacheSnapshot, batchId);

            // update backfill batch record(s) if exists
            if (updateBackfills(batchId, processed)) {
                retryCache.remove(batchId);
                continue;
            }

            if (processed) {
                // clear retry caches if no errors after re-processing
                retryAttempts.remove(batchId);
                errorMap.remove(batchId);
            } else {
                int attempt = retryAttempts.getOrDefault(batchId, 0);
                if (attempt >= maxRetries) {
                    logger.info("Reached max retries for batch id: {}. Skipping further processing.", batchId);
                    retryAttempts.remove(batchId);
                    retryCache.remove(batchId);

                    processBackfills(retryCacheSnapshot, batchId);
                    errorMap.remove(batchId);
                }
            }
        }
    }

    /**
     * Persists failed entities for backfill processing into the database.
     * <p>
     * Applies nameOp to each cache key and invokes the backfill
     * stored procedure with entity name, ID list, batchId, error,
     * status, and retry count.
     * </p>
     * @param cache   map of entity names to failed record IDs
     * @param nameOp  transforms the cache key into the database-specific entity name
     * @param batchId unique batch identifier for this backfill run
     */
    void processBackfills(Map<String, List<Long>> cache, UnaryOperator<String> nameOp, Long batchId) {

        for (Map.Entry<String, List<Long>> entry : cache.entrySet()) {
            procRepository.executeStoredProcForBackfill(
                    nameOp.apply(entry.getKey()),
                    listToParameterString(entry.getValue()),
                    batchId,
                    errorMap.get(batchId),
                    STATUS_READY,
                    backfillAttempts.getOrDefault(batchId, 0)
            );
        }
    }

    /**
     * Persists failed datamarts for backfill processing into the database.
     * <p>
     * Invokes the backfill stored procedure with datamart name, ID list, batchId, error,
     * status, and retry count.
     * </p>
     * @param cache   map of datamart names to failed record IDs
     * @param batchId unique batch identifier for this backfill run
     */
    void processBackfills(Map<String, Map<String, List<Long>>> cache, Long batchId) {
        for (Map.Entry<String, Map<String, List<Long>>> entry : cache.entrySet()) {
            String dmName = "DM^" + entry.getKey();
            String ids = entry.getValue().entrySet().stream()
                    .filter(idEntry -> !idEntry.getValue().isEmpty())
                    .map(idEntry -> idEntry.getKey() + ":" + listToParameterString(idEntry.getValue()))
                    .collect(Collectors.joining(" "));
            procRepository.executeStoredProcForBackfill(
                    dmName,
                    ids.trim(),
                    batchId,
                    errorMap.get(batchId),
                    STATUS_READY,
                    backfillAttempts.getOrDefault(batchId, 0)
            );
        }
    }

    boolean updateBackfills(Long batchId, boolean processed) {
        if (backfillAttempts.containsKey(batchId)) {
            retryAttempts.remove(batchId);

            String status = processed ? STATUS_COMPLETE : STATUS_READY;
            int bfAttempt = backfillAttempts.get(batchId) + 1;
            if (bfAttempt >= maxRetries) {
                logger.info("Reached max backfill retries for batch id: {}. Suspend further processing.", batchId);
                status = STATUS_SUSPENDED;
                bfAttempt = 0;
            }

            procRepository.executeStoredProcForBackfill(null, null, batchId,
                    errorMap.get(batchId), status, bfAttempt);

            backfillAttempts.remove(batchId);
            errorMap.remove(batchId);
            return true;
        }
        return false;
    }

    private Long buildRetryCache(
            Long batchId, String dmKey, Map<String, List<Long>> idMap, Exception e) {

        //skip retrying for non-positive value
        if (maxRetries <= 0) {
            return null;
        }

        batchId = getBatchId(batchId, e);
        updateRetryCache(batchId, dmKey, idMap);

        return batchId;
    }

    protected Long getBatchId(Long batchId, Exception e) {
        if (batchId == null) {
            batchId = (System.currentTimeMillis() << 10) | INSTANCE_ID;
            retryAttempts.put(batchId, 0);
        } else {
            retryAttempts.merge(batchId, 1, Integer::sum);
        }

        Throwable cause = e;
        while (cause.getCause() != null) {
            cause = cause.getCause(); // unwrap nested exceptions
        }
        String errorMsg = cause.getMessage();
        errorMap.put(batchId, errorMsg);

        return batchId;
    }

    void updateRetryCache(Long batchId, BackfillData bfd) {

        String dmKey = bfd.getEntity().substring("DM^".length());

        // Parse recordUidList into a map
        String recordUidList = bfd.getRecordUidList();
        Map<String, List<Long>> idMap =
                Arrays.stream(recordUidList.split("\\s+"))
                        .map(token -> token.split(":", 2))
                        .collect(Collectors.toMap(
                                parts -> parts[0],
                                parts -> Arrays.stream(parts[1].split(","))
                                        .map(Long::valueOf).toList()
                        ));
        backfillAttempts.put(batchId, bfd.getRetryCount());
        retryAttempts.put(batchId, bfd.getRetryCount());
        errorMap.put(batchId, bfd.getErrDescription());

        updateRetryCache(batchId, dmKey, idMap);
    }

    private void updateRetryCache(Long batchId, String dmKey, Map<String, List<Long>> idMap) {
        if (batchId != null) {
            Map<String, Queue<Long>> dmMap = retryCache
                    .computeIfAbsent(batchId, k -> new ConcurrentHashMap<>())
                    .computeIfAbsent(dmKey, k -> new ConcurrentHashMap<>());
            idMap.forEach((key, value) ->
                    dmMap.computeIfAbsent(key, k -> new ConcurrentLinkedQueue<>()).addAll(value));
        }
    }

    private <T> void executeDmProc(Entity dmEntity, Function<String, List<T>> repositoryMethod, String ids,
                                   Consumer<List<T>> checkResult) {
        if (!ids.isEmpty()) {
            logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmEntity.getEntityName(), dmEntity.getStoredProcedure(), ids);
            List<T> result = repositoryMethod.apply(ids);
            checkResult.accept(result);
            logger.info(SP_EXECUTION_COMPLETED, dmEntity.getStoredProcedure());
        }
    }

    private <T> void executeDmProc(Entity dmEntity, BiFunction<String, String, List<T>> repositoryMethod,
                                   String ids, String pids, Consumer<List<T>> checkResult) {
        if (!ids.isEmpty() && !pids.isEmpty()) {
            logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG_2, dmEntity.getEntityName(), dmEntity.getStoredProcedure(), ids, pids);
            List<T> result = repositoryMethod.apply(ids, pids);
            checkResult.accept(result);
            logger.info(SP_EXECUTION_COMPLETED, dmEntity.getStoredProcedure());
        }
    }

    private List<Long> getUids(Map<String, List<Long>> dmValues, Entity entity) {
        return Optional.ofNullable(dmValues.get(entity.getEntityName()))
                .map(ArrayList::new).orElseGet(ArrayList::new);
    }

    private String listToParameterString(Collection<Long> inputList) {
        return Optional.ofNullable(inputList)
                .map(list -> list.stream().distinct().map(String::valueOf).collect(Collectors.joining(",")))
                .orElse("");
    }

    void checkResult(List<DatamartData> dmData) throws DataProcessingException {
        if (!dmData.isEmpty()) {
            DatamartData dme = dmData.getFirst();
            if ("Error".equals(dme.getDatamart())) {
                throw new DataProcessingException(dme.getStoredProcedure());
            }
        }
    }
}
