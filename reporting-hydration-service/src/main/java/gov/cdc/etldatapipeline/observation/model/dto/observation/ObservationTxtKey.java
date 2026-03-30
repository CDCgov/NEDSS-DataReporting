package gov.cdc.etldatapipeline.observation.model.dto.observation;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ObservationTxtKey {
  private Long observationUid;
  private Integer ovtSeq;
}
