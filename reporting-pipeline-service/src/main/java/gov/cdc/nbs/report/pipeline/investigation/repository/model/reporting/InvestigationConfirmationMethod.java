package gov.cdc.nbs.report.pipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class InvestigationConfirmationMethod {
  private Long publicHealthCaseUid;
  private String confirmationMethodCd;
  private String confirmationMethodDescTxt;
  private String confirmationMethodTime;
  private Long batchId;
}
