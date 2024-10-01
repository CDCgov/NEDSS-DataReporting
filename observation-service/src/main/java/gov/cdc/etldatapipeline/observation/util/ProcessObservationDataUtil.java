package gov.cdc.etldatapipeline.observation.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.*;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.function.BiPredicate;

@Component
@RequiredArgsConstructor @Setter
public class ProcessObservationDataUtil {
    private static final Logger logger = LoggerFactory.getLogger(ProcessObservationDataUtil.class);
    private static final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    @Value("${spring.kafka.output.topic-name-coded}")
    public String codedTopicName;

    @Value("${spring.kafka.output.topic-name-date}")
    public String dateTopicName;

    @Value("${spring.kafka.output.topic-name-edx}")
    public String edxTopicName;

    @Value("${spring.kafka.output.topic-name-material}")
    public String materialTopicName;

    @Value("${spring.kafka.output.topic-name-numeric}")
    public String numericTopicName;

    @Value("${spring.kafka.output.topic-name-reason}")
    public String reasonTopicName;

    @Value("${spring.kafka.output.topic-name-txt}")
    public String txtTopicName;

    ObservationKey observationKey = new ObservationKey();

    private static final String SUBJECT_CLASS_CD = "subject_class_cd";
    public static final String TYPE_CD = "type_cd";
    public static final String ENTITY_ID = "entity_id";
    public static final String DOM_ORDER = "Order";
    public static final String DOM_RESULT = "Result";

    public ObservationTransformed transformObservationData(Observation observation) {
        ObservationTransformed observationTransformed = new ObservationTransformed();

        String obsDomainCdSt1 = observation.getObsDomainCdSt1();

        transformPersonParticipations(observation.getPersonParticipations(), obsDomainCdSt1, observationTransformed);
        transformOrganizationParticipations(observation.getOrganizationParticipations(), obsDomainCdSt1, observationTransformed);
        transformMaterialParticipations(observation.getMaterialParticipations(), obsDomainCdSt1, observationTransformed);
        transformFollowupObservations(observation.getFollowupObservations(), obsDomainCdSt1, observationTransformed);
        transformParentObservations(observation.getParentObservations(), obsDomainCdSt1, observationTransformed);
        transformObservationCoded(observation.getObsCode());
        transformObservationDate(observation.getObsDate());
        transformObservationEdx(observation.getEdxIds());
        transformObservationNumeric(observation.getObsNum());
        transformObservationReasons(observation.getObsReason());
        transformObservationTxt(observation.getObsTxt());

        return observationTransformed;
    }

    private void transformPersonParticipations(String personParticipations, String obsDomainCdSt1, ObservationTransformed observationTransformed) {
        try {
            JsonNode personParticipationsJsonArray = parseJsonArray(personParticipations);

            for (JsonNode jsonNode : personParticipationsJsonArray) {
                String typeCd = getNodeValue(jsonNode.get(TYPE_CD));
                String subjectClassCd = getNodeValue(jsonNode.get(SUBJECT_CLASS_CD));

                if(obsDomainCdSt1.equals(DOM_ORDER)) {
                    if(typeAndClassNull.test(typeCd, subjectClassCd)) {
                        if("ORD".equals(typeCd) && "PSN".equals(subjectClassCd)) {
                            observationTransformed.setOrderingPersonId(jsonNode.get(ENTITY_ID).asLong());
                        }
                        if ("PATSBJ".equals(typeCd) && "PSN".equals(subjectClassCd)) {
                            observationTransformed.setPatientId(jsonNode.get(ENTITY_ID).asLong());
                        }
                    } else {
                        logger.error("Type_cd or subject_class_cd is null for the personParticipations: {}", personParticipations);
                    }
                } else {
                    logger.error("obsDomainCdSt1: {} is not valid for the personParticipations.", obsDomainCdSt1);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info("PersonParticipations array is null.");
        } catch (Exception e) {
            logger.error("Error processing Person Participation JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformOrganizationParticipations(String organizationParticipations, String obsDomainCdSt1, ObservationTransformed observationTransformed) {
        try {
            JsonNode organizationParticipationsJsonArray = parseJsonArray(organizationParticipations);

            for(JsonNode jsonNode : organizationParticipationsJsonArray) {
                String typeCd = getNodeValue(jsonNode.get(TYPE_CD));
                String subjectClassCd = getNodeValue(jsonNode.get(SUBJECT_CLASS_CD));

                if (typeAndClassNull.test(typeCd, subjectClassCd)) {
                    if (obsDomainCdSt1.equals(DOM_RESULT)) {
                        if("PRF".equals(typeCd) && "ORG".equals(subjectClassCd)) {
                            observationTransformed.setPerformingOrganizationId(jsonNode.get(ENTITY_ID).asLong());
                        }
                    } else if(obsDomainCdSt1.equals(DOM_ORDER)) {
                            if("AUT".equals(typeCd) && "ORG".equals(subjectClassCd)) {
                                observationTransformed.setAuthorOrganizationId(jsonNode.get(ENTITY_ID).asLong());
                            }
                            if("ORD".equals(typeCd) && "ORG".equals(subjectClassCd)) {
                                observationTransformed.setOrderingOrganizationId(jsonNode.get(ENTITY_ID).asLong());
                            }
                    } else {
                        logger.error("obsDomainCdSt1: {} is not valid for the organizationParticipations", obsDomainCdSt1);
                    }
                } else {
                    logger.error("Type_cd or subject_class_cd is null for the organizationParticipations: {}", organizationParticipations);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info("OrganizationParticipations array is null.");
        } catch (Exception e) {
            logger.error("Error processing Organization Participation JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformMaterialParticipations(String materialParticipations, String obsDomainCdSt1, ObservationTransformed observationTransformed) {
        try {
            JsonNode materialParticipationsJsonArray = parseJsonArray(materialParticipations);

            for (JsonNode jsonNode : materialParticipationsJsonArray) {
                String typeCd = getNodeValue(jsonNode.get(TYPE_CD));
                String subjectClassCd = getNodeValue(jsonNode.get(SUBJECT_CLASS_CD));

                if (obsDomainCdSt1.equals(DOM_ORDER)) {
                    if (typeAndClassNull.test(typeCd, subjectClassCd)) {
                        if ("SPC".equals(typeCd) && "MAT".equals(subjectClassCd)) {
                            Long materialId = jsonNode.get(ENTITY_ID).asLong();
                            observationTransformed.setMaterialId(materialId);

                            ObservationMaterial material = objectMapper.treeToValue(jsonNode, ObservationMaterial.class);
                            material.setMaterialId(materialId);
                            ObservationMaterialKey key = new ObservationMaterialKey();
                            key.setMaterialId(observationTransformed.getMaterialId());
                            sendToKafka(key, material, materialTopicName, materialId, "Observation Material data (uid={}) sent to {}");
                        }
                    } else {
                        logger.error("Type_cd or subject_class_cd is null for the materialParticipations: {}", materialParticipations);
                    }
                }
                else {
                    logger.error("obsDomainCdSt1: {} is not valid for the materialParticipations", obsDomainCdSt1);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info("MaterialParticipations array is null.");
        } catch (Exception e) {
            logger.error("Error processing Material Participation JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformFollowupObservations(String followupObservations, String obsDomainCdSt1, ObservationTransformed observationTransformed) {
        try {
            JsonNode followupObservationsJsonArray = parseJsonArray(followupObservations);

            List<String> results = new ArrayList<>();
            List<String> followUps = new ArrayList<>();
            for (JsonNode jsonNode : followupObservationsJsonArray) {
                String domainCdSt1 = getNodeValue(jsonNode.get("domain_cd_st_1"));

                if (obsDomainCdSt1.equals(DOM_ORDER)) {
                    if (DOM_RESULT.equals(domainCdSt1)) {
                        Optional.ofNullable(jsonNode.get("result_observation_uid")).ifPresent(r -> results.add(r.asText()));
                    }
                    else {
                        Optional.ofNullable(jsonNode.get("result_observation_uid")).ifPresent(r -> followUps.add(r.asText()));
                    }
                } else {
                    logger.error("obsDomainCdSt1: {} is not valid for the followupObservations", obsDomainCdSt1);
                }
            }

            if(!results.isEmpty()) {
                observationTransformed.setResultObservationUid(String.join(",", results));
            }
            if(!followUps.isEmpty()) {
                observationTransformed.setFollowUpObservationUid(String.join(",", followUps));
            }
        } catch (IllegalArgumentException ex) {
            logger.info("FollowupObservations array is null.");
        } catch (Exception e) {
            logger.error("Error processing Followup Observations JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformParentObservations(String parentObservations, String obsDomainCdSt1, ObservationTransformed observationTransformed) {
        try {
            JsonNode parentObservationsJsonArray = parseJsonArray(parentObservations);

            for (JsonNode jsonNode : parentObservationsJsonArray) {
                Optional<String> parentTypeCd = Optional.ofNullable(getNodeValue(jsonNode.get("parent_type_cd")));
                if (obsDomainCdSt1.equals(DOM_ORDER)) {
                    parentTypeCd.ifPresentOrElse(typeCd -> {
                        Optional<JsonNode> parentUid = Optional.ofNullable(jsonNode.get("parent_uid"));
                        Optional<JsonNode> observationUid = Optional.ofNullable(jsonNode.get("report_observation_uid"));

                        switch (typeCd) {
                            case "SPRT":
                                parentUid.ifPresent(id -> observationTransformed.setReportSprtUid(id.asLong()));
                                observationUid.ifPresent(id -> observationTransformed.setReportObservationUid(id.asLong()));
                                break;
                            case "REFR":
                                parentUid.ifPresent(id -> observationTransformed.setReportRefrUid(id.asLong()));
                                observationUid.ifPresent(id -> observationTransformed.setReportObservationUid(id.asLong()));
                                break;
                            default:
                                parentUid.ifPresent(id ->  observationTransformed.setReportObservationUid(id.asLong()));
                                break;
                        }
                    },
                    () -> logger.error("Parent_type_cd is null for the parentObservations: {}", parentObservations));
                } else {
                    logger.error("obsDomainCdSt1: {} is not valid for the parentObservations", obsDomainCdSt1);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info("ParentObservations array is null.");
        } catch (Exception e) {
            logger.error("Error processing Parent Observations JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationCoded(String observationCoded) {
        try {
            JsonNode observationCodedJsonArray = parseJsonArray(observationCoded);

            for (JsonNode jsonNode : observationCodedJsonArray) {
                ObservationCoded coded = objectMapper.treeToValue(jsonNode, ObservationCoded.class);
                observationKey.setObservationUid(coded.getObservationUid());
                sendToKafka(observationKey, coded, codedTopicName, coded.getObservationUid(), "Observation Coded data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info("ObservationCoded array is null.");
        } catch (Exception e) {
            logger.error("Error processing Observation Coded JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationDate(String observationDate) {
        try {
            JsonNode observationDateJsonArray = parseJsonArray(observationDate);

            for (JsonNode jsonNode : observationDateJsonArray) {
                ObservationDate coded = objectMapper.treeToValue(jsonNode, ObservationDate.class);
                observationKey.setObservationUid(coded.getObservationUid());
                sendToKafka(observationKey, coded, dateTopicName, coded.getObservationUid(), "Observation Date data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info("ObservationDate array is null.");
        } catch (Exception e) {
            logger.error("Error processing Observation Date JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationEdx(String observationEdx) {
        try {
            JsonNode observationEdxJsonArray = parseJsonArray(observationEdx);
            ObservationEdxKey edxKey = new ObservationEdxKey();

            for (JsonNode jsonNode : observationEdxJsonArray) {
                ObservationEdx edx = objectMapper.treeToValue(jsonNode, ObservationEdx.class);
                edxKey.setEdxDocumentUid(edx.getEdxDocumentUid());
                sendToKafka(edxKey, edx, edxTopicName, edx.getEdxDocumentUid(), "Observation Edx data (edx doc uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info("ObservationEdx array is null.");
        } catch (Exception e) {
            logger.error("Error processing Observation Edx JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationNumeric(String observationNumeric) {
        try {
            JsonNode observationNumericJsonArray = parseJsonArray(observationNumeric);

            for (JsonNode jsonNode : observationNumericJsonArray) {
                ObservationNumeric numeric = objectMapper.treeToValue(jsonNode, ObservationNumeric.class);
                observationKey.setObservationUid(numeric.getObservationUid());
                sendToKafka(observationKey, numeric, numericTopicName, numeric.getObservationUid(), "Observation Numeric data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info("ObservationNumeric array is null.");
        } catch (Exception e) {
            logger.error("Error processing Observation Numeric JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationReasons(String observationReasons) {
        try {
            JsonNode observationReasonsJsonArray = parseJsonArray(observationReasons);

            for (JsonNode jsonNode : observationReasonsJsonArray) {
                ObservationReason reason = objectMapper.treeToValue(jsonNode, ObservationReason.class);
                observationKey.setObservationUid(reason.getObservationUid());
                sendToKafka(observationKey, reason, reasonTopicName, reason.getObservationUid(), "Observation Reason data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info("ObservationReasons array is null.");
        } catch (Exception e) {
            logger.error("Error processing Observation Reasons JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationTxt(String observationTxt) {
        try {
            JsonNode observationTxtJsonArray = parseJsonArray(observationTxt);

            for (JsonNode jsonNode : observationTxtJsonArray) {
                ObservationTxt txt = objectMapper.treeToValue(jsonNode, ObservationTxt.class);
                observationKey.setObservationUid(txt.getObservationUid());
                sendToKafka(observationKey, txt, txtTopicName, txt.getObservationUid(), "Observation Txt data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info("ObservationTxt array is null.");
        } catch (Exception e) {
            logger.error("Error processing Observation Txt JSON array from observation data: {}", e.getMessage());
        }
    }

    private void sendToKafka(Object key, Object value, String topicName, Long uid, String message) {
        String jsonKey = jsonGenerator.generateStringJson(key);
        String jsonValue = jsonGenerator.generateStringJson(value);
        kafkaTemplate.send(topicName, jsonKey, jsonValue)
                .whenComplete((res, e) -> logger.info(message, uid, topicName));
    }

    private JsonNode parseJsonArray(String jsonString) throws JsonProcessingException, IllegalArgumentException {
        JsonNode jsonArray = jsonString != null ? objectMapper.readTree(jsonString) : null;
        if (jsonArray != null && jsonArray.isArray()) {
            return jsonArray;
        } else {
            throw new IllegalArgumentException();
        }
    }

    private String getNodeValue(JsonNode jsonNode) {
        return jsonNode == null || jsonNode.isNull() ? null : jsonNode.asText();
    }

    private final BiPredicate<String, String> typeAndClassNull = (t, c) -> (t != null) && (c != null);
}
