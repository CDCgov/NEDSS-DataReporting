package gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.sql.Timestamp;

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
