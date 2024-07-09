package gov.cdc.etldatapipeline.organization.model.odse;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.Column;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@JsonIgnoreProperties(ignoreUnknown = true)
public class Organization extends DebeziumMetadata {
    @Column(name = "organization_uid")
    @JsonProperty("organization_uid")
    private String organizationUid;
}
