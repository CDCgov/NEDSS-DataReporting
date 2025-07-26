package gov.cdc.etldatapipeline.person.model.dto.persondetail;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@Builder
public class EntityData implements ExtendPerson {
    @JsonProperty("entity_uid")
    private Long entityUid;
    private String typeCd;
    private String recordStatusCd;
    private String rootExtensionTxt;
    @JsonProperty("entity_id_seq")
    private Integer entityIdSeq;
    @JsonProperty("assigning_authority_cd")
    private String assigningAuthorityCd;

    public <T extends PersonExtendedProps> T updatePerson(T personFull) {

        if ("SSA".equalsIgnoreCase(assigningAuthorityCd)) {
            personFull.setSsn(rootExtensionTxt);
        } else {
            switch (typeCd.trim().toUpperCase()) {
                case "PN" -> { // Patient Only Data
                    personFull.setPatientNumber(rootExtensionTxt);
                    personFull.setPatientNumberAuth(assigningAuthorityCd);
                }
                case "QEC" -> personFull.setProviderQuickCode(rootExtensionTxt);  // Provider only Data
                case "PRN" -> { // Provider Only Data
                    personFull.setProviderRegistrationNum(rootExtensionTxt);
                    personFull.setProviderRegistrationNumAuth(assigningAuthorityCd);
                }
                case "NPI" -> personFull.setProviderNpi(rootExtensionTxt);  // Provider Only Data
                default -> {
                    // no-op: unsupported typeCd, unreachable
                }
            }
        }
        // ElasticSearch related data
        personFull.setEntityUid(entityUid);
        personFull.setEntityIdSeq(entityIdSeq);
        personFull.setTypeCd(typeCd);
        personFull.setEntityRecordStatusCd(recordStatusCd);
        personFull.setAssigningAuthorityCd(assigningAuthorityCd);
        return personFull;
    }
}
