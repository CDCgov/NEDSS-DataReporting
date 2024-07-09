package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;


@Data
@NoArgsConstructor
public class InvestigationNotificationsKey {

    @NonNull
    @JsonProperty("notification_uid")
    private Long notificationUid;
}
