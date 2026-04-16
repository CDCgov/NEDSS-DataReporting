package gov.cdc.nbs.report.pipeline.observation.model.dto.observation;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.NonNull;

public record ObservationMaterialKey(@NonNull @JsonProperty("material_id") Long materialId) {}
