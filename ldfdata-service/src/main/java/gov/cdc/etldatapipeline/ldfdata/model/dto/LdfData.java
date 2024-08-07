package gov.cdc.etldatapipeline.ldfdata.model.dto;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

import java.time.Instant;

@Entity
@Data
public class LdfData {
    @Id
    @Column(name = "ldf_uid")
    private Long ldfUid;

    @Column(name = "active_ind")
    private String activeInd;

    @Column(name = "ldf_meta_data_add_time")
    private Instant ldfMetaDataAddTime;

    @Column(name = "admin_comment")
    private String adminComment;

    @Column(name = "ldf_meta_data_business_object_nm")
    private String ldfMetaDataBusinessObjectNm;

    @Column(name = "category_type")
    private String categoryType;

    @Column(name = "cdc_national_id")
    private String cdcNationalId;

    @Column(name = "class_cd")
    private String classCd;

    @Column(name = "code_set_nm")
    private String codeSetNm;

    @Column(name = "condition_cd")
    private String conditionCd;

    @Column(name = "condition_desc_txt")
    private String conditionDescTxt;

    @Column(name = "data_type")
    private String dataType;

    @Column(name = "deployment_cd")
    private String deploymentCd;

    @Column(name = "display_order_nbr")
    private Integer displayOrderNbr;

    @Column(name = "field_size")
    private String fieldSize;

    @Column(name = "label_txt")
    private String labelTxt;

    @Column(name = "ldf_page_id")
    private String ldfPageId;

    @Column(name = "required_ind")
    private String requiredInd;

    @Column(name = "state_cd")
    private String stateCd;

    @Column(name = "validation_txt")
    private String validationTxt;

    @Column(name = "validation_jscript_txt")
    private String validationJscriptTxt;

    @Column(name = "record_status_time")
    private Instant recordStatusTime;

    @Column(name = "record_status_cd")
    private String recordStatusCd;

    @Column(name = "custom_subform_metadata_uid")
    private Long customSubformMetadataUid;

    @Column(name = "html_tag")
    private String htmlTag;

    @Column(name = "import_version_nbr")
    private Long importVersionNbr;

    @Column(name = "nnd_ind")
    private String nndInd;

    @Column(name = "ldf_oid")
    private String ldfOid;

    @Column(name = "ldf_meta_data_version_ctrl_num")
    private Integer ldfMetaDataVersionCtrlNum;

    @Column(name = "NBS_QUESTION_UID")
    private Long nbsQuestionUid;

    @Column(name = "business_object_uid")
    private Long businessObjectUid;

    @Column(name = "ldf_data_field_add_time")
    private Instant ldfDataFieldAddTime;

    @Column(name = "ldf_field_data_business_object_nm")
    private String ldfFieldDataBusinessObjectNm;

    @Column(name = "ldf_data_last_chg_time")
    private Instant ldfDataLastChgTime;

    @Column(name = "ldf_value")
    private String ldfValue;

    @Column(name = "ldf_field_data_version_ctrl_num")
    private Integer ldfFieldDataVersionCtrlNum;

    @Column(name = "LDF_COLUMN_TYPE")
    private String ldfColumnType;
}
