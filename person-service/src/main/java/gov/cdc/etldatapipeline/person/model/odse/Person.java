package gov.cdc.etldatapipeline.person.model.odse;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.Column;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@JsonIgnoreProperties(ignoreUnknown = true)
public class Person extends DebeziumMetadata {
    @Column(name = "person_uid")
    @JsonProperty("person_uid")
    private String personUid;
    @Column(name = "cd")
    @JsonProperty("cd")
    private String cd;
}
