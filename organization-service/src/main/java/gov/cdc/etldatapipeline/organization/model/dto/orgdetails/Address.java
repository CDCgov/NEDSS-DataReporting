package gov.cdc.etldatapipeline.organization.model.dto.orgdetails;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationElasticSearch;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationReporting;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@ToString(callSuper = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class Address implements OrgExtension {
    private String addrElpCd;
    private String addrElpUseCd;
    private Long addrPlUid;
    private String streetAddr1;
    private String streetAddr2;
    private String city;
    private String zip;
    private String cntyCd;
    private String state;
    private String cntryCd;
    private String state_desc;
    private String county;
    private String withinCityLimitsInd;
    private String country;
    private String addressComments;

    public <T> T updateOrg(T org) {
        if (org.getClass() == OrganizationReporting.class) {
            OrganizationReporting orgRep = (OrganizationReporting) org;
            orgRep.setStreetAddress1(streetAddr1);
            orgRep.setStreetAddress2(streetAddr2);
            orgRep.setCity(city);
            orgRep.setStateCode(state);
            orgRep.setState(state_desc);
            orgRep.setZip(zip);
            orgRep.setCounty(county);
            orgRep.setCountyCode(cntyCd);
            orgRep.setCountry(cntryCd);
            orgRep.setAddressComments(addressComments);
        } else if (org.getClass() == OrganizationElasticSearch.class) {
            OrganizationElasticSearch orgElastic = (OrganizationElasticSearch) org;
            orgElastic.setStreetAddr1(streetAddr1);
            orgElastic.setStreetAddr2(streetAddr2);
            orgElastic.setCity(city);
            orgElastic.setState(state);
            orgElastic.setState(state_desc);
            orgElastic.setZip(zip);
            orgElastic.setCntyCd(cntyCd);
            orgElastic.setCntryCd(cntryCd);
            orgElastic.setAddressComments(addressComments);
            orgElastic.setAddrElpCd(addrElpCd);
            orgElastic.setAddrElpUseCd(addrElpUseCd);
            orgElastic.setAddrPlUid(addrPlUid);
        }
        return org;
    }
}
