package gov.cdc.etldatapipeline.person.model.dto.persondetail;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class Email implements ExtendPerson {
    private String emailAddress;
    @JsonProperty("email_elp_use_cd")
    private String useCd;
    @JsonProperty("email_elp_cd")
    private String cd;
    @JsonProperty("email_tl_uid")
    private Long teleLocatorUid;

    public <T extends PersonExtendedProps> T updatePerson(T personFull) {
        personFull.setEmail(emailAddress);
        personFull.setEmailElpCd(cd);
        personFull.setEmailElpUseCd(useCd);
        personFull.setEmailTlUid(teleLocatorUid);
        return personFull;
    }
}
