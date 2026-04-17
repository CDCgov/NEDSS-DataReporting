package gov.cdc.nbs.report.pipeline.observation.service.observation;

import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationCoded;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationDate;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationEdx;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationMaterial;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationNumeric;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationReason;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationTxt;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ParsedObservation;
import java.util.List;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Responsible for writing Observation data to the following tables:
 *
 * <ul>
 *   <li>nrt_observation_material
 *   <li>nrt_observation_coded
 *   <li>nrt_observation_date
 *   <li>nrt_observation_edx
 *   <li>nrt_observation_numeric
 *   <li>nrt_observation_reason
 *   <li>nrt_observation_txt
 * </ul>
 */
@Component
public class NrtObservationWriter {

  private final JdbcClient client;

  public NrtObservationWriter(final JdbcClient client) {
    this.client = client;
  }

  public void persist(ParsedObservation parsedObservation) {
    persistMaterials(parsedObservation.materialEntries());
    persistCoded(parsedObservation.codedEntries());
    persistDate(parsedObservation.dateEntries());
    persistEdx(parsedObservation.edxEntries());
    persistNumeric(parsedObservation.numericEntries());
    persistReason(parsedObservation.reasonEntries());
    persistText(parsedObservation.textEntries());
  }

  private static final String UPSERT_MATERIAL =
      """
      MERGE INTO nrt_observation_material
      USING (
        SELECT
          :act_uid AS act_uid,
          :material_id AS material_id,
          :type_cd AS type_cd,
          :subject_class_cd AS subject_class_cd,
          :record_status AS record_status,
          :type_desc_txt AS type_desc_txt,
          :last_chg_time AS last_chg_time,
          :material_cd AS material_cd,
          :material_nm AS material_nm,
          :material_details AS material_details,
          :material_collection_vol AS material_collection_vol,
          :material_collection_vol_unit AS material_collection_vol_unit,
          :material_desc AS material_desc,
          :risk_cd AS risk_cd,
          :risk_desc_txt AS risk_desc_txt
      ) AS source
       ON nrt_observation_material.act_uid = source.act_uid AND nrt_observation_material.material_id = source.material_id
      WHEN MATCHED THEN
        UPDATE SET
          type_cd = source.type_cd,
          subject_class_cd = source.subject_class_cd,
          record_status = source.record_status,
          type_desc_txt = source.type_desc_txt,
          last_chg_time = source.last_chg_time,
          material_cd = source.material_cd,
          material_nm = source.material_nm,
          material_details = source.material_details,
          material_collection_vol = source.material_collection_vol,
          material_collection_vol_unit = source.material_collection_vol_unit,
          material_desc = source.material_desc,
          risk_cd = source.risk_cd,
          risk_desc_txt = source.risk_desc_txt
        WHEN NOT MATCHED THEN
        INSERT(
          act_uid,
          type_cd,
          material_id,
          subject_class_cd,
          record_status,
          type_desc_txt,
          last_chg_time,
          material_cd,
          material_nm,
          material_details,
          material_collection_vol,
          material_collection_vol_unit,
          material_desc,
          risk_cd,
          risk_desc_txt
        ) VALUES (
          source.act_uid,
          source.type_cd,
          source.material_id,
          source.subject_class_cd,
          source.record_status,
          source.type_desc_txt,
          source.last_chg_time,
          source.material_cd,
          source.material_nm,
          source.material_details,
          source.material_collection_vol,
          source.material_collection_vol_unit,
          source.material_desc,
          source.risk_cd,
          source.risk_desc_txt
        );
      """;

  private void persistMaterials(List<ObservationMaterial> materials) {
    materials.forEach(
        m ->
            client
                .sql(UPSERT_MATERIAL)
                .param("act_uid", m.getActUid())
                .param("material_id", m.getMaterialId())
                .param("type_cd", m.getTypeCd())
                .param("subject_class_cd", m.getSubjectClassCd())
                .param("record_status", m.getRecordStatus())
                .param("type_desc_txt", m.getTypeDescTxt())
                .param("last_chg_time", m.getLastChgTime())
                .param("material_cd", m.getMaterialCd())
                .param("material_nm", m.getMaterialNm())
                .param("material_details", m.getMaterialDetails())
                .param("material_collection_vol", m.getMaterialCollectionVol())
                .param("material_collection_vol_unit", m.getMaterialCollectionVolUnit())
                .param("material_desc", m.getMaterialDesc())
                .param("risk_cd", m.getRiskCd())
                .param("risk_desc_txt", m.getRiskDescTxt())
                .update());
  }

  private static final String UPSERT_CODED =
      """
      MERGE INTO nrt_observation_coded
      USING (
        SELECT
          :observation_uid AS observation_uid,
          :ovc_code AS ovc_code,
          :ovc_code_system_cd AS ovc_code_system_cd,
          :ovc_code_system_desc_txt AS ovc_code_system_desc_txt,
          :ovc_display_name AS ovc_display_name,
          :ovc_alt_cd AS ovc_alt_cd,
          :ovc_alt_cd_desc_txt AS ovc_alt_cd_desc_txt,
          :ovc_alt_cd_system_cd AS ovc_alt_cd_system_cd,
          :ovc_alt_cd_system_desc_txt AS ovc_alt_cd_system_desc_txt,
          :batch_id AS batch_id
      ) AS source
       ON nrt_observation_coded.observation_uid = source.observation_uid AND nrt_observation_coded.ovc_code = source.ovc_code
      WHEN MATCHED THEN
        UPDATE SET
          observation_uid = source.observation_uid,
          ovc_code = source.ovc_code,
          ovc_code_system_cd = source.ovc_code_system_cd,
          ovc_code_system_desc_txt = source.ovc_code_system_desc_txt,
          ovc_display_name = source.ovc_display_name,
          ovc_alt_cd = source.ovc_alt_cd,
          ovc_alt_cd_desc_txt = source.ovc_alt_cd_desc_txt,
          ovc_alt_cd_system_cd = source.ovc_alt_cd_system_cd,
          ovc_alt_cd_system_desc_txt = source.ovc_alt_cd_system_desc_txt,
          batch_id = source.batch_id
      WHEN NOT MATCHED THEN
      INSERT (
        observation_uid,
        ovc_code,
        ovc_code_system_cd,
        ovc_code_system_desc_txt,
        ovc_display_name,
        ovc_alt_cd,
        ovc_alt_cd_desc_txt,
        ovc_alt_cd_system_cd,
        ovc_alt_cd_system_desc_txt,
        batch_id
      ) VALUES (
        source.observation_uid,
        source.ovc_code,
        source.ovc_code_system_cd,
        source.ovc_code_system_desc_txt,
        source.ovc_display_name,
        source.ovc_alt_cd,
        source.ovc_alt_cd_desc_txt,
        source.ovc_alt_cd_system_cd,
        source.ovc_alt_cd_system_desc_txt,
        source.batch_id
      );
      """;

  private void persistCoded(List<ObservationCoded> codedEntries) {
    codedEntries.forEach(
        c ->
            client
                .sql(UPSERT_CODED)
                .param("observation_uid", c.getObservationUid())
                .param("ovc_code", c.getOvcCode())
                .param("ovc_code_system_cd", c.getOvcCodeSystemCd())
                .param("ovc_code_system_desc_txt", c.getOvcCodeSystemDescTxt())
                .param("ovc_display_name", c.getOvcDisplayName())
                .param("ovc_alt_cd", c.getOvcAltCd())
                .param("ovc_alt_cd_desc_txt", c.getOvcAltCdDescTxt())
                .param("ovc_alt_cd_system_cd", c.getOvcAltCdSystemCd())
                .param("ovc_alt_cd_system_desc_txt", c.getOvcAltCdSystemDescTxt())
                .param("batch_id", c.getBatchId())
                .update());
  }

  private static final String UPSERT_DATE =
      """
      MERGE INTO nrt_observation_date
      USING (
        SELECT
          :observation_uid AS observation_uid,
          :ovd_from_date AS ovd_from_date,
          :ovd_to_date AS ovd_to_date,
          :ovd_seq AS ovd_seq,
          :batch_id AS batch_id
      ) AS source
       ON nrt_observation_date.observation_uid = source.observation_uid
      WHEN MATCHED THEN
        UPDATE SET
          observation_uid = source.observation_uid,
          ovd_from_date = source.ovd_from_date,
          ovd_to_date = source.ovd_to_date,
          ovd_seq = source.ovd_seq,
          batch_id = source.batch_id
      WHEN NOT MATCHED THEN
      INSERT (
        observation_uid,
        ovd_from_date,
        ovd_to_date,
        ovd_seq,
        batch_id
      ) VALUES (
        source.observation_uid,
        source.ovd_from_date,
        source.ovd_to_date,
        source.ovd_seq,
        source.batch_id
      );
      """;

  private void persistDate(List<ObservationDate> dateEntries) {
    dateEntries.forEach(
        d ->
            client
                .sql(UPSERT_DATE)
                .param("observation_uid", d.getObservationUid())
                .param("ovd_from_date", d.getOvdFromDate())
                .param("ovd_to_date", d.getOvdToDate())
                .param("ovd_seq", d.getOvdSeq())
                .param("batch_id", d.getBatchId())
                .update());
  }

  private static final String UPSERT_EDX =
      """
      MERGE INTO nrt_observation_edx
      USING (
        SELECT
        :edx_document_uid AS edx_document_uid,
        :edx_act_uid AS edx_act_uid,
        :edx_add_time AS edx_add_time
      ) AS source
       ON nrt_observation_edx.edx_document_uid = source.edx_document_uid AND nrt_observation_edx.edx_act_uid = source.edx_act_uid
      WHEN MATCHED THEN
        UPDATE SET
          edx_document_uid = source.edx_document_uid,
          edx_act_uid = source.edx_act_uid,
          edx_add_time = source.edx_add_time
      WHEN NOT MATCHED THEN
      INSERT (
        edx_document_uid,
        edx_act_uid,
        edx_add_time
      ) VALUES (
        source.edx_document_uid,
        source.edx_act_uid,
        source.edx_add_time
      );
      """;

  private void persistEdx(List<ObservationEdx> edxEntries) {
    edxEntries.forEach(
        e ->
            client
                .sql(UPSERT_EDX)
                .param("edx_document_uid", e.getEdxDocumentUid())
                .param("edx_act_uid", e.getEdxActUid())
                .param("edx_add_time", e.getEdxAddTime())
                .param("batch_id", e.getBatchId())
                .update());
  }

  private static final String UPSERT_NUMERIC =
      """
      MERGE INTO nrt_observation_edx
      USING (
        SELECT
          :observation_uid AS observation_uid,
          :ovn_high_range AS ovn_high_range,
          :ovn_low_range AS ovn_low_range,
          :ovn_comparator_cd_1 AS ovn_comparator_cd_1,
          :ovn_numeric_value_1 AS ovn_numeric_value_1,
          :ovn_numeric_value_2 AS ovn_numeric_value_2,
          :ovn_numeric_unit_cd AS ovn_numeric_unit_cd,
          :ovn_separator_cd AS ovn_separator_cd,
          :ovn_seq AS ovn_seq,
          :batch_id AS batch_id
      ) AS source
       ON nrt_observation_edx.observation_uid = source.observation_uid AND nrt_observation_edx.ovn_seq = source.ovn_seq
      WHEN MATCHED THEN
        UPDATE SET
          observation_uid = source.observation_uid,
          ovn_high_range = source.ovn_high_range,
          ovn_low_range = source.ovn_low_range,
          ovn_comparator_cd_1 = source.ovn_comparator_cd_1,
          ovn_numeric_value_1 = source.ovn_numeric_value_1,
          ovn_numeric_value_2 = source.ovn_numeric_value_2,
          ovn_numeric_unit_cd = source.ovn_numeric_unit_cd,
          ovn_separator_cd = source.ovn_separator_cd,
          ovn_seq = source.ovn_seq,
          batch_id = source.batch_id
      WHEN NOT MATCHED THEN
      INSERT (
        observation_uid,
        ovn_high_range,
        ovn_low_range,
        ovn_comparator_cd_1,
        ovn_numeric_value_1,
        ovn_numeric_value_2,
        ovn_numeric_unit_cd,
        ovn_separator_cd,
        ovn_seq,
        batch_id
      ) VALUES (
        source.observation_uid,
        source.ovn_high_range,
        source.ovn_low_range,
        source.ovn_comparator_cd_1,
        source.ovn_numeric_value_1,
        source.ovn_numeric_value_2,
        source.ovn_numeric_unit_cd,
        source.ovn_separator_cd,
        source.ovn_seq,
        source.batch_id
      );
      """;

  private void persistNumeric(List<ObservationNumeric> numericEntries) {
    numericEntries.forEach(
        n ->
            client
                .sql(UPSERT_NUMERIC)
                .param("observation_uid", n.getObservationUid())
                .param("ovn_seq", n.getOvnSeq())
                .param("ovn_high_range", n.getOvnHighRange())
                .param("ovn_low_range", n.getOvnLowRange())
                .param("ovn_comparator_cd_1", n.getOvnComparatorCd1())
                .param("ovn_numeric_value_1", n.getOvnNumericValue1())
                .param("ovn_numeric_value_2", n.getOvnNumericValue2())
                .param("ovn_numeric_unit_cd", n.getOvnNumericUnitCd())
                .param("ovn_separator_cd", n.getOvnSeparatorCd())
                .param("batch_id", n.getBatchId())
                .update());
  }

  private static final String UPSERT_REASON =
      """
      MERGE INTO nrt_observation_reason
      USING (
        SELECT
          :observation_uid as observation_uid,
          :reason_cd as reason_cd,
          :reason_desc_txt as reason_desc_txt,
          :batch_id as batch_id
      ) AS source
       ON nrt_observation_reason.observation_uid = source.observation_uid AND nrt_observation_reason.reason_cd = source.reason_cd
      WHEN MATCHED THEN
        UPDATE SET
          observation_uid = source.observation_uid,
          reason_cd = source.reason_cd,
          reason_desc_txt = source.reason_desc_txt,
          batch_id = source.batch_id
      WHEN NOT MATCHED THEN
      INSERT (
        observation_uid,
        reason_cd,
        reason_desc_txt,
        batch_id
      ) VALUES (
        source.observation_uid,
        source.reason_cd,
        source.reason_desc_txt,
        source.batch_id
      );
      """;

  private void persistReason(List<ObservationReason> reasonEntries) {
    reasonEntries.forEach(
        r ->
            client
                .sql(UPSERT_REASON)
                .param("observation_uid", r.getObservationUid())
                .param("reason_cd", r.getReasonCd())
                .param("reason_desc_txt", r.getReasonDescTxt())
                .param("batch_id", r.getBatchId())
                .update());
  }

  private static final String UPSERT_TEXT =
      """
      MERGE INTO nrt_observation_txt
      USING (
        SELECT
          :observation_uid AS observation_uid,
          :ovt_seq AS ovt_seq,
          :ovt_txt_type_cd AS ovt_txt_type_cd,
          :ovt_value_txt AS ovt_value_txt,
          :batch_id AS batch_id
      ) AS source
       ON nrt_observation_txt.observation_uid = source.observation_uid AND nrt_observation_txt.ovt_seq = source.ovt_seq
      WHEN MATCHED THEN
        UPDATE SET
          observation_uid = source.observation_uid,
          ovt_seq = source.ovt_seq,
          ovt_txt_type_cd = source.ovt_txt_type_cd,
          ovt_value_txt = source.ovt_value_txt,
          batch_id = source.batch_id
      WHEN NOT MATCHED THEN
      INSERT (
        observation_uid,
        ovt_seq,
        ovt_txt_type_cd,
        ovt_value_txt,
        batch_id
      ) VALUES (
        source.observation_uid,
        source.ovt_seq,
        source.ovt_txt_type_cd,
        source.ovt_value_txt,
        source.batch_id
      );
      """;

  private void persistText(List<ObservationTxt> textEntries) {
    textEntries.forEach(
        t ->
            client
                .sql(UPSERT_TEXT)
                .param("observation_uid", t.getObservationUid())
                .param("ovt_seq", t.getOvtSeq())
                .param("ovt_txt_type_cd", t.getOvtTxtTypeCd())
                .param("ovt_value_txt", t.getOvtValueTxt())
                .param("batch_id", t.getBatchId())
                .update());
  }
}
