package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.persistence.Column;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class VaccinationReporting {

    private Long vaccinationUid;
    private String addTime;
    private Long addUserId;
    private Integer ageAtVaccination;
    private String ageAtVaccinationUnit;
    private String lastChgTime;
    private Long lastChgUserId;
    private String localId;
    private String recordStatusCd;
    private String recordStatusTime;
    private String vaccineAdministeredDate;
    private Integer vaccineDoseNbr;
    private String vaccinationAdministeredNm;
    private String vaccinationAnatomicalSite;
    private String vaccineExpirationDt;
    private String vaccineInfoSource;
    private String vaccineLotNumberTxt;
    private String vaccineManufacturerNm;
    private Long versionCtrlNbr;
    private String electronicInd;
}
