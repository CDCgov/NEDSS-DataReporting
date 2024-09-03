package gov.cdc.etldatapipeline.observation.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ProcessObservationDataUtil {
    private static final Logger logger = LoggerFactory.getLogger(ProcessObservationDataUtil.class);

    private static final String SUBJECT_CLASS_CD = "subject_class_cd";
    public static final String TYPE_CD = "type_cd";
    public static final String ENTITY_ID = "entity_id";
    public static final String DOM_ORDER = "Order";
    public static final String DOM_RESULT = "Result";

    public ObservationTransformed transformObservationData(Observation observation) {
        ObservationTransformed observationTransformed = new ObservationTransformed();
        ObjectMapper objectMapper = new ObjectMapper();

        String obsDomainCdSt1 = observation.getObsDomainCdSt1();

        transformPersonParticipations(observation.getPersonParticipations(), obsDomainCdSt1, observationTransformed, objectMapper);
        transformOrganizationParticipations(observation.getOrganizationParticipations(), obsDomainCdSt1, observationTransformed, objectMapper);
        transformMaterialParticipations(observation.getMaterialParticipations(), obsDomainCdSt1, observationTransformed, objectMapper);
        transformFollowupObservations(observation.getFollowupObservations(), obsDomainCdSt1, observationTransformed, objectMapper);

        return observationTransformed;
    }

    private void transformPersonParticipations(String personParticipations, String obsDomainCdSt1, ObservationTransformed observationTransformed, ObjectMapper objectMapper) {
        try {
            JsonNode personParticipationsJsonArray = parseJsonArray(personParticipations, objectMapper);

            if(personParticipationsJsonArray != null) {
                for(JsonNode jsonNode : personParticipationsJsonArray) {
                    String typeCd = getNodeValue(jsonNode.get(TYPE_CD));
                    String subjectClassCd = getNodeValue(jsonNode.get(SUBJECT_CLASS_CD));

                    if(obsDomainCdSt1.equals(DOM_ORDER)) {
                        if(typeCd != null && subjectClassCd != null) {
                            if(typeCd.equals("ORD") && subjectClassCd.equals("PSN")) {
                                observationTransformed.setOrderingPersonId(jsonNode.get(ENTITY_ID).asLong());
                            }
                            if (typeCd.equals("PATSBJ") && subjectClassCd.equals("PSN")) {
                                observationTransformed.setPatientId(jsonNode.get(ENTITY_ID).asLong());
                            }
                        }
                        else {
                            logger.error("typeCd or subjectClassCd is null for the personParticipations: {}", personParticipations);
                        }
                    }
                    else {
                        logger.error("obsDomainCdSt1: {} is not valid for the personParticipations.", obsDomainCdSt1);
                    }
                }
            }
            else {
                logger.info("PersonParticipations array is null.");
            }
        } catch (Exception e) {
            logger.error("Error processing Person Participation JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformOrganizationParticipations(String organizationParticipations, String obsDomainCdSt1, ObservationTransformed observationTransformed, ObjectMapper objectMapper) {
        try {
            JsonNode organizationParticipationsJsonArray = parseJsonArray(organizationParticipations, objectMapper);

            if(organizationParticipationsJsonArray != null) {
                for(JsonNode jsonNode : organizationParticipationsJsonArray) {
                    String typeCd = getNodeValue(jsonNode.get(TYPE_CD));
                    String subjectClassCd = getNodeValue(jsonNode.get(SUBJECT_CLASS_CD));

                    if(obsDomainCdSt1.equals(DOM_RESULT)) {
                        if(typeCd != null && subjectClassCd != null) {
                            if(typeCd.equals("PRF") && subjectClassCd.equals("ORG")) {
                                observationTransformed.setPerformingOrganizationId(jsonNode.get(ENTITY_ID).asLong());
                            }
                        }
                        else {
                            logger.error("typeCd or subjectClassCd is null for the organizationParticipations: {}", organizationParticipations);
                        }
                    }
                    else if(obsDomainCdSt1.equals(DOM_ORDER)) {
                        if(typeCd != null && subjectClassCd != null) {
                            if(typeCd.equals("AUT") && subjectClassCd.equals("ORG")) {
                                observationTransformed.setAuthorOrganizationId(jsonNode.get(ENTITY_ID).asLong());
                            }
                            if(typeCd.equals("ORD") && subjectClassCd.equals("ORG")) {
                                observationTransformed.setOrderingOrganizationId(jsonNode.get(ENTITY_ID).asLong());
                            }
                        }
                        else {
                            logger.error("typeCd or subjectClassCd is null for the organizationParticipations: {}", organizationParticipations);
                        }
                    }
                    else {
                        logger.error("obsDomainCdSt1: {} is not valid for the organizationParticipations", obsDomainCdSt1);
                    }
                }
            }
            else {
                logger.info("OrganizationParticipations array is null.");
            }
        } catch (Exception e) {
            logger.error("Error processing Organization Participation JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformMaterialParticipations(String materialParticipations, String obsDomainCdSt1, ObservationTransformed observationTransformed, ObjectMapper objectMapper) {
        try {
            JsonNode materialParticipationsJsonArray = parseJsonArray(materialParticipations, objectMapper);

            if(materialParticipationsJsonArray != null) {
                for(JsonNode jsonNode : materialParticipationsJsonArray) {
                    String typeCd = getNodeValue(jsonNode.get(TYPE_CD));
                    String subjectClassCd = getNodeValue(jsonNode.get(SUBJECT_CLASS_CD));

                    if(obsDomainCdSt1.equals(DOM_ORDER)) {
                        if(typeCd != null && subjectClassCd != null) {
                            if(typeCd.equals("SPC") && subjectClassCd.equals("MAT")) {
                                observationTransformed.setMaterialId(jsonNode.get(ENTITY_ID).asLong());
                            }
                        }
                        else {
                            logger.error("typeCd or subjectClassCd is null for the materialParticipations: {}", materialParticipations);
                        }
                    }
                    else {
                        logger.error("obsDomainCdSt1: {} is not valid for the materialParticipations", obsDomainCdSt1);
                    }
                }
            }
            else {
                logger.info("MaterialParticipations array is null.");
            }
        } catch (Exception e) {
            logger.error("Error processing Material Participation JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformFollowupObservations(String followupObservations, String obsDomainCdSt1, ObservationTransformed observationTransformed, ObjectMapper objectMapper) {
        try {
            JsonNode followupObservationsJsonArray = parseJsonArray(followupObservations, objectMapper);

            if(followupObservationsJsonArray != null) {
                for (JsonNode jsonNode : followupObservationsJsonArray) {
                    String domainCdSt1 = getNodeValue(jsonNode.get("domain_cd_st_1"));

                    if (obsDomainCdSt1.equals(DOM_ORDER)) {
                        if (domainCdSt1 != null && domainCdSt1.equals("Result")) {
                            observationTransformed.setResultObservationUid(jsonNode.get("result_observation_uid").asLong());
                        }
                        else {
                            logger.error("domainCdSt1: {} is null or not valid for the followupObservations: {}", domainCdSt1, followupObservations);
                        }
                    }
                    else {
                        logger.error("obsDomainCdSt1: {} is not valid for the followupObservations", obsDomainCdSt1);
                    }
                }
            }
            else {
                logger.info("FollowupObservations array is null.");
            }
        } catch (Exception e) {
            logger.error("Error processing Followup Observations JSON array from observation data: {}", e.getMessage());
        }
    }

    private JsonNode parseJsonArray(String jsonString, ObjectMapper objectMapper) throws JsonProcessingException {
        JsonNode jsonArray = jsonString != null ? objectMapper.readTree(jsonString) : null;
        if (jsonArray != null) {
            return jsonArray.isArray() ? jsonArray : null;
        } else {
            return null;
        }
    }

    private String getNodeValue(JsonNode jsonNode) {
        return jsonNode == null || jsonNode.isNull() ? null : jsonNode.asText();
    }
}
