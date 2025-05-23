package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

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
    private String statusTime;
    private String progAreaCd;
    private String jurisdictionCd;
    private Long programJurisdictionOid;
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
    private Long providerUid;
    private Long organizationUid;
    private Long phcUid;
    private Long patientUid;
    private String materialCd;
}
