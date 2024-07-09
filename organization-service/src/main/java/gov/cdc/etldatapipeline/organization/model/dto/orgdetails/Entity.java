package gov.cdc.etldatapipeline.organization.model.dto.orgdetails;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationElasticSearch;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationReporting;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.util.StringUtils;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class Entity implements OrgExtension {
    private Long entityUid;
    private String typeCd;
    private String recordStatusCd;
    private String rootExtensionTxt;
    private String entityIdSeq;
    private String assigningAuthorityCd;

    public <T> T updateOrg(T org) {
        if (org.getClass() == OrganizationReporting.class) {
            OrganizationReporting orgReporting = (OrganizationReporting) org;
            if (StringUtils.hasText(typeCd)) {
                if (typeCd.equalsIgnoreCase("QEC")) { // Quick Code
                    orgReporting.setQuickCode(rootExtensionTxt);
                } else if (typeCd.equalsIgnoreCase("FI")) { // Facility ID
                    orgReporting.setFacilityId(rootExtensionTxt);
                    orgReporting.setFacilityIdAuth(assigningAuthorityCd);
                }
            }
        } else if (org.getClass() == OrganizationElasticSearch.class) {
            OrganizationElasticSearch orgElastic = (OrganizationElasticSearch) org;
            orgElastic.setTypeCd(typeCd);
            orgElastic.setEntityRecordStatusCd(recordStatusCd);
            orgElastic.setEntityUid(entityUid);
            orgElastic.setEntityIdSeq(entityIdSeq);
            orgElastic.setAssigningAuthorityCd(assigningAuthorityCd);
        }
        return org;
    }
}
