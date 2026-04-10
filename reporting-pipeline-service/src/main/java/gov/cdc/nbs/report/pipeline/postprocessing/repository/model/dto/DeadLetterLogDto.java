package gov.cdc.nbs.report.pipeline.postprocessing.repository.model.dto;

import java.sql.Timestamp;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeadLetterLogDto {
  private String id;
  private String originTopic;
  private String payload;
  private String stackTrace;
  private Timestamp receivedAt;
}
