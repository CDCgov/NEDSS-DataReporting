package gov.cdc.etldatapipeline.investigation.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.*;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationKey;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationNotification;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationNotificationKey;
import gov.cdc.etldatapipeline.investigation.repository.odse.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.rdb.InvestigationCaseAnswerRepository;
import lombok.Setter;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
@Setter
public class ProcessInvestigationDataUtil {
    private static final Logger logger = LoggerFactory.getLogger(ProcessInvestigationDataUtil.class);
    private static final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @Value("${spring.kafka.output.topic-name-confirmation}")
    public String investigationConfirmationOutputTopicName;

    @Value("${spring.kafka.output.topic-name-observation}")
    public String investigationObservationOutputTopicName;

    @Value("${spring.kafka.output.topic-name-notifications}")
    public String investigationNotificationsOutputTopicName;

    private final KafkaTemplate<String, String> kafkaTemplate;
    InvestigationKey investigationKey = new InvestigationKey();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    private final InvestigationCaseAnswerRepository investigationCaseAnswerRepository;
    private final InvestigationRepository investigationRepository;

    public static final String TYPE_CD = "type_cd";

    @Transactional(transactionManager = "rdbTransactionManager")
    public InvestigationTransformed transformInvestigationData(Investigation investigation) {

        InvestigationTransformed investigationTransformed = new InvestigationTransformed();

        transformPersonParticipations(investigation.getPersonParticipations(), investigationTransformed);
        transformOrganizationParticipations(investigation.getOrganizationParticipations(), investigationTransformed);
        transformActIds(investigation.getActIds(), investigationTransformed);
        transformObservationIds(investigation.getObservationNotificationIds(), investigationTransformed);
        transformInvestigationConfirmationMethod(investigation.getInvestigationConfirmationMethod());
        processInvestigationPageCaseAnswer(investigation.getInvestigationCaseAnswer(), investigationTransformed);

        return investigationTransformed;
    }

    public void processNotifications(String investigationNotifications) {
        try {
            JsonNode investigationNotificationsJsonArray = parseJsonArray(investigationNotifications);

            InvestigationNotificationKey investigationNotificationKey = new InvestigationNotificationKey();
            for (JsonNode node : investigationNotificationsJsonArray) {
                Long notificationUid = node.get("notification_uid").asLong();
                investigationNotificationKey.setNotificationUid(notificationUid);

                InvestigationNotification tempInvestigationNotificationObject = objectMapper.treeToValue(node, InvestigationNotification.class);

                String jsonKey = jsonGenerator.generateStringJson(investigationNotificationKey);
                String jsonValue = jsonGenerator.generateStringJson(tempInvestigationNotificationObject);
                kafkaTemplate.send(investigationNotificationsOutputTopicName, jsonKey, jsonValue)
                        .whenComplete((res, e) -> logger.info("Notification data (uid={}) sent to {}", notificationUid, investigationNotificationsOutputTopicName));
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "InvestigationNotification");
        } catch (Exception e) {
            logger.error("Error processing Notifications JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformPersonParticipations(String personParticipations, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode personParticipationsJsonArray = parseJsonArray(personParticipations);

            for (JsonNode node : personParticipationsJsonArray) {
                String typeCode = node.get(TYPE_CD).asText();
                String subjectClassCode = node.get("subject_class_cd").asText();
                String personCode = node.get("person_cd").asText();
                Long entityId = node.get("entity_id").asLong();

                if (typeCode.equals("InvestgrOfPHC") && subjectClassCode.equals("PSN") && personCode.equals("PRV")) {
                    investigationTransformed.setInvestigatorId(entityId);
                }
                if (typeCode.equals("PhysicianOfPHC") && subjectClassCode.equals("PSN") && personCode.equals("PRV")) {
                    investigationTransformed.setPhysicianId(entityId);
                }
                if (typeCode.equals("SubjOfPHC") && subjectClassCode.equals("PSN") && personCode.equals("PAT")) {
                    investigationTransformed.setPatientId(entityId);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "PersonParticipations");
        } catch (Exception e) {
            logger.error("Error processing Person Participation JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformOrganizationParticipations(String organizationParticipations, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode organizationParticipationsJsonArray = parseJsonArray(organizationParticipations);

            for (JsonNode node : organizationParticipationsJsonArray) {
                String typeCode = node.get(TYPE_CD).asText();
                String subjectClassCode = node.get("subject_class_cd").asText();

                if (typeCode.equals("OrgAsReporterOfPHC") && subjectClassCode.equals("ORG")) {
                    investigationTransformed.setOrganizationId(node.get("entity_id").asLong());
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "OrganizationParticipations");
        } catch (Exception e) {
            logger.error("Error processing Organization Participation JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformActIds(String actIds, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode actIdsJsonArray = parseJsonArray(actIds);

            for(JsonNode node : actIdsJsonArray) {
                int actIdSeq = node.get("act_id_seq").asInt();
                String typeCode = node.get(TYPE_CD).asText();
                String rootExtension = node.get("root_extension_txt").asText();

                if(typeCode.equals("STATE") && actIdSeq == 1) {
                    investigationTransformed.setInvStateCaseId(rootExtension);
                }
                if(typeCode.equals("CITY") && actIdSeq == 2) {
                    investigationTransformed.setCityCountyCaseNbr(rootExtension);
                }
                if(typeCode.equals("LEGACY") && actIdSeq == 3) {
                    investigationTransformed.setLegacyCaseId(rootExtension);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ActIds");
        } catch (Exception e) {
            logger.error("Error processing Act Ids JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformObservationIds(String observationNotificationIds, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode investigationObservationIdsJsonArray = parseJsonArray(observationNotificationIds);
            InvestigationObservation investigationObservation = new InvestigationObservation();
            List<Long> observationIds = new ArrayList<>();

            for(JsonNode node : investigationObservationIdsJsonArray) {
                String sourceClassCode = node.path("source_class_cd").asText();
                String actTypeCode = node.path("act_type_cd").asText();
                Long sourceActId = node.get("source_act_uid").asLong();
                Long publicHealthCaseUid = node.get("public_health_case_uid").asLong();
                investigationKey.setPublicHealthCaseUid(publicHealthCaseUid);

                if(sourceClassCode.equals("OBS") && actTypeCode.equals("PHCInvForm")) {
                    investigationTransformed.setPhcInvFormId(sourceActId);
                }

                if(sourceClassCode.equals("OBS") && actTypeCode.equals("LabReport")) {
                    investigationObservation.setPublicHealthCaseUid(publicHealthCaseUid);
                    observationIds.add(sourceActId);
                }

                if(sourceClassCode.equals("OBS") && actTypeCode.equals("MorbReport")) {
                    investigationObservation.setPublicHealthCaseUid(publicHealthCaseUid);
                    observationIds.add(sourceActId);
                }
            }

            for(Long id : observationIds) {
                investigationObservation.setObservationId(id);
                String jsonValue = jsonGenerator.generateStringJson(investigationObservation);
                kafkaTemplate.send(investigationObservationOutputTopicName, jsonValue, jsonValue);
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "InvestigationObservationIds");
        } catch (Exception e) {
            logger.error("Error processing Observation Ids JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformInvestigationConfirmationMethod(String investigationConfirmationMethod) {
        try {
            JsonNode investigationConfirmationMethodJsonArray = parseJsonArray(investigationConfirmationMethod);

            InvestigationConfirmationMethodKey investigationConfirmationMethodKey = new InvestigationConfirmationMethodKey();
            InvestigationConfirmationMethod investigationConfirmation = new InvestigationConfirmationMethod();
            Map<String, String> confirmationMethodMap = new HashMap<>();
            String confirmationMethodTime = null;

            // Redundant time variable in case if confirmation_method_time is null in all rows of the array
            String phcLastChgTime = investigationConfirmationMethodJsonArray.get(0).get("phc_last_chg_time").asText();
            Long publicHealthCaseUid = investigationConfirmationMethodJsonArray.get(0).get("public_health_case_uid").asLong();

            for(JsonNode node : investigationConfirmationMethodJsonArray) {
                JsonNode timeNode = node.get("confirmation_method_time");
                if (timeNode != null && !timeNode.isNull()) {
                    confirmationMethodTime = timeNode.asText();
                }
                confirmationMethodMap.put(node.get("confirmation_method_cd").asText(), node.get("confirmation_method_desc_txt").asText());
            }
            investigationConfirmation.setPublicHealthCaseUid(publicHealthCaseUid);
            investigationConfirmationMethodKey.setPublicHealthCaseUid(publicHealthCaseUid);

            investigationConfirmation.setConfirmationMethodTime(
                    confirmationMethodTime == null ? phcLastChgTime : confirmationMethodTime);

            for(Map.Entry<String, String> entry : confirmationMethodMap.entrySet()) {
                investigationConfirmation.setConfirmationMethodCd(entry.getKey());
                investigationConfirmation.setConfirmationMethodDescTxt(entry.getValue());
                investigationConfirmationMethodKey.setConfirmationMethodCd(entry.getKey());
                String jsonKey = jsonGenerator.generateStringJson(investigationConfirmationMethodKey);
                String jsonValue = jsonGenerator.generateStringJson(investigationConfirmation);
                kafkaTemplate.send(investigationConfirmationOutputTopicName, jsonKey, jsonValue);
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "InvestigationObservationIds");
        } catch (Exception e) {
            logger.error("Error processing investigation confirmation method JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void processInvestigationPageCaseAnswer(String investigationCaseAnswer, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode investigationCaseAnswerJsonArray = parseJsonArray(investigationCaseAnswer);

            Long actUid = investigationCaseAnswerJsonArray.get(0).get("act_uid").asLong();
            List<InvestigationCaseAnswer> investigationCaseAnswerList = new ArrayList<>();

            for(JsonNode node : investigationCaseAnswerJsonArray) {
                InvestigationCaseAnswer tempCaseAnswerObject = objectMapper.treeToValue(node, InvestigationCaseAnswer.class);
                investigationCaseAnswerList.add(tempCaseAnswerObject);
            }

            investigationCaseAnswerRepository.deleteByActUid(actUid);
            investigationCaseAnswerRepository.saveAll(investigationCaseAnswerList);

            String rdbTblNms = String.join(",", investigationCaseAnswerList.stream()
                            .map(InvestigationCaseAnswer::getRdbTableNm).collect(Collectors.toSet()));
            if (!rdbTblNms.isEmpty()) {
                investigationTransformed.setRdbTableNameList(rdbTblNms);
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "InvestigationCaseAnswer");
        } catch (Exception e) {
            logger.error("Error processing investigation case answer JSON array from investigation data: {}", e.getMessage());
        }
    }

    @Transactional(transactionManager = "odseTransactionManager", isolation = Isolation.REPEATABLE_READ)
    public void processPhcFactDatamart(String publicHealthCaseUid) {
        try {
            // Calling sp_public_health_case_fact_datamart_event
            logger.info("Executing stored proc: sp_public_health_case_fact_datamart_event '{}' to populate PHС fact datamart", publicHealthCaseUid);
            investigationRepository.populatePhcFact(publicHealthCaseUid);
            logger.info("Stored proc execution completed: sp_public_health_case_fact_datamart_event '{}", publicHealthCaseUid);
        } catch (Exception dbe) {
            logger.warn("Error processing PHC fact datamart: {}", dbe.getMessage());
        }
    }

    private JsonNode parseJsonArray(String jsonString) throws JsonProcessingException, IllegalArgumentException {
        JsonNode jsonArray = jsonString != null ? objectMapper.readTree(jsonString) : null;
        if (jsonArray != null && jsonArray.isArray()) {
            return jsonArray;
        } else {
            throw new IllegalArgumentException("{} array is null.");
        }
    }
}
