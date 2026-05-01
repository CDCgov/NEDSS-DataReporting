package gov.cdc.nbs.report.pipeline.observation.model.dto.observation;

import com.fasterxml.jackson.annotation.JsonProperty;

public record ObservationKey(@JsonProperty("observation_uid") Long observationUid) {}
