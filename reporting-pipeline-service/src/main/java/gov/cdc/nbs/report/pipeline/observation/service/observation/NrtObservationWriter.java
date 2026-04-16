package gov.cdc.nbs.report.pipeline.observation.service.observation;

import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationMaterial;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ParsedObservation;
import java.util.List;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Responsible for writing Observation data to the following tables:
 *
 * <ul>
 *   <li>nrt_observation_coded
 *   <li>nrt_observation_date
 *   <li>nrt_observation_edx
 *   <li>nrt_observation_material
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
  }

  private static final String UPSERT_MATERIAL =
      """
      MERGE INTO nrt_observation_material
      USING (
        SELECT
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
        FROM
          nrt_observation_material
        WHERE
          act_uid = :act_uid
          AND material_id = :material_id
      ) AS source
       ON nrt_observation_material.act_uid = source.act_uid AND nrt_observation_material.material_id = source.material_id
      WHEN MATCHED THEN
        UPDATE SET
          type_cd = :type_cd,
          subject_class_cd = :subject_class_cd,
          record_status = :record_status,
          type_desc_txt = :type_desc_txt,
          last_chg_time = :last_chg_time,
          material_cd = :material_cd,
          material_nm = :material_nm,
          material_details = :material_details,
          material_collection_vol = :material_collection_vol,
          material_collection_vol_unit = :material_collection_vol_unit,
          material_desc = :material_desc,
          risk_cd = :risk_cd,
          risk_desc_txt = :risk_desc_txt
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
        ) values (
          :act_uid,
          :type_cd,
          :material_id,
          :subject_class_cd,
          :record_status,
          :type_desc_txt,
          :last_chg_time,
          :material_cd,
          :material_nm,
          :material_details,
          :material_collection_vol,
          :material_collection_vol_unit,
          :material_desc,
          :risk_cd,
          :risk_desc_txt
        )
      """;

  private void persistMaterials(List<ObservationMaterial> materials) {
    materials.forEach(
        m -> {
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
              // Are these columns ever set?
              // :refresh_datetime
              // :max_datetime
              .update();
        });
  }
}
