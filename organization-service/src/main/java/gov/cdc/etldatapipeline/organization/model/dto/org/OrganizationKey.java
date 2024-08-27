package gov.cdc.etldatapipeline.organization.model.dto.org;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class OrganizationKey {
    @NonNull
    @JsonProperty("organization_uid")
    private Long organizationUid;
}
