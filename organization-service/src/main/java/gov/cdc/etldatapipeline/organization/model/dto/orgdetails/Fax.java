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
public class Fax implements OrgExtension {
    private Long faxTlUid;
    private String faxElpCd;
    private String faxElpUseCd;
    private String orgFax;

    public <T> T updateOrg(T org) {
        if (org.getClass() == OrganizationReporting.class) {
            OrganizationReporting orgReporting = (OrganizationReporting) org;
            orgReporting.setFax(orgFax);
        } else if (org.getClass() == OrganizationElasticSearch.class) {
            OrganizationElasticSearch orgElastic = (OrganizationElasticSearch) org;
            orgElastic.setFaxTlUid(faxTlUid);
            orgElastic.setFaxElpCd(faxElpCd);
            orgElastic.setFaxElpUseCd(faxElpUseCd);
            orgElastic.setFax(orgFax);
        }
        return org;
    }
}
