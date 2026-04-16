package gov.cdc.nbs.report.pipeline.observation.model.dto.observation;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record ObservationCodedKey(Long observationUid, String ovcCode) {}
