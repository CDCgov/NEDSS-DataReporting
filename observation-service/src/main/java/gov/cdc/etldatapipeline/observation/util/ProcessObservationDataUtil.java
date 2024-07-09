package gov.cdc.etldatapipeline.observation.util;

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
            JsonNode personParticipationsJsonArray = personParticipations != null ? objectMapper.readTree(personParticipations) : null;

            if(personParticipations != null && personParticipationsJsonArray.isArray()) {
                for(JsonNode jsonNode : personParticipationsJsonArray) {
                    String typeCd = jsonNode.get("type_cd").asText();
                    String subjectClassCd = jsonNode.get("subject_class_cd").asText();

                    if(obsDomainCdSt1.equals("Order")) {
                        if(typeCd != null && subjectClassCd != null) {
                            if(typeCd.equals("ORD") && subjectClassCd.equals("PSN")) {
                                observationTransformed.setOrderingPersonId(jsonNode.get("entity_id").asLong());
                            }
                            if (typeCd.equals("PATSBJ") && subjectClassCd.equals("PSN")) {
                                observationTransformed.setPatientId(jsonNode.get("entity_id").asLong());
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
            JsonNode organizationParticipationsJsonArray = organizationParticipations != null ? objectMapper.readTree(organizationParticipations) : null;

            if(organizationParticipations != null && organizationParticipationsJsonArray.isArray()) {
                for(JsonNode jsonNode : organizationParticipationsJsonArray) {
                    String typeCd = jsonNode.get("type_cd").asText();
                    String subjectClassCd = jsonNode.get("subject_class_cd").asText();

                    if(obsDomainCdSt1.equals("Result")) {
                        if(typeCd != null && subjectClassCd != null) {
                            if(typeCd.equals("PRF") && subjectClassCd.equals("ORG")) {
                                observationTransformed.setPerformingOrganizationId(jsonNode.get("entity_id").asLong());
                            }
                        }
                        else {
                            logger.error("typeCd or subjectClassCd is null for the organizationParticipations: {}", organizationParticipations);
                        }
                    }
                    if(obsDomainCdSt1.equals("Order")) {
                        if(typeCd != null && subjectClassCd != null) {
                            if(typeCd.equals("AUT") && subjectClassCd.equals("ORG")) {
                                observationTransformed.setAuthorOrganizationId(jsonNode.get("entity_id").asLong());
                            }
                            if(typeCd.equals("ORD") && subjectClassCd.equals("ORG")) {
                                observationTransformed.setOrderingOrganizationId(jsonNode.get("entity_id").asLong());
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
            JsonNode materialParticipationsJsonArray = materialParticipations != null ? objectMapper.readTree(materialParticipations) : null;

            if(materialParticipations != null && materialParticipationsJsonArray.isArray()) {
                for(JsonNode jsonNode : materialParticipationsJsonArray) {
                    String typeCd = jsonNode.get("type_cd").asText();
                    String subjectClassCd = jsonNode.get("subject_class_cd").asText();

                    if(obsDomainCdSt1.equals("Order")) {
                        if(typeCd != null && subjectClassCd != null) {
                            if(typeCd.equals("SPC") && subjectClassCd.equals("MAT")) {
                                observationTransformed.setMaterialId(jsonNode.get("entity_id").asLong());
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
            JsonNode followupObservationsJsonArray = followupObservations != null ? objectMapper.readTree(followupObservations) : null;

            if(followupObservations != null && followupObservationsJsonArray.isArray()) {
                for (JsonNode jsonNode : followupObservationsJsonArray) {
                    String domainCdSt1 = jsonNode.get("domain_cd_st_1").asText();

                    if (obsDomainCdSt1.equals("Order")) {
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
}
