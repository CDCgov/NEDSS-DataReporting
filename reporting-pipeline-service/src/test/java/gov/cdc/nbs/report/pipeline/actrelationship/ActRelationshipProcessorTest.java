package gov.cdc.nbs.report.pipeline.actrelationship;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import gov.cdc.nbs.report.pipeline.investigation.service.InvestigationService;
import gov.cdc.nbs.report.pipeline.observation.service.ObservationService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ActRelationshipProcessorTest {

  @Mock private InvestigationService investigationService;

  @Mock private ObservationService observationService;

  @InjectMocks private ActRelationshipProcessor processor;

  @Test
  void does_not_process_null_message() {
    // given a null message
    String message = null;
    long batchId = 1l;

    // when the processer is called
    processor.process(message, batchId);

    // no processing occurs
    verifyNoInteractions(investigationService, observationService);
  }

  @Test
  void does_not_process_tombstone_message() {
    // given a message with no payload
    String message =
        """
        {
        }
        """;
    long batchId = 1l;

    // when the processer is called
    processor.process(message, batchId);

    // no processing occurs
    verifyNoInteractions(investigationService, observationService);
  }

  @ParameterizedTest
  @CsvSource({
    // all operations for 1180
    "c,1180,true",
    "r,1180,true",
    "u,1180,true",
    "d,1180,true",
    // no operations for other type_cd
    "c,2180,false",
    "r,2180,false",
    "u,2180,false",
    "d,2180,false"
  })
  void processes_vaccinations(String operation, int typeCd, boolean shouldProcess) {
    // given a message for a vaccination
    String message =
        """
        {
        "payload": {
        "before": {
            "source_act_uid": "3",
            "type_cd": %d
          },
          "after": {
            "source_act_uid": "3",
            "type_cd": %d
          },
          "op": "%s"
          }
        }
        """
            .formatted(typeCd, typeCd, operation);
    long batchId = 1l;

    // when the processor is called
    processor.process(message, batchId);

    // then the investigation service processes the vaccination
    verifyNoInteractions(observationService);
    if (shouldProcess) {
      verify(investigationService).processVaccination(message, false, "3");
    } else {
      verifyNoInteractions(investigationService);
    }
  }

  @ParameterizedTest
  @CsvSource({
    // all operations for TreatmentToPHC
    "c,TreatmentToPHC,true",
    "r,TreatmentToPHC,true",
    "u,TreatmentToPHC,true",
    "d,TreatmentToPHC,true",
    // all operations for TreatmentToMorb
    "c,TreatmentToMorb,true",
    "r,TreatmentToMorb,true",
    "u,TreatmentToMorb,true",
    "d,TreatmentToMorb,true",
    // no operations for other type_cd
    "c,NotATreatment,false",
    "r,NotATreatment,false",
    "u,NotATreatment,false",
    "d,NotATreatment,false",
  })
  void processes_treatments(String operation, String typeCd, boolean shouldProcess) {
    // given a message for a vaccination
    String message =
        """
        {
        "payload": {
        "before": {
            "source_act_uid": "3",
            "type_cd": "%s"
          },
          "after": {
            "source_act_uid": "3",
            "type_cd": "%s"
          },
          "op": "%s"
          }
        }
        """
            .formatted(typeCd, typeCd, operation);
    long batchId = 1l;

    // when the processor is called
    processor.process(message, batchId);

    // then the investigation service processes the vaccination
    verifyNoInteractions(observationService);
    if (shouldProcess) {
      verify(investigationService).processTreatment(message, false, "3");
    } else {
      verifyNoInteractions(investigationService);
    }
  }

  @ParameterizedTest
  @CsvSource({
    // negative cases
    "c,LabReport,OBS,false",
    "r,LabReport,OBS,false",
    "u,LabReport,OBS,false",
    "d,LabReport,BBB,false",
    "d,OtherReport,OBS,false",

    // only processes for "d" operations with type_cd LabReport and target_class_cd OBS
    "d,LabReport,OBS,true"
  })
  void processes_observations(
      String operation, String typeCd, String targetClassCd, boolean shouldProcess) {
    // given a message for an observation
    String message =
        """
        {
        "payload": {
        "before": {
            "source_act_uid": "3",
            "type_cd": "%s",
            "target_class_cd": "%s"
          },
          "after": {
            "source_act_uid": "3",
            "type_cd": "%s",
            "target_class_cd": "%s"
          },
          "op": "%s"
          }
        }
        """
            .formatted(typeCd, targetClassCd, typeCd, targetClassCd, operation);
    long batchId = 1l;

    // when the processor is called
    processor.process(message, batchId);

    // then the investigation service processes the vaccination
    verifyNoInteractions(investigationService);
    if (shouldProcess) {
      verify(observationService).processObservation(message, batchId, false, "3");
    } else {
      verifyNoInteractions(observationService);
    }
  }

  // TODO exception throwing
  // TODO getSourceActUid
  // TODO getTypeCd
  // TODO InvestigationServiceTest
  // TODO ObservationServiceTest
}
