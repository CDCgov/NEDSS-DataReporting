package gov.cdc.etldatapipeline.reportinghydration.investigation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;


@Data
@NoArgsConstructor
public class InvestigationNotificationKey {

    @NonNull
    @JsonProperty("notification_uid")
    private Long notificationUid;
}
