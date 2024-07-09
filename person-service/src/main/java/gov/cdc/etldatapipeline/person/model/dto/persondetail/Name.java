package gov.cdc.etldatapipeline.person.model.dto.persondetail;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Objects;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class Name implements ExtendPerson {
    private String lastNm;
    private String lastNmSndx;
    private String middleNm;
    private String firstNm;
    private String firstNmSndx;
    @JsonProperty("nm_use_cd")
    private String nmUseCd;
    private String nmSuffix;
    private String nmPrefix;
    private String nmDegree;
    @JsonProperty("pn_person_uid")
    private Long personUid;
    @JsonProperty("pn_person_name_seq")
    private String personNmSeq;
    @JsonProperty("pn_last_chg_time")
    private String lastChgTime;

    public <T extends PersonExtendedProps> T updatePerson(T person) {
        person.setLastNm(this.lastNm);
        person.setMiddleNm(this.middleNm);
        person.setFirstNm(this.firstNm);
        person.setNmSuffix(this.nmSuffix);
        person.setNmPrefix(this.nmPrefix);
        person.setPnPersonUid(this.personUid);
        person.setPersonNmSeq(this.personNmSeq);
        person.setNmUseCd(this.nmUseCd);
        person.setNmDegree(this.nmDegree);
        return person;
    }

    public <T extends PersonExtendedProps> T updatePerson(T person, String cd) {
        if (Objects.equals(cd, NameUseCd.LEGAL.getVal()))
            updatePerson(person);
        if (Objects.equals(cd, NameUseCd.ALIAS.getVal()))
            person.setAliasNickname(firstNm);
        return person;
    }
}
