package gov.cdc.etldatapipeline.observation;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import gov.cdc.etldatapipeline.observation.util.ProcessObservationDataUtil;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;

import java.util.List;

import static gov.cdc.etldatapipeline.commonutil.TestUtils.readFileData;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ObservationDataProcessTests {
    private static final String FILE_PREFIX = "rawDataFiles/";
    ProcessObservationDataUtil transformer = new ProcessObservationDataUtil();
    private final ListAppender<ILoggingEvent> listAppender = new ListAppender<>();

    @BeforeEach
    void setUp() {
        Logger logger = (Logger) LoggerFactory.getLogger(ProcessObservationDataUtil.class);
        listAppender.start();
        logger.addAppender(listAppender);
    }

    @AfterEach
    void tearDown() {
        Logger logger = (Logger) LoggerFactory.getLogger(ProcessObservationDataUtil.class);
        logger.detachAppender(listAppender);
    }

    @Test
    void consolidatedDataTransformationTest() {
        Observation observation = new Observation();
        observation.setActUid(100000001L);
        observation.setObsDomainCdSt1("Order");

        observation.setPersonParticipations(readFileData(FILE_PREFIX + "PersonParticipations.json"));
        observation.setOrganizationParticipations(readFileData(FILE_PREFIX + "OrganizationParticipations.json"));
        observation.setMaterialParticipations(readFileData(FILE_PREFIX + "MaterialParticipations.json"));
        observation.setFollowupObservations(readFileData(FILE_PREFIX + "FollowupObservations.json"));

        ObservationTransformed observationTransformed = transformer.transformObservationData(observation);

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
    void organizationDataTransformationTest() {
        Observation observation = new Observation();
        observation.setActUid(100000001L);
        observation.setObsDomainCdSt1("Result");

        observation.setOrganizationParticipations(readFileData(FILE_PREFIX + "OrganizationParticipations.json"));

        ObservationTransformed observationTransformed = transformer.transformObservationData(observation);
        Long authorOrgId = observationTransformed.getAuthorOrganizationId();
        Long ordererOrgId = observationTransformed.getOrderingOrganizationId();
        Long performerOrgId = observationTransformed.getPerformingOrganizationId();

        Assertions.assertNull(authorOrgId);
        Assertions.assertNull(ordererOrgId);
        Assertions.assertEquals(45678901L, performerOrgId);
    }

    @Test
    void testTransformObservationDataError(){
        Observation observation = new Observation();
        String invalidJSON = "invalidJSON";

        observation.setPersonParticipations(invalidJSON);
        observation.setOrganizationParticipations(invalidJSON);
        observation.setMaterialParticipations(invalidJSON);
        observation.setFollowupObservations(invalidJSON);

        transformer.transformObservationData(observation);

        List<ILoggingEvent> logs = listAppender.list;
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains(invalidJSON)));
    }

    @Test
    void testTransformObservationInvalidDomainError(){
        Observation observation = new Observation();
        String dummyJSON = "[{\"subject_class_cd\": null}]";
        String invalidDomain = "invalidDomain";
        observation.setObsDomainCdSt1(invalidDomain);

        observation.setPersonParticipations(dummyJSON);
        observation.setOrganizationParticipations(dummyJSON);
        observation.setMaterialParticipations(dummyJSON);
        observation.setFollowupObservations(dummyJSON);

        transformer.transformObservationData(observation);

        List<ILoggingEvent> logs = listAppender.list;
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains(invalidDomain)));
    }

    @Test
    void testTransformObservationResultDomainError(){
        Observation observation = new Observation();
        String dummyJSON = "[{\"type_cd\": \"PRF\",\"subject_class_cd\": \"ORG\",\"entity_id\": 45678901}]";

        observation.setObsDomainCdSt1("Result");
        observation.setPersonParticipations(dummyJSON);
        observation.setOrganizationParticipations(dummyJSON);
        observation.setMaterialParticipations(dummyJSON);
        observation.setFollowupObservations(dummyJSON);

        transformer.transformObservationData(observation);

        List<ILoggingEvent> logs = listAppender.list;
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains("Result is not valid")));
    }

    @Test
    void testTransformObservationNullError(){
        Observation observation = new Observation();
        String dummyJSON = "[{\"subject_class_cd\": null}]";

        observation.setObsDomainCdSt1("Order");
        observation.setPersonParticipations(dummyJSON);
        observation.setOrganizationParticipations(dummyJSON);
        observation.setMaterialParticipations(dummyJSON);
        observation.setFollowupObservations(dummyJSON);

        transformer.transformObservationData(observation);

        List<ILoggingEvent> logs = listAppender.list;
        logs.forEach(le -> assertTrue(le.getFormattedMessage().contains("is null")));
    }
}
