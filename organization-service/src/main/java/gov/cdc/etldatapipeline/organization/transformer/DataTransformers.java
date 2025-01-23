package gov.cdc.etldatapipeline.organization.transformer;

import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationElasticSearch;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationKey;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationReporting;
import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationSp;
import gov.cdc.etldatapipeline.organization.model.dto.place.*;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DataTransformers {
    public static final String PLACE_UID = "place_uid";
    public static final String PLACE_TL_UID = "place_tele_locator_uid";

    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();
    private static final DataPostProcessor processor = new DataPostProcessor();

    public String buildOrganizationKey(OrganizationSp p) {
        return jsonGenerator.generateStringJson(OrganizationKey.builder().organizationUid(p.getOrganizationUid()).build());
    }

    public String buildPlaceKey(Place p) {
        return jsonGenerator.generateStringJson(PlaceKey.builder().placeUid(p.getPlaceUid()).build(), PLACE_UID);
    }

    public String buildPlaceTeleKey(PlaceTele p) {
        return jsonGenerator.generateStringJson(PlaceTeleKey.builder().placeTeleLocatorUid(p.getPlaceTeleLocatorUid()).build(), PLACE_TL_UID);
    }

    public String processData(OrganizationSp organizationSp, OrganizationType organizationType) {
        return jsonGenerator.generateStringJson(buildTransformedObject(organizationSp, organizationType));
    }

    public String processData(Place place) {
        return jsonGenerator.generateStringJson(buildPlaceReporting(place), PLACE_UID);
    }

    public String processData(PlaceTele tele) {
        return jsonGenerator.generateStringJson(tele, PLACE_UID, PLACE_TL_UID);
    }

    public List<PlaceTele> buildPlaceTele(String teleData) {
        return processor.processArrayData(teleData, PlaceTele[].class);
    }

    public Object buildTransformedObject(OrganizationSp organizationSp, OrganizationType organizationType) {
        Object transformedObj =
                switch (organizationType) {
                    case ORGANIZATION_REPORTING -> buildOrganizationReporting(organizationSp);
                    case ORGANIZATION_ELASTIC_SEARCH -> buildOrganizationElasticSearch(organizationSp);
                };

        processor.processOrgAddress(organizationSp.getOrganizationAddress(), transformedObj);
        processor.processOrgPhone(organizationSp.getOrganizationTelephone(), transformedObj);
        processor.processOrgFax(organizationSp.getOrganizationFax(), transformedObj);
        processor.processOrgEntity(organizationSp.getOrganizationEntityId(), transformedObj);
        processor.processOrgName(organizationSp.getOrganizationName(), transformedObj);
        return transformedObj;
    }

    private OrganizationElasticSearch buildOrganizationElasticSearch(OrganizationSp orgSp) {
        return OrganizationElasticSearch.builder()
                .organizationUid(orgSp.getOrganizationUid())
                .cd(orgSp.getCd())
                .statusCd(orgSp.getStatusCd())
                .statusTime(orgSp.getStatusTime())
                .versionCtrlNbr(orgSp.getVersionCtrlNbr())
                .edxInd(orgSp.getEdxInd())
                .recordStatusTime(orgSp.getRecordStatusTime())
                .localId(orgSp.getLocalId())
                .orgRecordStatusCd(orgSp.getRecordStatusCd())
                .description(orgSp.getDescription())
                .electronicInd(orgSp.getElectronicInd())
                .standIndClass(orgSp.getStandIndClass())
                .addUserId(orgSp.getAddUserId())
                .addTime(orgSp.getAddTime())
                .lastChgUserId(orgSp.getLastChgUserId())
                .lastChgTime(orgSp.getLastChgTime())
                .build();
    }

    private OrganizationReporting buildOrganizationReporting(OrganizationSp orgSp) {
        return OrganizationReporting.builder()
                .organizationUid(orgSp.getOrganizationUid())
                .localId(orgSp.getLocalId())
                .recordStatus(orgSp.getRecordStatusCd())
                .generalComments(orgSp.getDescription())
                .entryMethod(orgSp.getElectronicInd())
                .standIndClass(orgSp.getStandIndClass())
                .organizationName(orgSp.getOrganizationName())
                .addTime(orgSp.getAddTime())
                .addUserId(orgSp.getAddUserId())
                .lastChgUserId(orgSp.getLastChgUserId())
                .lastChgTime(orgSp.getLastChgTime())
                .addUserName(orgSp.getAddUserName())
                .lastChgUserName(orgSp.getLastChgUserName())
                .build();
    }

    private PlaceReporting buildPlaceReporting(Place place) {
        PlaceReporting placeRep = PlaceReporting.builder()
                .placeUid(place.getPlaceUid())
                .cd(place.getCd())
                .placeTypeDescription(place.getPlaceTypeDescription())
                .placeLocalId(place.getPlaceLocalId())
                .placeName(place.getPlaceName())
                .placeGeneralComments(place.getPlaceGeneralComments())
                .placeAddTime(place.getPlaceAddTime())
                .placeAddUserId(place.getPlaceAddUserId())
                .placeLastChangeTime(place.getPlaceLastChangeTime())
                .placeLastChgUserId(place.getPlaceLastChgUserId())
                .placeRecordStatus(place.getPlaceRecordStatus())
                .placeRecordStatusTime(place.getPlaceRecordStatusTime())
                .placeStatusCd(place.getPlaceStatusCd())
                .placeStatusTime(place.getPlaceStatusTime())
                .build();

        processor.processPlaceEntity(place.getPlaceEntity(), placeRep);
        processor.processPlaceAddress(place.getPlaceAddress(), placeRep);
        return placeRep;
    }
}
