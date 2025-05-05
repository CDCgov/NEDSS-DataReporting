package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Entity
@Data
public class Vaccination {
    @Id
    @Column(name="vaccination_uid")
    private Long vaccinationUid;

    @Column(name="add_time")
    private String addTime;

    @Column(name="add_user_id")
    private Long addUserId;

    @Column(name="age_at_vaccination")
    private Integer ageAtVaccination;

    @Column(name="age_at_vaccination_unit")
    private String ageAtVaccinationUnit;

    @Column(name="last_chg_time")
    private String lastChgTime;

    @Column(name="last_chg_user_id")
    private Long lastChgUserId;

    @Column(name="local_id")
    private String localId;

    @Column(name="record_status_cd")
    private String recordStatusCd;

    @Column(name="record_status_time")
    private String recordStatusTime;

    @Column(name="status_time")
    private String statusTime;

    @Column(name="prog_area_cd")
    private String progAreaCd;

    @Column(name="jurisdiction_cd")
    private String jurisdictionCd;

    @Column(name="program_jurisdiction_oid")
    private Long programJurisdictionOid;

    @Column(name="vaccine_administered_date")
    private String vaccineAdministeredDate;

    @Column(name="vaccine_dose_nbr")
    private Integer vaccineDoseNbr;

    @Column(name="vaccination_administered_nm")
    private String vaccinationAdministeredNm;

    @Column(name="vaccination_anatomical_site")
    private String vaccinationAnatomicalSite;

    @Column(name="vaccine_expiration_dt")
    private String vaccineExpirationDt;

    @Column(name="vaccine_info_source")
    private String vaccineInfoSource;

    @Column(name="vaccine_lot_number_txt")
    private String vaccineLotNumberTxt;

    @Column(name="vaccine_manufacturer_nm")
    private String vaccineManufacturerNm;

    @Column(name="version_ctrl_nbr")
    private Long versionCtrlNbr;

    @Column(name="electronic_ind")
    private String electronicInd;

    @Column(name="PROVIDER_UID")
    private Long providerUid;

    @Column(name="ORGANIZATION_UID")
    private Long organizationUid;

    @Column(name="PHC_UID")
    private Long phcUid;

    @Column(name="PATIENT_UID")
    private Long patientUid;

    @Column(name="rdb_cols")
    private String rdbCols;

    @Column(name="answers")
    private String answers;

    @Column(name="material_cd")
    private String materialCd;

}
