package gov.cdc.etldatapipeline.person.model.dto.persondetail;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.util.StringUtils;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class Phone implements ExtendPerson {
    private String telephoneNbr;
    private String extensionTxt;
    @JsonProperty("ph_elp_use_cd")
    private String useCd;
    @JsonProperty("ph_elp_cd")
    private String cd;
    @JsonProperty("ph_tl_uid")
    private Long teleLocatorUid;
    @JsonProperty("phone_comments")
    private String phoneComments;

    public <T extends PersonExtendedProps> T updatePerson(T personFull) {
        personFull.setPhElpCd(cd);
        personFull.setPhElpUseCd(useCd);
        personFull.setPhTlUid(teleLocatorUid);
        if (StringUtils.hasText(useCd)) {
            if (useCd.equalsIgnoreCase("WP")) {
                personFull.setPhoneWork(telephoneNbr);
                personFull.setPhoneExtWork(extensionTxt);
                personFull.setPhoneComments(phoneComments);
            } else if (useCd.equalsIgnoreCase("H")) {
                personFull.setPhoneHome(telephoneNbr);
                personFull.setPhoneExtHome(extensionTxt);
            }
        }
        if (StringUtils.hasText(cd))  {
            if (cd.equalsIgnoreCase("CP")) {
                personFull.setPhoneCell(telephoneNbr);
            }
        }
        return personFull;
    }
}