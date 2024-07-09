package gov.cdc.etldatapipeline.observation;

import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import gov.cdc.etldatapipeline.observation.util.ProcessObservationDataUtil;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;

public class ObservationDataProcessTests {
    private static final String FILE_PREFIX = "rawDataFiles/";
    ProcessObservationDataUtil util = new ProcessObservationDataUtil();

    @Test
    public void consolidatedDataTransformationTest() {
        Observation observation = new Observation();
        observation.setActUid(100000001L);
        observation.setObsDomainCdSt1("Order");

        observation.setPersonParticipations(readFileData(FILE_PREFIX + "PersonParticipations.json"));
        observation.setOrganizationParticipations(readFileData(FILE_PREFIX + "OrganizationParticipations.json"));
        observation.setMaterialParticipations(readFileData(FILE_PREFIX + "MaterialParticipations.json"));
        observation.setFollowupObservations(readFileData(FILE_PREFIX + "FollowupObservations.json"));

        ObservationTransformed observationTransformed = util.transformObservationData(observation);

        Long patId = observationTransformed.getPatientId();
        Long ordererId = observationTransformed.getOrderingPersonId();
        Long authorOrgId = observationTransformed.getAuthorOrganizationId();
        Long ordererOrgId = observationTransformed.getOrderingOrganizationId();
        Long performerOrgId = observationTransformed.getPerformingOrganizationId();
        Long materialId = observationTransformed.getMaterialId();
        Long resultObsUid = observationTransformed.getResultObservationUid();


        Assertions.assertEquals(10000055L, ordererId);
        Assertions.assertEquals(10000066L, patId);
        Assertions.assertEquals(34567890L, authorOrgId);
        Assertions.assertEquals(23456789L, ordererOrgId);
        Assertions.assertNull(performerOrgId);
        Assertions.assertEquals(10000005L, materialId);
        Assertions.assertEquals(56789012L, resultObsUid);
    }

    @Test
    public void organizationDataTransformationTest() {
        Observation observation = new Observation();
        observation.setActUid(100000001L);
        observation.setObsDomainCdSt1("Result");

        observation.setOrganizationParticipations(readFileData(FILE_PREFIX + "OrganizationParticipations.json"));

        ObservationTransformed observationTransformed = util.transformObservationData(observation);
        Long authorOrgId = observationTransformed.getAuthorOrganizationId();
        Long ordererOrgId = observationTransformed.getOrderingOrganizationId();
        Long performerOrgId = observationTransformed.getPerformingOrganizationId();

        Assertions.assertNull(authorOrgId);
        Assertions.assertNull(ordererOrgId);
        Assertions.assertEquals(45678901L, performerOrgId);
    }
}
