package gov.cdc.etldatapipeline.organization.model.dto.org;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class OrganizationElasticSearch {
    private long organizationUid;
    private String cd;
    private String statusCd;
    private String statusTime;
    private String versionCtrlNbr;
    private String edxInd;
    private String recordStatusTime;
    private String localId;
    @JsonProperty("record_status_cd")
    private String orgRecordStatusCd;
    private String description;
    private String electronicInd;
    private String standIndClass;
    private Long onOrgUid;
    private String organizationName;
    private String typeCd;
    @JsonProperty("recordStatusCd")
    private String entityRecordStatusCd;
    private Long entityUid;
    private String entityIdSeq;
    private String assigningAuthorityCd;
    private String addrElpCd;
    private String addrElpUseCd;
    private Long addrPlUid;
    @JsonProperty("streetAddr1")
    private String streetAddr1;
    @JsonProperty("streetAddr2")
    private String streetAddr2;
    private String city;
    private String stateDesc;
    private String state;
    private String zip;
    @JsonProperty("cntyCd")
    private String cntyCd;
    @JsonProperty("cntryCd")
    private String cntryCd;
    private String addressComments;
    private String phElpCd;
    private String phElpUseCd;
    private Long phTlUid;
    @JsonProperty("telephoneNbr")
    private String telephoneNbr;
    @JsonProperty("extensionTxt")
    private String extensionTxt;
    @JsonProperty("emailAddress")
    private String emailAddress;
    private String phoneComments;
    private String faxElpCd;
    private String faxElpUseCd;
    private Long faxTlUid;
    @JsonProperty("org_fax")
    private String fax;
    private Long addUserId;
    private String addTime;
    private Long lastChgUserId;
    private String lastChgTime;
}
