package gov.cdc.nbs.report.pipeline.observation.model.dto.observation;

import java.util.ArrayList;
import java.util.List;

/**
 * Output of the ObservationTransformer that contains the ObservationTransformed object as well as
 * lists of entites that need to be persisted to the database
 */
public record ParsedObservation(
    ObservationTransformed transformed,
    List<ObservationMaterial> materialEntries,
    List<ObservationCoded> codedEntries,
    List<ObservationDate> dateEntries,
    List<ObservationEdx> edxEntries,
    List<ObservationNumeric> numericEntries,
    List<ObservationReason> reasonEntries,
    List<ObservationTxt> textEntries) {
  public ParsedObservation(ObservationTransformed observationTransformed) {
    this(
        observationTransformed,
        new ArrayList<>(),
        new ArrayList<>(),
        new ArrayList<>(),
        new ArrayList<>(),
        new ArrayList<>(),
        new ArrayList<>(),
        new ArrayList<>());
  }
}
