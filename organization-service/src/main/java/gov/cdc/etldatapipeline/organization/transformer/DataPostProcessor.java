package gov.cdc.etldatapipeline.organization.transformer;

import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationElasticSearch;
import gov.cdc.etldatapipeline.organization.model.dto.orgdetails.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.util.ObjectUtils;
import org.springframework.util.StringUtils;

import java.util.Arrays;
import java.util.Comparator;
import java.util.function.Function;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.deserializePayload;
import static java.util.Objects.requireNonNull;

@Slf4j
public class DataPostProcessor {
    public <T> void processOrgName(String name, T org) {
        if (!ObjectUtils.isEmpty(name)) {
            Arrays.stream(requireNonNull(deserializePayload(name, Name[].class)))
                    .filter(oName -> !ObjectUtils.isEmpty(oName.getOnOrgUid()))
                    .max(Comparator.comparing(Name::getOnOrgUid))
                    .ifPresent(n -> n.updateOrg(org));
        }
    }

    public <T> void processOrgEntity(String entity, T org) {

        if (!ObjectUtils.isEmpty(entity)) {
            if (org.getClass() == OrganizationElasticSearch.class) {
                // ToDo: Entity Data for Organization Elastic search gets the max Entity Id and processes them.
                //  Revisit after clarification from the Features team.
                Arrays.stream(requireNonNull(deserializePayload(entity, Entity[].class)))
                        .filter(oEntity -> !ObjectUtils.isEmpty(oEntity.getEntityIdSeq()))
                        .max(Comparator.comparing(Entity::getEntityIdSeq))
                        .ifPresent(n -> n.updateOrg(org));
            } else {
                Function<String, T> entityFn =
                        (String typeCd) ->
                                Arrays.stream(requireNonNull(deserializePayload(entity, Entity[].class)))
                                        .filter(e -> !ObjectUtils.isEmpty(e.getEntityIdSeq())
                                                && StringUtils.hasText(e.getTypeCd())
                                                && e.getTypeCd().equalsIgnoreCase(typeCd))
                                        .max(Comparator.comparing(Entity::getEntityIdSeq))
                                        .map(n -> n.updateOrg(org))
                                        .orElse(null);
                entityFn.apply("QEC"); // Quick Code
                entityFn.apply("FI"); // Facility Id
            }
        }
    }

    public <T> void processOrgAddress(String address, T org) {
        if (!ObjectUtils.isEmpty(address)) {
            Arrays.stream(requireNonNull(deserializePayload(address, Address[].class)))
                    .filter(oAddr -> !ObjectUtils.isEmpty(oAddr.getAddrPlUid()))
                    .max(Comparator.comparing(Address::getAddrPlUid))
                    .ifPresent(n -> n.updateOrg(org));
        }
    }

    public <T> void processOrgPhone(String phone, T org) {
        if (!ObjectUtils.isEmpty(phone)) {
            Arrays.stream(requireNonNull(deserializePayload(phone, Phone[].class)))
                    .filter(oPhone -> !ObjectUtils.isEmpty(oPhone.getPhTlUid()))
                    .max(Comparator.comparing(Phone::getPhTlUid))
                    .ifPresent(n -> n.updateOrg(org));
        }
    }

    public <T> void processOrgFax(String fax, T org) {
        if (!ObjectUtils.isEmpty(fax)) {
            Arrays.stream(requireNonNull(deserializePayload(fax, Fax[].class)))
                    .filter(oPhone -> !ObjectUtils.isEmpty(oPhone.getFaxTlUid()))
                    .max(Comparator.comparing(Fax::getFaxTlUid))
                    .ifPresent(n -> n.updateOrg(org));
        }
    }
}
